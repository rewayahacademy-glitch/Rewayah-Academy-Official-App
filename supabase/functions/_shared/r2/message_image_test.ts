// IMAGES-MESSAGERIE (16/11/2026) : la logique pure des fonctions Edge
// `message-image-depot`, `message-images-lecture` et `message-images-purge`.
// Aucun appel reseau : `aws4fetch` signe localement.

import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { DOMAINES, type LecteurEnvironnement, prefixeSecrets, seauAttendu } from './domaines.ts'
import { signerDepot, signerLecture } from './signature.ts'
import { signatureConfirmationUpload } from './confirmation_hmac.ts'
import {
  cleImageValide,
  DOMAINE_CONFIRMATION_IMAGE,
  enteteConforme,
  estRefus,
  LOT_PURGE,
  LOTS_PURGE_MAX,
  lireDemande,
  lireLotPurge,
  purger,
  refusBase,
  TAILLE_IMAGE_MAX_OCTETS,
  TAILLE_MINIATURE_MAX_OCTETS,
  TYPES_IMAGE_MESSAGE,
} from './message_image.ts'

const FIL = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
const IMAGE = '7b1e4a2c-9d63-4f1a-8e55-2c0b6f9a7d10'
const MESSAGE = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'
const HEX32 = 'a'.repeat(32)
const HEX64 = 'b'.repeat(64)

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

function corpsValide(): Record<string, unknown> {
  return {
    action: 'demander',
    message_id: MESSAGE,
    image: { mime: 'image/jpeg', octets: 150000, largeur: 800, hauteur: 600, couleur_moyenne: '#A1B2C3' },
    miniature: { mime: 'image/webp', octets: 8000 },
  }
}

Deno.test('image messagerie : une demande valide est lue, la couleur est normalisee', () => {
  const d = lireDemande(corpsValide())
  assert(!estRefus(d))
  assertEquals(d.messageId, MESSAGE)
  assertEquals(d.couleurMoyenne, '#a1b2c3')
  assertEquals(d.mimeMiniature, 'image/webp')
})

Deno.test('image messagerie : les limites du serveur (2 Mo, 100 Ko, types)', () => {
  const sur = (maj: (c: Record<string, unknown>) => void) => {
    const c = corpsValide()
    maj(c)
    const d = lireDemande(c)
    return estRefus(d) ? d.code : 'ok'
  }
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).octets = TAILLE_IMAGE_MAX_OCTETS)), 'ok')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).octets = TAILLE_IMAGE_MAX_OCTETS + 1)), 'image_trop_lourde')
  assertEquals(sur((c) => ((c.miniature as Record<string, unknown>).octets = TAILLE_MINIATURE_MAX_OCTETS)), 'ok')
  assertEquals(sur((c) => ((c.miniature as Record<string, unknown>).octets = TAILLE_MINIATURE_MAX_OCTETS + 1)), 'miniature_trop_lourde')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).mime = 'image/gif')), 'type_refuse')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).mime = 'image/heic')), 'type_refuse')
  assertEquals(sur((c) => ((c.miniature as Record<string, unknown>).mime = 'application/pdf')), 'type_refuse')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).octets = 0)), 'demande_invalide')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).octets = 12.5)), 'demande_invalide')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).largeur = 0)), 'demande_invalide')
  assertEquals(sur((c) => ((c.image as Record<string, unknown>).couleur_moyenne = 'rouge')), 'demande_invalide')
  assertEquals(sur((c) => (c.message_id = 'pas-un-uuid')), 'demande_invalide')
  assertEquals(sur((c) => delete c.miniature), 'demande_invalide')
  assertEquals(TYPES_IMAGE_MESSAGE, ['image/jpeg', 'image/png', 'image/webp'])
})

Deno.test('image messagerie : un refus porte un code lisible et le bon statut', () => {
  const d = lireDemande({ ...corpsValide(), image: { mime: 'image/gif', octets: 1, largeur: 1, hauteur: 1 } })
  assert(estRefus(d))
  assertEquals([d.code, d.statut], ['type_refuse', 415])
})

Deno.test('image messagerie : chaque refus de la base a son code et son statut', () => {
  const cas: [string, string, number][] = [
    ['ImageMineurRefuse', 'mineur_refuse', 403],
    ['ImageLimiteHoraire', 'limite_horaire', 429],
    ['ImageDejaPourMessage', 'deja_une_image', 409],
    ['ImageIntentionIndisponible', 'depot_indisponible', 410],
    ['ImageConfirmationNonAutorisee', 'confirmation_mal_reglee', 503],
    ['ImageParametresInvalides', 'demande_invalide', 400],
    ['ImageNonAutorise', 'non_autorise', 403],
    ['ImageMessageIntrouvable', 'non_autorise', 403],
    ['connection terminated unexpectedly', 'depot_impossible', 500],
  ]
  for (const [message, code, statut] of cas) {
    const r = refusBase({ message })
    assertEquals([r.code, r.statut], [code, statut], message)
  }
  assertEquals(refusBase({ code: '42501', message: 'permission denied' }).code, 'non_autorise')
  // Sans message : une panne, jamais un refus qui accuserait la personne.
  assertEquals(refusBase(null).code, 'depot_impossible')
  assertEquals(refusBase({}).statut, 500)
})

