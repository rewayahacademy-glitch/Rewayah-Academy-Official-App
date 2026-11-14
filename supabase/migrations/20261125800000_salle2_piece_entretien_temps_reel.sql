-- SALLE2-ENTRETIEN (14/11/2026) : retours du directeur en production sur la
-- salle 2 du recrutement des enseignants (PLAN-TROIS-SALLES-2026-11-07).
--
-- 1. decider_dossier : la direction valide la piece d'un candidat en salle 2.
--    Constat en production le 14/11 (13:14-13:17 UTC, quatre essais) : la
--    validation de la piece de Sam Tester (candidature enseignant a l'etape
--    `verifications`, compte `pending_kyc`) rendait 400. Journal Postgres :
--    `compte_candidat_actif_avant_salle_3`. decider_dossier approuvait la
--    piece PUIS passait le compte a `active` ; le declencheur CAND-L1B
--    (20261021220000) refuse un compte actif avant la Salle des prets a
--    enseigner, et toute la transaction etait annulee : la piece n'etait pas
--    validee non plus.
--    Correction : pour un compte qui a une candidature en cours avant la
--    salle 3, la piece est approuvee et le compte RESTE `pending_kyc`. Son
--    ouverture reste celle de la salle 3 (valider_piece_candidat, qui accepte
--    une piece deja approuvee). La regle CAND-L1B ne change pas. Sans
--    candidature, rien ne change (approbation puis activation).
-- 2. mon_entretien : l'etat de l'entretien est fourni par le serveur
--    (`etat` : a_venir, proche, ouvert, en_cours, termine ; `serveurLe`,
--    l'heure du serveur, pour un decompte juste quelle que soit l'horloge de
--    l'appareil). Les champs d'avant restent.
-- 3. ouvrir_plage_entretien : la direction publie une plage (debut, fin,
--    duree d'un entretien) ; le serveur la decoupe en creneaux par
--    ouvrir_creneau_entretien, tout ou rien. Le candidat choisit ensuite
--    lui-meme (reserver_creneau_entretien, verrou FOR UPDATE existant : un
--    creneau pris disparait pour les autres).
-- 4. Temps reel : apres tout changement de creneau ou d'entretien, un signal
--    sans contenu est diffuse sur le canal public `entretiens`
--    (realtime.send). Le client relit alors ses listes par les RPC, qui
--    gardent leurs gardes : le signal ne porte aucune donnee. Sans le schema
--    realtime (CI sur Postgres nu), le signal ne fait rien. Un echec du
--    signal n'annule jamais la transaction.
--
-- Preflight : decider_dossier et mon_entretien de production ont l'empreinte
-- du depot (md5 01e53ff2ca89301b14947ea260c6212a et f7d208131a431bf1e9b3b3a43edc15cf,
-- relus le 14/11/2026 en lecture seule).
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

DO $preflight$
DECLARE
  v_dec text := pg_catalog.md5(pg_catalog.pg_get_functiondef('public.decider_dossier(uuid,boolean,text)'::regprocedure));
  v_mon text := pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mon_entretien()'::regprocedure));
BEGIN
  IF pg_catalog.to_regprocedure('public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[])') IS NOT NULL THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : deja installee';
  END IF;
  IF v_dec <> '01e53ff2ca89301b14947ea260c6212a' THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : decider_dossier a change depuis le depot (md5 %)', v_dec;
  END IF;
  IF v_mon <> 'f7d208131a431bf1e9b3b3a43edc15cf' THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : mon_entretien a change depuis le depot (md5 %)', v_mon;
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. decider_dossier
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decider_dossier(
  p_document_id uuid,
  p_approuve boolean,
  p_motif text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_doc public.kyc_documents;
  v_acces_retire boolean;
  v_candidat_avant_salle3 boolean;
  v_n integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur decide d''un dossier';
  END IF;

  IF NOT p_approuve AND coalesce(btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'un refus exige un motif';
  END IF;

  SELECT * INTO v_doc FROM public.read_kyc_documents() k WHERE k.id = p_document_id;
  IF v_doc.id IS NULL THEN
    RAISE EXCEPTION 'dossier introuvable ou hors du perimetre de lecture';
  END IF;

  IF v_doc.status <> 'pending' THEN
    RAISE EXCEPTION 'dossier déjà décidé' USING ERRCODE = 'check_violation';
  END IF;

  -- SALLE2-ENTRETIEN : un candidat avant la salle 3 garde un compte
  -- pending_kyc (CAND-L1B) ; sa piece est validee seule.
  v_candidat_avant_salle3 := EXISTS (
    SELECT 1 FROM public.candidatures c
     WHERE c.profile_id = v_doc.profile_id AND c.issue = 'en_cours' AND c.etape <> 'confirmee');

  UPDATE public.kyc_documents
  SET status = CASE WHEN p_approuve THEN 'approved'::public.kyc_doc_status
                    ELSE 'rejected'::public.kyc_doc_status END,
      rejection_reason = CASE WHEN p_approuve THEN NULL ELSE btrim(p_motif) END,
      verified_by = auth.uid(),
      verified_at = now()
  WHERE id = p_document_id;

  v_acces_retire := false;
  IF p_approuve AND NOT v_candidat_avant_salle3 THEN
    UPDATE public.profiles
    SET account_status = 'active', updated_at = now()
    WHERE id = v_doc.profile_id AND account_status = 'pending_kyc';
  ELSIF NOT p_approuve
    AND EXISTS (SELECT 1 FROM public.teacher_profiles tp WHERE tp.profile_id = v_doc.profile_id)
    AND NOT EXISTS (
      SELECT 1 FROM public.kyc_documents k
       WHERE k.profile_id = v_doc.profile_id AND k.id <> p_document_id AND k.status = 'approved'
    ) THEN
    UPDATE public.profiles
    SET account_status = 'disabled', updated_at = now()
    WHERE id = v_doc.profile_id AND account_status IN ('active', 'provisional_active');
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_acces_retire := v_n > 0;
  END IF;

  UPDATE public.teacher_profiles
  SET kyc_status = CASE WHEN p_approuve THEN 'approved' ELSE 'rejected' END
  WHERE profile_id = v_doc.profile_id;

  PERFORM public.log_sensitive_access('kyc_decision', 'kyc_documents', p_document_id::text,
    jsonb_build_object('approuve', p_approuve, 'motif', btrim(coalesce(p_motif, '')),
                       'acces_retire', v_acces_retire,
                       'candidat_avant_salle3', v_candidat_avant_salle3));
END;
$function$;
ALTER FUNCTION public.decider_dossier(uuid,boolean,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.decider_dossier(uuid,boolean,text) FROM PUBLIC, anon, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.decider_dossier(uuid,boolean,text) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.decider_dossier(uuid,boolean,text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. mon_entretien : l'etat fourni par le serveur
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mon_entretien()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r record;
  v_maintenant timestamptz := pg_catalog.now();
  v_etat text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'entretien reserve a un candidat connecte' USING ERRCODE = '42501';
  END IF;
  SELECT e.session_id, s.started_at, s.ended_at, s.join_opens_at, s.status::text AS statut
    INTO v_r
    FROM public.entretiens e
    JOIN public.sessions s ON s.id = e.session_id
   WHERE e.candidat_id = auth.uid() AND e.issue IS NULL AND s.deleted_at IS NULL
   ORDER BY s.started_at
   LIMIT 1;
  IF v_r.session_id IS NULL THEN
    RETURN NULL;
  END IF;
  -- proche : dans l'heure qui precede l'ouverture ; ouvert : des l'ouverture
  -- (10 minutes avant) ; en_cours : du debut a la fin ; termine : apres.
  v_etat := CASE
    WHEN v_maintenant >= v_r.ended_at THEN 'termine'
    WHEN v_maintenant >= v_r.started_at THEN 'en_cours'
    WHEN v_maintenant >= coalesce(v_r.join_opens_at, v_r.started_at - interval '10 minutes') THEN 'ouvert'
    WHEN v_maintenant >= v_r.started_at - interval '1 hour' THEN 'proche'
    ELSE 'a_venir'
  END;
  RETURN pg_catalog.jsonb_build_object('sessionId', v_r.session_id, 'debut', v_r.started_at,
    'fin', v_r.ended_at, 'ouvertureLe', v_r.join_opens_at, 'statut', v_r.statut,
    'etat', v_etat, 'serveurLe', v_maintenant);
END;
$function$;
REVOKE ALL ON FUNCTION public.mon_entretien() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mon_entretien() TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. ouvrir_plage_entretien : une plage decoupee en creneaux, tout ou rien
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.ouvrir_plage_entretien(
  p_cote public.gender,
  p_debut timestamptz,
  p_fin timestamptz,
  p_duree_minutes integer,
  p_langues text[],
  p_participants uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_t timestamptz;
  v_r jsonb;
  v_ids jsonb := '[]'::jsonb;
  v_refus jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'creneaux d''entretien reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_cote IS NULL OR p_debut IS NULL OR p_fin IS NULL OR p_duree_minutes IS NULL THEN
    RAISE EXCEPTION 'plage : cote, debut, fin et duree attendus' USING ERRCODE = '22023';
  END IF;
  IF p_duree_minutes NOT BETWEEN 15 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'duree_invalide');
  END IF;
  IF NOT pg_catalog.isfinite(p_fin)
     OR p_fin < p_debut + pg_catalog.make_interval(mins => p_duree_minutes) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'plage_trop_courte');
  END IF;
  IF p_fin > p_debut + interval '12 hours' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'plage_trop_longue');
  END IF;
  BEGIN
    v_t := p_debut;
    WHILE v_t + pg_catalog.make_interval(mins => p_duree_minutes) <= p_fin LOOP
      v_r := public.ouvrir_creneau_entretien(p_cote, v_t, p_duree_minutes, p_langues, p_participants);
      IF v_r ? 'erreur' THEN
        v_refus := v_r || pg_catalog.jsonb_build_object('creneau', v_t);
        RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'salle2_plage_refusee';
      END IF;
      v_ids := v_ids || pg_catalog.jsonb_build_array(v_r -> 'creneauId');
      v_t := v_t + pg_catalog.make_interval(mins => p_duree_minutes);
    END LOOP;
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'salle2_plage_refusee' THEN
      -- Le sous-bloc est annule : aucun creneau de la plage ne reste.
      RETURN v_refus;
    END IF;
    RAISE;
  END;
  RETURN pg_catalog.jsonb_build_object('creneaux', v_ids,
    'nombre', pg_catalog.jsonb_array_length(v_ids));
END;
$function$;
ALTER FUNCTION public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[]) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[]) FROM PUBLIC, anon, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[]) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[]) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. Le signal temps reel, sans contenu
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.entretiens_signal_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF pg_catalog.to_regprocedure('realtime.send(jsonb,text,text,boolean)') IS NOT NULL THEN
    BEGIN
      EXECUTE 'SELECT realtime.send($1, $2, $3, $4)'
        USING '{}'::jsonb, 'change', 'entretiens', false;
    EXCEPTION WHEN OTHERS THEN
      -- Le signal est un confort : il n'annule jamais la transaction.
      NULL;
    END;
  END IF;
  RETURN NULL;
