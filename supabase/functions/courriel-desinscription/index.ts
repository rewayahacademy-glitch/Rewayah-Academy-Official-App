// COURRIELS-1 : desinscription d'une categorie non essentielle, sans compte.
//
// Deux appels, tous deux en POST (un simple GET ne desinscrit jamais : les
// antivirus et les messageries ouvrent les liens d'un e-mail) :
// - le bouton de la page publique /fr/courriels/desinscription (formulaire,
//   champ `jeton`) : reponse 303 vers la meme page avec l'etat ;
// - la desinscription en un clic de Gmail et des autres (RFC 8058, en-tete
//   List-Unsubscribe-Post) : POST sur `?jeton=`, reponse 200.
// La RPC `courriel_desinscrire` est ouverte a anon ; on l'appelle avec la cle
// publique, jamais avec la cle de service.

import { createClient } from 'jsr:@supabase/supabase-js@2'

const PAGE = 'https://rewayahacademy.com/fr/courriels/desinscription'

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response(null, { status: 405, headers: { Allow: 'POST' } })
  const url = new URL(req.url)
  let jeton = url.searchParams.get('jeton')
  const type = req.headers.get('content-type') ?? ''
  const formulaire = type.includes('application/x-www-form-urlencoded') || type.includes('multipart/form-data')
  let unClic = false
  if (formulaire) {
    const f = await req.formData()
    unClic = f.get('List-Unsubscribe') === 'One-Click'
    jeton = (f.get('jeton') as string | null) ?? jeton
  }

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    auth: { persistSession: false },
  })
  const { data, error } = await db.rpc('courriel_desinscrire', { p_jeton: jeton ?? '' })
  const ok = !error && data?.ok === true

  if (unClic || !formulaire) return new Response(null, { status: ok ? 200 : 400 })
  const retour = new URL(PAGE)
  retour.searchParams.set('etat', ok ? 'ok' : 'invalide')
  if (ok && typeof data.categorie === 'string') retour.searchParams.set('categorie', data.categorie)
  return new Response(null, { status: 303, headers: { Location: retour.toString() } })
})
