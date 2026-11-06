-- CAND-PREVENIR (directeur, 24/10/2026, « oui Prévenir ») : le lien
-- d'inscription part par e-mail, depuis l'application, aux personnes des
-- formulaires Google importés qui ont laissé une adresse.
--
-- Decision du directeur du 23/10 (DECISION-CANDIDATURES-2026-10-21.md, « Le
-- message qui previent les inscrits des formulaires Google », regles 1 a 8) :
-- le message rappelle la date et le formulaire, dit qu'il n'y a rien a payer,
-- et ne part jamais deux fois. Le modele `lien_inscription` est celui de la
-- file des courriels (COURRIELS-1, supabase/functions/_shared/courriel/), et
-- son branchement revient a ce lot (docs/current/COURRIELS.md, section 7).
-- Il amende la spec consolidee 7.4, ou `lien_inscription` n'etait qu'un
-- message WhatsApp consigne : WhatsApp reste le geste des personnes sans
-- adresse (consigner_prevenu_candidat, inchange).
--
-- Deux fonctions, pour la direction de son cote seulement (le super-admin lit
-- les deux cotes mais ne decide que du sien, comme les autres gestes) :
-- * apercu_prevenir_par_courriel() : combien recevraient le message, combien
--   sont deja prevenus ou deja inscrits, et si l'inscription est ouverte ;
-- * prevenir_par_courriel(p_limite) : met le message en file pour chaque
--   personne a prevenir (au plus p_limite par appel), et rend les comptes.
--
-- Qui est « a prevenir par e-mail » : une reponse importee active, de ce cote,
-- avec une adresse valide, sans candidature rattachee ; personne n'a de compte
-- a cette adresse ; elle n'a pas ete prevenue par WhatsApp ; aucun message
-- `lien_inscription` n'est deja en file (ou parti) pour cette adresse. Deux
-- reponses a la meme adresse ne recoivent qu'un message (la plus ancienne).
--
-- Refus : tant que l'inscription en ligne est fermee
-- (candidatures.inscription_publique_ouverte), rien ne part : le lien
-- menerait a une page fermee. Rendu {erreur: 'inscription_fermee'}.
--
-- Donnees du message : la date de la reponse (horodatage importe), le nom du
-- formulaire (le nom du classeur, sans « (reponses) »), jamais une reponse ni
-- un telephone ; pas de prenom (le nom importe n'est pas decoupe), donc
-- « Bonjour ». Cle d'idempotence : candidat_prevenu:<id de la reponse>.
-- Audit : des compteurs seulement.
BEGIN;

CREATE FUNCTION public.apercu_prevenir_par_courriel()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_ouverte boolean;
  v_r jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'personnes a prevenir reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune personne a prevenir tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  v_ouverte := coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                          WHERE c.key = 'candidatures.inscription_publique_ouverte'), false);

  WITH cote AS (
    SELECT r.id, r.courriel, r.recue_le, r.suivi_id
      FROM public.formulaires_reponses r
     WHERE r.genre = v_genre AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
  ), classees AS (
    SELECT k.*,
           EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = k.courriel) AS inscrit,
           (EXISTS (SELECT 1 FROM public.candidature_evenements e
                     WHERE e.candidature_id = k.suivi_id AND e.type = 'prevenu')
            OR EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = k.courriel
                          AND s.statut <> 'annule')) AS prevenu
      FROM cote k
  )
  SELECT pg_catalog.jsonb_build_object(
           'aPrevenir', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE NOT c.inscrit AND NOT c.prevenu),
           'dejaPrevenus', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE NOT c.inscrit AND c.prevenu),
           'dejaInscrits', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE c.inscrit),
           'inscriptionOuverte', v_ouverte)
    INTO v_r
    FROM classees c;

  PERFORM public.log_sensitive_access('prevenir_courriel_apercu', 'candidatures', NULL,
    pg_catalog.jsonb_build_object('reader_gender', v_genre, 'exception_active', v_super) || v_r);
  RETURN v_r;
END;
$function$;

