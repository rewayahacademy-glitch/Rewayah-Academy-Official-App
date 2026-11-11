-- GARDE-COMPTE-DESACTIVE (08/11/2026, audit des gardes Codex sans equivalent,
-- decision du pilote ; plage reservee par le garde-cap : 20261121500000).
-- N'EST PAS INSTALLEE sans la decision du directeur (pilote et garde-cap,
-- 08/11) : un compte desactive et la securite sont a lui.
--
-- Le defaut, prouve sur une base rejouee depuis main 5b504e41 (Postgres 17) :
-- public.partie_concernee(uuid) rendait vrai pour app_role() in ('admin',
-- 'controller') SANS app_account_valid(). Le jeton d'un compte desactive
-- garde son role (custom_access_token_hook ne lit pas account_status) ; un
-- ancien admin ou controleur, session ouverte, lisait donc les
-- disponibilites (weekly_availability, availability_slots), les reglages de
-- priere avec la position du domicile (prayer_settings), les derogations
-- (rule_overrides), les demandes (matching_requests), les affectations
-- (teacher_student_assignments) de tout le monde, et cherchait toute personne
-- par matricule (rechercher_personne_par_matricule). La politique
-- intentions_horaire_parties avait sa propre branche admin/controleur, avec
-- le meme oubli.
--
-- Ce que fait ce fichier, et rien d'autre :
--   1. dans partie_concernee, la branche admin/controleur exige aussi
--      app_account_valid() (exigence positive, coalesce : une inconnue ferme) ;
--   2. la branche admin/controleur de la politique intentions_horaire_parties
--      (ALTER POLICY) exige de meme app_account_valid().
-- Les branches famille, la lecture de soi et celle de l'enseignant ne
-- changent pas : l'ecran du compte suspendu et le parcours pending_kyc
-- continuent de lire ce qu'ils lisaient. Le hook de jeton et les
-- bannissements ne sont pas touches (decision du pilote).
--
-- PREFLIGHT : md5(pg_get_functiondef) de partie_concernee relu sur une base
-- rejouee depuis le depot : 93246cc682b28eef3b910b8448e3a2ec ; expression de
-- la politique relue telle quelle. A verifier en production par le pilote
-- avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef(
--            'public.partie_concernee(uuid)'::regprocedure));
--   SELECT pg_catalog.pg_get_expr(polqual, polrelid) FROM pg_catalog.pg_policy
--    WHERE polname = 'intentions_horaire_parties';
-- Une definition differente, sans le marqueur de ce lot, arrete le fichier.
-- Rejouable : deja applique, rien n'est refait.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $preflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.partie_concernee(uuid)'::regprocedure);
  v_pol text;
BEGIN
  IF pg_catalog.md5(v_def) <> '93246cc682b28eef3b910b8448e3a2ec'
     AND pg_catalog.strpos(v_def, 'GARDE-COMPTE-DESACTIVE') = 0 THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE : partie_concernee a change (md5 %), rien n''est change',
      pg_catalog.md5(v_def);
  END IF;
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_pol
    FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.intentions_horaire'::regclass
     AND p.polname = 'intentions_horaire_parties';
  IF v_pol IS NULL THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE : politique intentions_horaire_parties absente';
  END IF;
  IF v_pol <> '(partie_concernee(eleve_id) OR COALESCE((( SELECT app_role() AS app_role) = ANY (ARRAY[''admin''::app_role, ''controller''::app_role])), false))'
     AND pg_catalog.strpos(v_pol, 'app_account_valid') = 0 THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE : intentions_horaire_parties a change (%), rien n''est change', v_pol;
  END IF;
END
$preflight$;

-- 1. partie_concernee : remplacement ANCRE de la seule branche admin/controleur.
DO $retouche$
DECLARE
  v_f constant pg_catalog.regprocedure := 'public.partie_concernee(uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef('public.partie_concernee(uuid)'::regprocedure);
  v_avant constant text := $a$  select
    public.app_role() in ('admin', 'controller')
    or p_profile_id = auth.uid()$a$;
  v_apres constant text := $b$  select
    -- GARDE-COMPTE-DESACTIVE (08/11/2026) : la branche admin/controleur exige
    -- un compte valide ; un compte desactive ne lit plus les dossiers des autres.
    coalesce(public.app_role() in ('admin', 'controller') and public.app_account_valid(), false)
    or p_profile_id = auth.uid()$b$;
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, 'GARDE-COMPTE-DESACTIVE') > 0 THEN
    RAISE NOTICE 'GARDE-COMPTE-DESACTIVE : partie_concernee deja retouchee';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1, migration a revoir', v_f, v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END
$retouche$;

-- 2. intentions_horaire_parties : la branche admin/controleur exige un compte valide.
ALTER POLICY intentions_horaire_parties ON public.intentions_horaire
  USING (
    public.partie_concernee(eleve_id)
    OR COALESCE(
         (SELECT public.app_role()) IN ('admin'::public.app_role, 'controller'::public.app_role)
         AND (SELECT public.app_account_valid()),
         false)
  );

-- Postflight : retouches presentes, droits et proprietes inchanges.
DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.partie_concernee(uuid)'::regprocedure);
  v_pol text;
BEGIN
  IF pg_catalog.strpos(v_def, 'GARDE-COMPTE-DESACTIVE') = 0
     OR pg_catalog.strpos(v_def, 'public.app_account_valid()') = 0
     OR pg_catalog.strpos(v_def, 'p_profile_id = auth.uid()') = 0
     OR pg_catalog.strpos(v_def, 'eleve.household_id = public.app_household_id()') = 0 THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE postflight : partie_concernee incomplete';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.partie_concernee(uuid)'::regprocedure
          AND p.prosecdef
          AND p.proconfig @> array['search_path=""']::text[]
          AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE postflight : DEFINER, search_path ou proprietaire incorrect';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.partie_concernee(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.partie_concernee(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE postflight : droits EXECUTE incorrects';
  END IF;
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_pol
    FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.intentions_horaire'::regclass
     AND p.polname = 'intentions_horaire_parties';
  IF pg_catalog.strpos(v_pol, 'app_account_valid') = 0
     OR pg_catalog.strpos(v_pol, 'partie_concernee(eleve_id)') = 0 THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE postflight : intentions_horaire_parties incomplete (%)', v_pol;
  END IF;
END
$postflight$;