END;
$function$;
REVOKE ALL ON FUNCTION private.entretiens_signal_trg() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER entretien_creneaux_signal
  AFTER INSERT OR UPDATE ON public.entretien_creneaux
  FOR EACH STATEMENT EXECUTE FUNCTION private.entretiens_signal_trg();
CREATE TRIGGER entretiens_signal
  AFTER INSERT OR UPDATE ON public.entretiens
  FOR EACH STATEMENT EXECUTE FUNCTION private.entretiens_signal_trg();

-- ---------------------------------------------------------------------------
-- 5. Empreintes F86 et verification finale
-- ---------------------------------------------------------------------------
DO $empreintes$
DECLARE
  f regprocedure;
BEGIN
  f := 'public.decider_dossier(uuid,boolean,text)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.decider_dossier(uuid,boolean,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-14; '
    || 'L1-05: une seule decision, acces retire au rejet d un enseignant sans autre piece approuvee. '
    || 'SALLE2-ENTRETIEN: un candidat avant la salle 3 a sa piece approuvee, compte laisse pending_kyc (CAND-L1B).');
  f := 'public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[])'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[]); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-14. '
    || 'SALLE2-ENTRETIEN : une plage publiee par la direction, decoupee en creneaux par ouvrir_creneau_entretien, tout ou rien. '
    || 'Must-pass: supabase/tests/scenarios_v1b_creneaux.sql (partie SALLE2-ENTRETIEN).');
