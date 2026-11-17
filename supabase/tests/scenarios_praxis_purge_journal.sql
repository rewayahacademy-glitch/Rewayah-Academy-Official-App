-- PRAXIS-PURGE-JOURNAL (migration 20261129920000) : la purge du journal de Praxis a douze mois.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. la fonction efface les lignes de plus de douze mois, garde le reste (une ligne de onze mois et vingt-neuf jours,
--      une de douze mois moins une heure, une recente) et rend le nombre de lignes effacees ;
--   2. un deuxieme appel n'en efface aucune (rejouable) ; une duree plus longue garde davantage ;
--   3. une duree absente, nulle ou inferieure a douze mois est refusee, et ne touche a rien : jamais une instruction de
--      tout purger, jamais une promesse raccourcie ;
--   4. aucun role client ne peut l'executer ; SECURITY DEFINER, search_path vide, proprietaire postgres ;
--   5. le journal reste a ajout seul : une modification est toujours refusee (la purge n'ouvre pas d'autre voie) ;
--   6. la purge n'efface que le journal : une autre table de Praxis (les cles) garde ses lignes.
--
-- Postgres nu apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

INSERT INTO private.praxis_journal (outil, issue, texte_envoye, cree_le) VALUES
  ('ecrire', 'envoye', 'ancien 13 mois',      pg_catalog.clock_timestamp() - interval '13 months'),
  ('ecrire', 'envoye', 'ancien 12 mois +1 j', pg_catalog.clock_timestamp() - interval '12 months' - interval '1 day'),
  ('ecrire', 'envoye', 'ancien 30 mois',      pg_catalog.clock_timestamp() - interval '30 months'),
  ('ecrire', 'envoye', 'garde 12 mois -1 h',  pg_catalog.clock_timestamp() - interval '12 months' + interval '1 hour'),
  ('ecrire', 'envoye', 'garde 11 mois 29 j',  pg_catalog.clock_timestamp() - interval '11 months' - interval '29 days'),
  ('annoncer', 'envoye', 'garde recent',      pg_catalog.clock_timestamp() - interval '2 days');

-- 1. Douze mois gardes, le reste efface.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.praxis_journal WHERE texte_envoye LIKE 'ancien %') = 3
  AND (SELECT pg_catalog.count(*) FROM private.praxis_journal WHERE texte_envoye LIKE 'garde %') = 3,
  'avant la purge : trois lignes anciennes, trois lignes a garder');
SELECT pg_temp.vrai(private.praxis_purger_journal() = 3,
  'la purge rend 3 : les lignes de 13, 12 mois et un jour, et 30 mois');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(j.texte_envoye ORDER BY j.texte_envoye) FROM private.praxis_journal j)
    = ARRAY['garde 11 mois 29 j', 'garde 12 mois -1 h', 'garde recent'],
  'restent les trois lignes de moins de douze mois');

-- 2. Rejouable ; une duree plus longue garde davantage.
SELECT pg_temp.vrai(private.praxis_purger_journal() = 0, 'un deuxieme appel n''efface rien (rejouable)');
SELECT pg_temp.vrai(private.praxis_purger_journal(interval '24 months') = 0,
  'une duree plus longue (24 mois) n''efface pas davantage');

-- 3. Jamais « tout purger », jamais une promesse raccourcie.
DO $$
BEGIN
  PERFORM private.praxis_purger_journal(interval '0');
  RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : une duree nulle a ete acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree nulle est refusee';
END $$;
DO $$
BEGIN
  PERFORM private.praxis_purger_journal(NULL);
  RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : une duree absente a ete acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree absente est refusee';
END $$;
DO $$
BEGIN
  PERFORM private.praxis_purger_journal(interval '6 months');
  RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : une duree de six mois a ete acceptee (la promesse est douze mois)';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree de six mois est refusee';
END $$;
DO $$
BEGIN
  PERFORM private.praxis_purger_journal(interval '12 months' - interval '1 day');
  RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : une duree de douze mois moins un jour a ete acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree de douze mois moins un jour est refusee';
END $$;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.praxis_journal) = 3,
  'les refus n''ont rien efface');

-- 4. Aucun client ; DEFINER, search_path vide, proprietaire postgres.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'private.praxis_purger_journal(interval)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.praxis_purger_journal(interval)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'private.praxis_purger_journal(interval)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'private.praxis_purger_journal(interval)', 'EXECUTE'),
  'aucun role client (anon, authenticated, service_role, agent_ro) ne peut executer la purge');
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::regrole
     FROM pg_catalog.pg_proc p WHERE p.oid = 'private.praxis_purger_journal(interval)'::regprocedure),
  'SECURITY DEFINER, search_path vide, proprietaire postgres');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('authenticated', 'private.praxis_journal', 'DELETE')
  AND NOT pg_catalog.has_table_privilege('service_role', 'private.praxis_journal', 'DELETE'),
  'aucun role client n''a de droit d''effacement direct sur le journal');

-- 5. Le journal reste a ajout seul.
DO $$
BEGIN
  UPDATE private.praxis_journal SET issue = 'modifie' WHERE texte_envoye = 'garde recent';
  RAISE EXCEPTION 'PRAXIS-PURGE ROUGE : une modification du journal a ete acceptee';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK le journal reste a ajout seul (la modification est refusee)';
END $$;

-- 6. Seul le journal est touche.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.comptes_officiels) >= 1,
  'les comptes officiels (autre table de Praxis) gardent leurs lignes');

ROLLBACK;
