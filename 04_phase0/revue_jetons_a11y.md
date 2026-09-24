# Revue indépendante phase 0 : jetons, typographie, palette, accessibilité, non-régression des autres rôles

Date : 24/09/2026, 13:50 à 14:35 (+03:00). Relecteur adversarial, **lecture seule**.
Objet : branche `ui/tuteur-v1`, `3cf3544..125fe78` (24 commits, rapports `0a`, `0b`, `0c1`, `0c2`, `0d`).
Statut de preuve : « testé en simulation » (tests de widget, captures sous `flutter test` avec les vraies polices). Rien n'est « vérifié réellement » (aucun appareil, aucun navigateur).

## 0. Méthode, commandes, état laissé

- Lu : `BRIEF.md`, `03_DECISIONS_COORDINATEUR.md`, les 5 rapports `04_phase0`, `lib/CLAUDE.md`, `docs/current/03`, le diff `3cf3544...HEAD` (thème, polices, widgets partagés, coquille, préférences, vérificateur).
- Deux worktrees **jetables et détachés** : `D:\RA_REVUE_TMP\base` (`3cf3544`) et `D:\RA_REVUE_TMP\head` (`125fe78`, HEAD isolé des fichiers non commités de 0a). Tests temporaires dans `test/_revue_tmp/` (non suivis), jamais dans `D:\RA_TUTEUR\integration`. Ensuite : dossiers de test supprimés, `windows/flutter` rétabli, `git worktree remove` x2, `git worktree prune`. Le dossier **vide** `D:\RA_REVUE_TMP` subsiste (suppression refusée par la protection de l'outil) : à retirer à la main.
- `D:\RA_TUTEUR\integration` : `git status` identique avant et après (reprise 0a toujours non commitée), HEAD `125fe78` inchangé.

| # | Commande (sous `flutter-verrou.ps1` sauf n° 1) | Résultat |
|---|---|---|
| 1 | `dart contrastes_revue.dart <palette base> <palette head>` (script hors Flutter, lit les sources) | sortie complète : `captures_revue_a11y/sources/contrastes_sortie.txt` |
| 2 | `flutter pub get --offline` (base puis head) | `Got dependencies!` x2 |
| 3 | `flutter test --no-pub test/_revue_tmp/revue_capture_test.dart` base puis head (`REVUE_DIR`, `REVUE_PREFIXE`) | `+9: All tests passed!` x2, puis `--name "eleve direct"` `+3` x2 |
| 4 | `flutter test --no-pub test/_revue_tmp/revue_mesures_test.dart` (head) | `+3: All tests passed!` (mesures ci-dessous) |
| 5 | HEAD isolé : `dart run tool/verifier_jetons.dart && flutter test --no-pub test/theme test/widgets/nav_shell_adaptatif_test.dart test/widgets/composants_test.dart test/router/parcours_enseignant_test.dart test/features/{accueil_eleve,journee,creneaux,tableau_de_bord}_test.dart test/config test/accessibilite` | code 0, `03:30 +262: All tests passed!` (première mesure de HEAD sans les fichiers non commités de 0a ; K7 passe) |

Sources des tests temporaires conservées hors dépôt : `04_phase0/captures_revue_a11y/sources/`.

## 1. Défauts

| ID | Gravité | Fichier:ligne | Preuve | Correction attendue |
|---|---|---|---|---|
| D1 | **majeur** | `lib/core/widgets/nav_shell.dart:467-471`, `:731-735`, `:814-817` | Trois `copyWith(fontWeight: ...)` sans toucher l'axe `wght` (la base n'en avait **aucun** hors `app_typography.dart`). Mesure à 40 px, vraies polices (test n° 4) : `labelMedium` + `w600` (onglet actif de la barre basse) = largeur 696,1 et 5 769 px d'encre, **identiques** au style non modifié (le vrai `wght 600` donne 703,3 / 6 843) ; `titleLarge` + `w700` (mot-symbole) = 687,4 / 6 546, **identiques** (vrai 700 : 698,9 / 7 259) ; `bodyLarge` + `w600` (libellé actif de la colonne) = même largeur 684,7 mais encre 4 740 -> 6 951 : **faux gras synthétisé** sur `wght 400` ; l'inactif `w500` sort en 400. Coquille partagée : élève, enseignant, tuteur. Contredit `app_typography.dart:253-254` et `controle_segmente.dart:28`. `verifier_jetons` n'a aucune règle `fontWeight`. | Un utilitaire `AppTypography` qui pose `fontWeight` ET `wght` (en gardant `opsz`), employé aux 3 endroits ; règle du vérificateur « `fontWeight:` hors `app_typography.dart` » ; test de rendu. |
| D2 | **majeur** (arbitrage directeur) | `lib/core/widgets/nav_shell.dart:522-523` (`choix ?? gabarit == Gabarit.tablette`) | Tablette 600-1199 : rail **replié, icônes seules**, pour **tous** les rôles. Captures `avant/apres_enseignant_journee_1024_clair.png` : la base affichait « Journée / Créneaux / Profil » sous les icônes, HEAD n'affiche plus que 3 icônes et un bouton de dépli. `test/router/parcours_enseignant_test.dart:174-180` a été réécrit pour l'accepter. Décisions §3.6 ne visent que la navigation tuteur. | Rail à libellés (ou déplié) par défaut pour les rôles non tuteur tant que le directeur n'a pas validé sur capture. |
| D3 | **majeur** (arbitrage directeur) | `lib/core/widgets/action_principale.dart:229-230`, `lib/core/theme/app_theme.dart:103-116` | CTA doux appliqué à l'élève, y compris en Interface guidée : « Rejoindre » passe de `#8652E6` / blanc à `#DCCAFD` / `#110E20` (`avant/apres_eleve_direct_390_{standard_clair,guidee_clair}.png`). Texte 12,56:1 (conforme), mais le bouton ne se détache plus de sa carte : 1,51:1 (contre 4,81:1 avant). C'est la seule action de l'écran d'un enfant. | Décision explicite du directeur sur capture ; à défaut, garder un CTA à 3:1 contre sa surface en Interface guidée. |
| D4 | mineur | `lib/features/journee/journee_page.dart:453-460` ; `lib/features/tc_espace_groupe/carte_session.dart:128`, `:195`, `:222` ; `lib/features/cahier/cahier_page.dart:325` | Compte à rebours (« Dans 1 h 59 », capture enseignant), heures « 14:00 · ville », « dans 12 min », durée : en `titleMedium`/`titleSmall` donc DM Sans, sans `tnum`. Décisions §3.4 : horaires et chronomètre en `chiffre`. Absents de la liste 0b §6.3. | `AppTypography.tabulaire(...)` à ces 5 endroits ; compléter la liste 0b §6.3. |
| D5 | mineur | `lib/core/theme/app_theme.dart` (aucun `tabBarTheme`) ; `lib/features/creneaux/creneaux_page.dart:138`, `lib/core/widgets/sous_navigation_domaine.dart:55` | Le `TabBar` M3 prend `titleSmall` par défaut : onglets « Mes heures / Élèves en attente » (enseignant) et sous-navigation admin en **DM Sans** (`apres_enseignant_creneaux_390_clair.png`). Libellés de navigation = Jakarta (§3.4). | `tabBarTheme` avec `labelStyle` / `unselectedLabelStyle` = `labelLarge`. |
| D6 | mineur | `lib/core/widgets/marque_page.dart:23-29` | Mot-marque « Rewayah » (`Semantics(header: true)`) en `displaySmall` = Jakarta 700, alors que le mot-symbole de la colonne est en DM Sans (`nav_shell.dart:727-735`). Écrans : connexion, connexion élève, attente, signature, dépôt, démarrage (`etats_routeur.dart:174`), tous rôles. Demandé par 0b §6.3, non fait. | `headlineLarge` (DM Sans). |
| D7 | mineur | `test/theme/support/contraste.dart:88-103` | La matrice ne teste une encre de rôle que sur **son** fond doux. Calcul sur toutes les paires : sombre `inkAlert #F4777D` sur `washWarning #44361A` = **4,35** (9,09 à la base) ; clair `inkFaint` sur `washAccent` = 4,45. Aucun usage trouvé par recherche (non exhaustive) : risque, pas défaut visible. | Étendre la matrice aux `wash*` (ou interdire ces paires), corriger l'`inkAlert` sombre ou le documenter. |
| D8 | mineur | `lib/core/widgets/status_pill.dart:123-129` | Les points de statut validés à 3:1 (`pointsStatut`) ne sont pas utilisés par `StatusPill`, présent partout : la pastille « En direct » reste `#70EE9C` sur `#E4F4EB` = 1,28:1 (captures élève en direct). Le libellé double le point, donc WCAG n'est pas en défaut. | `_pastille` -> `palette.pointsStatut.*.pastille()`. |
| D9 | mineur (typographie, tous rôles) | polices `PlusJakartaSans-Variable.ttf` | Apostrophe droite en Jakarta : chasse 9,9 px à 40 px (0,25 em), **plus large qu'une espace** (6,9 px). Rendu lu « s 'ouvre », « l 'heure » (`apres_enseignant_journee_390_clair_texte200.png`, serré à la base). U+2019 mesure 10,9 px : la passe A12 (apostrophes typographiques) ne corrigera **pas** l'effet. | Arbitrage directeur sur capture (accepter, ou revoir le choix de police du corps). |
| D10 | mineur (déjà connu, confirmé) | `lib/core/preferences/preferences_locales.dart:239-244` | Web = `StockagePreferencesMemoire` : le choix clair / sombre (et le repli de colonne) est perdu à chaque rechargement sur la cible de production. Appliqué au `MaterialApp` (`lib/app.dart:52`) : oui. Persisté sur le web : non. | Options web de Drift (0b §6.4-1) ou autre stockage non sensible. |
| D11 | mineur (doc) | `lib/CLAUDE.md:45-46`, `:58-59` | Toujours périmés à HEAD : « `inkFaint` interdit sur `surfaceSunken` (4,48) » (mesuré 4,65) et piège « Bricolage `wght` 800 » (police retirée). | Réécriture COORD (formulation de 0b §6.3). |

