import { assertEquals } from 'jsr:@std/assert@1'

type Handler = (request: Request) => Response | Promise<Response>
let handler: Handler
const deno = Deno as unknown as { serve: (value: Handler) => unknown }
const serve = deno.serve
deno.serve = (value) => { handler = value }
await import('./index.ts?test=agent-session')
deno.serve = serve

Deno.test('agent-session rejects empty and malformed token bodies', async () => {
  for (const request of [new Request('http://local/', { method: 'POST', body: '{}' }), new Request('http://local/', { method: 'POST', body: '{' })]) {
    const response = await handler(request)
    assertEquals(response.status, 400)
  }
})
