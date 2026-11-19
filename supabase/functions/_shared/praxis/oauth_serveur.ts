// PX-OAUTH, ETAPE 2c (17/11/2026) : les trois points du serveur d'autorisation de Praxis (`/register`, `/authorize`, `/token`), en
// dessus des fonctions SQL de l'etape 2b (migration 20261129980000). Voir docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md.
//
// Cette fonction n'a aucune logique metier de securite : elle LIT et BORNE les parametres, appelle la fonction SQL (qui decide : client
// connu, rappel EXACT, PKCE S256, code a usage unique, rotation) et traduit sa reponse en OAuth 2.1. Le code d'autorisation est decide
// par la DIRECTION sur la page de consentement de l'application (etape 2d), jamais ici. Elle ne journalise que la methode et le chemin :
// ni code, ni jeton, ni verifier, ni etat, ni rappel.

import { type PortePraxis } from './mcp.ts'
import { type Adresses, cheminDe, traiterOauth } from './oauth.ts'
import { type Limiteur } from './limiteur.ts'

export const TAILLE_MAX = 4 * 1024
export const DELAI_MS = 8000
// Debit grossier, par adresse (§ limiteur.ts) : /register est rare (une fois par connecteur), /token regulier.
export const LIMITE_REGISTER = { max: 10, fenetreMs: 60 * 60 * 1000 }
export const LIMITE_TOKEN = { max: 60, fenetreMs: 60 * 1000 }
export const LIMITE_AUTORISER = { max: 30, fenetreMs: 60 * 1000 }
// Et un plafond GLOBAL de l'instance, toutes adresses confondues.
export const LIMITE_GLOBALE = { max: 600, fenetreMs: 60 * 1000 }

export interface Contexte {
  adresses: Adresses
  porte: PortePraxis
  limiteur: Limiteur
  /// L'adresse de l'application (la page de consentement, etape 2d), sans barre finale.
  adresseApp: string
  /// L'adresse reseau de l'appelant, pour le debit seulement.
  adresseDe: (req: Request) => string
  journal?: (ligne: string) => void
}

const enJson = {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store',
  Pragma: 'no-cache',
  'Access-Control-Allow-Origin': '*',
}

function json(corps: unknown, statut = 200, plus: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(corps), { status: statut, headers: { ...enJson, ...plus } })
}

function trop(secondes: number): Response {
  return json({ error: 'slow_down', error_description: 'trop de demandes, reessayer plus tard' }, 429, { 'Retry-After': String(secondes) })
}

/// Une page d'erreur pour la personne (jamais une redirection : le rappel n'est pas prouve). Texte fixe, rien de la requete n'y est repris.
function pageErreur(message: string, statut: number): Response {
  const html = `<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Connexion refusee</title></head><body style="font-family:system-ui,sans-serif;max-width:32rem;margin:3rem auto;padding:0 1rem"><h1 style="font-size:1.25rem">Connexion impossible</h1><p>${message}</p></body></html>`
  return new Response(html, {
    status: statut,
    headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'" },
  })
}

async function lireBorne(req: Request, max: number): Promise<string | null> {
  if (!req.body) return ''
  const lecteur = req.body.getReader()
  const morceaux: Uint8Array[] = []
  let total = 0
  for (;;) {
    const { done, value } = await lecteur.read()
    if (done) break
    total += value.byteLength
    if (total > max) {
      await lecteur.cancel().catch(() => {})
      return null
    }
    morceaux.push(value)
  }
  const tout = new Uint8Array(total)
  let pos = 0
  for (const m of morceaux) {
    tout.set(m, pos)
    pos += m.byteLength
  }
  return new TextDecoder().decode(tout)
}

async function appeler(c: Contexte, fonction: string, params: Record<string, string | string[] | null>): Promise<Record<string, unknown> | null> {
  const ctrl = new AbortController()
  const minuteur = setTimeout(() => ctrl.abort(), DELAI_MS)
  try {
    const r = await c.porte.appeler(fonction, params as never, ctrl.signal)
    return typeof r === 'object' && r !== null ? (r as Record<string, unknown>) : null
  } catch {
    return null
  } finally {
    clearTimeout(minuteur)
  }
}

const texte = (v: unknown): string | null => (typeof v === 'string' ? v : null)

/// POST /register (RFC 7591) : un client PUBLIC. Seuls `client_name` et `redirect_uris` comptent ; le reste est ignore.
async function enregistrer(req: Request, c: Contexte): Promise<Response> {
  if (!req.headers.get('content-type')?.toLowerCase().startsWith('application/json')) {
    return json({ error: 'invalid_client_metadata', error_description: 'JSON attendu' }, 400)
  }
  const brut = await lireBorne(req, TAILLE_MAX)
  if (brut === null) return json({ error: 'invalid_client_metadata', error_description: 'corps trop grand' }, 413)
  let corps: Record<string, unknown>
  try {
    const v = JSON.parse(brut)
    if (typeof v !== 'object' || v === null || Array.isArray(v)) throw new Error('forme')
    corps = v as Record<string, unknown>
  } catch {
    return json({ error: 'invalid_client_metadata', error_description: 'JSON invalide' }, 400)
  }
  const rappels = Array.isArray(corps.redirect_uris) && corps.redirect_uris.every((r) => typeof r === 'string')
    ? (corps.redirect_uris as string[])
    : null
  if (!rappels) return json({ error: 'invalid_redirect_uri', error_description: 'redirect_uris attendu' }, 400)
  const methode = corps.token_endpoint_auth_method
  if (methode !== undefined && methode !== 'none') {
    return json({ error: 'invalid_client_metadata', error_description: 'client public seulement (none)' }, 400)
  }
  const r = await appeler(c, 'praxis_oauth_enregistrer', { p_nom: texte(corps.client_name) ?? 'Client MCP', p_rappels: rappels })
  if (!r) return json({ error: 'server_error' }, 503)
  if (r.erreur === 'debit') return trop(3600)
  if (typeof r.erreur === 'string') return json({ error: r.erreur }, 400)
  return json({
    client_id: r.client_id,
    client_name: r.nom,
    redirect_uris: r.rappels,
    grant_types: ['authorization_code', 'refresh_token'],
    response_types: ['code'],
    token_endpoint_auth_method: 'none',
  }, 201)
}

