-- ADMISSIONS-CHAMPS (directeur, 22/11/2026) : la direction lit, dans la feuille d'une demande, le lien de suivi
-- (`?ref=chingford-londres`) qui a amene la famille ou l'eleve adulte, en plus des reponses du nouvel onboarding.
--
-- LIVRE ICI : `public.lister_demandes_admission(text,text,integer)` rend une cle de plus par demande, `suivi`
-- (`private.sources_inscription.source_ref` du titulaire de la demande, ou nul). Meme signature, meme garde
-- (direction active seulement), meme pagination, SECURITY DEFINER, search_path vide. Aucune table, aucune colonne,
-- aucune donnee touchee : la table `private` reste illisible pour tout role de l'API, seule cette fonction la lit.
--
-- DEPEND DE : 20261130978000 (REF-SUIVI, la table) et 20261130979000 (ONBOARDING-PRAXIS, les champs). Le preflight
-- refuse net si l'une manque : installer dans l'ordre.
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : 0.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.sources_inscription') IS NULL THEN
    RAISE EXCEPTION 'ADMISSIONS-CHAMPS : installer d''abord 20261130978000 (REF-SUIVI)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute
                  WHERE attrelid = 'public.candidature_apprenants'::pg_catalog.regclass
                    AND attname = 'riwaya' AND NOT attisdropped) THEN
    RAISE EXCEPTION 'ADMISSIONS-CHAMPS : installer d''abord 20261130979000 (ONBOARDING-PRAXIS)';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION public.lister_demandes_admission(
  p_type text, p_recherche text DEFAULT NULL, p_page integer DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_recherche text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_recherche, ''))), '');
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_lignes jsonb;
  v_total integer;
  v_a_traiter integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'listes des admissions reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_type NOT IN ('famille', 'eleve_adulte') THEN
    RAISE EXCEPTION 'population inconnue : famille ou eleve_adulte' USING ERRCODE = '22023';
  END IF;
  WITH filtrees AS (
    SELECT c.*, public.courriel_adresse_profil(c.profile_id) AS courriel
      FROM public.candidatures c
     WHERE c.type_code = p_type
       AND (v_recherche IS NULL
            OR pg_catalog.strpos(pg_catalog.lower(c.nom_complet), v_recherche) > 0
            OR pg_catalog.strpos(pg_catalog.lower(c.reference), v_recherche) > 0
            OR pg_catalog.strpos(coalesce(pg_catalog.lower(public.courriel_adresse_profil(c.profile_id)), ''),
                                 v_recherche) > 0)
  )
  SELECT
    coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', f.id,
      'reference', f.reference,
      'nom', f.nom_complet,
      'courriel', f.courriel,
      'recueLe', f.recue_le,
      'etape', f.etape,
      'etat', f.etat,
      'issue', f.issue,
      'version', f.version,
      'derniereActivite', f.derniere_activite,
      'source', f.source_declaree,
      'suivi', (SELECT s.source_ref FROM private.sources_inscription s WHERE s.profile_id = f.profile_id),
      'apprenants', (
        SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'prenom', a.prenom, 'age', a.age, 'genre', a.genre,
                 'estTitulaire', a.est_titulaire, 'niveau', a.niveau_declare,
                 'objectif', CASE WHEN a.objectif_priere THEN 'priere_invocations' ELSE a.objectif END,
                 'moments', a.moments, 'langue', coalesce(a.langue_demandee, a.langue_code),
                 'riwaya', a.riwaya, 'riwayaAutre', a.riwaya_autre,
                 'memorise', a.memorise_quantite, 'juz', pg_catalog.to_jsonb(a.juz),
                 'sourates', pg_catalog.to_jsonb(a.sourates),
                 'langueSecours', a.langue_secours, 'langueAutre', a.langue_autre)
                 ORDER BY a.rang), '[]'::jsonb)
          FROM public.candidature_apprenants a WHERE a.candidature_id = f.id)
    ) ORDER BY (f.issue = 'en_cours') DESC, f.recue_le, f.id)
    FILTER (WHERE f.rang_page = v_page), '[]'::jsonb),
    pg_catalog.count(*)::integer
    INTO v_lignes, v_total
    FROM (SELECT x.*, ((pg_catalog.row_number() OVER (
                   ORDER BY (x.issue = 'en_cours') DESC, x.recue_le, x.id) - 1) / 50 + 1)
                   AS rang_page
            FROM filtrees x) f;
  SELECT pg_catalog.count(*)::integer INTO v_a_traiter
    FROM public.candidatures c
   WHERE c.type_code = p_type AND c.issue = 'en_cours' AND c.etape = 'recue';
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'total', v_total,
    'aTraiter', v_a_traiter, 'page', v_page, 'parPage', 50);
END;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure :=
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ADMIN_ONLY; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. ADMISSIONS-CHAMPS.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure :=
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'ADMISSIONS-CHAMPS : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.sources_inscription', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.sources_inscription', 'SELECT') THEN
    RAISE EXCEPTION 'ADMISSIONS-CHAMPS : sources_inscription lisible par un client';
  END IF;
END
$postflight$;
