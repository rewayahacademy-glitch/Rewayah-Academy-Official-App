-- DEPOT-SIMPLE (13/11/2026) : migration 20261124700000, rejouee sur un Postgres
-- nu apres stub_auth.sql et toutes les migrations. Base jetable seulement (le
-- script finit par ROLLBACK).
--
--   1. un fichier au nom neutre (« document.pdf », le nom que la fonction Edge
--      fabrique) se depose et se confirme : la regle du nom de la base est
--      tenue sans le nom du client ;
--   2. rayon des cours : un document cree avec SEULEMENT un nom et un fichier
--      est publie par la direction en un appel, droits remplis par defaut,
--      revue approuvee et tracee, visible d'un inscrit ;
--   3. rayon d'un tiers : refuse sans la declaration du droit de diffuser,
--      publie avec ; le telechargement n'est permis que s'il est choisi ;
--   4. refus : hors direction (enseignant, eleve, anonyme), sans fichier,
--      revision perimee (conflit, rien d'ecrit), acces inconnu ;
--   5. le controle classique est inchange sans depot direct ;
--   6. idempotence ; droits d'execution ;
--   7. mutation rouge : sans la garde de la declaration, la seconde barriere
--      (le controle) tient, et la premiere se voit absente.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d5100000-0000-0000-0000-000000000001', 'd51-direction@example.test'),
  ('d5100000-0000-0000-0000-000000000002', 'd51-eleve@example.test'),
  ('d5100000-0000-0000-0000-000000000005', 'd51-enseignant@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('d51fffff-0000-0000-0000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('d5100000-0000-0000-0000-000000000001', 'D51DIRECTION0001', 'admin', NULL, 'Direction', 'Depot', 'active', 'female'),
  ('d5100000-0000-0000-0000-000000000002', 'D51ELEVE0000002', 'student', 'd51fffff-0000-0000-0000-000000000001', 'Nour', 'Depot', 'active', NULL),
  ('d5100000-0000-0000-0000-000000000005', 'D51ENSEIGN00005', 'teacher', NULL, 'Enseignant', 'Depot', 'provisional_active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  ('d5100000-0000-0000-0000-000000000002', 'minor', 'child');
UPDATE public.student_profiles SET cohorte = 'enfant_10_13'
 WHERE profile_id = 'd5100000-0000-0000-0000-000000000002';

INSERT INTO private.library_upload_confirmation_secrets (singleton, secret)
VALUES (true, 'secret-de-test-depot-direct-0123456789abcdef')
ON CONFLICT (singleton) DO UPDATE SET secret = EXCLUDED.secret;

CREATE FUNCTION pg_temp.qui(p_uid text, p_role text, p_foyer text DEFAULT NULL) RETURNS void
LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_uid, true),
         set_config('request.jwt.claims', jsonb_build_object('sub', p_uid,
           'app_metadata', jsonb_build_object('role', p_role, 'household_id', p_foyer))::text, true);
$$;
CREATE FUNCTION pg_temp.direction() RETURNS void LANGUAGE sql AS
$$ SELECT pg_temp.qui('d5100000-0000-0000-0000-000000000001', 'admin', NULL) $$;

-- Depose et confirme un PDF sous le nom neutre que fabrique la fonction Edge.
CREATE FUNCTION pg_temp.deposer_fichier(p_resource uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_sha text := pg_catalog.repeat('ab', 32);
  i jsonb;
  r jsonb;
BEGIN
  i := public.demander_upload_bibliotheque(p_resource, 'support', 'document.pdf', 'application/pdf', 4321, v_sha);
  IF i ->> 'cle_finale' !~ '^supports/[0-9a-f-]{36}/[1-9][0-9]*/document\.pdf$' THEN
    RAISE EXCEPTION 'D51 ROUGE : cle finale inattendue %', i;
  END IF;
  r := public.confirmer_upload_bibliotheque(
    (i ->> 'id')::uuid, 'application/pdf', 4321, v_sha,
    pg_catalog.encode(extensions.hmac(
      pg_catalog.convert_to((i ->> 'id')::uuid::text || E'\n' || v_sha || E'\n4321', 'UTF8'),
      pg_catalog.convert_to('secret-de-test-depot-direct-0123456789abcdef', 'UTF8'), 'sha256'), 'hex'));
  IF r ->> 'etat' <> 'pret' THEN RAISE EXCEPTION 'D51 ROUGE : confirmation %', r; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1 et 2. Rayon des cours : un nom, un fichier, publie
-- ---------------------------------------------------------------------------
SELECT pg_temp.direction();
DO $cours$
DECLARE b jsonb; r jsonb; ctl jsonb; v_id uuid; v_version uuid; v_rev integer;
        d public.library_version_rights%ROWTYPE;
BEGIN
  -- Le strict necessaire : un nom (arabe), un type, une langue. Rien d'autre.
  b := public.library_creer_brouillon('{"titre":"متن الأخضري","type":"pdf","langue":"ar","categorie":""}');
  v_id := (b ->> 'id')::uuid; v_version := (b ->> 'version_id')::uuid;
  PERFORM set_config('d51.cours_id', v_id::text, true);

  -- Le nom du client n'entre plus en base : la regle du nom ASCII n'est plus
  -- un obstacle, puisque le nom recu est toujours le nom neutre.
  BEGIN
    PERFORM public.demander_upload_bibliotheque(v_id, 'support', 'متن الأخضري-1.pdf', 'application/pdf', 4321, pg_catalog.repeat('ab', 32));
    RAISE EXCEPTION 'D51 ROUGE : la base accepte un nom non neutre (la fonction doit continuer a le neutraliser)';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;

  -- Sans fichier : rien a publier.
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;
  BEGIN
    PERFORM public.library_depot_direct(v_id, v_rev, 'd51-cours-sans-fichier', 'lecture', false);
    RAISE EXCEPTION 'D51 ROUGE : depot direct sans fichier accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;

  PERFORM pg_temp.deposer_fichier(v_id);

  -- Avant le depot direct : le controle classique bloque (aucun droit saisi).
  ctl := public.library_controler_version(v_version);
  IF (ctl ->> 'publiable')::boolean THEN RAISE EXCEPTION 'D51 ROUGE : publiable sans rien : %', ctl; END IF;
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;
  r := public.library_publier_version(v_id, v_version, v_rev, 'd51-cours-classique');
  IF r ->> 'resultat' <> 'PublicationBloquee' THEN RAISE EXCEPTION 'D51 ROUGE : publication classique sans droits : %', r; END IF;

  -- Un acces inconnu, une cle vide : refuses.
  BEGIN PERFORM public.library_depot_direct(v_id, v_rev, 'd51-x', 'tout', false);
    RAISE EXCEPTION 'D51 ROUGE : acces inconnu accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_depot_direct(v_id, v_rev, ' ', 'lecture', false);
    RAISE EXCEPTION 'D51 ROUGE : cle vide acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;

  -- Une revision perimee : conflit, rien d'ecrit.
  r := public.library_depot_direct(v_id, v_rev - 1, 'd51-cours-perime', 'lecture', false);
  IF r ->> 'resultat' <> 'PublicationEnConflit' THEN RAISE EXCEPTION 'D51 ROUGE : revision perimee : %', r; END IF;
  IF EXISTS (SELECT 1 FROM public.library_version_rights x WHERE x.resource_version_id = v_version AND x.approuve) THEN
    RAISE EXCEPTION 'D51 ROUGE : un conflit a ecrit les droits';
  END IF;

  -- Le depot direct : publie.
  r := public.library_depot_direct(v_id, v_rev, 'd51-cours', 'lecture', false);
  IF r ->> 'resultat' <> 'VersionPubliee' THEN RAISE EXCEPTION 'D51 ROUGE : depot direct des cours : %', r; END IF;
  SELECT * INTO d FROM public.library_version_rights x WHERE x.resource_version_id = v_version;
  IF NOT d.approuve OR d.revu_par <> 'd5100000-0000-0000-0000-000000000001' OR d.revu_le IS NULL
     OR d.depot_direct_par <> 'd5100000-0000-0000-0000-000000000001' OR d.depot_direct_le IS NULL
     OR d.droit_tiers_declare
     OR d.titulaire <> 'Rewayah Academy' OR d.source_titre <> 'متن الأخضري' OR d.attribution <> 'Rewayah Academy'
     OR NOT (d.usages @> ARRAY['application', 'classe'] AND pg_catalog.cardinality(d.usages) = 2) THEN
    RAISE EXCEPTION 'D51 ROUGE : droits par defaut des cours : %', pg_catalog.to_jsonb(d);
  END IF;
  IF (SELECT statut::text FROM public.resource_version WHERE id = v_version) <> 'publiee'
     OR (SELECT access_policy::text FROM public.library_resource WHERE id = v_id) <> 'inscrits'
     OR (SELECT current_version_id FROM public.library_resource WHERE id = v_id) <> v_version THEN
    RAISE EXCEPTION 'D51 ROUGE : le document des cours n''est pas publie pour les inscrits';
  END IF;
  -- La trace : acteur, motif.
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs a
                  WHERE a.action = 'library_direct_deposit' AND a.row_id = v_id::text
                    AND a.actor = 'd5100000-0000-0000-0000-000000000001'
                    AND a.payload ->> 'motif' = 'depot direct de la direction') THEN
    RAISE EXCEPTION 'D51 ROUGE : le depot direct n''est pas trace';
  END IF;
  -- Idempotence : la meme cle rend la meme reponse, sans rien refaire.
  IF public.library_depot_direct(v_id, v_rev, 'd51-cours', 'telechargement', false) IS DISTINCT FROM r THEN
    RAISE EXCEPTION 'D51 ROUGE : la meme cle ne rend pas la meme reponse';
  END IF;
  IF EXISTS (SELECT 1 FROM public.library_version_rights x
              WHERE x.resource_version_id = v_version AND 'telechargement' = ANY (x.usages)) THEN
    RAISE EXCEPTION 'D51 ROUGE : un rejeu a elargi l''acces';
  END IF;
END;
$cours$;

-- Un inscrit le voit dans sa bibliotheque.
SELECT pg_temp.qui('d5100000-0000-0000-0000-000000000002', 'student', 'd51fffff-0000-0000-0000-000000000001');
DO $lecteur$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur('{"types":["pdf"]}');
  IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v) e WHERE e ->> 'title' = 'متن الأخضري') THEN
    RAISE EXCEPTION 'D51 ROUGE : « visible dans la bibliotheque » est faux pour un inscrit : %', v;
  END IF;
