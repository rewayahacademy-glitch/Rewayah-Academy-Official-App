-- FUSEAUX, partie serveur (garde-cap, 04/11/2026).
-- Migration 20261109500000_fuseaux_interlocuteurs.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle) et annule tout.
--   (1) le tuteur et l'eleve lisent l'enseignant : titre enregistre, prenom,
--       pays, fuseau de l'enseignant (Abidjan) et non celui de la classe ;
--       aucun fuseau de famille ;
--   (2) l'enseignant lit les fuseaux distincts des familles et leur nombre,
--       sans aucun nom ;
--   (3) la direction lit les deux ;
--   (4) en observation (session d'agent), le prenom est masque ;
--   (5) un remplacant pris sur la prochaine seance : la famille lit le
--       remplacant ; le remplacant lit les familles ;
--   (6) fuseau d'enseignant vide : le fuseau de la classe, source 'classe' ;
--   (7) refus : tuteur etranger, eleve d'une autre classe, enseignant
--       etranger, classe inconnue, compte inconnu ;
--   (8) changement d'heure : decalage et prochain changement exacts (Paris,
--       Toronto), aucun pour Abidjan, fuseau vide ou inconnu nul.
-- Chaque controle leve 'FUSEAUX ROUGE : ...' s'il echoue.

\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_agent uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', pg_catalog.json_build_object(
                         'role', p_role,
                         'household_id', (SELECT pr.household_id FROM public.profiles pr WHERE pr.id = p_id),
                         'agent_token_id', p_agent))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'FUSEAUX ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE TEMP TABLE fz_t (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
