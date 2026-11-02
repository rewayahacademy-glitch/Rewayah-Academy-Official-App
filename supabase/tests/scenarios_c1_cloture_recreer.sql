-- Lot C1 (02/11/2026) : cloturer une classe pendant sa seance, puis recreer
-- une classe au meme horaire avec le meme enseignant ; le refus de
-- chevauchement nomme la classe et l'heure.
-- Migration 20261105200000_c1_cloture_et_chevauchement_nomme.sql.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations,
-- sous une direction active (role authenticated). Fixtures sans donnee
-- personnelle ; tout est annule a la fin. Chaque controle reussi ecrit
-- "C1 OK" ; un echec leve 'C1 ROUGE : ...' (ON_ERROR_STOP).
--
-- L'heure de la nouvelle classe est la prochaine heure pleine en UTC : la
-- seance « en cours » de la classe close (debut il y a 5 minutes, fin deux
-- heures pleines plus tard) la couvre toujours, quelle que soit l'heure du
-- rejeu (aucun identifiant ni heure tires au hasard ne sont compares, T1).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c1000000-0000-4000-8000-000000000001', 'c1-admin@example.test'),
  ('c1000000-0000-4000-8000-0000000000e1', 'c1-e1@example.test'),
  ('c1000000-0000-4000-8000-0000000000e2', 'c1-e2@example.test'),
  ('c1000000-0000-4000-8000-0000000000e3', 'c1-e3@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('c1000000-0000-4000-8000-000000000001', 'C1ADMIN000000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('c1000000-0000-4000-8000-0000000000e1', 'C1TEACHER00000E1', 'teacher',
   'Fixture', 'Enseignante1', 'provisional_active', 'female', NULL),
  ('c1000000-0000-4000-8000-0000000000e2', 'C1TEACHER00000E2', 'teacher',
   'Fixture', 'Enseignante2', 'provisional_active', 'female', NULL),
  ('c1000000-0000-4000-8000-0000000000e3', 'C1TEACHER00000E3', 'teacher',
   'Fixture', 'Enseignante3', 'provisional_active', 'female', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('c1000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('c1000000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('c1000000-0000-4000-8000-0000000000e3', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- Une classe d'enfants en UTC, un seul creneau.
CREATE FUNCTION pg_temp.creer(p_teacher uuid, p_nom text, p_jour integer, p_heure integer)
RETURNS uuid LANGUAGE sql AS $$
  SELECT public.creer_classe_creneaux_admin(p_teacher, 'enfant', p_nom, 5::smallint, 'UTC',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('jour', p_jour, 'heure', p_heure)),
    'femmes', NULL::smallint);
$$;

-- La prochaine heure pleine, en UTC : jour ISO et heure.
CREATE FUNCTION pg_temp.prochaine() RETURNS TABLE (jour integer, heure integer)
LANGUAGE sql AS $$
  SELECT pg_catalog.date_part('isodow', h)::integer, pg_catalog.date_part('hour', h)::integer
    FROM (SELECT (pg_catalog.date_trunc('hour', pg_catalog.now() AT TIME ZONE 'UTC')
                  + interval '1 hour') AS h) x;
$$;

-- Une classe ancienne, dans trois jours : sa premiere seance est ramenee a
-- maintenant (debut il y a 5 minutes), comme si la direction la cloturait
-- pendant l'heure de sa seance. Rend l'identifiant de cette seance.
CREATE FUNCTION pg_temp.seance_en_cours(p_groupe uuid, p_statut text) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE
  v_s uuid;
BEGIN
  SELECT s.id INTO v_s FROM public.sessions s
   WHERE s.groupe_id = p_groupe AND s.status = 'planned' AND s.deleted_at IS NULL
   ORDER BY s.started_at LIMIT 1;
  UPDATE public.sessions
     SET started_at = pg_catalog.now() - interval '5 minutes',
         join_opens_at = pg_catalog.now() - interval '25 minutes',
         ended_at = pg_catalog.date_trunc('hour', pg_catalog.now()) + interval '2 hours'
   WHERE id = v_s;
  IF p_statut IN ('preflight', 'in_progress') THEN
    UPDATE public.sessions SET status = 'preflight' WHERE id = v_s;
  END IF;
  IF p_statut = 'in_progress' THEN
    UPDATE public.sessions SET status = 'in_progress' WHERE id = v_s;
  END IF;
  RETURN v_s;
END $$;

CREATE FUNCTION pg_temp.statut(p_s uuid) RETURNS text LANGUAGE sql AS $$
  SELECT s.status::text FROM public.sessions s WHERE s.id = p_s;
$$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated;

SELECT set_config('request.jwt.claim.sub', 'c1000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'c1000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

-- Les classes anciennes et leurs seances ramenees a maintenant.
CREATE TEMP TABLE c1_fixture (cle text PRIMARY KEY, groupe uuid, seance uuid);
GRANT ALL ON c1_fixture TO authenticated;

SET LOCAL ROLE authenticated;
INSERT INTO c1_fixture (cle, groupe)
SELECT x.cle, pg_temp.creer(x.t, x.nom,
         pg_catalog.date_part('isodow', pg_catalog.now() AT TIME ZONE 'UTC' + interval '3 days')::integer, 9)
  FROM (VALUES ('planned',     'c1000000-0000-4000-8000-0000000000e1'::uuid, 'C1 ancienne prevue'),
               ('preflight',   'c1000000-0000-4000-8000-0000000000e2'::uuid, 'C1 ancienne ouverte'),
               ('in_progress', 'c1000000-0000-4000-8000-0000000000e3'::uuid, 'C1 ancienne lancee')) x(cle, t, nom);
RESET ROLE;

UPDATE c1_fixture SET seance = pg_temp.seance_en_cours(groupe, cle);

SET LOCAL ROLE authenticated;

DO $c1$
DECLARE
  v_f record;
  v_p record;
  v_nouvelle uuid;
  v_msg text;
  v_detail text;
  v_json jsonb;
BEGIN
  SELECT * INTO v_p FROM pg_temp.prochaine();

  FOR v_f IN SELECT * FROM c1_fixture ORDER BY cle LOOP
    PERFORM public.cloturer_groupe(v_f.groupe, 'scenario C1');
  END LOOP;

  -- (1) FN-103 : la seance prevue de l'heure en cours est annulee.
  IF pg_temp.statut((SELECT seance FROM c1_fixture WHERE cle = 'planned')) <> 'canceled' THEN
    RAISE EXCEPTION 'C1 ROUGE : la seance prevue en cours reste % apres la cloture',
      pg_temp.statut((SELECT seance FROM c1_fixture WHERE cle = 'planned'));
  END IF;
  RAISE NOTICE 'C1 OK : (1) la seance prevue en cours est annulee par la cloture';

  -- (2) FN-103 : la seance ouverte (preflight) non lancee aussi.
  IF pg_temp.statut((SELECT seance FROM c1_fixture WHERE cle = 'preflight')) <> 'canceled' THEN
    RAISE EXCEPTION 'C1 ROUGE : la seance ouverte non lancee reste % apres la cloture',
      pg_temp.statut((SELECT seance FROM c1_fixture WHERE cle = 'preflight'));
  END IF;
  RAISE NOTICE 'C1 OK : (2) la seance ouverte non lancee est annulee par la cloture';

  -- (3) Le cas in_progress n'est pas touche (decision du directeur en attente).
  IF pg_temp.statut((SELECT seance FROM c1_fixture WHERE cle = 'in_progress')) <> 'in_progress' THEN
    RAISE EXCEPTION 'C1 ROUGE : la seance lancee a change de statut';
  END IF;
  RAISE NOTICE 'C1 OK : (3) la seance lancee reste in_progress';

  -- (4) Le meme enseignant, une classe a la prochaine heure pleine : acceptee.
  v_nouvelle := pg_temp.creer('c1000000-0000-4000-8000-0000000000e1', 'C1 recreee', v_p.jour, v_p.heure);
  IF NOT EXISTS (SELECT 1 FROM public.sessions s
                  WHERE s.groupe_id = v_nouvelle AND s.status = 'planned' AND s.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'C1 ROUGE : la classe recreee n''a pas ses seances';
  END IF;
  RAISE NOTICE 'C1 OK : (4) une classe au meme horaire, meme enseignant, est acceptee';

  -- (5) UX-020 : une seconde classe au meme creneau, meme enseignant : le
  -- refus nomme la classe et son horaire.
  BEGIN
    PERFORM pg_temp.creer('c1000000-0000-4000-8000-0000000000e1', 'C1 doublon', v_p.jour, v_p.heure);
    RAISE EXCEPTION 'C1 ROUGE : le doublon de creneau est accepte';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT, v_detail = PG_EXCEPTION_DETAIL;
    IF v_msg LIKE 'C1 ROUGE%' THEN RAISE; END IF;
  END;
  IF v_msg <> 'chevauchement avec une classe ou affectation active' THEN
    RAISE EXCEPTION 'C1 ROUGE : refus inattendu : %', v_msg;
  END IF;
  BEGIN
    v_json := v_detail::jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'C1 ROUGE : le refus ne nomme pas la classe (DETAIL : %)', coalesce(v_detail, 'vide');
  END;
  IF v_json ->> 'classe' IS DISTINCT FROM 'C1 recreee'
     OR (v_json ->> 'jour')::integer IS DISTINCT FROM v_p.jour
     OR (v_json ->> 'heure')::integer IS DISTINCT FROM v_p.heure
     OR v_json ->> 'fuseau' IS DISTINCT FROM 'UTC' THEN
    RAISE EXCEPTION 'C1 ROUGE : DETAIL incomplet : %', v_detail;
  END IF;
  RAISE NOTICE 'C1 OK : (5) le refus nomme la classe et son horaire';

  -- (6) La seance lancee de la classe close garde l'enseignante 3 : la
  -- nouvelle classe est refusee, et le refus nomme la classe et l'heure.
  v_msg := NULL; v_detail := NULL;
  BEGIN
    PERFORM pg_temp.creer('c1000000-0000-4000-8000-0000000000e3', 'C1 sur seance lancee', v_p.jour, v_p.heure);
    RAISE EXCEPTION 'C1 ROUGE : une classe sur une seance lancee est acceptee';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT, v_detail = PG_EXCEPTION_DETAIL;
    IF v_msg LIKE 'C1 ROUGE%' THEN RAISE; END IF;
  END;
  IF v_msg <> 'chevauchement avec une séance existante'
     OR v_detail NOT LIKE '%autre Classe%' THEN
    RAISE EXCEPTION 'C1 ROUGE : refus inattendu sur la seance lancee : % / %', v_msg, v_detail;
  END IF;
  BEGIN
    v_json := pg_catalog.substr(v_detail, pg_catalog.strpos(v_detail, '{'))::jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'C1 ROUGE : le refus sur la seance lancee ne la nomme pas (DETAIL : %)', v_detail;
  END;
  IF v_json ->> 'classe' IS DISTINCT FROM 'C1 ancienne lancee'
     OR v_json ->> 'fuseau' IS DISTINCT FROM 'UTC'
     OR v_json ->> 'date' IS NULL OR v_json ->> 'heure' IS NULL THEN
    RAISE EXCEPTION 'C1 ROUGE : DETAIL de seance incomplet : %', v_detail;
  END IF;
  RAISE NOTICE 'C1 OK : (6) la seance lancee bloque toujours, et le refus la nomme';
END
$c1$;

ROLLBACK;
