# AD-NETTOYAGE-2 et AD-M2-CAPT : notes de recette (poste admin, 04/10/2026)

Base : `corrections/c1-lib` (c1595c0e, porte AD-NETTOYAGE), puis fusion de `corrections/c1-integ2`
(qui contient c1-lib et AD-M3-PROD, AD-M4-DEFIL). `revue-directeur-2026-10` ne contient pas c1595c0e.

## AD-NETTOYAGE-2 : fait
m6, m7, m8, m11, n3 (portail /attente) ; m9, m10 (file, phrase de validation elidee) ; m12 (raison de 02B en encre douce) ;
m14, n12 (GroupeReglages) ; n1 (`?demo=enseignant` avec `dossier`, alias `tuteur` gardé) ; n6 (masquage du stockage :
modele, parametres, requete, extra, contextes) ; n7 (seuils de BottomSheet) ; n8 (pas de renvoi apres succes,
action Fermer sur DecisionReussie, pas de reentrance) ; n10 (pont de demonstration ferme) ; n11 (helper de test
rend un booleen ; le test de la fiche sans piece l'asserte) ; commentaire de `decider()`.
PageShell defilant : deja traite par AD-M4-DEFIL (fusion) ; ma version a ete abandonnee au profit de la leur.

## Non tranche (decision du directeur ou hors perimetre)
Pastille « En attente » de Comptes, m4, m5, n4, m13 (decision), n9 (supabase/), n5 traite cote capture seulement
(ecran 16 sans repere), n13 (rien a corriger). K-47 : rectifier `01_RELEVE.md` pour la legende de la file (m9) : fichier de pilotage, non touche.

## Choix a signaler
- m8 : colonne centree a 760 comme demande par la revue ; sur bureau le titre de la page reste au bord de la gouttiere
  (a gauche) alors que la carte est centree : decalage visible, a juger.
- n8 : une decision reussie n'est plus renvoyee par `envoyer`.

## AD-M2-CAPT
Captures dans `docs/current/captures/ad-m2-capt/` (96 HL-A-5 = 16 ecrans x 6 + 6 production + 2 ad9_14).
- Ecran 3 : la carte Vérifications est deja a l'ecran quand on touche le lien (le lien ne fait que poser le focus) ;
  la capture 3 est prise en mode de focus « clavier » : elle differe de la fiche par l'anneau de focus sur la premiere case
  (difference mince sur telephone). Hash differents pour les 6 paires (voir ci-dessous).
- portail_apres_refus_* : refaits (hash differents des anciens a8dfcb3, ex. telephone clair 6249d9bd -> c23e7f34).
- Ecran 16 capture sans le repere « Demonstration » (n5).
- Production : `test/capture/ad_m2_production_capture_test.dart` (390, 1440, 320 clair et sombre).
- ad9_14_indisponible_1440 : refait (clair et sombre).
Comptes a aligner dans HL-A-5.md, AD-11.md, AD-RC.md l.36 (fichiers de pilotage, non touches) : 16 ecrans, 96 PNG.
telephone clair fiche=d322f08c2f64 verif=7ce836c1a3b8
telephone sombre fiche=ca073717a260 verif=9cd7de7f29a4
tablette clair fiche=e6c82c8d8717 verif=9c2a4a834b4f
tablette sombre fiche=01483734caa9 verif=ffa22f4d9c89
ordinateur clair fiche=e90397fb9844 verif=448b071b36b3
ordinateur sombre fiche=ac5da2c4dfa8 verif=1074c22c34a4
