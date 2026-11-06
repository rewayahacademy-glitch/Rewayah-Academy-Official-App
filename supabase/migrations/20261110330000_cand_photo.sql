-- CAND-PHOTO (06/11/2026, demande du directeur de 23:22, relayee par le
-- pilote et le garde-cap) : la photo du candidat, obligatoire, et l'accord de
-- publication sur le site public, separe et retirable.
--
-- Ce que le lot reutilise (PHOTOS-1, 20261107300000 ; PHOTOS-2a,
-- 20261109300000) : une seule photo par personne. Pour un enseignant, et donc
-- pour un candidat, qui est deja un compte `teacher` avec sa ligne
-- `teacher_profiles` des l'inscription : `teacher_profiles.photo_storage_key`,
-- seau `photos_enseignants`, dossier = id du profil. A l'embauche, rien n'est
-- copie : c'est la meme ligne, la photo du candidat est celle de l'enseignant.
--
-- Ce qui manquait : un candidat est en `pending_kyc`. Or `poser_ma_photo` et
-- la politique d'ecriture du seau exigent `app_account_valid()` (actif ou
-- provisoire) : un candidat ne pouvait pas poser sa photo. Ce lot ajoute :
--
--   1. `public.photo_candidat_moi()` : vrai pour le titulaire d'une
--      candidature en cours (`private.candidature_du_titulaire(true)`) ;
--   2. une politique ADDITIVE du seau `photos_enseignants` : ce titulaire
--      ecrit, remplace et retire dans son propre dossier. Rien n'est retire ;
--   3. `public.poser_photo_candidat(p_cle)` : pose (ou retire, cle nulle) la
--      photo du titulaire, cle verifiee comme PHOTOS-1
--      (`private.photo_cle_valide`) ;
--   4. la photo obligatoire a l'envoi : `envoyer_reponses_salle_examen`
--      refuse « photo_requise », sans ecriture, tant que la photo manque
--      (remplacement par ancre, empreinte verifiee avant) ;
--   5. l'accord de publication : `public.accords_publication`, une ligne par
--      accord (version, nom signe relu au serveur, date), retirable (date de
--      retrait), jamais efface. Le texte se publie par sa version
--      (`app_config` : `enseignants.publication_version`). Le site public ne
--      lit rien de nouveau dans ce lot ; `private.accord_publication_en_cours`
--      est la seule lecture qu'il aura.
--
-- Aucune detection de visage. Ni suppression d'objet, ni effacement de ligne,
-- ni vidage de table.

-- ---------------------------------------------------------------------------
-- 0. Preflight : la fonction remplacee est celle relue en production le
--    06/11/2026 a 23:40 UTC.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_md5 text := pg_catalog.md5(pg_catalog.pg_get_functiondef(
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure));
BEGIN
  IF v_md5 <> '8f5c5436da1ac0c148976c4f74e0d506' THEN
    RAISE EXCEPTION 'CAND-PHOTO : envoyer_reponses_salle_examen a change (md5 %), migration a revoir', v_md5;
  END IF;
  IF pg_catalog.to_regclass('public.accords_publication') IS NOT NULL THEN
    RAISE EXCEPTION 'CAND-PHOTO : public.accords_publication existe deja';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le titulaire d'une candidature en cours
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.photo_candidat_moi()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL
                  AND public.app_role() = 'teacher'
                  AND private.candidature_du_titulaire(true) IS NOT NULL
                  AND EXISTS (SELECT 1 FROM public.teacher_profiles tp
                               WHERE tp.profile_id = auth.uid()), false);
$function$;

-- ---------------------------------------------------------------------------
-- 2. Le seau : le candidat ecrit dans son propre dossier (additif)
-- ---------------------------------------------------------------------------
DO $seau$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'CAND-PHOTO : schema storage absent, politique du seau ignoree';
    RETURN;
  END IF;
  EXECUTE $p$
    CREATE POLICY photos_enseignants_ecriture_candidat ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'photos_enseignants'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_candidat_moi()
      )
      WITH CHECK (
        bucket_id = 'photos_enseignants'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_candidat_moi()
      )
  $p$;
END
$seau$;

