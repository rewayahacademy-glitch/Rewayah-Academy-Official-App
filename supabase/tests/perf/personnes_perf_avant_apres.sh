#!/bin/bash
# PERSONNES-PERF : preuve « meme reponse, moins de travail » sur une base LOCALE jetable.
#
#   personnes_perf_avant_apres.sh <base_modele>
#
# <base_modele> : une base locale a l'etat de main SANS 20261130968000 ni 20261130968500 (stub_auth puis
# toutes les migrations precedentes). Le script cree deux copies jetables (pp_avant, pp_apres), y charge les
# donnees fictives (supabase/tests/fixtures/personnes_perf_volume.sql), installe les deux migrations dans
# pp_apres seulement, puis :
#   1. rejoue la batterie (personnes_perf_batterie.sql) dans les deux et compare les empreintes des reponses
#      (22 appels x 6 comptes) : elles doivent etre identiques ;
#   2. chronometre les lectures mesurees (6 appels chacune, meme connexion ; le premier compte la compilation).
# Il ne touche jamais une base distante : PGHOST doit etre une socket ou localhost.
set -euo pipefail
ICI="$(cd "$(dirname "$0")" && pwd)"
RACINE="$(cd "$ICI/../.." && pwd)"
MODELE="${1:?base modele locale attendue}"
case "${PGHOST:-/var/run/postgresql}" in
  /*|localhost|127.0.0.1) ;;
  *) echo "PGHOST n'est pas local : refuse" >&2; exit 2 ;;
esac
# Une seule base remplie, puis sa copie exacte : certains identifiants (messages, pieces) sont tires au hasard
# par leurs valeurs par defaut ; les deux bases portent ainsi les memes lignes, octet pour octet.
psql -qc "drop database if exists pp_avant"
psql -qc "drop database if exists pp_apres"
psql -qc "create database pp_avant template $MODELE"
psql -q -d pp_avant -f "$RACINE/tests/fixtures/personnes_perf_volume.sql" >/dev/null
psql -qc "create database pp_apres template pp_avant"
psql -q -v ON_ERROR_STOP=1 -1 -d pp_apres -f "$RACINE/migrations/20261130968000_personnes_perf.sql"
psql -q -v ON_ERROR_STOP=1 -1 -d pp_apres -f "$RACINE/migrations/20261130968500_personnes_perf_lectures.sql"
TMP="$(mktemp -d)"
psql -d pp_avant -f "$ICI/personnes_perf_batterie.sql" > "$TMP/avant.txt" 2>&1
psql -d pp_apres -f "$ICI/personnes_perf_batterie.sql" > "$TMP/apres.txt" 2>&1
if diff "$TMP/avant.txt" "$TMP/apres.txt"; then
  echo "REPONSES IDENTIQUES : $(wc -l < "$TMP/avant.txt") appels compares"
else
  echo "REPONSES DIFFERENTES" >&2; exit 1
fi
qui="SET ROLE authenticated; SELECT set_config('request.jwt.claims', '{\"sub\":\"9e900000-0000-4000-8000-0000000000d1\",\"role\":\"authenticated\",\"aal\":\"aal2\",\"app_metadata\":{\"role\":\"admin\"}}', false); SELECT set_config('request.jwt.claim.sub', '9e900000-0000-4000-8000-0000000000d1', false);"
chrono() {
  { echo "$qui"; echo '\timing on'; for _ in 1 2 3 4 5 6; do echo "select length(($2)::text);"; done; } \
    | psql -d "$1" -Atq 2>&1 | grep '^Time' | sed 's/Time: //; s/ ms.*//' | tr '\n' ' '
}
for appel in "public.com_lister_fils()" \
             "public.lister_candidatures('{}', 'activite', 1)" \
             "public.lister_candidatures('{\"etape\":\"verifications\"}', 'activite', 2)" \
             "(SELECT jsonb_agg(x) FROM public.comptes_admin_par_role() x)" \
             "(SELECT jsonb_agg(x) FROM public.dossiers_en_attente() x)"; do
  echo "$appel"
  echo "  avant (ms) : $(chrono pp_avant "$appel")"
  echo "  apres (ms) : $(chrono pp_apres "$appel")"
done
echo "public.com_non_lus_par_objet() (apres seulement)"
echo "  apres (ms) : $(chrono pp_apres "public.com_non_lus_par_objet()")"
psql -qc "drop database pp_avant"
psql -qc "drop database pp_apres"
rm -rf "$TMP"
