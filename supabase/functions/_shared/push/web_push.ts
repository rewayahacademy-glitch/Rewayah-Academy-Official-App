// PUSH-1 : Web Push standard, sans dependance npm, avec la seule Web Crypto
// de Deno.
//
// - RFC 8291 : chiffrement du message (aes128gcm, ECDH P-256 ephemere, HKDF).
// - RFC 8292 : identification VAPID (JWT ES256, signature brute r||s).
// - RFC 8188 : en-tete du contenu aes128gcm (sel, rs, keyid).
//
// Tout est pur et testable sans reseau : `envoyerPush` recoit son `fetch`.

// ---------------------------------------------------------------------------
// base64url

export function versBase64Url(octets: Uint8Array): string {
  let b = ''
  for (const o of octets) b += String.fromCharCode(o)
  return btoa(b).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

export function depuisBase64Url(texte: string): Uint8Array<ArrayBuffer> {
  const t = texte.trim().replace(/-/g, '+').replace(/_/g, '/')
  const b = atob(t + '='.repeat((4 - (t.length % 4)) % 4))
  const o = new Uint8Array(b.length)
  for (let i = 0; i < b.length; i++) o[i] = b.charCodeAt(i)
  return o
}

function concat(...parts: Uint8Array[]): Uint8Array {
  const n = parts.reduce((s, p) => s + p.length, 0)
  const r = new Uint8Array(n)
  let k = 0
  for (const p of parts) {
    r.set(p, k)
    k += p.length
  }
  return r
}

const ascii = (s: string) => new TextEncoder().encode(s)

// Les fonctions de Web Crypto attendent un BufferSource adosse a un
// ArrayBuffer ; une copie l'assure quel que soit le tableau d'origine.
const tampon = (o: Uint8Array): ArrayBuffer => o.slice().buffer as ArrayBuffer

// ---------------------------------------------------------------------------
// Cles P-256

/// Une cle publique P-256 non compressee : 65 octets, premier octet 0x04.
export function clePubliqueValide(o: Uint8Array): boolean {
  return o.length === 65 && o[0] === 0x04
}

/// JWK d'une cle P-256 a partir de la cle publique brute (65 octets) et, si
/// elle est donnee, du scalaire prive d (32 octets).
export function jwkP256(publique: Uint8Array, prive?: Uint8Array): JsonWebKey {
  if (!clePubliqueValide(publique)) throw new Error('cle publique P-256 invalide')
  const jwk: JsonWebKey = {
    kty: 'EC',
    crv: 'P-256',
    x: versBase64Url(publique.slice(1, 33)),
    y: versBase64Url(publique.slice(33, 65)),
    ext: true,
  }
  if (prive) {
    if (prive.length !== 32) throw new Error('cle privee P-256 invalide')
    jwk.d = versBase64Url(prive)
  }
  return jwk
}

export async function clePubliqueBrute(cle: CryptoKey): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.exportKey('raw', cle))
}

// ---------------------------------------------------------------------------
// VAPID (RFC 8292)

export interface Vapid {
  publique: Uint8Array // 65 octets
  prive: Uint8Array // 32 octets
  sujet: string // mailto: ou https:
}

/// Lit les trois secrets VAPID. `null` si l'un manque ; une erreur s'ils sont
/// presents mais mal formes.
export function lireVapid(env: (nom: string) => string | undefined): Vapid | null {
  const pub = env('VAPID_PUBLIC_KEY')?.trim()
  const priv = env('VAPID_PRIVATE_KEY')?.trim()
  const sujet = env('VAPID_SUBJECT')?.trim()
  if (!pub || !priv || !sujet) return null
  const publique = depuisBase64Url(pub)
  const prive = depuisBase64Url(priv)
  if (!clePubliqueValide(publique) || prive.length !== 32) throw new Error('vapid invalide')
  if (!/^(mailto:|https:)/.test(sujet)) throw new Error('vapid invalide')
  return { publique, prive, sujet }
}

/// Le JWT VAPID : {aud: origine de l'endpoint, exp: maintenant + 12 h, sub}.
export async function jwtVapid(vapid: Vapid, endpoint: string, maintenantMs = Date.now()): Promise<string> {
  const entete = versBase64Url(ascii(JSON.stringify({ typ: 'JWT', alg: 'ES256' })))
  const charge = versBase64Url(ascii(JSON.stringify({
    aud: new URL(endpoint).origin,
    exp: Math.floor(maintenantMs / 1000) + 12 * 3600,
    sub: vapid.sujet,
  })))
  const cle = await crypto.subtle.importKey(
    'jwk', jwkP256(vapid.publique, vapid.prive), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'],
  )
  // Web Crypto rend deja la forme brute r||s (IEEE P1363), 64 octets.
  const signature = new Uint8Array(await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' }, cle, ascii(`${entete}.${charge}`),
  ))
  return `${entete}.${charge}.${versBase64Url(signature)}`
}

