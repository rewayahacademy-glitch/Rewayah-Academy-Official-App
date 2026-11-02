-- REGLES-A3 (01/11/2026) : les trois delais de la regle A3 se reglent dans
-- Configuration > Regles, et le serveur exige leur ordre.
--
-- Demande du directeur du 01/11/2026 : « ca devrait etre une configuration
-- dans l'administration pour changer ce nombre ». Lot accorde par le pilote
-- le 01/11, avec ses precisions : le serveur refuse un ordre faux, en
-- exigence positive, en minutes depuis le debut de la seance.
--
-- Ce qui existait. 20261102500000_remplacement_auto.sql a pose les trois cles
-- de app_config, lues par private.remplacement_reglage (entier de 1 a 3
-- chiffres) :
--   remplacement.avertissement_minutes      (3)
--   remplacement.perte_acces_minutes        (8)
--   remplacement.debut_remplacant_minutes   (11)
-- et private.remplacement_auto_passer exige avertissement < perte < objectif
-- a chaque passage. Mais rien ne l'exigeait a l'ecriture : une direction qui
-- posait 12 pour la perte avec un objectif a 11 faisait echouer chaque passage
-- de la minute, sans que personne le voie, et plus aucun titulaire n'etait
-- remplace.
--
-- Ce lot. Pas de nouvelle table, pas de nouvelle RPC, pas de nouveau droit :
-- l'ecran Regles ecrit app_config comme pour « Classes au plus par
-- enseignant » (app_config_admin_update, direction active seule), et le
-- journal reste guard_app_config_history. Un declencheur valide AVANT lui
-- (l'ordre des declencheurs est alphabetique : app_config_delais_remplacement
-- precede app_config_history), sur le modele de app_config_classes_max
-- (20261022000200) :
--   - un entier de 0 a 999, ecrit en entier (8.0 devient 8) ;
--   - avertissement < perte < objectif, compare aux deux autres valeurs en
--     vigueur. Pour monter la perte au-dela de l'objectif, on releve d'abord
--     l'objectif ; pour descendre l'objectif sous la perte, on baisse d'abord
--     la perte. Le message dit l'ordre attendu et les valeurs en vigueur.
-- Mots de suppression dans ce fichier : aucun.

