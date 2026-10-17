-- RACCORDEMENT 16/10 : prochaine seance d'une Classe (A, B), classes du foyer
-- (B), mise a jour d'un support (C), consommation du code d'invitation (D),
-- annonces de l'academie (E). Migrations 20261016102000 a 20261016102300.
-- Chaque garde a au moins un controle de refus ; les controles positifs
-- prouvent que le refus vient de la garde et non d'une fixture cassee.
-- A rejouer sur une base NEUVE (les fixtures sont inserees puis annulees).
\o /dev/null
BEGIN;
-- ClassesFoyerSupabase lit groupe_membres en direct, sous sa RLS : le droit
-- de table que Supabase accorde par defaut est reproduit ici, encadre par la
-- photographie des ACL (les scenarios suivants retrouvent celles des
-- migrations).
\ir _acl_photo.sql
GRANT SELECT ON public.groupe_membres TO authenticated;

-- ------------------------------------------------------------
-- Outils de test (schema temporaire de la session)
-- ------------------------------------------------------------
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

-- Le foyer vit aussi dans le jeton (app_household_id).
CREATE FUNCTION pg_temp.qui_foyer(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
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

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.qui_foyer(uuid, text, uuid),
  pg_temp.ok(text), pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('d1600000-0000-4000-8000-0000000000a1','r16-admin@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000b1','r16-t1@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000b2','r16-t2@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000d1','r16-g1@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000d2','r16-g2@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000e1','r16-e1@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000e2','r16-e2@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000e3','r16-e3@test.invalid'),
 ('d1600000-0000-4000-8000-0000000000c9','r16-ctrl@test.invalid'),
 -- Candidats enseignants : sessions d'inscription, sans profil.
 ('d1600000-0000-4000-8000-000000000101','candidat@test.invalid'),
 ('d1600000-0000-4000-8000-000000000102','candidat@test.invalid'),
 ('d1600000-0000-4000-8000-000000000103','autre@test.invalid'),
 ('d1600000-0000-4000-8000-000000000104','echue@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('d1600000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('d1600000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('d1600000-0000-4000-8000-0000000000a1','R16-ADM-0001','admin',NULL,'Direction','R16','active','female'),
 ('d1600000-0000-4000-8000-0000000000b1','R16-ENS-0001','teacher',NULL,'Maryam','R16','provisional_active','female'),
 ('d1600000-0000-4000-8000-0000000000b2','R16-ENS-0002','teacher',NULL,'Ibrahim','R16','provisional_active','male'),
 ('d1600000-0000-4000-8000-0000000000d1','R16-TUT-0001','guardian','d1600000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('d1600000-0000-4000-8000-0000000000d2','R16-TUT-0002','guardian','d1600000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('d1600000-0000-4000-8000-0000000000e1','R16-ELV-0001','student','d1600000-0000-4000-8000-0000000000f1','Yasmine','Foyer1','active','female'),
 ('d1600000-0000-4000-8000-0000000000e2','R16-ELV-0002','student','d1600000-0000-4000-8000-0000000000f2','Adam','Foyer2','active','male'),
 ('d1600000-0000-4000-8000-0000000000e3','R16-ELV-0003','student','d1600000-0000-4000-8000-0000000000f1','Bilal','Foyer1','active','male'),
 ('d1600000-0000-4000-8000-0000000000c9','R16-CTL-0001','controller',NULL,'Controle','R16','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('d1600000-0000-4000-8000-0000000000e1','minor','child'),
 ('d1600000-0000-4000-8000-0000000000e2','minor','standard'),
 ('d1600000-0000-4000-8000-0000000000e3','minor','standard');
-- C1 : Yasmine (foyer 1) et Adam (foyer 2) ; C2 : Bilal (foyer 1, frere).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('d1600000-0000-4000-8000-0000000000c1','d1600000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour R16',1,9,'Europe/Paris'),
 ('d1600000-0000-4000-8000-0000000000c2','d1600000-0000-4000-8000-0000000000b2','enfant',5,'Al-Fajr R16',2,10,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('d1600000-0000-4000-8000-0000000000c1','d1600000-0000-4000-8000-0000000000e1'),
 ('d1600000-0000-4000-8000-0000000000c1','d1600000-0000-4000-8000-0000000000e2'),
 ('d1600000-0000-4000-8000-0000000000c2','d1600000-0000-4000-8000-0000000000e3');
-- Une Classe creee genere desormais ses seances a venir (lots posterieurs au
-- 16/10) : on les retire, pour que les seances posees ici soient les seules.
DELETE FROM public.session_participants sp USING public.sessions s
 WHERE sp.session_id = s.id
   AND s.groupe_id IN ('d1600000-0000-4000-8000-0000000000c1', 'd1600000-0000-4000-8000-0000000000c2');
DELETE FROM public.sessions
 WHERE groupe_id IN ('d1600000-0000-4000-8000-0000000000c1', 'd1600000-0000-4000-8000-0000000000c2');
-- C1 : une seance passee, une annulee (plus tot), la prochaine, une suivante.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 ('d1600000-0000-4000-8000-000000000501','d1600000-0000-4000-8000-0000000000b1',
  now() - interval '7 days', now() - interval '7 days' + interval '45 minutes', 'ended',
  'd1600000-0000-4000-8000-0000000000c1'),
 ('d1600000-0000-4000-8000-000000000502','d1600000-0000-4000-8000-0000000000b1',
  now() + interval '1 day', now() + interval '1 day 45 minutes', 'canceled',
  'd1600000-0000-4000-8000-0000000000c1'),
 ('d1600000-0000-4000-8000-000000000503','d1600000-0000-4000-8000-0000000000b1',
  now() + interval '2 days', now() + interval '2 days 45 minutes', 'planned',
  'd1600000-0000-4000-8000-0000000000c1'),
 ('d1600000-0000-4000-8000-000000000504','d1600000-0000-4000-8000-0000000000b1',
  now() + interval '9 days', now() + interval '9 days 45 minutes', 'planned',
  'd1600000-0000-4000-8000-0000000000c1'),
 ('d1600000-0000-4000-8000-000000000505','d1600000-0000-4000-8000-0000000000b2',
  now() + interval '3 days', now() + interval '3 days 45 minutes', 'planned',
  'd1600000-0000-4000-8000-0000000000c2');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('d1600000-0000-4000-8000-000000000501','d1600000-0000-4000-8000-0000000000e1','student'),
 ('d1600000-0000-4000-8000-000000000502','d1600000-0000-4000-8000-0000000000e1','student'),
 ('d1600000-0000-4000-8000-000000000503','d1600000-0000-4000-8000-0000000000e1','student'),
 ('d1600000-0000-4000-8000-000000000503','d1600000-0000-4000-8000-0000000000e2','student'),
 ('d1600000-0000-4000-8000-000000000504','d1600000-0000-4000-8000-0000000000e1','student'),
 ('d1600000-0000-4000-8000-000000000505','d1600000-0000-4000-8000-0000000000e3','student');

-- ------------------------------------------------------------
-- 0. ACL : ni anon, ni service_role, ni agent_ro
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.prochaine_seance_groupe(uuid)'::regprocedure,
    'public.library_mettre_a_jour(uuid,jsonb,integer)'::regprocedure,
    'public.library_get_detail(uuid)'::regprocedure,
    'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure,
    'public.com_annonces_academie(uuid)'::regprocedure,
    'public.com_annonce_lire(uuid)'::regprocedure
  ] LOOP
    IF NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : ACL EXECUTE de %', f;
    END IF;
    IF NOT (SELECT prosecdef AND proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE
           '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ROUGE : DEFINER, search_path ou empreinte F86 de %', f;
    END IF;
  END LOOP;
END $acl$;
SELECT pg_temp.ok('ACL et empreintes F86 des six fonctions');

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')$$,
  '42501', 'anon : prochaine seance refusee (EXECUTE)');
SELECT pg_temp.refus($$SELECT public.com_annonces_academie(NULL)$$,
  '42501', 'anon : annonces de l''academie refusees (EXECUTE)');
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','A','B',NULL)$$,
  '42501', 'anon : inscription enseignant invite refusee (EXECUTE)');
RESET ROLE;

-- ------------------------------------------------------------
-- A et B. Prochaine seance d'une Classe, classes du foyer
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000e1','student','d1600000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')
                    = 'd1600000-0000-4000-8000-000000000503'::uuid,
  'eleve membre : la prochaine seance, ni la passee ni l''annulee');
SELECT pg_temp.vrai((SELECT count(*) FROM public.horloge_seance(
                       public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1'))) = 1,
  'eleve membre : l''horloge de cette seance se lit');
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c2')$$,
  '42501', 'eleve : la Classe d''un frere du meme foyer est refusee');
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe(NULL)$$,
  '42501', 'eleve : Classe nulle refusee');
RESET ROLE;

SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d1','guardian','d1600000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')
                    = 'd1600000-0000-4000-8000-000000000503'::uuid
                AND public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c2')
                    = 'd1600000-0000-4000-8000-000000000505'::uuid,
  'tuteur : la prochaine seance de chaque Classe de ses enfants');
SELECT pg_temp.vrai((SELECT array_agg(groupe_id ORDER BY libelle) FROM public.mes_groupes_famille_v)
                    = ARRAY['d1600000-0000-4000-8000-0000000000c2','d1600000-0000-4000-8000-0000000000c1']::uuid[],
  'tuteur : mes_groupes_famille_v rend les deux Classes de ses enfants, rien d''autre');
SELECT pg_temp.vrai((SELECT count(*) FROM public.groupe_membres
                      WHERE student_id = 'd1600000-0000-4000-8000-0000000000e1' AND left_at IS NULL) = 1,
  'tuteur : l''appartenance de son enfant se lit (ClassesFoyerSupabase)');
RESET ROLE;

SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d2','guardian','d1600000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c2')$$,
  '42501', 'tuteur d''un autre foyer : prochaine seance refusee');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                                 WHERE groupe_id = 'd1600000-0000-4000-8000-0000000000c2'),
  'tuteur d''un autre foyer : la Classe absente de mes_groupes_famille_v');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.groupe_membres
                                 WHERE student_id = 'd1600000-0000-4000-8000-0000000000e3'),
  'tuteur d''un autre foyer : l''appartenance d''un enfant tiers est invisible');
