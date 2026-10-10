# Reprise après coupure (limite d'usage de Claude)

**Directeur, 10/10/2026.** Si la session de Claude s'arrête sur la limite d'usage, la reprise peut n'être possible que plusieurs jours plus tard. Ce fichier dit, en une page, où l'on en est et quoi faire en premier. Il remplace la relecture de la conversation.

## Où en est la branche `ccr-1b1bfa0b-m1kvkk` (10/10, soir)

- Fusionnés et poussés : GARDE-FOU-1 et 2, CLAVIER, ECHELLE-CORR-ECRANS-1, AR-REUNION-1, correction `SondageRegulier` (retour à la cadence dès la première réussite).
- Suite complète : 11 284 tests passés, 1 échec trouvé puis corrigé (test ciblé vert, suite complète non relancée).
- Déjà en échec avant ces fusions, à nettoyer dans un petit lot : `verifier_jetons` (`groupe_reglages.dart:391`) et `verifier_revue` (vérifier l'écart au socle).

## Ordre des priorités (dates acceptées par le directeur)

| Date cible | Étape | Qui |
| :--- | :--- | :--- |
| 13/10 | SEC-PROD : relecture adversariale de `docs/backend/SEC_PROD_REMEDIATION.sql` (PR #22, tête 747d65ba), puis exécution PROD sous le GO de la ligne 85 du Journal distant | Codex exécute, Claude relit |
| 15/10 | Test de bout en bout sur STAGING | Codex et Claude |
| 16/10 | Parcours de recrutement enseignant sur STAGING : invitation, pièces, signature probante, activation bloquée sans signature (Questions, lignes 54 et 55) | Codex le serveur, Claude les écrans |
| 18 à 20/10 | Mise en production après GO du directeur, premiers enseignants, petit groupe de classes | Directeur |

Arabe : non prioritaire (pas de public arabophone au lancement).

## Décisions du directeur (10/10, soir)

- Paie enseignant : hors de l'app au lancement (virements manuels).
- Contrat enseignant : le texte de l'app est celui des enseignants actuels, réadapté ; il est validé pour la signature.
- GitHub Actions : minutes du mois épuisées (courriel GitHub reçu). On fait sans : contrôles locaux (Flutter) et rejeu local ou transactionnel sur STAGING (base) tiennent lieu de preuve, notés comme tels ; aucune relance de CI. Reste ouvert : la mise en production passe par `flutter-deploy.yml` (Actions) ; avant le 18/10, il faut soit un petit budget de dépassement GitHub, soit la remise à zéro mensuelle.

## Pendant une coupure de Claude

Codex continue le serveur sur ses branches `codex/*` et écrit dans la feuille de liaison (onglets Questions et Contrats). Rien ne part en PROD sans la relecture de Claude et le GO du directeur. À la reprise : lire ce fichier, puis les lignes ouvertes de l'onglet Questions (colonne F vide adressée à Claude), puis le tableau.

## Économie d'usage

- Une session dédiée par lot, courte, sur Sonnet ; Opus seulement pour la sécurité et les arbitrages (`SESSIONS-ET-MODELES.md`).
- La session d'orchestration repart à neuf plutôt que de traîner un long historique.
- La suite complète des tests tourne une fois avant chaque fusion, en arrière-plan.
