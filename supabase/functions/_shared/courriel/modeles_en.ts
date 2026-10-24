// Les e-mails en anglais, ecrits a la main. Ils suivent le sens du francais
// (`modeles_fr.ts`) ; memes liens, memes boutons. Competence `mots-rewayah`.

import { APP } from './gabarit.ts'
import { avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole } from './outils.ts'

const PAROLE: Parole = {
  salut: 'Hello',
  fin: ',',
  salutSeul: 'Hello,',
  note: 'The details are in the app, once you are signed in.',
  sujetLibre: 'A message from Rewayah Academy',
  locale: 'en-GB',
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
  enseignant_affecte: (d) => avis(d, 'A teacher has been assigned to the class', 'Your class has a teacher',
    'A teacher has been assigned to the class. You will find their name and the schedule in the app.',
    'View the class', '/tuteur/demandes'),
  demande_close: (d) => avis(d, 'Your request has been closed', 'Your request has been closed',
    'Your time slot request has been closed. The management’s reply is in the app.',
    'Read the reply', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'Class change, same schedule', 'Class change',
    'A student in your household has joined another class, at the same time.',
    'View the details', '/tuteur/demandes'),
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
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'A member of your family'
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} invites you to join their household on Rewayah Academy`,
      apercu: `${qui} invites you to follow the family’s classes with them.`,
      titre: 'You are invited to join a household',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} invites you to join their household on Rewayah Academy, to follow the family’s classes together.` },
        { type: 'texte', texte: 'Sign in with this e-mail address: the invitation is waiting for you in the app.' },
        { type: 'bouton', libelle: 'Open the invitation', href: `${APP}/connexion` },
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
        { type: 'bouton', libelle: 'Create my account', href: `${APP}/inscription` },
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
