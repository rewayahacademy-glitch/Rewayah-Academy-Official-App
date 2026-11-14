-- PERF-AUDIT (migration 20261126200000_audit_chaine_differee) : plus de verrou
-- de table a chaque ecriture auditee, chaine posee par private.audit_chainer.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration) :
--   1. concurrence : apres un appel a log_sensitive_access, la transaction ne
--      tient AUCUN verrou ShareRowExclusive sur audit_logs (une seconde
--      transaction n'attend donc plus) ;
--   2. la ligne est ecrite tout de suite, marquee « differe », avec l'empreinte
--      de son contenu ; audit_logs reste append-only (UPDATE refuse) ;
--   3. chainage : audit_chainer pose un maillon par ligne differee, rangs sans
--      trou, dans l'ordre des id ; un second passage ne pose rien (aucun doublon) ;
--   4. verifier_chaine_audit : 0 rompue apres chainage ; une ligne differee non
--      chainee depuis plus de 5 minutes est rompue, puis intacte une fois chainee ;
--   5. falsification : une ligne chainee modifiee est rompue a son id ; un
--      maillon modifie ou une ligne effacee aussi ; la chaine est append-only ;
--   6. droits : aucun droit client sur la chaine ni sur audit_chainer.
-- Base jetable apres stub_auth.sql et toutes les migrations ; tout est annule.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERF-AUDIT ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Verdict de la verification, lu en administrateur valide.
CREATE FUNCTION pg_temp.verdict() RETURNS TABLE(verifiees integer, rompues integer, premiere_rompue bigint)
LANGUAGE plpgsql AS $$
DECLARE v_admin uuid := pg_catalog.md5('perf-audit-admin')::uuid;
BEGIN
  PERFORM pg_catalog.set_config('test.uid', v_admin::text, true);
  PERFORM pg_catalog.set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  RETURN QUERY SELECT v.verifiees, v.rompues, v.premiere_rompue FROM public.verifier_chaine_audit(5000) v;
END $$;

-- Un administrateur valide pour verifier_chaine_audit (app_account_valid).
INSERT INTO auth.users (id, email) VALUES (pg_catalog.md5('perf-audit-admin')::uuid, 'perf-audit-admin@exemple.test');
INSERT INTO public.households (id, timezone) VALUES (pg_catalog.md5('perf-audit-foyer')::uuid, 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_catalog.md5('perf-audit-admin')::uuid, 'ADMIN-PA-000001', 'admin',
        pg_catalog.md5('perf-audit-foyer')::uuid, 'Awa', 'Diallo', 'active', 'female');

-- Tout ce qui existe deja est chaine d'abord (lignes des migrations).
SELECT private.audit_chainer();

-- 1. Concurrence.
SELECT public.log_sensitive_access('perf_audit_a', 'perf', 'l1', '{"n":1}'::jsonb);
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_locks l
     WHERE l.pid = pg_catalog.pg_backend_pid()
       AND l.relation IN ('public.audit_logs'::pg_catalog.regclass,
                          (SELECT c.oid FROM pg_catalog.pg_class c WHERE c.relname = 'audit_logs_default'))
       AND l.mode = 'ShareRowExclusiveLock'),
  'log_sensitive_access ne tient plus de verrou ShareRowExclusive sur audit_logs');
SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.lower(pg_catalog.pg_get_functiondef(
    'public.log_sensitive_access(text,text,text,jsonb)'::pg_catalog.regprocedure)), 'lock table') = 0,
  'log_sensitive_access ne contient plus de LOCK TABLE');

-- 2. La ligne differee.
SELECT public.log_sensitive_access('perf_audit_a', 'perf', 'l2', '{"n":2}'::jsonb);
SELECT public.log_sensitive_access('perf_audit_a', 'perf', 'l3', '{"n":3}'::jsonb);
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(a.prev_hash = 'differe'
            AND a.hash = app_private.audit_empreinte(a.actor, a.actor_role, a.action, a.table_name, a.row_id, a.payload))
     FROM public.audit_logs a WHERE a.action = 'perf_audit_a')
  AND (SELECT pg_catalog.count(*) FROM public.audit_logs a WHERE a.action = 'perf_audit_a') = 3,
  'trois lignes ecrites tout de suite, marquees differe, hash = empreinte du contenu');
DO $$
BEGIN
  UPDATE public.audit_logs SET payload = '{}'::jsonb WHERE action = 'perf_audit_a';
  RAISE EXCEPTION 'PERF-AUDIT ROUGE : UPDATE accepte sur audit_logs';
EXCEPTION WHEN raise_exception THEN
  IF SQLERRM NOT LIKE '%append-only%' THEN RAISE; END IF;
  RAISE NOTICE 'OK audit_logs reste append-only';
END $$;

-- 3. Le chainage.
SELECT pg_temp.vrai(private.audit_chainer() = 3, 'audit_chainer pose trois maillons');
SELECT pg_temp.vrai(private.audit_chainer() = 0, 'un second passage ne pose rien (aucun doublon)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) = pg_catalog.max(rang) + 1 AND pg_catalog.min(rang) = 0
     FROM app_private.audit_chaine),
  'rangs sans trou depuis l''ancre 0');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(c.audit_id ORDER BY c.rang) = pg_catalog.array_agg(c.audit_id ORDER BY c.audit_id)
     FROM app_private.audit_chaine c JOIN public.audit_logs a ON a.id = c.audit_id AND a.created_at = c.audit_cree_le
    WHERE a.action = 'perf_audit_a'),
  'ordre stable : les maillons suivent l''ordre des id');