SELECT pg_temp.vrai((SELECT count(*) FROM public.horloge_seance('d1600000-0000-4000-8000-000000000505')) = 0,
  'tuteur d''un autre foyer : horloge d''une seance tierce vide');
RESET ROLE;

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c2')
                    = 'd1600000-0000-4000-8000-000000000505'::uuid,
  'enseignant : la prochaine seance de sa Classe');
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')$$,
  '42501', 'enseignant : la Classe d''un autre enseignant est refusee');
RESET ROLE;

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000c9','controller');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')$$,
  '42501', 'controleur : prochaine seance d''une Classe refusee');
RESET ROLE;

UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'd1600000-0000-4000-8000-0000000000e2';
SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000e2','student','d1600000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')$$,
  '42501', 'eleve desactive : prochaine seance refusee');
RESET ROLE;
UPDATE public.profiles SET account_status = 'active' WHERE id = 'd1600000-0000-4000-8000-0000000000e2';

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prochaine_seance_groupe('d1600000-0000-4000-8000-0000000000c1')
                    = 'd1600000-0000-4000-8000-000000000503'::uuid,
  'direction : la prochaine seance de toute Classe');
RESET ROLE;

-- ------------------------------------------------------------
-- C. Mise a jour d'un support de la Bibliotheque
-- ------------------------------------------------------------
SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $c_admin$
DECLARE v jsonb; v_id uuid; v_rev integer;
BEGIN
  v := public.library_creer_brouillon('{"titre":"Tuhfat al-Atfal","type":"pdf","langue":"fr","categorie":"tajwid"}'::jsonb);
  v_id := (v ->> 'id')::uuid;
  PERFORM set_config('test.res', v_id::text, true);
  v := public.library_get_detail(v_id);
  v_rev := (v ->> 'revision')::int;
  PERFORM pg_temp.vrai((v -> 'capacites' ->> 'peutModifier')::boolean,
    'direction : un support non retire se modifie (peutModifier)');
  v := public.library_mettre_a_jour(v_id, jsonb_build_object(
         'titre', 'Tuhfat al-Atfal (commentee)', 'organisme', 'Editions R16',
         'description', 'Poeme de tajwid', 'conditionsAttribution', 'Usage en classe',
         'edition', '', 'politiqueHorsLigne', 'sur_demande'), v_rev);
  PERFORM pg_temp.vrai(v ->> 'resultat' = 'EcritureFaite' AND (v ->> 'revision')::int = v_rev + 1,
    'direction : modification enregistree, revision suivante');
  v := public.library_get_detail(v_id);
  PERFORM pg_temp.vrai(v -> 'support' ->> 'titre' = 'Tuhfat al-Atfal (commentee)'
    AND v -> 'support' ->> 'organisme' = 'Editions R16'
    AND v -> 'support' ->> 'description' = 'Poeme de tajwid'
    AND v -> 'support' ->> 'conditionsAttribution' = 'Usage en classe'
    AND v -> 'support' ->> 'edition' IS NULL
    AND v -> 'support' ->> 'politiqueHorsLigne' = 'sur_demande'
    AND v -> 'support' ->> 'titreCourt' = 'Tuhfat al-Atfal',
    'direction : la fiche relit les champs modifies, le reste inchange');
  v := public.library_mettre_a_jour(v_id, '{"organisme":"Autre"}'::jsonb, v_rev);
  PERFORM pg_temp.vrai(v ->> 'resultat' = 'EcritureEnConflit',
    'direction : revision perimee rendue en conflit, rien n''est ecrit');
  PERFORM pg_temp.vrai(public.library_get_detail(v_id) -> 'support' ->> 'organisme' = 'Editions R16',
    'direction : le conflit n''a rien change');
  PERFORM pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"inconnu":"x"}'::jsonb, 1)$$, v_id),
    '22023', 'direction : cle inconnue refusee');
  PERFORM pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"titre":""}'::jsonb, %s)$$, v_id, v_rev + 1),
    '22023', 'direction : titre vide refuse');
  PERFORM pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"visibilite":"tous"}'::jsonb, %s)$$, v_id, v_rev + 1),
    '22023', 'direction : politique d''acces inconnue refusee');
  PERFORM pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"titre":5}'::jsonb, %s)$$, v_id, v_rev + 1),
    '22023', 'direction : valeur non textuelle refusee');
  PERFORM pg_temp.refus($$SELECT public.library_mettre_a_jour('d1600000-0000-4000-8000-000000000999', '{}'::jsonb, 1)$$,
    'P0002', 'direction : support inconnu');
  v := public.library_retirer(v_id, 'Doublon du catalogue', v_rev + 1);
  PERFORM pg_temp.vrai(NOT (public.library_get_detail(v_id) -> 'capacites' ->> 'peutModifier')::boolean,
    'direction : un support retire ne se modifie plus (peutModifier)');
  PERFORM pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"organisme":"x"}'::jsonb, %s)$$,
                               v_id, (public.library_get_detail(v_id) ->> 'revision')::int),
    '22023', 'direction : modification d''un support retire refusee');
