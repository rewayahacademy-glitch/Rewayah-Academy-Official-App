-- V1-a-bis (03/11/2026, numero reserve par garde-cap) : le super-admin agit
-- des deux cotes sur les entretiens.
--
-- Decision du directeur, 03/11 vers 20:30, relayee par garde-cap, mot pour
-- mot : « moi je peux tout voir, et je peux ajouter des agents feminins tout
-- comme j'ajoute des agents masculins pour les interview, je choisi qui je
-- veux sur une liste et c'est tout. »
--
-- Ce que pose ce fichier, sur ce qui tourne en production (20261108000001,
-- installee le 03/11 a 20:29, et le moteur des candidatures retouche par le
-- lot C du 30/10) :
--   * le super-admin de 0088, tant que `kyc_exception_super_admin` est vrai,
--     planifie, modifie les participants, consigne l'issue et lit les
--     entretiens des deux cotes. Une direction qui n'est pas super-admin
--     reste de son cote. Cela remplace, sur ce point, « l'exception
--     super-admin reste une exception de lecture » (CAND-L2A2) ;
--   * chaque geste du super-admin hors de son genre est ecrit au journal
--     sensible (audit_logs, action `super_admin_hors_cote`, mention
--     « super-admin hors côté ») ;
--   * CAND-Q07 reste tenu pour les participants : un participant est du cote
--     de la candidature, ou le super-admin ;
--   * `personnel_pour_entretien(p_candidature)` : le personnel du cote de
--     la candidature, plus le super-admin. `personnel_entretiens()` reste tel
--     quel (garde-cap, 03/11), aucune surcharge. Le nom propose,
--     `personnel_entretien_candidature`, est refuse par les gardes CAND-L1 et
--     CAND-L2A2 (aucune RPC publique dont le nom contient « candidature » en
--     dehors des cinq lectures du lot, pour ne pas doubler etat_dossier()).
--
-- Le moteur ne leve sa borne de genre pour le super-admin que pour les
-- gestes d'entretien (planifier_entretien, consigner_entretien_tenu,
-- consigner_entretien_non_tenu). « Les gestes de la candidature qui y
-- menent » n'ont pas de liste decidee : ils restent de son cote tant
-- qu'aucune decision ne les nomme (private.entretien_gestes_super_admin).
--
-- Fonctions existantes retouchees : toutes par ancres comptees sur le corps
-- en vigueur (chaque ancre une fois et une seule, sinon la migration
-- s'arrete), aucune recopie entiere :
--   private.entretien_direction_de_son_cote, public.planifier_entretien,
--   public.ajouter_participant_entretien, public.retirer_participant_entretien,
--   public.consigner_entretien, public.mes_entretiens,
--   private.candidature_geste_ouvrir.
-- public.lire_entretien n'est pas retouchee : elle passe deja par
-- private.entretien_direction_de_son_cote.
--
-- Mots de suppression de ce fichier : 0.

-- ---------------------------------------------------------------------------
-- 1. Les aides
-- ---------------------------------------------------------------------------
-- La direction qui agit sur un entretien de ce cote : la direction active de
-- ce genre, ou le super-admin de 0088 (exception active), des deux cotes.
CREATE FUNCTION private.entretien_peut_agir(p_genre public.gender)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_genre IS NOT NULL AND (
    coalesce((SELECT l.genre FROM private.cand_lecteur() l) = p_genre, false)
    OR coalesce(public.kyc_super_admin_exception_active(), false));
$function$;

-- Les gestes du moteur que le super-admin fait hors de son cote : ceux des
-- entretiens seulement.
CREATE FUNCTION private.entretien_gestes_super_admin()
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT ARRAY['planifier_entretien', 'consigner_entretien_tenu', 'consigner_entretien_non_tenu']::text[];
$function$;

-- Le journal sensible d'un geste d'entretien hors du genre de son auteur.
CREATE FUNCTION private.entretien_journal_hors_cote(p_genre public.gender, p_geste text, p_ref uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF (SELECT l.genre FROM private.cand_lecteur() l) IS DISTINCT FROM p_genre THEN
    PERFORM public.log_sensitive_access('super_admin_hors_cote', 'entretiens', p_ref::text,
      pg_catalog.jsonb_build_object('geste', p_geste, 'mention', 'super-admin hors côté',
                                    'genreCandidature', p_genre));
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION private.entretien_peut_agir(public.gender) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_gestes_super_admin() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_journal_hors_cote(public.gender, text, uuid) FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Le personnel d'une candidature
-- ---------------------------------------------------------------------------
-- Le personnel actif du cote de la candidature (CAND-Q07), et le super-admin.
-- Lu par la direction de ce cote, ou par le super-admin des deux cotes.
-- Aucun contact.
CREATE FUNCTION public.personnel_pour_entretien(p_candidature uuid)
RETURNS TABLE (profile_id uuid, prenom text, nom text, role text, fondateur boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'personnel des entretiens reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT c.genre INTO v_genre FROM public.candidatures c WHERE c.id = p_candidature;
  IF NOT private.entretien_peut_agir(v_genre) THEN
    RAISE EXCEPTION 'personnel des entretiens : candidature hors de portee' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT p.id, p.first_name, p.last_name, p.role::text, coalesce(f.fondateur, false)
      FROM public.profiles p
      LEFT JOIN public.personnel_fondateurs f ON f.profile_id = p.id
     WHERE private.personnel_actif(p.id)
       AND private.entretien_cote_permis(p.id, v_genre)
     ORDER BY coalesce(f.fondateur, false) DESC, p.first_name, p.last_name;
END;
$function$;
REVOKE ALL ON FUNCTION public.personnel_pour_entretien(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.personnel_pour_entretien(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Les retouches par ancres
-- ---------------------------------------------------------------------------
CREATE FUNCTION pg_temp.retoucher(p_f pg_catalog.regprocedure, p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1, migration a revoir : %',
      p_f, v_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- 3.1 L'entretien, pour la direction de son cote ou le super-admin.
SELECT pg_temp.retoucher('private.entretien_direction_de_son_cote(uuid)',
  $a$   WHERE e.session_id = p_session AND c.genre = v_genre;$a$,
  $a$   WHERE e.session_id = p_session AND private.entretien_peut_agir(c.genre);$a$);

-- 3.2 Planifier : journal hors cote (la borne du moteur est levee en 3.7).
SELECT pg_temp.retoucher('public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)',
  $a$  PERFORM private.candidature_geste_appliquer(p_candidature, 'planifier_entretien',$a$,
  $a$  PERFORM private.entretien_journal_hors_cote(v_c.genre, 'planifier_entretien', v_seance);
  PERFORM private.candidature_geste_appliquer(p_candidature, 'planifier_entretien',$a$);

-- 3.3 Ajouter un participant : journal hors cote.
SELECT pg_temp.retoucher('public.ajouter_participant_entretien(uuid,uuid)',
  $a$  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'ajoute', p_profil);$a$,
  $a$  PERFORM private.entretien_journal_hors_cote(v_genre, 'ajouter_participant', p_session);
  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'ajoute', p_profil);$a$);

-- 3.4 Retirer un participant : journal hors cote.
SELECT pg_temp.retoucher('public.retirer_participant_entretien(uuid,uuid)',
  $a$  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'retire', p_profil);$a$,
  $a$  PERFORM private.entretien_journal_hors_cote(
    (SELECT c.genre FROM public.candidatures c WHERE c.id = v_e.candidature_id),
    'retirer_participant', p_session);
  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'retire', p_profil);$a$);

-- 3.5 Consigner : journal hors cote.
SELECT pg_temp.retoucher('public.consigner_entretien(uuid,text,text,integer,text)',
  $a$  PERFORM private.candidature_geste_appliquer(v_e.candidature_id, v_geste,$a$,
  $a$  PERFORM private.entretien_journal_hors_cote(
    (SELECT c.genre FROM public.candidatures c WHERE c.id = v_e.candidature_id), v_geste, p_session);
  PERFORM private.candidature_geste_appliquer(v_e.candidature_id, v_geste,$a$);

-- 3.6 Mes entretiens : le super-admin voit les deux cotes.
SELECT pg_temp.retoucher('public.mes_entretiens(integer)',
  $a$       AND ((v_genre IS NOT NULL AND c.genre = v_genre)$a$,
  $a$       AND ((v_genre IS NOT NULL AND private.entretien_peut_agir(c.genre))$a$);

-- 3.7 Le moteur : la borne de genre (L2A1, retouchee par le lot C du 30/10)
-- est levee pour le super-admin, pour les seuls gestes d'entretien.
SELECT pg_temp.retoucher('private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)',
  $a$  IF p_categorie = 'direction' AND v_c.genre IS DISTINCT FROM v_genre AND v_c.type_code NOT IN ('famille', 'eleve_adulte') THEN
    RETURN private.cand_hors_portee(v_c.id, v_lecteur, 'geste:' || p_geste);
  END IF;$a$,
  $a$  IF p_categorie = 'direction' AND v_c.genre IS DISTINCT FROM v_genre AND v_c.type_code NOT IN ('famille', 'eleve_adulte')
     -- V1-a-bis : le super-admin de 0088 (exception active) fait les gestes
     -- d'entretien des deux cotes ; le geste est ecrit au journal sensible
     -- par la fonction d'entretien qui l'appelle.
     AND NOT (p_geste = ANY (private.entretien_gestes_super_admin())
              AND coalesce(public.kyc_super_admin_exception_active(), false)) THEN
    RETURN private.cand_hors_portee(v_c.id, v_lecteur, 'geste:' || p_geste);
  END IF;$a$);

-- ---------------------------------------------------------------------------
-- 4. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
  v_def text;
BEGIN
  -- Chaque retouche est la.
  FOREACH v_f IN ARRAY ARRAY[
      'private.entretien_direction_de_son_cote(uuid)', 'public.mes_entretiens(integer)'] LOOP
    IF pg_catalog.pg_get_functiondef(v_f::regprocedure) !~ 'entretien_peut_agir' THEN
      RAISE EXCEPTION 'V1-a-bis : % sans le super-admin', v_f;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
      'public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)',
      'public.ajouter_participant_entretien(uuid,uuid)', 'public.retirer_participant_entretien(uuid,uuid)',
      'public.consigner_entretien(uuid,text,text,integer,text)'] LOOP
    IF pg_catalog.pg_get_functiondef(v_f::regprocedure) !~ 'entretien_journal_hors_cote' THEN
      RAISE EXCEPTION 'V1-a-bis : % sans le journal hors cote', v_f;
    END IF;
  END LOOP;
  v_def := pg_catalog.pg_get_functiondef(
    'private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)'::regprocedure);
  IF v_def !~ 'entretien_gestes_super_admin' OR v_def !~ 'famille'', ''eleve_adulte' THEN
    RAISE EXCEPTION 'V1-a-bis : la borne de genre du moteur n''a pas son exception, ou le lot C est defait';
  END IF;
  -- La salle 3 (20261108300000) et V1-a (20261108000001) ne sont jamais defaites.
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF v_def !~ '''validerPiece'', v_decider' OR v_def !~ '''planifierEntretien'', v_decider'
     OR v_def !~ '''consignerEntretien'', v_decider' THEN
    RAISE EXCEPTION 'V1-a-bis : validerPiece, planifierEntretien ou consignerEntretien ne suit plus v_decider';
  END IF;
  -- personnel_entretiens() reste telle quelle, a cote de la nouvelle.
  IF pg_catalog.to_regprocedure('public.personnel_entretiens()') IS NULL THEN
    RAISE EXCEPTION 'V1-a-bis : personnel_entretiens() a disparu';
  END IF;
  -- Les droits.
  IF pg_catalog.has_function_privilege('anon', 'public.personnel_pour_entretien(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.personnel_pour_entretien(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'V1-a-bis : droits inattendus sur personnel_pour_entretien';
  END IF;
  FOREACH v_f IN ARRAY ARRAY['private.entretien_peut_agir(public.gender)',
      'private.entretien_gestes_super_admin()', 'private.entretien_journal_hors_cote(public.gender,text,uuid)'] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'V1-a-bis : % executable par un client', v_f;
    END IF;
  END LOOP;
END;
$postflight$;
