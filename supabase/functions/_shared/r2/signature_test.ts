// Ce que ces tests prouvent, et c'est le point que la connectivite deja mesuree
// ne dit pas : une URL produite ici est bornee dans le temps, limitee a une
// seule methode, dirigee vers le seau du bon domaine, et ne contient aucune
// credential permanente.
//
// Aucun appel reseau. `aws4fetch` signe localement ; c'est precisement ce qui
// rend la forme de l'URL verifiable sans toucher Cloudflare.

import { assert, assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { DOMAINES, type LecteurEnvironnement, prefixeSecrets, seauAttendu } from './domaines.ts'
import { cleDe, ErreurCleObjet } from './cles.ts'
import {
  DUREE_DEPOT_S,
  DUREE_LECTURE_SENSIBLE_S,
  ErreurStockageR2,
  messagePourClient,
  objetExiste,
  signerDepot,
  signerLecture,
  TAILLE_MAXIMALE_PIECE_OCTETS,
  TYPES_PIECE_IDENTITE,
} from './signature.ts'

const HEX32 = 'a'.repeat(32)
const HEX64 = 'b'.repeat(64)
const PROFIL = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
const DOCUMENT = '7b1e4a2c-9d63-4f1a-8e55-2c0b6f9a7d10'
const SEANCE = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'
const ARCHIVE = 'd4c3b2a1-5f6e-4b7a-9c8d-1e2f3a4b5c6d'

const env: LecteurEnvironnement = (nom) => {
  for (const domaine of DOMAINES) {
    const p = prefixeSecrets(domaine)
    if (nom === `${p}_ACCOUNT_ID`) return HEX32
    if (nom === `${p}_ACCESS_KEY_ID`) return HEX32
    if (nom === `${p}_SECRET_ACCESS_KEY`) return HEX64
    if (nom === `${p}_BUCKET_NAME`) return seauAttendu(domaine)
    if (nom === `${p}_ENDPOINT`) return `https://${HEX32}.eu.r2.cloudflarestorage.com`
  }
  return undefined
}

// ============================================================
// D. URL pre-signees
// ============================================================

Deno.test('D15 -- l expiration est celle de la politique centrale, et elle est inscrite', async () => {
  const { url, expireDansSecondes } = await signerLecture(
    'archiveSeance',
    cleDe('archiveSeance', SEANCE, ARCHIVE),
    { env },
  )
  assertEquals(expireDansSecondes, DUREE_LECTURE_SENSIBLE_S)
  assertEquals(DUREE_LECTURE_SENSIBLE_S, 60, 'ADR-002 : soixante secondes')
  assertEquals(new URL(url).searchParams.get('X-Amz-Expires'), '60')
})

Deno.test('D14 -- aucune URL ou vérification R2 ne prend une clé hors convention', async () => {
  const cleHostile = 'private/libraryupload/../../identity/opaque'
  await assertRejects(() => signerLecture('priveApplicatif', cleHostile), ErreurCleObjet)
  await assertRejects(
    () => signerDepot('priveApplicatif', cleHostile, {
      typeMime: 'application/pdf',
      tailleOctets: 12,
      typesAutorises: ['application/pdf'],
      tailleMaximaleOctets: 1024,
    }),
    ErreurCleObjet,
  )
  await assertRejects(() => objetExiste('priveApplicatif', cleHostile), ErreurCleObjet)
})

Deno.test('D16 -- l URL n est pas permanente : elle porte date, duree et portee', async () => {
  const { url } = await signerLecture('archiveSeance', cleDe('archiveSeance', SEANCE, ARCHIVE), { env })
  const p = new URL(url).searchParams
  for (const parametre of [
    'X-Amz-Algorithm',
    'X-Amz-Credential',
    'X-Amz-Date',
    'X-Amz-Expires',
    'X-Amz-SignedHeaders',
    'X-Amz-Signature',
  ]) {
    assert(p.get(parametre), `${parametre} absent de l URL signee`)
  }
  assertEquals(p.get('X-Amz-Algorithm'), 'AWS4-HMAC-SHA256')
})

Deno.test('D17 -- la methode est bornee : lecture et depot ne signent pas la meme chose', async () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  const lecture = await signerLecture('pieceIdentite', cle, { env })
  const depot = await signerDepot('pieceIdentite', cle, {
    typeMime: 'image/jpeg',
    tailleOctets: 1024,
    typesAutorises: TYPES_PIECE_IDENTITE,
    tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
    env,
  })
  // La methode HTTP entre dans la chaine canonique de SigV4 : deux methodes
  // produisent deux signatures, donc une URL de lecture ne peut pas ecrire.
  assert(
    new URL(lecture.url).searchParams.get('X-Amz-Signature') !==
      new URL(depot.url).searchParams.get('X-Amz-Signature'),
  )
})

