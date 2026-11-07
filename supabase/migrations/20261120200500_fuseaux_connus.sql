-- PERF-ATTENTE (d) (garde-cap, 07/11/2026 : feu vert avec trois conditions).
-- Valider un nom de fuseau SANS lire pg_catalog.pg_timezone_names.
--
-- Constat (production, lecture seule, 07/11/2026) : une simple lecture
-- `exists (select 1 from pg_catalog.pg_timezone_names where name = ...)` coute
-- 646 ms (EXPLAIN ANALYZE : parcours de 914 fuseaux, 913 rejetes). Quinze
-- fonctions de production la font, a chaque appel : offres_compatibles
-- (602 ms de moyenne, soit presque tout son temps), prerequis_enseignant (la
-- liste « A configurer » de Premiers pas), maj_profil_enseignant,
-- enregistrer_profil_apprentissage, demander_creneau_personnalise,
-- creer_classe_creneaux_admin, creer_groupe, modifier_groupe, creer_offre_horaire,
-- cle_horaire_utc, creneaux_normalises_utc, traduire_occurrences_fuseau (deux
-- fois), series_tresorerie, private.questionnaire_fuseau_propose,
-- private.formulaires_lire.
--
-- Correction (une cause, un fichier) :
--   1. app_private.fuseaux_connus : une table FIGEE des noms de fuseau, remplie
--      ici, une fois, depuis pg_timezone_names (RLS activee, aucun droit pour un
--      client) ;
--   2. app_private.fuseau_connu(nom) : STABLE, SECURITY DEFINER, search_path
--      vide. Un nom present dans la table repond tout de suite ; un nom ABSENT
--      est reverifie dans pg_timezone_names (chemin lent, rare : une mise a jour
--      de la base de fuseaux de PostgreSQL ne fait donc JAMAIS refuser un fuseau
--      valide) ; NULL repond faux, comme l'ancienne lecture ;
--   3. quinze fonctions remplacees PAR ANCRE : la seule lecture de la vue devient
--      un appel a fuseau_connu. Pour chacune, le preflight exige le md5 de
--      pg_get_functiondef lu en production le 07/11/2026 (identique a celui d'une
--      base rejouee du depot) ou la fonction deja remplacee ; l'ancre doit se
--      trouver une seule fois ; apres remplacement, l'ancre remise a sa place
--      redonne EXACTEMENT l'ancienne definition (la seule difference est donc
--      l'ancre) ; l'empreinte F86 du commentaire, s'il en porte une, est mise a
--      jour.
-- Non touchee, dit : private.questionnaire_options LISTE les fuseaux (elle ne
-- valide pas un nom) ; une liste figee pourrait manquer un fuseau nouveau.
--
-- Droits : trois des fonctions sont INVOKER et appelees par des clients
-- (cle_horaire_utc, creneaux_normalises_utc, series_tresorerie), une par le
-- service (traduire_occurrences_fuseau) : fuseau_connu est donc executable par
-- authenticated et service_role (un booleen sur un nom de fuseau, aucune
-- donnee) ; app_private est deja en USAGE pour authenticated. anon et agent_ro :
-- non.
--
-- ATTENTION a l'installation : les md5 ci-dessous sont ceux de la production le
-- 07/11/2026. Si un train (g3) change l'une de ces quinze fonctions, le preflight
-- s'arrete en nommant la fonction et son md5 ; les relire alors.
-- Aucun mot d'effacement. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regnamespace('app_private') IS NULL THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : le schema app_private est absent, arret';
  END IF;
END;
$preflight$;

-- 1. La table figee.
CREATE TABLE IF NOT EXISTS app_private.fuseaux_connus (
  nom text PRIMARY KEY CHECK (pg_catalog.length(nom) BETWEEN 1 AND 100)
);
ALTER TABLE app_private.fuseaux_connus ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.fuseaux_connus FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE app_private.fuseaux_connus IS
  'PERF-ATTENTE (d) : les noms de fuseau connus, figes depuis pg_timezone_names a l''installation (en lecture, sans droit client). Lue par app_private.fuseau_connu, qui reverifie dans pg_timezone_names un nom absent.';
INSERT INTO app_private.fuseaux_connus (nom)
SELECT z.name FROM pg_catalog.pg_timezone_names z WHERE pg_catalog.length(z.name) BETWEEN 1 AND 100
ON CONFLICT (nom) DO NOTHING;

-- 2. La fonction.
CREATE OR REPLACE FUNCTION app_private.fuseau_connu(p_nom text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_nom IS NULL THEN
    RETURN false;
  END IF;
  -- Chemin rapide : le nom est dans la table figee.
  IF EXISTS (SELECT 1 FROM app_private.fuseaux_connus f WHERE f.nom = p_nom) THEN
    RETURN true;
  END IF;
  -- Repli (rare) : un nom absent de la table est reverifie a la source, pour
  -- qu'une mise a jour de la base de fuseaux ne refuse jamais un fuseau valide.
  RETURN EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_nom);
