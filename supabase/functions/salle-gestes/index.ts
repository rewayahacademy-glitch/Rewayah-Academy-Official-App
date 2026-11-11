// Les gestes de l'enseignant sur un eleve, dans la salle (30/10/2026).
//
//   { session_id, eleve_id, geste }  ->  { applique }
//   geste : 'couper_micro' | 'couper_camera' | 'faire_sortir'
//         | 'faire_reciter' | 'terminer_recitation'
//
// GESTES-POINTEUR (directeur, 11/11/2026) : « Faire reciter ». Pendant qu'un
// eleve recite, le serveur ferme le micro de ses camarades (droit de publier
// retire chez LiveKit, jamais seulement a l'ecran), et le leur rend a la fin.
// Regles et raisons : `_shared/recitation.ts`.
//
//   faire_reciter       { session_id, eleve_id }   -> { applique, motif?, fermes, echecs }
//   terminer_recitation { session_id, eleve_id? }  -> { applique, rendus, echecs }
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
  type Fournisseur,
  type GesteSalle,
  ouvrirRecitation,
  recitantEnCours,
  type RouteGeste,
  type RouteSalle,
  terminerRecitation,
  videoConfiguree,
} from '../_shared/livekit.ts'

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
    // le serveur le lit dans la salle. Rien n'est change ni rendu a ce stade ;
    // la porte ci-dessous decide ensuite comme pour tout geste.
    try {
      const route = await routeDeLaSeance(seance)
      eleve = route ? (await recitantEnCours(route)) ?? '' : ''
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

/// La salle LiveKit d'une seance, telle que la base l'a figee a la premiere
/// emission de jeton, ou `null` (salle jamais ouverte). Lue sous la cle de
/// service, jamais rendue a l'appelant.
async function routeDeLaSeance(seance: string): Promise<RouteSalle | null> {
  const { data, error } = await clientService()
    .from('session_video_route')
    .select('provider, ws_url, room_name')
    .eq('session_id', seance)
    .maybeSingle()
  if (error) throw new Error(error.message)
  if (!data?.room_name || !data?.ws_url) return null
  return {
    provider: data.provider as Fournisseur,
    ws_url: String(data.ws_url),
    room_name: String(data.room_name),
  }
}
