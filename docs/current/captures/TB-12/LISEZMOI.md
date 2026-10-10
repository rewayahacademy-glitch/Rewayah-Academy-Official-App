# TB-12 : matrice de captures de la recette « Supports et tableau »

- Date : 10 octobre 2026.
- Base : `claude/wizardly-babbage-lmhkog` @ `2d38362e` (branche de travail `tb12-captures`).
- Statut : **testé localement** (rendu `flutter test` avec les vraies polices et icônes du dépôt,
  page `DemoSallePage`, celle que sert `/demo/salle`). Une capture ne prouve ni le réseau ni la
  synchronisation entre appareils : ce qui demande un serveur reste « non vérifiable sans BR-1 ».

## Commande exacte

```
CAPTURE_DIR=docs/current/captures/TB-12 flutter test \
  test/features/tb_recette/captures_tb_test.dart --name tb12_
```

Résultat : `+212, All tests passed`, 212 PNG. Chaque test vérifie d'abord ce que la capture
nomme (page ou feuille montée, notes visibles, Commandes ouvertes ou fermées, aucune commande
chez les observateurs, sens RTL en arabe, absence ou présence de la copie en vol), puis
capture. Les autres étapes ont été régénérées de la même façon, chacune dans son dossier
(`--name tb2_` … `--name tb11b_`, `--name ar_salle_`, et
`test/teaching_core/a/ar_tc_rtl_test.dart` pour AR-TC-1).

## Profils et états (5 × 3)

| Profil | Sans support | Support avec notes | Troisième état |
| :--- | :--- | :--- | :--- |
| `enseignant` | `libre` (PED-01) | `notes` (PED-03) | `commandes` : PED-03, Commandes ouvertes par le vrai déclencheur |
| `eleve` | `libre` | `notes` | `commandes` : ses Commandes (Lecture, Focus), rien de l'enseignant |
| `guidee` (Mode Accessibilité) | `libre` | `notes` | `commandes` : ses Commandes (Ajuster, Focus ; pas de zoom en guidée) |
| `tuteur` | `libre` | `notes` | `lecture` : l'affichage « Tableau » (PED-04) choisi par l'enseignant, lu sans aucune commande |
| `controleur` | `libre` | `notes` | `lecture` : idem |

Les observateurs n'ont pas de Commandes : leur troisième état est l'état équivalent en
lecture (l'affichage commandé par l'enseignant). Ils lisent la page 3 du support ; le cercle
de démonstration est sur la page 1, donc leur capture `notes` ne montre pas de trait.

## Cadrages (14 par profil et par état)

| Nom | Vue logique | Densité | Texte | Thème |
| :--- | :--- | :--- | :--- | :--- |
| `390_x1_clair`, `390_x1_sombre` | 390 × 844 (zone sûre 47/34) | 3 | ×1 | clair, sombre |
| `390_x2_clair`, `390_x2_sombre` | 390 × 844 | 3 | ×2 | clair, sombre |
| `768_x1_clair`, `768_x1_sombre` | 768 × 1024 | 2 | ×1 | clair, sombre |
| `768_x2_clair` | 768 × 1024 | 2 | ×2 | clair |
| `1440_x1_clair`, `1440_x1_sombre` | 1440 × 900 | 1 | ×1 | clair, sombre |
| `1440_x2_clair` | 1440 × 900 | 1 | ×2 | clair |
| `320_x1_clair`, `320_x2_clair` | 320 × 700 | 2 | ×1, ×2 | clair |
| `390_x1_clair_ar`, `1440_x1_clair_ar` | 390, 1440 | 3, 1 | ×1 | clair, **arabe (RTL)** |

`768_x2_sombre` et `1440_x2_sombre` sont omis pour tenir sous 220 PNG (le sombre à ×2 est
couvert à 390, la taille la plus contrainte après 320).

Plus deux captures de mouvement : `tb12_enseignant_rangement_en_cours_mouvement_reduit_390_x1_clair`
(« réduire les animations » actif : aucune copie en vol, état final aussitôt) et
`…_mouvement_ordinaire_390_x1_clair` (la copie de la page en vol vers la Bibliothèque, 80 ms
après « Ranger dans la bibliothèque »).

Total : 5 × 3 × 14 + 2 = **212 PNG**.

## Ce que la lecture des captures a relevé

- Corrigé : élève au bureau à texte ×2, « Zoom local, sans effet sur les a… » était coupé
  (`lib/features/salle_seance/barre_support.dart`, `ZoomLocal`) ; la phrase passe sur deux
  lignes, la rangée ne grandit pas (`test/features/tb_recette/zoom_local_libelle_test.dart`,
  qui échoue sans la correction).
- Ouvert, 320 × 2 : la tête bornée de la salle prend environ la moitié de l'écran ; la page
  PED-03 n'y occupe qu'environ un tiers de la largeur (titre illisible), et la feuille des Commandes n'en montre que le
  titre et les onglets (le reste défile). La phrase de conservation des notes n'y tient pas
  entière (« uniquement » coupé par le bord bas).
- Ouvert, 320 × 2, élève et guidée en PED-01 : la vignette de l'enseignant couvre le coin
  haut de la feuille du tableau libre.
- Ouvert, salle des observateurs (`features/salle`, hors périmètre TB) : la scène suit le
  registre inverse, sombre en thème clair et claire en thème sombre.
- Ouvert : la mention « Cours enregistré » et son point rouge ne correspondent à aucun
  enregistrement réel côté client (arbitrage ouvert, `06`).
