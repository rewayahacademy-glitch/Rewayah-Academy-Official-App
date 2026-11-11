import { assertEquals } from 'jsr:@std/assert@1'
import {
  deciderSalle,
  DELAI_SANS_ENSEIGNANT_S,
  DEPASSEMENT_PAR_DEFAUT_MIN,
  ecrireSansEnseignant,
  elevesQuiPublient,
  FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT,
  finDeSeance,
  lireDepassement,
  lireSallesASurveiller,
  lireSansEnseignant,
  lireSeance,
  type SeanceVue,
} from './fermeture_salle.ts'
import { metadonneesDuJeton, type ParticipantVu } from './publication_differee.ts'
import { ecrireRecitation, lireRecitation } from './recitation.ts'

const PARLE = { can_publish: true, can_publish_video: false }
const PARLE_ET_MONTRE = { can_publish: true, can_publish_video: true }
const MUET = { can_publish: false, can_publish_video: false }

const enseignant: ParticipantVu = {
  identity: 'ens',
  metadata: metadonneesDuJeton('teacher', PARLE_ET_MONTRE),
  peutPublier: true,
}

function eleve(identity: string, peutPublier = true): ParticipantVu {
  return { identity, metadata: metadonneesDuJeton('student', PARLE), peutPublier }
}

const tuteur: ParticipantVu = {
  identity: 'tuteur',
  metadata: metadonneesDuJeton('guardian_observer', MUET),
  peutPublier: false,
}

const direction: ParticipantVu = {
  identity: 'Administration Rewayah',
  metadata: metadonneesDuJeton('admin_visible', PARLE_ET_MONTRE),
  peutPublier: true,
}

/// Midi, le 11/11/2026, en millisecondes.
const T = Date.parse('2026-11-11T12:00:00Z')
const MIN = 60_000
const DELAI = DELAI_SANS_ENSEIGNANT_S * 1000

/// Une seance en cours qui finit dans [finDansMin] minutes.
function seance(finDansMin: number, statut = 'in_progress', cours = true): SeanceVue {
  return { cours, statut, finPrevueMs: T + finDansMin * MIN, depassementMin: 15 }
}

const candidat: ParticipantVu = {
  identity: 'candidat',
  metadata: metadonneesDuJeton('candidat', PARLE_ET_MONTRE),
  peutPublier: true,
}

const intervieweur: ParticipantVu = {
  identity: 'intervieweur',
  metadata: metadonneesDuJeton('intervieweur', PARLE_ET_MONTRE),
  peutPublier: true,
}

// --- La marque dans la salle -----------------------------------------------

Deno.test('la marque s\'ecrit dans les metadonnees de la salle et s\'y relit', () => {
  assertEquals(lireSansEnseignant(ecrireSansEnseignant('', { depuis: T })), { depuis: T })
})

Deno.test('poser ou lever la marque garde la recitation de la salle, et inversement', () => {
  const recitation = { recitant: 'yasmine', depuis: 1 }
  const avec = ecrireSansEnseignant(ecrireRecitation('', recitation), { depuis: T })
  assertEquals(lireRecitation(avec), recitation)
  assertEquals(lireSansEnseignant(avec), { depuis: T })
  const sans = ecrireSansEnseignant(avec, null)
  assertEquals(lireSansEnseignant(sans), null)
  assertEquals(lireRecitation(sans), recitation)
  assertEquals(lireSansEnseignant(ecrireRecitation(avec, null)), { depuis: T })
})

Deno.test('une marque absente ou illisible ne donne rien : le delai repartira de zero', () => {
  for (const brut of [null, undefined, '', 'pas du json', '[]', '{"sans_enseignant":3}',
    '{"sans_enseignant":{"depuis":"hier"}}', '{"sans_enseignant":{"depuis":0}}']) {
    assertEquals(lireSansEnseignant(brut), null)
  }
})

// --- La seance lue en base --------------------------------------------------

Deno.test('une seance incomplete ne se lit pas : sans seance, la salle n\'est jamais fermee', () => {
  assertEquals(lireSeance(null, 15), null)
  assertEquals(lireSeance({ status: 'in_progress' }, 15), null)
  assertEquals(lireSeance({ status: '', ended_at: '2026-11-11T12:00:00Z' }, 15), null)
  assertEquals(lireSeance({ status: 'in_progress', ended_at: 'pas une date' }, 15), null)
  // Une seance retiree : rien n'en est deduit.
  assertEquals(
    lireSeance({ status: 'ended', ended_at: '2026-11-11T12:00:00Z', deleted_at: '2026-11-11T12:30:00Z' }, 15),
    null,
  )
  assertEquals(
    lireSeance({ status: 'in_progress', session_type: 'child', ended_at: '2026-11-11T12:00:00Z' }, 20),
    { cours: true, statut: 'in_progress', finPrevueMs: T, depassementMin: 20 },
  )
  assertEquals(
    lireSeance({ status: 'in_progress', session_type: 'standard', ended_at: '2026-11-11T12:00:00Z' }, 20)
      ?.cours,
    true,
  )
})

