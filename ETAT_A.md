# État annoncé par le poste A (coordinateur)

## 25/09/2026 : nouvelle base origin/ui/tuteur-v1 @ 92f5cf7 (animations sobres P2-16)

- **Nouvelle base commune poussee : `origin/ui/tuteur-v1` @ `92f5cf7`** (fusion `--no-ff` de `origin/ui/tuteur-v1-anim` sur `f93272b`, commit `92f5cf7`, sans conflit).
- Contenu ajoute (P2-16) : socle de mouvement partage `lib/core/mouvement/` (durees 150-300 ms, courbes `easeOutCubic`/`emphasized`, respect de `MediaQuery.disableAnimations`) ; transitions de page glissees (`app_router.dart`, sens RTL/LTR) ; fondu court sur `AppCard`, `ChoiceCardGroup` (selection), `BlocAsynchrone` (changement d'etat) ; echelonnement des 8 premiers elements (Catalogue des classes, Hub du compte, lignes de l'Historique) ; soulignement d'onglet anime une fois.
- Revue adversariale courte (poste B) avant fusion : aucune animation en boucle hors indicateurs de chargement, `Mouvement.reduit`/`disableAnimations` verifie sur chaque composant anime, `RepaintBoundary` pose autour de ce qui s'anime, `AnimationController` de `FonduOnglet` correctement `dispose()`, toutes les durees <= 300 ms (`Mouvement.maximum`). Rien a corriger.
- Verification sous verrou (poste B coordinateur, P2-16) : `flutter analyze --fatal-infos` **aucun probleme** ; suite complete `flutter test` **2723 tests, 0 echec, 572 ignores, code 0**.
- Frontiere `git diff --stat origin/ui/tuteur-v1..HEAD -- supabase .github vercel.json pubspec.yaml` (apres fusion) : **vide**.

## 25/09/2026 : nouvelle base origin/ui/tuteur-v1 @ f93272b (finitions du role tuteur, P2-08 a P2-13, ROLE TUTEUR V1 TERMINE cote frontend)

