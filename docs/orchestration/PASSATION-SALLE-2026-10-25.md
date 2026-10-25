# Passation salle, 25/10/2026

Branche locale `salle-lot1-wip`, poussée en relais sur `claude/admiring-brown-r6ai72-relais`, au-dessus de `5fd66b7` (tête de `claude/admiring-brown-r6ai72`, PR 56). Rien n'est prouvé en production ; tout est testé localement seulement.

## Lot 1 (K4, plein écran sur ordinateur) : fait, testé localement

| Commit | Ce qu'il fait |
| :-- | :-- |
| 7c58cd5 | `/salle` à toutes les largeurs prend la composition plein écran du téléphone (`pleinEcranSalle`, `telephone_plein_ecran.dart`) : page composée sur la hauteur, boîte = ratio du mushaf ×1,4 au plus, centrée, flèches de page dans les marges ; pilule d'état + « Élèves » + présence en haut à gauche, vignette, pilule d'appel, Commandes et palette du tableau au bord droit, erreur caméra en pilule ; tout masqué à 3 s ; tableau = fenêtre |
| b77f8c1 | Tableau 16:9 unique (`TableauLibre.classe`), ajusté à échelle uniforme ; plus aucun chemin ne réécrit le repère à la taille de l'écran |
| 24924ec | Tests K4 (1366, 1920, tableau 390 et 1366), SALLE-PLAN, journal |
| d77362c | Les flèches de page ne rognent plus la boîte de la page |
| 7d3d625 | Zoom − / + visible (pilule flottante droite, 100 à 200 %) ; test « commandes masquées, trait au même rapport x/y » |
| e384e4c | Tests K4 : vraies polices seulement avec `CAPTURE_DIR` (sinon `setUpAll` restait en attente 12 min) |

Mesures : ligne 45,1 px à 768 de haut, 63,5 px à 1080 (≈ 42 à 708, pas 47 : cadre et en-tête du mushaf). Les lignes gardent la proportion du mushaf : la boîte va jusqu'à 1,4 fois la largeur, le texte ne s'étire pas. Les points 1 à 3 sont dans un seul commit (une même bascule).

**Reste du lot 1 (demandé par le pilote à 14:02, pas commencé)** : (1) versionner les quatre captures `k4-*.png` (< 300 Ko) dans `docs/current/maquettes/salle/captures/` avec une ligne dans `LIRE.md` ; les régénérer par `CAPTURE_DIR=<dossier> flutter test test/features/salle_test.dart --plain-name "K4"` ; (2) rétablir les raccourcis M/V/R/B sur ordinateur dans `/salle` (perdus avec `_FocusPanneaux` de `salle_seance.dart`, comme au téléphone), avec un test par touche.

## Lot 2 : fait, testé localement

| Commit | Point | État |
| :-- | :-- | :-- |
| b0dd13c | Attente lisible : `_Seul` (`salle_page.dart`) sur `surfaceSunken`, ornement, « En attente d'Omar », phrase ; test contraste ≥ 4,5:1 clair et sombre, fond non blanc | fait |
| 05ca9d8 | Vignette déplaçable, aimantée aux 4 coins (`VignetteAimantee`, `telephone_plein_ecran.dart`) ; test 1366 et 390 | fait |
| 703b4c9 | Quitter puis revenir : « Retourner dans la salle » + « Retour à l'accueil » (`resultat_seance.dart`, `salle_page.dart`) ; test sans carte | fait ; bandeau d'accueil non ajouté (voir limites) |
| 491404c | Choix du support (feuille « Choisir un support ») et reprise de la dernière page par classe (`memoire_page_classe.dart`) ; tests tuile → 604, Quitter/retourner → 604 | fait, mémoire locale |
| 1d8be81 | SALLE-PLAN et journal | fait |

## Limites dites au pilote

- Reprise de page : mémoire sur l'appareil, tant que l'application reste ouverte ; aucune mémoire de classe côté serveur (migration table + RPC à décider) ; stockage local non durable sur le web, `pubspec.yaml` verrouillé.
- Titre « Sayyid / Sayyida » non lu dans `/salle` : prénom seul (règle TB-10).
- « Retour à l'accueil » remplace « Retour à la Classe » (CLV-09) sur l'écran de sortie.
- Bannière « Séance en cours » non ajoutée : les trois accueils ont déjà un « Rejoindre » direct en tête.
- « Connexion perdue » : la pilule d'état la porte déjà en plein écran ; aucun nouvel écran.
- Perdu sur ordinateur dans `/salle` (comme au téléphone) : la colonne Élèves (feuille à la place) et les raccourcis M/V/R/B (voir reste du lot 1).

## Vérifications faites

`dart analyze --fatal-infos` propre ; `salle_test`, `salle_200`, `d10`, `salle_synchro`, `i18n` : 809 verts ; suites `salle_seance`, `accessibilite`, `tb_recette` : 2 605 verts avant le lot 2 ; jetons 0 ; revue 1076 (socle 1077).

## Pièges

- `pkill flutter` tue aussi la commande qui le lance ; une suite lancée pendant qu'on édite ses fichiers échoue au hasard.
- `PageAvecFlechesMushaf` étire la page sur sa largeur moins deux flèches.
- Les tests de `/salle` ne surchargent pas `stockagePreferencesProvider` : tout stockage y ouvrirait Drift.
- Libellé nouveau ou modifié : le déclarer dans `tool/libelles_sources.json` ; paramètre arabe entre U+2068 et U+2069.
- Pousser plus tard : `git fetch` puis rebase sur `claude/admiring-brown-r6ai72`, push simple, sur ordre du pilote.