END $c_admin$;
RESET ROLE;

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"organisme":"x"}'::jsonb, 1)$$,
                            current_setting('test.res')),
  '42501', 'enseignant : modification d''un support refusee');
RESET ROLE;
SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d1','guardian','d1600000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"organisme":"x"}'::jsonb, 1)$$,
                            current_setting('test.res')),
  '42501', 'tuteur : modification d''un support refusee');
RESET ROLE;
UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'd1600000-0000-4000-8000-0000000000a1';
SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($$SELECT public.library_mettre_a_jour(%L, '{"organisme":"x"}'::jsonb, 1)$$,
                            current_setting('test.res')),
  '42501', 'direction desactivee : modification refusee');
RESET ROLE;
UPDATE public.profiles SET account_status = 'active' WHERE id = 'd1600000-0000-4000-8000-0000000000a1';

-- ------------------------------------------------------------
-- D. Consommation du code d'invitation enseignant
-- ------------------------------------------------------------
INSERT INTO public.invitations_enseignant(code, email, cree_par, cree_le, expire_le) VALUES
 ('ABCD-EFGH-JKMN','candidat@test.invalid','d1600000-0000-4000-8000-0000000000a1', now(), now() + interval '14 days'),
 ('PQRS-TUVW-XYZ2','echue@test.invalid','d1600000-0000-4000-8000-0000000000a1',
  now() - interval '20 days', now() - interval '6 days'),
 ('2345-6789-ABCD','autre@test.invalid','d1600000-0000-4000-8000-0000000000a1', now(), now() + interval '14 days');
