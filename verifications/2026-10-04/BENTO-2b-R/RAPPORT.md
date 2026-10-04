# BENTO-2b-R : revue croisée de corrections/c2-bento2b @ 641ef8b8

Date : 04/10/2026. Session 268bd1ef (n'a écrit ni BENTO-2 ni BENTO-2b). Revue en lecture seule
(aucun commit, aucun push).
Worktree : `D:\RA_TUTEUR\r-bento2b` (détaché). Diff `e7b94c3a..641ef8b8`.
Méthode : 6 relecteurs (M1 famille, bloc séance et Journée, tests, exécution et mutation, 32
captures, documents), puis 2 sceptiques par constat. Règle de gravité finale : un constat dont les
2 sceptiques réfutent est écarté ; sinon la gravité la plus fréquente des votes, la plus haute en
cas d'égalité. Les doublons entre angles sont fusionnés.

## Verdict : REFUSÉ (un défaut majeur, correction courte)

M1 de BENTO-2-R est levé et prouvé : avec l'ancien code, les tests 768 x1 échouent et nomment
« Durée » et « 45 min » (contre-épreuve). Mais « À terminer » (`journee_page.dart:846-893`) coupe
encore « terminer » et « Obligatoire » à 320 px texte x2 dès que « Voir tout » s'affiche (4
cahiers ou plus), en LTR et en RTL. Le test du lot n'utilise que 2 cahiers et ne mesure que le
`Wrap` : il ne prouve pas ce qu'il annonce. Le défaut existait avant le lot, mais le lot réécrit
ce bloc précisément pour supprimer cette coupe.

## Résultats des commandes

- `flutter analyze` (lib/features/accueil_famille, lib/features/journee, test/support et les 3
  fichiers de test) : **0 problème**. Un `dart analyze` sur 5 fichiers donne aussi 0 problème.
- `flutter test` sur `accueil_famille_test`, `journee_test`, `grille_bento_test` : **146 réussis,
  0 échec**. Les 21 tests « BENTO-2b » passent aussi seuls.
- Mutation d1 (ancien `accueil_famille_page.dart`) : échecs à 768 x1 LTR et RTL, avec
  `['Durée : Durée', '45 min : min']`, plus le test de largeur « 768 pleine ; 1440 côte à côte ».
  Les cas 320x2, 768x2, 1024x1, 1440x1 et 1440x2 passent encore sur l'ancien code.
- Mutation d2 (ancien `journee_page.dart`) : les 8 tests « À terminer » échouent, mais avec « Bad
  state: No element » (le finder `Wrap` ne trouve rien), pas en nommant le mot coupé. Avec une
  copie temporaire du test qui cherche la `Row` : 4 échecs à 320x2 et 390x2, LTR et RTL, `['À
  terminer : terminer']`, puis 8 sur 8 verts avec le code du lot (copie supprimée).
- Mutation d3 (ancien `bloc_seance.dart`) : échecs à 320 x2 LTR et RTL, avec
  `['Lundi', '21', 'septembre', 'Durée']`.
- Sondes M1 (vrai routeur, vraies polices, 600 à 1440, x1, x1,5, x2, LTR et RTL) : 0 coupe à x1
  de 600 à 1440 et à x1,5 ; coupes seulement à 600 x2 (« Durée », « 45 min ») et 620 x2
  (« Durée ») ; 640 x2 et au-delà : 0 coupe. Bascule pleine largeur / côte à côte à x1 entre 863
  (carte 735) et 864 (carte 360). Famille 320 à 599 px, x1 à x2 (120 cas) : 0 mot coupé, 0
  exception. Journée (204 cas au total) : coupes seulement à 320 x2 avec 4 cahiers.
- Mesure à 1024 x1 : grille 896, carte 440, côte à côte.
- `git status` propre à la fin, HEAD `641ef8b8`. Les 3 fichiers `windows/flutter/generated_*`
  réécrits par Flutter (fins de ligne) ont été restaurés.
