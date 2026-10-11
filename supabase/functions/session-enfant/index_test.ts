import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=session-enfant'); deno.serve = serve
Deno.test('child session rejects malformed JSON before creating a service client', async () => {
  const response = await handler(new Request('http://local/', { method: 'POST', body: '{' }))
  assertEquals(response.status, 400)
})

Deno.test('child session returns a one-time pairing result and hides refused codes', async () => {
  const names = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY']
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const profileId = '00000000-0000-4000-8000-000000000030'
  let deny = true
  Deno.env.set('SUPABASE_URL', 'http://supabase.test')
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
  globalThis.fetch = async (input, init) => {
    const url = String(input)
    if (url.endsWith('/rest/v1/rpc/consommer_code_appairage')) {
      return deny
        ? Response.json({ message: 'code not available', code: 'P0001' }, { status: 400 })
        : Response.json([{ profile_id: profileId, device_token: 'device-test-token' }])
    }
    if (url.endsWith(`/auth/v1/admin/users/${profileId}`)) return Response.json({ id: profileId, email: 'child@example.test' })
    if (url.endsWith('/auth/v1/admin/generate_link')) return Response.json({ hashed_token: 'one-time-hash', action_link: 'https://auth.example.test/verify', email_otp: '123456', redirect_to: '', verification_type: 'magiclink' })
    if (url.includes('/rest/v1/profiles?')) return Response.json([{ first_name: 'Amina' }])
    throw new Error(`unexpected mocked request: ${init?.method ?? 'GET'} ${url}`)
  }
  try {
    const request = () => new Request('http://local/', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ code: 'ABC123', device_fingerprint: 'device-fingerprint', platform: 'android' }) })
    const denied = await handler(request())
    assertEquals(denied.status, 403)
    assertEquals((await denied.json()).error, 'code not available')
    deny = false
    const response = await handler(request())
    const responseText = await response.text()
    assertEquals([response.status, responseText], [200, JSON.stringify({ profile_id: profileId, first_name: 'Amina', token_hash: 'one-time-hash', device_token: 'device-test-token' })])
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
