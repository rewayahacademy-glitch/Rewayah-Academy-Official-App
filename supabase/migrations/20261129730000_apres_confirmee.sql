-- APRES-CONFIRMEE (carte des gestes de la direction, 16/11/2026, trou T3, arbitrage A3) : apres l'accueil
-- (`confirmee`), la direction n'avait presque rien : les regles `restreindre` (transition 20) et `lever_restriction`
-- (transition 21) existaient dans le moteur des gestes mais sans AUCUNE porte publique.
--
--   * restreindre_candidat(id, cause, motif, version, cle) : la direction restreint une candidature confirmee.
--     cause `manuelle` : regle `restreindre` en vigueur ; cause `piece` ou `paiement` : « demander une verification
--     de la piece ou du versement » (deux regles du moteur, `demander_verification_piece` et
--     `demander_verification_versement`, meme transition 20, la cause posee est celle de la regle) ;
--   * lever_restriction_candidat(id, motif, version, cle) : transition 21, contrôles revérifiés (spec §4.2 ligne 21) :
--     cause `piece`, la piece la plus recente est approuvee (controle `piece_validee`) ; cause `paiement`, le
--     versement est compatible (controle `paiement_compatible`) ; cause `manuelle`, aucun controle. Sinon
--     `controles_non_satisfaits`, nommes, et rien n'est ecrit.
--
-- TOUT PASSE PAR LE MOTEUR DES GESTES (private.candidature_gestes_regles, candidature_geste_ouvrir,
-- candidature_geste_appliquer) : aucune seconde logique. Les gestes permis par ligne (private.lp_gestes) les voient.
--
-- CE QUE CE LOT NE FAIT PAS (a decider, signale a la direction) : aucun message n'est envoye a la personne (aucun
-- texte decide) ; restreindre avec la cause `piece` ne desactive PAS le compte (la spec ne le dit que pour le refus
-- d'une piece par decider_dossier) et lever ne reactive aucun compte ; l'indisponibilite (transition 22) vient avec
-- l'etape E.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : deux regles, deux fonctions, une retouche
-- par ancrage (une ancre trouvee une fois, sinon echec) de public.capacites_candidatures, jamais une copie entiere.
-- Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles WHERE geste = 'demander_verification_piece') THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.candidature_controles_salle3(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_faux(jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_appliquer(uuid,text,smallint,text,uuid,text,text,jsonb,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : dependances absentes (moteur des gestes, controles de la salle 3)';
  END IF;
  -- Les deux regles neuves reprennent la transition 20 de `restreindre` (meme famille : une restriction). Le moteur
  -- n'exige pas des numeros uniques (cle primaire : geste, variante ; 7, 11, 18, 22 et 24 sont deja partages) ;
  -- mais la 20 ne doit appartenir qu'a la famille de la restriction.
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
              WHERE r.transition = 20
                AND r.geste NOT IN ('restreindre', 'demander_verification_piece', 'demander_verification_versement')) THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : la transition 20 est prise par une regle etrangere a la restriction';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. Les deux regles de « demander une verification »
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('demander_verification_piece', 1, 20, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite',
   'non_restreinte', '{direction}', NULL, false, 'restriction',
   '{"restreinte": true, "restriction_cause": "piece"}', '{}', false),
  ('demander_verification_versement', 1, 20, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite',
   'non_restreinte', '{direction}', NULL, false, 'restriction',
   '{"restreinte": true, "restriction_cause": "paiement"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 2. Restreindre (ou demander une verification) : la porte publique
-- ============================================================
CREATE FUNCTION public.restreindre_candidat(
  p_id uuid,
  p_cause text,
  p_motif text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_geste text;
  v_o jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_geste := CASE p_cause
               WHEN 'manuelle' THEN 'restreindre'
               WHEN 'piece' THEN 'demander_verification_piece'
               WHEN 'paiement' THEN 'demander_verification_versement'
             END;
  IF v_geste IS NULL THEN
    RAISE EXCEPTION 'cause attendue : manuelle, piece ou paiement' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, v_geste, 'direction', v_uid, p_version_attendue,
                                          p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, v_geste, (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('cause', p_cause));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, v_geste, v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;
ALTER FUNCTION public.restreindre_candidat(uuid, text, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.restreindre_candidat(uuid, text, text, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.restreindre_candidat(uuid, text, text, integer, text) TO authenticated;

-- ============================================================
-- 3. Lever la restriction : la porte publique, controles revérifiés
-- ============================================================
CREATE FUNCTION public.lever_restriction_candidat(
  p_id uuid,
  p_motif text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_o jsonb;
  v_c public.candidatures;
  v_nom text;
  v_faux jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'lever_restriction', 'direction', v_uid, p_version_attendue,
                                          p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  -- Controles revérifiés : seul celui de la cause de la restriction compte (spec §4.2, ligne 21).
  v_nom := CASE v_c.restriction_cause WHEN 'piece' THEN 'piece_validee' WHEN 'paiement' THEN 'paiement_compatible' END;
  IF v_nom IS NOT NULL THEN
    SELECT coalesce(pg_catalog.jsonb_agg(f.e), '[]'::jsonb) INTO v_faux
      FROM pg_catalog.jsonb_array_elements(
             private.candidature_controles_faux(private.candidature_controles_salle3(v_c))) AS f(e)
     WHERE f.e ->> 'nom' = v_nom;
    IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits', 'controles', v_faux);
    END IF;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'lever_restriction', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('causeLevee', v_c.restriction_cause));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'lever_restriction', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;
ALTER FUNCTION public.lever_restriction_candidat(uuid, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lever_restriction_candidat(uuid, text, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lever_restriction_candidat(uuid, text, integer, text) TO authenticated;

-- ============================================================
-- 4. Les capacites : restreindre, lever, et les deux verifications
-- ============================================================
DO $capacites$
DECLARE
  f regprocedure := 'public.capacites_candidatures()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(f);
BEGIN
  IF pg_catalog.strpos(v_def, 'demanderVerification') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''restreindre'', false,
      ''leverRestriction'', false,',
      '''restreindre'', v_decider,
      ''leverRestriction'', v_decider,
      ''demanderVerification'', v_decider,', 'capacites.restriction');
    EXECUTE v_def;
  END IF;
END;
$capacites$;

-- ============================================================
-- 5. F86 et controle final
-- ============================================================
DO $f86$
DECLARE
  f regprocedure := 'public.capacites_candidatures()'::regprocedure;
  v_com text;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.restreindre_candidat(uuid,text,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.restreindre_candidat(uuid,text,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.restreindre_candidat(uuid,text,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-17. '
    || 'APRES-CONFIRMEE. Direction active (garde positive) ; moteur (transition 20, motif ecrit, cause manuelle, piece ou paiement, '
    || 'candidature confirmee non restreinte) ; aucun message envoye, aucun compte touche. '
    || 'Must-pass: supabase/tests/scenarios_apres_confirmee.sql.');
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.lever_restriction_candidat(uuid,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.lever_restriction_candidat(uuid,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.lever_restriction_candidat(uuid,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-17. '
    || 'APRES-CONFIRMEE. Direction active (garde positive) ; moteur (transition 21, motif ecrit) ; controles revérifiés de la cause '
    || '(piece_validee, paiement_compatible) sinon controles_non_satisfaits sans ecriture. '
    || 'Must-pass: supabase/tests/scenarios_apres_confirmee.sql.');
  v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    IF pg_catalog.strpos(v_com, 'APRES-CONFIRMEE') = 0 THEN
      v_com := v_com || ' APRES-CONFIRMEE (17/11/2026) : restreindre, leverRestriction et demanderVerification ouverts a la direction.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;
END;
$f86$;

DO $postflight$
DECLARE
  v1 regprocedure := 'public.restreindre_candidat(uuid,text,text,integer,text)'::regprocedure;
  v2 regprocedure := 'public.lever_restriction_candidat(uuid,text,integer,text)'::regprocedure;
BEGIN
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
       WHERE p.oid IN (v1, v2) AND p.prosecdef AND p.proowner = 'postgres'::regrole
         AND p.proconfig @> ARRAY['search_path=""']) <> 2
     OR pg_catalog.has_function_privilege('anon', v1, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v2, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v1, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v2, 'EXECUTE') THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : DEFINER ou ACL invalide';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.candidature_gestes_regles
       WHERE geste IN ('demander_verification_piece', 'demander_verification_versement')) <> 2
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                          'demanderVerification') = 0 THEN
    RAISE EXCEPTION 'APRES-CONFIRMEE : regle ou capacite absente';
  END IF;
END
$postflight$;
