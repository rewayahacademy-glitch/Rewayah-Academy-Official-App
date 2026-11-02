// Lot O1 (02/11/2026) : coupe, cote serveur, les visites d'observation
// echues. Appelee chaque minute par pg_cron (tache `observation-coupure`,
// migration 20261105500000), sur le modele de `courriels-envoi`. Ouverte sans
// JWT (config.toml) : la porte est le secret partage
// `OBSERVATION_COUPURE_SECRET`, en en-tete `x-observation-secret`, compare en
// temps constant. Sans ce secret, tout est refuse.
//
// 1. `couper_visites_observation_echues()` clot en base chaque visite de
//    tuteur dont la duree permise par la politique est atteinte, et rend la
//    route LiveKit des coupures recentes.
// 2. Chaque participant est retire de sa salle (`removeParticipant`) : un
//    jeton expire n'ejecte pas un participant deja connecte. Un participant
//    deja parti n'est pas une erreur.

import { clientService, json, refus } from '../_shared/clients.ts'
import { estAbsent, lireSorties, porteOuverte } from '../_shared/coupure_observation.ts'
import { appliquerGeste, urlDe, videoConfiguree } from '../_shared/livekit.ts'

Deno.serve(async (req) => {
  if (req.method !== 'POST') return refus('methode', 405)
  if (!porteOuverte(req.headers.get('x-observation-secret'), Deno.env.get('OBSERVATION_COUPURE_SECRET'))) {
    return refus('acces refuse', 401)
  }

  const db = clientService()
  const { data, error } = await db.rpc('couper_visites_observation_echues', {
    p_ws_url_cloud: urlDe('cloud'),
    p_ws_url_self_hosted: urlDe('self_hosted'),
  })
  if (error) return refus(`coupure : ${error.message}`, 500)

  const sorties = lireSorties(data)
  if (sorties.length > 0 && !videoConfiguree()) {
    // Les visites sont closes en base ; seule la sortie LiveKit manque.
    return refus('video non configuree', 503)
  }

  let sortis = 0
  let absents = 0
  const echecs: string[] = []
  for (const s of sorties) {
    try {
      if (await appliquerGeste(s, 'faire_sortir')) sortis++
      else absents++
    } catch (e) {
      const message = String((e as Error).message)
      if (estAbsent(message)) {
        absents++
      } else {
        console.error('sortie impossible', { visite: s.visite_id, erreur: message })
        echecs.push(s.visite_id)
      }
    }
  }
  return json({ coupures: sorties.length, sortis, absents, echecs: echecs.length })
})
