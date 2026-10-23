-- CLASSES-PLAFOND (22/10/2026) : le nombre maximal de Classes par enseignant,
-- reglable par la direction.
--
-- Decision du directeur (22/10/2026, DECISION-CANDIDATURES-2026-10-21.md,
-- section 1 ter, ligne « Charge maximale ») : « trois Classes au plus par
-- enseignant pour l'instant, la direction peut changer cela dans les
-- reglages ».
--
-- Ce qui existait. Le seul plafond cote serveur etait l'horaire
-- (teacher_profiles.weekly_hours_cap, 40 h par defaut, 0001:94) que lit le
-- predicat d'affectation (0082:123, 20261021210200). Il ne dit rien du nombre
-- de Classes : trois Classes de 60 minutes tiennent dans 40 h, et trente
-- aussi. Et max_students_per_teacher (0005) borne les affectations
-- individuelles, fermees depuis L3-02 (20261017150300), pas les Classes.
--
-- 1. Le reglage. Une cle de la table des reglages que lit l'ecran Reglages de
--    la direction (app_config, lecture et ecriture par la seule direction
--    active : app_config_admin_read / _update, 0001, 20261017100800) :
--      enseignant.classes_max   entier de 1 a 80, 3 par defaut.
--    Pas de nouvelle table, pas de nouvelle RPC, pas de nouveau droit. Le
--    journal est celui des autres reglages : guard_app_config_history
--    (0001:938) ecrit l'ancienne et la nouvelle valeur et l'auteur dans
--    app_config_history a chaque changement. Le declencheur
--    app_config_classes_max valide la valeur AVANT lui (l'ordre des
--    declencheurs est alphabetique) : un entier de 1 a 80, ecrit en entier
--    (3.0 devient 3), la cle ne se renomme ni ne s'efface. 80 est le plafond
--    horaire maximal (teacher_profiles_weekly_hours_cap_check) : une Classe
--    prend au moins une heure par semaine, il n'y en a pas davantage a tenir.
--    Le semis ne remplace jamais une valeur deja posee par la direction
--    (ON CONFLICT DO NOTHING).
--
-- 2. Ce qui compte. Une Classe compte pour son enseignant quand elle est
--    ACTIVE et NON CLOSE : groupes.teacher_id = l'enseignant, etat 'active',
--    ended_at nul (la meme definition que classes_actives de
--    enseignants_pour_classe). Ne comptent pas : une Classe close
--    (cloturer_groupe, fusionner_classes), une Classe en attente
--    d'enseignant (elle n'en a pas), un remplacement ponctuel d'une seule
--    seance (remplacements_seance : ni prendre_remplacement ni
--    designer_remplacant_admin n'ecrivent groupes.teacher_id).
--
-- 3. Ou il s'applique. Une Classe n'a qu'un chemin vers un enseignant : le
--    predicat app_private.verifier_affectation_enseignant (20261021210200),
--    appele par creer_groupe (8 arguments) et, par
--    tc_verifier_affectation_enseignant, par affecter_enseignant_classe et
--    affecter_enseignant_classe_c11bis ; publier_groupe_depuis_offre passe
--    par creer_groupe. Le controle s'ajoute donc au predicat, une seule fois.
--    Pour ne pas recopier ses 230 lignes, le predicat existant est RENOMME
--    verifier_affectation_enseignant_base (corps, droits et verrou inchanges),
--    et le nom d'origine devient une enveloppe : la base d'abord, le plafond
--    de Classes ensuite. Consequences voulues :
--    * tout refus existant garde son message et sa priorite (le plafond ne
--      parle que lorsque rien d'autre ne refuse) ;
--    * le verrou par enseignant (pg_advisory_xact_lock « teacher-schedule »)
--      est pris par la base, avant le compte : deux affectations simultanees
--      du meme enseignant se suivent, la seconde compte la premiere ;
--    * enseignants_pour_classe, qui appelle le predicat et saute l'enseignant
--      refuse, ne propose plus un enseignant au plafond.
--    Le refus se nomme plafond_classes_atteint (SQLSTATE P0001, comme les
--    autres refus du predicat), avec en DETAIL le nombre de Classes actives
--    et le maximum. Aucun refus n'est retire ni change.
--    Les autres ecritures de groupes.teacher_id n'existent pas : groupes n'a
--    qu'une policy de lecture (aucun client n'ecrit), la surcharge a six
--    arguments de creer_groupe n'est executable par personne (L3-06), et
--    prendre_eleve / attribuer_eleve, fermees aux clients depuis L3-02, ne
--    creent aucune Classe (teacher_student_assignments, pas groupes) : un
--    cours particulier est une Classe de capacite un, donc compte ici. La
--    migration verifie en fin de course que ces chemins restent fermes.
--
-- 4. Ce qui n'est pas dans ce lot : l'ecran (lib/features/
--    admin_configuration_regles : la cle s'ajoute a clesRegles et a la liste
--    des champs ; admin/service_configuration.dart), et les deux tables de
--    messages de refus du client (core/offres/affectation_refusee.dart,
--    core/admin/creation_classe_refusee.dart) qui rendent aujourd'hui une
--    phrase generique pour plafond_classes_atteint. Aucune Classe existante
--    n'est retiree a un enseignant deja au-dessus du maximum : le plafond
--    refuse la suivante.
--
-- Droits (F86) : les quatre fonctions nouvelles sont de app_private, INVOKER,
-- sans EXECUTE pour aucun role ; le predicat renomme garde les siens.
BEGIN;

-- ------------------------------------------------------------------
-- 1. Le reglage et son declencheur de validation
-- ------------------------------------------------------------------
CREATE FUNCTION private.plafond_classes_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_n numeric;
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.key = 'enseignant.classes_max' THEN
      RAISE EXCEPTION 'le reglage enseignant.classes_max ne s''efface pas : il se change'
        USING ERRCODE = '42501';
    END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.key = 'enseignant.classes_max'
     AND NEW.key IS DISTINCT FROM OLD.key THEN
    RAISE EXCEPTION 'le reglage enseignant.classes_max ne se renomme pas'
      USING ERRCODE = '42501';
  END IF;
  IF NEW.key IS DISTINCT FROM 'enseignant.classes_max' THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number' THEN
    RAISE EXCEPTION 'nombre maximal de Classes par enseignant : un nombre entier de 1 a 80 est attendu'
      USING ERRCODE = '22023';
  END IF;
  v_n := (NEW.value #>> '{}')::numeric;
  IF NOT coalesce(v_n = pg_catalog.trunc(v_n) AND v_n BETWEEN 1 AND 80, false) THEN
    RAISE EXCEPTION 'nombre maximal de Classes par enseignant : un nombre entier de 1 a 80 est attendu'
      USING ERRCODE = '22023';
  END IF;
  NEW.value := pg_catalog.to_jsonb(v_n::integer);
  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.plafond_classes_valider() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.plafond_classes_valider()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.plafond_classes_valider() IS
  'CLASSES-PLAFOND : valide le reglage enseignant.classes_max (entier de 1 a 80, ecrit en entier), '
  'ni renomme ni efface. Declencheur app_config_classes_max, qui precede app_config_history (ordre '
  'alphabetique) pour que le journal garde la valeur ecrite. Aucun EXECUTE client.';

CREATE TRIGGER app_config_classes_max
  BEFORE INSERT OR UPDATE OR DELETE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.plafond_classes_valider();

-- Le defaut du directeur du 22/10 ; jamais ecrase si la direction l'a deja
-- change (la migration se rejoue sans perdre son choix).
INSERT INTO public.app_config (key, value)
VALUES ('enseignant.classes_max', pg_catalog.to_jsonb(3))
ON CONFLICT (key) DO NOTHING;

-- ------------------------------------------------------------------
-- 2. Lire le maximum, compter les Classes, refuser
-- ------------------------------------------------------------------
-- Le maximum en vigueur. Repli sur 3 si la cle manque (app_config_int) ;
-- borne a 1..80 par prudence, le declencheur garantit deja la plage.
CREATE FUNCTION app_private.classes_max_par_enseignant()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT LEAST(80, GREATEST(1, public.app_config_int('enseignant.classes_max', 3)));
$function$;

-- Les Classes qui comptent pour un enseignant : actives, non closes. La Classe
-- p_sauf_groupe_id est ecartee (celle qu'on est en train de lui donner).
CREATE FUNCTION app_private.classes_actives_enseignant(p_teacher_id uuid, p_sauf_groupe_id uuid DEFAULT NULL)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.count(*)::integer
    FROM public.groupes g
   WHERE g.teacher_id = p_teacher_id
     AND g.ended_at IS NULL
     AND g.etat = 'active'
     AND g.id IS DISTINCT FROM p_sauf_groupe_id;
$function$;

-- Refuse une Classe de plus a un enseignant qui est au maximum. Garde
-- positive : un compte ou un maximum inconnus refusent.
CREATE FUNCTION app_private.verifier_plafond_classes_enseignant(p_teacher_id uuid, p_sauf_groupe_id uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_max integer := app_private.classes_max_par_enseignant();
  v_actives integer := app_private.classes_actives_enseignant(p_teacher_id, p_sauf_groupe_id);
BEGIN
  IF NOT coalesce(p_teacher_id IS NOT NULL AND v_actives < v_max, false) THEN
    RAISE EXCEPTION 'plafond_classes_atteint'
      USING DETAIL = pg_catalog.format('classes actives : %s ; maximum : %s', v_actives, v_max);
  END IF;
END;
$function$;

-- ------------------------------------------------------------------
-- 3. Le predicat : l'ancien est renomme, le nom d'origine l'enveloppe
-- ------------------------------------------------------------------
ALTER FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean)
  RENAME TO verifier_affectation_enseignant_base;

CREATE FUNCTION app_private.verifier_affectation_enseignant(
  p_groupe_id uuid,
  p_teacher_id uuid,
  p_exiger_disponibilites boolean
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  -- Tout ce qui refusait deja (compte, piece, acces, langue, genre, plafond
  -- horaire, disponibilites, collisions) refuse comme avant, et garde la
  -- parole ; la base prend le verrou par enseignant.
  PERFORM app_private.verifier_affectation_enseignant_base(
    p_groupe_id, p_teacher_id, p_exiger_disponibilites);
  -- Puis le maximum de Classes (reglage enseignant.classes_max), compte sous
  -- ce verrou.
  PERFORM app_private.verifier_plafond_classes_enseignant(p_teacher_id, p_groupe_id);
END;
$function$;

ALTER FUNCTION app_private.classes_max_par_enseignant() OWNER TO postgres;
ALTER FUNCTION app_private.classes_actives_enseignant(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION app_private.verifier_plafond_classes_enseignant(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.classes_max_par_enseignant(),
  app_private.classes_actives_enseignant(uuid, uuid),
  app_private.verifier_plafond_classes_enseignant(uuid, uuid),
  app_private.verifier_affectation_enseignant(uuid, uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION app_private.classes_max_par_enseignant() IS
  'CLASSES-PLAFOND : le nombre maximal de Classes par enseignant, reglage app_config enseignant.classes_max (3 par defaut, 1 a 80). INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.classes_actives_enseignant(uuid, uuid) IS
  'CLASSES-PLAFOND : Classes qui comptent pour un enseignant (actives, non closes, hors la Classe passee). Un remplacement ponctuel ne compte pas. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_plafond_classes_enseignant(uuid, uuid) IS
  'CLASSES-PLAFOND : refuse plafond_classes_atteint (P0001) quand l''enseignant est deja au maximum de Classes. Garde positive. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_affectation_enseignant(uuid, uuid, boolean) IS
  'CLASSES-PLAFOND : predicat d''affectation d''un enseignant a une Classe = verifier_affectation_enseignant_base (CAND-Q15 : compte, piece, acces, langue, genre, plafond horaire, disponibilites si exigees, collisions, verrou par enseignant) puis le maximum de Classes (plafond_classes_atteint). INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_affectation_enseignant_base(uuid, uuid, boolean) IS
  'CAND-Q15 : predicat C-04/C-07 de 0082 (compte, piece validee, acces, langue, genre, plafond horaire, collisions, verrou par enseignant). p_exiger_disponibilites : couverture par weekly_availability exigee si true ou NULL ; false pour creer_groupe (D4). Renomme par CLASSES-PLAFOND, corps inchange : l''enveloppe verifier_affectation_enseignant lui ajoute le maximum de Classes. INVOKER, aucun EXECUTE client.';

-- ------------------------------------------------------------------
-- 4. Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_base regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)');
  v_envel regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)');
  v_fonctions regprocedure[] := ARRAY[
    pg_catalog.to_regprocedure('app_private.classes_max_par_enseignant()'),
    pg_catalog.to_regprocedure('app_private.classes_actives_enseignant(uuid,uuid)'),
    pg_catalog.to_regprocedure('app_private.verifier_plafond_classes_enseignant(uuid,uuid)'),
    pg_catalog.to_regprocedure('app_private.verifier_affectation_enseignant(uuid,uuid,boolean)'),
    pg_catalog.to_regprocedure('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'),
    pg_catalog.to_regprocedure('private.plafond_classes_valider()')];
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_valeur jsonb;
  v_def text;
BEGIN
  -- Les six fonctions existent, appartiennent a postgres, fixent un
  -- search_path vide, sont INVOKER et ne sont executables par personne.
  FOREACH v_f IN ARRAY v_fonctions LOOP
    IF v_f IS NULL THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND : fonction absente';
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF v_p.prosecdef
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND : % doit etre INVOKER, a postgres, search_path vide', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-PLAFOND : % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;

  -- L'enveloppe appelle la base puis le plafond ; la base n'appelle pas le plafond
  -- (sinon il compterait deux fois et la base ne serait plus la base).
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_envel::oid;
  IF pg_catalog.strpos(v_p.prosrc, 'app_private.verifier_affectation_enseignant_base(') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'app_private.verifier_plafond_classes_enseignant(p_teacher_id, p_groupe_id)') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'verifier_plafond_classes_enseignant')
        < pg_catalog.strpos(v_p.prosrc, 'verifier_affectation_enseignant_base') THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : l''enveloppe du predicat doit appeler la base puis le plafond';
  END IF;
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_base::oid;
  IF pg_catalog.strpos(v_p.prosrc, 'plafond_classes') <> 0
     OR pg_catalog.strpos(v_p.prosrc, 'enseignant non disponible: jour') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'plafond horaire enseignant dépassé') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'pg_advisory_xact_lock') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'teacher-schedule:') = 0 THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : la base du predicat n''est plus celle de CAND-Q15 (ou ne prend plus le verrou par enseignant, sous lequel le plafond compte)';
  END IF;
  -- Le predicat public delegue toujours a l'enveloppe, jamais a la base.
  SELECT * INTO v_p FROM pg_catalog.pg_proc
   WHERE oid = 'public.tc_verifier_affectation_enseignant(uuid,uuid)'::regprocedure::oid;
  IF pg_catalog.strpos(v_p.prosrc,
       'app_private.verifier_affectation_enseignant(p_groupe_id, p_teacher_id, true)') = 0 THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : tc_verifier_affectation_enseignant ne passe plus par l''enveloppe';
  END IF;
  -- creer_groupe (8 arguments) passe par l'enveloppe, sans disponibilites.
  SELECT * INTO v_p FROM pg_catalog.pg_proc
   WHERE oid = 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure::oid;
  IF pg_catalog.strpos(v_p.prosrc,
       'app_private.verifier_affectation_enseignant(v_id, p_teacher_profile_id, false)') = 0 THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : creer_groupe ne passe plus par l''enveloppe';
  END IF;

  -- Les chemins qui contourneraient le plafond restent fermes : la surcharge a
  -- six arguments de creer_groupe (elle pose un enseignant sans predicat), et
  -- les deux affectations individuelles.
  FOREACH v_f IN ARRAY ARRAY[
      'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)'::regprocedure,
      'public.attribuer_eleve(uuid,uuid,integer,integer,text)'::regprocedure,
      'public.prendre_eleve(uuid,integer,integer)'::regprocedure] LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-PLAFOND : % peut executer % (contournerait le plafond de Classes)', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;
  -- Aucun client n'ecrit groupes directement : aucune policy d'ecriture.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies p
              WHERE p.schemaname = 'public' AND p.tablename = 'groupes' AND p.cmd <> 'SELECT') THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : une policy d''ecriture existe sur groupes (contournerait le plafond de Classes)';
  END IF;

  -- Le reglage : present, entier de 1 a 80 ; son declencheur precede le journal.
  SELECT c.value INTO v_valeur FROM public.app_config c WHERE c.key = 'enseignant.classes_max';
  IF v_valeur IS NULL OR pg_catalog.jsonb_typeof(v_valeur) <> 'number'
     OR (v_valeur #>> '{}') !~ '^[0-9]{1,2}$'
     OR (v_valeur #>> '{}')::integer NOT BETWEEN 1 AND 80 THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : reglage enseignant.classes_max absent ou invalide : %', v_valeur;
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.app_config'::regclass AND NOT t.tgisinternal
         AND t.tgname = 'app_config_classes_max' AND t.tgenabled = 'O') <> 1
     OR 'app_config_classes_max' COLLATE "C" >= 'app_config_history' COLLATE "C" THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : declencheur de validation absent ou apres le journal';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.app_config'::regclass AND NOT t.tgisinternal
                    AND t.tgname = 'app_config_history' AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : le journal des reglages (app_config_history) est absent';
  END IF;
  v_def := pg_catalog.pg_get_triggerdef(
    (SELECT t.oid FROM pg_catalog.pg_trigger t
      WHERE t.tgrelid = 'public.app_config'::regclass AND t.tgname = 'app_config_classes_max'));
  IF v_def NOT LIKE '%BEFORE INSERT OR DELETE OR UPDATE ON public.app_config%' THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND : declencheur de validation mal pose : %', v_def;
  END IF;
END;
$postflight$;

COMMIT;
