// Les e-mails de Supabase Auth (lien de connexion, confirmation, invitation,
// changement d'adresse, nouveau mot de passe, reauthentification), composes
// avec le meme gabarit que la file (COURRIELS-1). Supabase les envoie lui-meme
// par le SMTP du projet (Workspace, support@) : on lui donne seulement le HTML.
// Les fichiers `supabase/templates/*.html` sont ecrits par
// `supabase/templates/generer.ts` ; `auth_modeles_test.ts` verifie qu'ils sont a jour.

import { type Contenu, composer } from './gabarit.ts'

const RAISON = 'Vous recevez cet e-mail parce qu’une demande a été faite avec cette adresse sur Rewayah Academy. Si ce n’est pas vous, ignorez-le : rien ne change sans ce lien.'

function lien(sujet: string, titre: string, phrase: string, bouton: string, note: string): Contenu {
  return {
    sujet, apercu: phrase, titre, raison: RAISON,
    blocs: [
      { type: 'texte', texte: 'Bonjour,' },
      { type: 'texte', texte: phrase },
      { type: 'bouton', libelle: bouton, href: '{{ .ConfirmationURL }}' },
      { type: 'note', texte: note },
      { type: 'note', texte: 'Le bouton ne fonctionne pas ? Copiez ce lien dans votre navigateur :\n{{ .ConfirmationURL }}' },
    ],
  }
}

export const MODELES_AUTH: Record<string, Contenu> = {
  magic_link: lien('Votre lien de connexion à Rewayah Academy', 'Votre lien de connexion',
    'Voici votre lien pour vous connecter à Rewayah Academy.', 'Me connecter',
    'Le lien est valable une heure et ne sert qu’une fois.'),
  confirmation: lien('Confirmez votre adresse e-mail', 'Confirmez votre adresse e-mail',
    'Pour terminer votre inscription à Rewayah Academy, confirmez votre adresse e-mail.', 'Confirmer mon adresse',
    'Le lien est valable une heure.'),
  invite: lien('Votre accès à Rewayah Academy', 'Votre accès est prêt',
    'La direction de Rewayah Academy a préparé votre accès. Ouvrez-le pour choisir comment vous connecter.',
    'Ouvrir mon accès', 'Le lien est valable une heure et ne sert qu’une fois.'),
  recovery: lien('Choisir un nouveau mot de passe', 'Choisir un nouveau mot de passe',
    'Une demande de nouveau mot de passe a été faite pour votre compte.', 'Choisir mon mot de passe',
    'Le lien est valable une heure. Votre mot de passe actuel reste valable tant que vous ne l’avez pas changé.'),
  email_change: lien('Confirmez votre nouvelle adresse e-mail', 'Confirmez votre nouvelle adresse',
    'Vous avez demandé à remplacer l’adresse de votre compte par {{ .NewEmail }}.', 'Confirmer le changement',
    'Tant que le changement n’est pas confirmé, votre adresse actuelle reste celle du compte.'),
  reauthentication: {
    sujet: 'Votre code de vérification', apercu: 'Le code à saisir pour confirmer votre action.',
    titre: 'Votre code de vérification', raison: RAISON,
    blocs: [
      { type: 'texte', texte: 'Bonjour,' },
      { type: 'texte', texte: 'Saisissez ce code dans l’application pour confirmer votre action :' },
      { type: 'code', code: '{{ .Token }}' },
      { type: 'note', texte: 'Le code est valable une heure. Ne le communiquez à personne : la direction ne vous le demandera jamais.' },
    ],
  },
}

export function htmlAuth(nom: string): string {
  return composer(MODELES_AUTH[nom]).html
}
