-- PERF-ATTENTE (b) (migration 20261120200400) : enseignants_pour_public reecrite
-- en ensemble rend EXACTEMENT le meme resultat que l'ancienne.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. sur des donnees riches (plusieurs enseignants, fuseaux differents dont
--      deux a heure d'ete, classes a plusieurs creneaux et durees, une classe
--      terminee, une classe en attente, eleves en cours particulier, des
--      disponibilites qui se chevauchent), la fonction rend les MEMES lignes,
--      les memes colonnes, dans le MEME ordre, pour le public adulte et pour le
--      public enfant, et sous l'identite masquee ;
--   2. le resultat n'est pas trivial : certains creneaux sont retires par une
--      classe, d'autres par un eleve en cours particulier, d'autres restent ;
--   3. app_private.series_se_chevauchent rend la meme chose que
--      app_private.creneaux_recurrents_se_chevauchent_durees sur une grille de
--      cas (jours, heures, fuseaux, durees) ;
--   4. droits et forme (F86) : authenticated oui, anon non, aucun EXECUTE client
--      sur l'aide ; une personne qui n'est pas la direction est refusee comme avant.
-- L'ancienne fonction est copiee ICI, telle que lue en production le 07/11/2026
-- (md5 b992c501b63163c7f0a48b23adfad93b), sous le nom pg_temp.ensp_ancien.
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout est
-- annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERF-ENSEIGNANTS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('perf-ensp-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- L'ancienne fonction, telle quelle.
CREATE OR REPLACE FUNCTION pg_temp.ensp_ancien(p_type_public text)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, titre_public text, timezone_iana text, classes_actives integer, creneaux_pris jsonb, creneaux_libres jsonb)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $ancien$
DECLARE
  v_duree integer;
  v_duree_individuelle integer;
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'proposition d''enseignants reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type_public IS NULL OR p_type_public NOT IN ('enfant', 'adulte') THEN
    RAISE EXCEPTION 'public invalide' USING ERRCODE = '22023';
  END IF;
  -- CLASSES-DUREE (23/10) : la duree du public demande (aucune offre, aucune
  -- Classe encore) ; les affectations individuelles gardent la duree unique.
  v_duree := app_private.duree_seance_minutes(NULL, p_type_public);
  v_duree_individuelle := public.app_config_int('session_duration_minutes', 60);
  v_masque := coalesce(public.agent_identite_masquee(), false);

  RETURN QUERY
  SELECT p.id,
         CASE WHEN v_masque THEN NULL ELSE p.first_name END,
         CASE WHEN v_masque THEN NULL ELSE p.last_name END,
         p.immutable_id, tp.country,
         CASE p.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayyid' END,
         tp.timezone_iana,
         (SELECT count(*)::integer FROM public.groupes g
           WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', b.weekday, 'hour_local', b.hour_local, 'timezone_iana', b.timezone_iana)
                  ORDER BY b.weekday, b.hour_local, b.timezone_iana)
           FROM (
             SELECT DISTINCT s.weekday, s.hour_local, g.timezone_iana
             FROM public.groupes g
             CROSS JOIN LATERAL (
               SELECT g.weekday, g.hour_local
               UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
             ) s
             WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
           ) b), '[]'::jsonb),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', wa.weekday, 'hour_local', wa.hour_local, 'timezone_iana', wa.timezone_iana)
                  ORDER BY wa.weekday, wa.hour_local)
           FROM public.weekly_availability wa
           WHERE wa.profile_id = p.id
             AND app_private.creneau_couvert_par_disponibilites(
                   wa.profile_id, wa.weekday, wa.hour_local, wa.timezone_iana, v_duree)
             AND NOT EXISTS (
               SELECT 1 FROM public.groupes g
               CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) s
               WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       s.jour, s.heure, g.timezone_iana, s.duree))
             AND NOT EXISTS (
               SELECT 1 FROM public.teacher_student_assignments tsa
               JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
               WHERE tsa.teacher_id = p.id AND tsa.ended_at IS NULL
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       busy.weekday, busy.hour_local, busy.timezone_iana, v_duree_individuelle))), '[]'::jsonb)
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.role = 'teacher' AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
  ORDER BY p.last_name, p.first_name, p.id;