- Fusion dans la branche commune réelle : `641ef8b8` est ancêtre de
  `origin/corrections/revue-directeur-2026-10` (fusion `fa64a6ad`, puis reprise `af20f6c2` de
  COUPE-MOTS-1). Sur les 7 fichiers lib et test du lot et le recensement, seul
  `test/support/aucun_mot_coupe.dart` diffère (blob 734bfb50 puis 2392dbbe, ajouts compatibles).
  Fusion à blanc avec c2-bento3 (`714b09e6`) : aucun conflit.
- Aucun fichier interdit touché (41 fichiers, dont 32 PNG : ni pubspec, ni supabase, ni .github, ni
  vercel.json, ni thème, ni Coran). Aucune couleur ni texte en dur ajouté.

## Confirmations (points tenus)

- M1 de BENTO-2-R levé : à 768 x1 la carte classe est pleine largeur (640 px), plus de « Duré/e »
  ni « 45 mi/n ». Prouvé par la contre-épreuve (d1) et par les captures 768 et 1440.
- Le seuil est lu sur la bonne largeur (colonne de `PageShell`, après rail et gouttière) ; aucun
  mot coupé à x1 de 600 à 1440, RTL identique au LTR, ordre de lecture conservé.
- Le repli « Durée sous l'heure » sous 96 px x échelle fonctionne et n'a pas de risque d'intrinsèque ;
  l'en-tête de la carte en `Wrap` est correct (la date reste entière à 320 x2).
- « À terminer » à 390 x2 avec 2 cahiers (cas de la fiche) n'est plus coupé ; rien n'est coupé
  non plus à 360 et 390 x2 avec 4 cahiers.
