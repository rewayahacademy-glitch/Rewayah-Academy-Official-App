-- CLASSES-DUREE, SUITE (23/10/2026) : la duree d'une Classe (90 minutes pour
-- les adultes, 60 pour les enfants) tient de bout en bout.
-- Migration 20261023000000_classes_duree_bout_en_bout.sql ; defauts :
-- CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md, 2.1 bis.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle), appelle les vraies
-- fonctions (materialiser_seances_groupe, modifier_groupe, groupe_creneaux sous
-- le role connecte, enseignants_pour_classe, enseignants_pour_public,
-- transferer_eleve, la paie), et annule tout a la fin.
--   (A) la duree des seances materialisees :
--       * une Classe d'adultes materialise des seances de 90 minutes, une Classe
--         d'enfants 60, une Classe nee d'une offre la duree de l'offre ;
--       * materialiser ne reecrit pas les seances deja materialisees ;
--       * les seances a venir non commencees sont alignees sur la duree de leur
--         Classe ; passees, commencees, en preparation, annulees, supprimees,
--         d'une Classe close : jamais touchees ; un raccourcissement passe ;
--       * un rallongement qui chevauche une autre seance du meme enseignant, d'un
--         remplacant ou d'un meme participant ARRETE tout, avec le nombre et les
--         identifiants, sans rien ecrire ; deux seances qui se touchent ne se
--         chevauchent pas ;
--   (B) deplacer une Classe qui a son enseignant repasse le predicat : refus pour
--       chaque raison, memes messages et meme SQLSTATE que l'affectation, rien
--       d'ecrit ni de materialise ; une Classe sans enseignant se deplace comme
--       avant ; groupe_creneaux ecrit par la direction sous le role connecte ;
--   (C) les creneaux libres comptent la duree de la Classe ou du public ;
--   (D) transferer_eleve compte la duree de la Classe cible ;
--   (E) la paie : sa base est la duree de la seance (constat, rien de change) ;
--   (F) droits et forme des fonctions (F86).
-- Chaque controle leve 'CLASSES-DUREE-BOUT ROUGE : ...' s'il echoue.
\o /dev/null
BEGIN;

-- La paie (E) lit la politique v2 : elle est mise en vigueur ce mois-ci
-- (comme scenarios_fac_e_paie_par_eleve.sql) ; tout est annule a la fin.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un appel doit etre refuse avec ce SQLSTATE et un message qui commence ainsi.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : % (%, « % » au lieu de %, « % »)',
        p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Les memes, sous le role connecte (le declencheur doit marcher pour un client,
-- pas seulement pour postgres).
CREATE FUNCTION pg_temp.client(p_sql text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  SET LOCAL ROLE authenticated;
  EXECUTE p_sql;
  RESET ROLE;
END $$;

CREATE FUNCTION pg_temp.refus_client(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.client(p_sql);
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : % (%, « % » au lieu de %, « % »)',
        p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RESET ROLE;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Les personnes et les classes se nomment par un code court.
CREATE TEMP TABLE dur_t (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
CREATE TEMP TABLE dur_c (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
GRANT SELECT ON dur_t, dur_c TO authenticated;
CREATE FUNCTION pg_temp.t(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM dur_t WHERE code = p_code; $$;
CREATE FUNCTION pg_temp.c(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM dur_c WHERE code = p_code; $$;

-- Une Classe active, avec son enseignant (le declencheur de 0055 materialise).
CREATE FUNCTION pg_temp.classe(p_code text, p_teacher text, p_public text, p_jour int, p_heure int,
                               p_offre uuid DEFAULT NULL, p_genre text DEFAULT 'indetermine',
                               p_tz text DEFAULT 'Europe/Paris', p_langue text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, offre_id, genre_public, langue_code)
  VALUES (v_id, pg_temp.t(p_teacher), 'active', p_public, 6, 'Bout ' || p_code, p_jour, p_heure, p_tz,
          p_offre, p_genre, p_langue);
  INSERT INTO dur_c VALUES (p_code, v_id);
  RETURN v_id;
END $$;

-- Une Classe qui attend son enseignant.
CREATE FUNCTION pg_temp.classe_attente(p_code text, p_public text, p_jour int, p_heure int,
                                       p_offre uuid DEFAULT NULL, p_langue text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, offre_id, genre_public, langue_code)
  VALUES (v_id, NULL, 'en_attente_enseignant', p_public, 6, 'Bout ' || p_code, p_jour, p_heure, 'Europe/Paris',
          p_offre, 'indetermine', p_langue);
  INSERT INTO dur_c VALUES (p_code, v_id);
  RETURN v_id;
END $$;

-- Ramene les seances A VENIR non commencees d'une Classe a 60 minutes : l'etat
-- qu'avait la base avant ce lot, quand le calendrier des adultes durait 60.
CREATE FUNCTION pg_temp.perime(p_code text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v_n integer;
BEGIN
  UPDATE public.sessions SET ended_at = started_at + interval '60 minutes'
   WHERE groupe_id = pg_temp.c(p_code) AND status = 'planned' AND deleted_at IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END $$;

-- Lance l'alignement (une Classe, ou toutes avec NULL) et rend le nombre de
-- seances ecrites. Dans une fonction VOLATILE a part : un controle de duree ne
-- doit pas se trouver dans la meme requete (un instantane ne voit pas ses ecritures).
CREATE FUNCTION pg_temp.aligne(p_code text) RETURNS integer
LANGUAGE plpgsql AS $$
BEGIN
  RETURN app_private.aligner_seances_a_venir_sur_la_classe(CASE WHEN p_code IS NULL THEN NULL ELSE pg_temp.c(p_code) END);
END $$;

-- La duree en minutes de chaque seance (non supprimee) d'une Classe, triee.
CREATE FUNCTION pg_temp.durees(p_code text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT coalesce(string_agg(round(extract(epoch FROM (s.ended_at - s.started_at)) / 60)::text, ',' ORDER BY s.started_at), '')
    FROM public.sessions s WHERE s.groupe_id = pg_temp.c(p_code) AND s.deleted_at IS NULL $$;

CREATE FUNCTION pg_temp.nb_seances(p_code text) RETURNS integer
LANGUAGE sql STABLE AS $$
  SELECT count(*)::integer FROM public.sessions s WHERE s.groupe_id = pg_temp.c(p_code) AND s.deleted_at IS NULL $$;

-- Un creneau libre se nomme « jour:heure ».
CREATE FUNCTION pg_temp.libres(p_json jsonb) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT coalesce(string_agg((e->>'weekday') || ':' || (e->>'hour_local'), ' ' ORDER BY (e->>'weekday')::int, (e->>'hour_local')::int), '')
    FROM jsonb_array_elements(p_json) e $$;

-- ------------------------------------------------------------------
-- Fixtures. Aucune donnee personnelle : des noms de fixture.
-- ------------------------------------------------------------------
INSERT INTO dur_t (code, id)
SELECT x.code, ('d0b20000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES
    ('admin', 1),
    ('tmat', 10), ('tali', 11), ('tali2', 12), ('tsolo', 13), ('tclos', 14),
    ('tcf1', 15), ('tcf2', 16), ('tcf2b', 17), ('tcf3', 18), ('trep', 19), ('tadj', 20),
    ('tpair', 21), ('tsh', 22),
    ('tmv', 23), ('tcap', 24), ('tkyc', 25), ('tgen', 26), ('ttz', 27), ('tdm', 28), ('tzz', 29),
    ('tlib', 30), ('tlib2', 31), ('tdm2', 38),
    ('ttr1', 32), ('ttr2', 33), ('ttr3', 34), ('ttr4', 35),
    ('tpay', 36), ('tpay2', 37),
    ('tph', 39), ('tph2', 40), ('tdl', 41),
    ('xmat', 50), ('xp', 51), ('xtr', 52), ('xpay', 53), ('xtsa', 54), ('xtsa2', 55)
  ) x(code, n);

INSERT INTO auth.users (id, email)
SELECT id, 'duree-bout-' || code || '@example.test' FROM dur_t;

INSERT INTO public.households (id, timezone) VALUES ('d0b2b000-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'DURBOUT' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' WHEN t.code LIKE 'x%' THEN 'student' ELSE 'teacher' END)::public.app_role,
       'Fixture', t.code,
       (CASE WHEN t.code LIKE 'x%' OR t.code = 'admin' THEN 'active' ELSE 'provisional_active' END)::public.account_status,
       (CASE WHEN t.code = 'tzz' THEN 'male' ELSE 'female' END)::public.gender,
       CASE WHEN t.code LIKE 'x%' THEN 'd0b2b000-0000-4000-8000-000000000001'::uuid END
  FROM dur_t t;

INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
SELECT t.id, 'autonomous'::public.student_type, 'standard'::public.interface_mode
  FROM dur_t t WHERE t.code LIKE 'x%';

-- Les enseignants parlent francais, sauf ceux de (C) : poular, pour que la
-- proposition d'enseignants (enseignants_pour_classe) ne parcoure qu'eux.
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT t.id, 'FR',
       CASE WHEN t.code IN ('tlib', 'tlib2') THEN ARRAY['poular'] ELSE ARRAY['francais'] END,
       CASE t.code WHEN 'tcap' THEN 3 ELSE 40 END,
       'approved', 'Europe/Paris'
  FROM dur_t t WHERE t.code LIKE 't%';

-- Disponibilites declarees (une ligne par heure) : (enseignant, jour ISO, heures).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.t(a.code), a.jour, h, 'Europe/Paris'
  FROM (VALUES
    -- (B) deplacements
    ('tmv', 3, ARRAY[15, 16, 17, 18, 19, 20, 21]),
    ('tmv', 4, ARRAY[15, 16, 17, 18, 19, 20, 21]),
    ('tmv', 1, ARRAY[16, 17, 18, 19, 20]),
    ('tmv', 5, ARRAY[8, 9, 10, 11, 12]),
    ('tcap', 1, ARRAY[7, 8, 9, 10, 11, 12, 13]),
    ('tcap', 2, ARRAY[10, 11]),
    ('tkyc', 3, ARRAY[17, 18, 19, 20]),
    ('tgen', 3, ARRAY[17, 18, 19, 20]),
    ('ttz', 3, ARRAY[17, 18, 19, 20]),
    ('tdm', 3, ARRAY[17, 18, 19, 20, 21]),
    ('tdm', 5, ARRAY[8, 9, 10, 11, 12]),
    ('tdm2', 3, ARRAY[17, 18, 19, 20, 21, 22]),
    ('tzz', 3, ARRAY[17, 18, 19, 20]),
    -- (C) creneaux libres : lundi 16-21, mardi 16-21, mercredi 18-19 et 21,
    -- mercredi 23 puis jeudi 0, dimanche 23 puis lundi 0
    ('tlib', 1, ARRAY[0, 16, 17, 18, 19, 20, 21]),
    ('tlib', 2, ARRAY[16, 17, 18, 19, 20, 21]),
    ('tlib', 3, ARRAY[18, 19, 21, 23]),
    ('tlib', 4, ARRAY[0]),
    ('tlib', 5, ARRAY[14, 15]),
    ('tlib', 7, ARRAY[23]),
    ('tlib2', 1, ARRAY[16, 17, 18, 19, 20]),
    ('tlib2', 5, ARRAY[14, 15]),
    -- (G) corrections de relecture
    ('tph', 3, ARRAY[18, 19, 20]),
    ('tph', 4, ARRAY[18, 19, 20]),
    ('tph', 5, ARRAY[18, 19, 20]),
    ('tph2', 3, ARRAY[17, 18, 19, 20, 21]),
    ('tdl', 3, ARRAY[17, 18, 19])
  ) a(code, jour, heures)
  CROSS JOIN LATERAL unnest(a.heures) h;
-- Un eleve de cours particulier de tlib2 declare lundi 18 h (affectation individuelle, 60 minutes).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES (pg_temp.t('xtsa'), 1, 18, 'Europe/Paris');
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local, timezone_iana)
VALUES (pg_temp.t('tlib2'), pg_temp.t('xtsa'), 1, 18, 'Europe/Paris');

-- Les offres : enfants 90 minutes, adultes 60, enfants 45.
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, created_by)
VALUES
  ('d0b2aaaa-0000-4000-8000-000000000090', 'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 90, 'brouillon', pg_temp.t('admin')),
  ('d0b2aaaa-0000-4000-8000-000000000060', 'adulte', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 60, 'brouillon', pg_temp.t('admin')),
  ('d0b2aaaa-0000-4000-8000-000000000045', 'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 17, 45, 'brouillon', pg_temp.t('admin'));

SELECT pg_temp.vrai(
  public.app_config_int('seance.duree_minutes_adulte', -1) = 90
  AND public.app_config_int('seance.duree_minutes_enfant', -1) = 60
  AND public.app_config_int('session_duration_minutes', -1) = 60
  AND public.app_config_int('matching_horizon_weeks', -1) = 4,
  'fixtures : les reglages valent 90 (adultes), 60 (enfants), 60 (duree unique d''avant), 4 semaines');

-- ==================================================================
-- (A) La duree des seances materialisees
-- ==================================================================
-- (A1) Les seances materialisees prennent la duree de la Classe.
SELECT pg_temp.classe('MAT_AD', 'tmat', 'adulte', 3, 18);
SELECT pg_temp.classe('MAT_EN', 'tmat', 'enfant', 5, 10);
SELECT pg_temp.classe('MAT_O90', 'tmat', 'enfant', 1, 10, 'd0b2aaaa-0000-4000-8000-000000000090');
SELECT pg_temp.classe('MAT_O60', 'tmat', 'adulte', 2, 10, 'd0b2aaaa-0000-4000-8000-000000000060');
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD') = '90,90,90,90',
  '(A1) une Classe d''adultes materialise quatre seances de 90 minutes (le calendrier reel suit l''affectation)');
SELECT pg_temp.vrai(pg_temp.durees('MAT_EN') = '60,60,60,60',
  '(A1) une Classe d''enfants materialise des seances de 60 minutes (rien ne change)');
SELECT pg_temp.vrai(pg_temp.durees('MAT_O90') = '90,90,90,90',
  '(A1) une Classe d''enfants nee d''une offre de 90 minutes : 90 minutes (la duree de l''offre)');
SELECT pg_temp.vrai(pg_temp.durees('MAT_O60') = '60,60,60,60',
  '(A1) une Classe d''adultes nee d''une offre de 60 minutes : 60 minutes (la duree de l''offre)');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM public.sessions s
     WHERE s.groupe_id IN (pg_temp.c('MAT_AD'), pg_temp.c('MAT_EN'), pg_temp.c('MAT_O90'), pg_temp.c('MAT_O60'))
       AND (s.started_at <= now()
            OR s.join_opens_at IS DISTINCT FROM s.started_at - interval '20 minutes'
            OR s.status <> 'planned')),
  '(A1) debut, ouverture de la salle (20 minutes avant) et statut ne changent pas : seule la fin change');
SELECT pg_temp.vrai(
  (SELECT s.session_type FROM public.sessions s WHERE s.groupe_id = pg_temp.c('MAT_AD') LIMIT 1) = 'standard'
  AND (SELECT s.session_type FROM public.sessions s WHERE s.groupe_id = pg_temp.c('MAT_EN') LIMIT 1) = 'child',
  '(A1) le type de seance suit le public comme avant (adultes standard, enfants child)');

-- Un eleve rejoint la Classe d'adultes : les seances deja materialisees ne sont
-- PAS reecrites (choix par defaut : materialiser tourne a chaque adhesion).
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('MAT_AD'), pg_temp.t('xmat'));
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD') = '90,90,90,90'
  AND (SELECT count(*) FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
        WHERE s.groupe_id = pg_temp.c('MAT_AD') AND sp.profile_id = pg_temp.t('xmat')) = 4,
  '(A1) un eleve qui rejoint est inscrit aux quatre seances a venir, a 90 minutes, sans rien reecrire');
-- Le reglage des adultes passe a 120 minutes : les seances CREEES ensuite
-- prennent 120 ; celles deja materialisees restent a 90 tant qu'on ne les aligne pas.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(120), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')));
SELECT pg_temp.classe('MAT_AD120', 'tmat', 'adulte', 6, 10);
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD120') = '120,120,120,120',
  '(A1) le reglage des adultes passe a 120 : une Classe creee ensuite materialise des seances de 120 minutes');
