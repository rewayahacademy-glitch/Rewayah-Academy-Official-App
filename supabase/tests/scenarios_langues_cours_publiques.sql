-- ADMISSION lot B (29/10/2026) : un visiteur sans compte (anon) lit le code
-- et le libelle des langues de cours actives, et rien d'autre : ni les
-- langues retirees, ni une autre colonne, ni la table elle-meme.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'LANGUES ROUGE : ...'.
BEGIN;

-- Une langue retiree, pour la contre-epreuve.
INSERT INTO public.langues_cours (code, nom_humain, ordre, actif)
VALUES ('fixture_retiree', 'Fixture retiree', 99, false);

SET LOCAL ROLE anon;
DO $anon$
DECLARE
  v_codes text[];
  v_colonnes integer;
BEGIN
  SELECT pg_catalog.array_agg(l.code ORDER BY l.code) INTO v_codes
    FROM public.langues_cours_publiques() AS l;
  IF v_codes IS NULL OR NOT (v_codes @> ARRAY['english', 'francais', 'poular']) THEN
    RAISE EXCEPTION 'LANGUES ROUGE : anon ne lit pas les langues actives (%)', v_codes;
  END IF;
  IF 'fixture_retiree' = ANY (v_codes) THEN
    RAISE EXCEPTION 'LANGUES ROUGE : anon lit une langue retiree';
  END IF;
  -- Dans l'ordre publie (ordre croissant), comme la vitrine le montre.
  IF (SELECT pg_catalog.array_agg(l.code) FROM public.langues_cours_publiques() AS l)
     IS DISTINCT FROM ARRAY['poular', 'francais', 'english'] THEN
    RAISE EXCEPTION 'LANGUES ROUGE : ordre publie non respecte';
  END IF;
  -- Deux colonnes, code et libelle, rien d'autre.
  SELECT pg_catalog.count(*) INTO v_colonnes
    FROM pg_catalog.pg_proc p, pg_catalog.unnest(p.proargnames) AS a
   WHERE p.oid = 'public.langues_cours_publiques()'::pg_catalog.regprocedure;
  IF v_colonnes <> 2 THEN
    RAISE EXCEPTION 'LANGUES ROUGE : % colonnes rendues, 2 attendues', v_colonnes;
  END IF;
  -- La table reste fermee a anon.
  BEGIN
    PERFORM 1 FROM public.langues_cours LIMIT 1;
    RAISE EXCEPTION 'LANGUES ROUGE : anon lit la table langues_cours';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  -- Et rien d'autre de voisin.
  BEGIN
    PERFORM 1 FROM public.cohortes_age LIMIT 1;
    RAISE EXCEPTION 'LANGUES ROUGE : anon lit cohortes_age';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  RAISE NOTICE 'LANGUES OK : anon lit le code et le libelle des langues actives, et rien d''autre';
END
$anon$;
RESET ROLE;

ROLLBACK;
