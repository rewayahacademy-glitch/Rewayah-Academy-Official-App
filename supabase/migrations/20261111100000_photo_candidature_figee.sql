-- PHOTO-CANDIDATURE-FIGEE (point 5 du pilote, 07/11/2026).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- le pilote l'installe tel quel. Migration additive (B6) : deux colonnes
-- facultatives ajoutees, aucune retiree, aucune signature publique changee.
--
-- Constat : `poser_photo_candidat` (20261110330000) ecrit
-- `teacher_profiles.photo_storage_key`, la photo d'affichage, que l'enseignant
-- change librement ; la politique `photos_enseignants_remplacement_candidat`
-- (et `photos_enseignants_ecriture` une fois le compte actif) laisse
-- remplacer n'importe quel objet de son dossier. Le dossier de candidature
-- n'a donc pas de photo a lui : la direction verrait la photo du jour, pas
-- celle envoyee avec la candidature.
--
-- Correction :
-- 1. `candidatures.photo_cle_figee` et `photo_figee_le` : la cle de la photo
--    d'affichage, figee a l'envoi des reponses (`envoyer_reponses_salle_examen`,
--    remplacement par ancre, empreinte de production relue avant). Un nouvel
--    envoi fige la photo de ce moment-la.
-- 2. Le fichier fige n'est jamais remplace ni efface : les deux politiques
--    d'ecriture du seau excluent une cle figee (texte des politiques verifie
--    avant). Une nouvelle photo est toujours une nouvelle cle (le client
--    horodate la cle) : la photo d'affichage reste libre.
-- 3. `photo_dossier_candidat(p_id)` : la direction lit la photo figee du dossier,
--    sous la garde de `lire_candidature` (direction active, genre du
--    lecteur, exception super admin journalisee).
-- 4. Les candidatures deja envoyees recoivent la photo d'affichage du moment
--    de cette migration (rattrapage, dit dans le commentaire de colonne).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : definitions relues en production (garde-cap, 07/11/2026).
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure))
     <> '2a6ceb427dcc32fb4ab24df7b60ca711' THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : envoyer_reponses_salle_examen a change, migration a revoir';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'candidatures'
                AND column_name IN ('photo_cle_figee', 'photo_figee_le')) THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : deja installee';
  END IF;
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL AND (
       (SELECT pg_catalog.md5(coalesce(p.qual, '') || '|' || coalesce(p.with_check, ''))
          FROM pg_catalog.pg_policies p
         WHERE p.schemaname = 'storage' AND p.policyname = 'photos_enseignants_ecriture')
         IS DISTINCT FROM '57e8a32337e88d5742e464ddedbb87ed'
    OR (SELECT pg_catalog.md5(coalesce(p.qual, '') || '|' || coalesce(p.with_check, ''))
          FROM pg_catalog.pg_policies p
         WHERE p.schemaname = 'storage' AND p.policyname = 'photos_enseignants_remplacement_candidat')
         IS DISTINCT FROM 'b3813565259c1cfe3dd303fad8c395de') THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : politiques du seau photos_enseignants changees, migration a revoir';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La photo du dossier de candidature
-- ---------------------------------------------------------------------------
ALTER TABLE public.candidatures
  ADD COLUMN photo_cle_figee text NULL
    CHECK (photo_cle_figee IS NULL OR pg_catalog.length(photo_cle_figee) BETWEEN 1 AND 300),
  ADD COLUMN photo_figee_le timestamptz NULL;
COMMENT ON COLUMN public.candidatures.photo_cle_figee IS
  'PHOTO-FIGEE (07/11/2026) : cle (seau photos_enseignants) de la photo envoyee avec la candidature, '
  'figee a l''envoi des reponses ; jamais remplacee ni effacee dans le seau. Pour les candidatures '
  'envoyees avant le 07/11/2026 : la photo d''affichage au moment de la migration.';

