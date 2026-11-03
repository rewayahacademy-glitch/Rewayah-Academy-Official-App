-- N1 (02/11/2026) : capacites Communications, regles de portee, alertes de la
-- direction. Tout s'execute en `authenticated` (B2), jamais en postgres seul :
--   1. capacites par role et par objet (com_mes_capacites) ;
--   2. la matrice (com_regles_audience) dit ce que com_annonce_publier fait ;
--   3. un tuteur et un enseignant ecrivent dans un meme fil ;
--   4. un signalement « securite d'un enfant » depose par un enseignant est
--      lu en tete par la direction (signalements_ouverts_direction) ;
--   5. droits : ni anon, ni service_role, ni agent_ro.
-- A rejouer sur une base NEUVE : tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role,
      'household_id', (SELECT p.household_id FROM public.profiles p WHERE p.id = p_id)))::text;
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
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('a1000000-0000-4000-8000-000000000001','n1-admin@test.invalid'),
 ('a1000000-0000-4000-8000-000000000002','n1-t1@test.invalid'),
 ('a1000000-0000-4000-8000-000000000003','n1-t2@test.invalid'),
 ('a1000000-0000-4000-8000-000000000004','n1-g1@test.invalid'),
 ('a1000000-0000-4000-8000-000000000005','n1-e1@test.invalid'),
 ('a1000000-0000-4000-8000-000000000006','n1-ctrl@test.invalid'),
 ('a1000000-0000-4000-8000-000000000007','n1-compta@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('a1000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('a1000000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('a1000000-0000-4000-8000-000000000001','N1ADMIN00001','admin','a1000000-0000-4000-8000-0000000000f2','Ad','Min','active','male'),
 ('a1000000-0000-4000-8000-000000000002','N1TEACH00001','teacher','a1000000-0000-4000-8000-0000000000f2','Tariq','Un','provisional_active','male'),
 ('a1000000-0000-4000-8000-000000000003','N1TEACH00002','teacher','a1000000-0000-4000-8000-0000000000f2','Sana','Deux','provisional_active','female'),
 ('a1000000-0000-4000-8000-000000000004','N1GUARD00001','guardian','a1000000-0000-4000-8000-0000000000f1','Gina','Tuteur','active','female'),
 ('a1000000-0000-4000-8000-000000000005','N1STUD000001','student','a1000000-0000-4000-8000-0000000000f1','Elyas','Eleve','active','male'),
 ('a1000000-0000-4000-8000-000000000006','N1CTRL000001','controller','a1000000-0000-4000-8000-0000000000f2','Co','Ntrol','active','male'),
 ('a1000000-0000-4000-8000-000000000007','N1COMPTA0001','accountant','a1000000-0000-4000-8000-0000000000f2','Comp','Table','active','female');
INSERT INTO public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana) VALUES
 ('a1000000-0000-4000-8000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris'),
 ('a1000000-0000-4000-8000-000000000003', array['francais'], 10, 'approved', 'Europe/Paris');
UPDATE public.households SET primary_guardian_id = 'a1000000-0000-4000-8000-000000000004'
 WHERE id = 'a1000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
VALUES ('a1000000-0000-4000-8000-000000000005', 'minor', 'child');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('a1000000-0000-4000-8000-0000000000c1', 'a1000000-0000-4000-8000-000000000002',
        'enfant', 5, 'N1 Classe An-Nour', 1, 10);
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('a1000000-0000-4000-8000-0000000000c1', 'a1000000-0000-4000-8000-000000000005');

SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------
-- 1. Capacites par role et par objet
-- ------------------------------------------------------------
DO $capacites$
DECLARE
  c jsonb;
BEGIN
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000001', 'admin');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai(c = '{"publier_annonce":true,"programmer":true,"ecrire_dans_fil":true,"envoyer_vocal":false}'::jsonb,
    'direction : publier, programmer, ecrire ; jamais de vocal');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000002', 'teacher');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai((c ->> 'publier_annonce')::boolean AND NOT (c ->> 'programmer')::boolean
    AND (c ->> 'ecrire_dans_fil')::boolean, 'enseignant avec Classe : publier et ecrire, pas programmer');
  c := public.com_mes_capacites('classe', 'a1000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai((c ->> 'publier_annonce')::boolean AND (c ->> 'ecrire_dans_fil')::boolean,
    'enseignant sur SA Classe : publier et ecrire');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000003', 'teacher');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai(NOT (c ->> 'publier_annonce')::boolean, 'enseignant sans Classe : pas de publication');
  c := public.com_mes_capacites('classe', 'a1000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(NOT (c ->> 'publier_annonce')::boolean AND NOT (c ->> 'ecrire_dans_fil')::boolean,
    'enseignant sur la Classe d''un autre : ni publier ni ecrire');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000004', 'guardian');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai(NOT (c ->> 'publier_annonce')::boolean AND (c ->> 'ecrire_dans_fil')::boolean,
    'tuteur : ecrire, jamais publier');
  c := public.com_mes_capacites('classe', 'a1000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai((c ->> 'ecrire_dans_fil')::boolean, 'tuteur sur la Classe de son enfant : ecrire');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000006', 'controller');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai(NOT (c ->> 'ecrire_dans_fil')::boolean AND NOT (c ->> 'publier_annonce')::boolean,
    'controleur : ni ecrire ni publier hors de sa mission');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000007', 'accountant');
  c := public.com_mes_capacites();
  PERFORM pg_temp.vrai((c ->> 'ecrire_dans_fil')::boolean AND NOT (c ->> 'publier_annonce')::boolean,
    'comptable : ecrire (profil de paiement), pas publier');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000005', 'student');
  PERFORM pg_temp.refus('SELECT public.com_mes_capacites()', '42501', 'eleve mineur : refuse');
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000004', 'teacher');
  PERFORM pg_temp.refus('SELECT public.com_mes_capacites()', '42501', 'role du jeton different du compte : refuse');
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000001', 'admin');
  PERFORM pg_temp.refus($q$SELECT public.com_mes_capacites('classe', NULL)$q$, '22023', 'objet incomplet : refuse');
  PERFORM pg_temp.refus($q$SELECT public.com_mes_capacites('inconnu', gen_random_uuid())$q$, '22023', 'objet inconnu : refuse');