END;
$lecteur$;

-- ---------------------------------------------------------------------------
-- 3. Rayon d'un tiers : la declaration, et elle seule
-- ---------------------------------------------------------------------------
SELECT pg_temp.direction();
DO $tiers$
DECLARE b jsonb; r jsonb; v_id uuid; v_version uuid; v_rev integer;
        d public.library_version_rights%ROWTYPE;
BEGIN
  b := public.library_creer_brouillon('{"titre":"Un livre d''un tiers","type":"pdf","langue":"fr","categorie":"","rayon":"plus_loin"}');
  v_id := (b ->> 'id')::uuid; v_version := (b ->> 'version_id')::uuid;
  PERFORM set_config('d51.tiers_id', v_id::text, true);
  PERFORM set_config('d51.tiers_version', v_version::text, true);
  PERFORM pg_temp.deposer_fichier(v_id);
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;

  -- Sans la declaration (faux, puis NULL) : refuse, rien d'ecrit.
  BEGIN PERFORM public.library_depot_direct(v_id, v_rev, 'd51-tiers-sans', 'lecture', false);
    RAISE EXCEPTION 'D51 ROUGE : document d''un tiers publie sans la declaration';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_depot_direct(v_id, v_rev, 'd51-tiers-null', 'lecture', NULL);
    RAISE EXCEPTION 'D51 ROUGE : document d''un tiers publie avec une declaration NULL';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  IF (SELECT statut::text FROM public.resource_version WHERE id = v_version) <> 'brouillon'
     OR EXISTS (SELECT 1 FROM public.library_version_rights x WHERE x.resource_version_id = v_version AND (x.approuve OR x.depot_direct_par IS NOT NULL)) THEN
    RAISE EXCEPTION 'D51 ROUGE : un refus a laisse une trace d''approbation';
  END IF;

  -- Avec la declaration, telechargement permis : publie.
  r := public.library_depot_direct(v_id, v_rev, 'd51-tiers', 'telechargement', true);
  IF r ->> 'resultat' <> 'VersionPubliee' THEN RAISE EXCEPTION 'D51 ROUGE : depot direct d''un tiers : %', r; END IF;
  SELECT * INTO d FROM public.library_version_rights x WHERE x.resource_version_id = v_version;
  IF NOT d.droit_tiers_declare OR NOT d.approuve OR d.depot_direct_par IS NULL
     OR d.titulaire = 'Rewayah Academy' OR pg_catalog.btrim(d.titulaire) = ''
     OR NOT (d.usages @> ARRAY['application', 'classe', 'telechargement']) THEN
    RAISE EXCEPTION 'D51 ROUGE : droits du document d''un tiers : %', pg_catalog.to_jsonb(d);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs a
                  WHERE a.action = 'library_direct_deposit' AND a.row_id = v_id::text
                    AND (a.payload ->> 'droit_tiers_declare')::boolean) THEN
    RAISE EXCEPTION 'D51 ROUGE : la declaration du droit n''est pas tracee';
  END IF;
