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
    if (!p) return new Response('ignore', { status: 200 })

    const { data, error } = await clientService().rpc('recharge_evenement_stripe', p)
    if (error) {
      // Une panne de la base : Stripe renverra l'evenement, et la base n'a
      // rien garde de cette tentative (transaction annulee).
      console.error('evenement stripe non traite', { evenement: p.p_evenement, erreur: error.message })
      return new Response('reessayer', { status: 500 })
    }
    console.log('evenement stripe', { evenement: p.p_evenement, type: p.p_type, issue: data })
    return new Response('ok', { status: 200 })
  })
}
