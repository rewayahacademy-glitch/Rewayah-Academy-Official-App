-- CONTRATS-MANQUANTS : support actif (PortSupportActif), travail a venir
-- (PortTravailAVenir via assignations_a_venir) et prerequis de l'enseignant
-- (PrerequisEnseignant). Chaque garde a un controle de refus.
-- A rejouer sur une base NEUVE (fixtures inserees puis annulees).
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('cd000000-0000-4000-8000-0000000000a1','cd-admin@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b1','cd-t1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b2','cd-t2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b3','cd-t3@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b4','cd-t4@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000d1','cd-g1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000d2','cd-g2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000e1','cd-e1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000e2','cd-e2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000e3','cd-e3@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('cd000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('cd000000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('cd000000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('cd000000-0000-4000-8000-0000000000a1','CD-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('cd000000-0000-4000-8000-0000000000b1','CD-ENS-0001','teacher',NULL,'Ibrahim','Exemple','provisional_active','male'),
 ('cd000000-0000-4000-8000-0000000000b2','CD-ENS-0002','teacher',NULL,'Maryam','Modele','provisional_active','female'),
 ('cd000000-0000-4000-8000-0000000000b3','CD-ENS-0003','teacher',NULL,'Sans','Profil','provisional_active','male'),
 ('cd000000-0000-4000-8000-0000000000b4','CD-ENS-0004','teacher',NULL,'Desactive','Essai','disabled','male'),
 ('cd000000-0000-4000-8000-0000000000d1','CD-TUT-0001','guardian','cd000000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('cd000000-0000-4000-8000-0000000000d2','CD-TUT-0002','guardian','cd000000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('cd000000-0000-4000-8000-0000000000e1','CD-ELV-0001','student','cd000000-0000-4000-8000-0000000000f1','Yasmine','Foyer1','active','female'),
 ('cd000000-0000-4000-8000-0000000000e2','CD-ELV-0002','student','cd000000-0000-4000-8000-0000000000f2','Adam','Foyer2','active','male'),
 ('cd000000-0000-4000-8000-0000000000e3','CD-ELV-0003','student','cd000000-0000-4000-8000-0000000000f3','Lina','Foyer3','active','female');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('cd000000-0000-4000-8000-0000000000e1','minor','child'),
 ('cd000000-0000-4000-8000-0000000000e2','minor','child'),
 ('cd000000-0000-4000-8000-0000000000e3','minor','child');
INSERT INTO public.teacher_profiles(profile_id, kyc_status, languages, timezone_iana, country, photo_storage_key) VALUES
 ('cd000000-0000-4000-8000-0000000000b1','approved','{}','Europe/Paris',NULL,NULL),
 ('cd000000-0000-4000-8000-0000000000b2','approved','{francais}','Europe/Paris','FR','enseignants/cd-b2/photo.webp'),
 ('cd000000-0000-4000-8000-0000000000b4','approved','{francais}','Europe/Paris','FR',NULL);
INSERT INTO public.weekly_availability(profile_id, weekday, hour_local, timezone_iana) VALUES
 ('cd000000-0000-4000-8000-0000000000b2',3,10,'Europe/Paris');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour Essai',1,18,'Europe/Paris'),
 ('cd000000-0000-4000-8000-0000000000c2','cd000000-0000-4000-8000-0000000000b2','enfant',5,'Al-Fajr Essai',2,10,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000e1'),
 ('cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000e3'),
 ('cd000000-0000-4000-8000-0000000000c2','cd000000-0000-4000-8000-0000000000e2');
-- Une seance de la classe 1, dans dix semaines.
INSERT INTO public.sessions(id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES ('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-0000000000b1','cd000000-0000-4000-8000-0000000000c1',
        public.instant_creneau(1, 18, 'Europe/Paris', 10),
        public.instant_creneau(1, 18, 'Europe/Paris', 10) + interval '60 min', 'planned');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-0000000000b1','teacher'),
 ('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-0000000000e1','student');

-- Bibliotheque : R1 attribue et en regle, R2 attribue aux droits echus,
-- R3 attribue puis retire du catalogue, R4 en regle mais non attribue.
INSERT INTO public.library_resource(id, title, short_title, resource_type, access_policy, offline_policy) VALUES
 ('cd000000-0000-4000-8000-000000000071','Support un','S1','pdf','groupe_assigne','jamais'),
 ('cd000000-0000-4000-8000-000000000072','Support deux','S2','pdf','groupe_assigne','jamais'),
 ('cd000000-0000-4000-8000-000000000073','Support trois','S3','pdf','groupe_assigne','jamais'),
 ('cd000000-0000-4000-8000-000000000074','Support quatre','S4','pdf','groupe_assigne','jamais');
INSERT INTO public.resource_version(id, resource_id, numero_version, statut) VALUES
 ('cd000000-0000-4000-8000-000000000081','cd000000-0000-4000-8000-000000000071',1,'brouillon'),
 ('cd000000-0000-4000-8000-000000000082','cd000000-0000-4000-8000-000000000072',1,'brouillon'),
 ('cd000000-0000-4000-8000-000000000083','cd000000-0000-4000-8000-000000000073',1,'brouillon'),
 ('cd000000-0000-4000-8000-000000000084','cd000000-0000-4000-8000-000000000074',1,'brouillon');
INSERT INTO public.download_asset(id, resource_version_id, format, cle_stockage, taille_octets, origine) VALUES
 ('cd000000-0000-4000-8000-000000000091','cd000000-0000-4000-8000-000000000081','pdf','supports/cd000000-0000-4000-8000-000000000091/1/un.pdf',128,'importe_tel_quel'),
 ('cd000000-0000-4000-8000-000000000092','cd000000-0000-4000-8000-000000000082','pdf','supports/cd000000-0000-4000-8000-000000000092/1/deux.pdf',128,'importe_tel_quel'),
 ('cd000000-0000-4000-8000-000000000093','cd000000-0000-4000-8000-000000000083','pdf','supports/cd000000-0000-4000-8000-000000000093/1/trois.pdf',128,'importe_tel_quel'),
 ('cd000000-0000-4000-8000-000000000094','cd000000-0000-4000-8000-000000000084','pdf','supports/cd000000-0000-4000-8000-000000000094/1/quatre.pdf',128,'importe_tel_quel');
UPDATE public.resource_version SET download_asset_id = ('cd000000-0000-4000-8000-0000000000' || (substr(id::text, 35, 2)::int + 10)::text)::uuid
 WHERE id::text LIKE 'cd000000-0000-4000-8000-00000000008_';
INSERT INTO public.library_version_rights(resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
SELECT v, 'Source essai', 'Titulaire essai', ARRAY['application','classe'], 'Attribution essai', true,
       'cd000000-0000-4000-8000-0000000000a1', now()
FROM unnest(ARRAY['cd000000-0000-4000-8000-000000000081','cd000000-0000-4000-8000-000000000082',
                  'cd000000-0000-4000-8000-000000000083','cd000000-0000-4000-8000-000000000084']::uuid[]) v;
SELECT set_config('request.jwt.claim.sub', 'cd000000-0000-4000-8000-0000000000a1', true);
UPDATE public.resource_version SET statut = 'publiee' WHERE id::text LIKE 'cd000000-0000-4000-8000-00000000008_';
UPDATE public.library_resource r SET current_version_id = v.id
  FROM public.resource_version v WHERE v.resource_id = r.id AND r.id::text LIKE 'cd000000-0000-4000-8000-00000000007_';
INSERT INTO public.library_resource_groupe(resource_id, groupe_id) VALUES
 ('cd000000-0000-4000-8000-000000000071','cd000000-0000-4000-8000-0000000000c1'),
 ('cd000000-0000-4000-8000-000000000072','cd000000-0000-4000-8000-0000000000c1'),
 ('cd000000-0000-4000-8000-000000000073','cd000000-0000-4000-8000-0000000000c1');
UPDATE public.library_version_rights SET expire_le = now() - interval '1 day'
 WHERE resource_version_id = 'cd000000-0000-4000-8000-000000000082';
UPDATE public.library_resource SET archived_at = now() WHERE id = 'cd000000-0000-4000-8000-000000000073';

-- Travaux de la classe 1 (A3 est nominatif pour une eleve d'un autre foyer,
-- A5 est fait).
INSERT INTO public.learning_assignment(id, group_id, student_id, resource_id, purpose, starts_at, due_at, created_by, status) VALUES
 ('cd000000-0000-4000-8000-0000000000a1','cd000000-0000-4000-8000-0000000000c1',NULL,'cd000000-0000-4000-8000-000000000071','learn',now(),now() + interval '1 day','cd000000-0000-4000-8000-0000000000b1','a_faire'),
 ('cd000000-0000-4000-8000-0000000000a2','cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000e1','cd000000-0000-4000-8000-000000000071','review',now(),now() + interval '2 days','cd000000-0000-4000-8000-0000000000b1','en_cours'),
 ('cd000000-0000-4000-8000-0000000000a3','cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000e3','cd000000-0000-4000-8000-000000000071','reinforce',now(),now() + interval '12 hours','cd000000-0000-4000-8000-0000000000b1','a_faire'),
 ('cd000000-0000-4000-8000-0000000000a4','cd000000-0000-4000-8000-0000000000c1',NULL,'cd000000-0000-4000-8000-000000000071','maintain',now(),NULL,'cd000000-0000-4000-8000-0000000000b1','a_faire'),
 ('cd000000-0000-4000-8000-0000000000a5','cd000000-0000-4000-8000-0000000000c1',NULL,'cd000000-0000-4000-8000-000000000071','learn',now(),now() + interval '2 hours','cd000000-0000-4000-8000-0000000000b1','fait'),
 ('cd000000-0000-4000-8000-0000000000a6','cd000000-0000-4000-8000-0000000000c1',NULL,'cd000000-0000-4000-8000-000000000071','assessment',now(),now() + interval '3 days','cd000000-0000-4000-8000-0000000000b1','a_faire');

-- ------------------------------------------------------------
-- 1. ACL et F86
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.presenter_support(uuid,uuid,integer,text,jsonb)'::regprocedure,
                           'public.support_actif(uuid)'::regprocedure,
                           'public.prerequis_enseignant()'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ROUGE : DEFINER ou empreinte de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('trois RPC DEFINER avec empreinte F86 reelle');
  FOREACH f IN ARRAY ARRAY['public.support_actif_capacites(uuid)'::regprocedure,
                           'public.assignations_a_venir(uuid,uuid,integer)'::regprocedure] LOOP
    IF (SELECT prosecdef OR NOT proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f) THEN
      RAISE EXCEPTION 'ROUGE : % doit etre INVOKER a search_path vide', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('deux lectures INVOKER');
  FOREACH f IN ARRAY ARRAY['public.presenter_support(uuid,uuid,integer,text,jsonb)'::regprocedure,
                           'public.support_actif(uuid)'::regprocedure,
                           'public.prerequis_enseignant()'::regprocedure,
                           'public.support_actif_capacites(uuid)'::regprocedure,
                           'public.assignations_a_venir(uuid,uuid,integer)'::regprocedure] LOOP
    IF NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : ACL EXECUTE de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('ACL : authenticated seul');
  FOREACH f IN ARRAY ARRAY['app_private.support_refus(uuid,uuid)'::regprocedure,
                           'app_private.support_actif_json(uuid)'::regprocedure] LOOP
    IF (SELECT prosecdef FROM pg_proc WHERE oid = f)
       OR has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : aide interne % DEFINER ou ouverte', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('aides internes INVOKER fermees aux clients');
END $acl$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.support_actif('cd000000-0000-4000-8000-000000000051')$$, '42501', 'anon : support actif refuse');
SELECT pg_temp.refus($$SELECT public.prerequis_enseignant()$$, '42501', 'anon : prerequis refuses');
SELECT pg_temp.refus($$SELECT * FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1')$$, '42501', 'anon : travail refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Support actif
-- ------------------------------------------------------------
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b4','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.support_actif_capacites('cd000000-0000-4000-8000-000000000051')$$, '42501',
  'compte desactive : capacites refusees (garde compte actif)');
RESET ROLE;

SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.support_actif_capacites('cd000000-0000-4000-8000-000000000051') = '{"peut_presenter": false}'::jsonb,
  'autre enseignant : ne peut pas presenter');
SELECT pg_temp.refus($$SELECT public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k-b2')$$,
  '42501', 'autre enseignant : presentation refusee (garde enseignant de la seance)');
SELECT pg_temp.refus($$SELECT public.support_actif('cd000000-0000-4000-8000-000000000051')$$, '42501',
  'autre enseignant : lecture refusee (garde participant)');
RESET ROLE;

SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000e1','student','cd000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.support_actif_capacites('cd000000-0000-4000-8000-000000000051') = '{"peut_presenter": false}'::jsonb,
  'eleve : ne peut pas presenter');
SELECT pg_temp.refus($$SELECT public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k-e1')$$,
  '42501', 'eleve : presentation refusee');
SELECT pg_temp.vrai(public.support_actif('cd000000-0000-4000-8000-000000000051') IS NULL,
  'eleve participant : aucun support presente (null)');
RESET ROLE;

SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.support_actif_capacites('cd000000-0000-4000-8000-000000000051') = '{"peut_presenter": true}'::jsonb,
  'enseignant de la seance : peut presenter');
SELECT pg_temp.refus($$SELECT public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k-pos',
  '{"resource_id": "cd000000-0000-4000-8000-000000000074", "type_ancrage": "page", "page": 2}')$$,
  '22023', 'position d''une autre ressource refusee');
DO $presenter$
DECLARE r jsonb;
BEGIN
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000074',0,'k1')
    = '{"statut": "refusee", "raison": "non_attribue"}'::jsonb, 'support non attribue a la classe : refuse');
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000072',0,'k2')
    = '{"statut": "refusee", "raison": "droits_echus"}'::jsonb, 'support aux droits echus : refuse');
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000073',0,'k3')
    = '{"statut": "refusee", "raison": "retire"}'::jsonb, 'support retire du catalogue : refuse');
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',5,'k4')
    = '{"statut": "conflit"}'::jsonb, 'revision perimee : conflit');
  r := public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k5');
  PERFORM pg_temp.vrai(r ->> 'statut' = 'faite' AND (r -> 'actif' ->> 'revision')::int = 1
    AND r -> 'actif' ->> 'titre' = 'Support un' AND r -> 'actif' ->> 'type' = 'pdf'
    AND (r -> 'actif' ->> 'numero_version')::int = 1 AND NOT (r -> 'actif' ->> 'retire')::boolean
    AND r -> 'actif' -> 'position' ->> 'resource_version_id' = 'cd000000-0000-4000-8000-000000000081'
    AND NOT r::text LIKE '%supports/%',
    'presentation faite : revision 1, version publiee, aucune cle de stockage');
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k5') = r,
    'meme cle : meme reponse');
  PERFORM pg_temp.vrai(public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',0,'k6')
    = '{"statut": "conflit"}'::jsonb, 'nouvelle tentative sur l''ancienne revision : conflit');
  r := public.presenter_support('cd000000-0000-4000-8000-000000000051','cd000000-0000-4000-8000-000000000071',1,'k7',
         '{"resource_id": "cd000000-0000-4000-8000-000000000071", "type_ancrage": "page", "page": 4}');
  PERFORM pg_temp.vrai(r ->> 'statut' = 'faite' AND (r -> 'actif' ->> 'revision')::int = 2
    AND (r -> 'actif' -> 'position' ->> 'page')::int = 4, 'page suivante presentee : revision 2');
