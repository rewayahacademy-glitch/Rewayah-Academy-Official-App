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
catalogue (`docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`, inscrites le 21/10,
statut proposé) s'inscrivent avant tout fichier `.dart` (section 10 de la revue).

**Réponses du 21/10 : les 22 questions ont une réponse**
(`docs/current/DECISION-CANDIDATURES-2026-10-21.md`, ligne datée au journal `08`).
- Le lot serveur borné est autorisé sur la base de test (`CAND-Q02`).
- Valider la pièce fait entrer en salle 3 (`CAND-Q01`).
- Lien public d'inscription (`CAND-Q03`, `CAND-Q17`).
- Pas de WhatsApp : entretien et contact dans l'app (`CAND-Q06`).
- Séparation femmes/hommes en base, le super-admin voit les deux côtés (`CAND-Q07`).
- Restent ouverts :
  - les pays et moyens de paiement en Afrique (`CAND-Q05`) ;
  - les noms des trois salles (`CAND-Q12`) ;
  - la durée de conservation (`CAND-Q21`, avis du juriste).

La suite suit la section 14 de la spécification : spécification verticale
consolidée, fiches au catalogue et maquettes pour les écrans. Le lot serveur
avance en parallèle, puisqu'il est autorisé.

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
1 bis. `SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md` : **la référence pour construire**
   (spec v1 plus les 22 décisions du directeur). Les documents suivants en sont
   les sources.
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
7. `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md` : une fiche par écran du module
   (18 écrans, statut proposé), à valider par le directeur fiche par fiche avant
   toute maquette.

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
