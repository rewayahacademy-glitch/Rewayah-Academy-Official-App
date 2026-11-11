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
  droitsEnVigueur,
  elevesARetablir,
  enseignantPresent,
  metadonneesDuJeton,
  type ParticipantVu,
  permissionDePublication,
  type PresenceEnseignant,
  type SourcePublication,
} from './publication_differee.ts'
import {
  deciderSalle,
  type DecisionSalle,
  ecrireSansEnseignant,
  lireSansEnseignant,
  type SalleASurveiller,
  type SeanceVue,
} from './fermeture_salle.ts'
import {
  camaradesARegler,
  ecrireRecitation,
  elevePresent,
  elevesARendre,
  lireRecitation,
  type Recitation,
  recitationTenue,
  retablisPendantRecitation,
} from './recitation.ts'

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

/// RECITATION-MICRO-SEUL : les sources auxquelles la permission borne la
/// publication, ou `undefined` sans borne (liste vide : LiveKit autorise
/// alors toutes les sources). Seuls le micro et la camera sont lus.
function sourcesVues(p: ParticipantInfo): SourcePublication[] | undefined {
  const brutes = p.permission?.canPublishSources ?? []
  if (brutes.length === 0) return undefined
  const sources: SourcePublication[] = []
  if (brutes.includes(TrackSource.MICROPHONE)) sources.push('micro')
  if (brutes.includes(TrackSource.CAMERA)) sources.push('camera')
  return sources
}

function vu(p: ParticipantInfo): ParticipantVu {
  return {
    identity: p.identity,
    metadata: p.metadata,
    peutPublier: p.permission ? p.permission.canPublish : undefined,
    sourcesPermises: sourcesVues(p),
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
  /// Avec une cible : son micro est permis a la sortie (RECITATION-MICRO-SEUL :
  /// un camarade qui ne garde que sa camera pendant une recitation n'est pas
  /// « ouvert »).
  cibleOuverte?: boolean
  /// GESTES-POINTEUR : une recitation tient, voici l'identite du recitant.
  /// Les autres eleves restent fermes tant qu'elle dure.
  recitation?: string
  /// GESTES-POINTEUR : une recitation ecrite dans la salle ne tenait plus
  /// (recitant ou enseignant parti) ; elle vient d'etre terminee ici.
  recitationTerminee?: boolean
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
    // RECITATION-MICRO-SEUL : « ouvert » veut dire que le MICRO est permis.
    // `canPublish` seul ne le dit plus (un camarade garde sa camera pendant
    // une recitation).
    const microPermis = lui !== undefined && lui.peutPublier === true && droitsEnVigueur(lui).micro
    bilan.cibleOuverte = microPermis
    aRetablir = bilan.enseignant && lui !== undefined && !microPermis && cible.droits.micro
      ? [{ identity: cible.identite, droits: cible.droits }]
      : []
  } else {
    aRetablir = elevesARetablir(vus)
  }

  // GESTES-POINTEUR (11/11/2026) : la recitation. Cette fonction est le seul
  // chemin qui rend un droit de publier (webhook a chaque entree et a chaque
  // sortie, filet demande par un eleve) ; c'est donc ici que la regle tient.
  //
  //   * la recitation tient (enseignant et recitant presents) : personne
  //     d'autre que le recitant ne retrouve son micro, et un eleve entre
  //     entre-temps perd le sien a son tour (RECITATION-MICRO-SEUL : chaque
  //     camarade garde, ou retrouve, la camera de son propre jeton) ;
  //   * elle ne tient plus : elle est effacee et tous les droits reviennent.
  //
  // Metadonnees illisibles : aucune recitation (dans le doute, la classe
  // parle).
  const recitation = await recitationDe(service, route.room_name)
  if (recitation !== null) {
    if (recitationTenue(recitation.recitation, vus)) {
      const recitant = recitation.recitation.recitant
      bilan.recitation = recitant
      const regles = await poserPublication(
        service,
        route.room_name,
        participants,
        camaradesARegler(vus, recitant),
        'reglage de la recitation',
      )
      bilan.echecs.push(...regles.echecs)
      aRetablir = retablisPendantRecitation(aRetablir, recitant)
    } else {
      bilan.recitationTerminee = true
      try {
        await borne(
          service.updateRoomMetadata(
            route.room_name,
            ecrireRecitation(recitation.metadonnees, null),
          ),
          'fin de la recitation',
        )
      } catch (e) {
        // Non efface : le prochain appel la retrouvera finie et recommencera.
        // Les droits, eux, sont rendus maintenant.
        if (!introuvable(e)) {
          console.error('fin de la recitation non ecrite', {
            salle: route.room_name,
            erreur: (e as Error).message,
          })
        }
      }
      const deja = new Set(aRetablir.map((e) => e.identity))
      aRetablir = [...aRetablir, ...elevesARendre(vus).filter((e) => !deja.has(e.identity))]
    }
  }

  const rendus = await rendrePublication(service, route.room_name, participants, aRetablir)
  bilan.retablis.push(...rendus.faits)
  bilan.echecs.push(...rendus.echecs)

  if (cible && bilan.retablis.includes(cible.identite)) bilan.cibleOuverte = true
  return bilan
}

