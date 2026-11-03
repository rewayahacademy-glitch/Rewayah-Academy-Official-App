-- Salle 3 (03/11/2026), partie serveur : de la Salle de verification et
-- d'entretien a la Salle des prets a enseigner (« Bienvenue dans l'equipe »
-- cote candidate), par le geste de la direction « Valider la piece »
-- (transition 14, spec consolidee des candidatures, sections 2.2 et 5 ;
-- decision CAND-Q01 du 21/10/2026).
--
-- Constat de depart (PR 191, captures trois-salles du 03/11) : la regle de
-- geste `valider_piece` existait (cand_l2a1), aucune fonction ne l'executait ;
-- `capacites_candidatures` rendait `validerPiece: false` ; et
-- `decider_dossier`, seul chemin vers `active`, echoue pour une candidate (le
-- declencheur L1B refuse un compte actif avant la salle 3). Une candidate
-- enseignante ne pouvait donc pas entrer en salle 3.
--
-- Ce fichier :
--   1. `private.candidature_entretien_controles` : `entretien_conclu` et
--      `evaluation_validee`, isoles dans une seule fonction que le lot de
--      l'entretien (V1) remplacera par un CREATE OR REPLACE. Tant qu'aucun
--      entretien n'existe en base, les deux sont faux, cause
--      « entretien_non_disponible » (voie (a), CAND-Q01 : la salle 3 reste
--      fermee tant que l'entretien n'est pas conclu).
--   2. `private.candidature_controles_salle3` : les sept controles exiges en
--      plus de la piece (section 5), {nom, valeur, cause}.
--   3. `public.valider_piece_candidat` : le geste, par le moteur des
--      candidatures (garde de la direction, cote femmes/hommes CAND-Q07,
--      idempotence, version). En UNE transaction : piece approuvee, langues
--      et fuseau copies dans `teacher_profiles`, disponibilites copiees dans
--      `weekly_availability`, candidature `confirmee`, puis compte `active`
--      (sous la garde d'activation et le declencheur L1B). Un controle faux,
--      une piece absente : rien n'est ecrit, les causes sont nommees.
--   4. `capacites_candidatures` : `validerPiece` suit `peutDecider`
--      (remplacement par ancre, rien d'autre ne change).
--   5. `public.affectation_candidat` : lecture de la direction, de son
--      cote : affectable ou non (causes), et les Classes de l'enseignante.
--      L'action d'affecter reste `affecter_enseignant_classe_c11bis`.
--
-- Rien ne change a l'ecran : les ecrans (/attente, geste « Valider la
-- piece », bloc « Affectation ») sont un lot lib/ a part.
-- Preflight du 03/11/2026 : les definitions de production de
-- capacites_candidatures, candidature_geste_ouvrir, candidature_geste_appliquer,
-- candidature_geste_conclure, decider_dossier, cand_lecteur,
-- candidature_compte_conforme, guard_teacher_activation_signatures,
-- paiement_etat, candidature_questionnaire_envoye, lire_candidature,
-- etat_dossier et admettre_salle_verification ont la meme empreinte md5 que
-- celles du depot (main 8b8c0a31).
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

-- ---------------------------------------------------------------------------
-- 1. L'entretien : une seule fonction, qui lit le lot V1 des qu'il existe.
-- ---------------------------------------------------------------------------
-- Accord avec Fin de seance (03/11/2026, lot V1-a, migrations 20261108000000
-- et 20261108000001) : V1-a pose `private.entretien_conclusion(uuid)`, qui
-- rend {tenu, avisFavorable, constatComplet, constat, sessionId} sur le
-- dernier entretien consigne « tenu ». Correspondance :
--   entretien_conclu   = tenu ET avisFavorable ;
--   evaluation_validee = constatComplet (memorisation observee, au moins une
--                        riwaya, ijaza renseignees).
-- Tant que cette fonction n'existe pas, les deux sont faux, cause
-- « entretien_non_disponible » (CAND-Q01, la salle 3 reste fermee). L'appel
-- est dynamique : cette migration s'applique avant ou apres V1-a, sans
-- CREATE OR REPLACE a venir.
CREATE FUNCTION private.candidature_entretien_controles(p_candidature uuid)
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
  v_constat boolean;
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
  v_constat := coalesce((v_conclusion ->> 'constatComplet')::boolean, false);
  RETURN pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('nom', 'entretien_conclu', 'valeur', v_tenu AND v_favorable,
      'cause', CASE WHEN NOT v_tenu THEN 'entretien_non_tenu'
                    WHEN NOT v_favorable THEN 'avis_non_favorable' END),
    pg_catalog.jsonb_build_object('nom', 'evaluation_validee', 'valeur', v_tenu AND v_constat,
      'cause', CASE WHEN NOT v_tenu THEN 'entretien_non_tenu'
                    WHEN NOT v_constat THEN 'constat_incomplet' END));
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
COMMENT ON FUNCTION private.candidature_entretien_controles(uuid) IS
  'Salle 3 (03/11/2026) : entretien_conclu et evaluation_validee, {nom, valeur, cause}, lus dans private.entretien_conclusion(uuid) du lot V1-a ; sans elle, faux, cause entretien_non_disponible.';

