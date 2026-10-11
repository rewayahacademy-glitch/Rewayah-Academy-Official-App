import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=piece-identite-confirme'); deno.serve = serve
Deno.test('identity confirmation rejects methods other than POST', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
})

Deno.test('identity confirmation denies another profile and confirms a present object using local fakes', async () => {
  const prefix = 'R2_IDENTITY_VAULT'
  const names = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', ...['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME', 'ENDPOINT'].map((name) => `${prefix}_${name}`)]
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const profileId = '00000000-0000-4000-8000-000000000070'
  const documentId = '00000000-0000-4000-8000-000000000071'
  let deny = true
  for (const [key, value] of Object.entries({
    SUPABASE_URL: 'http://supabase.test', SUPABASE_ANON_KEY: 'test-anon-key', SUPABASE_SERVICE_ROLE_KEY: 'test-service-key',
    [`${prefix}_ACCOUNT_ID`]: '4'.repeat(32), [`${prefix}_ACCESS_KEY_ID`]: '5'.repeat(32), [`${prefix}_SECRET_ACCESS_KEY`]: '6'.repeat(64),
    [`${prefix}_BUCKET_NAME`]: 'rewayah-identity-vault', [`${prefix}_ENDPOINT`]: `https://${'4'.repeat(32)}.eu.r2.cloudflarestorage.com`,
  })) Deno.env.set(key, value)
  globalThis.fetch = async (input, init) => {
    const url = input instanceof Request ? input.url : String(input)
    const method = init?.method ?? (input instanceof Request ? input.method : 'GET')
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: profileId })
    if (url.includes('/rest/v1/kyc_documents?')) return Response.json([{ id: documentId, profile_id: profileId, storage_backend: 'r2', status: 'pending', deleted_at: '2026-10-11T00:00:00Z' }])
    if (url.endsWith('/rest/v1/rpc/peut_deposer_piece_identite')) return Response.json(!deny)
    if (url.endsWith('/rest/v1/rpc/confirmer_depot_piece_identite')) return Response.json(true)
    if (method === 'HEAD' && url.includes(`/identity/${profileId}/${documentId}`)) return new Response(null, { status: 200 })
    throw new Error(`unexpected request: ${method} ${url}`)
  }
  try {
    const headers = { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: '{' }))).status, 400)
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ document_id: 'invalid' }) }))).status, 400)
    const payload = JSON.stringify({ document_id: documentId })
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: payload }))).status, 403)
    deny = false
    const response = await handler(new Request('http://local/', { method: 'POST', headers, body: payload }))
    assertEquals(response.status, 200)
    assertEquals(await response.json(), { confirme: true, document_id: documentId })
  } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
