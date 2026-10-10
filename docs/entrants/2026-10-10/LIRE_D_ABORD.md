# Specs entrantes du 10/10/2026 : où lire, qui fait quoi

Livraison du directeur (dossier « à faire »). Quatre ensembles, rangés ici sans modification de contenu.
Le découpage en étapes est dans le tableau de suivi (étapes CAP29-*, RECH-*, COMPTA-RECON-1, SITE-*) et la règle commune dans la consigne K-70.

| Dossier | Document de référence | Étapes | Voie |
|---|---|---|---|
| `cap29/` | `REWAYAH_CAP29_BIBLIOTHEQUE_HANDOFF_CANONIQUE_V1.md` + `HIGH_FI/` (M01 à M04, statiques, jamais copiés dans Flutter) | CAP29-0 à CAP29-H ; serveur : CAP29-BACK-1, -2 | CAP29 (+ TB pour CAP29-G) ; serveur en ATTEND |
| `rech/` | `REWAYAH_RECH_03_SPEC_CANONIQUE_FRONT_BACK_SECURITE_PERFORMANCE_V3.md` + `maquettes/` (IMG-RECH-01 à 07) | RECH-0 à RECH-REC ; serveur : RECH-BACK-1 à 6, RECH-REL | RECH ; serveur en ATTEND |
| `compta/` | `REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md` + 10 maquettes PNG | COMPTA-RECON-1 (déjà largement livré sur ui/comptable-v1 : on mesure l'écart, on ne refait pas) | VERIF |
| `site/` | `REWAYAH_PLAN_SITE_ET_CONFORMITE_2026-10-07.md` | SITE-* | SITE (chantier d'un autre agent, K-64 : une session Claude n'y touche pas) |

Règles de lecture : le document canonique prime sur tout autre texte du même dossier ; les thèmes et composants déjà validés de l'app priment sur les maquettes (K-63) ; aucune maquette n'est un code à copier. Le logo suit `assets/brand/logo/README.md` (K-69).
