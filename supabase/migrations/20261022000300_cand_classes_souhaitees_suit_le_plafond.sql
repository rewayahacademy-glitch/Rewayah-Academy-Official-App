-- CLASSES-PLAFOND, suite (22/10/2026) : la question « combien de Classes
-- souhaitez-vous tenir ? » (classesSouhaitees) suit le maximum de Classes par
-- enseignant que regle la direction.
--
-- Decision du directeur (22/10) : trois Classes au plus par enseignant pour
-- l'instant, la direction peut le changer dans les reglages. Le reglage
-- (app_config enseignant.classes_max, 20261022000200) borne l'affectation.
-- Cette migration fait que le questionnaire le suive sans republier de
-- version : l'audit (CANDIDATURES/AUDIT_QUESTIONNAIRE_SALLE_EXAMEN_2026-10-22.md,
-- Statut) laissait le choix entre « publier salle-examen-2 » et « faire lire
-- le reglage a l'examen des reponses ».
--
-- Pourquoi pas une definition dynamique ni une version suivante : la
-- definition de salle-examen-1 est immuable (candidature_questionnaires_
-- immuable) et ses valeurs sont une liste fermee ["1", "2", "3"]. Et le MEME
-- examen (private.questionnaire_examiner) valide une reponse qu'on enregistre
-- et relit les reponses deja envoyees (etat_dossier(), controle
-- questionnaire_complet de L2A2) : une reponse valide le jour de l'envoi ne
-- doit JAMAIS devenir invalide parce que la direction a regle le maximum,
-- sinon l'admission d'une candidate serait bloquee pour un reglage qu'elle n'a
-- pas touche. Un examen qui ne retiendrait que 1..maximum en vigueur, ou que
-- les valeurs de la definition plus 1..maximum, ne tient pas cette promesse :
-- « 5 », valide au maximum de 5, devient invalide quand il redescend a 4.
--
-- Ce qui change, dans les deux fonctions du moteur seulement, et pour le seul
-- champ classesSouhaitees :
-- * questionnaire_options (ce que l'ecran propose) : de 1 au maximum en
--   vigueur. Maximum 3 : ["1", "2", "3"], comme avant. Maximum 2 : ["1", "2"].
--   Maximum 5 : ["1", ..., "5"] ;
-- * questionnaire_permis (ce que l'examen accepte) : tout nombre entier de 1 a
--   80, SANS lire le maximum en vigueur. 80 est la borne du reglage (le
--   declencheur app_config_classes_max refuse au-dela) : le maximum ne sort
--   jamais de 1..80, donc une reponse valide le reste a vie.
-- Ce que le serveur refuse vraiment, c'est a l'affectation (plafond_classes_
-- atteint) ; le souhait est une indication, il ne donne droit a aucune Classe.
-- Un appel direct de l'API avec « 4 » alors que le maximum est 3 est donc
-- accepte comme souhait : c'est voulu, et sans effet sur l'affectation. Seul
-- l'ecran borne ce qu'on propose.
--
-- Les corps sont ceux de 20261022000000 (L2A1, lignes de questionnaire_permis
-- et questionnaire_options), recopies a l'identique hors ce champ. CREATE OR
-- REPLACE garde le proprietaire, les droits (aucun EXECUTE client) et la
-- fixation du search_path ; la migration le verifie.
BEGIN;

-- Une valeur est-elle dans la liste fermee d'un champ ? Les operateurs : une
-- ligne mobile money a confirme du pays de versement declare (spec 5.1).
-- Les classes souhaitees : les valeurs de la definition, plus tout entier de 1
-- a 80, la borne du reglage de Classes par enseignant (CLASSES-PLAFOND).
CREATE OR REPLACE FUNCTION private.questionnaire_permis(p_definition jsonb, p_champ jsonb, p_valeur text,
                                             p_pays_versement text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_valeur IS NULL THEN
    RETURN false;
  ELSIF p_champ ? 'valeurs' THEN
    -- Les valeurs de la definition, et, pour classesSouhaitees, tout entier
    -- de 1 a 80 (la borne du reglage), sans lire le maximum en vigueur : une
    -- reponse valide a l'envoi ne devient pas invalide quand la direction
    -- regle le maximum (le meme examen relit les reponses envoyees :
    -- etat_dossier(), controle questionnaire_complet).
    RETURN (p_champ -> 'valeurs') ? p_valeur
           OR (p_champ ->> 'code' = 'classesSouhaitees'
               AND CASE WHEN p_valeur ~ '^[1-9][0-9]?$'
                        THEN p_valeur::integer <= 80
                        ELSE false END);
  ELSIF p_champ ->> 'liste' = 'langues' THEN
    -- Les codes que le champ exclut (C17) ne sont pas permis, meme saisis a la main.
    RETURN NOT coalesce((p_champ -> 'exclure') ? p_valeur, false)
           AND EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(private.questionnaire_langues(p_definition)) o
                       WHERE o ->> 'code' = p_valeur);
  ELSIF p_champ ->> 'liste' = 'pays' THEN
    RETURN EXISTS (SELECT 1 FROM private.pays_iso_3166 x WHERE x.code = p_valeur);
  ELSIF p_champ ->> 'liste' = 'fuseaux' THEN
    RETURN private.questionnaire_fuseau_propose(p_valeur);
  ELSIF p_champ ->> 'liste' = 'operateurs_confirmes' THEN
    RETURN p_pays_versement IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.referentiel_paiement l
       WHERE l.pays = p_pays_versement AND l.methode = 'mobile_money' AND l.etat = 'confirme'
         AND l.operateur = p_valeur);
  ELSIF p_champ ->> 'liste' = 'moyens_connus' THEN
    -- Tous les moyens connus du catalogue de L6, confirmes ou non, quel que
    -- soit le pays (C17) : un champ informatif, que rien ne lit.
    RETURN EXISTS (SELECT 1 FROM public.referentiel_paiement_operateurs o
                    WHERE o.code = p_valeur AND o.actif);
  END IF;
  RETURN false;
END;
$function$;

-- Les options rendues a l'ecran pour un champ (listes fermees lues au
-- serveur). Les operateurs dependent du pays de versement : l'ecran les lit
-- par options_paiement_confirmees (L6) ; rien ici. Les langues d'un champ
-- sans les codes qu'il exclut (C17). Les moyens connus : code, methode et nom
-- de marque de chaque operateur actif du catalogue, sans aucun pays ni etat.
-- Les classes souhaitees : de 1 au maximum de Classes par enseignant (CLASSES-
-- PLAFOND).
CREATE OR REPLACE FUNCTION private.questionnaire_options(p_definition jsonb, p_champ jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_champ ->> 'code' = 'classesSouhaitees' AND p_champ ? 'valeurs' THEN
    -- 1 jusqu'au maximum de Classes par enseignant en vigueur (CLASSES-
    -- PLAFOND), en codes de texte comme la definition : ["1", "2", "3"] tant
    -- que le maximum est de trois.
    RETURN (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n::text) ORDER BY n)
              FROM pg_catalog.generate_series(1, app_private.classes_max_par_enseignant()) AS n);
  ELSIF p_champ ? 'valeurs' THEN
    RETURN p_champ -> 'valeurs';
  ELSIF p_champ ->> 'liste' = 'langues' THEN
    RETURN (SELECT coalesce(pg_catalog.jsonb_agg(x.o ORDER BY x.rang), '[]'::jsonb)
              FROM pg_catalog.jsonb_array_elements(private.questionnaire_langues(p_definition))
                   WITH ORDINALITY AS x(o, rang)
             WHERE NOT coalesce((p_champ -> 'exclure') ? (x.o ->> 'code'), false));
  ELSIF p_champ ->> 'liste' = 'moyens_connus' THEN
    RETURN (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                     'code', o.code, 'methode', o.methode, 'nom', o.nom) ORDER BY o.cree_le, o.code), '[]'::jsonb)
              FROM public.referentiel_paiement_operateurs o
             WHERE o.actif);
  ELSIF p_champ ->> 'liste' = 'pays' THEN
    RETURN (SELECT pg_catalog.jsonb_agg(x.code ORDER BY x.rang) FROM private.pays_iso_3166 x);
  ELSIF p_champ ->> 'liste' = 'fuseaux' THEN
    RETURN (SELECT pg_catalog.jsonb_agg(z.name ORDER BY z.name)
              FROM pg_catalog.pg_timezone_names z
             WHERE z.name ~ private.questionnaire_fuseau_motif());
  END IF;
  RETURN NULL;
