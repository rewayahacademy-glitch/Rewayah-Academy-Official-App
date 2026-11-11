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

const req = (entetes: Record<string, string>) => new Request('http://x', { headers: entetes })

Deno.test('l IP : une valeur forgee dans x-forwarded-for est ignoree', () => {
  assertEquals(ipDe(req({ 'x-forwarded-for': '1.2.3.4', 'cf-connecting-ip': '203.0.113.7' })), '203.0.113.7')
  assertEquals(ipDe(req({ 'x-forwarded-for': '1.2.3.4, 9.9.9.9', 'x-real-ip': '203.0.113.7' })), '203.0.113.7')
  // x-forwarded-for seul n'est jamais lu.
  assertEquals(ipDe(req({ 'x-forwarded-for': '1.2.3.4, 203.0.113.7' })), 'inconnue')
})

Deno.test('l IP : cf-connecting-ip passe avant x-real-ip', () => {
  assertEquals(ipDe(req({ 'cf-connecting-ip': '203.0.113.7', 'x-real-ip': '198.51.100.2' })), '203.0.113.7')
  assertEquals(ipDe(req({ 'x-real-ip': '198.51.100.2' })), '198.51.100.2')
})

Deno.test('l IP : sans aucun des deux en-tetes, inconnue', () => {
  assertEquals(ipDe(new Request('http://x')), 'inconnue')
})

Deno.test('l IP : un en-tete vide donne inconnue', () => {
  assertEquals(ipDe(req({ 'cf-connecting-ip': '', 'x-real-ip': '' })), 'inconnue')
  assertEquals(ipDe(req({ 'cf-connecting-ip': '   ' })), 'inconnue')
  // Vide d'un cote, plein de l'autre : la valeur pleine.
  assertEquals(ipDe(req({ 'cf-connecting-ip': ' ', 'x-real-ip': '198.51.100.2' })), '198.51.100.2')
})

const demande: Demande = { type: 'foyer', code: 'ABCD-EFGH-JKMN', adresse: 'ami@example.com' }

function porte(debit: boolean, autorise: boolean, creation: 'cree' | 'existe' | 'echec', consomme = true) {
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
    consommer: (d) => {
      appels.push(`consommer:${d.type}`)
      return Promise.resolve(consomme)
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

Deno.test('l adresse invitee : compte cree, puis code consomme', async () => {
  const { p, appels } = porte(true, true, 'cree')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'cree')
  assertEquals(appels, ['debit:203.0.113.7', 'autoriser:foyer', 'creer:ami@example.com', 'consommer:foyer'])
})

Deno.test('compte deja la : meme issue que tout echec, code non consomme', async () => {
  const { p, appels } = porte(true, true, 'existe')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'rien')
  assertEquals(appels.includes('consommer:foyer'), false)
})

Deno.test('createUser echoue : le code n est pas consomme (il resservira)', async () => {
  const { p, appels } = porte(true, true, 'echec')
  assertEquals(await traiter(demande, '203.0.113.7', p), 'rien')
  assertEquals(appels, ['debit:203.0.113.7', 'autoriser:foyer', 'creer:ami@example.com'])
})

Deno.test('compte cree mais consommation refusee : le compte reste cree', async () => {
  const { p } = porte(true, true, 'cree', false)
  assertEquals(await traiter(demande, '203.0.113.7', p), 'cree')
})
