// FI-BR-06 : l'emploi du SDK officiel de Stripe. Les signatures de test sont
// fabriquees par la bibliotheque de Stripe elle-meme
// (`generateTestHeaderStringAsync`), jamais a la main.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { clientStripe, parametresSession, retourAutorise, Stripe, verifierEvenement } from './stripe.ts'
import { parametres } from '../stripe-webhook/index.ts'

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
