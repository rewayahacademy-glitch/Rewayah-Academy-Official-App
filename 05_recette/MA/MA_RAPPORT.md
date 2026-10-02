# MA-12 : recette de la vague Mode Accessibilité

Dépôt : `C:\RA\accessibilite`, branche `ui/accessibilite-v1`, pointe de départ 093b67b, tests ajoutés au commit 4743d0e (poussé). Recette faite en démonstration, sans serveur, sur la route `/demo/accessibilite` (K-28, K-35). Les captures sont dans `build/captures` du dépôt (dossiers `ma1b` à `ma12`).

## En un coup d'oeil

- Réussi : 45
- Attend BR-1 : 3 (cas supplémentaires, tableau 2)
- Attend le directeur : 6 (essais à la main ou lecteur d'écran réel)
- Échoue : 3 (Mon espace et Salle, voir « Défauts »)

Sur les 54 cases du tableau 1 (9 écrans, 6 critères) : 45 Réussi, 6 Attend le directeur, 3 Échoue. Les cas du tableau 2 sont comptés à part (3 Attend BR-1).

## Tableau 1 : écran par critère

Preuves : « M12 » = `test/accessibilite/ma12_recette_test.dart` (nouveau, matrice des sept écrans MA pour Mariam et Idriss) ; « M11 » = `test/accessibilite/ma11_technique_test.dart` ; « cap » = `test/features/accessibilite_recette/captures_ma_test.dart` ; « K » = `test/accessibilite/tuteur_k_echelle_texte_test.dart` ; « mode » = `test/core/accessibilite/mode_accessibilite_test.dart`.

Critères : A = 390, 768, 1440 px en clair et en sombre ; B = texte à 200 % ; C = lecteur d'écran (arbre Semantics, chaque action a un nom) ; D = animations réduites ; E = écriture de droite à gauche (structure) ; F = clavier (Tab, Maj+Tab, cibles d'au moins 48).

| Écran | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| Accueil | Réussi (M12, cap ma3) | Réussi (M12, cap ma3 texte200) | Réussi (M12) | Réussi (mode, M11) | Réussi (M12) | Réussi (M11) |
| Ma classe | Réussi (M12, cap ma4) | Réussi (M12, cap ma4) | Réussi (M12) | Réussi | Réussi (M12, cap ma12) | Réussi (M11) |
| Coran | Réussi (M12, cap ma7) | Réussi (M12, cap ma7) | Réussi (M12) | Réussi | Réussi (M12) | Réussi (M11, Entrée ouvre le lecteur) |
| Mon espace | Réussi (M12, cap ma8) | **Échoue** (défaut 1) | **Échoue** (défaut 2) | Réussi | Réussi (M12) | Réussi (M11) |
| Après la séance | Réussi (M12, cap ma6) | Réussi (M12, cap ma6) | Réussi (M12) | Réussi | Réussi (M12) | Réussi (M11) |
| Préparation | Réussi (M12, cap ma5) | Réussi (M12, cap ma5 texte200) | Réussi (M12) | Réussi | Réussi (M12) | Réussi (M11) |
| Salle | Réussi (M12, cap ma5) | **Échoue** (défaut 3) | Réussi (M12) | Réussi | Réussi (M12, cap ma12) | Réussi (M11) |
| Interface du tuteur (vraie coquille tuteur) | Réussi à 390 et 1440 (cap ma9 ; pas de capture 768) | Réussi (K) | Attend le directeur (TalkBack) | Réussi | Attend le directeur | Réussi (M12 nouveau : Tab, Maj+Tab, cibles d'au moins 48, Entrée sur « Présentation standard » l'écrit) |
| Fiche de séance enseignant | Réussi à 390 et 1440 (cap ma9) | Attend le directeur | Attend le directeur | Réussi | Attend le directeur | Attend le directeur |