// ---------------------------------------------------------------------------
// GESTES-POINTEUR (directeur, 11/11/2026) : « Faire reciter ».
//
// Les decisions sont dans `recitation.ts` ; ici, seulement les appels a l'API
// serveur de LiveKit qu'elles demandent.
// ---------------------------------------------------------------------------

/// Ce qu'a fait un changement de droits sur une liste de participants.
interface BilanDroits {
  faits: string[]
  echecs: string[]
}

/// Pose chez LiveKit les droits de publication de chaque participant de
/// [liste] : le seul endroit qui ecrit une permission de publication.
///
/// RECITATION-MICRO-SEUL (11/11/2026) : les droits se posent source par
/// source (`canPublishSources`). Micro et camera, micro seul, camera seule
/// (un camarade pendant une recitation), ou rien : `canPublish` est alors
/// retire tout entier, jamais laisse avec une liste vide que LiveKit lirait
/// comme « tout » (`permissionDePublication`).
///
/// Quand une source n'est plus permise, **LiveKit depublie lui-meme la piste
/// deja publiee de cette source** et refuse toute nouvelle piste ; les pistes
/// des sources encore permises ne sont pas touchees (prouve sur la pile
/// locale, serveur LiveKit 1.13.11 : `tool/salle/gestes.mjs`, etape 3).
///
/// Les autres champs de la permission (recevoir, canal de donnees, invisible)
/// sont recopies tels quels : `updateParticipant` remplace la permission
/// entiere, et un eleve ne doit rien gagner ni perdre d'autre ici.
async function poserPublication(
  service: RoomServiceClient,
  salle: string,
  participants: readonly ParticipantInfo[],
  liste: readonly { identity: string; droits: DroitsPublication }[],
  quoi: string,
): Promise<BilanDroits> {
  const bilan: BilanDroits = { faits: [], echecs: [] }
  await Promise.all(liste.map(async ({ identity, droits }) => {
    const actuel = participants.find((p) => p.identity === identity)?.permission
    const voulue = permissionDePublication(droits)
    const sources: TrackSource[] = voulue.sources.map((s) =>
      s === 'micro' ? TrackSource.MICROPHONE : TrackSource.CAMERA
    )
    try {
      await borne(
        service.updateParticipant(salle, identity, {
          permission: {
            canSubscribe: actuel?.canSubscribe ?? true,
            canPublishData: actuel?.canPublishData ?? false,
            hidden: actuel?.hidden ?? false,
            canUpdateMetadata: actuel?.canUpdateMetadata ?? false,
            canPublish: voulue.canPublish,
            canPublishSources: sources,
          },
        }),
        quoi,
      )
      bilan.faits.push(identity)
    } catch (e) {
      // Deja parti : rien a poser. Tout autre refus est note ; le filet du
      // client (ou le prochain webhook) reessaiera.
      if (!introuvable(e)) {
        bilan.echecs.push(identity)
        console.error(`${quoi} impossible`, {
          salle,
          erreur: (e as Error).message,
        })
      }
    }
  }))
  return bilan
}

/// Rend le droit de publier a chaque eleve de [liste], avec les droits promis
/// par son jeton (le micro, et la camera s'il l'avait).
function rendrePublication(
  service: RoomServiceClient,
  salle: string,
  participants: readonly ParticipantInfo[],
  liste: readonly { identity: string; droits: DroitsPublication }[],
): Promise<BilanDroits> {
  return poserPublication(
    service,
    salle,
    participants,
    liste,
    'retablissement de la publication',
  )
}

