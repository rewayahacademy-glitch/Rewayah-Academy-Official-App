// Stripe pour FI-BR-06, par le SDK officiel (`npm:stripe`), selon le modele
// documente par Supabase (guides/functions/examples/stripe-webhooks) :
// client en Fetch, verification des webhooks par
// `stripe.webhooks.constructEventAsync` avec le fournisseur Web Crypto.
// Rien n'est reecrit a la main : signature, encodage et idempotence sont
// ceux de la bibliotheque de Stripe.
//
// Secrets (jamais dans le depot, jamais au client) :
//   STRIPE_SECRET_KEY      cle secrete du compte (sk_test_... ou sk_live_...)
//   STRIPE_WEBHOOK_SECRET  secret de signature de l'endpoint (whsec_...)
//   APP_ORIGINES           origines autorisees pour le retour, separees par
//                          des virgules (https://app.exemple.org,...)

import Stripe from 'npm:stripe@22.6.2'

export { Stripe }

/// Le client Stripe, en Fetch (Deno).
export function clientStripe(cleSecrete: string): Stripe {
  return new Stripe(cleSecrete, { httpClient: Stripe.createFetchHttpClient() })
}

const fournisseurCrypto = Stripe.createSubtleCryptoProvider()

/// Verifie l'en-tete `Stripe-Signature` et rend l'evenement ; leve une
/// erreur si la signature manque, est fausse ou trop ancienne.
export function verifierEvenement(
  stripe: Stripe,
  corps: string,
  entete: string | null,
  secret: string,
): Promise<Stripe.Event> {
  if (!entete) return Promise.reject(new Error('signature absente'))
  return stripe.webhooks.constructEventAsync(corps, entete, secret, undefined, fournisseurCrypto)
}

/// Une ligne de la page de paiement : le prenom du profil et sa part.
export interface LignePaiement {
  prenom: string
  mineur: number
}

/// Les parametres de la session Checkout : une ligne par profil, la
/// commande en metadonnees (relue par le webhook).
export function parametresSession(p: {
  commandeId: string
  reference: string
  devise: string
  lignes: LignePaiement[]
  retour: string
  libelle: (prenom: string) => string
  expireA: number
}): Stripe.Checkout.SessionCreateParams {
  return {
    mode: 'payment',
    success_url: p.retour,
    cancel_url: p.retour,
    client_reference_id: p.commandeId,
    metadata: { commande: p.commandeId, reference: p.reference },
    payment_intent_data: { metadata: { commande: p.commandeId }, description: p.reference },
    expires_at: p.expireA,
    line_items: p.lignes.map((l) => ({
      quantity: 1,
      price_data: {
        currency: p.devise.toLowerCase(),
        unit_amount: l.mineur,
        product_data: { name: p.libelle(l.prenom) },
      },
    })),
  }
}

/// Ouvre la session Checkout ; [idempotence] rend un second appel pour la
/// meme commande sans effet chez Stripe.
export async function creerSession(
  stripe: Stripe,
  parametres: Stripe.Checkout.SessionCreateParams,
  idempotence: string,
): Promise<{ id: string; url: string; environnement: 'test' | 'live' }> {
  const session = await stripe.checkout.sessions.create(parametres, { idempotencyKey: idempotence })
  if (!session.url) throw new Error('session sans adresse')
  return { id: session.id, url: session.url, environnement: session.livemode ? 'live' : 'test' }
}

/// Vrai quand [adresse] a pour origine l'une des origines autorisees.
export function retourAutorise(adresse: string, origines: string | undefined): boolean {
  let url: URL
  try {
    url = new URL(adresse)
  } catch {
    return false
  }
  const liste = (origines ?? '').split(',').map((o) => o.trim()).filter((o) => o.length > 0)
  return liste.some((o) => url.origin === o)
}
