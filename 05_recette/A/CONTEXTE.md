# Contexte condensé — Lot A (Admission)

Écrit une fois (25/09) pour éviter à chaque agent suivant de relire les sources. Lire d'abord ; ne rouvrir une source que pour un point précis.

## 1. Mandat des 4 sous-paquets (05_LOTS_PHASE1.md:42-49) et « fait »

Références du lot : maquettes `onboarding Mble.png`, `onboarding Mble d.png`, `onboarding mobile
1.png`, `Onboarding mobile 2.png`, `mobile/tuteur observation mobile light.png` (M6, consentement) ;
manifeste §1 lignes 10-17 et 23, §6 ; `02_code/C03_admission.md` ; mapping lignes 1-7, C1, C2, C3,
C7, C11.

- **LA-1** Bienvenue, connexion, récupération (`/bienvenue`, `/connexion`, `/connexion/recuperation`).
  Renvoyer le lien, lien expiré/déjà utilisé, accès appareil élève discret, états envoi/attente/erreur.
  **Livré partiel** (fbb603d) : code fait, reste tests de widget par gestes + captures + preuve
  (etat/B.md:19).
- **LA-2** Inscription par étapes (`/inscription/usage|identite|genre|recapitulatif`). Deux cartes
  d'usage EXACTEMENT (textes ci-dessous), en-tête d'étape (retour 48 dp, « n sur N » calculé), CTA
  pilule, aucune présélection, erreurs sous les champs, double soumission bloquée, déconnexion
  possible, impasse après `refreshSession` corrigée, récapitulatif avec « Modifier » par ligne.
  **Non commencé** (aucune ligne LA-2 dans etat/B.md).
- **LA-3** Dossier `/attente` (accusé, contrat, pièce) refondu ; statut exact + UNE prochaine action ;
  nouvelle version du texte signé ; invite comptes existants `/tuteur/compte/consentements` ; texte
  « Comment ça marche ? » en clés `consentement.*` paramétrées. **Livré partiel** (9a5c3a6) : code
  fait (attente, signature, consentements) ; reste tests de widget par gestes + captures + preuve
  (etat/B.md:21) ; texte à valider par le directeur avant fusion (P2).
- **LA-4** Questionnaire par élève `/tuteur/parcours/:eleveId` : branches serveur seulement (aucun
  code interne), prénom en contexte, retour sans perte, reprise ; `0043` non appliqué en production
  → indisponible honnête ; appeler `renoncer_intention_horaire` avant un nouveau choix ; enchaînement
  fin d'admission → `/tuteur/foyer/ajouter` (route seule, aucun import du lot B). **Non commencé**.

**Définition de « fait »** (05_LOTS_PHASE1.md:32, 03_DECISIONS §1 ter bis.1) : fichier atteignable
depuis `lib/main.dart` (graphe_imports.ps1) ; un bouton/onglet/lien y mène (hors routeur, hors
tests) ; **un test qui appelle `routeur.go()` seul ne prouve rien** — il faut un test qui TAPE le
bouton depuis la navigation ; captures 390x844 et 1440x900 clair ET sombre, planche maquette|rendu
si maquette existe, écarts corrigés.

## 2. Décisions du directeur qui priment (03_DECISIONS_COORDINATEUR.md)

