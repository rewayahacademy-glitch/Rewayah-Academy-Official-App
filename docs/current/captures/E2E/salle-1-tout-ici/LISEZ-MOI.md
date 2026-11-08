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

Arbitrage du garde-cap du 07/11 (PLAN-TROIS-SALLES §2) : l'action reste en fin de fil. Pour la pièce et la candidature, elle se voit sans défiler (option c). Pour les accords et le contrat, elle reste en fin de texte, avec en haut une seule ligne discrète, « Lisez jusqu'en bas pour confirmer » (`LireJusquEnBas`).

- **Avant** : `docs/current/captures/E2E/sans-barre-fixe/sbf_apres_<écran>_a.png` et `_b.png` (lot SANS-BARRE-FIXE de B, en français).
- **Après** : `sbf_apres_lot4_<langue>_<écran>_a.png` (ouverture) et `_b.png` (bas de page), ici, en français et en arabe.
- Outil des deux séries : `test/capture/sans_barre_fixe_capture_test.dart`, à 390x844, densité 3 ; `CAPTURE_LANGUE=ar` pour l'arabe.

| Écran | Avant (B, fr) | Après (lot 4) |
| :--- | :--- | :--- |
| Pièce, « Envoyer ma pièce » | y ≈ 954, hors du premier écran | Dans le premier écran, en fr comme en ar, avant comme après le choix du type. La zone d'action mesurée ne porte plus que « Se déconnecter », en fin de page. |
| Candidature (présentation), « Continuer » | y ≈ 834 à 942, coupé | y = 788 en fr, 665 en ar |
| Accords | action à y ≈ 1792 | Action toujours en fin de texte (y ≈ 1816 en fr, 1459 en ar), ligne « Lisez jusqu'en bas » en haut |
| Contrat | action à y ≈ 1588 | Action toujours en fin de texte (y ≈ 1612 en fr, 1266 en ar), ligne « Lisez jusqu'en bas » en haut |

La garde `test/features/salle1_action_premier_ecran_test.dart` vérifie à chaque CI la pièce et la candidature. La ligne « Lisez jusqu'en bas » est vérifiée dans `dossier_accords_test.dart`, `dossier_test.dart` et `recrutement/signature_contrat_page_test.dart`.
