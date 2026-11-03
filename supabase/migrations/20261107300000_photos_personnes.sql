-- PHOTOS-1 (03/11/2026, PLAN-LOTS §11) : une seule photo par personne, la
-- meme partout, et des droits ecrits une seule fois.
--
-- Demande du directeur (03/11) : « pour les photos il faut penser a les
-- synchroniser partout ou elles doivent etre, et c'est pour tous les roles ».
--
-- Une seule source par personne, aucune copie :
--   * eleve (mineur ou adulte, y compris l'adulte titulaire qui a un profil
--     eleve sur lui-meme) : `student_profiles.avatar_storage_key`, seau
--     `avatars` ;
--   * enseignant : `teacher_profiles.photo_storage_key`, seau
--     `photos_enseignants` (inchange) ;
--   * tout autre compte (tuteur, direction, comptabilite, controle) : une
--     colonne nouvelle, `profiles.photo_storage_key`, seau `avatars`.
--
-- Regles de lecture (§11, ecrites, sans question au directeur) :
--   * photo d'un eleve : lui-meme, son foyer, ses enseignants, la direction,
--     et ses camarades d'une Classe active, chacun dans sa propre session
--     (lecture stricte de K-44, decision de garde-cap du 03/11/2026) : les
--     adultes du foyer d'un camarade ne la voient pas ; jamais une autre
--     famille ;
--   * photo d'un enseignant : inchangee (lui-meme, la direction, les eleves
--     de ses Classes et leur foyer) ;
--   * photo d'un adulte du foyer : lui-meme, son foyer, la direction, les
--     enseignants des enfants du foyer. Reglage « propose » : il remplace la
--     regle Q4 (« le second adulte : ses initiales ») ;
--   * photo d'un membre de la direction : tout compte connecte au compte
--     valide (« visible des comptes qui voient son nom »). Reglage « propose ».
--
-- Ecriture : chaque adulte pose la sienne (`poser_ma_photo`), le tuteur celle
-- de ses enfants mineurs (`poser_photo_eleve`). Un eleve mineur ne pose rien,
-- en Interface guidee ou non.
--
-- Reste ouvert, a fermer dans PHOTOS-2 (point obligatoire) : le droit client
-- sur `student_profiles.avatar_storage_key` (0005), dont l'envoi actuel du
-- tuteur se sert (majReglages). Le fermer ici casserait cet envoi.
--
-- Seau `avatars` : deux politiques en plus, permissives, rien n'est retire :
-- l'ecriture de chaque adulte dans son propre dossier, et la lecture selon
-- les regles ci-dessus (`photo_visible`). Les politiques existantes du foyer
-- (0004) et de la Classe (L2-09) restent.
--
-- Effacement du compte : `private.cpt_anonymiser` (20261018150000) efface les
-- deux colonnes de photo existantes, pas la nouvelle. La remplacer ici n'est
-- pas possible sans recopier ses effacements de lignes ; un declencheur
-- efface donc `profiles.photo_storage_key` quand le profil recoit la marque
-- d'anonymisation de cette fonction.
--
-- Ni suppression d'objet, ni effacement de ligne, ni vidage de table.

-- ---------------------------------------------------------------------------
-- 1. La colonne des comptes qui n'en avaient pas
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS photo_storage_key text;

COMMENT ON COLUMN public.profiles.photo_storage_key IS
  'PHOTOS-1 (03/11/2026) : la cle de photo (seau avatars, dossier = id du profil) '
  'des comptes sans colonne propre : tuteur, direction, comptabilite, controle. '
  'Un eleve garde student_profiles.avatar_storage_key, un enseignant '
  'teacher_profiles.photo_storage_key. Ecrite par poser_ma_photo seulement.';

-- L'anonymisation (cpt_anonymiser) pose ce nom et desactive le compte : la
-- photo part avec lui.
CREATE FUNCTION private.photos_effacer_si_anonymise()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.first_name = 'Compte' AND NEW.last_name = 'supprimé'
     AND NEW.account_status = 'disabled' THEN
    NEW.photo_storage_key := NULL;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER profiles_photos_anonymisation
BEFORE UPDATE OF first_name, last_name, account_status ON public.profiles
FOR EACH ROW EXECUTE FUNCTION private.photos_effacer_si_anonymise();

