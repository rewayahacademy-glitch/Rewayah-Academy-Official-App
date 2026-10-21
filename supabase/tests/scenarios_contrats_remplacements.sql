-- CONTRATS-MANQUANTS : tableau commun des remplacements
-- (PortRemplacements.suivre : offres_remplacement) et enseignants
-- proposables pour une classe a creer (PortEnseignantsClasse :
-- enseignants_pour_public). Chaque garde a un controle de refus.
-- A rejouer sur une base NEUVE.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role))::text;
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
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
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
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('cf000000-0000-4000-8000-0000000000a1','cf-admin@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000b1','cf-t1@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000b2','cf-t2@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000b3','cf-t3@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000b4','cf-t4@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000b5','cf-t5@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000d1','cf-g1@test.invalid'),
 ('cf000000-0000-4000-8000-0000000000e1','cf-e1@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('cf000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('cf000000-0000-4000-8000-0000000000a1','CF-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('cf000000-0000-4000-8000-0000000000b1','CF-ENS-0001','teacher',NULL,'Ibrahim','Titulaire','provisional_active','male'),
 ('cf000000-0000-4000-8000-0000000000b2','CF-ENS-0002','teacher',NULL,'Yusuf','Remplacant','provisional_active','male'),
 ('cf000000-0000-4000-8000-0000000000b3','CF-ENS-0003','teacher',NULL,'Maryam','Enseignante','provisional_active','female'),
 ('cf000000-0000-4000-8000-0000000000b4','CF-ENS-0004','teacher',NULL,'Desactive','Essai','disabled','male'),
 ('cf000000-0000-4000-8000-0000000000b5','CF-ENS-0005','teacher',NULL,'Bilal','Collegue','provisional_active','male'),
 ('cf000000-0000-4000-8000-0000000000d1','CF-TUT-0001','guardian','cf000000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('cf000000-0000-4000-8000-0000000000e1','CF-ELV-0001','student','cf000000-0000-4000-8000-0000000000f1','Adam','Foyer1','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('cf000000-0000-4000-8000-0000000000e1','minor','child');
INSERT INTO public.teacher_profiles(profile_id, kyc_status, languages, timezone_iana, country) VALUES
 ('cf000000-0000-4000-8000-0000000000b1','approved','{francais}','Europe/Paris','FR'),
 ('cf000000-0000-4000-8000-0000000000b2','approved','{francais}','Europe/Paris','FR'),
 ('cf000000-0000-4000-8000-0000000000b3','approved','{francais}','Europe/Paris','FR'),
 ('cf000000-0000-4000-8000-0000000000b4','approved','{francais}','Europe/Paris','FR'),
 ('cf000000-0000-4000-8000-0000000000b5','approved','{francais}','Europe/Paris','FR');
INSERT INTO public.weekly_availability(profile_id, weekday, hour_local, timezone_iana) VALUES
 ('cf000000-0000-4000-8000-0000000000b1',1,18,'Europe/Paris'),
 ('cf000000-0000-4000-8000-0000000000b2',1,18,'Europe/Paris'),
 ('cf000000-0000-4000-8000-0000000000b2',2,10,'Europe/Paris');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public) VALUES
 ('cf000000-0000-4000-8000-0000000000c1','cf000000-0000-4000-8000-0000000000b1','enfant',5,'Garçons essai',1,18,'Europe/Paris','hommes');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('cf000000-0000-4000-8000-0000000000c1','cf000000-0000-4000-8000-0000000000e1');
SELECT set_config('test.s', (SELECT id::text FROM public.sessions
  WHERE groupe_id = 'cf000000-0000-4000-8000-0000000000c1' AND status = 'planned' AND started_at > now()
  ORDER BY started_at LIMIT 1), true);

-- ------------------------------------------------------------
-- 1. ACL et F86
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.offres_remplacement()'::regprocedure,
                           'public.enseignants_pour_public(text)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : DEFINER, empreinte ou ACL de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('deux RPC DEFINER, empreinte reelle, authenticated seul');
END $acl$;
SELECT pg_temp.vrai(current_setting('test.s') <> '', 'fixture : une seance a venir de la classe');

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.offres_remplacement()$$, '42501', 'anon : offres refusees');
SELECT pg_temp.refus($$SELECT * FROM public.enseignants_pour_public('enfant')$$, '42501', 'anon : enseignants refuses');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Tableau commun des remplacements
-- ------------------------------------------------------------
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.offres_remplacement()$$, '42501', 'tuteur : offres refusees (garde enseignant)');
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b4','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.offres_remplacement()$$, '42501', 'enseignant desactive : offres refusees');
RESET ROLE;

SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.offres_remplacement() = '[]'::jsonb, 'aucune absence : aucune offre');
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT public.declarer_absence_seance(current_setting('test.s')::uuid, 'cf000000-0000-4000-8000-0000000000aa');
SELECT pg_temp.vrai(public.offres_remplacement() = '[]'::jsonb, 'le titulaire absent ne voit pas sa seance');
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b3','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.offres_remplacement() = '[]'::jsonb,
  'genre : une classe de garcons n''est pas proposee a une enseignante');
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
DO $offres$
DECLARE v jsonb;
BEGIN
  v := public.offres_remplacement();
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1 AND v -> 0 ->> 'seance_id' = current_setting('test.s')
    AND v -> 0 ->> 'etat' = 'ouverte' AND (v -> 0 ->> 'nb_eleves')::int = 1
    AND v -> 0 ->> 'classe' = 'Garçons essai' AND (v -> 0 ->> 'numero_dans_famille')::int = 1
    AND v -> 0 ->> 'debut' IS NOT NULL AND v -> 0 ->> 'fin' IS NOT NULL,
    'enseignant compatible : une offre ouverte (classe, numero, debut, fin, effectif)');
  PERFORM pg_temp.vrai(NOT v::text LIKE '%Titulaire%' AND NOT v::text LIKE '%male%' AND NOT v::text LIKE '%hommes%',
    'ni titulaire ni genre dans l''offre');
  PERFORM pg_temp.vrai(public.prendre_remplacement(current_setting('test.s')::uuid, 'cf000000-0000-4000-8000-0000000000ab') ->> 'etat' = 'acceptee',
    'acceptation (RPC existante)');
  PERFORM pg_temp.vrai(public.offres_remplacement() -> 0 ->> 'etat' = 'prise_par_moi', 'apres acceptation : prise par moi');
END $offres$;
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b5','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.offres_remplacement() -> 0 ->> 'etat' = 'prise_par_un_collegue'
  AND NOT public.offres_remplacement()::text LIKE '%Remplacant%',
  'collegue : offre prise par un collegue, sans son nom');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Enseignants pour une classe a creer
-- ------------------------------------------------------------
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT * FROM public.enseignants_pour_public('enfant')$$, '42501', 'enseignant : liste refusee (garde direction)');
RESET ROLE;
SELECT pg_temp.qui('cf000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT * FROM public.enseignants_pour_public('ado')$$, '22023', 'public inconnu refuse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.enseignants_pour_public('adulte')) = 4
  AND NOT EXISTS (SELECT 1 FROM public.enseignants_pour_public('adulte') WHERE teacher_id = 'cf000000-0000-4000-8000-0000000000b4'),
  'quatre enseignants valides, le compte desactive exclu, aucun filtre de genre');
SELECT pg_temp.vrai((SELECT titre_public = 'sayyida' FROM public.enseignants_pour_public('enfant')
                      WHERE teacher_id = 'cf000000-0000-4000-8000-0000000000b3')
  AND (SELECT titre_public = 'sayyid' FROM public.enseignants_pour_public('enfant')
        WHERE teacher_id = 'cf000000-0000-4000-8000-0000000000b2'),
  'titre public sayyid / sayyida');
SELECT pg_temp.vrai((SELECT classes_actives = 1 AND creneaux_libres = '[]'::jsonb
                        AND creneaux_pris = '[{"weekday": 1, "hour_local": 18, "timezone_iana": "Europe/Paris"}]'::jsonb
                      FROM public.enseignants_pour_public('enfant') WHERE teacher_id = 'cf000000-0000-4000-8000-0000000000b1'),
  'titulaire : sa classe est prise, sa disponibilite au meme creneau n''est plus libre');
SELECT pg_temp.vrai((SELECT classes_actives = 0 AND jsonb_array_length(creneaux_libres) = 2 AND creneaux_pris = '[]'::jsonb
                      FROM public.enseignants_pour_public('enfant') WHERE teacher_id = 'cf000000-0000-4000-8000-0000000000b2'),
  'enseignant libre : ses deux disponibilites rendues');
RESET ROLE;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 20 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 20 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CONTRATS remplacements : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
