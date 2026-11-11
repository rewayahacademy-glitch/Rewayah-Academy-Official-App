// L'endpoint unique des webhooks LiveKit.
//
// Sur LiveKit Cloud il se configure au tableau de bord, en self-host dans
// `livekit.yaml`. Le code est identique dans les deux cas, et c'est voulu :
// c'est ce qui rend la bascule de fournisseur invisible cote produit.
//
// Pourquoi les webhooks et non le client :
//
// La section 26 de la specification l'impose, et l'audit initial le disait deja
// (section 265) : l'horodatage d'un webhook est SERVEUR. Il n'est pas
// falsifiable par un eleve qui voudrait s'inventer une presence, il ne coute
// aucune bande passante au telephone, et il survit a la mise en arriere-plan de
// l'application -- trois choses qu'un heartbeat client ne sait pas faire.
//
// Ce que cette fonction refuse de croire :
//
//   * qu'un webhook arrive une seule fois. La section 29 est explicite : ce
//     n'est ni ordonne, ni garanti sans doublon. L'idempotence est portee par
//     la cle primaire de `livekit_webhook_deliveries`, donc par la base, pas
//     par une condition ici ;
//   * qu'un echec doive etre signale. Repondre autre chose que 200 declenche
//     un renvoi, et renvoyer un doublon ne le rend pas moins doublon. Seule
//     une signature invalide merite un refus -- ce n'est pas une panne, c'est
//     quelqu'un qui fabrique des presences.
//
// `verify_jwt` est a **false** pour cette fonction, et c'est obligatoire :
// LiveKit ne porte pas de jeton Supabase. Son authentification est sa propre
// signature, verifiee ci-dessous. C'est le seul cas du depot avec
// `session-enfant`, et pour la meme raison : l'appelant ne peut pas avoir de
// session.

import { clientService, json } from '../_shared/clients.ts'
import {
  type Fournisseur,
  retablirPublication,
  type RouteSalle,
  urlDe,
  verifierWebhookSigne,
} from '../_shared/livekit.ts'
import { entrerArchiveSiEgressTermine } from '../_shared/r2/ingestion_archive.ts'

