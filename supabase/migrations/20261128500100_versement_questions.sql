-- VERSEMENT-QUESTIONS (directeur, 16/11/2026) : « oui pour le paiement, corrige sa reponse et lance
-- le lot. mais les modifications s'arretent apres la validation du dossier ».
-- Source : docs/current/DECISION-QUESTIONS-VERSEMENT-2026-11-16.md.
--
-- A installer APRES 20261128500000_versement_cand_00013.sql (independant en realite, mais dans l'ordre).
-- Ce fichier ne contient aucun mot d'effacement, ni BEGIN ni COMMIT hors des blocs plpgsql.
--
-- 1. public.modifier_mon_versement(p_compte, p_pays, p_operateurs) : le candidat modifie TOUT le
--    bloc (compte bancaire oui/non, pays, services de mobile money) tant que l'etape est
--    `prequalification` (la « validation du dossier ») ; au-dela, `modification_impossible`.
--    Une nouvelle ligne de reponses (l'historique est garde), le paiement recalcule, les
--    coordonnees remises a valider si le pays change. public.modifier_mon_pays_versement(text) est
--    gardee (aucun appelant ne casse) mais ferme, elle aussi, apres la preqalification.
-- 2. Le recalcul du paiement ramene un dossier `paiement_non_disponible` a `a_completer`
--    (transition 9) quand la reponse du candidat rend le paiement compatible (cause `reponses`) ou
--    quand la direction debloque (cause `deblocage`) : avant, seule une ligne du referentiel qui
--    passait confirme le faisait, et une candidate qui corrigeait sa reponse restait coincee.
-- 3. Le geste de la direction « Debloquer le versement » (geste `debloquer_versement`, transition
--    44) : motif ecrit obligatoire, trace, paiement `compatible` meme sans moyen declare, tant que
--    la declaration n'a pas change. Deux colonnes sur candidatures (versement_debloque_le,
--    versement_debloque_par). Une modification du bloc par le candidat leve le deblocage : la
--    direction a decide sur une declaration precise.
-- 4. Aucune nouvelle version du questionnaire : publier une version nouvelle rendrait PERIMEES
--    toutes les reponses deja envoyees (le serveur compte alors tous les champs requis comme
--    manquants). L'ordre des questions (compte d'abord) se regle a l'ecran.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'VERSEMENT-QUESTIONS : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. Les colonnes du deblocage
-- ============================================================
ALTER TABLE public.candidatures
  ADD COLUMN versement_debloque_le timestamptz NULL,
  ADD COLUMN versement_debloque_par uuid NULL REFERENCES public.profiles(id),
  ADD CONSTRAINT candidatures_versement_debloque_forme
    CHECK ((versement_debloque_le IS NULL) = (versement_debloque_par IS NULL));
COMMENT ON COLUMN public.candidatures.versement_debloque_le IS
  'VERSEMENT-QUESTIONS : la direction a debloque le versement a la main (paiement compatible sans moyen declare). Ecrite par public.debloquer_versement_candidat seule ; levee par public.modifier_mon_versement.';

-- ============================================================
-- 2. Le calcul et le recalcul
-- ============================================================
DO $retouches$
DECLARE
  v_def text;