CREATE TEMP TABLE fz_c (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
GRANT SELECT ON fz_t, fz_c TO authenticated;
CREATE FUNCTION pg_temp.t(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM fz_t WHERE code = p_code; $$;
CREATE FUNCTION pg_temp.c(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM fz_c WHERE code = p_code; $$;

-- L'horloge des interlocuteurs sous le role connecte, en tant que p_code.
CREATE FUNCTION pg_temp.h(p_code text, p_role text, p_classe uuid, p_agent uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(pg_temp.t(p_code), p_role, p_agent);
  SET LOCAL ROLE authenticated;
  v := public.horloge_interlocuteurs(p_classe);
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refuse(p_code text, p_role text, p_classe uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.h(p_code, p_role, p_classe);
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
    PERFORM pg_temp.qui(NULL, NULL);
    RETURN true;
  END;
  RETURN false;
END $$;

-- ------------------------------------------------------------------
-- Fixtures : trois foyers d'une classe (deux a Paris, un a Abidjan), un
-- foyer etranger, une direction, quatre enseignants.
-- ------------------------------------------------------------------
INSERT INTO fz_t (code, id)
SELECT x.code, ('f0a50000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES ('admin', 1), ('tA', 10), ('tR', 11), ('tV', 12), ('tX', 13),
               ('xA', 50), ('xB', 51), ('xC', 52), ('xZ', 53), ('xD', 54),
               ('gA', 70), ('gZ', 73)) x(code, n);
INSERT INTO auth.users (id, email)
SELECT id, 'fuseaux-' || lower(code) || '@example.test' FROM fz_t;
INSERT INTO public.households (id, timezone) VALUES
  ('f0a5b000-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('f0a5b000-0000-4000-8000-000000000002', 'Europe/Paris'),
  ('f0a5b000-0000-4000-8000-000000000003', 'Africa/Abidjan'),
  ('f0a5b000-0000-4000-8000-000000000009', 'America/Toronto');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'FUSEAUX' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' WHEN t.code LIKE 'x%' THEN 'student'
             WHEN t.code LIKE 'g%' THEN 'guardian' ELSE 'teacher' END)::public.app_role,
       'Prenom' || t.code, 'Fixture',
       (CASE WHEN t.code LIKE 't%' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender,
       CASE WHEN t.code IN ('xA', 'xD', 'gA') THEN 'f0a5b000-0000-4000-8000-000000000001'::uuid
            WHEN t.code = 'xB' THEN 'f0a5b000-0000-4000-8000-000000000002'::uuid
            WHEN t.code = 'xC' THEN 'f0a5b000-0000-4000-8000-000000000003'::uuid
            WHEN t.code IN ('xZ', 'gZ') THEN 'f0a5b000-0000-4000-8000-000000000009'::uuid END
  FROM fz_t t;
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
SELECT t.id, 'autonomous'::public.student_type, 'standard'::public.interface_mode
  FROM fz_t t WHERE t.code LIKE 'x%';
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, titre)
SELECT t.id,
       CASE t.code WHEN 'tA' THEN 'CI' WHEN 'tR' THEN 'CA' ELSE 'FR' END,
       ARRAY['francais'], 40, 'approved',
       CASE t.code WHEN 'tA' THEN 'Africa/Abidjan' WHEN 'tR' THEN 'America/Toronto'
                   WHEN 'tV' THEN '' ELSE 'Europe/Paris' END,
       CASE t.code WHEN 'tA' THEN 'sayyid' WHEN 'tR' THEN 'sayyida' END
  FROM fz_t t WHERE t.code LIKE 't%';
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT t.id, d, h, 'Europe/Paris'
  FROM fz_t t CROSS JOIN generate_series(1, 7) d CROSS JOIN generate_series(0, 23) h
 WHERE t.code LIKE 't%';

CREATE FUNCTION pg_temp.classe(p_code text, p_teacher text, p_jour int, p_heure int) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
  VALUES (v_id, pg_temp.t(p_teacher), 'active', 'adulte', 6, 'Fuseaux ' || p_code, p_jour, p_heure,
          'Europe/Paris', 'indetermine');
  INSERT INTO fz_c VALUES (p_code, v_id);
  RETURN v_id;
END $$;

SELECT pg_temp.classe('CL1', 'tA', 2, 9);
SELECT pg_temp.classe('CL2', 'tV', 5, 17);
SELECT pg_temp.classe('CLZ', 'tX', 6, 11);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  (pg_temp.c('CL1'), pg_temp.t('xA')),
  (pg_temp.c('CL1'), pg_temp.t('xB')),
  (pg_temp.c('CL1'), pg_temp.t('xC')),
  (pg_temp.c('CL2'), pg_temp.t('xD')),
  (pg_temp.c('CLZ'), pg_temp.t('xZ'));

CREATE TEMP TABLE fz_r (n text PRIMARY KEY, v jsonb) ON COMMIT DROP;
GRANT ALL ON fz_r TO authenticated;
CREATE FUNCTION pg_temp.r(p_n text) RETURNS jsonb
LANGUAGE sql STABLE AS $$ SELECT v FROM fz_r WHERE n = p_n; $$;

-- (1) Le tuteur et l'eleve lisent l'enseignant de la classe.
INSERT INTO fz_r VALUES ('g1', pg_temp.h('gA', 'guardian', pg_temp.c('CL1')));
INSERT INTO fz_r VALUES ('x1', pg_temp.h('xA', 'student', pg_temp.c('CL1')));
SELECT pg_temp.vrai(
  pg_temp.r('g1') -> 'enseignant' ->> 'titre' = 'sayyid'
  AND pg_temp.r('g1') -> 'enseignant' ->> 'prenom' = 'PrenomtA'
  AND pg_temp.r('g1') -> 'enseignant' ->> 'pays' = 'CI'
  AND pg_temp.r('g1') -> 'enseignant' ->> 'fuseau' = 'Africa/Abidjan'
  AND (pg_temp.r('g1') -> 'enseignant' ->> 'decalage_secondes')::int = 0
  AND pg_temp.r('g1') -> 'enseignant' ->> 'source' = 'enseignant'
  AND (pg_temp.r('g1') -> 'enseignant' ->> 'remplacant')::boolean = false,
  '(1) le tuteur lit le titre enregistre, le prenom, le pays et le fuseau de l''enseignant (Abidjan)');
SELECT pg_temp.vrai(
  pg_temp.r('g1') -> 'moi' ->> 'fuseau' = 'Europe/Paris'
  AND pg_temp.r('g1') -> 'moi' ->> 'prochain_changement' IS NOT NULL
  AND pg_temp.r('g1') -> 'classe' ->> 'fuseau' = 'Europe/Paris'
  AND pg_temp.r('g1') -> 'maintenant' IS NOT NULL,
  '(1) le tuteur lit son propre fuseau (Paris, avec son prochain changement) et celui de la classe');
SELECT pg_temp.vrai(NOT (pg_temp.r('g1') ? 'familles') AND NOT (pg_temp.r('x1') ? 'familles'),
  '(1) ni le tuteur ni l''eleve ne lisent les fuseaux des familles');
SELECT pg_temp.vrai(pg_temp.r('x1') -> 'enseignant' ->> 'fuseau' = 'Africa/Abidjan',
  '(1) l''eleve lit le meme enseignant');

-- (2) L'enseignant lit les fuseaux des familles, sans aucun nom.
INSERT INTO fz_r VALUES ('t2', pg_temp.h('tA', 'teacher', pg_temp.c('CL1')));
SELECT pg_temp.vrai(
  jsonb_array_length(pg_temp.r('t2') -> 'familles') = 2
  AND pg_temp.r('t2') -> 'familles' -> 0 ->> 'fuseau' = 'Europe/Paris'
  AND (pg_temp.r('t2') -> 'familles' -> 0 ->> 'familles')::int = 2
  AND pg_temp.r('t2') -> 'familles' -> 1 ->> 'fuseau' = 'Africa/Abidjan'
  AND (pg_temp.r('t2') -> 'familles' -> 1 ->> 'familles')::int = 1,
  '(2) l''enseignant lit deux fuseaux : Paris (2 familles), Abidjan (1 famille)');
SELECT pg_temp.vrai(
  NOT (pg_temp.r('t2') ? 'enseignant')
  AND pg_temp.r('t2')::text NOT LIKE '%Prenom%'
  AND pg_temp.r('t2')::text NOT LIKE '%FUSEAUX%'
  AND pg_temp.r('t2') -> 'moi' ->> 'fuseau' = 'Africa/Abidjan',
  '(2) aucun nom ni identifiant dans la reponse de l''enseignant ; son fuseau est le sien');

-- (3) La direction lit les deux.
INSERT INTO fz_r VALUES ('a3', pg_temp.h('admin', 'admin', pg_temp.c('CL1')));
SELECT pg_temp.vrai(
  pg_temp.r('a3') -> 'enseignant' ->> 'prenom' = 'PrenomtA'
  AND jsonb_array_length(pg_temp.r('a3') -> 'familles') = 2,
  '(3) la direction lit l''enseignant et les fuseaux des familles');

-- (4) En observation, le prenom est masque (jeton d'agent sans ligne : masque).
INSERT INTO fz_r VALUES ('a4', pg_temp.h('admin', 'admin', pg_temp.c('CL1'), gen_random_uuid()));
SELECT pg_temp.vrai(
  pg_temp.r('a4') -> 'enseignant' ->> 'prenom' = (SELECT immutable_id FROM public.profiles WHERE id = pg_temp.t('tA'))
  AND pg_temp.r('a4')::text NOT LIKE '%PrenomtA%'
  AND pg_temp.r('a4') -> 'enseignant' ->> 'fuseau' = 'Africa/Abidjan',
  '(4) en observation, le prenom de l''enseignant est remplace par son identifiant');

-- (5) Un remplacant pris sur la prochaine seance.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('f0a5c000-0000-4000-8000-000000000001', pg_temp.t('tA'),
        now() + interval '10 minutes', now() + interval '70 minutes', 'planned', 'standard', pg_temp.c('CL1'));
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('f0a5c000-0000-4000-8000-000000000001', 'remplacement_pris',
        pg_temp.t('tA'), pg_temp.t('tR'), pg_temp.t('tR'), gen_random_uuid());
SELECT pg_temp.vrai(
  (SELECT s.id FROM public.sessions s
    WHERE s.groupe_id = pg_temp.c('CL1') AND s.deleted_at IS NULL
      AND s.status IN ('planned', 'preflight', 'in_progress')
      AND coalesce(s.ended_at, s.started_at + interval '1 hour') > now()
    ORDER BY s.started_at LIMIT 1) = 'f0a5c000-0000-4000-8000-000000000001',
  'fixture : la seance remplacee est la prochaine de la classe');
INSERT INTO fz_r VALUES ('g5', pg_temp.h('gA', 'guardian', pg_temp.c('CL1')));
SELECT pg_temp.vrai(
  pg_temp.r('g5') -> 'enseignant' ->> 'titre' = 'sayyida'
  AND pg_temp.r('g5') -> 'enseignant' ->> 'prenom' = 'PrenomtR'
  AND pg_temp.r('g5') -> 'enseignant' ->> 'pays' = 'CA'
  AND pg_temp.r('g5') -> 'enseignant' ->> 'fuseau' = 'America/Toronto'
  AND (pg_temp.r('g5') -> 'enseignant' ->> 'remplacant')::boolean = true,
  '(5) la famille lit le remplacant effectif (titre, prenom, pays, fuseau)');
INSERT INTO fz_r VALUES ('r5', pg_temp.h('tR', 'teacher', pg_temp.c('CL1')));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.r('r5') -> 'familles') = 2
                    AND NOT (pg_temp.r('r5') ? 'enseignant'),
  '(5) le remplacant lit les fuseaux des familles, sans nom');
INSERT INTO fz_r VALUES ('t5', pg_temp.h('tA', 'teacher', pg_temp.c('CL1')));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.r('t5') -> 'familles') = 2,
  '(5) le titulaire garde la lecture des fuseaux de sa classe');

-- (6) Fuseau d'enseignant vide : celui de la classe, source 'classe'.
INSERT INTO fz_r VALUES ('g6', pg_temp.h('gA', 'guardian', pg_temp.c('CL2')));
SELECT pg_temp.vrai(
  pg_temp.r('g6') -> 'enseignant' ->> 'source' = 'classe'
  AND pg_temp.r('g6') -> 'enseignant' ->> 'fuseau' = 'Europe/Paris'
  AND pg_temp.r('g6') -> 'enseignant' ->> 'titre' IS NULL,
  '(6) fuseau d''enseignant vide : le fuseau de la classe, source classe, titre nul (jamais deduit)');

-- (7) Refus.
SELECT pg_temp.vrai(pg_temp.refuse('gZ', 'guardian', pg_temp.c('CL1')), '(7) un tuteur etranger est refuse');
SELECT pg_temp.vrai(pg_temp.refuse('xB', 'student', pg_temp.c('CL2')), '(7) un eleve d''une autre classe est refuse');
SELECT pg_temp.vrai(pg_temp.refuse('tX', 'teacher', pg_temp.c('CL1')), '(7) un enseignant etranger est refuse');
SELECT pg_temp.vrai(pg_temp.refuse('gA', 'guardian', pg_temp.c('CLZ')), '(7) un tuteur hors de la classe est refuse');
SELECT pg_temp.vrai(pg_temp.refuse('admin', 'admin', gen_random_uuid()), '(7) une classe inconnue est refusee');
INSERT INTO fz_t VALUES ('inconnu', gen_random_uuid());
SELECT pg_temp.vrai(pg_temp.refuse('inconnu', 'admin', pg_temp.c('CL1')), '(7) un compte inconnu est refuse');
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.horloge_interlocuteurs(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.fuseau_info(text,timestamptz)', 'EXECUTE'),
  '(7) anon ne peut pas appeler l''horloge ; le calcul prive reste ferme');

-- (8) Changement d'heure.
SELECT pg_temp.vrai(
  (private.fuseau_info('Europe/Paris', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 7200
  AND (private.fuseau_info('Europe/Paris', '2026-10-01 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2026-10-25 01:00+00',
  '(8) Paris en ete : +2 h, passage a l''heure d''hiver le 25/10 a 01:00 UTC');
SELECT pg_temp.vrai(
  (private.fuseau_info('Europe/Paris', '2026-11-04 12:00+00') ->> 'decalage_secondes')::int = 3600
  AND (private.fuseau_info('Europe/Paris', '2026-11-04 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2027-03-28 01:00+00',
  '(8) Paris en hiver : +1 h, passage a l''heure d''ete le 28/03/2027 a 01:00 UTC');
SELECT pg_temp.vrai(
  (private.fuseau_info('America/Toronto', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = -14400
  AND (private.fuseau_info('America/Toronto', '2026-10-01 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2026-11-01 06:00+00',
  '(8) Toronto : -4 h, changement le 01/11 a 06:00 UTC (une semaine apres Paris)');
SELECT pg_temp.vrai(
  (private.fuseau_info('Asia/Kolkata', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 19800,
  '(8) decalage d''une demi-heure (Kolkata, +5 h 30)');
SELECT pg_temp.vrai(
  private.fuseau_info('Africa/Abidjan') ->> 'prochain_changement' IS NULL
  AND (private.fuseau_info('Africa/Abidjan') ->> 'decalage_secondes')::int = 0,
  '(8) Abidjan : aucun changement d''heure');
SELECT pg_temp.vrai(
  private.fuseau_info('') IS NULL AND private.fuseau_info(NULL) IS NULL
  AND private.fuseau_info('Mars/Olympus') IS NULL,
  '(8) fuseau vide, nul ou inconnu : objet nul');

ROLLBACK;
\o
\echo 'FUSEAUX : scenario vert'
