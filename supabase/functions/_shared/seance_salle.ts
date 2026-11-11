// FERMETURE-SALLE (directeur, 11/11/2026, D-018) : ce que la base sait de la
// seance d'une salle LiveKit.
//
// Lectures seules, sous la cle de service (ces tables n'ont aucune policy :
// « personne, sauf la cle de service », migration 0010). Rien n'est rendu a
// un appelant : ces valeurs ne servent qu'a decider de fermer ou non une
// salle (`fermeture_salle.ts`).
//
// Aucune migration : les tables et le reglage existent deja
// (`session_video_route`, `sessions`, `app_config.grace_after_end_minutes`,
// le meme reglage que la porte d'entree de `autoriser_jeton_video`).
//
// **Une lecture qui echoue ne ferme jamais rien** : elle rend `null` ou une
// liste vide, et la salle reste comme elle est.

import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import {
  lireDepassement,
  lireSallesASurveiller,
  lireSeance,
  type SalleASurveiller,
  type SeanceVue,
} from './fermeture_salle.ts'
import type { Fournisseur, RouteSalle } from './livekit.ts'

/// Le depassement autorise apres la fin prevue (`grace_after_end_minutes`),
/// en minutes. Illisible : la valeur par defaut de la base (15).
export async function depassementAutorise(service: SupabaseClient): Promise<number> {
  try {
    const { data, error } = await service
      .from('app_config')
      .select('value')
      .eq('key', 'grace_after_end_minutes')
      .maybeSingle()
    if (error) {
      console.error('depassement autorise illisible', { erreur: error.message })
      return lireDepassement(undefined)
    }
    return lireDepassement(data?.value)
  } catch (e) {
    console.error('depassement autorise en echec', { erreur: (e as Error).message })
    return lireDepassement(undefined)
  }
}

/// La salle d'une seance et ce que la base sait d'elle, par le nom de la
/// salle LiveKit ([salle]) ou par la seance ([seanceId]). `route` est `null`
/// si aucune salle n'a ete ouverte ; `seance` est `null` si elle ne se lit
/// pas.
export async function seanceDeLaSalle(
  service: SupabaseClient,
  cle: { salle: string } | { seanceId: string },
): Promise<{ route: RouteSalle | null; seance: SeanceVue | null }> {
  try {
    const requete = service
      .from('session_video_route')
      .select('provider, ws_url, room_name, sessions!inner(status, session_type, ended_at, deleted_at)')
    const { data, error } = await ('salle' in cle
      ? requete.eq('room_name', cle.salle)
      : requete.eq('session_id', cle.seanceId)).maybeSingle()
    if (error || !data) {
      if (error) console.error('seance de la salle illisible', { erreur: error.message })
      return { route: null, seance: null }
    }
    const l = data as Record<string, unknown>
    const route = typeof l.ws_url === 'string' && l.ws_url !== '' &&
        typeof l.room_name === 'string' && l.room_name !== '' &&
        (l.provider === 'cloud' || l.provider === 'self_hosted')
      ? { provider: l.provider as Fournisseur, ws_url: l.ws_url, room_name: l.room_name }
      : null
    const seance = lireSeance(
      Array.isArray(l.sessions) ? l.sessions[0] : l.sessions,
      await depassementAutorise(service),
    )
    return { route, seance }
  } catch (e) {
    console.error('seance de la salle en echec', { erreur: (e as Error).message })
    return { route: null, seance: null }
  }
}

/// Les heures pendant lesquelles une salle peut encore etre ouverte apres la
/// fin prevue de sa seance : au-dela, la tache planifiee ne la cherche plus.
const HEURES_APRES_LA_FIN = 12

/// Les salles que la tache planifiee doit examiner : celles des seances dont
/// la fin prevue n'est pas passee depuis plus de douze heures et dont la
/// porte a pu s'ouvrir (debut dans moins d'une heure). Les seances a venir
/// plus tard et les vieilles seances n'ont personne en salle.
export async function sallesASurveiller(
  service: SupabaseClient,
  maintenantMs = Date.now(),
): Promise<SalleASurveiller[]> {
  try {
    const { data, error } = await service
      .from('session_video_route')
      .select('provider, ws_url, room_name, sessions!inner(status, session_type, started_at, ended_at, deleted_at)')
      .gte('sessions.ended_at', new Date(maintenantMs - HEURES_APRES_LA_FIN * 3_600_000).toISOString())
      .lte('sessions.started_at', new Date(maintenantMs + 3_600_000).toISOString())
      .limit(1000)
    if (error) {
      console.error('salles a surveiller illisibles', { erreur: error.message })
      return []
    }
    return lireSallesASurveiller(data, await depassementAutorise(service))
  } catch (e) {
    console.error('salles a surveiller en echec', { erreur: (e as Error).message })
    return []
  }
}
