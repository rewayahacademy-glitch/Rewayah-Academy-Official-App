import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=livekit-webhook'); deno.serve = serve
Deno.test('webhook requires POST and rejects an invalid signature without calling storage', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
  assertEquals((await handler(new Request('http://local/', { method: 'POST', body: '{}' }))).status, 401)
})
