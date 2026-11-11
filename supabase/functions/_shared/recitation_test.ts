import { assertEquals } from 'jsr:@std/assert@1'
import {
  elevesARetablir,
  metadonneesDuJeton,
  type ParticipantVu,
  permissionDePublication,
} from './publication_differee.ts'
import { elevesQuiPublient } from './fermeture_salle.ts'
import {
  camaradesARegler,
  droitsPendantRecitation,
  ecrireRecitation,
  elevePresent,
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

/// Un camarade pendant une recitation : `canPublish` garde, borne a la camera.
function cameraSeule(identity: string, capacites = PARLE_ET_MONTRE): ParticipantVu {
  return { ...eleve(identity, true, capacites), sourcesPermises: ['camera'] }
}

const SANS_MICRO_AVEC_CAMERA = { micro: false, camera: true }
const RIEN = { micro: false, camera: false }

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

// --- RECITATION-MICRO-SEUL (directeur, 11/11/2026) : le micro seul est ferme.

Deno.test('pendant la recitation, un camarade ne garde jamais le micro', () => {
  assertEquals(droitsPendantRecitation({ micro: true, camera: true }).micro, false)
  assertEquals(droitsPendantRecitation({ micro: true, camera: false }).micro, false)
  assertEquals(droitsPendantRecitation(null).micro, false)
})

Deno.test('pendant la recitation, un camarade garde la camera de son propre jeton', () => {
  assertEquals(droitsPendantRecitation({ micro: true, camera: true }), SANS_MICRO_AVEC_CAMERA)
})

Deno.test('camera interdite par le profil : la recitation ne donne jamais de camera', () => {
  assertEquals(droitsPendantRecitation({ micro: true, camera: false }), RIEN)
  // Jeton sans droits lisibles : rien n'est invente.
  assertEquals(droitsPendantRecitation(null), RIEN)
})

Deno.test('pendant la recitation, le serveur regle les autres eleves et eux seuls', () => {
  const salle = [
    enseignant,
    tuteur,
    eleve('yasmine', true, PARLE_ET_MONTRE),
    eleve('ilyes', true, PARLE_ET_MONTRE),
    eleve('adam'),
  ]
  assertEquals(camaradesARegler(salle, 'yasmine'), [
    // Camera permise par son jeton : il la garde, il perd le micro.
    { identity: 'ilyes', droits: SANS_MICRO_AVEC_CAMERA },
    // Camera interdite par son profil : il n'a plus rien.
    { identity: 'adam', droits: RIEN },
  ])
})

Deno.test('le recitant n\'est jamais regle, meme avec camera', () => {
  const salle = [enseignant, eleve('yasmine', true, PARLE_ET_MONTRE)]
  assertEquals(camaradesARegler(salle, 'yasmine'), [])
})

Deno.test('un camarade deja regle ou deja parti n\'est pas retouche (appel rejoue)', () => {
  const salle = [
    enseignant,
    eleve('yasmine'),
    // Deja a la camera seule.
    cameraSeule('ilyes'),
    // Camera interdite, deja ferme tout entier.
    eleve('sami', false),
    { ...eleve('adam'), deconnecte: true },
  ]
  assertEquals(camaradesARegler(salle, 'yasmine'), [])
})

Deno.test('un camarade ferme tout entier retrouve sa camera, pas son micro', () => {
  // Ferme par une autre regle (droit pas encore rendu) alors que la
  // recitation tient, donc que l'enseignant est la.
  const salle = [enseignant, eleve('yasmine'), eleve('ilyes', false, PARLE_ET_MONTRE)]
  assertEquals(camaradesARegler(salle, 'yasmine'), [
    { identity: 'ilyes', droits: SANS_MICRO_AVEC_CAMERA },
  ])
})

Deno.test('un camarade au micro seul permis (camera interdite) perd tout', () => {
  const salle: ParticipantVu[] = [
    enseignant,
    eleve('yasmine'),
    { ...eleve('adam'), sourcesPermises: ['micro'] },
  ]
  assertEquals(camaradesARegler(salle, 'yasmine'), [{ identity: 'adam', droits: RIEN }])
})

Deno.test('un eleve sans droits lisibles dans son jeton est ferme tout entier', () => {
  const ancien: ParticipantVu = {
    identity: 'ancien',
    metadata: '{"role":"student"}',
    peutPublier: true,
  }
  assertEquals(camaradesARegler([enseignant, eleve('yasmine'), ancien], 'yasmine'), [
    { identity: 'ancien', droits: RIEN },
  ])
})

Deno.test('la permission posee ne laisse jamais « publier » avec une liste vide', () => {
  // LiveKit lit `canPublish` + liste vide comme « toutes les sources ».
  assertEquals(permissionDePublication(RIEN), { canPublish: false, sources: [] })
  assertEquals(permissionDePublication(SANS_MICRO_AVEC_CAMERA), {
    canPublish: true,
    sources: ['camera'],
  })
  assertEquals(permissionDePublication({ micro: true, camera: false }), {
    canPublish: true,
    sources: ['micro'],
  })
  assertEquals(permissionDePublication({ micro: true, camera: true }), {
    canPublish: true,
    sources: ['micro', 'camera'],
  })
})

Deno.test('a la fin, un camarade reste a la camera seule retrouve son micro', () => {
  const salle = [enseignant, eleve('yasmine'), cameraSeule('ilyes')]
  assertEquals(elevesARendre(salle), [
    { identity: 'ilyes', droits: { micro: true, camera: true } },
  ])
})

Deno.test('a la fin, la camera interdite reste interdite : seul le micro revient', () => {
  const salle = [enseignant, eleve('yasmine'), eleve('adam', false)]
  assertEquals(elevesARendre(salle), [
    { identity: 'adam', droits: { micro: true, camera: false } },
  ])
})

// --- Les deux autres regles lisent toujours juste.

Deno.test('MICRO-AVANT-ENSEIGNANT : pendant la recitation, seul le recitant est retabli', () => {
  // Ilyes est a la camera seule : la regle ordinaire le voit « micro ferme »
  // et voudrait le retablir ; la recitation l'en empeche.
  const salle = [enseignant, eleve('yasmine'), cameraSeule('ilyes')]
  const candidats = elevesARetablir(salle)
  assertEquals(candidats.map((c) => c.identity), ['ilyes'])
  assertEquals(retablisPendantRecitation(candidats, 'yasmine'), [])
})

Deno.test('MICRO-AVANT-ENSEIGNANT : sans enseignant, une camera seule ne rend aucun micro', () => {
  assertEquals(elevesARetablir([eleve('yasmine'), cameraSeule('ilyes')]), [])
})

Deno.test('recitation finie mais droit non rendu : la regle ordinaire rend le micro', () => {
  // LiveKit muet au moment de rendre : la recitation est effacee, Ilyes
  // reste a la camera seule. Au prochain evenement, il est retabli.
  assertEquals(elevesARetablir([enseignant, cameraSeule('ilyes')]), [
    { identity: 'ilyes', droits: { micro: true, camera: true } },
  ])
})

Deno.test('FERMETURE-SALLE : un camarade a la camera seule est encore a fermer', () => {
  // Deux minutes sans enseignant : micro ET camera se ferment, pour lui aussi.
  assertEquals(elevesQuiPublient([cameraSeule('ilyes'), eleve('sami', false)]), ['ilyes'])
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
