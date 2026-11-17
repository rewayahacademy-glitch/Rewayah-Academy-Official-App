-- BE-1h ENTRETIEN-SUIT-LE-DOSSIER (pilote, 16/11/2026 ; carte des gestes, trou T11, lot 5) :
-- refuser, retirer ou mettre en pause une candidature laissait son entretien planifie en place, et une pause
-- interdisait ensuite de le consigner.
--
-- FICHIER SANS EFFACEMENT DE DONNEES : rien n'est supprime. Additif : deux fonctions, un declencheur.
-- Une seule ecriture sur des donnees de personnes, le rattrapage de la section 3, qui ne touche que des lignes
-- incoherentes (un entretien ouvert sur un dossier ferme ou en pause) ; la carte en compte 0 en production le
-- 16/11/2026. Sans BEGIN/COMMIT de premier niveau.
--
-- La regle : des qu'une candidature quitte `en_cours` (refusee, retiree) ou entre en pause, son entretien OUVERT
-- (issue NULL) est annule, comme le fait la dispense (20261129470000) pour un entretien planifie :
--   * l'entretien prend l'issue `annule`, la seance passe a `canceled` (rien n'est efface, le creneau reste lie) ;
--   * si le dossier etait `entretien_planifie`, il revient a `entretien_a_planifier` (le meme retour que la
--     transition 12, entretien non tenu), pour qu'aucun dossier ne porte « entretien planifie » sans entretien ;
--   * l'evenement du dossier (type entretien) garde la trace, avec le geste qui l'a causee.
-- Un declencheur BEFORE sur `candidatures` couvre les trois gestes de la direction ET le retrait fait par la
-- personne elle-meme, sans copier la regle dans chaque fonction. Ce qui n'y est PAS : prevenir l'intervieweur. Une
-- notification demande un nouvel evenement dans `notifications_evenement_check`, dont la liste de production
-- differe du depot (`annonce_direction`, voir 20261129600000) : la reecrire d'ici ferait disparaitre un
-- evenement de production. A faire dans une migration a part, avec la liste entiere de la production.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.entretiens') IS NULL OR pg_catalog.to_regclass('public.candidatures') IS NULL THEN
    RAISE EXCEPTION 'ENTRETIEN-SUIT-LE-DOSSIER : dependances absentes (entretiens, candidatures)';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
              WHERE t.tgrelid = 'public.candidatures'::regclass AND t.tgname = 'candidatures_entretien_suit') THEN
    RAISE EXCEPTION 'ENTRETIEN-SUIT-LE-DOSSIER : deja installee';
  END IF;
END
$preflight$;

-- ============================================================
-- 1. Annuler l'entretien ouvert d'une candidature (le coeur, partage avec le rattrapage)
-- ============================================================
-- Rend la seance annulee, ou NULL quand la candidature n'avait aucun entretien ouvert. [p_par] est la personne
-- qui a fait le geste ; sans elle, la personne qui avait planifie l'entretien (consigne_par est obligatoire).
CREATE FUNCTION private.entretien_annuler_pour_dossier(p_candidature uuid, p_par uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_e public.entretiens;
BEGIN
  SELECT e.* INTO v_e
    FROM public.entretiens e
   WHERE e.candidature_id = p_candidature AND e.issue IS NULL
   FOR UPDATE;
  IF v_e.session_id IS NULL THEN
    RETURN NULL;
  END IF;
  UPDATE public.entretiens
     SET issue = 'annule',
         consigne_par = coalesce(p_par, v_e.planifie_par),
         consigne_le = pg_catalog.clock_timestamp()
   WHERE session_id = v_e.session_id;
  UPDATE public.sessions SET status = 'canceled' WHERE id = v_e.session_id AND status = 'planned';
  RETURN v_e.session_id;
END;
$function$;
ALTER FUNCTION private.entretien_annuler_pour_dossier(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_annuler_pour_dossier(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 2. Le declencheur : refus, retrait ou pause
-- ============================================================
CREATE FUNCTION private.candidatures_entretien_suit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_session uuid;
  v_cause text;
BEGIN
  v_cause := CASE
    WHEN NEW.issue = 'refusee' AND OLD.issue IS DISTINCT FROM 'refusee' THEN 'refus'
    WHEN NEW.issue = 'retiree' AND OLD.issue IS DISTINCT FROM 'retiree' THEN 'retrait'
    WHEN NEW.en_pause AND NOT OLD.en_pause THEN 'pause'
  END;
  IF v_cause IS NULL THEN
    RETURN NEW;
  END IF;
  v_session := private.entretien_annuler_pour_dossier(NEW.id, auth.uid());
  IF v_session IS NULL THEN
    RETURN NEW;
  END IF;
  -- Un dossier « entretien planifie » sans entretien serait faux : retour a planifier.
  IF NEW.etape = 'verifications' AND NEW.etat = 'entretien_planifie' THEN
    NEW.etat := 'entretien_a_planifier';
  END IF;
  INSERT INTO public.candidature_evenements
    (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, issue_avant, issue_apres, auteur_id, details)
  VALUES
    (NEW.id, 'entretien', OLD.etape, NEW.etape, OLD.etat, NEW.etat, OLD.issue, NEW.issue, auth.uid(),
     pg_catalog.jsonb_build_object('entretienAnnule', true, 'cause', v_cause, 'sessionAnnulee', v_session,
                                   'suitLeDossier', true));
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.candidatures_entretien_suit() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidatures_entretien_suit() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER candidatures_entretien_suit
  BEFORE UPDATE OF issue, en_pause ON public.candidatures
  FOR EACH ROW
  WHEN ((NEW.issue IS DISTINCT FROM OLD.issue AND NEW.issue <> 'en_cours')
        OR (NEW.en_pause AND NOT OLD.en_pause))
  EXECUTE FUNCTION private.candidatures_entretien_suit();

-- ============================================================
-- 3. Le rattrapage des cas existants (0 en production le 16/11/2026, d'apres la carte des gestes)
-- ============================================================
-- Un dossier ferme ou en pause qui garde un entretien ouvert : l'entretien est annule et le dossier « entretien
-- planifie » revient a « entretien a planifier ». Le nombre de lignes touchees est dit dans le journal de
-- l'installation.
DO $rattrapage$
DECLARE
  v_c record;
  v_n integer := 0;
BEGIN
  FOR v_c IN
    SELECT c.id
      FROM public.candidatures c
     WHERE (c.issue <> 'en_cours' OR c.en_pause)
       AND EXISTS (SELECT 1 FROM public.entretiens e WHERE e.candidature_id = c.id AND e.issue IS NULL)
  LOOP
    PERFORM private.entretien_annuler_pour_dossier(v_c.id, NULL);
    UPDATE public.candidatures
       SET etat = 'entretien_a_planifier', version = version + 1
     WHERE id = v_c.id AND etape = 'verifications' AND etat = 'entretien_planifie';
    v_n := v_n + 1;
  END LOOP;
  RAISE NOTICE 'ENTRETIEN-SUIT-LE-DOSSIER : % entretien(s) ouvert(s) annule(s) par le rattrapage', v_n;
END
$rattrapage$;
