-- COULEUR-PROFIL (22 i ; directeur, 05/11/2026 : « active aussi les couleurs
-- de profil, l'ecran existe mais pas branche » ; K-62, FI-2, FI-BR-19)
--
-- Une cle d'accent par profil d'apprenant, JAMAIS une couleur libre : la
-- colonne n'accepte que les six cles du jeton Flutter `AccentProfil`
-- (`lib/core/theme/accent_profil.dart`) ; nul = « Sans couleur ».
--
-- Ecriture : par `choisir_accent_profil` (SECURITY DEFINER,
-- search_path vide). Aucun droit UPDATE de colonne n'est donne a
-- `authenticated` (0005 I6 : les droits de colonne de `student_profiles` sont
-- explicites ; la nouvelle colonne n'y entre pas). Ecrivains :
--   * le tuteur au compte valide, pour tout profil d'apprenant de son foyer
--     (enfant, ou son propre profil d'apprenant titulaire, 0052) ;
--   * l'adulte autonome au compte valide, pour son propre profil.
-- Lecture : `accents_profils_du_foyer()`, meme portee que
-- `profils_du_foyer_v` (L1-02-reprise) : le tuteur lit tout son foyer,
-- l'apprenant (enfant ou adulte) sa seule ligne, jamais celle d'un frere.
--
-- Couleur par defaut (directeur, 06/11/2026) : a la creation d'un profil, une
-- couleur au hasard parmi celles que le foyer n'emploie pas encore (sinon
-- parmi les six) ; les profils deja crees la recoivent une fois (UPDATE des
-- seules lignes sans cle). Le tuteur la change ensuite.
--
-- Aucun effacement de ligne ni d'objet. Pas de BEGIN/COMMIT de premier niveau.

-- 1. La colonne et sa contrainte ---------------------------------------------

ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS accent_key text;

DO $contrainte$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint
     WHERE conrelid = 'public.student_profiles'::pg_catalog.regclass
       AND conname = 'student_profiles_accent_key_jeton'
  ) THEN
    ALTER TABLE public.student_profiles
      ADD CONSTRAINT student_profiles_accent_key_jeton
      CHECK (accent_key IS NULL
             OR accent_key IN ('menthe', 'ciel', 'lavande', 'rose', 'peche', 'sable'));
  END IF;
END;
$contrainte$;

COMMENT ON COLUMN public.student_profiles.accent_key IS
  'COULEUR-PROFIL (22 i, K-62) : cle d''accent du profil (menthe, ciel, lavande, rose, peche, sable), nul = sans couleur. Jamais une couleur libre. Ecrite par choisir_accent_profil seulement.';

-- 1 bis. Une couleur au hasard a la creation (directeur, 06/11/2026 : « par
-- defaut une couleur aleatoire est attribuee a chaque profil automatiquement
-- a sa creation, et le parent/tuteur peut la changer apres »).
--
-- Tirage parmi les couleurs que le foyer n'emploie pas encore, sinon parmi
-- les six. Seulement a l'INSERT et seulement si aucune cle n'est fournie :
-- « Sans couleur », choisi ensuite par le tuteur, n'est jamais reecrit.

CREATE OR REPLACE FUNCTION private.accent_au_hasard(p_profil uuid)
RETURNS text
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH foyer AS (
    SELECT p.household_id FROM public.profiles p WHERE p.id = p_profil
  ),
  prises AS (
    SELECT sp.accent_key
      FROM public.student_profiles sp
      JOIN public.profiles p ON p.id = sp.profile_id
     WHERE p.household_id = (SELECT household_id FROM foyer)
       AND p.household_id IS NOT NULL
       AND sp.profile_id <> p_profil
       AND sp.deleted_at IS NULL
       AND sp.accent_key IS NOT NULL
  ),
  six(cle) AS (
    VALUES ('menthe'), ('ciel'), ('lavande'), ('rose'), ('peche'), ('sable')
  ),
  libres AS (
    SELECT cle FROM six WHERE cle NOT IN (SELECT accent_key FROM prises)
  )
  SELECT coalesce(
    (SELECT cle FROM libres ORDER BY pg_catalog.random() LIMIT 1),
    (SELECT cle FROM six ORDER BY pg_catalog.random() LIMIT 1));
$function$;

REVOKE EXECUTE ON FUNCTION private.accent_au_hasard(uuid) FROM public;
REVOKE EXECUTE ON FUNCTION private.accent_au_hasard(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION private.accent_au_hasard(uuid) FROM authenticated;

CREATE OR REPLACE FUNCTION private.accent_a_la_creation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.accent_key IS NULL THEN
    NEW.accent_key := private.accent_au_hasard(NEW.profile_id);
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE EXECUTE ON FUNCTION private.accent_a_la_creation() FROM public;
REVOKE EXECUTE ON FUNCTION private.accent_a_la_creation() FROM anon;
REVOKE EXECUTE ON FUNCTION private.accent_a_la_creation() FROM authenticated;

DO $declencheur$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger
     WHERE tgrelid = 'public.student_profiles'::pg_catalog.regclass
       AND tgname = 'student_profiles_accent_a_la_creation'
  ) THEN
    CREATE TRIGGER student_profiles_accent_a_la_creation
      BEFORE INSERT ON public.student_profiles
      FOR EACH ROW EXECUTE FUNCTION private.accent_a_la_creation();
  END IF;
END;
$declencheur$;

-- Les profils deja crees recoivent leur couleur une fois, foyer par foyer,
-- profil par profil (dans l'ordre de creation), pour que deux profils d'un
-- meme foyer evitent la meme couleur tant qu'il en reste. Seuls les profils
-- sans cle ; rien n'est efface.
DO $existants$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT sp.profile_id
      FROM public.student_profiles sp
     WHERE sp.accent_key IS NULL
       AND sp.deleted_at IS NULL
     ORDER BY sp.created_at, sp.profile_id
  LOOP
    UPDATE public.student_profiles
       SET accent_key = private.accent_au_hasard(r.profile_id)
     WHERE student_profiles.profile_id = r.profile_id;
  END LOOP;
END;
$existants$;

-- 2. Lecture -----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.accents_profils_du_foyer()
RETURNS TABLE(profile_id uuid, accent_key text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT sp.profile_id, sp.accent_key
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.profile_id
   WHERE sp.accent_key IS NOT NULL
     AND sp.deleted_at IS NULL
     AND p.deleted_at IS NULL
     AND p.household_id IS NOT NULL
     AND p.household_id = public.app_household_id()
     AND coalesce(public.app_account_valid(), false)
     AND (public.app_role() = 'guardian'
          OR (public.app_role() = 'student' AND p.id = auth.uid()));
$function$;

REVOKE EXECUTE ON FUNCTION public.accents_profils_du_foyer() FROM public;
REVOKE EXECUTE ON FUNCTION public.accents_profils_du_foyer() FROM anon;
GRANT  EXECUTE ON FUNCTION public.accents_profils_du_foyer() TO authenticated;

-- 3. Ecriture ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.choisir_accent_profil(p_profil uuid, p_accent text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_accent text := nullif(pg_catalog.btrim(coalesce(p_accent, '')), '');
  v_autorise boolean;
BEGIN
  IF v_accent IS NOT NULL
     AND v_accent NOT IN ('menthe', 'ciel', 'lavande', 'rose', 'peche', 'sable') THEN
    RAISE EXCEPTION 'couleur de profil inconnue' USING ERRCODE = '22023';
  END IF;

  v_autorise := coalesce(
    p_profil IS NOT NULL
    AND auth.uid() IS NOT NULL
    AND public.app_account_valid()
    AND EXISTS (
      SELECT 1
        FROM public.student_profiles sp
        JOIN public.profiles p ON p.id = sp.profile_id
       WHERE sp.profile_id = p_profil
         AND sp.deleted_at IS NULL
         AND p.deleted_at IS NULL
         AND p.household_id IS NOT NULL
         AND p.household_id = public.app_household_id()
         AND (public.app_role() = 'guardian'
              OR (public.app_role() = 'student'
                  AND p.id = auth.uid()
                  AND sp.student_type = 'autonomous'))
    ),
    false);
  IF NOT v_autorise THEN
    RAISE EXCEPTION 'couleur reservee au tuteur du foyer ou a l''adulte pour son profil'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.student_profiles
     SET accent_key = v_accent
   WHERE student_profiles.profile_id = p_profil
     AND student_profiles.deleted_at IS NULL;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.choisir_accent_profil(uuid, text) FROM public;
REVOKE EXECUTE ON FUNCTION public.choisir_accent_profil(uuid, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.choisir_accent_profil(uuid, text) TO authenticated;

-- 4. Postflight --------------------------------------------------------------

DO $postflight$
BEGIN
  IF pg_catalog.has_column_privilege('authenticated', 'public.student_profiles', 'accent_key', 'UPDATE') THEN
    RAISE EXCEPTION 'COULEUR-PROFIL : authenticated ne doit pas ecrire accent_key en direct';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.choisir_accent_profil(uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.accents_profils_du_foyer()', 'EXECUTE') THEN
    RAISE EXCEPTION 'COULEUR-PROFIL : anon ne doit executer aucune des deux fonctions';
  END IF;
END;
$postflight$;
