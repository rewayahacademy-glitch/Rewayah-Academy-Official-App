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
//
// FERMETURE-SALLE (directeur, 11/11/2026, seconde moitie de SEC-1, journal
// D-018) : le meme passage, chaque minute, tient aussi la regle des salles.
// C'est la voie qui ne depend de la bonne foi d'aucun client, et elle ne
// demande aucune migration (la tache planifiee existe deja).
//
// 3. Les salles ouvertes chez LiveKit sont relues une a une
//    (`_shared/fermeture_salle.ts`) : enseignant parti depuis le delai de
//    grace, les micros des eleves sont fermes ; seance finie et enseignant
//    parti, la salle est fermee pour tous.
//
// Les deux travaux sont independants : l'echec de l'un n'empeche pas l'autre,
// et la reponse garde le statut des visites (c'est lui que la tache lit).

import { clientService, json, refus } from '../_shared/clients.ts'
import { estAbsent, lireSorties, porteOuverte } from '../_shared/coupure_observation.ts'
import {
  appliquerGeste,
  type BilanSurveillance,
  surveillerSalles,
  urlDe,
  videoConfiguree,
} from '../_shared/livekit.ts'
import { sallesASurveiller } from '../_shared/seance_salle.ts'

Deno.serve(async (req) => {
  if (req.method !== 'POST') return refus('methode', 405)
  if (!porteOuverte(req.headers.get('x-observation-secret'), Deno.env.get('OBSERVATION_COUPURE_SECRET'))) {
    return refus('acces refuse', 401)
  }

  const db = clientService()
  const [visites, salles] = await Promise.all([couperVisites(db), surveiller(db)])
  return json({ ...visites.corps, salles }, visites.statut)
})

/// Les visites d'observation echues (lot O1) : inchange, seulement range
/// dans une fonction pour que la surveillance des salles tourne a cote.
async function couperVisites(
  db: ReturnType<typeof clientService>,
): Promise<{ statut: number; corps: Record<string, unknown> }> {
  const { data, error } = await db.rpc('couper_visites_observation_echues', {
    p_ws_url_cloud: urlDe('cloud'),
    p_ws_url_self_hosted: urlDe('self_hosted'),
  })
  if (error) return { statut: 500, corps: { error: `coupure : ${error.message}` } }

  const sorties = lireSorties(data)
  if (sorties.length > 0 && !videoConfiguree()) {
    // Les visites sont closes en base ; seule la sortie LiveKit manque.
    return { statut: 503, corps: { error: 'video non configuree' } }
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
  return { statut: 200, corps: { coupures: sorties.length, sortis, absents, echecs: echecs.length } }
}

/// FERMETURE-SALLE : le passage sur les salles ouvertes. Jamais une erreur
/// pour l'appelant : ce qui ne passe pas est consigne, et le passage de la
/// minute suivante recommence.
async function surveiller(
  db: ReturnType<typeof clientService>,
): Promise<BilanSurveillance | null> {
  if (!videoConfiguree()) return null
  try {
    return await surveillerSalles(await sallesASurveiller(db))
  } catch (e) {
    console.error('surveillance des salles en echec', { erreur: (e as Error).message })
    return null
  }
}