SELECT pg_temp.vrai(public.materialiser_seances_groupe(pg_temp.c('MAT_AD')) = 0,
  '(A1) ... mais materialiser une Classe deja materialisee ne cree rien (0 seance)');
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD') = '90,90,90,90', '(A1) ... et ne reecrit rien : toujours 90 minutes');
SELECT pg_temp.vrai(pg_temp.aligne('MAT_AD') = 4, '(A1) ... la direction les aligne quand elle le veut : 4 seances ecrites');
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD') = '120,120,120,120', '(A1) ... a 120 minutes');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(90), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')));
SELECT pg_temp.vrai(pg_temp.aligne('MAT_AD') = 4 AND pg_temp.aligne('MAT_AD120') = 4,
  '(A1) le reglage revient a 90 : l''alignement ecrit les 8 seances des deux Classes');
SELECT pg_temp.vrai(pg_temp.durees('MAT_AD') = '90,90,90,90' AND pg_temp.durees('MAT_AD120') = '90,90,90,90',
  '(A1) ... qui reviennent a 90 minutes (rejouable, raccourcit aussi)');
SELECT pg_temp.vrai(pg_temp.aligne(NULL) = 0,
  '(A1) un alignement sur des seances deja alignees n''ecrit rien (0)');

-- (A2) L'alignement ne touche que les seances a venir non commencees.
SELECT pg_temp.classe('ALI', 'tali', 'adulte', 4, 14);
SELECT pg_temp.perime('ALI');
-- Quatre seances : s0 reste planifiee ; s1 en preparation ; s2 supprimee ; s3 annulee.
DO $ali$
DECLARE
  v_ids uuid[];
BEGIN
  SELECT pg_catalog.array_agg(s.id ORDER BY s.started_at) INTO v_ids
    FROM public.sessions s WHERE s.groupe_id = pg_temp.c('ALI');
  UPDATE public.sessions SET status = 'preflight' WHERE id = v_ids[2];
  UPDATE public.sessions SET deleted_at = now() WHERE id = v_ids[3];
  UPDATE public.sessions SET status = 'canceled' WHERE id = v_ids[4];
  PERFORM pg_catalog.set_config('test.ali', pg_catalog.array_to_string(v_ids, ','), true);
