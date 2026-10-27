-- Fraicheur (fiche du 27/10/2026, lignes 1 a 9) : publier dans Realtime les
-- quatre tables des classes et des seances, pour que l'application soit
-- prevenue d'un changement sans geste de la personne.
--
-- Tables : public.groupes, public.groupe_membres, public.groupe_creneaux,
-- public.sessions. L'application n'affiche jamais le paquet Realtime : il ne
-- sert que de signal, et chaque ecran relit ses donnees par ses lectures
-- habituelles, sous RLS. La publication n'ouvre donc aucune ligne de plus.
--
-- Limites connues de Realtime (documentation Supabase, « Postgres Changes ») :
--   * les insertions et les modifications passent par la RLS de la table,
--     evaluee pour chaque abonne avec son jeton ;
--   * une suppression ne passe par aucune RLS : Realtime ne transmet que la
--     cle primaire de la ligne supprimee, a TOUS les abonnes de la table.
--     L'application traite ce paquet comme un simple signal de relecture.
--   * `replica identity full` n'est PAS pose : il ferait transmettre la ligne
--     entiere supprimee (libelle, enseignant, foyer) a tous les abonnes, hors
--     RLS. La cle primaire suffit a signaler qu'il faut relire.
--
-- Le modele est celui de 20261016101000 (session_shared_content) : sur un
-- Postgres nu sans publication supabase_realtime (CI, rejeu local), la
-- migration ne fait rien, et le controle final n'exige la publication que si
-- elle existe. La RLS, elle, est exigee partout : une table publiee sans RLS
-- serait lisible par tout abonne.

BEGIN;

DO $realtime$
DECLARE
  v_table text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p
     WHERE p.pubname = 'supabase_realtime'
  ) THEN
    RETURN;
  END IF;
  FOREACH v_table IN ARRAY ARRAY['groupes', 'groupe_membres', 'groupe_creneaux', 'sessions']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_publication_tables p
       WHERE p.pubname = 'supabase_realtime'
         AND p.schemaname = 'public'
         AND p.tablename = v_table
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', v_table);
    END IF;
  END LOOP;
END;
$realtime$;

DO $postflight$
DECLARE
  v_table text;
  v_publication boolean;
BEGIN
  v_publication := EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p
     WHERE p.pubname = 'supabase_realtime'
  );
  FOREACH v_table IN ARRAY ARRAY['groupes', 'groupe_membres', 'groupe_creneaux', 'sessions']
  LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_class c
           JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = 'public'
            AND c.relname = v_table
            AND c.relrowsecurity
       ) THEN
      RAISE EXCEPTION '% sans RLS : publication refusee', v_table;
    END IF;
    IF v_publication AND NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_publication_tables p
          WHERE p.pubname = 'supabase_realtime'
            AND p.schemaname = 'public'
            AND p.tablename = v_table
       ) THEN
      RAISE EXCEPTION '% absente de supabase_realtime', v_table;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
