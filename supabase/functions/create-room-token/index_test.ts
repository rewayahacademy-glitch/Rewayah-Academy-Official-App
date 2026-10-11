import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=create-room-token'); deno.serve = serve
Deno.test('room token endpoint returns a controlled configuration gate without provider credentials', async () => {
  const response = await handler(new Request('http://local/', { method: 'POST', body: '{}' }))
  assertEquals(response.status, 503)
  const text = await response.text()
  assertEquals(text.includes('LIVEKIT_'), false)
})

async function withVideoFakes(run: (calls: string[]) => Promise<void>, rpcStatus = 200) {
  const priorFetch = globalThis.fetch
  const names = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'LIVEKIT_CLOUD_API_KEY', 'LIVEKIT_CLOUD_API_SECRET', 'LIVEKIT_CLOUD_WS_URL']
  const prior = Object.fromEntries(names.map((key) => [key, Deno.env.get(key)]))
  const calls: string[] = []
  for (const [key, value] of Object.entries({
    SUPABASE_URL: 'http://supabase.test', SUPABASE_ANON_KEY: 'test-anon-key', SUPABASE_SERVICE_ROLE_KEY: 'test-service-key',
    LIVEKIT_CLOUD_API_KEY: 'test-livekit-key', LIVEKIT_CLOUD_API_SECRET: 'test-livekit-secret', LIVEKIT_CLOUD_WS_URL: 'wss://video.example.test',
  })) Deno.env.set(key, value)
  globalThis.fetch = async (input, init) => {
    const url = String(input)
    calls.push(`${init?.method ?? 'GET'} ${url}`)
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: '00000000-0000-4000-8000-000000000010' })
    if (url.endsWith('/rest/v1/rpc/autoriser_jeton_video')) {
      if (rpcStatus !== 200) return Response.json({ code: '42501', message: 'not authorized' }, { status: rpcStatus })
      return Response.json({ ws_url: 'wss://video.example.test', room_name: 'room-test', provider: 'cloud', identity: 'profile-test', role: 'student', ttl_seconds: 60, capabilities: { can_publish: false, can_publish_video: false, can_publish_data: true, can_subscribe: true, hidden: false }, expire_le: '2026-10-11T00:01:00Z' })
    }
    throw new Error(`unexpected mocked request: ${url}`)
  }
  try { await run(calls) } finally {
    globalThis.fetch = priorFetch
    for (const [key, value] of Object.entries(prior)) value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value)
  }
}

Deno.test('room token rejects missing caller, invalid body, and denied membership', async () => {
  const missing = await withVideoFakes(async () => {
    const response = await handler(new Request('http://local/', { method: 'POST', body: '{}' }))
    assertEquals(response.status, 401)
  })
  assertEquals(missing, undefined)
  await withVideoFakes(async () => {
    const response = await handler(new Request('http://local/', { method: 'POST', headers: { Authorization: 'Bearer test-user-token' }, body: '{' }))
    assertEquals(response.status, 400)
  })
  await withVideoFakes(async () => {
    const response = await handler(new Request('http://local/', { method: 'POST', headers: { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }, body: JSON.stringify({ session_id: 'session-1' }) }))
    assertEquals(response.status, 403)
  }, 403)
})

Deno.test('room token signs an authorized nominal response without logging credentials', async () => {
  await withVideoFakes(async () => {
      const response = await handler(new Request('http://local/', { method: 'POST', headers: { Authorization: 'Bearer test-user-token', 'Content-Type': 'application/json' }, body: JSON.stringify({ session_id: 'session-1' }) }))
      assertEquals(response.status, 200)
      const body = await response.json()
      assertEquals(body.ws_url, 'wss://video.example.test')
      assertEquals(body.room_name, 'room-test')
      assertEquals(typeof body.token, 'string')
      assertEquals(body.token.includes('test-livekit-secret'), false)
  })
})
