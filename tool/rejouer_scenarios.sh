#!/usr/bin/env bash
# Rejoue TOUS les scenarios SQL de supabase/tests, chacun sur une base neuve
# (passation du 17/10/2026, point 11 : la CI n'en rejouait que 15 sur 96).
#
#   tool/rejouer_scenarios.sh            # tous les scenarios
#   tool/rejouer_scenarios.sh fac_b      # ceux dont le nom contient « fac_b »
#
# Connexion par les variables habituelles de psql (PGHOST, PGPORT, PGUSER,
# PGPASSWORD). Une base modele est montee une fois (stub_auth.sql puis toutes
# les migrations, dans l'ordre) ; chaque scenario tourne sur une copie
# fraiche, puis la copie est supprimee. Sortie non nulle au premier rouge
# compte, avec la liste des scenarios rouges a la fin.
set -euo pipefail

cd "$(dirname "$0")/.."
filtre="${1:-}"
modele="scenarios_modele_$$"
psqlq=(psql -X -q -v ON_ERROR_STOP=1)

nettoyer() {
  "${psqlq[@]}" -d postgres -c "DROP DATABASE IF EXISTS ${modele}_copie" >/dev/null 2>&1 || true
  "${psqlq[@]}" -d postgres -c "DROP DATABASE IF EXISTS ${modele}" >/dev/null 2>&1 || true
}
trap nettoyer EXIT

"${psqlq[@]}" -d postgres -c "CREATE DATABASE ${modele}" >/dev/null
# Les roles (anon, authenticated...) sont communs au serveur : un second
# passage ne les recree pas.
if ! "${psqlq[@]}" -d "$modele" -f supabase/tests/stub_auth.sql >/dev/null 2>&1; then
  sed -E '/^create role /d' supabase/tests/stub_auth.sql \
    | "${psqlq[@]}" -d "$modele" >/dev/null
fi
for m in supabase/migrations/*.sql; do
  "${psqlq[@]}" -d "$modele" -f "$m" >/dev/null || {
    echo "MIGRATION EN ECHEC : $m" >&2
    exit 1
  }
done

verts=0
rouges=()
for s in supabase/tests/scenarios_*.sql; do
  [[ -n "$filtre" && "$s" != *"$filtre"* ]] && continue
  "${psqlq[@]}" -d postgres -c "DROP DATABASE IF EXISTS ${modele}_copie" >/dev/null
  "${psqlq[@]}" -d postgres -c "CREATE DATABASE ${modele}_copie TEMPLATE ${modele}" >/dev/null
  if "${psqlq[@]}" -d "${modele}_copie" -f "$s" >/tmp/scenario_$$.log 2>&1; then
    verts=$((verts + 1))
  else
    rouges+=("$(basename "$s")")
    echo "ROUGE : $(basename "$s")" >&2
    grep -E 'ERROR|ROUGE' /tmp/scenario_$$.log | head -3 >&2 || true
  fi
done
rm -f /tmp/scenario_$$.log

echo "Scenarios verts : $verts ; rouges : ${#rouges[@]}"
if ((${#rouges[@]} > 0)); then
  printf '  %s\n' "${rouges[@]}"
  exit 1
fi
