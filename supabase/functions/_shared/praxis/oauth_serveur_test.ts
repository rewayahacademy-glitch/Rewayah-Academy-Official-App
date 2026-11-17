// PX-OAUTH 2c : tests Deno du serveur d'autorisation (aucun reseau, la base est un faux qui note ses appels). Ce qu'ils prouvent :
//  - /register : JSON seulement, client public, rappels transmis tels quels a la base (qui tient la liste blanche), debit -> 429 ;
//  - /authorize : un client ou un rappel inconnu ne redirige JAMAIS (page d'erreur) ; une demande valable va a la page de consentement
//    de l'application ; une erreur de forme revient au client avec son etat seulement apres que la base a prouve le rappel ;
//  - /token : form-urlencoded seulement, les deux octrois, toute erreur d'octroi = invalid_grant sans cause, jamais de cache ;
//  - le debit (par adresse et global) coupe avant la base ; le journal ne garde que methode et chemin ;
//  - praxis-mcp rend 401 sur une cle dont la base dit `false`, et seulement alors.

import { assert, assertEquals, assertFalse } from 'jsr:@std/assert@1'
import { creerLimiteur } from './limiteur.ts'
import { type PortePraxis, traiter } from './mcp.ts'
import { adressesDe } from './oauth.ts'
import { type Contexte, LIMITE_GLOBALE, LIMITE_REGISTER, LIMITE_TOKEN, traiterServeur } from './oauth_serveur.ts'

const RACINE = 'https://projet.supabase.co'
const O = `${RACINE}/functions/v1/praxis-oauth`
const CLIENT = 'prxc_' + '1'.repeat(32)
const RAPPEL = 'https://claude.ai/api/mcp/auth_callback'
const DEMANDE = '5a130000-0000-4000-8000-000000000001'

interface Appel { fonction: string; params: Record<string, unknown> }

function contexte(reponse: unknown | (() => unknown), maintenant = () => 0): { c: Contexte; appels: Appel[]; journal: string[] } {
  const appels: Appel[] = []
  const journal: string[] = []
  const porte: PortePraxis = {
    appeler(fonction, params) {
      appels.push({ fonction, params })
      if (reponse instanceof Error) return Promise.reject(reponse)
      return Promise.resolve(typeof reponse === 'function' ? (reponse as () => unknown)() : reponse)
    },
  }
  return {
    appels,
    journal,
    c: {
      adresses: adressesDe(RACINE), porte, limiteur: creerLimiteur(maintenant), adresseApp: 'https://app.test',
      adresseDe: (req) => req.headers.get('x-forwarded-for') ?? 'a', journal: (l) => journal.push(l),
    },
  }
}

const json = (chemin: string, corps: unknown, entetes: Record<string, string> = {}) =>
  new Request(`${O}${chemin}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...entetes }, body: JSON.stringify(corps) })
const form = (corps: Record<string, string>, entetes: Record<string, string> = {}) =>
  new Request(`${O}/token`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', ...entetes }, body: new URLSearchParams(corps).toString() })
const autoriser = (q: Record<string, string>) => new Request(`${O}/authorize?${new URLSearchParams(q)}`)
const QUERY = { response_type: 'code', client_id: CLIENT, redirect_uri: RAPPEL, code_challenge: 'a'.repeat(43), code_challenge_method: 'S256', state: 'etat 1&x' }

Deno.test('/register : un client public, rappels transmis a la base, reponse RFC 7591', async () => {
  const { c, appels } = contexte({ client_id: CLIENT, nom: 'Claude', rappels: [RAPPEL] })
  const r = await traiterServeur(json('/register', { client_name: 'Claude', redirect_uris: [RAPPEL], token_endpoint_auth_method: 'none', extra: 1 }), c)
  assertEquals(r.status, 201)
  assertEquals(await r.json(), {
    client_id: CLIENT, client_name: 'Claude', redirect_uris: [RAPPEL], grant_types: ['authorization_code', 'refresh_token'],
    response_types: ['code'], token_endpoint_auth_method: 'none',
  })
  assertEquals(appels, [{ fonction: 'praxis_oauth_enregistrer', params: { p_nom: 'Claude', p_rappels: [RAPPEL] } }])
  assertEquals(r.headers.get('Cache-Control'), 'no-store')
})

Deno.test('/register : refus avant la base (type, forme, secret client), erreurs de la base traduites', async () => {
  const cas: Request[] = [
    new Request(`${O}/register`, { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: '{}' }),
    new Request(`${O}/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: 'pas du json' }),
    json('/register', [1]),
    json('/register', { client_name: 'X' }),
    json('/register', { redirect_uris: [RAPPEL, 3] }),
    json('/register', { redirect_uris: [RAPPEL], token_endpoint_auth_method: 'client_secret_basic' }),
    json('/register', { redirect_uris: [RAPPEL], pad: 'x'.repeat(5000) }),
  ]
  for (const req of cas) {
    const { c, appels } = contexte({})
    const r = await traiterServeur(req, c)
    assert(r.status === 400 || r.status === 413, `statut ${r.status}`)
    assertEquals(appels.length, 0)
  }
  const { c } = contexte({ erreur: 'invalid_redirect_uri' })
  const r = await traiterServeur(json('/register', { redirect_uris: ['https://evil.example/cb'] }), c)
  assertEquals(r.status, 400)
  assertEquals(await r.json(), { error: 'invalid_redirect_uri' })
  const d = contexte({ erreur: 'debit' })
  assertEquals((await traiterServeur(json('/register', { redirect_uris: [RAPPEL] }), d.c)).status, 429)
  const e = contexte(new Error('rpc'))
  assertEquals((await traiterServeur(json('/register', { redirect_uris: [RAPPEL] }), e.c)).status, 503)
})

