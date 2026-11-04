-- REAFFECTER-CLASSE (31/10/2026) : la direction retire une Classe a son
-- enseignant pour la confier a un autre (regle du directeur : « la
-- direction peut retirer la classe »).
--
-- DELETE / DROP / TRUNCATE : 0. Deux fonctions publiques creees, droits,
-- commentaires, verifications.
--
-- Aujourd'hui `affecter_enseignant_classe` et `affecter_enseignant_classe_c11bis`
-- n'affectent qu'une Classe en attente et repondent `deja_affecte` sinon :
-- ils restent tels quels. Ce lot ajoute le geste qui manquait, sans dupliquer
-- les regles :
--
-- 1. `reaffecter_enseignant_classe(classe, nouvel enseignant, motif)` :
--    * direction active seule (garde positive) ;
--    * Classe active, non fermee, avec un enseignant ; le meme enseignant
--      redemande : `deja_en_place`, rien n'est reecrit (rejeu) ;
--    * les regles du nouvel enseignant sont celles de l'affectation, par la
--      meme fonction : `app_private.verifier_affectation_enseignant`
--      (compte, piece, langue, genre du public, plafond horaire, maximum de
--      Classes, chevauchement avec ses Classes et seances, verrou par
--      enseignant). Les disponibilites declarees ne sont pas exigees
--      (p_exiger_disponibilites = false, comme `creer_groupe` et la
--      designation d'un remplacant) : la direction decide, l'unicite a
--      l'heure reste stricte ;
--    * en plus, a l'heure exacte de chaque seance future deja creee, il doit
--      etre libre (`private.remplacant_libre_a_l_heure`, R12, PR 96) : une
--      seance ou il remplace deja quelqu'un compte ;
--    * s'applique aux seances futures : `groupes.teacher_id` et
--      `sessions.teacher_id` des seances planifiees qui n'ont pas commence.
--      Une seance passee ou en cours garde son enseignant, donc sa paie
--      (PAIE-REMPLACANT, enseignant effectif inchange) ;
--    * journal : `log_sensitive_access('enseignant_reaffecte_classe')`
--      avec l'ancien, le nouveau, le motif et le nombre de seances ;
--    * notifications : le declencheur existant `notifications_classe_groupes`
--      (20261027120000) envoie `enseignant_change` a l'ancien enseignant, au
--      nouveau et aux familles de la Classe. Rien n'est ajoute ici.
-- 2. `enseignants_pour_reaffectation(classe)` : les enseignants que
--    `reaffecter_enseignant_classe` accepterait, pour la feuille de la
--    direction. Meme verification, aucune seconde regle.
BEGIN;

-- ---------------------------------------------------------------------------
-- Le controle commun aux deux fonctions : leve si [p_enseignant] ne peut pas
-- reprendre la Classe.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.verifier_reaffectation(p_groupe uuid, p_enseignant uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM app_private.verifier_affectation_enseignant(p_groupe, p_enseignant, false);
  IF EXISTS (
    SELECT 1 FROM public.sessions s
     WHERE s.groupe_id = p_groupe AND s.deleted_at IS NULL
       AND s.status = 'planned' AND s.started_at > pg_catalog.now()
       AND NOT private.remplacant_libre_a_l_heure(s.id, p_enseignant)
  ) THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante';
  END IF;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 1. La reaffectation
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.reaffecter_enseignant_classe(
  p_groupe_id uuid, p_enseignant_id uuid, p_motif text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
  v_seances integer;
  v_message text;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'ReaffectationNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR p_enseignant_id IS NULL THEN
    RAISE EXCEPTION 'ReaffectationParametresInvalides' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes g WHERE g.id = p_groupe_id FOR UPDATE;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL OR v_groupe.etat <> 'active'
     OR v_groupe.teacher_id IS NULL THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0001';
  END IF;
  IF v_groupe.teacher_id = p_enseignant_id THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'deja_en_place', 'seances', 0);
  END IF;

  BEGIN
    PERFORM private.verifier_reaffectation(p_groupe_id, p_enseignant_id);
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message LIKE 'chevauchement%' THEN
      RAISE EXCEPTION 'EnseignantOccupe' USING ERRCODE = 'P0001', DETAIL = v_message;
    END IF;
    RAISE EXCEPTION 'EnseignantIncompatible' USING ERRCODE = 'P0001', DETAIL = v_message;
  END;

  -- Les seances futures d'abord, puis la Classe (ses declencheurs creent les
  -- seances manquantes au nom du nouvel enseignant et previennent tout le
  -- monde).
  -- `sessions_no_teacher_overlap` reste le dernier filet : un chevauchement
  -- que le controle n'aurait pas vu est refuse comme tel.
  BEGIN
    UPDATE public.sessions s
       SET teacher_id = p_enseignant_id
     WHERE s.groupe_id = p_groupe_id AND s.deleted_at IS NULL
       AND s.status = 'planned' AND s.started_at > pg_catalog.now();
    GET DIAGNOSTICS v_seances = ROW_COUNT;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'EnseignantOccupe' USING ERRCODE = 'P0001', DETAIL = SQLERRM;
  END;

  UPDATE public.groupes SET teacher_id = p_enseignant_id WHERE id = p_groupe_id;

  PERFORM public.log_sensitive_access(
    'enseignant_reaffecte_classe', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object(
      'ancien_teacher_id', v_groupe.teacher_id,
      'teacher_id', p_enseignant_id,
      'motif', nullif(pg_catalog.btrim(coalesce(p_motif, '')), ''),
      'seances_futures', v_seances));

  RETURN pg_catalog.jsonb_build_object('etat', 'reaffecte', 'seances', v_seances);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les enseignants possibles
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.enseignants_pour_reaffectation(p_groupe_id uuid)
RETURNS TABLE (enseignant_id uuid, nom text, identifiant text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
  v_t record;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'ReaffectationNonAutorisee' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_groupe FROM public.groupes g WHERE g.id = p_groupe_id;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL OR v_groupe.etat <> 'active'
     OR v_groupe.teacher_id IS NULL THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0001';
  END IF;

  FOR v_t IN
    SELECT p.id, p.first_name, p.last_name, p.immutable_id
      FROM public.profiles p
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id
     WHERE p.role = 'teacher' AND p.deleted_at IS NULL
       AND p.id <> v_groupe.teacher_id
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
     ORDER BY p.last_name, p.first_name, p.id
  LOOP
    BEGIN
      PERFORM private.verifier_reaffectation(p_groupe_id, v_t.id);
    EXCEPTION WHEN raise_exception THEN
      CONTINUE;
    END;
    enseignant_id := v_t.id;
    nom := pg_catalog.btrim(pg_catalog.concat_ws(' ', v_t.first_name, v_t.last_name));
    identifiant := v_t.immutable_id;
    RETURN NEXT;
  END LOOP;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits et commentaires
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.verifier_reaffectation(uuid,uuid)'::pg_catalog.regprocedure,
    'public.reaffecter_enseignant_classe(uuid,uuid,text)'::pg_catalog.regprocedure,
    'public.enseignants_pour_reaffectation(uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;
  GRANT EXECUTE ON FUNCTION public.reaffecter_enseignant_classe(uuid, uuid, text) TO authenticated;
  GRANT EXECUTE ON FUNCTION public.enseignants_pour_reaffectation(uuid) TO authenticated;
END;
$droits$;

COMMENT ON FUNCTION private.verifier_reaffectation(uuid, uuid) IS
  'REAFFECTER-CLASSE (31/10/2026) : leve si l''enseignant ne peut pas reprendre la Classe (verifier_affectation_enseignant sans disponibilites, puis libre a l''heure de chaque seance future, R12). Privee.';
COMMENT ON FUNCTION public.reaffecter_enseignant_classe(uuid, uuid, text) IS
  'REAFFECTER-CLASSE (31/10/2026) : la direction retire une Classe active a son enseignant et la confie a un autre ; seances planifiees futures comprises ; journal enseignant_reaffecte_classe ; notifications enseignant_change par le declencheur existant. Erreurs : ReaffectationNonAutorisee, ClasseIndisponible, EnseignantOccupe, EnseignantIncompatible. guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';
COMMENT ON FUNCTION public.enseignants_pour_reaffectation(uuid) IS
  'REAFFECTER-CLASSE (31/10/2026) : enseignants que reaffecter_enseignant_classe accepterait pour cette Classe (meme verification). Direction active seule.';

DO $postflight$
DECLARE
  f record;
BEGIN
  FOR f IN SELECT p.oid, p.oid::pg_catalog.regprocedure AS sig, p.prosecdef, p.proconfig
             FROM pg_catalog.pg_proc p
            WHERE p.oid IN (
              'public.reaffecter_enseignant_classe(uuid,uuid,text)'::pg_catalog.regprocedure,
              'public.enseignants_pour_reaffectation(uuid)'::pg_catalog.regprocedure)
  LOOP
    IF NOT f.prosecdef OR f.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[]
       OR pg_catalog.has_function_privilege('anon', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f.oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'REAFFECTER-CLASSE : DEFINER, search_path ou droits invalides pour %', f.sig;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.verifier_reaffectation(uuid,uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'REAFFECTER-CLASSE : aide privee exposee';
  END IF;
END;
$postflight$;

COMMIT;
