-- BE-1h REFAIRE-ENTRETIEN (lot 8 de CARTE-GESTES-DIRECTION, trou T9 ; arbitrage du pilote : autorise).
--
-- Aucun retour a l'entretien n'existait depuis `decision_en_attente` (entretien tenu ou dispense).
-- Le geste `refaire_entretien` (transition 46) : la direction ramene une candidature de la salle de
-- verification, etat `decision_en_attente`, a `entretien_a_planifier`.
--   * motif ecrit obligatoire ; direction active seulement ; ni pause ni dossier ferme ;
--   * rien n'est efface : l'entretien tenu et sa fiche restent ; la dispense reste ;
--     une ligne `candidature_entretiens_refaits` garde qui, quand, pourquoi, l'etat d'avant ;
--   * l'ancien resultat ne compte plus : `entretien_conclusion` ignore un entretien tenu avant le
--     dernier retour, et les controles de la salle 3 ignorent une dispense d'avant le dernier retour ;
--     une nouvelle dispense ou un nouvel entretien tenu, apres le retour, compte de nouveau ;
--   * la personne peut planifier un nouvel entretien (geste `planifier_entretien`, inchange).
-- Aucun message n'est envoye a la personne (aucun texte n'est decide pour cela).
--
-- FICHIER SANS EFFACEMENT DE DONNEES. Additif : une table, une regle du moteur, deux fonctions ;
-- retouches par ancrage de trois fonctions en vigueur (jamais une copie entiere). Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.candidature_entretiens_refaits') IS NOT NULL THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : deja installee';
  END IF;
  IF pg_catalog.to_regclass('public.candidature_dispenses_entretien') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_entretien_controles(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.entretien_conclusion(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)') IS NULL THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : dependances absentes (dispense, entretiens, moteur des gestes)';
  END IF;
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.transition = 46) THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : la transition 46 est deja prise';
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
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La trace du retour a l'entretien
-- ============================================================
CREATE TABLE public.candidature_entretiens_refaits (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id),
  motif text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(motif)) BETWEEN 1 AND 2000),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  etat_avant text NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_entretiens_refaits_candidature_idx
  ON public.candidature_entretiens_refaits (candidature_id, cree_le DESC);
ALTER TABLE public.candidature_entretiens_refaits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.candidature_entretiens_refaits FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE public.candidature_entretiens_refaits IS
  'BE-1h (16/11/2026) : la direction a ramene une candidature de decision_en_attente a entretien_a_planifier '
  '(motif, auteur, etat d''avant). Jamais effacee. Ce qui precede une ligne ne compte plus comme entretien tenu '
  'ni comme dispense. Ecrite par private.candidature_geste_refaire_entretien seulement ; aucun droit client.';

