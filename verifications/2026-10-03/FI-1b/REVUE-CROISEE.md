# FI-1b-R : revue croisée de `ui/finance-v1` @ `af9f408b`

Revue en lecture seule, 03/10/2026. Worktree détaché `D:\RA_TUTEUR\r-fi1b` (HEAD `af9f408bf31a…`). Diff relu : `git diff 7c612872..af9f408b` (merge-base avec `origin/corrections/revue-directeur-2026-10`), 14 fichiers. Aucun code modifié, aucun commit, aucun push. Le test de capture temporaire a été retiré ; `windows/flutter/generated_*` restaurés ; `git status` vide à la fin.

## Verdict : **accepté**

Aucun défaut bloquant ni majeur. Trois défauts mineurs, deux constats hors périmètre (code partagé non touché par FI-1b). L'écart DEMO-ENV-1 (compilation sans `ENVIRONNEMENT`) n'est pas compté, comme demandé.

## Ce qui est conforme

| Point | Preuve |
|---|---|
| Domaine Finance actif, onglets dans l'ordre des sources | `lib/core/admin/admin_domaine.dart` : `finance => Routes.adminFinance` ; `ongletsFinance()` = « Vue globale » `/admin/finance`, « Politiques commerciales » `/admin/finance/politiques`. Conforme à `17_finance/02_DECOUPAGE.md:30` (ligne FI-1b), `UX_REVIEW_08_FINANCE.md:80-81, :91, :297`. Direction reste seul à `null`. |
| Page neutre, sans valeur commerciale ni chiffre | `lib/features/admin_finance/finance_page.dart` : `EtatSysteme(nature: indisponible)`, textes existants « Pas encore disponible » / « Cette fonction n'est pas encore ouverte. » ; aucun montant, aucun bouton. Le champ `dependance` (« FI-1c, FI-11a… ») n'est ni affiché ni lu (`etat_systeme.dart:77`, et les captures le confirment). |
| `/demo/finance` absente en production | `lib/features/demo/demo_finance_page.dart:23` : `if (!environnementAutoriseDemo(environnement)) return const []` ; porte `redirection.dart` ; tests `routesDemoFinance('production')`, `' Production '`, `''` vides, `deciderRedirection` fermée en production (log `03_tests.log`, « /demo/finance absente en production… » passé). |
| Libellés déclarés | `assets/i18n/fr.i18n.json` : `admin.finance.vueGlobale`, `admin.finance.politiques` ; les deux clés sont dans `tool/libelles_sources.json` avec leur source (guide V4 §2, §5.6, §5.7, maquettes 09/10, revue FI-1a :297). `verifier_revue` identique base/tête (contrôle adverse, 1662 = 1662, sorties identiques). |
| Rien hors périmètre | `git diff --name-only` : ni `pubspec`, ni `supabase/`, ni `.github/`, ni thème, ni Coran. Recherche dans les lignes ajoutées : aucun `skip`, aucune `Color(`, `Colors.`, ni code hexadécimal. |
| Aucune régression routeur/admin/widgets | Relancé moi-même sous le verrou : `flutter test test/router test/widgets test/features/admin_configuration admin_dossiers admin_finance admin_observations admin_pedagogie_programmes admin_coque_test.dart` → **`04:10 +631: All tests passed!`**, aucun sauté (`D:\RA_TUTEUR\yaaden-cache\FI-1b-R\03_tests.log`). |
| K-07 : « Finance » tapé depuis la vraie coquille | Mon test de capture temporaire (vrai `routeurProvider`, `surchargesDemoAdmin('staging')`) tape « Finance » dans la barre 288 (1440) et dans le tiroir (320, 390), puis l'onglet « Politiques commerciales » : routes relevées `/admin/finance` puis `/admin/finance/politiques` dans les 14 cas, **0 exception** (débordement compris) dans les 14 cas (`02_captures.log`). |

## Captures (K-61)

