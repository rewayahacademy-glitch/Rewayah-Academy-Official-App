# BENTO-1 : recensement des tableaux de bord (02/10/2026)

Composant partagé : `lib/core/widgets/grille_bento.dart` (`GrilleBento`,
`TuileBento`, `EtendueBento`, `placerBento`). Deux colonnes sous 600 px de
largeur offerte, quatre au-delà ; écart 16 px (K-55) ; ligne de 160 px
(`GrilleBento.hauteurLigne`) ; une seule colonne de hauteur libre dès que le
texte dépasse 115 %.

## Fait dans ce lot

| Rôle | Écran | Fichier | Avant | Après |
|---|---|---|---|---|
| Direction | Centre de commande (ADM-01) | `lib/features/admin_tableau/tableau_de_bord_page.dart` | 6 `StatTile` identiques dans un `Wrap` (damier 2 x 3) | Grille Bento : Dossiers 2x1 (2x2 sur 4 colonnes) avec phrase d'action, Demandes 1x2 avec phrase, Élèves sans enseignant et Cahiers manquants 1x1, Incidents + Accès échus regroupés 2x1 (4x1) quand ils valent 0 |

## À reprendre (non modifiés)

| Rôle | Écran | Fichier | Constat |
|---|---|---|---|
| Élève (enfant) | Accueil élève | `lib/features/accueil_eleve/accueil_eleve_page.dart` | `BentoTile` empilées en pleine largeur (`TailleBento.pleine` par défaut, aucune autre taille utilisée dans `lib/features`) ; passage en deux colonnes égales via `accueil_accessibilite.dart`. Candidat direct à `GrilleBento`. |
| Tuteur | Accueil famille | `lib/features/accueil_famille/accueil_famille_page.dart` | Une colonne sur téléphone, deux colonnes égales sur bureau (carte classe / carte groupée). Pas de damier, mais aucune variation de forme. |
| Enseignant | Aujourd'hui (ENS-02) | `lib/features/journee/journee_page.dart` (`_Composition`) | Une ou deux colonnes égales (Prochaine séance, Ma journée, À terminer, Alertes). À passer en Bento : Prochaine séance large, Ma journée haute. |
| Élève adulte | Accueil adulte / Mon espace | `lib/features/accueil_adulte/accueil_adulte_page.dart`, `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart` | Cartes empilées en une colonne ; aucune grille. |
| Contrôleur | Contrôle | `lib/features/controleur/controle_page.dart` | Une seule colonne bornée (missions, à terminer) ; aucune grille. |
| Enseignant | Mes classes | `lib/features/enseignant_classes/mes_classes_page.dart` | Liste de cartes identiques ; à évaluer (liste plutôt que tableau de bord). |

`BentoTile` / `TailleBento` (`lib/core/widgets/bento_tile.dart`) restent en
place : ils donnent la surface d'une tuile, pas sa place. Une étape suivante
peut poser des `BentoTile` dans des `TuileBento`.
