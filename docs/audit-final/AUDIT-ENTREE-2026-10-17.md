# Audit UX du parcours d'entrée, Rewayah Academy

Date : 17/10/2026. Branche : `claude/corrections-audit-2026-10-17`. Lecture seule : aucun fichier de `lib/` ni de `test/` modifié, aucun commit. Le test temporaire `test/_audit_tmp/audit_entree_test.dart` a servi aux captures puis a été supprimé (`git status` propre).

Statut de preuve de chaque constat : `présent dans le code` (lu, avec fichier:ligne) et, quand c'est indiqué, `vu en capture` (test widget local, polices réelles, thème clair). Rien n'est `testé sur staging` ni `déployé`.

Captures : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/37ff0dc5-64c8-5d90-a02d-24473d02f0f3/scratchpad/AUDIT-ENTREE/captures/` (99 PNG, clair, 390x844 et 1440x900). Préfixes : `la1_` à `la4_` et `ajout_` viennent des tests de capture déjà présents dans le dépôt (relancés avec `CAPTURE_DIR`), `audit_` vient du test temporaire. Le petit ruban rouge en haut à droite des captures `audit_` est le bandeau de débogage du test, pas un défaut de l'app.

## 0. Carte du parcours (d'après le routeur)

Source : `lib/core/router/app_router.dart:270-372` (routes), `lib/core/router/redirection.dart` (portes), `Routes.publiques` = `/connexion`, `/bienvenue`, `/agent` (`lib/core/router/routes.dart:1163`).

```
Visiteur sans session
  /  (EcranDemarrage) ──1re visite──> /bienvenue (5 diapositives) ──> /connexion
                      └─déjà vue────> /connexion
  /connexion ──lien courriel ou Google──> session
            ├─> /connexion/recuperation
            └─> feuille « appareil d'un élève » ──> /connexion/eleve (/scanner, /code)
Session sans profil (porte inscription)
  /inscription/usage ──> /identite ──> /genre ──> /recapitulatif ──> /attente
        └─ « J'ai un code d'invitation » ──> /inscription/invitation (enseignant)
Compte en attente (porte attente, forcé)
  /attente (hub) ──> /attente/accuse ──> retour /attente ──> /attente/contrat ──> retour /attente
                                                   └─ enseignant : ──> /attente/piece ──> /attente
Compte actif, écrans forcés avant l'accueil
  contrôleur : /controleur/mfa ; enseignant à resigner : /enseignant/contrat
