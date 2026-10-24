-- Arbitrage du pilote (24/10/2026, nuit) : concierge (a) + tuteur.
-- Migration 20261025040000_horloge_classe_et_concierge_tuteur.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle) et annule tout.
--   - une Classe sans seance pour le cours du jour : horloge_classe rend
--     l'occurrence (session_id nul, fenetre ouverte) ;
--   - le tuteur du foyer d'un inscrit lit l'horloge et le concierge
--     l'accepte ; un tuteur etranger et un eleve d'ailleurs sont refuses ;
--   - deux appels (tuteur puis eleve) : une seule seance ; l'horloge rend
--     ensuite son identifiant ;
--   - la seance supprimee par la direction n'est jamais recreee, ni rendue
--     par l'horloge.
-- Chaque controle leve 'HORLOGE-CLASSE ROUGE : ...' s'il echoue.

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
    RAISE EXCEPTION 'HORLOGE-CLASSE ROUGE : %', p_label;
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

CREATE FUNCTION pg_temp.refuse(p_qui uuid, p_role text, p_classe uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.rejoindre(p_qui, p_role, p_classe);
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
    PERFORM pg_temp.qui(NULL, NULL);
    RETURN true;
  END;
  RETURN false;
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

-- L'horloge de la Classe sous le role connecte, en tant que p_qui.
CREATE TEMP TABLE hc_h (n int, session_id uuid, debut timestamptz, ouvre timestamptz,
                        fin timestamptz, heure_groupe text) ON COMMIT DROP;
GRANT ALL ON hc_h TO authenticated;
CREATE FUNCTION pg_temp.horloge(p_n int, p_qui uuid, p_role text, p_classe uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_qui, p_role);
  SET LOCAL ROLE authenticated;
  INSERT INTO hc_h
  SELECT p_n, h.session_id, h.debut_utc, h.join_opens_at_utc, h.fin_prevue_utc, h.heure_groupe
    FROM public.horloge_classe(p_classe) h;
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
END $$;
CREATE FUNCTION pg_temp.horloge_refusee(p_qui uuid, p_role text, p_classe uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.horloge(-1, p_qui, p_role, p_classe);
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
    PERFORM pg_temp.qui(NULL, NULL);
    RETURN true;
  END;
  RETURN false;
END $$;

-- ------------------------------------------------------------------
-- Fixtures : deux foyers, une direction, un enseignant.
-- ------------------------------------------------------------------
INSERT INTO hc_t (code, id)
SELECT x.code, ('a0c10000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES ('admin', 1), ('tA', 10), ('xA', 50), ('xB', 51), ('gA', 70), ('gB', 71)) x(code, n);
INSERT INTO auth.users (id, email)
SELECT id, 'horloge-' || lower(code) || '@example.test' FROM hc_t;
INSERT INTO public.households (id, timezone) VALUES
  ('a0c1b000-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('a0c1b000-0000-4000-8000-000000000002', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'HORLOGE' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' WHEN t.code LIKE 'x%' THEN 'student'
             WHEN t.code LIKE 'g%' THEN 'guardian' ELSE 'teacher' END)::public.app_role,
       'Fixture', t.code,
       (CASE WHEN t.code LIKE 't%' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender,
       CASE WHEN t.code IN ('xA', 'gA') THEN 'a0c1b000-0000-4000-8000-000000000001'::uuid
            WHEN t.code IN ('xB', 'gB') THEN 'a0c1b000-0000-4000-8000-000000000002'::uuid END
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

-- (1) L'horloge de la Classe rend l'occurrence du jour, sans seance.
SELECT pg_temp.horloge(1, pg_temp.t('xA'), 'student', pg_temp.c('JOUR'));
SELECT pg_temp.vrai(
  (SELECT count(*) FROM hc_h WHERE n = 1) = 1
  AND (SELECT session_id IS NULL AND debut = (SELECT d FROM hc_debut)
              AND ouvre = debut - interval '20 minutes' AND fin = debut + interval '90 minutes'
              AND ouvre <= now() AND fin > now()
         FROM hc_h WHERE n = 1),
  '(1) classe sans seance : l''horloge rend le cours du jour, fenetre ouverte, session_id nul');
SELECT pg_temp.horloge(2, pg_temp.t('tA'), 'teacher', pg_temp.c('JOUR'));
SELECT pg_temp.vrai((SELECT debut FROM hc_h WHERE n = 2) = (SELECT d FROM hc_debut),
  '(1) l''enseignant lit la meme horloge');

-- (2) Le tuteur du foyer lit l'horloge ; l'etranger et l'eleve d'ailleurs sont refuses.
SELECT pg_temp.horloge(3, pg_temp.t('gA'), 'guardian', pg_temp.c('JOUR'));
SELECT pg_temp.vrai((SELECT debut FROM hc_h WHERE n = 3) = (SELECT d FROM hc_debut),
  '(2) le tuteur du foyer d''un inscrit lit l''horloge');
SELECT pg_temp.vrai(pg_temp.horloge_refusee(pg_temp.t('gB'), 'guardian', pg_temp.c('JOUR')),
  '(2) un tuteur etranger est refuse (horloge)');
SELECT pg_temp.vrai(pg_temp.horloge_refusee(pg_temp.t('xB'), 'student', pg_temp.c('JOUR')),
  '(2) un eleve d''une autre famille est refuse (horloge)');

-- (3) Le concierge accepte le tuteur ; un second appel ne double rien.
CREATE TEMP TABLE hc_r (n int, id uuid) ON COMMIT DROP;
GRANT ALL ON hc_r TO authenticated;
INSERT INTO hc_r SELECT 1, pg_temp.rejoindre(pg_temp.t('gA'), 'guardian', pg_temp.c('JOUR'));
INSERT INTO hc_r SELECT 2, pg_temp.rejoindre(pg_temp.t('xA'), 'student', pg_temp.c('JOUR'));
SELECT pg_temp.vrai(
  (SELECT id FROM hc_r WHERE n = 1) IS NOT NULL
  AND (SELECT id FROM hc_r WHERE n = 1) = (SELECT id FROM hc_r WHERE n = 2),
  '(3) le tuteur du foyer est accepte ; l''eleve recoit la meme seance');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions s, hc_debut
    WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = hc_debut.d) = 1,
  '(3) pas de doublon : une seule seance pour le cours du jour');
SELECT pg_temp.vrai(pg_temp.refuse(pg_temp.t('gB'), 'guardian', pg_temp.c('JOUR')),
  '(3) un tuteur etranger est refuse (concierge)');
SELECT pg_temp.vrai(pg_temp.refuse(pg_temp.t('xB'), 'student', pg_temp.c('JOUR')),
  '(3) un eleve d''une autre famille est refuse (concierge)');

-- (4) L'horloge rend desormais l'identifiant de la seance creee.
SELECT pg_temp.horloge(4, pg_temp.t('gA'), 'guardian', pg_temp.c('JOUR'));
SELECT pg_temp.vrai((SELECT session_id FROM hc_h WHERE n = 4) = (SELECT id FROM hc_r WHERE n = 1),
  '(4) apres le concierge, l''horloge rend la seance du jour');

-- (5) Supprimee par la direction : jamais recreee, jamais rendue.
UPDATE public.sessions SET deleted_at = now() WHERE id = (SELECT id FROM hc_r WHERE n = 1);
SELECT pg_temp.vrai(pg_temp.rejoindre(pg_temp.t('xA'), 'student', pg_temp.c('JOUR')) IS NULL
  AND (SELECT count(*) FROM public.sessions s, hc_debut
        WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = hc_debut.d) = 1,
  '(5) la seance supprimee n''est pas recreee par le concierge');
SELECT pg_temp.horloge(5, pg_temp.t('xA'), 'student', pg_temp.c('JOUR'));
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM hc_h WHERE n = 5 AND debut = (SELECT d FROM hc_debut)),
  '(5) l''horloge ne rend plus l''occurrence supprimee');

-- (6) Droits.
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.horloge_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.horloge_classe(uuid)', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
         FROM pg_proc p WHERE p.oid = 'public.horloge_classe(uuid)'::regprocedure),
  '(6) horloge_classe : connecte oui, anonyme non ; SECURITY DEFINER, search_path vide');

ROLLBACK;
