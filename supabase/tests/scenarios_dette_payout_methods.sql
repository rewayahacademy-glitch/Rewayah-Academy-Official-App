-- DETTE-PAYOUT-METHODS (migration 20261129880000, arbitrage du pilote du 17/11/2026, inventaire #600) :
-- la direction et la comptabilite ne lisent plus `payout_methods` (coordonnees de versement) par l'API ;
-- la famille garde la lecture de SES coordonnees ; `payouts` reste lisible (option B) ; `agent_ro` ne lit
-- plus les lignes ; l'export des donnees de la personne (SECURITY DEFINER) continue. Rouge avant la
-- migration (le comptable lit la ligne), vert apres.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('dd800000-0000-0000-0000-000000000001','dd8-admin@test.invalid'),
 ('dd800000-0000-0000-0000-000000000002','dd8-compta@test.invalid'),
 ('dd800000-0000-0000-0000-000000000003','dd8-tuteur@test.invalid'),
 ('dd800000-0000-0000-0000-000000000004','dd8-autre@test.invalid');
INSERT INTO public.households(id,timezone) VALUES
 ('dd840000-0000-0000-0000-000000000001','Europe/Paris'),
 ('dd840000-0000-0000-0000-000000000002','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender) VALUES
 ('dd800000-0000-0000-0000-000000000001','DD8-ADMIN-0001','admin',NULL,'Direction','DD8','active','female'),
 ('dd800000-0000-0000-0000-000000000002','DD8-ACCT-00001','accountant',NULL,'Compta','DD8','active','female'),
 ('dd800000-0000-0000-0000-000000000003','DD8-GUARD-0001','guardian','dd840000-0000-0000-0000-000000000001','Tuteur','DD8','active','female'),
 ('dd800000-0000-0000-0000-000000000004','DD8-GUARD-0002','guardian','dd840000-0000-0000-0000-000000000002','Autre','DD8','active','male');
INSERT INTO public.wallets(id,household_id,currency) VALUES
 ('dd850000-0000-0000-0000-000000000001','dd840000-0000-0000-0000-000000000001','EUR');
INSERT INTO public.payout_methods(id,profile_id,kind,details) VALUES
 ('dd860000-0000-0000-0000-000000000001','dd800000-0000-0000-0000-000000000003','bank','{"test":"dd8"}'::jsonb);
INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
VALUES ('dd850000-0000-0000-0000-000000000001','dd860000-0000-0000-0000-000000000001',500);

CREATE FUNCTION pg_temp.comme(p_uid uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  RESET ROLE;
  PERFORM set_config('request.jwt.claim.sub', p_uid::text, true);
  PERFORM set_config('test.uid', p_uid::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub',p_uid,'aal','aal2',
    'app_metadata', jsonb_build_object('role',p_role,
      'authorization_version',(SELECT authorization_version FROM public.profiles WHERE id=p_uid),
      'household_id',(SELECT household_id FROM public.profiles WHERE id=p_uid)))::text, true);
  PERFORM set_config('test.jwt', current_setting('request.jwt.claims'), true);
  SET LOCAL ROLE authenticated;
END $$;

CREATE FUNCTION pg_temp.n(p_qui text, p_table text, p_voulu bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN
  EXECUTE format('SELECT count(*) FROM public.%I', p_table) INTO v;
  IF v <> p_voulu THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: % lit % ligne(s) de % (attendu %)', p_qui, v, p_table, p_voulu;
  END IF;
END $$;

-- Une ecriture sous le role courant DOIT etre refusee (42501, droit ou politique).
CREATE FUNCTION pg_temp.refuse(p_qui text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN;
  END;
  RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: % a pu ecrire : %', p_qui, left(p_sql, 80);
END $$;

-- 1. Direction et comptabilite : plus aucune ligne de payout_methods, mais payouts reste lisible.
SELECT pg_temp.comme('dd800000-0000-0000-0000-000000000002','accountant');
SELECT pg_temp.n('comptable','payout_methods',0);
SELECT pg_temp.n('comptable','payouts',1);
SELECT pg_temp.refuse('comptable', $$INSERT INTO public.payout_methods(profile_id,kind,details)
  VALUES ('dd800000-0000-0000-0000-000000000003','bank','{}')$$);
SELECT pg_temp.comme('dd800000-0000-0000-0000-000000000001','admin');
SELECT pg_temp.n('direction','payout_methods',0);
SELECT pg_temp.n('direction','payouts',1);
SELECT pg_temp.refuse('direction', $$INSERT INTO public.payout_methods(profile_id,kind,details)
  VALUES ('dd800000-0000-0000-0000-000000000003','bank','{}')$$);

-- 2. La famille garde la lecture de SES coordonnees ; l'autre foyer ne voit rien.
SELECT pg_temp.comme('dd800000-0000-0000-0000-000000000003','guardian');
SELECT pg_temp.n('tuteur','payout_methods',1);
SELECT pg_temp.n('tuteur','payouts',1);
SELECT pg_temp.comme('dd800000-0000-0000-0000-000000000004','guardian');
SELECT pg_temp.n('autre foyer','payout_methods',0);

-- 3. L'export des donnees de la personne (SECURITY DEFINER) continue de dire que des coordonnees existent.
SELECT pg_temp.comme('dd800000-0000-0000-0000-000000000003','guardian');
DO $$
DECLARE v jsonb;
BEGIN
  v := public.mes_donnees_export();
  IF jsonb_array_length(v -> 'moyens_de_paiement_recus') <> 1 THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: mes_donnees_export ne rend plus le moyen de versement de la personne (%)', v -> 'moyens_de_paiement_recus';
  END IF;
END $$;

-- 4. agent_ro : le privilege reste, les lignes ne se lisent plus. Il n'a aucun jeton : les claims de la
--    session precedente (le tuteur) sont vides, sinon la lecture famille lui serait appliquee a tort.
RESET ROLE;
DO $$
DECLARE v bigint;
BEGIN
  PERFORM set_config('request.jwt.claims', '{}', true);
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('test.jwt', '{}', true);
  IF NOT has_table_privilege('agent_ro','public.payout_methods','SELECT') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: agent_ro a perdu son privilege SELECT';
  END IF;
  SET LOCAL ROLE agent_ro;
  SELECT count(*) INTO v FROM public.payout_methods;
  RESET ROLE;
  IF v <> 0 THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: agent_ro lit % ligne(s) de payout_methods (attendu 0)', v;
  END IF;
END $$;

-- 5. Catalogue : la politique de direction et comptabilite est fermee, la lecture famille n'a pas change,
--    les droits d'authenticated n'ont pas change.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='payout_methods'
                  AND policyname='payout_methods_admin_accountant_all' AND cmd='ALL'
                  AND qual='false' AND with_check='false') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: la politique de direction et comptabilite n''est pas fermee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='payout_methods'
                  AND policyname='payout_methods_family_read' AND cmd='SELECT') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: la lecture famille a disparu';
  END IF;
  IF NOT has_table_privilege('authenticated','public.payout_methods','SELECT')
     OR has_table_privilege('authenticated','public.payout_methods','INSERT')
     OR has_table_privilege('authenticated','public.payout_methods','UPDATE') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: les droits d''authenticated ont change';
  END IF;
  IF (SELECT count(*) FROM pg_policies WHERE schemaname='public' AND tablename='payouts') <> 2 THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS: les politiques de payouts ont change';
  END IF;
END $$;

RESET ROLE;
ROLLBACK;
