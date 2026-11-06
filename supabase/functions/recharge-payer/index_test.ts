// GAINS (06/11/2026) : la chauffe ne cree rien ; l'appelant se lit dans un
// jeton dont la signature est verifiee (`auth.getClaims`), jamais decode seul.

import { assertEquals } from 'jsr:@std/assert@1'
import { gerer, identiteVerifiee } from './index.ts'

type Reponse = { data: { claims: { sub?: unknown; email?: unknown } } | null; error: unknown }

function faux(reponse: Reponse) {
  const jetons: string[] = []
  return {
    jetons,
    auth: {
      getClaims(jeton: string): Promise<Reponse> {
        jetons.push(jeton)
        return Promise.resolve(reponse)
      },
    },
  }
}

Deno.test('identite : sans jeton Bearer, personne, et getClaims n est pas appele', async () => {
  const f = faux({ data: { claims: { sub: 'u1' } }, error: null })
  assertEquals(await identiteVerifiee(f.auth, null), null)
  assertEquals(await identiteVerifiee(f.auth, 'Basic abc'), null)
  assertEquals(await identiteVerifiee(f.auth, 'Bearer   '), null)
  assertEquals(f.jetons.length, 0)
})

Deno.test('identite : le jeton seul part a getClaims ; sub et adresse rendus', async () => {
  const f = faux({ data: { claims: { sub: 'u1', email: 'a@b.test' } }, error: null })
  assertEquals(await identiteVerifiee(f.auth, 'Bearer jwt.x.y'), { id: 'u1', email: 'a@b.test' })
  assertEquals(f.jetons, ['jwt.x.y'])
})

Deno.test('identite : signature refusee ou jeton expire, personne', async () => {
  const f = faux({ data: null, error: new Error('Invalid JWT signature') })
  assertEquals(await identiteVerifiee(f.auth, 'Bearer jwt.x.y'), null)
})

Deno.test('identite : sans sub, personne ; sans adresse, adresse nulle', async () => {
  assertEquals(await identiteVerifiee(faux({ data: { claims: {} }, error: null }).auth, 'Bearer j'), null)
  assertEquals(await identiteVerifiee(faux({ data: { claims: { sub: '' } }, error: null }).auth, 'Bearer j'), null)
  assertEquals(
    await identiteVerifiee(faux({ data: { claims: { sub: 'u1' } }, error: null }).auth, 'Bearer j'),
    { id: 'u1', email: null },
  )
})

Deno.test('chauffe : reponse immediate, aucun appel reseau (ni RPC, ni Stripe)', async () => {
  Deno.env.set('STRIPE_SECRET_KEY', 'sk_test_chauffe')
  Deno.env.set('SUPABASE_URL', 'http://127.0.0.1:1')
  Deno.env.set('SUPABASE_ANON_KEY', 'anon_chauffe')
  const fetchAvant = globalThis.fetch
  let appels = 0
  globalThis.fetch = () => {
    appels++
    return Promise.reject(new Error('aucun appel reseau attendu'))
  }
  try {
    const r = await gerer(new Request('http://local/recharge-payer', {
      method: 'POST',
      headers: { Authorization: 'Bearer jwt.x.y', 'Content-Type': 'application/json' },
      body: JSON.stringify({ chauffer: true }),
    }))
    assertEquals(r.status, 200)
    assertEquals(await r.json(), { chaud: true })
    assertEquals(appels, 0)
  } finally {
    globalThis.fetch = fetchAvant
  }
})

Deno.test('chauffe : sans jeton, refusee comme toute demande', async () => {
  Deno.env.set('STRIPE_SECRET_KEY', 'sk_test_chauffe')
  const r = await gerer(new Request('http://local/recharge-payer', {
    method: 'POST',
    body: JSON.stringify({ chauffer: true }),
  }))
  assertEquals(r.status, 401)
  await r.body?.cancel()
})