END
$ali$;
-- Des seances de la meme Classe, mais d'un autre enseignant (pour ne chevaucher
-- aucune occurrence de la Classe) : passee, commencee, terminee.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES
  ('d0b2c000-0000-4000-8000-000000000001', pg_temp.t('tsolo'), now() - interval '2 days', now() - interval '2 days' + interval '60 minutes', 'planned', pg_temp.c('ALI')),
  ('d0b2c000-0000-4000-8000-000000000002', pg_temp.t('tsolo'), now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress', pg_temp.c('ALI')),
  ('d0b2c000-0000-4000-8000-000000000003', pg_temp.t('tsolo'), now() - interval '9 days', now() - interval '9 days' + interval '60 minutes', 'ended', pg_temp.c('ALI'));
-- Une Classe close avec une seance a venir de 60 minutes, et une autre Classe.
SELECT pg_temp.classe('CLOS', 'tclos', 'adulte', 2, 16);
UPDATE public.groupes SET ended_at = now(), ended_by = pg_temp.t('admin'), end_reason = 'fin du lot'
 WHERE id = pg_temp.c('CLOS');
SELECT pg_temp.perime('CLOS');
SELECT pg_temp.classe('ALI2', 'tali2', 'adulte', 5, 15);
SELECT pg_temp.perime('ALI2');

SELECT pg_temp.vrai(pg_temp.aligne('ALI') = 1,
  '(A2) l''alignement d''une Classe n''ecrit que sa seance planifiee a venir (1)');
SELECT pg_temp.vrai(
  (SELECT round(extract(epoch FROM (ended_at - started_at)) / 60) FROM public.sessions
    WHERE id = (string_to_array(current_setting('test.ali'), ','))[1]::uuid) = 90,
  '(A2) ... qui passe de 60 a 90 minutes');
SELECT pg_temp.vrai(
  (SELECT round(extract(epoch FROM (ended_at - started_at)) / 60) FROM public.sessions
    WHERE id = (string_to_array(current_setting('test.ali'), ','))[2]::uuid) = 60,
  '(A2) une seance en preparation (preflight) n''est pas touchee');
SELECT pg_temp.vrai(
  (SELECT round(extract(epoch FROM (ended_at - started_at)) / 60) FROM public.sessions
    WHERE id = (string_to_array(current_setting('test.ali'), ','))[3]::uuid) = 60,
  '(A2) une seance supprimee n''est pas touchee');
SELECT pg_temp.vrai(
  (SELECT round(extract(epoch FROM (ended_at - started_at)) / 60) FROM public.sessions
    WHERE id = (string_to_array(current_setting('test.ali'), ','))[4]::uuid) = 60,
  '(A2) une seance annulee n''est pas touchee');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions WHERE id::text LIKE 'd0b2c000-0000-4000-8000-00000000000%'
     AND ended_at - started_at = interval '60 minutes') = 3,
  '(A2) une seance passee, une seance commencee (en cours) et une seance terminee gardent leurs 60 minutes : jamais reecrites');
SELECT pg_temp.vrai(pg_temp.durees('CLOS') = '60,60,60,60',
  '(A2) les seances d''une Classe close ne sont pas touchees (60 minutes)');
SELECT pg_temp.vrai(pg_temp.durees('ALI2') = '60,60,60,60',
  '(A2) l''alignement d''une Classe ne touche pas les seances d''une autre Classe');

-- (A3) Un rallongement qui chevauche ARRETE tout, sans rien ecrire.
-- CF1 : une seance ponctuelle du meme enseignant commence a 19 h.
SELECT pg_temp.classe('CF1', 'tcf1', 'adulte', 3, 18);
SELECT pg_temp.perime('CF1');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000a1', pg_temp.t('tcf1'),
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '90 minutes', 'planned', NULL);
DO $cf1$
DECLARE
  v_msg text;
  v_hint text;
  v_etat text;
  v_ids text;
BEGIN
  BEGIN
    PERFORM app_private.aligner_seances_a_venir_sur_la_classe(pg_temp.c('CF1'));
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : (A3) le rallongement qui chevauche n''a pas ete arrete';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> 'P0001' THEN RAISE; END IF;
    GET STACKED DIAGNOSTICS v_hint = PG_EXCEPTION_HINT;
    v_msg := SQLERRM;
  END;
  SELECT string_agg(s.id::text, ',' ORDER BY s.started_at) INTO v_ids
    FROM public.sessions s WHERE s.groupe_id = pg_temp.c('CF1')
     AND s.started_at = public.instant_creneau(3, 18, 'Europe/Paris', 1);
  IF v_msg NOT LIKE 'CLASSES-DUREE : 1 seance(s) a venir ne peuvent pas prendre la duree de leur Classe sans en chevaucher une autre%'
     OR position(v_ids in v_msg) = 0
     OR position('d0b2c000-0000-4000-8000-0000000000a1' in v_msg) = 0
     OR v_hint NOT LIKE '%aligner_seances_a_venir_sur_la_classe%'
     OR v_hint NOT LIKE '%rejouer la migration%'
     OR position('Classe ' || pg_temp.c('CF1')::text in v_msg) = 0
     OR position('debut ' in v_msg) = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : (A3) message incomplet : « % » (indice : %)', v_msg, v_hint;
  END IF;
END
$cf1$;
SELECT pg_temp.ok('(A3) un rallongement qui chevauche une seance ponctuelle du meme enseignant s''arrete : le message donne le nombre (1), l''identifiant de la seance et celui de l''autre, et un indice');
SELECT pg_temp.vrai(pg_temp.durees('CF1') = '60,60,60,60',
  '(A3) ... et RIEN n''est ecrit : les quatre seances de la Classe (dont les trois sans conflit) restent a 60 minutes');
-- Une fois l'autre seance annulee, l'alignement passe.
UPDATE public.sessions SET status = 'canceled' WHERE id = 'd0b2c000-0000-4000-8000-0000000000a1';
SELECT pg_temp.vrai(pg_temp.aligne('CF1') = 4,
  '(A3) l''autre seance annulee (elle ne compte plus pour la contrainte), l''alignement passe : 4 seances ecrites');
SELECT pg_temp.vrai(pg_temp.durees('CF1') = '90,90,90,90', '(A3) ... a 90 minutes');

-- Deux seances qui se TOUCHENT ne se chevauchent pas : la seance ponctuelle commence a 19 h 30.
SELECT pg_temp.classe('CF4', 'tadj', 'adulte', 3, 18);
SELECT pg_temp.perime('CF4');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000a4', pg_temp.t('tadj'),
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '90 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '150 minutes', 'planned', NULL);
SELECT pg_temp.vrai(pg_temp.aligne('CF4') = 4,
  '(A3) une seance qui commence exactement a la nouvelle fin (19 h 30) ne chevauche pas : l''alignement passe');

-- CF2 : un meme eleve est inscrit a une seance d'un AUTRE enseignant qui commence a 19 h.
SELECT pg_temp.classe('CF2', 'tcf2', 'adulte', 3, 18);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('CF2'), pg_temp.t('xp'));
SELECT pg_temp.perime('CF2');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000a2', pg_temp.t('tcf2b'),
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '120 minutes', 'planned', NULL);
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('d0b2c000-0000-4000-8000-0000000000a2', pg_temp.t('xp'), 'student');
SELECT pg_temp.refus($$SELECT app_private.aligner_seances_a_venir_sur_la_classe(pg_temp.c('CF2'))$$, 'P0001',
  'CLASSES-DUREE : 1 seance(s) a venir ne peuvent pas prendre la duree de leur Classe sans en chevaucher une autre',
  '(A3) un rallongement qui chevauche une seance du MEME ELEVE (autre enseignant) s''arrete aussi');
SELECT pg_temp.vrai(pg_temp.durees('CF2') = '60,60,60,60', '(A3) ... sans rien ecrire');
UPDATE public.session_participants SET deleted_at = now()
 WHERE session_id = 'd0b2c000-0000-4000-8000-0000000000a2' AND profile_id = pg_temp.t('xp');
SELECT pg_temp.vrai(pg_temp.aligne('CF2') = 4,
  '(A3) l''eleve retire de l''autre seance, l''alignement passe (4)');

-- CF3 : la seance 0 a un REMPLACANT designe, qui a sa propre seance a 19 h.
SELECT pg_temp.classe('CF3', 'tcf3', 'adulte', 3, 18);
SELECT pg_temp.perime('CF3');
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
SELECT s.id, 'remplacement_designe_admin', pg_temp.t('tcf3'), pg_temp.t('trep'), pg_temp.t('admin'), gen_random_uuid()
  FROM public.sessions s WHERE s.groupe_id = pg_temp.c('CF3')
 ORDER BY s.started_at LIMIT 1;
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000a3', pg_temp.t('trep'),
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '120 minutes', 'planned', NULL);
SELECT pg_temp.refus($$SELECT app_private.aligner_seances_a_venir_sur_la_classe(pg_temp.c('CF3'))$$, 'P0001',
  'CLASSES-DUREE : 1 seance(s) a venir ne peuvent pas prendre la duree de leur Classe sans en chevaucher une autre',
  '(A3) un rallongement qui chevauche une seance du REMPLACANT designe s''arrete (enseignant effectif)');
SELECT pg_temp.vrai(pg_temp.durees('CF3') = '60,60,60,60', '(A3) ... sans rien ecrire');
UPDATE public.sessions SET status = 'canceled' WHERE id = 'd0b2c000-0000-4000-8000-0000000000a3';
SELECT pg_temp.vrai(pg_temp.aligne('CF3') = 4,
  '(A3) la seance du remplacant annulee, l''alignement passe (4)');

