// FI-BR-06 : l'emploi du SDK officiel de Stripe. Les signatures de test sont
// fabriquees par la bibliotheque de Stripe elle-meme
// (`generateTestHeaderStringAsync`), jamais a la main.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import {
  clientStripe,
  formulaireIntegrePossible,
  MARQUE_INTEGRE,
  parametresSession,
  retourAutorise,
  sessionIntegree,
  Stripe,
  verifierEvenement,
  adresseBanc,
  couleurFond,
  fermerAncienneSession,
  nomLigne,
  type SessionsCheckout,
  parametresRemboursementDirection,
} from './stripe.ts'
import { parametres, parametresRemboursement, remboursementsDeLaCharge } from '../stripe-webhook/index.ts'

const SECRET = 'whsec_test_rewayah'
const stripe = clientStripe('sk_test_rewayah')
const crypto = Stripe.createSubtleCryptoProvider()
const CORPS = JSON.stringify({
  id: 'evt_1',
  object: 'event',
  type: 'checkout.session.completed',
  livemode: false,
  data: {
    object: {
      id: 'cs_test_1',
      object: 'checkout.session',
      client_reference_id: '11111111-1111-4111-8111-111111111111',
      metadata: { commande: '11111111-1111-4111-8111-111111111111' },
      payment_intent: 'pi_1',
      payment_status: 'paid',
      amount_total: 15000,
      currency: 'usd',
    },
  },
})

function entete(corps: string, secret = SECRET, horodatage?: number): Promise<string> {
  return stripe.webhooks.generateTestHeaderStringAsync({ payload: corps, secret, timestamp: horodatage, cryptoProvider: crypto })
}

Deno.test('signature du SDK : l evenement est rendu', async () => {
  const e = await verifierEvenement(stripe, CORPS, await entete(CORPS), SECRET)
  assertEquals(e.id, 'evt_1')
})

Deno.test('signature fausse, absente, d un autre secret ou trop ancienne : refusee', async () => {
  await assertRejects(() => verifierEvenement(stripe, CORPS, null, SECRET))
  await assertRejects(async () => verifierEvenement(stripe, CORPS, await entete(CORPS, 'whsec_autre'), SECRET))
  await assertRejects(async () =>
    verifierEvenement(stripe, CORPS.replace('15000', '1'), await entete(CORPS), SECRET)
  )
  const ancien = Math.floor(Date.now() / 1000) - 3600
  await assertRejects(async () => verifierEvenement(stripe, CORPS, await entete(CORPS, SECRET, ancien), SECRET))
})

Deno.test('parametres : montant, devise, session, commande et environnement', () => {
  assertEquals(parametres(JSON.parse(CORPS)), {
    p_evenement: 'evt_1',
    p_type: 'checkout.session.completed',
    p_environnement: 'test',
    p_commande: '11111111-1111-4111-8111-111111111111',
    p_session: 'cs_test_1',
    p_paiement: 'pi_1',
    p_statut_paiement: 'paid',
    p_montant: 15000,
    p_devise: 'usd',
  })
  assertEquals(parametres({ id: 'evt_2', type: 'customer.created', data: { object: { id: 'cus_1' } } }), null)
})

Deno.test('session : une ligne par profil, montants en unites mineures', () => {
  const p = parametresSession({
    commandeId: 'c1',
    reference: 'RWY-ABCD1234',
    devise: 'USD',
    lignes: [{ prenom: 'Bilal', mineur: 5000 }, { prenom: 'Yasmine', mineur: 10000 }],
    retour: 'https://app.test/#/r?commande=c1',
    libelle: (l) => `Rewayah Academy · ${l.prenom}`,
    expireA: 1,
  })
  assertEquals(p.line_items?.length, 2)
  assertEquals(p.line_items?.[0].price_data?.unit_amount, 5000)
  assertEquals(p.line_items?.[1].price_data?.currency, 'usd')
  assertEquals(p.line_items?.[1].price_data?.product_data?.name, 'Rewayah Academy · Yasmine')
  assertEquals(p.metadata?.commande, 'c1')
  assertEquals(p.success_url, 'https://app.test/#/r?commande=c1')
})