-- `authenticated` a le droit UPDATE sur toute la table `profiles` (sa ligne,
-- par `profiles_self_update`), comme sur Supabase. La photo ne s'ecrit
-- pourtant que par `poser_ma_photo`, qui verifie la cle : une ecriture
-- directe d'un client est refusee, comme les colonnes privilegiees
-- (`guard_profile_privileged_columns`).
CREATE FUNCTION public.garde_photo_profil()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF current_user NOT IN ('service_role', 'postgres', 'supabase_admin')
     AND (CASE WHEN TG_OP = 'INSERT' THEN NEW.photo_storage_key IS NOT NULL
               ELSE OLD.photo_storage_key IS DISTINCT FROM NEW.photo_storage_key END) THEN
    RAISE EXCEPTION 'la photo se pose par poser_ma_photo'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER profiles_garde_photo
BEFORE INSERT OR UPDATE OF photo_storage_key ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.garde_photo_profil();

-- ---------------------------------------------------------------------------
-- 2. La source d'une personne : son seau et sa cle
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.photo_source(p_personne uuid)
RETURNS TABLE(seau text, cle text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
           WHEN sp.profile_id IS NOT NULL THEN 'avatars'
           WHEN tp.profile_id IS NOT NULL THEN 'photos_enseignants'
           ELSE 'avatars'
         END,
         CASE
           WHEN sp.profile_id IS NOT NULL THEN sp.avatar_storage_key
           WHEN tp.profile_id IS NOT NULL THEN tp.photo_storage_key
           ELSE p.photo_storage_key
         END
    FROM public.profiles p
    LEFT JOIN public.student_profiles sp
      ON sp.profile_id = p.id AND sp.deleted_at IS NULL
    LEFT JOIN public.teacher_profiles tp
      ON tp.profile_id = p.id
   WHERE p.id = p_personne
     AND p.deleted_at IS NULL;
$function$;

-- Vrai si l'appelant est un adulte qui peut poser sa propre photo : tout
-- compte valide qui n'est pas un eleve mineur.
CREATE FUNCTION private.photo_adulte(p_personne uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = p_personne
       AND p.deleted_at IS NULL
       AND (p.role <> 'student'
            OR EXISTS (SELECT 1 FROM public.student_profiles sp
                        WHERE sp.profile_id = p.id
                          AND sp.deleted_at IS NULL
                          AND sp.student_type = 'autonomous'))
       AND NOT EXISTS (SELECT 1 FROM public.student_profiles sp
                        WHERE sp.profile_id = p.id
                          AND sp.deleted_at IS NULL
                          AND sp.student_type = 'minor')
  );
$function$;

-- ---------------------------------------------------------------------------
-- 3. Les regles de lecture, ecrites une seule fois
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.photo_visible_par(p_cible uuid, p_lecteur uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH cible AS (
    SELECT p.id, p.role, p.household_id,
           EXISTS (SELECT 1 FROM public.student_profiles sp
                    WHERE sp.profile_id = p.id AND sp.deleted_at IS NULL) AS eleve,
           EXISTS (SELECT 1 FROM public.teacher_profiles tp
                    WHERE tp.profile_id = p.id) AS enseignant
      FROM public.profiles p
     WHERE p.id = p_cible AND p.deleted_at IS NULL
  ), lecteur AS (
    SELECT p.id, p.role, p.household_id
      FROM public.profiles p
     WHERE p.id = p_lecteur AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
  )
  SELECT coalesce((
    SELECT
      -- Soi-meme, et la direction.
      c.id = l.id
      OR l.role = 'admin'
      -- Le foyer de la personne (eleve ou adulte).
      OR (c.household_id IS NOT NULL AND c.household_id = l.household_id)
      -- Un eleve : ses enseignants, et ses camarades d'une Classe active,
      -- chacun dans sa propre session (K-44 stricte : pas le foyer du
      -- camarade).
      OR (c.eleve AND EXISTS (
            SELECT 1
              FROM public.groupe_membres mc
              JOIN public.groupes g ON g.id = mc.groupe_id AND g.ended_at IS NULL
             WHERE mc.student_id = c.id AND mc.left_at IS NULL
               AND (g.teacher_id = l.id
                    OR EXISTS (
                      SELECT 1
                        FROM public.groupe_membres ml
                       WHERE ml.groupe_id = g.id AND ml.left_at IS NULL
                         AND ml.student_id = l.id))))
      -- Un enseignant : les eleves de ses Classes et leur foyer (inchange,
      -- comme `photos_enseignants_lecture`).
      OR (c.enseignant AND EXISTS (
            SELECT 1
              FROM public.groupes g
              JOIN public.groupe_membres m ON m.groupe_id = g.id
              JOIN public.profiles pm ON pm.id = m.student_id
             WHERE g.teacher_id = c.id AND m.left_at IS NULL
               AND (m.student_id = l.id
                    OR (pm.household_id IS NOT NULL
                        AND pm.household_id = l.household_id))))
      -- Un adulte du foyer : les enseignants des enfants du foyer.
      OR (NOT c.eleve AND NOT c.enseignant AND c.household_id IS NOT NULL
          AND EXISTS (
            SELECT 1
              FROM public.profiles e
              JOIN public.groupe_membres m ON m.student_id = e.id AND m.left_at IS NULL
              JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
             WHERE e.household_id = c.household_id AND e.deleted_at IS NULL
               AND g.teacher_id = l.id))
      -- Un membre de la direction : tout compte connecte au compte valide.
      OR c.role = 'admin'
      FROM cible c, lecteur l
  ), false);
$function$;

-- La porte de lecture des politiques du seau : le premier segment du chemin
-- vient du client, il est lu en texte et n'est converti qu'une fois verifie.
CREATE FUNCTION public.photo_visible(p_dossier text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR p_dossier IS NULL
     OR p_dossier !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
    RETURN false;
  END IF;
  RETURN private.photo_visible_par(p_dossier::uuid, auth.uid());
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. La lecture : une seule fonction pour tout ecran
-- ---------------------------------------------------------------------------
-- Pour chaque personne visible par l'appelant : son seau et sa cle (nulle
-- quand elle n'a pas de photo). Rien pour les autres : l'ecran montre alors
-- les initiales.
CREATE FUNCTION public.photos_personnes(p_ids uuid[])
RETURNS TABLE(profile_id uuid, seau text, cle text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT x.id, s.seau, s.cle
    FROM (SELECT DISTINCT pg_catalog.unnest(p_ids) AS id) x
    CROSS JOIN LATERAL private.photo_source(x.id) s
   WHERE public.app_account_valid()
     AND private.photo_visible_par(x.id, auth.uid());
$function$;

-- ---------------------------------------------------------------------------
-- 5. L'ecriture
-- ---------------------------------------------------------------------------
-- Une cle de photo d'une personne : dans son dossier, sans remontee, bornee.
CREATE FUNCTION private.photo_cle_valide(p_personne uuid, p_cle text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT p_cle IS NOT NULL
     AND pg_catalog.char_length(p_cle) <= 300
     AND pg_catalog.starts_with(p_cle, p_personne::text || '/')
     AND pg_catalog.char_length(p_cle) > pg_catalog.char_length(p_personne::text) + 1
     AND pg_catalog.strpos(p_cle, '..') = 0
     AND pg_catalog.strpos(p_cle, '//') = 0;
$function$;

-- Chaque adulte pose (ou retire, avec une cle nulle) sa propre photo, dans
-- la colonne de son role. Rend sa source.
CREATE FUNCTION public.poser_ma_photo(p_cle text)
RETURNS TABLE(profile_id uuid, seau text, cle text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_cle text := nullif(pg_catalog.btrim(coalesce(p_cle, '')), '');
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'photo reservee a un compte valide';
  END IF;
  IF NOT private.photo_adulte(v_moi) THEN
    RAISE EXCEPTION 'un eleve mineur ne pose pas de photo';
  END IF;
  IF v_cle IS NOT NULL AND NOT private.photo_cle_valide(v_moi, v_cle) THEN
    RAISE EXCEPTION 'cle de photo invalide';
  END IF;

  IF EXISTS (SELECT 1 FROM public.student_profiles sp
              WHERE sp.profile_id = v_moi AND sp.deleted_at IS NULL) THEN
    UPDATE public.student_profiles
       SET avatar_storage_key = v_cle
     WHERE student_profiles.profile_id = v_moi AND deleted_at IS NULL;
  ELSIF EXISTS (SELECT 1 FROM public.teacher_profiles tp
                 WHERE tp.profile_id = v_moi) THEN
    UPDATE public.teacher_profiles
       SET photo_storage_key = v_cle
     WHERE teacher_profiles.profile_id = v_moi;
  ELSE
    UPDATE public.profiles
       SET photo_storage_key = v_cle
     WHERE id = v_moi;
  END IF;

  RETURN QUERY SELECT v_moi, s.seau, s.cle FROM private.photo_source(v_moi) s;
END;
$function$;

-- Le tuteur pose (ou retire) la photo d'un enfant mineur de son foyer.
CREATE FUNCTION public.poser_photo_eleve(p_eleve uuid, p_cle text)
RETURNS TABLE(profile_id uuid, seau text, cle text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cle text := nullif(pg_catalog.btrim(coalesce(p_cle, '')), '');
BEGIN
  IF NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'photo d''un enfant reservee a son tuteur';
  END IF;
  IF p_eleve IS NULL OR NOT public.est_du_foyer(p_eleve) OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp
        WHERE sp.profile_id = p_eleve AND sp.deleted_at IS NULL
          AND sp.student_type = 'minor') THEN
    RAISE EXCEPTION 'enfant introuvable dans votre foyer';
  END IF;
  IF v_cle IS NOT NULL AND NOT private.photo_cle_valide(p_eleve, v_cle) THEN
    RAISE EXCEPTION 'cle de photo invalide';
  END IF;

  UPDATE public.student_profiles
     SET avatar_storage_key = v_cle
   WHERE student_profiles.profile_id = p_eleve AND deleted_at IS NULL;

  RETURN QUERY SELECT p_eleve, s.seau, s.cle FROM private.photo_source(p_eleve) s;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Le seau `avatars` : deux politiques en plus, rien n'est retire
-- ---------------------------------------------------------------------------
-- Vrai si l'appelant est un adulte au compte valide (porte de la politique
-- d'ecriture : la politique s'evalue sous le role de l'appelant).
CREATE FUNCTION public.photo_adulte_moi()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid()
                  AND private.photo_adulte(auth.uid()), false);
$function$;

DO $seau$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'PHOTOS-1 : schema storage absent, politiques du seau ignorees';
    RETURN;
  END IF;
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', false)
  ON CONFLICT (id) DO NOTHING;

  -- Chaque adulte ecrit, remplace et retire dans son propre dossier.
  EXECUTE $p$
    CREATE POLICY avatar_ecriture_soi ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_adulte_moi()
      )
      WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_adulte_moi()
      )
  $p$;

  -- La lecture selon les regles (camarades, foyers, enseignants, direction).
  EXECUTE $p$
    CREATE POLICY avatar_lecture_regles ON storage.objects
      FOR SELECT TO authenticated
      USING (
        bucket_id = 'avatars'
        AND public.photo_visible((storage.foldername(name))[1])
      )
  $p$;
END
$seau$;

-- ---------------------------------------------------------------------------
-- 7. Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.photos_effacer_si_anonymise()'::regprocedure,
    'public.garde_photo_profil()'::regprocedure,
    'private.photo_source(uuid)'::regprocedure,
    'private.photo_adulte(uuid)'::regprocedure,
    'private.photo_visible_par(uuid,uuid)'::regprocedure,
    'private.photo_cle_valide(uuid,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.photo_visible(text)'::regprocedure,
    'public.photo_adulte_moi()'::regprocedure,
    'public.photos_personnes(uuid[])'::regprocedure,
    'public.poser_ma_photo(text)'::regprocedure,
    'public.poser_photo_eleve(uuid,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. PHOTOS-1.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid = 'public.poser_photo_eleve(uuid,text)'::regprocedure
           THEN 'ROLE_POSITIVE_GUARDIAN'
           ELSE 'ACCOUNT_VALID_AUTHENTICATED' END));
  END LOOP;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 8. Verification : droits et objets, sans nombre ecrit en dur
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'profiles'
                    AND column_name = 'photo_storage_key') THEN
    RAISE EXCEPTION 'PHOTOS-1 : colonne profiles.photo_storage_key absente';
  END IF;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.photo_visible(text)'::regprocedure,
    'public.photo_adulte_moi()'::regprocedure,
    'public.photos_personnes(uuid[])'::regprocedure,
    'public.poser_ma_photo(text)'::regprocedure,
    'public.poser_photo_eleve(uuid,text)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PHOTOS-1 : droits ou search_path invalides sur %', v_oid::text;
    END IF;
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'private.photos_effacer_si_anonymise()'::regprocedure,
    'private.photo_source(uuid)'::regprocedure,
    'private.photo_adulte(uuid)'::regprocedure,
    'private.photo_visible_par(uuid,uuid)'::regprocedure,
    'private.photo_cle_valide(uuid,text)'::regprocedure] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PHOTOS-1 : fonction privee appelable : %', v_oid::text;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.profiles'::regclass
                    AND t.tgname = 'profiles_garde_photo' AND NOT t.tgisinternal)
     OR pg_catalog.has_column_privilege('anon', 'public.profiles', 'photo_storage_key', 'SELECT') THEN
    RAISE EXCEPTION 'PHOTOS-1 : profiles.photo_storage_key sans garde d''ecriture, ou lisible par anon';
  END IF;
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL
     AND (NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                       WHERE schemaname = 'storage' AND policyname = 'avatar_ecriture_soi')
          OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                          WHERE schemaname = 'storage' AND policyname = 'avatar_lecture_regles')) THEN
    RAISE EXCEPTION 'PHOTOS-1 : politiques du seau avatars absentes';
  END IF;
END;
$postflight$;
