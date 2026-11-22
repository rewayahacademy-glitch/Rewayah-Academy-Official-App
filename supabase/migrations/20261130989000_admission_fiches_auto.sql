-- ADMISSION-FICHES-AUTO (directeur, 22/11/2026, « sans discussion ») : quand la
-- direction accepte la demande d'une famille ou d'un eleve adulte
-- (`accepter_admission`), les fiches des eleves naissent AUTOMATIQUEMENT des
-- reponses de l'onboarding (public.candidature_apprenants), dans la meme
-- transaction. La famille ne ressaisit jamais ses enfants.
--
-- Avant : l'acceptation ne creait rien (profil_eleve_id restait NULL) ; la
-- creation attendait l'application du tuteur (fonction Edge
-- creer-profil-enfant, puis lier_apprenant_profil), et ne se faisait pas
-- toujours (CAND-00645, constat en production le 22/11/2026).
--
-- Ce que fait l'acceptation, pour chaque apprenant de la demande non encore lie :
--   * un enfant : si le foyer a deja un profil eleve au meme prenom, non lie
--     (le `profil_probable` de mes_apprenants_demande : une creation faite a la
--     main), il est lie, sans doublon ; sinon son compte d'identite est cree
--     comme le fait la fonction Edge (courriel eleve-<uuid>@<domaine eleves>,
--     jamais confirme, sans mot de passe utilisable, child_of et genre dans
--     raw_app_meta_data), puis sa fiche par public.creer_profil_enfant (profil
--     du foyer, student_profiles, tranche, affichage, camera, genre), puis le
--     lien et les reponses par public.lier_apprenant_profil (niveau, objectif,
--     langue, fiche marquee remplie) ;
--   * le titulaire qui suit des cours (« moi », ou parent apprenant) : sa fiche
--     autonome par public.creer_profil_eleve_titulaire si elle manque, ses
--     reponses rangees comme le fait private.niv1_reponses_titulaire_vers_profil,
--     et le lien profil_eleve_id vers sa propre fiche.
-- Les fonctions existantes sont appelees telles quelles, au nom du titulaire
-- (ses claims le temps de l'appel, puis ceux de l'appelant sont rendus) : leurs
-- gardes, leurs regles (6 a 17 ans, prenom du titulaire refuse, genre) et leurs
-- journaux s'appliquent sans copie.
-- Un apprenant qui ne peut pas recevoir sa fiche (regle refusee) ne bloque pas
-- l'acceptation : l'echec est journalise (admission_fiche_auto_echec) et
-- l'application du tuteur garde sa reprise.
-- Idempotent : un apprenant deja lie n'est jamais repris.
--
-- Rattrapage : les demandes deja acceptees (confirmee, en_cours, famille ou
-- eleve adulte, titulaire au compte valide) recoivent leurs fiches de la meme
-- facon. Postflight : plus aucun apprenant d'une telle demande sans fiche.
--
-- Fichier sans aucun mot d'effacement, sans transaction de premier niveau.

-- 1. Le compte d'identite d'un enfant -------------------------------------
--
-- Les colonnes de auth.users varient entre Supabase et le stub de la CI : les
-- colonnes connues sont posees si elles existent, comme les poserait
-- auth.admin.createUser. Le domaine vient de la configuration
-- (student_email_domain), sinon celui de la fonction Edge en production.