Deno.test('image messagerie : une cle est confrontee a la convention fils/<fil>/<uuid>', () => {
  const cle = `fils/${FIL}/${IMAGE}.jpg`
  const mini = `fils/${FIL}/${IMAGE}-min.webp`
  assertEquals(cleImageValide(cle, FIL, false), cle)
  assertEquals(cleImageValide(mini, FIL, true), mini)
  // La miniature n'est pas l'image, et inversement.
  assertEquals(cleImageValide(mini, FIL, false), null)
  assertEquals(cleImageValide(cle, FIL, true), null)
  // Un autre fil, une remontee de chemin, une extension etrangere, un autre prefixe.
  assertEquals(cleImageValide(cle, MESSAGE, false), null)
  assertEquals(cleImageValide(`fils/${FIL}/../${IMAGE}.jpg`, FIL, false), null)
  assertEquals(cleImageValide(`fils/${FIL}/${IMAGE}.gif`, FIL, false), null)
  assertEquals(cleImageValide(`messages/${FIL}/${IMAGE}.jpg`, FIL, false), null)
  assertEquals(cleImageValide(`fils/${FIL}/${IMAGE}.jpg/x`, FIL, false), null)
  assertEquals(cleImageValide(undefined, FIL, false), null)
})

Deno.test('image messagerie : les premiers octets disent le vrai type (JPEG, PNG, WebP)', () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0, 0, 0, 0, 0])
  const webp = new TextEncoder().encode('RIFF\x10\x00\x00\x00WEBPVP8 ')
  const gif = new TextEncoder().encode('GIF89a..........')
  const pdf = new TextEncoder().encode('%PDF-1.7.........')
  assert(enteteConforme('image/jpeg', jpeg))
  assert(enteteConforme('image/png', png))
  assert(enteteConforme('image/webp', webp))
  // Un type annonce qui n'est pas le contenu : refuse, dans tous les sens.
  assert(!enteteConforme('image/png', jpeg))
  assert(!enteteConforme('image/jpeg', webp))
  assert(!enteteConforme('image/webp', png))
  assert(!enteteConforme('image/jpeg', pdf))
  assert(!enteteConforme('image/png', gif))
  assert(!enteteConforme('image/gif', gif))
  assert(!enteteConforme('image/webp', new Uint8Array([0x52, 0x49, 0x46, 0x46])))
  assert(!enteteConforme('image/jpeg', new Uint8Array(0)))
})

Deno.test('image messagerie : le lien de depot est un PUT de 10 minutes vers le seau de la messagerie', async () => {
  const cle = `fils/${FIL}/${IMAGE}.jpg`
  const { url, enTetesExiges, expireDansSecondes } = await signerDepot('pieceJointeMessage', cle, {
    typeMime: 'image/jpeg',
    tailleOctets: 150000,
    typesAutorises: TYPES_IMAGE_MESSAGE,
    tailleMaximaleOctets: TAILLE_IMAGE_MAX_OCTETS,
    dureeSecondes: 600,
    env,
  })
  const u = new URL(url)
  assertEquals(expireDansSecondes, 600)
  assertEquals(u.searchParams.get('X-Amz-Expires'), '600')
  assertEquals(u.pathname, `/rewayah-message-attachments/${cle}`)
  assertEquals(enTetesExiges['content-type'], 'image/jpeg')
  assertEquals(enTetesExiges['content-length'], '150000')
  assert(u.searchParams.get('X-Amz-SignedHeaders')?.includes('content-length'), 'la taille est signee')
  assert(u.searchParams.get('X-Amz-SignedHeaders')?.includes('content-type'), 'le type est signe')
})

Deno.test('image messagerie : un depot au-dela des plafonds ou d\'un autre type ne se signe pas', async () => {
  const cle = `fils/${FIL}/${IMAGE}.jpg`
  await assertRejects(() =>
    signerDepot('pieceJointeMessage', cle, {
      typeMime: 'image/jpeg',
      tailleOctets: TAILLE_IMAGE_MAX_OCTETS + 1,
      typesAutorises: TYPES_IMAGE_MESSAGE,
      tailleMaximaleOctets: TAILLE_IMAGE_MAX_OCTETS,
      env,
    })
  )
  await assertRejects(() =>
    signerDepot('pieceJointeMessage', `fils/${FIL}/${IMAGE}-min.webp`, {
      typeMime: 'image/webp',
      tailleOctets: TAILLE_MINIATURE_MAX_OCTETS + 1,
      typesAutorises: TYPES_IMAGE_MESSAGE,
      tailleMaximaleOctets: TAILLE_MINIATURE_MAX_OCTETS,
      env,
    })
  )
  await assertRejects(() =>
    signerDepot('pieceJointeMessage', cle, {
      typeMime: 'image/gif',
      tailleOctets: 100,
      typesAutorises: TYPES_IMAGE_MESSAGE,
      tailleMaximaleOctets: TAILLE_IMAGE_MAX_OCTETS,
      env,
    })
  )
})