END;
$tiers$;

-- ---------------------------------------------------------------------------
-- 5. Ce que la direction a saisi dans « Plus de reglages » est garde
-- ---------------------------------------------------------------------------
DO $garde_saisie$
DECLARE b jsonb; r jsonb; v_id uuid; v_version uuid; v_rev integer;
BEGIN
  b := public.library_creer_brouillon('{"titre":"Avec reglages","type":"pdf","langue":"fr","categorie":""}');
  v_id := (b ->> 'id')::uuid; v_version := (b ->> 'version_id')::uuid;
  PERFORM set_config('d51.classique_id', v_id::text, true);
  PERFORM set_config('d51.classique_version', v_version::text, true);
  PERFORM pg_temp.deposer_fichier(v_id);
  INSERT INTO public.library_version_rights (resource_version_id, source_titre, titulaire, attribution, usages)
  VALUES (v_version, 'Edition de reference', 'Un editeur', 'Mention exigee', ARRAY['application', 'classe', 'hors_ligne'])
  ON CONFLICT (resource_version_id) DO UPDATE
    SET source_titre = EXCLUDED.source_titre, titulaire = EXCLUDED.titulaire,
        attribution = EXCLUDED.attribution, usages = EXCLUDED.usages;
  -- 5 bis. Sans depot direct, le controle est INCHANGE : sans preuve ni niveau,
  -- ces droits saisis ne suffisent pas.
  IF (public.library_controler_version(v_version) ->> 'publiable')::boolean
     OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.library_controler_version(v_version) -> 'criteres') c
                     WHERE c ->> 'cle' = 'preuve' AND c ->> 'etat' = 'bloque')
     OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.library_controler_version(v_version) -> 'criteres') c
                     WHERE c ->> 'cle' = 'langueNiveau' AND c ->> 'etat' = 'bloque') THEN
    RAISE EXCEPTION 'D51 ROUGE : le controle classique a change : %', public.library_controler_version(v_version);
  END IF;
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;
  r := public.library_depot_direct(v_id, v_rev, 'd51-reglages', 'lecture', false);
  IF r ->> 'resultat' <> 'VersionPubliee' THEN RAISE EXCEPTION 'D51 ROUGE : depot direct avec reglages : %', r; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.library_version_rights x
                  WHERE x.resource_version_id = v_version AND x.source_titre = 'Edition de reference'
                    AND x.titulaire = 'Un editeur' AND x.attribution = 'Mention exigee'
                    AND x.usages @> ARRAY['hors_ligne'] AND NOT ('telechargement' = ANY (x.usages))) THEN
    RAISE EXCEPTION 'D51 ROUGE : la saisie de la direction a ete ecrasee';
  END IF;