CREATE FUNCTION private.admission_compte_enfant(p_tuteur uuid, p_genre text)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid := pg_catalog.gen_random_uuid();
  v_domaine text := coalesce(
    nullif(pg_catalog.btrim(public.get_config('student_email_domain', 'null'::jsonb) #>> '{}'), ''),
    'eleves.rewayahacademy.com');
  v_courriel text;
  v_meta jsonb;
  v_maintenant text := pg_catalog.now()::text;
  v_col text;
  v_val text;
BEGIN
  v_courriel := 'eleve-' || v_id::text || '@' || v_domaine;
  v_meta := pg_catalog.jsonb_build_object('child_of', p_tuteur::text, 'provider', 'email',
                                          'providers', pg_catalog.jsonb_build_array('email'));
  IF p_genre IN ('male', 'female') THEN
    v_meta := v_meta || pg_catalog.jsonb_build_object('gender', p_genre);
  END IF;
  INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES (v_id, v_courriel, v_meta);
  FOR v_col, v_val IN
    SELECT o.key, o.value FROM pg_catalog.jsonb_each_text(pg_catalog.jsonb_build_object(
      'instance_id', '00000000-0000-0000-0000-000000000000',
      'aud', 'authenticated',
      'role', 'authenticated',
      'encrypted_password', '',
      'raw_user_meta_data', '{}',
      'created_at', v_maintenant,
      'updated_at', v_maintenant,
      'confirmation_token', '',
      'recovery_token', '',
      'email_change_token_new', '',
      'email_change', '',
      'email_change_token_current', '',
      'reauthentication_token', '',
      'phone_change', '',
      'phone_change_token', '',
      'is_sso_user', 'false',
      'is_anonymous', 'false')) o
  LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                WHERE a.attrelid = 'auth.users'::pg_catalog.regclass AND a.attname = v_col
                  AND a.attnum > 0 AND NOT a.attisdropped AND a.attgenerated = '') THEN
      EXECUTE pg_catalog.format('UPDATE auth.users SET %I = %L WHERE id = $1', v_col, v_val)
        USING v_id;
    END IF;
  END LOOP;
  -- L'identite « email », comme la cree auth.admin.createUser.
  IF pg_catalog.to_regclass('auth.identities') IS NOT NULL THEN
    EXECUTE 'INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, created_at, updated_at)
             VALUES ($1::text, $1, $2, ''email'', pg_catalog.now(), pg_catalog.now())'
      USING v_id, pg_catalog.jsonb_build_object('sub', v_id::text, 'email', v_courriel,
                                                'email_verified', false, 'phone_verified', false);
  END IF;
  RETURN v_id;
END;
$function$;

-- 2. Les fiches d'une demande acceptee ------------------------------------

CREATE FUNCTION private.admission_fiches_auto(p_candidature_id uuid)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_t public.profiles;
  v_sub text := current_setting('request.jwt.claim.sub', true);
  v_claims text := current_setting('request.jwt.claims', true);
  v_claim text := current_setting('request.jwt.claim', true);
  v_nom text;
  v_a public.candidature_apprenants;
  v_probable uuid;
  v_eleve uuid;
  v_lies integer := 0;
  v_echecs jsonb := '[]'::jsonb;
BEGIN
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature_id;
  IF NOT FOUND OR v_c.type_code NOT IN ('famille', 'eleve_adulte')
     OR v_c.etape <> 'confirmee' OR v_c.issue <> 'en_cours' THEN
    RETURN 0;
  END IF;
  SELECT p.* INTO v_t FROM public.profiles p WHERE p.id = v_c.profile_id;
  IF NOT FOUND OR v_t.role <> 'guardian' OR v_t.deleted_at IS NOT NULL
     OR v_t.household_id IS NULL
     OR v_t.account_status NOT IN ('active', 'provisional_active') THEN
    RETURN 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidature_apprenants a
                  WHERE a.candidature_id = v_c.id AND a.profil_eleve_id IS NULL) THEN
    RETURN 0;
  END IF;

  -- Les fonctions existantes s'appellent au nom du titulaire.
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_t.id::text, true);
  v_nom := pg_catalog.jsonb_build_object(
    'sub', v_t.id::text, 'role', 'authenticated',
    'app_metadata', pg_catalog.jsonb_build_object('role', 'guardian',
                                                  'household_id', v_t.household_id::text))::text;
  PERFORM pg_catalog.set_config('request.jwt.claims', v_nom, true);
  -- auth.jwt() lit request.jwt.claim avant request.jwt.claims.
  PERFORM pg_catalog.set_config('request.jwt.claim', v_nom, true);

  FOR v_a IN
    SELECT a.* FROM public.candidature_apprenants a
     WHERE a.candidature_id = v_c.id AND a.profil_eleve_id IS NULL
     ORDER BY a.rang
  LOOP
    BEGIN
      IF v_a.est_titulaire THEN
        IF NOT EXISTS (SELECT 1 FROM public.student_profiles s
                        WHERE s.profile_id = v_t.id AND s.deleted_at IS NULL) THEN
          PERFORM public.creer_profil_eleve_titulaire();
        END IF;
        -- Les reponses du titulaire, sans ecraser une valeur deja posee
        -- (meme regle que private.niv1_reponses_titulaire_vers_profil).
        UPDATE public.student_profiles s
           SET niveau_declare = coalesce(s.niveau_declare, v_a.niveau_declare),
               objectif = coalesce(s.objectif, v_a.objectif),
               langue_cours = coalesce(s.langue_cours, v_a.langue_code)
         WHERE s.profile_id = v_t.id AND s.deleted_at IS NULL;
        UPDATE public.student_profiles s
           SET onboarding_fait_le = pg_catalog.now()
         WHERE s.profile_id = v_t.id AND s.deleted_at IS NULL
           AND s.onboarding_fait_le IS NULL AND s.cohorte IS NOT NULL
           AND s.langue_cours IS NOT NULL AND s.niveau_declare IS NOT NULL
           AND s.objectif IS NOT NULL;
        UPDATE public.candidature_apprenants SET profil_eleve_id = v_t.id WHERE id = v_a.id;
      ELSE
        -- Une fiche deja creee a la main au meme prenom : liee, jamais doublee.
        SELECT (e ->> 'profil_probable')::uuid INTO v_probable
          FROM pg_catalog.jsonb_array_elements(public.mes_apprenants_demande()) e
         WHERE (e ->> 'id')::uuid = v_a.id;
        v_eleve := v_probable;
        IF v_eleve IS NULL THEN
          v_eleve := private.admission_compte_enfant(v_t.id, v_a.genre::text);
          PERFORM public.creer_profil_enfant(v_eleve, v_t.id, v_a.prenom, v_t.last_name,
                                             v_a.age::integer, NULL::text, NULL::text);
        END IF;
        PERFORM public.lier_apprenant_profil(v_a.id, v_eleve);
      END IF;
      v_lies := v_lies + 1;
    EXCEPTION WHEN OTHERS THEN
      v_echecs := v_echecs || pg_catalog.jsonb_build_object(
        'apprenant_id', v_a.id, 'sqlstate', SQLSTATE, 'message', SQLERRM);
    END;
  END LOOP;

  -- Les claims de l'appelant sont rendus.
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(v_sub, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', coalesce(v_claims, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claim', coalesce(v_claim, ''), true);

  PERFORM public.log_sensitive_access('admission_fiches_auto', 'candidatures', v_c.id::text,
    pg_catalog.jsonb_build_object('reference', v_c.reference, 'lies', v_lies));
  IF pg_catalog.jsonb_array_length(v_echecs) > 0 THEN
    PERFORM public.log_sensitive_access('admission_fiche_auto_echec', 'candidatures', v_c.id::text,
      pg_catalog.jsonb_build_object('reference', v_c.reference, 'echecs', v_echecs));
  END IF;
  RETURN v_lies;