-- Deux Classes du meme enseignant qui changent TOUTES LES DEUX : PA mercredi 18 h,
-- PB mercredi 19 h. PA rallongee (19 h 30) chevauche PB meme quand PB change aussi
-- (19 h-20 h 30) : la nouvelle fin de chaque seance compte.
SELECT pg_temp.classe('PA', 'tpair', 'adulte', 3, 18);
SELECT pg_temp.perime('PA');
SELECT pg_temp.classe('PB', 'tpair', 'adulte', 3, 19);
SELECT pg_temp.perime('PB');
SELECT pg_temp.refus($$SELECT app_private.aligner_seances_a_venir_sur_la_classe(pg_temp.c('PA'))$$, 'P0001',
  'CLASSES-DUREE : 4 seance(s) a venir ne peuvent pas prendre la duree de leur Classe sans en chevaucher une autre',
  '(A3) deux Classes consecutives du meme enseignant : rallonger PA chevauche PB (4 seances)');
DO $pair$
DECLARE
  v_msg text;
BEGIN
  BEGIN
    PERFORM app_private.aligner_seances_a_venir_sur_la_classe();
  EXCEPTION WHEN OTHERS THEN
    v_msg := SQLERRM;
  END;
  -- Le global voit PA et PB (8 seances), chacune avec la nouvelle fin de l'autre.
  IF v_msg IS NULL OR v_msg NOT LIKE 'CLASSES-DUREE : 8 seance(s) a venir ne peuvent pas%' THEN
    RAISE EXCEPTION 'CLASSES-DUREE-BOUT ROUGE : (A3) l''alignement global devait s''arreter sur 8 seances (PA et PB), message : %', v_msg;
  END IF;
END
$pair$;
SELECT pg_temp.ok('(A3) l''alignement GLOBAL s''arrete aussi, et compte les huit seances de PA et de PB (leurs nouvelles fins se chevauchent)');
SELECT pg_temp.vrai(pg_temp.durees('PA') = '60,60,60,60' AND pg_temp.durees('PB') = '60,60,60,60',
  '(A3) ... sans rien ecrire (PA et PB restent a 60)');
-- Une seance n'a pas besoin d'etre sur le meme jour : PB annulee, tout passe.
UPDATE public.sessions SET status = 'canceled' WHERE groupe_id = pg_temp.c('PB');

-- (A4) Un raccourcissement passe : une Classe nee d'une offre de 45 minutes.
SELECT pg_temp.classe('SH', 'tsh', 'enfant', 2, 16, 'd0b2aaaa-0000-4000-8000-000000000045');
SELECT pg_temp.vrai(pg_temp.durees('SH') = '45,45,45,45', '(A4) une Classe nee d''une offre de 45 minutes materialise 45 minutes');
SELECT pg_temp.perime('SH');
SELECT pg_temp.vrai(pg_temp.aligne('SH') = 4, '(A4) ... ses seances a 60 minutes (anciennes) sont RACCOURCIES par l''alignement (4 ecrites)');
SELECT pg_temp.vrai(pg_temp.durees('SH') = '45,45,45,45', '(A4) ... a 45 minutes');

-- (A5) L'alignement global : plus rien ne differe ensuite.
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM app_private.seances_a_venir_a_realigner()),
  '(A5) avant l''alignement global, des seances a venir (ALI2, PA) different de la duree de leur Classe');
SELECT pg_temp.vrai(pg_temp.aligne(NULL) >= 8,
  '(A5) l''alignement global ecrit au moins les 8 seances de ALI2 et PA');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM app_private.seances_a_venir_a_realigner())
  AND pg_temp.durees('ALI2') = '90,90,90,90' AND pg_temp.durees('PA') = '90,90,90,90'
  AND pg_temp.durees('CLOS') = '60,60,60,60',
  '(A5) apres lui, plus aucune seance a venir ne differe de la duree de sa Classe ; la Classe close reste a 60');

-- ==================================================================
-- (B) Deplacer une Classe qui a son enseignant
-- ==================================================================
-- tmv : MV (adultes, mercredi 18 h), KID (enfants, jeudi 19 h), OTH (adultes, lundi 18 h) ;
-- une seance ponctuelle le vendredi 10 h (semaine 2).
SELECT pg_temp.classe('MV', 'tmv', 'adulte', 3, 18);
SELECT pg_temp.classe('KID', 'tmv', 'enfant', 4, 19);
SELECT pg_temp.classe('OTH', 'tmv', 'adulte', 1, 18);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000b1', pg_temp.t('tmv'),
        public.instant_creneau(5, 10, 'Europe/Paris', 2), public.instant_creneau(5, 10, 'Europe/Paris', 2) + interval '60 minutes',
        'planned', NULL);

CREATE FUNCTION pg_temp.mv(p_code text, p_jour int, p_heure int, p_tz text DEFAULT NULL, p_seuil int DEFAULT 6) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT format($q$SELECT public.modifier_groupe(%L::uuid, 'Bout deplacee', %s::smallint, %s::smallint, %s::smallint, %L, NULL)$q$,
                pg_temp.c(p_code), p_seuil, p_jour, p_heure, p_tz) $$;
CREATE FUNCTION pg_temp.etat(p_code text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT g.weekday || ':' || g.hour_local || ':' || g.timezone_iana || ' creneaux='
         || coalesce((SELECT string_agg(gc.weekday || ':' || gc.hour_local, ',' ORDER BY gc.weekday, gc.hour_local)
                        FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id), '')
         || ' seances=' || (SELECT count(*) FROM public.sessions s WHERE s.groupe_id = g.id)
    FROM public.groupes g WHERE g.id = pg_temp.c(p_code) $$;

SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SELECT pg_temp.vrai(pg_temp.etat('MV') = '3:18:Europe/Paris creneaux=3:18 seances=4', '(B) depart : MV mercredi 18 h, un creneau, 4 seances de 90 minutes');
-- (B1) Un deplacement qui passe : mercredi 16 h, couvert (16 et 17) et libre.
SELECT pg_temp.client(pg_temp.mv('MV', 3, 16));
SELECT pg_temp.vrai(pg_temp.etat('MV') = '3:16:Europe/Paris creneaux=3:16 seances=8',
  '(B1) un deplacement couvert et libre passe : jour et heure changent, le creneau d''ancrage suit, les seances du NOUVEL horaire sont materialisees');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions s WHERE s.groupe_id = pg_temp.c('MV') AND s.status = 'planned'
      AND extract(hour FROM s.started_at AT TIME ZONE 'Europe/Paris') = 18) = 4,
  '(B1) ... et celles de l''ANCIEN horaire (mercredi 18 h) restent planifiees : le deplacement ne les suit pas (comportement d''avant, non invente ici)');
-- (B2) Chaque raison de refus : memes messages, meme SQLSTATE, rien d'ecrit.
SELECT pg_temp.refus_client(pg_temp.mv('MV', 3, 22), 'P0001', 'enseignant non disponible: jour 3, heure 22',
  '(B2) refus : heure non declaree (mercredi 22 h)');
SELECT pg_temp.refus_client(pg_temp.mv('MV', 3, 21), 'P0001', 'enseignant non disponible: jour 3, heure 21',
  '(B2) refus : 21 h est declaree mais pas 22 h : un cours d''adultes de 90 minutes n''est pas couvert (la duree compte)');
SELECT pg_temp.refus_client(pg_temp.mv('MV', 4, 18), 'P0001', 'chevauchement avec une classe ou affectation active',
  '(B2) refus : jeudi 18 h-19 h 30 chevauche KID (jeudi 19 h)');
SELECT pg_temp.refus_client(pg_temp.mv('MV', 1, 19), 'P0001', 'chevauchement avec une classe ou affectation active',
  '(B2) refus : lundi 19 h-20 h 30 chevauche OTH (lundi 18 h-19 h 30, 90 minutes : sa propre duree compte)');
SELECT pg_temp.refus_client(pg_temp.mv('MV', 5, 9), 'P0001', 'chevauchement avec une séance existante',
  '(B2) refus : vendredi 9 h-10 h 30 chevauche la seance ponctuelle du vendredi 10 h');
SELECT pg_temp.vrai(pg_temp.etat('MV') = '3:16:Europe/Paris creneaux=3:16 seances=8',
  '(B2) apres ces cinq refus : horaire, creneaux et seances de MV inchanges (rien d''ecrit, rien de materialise)');
-- Un deplacement qui frole une autre Classe sans la chevaucher passe.
SELECT pg_temp.client(pg_temp.mv('MV', 1, 16));
SELECT pg_temp.vrai(pg_temp.etat('MV') LIKE '1:16:Europe/Paris creneaux=1:16 %',
  '(B2) lundi 16 h-17 h 30 passe (couvert 16 et 17, OTH commence a 18 h) : la Classe est ecartee de ses propres collisions');
SELECT pg_temp.client(pg_temp.mv('MV', 4, 20));
SELECT pg_temp.vrai(pg_temp.etat('MV') LIKE '4:20:Europe/Paris creneaux=4:20 %',
  '(B2) jeudi 20 h-21 h 30 passe : il commence exactement a la fin de KID (jeudi 19 h-20 h), deux creneaux qui se touchent ne se chevauchent pas');
