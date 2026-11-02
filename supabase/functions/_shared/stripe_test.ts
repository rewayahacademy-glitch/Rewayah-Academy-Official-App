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
} from './stripe.ts'
import { parametres, parametresRemboursement } from '../stripe-webhook/index.ts'

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
    libelle: (prenom) => `Rewayah Academy · ${prenom}`,
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
    libelle: (prenom) => `Rewayah Academy · ${prenom}`,
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
