-- PUB-TARIFS (18/10/2026) : public.tarifs_publics(). Migration 20261018140000.
--   1. anon et authenticated appellent la fonction ; l'aide privee non ;
--   2. v1 en vigueur et v2 a venir : courante v1, suivante v2 avec sa date ;
--   3. v2 en vigueur : 5500 / 6500, remises 80 / 170, prepaiement 50 / 100,
--      parrainage 2000, bourse 300, cumul 250, plus de suivante ;
--   4. aucune cle interdite (paie, marges, identifiants, auteur) a aucun niveau,
--      et uniquement des cles de la liste blanche ;
--   5. anon ne lit toujours pas la table, et n'a aucun autre droit nouveau.
-- Les dates sont deplacees dans la transaction ; tout est annule a la fin.
\o /dev/null
BEGIN;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) + interval '1 month')::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
END $$;

-- Toutes les cles d'un document, a tous les niveaux.
CREATE FUNCTION pg_temp.cles(p jsonb) RETURNS SETOF text LANGUAGE sql AS $$
  WITH RECURSIVE t(v) AS (
    SELECT p
    UNION ALL
    SELECT e.value FROM t, LATERAL (
      SELECT value FROM jsonb_each(CASE WHEN jsonb_typeof(t.v) = 'object' THEN t.v ELSE '{}'::jsonb END)
      UNION ALL
      SELECT value FROM jsonb_array_elements(CASE WHEN jsonb_typeof(t.v) = 'array' THEN t.v ELSE '[]'::jsonb END)
    ) e)
  SELECT DISTINCT k FROM t, LATERAL jsonb_object_keys(CASE WHEN jsonb_typeof(t.v) = 'object' THEN t.v ELSE '{}'::jsonb END) k;
$$;

-- ------------------------------------------------------------------
-- 1. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(has_function_privilege('anon', 'public.tarifs_publics()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.tarifs_publics()', 'EXECUTE'),
  'droits : anon et authenticated appellent tarifs_publics');
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'private.pub_tarifs_politique(public.politiques_commerciales)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pub_tarifs_politique(public.politiques_commerciales)', 'EXECUTE'),
  'droits : l''aide privee n''est pas appelable');
SELECT pg_temp.vrai((SELECT prosecdef AND provolatile = 's' AND proconfig = ARRAY['search_path=""'] AND pronargs = 0
                       FROM pg_proc WHERE oid = 'public.tarifs_publics()'::regprocedure),
  'fonction : DEFINER, STABLE, search_path vide, sans parametre');

