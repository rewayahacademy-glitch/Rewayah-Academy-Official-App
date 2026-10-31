# Parcours 1 : pièges (personne pressée, non technique)

Règle (`METHODE-2026-11-01.md`, « Les usages non prévus ») : si l'application laisse faire une
erreur sans un mot clair et sans un moyen de revenir, le parcours est rouge. On ne reproche jamais
l'erreur à la personne : c'est l'écran qui l'a permise. Familles de pièges : (1) mauvais choix,
(2) détour, (3) saisie libre, (4) arrêt en cours de route, (5) lecture, (6) mauvais appareil.

Script : `tool/e2e/pieges_1.mjs`. Colonne « Joué » : oui / non ; « Résultat » : vert (l'écran
guide ou rattrape), rouge (renvoi au constat), ou « non joué » avec la raison.

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 1.1 | Direction › Invitations | 3 | Adresse collée avec majuscules et espaces autour (`  E2E-Maj@Example.COM `) ; la candidate s'inscrit ensuite en minuscules | oui | vert : invitation « flt-semantics:Invitation créée. Transmettez ce code à l'enseignant : 4F28-VW8W-8ZPJ » ; code verifie avec l'adresse en minuscules : « flt-semantics:Invitation valide jusqu'au Samedi 14 novembre. » |
| 1.2 | Direction › Invitations | 1 | Inviter une adresse qui a déjà un compte (celle de la direction de test) | oui | vert : « flt-semantics:Un compte existe déjà pour cette adresse : aucune invitation n'est nécessaire. » |
| 1.3 | Direction › Invitations | 2 | Double clic sur « Créer l'invitation » | oui | vert : 1 invitation(s) en base ; message « flt-semantics:Invitation créée. Transmettez ce code à l'enseignant : G2VB-FRVF-DC4T » |
| 1.4 | Candidate › Votre code | 3 | Code tapé en minuscules, avec espaces | oui | rouge : code en minuscules avec espaces : « flt-semantics:Code non reconnu. flt-semantics:Vérifiez le code, puis saisissez-le de nouveau. » → UX-015 |
| 1.5 | Candidate › Votre code | 3 | Code faux (une lettre changée) | oui | vert : code faux : « flt-semantics:Code non reconnu. flt-semantics:Vérifiez le code, puis saisissez-le de nouveau. » |
| 1.6 | Candidate › Votre code | 1 | Code reçu pour une adresse, compte créé avec une autre adresse | oui | vert : code d'une autre adresse : « flt-semantics:Code non reconnu. flt-semantics:Vérifiez le code, puis saisissez-le de nouveau. » |
| 1.7 | Candidate › retour du lien d'e-mail | 1 | Après le lien, elle choisit « Je m'inscris pour moi » (ce qu'elle croit être « moi, l'enseignante ») : peut-elle revenir à l'inscription enseignante ? | oui | rouge : joué en exploration (31/10 20:56 UTC) : apres le lien, « Je m'inscris pour moi » mene au parcours famille jusqu'a « Votre demande est en cours », sans rappel du code d'invitation ni retour vers l'inscription enseignante (UX-011) |
| 1.8 | Candidate › Identité | 2 | Rechargement de la page au milieu de l'identité : la saisie est-elle gardée, sait-elle où elle en est ? | oui | rouge : apres rechargement : http://127.0.0.1:8090/#/inscription/usage ; prenom vide ; ecran : flt-semantics:Étape 1 sur 4 / flt-semantics:Pour qui créez-vous ce compte ? / flt-semantics:Vous êtes enseignant ? L'académie vous invite par courriel. → UX-016 |
| 1.9 | Candidate › Identité | 3 | Nom en arabe et prénom très long (80 caractères) | oui | vert : prenom de 76 caracteres et nom en arabe : acceptes |
| 1.10 | Candidate › Identité | 3 | Champs vides puis « Continuer » | oui | vert : « Continuer » a vide : « flt-semantics:Cette réponse est nécessaire pour continuer. » ; http://127.0.0.1:8090/#/inscription/identite |
| 1.11 | Candidate › Votre pièce | 1 | « Envoyer ma pièce » sans choisir le type de pièce ni la photo | non | non joué : le script a echoue : locator.click: Timeout 30000ms exceeded. Call log: [2m - waiting for getByRole('button', { name: /^Envoyer ma pièce$/ }).first()[22m [2m - locator resolved to <flt-semantics role="button" aria-disabled="true" id=" |
| 1.12 | Candidate › Votre pièce | 3 | Un fichier qui n'est pas une image (PDF de test) | oui | rouge : un PDF qui n'est pas une image est accepte comme piece d'identite → FN-002 |
| 1.13 | Candidate › Nos conditions | 3 | Nom complet de signature différent du nom du compte | oui | rouge : signature « Quelqu'un d'autre » acceptee sans un mot (nom du compte : E2E Candidate Pieges) → FN-003 |
| 1.14 | Candidate | 4 | Elle ferme, revient « le lendemain » sur un autre appareil (nouveau navigateur, connexion par lien) : voit-elle où en est son dossier ? | oui | vert : autre appareil, le lendemain : « flt-semantics:Votre dossier » |
| 1.15 | Candidate | 2 | Ouvre une seconde fois le même lien d'e-mail (déjà utilisé) | oui | rouge : lien deja utilise, ouvert de nouveau : http://127.0.0.1:8090/?error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired&sb= ; flt-semantics:Le lien est peut-être incomplet, ou la page n'existe plus. / button:Se connecter → UX-017 |
| 1.16 | Direction › dossier | 1 | « Valider le dossier » sans avoir coché les trois cases | oui | vert : « flt-semantics:Ce dossier n'est pas encore prêt à être validé. » |
| 1.17 | Direction › dossier | 1 | Cocher les cases sans ouvrir « Voir la pièce » | oui | vert : cases inactives tant que la piece n'a pas ete ouverte |
| 1.18 | Direction › dossier | 2 | Double clic sur « Valider le dossier » | non | non joué : le script a echoue : locator.click: Timeout 30000ms exceeded. Call log: [2m - waiting for getByRole('checkbox', { name: /^La pièce est lisible/ }).first()[22m [2m - locator resolved to <flt-semantics role="checkbox" disabled="true" ar |
| 1.19 | Direction › dossier | 1 | « Refuser le dossier » par erreur au lieu de valider : peut-elle revenir ? | non | non joué : refuser exige un motif et retire l'acces : a jouer sur un dossier dedie |
| 1.20 | Tous les écrans du parcours | 5 | Lecture des libellés par un nouveau venu (mots internes, codes, sigles) | non | non joué : lecture faite sur les captures, voir le bilan |
| 1.21 | Candidate | 6 | Tout le parcours candidate au téléphone (390 px) | non | non joué : parcours candidate au telephone : a jouer |
| 1.22 | Direction › Dossiers à valider | 6 | La direction au téléphone (390 px) | non | non joué : direction au telephone : a jouer |
