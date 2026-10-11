import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=archive-seance-acces'); deno.serve = serve
Deno.test('archive access rejects methods other than POST without network calls', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
})

Deno.test('archive access covers unauthenticated, invalid, denied, and nominal paths with local fakes', async () => {
  const prefix = 'R2_RECORDINGS'
  const names = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', ...['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME', 'ENDPOINT'].map((name) => `${prefix}_${name}`)]
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const priorLog = console.log
  const logs: string[] = []
  let deny = true
  for (const [key, value] of Object.entries({
    SUPABASE_URL: 'http://supabase.test', SUPABASE_ANON_KEY: 'test-anon-key',
    [`${prefix}_ACCOUNT_ID`]: 'a'.repeat(32), [`${prefix}_ACCESS_KEY_ID`]: 'b'.repeat(32), [`${prefix}_SECRET_ACCESS_KEY`]: 'c'.repeat(64),
    [`${prefix}_BUCKET_NAME`]: 'rewayah-session-recordings', [`${prefix}_ENDPOINT`]: `https://${'a'.repeat(32)}.eu.r2.cloudflarestorage.com`,
  })) Deno.env.set(key, value)
  console.log = (...args: unknown[]) => logs.push(args.join(' '))
  globalThis.fetch = async (input) => {
    const url = String(input)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: '00000000-0000-4000-8000-000000000040' })
    if (url.endsWith('/rest/v1/rpc/autoriser_ecoute_archive')) {
      return deny ? Response.json({ code: '42501', message: 'not a participant' }, { status: 403 }) : Response.json({ recording_id: '00000000-0000-4000-8000-000000000041', session_id: '00000000-0000-4000-8000-000000000042', object_key: 'recordings/00000000-0000-4000-8000-000000000042/00000000-0000-4000-8000-000000000041.ogg', duration_seconds: 90, expires_at: '2026-10-11T00:01:00Z' })
    }
    throw new Error(`unexpected request: ${url}`)
  }
  try {
    const noAuth = await handler(new Request('http://local/', { method: 'POST', body: '{}' }))
    assertEquals(noAuth.status, 401)
    const headers = { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: '{' }))).status, 400)
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ recording_id: 'rec-1' }) }))).status, 403)
    deny = false
    const response = await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ recording_id: 'rec-1' }) }))
    assertEquals(response.status, 200)
    const body = await response.json()
    assertEquals(body.expire_dans_secondes, 60)
    assertEquals(body.url.includes('X-Amz-Signature='), true)
    assertEquals(body.url.includes('c'.repeat(64)), false)
    assertEquals(logs.some((line) => line.includes('X-Amz-Signature') || line.includes('c'.repeat(64))), false)
  } finally {
    console.log = priorLog
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
