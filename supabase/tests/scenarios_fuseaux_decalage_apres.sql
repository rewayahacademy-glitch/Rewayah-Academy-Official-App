-- FUSEAUX-bis (garde-cap, 04/11/2026). Migration
-- 20261109900000_fuseaux_decalage_apres.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Aucune
-- fixture : la fonction ne lit que la table des fuseaux de Postgres.
--   (1) Paris en ete : decalage apres le 25/10 (+1 h), changement suivant le
--       28/03/2027 ;
--   (2) Paris en hiver : decalage apres le 28/03/2027 (+2 h), changement
--       suivant le 31/10/2027 ;
--   (3) Toronto : -4 h, puis -5 h apres le 01/11, changement suivant le
--       14/03/2027 ;
--   (4) fuseaux sans heure d'ete (Abidjan, Kolkata) : decalage_apres et
--       changement_suivant nuls ;
--   (5) les cles de la 20261109500000 sont inchangees ;
--   (6) droits inchanges : la fonction privee reste fermee aux clients ;
--   (7) public.mon_horloge() : le fuseau du foyer du tuteur, celui du profil
--       enseignant, nul pour un profil sans fuseau (jamais Paris invente) ;
--       un compte inconnu est refuse, anon n'a pas le droit d'execution.
-- Chaque controle leve 'FUSEAUX-BIS ROUGE : ...' s'il echoue.

\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'FUSEAUX-BIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.f(p_fuseau text, p_instant timestamptz) RETURNS jsonb
LANGUAGE sql STABLE AS $$ SELECT private.fuseau_info(p_fuseau, p_instant) $$;

-- (1) Paris en ete.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'decalage_apres')::int = 3600
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-03-28 01:00+00',
  '(1) Paris en ete : +1 h apres le 25/10, changement suivant le 28/03/2027 a 01:00 UTC');

-- (2) Paris en hiver.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2027-03-28 01:00+00'
  AND (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'decalage_apres')::int = 7200
  AND (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-10-31 01:00+00',
  '(2) Paris en hiver : +2 h apres le 28/03/2027, changement suivant le 31/10/2027');

