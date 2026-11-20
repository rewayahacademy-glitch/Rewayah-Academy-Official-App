-- PE-B1 (parcours de l'enseignant, vague B, 20/11/2026) : le candidat dit le NOMBRE EXACT de juz qu'il a memorises.
--
-- Decision du directeur (plan du parcours, arbitrage A10, confirme le 19/11 au §12.1) : « Tout le Coran », « Rien pour l'instant »,
-- ou « Un nombre de juz » (de 1 a 29). Les anciennes reponses restent lisibles telles quelles.
--
-- FORMAT. Le champ niveauMemorisationDeclare garde ses quatre codes (aucune, moins_10_juz, de_10_a_29_juz, coran_entier), qui restent
-- valides a vie et se relisent sans changement ; il accepte EN PLUS « juz_1 » a « juz_29 ». Le formulaire n'ecrit plus que aucune,
-- coran_entier ou juz_N ; moins_10_juz et de_10_a_29_juz ne sont plus proposes mais restent permis (une reponse deja donnee ne
-- devient jamais invalide).
--
-- POURQUOI PAS UNE VERSION SUIVANTE DU QUESTIONNAIRE (salle-examen-3) : etat_dossier() compte comme MANQUANTS tous les champs requis
-- d'un document de reponses dont la version n'est pas la courante. Publier une version rendrait « perimees » les reponses de
-- centaines de candidats deja envoyees. La definition de salle-examen-2 est immuable (candidature_questionnaires_immuable). On suit
-- donc la methode deja employee pour classesSouhaitees (20261022000300_cand_classes_souhaitees_suit_le_plafond.sql) : les deux
-- fonctions du moteur, pour ce seul champ.
--
-- CE QUI CHANGE, et pour le seul champ niveauMemorisationDeclare :
--   * private.questionnaire_permis (ce que l'examen accepte) : les valeurs de la definition, plus juz_1 a juz_29, rien d'autre
--     (ni juz_0, ni juz_30, ni juz_01) ;
--   * private.questionnaire_options (ce que l'ecran recoit) : les valeurs de la definition, puis juz_1 a juz_29. Un ecran d'avant
--     ce lot ne montre que les options qui ont un texte : il ne voit pas les juz_N et reste tel quel.
-- Les deux corps sont les DERNIERS installes, recopies a l'identique hors ce champ, apres controle de l'empreinte md5(prosrc) :
-- questionnaire_permis tel que 20261022000300 l'a laisse ; questionnaire_options tel que 20261126000000 (PERF-FUSEAUX-Q) l'a
-- laisse, qui lit les fuseaux dans la table figee app_private.fuseaux_connus et plus dans pg_timezone_names (508 ms par appel en
-- production le 14/11). Le controle final refuse tout corps qui relirait pg_timezone_names. CREATE OR REPLACE a signature identique : proprietaire, droits (aucun EXECUTE client) et search_path vide
-- conserves ; le controle final le verifie.
--
-- LECTEURS de niveauMemorisationDeclare (releve du 20/11 sur une base rejouee jusqu'a 20261130400000) :
--   * private.questionnaire_examiner -> permis : juz_N valide (enregistrer, envoyer, etat_dossier, formulaires_prerempli) ;
--   * questionnaire_salle_examen() -> options : juz_N propose ;
--   * lire_candidature (dossier de la direction), private.candidature_questionnaire_envoye, praxis_dossier / private.praxis_reponses :
--     rendent le JSON tel quel, juz_N y passe sans traitement ;
--   * private.be_predicat (filtres de lister_candidatures, voisins_candidature, lister_enseignants) : aucun filtre sur la memorisation ;
--   * private.formulaires_lire (import des formulaires) : ecrit les anciens codes, inchange ;
--   * entretien_comptes_rendus.memorisation_observee (CHECK sur les quatre anciens codes) : constat ECRIT PAR LA DIRECTION a
--     l'entretien, autre donnee, jamais rempli depuis la reponse du candidat : non touche.
-- MOTS D'EFFACEMENT : zero. Rien d'autre n'est modifie. Rien n'est allume.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('private.questionnaire_permis(jsonb,jsonb,text,text)', '89f3a8dc92a4e98b6ec32a70649d3bb9'),
      ('private.questionnaire_options(jsonb,jsonb)', 'ff0a652a157623d97902c98783fce961')) AS t(f, md5) LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL THEN
      RAISE EXCEPTION 'PE-B1 : % absente ; rien n''est modifie', v.f;
    END IF;
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = pg_catalog.to_regprocedure(v.f)) IS DISTINCT FROM v.md5 THEN
      IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = pg_catalog.to_regprocedure(v.f)), 'PE-B1') > 0 THEN
        RAISE EXCEPTION 'PE-B1 : deja installe ; rien n''est modifie';
      END IF;
      RAISE EXCEPTION 'PE-B1 : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM public.candidature_questionnaires q, pg_catalog.jsonb_array_elements(q.definition -> 'champs') c
                  WHERE q.courant AND q.type_code = 'enseignant' AND c ->> 'code' = 'niveauMemorisationDeclare'
                    AND c -> 'valeurs' = '["aucune", "moins_10_juz", "de_10_a_29_juz", "coran_entier"]'::jsonb) THEN
    RAISE EXCEPTION 'PE-B1 : le questionnaire courant ne porte pas niveauMemorisationDeclare tel qu''attendu ; rien n''est modifie';
  END IF;
