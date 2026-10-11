import { AccessToken } from 'npm:livekit-server-sdk@2.13.1'

export interface CasEdge {
  succes: RequestInit
  sansJeton: { request: RequestInit; statut: number; rpc?: string }
  roleInterdit: { request: RequestInit; statut: number; rpc?: string }
  jsonInvalide: { request: RequestInit; statut: number }
}

const URL_SUPABASE = 'https://supabase.test.invalid'
const FAKE_ANON = 'fake-anon-key-for-tests'
const FAKE_SERVICE = 'fake-service-role-key-for-tests'
const FAKE_JWT_SECRET = '0123456789abcdef0123456789abcdef-test-only'
const PROFIL = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
const SESSION = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
const DOCUMENT = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
const RECORDING = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'

const envFake: Record<string, string> = {
  SUPABASE_URL: URL_SUPABASE,
  SUPABASE_ANON_KEY: FAKE_ANON,
  SUPABASE_SERVICE_ROLE_KEY: FAKE_SERVICE,
  ISSUPABASE_JWT_SECRET: FAKE_JWT_SECRET,
  STUDENT_EMAIL_DOMAIN: 'example.test',
  LIVEKIT_CLOUD_API_KEY: 'LK_FAKE_CLOUD',
  LIVEKIT_CLOUD_API_SECRET: 'livekit-cloud-fake-secret-only',
  LIVEKIT_CLOUD_WS_URL: 'wss://livekit.test.invalid',
  LIVEKIT_SELFHOST_API_KEY: 'LK_FAKE_SELFHOST',
  LIVEKIT_SELFHOST_API_SECRET: 'livekit-selfhost-fake-secret-only',
  LIVEKIT_SELFHOST_WS_URL: 'wss://selfhost.test.invalid',
}

const domainesR2 = [
  ['R2_IDENTITY_VAULT', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'rewayah-identity-vault'],
  ['R2_RECORDINGS', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 'rewayah-session-recordings'],
  ['R2_MESSAGING', 'cccccccccccccccccccccccccccccccc', 'rewayah-message-attachments'],
  ['R2_APP_PRIVATE', 'dddddddddddddddddddddddddddddddd', 'rewayah-app-private-storage'],
] as const
for (const [prefix, account, bucket] of domainesR2) {
  envFake[`${prefix}_ACCOUNT_ID`] = account
  envFake[`${prefix}_ACCESS_KEY_ID`] = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
  envFake[`${prefix}_SECRET_ACCESS_KEY`] = 'f'.repeat(64)
  envFake[`${prefix}_BUCKET_NAME`] = bucket
  envFake[`${prefix}_ENDPOINT`] = `https://${account}.eu.r2.cloudflarestorage.com`
}

