# Revue croisée FI-2-R : couleur de profil (K-62)

- **Objet revu** : `ui/finance-v1`, de `4cc9c472` à `f58645d1`, soit les trois parties de FI-2 : `14ee62a2`, `5840cf64` et `f58645d1`, cette dernière étant la reprise après la revue du directeur. 24 fichiers, +1800 −55.
- **Relecteur** : session cloud `01KyPAZg` (téléphone du directeur). Elle n'a pas écrit FI-2 (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** :
  - K-62 ;
  - la maquette `17_finance/V/11_mobile_sombre_foyer_bandeau_profil_2026-10-04.jpg` ;
  - les captures pilotage `17_finance/captures/FI-2/` (`6dc980eb`).
- **Méthode** : lecture du diff, contrôles relancés sur un worktree propre (Flutter 3.47.6, Dart 3.13.5), une sonde jetable de mise en page, supprimée après usage, et les captures ouvertes.

## Verdict

**Refusée, pour un défaut majeur dont la correction est courte.**

Le fond est juste :

- des jetons d'accent figés, distincts des classes et lisibles ;
- un bandeau derrière le cercle, collé au bord haut de la carte ;
- un choix fait dans les réglages du profil, sans aucune couleur au hasard ;
- un port neutre en production.

Mais **sur tablette et sur ordinateur, la flèche des cartes du Foyer flotte au milieu de la carte**. Elle se place juste après le texte au lieu d'aller au bout de la carte. C'est une régression visible : avant FI-2, la ligne `GroupeReglages` posait la flèche au bout.

→ Nouvelle étape **FI-2-CORR** (voie FIN).

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `flutter test test/features/foyer` | **279 / 0** (37 ignorés) |
| `test/core/widgets/identite_profil_test.dart` | **27 / 0** |
| `test/theme` (dont `accents_profil_test`) | **82 / 0** |
| `test/widgets` (catalogue de la galerie) | **230 / 0** |
| `dart run tool/verifier_jetons.dart` | **39 relevés**, le chiffre de la base |
| Fichiers interdits | `app_palette.dart` est touché, mais c'est l'exception de couleur approuvée par K-62. Les valeurs sont figées par `accents_profil_test` (« toute retouche passe par le directeur »). Rien dans pubspec, supabase, .github, vercel.json ni Coran |