Notes : pour les cases A, B et E prouvées par M12, le test monte l'écran réel et exige zéro exception de mise en page (donc aucun débordement). Mariam (mineure, tutoiement) et Idriss (adulte, vouvoiement) sont testés à chaque fois. Les animations réduites sont prouvées par le mécanisme commun (`Mouvement.duree` vaut zéro avec `disableAnimations` ou la préférence locale), testé dans `mode_accessibilite_test` et `ma11_technique_test`.

## Tableau 2 : cas qui dépendent du serveur ou de vous

| Cas | Résultat | Pourquoi |
|---|---|---|
| Demande de présentation standard par la mineure (Mariam) : états « en cours », « envoyée », « envoi non confirmé » | Attend BR-1 | Seul le faux port existe (MA-BR-1). Les messages honnêtes sont testés (`mon_espace_ma8_test`). |
| Bascule de l'adulte (Idriss) entre Mode Accessibilité et standard | Attend BR-1 | Agit seulement en démonstration (MA-BR-2). |
| Salle : reconnexion et réseau coupé réels | Attend BR-1 | Dépend du vrai direct (LiveKit), absent de la démo (MA-BR-3, ajouté). |
| TalkBack sur le téléphone Android | Attend le directeur | Non fait : le débogage USB n'est pas confirmé actif. Consigné. Les tests ne prouvent que les noms et les rôles. |

## Défauts trouvés (non corrigés, pour la revue MA-R)

