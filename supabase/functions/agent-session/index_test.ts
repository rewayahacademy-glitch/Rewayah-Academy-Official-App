import { assertEquals } from 'jsr:@std/assert@1'

type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }
const serve = deno.serve
deno.serve = (value) => { handler = value }
await import('./index.ts?test=agent-session')
deno.serve = serve

Deno.test('agent-session rejects empty and malformed token bodies', async () => {
  for (const request of [new Request('http://local/', { method: 'POST', body: '{}' }), new Request('http://local/', { method: 'POST', body: '{' })]) {
    const response = await handler(request)
    assertEquals(response.status, 400)
  }
})

Deno.test('agent-session refuses database-denied tokens and signs a nominal read-only session', async () => {
  const names = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'ISSUPABASE_JWT_SECRET']
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  Deno.env.set('SUPABASE_URL', 'http://supabase.test')
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
  Deno.env.set('ISSUPABASE_JWT_SECRET', 'test-signing-secret-with-at-least-32-bytes')
  let deny = true
  globalThis.fetch = async (input) => {
    const url = String(input)
    if (url.endsWith('/rest/v1/rpc/remettre_session_agent')) {
      return deny
        ? Response.json({ code: '42501', message: 'denied' }, { status: 403 })
        : Response.json({ jeton_id: 'token-id', profil_observe: '00000000-0000-4000-8000-000000000020', parcours: 'controller', foyer: null, identite_masquee: true, expire_le: new Date(Date.now() + 120_000).toISOString() })
    }
    throw new Error(`unexpected mocked request: ${url}`)
  }
  try {
    const request = () => new Request('http://local/', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jeton: 'rag-test-token' }) })
    const denied = await handler(request())
    assertEquals(denied.status, 401)
    deny = false
    const response = await handler(request())
    assertEquals(response.status, 200)
    const body = await response.json()
    assertEquals(body.parcours, 'controller')
    assertEquals(body.identite_masquee, true)
    const payload = JSON.parse(atob(body.access_token.split('.')[1]))
    assertEquals(payload.role, 'agent_ro')
    assertEquals(payload.sub, '00000000-0000-4000-8000-000000000020')
    assertEquals(body.access_token.includes('test-signing-secret'), false)
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