-- ---------------------------------------------------------------------------
-- 3. Poser la photo du candidat
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.poser_photo_candidat(p_cle text)
RETURNS TABLE(profile_id uuid, seau text, cle text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_cle text := nullif(pg_catalog.btrim(coalesce(p_cle, '')), '');
BEGIN
  IF NOT public.photo_candidat_moi() THEN
    RAISE EXCEPTION 'photo reservee au titulaire d''une candidature en cours'
      USING ERRCODE = '42501';
  END IF;
  IF v_cle IS NOT NULL AND NOT private.photo_cle_valide(v_moi, v_cle) THEN
    RAISE EXCEPTION 'cle de photo invalide' USING ERRCODE = '22023';
  END IF;
  UPDATE public.teacher_profiles
     SET photo_storage_key = v_cle
   WHERE teacher_profiles.profile_id = v_moi;
  RETURN QUERY SELECT v_moi, s.seau, s.cle FROM private.photo_source(v_moi) s;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. La photo obligatoire a l'envoi des reponses
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

SELECT pg_temp.remplacer('public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)',
  $a$  IF NOT p_accord_remuneration THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'accord_remuneration_requis');
  END IF;$a$,
  $b$  IF NOT p_accord_remuneration THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'accord_remuneration_requis');
  END IF;
  -- CAND-PHOTO (06/11/2026) : la photo est obligatoire ; sans elle, rien
  -- n'est ecrit.
  IF NOT EXISTS (SELECT 1 FROM public.teacher_profiles tp
                  WHERE tp.profile_id = v_uid AND tp.photo_storage_key IS NOT NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'photo_requise');
  END IF;$b$, 1);

-- ---------------------------------------------------------------------------
-- 5. L'accord de publication
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
VALUES ('enseignants.publication_version', '"publication-2026-11-v1"'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE TABLE public.accords_publication (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  version text NOT NULL CHECK (pg_catalog.length(version) BETWEEN 1 AND 80),
  -- Le nom du compte au moment de l'accord, relu au serveur : la signature.
  nom_signe text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(nom_signe)) BETWEEN 1 AND 200),
  accepte_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retire_le timestamptz NULL,
  CONSTRAINT accords_publication_retrait_apres CHECK (retire_le IS NULL OR retire_le >= accepte_le)
);
-- Un seul accord en cours par personne.
CREATE UNIQUE INDEX accords_publication_en_cours_uidx
  ON public.accords_publication (profile_id) WHERE retire_le IS NULL;

ALTER TABLE public.accords_publication ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.accords_publication FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.accords_publication TO authenticated;
-- Chacun lit les siens ; la direction lit tout. Aucune ecriture client : les
-- deux RPC ci-dessous seulement.
CREATE POLICY accords_publication_lecture ON public.accords_publication
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid()
         OR coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

COMMENT ON TABLE public.accords_publication IS
  'CAND-PHOTO (06/11/2026) : accord de l''enseignant (ou du candidat) pour que son nom, sa photo et son pays '
  'paraissent sur le site public. Une ligne par accord, version du texte, nom signe relu au serveur, '
  'date ; retire par retire_le, jamais efface. Ecrit par accepter_accord_publication et '
  'retirer_accord_publication seulement.';

-- L'accord en cours d'une personne (le site public le lira, plus tard).
CREATE FUNCTION private.accord_publication_en_cours(p_personne uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.accords_publication a
                  WHERE a.profile_id = p_personne AND a.retire_le IS NULL);
$function$;

-- Ce que l'ecran montre : la version courante, et l'accord en cours.
CREATE FUNCTION public.mon_accord_publication()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_a public.accords_publication;
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND public.app_role() = 'teacher'
                  AND (public.app_account_valid() OR public.photo_candidat_moi()), false) THEN
    RAISE EXCEPTION 'accord de publication reserve a l''enseignant et au candidat'
      USING ERRCODE = '42501';
  END IF;
  SELECT a.* INTO v_a FROM public.accords_publication a
   WHERE a.profile_id = v_moi AND a.retire_le IS NULL;
  RETURN pg_catalog.jsonb_build_object(
    'versionCourante', (SELECT c.value #>> '{}' FROM public.app_config c
                         WHERE c.key = 'enseignants.publication_version'),
    'enCours', v_a.id IS NOT NULL,
    'version', v_a.version,
    'nomSigne', v_a.nom_signe,
    'accepteLe', v_a.accepte_le);
END;
$function$;

