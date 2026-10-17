-- L1-10 : double verification (TOTP, aal2) du controleur. Decision A-02 option 1.
-- Un controleur en aal1 (mot de passe seul, ou facteur enrole mais non verifie a
-- cette connexion) est refuse par SQLSTATE 42501 ; en aal2 il passe ; un admin en
-- aal1 n'est pas concerne ; un compte suspendu reste refuse meme en aal2.
-- Doit ECHOUER sur une base sans la migration 20261017150100, PASSER avec.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('a1100000-0000-0000-0000-000000000001','l110-admin@test.invalid'),
 ('a1100000-0000-0000-0000-000000000002','l110-controller@test.invalid'),
 ('a1100000-0000-0000-0000-000000000004','l110-teacher@test.invalid');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
 ('a1100000-0000-0000-0000-000000000001','L110-ADMIN-0001','admin',NULL,'Direction','L110','active','female'),
 ('a1100000-0000-0000-0000-000000000002','L110-CTRL-00001','controller',NULL,'Controleur','L110','active','male'),
 ('a1100000-0000-0000-0000-000000000004','L110-TEACH-0001','teacher',NULL,'Enseignant','L110','provisional_active','male');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('a1110000-0000-0000-0000-000000000001','a1100000-0000-0000-0000-000000000004',
        'enfant',5,'Classe L110',1,9,'Europe/Paris');
INSERT INTO public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,session_type)
VALUES ('a1120000-0000-0000-0000-000000000001','a1100000-0000-0000-0000-000000000004',
        'a1110000-0000-0000-0000-000000000001',now()-interval '1 hour',now()+interval '1 hour',
        'planned','standard');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('a1100000-0000-0000-0000-000000000002','a1100000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',true,'{}','{}',
        'a1130000-0000-0000-0000-000000000001');

CREATE FUNCTION pg_temp.jeton(p_uid uuid, p_role text, p_aal text) RETURNS void
LANGUAGE plpgsql AS $f$
DECLARE v_claims text;
BEGIN
  v_claims := jsonb_build_object('sub', p_uid, 'app_metadata', jsonb_build_object('role', p_role))::text;
  IF p_aal IS NOT NULL THEN
    v_claims := (v_claims::jsonb || jsonb_build_object('aal', p_aal))::text;
  END IF;
  PERFORM set_config('request.jwt.claim.sub', p_uid::text, true);
  PERFORM set_config('test.uid', p_uid::text, true);
  PERFORM set_config('request.jwt.claims', v_claims, true);
  PERFORM set_config('test.jwt', v_claims, true);
END $f$;

-- 1. app_aal() lit le claim, null sans claim.
SELECT pg_temp.jeton('a1100000-0000-0000-0000-000000000002','controller','aal2');
DO $t$ BEGIN
  IF public.app_aal() IS DISTINCT FROM 'aal2' THEN RAISE EXCEPTION 'L110: app_aal() devait rendre aal2'; END IF;
END $t$;
SELECT pg_temp.jeton('a1100000-0000-0000-0000-000000000002','controller',NULL);
DO $t$ BEGIN
  IF public.app_aal() IS NOT NULL THEN RAISE EXCEPTION 'L110: app_aal() devait rendre null sans claim'; END IF;
END $t$;

SET LOCAL ROLE authenticated;
-- 2. Controleur en aal1 ou sans claim : chaque RPC refuse en 42501, message exact.
DO $refus$
DECLARE
  v_appels text[] := ARRAY[
    'public.rejoindre_observation(''a1120000-0000-0000-0000-000000000001''::uuid)',
    'public.ma_mission_controle()',
    'public.controleur_lister_fils()',
    'public.controleur_lister_rapports()',
    'public.controleur_fil_de_mission(''a1120000-0000-0000-0000-000000000001''::uuid)',
    'public.controleur_envoyer_message(''a1120000-0000-0000-0000-000000000001''::uuid,''a1120000-0000-0000-0000-000000000002''::uuid,''bonjour'')',
    'public.controleur_ajouter_complement(''a1120000-0000-0000-0000-000000000001''::uuid,''complement'',NULL)'
  ];
  v_appel text;
  v_aal text;
  v_claims text;
