// Le SEUL fichier du depot autorise a importer le SDK serveur LiveKit.
//
// Regle posee par l'ADR-001 et reprise telle quelle : la cle API et son secret
// ne quittent jamais les secrets Supabase, et aucune autre fonction Edge n'a le
// droit de fabriquer un jeton. Concentrer cela ici rend la regle verifiable
// d'un seul `grep` plutot que par relecture.
//
// Pourquoi le SDK officiel plutot qu'un JWT signe a la main : la section 4 de
// la specification l'impose (« ne te contente jamais d'une memoire approximative
// de l'API »), et surtout les claims LiveKit evoluent avec les versions --
// `canPublishSources` n'existait pas au debut, `roomJoin` a change de forme.
// Un jeton fabrique de memoire marche le jour ou on l'ecrit et casse a la
// montee de version suivante, sans prevenir.

import {
  AccessToken,
  type ParticipantInfo,
  ParticipantInfo_State,
  RoomServiceClient,
  TrackSource,
  WebhookReceiver,
} from 'npm:livekit-server-sdk@2.13.1'
import {
  type DroitsPublication,
  elevesARetablir,
  enseignantPresent,
  metadonneesDuJeton,
  type ParticipantVu,
  type PresenceEnseignant,
} from './publication_differee.ts'

/// Les deux fournisseurs coexistent (decision de l'operateur du 12 septembre
/// 2026 : Cloud pour eprouver, self-host pour encaisser, jamais Cloud seul).
/// Chacun a son trousseau ; la base dit lequel s'applique a une seance donnee.
export type Fournisseur = 'cloud' | 'self_hosted'

/// Ce que la base a decide, et que cette couche se contente de signer.
export interface AutorisationVideo {
  ws_url: string
  room_name: string
  provider: Fournisseur
  identity: string
  role: string
  ttl_seconds: number
  capabilities: {
    can_publish: boolean
    can_publish_video: boolean
    can_publish_data: boolean
    can_subscribe: boolean
    hidden: boolean
  }
}

interface Trousseau {
  cle: string
  secret: string
}

/// Lit le trousseau d'un fournisseur. Les noms sont explicites parce qu'il y en
/// a deux : `LIVEKIT_API_KEY` tout court serait ambigu le jour de la bascule.
function trousseau(fournisseur: Fournisseur): Trousseau {
  const prefixe = fournisseur === 'cloud' ? 'LIVEKIT_CLOUD' : 'LIVEKIT_SELFHOST'
  const cle = Deno.env.get(`${prefixe}_API_KEY`)
  const secret = Deno.env.get(`${prefixe}_API_SECRET`)
  if (!cle || !secret) {
    throw new Error(`configuration absente : ${prefixe}_API_KEY ou ${prefixe}_API_SECRET`)
  }
  return { cle, secret }
}

/// L'URL de repli d'un fournisseur, quand la base n'impose pas d'`ws_url_override`.
export function urlDe(fournisseur: Fournisseur): string {
  const nom = fournisseur === 'cloud' ? 'LIVEKIT_CLOUD_WS_URL' : 'LIVEKIT_SELFHOST_WS_URL'
  return Deno.env.get(nom) ?? ''
}

/// Vrai quand au moins un fournisseur est configure. Sert a repondre
/// proprement « la video n'est pas encore branchee » plutot qu'a exploser.
export function videoConfiguree(): boolean {
  return (
    (!!Deno.env.get('LIVEKIT_CLOUD_API_KEY') && !!Deno.env.get('LIVEKIT_CLOUD_API_SECRET')) ||
    (!!Deno.env.get('LIVEKIT_SELFHOST_API_KEY') && !!Deno.env.get('LIVEKIT_SELFHOST_API_SECRET'))
  )
}