Deno.test('/authorize : une demande valable mene a la page de consentement, sans rien d\'autre dans l\'adresse', async () => {
  const { c, appels } = contexte({ demande: DEMANDE })
  const r = await traiterServeur(autoriser(QUERY), c)
  assertEquals(r.status, 302)
  assertEquals(r.headers.get('Location'), `https://app.test/praxis/autoriser?demande=${DEMANDE}`)
  assertEquals(appels, [{ fonction: 'praxis_oauth_demander', params: {
    p_client: CLIENT, p_rappel: RAPPEL, p_challenge: 'a'.repeat(43), p_methode: 'S256', p_etat: 'etat 1&x', p_scope: null,
  } }])
})

Deno.test('/authorize : client ou rappel inconnu = page d\'erreur, JAMAIS de redirection ; reponse_type autre = refus avant la base', async () => {
  for (const erreur of ['client_inconnu', 'redirect_invalide']) {
    const { c } = contexte({ erreur })
    const r = await traiterServeur(autoriser({ ...QUERY, redirect_uri: 'https://evil.example/cb' }), c)
    assertEquals(r.status, 400)
    assertEquals(r.headers.get('Location'), null)
    assert((r.headers.get('Content-Type') ?? '').startsWith('text/html'))
    assertFalse((await r.text()).includes('evil.example'))
  }
  const { c, appels } = contexte({})
  assertEquals((await traiterServeur(autoriser({ ...QUERY, response_type: 'token' }), c)).status, 400)
  assertEquals(appels.length, 0)
  const d = contexte({ erreur: 'debit' })
  assertEquals((await traiterServeur(autoriser(QUERY), d.c)).status, 429)
})

Deno.test('/authorize : requete de forme invalide (rappel prouve) revient au client avec son etat', async () => {
  const { c } = contexte({ erreur: 'requete_invalide' })
  const r = await traiterServeur(autoriser({ ...QUERY, code_challenge_method: 'plain' }), c)
  assertEquals(r.status, 302)
  const dest = new URL(r.headers.get('Location')!)
  assertEquals(`${dest.origin}${dest.pathname}`, RAPPEL)
  assertEquals(dest.searchParams.get('error'), 'invalid_request')
  assertEquals(dest.searchParams.get('state'), 'etat 1&x')
})

Deno.test('/token : echange du code et renouvellement, form-urlencoded, jamais de cache', async () => {
  const jetons = { access_token: 'prx_x', token_type: 'Bearer', expires_in: 3600, refresh_token: 'prxr_x', scope: 'praxis' }
  {
    const { c, appels } = contexte(jetons)
    const r = await traiterServeur(form({ grant_type: 'authorization_code', client_id: CLIENT, code: 'c'.repeat(64), redirect_uri: RAPPEL, code_verifier: 'v'.repeat(43) }), c)
    assertEquals(r.status, 200)
    assertEquals(await r.json(), jetons)
    assertEquals(r.headers.get('Cache-Control'), 'no-store')
    assertEquals(r.headers.get('Pragma'), 'no-cache')
    assertEquals(appels, [{ fonction: 'praxis_oauth_echanger', params: { p_client: CLIENT, p_code: 'c'.repeat(64), p_rappel: RAPPEL, p_verifier: 'v'.repeat(43) } }])
  }
  {
    const { c, appels } = contexte(jetons)
    const r = await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'prxr_' + 'd'.repeat(64) }), c)
    assertEquals(r.status, 200)
    assertEquals(appels, [{ fonction: 'praxis_oauth_renouveler', params: { p_client: CLIENT, p_refresh: 'prxr_' + 'd'.repeat(64) } }])
  }
})

Deno.test('/token : erreurs : invalid_grant sans cause, type de contenu, type d\'octroi, base en panne', async () => {
  const { c } = contexte({ erreur: 'invalid_grant' })
  const r = await traiterServeur(form({ grant_type: 'authorization_code', client_id: CLIENT, code: 'x' }), c)
  assertEquals(r.status, 400)
  assertEquals(await r.json(), { error: 'invalid_grant' })
  const q = contexte({ erreur: 'invalid_request' })
  assertEquals(await (await traiterServeur(form({ grant_type: 'refresh_token' }), q.c)).json(), { error: 'invalid_request' })
  const j = contexte({})
  const rj = await traiterServeur(new Request(`${O}/token`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: `grant_type=refresh_token&client_id=${CLIENT}&refresh_token=x` }), j.c)
  assertEquals(rj.status, 400)
  assertEquals(j.appels.length, 0)
  const u = contexte({})
  const ru = await traiterServeur(form({ grant_type: 'password' }), u.c)
  assertEquals(await ru.json(), { error: 'unsupported_grant_type' })
  assertEquals(u.appels.length, 0)
  const e = contexte(new Error('rpc'))
  assertEquals((await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }), e.c)).status, 503)
})

