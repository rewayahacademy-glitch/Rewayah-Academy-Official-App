# État de l'orchestration Teaching Core — 20/09/2026

## Où en est le chantier

| Phase | Statut |
|---|---|
| Phase 0 — Agent 0 (cartographie, contrats, ownership) | **Terminée.** 6 documents dans `D:\RA_TC\shared\` |
| Phase 1 — Agents A…H + Q (construction parallèle) | **En cours** |
| Phase 2 — Contrôle pré-merge | À lancer après la phase 1 |
| Phase Z — Intégration | Débloquée : `TARGET_SHA` = `0071557` |

## Baseline

- `TEACHING_BASELINE_SHA` = `TARGET_SHA` = **`0071557`** (rôle Enseignant inclus).
- Le chantier enseignant est **terminé et commité**. Le dépôt principal est propre.
- Baseline mesurée : `flutter analyze` **vert**, `flutter test` **871 passent / 1 échoue**
  (`catalogue_galerie_test`, défaut préexistant connu, hors mission).

## Infrastructure

Dix worktrees git isolés, tous issus de `0071557`, `flutter pub get` déjà fait :

| Worktree | Branche | Agent |
|---|---|---|
| `D:\RA_TC\0` | `teaching-core/0-coordinateur` | Agent 0 |
| `D:\RA_TC\a` | `teaching-core/a-group-space` | A — Group Space |
| `D:\RA_TC\b` | `teaching-core/b-library` | B — Library Core |
| `D:\RA_TC\c` | `teaching-core/c-quran` | C — Quran Engine |
| `D:\RA_TC\d` | `teaching-core/d-teaching-tools` | D — Teaching Tools |
| `D:\RA_TC\e` | `teaching-core/e-classroom` | E — Classroom Shell |
| `D:\RA_TC\f` | `teaching-core/f-realtime` | F — Realtime Protocol |
| `D:\RA_TC\g` | `teaching-core/g-observation` | G — Observation & Policies |
| `D:\RA_TC\h` | `teaching-core/h-academic` | H — Academic Flow |
| `D:\RA_TC\q` | `teaching-core/q-qa` | Q — QA |

Le dépôt principal `D:\RA _APP\RA -OFFICIAL-APP` n'est **jamais** touché par ce chantier.

## Contrainte matérielle mesurée

4 cœurs logiques, 7,9 Go de RAM. Le plafond de concurrence des workflows est
`min(16, cœurs − 2)` = **2 agents simultanés**. Les 9 lots s'exécutent donc par vagues de 2,
chacun suivi de son contrôleur adversarial. La durée est longue ; l'isolation et l'absence de
conflit, elles, ne dépendent pas de la concurrence.

## Comment reprendre si la session est interrompue

Workflow phase 1 :
`Workflow({scriptPath: "…/workflows/scripts/teaching-core-phase1-wf_980f37e9-697.js", resumeFromRunId: "wf_980f37e9-697"})`
Les agents déjà terminés rejouent depuis le cache ; seuls les interrompus repartent.

Workflow phase 0 (si besoin) : run `wf_4a87c116-167`.

## Décisions d'orchestration prises

1. **Livrables renommés.** Le chantier enseignant occupait déjà
   `docs/parallel-reports/AGENT_A..E_REPORT.md` et `CONTRACT_REQUEST_A..E.md`. Les livrables
   Teaching Core vont dans `docs/teaching-core/TC_*` et les tests dans `test/teaching_core/`,
   pour supprimer toute collision de noms.
2. **Namespaces préfixés `tc_`.** Les 28 préfixes possédés sont deux à deux disjoints et
   vérifiés contre le code enseignant livré : aucun n'existe dans le dépôt.
3. **i18n déporté.** Aucun agent n'écrit dans `assets/i18n/fr.i18n.json` ni dans les fichiers slang
   générés : chacun dépose ses libellés dans `docs/teaching-core/i18n/tc_i18n_<X>.json`,
   fusion par Agent Z.
4. **Routes sans routeur.** Chaque agent expose `routesTc<X>()` qui *retourne* des routes ;
   aucun second `GoRouter` dans `lib/` (un contrôle CI le refuse).
5. **Rebase sur `0071557`.** Dès la livraison du rôle Enseignant, les worktrees ont été avancés de
   `550e605` à `0071557`, ce qui supprime la phase de réconciliation prévue pour Agent Z.
6. **Aucune migration en phase parallèle.** Dernière existante `0029` ; tout besoin SQL passe par
   la section « DEMANDE SQL » d'un `TC_CONTRACT_REQUEST_<X>.md`.
