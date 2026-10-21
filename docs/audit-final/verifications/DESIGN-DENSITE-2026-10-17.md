# Critique mesurée de densité et de hiérarchie - 17/10/2026

Préparation du lot L4-07 (`docs/audit-final/lots/L4-07.md`). Réponse au point 2 de `docs/audit-final/ERRATUM-2026-10-16.md` et au point 3 de la section 7 du prompt de l'orchestrateur.

## 1. Ce qui a été mesuré, et comment

- **Données de démonstration, pas un compte réel.** Routes `/?demo=tuteur` et `/?demo=admin`, `localStorage presentation.vue=oui` posé avant la navigation. Le bandeau « Démonstration » (24 px en haut) n'existe pas avec un vrai compte : il est retiré de toutes les hauteurs ci-dessous.
- **Pas la préversion Vercel.** `https://rewayah-academy-jsmnhsct2-rewayahacademy-3863s-projects.vercel.app` est refusée par le proxy de sortie de la session (`curl` : `CONNECT tunnel failed, response 403`, `connect_rejected`). Mesure faite sur une construction web locale (`flutter build web`, mode release par défaut, sans `--dart-define`) d'une copie de la branche `lots/L4-07-critique-densite` au commit `a2f9dafb` : `diff -rq` entre la copie et le worktree ne montre que les trois fichiers `strings*.g.dart` régénérés par `slang`. Rien ne garantit que la préversion porte le même commit : à recouper sur la préversion quand le réseau le permet.
- **Navigateur.** Chromium 1194 préinstallé (`/opt/pw-browsers/chromium-1194`), Playwright, `deviceScaleFactor` 1, locale `fr-FR`, sans extension. Fenêtres 390 x 844, 1366 x 650 (portable 1366 x 768 moins la barre du navigateur), 1440 x 900. Clair et sombre pour Foyer et Accueil tuteur, clair pour les trois autres.
- **Méthode des chiffres.** Positions et largeurs : arbre `flt-semantics` (activé par un clic sur `flt-semantics-placeholder`, `getBoundingClientRect`, pixels CSS), noté « S ». Quand l'élément n'a pas de nœud propre (bord d'une carte, champ visuel), lecture sur l'image, notée « I ». Taille du corps : style du thème lu dans le code du composant (`lib/core/theme/app_typography.dart:285-296`), noté « C ».
- **« Premier contenu utile »** : la première donnée propre à l'utilisateur (carte de profil, carte de demandes, première ligne de liste ou de tableau). Pour Recherche, le champ lui-même.
- Scripts et sorties brutes : `scratchpad/densite/` (`lib.js`, `mesurer.js`, `defiler.js`, `out/*.json`). Captures : `docs/audit-final/captures/densite/` (23 fichiers).

Repères (rien au-delà) : Apple HIG (un seul geste principal par écran, corps 17 sur mobile, barre de navigation 44) ; Material 3 (barre d'application 64, corps 14 et 16, listes denses sur bureau) ; WCAG 2.2 AA (contraste 4,5, cibles 24 au moins, focus visible).

## 2. Foyer (tuteur, `/tuteur/foyer`)

| Mesure | 390 x 844 | 1366 x 650 | 1440 x 900 | Méthode |
|---|---|---|---|---|
| Hauteur avant le premier contenu utile (première carte de profil), px | 218 | 150 | 150 | S |
| Part de la fenêtre utile (sans le bandeau de démonstration), % | 27 | 24 | 17 | S |
| Lignes de filtres | 0 | 0 | 0 | S |
| Largeur de la barre de recherche, px | aucune (icône) | aucune (icône) | aucune (icône) | S |
| Largeur d'une carte de profil, px | 358 | 338 | 363 | S |
| Largeur de la ligne « Appareils du foyer », px | 358 | 418 | 448 | S |
| Largeur du bouton plein « Ajouter un profil élève », px | 358 | 236 | 236 | S |
| Largeur de son contenu (libellé et flèche), px | 188 | 188 | 188 | I |
| Boutons pleins sur l'écran | 1 | 1 | 1 | S, I |
| Corps des cartes (légende), px | 14 | 14 | 14 | C |
| Contraste surface « Appareils du foyer » contre le fond, clair / sombre | 1,07 / 1,10 | 1,07 / 1,10 | 1,07 / 1,10 | I (pixels 255,255,255 contre 248,247,250) |

Clair et sombre donnent les mêmes positions au pixel près (`foyer_*_dark.json` identiques en géométrie).

Lecture : en démonstration, le Foyer respecte la règle d'un bouton plein et borne ses cartes (grille de 338 à 363). L'écart du directeur (cartes de parcours d'environ 1040 px, trois boutons pleins) vient de l'Accueil avec un compte sans données, pas du Foyer de démonstration (voir 3). La ligne « Appareils du foyer » a un contraste de surface de 1,07 : le composant demande déjà un filet et une ombre (`lib/core/widgets/groupe_reglages.dart:145-148`, `AppElevation.avecFilet` avec `contourCarte` et `ombre`) ; ce qui la rend presque invisible tient aux jetons, pas au composant.

## 3. Accueil tuteur (`/tuteur`)

| Mesure | 390 x 844 | 1366 x 650 | 1440 x 900 | Méthode |
|---|---|---|---|---|
| Hauteur de l'en-tête fixe (titre et actions), px | 96 | 96 | 96 | S |
| Hauteur avant le premier contenu utile (carte « Vos demandes de créneau »), px | 213 | 229 | 229 | I |
| Hauteur avant la carte « Prochaine séance », px | 666 | sous le pli (plus de 626) | environ 621 | I |
| Lignes de filtres | 0 | 0 | 0 | S |
| Largeur de la barre de recherche, px | aucune (icône) | aucune (icône) | aucune (icône) | S |
| Largeur de la carte « Vos demandes de créneau », px | 358 | 1046 | 1120 | I |
| Largeur de sa plus longue ligne de contenu, px | 229 | 229 | 229 | I |
| Largeur de la cible du lien « Voir le suivi des demandes », px | 316 | 996 | 1070 | S |
| Largeur du bouton plein « Connecter un appareil », px | 148 | 212 | 212 | S |
| Boutons pleins sur l'écran (démonstration) | 1 | 1 | 1 | S, I |
| Corps dans la carte de demandes, px | 14 | 14 | 14 | C |

L'en-tête ne défile pas : sur les captures `accueil-defile_*`, après défilement, le titre « Accueil » et ses actions restent figés et coupent le contenu (96 px, 15 % d'une fenêtre de 626). À 1366 x 650, la carte « Prochaine séance », qui est la raison d'être de l'écran, n'apparaît pas sans défiler ; l'ordre des blocs (rangée d'élèves 112, demandes 259, alerte d'appareil 120) relève de l'écran `accueil_famille`, réservé à L4-05.

Avec le vrai compte du directeur (non reproductible en démonstration, où chaque élève a une classe ; le bloc ne s'affiche que pour un élève sans classe, `accueil_famille_page.dart:212-224`) : le bloc de parcours pose un `ActionPrincipale` sans `pleineLargeur: false` (`lib/features/parcours_offres/bloc_parcours.dart:187`, zone interdite), donc pleine largeur, et l'écran montre trois boutons pleins.

## 4. Classes de l'administration (`/admin/operations/groupes`)

| Mesure | 390 x 844 | 1366 x 650 | 1440 x 900 | Méthode |
|---|---|---|---|---|
| Hauteur avant le premier contenu utile (première ligne de classe), px | 694 | 506 | 506 | S |
| Part de la fenêtre utile, % | 85 | 81 | 58 | S |
| dont bandeau d'alerte urgente (voulu, ALERTE-1), px | 158 | 118 | 118 | S |
| Hauteur de liste visible au premier écran, px | 50 (sous la barre basse) | 120 (1,6 ligne) | 370 (5 lignes) | S |
| Lignes de filtres | 1 | 1 | 1 | S |
| Puces dans la rangée | 11 | 11 | 11 | S |
| Puces visibles sans défiler | 1 et une coupée | 6 | 6 et une coupée | S |
| Hauteur de la rangée (puces et barre de défilement), px | 60 | 60 | 60 | S |
| Largeur de la barre de recherche, px | 358 | 846 | 920 | I |
| Largeur du bouton plein « Nouvelle classe », px | 358 | 161 | 161 | S |
| Boutons pleins sur l'écran | 1 | 1 | 1 | I |
| Largeur d'une ligne de tableau, px | 358 (carte) | 1014 | 1088 | S |
| Corps dans la liste (cellule de tableau ; résumé de carte sur téléphone), px | 12 | 12 | 12 | C (`data_collection.dart:503`, `:671`) |
| Cibles d'icône dans la rangée de titre | 4 | 7 (dont deux cloches) | 8 (dont deux cloches) | S |

Composition des 506 px à 1366 x 650 : alerte 118, rangée de titre 24 + 48, sélecteur de section 24 + 48, phrase d'introduction 30, recherche 62, rangée de filtres 60, écart 24, en-tête de tableau 40. Le corps de tableau (12) est déjà sous le repère Material des listes denses (14) : la densité ne se gagne pas sur le texte de cet écran, elle se gagne sur l'empilement au-dessus de la liste.

## 5. Recherche (`/recherche`, tuteur)

| Mesure | 390 x 844 | 1366 x 650 | 1440 x 900 | Méthode |
|---|---|---|---|---|
| Hauteur avant le premier contenu utile (le champ), px | 112 | 116 | 116 | S |
| Lignes de filtres | 1 | 1 | 1 | S |
| Puces visibles / puces | 3 / 4 | 4 / 4 | 4 / 4 | S |
| Largeur de la barre de recherche, px | 358 | 1046 | 1120 | I |
| Hauteur du champ, px | 62 | 62 | 62 | S |
| Largeur utile du texte saisi contre largeur du champ, px | 286 / 358 | 974 / 1046 | 1048 / 1120 | S |
| Boutons pleins sur l'écran | 0 | 0 | 0 | I |
| Corps de l'état vide, px | 14 | 14 | 14 | C |

Le champ de 1046 à 1120 px est deux fois plus large qu'une requête courante et que la recherche de la coquille d'administration, déjà bornée à 640 (`lib/core/widgets/admin_shell.dart:1234-1237`, `AppPage.largeurFormulaire`).

## 6. Écran à filtres : Espace de traitement (`/admin/operations/traitement`)

| Mesure | 390 x 844 | 1366 x 650 | 1440 x 900 | Méthode |
|---|---|---|---|---|
| Hauteur avant le premier contenu utile (première ligne), px | 646 | 458 | 434 | S |
| Part de la fenêtre utile, % | 79 | 73 | 50 | S |
| Lignes de filtres | 1 | 1 | 1 | S |
| Puces visibles / puces | 3 / 4 | 4 / 4 | 4 / 4 | S |
| Largeur de la barre de recherche, px | aucune | aucune | aucune | S |
| Largeur d'une ligne de la file, px | 358 | 1014 | 336 (inspecteur) | S |
| Boutons pleins sur l'écran | 0 | 0 | 1 (« Ouvrir la demande pour Sami », 263) | S, I |
| Corps dans la liste (libellé / légende), px | 16 / 14 | 16 / 14 | 16 / 14 | C (`groupe_reglages.dart:390-403`) |

## 7. Écarts, repères et composants

| Écart mesuré | Repère | Composant (fichier:ligne) | Correction de composant possible |
|---|---|---|---|
| Rangée de filtres de 11 puces, 5 à 10 cachées, barre de défilement de 12 px sous la rangée (Classes) | un seul niveau de choix visible, rien de caché sans le dire | `lib/core/widgets/rangee_filtres.dart:44` (classe), `:261-263` (défilement horizontal, pas de « Plus ») | trois puces au plus, puis « Plus » qui ouvre le reste |
| Barre de recherche à 846, 1046, 1120 px | Material 3 : champ de recherche borné ; précédent du dépôt 640 | `lib/core/widgets/champ_recherche.dart:101-109` (`LayoutBuilder` puis `TextField` sans borne) ; écran `lib/features/admin_groupes/groupes_page.dart:349` (`Expanded(child: recherche)`) | borne à `AppPage.largeurFormulaire` (640) dans le composant |
| En-tête fixe de 96 px sur l'Accueil ; tête de 388 px (hors alerte) au-dessus du tableau des Classes à 1366 x 650 | HIG : le titre se replie au défilement ; Material 3 : barre de 64 | `lib/core/widgets/page_shell.dart:20` (`_hauteurTeteFixe = 360`), `:163-166` (la tête ne défile pas), `:327-336` (règle de bascule) ; `lib/core/widgets/entete_page.dart:281` (`hauteurSeuil = 600`, l'en-tête compact ne s'active pas à 650 ni à 760) ; `lib/core/widgets/data_collection.dart:150-159` (`minimumLisible` = 114 px, soit 1,6 ligne) | tête qui défile sous 800 px de haut ; en-tête compact sous 800 ; minimum lisible porté à quatre lignes |
| Carte de demandes de 1046 à 1120 px pour 229 px de contenu ; lien de 996 px de cible | cartes bornées, lecture 45 à 75 caractères | `lib/core/widgets/app_card.dart:128-136` (aucune largeur maximale) ; `lib/core/widgets/lien_fleche.dart:113-115` (contenu centré dans une cible étirée) | largeur maximale optionnelle de carte ; lien à la largeur de son contenu |
| Bouton plein pleine largeur par défaut (vrai compte : parcours) | HIG : un seul geste principal, à sa taille sur bureau | `lib/core/widgets/action_principale.dart:61` (`pleineLargeur = true` par défaut), `:227` (`double.infinity`) | pleine largeur sur téléphone seulement |
| Trois boutons pleins sur l'Accueil du vrai compte | HIG, K-42 : un seul | `bloc_parcours.dart:187` (zone interdite), `accueil_famille_page.dart:224` (L4-05) | corrigé en partie par le défaut ci-dessus (largeur), le nombre reste à l'écran |
| Deux cloches dans la rangée de titre de l'administration | une action, un endroit | `lib/core/widgets/admin_shell.dart:439-466` (`_RangeeActions`) et actions de coquille de `PageShell` | hors L4-07, signalé |
| Bandeau d'alerte de 118 à 158 px sur toutes les pages d'administration | voulu (ALERTE-1) | `lib/core/widgets/admin_shell.dart:370` (`_ZoneBandeau`) | aucune : décision |
| Surface « Appareils du foyer » à 1,07 de contraste avec le fond | WCAG 1.4.11 (3 pour un composant à repérer) | jetons `contourCarte`, `ombre`, `surfaceRaised` | jeton, hors L4-07 |
| Corps du tableau des Classes à 12 | Material 3 : 14 en liste dense | `lib/core/widgets/data_collection.dart:503` (`bodySmall`) | hors densité : plutôt trop petit que trop grand |

Contrôles WCAG relevés au passage : toutes les cibles mesurées font 48 px de haut ou plus (repère 24 atteint) ; le contraste du texte n'a pas été mesuré sur ces captures ; le focus visible n'a pas été parcouru au clavier dans cette critique.

Le bouton rond sombre qui flotte au bord droit des captures du directeur n'apparaît sur aucune des 23 captures (Chromium sans extension) : il vient très probablement d'une extension de son navigateur.

## 8. Ce que les jetons (question A-11) apporteraient

Réduire l'échelle (titres 28, 24, 22 ; titre de carte 17 ; `titreEcran` 32) ferait gagner au plus 8 px avant le premier contenu sur ces cinq écrans (Foyer 150 à environ 142 ; rien sur Classes, Accueil et Traitement, dont la rangée de titre est tenue par les cibles de 48 et non par la taille du titre), contre 96 à 388 px rendus au contenu par les corrections de composants de L4-07 (en-tête qui défile sur l'Accueil, tête entière des Classes).

## 9. Conclusion

Le diagnostic du directeur est confirmé et localisé : rien n'est zoomé, la place se perd dans quatre composants (`page_shell.dart`, `entete_page.dart`, `rangee_filtres.dart`, `champ_recherche.dart`) et dans deux défauts de largeur (`action_principale.dart`, `app_card.dart`). Les tailles de texte ne sont pas la cause principale de la densité sur ces écrans. La fiche L4-07 reprend ces six composants avec un critère chiffré tiré des tableaux ci-dessus.
