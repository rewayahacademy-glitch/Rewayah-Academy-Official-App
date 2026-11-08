-- HYGIENE-GARDES, point 5 (08/11/2026, audit des gardes Codex ; plage
-- reservee par le garde-cap : 20261121800000-20261121899999, un fichier par
-- point). N'est ni installee ni fusionnee sans decision (pilote, 08/11).
--
-- Le defaut, prouve sur une base rejouee depuis le depot (Postgres 17) : un
-- jeton agent dont la personne observee a un acces expire
-- (profiles.access_until passe) recevait encore sa session
-- (remettre_session_agent) et passait le crochet de chaque requete
-- (agent_pre_request) ; il lisait alors les tables dont les politiques ne
-- testent pas app_account_valid(). Les deux fonctions testaient account_status
-- mais pas access_until, que app_account_valid() exige pourtant.
--
-- Ce que fait ce fichier, et rien d'autre : dans les deux fonctions, la
-- lecture du profil observe exige aussi (access_until IS NULL OR
-- access_until > now()), exactement comme app_account_valid(). Rien d'autre
-- ne change (messages, codes d'erreur, journal, droits).
--
-- PREFLIGHT : md5(pg_get_functiondef) relu sur une base rejouee depuis le
-- depot : agent_pre_request() bfee15582a99155205f822798dccd6dd,
-- remettre_session_agent(text) 48b94f20722d805dc5b7052c5e3fcee9. A verifier
-- en production par le pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef('public.agent_pre_request()'::regprocedure)),
--          pg_catalog.md5(pg_catalog.pg_get_functiondef('public.remettre_session_agent(text)'::regprocedure));
-- Une definition differente, sans le marqueur de ce lot, arrete le fichier.
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot
-- d'effacement : applicable par apply_migration.

CREATE OR REPLACE FUNCTION pg_temp.hyg_remplacer(p_f pg_catalog.regprocedure, p_md5 text, p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, 'HYGIENE-GARDES') > 0 THEN
    RAISE NOTICE '% : deja retouchee, rien n''est refait', p_f;
    RETURN;
  END IF;
  IF pg_catalog.md5(v_def) <> p_md5 THEN
    RAISE EXCEPTION '% a change (md5 %), rien n''est change', p_f, pg_catalog.md5(v_def);
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1, migration a revoir', p_f, v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

DO $retouches$
BEGIN
  PERFORM pg_temp.hyg_remplacer('public.agent_pre_request()'::regprocedure,
    'bfee15582a99155205f822798dccd6dd',
    $a$     AND p.account_status IN ('active', 'provisional_active')
     AND p.role = t.parcours;$a$,
    $b$     AND p.account_status IN ('active', 'provisional_active')
     -- HYGIENE-GARDES (08/11/2026) : un acces expire ferme aussi le jeton.
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
     AND p.role = t.parcours;$b$);

  PERFORM pg_temp.hyg_remplacer('public.remettre_session_agent(text)'::regprocedure,
    '48b94f20722d805dc5b7052c5e3fcee9',
    $a$    and p.account_status in ('active', 'provisional_active');$a$,
    $b$    and p.account_status in ('active', 'provisional_active')
    -- HYGIENE-GARDES (08/11/2026) : un acces expire n'ouvre pas de session.
    and (p.access_until is null or p.access_until > now());$b$);
END
$retouches$;

DO $postflight$
DECLARE
  f pg_catalog.regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.agent_pre_request()'::regprocedure,
                           'public.remettre_session_agent(text)'::regprocedure] LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(f), 'HYGIENE-GARDES') = 0
       OR pg_catalog.strpos(pg_catalog.lower(pg_catalog.pg_get_functiondef(f)), 'access_until') = 0 THEN
      RAISE EXCEPTION 'HYGIENE-GARDES postflight : % non retouchee', f;
    END IF;
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = f AND p.prosecdef
            AND p.proconfig @> array['search_path=""']::text[]
            AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
      RAISE EXCEPTION 'HYGIENE-GARDES postflight : % : DEFINER, search_path ou proprietaire incorrect', f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'public.remettre_session_agent(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.remettre_session_agent(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.remettre_session_agent(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'HYGIENE-GARDES postflight : droits de remettre_session_agent modifies';
  END IF;
END
$postflight$;