export async function autorisationVapid(vapid: Vapid, endpoint: string, maintenantMs = Date.now()): Promise<string> {
  return `vapid t=${await jwtVapid(vapid, endpoint, maintenantMs)}, k=${versBase64Url(vapid.publique)}`
}

// ---------------------------------------------------------------------------
// Chiffrement aes128gcm (RFC 8291 + RFC 8188)

export const TAILLE_ENREGISTREMENT = 4096

async function hkdf(sel: Uint8Array, ikm: Uint8Array, info: Uint8Array, octets: number): Promise<Uint8Array> {
  const cle = await crypto.subtle.importKey('raw', tampon(ikm), 'HKDF', false, ['deriveBits'])
  return new Uint8Array(await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt: tampon(sel), info: tampon(info) }, cle, octets * 8,
  ))
}

/// Les cles du contenu (CEK et NONCE), communes a l'emetteur et au recepteur.
/// `uaPublique` : la cle de l'abonne ; `asPublique` : la cle ephemere du serveur.
export async function deriverCles(
  secretEcdh: Uint8Array, auth: Uint8Array, uaPublique: Uint8Array, asPublique: Uint8Array, sel: Uint8Array,
): Promise<{ cek: Uint8Array; nonce: Uint8Array }> {
  const infoCle = concat(ascii('WebPush: info'), new Uint8Array([0]), uaPublique, asPublique)
  const ikm = await hkdf(auth, secretEcdh, infoCle, 32)
  const cek = await hkdf(sel, ikm, concat(ascii('Content-Encoding: aes128gcm'), new Uint8Array([0])), 16)
  const nonce = await hkdf(sel, ikm, concat(ascii('Content-Encoding: nonce'), new Uint8Array([0])), 12)
  return { cek, nonce }
}

export async function secretEcdh(prive: CryptoKey, publiqueBrute: Uint8Array): Promise<Uint8Array> {
  const pub = await crypto.subtle.importKey(
    'raw', tampon(publiqueBrute), { name: 'ECDH', namedCurve: 'P-256' }, false, [],
  )
  return new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: pub }, prive, 256))
}

export interface OptionsChiffrement {
  /// Pour les tests (vecteur de l'annexe A de RFC 8291) ; sinon tire au hasard.
  sel?: Uint8Array
  /// Paire ephemere imposee ; sinon generee pour chaque message.
  ephemere?: { prive: CryptoKey; publique: Uint8Array }
}

/// Chiffre `clair` pour un abonne (p256dh, auth en base64url). Rend le corps
/// complet a poster : en-tete aes128gcm puis un seul enregistrement.
export async function chiffrer(
  clair: Uint8Array, p256dh: string, authB64: string, options: OptionsChiffrement = {},
): Promise<Uint8Array> {
  const uaPublique = depuisBase64Url(p256dh)
  const auth = depuisBase64Url(authB64)
  if (!clePubliqueValide(uaPublique)) throw new Error('p256dh invalide')
  if (auth.length !== 16) throw new Error('auth invalide')
  // Un seul enregistrement : clair + delimiteur (1) + etiquette GCM (16) <= rs.
  if (clair.length + 17 > TAILLE_ENREGISTREMENT) throw new Error('message trop long')

  let ephemere = options.ephemere
  if (!ephemere) {
    const paire = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']) as CryptoKeyPair
    ephemere = { prive: paire.privateKey, publique: await clePubliqueBrute(paire.publicKey) }
  }
  const sel = options.sel ?? crypto.getRandomValues(new Uint8Array(16))
  if (sel.length !== 16) throw new Error('sel invalide')

  const ecdh = await secretEcdh(ephemere.prive, uaPublique)
  const { cek, nonce } = await deriverCles(ecdh, auth, uaPublique, ephemere.publique, sel)
  const cle = await crypto.subtle.importKey('raw', tampon(cek), 'AES-GCM', false, ['encrypt'])
  // Dernier (et seul) enregistrement : delimiteur 0x02, sans bourrage.
  const chiffre = new Uint8Array(await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: tampon(nonce) }, cle, tampon(concat(clair, new Uint8Array([2]))),
  ))
  const rs = new Uint8Array(4)
  new DataView(rs.buffer).setUint32(0, TAILLE_ENREGISTREMENT)
  return concat(sel, rs, new Uint8Array([ephemere.publique.length]), ephemere.publique, chiffre)
}

