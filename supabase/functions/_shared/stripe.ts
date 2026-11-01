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
//   STRIPE_PUBLISHABLE_KEY cle publiable du meme compte et du meme mode
//                          (pk_test_... ou pk_live_...) : sans elle, ou d'un
//                          autre mode que la cle secrete, le paiement reste
//                          sur la page hebergee de Stripe (repli).
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
///
/// [integre] (decision du directeur du 01/11/2026 : « le paiement doit se
/// faire sur l'app, pas de sortir ailleurs ») : le formulaire de Stripe se
/// monte dans la page de l'application (`ui_mode: embedded_page`). Une carte
/// se paie sans quitter l'application (`redirect_on_completion:
/// if_required`) ; seul un moyen qui exige une banque externe ramene ensuite
/// a [retour]. Sans [integre], la page hebergee de Stripe (repli).
export function parametresSession(p: {
  commandeId: string
  reference: string
  devise: string
  lignes: LignePaiement[]
  retour: string
  libelle: (prenom: string) => string
  expireA: number
  integre?: boolean
}): Stripe.Checkout.SessionCreateParams {
  const commun: Stripe.Checkout.SessionCreateParams = {
    mode: 'payment',
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
  if (p.integre) {
    return { ...commun, ui_mode: 'embedded_page', redirect_on_completion: 'if_required', return_url: p.retour }
  }
  return { ...commun, success_url: p.retour, cancel_url: p.retour }
}

/// Une session ouverte : son adresse (page hebergee) ou son secret client
/// (formulaire integre), l'un ou l'autre.
export interface SessionOuverte {
  id: string
  url: string | null
  secretClient: string | null
  environnement: 'test' | 'live'
}

/// Ouvre la session Checkout ; [idempotence] rend un second appel pour la
/// meme commande sans effet chez Stripe.
export async function creerSession(
  stripe: Stripe,
  parametres: Stripe.Checkout.SessionCreateParams,
  idempotence: string,
): Promise<SessionOuverte> {
  const session = await stripe.checkout.sessions.create(parametres, { idempotencyKey: idempotence })
  const integre = parametres.ui_mode === 'embedded_page'
  if (integre ? !session.client_secret : !session.url) throw new Error('session incomplete')
  return {
    id: session.id,
    url: integre ? null : session.url,
    secretClient: integre ? session.client_secret : null,
    environnement: session.livemode ? 'live' : 'test',
  }
}

/// La marque qu'une session integree laisse dans `url_paiement` : aucune
/// adresse n'existe pour elle, la commande garde l'identifiant de la session,
/// que la reprise relit chez Stripe pour rendre son secret client. Aucune
/// migration : la colonne garde son sens, « ou reprendre ce paiement ».
export const MARQUE_INTEGRE = 'stripe-integre:'

/// L'identifiant de session d'une reprise integree, ou `null` (adresse d'une
/// page hebergee).
export function sessionIntegree(urlPaiement: string): string | null {
  if (!urlPaiement.startsWith(MARQUE_INTEGRE)) return null
  const id = urlPaiement.slice(MARQUE_INTEGRE.length)
  return /^cs_(test|live)_[A-Za-z0-9]+$/.test(id) ? id : null
}

/// Vrai quand le formulaire integre peut s'ouvrir : une cle publiable du meme
/// mode que la cle secrete (test avec test, reel avec reel).
export function formulaireIntegrePossible(cleSecrete: string, clePublique: string | undefined): boolean {
  const mode = (cle: string, prefixes: string[]) => prefixes.find((x) => cle.startsWith(x))?.split('_')[1]
  const secret = mode(cleSecrete, ['sk_test_', 'sk_live_', 'rk_test_', 'rk_live_'])
  const publique = mode(clePublique ?? '', ['pk_test_', 'pk_live_'])
  return secret !== undefined && secret === publique
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
