import { assertEquals } from 'jsr:@std/assert@1'
import { type Demande, ipDe, lireDemande, type PorteInvitation, traiter } from './index.ts'

Deno.test('lit le type, le code et l adresse ; refuse un corps mal forme', () => {
  assertEquals(lireDemande({ code: 'ABCD-EFGH-JKMN', email: ' Ami@Example.com ' }),
    { type: 'foyer', code: 'ABCD-EFGH-JKMN', adresse: 'ami@example.com' })
  assertEquals(lireDemande({ type: 'enseignant', code: 'ABCD-EFGH-JKMN', email: 'prof@example.com' }),
    { type: 'enseignant', code: 'ABCD-EFGH-JKMN', adresse: 'prof@example.com' })
  assertEquals(lireDemande({ type: 'admin', code: 'ABCD-EFGH-JKMN', email: 'x@example.com' }), null)
  assertEquals(lireDemande({ code: 'ABCD', email: 'ami@example.com' }), null)
  assertEquals(lireDemande({ code: 'ABCD-EFGH-JKMN', email: 'pas-une-adresse' }), null)
  assertEquals(lireDemande({ email: 'ami@example.com' }), null)
  assertEquals(lireDemande(null), null)
})

Deno.test('l IP vient de x-forwarded-for, premier saut', () => {
  assertEquals(ipDe(new Request('http://x', { headers: { 'x-forwarded-for': '203.0.113.7, 10.0.0.1' } })), '203.0.113.7')
  assertEquals(ipDe(new Request('http://x')), 'inconnue')
})

const demande: Demande = { type: 'foyer', code: 'ABCD-EFGH-JKMN', adresse: 'ami@example.com' }

function porte(debit: boolean, autorise: boolean, creation: 'cree' | 'existe' | 'echec') {
  const appels: string[] = []
  const p: PorteInvitation = {
    debit: (_a, ip) => {
      appels.push(`debit:${ip}`)
      return Promise.resolve(debit)
    },
    autoriser: (d) => {
      appels.push(`autoriser:${d.type}`)
      return Promise.resolve(autorise)
    },
    creerCompte: (a) => {
      appels.push(`creer:${a}`)
      return Promise.resolve(creation)
    },
  }
  return { p, appels }
}

Deno.test('debit atteint : ni autorisation ni compte', async () => {
  const { p, appels } = porte(false, true, 'cree')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'rien')
  assertEquals(appels, ['debit:203.0.113.7'])
})

Deno.test('adresse non invitee ou code faux : aucun compte cree', async () => {
  const { p, appels } = porte(true, false, 'cree')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'rien')
  assertEquals(appels, ['debit:203.0.113.7', 'autoriser:foyer'])
})

Deno.test('l adresse invitee : compte cree', async () => {
  const { p, appels } = porte(true, true, 'cree')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'cree')
  assertEquals(appels, ['debit:203.0.113.7', 'autoriser:foyer', 'creer:ami@example.com'])
})

Deno.test('compte deja la : meme issue que tout echec', async () => {
  const { p } = porte(true, true, 'existe')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'rien')
})
