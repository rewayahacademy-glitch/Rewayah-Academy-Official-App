-- PE-A6 REPRISE-CANDIDATURE (directeur, 19/11/2026 : « Retrait : 7 jours d'accord, a condition que le candidat
-- comprenne par l'ecran ce qui lui arrive ; jamais de silence », PARCOURS-ENSEIGNANT/PLAN, arbitrage A8 et §13.2).
--
-- Le constat (PLAN §2.5, lu en production le 19/11) : 20 candidats ont retire leur candidature eux-memes ; 7 ont ete
-- rouverts par l'equipe apres 2 a 94 heures d'attente, 13 sont restes retires, 4 ont ecrit « je me suis trompe ».
-- Aujourd'hui seule la direction rouvre (public.rouvrir_candidat, transition 19).
--
-- Ce que ce fichier ajoute : le candidat enseignant qui a retire LUI-MEME sa candidature peut la reprendre lui-meme
-- pendant 7 jours. Apres 7 jours, ou si le retrait a ete consigne par la direction, rien ne change : seule la
-- direction rouvre, comme avant.
--
--   1. une regle de plus dans private.candidature_gestes_regles : le geste `reprendre`, auteur `candidat`, depuis
--      l'issue `retiree`, vers `en_cours` (la meme cible que `rouvrir`, la meme transition 19 : c'est une reouverture,
--      faite par une autre personne). L'etape et l'etat ne bougent pas : le retrait ne les avait pas changes, sauf
--      l'entretien annule par le declencheur de 20261129460000, qui a deja ramene « entretien planifie » a
--      « entretien a planifier » ;
--   2. private.candidature_reprise_delai() : les 7 jours, a un seul endroit ;
--   3. private.candidature_dernier_retrait(uuid) : la date du dernier retrait et qui l'a fait, lus dans
--      public.candidature_evenements (l'evenement de la transition 17, ecrit par le moteur) ;
--   4. private.candidature_reprise(candidatures) et une cle de plus, `reprise`, dans le bloc candidature de
--      public.etat_dossier() (private.candidature_etat_candidat()) : la lecture, pour l'ecran. Elle dit le delai,
--      et pour une candidature retiree jusqu'a quand elle se reprend, ou sinon pourquoi (delai passe, retrait fait
--      par la direction, un element a change). L'ecran n'en deduit rien : il affiche. Aucune fonction publique de
--      lecture n'est ajoutee : etat_dossier() reste la seule lecture de l'etat du candidat (contrat des ports,
--      section 3 ; scenarios CAND-L2A1, L2A2 et L3) ;
--   5. public.reprise_candidat(integer, text) : le geste, par le moteur (version attendue, cle d'idempotence,
--      evenement, audit), sous les MEMES controles que la reouverture par la direction
--      (private.candidature_controles_entree, « reouverture »), puis le meme recalcul du versement
--      (private.paiement_recalculer, cause reouverture). Un controle faux ne rouvre rien : il est rendu
--      (`controles_non_satisfaits`), et la direction reste la voie.
--
-- Ce qui n'est PAS ici : prevenir la direction qu'une candidature a ete reprise (l'evenement est dans l'historique du
-- dossier ; une notification demande un evenement de plus dans la liste de production) ; les candidatures de famille
-- et d'eleve adulte (elles ont leurs gestes d'admission : la reprise les refuse, comme public.rouvrir_candidat).
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement, commentaires compris. Additif : une ligne de regle,
-- quatre fonctions neuves. UNE fonction en place est remplacee, private.candidature_etat_candidat(), par CREATE OR
-- REPLACE a signature identique, apres controle de son empreinte md5(prosrc) (methode de 20261130300000) : son corps
-- est celui de la derniere definition (20261128400000), recopie par pg_get_functiondef sur une base rejouee jusqu'a
-- 20261130400000, avec une seule cle de plus a la fin. Une seule ecriture, la ligne de regle (une table de reglages
-- du moteur, aucune donnee de personne). Sans BEGIN/COMMIT de premier niveau.
-- Doit suivre 20261129760000 (derniere regle du moteur) et 20261129460000 (l'entretien suit le dossier).

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.candidature_gestes_regles') IS NULL
     OR pg_catalog.to_regclass('public.candidature_evenements') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)') IS NULL
     OR pg_catalog.to_regprocedure(
          'private.candidature_geste_appliquer(uuid,text,smallint,text,uuid,text,text,jsonb,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_geste_conclure(text,uuid,text,uuid,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_entree(public.candidatures,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_faux(jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_du_titulaire(boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.paiement_recalculer(uuid,text,uuid,text,uuid,boolean)') IS NULL
     OR pg_catalog.to_regprocedure('public.etat_dossier()') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_etat_candidat()') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_regle(public.candidatures,text,text,smallint,boolean)') IS NULL THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : dependances absentes (moteur des candidatures)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.candidatures'::regclass AND t.tgname = 'candidatures_entretien_suit') THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : le declencheur candidatures_entretien_suit (20261129460000) est attendu';
  END IF;
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = 'reprendre')
     OR pg_catalog.to_regprocedure('public.reprise_candidat(integer,text)') IS NOT NULL
     OR pg_catalog.to_regprocedure('private.candidature_reprise(public.candidatures)') IS NOT NULL THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : deja installee';
  END IF;
  -- La fonction remplacee plus bas : son empreinte doit etre celle de la definition recopiee ici.
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.candidature_etat_candidat()'::pg_catalog.regprocedure)
     IS DISTINCT FROM 'e98d243b0e31b90022a388ef6ad52594' THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : private.candidature_etat_candidat() a change depuis 20261128400000 (empreinte inattendue) : recopier sa derniere definition avant d''installer';
  END IF;
  -- La regle de la reouverture par la direction, dont la reprise copie la cible : si elle a change, on s'arrete.
  IF NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                  WHERE r.geste = 'rouvrir' AND r.variante = 1 AND r.transition = 19
                    AND r.cible = '{"issue": "en_cours", "issue_modele": null}'::jsonb
                    AND 'retiree' = ANY (r.issues)) THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : la regle « rouvrir » (transition 19) n''est plus celle attendue';
  END IF;
