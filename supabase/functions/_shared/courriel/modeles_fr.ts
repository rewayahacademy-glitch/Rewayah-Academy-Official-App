// Les textes des e-mails en francais, un par modele de la file (COURRIELS-1).
// Le francais est la langue de reference : les autres langues en suivent le sens.
//
// Vocabulaire : competence `mots-rewayah` (classe, la direction, ferme et
// bienveillant, jamais « paiement confirme » sans preuve). Un e-mail ne porte
// jamais de detail sensible : il dit qu'il y a du nouveau et ouvre
// l'application, ou l'information vit derriere la connexion.

import { APP } from './gabarit.ts'
import { avisDans, bonjour, dateLongue, type Donnees, type Fabrique, type LangueEcrite, libre, PAROLE_FR } from './outils.ts'

export const RAISON: Record<string, string> = {
  compte: 'Vous recevez cet e-mail parce qu’il concerne votre compte Rewayah Academy.',
  inscription: 'Vous recevez cet e-mail parce qu’il concerne une demande faite sur Rewayah Academy.',
  classes: 'Vous recevez cet e-mail parce qu’il concerne une classe que vous suivez ou enseignez.',
  facturation: 'Vous recevez cet e-mail parce qu’il concerne la facturation de votre foyer.',
  recrutement: 'Vous recevez cet e-mail parce que vous êtes en relation avec notre recrutement.',
  direction: 'Vous recevez cet e-mail de la direction de Rewayah Academy.',
  nouvelles: 'Vous recevez cet e-mail parce que vous suivez les nouvelles de Rewayah Academy.',
}

const avis = avisDans(PAROLE_FR)

/// L'heure locale d'une seance telle que le serveur la pose dans les
/// notifications des classes (`debut_local`, « AAAA-MM-JJTHH:MM:SS », deja
/// dans le fuseau de la personne, migration 20261027120000) : « 6 novembre
/// 2026 a 18:00 » ; `null` quand elle manque. Le jour vient de `dateLongue`,
/// l'heure est lue telle quelle (elle est deja locale, aucun fuseau a appliquer).
export function quandSeance(d: Donnees, locale = 'fr-FR', a = 'à'): string | null {
  const v = d.debut_local
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(v)) return null
  const jour = dateLongue(v.slice(0, 10), locale)
  return jour ? `${jour} ${a} ${v.slice(11, 16)}` : null
}