BEGIN
  FOREACH v_aal IN ARRAY ARRAY['aal1', NULL] LOOP
    v_claims := jsonb_build_object('sub','a1100000-0000-0000-0000-000000000002','app_metadata',jsonb_build_object('role','controller'))::text;
    IF v_aal IS NOT NULL THEN v_claims := (v_claims::jsonb || jsonb_build_object('aal', v_aal))::text; END IF;
    PERFORM set_config('request.jwt.claims', v_claims, true);
    PERFORM set_config('test.jwt', v_claims, true);
    FOREACH v_appel IN ARRAY v_appels LOOP
      BEGIN
        EXECUTE 'SELECT ' || v_appel;
        RAISE EXCEPTION 'L110: % accepte pour un controleur (aal=%)', v_appel, coalesce(v_aal,'absent');
      EXCEPTION WHEN insufficient_privilege THEN
        IF SQLSTATE <> '42501' OR SQLERRM <> 'seconde étape de connexion requise' THEN
          RAISE EXCEPTION 'L110: % refuse pour une autre raison (%, %)', v_appel, SQLSTATE, SQLERRM;
        END IF;
      END;
    END LOOP;
  END LOOP;
END $refus$;

-- 3. Controleur en aal2 : la seconde etape ne bloque plus.
RESET ROLE;
SELECT pg_temp.jeton('a1100000-0000-0000-0000-000000000002','controller','aal2');
SET LOCAL ROLE authenticated;
DO $ok$
DECLARE v_id uuid; v_r jsonb;
BEGIN
  v_id := public.rejoindre_observation('a1120000-0000-0000-0000-000000000001'::uuid);
  IF v_id IS DISTINCT FROM 'a1120000-0000-0000-0000-000000000001'::uuid THEN
    RAISE EXCEPTION 'L110: rejoindre_observation aal2 devait rendre la seance';
  END IF;
  v_r := public.ma_mission_controle();
  IF v_r IS NULL THEN RAISE EXCEPTION 'L110: ma_mission_controle aal2 devait rendre un jsonb'; END IF;
  v_r := public.controleur_lister_fils();
  IF jsonb_typeof(v_r) <> 'array' THEN RAISE EXCEPTION 'L110: controleur_lister_fils aal2 devait rendre un tableau'; END IF;
  v_r := public.controleur_lister_rapports();
  IF jsonb_typeof(v_r) <> 'array' THEN RAISE EXCEPTION 'L110: controleur_lister_rapports aal2 devait rendre un tableau'; END IF;
END $ok$;

RESET ROLE;
DO $part$ DECLARE v_id uuid := 'a1120000-0000-0000-0000-000000000001'; BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.session_participants
                  WHERE session_id = v_id AND profile_id = 'a1100000-0000-0000-0000-000000000002'
                    AND role = 'masked_controller' AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'L110: observateur masque absent apres rejoindre_observation en aal2';
  END IF;
END $part$;
SELECT pg_temp.jeton('a1100000-0000-0000-0000-000000000001','admin','aal1');
SET LOCAL ROLE authenticated;
-- 4. Un admin en aal1 n'est pas concerne par la garde du controleur.
DO $admin$
DECLARE v_r jsonb;
BEGIN
  v_r := public.controleur_lister_fils();
  IF jsonb_typeof(v_r) <> 'array' THEN RAISE EXCEPTION 'L110: admin aal1 refuse sur controleur_lister_fils'; END IF;
  v_r := public.controleur_lister_rapports();
  IF jsonb_typeof(v_r) <> 'array' THEN RAISE EXCEPTION 'L110: admin aal1 refuse sur controleur_lister_rapports'; END IF;
  BEGIN
    PERFORM public.rejoindre_observation('a1120000-0000-0000-0000-000000000001'::uuid);
    RAISE EXCEPTION 'L110: un admin ne devait pas rejoindre une observation';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'observation reservee au controle qualite' THEN
      RAISE EXCEPTION 'L110: admin aal1 refuse par la garde MFA (%)', SQLERRM;
    END IF;
  END;
END $admin$;

RESET ROLE;
-- 5. app_account_valid() reste exige.
UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'a1100000-0000-0000-0000-000000000002';
SELECT pg_temp.jeton('a1100000-0000-0000-0000-000000000002','controller','aal2');
SET LOCAL ROLE authenticated;
DO $suspendu$
BEGIN
  BEGIN
    PERFORM public.rejoindre_observation('a1120000-0000-0000-0000-000000000001'::uuid);
    RAISE EXCEPTION 'L110: controleur suspendu en aal2 a rejoint une observation';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLSTATE <> '42501' OR SQLERRM <> 'observation reservee au controle qualite' THEN
      RAISE EXCEPTION 'L110: suspendu refuse pour une autre raison (%)', SQLERRM;
    END IF;
  END;
END $suspendu$;

RESET ROLE;
-- 6. Les fonctions guardees ne sont ouvertes ni a anon ni a service_role.
DO $acl$
BEGIN
  IF has_function_privilege('anon','public.rejoindre_observation(uuid)','EXECUTE')
     OR has_function_privilege('service_role','public.rejoindre_observation(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'L110: ACL de rejoindre_observation elargie';
  END IF;
END $acl$;

ROLLBACK;
