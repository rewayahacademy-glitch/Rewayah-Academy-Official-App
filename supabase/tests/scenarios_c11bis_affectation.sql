-- C11BIS-AFFECTATION (21/10/2026, CAND-Q15, lot c11bis), migration
-- 20261021210100 : une classe nee d'un regroupement recoit son enseignant.
--   * affecter_enseignant_classe_c11bis delegue a
--     tc_verifier_affectation_enseignant puis affecte : classe active, seances
--     au nom de l'enseignant, ligne d'audit, demande passee a
--     enseignant_affecte, notification au tuteur principal dans le fuseau du
--     foyer pour la premiere seance future (M-b de 0075) ;
--   * rejeu du meme choix (reponse perdue puis nouvel appui) : affecte, sans
--     seance, audit ni notification de plus (relecture du lot) ;
--   * deja_affecte (autre enseignant) ne change rien ; chevauchement par
--     instant (Paris 18 h et
--     Londres 17 h) refuse (preuve de DECISION-CLASSES-SIMULTANEES:48) ;
--     genre incompatible refuse ; la garde F86 reste au mot pres (42501) ;
--   * regroupements_c11bis_admin rend la capacite calculee dans ses deux
--     branches (:299 regroupement ouvert, :403 classe en attente) : vraie pour
--     une classe en attente ; une fois la classe active, elle n'est plus
--     rattachee ni listee comme en attente, et la demande encore ouverte sur
--     sa cle redevient un regroupement ordinaire, sans classe (relecture du
--     lot : avant, la classe active restait rangee sous "Enseignant a
--     confirmer") ;
--   * affecter_enseignant_classe(uuid,uuid) reste fermee (L3-06).
-- Chaque classe porte un langue_code valide que les enseignants ont dans
-- languages : sans cela la jointure interne de la branche :403 ne rend rien
-- et le predicat refuse pour la langue.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object('app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Refus attendu : SQLSTATE exact ET message exact.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR SQLERRM <> p_message THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %, %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Capacite rendue pour une classe : 'g:' = branche :403, sinon :299.
CREATE FUNCTION pg_temp.capacite(p_lignes jsonb, p_classe uuid, p_branche_403 boolean)
RETURNS boolean
LANGUAGE sql AS $$
  SELECT (l -> 'classe' ->> 'peut_affecter_enseignant')::boolean
    FROM pg_catalog.jsonb_array_elements(p_lignes) l
   WHERE l -> 'classe' ->> 'classe_id' = p_classe::text
     AND (l ->> 'regroupement_id' LIKE 'g:%') = p_branche_403
$$;

CREATE FUNCTION pg_temp.lignes(p_lignes jsonb, p_classe uuid, p_branche_403 boolean)
RETURNS integer
LANGUAGE sql AS $$
  SELECT pg_catalog.count(*)::integer
    FROM pg_catalog.jsonb_array_elements(p_lignes) l
   WHERE l -> 'classe' ->> 'classe_id' = p_classe::text
     AND (l ->> 'regroupement_id' LIKE 'g:%') = p_branche_403
$$;

-- ------------------------------------------------------------------
-- Fixtures
--   A  direction active ; T1 enseignant, T2 enseignante, pieces validees,
--      francais, lundi 18 h Paris (T2 aussi mercredi 18 h) ;
--   P1 tuteur principal du foyer H1 (fuseau America/Toronto, different de
--      celui de la classe : la notification doit suivre le foyer) ;
--   S1 eleve de G1 (demande classe_validee) ; S2 enfant et S3 adulte avec
--      une demande envoyee qui ouvre un regroupement sur la cle de G1, G3.
--   G1 en attente, lundi 18 h Paris, public hommes ;
--   G2 en attente au meme instant (lundi 17 h Londres), public indetermine ;
--   G3 en attente, adultes, public hommes, mercredi 18 h Paris.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('c11b0000-0000-0000-0000-000000000001', 'c11b-admin@example.test'),
  ('c11b0000-0000-0000-0000-000000000002', 'c11b-t1@example.test'),
  ('c11b0000-0000-0000-0000-000000000003', 'c11b-t2@example.test'),
  ('c11b0000-0000-0000-0000-000000000004', 'c11b-p1@example.test'),
  ('c11b0000-0000-0000-0000-000000000005', 'c11b-s1@example.test'),
  ('c11b0000-0000-0000-0000-000000000006', 'c11b-s2@example.test'),
  ('c11b0000-0000-0000-0000-000000000007', 'c11b-s3@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('c11b0000-0000-0000-0000-000000000101', 'America/Toronto'),
  ('c11b0000-0000-0000-0000-000000000102', 'Europe/Paris'),
  ('c11b0000-0000-0000-0000-000000000103', 'Europe/Paris');

-- Enseignants en provisional_active : l'activation passe par la signature
-- du NDA (hors de ce scenario), et le predicat accepte ce statut.
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
VALUES
  ('c11b0000-0000-0000-0000-000000000001', 'C11B-ADMIN', 'admin', NULL,
   'Direction', 'C11B', 'male', 'active'),
  ('c11b0000-0000-0000-0000-000000000002', 'C11B-T1', 'teacher', NULL,
   'Enseignant', 'Un', 'male', 'provisional_active'),
  ('c11b0000-0000-0000-0000-000000000003', 'C11B-T2', 'teacher', NULL,
   'Enseignante', 'Deux', 'female', 'provisional_active'),
  ('c11b0000-0000-0000-0000-000000000004', 'C11B-P1', 'guardian',
   'c11b0000-0000-0000-0000-000000000101', 'Tuteur', 'Un', 'female', 'active'),
  ('c11b0000-0000-0000-0000-000000000005', 'C11B-S1', 'student',
   'c11b0000-0000-0000-0000-000000000101', 'Eleve', 'Un', 'male', 'active'),
  ('c11b0000-0000-0000-0000-000000000006', 'C11B-S2', 'student',
   'c11b0000-0000-0000-0000-000000000102', 'Eleve', 'Deux', 'male', 'active'),
  ('c11b0000-0000-0000-0000-000000000007', 'C11B-S3', 'student',
   'c11b0000-0000-0000-0000-000000000103', 'Eleve', 'Trois', 'male', 'active');

UPDATE public.households
   SET primary_guardian_id = 'c11b0000-0000-0000-0000-000000000004'
 WHERE id = 'c11b0000-0000-0000-0000-000000000101';

INSERT INTO public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('c11b0000-0000-0000-0000-000000000002', ARRAY['francais'], 10, 'approved', 'Europe/Paris'),
  ('c11b0000-0000-0000-0000-000000000003', ARRAY['francais'], 10, 'approved', 'Europe/Paris');

INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES
  ('c11b0000-0000-0000-0000-000000000002', 1, 18, 'Europe/Paris'),
  ('c11b0000-0000-0000-0000-000000000003', 1, 18, 'Europe/Paris'),
  ('c11b0000-0000-0000-0000-000000000003', 3, 18, 'Europe/Paris');

INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy,
   langue_cours, cohorte, niveau_declare, objectif)
VALUES
  ('c11b0000-0000-0000-0000-000000000005', 'minor', 'child', 'forbidden',
   'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'),
  ('c11b0000-0000-0000-0000-000000000006', 'minor', 'child', 'forbidden',
   'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'),
  ('c11b0000-0000-0000-0000-000000000007', 'autonomous', 'standard', 'forbidden',
   'francais', 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire');

INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat)
VALUES
  ('c11b0000-0000-0000-0000-000000000201', NULL, 'enfant', 5, 'C11B G1', 1, 18,
   'Europe/Paris', 'francais', 'hommes', 'debut_lettres', 'en_attente_enseignant'),
  ('c11b0000-0000-0000-0000-000000000202', NULL, 'enfant', 5, 'C11B G2', 1, 17,
   'Europe/London', 'francais', 'indetermine', 'debut_lettres', 'en_attente_enseignant'),
  ('c11b0000-0000-0000-0000-000000000203', NULL, 'adulte', 6, 'C11B G3', 3, 18,
   'Europe/Paris', 'francais', 'hommes', 'lecture_lente', 'en_attente_enseignant');

INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
   source, etat, groupe_id)
VALUES
  ('c11b0000-0000-0000-0000-000000000301', 'c11b0000-0000-0000-0000-000000000005',
   'enfant', 'francais', 'Europe/Paris', ARRAY[1]::smallint[], ARRAY[18]::smallint[],
   'personnalisee', 'envoyee', NULL),
  ('c11b0000-0000-0000-0000-000000000302', 'c11b0000-0000-0000-0000-000000000006',
   'enfant', 'francais', 'Europe/Paris', ARRAY[1]::smallint[], ARRAY[18]::smallint[],
   'personnalisee', 'envoyee', NULL),
  ('c11b0000-0000-0000-0000-000000000303', 'c11b0000-0000-0000-0000-000000000007',
   'adulte', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], ARRAY[18]::smallint[],
   'personnalisee', 'envoyee', NULL);

