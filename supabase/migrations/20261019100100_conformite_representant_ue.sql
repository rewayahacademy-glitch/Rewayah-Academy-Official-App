-- Conformite (19/10/2026) : representant dans l'Union europeenne, regle par la
-- direction.
--
-- Le nom du representant dans l'UE n'est plus ecrit dans les textes de
-- l'application. Il est un reglage de `app_config`
-- (`conformite.representant_ue`), vide par defaut, modifiable par la seule
-- administration (policies existantes d'`app_config`), valide par un
-- declencheur, et lu par tout compte connecte par `representant_ue_conformite()`
-- (le nom d'un representant legal est une information publique, pas un secret).
--
-- Vide, ou lecture impossible : l'application affiche « Rewayah Academy »
-- (decision du directeur, 19/10/2026).
--
-- Modele : le responsable de la protection des enfants
-- (20261018160000_pe_protection_enfants.sql). Migration additive : aucune
-- suppression, aucun retrait de table ou de fonction.
BEGIN;

-- Le declencheur d'abord, pour que la valeur initiale soit deja controlee.
-- Le nom : un texte de 120 signes au plus, sans caractere de commande, range
-- sans espaces autour.
CREATE FUNCTION private.conformite_valider_representant_ue()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_texte text;
BEGIN
  IF NEW.key IS DISTINCT FROM 'conformite.representant_ue' THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'string' THEN
    RAISE EXCEPTION 'reglage de conformite : un texte est attendu';
  END IF;
  v_texte := pg_catalog.btrim(NEW.value #>> '{}');
  IF v_texte ~ '[[:cntrl:]]' THEN
    RAISE EXCEPTION 'reglage de conformite : caractere interdit';
  END IF;
  IF pg_catalog.char_length(v_texte) > 120 THEN
    RAISE EXCEPTION 'reglage de conformite : nom trop long';
  END IF;
  NEW.value := pg_catalog.to_jsonb(v_texte);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_conformite_representant_ue
BEFORE INSERT OR UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION private.conformite_valider_representant_ue();

INSERT INTO public.app_config (key, value) VALUES
  ('conformite.representant_ue', '""'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Le representant, lu par les textes juridiques. Vide tant que la direction
-- n'a rien saisi : l'application affiche alors « Rewayah Academy ».
CREATE FUNCTION public.representant_ue_conformite()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'nom', coalesce((SELECT c.value #>> '{}' FROM public.app_config c
                      WHERE c.key = 'conformite.representant_ue'), ''));
$function$;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.representant_ue_conformite()'::regprocedure;
BEGIN
  REVOKE ALL ON FUNCTION private.conformite_valider_representant_ue()
    FROM PUBLIC, anon, authenticated, service_role, agent_ro;

  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-19. Conformite, representant dans l''UE.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
    'AUTHENTICATED_PUBLIC_CONTACT'));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.representant_ue_conformite()'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'Conformite : droits ou search_path invalides sur %', v_oid::text;
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.conformite_valider_representant_ue()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'Conformite : le declencheur de validation ne doit pas etre appelable';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'conformite.representant_ue') THEN
    RAISE EXCEPTION 'Conformite : reglage du representant dans l''UE absent';
  END IF;
END;
$postflight$;

COMMIT;
