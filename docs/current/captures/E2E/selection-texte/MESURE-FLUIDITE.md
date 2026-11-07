# SELECTION-TEXTE (PR 293) : mesure de fluidité du défilement (C1)

**Verdict : aucune régression mesurable.** Moyenne des trois essais : 25,9 ms par image avant, 26,5 ms
après (+0,5 ms, +2 %), alors que l'écart entre deux essais d'une même version atteint 2,3 ms. La
différence est dans le bruit. **Non prouvé** : la fluidité sur un vrai appareil (voir limites).

## Ce qui a été mesuré

- Liste : Personnes > Comptes, 100 lignes affichées d'un coup (taille de page maximale proposée), 268
  comptes de test en base (`mesure-N@test.invalid`, aucune donnée réelle). **Écart à la consigne** :
  le maximum par page est 100 (Candidatures : 50 en dur), donc pas 200 lignes dans une même vue ;
  les 268 existent derrière la pagination.
- AVANT : `bf026fffa`, l'état de `main` fusionné dans la branche (la tête de `origin/main` a 17
  commits sans rapport en plus). APRÈS : `02688ae1f1b7`. Même SDK, même base, même robot.
- Build web release (`flutter build web --release`), pile locale, Chromium sans carte graphique
  (rendu logiciel), 1440 x 900.
- Geste : 160 crans de molette vers le bas (120 px, un toutes les 16 ms), puis 160 vers le haut,
  soit environ 19 000 px, la liste entière aller-retour. Mesure : intervalle entre deux
  `requestAnimationFrame`, tâches longues (`longtask`). Essais alternés avant / après, un contexte
  neuf chacun.

## Résultats (3 essais chacun)

| Version | Essai | Moyenne (ms) | p90 (ms) | p99 (ms) | Images > 33 ms | Images > 50 ms | Tâches longues |
| :-- | :-: | --: | --: | --: | --: | --: | --: |
| Avant | 1 | 25,84 | 50,0 | 66,8 | 217 | 90 | 144 |
| Avant | 2 | 27,15 | 66,6 | 83,4 | 214 | 136 | 184 |
| Avant | 3 | 24,83 | 50,0 | 66,7 | 198 | 64 | 116 |
| **Avant, moyenne** | | **25,94** | 50-66,6 | | 210 | 97 | 148 |
| Après | 1 | 27,58 | 66,7 | 83,4 | 214 | 143 | 183 |
| Après | 2 | 25,73 | 50,0 | 66,8 | 215 | 92 | 136 |
| Après | 3 | 26,12 | 50,1 | 83,4 | 211 | 102 | 144 |
| **Après, moyenne** | | **26,48** | 50-66,7 | | 213 | 112 | 154 |

Lecture : les plages des deux versions se recouvrent sur chaque colonne (moyenne avant 24,8 à 27,2 ;
après 25,7 à 27,6). Le meilleur et le pire essai sont de chaque côté selon la colonne.

## Limites, dites en premier

- Ce n'est **pas** le profil Flutter : le temps de build et le temps de raster ne sont pas séparés
  (il faudrait un profil sur appareil). On mesure l'intervalle entre images.
- Rendu logiciel : même sans le lot, la page n'atteint pas 60 images par seconde (moyenne 26 ms).
  L'écart relatif est lisible, la valeur absolue ne dit rien d'un téléphone.
- Trois essais seulement : une régression de moins de 2 ms ne serait pas distinguée du bruit.
- Seul le défilement à la molette est mesuré ; ni la sélection du texte, ni le défilement tactile.
- Rien n'a été poussé sur `claude/selection-texte`.

Robot : `tool/e2e/mesure_fluidite.mjs` (`E2E_APP`, `E2E_TRAVAIL`).