## 2. Vérifié conforme

- Polices : 4 familles de texte + 2 d'icônes dans `pubspec.yaml` ; `NotoSansArabic`, `UthmanTahaNaskh`, `Phosphor-Regular`, `Phosphor-Fill` et leurs licences **identiques à l'octet** (`git diff --quiet 3cf3544 HEAD`) ; `AppTypography.document()` inchangé.
- Aucun `fontFamily` hors `app_typography.dart` / `app_icons.dart` (recherche) ; aucune couleur littérale ajoutée hors `app_palette.dart` (recherche sur les lignes ajoutées du diff) ; aucun rayon littéral ajouté.
- Styles **effectifs après `ThemeData`** (standard et Interface guidée, mesure n° 4) : `headline*`/`title*` en DMSans avec `wght` = graisse et `opsz` = taille ; `body*`/`label*`/`display*` en PlusJakartaSans avec `wght`.
- Contrastes (script n° 1) : les 17 paires fond / texte >= 4,5 dans les deux thèmes (minimum clair `surfacePrimary` 4,81, sombre `surfaceActionDouce` 7,29) ; aucune régression sous 4,5 sur les 5 surfaces neutres ; 32 + 32 teintes d'identité inchangées (minimum 4,57 / 4,55) ; `surfaceQuran` figée (`#F3EAD9`/`#1C1D21`, `#2E2417`/`#F5F1E9`).
- Rayons : boutons et champs `sm` (`app_theme.dart:27`, `:60`), cartes `md` ; CTA `principale` sur `surfaceActionDouce`.
- Thème réellement appliqué : `lib/app.dart:52`.
- Captures élève et enseignant, base contre HEAD : aucun écrêtage ni chevauchement nouveau, y compris à 200 % ; libellés de barre basse bornés à 150 % (la barre M3 de la base les bornait plus bas).

## 3. Captures (`04_phase0/captures_revue_a11y/`, préfixes `avant_` = `3cf3544`, `apres_` = `125fe78`)

`eleve_accueil_390_{clair,sombre,clair_texte200}`, `eleve_accueil_1440_sombre`, `eleve_direct_390_{standard_clair,guidee_clair,guidee_sombre}`, `enseignant_journee_390_{clair,sombre,clair_texte200}`, `enseignant_journee_1024_clair`, `enseignant_creneaux_390_clair` (12 paires, 24 PNG). 21 relues ; non relues : `avant_`/`apres_enseignant_journee_390_sombre`, `avant_eleve_direct_390_guidee_sombre`.

Limites : données fictives du harnais, vrai routeur, vrai thème, polices réelles ; les horaires diffèrent de 5 min entre les deux passes (heure de lancement) ; ni admin ni contrôleur capturés (`AdminShell` inchangé ; ADM-01/02/06 à 200 % verts sur HEAD isolé, n° 5) ; aucun appareil réel.