/// Le chemin du recepteur (RFC 8291 §3.4), pour les tests : dechiffre un corps
/// aes128gcm d'un seul enregistrement avec la cle privee de l'abonne.
export async function dechiffrer(
  corps: Uint8Array, uaPrive: CryptoKey, uaPublique: Uint8Array, auth: Uint8Array,
): Promise<Uint8Array> {
  const sel = corps.slice(0, 16)
  const idlen = corps[20]
  const asPublique = corps.slice(21, 21 + idlen)
  const chiffre = corps.slice(21 + idlen)
  const ecdh = await secretEcdh(uaPrive, asPublique)
  const { cek, nonce } = await deriverCles(ecdh, auth, uaPublique, asPublique, sel)
  const cle = await crypto.subtle.importKey('raw', tampon(cek), 'AES-GCM', false, ['decrypt'])
  const clair = new Uint8Array(await crypto.subtle.decrypt({ name: 'AES-GCM', iv: tampon(nonce) }, cle, tampon(chiffre)))
  // Retire le bourrage final (zeros) puis le delimiteur 0x02.
  let fin = clair.length - 1
  while (fin >= 0 && clair[fin] === 0) fin--
  if (fin < 0 || clair[fin] !== 2) throw new Error('delimiteur absent')
  return clair.slice(0, fin)
}

// ---------------------------------------------------------------------------
// Topic (RFC 8030 §5.4) : 32 caracteres base64url au plus.

export async function topicDe(tag: string | null | undefined): Promise<string | null> {
  if (!tag) return null
  if (/^[A-Za-z0-9_-]{1,32}$/.test(tag)) return tag
  const h = new Uint8Array(await crypto.subtle.digest('SHA-256', ascii(tag)))
  return versBase64Url(h).slice(0, 32)
}

// ---------------------------------------------------------------------------
// Envoi a un abonnement

export interface Abonnement {
  id: string
  endpoint: string
  p256dh: string
  auth: string
}

export type Issue =
  | { etat: 'ok' }
  | { etat: 'mort'; statut: number }
  | { etat: 'echec'; erreur: string }

export type Fetch = (url: string, init: RequestInit) => Promise<Response>

/// Envoie un message chiffre a un abonnement. 2xx : ok ; 404 ou 410 :
/// abonnement mort ; tout le reste (5xx, 4xx, reseau) : echec, jamais mort.
/// L'erreur reste courte et ne porte ni l'endpoint ni la reponse.
/// Les services de push des navigateurs (garde-cap, 07/11 : SSRF et abus) :
/// FCM (Chrome, Edge sur Android), Mozilla (Firefox), Apple (Safari, iPhone),
/// WNS (Edge sur Windows, sous-domaines de notify.windows.com). La meme liste
/// que `private.push_hote_autorise` en base ; toute autre adresse est ignoree.
export function hoteAutorise(endpoint: string): boolean {
  let u: URL
  try {
    u = new URL(endpoint)
  } catch {
    return false
  }
  if (u.protocol !== 'https:' || u.port !== '' || u.username !== '' || u.password !== '') return false
  const h = u.hostname.toLowerCase()
  return h === 'fcm.googleapis.com' ||
    h === 'updates.push.services.mozilla.com' ||
    h === 'web.push.apple.com' ||
    /^([a-z0-9-]+\.)+notify\.windows\.com$/.test(h)
}

export async function envoyerPush(
  abonnement: Abonnement,
  clair: Uint8Array,
  vapid: Vapid,
  options: { tag?: string | null; fetch?: Fetch; maintenantMs?: number; chiffrement?: OptionsChiffrement } = {},
): Promise<Issue> {
  // Aucun envoi hors des services de push connus : l'abonnement est ignore.
  if (!hoteAutorise(abonnement.endpoint)) return { etat: 'echec', erreur: 'hote refuse' }
  let corps: Uint8Array
  let autorisation: string
  try {
    corps = await chiffrer(clair, abonnement.p256dh, abonnement.auth, options.chiffrement)
    autorisation = await autorisationVapid(vapid, abonnement.endpoint, options.maintenantMs)
  } catch (e) {
    return { etat: 'echec', erreur: `preparation : ${(e as Error).message ?? 'inconnue'}`.slice(0, 80) }
  }
  const entetes: Record<string, string> = {
    'Authorization': autorisation,
    'Content-Encoding': 'aes128gcm',
    'Content-Type': 'application/octet-stream',
    'TTL': '86400',
    'Urgency': 'high',
  }
  const topic = await topicDe(options.tag)
  if (topic) entetes['Topic'] = topic

  const f: Fetch = options.fetch ?? ((u, i) => fetch(u, i))
  try {
    const r = await f(abonnement.endpoint, { method: 'POST', headers: entetes, body: tampon(corps) })
    // Le corps de la reponse n'est jamais lu : il peut contenir l'endpoint.
    await r.body?.cancel().catch(() => {})
    if (r.status >= 200 && r.status < 300) return { etat: 'ok' }
    if (r.status === 404 || r.status === 410) return { etat: 'mort', statut: r.status }
    return { etat: 'echec', erreur: `http ${r.status}` }
  } catch {
    return { etat: 'echec', erreur: 'reseau' }
  }
}
