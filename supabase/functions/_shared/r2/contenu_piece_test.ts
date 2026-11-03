// Ce que ces tests prouvent : la confirmation d'une piece d'identite refuse un
// fichier dont les premiers octets ne correspondent pas au type signe, et
// accepte un vrai fichier de ce type ; la lecture en tete d'objet ne demande
// jamais plus de 16 octets, et n'en garde jamais plus de 16 meme si R2 ignore
// la plage.
//
// Aucun appel reseau vers Cloudflare : `fetch` est remplace le temps du test.

import { assert, assertEquals, assertFalse, assertRejects } from 'jsr:@std/assert@1'
import { DOMAINES, type LecteurEnvironnement, prefixeSecrets, seauAttendu } from './domaines.ts'
import { cleDe } from './cles.ts'
import { contenuConforme, OCTETS_ENTETE } from './contenu_piece.ts'
import { ErreurStockageR2, lireEnteteObjet } from './signature.ts'
import { CLE_SONDE, etatConnexions } from './autotest.ts'

const HEX32 = 'a'.repeat(32)
const HEX64 = 'b'.repeat(64)
const PROFIL = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
const DOCUMENT = '7b1e4a2c-9d63-4f1a-8e55-2c0b6f9a7d10'

const env: LecteurEnvironnement = (nom) => {
  if (nom === 'R2_BUCKET_SUPPORTS') return 'rewayah-supports'
  for (const domaine of DOMAINES) {
    const p = prefixeSecrets(domaine)
    if (nom === `${p}_ACCOUNT_ID`) return HEX32
    if (nom === `${p}_ACCESS_KEY_ID`) return HEX32
    if (nom === `${p}_SECRET_ACCESS_KEY`) return HEX64
    if (nom === `${p}_BUCKET_NAME`) return seauAttendu(domaine) ?? undefined
    if (nom === `${p}_ENDPOINT`) return `https://${HEX32}.eu.r2.cloudflarestorage.com`
  }
  return undefined
}

const texte = (s: string) => new TextEncoder().encode(s)

// Un « faux PDF » de 53 octets : du texte enregistre sous le type PDF.
const FAUX_PDF = texte('Ceci est un simple texte, renomme en piece.pdf ! ;-))')
// Le debut d'un vrai PDF (en-tete standard suivi d'octets binaires).
const VRAI_PDF = new Uint8Array([...texte('%PDF-1.7\n%'), 0xe2, 0xe3, 0xcf, 0xd3, 0x0a, 0x31])

/// Remplace `fetch` le temps d'un test, et rend ce que la reponse simulee rend.
async function avecFetch(
  reponse: (requete: Request) => Response,
  corps: (requetes: Request[]) => Promise<void>,
) {
  const original = globalThis.fetch
  const requetes: Request[] = []
  globalThis.fetch = (entree: RequestInfo | URL, init?: RequestInit) => {
    const requete = entree instanceof Request ? entree : new Request(entree, init)
    requetes.push(requete)
    return Promise.resolve(reponse(requete))
  }
  try {
    await corps(requetes)
  } finally {
    globalThis.fetch = original
  }
}

Deno.test('C1 -- un faux PDF de 53 octets est refuse', () => {
  assertEquals(FAUX_PDF.length, 53)
  assertFalse(contenuConforme('application/pdf', FAUX_PDF.subarray(0, OCTETS_ENTETE)))
})

Deno.test('C2 -- un vrai PDF est accepte', () => {
  assert(contenuConforme('application/pdf', VRAI_PDF.subarray(0, OCTETS_ENTETE)))
})

Deno.test('C3 -- JPEG, PNG et HEIC sont reconnus par leurs premiers octets', () => {
  assert(contenuConforme('image/jpeg', new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0x10])))
  assert(contenuConforme('image/png', new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])))
  const heic = new Uint8Array([0, 0, 0, 0x18, ...texte('ftypheic'), 0, 0, 0, 0])
  assert(contenuConforme('image/heic', heic))
  const mif1 = new Uint8Array([0, 0, 0, 0x1c, ...texte('ftypmif1'), 0, 0, 0, 0])
  assert(contenuConforme('image/heic', mif1))
})

Deno.test('C4 -- un type croise ou hors liste est refuse', () => {
  // Une image JPEG annoncee comme PDF, un PDF annonce comme PNG.
  assertFalse(contenuConforme('application/pdf', new Uint8Array([0xff, 0xd8, 0xff, 0xe0])))
  assertFalse(contenuConforme('image/png', VRAI_PDF))
  // Une video MP4 porte aussi une boite `ftyp`, mais pas une marque HEIF.
  assertFalse(contenuConforme('image/heic', new Uint8Array([0, 0, 0, 0x18, ...texte('ftypisom'), 0, 0, 0, 0])))
  assertFalse(contenuConforme('text/plain', FAUX_PDF))
  assertFalse(contenuConforme(null, VRAI_PDF))
  assertFalse(contenuConforme('application/pdf', new Uint8Array([])))
})