-- ---------------------------------------------------------------------------
-- 2. Les sept controles exiges en plus de la piece (section 5).
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.candidature_controles_salle3(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_resultat jsonb := '[]'::jsonb;
  v_paiement text;
  v_quest text;
  v_accords text;
  v_unique text;
  v_p public.profiles;
  v_nda_version text;
  v_nda_hash text;
BEGIN
  -- paiement_compatible : un moyen confirme croise le referentiel.
  v_paiement := private.paiement_etat(c.id);
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'paiement_compatible', 'valeur', v_paiement = 'compatible',
    'cause', CASE WHEN v_paiement IS DISTINCT FROM 'compatible' THEN v_paiement END));

  -- accords_signes : contrat (texte courant et son empreinte), avis, code de
  -- conduite et cadre religieux, aux versions requises. La cause nomme le
  -- premier accord manquant.
  SELECT t.version, t.sha256 INTO v_nda_version, v_nda_hash
    FROM public.contract_texts t
   WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
  v_accords := CASE
    WHEN c.profile_id IS NULL THEN 'compte_absent'
    WHEN v_nda_version IS NULL OR NOT EXISTS (
           SELECT 1 FROM public.contract_acceptances a
            WHERE a.profile_id = c.profile_id AND a.contract_kind = 'teacher_nda'
              AND a.version = v_nda_version AND a.signed_sha256 = v_nda_hash) THEN 'teacher_nda'
    WHEN NOT EXISTS (
           SELECT 1 FROM public.contract_required_versions r
             JOIN public.contract_acceptances a
               ON a.contract_kind = r.contract_kind AND a.version = r.version
            WHERE r.contract_kind = 'recording_and_control_notice' AND a.profile_id = c.profile_id)
      THEN 'recording_and_control_notice'
    WHEN NOT EXISTS (
           SELECT 1 FROM public.contract_required_versions r
             JOIN public.contract_acceptances a
               ON a.contract_kind = r.contract_kind AND a.version = r.version
            WHERE r.contract_kind = 'teacher_conduct_code' AND a.profile_id = c.profile_id)
      THEN 'teacher_conduct_code'
    WHEN public.cadre_religieux_version_requise() IS NULL OR NOT EXISTS (
           SELECT 1 FROM public.contract_acceptances a
            WHERE a.profile_id = c.profile_id AND a.contract_kind = 'teacher_religious_framework'
              AND a.version = public.cadre_religieux_version_requise())
      THEN 'teacher_religious_framework'
  END;
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'accords_signes', 'valeur', v_accords IS NULL, 'cause', v_accords));

  -- profil_renseigne : le questionnaire envoye et complet (langues
  -- d'explication, niveau, publics, fuseau, disponibilites : tous requis).
  v_quest := private.candidature_questionnaire_envoye(c);
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'profil_renseigne', 'valeur', v_quest = 'complet',
    'cause', CASE WHEN v_quest IS DISTINCT FROM 'complet' THEN v_quest END));

  -- entretien_conclu, evaluation_validee : la fonction isolee (1).
  v_resultat := v_resultat || private.candidature_entretien_controles(c.id);

  -- profil_unique : un seul compte, du role du type, encore en attente, de
  -- genre connu, sans autre candidature enseignante en cours.
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = c.profile_id;
  v_unique := CASE
    WHEN v_p.id IS NULL OR v_p.deleted_at IS NOT NULL THEN 'compte_absent'
    WHEN v_p.role IS DISTINCT FROM 'teacher'::public.app_role THEN 'role'
    WHEN v_p.account_status IS DISTINCT FROM 'pending_kyc'::public.account_status THEN 'statut'
    WHEN v_p.gender IS NULL THEN 'genre_inconnu'
    WHEN NOT EXISTS (SELECT 1 FROM public.teacher_profiles tp
                      WHERE tp.profile_id = v_p.id AND tp.deleted_at IS NULL) THEN 'profil_enseignant_absent'
    WHEN EXISTS (SELECT 1 FROM public.candidatures o
                  WHERE o.profile_id = c.profile_id AND o.id <> c.id
                    AND o.type_code = c.type_code AND o.issue = 'en_cours') THEN 'autre_candidature'
  END;
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'profil_unique', 'valeur', v_unique IS NULL, 'cause', v_unique));

  -- aucune_restriction : ni pause ni restriction.
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'aucune_restriction', 'valeur', NOT (c.en_pause OR coalesce(c.restreinte, false)),
    'cause', CASE WHEN c.en_pause THEN 'pause'
                  WHEN coalesce(c.restreinte, false) THEN 'restriction' END));
  RETURN v_resultat;
