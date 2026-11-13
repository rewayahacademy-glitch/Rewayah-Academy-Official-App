// Les e-mails en anglais, ecrits a la main. Ils suivent le sens du francais
// (`modeles_fr.ts`) ; memes liens, memes boutons. Competence `mots-rewayah`.

import { APP } from './gabarit.ts'
import { avec, avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole, montantLisible,
  precisions, type Precisions } from './outils.ts'
import { quandSeance, codeCandidat } from './modeles_fr.ts'

const PAROLE: Parole = {
  salut: 'Hello',
  fin: ',',
  salutSeul: 'Hello,',
  note: 'The details are in the app, once you are signed in.',
  sujetLibre: 'A message from Rewayah Academy',
  locale: 'en-GB',
}
export const PRECISIONS_EN: Precisions = {
  locale: 'en-GB',
  a: 'at',
  classe: (n) => `Class: “${n}”.`,
  eleves: (n, plusieurs) => plusieurs ? `Students: ${n}.` : `Student: ${n}.`,
  premiere: (q) => `First session: ${q}.`,
}

const avis = avisDans(PAROLE)

const RAISON: Record<string, string> = {
  compte: 'You are receiving this e-mail because it concerns your Rewayah Academy account.',
  inscription: 'You are receiving this e-mail because it concerns a request made on Rewayah Academy.',
  classes: 'You are receiving this e-mail because it concerns a class you attend or teach.',
  facturation: 'You are receiving this e-mail because it concerns your household’s billing.',
  recrutement: 'You are receiving this e-mail because you are in contact with our recruitment team.',
  direction: 'You are receiving this e-mail from the management of Rewayah Academy.',
  nouvelles: 'You are receiving this e-mail because you follow the news from Rewayah Academy.',
}