/// Retire tout droit de publier (micro ET camera) a chaque identite de
/// [liste] : FERMETURE-SALLE, apres le depart de l'enseignant. LiveKit
/// depublie alors lui-meme leurs pistes, et refuse toute nouvelle piste tant
/// que le droit n'est pas rendu.
function fermerPublication(
  service: RoomServiceClient,
  salle: string,
  participants: readonly ParticipantInfo[],
  liste: readonly string[],
): Promise<BilanDroits> {
  return poserPublication(
    service,
    salle,
    participants,
    liste.map((identity) => ({ identity, droits: { micro: false, camera: false } })),
    'fermeture de la publication',
  )
}

/// La recitation ecrite dans la salle, avec les metadonnees completes (pour
/// les reecrire sans rien perdre), ou `null` : pas de salle, pas de
/// recitation, ou LiveKit n'a pas repondu.
async function recitationDe(
  service: RoomServiceClient,
  salle: string,
): Promise<{ recitation: Recitation; metadonnees: string } | null> {
  try {
    const salles = await borne(service.listRooms([salle]), 'lecture de la salle')
    const metadonnees = salles.find((r) => r.name === salle)?.metadata ?? ''
    const recitation = lireRecitation(metadonnees)
    return recitation === null ? null : { recitation, metadonnees }
  } catch (e) {
    if (!introuvable(e)) {
      console.error('recitation illisible', { salle, erreur: (e as Error).message })
    }
    return null
  }
}

/// Ce qu'a fait [ouvrirRecitation] ou [terminerRecitation].
export interface BilanRecitation {
  /// La recitation est en place (ou terminee) chez LiveKit.
  applique: boolean
  /// Pourquoi elle n'a pas ete ouverte : le recitant ou l'enseignant n'est
  /// pas dans la salle.
  motif?: 'recitant_absent' | 'enseignant_absent'
  /// Les camarades dont le micro vient d'etre ferme (RECITATION-MICRO-SEUL :
  /// leur camera reste, si leur jeton la leur donne).
  fermes: string[]
  /// Les eleves dont le droit de publier vient d'etre rendu.
  rendus: string[]
  /// Les identites pour lesquelles LiveKit a refuse ou n'a pas repondu.
  echecs: string[]
}

/// Ouvre la recitation de [route].identity, deja autorisee par la base
/// (`autoriser_geste_salle` : l'appelant est l'enseignant effectif, la cible
/// un eleve inscrit, la salle ouverte).
///
/// L'ordre compte : l'etat est ecrit dans la salle AVANT de fermer qui que ce
/// soit, pour qu'un filet demande au meme instant ne rouvre personne. Si
/// l'ecriture echoue, rien n'est ferme et l'erreur remonte.
export async function ouvrirRecitation(route: RouteGeste): Promise<BilanRecitation> {
  const service = serviceSalle(route)
  const participants = await participantsDe(service, route.room_name)
  const vus = participants.map(vu)
  const bilan: BilanRecitation = { applique: false, fermes: [], rendus: [], echecs: [] }
  if (!enseignantPresent(vus)) return { ...bilan, motif: 'enseignant_absent' }
  if (!elevePresent(vus, route.identity)) return { ...bilan, motif: 'recitant_absent' }

  const salles = await borne(service.listRooms([route.room_name]), 'lecture de la salle')
  const metadonnees = salles.find((r) => r.name === route.room_name)?.metadata ?? ''
  await borne(
    service.updateRoomMetadata(
      route.room_name,
      ecrireRecitation(metadonnees, { recitant: route.identity, depuis: Date.now() }),
    ),
    'ouverture de la recitation',
  )

  const [fermes, rendus] = await Promise.all([
    // RECITATION-MICRO-SEUL : le micro des camarades est ferme, leur camera
    // reste (ou tout se ferme, si leur profil interdit la camera).
    poserPublication(
      service,
      route.room_name,
      participants,
      camaradesARegler(vus, route.identity),
      'reglage de la recitation',
    ),
    // Le recitant ferme par une recitation precedente retrouve son droit ;
    // son micro, lui, n'est jamais ouvert d'ici.
    rendrePublication(
      service,
      route.room_name,
      participants,
      elevesARendre(vus).filter((e) => e.identity === route.identity),
    ),
  ])
  return {
    applique: true,
    fermes: fermes.faits,
    rendus: rendus.faits,
    echecs: [...fermes.echecs, ...rendus.echecs],
  }
}