EXCEPTION WHEN OTHERS THEN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(v_sub, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', coalesce(v_claims, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claim', coalesce(v_claim, ''), true);
  RAISE;
END;
$function$;

-- 3. L'acceptation cree les fiches -----------------------------------------
--
-- Meme corps que le lot C (20261030140000), plus l'appel aux fiches apres la
-- transition vers confirmee et l'activation du compte.

CREATE OR REPLACE FUNCTION public.accepter_admission(
  p_id uuid, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_o jsonb;
BEGIN
  v_o := private.candidature_geste_ouvrir(p_id, 'accepter_admission', 'direction', auth.uid(),
                                          p_version_attendue, p_cle_idempotence, NULL, NULL);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'accepter_admission',
    (v_o ->> 'variante')::smallint, 'direction', auth.uid(), NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('aNotifier', 'admission_acceptee'));
  -- La demande est confirmee : le compte peut devenir actif (la regle de
  -- forme du compte, CAND-L1B, le permet desormais).
  UPDATE public.profiles p
     SET account_status = 'active'
   WHERE p.id = v_c.profile_id AND p.account_status = 'pending_kyc';
  -- Une acceptation annulee puis redonnee rend leurs profils aux enfants.
  UPDATE public.profiles p
     SET account_status = 'active'
    FROM public.candidature_apprenants a
   WHERE a.candidature_id = v_c.id AND p.id = a.profil_eleve_id
     AND p.account_status = 'disabled';
  -- ADMISSION-FICHES-AUTO (22/11/2026) : les fiches des eleves naissent des
  -- reponses de la demande, sans rien ressaisir.
  PERFORM private.admission_fiches_auto(v_c.id);
  PERFORM private.admission_courriel(v_c, 'admission_acceptee', '{}'::jsonb,
    'admission_acceptee:' || v_c.id::text || ':' || p_cle_idempotence);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'accepter_admission', auth.uid(),
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- 4. Droits et empreintes ---------------------------------------------------

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.admission_compte_enfant(uuid,text)'::pg_catalog.regprocedure,
    'private.admission_fiches_auto(uuid)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  v_oid := 'public.accepter_admission(uuid,integer,text)'::pg_catalog.regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ADMIN_ONLY; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. Admission lot C, puis ADMISSION-FICHES-AUTO (fiches creees a l''acceptation). Must-pass: supabase/tests/scenarios_admission_fiches_auto.sql.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- 5. Rattrapage des demandes deja acceptees --------------------------------

