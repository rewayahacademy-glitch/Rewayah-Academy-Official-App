import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=creer-profil-enfant'); deno.serve = serve
Deno.test('child profile creation rejects missing caller before parsing the body', async () => {
  const response = await handler(new Request('http://local/', { method: 'POST', body: '{' }))
  assertEquals(response.status, 401)
})

Deno.test('child profile creation uses the caller and returns the created profile', async () => {
  const priorFetch = globalThis.fetch
  const prior = Object.fromEntries(['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'STUDENT_EMAIL_DOMAIN'].map((key) => [key, Deno.env.get(key)]))
  const calls: string[] = []
  Deno.env.set('SUPABASE_URL', 'http://supabase.test')
  Deno.env.set('SUPABASE_ANON_KEY', 'test-anon-key')
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
  Deno.env.set('STUDENT_EMAIL_DOMAIN', 'example.test')
  globalThis.fetch = async (input, init) => {
    const url = String(input)
    calls.push(`${init?.method ?? 'GET'} ${url}`)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'guardian-1' })
    if (url.endsWith('/auth/v1/admin/users')) return Response.json({ user: { id: '00000000-0000-4000-8000-000000000002' } })
    if (url.endsWith('/rest/v1/rpc/creer_profil_enfant')) return Response.json({ immutable_id: 'immutable-1' })
    throw new Error(`unexpected mocked request: ${url}`)
  }
  try {
    const response = await handler(new Request('http://local/', {
      method: 'POST', headers: { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' },
      body: JSON.stringify({ first_name: 'Amina', last_name: 'Test', age: 9, level: 'A1' }),
    }))
    assertEquals(response.status, 200)
    assertEquals(await response.json(), { profile_id: '00000000-0000-4000-8000-000000000002', immutable_id: 'immutable-1' })
    assertEquals(calls.length, 3)
    assertEquals(calls.some((call) => call.includes('guardian-1')), false)
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})

Deno.test('child profile creation compensates when the household RPC denies access', async () => {
  const priorFetch = globalThis.fetch
  const prior = Object.fromEntries(['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'STUDENT_EMAIL_DOMAIN'].map((key) => [key, Deno.env.get(key)]))
  const calls: string[] = []
  Deno.env.set('SUPABASE_URL', 'http://supabase.test')
  Deno.env.set('SUPABASE_ANON_KEY', 'test-anon-key')
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
  Deno.env.set('STUDENT_EMAIL_DOMAIN', 'example.test')
  globalThis.fetch = async (input, init) => {
    const url = String(input)
    calls.push(`${init?.method ?? 'GET'} ${url}`)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'guardian-1' })
    if (url.endsWith('/auth/v1/admin/users')) return Response.json({ user: { id: '00000000-0000-4000-8000-000000000002' } })
    if (url.endsWith('/rest/v1/rpc/creer_profil_enfant')) return Response.json({ message: 'household access denied', code: '42501' }, { status: 403 })
    if (url.endsWith('/auth/v1/admin/users/00000000-0000-4000-8000-000000000002')) return new Response(null, { status: 204 })
    throw new Error(`unexpected mocked request: ${url}`)
  }
  try {
    const response = await handler(new Request('http://local/', {
      method: 'POST', headers: { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' },
      body: JSON.stringify({ first_name: 'Amina', last_name: 'Test', age: 9 }),
    }))
    assertEquals(response.status, 403)
    assertEquals(calls.some((call) => call.endsWith('DELETE http://supabase.test/auth/v1/admin/users/00000000-0000-4000-8000-000000000002')), true)
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