/// Termine la recitation : l'etat est efface, puis tous les droits reviennent
/// (micros fermes : rien n'est rouvert a la place des eleves). Sans
/// recitation en cours, rend quand meme tout droit reste ferme : ce geste est
/// aussi la porte de secours de l'enseignant.
export async function terminerRecitation(route: RouteSalle): Promise<BilanRecitation> {
  const service = serviceSalle(route)
  const participants = await participantsDe(service, route.room_name)
  const vus = participants.map(vu)
  const enCours = await recitationDe(service, route.room_name)
  if (enCours !== null) {
    await borne(
      service.updateRoomMetadata(
        route.room_name,
        ecrireRecitation(enCours.metadonnees, null),
      ),
      'fin de la recitation',
    )
  }
  // Une recitation etait en cours : chacun retrouve ce qu'il avait. Sinon, la
  // regle ordinaire seulement (rien n'est rendu sans l'enseignant dans la
  // salle : MICRO-AVANT-ENSEIGNANT).
  const liste = enCours !== null ? elevesARendre(vus) : elevesARetablir(vus)
  const rendus = await rendrePublication(service, route.room_name, participants, liste)
  return { applique: true, fermes: [], rendus: rendus.faits, echecs: rendus.echecs }
}

/// L'identite du recitant ecrite dans la salle, ou `null`. Sert a terminer
/// une recitation dont l'application de l'enseignant a perdu la trace (page
/// rechargee) : le serveur, lui, la connait.
export async function recitantEnCours(route: RouteSalle): Promise<string | null> {
  const enCours = await recitationDe(serviceSalle(route), route.room_name)
  return enCours?.recitation.recitant ?? null
}

// ---------------------------------------------------------------------------
// FERMETURE-SALLE (directeur, 11/11/2026, seconde moitie de SEC-1, D-018).
//
// Les decisions sont dans `fermeture_salle.ts` ; ici, seulement les appels a
// l'API serveur de LiveKit qu'elles demandent.
// ---------------------------------------------------------------------------

/// Ce qu'a fait [tenirFermeture] dans une salle.
export interface BilanFermeture {
  /// Ce qui a ete decide (et applique, sauf [echecs]).
  action: DecisionSalle['action']
  /// Pour `fermer_salle` : la seance close en base, ou le depassement passe.
  motif?: 'depassement' | 'cloture'
  /// Les eleves dont le droit de publier vient d'etre ferme.
  fermes: string[]
  /// Ce que LiveKit a refuse ou n'a pas fait a temps.
  echecs: string[]
  /// Le temps qui reste avant l'echeance (salle sans enseignant, delai en
  /// cours), en millisecondes.
  resteMs?: number
}

/// Tient la regle de FERMETURE-SALLE dans une salle : lit qui est la et la
/// marque `sans_enseignant`, decide (`deciderSalle`), applique.
///
/// [seance] : ce que la base sait de la seance, ou `null` si elle ne se lit
/// pas (la salle n'est alors jamais fermee ; seuls les micros des eleves
/// peuvent l'etre, apres le delai sans enseignant).
///
/// Une panne de LiveKit a la lecture remonte en erreur : l'appelant la
/// consigne et ne ferme rien. Dans le doute, la salle reste comme elle est.
export async function tenirFermeture(
  route: RouteSalle,
  seance: SeanceVue | null,
  options: { departEnseignant?: boolean; maintenantMs?: number } = {},
): Promise<BilanFermeture> {
  const service = serviceSalle(route)
  const participants = await participantsDe(service, route.room_name)
  const bilan: BilanFermeture = { action: 'rien', fermes: [], echecs: [] }
  if (participants.length === 0) return bilan

  const salles = await borne(service.listRooms([route.room_name]), 'lecture de la salle')
  const metadonnees = salles.find((r) => r.name === route.room_name)?.metadata ?? ''
  const decision = deciderSalle({
    maintenantMs: options.maintenantMs ?? Date.now(),
    participants: participants.map(vu),
    marque: lireSansEnseignant(metadonnees),
    seance,
    departEnseignant: options.departEnseignant,
  })
  bilan.action = decision.action

  switch (decision.action) {
    case 'rien':
      bilan.resteMs = decision.resteMs
      break
    case 'poser_echeance':
      bilan.resteMs = decision.resteMs
      await ecrireMarque(service, route.room_name, metadonnees, { depuis: decision.depuis }, bilan)
      break
    case 'lever_echeance':
      await ecrireMarque(service, route.room_name, metadonnees, null, bilan)
      break
    case 'fermer_micros': {
      const fermes = await fermerPublication(
        service,
        route.room_name,
        participants,
        decision.eleves,
      )
      bilan.fermes = fermes.faits
      bilan.echecs.push(...fermes.echecs)
      break
    }
    case 'fermer_salle':
      bilan.motif = decision.motif
      try {
        // `DeleteRoom` deconnecte tous les participants (raison
        // `ROOM_DELETED` chez chacun) : c'est ce que l'application lit pour
        // dire « La seance est terminee. ».
        await borne(service.deleteRoom(route.room_name), 'fermeture de la salle')
      } catch (e) {
        // Deja fermee : rien a faire. Tout autre refus est note ; le
        // prochain passage recommencera.
        if (!introuvable(e)) {
          bilan.echecs.push(route.room_name)
          console.error('fermeture de la salle impossible', {
            salle: route.room_name,
            erreur: (e as Error).message,
          })
        }
      }
      break
  }
  return bilan
}

