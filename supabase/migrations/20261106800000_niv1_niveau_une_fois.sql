-- NIV1 (03/11/2026, fiche PLAN-LOTS section 9, plan valide par le pilote) :
-- le niveau demande une seule fois.
--
-- 1. lier_apprenant_profil marque la fiche remplie (onboarding_fait_le)
--    quand la tranche, la langue, le niveau et l'objectif sont connus apres
--    la reprise des reponses de la demande. Le Parcours
--    (v_parcours_onboarding, ParcoursOffresPage, non modifie) s'ouvre alors
--    sur les horaires.
-- 2. Un declencheur reprend le niveau, l'objectif et la langue que le
--    titulaire a donnes pour lui-meme dans sa demande (« pour moi », ou
--    parent qui suit des cours) sur son profil eleve, ne dans la meme
--    inscription : jusqu'ici ils ne rejoignaient aucun profil.
-- 3. UX-032 : une contrainte NOT VALID refuse desormais une candidature
--    d'enfant de moins de 6 ans (decision du 13/10/2026 ;
--    creer_profil_enfant refuse deja moins de 6 ans). L'ancienne contrainte
--    (5 a 17) reste ; les lignes existantes ne sont pas revalidees. Le refus
--    se produit dans la RPC de soumission (inscrire_titulaire), a
--    l'insertion de l'apprenant.
--
-- FICHIER SANS EFFACEMENT (regle B5) : un remplacement de fonction a
-- signature egale, une fonction de declencheur et son declencheur nouveaux,
-- une contrainte ajoutee ; rien n'est retire.

BEGIN;

-- 1. lier_apprenant_profil ------------------------------------------------

CREATE OR REPLACE FUNCTION public.lier_apprenant_profil(p_apprenant_id uuid, p_profil_eleve_id uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_a public.candidature_apprenants;
  v_c public.candidatures;
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'session active requise' USING ERRCODE = '42501';
  END IF;
  SELECT a.* INTO v_a FROM public.candidature_apprenants a WHERE a.id = p_apprenant_id FOR UPDATE;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_a.candidature_id;
  IF NOT FOUND OR v_c.profile_id IS DISTINCT FROM auth.uid() OR v_c.etape <> 'confirmee'
     OR v_a.est_titulaire THEN
    RAISE EXCEPTION 'apprenant introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_a.profil_eleve_id IS NOT NULL THEN
    IF v_a.profil_eleve_id = p_profil_eleve_id THEN
      RETURN;
    END IF;
    RAISE EXCEPTION 'apprenant deja lie' USING ERRCODE = '23505';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.profiles e
         JOIN public.profiles t ON t.id = auth.uid()
        WHERE e.id = p_profil_eleve_id AND e.role = 'student' AND e.deleted_at IS NULL
          AND e.household_id = t.household_id) THEN
    RAISE EXCEPTION 'profil d''eleve hors du foyer' USING ERRCODE = '42501';
  END IF;
  UPDATE public.candidature_apprenants SET profil_eleve_id = p_profil_eleve_id WHERE id = v_a.id;
  UPDATE public.profiles SET gender = v_a.genre WHERE id = p_profil_eleve_id AND gender IS NULL;
  UPDATE public.student_profiles s
     SET niveau_declare = coalesce(s.niveau_declare, v_a.niveau_declare),
         objectif = coalesce(s.objectif, v_a.objectif),
         langue_cours = coalesce(s.langue_cours, v_a.langue_code)
   WHERE s.profile_id = p_profil_eleve_id;
  -- NIV1 : les reponses de la demande valent le questionnaire du Parcours.
  -- Quand la fiche a sa tranche (posee par creer_profil_enfant), sa langue,
  -- son niveau et son objectif, elle est marquee remplie : le Parcours
  -- s'ouvre sur les horaires sans reposer les questions. Un enfant sans
  -- tranche (moins de 6 ans, exception de la direction) garde le
  -- questionnaire.
  UPDATE public.student_profiles s
     SET onboarding_fait_le = pg_catalog.now()
   WHERE s.profile_id = p_profil_eleve_id
     AND s.deleted_at IS NULL
     AND s.onboarding_fait_le IS NULL
     AND s.cohorte IS NOT NULL
     AND s.langue_cours IS NOT NULL
     AND s.niveau_declare IS NOT NULL
     AND s.objectif IS NOT NULL;
  PERFORM public.log_sensitive_access('admission_apprenant_lie', 'candidature_apprenants',
    v_a.id::text, pg_catalog.jsonb_build_object('profil_eleve_id', p_profil_eleve_id));
