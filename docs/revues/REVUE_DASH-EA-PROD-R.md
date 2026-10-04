## Verdict
**ACCEPTÉE AVEC RÉSERVES** pour DASH-EA-PROD (origin/corrections/c2-bento3b..origin/corrections/c2-ea-prod, commit a935bac3). Il ne reste ni bloquant ni majeur. Il y a quatre défauts mineurs ; l'un existe déjà dans la base et sort du périmètre.

Statuts de preuve :
- **Présent dans le code** : oui.
- **Testé localement** : oui (analyze, deux vérificateurs, tests ciblés, contre-épreuves).
- **Testé sur staging** : non.
- **Déployé** : non.
- **Serveur** : aucun branchement. EA-BR-04 (accueil adulte) et la future ligne EA-BR pour l'historique restent à faire, et le lot les consigne.

## Ce qui est livré, jugé contre la fiche
- **Route réelle /eleve/adulte** dans la branche Accueil de la coquille élève (`routes_accueil_adulte.dart`). /eleve y redirige via `redirectionAccueilEleve`, une fonction pure qui dépend de `capaciteAccueilAdulteProvider`. Le routeur se réveille sur un changement de cette capacité (`ref.listen` dans app_router.dart).
- **En production** : la capacité reste fausse car le provider rend `CapaciteIndisponible`, donc /eleve ne change pas. Demandée par son adresse, /eleve/adulte affiche « indisponible ». Rien n'est inventé (D10).
- **« Voir tout » des dernières séances** : ouvre /eleve/adulte/seances, servi par `historiqueSeancesAdulteProvider`. Ce port neutre rend « indisponible » et n'est surchargé qu'en démonstration. La page couvre les cinq états : chargement en squelette de liste, contenu, vide subi sans bouton, erreur K-59 avec « Réessayer », hors ligne.
- **Accueil adulte** :
  - squelette en grille Bento (m6 de BENTO-3-R) ;
  - plus de cloche inerte (D9) ;
  - plus de ligne de squelette au-dessus d'un état d'échec ;
  - `retry` désactivé pour une capacité absente ;
  - nouveau libellé d'échec K-59.
- **Retouches** :
  - `LecteurGroupe` reçoit un paramètre `squelette` ; la valeur par défaut reste celle d'avant, donc les autres appelants ne changent pas.
  - `_preparer` devient `preparerSalleEleve`, désormais public. Simple renommage, comportement identique.
- **Libellés** : les cinq nouveaux sont déclarés dans tool/libelles_sources.json comme « proposé par l'agent, à faire valider par le directeur ».
- **Hors champ** : thème, rendu du Coran et serveur ne sont pas touchés.

## Périmètre et commandes
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1610 sur la base comme sur la tête, diff vide.
- `verifier_jetons` : 39 sur la base comme sur la tête, diff vide.
- Tests ciblés, tous verts :
  - test/features/accueil_adulte : 58 ;
  - démo adulte et test/router : 289 ;
  - teaching_core/a, ma_classe_adulte et espace_classe_eleve : 153, plus 12 sautés (captures).
- **Contre-épreuves faites moi-même** :
  - retrait du redirect : 7 échecs ;
  - retour à l'ancien squelette : 3 échecs ;
  - capacité vraie pour tout élève, c'est-à-dire décision d'après le rôle : 1 échec ;
  - « Voir tout » forcé : 0 échec, car SectionHeader masque déjà une action sans callback.

## Défauts
1. **Mineur**, `accueil_adulte_page.dart:145-151` : la capacité est déduite de `hasValue` de l'accueil adulte et non rendue par le serveur avec la session. Conséquences : l'accueil élève s'affiche un instant avant la redirection, et la capacité peut rester vraie après une relecture en échec. Le lot le consigne dans « Reste » ; à traiter avec EA-BR-04.
2. **Mineur**, `SqueletteAccueilAdulte` : hauteurs 280 et 96 écrites en dur. Pratique déjà en place ailleurs (journee_page:1173, mes_groupes_page:74, accueil_eleve_page:212) et non relevée par le vérificateur.
3. **Mineur**, accueil_adulte_route_test.dart:157 : le test D9 « contre-épreuve » ne peut pas échouer sur le code muté, il ne fait que protéger contre une régression.
4. **Mineur, hors périmètre**, emplacements_groupe.dart:155-160 : « Ressources de la classe » est réduit par scaleDown à 320 px avec texte ×2. Même rendu dans BENTO-3/adulte_320x2 sur la base.

## Captures vues
Six captures ouvertes : contenu_320x2, historique_320x2, contenu_1440, historique_390_sombre, chargement_1440 et erreur_320x2. Je n'ai trouvé aucun mot coupé, chevauchement ou élément collé. Le seul texte trop petit est le titre Ressources, défaut de la base.

## Pour lever les réserves
- Ajouter à EA-BR.md la ligne de source de l'historique.
- Faire rendre la capacité « accueil adulte » avec la session (serveur, à consigner).
- À terme, remplacer les hauteurs de squelette par des jetons.
- Renommer le test D9 en « non-régression ».
- Traiter le scaleDown du titre de BlocBibliotheque dans une étape dédiée.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

J'ai relu le diff c2-bento3b..c2-ea-prod (a935bac3) dans un worktree détaché cr-5, retiré à la fin.

