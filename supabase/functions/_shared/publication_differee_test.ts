import { assertEquals } from 'jsr:@std/assert@1'
import {
  doitDifferer,
  elevesARetablir,
  enseignantPresent,
  lireMetadonnees,
  metadonneesDuJeton,
  type ParticipantVu,
} from './publication_differee.ts'

const PARLE = { can_publish: true, can_publish_video: false }
const PARLE_ET_MONTRE = { can_publish: true, can_publish_video: true }
const MUET = { can_publish: false, can_publish_video: false }

const enseignant: ParticipantVu = {
  identity: 'ens',
  metadata: metadonneesDuJeton('teacher', PARLE_ET_MONTRE),
  peutPublier: true,
}

function eleve(identity: string, capacites = PARLE, peutPublier = false): ParticipantVu {
  return { identity, metadata: metadonneesDuJeton('student', capacites), peutPublier }
}

Deno.test('un eleve est differe quand l\'enseignant est absent', () => {
  assertEquals(doitDifferer('student', PARLE, 'absent'), true)
  assertEquals(doitDifferer('student', PARLE_ET_MONTRE, 'absent'), true)
})

Deno.test('un eleve n\'est pas differe quand l\'enseignant est la', () => {
  assertEquals(doitDifferer('student', PARLE, 'present'), false)
})

Deno.test('dans le doute (LiveKit muet), la classe parle : pas de jeton differe', () => {
  assertEquals(doitDifferer('student', PARLE, 'inconnue'), false)
})

Deno.test('celui qui conduit et les adultes de l\'institution ne sont jamais differes', () => {
  for (const role of ['teacher', 'admin_visible']) {
    assertEquals(doitDifferer(role, PARLE_ET_MONTRE, 'absent'), false)
  }
})

Deno.test('les roles qui ne publient jamais ne changent pas', () => {
  for (const role of ['guardian_observer', 'masked_controller', 'admin_masked']) {
    assertEquals(doitDifferer(role, MUET, 'absent'), false)
  }
  // Un eleve sans droit de publier n'a rien a differer.
  assertEquals(doitDifferer('student', MUET, 'absent'), false)
})

Deno.test('les metadonnees d\'un eleve portent les droits qu\'il retrouvera', () => {
  assertEquals(JSON.parse(metadonneesDuJeton('student', PARLE)), {
    role: 'student',
    pub: { micro: true, camera: false },
  })
  assertEquals(JSON.parse(metadonneesDuJeton('student', PARLE_ET_MONTRE)), {
    role: 'student',
    pub: { micro: true, camera: true },
  })
  // La camera ne va jamais sans le micro : `can_publish` commande tout.
  assertEquals(
    JSON.parse(metadonneesDuJeton('student', { can_publish: false, can_publish_video: true })),
    { role: 'student', pub: { micro: false, camera: false } },
  )
})

Deno.test('les metadonnees des autres roles ne changent pas de forme', () => {
  assertEquals(metadonneesDuJeton('teacher', PARLE_ET_MONTRE), '{"role":"teacher"}')
  assertEquals(metadonneesDuJeton('guardian_observer', MUET), '{"role":"guardian_observer"}')
})

Deno.test('une metadonnee absente ou illisible ne donne ni role ni droit', () => {
  for (const brut of [null, undefined, '', 'teacher', '[]', '3', '{"role":7}']) {
    assertEquals(lireMetadonnees(brut), { role: '', pub: null })
  }
  assertEquals(lireMetadonnees('{"role":"student","pub":"oui"}'), { role: 'student', pub: null })
  assertEquals(lireMetadonnees('{"role":"student","pub":{"micro":"oui"}}'), {
    role: 'student',
    pub: { micro: false, camera: false },
  })
})

Deno.test('l\'enseignant est present seulement par son role signe, et s\'il n\'est pas parti', () => {
  assertEquals(enseignantPresent([]), false)
  assertEquals(enseignantPresent([eleve('a'), eleve('b')]), false)
  assertEquals(enseignantPresent([eleve('a'), enseignant]), true)
  assertEquals(enseignantPresent([{ ...enseignant, deconnecte: true }]), false)
  // Un observateur, meme adulte, n'ouvre pas les micros.
  assertEquals(
    enseignantPresent([{ identity: 'ctl', metadata: '{"role":"masked_controller"}' }]),
    false,
  )
  assertEquals(enseignantPresent([{ identity: 'x', metadata: null }]), false)
})

Deno.test('sans enseignant dans la salle, personne n\'est retabli', () => {
  assertEquals(elevesARetablir([eleve('a'), eleve('b', PARLE_ET_MONTRE)]), [])
})

Deno.test('a l\'entree de l\'enseignant, chaque eleve differe retrouve SES droits', () => {
  assertEquals(
    elevesARetablir([enseignant, eleve('a'), eleve('b', PARLE_ET_MONTRE)]),
    [
      { identity: 'a', droits: { micro: true, camera: false } },
      { identity: 'b', droits: { micro: true, camera: true } },
    ],
  )
})

Deno.test('un eleve qui publie deja, un observateur ou un parti ne sont pas touches', () => {
  assertEquals(
    elevesARetablir([
      enseignant,
      eleve('deja', PARLE, true),
      { identity: 'tuteur', metadata: '{"role":"guardian_observer"}', peutPublier: false },
      { ...eleve('parti'), deconnecte: true },
      // Jeton d'avant ce lot (aucun droit promis) : rien n'est invente.
      { identity: 'ancien', metadata: '{"role":"student"}', peutPublier: false },
      // Droit inconnu : on ne touche pas.
      { identity: 'flou', metadata: metadonneesDuJeton('student', PARLE) },
    ]),
    [],
  )
})

Deno.test('rejouer la meme salle donne le meme resultat (webhook en double)', () => {
  const salle = [enseignant, eleve('a')]
  assertEquals(elevesARetablir(salle), elevesARetablir(salle))
})
