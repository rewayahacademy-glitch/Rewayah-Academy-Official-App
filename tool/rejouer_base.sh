#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS="$ROOT/supabase/tests"
MIGRATIONS="$ROOT/supabase/migrations"
DB="rewayah_codex2_${$}_$(date +%s)"
TMP="$(mktemp -d)"
CREATED=0

cleanup() {
  if [[ "$CREATED" == 1 ]]; then dropdb --if-exists "$DB" >/dev/null; fi
  rm -rf "$TMP"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! command -v psql >/dev/null || ! command -v createdb >/dev/null || ! command -v dropdb >/dev/null; then
  printf 'BLOQUÉ: psql, createdb et dropdb sont requis.\n' >&2
  exit 2
fi

# Inspect the server actually reached. Accept loopback TCP or a local socket;
# reject remote PostgreSQL before creating the disposable database.
ADDR="$(psql -X -d postgres -Atqc "select coalesce(inet_server_addr()::text, 'local-socket')" 2>/dev/null)" || {
  printf 'BLOQUÉ: connexion locale à la base postgres impossible.\n' >&2
  exit 2
}
case "$ADDR" in
  local-socket|127.*|::1) ;;
  *) printf 'BLOQUÉ: serveur PostgreSQL non local (%s).\n' "$ADDR" >&2; exit 2 ;;
esac

createdb --maintenance-db=postgres "$DB" || {
  printf 'BLOQUÉ: création de la base jetable impossible.\n' >&2
  exit 2
}
CREATED=1

run_sql() {
  psql -X -d "$DB" -v ON_ERROR_STOP=1 -f "$1"
}

printf 'Base jetable locale: %s\n' "$DB"
if ! run_sql "$TESTS/stub_auth.sql" >"$TMP/stub.log" 2>&1; then
  printf 'MIGRATIONS | RED | stub_auth.sql\n'
  tail -n 25 "$TMP/stub.log"
  exit 1
fi
for migration in "$MIGRATIONS"/*.sql; do
  if ! run_sql "$migration" >"$TMP/migration.log" 2>&1; then
    printf 'MIGRATIONS | RED | %s\n' "${migration##*/}"
    tail -n 25 "$TMP/migration.log"
    exit 1
  fi
done
if [[ -f "$TESTS/disable_guard.sql" ]]; then
  if ! run_sql "$TESTS/disable_guard.sql" >"$TMP/disable_guard.log" 2>&1; then
    printf 'PRÉPARATION | RED | disable_guard.sql\n'
    tail -n 25 "$TMP/disable_guard.log"
    exit 1
  fi
fi
printf 'MIGRATIONS | GREEN | stub_auth + %s migrations\n' "$(find "$MIGRATIONS" -maxdepth 1 -name '*.sql' | wc -l | tr -d ' ')"

# Keep the CI order where fixtures/audit-chain assertions depend on it, then
# add every scenario not already listed. The glob addition is exhaustive.
preferred=(
  scenarios_etape3.sql scenarios_etape4.sql scenarios_etape5.sql
  scenarios_adm05.sql scenarios_n2.sql scenarios_n4.sql scenarios_n5.sql
  scenarios_ctr01.sql scenarios_agt01.sql scenarios_hook_jeton.sql
  scenarios_r2.sql scenarios_adm04.sql scenarios_b18_security_definer.sql
)
declare -A seen=()
scenarios=()
for name in "${preferred[@]}"; do
  if [[ -f "$TESTS/$name" ]]; then scenarios+=("$TESTS/$name"); seen["$name"]=1; fi
done
for file in "$TESTS"/scenarios_*.sql; do
  [[ -f "$file" ]] || continue
  name="${file##*/}"
  if [[ -z "${seen[$name]+x}" ]]; then scenarios+=("$file"); seen["$name"]=1; fi
done

failed=0
red=0
missing=0
printf 'SCÉNARIO | STATUT\n'
for scenario in "${scenarios[@]}"; do
  name="${scenario##*/}"
  log="$TMP/$name.log"
  if run_sql "$scenario" >"$log" 2>&1; then
    printf '%s | GREEN\n' "$name"
  else
    printf '%s | RED\n' "$name"
    tail -n 25 "$log"
    failed=1
    red=$((red + 1))
  fi
done
# X2-14 found these files on fe253766 but absent from the ccr base used by
# this branch. Keep the gap visible until the canonical scenarios are merged.
expected=(
  scenarios_age_presentation.sql scenarios_agent_identity.sql
  scenarios_b03_invitations_foyer.sql scenarios_b07_profil_titulaire.sql
  scenarios_b08_progression_famille.sql scenarios_b09_notifications.sql
  scenarios_b10_support.sql scenarios_b11_feedback_questions.sql
  scenarios_b11_student_concern.sql scenarios_b13_admin_suspended.sql
  scenarios_b14_shared_state.sql scenarios_b15_assignations_annotations.sql
  scenarios_c04_teacher_title.sql scenarios_c11bis_f74_partition.sql
  scenarios_c20_demande_timeline.sql scenarios_offres_notifications.sql
  scenarios_offres_personnalisees.sql
)
for name in "${expected[@]}"; do
  if [[ ! -f "$TESTS/$name" ]]; then
    printf '%s | MISSING\n' "$name"
    failed=1
    red=$((red + 1))
    missing=$((missing + 1))
  fi
done
printf 'RÉSULTAT | %s exécuté(s), %s attendu(s) absent(s), %s rouge(s)\n' "${#scenarios[@]}" "$missing" "$red"
exit "$failed"