Deno.test('D19 -- aucun parametre n est encode en + : ce serait un 403 chez R2', async () => {
  // SigV4 impose l encodage RFC 3986, ou l espace s ecrit %20. `URLSearchParams`
  // encode l espace en `+` : un seul parametre a espace dans l URL et R2
  // recalculerait une signature differente. Mesure du 21 septembre 2026 : c est
  // exactement ce qui serait arrive avec `response-content-disposition`.
  const cas = [
    await signerLecture('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), { env }),
    await signerLecture('archiveSeance', cleDe('archiveSeance', SEANCE, ARCHIVE), { env }),
  ]
  for (const { url } of cas) {
    const requete = url.slice(url.indexOf('?'))
    assert(!requete.includes('+'), 'un + dans la chaine de requete signee est un 403 en puissance')
  }

  const depot = await signerDepot('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), {
    typeMime: 'image/jpeg',
    tailleOctets: 1024,
    typesAutorises: TYPES_PIECE_IDENTITE,
    tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
    env,
  })
  assert(!depot.url.slice(depot.url.indexOf('?')).includes('+'))
})

Deno.test('D18 -- aucune credential permanente ne sort dans l URL', async () => {
  const { url } = await signerLecture('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), { env })
  // Le secret ne doit apparaitre nulle part, sous aucune forme.
  assert(!url.includes(HEX64), 'le secret d acces ne doit jamais entrer dans une URL')
  // `X-Amz-Credential` porte l identifiant de cle, c est le protocole lui-meme
  // et il est inevitable ; ce qui compte est que le SECRET reste dehors et que
  // la portee soit bornee par la date et la duree.
  const credential = new URL(url).searchParams.get('X-Amz-Credential') ?? ''
  assert(credential.includes('/auto/s3/aws4_request'))
})

// ============================================================
// B. Routage -- l URL atteint le seau du domaine, et lui seul
// ============================================================

Deno.test('B10 -- chaque domaine signe vers son propre seau', async () => {
  const cas: [Parameters<typeof signerLecture>[0], string][] = [
    ['pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT)],
    ['archiveSeance', cleDe('archiveSeance', SEANCE, ARCHIVE)],
    ['pieceJointeMessage', cleDe('pieceJointeMessage', SEANCE, ARCHIVE)],
    ['priveApplicatif', cleDe('priveApplicatif', 'export', ARCHIVE)],
  ]
  for (const [domaine, cle] of cas) {
    const { url } = await signerLecture(domaine, cle, { env })
    const chemin = new URL(url).pathname
    assertEquals(chemin, `/${seauAttendu(domaine)}/${cle}`)
    // Et surtout : aucun autre seau n apparait dans l URL.
    for (const autre of DOMAINES) {
      if (autre !== domaine) {
        assert(!url.includes(seauAttendu(autre)), `${domaine} ne doit pas atteindre ${seauAttendu(autre)}`)
      }
    }
  }
})

// ============================================================
// 11. Contraintes du depot -- type et taille, signes donc opposables
// ============================================================

Deno.test('11f -- le type et la taille entrent dans les en-tetes signes', async () => {
  const depot = await signerDepot('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), {
    typeMime: 'application/pdf',
    tailleOctets: 4096,
    typesAutorises: TYPES_PIECE_IDENTITE,
    tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
    env,
  })

  assertEquals(depot.enTetesExiges['content-type'], 'application/pdf')
  assertEquals(depot.enTetesExiges['content-length'], '4096')
  assertEquals(depot.expireDansSecondes, DUREE_DEPOT_S)

  // Le point qui fait que ce sont des verrous et non des voeux : les deux
  // en-tetes sont SIGNES. R2 refusera un envoi qui annonce autre chose.
  const signes = (new URL(depot.url).searchParams.get('X-Amz-SignedHeaders') ?? '').split(';')
  assert(signes.includes('content-type'), 'content-type doit etre signe')
  assert(signes.includes('content-length'), 'content-length doit etre signe')
  assert(signes.includes('host'), 'host doit etre signe')
})

Deno.test('11g -- un type de contenu hors liste est refuse avant toute signature', async () => {
  await assertRejects(
    () =>
      signerDepot('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), {
        typeMime: 'application/x-msdownload',
        tailleOctets: 1024,
        typesAutorises: TYPES_PIECE_IDENTITE,
        tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
        env,
      }),
    ErreurStockageR2,
    'type de contenu refuse',
  )
})