-- Choix par defaut : le maximum de Classes par enseignant (plafond_classes_atteint)
-- n'est PAS rejoue pour un deplacement, qui n'ajoute aucune Classe. tmv en tient 3 ;
-- le maximum passe a 2 ; deplacer MV (jeudi 20 h -> 17 h) passe quand meme.
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(2), updated_by = %L WHERE key = 'enseignant.classes_max'$q$, pg_temp.t('admin')));
SELECT pg_temp.client(pg_temp.mv('MV', 4, 17));
SELECT pg_temp.vrai(pg_temp.etat('MV') LIKE '4:17:Europe/Paris creneaux=4:17 %',
  '(B2) un enseignant au-dessus du maximum de Classes (3 Classes, maximum ramene a 2) peut deplacer une Classe qu''il tient deja : le maximum compte les affectations, pas les deplacements');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(3), updated_by = %L WHERE key = 'enseignant.classes_max'$q$, pg_temp.t('admin')));
SELECT pg_temp.client(pg_temp.mv('MV', 4, 17, NULL, 5));
SELECT pg_temp.vrai(pg_temp.etat('MV') LIKE '4:17:Europe/Paris creneaux=4:17 %' AND (SELECT seuil_max FROM public.groupes WHERE id = pg_temp.c('MV')) = 5,
  '(B2) un changement de seuil sans changement d''horaire passe');
-- Le fuseau : 18 h a Tokyo (10 h a Paris l'hiver) n'est pas couvert, 18 h a Bruxelles l'est.
SELECT pg_temp.classe('TZ', 'ttz', 'adulte', 3, 18);
SELECT pg_temp.refus_client(pg_temp.mv('TZ', 3, 18, 'Asia/Tokyo'), 'P0001', 'enseignant non disponible: jour 3, heure 18, fuseau Asia/Tokyo',
  '(B2) refus : changer le FUSEAU compte comme changer l''horaire (18 h a Tokyo n''est pas couvert)');
SELECT pg_temp.vrai(pg_temp.etat('TZ') = '3:18:Europe/Paris creneaux=3:18 seances=4', '(B2) ... et le fuseau de la Classe n''a pas change');
SELECT pg_temp.client(pg_temp.mv('TZ', 3, 18, 'Europe/Brussels'));
SELECT pg_temp.vrai(pg_temp.etat('TZ') LIKE '3:18:Europe/Brussels %', '(B2) 18 h a Bruxelles (meme decalage que Paris) passe');
-- Le plafond horaire : tcap (3 h par semaine) tient CAP, 2 creneaux de 90 minutes = 3 h.
SELECT pg_temp.classe('CAP', 'tcap', 'adulte', 1, 10);
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (pg_temp.c('CAP'), 2, 10);
-- Lundi 10 h -> 11 h : les seances de l'ancien horaire (10 h-11 h 30) restent
-- planifiees et chevaucheraient les nouvelles (11 h-12 h 30) : refus nomme, plus
-- d'erreur technique de la contrainte d'exclusion.
SELECT pg_temp.refus_client(pg_temp.mv('CAP', 1, 11), 'P0001', 'chevauchement avec une séance existante',
  '(B2) refus : lundi 10 h -> 11 h pour un cours de 90 minutes chevauche les seances a venir de l''ancien horaire de la meme Classe (refus nomme, pas l''erreur de la contrainte)');
SELECT pg_temp.vrai(pg_temp.etat('CAP') = '1:10:Europe/Paris creneaux=1:10,2:10 seances=4', '(B2) ... rien d''ecrit');
SELECT pg_temp.client(pg_temp.mv('CAP', 1, 8));
SELECT pg_temp.vrai(pg_temp.etat('CAP') LIKE '1:8:Europe/Paris creneaux=1:8,2:10 %',
  '(B2) lundi 10 h -> 8 h passe (8 h-9 h 30 ne touche pas l''ancien horaire) : le plafond horaire (3 h pour un plafond de 3 h) ne change pas, deplacer ne change pas la charge');
UPDATE public.teacher_profiles SET weekly_hours_cap = 2 WHERE profile_id = pg_temp.t('tcap');
SELECT pg_temp.refus_client(pg_temp.mv('CAP', 1, 12), 'P0001', 'plafond horaire enseignant dépassé',
  '(B2) refus : plafond horaire (3 h de Classes pour un plafond ramene a 2 h)');
-- Le compte : piece non validee.
SELECT pg_temp.classe('KYC', 'tkyc', 'adulte', 3, 18);
UPDATE public.teacher_profiles SET kyc_status = 'pending' WHERE profile_id = pg_temp.t('tkyc');
SELECT pg_temp.refus_client(pg_temp.mv('KYC', 3, 17), 'P0001', 'enseignant indisponible ou genre inconnu',
  '(B2) refus : piece d''identite non validee');
-- Le genre du public.
SELECT pg_temp.classe('GEN', 'tgen', 'adulte', 3, 18);
UPDATE public.groupes SET genre_public = 'hommes' WHERE id = pg_temp.c('GEN');
SELECT pg_temp.refus_client(pg_temp.mv('GEN', 3, 17), 'P0001', 'enseignant incompatible avec le public de la classe',
  '(B2) refus : genre de l''enseignante incompatible avec le public de la Classe');
SELECT pg_temp.vrai(pg_temp.etat('GEN') = '3:18:Europe/Paris creneaux=3:18 seances=4' AND pg_temp.etat('KYC') = '3:18:Europe/Paris creneaux=3:18 seances=4',
  '(B2) ... rien d''ecrit pour ces deux Classes non plus');
-- (B3) Une Classe SANS enseignant se deplace comme avant, meme sur un creneau que personne ne couvre.
SELECT pg_temp.classe_attente('EN', 'adulte', 3, 18);
SELECT pg_temp.client(pg_temp.mv('EN', 6, 3));
SELECT pg_temp.vrai(pg_temp.etat('EN') = '6:3:Europe/Paris creneaux=6:3 seances=0',
  '(B3) une Classe sans enseignant se deplace sans controle (samedi 3 h), et ne materialise aucune seance');
-- (B4) Le declencheur ne s'allume que pour un deplacement : sans disponibilites, un changement de seuil passe.
DELETE FROM public.weekly_availability WHERE profile_id = pg_temp.t('tgen');
SELECT pg_temp.client(pg_temp.mv('GEN', 3, 18, NULL, 4));
SELECT pg_temp.vrai(pg_temp.etat('GEN') LIKE '3:18:Europe/Paris %' AND (SELECT seuil_max FROM public.groupes WHERE id = pg_temp.c('GEN')) = 4,
  '(B4) sans plus aucune disponibilite declaree, changer le seuil (meme horaire) passe : seul un deplacement est controle');

-- (B5) groupe_creneaux ecrit directement par la direction, sous le role connecte.
SELECT pg_temp.classe('DM', 'tdm', 'adulte', 3, 18);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000b2', pg_temp.t('tdm'),
        public.instant_creneau(5, 10, 'Europe/Paris', 2), public.instant_creneau(5, 10, 'Europe/Paris', 2) + interval '60 minutes',
        'planned', NULL);
CREATE FUNCTION pg_temp.cr(p_code text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT coalesce(string_agg(gc.weekday || ':' || gc.hour_local, ',' ORDER BY gc.weekday, gc.hour_local), '')
    FROM public.groupe_creneaux gc WHERE gc.groupe_id = pg_temp.c(p_code) $$;
SELECT pg_temp.client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 5, 8)$q$, pg_temp.c('DM')));
SELECT pg_temp.vrai(pg_temp.cr('DM') = '3:18,5:8', '(B5) un creneau couvert et libre (vendredi 8 h-9 h 30) s''ajoute a une Classe qui a son enseignant');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 5, 10)$q$, pg_temp.c('DM')),
  'P0001', 'chevauchement avec une séance existante', '(B5) refus : un creneau (vendredi 10 h) qui chevauche une seance ponctuelle');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 3, 19)$q$, pg_temp.c('DM')),
  'P0001', 'chevauchement avec une séance existante',
  '(B5) refus : un second creneau le mercredi a 19 h (18 h-19 h 30 puis 19 h-20 h 30) : la Classe se chevaucherait elle-meme');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 5, 23)$q$, pg_temp.c('DM')),
  'P0001', 'enseignant non disponible: jour 5, heure 23', '(B5) refus : un creneau que l''enseignant ne couvre pas');
SELECT pg_temp.refus_client(format($q$UPDATE public.groupe_creneaux SET hour_local = 23 WHERE groupe_id = %L AND weekday = 5$q$, pg_temp.c('DM')),
  'P0001', 'enseignant non disponible: jour 5, heure 23', '(B5) refus : modifier un creneau vers une heure non couverte');
SELECT pg_temp.refus_client(format($q$UPDATE public.groupe_creneaux SET hour_local = 9 WHERE groupe_id = %L AND weekday = 5$q$, pg_temp.c('DM')),
  'P0001', 'chevauchement avec une séance existante', '(B5) refus : modifier un creneau vers vendredi 9 h-10 h 30 (chevauche la seance de 10 h)');