END
$preflight$;

-- ============================================================
-- 1. La regle du moteur
-- ============================================================
-- Hors pause (un retrait leve la pause : la cible de la transition 17 pose en_pause a faux). Sans motif : le candidat
-- n'a pas a se justifier.
-- Deux etapes seulement : celles ou la personne a un compte et a pu retirer elle-meme (salle 1 et salle 2).
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('reprendre', 1, 19, '{candidat}', '{prequalification,verifications}', NULL,
   '{retiree}', 'interdite', NULL, '{}', NULL, false, 'transition',
   '{"issue": "en_cours", "issue_modele": null}', '{}', false);

-- ============================================================
-- 2. Le delai : 7 jours, a un seul endroit
-- ============================================================
CREATE FUNCTION private.candidature_reprise_delai()
RETURNS interval
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT interval '7 days';
$function$;
ALTER FUNCTION private.candidature_reprise_delai() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_reprise_delai() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 3. Le dernier retrait d'une candidature
-- ============================================================
-- L'evenement de la transition 17, ecrit par le moteur (details.geste = retirer, details.auteur = candidat ou
-- direction). Aucune ligne : la candidature n'a jamais ete retiree par le moteur.
CREATE FUNCTION private.candidature_dernier_retrait(p_candidature uuid)
RETURNS TABLE (retiree_le timestamptz, par_le_candidat boolean)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT e.cree_le, coalesce(e.details ->> 'auteur' = 'candidat', false)
    FROM public.candidature_evenements e
   WHERE e.candidature_id = p_candidature
     AND e.type = 'transition'
     AND e.details ->> 'geste' = 'retirer'
     AND e.issue_apres = 'retiree'
   ORDER BY e.id DESC
   LIMIT 1;
