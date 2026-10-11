import { assertEquals } from 'jsr:@std/assert@1'
import { SignJWT } from 'npm:jose@5.9.6'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=livekit-webhook'); deno.serve = serve
Deno.test('webhook requires POST and rejects an invalid signature without calling storage', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
  assertEquals((await handler(new Request('http://local/', { method: 'POST', body: '{}' }))).status, 401)
})

Deno.test('webhook accepts a locally signed nominal event and records it through mocked RPC', async () => {
  const names = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'LIVEKIT_CLOUD_API_KEY', 'LIVEKIT_CLOUD_API_SECRET']
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const apiKey = 'test-livekit-api-key'
  const apiSecret = 'test-livekit-secret-for-webhook'
  Deno.env.set('SUPABASE_URL', 'http://supabase.test')
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
  Deno.env.set('LIVEKIT_CLOUD_API_KEY', apiKey)
  Deno.env.set('LIVEKIT_CLOUD_API_SECRET', apiSecret)
  globalThis.fetch = async (input) => {
    const url = String(input)
    if (url.endsWith('/rest/v1/rpc/enregistrer_webhook_livekit')) return Response.json(true)
    throw new Error(`unexpected mocked request: ${url}`)
  }
  try {
    const body = JSON.stringify({ id: 'event-test-1', event: 'participant_joined', room: { name: 'room-test' }, participant: { identity: '00000000-0000-4000-8000-000000000080' }, createdAt: '1791676800' })
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(body))
    const sha256 = btoa(String.fromCharCode(...new Uint8Array(digest)))
    const token = await new SignJWT({ sha256 }).setProtectedHeader({ alg: 'HS256', typ: 'JWT' }).setIssuer(apiKey).setIssuedAt().setExpirationTime('1m').sign(new TextEncoder().encode(apiSecret))
    const response = await handler(new Request('http://local/', { method: 'POST', headers: { Authorization: token }, body }))
    assertEquals(response.status, 200)
    assertEquals(await response.json(), { applique: true, archive: 'sans_objet' })
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