END;
$function$;

ALTER FUNCTION app_private.fuseau_connu(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.fuseau_connu(text) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION app_private.fuseau_connu(text) TO authenticated, service_role;
COMMENT ON FUNCTION app_private.fuseau_connu(text) IS
  'PERF-ATTENTE (d) : ce nom est-il un fuseau connu ? Table figee d''abord, repli sur pg_timezone_names pour un nom absent, NULL = faux. STABLE, DEFINER, search_path vide ; executable par authenticated et service_role (booleen sur un nom, aucune donnee).';

-- 3. Les quinze fonctions, par ancre.
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_md5 text, p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_ancien text := pg_catalog.pg_get_functiondef(p_f);
  v_md5 text := pg_catalog.md5(v_ancien);
  v_n integer;
  v_nouveau text;
  v_comment text;
BEGIN
  IF pg_catalog.strpos(v_ancien, p_avant) = 0 AND pg_catalog.strpos(v_ancien, p_apres) > 0 THEN
    RAISE NOTICE 'PERF-FUSEAUX : % est deja remplacee', p_f::text;
    RETURN;
  END IF;
  IF v_md5 <> p_md5 THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : % a change (md5 % au lieu de %), migration a revoir', p_f::text, v_md5, p_md5;
  END IF;
  v_n := (pg_catalog.length(v_ancien) - pg_catalog.length(pg_catalog.replace(v_ancien, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : ancre de % trouvee % fois au lieu de 1', p_f::text, v_n;
  END IF;
  v_nouveau := pg_catalog.replace(v_ancien, p_avant, p_apres);
  IF pg_catalog.replace(v_nouveau, p_apres, p_avant) <> v_ancien THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : le remplacement de % ne se reverse pas a l''identique', p_f::text;
  END IF;
  EXECUTE v_nouveau;
  -- L'empreinte F86 du commentaire, s'il en porte une, suit la nouvelle definition.
  SELECT pg_catalog.obj_description(p_f::oid, 'pg_proc') INTO v_comment;
  IF v_comment IS NOT NULL AND pg_catalog.strpos(v_comment, v_md5) > 0 THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f::text,
      pg_catalog.replace(v_comment, v_md5, pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f))));
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(p_f), 'pg_timezone_names') > 0 THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : % lit encore pg_timezone_names', p_f::text;
  END IF;
END;
$function$;

SELECT pg_temp.remplacer('public.cle_horaire_utc(smallint[],smallint[],text)'::pg_catalog.regprocedure, 'dad0aabdff8be7f5a1875412170ac3c9',
  $a1$     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau
     ) THEN$a1$,
  $a2$     OR NOT app_private.fuseau_connu(p_fuseau) THEN$a2$);
SELECT pg_temp.remplacer('public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure, '03e34815131eb0724b07b33d94d6764c',
  $a3$    PERFORM 1 FROM pg_catalog.pg_timezone_names WHERE name = p_timezone_iana;
    IF NOT FOUND THEN$a3$,
  $a4$    IF NOT app_private.fuseau_connu(p_timezone_iana) THEN$a4$);
SELECT pg_temp.remplacer('public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::pg_catalog.regprocedure, '95cfde345c0ceec51943eff788a6785f',
  $a5$    perform 1 from pg_catalog.pg_timezone_names where name = p_timezone_iana;
    if not found then$a5$,
  $a6$    if not app_private.fuseau_connu(p_timezone_iana) then$a6$);
SELECT pg_temp.remplacer('public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint)'::pg_catalog.regprocedure, 'e5280720af7cd321a4160c4050297095',
  $a7$  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana) then$a7$,
  $a8$  if not app_private.fuseau_connu(p_fuseau_iana) then$a8$);
SELECT pg_temp.remplacer('public.creneaux_normalises_utc(smallint[],smallint[],text)'::pg_catalog.regprocedure, 'e5d2cde23dd71b6d8ef0d97043621b96',
  $a9$     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau
     ) THEN$a9$,
  $a10$     OR NOT app_private.fuseau_connu(p_fuseau) THEN$a10$);
SELECT pg_temp.remplacer('public.demander_creneau_personnalise(uuid,text,smallint[],smallint)'::pg_catalog.regprocedure, '20425c7d87f88f4a27765b7c5756fbf2',
  $a11$     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau_iana) THEN$a11$,
  $a12$     OR NOT app_private.fuseau_connu(p_fuseau_iana) THEN$a12$);
