#!/usr/bin/env bash
# PX-5 (20261130300000) : le plafond des ouvertures de dialogue (100 par 5 heures glissantes) tient EN APPELS PARALLELES.
# Le compteur est lu sous le verrou des envois de Praxis (pg_advisory_xact_lock('praxis-envois'), pose par praxis_ouvrir avant
# private.praxis_ouverture_refus) : deux sessions ne peuvent pas compter la meme place libre.
#
# L'essai : 95 ouvertures deja faites dans la fenetre, puis 20 sessions psql lancees en meme temps, chacune ouvre une conversation avec
# un candidat different. Attendu : exactement 5 passent, 15 sont refusees `plafond_ouvertures`, et la fenetre compte 100, pas plus.
#
# A NE LANCER QUE SUR UNE BASE JETABLE (stub_auth puis toutes les migrations) : l'essai VALIDE des donnees (il en faut pour que
# plusieurs sessions les voient). Usage : PGHOST=... PGPORT=... PGUSER=postgres BASE_JETABLE=nom_de_la_base ./concurrence_praxis_px5.sh
set -u
: "${BASE_JETABLE:?nommer la base jetable dans BASE_JETABLE}"
case "$BASE_JETABLE" in postgres|template0|template1) echo "refus : base systeme"; exit 2;; esac
B="$BASE_JETABLE"
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

psql -X -q -v ON_ERROR_STOP=1 -d "$B" >/dev/null <<'SQL' || exit 1
INSERT INTO auth.users (id, email) SELECT ('5c1c0000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'conc-' || n || '@test.invalid'
  FROM generate_series(1, 40) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('5c1c0000-0000-4000-8000-000000000001', 'CONC-ADM-1', 'admin', 'Direction', 'Essai', 'active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('5c1c0000-0000-4000-8000-000000000001');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('5c1c0000-0000-4000-8000-0000000000' || n)::uuid, 'CONC-CAN-' || n, 'teacher', 'Candidate' || n, 'Essai', 'pending_kyc', 'female'
  FROM generate_series(10, 29) n;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT ('5c1c0000-0000-4000-8000-0000000000' || n)::uuid, 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 29) n;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, recue_le, derniere_activite,
                                 majorite_declaree, majorite_attestee_le)
SELECT ('5c1ccccc-0000-4000-8000-0000000000' || n)::uuid, 'enseignant', ('5c1c0000-0000-4000-8000-0000000000' || n)::uuid, 'female',
       'Candidate' || n || ' Essai', 'prequalification', 'a_completer', 'en_cours', 'lien_public', now() - interval '20 days',
       now() - interval '10 days', true, now()
  FROM generate_series(10, 29) n;
-- La cle de Praxis, emise par la direction en aal2 ; Praxis allume, donnees reelles ouvertes.
SELECT set_config('request.jwt.claim.sub', '5c1c0000-0000-4000-8000-000000000001', false);
SELECT set_config('request.jwt.claims', '{"sub":"5c1c0000-0000-4000-8000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', false);
SET ROLE authenticated;
CREATE TEMP TABLE cle AS SELECT public.direction_praxis_emettre_cle('Essai concurrence', 'chat', now() + interval '1 day',
  '5c1c2222-0000-4000-8000-000000000001'::uuid) AS j;
SELECT public.direction_praxis_regler(true, false, NULL);
RESET ROLE;
UPDATE private.praxis_reglages SET donnees_reelles = true;
CREATE TABLE public.zz_conc_cle AS SELECT j ->> 'secret' AS secret FROM cle;
-- 95 ouvertures deja faites dans la fenetre (il y a 4 heures).
INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
SELECT gen_random_uuid(), 'question', gen_random_uuid(), gen_random_uuid(), k.id, k.emise_par, gen_random_uuid(), now() - interval '4 hours'
  FROM (SELECT id, emise_par FROM private.praxis_cles ORDER BY emise_le DESC LIMIT 1) k, generate_series(1, 95);
SQL
SECRET=$(psql -X -At -d "$B" -c "SELECT secret FROM public.zz_conc_cle")
psql -X -q -d "$B" -c "REVOKE ALL ON public.zz_conc_cle FROM PUBLIC" >/dev/null

DEPART=$(psql -X -At -d "$B" -c "SELECT extract(epoch FROM clock_timestamp() + interval '5 seconds')")
for n in $(seq 10 29); do
  REF=$(psql -X -At -d "$B" -c "SELECT reference FROM public.candidatures WHERE id = '5c1ccccc-0000-4000-8000-0000000000$n'")
  psql -X -q -At -d "$B" >"$DIR/$n.txt" 2>&1 <<SQL &
SELECT pg_sleep(greatest($DEPART - extract(epoch FROM clock_timestamp()), 0)) \\g /dev/null
SET ROLE service_role;
SELECT coalesce(r ->> 'erreur', CASE WHEN r ->> 'ok' = 'true' THEN 'ok' END)
  FROM (SELECT public.praxis_ouvrir('$SECRET', '$REF', 'question', 'Bonjour, une question de Praxis ?', gen_random_uuid()) AS r) x;
SQL
done
wait
OK=$(grep -lx ok "$DIR"/*.txt | wc -l)
PLAFOND=$(grep -lx plafond_ouvertures "$DIR"/*.txt | wc -l)
FENETRE=$(psql -X -At -d "$B" -c "SELECT count(*) FROM private.praxis_ouvertures WHERE raison <> 'felicitations' AND ouverte_le > now() - interval '5 hours'")
echo "sessions : 20 ; ok : $OK ; plafond_ouvertures : $PLAFOND ; ouvertures dans la fenetre : $FENETRE"
grep -hv -x -e ok -e plafond_ouvertures "$DIR"/*.txt | sed 's/^/autre : /'
if [ "$OK" = 5 ] && [ "$PLAFOND" = 15 ] && [ "$FENETRE" = 100 ]; then echo "VERT : le plafond tient en parallele"; else echo "ROUGE"; exit 1; fi
