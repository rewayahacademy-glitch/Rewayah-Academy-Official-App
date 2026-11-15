-- AUDIT-PORTAIL-CANDIDAT (directeur, 14/11/2026 : « je t'ai expressement dit
-- de scanner tout globalement pour ne rien rater »). Tableau complet :
-- docs/current/CANDIDATURES/AUDIT_PORTAIL_CANDIDAT_2026-11-14.md.
--
-- Deux trous du serveur, corriges ici, sans rien effacer :
--
-- T3. etat_dossier() disait « contrat signe » pour un enseignant des qu'UNE
--     acceptation teacher_nda existait, et « avis signe » pour toute version
--     de recording_and_control_notice ; la salle 3 (candidature_controles_salle3,
--     accords_signes) exige le contrat COURANT (version et empreinte) et l'avis
--     a la version requise. Le jour d'une nouvelle version, le portail aurait
--     dit « Fait » et la confirmation en salle 3 aurait ete refusee, sans aucun
--     chemin pour signer. 0 personne touchee le 14/11 (lu en production) : trou
--     latent. Desormais, pour l'enseignant seulement, etat_dossier lit la meme
--     regle que la salle 3 ; la page des accords propose alors la nouvelle
--     version (elle lit deja contratEtSignature). Les autres roles ne changent
--     pas. Sans texte courant ou sans version requise posee (base rejouee), la
--     regle d'avant reste.
--
-- T4. lire_candidature() rendait 'controles' a nul : le dossier de la direction
--     disait « Disponible au branchement serveur » et ne montrait ni le contrat,
--     ni l'avis, ni le code de conduite, ni la piece manquants (36 candidatures
--     envoyees sans contrat signe le 14/11). Il rend desormais, pour une
--     candidature enseignant, les controles nommes deja connus de l'ecran :
--     cadre_religieux, accords_signes (cause : le premier accord manquant, la
--     meme regle que la salle 3), piece_validee (cause : piece_absente,
--     piece_a_verifier, piece_a_redeposer) et, apres l'envoi,
--     questionnaire_complet et paiement_compatible. Pour une autre candidature,
--     nul comme avant.
--
-- Remplacement par ANCRES sur les definitions en place (relues en production
-- le 14/11/2026) ; chaque ancre doit se trouver une seule fois, sinon arret.
-- Rejouable : une fonction qui porte deja la marque n'est pas retouchee.
-- Empreintes F86 recalculees dans le commentaire existant (md5 seulement).
-- Aucun mot d'effacement. Sans BEGIN ni COMMIT de premier niveau.

-- ---------------------------------------------------------------------------
-- 1. L'aide interne : les controles du dossier, vus par la direction.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.candidature_controles_dossier(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $fonction$
DECLARE
  v_resultat jsonb := '[]'::jsonb;
  v_cadre text;
  v_cadre_cause text;
  v_nda_version text;
  v_nda_hash text;
  v_accords text;
  v_piece text;
  v_piece_cause text;
  v_quest text;
  v_paiement text;
BEGIN
  IF c.id IS NULL OR c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN NULL;
  END IF;

  -- cadre_religieux : la version requise, acceptee.
  v_cadre := public.cadre_religieux_version_requise();
  v_cadre_cause := CASE
    WHEN v_cadre IS NULL THEN 'non_publie'
    WHEN c.profile_id IS NULL THEN 'compte_absent'
    WHEN NOT EXISTS (SELECT 1 FROM public.contract_acceptances a
                      WHERE a.profile_id = c.profile_id
                        AND a.contract_kind = 'teacher_religious_framework'
                        AND a.version = v_cadre) THEN 'non_accepte'
  END;
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'cadre_religieux', 'valeur', v_cadre_cause IS NULL, 'cause', v_cadre_cause));

  -- accords_signes : la regle de la salle 3 (candidature_controles_salle3), le
  -- premier accord manquant en cause.
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
  END;
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'accords_signes', 'valeur', v_accords IS NULL, 'cause', v_accords));

  -- piece_validee : la derniere piece non effacee du compte.
  IF c.profile_id IS NOT NULL THEN
    SELECT k.status::text INTO v_piece
      FROM public.kyc_documents k
     WHERE k.profile_id = c.profile_id AND k.deleted_at IS NULL
     ORDER BY k.created_at DESC
     LIMIT 1;
  END IF;
  v_piece_cause := CASE
    WHEN c.profile_id IS NULL THEN 'compte_absent'
    WHEN v_piece IS NULL THEN 'piece_absente'
    WHEN v_piece = 'approved' THEN NULL
    WHEN v_piece = 'rejected' THEN 'piece_a_redeposer'
    ELSE 'piece_a_verifier'
  END;
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nom', 'piece_validee', 'valeur', v_piece_cause IS NULL, 'cause', v_piece_cause));

  -- Apres l'envoi : le questionnaire envoye et le versement.
  IF c.etape = 'verifications'
     OR (c.etape = 'prequalification' AND c.etat IN ('en_examen', 'paiement_non_disponible')) THEN
    v_quest := private.candidature_questionnaire_envoye(c);
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'questionnaire_complet', 'valeur', v_quest = 'complet',
      'cause', CASE WHEN v_quest IS DISTINCT FROM 'complet' THEN v_quest END));
    v_paiement := private.paiement_etat(c.id);
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'paiement_compatible', 'valeur', v_paiement = 'compatible',
      'cause', CASE WHEN v_paiement IS DISTINCT FROM 'compatible' THEN v_paiement END));
  END IF;
  RETURN v_resultat;