DO $rattrapage$
DECLARE
  v_id uuid;
  v_n integer;
BEGIN
  FOR v_id IN
    SELECT c.id
      FROM public.candidatures c
      JOIN public.profiles t ON t.id = c.profile_id
     WHERE c.type_code IN ('famille', 'eleve_adulte')
       AND c.etape = 'confirmee' AND c.issue = 'en_cours'
       AND t.role = 'guardian' AND t.deleted_at IS NULL
       AND t.account_status IN ('active', 'provisional_active')
       AND EXISTS (SELECT 1 FROM public.candidature_apprenants a
                    WHERE a.candidature_id = c.id AND a.profil_eleve_id IS NULL)
     ORDER BY c.reference
  LOOP
    v_n := private.admission_fiches_auto(v_id);
    RAISE NOTICE 'ADMISSION-FICHES-AUTO : % apprenant(s) lie(s) pour %', v_n,
      (SELECT c.reference FROM public.candidatures c WHERE c.id = v_id);
  END LOOP;
END;
$rattrapage$;

-- 6. Postflight ---------------------------------------------------------------

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_reste integer;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.admission_compte_enfant(uuid,text)'::pg_catalog.regprocedure,
    'private.admission_fiches_auto(uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'ADMISSION-FICHES-AUTO : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  v_oid := 'public.accepter_admission(uuid,integer,text)'::pg_catalog.regprocedure;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR pg_catalog.strpos(pg_catalog.obj_description(v_oid, 'pg_proc'),
                          pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))) = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_oid), 'private.admission_fiches_auto') = 0 THEN
    RAISE EXCEPTION 'ADMISSION-FICHES-AUTO : accepter_admission invalide (DEFINER, ACL, empreinte ou appel)';
  END IF;
  SELECT pg_catalog.count(*) INTO v_reste
    FROM public.candidature_apprenants a
    JOIN public.candidatures c ON c.id = a.candidature_id
    JOIN public.profiles t ON t.id = c.profile_id
   WHERE c.type_code IN ('famille', 'eleve_adulte')
     AND c.etape = 'confirmee' AND c.issue = 'en_cours'
     AND t.role = 'guardian' AND t.deleted_at IS NULL
     AND t.account_status IN ('active', 'provisional_active')
     AND a.profil_eleve_id IS NULL;
  IF v_reste > 0 THEN
    RAISE EXCEPTION 'ADMISSION-FICHES-AUTO : % apprenant(s) d''une demande acceptee sans fiche', v_reste;
  END IF;
END;
$postflight$;
