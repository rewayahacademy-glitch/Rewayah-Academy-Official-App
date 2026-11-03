#!/bin/bash
# A3-bis (03/11/2026) : deux entrees au meme instant, sur la base LOCALE.
#
# Prouve, avec deux connexions reelles, qu'un seul enseignant gagne l'entree
# d'une seance prise (verrou FOR UPDATE de autoriser_jeton_video) :
#   A : le titulaire demande son jeton et garde la transaction ouverte 4 s ;
#   B : une seconde apres, le remplacant pris demande le sien.
# Attendu : B attend la fin de A (au moins 2 s), puis est refuse
# (insufficient_privilege) ; l'enseignant effectif est le titulaire.
# Ecrit le resultat dans docs/current/captures/E2E/a3bis-remplacement/concurrence.txt.
# Base locale seulement (refus sinon). Usage : tool/e2e/a3bis_concurrence.sh
set -euo pipefail
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVAIL="${E2E_TRAVAIL:-/tmp/e2e-pile}"
DB=$(grep '^DB_URL=' "$TRAVAIL/statut.env" | cut -d'"' -f2)
case "$DB" in postgresql://*@127.0.0.1:*) ;; *) echo "refus : base non locale"; exit 1 ;; esac
SORTIE="$DEPOT/docs/current/captures/E2E/a3bis-remplacement/concurrence.txt"
q() { psql "$DB" -v ON_ERROR_STOP=1 -Atq "$@"; }

N=$(date +%s)
T=$(q -c "select gen_random_uuid()"); R=$(q -c "select gen_random_uuid()")
G=$(q -c "select gen_random_uuid()"); S=$(q -c "select gen_random_uuid()")
q <<SQL
begin;
insert into auth.users (id, email) values ('$T', 'e2e-a3bis-t-$N@example.com'), ('$R', 'e2e-a3bis-r-$N@example.com');
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) values
  ('$T', 'E2E-A3B-T-$N', 'teacher', 'E2E Titulaire', 'Concurrence', 'provisional_active', 'male'),
  ('$R', 'E2E-A3B-R-$N', 'teacher', 'E2E Remplacant', 'Concurrence', 'provisional_active', 'male');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
  values ('$G', '$T', 'enfant', 5, 'E2E A3bis concurrence $N',
          extract(isodow from (now() at time zone 'Europe/Paris') + interval '3 days')::int, 5, 'Europe/Paris', now() - interval '1 day');
insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
  values ('$S', '$T', now() - interval '10 minutes', now() + interval '35 minutes', 'planned', 'standard', '$G');
insert into public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
values ('$S', 'absence_declaree', '$T', null, '$T', gen_random_uuid(), 'auto', now() - interval '2 minutes'),
       ('$S', 'remplacement_pris', '$T', '$R', '$R', gen_random_uuid(), 'auto', now() - interval '1 minute');
commit;
SQL

TMP=$(mktemp -d)
(psql "$DB" -v ON_ERROR_STOP=1 -Atq > "$TMP/a.txt" 2>&1 <<SQL
begin;
select 'A jeton titulaire : ' || (public.autoriser_jeton_video('$S', '$T', 'wss://a.test', 'wss://b.test')->>'role');
select pg_sleep(4);
commit;
SQL
) &
PA=$!
sleep 1
DEBUT=$(date +%s.%N)
psql "$DB" -Atq > "$TMP/b.txt" 2>&1 <<SQL || true
select 'B jeton remplacant : ' || (public.autoriser_jeton_video('$S', '$R', 'wss://a.test', 'wss://b.test')->>'role');
SQL
FIN=$(date +%s.%N)
wait $PA
ATTENTE=$(python3 -c "print(round($FIN - $DEBUT, 2))")
EFFECTIF=$(q -c "select private.c29_enseignant_effectif_session('$S')")

{
  echo "A3-bis : deux entrees au meme instant ($(date -u +%FT%TZ)), base locale"
  echo "seance $S ; titulaire $T ; remplacant pris $R"
  cat "$TMP/a.txt"
  sed 's/^psql:[^:]*:[0-9]*: //' "$TMP/b.txt"
  echo "attente de B : ${ATTENTE} s"
  echo "enseignant effectif apres les deux demandes : $EFFECTIF"
} | tee "$SORTIE"

grep -q "A jeton titulaire : teacher" "$TMP/a.txt"
grep -q "non inscrit a cette seance" "$TMP/b.txt"
python3 -c "import sys; sys.exit(0 if $ATTENTE >= 2 else 1)"
[ "$EFFECTIF" = "$T" ]
echo "verdict : vert (un seul gagnant, B a attendu le verrou puis a ete refuse)" | tee -a "$SORTIE"