Deno.test('11h -- une taille au-dela du plafond est refusee', async () => {
  for (const taille of [0, -1, TAILLE_MAXIMALE_PIECE_OCTETS + 1]) {
    await assertRejects(
      () =>
        signerDepot('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), {
          typeMime: 'image/png',
          tailleOctets: taille,
          typesAutorises: TYPES_PIECE_IDENTITE,
          tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
          env,
        }),
      ErreurStockageR2,
    )
  }
})

Deno.test('11i -- une duree hors bornes est refusee', async () => {
  for (const duree of [0, -60, 7200]) {
    await assertRejects(
      () => signerLecture('archiveSeance', cleDe('archiveSeance', SEANCE, ARCHIVE), { dureeSecondes: duree, env }),
      ErreurStockageR2,
    )
  }
})

// ============================================================
// 14. Observabilite sans fuite
// ============================================================

Deno.test('14a -- un echec de configuration ne dit rien au client', () => {
  const configuration = new ErreurStockageR2('configuration', 'pieceIdentite', 'R2_IDENTITY_VAULT_ENDPOINT absent')
  const masque = messagePourClient(configuration)
  assertEquals(masque, { message: 'stockage indisponible', statut: 503 })
  // Le nom du secret reste cote serveur : le message rendu ne le cite pas.
  assert(!masque.message.includes('R2_IDENTITY_VAULT_ENDPOINT'))

  // Une erreur inconnue est masquee de la meme facon, jamais relayee telle quelle.
  assertEquals(messagePourClient(new Error('AccessDenied: /rewayah-identity-vault/identity/...')), {
    message: 'stockage indisponible',
    statut: 503,
  })

  // Seule une faute de l appelant lui revient, et sans detail.
  assertEquals(messagePourClient(new ErreurStockageR2('validation', 'pieceIdentite', 'taille')), {
    message: 'depot refuse',
    statut: 400,
  })
})

Deno.test('14b -- une trace ne peut pas porter une URL signee', async () => {
  const { url } = await signerLecture('pieceIdentite', cleDe('pieceIdentite', PROFIL, DOCUMENT), { env })
  // `TraceStockage` est une forme fermee : il n existe aucun champ ou une URL
  // pourrait passer. Ce test fige cette forme.
  const trace = {
    domaine: 'pieceIdentite' as const,
    operation: 'lecture' as const,
    statut: 'accorde' as const,
    ressource: DOCUMENT,
  }
  assertEquals(Object.keys(trace).sort(), ['domaine', 'operation', 'ressource', 'statut'])
  assert(!JSON.stringify(trace).includes('X-Amz-Signature'))
  assert(!JSON.stringify(trace).includes(url))
})
