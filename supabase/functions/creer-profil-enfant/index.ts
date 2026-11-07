// Cree le compte, le profil et la fiche eleve d'un enfant du foyer.
//
// Pourquoi une fonction Edge et pas une RPC : la ligne `profiles` d'un enfant
// reference `auth.users`, et creer un utilisateur d'authentification demande la
// cle de service. Tout le reste, y compris la reverification que l'appelant est
// bien le tuteur du foyer vise, vit dans `public.creer_profil_enfant()`.
//
// L'enfant n'a ni courriel utilisable ni mot de passe connu de lui : son compte
// existe pour porter une identite, pas pour se connecter. Il entre par un code
// d'appairage, puis par le jeton d'appareil (ADR-010).

import { appelant, clientAuthentifie, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }

  const tuteur = await appelant(requete)
  if (!tuteur) {
    return refus('session absente', 401)
  }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const prenom = String(corps.first_name ?? '').trim()
  const nom = String(corps.last_name ?? '').trim()
  const age = Number(corps.age)
  const niveau = corps.level == null ? null : String(corps.level)

  if (!prenom || !nom || !Number.isInteger(age)) {
    return refus('prenom, nom et age sont requis')
  }

  // MINEUR-FANTOME (directeur, 07/11/2026) : un profil cree ici est un
  // mineur ; meme refus, mot pour mot, que public.creer_profil_enfant
  // (20261110340000), que le client reconnait par « age adulte ».
  if (age >= 18) {
    return refus('age adulte : un profil eleve de 18 ans ou plus ne se cree pas ici ; pour soi-meme, creer mon profil eleve')
  }

  // MINEUR-FANTOME B : le genre est obligatoire. Valeurs de l'enum
  // public.gender en production (releve du pilote, 07/11/2026 07:50 UTC) :
  // male, female. Il voyage dans app_metadata seulement (jamais
  // user_metadata, que l'utilisateur peut ecrire), ou la RPC le lit.
  const genre = corps.gender == null ? '' : String(corps.gender)
  if (genre !== 'male' && genre !== 'female') {
    return refus('genre_requis')
  }

  // Le domaine n'est pas invente ici : il vient de la configuration, pour que
  // l'operateur choisisse un domaine qu'il maitrise et qui ne recevra jamais de
  // courrier.
  const domaine = Deno.env.get('STUDENT_EMAIL_DOMAIN')
  if (!domaine) {
    return refus('configuration absente : STUDENT_EMAIL_DOMAIN', 500)
  }

  const service = clientService()
  const clientTuteur = clientAuthentifie(requete)
  if (!clientTuteur) {
    return refus('session absente', 401)
  }
  const identifiant = crypto.randomUUID()
  const courriel = `eleve-${identifiant}@${domaine}`

  const { data: compte, error: erreurCompte } = await service.auth.admin.createUser({
    email: courriel,
    email_confirm: false,
    password: crypto.randomUUID() + crypto.randomUUID(),
    app_metadata: { child_of: tuteur.id, gender: genre },
  })
  if (erreurCompte || !compte.user) {
    return refus('creation du compte impossible', 500)
  }

  const { data: profil, error: erreurProfil } = await clientTuteur.rpc('creer_profil_enfant', {
    p_auth_user_id: compte.user.id,
    p_guardian_id: tuteur.id,
    p_first_name: prenom,
    p_last_name: nom,
    p_age: age,
    p_level: niveau,
  })

  if (erreurProfil) {
    // Compensation : sans elle, un refus metier laisserait derriere lui un
    // utilisateur d'authentification orphelin, que plus rien ne rattacherait a
    // un foyer et que personne ne verrait.
    await service.auth.admin.deleteUser(compte.user.id)
    return refus(erreurProfil.message ?? 'creation du profil refusee', 403)
  }

  return json({ profile_id: compte.user.id, immutable_id: profil?.immutable_id ?? null })
})