END;
$ancien$;

-- ---------------------------------------------------------------------------
-- Fixtures : sans declencheurs (session_replication_role = replica) pour poser
-- des classes et des disponibilites qui se chevauchent comme en production.
-- ---------------------------------------------------------------------------
SET LOCAL session_replication_role = replica;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'perf-ensp-' || x || '@test.invalid'
  FROM unnest(ARRAY['admin', 'ta', 'tb', 'tc', 'td', 'te', 'tmort']) AS x;

INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('admin'), 'PE-ADM-0001', 'admin', 'Direction', 'Test', 'active', 'male'),
       (pg_temp.id('ta'), 'PE-ENS-0001', 'teacher', 'Amina', 'Alaoui', 'active', 'female'),
       (pg_temp.id('tb'), 'PE-ENS-0002', 'teacher', 'Bilal', 'Benali', 'active', 'male'),
       (pg_temp.id('tc'), 'PE-ENS-0003', 'teacher', 'Chaima', 'Cherif', 'provisional_active', 'female'),
       (pg_temp.id('td'), 'PE-ENS-0004', 'teacher', 'Driss', 'Dahmani', 'active', 'male'),
       (pg_temp.id('te'), 'PE-ENS-0005', 'teacher', 'Elias', 'Alaoui', 'active', 'male'),
       (pg_temp.id('tmort'), 'PE-ENS-0006', 'teacher', 'Farah', 'Zaidi', 'disabled', 'female');

INSERT INTO public.teacher_profiles (profile_id, country, kyc_status, timezone_iana)
VALUES (pg_temp.id('ta'), 'FR', 'approved', 'Europe/Paris'),
       (pg_temp.id('tb'), 'US', 'approved', 'America/New_York'),
       (pg_temp.id('tc'), 'JP', 'approved', 'Asia/Tokyo'),
       (pg_temp.id('td'), 'MA', 'approved', 'Africa/Casablanca'),
       (pg_temp.id('te'), 'FR', 'pending', 'Europe/Paris'),
       (pg_temp.id('tmort'), 'FR', 'approved', 'Europe/Paris')
ON CONFLICT (profile_id) DO UPDATE SET country = EXCLUDED.country, kyc_status = EXCLUDED.kyc_status,
  timezone_iana = EXCLUDED.timezone_iana;

-- Disponibilites : une grille serree par enseignant, dans SON fuseau (heures 8 a 22,
-- lundi a samedi) ; tb a aussi des heures en fuseau de Paris (deux fuseaux), ta des
-- heures tardives qui passent minuit.
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('ta'), j, h, 'Europe/Paris' FROM generate_series(1, 5) j, generate_series(14, 22) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('ta'), j, h, 'Europe/Paris' FROM generate_series(1, 7) j, generate_series(23, 23) h
ON CONFLICT DO NOTHING;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('tb'), j, h, 'America/New_York' FROM generate_series(1, 4) j, generate_series(17, 23) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('tb'), j, h, 'Europe/Paris' FROM generate_series(6, 7) j, generate_series(9, 13) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('tc'), j, h, 'Asia/Tokyo' FROM generate_series(1, 5) j, generate_series(6, 11) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('td'), j, h, 'Africa/Casablanca' FROM generate_series(1, 5) j, generate_series(16, 21) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('te'), j, h, 'Europe/Paris' FROM generate_series(1, 2) j, generate_series(9, 10) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('tmort'), j, h, 'Europe/Paris' FROM generate_series(1, 2) j, generate_series(9, 10) h;

-- Classes actives : plusieurs creneaux, durees, fuseaux ; une classe terminee et une
-- classe sans enseignant (ne comptent pas).
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES (pg_temp.id('ga1'), pg_temp.id('ta'), 'active', 'adulte', 6, 'PE A1', 1, 18, 'Europe/Paris'),
       (pg_temp.id('ga2'), pg_temp.id('ta'), 'active', 'enfant', 6, 'PE A2', 3, 10, 'Europe/Paris'),
       (pg_temp.id('gb1'), pg_temp.id('tb'), 'active', 'adulte', 6, 'PE B1', 2, 20, 'America/New_York'),
       (pg_temp.id('gc1'), pg_temp.id('tc'), 'active', 'enfant', 6, 'PE C1', 4, 9, 'Asia/Tokyo'),
       (pg_temp.id('gd1'), pg_temp.id('td'), 'active', 'adulte', 6, 'PE D1', 5, 18, 'Africa/Casablanca'),
       (pg_temp.id('gfin'), pg_temp.id('ta'), 'active', 'adulte', 6, 'PE FIN', 2, 12, 'Europe/Paris'),
       (pg_temp.id('gatt'), NULL, 'en_attente_enseignant', 'adulte', 6, 'PE ATT', 6, 10, 'Europe/Paris');