Deno.test('retour : seulement vers une origine autorisee', () => {
  assertEquals(retourAutorise('https://app.test/#/x', 'https://app.test, https://autre.test'), true)
  assertEquals(retourAutorise('https://pirate.test/#/x', 'https://app.test'), false)
  assertEquals(retourAutorise('pas une adresse', 'https://app.test'), false)
  assertEquals(retourAutorise('https://app.test/', undefined), false)
})

Deno.test('formulaire integre : embedded_page, retour seulement si un moyen l exige, aucune page hebergee', () => {
  const p = parametresSession({
    commandeId: 'c1',
    reference: 'RWY-ABCD1234',
    devise: 'USD',
    lignes: [{ prenom: 'Bilal', mineur: 5000 }],
    retour: 'https://app.test/#/r?commande=c1',
    libelle: (l) => `Rewayah Academy · ${l.prenom}`,
    expireA: 1,
    integre: true,
  })
  assertEquals(p.ui_mode, 'embedded_page')
  assertEquals(p.redirect_on_completion, 'if_required')
  assertEquals(p.return_url, 'https://app.test/#/r?commande=c1')
  assertEquals(p.success_url, undefined)
  assertEquals(p.cancel_url, undefined)
  assertEquals(p.metadata?.commande, 'c1')
  assertEquals(p.line_items?.[0].price_data?.unit_amount, 5000)
})

Deno.test('formulaire integre possible : cle publiable du meme mode que la cle secrete', () => {
  assertEquals(formulaireIntegrePossible('sk_live_x', 'pk_live_y'), true)
  assertEquals(formulaireIntegrePossible('sk_test_x', 'pk_test_y'), true)
  assertEquals(formulaireIntegrePossible('rk_live_x', 'pk_live_y'), true)
  assertEquals(formulaireIntegrePossible('sk_live_x', 'pk_test_y'), false)
  assertEquals(formulaireIntegrePossible('sk_test_x', 'pk_live_y'), false)
  assertEquals(formulaireIntegrePossible('sk_live_x', undefined), false)
  assertEquals(formulaireIntegrePossible('sk_live_x', ''), false)
  assertEquals(formulaireIntegrePossible('sk_live_x', 'sk_live_x'), false)
})

Deno.test('reprise integree : seul un identifiant de session marque se relit', () => {
  assertEquals(sessionIntegree(`${MARQUE_INTEGRE}cs_live_a1B2`), 'cs_live_a1B2')
  assertEquals(sessionIntegree(`${MARQUE_INTEGRE}cs_test_a1B2`), 'cs_test_a1B2')
  assertEquals(sessionIntegree('https://checkout.stripe.com/c/pay/cs_live_a1B2'), null)
  assertEquals(sessionIntegree(`${MARQUE_INTEGRE}cs_live_a1B2/../x`), null)
  assertEquals(sessionIntegree(`${MARQUE_INTEGRE}`), null)
})

Deno.test('FN-115b : remboursement, le cumul rembourse et le paiement', () => {
  assertEquals(parametresRemboursement({
    id: 'evt_r', type: 'charge.refunded', livemode: false,
    data: { object: { id: 'ch_1', payment_intent: 'pi_1', amount_refunded: 4000, currency: 'usd' } },
  }), {
    p_evenement: 'evt_r', p_type: 'charge.refunded', p_environnement: 'test', p_paiement: 'pi_1',
    p_devise: 'usd', p_montant: 4000,
  })
})

