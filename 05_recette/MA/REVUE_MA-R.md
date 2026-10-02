# REVUE_MA-R : revue croisée de la vague Mode Accessibilité (MA-R)

Rédigée le 02/10/2026 par une session indépendante, qui n'a écrit aucun code de cette vague. Revue en lecture seule : rien n'a été corrigé ni poussé sur `ui/*`.

- **Code** : branche `ui/accessibilite-v1` @ `4743d0e` (clone propre, hors `C:\RA\accessibilite`).
- **Diff de la vague** : `git diff 1108a4a..4743d0e`, de MA-1b à MA-12, 47 fichiers.
- **Références** : `memoire/ACCESSIBILITE-2026-09-27.md` (MA1 à MA24), `CLASSE-ENTREE` (R1 à R21), `ENSEIGNANT` (E1 à E20), `DESIGN-GOV` (contrats A à E), `STYLE-REFERENCE-CL4` (K-42) ; consignes du 02/10 : K-53 à K-59, D5 ; décisions A4 = a, A8 = a, S7 = b ; `05_recette/MA/MA_RAPPORT.md`, `15_accessibilite/MA-BR.md`.

## Verrou

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK |
| `dart analyze --fatal-infos lib test tool` | **No issues found!**, code 0 |
| `flutter test test/accessibilite test/core/accessibilite test/features/accessibilite_recette test/widgets/setting_row_valeur_test.dart test/router/navigation_test.dart` | **All tests passed!** +364, ~92 ignorés (captures sans `CAPTURE_DIR` et 4 tests sautés de MA-12), code 0 |
| Les 4 tests sautés de `ma12_recette_test.dart` rejoués en local (saut retiré, non commité) | **4 échecs**, qui confirment les défauts 1 et 2 de la recette (voir B1, B2) |

## Verdict

**PAS PRÊTE pour la fusion.**

**Bilan : 2 bloquants, 4 majeurs, 9 mineurs.**

- Les deux bloquants sont les défauts 1 et 2 de MA-12, **confirmés en exécution** : Mon espace est inutilisable à 200 % sur un téléphone ordinaire, et ses interrupteurs n'ont pas de nom pour le lecteur d'écran (WCAG 4.1.2, niveau A). Pour la vague Accessibilité, ce sont des échecs de fond sur l'un de ses sept écrans.
- Les majeurs sont courts : salle en icônes seules à 200 %, zoom du Coran perdu en Mode Accessibilité, aide de Mon espace qui ne mène nulle part, descriptions de la page Interface hors K-58.
- Le rendu du Coran est **intouché** (voir Conformités).

## BLOQUANT

### B1. Mon espace à 200 % sur 390 × 844 : la tête de page déborde de 147 px (MA15, K-42 point 6) — défaut 1 CONFIRMÉ

- **Preuve** : `test/accessibilite/ma12_recette_test.dart:238` (saut retiré en local) : `A RenderFlex overflowed by 147 pixels on the bottom`, pour Mariam et pour Idriss.
- **Cause** : `lib/core/widgets/page_shell.dart:181-186`. `...tete` (titre, `entete` = `t.compte.reglagesIntro`) est posé **hors** du `SingleChildScrollView`, dans la `Column` bornée. À 200 %, titre sur plusieurs lignes, phrase d'intro et barre basse de 4 destinations sur deux lignes ne laissent rien au corps. En build release, le corps disparaît sans erreur.
- **Correction attendue** (dans `PageShell`, pour ne rien changer aux autres rôles en taille normale) :
  1. calculer `final bool teteDefile = defilante && MediaQuery.textScalerOf(context).scale(1) > 1.3;` ;
  2. si `teteDefile`, rendre `Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[...tete, corps])))` au lieu de `...tete` + `Expanded(SingleChildScrollView(corps))` ;
  3. sinon, garder le code actuel tel quel.
  4. Rétablir le test : supprimer `_sautDebordement` (`ma12_recette_test.dart:194` et `:238`).
- Note : le défaut vient de `PageShell` (antérieur à la vague), mais il est révélé par un écran de la vague. La même page Réglages des autres rôles en profite.

### B2. Interrupteurs et ronds de choix sans nom pour le lecteur d'écran (MA16, WCAG 4.1.2) — défaut 2 CONFIRMÉ

