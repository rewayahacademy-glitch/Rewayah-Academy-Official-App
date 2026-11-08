-- MES-CLASSES-ETAPE (08/11/2026) : public.mes_classes_details() rend a l'enseignant, pour les Classes
-- actives dont il est TITULAIRE, l'etape du programme (version PUBLIEE seulement) et la langue.
-- Migration 20261122500000_mes_classes_details.sql. ROUGE sans la migration (la fonction n'existe
-- pas) ; VERT avec. Base NEUVE ; tout est annule a la fin.
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
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'MES-CLASSES ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cfa00000-0000-4000-8000-0000000000' || p_n)::uuid $$;
-- Les lignes que la fonction rend a cet appelant, en jsonb (une par Classe).
CREATE FUNCTION pg_temp.lues(p_id uuid, p_role text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.groupe_id), '[]'::jsonb) INTO v FROM public.mes_classes_details() d;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- 01 enseignant T (3 Classes actives + 1 terminee) ; 02 enseignant X (une Classe) ; 03 direction ;
-- 04 enseignant au compte desactive (une Classe) ; 05 eleve.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'mcd-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05']) n;
INSERT INTO public.households (id, timezone) VALUES ('cfa0ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'MCD-01', 'teacher', NULL, 'Ens', 'Titulaire', 'active', 'male'),
  (pg_temp.p('02'), 'MCD-02', 'teacher', NULL, 'Ens', 'Autre', 'active', 'male'),
  (pg_temp.p('03'), 'MCD-03', 'admin', NULL, 'Direction', 'Une', 'active', 'female'),
  (pg_temp.p('04'), 'MCD-04', 'teacher', NULL, 'Ens', 'Desactive', 'disabled', 'male'),
  (pg_temp.p('05'), 'MCD-05', 'student', 'cfa0ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Un', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT pg_temp.p(n), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry' FROM unnest(ARRAY['01','02','04']) n;
-- Programme : v1 PUBLIEE (etapes 1 et 2), v2 BROUILLON (etape 1 renommee), v0 ARCHIVEE (etape 1).
INSERT INTO public.programme_versions (id, statut, numero_version, cree_par, publiee_par, publiee_at) VALUES
  ('cfa000bb-0000-4000-8000-000000000001', 'publiee',  9101, pg_temp.p('03'), pg_temp.p('03'), now()),
  ('cfa000bb-0000-4000-8000-000000000002', 'brouillon', 9102, pg_temp.p('03'), NULL, NULL),
  ('cfa000bb-0000-4000-8000-000000000003', 'archivee',  9100, pg_temp.p('03'), pg_temp.p('03'), now() - interval '30 days');
INSERT INTO public.programme_niveaux (id, version_id, code_technique, nom_humain, cycle, ordre) VALUES
  ('cfa000cc-0000-4000-8000-000000000001', 'cfa000bb-0000-4000-8000-000000000001', 'MCD-A1', 'Les lettres', 'bases', 1),
  ('cfa000cc-0000-4000-8000-000000000002', 'cfa000bb-0000-4000-8000-000000000001', 'MCD-A2', 'Lire avec les voyelles', 'bases', 2),
  ('cfa000cc-0000-4000-8000-000000000003', 'cfa000bb-0000-4000-8000-000000000002', 'MCD-A1', 'Brouillon : les lettres', 'bases', 1),
  ('cfa000cc-0000-4000-8000-000000000004', 'cfa000bb-0000-4000-8000-000000000003', 'MCD-A1', 'Ancienne etape', 'bases', 1);
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, langue_code, programme_niveau_id, ended_at, ended_by, end_reason) VALUES
  -- T : etape publiee 2 + langue ; etape d'un brouillon ; sans etape ; terminee.
  ('cfa000aa-0000-4000-8000-000000000001', pg_temp.p('01'), 'enfant', 5, 'MCD publiee', 1, 9, 'Europe/Paris', 'francais', 'cfa000cc-0000-4000-8000-000000000002', NULL, NULL, NULL),
  ('cfa000aa-0000-4000-8000-000000000002', pg_temp.p('01'), 'enfant', 5, 'MCD brouillon', 2, 9, 'Europe/Paris', NULL, 'cfa000cc-0000-4000-8000-000000000003', NULL, NULL, NULL),
  ('cfa000aa-0000-4000-8000-000000000003', pg_temp.p('01'), 'enfant', 5, 'MCD sans etape', 3, 9, 'Europe/Paris', NULL, NULL, NULL, NULL, NULL),
  ('cfa000aa-0000-4000-8000-000000000004', pg_temp.p('01'), 'enfant', 5, 'MCD terminee', 4, 9, 'Europe/Paris', 'francais', 'cfa000cc-0000-4000-8000-000000000001', now(), pg_temp.p('03'), 'Fixture : classe terminee'),
  ('cfa000aa-0000-4000-8000-000000000005', pg_temp.p('01'), 'enfant', 5, 'MCD archivee', 5, 9, 'Europe/Paris', NULL, 'cfa000cc-0000-4000-8000-000000000004', NULL, NULL, NULL),
  -- X et le compte desactive : leurs propres Classes.
  ('cfa000aa-0000-4000-8000-000000000006', pg_temp.p('02'), 'enfant', 5, 'MCD de X', 6, 9, 'Europe/Paris', 'francais', 'cfa000cc-0000-4000-8000-000000000001', NULL, NULL, NULL),
  ('cfa000aa-0000-4000-8000-000000000007', pg_temp.p('04'), 'enfant', 5, 'MCD desactive', 7, 9, 'Europe/Paris', 'francais', 'cfa000cc-0000-4000-8000-000000000001', NULL, NULL, NULL);
SET LOCAL session_replication_role = origin;

-- a. Le titulaire lit l'etape et la langue de ses Classes ACTIVES, et d'elles seules.
SELECT pg_temp.vrai((SELECT jsonb_array_length(pg_temp.lues(pg_temp.p('01'), 'teacher'))) = 4,
  'a1 le titulaire lit ses 4 Classes actives (la terminee n''y est pas)');
SELECT pg_temp.vrai(
  (SELECT x ->> 'etape_ordre' = '2' AND x ->> 'etape_nom' = 'Lire avec les voyelles'
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('01'), 'teacher')) x
    WHERE x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000001'),
  'a2 etape d''une version PUBLIEE : ordre et nom');