-- Donner l'accord, a la version affichee. Le nom signe est celui du compte.
CREATE FUNCTION public.accepter_accord_publication(p_version text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_courante text;
  v_nom text;
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND public.app_role() = 'teacher'
                  AND (public.app_account_valid() OR public.photo_candidat_moi()), false) THEN
    RAISE EXCEPTION 'accord de publication reserve a l''enseignant et au candidat'
      USING ERRCODE = '42501';
  END IF;
  SELECT c.value #>> '{}' INTO v_courante FROM public.app_config c
   WHERE c.key = 'enseignants.publication_version';
  IF v_courante IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'texte_indisponible');
  END IF;
  IF p_version IS DISTINCT FROM v_courante THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'version_perimee', 'versionCourante', v_courante);
  END IF;
  SELECT nullif(pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)), '')
    INTO v_nom FROM public.profiles p WHERE p.id = v_moi;
  IF v_nom IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'nom_absent');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('accord_publication:' || v_moi::text, 0));
  -- Deja donne a cette version : rien de nouveau (rejouable).
  IF NOT EXISTS (SELECT 1 FROM public.accords_publication a
                  WHERE a.profile_id = v_moi AND a.retire_le IS NULL AND a.version = v_courante) THEN
    UPDATE public.accords_publication SET retire_le = pg_catalog.clock_timestamp()
     WHERE profile_id = v_moi AND retire_le IS NULL;
    INSERT INTO public.accords_publication (profile_id, version, nom_signe)
    VALUES (v_moi, v_courante, v_nom);
  END IF;
  RETURN public.mon_accord_publication();
END;
$function$;

-- Retirer l'accord : la ligne garde sa date de retrait, rien n'est efface.
CREATE FUNCTION public.retirer_accord_publication()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND public.app_role() = 'teacher'
                  AND (public.app_account_valid() OR public.photo_candidat_moi()), false) THEN
    RAISE EXCEPTION 'accord de publication reserve a l''enseignant et au candidat'
      USING ERRCODE = '42501';
  END IF;
  UPDATE public.accords_publication SET retire_le = pg_catalog.clock_timestamp()
   WHERE profile_id = v_moi AND retire_le IS NULL;
  RETURN public.mon_accord_publication();
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  EXECUTE 'REVOKE ALL ON FUNCTION private.accord_publication_en_cours(uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro';
  FOREACH v_oid IN ARRAY ARRAY[
    'public.photo_candidat_moi()'::regprocedure,
    'public.poser_photo_candidat(text)'::regprocedure,
    'public.mon_accord_publication()'::regprocedure,
    'public.accepter_accord_publication(text)'::regprocedure,
    'public.retirer_accord_publication()'::regprocedure,
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-06. %s',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid = 'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure
           THEN 'CANDIDATURE_TITULAIRE'
           ELSE 'ROLE_POSITIVE_TEACHER_OR_CANDIDATE' END,
      -- L'envoi garde son lot d'origine (CAND-L2A1), que ses scenarios relisent.
      CASE WHEN v_oid = 'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure
           THEN 'CAND-L2A1 ; CAND-PHOTO (photo obligatoire).'
           ELSE 'CAND-PHOTO.' END));
  END LOOP;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 7. Verification
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.photo_candidat_moi()'::regprocedure,
    'public.poser_photo_candidat(text)'::regprocedure,
    'public.mon_accord_publication()'::regprocedure,
    'public.accepter_accord_publication(text)'::regprocedure,
    'public.retirer_accord_publication()'::regprocedure,
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-PHOTO : droits ou search_path invalides sur %', v_oid::text;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.accord_publication_en_cours(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.accord_publication_en_cours(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAND-PHOTO : fonction privee appelable';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure),
       '''photo_requise''') = 0 THEN
    RAISE EXCEPTION 'CAND-PHOTO : photo_requise absente de l''envoi';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.accords_publication'::regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'public.accords_publication', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.accords_publication', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.accords_publication', 'DELETE')
     OR pg_catalog.has_table_privilege('anon', 'public.accords_publication', 'SELECT') THEN
    RAISE EXCEPTION 'CAND-PHOTO : accords_publication sans RLS, ou ecrivable par un client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'enseignants.publication_version') THEN
    RAISE EXCEPTION 'CAND-PHOTO : version du texte de publication absente';
  END IF;
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                      WHERE schemaname = 'storage' AND policyname = 'photos_enseignants_ecriture_candidat') THEN
    RAISE EXCEPTION 'CAND-PHOTO : politique du seau absente';
  END IF;
END;
$postflight$;
