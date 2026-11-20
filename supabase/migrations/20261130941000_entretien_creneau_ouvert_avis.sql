-- PE-A7 COURRIELS-CANDIDAT (parcours de l'enseignant, plan du 19/11/2026 ; RETOURS-TERRAIN R22, « a construire »
-- depuis le 16/11/2026).
--
-- LE PROBLEME : le courriel « retenu pour un entretien » et l'application disent au candidat « nous vous
-- ecrirons des que les moments d'entretien seront ouverts ; vous n'avez rien a faire ». Rien n'executait cette
-- promesse : ouvrir un creneau (ouvrir_creneau_entretien) n'ecrivait a personne (limite ecrite dans
-- 20261129440000_courriel_entretien.sql). 40 candidats « entretien a planifier » le 16/11.
--
-- CE QUE FAIT CE FICHIER (le circuit existant, aucun second circuit) :
--   1. A l'ouverture d'un creneau, chaque candidat qui attend son entretien et pour qui CE creneau est
--      choisissable recoit le courriel `entretien_creneau_ouvert` par la file des courriels (courriel_enfiler,
--      categorie recrutement, dans sa langue par le declencheur courriel_langue). « Choisissable » est la regle
--      exacte de l'application (creneaux_entretien_disponibles, reprise par entretien_creneaux_ouverts_pour) :
--      candidature en cours, etape verifications, etat entretien_a_planifier, pas en pause ; meme cote ;
--      langue commune ; libre, non annule, a plus de 30 minutes ; tenable (participants, fondateurs).
--   2. Le declencheur est un declencheur de contrainte DIFFERE a la fin de la transaction : ouvrir_creneau_entretien
--      insere le creneau PUIS ses participants ; la tenabilite n'est juste qu'une fois les participants poses.
--      ouvrir_creneau_entretien n'est pas retouchee.
--   3. Pas de pluie de courriels : au plus un avis par candidature sur 20 heures (ouvrir dix creneaux d'un coup
--      donne un seul courriel), et aucun avis si le courriel « retenu » de moins de 20 heures disait deja de
--      choisir (creneauxOuverts vrai). Cle d'idempotence : entretien_creneau_ouvert:<candidature>:<heure UTC>.
--   4. Un echec de l'avis n'empeche JAMAIS l'ouverture du creneau (sous-bloc, avertissement).
--   5. `entretien_creneau_ouvert` rejoint private.courriel_hors_plafond (retouche par ancre, comme
--      20261126100000) : un moment ouvert se prend vite, l'avis ne doit pas attendre derriere les envois en
--      nombre.
--
-- CE QUE CE FICHIER NE FAIT PAS : aucune notification dans l'application (cloche, appareil). Elle demanderait
-- un evenement neuf dans notifications_evenement_check (reecriture d'un CHECK, donc un mot d'effacement) et son
-- texte dans l'application (lib/, assets/i18n) : hors de ce lot, dit dans la PR. Le candidat retrouve le moment
-- dans l'application des qu'il l'ouvre (/attente/entretien).
--
-- MOTS D'EFFACEMENT : ZERO. Additif : une fonction privee neuve, un declencheur neuf, une fonction retouchee par
-- ancre (une fois ; proprietaire, droits et attributs gardes). Aucune donnee ecrite a l'installation. Sans BEGIN
-- ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.entretien_creneaux_ouverts_pour(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.entretien_creneau_tenable(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_langues(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.courriel_hors_plafond(boolean,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_adresse_profil(uuid)') IS NULL THEN
    RAISE EXCEPTION 'PE-A7 : installer d''abord V1-b, COURRIEL-ENTRETIEN et COURRIELS-RECRUTEMENT-HORS-PLAFOND';
  END IF;
END
$preflight$;

-- ====================================================================================================================
-- 1. L'avis : un creneau vient de s'ouvrir
-- ====================================================================================================================
CREATE OR REPLACE FUNCTION private.entretien_creneau_ouvert_prevenir()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cr public.entretien_creneaux;
  v_c record;
  v_adresse text;
BEGIN
  BEGIN
    -- L'etat a la fin de la transaction : le creneau a pu etre annule ou pris entre-temps.
    SELECT k.* INTO v_cr FROM public.entretien_creneaux k WHERE k.id = NEW.id;
    IF v_cr.id IS NULL OR v_cr.session_id IS NOT NULL OR v_cr.annule_le IS NOT NULL
       OR v_cr.debut <= pg_catalog.now() + interval '30 minutes'
       OR private.entretien_creneau_tenable(v_cr.id) IS NOT NULL THEN
      RETURN NULL;
    END IF;
    FOR v_c IN
      SELECT c.id, c.profile_id
        FROM public.candidatures c
       WHERE c.issue = 'en_cours' AND c.etape = 'verifications' AND c.etat = 'entretien_a_planifier'
         AND NOT c.en_pause AND c.genre = v_cr.cote AND c.profile_id IS NOT NULL
         AND v_cr.langues && private.candidature_langues(c.id)
         -- Au plus un avis sur 20 heures.
         AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                          WHERE s.destinataire_profil = c.profile_id AND s.modele = 'entretien_creneau_ouvert'
                            AND s.cle_idempotence LIKE 'entretien_creneau_ouvert:' || c.id::text || ':%'
                            AND s.cree_le > pg_catalog.now() - interval '20 hours')
         -- Le courriel « retenu » recent disait deja de choisir.
         AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                          WHERE s.destinataire_profil = c.profile_id AND s.modele = 'retenu_entretien'
                            AND (s.donnees ->> 'creneauxOuverts') = 'true'
                            AND s.cree_le > pg_catalog.now() - interval '20 hours')
    LOOP
      v_adresse := public.courriel_adresse_profil(v_c.profile_id);
      IF v_adresse IS NOT NULL THEN
        PERFORM public.courriel_enfiler(
          'recrutement', 'entretien_creneau_ouvert', v_adresse, v_c.profile_id,
          '{}'::jsonb,
          'entretien_creneau_ouvert:' || v_c.id::text || ':'
            || pg_catalog.to_char(pg_catalog.now() AT TIME ZONE 'UTC', 'YYYYMMDDHH24'),
          'auto', NULL);
      END IF;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PE-A7 : avis d''ouverture de creneau non pose (SQLSTATE %), creneau garde', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION private.entretien_creneau_ouvert_prevenir() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_creneau_ouvert_prevenir() FROM PUBLIC, anon, authenticated, service_role;
DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON FUNCTION private.entretien_creneau_ouvert_prevenir() FROM agent_ro;
  END IF;
END
$droits$;

DO $declencheur$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.entretien_creneaux'::pg_catalog.regclass
                    AND t.tgname = 'entretien_creneau_ouvert_avis') THEN
    CREATE CONSTRAINT TRIGGER entretien_creneau_ouvert_avis
      AFTER INSERT ON public.entretien_creneaux
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW EXECUTE FUNCTION private.entretien_creneau_ouvert_prevenir();
  END IF;
END
$declencheur$;

-- ====================================================================================================================
-- 2. Hors plafond (retouche par ancre, une fois)
-- ====================================================================================================================
DO $hors_plafond$
DECLARE
  v_f regprocedure := 'private.courriel_hors_plafond(boolean,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''message_candidat_recu'')';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, '''entretien_creneau_ouvert''') > 0 THEN
    RAISE NOTICE 'PE-A7 : hors plafond deja fait, rien ne change';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PE-A7 : ancre de courriel_hors_plafond trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''message_candidat_recu'',' || pg_catalog.chr(10)
    || '                       -- PE-A7 (20/11/2026) : un moment d''entretien vient de s''ouvrir.' || pg_catalog.chr(10)
    || '                       ''entretien_creneau_ouvert'')');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'PE-A7 : courriel_hors_plafond : proprietaire, droits ou attributs modifies';
  END IF;
END
$hors_plafond$;

-- ====================================================================================================================
-- Controle final
-- ====================================================================================================================
DO $postflight$
BEGIN
  IF NOT private.courriel_hors_plafond(false, 'entretien_creneau_ouvert')
     OR NOT private.courriel_hors_plafond(false, 'message_candidat_recu')
     OR private.courriel_hors_plafond(false, 'lien_inscription') THEN
    RAISE EXCEPTION 'PE-A7 : courriel_hors_plafond ne rend pas ce qui est attendu';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.entretien_creneaux'::pg_catalog.regclass
                    AND t.tgname = 'entretien_creneau_ouvert_avis' AND t.tgdeferrable AND t.tginitdeferred
                    AND t.tgfoid = 'private.entretien_creneau_ouvert_prevenir()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'PE-A7 : le declencheur differe manque';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'private.entretien_creneau_ouvert_prevenir()'::pg_catalog.regprocedure AND p.prosecdef
                       AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
    RAISE EXCEPTION 'PE-A7 : droits ou definition inattendus pour l''avis';
  END IF;
END
$postflight$;