Dossier : `D:\RA_TUTEUR\captures\FI-1b-R_2026-10-03\` (hors dépôt), 37 PNG. Variantes : 320×693 et 390×844 (densité 2, zone sûre 47/34), 1440×900 ; clair et sombre ; texte ×1 et ×2 ; RTL forcé à 390 et 1440 (clair, ×1). Pour chaque cas : tiroir ouvert (mobile), Vue globale, Politiques commerciales. Ouvertes moi-même :

- `fi1b_1440x900_x1_light_1vue.png` : haut = titre « Vue globale » à 48, disque retour, recherche, thème, compte, repère « Démonstration » ; gauche = barre 288, Finance sélectionné ; droite = vide de x≈1120 à 1440 ; bas = pied « Administrateur ». Onglets segmentés, carte « Pas encore disponible » détachée de 20 px sous les onglets. Rien ne déborde.
- `fi1b_1440x900_x2_dark_2politiques.png` : haut = titre « Politiques commerciales » sur une ligne ; gauche = barre, Finance actif ; droite = vide ; bas = pied « Administrat / eur » coupé (voir H1). Onglet actif encadré, contraste lisible en sombre.
- `fi1b_1440x900_x2_light_1vue.png` : même constat, pied « Administrat / eur ».
- `fi1b_1440x900_x1_light_rtl_2politiques.png` : barre à droite, titre aligné à droite avec flèche retour miroir, onglets inversés, carte en miroir ; bords sains. Le point avant « .Cette fonction » vient du texte français forcé en RTL (bidi), pas d'un défaut.
- `fi1b_390x844_x1_light_0tiroir.png` : tiroir, Finance présent entre Pédagogie et Configuration ; haut/bas/gauche sains ; droite = voile sur la page.
- `fi1b_390x844_x1_dark_1vue.png` : haut = barre mobile (menu, recherche, compte) ; titre « Vue globale » ; onglets, « Politiques commerciales » sur deux lignes, mot entier ; carte séparée ; gauche/droite gouttière 16 ; bas vide.
- `fi1b_390x844_x1_light_rtl_1vue.png` : miroir correct, rien coupé.
- `fi1b_320x693_x1_light_2politiques.png` : titre sur deux lignes, mots entiers ; onglets pleine largeur, « Politiques commerciales » sur deux lignes ; carte séparée ; quatre bords sains.
- `fi1b_390x844_x2_light_2politiques.png` : **titre coupé « Politiques / commerci / ales »** (m1). Onglets passés en liste déroulante, mots entiers ; carte entière.
- `fi1b_320x693_x2_light_2politiques.png` : **titre coupé « Politiqu / es com / mercial / es »** (m1) ; bas = la carte commence en fin d'écran (la page défile, pas de débordement signalé).
- `fi1b_320x693_x2_dark_1vue.png` : titre « Vue / globale » mots entiers ; liste déroulante ; carte qui continue sous le pli (défilement).

K-55 : la carte n'est jamais collée aux onglets (≈20 px à 1440, ≈40 px physiques à 390). K-54 : aucun débordement ; la colonne de `PageShell` est centrée, la carte d'état garde sa largeur bornée alignée sur le titre (comportement d'`EtatSysteme`, antérieur).

## Défauts

### m1 — Mineur : mot coupé dans le titre « Politiques commerciales » à texte ×2 (leçon 8)
- **Où** : écran `/admin/finance/politiques`, titre de `PageShell` (`finance_page.dart:43`, `titre: liste[onglet.index].libelle`), rendu par `EntetePage` (`lib/core/widgets/page_shell.dart:136`, `headlineLarge` sans repli).
- **Preuve** : `fi1b_390x844_x2_light_2politiques.png` (« commerci / ales »), `fi1b_320x693_x2_light_2politiques.png` (« Politiqu / es com / mercial / es »), idem en sombre.
- **Cause** : le gabarit partagé coupe tout mot plus large que la colonne à 200 % ; FI-1b y met un libellé long. Même classement que « Mari / am » (`REVUE_MA-R.md` m1, cité par la leçon 8).
- **Remède attendu** : dans l'étape qui touche `EntetePage` (gabarit partagé, hors FI-1b), un titre qui réduit sa taille au lieu de couper un mot (par exemple taille bornée par la largeur du plus long mot), avec un test à 320 et 390, texte ×2 ; rien à changer dans FI-1b.

### m2 — Mineur : leçon 8 non appliquée par l'auteur
- **Où** : `FI-1b/RAPPORT.md:53` (« captures : FI-1b ne livre pas d'écran à maquette »).
- **Preuve** : FI-1b livre bien un écran (deux routes atteignables) ; la leçon 8 (`LECONS_DES_ROLES.md:112`) demande 320, 390, ×2 et RTL avant la revue. m1 l'aurait montré.
- **Remède attendu** : pour FI-11a et FI-11b, captures K-61 complètes par l'auteur avant la revue.

### m3 — Mineur (déjà relevé par le contrôle adverse, écart 2) : commentaire faux
- **Où** : `lib/features/demo/demo_finance_page.dart:20-21` (« ni quand l'environnement n'est pas declare »).
- **Preuve** : `env.dart` met `developpement` par défaut ; c'est l'écart DEMO-ENV-1.
- **Remède attendu** : corriger le commentaire dans l'étape DEMO-ENV-1.

## Hors périmètre (code partagé non modifié par FI-1b, à porter ailleurs)

- **H1** : pied de la barre 288 à texte ×2 : « Administrat / eur » coupé (`fi1b_1440x900_x2_light_1vue.png`, `…_x2_dark_2politiques.png`). `AdminShell` n'est pas dans le diff ; présent sur tous les domaines. À porter dans une étape AdminShell (leçon 8).
- **H2** : à 1440, la carte d'état (largeur bornée ≈800) laisse ≈290 px vides à droite de la colonne ; comportement d'`EtatSysteme`, identique sur les autres pages neutres. Rien à faire dans FI-1b ; à revoir quand FI-11a remplira la Vue globale.

## Questions au directeur

Aucune nouvelle. La route `/admin/finance/politiques` (au lieu de `/admin/parametres/politiques-commerciales`, guide §4) suit la revue FI-1a ; la question est déjà posée par l'auteur.

## Journaux de cette revue

- `D:\RA_TUTEUR\yaaden-cache\FI-1b-R\01_pubget.log` : `flutter pub get` (`.dart_tool` absent).
- `D:\RA_TUTEUR\yaaden-cache\FI-1b-R\02_captures.log` : test de capture temporaire (14 cas, `+14 All tests passed`, routes et exceptions relevées).
- `D:\RA_TUTEUR\yaaden-cache\FI-1b-R\03_tests.log` : suites routeur, widgets, admin (`+631`).
