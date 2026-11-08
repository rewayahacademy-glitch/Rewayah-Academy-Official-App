-- PHOTO-FOYER (07/11/2026 ; plan de E accepte par le garde-cap a 23:45 UTC,
-- plage 20261120400000 a 20261120499999 reservee).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ; le
-- pilote l'installe tel quel. Additif (B6) : aucune signature changee, aucune
-- fonction retiree ; une fonction retouchee par ancre (poser_photo_eleve), trois
-- politiques du seau `avatars` modifiees par ALTER POLICY.
--
-- Constat : le tuteur ne pouvait poser la photo que d'un enfant MINEUR de son
-- foyer. Un adulte de son foyer qu'il a cree lui-meme (compte enfant, cle
-- child_of de raw_app_meta_data, sans connexion propre) et le tuteur qui suit
-- lui-meme des cours restaient sans photo ; a l'inverse, les politiques du seau
-- laissaient le tuteur ecrire dans le dossier de N'IMPORTE QUEL membre de son
-- foyer, y compris un adulte qui a son propre compte.
--
-- Une seule regle, private.photo_foyer_permise(p) : l'appelant est un tuteur au
-- compte valide, p est de son foyer, et p est soit un eleve mineur, soit un
-- compte cree par ce tuteur (child_of = auth.uid(), lu dans auth.users par une
-- fonction DEFINER, jamais depuis le jeton du client), soit le tuteur lui-meme.
-- Elle est lue par :
--   1. poser_photo_eleve (ancre) : la personne doit aussi avoir une ligne
--      student_profiles, la seule colonne de photo d'un eleve ;
--   2. avatar_ecriture_foyer, avatar_remplacement_foyer et
--      avatar_suppression_foyer (ALTER POLICY), par public.photo_foyer_dossier
--      (le segment de chemin vient du client : texte verifie avant conversion).
--      avatar_lecture_foyer ne change pas.
-- Une seule cle de photo par personne : student_profiles.avatar_storage_key
-- (ecrite par poser_ma_photo et poser_photo_eleve, lue par photo_source, qui ne
-- changent pas). 3. Reprise unique : pour un tuteur qui a une ligne
-- student_profiles sans photo, sa cle profiles.photo_storage_key valide y est
-- recopiee (UPDATE seulement, rien n'est retire), et le nombre de lignes est
-- affiche.
--
-- Preflight : md5 de production lus par le garde-cap le 07/11 a 23:45 UTC et
-- egaux a la base rejouee depuis le depot (poser_photo_eleve 5858689e...,
-- with_check / qual des trois politiques d975df45...). Rejeu : rien n'est
-- reapplique si la retouche est deja la.
-- Must-pass : supabase/tests/scenarios_photo_foyer.sql.


-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_md5 text := pg_catalog.md5(pg_catalog.pg_get_functiondef(
    'public.poser_photo_eleve(uuid,text)'::regprocedure));
BEGIN
  IF v_md5 <> '5858689e7465a174eff31a8f54530ae0'
     AND pg_catalog.strpos(pg_catalog.pg_get_functiondef(
           'public.poser_photo_eleve(uuid,text)'::regprocedure),
           'private.photo_foyer_permise') = 0 THEN
    RAISE EXCEPTION 'PHOTO-FOYER : poser_photo_eleve a change depuis la lecture du 07/11 (md5 %)', v_md5;
  END IF;
  IF pg_catalog.to_regprocedure('public.est_du_foyer(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.photo_cle_valide(uuid,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.photo_source(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.poser_ma_photo(text)') IS NULL THEN
    RAISE EXCEPTION 'PHOTO-FOYER : un objet attendu manque';
  END IF;
END;
$preflight$;

-- Outil de la migration (detruit avec la session) : remplace une ancre, une
-- seule fois, puis rafraichit l'empreinte F86 du commentaire.
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PHOTO-FOYER : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1. La regle unique
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.photo_foyer_permise(p_personne uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    auth.uid() IS NOT NULL
    AND p_personne IS NOT NULL
    AND public.app_role() = 'guardian'
    AND public.app_account_valid()
    AND public.est_du_foyer(p_personne)
    AND (
      p_personne = auth.uid()
      OR EXISTS (SELECT 1 FROM public.student_profiles sp
                  WHERE sp.profile_id = p_personne
                    AND sp.deleted_at IS NULL
                    AND sp.student_type = 'minor')
      -- CHILD_OF (en attente de la decision du directeur, garde-cap 07/11
      -- 23:59) : un compte cree par ce tuteur. Cas isole sur la seule ligne
      -- qui suit : la retirer suffit si le directeur dit non (PF1 du scenario
      -- s'inverse alors en refus).
      OR EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p_personne AND u.raw_app_meta_data ->> 'child_of' = auth.uid()::text)
    ), false);
$function$;

REVOKE EXECUTE ON FUNCTION private.photo_foyer_permise(uuid) FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION private.photo_foyer_permise(uuid) IS
  'PHOTO-FOYER (07/11/2026) : un tuteur au compte valide pose la photo d''un '
  'membre de son foyer sans compte propre (eleve mineur, compte qu''il a cree, '
  'child_of) ou la sienne. Lue par poser_photo_eleve et par les politiques '
  'd''ecriture du seau avatars (photo_foyer_dossier).';

-- Porte des politiques du seau : elles s'evaluent sous le role de l'appelant,
-- qui n'a pas acces au schema private. Le segment vient du nom d'un objet de
-- stockage, donc du client : il est verifie en texte avant la conversion, une
-- valeur mal formee est refusee, jamais en erreur.
CREATE OR REPLACE FUNCTION public.photo_foyer_dossier(p_dossier text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_dossier IS NULL
     OR p_dossier !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN false;
  END IF;
  RETURN private.photo_foyer_permise(p_dossier::uuid);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.photo_foyer_dossier(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.photo_foyer_dossier(text) TO authenticated;

COMMENT ON FUNCTION public.photo_foyer_dossier(text) IS
  'PHOTO-FOYER (07/11/2026) : porte des politiques avatar_ecriture_foyer, '
  'avatar_remplacement_foyer et avatar_suppression_foyer. Texte verifie avant '
  'conversion en uuid ; delegue a private.photo_foyer_permise.';

-- ---------------------------------------------------------------------------
-- 2. poser_photo_eleve lit la regle (ancre, sautee au rejeu)
-- ---------------------------------------------------------------------------
DO $ancre$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.poser_photo_eleve(uuid,text)'::regprocedure),
       'private.photo_foyer_permise') > 0 THEN
    RAISE NOTICE 'PHOTO-FOYER : poser_photo_eleve deja retouchee';
    RETURN;
  END IF;
  PERFORM pg_temp.remplacer('public.poser_photo_eleve(uuid,text)'::regprocedure,
$a$  IF p_eleve IS NULL OR NOT public.est_du_foyer(p_eleve) OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp
        WHERE sp.profile_id = p_eleve AND sp.deleted_at IS NULL
          AND sp.student_type = 'minor') THEN$a$,
$n$  IF p_eleve IS NULL OR NOT private.photo_foyer_permise(p_eleve) OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp
        WHERE sp.profile_id = p_eleve AND sp.deleted_at IS NULL) THEN$n$);
