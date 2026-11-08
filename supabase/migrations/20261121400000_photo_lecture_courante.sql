-- PHOTO-LECTURE-COURANTE (08/11/2026, ordre du pilote, faille de confidentialite
-- trouvee pendant PHOTO-CANDIDATURE-FIGEE).
--
-- FICHIER SANS BEGIN; NI COMMIT; (la page du directeur ouvre elle-meme la
-- transaction unique, PR 355) ; SANS MOT D'EFFACEMENT : un ALTER POLICY, jamais un
-- retrait de politique. Il remplace l'expression de LECTURE d'une seule
-- politique du seau `photos_enseignants`. Aucun droit n'est ajoute : un seul est
-- retire (voir la regle).
--
-- Constat. `photos_enseignants_lecture` (0032) laisse lire, dans le dossier d'un
-- enseignant (premier segment du chemin = son profile_id) :
--   1. son titulaire ;
--   2. tout role `admin` ;
--   3. les membres de ses classes, eleve ou foyer d'un eleve, tant qu'ils n'en
--      sont pas sortis.
-- La troisieme branche ouvre TOUT objet du dossier, pas seulement la photo
-- d'affichage : un eleve ou une famille lit aussi les anciens fichiers de
-- l'enseignant (ses photos remplacees) et, depuis PHOTO-CANDIDATURE-FIGEE, la
-- photo envoyee avec sa candidature. Aucune fonction ne leur donne ces cles,
-- mais la politique les laisse lire (et lister) : c'est la faille.
--
-- Regle visee, en une phrase : le titulaire et tout role `admin` gardent
-- exactement leurs droits ; un eleve ou une famille de la classe d'un enseignant
-- ne lit, dans son dossier, que sa photo d'affichage ACTUELLE
-- (`teacher_profiles.photo_storage_key`), jamais un ancien fichier ni le fichier
-- fige de sa candidature.
--
-- Correction : la troisieme branche exige en plus
-- `private.photo_affichage_courante(name)`. Le test lit `teacher_profiles` par une
-- fonction DEFINER : un eleve ne lit pas cette table (RLS), un test fait avec ses
-- droits ne verrait jamais la photo et couperait l'affichage de tous.
--
-- L'affichage cote famille ne change pas : toutes les sources serveur de la cle
-- d'un enseignant (`photos_personnes` par `private.photo_source`, les vues
-- `mes_groupes_*_v`) rendent `teacher_profiles.photo_storage_key`, donc la
-- cle courante. Une URL signee demandee avec une cle perimee (la photo vient de
-- changer) n'est plus delivree : le client en relit une nouvelle.
--
-- Rien de ce fichier ne change la regle « un admin lit tout le seau hors de son
-- genre » : politique existante, a confronter a la regle de genre dans un lot a
-- part (proposition, pas une decision).

-- ---------------------------------------------------------------------------
-- 0. Preflight : la politique est celle relue, et rien n'est deja installe.
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NULL THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : schema storage absent, politique du seau introuvable';
  END IF;
  -- Empreinte = md5(qual || '|' || with_check || '|' || cmd || '|' || roles), la
  -- formule relue et recalibree en production avant le collage.
  IF (SELECT pg_catalog.md5(coalesce(p.qual, '') || '|' || coalesce(p.with_check, '')
                            || '|' || p.cmd || '|' || p.roles::text)
        FROM pg_catalog.pg_policies p
       WHERE p.schemaname = 'storage' AND p.tablename = 'objects'
         AND p.policyname = 'photos_enseignants_lecture')
     IS DISTINCT FROM 'baf72997bb78a9965aaeed1b9155ecfc' THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : photos_enseignants_lecture a change, migration a revoir';
  END IF;
  IF pg_catalog.to_regprocedure('private.photo_affichage_courante(text)') IS NOT NULL THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : deja installee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'teacher_profiles'
                    AND column_name = 'photo_storage_key') THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : teacher_profiles.photo_storage_key absente';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Une cle est-elle la photo d'affichage ACTUELLE d'un enseignant ?
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.photo_affichage_courante(p_cle text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_cle IS NOT NULL
         AND EXISTS (SELECT 1 FROM public.teacher_profiles tp WHERE tp.photo_storage_key = p_cle);
$function$;
ALTER FUNCTION private.photo_affichage_courante(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.photo_affichage_courante(text) FROM PUBLIC, anon, service_role, agent_ro;
-- Lue par la politique du seau, evaluee au nom de la session : seul EXECUTE est
-- verifie a l'evaluation (pas USAGE sur le schema private).
GRANT EXECUTE ON FUNCTION private.photo_affichage_courante(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. La politique de lecture : la troisieme branche se limite a la photo courante.
-- ---------------------------------------------------------------------------
ALTER POLICY photos_enseignants_lecture ON storage.objects
  USING (
    bucket_id = 'photos_enseignants'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR (SELECT public.app_role()) = 'admin'
      OR (
        EXISTS (
          SELECT 1
            FROM public.groupes g
            JOIN public.groupe_membres m ON m.groupe_id = g.id
           WHERE g.teacher_id::text = (storage.foldername(name))[1]
             AND m.left_at IS NULL
             AND (m.student_id = auth.uid() OR public.est_du_foyer(m.student_id))
        )
        AND private.photo_affichage_courante(name)
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies p
                  WHERE p.schemaname = 'storage' AND p.tablename = 'objects'
                    AND p.policyname = 'photos_enseignants_lecture'
                    AND p.cmd = 'SELECT' AND p.roles = ARRAY['authenticated']::name[]
                    AND p.qual LIKE '%photo_affichage_courante%'
                    AND p.qual LIKE '%app_role()%'
                    AND p.qual LIKE '%auth.uid()%'
                    AND p.with_check IS NULL) THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : politique de lecture non posee comme prevu';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.photo_affichage_courante(text)'::regprocedure AND p.prosecdef
                    AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', 'private.photo_affichage_courante(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'private.photo_affichage_courante(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTO-LECTURE : DEFINER ou ACL invalide (EXECUTE : authenticated oui, anon non)';
  END IF;
END
$postflight$;