-- S1 suit le chemin reel : demande envoyee, classe validee, eleve integre.
UPDATE public.demandes_horaires_famille
   SET etat = 'classe_validee', groupe_id = 'c11b0000-0000-0000-0000-000000000201'
 WHERE id = 'c11b0000-0000-0000-0000-000000000301';
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('c11b0000-0000-0000-0000-000000000201', 'c11b0000-0000-0000-0000-000000000005');

-- ------------------------------------------------------------------
-- 1. Catalogue : corps, empreintes, droits.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)') IS NOT NULL
  AND pg_catalog.strpos(pg_catalog.pg_get_functiondef(
        pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)')),
        'compatibilite enseignant non verifiable') = 0
  AND pg_catalog.strpos(pg_catalog.pg_get_functiondef(
        pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)')),
        'PERFORM public.tc_verifier_affectation_enseignant(') > 0,
  'c11bis : refus inconditionnel retire, predicat appele');
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_proc p
   WHERE p.oid IN (pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)'),
                   pg_catalog.to_regprocedure('public.regroupements_c11bis_admin()'))
     AND (NOT p.prosecdef OR p.proowner <> 'postgres'::regrole
          OR NOT (p.proconfig @> ARRAY['search_path=""'])
          OR pg_catalog.strpos(coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), ''),
               'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || ';') = 0
          OR pg_catalog.strpos(coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), ''),
               'fail-closed') > 0))
  AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
        WHERE p.oid IN (pg_catalog.to_regprocedure('public.affecter_enseignant_classe_c11bis(uuid,uuid)'),
                        pg_catalog.to_regprocedure('public.regroupements_c11bis_admin()'))) = 2,
  'c11bis et regroupements : DEFINER, proprietaire, search_path vide, empreinte F86 exacte');
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.affecter_enseignant_classe_c11bis(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.affecter_enseignant_classe_c11bis(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.affecter_enseignant_classe_c11bis(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.affecter_enseignant_classe_c11bis(uuid,uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.regroupements_c11bis_admin()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.regroupements_c11bis_admin()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.regroupements_c11bis_admin()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.regroupements_c11bis_admin()', 'EXECUTE'),
  'droits : authenticated seul');
SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.pg_get_functiondef(
    pg_catalog.to_regprocedure('public.regroupements_c11bis_admin()')),
    '''peut_affecter_enseignant'', false') = 0,
  'regroupements : plus aucune capacite en dur');

-- ------------------------------------------------------------------
-- 2. Avant affectation : capacite vraie dans les deux branches.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('test.lignes',
  (SELECT coalesce(pg_catalog.jsonb_agg(l), '[]'::jsonb)
     FROM public.regroupements_c11bis_admin() l)::text, true);
RESET ROLE;

SELECT pg_temp.vrai(
  pg_temp.lignes(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000201', false) = 1
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000201', false),
  'branche :299 : regroupement ouvert sur la cle de G1 en attente, capacite vraie');
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000203', false) = 1
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000203', false),
  'branche :299 : regroupement adulte sur la cle de G3 en attente, capacite vraie');
SELECT pg_temp.vrai(
  pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000201', true)
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000202', true)
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000203', true),
  'branche :403 : G1, G2 et G3 en attente, capacite vraie');

-- ------------------------------------------------------------------
-- 3. Garde F86 au mot pres : 42501, meme message.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(
  $$SELECT public.affecter_enseignant_classe_c11bis('c11b0000-0000-0000-0000-000000000201', 'c11b0000-0000-0000-0000-000000000002')$$,
  '42501', 'affectation reservee a l''administration',
  'un enseignant ne s''affecte pas lui-meme (42501)');
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SELECT pg_temp.refus(
  $$SELECT public.affecter_enseignant_classe_c11bis('c11b0000-0000-0000-0000-000000000201', NULL)$$,
  '42501', 'affectation reservee a l''administration',
  'argument nul refuse par la seconde garde (42501)');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. _c11bis(G1, T1) : affecte.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('test.res',
  public.affecter_enseignant_classe_c11bis(
    'c11b0000-0000-0000-0000-000000000201', 'c11b0000-0000-0000-0000-000000000002'), true);
RESET ROLE;

SELECT pg_temp.vrai(pg_catalog.current_setting('test.res') = 'affecte',
  '_c11bis(G1, T1) rend affecte');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.groupes
   WHERE id = 'c11b0000-0000-0000-0000-000000000201'
     AND teacher_id = 'c11b0000-0000-0000-0000-000000000002' AND etat = 'active'),
  'G1 active, T1 enseignant');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sessions
    WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201') > 0
  AND NOT EXISTS (SELECT 1 FROM public.sessions
    WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201'
      AND teacher_id IS DISTINCT FROM 'c11b0000-0000-0000-0000-000000000002'),
  'seances de G1 generees au nom de T1');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.audit_logs
   WHERE action = 'enseignant_affecte_classe' AND table_name = 'groupes'
     AND row_id = 'c11b0000-0000-0000-0000-000000000201'
     AND actor = 'c11b0000-0000-0000-0000-000000000001'
     AND payload ->> 'teacher_id' = 'c11b0000-0000-0000-0000-000000000002'),
  'ligne d''audit enseignant_affecte_classe');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.demandes_horaires_famille
   WHERE id = 'c11b0000-0000-0000-0000-000000000301' AND etat = 'enseignant_affecte'),
  'demande de S1 passee a enseignant_affecte');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications
    WHERE evenement = 'enseignant_affecte'
      AND params ->> 'groupe_id' = 'c11b0000-0000-0000-0000-000000000201') = 1
  AND EXISTS (
    SELECT 1 FROM public.notifications n
     WHERE n.evenement = 'enseignant_affecte'
       AND n.destinataire = 'c11b0000-0000-0000-0000-000000000004'
       AND n.foyer_id = 'c11b0000-0000-0000-0000-000000000101'
       AND n.destination = '/tuteur/demandes'
       AND n.params ->> 'groupe_id' = 'c11b0000-0000-0000-0000-000000000201'
       AND n.params ->> 'debut_local' = (
         SELECT pg_catalog.to_char(pg_catalog.min(s.started_at) AT TIME ZONE 'America/Toronto',
                                   'YYYY-MM-DD"T"HH24:MI:SS')
           FROM public.sessions s
          WHERE s.groupe_id = 'c11b0000-0000-0000-0000-000000000201'
            AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now())),
  'une notification au tuteur principal, heure du foyer, premiere seance future');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.min(s.started_at) FROM public.sessions s
    WHERE s.groupe_id = 'c11b0000-0000-0000-0000-000000000201' AND s.deleted_at IS NULL
      AND s.started_at > pg_catalog.now()) > pg_catalog.now()
  AND (SELECT n.params ->> 'debut_local' FROM public.notifications n
        WHERE n.evenement = 'enseignant_affecte'
          AND n.params ->> 'groupe_id' = 'c11b0000-0000-0000-0000-000000000201')
      IS DISTINCT FROM (
        SELECT pg_catalog.to_char(pg_catalog.min(s.started_at) AT TIME ZONE 'Europe/Paris',
                                  'YYYY-MM-DD"T"HH24:MI:SS')
          FROM public.sessions s
         WHERE s.groupe_id = 'c11b0000-0000-0000-0000-000000000201'
           AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now()),
  'date future, et lue dans le fuseau du foyer, pas celui de la classe (M-b)');

-- ------------------------------------------------------------------
-- 4 bis. Rejeu du meme choix : _c11bis(G1, T1) une seconde fois (reponse
--        perdue, puis "Pressez de nouveau"). affecte, et rien n'est
--        reecrit : ni seance, ni notification, ni ligne d'audit. Avant la
--        relecture du lot, ce rejeu rendait deja_affecte et l'ecran disait
--        qu'un autre membre de la direction avait confirme.
-- ------------------------------------------------------------------
SELECT pg_catalog.set_config('test.seances_g1',
  (SELECT pg_catalog.count(*) FROM public.sessions
    WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201')::text, true);
SELECT pg_catalog.set_config('test.notifications',
  (SELECT pg_catalog.count(*) FROM public.notifications)::text, true);
SELECT pg_catalog.set_config('test.audit',
  (SELECT pg_catalog.count(*) FROM public.audit_logs
    WHERE action = 'enseignant_affecte_classe')::text, true);
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('test.res',
  public.affecter_enseignant_classe_c11bis(
    'c11b0000-0000-0000-0000-000000000201', 'c11b0000-0000-0000-0000-000000000002'), true);
RESET ROLE;
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.res') = 'affecte'
  AND EXISTS (SELECT 1 FROM public.groupes
               WHERE id = 'c11b0000-0000-0000-0000-000000000201'
                 AND teacher_id = 'c11b0000-0000-0000-0000-000000000002' AND etat = 'active')
  AND (SELECT pg_catalog.count(*) FROM public.sessions
        WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201')::text
      = pg_catalog.current_setting('test.seances_g1')
  AND (SELECT pg_catalog.count(*) FROM public.notifications)::text
      = pg_catalog.current_setting('test.notifications')
  AND (SELECT pg_catalog.count(*) FROM public.notifications
        WHERE evenement = 'enseignant_affecte'
          AND params ->> 'groupe_id' = 'c11b0000-0000-0000-0000-000000000201') = 1
  AND (SELECT pg_catalog.count(*) FROM public.audit_logs
        WHERE action = 'enseignant_affecte_classe')::text
      = pg_catalog.current_setting('test.audit'),
  '_c11bis(G1, T1) rejoue : affecte, sans seance, notification ni audit de plus');

-- ------------------------------------------------------------------
-- 5. _c11bis(G1, T2) : deja_affecte, rien ne change.
-- ------------------------------------------------------------------
SELECT pg_catalog.set_config('test.seances_g1',
  (SELECT pg_catalog.count(*) FROM public.sessions
    WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201')::text, true);
SELECT pg_catalog.set_config('test.notifications',
  (SELECT pg_catalog.count(*) FROM public.notifications)::text, true);
SELECT pg_catalog.set_config('test.audit',
  (SELECT pg_catalog.count(*) FROM public.audit_logs
    WHERE action = 'enseignant_affecte_classe')::text, true);
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('test.res',
  public.affecter_enseignant_classe_c11bis(
    'c11b0000-0000-0000-0000-000000000201', 'c11b0000-0000-0000-0000-000000000003'), true);
RESET ROLE;
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.res') = 'deja_affecte'
  AND EXISTS (SELECT 1 FROM public.groupes
               WHERE id = 'c11b0000-0000-0000-0000-000000000201'
                 AND teacher_id = 'c11b0000-0000-0000-0000-000000000002' AND etat = 'active')
  AND (SELECT pg_catalog.count(*) FROM public.sessions
        WHERE groupe_id = 'c11b0000-0000-0000-0000-000000000201')::text
      = pg_catalog.current_setting('test.seances_g1')
  AND (SELECT pg_catalog.count(*) FROM public.notifications)::text
      = pg_catalog.current_setting('test.notifications')
  AND (SELECT pg_catalog.count(*) FROM public.audit_logs
        WHERE action = 'enseignant_affecte_classe')::text
      = pg_catalog.current_setting('test.audit'),
  '_c11bis(G1, T2) rend deja_affecte : enseignant, seances, notifications et audit inchanges');

-- ------------------------------------------------------------------
-- 6. _c11bis(G2, T1) : chevauchement par instant (Londres 17 h = Paris 18 h).
-- 7. _c11bis(G3, T2) : genre incompatible.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(
  $$SELECT public.affecter_enseignant_classe_c11bis('c11b0000-0000-0000-0000-000000000202', 'c11b0000-0000-0000-0000-000000000002')$$,
  'P0001', 'chevauchement avec une classe ou affectation active',
  '_c11bis(G2, T1) refuse : T1 a deja G1 au meme instant');
SELECT pg_temp.refus(
  $$SELECT public.affecter_enseignant_classe_c11bis('c11b0000-0000-0000-0000-000000000203', 'c11b0000-0000-0000-0000-000000000003')$$,
  'P0001', 'enseignant incompatible avec le public de la classe',
  '_c11bis(G3, T2) refuse : enseignante pour un public hommes');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.groupes
    WHERE id IN ('c11b0000-0000-0000-0000-000000000202', 'c11b0000-0000-0000-0000-000000000203')
      AND teacher_id IS NULL AND etat = 'en_attente_enseignant') = 2
  AND NOT EXISTS (SELECT 1 FROM public.sessions
    WHERE groupe_id IN ('c11b0000-0000-0000-0000-000000000202', 'c11b0000-0000-0000-0000-000000000203')),
  'refus avant toute ecriture : G2 et G3 en attente, sans seance');

-- ------------------------------------------------------------------
-- 8. Apres affectation : G1 active n'est plus presentee comme une classe qui
--    attend son enseignant. La demande ouverte de S2, sur la cle de G1,
--    redevient un regroupement ordinaire, sans classe rattachee.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_catalog.set_config('test.lignes',
  (SELECT coalesce(pg_catalog.jsonb_agg(l), '[]'::jsonb)
     FROM public.regroupements_c11bis_admin() l)::text, true);
RESET ROLE;
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000201', false) = 0
  AND pg_temp.lignes(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000201', true) = 0
  AND (SELECT pg_catalog.count(*)
         FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.lignes')::jsonb) l
        WHERE l ->> 'regroupement_id' NOT LIKE 'g:%'
          AND l ->> 'type_public' = 'enfant'
          AND l ->> 'genre_public' = 'hommes'
          AND l ->> 'niveau' = 'debut_lettres'
          AND l -> 'occurrences' = '[{"jour_iso": 1, "heure": 18, "minute": 0}]'::jsonb
          AND (l ->> 'nombre_eleves')::int = 1
          AND pg_catalog.jsonb_typeof(l -> 'classe') = 'null') = 1,
  'G1 active : ni :299 ni :403 ne la rendent en attente ; la demande de S2 sur sa cle reste, sans classe');
SELECT pg_temp.vrai(
  pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000202', true)
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000203', true)
  AND pg_temp.capacite(pg_catalog.current_setting('test.lignes')::jsonb, 'c11b0000-0000-0000-0000-000000000203', false),
  'G2 et G3 toujours en attente : capacite vraie dans les deux branches');

-- ------------------------------------------------------------------
-- 9. L3-06 tient : affecter_enseignant_classe(uuid,uuid) fermee.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'public.affecter_enseignant_classe(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.affecter_enseignant_classe(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.affecter_enseignant_classe(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.affecter_enseignant_classe(uuid,uuid)', 'EXECUTE'),
  'affecter_enseignant_classe : executable par aucun role');
SELECT pg_temp.qui('c11b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(
  $$SELECT public.affecter_enseignant_classe('c11b0000-0000-0000-0000-000000000202', 'c11b0000-0000-0000-0000-000000000003')$$,
  '42501', 'permission denied for function affecter_enseignant_classe',
  'affecter_enseignant_classe refusee a la direction valide (42501)');
RESET ROLE;

DO $fin$
BEGIN
  IF pg_catalog.current_setting('test.r_n')::int <> 25 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 25 attendus', pg_catalog.current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'C11BIS-AFFECTATION : % controles verts', pg_catalog.current_setting('test.r_n');
END $fin$;

ROLLBACK;