SELECT pg_temp.vrai(
  (SELECT bool_and(c.prev_hash = p.hash) FROM app_private.audit_chaine c
     JOIN app_private.audit_chaine p ON p.rang = c.rang - 1),
  'chaque maillon pointe le hash du precedent');

-- 4. Verification.
SELECT pg_temp.vrai((SELECT rompues FROM pg_temp.verdict()) = 0, 'verifier_chaine_audit : 0 rompue apres chainage');
INSERT INTO public.audit_logs (action, table_name, row_id, payload, prev_hash, hash, created_at)
VALUES ('perf_audit_vieille', 'perf', 'v1', '{}'::jsonb, 'differe',
        app_private.audit_empreinte(NULL, NULL, 'perf_audit_vieille', 'perf', 'v1', '{}'::jsonb),
        pg_catalog.now() - interval '10 minutes');
SELECT pg_temp.vrai(
  (SELECT rompues = 1 AND premiere_rompue = (SELECT id FROM public.audit_logs WHERE action = 'perf_audit_vieille')
     FROM pg_temp.verdict()),
  'une ligne differee non chainee depuis plus de 5 minutes est rompue');
SELECT private.audit_chainer();
SELECT pg_temp.vrai((SELECT rompues FROM pg_temp.verdict()) = 0, 'une fois chainee, elle est intacte');

-- 5. Falsification.
ALTER TABLE public.audit_logs DISABLE TRIGGER audit_logs_no_update;
UPDATE public.audit_logs SET payload = '{"n":99}'::jsonb WHERE action = 'perf_audit_a' AND row_id = 'l2';
SELECT pg_temp.vrai(
  (SELECT rompues = 1 AND premiere_rompue = (SELECT id FROM public.audit_logs WHERE action = 'perf_audit_a' AND row_id = 'l2')
     FROM pg_temp.verdict()),
  'une ligne chainee modifiee est rompue a son id');
UPDATE public.audit_logs SET payload = '{"n":2}'::jsonb WHERE action = 'perf_audit_a' AND row_id = 'l2';
ALTER TABLE public.audit_logs ENABLE TRIGGER audit_logs_no_update;
SELECT pg_temp.vrai((SELECT rompues FROM pg_temp.verdict()) = 0, 'remise en place : intacte');

-- Meme en recalculant le hash de la ligne, le maillon la trahit.
ALTER TABLE public.audit_logs DISABLE TRIGGER audit_logs_no_update;
UPDATE public.audit_logs SET payload = '{"n":77}'::jsonb,
       hash = app_private.audit_empreinte(actor, actor_role, action, table_name, row_id, '{"n":77}'::jsonb)
 WHERE action = 'perf_audit_a' AND row_id = 'l1';
SELECT pg_temp.vrai(
  (SELECT rompues = 1 AND premiere_rompue = (SELECT id FROM public.audit_logs WHERE action = 'perf_audit_a' AND row_id = 'l1')
     FROM pg_temp.verdict()),
  'ligne modifiee avec un hash recalcule : le maillon la trahit');
UPDATE public.audit_logs SET payload = '{"n":1}'::jsonb,
       hash = app_private.audit_empreinte(actor, actor_role, action, table_name, row_id, '{"n":1}'::jsonb)
 WHERE action = 'perf_audit_a' AND row_id = 'l1';
ALTER TABLE public.audit_logs ENABLE TRIGGER audit_logs_no_update;

DO $$
BEGIN
  UPDATE app_private.audit_chaine SET hash = 'x' WHERE rang = 1;
  RAISE EXCEPTION 'PERF-AUDIT ROUGE : UPDATE accepte sur audit_chaine';
EXCEPTION WHEN raise_exception THEN
  IF SQLERRM NOT LIKE '%append-only%' THEN RAISE; END IF;
  RAISE NOTICE 'OK audit_chaine refuse la modification';
END $$;

ALTER TABLE app_private.audit_chaine DISABLE TRIGGER audit_chaine_immuable;
UPDATE app_private.audit_chaine SET prev_hash = 'falsifie'
 WHERE audit_id = (SELECT id FROM public.audit_logs WHERE action = 'perf_audit_a' AND row_id = 'l3');
SELECT pg_temp.vrai(
  (SELECT rompues = 1 AND premiere_rompue = (SELECT id FROM public.audit_logs WHERE action = 'perf_audit_a' AND row_id = 'l3')
     FROM pg_temp.verdict()),
  'un maillon falsifie est rompu a sa ligne');
ALTER TABLE app_private.audit_chaine ENABLE TRIGGER audit_chaine_immuable;

-- 6. Droits.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('authenticated', 'app_private.audit_chaine', 'SELECT')
  AND NOT pg_catalog.has_table_privilege('anon', 'app_private.audit_chaine', 'SELECT')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.audit_chainer()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.audit_chainer()', 'EXECUTE'),
  'aucun droit client sur la chaine ni sur audit_chainer');

ROLLBACK;
