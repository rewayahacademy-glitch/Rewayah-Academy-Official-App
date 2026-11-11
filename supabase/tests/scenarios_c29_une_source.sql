-- C29-UNE-SOURCE (11/11/2026), migration 20261123500000_c29_une_source.sql.
-- L'affectation des missions de controle lit le plafond hebdomadaire a la
-- meme source que l'affichage (lire_regles_tirage) : la derniere version de
-- controle_regles, avec repli sur la cle app_config quand la table est vide.
-- Rouge sans la migration, vert avec.
--
-- Pour voir QUELLE source est lue, les deux sont desaccordees a dessein
-- (session_replication_role = replica, le declencheur de recopie ne joue
-- pas) : la cle app_config vaut 99, hors des bornes 0-50.
--   1. table vide : la cle est lue ; le passage d'une seance a in_progress
--      leve « quota C-29 invalide » (23514) ;
--   2. une version enregistree a 0 : la table est lue ; plafond 0, aucune
--      mission, aucune erreur, malgre la cle a 99 ;
--   3. temoin : lire_regles_tirage (l'affichage) rend aussi 0.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'C29-UNE-SOURCE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

-- Passe la seance a in_progress ; rend 'ok' ou le code SQLSTATE leve.
CREATE FUNCTION pg_temp.lancer(p_seance uuid) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.sessions SET status = 'in_progress' WHERE id = p_seance;
  RETURN 'ok';
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE || ' ' || SQLERRM;
END $$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('c29a0000-0000-0000-0000-000000000001'), ('c29a0000-0000-0000-0000-000000000002');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('c29a0000-0000-0000-0000-000000000001', 'C29U-ADM', 'admin', 'Adm', 'Un', 'active', 'male'),
  ('c29a0000-0000-0000-0000-000000000002', 'C29U-ENS', 'teacher', 'Ens', 'Un', 'active', 'male');
INSERT INTO public.groupes (id, type_public, seuil_max, libelle, weekday, hour_local, teacher_id) VALUES
  ('c29a0000-0000-0000-0000-0000000000a1', 'enfant', 6, 'Classe une source', 1, 10,
   'c29a0000-0000-0000-0000-000000000002');
INSERT INTO public.sessions (id, groupe_id, teacher_id, started_at, ended_at, status) VALUES
  ('c29a0000-0000-0000-0000-0000000000b1', 'c29a0000-0000-0000-0000-0000000000a1',
   'c29a0000-0000-0000-0000-000000000002', now(), now() + interval '1 hour', 'preflight'),
  ('c29a0000-0000-0000-0000-0000000000b2', 'c29a0000-0000-0000-0000-0000000000a1',
   'c29a0000-0000-0000-0000-000000000002', now() + interval '2 hours', now() + interval '3 hours', 'preflight');
-- Les deux sources desaccordees : la cle a 99, la table vide.
UPDATE public.app_config SET value = '99'::jsonb WHERE key = 'controle.missions_par_semaine';
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.controle_regles),
  'depart : controle_regles est vide');

-- 1. Table vide : repli sur la cle app_config (99, hors bornes)
SELECT pg_temp.vrai(
  pg_temp.lancer('c29a0000-0000-0000-0000-0000000000b1') LIKE '23514%quota C-29 invalide%',
  '1 : table vide, la cle app_config est lue (99 refuse en 23514)');

-- 2. Une version enregistree a 0 : la table est lue, la cle a 99 ignoree
SET LOCAL session_replication_role = replica;
INSERT INTO public.controle_regles (version, missions_par_semaine, ponderations, payload, cree_par, cle)
VALUES (1, 0, '{"enseignants_recents":"normal","classes_signalees":"normal","heures_de_pointe":"normal"}'::jsonb,
        '{}'::jsonb, 'c29a0000-0000-0000-0000-000000000001', 'c29a0000-0000-0000-0000-0000000000c1');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'controle.missions_par_semaine') = '99'::jsonb,
  '2 : la cle app_config vaut toujours 99 (sources desaccordees)');
SELECT pg_temp.vrai(
  pg_temp.lancer('c29a0000-0000-0000-0000-0000000000b2') = 'ok'
  AND NOT EXISTS (SELECT 1 FROM private.controle_missions
                   WHERE session_id = 'c29a0000-0000-0000-0000-0000000000b2'),
  '2 : une version enregistree, la table est lue (plafond 0 : aucune mission, aucune erreur)');

-- 3. Temoin : l'affichage lit la meme source
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c29a0000-0000-0000-0000-000000000001', true),
       set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT pg_temp.vrai(
  (public.lire_regles_tirage() ->> 'missions_par_semaine')::integer = 0,
  '3 : lire_regles_tirage rend aussi 0 : une seule source');
RESET ROLE;

\o
ROLLBACK;
