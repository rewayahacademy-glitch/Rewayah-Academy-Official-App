import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
const auth = { Authorization: 'Bearer fake-user-token', 'Content-Type': 'application/json' }
const good = { method: 'POST', headers: auth, body: JSON.stringify({ doc_type: 'id_card', type_mime: 'image/jpeg', taille_octets: 1024 }) }
Deno.test('piece-identite-depot: success, auth, role, JSON and journal hygiene', async () => {
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ doc_type: 'id_card', type_mime: 'image/jpeg', taille_octets: 1024 }) }, statut: 401 },
    roleInterdit: { request: good, statut: 403, rpc: 'preparer_depot_piece_identite' },
    jsonInvalide: { request: { method: 'POST', headers: auth, body: '{' }, statut: 400 },
  })
})