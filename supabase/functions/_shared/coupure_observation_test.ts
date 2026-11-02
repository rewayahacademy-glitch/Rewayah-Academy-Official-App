// Lot O1 (02/11/2026) : la porte de `observation-coupure`, la lecture des
// sorties, et le jeton d'un parent qui regarde (ni micro, ni camera, ni
// partage d'ecran, invisible, duree bornee).
//
// deno test --allow-env --allow-net supabase/functions/_shared/coupure_observation_test.ts

import { assert, assertEquals, assertFalse } from 'jsr:@std/assert@1'
import { egal, lireSorties, porteOuverte } from './coupure_observation.ts'
import { signerJeton } from './livekit.ts'

Deno.test('la porte est fermee sans secret configure, ouverte avec le bon seulement', () => {
  assertFalse(porteOuverte('quelque-chose', undefined))
  assertFalse(porteOuverte('quelque-chose', ''))
  assertFalse(porteOuverte(null, 's3cret'))
  assertFalse(porteOuverte('s3cret-', 's3cret'))
  assertFalse(porteOuverte('S3cret', 's3cret'))
  assert(porteOuverte('s3cret', 's3cret'))
  assert(egal('', ''))
  assertFalse(egal('a', ''))
})

Deno.test('les sorties incompletes sont ecartees, jamais devinees', () => {
  const sorties = lireSorties([
    { visite_id: 'v1', provider: 'cloud', ws_url: 'wss://x', room_name: 'salle', identity: 'p1' },
    { visite_id: 'v2', provider: 'autre', ws_url: 'wss://x', room_name: 'salle', identity: 'p2' },
    { visite_id: 'v3', provider: 'self_hosted', ws_url: '', room_name: 'salle', identity: 'p3' },
    { visite_id: 'v4', provider: 'cloud', ws_url: 'wss://x', room_name: 'salle' },
    null,
    'texte',
  ])
  assertEquals(sorties.map((s) => s.visite_id), ['v1'])
  assertEquals(lireSorties(null), [])
  assertEquals(lireSorties({}), [])
})

function charge(jwt: string): Record<string, unknown> {
  const morceau = jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')
  return JSON.parse(atob(morceau + '='.repeat((4 - (morceau.length % 4)) % 4)))
}

Deno.test('le jeton d\'un parent qui regarde ne publie rien et reste invisible', async () => {
  Deno.env.set('LIVEKIT_CLOUD_API_KEY', 'cle_de_test')
  Deno.env.set('LIVEKIT_CLOUD_API_SECRET', 'secret_de_test_0123456789abcdef0123456789')
  // Ce que `autoriser_jeton_video()` rend pour guardian_observer
  // (scenarios_o1_observation.sql, controle 6).
  const jeton = await signerJeton({
    ws_url: 'wss://exemple.test',
    room_name: 'salle-test',
    provider: 'cloud',
    identity: 'tuteur-test',
    role: 'guardian_observer',
    ttl_seconds: 120,
    capabilities: {
      can_publish: false,
      can_publish_video: false,
      can_publish_data: false,
      can_subscribe: true,
      hidden: true,
    },
  })
  const c = charge(jeton)
  const video = c.video as Record<string, unknown>
  assertEquals(video.canPublish, false)
  assertEquals(video.canPublishData, false)
  assertEquals(video.canPublishSources ?? [], [])
  assertEquals(video.hidden, true)
  assertEquals(video.canSubscribe, true)
  // La duree vient de la base (restant du budget) : au plus 120 s ici.
  const maintenant = Math.floor(Date.now() / 1000)
  assert((c.exp as number) - maintenant <= 121, `exp trop lointain : ${JSON.stringify(c)}`)
})