CREATE FUNCTION private.reglages_remplacement_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_n numeric;
  v_avert integer;
  v_perte integer;
  v_objectif integer;
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.key LIKE 'remplacement.%'
     AND NEW.key IS DISTINCT FROM OLD.key THEN
    RAISE EXCEPTION 'le reglage % garde son nom : seule sa valeur se change', OLD.key
      USING ERRCODE = '42501';
  END IF;
  IF NEW.key NOT IN ('remplacement.avertissement_minutes',
                     'remplacement.perte_acces_minutes',
                     'remplacement.debut_remplacant_minutes') THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number' THEN
    RAISE EXCEPTION 'delai de remplacement : un nombre entier de minutes, de 0 a 999, est attendu'
      USING ERRCODE = '22023';
  END IF;
  v_n := (NEW.value #>> '{}')::numeric;
  IF NOT coalesce(v_n = pg_catalog.trunc(v_n) AND v_n BETWEEN 0 AND 999, false) THEN
    RAISE EXCEPTION 'delai de remplacement : un nombre entier de minutes, de 0 a 999, est attendu'
      USING ERRCODE = '22023';
  END IF;
  NEW.value := pg_catalog.to_jsonb(v_n::integer);

  -- Les deux autres valeurs en vigueur ; celle qui change prend sa nouvelle
  -- valeur. Une cle encore absente (premier semis) ne contraint rien.
  SELECT max(CASE WHEN c.key = 'remplacement.avertissement_minutes' THEN (c.value #>> '{}')::integer END),
         max(CASE WHEN c.key = 'remplacement.perte_acces_minutes' THEN (c.value #>> '{}')::integer END),
         max(CASE WHEN c.key = 'remplacement.debut_remplacant_minutes' THEN (c.value #>> '{}')::integer END)
    INTO v_avert, v_perte, v_objectif
    FROM public.app_config c
   WHERE c.key IN ('remplacement.avertissement_minutes',
                   'remplacement.perte_acces_minutes',
                   'remplacement.debut_remplacant_minutes')
     AND c.key <> NEW.key
     AND pg_catalog.jsonb_typeof(c.value) = 'number'
     AND (c.value #>> '{}') ~ '^[0-9]{1,3}$';
  CASE NEW.key
    WHEN 'remplacement.avertissement_minutes' THEN v_avert := v_n::integer;
    WHEN 'remplacement.perte_acces_minutes' THEN v_perte := v_n::integer;
    ELSE v_objectif := v_n::integer;
  END CASE;

  IF v_avert IS NOT NULL AND v_perte IS NOT NULL AND v_avert >= v_perte THEN
    RAISE EXCEPTION 'delais de remplacement : l''avertissement doit venir avant la perte de la seance (avertissement % min, perte % min, depuis le debut de la seance)', v_avert, v_perte
      USING ERRCODE = '22023';
  END IF;
  IF v_perte IS NOT NULL AND v_objectif IS NOT NULL AND v_perte >= v_objectif THEN
    RAISE EXCEPTION 'delais de remplacement : la perte de la seance doit venir avant le remplacant dans la salle (perte % min, objectif % min, depuis le debut de la seance)', v_perte, v_objectif
      USING ERRCODE = '22023';
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.reglages_remplacement_valider() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.reglages_remplacement_valider()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.reglages_remplacement_valider() IS
  'REGLES-A3 : valide les delais remplacement.* (entier de 0 a 999, ecrit en entier ; '
  'avertissement < perte < objectif, compare aux valeurs en vigueur). Declencheur '
  'app_config_delais_remplacement, qui precede app_config_history (ordre alphabetique). '
  'Aucun EXECUTE client.';

CREATE TRIGGER app_config_delais_remplacement
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.reglages_remplacement_valider();

-- ---------------------------------------------------------------------------
-- Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_def text;
  v_avert integer;
  v_perte integer;
  v_objectif integer;
BEGIN
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.app_config'::regclass AND NOT t.tgisinternal
         AND t.tgname = 'app_config_delais_remplacement' AND t.tgenabled = 'O') <> 1
     OR 'app_config_delais_remplacement' COLLATE "C" >= 'app_config_history' COLLATE "C" THEN
    RAISE EXCEPTION 'REGLES-A3 : declencheur de validation absent ou apres le journal';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.app_config'::regclass AND NOT t.tgisinternal
                    AND t.tgname = 'app_config_history' AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'REGLES-A3 : le journal des reglages (app_config_history) est absent';
  END IF;
  v_def := pg_catalog.pg_get_triggerdef(
    (SELECT t.oid FROM pg_catalog.pg_trigger t
      WHERE t.tgrelid = 'public.app_config'::regclass AND t.tgname = 'app_config_delais_remplacement'));
  IF v_def NOT LIKE '%BEFORE INSERT OR UPDATE ON public.app_config%' THEN
    RAISE EXCEPTION 'REGLES-A3 : declencheur de validation mal pose : %', v_def;
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.reglages_remplacement_valider()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.reglages_remplacement_valider()', 'EXECUTE') THEN
    RAISE EXCEPTION 'REGLES-A3 : un client peut executer la fonction de validation';
  END IF;
  -- Les valeurs en vigueur respectent deja l'ordre (sinon A3 echouerait
  -- deja a chaque minute) : le lot ne pose rien, il le constate.
  v_avert := private.remplacement_reglage('remplacement.avertissement_minutes');
  v_perte := private.remplacement_reglage('remplacement.perte_acces_minutes');
  v_objectif := private.remplacement_reglage('remplacement.debut_remplacant_minutes');
  IF NOT (v_avert < v_perte AND v_perte < v_objectif) THEN
    RAISE EXCEPTION 'REGLES-A3 : delais en vigueur hors d''ordre : % / % / %', v_avert, v_perte, v_objectif;
  END IF;
END;
$postflight$;