BEGIN
  -- paiement_etat : un versement debloque par la direction est compatible.
  v_def := pg_catalog.pg_get_functiondef('private.paiement_etat(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'versement_debloque_le') = 0 THEN
    v_def := pg_temp.remplacer(v_def, 'v_decl := private.paiement_declaration(p_candidature);',
      'IF EXISTS (SELECT 1 FROM public.candidatures c WHERE c.id = p_candidature AND c.versement_debloque_le IS NOT NULL) THEN
    RETURN ''compatible'';
  END IF;
  v_decl := private.paiement_declaration(p_candidature);', 'paiement_etat.debloque');
    EXECUTE v_def;
  END IF;

  -- paiement_recalculer : deux causes de plus ramenent le dossier a a_completer.
  v_def := pg_catalog.pg_get_functiondef('private.paiement_recalculer(uuid,text,uuid,text,uuid,boolean)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''deblocage''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '''moyen_infirme'', ''reouverture'') THEN',
      '''moyen_infirme'', ''reouverture'', ''deblocage'') THEN', 'recalculer.causes');
    v_def := pg_temp.remplacer(v_def,
      'OR (p_cause = ''reouverture'' AND v_apres <> ''incompatible'')) THEN',
      'OR (p_cause = ''reouverture'' AND v_apres <> ''incompatible'')
          OR (p_cause IN (''reponses'', ''deblocage'') AND v_apres = ''compatible'')) THEN', 'recalculer.transition9');
    EXECUTE v_def;
  END IF;

  -- L'ancienne RPC du pays : fermee apres la validation du dossier, comme la nouvelle.
  v_def := pg_catalog.pg_get_functiondef('public.modifier_mon_pays_versement(text)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'v_c.etape NOT IN (''prequalification'', ''verifications'', ''confirmee'')') > 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'v_c.etape NOT IN (''prequalification'', ''verifications'', ''confirmee'')',
      'v_c.etape <> ''prequalification''', 'pays.etape');
    EXECUTE v_def;
  END IF;

  -- capacites_candidatures : la direction sait si le geste est le sien.
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'debloquerVersement') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''infirmerMoyenPaiement'', v_decider,',
      '''infirmerMoyenPaiement'', v_decider,
      ''debloquerVersement'', v_decider,', 'capacites.geste');
    EXECUTE v_def;
  END IF;
END;
$retouches$;

-- ============================================================
-- 3. La regle du geste (moteur des gestes)
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('debloquer_versement', 1, 44, '{direction}', '{prequalification}', '{en_examen,paiement_non_disponible}',
   '{en_cours}', 'interdite', NULL, '{direction}', NULL, false, 'controle', '{}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 4. Le candidat modifie tout le bloc
-- ============================================================
CREATE FUNCTION public.modifier_mon_versement(p_compte boolean, p_pays text, p_operateurs text[] DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(true);
  v_pays text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_pays, '')));
  v_ops text[];
  v_c public.candidatures;
  v_doc public.candidature_reponses;
  v_avant jsonb;
  v_apres jsonb;
  v_ramene text;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'reserve au titulaire d''une candidature en cours' USING ERRCODE = '42501';
  END IF;
  IF p_compte IS NULL THEN
    RAISE EXCEPTION 'compte bancaire attendu : vrai ou faux' USING ERRCODE = '22023';
  END IF;
  IF v_pays !~ '^[A-Z]{2}$'
     OR NOT EXISTS (SELECT 1 FROM private.pays_iso_3166 x WHERE x.code = v_pays) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'pays_invalide');
  END IF;
  -- Avec un compte bancaire, aucun service de mobile money n'est retenu ; sans, la liste est
  -- celle du candidat, dedoublonnee, et chaque service doit exister au referentiel du pays.
  IF p_compte THEN
    v_ops := ARRAY[]::text[];
  ELSE
    SELECT coalesce(pg_catalog.array_agg(DISTINCT o.code ORDER BY o.code), ARRAY[]::text[]) INTO v_ops
      FROM pg_catalog.unnest(coalesce(p_operateurs, ARRAY[]::text[])) AS o(code);
    IF pg_catalog.cardinality(v_ops) > 10
       OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_ops) AS o(code)
                   WHERE o.code IS NULL OR o.code !~ '^[a-z][a-z0-9_]{1,39}$'
                      OR NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                                      WHERE l.pays = v_pays AND l.methode = 'mobile_money'
                                        AND l.operateur = o.code)) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'operateur_invalide');
    END IF;
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.issue <> 'en_cours' OR v_c.etape <> 'prequalification' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modification_impossible');
  END IF;
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_id AND r.source = 'candidat' AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  IF v_doc.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'aucune_reponse_envoyee');
  END IF;

  v_avant := pg_catalog.jsonb_build_object(
    'compteBancaire', v_doc.reponses -> 'compteBancaire',
    'paysVersement', v_doc.reponses -> 'paysVersement',
    'operateurs', coalesce(v_doc.reponses -> 'operateurs', '[]'::jsonb));
  v_apres := pg_catalog.jsonb_build_object(
    'compteBancaire', p_compte, 'paysVersement', v_pays, 'operateurs', pg_catalog.to_jsonb(v_ops));
  IF v_avant = v_apres THEN
    RETURN pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature',
                                         'inchange', true);
  END IF;

  INSERT INTO public.candidature_reponses
    (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
  VALUES (v_id, v_doc.questionnaire_version,
          ((v_doc.reponses - 'operateurs') - 'compteBancaire' - 'paysVersement')
            || pg_catalog.jsonb_build_object('compteBancaire', p_compte, 'paysVersement', v_pays)
            || CASE WHEN pg_catalog.cardinality(v_ops) > 0
                    THEN pg_catalog.jsonb_build_object('operateurs', pg_catalog.to_jsonb(v_ops))
                    ELSE '{}'::jsonb END,
          'candidat', false, pg_catalog.clock_timestamp());
  -- Le pays change : les coordonnees deja saisies ne valent plus, la direction les revalide.
  IF v_avant -> 'paysVersement' IS DISTINCT FROM v_apres -> 'paysVersement' THEN
    UPDATE public.versement_coordonnees
       SET valide_le = NULL, valide_par = NULL
     WHERE profile_id = v_uid AND active AND valide_le IS NOT NULL;
  END IF;
  -- Un deblocage de la direction valait pour la declaration d'avant.
  IF v_c.versement_debloque_le IS NOT NULL THEN
    UPDATE public.candidatures
       SET versement_debloque_le = NULL, versement_debloque_par = NULL
     WHERE id = v_id;
  END IF;
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
  VALUES (v_id, 'controle', v_uid, pg_catalog.jsonb_build_object(
    'controle', 'versement_modifie', 'avant', v_avant, 'apres', v_apres,
    'deblocageLeve', v_c.versement_debloque_le IS NOT NULL));
  PERFORM private.paiement_recalculer(v_id, 'reponses');
  RETURN pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature');
END;
$function$;

ALTER FUNCTION public.modifier_mon_versement(boolean, text, text[]) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.modifier_mon_versement(boolean, text, text[]) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.modifier_mon_versement(boolean, text, text[]) TO authenticated;

-- ============================================================
-- 5. Le geste de la direction : « Debloquer le versement »
-- ============================================================
CREATE FUNCTION public.debloquer_versement_candidat(
  p_id uuid,
  p_version_attendue integer,
  p_cle_idempotence text,
  p_motif text
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
  v_o := private.candidature_geste_ouvrir(p_id, 'debloquer_versement', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  -- Le geste d'abord (evenement controle avec son motif, version), puis ses effets.
  PERFORM private.candidature_geste_appliquer(p_id, 'debloquer_versement', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('controle', 'versement_debloque'));
  UPDATE public.candidatures
     SET versement_debloque_le = pg_catalog.clock_timestamp(), versement_debloque_par = v_uid
   WHERE id = p_id;
  PERFORM private.paiement_recalculer(p_id, 'deblocage', v_uid, p_motif);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'debloquer_versement', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'paiement', private.paiement_etat(p_id)));
END;
$function$;

ALTER FUNCTION public.debloquer_versement_candidat(uuid, integer, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.debloquer_versement_candidat(uuid, integer, text, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.debloquer_versement_candidat(uuid, integer, text, text) TO authenticated;

-- ============================================================
-- 6. Empreintes F86 et controle final
-- ============================================================
DO $f86$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.capacites_candidatures()'::regprocedure,
                           'public.modifier_mon_pays_versement(text)'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'VERSEMENT-QUESTIONS') = 0 THEN
        v_com := v_com || ' VERSEMENT-QUESTIONS (16/11/2026) : ferme apres la validation du dossier ; geste debloquerVersement.';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.modifier_mon_versement(boolean, text, text[]) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.modifier_mon_versement(boolean,text,text[]); md5_functiondef=%s; guard_type=POSITIVE_CANDIDATE_SELF; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. VERSEMENT-QUESTIONS : titulaire d une candidature en cours, sinon 42501 ; compte, pays et services (referentiel du pays) ; permise seulement en prequalification, sinon modification_impossible ; nouvelle ligne de reponses, historique garde, paiement recalcule, coordonnees a valider si le pays change, deblocage de la direction leve ; jamais pour une autre personne. Must-pass: supabase/tests/scenarios_versement_questions.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef('public.modifier_mon_versement(boolean,text,text[])'::regprocedure))));
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.debloquer_versement_candidat(uuid, integer, text, text) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.debloquer_versement_candidat(uuid,integer,text,text); md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. VERSEMENT-QUESTIONS : direction active et de genre connu (moteur des gestes), candidature de son cote ; motif ecrit obligatoire, version attendue, cle d idempotence ; prequalification en examen ou en attente de paiement ; paiement compatible sans moyen declare, dossier de retour a a_completer ; trace (evenement controle, audit). Must-pass: supabase/tests/scenarios_versement_questions.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef('public.debloquer_versement_candidat(uuid,integer,text,text)'::regprocedure))));
END;
$f86$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.paiement_etat(uuid)'::regprocedure),
                       'versement_debloque_le') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.paiement_recalculer(uuid,text,uuid,text,uuid,boolean)'::regprocedure),
                          '''deblocage''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.modifier_mon_pays_versement(text)'::regprocedure),
                          'v_c.etape <> ''prequalification''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                          'debloquerVersement') = 0 THEN
    RAISE EXCEPTION 'VERSEMENT-QUESTIONS : retouche absente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles WHERE geste = 'debloquer_versement') THEN
    RAISE EXCEPTION 'VERSEMENT-QUESTIONS : regle du geste absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'VERSEMENT-QUESTIONS : droits inattendus';
  END IF;
END;
$postflight$;
