// PX-OAUTH 2a : tests Deno de la DECOUVERTE (aucun reseau, aucune base). Ce qu'ils prouvent (PLAN-OAUTH.md §1, §10) :
//  - un 401 de praxis-mcp annonce les metadonnees de ressource (WWW-Authenticate) ; un 200 ne le porte pas ;
//  - `resource` est EXACTEMENT l'URL du serveur MCP, et le seul serveur d'autorisation annonce est la fonction praxis-oauth ;
//  - le serveur d'autorisation n'annonce que ce que nous tiendrons (code + PKCE S256, client public, pas de CIMD) ;
//  - les chemins de decouverte marchent avec ou sans le prefixe /functions/v1 ; les points non faits rendent 503, jamais un jeton ;
//  - le journal ne garde que la methode et le chemin (ni requete, ni en-tete, ni corps).

import { assert, assertEquals, assertFalse } from 'jsr:@std/assert@1'
import { type PortePraxis, traiter } from './mcp.ts'
import { adressesDe, cheminDe, enteteWwwAuthenticate, metadonneesRessource, metadonneesServeur, traiterOauth } from './oauth.ts'

const RACINE = 'https://projet.supabase.co'
const A = adressesDe(RACINE)
const CLE = 'prx_' + 'a'.repeat(64)

function porteInerte(): PortePraxis {
  return { appeler: () => Promise.resolve({ ok: true }) }
}

function mcp(entetes: Record<string, string>): Request {
  return new Request(`${RACINE}/functions/v1/praxis-mcp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...entetes },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'ping' }),
  })
}

Deno.test('adresses : la ressource est l\'URL du serveur MCP, sans barre finale en double', () => {
  assertEquals(A.ressource, 'https://projet.supabase.co/functions/v1/praxis-mcp')
  assertEquals(A.emetteur, 'https://projet.supabase.co/functions/v1/praxis-oauth')
  assertEquals(A.metadonneesRessource, 'https://projet.supabase.co/functions/v1/praxis-oauth/resource')
  assertEquals(adressesDe(RACINE + '///').ressource, A.ressource)
})

Deno.test('401 de praxis-mcp : WWW-Authenticate annonce les metadonnees de ressource', async () => {
  const cas: Record<string, string>[] = [{}, { Authorization: 'Bearer nimporte' }, { Authorization: 'Bearer prx_court' }]
  for (const entetes of cas) {
    const r = await traiter(mcp(entetes), porteInerte(), A)
    assertEquals(r.status, 401)
    assertEquals(r.headers.get('WWW-Authenticate'), enteteWwwAuthenticate(A))
    assertEquals(r.headers.get('WWW-Authenticate'), `Bearer resource_metadata="${A.metadonneesRessource}"`)
    assertEquals(await r.json(), { error: 'cle_refusee' })
  }
})

Deno.test('sans adresses (appel ancien) : le 401 est celui d\'avant, sans en-tete', async () => {
  const r = await traiter(mcp({}), porteInerte())
  assertEquals(r.status, 401)
  assertEquals(r.headers.get('WWW-Authenticate'), null)
})

Deno.test('une reponse 200 ne porte pas WWW-Authenticate', async () => {
  const r = await traiter(mcp({ Authorization: `Bearer ${CLE}` }), porteInerte(), A)
  assertEquals(r.status, 200)
  assertEquals(r.headers.get('WWW-Authenticate'), null)
})

Deno.test('metadonnees de ressource : resource = URL MCP exacte, un seul serveur d\'autorisation', () => {
  const m = metadonneesRessource(A) as { resource: string; authorization_servers: string[] }
  assertEquals(m.resource, A.ressource)
  assertEquals(m.authorization_servers, [A.emetteur])
})

Deno.test('metadonnees du serveur : code + PKCE S256, client public, ni CIMD ni secret', () => {
  const m = metadonneesServeur(A) as Record<string, unknown>
  assertEquals(m.issuer, A.emetteur)
  for (const k of ['authorization_endpoint', 'token_endpoint', 'registration_endpoint']) {
    assert(String(m[k]).startsWith(A.emetteur + '/'), k)
  }
  assertEquals(m.code_challenge_methods_supported, ['S256'])
  assertEquals(m.token_endpoint_auth_methods_supported, ['none'])
  assertEquals(m.response_types_supported, ['code'])
  assertEquals(m.grant_types_supported, ['authorization_code', 'refresh_token'])
  assertFalse('client_id_metadata_document_supported' in m, 'pas de CIMD : Claude passe au DCR')
})

Deno.test('chemins : avec ou sans le prefixe de la plateforme', () => {
  assertEquals(cheminDe('https://x/functions/v1/praxis-oauth/resource'), '/resource')
  assertEquals(cheminDe('https://x/praxis-oauth/resource'), '/resource')
  assertEquals(cheminDe('https://x/praxis-oauth/'), '/')
  assertEquals(cheminDe('https://x/functions/v1/praxis-oauth/.well-known/openid-configuration'), '/.well-known/openid-configuration')
})

for (const chemin of ['/resource', '/.well-known/oauth-protected-resource']) {
  Deno.test(`GET ${chemin} : metadonnees de ressource`, async () => {
    const r = traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth${chemin}`), A, () => {})
    assertEquals(r.status, 200)
    assertEquals(await r.json(), metadonneesRessource(A))
  })
}

for (const chemin of ['/.well-known/openid-configuration', '/.well-known/oauth-authorization-server']) {
  Deno.test(`GET ${chemin} : metadonnees du serveur`, async () => {
    const r = traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth${chemin}`), A, () => {})
    assertEquals(r.status, 200)
    assertEquals(await r.json(), metadonneesServeur(A))
  })
}

Deno.test('/register, /authorize, /token : 503 non disponible, jamais un jeton', async () => {
  for (const [methode, chemin] of [['POST', '/register'], ['GET', '/authorize'], ['POST', '/token'], ['GET', '/token']]) {
    const r = traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth${chemin}`, { method: methode }), A, () => {})
    assertEquals(r.status, 503, `${methode} ${chemin}`)
    const corps = await r.json()
    assertEquals(corps.error, 'temporarily_unavailable')
    assertFalse('access_token' in corps)
  }
})

Deno.test('inconnu : 404 ; methode autre : 405', async () => {
  assertEquals(traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth/autre`), A, () => {}).status, 404)
  assertEquals(traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth/resource`, { method: 'PUT' }), A, () => {}).status, 405)
  assertEquals(traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth/resource`, { method: 'POST' }), A, () => {}).status, 404)
})

Deno.test('journal : methode et chemin seulement, ni requete, ni en-tete, ni corps', () => {
  const lignes: string[] = []
  traiterOauth(
    new Request(`${RACINE}/functions/v1/praxis-oauth/authorize?code=SECRET123&state=ETAT456&code_challenge=CHALL789`, {
      method: 'GET',
      headers: { Authorization: 'Bearer prx_' + 'b'.repeat(64) },
    }),
    A,
    (l) => lignes.push(l),
  )
  assertEquals(lignes, ['praxis-oauth GET /authorize'])
  const tout = lignes.join('\n')
  for (const interdit of ['SECRET123', 'ETAT456', 'CHALL789', 'prx_']) assertFalse(tout.includes(interdit), interdit)
})

Deno.test('OPTIONS : reponse vide ouverte, rien d\'autre', () => {
  const r = traiterOauth(new Request(`${RACINE}/functions/v1/praxis-oauth/resource`, { method: 'OPTIONS' }), A, () => {})
  assertEquals(r.status, 200)
})