SELECT pg_temp.remplacer('public.enregistrer_profil_apprentissage(uuid,text,text,text,text,text)'::pg_catalog.regprocedure, '58df2faa6b5029d2fcf6c40af99959e4',
  $a13$  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana
  ) then$a13$,
  $a14$  if not app_private.fuseau_connu(p_fuseau_iana) then$a14$);
SELECT pg_temp.remplacer('public.maj_profil_enseignant(text,text[],text)'::pg_catalog.regprocedure, '4aed10e8b53384372f2eb0595a2345bd',
  $a15$     AND NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_timezone
     ) THEN$a15$,
  $a16$     AND NOT app_private.fuseau_connu(p_timezone) THEN$a16$);
SELECT pg_temp.remplacer('public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)'::pg_catalog.regprocedure, 'b6b4ee9e3bda2746db7b2a6d0053eb3f',
  $a17$    perform 1 from pg_catalog.pg_timezone_names where name = p_timezone_iana;
    if not found then$a17$,
  $a18$    if not app_private.fuseau_connu(p_timezone_iana) then$a18$);
SELECT pg_temp.remplacer('public.offres_compatibles(uuid,text)'::pg_catalog.regprocedure, '917560d86a7b22fffde9a4fede112741',
  $a19$      and exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_vue)$a19$,
  $a20$      and app_private.fuseau_connu(p_fuseau_vue)$a20$);
SELECT pg_temp.remplacer('public.prerequis_enseignant()'::pg_catalog.regprocedure, 'cf58651d62a508cdcbfadfca719572db',
  $a21$v_profil.country IS NOT NULL AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_profil.timezone_iana),$a21$,
  $a22$v_profil.country IS NOT NULL AND app_private.fuseau_connu(v_profil.timezone_iana),$a22$);
SELECT pg_temp.remplacer('private.formulaires_lire(text,text,text,jsonb,text)'::pg_catalog.regprocedure, '2616ef2ef1c7f91c367bbdff87716629',
  $a23$  IF p_fuseau IS NULL OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_fuseau) THEN$a23$,
  $a24$  IF p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN$a24$);
SELECT pg_temp.remplacer('private.questionnaire_fuseau_propose(text)'::pg_catalog.regprocedure, '1d449d7e400b00fd8260688c56276e9f',
  $a25$  RETURN EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_nom);$a25$,
  $a26$  RETURN app_private.fuseau_connu(p_nom);$a26$);
SELECT pg_temp.remplacer('public.series_tresorerie()'::pg_catalog.regprocedure, 'b21a1db04ee6a816de9ad4cc607cee61',
  $a27$  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_tz) THEN$a27$,
  $a28$  IF NOT app_private.fuseau_connu(v_tz) THEN$a28$);
SELECT pg_temp.remplacer('public.traduire_occurrences_fuseau(smallint[],smallint[],text,text)'::pg_catalog.regprocedure, 'b6d66e153b0d72561631aa30c13d2b9f',
  $a29$     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names
       WHERE name = p_fuseau_source
     )
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names
       WHERE name = p_fuseau_destination
     ) THEN$a29$,
  $a30$     OR NOT app_private.fuseau_connu(p_fuseau_source)
     OR NOT app_private.fuseau_connu(p_fuseau_destination) THEN$a30$);

DO $postflight$
DECLARE
  v_f record;
BEGIN
  FOR v_f IN SELECT p.oid::regprocedure AS f FROM pg_catalog.pg_proc p
               JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname IN ('public', 'private', 'app_private')
                AND p.prosrc ILIKE '%pg_timezone_names%'
                AND p.oid <> 'app_private.fuseau_connu(text)'::regprocedure
                AND p.oid <> 'private.questionnaire_options(jsonb,jsonb)'::regprocedure LOOP
    RAISE EXCEPTION 'PERF-FUSEAUX : % lit encore pg_timezone_names', v_f.f::text;
  END LOOP;
  IF NOT app_private.fuseau_connu('Europe/Paris') OR app_private.fuseau_connu('Mars/Olympus')
     OR app_private.fuseau_connu(NULL) THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : fuseau_connu ne repond pas comme attendu';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM app_private.fuseaux_connus)
       < (SELECT pg_catalog.count(*) FROM pg_catalog.pg_timezone_names z WHERE pg_catalog.length(z.name) BETWEEN 1 AND 100) THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : la table des fuseaux est incomplete';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'app_private.fuseaux_connus'::regclass)
     OR pg_catalog.has_table_privilege('anon', 'app_private.fuseaux_connus', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'app_private.fuseaux_connus', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'app_private.fuseaux_connus', 'INSERT') THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : fuseaux_connus sans RLS, ou lisible par un client';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'app_private.fuseau_connu(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'app_private.fuseau_connu(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'app_private.fuseau_connu(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'app_private.fuseau_connu(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PERF-FUSEAUX : droits de fuseau_connu inattendus';
  END IF;
END;
$postflight$;
