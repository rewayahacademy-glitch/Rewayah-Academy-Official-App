-- PRAXIS-ROUTINE (migration 20261129900000) : le pouls de la routine horaire de Praxis.
--   0 etat apres installation : aucun tir, rien d'allume, derniereRoutine NULL ;
--   1 interrupteur coupe : terminer refuse `eteint` ; 2 autonome faux : refuse `autonome_requis` (journalise) ;
--   3 une cle de chat est refusee `hors_portee` ; 4 autonome vrai : le tir se note et la direction le lit (le DERNIER) ;
--   5 parametres hors bornes refuses `parametre`, rien d'ecrit, journalise ; 6 cle inconnue ; 7 droits (service_role seul, table fermee).
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'ROUTINE ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.appel(p_id uuid, p_role text, p_aal text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_aal text, p_sql text, p_code text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_passe boolean := false; v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN RAISE EXCEPTION 'ROUTINE ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'ROUTINE ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text),
  pg_temp.refus(uuid, text, text, text, text, text), pg_temp.srv(text) TO authenticated, anon, service_role;


-- Fixture : une direction (super-administration), un tuteur adulte, un fil de l'academie.
CREATE FUNCTION pg_temp.u(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b9000000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(integer) TO authenticated, anon, service_role;
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n), 'rt-' || n || '@test.invalid' FROM generate_series(1, 3) n;
INSERT INTO public.households (id, timezone) VALUES ('b9ffffff-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(1), 'RT-ADM-0001', 'admin', NULL, 'Direction', 'Un', 'active', 'male'),
 (pg_temp.u(2), 'RT-TUT-0001', 'guardian', 'b9ffffff-0000-4000-8000-000000000001', 'Tuteur', 'Un', 'active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u(1));

CREATE FUNCTION pg_temp.nb_tirs() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM private.praxis_tirs $$;
CREATE FUNCTION pg_temp.nb_journal(p_issue text) RETURNS bigint LANGUAGE sql AS $$
  SELECT count(*) FROM private.praxis_journal WHERE outil = 'terminer' AND issue = p_issue $$;
CREATE FUNCTION pg_temp.etat() RETURNS jsonb LANGUAGE sql AS $$ SELECT public.direction_praxis_etat() $$;
GRANT EXECUTE ON FUNCTION pg_temp.nb_tirs(), pg_temp.nb_journal(text), pg_temp.etat() TO authenticated, anon, service_role;

-- Les deux cles : chat et routine (emises par la direction, aal2).
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Chat de test', 'chat', pg_catalog.now() + interval '30 days', 'b9222222-0000-4000-8000-000000000001'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle_chat \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Routine de test', 'routine', pg_catalog.now() + interval '30 days', 'b9222222-0000-4000-8000-000000000002'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle_routine \gset

-- ============ 0 : etat apres installation ============
SELECT pg_temp.vrai(pg_temp.nb_tirs() = 0, '0 : aucun tir note apres installation');
SELECT pg_temp.vrai((SELECT NOT r.actif AND NOT r.autonome AND NOT r.donnees_reelles FROM private.praxis_reglages r),
  '0 : actif, autonome et donnees_reelles sont faux : la migration n''allume rien');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_etat()') AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ? 'derniereRoutine' AND :'j'::jsonb -> 'derniereRoutine' = 'null'::jsonb,
  '0 : l''etat de la direction rend derniereRoutine NULL tant qu''aucun tir n''est note');

-- ============ 1 : interrupteur coupe : rien ne s'ecrit ============
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 1, 1, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"eteint"}'::jsonb AND pg_temp.nb_tirs() = 0, '1 : praxis.actif faux : terminer est refuse `eteint`, aucun tir');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_regler(true, false, NULL)$$);

-- ============ 2 : mode autonome faux : la cle de routine est refusee ============
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 1, 1, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"autonome_requis"}'::jsonb AND pg_temp.nb_tirs() = 0,
  '2 : autonome faux : terminer par la cle de routine est refuse `autonome_requis`, aucun tir');
SELECT pg_temp.vrai(pg_temp.nb_journal('autonome_requis') = 1, '2 : le refus est journalise');