/// Signe le jeton que le client presentera a LiveKit.
///
/// **Cette fonction ne decide rien.** Elle transcrit ce que
/// `autoriser_jeton_video()` a deja tranche en base. Si une capacite devait se
/// calculer ici, elle serait calculee dans un endroit ou la RLS, les roles et
/// l'appartenance a la seance ne sont plus sous la main -- c'est-a-dire au
/// mauvais endroit.
///
/// MICRO-AVANT-ENSEIGNANT (11/11/2026) : [differe] signe le jeton d'un eleve
/// **sans droit de publier** tant que l'enseignant n'est pas dans la salle.
/// La decision se prend dans `publication_differee.ts` (`doitDifferer`), a
/// partir du role decide en base et de la presence lue chez LiveKit ; ici on
/// ne fait que l'ecrire dans le jeton. Les droits que l'eleve retrouvera
/// voyagent dans les metadonnees signees (`pub`).
export async function signerJeton(a: AutorisationVideo, differe = false): Promise<string> {
  const { cle, secret } = trousseau(a.provider)

  const jeton = new AccessToken(cle, secret, {
    identity: a.identity,
    ttl: a.ttl_seconds,
    // Le role voyage en metadonnee : la salle en a besoin pour placer
    // l'enseignant au centre sans redemander la base a chaque rendu.
    metadata: metadonneesDuJeton(a.role, a.capabilities),
  })
  const publie = a.capabilities.can_publish && !differe

  // `canPublishSources` borne ce qu'un participant peut publier, source par
  // source. C'est lui qui realise `camera_policy = 'forbidden'` : l'eleve garde
  // le micro et perd la camera, sans que l'interface ait a y veiller.
  // Le SDK 2.x attend l'enum `TrackSource` et la convertit lui-meme en nom
  // (« microphone », « camera ») dans le JWT ; une chaine brute fait echouer
  // `toJwt()` (« Cannot convert TrackSource microphone to string »).
  const sources: TrackSource[] = []
  if (publie) {
    sources.push(TrackSource.MICROPHONE)
    if (a.capabilities.can_publish_video) sources.push(TrackSource.CAMERA)
  }

  jeton.addGrant({
    room: a.room_name,
    roomJoin: true,
    canPublish: publie,
    canSubscribe: a.capabilities.can_subscribe,
    canPublishData: a.capabilities.can_publish_data,
    canPublishSources: sources,
    // L'observation invisible de `CTR-02`, decidee en base et appliquee par le
    // serveur : le controleur n'apparait dans la liste de personne.
    hidden: a.capabilities.hidden,
  })

  return await jeton.toJwt()
}

/// Verifie la signature d'un webhook LiveKit et rend l'evenement.
///
/// Un webhook non signe, ou signe par une cle inconnue, n'est pas un evenement
/// douteux : c'est quelqu'un qui fabrique des presences. Il est refuse.
///
/// Les deux trousseaux sont essayes parce que les deux fournisseurs tournent en
/// parallele : une salle sur le serveur auto-heberge est annoncee par le
/// trousseau self-host, pas par celui du Cloud.
export async function verifierWebhook(
  corps: string,
  entete: string | null,
): Promise<Record<string, unknown>> {
  return (await verifierWebhookSigne(corps, entete)).evenement
}

/// Comme [verifierWebhook], et dit en plus quel trousseau a signe : c'est le
/// fournisseur de la salle annoncee, utile quand la route de la seance n'a pas
/// pu etre relue en base.
export async function verifierWebhookSigne(
  corps: string,
  entete: string | null,
): Promise<{ evenement: Record<string, unknown>; fournisseur: Fournisseur }> {
  if (!entete) {
    throw new Error('webhook non signe')
  }

  const candidats: Fournisseur[] = ['cloud', 'self_hosted']
  let derniereErreur: unknown = new Error('aucun fournisseur configure')

  for (const fournisseur of candidats) {
    let cles: Trousseau
    try {
      cles = trousseau(fournisseur)
    } catch (e) {
      derniereErreur = e
      continue
    }
    try {
      const receveur = new WebhookReceiver(cles.cle, cles.secret)
      const evenement = (await receveur.receive(corps, entete)) as unknown as Record<
        string,
        unknown
      >
      return { evenement, fournisseur }
    } catch (e) {
      derniereErreur = e
    }
  }

  throw derniereErreur
}

/// La salle LiveKit d'une seance : le fournisseur, son adresse, son nom.
export interface RouteSalle {
  provider: Fournisseur
  ws_url: string
  room_name: string
}