END;
$function$;
REVOKE ALL ON FUNCTION private.candidature_controles_salle3(public.candidatures) FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.candidature_controles_salle3(public.candidatures) FROM agent_ro';
  END IF;
END;
$agent_ro$;
COMMENT ON FUNCTION private.candidature_controles_salle3(public.candidatures) IS
  'Salle 3 (03/11/2026) : les sept controles exiges avec la piece (spec section 5), {nom, valeur, cause} ; lus par valider_piece_candidat.';

-- ---------------------------------------------------------------------------
-- 3. Le geste « Valider la piece » (transition 14).
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.valider_piece_candidat(p_id uuid, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_o jsonb;
  v_c public.candidatures;
  v_controles jsonb;
  v_faux jsonb;
  v_doc public.kyc_documents;
  v_rep jsonb;
  v_langues text[];
  v_fuseau text;
  v_n integer;
  v_heures integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  -- Le moteur : direction active de genre connu, du cote de la candidature
  -- (sinon hors_portee, trace), idempotence, version, regle (verifications,
  -- decision_en_attente, en cours, hors pause).
  v_o := private.candidature_geste_ouvrir(p_id, 'valider_piece', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'type_non_admis');
  END IF;

  v_controles := private.candidature_controles_salle3(v_c);
  v_faux := private.candidature_controles_faux(v_controles);
  IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits', 'controles', v_faux);
  END IF;

  -- La piece : la plus recente, deposee et non effacee ; deja approuvee, elle
  -- vaut ; en attente, ce geste la decide.
  SELECT k.* INTO v_doc FROM public.kyc_documents k
   WHERE k.profile_id = v_c.profile_id AND k.deleted_at IS NULL
   ORDER BY k.created_at DESC, k.id DESC LIMIT 1;
  IF v_doc.id IS NULL OR v_doc.status NOT IN ('pending'::public.kyc_doc_status,
                                              'approved'::public.kyc_doc_status) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits',
      'controles', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nom', 'piece_validee',
        'cause', CASE WHEN v_doc.id IS NULL THEN 'absente' ELSE v_doc.status::text END)));
  END IF;

  -- Les reponses envoyees : langues d'explication (codes), fuseau IANA,
  -- disponibilites (plages par jour ISO, heures entieres, sans fuseau).
  SELECT r.reponses INTO v_rep FROM public.candidature_reponses r
   WHERE r.candidature_id = v_c.id
   ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1;
  SELECT pg_catalog.array_agg(x ORDER BY o) INTO v_langues
    FROM pg_catalog.jsonb_array_elements_text(coalesce(v_rep -> 'languesExplication', '[]'::jsonb))
         WITH ORDINALITY AS l(x, o);
  v_fuseau := v_rep ->> 'fuseauIana';
  IF coalesce(pg_catalog.cardinality(v_langues), 0) = 0 OR v_fuseau IS NULL
     OR pg_catalog.jsonb_typeof(v_rep -> 'disponibilitesDeclarees') IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_array_length(v_rep -> 'disponibilitesDeclarees') = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits',
      'controles', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nom', 'profil_renseigne', 'cause', 'reponses_incompletes')));
  END IF;

  -- Rien n'a ete ecrit jusqu'ici. A partir d'ici, tout ou rien.
  IF v_doc.status = 'pending'::public.kyc_doc_status THEN
    UPDATE public.kyc_documents
       SET status = 'approved'::public.kyc_doc_status, rejection_reason = NULL,
           verified_by = v_uid, verified_at = pg_catalog.now()
     WHERE id = v_doc.id;
    PERFORM public.log_sensitive_access('kyc_decision', 'kyc_documents', v_doc.id::text,
      pg_catalog.jsonb_build_object('approuve', true, 'motif', '', 'acces_retire', false,
                                    'geste', 'valider_piece', 'candidature', v_c.id));
  END IF;

  UPDATE public.teacher_profiles tp
     SET kyc_status = 'approved', languages = v_langues, timezone_iana = v_fuseau
   WHERE tp.profile_id = v_c.profile_id AND tp.deleted_at IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'salle 3 : profil enseignant introuvable pour la candidature %', v_c.id
      USING ERRCODE = 'P0001';
  END IF;

  -- Une ligne par heure entiere couverte, dans le fuseau declare. Une heure
  -- deja declaree reste telle quelle.
  INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  SELECT DISTINCT v_c.profile_id, (pl ->> 'jour')::smallint, h::smallint, v_fuseau
    FROM pg_catalog.jsonb_array_elements(v_rep -> 'disponibilitesDeclarees') AS pl,
         LATERAL pg_catalog.generate_series(
           pg_catalog.split_part(pl ->> 'debut', ':', 1)::integer,
           pg_catalog.split_part(pl ->> 'fin', ':', 1)::integer - 1) AS h
   WHERE h BETWEEN 0 AND 23
  ON CONFLICT (profile_id, weekday, hour_local) DO NOTHING;
  SELECT pg_catalog.count(*) INTO v_heures FROM public.weekly_availability w
   WHERE w.profile_id = v_c.profile_id;

  -- La candidature entre en salle 3, puis le compte devient actif : le
  -- declencheur L1B l'admet une fois l'etape `confirmee`, la garde des
  -- signatures s'applique, le courriel « compte enseignant valide » part par
  -- son declencheur.
  PERFORM private.candidature_geste_appliquer(p_id, 'valider_piece', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('controles', v_controles, 'piece', v_doc.id,
                                  'heuresDisponibles', v_heures, 'aNotifier', 'bienvenue_equipe'));
  UPDATE public.profiles p
     SET account_status = 'active'::public.account_status, updated_at = pg_catalog.now()
   WHERE p.id = v_c.profile_id AND p.account_status = 'pending_kyc'::public.account_status;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'salle 3 : compte de la candidature % non activable', v_c.id USING ERRCODE = 'P0001';
  END IF;

  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'valider_piece', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;