END $presenter$;
RESET ROLE;

SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000e1','student','cd000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.support_actif('cd000000-0000-4000-8000-000000000051') ->> 'revision')::int = 2
  AND NOT (public.support_actif('cd000000-0000-4000-8000-000000000051') ->> 'retire')::boolean,
  'la classe recoit le support sans rien faire');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d2','guardian','cd000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.support_actif('cd000000-0000-4000-8000-000000000051')$$, '42501',
  'tuteur d''un autre foyer : lecture refusee');
RESET ROLE;
UPDATE public.library_version_rights SET expire_le = now() - interval '1 minute'
 WHERE resource_version_id = 'cd000000-0000-4000-8000-000000000081';
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000e1','student','cd000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.support_actif('cd000000-0000-4000-8000-000000000051') ->> 'retire')::boolean,
  'droits echus en cours de seance : la classe le sait (retire)');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.pedagogie_partage_idempotence WHERE operation = 'presenter_support') = 7,
  'une trace d''idempotence par cle');

-- ------------------------------------------------------------
-- 3. Travail a venir (plafond 3, filtre par eleve a la source)
-- ------------------------------------------------------------
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d2','guardian','cd000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT * FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1')$$, '42501',
  'tuteur sans enfant dans la classe : refuse (garde classe lisible)');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1','guardian','cd000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT array_agg(id ORDER BY ord) FROM public.assignations_a_venir(
                       'cd000000-0000-4000-8000-0000000000c1','cd000000-0000-4000-8000-0000000000e1')
                       WITH ORDINALITY AS t(id, group_id, student_id, resource_id, resource_version_id, content_range,
                         purpose, instructions, starts_at, due_at, created_by, status, ord))
  = ARRAY['cd000000-0000-4000-8000-0000000000a1','cd000000-0000-4000-8000-0000000000a2',
          'cd000000-0000-4000-8000-0000000000a6']::uuid[],
  'tuteur : trois travaux ouverts, le plus urgent d''abord, collectifs et nominatifs de son enfant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1',
                       'cd000000-0000-4000-8000-0000000000e1', 50)) = 3, 'plafond de trois garanti par le serveur');