/// La route d'un geste de l'enseignant, rendue par `autoriser_geste_salle()`.
export interface RouteGeste extends RouteSalle {
  identity: string
}

/// Ce que l'API serveur LiveKit sait faire a un participant, pour la salle.
export type GesteSalle = 'couper_micro' | 'couper_camera' | 'faire_sortir'

/// Le client de l'API serveur d'une salle : la meme adresse que celle des
/// participants, en HTTP(S) au lieu de WebSocket.
function serviceSalle(route: RouteSalle): RoomServiceClient {
  const { cle, secret } = trousseau(route.provider)
  const hote = route.ws_url.replace(/^wss:/, 'https:').replace(/^ws:/, 'http:')
  return new RoomServiceClient(hote, cle, secret)
}

/// Applique un geste deja autorise et journalise par la base.
///
/// **Cette fonction ne decide rien non plus** : `autoriser_geste_salle()` a
/// verifie l'enseignant effectif, la cible et la salle ouverte. Rend `false`
/// quand il n'y avait rien a faire (piste non publiee, participant deja
/// parti) : ce n'est pas une erreur.
export async function appliquerGeste(route: RouteGeste, geste: GesteSalle): Promise<boolean> {
  const service = serviceSalle(route)
  if (geste === 'faire_sortir') {
    try {
      await service.removeParticipant(route.room_name, route.identity)
      return true
    } catch (e) {
      // Deja parti : la sortie, elle, est enregistree en base et le jeton
      // suivant sera refuse.
      if (String((e as Error).message).toLowerCase().includes('not found')) return false
      throw e
    }
  }
  const source = geste === 'couper_micro' ? TrackSource.MICROPHONE : TrackSource.CAMERA
  let participant
  try {
    participant = await service.getParticipant(route.room_name, route.identity)
  } catch (e) {
    if (String((e as Error).message).toLowerCase().includes('not found')) return false
    throw e
  }
  const pistes = participant.tracks.filter((p) => p.source === source && !p.muted)
  for (const piste of pistes) {
    await service.mutePublishedTrack(route.room_name, route.identity, piste.sid, true)
  }
  return pistes.length > 0
}

// ---------------------------------------------------------------------------
// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1).
//
// Les decisions sont dans `publication_differee.ts` ; ici, seulement les
// appels a l'API serveur de LiveKit qu'elles demandent.
// ---------------------------------------------------------------------------

/// Le delai accorde a l'API serveur LiveKit pour ces appels. Au-dela, la
/// presence est « inconnue » et le jeton part avec ses droits ordinaires : la
/// regle ne doit jamais retarder ni empecher une entree en salle.
const DELAI_API_SALLE_MS = 3000

function borne<T>(promesse: Promise<T>, quoi: string): Promise<T> {
  let minuterie: ReturnType<typeof setTimeout> | undefined
  const delai = new Promise<never>((_, rejeter) => {
    minuterie = setTimeout(
      () => rejeter(new Error(`delai depasse : ${quoi}`)),
      DELAI_API_SALLE_MS,
    )
  })
  return Promise.race([promesse, delai]).finally(() => clearTimeout(minuterie))
}

/// Vrai quand LiveKit dit que la salle (ou le participant) n'existe pas :
/// ce n'est pas une panne, c'est une salle vide ou quelqu'un deja parti.
function introuvable(e: unknown): boolean {
  const message = String((e as Error)?.message ?? e).toLowerCase()
  return message.includes('not found') || message.includes('does not exist')
}

function vu(p: ParticipantInfo): ParticipantVu {
  return {
    identity: p.identity,
    metadata: p.metadata,
    peutPublier: p.permission ? p.permission.canPublish : undefined,
    deconnecte: p.state === ParticipantInfo_State.DISCONNECTED,
  }
}

/// Les participants de la salle ; une salle qui n'existe pas encore est vide.
async function participantsDe(
  service: RoomServiceClient,
  salle: string,
): Promise<ParticipantInfo[]> {
  try {
    return await borne(service.listParticipants(salle), 'liste des participants')
  } catch (e) {
    if (introuvable(e)) return []
    throw e
  }
}

