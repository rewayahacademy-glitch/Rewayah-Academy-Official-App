// FN-115c (pilote, 02/11/2026) : le remboursement decide par la direction,
// envoye au prestataire. Decision du directeur du 01/11/2026 (point 7) :
// « Le serveur y propose le montant juste ; la direction confirme ;
// l'application rembourse par le prestataire. »
//
// 1. Avec le jeton de l'appelant, `remboursement_a_envoyer` relit la demande
//    deja confirmee (`remboursement_confirmer`, plafonnee au montant propose
//    par le serveur) : la direction seule y arrive. Aucun montant ne vient du
//    corps de la requete.
// 2. Le remboursement part chez Stripe, idempotent par la demande : deux
//    envois (double clic, reprise apres coupure) n'en font qu'un.
// 3. `remboursement_resultat_stripe` (cle de service) note l'identifiant du
//    remboursement, ou l'echec, qui libere le paiement pour une nouvelle
//    demande.
//
// Rien n'est rendu aux ecritures ici : seul le webhook signe
// (`charge.refunded`) le fait, en visant le profil retrouve par cet
// identifiant.

import { clientAuthentifie, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import { clientStripe, parametresRemboursementDirection } from '../_shared/stripe.ts'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return refus('methode non autorisee', 405)

  const cleSecrete = Deno.env.get('STRIPE_SECRET_KEY')
  if (!cleSecrete) return refus('remboursement indisponible', 503)

  const utilisateur = clientAuthentifie(requete)
  if (!utilisateur) return refus('authentification requise', 401)

  let demandeId = ''
  try {
    const valeur: unknown = await requete.json()
    if (valeur && typeof valeur === 'object' && !Array.isArray(valeur)) {
      const d = (valeur as Record<string, unknown>).demandeId
      demandeId = typeof d === 'string' ? d : ''
    }
  } catch {
    return refus('corps illisible')
  }
  if (!UUID.test(demandeId)) return refus('demande invalide')

  const { data, error } = await utilisateur.rpc('remboursement_a_envoyer', { p_demande: demandeId })
  if (error) return refus('remboursement refuse', error.code === '42501' ? 403 : 400)
  const ligne = (Array.isArray(data) ? data[0] : null) as Record<string, unknown> | null
  if (!ligne) return refus('demande inconnue', 404)
  const etat = String(ligne.etat)
  // Deja envoyee ou soldee : rien a refaire ; un echec se redemande.
  if (etat !== 'confirmee') return json({ demandeId, etat })
  const paiement = typeof ligne.paiement === 'string' ? ligne.paiement : ''
  const montant = Number(ligne.montant_mineur)
  if (!paiement || !Number.isInteger(montant) || montant <= 0) return refus('demande incomplete', 409)

  const { params, cle } = parametresRemboursementDirection({
    demandeId,
    paiement,
    montant,
    profil: String(ligne.profil),
  })
  let remboursementId: string | null = null
  let erreur: string | null = null
  try {
    const r = await clientStripe(cleSecrete).refunds.create(params, { idempotencyKey: cle })
    remboursementId = r.id
  } catch (e) {
    erreur = (e as Error).message
    console.error('remboursement stripe refuse', { demandeId, erreur })
  }

  const { data: issue, error: note } = await clientService().rpc('remboursement_resultat_stripe', {
    p_demande: demandeId,
    p_remboursement: remboursementId,
    p_erreur: erreur,
  })
  if (note) {
    // Le remboursement est parti mais la base ne l'a pas note : le webhook le
    // rendra quand meme (au prorata), et un nouvel envoi de la meme demande
    // retombera sur le meme remboursement (idempotence de Stripe).
    console.error('remboursement non note', { demandeId, remboursementId, erreur: note.message })
    return refus('remboursement a verifier', 502)
  }
  if (!remboursementId) return refus('remboursement refuse par le prestataire', 502)
  return json({ demandeId, etat: String(issue) })
})