SELECT pg_temp.vrai(
  (SELECT x ->> 'langue' IS NOT NULL AND x ->> 'langue' <> 'francais'
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('01'), 'teacher')) x
    WHERE x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000001'),
  'a3 la langue est le nom lisible de langues_cours, pas le code');
-- b. Jamais l'etape d'un brouillon ni d'une version archivee ; NULL, rien d'invente.
SELECT pg_temp.vrai(
  (SELECT (x -> 'etape_ordre') = 'null'::jsonb AND (x -> 'etape_nom') = 'null'::jsonb
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('01'), 'teacher')) x
    WHERE x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000002'),
  'b1 etape d''un BROUILLON : NULL');
SELECT pg_temp.vrai(
  (SELECT (x -> 'etape_ordre') = 'null'::jsonb
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('01'), 'teacher')) x
    WHERE x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000005'),
  'b2 etape d''une version ARCHIVEE : NULL');
SELECT pg_temp.vrai(
  (SELECT (x -> 'etape_ordre') = 'null'::jsonb AND (x -> 'langue') = 'null'::jsonb
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('01'), 'teacher')) x
    WHERE x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000003'),
  'b3 Classe sans etape ni langue : NULL, la ligne existe quand meme');
-- c. Refus : seulement ses Classes, seulement un enseignant au compte valide.
SELECT pg_temp.vrai(
  (SELECT bool_and(x ->> 'groupe_id' = 'cfa000aa-0000-4000-8000-000000000006')
     FROM jsonb_array_elements(pg_temp.lues(pg_temp.p('02'), 'teacher')) x)
  AND jsonb_array_length(pg_temp.lues(pg_temp.p('02'), 'teacher')) = 1,
  'c1 un autre enseignant ne lit que SA Classe');
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lues(pg_temp.p('03'), 'admin')) = 0,
  'c2 la direction ne lit rien par cette fonction');
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lues(pg_temp.p('04'), 'teacher')) = 0,
  'c3 un compte desactive ne lit rien');
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lues(pg_temp.p('05'), 'student')) = 0,
  'c4 un eleve ne lit rien');
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lues(pg_temp.p('01'), 'guardian')) = 0,
  'c5 meme identifiant sous un autre role : rien (role teacher exige)');
-- d. Droits.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.mes_classes_details()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.mes_classes_details()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.mes_classes_details()', 'EXECUTE'),
  'd1 EXECUTE pour authenticated seul');
-- e. Ce que rend la liste officielle n'est pas change : mes_groupes_v voit les memes Classes actives.
SELECT pg_temp.qui(pg_temp.p('01'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.mes_groupes_v) = (SELECT count(*) FROM public.mes_classes_details()),
  'e1 la fonction couvre exactement les Classes de mes_groupes_v');
RESET ROLE;
ROLLBACK;
