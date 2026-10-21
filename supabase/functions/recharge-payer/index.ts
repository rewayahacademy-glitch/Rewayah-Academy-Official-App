// Ouvre la page de paiement du prestataire pour une recharge (FI-BR-06,
// guide Finance V4 §1.6 : `WEB_STRIPE` actif au lancement).
//
// 1. Avec le jeton de l'appelant, `recharge_payer` cree (ou rend, pour la
//    meme cle) la commande : seul le titulaire du foyer y arrive, et le
//    montant de chaque part a ete arrete par le serveur.
// 2. Si la commande attend deja le prestataire, sa page est rendue telle
//    quelle (reprise apres une coupure : jamais deux paiements).
// 3. Sinon, la session Checkout s'ouvre chez Stripe, idempotente par
//    l'identifiant de la commande, puis `recharge_attacher_session` (cle de
//    service) la note sur la commande, qui attend alors la confirmation.
//
// Rien n'est credite ici : seul le webhook signe (`stripe-webhook`) credite.
// Le retour du navigateur ramene a la page de resultat, qui relit l'etat.

import { clientAuthentifie, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import { clientStripe, creerSession, type LignePaiement, parametresSession, retourAutorise } from '../_shared/stripe.ts'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/// La page de paiement expire au bout de 30 minutes (minimum de Stripe) : une
/// commande abandonnee se lit ensuite « perimee », jamais « en cours ».
const DUREE_PAGE_S = 30 * 60

/// La marque que l'adresse de retour porte a la place de la commande.
const MARQUE_COMMANDE = 'COMMANDE_ID'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return refus('methode non autorisee', 405)

  const cleSecrete = Deno.env.get('STRIPE_SECRET_KEY')
  if (!cleSecrete) return refus('paiement indisponible', 503)

  const utilisateur = clientAuthentifie(requete)
  if (!utilisateur) return refus('authentification requise', 401)

  let corps: Record<string, unknown>
  try {
    const valeur: unknown = await requete.json()
    if (!valeur || typeof valeur !== 'object' || Array.isArray(valeur)) return refus('corps invalide')
    corps = valeur as Record<string, unknown>
  } catch {
    return refus('corps illisible')
  }
  const recapitulatif = typeof corps.recapitulatifId === 'string' ? corps.recapitulatifId : ''
  const cle = typeof corps.cle === 'string' ? corps.cle : ''
  const retourBase = typeof corps.retour === 'string' ? corps.retour : ''
  if (!UUID.test(recapitulatif) || !UUID.test(cle)) return refus('recapitulatif ou cle invalide')
  if (!retourBase.includes(MARQUE_COMMANDE) || !retourAutorise(retourBase, Deno.env.get('APP_ORIGINES'))) {
    return refus('adresse de retour refusee')
  }

  const { data, error } = await utilisateur.rpc('recharge_payer', {
    p_recapitulatif: recapitulatif,
    p_cle: cle,
  })
  if (error || !data || typeof data !== 'object') {
    const statut = error?.code === '42501' ? 403 : error?.code === 'P0002' ? 404 : 400
    return refus('recharge refusee', statut)
  }
  const commande = data as Record<string, unknown>
  const commandeId = String(commande.commandeId)
  const etat = String(commande.etat)

  if (etat === 'awaiting_confirmation' && typeof commande.urlPaiement === 'string') {
    return json({ commandeId, url: commande.urlPaiement })
  }
  if (etat !== 'preparing') {
    // Deja confirmee, echouee ou perimee : la page de resultat le dit.
    return json({ commandeId, url: null })
  }

  const { data: qui } = await utilisateur.auth.getUser()
  if (!qui?.user) return refus('authentification requise', 401)

  const total = commande.total as { devise: string }
  const lignes = (commande.lignesPaiement as LignePaiement[] | null) ?? []
  // L'application envoie l'adresse de sa page de resultat avec la marque
  // COMMANDE_ID a la place de la commande, qu'elle ne connait pas encore.
  const retour = retourBase.replace(MARQUE_COMMANDE, commandeId)

  let session
  try {
    session = await creerSession(
      clientStripe(cleSecrete),
      parametresSession({
        commandeId,
        reference: String(commande.reference),
        devise: total.devise,
        lignes,
        retour,
        libelle: (prenom) => `Rewayah Academy · ${prenom}`,
        expireA: Math.floor(Date.now() / 1000) + DUREE_PAGE_S,
      }),
      `recharge-${commandeId}`,
    )
  } catch (e) {
    console.error('session stripe refusee', { commandeId, erreur: (e as Error).message })
    return refus('paiement indisponible', 502)
  }

  const { error: attache } = await clientService().rpc('recharge_attacher_session', {
    p_commande: commandeId,
    p_titulaire: qui.user.id,
    p_session: session.id,
    p_url: session.url,
    p_environnement: session.environnement,
  })
  if (attache) {
    console.error('session non attachee', { commandeId, erreur: attache.message })
    return refus('paiement indisponible', 502)
  }
  return json({ commandeId, url: session.url })
})
