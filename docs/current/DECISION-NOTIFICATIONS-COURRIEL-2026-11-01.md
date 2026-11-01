# Courriel ou application seulement, décision du directeur du 01/11/2026

Décision écrite par le pilote, sur ordre du directeur relayé par le garde-cap le 01/11/2026 vers
05:40 (GMT+3). Elle amende la ligne 15 de `FICHE-FRAICHEUR-NOTIFICATIONS-2026-10-27.md`
(« un courriel part pour chaque notification »).

## 1. Ce que le directeur a dit

« Tout ce qui n'est pas urgent ou qui n'a pas besoin d'une trace reste dans l'app. » Les familles
et les enseignants reçoivent déjà trop de courriels.

## 2. La règle

Chaque notification apparaît dans l'application. Un courriel part en plus **seulement** si
l'événement est urgent ou s'il doit laisser une trace. Le choix se fait par événement et par
portée (`soi`, `foyer`, `classe`, `direction`), sur le serveur, jamais dans Flutter.

## 3. La table (elle fait foi ; le directeur peut rayer une ligne)

Codes des événements tels qu'ils existent en base (`private.notifier_classe` et voisins).

### Courriel et application (urgent ou trace)

| Événement | Portée | Pourquoi |
|---|---|---|
| `seance_annulee` | toutes | urgent |
| `seance_deplacee` | toutes | urgent |
| `enseignante_absente` | toutes | urgent |
| `remplacement_propose`, `remplacement_pris` | toutes | urgent |
| `creneau_change` | toutes | urgent |
| `classe_creee`, `classe_validee` | `soi`, `foyer` | trace |
| `eleve_inscrit` | `soi`, `foyer` | trace |
| `acces_suspendu_paiement`, `acces_retabli_paiement` | toutes | trace |
| `paiement_relance` | toutes | trace |
| `demande_recue`, `demande_close` | toutes | trace |
| `mot_accueil` | toutes | trace |

### Application seulement

| Événement | Portée |
|---|---|
| `seance_terminee` (FN-028, à créer) | toutes |
| `eleve_inscrit`, `eleve_retire` | `classe` (l'enseignant voit sa liste bouger) |
| `enseignant_affecte`, `enseignant_change` | `classe` |
| `classe_changee` | toutes |
| `titulaire_en_retard` | toutes |
| `remplacant_arrive` | toutes |
| tout ce qui concerne la salle pendant la séance | toutes |

### Non classés par la décision : état actuel conservé (courriel) jusqu'à la décision du directeur

`classe_supprimee`, `remplacement_designe_admin`, `eleve_retire` portée `soi` et `foyer`,
`enseignant_affecte` et `enseignant_change` portées `soi` et `foyer`. Le pilote ne les classe pas
lui-même : le directeur tranche, et la table ci-dessus prend la ligne.

## 4. Comment c'est appliqué

- Une migration ajoute un drapeau `courriel boolean` par événement et par portée, lu par le chemin
  qui écrit aujourd'hui une ligne `courriels_sortants` par notification (mécanisme du 23/10,
  `20261023120000_courriels_sortants.sql`, conservé, pas dupliqué). Valeurs : la table du §3.
  Aucune valeur dans Flutter.
- Un scénario SQL vérifie : une notification « application seulement » n'écrit aucune ligne
  `courriels_sortants` ; une notification « courriel » en écrit une, une fois ; un compte enfant
  n'en reçoit toujours aucune.
- Le pilote ne peut pas écrire `supabase/` : la migration est construite par l'agent du lot
  « fin de séance », dans l'étape FN-028 qui crée `seance_terminee` (même fonction, même scénario,
  une PR), et non par un troisième constructeur.

## 5. Statut

| | Statut |
|---|---|
| Règle et table | spécifié (décision du directeur du 01/11/2026) |
| Drapeau `courriel` | non présent dans le code ; étape FN-028 du lot « fin de séance » |
| Production | aujourd'hui, un courriel part pour chaque notification (ligne 15 de la fiche du 27/10) |
