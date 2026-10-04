# Revue croisée COUPE-MOTS-1 / PASTILLE-COUPE-1 / CORR-SUITE-2 (lecture seule)

Date : 2026-10-04. Branche `corrections/revue-directeur-2026-10` @ `af20f6c2`, worktree détaché.
Aucun commit, aucun push, aucune écriture au tableau de suivi.

## Verdict

**ACCEPTÉE AVEC RÉSERVES.** Aucun défaut bloquant, 2 majeurs, 7 mineurs.

Le lot corrige au bon endroit. Le gros du travail passe par un composant partagé,
`TexteSansCoupure`, branché dans PageShell, EntetePage, AppBottomSheet, NavShell
(barre basse, rail, barre latérale), ControleSegmente, AvatarNom, StatusPill, GroupeReglages,
LienFleche et LigneCleValeur, ainsi que dans le titre de salle. Aucun jeton n'est en dur,
aucune ellipse ne reste sur les titres, la sémantique est conservée (`header`,
`MergeSemantics`, libellé lu du `PointRappel`), la mise en page RTL est testée et la
contre-épreuve est probante. Les réserves portent sur deux points. Le plancher de réduction
annule, dans le rail enseignant, l'agrandissement du texte choisi par l'utilisateur. La mesure
« aucun mot coupé sur l'écran entier, un écran par rôle » ne tourne qu'avec `CAPTURE_DIR`,
donc jamais en CI.

## Périmètre et commandes (résultats chiffrés)

- Base du lot : `d57ed2b1` (parent de `284cd2b7`). Commits du lot : `284cd2b7`, `8c9a4a40`,
  `088d5e7c`, `a0c88379`, `d8728048`, `8097103a`. La fusion `af20f6c2` reprend BENTO-2b et BENTO-1c (`fa64a6ad`),
  hors périmètre de cette revue.
- Diff relu : `git diff d57ed2b1 8097103a`, sans les captures. 28 fichiers, +2775 / -346 :
  19 fichiers lib et 9 fichiers de test.
- `dart analyze --fatal-infos` : **No issues found**.
- `dart run tool/verifier_jetons.dart` : **39 violations à la base, 39 en tête**. Aucune
  nouvelle violation (comparaison ligne à ligne vide). Le code retour vaut 1 à la base comme
  en tête : c'est l'existant.
- `dart run tool/verifier_revue.dart` : **1629 à la base, 1627 en tête** (`libelle-sans-source`
  1568 puis 1566 ; autres familles inchangées). C'est le même total que le côté BENTO
  `fa64a6ad` (1627). Aucune régression.
- Tests ciblés, toujours avec `--concurrency=2` :
  - lot et voisins : coupe_mots1, coupe_mots1_part2, mes_classes, nav_shell_accessibilite,
    nav_shell_adaptatif, recette_ct12, accueil_famille, journee, page_shell, page_shell_etat,
    photo_publique, groupe_reglages_valeur, libelles_sans_coupure, selecteur_theme,
    avatar_nom, avatar_ligne_rubrique, rtl_echelle_texte_ecrans, hierarchie_titres,
    garde_interface. Résultat : **665 réussis, 4 sautés**. Un seul échec, au chargement,
    venait d'un chemin erroné que j'avais saisi (`test/widgets/reglages_enfant_test.dart`).
    Relancé au bon chemin `test/features/…`, il passe.
  - réglages, cartes collées et captures sans `CAPTURE_DIR` : **49 réussis, 74 sautés**.
  - compte, compte_tuteur, profil_enseignant(+dossier), r1_responsive, admin_shell,
    `test/features/salle_seance/` : **553 réussis, 391 sautés**.
  - salle_200, salle_enseignant, salle : **76 réussis, 3 sautés**.
  - captures du lot **avec** `CAPTURE_DIR` (vers le scratchpad) : **74/74 réussis**. Cela
    comprend la mesure de l'écran entier pour enseignant, contrôleur, tuteur et admin, à
    320 ×1/×2, en clair et en sombre, ainsi que le rail 768, la barre latérale 1440 et la salle.
    Les 70 PNG régénérés ont les mêmes dimensions que les captures versionnées. Les écarts se
    limitent à l'anticrénelage (Linux contre poste Windows), sans différence de mise en page.
