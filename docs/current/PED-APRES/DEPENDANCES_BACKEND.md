# PED-APRES-1 · Dépendances backend (non traitées, non livrées)

Statut : `spécifié` seulement. Rien ci-dessous n'existe côté serveur ; le frontend dit « indisponible » en production.

| # | Besoin | Écran qui l'attend | État frontend |
| :--- | :--- | :--- | :--- |
| 1 | Projection familiale par (élève, séance), indépendante de `lesson_reports`, issue de K-45 sans nouvelle saisie | TUT-PED-APR-01 | `compteRenduFamille`, état « Le compte rendu ne peut pas être affiché. » |
| 2 | Politique persistante de classe + exception élève, version de concurrence | ADM-PED-APR-02 | `partageClasse`, `definirPartageClasse`, `definirRegleEleve` : « Le réglage de partage n'est pas encore disponible. » |
| 3 | Statut de publication ciblé, publication et révocation avec effet sur toutes les lectures (liens directs, caches côté serveur) | ADM-PED-APR-03 | `apercuFamilial`, `publier`, `revoquer` |
| 4 | Publication automatique à la confirmation du cahier, sans rétroactif en masse | A02, A22 | oracle dans le double |
| 5 | Historique des actions (auteur, date, type) | ADM-PED-APR-03 | affiché seulement si fourni |
| 6 | Liste des comptes rendus d'un élève dans une classe | point d'entrée provisoire d'ADM-PED-APR-03 | `comptesRendusEleve` |
| 7 | Comptes adultes autonomes et changements de foyer / classe selon contrats actuels | A13, A14 | lecture réévaluée à chaque ouverture |
| 8 | Rapprochement avec `resume_seance_famille` (migration 0054, PR #21 `codex/backend-f2-after-c`) | TUT-PED-APR-01 | port existant conservé inchangé |
| 9 | **Décision directeur** : point d'entrée réel d'ADM-PED-APR-03 (aucune lecture admin de cahier confirmé n'existe ; entrée provisoire via la règle d'un élève dans l'inspecteur) | ADM-PED-APR-03 | voir AUDIT_ETAPE0 §6 |

Aucune migration, RPC, RLS ni adaptateur `*_supabase.dart` n'a été écrit dans ce lot.
