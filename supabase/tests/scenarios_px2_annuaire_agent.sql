-- PX-2 / AR-8 : l'annuaire de l'agent d'observation (agent_ro, parcours admin) ne montre pas le compte officiel Praxis, et montre toujours
-- les autres profils. Rouge avant la migration 20261129630000, vert apres. Rejoue sur une base NEUVE ; annule tout a la fin.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a8000000-0000-4000-8000-000000000001', 'px2-agent@example.test'),
  ('a8000000-0000-4000-8000-000000000002', 'px2-autre@example.test');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('a8000000-0000-4000-8000-000000000001', 'PX2-ADM-0001', 'admin', NULL, 'Agent', 'Observe', 'active', 'male'),
  ('a8000000-0000-4000-8000-000000000002', 'PX2-ADM-0002', 'admin', NULL, 'Autre', 'Direction', 'active', 'female');
INSERT INTO public.jetons_agent
  (id, libelle, prefixe, empreinte, profil_observe, parcours, identite_masquee, expire_le, cree_le, cree_par)
VALUES ('a8000000-0000-4000-8000-000000000010', 'PX2', 'rag_a8000010', 'px2-test-fingerprint',
        'a8000000-0000-4000-8000-000000000001', 'admin', false, pg_catalog.now() + interval '1 hour', pg_catalog.now(),
        'a8000000-0000-4000-8000-000000000001');

CREATE FUNCTION pg_temp.agent() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', 'a8000000-0000-4000-8000-000000000010', true);
  PERFORM pg_catalog.set_config('test.jwt', pg_catalog.jsonb_build_object(
    'sub', 'a8000000-0000-4000-8000-000000000010', 'role', 'agent_ro',
    'app_metadata', pg_catalog.jsonb_build_object('role', 'admin', 'agent_token_id', 'a8000000-0000-4000-8000-000000000010'))::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '', true);
  PERFORM public.agent_pre_request();
END $$;

CREATE TEMP TABLE res (autre bigint, praxis bigint);
GRANT ALL ON res TO agent_ro;
SELECT pg_temp.agent();
SET LOCAL ROLE agent_ro;
INSERT INTO res SELECT (SELECT count(*) FROM public.profiles WHERE id = 'a8000000-0000-4000-8000-000000000002'),
                       (SELECT count(*) FROM public.profiles WHERE immutable_id = 'RA-OFFICIEL-PRAXIS');
RESET ROLE;

DO $$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM res;
  IF r.autre <> 1 THEN RAISE EXCEPTION 'PX2 ROUGE : l''annuaire de l''agent ne montre plus les autres profils (%)', r.autre; END IF;
  IF r.praxis <> 0 THEN RAISE EXCEPTION 'PX2 ROUGE : l''annuaire de l''agent montre le compte officiel Praxis (%)', r.praxis; END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'app_private.compte_est_officiel(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'app_private.compte_est_officiel(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX2 ROUGE : compte_est_officiel est executable par authenticated ou anon';
  END IF;
  RAISE NOTICE 'OK PX-2 AR-8 : annuaire agent_ro sans Praxis, autres profils visibles, fonction fermee';
END $$;
ROLLBACK;