Deno.serve(async (requete: Request) => {
  if (requete.method !== 'POST') {
    return new Response('methode non autorisee', { status: 405 })
  }

  const corps = await requete.text()

  let evenement: Record<string, unknown>
  let fournisseur: Fournisseur
  try {
    ;({ evenement, fournisseur } = await verifierWebhookSigne(
      corps,
      requete.headers.get('Authorization'),
    ))
  } catch (e) {
    console.error('webhook refuse', { erreur: (e as Error).message })
    return new Response('signature invalide', { status: 401 })
  }

  const type = String(evenement.event ?? '')
  const salle = (evenement.room as Record<string, unknown> | undefined)?.name
  const participant = evenement.participant as Record<string, unknown> | undefined

  // L'identite LiveKit EST le `profile_id` : c'est `autoriser_jeton_video()`
  // qui l'y a mise, et rien d'autre ne peut la choisir puisque le jeton est
  // signe cote serveur. Un participant sans identite exploitable est enregistre
  // pour l'exploitation mais n'ecrit aucune presence.
  const identite = participant?.identity ? String(participant.identity) : null
  const profil = identite && /^[0-9a-f-]{36}$/i.test(identite) ? identite : null

  // LiveKit horodate en secondes ; `createdAt` peut arriver en chaine.
  const horodatage = Number(evenement.createdAt ?? 0)
  const survenuLe = horodatage > 0
    ? new Date(horodatage * 1000).toISOString()
    : new Date().toISOString()

  // `id` est l'identifiant d'evenement LiveKit. C'est lui qui fait
  // l'idempotence ; sans lui, un repli sur le triplet (type, salle, instant)
  // vaut mieux que rien, mais deux evenements identiques a la meme seconde
  // fusionneraient. On le dit dans le journal plutot que de le taire.
  const identifiant = evenement.id
    ? String(evenement.id)
    : `sans_id:${type}:${salle ?? '?'}:${identite ?? '?'}:${horodatage}`

  // K4 n° 13 (30/10/2026) : pour `track_published` et `track_unpublished`,
  // la piste en quelques champs (jamais le flux), afin de relire une seance :
  // l'image de l'eleve est-elle partie ? La base y ajoute l'identite.
  const track = evenement.track as Record<string, unknown> | undefined
  const piste = track
    ? {
      sid: track.sid ? String(track.sid) : null,
      type: track.type ? String(track.type) : null,
      source: track.source ? String(track.source) : null,
      muted: track.muted === true,
      simulcast: track.simulcast === true,
      width: Number(track.width ?? 0) || null,
      height: Number(track.height ?? 0) || null,
    }
    : null

  const service = clientService()
  const { data, error } = await service.rpc('enregistrer_webhook_livekit', {
    p_event_id: identifiant,
    p_event_type: type,
    p_room_name: salle ? String(salle) : null,
    p_profile_id: profil,
    p_server_ts: survenuLe,
    p_detail: {
      sans_id_livekit: !evenement.id,
      identite_non_exploitable: identite !== null && profil === null,
      ...(piste ? { piste } : {}),
    },
  })

  if (error) {
    // Une panne de base, elle, merite un renvoi : l'evenement n'est pas encore
    // enregistre, donc le rejouer n'a rien d'un doublon.
    console.error('enregistrement du webhook impossible', {
      identifiant,
      erreur: error.message,
    })
    return new Response('enregistrement impossible', { status: 500 })
  }

  // `egress_ended` annonce qu'une archive audio a ete deposee dans le seau R2.
  // Jusqu'ici l'evenement etait journalise puis ignore, faute de producteur
  // pour `session_recordings`. L'entree des metadonnees vit dans son propre
  // module : ce fichier reste la porte des webhooks, pas la place ou le
  // stockage se decide.
  //
  // Elle ne peut pas faire echouer la reponse. Un 200 est deja du a LiveKit
  // pour l'evenement de presence traite plus haut, et repondre autre chose
  // declencherait un renvoi de l'evenement ENTIER -- donc un doublon de
  // presence pour rattraper une archive. Ce qui ne passe pas ici est consigne
  // et reste rattrapable a la main.
  const archive = await entrerArchiveSiEgressTermine(service, type, evenement)

  // MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1) : a chaque
  // entree, si l'enseignant est dans la salle, les eleves dont le jeton a ete
  // signe sans droit de publier le retrouvent aussitot.
  //
  // A CHAQUE entree, et pas seulement a celle de l'enseignant : un eleve qui
  // a demande son jeton juste avant l'enseignant et entre juste apres lui
  // arrive differe dans une salle ou l'enseignant est deja ; c'est sa propre
  // entree qui le retablit. La fonction lit l'etat de la salle, jamais
  // l'ordre des evenements : un webhook en double ou en retard ne change rien.
  //
  // Meme regle que l'archive ci-dessus : un echec ici est consigne et ne
  // change pas la reponse. Le filet (`create-room-token`, action
  // `retablir_publication`, demande par le client) rattrape.
  let publication: { retablis: number; echecs: number } | null = null
  // GESTES-POINTEUR (11/11/2026) : aussi a chaque SORTIE. Si l'eleve qui
  // recite ou l'enseignant quitte la salle, la recitation se termine
  // d'elle-meme et les micros fermes pour elle sont rendus
  // (`retablirPublication` lit l'etat de la salle, `_shared/recitation.ts`).
  // Sans recitation, une sortie ne change rien a la regle ci-dessus.
  if ((type === 'participant_joined' || type === 'participant_left') && salle) {
    try {
      const bilan = await retablirPublication(
        await routeDeLaSalle(service, String(salle), fournisseur),
      )
      publication = { retablis: bilan.retablis.length, echecs: bilan.echecs.length }
    } catch (e) {
      console.error('retablissement de la publication en echec (webhook)', {
        salle,
        erreur: (e as Error).message,
      })
    }
  }

  return json({ applique: data === true, archive, publication })
})

/// La route LiveKit de la salle annoncee : celle que la base a figee a la
/// premiere emission de jeton (`session_video_route`). Si elle ne se relit
/// pas, le fournisseur dont le trousseau a signe ce webhook et son adresse de
/// configuration : c'est la meme salle, et rendre un micro ne doit pas
/// dependre d'une lecture de plus.
async function routeDeLaSalle(
  service: ReturnType<typeof clientService>,
  salle: string,
  fournisseur: Fournisseur,
): Promise<RouteSalle> {
  try {
    const { data, error } = await service
      .from('session_video_route')
      .select('provider, ws_url, room_name')
      .eq('room_name', salle)
      .maybeSingle()
    if (error) {
      console.error('route de la salle illisible', { salle, erreur: error.message })
    } else if (data?.ws_url && (data.provider === 'cloud' || data.provider === 'self_hosted')) {
      return { provider: data.provider, ws_url: String(data.ws_url), room_name: salle }
    }
  } catch (e) {
    console.error('route de la salle en echec', { salle, erreur: (e as Error).message })
  }
  return { provider: fournisseur, ws_url: urlDe(fournisseur), room_name: salle }
}