- **§1 bis.3** (l.23) : paragraphe de consentement d'observation en mots clairs et bienveillants (qui
  observe, ce qu'il entend/voit, ce qu'il ne peut pas faire, pourquoi, limites de visites). Nouvelle
  version du texte signé = **texte existant INCHANGÉ** (notice d'enregistrement comprise) **+** ce
  paragraphe. Variantes responsable légal / élève adulte. Case non précochée.
- **§1 bis.2** (l.22) : `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. »
  (valeur `3cf3544`) — texte gelé. `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse`
  inchangés. Toute variante issue de `33503fe` doit être rétablie.
- **§1 bis.4** (l.24) : quota **par parent, 2 par défaut par séance** ; visite écourtée consommée ;
  valeurs lues depuis la politique effective, **jamais codées en dur** (`consentement.comment.*`,
  déjà fait en LA-3 depuis `GuardianObservationPolicy`).
- **§1 ter.1** (l.30-31) : les high-fi font autorité pour le **layout** (sections, colonnes,
  emplacement exact de chaque bouton/action, route ouverte) ; **pas pour la palette** (idée générale
  seulement — couleurs = jetons gelés) ; une fonction = un seul endroit, carte des fonctions
  obligatoire.
- **§1 ter.3** (l.34) : carte groupée = UN rectangle, filet en retrait (`groupe_reglages`/équivalent) ;
  jamais un rectangle par ligne.
- **§1 ter.4-5** (l.35-36) : navigation/retour niveau 2/déconnexion toujours accessibles, aucune
  impasse (testé) ; web = vraie desktop (rail dès 600, barre latérale dès 1200), jamais mobile étiré.
- **§1 ter bis.2** (l.46) : `.order(...)` sans `ascending` trie DÉCROISSANT côté PostgREST — préciser
  `ascending` partout et tester l'ordre.
- **§1 ter bis.4** (l.49) : ne jamais toucher `lib/core/coran`, `lib/core/tc_coran`,
  `lib/features/tc_mushaf` ; défaut découvert → ligne dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md`.

**Textes exacts imposés (mandat A, 05_LOTS_PHASE1.md:47)** — cartes d'usage, SANS carte « Autre » :
- « Moi uniquement » : « Je souhaite suivre les cours avec mon propre profil élève. »
- « Moi et ma famille » : « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez
  créer votre propre profil élève à tout moment. »
- Lien discret : « Je suis enseignant ».
(Textes de `onboarding Mble.png`, « Convient à une personne… » / « Convient aux familles… », plus
anciens : le mandat écrit et §1 ter.1 priment sur la maquette pour le texte ; la maquette prime pour
la disposition en 2 cartes + case radio + description + CTA pilule.)

**Notice d'enregistrement audio** (à conserver mot pour mot) : « Cours enregistré, visite de contrôle
possible. » — clé `salle.bandeauPermanent`, valeur `3cf3544`. Vérifier après tout merge de base que
`33503fe` n'a pas réintroduit une autre formulation.
**Clés signées intouchables** : tout texte du contrat accepté (`versions_contrat.dart`,
`signature_page.dart`) est déjà signé par des comptes réels en simulation ; une nouvelle version de
texte = nouvelle entrée `VersionsContrat`, jamais une réécriture de l'ancienne (`lib/core/dossier/
versions_contrat.dart:1-40`, modifié en LA-3, 9a5c3a6).

## 3. Fichiers, i18n, imports interdits

**Fichiers du lot A** (00_OWNERSHIP.md §3, l.55-63) :
- Existants possédés : `lib/features/connexion/connexion_page.dart`,
  `lib/features/inscription/inscription_page.dart`,
  `lib/features/dossier/{attente_page,signature_page,depot_piece_page}.dart`,
  `lib/features/parcours_offres/{parcours_offres_page,bloc_parcours,libelles_parcours}.dart`,
  `lib/core/dossier/{service_dossier,etat_dossier,versions_contrat,service_validation,
  selecteur_fichier}.dart`, `lib/core/offres/{offre_horaire,service_offres}.dart`,
  `lib/core/profil/service_acceptations.dart`.
- À créer : `lib/features/bienvenue/bienvenue_page.dart`, `lib/features/connexion/recuperation_page.
  dart`, `lib/features/inscription/etapes/{usage,identite,genre,recapitulatif}_etape.dart`,
  `lib/features/inscription/brouillon_inscription.dart`, `lib/features/consentements/{texte_
  observation,explication_observation,consentement_observation_page}.dart`, `lib/core/capacites/
  consentements_supabase.dart` (port K6 `PortConsentements`). LA-1/LA-3 ont déjà rempli tout sauf
  `lib/features/inscription/**` (LA-2) et le branchement LA-4.
- Tests : `test/features/{connexion,inscription,attente,dossier,dossiers_sans_piece}_test.dart`,
  `test/parcours/**`, nouveaux `test/features/admission/**`.
- Lecture seule : `lib/core/auth/service_auth.dart` (demande à COORD pour tout changement), contrat
  K3 (formulaire B), K4 (politique effective).
- Non-régression : tunnel inscription enseignant (même écran) ; `libelles_parcours.dart` est importé
  HORS lot A par `lib/core/tc_parcours/port_travail_a_venir.dart` et
  `lib/features/tc_flux_academique/{bloc_avant_prochain_cours,feuille_signalement,
  panneau_post_cours}.dart` — **aucune signature publique retirée sans demande COORD**.

**i18n, espaces de noms lot A** (00_OWNERSHIP.md §4, l.131) : `bienvenue.*`, `connexion.*` (hors
`connexion.feuilleAppareil.*`, propriété D), `inscription.*`, `attente.*`, `accuse.*`, `contrat.*`,
`parcours.*`, `consentement.*`. Règle générale §4 : ajouter localement, ne pas committer
`fr.i18n.json`/`*.g.dart`, déposer un fragment pour COORD — mais LA-1 et LA-3 ont déjà committé
`fr.i18n.json` et le généré sur `ui/tuteur-v1-a` (fbb603d, 9a5c3a6) : continuer cette méthode déjà en
place, ne pas changer en cours de lot.

**Imports interdits / à surveiller** (00_OWNERSHIP.md §6 bis, l.171-179) :
- `texte_observation.dart`, `explication_observation.dart` (lot A) sont **repris par C-obs** via des
  clés i18n `consentement.*` paramétrées (pas d'import Dart direct) — ne pas casser leur forme sans
  vérifier C-obs.
- Le lot A **n'importe jamais** `CarteChoixFoyer` (fichier du lot B,
  `lib/features/foyer/formulaire_profil_eleve.dart:636`) même si elle est publique : ce n'est pas un
  fichier du lot A (00_OWNERSHIP §3). Voir §7 ci-dessous (B-3).
- Jamais `lib/core/theme/**`, `lib/core/router/**`, `lib/core/widgets/**`,
  `lib/core/capacites/port_*.dart`, contrats K1-K7, `supabase/`, `.github/`, `vercel.json`,
  `pubspec.yaml`, `assets/fonts`, Coran (règle générale, rappelée ici pour le lot A).

## 4. Routes du lot (00_MAPPING_ROUTES.md)

- Légende (l.1-7) : états possibles **absent / présent à perfectionner / présent conforme / démo** ;
  `DB-xxx` → `00_DEPENDANCES_BACKEND.md`, `Kx` → `00_CONTRATS_PARTAGES.md`.
- **C1** (l.85) Consentement d'observation, nouveaux comptes → `/attente/contrat`
  (`signature_page.dart`), étape du dossier, case non précochée, texte paramétré par la politique
  effective. Lot A. DB-ADM-02 ; point directeur P2.
- **C2** (l.86) Consentement, comptes existants → aucune route actuelle aujourd'hui (compte actif
  n'entre plus dans `/attente`) ; nouvelle route `/tuteur/compte/consentements` (écran A, route posée
  par COORD). DB-ADM-03 ; non activé avant décision P2.
- **C3** (l.87) « Comment ça marche ? » → intro statique de `choix_entree_observation.dart` (C-obs
  aujourd'hui) ; à terme état de `/tc/observation/:seanceId` avant « Entrer », texte fourni par A,
  intégré par C-obs ; le compteur ne démarre pas avant confirmation.
- **C7** (l.91) `/tuteur/parcours/:eleveId` = questionnaire + offres, déplacé dans Foyer (R6). Lot A.
  DB-ADM-01.
- **C11** (l.95) `/attente/*` = portail dossier, refonte visuelle complète. Lot A.

## 5. Contrats/ports consommés, dépendances backend

- **K3** (00_CONTRATS_PARTAGES.md:203-241) Formulaire élève partagé : le lot A **consomme**
  l'enchaînement vers `/tuteur/foyer/ajouter` (LA-4) mais ne construit pas le formulaire (lot B,
  `formulaire_profil_eleve.dart`, dès que K3 est figé). `BrouillonProfilEleve`, bornes d'âge client
  3-18 (`ajouter_enfant_page.dart:44`), pas d'idempotence serveur.
- **K4** politique effective d'observation (00_CONTRATS_PARTAGES.md:288+) : lue par
  `explication_observation.dart` et `consentement.comment.*` (déjà branché en LA-3).
- **K6** ports/adaptateurs (00_CONTRATS_PARTAGES.md:469+) : `PortConsentements` implémenté par
  `consentements_supabase.dart` (LA-3, fait).
- **DB-ADM-01** (00_DEPENDANCES_BACKEND.md:33) Questionnaire/offres : `0043` non appliqué en
  production → bloc parcours inerte (`bloc_parcours.dart:46-48`). LA-4 affiche un état « questionnaire
  pas encore disponible » explicite, aucune tranche/langue codée en dur.
- **DB-ADM-02** (l.34) Consentement enregistrable : dépend de P2 ; ne rien enregistrer de faux (déjà
  respecté en LA-3 via `accepterContrat` existant).
- **DB-ADM-03** (l.35) Re-consentement comptes existants : RPC serveur manquante ; écran
  `/tuteur/compte/consentements` construit et testé en simulation, **non activé** avant P2 (LA-3
  fait ; `demandes/A.md:13`, A-3 bloque l'accès par bouton).
- **DB-ADM-04** (l.36) Ajout d'élève avant validation du dossier : refusé tant que `pending_kyc`
  n'ouvre pas `creer_profil_enfant` — concerne l'enchaînement LA-4 → foyer.
- **DB-ADM-05** (l.37) cohortes d'âge : lire les tranches du serveur, ne jamais en coder ; âge affiché
  seulement s'il est fourni.
- **DB-ADM-06** (l.38) branche débutant/diagnostic LA-4 : afficher le statut rendu par le serveur,
  jamais réécrire « il reste un échange avec un enseignant » pour tous.
- **DB-ADM-07** (l.39) retour natif lien courriel/Google : non testable mobile natif (fichiers
  plateforme = COORD) ; web fonctionnel (déjà le cas LA-1).
- **DB-ADM-08** (l.40) changer d'horaire (LA-4) : `renoncer_intention_horaire` avant
  `choisir_offre_horaire` (voie frontend retenue, `0043` non appliquée).

## 6. Maquettes ouvertes (chemins exacts, poste B)

Racine : `C:\RA\pilotage\lancement\tutuor image\`.
- `onboarding Mble.png` — mobile sombre, étape 2/5 « Quel type de compte souhaitez-vous créer ? »
  (LA-2, usage) : 2 cartes empilées (icône ronde, titre, description, radio à droite), sélection en
  halo violet + bordure pleine, CTA pilule « Continuer → » en bas, barre de progression sous le
  disque retour, « 2 sur 5 » à droite.
- `onboarding Mble d.png` — mobile sombre, étape 3/5 « genre » : 2 cartes CÔTE À CÔTE (icône ronde
  centrée, titre centré, radio en haut à droite) ; même en-tête et CTA.
- `onboarding mobile 1.png` — clair, 3 écrans : 01/Compte (2 cartes empilées, textes « Pour apprendre
  et suivre mes cours. » / « Les cours, les appareils et les paiements de la famille, au même
  endroit. »), 02/Genre (2 cartes côte à côte), 03/Âge (champ numérique unique, pas de tranche). CTA
  « Suivant → » sauf dernier écran. Barre « n sur 6 » : gabarit ancien à 6 étapes (+langue +objectif) ;
  le mandat écrit ne retient que usage/identité/genre/récapitulatif (4 étapes) — suivre le mandat
  pour la LISTE des étapes, la maquette pour le GABARIT (en-tête, carte, CTA).
- `Onboarding mobile 2.png` — suite : 04/Langue, 05/Objectif (cartes radio en liste, icône par choix),
  06/Continuité = récapitulatif façon `ligne_cle_valeur` (icône, libellé gris, valeur en gras, filets)
  + « Modifier mes réponses » + « Continuer → » : référence directe de `recapitulatif_etape.dart`.
- `mobile/tuteur observation mobile light.png` — planche M1-M6 claire ; écran 6 « Les visites des
  parents » : icône ronde, titre gras, 2 paragraphes explicatifs, case « J'accepte ces modalités pour
  mon enfant » NON PRÉCOCHÉE, CTA désactivé tant que non coché, lien « Retour » sous le CTA. Gabarit
  du paragraphe de consentement déjà écrit en LA-3 (`texte_observation.dart`) — vérifier case/CTA/retour.

## 7. Composants partagés disponibles et contournements

- `lib/core/widgets/groupe_reglages.dart` (COORD, phase 0c1) : carte groupée à filets, seul composant
  admis pour une liste groupée (règle §1 ter.3). Utilisé en LA-3 pour `/attente/accuse` et
  `/attente/contrat`.
- `lib/core/widgets/ecran_resultat.dart`, `lien_fleche.dart`, `ligne_cle_valeur.dart`,
  `controle_segmente.dart`, `app_bottom_sheet.dart` (0c1_composants.md:18) : `ligne_cle_valeur.dart`
  est la référence directe du récapitulatif LA-2 (icône/libellé/valeur, cf. §6 ci-dessus).
- **B-3** (`demandes/B.md:24`, `demandes/A.md:13`) : `PageShell` rend les actions de la coquille
  au-dessus de la rangée d'étape (pas de mode plein écran) ; `ChoiceCardGroup` n'a ni description ni
  option désactivée. Le lot B a contourné en écrivant une carte de choix privée dans
  `formulaire_profil_eleve.dart` — **elle est en réalité publique** (`class CarteChoixFoyer extends
  StatelessWidget`, corrigé par LB-F) mais reste un fichier du lot B. **Le lot A ne l'importe pas**
  (fichier hors 00_OWNERSHIP §3 du lot A) : écrire un contournement LOCAL PRIVÉ équivalent dans les
  fichiers d'étape du lot A (`lib/features/inscription/etapes/usage_etape.dart` notamment, pour la
  carte à description + option désactivée), à migrer plus tard vers le `ChoiceCardGroup` enrichi que
  COORD promet. Citer B-3 dans le commit/rapport si ce contournement est utilisé.
- `PageShell` : composant coquille existant (COORD, `lib/core/widgets` — lecture seule) ; l'en-tête à
  actions n'est pas encore branchée (0c1_composants.md:79, `EntetePage`) — ne pas attendre ce
  branchement pour livrer LA-2.

## 8. Commandes exactes (poste B)

Commande lourde, toujours sous verrou, depuis n'importe où :
```
& C:\RA\pilotage\outils\flutter-verrou.ps1 -Dossier C:\RA\lot-a -Commande "<commande>"
```
- Analyse ciblée : `-Commande "dart analyze --fatal-infos lib/features/inscription test/features/inscription_test.dart"`
- Tests ciblés : `-Commande "flutter test test/features/inscription_test.dart test/features/connexion_test.dart test/features/dossier_test.dart test/router/navigation_test.dart"` (+ `test/parcours/**`,
  `test/i18n`, `test/config` selon ce qui est touché ; jamais la suite complète).
- Jetons : `-Commande "dart run tool/verifier_jetons.dart"`. slang : `-Commande "dart run slang"`.
- Captures (`test/capture/LISEZ-MOI.md`, D: → `C:\RA\pilotage\05_recette\A\captures`) :
  `$env:CAPTURE_DIR = "C:\RA\pilotage\05_recette\A\captures"` puis flutter-verrou sur
  `flutter test --no-pub test/capture/<test_du_lot>.dart --reporter expanded`, puis
  `Remove-Item Env:\CAPTURE_DIR`. `CAPTURE_MAQUETTE` = chemin PNG maquette ; `CAPTURE_LARGEUR_
  LOGIQUE` = 390 (mobile) ou 1440 (bureau).
- Graphe d'imports (lecture seule, hors verrou) :
  `powershell -NoProfile -ExecutionPolicy Bypass -File C:\RA\pilotage\06_registre\outils\
  graphe_imports.ps1 -Repo C:\RA\lot-a -Ref <commit>` (défaut `-Repo` = poste A : **toujours passer
  `-Repo C:\RA\lot-a`**).

## 9. Pièges connus

- **BOM** : ne jamais écrire un message de commit via `Set-Content` (BOM vu sur d7b006f, lot B) ;
  `git commit -m "..."` directement.
- **`.order()` sans `ascending`** : PostgREST trie décroissant par défaut. `service_offres.dart:
  115,125` (`.order('ordre')` sans `ascending`, fichier du lot A) déjà relevé par le lot B (etat/B.md,
  constats LB-3) — corriger si LA-4 le touche, sinon consigner (déjà consigné, ne pas redoubler).
- **Vocabulaire interdit** : « Session », « Cours en cours », « Ajouter enfant », « mode enfant »,
  « groupe » à l'écran, codes internes. Imposés : « Classe », « Séance », Sayyid/Sayyida, « Interface
  guidée », « Ajouter un profil élève ».
- **`libelles_parcours.dart`** (§3, l.63) : importé par C, aucune signature publique retirée sans
  demande COORD.
- **`refreshSession`** : LA-2 doit corriger une impasse déjà identifiée après `refreshSession` ; à
  creuser dans `service_auth.dart` (lecture seule) et `inscription_page.dart` existant.
- **Texte du contrat à valider par le directeur avant fusion (P2)** : LA-3 l'a laissé en attente
  (etat/B.md:21) — ne pas fusionner sans confirmation.
- **`?pour=moi`** : LA-2 doit le passer vers `/attente/contrat` pour un élève adulte (etat/B.md:21).
- **Worktree existant** : modifications non commitées dans `fr.i18n.json` → garder seulement celles
  des espaces de noms du lot A (§3).