/// L'enseignant de la seance est-il dans la salle LiveKit ?
///
/// `inconnue` quand LiveKit ne repond pas : l'appelant ne differe alors rien
/// (`doitDifferer`), et le journal le dit.
export async function presenceEnseignant(route: RouteSalle): Promise<PresenceEnseignant> {
  try {
    const participants = await participantsDe(serviceSalle(route), route.room_name)
    return enseignantPresent(participants.map(vu)) ? 'present' : 'absent'
  } catch (e) {
    console.error('presence de l enseignant illisible', {
      salle: route.room_name,
      erreur: (e as Error).message,
    })
    return 'inconnue'
  }
}

/// Ce qu'a fait [retablirPublication].
export interface BilanRetablissement {
  /// L'enseignant est dans la salle.
  enseignant: boolean
  /// Les identites dont le droit de publier vient d'etre rendu.
  retablis: string[]
  /// Les identites pour lesquelles LiveKit a refuse ou n'a pas repondu.
  echecs: string[]
  /// Avec une cible : elle est dans la salle.
  ciblePresente?: boolean
  /// Avec une cible : son droit de publier est ouvert a la sortie.
  cibleOuverte?: boolean
}

/// Rend le droit de publier aux eleves differes, **si et seulement si
/// l'enseignant est dans la salle LiveKit** : c'est relu ici a chaque appel,
/// personne ne l'affirme a la place du serveur.
///
/// Sans [cible] (webhook) : tous les eleves differes de la salle, avec les
/// droits promis par leur jeton signe (`pub`). Avec [cible] (filet demande par
/// un client) : ce seul participant, avec les droits que la base vient de
/// redecider pour lui.
///
/// Les autres champs de la permission (recevoir, canal de donnees, invisible)
/// sont recopies tels quels : `updateParticipant` remplace la permission
/// entiere, et un eleve ne doit rien gagner ni perdre d'autre ici.
export async function retablirPublication(
  route: RouteSalle,
  cible?: { identite: string; droits: DroitsPublication },
): Promise<BilanRetablissement> {
  const service = serviceSalle(route)
  const participants = await participantsDe(service, route.room_name)
  const vus = participants.map(vu)
  const bilan: BilanRetablissement = {
    enseignant: enseignantPresent(vus),
    retablis: [],
    echecs: [],
  }

  let aRetablir: { identity: string; droits: DroitsPublication }[]
  if (cible) {
    const lui = vus.find((p) => p.identity === cible.identite && p.deconnecte !== true)
    bilan.ciblePresente = lui !== undefined
    bilan.cibleOuverte = lui?.peutPublier === true
    aRetablir =
      bilan.enseignant && lui !== undefined && lui.peutPublier !== true && cible.droits.micro
        ? [{ identity: cible.identite, droits: cible.droits }]
        : []
  } else {
    aRetablir = elevesARetablir(vus)
  }

  await Promise.all(aRetablir.map(async ({ identity, droits }) => {
    const actuel = participants.find((p) => p.identity === identity)?.permission
    const sources: TrackSource[] = [TrackSource.MICROPHONE]
    if (droits.camera) sources.push(TrackSource.CAMERA)
    try {
      await borne(
        service.updateParticipant(route.room_name, identity, {
          permission: {
            canSubscribe: actuel?.canSubscribe ?? true,
            canPublishData: actuel?.canPublishData ?? false,
            hidden: actuel?.hidden ?? false,
            canUpdateMetadata: actuel?.canUpdateMetadata ?? false,
            canPublish: true,
            canPublishSources: sources,
          },
        }),
        'retablissement de la publication',
      )
      bilan.retablis.push(identity)
    } catch (e) {
      // Deja parti : rien a rendre. Tout autre refus est note ; le filet du
      // client (ou le prochain webhook) reessaiera.
      if (!introuvable(e)) {
        bilan.echecs.push(identity)
        console.error('retablissement de la publication impossible', {
          salle: route.room_name,
          erreur: (e as Error).message,
        })
      }
    }
  }))

  if (cible && bilan.retablis.includes(cible.identite)) bilan.cibleOuverte = true
  return bilan
}