END;
$garde_saisie$;

-- ---------------------------------------------------------------------------
-- 4. Hors direction : refuse
-- ---------------------------------------------------------------------------
DO $prepare_refus$
DECLARE b jsonb;
BEGIN
  b := public.library_creer_brouillon('{"titre":"Pour les refus","type":"pdf","langue":"fr","categorie":""}');
  PERFORM set_config('d51.refus_id', b ->> 'id', true);
  PERFORM pg_temp.deposer_fichier((b ->> 'id')::uuid);
END;
$prepare_refus$;

DO $refus$
DECLARE v_id uuid := current_setting('d51.refus_id')::uuid; v_rev integer; q record;
BEGIN
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;
  FOR q IN SELECT * FROM (VALUES
      ('d5100000-0000-0000-0000-000000000005', 'teacher', NULL),
      ('d5100000-0000-0000-0000-000000000002', 'student', 'd51fffff-0000-0000-0000-000000000001'),
      ('d5100000-0000-0000-0000-000000000002', 'guardian', 'd51fffff-0000-0000-0000-000000000001')
    ) AS t(uid, role, foyer)
  LOOP
    PERFORM pg_temp.qui(q.uid, q.role, q.foyer);
    BEGIN
      PERFORM public.library_depot_direct(v_id, v_rev, 'd51-refus-' || q.role, 'lecture', true);
      RAISE EXCEPTION 'D51 ROUGE : depot direct accepte pour %', q.role;
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  END LOOP;
  -- Un compte direction qui n'est plus valide (jeton sans role) : refuse.
  PERFORM set_config('request.jwt.claims', '{}', true);
  BEGIN
    PERFORM public.library_depot_direct(v_id, v_rev, 'd51-refus-sans-role', 'lecture', true);
    RAISE EXCEPTION 'D51 ROUGE : depot direct accepte sans role';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM pg_temp.direction();
  IF (SELECT statut::text FROM public.resource_version WHERE resource_id = v_id) <> 'brouillon' THEN
    RAISE EXCEPTION 'D51 ROUGE : un refus a publie';
  END IF;
