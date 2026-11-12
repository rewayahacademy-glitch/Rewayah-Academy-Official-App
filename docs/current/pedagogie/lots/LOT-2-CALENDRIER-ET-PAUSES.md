# Lot 2 · CALENDRIER-ET-PAUSES

> Branche `claude/calendrier-pauses`, ouverte le 12/11/2026 sur la branche du lot 1 (`claude/socle-programme`, tête `138adce9`), charte à jour (`claude/charte-ecole` déjà contenue).
> Plan : `PLAN-DE-CONSTRUCTION.md`, section « Lot 2 ». Valeurs : `REGLAGES.md`, partie 2.
> Migrations : `20261123910000_calendrier_pauses.sql` (sans aucun mot d'effacement) et `20261123911000_calendrier_pauses_evenement.sql` (un seul `DROP CONSTRAINT`, pour l'événement de notification ; à coller par le directeur).
> Statut : voir la fin de cette fiche (« Ce qui est fait et testé »). Rien n'est installé ni prouvé en production.

## Ce que le lot réutilise

| Existant | Comment |
|---|---|
| `eleve_etape_en_cours.recul_jours` et `private.dates_etape` (lot 1) | Point d'accroche : la colonne devient une valeur **dérivée**, recalculée par un déclencheur ; `dates_etape` n'est pas touchée et rend déjà la date limite reculée. |
| `etape_eleve_lecture` (lot 1) | Reste la lecture unique de l'étape ; une clé `recul_jours` y est ajoutée (masquée pour l'enfant de 6 à 9 ans, comme les dates). |
| `app_config` | Les valeurs : préavis, plafond, fenêtre, délai de réponse, jours maximum des fermetures. Un déclencheur valide leurs bornes. |
| `public.materialiser_seances_groupe` | Ne crée plus de séance un jour de fermeture publiée (réécriture par remplacement exact, avec empreinte et préflight, comme `20261030100000`). |
| `notifications`, `private.notification_courriel` | La réponse de la direction à une demande de pause. |
| `public.app_role()`, `app_household_id()`, `app_account_valid()`, `cohortes_age`, `student_profiles.student_type` | Portes et tranches ; rien de nouveau. |
| `pause_seances`, `pause_reglages` | **Sans rapport** : la pause de 5 minutes pendant une séance. Non touchées. |

## Ce que le lot crée

- `public.calendrier_ecole` : fermetures, rencontres de récitation, dates d'évaluation, autres dates. Type, titre, du / au, portée (école, tranche d'âge, classe), publié ou non.
- `public.pauses_eleve` : pause d'un mois (mois civil entier) et pause d'exception, statut, motif, décision.
- `private.recul_jours_calcule` : **le seul endroit** où le recul de la date limite est calculé (fermetures et pauses, sans double compte, jusqu'à stabilité).
- `private.eleve_en_pause(élève, date)` et `private.eleve_en_pause_mois(élève, mois)` : la lecture propre, pour le moteur (lot 7) et, plus tard, la facturation. Rien n'est branché sur l'argent.
- `private.jour_ferme_pour_classe(date, classe)` : le fait « jour fermé » ; utilisé par la génération des séances.
- Gestes serveur (tous `SECURITY DEFINER`, `search_path = ''`, porte positive, EXECUTE retiré de PUBLIC et anon) : saisie, publication et lecture du calendrier ; demande, annulation et décision d'une pause ; pause d'exception.
- Écrans : direction (calendrier de l'école ; demandes de pause), tuteur et élève adulte (demander une pause d'un mois).

## Choix

À compléter pendant la construction (voir la fin).

## Écarts entre le plan et le code trouvé

À compléter.