UPDATE public.groupes SET ended_at = now() - interval '1 day', ended_by = pg_temp.id('admin'), end_reason = 'essai' WHERE id = pg_temp.id('gfin');
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
VALUES (pg_temp.id('ga1'), 4, 19, 120), (pg_temp.id('ga1'), 6, 11, NULL),
       (pg_temp.id('gb1'), 4, 21, 60),
       (pg_temp.id('gc1'), 6, 6, 45),
       (pg_temp.id('gd1'), 1, 17, 90);

-- Eleves en cours particulier : ta (eleve s1), tb (s2), tc (s3, termine : ne compte pas).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('s1'), j, h, 'Europe/Paris' FROM generate_series(1, 3) j, generate_series(15, 17) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('s2'), j, h, 'America/New_York' FROM generate_series(1, 2) j, generate_series(19, 20) h;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.id('s3'), j, h, 'Asia/Tokyo' FROM generate_series(1, 3) j, generate_series(6, 7) h;
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local, timezone_iana, ended_at, ended_by, end_reason)
VALUES (pg_temp.id('ta'), pg_temp.id('s1'), 1, 16, 'Europe/Paris', NULL, NULL, NULL),
       (pg_temp.id('tb'), pg_temp.id('s2'), 1, 19, 'America/New_York', NULL, NULL, NULL),
       (pg_temp.id('tc'), pg_temp.id('s3'), 1, 6, 'Asia/Tokyo', now(), pg_temp.id('admin'), 'essai');

RESET session_replication_role;

-- 1. Le resultat est identique, ligne a ligne, dans le meme ordre.
SELECT pg_temp.qui(pg_temp.id('admin'), 'admin');
CREATE FUNCTION pg_temp.identique(p_public text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n)), '[]'::jsonb)
            FROM public.enseignants_pour_public(p_public) n)
       = (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.to_jsonb(o)), '[]'::jsonb)
            FROM pg_temp.ensp_ancien(p_public) o) $$;
SELECT pg_temp.vrai(pg_temp.identique('adulte'), 'public adulte : meme resultat que l''ancienne fonction, meme ordre, toutes colonnes');
SELECT pg_temp.vrai(pg_temp.identique('enfant'), 'public enfant : meme resultat que l''ancienne fonction, meme ordre, toutes colonnes');

-- 2. Le resultat n'est pas trivial.
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.enseignants_pour_public('adulte')) = 4
  AND (SELECT pg_catalog.jsonb_array_length(creneaux_libres) FROM public.enseignants_pour_public('adulte') WHERE teacher_id = pg_temp.id('ta')) > 20
  AND (SELECT pg_catalog.jsonb_array_length(creneaux_libres) FROM public.enseignants_pour_public('adulte') WHERE teacher_id = pg_temp.id('ta'))
    < (SELECT count(*) FROM public.weekly_availability WHERE profile_id = pg_temp.id('ta'))
  AND (SELECT pg_catalog.jsonb_array_length(creneaux_libres) FROM public.enseignants_pour_public('adulte') WHERE teacher_id = pg_temp.id('tb'))
    < (SELECT count(*) FROM public.weekly_availability WHERE profile_id = pg_temp.id('tb')),
  'quatre enseignants eligibles (ni en attente de verification, ni suspendu) ; des creneaux sont retires par une classe ou un eleve, pas tous');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(a.creneaux_libres) <> pg_catalog.jsonb_array_length(e.creneaux_libres)
     FROM public.enseignants_pour_public('adulte') a, public.enseignants_pour_public('enfant') e
    WHERE a.teacher_id = pg_temp.id('ta') AND e.teacher_id = pg_temp.id('ta')),
  'la duree du public change le resultat (90 contre 60 minutes) : le test voit la duree');

