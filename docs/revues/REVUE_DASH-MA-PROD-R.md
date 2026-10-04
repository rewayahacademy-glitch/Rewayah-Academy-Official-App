# Revue croisée DASH-MA-PROD-R : Accueil du Mode Accessibilité hors démonstration, aide de l'élève

- **Objet revu** : `corrections/c2-ma-prod` @ `ef272b74` (base `af20f6c2`). 2 commits, 52 fichiers (+1323 −204), dont 34 captures et le script de capture archivé.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-MA-PROD (auteur : `b061fd81`).
- **Date** : 4 octobre 2026.
- **Références** : `DASH_STRATEGIE.md` §3.3, Q3, fiche ELV-02-MA et ligne DASH-MA-PROD, lus sur `origin/corrections/c2-dash1`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés dans le worktree `/home/user/rv-ma-prod` ;
  - deux mutations ciblées, remises en place (`git status` propre à la fin) ;
  - 5 captures ouvertes.

## Verdict

**Refusée** (verdict corrigé par la contre-vérification, voir la dernière section : un mot coupé à 320 px ×2 dans l'état hors ligne, M1).

Verdict de la première revue : **acceptée avec réserves.** Ce que demande la fiche est tenu :

- l'Accueil du mode est monté sur `/eleve`, choisi par la présentation et jamais par le rôle ;
- `/eleve/aide` existe ;
- les cinq états sont là ;
- une seule colonne ;
- le port est neutre en production.

Aucune règle n'est cassée. Trois réserves :

- le changement d'`EtatSysteme` (médaillon empilé) n'est couvert par aucun test ;
- en production, un élève en présentation enfant perd l'Accueil ELV-02, qui lisait de vraies données. Il voit maintenant « pas encore affichée ici » ;
- la suite `test/features` n'a pas pu être menée à son terme pendant cette revue.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (code 0) |
| `dart analyze --fatal-infos` | **0 problème** |
| `verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `accueil_ma_prod_test.dart` + `accueil_ma3_test.dart` | **49 réussis, 0 échec** (40 + 9) |
| `test/core`, `test/widgets`, `test/accessibilite`, `test/router` (dont `composants_etats_test`, `etats_transverses_test`, `catalogue_galerie_test`) | **1509 réussis, 0 échec** |
| `test/features` (2501 tests attendus) | **Pas mené à son terme** : la suite tournait encore à la fin de la revue. De plus, deux mutations ont été posées pendant qu'elle tournait, ce qui pourrait fausser des résultats. À relancer sur la fusion |
| Mutation 1 : `/eleve` rend toujours ELV-02 (`if (true \|\| …)`) | **31 échecs sur 40** dans `accueil_ma_prod_test`. Le cœur du changement est bien gardé |
| Mutation 2 : `EtatSysteme` n'empile jamais (`empile: false`) | **40 sur 40 réussis**. Aucun test de cette étape ne voit le changement. Les tests « aucun mot coupé » passent quand même, parce que `TexteSansCoupure` réduit le texte |
| Fichiers interdits (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`) | Aucun |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` | **Conflit** sur `lib/core/i18n/strings_fr.g.dart` (fichier généré : relancer `dart run slang`) et sur `tool/libelles_sources.json` (deux ajouts en fin d'objet : les garder tous les deux, avec la virgule). Les deux conflits sont mécaniques |

## Points de la fiche, un par un

| Point | Constat |
| :--- | :--- |
| Choix par capacité sur `/eleve` | ✅ `accueil_eleve_selon_presentation.dart:26` lit `modeAccessibiliteActifProvider`, c'est-à-dire la présentation (`InterfaceMode.enfant`), et jamais un rôle. Même route, même arbre (ADR-009). Test « présentation standard : ELV-02, inchangé » |
| Port neutre en production | ✅ `port_accueil_accessibilite.dart`. `AccueilAccessibiliteIndisponible` lève `CapaciteIndisponible('MA-BR')`, et `retry` est nul. La démonstration surcharge le port (`PortAccueilAccessibiliteDemo`) dans un `ProviderScope` imbriqué. Aucun appel serveur |
| Cinq états | ✅ Les cinq sont là : chargement (`_Squelette`, aucune fausse donnée), contenu, vide (`_Vide`, sans Classe inventée), erreur (K-59, « Réessayer » relance) et hors ligne (bandeau de `PageShell` et entrée inerte). « Indisponible » est un état en plus. Chaque état est testé sur la route réelle et sur la démo (`?accueil=`). « Lire le Coran » et l'aide restent dans tous les états (D11) |
| `/eleve/aide` | ✅ `app_router.dart:357-370`, dans `_CoquilleSecondaire`. Le retour mène à `/eleve`. La route est sous le préfixe de l'élève, donc la garde de rôle s'applique. Tests : la route s'ouvre depuis l'Accueil et aussi quand on la tape directement |
| Une seule colonne | ✅ `seuilDeuxColonnesAccueil` est retiré. Le test `_uneColonne` remplace l'ancienne clé deux colonnes. La capture 1440 le confirme |
| Un seul bouton plein | ✅ `verifierUnSeulBoutonPlein` dans les tests. Dans les états erreur et indisponible, le bouton de l'état est secondaire |
| Texte en dur | ✅ 6 clés i18n, inscrites dans `tool/libelles_sources.json`, avec la mention « à faire valider par le directeur » |
| `ActionPrincipale` → `TexteSansCoupure` | ✅ Pas de régression mesurée dans `test/core`, `test/widgets`, `test/router` et `test/accessibilite`. `test/features` reste à confirmer |
| `EmptyState` → `TexteSansCoupure` | ✅ Même constat |
| `EtatSysteme` empilé au-delà de 130 % | ⚠ Le code est correct, la capture `indisponible_320x2_sombre` le montre, et aucune régression n'est mesurée. Mais aucun test ne le garde (mutation 2) |

### Écrans touchés par ces composants partagés

`EtatSysteme` est employé, entre autres, par :

- ma classe adulte ;
- admin observations ;
- classe tuteur et catalogue ;
- accueil famille ;
- salle de secours ;
- notifications ;
- tout le foyer ;
- accueil adulte ;
- les états transverses du routeur.

`EmptyState` et `ActionPrincipale` sont employés presque partout. Les dossiers `test/widgets` et `test/router` sont verts. Les écrans de `test/features` restent à confirmer sur la fusion.

## Captures ouvertes

- **`contenu_320x2_clair`** :
  - aucun mot coupé ;
  - « As-salāmu » et « An-Nour » restent entiers grâce au trait insécable ;
  - un seul bouton plein, « Voir ma classe ».
- **`indisponible_320x2_sombre`** :
  - le mode sombre est bien sombre ;
  - le médaillon est au-dessus du texte ;
  - « Voir ma classe » est secondaire.
- **`contenu_1440_clair`** :
  - une seule colonne, à toute la largeur utile, soit environ 1120 px ;
  - les lignes sont longues mais lisibles.
- **`erreur_390_sombre`** : le titre, la cause, « Réessayer », puis le Coran et l'aide.
- **`horsligne_390_clair`** :
  - le bandeau est là ;
  - « Voir ma classe » est remplacé par la ligne hors ligne de `CarteSession` et un « Réessayer » inerte. C'est le comportement existant de `CarteSession` (D9).

## Défauts retenus (aucun majeur)

- **r1 (mineur) : le médaillon empilé d'`EtatSysteme` n'est pas testé.** Il s'agit d'un composant partagé, modifié dans cette étape. Remède : un test dans `test/widgets/composants_etats_test.dart`. À 2,0 le médaillon est au-dessus du titre (`getRect`) ; à 1,0 il est à côté.
- **r2 (mineur, décision du directeur) : effet en production pour les élèves en présentation enfant.**
  - Avant, ces élèves voyaient ELV-02 avec leurs vraies séances (`ServicePlanningSupabase`).
  - Maintenant, ils voient « Prochaine séance pas encore affichée ici » et doivent passer par Ma classe.
  - La règle du port neutre est respectée, mais c'est un recul visible tant que MA-BR n'est pas branché.
  - Il faut le faire confirmer, ou prioriser MA-BR.
  - Autre option : revenir à ELV-02 quand le port est indisponible.
- **r3 (cosmétique) : le commentaire de `_insecable` est inexact.** Il parle de U+2011, alors que le code insère U+2060 (word joiner) après le trait d'union. Le rendu est correct, seul le commentaire est à corriger.
- **r4 (cosmétique) : sans en-tête dans les états erreur et indisponible.** La salutation n'est pas rendue, et l'écran commence directement par la carte d'état. L'écran n'a donc pas d'en-tête sémantique dans ces deux états.
- **Rappel** : aucune clé arabe n'est ajoutée. Le repli `fallback_strategy: base_locale` affiche le français, comme ailleurs dans le projet.

## Pour accepter

1. Fusionner en résolvant les deux conflits mécaniques : relancer `dart run slang`, et réunir les deux ajouts de `libelles_sources.json`.
2. Relancer `test/features` sur la fusion (dossier par dossier). Attendu : 0 échec, notamment sur les écrans qui emploient `EtatSysteme`, `EmptyState` et `ActionPrincipale`.
3. Ajouter le test de r1 (petit lot de suivi possible).
4. Soumettre r2 au directeur.

## Contre-vérification

Sceptique indépendant, session `01KyPAZg`, non auteur. Même worktree, même commit `ef272b74`. Date : 4 octobre 2026.

### Ce qui est confirmé

- Aucun majeur n'avait été retenu. Je n'en rejette donc aucun.
- r1 (médaillon empilé non testé) : confirmé à la lecture. `etat_systeme.dart` choisit `empile` sur `textScaler > 1,3`, et aucun test ne lit la position du médaillon.
- r2, r3, r4 : confirmés à la lecture du code (`accueil_eleve_selon_presentation.dart:45`, `accueil_accessibilite.dart:556-563`, état erreur sans `_Salutation`). La capture `erreur_320x2_clair` montre bien l'écran qui commence par la carte d'état.
- Pas de bouton dans un bouton : `CarteSession` n'a pas de `onTap` de carte, et l'`AppCard` de l'état vide n'en a pas non plus.
- La suite `test/features`, que la première revue n'avait pas menée à son terme, est relancée sans mutation en cours : **2506 réussis, 0 échec, 2062 ignorés** (`flutter test test/features -j 3`, code 0). Les écrans qui emploient `ActionPrincipale` sous `IntrinsicWidth` (cahier, journée, bienvenue, attente) ne régressent pas.

### Ce qui est nouveau : un majeur

**M1 (majeur) : un mot coupé à 320 px ×2 dans l'état hors ligne.**

- **Ce qu'on voit** : sur la capture de l'auteur, `ma_prod_horsligne_320x2_clair.png`, la ligne d'état de la carte de séance se lit « La séance nécessite une conn / exion. ». Le mot « connexion » est coupé.
- **D'où ça vient** : cette étape passe pour la première fois `horsLigne:` à `CarteSession` depuis l'Accueil (`accueil_accessibilite.dart:641`). Avant, la base `af20f6c2` ne le passait pas. La ligne d'état est rendue par `_LigneEtat` (`carte_session.dart:500-509`), avec un `Text` simple dans un `Flexible`. Ce n'est pas un `TexteSansCoupure`.
- **Pourquoi les tests ne le voient pas** : le groupe « Aucun mot coupé » de `accueil_ma_prod_test.dart:365-390` couvre indisponible, contenu, vide et erreur. **Il ne couvre pas l'état hors ligne.**
- **Preuve reproductible** : j'ai ajouté un test temporaire, copie du fichier de l'étape plus un cas `horsLigne: true`, port de démo Mariam, 320 × 3200, échelle 2. Résultat : **2 échecs sur 2** (LTR et RTL), avec `verifierEcranSansMotCoupe` qui rapporte `['Tu es hors ligne. La séance nécessite une connexion. : connexion.']`. J'ai ensuite supprimé le fichier, et `git status` est propre.
- **Gravité** : la règle « 320 px et texte ×2 sans mot coupé » est cassée, sur un des cinq états livrés par l'étape, et le défaut se voit sur sa propre capture. Selon les consignes, c'est un majeur.
- **Correction proposée** :
  1. Dans `_LigneEtat` (`carte_session.dart:503`), remplacer `Text` par `TexteSansCoupure`, en gardant le style tabulaire.
  2. Ajouter `('horsLigne', port démo + horsLigne: true)` à la liste du groupe « Aucun mot coupé ».
  3. Relancer les tests des écrans qui emploient `CarteSession` (`test/features/tc_espace_groupe`, accueil famille, classe tuteur).
  4. Refaire les captures hors ligne.

### Ce qui est rejeté

Rien. La première revue ne retenait aucun majeur.

### Verdict final

**REFUSÉE**, à cause de M1. La correction est petite : un composant, un cas de test, des captures à refaire. Une fois M1 corrigé, l'étape peut passer en « acceptée avec réserves » (r1 à r4 restent des réserves).

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