function reponse(data: unknown, status = 200): Response {
  return new Response(data === null ? null : JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function donneesRpc(nom: string): unknown {
  switch (nom) {
    case 'remettre_session_agent':
      return {
        jeton_id: 'agent-token-id-test',
        profil_observe: PROFIL,
        parcours: 'guardian',
        foyer: PROFIL,
        identite_masquee: true,
        expire_le: new Date(Date.now() + 60_000).toISOString(),
      }
    case 'autoriser_ecoute_archive':
      return {
        recording_id: RECORDING,
        session_id: SESSION,
        object_key: `recordings/${SESSION}/${RECORDING}.ogg`,
        duration_seconds: 60,
        expires_at: new Date(Date.now() + 60_000).toISOString(),
      }
    case 'autoriser_jeton_video':
      return {
        ws_url: 'wss://livekit.test.invalid',
        room_name: 'test-room',
        provider: 'cloud',
        identity: PROFIL,
        role: 'student',
        ttl_seconds: 60,
        expire_le: new Date(Date.now() + 60_000).toISOString(),
        capabilities: {
          can_publish: false,
          can_publish_video: false,
          can_publish_data: true,
          can_subscribe: true,
          hidden: false,
        },
      }
    case 'creer_profil_enfant':
      return { immutable_id: 'CHILD-TEST-001' }
    case 'autoriser_lecture_piece_identite':
      return {
        document_id: DOCUMENT,
        profile_id: PROFIL,
        object_key: 'kyc/test-document',
        storage_backend: 'supabase',
        doc_type: 'id_card',
      }
    case 'peut_deposer_piece_identite':
      return true
    case 'preparer_depot_piece_identite':
      return {
        document_id: DOCUMENT,
        object_key: `identity/${PROFIL}/${DOCUMENT}`,
      }
    case 'confirmer_depot_piece_identite':
      return true
    case 'enregistrer_webhook_livekit':
      return true
    case 'consommer_code_appairage':
      return [{ profile_id: PROFIL, device_token: 'fake-device-token' }]
    case 'profil_du_jeton_appareil':
      return PROFIL
    default:
      return null
  }
}

function urlEtMethode(input: RequestInfo | URL, init?: RequestInit): { url: URL; method: string; auth: string | null } {
  const request = input instanceof Request ? input : null
  const url = new URL(request ? request.url : String(input))
  const method = (init?.method ?? request?.method ?? 'GET').toUpperCase()
  const headers = new Headers(init?.headers ?? request?.headers)
  const auth = headers.get('Authorization')
  return { url, method, auth }
}

async function fetchFactice(
  input: RequestInfo | URL,
  init: RequestInit | undefined,
  rpcRefuse: string | undefined,
  urls: string[],
): Promise<Response> {
  const { url, method, auth } = urlEtMethode(input, init)
  urls.push(url.toString())
  const path = url.pathname

  if (path.endsWith('/auth/v1/user')) {
    return auth === 'Bearer fake-user-token'
      ? reponse({ id: PROFIL, email: 'fixture@example.test' })
      : reponse({ message: 'invalid token' }, 401)
  }
  if (path.endsWith('/auth/v1/admin/users') && method === 'POST') {
    return reponse({ id: PROFIL, email: 'child@example.test' })
  }
  if (/\/auth\/v1\/admin\/users\//.test(path)) {
    return reponse({ user: { id: PROFIL, email: 'child@example.test' } })
  }
  if (path.endsWith('/auth/v1/admin/generate_link')) {
    return reponse({ hashed_token: 'fake-hashed-token' })
  }
  if (path.includes('/rest/v1/rpc/')) {
    const nom = decodeURIComponent(path.slice(path.lastIndexOf('/') + 1))
    if (rpcRefuse === nom) {
      return reponse({ code: '42501', message: 'role not authorized' }, 403)
    }
    return reponse(donneesRpc(nom))
  }
  if (path.includes('/rest/v1/kyc_documents')) {
    return reponse({
      id: DOCUMENT,
      profile_id: PROFIL,
      storage_backend: 'r2',
      status: 'pending',
      deleted_at: null,
    })
  }
  if (path.includes('/rest/v1/profiles')) return reponse({ first_name: 'Test' })
  if (path.includes('/storage/v1/object/sign/')) {
    return reponse({ signedURL: '/storage/v1/object/sign/fake' })
  }
  if (method === 'HEAD') return new Response(null, { status: 200 })
  return reponse({})
}

export async function webhookSigne(): Promise<{ corps: string; authorization: string }> {
  const corps = JSON.stringify({
    id: 'fake-event-id',
    event: 'participant_joined',
    createdAt: Math.floor(Date.now() / 1000),
    room: { name: 'test-room' },
    participant: { identity: PROFIL },
  })
  const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(corps))
  const sha256 = btoa(Array.from(new Uint8Array(bytes), (value) => String.fromCharCode(value)).join(''))
  const token = new AccessToken('LK_FAKE_CLOUD', 'livekit-cloud-fake-secret-only', { identity: 'webhook-test' })
  token.sha256 = sha256
  return { corps, authorization: await token.toJwt() }
}

export async function verifierHandler(
  moduleUrl: string,
  cas: CasEdge,
): Promise<void> {
  for (const [nom, valeur] of Object.entries(envFake)) {
    Deno.env.set(nom, valeur)
  }

  const ancienFetch = globalThis.fetch
  const ancienServe = Deno.serve
  let handler: ((request: Request) => Response | Promise<Response>) | undefined
  Deno.serve = ((serveHandler: (request: Request) => Response | Promise<Response>) => {
    handler = serveHandler
    return undefined as unknown as Deno.HttpServer
  }) as typeof Deno.serve

  try {
    await import(`${moduleUrl}?edge-test=${crypto.randomUUID()}`)
  } finally {
    Deno.serve = ancienServe
  }
  if (!handler) throw new Error(`Deno.serve non capturأ© pour ${moduleUrl}`)

  const logs: string[] = []
  const urls: string[] = []
  const savedConsole = { log: console.log, warn: console.warn, error: console.error }
  const capture = (...args: unknown[]) => logs.push(args.map((arg) => {
    if (arg instanceof Error) return `${arg.name}: ${arg.message}`
    if (typeof arg === 'object' && arg !== null) return JSON.stringify(arg)
    return String(arg)
  }).join(' '))
  console.log = capture
  console.warn = capture
  console.error = capture

  async function appeler(requestInit: RequestInit, rpcRefuse?: string): Promise<Response> {
    globalThis.fetch = (input: RequestInfo | URL, init?: RequestInit) =>
      fetchFactice(input, init, rpcRefuse, urls)
    return await handler!(new Request('http://edge.test.invalid/function', requestInit))
  }

  async function verifierStatut(label: string, request: RequestInit, expected: number, rpcRefuse?: string) {
    const response = await appeler(request, rpcRefuse)
    if (response.status !== expected) {
      const diagnostic = logs.join(' | ')
        .replace(/https?:\/\/\S+/gi, '[URL masquأ©e]')
        .replaceAll(URL_SUPABASE, '[URL masquأ©e]')
        .replaceAll(FAKE_SERVICE, '[clأ© factice masquأ©e]')
        .replaceAll(FAKE_ANON, '[clأ© factice masquأ©e]')
        .replaceAll(FAKE_JWT_SECRET, '[secret factice masquأ©]')
      const chemins = urls.map((url) => new URL(url).pathname).join(', ')
      throw new Error(`${label}: attendu HTTP ${expected}, obtenu ${response.status}: ${await response.text()}; chemins=${chemins}; journaux=${diagnostic}`)
    }
  }

  try {
    await verifierStatut('succأ¨s simulأ©', cas.succes, 200)
    await verifierStatut('absence de jeton / preuve', cas.sansJeton.request, cas.sansJeton.statut, cas.sansJeton.rpc)
    await verifierStatut('rأ´le ou autorisation refusأ©', cas.roleInterdit.request, cas.roleInterdit.statut, cas.roleInterdit.rpc)
    await verifierStatut('JSON invalide', cas.jsonInvalide.request, cas.jsonInvalide.statut)

    const texteLogs = logs.join('\n')
    const valeursSensibles = [
      URL_SUPABASE,
      FAKE_ANON,
      FAKE_SERVICE,
      FAKE_JWT_SECRET,
      'livekit-cloud-fake-secret-only',
      'livekit-selfhost-fake-secret-only',
      'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      'f'.repeat(64),
    ]
    if (/https?:\/\//i.test(texteLogs)) throw new Error(`URL trouvأ©e dans les journaux: ${texteLogs}`)
    for (const valeur of valeursSensibles) {
      if (texteLogs.includes(valeur)) throw new Error('une valeur de configuration factice apparaأ®t dans les journaux')
    }
    if (urls.some((url) => !url.includes('supabase.test.invalid') && !url.includes('.r2.cloudflarestorage.com'))) {
      throw new Error(`fetch simulأ© vers une destination inattendue: ${urls.join(', ')}`)
    }
  } finally {
    console.log = savedConsole.log
    console.warn = savedConsole.warn
    console.error = savedConsole.error
    globalThis.fetch = ancienFetch
    for (const nom of Object.keys(envFake)) Deno.env.delete(nom)
  }
}

