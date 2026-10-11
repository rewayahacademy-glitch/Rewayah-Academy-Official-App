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
