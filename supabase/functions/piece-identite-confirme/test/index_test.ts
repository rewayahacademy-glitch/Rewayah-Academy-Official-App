import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
const auth = { Authorization: 'Bearer fake-user-token', 'Content-Type': 'application/json' }
const good = { method: 'POST', headers: auth, body: JSON.stringify({ document_id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' }) }
Deno.test('piece-identite-confirme: success, auth, role, JSON and journal hygiene', async () => {
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ document_id: 'x' }) }, statut: 401 },
    roleInterdit: { request: good, statut: 403, rpc: 'peut_deposer_piece_identite' },
    jsonInvalide: { request: { method: 'POST', headers: auth, body: '{' }, statut: 400 },
  })
})