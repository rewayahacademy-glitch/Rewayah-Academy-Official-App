-- CAND-L1B, reprise R1 : la forme du compte candidat tient quand deux
-- transactions se croisent. Migration
-- 20261021220000_cand_l1b_forme_compte_candidat.sql.
--
-- Sans verrou, chaque cote lisait l'autre avant sa validation (ecriture
-- biaisee) : un rattachement de candidature et une activation, ou une
-- affectation, validaient tous les deux. Ici, deux sessions dblink jouent
-- chaque croisement dans les deux ordres ; la premiere tient sa transaction
-- ouverte, la seconde doit ATTENDRE (dblink_is_busy), puis etre refusee une
-- fois la premiere validee, et l'etat final doit respecter la forme.
--
-- Ce scenario VALIDE ses donnees (deux sessions doivent les voir) : a rejouer
-- sur une base NEUVE et jetable (stub_auth puis toutes les migrations ;
-- tool/rejouer_scenarios.sh en donne une a chaque scenario). Il retire a la
-- fin ce qu'il a pose, et l'extension dblink s'il l'a creee.
-- Contre-epreuve : sur une base sans la migration, ou avec les verrous
-- retires, la seconde session n'attend pas et passe ; le scenario echoue.

-- La connexion des deux sessions : la meme base, le meme serveur.
CREATE SCHEMA cand_l1b_concurrence;
DO $dblink$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'dblink') THEN
    CREATE EXTENSION dblink SCHEMA cand_l1b_concurrence;
    PERFORM pg_catalog.set_config('test.dblink_cree', 'oui', false);
  END IF;
END $dblink$;
SELECT pg_catalog.set_config('search_path', 'public, ' || n.nspname, false)
FROM pg_catalog.pg_extension e JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
WHERE e.extname = 'dblink';
SELECT pg_catalog.set_config('test.conninfo', pg_catalog.format('dbname=%s user=%s port=%s host=%s',
  pg_catalog.current_database(), current_user, pg_catalog.current_setting('port'),
  pg_catalog.split_part(pg_catalog.current_setting('unix_socket_directories'), ',', 1)), false);

