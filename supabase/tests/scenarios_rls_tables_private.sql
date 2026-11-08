-- RLS-PRIVATE (08/11/2026) : migration 20261120500000_rls_tables_private.sql.
--
-- Ce que le scenario prouve :
-- (a) les quatre tables ont la RLS active, sans FORCE et sans policy ;
-- (b) chaque fonction qui les lit ou les ecrit est SECURITY DEFINER et
--     appartient au proprietaire des tables : sans FORCE, elle n'est pas
--     soumise a la RLS ;
-- (c) aucun role client (anon, authenticated, service_role, agent_ro) n'a de
--     privilege direct sur ces tables ;
-- (d) un role sans BYPASSRLS, meme avec le droit de lire, n'y voit aucune ligne
--     (preuve que la RLS est bien en vigueur), alors que la fonction DEFINER
--     de lecture du curseur D1 rend la sienne ;
-- (e) les fonctions travaillent toujours : les scenarios fonctionnels qui les
--     appellent (en partie sous SET ROLE authenticated) sont rejoues a la
--     suite, sur la meme base : remplacements (se_declarer_pret_remplacement,
--     prendre_remplacement, remplacement_fenetres_passer, remplacement_choisir),
--     entretien (entretien_avis_passer), recherche D1 (curseurs).
-- Chaque controle leve 'RLS-PRIVATE ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations), depuis la racine du depot.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'RLS-PRIVATE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- (a)
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM pg_catalog.pg_class c
     JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'private' AND c.relrowsecurity AND NOT c.relforcerowsecurity
      AND c.relname IN ('remplacements_prets_candidats', 'remplacements_acceptations',
                        'entretien_avis_envoyes', 'rech_d1_curseurs')) = 4
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                   WHERE schemaname = 'private'
                     AND tablename IN ('remplacements_prets_candidats', 'remplacements_acceptations',
                                       'entretien_avis_envoyes', 'rech_d1_curseurs')),
  '(a) quatre tables : RLS active, sans FORCE, aucune policy');

-- (b)
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
    WHERE p.prosrc ~ '(remplacements_prets_candidats|remplacements_acceptations|entretien_avis_envoyes|rech_d1_curseurs)') >= 8
  AND NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.prosrc ~ '(remplacements_prets_candidats|remplacements_acceptations|entretien_avis_envoyes|rech_d1_curseurs)'
       AND (NOT p.prosecdef OR p.proowner <> (SELECT c.relowner FROM pg_catalog.pg_class c
                                                WHERE c.oid = 'private.remplacements_acceptations'::regclass))),
  '(b) les fonctions qui touchent ces tables (8 au moins) sont DEFINER et appartiennent a leur proprietaire');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(DISTINCT c.relowner) FROM pg_catalog.pg_class c
    WHERE c.oid IN ('private.remplacements_prets_candidats'::regclass, 'private.remplacements_acceptations'::regclass,
                    'private.entretien_avis_envoyes'::regclass, 'private.rech_d1_curseurs'::regclass)) = 1,
  '(b) un seul proprietaire pour les quatre tables');

-- (c)
DO $c$
DECLARE
  r text;
  t text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r);
    FOREACH t IN ARRAY ARRAY['remplacements_prets_candidats', 'remplacements_acceptations',
                             'entretien_avis_envoyes', 'rech_d1_curseurs'] LOOP
      IF pg_catalog.has_table_privilege(r, 'private.' || t, 'SELECT,INSERT,UPDATE,DELETE') THEN
        RAISE EXCEPTION 'RLS-PRIVATE ROUGE : (c) % a un privilege direct sur private.%', r, t;
      END IF;
    END LOOP;
  END LOOP;
END $c$;
SELECT pg_temp.vrai(true, '(c) aucun role client n''a de privilege direct sur ces tables');

-- (d) Un role de test, cree et detruit dans la transaction : il a le droit de
-- lire les quatre tables, mais pas BYPASSRLS. Une ligne de curseur D1 est posee
-- par le proprietaire ; le proprietaire la voit, le role de test non.
INSERT INTO private.rech_d1_curseurs (caller_id, domaine, query_hash, after_kind, after_id,
                                      authorization_version, expires_at)
VALUES ('5e1e0000-0000-4000-8000-000000000001', 'classes', pg_catalog.md5('rls-private-essai'),
        'groupe', '5e1e0000-0000-4000-8000-000000000002', 1, pg_catalog.now() + interval '1 hour');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.rech_d1_curseurs
    WHERE caller_id = '5e1e0000-0000-4000-8000-000000000001') = 1,
  '(d) le proprietaire (celui des fonctions DEFINER) voit la ligne posee');
CREATE ROLE rls_private_essai NOLOGIN NOBYPASSRLS;
GRANT USAGE ON SCHEMA private TO rls_private_essai;
GRANT SELECT ON private.remplacements_prets_candidats, private.remplacements_acceptations,
                private.entretien_avis_envoyes, private.rech_d1_curseurs TO rls_private_essai;
SET LOCAL ROLE rls_private_essai;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.remplacements_prets_candidats) = 0
  AND (SELECT pg_catalog.count(*) FROM private.remplacements_acceptations) = 0
  AND (SELECT pg_catalog.count(*) FROM private.entretien_avis_envoyes) = 0
  AND (SELECT pg_catalog.count(*) FROM private.rech_d1_curseurs) = 0,
  '(d) un role sans BYPASSRLS, meme autorise a lire, ne voit aucune ligne (RLS en vigueur, aucune policy)');
RESET ROLE;

ROLLBACK;

-- (e) Les fonctions travaillent toujours : les scenarios fonctionnels, rejoues
-- tels quels apres la migration (chacun dans sa transaction, annulee a la fin).
\ir scenarios_remplacement_temps_reel.sql
\ir scenarios_harmonisation_a_pret_par_rang.sql
\ir scenarios_salle2_entretien_avis.sql
\ir scenarios_rech_back_2_d1_search.sql

SELECT 'RLS-PRIVATE VERT' AS resultat;
