# Captures du lot 4 SALLE-1-TOUT-ICI

Les captures sont des **captures de widgets** : outil `test/capture`, vraies polices, données de test seulement. Ce ne sont pas des captures du robot sur la pile locale.

## Portail du candidat (PR 298, puis la suite)

`test/capture/salle_1_tout_ici_capture_test.dart` produit `<état>_<langue>_<taille>.png`, avec quatre états :

| État | Contenu |
| :--- | :--- |
| `a_completer` | Tout reste à faire (cadre, accords, pièce) : page unique « Votre candidature », chaque élément avec son état, prochaine action « Lire et accepter nos conditions ». |
| `a_completer_piece` | Accords faits, pièce à déposer : la prochaine action est « Déposer ma pièce ». |
| `envoyee` | Candidature envoyée, « Votre candidature est envoyée ». |
| `faisons_connaissance` | Salle 2 : l'en-tête dit « Faisons connaissance », jamais un nom de salle de la direction. |

Chaque état est capturé en français et en arabe, à 390x844 et à 1440x900.

## Place de l'action principale, avant et après

Arbitrage du garde-cap du 07/11 (PLAN-TROIS-SALLES §2, option c).

- **Avant** : `docs/current/captures/E2E/sans-barre-fixe/sbf_apres_piece_a.png` et `sbf_apres_candidature_a.png` (lot SANS-BARRE-FIXE de B).
- **Après** : `sbf_apres_lot4_piece_a.png` et `sbf_apres_lot4_candidature_a.png`, ici.
- Outil des deux séries : `test/capture/sans_barre_fixe_capture_test.dart`, à 390x844, densité 3, français.

| Écran | Avant (B) | Après (lot 4) |
| :--- | :--- | :--- |
| Pièce, « Envoyer ma pièce » | y ≈ 954, hors du premier écran | Dans le premier écran, avant comme après le choix du type. La zone d'action mesurée (y ≈ 970) ne porte plus que « Se déconnecter », en fin de page. |
| Candidature (présentation), « Continuer » | y ≈ 834 à 942, coupé | y = 788, dans le premier écran |

La garde `test/features/salle1_action_premier_ecran_test.dart` le vérifie à chaque CI : les trois écrans de présentation, et la pièce avant et après le choix du type.