END;
$refus$;

-- ---------------------------------------------------------------------------
-- 6. Droits d'execution
-- ---------------------------------------------------------------------------
DO $droits$
BEGIN
  IF has_function_privilege('anon', 'public.library_depot_direct(uuid,integer,text,text,boolean)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.library_depot_direct(uuid,integer,text,text,boolean)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.library_depot_direct(uuid,integer,text,text,boolean)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.library_depot_direct(uuid,integer,text,text,boolean)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'app_private.library_controle_version(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'D51 ROUGE : droits d''execution du depot direct';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid = 'public.library_depot_direct(uuid,integer,text,text,boolean)'::regprocedure
                AND (NOT p.prosecdef OR NOT p.proconfig @> ARRAY['search_path=""'])) THEN
    RAISE EXCEPTION 'D51 ROUGE : le depot direct n''est pas DEFINER a search_path vide';
  END IF;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 7. Mutation rouge : on retire la garde de la declaration. La seconde
-- barriere (le controle de publication) doit tenir ; et la premiere se voit
-- absente, ce qui prouve que le scenario 3 la teste vraiment.
-- ---------------------------------------------------------------------------
SELECT pg_temp.direction();
DO $mutation$
DECLARE b jsonb; r jsonb; v_id uuid; v_rev integer; v_def text;
BEGIN
  b := public.library_creer_brouillon('{"titre":"Mutation","type":"pdf","langue":"fr","categorie":"","rayon":"plus_loin"}');
  v_id := (b ->> 'id')::uuid;
  PERFORM pg_temp.deposer_fichier(v_id);
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = v_id;
  v_def := pg_get_functiondef('public.library_depot_direct(uuid,integer,text,text,boolean)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'IF v_tiers AND p_droit_tiers IS NOT TRUE THEN') = 0 THEN
    RAISE EXCEPTION 'D51 ROUGE : la garde a muter est introuvable';
  END IF;
  BEGIN
    EXECUTE pg_catalog.replace(v_def, 'IF v_tiers AND p_droit_tiers IS NOT TRUE THEN', 'IF false THEN');
    -- Garde retiree : plus d'exception (la mutation est vue)...
    r := public.library_depot_direct(v_id, v_rev, 'd51-mutation', 'lecture', false);
    -- ... mais le controle refuse encore la publication.
    IF r ->> 'resultat' <> 'PublicationBloquee' THEN
      RAISE EXCEPTION 'D51 ROUGE : sans la garde, un document d''un tiers est publie sans declaration : %', r;
    END IF;
    RAISE EXCEPTION 'D51_MUTATION_VUE';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'D51_MUTATION_VUE' THEN RAISE; END IF;
  END;
  -- La mutation est annulee avec son bloc : la garde est revenue.
  BEGIN PERFORM public.library_depot_direct(v_id, v_rev, 'd51-mutation-2', 'lecture', false);
    RAISE EXCEPTION 'D51 ROUGE : la garde n''est pas revenue apres la mutation';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
END;
$mutation$;

ROLLBACK;