- **Preuve** : `ma12_recette_test.dart:265` (saut retiré en local) : « action sans libellé sur Mon espace », pour Mariam et Idriss.
- **Cause** : `lib/core/widgets/setting_row.dart:39-44` pose `Semantics(label: title)` via `Pressable.selon` sur la ligne. Mais avec `onPress` nul, la ligne n'est pas un bouton. Le `controle` (ligne 110 : `Switch.adaptive`, `Radio`) forme un nœud tactile à part, **sans libellé**. TalkBack annonce « Activé, interrupteur » sans dire lequel, en deux arrêts par ligne.
- **Correction attendue** :
  1. dans `SettingRow.build`, quand `controle != null` et `onPress == null`, envelopper tout le `Pressable.selon` dans `MergeSemantics(child: …)`. Le titre et la description fusionnent alors avec l'état coché du contrôle, en un seul nœud et un seul arrêt ;
  2. faire de même dans `_Ligne` de `lib/core/widgets/groupe_reglages.dart` quand `ligne.controle != null` et `ligne.onPress == null` : c'est le cas de la bascule « Mode Accessibilité » d'Idriss (`mon_espace_accessibilite.dart:151-157`) ;
  3. rétablir le test (`_sautLibelle`, `ma12_recette_test.dart:196` et `:265`) ;
  4. ajouter au test un contrôle sur `ReglagesComptePage` en présentation standard (Compte de tous les rôles, HU-1).

## MAJEUR

### M1. Salle à texte agrandi : commandes en icônes seules (MA9, MA20) — défaut 3 CONFIRMÉ

- **Cause** : `lib/features/salle_seance/dock_seance.dart:439-443`. `texteAgrandi = textScaler.scale(1) > 1` fait passer la barre en icônes seules (EN-12), libellé seulement lu. En Mode Accessibilité, c'est précisément l'élève qui agrandit le texte qui perd « Quitter », « Caméra », « Parler ».
- **Arbitrage** : EN-12 traite le débordement, il n'interdit pas le texte. MA9 (« jamais une icône seule ») s'applique donc sans contredire E1 à E20.
- **Correction attendue** :
  1. dans le `LayoutBuilder` du dock, si `AppMetriques.of(contexte).mode == InterfaceMode.enfant && texteAgrandi`, ne pas retourner `_DockEtroit` ;
  2. rendre à la place un `Wrap` de cases de largeur `contraintes.maxWidth / 2` (deux commandes par ligne), chaque case avec le disque (≥ `cibleTactile`) et le libellé visible dessous, sur deux lignes au plus (`maxLines: 2`, `softWrap: true`), sans mot coupé ;
  3. garder « Quitter » séparé des autres par l'écart existant (MA10) ;
  4. inchangé pour la présentation standard et pour l'enseignant (EN-12) ;
  5. test : salle de Mariam à 390 px et 200 %, chaque libellé (`Quitter`, `Caméra`, `Parler`, `Agrandir`) trouvé par `find.text`.

### M2. Coran en Mode Accessibilité : le grossissement enregistré n'est pas rétabli, puis il est écrasé (MA22, K-51)

- **Cause** : `lib/features/accueil_eleve/coran_accessibilite.dart:124-136` (`_ouvrir`). Il appelle `allerA(reprise.page)`, mais **pas** `definirZoom(reprise.zoom)`, contrairement à `MushafPage` (`lib/features/tc_mushaf/mushaf_page.dart:94-98`, « un lecteur qui a grossi son texte le retrouve grossi »).
- **Effet** : à la première page tournée, `LecteurCoranAccessibilite._enregistrer` (`coran_accessibilite.dart:358-369`) écrit la position avec `etat.zoomLocal` par défaut. Le zoom personnel est perdu, y compris pour le lecteur standard. Un élève malvoyant retrouve son texte petit.
- **Correction attendue** :
  1. dans `_ouvrir`, après `lecture.allerA(...)`, ajouter `lecture.definirZoom(reprise.zoom);` ;
  2. test dans `coran_ma7_test.dart` : un faux port rend une position avec un zoom de 1,6, on ouvre, `lectureCoranProvider.zoomLocal == 1.6`, puis on tourne une page et on vérifie que la position mémorisée garde 1,6.

### M3. « Besoin d'aide ? » de Mon espace ne mène nulle part (MA14, MA9)