END;
$fonction$;

ALTER FUNCTION private.candidature_controles_dossier(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_controles_dossier(public.candidatures)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 2. lire_candidature : les controles du dossier au lieu de nul.
-- ---------------------------------------------------------------------------
DO $lire$
DECLARE
  v_oid regprocedure := 'public.lire_candidature(uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_avant constant text := E'''controles'', NULL::jsonb,';
  v_apres constant text := E'''controles'', private.candidature_controles_dossier(v_c), -- AUDIT-PORTAIL-CANDIDAT';
  v_n integer;
  v_commentaire text;
BEGIN
  IF pg_catalog.strpos(v_def, 'AUDIT-PORTAIL-CANDIDAT') > 0 THEN
    RAISE NOTICE 'AUDIT-PORTAIL-CANDIDAT : lire_candidature rend deja les controles, rien a faire';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : ancre de lire_candidature trouvee % fois au lieu de 1', v_n;
  END IF;
  v_commentaire := pg_catalog.obj_description(v_oid::oid, 'pg_proc');
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  IF v_commentaire IS NOT NULL THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      pg_catalog.regexp_replace(v_commentaire, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)))
      || ' AUDIT-PORTAIL-CANDIDAT (14/11/2026) : controles du dossier (private.candidature_controles_dossier).');
  END IF;
END;
$lire$;

-- ---------------------------------------------------------------------------
-- 3. etat_dossier : le contrat et l'avis de l'enseignant, a la regle de la
--    salle 3.
-- ---------------------------------------------------------------------------
DO $etat$
DECLARE
  v_oid regprocedure := 'public.etat_dossier()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_avant constant text := E'  ) into v_accuse;\n';
  v_apres constant text := E'  ) into v_accuse;\n'
    || E'\n'
    || E'  -- AUDIT-PORTAIL-CANDIDAT (14/11/2026) : pour l''enseignant, la regle de la\n'
    || E'  -- salle 3 (accords_signes) : contrat courant, version et empreinte ; avis a\n'
    || E'  -- la version requise. Sans texte courant ou sans version requise, la regle\n'
    || E'  -- d''avant reste.\n'
    || E'  if v_profile.role = ''teacher''::public.app_role then\n'
    || E'    if exists (select 1 from public.contract_texts t\n'
    || E'               where t.contract_kind = ''teacher_nda'' and t.locale = ''fr'' and t.is_current) then\n'
    || E'      select exists (\n'
    || E'        select 1 from public.contract_acceptances c\n'
    || E'        join public.contract_texts t\n'
    || E'          on t.contract_kind = c.contract_kind and t.version = c.version\n'
    || E'         and t.locale = ''fr'' and t.is_current\n'
    || E'        where c.profile_id = v_profile.id and c.contract_kind = ''teacher_nda''\n'
    || E'          and c.signed_sha256 = t.sha256\n'
    || E'      ) into v_contrat;\n'
    || E'    end if;\n'
    || E'    if exists (select 1 from public.contract_required_versions r\n'
    || E'               where r.contract_kind = ''recording_and_control_notice'') then\n'
    || E'      select exists (\n'
    || E'        select 1 from public.contract_acceptances c\n'
    || E'        join public.contract_required_versions r\n'
    || E'          on r.contract_kind = c.contract_kind and r.version = c.version\n'
    || E'        where c.profile_id = v_profile.id\n'
    || E'          and c.contract_kind = ''recording_and_control_notice''\n'
    || E'      ) into v_accuse;\n'
    || E'    end if;\n'
    || E'  end if;\n';
  v_n integer;
  v_commentaire text;
BEGIN
  IF pg_catalog.strpos(v_def, 'AUDIT-PORTAIL-CANDIDAT') > 0 THEN
    RAISE NOTICE 'AUDIT-PORTAIL-CANDIDAT : etat_dossier lit deja les versions, rien a faire';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : ancre de etat_dossier trouvee % fois au lieu de 1', v_n;
  END IF;
  v_commentaire := pg_catalog.obj_description(v_oid::oid, 'pg_proc');
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  IF v_commentaire IS NOT NULL THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      pg_catalog.regexp_replace(v_commentaire, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)))
      || ' AUDIT-PORTAIL-CANDIDAT (14/11/2026) : contrat et avis de l enseignant a la regle de la salle 3.');
  END IF;
END;
$etat$;

-- ---------------------------------------------------------------------------
-- 4. Verification.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.lire_candidature(uuid)'::regprocedure,
                           'public.etat_dossier()'::regprocedure] LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(f), 'AUDIT-PORTAIL-CANDIDAT') = 0 THEN
      RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : % non remplacee', f;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : droits ou search_path invalides sur %', f;
    END IF;
    IF coalesce(pg_catalog.obj_description(f::oid, 'pg_proc'), '') <> ''
       AND pg_catalog.obj_description(f::oid, 'pg_proc') LIKE '%md5_functiondef=%'
       AND pg_catalog.obj_description(f::oid, 'pg_proc')
           NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : empreinte F86 non a jour sur %', f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.candidature_controles_dossier(public.candidatures)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT : aide interne executable par authenticated';
  END IF;
END;
$postflight$;
