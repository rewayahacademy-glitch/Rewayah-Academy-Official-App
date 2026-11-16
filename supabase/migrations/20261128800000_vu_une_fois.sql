-- VU-UNE-FOIS (directeur, 16/11/2026 : « tout ce qui est utile une seule fois ne doit pas
-- rester indefiniment »). Ce qu'une personne a deja vu ou compris ne lui est plus montre :
-- une fois dans la vie du COMPTE, pas de l'appareil.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : une table, deux fonctions.
-- Sans BEGIN/COMMIT de premier niveau : apply_migration est deja atomique.
--
-- Reutilisation : `nouveautes_vues` (NOUVEAUTES, 07/11) suit un badge « Nouveau » de 14 jours et
-- sa cle est une cle etrangere vers `nouveautes` ; elle ne convient pas a une aide, un tour guide
-- ou une explication a ne montrer qu'une fois. Meme patron (une ligne par compte et par cle,
-- jamais effacee, idempotent, titulaire seul), table distincte.
--
-- 1. `public.vus_une_fois` : (compte, cle, vu_le). Aucune ecriture client.
-- 2. `lire_vus()` : les cles que la personne connectee a deja vues. Lecture seule.
-- 3. `marquer_vu(p_cle)` : la personne a vu cette chose. Idempotent. Cle au format borne
--    (minuscules, chiffres, _ . -, 3 a 60 caracteres, commence par une lettre), et au plus
--    200 cles par compte : une cle fantaisiste ne grossit pas la table sans limite.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.vus_une_fois') IS NOT NULL THEN
    RAISE EXCEPTION 'VU-UNE-FOIS : deja installee';
  END IF;
END
$preflight$;

CREATE TABLE public.vus_une_fois (
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  cle text NOT NULL CHECK (cle ~ '^[a-z][a-z0-9_.-]{2,59}$'),
  vu_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (profile_id, cle)
);
ALTER TABLE public.vus_une_fois ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vus_une_fois FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.vus_une_fois TO authenticated;
CREATE POLICY vus_une_fois_lecture ON public.vus_une_fois
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid());
COMMENT ON TABLE public.vus_une_fois IS
  'VU-UNE-FOIS (16/11/2026) : ce que la personne a deja vu (aide, explication, tour) ; ne revient plus, '
  'sur aucun appareil. Ecrite par marquer_vu seulement.';

CREATE FUNCTION public.lire_vus()
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(v.cle ORDER BY v.cle), ARRAY[]::text[])
    FROM public.vus_une_fois v
   WHERE auth.uid() IS NOT NULL
     AND coalesce(public.app_account_valid(), false)
     AND v.profile_id = auth.uid();
$function$;
ALTER FUNCTION public.lire_vus() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_vus() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_vus() TO authenticated;

CREATE FUNCTION public.marquer_vu(p_cle text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a un compte valide' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR p_cle !~ '^[a-z][a-z0-9_.-]{2,59}$' THEN
    RAISE EXCEPTION 'cle invalide' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.vus_une_fois WHERE profile_id = v_moi AND cle = p_cle) THEN
    RETURN true;
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.vus_une_fois WHERE profile_id = v_moi) >= 200 THEN
    RAISE EXCEPTION 'trop de cles' USING ERRCODE = '54000';
  END IF;
  INSERT INTO public.vus_une_fois (profile_id, cle)
  VALUES (v_moi, p_cle)
  ON CONFLICT (profile_id, cle) DO NOTHING;
  RETURN true;
END;
$function$;
ALTER FUNCTION public.marquer_vu(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.marquer_vu(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.marquer_vu(text) TO authenticated;

COMMENT ON FUNCTION public.lire_vus() IS
  'F86: signature=public.lire_vus(); guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-16. Lecture seule : les cles deja vues par le compte valide connecte.';
COMMENT ON FUNCTION public.marquer_vu(text) IS
  'F86: signature=public.marquer_vu(text); guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-16. Garde : compte valide, cle au format borne, 200 cles au plus ; idempotent.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY['public.lire_vus()'::regprocedure,
                               'public.marquer_vu(text)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                      AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'VU-UNE-FOIS : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.vus_une_fois', 'INSERT')
     OR pg_catalog.has_table_privilege('anon', 'public.vus_une_fois', 'SELECT') THEN
    RAISE EXCEPTION 'VU-UNE-FOIS : droits de table invalides';
  END IF;
END
$postflight$;