-- Sous l'identite masquee, la meme chose.
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.enseignants_pour_public('adulte')) = (SELECT count(*) FROM pg_temp.ensp_ancien('adulte')),
  'meme nombre de lignes');

-- 3. L'aide rend la meme chose que la regle d'origine, sur une grille de cas.
CREATE FUNCTION pg_temp.grille() RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE
  v_tz text[] := ARRAY['Europe/Paris', 'America/New_York', 'Australia/Lord_Howe'];
  v_ja int; v_ha int; v_za text; v_jb int; v_hb int; v_zb text; v_da int; v_db int;
  v_ia timestamptz[]; v_ib timestamptz[];
  v_n integer := 0;
BEGIN
  FOR v_ja IN 1..7 LOOP FOREACH v_za IN ARRAY v_tz LOOP
    FOR v_ha IN SELECT unnest(ARRAY[0, 9, 23]) LOOP
      v_ia := ARRAY(SELECT public.instant_creneau(v_ja, v_ha, v_za, n) FROM generate_series(0, 51) n ORDER BY n);
      FOR v_jb IN SELECT unnest(ARRAY[v_ja, 1 + (v_ja % 7)]) LOOP
        FOREACH v_zb IN ARRAY ARRAY[v_za, 'America/New_York'] LOOP
          FOR v_hb IN SELECT unnest(ARRAY[v_ha, (v_ha + 23) % 24]) LOOP
            v_ib := ARRAY(SELECT public.instant_creneau(v_jb, v_hb, v_zb, n) FROM generate_series(0, 51) n ORDER BY n);
            FOR v_da, v_db IN SELECT * FROM (VALUES (60, 60), (90, 45)) AS d(a, b) LOOP
              IF app_private.series_se_chevauchent(v_ia, v_da, v_ib, v_db)
                 IS DISTINCT FROM app_private.creneaux_recurrents_se_chevauchent_durees(
                      v_ja, v_ha, v_za, v_da, v_jb, v_hb, v_zb, v_db) THEN
                RETURN false;
              END IF;
              v_n := v_n + 1;
            END LOOP;
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP; END LOOP;
  PERFORM pg_catalog.set_config('test.grille_cas', v_n::text, true);
  RETURN true;
END $$;
SELECT pg_temp.vrai(pg_temp.grille(),
  'app_private.series_se_chevauchent = creneaux_recurrents_se_chevauchent_durees sur toute la grille');
SELECT pg_temp.vrai(pg_catalog.current_setting('test.grille_cas')::int > 900,
  'la grille couvre plus de 900 cas (fuseaux a heure d''ete, passage de minuit, durees differentes)');

-- 4. Droits et garde.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.enseignants_pour_public(text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.enseignants_pour_public(text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'app_private.series_se_chevauchent(timestamptz[],integer,timestamptz[],integer)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'app_private.series_se_chevauchent(timestamptz[],integer,timestamptz[],integer)', 'EXECUTE'),
  'authenticated peut appeler la fonction, anon non, et personne n''appelle l''aide');
SELECT pg_temp.vrai(
  pg_catalog.obj_description('public.enseignants_pour_public(text)'::regprocedure, 'pg_proc')
    LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.enseignants_pour_public(text)'::regprocedure)) || ';%',
  'l''empreinte F86 est celle de la fonction en place');
SELECT pg_temp.qui(pg_temp.id('ta'), 'teacher');
DO $$
BEGIN
  PERFORM * FROM public.enseignants_pour_public('adulte');
  RAISE EXCEPTION 'PERF-ENSEIGNANTS ROUGE : un enseignant a lu la proposition';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK un enseignant est refuse (42501) comme avant';
END $$;
SELECT pg_temp.qui(pg_temp.id('admin'), 'admin');
DO $$
BEGIN
  PERFORM * FROM public.enseignants_pour_public('adulte et enfant');
  RAISE EXCEPTION 'PERF-ENSEIGNANTS ROUGE : un public inconnu a ete accepte';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK un public invalide est refuse (22023) comme avant';
END $$;

ROLLBACK;