Deno.test('FN-115b : contestation ouverte puis perdue, frais lus a la cloture seulement', () => {
  const objet = {
    id: 'du_1', payment_intent: 'pi_2', amount: 5500, currency: 'usd', status: 'needs_response',
    balance_transactions: [{ fee: 1500 }, { fee: 0 }],
  }
  assertEquals(parametresRemboursement({ id: 'evt_d1', type: 'charge.dispute.created', livemode: true, data: { object: objet } }), {
    p_evenement: 'evt_d1', p_type: 'charge.dispute.created', p_environnement: 'live', p_paiement: 'pi_2',
    p_devise: 'usd', p_montant: 5500, p_litige: 'du_1', p_statut: 'needs_response', p_frais: null,
  })
  assertEquals(
    parametresRemboursement({
      id: 'evt_d2', type: 'charge.dispute.closed', livemode: true, data: { object: { ...objet, status: 'lost' } },
    })?.p_frais,
    1500,
  )
})

Deno.test('FN-115b : sans paiement ou d un autre type, rien ; le credit reste a son chemin', () => {
  assertEquals(parametresRemboursement({ id: 'e', type: 'charge.refunded', data: { object: { amount_refunded: 1 } } }), null)
  assertEquals(parametresRemboursement({ id: 'e', type: 'checkout.session.completed', data: { object: {} } }), null)
  assertEquals(parametres({ id: 'e', type: 'charge.refunded', data: { object: { id: 'ch_1' } } }), null)
})

// FN-115c (pilote, 02/11/2026).
Deno.test('remboursement de la direction : payment_intent, montant, cle = la demande', () => {
  const { params, cle } = parametresRemboursementDirection({
    demandeId: 'd-1', paiement: 'pi_1', montant: 1000, profil: 'p-1',
  })
  assertEquals(params.payment_intent, 'pi_1')
  assertEquals(params.amount, 1000)
  assertEquals(params.metadata, { demande: 'd-1', profil: 'p-1' })
  assertEquals(cle, 'remboursement-d-1')
})

Deno.test('faux Stripe de banc : cle de test et adresse locale seulement', () => {
  assertEquals(adresseBanc('sk_test_x', 'http://127.0.0.1:12111'), { host: '127.0.0.1', port: 12111, protocol: 'http' })
  assertEquals(adresseBanc('sk_test_x', 'http://host.docker.internal:12111')?.host, 'host.docker.internal')
  assertEquals(adresseBanc('sk_live_x', 'http://127.0.0.1:12111'), null)
  assertEquals(adresseBanc('sk_test_x', 'https://api.exemple.org'), null)
  assertEquals(adresseBanc('sk_test_x', undefined), null)
  assertEquals(adresseBanc('sk_test_x', 'pas une adresse'), null)
})

Deno.test('charge.refunded : les remboursements portes, le plus recent d abord', () => {
  const charge = (objet: Record<string, unknown>) =>
    ({ type: 'charge.refunded', data: { object: objet } }) as unknown as Record<string, unknown>
  assertEquals(
    remboursementsDeLaCharge(charge({ refunds: { data: [{ id: 're_a', created: 1 }, { id: 're_b', created: 5 }] } })),
    ['re_b', 're_a'],
  )
  assertEquals(remboursementsDeLaCharge(charge({})), [])
})

// PAY-UX (02/11/2026) : nom des lignes, fond du formulaire, nouveau depart.
Deno.test('PAY-UX : le nom d une ligne dit ce qu on paie, jamais un prenom', () => {
  assertEquals(nomLigne({ prenom: 'H', mineur: 5500, formule: 'mois', mois: '2026-11-01' }), 'Mensualité de novembre 2026')
  assertEquals(nomLigne({ prenom: 'H', mineur: 5500, formule: 'mois', mois: '2027-04-01' }), 'Mensualité d’avril 2027')
  assertEquals(nomLigne({ prenom: 'H', mineur: 5500, formule: 'mois', mois: '2026-10-01' }), 'Mensualité d’octobre 2026')
  assertEquals(nomLigne({ prenom: 'H', mineur: 5500, formule: 'mois', mois: '2026-11-01' }, 'ar'), 'رسوم شهر نوفمبر 2026')
  assertEquals(nomLigne({ prenom: 'H', mineur: 1, formule: 'trimestriel' }), 'Trois mois payés d’avance')
  assertEquals(nomLigne({ prenom: 'H', mineur: 1, formule: 'annuel' }), 'Une année payée d’avance')
  assertEquals(nomLigne({ prenom: 'H', mineur: 1, formule: 'libre' }), 'Paiement des cours')
  // Une base d'avant le lot (sans formule ni mois) : un nom sans prenom.
  assertEquals(nomLigne({ prenom: 'Yasmine', mineur: 1 }), 'Paiement des cours')
  assertEquals(nomLigne({ prenom: 'H', mineur: 1, formule: 'mois', mois: 'n importe' }), 'Mensualité')
})