Deno.test('image messagerie : le lien de lecture est un GET d\'une heure', async () => {
  const { url, expireDansSecondes } = await signerLecture('pieceJointeMessage', `fils/${FIL}/${IMAGE}-min.webp`, {
    dureeSecondes: 3600,
    env,
  })
  assertEquals(expireDansSecondes, 3600)
  assertEquals(new URL(url).searchParams.get('X-Amz-Expires'), '3600')
  assert(new URL(url).pathname.startsWith('/rewayah-message-attachments/fils/'))
})

Deno.test('image messagerie : la signature de confirmation porte son propre domaine', async () => {
  const secret = 'secret-de-test-0123456789-0123456789-xx'
  const sha = 'c'.repeat(64)
  const pour = (domaine?: string) => signatureConfirmationUpload(secret, IMAGE, sha, 150000, domaine)
  const image = await pour(DOMAINE_CONFIRMATION_IMAGE)
  assertEquals(image.length, 64)
  // Une signature de bibliotheque (sans domaine) ou de vignette ne confirme pas une image.
  assert(image !== await pour())
  assert(image !== await pour('bibliotheque-vignette-v1'))
  assertEquals(image, await pour(DOMAINE_CONFIRMATION_IMAGE))
})

Deno.test('image messagerie : le lot de purge ecarte toute ligne hors convention', () => {
  const bonne = { id: IMAGE, cle_r2: `fils/${FIL}/${IMAGE}.jpg`, cle_miniature: `fils/${FIL}/${IMAGE}-min.jpg` }
  const lot = lireLotPurge([
    bonne,
    { ...bonne, cle_r2: `private/export/${IMAGE}` },
    { ...bonne, cle_miniature: `fils/${MESSAGE}/${IMAGE}-min.jpg` },
    { ...bonne, id: 'pas-un-uuid' },
    null,
    'x',
  ])
  assertEquals(lot, [bonne])
  assertEquals(lireLotPurge('rien'), [])
})

function ligne(i: number) {
  const id = `00000000-0000-4000-8000-${String(i).padStart(12, '0')}`
  return { id, cle_r2: `fils/${FIL}/${id}.jpg`, cle_miniature: `fils/${FIL}/${id}-min.jpg` }
}

Deno.test('image messagerie : la purge retire les deux objets puis marque la ligne', async () => {
  const supprimes: string[] = []
  const marques: string[][] = []
  let appels = 0
  const bilan = await purger({
    lire: (lot) => {
      assertEquals(lot, LOT_PURGE)
      return Promise.resolve(appels++ === 0 ? [ligne(1), ligne(2)] : [])
    },
    supprimer: (cle) => {
      supprimes.push(cle)
      return Promise.resolve()
    },
    marquer: (ids) => {
      marques.push(ids)
      return Promise.resolve()
    },
  })
  assertEquals(bilan, { retirees: 2, echecs: 0, lots: 1 })
  assertEquals(supprimes.length, 4)
  assertEquals(marques, [[ligne(1).id, ligne(2).id]])
})

Deno.test('image messagerie : un objet impossible a retirer laisse la ligne due', async () => {
  const marques: string[][] = []
  let appels = 0
  const bilan = await purger({
    lire: () => Promise.resolve(appels++ === 0 ? [ligne(1), ligne(2), ligne(3)] : []),
    supprimer: (cle) => cle.includes('0002') ? Promise.reject(new Error('R2')) : Promise.resolve(),
    marquer: (ids) => {
      marques.push(ids)
      return Promise.resolve()
    },
  })
  assertEquals(bilan, { retirees: 2, echecs: 1, lots: 1 })
  assertEquals(marques, [[ligne(1).id, ligne(3).id]])
})

Deno.test('image messagerie : un lot plein est suivi d\'un autre, jamais plus de 25', async () => {
  let lus = 0
  const plein = Array.from({ length: LOT_PURGE }, (_, i) => ligne(i + 1))
  const bilan = await purger({
    lire: () => {
      lus++
      return Promise.resolve(plein)
    },
    supprimer: () => Promise.resolve(),
    marquer: () => Promise.resolve(),
  })
  assertEquals(lus, LOTS_PURGE_MAX)
  assertEquals(bilan.lots, LOTS_PURGE_MAX)
  assertEquals(bilan.retirees, LOTS_PURGE_MAX * LOT_PURGE)
})

Deno.test('image messagerie : un lot sans aucune reussite arrete la boucle', async () => {
  let lus = 0
  const plein = Array.from({ length: LOT_PURGE }, (_, i) => ligne(i + 1))
  const bilan = await purger({
    lire: () => {
      lus++
      return Promise.resolve(plein)
    },
    supprimer: () => Promise.reject(new Error('R2 hors service')),
    marquer: () => Promise.reject(new Error('ne doit pas etre appele')),
  })
  assertEquals(lus, 1)
  assertEquals(bilan, { retirees: 0, echecs: LOT_PURGE, lots: 1 })
})
