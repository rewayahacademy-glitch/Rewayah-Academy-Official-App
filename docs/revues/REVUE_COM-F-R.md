# Revue COM-F-R : socle Communications V1 (COM-F)

- **Objet** : étape COM-F, branche `origin/ui/communications-v1` (HEAD `b0cc9243`), diff `f6ac3658..b0cc9243` (6 commits, 54 fichiers, +7407 / -51). Auteur : session 01FM3Arm.
- **Relecteur** : session 01KyPAZg, non auteur.
- **Date** : 4 octobre 2026.
- **Méthode** : lecture du diff, de §COM-F de `19_communications/02_DECOUPAGE.md` (version actuelle, compléments COM-0b compris), de `QUESTIONS.md` et de son historique (`5a363e93`, `3d9d2095`, `cf581dc9`). Outils et tests ciblés relancés dans `/home/user/rv-com-f`. Trois mutations. Quatre captures faites par une capture temporaire (fichier retiré). Fusion à blanc. Aucun commit, aucun push, `git status` propre.

## Verdict

**REFUSÉE** (confirmée par la contre-vérification en fin de rapport). Le code livré est propre, testé et discriminant : badge, carte pièce jointe, espace adaptatif, ports neutres, garde de démo, cloches, Studio, Communications sous Opérations. Mais §COM-F, tel qu'il est écrit aujourd'hui, n'est pas tenu. Les compléments COM-0b (commit pilotage `3d9d2095`, 14:10 UTC, avant le commit de corrections de l'auteur à 14:33 UTC) sont en partie absents. Or les cinq sous-branches partent déjà de ce socle. Sans correction, trois voies devront toucher un fichier du socle, ce que la règle 2 des fichiers interdit. Et les composants du socle échappent au contrôle de la galerie.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
|---|---|
| `dart run slang`, `build_runner` | code 0, 0 fichier modifié |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_jetons.dart \| grep -c "\["` | 39 (attendu 39) |
| Tests ciblés lot 1 : `test/core/communications/`, `classe_tuteur/`, `mes_classes_test`, `fiche_groupe_test`, `ma_classe_adulte/`, `admin_domaine_test`, `fixtures_isolees_test` | 310 verts, 54 sautés, 0 échec |
| Tests ciblés lot 2 : `test/router/`, `echanges_controleur_test`, `admin_coque_test`, `test/widgets/`, `admin_ad11_test`, `test/features/demo/` | 742 verts, 10 sautés, 0 échec |
| Tests ciblés lot 3 : `espaces_controleur_test`, `test/features/notifications/`, `test/features/journee/` | 110 verts, 30 sautés, 0 échec |
| `verifier_revue` règles CI (cartes-collees, bouton-recompose, libelle-ambigu, mot-interne, erreur-sans-action) | 1 violation, `coran_accessibilite.dart:688`, déjà dans le socle, hors COM |
| `verifier_revue --regle=libelle-sans-source` | aucune clé `com.*` signalée |
| Sous-branches `ui/com-msg`, `com-voc`, `com-commu`, `com-stu`, `com-ann` | les 5 existent et pointent exactement sur `b0cc9243` (merge-base = HEAD, 0 commit propre) |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` (28 commits d'avance) | 3 conflits : `lib/core/i18n/strings.g.dart` (généré, slang), `test/features/enseignant_classes/mes_classes_test.dart`, `tool/libelles_sources.json` |

Mutations, toutes remises en place avec `git checkout --` :

1. `badge_non_lu.dart` : icône retirée de la pastille, il ne reste que la couleur. Résultat : le test « chaque information a son mot ET son icone » échoue (1 échec).
2. `carte_piece_jointe.dart:197` : la référence opaque est affichée à côté du nom. Résultat : 8 échecs, dont « aucune URL, aucun chemin, aucune reference a l ecran ».
3. `routes.dart` : `notificationsPour(teacher)` renvoie null. Résultat : 2 échecs (cloche enseignant, `notificationsPour`).

## Points de la fiche, un par un

1. ✅ **Sous-branches** : les cinq existent et partent du socle (voir tableau).
2. ✅ **Q1, Le Studio pour l'admin seul, `/admin/studio`** : `routes.dart` (`adminStudio`), route hors `AdminShell` (`app_router.dart`, bloc COM-F). Action dans l'en-tête à partir de 600 (`admin_shell.dart`, `_BoutonStudio`). Sous 600, lien au pied du tiroir. Tests : « 1440 : Le Studio ouvre /admin/studio », « 390 : cloche dans l en-tete, Le Studio au pied du tiroir », « le controleur et le comptable n entrent pas dans Le Studio ».
3. ✅ en partie, ❌ en partie : **Q2, Communauté en raccourci sur Aujourd'hui**. La route `/enseignant/communaute` est une pose de la branche Aujourd'hui, sans nouvelle destination, et son retour ramène à Aujourd'hui (testé). En revanche, l'emplacement `EntreeCommunaute` dans `journee_page.dart` n'existe pas (compléments COM-0b, 02_DEC-10). Voir Défaut M1.
4. ✅ **Q4, Communications sous `/admin/operations/communications`** : la racine redirige vers Annonces. Trois onglets pairs (`ongletsCommunications`), domaine Opérations allumé, cible de recherche admin. Tests « Communications : sous Operations, trois onglets pairs » et « la recherche de l en-tete trouve les Communications ». La ligne du tableau de bord admin manque (Défaut M1).
5. ✅ **Ports neutres** : `ModerationIndisponible` (COM-BR-06), `ElementsEnregistresIndisponibles` (COM-BR-12), `PolitiquePiecesJointesIndisponible` (COM-BR-04) lèvent `CapaciteIndisponible`. `BlocCommunication` rend l'état indisponible sans « Réessayer » (test « capacite indisponible : etat indisponible, sans action »). Brouillons en mémoire de session, vidés au changement de compte (testé). Aucun port réel dans `main.dart`.
6. ✅ **Garde de démo** : `routesDemoCommunications` renvoie une liste vide hors `environnementAutoriseDemo`. `redirection.dart` n'admet `/demo/communications` sans session qu'en démo. Tests `demo_garde_test.dart` par environnement.
7. ✅ **Espace adaptatif 390/768/1440 dans la vraie coquille** : `espace_travail_adaptatif_test.dart:236-303` monte `NavShell` + `PageShell`. Résultat : 1 panneau à 390, 2 à 768 (largeur reçue inférieure à 768), 3 à 1440. Les seuils viennent d'`AppGabarit.classe`. L'état du contenu survit à la fermeture du contexte et au passage de 1440 à 768 (test dédié). Aucune colonne vide (tests « sans contexte », « sans liste ni contexte »).
8. ✅ **Fil Contrôleur inchangé** : `fil_controleur_inchange_test.dart` et `echanges_controleur_test.dart` sont verts. Les trois paramètres de `FilDiscussion` sont optionnels et vides par défaut.
9. ✅ **i18n fr/ar, comme le demande la fiche** : bloc `com`, six sous-blocs, mêmes clés en fr et en ar, avec une vraie traduction arabe (test « memes cles en fr et en ar »). Mais cela contredit la règle 4 actuelle du découpage, qui ne veut aucune clé `com` dans `ar.i18n.json` (voir mineur m1).
10. ✅ **STYLE (K-37/K-63)** : aucune couleur, police, rayon ou ombre en dur dans `lib/core/widgets/communications/` ni dans `lib/features/com_*`. Les tons viennent de `StatusPill`/`TonEtat` et `AppPalette` ; le filet de colonne vient de `palette.borderHairline`. Jetons : 39.
11. ✅ **UnreadUrgencyBadge, texte + icône** : chaque pastille a un mot et une icône (`badge_non_lu.dart`, `_IconeBadge` remplace le disque de couleur). La phrase sémantique est entière. La mutation 1 le prouve.
12. ✅ **Carte pièce jointe sans URL R2 brute** : `ReferencePieceJointe` refuse toute adresse, tout chemin et tout jeton, et ne s'écrit pas dans un journal. La carte n'affiche que le nom, le type et la taille. La mutation 2 le prouve.
13. ✅ **Un widget lit une capacité, jamais un rôle** : `AdminShell` reçoit `onNotifications` et `onStudio` du routeur. Le choix de la cloche (`Routes.notificationsPour(role)`) est fait dans le routeur, pas dans un widget. La modération lit `CapacitesModeration`.
14. ✅ **Cloches (Q5)** : enseignant, contrôleur et admin, y compris sous 600. Le retour se fait vers la racine du rôle (testé pour l'enseignant). L'élève n'a pas de cloche (testé). Composition avec `RaccourciEspaces` : la cloche lit `ActionsEnteteCoquille.de` sous `EnteteEspaces` et s'ajoute au raccourci. `espaces_controleur_test` reste vert, mais aucun test ne montre les deux ensemble sur un compte à plusieurs espaces (mineur m4).

Captures : `docs/current/captures/` ne contient aucun dossier COM-F (les captures sont prévues à COM-CAPT). J'ai produit quatre captures temporaires avec `outil_capture.dart` :
- `planche_390_clair` : les pastilles « Urgent », « 3 non lus », « Mention », « Action requise », « 1 non lu », « À lire » ont chacune une icône et un mot. Les cartes de pièce jointe affichent le nom, « PDF 640 Ko » et l'état en toutes lettres, avec le thème Rewayah. Aucune référence n'est visible.
- `planche_320x2_sombre` (320 px, texte ×2, sombre) : aucun débordement, pastilles lisibles en sombre. Le nom du fichier passe à la ligne aux tirets (« devoir- / sourate-al- / mulk.pdf »), et le lien « Retirer devoir-sourate-al-mulk.pdf » prend 4 lignes (mineur m3).
- `espace_1440_clair` : trois colonnes, liste (256), contenu, contexte avec titre et bouton fermer. Les colonnes sont séparées par un filet fin, sans carte ni ombre.
- `espace_768_sombre` : produite, non commentée plus avant.

## Défauts retenus

### MAJEUR

**M1. Compléments COM-0b de §COM-F non appliqués, alors que les voies sont déjà ouvertes.** Absents du diff :
- `lib/features/com_communaute/entree_communaute.dart` et sa pose dans `journee_page.dart`. Il faut aussi le test « quatre blocs au plus » (Q2, 02_DEC-10).
- La ligne « Communications » de `tableau_de_bord_page.dart` vers `/admin/operations/communications` (UX_REV-03, retirée de COM-ANN-2).
- `lib/core/communications/capacites_communication.dart` : `CapaciteCommunication` et `PortCapacitesCommunications` neutre (COM-BR-A01). Le commentaire `COM-BR-nn` de `capacite_indisponible.dart` manque aussi.
- Les icônes des voies dans `app_icons.dart` (02_DEC-01). Le Studio emprunte `AppIcons.discussion`.

Effet : la règle 2 interdit à COM-COMU-1, COM-ANN-2, COM-STU et COM-ANN de toucher `journee_page.dart`, `tableau_de_bord_page.dart`, `app_icons.dart` ou la capacité du socle. Ces voies sont bloquées, ou bien elles casseront la règle.

**M2. Composants du socle hors du contrôle de la galerie.** Les quatre composants (et `composer_texte.dart`) sont dans `lib/core/widgets/communications/`. Or `test/widgets/catalogue_galerie_test.dart:240-252` ne lit que la racine (`listSync()` sans `recursive`). Aucune entrée n'existe dans `composantsDuCatalogue` ni dans `catalogue_galerie.dart`. 02_DEC-13 exige la racine de `lib/core/widgets/`, le nom en serpent de la classe (`BadgeNonLu` donne `badge_non_lu`, ce qui convient), et au moins deux états en galerie.

### mineurs

- m1. `ar.i18n.json` reçoit 165 lignes `com`, alors que la règle 4 actuelle dit « aucune clé com » (repli slang) et que la règle 5 gèle ce fichier après COM-F. La fiche de revue, elle, demande « fr/ar ». Le pilotage doit trancher : soit garder l'arabe et mettre à jour la règle 4, soit retirer les clés.
- m2. `/admin/notifications` est montée avec `_CoquilleAdmin(domaine: null)` (`app_router.dart`, bloc COM-F). Le complément UX_REV-07 demandait `AdminDomaine.accueil`. Le retour vers `/admin` est correct.
- m3. Carte pièce jointe à 320 ×2 : le libellé « Retirer <nom complet> » est long (4 lignes) et le nom passe à la ligne aux tirets. Il n'y a ni débordement ni mot coupé hors des tirets. Mettre le nom dans le libellé sémantique seulement, et garder « Retirer » à l'écran.
- m4. Pas de test « cloche et raccourci Espaces visibles ensemble » sur un compte à plusieurs espaces (complément 02_DEC-03).
- m5. Fusion avec `corrections/revue-directeur-2026-10` : 3 conflits (`strings.g.dart` à régénérer, `mes_classes_test.dart`, `libelles_sources.json`).

## Pour accepter

Étape proposée **COM-F-b**, sur `ui/communications-v1`, avant tout travail des voies :
1. Appliquer M1 : `entree_communaute.dart` posé dans un bloc toujours rendu de `journee_page.dart` (test : 4 blocs au plus), ligne « Communications » du tableau de bord admin, `capacites_communication.dart` avec un port neutre, commentaire `COM-BR-nn`, icônes des voies dans `app_icons.dart` (dont une icône propre au Studio).
2. Appliquer M2 : déplacer les composants à la racine de `lib/core/widgets/`, avec leurs entrées dans `catalogue_galerie_test.dart` et `catalogue_galerie.dart` (deux états chacun).
3. Traiter m2 et m4. Faire trancher m1 par le pilotage.
4. Avancer les cinq sous-branches sur le nouveau commit du socle (elles n'ont encore aucun commit propre, l'avance est donc sans risque).
5. Relancer `analyze` et jetons (39), puis `test/core/communications/`, `test/widgets/`, `test/router/` et `test/features/journee/`, et citer les chiffres.

## Contre-vérification

- **Relecteur** : second relecteur sceptique, session 01KyPAZg, non auteur. Même worktree `/home/user/rv-com-f`, même cible `b0cc9243`.
- **Méthode** : relecture de §COM-F actuel (`git show origin/pilotage/tuteur-v1:19_communications/02_DECOUPAGE.md`, lignes 36 à 96) et de la chronologie des commits. Recherche directe dans le code de chaque élément de M1 et M2. Trois captures temporaires que j'ai faites moi-même (arabe 320 ×2 sombre, arabe 390 clair, français 320 ×2 sombre). Une mutation de plus. Fichier de capture retiré, `git status` propre.

### Contrôles relancés

| Contrôle | Résultat |
|---|---|
| `slang`, `build_runner` | code 0 |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_jetons.dart \| grep -c "\["` | 39 |
| `test/core/communications/` + `test/widgets/catalogue_galerie_test.dart` | 149 verts, 0 échec |
| Mutation 4 : garde de `routesDemoCommunications` neutralisée (`if (false && ...)`) | 3 échecs dans `demo_garde_test.dart` (« prod », « production », « Production »). Remise en place. |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` | mêmes 3 conflits : `strings.g.dart`, `mes_classes_test.dart`, `libelles_sources.json` |
| Sous-branches | les 5 pointent sur `b0cc9243`. Mais `origin/ui/communications-v1` est maintenant à `d04bbeba` (voir n2) |

### Tentative de réfutation des majeurs

**M1 : confirmé, non réfuté.**
- Chronologie : `3d9d2095` (COM-0b) est daté 14:10:41 UTC. Le commit de corrections `b0cc9243` est daté 14:33:10 UTC. Le texte de §COM-F dit lui-même « à lire par la session COM-F en cours ». L'auteur ne peut pas plaider une fiche postérieure.
- `lib/features/com_communaute/` ne contient que `communaute_page.dart`. Pas d'`entree_communaute.dart`. `journee_page.dart` n'est pas dans le diff `f6ac3658..b0cc9243` (0 occurrence de « Communaute »).
- `tableau_de_bord_page.dart` : 0 occurrence de « communication ».
- `lib/core/communications/` : 5 fichiers, pas de `capacites_communication.dart`. `capacite_indisponible.dart` : 0 occurrence de « COM-BR ».
- `app_icons.dart` absent du diff. `admin_shell.dart:428` et `:710` utilisent `AppIcons.discussion` pour Le Studio.
- Ajout : à `b0cc9243`, le commentaire de `journee_page.dart:10-12` dit encore que la cloche est retirée, alors que COM-0b demande de le mettre à jour. C'est corrigé seulement dans `d04bbeba`, que les sous-branches n'ont pas.

**M2 : confirmé, non réfuté.** `test/widgets/catalogue_galerie_test.dart:240-252` appelle `Directory('lib/core/widgets').listSync()` sans `recursive`. Les cinq fichiers sont dans `lib/core/widgets/communications/`. Aucun n'apparaît dans `catalogue_galerie_test.dart` ni dans `catalogue_galerie.dart` (grep vide). Le test de galerie est vert uniquement parce qu'il ne regarde pas ce dossier. La règle 2 (« composants à la racine, pas de sous-dossier, 02_DEC-13 ») et la règle 5 (galerie gelée après COM-F) rendent ce point bloquant : aucune voie ne pourra le rattraper.

**Mineurs du premier relecteur** : m1 à m5 confirmés. Pour m2, `app_router.dart:1041` porte bien `domaine: null`. Pour m3, le code le montre (`carte_piece_jointe.dart:241` et `:252` : `p.ouvrir(nom:)` et `p.retirer(nom:)` mettent le nom dans le texte visible). Le lien « Ouvrir <nom> » a le même défaut.

### Ce que le premier relecteur a manqué

- **n1 (mineur, visible)** : l'état d'erreur répète son titre. `fr.i18n.json:4704-4705` : titre « Impossible de charger ce contenu. », phrase « Impossible de charger ce contenu. Vérifiez votre connexion, puis réessayez. ». Sur la capture (fr 320 ×2 sombre, ar 390 clair), on lit deux fois la même phrase, en gras puis en clair. Correction : la phrase garde seulement « Vérifiez votre connexion, puis réessayez. » (même chose en arabe).
- **n2 (mineur, pilotage)** : `origin/ui/communications-v1` a avancé à `d04bbeba` (cloches Q5, touche `admin_shell.dart`, `entete_page.dart`, `journee_page.dart`, `app_router.dart`). Les cinq sous-branches restent sur `b0cc9243`. Elles ne partent donc plus du socle actuel. Les avancer en même temps que COM-F-b. Ce commit n'est pas couvert par la présente revue.
- **n3 (cosmétique)** : sur la carte pièce jointe, « Retirer <nom> » est en grand (tertiaire) alors que « Ouvrir <nom> » est un petit lien. À 320 ×2 le contraste de taille se voit. Il disparaît si m3 est appliqué (verbe seul à l'écran).

### Captures (faites par moi, fichier de test retiré)

- `rv2_ar_dark_320x2` : RTL juste. Les pastilles « عاجل », « 3 غير مقروءة », « إشارة », « إجراء مطلوب » ont chacune icône et mot. La flèche d'« إجراء مطلوب » et celle de « فتح » sont bien miroir. Pas de débordement, pas de mot arabe coupé. « إعادة المحاولة » passe sur deux lignes dans le bouton de l'état d'erreur, sans coupure. Le nom du fichier latin passe à la ligne aux tirets (m3).
- `rv2_ar_light_390x1` : propre. Un seul bouton contour par carte, aucun bouton plein, aucun bouton dans un bouton (la carte n'est pas tappable). Erreur répétée (n1).
- `rv2_fr_dark_320x2` : aucun débordement. « Retirer devoir-sourate-al-mulk.pdf » sur 4 lignes (m3). Titre de l'erreur répété dans la phrase (n1).
- Aucune couleur, police, rayon ou ombre en dur dans les fichiers Dart du diff (grep `Color(0x`, `Colors.`, `fontFamily`, `BorderRadius.circular(<nombre>)`, `BoxShadow(` : 0 résultat). Aucun texte en dur hors messages d'`assert`. Aucune lecture de rôle hors du routeur.

### Verdict après contre-vérification

**REFUSÉE, confirmée.** M1 et M2 tiennent, preuves à l'appui. Aucun nouveau majeur. Trois nouveaux points mineurs (n1, n2, n3). L'étape COM-F-b proposée plus haut reste la bonne, avec en plus : retirer la répétition du titre d'erreur (n1), et avancer les cinq sous-branches sur le commit final du socle, qui contiendra `d04bbeba` (n2).

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : ui/communications-v1 @ b0cc9243 : 5571 réussis, 0 échec.
