# Recensement des tableaux de bord en grille Bento (BENTO-1 à BENTO-2c, 04/10/2026)

Composant partagé : `lib/core/widgets/grille_bento.dart` (`GrilleBento`,
`TuileBento`, `EtendueBento`, `placerBento`) ; la règle des colonnes est la
décision D12 de `DASH_STRATEGIE.md`, qui renvoie ici. Deux colonnes sous 600 px de
largeur offerte, quatre au-delà ; écart 16 px (K-55) ; ligne de 160 px
(`GrilleBento.hauteurLigne`), multipliée par l'échelle du texte quand elle
dépasse 100 % (`GrilleBento.hauteurLignePour`). Depuis BENTO-1b, c'est la
largeur utile par colonne qui décide, pas l'échelle seule
(`GrilleBento.colonnesPour`) : tant qu'une colonne ferait moins de
112 px × échelle (`GrilleBento.largeurMinCellule`, seuil sans source, à faire
valider), la grille perd une colonne : 4, 3, 2, puis 1 colonne de hauteur
libre (BENTO-1c). Cette règle ne joue qu'au-dessus de 100 % : à 100 % ou
moins, rien ne change, même dans une place étroite. À trois colonnes et plus,
une tuile prend son étendue large (`TuileBento.etendueLarge`). À trois
colonnes (texte agrandi), la grande tuile 2×2 n'y garde une voisine qu'au
Centre de commande ; Aujourd'hui et l'accueil famille restent en bandes
pleine largeur, comme à deux colonnes (revue BENTO-1c-R, m-C). À quatre
colonnes, deux grandes tuiles 2×2 peuvent se partager la bande : sur
Aujourd'hui selon le placement de `placerBento` (captures 1440 de
BENTO-2b), sur l'accueil famille seulement si chaque moitié offre 360 px ×
échelle du texte (`largeurMinCarteClasse`, BENTO-2b ; revue BENTO-2b-R, m6). À 1440 px et
texte × 2, le Centre de commande garde plusieurs colonnes ; à 320 px et
texte × 2, une seule.

## Fait (BENTO-1 à BENTO-2c)

| Rôle | Écran | Fichier | Avant | Après |
|---|---|---|---|---|
| Direction | Centre de commande (ADM-01) | `lib/features/admin_tableau/tableau_de_bord_page.dart` | 6 `StatTile` identiques dans un `Wrap` (damier 2 x 3) | Grille Bento : Dossiers 2x1 (2x2 sur 4 colonnes) avec phrase d'action, Demandes 1x2 avec phrase, Élèves sans enseignant et Cahiers manquants 1x1, Incidents + Accès échus regroupés 2x1 (4x1) quand ils valent 0 |
| Tuteur | Accueil famille (TUT-01, BENTO-2, BENTO-2b) | `lib/features/accueil_famille/accueil_famille_page.dart` | Une colonne sur téléphone, deux colonnes égales sur bureau | Grille Bento en hauteur de contenu (DASH_STRATEGIE.md §3.4) : blocage large, carte classe et « Avant le prochain cours » en grandes tuiles côte à côte seulement si chaque moitié offre 360 px × échelle du texte (`largeurMinCarteClasse`), sinon pleine largeur ; dernière séance large |
| Enseignant | Aujourd'hui (ENS-02, BENTO-2) | `lib/features/journee/journee_page.dart` (`_Composition`) | Une ou deux colonnes égales | Grille Bento en hauteur de contenu (DASH_STRATEGIE.md §3.5) : Prochaine séance grande, remplacements larges, Ma journée haute (grande à trois colonnes et plus), À terminer grande, Alertes larges |
| Élève adulte | Accueil adulte (EA-ACCUEIL, BENTO-3) | `lib/features/accueil_adulte/accueil_adulte_page.dart` (`_Sections`) | Deux colonnes par rangées (`ColonnesParRangees`) | Grille Bento en hauteur de contenu (DASH_STRATEGIE.md §3.7) : Prochaine séance grande, « Avant le prochain cours » grande (s'il y en a), Mon parcours large (une ligne), Dernières séances grande, Ressources grande. Deux grandes tuiles côte à côte seulement si chaque moitié offre 360 px × échelle du texte (`largeurMinCarteClasse`, règle BENTO-2b reprise de l'accueil famille), sinon pleine largeur ; sans « Avant », la Prochaine séance prend toute sa bande ; 2 tuiles ou moins : une colonne sans Bento (D14) |

## Pas de Bento (décision)

| Rôle | Écran | Fichier | Raison |
|---|---|---|---|
| Élève (enfant) | Accueil élève | `lib/features/accueil_eleve/accueil_eleve_page.dart` | Pas de Bento (D14, DASH_STRATEGIE.md §3.2) : deux blocs seulement (`_BlocPrincipal`, `_BlocCoran`) ; le Mode Accessibilité garde une colonne linéaire. |
| Contrôleur | Contrôle (CTR-01) | `lib/features/controleur/controle_page.dart` | Pas de Bento (D14, DASH_STRATEGIE.md §3.6, BENTO-3) : le rôle n'a qu'une chose à faire, une seule carte de mission (et « Compte rendu à terminer » s'il existe), donc 2 tuiles ou moins ; colonne bornée à 640 inchangée. |
| Élève adulte | Mon espace | `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart` | Pas de Bento (DASH_STRATEGIE.md §3.7, BENTO-3) : page de compte (identité, rubriques), pas un tableau de bord ; hors DASH. |

## À reprendre (non modifiés)

| Rôle | Écran | Fichier | Constat |
|---|---|---|---|
| Enseignant | Mes classes | `lib/features/enseignant_classes/mes_classes_page.dart` | Liste de cartes identiques ; à évaluer (liste plutôt que tableau de bord). |

`BentoTile` / `TailleBento` (`lib/core/widgets/bento_tile.dart`) restent en
place : ils donnent la surface d'une tuile, pas sa place. Une étape suivante
peut poser des `BentoTile` dans des `TuileBento`.
