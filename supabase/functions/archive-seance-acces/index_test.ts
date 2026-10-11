import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=archive-seance-acces'); deno.serve = serve
Deno.test('archive access rejects methods other than POST without network calls', async () => {
  assertEquals((await handler(new Request('http://local/', { method: 'GET' }))).status, 405)
})
