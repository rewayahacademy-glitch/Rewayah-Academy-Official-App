-- COMPLEMENT-SALLE-EXAMEN (carte des gestes de la direction, 16/11/2026, trous T6 et T7) :
--   T6 : en Salle d'examen, un complement demande ne pouvait etre ni modifie ni annule (seule la personne pouvait
--        le lever en envoyant). La direction peut maintenant le MODIFIER (nouvelle demande, variante 3 du geste
--        demander_complement) ou l'ANNULER (geste annuler_complement : le dossier revient a `en_examen`).
--   T7 : en `paiement_non_disponible`, la direction peut demander un complement sur le versement (pays ou moyen de
--        versement : le seul code `versement`), variante 4 du geste demander_complement ; l'etat d'arrivee est
--        `a_completer`, comme celui de debloquer_versement.
--
-- TOUT PASSE PAR LE MOTEUR DES GESTES (private.candidature_gestes_regles, private.candidature_geste_ouvrir,
-- private.candidature_geste_appliquer) : trois regles, aucune seconde logique. Les gestes permis par ligne
-- (private.lp_gestes) les voient donc tout seuls.
--
-- FICHIER SANS EFFACEMENT DE DONNEES : un seul mot d'effacement, a la section 1, pour reecrire le CHECK
-- candidature_gestes_regles_condition_check (seule exception admise, supabase/CLAUDE.md) ; les 33 regles en place
-- restent valides. Retouches par ancrage (une ancre trouvee une fois, sinon echec) de trois fonctions en vigueur,
-- jamais une copie entiere. Sans BEGIN/COMMIT de premier niveau.
--
-- Pourquoi une condition de plus (`complement_en_cours`). a_completer sert aussi au questionnaire PAS ENCORE envoye
-- (87 dossiers au 16/11, sans complement) : modifier ou annuler n'y a aucun sens, et lp_gestes proposerait a tort le
-- geste. La condition lit private.candidature_complement_en_cours, la meme source que le geste de cloture.
--
-- Aucun message n'est envoye a la personne pour une ANNULATION (aucun `aNotifier` : aucun texte n'est decide pour
-- cela). Une modification et une demande en `paiement_non_disponible` envoient `complement_demande`, comme toute
-- demande de complement.
--
-- NON COUVERT : les missions de delegation (private.mission_capacites) ne portent pas encore annulerComplement.