-- (3) Toronto.
SELECT pg_temp.vrai(
  (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = -14400
  AND (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'decalage_apres')::int = -18000
  AND (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-03-14 07:00+00',
  '(3) Toronto : -4 h, -5 h apres le 01/11, changement suivant le 14/03/2027 a 07:00 UTC');

-- (4) Sans heure d'ete.
SELECT pg_temp.vrai(
  pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ? 'decalage_apres'
  AND pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ->> 'decalage_apres' IS NULL
  AND pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ->> 'changement_suivant' IS NULL
  AND pg_temp.f('Asia/Kolkata', '2026-10-01 12:00+00') ->> 'decalage_apres' IS NULL
  AND (pg_temp.f('Asia/Kolkata', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 19800,
  '(4) Abidjan et Kolkata : aucune heure d''ete, decalage_apres et changement_suivant nuls');

-- (5) Les cles d'avant, inchangees.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'fuseau') = 'Europe/Paris'
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 7200
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2026-10-25 01:00+00'
  AND private.fuseau_info('') IS NULL AND private.fuseau_info(NULL) IS NULL
  AND private.fuseau_info('Mars/Olympus') IS NULL,
  '(5) fuseau, decalage et prochain changement inchanges ; vide, nul ou inconnu : objet nul');

-- (6) Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.fuseau_info(text,timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.fuseau_info(text,timestamptz)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.horloge_interlocuteurs(uuid)', 'EXECUTE'),
  '(6) la fonction privee reste fermee ; horloge_interlocuteurs reste ouverte aux connectes');

-- (7) public.mon_horloge().
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated',
                       'app_metadata', pg_catalog.json_build_object(
                         'role', p_role,
                         'household_id', (SELECT pr.household_id FROM public.profiles pr WHERE pr.id = p_id)))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE TEMP TABLE fb_r (n text PRIMARY KEY, v jsonb) ON COMMIT DROP;
GRANT ALL ON fb_r TO authenticated;
CREATE FUNCTION pg_temp.mien(p_n text, p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  SET LOCAL ROLE authenticated;
  INSERT INTO fb_r VALUES (p_n, public.mon_horloge());
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
END $$;

INSERT INTO auth.users (id, email) VALUES
  ('f0b50000-0000-4000-8000-000000000001', 'fuseaux-bis-g@example.test'),
  ('f0b50000-0000-4000-8000-000000000002', 'fuseaux-bis-t@example.test'),
  ('f0b50000-0000-4000-8000-000000000003', 'fuseaux-bis-v@example.test'),
  ('f0b50000-0000-4000-8000-000000000004', 'fuseaux-bis-a@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('f0b5b000-0000-4000-8000-000000000001', 'America/Toronto');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id) VALUES
  ('f0b50000-0000-4000-8000-000000000001', 'FUSEAUXBIS01', 'guardian', 'Fixture', 'g', 'active', 'female', 'f0b5b000-0000-4000-8000-000000000001'),
  ('f0b50000-0000-4000-8000-000000000002', 'FUSEAUXBIS02', 'teacher', 'Fixture', 't', 'provisional_active', 'female', NULL),
  ('f0b50000-0000-4000-8000-000000000003', 'FUSEAUXBIS03', 'teacher', 'Fixture', 'v', 'provisional_active', 'female', NULL),
  ('f0b50000-0000-4000-8000-000000000004', 'FUSEAUXBIS04', 'admin', 'Fixture', 'a', 'active', 'female', NULL);
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana) VALUES
  ('f0b50000-0000-4000-8000-000000000002', 'CI', ARRAY['francais'], 40, 'approved', 'Africa/Abidjan'),
  ('f0b50000-0000-4000-8000-000000000003', 'FR', ARRAY['francais'], 40, 'approved', '');

SELECT pg_temp.mien('g', 'f0b50000-0000-4000-8000-000000000001', 'guardian');
SELECT pg_temp.mien('t', 'f0b50000-0000-4000-8000-000000000002', 'teacher');
SELECT pg_temp.mien('v', 'f0b50000-0000-4000-8000-000000000003', 'teacher');
SELECT pg_temp.mien('a', 'f0b50000-0000-4000-8000-000000000004', 'admin');
SELECT pg_temp.vrai(
  (SELECT v -> 'moi' ->> 'fuseau' FROM fb_r WHERE n = 'g') = 'America/Toronto'
  AND (SELECT v -> 'moi' ? 'decalage_apres' FROM fb_r WHERE n = 'g')
  AND (SELECT v ->> 'maintenant' FROM fb_r WHERE n = 'g') IS NOT NULL,
  '(7) le tuteur lit le fuseau de son foyer, avec ses changements d''heure');
SELECT pg_temp.vrai(
  (SELECT v -> 'moi' ->> 'fuseau' FROM fb_r WHERE n = 't') = 'Africa/Abidjan',
  '(7) l''enseignant lit le fuseau de son profil');
SELECT pg_temp.vrai(
  (SELECT v -> 'moi' = 'null'::jsonb FROM fb_r WHERE n = 'v')
  AND (SELECT v -> 'moi' = 'null'::jsonb FROM fb_r WHERE n = 'a')
  AND (SELECT v ->> 'maintenant' FROM fb_r WHERE n = 'a') IS NOT NULL,
  '(7) profil sans fuseau : moi nul, sans erreur, jamais Paris invente');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM fb_r WHERE v::text LIKE '%Fixture%' OR v::text LIKE '%FUSEAUXBIS%') = 0,
  '(7) aucune donnee de personne dans la reponse');
DO $refus$
BEGIN
  PERFORM pg_temp.qui('f0b50000-0000-4000-8000-0000000000ff', 'admin');
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.mon_horloge();
    RESET ROLE;
    RAISE EXCEPTION 'FUSEAUX-BIS ROUGE : (7) un compte inconnu lit une horloge';
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
  END;
  PERFORM pg_temp.qui(NULL, NULL);
END $refus$;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.mon_horloge()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.mon_horloge()', 'EXECUTE'),
  '(7) un compte inconnu est refuse ; anon n''a pas le droit d''execution');

ROLLBACK;
\o
\echo 'FUSEAUX-BIS : scenario vert'
