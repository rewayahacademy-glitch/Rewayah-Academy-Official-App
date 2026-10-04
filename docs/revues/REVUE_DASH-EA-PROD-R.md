# Revue croisée DASH-EA-PROD-R : route réelle de l'Accueil élève adulte et historique

- **Objet revu** : `corrections/c2-ea-prod` @ `a935bac3` (base `f0252b84`, branche `c2-bento3b`), 1 commit, 58 fichiers (+1213 −49), dont 40 captures.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-EA-PROD (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** : `docs/current/DASH_STRATEGIE.md` §3.7 et D6, D9, D10, D11, D14 ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff complet ;
  - contrôles relancés sur le worktree `/home/user/rv-ea-prod` ;
  - deux mutations ciblées, remises en place (`git status` propre à la fin) ;
  - quatre captures ouvertes ;
  - fusion à blanc sur `origin/corrections/revue-directeur-2026-10`.

## Verdict

**Acceptée avec réserves.** Le cœur est tenu :

- `/eleve` mène à `/eleve/adulte` par une capacité, pas par un rôle dans un widget ;
- en production, sans source (EA-BR-04), `/eleve` ne change pas, et `/eleve/adulte` par adresse dit « Pas encore disponible », sans « Réessayer », sans squelette, sans lien ;
- « Voir tout » des dernières séances ouvre `/eleve/adulte/seances`, et le retour ramène à l'Accueil ;
- les deux écrans ont leurs cinq états, testés sur la vraie route ;
- pas de cloche sans destination (D9).

Sept remarques mineures ou cosmétiques, aucune ne bloque.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK, aucun fichier modifié |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `test/features/accueil_adulte` (page + route) | **58 réussis, 0 échec** |
| Écrans voisins : `test/router`, `classe_eleve`, `demo_adulte_page_test`, `ma_classe_adulte`, `accueil_eleve_test`, `accessibilite/accueil_ma3`, `navigation_ma2`, `recette_ea12` | **600 réussis, 25 ignorés, 0 échec** |
| Composant partagé `LecteurGroupe` et `preparerSalleEleve` : `teaching_core/a/espace_groupe_page_test`, `routes_tc_a_test`, `responsive_test`, `tuteur_k_echelle_texte_test`, `ma_classe_ma4`, `apres_ma6`, `demo_accessibilite_page_test` (et ceux déjà cités) | **122 réussis, 12 ignorés, 0 échec** |
| Mutation 1 : `capaciteAccueilAdulteProvider` rend toujours `true` | **1 échec** : « contre-épreuve, production : sans source, /eleve garde l'accueil de l'élève » (attendu `/eleve`, obtenu `/eleve/adulte`, `accueil_adulte_route_test.dart:130`) |
| Mutation 2 : `LecteurGroupe` ignore son nouveau paramètre `squelette` (revient à `SqueletteGroupe`) | **0 échec** sur 58 : la retouche n'est pas couverte (voir m1) |
| Fusion à blanc `git merge-tree` sur `revue-directeur-2026-10` | **1 conflit** : `tool/libelles_sources.json` (voir plus bas). `fr.i18n.json` et `strings_fr.g.dart` fusionnent seuls. La base `f0252b84` est déjà dans la branche commune |

## Points de la fiche, un par un

1. **Redirection `/eleve` par capacité, pas par rôle.** ✅
   - `routes_accueil_adulte.dart` : `redirectionAccueilEleve` est une fonction pure de la capacité.
   - `app_router.dart` : le `redirect` de `/eleve` lit `capaciteAccueilAdulteProvider` ; un `ref.listen` réveille le routeur quand elle change.
   - `accueil_adulte_page.dart` : la capacité vaut `accueilAdulteProvider.hasValue`. Le provider vérifie aussi `role == student`, mais c'est un garde de périmètre dans un provider, pas un widget (voir m3).
   - Mutation 1 : un test échoue. Le test est discriminant.
2. **Indisponible en production, sans invention (D10).** ✅
   - `accueilAdulteProvider` et `historiqueSeancesAdulteProvider` rendent `CapaciteIndisponible`, avec `retry: null`.
   - Test « /eleve/adulte par adresse dit indisponible » : aucune ligne de squelette, pas de « Réessayer », pas de « Voir tout ».
   - La démo surcharge les providers ; le second adulte garde le provider réel.
3. **Historique `/eleve/adulte/seances`.** ✅
   - Page `historique_seances_adulte_page.dart`, faite de composants existants (`PageShell`, `BlocAsynchrone`, `EmptyState`, `EtatSysteme`).
   - La liste est partagée avec l'Accueil (`ListeSeancesPassees`).
   - La destination « Accueil » reste allumée (`indexActif == 0`, testé).
4. **Cinq états.** ✅ Pour les deux écrans, sur la vraie route : chargement, contenu, vide, erreur (K-59, « Réessayer »), hors ligne, et en plus indisponible. Le squelette de l'Accueil a la forme de la grille Bento (m6 de BENTO-3-R) : il est côte à côte au bureau et empilé en mobile (testé).
5. **Retouches `LecteurGroupe` et `preparerSalleEleve`.** ✅ sans régression, mais la première n'est pas couverte.
   - `LecteurGroupe` prend un `squelette`, dont la valeur par défaut est l'ancien `SqueletteGroupe`. Les autres écrans ne changent donc pas.
   - `_preparer` devient `preparerSalleEleve` sans changer de corps.
   - Les tests des écrans voisins passent (122 et 600).
   - Mutation 2 : le nouveau paramètre n'est vérifié par aucun test (m1).
6. **Captures `docs/current/captures/DASH-EA-PROD`.** ✅ 40 captures, chacune à 1440, 390 clair, 390 sombre et 320 ×2. Quatre ouvertes :
   - `contenu_320x2_clair` :
     - aucun mot n'est coupé ;
     - « Voir tout » apparaît sous « Dernières séances » ;
     - l'absence est en pastille ;
     - un seul bouton plein n'est pas visible ici, parce qu'il n'y a pas d'entrée possible : c'est conforme.
     - Seul défaut : le titre « Ressources de la classe » est nettement plus petit que les autres titres de section (m6, déjà présent avant).
   - `historique_390_sombre` : le titre « Mes séances passées » et le disque retour sont présents. Sept séances, une absence. Le contraste est correct et l'onglet Accueil est allumé.
   - `indisponible_390_clair` : une seule carte « Pas encore disponible ». Pas de bouton, pas de squelette, mais pas de titre de page non plus (m7).
   - `chargement_1440_clair` : la ligne de salutation, deux grandes tuiles côte à côte, la ligne « Mon parcours », puis deux grandes tuiles. Aucune fausse donnée.

## Règles du projet

- Textes : 5 clés neuves, dans `fr.i18n.json`, et toutes déclarées dans `tool/libelles_sources.json` (« à faire valider par le directeur »). ✅
- Aucune couleur inventée. Le vérificateur relève 39 points, le chiffre de la base. ✅ Les deux hauteurs du squelette (280 et 96) sont des constantes sans source (m5).
- 320 ×2 et RTL : 18 tests « aucun mot coupé » (Accueil, Historique, États ; 320 ×2 et 1440 ; LTR et RTL), tous verts. ✅
- Un seul bouton plein : `verifierUnSeulBoutonPlein` passe sur la vraie route. ✅
- Aucun bouton dans un bouton : `SectionHeader` porte un lien tertiaire. ✅

## Défauts retenus

Aucun majeur.

- **m1 (tests)** : le paramètre `squelette` de `LecteurGroupe` n'est pas testé. Quand l'Accueil adulte est servi mais que le groupe charge encore, rien ne vérifie que la grille Bento s'affiche plutôt que `SqueletteGroupe` (mutation 2 survivante). Il faut ajouter un test « accueil servi, groupe en attente → `SqueletteAccueilAdulte` ».
- **m2 (catalogue)** : la page « Mes séances passées » est un écran nouveau. Elle n'a pas de fiche propre. Seuls la ligne du §3.7 et le champ Route de la fiche EA-ACCUEIL la citent. Il faut ajouter sa fiche (code, rôle, route, question, états) dans `DASH_STRATEGIE.md` ou au registre des écrans.
- **m3 (capacité)** : `capaciteAccueilAdulteProvider` filtre sur `AppRole.student` et dépend d'une lecture faite après la session. Une fois EA-BR-04 servi, l'élève verra un instant l'Accueil élève avant la redirection. C'est reconnu dans « Reste » de §3.7. La capacité devra arriver avec la session.
- **m4 (texte)** : « Voir tout » reprend la clé `t.tuteur.accueil.voirTout`. Une clé commune (`commun.*`) serait plus propre.
- **m5 (valeurs)** : `SqueletteAccueilAdulte.hauteurGrande = 280` et `hauteurLarge = 96` sont des hauteurs choisies sans source écrite. Elles sont acceptables pour un squelette, mais il faut les noter.
- **m6 (cosmétique, déjà présent)** : à 320 ×2, le titre de `BlocBibliotheque` (« Ressources de la classe ») est bien plus petit que les autres `SectionHeader`.
- **m7 (cosmétique)** : l'état « indisponible » de `/eleve/adulte` n'a pas d'en-tête. On n'y arrive que par l'adresse.

## Conflit de fusion

Le seul conflit est `tool/libelles_sources.json`, en fin de fichier. Les deux branches y ajoutent des clés après `enseignant.cahier.travailMaisonSaisi` : DASH-ADM-1 et DASH-ELV-ERR d'un côté, les 5 clés `adulte.*` de l'autre. Pour le résoudre, on garde les deux blocs, on met une virgule entre eux, puis on vérifie que le JSON reste valide.

## Pour accepter

1. Résoudre le conflit `libelles_sources.json` en gardant les deux blocs.
2. Optionnel avant de passer à « fait » : le test de m1 et la fiche de m2.
3. Reporter m3 à m7 dans « Reste » de DASH-EA-PROD ou dans DASH-LIB.

## Contre-vérification

- **Relecteur** : session `01KyPAZg`, sceptique indépendant. Il n'est pas l'auteur et n'a pas fait la première revue.
- **Date** : 4 octobre 2026.
- **Worktree** : `/home/user/rv-ea-prod` @ `a935bac3`. `git status` est propre à la fin.

### Contrôles relancés

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_jetons` | 39 points |
| `test/features/accueil_adulte` | 58 réussis, 0 échec |
| Mutation 3 : `redirectionAccueilEleve` rend toujours `null` | **8 échecs** sur 58. La redirection servie est bien testée |
| Mutation 4 : on retire la garde `!lecture.hasError` de l'en-tête de l'Accueil | **0 échec**. Elle n'est pas couverte (n1) |
| Fusion à blanc sur `origin/corrections/revue-directeur-2026-10` | 1 seul conflit, sur `tool/libelles_sources.json`. C'est confirmé |

Trois captures ouvertes :
- `historique_320x2_clair` : aucun mot coupé, le titre est sur trois lignes, le retour est présent, l'absence est en pastille. Les lignes n'ont ni chevron ni action, donc il n'y a pas de bouton dans un bouton.
- `erreur_320x2_clair` : une carte d'échec et « Réessayer » en contour. Aucun mot coupé. Pas d'en-tête de page.
- `horsligne_390_sombre` : le bandeau hors ligne, la carte « Vous êtes hors ligne » et « Réessayer ». Le contraste est correct.

### Majeurs

- **Confirmés** : aucun. La première revue n'en retenait aucun.
- **Rejetés** : aucun, puisqu'il n'y en avait pas à réfuter.
- **Oubliés** : aucun après recherche. Voici ce qui a été vérifié :
  - **Bouton dans un bouton** : non. `ListeSeancesPassees` pose des `LigneRubrique` sans `onPress`. « Voir tout » est un lien tertiaire de `SectionHeader`.
  - **Mot coupé à 320 ×2** : aucun dans les captures ouvertes. Les 18 tests de coupure passent.
  - **États** : les cinq états, plus « indisponible », sont présents pour les deux écrans et capturés.
  - **Texte en dur** : aucun. Les 5 clés neuves sont dans `fr.i18n.json` et dans `libelles_sources.json`. `ar.i18n.json` est partiel par conception, comme pour les autres clés.
  - **Composants partagés** :
    - `LecteurGroupe` garde `SqueletteGroupe` par défaut, donc rien ne change pour les autres écrans.
    - `preparerSalleEleve` est un simple renommage.
    - Le rôle n'est lu que dans un provider, jamais dans un widget.
  - **Ordre des routes** : `/eleve/adulte` est une route sœur de `/eleve`, et non une sous-route. Go_router ne lance donc pas la redirection de `/eleve` sur `/eleve/adulte`. Les tests sur la vraie route le confirment.

### Mineurs

- m1 à m7 sont confirmés. m1 est reproduit d'une autre manière, avec une deuxième garde non couverte (n1).
- **n1 (tests, nouveau)** : la garde `!lecture.hasError` de l'en-tête de l'Accueil n'est couverte par aucun test (mutation 4 : 0 échec). C'est le cas « échec que Riverpod relance ». Il faut un test avec `AsyncLoading` qui garde une erreur : aucune ligne de squelette au-dessus de l'état d'échec.
- **n2 (cosmétique, nouveau, prolonge m7)** : en échec et hors ligne aussi, `/eleve/adulte` n'a pas d'en-tête (capture `erreur_320x2_clair`). La salutation disparaît dès que la lecture a échoué. On n'est pas perdu, puisque la barre du bas allume « Accueil ».

### Verdict final

**Acceptée avec réserves**, sans changement. Aucun majeur ne tient ou n'apparaît. Les réserves sont m1 à m7, plus n1 et n2. Le conflit `libelles_sources.json` se résout en gardant les deux blocs.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