Deno.test('PAY-UX : le formulaire integre prend le fond de la page et le nom de l academie', () => {
  const p = parametresSession({
    commandeId: 'c1', reference: 'RWY-ABCD1234', devise: 'USD',
    lignes: [{ prenom: 'H', mineur: 5500, formule: 'mois', mois: '2026-11-01' }],
    retour: 'https://app.test/#/r?commande=c1',
    libelle: (l) => nomLigne(l), expireA: 1, integre: true, fond: '#F7F4FB',
  })
  assertEquals(p.branding_settings?.background_color, '#f7f4fb')
  assertEquals(p.branding_settings?.display_name, 'Rewayah Academy')
  assertEquals(p.line_items?.[0].price_data?.product_data?.name, 'Mensualité de novembre 2026')
  const sansFond = parametresSession({
    commandeId: 'c1', reference: 'R', devise: 'USD', lignes: [{ prenom: 'H', mineur: 1 }],
    retour: 'https://app.test/', libelle: (l) => nomLigne(l), expireA: 1, integre: true, fond: 'red;}',
  })
  assertEquals(sansFond.branding_settings?.background_color, undefined)
  assertEquals(couleurFond('#123abc'), '#123abc')
  assertEquals(couleurFond('url(x)'), null)
  assertEquals(couleurFond(12), null)
})

function fauxSessions(statut: string, expireRefuse = false) {
  const appels: string[] = []
  return {
    appels,
    sessions: {
      retrieve: (id: string) => { appels.push(`retrieve:${id}`); return Promise.resolve({ id, status: statut }) },
      expire: (id: string) => {
        appels.push(`expire:${id}`)
        return expireRefuse ? Promise.reject(new Error('session deja payee')) : Promise.resolve({ id, status: 'expired' })
      },
    } as SessionsCheckout,
  }
}

Deno.test('PAY-UX : nouveau depart, la session ouverte est expiree puis remplacee', async () => {
  const f = fauxSessions('open')
  assertEquals(await fermerAncienneSession(f.sessions, 'cs_a'), 'remplacer')
  assertEquals(f.appels, ['retrieve:cs_a', 'expire:cs_a'])
})

Deno.test('PAY-UX : session payee, aucune expiration, aucune nouvelle session', async () => {
  const f = fauxSessions('complete')
  assertEquals(await fermerAncienneSession(f.sessions, 'cs_a'), 'payee')
  assertEquals(f.appels, ['retrieve:cs_a'])
})

Deno.test('PAY-UX : session deja expiree, remplacee sans nouvel appel d expiration', async () => {
  const f = fauxSessions('expired')
  assertEquals(await fermerAncienneSession(f.sessions, 'cs_a'), 'remplacer')
  assertEquals(f.appels, ['retrieve:cs_a'])
})

Deno.test('PAY-UX : expiration refusee par Stripe, l erreur remonte (rien n est cree)', async () => {
  const f = fauxSessions('open', true)
  await assertRejects(() => fermerAncienneSession(f.sessions, 'cs_a'))
  assertEquals(f.appels, ['retrieve:cs_a', 'expire:cs_a'])
})
