-- NOUVEAU-FILS (16/11/2026) : la cle « nouveau » de private.com_fil_json, lue par
-- public.com_lister_fils. Une conversation est « nouvelle » si elle a moins de 7 jours ET
-- qu'aucun membre de l'equipe n'a de ligne dans com_lectures pour elle ; le booleen n'est
-- vrai que pour un membre de l'equipe. A rejouer sur une base NEUVE apres toutes les
-- migrations (stub_auth.sql, puis supabase/migrations/*.sql). Transaction annulee.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

INSERT INTO auth.users(id, email) VALUES
 ('f0000000-0000-4000-8000-0000000000a1','nf-admin@test.invalid'),
 ('f0000000-0000-4000-8000-0000000000b1','nf-ens@test.invalid'),
 ('f0000000-0000-4000-8000-0000000000d1','nf-tut@test.invalid'),
 ('f0000000-0000-4000-8000-0000000000e1','nf-elv@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('f0000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('f0000000-0000-4000-8000-0000000000a1','NF-ADM-0001','admin',NULL,'Direction','Nf','active','female'),
 ('f0000000-0000-4000-8000-0000000000b1','NF-ENS-0001','teacher',NULL,'Maryam','Nf','provisional_active','female'),
 ('f0000000-0000-4000-8000-0000000000d1','NF-TUT-0001','guardian','f0000000-0000-4000-8000-0000000000f1','Amina','Nf','active','female'),
 ('f0000000-0000-4000-8000-0000000000e1','NF-ELV-0001','student','f0000000-0000-4000-8000-0000000000f1','Yasmine','Nf','active','female');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('f0000000-0000-4000-8000-0000000000e1','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('f0000000-0000-4000-8000-0000000000c1','f0000000-0000-4000-8000-0000000000b1','enfant',5,'Nf Un',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('f0000000-0000-4000-8000-0000000000c1','f0000000-0000-4000-8000-0000000000e1');

-- A : 2 jours, aucune lecture, aucun message.      -> nouvelle
-- B : 2 jours, lue par l'Administration.           -> pas nouvelle
-- C : 8 jours, aucune lecture.                     -> pas nouvelle
-- D : 2 jours, lue seulement par l'enseignante.    -> nouvelle (lecture d'un non-membre)
INSERT INTO public.com_fils(id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id, cree_le) VALUES
 ('f0000000-0000-4000-8000-0000000001a1','classe','f0000000-0000-4000-8000-0000000000c1','foyer','f0000000-0000-4000-8000-0000000000f1','equipe',NULL, pg_catalog.now() - interval '2 days'),
 ('f0000000-0000-4000-8000-0000000001b1','dossier','f0000000-0000-4000-8000-0000000000b1','profil','f0000000-0000-4000-8000-0000000000b1','equipe',NULL, pg_catalog.now() - interval '2 days'),
 ('f0000000-0000-4000-8000-0000000001c1','dossier','f0000000-0000-4000-8000-0000000000d1','foyer','f0000000-0000-4000-8000-0000000000f1','equipe',NULL, pg_catalog.now() - interval '8 days'),
 ('f0000000-0000-4000-8000-0000000001d1','profilPaiement','f0000000-0000-4000-8000-0000000000b1','profil','f0000000-0000-4000-8000-0000000000b1','equipe',NULL, pg_catalog.now() - interval '2 days');
INSERT INTO public.com_messages(fil_id, auteur_id, cle_idempotence, texte) VALUES
 ('f0000000-0000-4000-8000-0000000001d1','f0000000-0000-4000-8000-0000000000b1','f0000000-0000-4000-8000-0000000002d1','Mon profil de paiement');
INSERT INTO public.com_lectures(fil_id, profile_id, lu_jusqu_au) VALUES
 ('f0000000-0000-4000-8000-0000000001b1','f0000000-0000-4000-8000-0000000000a1', pg_catalog.now()),
 ('f0000000-0000-4000-8000-0000000001d1','f0000000-0000-4000-8000-0000000000b1', pg_catalog.now());

CREATE TEMP TABLE lu(qui text, fil uuid, nouveau jsonb);
GRANT ALL ON lu TO PUBLIC;
DO $lire$
DECLARE c record; r jsonb;
BEGIN
  FOR c IN SELECT * FROM (VALUES
    ('admin','f0000000-0000-4000-8000-0000000000a1'::uuid,'admin'),
    ('ens','f0000000-0000-4000-8000-0000000000b1'::uuid,'teacher'),
    ('tut','f0000000-0000-4000-8000-0000000000d1'::uuid,'guardian')) AS v(qui, id, role) LOOP
    PERFORM pg_temp.qui(c.id, c.role);
    FOR r IN SELECT x FROM pg_catalog.jsonb_array_elements(public.com_lister_fils()) x LOOP
      INSERT INTO lu VALUES (c.qui, (r->>'id')::uuid, r->'nouveau');
    END LOOP;
  END LOOP;
END $lire$;

CREATE FUNCTION pg_temp.attendre(p_qui text, p_fil uuid, p_attendu boolean, p_libelle text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v jsonb; n integer;
BEGIN
  SELECT count(*) INTO n FROM lu WHERE qui = p_qui AND fil = p_fil;
  IF n <> 1 THEN RAISE EXCEPTION 'ROUGE % : fil lu % fois (attendu 1)', p_libelle, n; END IF;
  SELECT nouveau INTO v FROM lu WHERE qui = p_qui AND fil = p_fil;
  IF v IS DISTINCT FROM pg_catalog.to_jsonb(p_attendu) THEN
    RAISE EXCEPTION 'ROUGE % : nouveau = %, attendu %', p_libelle, v, p_attendu;
  END IF;
END $$;

DO $verdict$
BEGIN
  -- La direction.
  PERFORM pg_temp.attendre('admin','f0000000-0000-4000-8000-0000000001a1',true ,'2 jours, sans lecture ni message : nouvelle');
  PERFORM pg_temp.attendre('admin','f0000000-0000-4000-8000-0000000001b1',false,'2 jours, lue par l''equipe : pas nouvelle');
  PERFORM pg_temp.attendre('admin','f0000000-0000-4000-8000-0000000001c1',false,'8 jours : pas nouvelle');
  PERFORM pg_temp.attendre('admin','f0000000-0000-4000-8000-0000000001d1',true ,'lecture d''un non-membre de l''equipe : ne compte pas');
  -- Un non-membre de l'equipe ne voit jamais « nouveau ».
  PERFORM pg_temp.attendre('tut','f0000000-0000-4000-8000-0000000001a1',false,'famille : jamais nouveau');
  PERFORM pg_temp.attendre('ens','f0000000-0000-4000-8000-0000000001d1',false,'enseignante : jamais nouveau');
  -- Droits et attributs inchanges.
  IF pg_catalog.has_function_privilege('anon','private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure,'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated','private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure,'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : droit EXECUTE ouvert sur private.com_fil_json';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure
                  AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'ROUGE : com_fil_json sans search_path vide';
  END IF;
  RAISE NOTICE 'OK nouveau fils : 4 cas de la regle et 2 cas de non-membre';
END $verdict$;

ROLLBACK;
