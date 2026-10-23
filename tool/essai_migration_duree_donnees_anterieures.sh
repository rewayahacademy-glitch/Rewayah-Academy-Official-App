#!/usr/bin/env bash
# CLASSES-DUREE, suite (23/10/2026) : essaie la migration
# 20261023000000_classes_duree_bout_en_bout.sql sur des DONNEES ANTERIEURES.
#
# Les scenarios rejouent les migrations sur une base vide : l'alignement des
# seances a venir, que la migration lance une fois a l'application, n'y trouve
# rien a faire. Ce script monte la base AVANT cette migration, y pose des
# seances de 60 minutes d'une Classe d'adultes (l'ancienne materialisation les
# a faites ainsi), puis applique la migration :
#   cas 1 : sans chevauchement, la seance a venir passe a 90 minutes, la
#           passee, la commencee et celle des enfants gardent leur duree ;
#   cas 2 : avec une seance du meme enseignant qui commence a 19 h, la
#           migration S'ARRETE (nombre et identifiants dans le message) et
#           rien n'est ecrit ; le controle en lecture seule
#           tool/controle_avant_migration_duree.sql voit le meme conflit AVANT
#           (et ne rend rien dans le cas 1).
#
#   PGHOST=/tmp PGPORT=55432 PGUSER=postgres tool/essai_migration_duree_donnees_anterieures.sh
# Variable facultative : MIGRATION (chemin d'une variante, pour les mutations).
set -euo pipefail
export PGOPTIONS="${PGOPTIONS:-} -c client_min_messages=warning"
cd "$(dirname "$0")/.."
migration="${MIGRATION:-supabase/migrations/20261023000000_classes_duree_bout_en_bout.sql}"
base="duree_ant_$$"
psqlq=(psql -X -q -v ON_ERROR_STOP=1)
nettoyer() {
  for d in "${base}" "${base}_c2"; do
    "${psqlq[@]}" -d postgres -c "DROP DATABASE IF EXISTS ${d}" >/dev/null 2>&1 || true
  done
}
trap nettoyer EXIT

"${psqlq[@]}" -d postgres -c "CREATE DATABASE ${base}" >/dev/null
if ! "${psqlq[@]}" -d "$base" -f supabase/tests/stub_auth.sql >/dev/null 2>&1; then
  sed -E '/^create role /d' supabase/tests/stub_auth.sql | "${psqlq[@]}" -d "$base" >/dev/null
