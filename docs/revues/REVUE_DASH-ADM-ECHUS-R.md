# Revue croisée DASH-ADM-ECHUS-R : Comptes filtrée sur les accès échus

- **Objet revu** : `corrections/c2-adm-echus` @ `7e7a41be` (base `f6ac3658`), 2 commits, 15 fichiers (+335 −43), dont 6 captures et le texte du test de capture.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-ADM-ECHUS (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** : `DASH_STRATEGIE.md` §5 (sur `origin/corrections/c2-dash1`), D4 et D9 ; `supabase/migrations/0015_administration_voit_les_personnes.sql` ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés dans le worktree `/home/user/rv-adm-echus` ;
  - trois mutations ciblées, remises en place (`git status` propre à la fin) ;
  - quatre captures ouvertes ;
  - fusion à blanc sur `origin/corrections/revue-directeur-2026-10`.

## Verdict

**Refusée** (confirmée par la contre-vérification, voir en fin de rapport). Deux défauts majeurs sur la page Comptes ouverte filtrée.

Le reste est bon. La définition côté client est la même que le compteur SQL. L'adresse `?filtre=echus` est en place. La demi-tuile est un lien, sans bouton dans un bouton. Les tests sont discriminants.

Le défaut : la pastille « Accès échus » est un axe à part, qui se cumule avec la rangée des états. À l'ouverture filtrée, **deux pastilles sont allumées à la fois** : « Tous 3 » et « Accès échus 2 ». La liste montre 2 comptes. « Tous » dit le contraire de ce qu'on voit. Et un tap sur « Tous » ne relâche pas le filtre échus (`onPress: () => onEtat(null)`, `comptes_page.dart:209`) : l'admin croit tout revoir, il voit toujours 2 comptes. « Actif » + « Accès échus » donne une liste vide, combinaison impossible proposée à l'écran.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre de la base |
| `test/features/comptes_test.dart` + `tableau_de_bord_test.dart` | **59 réussis, 0 échec** |
| `catalogue_galerie_test`, `admin_coque_test`, `rtl_echelle_texte_ecrans_test`, `test/router` | **354 réussis, 0 échec** |
| Mutation 1 : `accesEchu` oublie la condition `provisionalActive` | **3 échecs** (« même définition que le compteur serveur », « ouverte sur les échus », « sans échu, pas de filtre à vide ») |
| Mutation 2 : la demi-tuile ouvre `adminPersonnesComptes` sans `?filtre=echus` | **1 échec** (« un tap ouvre ADM-08 échus ») |
| Mutation 3 : le vrai routeur (`app_router.dart:933`) ne lit plus `filtre=echus` | **0 échec** sur `test/router`, `comptes_test`, `admin_coque_test` : ce branchement n'est couvert par aucun test |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | **Aucun conflit** (arbre `8853b443`) |

## Points de la fiche, un par un

1. **Définition client identique au compteur SQL** : ✅. SQL (0015, l. 247 à 250) : `deleted_at is null`, `account_status = 'provisional_active'`, `access_until is not null and access_until < now()`. Client (`service_comptes.dart:159-164`) : `provisionalActive`, `accesJusquAu != null`, `fin.isBefore(maintenant)`. Le `deleted_at is null` est déjà fait par `comptes_admin()` (0015, l. 183). Aucune migration ultérieure ne redéfinit `indicateurs_admin` ni `comptes_admin`. Mutation 1 le prouve côté test.
2. **Adresse `?filtre=echus`** : ✅ en partie. `Routes.adminPersonnesComptesEchus` (`routes.dart:409`), lue par `app_router.dart:933`. Mais ce branchement n'est pas testé (mutation 3). Mineur.
3. **Pastille** : ❌. Présente, clé `comptes-filtre-echus`, compteur juste, masquée s'il n'y a aucun échu. Mais elle cohabite avec « Tous » allumée (voir Verdict). Capture `echus_comptes_390_clair.png` et `echus_comptes_320x2_sombre.png` : les deux pastilles sont violettes en même temps.
4. **Demi-tuile lien, pas de bouton dans un bouton (D4, D9)** : ✅. `TuileDouble` : l'`AppCard` n'a pas d'`onPress`, seul le compteur droit est un `Pressable(lien: true)`. Incidents reste un rapport. Le test vérifie exactement un `Pressable` dans la tuile, et qu'il porte « Accès échus » et pas « Incidents ». Libellé du lien en encre d'accent, jeton existant (`palette.inkAccent`).
5. **Captures K-61** : ✅. Six captures (390 clair, 320 ×2 sombre, 1440 clair, pour le tableau et pour Comptes).
   - `echus_tableau_320x2_sombre.png` : tuile « Incidents et accès », « 1 Incidents (24 h) » et « 2 Accès échus » en violet. Aucun mot coupé.
   - `echus_tableau_1440_clair.png` : demi-tuiles côte à côte, « Accès échus » en lien violet, incidents en encre normale.
   - `echus_comptes_390_clair.png` et `echus_comptes_320x2_sombre.png` : deux comptes provisoires échus. Rangée « Tous 3 / Actif 1 / Provisoire 2 / Accès échus 2 », avec **Tous et Accès échus allumées ensemble**. C'est le défaut retenu.

## Règles du projet

- 5 états : inchangés sur Comptes (chargement, erreur, hors ligne, vide déjà en place). Filtre échus vide : « Aucun compte avec ce filtre », et la pastille reste pour se relâcher. ✅
- 320 px et texte ×2 : ✅ sur les captures et sur le test « aucun mot coupé ».
- RTL : `rtl_echelle_texte_ecrans_test` vert. ✅
- Un seul bouton plein, jamais de bouton dans un bouton : ✅.
- Couleur ou valeur inventée : aucune (39 relevés). ✅
- Texte en dur : aucun, la pastille réutilise `t.admin.tableau.comptes` (« Accès échus »). ✅ (clé mal nommée, voir mineurs)
- Capacité et non rôle : rien de nouveau ne lit un rôle. ✅
- Port neutre en production : service inchangé. ✅

## Composants partagés modifiés

`TuileDouble` (`tuiles_compteur.dart`) : utilisée aussi par `lib/features/_dev/galerie/catalogue_galerie.dart`. Sans `onPress`, le rendu reste un rapport. `catalogue_galerie_test` vert. La sémantique change : l'`AppCard` ne porte plus le libellé global, chaque demi-tuile porte le sien et le titre devient un en-tête. Pas de régression mesurée.

## Défauts retenus

### MAJEUR

1. **Deux pastilles allumées à la fois, « Tous » ne relâche pas « Accès échus »** (`comptes_page.dart:205-229`). Ouverte par la tuile, la page montre « Tous 3 » retenue et 2 comptes. Un tap sur « Tous » laisse le filtre échus. « Actif » + « Accès échus » donne une liste vide impossible.

### Mineurs

1. Le vrai routeur (`app_router.dart:933`) qui lit `filtre=echus` n'est couvert par aucun test (mutation 3 sans échec). Le test du tableau utilise son propre routeur.
2. La pastille réutilise la clé `t.admin.tableau.comptes`, dont le nom ne dit pas « accès échus ». Une clé `admin.comptes.filtreEchus` (avec sa ligne dans `tool/libelles_sources.json`) serait plus lisible.

## Pour accepter

Étape de correction proposée (DASH-ADM-ECHUS-C1) :

1. Faire de « Accès échus » une valeur du même axe que les états, exclusive : `Tous` retenue seulement si `etat == null && !echus` ; un tap sur `Tous` ou sur un état remet `echus` à faux ; un tap sur « Accès échus » remet `etat` à null.
2. Ajouter un test : ouverte filtrée, « Tous » n'est pas retenue ; un tap sur « Tous » montre les 3 comptes.
3. Ajouter un test du vrai `routeurProvider` : `/admin/personnes/comptes?filtre=echus` construit `ComptesPage(echusSeulement: true)`.
4. Refaire les deux captures Comptes (390 clair, 320 ×2 sombre) avec une seule pastille allumée.

## Contre-vérification

Relecteur sceptique, session `01KyPAZg`, non auteur. But : réfuter le majeur, chercher un majeur oublié.

### Majeur 1 : confirmé

- Lecture du code : `comptes_page.dart:208` met `retenue: etat == null` sur « Tous », sans regarder `echus`. `onPress: () => onEtat(null)` ne touche pas `_echus`.
- Capture `echus_comptes_320x2_sombre.png` ouverte : « Tous 3 » et « Accès échus 2 » sont violettes ensemble, 2 cartes listées. Le défaut se voit.
- Test de contre-épreuve (fichier temporaire, supprimé) : ouverte avec `echusSeulement: true`, tap sur « Tous ». Le compte « Encore » (provisoire, non échu) reste **absent**. 1 échec, comme prévu.
- Vraiment majeur : oui. Le libellé « Tous » ment sur ce que montre la liste, et le geste attendu pour tout revoir ne marche pas.

### Majeur 2 (nouveau) : le filtre échus survit à une navigation vers Comptes sans filtre

- `comptes_page.dart:57` : `late bool _echus = widget.echusSeulement;`. L'initialiseur ne tourne qu'une fois. Pas de `didUpdateWidget`.
- go_router 18.0.1 : la clé de page est le chemin apparié, sans la requête (`match.dart:231`). De `/admin/personnes/comptes?filtre=echus` vers `/admin/personnes/comptes`, l'État est **gardé**. Le widget reçoit `echusSeulement: false`, mais `_echus` reste vrai.
- Chemin réel : l'entrée « Comptes » du domaine Personnes (`admin_domaine.dart:210`) mène à `Routes.adminPersonnesComptes`. Depuis la page filtrée, l'admin choisit « Comptes » dans la navigation : l'adresse ne porte plus de filtre, la liste reste filtrée.
- Test de contre-épreuve (routeur de test avec la même route, fichier supprimé) : `go('/c?filtre=echus')` puis `go('/c')`. Le compte « Encore » reste **absent**. 1 échec, comme prévu.
- Correction : dériver le filtre de l'adresse (ou `didUpdateWidget` qui recopie `echusSeulement` quand il change), plus un test qui navigue de l'adresse filtrée à l'adresse nue.

### Mineurs : confirmés

- Mutation 3 sans échec : le branchement du vrai routeur n'est pas testé. Le majeur 2 montre que ce trou coûte cher : c'est là que l'état se perd.
- Clé `t.admin.tableau.comptes` réutilisée : confirmé, cosmétique.

### Points vérifiés sans défaut

- Bouton dans un bouton : non. `TuileDouble` n'a plus d'`onPress` sur l'`AppCard`, seul le compteur droit est un `Pressable(lien: true)`.
- Mot coupé à 320 ×2 : aucun dans les captures du tableau ni de Comptes. « GUARDIAN-AD-000001 » se coupe au tiret, comportement de la base, hors de ce lot.
- Texte en dur : aucun.
- Composant partagé `TuileDouble` : seul autre usage, la galerie, test vert (mesure de la première revue).
- Capture `echus_tableau_390_clair.png` : « 2 Accès échus » en violet, « 1 Incidents (24 h) » en encre normale. Conforme.

### Verdict final

**Refusée.** Deux majeurs : pastilles cumulées (confirmé) et filtre gardé après navigation (nouveau). L'étape DASH-ADM-ECHUS-C1 doit ajouter : point 5, l'état du filtre suit l'adresse ; point 6, un test qui navigue de `?filtre=echus` vers l'adresse nue et voit tous les comptes.

Worktree `/home/user/rv-adm-echus` propre à la fin (`git status` vide).

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
