-- PERF-FUSEAUX-HORLOGE (a) (pilote, 14/11/2026 : lenteurs en production pendant
-- l'arrivee de vrais candidats, le directeur refuse un palier de compute).
-- La liste des fuseaux du questionnaire ne lit plus pg_catalog.pg_timezone_names.
--
-- Constat (production, lecture seule, 14/11/2026) :
--   - une seule fonction lit encore la vue : private.questionnaire_options, branche
--     `liste = 'fuseaux'` (la migration 20261120200500 l'avait laissee, parce
--     qu'elle LISTE au lieu de valider) ;
--   - EXPLAIN ANALYZE de private.questionnaire_options('{}', '{"liste":"fuseaux"}') :
--     508 ms ; questionnaire_salle_examen() l'appelle a chaque ouverture du
--     questionnaire candidat (champ fuseauIana) : 885 ms de moyenne, 6,5 s au
--     plus, timeouts du 14/11 a 14:21-14:23 et 14:44 UTC ;
--   - la table figee app_private.fuseaux_connus porte, sous le motif du
--     questionnaire, exactement les memes 489 noms que la vue (0 manquant,
--     0 en trop).
--   - NON traite ici, dit : les 362 appels « SELECT name FROM pg_timezone_names »
--     de pg_stat_statements viennent du role authenticator, c'est PostgREST
--     qui relit les fuseaux a chaque rechargement de son cache de schema (364
--     rechargements depuis le 05/09, soit apres chaque migration) ; aucune
--     table ne les supprime.
--
-- Correction (une cause, un fichier) :
--   1. la table figee est completee depuis la vue (ON CONFLICT DO NOTHING : un
--      fuseau ajoute par une mise a jour de PostgreSQL entre a la prochaine
--      migration qui la rejoue) ;
--   2. private.questionnaire_options est remplacee PAR ANCRE : seule la lecture de
--      la vue devient une lecture de la table ; l'ancre doit se trouver une seule
--      fois ; apres remplacement, l'ancre remise a sa place redonne EXACTEMENT
--      l'ancienne definition. Pas d'empreinte md5 exigee (la fonction ne porte
--      pas de commentaire, et une autre session peut la redefinir a l'identique
--      ailleurs) : l'ancre unique et le retour a l'identique suffisent.
-- Droits : questionnaire_options est INVOKER, appelee seulement par
-- public.questionnaire_salle_examen (SECURITY DEFINER, proprietaire postgres,
-- proprietaire aussi de la table) : aucun droit client nouveau.
-- Aucun mot d'effacement. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('app_private.fuseaux_connus') IS NULL THEN
    RAISE EXCEPTION 'PERF-FUSEAUX-Q : app_private.fuseaux_connus est absente (migration 20261120200500 non installee), arret';
  END IF;
  IF pg_catalog.to_regprocedure('private.questionnaire_options(jsonb,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'PERF-FUSEAUX-Q : private.questionnaire_options(jsonb,jsonb) est absente, arret';
  END IF;
END;
$preflight$;

-- 1. La table figee, completee (idempotent).
INSERT INTO app_private.fuseaux_connus (nom)
SELECT z.name FROM pg_catalog.pg_timezone_names z WHERE pg_catalog.length(z.name) BETWEEN 1 AND 100
ON CONFLICT (nom) DO NOTHING;

-- 2. La liste, par ancre.
DO $remplacer$
DECLARE
  v_f constant pg_catalog.regprocedure := 'private.questionnaire_options(jsonb,jsonb)'::pg_catalog.regprocedure;
  v_avant constant text := $a1$    RETURN (SELECT pg_catalog.jsonb_agg(z.name ORDER BY z.name)
              FROM pg_catalog.pg_timezone_names z
             WHERE z.name ~ private.questionnaire_fuseau_motif());$a1$;
  v_apres constant text := $a2$    RETURN (SELECT pg_catalog.jsonb_agg(z.nom ORDER BY z.nom)
              FROM app_private.fuseaux_connus z
             WHERE z.nom ~ private.questionnaire_fuseau_motif());$a2$;
  v_ancien text := pg_catalog.pg_get_functiondef(v_f);
  v_n integer;
  v_nouveau text;
BEGIN
  IF pg_catalog.strpos(v_ancien, v_avant) = 0 AND pg_catalog.strpos(v_ancien, v_apres) > 0 THEN
    RAISE NOTICE 'PERF-FUSEAUX-Q : % est deja remplacee', v_f::text;
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_ancien) - pg_catalog.length(pg_catalog.replace(v_ancien, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PERF-FUSEAUX-Q : ancre de % trouvee % fois au lieu de 1, migration a revoir', v_f::text, v_n;
  END IF;
  v_nouveau := pg_catalog.replace(v_ancien, v_avant, v_apres);
  IF pg_catalog.replace(v_nouveau, v_apres, v_avant) <> v_ancien THEN
    RAISE EXCEPTION 'PERF-FUSEAUX-Q : le remplacement de % ne se reverse pas a l''identique', v_f::text;
  END IF;
  EXECUTE v_nouveau;
END;
$remplacer$;

-- 3. Controle : plus aucune fonction applicative ne lit la vue, sauf le repli
-- de app_private.fuseau_connu (un nom absent de la table, chemin rare).
DO $postflight$
DECLARE
  v_reste text;
BEGIN
  SELECT pg_catalog.string_agg(p.oid::pg_catalog.regprocedure::text, ', ')
    INTO v_reste
    FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname IN ('public', 'private', 'app_private')
     AND p.prosrc ILIKE '%pg_timezone_names%'
     AND p.oid <> 'app_private.fuseau_connu(text)'::pg_catalog.regprocedure;
  IF v_reste IS NOT NULL THEN
    RAISE EXCEPTION 'PERF-FUSEAUX-Q : lisent encore pg_timezone_names : %', v_reste;
  END IF;
END;
$postflight$;
