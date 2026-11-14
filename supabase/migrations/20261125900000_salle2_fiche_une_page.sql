-- SALLE2-FICHE (directeur, 14/11/2026, relaye par le pilote) : la fiche de
-- candidature de la direction en cinq etapes au plus, un clic par decision,
-- sans re-saisie de ce que le candidat a declare.
--
-- 1. private.candidature_entretien_controles : « Evaluation validee » ne
--    demande plus le constat du compte rendu (memorisation, riwayas, ijaza).
--    Le directeur : « la declaration du candidat suffit, la direction peut
--    corriger si besoin ». Le controle vaut des que l'entretien est tenu.
--    « Entretien conclu » ne change pas (tenu et avis favorable) : le resultat
--    « Concluant » de la fiche ecrit cet avis favorable.
--    Constat en production le 14/11 : refus « Evaluation validee (compte
--    rendu incomplet : memorisation, riwayas ou ijaza) » sur la fiche de Sam
--    Tester, qui obligeait a re-cocher tout le declare.
-- 2. public.piece_candidature(p_candidature) : la piece d'identite d'une
--    candidature pour la fiche (profil, document le plus recent, son etat),
--    pour l'ouvrir et la decider sur place. Meme garde que lire_candidature :
--    direction active, de son cote (super-admin : les deux, trace). Ni
--    chemin ni URL : la piece s'ouvre par le circuit existant
--    (piece-identite-acces), la decision par decider_dossier.
--
-- Preflight : candidature_entretien_controles de production a l'empreinte du
-- depot (md5 a0c5dbcdb8dc36374ba2e82e4cd72185, lu le 14/11/2026).
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

DO $preflight$
DECLARE
  v_ctl text := pg_catalog.md5(pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure));
BEGIN
  IF pg_catalog.to_regprocedure('public.piece_candidature(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'SALLE2-FICHE : deja installee';
  END IF;
  IF v_ctl <> 'a0c5dbcdb8dc36374ba2e82e4cd72185' THEN
    RAISE EXCEPTION 'SALLE2-FICHE : candidature_entretien_controles a change depuis le depot (md5 %)', v_ctl;
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Evaluation validee : l'entretien tenu suffit
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.candidature_entretien_controles(p_candidature uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_conclusion jsonb;
  v_tenu boolean;
  v_favorable boolean;
BEGIN
  IF pg_catalog.to_regprocedure('private.entretien_conclusion(uuid)') IS NULL THEN
    RETURN pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('nom', 'entretien_conclu', 'valeur', false,
                                    'cause', 'entretien_non_disponible'),
      pg_catalog.jsonb_build_object('nom', 'evaluation_validee', 'valeur', false,
                                    'cause', 'entretien_non_disponible'));
  END IF;
  EXECUTE 'SELECT private.entretien_conclusion($1)' INTO v_conclusion USING p_candidature;
  v_tenu := coalesce((v_conclusion ->> 'tenu')::boolean, false);
  v_favorable := coalesce((v_conclusion ->> 'avisFavorable')::boolean, false);
  -- SALLE2-FICHE : la declaration du candidat suffit ; le constat du compte
  -- rendu n'est plus un prealable (directeur, 14/11/2026).
  RETURN pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('nom', 'entretien_conclu', 'valeur', v_tenu AND v_favorable,
      'cause', CASE WHEN NOT v_tenu THEN 'entretien_non_tenu'
                    WHEN NOT v_favorable THEN 'avis_non_favorable' END),
    pg_catalog.jsonb_build_object('nom', 'evaluation_validee', 'valeur', v_tenu,
      'cause', CASE WHEN NOT v_tenu THEN 'entretien_non_tenu' END));
END;
$function$;
REVOKE ALL ON FUNCTION private.candidature_entretien_controles(uuid) FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.candidature_entretien_controles(uuid) FROM agent_ro';
  END IF;
END;
$agent_ro$;

-- ---------------------------------------------------------------------------
-- 2. La piece d'une candidature, pour la fiche
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.piece_candidature(p_candidature uuid)
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
ALTER FUNCTION public.piece_candidature(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.piece_candidature(uuid) FROM PUBLIC, anon, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.piece_candidature(uuid) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.piece_candidature(uuid) TO authenticated;

DO $empreintes$
DECLARE
  f regprocedure := 'public.piece_candidature(uuid)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.piece_candidature(uuid); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-14. '
    || 'SALLE2-FICHE : la piece la plus recente d''une candidature (profil, document, etat), pour la decider sur la fiche. '
    || 'Must-pass: supabase/tests/scenarios_salle3_prets.sql (partie SALLE2-FICHE).');
END;
$empreintes$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure),
                       'constat_incomplet') > 0 THEN
    RAISE EXCEPTION 'SALLE2-FICHE : le constat est encore exige';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.piece_candidature(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.piece_candidature(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.candidature_entretien_controles(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE2-FICHE : droits d''execution inattendus';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.piece_candidature(uuid)'::regprocedure
                    AND p.prosecdef AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)) THEN
    RAISE EXCEPTION 'SALLE2-FICHE : SECURITY DEFINER et search_path vide attendus';
  END IF;
END;
$postflight$;
