-- PREFERENCES-PAR-COMPTE (directeur, 11/11/2026, relaye par le pilote) : le
-- theme est porte par le COMPTE, pas par l'appareil. Constat : regle sur un
-- compte enseignant, le theme suivait sur le compte eleve du meme appareil.
--
-- La langue existe deja au compte (profiles.langue_communication,
-- ma_langue_communication, ma_langue_communication_regler, 20261023140000).
-- Le theme n'existait nulle part : cette migration l'ajoute.
--
--   * profiles.preference_theme : 'systeme' (defaut), 'clair' ou 'sombre' ;
--   * ma_preference_theme() : la valeur de sa propre ligne ;
--   * ma_preference_theme_regler(text) : l'ecrit sur sa propre ligne.
--
-- Les deux fonctions sont SECURITY DEFINER, search_path vide, limitees a
-- auth.uid(), fermees a PUBLIC et anon. La garde de profil
-- (guard_profile_privileged_columns, 20261110000000) ne porte pas sur cette
-- colonne : l'ecriture passe. Aucun effacement, aucune suppression de table.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS preference_theme text NOT NULL DEFAULT 'systeme';

DO $contrainte$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint
     WHERE conname = 'profiles_preference_theme_valeur'
       AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_preference_theme_valeur
      CHECK (preference_theme IN ('systeme', 'clair', 'sombre'));
  END IF;
END;
$contrainte$;

COMMENT ON COLUMN public.profiles.preference_theme IS
  'PREFERENCES-PAR-COMPTE (11/11/2026) : theme choisi par la personne (systeme, clair, sombre), porte par le compte. Lu et ecrit par ma_preference_theme et ma_preference_theme_regler.';

CREATE OR REPLACE FUNCTION public.ma_preference_theme()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_theme text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  SELECT p.preference_theme INTO v_theme
    FROM public.profiles p
   WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN v_theme;
END;
$function$;

CREATE OR REPLACE FUNCTION public.ma_preference_theme_regler(p_theme text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_theme text := pg_catalog.lower(pg_catalog.btrim(p_theme));
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = auth.uid() AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF v_theme IS NULL OR v_theme NOT IN ('systeme', 'clair', 'sombre') THEN
    RAISE EXCEPTION 'theme' USING ERRCODE = '22023';
  END IF;
  UPDATE public.profiles SET preference_theme = v_theme WHERE id = auth.uid();
END;
$function$;

ALTER FUNCTION public.ma_preference_theme() OWNER TO postgres;
ALTER FUNCTION public.ma_preference_theme_regler(text) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.ma_preference_theme() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ma_preference_theme_regler(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ma_preference_theme() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ma_preference_theme_regler(text) TO authenticated;

COMMENT ON FUNCTION public.ma_preference_theme() IS
  'PREFERENCES-PAR-COMPTE (11/11/2026) : le theme de la personne connectee (sa propre ligne). Refuse sans compte (42501).';
COMMENT ON FUNCTION public.ma_preference_theme_regler(text) IS
  'PREFERENCES-PAR-COMPTE (11/11/2026) : ecrit le theme de la personne connectee (systeme, clair, sombre ; sinon 22023), sur sa propre ligne seulement. Refuse sans compte (42501).';

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.ma_preference_theme()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ma_preference_theme_regler(text)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_preference_theme()'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_preference_theme_regler(text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PREFERENCES-PAR-COMPTE : droits inattendus';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc
     WHERE oid = 'public.ma_preference_theme_regler(text)'::regprocedure
       AND prosecdef AND proconfig @> ARRAY['search_path=""']
  ) THEN
    RAISE EXCEPTION 'PREFERENCES-PAR-COMPTE : fonction d''ecriture sans DEFINER ou sans search_path vide';
  END IF;
END;
$postflight$;