SELECT pg_temp.vrai((SELECT count(*) FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1',
                       'cd000000-0000-4000-8000-0000000000e1', 0)) = 0, 'limite nulle : aucune ligne');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT array_agg(id) FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1'))
  @> ARRAY['cd000000-0000-4000-8000-0000000000a3']::uuid[]
  AND NOT (SELECT array_agg(id) FROM public.assignations_a_venir('cd000000-0000-4000-8000-0000000000c1',
             'cd000000-0000-4000-8000-0000000000e1')) @> ARRAY['cd000000-0000-4000-8000-0000000000a3']::uuid[],
  'enseignant : le nominatif d''une autre eleve sort du filtre par eleve');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. Prerequis de l'enseignant (ENS-01)
-- ------------------------------------------------------------
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1','guardian','cd000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prerequis_enseignant()$$, '42501', 'tuteur : prerequis refuses (garde enseignant)');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b4','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prerequis_enseignant()$$, '42501', 'enseignant desactive : prerequis refuses');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b3','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prerequis_enseignant()$$, 'P0002', 'enseignant sans profil enseignant : introuvable');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prerequis_enseignant()
  = '{"photo": false, "langues": false, "fuseau": false, "disponibilites": false}'::jsonb,
  'enseignant debutant : rien n''est confirme');
RESET ROLE;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prerequis_enseignant()
  = '{"photo": true, "langues": true, "fuseau": true, "disponibilites": true}'::jsonb,
  'enseignante complete : les quatre prerequis faits, pour elle seule');
RESET ROLE;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 38 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 38 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CONTRATS seance : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
