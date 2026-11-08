-- MESURE-LECTURE (08/11/2026) : public.lire_resultats_evaluations(uuid) rend les
-- resultats REALISES d'un eleve a lui-meme, a son tuteur (mineur du foyer), au
-- titulaire de sa classe et au remplacant de la seance en cours ; a personne d'autre.
-- Ni notes ni evaluateur dans le resultat. Migration 20261121900000_mesure_lecture.sql.
-- ROUGE sans la migration (la fonction n'existe pas) ; VERT avec. Base NEUVE ; tout est
-- annule a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'MESURE-LECTURE ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf800000-0000-4000-8000-0000000000' || p_n)::uuid $$;
-- Combien de resultats la session lit pour cet eleve (p_cible NULL = pour soi).
CREATE FUNCTION pg_temp.lus(p_id uuid, p_role text, p_foyer uuid, p_cible uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v FROM public.lire_resultats_evaluations(p_cible);
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- 01 enseignant T (titulaire) ; 02 enseignant T2 (autre classe) ; 03 eleve S mineur (foyer 1) ;
-- 04 tuteur de S (foyer 1) ; 05 eleve S5 d'un autre foyer ; 06 direction ; 07 tuteur d'un autre foyer ;
-- 08 enseignant remplacant de la seance en cours ; 09 eleve adulte du foyer 1 ;
-- 10 tuteur de S au compte desactive ; 11 enseignant T3, ancien de rien.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'mesure-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05','06','07','08','09','10','11','12']) n;
INSERT INTO public.households (id, timezone) VALUES
  ('cf80ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris'),
  ('cf80ffff-ffff-4fff-8fff-000000000002', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'MES-01', 'teacher', NULL, 'Ens', 'Titulaire', 'active', 'male'),
  (pg_temp.p('02'), 'MES-02', 'teacher', NULL, 'Ens', 'Autre', 'active', 'male'),
  (pg_temp.p('03'), 'MES-03', 'student', 'cf80ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Mineur', 'active', 'male'),
  (pg_temp.p('04'), 'MES-04', 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Un', 'active', 'female'),
  (pg_temp.p('05'), 'MES-05', 'student', 'cf80ffff-ffff-4fff-8fff-000000000002', 'Eleve', 'Tiers', 'active', 'male'),
  (pg_temp.p('06'), 'MES-06', 'admin', NULL, 'Direction', 'Une', 'active', 'female'),
  (pg_temp.p('07'), 'MES-07', 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000002', 'Tuteur', 'Deux', 'active', 'female'),
  (pg_temp.p('08'), 'MES-08', 'teacher', NULL, 'Ens', 'Remplacant', 'active', 'male'),
  (pg_temp.p('09'), 'MES-09', 'student', 'cf80ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Adulte', 'active', 'male'),
  (pg_temp.p('10'), 'MES-10', 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Suspendu', 'disabled', 'female'),
  (pg_temp.p('11'), 'MES-11', 'teacher', NULL, 'Ens', 'Sans', 'active', 'male'),
  (pg_temp.p('12'), 'MES-12', 'student', 'cf80ffff-ffff-4fff-8fff-000000000002', 'Eleve', 'Sorti', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana) VALUES
  (pg_temp.p('01'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry'),
  (pg_temp.p('02'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry'),
  (pg_temp.p('08'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry'),
  (pg_temp.p('11'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  (pg_temp.p('03'), 'minor', 'standard'),
  (pg_temp.p('05'), 'minor', 'standard'),
  (pg_temp.p('09'), 'autonomous', 'standard'),
  (pg_temp.p('12'), 'minor', 'standard');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
  ('cf8000aa-0000-4000-8000-000000000001', pg_temp.p('01'), 'enfant', 5, 'Classe mesure 1', 1, 9, 'Europe/Paris'),
  ('cf8000aa-0000-4000-8000-000000000002', pg_temp.p('02'), 'enfant', 5, 'Classe mesure 2', 2, 9, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id, left_at, left_by, left_reason) VALUES
  ('cf8000aa-0000-4000-8000-000000000001', pg_temp.p('03'), NULL, NULL, NULL),
  ('cf8000aa-0000-4000-8000-000000000001', pg_temp.p('12'), now(), pg_temp.p('06'), 'Fixture : sorti de la classe'),
  ('cf8000aa-0000-4000-8000-000000000002', pg_temp.p('05'), NULL, NULL, NULL);
-- Programme et evaluations : S a deux resultats realises (dont des notes privees) et une
-- evaluation seulement planifiee ; S5 a un resultat realise.
INSERT INTO public.programme_versions (id, statut, numero_version, cree_par, publiee_par, publiee_at)
VALUES ('cf8000bb-0000-4000-8000-000000000001', 'publiee', 9001, pg_temp.p('06'), pg_temp.p('06'), now());
INSERT INTO public.programme_niveaux (id, version_id, code_technique, nom_humain, cycle, ordre) VALUES
  ('cf8000cc-0000-4000-8000-000000000001', 'cf8000bb-0000-4000-8000-000000000001', 'MES-N1', 'Premiere etape', 'bases', 1),
  ('cf8000cc-0000-4000-8000-000000000002', 'cf8000bb-0000-4000-8000-000000000001', 'MES-N2', 'Deuxieme etape', 'bases', 2);
INSERT INTO public.evaluations (id, student_id, niveau_id, type, statut, date_prevue, date_realisee, resultat, evaluateur_id, notes) VALUES
  ('cf8000dd-0000-4000-8000-000000000001', pg_temp.p('03'), 'cf8000cc-0000-4000-8000-000000000001', 'periodique', 'realisee',
   current_date - 20, current_date - 20, 'reussi', pg_temp.p('06'), 'NOTE PRIVEE A'),
  ('cf8000dd-0000-4000-8000-000000000002', pg_temp.p('03'), 'cf8000cc-0000-4000-8000-000000000002', 'periodique', 'realisee',
   current_date - 5, current_date - 5, 'a_revoir', pg_temp.p('06'), 'NOTE PRIVEE B'),
  ('cf8000dd-0000-4000-8000-000000000003', pg_temp.p('03'), 'cf8000cc-0000-4000-8000-000000000002', 'reevaluation', 'planifiee',
   current_date + 10, NULL, NULL, NULL, NULL),
  ('cf8000dd-0000-4000-8000-000000000004', pg_temp.p('05'), 'cf8000cc-0000-4000-8000-000000000001', 'periodique', 'realisee',
   current_date - 3, current_date - 3, 'echec', pg_temp.p('06'), NULL),
  ('cf8000dd-0000-4000-8000-000000000005', pg_temp.p('09'), 'cf8000cc-0000-4000-8000-000000000001', 'periodique', 'realisee',
   current_date - 3, current_date - 3, 'reussi', pg_temp.p('06'), NULL),
  ('cf8000dd-0000-4000-8000-000000000006', pg_temp.p('12'), 'cf8000cc-0000-4000-8000-000000000001', 'periodique', 'realisee',
   current_date - 3, current_date - 3, 'reussi', pg_temp.p('06'), NULL);
-- Une seance de la classe de S EN COURS, confiee au remplacant 08.
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status, session_type)
VALUES ('cf8000ee-0000-4000-8000-000000000001', pg_temp.p('01'), 'cf8000aa-0000-4000-8000-000000000001',
        now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard');
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('cf8000ee-0000-4000-8000-000000000001', 'remplacement_designe_admin', pg_temp.p('01'), pg_temp.p('08'),
        pg_temp.p('06'), 'cf8000ff-0000-4000-8000-000000000001');
SET LOCAL session_replication_role = origin;

-- a. Les ayants droit lisent les deux resultats REALISES (jamais la planifiee).
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('03'), 'student', 'cf80ffff-ffff-4fff-8fff-000000000001', NULL) = 2,
  'a1 l''eleve lit ses deux resultats realises, pas l''evaluation planifiee');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', pg_temp.p('03')) = 2,
  'a2 le tuteur lit ceux de son enfant mineur');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('01'), 'teacher', NULL, pg_temp.p('03')) = 2,
  'a3 le titulaire de la classe les lit');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('08'), 'teacher', NULL, pg_temp.p('03')) = 2,
  'a4 le remplacant les lit pendant la seance qu''il assure');

-- b. Refus : personne d'autre.
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('07'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000002', pg_temp.p('03')) = 0,
  'b1 le tuteur d''un autre foyer ne lit rien');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('02'), 'teacher', NULL, pg_temp.p('03')) = 0,
  'b2 l''enseignant d''une autre classe ne lit rien');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('11'), 'teacher', NULL, pg_temp.p('03')) = 0,
  'b3 l''enseignant sans classe ne lit rien');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('10'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', pg_temp.p('03')) = 0,
  'b4 un tuteur au compte desactive ne lit rien');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('05'), 'student', 'cf80ffff-ffff-4fff-8fff-000000000002', pg_temp.p('03')) = 0,
  'b5 un eleve ne lit pas ceux d''un autre eleve (le parametre ne l''emporte pas)');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', pg_temp.p('09')) = 0,
  'b6 le tuteur ne lit pas ceux d''un adulte de son foyer');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001', pg_temp.p('05')) = 0,
  'b7 le tuteur ne lit pas ceux d''un enfant d''un autre foyer');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('01'), 'teacher', NULL, pg_temp.p('05')) = 0,
  'b8 le titulaire ne lit pas ceux d''un eleve d''une autre classe');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('01'), 'teacher', NULL, pg_temp.p('12')) = 0,
  'b10 le titulaire ne lit pas ceux d''un eleve sorti de sa classe');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('09'), 'student', 'cf80ffff-ffff-4fff-8fff-000000000001', NULL) = 1,
  'b9 l''eleve adulte lit les siens (un seul)');

