-- CONTRATS-MANQUANTS : liste paginee des classes (PortClassesAdmin), tableau
-- de pilotage (PortPilotage), fusion et transfert (PortFusionClasses).
-- Chaque garde a un controle de refus ; les controles positifs prouvent que
-- le refus vient de la garde et non d'une fixture cassee.
-- A rejouer sur une base NEUVE (fixtures inserees puis annulees).
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

-- La ligne d'une classe dans une page.
CREATE FUNCTION pg_temp.ligne(p_page jsonb, p_id text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT l FROM jsonb_array_elements(p_page -> 'lignes') l WHERE l ->> 'groupe_id' = p_id
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.ligne(jsonb, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('cc000000-0000-4000-8000-0000000000a1','cc-admin@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000a2','cc-admin-off@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000b1','cc-t1@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000b2','cc-t2@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000b3','cc-t3@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000b4','cc-t4@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000d1','cc-g1@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000d2','cc-g2@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e1','cc-e1@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e2','cc-e2@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e3','cc-e3@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e4','cc-e4@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e5','cc-e5@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e6','cc-e6@test.invalid'),
 ('cc000000-0000-4000-8000-0000000000e7','cc-e7@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('cc000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('cc000000-0000-4000-8000-0000000000a1','CC-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('cc000000-0000-4000-8000-0000000000a2','CC-ADM-0002','admin',NULL,'Direction','Desactivee','disabled','male'),
 ('cc000000-0000-4000-8000-0000000000b1','CC-ENS-0001','teacher',NULL,'Ibrahim','Exemple','provisional_active','male'),
 ('cc000000-0000-4000-8000-0000000000b2','CC-ENS-0002','teacher',NULL,'Yusuf','Fictif','provisional_active','male'),
 ('cc000000-0000-4000-8000-0000000000b3','CC-ENS-0003','teacher',NULL,'Maryam','Modele','provisional_active','female'),
 ('cc000000-0000-4000-8000-0000000000b4','CC-ENS-0004','teacher',NULL,'Bilal','Essai','provisional_active','male'),
 ('cc000000-0000-4000-8000-0000000000d1','CC-TUT-0001','guardian','cc000000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('cc000000-0000-4000-8000-0000000000d2','CC-TUT-0002','guardian','cc000000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('cc000000-0000-4000-8000-0000000000e1','CC-ELV-0001','student','cc000000-0000-4000-8000-0000000000f1','Adam','Foyer1','active','male'),
 ('cc000000-0000-4000-8000-0000000000e2','CC-ELV-0002','student','cc000000-0000-4000-8000-0000000000f1','Bilel','Foyer1','active','male'),
 ('cc000000-0000-4000-8000-0000000000e3','CC-ELV-0003','student','cc000000-0000-4000-8000-0000000000f2','Driss','Foyer2','active','male'),
 ('cc000000-0000-4000-8000-0000000000e4','CC-ELV-0004','student','cc000000-0000-4000-8000-0000000000f2','Farid','Foyer2','active','male'),
 ('cc000000-0000-4000-8000-0000000000e5','CC-ELV-0005','student','cc000000-0000-4000-8000-0000000000f3','Hamza','Foyer3','active','male'),
 ('cc000000-0000-4000-8000-0000000000e6','CC-ELV-0006','student','cc000000-0000-4000-8000-0000000000f2','Jawad','Foyer2','active','male'),
 ('cc000000-0000-4000-8000-0000000000e7','CC-ELV-0007','student','cc000000-0000-4000-8000-0000000000f3','Karim','Adulte','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('cc000000-0000-4000-8000-0000000000e1','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e2','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e3','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e4','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e5','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e6','minor','child'),
 ('cc000000-0000-4000-8000-0000000000e7','autonomous','standard');
INSERT INTO public.teacher_profiles(profile_id, kyc_status, languages, timezone_iana) VALUES
 ('cc000000-0000-4000-8000-0000000000b1','approved','{francais}','Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000b2','approved','{francais}','Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000b3','approved','{francais}','Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000b4','approved','{francais}','Europe/Paris');
INSERT INTO public.weekly_availability(profile_id, weekday, hour_local, timezone_iana) VALUES
 ('cc000000-0000-4000-8000-0000000000b1',1,18,'Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000b3',1,18,'Europe/Paris'),
 ('cc000000-0000-4000-8000-0000000000b4',1,18,'Europe/Paris');

-- Famille « Garcons debutants, lundi 18 h, Paris » : C1 a C4 et C7 (Londres
-- 17 h est le meme instant) ; New York 12 h (C5) est une autre famille ; C6
-- est cloturee.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
                           timezone_iana, etat, genre_public, created_at) VALUES
 ('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000b1','enfant',5,'Garçons débutants',1,18,'Europe/Paris','active','hommes', now() - interval '60 min'),
 ('cc000000-0000-4000-8000-0000000000c2','cc000000-0000-4000-8000-0000000000b2','enfant',5,'Garçons débutants',1,18,'Europe/Paris','active','hommes', now() - interval '59 min'),
 ('cc000000-0000-4000-8000-0000000000c3',NULL,'enfant',5,'Garçons débutants',1,18,'Europe/Paris','en_attente_enseignant','hommes', now() - interval '58 min'),
 ('cc000000-0000-4000-8000-0000000000c4',NULL,'enfant',5,'Garçons débutants',1,17,'Europe/London','en_attente_enseignant','hommes', now() - interval '57 min'),
 ('cc000000-0000-4000-8000-0000000000c5','cc000000-0000-4000-8000-0000000000b3','enfant',5,'Garçons débutants',1,12,'America/New_York','active','hommes', now() - interval '56 min'),
 ('cc000000-0000-4000-8000-0000000000c6','cc000000-0000-4000-8000-0000000000b2','adulte',6,'Filles',2,10,'Europe/Paris','active','femmes', now() - interval '55 min'),
 ('cc000000-0000-4000-8000-0000000000c7',NULL,'enfant',1,'Garçons débutants',1,18,'Europe/Paris','en_attente_enseignant','hommes', now() - interval '54 min');
UPDATE public.groupes SET ended_at = now(), ended_by = 'cc000000-0000-4000-8000-0000000000a1', end_reason = 'essai'
 WHERE id = 'cc000000-0000-4000-8000-0000000000c6';
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000e1'),
 ('cc000000-0000-4000-8000-0000000000c2','cc000000-0000-4000-8000-0000000000e3'),
 ('cc000000-0000-4000-8000-0000000000c2','cc000000-0000-4000-8000-0000000000e4'),
 ('cc000000-0000-4000-8000-0000000000c5','cc000000-0000-4000-8000-0000000000e6'),
 ('cc000000-0000-4000-8000-0000000000c7','cc000000-0000-4000-8000-0000000000e5');
-- La demande d'E1 est rattachee a C1 ; E2 et E7 attendent.
INSERT INTO public.demandes_horaires_famille(eleve_id, type_public, langue_code, fuseau_iana, jours,
                                             heures_locales, source, etat, groupe_id) VALUES
 ('cc000000-0000-4000-8000-0000000000e1','enfant','francais','Europe/Paris','{1}','{18}','personnalisee','envoyee',NULL),
 ('cc000000-0000-4000-8000-0000000000e2','enfant','francais','Europe/Paris','{1}','{18}','personnalisee','envoyee',NULL),
 ('cc000000-0000-4000-8000-0000000000e7','adulte','francais','Europe/Paris','{2,4}','{10,10}','personnalisee','envoyee',NULL);
UPDATE public.demandes_horaires_famille
   SET etat = 'enseignant_affecte', groupe_id = 'cc000000-0000-4000-8000-0000000000c1'
 WHERE eleve_id = 'cc000000-0000-4000-8000-0000000000e1';
-- Une seance individuelle d'E4, dans huit semaines, au meme instant que la
-- famille (R5).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status)
VALUES ('cc000000-0000-4000-8000-000000000051','cc000000-0000-4000-8000-0000000000b4',
        public.instant_creneau(1, 18, 'Europe/Paris', 8),
        public.instant_creneau(1, 18, 'Europe/Paris', 8) + interval '60 min', 'planned');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('cc000000-0000-4000-8000-000000000051','cc000000-0000-4000-8000-0000000000e4','student');

-- ------------------------------------------------------------
-- 1. ACL et F86 (proprietaire)
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::regprocedure,
    'public.pilotage_admin_page(integer,integer,text,integer,integer,text,text)'::regprocedure,
    'public.classes_cibles_fusion(uuid,integer)'::regprocedure,
    'public.apercu_fusion(uuid,uuid)'::regprocedure,
    'public.membres_transferables(uuid)'::regprocedure,
    'public.historique_classe(uuid)'::regprocedure,
    'public.fusionner_classes(uuid,uuid,text)'::regprocedure,
    'public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure
  ] LOOP
    IF NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : ACL EXECUTE de %', f;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid = f AND p.proconfig @> ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'ROUGE : % sans search_path vide', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('ACL : 8 RPC ouvertes a authenticated seul, search_path vide');

  FOREACH f IN ARRAY ARRAY[
    'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::regprocedure,
    'public.pilotage_admin_page(integer,integer,text,integer,integer,text,text)'::regprocedure,
    'public.classes_cibles_fusion(uuid,integer)'::regprocedure,
    'public.apercu_fusion(uuid,uuid)'::regprocedure,
    'public.membres_transferables(uuid)'::regprocedure,
    'public.historique_classe(uuid)'::regprocedure,
    'public.fusionner_classes(uuid,uuid,text)'::regprocedure,
    'public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE
       '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ROUGE : % sans DEFINER ou empreinte F86 absente ou perimee', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('8 RPC DEFINER avec empreinte F86 reelle');

  FOREACH f IN ARRAY ARRAY[
    'app_private.deplacer_membre_classe(uuid,uuid,uuid,text)'::regprocedure,
    'app_private.classes_numerotees()'::regprocedure,
    'app_private.instant_hebdo_utc(integer,integer,text)'::regprocedure,
    'app_private.instants_se_croisent(text,text)'::regprocedure] LOOP
    IF (SELECT prosecdef FROM pg_proc WHERE oid = f)
       OR has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : aide interne % DEFINER ou executable par un client', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('aides internes INVOKER fermees aux clients');

  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.classe_mouvements'::regclass)
     OR has_table_privilege('authenticated', 'public.classe_mouvements', 'INSERT,UPDATE,DELETE')
     OR has_table_privilege('anon', 'public.classe_mouvements', 'SELECT') THEN
    RAISE EXCEPTION 'ROUGE : classe_mouvements sans RLS ou ecrivable';
  END IF;
  PERFORM pg_temp.ok('classe_mouvements : RLS, lecture seule pour authenticated');
END $acl$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus('SELECT public.classes_admin_page()', '42501', 'anon : liste des classes refusee');
SELECT pg_temp.refus('SELECT public.pilotage_admin_page()', '42501', 'anon : pilotage refuse');
SELECT pg_temp.refus($$SELECT public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','x')$$,
  '42501', 'anon : fusion refusee');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Gardes : un enseignant, une direction desactivee
-- ------------------------------------------------------------
SELECT pg_temp.qui('cc000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.classes_admin_page()', '42501', 'enseignant : liste des classes refusee (garde direction)');
SELECT pg_temp.refus('SELECT public.pilotage_admin_page()', '42501', 'enseignant : pilotage refuse');
SELECT pg_temp.refus($$SELECT public.classes_cibles_fusion('cc000000-0000-4000-8000-0000000000c1')$$, '42501', 'enseignant : cibles refusees');
SELECT pg_temp.refus($$SELECT public.apercu_fusion('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2')$$, '42501', 'enseignant : apercu refuse');
SELECT pg_temp.refus($$SELECT public.membres_transferables('cc000000-0000-4000-8000-0000000000c1')$$, '42501', 'enseignant : membres refuses');
SELECT pg_temp.refus($$SELECT public.historique_classe('cc000000-0000-4000-8000-0000000000c1')$$, '42501', 'enseignant : historique refuse');
SELECT pg_temp.refus($$SELECT public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','k-ens')$$, '42501', 'enseignant : fusion refusee');
SELECT pg_temp.refus($$SELECT public.transferer_eleve('cc000000-0000-4000-8000-0000000000e1','cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','k-ens')$$, '42501', 'enseignant : transfert refuse');
RESET ROLE;

SELECT pg_temp.qui('cc000000-0000-4000-8000-0000000000a2','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.classes_admin_page()', '42501', 'direction desactivee : liste refusee');
SELECT pg_temp.refus($$SELECT public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','k-off')$$, '42501', 'direction desactivee : fusion refusee');
SELECT pg_temp.refus($$SELECT public.transferer_eleve('cc000000-0000-4000-8000-0000000000e1','cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','k-off')$$, '42501', 'direction desactivee : transfert refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Liste paginee des classes (R16, R17)
-- ------------------------------------------------------------
SELECT pg_temp.qui('cc000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.classes_admin_page(p_etat => 'inconnu')$$, '22023', 'filtre d''etat invalide refuse');
SELECT pg_temp.refus($$SELECT public.classes_admin_page(p_taille => 0)$$, '22023', 'taille de page nulle refusee');
DO $liste$
DECLARE v jsonb; l jsonb;
BEGIN
  v := public.classes_admin_page();
  PERFORM pg_temp.vrai((v ->> 'total_sans_filtre')::int = 7 AND (v ->> 'total')::int = 7
    AND (v ->> 'page')::int = 1 AND jsonb_array_length(v -> 'lignes') = 7,
    'sans filtre : 7 classes, clotures et sans enseignant comprises');
  PERFORM pg_temp.vrai(
    (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c1') ->> 'numero_dans_famille')::int = 1
    AND (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c2') ->> 'numero_dans_famille')::int = 2
    AND (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c3') ->> 'numero_dans_famille')::int = 3
    AND (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c7') ->> 'numero_dans_famille')::int = 5,
    'R16 : numeros 1, 2, 3 puis 5 dans la famille de Paris');
  PERFORM pg_temp.vrai(
    (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c4') ->> 'numero_dans_famille')::int = 4
    AND (pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c5') ->> 'numero_dans_famille')::int = 1,
    'cle de famille : Londres 17 h rejoint Paris 18 h (n° 4), New York 12 h a part (n° 1)');
  l := pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c3');
  PERFORM pg_temp.vrai((l ->> 'sans_enseignant')::boolean AND l -> 'teacher_id' = 'null'::jsonb
    AND (l ->> 'peut_affecter_enseignant')::boolean AND NOT (l ->> 'peut_fusionner')::boolean
    AND l ->> 'genre' = 'hommes' AND l -> 'code_court' = 'null'::jsonb,
    'R7 : classe sans enseignant rendue, affectable, sans fusion a zero eleve');
  l := pg_temp.ligne(v, 'cc000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(l ->> 'teacher_prenom' = 'Ibrahim' AND (l ->> 'nombre_membres')::int = 1
    AND (l ->> 'peut_fusionner')::boolean AND (l ->> 'peut_transferer')::boolean
    AND (l ->> 'actif')::boolean AND l ->> 'timezone_iana' = 'Europe/Paris',
    'ligne active : enseignant, effectif, capacites rendues');
  PERFORM pg_temp.vrai(v -> 'compteurs' = '{"active": 3, "attente_enseignant": 3, "cloturee": 1}'::jsonb,
    'compteurs par etat');
  PERFORM pg_temp.vrai(v -> 'jours' = '[1, 2]'::jsonb AND v -> 'heures' = '[10, 12, 17, 18]'::jsonb
    AND v -> 'fuseaux' = '["America/New_York", "Europe/London", "Europe/Paris"]'::jsonb
    AND v -> 'genres' = '["femmes", "hommes"]'::jsonb
    AND jsonb_array_length(v -> 'enseignants') = 3,
    'valeurs de filtre possibles (jours, heures, fuseaux, genres, enseignants)');

  v := public.classes_admin_page(p_sans_enseignant => true);
  PERFORM pg_temp.vrai((v ->> 'total')::int = 3
    AND v -> 'compteurs' = '{"active": 0, "attente_enseignant": 3, "cloturee": 0}'::jsonb,
    'filtre « sans enseignant » : 3 classes');
  v := public.classes_admin_page(p_etat => 'cloturee');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 1
    AND v -> 'compteurs' = '{"active": 3, "attente_enseignant": 3, "cloturee": 1}'::jsonb,
    'filtre d''etat : les compteurs gardent les autres etats');
  v := public.classes_admin_page(p_enseignant_id => 'cc000000-0000-4000-8000-0000000000b2');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 2, 'filtre par enseignant');
  v := public.classes_admin_page(p_remplissage => 'pleine');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 1
    AND v -> 'lignes' -> 0 ->> 'groupe_id' = 'cc000000-0000-4000-8000-0000000000c7',
    'filtre de remplissage : seule C7 est pleine');
  v := public.classes_admin_page(p_texte => 'GARCONS DEBUTANTS');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 6, 'recherche insensible a la casse et aux accents');
  v := public.classes_admin_page(p_texte => 'n° 3');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 1
    AND v -> 'lignes' -> 0 ->> 'groupe_id' = 'cc000000-0000-4000-8000-0000000000c3',
    'recherche par numero dans la famille');
  v := public.classes_admin_page(p_page => 2, p_taille => 3);
  PERFORM pg_temp.vrai((v ->> 'page')::int = 2 AND jsonb_array_length(v -> 'lignes') = 3
    AND (v ->> 'total')::int = 7, 'pagination : page 2 de 3 lignes');
  v := public.classes_admin_page(p_page => 99, p_taille => 3);
  PERFORM pg_temp.vrai((v ->> 'page')::int = 3 AND jsonb_array_length(v -> 'lignes') = 1,
    'pagination : page au-dela de la fin ramenee a la derniere');
END $liste$;

-- ------------------------------------------------------------
-- 4. Pilotage (R7, R9, R19)
-- ------------------------------------------------------------
SELECT pg_temp.refus($$SELECT public.pilotage_admin_page(p_signal => 'autre')$$, '22023', 'signal de pilotage invalide refuse');
DO $pilotage$
DECLARE v jsonb; l jsonb;
BEGIN
  v := public.pilotage_admin_page();
  PERFORM pg_temp.vrai((v ->> 'total_sans_filtre')::int = 4 AND (v ->> 'total')::int = 4,
    'pilotage : 4 horaires (classes actives ou demandes en attente)');
  l := v -> 'lignes' -> 0;
  PERFORM pg_temp.vrai(l ->> 'id' = 'enfant|1|18|Europe/Paris' AND (l ->> 'classes')::int = 4
    AND (l ->> 'effectif')::int = 4 AND (l ->> 'capacite')::int = 16
    AND (l ->> 'classes_sous_minimum')::int = 4 AND (l ->> 'classes_attente_enseignant')::int = 2
    AND (l ->> 'demandes_en_attente')::int = 1,
    'ligne Paris 18 h en tete : classes, effectif, capacite, sous minimum, attente, demandes');
  PERFORM pg_temp.vrai(l -> 'par_genre' = '[{"genre": "hommes", "libres": 1, "manquants": 1},
                                            {"genre": "femmes", "libres": 0, "manquants": 0}]'::jsonb,
    'R7 : un homme libre pour deux classes en attente ; l''enseignante de New York est occupee');
  l := v -> 'lignes' -> 1;
  PERFORM pg_temp.vrai(l ->> 'id' = 'adulte|2|10|Europe/Paris' AND (l ->> 'classes')::int = 0
    AND l -> 'par_genre' -> 2 = '{"genre": "indetermine", "libres": 0, "manquants": 1}'::jsonb,
    'demande sans classe : un enseignant manque, genre encore inconnu');
  PERFORM pg_temp.vrai(v -> 'lignes' -> 2 ->> 'id' = 'enfant|1|17|Europe/London'
    AND v -> 'lignes' -> 2 -> 'par_genre' -> 0 = '{"genre": "hommes", "libres": 1, "manquants": 0}'::jsonb
    AND v -> 'lignes' -> 3 ->> 'id' = 'enfant|1|12|America/New_York',
    'tri : penuries d''abord, puis classes en attente');
  PERFORM pg_temp.vrai(v -> 'compteurs' = '{"penurie": 2, "sous_minimum": 3, "attente_enseignant": 2}'::jsonb
    AND v -> 'resume' = '{"classes": 6, "classes_attente_enseignant": 3, "classes_sous_minimum": 6,
                         "demandes_en_attente": 2, "enseignants_libres": 2, "enseignants_manquants": 2}'::jsonb,
    'compteurs par signal et resume du jeu');
  v := public.pilotage_admin_page(p_signal => 'sous_minimum');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 3, 'filtre signal sous minimum');
  v := public.pilotage_admin_page(p_type => 'adulte');
  PERFORM pg_temp.vrai((v ->> 'total')::int = 1 AND (v ->> 'total_sans_filtre')::int = 4,
    'filtre de categorie');
  v := public.pilotage_admin_page(p_page => 9, p_taille => 1);
  PERFORM pg_temp.vrai((v ->> 'page')::int = 4 AND jsonb_array_length(v -> 'lignes') = 1,
    'pilotage : page bornee a la derniere');
END $pilotage$;

-- ------------------------------------------------------------
-- 5. Fusion (R8, R9)
-- ------------------------------------------------------------
SELECT pg_temp.refus($$SELECT public.apercu_fusion('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c5')$$,
  '22023', 'apercu vers une autre famille refuse');
SELECT pg_temp.refus($$SELECT public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','')$$,
  '22023', 'fusion sans cle d''envoi refusee');
DO $fusion$
DECLARE v jsonb; r jsonb;
BEGIN
  v := public.classes_cibles_fusion('cc000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 3
    AND NOT v::text LIKE '%cc000000-0000-4000-8000-0000000000c5%'
    AND NOT v::text LIKE '%cc000000-0000-4000-8000-0000000000c7%',
    'cibles : C2, C3, C4 (meme famille, de la place) ; ni New York ni C7 pleine');
  v := public.classes_cibles_fusion('cc000000-0000-4000-8000-0000000000c1', 5);
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 2, 'cibles pour cinq eleves : C3 et C4 seulement');
  v := public.apercu_fusion('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai((v ->> 'membres_deplaces')::int = 1 AND (v ->> 'familles_notifiees')::int = 1
    AND v ->> 'enseignant_libere_prenom' = 'Ibrahim' AND (v -> 'cible' ->> 'membres')::int = 2
    AND (v -> 'cible' ->> 'numero')::int = 2 AND (v ->> 'source_numero')::int = 1,
    'apercu : un eleve, une famille, enseignant libere, cible n° 2');

  r := public.fusionner_classes('cc000000-0000-4000-8000-0000000000c2','cc000000-0000-4000-8000-0000000000c5','k-nyc');
  PERFORM pg_temp.vrai(r = '{"statut": "refusee", "motif": "cible_incompatible"}'::jsonb,
    'fusion vers une autre famille refusee avec son motif');
  r := public.fusionner_classes('cc000000-0000-4000-8000-0000000000c2','cc000000-0000-4000-8000-0000000000c7','k-pleine');
  PERFORM pg_temp.vrai(r = '{"statut": "refusee", "motif": "cible_pleine"}'::jsonb,
    'fusion vers une classe sans assez de place refusee');

  r := public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1','cc000000-0000-4000-8000-0000000000c2','k-fusion');
  PERFORM pg_temp.vrai(r ->> 'statut' = 'faite' AND (r ->> 'eleves_deplaces')::int = 1
    AND (r ->> 'cible_numero')::int = 2, 'fusion faite');
  PERFORM pg_temp.vrai(public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1',
                         'cc000000-0000-4000-8000-0000000000c2','k-fusion') = r,
    'idempotence : la meme cle rend la meme reponse');
  PERFORM pg_temp.vrai(public.fusionner_classes('cc000000-0000-4000-8000-0000000000c1',
                         'cc000000-0000-4000-8000-0000000000c2','k-fusion-bis') = '{"statut": "deja_faite"}'::jsonb,
    'une seconde fusion de la meme source rend deja_faite');

  v := public.historique_classe('cc000000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1 AND v -> 0 ->> 'type' = 'fusion_entrante'
    AND (v -> 0 ->> 'nombre')::int = 1 AND (v -> 0 ->> 'autre_numero')::int = 1,
    'historique de la cible : fusion entrante');
  v := public.historique_classe('cc000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1 AND v -> 0 ->> 'type' = 'fusion_sortante',
    'historique de la source : fusion sortante');
END $fusion$;
RESET ROLE;

SELECT pg_temp.vrai((SELECT ended_at IS NOT NULL AND end_reason = 'fusion' FROM public.groupes
                      WHERE id = 'cc000000-0000-4000-8000-0000000000c1'), 'fusion : source cloturee');
SELECT pg_temp.vrai((SELECT groupe_id FROM public.groupe_membres
                      WHERE student_id = 'cc000000-0000-4000-8000-0000000000e1' AND left_at IS NULL)
                     = 'cc000000-0000-4000-8000-0000000000c2', 'fusion : l''eleve est dans la cible');
SELECT pg_temp.vrai((SELECT etat = 'enseignant_affecte' AND groupe_id = 'cc000000-0000-4000-8000-0000000000c2'
                       FROM public.demandes_horaires_famille
                      WHERE eleve_id = 'cc000000-0000-4000-8000-0000000000e1'),
  'fusion : la demande suit l''eleve sans etre cloturee');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id = 'cc000000-0000-4000-8000-0000000000c1'
                                   AND status = 'planned' AND started_at > now() AND deleted_at IS NULL)
  AND EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id = 'cc000000-0000-4000-8000-0000000000c1'
                 AND status = 'canceled'),
  'R9 : les seances a venir de la source sont annulees, l''enseignant est libre');
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications WHERE evenement = 'classe_changee'
                       AND destinataire = 'cc000000-0000-4000-8000-0000000000d1' AND params ->> 'motif' = 'fusion') = 1,
  'fusion : la famille est prevenue une fois');
