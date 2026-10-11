import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
const auth = { Authorization: 'Bearer fake-user-token', 'Content-Type': 'application/json' }
const good = { method: 'POST', headers: auth, body: JSON.stringify({ first_name: 'Enfant', last_name: 'Test', age: 8 }) }
Deno.test('creer-profil-enfant: success, auth, role, JSON and journal hygiene', async () => {
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ first_name: 'x', last_name: 'y', age: 8 }) }, statut: 401 },
    roleInterdit: { request: good, statut: 403, rpc: 'creer_profil_enfant' },
    jsonInvalide: { request: { method: 'POST', headers: auth, body: '{' }, statut: 400 },
  })
})