Deno.test('un entretien, une reunion, un type inconnu ou absent ne sont pas des cours', () => {
  for (const type of ['entretien', 'reunion', 'autre', undefined, null, 3]) {
    assertEquals(
      lireSeance({ status: 'in_progress', session_type: type, ended_at: '2026-11-11T12:00:00Z' }, 15)
        ?.cours,
      false,
    )
  }
})

Deno.test('un entretien de recrutement n\'est jamais touche : ni marque, ni micro, ni salle fermee', () => {
  // Un entretien passe par les memes salles, sans aucun role `teacher`. Sans
  // ce garde-fou, la regle fermerait la salle d'un entretien qui deborde.
  for (const s of [
    seance(30, 'in_progress', false),
    seance(-20, 'in_progress', false),
    seance(-45, 'ended', false),
  ]) {
    for (const marque of [null, { depuis: T - 10 * MIN }]) {
      assertEquals(
        deciderSalle({ maintenantMs: T, participants: [candidat, intervieweur], marque, seance: s }),
        { action: 'rien' },
      )
      assertEquals(
        deciderSalle({
          maintenantMs: T,
          participants: [candidat],
          marque,
          seance: s,
          departEnseignant: true,
          fermerAvecEnseignant: true,
        }),
        { action: 'rien' },
      )
    }
  }
})

Deno.test('le depassement illisible prend la valeur par defaut de la base', () => {
  assertEquals(lireDepassement(20), 20)
  assertEquals(lireDepassement('20'), 20)
  assertEquals(lireDepassement(0), 0)
  for (const v of [undefined, null, 'vingt', -5, 1.5, 100000, {}]) {
    assertEquals(lireDepassement(v), DEPASSEMENT_PAR_DEFAUT_MIN)
  }
})

Deno.test('la fin de seance : pas avant la fin prevue plus le depassement', () => {
  assertEquals(finDeSeance(null, T), 'non')
  assertEquals(finDeSeance(seance(30), T), 'non')
  // Fin prevue passee de 14 minutes : le depassement autorise court encore.
  assertEquals(finDeSeance(seance(-14), T), 'non')
  assertEquals(finDeSeance(seance(-15), T), 'non')
  assertEquals(finDeSeance(seance(-16), T), 'depassement')
  for (const statut of ['ended', 'canceled', 'canceled_late', 'teacher_absent', 'tech_failure']) {
    assertEquals(finDeSeance(seance(30, statut), T), 'cloture')
  }
  for (const statut of ['planned', 'preflight', 'in_progress']) {
    assertEquals(finDeSeance(seance(30, statut), T), 'non')
  }
})

// --- Pendant la seance ------------------------------------------------------

Deno.test('l\'enseignant est la : rien n\'est ferme, a aucun moment de la seance', () => {
  const salle = [enseignant, eleve('a'), eleve('b')]
  for (const s of [seance(30), seance(-10), seance(-20), null]) {
    assertEquals(
      deciderSalle({ maintenantMs: T, participants: salle, marque: null, seance: s }),
      { action: 'rien' },
    )
  }
})

Deno.test('l\'enseignant sort : rien n\'est retire, le serveur note seulement l\'instant', () => {
  assertEquals(
    deciderSalle({ maintenantMs: T, participants: [eleve('a'), eleve('b')], marque: null, seance: seance(30) }),
    { action: 'poser_echeance', depuis: T, resteMs: DELAI },
  )
})

Deno.test('pendant le delai de grace, les micros restent ouverts', () => {
  for (const ecoule of [0, 1000, DELAI - 1]) {
    assertEquals(
      deciderSalle({
        maintenantMs: T + ecoule,
        participants: [eleve('a'), eleve('b')],
        marque: { depuis: T },
        seance: seance(30),
      }),
      { action: 'rien', resteMs: DELAI - ecoule },
    )
  }
})

