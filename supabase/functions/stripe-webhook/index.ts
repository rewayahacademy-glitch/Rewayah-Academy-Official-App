// L'endpoint des webhooks Stripe (FI-BR-06). Seule source d'un credit de
// recharge : le retour du navigateur ne prouve rien (guide Finance V4 §1.6,
// dossier maitre §13.4).
//
// `verify_jwt` est a **false** : Stripe ne porte pas de jeton Supabase. Son
// authentification est la signature `Stripe-Signature`, verifiee par le SDK
// officiel (`constructEventAsync`) avec STRIPE_WEBHOOK_SECRET ; une signature absente, fausse ou trop ancienne est
// refusee (400) et rien n'est ecrit.
//
// L'idempotence est portee par la base (`paiement_webhooks`, cle prestataire
// + environnement + identifiant d'evenement), pas par une condition ici : un
// evenement rejoue repond 200 sans effet. Le montant, la devise, la session
// et l'environnement sont reverifies par `recharge_evenement_stripe`.

import { clientService } from '../_shared/clients.ts'
import { clientStripe, type Stripe, verifierEvenement } from '../_shared/stripe.ts'

/// Les evenements qui changent une commande ; les autres sont notes, sans effet.
export const TYPES_SUIVIS = new Set([
  'checkout.session.completed',
  'checkout.session.async_payment_succeeded',
  'checkout.session.async_payment_failed',
  'checkout.session.expired',
])

/// Les parametres de `recharge_evenement_stripe` lus dans un evenement.
export function parametres(evenement: Stripe.Event | Record<string, unknown>): Record<string, unknown> | null {
  const e = evenement as Record<string, unknown>
  const type = String(e.type ?? '')
  const objet = (e.data as { object?: Record<string, unknown> } | undefined)?.object
  if (!TYPES_SUIVIS.has(type) || !objet) return null
  const metadata = (objet.metadata as Record<string, unknown> | undefined) ?? {}
  const commande = typeof metadata.commande === 'string' ? metadata.commande : objet.client_reference_id
  if (typeof commande !== 'string' || typeof objet.id !== 'string') return null
  return {
    p_evenement: String(e.id),
    p_type: type,
    p_environnement: e.livemode === true ? 'live' : 'test',
    p_commande: commande,
    p_session: objet.id,
    p_paiement: typeof objet.payment_intent === 'string' ? objet.payment_intent : null,
    p_statut_paiement: typeof objet.payment_status === 'string' ? objet.payment_status : null,
    p_montant: typeof objet.amount_total === 'number' ? objet.amount_total : null,
    p_devise: typeof objet.currency === 'string' ? objet.currency : null,
  }
}

/// FN-115b : les remboursements et contestations (directeur, 01/11/2026). Le
/// directeur les ajoute aux evenements de son webhook Stripe.
export const TYPES_REMBOURSEMENT = new Set([
  'charge.refunded',
  'charge.dispute.created',
  'charge.dispute.closed',
])

/// Les parametres de `remboursement_evenement_stripe` lus dans un evenement :
/// - `charge.refunded` (objet charge) : le CUMUL rembourse (`amount_refunded`) ;
/// - `charge.dispute.*` (objet dispute) : montant conteste, identifiant,
///   statut, et frais du prestataire (somme des `fee` des transactions de la
///   contestation), lus seulement a la cloture.
/// Le paiement est le `payment_intent`, que la commande garde depuis le credit.
export function parametresRemboursement(
  evenement: Stripe.Event | Record<string, unknown>,
): Record<string, unknown> | null {
  const e = evenement as Record<string, unknown>
  const type = String(e.type ?? '')
  const objet = (e.data as { object?: Record<string, unknown> } | undefined)?.object
  if (!TYPES_REMBOURSEMENT.has(type) || !objet) return null
  const pi = objet.payment_intent
  const paiement = typeof pi === 'string' ? pi : (pi as { id?: unknown } | null)?.id
  if (typeof paiement !== 'string') return null
  const base = {
    p_evenement: String(e.id),
    p_type: type,
    p_environnement: e.livemode === true ? 'live' : 'test',
    p_paiement: paiement,
    p_devise: typeof objet.currency === 'string' ? objet.currency : null,
  }
  if (type === 'charge.refunded') {
    return {
      ...base,
      p_montant: typeof objet.amount_refunded === 'number' ? objet.amount_refunded : null,
    }
  }
  const transactions = Array.isArray(objet.balance_transactions) ? objet.balance_transactions : []
  const frais = transactions.reduce(
    (somme: number, t: unknown) => somme + (typeof (t as { fee?: unknown }).fee === 'number' ? (t as { fee: number }).fee : 0),
    0,
  )
  return {
    ...base,
    p_montant: typeof objet.amount === 'number' ? objet.amount : null,
    p_litige: typeof objet.id === 'string' ? objet.id : null,
    p_statut: typeof objet.status === 'string' ? objet.status : null,
    p_frais: type === 'charge.dispute.closed' ? frais : null,
  }
}

if (import.meta.main) {
  Deno.serve(async (requete: Request) => {
    if (requete.method !== 'POST') return new Response('methode non autorisee', { status: 405 })
    const secret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    const cle = Deno.env.get('STRIPE_SECRET_KEY')
    if (!secret || !cle) return new Response('webhook non configure', { status: 503 })

    const corps = await requete.text()
    let evenement: Stripe.Event
    try {
      evenement = await verifierEvenement(clientStripe(cle), corps, requete.headers.get('Stripe-Signature'), secret)
    } catch (e) {
      console.error('webhook stripe refuse', { erreur: (e as Error).message })
      return new Response('signature invalide', { status: 400 })
    }

    const p = parametres(evenement)
    const r = p ? null : parametresRemboursement(evenement)
    if (!p && !r) return new Response('ignore', { status: 200 })
    const fonction = p ? 'recharge_evenement_stripe' : 'remboursement_evenement_stripe'
    const parametresAppel = (p ?? r) as Record<string, unknown>

    const { data, error } = await clientService().rpc(fonction, parametresAppel)
    if (error) {
      // Une panne de la base : Stripe renverra l'evenement, et la base n'a
      // rien garde de cette tentative (transaction annulee).
      console.error('evenement stripe non traite', { evenement: parametresAppel.p_evenement, erreur: error.message })
      return new Response('reessayer', { status: 500 })
    }
    console.log('evenement stripe', { evenement: parametresAppel.p_evenement, type: parametresAppel.p_type, issue: data })
    return new Response('ok', { status: 200 })
  })
}
