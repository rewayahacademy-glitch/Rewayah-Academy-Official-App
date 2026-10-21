# Archive documentaire

Ces documents ne sont **plus des instructions actives**. Ils ont été déplacés le
23 septembre 2026 lors de la remise à plat (`docs/current/` fait foi). Ils sont
conservés pour l'audit et pour retrouver une décision passée nommément.

## `2026-09-pre-remise-a-plat/`

| Dossier ou fichier | Contenu | Statut |
| :--- | :--- | :--- |
| `HANDOFF.md`, `PROGRESS.md`, `AGENT_HANDOFF.md` | journaux de session du 5 au 21 septembre | historique |
| `MISE-EN-SERVICE.md`, `ECART-SPEC-REALITE.md`, `agent-onboarding.md` | mise en service, écart specs/réalité du 18/09 | historique |
| `architecture/decisions.md` | registre ADR-001 à ADR-031 ; les décisions encore valides sont reprises dans `docs/current/00` | historique, à consulter par numéro d'ADR |
| `architecture/etape-*.md`, `audit-initial.md` | plans et journaux des étapes 0 à 5 | historique |
| `architecture/ADMIN_*.md`, `TEACHER_*.md`, `R2_STORAGE_IMPLEMENTATION.md` | contrats et rapports des lots Admin, Enseignant, R2 | historique |
| `design/` | Bible frontend V2 (ADR-019), catalogue d'écrans et de composants | remplacé par `docs/current/03` ; le catalogue reste utile pour retrouver un écran existant |
| `produit/design-tokens.md` | valeurs de jetons mesurées ; `tool/verifier_jetons.dart` les applique encore | référence technique, pas une charte approuvée |
| `produit/parcours-utilisateurs.md`, `bibliotheque-contenu.md` | parcours MVP-0 et formats de contenu | remplacé par `docs/current/01` |
| `parallel-reports/`, `teaching-core/` | rapports et contrats des agents parallèles (lots A à Q) | historique |
| `historique/` | cadrage d'avant le code | historique |
| `racine/CODEX.md`, `racine/CODEX_FRONTEND_BASELINE.md` | instructions de l'agent Codex | caduques |

Les liens en commentaire dans le code (`lib/`, `test/`, `tool/`, `.github/`) ont été
réécrits vers ce dossier ; ils désignent une source historique, pas une règle.
