# C03 - Admission : auth visuelle et onboarding (cartographie, lecture seule)

Date : 24/09/2026. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, checkout `c0/configuration-baseline-2026-09-23` (HEAD `3cf3544`, identique à `main` `4a7aa2b` pour tout le code `lib/` et `supabase/` cité ici). Aucune écriture dans le dépôt, aucun test lancé, aucune base interrogée. Le statut « appliqué en production » des migrations est repris de `docs/current/CONFIGURATION_BASELINE_2026-09-23.md` (inventaire `list_migrations` du 23/09), pas revérifié.

Légende des statuts : **FAIT** = ce que le code exécute ; **DIT** = ce qu'un commentaire ou un document affirme ; **ABSENT** = rien dans le code.

---

## 0. Synthèse (ce qu'il faut retenir)

1. **L'admission réelle se fait en trois tunnels séparés, dans cet ordre imposé par le routeur et la base** : (a) `/connexion` (lien courriel ou Google), (b) `/inscription` (4 pages, crée le titulaire), (c) `/attente` (accusé, contrat, pièce d'identité, puis validation humaine). **Le questionnaire pédagogique (`/tuteur/parcours/:eleveId`, 7 pages) n'est atteignable qu'après validation du dossier ET ajout d'un enfant**, alors que son backend (`0043`) a été conçu pour un foyer `pending_kyc` (contradiction §9).
2. **Le questionnaire pédagogique est inerte en production** : il appelle des RPC de `0043_offres_horaires_et_intentions.sql`, migration **non appliquée** (`CONFIGURATION_BASELINE:129`, `08:79`, `FABLE_BACKEND_CONTRACT...md:8-10`). Le bloc d'accueil qui y mène se tait en cas d'erreur (`bloc_parcours.dart:46-48`) : en prod, il est donc invisible.
3. **Aucun choix « Moi uniquement / Moi et ma famille »** n'existe. La première page d'inscription propose trois cartes : « Parent ou tuteur », « Élève adulte, pour moi-même », « Enseignant » (`fr.i18n.json:159-162`, `inscription_page.dart:138-155`). **Inscription enseignant : oui**, même tunnel.
4. **« Élève adulte, pour moi-même » est cassé de bout en bout** : il crée le même profil `guardian` que « Parent » (`inscription_page.dart:38-41`), sans aucune fiche élève ; rien dans le dépôt ne crée jamais une fiche `student_profiles` `autonomous` pour soi (seules les données de test SQL en contiennent). L'adulte arrive sur un accueil qui lui dit « Aucun enfant dans le foyer » (`accueil_famille_page.dart:239-246`).
5. **Le parent n'est pas forcé d'avoir un profil élève**, et **il ne peut pas en créer un plus tard** : un compte = un profil = un rôle (`0004:375-378`, `profiles.role` unique, rôle porté par le JWT). « Créer mon profil élève » : ABSENT (ni route, ni RPC). Dépendance backend lourde (§11, D1).
6. **Ajout d'un 2e enfant** : même écran que le 1er, `/tuteur/foyer/ajouter-enfant` (prénom, nom, âge 3-18), via la fonction Edge `creer-profil-enfant`, **réservé aux comptes validés** (`0004:856-858`). Pas de choix « pour moi / pour un proche », l'élève créé est toujours `minor` (`0004:892-893`).
7. **Consentement d'observation parentale : ABSENT** partout (dépôt et branche `observation/lot-2026-09-21`). Le seul mécanisme de consentement est `contract_acceptances` (3 sortes figées par un `CHECK`, `0004:224-228`). **Aucun mécanisme de remise à jour pour les comptes existants** : `etat_dossier()` teste l'existence d'une acceptation sans regarder la version (`0004:459-470`) et un compte actif ne peut plus entrer dans `/attente` (`redirection.dart:81-87`). Le commentaire de `versions_contrat.dart:3-9` affirme le contraire.
8. **Le texte signé aujourd'hui est faux** : l'accusé et le contrat font accepter « Chaque cours est enregistré en audio, conservé trente jours » (`fr.i18n.json:180`, `signature_page.dart:39,60`) alors qu'aucun enregistrement n'existe (`CLAUDE.md` racine, `06:32-33`). Corrigé sur `v0/verite-produit` sans changer la version.
9. **Mot de passe : aucun en production** (lien à usage unique ou Google, `service_auth.dart:12-14`). « Récupérer mon accès » = redemander un lien ; **lien expiré : non géré** (aucun traitement d'erreur de retour d'URL) ; **retour natif mobile non configuré** (aucun schéma de lien profond Android/iOS, alors que `service_auth.dart:46-48` le suppose).
10. **Écrans à bannir selon le mandat** (« beaucoup de CTA, rectangles les uns sur les autres ») : ce sont exactement `/attente` (carte > tuile > bouton plein, jusqu'à 3 CTA pleins, `attente_page.dart:113-126,158-170`), `/attente/accuse|contrat` (carte > tuiles par point, `signature_page.dart:155-185`) et `/attente/piece` (2 boutons empilés, `depot_piece_page.dart:115-144`).

---

## 1. Carte des fichiers du domaine

| Fichier | Rôle réel | Branché |
|---|---|---|
| `lib/features/connexion/connexion_page.dart` | `TUT-00` connexion : lien courriel, Google, entrée appareil élève | `/connexion` (`app_router.dart:112-115`) |
| `lib/features/connexion/feuille_appareil_eleve.dart` | feuille explicative vers `/connexion/eleve` | depuis `connexion_page.dart:165-170` |
| `lib/core/auth/service_auth.dart` | `signInWithOtp`, `signInWithOAuth(google)`, `signInWithPassword` (démo), `signOut` | oui |
| `lib/core/session/{session_state,source_session,session_controleur,claims_jwt}.dart` | portes d'accès (`PorteAcces`), lecture `profiles`, mode démo | oui |
| `lib/features/inscription/inscription_page.dart` | `TUT-00c` : rôle, identité, genre, récapitulatif | `/inscription` (`app_router.dart:121-124`) |
| `lib/core/dossier/service_dossier.dart` | `creer_profil_inscription`, `etat_dossier`, insert `contract_acceptances`, dépôt pièce | oui |
| `lib/core/dossier/etat_dossier.dart` | miroir de `etat_dossier()`, calcul des manquants | oui |
| `lib/core/dossier/versions_contrat.dart` | version signée `'2026-09'` | oui |
| `lib/core/dossier/service_validation.dart`, `selecteur_fichier.dart` | validation admin, sélection fichier | admin / dépôt |
| `lib/features/dossier/attente_page.dart` | `TUT-00b` portail d'attente (4 états) | `/attente` (`app_router.dart:134-137`) |
| `lib/features/dossier/signature_page.dart` | `AccusePage` + `ContratPage` | `/attente/accuse`, `/attente/contrat` (`app_router.dart:138-145`) |
| `lib/features/dossier/depot_piece_page.dart` | dépôt pièce d'identité | `/attente/piece` (`app_router.dart:146-149`) |
| `lib/core/profil/service_acceptations.dart` | lecture des acceptations signées | utilisé seulement par `profil_enseignant_page.dart:511` |
| `lib/core/profil/service_declaration.dart`, `service_profil_enseignant.dart` | profil enseignant | hors tuteur |
| `lib/features/appareils/ajouter_enfant_page.dart` | ajout d'un élève au foyer | `/tuteur/foyer/ajouter-enfant` (`app_router.dart:282-285`) |
| `lib/core/appairage/service_appairage.dart:241-259` | appel Edge `creer-profil-enfant` | oui |
| `lib/features/parcours_offres/parcours_offres_page.dart` | 6 questions + horaires vitrines | `/tuteur/parcours/:eleveId` (`app_router.dart:294-298`) |
| `lib/features/parcours_offres/bloc_parcours.dart` | bloc d'état à l'accueil tuteur | `accueil_famille_page.dart:236` |
| `lib/features/parcours_offres/libelles_parcours.dart` | moments, fuseaux proposés, libellés | oui |
| `lib/core/offres/{offre_horaire,service_offres}.dart` | modèle + 9 appels serveur `0043` | oui (backend non appliqué) |
| `lib/features/bienvenue_enseignant/bienvenue_page.dart` | `ENS-01`, **enseignant validé**, pas une page publique | route `/enseignant/bienvenue` **orpheline** : aucun appel à `Routes.enseignantBienvenue` hors `routes.dart:133` et `app_router.dart:348` |
| `lib/features/agent_entree/agent_entree_page.dart` | `AGT-00` entrée d'un agent IA par jeton (ADR-025) | `/agent`, publique. **Sans rapport avec l'admission humaine** |
| `lib/features/_dev/playground/persona.dart:220-260` | personas « visiteur », « compte sans profil », « famille dossier incomplet / en vérification » | outil de dev (`PLAYGROUND`), pas de faux `ServiceOffres` |

Confusions de nom à éviter : `bienvenue_enseignant` ≠ route publique `/bienvenue` du mandat (qui **n'existe pas** : la racine `/` rend un écran de chargement puis redirige vers `/connexion`, `app_router.dart:107-111`, `redirection.dart:39-49`) ; `agent_entree` ≠ tuteur ; `features/parcours_offres` ≠ `core/tc_parcours` (travail Teaching Core).

---

## 2. Le parcours tel que le code l'enchaîne

Portes calculées dans `session_state.dart:133-172` à partir de la lecture `profiles` (`source_session.dart:77-124`) et appliquées par `redirection.dart:31-116`.

```
Visiteur (deconnecte) ──> /connexion  [seule zone publique avec /connexion/eleve et /agent]
   │ lien courriel (signInWithOtp) ou Google (signInWithOAuth)
   ▼
Session, aucune ligne profiles (LectureProfil.absente) ──> /inscription UNIQUEMENT (redirection.dart:55-58)
   │ RPC creer_profil_inscription -> profiles.account_status = 'pending_kyc' en dur (0004:405)
   │ puis refreshSession (inscription_page.dart:105)
   ▼
pending_kyc / lecture échouée / role absent ──> /attente/* UNIQUEMENT (redirection.dart:64-68, session_state.dart:151-169)
   │ accusé -> contrat -> pièce (ordre etat_dossier.dart:102-107), puis validation admin (ADM-02)
   ▼
active / provisional_active ──> /tuteur (racine guardian), /attente et /inscription deviennent inaccessibles (redirection.dart:81-87)
   │ Accueil : « Aucun enfant dans le foyer » -> /tuteur/foyer/ajouter-enfant (accueil_famille_page.dart:239-246)
   │ Edge creer-profil-enfant -> retour /tuteur/foyer (ajouter_enfant_page.dart:74), PAS vers le questionnaire
   ▼
Retour manuel à l'Accueil -> BlocParcours « Personnaliser le parcours » -> /tuteur/parcours/:eleveId
   │ 6 questions -> enregistrer_profil_apprentissage -> offres_compatibles -> choisir_offre_horaire
   ▼
Préférence enregistrée (aucune place, aucun groupe, aucun enseignant) -> retour /tuteur
```

Conséquences directes :
- Le questionnaire pédagogique ne s'ouvre **qu'après** validation KYC humaine et ajout d'un enfant. Un foyer en vérification ne peut ni ajouter d'enfant (`0004:856-858`) ni atteindre `/tuteur/*` (routeur).
- Il n'existe aucun récapitulatif global « titulaire + élèves + parcours » : deux récapitulatifs partiels (inscription page 4 ; aucun pour le parcours, dont la page 7 est la liste d'horaires).

---

## 3. Inventaire exact des questions

### 3.1 Connexion `/connexion` (`connexion_page.dart`, i18n `connexion` `fr.i18n.json:127-154`)

| Élément | Libellé exact | Comportement | Réf. |
|---|---|---|---|
| Titre | « Se connecter » | | `:264` |
| Intro | « Nous vous envoyons un lien par courriel. Aucun mot de passe à retenir, donc aucun à perdre. » | | `:266-271` |
| Champ | « Votre adresse électronique », indice « vous@exemple.com » | validation locale permissive `courrielPlausible` (`service_auth.dart:80-93`), erreur **sous le champ** « Cette adresse ne semble pas valide. » | `:273-283`, `:95-98` |
| CTA principal | « Recevoir le lien » | `signInWithOtp(email, emailRedirectTo: origine web)` | `:300-304`, `service_auth.dart:51-52` |
| Succès | « Lien envoyé » / « Ouvrez le message envoyé à {courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte. » ; seule action « Utiliser une autre adresse » | **pas de bouton « Renvoyer le lien »** | `:424-458` |
| Échec | « L'envoi n'a pas abouti. Réessayez dans un instant. » (tous motifs confondus, dont limitation de débit) | | `:108-111` |
| Secondaire | « Continuer avec Google » (logo) | `signInWithOAuth(google, redirectTo: origine web)` ; message brut du fournisseur affiché sur `AuthException` | `:326-333`, `:146-163` |
| Tertiaire | « Vous êtes tuteur et vous préparez l'appareil d'un élève ? » + « Connecter l'appareil d'un élève » | ouvre la feuille puis `/connexion/eleve` (domaine D) | `:341-356` |
| Démo | champ « Mot de passe de démonstration » si `DEMO_AUTH` ; `tuteur@…`, `eleve@…` etc. ouvrent un rôle **actif** sans Supabase | ne montre jamais `/inscription` ni `/attente` | `:284-298`, `session_controleur.dart:23-40,78-91` |

### 3.2 Inscription `/inscription` (`inscription_page.dart`, i18n `inscription` `fr.i18n.json:155-176`)

`PageParcours` : en-tête « Retour » (si fourni) + « Étape {n} sur {total} » + barre, CTA collé en bas, « Environ {minutes} min » (`page_parcours.dart:83-131`). Aucune donnée n'est écrite avant la page 4.

| Page | Question (libellé exact) | Réponses | Obligatoire / validation | Réf. |
|---|---|---|---|---|
| 1/4 (3 min) | « Vous inscrivez-vous comme parent ou comme enseignant ? » | « Parent ou tuteur » -> `guardian` ; « Élève adulte, pour moi-même » -> **`guardian` aussi** ; « Enseignant » -> `teacher` ; carte « Autre » (défaut `ChoiceCardGroup`, `choice_card_group.dart:61`) -> phrase « Écrivez à l'académie et nous créerons votre accès. Cette page ne peut pas le faire pour vous. », CTA inerte | oui ; CTA grisé tant que rien n'est choisi (aucun message) ; **pas de bouton Retour ni de déconnexion** | `:127-173`, `:38-46` |
| 2/4 (2 min) | « Comment vous appelez-vous ? » ; explication « Ce nom doit être celui de votre pièce d'identité. » | champs « Prénom », « Nom » (autofill) | les deux non vides (trim) ; CTA grisé, **aucune erreur sous champ** (clé `inscription.champRequis` inutilisée) ; **rien n'est prérempli** depuis Google/Supabase | `:175-206` |
| 3/4 (1 min) | « Vous êtes » ; explication « Cette réponse ne sert qu'à confier votre pièce d'identité à un membre du personnel du même genre. » | « Un homme » / « Une femme » ; « Autre » -> même impasse que page 1 | oui | `:208-243` |
| 4/4 | « Avant de continuer » (récapitulatif) | 3 lignes en lecture : rôle, nom complet, genre ; CTA « Créer mon compte » | pas de lien « Modifier » par ligne : correction = « Retour » page par page ; erreur « La création du compte n'a pas abouti. Réessayez dans un instant. » | `:245-283` |

Non demandés : téléphone, pays, fuseau (le foyer est créé en `Europe/Paris` par défaut, `0004:352,386-388`, le client n'envoie pas `p_timezone`, `service_dossier.dart:96-104`), langue, date de naissance, consentement (déplacé dans `/attente`).

### 3.3 Portail d'attente `/attente` (dossier)

État calculé en base par `etat_dossier()` (`0004:431-484`) : `incomplet`, `enVerification`, `refuse`, `suspendu` (`etat_dossier.dart:80-91`). Manquants dans l'ordre accusé -> contrat -> pièce (`etat_dossier.dart:102-107`).

| Écran | Titre et contenu exacts | Action | Stockage | Réf. |
|---|---|---|---|---|
| `/attente` incomplet | « Il manque encore des pièces à votre dossier. » / « À fournir » ; lignes « Ce que vous devez savoir » -> « Lire », « La signature du contrat » -> « Lire et signer », « Une pièce d'identité » -> « Déposer ma pièce » | un **bouton plein par ligne** dans une tuile dans une carte ; « Se déconnecter » en secondaire | - | `attente_page.dart:104-172`, `fr.i18n.json:106-126` |
| `/attente` en vérification | « Votre dossier est en cours de vérification » ; « Nous vérifions votre dossier. Vous recevrez une notification dès qu'il est validé. » ; « Déposé le {date} » ; « La vérification prend en général moins de 48 heures. » | aucune | - | `:81-90` |
| `/attente` refusé | « Votre dossier n'a pas été validé. » + motif serveur | « Reprendre mon dossier » -> `/attente/piece` | - | `:175-206` |
| `/attente` suspendu | « Votre compte est suspendu. » / « Vous pouvez joindre l'académie pour connaître la marche à suivre. » + « Contacter l'académie » en **texte simple, non actionnable** | aucune | - | `:92-98` |
| `/attente/accuse` | « À savoir avant de commencer » ; 2 points : `contrat.pointEnregistrement` + `contrat.pointControle` (texte §5) | « J'ai compris » | `contract_acceptances(recording_and_control_notice, '2026-09')` | `signature_page.dart:29-42` |
| `/attente/contrat` | « Ce que vous signez » ; intro « Deux points comptent plus que les autres… » ; mêmes 2 points (+ « Vous ne voyez jamais les coordonnées d'une famille… » si enseignant) | « J'ai lu et j'accepte » | `guardian_terms` ou `teacher_nda`, version `'2026-09'` | `signature_page.dart:46-70`, `fr.i18n.json:177-187` |
| `/attente/piece` | « Votre pièce d'identité » ; « Une photo lisible suffit. Elle est conservée le temps de la vérification, puis effacée. » ; « Quelle pièce déposez-vous ? » : Carte d'identité / Passeport / Titre de séjour / Autre (-> `other`) | « Choisir la photo » (secondaire) puis « Envoyer ma pièce » (principal), plafond 8 Mo vérifié avant envoi | upload bucket Supabase `kyc` (`<uid>/<ms>.<ext>`) + insert `kyc_documents` ; genre posé par déclencheur | `depot_piece_page.dart:39-186`, `service_dossier.dart:130-156` |

Remarques factuelles :
- Le texte intégral du contrat n'est **nulle part** : la clé « Lire le texte complet » (`fr.i18n.json:183`) n'est utilisée par aucun écran. On signe deux phrases.
- Le tuteur signe **deux fois les mêmes deux phrases** (accusé puis contrat).
- `ContratPage` prend `guardian` par défaut tant que l'état n'est pas chargé (`signature_page.dart:52-53`) et le bouton est actif tout de suite : sur un lien direct rechargé, un enseignant rapide peut écrire une ligne `guardian_terms` immuable.
- Le client dépose la pièce dans Supabase Storage `kyc`, pas par la fonction Edge `piece-identite-depot` (R2, présente dans `supabase/functions/`) : aucun appel à `piece-identite` dans `lib/`.

### 3.4 Ajout d'un élève `/tuteur/foyer/ajouter-enfant` (`ajouter_enfant_page.dart`, i18n `enfant` `fr.i18n.json:223-234`)

Une page `PageParcours` « Étape 1 sur 1 ».

| Élément | Libellé exact | Validation | Réf. |
|---|---|---|---|
| Titre | « Ajouter un enfant » ; explication « L'âge fixe le mode d'affichage et la politique caméra. Vous pourrez changer les deux à tout moment. » | | `:89-94` |
| Champs | « Son prénom », « Son nom », « Son âge » (clavier numérique) | prénom et nom non vides ; âge entier **3 à 18** (constante client), erreur sous le champ « Indiquez un âge entre 3 et 18 ans. » | `:42-53`, `:111-135` |
| CTA | « Ajouter au foyer » ; échec « L'ajout n'a pas abouti. Réessayez dans un instant. » | | `:95`, `:76-79` |
| Sortie | « Retour » -> `/tuteur/foyer` ; succès -> `/tuteur/foyer` | | `:96`, `:74` |

Serveur : Edge `creer-profil-enfant` crée un utilisateur auth `eleve-<uuid>@<STUDENT_EMAIL_DOMAIN>` puis `creer_profil_enfant()` (`creer-profil-enfant/index.ts:49-69`) : tuteur `active|provisional_active` exigé, âge 3-99, `student_type = 'minor'` en dur, `interface_mode` par `child_ui_mode_max_age`, caméra par `camera_auto_allow_min_age`, statut hérité du tuteur (`0004:846-893`). Le paramètre `niveau` du service n'est jamais fourni par l'écran.

Entrées vers cet écran : Accueil vide (`accueil_famille_page.dart:245`), Foyer (`appareils_page.dart:68,93`), Compte > Profils du foyer (`compte_page.dart:389-390`), Réglages par enfant (`reglages_enfant_page.dart:84`).

### 3.5 Questionnaire pédagogique `/tuteur/parcours/:eleveId` (`parcours_offres_page.dart`, i18n `parcours` `fr.i18n.json:965-1026`)

7 pages linéaires, **mêmes questions pour tout le monde, aucune branche**. Réponses gardées en mémoire, écrites **en une fois** à la page 6 (`:106-150`).

| Page | Question exacte | Réponses | Obligatoire | Réf. |
|---|---|---|---|---|
| 1/7 (3 min) | « Quel âge a {prenom} ? » ; « L'âge décide de la durée des séances et du nombre d'élèves par groupe. Nous ne demandons pas de date de naissance : une tranche suffit. » | tranches serveur `cohortes_age` : « 5 à 7 ans », « 8 à 10 ans », « 11 à 14 ans », « 15 à 17 ans », « 18 ans et plus » (`0043:112-119`) | oui ; **pas de bouton Retour sur cette page** | `:249-283` |
| 2/7 (3 min) | « Dans quelle langue le cours doit-il être donné ? » ; explication langue du cours ≠ langue de l'app | `langues_cours` : Poular, Français, English (`0043:75-79`) | oui | `:287-321` |
| 3/7 (2 min) | « Où vous trouvez-vous ? » ; « Nous nous en servons uniquement pour vous montrer les horaires à votre heure locale… » ; « Proposé d'après l'heure de votre appareil » | 8 lieux **libellés en dur dans le Dart** (`libelles_parcours.dart:115-155` : « France, Belgique, Espagne », « Guinée, Sénégal, Mali, Mauritanie », « Canada et États-Unis, côte est »…) | oui (suggestion possible, DST non modélisé `:86-90`) | `:325-368` |
| 4/7 (2 min) | « Où en est {prenom} aujourd'hui ? » ; « Votre réponse oriente les premières propositions. Elle ne fixe pas le niveau officiel… » | « Nous commençons par les lettres » ; « Les lettres sont reconnues, la lecture demande de l'aide » ; « La lecture est possible, lentement » ; « Le Coran se lit déjà couramment » ; « Une partie est déjà mémorisée » | oui | `:372-398`, `fr.i18n.json:984-990` |
| 5/7 (1 min) | « Que souhaitez-vous d'abord ? » | « Apprendre à lire », « Lire plus couramment », « Mémoriser », « Je ne sais pas encore » | oui, posée **même au débutant** | `:402-430` |
| 6/7 (1 min) | « Quels moments de la journée vous conviennent le mieux ? » (multi) | « Le matin », « L'après-midi », « Le soir » | facultatif ; **jamais envoyé au serveur**, perdu au rechargement | `:434-470`, rapport FABLE §3.1 |
| 7/7 | « Voici les horaires ouverts pour {prenom} » ; « Le plus proche de vos réponses » / « Autres horaires possibles » ; carte `ScheduleOption` « Choisir cet horaire » | repli « Aucun de ces horaires ne me convient » -> « Me prévenir si de nouveaux horaires ouvrent » ; vide « Aucun horaire ouvert ne correspond encore » | choix -> retour `/tuteur` ; CTA bas « Retour » -> `/tuteur` | `:474-577` |

Chargement ou erreur initiale : `PageShell` titré « Nous préparons vos options. » avec squelette, ou en erreur la phrase « Cette réponse n'a pas pu être enregistrée. Réessayez. » **sans bouton Réessayer ni sortie** (`:219-226`).

Reprise : si `onboarding_fait_le` et cohorte et langue existent, la page s'ouvre directement sur les horaires ; « Retour » redescend vers les réponses connues (`:228-232`, `offre_horaire.dart:538-539`).

---

## 4. Services et RPC appelés (noms exacts)

| Appel | Depuis | Serveur | En production |
|---|---|---|---|
| `auth.signInWithOtp(email, emailRedirectTo)` | `service_auth.dart:51-52` | Supabase Auth | oui (état SMTP non documenté dans `docs/current`) |
| `auth.signInWithOAuth(google, redirectTo)` | `service_auth.dart:63-64` | Supabase Auth | **INCONNU** (aucune preuve dans `docs/current` ; le commentaire `connexion_page.dart:151-154` cite une panne `invalid_client` passée) |
| `auth.signInWithPassword` | `service_auth.dart:55-60` | démo `DEMO_AUTH` seulement | non (masqué) |
| `auth.refreshSession` | `source_session.dart:44-49` | Supabase Auth | oui |
| `from('profiles').select('account_status, student_profiles(interface_mode)')` | `source_session.dart:79-83` | policy `profiles_self_select` | oui |
| RPC `creer_profil_inscription(p_role, p_first_name, p_last_name, p_gender)` | `service_dossier.dart:96-104` | `0004:347-420` | oui |
| RPC `etat_dossier()` | `service_dossier.dart:109` | `0004:431-484` | oui |
| insert `contract_acceptances(profile_id, contract_kind, version)` | `service_dossier.dart:117-127` | `0004:221-264` | oui |
| storage `kyc`.uploadBinary + insert `kyc_documents` | `service_dossier.dart:142-155` | `0004`, colonnes R2 `0034:104-120` | oui |
| select `contract_acceptances` | `service_acceptations.dart:87-91` | policy self read | oui (enseignant seulement) |
| Edge `creer-profil-enfant` | `service_appairage.dart:250-258` | `index.ts` + RPC `creer_profil_enfant` (`0004:828-905`) | fonction présente dans le dépôt ; déploiement non vérifié ici |
| RPC `regles_academie` | `service_offres.dart:99-100` | `0043:548-569` | **non (0043 non appliquée)** |
| select `langues_cours`, `cohortes_age` | `service_offres.dart:111-125` | `0043` | **non** |
| select `v_parcours_onboarding` | `service_offres.dart:131-133` | `0043:945-987` | **non** |
| RPC `enregistrer_profil_apprentissage` | `service_offres.dart:145-155` | `0043:585-660` | **non** |
| RPC `offres_compatibles` | `service_offres.dart:159-165` | `0043:682-765` | **non** |
| RPC `choisir_offre_horaire` | `service_offres.dart:175-183` | `0043:769-826` | **non** |
| RPC `renoncer_intention_horaire` | `service_offres.dart:186-190` | `0043:830-865` | **non**, et **jamais appelée par l'UI** |
| RPC `signaler_horaire_insatisfait` | `service_offres.dart:198-212` | `0043:880-929` | **non** |

---

## 5. Consentements : texte, stockage, version, mise à jour

| Point | FAIT | Réf. |
|---|---|---|
| Sortes possibles | `guardian_terms`, `teacher_nda`, `recording_and_control_notice` ; toute autre valeur refusée par `CHECK` | `0004:224-228`, `enums.dart:197-218` |
| Texte accusé tuteur | « Chaque cours est enregistré en audio, conservé trente jours, puis effacé. Chaque écoute est inscrite au journal, avec le nom de qui écoute. » + « Un contrôleur qualité peut assister à un cours sans être vu. La salle le rappelle en permanence, que la visite ait lieu ou non. » | `fr.i18n.json:180-181` |
| Geste | un bouton « J'ai compris » / « J'ai lu et j'accepte » : pas de case, rien de précoché, pas de texte long | `signature_page.dart:143-147` |
| Stockage | une ligne par (profil, sorte, version), immuable par déclencheurs, lue par le titulaire et l'admin | `0004:231-264` |
| Version | `'2026-09'` pour toutes les sortes | `versions_contrat.dart:13` |
| Qui signe | le titulaire connecté uniquement (`profile_id = auth.uid()`) ; un élève (enfant ou adulte ajouté) ne signe jamais rien | `service_dossier.dart:118-126` |
| Relecture | seulement dans le profil enseignant | `profil_enseignant_page.dart:511` |
| Mise à jour pour comptes existants | **ABSENT.** `etat_dossier()` vérifie `exists` sans filtre de version (`0004:459-470`) ; un compte actif est renvoyé hors de `/attente` (`redirection.dart:81-87`) | |
| Ce que DIT le code | « Changer cette valeur redemande donc la signature à tout le monde » | `versions_contrat.dart:3-6` : **faux en pratique** |
| Consentement d'observation parentale (mandat observation §6) | **ABSENT** : aucune clé i18n (« Les parents des élèves… », « Comment ça marche ? ») ; aucune sorte en base ; aucune migration sur `observation/lot-2026-09-21` ; la politique serveur de visites existe (`0036`, 2 visites, 120 s par visite, 240 s au total, appliquée d'après `CONFIGURATION_BASELINE:124`) | grep `fr.i18n.json` et migrations |
| Texte corrigé ailleurs | `v0/verite-produit` remplace le point enregistrement par « Aucun cours n'est enregistré aujourd'hui… » **sans changer la version** (`git diff main...v0/verite-produit -- assets/i18n/fr.i18n.json`) | contraire à `versions_contrat.dart:8-9` |

---

## 6. Réponses aux questions posées

| Question | Réponse factuelle |
|---|---|
| Choix « Moi uniquement / Moi et ma famille » ? | **Non.** Trois cartes de rôle (§3.2). « Élève adulte, pour moi-même » est l'ancêtre de « Moi uniquement » mais n'a pas d'effet distinct (même rôle `guardian`, aucune trace du choix en base, `inscription_page.dart:92-99`). |
| Inscription enseignant ? | **Oui** : carte « Enseignant » -> `creer_profil_inscription('teacher')` -> `teacher_profiles` + `pending_kyc` (`0004:409-413`) -> même portail `/attente` avec `teacher_nda` -> `/enseignant/journee`. La page `ENS-01` `/enseignant/bienvenue` n'est jamais atteinte (route orpheline). |
| Le parent est-il forcé d'avoir un profil élève ? | **Non** : `guardian` n'a pas de `student_profiles`. Mais l'adulte qui veut étudier **ne peut pas** en avoir un non plus (voir ligne suivante). |
| Comment le parent créerait son propre profil plus tard ? | **Impossible aujourd'hui.** Un compte = un profil = un rôle (`0004:375-378`) ; le rôle vient du JWT (`source_session.dart:58-70`) ; aucune RPC ne crée une fiche `autonomous` pour soi. Seul contournement : s'ajouter comme « enfant » (âge ≤ 18 côté client), ce qui crée un **second compte** élève sans courriel, accessible par code d'appareil, typé `minor` : contraire au mandat (« même compte, aucun doublon »). `peut_decrire_apprenant` prévoit pourtant le cas `p_profile_id = auth.uid()` + `autonomous` (`0043:215-223`) : chemin de lecture/écriture sans chemin de création. |
| Comment ajoute-t-on un 2e enfant ? | Même écran que le premier (§3.4), depuis Foyer, Compte ou Accueil vide ; retour au Foyer ; le questionnaire se relance depuis la carte de l'enfant dans le bloc d'accueil. Aucune limite côté client. |
| Pour qui la question est posée ? | Inscription : toujours le titulaire. Questionnaire : l'élève nommé par l'URL (`{prenom}` dans l'âge et le niveau, « vous » dans langue, objectif, moments). Le bloc d'accueil titre « Le parcours de {prenom} » avec le **premier** apprenant seulement même s'il y en a plusieurs (`bloc_parcours.dart:66`). |
| Consentement d'observation ? | ABSENT (§5). À compléter côté texte : possible en frontend ; enregistrement et remise à jour : dépendance backend (§11, D3-D4). |
| Récupération de mot de passe ? | Sans objet en production (aucun mot de passe). « Récupérer mon accès » = redemander un lien sur `/connexion` ; pas de route `/recuperation`, pas de bouton « Renvoyer » sur l'état « Lien envoyé ». |
| Lien expiré ? | **Non géré.** Aucun code ne lit l'erreur de retour d'URL (`otp_expired`, `error_description` : 0 occurrence dans `lib/`) ; l'usager retombe sur `/connexion` sans explication. |
| Connexion Google ? | Bouton présent et branché (`service_auth.dart:63-64`). Sur le web, retour sur l'origine servie. Sur Android/iOS natifs : aucun `intent-filter` de lien profond (`AndroidManifest.xml:23-26` = seul `MAIN/LAUNCHER`), aucun `CFBundleURLSchemes` dans `ios/Runner/Info.plist` ; le retour tombe donc sur le « Site URL » web. Les nom et prénom Google ne préremplissent pas l'inscription. |
| Session expirée ? | Déconnexion -> `/connexion` sans message ni retour vers la destination demandée (`redirection.dart:39-49`). |

---

## 7. Reprise, sorties, double soumission

| Tunnel | Reprise | Sorties | Double soumission |
|---|---|---|---|
| `/inscription` | aucune donnée écrite avant la page 4 : un rechargement repart de la page 1 (le routeur y ramène tant que `profiles` est vide) | **aucune** : pas de déconnexion, pas de Retour en page 1 ; un compte Google erroné reste bloqué ici | bouton inerte pendant l'envoi (`action_principale.dart:91`) ; **défaut** : si `creer_profil_inscription` réussit puis `refreshSession` échoue, l'erreur s'affiche, et chaque nouvel essai échoue sur « ce compte a déjà un profil » (`0004:376-378`) sans jamais rappeler le rafraîchissement (`inscription_page.dart:91-114`) : impasse jusqu'au rechargement |
| `/attente` | calcul serveur `etat_dossier()`, reprise multi-appareil | « Se déconnecter » ; chaque sous-page revient à `/attente` | acceptations protégées par l'unicité (`0004:231`) ; dépôts de pièce multiples possibles (nom aléatoire) |
| Ajout d'élève | aucune | « Retour » -> Foyer | bouton inerte pendant l'envoi ; **aucune idempotence serveur** (nouvel utilisateur auth à chaque appel, `index.ts:49-57`) : une réponse perdue puis un nouvel essai créent un doublon |
| Questionnaire | fin de parcours seulement (`profilRempli`) ; moments jamais conservés ; réponses partielles perdues | page 1 sans Retour ni navigation (route hors coquille, `app_router.dart:294-298`) ; erreur de chargement sans action | choix d'horaire protégé par l'index `intentions_une_vivante_par_eleve` (`0043:413-414`) ; « Changer d'horaire » (`bloc_parcours.dart:96`) **échoue toujours** : aucun appel à `renoncer_intention_horaire` avant le nouveau choix, d'où `unique_violation` (`0043:802-805`) ; signalement « Me prévenir » répétable après rechargement |

---

## 8. Branches : débutant / non-débutant, âge, pour qui

- **Aucune branche** dans le code actuel : le niveau déclaré ne change aucune question suivante (`parcours_offres_page.dart:234-242`). Pas de pré-diagnostic.
- **Débutant** : `diagnostic_statut` vaut `a_planifier` par défaut (`0043:242`) ; l'accueil annonce donc à tous « Il reste un échange avec un enseignant pour situer le niveau de {prenom}. L'académie vous proposera un rendez-vous. » (`offre_horaire.dart:596-599`, `fr.i18n.json` `etatDiagnosticRequisDetail`). Contraire à `01:19` (débutant : parcours de base) et à l'arbitrage Classes V2 §5 (« Je débute », aucun diagnostic D0 ; branche `docs/core24-classes-arbitration`, non fusionnée).
- **Âge demandé deux fois, de deux façons** : entier 3-18 à l'ajout (`ajouter_enfant_page.dart:42-48`), puis tranche au questionnaire. Deux vérités non reliées : un enfant saisi « 9 ans » peut être placé « 11 à 14 ans » ; `interface_mode` est calculé à la création (`0004:869-875`) puis écrasé par la tranche (`0043:633-634`). Un enfant de 3 ou 4 ans accepté à l'ajout n'a aucune tranche (minimum 5 ans). Anniversaire, âge manquant, borne : non traités.
- **Tranches** : 5-7 / 8-10 / 11-14 / 15-17 / 18+ en base (`0043:112-119`). Le mandat cite 6-9 / 10-13 / 14-17 / 18+ « si confirmée » : cette décision existe dans `CORE24_CLASSES_ARBITRATION_FINAL.md` §4 (branche non fusionnée), avec date de naissance obligatoire pour les mineurs ; son implémentation (`definir_date_naissance_apprenant`) n'existe que sur `integration/core24-classes-v2-remediation`, ligne CORE24 déclarée non conforme.
- **Pour qui** : un seul type d'apprenant, l'élève `student` du foyer ; aucun écran ne distingue enfant, proche adulte ou soi-même.

---

## 9. Ce que disent les commentaires et documents, contre ce que fait le code

| DIT | FAIT |
|---|---|
| « un foyer en vérification doit pouvoir décrire son enfant » (`0043:194-196`, FABLE report §1.4) | `/tuteur/*` fermé à `pending_kyc` (`redirection.dart:64-68`) ; ajout d'enfant refusé à `pending_kyc` (`0004:856-858`) |
| « Changer cette valeur redemande la signature à tout le monde » (`versions_contrat.dart:3-6`) | `etat_dossier()` ignore la version ; aucun écran n'est atteignable pour un compte actif |
| « Sur mobile, le schéma d'application reste celui que le paquet déclare » (`service_auth.dart:46-47`) | aucun schéma déclaré dans les manifestes Android/iOS |
| Contrat : audio enregistré et conservé 30 jours (`fr.i18n.json:180`) | aucun enregistrement réel (`CLAUDE.md`, `06:32-33`) |
| « Élève adulte » = son propre tuteur, un seul chemin en base (`inscription_page.dart:33-37`) | pas de fiche élève : l'adulte ne peut ni se décrire ni choisir un horaire |
| « Changer d'horaire » depuis l'accueil (`fr.i18n.json` `changerHoraire`) | le choix échoue tant que l'ancienne intention n'est pas retirée ; retrait jamais appelé |
| Clés prêtes : `inscription.titre`, `inscription.champRequis`, `parcours.intro`, `parcours.reprendre`, `parcours.modifier`, `contrat.lireTexte` | aucune utilisée (grep `lib/` hors `*.g.dart`) |
| Rapport FABLE : « Déployer sur Vercel (manuel) - main ne déclenche rien » (§7) | caduc : depuis le 24/09 un push `main` déploie (`CLAUDE.md` racine) |

---

## 10. Contradictions à consigner (ne pas trancher en silence)

| # | Source A | Source B | Effet sur l'admission |
|---|---|---|---|
| X1 | Mandat §4-§5 + `01:20` + `06:15` : la famille choisit une **classe réelle** avec enseignant, séances, places, liste d'attente | `0043` + `offre_horaire.dart:307-316` + arbitrage Classes V2 §2 : la famille choisit une **offre sans enseignant ni places** ; « Marketplace famille : DEPRECATE » | la fin du questionnaire (catalogue) n'a pas de backend conforme au mandat ; à arbitrer par le directeur |
| X2 | Mandat §6 : parent sans profil élève, qui peut en créer un plus tard dans le même compte | modèle « un compte = un rôle » (`0004:375-378`) | « Créer mon profil élève » impossible sans backend |
| X3 | Mandat : cohortes 6-9 / 10-13 / 14-17 / 18+ ; arbitrage : date de naissance pour mineurs | base : 5-7 / 8-10 / 11-14 / 15-17 / 18+, « jamais une date de naissance » (`0043:81-92`) | la question d'âge ne peut pas être refaite sans RPC |
| X4 | Mandat + arbitrage : débutant sans diagnostic | code : diagnostic à planifier pour tous | message d'accueil faux pour un débutant |
| X5 | Texte d'accusé signé (audio enregistré) | `06:32-33`, `v0` | consentement recueilli sur une information fausse ; correction de texte = nouvelle version à signer, mécanisme absent |
| X6 | `docs/current/01:30` : observation « une visite, 120 s cumulées » | mandat observation §4 + `0036` appliquée : 2 visites × 120 s, 240 s | le texte de consentement doit lire la politique effective, pas une constante |
| X7 | Mandat : `/bienvenue`, `/recuperation`, `/onboarding/usage`, `/onboarding/recapitulatif` | routes réelles `/connexion`, `/inscription`, `/attente/*`, `/tuteur/parcours/:id` | mapper par alias, ne pas créer de routes concurrentes (propriété du coordinateur) |

---

## 11. Dépendances backend (hors périmètre, à documenter)

| Id | Service attendu | Entrée / sortie | Impact si absent |
|---|---|---|---|
| D0 | Application de `0043_offres_horaires_et_intentions.sql` (déjà écrite) | - | tout le questionnaire pédagogique et le bloc d'accueil restent inertes |
| D1 | Création d'une fiche élève pour le titulaire lui-même (même compte, même foyer) et projection de ce double statut dans le jeton ou une capacité | `creer_mon_profil_eleve()` -> `student_profiles(profile_id = auth.uid(), student_type = 'autonomous')` ; lecture d'une capacité « a un espace élève » | « Moi uniquement », « Créer mon profil élève » et l'élève adulte seul impossibles |
| D2 | Ajout d'un **proche adulte** distinct d'un mineur (type, consentement propre) et ouverture de l'ajout d'élève à un foyer `pending_kyc` si la politique le veut | `creer_profil_enfant` paramétré par type ; porte `compte_en_parcours()` | l'ajout reste réservé aux comptes validés et toujours `minor` |
| D3 | Sorte de consentement « information d'observation parentale » (élargir le `CHECK` de `contract_acceptances` ou table dédiée) | insert (profil, sorte, version) | le texte peut s'afficher, pas s'enregistrer comme accord |
| D4 | Consentements **requis par version** et exposition des manquants à un compte **actif** (RPC `consentements_a_renouveler()`), plus règle serveur sur ce que bloque un refus | liste des sortes et versions manquantes | aucun compte existant ne sera jamais interrogé ; `VersionsContrat` ne sert à rien |
| D5 | Date de naissance canonique des mineurs et nouvelles cohortes (arbitrage Classes V2 §4) | `definir_date_naissance_apprenant(membre, date)` | âge demandé en tranche, bornes incohérentes |
| D6 | Branche débutant : ne pas passer `diagnostic_statut` à `a_planifier` pour une entrée débutant déclarée ; pré-diagnostic 2-4 questions pour les autres | colonnes `placement_basis` / statut | message de diagnostic faux |
| D7 | Idempotence de `creer-profil-enfant` (clé d'idempotence) | clé client -> même profil | doublons d'élève sur réseau instable |
| D8 | Retrait + nouveau choix atomique (`changer_offre_horaire`) ou appel client à `renoncer_intention_horaire` avant `choisir_offre_horaire` (cette seconde voie est frontend) | motif `parcours.renoncerMotif` déjà présent | « Changer d'horaire » en échec |
| D9 | Configuration plateforme : liens profonds Android/iOS pour lien courriel et Google ; URL de redirection autorisées Supabase ; état réel du fournisseur Google | - | connexion native mobile non fermée ; propriété du coordinateur (config plateforme) |

---

## 12. Ce que l'agent Admission peut faire en frontend seul (sans affaiblir un contrat)

- Écran d'usage à deux cartes + lien enseignant discret, en conservant le mapping réel : « Moi uniquement » et « Moi et ma famille » -> `guardian` ; « Enseignant » -> `teacher`. Le choix « Moi uniquement » doit **dire honnêtement** que l'espace élève personnel dépend de D1 (état indisponible, pas de faux succès).
- Préremplir prénom et nom depuis les métadonnées Google si présentes (`auth.currentUser.userMetadata`), déconnexion accessible depuis `/inscription`, correction du défaut de rafraîchissement (rappeler `rafraichir()` quand la RPC répond « déjà un profil »).
- Refonte visuelle de `/attente`, `/attente/accuse|contrat`, `/attente/piece` (une liste sobre, une seule zone pleine par écran) ; afficher un texte d'information d'observation paramétré par la politique effective, **sans prétendre l'enregistrer** tant que D3 manque.
- Connexion : état « lien expiré ou déjà utilisé » en lisant l'erreur de retour d'URL, bouton « Renvoyer le lien », alias `/recuperation` -> `/connexion` (routeur : demande au coordinateur).
- Questionnaire : Retour/sortie en page 1, bouton Réessayer sur l'erreur de chargement, chaîner ajout d'élève -> questionnaire, titre du bloc par apprenant, appel `renoncer_intention_horaire` avant un nouveau choix (le service existe), libellés de fuseaux passés en i18n. Tant que D0 manque, l'écran doit afficher un état indisponible explicite plutôt que se taire.
- Recette du mandat réalisable seulement en simulation : parent + un enfant, plusieurs enfants, reprise interrompue (dossier), enseignant. **Non réalisables réellement** : adulte seul, parent qui ajoute son profil plus tard, profil personnel existant, débutant/non-débutant distincts (D0, D1, D6).

---

## 13. Tests existants (non exécutés dans cette mission)

`test/features/inscription_test.dart` (7 tests, dont « un élève adulte est son propre tuteur » qui vérifie seulement le rôle `guardian`, `:100-134`), `connexion_test.dart` (démo, courriel, Google, feuille élève), `attente_test.dart`, `dossier_test.dart`, `dossiers_sans_piece_test.dart`, `test/parcours/parcours_offres_test.dart` (32 tests selon le rapport FABLE, faux service `test/parcours/faux_service_offres.dart`), `test/router/redirection_test.dart`. Aucun test ne couvre : lien expiré, retour natif, idempotence d'ajout d'élève, changement d'horaire, consentement d'observation, élève adulte réel.

## 14. Branches consultées (lecture `git diff main...<branche>` sur les chemins du domaine)

`observation/lot-2026-09-21` (i18n +1 clé d'annonce, rien sur l'admission) ; `v0/verite-produit` et `nettoyage/base-2026-09-23` (texte d'enregistrement corrigé, chemins de docs) ; `integration/core24-classes-v2(-remediation)` (date de naissance, cohortes : NON CONFORME, ne pas intégrer) ; `docs/core24-classes-arbitration` (arbitrage Classes V2) ; `core24/fable-frontend`, `astra/core24-v2` (i18n et `/attente` modifiés, NON CONFORME) ; `lot/onboarding-offres` (identique à `main` sur ces chemins).
