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
///
/// FN-115c (pilote, 02/11/2026) : `STRIPE_API_BASE_BANC`, de banc
/// seulement, envoie les appels a un faux Stripe local (R3). Il n'est suivi
/// qu'avec une cle de test et une adresse locale ; en production, il n'existe
/// pas et rien ne change.
export function clientStripe(cleSecrete: string): Stripe {
  const banc = adresseBanc(cleSecrete, Deno.env.get('STRIPE_API_BASE_BANC'))
  return new Stripe(cleSecrete, {
    httpClient: Stripe.createFetchHttpClient(),
    ...(banc ?? {}),
  })
}

/// L'adresse du faux Stripe de banc, ou `null` : jamais avec une cle live,
/// jamais hors d'une adresse locale.
export function adresseBanc(
  cleSecrete: string,
  base: string | undefined,
): { host: string; port: number; protocol: 'http' | 'https' } | null {
  if (!base || !cleSecrete.startsWith('sk_test_')) return null
  let u: URL
  try {
    u = new URL(base)
  } catch {
    return null
  }
  const locale = ['127.0.0.1', 'localhost', 'host.docker.internal'].includes(u.hostname)
  if (!locale || (u.protocol !== 'http:' && u.protocol !== 'https:')) return null
  const protocol = u.protocol === 'https:' ? 'https' : 'http'
  return { host: u.hostname, port: Number(u.port || (protocol === 'https' ? 443 : 80)), protocol }
}

/// FN-115c : les parametres d'un remboursement decide par la direction. La
/// cle d'idempotence est la demande : deux envois de la meme demande (double
/// clic, reprise apres coupure) ne font qu'un remboursement chez Stripe.
export function parametresRemboursementDirection(d: {
  demandeId: string
  paiement: string
  montant: number
  profil: string
}): { params: Stripe.RefundCreateParams; cle: string } {
  return {
    params: {
      payment_intent: d.paiement,
      amount: d.montant,
      reason: 'requested_by_customer',
      metadata: { demande: d.demandeId, profil: d.profil },
    },
    cle: `remboursement-${d.demandeId}`,
  }
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
  /// PAY-UX (migration 20261105900000) : la formule de la part (`libre`,
  /// `mois`, `trimestriel`, `annuel`) et le mois de facturation
  /// (AAAA-MM-01). Absents d'une base d'avant ce lot.
  formule?: string
  mois?: string
}

const MOIS_FR = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre',
  'octobre', 'novembre', 'décembre']
const MOIS_AR = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر',
  'أكتوبر', 'نوفمبر', 'ديسمبر']

/// PAY-UX (constat du directeur du 02/11/2026 : « Rewayah Academy · H ») : le
/// nom d'une ligne chez Stripe dit seulement ce qu'on paie, jamais un
/// prenom ; le montant est affiche par Stripe a cote. Le mois vient du
/// serveur (`private.fac_mois_courant()`), jamais de l'horloge de la fonction.
export function nomLigne(l: LignePaiement, langue = 'fr'): string {
  const m = typeof l.mois === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(l.mois)
    ? { an: l.mois.slice(0, 4), i: Number(l.mois.slice(5, 7)) - 1 }
    : null
  const ar = langue === 'ar'
  switch (l.formule) {
    case 'mois':
      if (m && m.i >= 0 && m.i < 12) {
        if (ar) return `رسوم شهر ${MOIS_AR[m.i]} ${m.an}`
        const mois = MOIS_FR[m.i]
        return `Mensualité ${/^[aeiouyâàéèêëîïôûù]/i.test(mois) ? 'd’' : 'de '}${mois} ${m.an}`
      }
      return ar ? 'رسوم الشهر' : 'Mensualité'
    case 'trimestriel':
      return ar ? 'ثلاثة أشهر مدفوعة مسبقًا' : 'Trois mois payés d’avance'
    case 'annuel':
      return ar ? 'سنة مدفوعة مسبقًا' : 'Une année payée d’avance'
    default:
      return ar ? 'رسوم الدروس' : 'Paiement des cours'
  }
}

/// Une couleur de fond acceptee pour le formulaire (« #RRGGBB »), sinon `null`.
export function couleurFond(v: unknown): string | null {
  return typeof v === 'string' && /^#[0-9a-fA-F]{6}$/.test(v) ? v.toLowerCase() : null
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
  libelle: (ligne: LignePaiement) => string
  expireA: number
  integre?: boolean
  /// PAY-UX : le fond de la page de l'application autour du formulaire ; le
  /// formulaire integre prend le meme (`branding_settings.background_color`),
  /// sans cadre d'une autre couleur. Le CSS de la page ne traverse pas
  /// l'iframe de Stripe : seul ce reglage (ou celui du tableau de bord) agit.
  fond?: string | null
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
        product_data: { name: p.libelle(l) },
      },
    })),
  }
  if (p.integre) {
    const fond = couleurFond(p.fond)
    return {
      ...commun,
      ui_mode: 'embedded_page',
      redirect_on_completion: 'if_required',
      return_url: p.retour,
      branding_settings: { display_name: 'Rewayah Academy', ...(fond ? { background_color: fond } : {}) },
    }
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

/// PAY-UX : ce qu'un nouveau depart fait d'une session integree deja notee
/// sur la commande. `payee` : la session est `complete`, rien n'est expire ni
/// cree. `remplacer` : la session etait ouverte et vient d'etre expiree chez
/// Stripe, ou elle l'etait deja ; une nouvelle peut etre creee. Une
/// expiration refusee leve l'erreur : l'appelant ne cree alors rien.
export interface SessionsCheckout {
  retrieve(id: string): Promise<{ status: string | null }>
  expire(id: string): Promise<unknown>
}

export async function fermerAncienneSession(
  sessions: SessionsCheckout,
  sessionId: string,
): Promise<'payee' | 'remplacer'> {
  const session = await sessions.retrieve(sessionId)
  if (session.status === 'complete') return 'payee'
  if (session.status === 'open') await sessions.expire(sessionId)
  return 'remplacer'
}