REVOKE ALL ON FUNCTION public.valider_piece_candidat(uuid, integer, text) FROM PUBLIC, anon, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.valider_piece_candidat(uuid, integer, text) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.valider_piece_candidat(uuid, integer, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. Le geste devient disponible pour la direction de son cote.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

SELECT pg_temp.remplacer('public.capacites_candidatures()',
  $a$      'validerPiece', false,$a$,
  $b$      'validerPiece', v_decider,$b$, 1);

-- ---------------------------------------------------------------------------
-- 5. L'affectation, lue par la direction de son cote.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.affectation_candidat(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
  v_p public.profiles;
  v_tp public.teacher_profiles;
  v_causes jsonb := '[]'::jsonb;
  v_classes jsonb;
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
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN private.cand_hors_portee(p_id, v_lecteur, 'affectation');
  END IF;
  IF v_super AND v_c.genre IS DISTINCT FROM v_genre THEN
    PERFORM public.log_sensitive_access('candidature_exception_super_admin', 'candidatures',
      p_id::text, pg_catalog.jsonb_build_object('lecture', 'affectation',
                                                'motif', 'exception_super_admin_kyc'));
  END IF;

  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = v_c.profile_id;
  SELECT tp.* INTO v_tp FROM public.teacher_profiles tp
   WHERE tp.profile_id = v_c.profile_id AND tp.deleted_at IS NULL;
  -- Les causes, dans l'ordre ou la direction les leverait. Ce que
  -- `app_private.verifier_affectation_enseignant` exige aussi pour chaque
  -- Classe (langue, public, disponibilites) se juge a l'affectation.
  IF v_c.etape IS DISTINCT FROM 'confirmee' OR v_c.issue IS DISTINCT FROM 'en_cours' THEN
    v_causes := v_causes || '["pas_en_salle_3"]'::jsonb;
  END IF;
  IF v_p.id IS NULL OR v_p.deleted_at IS NOT NULL
     OR v_p.role IS DISTINCT FROM 'teacher'::public.app_role
     OR v_p.account_status NOT IN ('active'::public.account_status, 'provisional_active'::public.account_status)
     OR (v_p.access_until IS NOT NULL AND v_p.access_until <= pg_catalog.now()) THEN
    v_causes := v_causes || '["compte_inactif"]'::jsonb;
  END IF;
  IF v_tp.kyc_status IS DISTINCT FROM 'approved' THEN
    v_causes := v_causes || '["piece_non_validee"]'::jsonb;
  END IF;
  IF coalesce(pg_catalog.cardinality(v_tp.languages), 0) = 0 THEN
    v_causes := v_causes || '["langues_absentes"]'::jsonb;
  END IF;
  IF v_p.gender IS NULL THEN
    v_causes := v_causes || '["genre_inconnu"]'::jsonb;
  END IF;
  IF coalesce(v_c.indisponible, false) THEN
    v_causes := v_causes || '["indisponible"]'::jsonb;
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', g.id, 'libelle', g.libelle, 'jour', g.weekday, 'heure', g.hour_local,
           'fuseau', g.timezone_iana, 'public', g.type_public)
         ORDER BY g.weekday, g.hour_local, g.id), '[]'::jsonb)
    INTO v_classes
    FROM public.groupes g
   WHERE g.teacher_id = v_c.profile_id AND g.ended_at IS NULL;

  RETURN pg_catalog.jsonb_build_object(
    'candidature', v_c.id,
    'affectable', pg_catalog.jsonb_array_length(v_causes) = 0,
    'causes', v_causes,
    'nombreClasses', pg_catalog.jsonb_array_length(v_classes),
    'classes', v_classes);