Accueil famille (non forcé, mais suite logique de l'entrée)
  /tuteur/foyer/ajouter (âge en années) ──> /tuteur/parcours/:id (âge en tranche, 7 questions)
  /tuteur/compte/consentements (accord « visites des parents », comptes existants)
```

Écrans **publics, d'avant connexion** : `/` (démarrage), `/bienvenue`, `/connexion`, la feuille « appareil d'un élève », `/connexion/recuperation`, `/connexion/eleve`, `/connexion/eleve/scanner`, `/connexion/eleve/code`, `/agent` (entrée d'agent IA, hors parcours humain). Tous les autres demandent une session.

## 1. Les quatre signalements du directeur

### 1.1 Cartes cliquables seulement sur le petit point : confirmé en partie

- `ChoiceCardGroup` : dans le code, **toute la carte** est la cible (`lib/core/widgets/choice_card_group.dart:376-380`, `Pressable.selon` ; `lib/core/widgets/pressable.dart:375-376`, `HitTestBehavior.opaque`). Vérifié par un appui dans la marge gauche de la carte « Moi uniquement » à 1440 px : la carte est retenue (`CIBLE usage marge : (true, false)`).
- Mais tout dans le rendu dit le contraire : sur grand écran la carte fait 1136 px de large et le **seul contrôle visible est le radio tout au bout à droite** (`choice_card_group.dart:529` en liste, `:584` en côte à côte) ; au survol, seul le filet change (`choice_card_group.dart:394`), aucun fond ; le texte est noir sur blanc comme un texte inerte. La personne vise le radio. Capture : `la2_usage_1440x900_light.png`, `la4_question_age_1440x900_light.png`.
- **Cases d'accord (consentements) : confirmé.** `CaseAccordTexte` pose un `CheckboxListTile` dans une `AppCard` (`lib/features/consentements/texte_observation.dart:131-146`) : la marge intérieure de la carte n'est pas une cible. Appui à 6 px du bord de la tuile, dans la carte : la case reste décochée (`CIBLE case marge : false`). La personne voit une carte et ne peut toucher qu'une bande.

Correction : dans `ChoiceCardGroup`, l'état choisi se lit sur toute la carte (fond `washAccent` déjà là, plus une coche en tête de carte côté `start`, pas un radio isolé en bout de ligne), fond au survol, texte du titre en encre d'accent au survol ; sur bureau, plus de carte de 1136 px (voir 1.2). Pour les accords, `CaseAccordTexte` devient une carte entièrement pressable (`AppCard(onPress:)` ou `Pressable`) qui dessine la case, au lieu d'un `CheckboxListTile` posé dans une carte.

### 1.2 Grand écran : cartes du mobile étirées : confirmé

- `PageEtape` (inscription) n'a aucune borne de largeur (`lib/core/widgets/page_etape.dart:64-70`) ; `PageParcours` non plus (`lib/core/widgets/page_parcours.dart`). Les cartes et le bouton « Continuer » prennent toute la colonne de 1136 px (`la2_usage_1440x900_light.png`, `la2_genre_1440x900_light.png`, `la4_question_age_1440x900_light.png`). À l'inverse, l'ajout d'un profil élève borne sa colonne (`lib/features/foyer/formulaire_profil_eleve.dart:709`, `AppPage.largeurDialogue`) : trois gabarits d'étape, trois largeurs.
- Bouton plein pleine largeur sur bureau (`lib/features/inscription/inscription_page.dart:163-169`, `page_parcours.dart:120`), contraire au contrat DESIGN-GOV (« pas de bouton pleine largeur sur bureau sans justification »).
- `ChoiceCardGroup` n'a que deux dispositions, liste (`choice_card_group.dart:245`) et côte à côte (`:219`), identiques au mobile : toutes les options ont même taille et même style.
- Aucune option n'a d'exemple ni d'illustration ; beaucoup n'ont même pas de phrase (voir 1.2 bis).
- `/bienvenue` sur bureau : cinq diapositives de même gabarit (pictogramme rond + titre + phrase), une à la fois, avec un grand vide (`la1_bienvenue_1440x900_light.png`).

Correction : une disposition **bento** dans le composant partagé (jamais écran par écran) : `ChoiceCardGroup(disposition: bento)` au-delà de 900 px, posée sur `GrilleBento` / `BentoTile` (`lib/core/widgets/grille_bento.dart`, `bento_tile.dart`). Une option mise en avant (la plus fréquente ou recommandée) en grande tuile, les autres en tuiles de tailles et de traitements différents ; `OptionChoix` gagne `exemple` (« Par exemple : vous inscrivez Yasmine, 9 ans, et Bilal, 12 ans ») et `illustration` (asset du dépôt). Mobile inchangé (liste). Bouton à largeur de contenu, au bord `end`, sur bureau. `/bienvenue` sur bureau : une seule page bento des cinq idées au lieu du carrousel. Avant d'implémenter : fiche `UX_REVIEW_<lot>.md` exigée par `DESIGN-GOV-2026-09-26.md` §4.

1.2 bis. Choix non expliqués (K-58, « chaque option dit quand la choisir ») : genre pour le tuteur (aucune explication, `lib/features/inscription/etapes/genre_etape.dart:35`) ; « Suivez-vous aussi des cours ? » oui / non sans phrase ni icône (`lib/features/inscription/etapes/usage_etape.dart:133-150`) ; parcours : tranche d'âge, langue, lieu, niveau, objectif, moments, toutes en libellé seul (`lib/features/parcours_offres/parcours_offres_page.dart:425, 464, 514, 542, 574, 608`) ; type de pièce d'identité (`lib/features/dossier/depot_piece_page.dart:215-236`).

### 1.3 Âge tantôt en tranche, tantôt en chiffres : confirmé, et posé deux fois

- Ajout d'un profil élève : âge **en années**, 13 puces de 6 à 18 (`lib/features/foyer/formulaire_profil_eleve.dart:615-675`, libellé « Âge, en années », `assets/i18n/fr.i18n.json:1377`). Capture `ajout_identiteRemplie_1440x900@1_light.png`.
- Parcours, question 1 : **tranche** venue du serveur (« 8 à 10 ans », « 18 ans et plus »), avec la phrase « une tranche suffit » (`parcours_offres_page.dart:399-431`). Capture `la4_question_age_390x844_light.png`.
- Même enfant, même famille, à deux écrans d'écart : l'âge est demandé deux fois, sous deux formes ; la seconde ne reprend pas la première (K-57 « déduit > choisi > saisi »).
- La fiche élève dit ensuite que « l'âge et la date de naissance ne sont pas encore enregistrés » (`fr.i18n.json:1461`) : troisième discours.

Correction : une seule question, une seule forme, posée une fois à l'ajout du profil. Proposition : la tranche (cohortes servies par `cohortesAgeProvider`), puisque c'est elle qui décide de la classe ; le parcours la déduit et ne la repose pas (il commence à la langue). La dérivation affichage / caméra à partir de la tranche se décide en base (ADR-009) : point à confier au backend (ChatGPT, `docs/orchestration/COHABITATION.md`). Arbitrage du directeur nécessaire si l'âge exact reste exigé pour la caméra.

### 1.4 Consentements éclatés, va-et-vient, passage sans signer : confirmé

- Le hub `/attente` envoie à un seul texte à la fois (`lib/features/dossier/attente_page.dart:202-236`) ; chaque signature renvoie au hub (`lib/features/dossier/signature_page.dart:300`, `onRetour` `:326`), qui renvoie au texte suivant. Tuteur : 2 allers-retours ; enseignant : 3 (accusé, contrat, pièce). Captures `la3_attente_390x844_light.png`, `audit_attente_enseignant_390x844_light.png`.
- **Le même texte deux fois** pour le tuteur : l'accusé affiche `paragraphesA3()` (`signature_page.dart:97`) et le contrat affiche encore `paragraphesA3()` (`:178`) avant la case des visites. Captures `audit_accuse_tuteur_390x844_light.png`, `audit_contrat_tuteur_390x844_light.png`.
- L'accusé n'a **aucune case** : on « signe » par le bouton « J'ai lu » (`signature_page.dart:94`).
- Le contrat a son bouton **toujours actif** : on peut appuyer sans cocher, puis l'écran dit « Il manque votre accord : cochez la case » (`signature_page.dart:346`, `_direManque`). Capture `audit_contrat_tuteur_refus_390x844_light.png`. Ailleurs dans l'entrée, « Continuer » est au contraire inactif tant qu'on n'a pas choisi (`inscription_page.dart:165`) : deux comportements opposés.
- Troisième lieu de consentement : `/tuteur/compte/consentements` pour les comptes existants (`lib/features/consentements/consentement_observation_page.dart`), et l'invite qui devait y mener, `InviteConsentementObservation` (`:269`), **n'est utilisée nulle part** : personne n'y est conduit.
- Texte faux par rapport aux décisions : l'accusé et le contrat disent « Chaque cours est enregistré en audio » et le titre « Les cours sont enregistrés (le son seulement) » (`assets/i18n/fr.i18n.json:921, 932, 934, 946`), alors que le client ne fait aucun enregistrement et que la décision du 11/10/2026 remplace la mention par « Visite de contrôle possible » (`lib/CLAUDE.md`, ADR-011). À faire trancher avant toute signature réelle : on fait signer un fait qui n'existe pas.

Correction (cible du directeur) : une seule page `/attente/accords` qui défile : chaque texte (ce que vous devez savoir, contrat, visites des parents ; pour l'enseignant, clause de contrôle et politique) en section, **une case par texte**, toute la carte de la case est la cible, un seul bouton « Suivant » en bas, actif seulement quand tout est coché, avec la ligne « Il reste N accords à cocher » au-dessus. Envoi groupé des acceptations (`ServiceDossier.accepterContrat` par sorte aujourd'hui ; une RPC groupée relève du backend). La pièce d'identité reste une étape à part pour l'enseignant (elle demande un fichier). `/attente` ne montre plus que l'état. Note : « bouton inactif jusqu'à complétude » contredit BOUTONS-GRISES-1 / K-56 ; la demande explicite du directeur prévaut, à consigner comme décision datée pour que le contrôle `bouton-grise` l'admette.

## 2. Fiches par écran

Format : route, fichier, public ou non, captures, défauts (fichier:ligne), correction.

### E0. Démarrage `/` : public
- Fichier : `lib/core/router/etats_routeur.dart:140` (`EcranDemarrage`). Captures : `audit_demarrage_390x844_light.png`, `audit_demarrage_1440x900_light.png`.
- Défauts : aucun bloquant ; écran neutre (marque + squelette).

### E1. Présentation `/bienvenue` : public
- Fichier : `lib/features/bienvenue/bienvenue_page.dart`. Captures : `la1_bienvenue_390x844_light.png`, `la1_bienvenue_1440x900_light.png`, `audit_bienvenue_derniere_390x844_light.png`, `audit_bienvenue_derniere_1440x900_light.png`.
- Défauts :
  - « Commencer » et « J'ai déjà un compte » font exactement la même chose, aller à `/connexion` (`bienvenue_page.dart:577-589`) : deux boutons, un seul chemin ; le nouveau visiteur n'apprend nulle part qu'il crée un compte.
  - Les sorties sont au milieu du contenu de la dernière diapositive (`:462-465`), pas en bas (K-56).
  - Sur bureau, carrousel de cinq pages identiques et grand vide (voir 1.2).
  - Arabe : 7 clés absentes de `assets/i18n/ar.i18n.json` (`bienvenue.pointParcoursTitre`, `pointParcours`, `passer`, `position`, `positionLecteur`, `precedente`, `suivante`) : l'interface arabe affiche du français.
- Correction : « Commencer » mène à la connexion en mode création (titre « Créer votre compte », même lien courriel), « J'ai déjà un compte » au mode connexion ; actions en bas ; bureau en une page bento ; clés arabes.

### E2. Connexion `/connexion` : public
- Fichier : `lib/features/connexion/connexion_page.dart`. Captures : `la1_connexion_390x844_light.png`, `la1_connexion_1440x900_light.png`.
- Défauts :
  - Aucun « Créer un compte » : l'inscription passe par le même lien, sans que l'écran le dise (titre « Se connecter »).
  - Six sorties empilées dans une carte de 460 (lien, Google, appareil d'élève, lien expiré, découvrir) : beaucoup de choix pour un premier visiteur.
  - Erreur de renvoi peinte avec `colorScheme.error` au lieu de l'encre `inkAlert` (`connexion_page.dart:651`).
- Correction : une phrase « Pas encore de compte ? Le même lien le crée. » sous le titre, ou le mode création venu de E1 ; encre `inkAlert`.

### E2b. Feuille « Connecter l'appareil d'un élève » : public
- Fichier : `lib/features/connexion/feuille_appareil_eleve.dart`. Captures : `audit_feuille_appareil_eleve_390x844_light.png`, `audit_feuille_appareil_eleve_1440x900_light.png`.
- Défauts : pas de défaut bloquant relevé.

### E3. Récupération `/connexion/recuperation` : public
- Fichier : `lib/features/connexion/recuperation_page.dart`. Captures : `la1_connexion_recuperation_390x844_light.png`, `la1_connexion_recuperation_1440x900_light.png`.
- Défauts : pas de défaut bloquant relevé.

### E4. Entrée de l'élève `/connexion/eleve`, `/scanner`, `/code` : public
- Fichiers : `lib/features/eleve_connexion/eleve_connexion_page.dart`, `scanner_page.dart`, `saisie_code_page.dart`. Captures : `audit_eleve_connexion_*`, `audit_eleve_scanner_*`, `audit_eleve_code_*`.
- Capture partielle : dans le test, la base locale (drift, `path_provider`) n'a pas de greffon ; l'écran reste sur « Chargement ». Décrit d'après le code : choix du profil en deux colonnes (`eleve_connexion_page.dart:496-583`), pavé du code personnel (`PinPad`, `:700`), états vide et refus présents (`:427`, `:375`).
- Défauts : état de chargement en texte seul « Chargement » dans une carte (capture 1440), pas de `Skeleton` (DESIGN-GOV, contrat E).
- Correction : `Skeleton` pendant la lecture des profils locaux.

### E5. Hors ligne `/hors-ligne` : session sans profil lisible
- Fichier : `lib/core/router/etats_routeur.dart:84`. Captures : `audit_hors_ligne_390x844_light.png`, `audit_hors_ligne_1440x900_light.png`.
- Défauts : aucun bloquant.

### E6. Inscription, usage `/inscription` et `/inscription/usage` : session, sans profil
- Fichiers : `lib/features/inscription/inscription_page.dart`, `etapes/usage_etape.dart`. Captures : `la2_usage_390x844_light.png`, `la2_usage_1440x900_light.png`, `audit_usage_famille_390x844_light.png`, `audit_usage_famille_1440x900_light.png`.
- Défauts :
  - Cartes étirées, radio en bout de ligne, bouton pleine largeur sur bureau (1.1, 1.2).
  - La sous-question « Suivez-vous aussi des cours ? » arrive sous la carte, à moitié sous la ligne de flottaison (capture 390), oui / non sans explication ni icône (`usage_etape.dart:133-150`).
  - **Réponse perdue** : `parentSuitDesCours` est demandé et bloque « Continuer », mais n'est ni envoyé (`ServiceDossier.creerProfil`, `lib/core/dossier/service_dossier.dart:69-75`, aucun paramètre) ni montré au récapitulatif.
  - **Choix « Moi » / « Famille » gardé en mémoire seulement** (`lib/features/inscription/brouillon_inscription.dart:136`) alors que `/attente` s'en sert pour choisir la variante du contrat (`attente_page.dart:87`, `:233-234`) : après un rechargement du navigateur ou sur un autre appareil, l'adulte seul reçoit le texte « responsable légal ».
  - Écarts en dur `SizedBox(height: 24)` et `12` (`usage_etape.dart:127, 132`) au lieu d'`Ecart`.
  - Aucun retour possible vers `/bienvenue` ou `/connexion` depuis l'étape 1 : seulement « Se déconnecter ».
- Correction : bento sur bureau avec exemple et illustration ; sous-question soit intégrée à la carte « Moi et ma famille », soit supprimée tant qu'elle n'est pas enregistrée ; persister l'usage côté serveur (backend) ou le relire depuis le profil.

### E7. Code d'invitation `/inscription/invitation` : session, sans profil
- Fichier : `lib/features/recrutement/invitation_candidat_page.dart`. Captures : `audit_invitation_candidat_390x844_light.png`, `audit_invitation_candidat_1440x900_light.png`.
- Défauts : sans port serveur, l'écran ne dit que « La vérification des invitations sera disponible au branchement du serveur » (`:164-168`) : impasse, sans délai ni contact (K-59) ; titre « Votre code » répété dans la carte. Arabe : tout `recrutement.candidat.*` manque dans `ar.i18n.json`.
- Correction : phrase K-59 (quoi faire maintenant : écrire à la direction, lien de contact) ; clés arabes.

### E8. Identité `/inscription/identite` : session, sans profil
- Fichier : `lib/features/inscription/etapes/identite_etape.dart`. Captures : `la2_identite_390x844_light.png`, `la2_identite_1440x900_light.png`.
- Défauts : champs de 1136 px sur bureau (1.2) ; pour le tuteur, aucune phrase ne dit à quoi sert le nom (`:71-75`, explication réservée à l'enseignant).

### E9. Genre `/inscription/genre` : session, sans profil
- Fichier : `lib/features/inscription/etapes/genre_etape.dart`. Captures : `la2_genre_390x844_light.png`, `la2_genre_1440x900_light.png`.
- Défauts : deux cartes de 560 x 220 sur bureau, radio isolé en coin (1.1, 1.2) ; aucune raison donnée au tuteur (`:35`), alors que la question est sensible (K-58).
- Correction : une phrase de raison pour tous les rôles ; cartes compactes sur bureau.

### E10. Récapitulatif `/inscription/recapitulatif` : session, sans profil
- Fichier : `lib/features/inscription/etapes/recapitulatif_etape.dart`. Captures : `la2_recapitulatif_*`, `la2_recapitulatif_erreur_390x844_light.png`, `la2_recapitulatif_actualisation_390x844_light.png`.
- Défauts : la réponse « Suivez-vous aussi des cours ? » n'y figure pas (E6) ; identité et genre portent la même icône profil (`:184`, `:193`).

### E11. Portail d'attente `/attente` : forcé
- Fichier : `lib/features/dossier/attente_page.dart`. Captures : `la3_attente_390x844_light.png`, `la3_attente_1440x900_light.png`, `audit_attente_tuteur_*`, `audit_attente_enseignant_*`.
- Défauts : hub qui renvoie un texte à la fois (1.4) ; bouton « Lire » ambigu (`fr.i18n.json:793`, `lireLaCarte`, contrôle `libelle-ambigu`) ; « Il reste 2 éléments à fournir » dit à un tuteur qui n'a rien à fournir, seulement à accepter.
- Correction : un seul bouton « Lire et accepter nos conditions » vers la page unique `/attente/accords` ; le hub ne garde que l'état.

### E12. Accusé `/attente/accuse` : forcé
- Fichier : `lib/features/dossier/signature_page.dart:85-98`. Captures : `audit_accuse_tuteur_*`, `audit_accuse_enseignant_*`.
- Défauts : aucune case, « J'ai lu » vaut signature ; texte d'enregistrement audio contraire à la décision du 11/10 ; texte répété au contrat (1.4).

### E13. Contrat `/attente/contrat` (tuteur, adulte `?pour=moi`, enseignant) : forcé
- Fichiers : `lib/features/dossier/signature_page.dart:126-178`, `lib/features/recrutement/signature_contrat_page.dart` (enseignant quand le port serveur est branché). Captures : `audit_contrat_tuteur_*`, `audit_contrat_tuteur_refus_390x844_light.png`, `audit_contrat_enseignant_*` (la capture `la3_contrat_*` du dépôt est fausse : le test `test/capture/la3_dossier_capture_test.dart:144-163` ne surcharge pas `serviceDossierProvider` et échoue sur Supabase non initialisé ; défaut du test, pas de l'app).
- Défauts : bouton actif sans case cochée puis reproche (`:346`) ; marge de la carte de la case inerte (1.1) ; titre « Ce que vous signez » au-dessus d'un texte déjà lu ; arabe : `contrat.a3.*`, `contrat.e1.*`, `contrat.clauseControle.*`, `contrat.politique.*`, `contrat.resignature` absents de `ar.i18n.json`.

### E14. Pièce d'identité `/attente/piece` (enseignant) : forcé
- Fichier : `lib/features/dossier/depot_piece_page.dart`. Captures : `audit_piece_enseignant_390x844_light.png`, `audit_piece_enseignant_1440x900_light.png`.
- Défauts : aucun retour ni « Se déconnecter » (`PageShell` sans `onRetour`, `:138`) ; « Envoyer ma pièce » actif sans photo puis reproche (`:106-110`) ; types de pièce sans explication et « Autre pièce » sans précision (`:215-236`) ; cartes de choix dans une carte.

### E15. Seconde étape du contrôleur `/controleur/mfa` : forcé (compte actif)
- Fichier : `lib/features/mfa_controleur/mfa_controleur_page.dart`. Captures : `audit_mfa_controleur_*` (squelette seulement : le port MFA lit Supabase, non surchargeable dans ce test). D'après le code, les cinq états sont présents (`:231-247`). Pas de défaut relevé.

### E16. Nouvelle signature de l'enseignant `/enseignant/contrat` : forcé (compte actif)
- Fichiers : `lib/core/router/redirection.dart` (`_resignature`), `signature_page.dart:166-178`. Pas de capture (route ouverte seulement sous `resignatureContratEnseignantProvider`). Mêmes défauts que E13.

### E17. Ajout d'un profil élève `/tuteur/foyer/ajouter` : onboarding famille
- Fichier : `lib/features/foyer/formulaire_profil_eleve.dart`, routé par `lib/features/appareils/ajouter_enfant_page.dart`. Captures : `ajout_*_390x844@3_light.png`, `ajout_*_1440x900@1_light.png`.
- Défauts : âge en années (1.3) ; seul écran d'entrée à colonne bornée sur bureau, mais avec la barre latérale du tuteur : changement de gabarit au milieu du parcours.

### E18. Parcours `/tuteur/parcours/:eleveId` : onboarding famille, 7 questions
- Fichier : `lib/features/parcours_offres/parcours_offres_page.dart`, gabarit `lib/core/widgets/page_parcours.dart`. Captures : `la4_*`.
- Défauts : âge en tranche, posé une seconde fois (1.3) ; options sans phrase (1.2 bis) ; gabarit différent de l'inscription (lien texte « Retour », « Étape 1 sur 7 », temps restant) alors que l'inscription a un disque retour et « 1 sur 4 » ; sur la page des horaires, le bouton plein est « Retour à l'accueil » (`:663`, `:716`) alors que l'action est de choisir un horaire ; « Continuer » grisé tant qu'on n'a pas choisi.
- Correction : retirer la question d'âge (déduite de E17) ; un seul gabarit d'étape pour E6 à E10, E17 et E18 (`PageEtape` borné) ; bento sur bureau.

### E19. Accord « visites des parents » `/tuteur/compte/consentements`
- Fichier : `lib/features/consentements/consentement_observation_page.dart`. Captures : `la3_consentements_*`, `la3_consentements_signe_390x844_light.png`.
- Défauts : troisième lieu de consentement ; `InviteConsentementObservation` (`:269`) jamais posé : un compte existant n'est conduit nulle part.

### Transverses
- Trois gabarits d'étape et trois façons de compter (« 1 sur 4 », « Étape 1 sur 7 », « 2 sur 2 ») : `page_etape.dart`, `page_parcours.dart`, `formulaire_profil_eleve.dart`.
- Bouton qui attend une condition : grisé à l'inscription et au parcours, actif puis reproche aux accords et à la pièce. Une seule règle à fixer (voir 1.4).
- Arabe : 7 clés `bienvenue`, ~50 clés `contrat`, ~80 clés `recrutement` absentes (relevé par comparaison des deux fichiers JSON).

## 3. Plan de lots

Ordonnés, indépendants : deux lots ne touchent jamais le même fichier, sauf ceux marqués « après ». Chaque lot visuel passe par une fiche `UX_REVIEW_<lot>.md` (DESIGN-GOV §4) et ses captures 390 et 1440.

| Lot | Objet | Fichiers touchés | Dépend de |
| :--- | :--- | :--- | :--- |
| **L0 Décisions** | Faire trancher : (a) bouton « Suivant » inactif jusqu'à complétude malgré BOUTONS-GRISES-1 ; (b) âge : tranche partout ; (c) texte d'enregistrement audio des accords | `docs/current/` (décision datée), `tool/revue_socle.txt` si (a) | aucun |
| **L1 Cible et état des cartes** | Coche en tête côté `start`, fond au survol, carte entière lisible comme cible ; case d'accord en carte pressable | `lib/core/widgets/choice_card_group.dart`, `lib/features/consentements/texte_observation.dart`, tests `test/core/widgets/choice_card_group*_test.dart` | aucun |
| **L2 Bento des choix** | `OptionChoix.exemple`, `OptionChoix.illustration`, disposition bento au-delà de 900 px, assets d'illustration | `lib/core/widgets/choice_card_group.dart`, `lib/core/widgets/grille_bento.dart`, `assets/illustrations/` (à créer) | après L1 (même fichier) |
| **L3 Gabarit d'étape unique** | `PageEtape` borné sur bureau, bouton à largeur de contenu au bord `end`, `PageParcours` remplacé par `PageEtape` | `lib/core/widgets/page_etape.dart`, `lib/core/widgets/page_parcours.dart` | aucun |
| **L4 Présentation et connexion** | Deux chemins distincts (créer / se connecter), sorties en bas, bento sur bureau, encre d'erreur | `lib/features/bienvenue/bienvenue_page.dart`, `lib/features/connexion/connexion_page.dart` | aucun |
| **L5 Inscription** | Textes d'explication (genre, identité), sous-question oui / non intégrée ou retirée, `Ecart`, exemples des options | `lib/features/inscription/**` | après L2 (pour les exemples) |
| **L6 Page unique des accords** | `/attente/accords` qui défile, une case par texte, un bouton ; `/attente` réduit à l'état ; route ajoutée | `lib/features/dossier/signature_page.dart`, `lib/features/dossier/attente_page.dart`, `lib/core/router/app_router.dart`, `lib/core/router/routes.dart` | après L0 (a, c) |
| **L6b Accords côté serveur** (ChatGPT) | Acceptations groupées ; persistance de l'usage « moi / famille » et de « suit des cours » | `supabase/**`, `lib/core/dossier/service_dossier*.dart` | en parallèle de L6 |
| **L7 Pièce d'identité** | Retour et déconnexion, envoi seulement avec photo (ou règle L0 a), explication des types | `lib/features/dossier/depot_piece_page.dart` | après L0 (a) |
| **L8 Âge unique** | Tranche à l'ajout du profil, question d'âge retirée du parcours, options du parcours expliquées | `lib/features/foyer/formulaire_profil_eleve.dart`, `lib/features/parcours_offres/parcours_offres_page.dart`, `lib/features/parcours_offres/libelles_parcours.dart` | après L0 (b) ; dérivation en base par le backend |
| **L9 Invite des comptes existants** | Poser `InviteConsentementObservation` sur l'accueil du tuteur | `lib/features/accueil_famille/accueil_famille_page.dart` | après L6 (texte final) |
| **L10 Libellés** | Clés arabes manquantes, nouveaux libellés de L4 à L9 déclarés dans `tool/libelles_sources.json` | `assets/i18n/fr.i18n.json`, `assets/i18n/ar.i18n.json`, `lib/core/i18n/strings*.g.dart` (régénérés), `tool/libelles_sources.json` | en dernier (fichiers partagés par tous les lots : chaque lot écrit ses clés dans une liste, L10 les fusionne) |
| **L11 Tests de capture** | Réparer `test/capture/la3_dossier_capture_test.dart` (surcharge du dossier) et ajouter les captures des nouveaux écrans | `test/capture/**` | après L6 |

Parallélisables d'emblée : L1, L3, L4 (et L0 côté directeur). Puis L2 et L6 / L6b. Puis L5, L7, L8, L9. L10 et L11 ferment.
