// Ce que ces tests prouvent : une cle d'objet ne porte jamais de donnee
// lisible, elle est fabriquee par le serveur, et ce qui revient de l'exterieur
// est confronte a la convention avant d'entrer en base.

import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import {
  cleDe,
  cleDepotBibliotheque,
  ErreurCleObjet,
  EXTENSION_ARCHIVE,
  verifierCle,
} from './cles.ts'

const PROFIL = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
const DOCUMENT = '7b1e4a2c-9d63-4f1a-8e55-2c0b6f9a7d10'
const SEANCE = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'
const ARCHIVE = 'd4c3b2a1-5f6e-4b7a-9c8d-1e2f3a4b5c6d'

Deno.test('7a -- la cle d une piece d identite ne porte que des UUID', () => {
  const cle = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  assertEquals(cle, `identity/${PROFIL}/${DOCUMENT}`)

  // Aucune donnee lisible : ni nom, ni courriel, ni telephone, ni type de
  // piece, ni genre -- et le genre compte double, puisqu il decide QUI peut
  // ouvrir le dossier (migration 0004).
  for (const interdit of ['@', 'passport', 'male', 'female', 'cni', ' ']) {
    assert(!cle.includes(interdit), `la cle ne doit pas porter << ${interdit} >>`)
  }
})

Deno.test('7b -- le premier segment reste le profil titulaire', () => {
  // Le stockage Supabase actuel ecrit `<auth.uid()>/<horodatage>.<ext>` et la
  // policy `kyc_depot_self` compare ce premier segment a `auth.uid()`. Garder
  // le profil en tete conserve ce rapprochement.
  assertEquals(cleDe('pieceIdentite', PROFIL, DOCUMENT).split('/')[1], PROFIL)
})

Deno.test('7c -- la cle d une archive porte son conteneur audio', () => {
  const cle = cleDe('archiveSeance', SEANCE, ARCHIVE)
  assertEquals(cle, `recordings/${SEANCE}/${ARCHIVE}${EXTENSION_ARCHIVE}`)
  assertEquals(EXTENSION_ARCHIVE, '.ogg')
})

Deno.test('7d -- les quatre domaines ont des prefixes distincts', () => {
  const cles = [
    cleDe('pieceIdentite', PROFIL, DOCUMENT),
    cleDe('archiveSeance', SEANCE, ARCHIVE),
    cleDe('pieceJointeMessage', SEANCE, ARCHIVE),
    cleDe('priveApplicatif', 'export', ARCHIVE),
  ]
  const prefixes = cles.map((c) => c.split('/')[0])
  assertEquals(prefixes, ['identity', 'recordings', 'messages', 'private'])
  assertEquals(new Set(prefixes).size, 4)
})

Deno.test('7e -- un identifiant qui n est pas un UUID est refuse', () => {
  const e = assertThrows(
    () => cleDe('pieceIdentite', '../../autre-profil', DOCUMENT),
    ErreurCleObjet,
  ) as ErreurCleObjet
  assert(e.motif.includes('UUID'))
  // Et la valeur refusee n entre pas dans le message.
  assert(!e.message.includes('autre-profil'))

  assertThrows(() => cleDe('archiveSeance', SEANCE, 'pas-un-uuid'), ErreurCleObjet)
  assertThrows(
    () => verifierCle('priveApplicatif', `private/Export Des Eleves/${ARCHIVE}`),
    ErreurCleObjet,
  )
})