const MODELES: Record<string, Fabrique> = {
  demande_recue: (d) => avis(d, 'We have received your request', 'We have received your request',
    'We have received your request for a time slot. The management is reviewing it and will reply in the app.',
    'Follow my request', '/tuteur/demandes'),
  demande_presentation: (d) => avis(d, 'An introduction request has been received', 'Introduction request received',
    'An introduction request has been received. It is waiting for you in the app.',
    'Open the request', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'Your class is ready', 'Your class is ready',
    'The class matching your request is ready. A teacher still has to be assigned to it; you will be notified.',
    'View the class', '/tuteur/demandes'),
  // SUIVI-ATTENTE (12/11/2026) : courriel de l'enseignant a l'affectation.
  enseignant_affecte: (d) => {
    if (d.portee === 'classe') {
      const P = PRECISIONS_EN
      const n = Number(d.eleves_n)
      const tranche = d.public === 'adulte' ? 'adults' : d.public === 'enfant' ? 'children' : ''
      const eleves = Number.isInteger(n) && n > 0 ? `Students: ${n}${tranche ? ` (${tranche})` : ''}.` : ''
      const q = quandSeance(d, P.locale, P.a)
      const detail = [typeof d.classe === 'string' && d.classe ? P.classe(d.classe) : '', eleves, q ? `First class: ${q}.` : ''].filter(Boolean).join(' ')
      return avis(d, 'A class is entrusted to you', 'A class is entrusted to you',
        avec('A class is entrusted to you.', detail)
          + ' Introduce yourself to the families from the app: a message is already written, and you can edit it.',
        'Introduce myself', '/enseignant/classes')
    }
    return avis(d, 'A teacher has been assigned to the class', 'Your class has a teacher',
    'A teacher has been assigned to the class. You will find their name and the schedule in the app.',
    'View the class', '/tuteur/demandes')
  },
  // SUIVI-ATTENTE (12/11/2026): "Everything is ready" (step 5), to the family or the adult
  // student, never to a child.
  tout_est_pret: (d) => {
    const P = PRECISIONS_EN
    if (d.portee === 'soi') {
      return avis(d, 'Everything is ready for your first class', 'Everything is ready',
        avec('Everything is ready: your class, your teacher and your schedule are confirmed.', precisions(d, P, { premiere: true }))
          + ' You can follow it in the app.',
        'See the tracking', '/eleve')
    }
    return avis(d, 'Everything is ready for the first class', 'Everything is ready',
      avec('Everything is ready: the class, the teacher and the schedule are confirmed.', precisions(d, P, { premiere: true }))
        + ' You can follow it in the app.',
      'See the tracking', '/tuteur/demandes')
  },
  demande_close: (d) => avis(d, 'Your request has been closed', 'Your request has been closed',
    'Your time slot request has been closed. The management’s reply is in the app.',
    'Read the reply', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'Class change, same schedule', 'Class change',
    'A student in your household has joined another class, at the same time.',
    'View the details', '/tuteur/demandes'),
  // Fiche of 27/10/2026, line 15: the nine class and session events.
  // COURRIELS-UX (UX-026, FN-108) : la classe, l'enfant, la premiere seance et son fuseau.
  classe_creee: (d) => {
    if (d.portee === 'classe') {
      return avis(d, 'A class is created', 'A class is created',
        avec('A class has just been created.', precisions(d, PRECISIONS_EN, { eleves: false, premiere: true })) + ' Its students and its schedule are in the app.',
        'View my classes', '/enseignant/classes')
    }
    return avis(d, 'Your class is created', 'Your class is created',
      avec(d.portee === 'foyer' ? 'A class is created for your household.' : 'Your class is created.', precisions(d, PRECISIONS_EN, { premiere: true })) + ' Its teacher and its full schedule are in the app.',
      'View the schedule', '/tuteur')
  },
  enseignant_change: (d) => avis(d, 'The class teacher is changing', 'The class teacher is changing',
    'Another teacher is taking the class, at the same time. The name is in the app.',
    'View the class', '/tuteur'),
  eleve_inscrit: (d) => {
    if (d.portee === 'foyer') {
      return avis(d, 'A class enrolment', 'A class enrolment',
        avec('A student from your household joins a class.', precisions(d, PRECISIONS_EN, { premiere: true })) + ' Their teacher and full schedule are in the app.',
        'View the class', '/tuteur')
    }
    if (d.portee === 'soi') {
      return avis(d, 'You join a class', 'You join a class',
        avec('You join a class.', precisions(d, PRECISIONS_EN, { premiere: true })) + ' Your teacher and your full schedule are in the app.',
        'View my class', '/eleve')
    }
    return avis(d, 'A student joins your class', 'A student joins your class',
      avec('A student joins your class.', precisions(d, PRECISIONS_EN, { eleves: false })) + ' The profile is in the app.',
      'View my classes', '/enseignant/classes')
  },
  eleve_retire: (d) => avis(d, 'A student leaves your class', 'A student leaves your class',
    'A student leaves your class. The updated list is in the app.',
    'View my classes', '/enseignant/classes'),
  creneau_change: (d) => avis(d, 'The class schedule is changing', 'The class schedule is changing',
    'The class schedule is changing. The new schedule is in the app.',
    'View the new schedule', '/tuteur'),
  seance_annulee: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    return avis(d, 'A session is cancelled', 'A session is cancelled',
      avec(quand ? `The session of ${quand} is cancelled.` : 'A class session is cancelled.', precisions(d, PRECISIONS_EN)),
      'View the schedule', '/tuteur')
  },
  seance_deplacee: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    return avis(d, 'A session is moved', 'A session is moved',
      quand ? `A session is moved to ${quand}.` : 'A class session is moved. The new time is in the app.',
      'View the new time', '/tuteur')
  },
  enseignante_absente: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    return avis(d, 'The teacher is absent for a session', 'The teacher is absent for a session',
      (quand ? `The teacher is absent for the session of ${quand}.` : 'The teacher is absent for a class session.')
        + ' The management will keep you informed.',
      'View the schedule', '/tuteur')
  },
  // A3 (31/10/2026) : le titulaire n’est pas entré dans la salle.
  remplacement_avertissement: (d) => avis(d, 'You are not in the room yet', 'You are not in the room yet',
    (typeof d.minutes === 'string' ? `Join within ${d.minutes} minutes` : 'Join now') + ': after that, if a teacher has offered to replace you, you lose access to today’s session.',
    'View my day', '/enseignant/journee'),
  remplacement_pre_alerte: (d) => avis(d, 'A replacement is being prepared', 'A replacement is being prepared',
    'A teacher is not in their room yet. Say you are ready in Replacements.',
    'View replacements', '/enseignant/journee/remplacements'),
  remplacement_inutile: (d) => avis(d, 'The replacement is no longer needed', 'The replacement is no longer needed',
    'The class teacher has arrived. Thank you for being ready.',
    'View replacements', '/enseignant/journee/remplacements'),
  titulaire_en_retard: (d) => avis(d, 'The class teacher is late', 'The class teacher is late',
    d.portee === 'direction' ? 'A class teacher has not entered their room. A replacement is being sought.' : 'The academy is looking for a replacement: stay in the room.',
    'Open the app', '/tuteur'),
  // A3-bis (02/11/2026).
  // SNT (03/11/2026).
  seance_reportee: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    return avis(d, 'A session is postponed', 'A session is postponed',
      (quand ? `The session of ${quand} did not take place: it is postponed.` : 'A class session did not take place: it is postponed.')
        + ' The new date will be given in the app.',
      'View the schedule', '/tuteur')
  },
  seance_reportee_direction: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    const classe = typeof d.classe === 'string' ? ` of the class ${d.classe}` : ''
    const ens = typeof d.enseignant === 'string' ? ` Class teacher: ${d.enseignant}.` : ''
    const delai = typeof d.minutes === 'string' ? ` within ${d.minutes} minutes` : ''
    return avis(d, 'Session postponed: set the new date', 'Session postponed: set the new date',
      `No teacher joined the room${classe}${quand ? `, session of ${quand}` : ''}${delai}: the session is postponed.${ens} Set the new date in the schedule.`,
      'See the schedule', '/admin/operations/planning')
  },
  remplacement_personne_en_salle: (d) => {
    const quand = quandSeance(d, 'en-GB', 'at')
    const classe = typeof d.classe === 'string' ? ` of the class ${d.classe}` : ''
    const ens = typeof d.enseignant === 'string' ? ` Class teacher: ${d.enseignant}.` : ''
    return avis(d, 'Nobody is in the room', 'Nobody is in the room',
      `Neither the teacher nor a replacement has joined the room${classe}${quand ? `, session of ${quand}` : ''}.${ens} Find a replacement or inform the families.`,
      'See the schedule', '/admin/operations/planning')
  },
  remplacant_arrive: (d) => avis(d, 'A replacement teacher is on the way', 'A replacement teacher is on the way',
    'A replacement teacher is on the way: stay in the room.',
    'Open the app', '/tuteur'),
  classe_supprimee: (d) => avis(d, 'The class is closed', 'The class is closed',
    avec('The class is closed.', precisions(d, PRECISIONS_EN)) + ' The management will contact you about what comes next.',
    'Open the app', '/tuteur'),
  remplacement_propose: (d) => avis(d, 'A replacement is offered to you', 'A replacement is offered to you',
    'A class replacement is offered to you. Reply in the app so that the class is covered.',
    'View the replacement', '/enseignant/journee/remplacements'),
  remplacement_pris: (d) => avis(d, 'The replacement has been assigned', 'The replacement has been assigned',
    'The class replacement has been assigned.',
    'View my day', '/enseignant/journee/remplacements'),
  controle_mission_attribuee: (d) => avis(d, 'A review mission has been assigned to you', 'New review mission',
    'A review mission has been assigned to you.', 'Open the mission', '/controleur'),
  controle_mission_non_controlee: (d) => avis(d, 'A mission was left without verification', 'Mission without verification',
    'A review mission was left without verification.', 'View the draws', '/admin/securite-audit/tirages'),
  paiement_relance: (d) => {
    const j = typeof d.jours_avant === 'number' ? d.jours_avant : null
    const quand = j === null ? 'soon' : j === 0 ? 'today' : j === 1 ? 'tomorrow' : `in ${j} days`
    return avis(d, `A payment is due ${quand}`, 'A payment is due',
      `This month’s payment is due ${quand}. It is made in the app, under Payments, so that classes continue without interruption.`,
      'Make the payment', '/tuteur/foyer/recharge')
  },
  acces_suspendu_paiement: (d) => avis(d, 'Access is suspended', 'Access is suspended',
    'This month’s payment has not been received: access to the class is suspended. It returns as soon as the payment is received.',
    'Make the payment', '/tuteur/foyer/recharge'),
  acces_retabli_paiement: (d) => avis(d, 'Access has been restored', 'Access has been restored',
    'The payment has been received: access to the class is restored.', 'Open the app', '/tuteur/foyer/recharge'),
  paiement_recu: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'The payment has been received', 'The payment has been received',
      m === null ? 'The payment has been received. The balance is up to date in the app.'
        : `The payment of ${m} has been received. The balance is up to date in the app.`,
      'Open the app', '/tuteur/foyer/recharge')
  },
  // FN-115b (02/11/2026) : remboursement et contestation d'un paiement.
  remboursement_effectue: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'A refund has been made', 'A refund has been made',
      m === null ? 'A refund has been made to the payment method used. The balance is up to date in the app.'
        : `A refund of ${m} has been made to the payment method used. The balance is up to date in the app.`,
      'Open the app', '/tuteur/foyer/recharge')
  },
  litige_ouvert: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'A payment is disputed with the bank', 'A payment is disputed',
      m === null ? 'A payment is disputed with the bank. During the review, the students concerned cannot access sessions or resources. If this is a mistake, write to us.'
        : `A payment of ${m} is disputed with the bank. During the review, the students concerned cannot access sessions or resources. If this is a mistake, write to us.`,
      'Open the app', '/tuteur/foyer/recharge')
  },
  litige_clos: (d) => {
    const f = montantLisible({ montant_mineur: d.frais_mineur, devise: d.devise }, PAROLE.locale)
    return avis(d, 'The dispute is closed', 'The dispute is closed',
      d.issue === 'gagne' ? 'The bank ruled in favour of the academy: the payment is restored and access returns once the month is paid again.'
        : f === null ? 'The bank ruled in your favour: the payment is treated as a full refund. The dispute fees are added to the household balance.'
        : `The bank ruled in your favour: the payment is treated as a full refund. The dispute fees (${f}) are added to the household balance.`,
      'Open the app', '/tuteur/foyer/recharge')
  },
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'A member of your family'
    const code = typeof d.code === 'string' && /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(d.code) ? d.code : null
    const lien = `${APP}/#/connexion${code ? `?mode=creer&foyer=1&code=${code}` : ''}`
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} invites you to join their household on Rewayah Academy`,
      apercu: `${qui} invites you to follow the family’s classes with them.`,
      titre: 'You are invited to join a household',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} invites you to join their household on Rewayah Academy, to follow the family’s classes together.` },
        ...(code
          ? [{ type: 'texte', texte: 'Create your account with this e-mail address, or sign in if you already have one. Your invitation code:' } as const, { type: 'code', code } as const]
          : [{ type: 'texte', texte: 'Sign in with this e-mail address: the invitation is waiting for you in the app.' } as const]),
        { type: 'bouton', libelle: 'Open the invitation', href: lien },
        ...(code ? [{ type: 'texte', texte: 'The code only works with this address, and only once.' } as const] : []),
        { type: 'note', texte: (fin ? `The invitation is valid until ${fin}. ` : '') + 'If you do not know this person, ignore this message.' },
      ],
    }
  },
  lien_inscription: (d) => {
    const quand = dateLongue(d.date_reponse, PAROLE.locale)
    const nom = typeof d.formulaire === 'string' && d.formulaire.trim() ? ` “${d.formulaire.trim()}”` : ''
    const rappel = `${quand ? `On ${quand}, you` : 'You'} answered our form${nom}.`
    return {
      sujet: 'Your application to Rewayah Academy: create your account',
      apercu: rappel,
      titre: 'Your application continues in the app',
      blocs: [
        { type: 'texte', texte: bonjour(d, PAROLE) },
        { type: 'texte', texte: rappel },
        { type: 'texte', texte: 'This form was used to put forward your application to teach the Quran at Rewayah Academy, in small classes and by video.' },
        { type: 'texte', texte: 'Applications are now made in the Rewayah Academy app, and your answers are already there. Create your account with the same e-mail address as in the form: your application will be found there automatically.' },
        { type: 'bouton', libelle: 'Create my account', href: `${APP}/#/connexion?mode=creer&candidature=1${codeCandidat(d)}` },
        { type: 'texte', texte: 'Nothing to pay: applying and creating an account are free. No applicant pays, at any stage, and the academy will never ask you for money.' },
        { type: 'note', texte: 'We will never ask you for a password or a payment by message. The link leads to our official address, app.rewayahacademy.com. If you did not fill in this form, ignore this message.' },
      ],
    }
  },
  message_libre: (d) => libre(d, PAROLE.sujetLibre),
  nouvelles: (d) => libre(d, PAROLE.sujetLibre),
}

export const ANGLAIS: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'Stop receiving these e-mails',
}
