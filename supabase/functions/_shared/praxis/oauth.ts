// PX-OAUTH, ETAPE 2a (17/11/2026) : la DECOUVERTE seule du connecteur Praxis pour claude.ai. Voir
// docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md (§3, §7, §10).
//
// Cette etape ne delivre AUCUN jeton : elle publie les metadonnees (ressource protegee RFC 9728, serveur d'autorisation RFC 8414 /
// OpenID Connect), pour verifier que claude.ai les trouve et va jusqu'a l'ecran d'autorisation. Les points `/register`, `/authorize`
// et `/token` rendent 503 `non_disponible` (ils viennent aux etapes 2b et 2c). Aucun acces a la base, aucun secret.
//
// Chaque requete laisse UNE ligne de journal (methode et chemin, rien d'autre : ni en-tete, ni corps, ni parametre) : c'est elle qui
// dit au pilote QUELS chemins de decouverte claude.ai essaie (le point non prouve du plan, §7).

const NOM = 'praxis-oauth'

/// Les adresses publiques derivees de la racine du projet (`SUPABASE_URL`, sans barre finale).
export interface Adresses {
  /// L'URL du serveur MCP : celle que le directeur saisit dans claude.ai. `resource` doit lui etre EGALE, chemin compris.
  ressource: string
  /// L'identifiant du serveur d'autorisation (`issuer`).
  emetteur: string
  /// L'URL des metadonnees de ressource, annoncee dans `WWW-Authenticate`.
  metadonneesRessource: string
}

export function adressesDe(racine: string): Adresses {
  const r = racine.replace(/\/+$/, '')
  return {
    ressource: `${r}/functions/v1/praxis-mcp`,
    emetteur: `${r}/functions/v1/${NOM}`,
    metadonneesRessource: `${r}/functions/v1/${NOM}/resource`,
  }
}

/// L'en-tete `WWW-Authenticate` d'un 401 de `praxis-mcp` (claude.ai l'exige sur un 401, jamais sur un 200).
export function enteteWwwAuthenticate(a: Adresses): string {
  return `Bearer resource_metadata="${a.metadonneesRessource}"`
}

export function metadonneesRessource(a: Adresses): Record<string, unknown> {
  return {
    resource: a.ressource,
    authorization_servers: [a.emetteur],
    scopes_supported: ['praxis', 'offline_access'],
    bearer_methods_supported: ['header'],
  }
}

export function metadonneesServeur(a: Adresses): Record<string, unknown> {
  return {
    issuer: a.emetteur,
    authorization_endpoint: `${a.emetteur}/authorize`,
    token_endpoint: `${a.emetteur}/token`,
    registration_endpoint: `${a.emetteur}/register`,
    scopes_supported: ['praxis', 'offline_access'],
    response_types_supported: ['code'],
    grant_types_supported: ['authorization_code', 'refresh_token'],
    code_challenge_methods_supported: ['S256'],
    token_endpoint_auth_methods_supported: ['none'],
  }
}

const entetes = {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, mcp-protocol-version',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

function json(corps: unknown, statut = 200): Response {
  return new Response(JSON.stringify(corps), { status: statut, headers: entetes })
}

/// Le chemin APRES le nom de la fonction (`/functions/v1/praxis-oauth/resource` ou `/praxis-oauth/resource` selon la couche qui
/// le reecrit), sans barre finale ; `/` pour la racine.
export function cheminDe(url: string): string {
  const { pathname } = new URL(url)
  const i = pathname.indexOf(`/${NOM}`)
  const reste = i < 0 ? pathname : pathname.slice(i + NOM.length + 1)
  const net = reste.replace(/\/+$/, '')
  return net === '' ? '/' : net
}

export function traiterOauth(req: Request, a: Adresses, journal: (ligne: string) => void = console.log): Response {
  const chemin = cheminDe(req.url)
  // Une ligne, methode et chemin SEULEMENT (voir l'en-tete du fichier).
  journal(`${NOM} ${req.method} ${chemin}`)
  if (req.method === 'OPTIONS') return new Response('ok', { headers: entetes })
  if (req.method !== 'GET' && req.method !== 'POST') return json({ error: 'methode' }, 405)

  if (req.method === 'GET') {
    if (chemin === '/resource' || chemin === '/.well-known/oauth-protected-resource') {
      return json(metadonneesRessource(a))
    }
    if (chemin === '/.well-known/openid-configuration' || chemin === '/.well-known/oauth-authorization-server') {
      return json(metadonneesServeur(a))
    }
  }
  if (chemin === '/register' || chemin === '/authorize' || chemin === '/token') {
    // Etape 2a : annoncee, pas encore servie.
    return json({ error: 'temporarily_unavailable', error_description: 'non_disponible : decouverte seulement (etape 2a)' }, 503)
  }
  return json({ error: 'introuvable' }, 404)
}