SELECT pg_temp.vrai((SELECT count(*) FROM public.classe_mouvements WHERE nature = 'fusion') = 1
  AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'classes_fusionnees'),
  'fusion tracee une seule fois et auditee');

-- ------------------------------------------------------------
-- 6. Transfert (R5, R10)
-- ------------------------------------------------------------
SELECT pg_temp.qui('cc000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $transfert$
DECLARE v jsonb; r jsonb;
BEGIN
  v := public.membres_transferables('cc000000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 3 AND v -> 0 ->> 'prenom' = 'Adam',
    'membres transferables de C2 apres fusion');
  r := public.transferer_eleve('cc000000-0000-4000-8000-0000000000e4','cc000000-0000-4000-8000-0000000000c2',
                               'cc000000-0000-4000-8000-0000000000c4','t-chev');
  PERFORM pg_temp.vrai(r = '{"statut": "refuse", "raison": "chevauchement", "motif": null}'::jsonb,
    'R5 : transfert refuse, une seance de l''eleve chevauche la cible');
  r := public.transferer_eleve('cc000000-0000-4000-8000-0000000000e3','cc000000-0000-4000-8000-0000000000c2',
                               'cc000000-0000-4000-8000-0000000000c7','t-plein');
  PERFORM pg_temp.vrai(r = '{"statut": "refuse", "raison": "classe_pleine", "motif": null}'::jsonb,
    'transfert vers une classe pleine refuse');
  r := public.transferer_eleve('cc000000-0000-4000-8000-0000000000e3','cc000000-0000-4000-8000-0000000000c2',
                               'cc000000-0000-4000-8000-0000000000c5','t-nyc');
  PERFORM pg_temp.vrai(r = '{"statut": "refuse", "raison": "autre", "motif": "cible_incompatible"}'::jsonb,
    'transfert hors famille refuse');
  r := public.transferer_eleve('cc000000-0000-4000-8000-0000000000e3','cc000000-0000-4000-8000-0000000000c2',
                               'cc000000-0000-4000-8000-0000000000c3','t-ok');
  PERFORM pg_temp.vrai(r = '{"statut": "fait", "prenom": "Driss", "cible_libelle": "Garçons débutants", "cible_numero": 3}'::jsonb,
    'transfert fait');
  PERFORM pg_temp.vrai(public.transferer_eleve('cc000000-0000-4000-8000-0000000000e3','cc000000-0000-4000-8000-0000000000c2',
                         'cc000000-0000-4000-8000-0000000000c3','t-ok') = r,
    'transfert idempotent par cle');
  PERFORM pg_temp.vrai(public.transferer_eleve('cc000000-0000-4000-8000-0000000000e3','cc000000-0000-4000-8000-0000000000c2',
                         'cc000000-0000-4000-8000-0000000000c3','t-ok-bis') = '{"statut": "deja_fait"}'::jsonb,
    'un second transfert du meme eleve rend deja_fait');
  v := public.historique_classe('cc000000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 2 AND v -> 0 ->> 'type' = 'transfert_sortant'
    AND v -> 0 ->> 'prenom' = 'Driss' AND v -> 0 -> 'nombre' = 'null'::jsonb
    AND v -> 1 ->> 'type' = 'fusion_entrante',
    'historique : le plus recent d''abord');
END $transfert$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT groupe_id FROM public.groupe_membres
                      WHERE student_id = 'cc000000-0000-4000-8000-0000000000e3' AND left_at IS NULL)
                     = 'cc000000-0000-4000-8000-0000000000c3'
  AND (SELECT count(*) FROM public.notifications WHERE evenement = 'classe_changee'
         AND destinataire = 'cc000000-0000-4000-8000-0000000000d2' AND params ->> 'motif' = 'transfert') = 1,
  'transfert : eleve deplace, famille prevenue');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
     WHERE sp.profile_id = 'cc000000-0000-4000-8000-0000000000e3' AND sp.deleted_at IS NULL
       AND s.groupe_id = 'cc000000-0000-4000-8000-0000000000c2' AND s.started_at > now()),
  'transfert : l''eleve ne compte plus dans les seances a venir de la source');
SELECT pg_temp.refus($$UPDATE public.classe_mouvements SET nombre = 9$$, '55000', 'historique non modifiable');

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 74 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 74 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CONTRATS classes : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
