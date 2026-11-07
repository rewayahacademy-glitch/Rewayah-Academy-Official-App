// PUSH-1 (07/11/2026) : fabrique une paire de cles VAPID au format exact que
// lit supabase/functions/_shared/push/web_push.ts (lireVapid) :
//   VAPID_PUBLIC_KEY  : point P-256 non compresse (0x04 || X || Y), 65 octets,
//                       en base64url sans « = » ;
//   VAPID_PRIVATE_KEY : le scalaire d, 32 octets, en base64url sans « = » ;
//   VAPID_SUBJECT     : « mailto:... » ou « https://... » (contact de
//                       l'academie, donne par le directeur).
// Les valeurs s'impriment dans le terminal, une fois ; elles ne s'ecrivent
// dans aucun fichier et n'entrent JAMAIS dans le depot. Elles se collent dans
// Supabase, Edge Functions, Secrets.
//
// Usage : deno run tool/push_cles_vapid.ts mailto:<adresse de contact>
// (Equivalent : `npx web-push generate-vapid-keys`, meme format.)

const b64url = (o: Uint8Array) =>
  btoa(String.fromCharCode(...o)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const depuisB64url = (s: string) =>
  Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - s.length % 4) % 4)), (c) => c.charCodeAt(0))

const sujet = Deno.args[0] ?? ''
if (!/^(mailto:|https:)/.test(sujet)) {
  console.error('Donnez le sujet : mailto:<adresse> ou https://<site> (VAPID_SUBJECT).')
  Deno.exit(1)
}
const paire = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify'])
const jwk = await crypto.subtle.exportKey('jwk', paire.privateKey)
const publique = new Uint8Array(await crypto.subtle.exportKey('raw', paire.publicKey))
const prive = depuisB64url(jwk.d!)
if (publique.length !== 65 || publique[0] !== 4 || prive.length !== 32) {
  console.error('Paire inattendue, recommencez.')
  Deno.exit(1)
}
console.log(`VAPID_PUBLIC_KEY=${b64url(publique)}`)
console.log(`VAPID_PRIVATE_KEY=${b64url(prive)}`)
console.log(`VAPID_SUBJECT=${sujet}`)