END;
$empreintes$;

DO $postflight$
DECLARE
  v_dec text := pg_catalog.pg_get_functiondef('public.decider_dossier(uuid,boolean,text)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_dec, 'dossier déjà décidé') = 0
     OR pg_catalog.strpos(v_dec, 'v_candidat_avant_salle3') = 0
     OR pg_catalog.strpos(pg_catalog.upper(v_dec), 'NOT COALESCE') = 0 THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : decider_dossier inattendu';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.mon_entretien()'::regprocedure), '''etat''') = 0 THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : mon_entretien sans etat';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.decider_dossier(uuid,boolean,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.mon_entretien()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.entretiens_signal_trg()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : droits d''execution inattendus';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.decider_dossier(uuid,boolean,text)'::regprocedure,
                              'public.mon_entretien()'::regprocedure,
                              'public.ouvrir_plage_entretien(public.gender,timestamptz,timestamptz,integer,text[],uuid[])'::regprocedure,
                              'private.entretiens_signal_trg()'::regprocedure)
                AND (NOT p.prosecdef OR NOT coalesce(p.proconfig @> ARRAY['search_path=""'], false))) THEN
    RAISE EXCEPTION 'SALLE2-ENTRETIEN : SECURITY DEFINER et search_path vide attendus';
  END IF;
END;
$postflight$;