Deno.test('debit : par adresse puis global, avant la base ; une autre adresse passe', async () => {
  const { c, appels } = contexte({ client_id: CLIENT, nom: 'C', rappels: [RAPPEL] })
  for (let i = 0; i < LIMITE_REGISTER.max; i++) {
    assertEquals((await traiterServeur(json('/register', { redirect_uris: [RAPPEL] }, { 'x-forwarded-for': '1.1.1.1' }), c)).status, 201)
  }
  const refuse = await traiterServeur(json('/register', { redirect_uris: [RAPPEL] }, { 'x-forwarded-for': '1.1.1.1' }), c)
  assertEquals(refuse.status, 429)
  assert(Number(refuse.headers.get('Retry-After')) >= 1)
  assertEquals(appels.length, LIMITE_REGISTER.max)
  assertEquals((await traiterServeur(json('/register', { redirect_uris: [RAPPEL] }, { 'x-forwarded-for': '2.2.2.2' }), c)).status, 201)
  // /token a sa propre fenetre.
  const t = contexte({ erreur: 'invalid_grant' })
  for (let i = 0; i < LIMITE_TOKEN.max; i++) await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }), t.c)
  assertEquals((await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }), t.c)).status, 429)
})

Deno.test('debit global : toutes adresses confondues, avant la base', async () => {
  const { c, appels } = contexte({ erreur: 'invalid_grant' })
  for (let i = 0; i < LIMITE_GLOBALE.max; i++) {
    const r = await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }, { 'x-forwarded-for': `10.0.${i >> 8}.${i & 255}` }), c)
    assertEquals(r.status, 400)
  }
  const refuse = await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }, { 'x-forwarded-for': '9.9.9.9' }), c)
  assertEquals(refuse.status, 429)
  assertEquals(appels.length, LIMITE_GLOBALE.max)
})

Deno.test('limiteur : la fenetre se rouvre ; journal : methode et chemin seulement', async () => {
  let t = 0
  const { c, journal } = contexte({ erreur: 'invalid_grant' }, () => t)
  for (let i = 0; i < LIMITE_TOKEN.max; i++) await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'secret-a-ne-pas-journaliser' }), c)
  assertEquals((await traiterServeur(form({ grant_type: 'refresh_token' }), c)).status, 429)
  t += LIMITE_TOKEN.fenetreMs
  assertEquals((await traiterServeur(form({ grant_type: 'refresh_token', client_id: CLIENT, refresh_token: 'x' }), c)).status, 400)
  assert(journal.every((l) => l === 'praxis-oauth POST /token'))
  assertFalse(journal.join('').includes('secret'))
})

Deno.test('decouverte et chemins inconnus restent ceux de 2a ; mauvaise methode = 405', async () => {
  const { c } = contexte({})
  assertEquals((await traiterServeur(new Request(`${O}/resource`), c)).status, 200)
  assertEquals((await traiterServeur(new Request(`${O}/inconnu`), c)).status, 404)
  assertEquals((await traiterServeur(new Request(`${O}/token`), c)).status, 405)
  assertEquals((await traiterServeur(new Request(`${O}/authorize`, { method: 'POST' }), c)).status, 405)
})

Deno.test('praxis-mcp : 401 seulement quand la base dit `false` ; erreur de verification = l\'appel continue', async () => {
  const A = adressesDe(RACINE)
  const cle = 'prx_' + 'a'.repeat(64)
  const req = () => new Request(`${RACINE}/functions/v1/praxis-mcp`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${cle}` },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'ping' }),
  })
  const porte = (valeur: unknown): { p: PortePraxis; appels: Appel[] } => {
    const appels: Appel[] = []
    return { appels, p: { appeler: (fonction, params) => { appels.push({ fonction, params }); return valeur instanceof Error ? Promise.reject(valeur) : Promise.resolve(valeur) } } }
  }
  const refus = porte(false)
  const r = await traiter(req(), refus.p, A, true)
  assertEquals(r.status, 401)
  assert((r.headers.get('WWW-Authenticate') ?? '').includes('resource_metadata'))
  assertEquals(refus.appels, [{ fonction: 'praxis_cle_valide', params: { p_cle: cle } }])
  assertEquals((await traiter(req(), porte(true).p, A, true)).status, 200)
  assertEquals((await traiter(req(), porte(new Error('rpc')).p, A, true)).status, 200)
  assertEquals((await traiter(req(), porte({ erreur: 'eteint' }).p, A, true)).status, 200)
  // Sans le controle (tests et appels anciens) : aucune verification, aucun appel.
  const sans = porte(false)
  assertEquals((await traiter(req(), sans.p, A)).status, 200)
  assertEquals(sans.appels.length, 0)
})