END;
$function$;

-- 2. Le niveau du titulaire rejoint son profil eleve -----------------------
--
-- Le profil eleve du titulaire (« pour moi », ou parent qui suit des cours)
-- nait a l'inscription (private.creer_profil_inscription_interne), AVANT que
-- ses reponses soient rangees dans candidature_apprenants ; et
-- lier_apprenant_profil exclut le titulaire. Un declencheur reprend donc
-- ses reponses des leur insertion, sans ecraser une valeur deja posee.

CREATE FUNCTION private.niv1_reponses_titulaire_vers_profil()
RETURNS trigger
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.student_profiles s
     SET niveau_declare = coalesce(s.niveau_declare, NEW.niveau_declare),
         objectif = coalesce(s.objectif, NEW.objectif),
         langue_cours = coalesce(s.langue_cours, NEW.langue_code)
    FROM public.candidatures c
   WHERE c.id = NEW.candidature_id
     AND s.profile_id = c.profile_id
     AND s.titulaire_profile_id = c.profile_id
     AND s.deleted_at IS NULL;
  -- Meme regle que pour un enfant : la fiche complete est marquee remplie.
  UPDATE public.student_profiles s
     SET onboarding_fait_le = pg_catalog.now()
    FROM public.candidatures c
   WHERE c.id = NEW.candidature_id
     AND s.profile_id = c.profile_id
     AND s.titulaire_profile_id = c.profile_id
     AND s.deleted_at IS NULL
     AND s.onboarding_fait_le IS NULL
     AND s.cohorte IS NOT NULL
     AND s.langue_cours IS NOT NULL
     AND s.niveau_declare IS NOT NULL
     AND s.objectif IS NOT NULL;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.niv1_reponses_titulaire_vers_profil() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.niv1_reponses_titulaire_vers_profil()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER niv1_reponses_titulaire_vers_profil
  AFTER INSERT ON public.candidature_apprenants
  FOR EACH ROW
  WHEN (NEW.est_titulaire)
  EXECUTE FUNCTION private.niv1_reponses_titulaire_vers_profil();

-- 3. UX-032 : pas de candidature d'enfant sous 6 ans ------------------------

ALTER TABLE public.candidature_apprenants
  ADD CONSTRAINT candidature_apprenants_age_min_6
  CHECK (age IS NULL OR age >= 6) NOT VALID;

COMMENT ON CONSTRAINT candidature_apprenants_age_min_6 ON public.candidature_apprenants IS
  'NIV1, UX-032 (03/11/2026) : age minimum 6 ans (decision du 13/10/2026), comme creer_profil_enfant. NOT VALID : les lignes anterieures ne sont pas revalidees.';

-- Droits et empreintes ----------------------------------------------------

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.lier_apprenant_profil(uuid,uuid)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=TITULAIRE_SELF; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. NIV1 : niveau demande une seule fois. Must-pass: supabase/tests/scenarios_niv1_niveau_une_fois.sql.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.lier_apprenant_profil(uuid,uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'NIV1 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
    IF pg_catalog.strpos(pg_catalog.obj_description(v_oid, 'pg_proc'),
                         pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))) = 0 THEN
      RAISE EXCEPTION 'NIV1 : empreinte F86 absente ou perimee pour %', v_oid;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgname = 'niv1_reponses_titulaire_vers_profil'
                    AND t.tgrelid = 'public.candidature_apprenants'::pg_catalog.regclass)
     OR pg_catalog.has_function_privilege('authenticated',
          'private.niv1_reponses_titulaire_vers_profil()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
          'private.niv1_reponses_titulaire_vers_profil()', 'EXECUTE') THEN
    RAISE EXCEPTION 'NIV1 : declencheur du titulaire absent ou fonction ouverte';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
                  WHERE conname = 'candidature_apprenants_age_min_6'
                    AND conrelid = 'public.candidature_apprenants'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'NIV1 : contrainte d''age absente';
  END IF;
END;
$postflight$;

COMMIT;
