-- HYGIENE-2, point 10 (08/11/2026, audit des gardes Codex ; plage reservee
-- par le garde-cap : 20261122100000-20261122199999). DONNEES PERSONNELLES :
-- duree de conservation des pieces d'identite. Ne s'installe que sur
-- decision du directeur (pilote et garde-cap, 08/11).
--
-- Le defaut, prouve sur une base rejouee depuis le depot (Postgres 17) :
-- public.completer_kyc_document(), declencheur BEFORE INSERT de
-- public.kyc_documents, ne posait la date de purge que si l'insertion n'en
-- fournissait pas. Un compte qui depose sa propre piece par PostgREST
-- (kyc_staff_self_insert, kyc_guardian_insert) pouvait donc fixer purge_at
-- a 2100 et garder sa piece au-dela de la duree de conservation
-- (kyc_retention_days, 90 jours par defaut). Ecart deja note CAND-Q21 dans
-- 20261021220000_cand_l1b_forme_compte_candidat.sql.
--
-- Ce que fait ce fichier, et rien d'autre : la base pose TOUJOURS
-- purge_at = now() + kyc_retention_days a l'insertion, quelle que soit la
-- valeur fournie. Le genre, le refus d'un genre inconnu, la duree lue dans
-- la configuration, le proprietaire et les droits ne changent pas.
--
-- Chemins d'UPDATE, inchanges : ce declencheur ne s'arme que sur INSERT.
-- Le seul UPDATE de purge_at dans le depot est l'anonymisation d'un compte
-- (20261018150000_cpt_suppression_export.sql : purge_at ramene a
-- maintenant pour une purge anticipee) ; il ne passe pas par ici et n'est
-- pas touche. Aucun chemin de prolongation ni de gel legal n'ecrit
-- purge_at dans le depot.
--
-- PREFLIGHT : md5(pg_get_functiondef) relu sur une base rejouee depuis le
-- depot : 55e4cc15937dcb0b70a28ac0471ef7b8. A verifier en production par le
-- pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef('public.completer_kyc_document()'::regprocedure));
-- Une definition differente, sans le marqueur de ce lot, arrete le fichier.
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot
-- d'effacement : applicable par apply_migration.

CREATE OR REPLACE FUNCTION pg_temp.hyg2_remplacer(p_f pg_catalog.regprocedure, p_md5 text, p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, 'HYGIENE-2') > 0 THEN
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

DO $retouche$
BEGIN
  PERFORM pg_temp.hyg2_remplacer('public.completer_kyc_document()'::regprocedure,
    '55e4cc15937dcb0b70a28ac0471ef7b8',
    $a$  if new.purge_at is null then
    new.purge_at := now() + make_interval(days =>
      coalesce((public.get_config('kyc_retention_days', '90'::jsonb) #>> '{}')::int, 90));
  end if;$a$,
    $b$  -- HYGIENE-2 (08/11/2026) : la date de purge est toujours celle de la
  -- base ; une valeur fournie par le deposant est ignoree.
  new.purge_at := now() + make_interval(days =>
    coalesce((public.get_config('kyc_retention_days', '90'::jsonb) #>> '{}')::int, 90));$b$);
END
$retouche$;

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.completer_kyc_document()'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'HYGIENE-2') = 0
     OR pg_catalog.strpos(v_def, 'if new.purge_at is null') > 0
     OR pg_catalog.strpos(v_def, 'kyc_retention_days') = 0
     OR pg_catalog.strpos(v_def, 'new.gender := v_genre') = 0
     OR pg_catalog.strpos(v_def, 'genre du titulaire inconnu') = 0 THEN
    RAISE EXCEPTION 'HYGIENE-2 postflight : completer_kyc_document incomplete';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.completer_kyc_document()'::regprocedure AND p.prosecdef
          AND p.proconfig @> array['search_path=""']::text[]
          AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
    RAISE EXCEPTION 'HYGIENE-2 postflight : DEFINER, search_path ou proprietaire incorrect';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.completer_kyc_document()', 'EXECUTE') THEN
    RAISE EXCEPTION 'HYGIENE-2 postflight : droits EXECUTE modifies';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgrelid = 'public.kyc_documents'::regclass
          AND t.tgname = 'kyc_documents_completer'
          AND t.tgfoid = 'public.completer_kyc_document()'::regprocedure
          AND NOT t.tgisinternal AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'HYGIENE-2 postflight : declencheur kyc_documents_completer absent ou inactif';
  END IF;
END
$postflight$;
