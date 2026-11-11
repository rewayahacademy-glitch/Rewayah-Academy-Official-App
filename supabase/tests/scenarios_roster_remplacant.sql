-- ROSTER-REMPLACANT (08/11/2026) : public.groupe_roster_enseignant(uuid) est lisible par le
-- titulaire de la Classe (comme avant) ET par le remplacant d'une seance de la Classe non
-- passee depuis plus d'un jour (predicat de CAHIER-C1) ; pas par un tiers, pas par la
-- direction, pas par un remplacant d'une autre Classe ou d'une seance trop ancienne, pas par un
-- compte desactive. Signature et colonnes inchangees. ROUGE sans la migration (le remplacant
-- ne lit rien) ; VERT avec. Base NEUVE ; tout est annule a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ROSTER-REMPLACANT ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf900000-0000-4000-8000-0000000000' || p_n)::uuid $$;
-- Combien de lignes le roster de la Classe rend a cet appelant.
CREATE FUNCTION pg_temp.lignes(p_id uuid, p_role text, p_groupe uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v FROM public.groupe_roster_enseignant(p_groupe);
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- 01 titulaire T ; 02 remplacant R (seance en cours) ; 03 enseignant tiers X ; 04 direction ;
-- 05 eleve S de la Classe 1 ; 06 enseignant U, remplacant d'une seance finie depuis 3 jours ;
-- 07 enseignant V au compte desactive, remplacant de la seance en cours ; 08 remplacant W
-- d'une seance de la Classe 2 (pas de la Classe 1) ; 09 enseignant T2, titulaire de la Classe 2.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'roster-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05','06','07','08','09','10']) n;
INSERT INTO public.households (id, timezone) VALUES ('cf90ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'ROS-01', 'teacher', NULL, 'Ens', 'Titulaire', 'active', 'male'),
  (pg_temp.p('02'), 'ROS-02', 'teacher', NULL, 'Ens', 'Remplacant', 'active', 'male'),
  (pg_temp.p('03'), 'ROS-03', 'teacher', NULL, 'Ens', 'Tiers', 'active', 'male'),
  (pg_temp.p('04'), 'ROS-04', 'admin', NULL, 'Direction', 'Une', 'active', 'female'),
  (pg_temp.p('05'), 'ROS-05', 'student', 'cf90ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Roster', 'active', 'male'),
  (pg_temp.p('06'), 'ROS-06', 'teacher', NULL, 'Ens', 'Ancien', 'active', 'male'),
  (pg_temp.p('07'), 'ROS-07', 'teacher', NULL, 'Ens', 'Desactive', 'disabled', 'male'),
  (pg_temp.p('08'), 'ROS-08', 'teacher', NULL, 'Ens', 'AutreClasse', 'active', 'male'),
  (pg_temp.p('09'), 'ROS-09', 'teacher', NULL, 'Ens', 'TitulaireDeux', 'active', 'male'),
  (pg_temp.p('10'), 'ROS-10', 'student', 'cf90ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Deux', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT pg_temp.p(n), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry'
  FROM unnest(ARRAY['01','02','03','06','07','08','09']) n;
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  (pg_temp.p('05'), 'minor', 'standard'),
  (pg_temp.p('10'), 'minor', 'standard');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
  ('cf9000aa-0000-4000-8000-000000000001', pg_temp.p('01'), 'enfant', 5, 'Classe roster 1', 1, 9, 'Europe/Paris'),
  ('cf9000aa-0000-4000-8000-000000000002', pg_temp.p('09'), 'enfant', 5, 'Classe roster 2', 2, 9, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('cf9000aa-0000-4000-8000-000000000001', pg_temp.p('05')),
  ('cf9000aa-0000-4000-8000-000000000002', pg_temp.p('10'));
-- Classe 1 : une seance en cours (remplacee par R et par V), une seance finie depuis 3 jours
-- (remplacee par U). Classe 2 : une seance en cours remplacee par W.
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status, session_type) VALUES
  ('cf9000ee-0000-4000-8000-000000000001', pg_temp.p('01'), 'cf9000aa-0000-4000-8000-000000000001',
   now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard'),
  ('cf9000ee-0000-4000-8000-000000000002', pg_temp.p('01'), 'cf9000aa-0000-4000-8000-000000000001',
   now() - interval '3 days 1 hour', now() - interval '3 days', 'planned', 'standard'),
  ('cf9000ee-0000-4000-8000-000000000003', pg_temp.p('09'), 'cf9000aa-0000-4000-8000-000000000002',
   now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard');
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence) VALUES
  ('cf9000ee-0000-4000-8000-000000000001', 'remplacement_designe_admin', pg_temp.p('01'), pg_temp.p('02'), pg_temp.p('04'), 'cf9000ff-0000-4000-8000-000000000001'),
  ('cf9000ee-0000-4000-8000-000000000002', 'remplacement_designe_admin', pg_temp.p('01'), pg_temp.p('06'), pg_temp.p('04'), 'cf9000ff-0000-4000-8000-000000000002'),
  ('cf9000ee-0000-4000-8000-000000000003', 'remplacement_designe_admin', pg_temp.p('09'), pg_temp.p('08'), pg_temp.p('04'), 'cf9000ff-0000-4000-8000-000000000003');
SET LOCAL session_replication_role = origin;

-- a. Le titulaire lit, comme avant (meme quand sa seance est remplacee).
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('01'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 1,
  'a1 le titulaire de la Classe lit son roster, comme avant');
-- b. Le remplacant de la seance en cours lit.
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('02'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 1,
  'b1 le remplacant de la seance en cours lit le roster');
-- c. Refus.
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('03'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c1 un enseignant tiers ne lit rien');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('04'), 'admin', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c2 la direction ne lit pas ce roster (role teacher exige : la branche direction de CAHIER-C1 reste fermee)');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('06'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c3 le remplacant d''une seance finie depuis plus d''un jour ne lit plus rien');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('08'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c4 le remplacant d''une AUTRE Classe ne lit pas celle-ci');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('08'), 'teacher', 'cf9000aa-0000-4000-8000-000000000002') = 1,
  'c5 ... mais lit la sienne (Classe 2)');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('05'), 'student', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c6 un eleve ne lit pas le roster');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('02'), 'guardian', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'c7 meme identifiant sous un autre role : rien (role teacher exige)');
-- d. Compte desactive : le remplacant V n'est plus un compte valide.
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('cf9000ee-0000-4000-8000-000000000001', 'remplacement_designe_admin', pg_temp.p('01'), pg_temp.p('07'), pg_temp.p('04'), 'cf9000ff-0000-4000-8000-000000000004');
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('07'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'd1 un compte desactive, meme remplacant effectif, ne lit rien');
-- e. L'effectif est le DERNIER remplacant : R n'est plus effectif, il perd l'acces ; V (desactive) l'est.
SELECT pg_temp.vrai(pg_temp.lignes(pg_temp.p('02'), 'teacher', 'cf9000aa-0000-4000-8000-000000000001') = 0,
  'e1 un remplacant remplace par un autre perd l''acces (un seul circuit : l''enseignant effectif)');
-- f. Ce que rend la fonction : colonnes et valeurs inchangees.
SELECT pg_temp.qui(pg_temp.p('01'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT r.student_id = pg_temp.p('05') AND r.immutable_id = 'ROS-05' AND r.interface_mode = 'standard'
          AND r.first_name IN ('Eleve', 'ROS-05')
     FROM public.groupe_roster_enseignant('cf9000aa-0000-4000-8000-000000000001') r),
  'f1 la ligne rendue est celle d''avant (eleve, matricule, mode d''interface)');
RESET ROLE;
SELECT pg_temp.vrai(
  pg_catalog.pg_get_function_result('public.groupe_roster_enseignant(uuid)'::pg_catalog.regprocedure)
    = 'TABLE(student_id uuid, first_name text, immutable_id text, level text, riwaya text, interface_mode interface_mode, curriculum_path text, current_unit text, active_goals text[], resume_page integer, resume_sourate integer, resume_verset integer)',
  'f2 la signature et les colonnes sont inchangees');
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE'),
  'f3 droits inchanges : authenticated seul');
ROLLBACK;