UPDATE public.invitations_enseignant SET revoquee_le = now(), revoquee_par = 'd1600000-0000-4000-8000-0000000000a1'
 WHERE code = '2345-6789-ABCD';

-- Une session qui a deja un profil (tuteur) est refusee.
SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000d1', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','R16',NULL)$$,
  '42501', 'session avec profil : inscription enseignant invite refusee');
RESET ROLE;
-- Aucune session.
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','R16',NULL)$$,
  '42501', 'sans session : inscription enseignant invite refusee');
RESET ROLE;
-- Un code emis pour une autre adresse, un code revoque, un code echu.
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000103', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','R16',NULL) ->> 'resultat' = 'inconnue',
  'code d''une autre adresse : inconnue, sans fuite');
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('2345-6789-ABCD','Hafsa','R16',NULL) ->> 'resultat' = 'inconnue',
  'code revoque : inconnue');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1600000-0000-4000-8000-000000000103'),
  'refus : aucun profil cree');
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000104', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('PQRS-TUVW-XYZ2','Hafsa','R16',NULL) ->> 'resultat' = 'expiree',
  'code echu : expiree');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1600000-0000-4000-8000-000000000104'),
  'code echu : aucun profil cree');
-- Un nom vide : la creation echoue et le code n'est pas brule.
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000101', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','  ',NULL)$$,
  'P0001', 'creation en echec (nom vide) : erreur rendue');
