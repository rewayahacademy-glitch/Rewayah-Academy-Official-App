import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
const auth = { Authorization: 'Bearer fake-user-token', 'Content-Type': 'application/json' }
const good = { method: 'POST', headers: auth, body: JSON.stringify({ recording_id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd' }) }
Deno.test('archive-seance-acces: success, auth, role, JSON and journal hygiene', async () => {
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ recording_id: 'x' }) }, statut: 401 },
    roleInterdit: { request: good, statut: 403, rpc: 'autoriser_ecoute_archive' },
    jsonInvalide: { request: { method: 'POST', headers: auth, body: '{' }, statut: 400 },
  })
})