END
$capacites$;

-- ------------------------------------------------------------
-- 2. La matrice redit com_annonce_publier
-- ------------------------------------------------------------
DO $regles$
DECLARE
  r jsonb;
  v_ligne jsonb;
BEGIN
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000001', 'admin');
  r := public.com_regles_audience();
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(r) = 6, 'six lignes de regles');
  SELECT x INTO v_ligne FROM pg_catalog.jsonb_array_elements(r) x WHERE x ->> 'id' = 'direction';
  PERFORM pg_temp.vrai((v_ligne ->> 'peut_publier')::boolean AND v_ligne ->> 'portee' = 'toute_audience',
    'regle direction : toute audience');
  PERFORM pg_temp.vrai((public.com_annonce_publier('toutes', 'N1 Annonce', 'Texte N1', NULL,
    gen_random_uuid()) ->> 'etat') = 'publiee', 'direction : annonce a toute l''academie publiee');

  SELECT x INTO v_ligne FROM pg_catalog.jsonb_array_elements(r) x WHERE x ->> 'id' = 'enseignants';
  PERFORM pg_temp.vrai(v_ligne ->> 'portee' = 'sa_classe', 'regle enseignants : sa Classe');
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000002', 'teacher');
  PERFORM pg_temp.vrai((public.com_annonce_publier('classe:a1000000-0000-4000-8000-0000000000c1',
    'N1 Classe', 'Texte', NULL, gen_random_uuid()) ->> 'etat') = 'publiee', 'enseignant : annonce de sa Classe publiee');
  PERFORM pg_temp.refus($q$SELECT public.com_annonce_publier('toutes', 'x', 'y', NULL, gen_random_uuid())$q$,
    '42501', 'enseignant : toute l''academie refusee, comme la regle le dit');
  PERFORM pg_temp.refus('SELECT public.com_regles_audience()', '42501', 'enseignant : matrice refusee');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000004', 'guardian');
  SELECT x INTO v_ligne FROM pg_catalog.jsonb_array_elements(r) x WHERE x ->> 'id' = 'familles';
  PERFORM pg_temp.vrai(NOT (v_ligne ->> 'peut_publier')::boolean, 'regle familles : aucune publication');
  PERFORM pg_temp.refus($q$SELECT public.com_annonce_publier('classe:a1000000-0000-4000-8000-0000000000c1', 'x', 'y', NULL, gen_random_uuid())$q$,
    '42501', 'tuteur : publication refusee, comme la regle le dit');