Deno.test('le delai passe sans l\'enseignant : le serveur ferme les micros des eleves, eux seuls', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI,
      participants: [eleve('a'), eleve('b', false), tuteur, direction],
      marque: { depuis: T },
      seance: seance(30),
    }),
    { action: 'fermer_micros', eleves: ['a'] },
  )
})

Deno.test('l\'enseignant revient : la marque est levee, rien n\'est ferme', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI + 5000,
      participants: [enseignant, eleve('a', false)],
      marque: { depuis: T },
      seance: seance(30),
    }),
    { action: 'lever_echeance' },
  )
})

Deno.test('le depart de l\'enseignant fait repartir le delai : une vieille marque ne ferme pas la classe', () => {
  // La marque d'une absence d'il y a dix minutes n'a pas ete levee (webhook
  // perdu). L'enseignant a une coupure : sans ce garde-fou, les micros
  // fermeraient a la seconde.
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [eleve('a')],
      marque: { depuis: T - 10 * MIN },
      seance: seance(30),
      departEnseignant: true,
    }),
    { action: 'poser_echeance', depuis: T, resteMs: DELAI },
  )
})

Deno.test('une marque dans le futur (horloge deplacee) est reprise a maintenant', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [eleve('a')],
      marque: { depuis: T + 5 * MIN },
      seance: seance(30),
    }),
    { action: 'poser_echeance', depuis: T, resteMs: DELAI },
  )
})

Deno.test('avant le cours, les eleves qui attendent (micro deja ferme) ne changent pas', () => {
  // Le jeton d'un eleve entre avant l'enseignant est signe sans droit de
  // publier (MICRO-AVANT-ENSEIGNANT) : il n'y a rien a fermer.
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI,
      participants: [eleve('a', false), eleve('b', false)],
      marque: { depuis: T },
      seance: seance(60),
    }),
    { action: 'rien' },
  )
})

Deno.test('la direction entree en visible n\'est pas l\'enseignant : les micros ferment quand meme', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI,
      participants: [direction, eleve('a')],
      marque: { depuis: T },
      seance: seance(30),
    }),
    { action: 'fermer_micros', eleves: ['a'] },
  )
})

Deno.test('un participant que LiveKit dit deja parti ne compte pas', () => {
  const parti: ParticipantVu = { ...enseignant, deconnecte: true }
  assertEquals(
    deciderSalle({ maintenantMs: T, participants: [parti, eleve('a')], marque: null, seance: seance(30) }),
    { action: 'poser_echeance', depuis: T, resteMs: DELAI },
  )
  assertEquals(
    deciderSalle({ maintenantMs: T, participants: [parti], marque: null, seance: seance(-60, 'ended') }),
    { action: 'rien' },
  )
})

Deno.test('une salle vide n\'appelle rien : LiveKit la ferme lui-meme', () => {
  assertEquals(
    deciderSalle({ maintenantMs: T, participants: [], marque: { depuis: T - DELAI }, seance: seance(-60, 'ended') }),
    { action: 'rien' },
  )
})

// --- La fin de la seance ----------------------------------------------------

Deno.test('fin prevue passee mais depassement en cours, sans enseignant : les micros ferment, pas la salle', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [eleve('a')],
      marque: { depuis: T - DELAI },
      seance: seance(-10),
    }),
    { action: 'fermer_micros', eleves: ['a'] },
  )
})

Deno.test('depassement passe et enseignant parti depuis le delai : la salle se ferme pour tous', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [eleve('a', false), eleve('b', false), tuteur],
      marque: { depuis: T - 10 * MIN },
      seance: seance(-16),
    }),
    { action: 'fermer_salle', motif: 'depassement' },
  )
})

Deno.test('depassement passe, l\'enseignant vient de sortir : le delai de grace court d\'abord', () => {
  // Une coupure du reseau de l'enseignant pendant un cours qui deborde ne
  // ferme pas la salle a la seconde.
  assertEquals(
    deciderSalle({ maintenantMs: T, participants: [eleve('a')], marque: null, seance: seance(-20) }),
    { action: 'poser_echeance', depuis: T, resteMs: DELAI },
  )
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI - 1,
      participants: [eleve('a')],
      marque: { depuis: T },
      seance: seance(-20),
    }),
    { action: 'rien', resteMs: 1 },
  )
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI,
      participants: [eleve('a')],
      marque: { depuis: T },
      seance: seance(-20),
    }),
    { action: 'fermer_salle', motif: 'depassement' },
  )
})

