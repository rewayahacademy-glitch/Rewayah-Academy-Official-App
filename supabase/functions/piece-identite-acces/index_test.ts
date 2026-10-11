import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=piece-identite-acces'); deno.serve = serve
Deno.test('identity access rejects methods other than POST', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
})

Deno.test('identity access covers caller, authorization, and signed nominal response without logging its URL', async () => {
  const prefix = 'R2_IDENTITY_VAULT'
  const names = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', ...['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME', 'ENDPOINT'].map((name) => `${prefix}_${name}`)]
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const priorLog = console.log
  const logs: string[] = []
  let deny = true
  for (const [key, value] of Object.entries({
    SUPABASE_URL: 'http://supabase.test', SUPABASE_ANON_KEY: 'test-anon-key',
    [`${prefix}_ACCOUNT_ID`]: 'd'.repeat(32), [`${prefix}_ACCESS_KEY_ID`]: 'e'.repeat(32), [`${prefix}_SECRET_ACCESS_KEY`]: 'f'.repeat(64),
    [`${prefix}_BUCKET_NAME`]: 'rewayah-identity-vault', [`${prefix}_ENDPOINT`]: `https://${'d'.repeat(32)}.eu.r2.cloudflarestorage.com`,
  })) Deno.env.set(key, value)
  console.log = (...args: unknown[]) => logs.push(args.join(' '))
  globalThis.fetch = async (input) => {
    const url = String(input)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: '00000000-0000-4000-8000-000000000050' })
    if (url.endsWith('/rest/v1/rpc/autoriser_lecture_piece_identite')) {
      return deny ? Response.json({ code: '42501', message: 'not authorized' }, { status: 403 }) : Response.json({ document_id: '00000000-0000-4000-8000-000000000051', profile_id: '00000000-0000-4000-8000-000000000050', object_key: 'identity/00000000-0000-4000-8000-000000000050/00000000-0000-4000-8000-000000000051', storage_backend: 'r2', doc_type: 'id_card' })
    }
    throw new Error(`unexpected request: ${url}`)
  }
  try {
    assertEquals((await handler(new Request('http://local/', { method: 'POST', body: '{}' }))).status, 401)
    const headers = { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: '{' }))).status, 400)
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ document_id: 'doc-1' }) }))).status, 403)
    deny = false
    const response = await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ document_id: 'doc-1' }) }))
    assertEquals(response.status, 200)
    const body = await response.json()
    assertEquals(body.expire_dans_secondes, 60)
    assertEquals(body.url.includes('X-Amz-Signature='), true)
    assertEquals(logs.some((line) => line.includes('X-Amz-Signature') || line.includes('f'.repeat(64))), false)
  } finally {
    console.log = priorLog
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
