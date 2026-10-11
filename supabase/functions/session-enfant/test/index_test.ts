import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
const good = { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ code: 'FAKECODE', device_fingerprint: 'fixture-device', platform: 'web' }) }
Deno.test('session-enfant: appairage sans JWT, refus de code, JSON invalide et journaux', async () => {
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }, statut: 400 },
    roleInterdit: { request: good, statut: 403, rpc: 'consommer_code_appairage' },
    jsonInvalide: { request: { method: 'POST', body: '{' }, statut: 400 },
  })
})