-- ------------------------------------------------------------------
-- 2. v1 en vigueur, v2 a venir (appel en anon)
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
CREATE TEMP TABLE pub_a AS SELECT public.tarifs_publics() AS j;
RESET ROLE;
SELECT pg_temp.vrai((SELECT j #>> '{courante,version}' FROM pub_a) = 'v1.0.0', 'v1 en vigueur');
SELECT pg_temp.vrai((SELECT j #>> '{suivante,version}' FROM pub_a) = 'v2.0.0', 'v2 annoncee comme suivante');
SELECT pg_temp.vrai((SELECT (j #>> '{suivante,dateEffet}')::date FROM pub_a)
  = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) + interval '1 month')::date,
  'la suivante porte sa date d''effet');

-- ------------------------------------------------------------------
-- 3. v2 en vigueur
-- ------------------------------------------------------------------
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

SET LOCAL ROLE anon;
CREATE TEMP TABLE pub_b AS SELECT public.tarifs_publics() AS j;
RESET ROLE;
SELECT pg_temp.vrai((SELECT j #>> '{courante,version}' FROM pub_b) = 'v2.0.0', 'v2 en vigueur');
SELECT pg_temp.vrai((SELECT j -> 'suivante' FROM pub_b) = 'null'::jsonb, 'plus de suivante');
SELECT pg_temp.vrai((SELECT (j #>> '{courante,tarifEnfantMineur}')::int FROM pub_b) = 5500
  AND (SELECT (j #>> '{courante,tarifAdulteMineur}')::int FROM pub_b) = 6500, 'prix 5500 / 6500');
SELECT pg_temp.vrai((SELECT j #>> '{courante,devise}' FROM pub_b) = 'USD'
  AND (SELECT (j #>> '{courante,horsTaxes}')::boolean FROM pub_b)
  AND (SELECT (j #>> '{courante,ageAdulte}')::int FROM pub_b) = 18, 'devise, hors taxes, age 18');
SELECT pg_temp.vrai((SELECT j #> '{courante,remisesFoyer}' FROM pub_b)
  = '[{"aPartirDuRang":2,"pourMille":80},{"aPartirDuRang":3,"pourMille":170}]'::jsonb, 'remises du foyer 8 % / 17 %');
SELECT pg_temp.vrai((SELECT j #> '{courante,prepaiement}' FROM pub_b)
  = '{"trimestrielPourMille":50,"annuelPourMille":100}'::jsonb, 'prepaiement 5 % / 10 %');
SELECT pg_temp.vrai((SELECT (j #>> '{courante,parrainageCreditMineur}')::int FROM pub_b) = 2000, 'parrainage 20 $');
SELECT pg_temp.vrai((SELECT j #> '{courante,bourse}' FROM pub_b) = '{"pourMille":300,"dureeMois":6}'::jsonb, 'bourse 30 %, 6 mois');
SELECT pg_temp.vrai((SELECT (j #>> '{courante,cumulMaxPourMille}')::int FROM pub_b) = 250, 'plafond de cumul 25 %');
SELECT pg_temp.vrai((SELECT j #> '{courante,classes}' FROM pub_b)
  = '{"tailleEnfant":5,"tailleAdulte":6,"ouvertureMinimum":3}'::jsonb, 'taille des classes');
SELECT pg_temp.vrai((SELECT (j #>> '{courante,essaiActif}')::boolean FROM pub_b) IS FALSE, 'pas d''essai gratuit');

-- ------------------------------------------------------------------
-- 4. Liste blanche des cles, a tous les niveaux et dans les deux etats
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM (SELECT j FROM pub_a UNION ALL SELECT j FROM pub_b) x, LATERAL pg_temp.cles(x.j) k
   WHERE k NOT IN ('courante','suivante','version','dateEffet','devise','horsTaxes','ageAdulte',
     'tarifEnfantMineur','tarifAdulteMineur','essaiActif','essaisMax','remisesFoyer','aPartirDuRang',
     'pourMille','montantMineur','prepaiement','trimestrielPourMille','annuelPourMille',
     'parrainageCreditMineur','bourse','dureeMois','cumulMaxPourMille','classes','tailleEnfant',
     'tailleAdulte','ouvertureMinimum')),
  'liste blanche : aucune cle hors liste');
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM (SELECT j::text AS t FROM pub_a UNION ALL SELECT j::text FROM pub_b) x
   WHERE t ~* '(taux|plafond|marge|budget|publiee|auteur|notes|"id"|_id|uuid|dureeDue|jourSuspension|joursRelance|rails|baseHoraire|famille|household|email)'),
  'aucun mot interdit (paie, marges, identifiants, auteur, notes, familles)');

-- ------------------------------------------------------------------
-- 5. Aucun droit nouveau sur les tables
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_table_privilege('anon', 'public.politiques_commerciales', 'SELECT')
  AND NOT has_table_privilege('anon', 'public.politiques_commerciales', 'INSERT')
  AND NOT has_table_privilege('anon', 'public.bourses_eleves', 'SELECT')
  AND NOT has_table_privilege('anon', 'public.parrainages', 'SELECT'),
  'tables : anon ne lit ni ne modifie les politiques, bourses, parrainages');
DO $$
BEGIN
  SET LOCAL ROLE anon;
  BEGIN
    PERFORM 1 FROM public.politiques_commerciales LIMIT 1;
    RESET ROLE;
    RAISE EXCEPTION 'ROUGE : anon a lu la table des politiques';
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
  END;
END $$;
SELECT pg_temp.vrai(NOT has_table_privilege('authenticated', 'public.politiques_commerciales', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.politiques_commerciales', 'UPDATE'),
  'tables : authenticated n''ecrit pas les politiques');

\o
ROLLBACK;
\echo 'OK pub_tarifs_publics'
