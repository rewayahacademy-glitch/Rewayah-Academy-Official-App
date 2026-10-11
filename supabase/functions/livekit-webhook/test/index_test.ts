import { verifierHandler, webhookSigne } from '../../_shared/test_support/edge_handler_contract.ts'
Deno.test('livekit-webhook: signed success; unsigned/bad JSON rejected; no secret or URL in logs', async () => {
  const signed = await webhookSigne()
  const good = { method: 'POST', headers: { Authorization: signed.authorization, 'Content-Type': 'application/json' }, body: signed.corps }
  const unsigned = { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: signed.corps }
  // LiveKit ne possède pas de JWT Supabase ni de rôle; seule la signature du
  // fournisseur authentifie l'événement.
  const signatureFausse = { method: 'POST', headers: { Authorization: 'fake-invalid-signature' }, body: signed.corps }
  await verifierHandler(new URL('../index.ts', import.meta.url).href, {
    succes: good,
    sansJeton: { request: unsigned, statut: 401 },
    roleInterdit: { request: signatureFausse, statut: 401 },
    jsonInvalide: { request: { method: 'POST', body: '{' }, statut: 401 },
  })
})
