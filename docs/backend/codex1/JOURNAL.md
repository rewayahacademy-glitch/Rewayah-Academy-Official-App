# Codex 1 journal

## 2026-10-13 - B-09 notifications integration WIP

- Lot branch: `codex/backend-b09-notifications-integration-r1` @ `a8c7a6a5763a9def9c2b4b8ceeb12b7b349bc140`.
- Combines on canon `481e9921a2a59fbe8a5c5985a709597a1697f329` the adapter for nine events/four destinations, per-row handling of unknown events, provider/page, and FR/AR labels with sources.
- `dart run slang` succeeded. Targeted `dart analyze --fatal-infos` reported no diagnostics. B-09 targeted tests: 34/34 passed. `git diff --check` clean; no Codex 2 reserved paths changed.
- `dart tool/verifier_revue.dart` was interrupted after over two minutes without output; result unknown. No SQL/PG17 replay. No canon-fixes integration because the source branch is not CONFIRMED. No STAGING/PROD.

## BLOCKED - F86 child registration follow-up

- Existing branch: `codex/backend-f86-registration-acl-r3` @ `9f0349b3785fd5d6a3eec45f19b8e862fbd3d499`, exact remote ref verified.
- Static review confirms the Edge sets server app_metadata `child_of`; the RPC requires matching raw_app_meta_data, a recent Auth user, no existing profile, no confirmed email and no Auth session. The SQL scenarios contain guardian identity setup, role/status refusals, anon EXECUTE checks, and an unproven third-party account refusal.
- No additional source change was necessary for the visible dashboard CHANGES. Remaining proof blocker: no local `psql` or `pg_isready`, so PG17 replay and the `creer_profil_enfant` `md5(pg_get_functiondef)` value cannot be produced here. The migration comment remains `A_CALCULER` for that function. No remote DB, STAGING or PROD used.## 2026-10-13 - B-09 disabled-recipient negative scenario

- Branch: `codex/backend-b09-notifications-negative-r1` @ `89d5e772a78255837bf36f7157f76808fcdad9a4`.
- Adds a disabled-recipient probe to `scenarios_b09_notifications.sql`: authenticated user with disabled profile sees zero notification rows and cannot set `lu_le`. Existing recipient isolation and anon refusals remain.
- `git diff --check` clean; only the scenario changed and the named dollar delimiter is paired. No local `psql`/`pg_isready`; SQL/PG17 replay unavailable. JWT expiry remains a gateway/API test; no STAGING/PROD.## 2026-10-13 - C-35 disabled-reader negative scenario

- Branch: `codex/backend-c35-library-read-negative-r1` @ `dad52bc79c0de63f75bd4608bbd69f8eb7fadb89`.
- Extends `scenarios_c35_library_read.sql`: after positive authorized reads and the active outsider refusal, disables the student account and asserts `autoriser_lecture_version(uuid)` refuses it. Existing anon ACL and direct-table denials remain.
- `git diff --check` clean; one SQL scenario changed; named dollar delimiter paired. No local `psql`/`pg_isready`, so SQL/PG17 replay is unavailable. JWT expiry is a gateway/API check; no STAGING/PROD.## 2026-10-13 - B-13 anonymous-read negative scenario

- Branch: `codex/backend-b13-anon-negative-r1` @ `1a0f9ab0745ab5e1cc10caff3a688e86dcf83740`.
- Extends `scenarios_b13_admin_suspended.sql` with an anon SELECT ACL assertion and a direct anonymous read refusal for `guardian_session_visit`; the active-admin and disabled-admin coverage remains.
- `git diff --check` clean; one SQL scenario changed and both named dollar delimiters are paired. No local `psql`/`pg_isready`, so no SQL/PG17 replay. No STAGING/PROD.## 2026-10-13 - F86 observation-join negative contexts

- Branch: `codex/backend-f86-observation-context-negative-r1` @ `4109340f989a748e8c104c02bf69a0d71537d1aa`.
- Extends `scenarios_f86_observation_join.sql` with refusals for an active guardian role, a disabled account claiming controller, and anon (ACL plus direct call). Existing null-role refusal remains.
- `git diff --check` clean; one SQL scenario changed; all four named dollar tags are paired. No local `psql`/`pg_isready`, so PG17 replay and mutation proof are unavailable. No STAGING/PROD.## 2026-10-13 - F86 take-student negative contexts

- Branch: `codex/backend-f86-take-student-context-negative-r1` @ `43621e0b9ad6363e338bd75fccedc61c95c2f45d`.
- Extends `scenarios_f86_take_student.sql` with refusals for an active guardian role and a disabled account claiming teacher, plus anon ACL and direct-call denials. The existing missing-role refusal remains.
- `git diff --check` clean; one SQL scenario changed; all four named dollar tags are paired. No local `psql`/`pg_isready`, so PG17 replay and mutation proof are unavailable. No STAGING/PROD.## 2026-10-13 - B-11 student concern anon RPC scenarios

- Branch: `codex/backend-b11-student-concern-anon-r1` @ `33c6f60fa7567bd3896b658fa634c25421e9a8ff`.
- Extends `scenarios_b11_student_concern.sql` with anon EXECUTE checks and direct-call refusals for submit, read, and transmit RPCs; existing other-teacher, disabled-teacher, and family-isolation coverage remains.
- `git diff --check` clean; one SQL scenario changed; both named dollar tags are paired. No local `psql`/`pg_isready`, so SQL/PG17 replay is unavailable. No STAGING/PROD.## 2026-10-13 - B-08 published summary negative contexts

- Branch: `codex/backend-b08-summary-negative-context-r1` @ `c381f48c7153beb553a53e3e6ff53f42b1bead12`.
- Extends `scenarios_b08_progression_famille.sql` with anon ACL/direct-call denial and a disabled teacher refusal against the valid owned session/student summary path. Existing cross-teacher and guardian refusals remain.
- `git diff --check` clean; one SQL scenario changed; all three named dollar tags are paired. No local `psql`/`pg_isready`, so SQL/PG17 replay is unavailable. No STAGING/PROD.