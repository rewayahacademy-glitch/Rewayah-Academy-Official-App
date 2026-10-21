# CANDIDATURES : lire d'abord

Reçu le 21/10/2026. Spécification produit du directeur : « Module de gestion des
candidatures et viviers de recrutement », version 1.0, recopiée mot pour mot dans
`REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md`.

## Préalable obligatoire, posé par la spécification elle-même

La section 12 de la spécification rend la revue critique **bloquante** : aucun
écran, aucune migration, aucun port de ce module ne s'écrit avant que le directeur
ait répondu aux questions ouvertes de la revue (`CAND-Q01` à `CAND-Q22`, dont cinq
bloquantes). Le travail ne reprend que sur les points qu'il aura tranchés, dans
l'ordre de la section 14 de la spécification : arbitrage, spécification verticale
consolidée, maquettes et leur contrôle, puis implémentation. Les fiches au
catalogue (`docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`, à créer) s'inscrivent
avant tout fichier `.dart` (section 10 de la revue).

## Ordre de lecture

1. Ce fichier.
2. `REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md` : cartographie de l'existant à la
   pointe de la pile du 21/10, écarts, risques, permissions, modèle proposé,
   transitions, plan d'écrans, recette, et les questions au directeur (section 9).
3. `REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md` : la spécification.

## Règles qui tiennent déjà, quoi que décide le directeur

- Aucune donnée personnelle des formulaires Drive dans le dépôt : la revue n'en
  garde que la structure et des comptes agrégés.
- Une candidature ne crée jamais un compte actif, ne valide jamais une pièce
  d'identité et ne signe jamais un accord au nom de la personne.
- Ce qui décide d'un droit (étape, éligibilité, cloisonnement femmes/hommes) se
  pose en base, jamais à l'écran.
- Les mots visibles passent par `.claude/skills/mots-rewayah`. « Vivier » (dans le
  code, la réserve d'élèves d'une offre horaire) et « salle » (la salle de cours
  unique `/salle`) ont déjà un autre sens dans le dépôt.
