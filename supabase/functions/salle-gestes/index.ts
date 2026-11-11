// Les gestes de l'enseignant sur un eleve, dans la salle (30/10/2026).
//
//   { session_id, eleve_id, geste }  ->  { applique }
//   geste : 'couper_micro' | 'couper_camera' | 'faire_sortir'
//         | 'faire_reciter' | 'terminer_recitation'
//
// GESTES-POINTEUR (directeur, 11/11/2026) : « Faire reciter ». Pendant qu'un
// eleve recite, le serveur ferme le micro de ses camarades (droit retire chez
// LiveKit, jamais seulement a l'ecran), et le leur rend a la fin.
// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : le micro seul ; leur camera
// reste, si leur propre jeton la leur donne. `fermes` compte les camarades
// dont les droits viennent d'etre regles.
// Regles et raisons : `_shared/recitation.ts`.
//
//   faire_reciter       { session_id, eleve_id }   -> { applique, motif?, fermes, echecs }
//   terminer_recitation { session_id, eleve_id? }  -> { applique, rendus, echecs }
//
// `terminer_recitation` sans `eleve_id` (page de l'enseignant rechargee) :
// la porte de la salle (`autoriser_jeton_video`) verifie d'abord que
// l'appelant conduit la seance, AVANT de lire qui recite ; un autre compte
// recoit 403, recitation en cours ou non (revue du garde-cap, B2).
//
// La porte reste `autoriser_geste_salle()` : enseignant effectif, eleve
// inscrit, salle ouverte. Elle ne connait que trois gestes ; la recitation y
// passe sous `couper_micro` (c'est bien ce que le serveur fait aux
// camarades), avec le recitant pour cible. Le journal d'acces porte donc
// `salle_geste_couper_micro` pour une recitation : dette notee dans
// `docs/current/salle/JOURNAL-DECISIONS.md` (D-014), une migration additive
// lui donnerait son nom.
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
import {
  appliquerGeste,
  type GesteSalle,
  ouvrirRecitation,
  recitantEnCours,
  type RouteGeste,
  type RouteSalle,
  terminerRecitation,
  urlDe,
  videoConfiguree,
} from '../_shared/livekit.ts'
import { ROLE_QUI_CONDUIT } from '../_shared/publication_differee.ts'

const GESTES: readonly GesteSalle[] = ['couper_micro', 'couper_camera', 'faire_sortir']

/// GESTES-POINTEUR : les deux gestes de la recitation.
const FAIRE_RECITER = 'faire_reciter'
const TERMINER_RECITATION = 'terminer_recitation'
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

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
  let eleve = String(corps.eleve_id ?? '').trim()
  const demande = String(corps.geste ?? '').trim()
  const recitation = demande === FAIRE_RECITER || demande === TERMINER_RECITATION

  if (demande === TERMINER_RECITATION && !eleve && UUID.test(seance)) {
    // L'application de l'enseignant ne sait plus qui recite (page rechargee) :
    // le serveur le lit dans la salle.
    //
    // Revue du garde-cap du 11/11/2026 (B2) : **l'autorisation passe avant
    // toute lecture.** La porte des gestes exige une cible, que l'on ne
    // connait pas encore ; c'est donc la porte de la salle
    // (`autoriser_jeton_video`, la meme que `create-room-token`) qui dit
    // d'abord si l'appelant conduit cette seance (role `teacher` : l'enseignant
    // effectif, remplacant compris). Pour tout autre compte : le meme 403 que
    // la porte des gestes, qu'une recitation soit en cours ou non, et ni la
    // route ni LiveKit ne sont lus. Aucun jeton n'est signe ici. La porte des
    // gestes decide ensuite, avec la vraie cible, comme pour tout geste.
    const { data: droit, error: refusDroit } = await clientService().rpc('autoriser_jeton_video', {
      p_session_id: seance,
      p_profile_id: compte.id,
      p_ws_url_cloud: urlDe('cloud'),
      p_ws_url_self_hosted: urlDe('self_hosted'),
    })
    const conduit = !refusDroit && droit !== null &&
      (droit as { role?: unknown }).role === ROLE_QUI_CONDUIT
    if (!conduit) {
      console.error('terminer_recitation refuse avant lecture', { seance, erreur: refusDroit?.message })
      return refus('geste refuse', 403)
    }
    try {
      const route = droit as unknown as RouteSalle
      eleve = route.room_name && route.ws_url ? (await recitantEnCours(route)) ?? '' : ''
    } catch (e) {
      console.error('recitation illisible', { seance, erreur: (e as Error).message })
      return refus('serveur video indisponible', 502)
    }
    if (!eleve) {
      // Aucune recitation en cours : rien a terminer.
      return json({ applique: false, rendus: 0, echecs: 0 })
    }
  }

  // La porte ne connait que ses trois gestes : la recitation y passe sous
  // `couper_micro`, avec le recitant pour cible (voir l'en-tete).
  const geste = (recitation ? 'couper_micro' : demande) as GesteSalle
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
    console.error('autoriser_geste_salle refuse', { seance, geste: demande, erreur: error?.message })
    return refus('geste refuse', 403)
  }

  try {
    if (demande === FAIRE_RECITER) {
      const bilan = await ouvrirRecitation(data as unknown as RouteGeste)
      return json({
        applique: bilan.applique,
        motif: bilan.motif ?? null,
        fermes: bilan.fermes.length,
        echecs: bilan.echecs.length,
      })
    }
    if (demande === TERMINER_RECITATION) {
      const bilan = await terminerRecitation(data as unknown as RouteGeste)
      if (bilan.echecs.length > 0) {
        // Un droit n'a pas pu etre rendu : l'enseignant doit le savoir et
        // recommencer (le filet des eleves reessaie aussi de son cote).
        return refus('serveur video indisponible', 502)
      }
      return json({ applique: bilan.applique, rendus: bilan.rendus.length, echecs: 0 })
    }
    const applique = await appliquerGeste(data as unknown as RouteGeste, geste)
    return json({ applique })
  } catch (e) {
    // Le geste est journalise et, pour une sortie, enregistre : le refus du
    // prochain jeton tient meme si LiveKit n'a pas repondu.
    console.error('geste LiveKit impossible', { seance, geste: demande, erreur: (e as Error).message })
    return refus('serveur video indisponible', 502)
  }
})
