// Ce que toute fonction Edge de ce projet partage.
//
// Regle non negociable de l'etape 1, rappelee ici parce que c'est le seul
// endroit du depot ou la cle de service existe : **une fonction qui emploie la
// cle de service reverifie l'autorisation metier explicitement.** La cle
// contourne la RLS, elle ne remplace pas le controle.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'

/// Les en-tetes CORS. L'application tourne aussi en PWA (ADR-008), donc les
/// appels viennent d'un navigateur.
export const enTetesCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

/// Une reponse JSON, avec les en-tetes qui vont bien.
export function json(corps: unknown, statut = 200): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...enTetesCors, 'Content-Type': 'application/json' },
  })
}

/// Un refus. Le message reste court et ne dit jamais pourquoi une valeur est
/// invalide : « code inconnu » et « code expire » se distinguent pour l'usager
/// legitime, pas pour celui qui essaie des codes au hasard.
export function refus(message: string, statut = 400): Response {
  return json({ error: message }, statut)
}

/// Le client qui detient la cle de service. Jamais expose au navigateur.
export function clientService(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!url || !cle) {
    throw new Error('configuration absente : SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY')
  }
  return createClient(url, cle, { auth: { persistSession: false } })
}

/// L'appelant, lu depuis son propre jeton et non depuis le corps de la requete.
///
/// Renvoie `null` quand aucun jeton exploitable n'accompagne l'appel.
export async function appelant(requete: Request): Promise<{ id: string } | null> {
  const entete = requete.headers.get('Authorization')
  if (!entete?.startsWith('Bearer ')) {
    return null
  }
  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !cle) {
    throw new Error('configuration absente : SUPABASE_URL ou SUPABASE_ANON_KEY')
  }

  const client = createClient(url, cle, {
    global: { headers: { Authorization: entete } },
    auth: { persistSession: false },
  })
  const { data, error } = await client.auth.getUser()
  if (error || !data.user) {
    return null
  }
  return { id: data.user.id }
}

/// Client qui conserve le JWT de l'appelant pour les RPC autorisees aux comptes.
export function clientAuthentifie(requete: Request): SupabaseClient | null {
  const entete = requete.headers.get('Authorization')
  if (!entete?.startsWith('Bearer ')) {
    return null
  }
  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !cle) {
    throw new Error('configuration absente : SUPABASE_URL ou SUPABASE_ANON_KEY')
  }
  return createClient(url, cle, {
    global: { headers: { Authorization: entete } },
    auth: { persistSession: false },
  })
}