/// Ecrit ou leve la marque `sans_enseignant`. Un echec est note dans le
/// bilan : la marque non posee repousse seulement l'echeance (le prochain
/// passage la posera), la marque non levee le sera au prochain passage.
async function ecrireMarque(
  service: RoomServiceClient,
  salle: string,
  metadonnees: string,
  marque: { depuis: number } | null,
  bilan: BilanFermeture,
): Promise<void> {
  try {
    await borne(
      service.updateRoomMetadata(salle, ecrireSansEnseignant(metadonnees, marque)),
      'marque sans enseignant',
    )
  } catch (e) {
    if (!introuvable(e)) {
      bilan.echecs.push(salle)
      console.error('marque sans enseignant non ecrite', {
        salle,
        erreur: (e as Error).message,
      })
    }
  }
}

/// Ce qu'a fait [surveillerSalles].
export interface BilanSurveillance {
  /// Les salles ouvertes chez LiveKit qui ont ete examinees.
  examinees: number
  /// Les salles dont les micros des eleves viennent d'etre fermes.
  microsFermes: number
  /// Les salles fermees pour tous.
  sallesFermees: number
  /// Les salles ou LiveKit a refuse ou n'a pas repondu.
  echecs: number
}

/// Le passage de la tache planifiee : parmi les [salles] que la base connait,
/// celles qui sont ouvertes chez LiveKit sont examinees une a une
/// ([tenirFermeture]). Une liste des salles ouvertes par serveur LiveKit, puis
/// seulement les salles ouvertes : une seance sans personne ne coute aucun
/// appel.
///
/// L'echec d'une salle n'arrete pas les autres.
export async function surveillerSalles(
  salles: readonly SalleASurveiller[],
  maintenantMs = Date.now(),
): Promise<BilanSurveillance> {
  const bilan: BilanSurveillance = { examinees: 0, microsFermes: 0, sallesFermees: 0, echecs: 0 }
  const parServeur = new Map<string, SalleASurveiller[]>()
  for (const s of salles) {
    const cle = `${s.provider} ${s.ws_url}`
    parServeur.set(cle, [...(parServeur.get(cle) ?? []), s])
  }
  for (const groupe of parServeur.values()) {
    let ouvertes: Set<string>
    try {
      const liste = await borne(serviceSalle(groupe[0]).listRooms(), 'liste des salles')
      ouvertes = new Set(liste.filter((r) => r.numParticipants > 0).map((r) => r.name))
    } catch (e) {
      bilan.echecs++
      console.error('liste des salles illisible', {
        serveur: groupe[0].ws_url,
        erreur: (e as Error).message,
      })
      continue
    }
    for (const s of groupe) {
      if (!ouvertes.has(s.room_name)) continue
      bilan.examinees++
      try {
        const r = await tenirFermeture(s, s.seance, { maintenantMs })
        if (r.action === 'fermer_micros' && r.fermes.length > 0) bilan.microsFermes++
        if (r.action === 'fermer_salle' && r.echecs.length === 0) bilan.sallesFermees++
        if (r.echecs.length > 0) bilan.echecs++
      } catch (e) {
        bilan.echecs++
        console.error('surveillance de la salle en echec', {
          salle: s.room_name,
          erreur: (e as Error).message,
        })
      }
    }
  }
  return bilan
}

/// Vrai quand ces metadonnees signees sont celles de celui qui conduit la
/// seance. Sert au webhook : le depart de l'enseignant fait repartir le delai
/// de zero.
export function conduitLaSeance(metadonnees: string | null | undefined): boolean {
  return enseignantPresent([{ identity: '', metadata: metadonnees }])
}