1. **Mon espace, texte à 200 %, écran de 390 x 844 : la zone du contenu disparaît.** `lib/core/widgets/page_shell.dart:186` : la tête de page (titre, phrase d'intro) et la barre du bas laissent trop peu de place, la tête ne défile pas et déborde de 147 px. La recette ne le voit que sur un écran de hauteur réelle ; les captures 200 % de la vague sont prises sur une planche très haute et le cachent. Le test M12 correspondant est sauté avec ce message ; à rétablir quand c'est corrigé.
2. **Mon espace, lecteur d'écran : les interrupteurs et les ronds de choix n'ont pas de nom.** `lib/core/widgets/setting_row.dart:110` (`controle!`) : le contrôle natif (Switch, Radio) est un noeud tactile à part, sans libellé ; le nom n'est que sur la ligne autour. Résultat probable avec TalkBack : une case « cochée » sans dire laquelle, et deux arrêts par ligne. Neuf noeuds sur Mon espace. Le widget est partagé (Compte standard aussi, donc HU-1).
3. **Salle, texte à 200 % : les commandes perdent leur mot.** `lib/features/salle_seance/dock_seance.dart:439-443` : dès que le texte dépasse 100 %, la barre passe en icônes seules (décision EN-12, libellé « lu » seulement). La règle MA20 demande des commandes avec texte. Capture : `ma5/ma5_salle_mariam_390_light_texte200.png`. À arbitrer par la revue : texte sur deux lignes, ou règle EN-12 assouplie pour le Mode Accessibilité.
4. **Mots coupés dans Mon espace à 200 %** (capture `ma8/ma8_mon_espace_mariam_390_light_texte200.png`) : « Mari / am » (`lib/features/accueil_eleve/mon_espace_accessibilite.dart:128`), « Accessibilit / é » et « Notification / s » (titres de section, `lib/core/widgets/groupe_reglages.dart:103`), « mouvemen / ts » et « autom / atiquement » (descriptions de `lib/core/widgets/setting_row.dart`). Le test M12 ne le voit pas (aucune exception) ; seul le regard sur la capture le trouve.
5. **Texte français forcé en RTL** : l'ordre est mêlé sur Ma classe (« Paris 18:00 » au lieu de « 18:00 Paris », « min 45 », point de fin de phrase placé au début : « .charge »). Même constat qu'à CT-12 : probablement sans objet en arabe réel, à revérifier à LG-1 en isolant les nombres et horaires.
6. Détail de démonstration : le bandeau « Démonstration » en haut à gauche est rogné en RTL (`ma12/ma12_rtl_accueil_mariam_390_light.png`). Sans effet en production.

## Ce que j'ai vu sur les captures ouvertes (6)

- Ma classe, RTL, 390 px (`ma12/ma12_rtl_accueil_mariam_390_light.png`, qui montre Ma classe car la destination par défaut de la démo est Ma classe, pas Accueil) : titre, carte et étiquettes à droite, valeurs à gauche, barre du bas inversée (Mon espace à gauche, Accueil à droite). Aucun bouton plein, carte détachée des bords (pas de carte collée, K-55). Ponctuation et chiffres mêlés (défaut 5). Le grand rond « I » (photo de l'enseignant en démonstration) est grand mais pas coupé.
- Salle, RTL, 390 px (`ma12/ma12_rtl_salle_mariam_390_light.png`) : barre de commandes avec texte (Quitter, Agrandir, Caméra, Parler), inversée comme attendu ; « Ton parent observe la séance » lisible ; un seul bouton plein destructif (Quitter) ; points de fin de phrase passés au début des lignes (défaut 5). Rien ne déborde.
- Accueil, 200 %, 390 px (`ma3/ma3_accueil_mariam_avant_390_light_texte200.png`) : tout passe sur plusieurs lignes, aucun mot coupé, une seule action pleine (« Voir ma classe », texte centré, flèche à droite), cartes séparées, barre du bas avec « Mon espace » sur deux lignes. Beaucoup de vide en bas, normal.
- Salle, 200 %, 390 px (`ma5/ma5_salle_mariam_390_light_texte200.png`) : titre « Ma séance » sur deux lignes, support tronqué par la barre (il se défile), commandes en icônes seules (défaut 3).
- Salle d'Idriss, sombre, 390 px (`ma5/ma5_salle_idriss_390_dark.png`) : fond sombre propre, le support reste une carte claire (voulu pour la lecture), commandes avec texte lisible, un seul bouton plein destructif, rien de coupé ni de débordant.
- Mon espace, 200 %, 390 px (`ma8/ma8_mon_espace_mariam_390_light_texte200.png`) : page très longue, mots coupés (défaut 4), aucun bouton plein.

Aucun bouton au contenu non centré (K-54) ni deuxième bouton plein (K-56) vu sur ces six captures.

## Questions du directeur (Q1 à Q11)

Le découpage ne liste que Q1 à Q11 (pas de Q12 ni Q13 dans `02_DECOUPAGE.md`). Les choix provisoires ont été appliqués partout ; je n'ai pas vu les réponses définitives du directeur dans les fichiers lus. L'orchestrateur doit confirmer.

## Ce qui reste

1. Essai TalkBack sur le téléphone du directeur (débogage USB à activer), surtout Mon espace après correction du défaut 2.
2. Essai clavier à la main sur ordinateur : fiche de séance enseignant et page Interface au navigateur.
3. Capture 768 px de la page Interface du tuteur (absente) ; RTL et 200 % de cette page et de la fiche de séance.
4. Corrections des défauts 1 à 4 à MA-RC, puis rétablir les deux tests sautés de `ma12_recette_test.dart`.
5. BR-1 : MA-BR-1 à MA-BR-3 (voir `15_accessibilite/MA-BR.md`).
6. TH-2 : aucune ligne nouvelle relevée (contrastes non mesurés dans cette recette).

## Les chiffres

- `dart analyze --fatal-infos lib test tool` : aucun problème (0).
- Suite complète sur la pointe 093b67b (`flutter test`, sans CAPTURE_DIR) : 3461 réussis, 0 échec, 1476 sautés (captures et tests réservés). Journal : `build/suite_ma12.log`. Elle précède l'ajout du seul fichier de tests MA-12.
- `ma12_recette_test.dart` : 139 réussis, 4 sautés (défauts 1 et 2, pour Mariam et Idriss), 0 échec.
- Captures : 96 images produites avec CAPTURE_DIR, dont 3 nouvelles (RTL, dossier `ma12`) ; 6 ouvertes et décrites ci-dessus.