- Le test « moulinet » prouve maintenant le placement exact et le repli une colonne (m2 de BENTO-2-R
  levé). Le détecteur de mots coupés mesure vraiment la coupure (pas un simple test d'exception).
- Sémantique non régressée (en-têtes, `MergeSemantics` heure et durée, cible de 48 px).
- 32 captures présentes et ouvertes (famille et journée, 320, 390, 768, 1440, x1 et x2, clair et
  sombre) : pas de bande de débordement, sombre réellement sombre, contraste lisible.
- `BENTO_RECENSEMENT.md` : accueil famille et Aujourd'hui sont passés en « Fait », l'accueil élève
  est en « Pas de Bento (D14) » ; les lignes 27-28 sont fidèles au code.

## Défauts retenus

### M1 (MAJEUR) : « À terminer » coupe « terminer » et « Obligatoire » à 320 x2 avec « Voir tout »

- **Où** : `lib/features/journee/journee_page.dart:846-893` ; test
  `test/features/journee_test.dart:1081-1120`.
- **Preuve** : le `Wrap` reste l'enfant `Expanded` d'une `Row` (l.846-848) ; « Voir tout »
  (`LienFleche`, environ 122 px à x2, l.880-893) s'affiche dans la même `Row` dès que
  `tries.length > maximumATerminer` (3). Il ne reste qu'environ 162 px au titre. Sonde à 4 cahiers,
  320 x2, LTR et RTL : `[À terminer : terminer, Obligatoire : Obligatoire]`. À 360 et 390 x2 : rien
  de coupé. Le test du lot ne fournit que 2 cahiers (`_cahier('a')`, `_cahier('b')`), donc « Voir
  tout » n'est jamais monté, et `verifierAucunMotCoupe` ne mesure que le `Wrap` : il passe (8/8)
  alors que le cas réaliste (enseignant avec 4 cahiers en retard) casse. Le commentaire l.844-845
  (« un `Wrap` et non une `Row` ») est inexact : la `Row` existe toujours.
- **Gravité** : un sceptique la ramenait à mineur (défaut antérieur, cas 390 x2 de la fiche tenu) ;
  l'autre et le constat sur le test la maintiennent majeure : le lot réécrit ce bloc pour
  supprimer cette coupe et le test annonce « aucun mot coupé à 320 x2 ». Égalité, donc la plus
  haute.
- **Remède** : faire entrer « Voir tout » dans le `Wrap`, ou le passer sous l'en-tête quand la
  place manque. Test avec 2 et 4 cahiers, à 320 x2 et 390 x2, en mesurant toute la `Row` (pas
  seulement le `Wrap`). Corriger le commentaire l.844-845.

### Mineurs

- **m1 : famille 600 à 630 px, texte x2, « Durée » et « min » coupés dans la carte pleine largeur.**
  `lib/features/accueil_famille/bloc_seance.dart:471-538` (`_HeuresLarges`, inchangé) et
  `accueil_famille_page.dart:320-325`. Sonde : 600 x2, carte 472, 2 coupes ; 620 x2, 1 coupe ;
  640 x2, 0. Le repli à 96 px x échelle n'existe que dans `_HeuresCompactes`. Défaut antérieur
  (`_HeuresLarges` inchangé), bande étroite, mais BENTO-2-R l.158 exigeait « aucun mot coupé à
  600-1024 px, x1 et x2 ». Remède : appliquer le même repli à `_HeuresLarges` (ou une largeur
  minimale) ; ajouter les cas (600, 2) et (620, 2) à la boucle de `accueil_famille_test.dart:543-550`.
- **m2 : la bascule n'est pas « sous ~1024 px » ; à 1024 x1 la carte est côte à côte (440 px).**
  `accueil_famille_page.dart:55-61` et `:305-309` ; fiche « 768/1024 : pleine ». Grille = écran -
  80 (rail) - 48 (gouttières), donc bascule réelle à 864 px d'écran (grille de 736 px x échelle) ;
  1040 si la barre latérale est dépliée. Aucun mot coupé, mais la doc et le commentaire sont faux, et
  aucune capture ni assertion à 1024 ou 1280. Remède : corriger les deux commentaires et la fiche
  (« côte à côte dès que la grille fait 736 px x échelle ») ; assertion de placement à 1024 ;
  captures 1024 et 1280 facultatives.
- **m3 : la valeur limite de 360 px n'est couverte par aucun test.**
  `test/features/accueil_famille_test.dart:543-550` et `:570-591`. Le commentaire de la page dit
  « mesurée par les tests », mais la bande 864-1023 (moitié de 360 à 439) n'est jamais exercée, 1280
  non plus, et le facteur `max(1, échelle)` n'a aucune assertion de placement. Remède : cas (864, 1)
  ou (900, 1), (1200, 1) (moitié 432), (600, 2) ; assertions de placement à 863 et 864 et à 1440 x2
  (pleine).
- **m4 : le test famille « aucun mot coupé » peut réussir sans rien mesurer.**
  `test/features/accueil_famille_test.dart:565`. Aucune garde avant la mesure : avec un finder vide,
  `motsCoupes` renvoie une liste vide et le test passe. Rien ne prouve non plus qu'il aurait attrapé
  M1 (la contre-épreuve d1 le prouve toutefois à 768 x1 seulement). Remède :
  `expect(find.byType(GrilleBento), findsOneWidget)` et un `expect` sur « 45 » ou la Durée avant la
  mesure.
- **m5 : le test « À terminer » dépend du `Wrap` ajouté et ne mesure que l'en-tête.**
  `test/features/journee_test.dart:1114-1117` (fusion de deux angles). Sur l'ancien code, les 8 cas
  échouent par « Bad state: No element » (structure), pas en nommant « À termi/ner » ; les lignes
  de cahier et « Voir tout » ne sont pas mesurées. Le test reste rouge si on remet la `Row`, mais le
  message est trompeur. Remède : mesurer depuis un ancêtre qui ne dépend pas du correctif (la `Row`
  ou la tuile), avec `expect(finder, findsOneWidget)`.
- **m6 : `BENTO_RECENSEMENT.md` se contredit sur la 2x2.** `docs/current/BENTO_RECENSEMENT.md:15-18`
  dit que la 2x2 ne garde une voisine qu'au Centre de commande et que Aujourd'hui et l'accueil
  famille restent en bandes ; or `etendueLarge` joue aussi à 4 colonnes, les captures 1440 montrent
  deux 2x2 côte à côte, et la l.27 du même fichier dit l'inverse (fusion de deux angles). Remède :
  restreindre la phrase au palier à 3 colonnes (texte agrandi), et décrire le côte à côte à 4
  colonnes (famille : si chaque moitié offre 360 px x échelle).
- **m7 : le point de rappel peut rester seul en tête de deuxième ligne.**
  `journee_page.dart:842-845, 849-877`. Titre, `PointRappel` et `StatusPill` sont trois enfants
  séparés du `Wrap` ; à 360 et 390 x2 avec 4 cahiers le point passe sous le titre (RTL idem), et le
  commentaire « le point colle à lui » n'est plus vrai. Aucun mot coupé. Remède : grouper le titre et
  le point dans un seul enfant (une `Row` en `mainAxisSize.min`, texte dans un `Flexible`).
- **m8 : seuil de 96 px non mesuré sur la colonne réelle, commentaire inexact.**
  `bloc_seance.dart:440-444, 463-466`. `moitie = (maxWidth - 2 lg) / 2` ne correspond ni à la colonne
  de gauche (`maxWidth/2`) ni à la largeur utile de la Durée (`maxWidth/2 - 2 lg - filet`) ; la doc
  de `_largeurMinColonne` cite une mesure par `accueil_famille_test.dart` qui n'existe pas (aucun test
  de bascule de part et d'autre du seuil). Remède : corriger le calcul ou le commentaire ; ajouter un
  test de bascule autour du seuil.
- **m9 : à 320 x1 la Durée passe sous l'heure, doc non mise à jour.**
  `bloc_seance.dart:223-227, 389-390, 443-444`. À 320 x1, bloc 254, colonne 222, moitié 95 < 96 :
  repli en colonne (dès 340 x1, retour aux deux colonnes). La capture `famille_320_clair.png` le
  montre ; les docs disent encore « deux colonnes » et « filet vertical ». Rendu propre, mais non
  annoncé. Un sceptique le jugeait cosmétique (égalité, donc mineur). Remède : documenter le repli ou
  ajuster le seuil si les deux colonnes doivent rester à 320 x1.
- **m10 : D12 de `DASH_STRATEGIE.md` n'est pas levé par ce lot** (sur `c2-dash1`, non fusionnée).
  `DASH_STRATEGIE.md:72` garde « `BENTO_RECENSEMENT.md:3-7` » périmé, le double espace avant « ; » et
  « la grande tuile 2x2 reste » sans restriction ; le renvoi n'est fait que dans un sens. Corrigé
  en partie par BENTO-3 (`0f329aba`, renvoi 3-20 et espace), pas la restriction de la 2x2. Peut
  rester hors lot : à consigner et reporter à la voie DASH ou BENTO-3.
- **m11 : sur la branche commune, le recensement renvoie à un `DASH_STRATEGIE.md` absent.**
  `BENTO_RECENSEMENT.md:5, 27, 28, 34`. Le fichier n'existe pas sur
  `origin/corrections/revue-directeur-2026-10` (`c2-dash1` non fusionnée). Un sceptique juge que le
  renvoi est voulu par la fiche (égalité, donc mineur). Se résout à la fusion de `c2-dash1` ou
  `c2-bento3` ; à défaut, citer la branche source dans le renvoi. Peut rester hors lot.

### Cosmétiques

- **c1 : la pastille saute du bout de la ligne à son début quand elle passe à la ligne.**
  `bloc_seance.dart:251-270` (`WrapAlignment.spaceBetween` : un enfant seul se place au début).
  Position qui change selon l'échelle, rien de coupé. Remède facultatif : documenter ou aligner au
  bout (`AlignmentDirectional.centerEnd`).
- **c2 : vues de capture trop courtes à 768 x2.** `docs/current/captures/BENTO-2b/famille_768x2_*.png`,
  `journee_768x2_*.png` (`bento2b_capture_test.dart.txt:203`, hauteur 1500 au lieu de 2600) : le bas
  est rogné (« Dernière séance », second cahier). Les zones corrigées sont visibles ; limite reprise
  de BENTO-2. Remède : hauteur 2600 pour toutes les largeurs.
- **c3 : un nombre séparé de son unité** (« Cours dans 3 h / 00 » à 320 x2 et 390 x2 ; « 45 / min » à
  768 x2). `bloc_seance.dart` (libellés de durée et de compte à rebours, `_HeuresLarges`). Retour à
  la ligne sur espace, antérieur au lot mais rendu visible par lui. Remède : espaces insécables
  (U+00A0 ou U+202F).
- **c4 : titre et en-tête du recensement pas à jour.** `BENTO_RECENSEMENT.md:1, 22` : « BENTO-1 »
  daté du 02/10 et « Fait dans ce lot » alors que le tableau mêle BENTO-1, 2 et 2b. Remède : « Fait
  (BENTO-1 à BENTO-2b) » et la date.
- **c5 : renvoi incomplet.** `BENTO_RECENSEMENT.md:34` : la colonne linéaire du Mode Accessibilité
  relève de §3.3, pas de §3.2. Remède : « §3.2 et §3.3 ».

## Constats écartés (les 2 sceptiques ont réfuté)

- Seuil de 360 px posé dans l'écran, hors `AppGabarit` : seuil de contenu (largeur du conteneur), pas
  de largeur d'écran ; précédents dans le dépôt.
- Helper `aucun_mot_coupe.dart` « plus le même blob que c1-coupe » : la fiche cite le blob exact
  734bfb50, vrai à la livraison ; c1-coupe a avancé après, déjà résolu sur la branche commune.
- Limites du détecteur (rognage sans `maxLines`, faux positif sur glyphe de repli) : composant
  partagé de COUPE-MOTS-1, hors lot, déjà traité par BENTO-3.
- Renvoi D12 vers un fichier absent de ce worktree : voulu par la fiche, DASH vit sur une branche
  parallèle ; reste couvert par m10 et m11.
- « Classe An- / Nour » à 390 x2 : identique dans les captures BENTO-2, liste « Ma journée »
  inchangée, coupe légitime au trait d'union.
- Icônes de tête de carte centrées et vide à droite à 1440 : rangées et composants non touchés par le
  lot (`liste_preparation.dart`, `ligne_derniere_seance.dart`).
- Renvois `DASH_STRATEGIE.md:221 et 249` périmés : déjà faux sur `c2-dash1` avant le lot, corrigés par
  BENTO-3.
- §3.4 de `DASH_STRATEGIE.md` (2x2 à quatre colonnes) pas à jour : fichier d'une autre branche, à
  réaligner par la voie DASH ou à l'intégration.

## Pour accepter

1. Lever M1 : « À terminer » ne coupe aucun mot à 320 x2 et 390 x2, avec 2 et 4 cahiers, en LTR et
   RTL ; test qui mesure toute la `Row` ; commentaire l.844-845 corrigé.
2. Dans la même correction, lever les mineurs du lot :
   - m1 : famille 600-630 x2, « Durée » et « min » (`_HeuresLarges`), avec les cas de test (600, 2)
     et (620, 2) ;
   - m2 : doc et commentaire « 1024 : pleine » faux (à 1024 x1 la carte est côte à côte, 440 px ;
     bascule réelle à 864 px d'écran, grille de 736 px x échelle) ;
   - m3 : test de la limite de 360 px (bande 864-1023, 1280, 1440 x2) ;
   - m4 : test famille qui peut réussir sans rien mesurer (garde de présence) ;
   - m6 : contradictions de `BENTO_RECENSEMENT.md` (l.15-18 contre l.27).
3. Recommandé dans la même correction, car dans les mêmes fichiers : m5, m7, m8, m9.
4. Peut rester hors lot : D12 sur `c2-dash1` non fusionnée (m10, m11, avec les renvois de §3.4 et de
   `DASH_STRATEGIE.md:221 et 249`, déjà traités par BENTO-3) ; les défauts des composants partagés de
   COUPE-MOTS-1 (détecteur, barre de navigation « Historiq/ue », « Reway… », « Aujourd'hu/i »,
   sélecteur de profils). Cosmétiques c1 à c5 à la discrétion du directeur.

## Pour le directeur

Le correctif de l'accueil famille sur tablette est bon : la carte de la séance ne coupe plus ses
mots, et la contre-épreuve le prouve. Mais le bloc « À terminer » de la page Aujourd'hui coupe
encore des mots sur un petit téléphone avec le texte agrandi quand un enseignant a quatre cahiers en
retard ou plus, et le test du lot ne vérifie pas ce cas. La correction est courte ; je recommande de
la faire avant la fusion et de ne pas bloquer le reste.
