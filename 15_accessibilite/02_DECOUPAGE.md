# Mode Accessibilité : découpage en étapes (MA-0 à MA-RC)

## Où et comment

- **Branche proposée** `ui/accessibilite-v1`, à créer depuis `ui/enseignant-v1` au dernier commit `verifie` au moment de MA-1b (aujourd'hui 1108a4a), dans un nouveau worktree `C:\RA\accessibilite`.
  - Pourquoi cette base : c'est la plus récente ; elle contient la salle unique et la préparation CL-4, l'`EmplacementEntree`, les extensions enseignant de `/salle`, les préférences locales (`animationsReduites`, `lectureGrande`, `raccourcisSalle`) et `/demo/classe`, `/demo/salle`, `/demo/enseignant`. Partir de `ui/classe-v1` obligerait à refaire les fusions des widgets partagés déjà touchés par la vague Enseignant.
  - Prudence : la vague Enseignant commite encore dans `C:\RA\enseignant`. On ne touche pas à ses fichiers ; les widgets partagés (`action_principale`, `groupe_reglages`, `nav_shell`) ne reçoivent que des ajouts minimes, notés pour la future fusion (modèle `13_fusion`).
- **Un seul agent qui committe à la fois** dans ce worktree (K-30), tâches de moins de 35 minutes (K-16).
- **Modèles.** Opus pour le design et le code d'écran. Sonnet pour les tests, captures, preuves et la revue de lecture. Haiku pour les écritures du tableau.
- **Démonstration seulement** (K-35), sans serveur (K-28) :
  - les fournisseurs réels restent en place ;
  - la démonstration les surcharge par `/demo/accessibilite?ecran=…&etat=…&profil=enfant|adulte&mode=accessibilite|standard`, gardée par `environnementAutoriseDemo` ;
  - tout besoin serveur devient une ligne de `15_accessibilite/MA-BR.md` (BR-1).
- **Réutiliser, sans fork** : `InterfaceMode` (aucune nouvelle énumération), `preferencesLocalesProvider`, `lib/core/mouvement`, `NavShell` et `destinationsPour`, `EmplacementEntree`, `ActionPrincipale`, `AppCard`, `GroupeReglages`, `AppBottomSheet`, `PhotoEnseignant`, `PhotoEleve`, `BlocAsynchrone` + `Skeleton`, `OfflineBanner`, `EtatSysteme`, `outil_capture.dart`.
- **Définition de « fait »** (K-7) : écran atteint depuis la vraie coquille et un test tape le vrai bouton ; `analyze` à 0 ; suite complète relancée après la dernière correction (K-29) ; captures 390, 768 et 1440, clair et sombre, **et texte à 200 %** ; relues par l'orchestrateur avant `verifie`.
- **Interdits** : main, PR, supabase/ (lecture seule), .github/, vercel.json, pubspec.yaml ; thème et couleurs (K-37, tout besoin → ligne TH-2) ; le rendu du Coran ; les secrets ; `dart format` sur un dossier (K-23) ; toute traduction avant LG-1 (K-41) ; renommer `InterfaceMode` ou sa valeur SQL.

## Les étapes

| Étape | Contenu | Réutiliser, sans fork | Modèle, durée | Dépend de |
|---|---|---|---|---|
| **MA-0** | Préparation : copie du doc et des planches, comparaison, rectifications, règles MA1 à MA24, découpage, reprise. | — | fait (27/09) | — |
| **MA-1a** | `UX_REVIEW_06_ACCESSIBILITE.md` (DESIGN-GOV §4) : WCAG 2.2 AA (2.4.7, 2.4.11, 2.5.7, 2.5.8, 1.4.4, 1.4.10, 2.3.3), W3C COGA, Material 3 et Android (48 dp), Apple HIG (Dynamic Type, Reduce Motion), Flutter (Semantics, TextScaler, MediaQuery.disableAnimations), ICO Children's Code. Sources datées, décision par écran. Vérifier aussi à qui s'affiche « Le tuteur de {prenom} observe la séance ». Document seulement, **obligatoire avant tout code**. | modèle `12_enseignant/UX_REVIEW_04_ENSEIGNANT.md` | Opus, 30 min | MA-0 |
| **MA-1b** | Socle, en quatre parties (détail sous le tableau). | `InterfaceMode`, `preferencesLocalesProvider`, `demo_classe_page.dart`, `outil_capture.dart` | Opus, 35 min | MA-1a |
| **MA-2** | Navigation élève à 4 destinations dans les deux présentations (MA17) : Accueil, Ma classe, Coran, Mon espace ; libellés toujours visibles ; barre, rail, barre latérale. Fin du « aucune destination » en mode enfant. « Suivi » atteint depuis Ma classe. | `NavShell`, `destinationsPour` | Opus, 35 min | MA-1b |
| **MA-3** | Accueil élève en Mode Accessibilité (MA18, planches 1 et 3) : ordre du doc §5, emplacement unique, 3 tâches au plus, Coran, aide ; deux colonnes sur bureau ; retraits (cloche, décor, pastille « Aujourd'hui »). | `AccueilElevePage`, `EmplacementEntree`, `GroupeReglages`, `PhotoEnseignant` | Opus, 35 min, puis Sonnet tests et captures | MA-2 |
| **MA-4** | Ma classe avant la séance (MA19, planche 1) : identité, photo, heure locale, durée, une ligne d'état qui devient « Rejoindre », mention tablette, À préparer (3 au plus), support. Préparation guidée CL-4 revue au style (une question, une action, 200 %). | fiche de Classe élève, `preparation_eleve.dart`, `EmplacementEntree` | Opus, 35 min | MA-3 |
| **MA-5** | Salle pendant la séance (MA20, planches 2 et 4) : support dominant, chrome réduit, suivi automatique, commandes avec texte, « Quitter » destructif existant, observation (textes existants), réseau calme ; sans navigation d'app ni Lever la main, Discussion, Participants ; mise en page bureau. | `vue_seance.dart`, `vignette_video.dart`, `zone_support.dart`, `vue_salle.dart` | Opus, 35 min, puis seconde passe si besoin | MA-4 |
| **MA-6** | Après la séance (MA21, planche 2) : « Cours terminé », travail (3 au plus), « Revoir le support du cours », prochaine séance ; sans « Très bien », sans confettis. | `resultat_seance.dart`, `EcranResultat` | Opus, 30 min | MA-5 |
| **MA-7** | Coran (MA22, planche 1) : contrôles autour du rendu (Précédent, Suivant avec texte ; taille moins/plus ; mode verset ; reprise ; hors ligne expliqué). **Rendu intouché.** | `tc_mushaf`, `vue_verset_agrandi.dart`, `navigation_coran_feuille.dart` | Opus, 35 min | MA-2 |
| **MA-8** | Mon espace (MA24, planche 2) : identité sans âge, ligne « Mode Accessibilité » (bascule démo pour l'adulte ; état en lecture pour le mineur, sans fausse demande), « Préférences d'affichage » avec les libellés existants, aide honnête, appareils. | `compte_page.dart`, `GroupeReglages`, `aide_page.dart` | Opus, 35 min | MA-2 |
| **MA-9** | Côté tuteur et enseignant : page « interface » du profil (`interface_page.dart`) aux nouveaux termes, sans description d'âge ; libellé de `fiche_seance.dart` selon la réponse Q6. | `InterfaceElevePage`, `ChoiceCardGroup` | Opus, 30 min | MA-8 |
| **MA-10** | Lexique (MA3) : « mode enfant » et « Interface guidée » remplacés dans les seuls textes visibles de `fr.i18n.json` ; identifiants de code inchangés ; arabe laissé à LG-1. | — | Sonnet, 30 min | MA-9 |
| **MA-11** | Passe technique transverse : états chargement, vide, erreur, hors ligne, permission sur chaque écran MA ; focus visible et clavier intégral sur web ; ordre `Semantics` ; cibles ≥ 48, 52 à 56 sur les majeures ; `Mouvement.duree` partout. | `BlocAsynchrone`, `Skeleton`, `OfflineBanner`, `EtatSysteme`, `test/accessibilite/clavier_test.dart` | Opus, 35 min | MA-3 à MA-10 |
| **MA-12** | Recette, détail sous le tableau. | `captures_cl47_test.dart`, `test/accessibilite/rtl_echelle_texte_ecrans_test.dart` | Sonnet, 35 min, en deux agents si besoin | MA-11 |
| **MA-R** | Revue croisée par une autre session : contre MA1 à MA24, E1 à E20 (salle), R1 à R21, K-42, DESIGN-GOV, et les 8 risques du doc §12. | modèle `05_recette/CL/REVUE_CL-4.md` | Opus, 30 min | MA-12 |
| **MA-RC** | Corrections de la revue, puis la planche web du directeur (format CL-4 : Téléphone, Tablette, Ordinateur ; Clair, Sombre ; plus une bascule « Texte 200 % »), publiée par l'orchestrateur. | — | Opus, 35 min | MA-R |

**Détail de MA-1b, le socle.**
1. **Réglage du mode** : lecture de la présentation depuis `InterfaceMode` existant (profil élève), avec une surcharge de démonstration ; aucune nouvelle énumération, aucune écriture serveur.
2. **Fournisseur** : un fournisseur dérivé unique qui combine présentation (`InterfaceMode`), `animationsReduites`, `MediaQuery.disableAnimations` et le facteur de texte, lu par les écrans ; pas de second état concurrent.
3. **Données de démonstration** `lib/features/demo/accessibilite_demo.dart` : Mariam (mineure), un élève adulte fictif, Classe An-Nour, Sayyid Ibrahim, séances de septembre et octobre 2026, travail (3 au plus), états avant, pendant et après la séance, observation active ou non (00_MAQUETTES §4).
4. **Route** `/demo/accessibilite`, gardée par `environnementAutoriseDemo`.
5. **Squelette de captures** `test/features/accessibilite_recette/captures_ma_test.dart` (390, 768, 1440 ; clair, sombre ; 1,0 et 2,0 de texte ; animations réduites).

**Détail de MA-12, la recette.**
1. Tests partant de la vraie coquille pour chaque bouton, dans les deux présentations.
2. Captures 390, 768, 1440, clair et sombre, texte à 200 %, RTL simulé, pour chaque écran et ses cas (avant, pendant, après ; observation ; hors ligne ; mineur et adulte).
3. **Lecteur d'écran** : tests de l'arbre `Semantics` (libellés, ordre, une annonce par changement) ; essai TalkBack sur le téléphone Android du directeur, si le débogage USB est actif (sinon consigné).
4. **Animations réduites** : test avec `MediaQuery(disableAnimations: true)` et avec la préférence locale ; aucune durée non nulle.
5. Clavier intégral et focus visible sur web ; aucune couleur seule ; zoom ; orientation.
6. Rapport `05_recette/MA/MA_RAPPORT.md` en français simple ; besoins serveur `15_accessibilite/MA-BR.md` ; lignes TH-2 relevées.

## Lignes à porter au tableau (hors vague)

- **BR-1** : écriture de la présentation par l'élève adulte ; politique et contrat des demandes d'un mineur (DB-FOY-04) ; valeur par défaut par cohorte (6-9 au lieu de 6-8) ; message de l'enseignant à l'élève après la séance (si retenu) ; nom de la valeur SQL `child` ; canal d'aide (DB-CPT-07).
- **TH-2** : contraste de la lavande des boutons et des lignes teintées (vert « Support ») en Mode Accessibilité, clair et sombre ; indication de focus.
- **HU-1** : les écrans standard élève déjà faits s'harmonisent avec MA-2 à MA-8 en une seule passe.
- **MA-UT** (future) : tests avec de vrais utilisateurs (profils du doc §13), avec consentement UK GDPR et Children's Code, après BR-1.

## Ordre et dépendances

1. MA-1a, puis MA-1b (MA-1a est obligatoire avant le code).
2. MA-2, puis MA-3 → MA-4 → MA-5 → MA-6 dans l'ordre ; MA-7 et MA-8 peuvent suivre MA-2 en parallèle d'une autre session documentaire, mais un seul agent committe.
3. MA-9, puis MA-10.
4. MA-11, puis MA-12.
5. MA-R, puis MA-RC.

Chaque étape passe par `fait` avec preuve (commit, tests, captures), relecture des captures par l'orchestrateur, puis `verifie`.

## Questions au directeur (choix provisoire appliqué, on continue)

| N° | Question | Choix provisoire | Étapes |
|---|---|---|---|
| Q1 | Les 4 destinations du doc (Accueil, Ma classe, Coran, Mon espace) remplacent-elles aussi celles de l'élève standard (Accueil, Coran, Suivi, Compte) ? | Oui, les mêmes pour les deux présentations ; Suivi atteint depuis Ma classe ; routes inchangées. | MA-2, HU-1 |
| Q2 | Les libellés venus des planches seulement (« Préférences d'affichage », « Vous suivez le support automatiquement », « Cours terminé », « Travail pour la prochaine fois », « Revoir le support du cours », « À lire aujourd'hui ») sont-ils validés ? | Repris tels quels en démonstration, les libellés existants priment quand la fonction existe déjà. | MA-3 à MA-8 |
| Q3 | Taille des cibles en Mode Accessibilité : 52 à 56 (doc) ou 72 (ancien mode enfant) ? | Jetons existants de `app_metriques.dart` gardés s'ils font au moins 52. | MA-1b, MA-11 |
| Q4 | Garde-t-on la phrase « Qu'Allah facilite ton apprentissage » sous la salutation ? | Non : salutation d'une ligne seulement (K-42). | MA-3 |
| Q5 | Le réglage « Aide audio » de la planche doit-il exister ? | Seulement s'il pilote la clé audio existante ; sinon retiré. | MA-8 |
| Q6 | L'enseignant doit-il voir qu'un élève utilise le Mode Accessibilité (risque de révéler un handicap) ? | Oui, sans raison ni diagnostic, en libellé neutre « Mode Accessibilité », comme l'existant. | MA-9 |
| Q7 | Veut-on une traduction française sous les versets, comme sur les planches ? | Non dans cette vague : rendu du Coran intouché. | MA-7 |
| Q8 | L'élève reçoit-il un « Message de votre enseignante » après la séance ? | Non affiché tant que le contrat ne le prévoit pas (ligne BR-1). | MA-6 |
| Q9 | Où est `06_ELEVE_ENFANT.md`, dans lequel le doc doit être intégré ? | On avance sur le doc 06 recherche seul. | toutes |
| Q10 | Quel texte décrit le Mode Accessibilité au tuteur et à l'adulte ? | Celui de la planche : « Une interface simplifiée et adaptée pour un apprentissage plus serein. » | MA-8, MA-9 |
| Q11 | Un mineur peut-il demander la présentation standard (« Demander une interface classique ») ? | Non affiché avant la politique et son contrat (DB-FOY-04). | MA-8 |