- **Nouvelle base commune poussee : `origin/ui/tuteur-v1` @ `f93272b`** (fusion `--no-ff` de `origin/ui/tuteur-v1-fin` sur `2e0fb7a`, commit `f93272b`, sans conflit).
- Contenu ajoute par le lot de finitions : icones femme/homme/horloge (HL-B-1), catalogue des classes avec jours/heures/fuseau (HL-B-2, C-14), accessibilite 200%/RTL des ecrans K du lot teaching_core, scanner bord a bord sur telephone, chaque route du tuteur rattachee a un test qui presse un vrai bouton, catalogue de classes en mode demonstration.
- Verification finale sous verrou (poste B coordinateur, P2-13) : `flutter analyze --fatal-infos` **aucun probleme** ; suite complete `flutter test` **2710 tests, 0 echec, code 0** (journal `04_phase0/final_tests.log`) ; `flutter build web` **reussi** (aucune valeur `dart_define` requise).
- Frontiere `git diff --stat origin/ui/tuteur-v1..HEAD -- supabase .github vercel.json pubspec.yaml` (avant fusion, sur `ui/tuteur-v1-fin`) : **vide**.
- Ecrans/parcours couverts par le lot de finitions P2-08 a P2-13 : plus aucun defaut bloquant ni majeur ouvert dans les revues P2-08 a P2-11 (fidelite aux maquettes, parcours et routes, mobile/tablette/desktop/accessibilite, securite et honnetete). Mineurs restants non traites, sans impact fonctionnel : P2-08 m1, P2-10 m4, P2-11 M1/M2.
- **Points ouverts (reportes, hors perimetre poste B ou en attente du directeur)** : actions encore adossees a Supabase non simulees en mode demonstration (compte, appairage, offres, reglages) ; ports capacites consentements/identite/notifications/paiements/progression/resume/support encore Indisponible en demo ; C-14 : catalogue etendu cote application seulement, aucune source serveur des classes ouvertes (DB-CRS-07) ; mise en ligne d'un apercu (deploiement) hors du droit du poste B seul.
- **Ou trouver les choses (sans jargon)** : le bouton de demonstration est explique dans `05_recette/demo/OU_TROUVER_LA_DEMO.md` ; toutes les images de verification (captures d'ecran) sont listees dossier par dossier dans `05_recette/OU_TROUVER_LES_CAPTURES.md`.

## 25/09/2026 : nouvelle base origin/ui/tuteur-v1 @ 2e0fb7a (mode demonstration P2-07 integre)

- **Nouvelle base commune poussee : `origin/ui/tuteur-v1` @ `2e0fb7a`** (fusion `--no-ff` de `origin/ui/tuteur-v1-demo` @ `bb51374` sur `bd51224`, commit `2e0fb7a`, sans conflit).
- Contenu ajoute : socle du mode demonstration tuteur (P2-07) — `lib/features/demo/mode_demonstration.dart`, `observation_demo.dart`, `presence_demo.dart`, `repere_demonstration.dart`, `racine_demonstrable.dart` ; entree « Essayer la démonstration » depuis `/bienvenue` et `/connexion` ; jamais actif en production (garde double : variable d'environnement hors « prod » ET `?demo=tuteur`).
- Verification sous verrou (poste B coordinateur) : `flutter analyze --fatal-infos` **aucun probleme** ; suite complete `flutter test` **2691 tests, 0 echec, code 0** (466 s).
- Frontiere `git diff --name-only 20731a4..HEAD` contre `supabase/ .github/ vercel.json pubspec.yaml assets/fonts lib/core/theme dart_define.json` : **vide**.
- Aucun conflit i18n/slang a la fusion.
- **Points ouverts (reportes du mode demo, non traites ici)** : actions encore adossees a Supabase non simulees en mode demo (serviceAppairageProvider, portStatutCodeAppairageProvider, serviceAuthProvider, services parcours_offres/reglages_enfant, avatarUrlProvider) ; ports capacites consentements/identite/notifications/paiements/progression/resume/support encore Indisponible en demo ; controle visuel de l'apercu deploye non fait.

## 25/09/2026 : nouvelle base origin/ui/tuteur-v1 @ bd51224 (lots B, A, C, E, O integres, coordination poste B)

- **Nouvelle base commune poussee : `origin/ui/tuteur-v1` @ `bd51224`** (tous les lots B, A, C, E, O fusionnes et integres).
- Suite complete `flutter test` sous verrou (poste B coordinateur) : **+2677 tests, 0 echec, code 0**. Journal : `04_phase0/integration_finale_25-09_tests.log`.
- Frontiere `git diff --stat origin/ui/tuteur-v1..HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme` : **vide**.
- Corrections integrees a cette base : B-5 (route perimee appareils, 20731a4), C-INT-1 (`portClassesFoyerProvider` revenu a l'indisponible par defaut, adaptateur Supabase branche dans `main.dart`, 7212a0d), O-INT-1 (`entree_observation_navigation_test.dart` reecrit depuis l'Accueil reel -> Voir la classe -> `t.classe.observer`, 24f0b0f + bd51224).
- Tableau : P2-01, P2-02, P2-03, P2-04, P2-06 passes a `fait` avec preuve ; P2-05 deja `fait` (`ae34143`). Lignes L*-* `fait` par une session anterieure passees a `verifie` (`verifie_par` : `B-2026-09-25-coord`). LA-3 : motif reduit a « texte signe a valider par le directeur (P2) », la ligne Consentements (`e82ec66`) etant deja dans la base.
- **Points ouverts** (non traites ici, hors perimetre ou en attente du directeur) :
  - Texte de consentement a valider par le directeur (P2).
  - C-14 : contrat K6 gele (seances/parcours d'une classe ouverte), decision directeur requise.
  - O-4 : icone horloge/sablier non traitee (m4).
  - Icone femme absente du catalogue (lot A, demandes/A.md).

## 25/09/2026 : lots C, E, O poussés par sécurité (demande du poste B)

- `origin/ui/tuteur-v1-c` @ `4d37dc9` : 11 commits + 1 commit `wip(lot-c): EN COURS` (fichiers laissés par un agent coupé : non revus, non testés). `REVUE.md` du lot existe (5 majeurs M1–M5), corrections non faites.
- `origin/ui/tuteur-v1-e` @ `d33aca4` : 11 commits, aucun fichier en cours, pas encore de revue.
- `origin/ui/tuteur-v1-o` @ `9bfbb6a` : 4 commits + 1 commit `wip(lot-o): EN COURS` (sous-paquet O3 « fins et états » entamé : non revu, non testé).
- Frontière contrôlée avant envoi : aucun fichier `dart_define`, `.env`, `supabase/`, `.github/`, `vercel.json`, `pubspec`. Les fichiers `windows/flutter/generated_*` (fins de ligne seulement) ne sont pas committés.
- La question « le poste B devient-il coordinateur ? » attend la décision du directeur.

## 25/09/2026 : nouvelle base `origin/ui/tuteur-v1` @ `1cbc760` (réponses aux demandes, lot D intégré)

- **Nouvelle base commune : `origin/ui/tuteur-v1` @ `1cbc760`** (poussée). Contenu depuis `cefab7f` : les réponses aux demandes (5 commits), la fusion du lot D `ae34143` (`origin/ui/tuteur-v1-d` @ `f799ade`), puis la bascule du QR `1cbc760`.
- Vérification complète sous verrou : `dart analyze --fatal-infos` (dépôt entier) sans problème ; `verifier_jetons` 424 fichiers sans violation ; **suite complète 2241 tests verts, 0 échec** (229 captures sautées sans `CAPTURE_DIR`) ; frontière `supabase`, `.github`, `vercel.json`, `pubspec.yaml` vide. Journal : `04_phase0/integration_lotD_tests.log`.

## Réponses aux demandes

| Demande | Réponse | Commit |
|---|---|---|
| B-1 (meneur dans `GroupeReglages`) | **Fait.** `LigneRubrique.meneur` (`Widget?`) rendu à la place de l'icône, filet au même retrait ; `icone` facultative, assertion `icone != null \|\| meneur != null`. | `c950607` |
| B-2 / D-2 (tri `paired_at`) | **Fait.** `.order('paired_at', ascending: false)` (plus récent d'abord). Aucun autre `.order(` dans `lib/core/appairage`. Garde lexicale `test/appairage/tri_explicite_test.dart` (le client Supabase n'est pas simulable sans nouvelle dépendance). | `5445d97` |
| B-3 / A-2 (gabarit d'étape, choix) | **Fait.** `PageShell(actionsCoquille: false)` : ni cloche ni bascule. Nouveau `lib/core/widgets/page_etape.dart` : `PageEtape(numero, total, onRetour, child, action)` (rangée V6 en première ligne : disque retour 48, progression continue, « n sur N » lu « Étape n sur N », clés `commun.etape.*` ; action collée en bas, `ActionPrincipale(pilule: true)` permise) et `RangeeEtape` publique (panneau bureau, dialogue). `OptionChoix(description, disponible = true, raisonIndisponible)` (défaut `commun.choix.indisponible`) ; radio dessiné `RadioChoix` (anneau ≥ 3:1, testé clair et sombre) en sélection unique, coche conservée en sélection multiple ; carte « Autre » et `autoriserSaisieLibre` inchangés. | `6c6aef9` |
| B-4 (`/tuteur/reglages`) | **Fait.** Alias vers `/tuteur/foyer` (mapping C6) ; `ReglagesEnfantPage` n'est plus montée par le routeur. Conséquence : les liens des lots C (`accueil_famille_page.dart`, `destination: Routes.tuteurReglages`) et E (`compte_page.dart`, `context.push(Routes.tuteurReglages)`) aboutissent au Foyer tant qu'ils ne sont pas mis à jour. | `9bed664` |
| D-1 (paire QR) | **Fait.** `AppPalette.contenuQr` (fond `#FFFFFF`, encre `#110E20`), identique en clair et en sombre. Ajout pur, aucun jeton existant ne change. Test de contraste. | `1614d28` |
| D-3 (retour de l'émetteur) | Information notée, aucun changement. La fiche (lot B) appelle `Routes.appairerPour(id)` + `?retour=<chemin de la fiche>`. | — |
| A-1 (visiteur vers `/bienvenue`) | **Non appliqué maintenant** : l'écran `/bienvenue` n'existe que sur `ui/tuteur-v1-a`. Sera appliqué à l'intégration du lot A. | — |
| A-3 (port des consentements) | Hors de cette passe ; traité à l'intégration du lot A (branchement du port) et avec le lot E (entrée dans le Compte). | — |
| R-08 (scanner et gouttière de `PageShell`) | **Accepté, écart justifié, `PageShell` inchangé.** Le scanner n'a pas de maquette propre ; la référence la plus proche (M3 #20) pose elle-même son contenu avec des marges. Si le directeur veut un scanner bord à bord, `PageImmersive` (gabarit partagé sans gouttière) existe déjà : ce serait un changement du lot D, pas de `PageShell`. | — |

Bascule faite par COORD à l'intégration du lot D : `EmetteurQr.paire` retiré, le QR lit `contenuQr` (`1cbc760`).

## Consignes aux postes

- **Poste B** : fusionner `origin/ui/tuteur-v1` @ `1cbc760` dans le lot en cours (et dans `ui/tuteur-v1-b` avant sa fin), puis migrer les contournements vers les composants partagés :
  - `_RangeeEtape` et le haut de page de l'ajout de profil : `PageEtape` / `RangeeEtape` ;
  - `_Radio` et `CarteChoixFoyer` (formulaire K3 et `fiche/interface_page.dart`) : `ChoiceCardGroup` avec `OptionChoix.description`, `disponible`, `raisonIndisponible` (`autoriserSaisieLibre: false` si aucune réponse libre) ;
  - icône profil des lignes du Foyer (`ligne_membre.dart`) : `LigneRubrique(meneur: AvatarTile(...))` ;
  - lot A : ses contournements locaux d'étape et de choix, même migration.
- **Lots C et E (poste A)** : remplacer les liens vers `Routes.tuteurReglages` (`accueil_famille_page.dart`, `compte_page.dart`) par la destination de la fiche ou du Foyer ; la route n'est plus qu'un alias du Foyer.
- Ordre d'intégration suivant : B, puis A (avec A-1 et A-3), C, E, O au fil de leurs fins de lot.
