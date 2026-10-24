-- D3 (24/10/2026) : la cloture d'une classe annule ses seances futures, et
-- une nouvelle classe du meme enseignant au meme instant se cree ensuite.
-- Migration 20261024150000_cloture_annule_seances.sql.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations,
-- sous une direction active (role authenticated). Fixtures sans donnee
-- personnelle ; tout est annule a la fin. Chaque controle reussi ecrit une
-- ligne "D3 OK" ; un echec leve 'D3 ROUGE : ...' (ON_ERROR_STOP).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d3000000-0000-4000-8000-000000000001', 'd3-admin@example.test'),
  ('d3000000-0000-4000-8000-0000000000e1', 'd3-e1@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('d3000000-0000-4000-8000-000000000001', 'D3ADMIN000000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('d3000000-0000-4000-8000-0000000000e1', 'D3TEACHER00000E1', 'teacher',
   'Fixture', 'Enseignante', 'provisional_active', 'female', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('d3000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

SELECT set_config('request.jwt.claim.sub', 'd3000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'd3000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

DO $d3$
DECLARE
  v_premiere uuid;
  v_seconde uuid;
  v_prevues bigint;
BEGIN
  v_premiere := public.creer_groupe('d3000000-0000-4000-8000-0000000000e1', 'adulte',
    'D3 premiere', 2::smallint, 18::smallint, 6::smallint, NULL::text, NULL::smallint);

  SELECT pg_catalog.count(*) INTO v_prevues FROM public.sessions s
   WHERE s.groupe_id = v_premiere AND s.status = 'planned' AND s.deleted_at IS NULL;
  IF v_prevues = 0 THEN
    RAISE EXCEPTION 'D3 ROUGE : aucune seance materialisee pour la premiere classe';
  END IF;
  RAISE NOTICE 'D3 OK : % seances prevues materialisees', v_prevues;

  PERFORM public.cloturer_groupe(v_premiere, 'scenario D3');

  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.groupe_id = v_premiere AND s.status = 'planned'
                AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now()) THEN
    RAISE EXCEPTION 'D3 ROUGE : une seance future reste prevue apres la cloture';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.sessions s
       WHERE s.groupe_id = v_premiere AND s.status = 'canceled') <> v_prevues THEN
    RAISE EXCEPTION 'D3 ROUGE : les seances futures ne sont pas toutes annulees';
  END IF;
  RAISE NOTICE 'D3 OK : la cloture annule les seances futures';

  -- Le meme enseignant, le meme instant : la nouvelle classe se cree.
  v_seconde := public.creer_groupe('d3000000-0000-4000-8000-0000000000e1', 'adulte',
    'D3 seconde', 2::smallint, 18::smallint, 6::smallint, NULL::text, NULL::smallint);
  IF v_seconde IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.sessions s
        WHERE s.groupe_id = v_seconde AND s.status = 'planned' AND s.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'D3 ROUGE : la seconde classe n''a pas ses seances';
  END IF;
  RAISE NOTICE 'D3 OK : une classe au meme instant se cree apres la cloture';
END
$d3$;

ROLLBACK;
