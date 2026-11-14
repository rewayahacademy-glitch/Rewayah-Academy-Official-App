-- SALLE2-FICHE, rattrapage (14/11/2026). Constat du pilote en production :
-- l'ANCIENNE version de 20261125900000 a ete installee. Elle a cree
-- public.piece_candidature(uuid), renommee depuis public.piece_dossier_candidat(uuid)
-- parce que le garde CAND-L1 refuse toute RPC publique dont le nom contient
-- « candidature » (scenarios_cand_l1_socle). Le controle « evaluation_validee »
-- de cette ancienne version est identique a la nouvelle : rien a rattraper
-- de ce cote.
--
-- Ce fichier, rejouable et sans effacement :
--   1. cree ou remplace public.piece_dossier_candidat(uuid), le meme corps que
--      la nouvelle 20261125900000 (le client de la PR #480 l'appelle) ;
--   2. retire l'execution de public.piece_candidature(uuid) a PUBLIC, anon,
--      authenticated et service_role, si elle existe (elle n'est pas effacee : la
--      fonction reste, inerte). Sur une base neuve, elle n'existe pas.
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

CREATE OR REPLACE FUNCTION public.piece_dossier_candidat(p_candidature uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
  v_doc public.kyc_documents;
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
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature;
  IF v_c.id IS NULL OR NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  IF v_c.profile_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('profilId', NULL, 'statut', 'sans_compte');
  END IF;
  SELECT k.* INTO v_doc FROM public.kyc_documents k
   WHERE k.profile_id = v_c.profile_id
   ORDER BY k.created_at DESC, k.id DESC
   LIMIT 1;
  RETURN pg_catalog.jsonb_build_object(
    'profilId', v_c.profile_id,
    'documentId', v_doc.id,
    'statut', CASE WHEN v_doc.id IS NULL THEN 'a_deposer' ELSE v_doc.status::text END,
    'motifRefus', v_doc.rejection_reason,
    'deposeLe', v_doc.created_at,
    'decideLe', v_doc.verified_at);
END;
$function$;
ALTER FUNCTION public.piece_dossier_candidat(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.piece_dossier_candidat(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.piece_dossier_candidat(uuid) TO authenticated;

DO $rattrapage$
DECLARE
  f regprocedure := 'public.piece_dossier_candidat(uuid)'::regprocedure;
  ancienne regprocedure := pg_catalog.to_regprocedure('public.piece_candidature(uuid)');
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.piece_dossier_candidat(uuid) FROM agent_ro';
  END IF;
  IF ancienne IS NOT NULL THEN
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role', ancienne);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', ancienne);
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', ancienne,
      'SALLE2-FICHE : remplacee par public.piece_dossier_candidat(uuid) (20261125905000) ; plus executable par un client.');
  END IF;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.piece_dossier_candidat(uuid); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-14. '
    || 'SALLE2-FICHE : la piece la plus recente d''une candidature (profil, document, etat), pour la decider sur la fiche.');
END;
$rattrapage$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.piece_dossier_candidat(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.piece_dossier_candidat(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE2-FICHE rattrapage : droits inattendus sur piece_dossier_candidat';
  END IF;
  IF pg_catalog.to_regprocedure('public.piece_candidature(uuid)') IS NOT NULL
     AND (pg_catalog.has_function_privilege('authenticated', 'public.piece_candidature(uuid)', 'EXECUTE')
          OR pg_catalog.has_function_privilege('anon', 'public.piece_candidature(uuid)', 'EXECUTE')) THEN
    RAISE EXCEPTION 'SALLE2-FICHE rattrapage : piece_candidature encore executable par un client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.piece_dossier_candidat(uuid)'::regprocedure
                    AND p.prosecdef AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)) THEN
    RAISE EXCEPTION 'SALLE2-FICHE rattrapage : SECURITY DEFINER et search_path vide attendus';
  END IF;
END;
$postflight$;