fi
for m in supabase/migrations/*.sql; do
  [[ "$m" == *20261023000000_classes_duree_bout_en_bout.sql ]] && continue
  "${psqlq[@]}" -d "$base" -f "$m" >/dev/null || { echo "MIGRATION EN ECHEC : $m" >&2; exit 1; }
done

"${psqlq[@]}" -d "$base" >/dev/null <<'SQL'
INSERT INTO auth.users (id, email) VALUES
  ('d0c10000-0000-4000-8000-000000000001', 'ant-ens1@example.test'),
  ('d0c10000-0000-4000-8000-000000000002', 'ant-ens2@example.test'),
  ('d0c10000-0000-4000-8000-000000000003', 'ant-ens3@example.test');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT id, 'ANT' || right(id::text, 8), 'teacher', 'Fixture', 'Ant', 'provisional_active', 'female'
  FROM auth.users WHERE id::text LIKE 'd0c10000%';
-- Classes actives (donnees anterieures) : l'ancienne materialisation fait des
-- seances de 60 minutes, pour les adultes comme pour les enfants.
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
  ('d0c10000-0000-4000-8000-0000000000a1', 'd0c10000-0000-4000-8000-000000000001', 'active', 'adulte', 6, 'Ant adultes', 3, 18, 'Europe/Paris'),
  ('d0c10000-0000-4000-8000-0000000000b1', 'd0c10000-0000-4000-8000-000000000002', 'active', 'enfant', 6, 'Ant enfants', 3, 18, 'Europe/Paris');
-- Une seance passee et une seance commencee de la Classe d'adultes (autre enseignant,
-- pour ne chevaucher aucune occurrence).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
  ('d0c10000-0000-4000-8000-0000000000e1', 'd0c10000-0000-4000-8000-000000000003', now() - interval '2 days', now() - interval '2 days' + interval '60 minutes', 'planned', 'd0c10000-0000-4000-8000-0000000000a1'),
  ('d0c10000-0000-4000-8000-0000000000e2', 'd0c10000-0000-4000-8000-000000000003', now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress', 'd0c10000-0000-4000-8000-0000000000a1');
SQL

durees() { "${psqlq[@]}" -At -d "$1" -c "SELECT coalesce(string_agg(round(extract(epoch FROM (s.ended_at - s.started_at)) / 60)::text, ',' ORDER BY s.started_at), '') FROM public.sessions s WHERE s.groupe_id = '$2'"; }

[[ "$(durees "$base" d0c10000-0000-4000-8000-0000000000a1)" == "60,60,60,60,60,60" ]] || { echo "ROUGE : la base d'essai devait avoir des seances d'adultes de 60 minutes" >&2; exit 1; }

# Cas 2 d'abord (copie de la base avant la migration) : un chevauchement arrete la migration.
"${psqlq[@]}" -d postgres -c "CREATE DATABASE ${base}_c2 TEMPLATE ${base}" >/dev/null
"${psqlq[@]}" -d "${base}_c2" >/dev/null <<'SQL'
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0c10000-0000-4000-8000-0000000000f1', 'd0c10000-0000-4000-8000-000000000001',
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '90 minutes', 'planned', NULL);
SQL
# Le controle en lecture seule (a lancer avant la migration) voit le meme conflit.
controle="$("${psqlq[@]}" -At -d "${base}_c2" -f tool/controle_avant_migration_duree.sql)"
grep -q 'd0c10000-0000-4000-8000-0000000000f1' <<<"$controle" && grep -q 'meme enseignant' <<<"$controle" \
  || { echo "ROUGE (cas 2) : le controle avant migration ne voit pas le conflit : $controle" >&2; exit 1; }
[[ "$(wc -l <<<"$controle")" == "1" ]] || { echo "ROUGE (cas 2) : le controle devait rendre une seule ligne : $controle" >&2; exit 1; }
if erreur="$("${psqlq[@]}" -d "${base}_c2" -f "$migration" 2>&1)"; then
  echo "ROUGE (cas 2) : la migration aurait du s'arreter sur un chevauchement" >&2; exit 1
fi
grep -q 'CLASSES-DUREE : 1 seance(s) a venir ne peuvent pas prendre la duree de leur Classe' <<<"$erreur" \
  && grep -q 'd0c10000-0000-4000-8000-0000000000f1' <<<"$erreur" \
  || { echo "ROUGE (cas 2) : message inattendu : $erreur" >&2; exit 1; }
[[ "$(durees "${base}_c2" d0c10000-0000-4000-8000-0000000000a1)" == "60,60,60,60,60,60" ]] \
  || { echo "ROUGE (cas 2) : la migration arretee a quand meme ecrit" >&2; exit 1; }
echo "cas 2 vert : la migration s'arrete sur un chevauchement (nombre et identifiants dans le message), rien n'est ecrit"

# Cas 1 : sans chevauchement, l'alignement se fait a l'application.
[[ -z "$("${psqlq[@]}" -At -d "$base" -f tool/controle_avant_migration_duree.sql)" ]] \
  || { echo "ROUGE (cas 1) : le controle avant migration devait ne rien rendre" >&2; exit 1; }
"${psqlq[@]}" -d "$base" -f "$migration" >/dev/null
[[ "$(durees "$base" d0c10000-0000-4000-8000-0000000000a1)" == "60,60,90,90,90,90" ]] \
  || { echo "ROUGE (cas 1) : durees des seances d'adultes : $(durees "$base" d0c10000-0000-4000-8000-0000000000a1) au lieu de 60,60,90,90,90,90" >&2; exit 1; }
# L'ordre est celui des debuts : la passee (60), la commencee (60), puis les quatre a venir (90).
[[ "$(durees "$base" d0c10000-0000-4000-8000-0000000000b1)" == "60,60,60,60" ]] \
  || { echo "ROUGE (cas 1) : les seances d'enfants ont change" >&2; exit 1; }
[[ "$("${psqlq[@]}" -At -d "$base" -c 'SELECT count(*) FROM app_private.seances_a_venir_a_realigner()')" == "0" ]] \
  || { echo "ROUGE (cas 1) : des seances a venir different encore" >&2; exit 1; }
echo "cas 1 vert : les quatre seances a venir d'adultes passent de 60 a 90 minutes ; la passee, la commencee et les seances d'enfants gardent 60"
