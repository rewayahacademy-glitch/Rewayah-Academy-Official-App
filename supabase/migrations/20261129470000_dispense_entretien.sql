-- BE-1g DISPENSE-ENTRETIEN (directeur, 16/11/2026 : « pas d'entretien pour l'instant » ; il n'avait
-- aucun geste pour faire passer un fondateur, CAND-00068, salle de verification, entretien a planifier).
--
-- FICHIER SANS EFFACEMENT DE DONNEES : un seul mot d'effacement, a la section 3 bis, pour reecrire le CHECK
-- candidature_lots_geste_check (seule exception admise, supabase/CLAUDE.md). Additif : une table, une regle
-- du moteur des gestes, deux fonctions, retouches par ancrage de six fonctions en vigueur (jamais une copie entiere).
-- Sans BEGIN/COMMIT de premier niveau.
--
-- Le geste `dispenser_entretien` (transition 45) : la direction dispense une candidature en salle de
-- verification (etape verifications, etats entretien_a_planifier et entretien_planifie) de l'entretien.
--   * motif ecrit obligatoire ; categorie de dispense `fondateur` ou `autre` ;
--   * l'effet est celui d'un entretien tenu et favorable : l'etat d'arrivee est `decision_en_attente`, le meme
--     que consigner_entretien_tenu (transition 13), et les deux controles de la salle 3 (entretien_conclu,
--     evaluation_validee) sont vrais, sinon valider_piece ne pourrait jamais conclure ;
--   * un entretien deja planifie est annule (issue `annule`, seance `canceled`), sans rien effacer ;
--   * la dispense est gardee dans `candidature_dispenses_entretien` (qui, quand, pourquoi, quelle categorie,
--     quelle seance annulee), et l'evenement du dossier (type entretien) et le journal sensible la tracent ;
--   * groupable : apercu_lot_candidats / executer_lot_candidats l'acceptent. Pour ce geste seul, l'argument
--     `p_modele` porte la categorie (`fondateur` ou `autre`), le moteur de lot n'ayant pas d'autre argument.
-- Aucun message n'est envoye a la personne (aucun `aNotifier`) : aucun texte n'est decide pour cela.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.candidature_dispenses_entretien') IS NOT NULL THEN
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.candidature_entretien_controles(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_groupe(uuid,text,uuid,integer,text,text,text,date,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : dependances absentes (moteur des gestes, entretiens)';
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
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La trace de la dispense
-- ============================================================
CREATE TABLE public.candidature_dispenses_entretien (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id),
  categorie text NOT NULL CHECK (categorie IN ('fondateur', 'autre')),
  motif text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(motif)) BETWEEN 1 AND 2000),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  etat_avant text NOT NULL,
  session_annulee uuid NULL REFERENCES public.sessions(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_dispenses_entretien_candidature_idx
  ON public.candidature_dispenses_entretien (candidature_id);
ALTER TABLE public.candidature_dispenses_entretien ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.candidature_dispenses_entretien FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE public.candidature_dispenses_entretien IS
  'BE-1g (16/11/2026) : la direction a dispense une candidature de l''entretien (categorie fondateur ou autre, '
  'motif, etat d''avant, seance annulee). Jamais effacee. Ecrite par private.candidature_geste_dispenser seulement ; aucun droit client.';

-- ============================================================
-- 2. La regle du geste (moteur des gestes)
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('dispenser_entretien', 1, 45, '{direction}', '{verifications}',
   '{entretien_a_planifier,entretien_planifie}', '{en_cours}', 'interdite', NULL, '{direction}',
   NULL, true, 'entretien', '{"etat": "decision_en_attente"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 3. Le geste lui-meme (un coeur prive, une porte publique)
-- ============================================================
CREATE FUNCTION private.candidature_geste_dispenser(
  p_id uuid, p_categorie text, p_auteur uuid, p_version integer, p_cle text, p_motif text,
  p_details jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
  v_e public.entretiens;
  v_motif text := private.candidature_motif(p_motif);
  v_annulee uuid;
BEGIN
  IF p_categorie IS NULL OR p_categorie NOT IN ('fondateur', 'autre') THEN
    RAISE EXCEPTION 'categorie de dispense : fondateur ou autre' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'dispenser_entretien', 'direction', p_auteur, p_version, p_cle,
                                          p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  IF v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'motif_requis', 'geste', 'dispenser_entretien');
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'type_non_admis');
  END IF;

  -- Un entretien deja planifie ou reserve est annule, rien n'est efface : l'issue passe a `annule`, la
  -- seance a `canceled` (comme une issue non tenue), le creneau reste lie a son entretien.
  SELECT e.* INTO v_e FROM public.entretiens e
   WHERE e.candidature_id = p_id AND e.issue IS NULL
   FOR UPDATE;
  IF v_e.session_id IS NOT NULL THEN
    UPDATE public.entretiens
       SET issue = 'annule', consigne_par = p_auteur, consigne_le = pg_catalog.clock_timestamp()
     WHERE session_id = v_e.session_id;
    UPDATE public.sessions SET status = 'canceled' WHERE id = v_e.session_id AND status = 'planned';
    v_annulee := v_e.session_id;
  END IF;

  INSERT INTO public.candidature_dispenses_entretien (candidature_id, categorie, motif, auteur_id, etat_avant, session_annulee)
  VALUES (p_id, p_categorie, v_motif, p_auteur, v_c.etat, v_annulee);

  PERFORM private.candidature_geste_appliquer(p_id, 'dispenser_entretien', (v_o ->> 'variante')::smallint,
    'direction', p_auteur, p_motif, NULL, '{}'::jsonb,
    coalesce(p_details, '{}'::jsonb) || pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
      'dispense', p_categorie, 'sessionAnnulee', v_annulee,
      'entretienAnnule', v_annulee IS NOT NULL)));
  RETURN private.candidature_geste_conclure(p_cle, p_id, 'dispenser_entretien', p_auteur,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(p_id),
      'dispense', pg_catalog.jsonb_build_object('categorie', p_categorie, 'entretienAnnule', v_annulee IS NOT NULL)));
