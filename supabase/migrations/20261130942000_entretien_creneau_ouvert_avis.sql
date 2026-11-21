-- PE-A7 COURRIELS-CANDIDAT (parcours de l'enseignant, plan du 19/11/2026 ; RETOURS-TERRAIN R22, « a construire »
-- depuis le 16/11/2026). NE PAS INSTALLER SANS DECISION DU DIRECTEUR.
--
-- LE PROBLEME : le courriel « retenu pour un entretien » et l'application disent au candidat « nous vous
-- ecrirons des que les moments d'entretien seront ouverts ; vous n'avez rien a faire ». Rien n'executait cette
-- promesse : ouvrir un creneau (ouvrir_creneau_entretien) n'ecrivait a personne (limite ecrite dans
-- 20261129440000_courriel_entretien.sql). 40 candidats « entretien a planifier » le 16/11.
--
-- LA REGLE (la plus prudente, demandee par le pilote apres relecture, 20/11/2026) :
--   * a l'ouverture d'un creneau, un candidat qui attend son entretien et pour qui CE creneau est choisissable
--     (regle exacte de l'application, creneaux_entretien_disponibles : candidature en cours, etape
--     verifications, etat entretien_a_planifier, pas en pause ; meme cote ; langue commune ; libre, non annule,
--     a plus de 30 minutes ; tenable) est prevenu SEULEMENT s'il n'avait AUCUN creneau choisissable avant
--     celui-ci (aucun autre creneau ouvert plus tot, libre, tenable et compatible). Dix creneaux ouverts d'un
--     coup : seul le premier compte ;
--   * au plus un avis par candidature sur 7 jours (un avis ecarte a l'envoi ne compte pas) ; aucun avis si le
--     courriel « retenu » des 7 derniers jours disait deja de choisir (creneauxOuverts vrai) ;
--   * l'avis reste DANS le plafond et l'etalement ordinaires des courriels non essentiels (categorie
--     recrutement) : aucune retouche de courriel_hors_plafond ;
--   * un avis encore en file est ECARTE a l'envoi (statut annule) si le candidat n'attend plus son entretien ou
--     n'a plus aucun creneau choisissable : public.courriel_avis_creneau_ecarter(uuid), appelee par
--     courriels-envoi (service_role seul) juste avant l'envoi de ce modele.
--   Le declencheur est un declencheur de contrainte DIFFERE a la fin de la transaction : ouvrir_creneau_entretien
--   insere le creneau PUIS ses participants ; la tenabilite n'est juste qu'une fois les participants poses.
--   ouvrir_creneau_entretien n'est pas retouchee. Un echec de l'avis n'empeche JAMAIS l'ouverture du creneau.
--
-- A DECIDER PAR LE DIRECTEUR : un seul creneau ouvert previent TOUS les candidats compatibles qui n'avaient rien
-- (100 candidats en attente => 100 courriels pour une seule place ; le premier qui choisit la prend, les autres
-- retrouvent « aucun moment ouvert »). Aucune limite par creneau n'est posee ici.
--
-- CE QUE CE FICHIER NE FAIT PAS : aucune notification dans l'application (cloche, appareil) : elle demanderait un
-- evenement neuf dans notifications_evenement_check (reecriture d'un CHECK) et son texte dans l'application.
--
-- MOTS D'EFFACEMENT : ZERO. Additif : trois fonctions neuves (deux privees, une porte du travailleur), un
-- declencheur neuf. Aucune donnee ecrite a l'installation. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.entretien_creneaux_ouverts_pour(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.entretien_creneau_tenable(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_langues(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_adresse_profil(uuid)') IS NULL THEN
    RAISE EXCEPTION 'PE-A7 : installer d''abord V1-b et COURRIEL-ENTRETIEN';
  END IF;
END
$preflight$;

-- ====================================================================================================================
-- 1. La candidature d'un compte qui attend son entretien (meme regle que candidature_a_planifier_du_candidat)
-- ====================================================================================================================
CREATE OR REPLACE FUNCTION private.candidature_a_planifier_de(p_profil uuid)
RETURNS public.candidatures
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT c.* FROM public.candidatures c
   WHERE c.profile_id = p_profil
     AND c.issue = 'en_cours' AND c.etape = 'verifications' AND c.etat = 'entretien_a_planifier'
     AND NOT c.en_pause
   ORDER BY c.recue_le DESC, c.id
   LIMIT 1;
$function$;
ALTER FUNCTION private.candidature_a_planifier_de(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_a_planifier_de(uuid) FROM PUBLIC, anon, authenticated, service_role;

-- ====================================================================================================================
-- 2. L'avis : un creneau vient de s'ouvrir
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
         -- Aucun creneau choisissable ouvert AVANT celui-ci (dix creneaux d'un coup : seul le premier compte).
         AND NOT EXISTS (
           SELECT 1 FROM public.entretien_creneaux k
            WHERE (k.ouvert_le, k.id) < (v_cr.ouvert_le, v_cr.id)
              AND k.cote = c.genre
              AND k.session_id IS NULL AND k.annule_le IS NULL
              AND k.debut > pg_catalog.now() + interval '30 minutes'
              AND k.langues && private.candidature_langues(c.id)
              AND private.entretien_creneau_tenable(k.id) IS NULL)
         -- Au plus un avis sur 7 jours (un avis ecarte a l'envoi ne compte pas).
         AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                          WHERE s.destinataire_profil = c.profile_id AND s.modele = 'entretien_creneau_ouvert'
                            AND s.statut <> 'annule'
                            AND s.cree_le > pg_catalog.now() - interval '7 days')
         -- Le courriel « retenu » recent disait deja de choisir.
         AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                          WHERE s.destinataire_profil = c.profile_id AND s.modele = 'retenu_entretien'
                            AND (s.donnees ->> 'creneauxOuverts') = 'true'
                            AND s.cree_le > pg_catalog.now() - interval '7 days')
    LOOP
      v_adresse := public.courriel_adresse_profil(v_c.profile_id);
      IF v_adresse IS NOT NULL THEN
        PERFORM public.courriel_enfiler(
          'recrutement', 'entretien_creneau_ouvert', v_adresse, v_c.profile_id,
          '{}'::jsonb,
          'entretien_creneau_ouvert:' || v_c.id::text || ':' || v_cr.id::text,
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
-- 3. A l'envoi : un avis devenu inutile est ecarte (porte du travailleur courriels-envoi, service_role seul)
-- ====================================================================================================================
CREATE OR REPLACE FUNCTION public.courriel_avis_creneau_ecarter(p_id uuid)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.courriels_sortants;
  v_c public.candidatures;
BEGIN
  SELECT s.* INTO v_s FROM public.courriels_sortants s
   WHERE s.id = p_id AND s.modele = 'entretien_creneau_ouvert' AND s.statut = 'envoi'
   FOR UPDATE;
  IF v_s.id IS NULL THEN
    RETURN false;
  END IF;
  v_c := private.candidature_a_planifier_de(v_s.destinataire_profil);
  IF v_c.id IS NOT NULL AND private.entretien_creneaux_ouverts_pour(v_c) THEN
    RETURN false;
  END IF;
  UPDATE public.courriels_sortants
     SET statut = 'annule',
         derniere_erreur = 'PE-A7 : ecarte a l''envoi, plus aucun creneau choisissable ou entretien deja fixe'
   WHERE id = p_id;
  RETURN true;
END;
$function$;
ALTER FUNCTION public.courriel_avis_creneau_ecarter(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.courriel_avis_creneau_ecarter(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.courriel_avis_creneau_ecarter(uuid) TO service_role;

DO $droits$
DECLARE
  v text;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    FOREACH v IN ARRAY ARRAY['private.candidature_a_planifier_de(uuid)', 'private.entretien_creneau_ouvert_prevenir()',
                             'public.courriel_avis_creneau_ecarter(uuid)'] LOOP
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', v);
    END LOOP;
  END IF;
END
$droits$;

-- ====================================================================================================================
-- Controle final
-- ====================================================================================================================
DO $postflight$
DECLARE
  v text;
BEGIN
  IF private.courriel_hors_plafond(false, 'entretien_creneau_ouvert') THEN
    RAISE EXCEPTION 'PE-A7 : l''avis ne doit pas passer hors plafond';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.entretien_creneaux'::pg_catalog.regclass
                    AND t.tgname = 'entretien_creneau_ouvert_avis' AND t.tgdeferrable AND t.tginitdeferred
                    AND t.tgfoid = 'private.entretien_creneau_ouvert_prevenir()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'PE-A7 : le declencheur differe manque';
  END IF;
  FOREACH v IN ARRAY ARRAY['private.candidature_a_planifier_de(uuid)', 'private.entretien_creneau_ouvert_prevenir()'] LOOP
    IF pg_catalog.has_function_privilege('anon', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PE-A7 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'public.courriel_avis_creneau_ecarter(uuid)'::pg_catalog.regprocedure AND p.prosecdef
                       AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
    RAISE EXCEPTION 'PE-A7 : droits ou definition inattendus pour la porte du travailleur';
  END IF;
END
$postflight$;
