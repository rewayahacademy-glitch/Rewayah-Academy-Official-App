-- Defaut du 30/10/2026 : une Classe creee pendant son creneau n'apparaissait
-- ni sur « Aujourd'hui » ni sur « Classes ». Migration
-- 20261101100000_cours_du_moment_par_classe.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle) et annule tout.
--   (1) une Classe nee pendant son creneau n'a pas de seance pour le cours du
--       jour ; cours_du_moment_mes_classes la rend a l'enseignant : session_id
--       nul, debut a l'heure du creneau, cours en cours ;
--   (2) la lecture ne cree aucune seance ;
--   (3) l'eleve inscrit, le tuteur de son foyer et la direction la lisent ;
--       un tuteur etranger, un eleve d'ailleurs et un autre enseignant ne la
--       voient pas ;
--   (4) apres le concierge, la meme lecture rend l'identifiant de la seance ;
--   (5) droits : connecte oui, anonyme non ; STABLE ; SECURITY DEFINER,
--       search_path vide.
-- Chaque controle leve 'COURS-DU-MOMENT ROUGE : ...' s'il echoue.

\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object(
                                                   'role', p_role,
                                                   -- Le foyer, comme le pose le jeton reel.
                                                   'household_id', (SELECT pr.household_id FROM public.profiles pr
                                                                     WHERE pr.id = p_id)) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'COURS-DU-MOMENT ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un appel du concierge sous le role connecte, en tant que p_qui.
CREATE FUNCTION pg_temp.rejoindre(p_qui uuid, p_role text, p_classe uuid) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v uuid;
BEGIN
  PERFORM pg_temp.qui(p_qui, p_role);
  SET LOCAL ROLE authenticated;
  v := public.seance_a_rejoindre(p_classe);
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
  RETURN v;
END $$;

CREATE TEMP TABLE hc_t (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
CREATE TEMP TABLE hc_c (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
GRANT SELECT ON hc_t, hc_c TO authenticated;
CREATE FUNCTION pg_temp.t(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM hc_t WHERE code = p_code; $$;
CREATE FUNCTION pg_temp.c(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM hc_c WHERE code = p_code; $$;

-- Le jour ISO et l'heure de maintenant, a Paris (les cours du jour).
CREATE FUNCTION pg_temp.jour(p_decalage_jours int DEFAULT 0) RETURNS int
LANGUAGE sql STABLE AS $$
  SELECT extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + make_interval(days => p_decalage_jours))::int $$;
CREATE FUNCTION pg_temp.heure() RETURNS int
LANGUAGE sql STABLE AS $$ SELECT extract(hour FROM now() AT TIME ZONE 'Europe/Paris')::int $$;

CREATE FUNCTION pg_temp.classe(p_code text, p_teacher text, p_jour int, p_heure int) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
  VALUES (v_id, pg_temp.t(p_teacher), 'active', 'adulte', 6, 'Horloge ' || p_code, p_jour, p_heure,
          'Europe/Paris', 'indetermine');
  INSERT INTO hc_c VALUES (p_code, v_id);
  RETURN v_id;
END $$;

-- ------------------------------------------------------------------
-- Fixtures : deux foyers, une direction, un enseignant.
-- ------------------------------------------------------------------
INSERT INTO hc_t (code, id)
SELECT x.code, ('a0c20000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES ('admin', 1), ('tA', 10), ('tB', 11), ('xA', 50), ('xB', 51), ('gA', 70), ('gB', 71)) x(code, n);
INSERT INTO auth.users (id, email)
SELECT id, 'moment-' || lower(code) || '@example.test' FROM hc_t;
INSERT INTO public.households (id, timezone) VALUES
  ('a0c2b000-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('a0c2b000-0000-4000-8000-000000000002', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'MOMENT' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' WHEN t.code LIKE 'x%' THEN 'student'
             WHEN t.code LIKE 'g%' THEN 'guardian' ELSE 'teacher' END)::public.app_role,
       'Fixture', t.code,
       (CASE WHEN t.code LIKE 't%' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender,
       CASE WHEN t.code IN ('xA', 'gA') THEN 'a0c2b000-0000-4000-8000-000000000001'::uuid
            WHEN t.code IN ('xB', 'gB') THEN 'a0c2b000-0000-4000-8000-000000000002'::uuid END
  FROM hc_t t;
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
SELECT t.id, 'autonomous'::public.student_type, 'standard'::public.interface_mode
  FROM hc_t t WHERE t.code LIKE 'x%';
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT t.id, 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'
  FROM hc_t t WHERE t.code LIKE 't%';
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT t.id, d, h, 'Europe/Paris'
  FROM hc_t t CROSS JOIN generate_series(1, 7) d CROSS JOIN generate_series(0, 23) h
 WHERE t.code LIKE 't%';

-- La Classe nait pendant le cours du jour (debut a l'heure pile, il y a
-- moins de 60 minutes, le cours dure 90) : la materialisation saute ce cours.
SELECT pg_temp.classe('JOUR', 'tA', pg_temp.jour(0), pg_temp.heure());
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('JOUR'), pg_temp.t('xA'));
CREATE TEMP TABLE hc_debut ON COMMIT DROP AS
SELECT (date_trunc('hour', now() AT TIME ZONE 'Europe/Paris') AT TIME ZONE 'Europe/Paris') AS d;
GRANT SELECT ON hc_debut TO authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.sessions s, hc_debut
                                 WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = hc_debut.d),
  'fixture : la Classe n''a pas de seance pour le cours du jour');


-- La lecture sous le role connecte, en tant que p_qui.
CREATE TEMP TABLE cm_l (n int, groupe_id uuid, session_id uuid, debut timestamptz,
                        fin timestamptz, ouvre timestamptz, nb int) ON COMMIT DROP;
GRANT ALL ON cm_l TO authenticated;
CREATE FUNCTION pg_temp.lire(p_n int, p_qui uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_qui, p_role);
  SET LOCAL ROLE authenticated;
  INSERT INTO cm_l
  SELECT p_n, c.groupe_id, c.session_id, c.debut_utc, c.fin_prevue_utc, c.join_opens_at_utc, c.nb_membres
    FROM public.cours_du_moment_mes_classes() c;
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
END $$;
CREATE FUNCTION pg_temp.voit(p_n int) RETURNS boolean
LANGUAGE sql STABLE AS $$ SELECT EXISTS (SELECT 1 FROM cm_l WHERE n = p_n AND groupe_id = pg_temp.c('JOUR')) $$;

CREATE TEMP TABLE cm_avant ON COMMIT DROP AS SELECT count(*) AS n FROM public.sessions;
GRANT SELECT ON cm_avant TO authenticated;

-- (1) L'enseignant de la Classe lit le cours du jour, sans seance.
SELECT pg_temp.lire(1, pg_temp.t('tA'), 'teacher');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM cm_l WHERE n = 1 AND groupe_id = pg_temp.c('JOUR')) = 1
  AND (SELECT session_id IS NULL AND debut = (SELECT d FROM hc_debut)
              AND fin = debut + interval '90 minutes'
              AND ouvre <= now() AND debut <= now() AND fin > now() AND nb = 1
         FROM cm_l WHERE n = 1 AND groupe_id = pg_temp.c('JOUR')),
  '(1) classe creee pendant son creneau : l''enseignant lit le cours en cours, session_id nul');

