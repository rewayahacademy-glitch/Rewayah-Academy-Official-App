import { assertEquals } from 'jsr:@std/assert@1'
import { metadonneesDuJeton, type ParticipantVu } from './publication_differee.ts'
import {
  ecrireRecitation,
  elevePresent,
  elevesAFermer,
  elevesARendre,
  lireRecitation,
  recitationTenue,
  retablisPendantRecitation,
} from './recitation.ts'

const PARLE = { can_publish: true, can_publish_video: false }
const PARLE_ET_MONTRE = { can_publish: true, can_publish_video: true }
const MUET = { can_publish: false, can_publish_video: false }

const enseignant: ParticipantVu = {
  identity: 'ens',
  metadata: metadonneesDuJeton('teacher', PARLE_ET_MONTRE),
  peutPublier: true,
}

function eleve(identity: string, peutPublier = true, capacites = PARLE): ParticipantVu {
  return { identity, metadata: metadonneesDuJeton('student', capacites), peutPublier }
}

const tuteur: ParticipantVu = {
  identity: 'tuteur',
  metadata: metadonneesDuJeton('guardian', MUET),
  peutPublier: false,
}

const YASMINE = { recitant: 'yasmine', depuis: 1 }

Deno.test('la recitation s\'ecrit dans les metadonnees de la salle et s\'y relit', () => {
  const ecrit = ecrireRecitation('', YASMINE)
  assertEquals(lireRecitation(ecrit), YASMINE)
})

Deno.test('ecrire la recitation garde les autres cles de la salle', () => {
  const ecrit = ecrireRecitation('{"autre":42}', YASMINE)
  assertEquals(JSON.parse(ecrit).autre, 42)
  const efface = ecrireRecitation(ecrit, null)
  assertEquals(JSON.parse(efface), { autre: 42 })
  assertEquals(lireRecitation(efface), null)
})

Deno.test('des metadonnees absentes ou illisibles ne portent aucune recitation', () => {
  assertEquals(lireRecitation(null), null)
  assertEquals(lireRecitation(''), null)
  assertEquals(lireRecitation('pas du json'), null)
  assertEquals(lireRecitation('[]'), null)
  assertEquals(lireRecitation('{"recitation":"yasmine"}'), null)
  assertEquals(lireRecitation('{"recitation":{"recitant":"  "}}'), null)
  assertEquals(lireRecitation('{"recitation":{"recitant":"y"}}'), { recitant: 'y', depuis: 0 })
})

Deno.test('la recitation tient tant que l\'enseignant et le recitant sont dans la salle', () => {
  assertEquals(recitationTenue(YASMINE, [enseignant, eleve('yasmine'), eleve('ilyes')]), true)
})

Deno.test('le recitant parti : la recitation ne tient plus', () => {
  assertEquals(recitationTenue(YASMINE, [enseignant, eleve('ilyes')]), false)
  assertEquals(
    recitationTenue(YASMINE, [enseignant, { ...eleve('yasmine'), deconnecte: true }]),
    false,
  )
})

Deno.test('l\'enseignant parti : la recitation ne tient plus', () => {
  assertEquals(recitationTenue(YASMINE, [eleve('yasmine'), eleve('ilyes')]), false)
  assertEquals(
    recitationTenue(YASMINE, [{ ...enseignant, deconnecte: true }, eleve('yasmine')]),
    false,
  )
})

Deno.test('sans recitation ecrite, rien ne tient', () => {
  assertEquals(recitationTenue(null, [enseignant, eleve('yasmine')]), false)
})

Deno.test('un recitant qui n\'est pas un eleve ne fait pas tenir la recitation', () => {
  assertEquals(recitationTenue({ recitant: 'tuteur', depuis: 1 }, [enseignant, tuteur]), false)
  assertEquals(elevePresent([enseignant, tuteur], 'ens'), false)
})

Deno.test('pendant la recitation, le serveur ferme les autres eleves et eux seuls', () => {
  const salle = [enseignant, tuteur, eleve('yasmine'), eleve('ilyes'), eleve('adam')]
  assertEquals(elevesAFermer(salle, 'yasmine'), ['ilyes', 'adam'])
})

Deno.test('un eleve deja ferme ou deja parti n\'est pas ferme une seconde fois', () => {
  const salle = [
    enseignant,
    eleve('yasmine'),
    eleve('ilyes', false),
    { ...eleve('adam'), deconnecte: true },
  ]
  assertEquals(elevesAFermer(salle, 'yasmine'), [])
})

Deno.test('a la fin, chaque eleve ferme retrouve les droits promis par son jeton', () => {
  const salle = [
    enseignant,
    eleve('yasmine'),
    eleve('ilyes', false),
    eleve('adam', false, PARLE_ET_MONTRE),
  ]
  assertEquals(elevesARendre(salle), [
    { identity: 'ilyes', droits: { micro: true, camera: false } },
    { identity: 'adam', droits: { micro: true, camera: true } },
  ])
})

Deno.test('la fin rend les droits meme si l\'enseignant est parti : jamais une classe bloquee', () => {
  assertEquals(elevesARendre([eleve('yasmine'), eleve('ilyes', false)]), [
    { identity: 'ilyes', droits: { micro: true, camera: false } },
  ])
})

Deno.test('la fin ne donne rien a qui n\'avait rien : tuteur, eleve sans micro', () => {
  const salle = [enseignant, tuteur, eleve('muet', false, MUET)]
  assertEquals(elevesARendre(salle), [])
})

Deno.test('pendant la recitation, le filet d\'un camarade ne rouvre pas son micro', () => {
  const ilyes = { identity: 'ilyes', droits: { micro: true, camera: false } }
  const yasmine = { identity: 'yasmine', droits: { micro: true, camera: false } }
  assertEquals(retablisPendantRecitation([ilyes], 'yasmine'), [])
  assertEquals(retablisPendantRecitation([ilyes, yasmine], 'yasmine'), [yasmine])
})
