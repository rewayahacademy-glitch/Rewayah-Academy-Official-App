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
    email_confirm: true,
    password: crypto.randomUUID() + crypto.randomUUID(),
    user_metadata: { cree_par: tuteur.id },
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
