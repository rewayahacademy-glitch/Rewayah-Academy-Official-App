import { assertEquals } from 'jsr:@std/assert@1'
type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }; const serve = deno.serve
deno.serve = (value) => { handler = value }; await import('./index.ts?test=session-enfant'); deno.serve = serve
Deno.test('child session rejects malformed JSON before creating a service client', async () => {
  const response = await handler(new Request('http://local/', { method: 'POST', body: '{' }))
  assertEquals(response.status, 400)
})
