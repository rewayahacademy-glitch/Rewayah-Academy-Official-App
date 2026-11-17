// PX-KYC-1 : le client du fournisseur, contre un faux `fetch`. AUCUN reseau.

import { assert, assertEquals } from 'jsr:@std/assert@1'
import { creerFournisseurAnthropic, ADRESSE_API } from './fournisseur_anthropic.ts'
import { CONSIGNE, ErreurFournisseur } from './lecture.ts'

const OCTETS = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3])
const demande = { modele: 'claude-test', octets: OCTETS, format: { type: 'image', mime: 'image/jpeg' } as const }

function fauxFetch(statut: number, corps: unknown, notes: { requete?: { url: string; init: RequestInit } } = {}): typeof fetch {
  return ((url: string | URL | Request, init?: RequestInit) => {
    notes.requete = { url: String(url), init: init ?? {} }
    return Promise.resolve(new Response(JSON.stringify(corps), { status: statut }))
  }) as typeof fetch
}

Deno.test('la requete : consigne fixe, une piece, AUCUN outil, cle en en-tete seulement', async () => {
  const notes: { requete?: { url: string; init: RequestInit } } = {}
  const f = creerFournisseurAnthropic('cle-fictive', fauxFetch(200, { content: [{ type: 'text', text: '{"a":1}' }] }, notes))
  assertEquals(await f.lire(demande), '{"a":1}')
  const r = notes.requete!
  assertEquals(r.url, ADRESSE_API)
  const corps = JSON.parse(String(r.init.body))
  assertEquals(corps.model, 'claude-test')
  assertEquals(corps.system, CONSIGNE)
  assertEquals(corps.temperature, 0)
  assert(!('tools' in corps) && !('tool_choice' in corps), 'aucun outil')
  assertEquals(corps.messages.length, 1)
  assertEquals(corps.messages[0].content[0].type, 'image')
  assertEquals(corps.messages[0].content[0].source.media_type, 'image/jpeg')
  assert(!JSON.stringify(corps).includes('cle-fictive'), 'la cle n est pas dans le corps')
  assertEquals((r.init.headers as Record<string, string>)['x-api-key'], 'cle-fictive')
})

Deno.test('un PDF part comme document', async () => {
  const notes: { requete?: { url: string; init: RequestInit } } = {}
  const f = creerFournisseurAnthropic('c', fauxFetch(200, { content: [{ type: 'text', text: 'x' }] }, notes))
  await f.lire({ ...demande, format: { type: 'document', mime: 'application/pdf' } })
  assertEquals(JSON.parse(String(notes.requete!.init.body)).messages[0].content[0].type, 'document')
})

Deno.test('401 et 403 : configuration ; 400, 413, 422 : refus ; 429, 500, 529 : panne', async () => {
  const cas: Array<[number, string]> = [[401, 'configuration'], [403, 'configuration'], [400, 'refus'], [413, 'refus'],
    [422, 'refus'], [429, 'panne'], [500, 'panne'], [529, 'panne']]
  for (const [statut, classe] of cas) {
    const f = creerFournisseurAnthropic('c', fauxFetch(statut, { error: 'x' }))
    try {
      await f.lire(demande)
      throw new Error('aurait du lever')
    } catch (e) {
      assert(e instanceof ErreurFournisseur, `statut ${statut}`)
      assertEquals(e.classe, classe, `statut ${statut}`)
    }
  }
})

Deno.test('une reponse « refusal », un reseau coupe, un corps illisible : refus ou panne, jamais un texte', async () => {
  const refus = creerFournisseurAnthropic('c', fauxFetch(200, { stop_reason: 'refusal', content: [] }))
  try { await refus.lire(demande); throw new Error('x') } catch (e) { assertEquals((e as ErreurFournisseur).classe, 'refus') }
  const coupe = creerFournisseurAnthropic('c', (() => Promise.reject(new Error('reseau'))) as typeof fetch)
  try { await coupe.lire(demande); throw new Error('x') } catch (e) { assertEquals((e as ErreurFournisseur).classe, 'panne') }
  const illisible = creerFournisseurAnthropic('c', (() => Promise.resolve(new Response('pas du json', { status: 200 }))) as typeof fetch)
  try { await illisible.lire(demande); throw new Error('x') } catch (e) { assertEquals((e as ErreurFournisseur).classe, 'panne') }
})

Deno.test('seuls les blocs de texte sont rendus, mis bout a bout', async () => {
  const f = creerFournisseurAnthropic('c', fauxFetch(200, { content: [{ type: 'text', text: 'a' }, { type: 'tool_use', id: 'x' }, { type: 'text', text: 'b' }] }))
  assertEquals(await f.lire(demande), 'ab')
})