-- Fixtures (donnees inventees) : quatre comptes candidats, un par croisement,
-- et la directrice qui clot les classes au nettoyage.
INSERT INTO auth.users (id, email) VALUES
 ('cb1c0000-0000-4000-8000-0000000000a1', 'cand-l1b-course-direction@test.invalid'),
 ('cb1c0000-0000-4000-8000-0000000000c1', 'cand-l1b-course-1@test.invalid'),
 ('cb1c0000-0000-4000-8000-0000000000c2', 'cand-l1b-course-2@test.invalid'),
 ('cb1c0000-0000-4000-8000-0000000000c3', 'cand-l1b-course-3@test.invalid'),
 ('cb1c0000-0000-4000-8000-0000000000c4', 'cand-l1b-course-4@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 ('cb1c0000-0000-4000-8000-0000000000a1', 'CL1C-ADM-0001', 'admin', 'Direction', 'Course', 'active', 'female'),
 ('cb1c0000-0000-4000-8000-0000000000c1', 'CL1C-ENS-0001', 'teacher', 'Course', 'Un', 'pending_kyc', 'female'),
 ('cb1c0000-0000-4000-8000-0000000000c2', 'CL1C-ENS-0002', 'teacher', 'Course', 'Deux', 'pending_kyc', 'female'),
 ('cb1c0000-0000-4000-8000-0000000000c3', 'CL1C-ENS-0003', 'teacher', 'Course', 'Trois', 'pending_kyc', 'female'),
 ('cb1c0000-0000-4000-8000-0000000000c4', 'CL1C-ENS-0004', 'teacher', 'Course', 'Quatre', 'pending_kyc', 'female');

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.rouge(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.rouges',
    coalesce(nullif(pg_catalog.current_setting('test.rouges', true), ''), '') || ' | ' || p_label, false);
  RAISE NOTICE 'ROUGE %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    PERFORM pg_temp.rouge(p_label);
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Un croisement : la session 1 ouvre sa transaction et ecrit ; la session 2
-- ecrit pendant ce temps. Rend vrai quand la seconde a attendu la premiere,
-- puis a ete refusee avec le SQLSTATE et le message attendus. La seconde
-- valide si elle passe (c'est ce que fait la base sans verrou).
CREATE FUNCTION pg_temp.croisement(p_label text, p_premier text, p_second text,
                                   p_code text, p_message text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_attend boolean;
  v_etat text;
  v_msg text;
BEGIN
  PERFORM dblink_connect('cand_l1b_t1', pg_catalog.current_setting('test.conninfo'));
  PERFORM dblink_connect('cand_l1b_t2', pg_catalog.current_setting('test.conninfo'));
  PERFORM dblink_exec('cand_l1b_t1', 'BEGIN');
  PERFORM dblink_exec('cand_l1b_t1', p_premier);
  PERFORM dblink_exec('cand_l1b_t2', 'BEGIN');
  PERFORM dblink_send_query('cand_l1b_t2', p_second);
  PERFORM pg_catalog.pg_sleep(0.5);
  v_attend := dblink_is_busy('cand_l1b_t2') = 1;
  PERFORM dblink_exec('cand_l1b_t1', 'COMMIT');
  BEGIN
    PERFORM * FROM dblink_get_result('cand_l1b_t2') AS t(r text);
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
  END;
  PERFORM * FROM dblink_get_result('cand_l1b_t2', false) AS t(r text);
  PERFORM dblink_exec('cand_l1b_t2', CASE WHEN v_etat IS NULL THEN 'COMMIT' ELSE 'ROLLBACK' END);
  PERFORM dblink_disconnect('cand_l1b_t1');
  PERFORM dblink_disconnect('cand_l1b_t2');
  PERFORM pg_temp.vrai(v_attend, p_label || ' : la seconde session attend la premiere');
  PERFORM pg_temp.vrai(v_etat = p_code AND v_msg = p_message,
    pg_catalog.format('%s : la seconde est refusee (%s %s)', p_label, coalesce(v_etat, 'aucun refus'),
                      coalesce(v_msg, '')));
END $$;

-- (1) activation, puis rattachement d'une candidature
SELECT pg_temp.croisement('activation puis candidature',
  $q$UPDATE public.profiles SET account_status = 'provisional_active'
      WHERE id = 'cb1c0000-0000-4000-8000-0000000000c1'$q$,
  $q$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
      VALUES ('enseignant', 'cb1c0000-0000-4000-8000-0000000000c1', 'female', 'Course Un',
              'prequalification', 'a_completer', 'lien_public')$q$,
  '23514', 'compte_candidat_actif_avant_salle_3');
-- (2) rattachement, puis activation
SELECT pg_temp.croisement('candidature puis activation',
  $q$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
      VALUES ('enseignant', 'cb1c0000-0000-4000-8000-0000000000c2', 'female', 'Course Deux',
              'prequalification', 'a_completer', 'lien_public')$q$,
  $q$UPDATE public.profiles SET account_status = 'provisional_active'
      WHERE id = 'cb1c0000-0000-4000-8000-0000000000c2'$q$,
  '23514', 'compte_candidat_actif_avant_salle_3');
-- (3) affectation (classe), puis rattachement
SELECT pg_temp.croisement('classe puis candidature',
  $q$INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
                                 timezone_iana, genre_public, etat)
      VALUES ('cb1c0000-0000-4000-8000-000000000103', 'cb1c0000-0000-4000-8000-0000000000c3', 'enfant', 5,
              'CL1C classe 3', 2, 9, 'Europe/Paris', 'femmes', 'active')$q$,
  $q$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
      VALUES ('enseignant', 'cb1c0000-0000-4000-8000-0000000000c3', 'female', 'Course Trois',
              'prequalification', 'a_completer', 'lien_public')$q$,
  '23514', 'compte_candidat_non_affectable');
-- (4) rattachement, puis affectation (classe)
SELECT pg_temp.croisement('candidature puis classe',
  $q$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
      VALUES ('enseignant', 'cb1c0000-0000-4000-8000-0000000000c4', 'female', 'Course Quatre',
              'prequalification', 'a_completer', 'lien_public')$q$,
  $q$INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
                                 timezone_iana, genre_public, etat)
      VALUES ('cb1c0000-0000-4000-8000-000000000104', 'cb1c0000-0000-4000-8000-0000000000c4', 'enfant', 5,
              'CL1C classe 4', 3, 9, 'Europe/Paris', 'femmes', 'active')$q$,
  '23514', 'compte_candidat_non_affectable');

-- L'etat valide apres les quatre croisements : la premiere ecriture reste,
-- la seconde n'a rien laisse.
SELECT pg_temp.vrai(
  (SELECT account_status FROM public.profiles WHERE id = 'cb1c0000-0000-4000-8000-0000000000c1') = 'provisional_active'
  AND NOT EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb1c0000-0000-4000-8000-0000000000c1')
  AND (SELECT account_status FROM public.profiles WHERE id = 'cb1c0000-0000-4000-8000-0000000000c2') = 'pending_kyc'
  AND EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb1c0000-0000-4000-8000-0000000000c2')
  AND EXISTS (SELECT 1 FROM public.groupes WHERE teacher_id = 'cb1c0000-0000-4000-8000-0000000000c3')
  AND NOT EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb1c0000-0000-4000-8000-0000000000c3')
  AND EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb1c0000-0000-4000-8000-0000000000c4')
  AND NOT EXISTS (SELECT 1 FROM public.groupes WHERE teacher_id = 'cb1c0000-0000-4000-8000-0000000000c4'),
  'etat valide : aucun compte candidat actif ni enseignant d''une classe');

-- Nettoyage : ce que le scenario a pose, dans l'ordre des cles (une classe
-- creee engendre ses seances).
DELETE FROM public.candidatures WHERE profile_id::text LIKE 'cb1c0000-%';
DELETE FROM public.sessions WHERE groupe_id IN (SELECT id FROM public.groupes WHERE teacher_id::text LIKE 'cb1c0000-%');
DELETE FROM public.groupes WHERE teacher_id::text LIKE 'cb1c0000-%';
DELETE FROM public.profiles WHERE id::text LIKE 'cb1c0000-%';
DELETE FROM auth.users WHERE id::text LIKE 'cb1c0000-%';
RESET search_path;
DO $retrait$
BEGIN
  IF pg_catalog.current_setting('test.dblink_cree', true) = 'oui' THEN
    DROP EXTENSION dblink;
  END IF;
END $retrait$;
DROP SCHEMA cand_l1b_concurrence;

DO $fin$
BEGIN
  IF coalesce(nullif(pg_catalog.current_setting('test.rouges', true), ''), '') <> '' THEN
    RAISE EXCEPTION 'CAND-L1B CONCURRENCE ROUGE : % controles verts ; rouges :%',
      coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0'),
      pg_catalog.current_setting('test.rouges');
  END IF;
  IF pg_catalog.current_setting('test.n')::int <> 9 THEN
    RAISE EXCEPTION 'CAND-L1B CONCURRENCE ROUGE : % controles executes, 9 attendus',
      pg_catalog.current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L1B concurrence : % controles verts', pg_catalog.current_setting('test.n');
END $fin$;