Deno.test('un cours qui se tient encore apres le depassement n\'est pas coupe', () => {
  assertEquals(FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT, false)
  for (const s of [seance(-20), seance(-45, 'ended'), seance(-45, 'tech_failure')]) {
    assertEquals(
      deciderSalle({ maintenantMs: T, participants: [enseignant, eleve('a')], marque: null, seance: s }),
      { action: 'rien' },
    )
  }
})

Deno.test('seance close en base, sans enseignant : la salle se ferme sans attendre', () => {
  for (const statut of ['ended', 'canceled', 'canceled_late', 'teacher_absent', 'tech_failure']) {
    assertEquals(
      deciderSalle({
        maintenantMs: T,
        participants: [eleve('a'), tuteur],
        marque: null,
        seance: seance(-45, statut),
      }),
      { action: 'fermer_salle', motif: 'cloture' },
    )
  }
})

Deno.test('l\'interrupteur du directeur : a la cloture, la salle se ferme meme avec l\'enseignant', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [enseignant, eleve('a')],
      marque: null,
      seance: seance(-45, 'ended'),
      fermerAvecEnseignant: true,
    }),
    { action: 'fermer_salle', motif: 'cloture' },
  )
  // Jamais avant la cloture en base, meme avec l'interrupteur.
  assertEquals(
    deciderSalle({
      maintenantMs: T,
      participants: [enseignant, eleve('a')],
      marque: null,
      seance: seance(-20),
      fermerAvecEnseignant: true,
    }),
    { action: 'rien' },
  )
})

Deno.test('seance illisible en base : la salle n\'est jamais fermee, seuls les micros le sont', () => {
  assertEquals(
    deciderSalle({
      maintenantMs: T + DELAI,
      participants: [eleve('a')],
      marque: { depuis: T },
      seance: null,
    }),
    { action: 'fermer_micros', eleves: ['a'] },
  )
  assertEquals(
    deciderSalle({
      maintenantMs: T + 24 * 60 * MIN,
      participants: [eleve('a', false)],
      marque: { depuis: T },
      seance: null,
    }),
    { action: 'rien' },
  )
})

Deno.test('la decision lit l\'etat, jamais l\'ordre : rejouee, elle rend la meme chose', () => {
  const entree = {
    maintenantMs: T + DELAI,
    participants: [eleve('a'), eleve('b')],
    marque: { depuis: T },
    seance: seance(30),
  }
  assertEquals(deciderSalle(entree), deciderSalle(entree))
  // Une fois les micros fermes, le passage suivant ne trouve plus rien a faire.
  assertEquals(
    deciderSalle({ ...entree, participants: [eleve('a', false), eleve('b', false)] }),
    { action: 'rien' },
  )
})

Deno.test('les eleves qui publient : ni l\'enseignant, ni le tuteur, ni un eleve deja ferme', () => {
  assertEquals(elevesQuiPublient([enseignant, eleve('a'), eleve('b', false), tuteur, direction]), ['a'])
})

// --- Les salles a surveiller ------------------------------------------------

Deno.test('les salles rendues par la base : une ligne incomplete est ecartee, jamais devinee', () => {
  const bonne = {
    provider: 'cloud',
    ws_url: 'wss://exemple',
    room_name: 'r_1',
    sessions: { status: 'in_progress', session_type: 'child', ended_at: '2026-11-11T12:00:00Z' },
  }
  const lues = lireSallesASurveiller(
    [
      bonne,
      {
        ...bonne,
        room_name: 'r_2',
        sessions: [{ status: 'ended', session_type: 'standard', ended_at: '2026-11-11T12:00:00Z' }],
      },
      // Un entretien : jamais examine.
      {
        ...bonne,
        room_name: 'r_entretien',
        sessions: { status: 'in_progress', session_type: 'entretien', ended_at: '2026-11-11T12:00:00Z' },
      },
      { ...bonne, provider: 'ailleurs' },
      { ...bonne, ws_url: '' },
      { ...bonne, room_name: '' },
      { ...bonne, sessions: null },
      { ...bonne, sessions: { status: 'in_progress' } },
      null,
      'texte',
    ],
    '20',
  )
  assertEquals(lues.map((s) => s.room_name), ['r_1', 'r_2'])
  assertEquals(lues[0].seance, { cours: true, statut: 'in_progress', finPrevueMs: T, depassementMin: 20 })
  assertEquals(lues[1].seance.statut, 'ended')
  assertEquals(lireSallesASurveiller(null, 15), [])
  assertEquals(lireSallesASurveiller({}, 15), [])
})