Ce que j'ai vérifié et qui tient :
- La redirection ne dépend pas du rôle. Le seul filtre est role == student, et seuls les élèves atteignent /eleve.
- La route /eleve n'a pas de sous-routes, donc le redirect ne déborde pas sur /eleve/suivi.
- /tc/bibliotheque est ouvert à l'élève (_teachingCoreAutorise), donc « Voir tout » des ressources mène bien à une page.
- La cloche n'est retirée qu'en l'absence de destination. La démo continue de passer onNotifications.
- LecteurGroupe garde SqueletteGroupe par défaut.
- Cinq libellés nouveaux, tous déclarés dans libelles_sources.json.
- flutter test --concurrency=2 test/features/accueil_adulte/ : 58 réussis.

Captures ouvertes, autres que celles du premier relecteur :
- indisponible_320x2 : sobre, sans invention.
- horsligne_320x2 : bandeau et « Réessayer » en secondaire.
- chargement_320x2 : grille Bento empilée, sans donnée.
- historique_vide_320x2 : aucun mot coupé.
- contenu_390_sombre : contraste correct.

Les quatre défauts mineurs du premier relecteur sont réels. Je n'en conteste aucun.

Il a manqué un défaut majeur de preuve. L'écoute de la capacité par le routeur fait toute la redirection dans le vrai parcours de connexion, et aucun test ne la couvre. Je l'ai démontré par mutation (28 tests sur 28 restent verts) et par un test qui échoue sur le mutant mais réussit sur la tête. Le code est donc correct, mais sans contre-épreuve. Ce défaut n'a aucun effet en production aujourd'hui : la capacité y est toujours fausse, faute de source avant BR-1.

La décision ACCEPTEE_AVEC_RESERVES tient sur le fond. Il faut toutefois ajouter aux réserves, avant fusion, ce test de capacité servie après la première navigation, plus les deux mineurs relevés ici : l'incohérence des « Voir tout » sur mobile et le registre EA-BR.md absent.

- Défaut manqué (majeur) — lib/core/router/app_router.dart:146-153 (ref.listen<bool>(capaciteAccueilAdulteProvider, ... rafraichisseur.declencher())) ; test/features/accueil_adulte/accueil_adulte_route_test.dart : Aucun test ne couvre le réveil du routeur. C'est pourtant ce qui fait la redirection dans le vrai parcours : à la connexion, l'élève arrive sur /eleve avant que la capacité soit lue, et la capacité arrive ensuite. Tous les tests de navigation appellent routeur.go(depart) une fois l'application stabilisée, donc la capacité est déjà résolue au moment de la redirection. Retirer l'écoute ne fait échouer aucun test. Le code de la tête est correct (je l'ai prouvé), mais l'invariant central de l'étape (« /eleve s'ouvre sur l'Accueil adulte quand la capacité est servie après la session ») n'a pas de contre-épreuve. Une régression partirait sans alerte. Le premier relecteur n'a pas essayé cette mutation.
  Preuve : Mutation : suppression des trois lignes ref.listen(capaciteAccueilAdulteProvider…) dans app_router.dart, puis flutter test --concurrency=2 test/features/accueil_adulte/accueil_adulte_route_test.dart : « +28: All tests passed! ». Test ajouté par moi (zz_cr5_test.dart, supprimé ensuite) : accueilAdulteProvider surchargé par un Completer, départ /eleve, lieu == /eleve et AccueilElevePage affichée, puis complete(accueilDemo()) et pump. Sur la tête : réussi, lieu == /eleve/adulte. Sur le mutant : échec, « Expected: '/eleve/adulte' Actual: '/eleve' ». Fichiers restaurés par git checkout, worktree cr-5 retiré.
- Défaut manqué (mineur) — lib/features/accueil_adulte/accueil_adulte_page.dart (SectionHeader « Dernières séances ») et emplacements_groupe.dart (BlocBibliotheque) ; capture contenu_390_sombre.png : Sur mobile, les deux « Voir tout » voisins ne sont pas placés de la même façon. Celui des dernières séances passe sous le titre et s'aligne au début, car SectionHeader place toujours l'action sous le titre en dessous de 600 px (section_header.dart:51-53). Celui des ressources reste sur la ligne du titre, au bord de fin. Le commentaire du lot annonce pourtant le « même lien tertiaire que les ressources ». L'incohérence est visible à 390 px avec le texte ×1, alors que le titre « Dernières séances » est court.
  Preuve : docs/current/captures/DASH-EA-PROD/contenu_390_sombre.png : « Voir tout » sous « Dernières séances », à gauche ; « Voir tout » à droite de « Ressources de la classe ». section_header.dart:51-53 : actionSousTitre = texte agrandi || largeur < 600.
- Défaut manqué (mineur) — docs/current/DASH_STRATEGIE.md §3.7 « Reste » ; historique_seances_adulte_page.dart:11-14 ; accueil_adulte_page.dart (doc de capaciteAccueilAdulteProvider) : Les deux besoins serveur, la source de l'historique complet (prolongement d'EA-BR-06) et la capacité rendue avec la session, sont renvoyés à « une ligne à ajouter à EA-BR.md ». Ce registre n'existe pas dans la lignée revue, donc ces besoins ne sont inscrits dans aucun registre de besoins serveur. Ils ne sont consignés que dans le « Reste » de DASH_STRATEGIE et dans des commentaires de code.
  Preuve : git ls-tree -r --name-only HEAD | grep -i ea-br : vide. EA-BR.md n'existe que sur d'autres branches (commits 05de80fd, edf11193, 9a091d80).