-- ============================================================
-- 2. La regle du geste (moteur des gestes)
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('refaire_entretien', 1, 46, '{direction}', '{verifications}',
   '{decision_en_attente}', '{en_cours}', 'interdite', NULL, '{direction}',
   NULL, false, 'entretien', '{"etat": "entretien_a_planifier"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 3. Le geste lui-meme (un coeur prive, une porte publique)
-- ============================================================
CREATE FUNCTION private.candidature_geste_refaire_entretien(
  p_id uuid, p_auteur uuid, p_version integer, p_cle text, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
  v_motif text := private.candidature_motif(p_motif);
BEGIN
  v_o := private.candidature_geste_ouvrir(p_id, 'refaire_entretien', 'direction', p_auteur, p_version, p_cle,
                                          p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  IF v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'motif_requis', 'geste', 'refaire_entretien');
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'type_non_admis');
  END IF;

  INSERT INTO public.candidature_entretiens_refaits (candidature_id, motif, auteur_id, etat_avant)
  VALUES (p_id, v_motif, p_auteur, v_c.etat);

  PERFORM private.candidature_geste_appliquer(p_id, 'refaire_entretien', (v_o ->> 'variante')::smallint,
    'direction', p_auteur, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('refaire', true, 'etatAvant', v_c.etat));
  RETURN private.candidature_geste_conclure(p_cle, p_id, 'refaire_entretien', p_auteur,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;
ALTER FUNCTION private.candidature_geste_refaire_entretien(uuid, uuid, integer, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_geste_refaire_entretien(uuid, uuid, integer, text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.refaire_entretien(
  p_id uuid, p_motif text, p_version_attendue integer, p_cle_idempotence text)
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
  RETURN private.candidature_geste_refaire_entretien(p_id, auth.uid(), p_version_attendue,
                                                     p_cle_idempotence, p_motif);
END;
$function$;
ALTER FUNCTION public.refaire_entretien(uuid, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.refaire_entretien(uuid, text, integer, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.refaire_entretien(uuid, text, integer, text) TO authenticated;

-- ============================================================
-- 4. Les retouches par ancrage des fonctions en vigueur
-- ============================================================
DO $retouches$
DECLARE
  v_def text;
BEGIN
  -- 4.1 L'entretien tenu d'avant le dernier retour ne compte plus.
  v_def := pg_catalog.pg_get_functiondef('private.entretien_conclusion(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'candidature_entretiens_refaits') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'WHERE e.candidature_id = p_candidature AND e.issue = ''tenu''',
      'WHERE e.candidature_id = p_candidature AND e.issue = ''tenu''
     -- BE-1h : un entretien tenu avant le dernier retour (entretien refait) ne compte plus.
     AND NOT EXISTS (SELECT 1 FROM public.candidature_entretiens_refaits rf
                      WHERE rf.candidature_id = p_candidature
                        AND rf.cree_le > coalesce(e.consigne_le, ''-infinity''::timestamptz))',
      'conclusion.tenu');
    EXECUTE v_def;
  END IF;

  -- 4.2 La dispense d'avant le dernier retour ne vaut plus entretien tenu.
  v_def := pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'candidature_entretiens_refaits') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = p_candidature)',
      'FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = p_candidature
                AND NOT EXISTS (SELECT 1 FROM public.candidature_entretiens_refaits rf
                                 WHERE rf.candidature_id = p_candidature AND rf.cree_le > d.cree_le))',
      'controles.dispense');
    EXECUTE v_def;
  END IF;

  -- 4.3 La capacite du geste.
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'refaireEntretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''dispenserEntretien'', v_decider,',
      '''dispenserEntretien'', v_decider,
      ''refaireEntretien'', v_decider,', 'capacites.geste');
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
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.refaire_entretien(uuid,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.refaire_entretien(uuid,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.refaire_entretien(uuid,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. '
    || 'BE-1h REFAIRE-ENTRETIEN. Direction active ; moteur (transition 46, motif ecrit) ; '
    || 'decision_en_attente vers entretien_a_planifier ; rien n''est efface, l''ancien resultat ne compte plus. '
    || 'Must-pass: supabase/tests/scenarios_refaire_entretien.sql.');
  FOREACH f IN ARRAY ARRAY['public.capacites_candidatures()'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'BE-1h') = 0 THEN
        v_com := v_com || ' BE-1h (16/11/2026) : la capacite refaireEntretien.';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$f86$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.refaire_entretien(uuid,text,integer,text)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.candidature_geste_refaire_entretien(uuid,uuid,integer,text,text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : DEFINER ou ACL invalide';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.candidature_entretiens_refaits', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
              WHERE c.oid = 'public.candidature_entretiens_refaits'::regclass) THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : table ouverte ou sans RLS';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.entretien_conclusion(uuid)'::regprocedure),
                       'candidature_entretiens_refaits') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_entretien_controles(uuid)'::regprocedure),
                          'candidature_entretiens_refaits') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                          'refaireEntretien') = 0 THEN
    RAISE EXCEPTION 'REFAIRE-ENTRETIEN : retouche absente';
  END IF;
END
$postflight$;