-- Une cle est-elle celle d'un dossier de candidature ?
CREATE FUNCTION private.photo_candidature_figee(p_cle text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.candidatures c WHERE c.photo_cle_figee = p_cle);
$function$;
ALTER FUNCTION private.photo_candidature_figee(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.photo_candidature_figee(text) FROM PUBLIC, anon, service_role, agent_ro;
-- Lue par les politiques du seau, evaluees au nom de la session.
GRANT EXECUTE ON FUNCTION private.photo_candidature_figee(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Figee a l'envoi des reponses
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
  $a$  PERFORM private.paiement_recalculer(v_id, 'reponses');$a$,
  $b$  -- PHOTO-FIGEE (07/11/2026) : la photo envoyee avec la candidature est
  -- figee dans le dossier ; la photo d'affichage reste libre.
  UPDATE public.candidatures
     SET photo_cle_figee = (SELECT tp.photo_storage_key FROM public.teacher_profiles tp
                             WHERE tp.profile_id = v_uid),
         photo_figee_le = pg_catalog.clock_timestamp()
   WHERE id = v_id;
  PERFORM private.paiement_recalculer(v_id, 'reponses');$b$, 1);

COMMENT ON FUNCTION public.envoyer_reponses_salle_examen(text, jsonb, boolean, text, integer, text) IS
  'F86 candidate allowlist: signature=envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text); md5_functiondef=b0c24f581ee3e2829b8cf7799c4e9da6; guard_type=CANDIDATURE_TITULAIRE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-07. CAND-L2A1 ; CAND-PHOTO (photo obligatoire) ; PHOTO-FIGEE (photo de l''envoi figee dans le dossier).';

-- ---------------------------------------------------------------------------
-- 3. Le fichier fige n'est jamais remplace ni efface
-- ---------------------------------------------------------------------------
DO $seau$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'PHOTO-FIGEE : schema storage absent, politiques du seau ignorees';
    RETURN;
  END IF;
  EXECUTE $p$
    ALTER POLICY photos_enseignants_remplacement_candidat ON storage.objects
      USING (
        bucket_id = 'photos_enseignants'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_candidat_moi()
        AND NOT private.photo_candidature_figee(name)
      )
      WITH CHECK (
        bucket_id = 'photos_enseignants'
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND public.photo_candidat_moi()
        AND NOT private.photo_candidature_figee(name)
      )
  $p$;
  EXECUTE $p$
    ALTER POLICY photos_enseignants_ecriture ON storage.objects
      USING (
        bucket_id = 'photos_enseignants'
        AND coalesce((SELECT public.app_role()) = 'teacher'
                     AND (SELECT public.app_account_valid()), false)
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND NOT private.photo_candidature_figee(name)
      )
      WITH CHECK (
        bucket_id = 'photos_enseignants'
        AND coalesce((SELECT public.app_role()) = 'teacher'
                     AND (SELECT public.app_account_valid()), false)
        AND (storage.foldername(name))[1] = auth.uid()::text
        AND NOT private.photo_candidature_figee(name)
      )
  $p$;
END
$seau$;

-- ---------------------------------------------------------------------------
-- 4. La direction lit la photo du dossier
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.photo_dossier_candidat(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  IF v_super AND v_c.genre IS DISTINCT FROM v_genre THEN
    PERFORM public.log_sensitive_access('candidature_exception_super_admin', 'candidatures',
      p_id::text, pg_catalog.jsonb_build_object('lecture', 'photo',
                                                'motif', 'exception_super_admin_kyc'));
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'seau', 'photos_enseignants',
    'cle', v_c.photo_cle_figee,
    'figeeLe', v_c.photo_figee_le);
END;
$function$;
ALTER FUNCTION public.photo_dossier_candidat(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.photo_dossier_candidat(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.photo_dossier_candidat(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Rattrapage : les candidatures deja envoyees
-- ---------------------------------------------------------------------------
UPDATE public.candidatures c
   SET photo_cle_figee = tp.photo_storage_key,
       photo_figee_le = pg_catalog.clock_timestamp()
  FROM public.teacher_profiles tp
 WHERE tp.profile_id = c.profile_id
   AND tp.photo_storage_key IS NOT NULL
   AND c.photo_cle_figee IS NULL
   AND EXISTS (SELECT 1 FROM public.candidature_reponses r
                WHERE r.candidature_id = c.id AND r.source = 'candidat'
                  AND NOT r.brouillon AND r.envoye_le IS NOT NULL);

-- ---------------------------------------------------------------------------
-- 6. Commentaires F86 et postflight
-- ---------------------------------------------------------------------------
COMMENT ON FUNCTION public.photo_dossier_candidat(uuid) IS
  'F86: signature=public.photo_dossier_candidat(uuid); md5_functiondef=d1030f3f773e4736bc13579a3d165e08; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Garde de lire_candidature : direction active, genre du lecteur, exception super admin journalisee. Rend la photo figee du dossier.';

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'SET photo_cle_figee = (SELECT tp.photo_storage_key') = 0
     OR pg_catalog.md5(v_def) <> 'b0c24f581ee3e2829b8cf7799c4e9da6' THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : envoyer_reponses_salle_examen ne fige pas la photo';
  END IF;
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.photo_dossier_candidat(uuid)'::regprocedure)) <> 'd1030f3f773e4736bc13579a3d165e08' THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : empreinte F86 invalide';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.photo_dossier_candidat(uuid)'::regprocedure AND p.prosecdef
                    AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', 'public.photo_dossier_candidat(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.photo_dossier_candidat(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.photo_candidature_figee(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : DEFINER ou ACL invalide';
  END IF;
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL AND (
       NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies p
                    WHERE p.schemaname = 'storage' AND p.policyname = 'photos_enseignants_ecriture'
                      AND p.qual LIKE '%photo_candidature_figee%' AND p.with_check LIKE '%photo_candidature_figee%')
    OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies p
                    WHERE p.schemaname = 'storage' AND p.policyname = 'photos_enseignants_remplacement_candidat'
                      AND p.qual LIKE '%photo_candidature_figee%' AND p.with_check LIKE '%photo_candidature_figee%')) THEN
    RAISE EXCEPTION 'PHOTO-FIGEE : politiques du seau non posees';
  END IF;
END
$postflight$;

COMMIT;