La suite complète de `f58645d1` avait déjà été mesurée par cette session pendant FI-1c-CORR (5356 / 0, avec le patch FI-1c-CORR, qui ne touche pas FI-2).

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| Le bandeau est derrière le cercle, dans la carte | ✅ `BandeauProfil` : rectangle à 84 % de la largeur du cercle, remonté de la marge de la carte jusqu'à son bord haut, il couvre la moitié du cercle, qui reste entier. `PositionedDirectional`, donc RTL juste. Test « bandeau.top = carte.top à 1,5 px près ». La capture `foyer_390_dark` est fidèle à la maquette 11 |
| Jamais une couleur de classe ni un statut | ✅ `accentsProfil` est distinct de `teintesIdentite` (test « jamais une teinte de classe »). La couleur est `ExcludeSemantics`, toujours à côté du prénom |
| Le choix se fait dans les réglages du profil | ✅ Une ligne « Couleur du profil » dans la fiche, dont la légende donne le nom de la couleur. Elle mène à la page `/tuteur/foyer/:eleveId/couleur`, avec `SelecteurCouleurProfil` (6 pastilles et « Sans couleur »). La couleur retenue a trois signaux : un anneau, une coche et son nom écrit dessous |
| Aucune couleur au hasard sans choix | ✅ `accentLu` rend `null` tant que la lecture est en cours, en échec ou indisponible : le cercle est alors seul, sans place réservée. `AccentProfil.depuisCle` rend `null` pour une clé inconnue (test « #FF00FF ») |
| Port neutre en production | ✅ `AccentsProfilsIndisponibles` rend `CapaciteIndisponible('FI-BR-19')`. Seule la démonstration surcharge le port, avec un dépôt en mémoire. Test « sans source (production) : la page le dit, aucun choix » |
| Aucun état optimiste | ✅ La page relit les accents après l'écriture (`ref.invalidate`). Hors ligne et échec ont chacun leur phrase, avec `liveRegion` pour l'échec |
| Lecteur d'écran | ✅ Sonde : la carte du Foyer est un bouton qui lit « Eleve A1 / Accès sans échéance ». `IdentiteProfil` lit « Mariam, profil enfant, Classe An-Nour » |
| Les 15 captures (K-61) | Ouvertes : `foyer_390_dark`, `foyer_1440_light`, `foyer_390_light_200pc`, `fiche_390_light`, `couleur_390_light_200pc`, `couleur_1440_dark`. À 390 px, rien n'est coupé ni ne déborde, à 100 % comme à 200 %. **À 1440 px : voir M1** |

## Défauts retenus

### M1 (MAJEUR) : la flèche des cartes du Foyer flotte au milieu de la carte dès que la carte est large

- **Où** :
  - `lib/features/foyer/ligne_membre.dart`, `CarteMembre`, qui passe la flèche en `fin:` à `AvatarNom.enLigne` ;
  - `lib/core/widgets/avatar_nom.dart`, où le texte est dans un `Flexible` (ajustement lâche) et où `fin` suit donc le texte au lieu d'aller au bout de la `Row`.
- **Mesure** (sonde, carte « Eleve A1 », écart entre le bord de fin de la flèche et celui de la carte) :

  | Largeur d'écran | Écart |
  | :--- | :--- |
  | 390 px | 21 px (la marge, correct) |
  | 1024 px | **502 px** |
  | 1440 px | **264 px** |

  La capture `fi2_foyer_1440_light.png` le montre : la flèche est vers x = 740, la carte finit vers x = 945.
- **Pourquoi majeur** :
  - c'est une régression visible sur l'écran d'accueil du foyer, sur tablette et sur ordinateur, là où le directeur suit le produit en PWA ;
  - avant FI-2, `GroupeReglages` posait la flèche au bout de la ligne ;
  - aucun test ne mesure la position de la flèche.
- **Remède** :
  - dans `CarteMembre`, mettre le texte dans un `Expanded` quand une `fin` est donnée ;
  - ou bien ajouter à `AvatarNom` une option qui le fait, sans changer les 4 autres appelants de `fin:` : `panneau_eleves`, `chrome_seance`, `compte_page`, `child_card` ;
  - ajouter un test qui mesure le bord de fin de la flèche à la marge près, à 390, 1024 et 1440 px, en LTR et en RTL, et refaire les captures 1440.

### Mineurs

- **m1 : en production, la légende de la fiche dit « Sans couleur » alors que la fonction n'est pas ouverte.**
  - **Où** : `fiche_eleve_page.dart`, ligne « Couleur du profil ». `accentLu` rend `null` sur `CapaciteIndisponible`, et la légende vaut alors `couleurAucune`.
  - **Conséquence** : la page derrière dit bien « pas encore disponible », mais la ligne laisse croire à un choix vide.
  - **Remède** : la légende de l'indisponible, comme pour les autres lignes branchées sur un port neutre.
- **m2 : une couleur choisie pour deux autres profils n'en nomme qu'un.**
  - **Où** : `couleur_page.dart`, `priseePar`, qui s'arrête au premier.
  - **Conséquence** : sans effet tant qu'un foyer a peu d'enfants, mais la phrase « déjà choisie pour Yusuf » devient incomplète au-delà.
  - **Remède** : joindre les prénoms.
- **m3 : `lib/CLAUDE.md` garde la phrase d'AVATAR-1 « bandeau sur la carte, pas sur l'avatar », contraire à K-62.** L'auteur le signale lui-même. À corriger par la session qui tient `lib/CLAUDE.md` sur la branche commune.

### Cosmétique

- **c1.** La fiche FI-2-R vise `5840cf64`, mais la branche porte une partie 3 (`f58645d1`, reprise de la revue du directeur). Cette revue couvre les trois parties.

## Pour accepter (FI-2-CORR)

1. Lever M1 : la flèche au bout de chaque carte du Foyer, à toute largeur, en LTR et en RTL. Un test qui la mesure, et les captures 1440 refaites.
2. Dans la même correction, car dans les mêmes fichiers : m1 et m2.
3. Revue FI-2-CORR-R par une autre session que l'auteur de la correction.