export const MODELES: Record<string, Fabrique> = {
  demande_recue: (d) => avis(d, 'Votre demande est bien reçue', 'Votre demande est bien reçue',
    'Nous avons reçu votre demande de créneau. La direction l’étudie et vous répond dans l’application.',
    'Suivre ma demande', '/tuteur/demandes'),
  // Admission, lot B (decision du directeur du 27/10/2026, regle 4) : la
  // demande d'acces d'une famille ou d'un eleve adulte, a son inscription.
  admission_recue: (d) => avis(d, 'Votre demande est bien reçue', 'Votre demande est en cours',
    'Nous avons bien reçu votre demande. La direction lit chaque demande avant d’ouvrir un compte. Vous n’avez rien à envoyer : nous vous écrivons à cette adresse dès que la direction a répondu.',
    'Voir ma demande', '/attente'),
  demande_presentation: (d) => avis(d, 'Une demande de présentation est reçue', 'Demande de présentation reçue',
    'Une demande de présentation a été reçue. Elle vous attend dans l’application.',
    'Ouvrir la demande', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'Votre classe est prête', 'Votre classe est prête',
    'La classe correspondant à votre demande est prête. Il reste à lui affecter son enseignant ; vous serez prévenu.',
    'Voir la classe', '/tuteur/demandes'),
  enseignant_affecte: (d) => avis(d, 'Un enseignant est affecté à la classe', 'Votre enseignant est connu',
    'Un enseignant a été affecté à la classe. Vous retrouvez son nom et les horaires dans l’application.',
    'Voir la classe', '/tuteur/demandes'),
  demande_close: (d) => avis(d, 'Votre demande est clôturée', 'Votre demande est clôturée',
    'Votre demande de créneau a été clôturée. La réponse de la direction est dans l’application.',
    'Lire la réponse', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'Changement de classe, même horaire', 'Changement de classe',
    'Un élève de votre foyer a rejoint une autre classe, au même horaire.',
    'Voir le détail', '/tuteur/demandes'),
  // Fiche « Fraicheur et notifications » (27/10/2026), ligne 15 : les neuf
  // evenements des classes et des seances (migration 20261027120000). Le
  // lien reel vient de `destination` (accueil de l'eleve, classe ou planning
  // du tuteur, classes ou journee de l'enseignant) ; le repli suit le
  // destinataire que l'evenement vise d'abord.
  classe_creee: (d) => avis(d, 'Votre classe est créée', 'Votre classe est créée',
    'Une classe vient d’être créée. Son horaire et son enseignant sont dans l’application.',
    'Voir l’horaire', '/tuteur'),
  enseignant_change: (d) => avis(d, 'L’enseignant de la classe change', 'L’enseignant de la classe change',
    'Un autre enseignant prend la classe, au même horaire. Son nom est dans l’application.',
    'Voir la classe', '/tuteur'),
  eleve_inscrit: (d) => avis(d, 'Un élève rejoint votre classe', 'Un élève rejoint votre classe',
    'Un élève rejoint votre classe. Sa fiche est dans l’application.',
    'Voir mes classes', '/enseignant/classes'),
  eleve_retire: (d) => avis(d, 'Un élève quitte votre classe', 'Un élève quitte votre classe',
    'Un élève quitte votre classe. La liste à jour est dans l’application.',
    'Voir mes classes', '/enseignant/classes'),
  creneau_change: (d) => avis(d, 'L’horaire de la classe change', 'L’horaire de la classe change',
    'L’horaire de la classe change. Le nouvel horaire est dans l’application.',
    'Voir le nouvel horaire', '/tuteur'),
  seance_annulee: (d) => {
    const quand = quandSeance(d)
    return avis(d, 'Une séance est annulée', 'Une séance est annulée',
      quand ? `La séance du ${quand} est annulée.` : 'Une séance de la classe est annulée.',
      'Voir le planning', '/tuteur')
  },
  seance_deplacee: (d) => {
    const quand = quandSeance(d)
    return avis(d, 'Une séance est déplacée', 'Une séance est déplacée',
      quand ? `Une séance est déplacée au ${quand}.` : 'Une séance de la classe est déplacée. Le nouvel horaire est dans l’application.',
      'Voir le nouvel horaire', '/tuteur')
  },
  enseignante_absente: (d) => {
    const quand = quandSeance(d)
    return avis(d, 'L’enseignant est absent pour une séance', 'L’enseignant est absent pour une séance',
      (quand ? `L’enseignant est absent pour la séance du ${quand}.` : 'L’enseignant est absent pour une séance de la classe.')
        + ' La direction vous tient informé.',
      'Voir le planning', '/tuteur')
  },
  classe_supprimee: (d) => avis(d, 'La classe est fermée', 'La classe est fermée',
    'La classe est fermée. La direction vous contacte pour la suite.',
    'Ouvrir l’application', '/tuteur'),
  remplacement_propose: (d) => avis(d, 'Un remplacement vous est proposé', 'Un remplacement vous est proposé',
    'Un remplacement de cours vous est proposé. Répondez dans l’application pour que la classe soit assurée.',
    'Voir le remplacement', '/enseignant/journee/remplacements'),
  remplacement_pris: (d) => avis(d, 'Le remplacement est attribué', 'Le remplacement est attribué',
    'Le remplacement de cours a été attribué.',
    'Voir ma journée', '/enseignant/journee/remplacements'),
  controle_mission_attribuee: (d) => avis(d, 'Une mission de contrôle vous est attribuée', 'Nouvelle mission de contrôle',
    'Une mission de contrôle vous a été attribuée.', 'Ouvrir la mission', '/controleur'),
  controle_mission_non_controlee: (d) => avis(d, 'Une mission est restée sans vérification', 'Mission sans vérification',
    'Une mission de contrôle est restée sans vérification.', 'Voir les tirages', '/admin/securite-audit/tirages'),
  paiement_relance: (d) => {
    const j = typeof d.jours_avant === 'number' ? d.jours_avant : null
    const quand = j === null ? 'bientôt' : j === 0 ? 'aujourd’hui' : j === 1 ? 'demain' : `dans ${j} jours`
    return avis(d, `Un paiement arrive à échéance ${quand}`, 'Un paiement arrive à échéance',
      `Le paiement du mois arrive à échéance ${quand}. Il se règle dans l’application, rubrique Paiements, pour que les cours continuent sans interruption.`,
      'Régler le paiement', '/tuteur/foyer/recharge')
  },
  acces_suspendu_paiement: (d) => avis(d, 'Un accès est suspendu', 'Un accès est suspendu',
    'Le paiement du mois n’est pas reçu : l’accès à la classe est suspendu. Il revient dès que le paiement est reçu.',
    'Régler le paiement', '/tuteur/foyer/recharge'),
  acces_retabli_paiement: (d) => avis(d, 'L’accès est rétabli', 'L’accès est rétabli',
    'Le paiement est reçu : l’accès à la classe est rétabli.', 'Ouvrir l’application', '/tuteur/foyer/recharge'),
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'Un membre de votre famille'
    const fin = dateLongue(d.expire_le)
    return {
      sujet: `${qui} vous invite à rejoindre son foyer sur Rewayah Academy`,
      apercu: `${qui} vous invite à suivre les cours de la famille avec lui.`,
      titre: 'Vous êtes invité à rejoindre un foyer',
      blocs: [
        { type: 'texte', texte: 'Bonjour,' },
        { type: 'texte', texte: `${qui} vous invite à rejoindre son foyer sur Rewayah Academy, pour suivre ensemble les cours de la famille.` },
        { type: 'texte', texte: 'Connectez-vous avec cette adresse e-mail : l’invitation vous attend dans l’application.' },
        { type: 'bouton', libelle: 'Ouvrir l’invitation', href: `${APP}/connexion` },
        { type: 'note', texte: (fin ? `L’invitation est valable jusqu’au ${fin}. ` : '') + 'Si vous ne connaissez pas cette personne, ignorez ce message.' },
      ],
    }
  },
  // Candidats inscrits aux formulaires Google, prevenus de creer leur compte
  // (DECISION-CANDIDATURES-2026-10-21.md, « Le message qui previent les inscrits
  // des formulaires Google », regles 1 a 8). Donnees : `date_reponse` (horodatage
  // importe, ISO), `formulaire` (nom du formulaire), `prenom` facultatif. Aucune
  // reponse du formulaire n'entre dans le message.
  lien_inscription: (d) => {
    const quand = dateLongue(d.date_reponse)
    const nom = typeof d.formulaire === 'string' && d.formulaire.trim() ? ` « ${d.formulaire.trim()} »` : ''
    const rappel = `${quand ? `Le ${quand}, vous` : 'Vous'} avez répondu à notre formulaire${nom}.`
    return {
      sujet: 'Votre candidature à Rewayah Academy : créez votre compte',
      apercu: rappel,
      titre: 'Votre candidature continue dans l’application',
      blocs: [
        { type: 'texte', texte: bonjour(d) },
        { type: 'texte', texte: rappel },
        { type: 'texte', texte: 'Ce formulaire servait à proposer votre candidature pour enseigner le Coran à Rewayah Academy, en petite classe et en visio.' },
        { type: 'texte', texte: 'Les candidatures se font désormais dans l’application Rewayah Academy, et vos réponses y sont déjà. Créez votre compte avec la même adresse e-mail que dans le formulaire : votre candidature s’y retrouvera d’elle-même.' },
        { type: 'bouton', libelle: 'Créer mon compte', href: `${APP}/inscription` },
        { type: 'texte', texte: 'Rien à payer : postuler et créer son compte sont gratuits. Aucun candidat ne paie, à aucune étape, et l’académie ne vous demandera jamais d’argent.' },
        { type: 'note', texte: 'Nous ne vous demanderons jamais de mot de passe ni de paiement par message. Le lien mène à notre adresse officielle, app.rewayahacademy.com. Si vous n’avez pas rempli ce formulaire, ignorez ce message.' },
      ],
    }
  },
  // B3.1 (Boucle 3) : les candidats des formulaires Google, prevenus de ce qui
  // va se passer. Texte valide par le directeur le 24/10/2026, mot pour mot :
  // docs/current/CANDIDATURES/COURRIEL_ATTENTE_2026-10-24.md. Ecrit une seule
  // fois, en francais : chaque candidat le recoit traduit dans sa langue a
  // l'envoi (traduction.ts), jamais trois langues dans un message. Categorie
  // `recrutement`, non essentielle : lien de desinscription en un clic.
  attente_candidat: () => {
    const sujet = 'Votre candidature pour enseigner à Rewayah Academy : où nous en sommes'
    const accroche = 'Vous avez rempli notre formulaire pour enseigner le Coran à Rewayah Academy. Nous vous remercions de votre confiance et nous vous devons une réponse claire.'
    return {
      sujet,
      apercu: accroche,
      titre: sujet,
      // Lettre personnelle (pilote, 25/10/2026) : jamais « Promotions ».
      lettre: true,
      blocs: [
        { type: 'texte', texte: 'Assalamou alaykoum wa rahmatoullah,' },
        { type: 'texte', texte: accroche },
        { type: 'texte', texte: 'Vous êtes près de six cents à avoir répondu. Nous lisons chaque candidature une par une, et nous n’ouvrons les classes qu’avec des enseignants que nous avons rencontrés. Cela prend du temps, et nous préférons le prendre plutôt que de mal faire.' },
        { type: 'texte', texte: 'Ce qui va se passer :' },
        { type: 'texte', texte: '1. D’ici trois semaines, vous recevrez un courriel personnel de notre part, dans tous les cas.\n' +
          '2. Si votre profil correspond à nos besoins du moment, ce courriel contiendra une invitation à créer votre compte dans l’application Rewayah, puis un entretien en visio avec la direction.\n' +
          '3. Si ce n’est pas le cas pour l’instant, nous vous le dirons aussi, et nous garderons votre candidature pour les prochaines ouvertures, sauf si vous préférez qu’on l’efface.' },
        { type: 'texte', texte: 'Il n’y a rien à payer, ni aujourd’hui ni plus tard : enseigner à Rewayah Academy est un travail rémunéré, jamais une formation payante.' },
        { type: 'texte', texte: 'Vous n’avez rien à faire aujourd’hui. Inutile de nous écrire pour demander où en est votre dossier : c’est nous qui reviendrons vers vous, à cette adresse.' },
        { type: 'texte', texte: 'Si vous ne souhaitez plus enseigner avec nous, un clic sur le lien en bas de ce message suffit, sans justification.' },
        { type: 'texte', texte: 'Qu’Allah vous récompense pour votre démarche.' },
        { type: 'texte', texte: 'La direction\nRewayah Academy' },
      ],
    }
  },
  message_libre: (d) => libre(d),
  nouvelles: (d) => libre(d),
}

/// Les modeles ecrits en francais et traduits a l'envoi vers la langue du
/// destinataire (decision du directeur, 24/10/2026), sauf vers une langue qui
/// les ecrit a la main : `attente_candidat` est ecrit en arabe (pilote,
/// 25/10/2026), traduit vers en, es, pt et les autres ; `admission_recue`
/// (lot B de l'admission, 29/10/2026), ecrit en francais et en arabe.
export const TRADUITS_A_L_ENVOI: readonly string[] = ['attente_candidat', 'admission_recue']

export const FRANCAIS: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'Ne plus recevoir ces e-mails',
}