CREATE FUNCTION public.prevenir_par_courriel(p_limite integer DEFAULT 200)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_r record;
  v_formulaire text;
  v_id uuid;
  v_mis integer := 0;
  v_restants integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun envoi tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite < 1 OR p_limite > 500 THEN
    RAISE EXCEPTION 'limite invalide : de 1 a 500' USING ERRCODE = '22023';
  END IF;
  IF NOT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                    WHERE c.key = 'candidatures.inscription_publique_ouverte'), false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'inscription_fermee');
  END IF;

  -- Deux directions qui envoient en meme temps ne previennent pas deux fois
  -- la meme adresse : un seul envoi a la fois.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('cand_prevenir_par_courriel'));

  FOR v_r IN
    SELECT DISTINCT ON (r.courriel) r.id, r.courriel, r.recue_le, l.classeur
      FROM public.formulaires_reponses r
      JOIN public.formulaires_lots l ON l.id = r.lot_id
     WHERE r.genre = v_genre AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = r.courriel)
       AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                        WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu')
       AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                          AND s.statut <> 'annule')
     ORDER BY r.courriel, r.recue_le ASC, r.id ASC
  LOOP
    EXIT WHEN v_mis >= p_limite;
    v_formulaire := nullif(pg_catalog.btrim(pg_catalog.regexp_replace(
                      v_r.classeur, '\s*\((r[ée]ponses|responses)\)\s*$', '', 'i')), '');
    v_id := public.courriel_enfiler(
      'recrutement',
      'lien_inscription',
      v_r.courriel,
      NULL,
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'date_reponse', v_r.recue_le,
        'formulaire', v_formulaire)),
      'candidat_prevenu:' || v_r.id::text,
      'manuel',
      v_uid);
    IF v_id IS NOT NULL THEN
      v_mis := v_mis + 1;
    END IF;
  END LOOP;

  SELECT pg_catalog.count(DISTINCT r.courriel)::integer INTO v_restants
    FROM public.formulaires_reponses r
   WHERE r.genre = v_genre AND r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = r.courriel)
     AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                      WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu')
     AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                      WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                        AND s.statut <> 'annule');

  PERFORM public.log_sensitive_access('prevenir_courriel_envoi', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'mis_en_file', v_mis,
      'restants', v_restants,
      'limite', p_limite));
  RETURN pg_catalog.jsonb_build_object('misEnFile', v_mis, 'restants', v_restants);
END;
$function$;

-- ============================================================
-- Droits, empreintes F86, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.apercu_prevenir_par_courriel()',
    'public.prevenir_par_courriel(integer)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.apercu_prevenir_par_courriel()', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active, genre connu, sinon 42501 ; lecture de son cote seulement : trois compteurs par adresse (a prevenir, deja prevenus, deja inscrits) et l etat de l inscription ; aucune adresse rendue ; audit des compteurs.'),
      ('public.prevenir_par_courriel(integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active, genre connu, sinon 42501 ; limite 1 a 500 sinon 22023 ; inscription fermee : refus rendu sans ecriture ; verrou consultatif ; de son cote seulement ; une adresse une fois (compte existant, WhatsApp consigne, lien_inscription deja en file : exclus) ; courriel_enfiler recrutement/lien_inscription, cle candidat_prevenu:<reponse>, origine manuel ; donnees date et formulaire seulement ; audit des compteurs.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-24. CAND-PREVENIR. %s Must-pass: supabase/tests/scenarios_cand_prevenir_courriel.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde,
      v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT e.signature, p.*
    FROM (VALUES
      ('public.apercu_prevenir_par_courriel()'),
      ('public.prevenir_par_courriel(integer)')
    ) AS e(signature)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> 'v'
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'CAND-PREVENIR : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;
  -- La file reste fermee aux comptes : seule une fonction DEFINER y ecrit.
  IF pg_catalog.has_function_privilege('authenticated',
       'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.courriels_sortants', 'SELECT,INSERT,UPDATE') THEN
    RAISE EXCEPTION 'CAND-PREVENIR : la file des courriels est ouverte aux comptes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.courriel_categories c WHERE c.code = 'recrutement') THEN
    RAISE EXCEPTION 'CAND-PREVENIR : categorie recrutement absente de la file des courriels';
  END IF;
END;
$postflight$;

COMMIT;