- **Cause** : `lib/features/accueil_eleve/mon_espace_accessibilite.dart:166-175`. La ligne d'aide n'a pas d'`onPress`, alors que la même ligne de l'Accueil (`accueil_accessibilite.dart:151-155`), de l'après-séance (`apres_seance_accessibilite.dart:182-185`) et du Coran (`coran_accessibilite.dart:294-297`) ouvre l'aide. Même libellé, autre comportement : MA9 et MA14 (« l'entrée mène à la page d'aide honnête existante ») ne sont pas tenus.
- **Correction attendue** :
  1. ajouter un paramètre `final VoidCallback onAide;` à `MonEspaceAccessibilite` ;
  2. le passer à la ligne (`onPress: widget.onAide`), en retirant la `legende` `aucunCanal` (elle est dite sur la page d'aide), comme sur l'Accueil ;
  3. le brancher dans `demo_accessibilite_page.dart:464` comme les autres écrans.

### M4. Page Interface du tuteur : descriptions hors K-58, et une affirmation fausse au regard de MA2

- **Cause** : `assets/i18n/fr.i18n.json`, `ficheEleve.interface.guideeDescription` / `standardDescription`, lus par `lib/features/foyer/fiche/interface_page.dart:127` et `:134`.
  - Aucune des deux ne donne la ligne « quand / conséquence » demandée par K-58.
  - « Toutes les rubriques de Rewayah » laisse croire que le Mode Accessibilité en retire. Or il a les mêmes 4 destinations, les mêmes fonctions et les mêmes droits (MA1, MA2). Le tuteur est donc mal informé.
- **Correction attendue** (vouvoiement, tuteur adulte ; aucune mention d'âge ni de difficulté) :
  - `guideeDescription` : « Quand {prenom} préfère des écrans aérés : textes plus grands, une action à la fois. Mêmes rubriques et mêmes droits. » ;
  - `standardDescription` : « Quand {prenom} est à l'aise avec des écrans plus denses : plus d'informations par écran. Mêmes rubriques et mêmes droits. » ;
  - passer `prenom: profil.prenom` aux deux appels ;
  - régénérer `strings_fr.g.dart`.

## MINEUR

1. **Mots coupés à 200 % (MA15)** — défaut 4 CONFIRMÉ, avec une correction de localisation :
   - « Mari / am » : `mon_espace_accessibilite.dart:122-131`. Rangée avatar + `headlineSmall`. Correction : à `textScaler.scale(1) > 1.3`, mettre l'avatar au-dessus du prénom (`Column`, `crossAxisAlignment.start`) au lieu de la `Row`.
   - « Accessibilit / é », « Notification / s » : **ce n'est pas `groupe_reglages.dart:103`**. Mon espace ne passe aucun `titre` à `GroupeReglages`. Ce sont les `SectionHeader` de `compte_page.dart`, rendus par `lib/core/widgets/section_header.dart:45` et `:54` (`headlineSmall`). Correction : `styleTitre = (textScaler.scale(1) > 1.3 && largeur < 600) ? textes.titleLarge : textes.headlineSmall`.
   - « mouvemen / ts », « autom / atiquement » : `setting_row.dart:83-110`. À 200 %, l'`Expanded` est comprimé par l'icône et le `Switch`. Correction : à `echelle > 1.3`, disposer la ligne en colonne : rangée (icône, titre), puis la description pleine largeur, puis le `controle` aligné en fin (`Align(alignment: AlignmentDirectional.centerEnd)`).
   - Ajouter au test M12 une vérification « aucun mot plus large que son `Text` » (mesure du mot le plus long, comme `_motLePlusLong` de `coran_accessibilite.dart`), puisque les captures seules l'ont trouvé.
2. **Régression visuelle chez un autre rôle (`setting_row.dart:136`).** `controle != null` force la valeur **sous** le libellé à toutes les largeurs. Les réglages d'observation (`lib/features/tc_observation_ui/module_reglages_observation.dart:120-148`, valeur + pas à pas) voient leur valeur éloignée du pas à pas, même à 1440 px et 100 %. Correction : ne forcer `dessous` que si `echelle.scale(1) > 1.3`, sinon réserver la largeur du contrôle dans `reserve` (mesurer le `controle` est impossible : retenir `2 × cibleTactile` pour un pas à pas, ou ajouter un paramètre `largeurControle`). Aucune autre ligne avec valeur et contrôle trouvée dans `lib/`.
3. **K-59, page Interface** : `ficheEleve.interface.echec` donne la cause et l'action, pas ce qui reste fiable. Ajouter : « La présentation actuelle de {prenom} reste inchangée. »
4. **« Reprendre là où tu t'es arrêté(e) »** (`fr.i18n.json`, `accessibilite.coran.reprendre` / `reprendreVous`) : le « (e) » est lu tel quel par TalkBack et alourdit (MA8). Remplacer par « Reprendre à ta dernière page » / « Reprendre à votre dernière page ».
5. **Mon espace dense en Mode Accessibilité (MA7, K-42)** : `compte_page.dart:326-402` montre des lignes inactives, sans effet pour l'élève : « Arabe, non disponible », « Fuseau, non disponible », « Appareils » (désactivé hors tuteur), « Confidentialité » (désactivé), « Notifications du foyer ». La vague masque déjà « Réduire les effets » pour cette raison (`compte_page.dart:296`). Correction : sous `if (!modeAccessibilite)`, masquer de même `arabe`, `fuseau`, `appareils` si `!foyerDisponible`, `confidentialite` et `notificationsFoyer`.
6. **Écrans MA joignables seulement en démonstration** : Accueil, Ma classe, Coran, Mon espace et après-séance MA ne sont rendus que par `demo_accessibilite_page.dart:396-464`. En production, la barre à 4 destinations (MA-2) et la salle MA sont actives, mais l'Accueil reste `accueil_eleve_page.dart`. C'est voulu (K-35), mais aucune ligne de `MA-BR.md` ne le dit. Ajouter « MA-BR-4 : brancher les écrans MA sur `/eleve/accueil`, `/eleve/suivi`, `/eleve/coran`, `/compte` quand `modeAccessibiliteActifProvider` est vrai » (règle « brancher l'entrée, pas la route »).
7. **RTL forcé en français** (défaut 5) : confirmé, sans objet tant que l'arabe n'est pas livré. Ligne LG-1 : isoler heures, durées et nombres (`\u2068…\u2069` ou `Directionality(textDirection: TextDirection.ltr)` autour des valeurs).
8. **Bandeau « Démonstration » rogné en RTL** (défaut 6) : démonstration seulement, sans effet en production.
9. **Recette incomplète** : pas de capture 768 px de la page Interface ; 200 %, RTL et clavier de la fiche de séance enseignant non prouvés ; TalkBack réel non fait. À faire après B2 (MA-RC).

## Conformités vérifiées

- **Rendu du Coran intouché** : aucun fichier de `lib/features/tc_mushaf/`, `lib/core/tc_coran/`, `lib/core/coran/` ni asset du Coran dans le diff. Les seuls fichiers « coran* » sont nouveaux et d'enrobage : `coran_accessibilite.dart`, `coran_demo_accessibilite.dart`, le test `coran_ma7`. `VuePageMushaf`, `VueVersetAgrandi` et `FeuilleNavigationCoran` sont réutilisés tels quels.
- **Lecteur MA propre (`LecteurCoranAccessibilite`) au regard de K-10 / K-51** : les vues de rendu sont réutilisées, mais l'enrobage de `MushafPage` est **recopié** : minuterie d'enregistrement de 3 s, double barrière d'origine, zoom, attribution Tanzil (`coran_accessibilite.dart:322-505`). La recopie a déjà divergé (M2). C'est le prix de l'interdiction de toucher `tc_mushaf`. Voir la question 1.
- **K-53** : aucun « admin » visible dans les textes ajoutés. Seul « Administration » existant apparaît ailleurs.
- **Handicap et diagnostic** : aucun texte ne nomme une difficulté. « Mode Accessibilité » est le seul libellé côté enseignant (`fiche_seance.dart`, Q6), et « Aucune raison n'est demandée » figure côté tuteur.
- **D5 / S7 = b** : la demande du mineur a trois états (`mon_espace_accessibilite.dart:85-107`), « non confirmé » avec cause, action et ce qui reste fiable (K-59). Aucune écriture optimiste. Le port est neutre (`port_demande_presentation.dart`).
- **A4 = a** : tutoiement selon l'âge et non selon la présentation (`emplacement_entree.dart`, `VueSeance.tutoiement`, clés `accessibilite.tutoiement`) ; Idriss est vouvoyé.
- **A8 = a** : libellés existants réutilisés (`t.eleve.coran.pagePrecedente`, `t.compte.reessayer`, `t.tc.coran.navigation.ouvrir`).
- **K-56** : un seul bouton plein par écran (Accueil « Voir ma classe » seulement si l'entrée n'est pas un bouton ; après-séance « Retour à la Classe » ; Coran une action principale). Les autres actions sont en tertiaire, en secondaire ou en lignes.
- **K-55** : cartes séparées par `Ecart.vSection` (Mon espace, Accueil).
- **MA15** : deux colonnes de l'Accueil seulement si largeur / facteur ≥ 840 (`accueil_accessibilite.dart:32`).
- **MA12** : mouvement réduit posé une fois sous `MaterialApp.builder`, appareil **et** préférence locale (tests `mode_accessibilite_test`, `ma11`).
- **MA17** : 4 destinations dans les deux présentations, routes inchangées (`navigation_test` vert, aucune route orpheline).
- **MA19** : initiales en repli (`photo_enseignant.dart`, `repliInitiales`) seulement côté élève ; l'état « photo manquante » reste explicite côté enseignant.
- **`setting_row.dart` (MA-8, composant partagé)** : aucun débordement introduit (la réserve calculée suit la rangée réelle), tests de galerie et de compte verts. Seule réserve : le mineur 2.

## Questions au directeur

1. **Lecteur du Coran MA** : autorisez-vous, à HU-1, d'extraire la logique d'enregistrement et les commandes de `MushafPage` (hors rendu) dans un composant partagé, pour supprimer la recopie de `LecteurCoranAccessibilite` ? Recommandation : oui, à HU-1 seulement, rendu toujours intouché ; d'ici là, M2 corrigé dans la recopie.
2. **Salle à 200 %** : confirmez-vous que MA9 l'emporte sur EN-12 pour l'élève en Mode Accessibilité (libellés visibles, deux commandes par ligne) ? Recommandation : oui, comme décrit en M1.