-- (2) Aucune seance creee par la lecture.
SELECT pg_temp.vrai((SELECT count(*) FROM public.sessions) = (SELECT n FROM cm_avant),
  '(2) la lecture ne cree aucune seance');

-- (3) Les ayants droit, et eux seuls.
SELECT pg_temp.lire(2, pg_temp.t('xA'), 'student');
SELECT pg_temp.lire(3, pg_temp.t('gA'), 'guardian');
SELECT pg_temp.lire(4, pg_temp.t('admin'), 'admin');
SELECT pg_temp.lire(5, pg_temp.t('gB'), 'guardian');
SELECT pg_temp.lire(6, pg_temp.t('xB'), 'student');
SELECT pg_temp.lire(7, pg_temp.t('tB'), 'teacher');
SELECT pg_temp.vrai(pg_temp.voit(2) AND pg_temp.voit(3) AND pg_temp.voit(4),
  '(3) l''eleve inscrit, le tuteur de son foyer et la direction lisent le cours');
SELECT pg_temp.vrai(NOT pg_temp.voit(5) AND NOT pg_temp.voit(6) AND NOT pg_temp.voit(7),
  '(3) un tuteur etranger, un eleve d''ailleurs, un autre enseignant ne le voient pas');
SELECT pg_temp.vrai((SELECT count(*) FROM public.sessions) = (SELECT n FROM cm_avant),
  '(3) toujours aucune seance creee');

-- (4) Apres le concierge, la lecture rend la seance creee.
CREATE TEMP TABLE cm_r (id uuid) ON COMMIT DROP;
GRANT ALL ON cm_r TO authenticated;
INSERT INTO cm_r SELECT pg_temp.rejoindre(pg_temp.t('tA'), 'teacher', pg_temp.c('JOUR'));
SELECT pg_temp.lire(8, pg_temp.t('tA'), 'teacher');
SELECT pg_temp.vrai(
  (SELECT id FROM cm_r) IS NOT NULL
  AND (SELECT session_id FROM cm_l WHERE n = 8 AND groupe_id = pg_temp.c('JOUR')) = (SELECT id FROM cm_r)
  AND (SELECT debut FROM cm_l WHERE n = 8 AND groupe_id = pg_temp.c('JOUR')) = (SELECT d FROM hc_debut),
  '(4) apres le concierge, la lecture rend l''identifiant de la seance du jour');

-- (5) Droits.
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.cours_du_moment_mes_classes()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.cours_du_moment_mes_classes()', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""']
         FROM pg_proc p WHERE p.oid = 'public.cours_du_moment_mes_classes()'::regprocedure),
  '(5) connecte oui, anonyme non ; STABLE ; SECURITY DEFINER, search_path vide');

ROLLBACK;
