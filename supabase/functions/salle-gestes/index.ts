// Les gestes de l'enseignant sur un eleve, dans la salle (30/10/2026).
//
//   { session_id, eleve_id, geste }  ->  { applique }
//   geste : 'couper_micro' | 'couper_camera' | 'faire_sortir'
//
// Meme partage que `create-room-token` : la base decide, cette fonction
// applique. `autoriser_geste_salle()` verifie que l'appelant (lu dans SON
// jeton Supabase, jamais dans le corps) est l'enseignant effectif de cette
// seance, que l'eleve y est inscrit et que la salle est ouverte ; elle
// journalise le geste et enregistre la sortie. Ensuite seulement, l'API
// serveur LiveKit coupe la piste ou retire le participant.
//
// La readmission d'un eleve sorti ne passe pas ici : elle n'a rien a faire
// chez LiveKit (`readmettre_eleve_salle`, appelee par l'application).

import { appelant, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import { appliquerGeste, type GesteSalle, type RouteGeste, videoConfiguree } from '../_shared/livekit.ts'

const GESTES: readonly GesteSalle[] = ['couper_micro', 'couper_camera', 'faire_sortir']

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (!videoConfiguree()) {
    return refus('video non configuree', 503)
  }

  const compte = await appelant(requete)
  if (!compte) {
    return refus('authentification requise', 401)
  }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const seance = String(corps.session_id ?? '').trim()
  const eleve = String(corps.eleve_id ?? '').trim()
  const geste = String(corps.geste ?? '').trim() as GesteSalle
  if (!seance || !eleve || !GESTES.includes(geste)) {
    return refus('demande incomplete')
  }

  const { data, error } = await clientService().rpc('autoriser_geste_salle', {
    p_session_id: seance,
    p_profile_id: compte.id,
    p_cible: eleve,
    p_geste: geste,
  })
  if (error || !data) {
    // Le motif exact reste dans les logs, comme pour le jeton.
    console.error('autoriser_geste_salle refuse', { seance, geste, erreur: error?.message })
    return refus('geste refuse', 403)
  }

  try {
    const applique = await appliquerGeste(data as unknown as RouteGeste, geste)
    return json({ applique })
  } catch (e) {
    // Le geste est journalise et, pour une sortie, enregistre : le refus du
    // prochain jeton tient meme si LiveKit n'a pas repondu.
    console.error('geste LiveKit impossible', { seance, geste, erreur: (e as Error).message })
    return refus('serveur video indisponible', 502)
  }
})