SELECT pg_temp.vrai(pg_temp.cr('DM') = '3:18,5:8', '(B5) ... et les creneaux de la Classe sont inchanges apres ces refus');
SELECT pg_temp.client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 6, 4)$q$, pg_temp.c('EN')));
SELECT pg_temp.vrai(pg_temp.cr('EN') = '6:3,6:4', '(B5) un creneau ajoute a une Classe sans enseignant passe, meme non couvert');
SELECT pg_temp.client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 6, 2)$q$, pg_temp.c('CLOS')));
SELECT pg_temp.vrai(pg_temp.cr('CLOS') LIKE '%6:2%', '(B5) un creneau ajoute a une Classe close n''est pas controle');
-- Deux creneaux d'une meme Classe qui se chevauchent AVANT toute materialisation : la
-- Classe DM2 (mercredi 18 h) recoit un creneau a 20 h (accepte, aucune seance encore
-- materialisee), puis un second a 21 h (20 h-21 h 30 puis 21 h-22 h 30) : refuse.
SELECT pg_temp.classe('DM2', 'tdm2', 'adulte', 3, 18);
SELECT pg_temp.client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 3, 20)$q$, pg_temp.c('DM2')));
SELECT pg_temp.vrai(pg_temp.cr('DM2') = '3:18,3:20' AND pg_temp.nb_seances('DM2') = 4,
  '(B5) un second creneau (mercredi 20 h-21 h 30) s''ajoute : il ne chevauche rien, et aucune seance n''existe encore pour lui');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 3, 21)$q$, pg_temp.c('DM2')),
  'P0001', 'chevauchement avec une séance existante',
  '(B5) refus : mercredi 21 h chevauche le creneau de 20 h de la MEME Classe, meme sans seance materialisee');
-- Un compte qui n'est pas la direction ne peut toujours pas ecrire (la policy est intacte).
SELECT pg_temp.qui(pg_temp.t('tdm'), 'teacher');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 5, 9)$q$, pg_temp.c('DM')),
  '42501', 'new row violates row-level security policy',
  '(B5) un enseignant n''ecrit pas groupe_creneaux : la policy de la direction est intacte');
SELECT pg_temp.refus_client(pg_temp.mv('DM', 3, 17), 'P0001', 'modification de groupe reservee a l''administration',
  '(B5) ... et modifier_groupe garde sa porte (direction active)');
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');

-- ==================================================================
-- (C) Les creneaux libres comptent la duree
-- ==================================================================
-- tlib tient LA (adultes, lundi 18 h-19 h 30) et LK (enfants, mardi 18 h-19 h).
SELECT pg_temp.classe('LA', 'tlib', 'adulte', 1, 18);
SELECT pg_temp.classe('LK', 'tlib', 'enfant', 2, 18);
SELECT pg_temp.classe_attente('CA', 'adulte', 5, 14, NULL, 'poular');
SELECT pg_temp.classe_attente('CK', 'enfant', 5, 14, NULL, 'poular');
SELECT pg_temp.classe_attente('CO90', 'enfant', 5, 14, 'd0b2aaaa-0000-4000-8000-000000000090', 'poular');
CREATE FUNCTION pg_temp.libres_classe(p_code text, p_teacher text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT pg_temp.libres(r.creneaux_libres) FROM public.enseignants_pour_classe(pg_temp.c(p_code)) r WHERE r.teacher_id = pg_temp.t(p_teacher) $$;
CREATE FUNCTION pg_temp.libres_public(p_public text, p_teacher text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT pg_temp.libres(r.creneaux_libres) FROM public.enseignants_pour_public(p_public) r WHERE r.teacher_id = pg_temp.t(p_teacher) $$;
-- Les heures declarees de tlib : lundi 0 et 16-21, mardi 16-21, mercredi 18, 19, 21 et 23,
-- jeudi 0, vendredi 14 et 15 (l'horaire des Classes a pourvoir), dimanche 23.
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CA', 'tlib') = '1:16 1:20 2:16 2:19 2:20 3:18 3:23 5:14 7:23',
  '(C) Classe d''ADULTES (90 minutes) : lundi 16 et 20 (17 et 19 chevauchent LA 18 h-19 h 30 ; 21 manque la 22), mardi 16, 19 et 20, mercredi 18 (19 manque la 20) et 23 (+ jeudi 0), dimanche 23 (+ lundi 0)');
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CK', 'tlib') = '1:0 1:16 1:17 1:20 1:21 2:16 2:17 2:19 2:20 2:21 3:18 3:19 3:21 3:23 4:0 5:14 5:15 7:23',
  '(C) Classe d''ENFANTS (60 minutes) : une seule heure suffit (lundi 0, 17 qui touche LA sans la chevaucher, 21...), 18 et 19 du lundi chevauchent LA, 18 du mardi chevauche LK');
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CO90', 'tlib') = pg_temp.libres_classe('CA', 'tlib'),
  '(C) Classe d''enfants nee d''une offre de 90 minutes : les memes creneaux libres qu''une Classe d''adultes (la duree est celle de la Classe)');
SELECT pg_temp.vrai(
  pg_temp.libres_public('adulte', 'tlib') = pg_temp.libres_classe('CA', 'tlib')
  AND pg_temp.libres_public('enfant', 'tlib') = pg_temp.libres_classe('CK', 'tlib'),
  '(C) enseignants_pour_public compte la duree du public demande : les memes creneaux libres, adultes (90) et enfants (60)');
-- Une seance ponctuelle de tlib le mardi 20 h-21 h (semaine 3) : chaque duree la compte a sa facon.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000c1', pg_temp.t('tlib'),
        public.instant_creneau(2, 20, 'Europe/Paris', 3), public.instant_creneau(2, 20, 'Europe/Paris', 3) + interval '60 minutes',
        'planned', NULL);
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CA', 'tlib') = '1:16 1:20 2:16 3:18 3:23 5:14 7:23',
  '(C) seance ponctuelle du mardi 20 h-21 h : la Classe d''adultes perd mardi 19 (19 h-20 h 30) et 20, garde mardi 16');
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CK', 'tlib') = '1:0 1:16 1:17 1:20 1:21 2:16 2:17 2:19 2:21 3:18 3:19 3:21 3:23 4:0 5:14 5:15 7:23',
  '(C) ... la Classe d''enfants perd seulement mardi 20 (mardi 19 h-20 h touche la seance sans la chevaucher)');
UPDATE public.sessions SET status = 'canceled' WHERE id = 'd0b2c000-0000-4000-8000-0000000000c1';
-- tlib2 : un eleve en cours particulier (60 minutes) le lundi 18 h-19 h ; hier declare lundi 16-20.
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CA', 'tlib2') = '1:16 1:19 5:14',
  '(C) affectation individuelle (60 minutes) lundi 18 h : adultes (90) lundi 16 (16 h-17 h 30) et 19 (19 h-20 h 30, touche 19 h) ; 17 et 18 chevauchent');
SELECT pg_temp.vrai(
  pg_temp.libres_classe('CK', 'tlib2') = '1:16 1:17 1:19 1:20 5:14 5:15',
  '(C) ... enfants (60) : lundi 16, 17, 19 et 20 (18 chevauche l''eleve)');

-- ==================================================================
-- (D) transferer_eleve compte la duree de la Classe CIBLE
-- ==================================================================
-- Classes de la meme famille (mercredi 18 h, enfants) : S (60 min, ttr1) ou xtr est inscrit,
-- T (nee d'une offre de 90 min, ttr2), T2 (60 min, ttr4). xtr est aussi inscrit a une seance
-- ponctuelle de ttr3 qui commence a 19 h.
SELECT pg_temp.classe('TS', 'ttr1', 'enfant', 3, 18);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('TS'), pg_temp.t('xtr'));
SELECT pg_temp.classe('TT', 'ttr2', 'enfant', 3, 18, 'd0b2aaaa-0000-4000-8000-000000000090');
SELECT pg_temp.classe('TT2', 'ttr4', 'enfant', 3, 18);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('d0b2c000-0000-4000-8000-0000000000d1', pg_temp.t('ttr3'),
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 1) + interval '120 minutes', 'planned', NULL);
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('d0b2c000-0000-4000-8000-0000000000d1', pg_temp.t('xtr'), 'student');
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SELECT pg_temp.vrai(
  (public.transferer_eleve(pg_temp.t('xtr'), pg_temp.c('TS'), pg_temp.c('TT'), 'bout-en-bout-1'))->>'statut' = 'refuse'
  AND (public.transferer_eleve(pg_temp.t('xtr'), pg_temp.c('TS'), pg_temp.c('TT'), 'bout-en-bout-1'))->>'raison' = 'chevauchement',
  '(D) transferer_eleve vers une Classe nee d''une offre de 90 minutes : refus « chevauchement » (18 h-19 h 30 touche la seance de 19 h), pas une erreur du garde de seances');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.groupe_membres WHERE groupe_id = pg_temp.c('TS') AND student_id = pg_temp.t('xtr') AND left_at IS NULL),
  '(D) ... l''eleve reste dans sa Classe source');
SELECT pg_temp.vrai(
  (public.transferer_eleve(pg_temp.t('xtr'), pg_temp.c('TS'), pg_temp.c('TT2'), 'bout-en-bout-2'))->>'statut' = 'fait',
  '(D) vers une Classe de 60 minutes de la meme famille (18 h-19 h, elle touche la seance de 19 h sans la chevaucher) : transfert fait');