END;
$ancre$;

-- ---------------------------------------------------------------------------
-- 3. Les trois politiques d'ecriture du seau suivent la meme regle
-- ---------------------------------------------------------------------------
DO $seau$
DECLARE
  v_attendu constant text := 'd975df453c8903c60a014a9e8112987d';
  v_pol record;
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'PHOTO-FOYER : schema storage absent, politiques du seau ignorees';
    RETURN;
  END IF;
  FOR v_pol IN
    SELECT policyname, coalesce(with_check, qual) AS expr
      FROM pg_catalog.pg_policies
     WHERE schemaname = 'storage' AND tablename = 'objects'
       AND policyname IN ('avatar_ecriture_foyer', 'avatar_remplacement_foyer',
                          'avatar_suppression_foyer')
  LOOP
    IF pg_catalog.strpos(v_pol.expr, 'photo_foyer_dossier') > 0 THEN
      CONTINUE;
    END IF;
    IF pg_catalog.md5(v_pol.expr) <> v_attendu THEN
      RAISE EXCEPTION 'PHOTO-FOYER : la politique % a change (md5 %)',
        v_pol.policyname, pg_catalog.md5(v_pol.expr);
    END IF;
  END LOOP;
  IF (SELECT count(*) FROM pg_catalog.pg_policies
       WHERE schemaname = 'storage' AND tablename = 'objects'
         AND policyname IN ('avatar_ecriture_foyer', 'avatar_remplacement_foyer',
                            'avatar_suppression_foyer')) <> 3 THEN
    RAISE EXCEPTION 'PHOTO-FOYER : une politique d''ecriture du foyer manque';
  END IF;

  EXECUTE $p$
    ALTER POLICY avatar_ecriture_foyer ON storage.objects
      WITH CHECK (
        bucket_id = 'avatars'
        AND (SELECT public.app_role()) = 'guardian'
        AND public.photo_foyer_dossier((storage.foldername(name))[1])
      )
  $p$;
  EXECUTE $p$
    ALTER POLICY avatar_remplacement_foyer ON storage.objects
      USING (
        bucket_id = 'avatars'
        AND (SELECT public.app_role()) = 'guardian'
        AND public.photo_foyer_dossier((storage.foldername(name))[1])
      )
  $p$;
  EXECUTE $p$
    ALTER POLICY avatar_suppression_foyer ON storage.objects
      USING (
        bucket_id = 'avatars'
        AND (SELECT public.app_role()) = 'guardian'
        AND public.photo_foyer_dossier((storage.foldername(name))[1])
      )
  $p$;