END;
$function$;
REVOKE ALL ON FUNCTION public.affectation_candidat(uuid) FROM PUBLIC, anon, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.affectation_candidat(uuid) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.affectation_candidat(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Empreintes F86 : les deux RPC nouvelles, et capacites_candidatures dont le
-- texte change (son empreinte suit).
-- ---------------------------------------------------------------------------
DO $empreintes$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  f := 'public.valider_piece_candidat(uuid,integer,text)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.valider_piece_candidat(uuid,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. '
    || 'Salle 3 : la direction valide la piece d''une candidate enseignante (transition 14, verifications/decision_en_attente, hors pause). '
    || 'Les sept controles (private.candidature_controles_salle3) et une piece deposee, sinon controles_non_satisfaits nommes, sans ecriture ; '
    || 'puis en une transaction : piece approuvee, langues et fuseau dans teacher_profiles, disponibilites dans weekly_availability, '
    || 'candidature confirmee, compte active. Must-pass: supabase/tests/scenarios_salle3_prets.sql.');
  f := 'public.affectation_candidat(uuid)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.affectation_candidat(uuid); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=SESSION_ROLE_ADMIN_GENDER_SCOPE_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. '
    || 'Salle 3 : lecture de la direction de son cote (super-admin : les deux, trace) : affectable ou non avec ses causes, '
    || 'et les Classes de l''enseignante. Must-pass: supabase/tests/scenarios_salle3_prets.sql.');
  f := 'public.capacites_candidatures()'::regprocedure;
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    IF pg_catalog.strpos(v_com, 'Salle 3 (03/11/2026)') = 0 THEN
      v_com := v_com || ' Salle 3 (03/11/2026) : validerPiece suit peutDecider. Must-pass: supabase/tests/scenarios_salle3_prets.sql.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;
END;
$empreintes$;

-- ---------------------------------------------------------------------------
-- Postflight.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_caps text := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_caps, '''validerPiece'', v_decider') = 0 THEN
    RAISE EXCEPTION 'salle 3 : validerPiece ne suit pas peutDecider';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                  WHERE r.geste = 'valider_piece' AND r.transition = 14
                    AND r.cible ->> 'etape' = 'confirmee') THEN
    RAISE EXCEPTION 'salle 3 : la regle valider_piece (transition 14) manque';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.valider_piece_candidat(uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.affectation_candidat(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.valider_piece_candidat(uuid,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.affectation_candidat(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.candidature_controles_salle3(public.candidatures)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.candidature_entretien_controles(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'salle 3 : droits d''execution inattendus';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.capacites_candidatures()'::regprocedure,
                              'public.valider_piece_candidat(uuid,integer,text)'::regprocedure,
                              'public.affectation_candidat(uuid)'::regprocedure)
                AND coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '')
                    NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%') THEN
    RAISE EXCEPTION 'salle 3 : empreinte F86 perimee';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname IN ('public', 'private')
                AND p.proname IN ('valider_piece_candidat', 'affectation_candidat',
                                  'candidature_controles_salle3', 'candidature_entretien_controles')
                AND NOT coalesce(p.proconfig @> ARRAY['search_path=""'], false)) THEN
    RAISE EXCEPTION 'salle 3 : search_path vide attendu';
  END IF;
END;
$postflight$;
