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

**Réponses du 21/10** (`docs/current/DECISION-CANDIDATURES-2026-10-21.md`) :
- `CAND-Q02` validée : le lot serveur borné est autorisé sur la base de test ;
- `CAND-Q04` validée ;
- principes posés pour `CAND-Q03` (lien public d'inscription), `CAND-Q05`
  (inscription ouverte à tous les pays, salles 2 et 3 réservées aux personnes
  que l'académie peut payer) et `CAND-Q06` (pas de WhatsApp, entretien et contact
  dans l'app) ;
- `CAND-Q07` (séparation en base, le super-admin voit les deux côtés) et
  `CAND-Q08` validées ; `CAND-Q09` : aucune mention pendant l'entretien ;
- `CAND-Q01` reste en discussion ;
- `CAND-Q10` à `CAND-Q22` attendent.

## Où le directeur répond

Une page privée reprend les vingt-deux questions, chacune avec sa raison et la
recommandation : <https://claude.ai/artifact/JVZ8QM5e1ZnEPaiQPHEoEE>. Chaque
réponse enregistrée y est un document de la collection `reponses` (identifiant
`CAND-Qnn`, champs `choix` : `valide`, `autre` ou `discuter`, `texte`, `maj`),
lisible par Claude. Les réponses de Claude aux remarques du directeur sont dans la
collection `retours` (même identifiant, champs `texte` et `maj`) et s'affichent sous
la question. Une réponse ne devient une décision qu'une fois versée dans
`docs/current/` avec sa date (règle de `docs/current/08` §1).

## Ordre de lecture

1. Ce fichier.
2. `REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md` : cartographie de l'existant à la
   pointe de la pile du 21/10, écarts, risques, permissions, modèle proposé,
   transitions, plan d'écrans, recette, et les questions au directeur (section 9).
3. `REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md` : la spécification.
4. `CONTRAT_PORTS_CANDIDATURES.md` et `DEPENDANCES_BACKEND.md` : le contrat
   attendu des ports et les besoins serveur `CAND-BR-01` à `CAND-BR-18`, préparés
   comme la spec §1.2 le permet, au statut de proposition. Chaque méthode et
   chaque besoin citent la question du directeur dont ils dépendent.
5. `MAPPAGE_IMPORT_FORMULAIRES.md` : comment chaque colonne et chaque option des
   formulaires Google devient un champ de la candidature (en-têtes et libellés
   seulement, aucune réponse de personne), normalisation des contacts, doublons.
6. `CORRECTIFS_HORS_MODULE_PROPOSES.md` : les cinq défauts trouvés hors du module
   (`CAND-Q15`), chacun avec son correctif proposé, sa recette, sa reprise des
   données, l'ordre d'application et ce que le directeur doit trancher. Rien n'y
   est appliqué ni rejoué.

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