-- ==================================================================
-- (E) La paie : sa base est la duree de la seance (constat ; aucun calcul change)
-- ==================================================================
-- PAYA : Classe d'adultes materialisee par la fonction corrigee (90 minutes).
-- PAYB : Classe d'adultes dont les seances ont l'ancienne duree (60 minutes).
-- Meme eleve present, meme duree tenue (90 minutes, au-dessus des 70 minutes dues).
SELECT pg_temp.classe('PAYA', 'tpay', 'adulte', 1, 12);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('PAYA'), pg_temp.t('xpay'));
SELECT pg_temp.classe('PAYB', 'tpay2', 'adulte', 2, 12);
SELECT pg_temp.perime('PAYB');
CREATE TEMP TABLE dur_pay (code text PRIMARY KEY, session_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO dur_pay
SELECT x.code, (SELECT s.id FROM public.sessions s WHERE s.groupe_id = pg_temp.c(x.code) ORDER BY s.started_at LIMIT 1)
  FROM (VALUES ('PAYA'), ('PAYB')) x(code);
INSERT INTO public.session_participants (session_id, profile_id, role)
SELECT session_id, pg_temp.t('xpay'), 'student' FROM dur_pay WHERE code = 'PAYB'
ON CONFLICT DO NOTHING;
INSERT INTO public.session_events (session_id, profile_id, event_type, server_ts, source)
SELECT p.session_id, pg_temp.t('xpay'), 'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM dur_pay p JOIN public.sessions s ON s.id = p.session_id;
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id IN (SELECT session_id FROM dur_pay);
UPDATE public.sessions SET status = 'in_progress' WHERE id IN (SELECT session_id FROM dur_pay);
UPDATE public.sessions s
   SET finance_started_at = s.started_at, finance_ended_at = s.started_at + interval '90 minutes', status = 'ended'
 WHERE s.id IN (SELECT session_id FROM dur_pay);
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
CREATE FUNCTION pg_temp.paie(p_code text) RETURNS bigint
LANGUAGE sql STABLE AS $$
  SELECT m.montant_minor FROM public.tresorerie_mouvements m
    JOIN dur_pay p ON p.session_id::text = m.source_id AND p.code = p_code
   WHERE m.source_type = 'prestation' AND m.regle = 'remuneration_due'
     AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
SELECT pg_temp.vrai(pg_temp.paie('PAYA') = 236,
  '(E) seance d''adultes de 90 minutes : 1,57 USD x 1 eleve present x 1,5 h = 2,36 USD (235,5 arrondi) : la paie compte les 90 minutes de la seance');
SELECT pg_temp.vrai(pg_temp.paie('PAYB') = 157,
  '(E) la meme seance a l''ANCIENNE duree de 60 minutes : 1,57 USD x 1 x 1 h = 1,57 USD : la paie suit la duree ecrite sur la seance (+50 % : les deux seances sont TENUES 90 minutes, mais la paie compte la duree prevue des que la duree tenue atteint 70 minutes, et la duree prevue est 90 au lieu de 60)');

-- ==================================================================
-- (G) Corrections de relecture (23/10)
-- ==================================================================
CREATE FUNCTION pg_temp.detail_du_refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v_detail text;
BEGIN
  BEGIN
    PERFORM pg_temp.client(p_sql);
    RETURN 'aucun refus';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_detail = PG_EXCEPTION_DETAIL;
    RESET ROLE;
    RETURN SQLSTATE || ' | ' || SQLERRM || ' | ' || coalesce(v_detail, '');
  END;
END $$;

-- (G1) Les seances laissees par un deplacement precedent comptent : la Classe PHB
-- (jeudi 19 h) passe au vendredi 19 h, ses seances du jeudi 19 h restent planifiees ;
-- la Classe PHA (mercredi 19 h, meme enseignant) ne peut pas aller au jeudi 19 h.
SELECT pg_temp.qui(pg_temp.t('admin'), 'admin');
SELECT pg_temp.classe('PHB', 'tph', 'enfant', 4, 19);
SELECT pg_temp.classe('PHA', 'tph', 'enfant', 3, 19);
SELECT pg_temp.client(pg_temp.mv('PHB', 5, 19));
SELECT pg_temp.vrai(pg_temp.etat('PHB') = '5:19:Europe/Paris creneaux=5:19 seances=8'
  AND (SELECT count(*) FROM public.sessions s WHERE s.groupe_id = pg_temp.c('PHB') AND s.status = 'planned'
         AND extract(isodow FROM s.started_at AT TIME ZONE 'Europe/Paris') = 4) = 4,
  '(G1) PHB passe au vendredi 19 h ; ses 4 seances du jeudi 19 h restent planifiees (comportement d''avant)');
SELECT pg_temp.refus_client(pg_temp.mv('PHA', 4, 19), 'P0001', 'chevauchement avec une séance existante',
  '(G1) refus nomme (et non 23P01) : PHA ne peut pas aller au jeudi 19 h, les seances laissees par PHB y sont encore (autre Classe, meme enseignant)');
SELECT pg_temp.vrai(pg_temp.detail_du_refus(pg_temp.mv('PHA', 4, 19)) LIKE 'P0001 | chevauchement avec une séance existante | %autre Classe%',
  '(G1) ... le detail dit que c''est une AUTRE Classe ou une seance hors Classe de cet enseignant');
SELECT pg_temp.refus_client(format($q$INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local) VALUES (%L, 4, 19)$q$, pg_temp.c('PHA')),
  'P0001', 'chevauchement avec une séance existante',
  '(G1) refus nomme aussi pour une ecriture directe de groupe_creneaux (sinon le conflit se revelait a l''inscription d''un eleve)');
SELECT pg_temp.vrai(pg_temp.etat('PHA') = '3:19:Europe/Paris creneaux=3:19 seances=4',
  '(G1) ... rien d''ecrit pour PHA');
-- Les seances annulees ou supprimees ne comptent pas : 2 annulees, 2 supprimees.
UPDATE public.sessions SET status = 'canceled'
 WHERE id IN (SELECT s.id FROM public.sessions s WHERE s.groupe_id = pg_temp.c('PHB') AND s.status = 'planned'
                 AND extract(isodow FROM s.started_at AT TIME ZONE 'Europe/Paris') = 4 ORDER BY s.started_at LIMIT 2);
SELECT pg_temp.refus_client(pg_temp.mv('PHA', 4, 19), 'P0001', 'chevauchement avec une séance existante',
  '(G1) avec 2 seances annulees seulement, il en reste 2 qui comptent : toujours refuse');
UPDATE public.sessions SET deleted_at = now()
 WHERE groupe_id = pg_temp.c('PHB') AND status = 'planned'
   AND extract(isodow FROM started_at AT TIME ZONE 'Europe/Paris') = 4;
SELECT pg_temp.client(pg_temp.mv('PHA', 4, 19));
SELECT pg_temp.vrai(pg_temp.etat('PHA') LIKE '4:19:Europe/Paris creneaux=4:19 %',
  '(G1) les 2 seances annulees et les 2 seances supprimees ne comptent plus : PHA passe au jeudi 19 h');

-- (G1 bis) Une Classe d'adultes deplacee d'une heure : refusee tant que ses seances de l'ancien
-- horaire sont planifiees, acceptee une fois celles-ci annulees.
SELECT pg_temp.classe('XA', 'tph2', 'adulte', 3, 18);
SELECT pg_temp.refus_client(pg_temp.mv('XA', 3, 19), 'P0001', 'chevauchement avec une séance existante',
  '(G1 bis) refus : mercredi 18 h -> 19 h pour un cours de 90 minutes chevauche ses propres seances de l''ancien horaire');
UPDATE public.sessions SET status = 'canceled' WHERE groupe_id = pg_temp.c('XA') AND status = 'planned';
SELECT pg_temp.client(pg_temp.mv('XA', 3, 19));
SELECT pg_temp.vrai(pg_temp.etat('XA') = '3:19:Europe/Paris creneaux=3:19 seances=8'
  AND (SELECT count(*) FROM public.sessions s WHERE s.groupe_id = pg_temp.c('XA') AND s.status = 'planned') = 4,
  '(G1 bis) une fois les seances de l''ancien horaire annulees, le deplacement passe : 4 annulees + 4 planifiees au nouvel horaire');

-- (G1 ter) Une seance d'une autre Classe dont l'enseignant EFFECTIF est le notre (remplacant designe) compte.
SELECT pg_temp.classe('RX', 'tph2', 'enfant', 3, 17);
SELECT pg_temp.classe('RB', 'tcf1', 'enfant', 3, 21);
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
SELECT s.id, 'remplacement_designe_admin', pg_temp.t('tcf1'), pg_temp.t('tph2'), pg_temp.t('admin'), gen_random_uuid()
  FROM public.sessions s WHERE s.groupe_id = pg_temp.c('RB')
 ORDER BY s.started_at LIMIT 1;
SELECT pg_temp.refus_client(pg_temp.mv('RX', 3, 21), 'P0001', 'chevauchement avec une séance existante',
  '(G1 ter) refus : mercredi 21 h chevauche une seance de RB dont tph2 est le remplacant designe (enseignant effectif)');
SELECT pg_temp.vrai(pg_temp.etat('RX') = '3:17:Europe/Paris creneaux=3:17 seances=4', '(G1 ter) ... rien d''ecrit');

-- (G2) Un fuseau different ne couvre pas : les heures declarees le sont dans UN fuseau.
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.t('tdl'), 6, h, 'Asia/Tokyo' FROM unnest(ARRAY[10, 11]) h;
SELECT pg_temp.vrai(
  app_private.creneau_couvert_par_disponibilites(pg_temp.t('tdl'), 6, 10, 'Asia/Tokyo', 90)
  AND NOT app_private.creneau_couvert_par_disponibilites(pg_temp.t('tdl'), 6, 10, 'Europe/Paris', 90),
  '(G2) des heures declarees a Tokyo couvrent un creneau a Tokyo, pas le meme jour et la meme heure a Paris');