- Contre-épreuve. Dans chaque cas, seuls les fichiers lib concernés ont été remis à la base,
  puis restaurés (`git status` propre ensuite) :
  1. `status_pill.dart` à `d57ed2b1` : **4 échecs** dans mes_classes_test (ENS-09 320/390 ×2,
     LTR et RTL).
  2. `page_shell.dart` et `entete_page.dart` à la base : **3 échecs** dans coupe_mots1_test
     (« Aujourd'hui », « Centre de commande », « Cahier de transmission » à 320 ×2).
  3. `photo_publique.dart` à la base : **2 échecs** dans coupe_mots1_part2_test (LTR et RTL
     320 ×2, « obligatoire » entier, point au bord de début).
  4. CORR-SUITE-2 : `mes_classes_page.dart` et `groupe_reglages.dart` à `284cd2b7`, c'est-à-dire
     avec la borne fixe de 200. Résultat : **6 échecs**, dont 1280 ×1 en LTR et en RTL.

## Défauts

### Bloquant

Aucun.

### Majeurs

**M1. Rail enseignant : à ×2, les libellés sont plus petits qu'à 100 %.**
`lib/core/widgets/nav_shell.dart:1320` (`plancher: echelleMinimaleLisible`) et `:1285`
(le rail ne s'élargit que sous 0,85). `lib/core/accessibilite/texte_sans_coupure.dart:133`, `:191`.
Preuve : journal de la capture, `RAIL « Disponibilités » echelle 0.877`, identique à ×1 et à ×2.
Tous les libellés du rail enseignant sortent donc à 12 × 0,877 ≈ **10,5 px**, alors que
l'utilisateur a demandé 200 %. La capture `enseignant_rail_768_x2_light.png` le montre :
« Disponibilités » occupe 70 px sur 80 à côté d'un corps de page à ×2. Le test verrouille ce
comportement : `test/capture/coupe_mots1_capture_test.dart:156` exige `largeur du rail == 80`.
Le plancher de 0,85 est donc tenu, mais il est relatif au thème. Sur un style de 12 px, il donne
un texte minuscule et neutralise l'agrandissement (WCAG 1.4.4). Le cas visé, « pas de FittedBox
qui rend le texte minuscule », est atteint de fait.
Attendu : quand l'utilisateur agrandit le texte (facteur > 1), le rail s'élargit pour tenir le
mot le plus long au moins à l'échelle 1 (ou plancher absolu ≥ 12 px). Il faut retirer
l'assertion `== 80` à ×2. Le contrôleur, lui, est à 1,151 à ×2 : c'est correct.

**M2. La mesure « aucun mot coupé sur l'écran entier, un écran par rôle » ne tourne pas en CI.**
`test/capture/coupe_mots1_capture_test.dart:183` et
`test/capture/coupe_mots1_part2_capture_test.dart:122` (`skip: sautSansCapture`).
Les écrans par rôle (enseignant, contrôleur, tuteur, admin, salle, réglages, photo, détail
contrôleur) ne sont mesurés que dans les groupes de capture, sautés sans `CAPTURE_DIR`.
Les tests non sautés (`coupe_mots1_test`, `coupe_mots1_part2_test`) vérifient des composants
isolés. Seul Mes Classes (rôle enseignant) est vérifié sur un écran réel. Une régression sur un
écran de rôle passerait donc la CI.
Attendu : sortir `_mesurer` des groupes de capture et l'exécuter dans un test non sauté, au
moins un écran par rôle à 320 ×2 (vraies polices si possible, sinon Ahem avec mesure par mot).

### Mineurs

- **m1. Barre basse qui défile.** `nav_shell.dart:779-780`. Quand les libellés ne tiennent pas au
  plancher, la barre devient un `SingleChildScrollView` horizontal, et une destination peut
  sortir de l'écran. Le test `coupe_mots1_test.dart:283` fige ce comportement. Cela contredit
  l'esprit d'ONGLETS-1 (« jamais de rangée qui défile ») ; le cas ne se produit pas en français
  à 320. Préférer le passage à deux lignes entre les mots, ou une icône seule au-delà.
- **m2. Contrôles segmentés non agrandis.** `ControleSegmente` (Réglages 320 ×2) : « Clair /
  Système / Sombre » sont rendus à **1,025** (16,4 px) quand l'écran est à ×2. C'est mesuré par
  une instrumentation temporaire du test de capture, retirée ensuite. Ce n'est pas une
  régression, puisque la base les bornait déjà à 1. L'agrandissement est toutefois perdu
  (même cas pour « Séances / Observations », tuteur 320 ×2). À arbitrer avec THEME-SW-1 :
  segments empilés au-delà de 130 %.
- **m3. Commentaire faux.** `lib/core/widgets/status_pill.dart:115` indique « jamais sous 1 »,
  alors que le plancher réel est 0,85 (`echelleMinimaleLisible`).
- **m4. Doc mal placée.** `lib/features/salle_seance/salle_seance.dart:1388-1397`. La classe
  `TeteSalleBornee` a été insérée sous la documentation de `BandeauSecours` : la doc de
  `BandeauSecours` (T-S3, contrat D) est maintenant attachée à `TeteSalleBornee`, et
  `BandeauSecours` n'a plus de doc.
- **m5. Valeurs de secours en dur.** `lib/features/salle_seance/chrome_seance.dart:366-367`
  contient `?? 22` et `?? 14`. Ce ne sont pas des jetons d'espacement, mais une copie de
  l'échelle typographique ; lire `AppTypography` plutôt.
- **m6. RTL de Mes Classes : « élèves 3 ».** C'est le reste déclaré. Il est produit par
  `mes_classes_page.dart:235` rendu en RTL avec des chaînes françaises : l'algorithme bidi met
  le chiffre à droite (`mes_classes_320_x2_rtl.png`). Ce n'est pas un défaut de mise en page.
  Le test RTL devrait employer la locale `ar`, ou isoler les fragments latins, pour être
  significatif.
- **m7. Limites de la mesure et de la galerie.**
  - `motsCoupes` (`test/support/aucun_mot_coupe.dart`) ne voit ni le rognage par un parent ni
    la sortie de viewport. Exemple : `tuteur_historique_320_x2_dark.png`, où la seconde vignette
    « Eleve A2 / Aucune s… » est coupée au bord. C'est un défilement horizontal préexistant,
    hors lot, mais la mesure ne l'aurait pas signalé.
  - Pour CORR-SUITE-2, la « galerie Bento fidèle » n'est pas démontrée : `lib/features/_dev/galerie`
    n'a pas été modifiée. La fidélité vient seulement du composant partagé, et aucune entrée ne
    montre une marque longue ni la pastille « Remplacement ».

## Captures vues

J'ai ouvert 13 captures versionnées (`docs/current/captures/COUPE-MOTS-1`) :

| Capture | Constat |
| :--- | :--- |
| `enseignant_classes_320_x2_light` | Aucun mot coupé. La barre basse « Aujourd'hui / Classes / Disponibilités / Profil » est entière, mais plus petite que le corps. |
| `salle_titre_320_x2_dark` | « Séance / en / direct » sur 3 lignes, sans ellipse. Le sous-titre est plus petit. Le panneau « Élèves 1/3 » paraît aussi gros que le titre (hiérarchie limite, sans inversion mesurée). |
| `enseignant_rail_768_x2_light` | **Libellés du rail minuscules (M1).** |
| `controleur_rail_768_x2_dark` | Libellés entiers, de taille correcte. Plus de « Contr… Histori… ». |
| `tuteur_barre_laterale_1440_x2_light` | « Rewayah » entier. Segments corrects. |
| `admin_barre_laterale_1440_x2_dark` | « Administrateur » entier, collé au bord droit de la barre. |
| `mes_classes_320_x2_rtl` | « Remplacement » entier. « Cahier de transmission à valider » coupé entre les mots. Légende « élèves 3 » (m6). |
| `controleur_detail_390_x2_dark` | « Échanges avec / l'administration » et « Écrire à / l'administration » entiers. Barre basse correcte. |
| `reglages_320_x2_dark` | « Accessibilité » et « Apparence » entiers. Segments petits (m2). |
| `photo_publique_320_x2_light` | Portrait au-dessus, point en tête de paragraphe, « obligatoire » entier. |
| `carte_remplacement_320_x2_dark` | « Al-Fatiha » entier, pastille dessous, aucun débordement. |
| `admin_dossiers_320_x2_light` | Titre sur 2 lignes. Sélecteur en menu. Rien de coupé. |
| `tuteur_historique_320_x2_dark` | Vignette de droite rognée au bord, hors lot (m7). Segments petits. |

## Pour accepter sans réserve

1. Corriger M1 : rail élargi à facteur > 1, ou plancher absolu, et retrait de l'assertion
   `largeur == 80` à ×2. Recapturer `enseignant_rail_768_x2`.
2. Corriger M2 : la mesure de l'écran entier pour un écran par rôle à 320 ×2 doit tourner dans
   un test non sauté en CI.
3. Mineurs à reporter :
   - doc de `BandeauSecours` ;
   - commentaire de `StatusPill` ;
   - valeurs de secours `22` et `14` ;
   - test RTL en locale `ar` ;
   - entrée de galerie « marque longue et pastille Remplacement » ;
   - décision sur la barre basse qui défile et sur les segments à ×2.