Deno.test('7g -- les deux familles de la bibliotheque sont distinctes et opaques', () => {
  const support = cleDe('priveApplicatif', 'libraryupload', ARCHIVE)
  const preuve = cleDe('priveApplicatif', 'libraryproof', ARCHIVE)

  assertEquals(support, `private/libraryupload/${ARCHIVE}`)
  assertEquals(preuve, `private/libraryproof/${ARCHIVE}`)
  assertEquals(verifierCle('priveApplicatif', support), support)
  assertEquals(verifierCle('priveApplicatif', preuve), preuve)
  assertThrows(
    () => verifierCle('priveApplicatif', `private/libraryupload/not-an-uuid`),
    ErreurCleObjet,
  )
  assertThrows(
    () => verifierCle('priveApplicatif', `private/libraryproof/${ARCHIVE}/extra`),
    ErreurCleObjet,
  )
  assertThrows(
    () => verifierCle('priveApplicatif', `private/unknown/${ARCHIVE}`),
    ErreurCleObjet,
  )
})

Deno.test('7h -- la finalite choisit la famille sans recevoir de cle du client', () => {
  assertEquals(cleDepotBibliotheque('support', ARCHIVE), `private/libraryupload/${ARCHIVE}`)
  assertEquals(cleDepotBibliotheque('preuve', ARCHIVE), `private/libraryproof/${ARCHIVE}`)
})

Deno.test('7f -- la casse est normalisee, pour ne pas creer deux objets', () => {
  assertEquals(
    cleDe('pieceIdentite', PROFIL.toUpperCase(), DOCUMENT.toUpperCase()),
    `identity/${PROFIL}/${DOCUMENT}`,
  )
})

Deno.test('11a -- une cle venue de l exterieur est confrontee a la convention', () => {
  const attendue = `recordings/${SEANCE}/${ARCHIVE}.ogg`
  assertEquals(verifierCle('archiveSeance', attendue), attendue)
  // Une barre de tete est toleree et normalisee : LiveKit annonce parfois un
  // chemin absolu.
  assertEquals(verifierCle('archiveSeance', `/${attendue}`), attendue)
})

Deno.test('11b -- une remontee de chemin est refusee', () => {
  for (const hostile of [
    `recordings/${SEANCE}/../../identity/${PROFIL}/${DOCUMENT}`,
    `recordings//${SEANCE}/${ARCHIVE}.ogg`,
    `recordings/${SEANCE}/${ARCHIVE}.ogg\u0000`,
  ]) {
    assertThrows(() => verifierCle('archiveSeance', hostile), ErreurCleObjet)
  }
})

Deno.test('11c -- une cle d un autre domaine est refusee', () => {
  // Le point crucial : meme si la cle est parfaitement formee, elle n entre pas
  // dans un domaine qui n est pas le sien. C est ce qui empeche une piece
  // d identite d etre signee comme une archive.
  const identite = cleDe('pieceIdentite', PROFIL, DOCUMENT)
  const e = assertThrows(
    () => verifierCle('archiveSeance', identite),
    ErreurCleObjet,
  ) as ErreurCleObjet
  assert(e.motif.includes('prefixe etranger'))

  assertThrows(() => verifierCle('pieceIdentite', cleDe('archiveSeance', SEANCE, ARCHIVE)), ErreurCleObjet)
})

Deno.test('11d -- une profondeur ou un conteneur inattendus sont refuses', () => {
  assertThrows(() => verifierCle('pieceIdentite', `identity/${PROFIL}`), ErreurCleObjet)
  assertThrows(
    () => verifierCle('pieceIdentite', `identity/${PROFIL}/${DOCUMENT}/encore`),
    ErreurCleObjet,
  )
  // Une archive sans son conteneur audio n est pas une archive de ce depot.
  assertThrows(() => verifierCle('archiveSeance', `recordings/${SEANCE}/${ARCHIVE}`), ErreurCleObjet)
  assertThrows(
    () => verifierCle('archiveSeance', `recordings/${SEANCE}/${ARCHIVE}.mp4`),
    ErreurCleObjet,
  )
})

Deno.test('11e -- une cle vide ou demesuree est refusee', () => {
  assertThrows(() => verifierCle('pieceIdentite', ''), ErreurCleObjet)
  assertThrows(() => verifierCle('pieceIdentite', 'identity/' + 'a'.repeat(600)), ErreurCleObjet)
})