/// GET /authorize : une demande valide mene a la page de consentement de l'application ; un client ou un rappel inconnu ne redirige JAMAIS.
async function autoriser(req: Request, c: Contexte): Promise<Response> {
  const q = new URL(req.url).searchParams
  if (q.get('response_type') !== 'code') return pageErreur('La demande de connexion est incomplete.', 400)
  const r = await appeler(c, 'praxis_oauth_demander', {
    p_client: q.get('client_id'),
    p_rappel: q.get('redirect_uri'),
    p_challenge: q.get('code_challenge'),
    p_methode: q.get('code_challenge_method'),
    p_etat: q.get('state'),
    p_scope: q.get('scope'),
  })
  if (!r) return pageErreur('Le service est indisponible. Reessayez dans un instant.', 503)
  if (r.erreur === 'client_inconnu' || r.erreur === 'redirect_invalide') {
    return pageErreur('Cette application n\'est pas reconnue. Reconnectez-la depuis claude.ai.', 400)
  }
  if (r.erreur === 'debit') return pageErreur('Trop de tentatives. Reessayez plus tard.', 429)
  if (r.erreur === 'requete_invalide') {
    // Client et rappel sont PROUVES (la base ne repond ainsi qu'apres) : l'erreur peut revenir au client, avec son etat.
    const dest = new URL(q.get('redirect_uri') ?? '')
    dest.searchParams.set('error', 'invalid_request')
    const etat = q.get('state')
    if (etat) dest.searchParams.set('state', etat)
    return new Response(null, { status: 302, headers: { Location: dest.toString(), 'Cache-Control': 'no-store' } })
  }
  const demande = texte(r.demande)
  if (!demande || !/^[0-9a-f-]{36}$/.test(demande)) return pageErreur('Le service est indisponible. Reessayez dans un instant.', 503)
  const dest = `${c.adresseApp}/admin/securite-audit/praxis-autoriser?demande=${demande}`
  return new Response(null, { status: 302, headers: { Location: dest, 'Cache-Control': 'no-store' } })
}

/// POST /token (RFC 6749 §3.2, form-urlencoded) : echange du code, ou renouvellement. Toute erreur d'octroi est `invalid_grant`, sans cause.
async function jeton(req: Request, c: Contexte): Promise<Response> {
  if (!req.headers.get('content-type')?.toLowerCase().startsWith('application/x-www-form-urlencoded')) {
    return json({ error: 'invalid_request', error_description: 'application/x-www-form-urlencoded attendu' }, 400)
  }
  const brut = await lireBorne(req, TAILLE_MAX)
  if (brut === null) return json({ error: 'invalid_request' }, 413)
  const f = new URLSearchParams(brut)
  const type = f.get('grant_type')
  let r: Record<string, unknown> | null
  if (type === 'authorization_code') {
    r = await appeler(c, 'praxis_oauth_echanger', {
      p_client: f.get('client_id'), p_code: f.get('code'), p_rappel: f.get('redirect_uri'), p_verifier: f.get('code_verifier'),
    })
  } else if (type === 'refresh_token') {
    r = await appeler(c, 'praxis_oauth_renouveler', { p_client: f.get('client_id'), p_refresh: f.get('refresh_token') })
  } else {
    return json({ error: 'unsupported_grant_type' }, 400)
  }
  if (!r) return json({ error: 'server_error' }, 503)
  if (r.erreur === 'invalid_grant') return json({ error: 'invalid_grant' }, 400)
  if (typeof r.erreur === 'string') return json({ error: 'invalid_request' }, 400)
  return json(r, 200)
}

/// Le point d'entree : la decouverte reste a `traiterOauth` (2a) ; ici les trois points qui touchent la base, derriere le debit.
export async function traiterServeur(req: Request, c: Contexte): Promise<Response> {
  const chemin = cheminDe(req.url)
  const sert = chemin === '/register' || chemin === '/authorize' || chemin === '/token'
  if (!sert || req.method === 'OPTIONS') return traiterOauth(req, c.adresses, c.journal)
  ;(c.journal ?? console.log)(`praxis-oauth ${req.method} ${chemin}`)

  const g = c.limiteur.essayer('global', LIMITE_GLOBALE.max, LIMITE_GLOBALE.fenetreMs)
  if (g > 0) return trop(g)
  const lim = chemin === '/register' ? LIMITE_REGISTER : chemin === '/token' ? LIMITE_TOKEN : LIMITE_AUTORISER
  const a = c.limiteur.essayer(`${chemin}|${c.adresseDe(req)}`, lim.max, lim.fenetreMs)
  if (a > 0) return trop(a)

  if (chemin === '/register' && req.method === 'POST') return await enregistrer(req, c)
  if (chemin === '/authorize' && req.method === 'GET') return await autoriser(req, c)
  if (chemin === '/token' && req.method === 'POST') return await jeton(req, c)
  return json({ error: 'methode' }, 405)
}