-- c. Le remplacant perd l'acces quand la seance est finie.
SELECT pg_temp.qui(pg_temp.p('06'), 'admin');
UPDATE public.sessions SET started_at = now() - interval '3 hours', ended_at = now() - interval '2 hours'
 WHERE id = 'cf8000ee-0000-4000-8000-000000000001';
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('08'), 'teacher', NULL, pg_temp.p('03')) = 0,
  'c1 le remplacant ne lit plus rien une fois la seance finie');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('01'), 'teacher', NULL, pg_temp.p('03')) = 2,
  'c2 le titulaire garde son acces');

-- Le prenom de l'eleve accompagne le resultat (famille de plusieurs enfants).
SELECT pg_temp.qui(pg_temp.p('04'), 'guardian', 'cf80ffff-ffff-4fff-8fff-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT count(*) = 2 AND bool_and(r.prenom = 'Eleve' AND r.student_id = pg_temp.p('03'))
     FROM public.lire_resultats_evaluations(pg_temp.p('03')) r),
  'e1 chaque resultat porte l''identifiant et le prenom de l''eleve');
RESET ROLE;

-- d. Ni notes ni evaluateur dans ce qui sort ; droits d'execution.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc pr
               WHERE pr.oid = 'public.lire_resultats_evaluations(uuid)'::regprocedure
                 AND pr.proargnames::text ~ '(notes|evaluateur)'),
  'd1 aucun champ notes ni evaluateur dans le resultat');
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.lire_resultats_evaluations(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.lire_resultats_evaluations(uuid)', 'EXECUTE'),
  'd2 EXECUTE pour authenticated, pas pour anon');
-- La table reste fermee : l'eleve ne la lit toujours pas directement.
SELECT pg_temp.qui(pg_temp.p('03'), 'student', 'cf80ffff-ffff-4fff-8fff-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.evaluations) = 0, 'd3 la table evaluations reste fermee a l''eleve');
RESET ROLE;
ROLLBACK;