-- (G3) Une seance SUPPRIMEE d'un autre enseignant ne bloque pas l'alignement.
SELECT pg_temp.classe('CF5', 'tdl', 'adulte', 3, 18);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id, deleted_at)
VALUES ('d0b2c000-0000-4000-8000-0000000000a5', pg_temp.t('tcf2b'),
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '60 minutes',
        public.instant_creneau(3, 18, 'Europe/Paris', 0) + interval '120 minutes', 'planned', NULL, now());
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('d0b2c000-0000-4000-8000-0000000000a5', pg_temp.t('xtsa2'), 'student');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('CF5'), pg_temp.t('xtsa2'));
SELECT pg_temp.perime('CF5');
SELECT pg_temp.vrai(pg_temp.aligne('CF5') = 4,
  '(G3) une seance supprimee (d''un autre enseignant, avec le meme eleve inscrit) n''est pas un conflit : l''alignement passe');

-- (G4) Un alignement met a jour updated_at.
SELECT pg_temp.perime('ALI2');
UPDATE public.sessions SET updated_at = now() - interval '1 day' WHERE groupe_id = pg_temp.c('ALI2');
SELECT pg_temp.aligne('ALI2');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.sessions s WHERE s.groupe_id = pg_temp.c('ALI2')
                                   AND s.status = 'planned' AND s.updated_at < now() - interval '1 hour'),
  '(G4) les seances ecrites par l''alignement ont leur updated_at remis a jour');

-- (G5) Le verrou de la Classe est pris avant le controle de cle etrangere (interblocage).
SELECT pg_temp.vrai(
  (SELECT t.tgtype & 2 = 2 AND t.tgtype & 1 = 1 AND t.tgenabled = 'O'
     FROM pg_trigger t WHERE t.tgrelid = 'public.groupe_creneaux'::regclass AND t.tgname = 'groupe_creneaux_a_verrou_classe')
  AND (SELECT p.prosrc LIKE '%FOR UPDATE%' FROM pg_proc p WHERE p.oid = 'app_private.verrouiller_classe_du_creneau()'::regprocedure),
  '(G5) groupe_creneaux_a_verrou_classe est un declencheur BEFORE, par ligne, actif, qui prend FOR UPDATE sur la Classe (ordre des verrous : Classe, puis enseignant)');

-- (G6) Un reglage de duree hors de 15 a 240 minutes est refuse a l'ecriture.
SELECT pg_temp.refus_client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(300), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')),
  '22023', 'duree de seance : un nombre entier de minutes, de 15 a 240', '(G6) refus : 300 minutes');
SELECT pg_temp.refus_client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(14), updated_by = %L WHERE key = 'seance.duree_minutes_enfant'$q$, pg_temp.t('admin')),
  '22023', 'duree de seance : un nombre entier de minutes, de 15 a 240', '(G6) refus : 14 minutes');
SELECT pg_temp.refus_client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(90.5), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')),
  '22023', 'duree de seance : un nombre entier de minutes, de 15 a 240', '(G6) refus : 90,5 minutes (pas un entier)');
SELECT pg_temp.refus_client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb('quatre-vingt-dix'::text), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')),
  '22023', 'duree de seance : un nombre entier de minutes, de 15 a 240', '(G6) refus : un texte');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(95.0::numeric), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')));
SELECT pg_temp.vrai((SELECT c.value::text FROM public.app_config c WHERE c.key = 'seance.duree_minutes_adulte') = '95',
  '(G6) 95 minutes passe, ecrit comme entier');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(90), updated_by = %L WHERE key = 'seance.duree_minutes_adulte'$q$, pg_temp.t('admin')));
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(7), updated_by = %L WHERE key = 'seance.pause_minutes_adulte'$q$, pg_temp.t('admin')));
SELECT pg_temp.vrai((SELECT c.value::text FROM public.app_config c WHERE c.key = 'seance.pause_minutes_adulte') = '7',
  '(G6) les autres reglages ne sont pas touches par la validation');
SELECT pg_temp.client(format($q$UPDATE public.app_config SET value = pg_catalog.to_jsonb(0), updated_by = %L WHERE key = 'seance.pause_minutes_adulte'$q$, pg_temp.t('admin')));


-- ==================================================================
-- (F) Droits et forme (F86)
-- ==================================================================
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1
      FROM unnest(ARRAY[
        'app_private.creneaux_recurrents_se_chevauchent_durees(integer,integer,text,integer,integer,integer,text,integer)',
        'app_private.creneau_couvert_par_disponibilites(uuid,integer,integer,text,integer)',
        'app_private.seances_a_venir_a_realigner(uuid)',
        'app_private.aligner_seances_a_venir_sur_la_classe(uuid)',
        'app_private.verifier_horaire_contre_seances_planifiees(uuid)',
        'app_private.verifier_horaire_classe_avec_enseignant()',
        'app_private.verifier_creneau_classe_avec_enseignant()',
        'app_private.verrouiller_classe_du_creneau()',
        'app_private.duree_seance_reglage_valider()']) f(sig)
      CROSS JOIN unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r(rol)
     WHERE has_function_privilege(r.rol, f.sig::regprocedure, 'EXECUTE')),
  '(F) les neuf fonctions nouvelles ne sont executables par aucun role (anon, authenticated, service_role, agent_ro)');
SELECT pg_temp.vrai(
  (SELECT bool_and(p.prosecdef = (p.proname IN ('verifier_horaire_classe_avec_enseignant', 'verifier_creneau_classe_avec_enseignant', 'verrouiller_classe_du_creneau')) AND p.proconfig @> ARRAY['search_path=""']
                   AND pg_get_userbyid(p.proowner) = 'postgres')
     FROM pg_proc p
    WHERE p.oid IN ('app_private.creneaux_recurrents_se_chevauchent_durees(integer,integer,text,integer,integer,integer,text,integer)'::regprocedure,
                    'app_private.creneau_couvert_par_disponibilites(uuid,integer,integer,text,integer)'::regprocedure,
                    'app_private.seances_a_venir_a_realigner(uuid)'::regprocedure,
                    'app_private.aligner_seances_a_venir_sur_la_classe(uuid)'::regprocedure,
                    'app_private.verifier_horaire_contre_seances_planifiees(uuid)'::regprocedure,
                    'app_private.verifier_horaire_classe_avec_enseignant()'::regprocedure,
                    'app_private.verifier_creneau_classe_avec_enseignant()'::regprocedure,
                    'app_private.verrouiller_classe_du_creneau()'::regprocedure,
                    'app_private.duree_seance_reglage_valider()'::regprocedure)),
  '(F) a postgres, search_path vide ; les trois declencheurs de groupes et de groupe_creneaux sont SECURITY DEFINER, les six autres INVOKER');
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'public.materialiser_seances_groupe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.materialiser_seances_groupe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.materialiser_seances_groupe(uuid)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.materialiser_seances_groupe(uuid)', 'EXECUTE'),
  '(F) materialiser_seances_groupe reste executable par service_role seulement');
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.enseignants_pour_classe(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.enseignants_pour_public(text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.transferer_eleve(uuid,uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.enseignants_pour_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.enseignants_pour_public(text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.transferer_eleve(uuid,uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.enseignants_pour_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.enseignants_pour_public(text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.transferer_eleve(uuid,uuid,uuid,text)', 'EXECUTE'),
  '(F) les droits des trois autres fonctions de public sont ceux d''avant : authenticated oui, anon et agent_ro non');
SELECT pg_temp.vrai(
  (SELECT bool_and(p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] AND pg_get_userbyid(p.proowner) = 'postgres'
                   AND obj_description(p.oid, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(p.oid)) || '%')
     FROM pg_proc p
    WHERE p.oid IN ('public.materialiser_seances_groupe(uuid)'::regprocedure,
                    'public.enseignants_pour_classe(uuid)'::regprocedure,
                    'public.enseignants_pour_public(text)'::regprocedure,
                    'public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure)),
  '(F) les quatre fonctions de public touchees : DEFINER, a postgres, search_path vide, empreinte md5_functiondef a jour');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM pg_trigger t
    WHERE t.tgrelid = 'public.groupes'::regclass AND NOT t.tgisinternal AND t.tgenabled = 'O'
      AND t.tgname IN ('groupes_creneau_ancre', 'groupes_horaire_verifie_enseignant', 'tc_materialiser_apres_creation_groupe')) = 3
  AND (SELECT array_agg(t.tgname::text ORDER BY t.tgname COLLATE "C") FROM pg_trigger t
        WHERE t.tgrelid = 'public.groupes'::regclass AND NOT t.tgisinternal AND t.tgfoid::regprocedure::text LIKE ANY (ARRAY['%verifier_horaire%', '%groupe_creneau_ancre%', '%tc_materialiser%']))
      = ARRAY['groupes_creneau_ancre', 'groupes_horaire_verifie_enseignant', 'tc_materialiser_apres_creation_groupe'],
  '(F) les declencheurs de groupes tirent dans l''ordre : ancrage du creneau, verification de l''horaire, materialisation');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM pg_policies p WHERE p.schemaname = 'public' AND p.tablename = 'groupe_creneaux' AND p.policyname = 'groupe_creneaux_admin'),
  '(F) la policy groupe_creneaux_admin est toujours la : le controle passe par le declencheur, pas par son retrait');
SELECT pg_temp.refus_client($q$SELECT app_private.aligner_seances_a_venir_sur_la_classe()$q$, '42501', 'permission denied',
  '(F) un compte connecte ne peut pas lancer l''alignement des seances');
SELECT pg_temp.refus_client($q$SELECT app_private.verifier_horaire_classe_avec_enseignant()$q$, '42501', 'permission denied',
  '(F) ... ni appeler un declencheur');

SELECT pg_temp.vrai(coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int >= 125,
  'au moins 125 controles ont passe (126 avec celui-ci)');

ROLLBACK;
