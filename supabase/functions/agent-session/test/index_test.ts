import { verifierHandler } from '../../_shared/test_support/edge_handler_contract.ts'
Deno.test('agent-session: success, jeton refuse, JSON invalide et journaux', async () => {
  const valid = { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jeton: 'rag_fake_invalid' }) }
  // Ce handler échange un jeton d'agent dans le corps; il n'utilise ni JWT
  // Supabase appelant ni rôle applicatif. Jeton absent = 400; rejet en base = 401.
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: valid,
    sansJeton: { request: { method: 'POST', body: JSON.stringify({ jeton: '' }) }, statut: 400 },
    roleInterdit: { request: valid, statut: 401, rpc: 'remettre_session_agent' },
    jsonInvalide: { request: { method: 'POST', body: '{' }, statut: 400 },
  })
})
