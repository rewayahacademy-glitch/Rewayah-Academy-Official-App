-- DETTE-COMPTABLE-2 (migration 20261129830000) : la comptabilite ne peut plus ECRIRE dans wallets ni
-- INSERER dans wallet_entries par l'API ; la direction ne peut plus ecrire dans wallets (elle garde
-- l'insertion au grand livre : correction par ecriture inverse, audit L1-06 du 16/10) ; les deux gardent
-- la lecture (wallets, payouts, wallet_entries, payout_methods : GARDE-VERSEMENTS du 08/11) ; la famille
-- garde la sienne. Rouge avant la migration (un credit forge par la comptabilite passe), vert apres.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('dc800000-0000-0000-0000-000000000001','dc8-admin@test.invalid'),
 ('dc800000-0000-0000-0000-000000000002','dc8-compta@test.invalid'),
 ('dc800000-0000-0000-0000-000000000003','dc8-tuteur@test.invalid'),
 ('dc800000-0000-0000-0000-000000000004','dc8-autre@test.invalid');
INSERT INTO public.households(id,timezone) VALUES
 ('dc840000-0000-0000-0000-000000000001','Europe/Paris'),
 ('dc840000-0000-0000-0000-000000000002','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender) VALUES
 ('dc800000-0000-0000-0000-000000000001','DC8-ADMIN-0001','admin',NULL,'Direction','DC8','active','female'),
 ('dc800000-0000-0000-0000-000000000002','DC8-ACCT-00001','accountant',NULL,'Compta','DC8','active','female'),
 ('dc800000-0000-0000-0000-000000000003','DC8-GUARD-0001','guardian','dc840000-0000-0000-0000-000000000001','Tuteur','DC8','active','female'),
 ('dc800000-0000-0000-0000-000000000004','DC8-GUARD-0002','guardian','dc840000-0000-0000-0000-000000000002','Autre','DC8','active','male');
INSERT INTO public.wallets(id,household_id,currency) VALUES
 ('dc850000-0000-0000-0000-000000000001','dc840000-0000-0000-0000-000000000001','EUR'),
 ('dc850000-0000-0000-0000-000000000002','dc840000-0000-0000-0000-000000000002','EUR');
INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type)
VALUES ('dc850000-0000-0000-0000-000000000001',1000,'EUR','credit');
INSERT INTO public.payout_methods(id,profile_id,kind,details) VALUES
 ('dc860000-0000-0000-0000-000000000001','dc800000-0000-0000-0000-000000000003','bank','{"test":"dc8"}'::jsonb);
INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
VALUES ('dc850000-0000-0000-0000-000000000001','dc860000-0000-0000-0000-000000000001',500);

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

-- Execute une ecriture sous le role courant ; elle DOIT etre refusee (42501, droit ou politique).
CREATE FUNCTION pg_temp.refuse(p_qui text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN;
  END;
  RAISE EXCEPTION 'DETTE-COMPTABLE-2: % a pu ecrire : %', p_qui, left(p_sql, 80);
END $$;

CREATE FUNCTION pg_temp.n(p_qui text, p_table text, p_voulu bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN
  EXECUTE format('SELECT count(*) FROM public.%I', p_table) INTO v;
  IF v <> p_voulu THEN
    RAISE EXCEPTION 'DETTE-COMPTABLE-2: % lit % ligne(s) de % (attendu %)', p_qui, v, p_table, p_voulu;
  END IF;
END $$;

-- Ecritures par l'API : refusees a la comptabilite et a la direction.
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000002','accountant');
SELECT pg_temp.refuse('comptable', $$INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type)
  VALUES ('dc850000-0000-0000-0000-000000000002',999999,'EUR','credit')$$);
SELECT pg_temp.refuse('comptable', $$UPDATE public.wallets SET household_id='dc840000-0000-0000-0000-000000000001'
  WHERE id='dc850000-0000-0000-0000-000000000002'$$);
SELECT pg_temp.refuse('comptable', $$UPDATE public.wallets SET currency='USD' WHERE id='dc850000-0000-0000-0000-000000000002'$$);
SELECT pg_temp.refuse('comptable', $$DELETE FROM public.wallets WHERE id='dc850000-0000-0000-0000-000000000002'$$);
SELECT pg_temp.refuse('comptable', $$INSERT INTO public.wallets(household_id) VALUES ('dc840000-0000-0000-0000-000000000099')$$);
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000001','admin');
SELECT pg_temp.refuse('direction', $$DELETE FROM public.wallets WHERE id='dc850000-0000-0000-0000-000000000002'$$);
SELECT pg_temp.refuse('direction', $$UPDATE public.wallets SET currency='USD' WHERE id='dc850000-0000-0000-0000-000000000002'$$);
-- La direction garde l'insertion au grand livre (correction par ecriture inverse, L1-06) : decision a relire.
INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type)
  VALUES ('dc850000-0000-0000-0000-000000000001',-1,'EUR','adjustment');
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000003','guardian');
SELECT pg_temp.refuse('tuteur', $$INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type)
  VALUES ('dc850000-0000-0000-0000-000000000001',999999,'EUR','credit')$$);

-- Lectures conservees pour la direction et la comptabilite (GARDE-VERSEMENTS du 08/11 : moyens de versement compris).
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000002','accountant');
SELECT pg_temp.n('comptable','wallets',2);
SELECT pg_temp.n('comptable','wallet_entries',2);
SELECT pg_temp.n('comptable','payouts',1);
SELECT pg_temp.n('comptable','payout_methods',1);
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000001','admin');
SELECT pg_temp.n('direction','wallets',2);
SELECT pg_temp.n('direction','wallet_entries',2);
SELECT pg_temp.n('direction','payouts',1);
SELECT pg_temp.n('direction','payout_methods',1);

-- La famille garde la sienne ; l'autre foyer ne voit rien du premier.
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000003','guardian');
SELECT pg_temp.n('tuteur','wallets',1);
SELECT pg_temp.n('tuteur','wallet_entries',2);
SELECT pg_temp.n('tuteur','payouts',1);
SELECT pg_temp.n('tuteur','payout_methods',1);
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000004','guardian');
SELECT pg_temp.n('autre foyer','wallet_entries',0);
SELECT pg_temp.n('autre foyer','payout_methods',0);

-- La recherche de reference financiere (fonction INVOKER) lit encore le grand livre pour la comptabilite.
SELECT pg_temp.comme('dc800000-0000-0000-0000-000000000002','accountant');
DO $$
DECLARE v jsonb;
BEGIN
  v := public.rech_d4_rechercher_reference_finance(gen_random_uuid());
  IF v -> 'items' IS NULL THEN
    RAISE EXCEPTION 'DETTE-COMPTABLE-2: la recherche de reference financiere ne repond plus';
  END IF;
END $$;

RESET ROLE;
ROLLBACK;
