// PE-B10 (20/11/2026) : ce que `kyc-confirme` rend, sans reseau ni secret.
// Une panne (authentification ou base) rend 503, jamais 401 ni 403.

import { assertEquals } from 'jsr:@std/assert@1'
import { etatErreurAuth, type AppelantDetaille } from '../_shared/clients.ts'
import { type Dependances, traiter } from './traiter.ts'

const UID = '11111111-2222-3333-4444-555555555555'
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

function dependances(
  options: {
    appelant?: AppelantDetaille
    confirmer?: Dependances['confirmer']
    octets?: Uint8Array
  } = {},
): Dependances & { confirmations: number } {
  const d = {
    confirmations: 0,
    appelant: () => Promise.resolve(options.appelant ?? { etat: 'ok', id: UID } as AppelantDetaille),
    url: () => 'https://exemple.supabase.co',
    cleLecture: () => 'cle-de-test',
    fetch: () => Promise.resolve(new Response(options.octets ?? JPEG, { status: 206 })),
    confirmer: (a: string, b: string, c: string) => {
      d.confirmations++
      return options.confirmer ? options.confirmer(a, b, c) : Promise.resolve({ error: null })
    },
  }
  return d
}

function requete(cle = `${UID}/1.jpg`): Request {
  return new Request('https://exemple/kyc-confirme', {
    method: 'POST',
    headers: { Authorization: 'Bearer x', 'Content-Type': 'application/json' },
    body: JSON.stringify({ object_key: cle }),
  })
}

Deno.test('conforme : 200 et la confirmation posee', async () => {
  const d = dependances()
  const r = await traiter(requete(), d)
  assertEquals(r.status, 200)
  assertEquals(d.confirmations, 1)
})

Deno.test('B1 : la RPC de confirmation echoue -> 503, plus jamais 403', async () => {
  const d = dependances({ confirmer: () => Promise.resolve({ error: { message: 'connexion refusee' } }) })
  const r = await traiter(requete(), d)
  assertEquals(r.status, 503)
  assertEquals((await r.json()).error, 'confirmation indisponible')
})

Deno.test('B1 : la RPC de confirmation leve une exception -> 503', async () => {
  const d = dependances({ confirmer: () => Promise.reject(new TypeError('fetch failed')) })
  assertEquals((await traiter(requete(), d)).status, 503)
})

Deno.test('B2 : authentification injoignable -> 503, sans rien confirmer', async () => {
  const d = dependances({ appelant: { etat: 'indisponible' } })
  const r = await traiter(requete(), d)
  assertEquals(r.status, 503)
  assertEquals(d.confirmations, 0)
})

Deno.test('B2 : jeton absent ou refuse -> 401 (inchange)', async () => {
  assertEquals((await traiter(requete(), dependances({ appelant: { etat: 'absent' } }))).status, 401)
  assertEquals((await traiter(requete(), dependances({ appelant: { etat: 'refuse' } }))).status, 401)
})

Deno.test('B2 : une erreur 4xx de getUser est un refus, le reste une panne', () => {
  assertEquals(etatErreurAuth({ status: 401 }), 'refuse')
  assertEquals(etatErreurAuth({ status: 403 }), 'refuse')
  assertEquals(etatErreurAuth({ status: 400 }), 'refuse')
  assertEquals(etatErreurAuth({ status: 0 }), 'indisponible')
  assertEquals(etatErreurAuth({ status: 500 }), 'indisponible')
  assertEquals(etatErreurAuth({ status: 503 }), 'indisponible')
  assertEquals(etatErreurAuth({}), 'indisponible')
  assertEquals(etatErreurAuth(null), 'indisponible')
})

Deno.test('inchange : cle d un autre -> 403 ; contenu faux -> 422 ; objet absent -> 409', async () => {
  assertEquals((await traiter(requete(`99999999-2222-3333-4444-555555555555/1.jpg`), dependances())).status, 403)
  const faux = dependances({ octets: new TextEncoder().encode('ceci est un texte, pas un') })
  assertEquals((await traiter(requete(), faux)).status, 422)
  assertEquals(faux.confirmations, 0)
  const absent = dependances()
  absent.fetch = () => Promise.resolve(new Response('{}', { status: 400 }))
  assertEquals((await traiter(requete(), absent)).status, 409)
})