END;
$function$;

-- ------------------------------------------------------------------
-- Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_def jsonb;
  v_champ jsonb;
  v_max integer := app_private.classes_max_par_enseignant();
  v_valeur text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
      pg_catalog.to_regprocedure('private.questionnaire_permis(jsonb,jsonb,text,text)'),
      pg_catalog.to_regprocedure('private.questionnaire_options(jsonb,jsonb)')] LOOP
    IF v_f IS NULL THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : fonction absente';
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    -- Les options lisent le maximum ; l'examen (permis) ne le lit PAS : une
    -- reponse valide a l'envoi ne doit jamais devenir invalide par un reglage.
    IF v_p.prosecdef OR v_p.provolatile <> 's'
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.strpos(v_p.prosrc, 'classesSouhaitees') = 0
       OR (pg_catalog.strpos(v_p.prosrc, 'app_private.classes_max_par_enseignant()') = 0)
          IS DISTINCT FROM (v_f = pg_catalog.to_regprocedure('private.questionnaire_permis(jsonb,jsonb,text,text)')) THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : % : STABLE, INVOKER, a postgres, search_path vide ; les options lisent le maximum, l''examen non', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;
  -- Les options rendues pour classesSouhaitees : 1 jusqu'au maximum. L'examen
  -- accepte tout entier de 1 a 80 quel que soit le maximum en vigueur (essaye
  -- a 1, a 3 et a 80), et rien d'autre.
  SELECT q.definition INTO v_def FROM public.candidature_questionnaires q WHERE q.version = 'salle-examen-1';
  SELECT c INTO v_champ FROM pg_catalog.jsonb_array_elements(v_def -> 'champs') c
   WHERE c ->> 'code' = 'classesSouhaitees';
  IF v_champ IS NULL
     OR private.questionnaire_options(v_def, v_champ) IS DISTINCT FROM (
          SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n::text) ORDER BY n)
            FROM pg_catalog.generate_series(1, v_max) AS n) THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : les options de classesSouhaitees ne suivent pas le maximum de Classes';
  END IF;
  FOREACH v_valeur IN ARRAY ARRAY['1', '2', '3', '4', '5', '9', '10', '45', '79', '80'] LOOP
    IF NOT private.questionnaire_permis(v_def, v_champ, v_valeur, NULL) THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : % doit etre permis (entier de 1 a 80)', v_valeur;
    END IF;
  END LOOP;
  FOREACH v_valeur IN ARRAY ARRAY['0', '00', '01', '81', '99', '100', '-1', '+3', '3.0', ' 3', 'x', ''] LOOP
    IF private.questionnaire_permis(v_def, v_champ, v_valeur, NULL) THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND (questionnaire) : « % » ne doit pas etre permis', v_valeur;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
