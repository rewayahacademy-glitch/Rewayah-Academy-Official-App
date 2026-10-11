#!/bin/sh
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TESTS="$ROOT/supabase/tests"
MIGRATIONS="$ROOT/supabase/migrations"
DB="rewayah_codex2_$$-$(date +%s)"
TMP=$(mktemp -d) || exit 2
CREATED=0

cleanup() {
  if [ "$CREATED" -eq 1 ]; then dropdb --if-exists "$DB" >/dev/null; fi
  rm -rf "$TMP"
}
trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM

if ! command -v psql >/dev/null 2>&1 || ! command -v createdb >/dev/null 2>&1 || ! command -v dropdb >/dev/null 2>&1; then
  printf 'BLOQUÉ: psql, createdb et dropdb sont requis.\n' >&2
  exit 2
fi

# Inspect the server actually reached; reject remote PostgreSQL before creating
# the disposable database. Local sockets and loopback TCP are accepted.
ADDR=$(psql -X -d postgres -Atqc "select coalesce(inet_server_addr()::text, 'local-socket')" 2>/dev/null) || {
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

migration_count=0
for migration in "$MIGRATIONS"/*.sql; do
  [ -f "$migration" ] || continue
  if ! run_sql "$migration" >"$TMP/migration.log" 2>&1; then
    printf 'MIGRATIONS | RED | %s\n' "${migration##*/}"
    tail -n 25 "$TMP/migration.log"
    exit 1
  fi
  migration_count=$((migration_count + 1))
done
if [ -f "$TESTS/disable_guard.sql" ]; then
  if ! run_sql "$TESTS/disable_guard.sql" >"$TMP/disable_guard.log" 2>&1; then
    printf 'PRÉPARATION | RED | disable_guard.sql\n'
    tail -n 25 "$TMP/disable_guard.log"
    exit 1
  fi
fi
printf 'MIGRATIONS | GREEN | stub_auth + %s migrations\n' "$migration_count"

# Preserve the CI order for scenarios whose fixtures depend on audit-chain
# history, then append every other scenarios_*.sql file in lexical order.
cat >"$TMP/preferred" <<'EOF'
scenarios_etape3.sql
scenarios_etape4.sql
scenarios_etape5.sql
scenarios_adm05.sql
scenarios_n2.sql
scenarios_n4.sql
scenarios_n5.sql
scenarios_ctr01.sql
scenarios_agt01.sql
scenarios_hook_jeton.sql
scenarios_r2.sql
scenarios_adm04.sql
scenarios_b18_security_definer.sql
EOF
: >"$TMP/seen"
: >"$TMP/scenarios"
while IFS= read -r name; do
  if [ -f "$TESTS/$name" ]; then
    printf '%s\n' "$name" >>"$TMP/scenarios"
    printf '%s\n' "$name" >>"$TMP/seen"
  fi
done <"$TMP/preferred"
for file in "$TESTS"/scenarios_*.sql; do
  [ -f "$file" ] || continue
  name=${file##*/}
  if ! grep -F -x "$name" "$TMP/seen" >/dev/null 2>&1; then
    printf '%s\n' "$name" >>"$TMP/scenarios"
    printf '%s\n' "$name" >>"$TMP/seen"
  fi
done

failed=0
red=0
missing=0
scenario_count=0
printf 'SCÉNARIO | STATUT\n'
while IFS= read -r scenario; do
  [ -n "$scenario" ] || continue
  scenario_count=$((scenario_count + 1))
  log="$TMP/$scenario.log"
  if run_sql "$TESTS/$scenario" >"$log" 2>&1; then
    printf '%s | GREEN\n' "$scenario"
  else
    printf '%s | RED\n' "$scenario"
    tail -n 25 "$log"
    failed=1
    red=$((red + 1))
  fi
done <"$TMP/scenarios"

# X2-14 found these files on fe253766 but absent from the ccr base used by this
# branch. Keep the coverage gap visible until the canonical scenarios arrive.
cat >"$TMP/expected" <<'EOF'
scenarios_age_presentation.sql
scenarios_agent_identity.sql
scenarios_b03_invitations_foyer.sql
scenarios_b07_profil_titulaire.sql
scenarios_b08_progression_famille.sql
scenarios_b09_notifications.sql
scenarios_b10_support.sql
scenarios_b11_feedback_questions.sql
scenarios_b11_student_concern.sql
scenarios_b13_admin_suspended.sql
scenarios_b14_shared_state.sql
scenarios_b15_assignations_annotations.sql
scenarios_c04_teacher_title.sql
scenarios_c11bis_f74_partition.sql
scenarios_c20_demande_timeline.sql
scenarios_offres_notifications.sql
scenarios_offres_personnalisees.sql
EOF
while IFS= read -r name; do
  if [ ! -f "$TESTS/$name" ]; then
    printf '%s | MISSING\n' "$name"
    failed=1
    red=$((red + 1))
    missing=$((missing + 1))
  fi
done <"$TMP/expected"
printf 'RÉSULTAT | %s exécuté(s), %s attendu(s) absent(s), %s rouge(s)\n' "$scenario_count" "$missing" "$red"
exit "$failed"
