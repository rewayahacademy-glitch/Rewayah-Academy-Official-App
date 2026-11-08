-- HYGIENE-GARDES, point 7 (08/11/2026, audit des gardes Codex ; plage
-- reservee par le garde-cap : 20261121800000-20261121899999, un fichier par
-- point). N'est ni installee ni fusionnee sans decision (pilote, 08/11).
--
-- Le defaut, prouve sur une base rejouee depuis le depot (Postgres 17) : la
-- politique offres_horaires_vitrine laissait sa branche admin/controleur sans
-- app_account_valid() ; un controleur desactive, session ouverte, lisait les
-- offres en brouillon ou retirees.
--
-- Ce que fait ce fichier, et rien d'autre (forme etroite retenue par le
-- pilote, 08/11) : seule la branche admin/controleur exige un compte valide.
-- La branche « etat = 'publiee' », lue par les familles (y compris un compte
-- en pending_kyc, par la vue v_parcours_onboarding en security_invoker), ne
-- change pas. Ecartes, sans y toucher : langues_cours_lecture et
-- cohortes_age_lecture (un compte en pending_kyc doit les lire : profil de
-- l'enseignant, declencheur teacher_profiles_langues_par_code, vue
-- v_parcours_onboarding). anon n'a aucun droit sur offres_horaires ; le site
-- public lit par des fonctions DEFINER, que la politique ne touche pas.
--
-- PREFLIGHT : expression exacte de la politique relue sur une base rejouee
-- depuis le depot. A verifier en production par le pilote avant
-- l'application (lecture seule) :
--   SELECT pg_catalog.pg_get_expr(polqual, polrelid) FROM pg_catalog.pg_policy
--    WHERE polname = 'offres_horaires_vitrine';
-- Une expression differente, sans app_account_valid, arrete le fichier.
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot
-- d'effacement : applicable par apply_migration.

DO $preflight$
DECLARE
  v_pol text;
BEGIN
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_pol
    FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.offres_horaires'::regclass
     AND p.polname = 'offres_horaires_vitrine';
  IF v_pol IS NULL THEN
    RAISE EXCEPTION 'HYGIENE-GARDES : politique offres_horaires_vitrine absente';
  END IF;
  IF v_pol <> '((etat = ''publiee''::text) OR COALESCE((( SELECT app_role() AS app_role) = ANY (ARRAY[''admin''::app_role, ''controller''::app_role])), false))'
     AND pg_catalog.strpos(v_pol, 'app_account_valid') = 0 THEN
    RAISE EXCEPTION 'HYGIENE-GARDES : offres_horaires_vitrine a change (%), rien n''est change', v_pol;
  END IF;
END
$preflight$;

ALTER POLICY offres_horaires_vitrine ON public.offres_horaires
  USING (
    etat = 'publiee'
    OR COALESCE(
         (SELECT public.app_role()) IN ('admin'::public.app_role, 'controller'::public.app_role)
         AND (SELECT public.app_account_valid()),
         false)
  );

DO $postflight$
DECLARE
  v_pol text;
BEGIN
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_pol
    FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.offres_horaires'::regclass
     AND p.polname = 'offres_horaires_vitrine';
  IF pg_catalog.strpos(v_pol, 'app_account_valid') = 0
     OR pg_catalog.strpos(v_pol, '''publiee''') = 0 THEN
    RAISE EXCEPTION 'HYGIENE-GARDES postflight : offres_horaires_vitrine incomplete (%)', v_pol;
  END IF;
END
$postflight$;