END;
$seau$;

-- ---------------------------------------------------------------------------
-- 4. Reprise unique : une seule cle de photo par personne
-- ---------------------------------------------------------------------------
-- Fonction privee, fermee a tous, pour que le scenario rejoue la reprise sur
-- ses propres donnees ; idempotente (seules les lignes sans photo bougent).
CREATE OR REPLACE FUNCTION private.photo_foyer_reprise()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.student_profiles sp
     SET avatar_storage_key = p.photo_storage_key
    FROM public.profiles p
   WHERE p.id = sp.profile_id
     AND p.role = 'guardian'
     AND p.deleted_at IS NULL
     AND sp.deleted_at IS NULL
     AND sp.avatar_storage_key IS NULL
     AND p.photo_storage_key IS NOT NULL
     AND private.photo_cle_valide(p.id, p.photo_storage_key);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

REVOKE EXECUTE ON FUNCTION private.photo_foyer_reprise() FROM PUBLIC, anon, authenticated;

DO $reprise$
BEGIN
  RAISE NOTICE 'PHOTO-FOYER : % photo(s) de tuteur recopiee(s) vers student_profiles',
    private.photo_foyer_reprise();
END;
$reprise$;

-- ---------------------------------------------------------------------------
-- 5. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.poser_photo_eleve(uuid,text)'::regprocedure),
       'private.photo_foyer_permise') = 0 THEN
    RAISE EXCEPTION 'PHOTO-FOYER : poser_photo_eleve ne lit pas la regle';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated',
           'public.poser_photo_eleve(uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
           'public.photo_foyer_dossier(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTO-FOYER : une porte de la photo est fermee a authenticated';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.photo_foyer_dossier(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.photo_foyer_permise(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.photo_foyer_permise(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.photo_foyer_reprise()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.photo_foyer_reprise()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTO-FOYER : une fonction de la regle est trop ouverte';
  END IF;
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL AND (
       SELECT count(*) FROM pg_catalog.pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects'
          AND policyname IN ('avatar_ecriture_foyer', 'avatar_remplacement_foyer',
                             'avatar_suppression_foyer')
          AND pg_catalog.strpos(coalesce(with_check, qual), 'photo_foyer_dossier') > 0) <> 3 THEN
    RAISE EXCEPTION 'PHOTO-FOYER : une politique d''ecriture du foyer ne suit pas la regle';
  END IF;
END;
$postflight$;
