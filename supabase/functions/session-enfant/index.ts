// Ouvre une session pour l'appareil d'un enfant.
//
// Deux entrees, une seule sortie :
//
//   { code, device_fingerprint, platform }  -> premier appairage
//   { device_token }                        -> reouverture
//
// Cette fonction est la seule du produit qui accepte un appel **sans session**,
// par construction : l'appareil qui presente un code n'en a pas encore.
//
// Ce qu'elle ne fait pas : elle ne rend jamais de jeton d'acces tout fait. Elle
// rend un jeton a usage unique que le client echange lui-meme, pour qu'aucun
// jeton d'acces ne transite dans un corps de reponse qu'un intermediaire
// pourrait journaliser.
//
// Sur la force brute : le code fait six caracteres pris dans un alphabet de 32,
// soit environ 1,07 milliard de combinaisons, et vit dix minutes. Un attaquant
// a mille essais par seconde couvrirait 6 * 10^5 combinaisons dans la fenetre,
// soit environ 0,06 % de l'espace. Aucune limitation de debit n'est donc posee
// ici ; si la duree de validite venait a s'allonger, il faudrait en ajouter une.

import { clientService, enTetesCors, json, refus } from '../_shared/clients.ts'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const service = clientService()

  let profilId: string | null = null
  let jetonAppareil: string | null = null

  if (typeof corps.code === 'string' && corps.code.trim() !== '') {
    const empreinte = String(corps.device_fingerprint ?? '').trim()
    const plateforme = String(corps.platform ?? '').trim()
    if (!empreinte || !['windows', 'android', 'ios', 'web'].includes(plateforme)) {
      return refus('appareil non decrit')
    }

    const { data, error } = await service.rpc('consommer_code_appairage', {
      p_code: corps.code,
      p_device_fingerprint: empreinte,
      p_platform: plateforme,
    })
    if (error || !data || data.length === 0) {
      return refus(error?.message ?? 'code refuse', 403)
    }
    profilId = data[0].profile_id
    jetonAppareil = data[0].device_token
  } else if (typeof corps.device_token === 'string' && corps.device_token !== '') {
    const { data, error } = await service.rpc('profil_du_jeton_appareil', {
      p_token: corps.device_token,
    })
    if (error || !data) {
      return refus(error?.message ?? 'jeton refuse', 403)
    }
    profilId = data as string
    // Le jeton ne change pas a la reouverture : il n'est rendu qu'a l'appairage.
    jetonAppareil = null
  } else {
    return refus('ni code ni jeton')
  }

  if (!profilId) {
    return refus('profil introuvable', 403)
  }

  const { data: compte, error: erreurCompte } = await service.auth.admin.getUserById(profilId)
  if (erreurCompte || !compte.user?.email) {
    return refus('compte introuvable', 500)
  }

  const { data: lien, error: erreurLien } = await service.auth.admin.generateLink({
    type: 'magiclink',
    email: compte.user.email,
  })
  if (erreurLien || !lien.properties?.hashed_token) {
    return refus('session impossible', 500)
  }

  const { data: profil } = await service
    .from('profiles')
    .select('first_name')
    .eq('id', profilId)
    .maybeSingle()

  return json({
    profile_id: profilId,
    first_name: profil?.first_name ?? '',
    token_hash: lien.properties.hashed_token,
    ...(jetonAppareil ? { device_token: jetonAppareil } : {}),
  })
})