DO $preflight$
BEGIN
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles WHERE geste = 'annuler_complement') THEN
    RAISE EXCEPTION 'COMPLEMENT-SALLE-EXAMEN : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.candidature_complement_en_cours(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('public.demander_complement_candidat(uuid,text[],text,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_condition(public.candidatures,text)') IS NULL THEN
    RAISE EXCEPTION 'COMPLEMENT-SALLE-EXAMEN : dependances absentes (moteur des gestes, complement en cours)';
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
    RAISE EXCEPTION 'COMPLEMENT-SALLE-EXAMEN : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La condition `complement_en_cours`
-- ============================================================
-- Seule reecriture d'un CHECK de ce fichier : une valeur de plus, les sept d'avant restent.
ALTER TABLE private.candidature_gestes_regles DROP CONSTRAINT candidature_gestes_regles_condition_check;
ALTER TABLE private.candidature_gestes_regles ADD CONSTRAINT candidature_gestes_regles_condition_check
  CHECK (condition IN ('restreinte', 'non_restreinte', 'indisponible', 'non_indisponible',
    'paiement_a_verifier', 'paiement_a_verifier_ou_compatible', 'restreinte_paiement_a_verifier',
    'complement_en_cours'));

DO $condition$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('private.candidature_condition(public.candidatures,text)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''complement_en_cours''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '    RETURN c.restreinte AND c.restriction_cause = ''paiement'' AND private.paiement_etat(c.id) = ''a_verifier'';
  END IF;',
      '    RETURN c.restreinte AND c.restriction_cause = ''paiement'' AND private.paiement_etat(c.id) = ''a_verifier'';
  ELSIF p_condition = ''complement_en_cours'' THEN
    RETURN pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0;
  END IF;',
      'condition.branche');
    EXECUTE v_def;
  END IF;
END;
$condition$;

-- ============================================================
-- 2. Les trois regles du moteur
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  -- Modifier : une nouvelle demande, tant qu'un complement court ; l'etat reste a_completer.
  ('demander_complement', 3, 7, '{direction}', '{prequalification}', '{a_completer}', '{en_cours}',
   'interdite', 'complement_en_cours', '{direction}', NULL, false, 'transition', '{}', '{}', false),
  -- Demander sur le versement quand le paiement n'est pas disponible : la personne repasse a_completer.
  ('demander_complement', 4, 7, '{direction}', '{prequalification}', '{paiement_non_disponible}', '{en_cours}',
   'interdite', NULL, '{direction}', NULL, false, 'transition', '{"etat": "a_completer"}', '{}', false),
  -- Annuler : le dossier revient en examen, le complement est clos.
  ('annuler_complement', 1, 46, '{direction}', '{prequalification}', '{a_completer}', '{en_cours}',
   'interdite', 'complement_en_cours', '{direction}', NULL, false, 'transition', '{"etat": "en_examen"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 3. L'annulation : la porte publique
-- ============================================================
CREATE FUNCTION public.annuler_complement_candidat(
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
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'annuler_complement', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  -- aCompleter vide : private.candidature_complement_en_cours rend alors aucun code (la demande est close).
  PERFORM private.candidature_geste_appliquer(p_id, 'annuler_complement', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('aCompleter', '[]'::jsonb, 'cloture', true, 'annule', true));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'annuler_complement', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'aCompleter', '[]'::jsonb));
END;
$function$;
ALTER FUNCTION public.annuler_complement_candidat(uuid, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.annuler_complement_candidat(uuid, text, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.annuler_complement_candidat(uuid, text, integer, text) TO authenticated;

-- ============================================================
-- 4. Les retouches par ancrage des fonctions en vigueur
-- ============================================================
DO $retouches$
DECLARE
  v_def text;
BEGIN
  -- 4.1 La demande : en paiement_non_disponible (variante 4), le seul code permis est `versement`.
  v_def := pg_catalog.pg_get_functiondef('public.demander_complement_candidat(uuid,text[],text,integer,text)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'COMPLEMENT-SALLE-EXAMEN') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '  v_codes := private.candidature_complement_codes(v_c.etape, v_c.type_code);',
      '  v_codes := private.candidature_complement_codes(v_c.etape, v_c.type_code);
  -- COMPLEMENT-SALLE-EXAMEN : paiement non disponible, la demande ne porte que sur le versement.
  IF (v_o ->> ''variante'')::smallint = 4 THEN
    v_codes := ARRAY[''versement'']::text[];
  END IF;',
      'demander.codes');
    EXECUTE v_def;
  END IF;

  -- 4.2 Les capacites : les gestes d'annulation et de modification (cles distinctes de demanderComplement,
  -- pour que l'ecran ne confonde pas « demander » et « modifier »).
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'annulerComplement') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''cloreComplement'', v_decider,',
      '''cloreComplement'', v_decider,
      ''annulerComplement'', v_decider,
      ''modifierComplement'', v_decider,', 'capacites.geste');
    EXECUTE v_def;
  END IF;
END;
$retouches$;

-- ============================================================
-- 5. F86 et controle final
-- ============================================================
DO $f86$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.annuler_complement_candidat(uuid,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.annuler_complement_candidat(uuid,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.annuler_complement_candidat(uuid,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. '
    || 'COMPLEMENT-SALLE-EXAMEN. Direction active (garde positive) ; moteur (transition 46, motif ecrit, complement en cours exige par la regle) ; '
    || 'le dossier revient a en_examen, la demande est close, rien n''est efface. '
    || 'Must-pass: supabase/tests/scenarios_complement_salle_examen.sql.');
  FOREACH f IN ARRAY ARRAY['public.demander_complement_candidat(uuid,text[],text,integer,text)'::regprocedure,
                           'public.capacites_candidatures()'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'COMPLEMENT-SALLE-EXAMEN') = 0 THEN
        v_com := v_com || ' COMPLEMENT-SALLE-EXAMEN (16/11/2026) : variantes 3 et 4 de demander_complement, geste annuler_complement.';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$f86$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.annuler_complement_candidat(uuid,text,integer,text)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'COMPLEMENT-SALLE-EXAMEN : DEFINER ou ACL invalide';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.candidature_gestes_regles
       WHERE (geste, variante) IN (('demander_complement', 3), ('demander_complement', 4), ('annuler_complement', 1))) <> 3
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_condition(public.candidatures,text)'::regprocedure),
                          'complement_en_cours') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.demander_complement_candidat(uuid,text[],text,integer,text)'::regprocedure),
                          'COMPLEMENT-SALLE-EXAMEN') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                          'annulerComplement') = 0 THEN
    RAISE EXCEPTION 'COMPLEMENT-SALLE-EXAMEN : retouche ou regle absente';
  END IF;
END
$postflight$;
