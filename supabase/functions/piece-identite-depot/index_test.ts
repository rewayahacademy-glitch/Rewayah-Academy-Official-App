import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=piece-identite-depot'); deno.serve = serve
Deno.test('identity upload rejects methods other than POST', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
})

Deno.test('identity upload validates input, denies refused reservation, and returns a signed nominal URL', async () => {
  const prefix = 'R2_IDENTITY_VAULT'
  const names = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', ...['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME', 'ENDPOINT'].map((name) => `${prefix}_${name}`)]
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const priorFetch = globalThis.fetch
  const priorLog = console.log
  const logs: string[] = []
  const profileId = '00000000-0000-4000-8000-000000000060'
  const documentId = '00000000-0000-4000-8000-000000000061'
  let deny = true
  for (const [key, value] of Object.entries({
    SUPABASE_URL: 'http://supabase.test', SUPABASE_ANON_KEY: 'test-anon-key',
    [`${prefix}_ACCOUNT_ID`]: '1'.repeat(32), [`${prefix}_ACCESS_KEY_ID`]: '2'.repeat(32), [`${prefix}_SECRET_ACCESS_KEY`]: '3'.repeat(64),
    [`${prefix}_BUCKET_NAME`]: 'rewayah-identity-vault', [`${prefix}_ENDPOINT`]: `https://${'1'.repeat(32)}.eu.r2.cloudflarestorage.com`,
  })) Deno.env.set(key, value)
  console.log = (...args: unknown[]) => logs.push(args.join(' '))
  globalThis.fetch = async (input) => {
    const url = String(input)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: profileId })
    if (url.endsWith('/rest/v1/rpc/preparer_depot_piece_identite')) {
      return deny ? Response.json({ code: '42501', message: 'deposit denied' }, { status: 403 }) : Response.json({ document_id: documentId, object_key: `identity/${profileId}/${documentId}` })
    }
    throw new Error(`unexpected request: ${url}`)
  }
  try {
    const headers = { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: '{' }))).status, 400)
    const payload = { doc_type: 'id_card', type_mime: 'image/jpeg', taille_octets: 256 }
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify({ ...payload, type_mime: 'text/plain' }) }))).status, 400)
    assertEquals((await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify(payload) }))).status, 403)
    deny = false
    const response = await handler(new Request('http://local/', { method: 'POST', headers, body: JSON.stringify(payload) }))
    assertEquals(response.status, 200)
    const body = await response.json()
    assertEquals(body.document_id, documentId)
    assertEquals(body.methode, 'PUT')
    assertEquals(body.expire_dans_secondes, 120)
    assertEquals(body.url.includes('X-Amz-Signature='), true)
    assertEquals(body.url.includes('3'.repeat(64)), false)
    assertEquals(logs.some((line) => line.includes('X-Amz-Signature') || line.includes('3'.repeat(64))), false)
  } finally {
    console.log = priorLog
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
})
