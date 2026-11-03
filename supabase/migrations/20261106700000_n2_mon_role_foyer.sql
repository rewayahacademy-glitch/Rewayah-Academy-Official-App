-- N2 (03/11/2026, migration ajoutee au lot N2 sur decision du pilote) : le
-- role de l'appelant dans son propre foyer, pour que l'application montre
-- « Inviter un second adulte » et « Demander la reprise du foyer » selon une
-- capacite rendue par le serveur, jamais selon un role devine.
--
-- public.mon_role_foyer() rend, pour l'appelant seul :
--   - `role` : `titulaire` (private.bf1_est_titulaire(), reutilisee telle
--     quelle), `second_adulte` (compte tuteur valide, rattache a un foyer
--     actif dont il n'est pas le titulaire) ou `aucun` ;
--   - `genre` : le genre enregistre sur SON profil (`female`, `male`), ou
--     null : l'application en tire « ma conjointe » / « mon conjoint », ou
--     une forme neutre quand rien n'est enregistre (jamais devine).
-- Aucune donnee d'une autre personne. Le refus serveur des gestes
-- (inviter_conjoint, deposer_reprise_foyer) reste la barriere.
--
-- FICHIER SANS EFFACEMENT (regle B5). Migration additive (B6) : une fonction
-- nouvelle, rien d'autre ne change.

BEGIN;

CREATE FUNCTION public.mon_role_foyer()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'role', CASE
      WHEN private.bf1_est_titulaire() THEN 'titulaire'
      WHEN coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'guardian'
                    AND public.app_account_valid(), false)
           AND EXISTS (SELECT 1 FROM public.profiles p
                         JOIN public.households h ON h.id = p.household_id
                        WHERE p.id = auth.uid()
                          AND p.role = 'guardian'
                          AND p.deleted_at IS NULL
                          AND h.status = 'active'
                          AND h.deleted_at IS NULL
                          AND h.primary_guardian_id IS DISTINCT FROM auth.uid())
        THEN 'second_adulte'
      ELSE 'aucun'
    END,
    'genre', (SELECT CASE WHEN p.gender::text IN ('female', 'male') THEN p.gender::text END
                FROM public.profiles p
               WHERE p.id = auth.uid() AND p.deleted_at IS NULL));
$function$;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.mon_role_foyer()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SELF_ONLY_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. N2 : role de l''appelant dans son foyer (titulaire, second_adulte, aucun) et son propre genre. Must-pass: supabase/tests/scenarios_n2_mon_role_foyer.sql.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- Postflight.
DO $postflight$
DECLARE
  f regprocedure := 'public.mon_role_foyer()'::regprocedure;
  v_com text;
BEGIN
  IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'N2 : droits de % incorrects', f;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f
              AND (NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""']))) THEN
    RAISE EXCEPTION 'N2 : % sans DEFINER ou search_path', f;
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(f), 'private.bf1_est_titulaire()') = 0 THEN
    RAISE EXCEPTION 'N2 : % doit reutiliser private.bf1_est_titulaire()', f;
  END IF;
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
    RAISE EXCEPTION 'N2 : empreinte F86 absente ou perimee pour %', f;
  END IF;
END;
$postflight$;

COMMIT;