-- ============ 3 : une cle de chat ne se fait pas passer pour la routine ============
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 1, 1, 0, 0, NULL)', :'cle_chat')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"hors_portee"}'::jsonb AND pg_temp.nb_tirs() = 0,
  '3 : la cle de chat est refusee `hors_portee` : un chat ne note pas de tir');
SELECT pg_temp.vrai(pg_temp.nb_journal('hors_portee') = 1, '3 : le refus est journalise');

-- ============ 4 : autonome vrai : le tir se note, le pouls se voit ============
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_regler(true, true, NULL)$$);
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 7, 4, 2, 1, ''Tout va bien'')', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"ok": true}'::jsonb AND pg_temp.nb_tirs() = 1, '4 : un tir est note');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_etat()') AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb #>> '{derniereRoutine,issue}') = 'ok'
    AND (:'j'::jsonb #>> '{derniereRoutine,filsLus}')::int = 7
    AND (:'j'::jsonb #>> '{derniereRoutine,messagesEnvoyes}')::int = 4
    AND (:'j'::jsonb #>> '{derniereRoutine,passesEquipe}')::int = 2
    AND (:'j'::jsonb #>> '{derniereRoutine,refus}')::int = 1
    AND (:'j'::jsonb #>> '{derniereRoutine,note}') = 'Tout va bien'
    AND (:'j'::jsonb #>> '{derniereRoutine,termineLe}') IS NOT NULL,
  '4 : la direction lit le dernier tir (issue, compteurs, note, date)');
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''erreur'', 0, 0, 0, 3, ''Plafond atteint'')', :'cle_routine')) AS j \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_etat()') AS j \gset
SELECT pg_temp.vrai(pg_temp.nb_tirs() = 2 AND (:'j'::jsonb #>> '{derniereRoutine,issue}') = 'erreur'
    AND (:'j'::jsonb #>> '{derniereRoutine,note}') = 'Plafond atteint',
  '4 : le pouls rend toujours le DERNIER tir (deux tirs notes, le second se voit)');

-- ============ 5 : parametres refuses, rien d'ecrit ============
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''zz'', 0, 0, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_tirs() = 2, '5 : issue inconnue : refusee `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 201, 0, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_tirs() = 2, '5 : 201 fils lus : refuse `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', -1, 0, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_tirs() = 2, '5 : compteur negatif : refuse `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 0, 0, 0, 0, %L)', :'cle_routine', repeat('x', 201))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_tirs() = 2, '5 : note de 201 signes : refusee `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, NULL, 0, 0, 0, 0, NULL)', :'cle_routine')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_tirs() = 2, '5 : issue NULL : refusee `parametre`');
SELECT pg_temp.vrai(pg_temp.nb_journal('parametre') = 5, '5 : chaque refus de parametre est journalise');

-- ============ 6 : cle inconnue, revoquee ============
SELECT pg_temp.srv(format('SELECT public.praxis_terminer(%L, ''ok'', 0, 0, 0, 0, NULL)', 'prx_' || repeat('0', 64))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' = 'cle_refusee' AND pg_temp.nb_tirs() = 2, '6 : une cle inconnue est refusee, aucun tir');

-- ============ 7 : droits ============
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
    AND NOT has_function_privilege('authenticated', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
    AND NOT has_function_privilege('agent_ro', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
    AND has_function_privilege('service_role', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE'),
  '7 : seul service_role execute praxis_terminer');
SELECT pg_temp.vrai(NOT has_table_privilege('anon', 'private.praxis_tirs', 'SELECT')
    AND NOT has_table_privilege('authenticated', 'private.praxis_tirs', 'SELECT')
    AND NOT has_table_privilege('service_role', 'private.praxis_tirs', 'SELECT')
    AND NOT has_table_privilege('agent_ro', 'private.praxis_tirs', 'SELECT')
    AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.praxis_tirs'::regclass),
  '7 : private.praxis_tirs : RLS active, aucun droit de lecture direct');
SELECT pg_temp.refus(pg_temp.u(2), 'guardian', 'aal2', 'SELECT public.direction_praxis_etat()', '42501',
  '7 : un tuteur ne lit pas l''etat (donc pas le pouls)');

ROLLBACK;
\o
\echo ROUTINE POULS : tous les controles sont verts