$function$;
ALTER FUNCTION private.candidature_dernier_retrait(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_dernier_retrait(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 4. La lecture, dans etat_dossier()
-- ============================================================
-- Rend toujours `delaiJours` (l'ecran qui explique le retrait le dit AVANT le geste). Quand la candidature est
-- retiree : `retireeLe`, `parLeCandidat`, `repriseJusquAu`, `possible` et, si elle ne se reprend pas, `raison` :
-- `type`, `retrait_par_la_direction`, `delai_depasse` ou `controles_non_satisfaits`. Jamais un motif interne ni le
-- detail d'un controle.
CREATE FUNCTION private.candidature_reprise(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_delai interval := private.candidature_reprise_delai();
  v_jours integer := (pg_catalog.date_part('day', private.candidature_reprise_delai()))::integer;
  v_le timestamptz;
  v_par boolean;
  v_raison text;
BEGIN
  IF c.id IS NULL OR c.issue IS DISTINCT FROM 'retiree' THEN
    RETURN pg_catalog.jsonb_build_object('delaiJours', v_jours);
  END IF;
  SELECT r.retiree_le, r.par_le_candidat INTO v_le, v_par FROM private.candidature_dernier_retrait(c.id) r;
  v_raison := CASE
    WHEN c.type_code IS DISTINCT FROM 'enseignant' THEN 'type'
    WHEN v_le IS NULL OR NOT coalesce(v_par, false) THEN 'retrait_par_la_direction'
    WHEN pg_catalog.clock_timestamp() >= v_le + v_delai THEN 'delai_depasse'
    WHEN (private.candidature_regle(c, 'reprendre', 'candidat', NULL, false)).geste IS NULL
      THEN 'controles_non_satisfaits'
    WHEN pg_catalog.jsonb_array_length(private.candidature_controles_faux(
           private.candidature_controles_entree(c, 'reouverture'))) > 0 THEN 'controles_non_satisfaits'
  END;
  RETURN pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
    'delaiJours', v_jours,
    'retireeLe', private.cand_instant(v_le),
    'parLeCandidat', coalesce(v_par, false),
    'repriseJusquAu', CASE WHEN coalesce(v_par, false) THEN private.cand_instant(v_le + v_delai) END,
    'possible', v_raison IS NULL,
    'raison', v_raison));
END;
$function$;
ALTER FUNCTION private.candidature_reprise(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_reprise(public.candidatures)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le bloc candidature d'etat_dossier() : le corps de 20261128400000, recopie, plus la cle `reprise`.
CREATE OR REPLACE FUNCTION private.candidature_etat_candidat()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_base jsonb := private.cand_ma_candidature();
  v_c public.candidatures;
  v_q public.candidature_questionnaires;
  v_doc public.candidature_reponses;
  v_ex jsonb;
  v_manquants jsonb := '[]'::jsonb;
  v_perime boolean;
  v_cadre text;
  v_cadre_ok boolean := false;
  v_cond jsonb;
  v_cond_ok boolean := false;
  v_salle_examen boolean;
  v_salle_verification boolean;
  v_bloque text[] := ARRAY[]::text[];
  v_a_completer text[] := ARRAY[]::text[];
  v_demande public.candidature_evenements;
  v_complement jsonb := '[]'::jsonb;
BEGIN
  IF NOT coalesce((v_base ->> 'candidature')::boolean, false) THEN
    RETURN v_base;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = v_base ->> 'reference';
  v_q := private.questionnaire_courant(v_c.type_code);
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_c.id AND r.source = 'candidat'
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  v_perime := v_doc.id IS NOT NULL AND v_doc.questionnaire_version IS DISTINCT FROM v_q.version;
  IF v_q.version IS NOT NULL THEN
    IF v_doc.id IS NOT NULL AND NOT v_perime THEN
      v_ex := private.questionnaire_examiner(v_q.definition, v_doc.reponses);
      v_manquants := (v_ex -> 'manquants') || (v_ex -> 'invalides');
    ELSE
      SELECT coalesce(pg_catalog.jsonb_agg(x.c ->> 'code' ORDER BY x.o), '[]'::jsonb) INTO v_manquants
        FROM pg_catalog.jsonb_array_elements(v_q.definition -> 'champs') WITH ORDINALITY AS x(c, o)
       WHERE (x.c ->> 'requis')::boolean;
    END IF;
  END IF;

  v_cadre := public.cadre_religieux_version_requise();
  IF v_cadre IS NOT NULL THEN
    v_cadre_ok := EXISTS (SELECT 1 FROM public.contract_acceptances a
                           WHERE a.profile_id = v_c.profile_id
                             AND a.contract_kind = 'teacher_religious_framework'
                             AND a.version = v_cadre);
  END IF;
  v_cond := private.conditions_remuneration_applicables();
  IF v_cond IS NOT NULL THEN
    v_cond_ok := EXISTS (SELECT 1 FROM public.contract_acceptances a
                          WHERE a.profile_id = v_c.profile_id
                            AND a.contract_kind = 'teacher_pay_conditions'
                            AND a.version = v_cond ->> 'version');
  END IF;

  v_salle_examen := coalesce(v_c.etape = 'prequalification' AND v_c.etat = 'a_completer'
                             AND v_c.issue = 'en_cours', false);
  v_salle_verification := coalesce(v_c.etape = 'verifications' AND v_c.issue = 'en_cours', false);
  IF NOT v_salle_examen THEN
    v_bloque := v_bloque || 'etat'::text;
  END IF;
  IF v_c.en_pause THEN
    v_bloque := v_bloque || 'pause'::text;
  END IF;
  IF v_q.version IS NULL THEN
    v_bloque := v_bloque || 'questionnaire_absent'::text;
  ELSIF v_perime THEN
    v_bloque := v_bloque || 'questionnaire_perime'::text;
  ELSIF pg_catalog.jsonb_array_length(v_manquants) > 0 THEN
    v_bloque := v_bloque || 'questionnaire_incomplet'::text;
  END IF;
  IF v_cadre IS NULL THEN
    v_bloque := v_bloque || 'cadre_non_publie'::text;
  ELSIF NOT v_cadre_ok THEN
    v_bloque := v_bloque || 'cadre_non_accepte'::text;
  END IF;
  IF v_cond IS NULL THEN
    v_bloque := v_bloque || 'conditions_indisponibles'::text;
  END IF;
  -- Ce qui reste a completer, hors pause : en Salle d'examen, le
  -- questionnaire et le cadre religieux ; en Salle de verification et
  -- d'entretien, le cadre religieux quand une version requise neuve n'est pas
  -- encore acceptee (4.3 : re-acceptee avant la salle 3).
  IF NOT v_c.en_pause THEN
    IF v_salle_examen AND (v_perime OR pg_catalog.jsonb_array_length(v_manquants) > 0) THEN
      v_a_completer := v_a_completer || 'questionnaire'::text;
    END IF;
    IF (v_salle_examen OR v_salle_verification) AND v_cadre IS NOT NULL AND NOT v_cadre_ok THEN
      v_a_completer := v_a_completer || 'cadre_religieux'::text;
    END IF;
  END IF;

  -- Ce que la direction a demande (C12) : les codes de details.aCompleter du
  -- dernier evenement de transition qui en porte (7, 9, 23), tant que l'etape
  -- n'a pas change, que l'issue est en cours et qu'aucun envoi (transition 6)
  -- ne l'a suivi. Jamais un motif.
  SELECT e.* INTO v_demande
    FROM public.candidature_evenements e
   WHERE e.candidature_id = v_c.id AND e.type = 'transition'
     AND pg_catalog.jsonb_typeof(e.details -> 'aCompleter') = 'array'
   ORDER BY e.cree_le DESC, e.id DESC
   LIMIT 1;
  IF v_demande.id IS NOT NULL AND v_c.issue = 'en_cours'
     AND v_c.etape IS NOT DISTINCT FROM v_demande.etape_apres
     AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                      WHERE e.candidature_id = v_c.id AND e.type = 'transition'
                        AND e.details ->> 'transition' = '6'
                        AND (e.cree_le, e.id) > (v_demande.cree_le, v_demande.id)) THEN
    SELECT coalesce(pg_catalog.jsonb_agg(a.x ORDER BY a.o), '[]'::jsonb) INTO v_complement
      FROM pg_catalog.jsonb_array_elements(v_demande.details -> 'aCompleter') WITH ORDINALITY AS a(x, o)
     WHERE pg_catalog.jsonb_typeof(a.x) = 'string' AND (a.x #>> '{}') ~ '^[a-z][a-z0-9_]{1,59}$';
  END IF;

  RETURN v_base || pg_catalog.jsonb_build_object(
    'version', v_c.version,
    'pauseModele', CASE WHEN v_c.en_pause THEN v_c.pause_modele END,
    'refusModele', CASE WHEN v_c.issue = 'refusee' THEN v_c.issue_modele END,
    'questionnaire', pg_catalog.jsonb_build_object(
      'versionCourante', v_q.version,
      'versionReponses', v_doc.questionnaire_version,
      'perime', v_perime,
      'envoyeLe', private.cand_instant(v_doc.envoye_le),
      'manquants', v_manquants),
    'cadreReligieux', pg_catalog.jsonb_build_object('versionRequise', v_cadre, 'accepte', v_cadre_ok),
    'conditionsRemuneration', pg_catalog.jsonb_build_object(
      'disponible', v_cond IS NOT NULL, 'version', v_cond ->> 'version', 'acceptees', v_cond_ok),
    -- La dimension paiement de L6, en direct, sur la declaration envoyee
    -- (C8) : inconnu, a_verifier, compatible ou incompatible, rien d'autre.
    'paiement', private.paiement_etat(v_c.id),
    -- MAJEUR : l'attestation « 18 ans ou plus », nulle tant qu'elle n'est pas faite.
    'majorite', pg_catalog.jsonb_build_object(
      'declaree', v_c.majorite_declaree,
      'attesteeLe', private.cand_instant(v_c.majorite_attestee_le)),
    'aCompleter', pg_catalog.to_jsonb(v_a_completer),
    'complementDemande', v_complement,
    -- COMPLEMENT-ET-FORMATS : la date de la demande en cours, nulle sans demande.
    'complementDemandeLe', CASE WHEN pg_catalog.jsonb_array_length(v_complement) > 0
      THEN private.cand_instant(v_demande.cree_le) END,
    'peutEnvoyer', pg_catalog.cardinality(v_bloque) = 0,
    'envoiBloque', pg_catalog.to_jsonb(v_bloque),
    -- REPRISE-CANDIDATURE (PE-A6) : le delai de reprise, et pour une candidature retiree ce que la personne peut
    -- faire elle-meme (date limite, ou la raison pour laquelle seule la direction rouvre).
    'reprise', private.candidature_reprise(v_c));
END;
$function$;

-- ============================================================
-- 5. Le geste : reprendre sa candidature
-- ============================================================
-- Rend le bloc candidature relu (comme public.retrait_candidat), le premier resultat rejoue sous la meme cle, ou un
-- refus rendu : `conflit_candidature`, `transition_interdite` (la candidature n'est pas retiree), `reprise_fermee`
-- avec sa `raison` (`type`, `retrait_par_la_direction`, `delai_depasse`), `controles_non_satisfaits`.
CREATE FUNCTION public.reprise_candidat(p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(false);
  v_o jsonb;
  v_c public.candidatures;
  v_delai interval := private.candidature_reprise_delai();
  v_le timestamptz;
  v_par boolean;
  v_controles jsonb;
  v_faux jsonb;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'reprise reservee au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce((SELECT c.type_code = 'enseignant' FROM public.candidatures c WHERE c.id = v_id), false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reprise_fermee', 'raison', 'type');
  END IF;
  -- Le moteur verrouille la ligne, lit la cle, compare la version, puis la regle (issue retiree, hors pause).
  v_o := private.candidature_geste_ouvrir(v_id, 'reprendre', 'candidat', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  SELECT r.retiree_le, r.par_le_candidat INTO v_le, v_par FROM private.candidature_dernier_retrait(v_id) r;
  -- Seul un retrait fait par la personne elle-meme se reprend par elle.
  IF NOT coalesce(v_le IS NOT NULL AND v_par, false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reprise_fermee', 'raison', 'retrait_par_la_direction');
  END IF;
  IF NOT coalesce(pg_catalog.clock_timestamp() < v_le + v_delai, false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reprise_fermee', 'raison', 'delai_depasse',
                                         'repriseJusquAu', private.cand_instant(v_le + v_delai));
  END IF;
  -- Les controles de la reouverture (D7), ceux de public.rouvrir_candidat : compte conforme, questionnaire a jour
  -- apres un envoi, et en salle 2 versement compatible et cadre a la version requise.
  v_controles := private.candidature_controles_entree(v_c, 'reouverture');
  v_faux := private.candidature_controles_faux(v_controles);
  IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits', 'controles', v_faux);
  END IF;
  PERFORM private.candidature_geste_appliquer(v_id, 'reprendre', (v_o ->> 'variante')::smallint,
    'candidat', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('canal', 'application', 'issueAvant', v_c.issue,
                                  'retireeLe', private.cand_instant(v_le), 'controles', v_controles));
  PERFORM private.paiement_recalculer(v_id, 'reouverture');
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_id, 'reprendre', v_uid,
    pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature'));
END;
$function$;
ALTER FUNCTION public.reprise_candidat(integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reprise_candidat(integer, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.reprise_candidat(integer, text) TO authenticated;

-- ============================================================
-- 6. Empreinte F86 et controle final
-- ============================================================
DO $f86$
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.reprise_candidat(integer, text) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.reprise_candidat(integer,text); md5_functiondef=%s; guard_type=POSITIVE_CANDIDATE_SELF_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-20. REPRISE-CANDIDATURE (PE-A6) : titulaire d une candidature d enseignant au compte valide, sinon 42501 ; par le moteur (version attendue, cle d idempotence, evenement, audit) ; seulement une candidature retiree par la personne elle-meme depuis moins de 7 jours, sous les controles de la reouverture (D7) ; puis recalcul du versement ; un refus est rendu, rien n est ecrit. Must-pass: supabase/tests/scenarios_reprise_candidature.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef('public.reprise_candidat(integer,text)'::regprocedure))));
END;
$f86$;

DO $postflight$
DECLARE
  f text;
BEGIN
  IF (SELECT count(*) FROM private.candidature_gestes_regles r
       WHERE r.geste = 'reprendre' AND r.variante = 1 AND r.transition = 19
         AND r.auteurs = '{candidat}'::text[] AND r.issues = '{retiree}'::text[]
         AND r.etapes = '{prequalification,verifications}'::text[]
         AND r.pause = 'interdite' AND r.type_evenement = 'transition' AND NOT r.brouillon) <> 1 THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : regle « reprendre » absente ou inattendue';
  END IF;
  IF private.candidature_reprise_delai() <> interval '7 days' THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : delai inattendu';
  END IF;
  -- La retouche : la cle `reprise` est la, et rien d'autre n'a bouge (meme texte, cette cle en moins).
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_etat_candidat()'::regprocedure),
                       '''reprise'', private.candidature_reprise(v_c)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_etat_candidat()'::regprocedure),
                          '''majorite''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_etat_candidat()'::regprocedure),
                          '''complementDemandeLe''') = 0 THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : retouche de private.candidature_etat_candidat() absente ou incomplete';
  END IF;
  IF (SELECT p.prosecdef OR p.provolatile <> 's' OR NOT (p.proconfig @> ARRAY['search_path=""'])
        FROM pg_catalog.pg_proc p WHERE p.oid = 'private.candidature_etat_candidat()'::regprocedure) THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : private.candidature_etat_candidat() a change de nature';
  END IF;
  f := 'public.reprise_candidat(integer,text)';
  IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : droits inattendus sur %', f;
  END IF;
  IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
            FROM pg_catalog.pg_proc p WHERE p.oid = f::regprocedure) THEN
    RAISE EXCEPTION 'REPRISE-CANDIDATURE : % sans SECURITY DEFINER ou sans search_path vide', f;
  END IF;
  FOREACH f IN ARRAY ARRAY['private.candidature_reprise_delai()', 'private.candidature_dernier_retrait(uuid)',
                           'private.candidature_reprise(public.candidatures)',
                           'private.candidature_etat_candidat()'] LOOP
    IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'REPRISE-CANDIDATURE : % ouverte a un role client', f;
    END IF;
  END LOOP;
END;
$postflight$;
