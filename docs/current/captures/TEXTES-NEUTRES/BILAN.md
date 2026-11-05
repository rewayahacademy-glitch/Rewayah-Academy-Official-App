# TEXTES-NEUTRES (04/11/2026) : bilan du lot

## Ce qui est faux, bloqué ou non prouvé

- **Fondatrice selon la personne : possible plus tard, si le serveur rend le genre (`personnel_pour_entretien`) ; non fait.** « Fondateur » / « مؤسس » reste le mot décidé (directeur, 03/11), au masculin générique, comme le prescrit mots-rewayah §1 quand le genre est inconnu (décision du pilote, 04/11, 15:22 UTC).
- **Captures de test de widget, pas de la pile locale.** Les refus `nonAutorise` et `autreCote` viennent du serveur, et la feuille ne permet pas de les provoquer simplement depuis l'écran : la liste ne propose que le personnel actif du bon côté. Elles sont donc rendues par `test/features/admin_candidature/entretien_direction_test.dart` (groupe « Capture : TEXTES-NEUTRES », sauté sans `CAPTURE_DIR`), avec les polices réelles du dépôt.
- **Rien n'est prouvé par le directeur en production.**

## Ce qui change

- Arabe seul : les refus `admin.candidatures.entretien.refus.nonAutorise` et `autreCote` disent « شخص مختار » (une personne choisie) au lieu du pluriel masculin « أحد المختارين ». Le français ne change pas (« Une personne choisie… », déjà neutre).
- mots-rewayah §1 : une ligne sur ce mot.

## Preuves

- Test `TEXTES-NEUTRES : en arabe, le refus … dit « شخص مختار »` (deux cas), en RTL. Contre-épreuve : avec l'arabe de main, le test échoue.
- Captures : `textes_neutres_{non_autorise,autre_cote}_{1440,390}_ar.png`, dans ce dossier. On y voit la feuille « Planifier l'entretien » en arabe, avec le bandeau « إجراء مرفوض » ramené en vue.