END
$preflight$;

-- Une valeur est-elle dans la liste fermee d'un champ ? Les operateurs : une
-- ligne mobile money a confirme du pays de versement declare (spec 5.1).
-- Les classes souhaitees : les valeurs de la definition, plus tout entier de 1
-- a 80, la borne du reglage de Classes par enseignant (CLASSES-PLAFOND).
-- La memorisation : les valeurs de la definition, plus juz_1 a juz_29 (PE-B1).
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
    -- PE-B1 : pour niveauMemorisationDeclare, le nombre exact de juz, de
    -- juz_1 a juz_29 (tout le Coran et rien restent coran_entier et aucune).
    RETURN (p_champ -> 'valeurs') ? p_valeur
           OR (p_champ ->> 'code' = 'classesSouhaitees'
               AND CASE WHEN p_valeur ~ '^[1-9][0-9]?$'
                        THEN p_valeur::integer <= 80
                        ELSE false END)
           OR (p_champ ->> 'code' = 'niveauMemorisationDeclare'
               AND p_valeur ~ '^juz_([1-9]|1[0-9]|2[0-9])$');
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
-- PLAFOND). La memorisation : les valeurs de la definition, puis juz_1 a
-- juz_29 (PE-B1).
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
  ELSIF p_champ ->> 'code' = 'niveauMemorisationDeclare' AND p_champ ? 'valeurs' THEN
    -- PE-B1 : les valeurs de la definition (les anciennes reponses se
    -- relisent), puis le nombre exact de juz, juz_1 a juz_29.
    RETURN (p_champ -> 'valeurs')
           || (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb('juz_' || n::text) ORDER BY n)
                 FROM pg_catalog.generate_series(1, 29) AS n);
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
    RETURN (SELECT pg_catalog.jsonb_agg(z.nom ORDER BY z.nom)
              FROM app_private.fuseaux_connus z
             WHERE z.nom ~ private.questionnaire_fuseau_motif());
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
  v_classes jsonb;
  v_valeur text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
      pg_catalog.to_regprocedure('private.questionnaire_permis(jsonb,jsonb,text,text)'),
      pg_catalog.to_regprocedure('private.questionnaire_options(jsonb,jsonb)')] LOOP
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF v_p.prosecdef OR v_p.provolatile <> 's'
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.strpos(v_p.prosrc, 'classesSouhaitees') = 0
       OR pg_catalog.strpos(v_p.prosrc, 'niveauMemorisationDeclare') = 0
       OR pg_catalog.strpos(v_p.prosrc, 'pg_timezone_names') > 0 THEN
      RAISE EXCEPTION 'PE-B1 : % : STABLE, INVOKER, a postgres, search_path vide, classes et memorisation, sans pg_timezone_names', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'PE-B1 : % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;
  SELECT q.definition INTO v_def FROM public.candidature_questionnaires q WHERE q.courant AND q.type_code = 'enseignant';
  SELECT c INTO v_champ FROM pg_catalog.jsonb_array_elements(v_def -> 'champs') c WHERE c ->> 'code' = 'niveauMemorisationDeclare';
  -- Les anciennes valeurs restent permises, et juz_1 a juz_29 le sont ; rien d'autre.
  FOREACH v_valeur IN ARRAY ARRAY['aucune', 'moins_10_juz', 'de_10_a_29_juz', 'coran_entier', 'juz_1', 'juz_9', 'juz_10',
                                  'juz_12', 'juz_19', 'juz_20', 'juz_29'] LOOP
    IF NOT private.questionnaire_permis(v_def, v_champ, v_valeur, NULL) THEN
      RAISE EXCEPTION 'PE-B1 : % doit etre permis', v_valeur;
    END IF;
  END LOOP;
  FOREACH v_valeur IN ARRAY ARRAY['juz_0', 'juz_00', 'juz_01', 'juz_30', 'juz_99', 'juz_', 'juz_1 ', 'JUZ_1', '12', 'juz_-1', ''] LOOP
    IF private.questionnaire_permis(v_def, v_champ, v_valeur, NULL) THEN
      RAISE EXCEPTION 'PE-B1 : « % » ne doit pas etre permis', v_valeur;
    END IF;
  END LOOP;
  IF private.questionnaire_options(v_def, v_champ) IS DISTINCT FROM (
       '["aucune", "moins_10_juz", "de_10_a_29_juz", "coran_entier"]'::jsonb
       || (SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb('juz_' || n::text) ORDER BY n) FROM pg_catalog.generate_series(1, 29) n)) THEN
    RAISE EXCEPTION 'PE-B1 : les options de niveauMemorisationDeclare sont inattendues';
  END IF;
  -- Les fuseaux se lisent dans la table figee (PERF-FUSEAUX-Q).
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = pg_catalog.to_regprocedure('private.questionnaire_options(jsonb,jsonb)')),
                       'app_private.fuseaux_connus') = 0 THEN
    RAISE EXCEPTION 'PE-B1 : questionnaire_options ne lit plus app_private.fuseaux_connus';
  END IF;
  -- Un autre champ a valeurs n'accepte pas juz_N, et classesSouhaitees suit toujours le maximum.
  SELECT c INTO v_champ FROM pg_catalog.jsonb_array_elements(v_def -> 'champs') c WHERE c ->> 'code' = 'ijazaPresentable';
  IF private.questionnaire_permis(v_def, v_champ, 'juz_12', NULL) THEN
    RAISE EXCEPTION 'PE-B1 : ijazaPresentable ne doit pas accepter juz_12';
  END IF;
  SELECT c INTO v_champ FROM pg_catalog.jsonb_array_elements(v_def -> 'champs') c WHERE c ->> 'code' = 'classesSouhaitees';
  SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(n::text) ORDER BY n) INTO v_classes
    FROM pg_catalog.generate_series(1, app_private.classes_max_par_enseignant()) AS n;
  IF private.questionnaire_options(v_def, v_champ) IS DISTINCT FROM v_classes
     OR NOT private.questionnaire_permis(v_def, v_champ, '80', NULL)
     OR private.questionnaire_permis(v_def, v_champ, '81', NULL) THEN
    RAISE EXCEPTION 'PE-B1 : classesSouhaitees a change';
  END IF;
END
$postflight$;
