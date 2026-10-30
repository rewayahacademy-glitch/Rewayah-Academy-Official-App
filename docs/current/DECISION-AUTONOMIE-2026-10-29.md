# Autonomie des agents et deux agents en parallèle, décision du directeur du 29/10/2026

Décision écrite par le pilote, sur ordre explicite du directeur du 29/10/2026 au soir. Elle amende
le point 4 du plan de la Boucle 1 (« aucune session parallèle ») et les invariants de `CLAUDE.md`
sur les PR vers `main`, la fusion et les migrations.

## 1. Ce que le directeur a dit

- « Oui, deux agents. »
- Les PR, les migrations, les lectures et les modifications de la base : « Je veux que tu gères
  cela. » Le directeur ne lit pas le code ; ses confirmations n'ajoutaient aucun contrôle.
- Être économe : pas d'allers-retours inutiles, les petits modèles pour les petites tâches.

## 2. Qui fait quoi désormais

| Action | Avant | Désormais |
|---|---|---|
| Ouvrir une PR vers `main` | le directeur | l'agent qui a construit le lot |
| Fusionner dans `main` (mise en production) | le directeur | **le pilote seul**, CI verte sur le dernier commit, une fusion à la fois |
| Migration en production | le directeur colle le SQL | le pilote, par `apply_migration`, après la fusion du lot qui la porte, dans l'ordre des numéros |
| Écriture directe dans la base hors migration | interdite | **toujours interdite** (`execute_sql` reste en lecture seule) : une correction de données passe par une migration, qui laisse une trace |
| Réglages Supabase (tableau de bord), `.github/`, `pubspec.yaml`, `vercel.json`, garde-fou | le directeur | inchangé : le directeur |
| Preuve en production | le directeur | inchangé : « fait » veut dire prouvé par le directeur |

Le garde-fou ne distingue pas les sessions : techniquement, toute session peut fusionner et
appliquer une migration. La règle est donc écrite dans chaque consigne d'agent de construction, en
toutes lettres : **interdit : `merge_pull_request`, `apply_migration`**. Avant chaque fusion, le
pilote relit lui-même les vérifications du dernier commit de la PR (toutes vertes, aucune en
cours). Avant toute migration qui supprime une fonction (`DROP FUNCTION`), il vérifie qu'aucun code
déjà en production ne l'appelle encore.

Restent interdits par le garde-fou : pousser directement sur `main` sans PR, forcer un envoi,
supprimer une branche distante, déclencher un workflow, déployer une fonction Edge en production,
modifier le garde-fou.

## 3. Deux agents de construction, au plus

1. Chaque agent a une zone écrite dans sa consigne : branche, dossiers, numéros de migration. Il
   ne touche pas la zone de l'autre.
2. Le pilote attribue les numéros de migration.
3. Les textes i18n (`assets/i18n`, fichiers générés) : un seul agent à la fois, désigné par le
   pilote.
4. Un agent ne reçoit une nouvelle tâche que lorsque la précédente est fusionnée et prouvée, ou
   mise en liste d'attente avec l'accord du directeur.
5. Le directeur reçoit une seule action à la fois.
6. Le pilote vérifie lui-même chaque « c'est fait » avant de le relayer.
7. Les petites tâches (relecture, documentation, recherche) vont à de petits modèles et ne
   touchent pas au code de l'application.

## 4. Répartition au 29/10

| Agent | Zone |
|---|---|
| Boucle 1, session `0163KjryLQrmy9HtWPRhdvc7` | lot B (admission), puis C ; migrations `20261029120000`, `20261029150000` ; seul sur l'i18n |
| Créneaux, nouvelle session | classes à plusieurs créneaux, branche `claude/admiring-brown-r6ai72-creneaux` ; migrations `2026103010xxxx` |

## 5. Risque accepté

Entre l'erreur d'un agent et la production, il n'y a plus de regard humain avant la preuve. Les
garde-fous qui restent sont la CI (Flutter, migrations rejouées sur un Postgres nu, scénarios) et
la relecture du pilote. En cas d'erreur après fusion : le pilote ouvre aussitôt une PR qui annule
le lot (`git revert`), et le directeur peut rétablir le déploiement précédent depuis Vercel.
Inconnu non levé : l'existence et la fréquence des sauvegardes automatiques de la base de
production (dépend de l'offre Supabase) ; le pilote le vérifie avant la première migration.