END
$regles$;

-- ------------------------------------------------------------
-- 3. Un tuteur et un enseignant ecrivent dans un meme fil
-- ------------------------------------------------------------
DO $fil$
DECLARE
  f jsonb;
  v_fil uuid;
  v_n integer;
BEGIN
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000004', 'guardian');
  f := public.com_ouvrir_conversation('classe', 'a1000000-0000-4000-8000-0000000000c1',
    'a1000000-0000-4000-8000-000000000002');
  PERFORM pg_temp.vrai(f IS NOT NULL AND (f ->> 'peut_ecrire')::boolean, 'tuteur : conversation ouverte avec l''enseignant');
  v_fil := (f ->> 'id')::uuid;
  PERFORM public.com_envoyer_message(v_fil, 'Bonjour, une question du tuteur.', gen_random_uuid());

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000002', 'teacher');
  PERFORM public.com_envoyer_message(v_fil, 'Bonjour, reponse de l''enseignant.', gen_random_uuid());
  SELECT pg_catalog.jsonb_array_length(public.com_lire_fil(v_fil) -> 'messages') INTO v_n;
  PERFORM pg_temp.vrai(v_n = 2, 'enseignant : les deux messages se lisent');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000003', 'teacher');
  PERFORM pg_temp.refus(pg_catalog.format('SELECT public.com_envoyer_message(%L, %L, gen_random_uuid())', v_fil, 'intrus'),
    '42501', 'autre enseignant : envoi refuse par la barriere serveur');
END
$fil$;

-- ------------------------------------------------------------
-- 4. Le signalement d'un enseignant arrive chez la direction
-- ------------------------------------------------------------
DO $signalement$
DECLARE
  v_premier jsonb;
BEGIN
  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000002', 'teacher');
  PERFORM public.deposer_student_concern('pedagogique', 'a1000000-0000-4000-8000-0000000000c1', NULL,
    'N1STUD000001', 'N1 note ordinaire', NULL);
  PERFORM public.deposer_student_concern('securite_enfant', 'a1000000-0000-4000-8000-0000000000c1', NULL,
    'N1STUD000001', 'N1 note securite', NULL);
  PERFORM pg_temp.refus('SELECT public.signalements_ouverts_direction()', 'P0001',
    'enseignant : la file de la direction est refusee');

  PERFORM pg_temp.qui('a1000000-0000-4000-8000-000000000001', 'admin');
  SELECT s INTO v_premier FROM public.signalements_ouverts_direction() s
   WHERE s ->> 'academy_id' = 'N1STUD000001' LIMIT 1;
  PERFORM pg_temp.vrai(v_premier ->> 'categorie' = 'securite_enfant'
    AND (v_premier ->> 'prioritaire')::boolean
    AND v_premier ->> 'internal_details' = 'N1 note securite',
    'direction : le signalement de securite d''un enfant en tete, avec sa note');
END
$signalement$;

RESET ROLE;

-- ------------------------------------------------------------
-- 5. Droits
-- ------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY['public.com_mes_capacites(text,uuid)'::regprocedure,
                               'public.com_regles_audience()'::regprocedure] LOOP
    PERFORM pg_temp.vrai(pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE'),
      'droits de ' || v_oid::text);
  END LOOP;
END
$droits$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus('SELECT public.com_mes_capacites()', '42501', 'anon : aucun droit');
RESET ROLE;

ROLLBACK;
\o
\echo 'N1 communications : tous les controles sont passes.'