RESET ROLE;
SELECT pg_temp.vrai((SELECT utilisee_le IS NULL FROM public.invitations_enseignant WHERE code = 'ABCD-EFGH-JKMN'),
  'creation en echec : le code reste disponible (transaction unique)');
-- Le bon candidat : profil enseignant cree ET code consomme, ensemble.
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000101', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite(' abcd-efgh-jkmn ','Hafsa','R16','female') ->> 'resultat' = 'consommee',
  'candidat invite : code consomme');
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'teacher' AND account_status = 'pending_kyc' FROM public.profiles
                      WHERE id = 'd1600000-0000-4000-8000-000000000101')
                AND EXISTS (SELECT 1 FROM public.teacher_profiles
                             WHERE profile_id = 'd1600000-0000-4000-8000-000000000101'),
  'candidat invite : profil enseignant en attente de KYC');
SELECT pg_temp.vrai((SELECT utilisee_par = 'd1600000-0000-4000-8000-000000000101' AND utilisee_le IS NOT NULL
                       FROM public.invitations_enseignant WHERE code = 'ABCD-EFGH-JKMN'),
  'candidat invite : invitation marquee utilisee par lui');
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000101', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','R16',NULL)$$,
  '42501', 'candidat deja inscrit : seconde inscription refusee');
SELECT pg_temp.vrai(public.verifier_invitation_enseignant('ABCD-EFGH-JKMN') ->> 'resultat' = 'deja_utilisee',
  'verification apres consommation : deja_utilisee');
RESET ROLE;
-- Une seconde session pour la meme adresse ne reutilise pas le code.
SELECT pg_temp.qui('d1600000-0000-4000-8000-000000000102', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('ABCD-EFGH-JKMN','Hafsa','Bis',NULL) ->> 'resultat' = 'deja_utilisee',
  'code deja consomme : deja_utilisee, usage unique');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1600000-0000-4000-8000-000000000102'),
  'code deja consomme : aucun second profil');

-- ------------------------------------------------------------
-- E. Annonces de l'academie
-- ------------------------------------------------------------
SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $e_admin$
DECLARE v jsonb;
BEGIN
  v := public.com_annonce_publier('toutes', 'Ramadan', 'Horaires adaptes.', NULL, 'd1600000-0000-4000-8000-000000000601');
  PERFORM set_config('test.toutes', v ->> 'id', true);
  v := public.com_annonce_publier('familles', 'Reunion', 'Reunion des familles.', NULL, 'd1600000-0000-4000-8000-000000000602');
  PERFORM set_config('test.familles', v ->> 'id', true);
  v := public.com_annonce_publier('enseignants', 'Formation', 'Formation des enseignants.', NULL, 'd1600000-0000-4000-8000-000000000603');
  PERFORM set_config('test.enseignants', v ->> 'id', true);
  v := public.com_annonce_publier('toutes', 'Plus tard', 'Programmee.', now() + interval '1 day', 'd1600000-0000-4000-8000-000000000604');
  PERFORM set_config('test.programmee', v ->> 'id', true);
  PERFORM pg_temp.vrai(jsonb_array_length(public.com_annonces_academie(NULL) -> 'annonces') = 3,
    'direction : lit les trois annonces generales diffusees, pas la programmee');
END $e_admin$;
RESET ROLE;

SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d1','guardian','d1600000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
DO $e_tuteur$
DECLARE v jsonb;
BEGIN
  v := public.com_annonces_academie('d1600000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v -> 'annonces') = 2
    AND NOT (v -> 'annonces') @> jsonb_build_array(jsonb_build_object('id', current_setting('test.enseignants')))
    AND (v -> 'annonces') @> jsonb_build_array(jsonb_build_object('id', current_setting('test.toutes'), 'portee', 'toutes'))
    AND v -> 'annonces' -> 0 -> 'classe' ->> 'id' = 'd1600000-0000-4000-8000-0000000000c1'
    AND v -> 'annonces' -> 0 -> 'auteur' ->> 'nature' = 'equipe',
    'tuteur : lit « toute l''academie » et « familles » dans le contexte de la Classe');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.toutes')::uuid) ->> 'id'
                       = current_setting('test.toutes'),
    'tuteur : l''annonce de l''academie s''ouvre');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.programmee')::uuid) IS NULL,
    'tuteur : annonce de l''academie programmee invisible avant sa date');
  PERFORM public.com_annonce_marquer_lue(current_setting('test.toutes')::uuid);
  PERFORM pg_temp.vrai((public.com_annonce_lire(current_setting('test.toutes')::uuid) ->> 'lue')::boolean,
    'tuteur : annonce de l''academie marquee lue');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.enseignants')::uuid) IS NULL,
    'tuteur : annonce reservee aux enseignants absente');
  PERFORM pg_temp.refus(format($$SELECT public.com_annonce_marquer_lue(%L)$$, current_setting('test.enseignants')),
    '42501', 'tuteur : marquer lue une annonce des enseignants refuse');
END $e_tuteur$;
RESET ROLE;

SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d2','guardian','d1600000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.com_annonces_academie('d1600000-0000-4000-8000-0000000000c2')$$,
  '42501', 'tuteur : contexte d''une Classe d''un autre foyer refuse');
SELECT pg_temp.vrai(NOT (public.com_annonce_lire(current_setting('test.toutes')::uuid) ->> 'lue')::boolean,
  'lecture individuelle : l''autre tuteur ne l''a pas lue');
RESET ROLE;

SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000e1','student','d1600000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.com_annonces_academie('d1600000-0000-4000-8000-0000000000c1') -> 'annonces') = 2,
  'eleve mineur : lit « toute l''academie » et « familles »');
RESET ROLE;

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
DO $e_ens$
DECLARE v jsonb;
BEGIN
  v := public.com_annonces_academie(NULL);
  PERFORM pg_temp.vrai(jsonb_array_length(v -> 'annonces') = 2
    AND (v -> 'annonces') @> jsonb_build_array(jsonb_build_object('id', current_setting('test.enseignants')))
    AND NOT (v -> 'annonces') @> jsonb_build_array(jsonb_build_object('id', current_setting('test.familles')))
    AND v -> 'annonces' -> 0 -> 'classe' = 'null'::jsonb,
    'enseignant : lit « toute l''academie » et « enseignants », sans Classe de contexte');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.toutes')::uuid) -> 'classe' ->> 'id'
                       = 'd1600000-0000-4000-8000-0000000000c1',
    'enseignant : l''annonce ouverte porte sa Classe en contexte');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.familles')::uuid) IS NULL,
    'enseignant : annonce reservee aux familles absente');
  PERFORM pg_temp.refus($$SELECT public.com_annonces_academie('d1600000-0000-4000-8000-0000000000c2')$$,
    '42501', 'enseignant : contexte d''une Classe qui n''est pas la sienne refuse');
END $e_ens$;
RESET ROLE;

SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000c9','controller');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT array_agg(a ->> 'id') FROM jsonb_array_elements(public.com_annonces_academie(NULL) -> 'annonces') a)
                    = ARRAY[current_setting('test.toutes')],
  'controleur : lit « toute l''academie » seulement');
RESET ROLE;

UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'd1600000-0000-4000-8000-0000000000d2';
SELECT pg_temp.qui_foyer('d1600000-0000-4000-8000-0000000000d2','guardian','d1600000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.com_annonces_academie(NULL)$$,
  '42501', 'tuteur desactive : annonces de l''academie refusees');
SELECT pg_temp.refus($$SELECT public.com_annonce_lire('d1600000-0000-4000-8000-000000000999')$$,
  '42501', 'tuteur desactive : lecture d''annonce refusee');
RESET ROLE;
-- Un jeton dont le role ne correspond pas au profil ne lit rien.
SELECT pg_temp.qui('d1600000-0000-4000-8000-0000000000e2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.com_annonces_academie(NULL)$$,
  '42501', 'role du jeton different du profil : refuse');
RESET ROLE;

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 69 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 69 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'RACCORDEMENT-1016 : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
