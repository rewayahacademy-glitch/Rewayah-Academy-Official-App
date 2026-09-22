import { signerJeton, type AutorisationVideo } from './livekit.ts'

function sourcesDuJeton(jeton: string): unknown {
  const corps = jeton.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')
  const contenu = JSON.parse(atob(corps)) as { video?: { canPublishSources?: unknown } }
  return contenu.video?.canPublishSources
}

Deno.test('le jeton LiveKit borne les sources publiees selon la politique', async () => {
  const ancienneCle = Deno.env.get('LIVEKIT_CLOUD_API_KEY')
  const ancienSecret = Deno.env.get('LIVEKIT_CLOUD_API_SECRET')
  Deno.env.set('LIVEKIT_CLOUD_API_KEY', 'test-core24')
  Deno.env.set('LIVEKIT_CLOUD_API_SECRET', 'secret-local-de-test-core24-assez-long')
  const base: AutorisationVideo = {
    ws_url: 'wss://local.example',
    room_name: 'presence-test',
    provider: 'cloud',
    identity: 'student-test',
    role: 'student',
    ttl_seconds: 300,
    capabilities: {
      can_publish: true,
      can_publish_video: false,
      can_publish_data: false,
      can_subscribe: true,
      hidden: false,
    },
  }

  try {
    const audioSeul = sourcesDuJeton(await signerJeton(base))
    if (JSON.stringify(audioSeul) !== JSON.stringify(['microphone'])) {
      throw new Error(`sources audio inattendues : ${JSON.stringify(audioSeul)}`)
    }
    const avecCamera = sourcesDuJeton(await signerJeton({
      ...base,
      capabilities: { ...base.capabilities, can_publish_video: true },
    }))
    if (JSON.stringify(avecCamera) !== JSON.stringify(['microphone', 'camera'])) {
      throw new Error(`sources camera inattendues : ${JSON.stringify(avecCamera)}`)
    }
  } finally {
    if (ancienneCle === undefined) Deno.env.delete('LIVEKIT_CLOUD_API_KEY')
    else Deno.env.set('LIVEKIT_CLOUD_API_KEY', ancienneCle)
    if (ancienSecret === undefined) Deno.env.delete('LIVEKIT_CLOUD_API_SECRET')
    else Deno.env.set('LIVEKIT_CLOUD_API_SECRET', ancienSecret)
  }
})