Deno.test('C5 -- le type signe est lu sans ses parametres', () => {
  assert(contenuConforme('application/PDF; charset=binary', VRAI_PDF))
})

Deno.test('C6 -- la lecture demande au plus 16 octets et n en garde pas plus', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  // R2 qui ignorerait la plage et rendrait l'objet entier (200) : on coupe a 16.
  const objet = new Uint8Array(4096).fill(0x41)
  objet.set(VRAI_PDF, 0)
  await avecFetch(
    () => new Response(objet, { status: 200, headers: { 'content-type': 'application/pdf' } }),
    async (requetes) => {
      const entete = await lireEnteteObjet('pieceIdentite', cle, OCTETS_ENTETE, env)
      assert(entete)
      assertEquals(entete.octets.length, 16)
      assertEquals(entete.typeContenu, 'application/pdf')
      assert(contenuConforme(entete.typeContenu, entete.octets))
      assertEquals(requetes.length, 1)
      assertEquals(requetes[0].method, 'GET')
      assertEquals(requetes[0].headers.get('range'), 'bytes=0-15')
      assert(new URL(requetes[0].url).pathname.startsWith('/rewayah-identity-vault/'))
    },
  )
})

Deno.test('C7 -- le faux PDF lu par la plage est refuse', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  await avecFetch(
    () => new Response(FAUX_PDF.subarray(0, 16), { status: 206, headers: { 'content-type': 'application/pdf' } }),
    async () => {
      const entete = await lireEnteteObjet('pieceIdentite', cle, OCTETS_ENTETE, env)
      assert(entete)
      assertFalse(contenuConforme(entete.typeContenu, entete.octets))
    },
  )
})

Deno.test('C8 -- objet absent ou vide : rien a comparer', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  await avecFetch(() => new Response(null, { status: 404 }), async () => {
    assertEquals(await lireEnteteObjet('pieceIdentite', cle, OCTETS_ENTETE, env), null)
  })
  await avecFetch(() => new Response(null, { status: 416 }), async () => {
    assertEquals(await lireEnteteObjet('pieceIdentite', cle, OCTETS_ENTETE, env), null)
  })
})

Deno.test('C9 -- une reponse inattendue est une panne, pas une absence', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  await avecFetch(() => new Response('AccessDenied', { status: 403 }), async () => {
    await assertRejects(() => lireEnteteObjet('pieceIdentite', cle, OCTETS_ENTETE, env), ErreurStockageR2)
  })
})

Deno.test('C10 -- la lecture ne peut pas etre elargie au-dela de 16 octets', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  await assertRejects(() => lireEnteteObjet('pieceIdentite', cle, 17, env), ErreurStockageR2)
})

// ============================================================
// Autotest des connexions (r2-selftest)
// ============================================================

Deno.test('A1 -- l autotest n ecrit rien : un seul HEAD par domaine, sur la cle sondee', async () => {
  await avecFetch(() => new Response(null, { status: 404 }), async (requetes) => {
    const etat = await etatConnexions(env)
    for (const domaine of DOMAINES) {
      assertEquals(etat[domaine], { configuree: true, joignable: true })
    }
    assertEquals(requetes.length, DOMAINES.length)
    for (const r of requetes) {
      assertEquals(r.method, 'HEAD')
      assert(new URL(r.url).pathname.endsWith(`/${CLE_SONDE}`))
    }
  })
})

Deno.test('A2 -- un refus de R2 rend non, sans rien dire de plus', async () => {
  await avecFetch(() => new Response('AccessDenied', { status: 403 }), async () => {
    const etat = await etatConnexions(env)
    const texteEtat = JSON.stringify(etat)
    for (const domaine of DOMAINES) {
      assertEquals(etat[domaine], { configuree: true, joignable: false })
    }
    // Ni nom de seau, ni point d'acces, ni identifiant, ni message de R2.
    assertFalse(texteEtat.includes('rewayah-'))
    assertFalse(texteEtat.includes(HEX32))
    assertFalse(texteEtat.includes('AccessDenied'))
  })
})

Deno.test('A3 -- un domaine sans secrets est non configure et n est pas sonde', async () => {
  const vide: LecteurEnvironnement = () => undefined
  await avecFetch(() => new Response(null, { status: 404 }), async (requetes) => {
    const etat = await etatConnexions(vide)
    for (const domaine of DOMAINES) {
      assertEquals(etat[domaine], { configuree: false, joignable: false })
    }
    assertEquals(requetes.length, 0)
  })
})