END;
$function$;
ALTER FUNCTION private.candidature_geste_dispenser(uuid, text, uuid, integer, text, text, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_geste_dispenser(uuid, text, uuid, integer, text, text, jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.dispenser_entretien(
  p_id uuid, p_categorie text, p_motif text, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.candidature_geste_dispenser(p_id, p_categorie, auth.uid(), p_version_attendue,
                                             p_cle_idempotence, p_motif);
END;
$function$;
ALTER FUNCTION public.dispenser_entretien(uuid, text, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.dispenser_entretien(uuid, text, text, integer, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.dispenser_entretien(uuid, text, text, integer, text) TO authenticated;

-- ============================================================
-- 3 bis. Le rapport d'un lot garde le nom du geste : le CHECK s'etend a la dispense
-- ============================================================
-- Seule reecriture d'un CHECK de ce fichier ; les lignes existantes (pause, levee, refus) restent valides.
ALTER TABLE public.candidature_lots DROP CONSTRAINT candidature_lots_geste_check;
ALTER TABLE public.candidature_lots ADD CONSTRAINT candidature_lots_geste_check
  CHECK (geste = ANY (ARRAY['mettre_en_pause'::text, 'lever_pause'::text, 'refuser'::text, 'dispenser_entretien'::text]));

-- ============================================================
-- 4. Les retouches par ancrage des fonctions en vigueur
-- ============================================================
DO $retouches$
DECLARE
  v_def text;
BEGIN
  -- 4.1 Le geste groupe du moteur : la dispense en fait partie.
  v_def := pg_catalog.pg_get_functiondef('private.candidature_geste_groupe(uuid,text,uuid,integer,text,text,text,date,jsonb)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'dispenser_entretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, 'p_geste NOT IN (''refuser'', ''mettre_en_pause'', ''lever_pause'')',
      'p_geste NOT IN (''refuser'', ''mettre_en_pause'', ''lever_pause'', ''dispenser_entretien'')', 'groupe.liste');
    v_def := pg_temp.remplacer(v_def,
      '  v_o := private.candidature_geste_ouvrir(p_id, p_geste, ''direction'', p_auteur, p_version, p_cle,',
      '  -- BE-1g : la dispense a son coeur ; p_modele y porte la categorie (fondateur ou autre).
  IF p_geste = ''dispenser_entretien'' THEN
    RETURN private.candidature_geste_dispenser(p_id, p_modele, p_auteur, p_version, p_cle, p_motif, p_details);
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, p_geste, ''direction'', p_auteur, p_version, p_cle,',
      'groupe.dispatch');
    EXECUTE v_def;
  END IF;

  -- 4.2 L'execution d'un lot.
  v_def := pg_catalog.pg_get_functiondef('public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'dispenser_entretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, 'WHEN ''leverPause'' THEN ''lever_pause''',
      'WHEN ''leverPause'' THEN ''lever_pause'' WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''', 'executer.camel');
    v_def := pg_temp.remplacer(v_def, 'v_groupable := v_geste IN (''mettre_en_pause'', ''lever_pause'', ''refuser'');',
      'v_groupable := v_geste IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'');', 'executer.groupable');
    v_def := pg_temp.remplacer(v_def, '  IF v_geste IN (''mettre_en_pause'', ''refuser'') AND v_motif IS NULL THEN',
      '  -- BE-1g : la dispense exige un motif et une categorie (fondateur ou autre) portee par p_modele.
  IF v_geste = ''dispenser_entretien'' AND v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object(''erreur'', ''motif_requis'', ''geste'', v_geste);
  END IF;
  IF v_geste = ''dispenser_entretien'' AND coalesce(p_modele <> ALL (ARRAY[''fondateur'', ''autre'']), true) THEN
    RETURN pg_catalog.jsonb_build_object(''erreur'', ''categorie_requise'', ''geste'', v_geste);
  END IF;
  IF v_geste IN (''mettre_en_pause'', ''refuser'') AND v_motif IS NULL THEN', 'executer.motif');
    EXECUTE v_def;
  END IF;

  -- 4.3 L'apercu d'un lot.
  v_def := pg_catalog.pg_get_functiondef('public.apercu_lot_candidats(text,uuid[])'::regprocedure);
  IF pg_catalog.strpos(v_def, 'dispenser_entretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, 'WHEN ''leverPause'' THEN ''lever_pause''',
      'WHEN ''leverPause'' THEN ''lever_pause'' WHEN ''dispenserEntretien'' THEN ''dispenser_entretien''', 'apercu.camel');
    v_def := pg_temp.remplacer(v_def, 'IF v_geste NOT IN (''mettre_en_pause'', ''lever_pause'', ''refuser'') THEN',
      'IF v_geste NOT IN (''mettre_en_pause'', ''lever_pause'', ''refuser'', ''dispenser_entretien'') THEN', 'apercu.liste');
    v_def := pg_temp.remplacer(v_def, '''motifRequis'', v_geste IN (''mettre_en_pause'', ''refuser''),',
      '''motifRequis'', v_geste IN (''mettre_en_pause'', ''refuser'', ''dispenser_entretien''),', 'apercu.motif');
    EXECUTE v_def;
  END IF;

  -- 4.4 Les capacites : le geste et sa place parmi les gestes groupables.
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'dispenserEntretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''consignerEntretien'', v_decider,',
      '''consignerEntretien'', v_decider,
      ''dispenserEntretien'', v_decider,', 'capacites.geste');
    v_def := pg_temp.remplacer(v_def, '''["mettreEnPause", "leverPause", "refuser"]''',
      '''["mettreEnPause", "leverPause", "refuser", "dispenserEntretien"]''', 'capacites.groupables');
    EXECUTE v_def;
  END IF;

  -- 4.5 Les controles de la salle 3 : une dispense vaut un entretien tenu et favorable.
  v_def := pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'candidature_dispenses_entretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '  v_favorable boolean;
BEGIN', '  v_favorable boolean;
BEGIN', 'controles.declaration');
    v_def := pg_temp.remplacer(v_def,
      '  v_favorable := coalesce((v_conclusion ->> ''avisFavorable'')::boolean, false);',
      '  v_favorable := coalesce((v_conclusion ->> ''avisFavorable'')::boolean, false);
  -- BE-1g : une dispense de la direction vaut un entretien tenu et favorable.
  IF EXISTS (SELECT 1 FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = p_candidature) THEN
    v_tenu := true;
    v_favorable := true;
  END IF;', 'controles.dispense');
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
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.dispenser_entretien(uuid,text,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.dispenser_entretien(uuid,text,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.dispenser_entretien(uuid,text,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. '
    || 'BE-1g DISPENSE-ENTRETIEN. Direction active ; moteur (transition 45, motif ecrit, categorie fondateur ou autre) ; '
    || 'entretien deja planifie annule sans rien effacer ; effet d''un entretien tenu et favorable. '
    || 'Must-pass: supabase/tests/scenarios_dispense_entretien.sql.');
  FOREACH f IN ARRAY ARRAY['public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure,
                           'public.apercu_lot_candidats(text,uuid[])'::regprocedure,
                           'public.capacites_candidatures()'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'BE-1g') = 0 THEN
        v_com := v_com || ' BE-1g (16/11/2026) : le geste groupable dispenser_entretien (categorie portee par p_modele).';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$f86$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.dispenser_entretien(uuid,text,text,integer,text)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.candidature_geste_dispenser(uuid,text,uuid,integer,text,text,jsonb)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : DEFINER ou ACL invalide';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.candidature_dispenses_entretien', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
              WHERE c.oid = 'public.candidature_dispenses_entretien'::regclass) THEN
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : table ouverte ou sans RLS';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure),
                       'candidature_dispenses_entretien') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                          'dispenserEntretien') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure),
                          'dispenser_entretien') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.apercu_lot_candidats(text,uuid[])'::regprocedure),
                          'dispenser_entretien') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_geste_groupe(uuid,text,uuid,integer,text,text,text,date,jsonb)'::regprocedure),
                          'candidature_geste_dispenser') = 0 THEN
    RAISE EXCEPTION 'DISPENSE-ENTRETIEN : retouche absente';
  END IF;
END
$postflight$;
