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
import { verifierWebhook } from '../_shared/livekit.ts'
import { entrerArchiveSiEgressTermine } from '../_shared/r2/ingestion_archive.ts'

Deno.serve(async (requete: Request) => {
  if (requete.method !== 'POST') {
    return new Response('methode non autorisee', { status: 405 })
  }

  const corps = await requete.text()

  let evenement: Record<string, unknown>
  try {
    evenement = await verifierWebhook(corps, requete.headers.get('Authorization'))
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

  return json({ applique: data === true, archive })
})
