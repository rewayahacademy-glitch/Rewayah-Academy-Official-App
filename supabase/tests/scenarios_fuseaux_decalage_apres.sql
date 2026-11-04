-- FUSEAUX-bis (garde-cap, 04/11/2026). Migration
-- 20261109900000_fuseaux_decalage_apres.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Aucune
-- fixture : la fonction ne lit que la table des fuseaux de Postgres.
--   (1) Paris en ete : decalage apres le 25/10 (+1 h), changement suivant le
--       28/03/2027 ;
--   (2) Paris en hiver : decalage apres le 28/03/2027 (+2 h), changement
--       suivant le 31/10/2027 ;
--   (3) Toronto : -4 h, puis -5 h apres le 01/11, changement suivant le
--       14/03/2027 ;
--   (4) fuseaux sans heure d'ete (Abidjan, Kolkata) : decalage_apres et
--       changement_suivant nuls ;
--   (5) les cles de la 20261109500000 sont inchangees ;
--   (6) droits inchanges : la fonction privee reste fermee aux clients.
-- Chaque controle leve 'FUSEAUX-BIS ROUGE : ...' s'il echoue.

\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'FUSEAUX-BIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.f(p_fuseau text, p_instant timestamptz) RETURNS jsonb
LANGUAGE sql STABLE AS $$ SELECT private.fuseau_info(p_fuseau, p_instant) $$;

-- (1) Paris en ete.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'decalage_apres')::int = 3600
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-03-28 01:00+00',
  '(1) Paris en ete : +1 h apres le 25/10, changement suivant le 28/03/2027 a 01:00 UTC');

-- (2) Paris en hiver.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2027-03-28 01:00+00'
  AND (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'decalage_apres')::int = 7200
  AND (pg_temp.f('Europe/Paris', '2026-11-04 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-10-31 01:00+00',
  '(2) Paris en hiver : +2 h apres le 28/03/2027, changement suivant le 31/10/2027');

-- (3) Toronto.
SELECT pg_temp.vrai(
  (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = -14400
  AND (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'decalage_apres')::int = -18000
  AND (pg_temp.f('America/Toronto', '2026-10-01 12:00+00') ->> 'changement_suivant')::timestamptz
      = '2027-03-14 07:00+00',
  '(3) Toronto : -4 h, -5 h apres le 01/11, changement suivant le 14/03/2027 a 07:00 UTC');

-- (4) Sans heure d'ete.
SELECT pg_temp.vrai(
  pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ? 'decalage_apres'
  AND pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ->> 'decalage_apres' IS NULL
  AND pg_temp.f('Africa/Abidjan', '2026-10-01 12:00+00') ->> 'changement_suivant' IS NULL
  AND pg_temp.f('Asia/Kolkata', '2026-10-01 12:00+00') ->> 'decalage_apres' IS NULL
  AND (pg_temp.f('Asia/Kolkata', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 19800,
  '(4) Abidjan et Kolkata : aucune heure d''ete, decalage_apres et changement_suivant nuls');

-- (5) Les cles d'avant, inchangees.
SELECT pg_temp.vrai(
  (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'fuseau') = 'Europe/Paris'
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'decalage_secondes')::int = 7200
  AND (pg_temp.f('Europe/Paris', '2026-10-01 12:00+00') ->> 'prochain_changement')::timestamptz
      = '2026-10-25 01:00+00'
  AND private.fuseau_info('') IS NULL AND private.fuseau_info(NULL) IS NULL
  AND private.fuseau_info('Mars/Olympus') IS NULL,
  '(5) fuseau, decalage et prochain changement inchanges ; vide, nul ou inconnu : objet nul');

-- (6) Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.fuseau_info(text,timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.fuseau_info(text,timestamptz)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.horloge_interlocuteurs(uuid)', 'EXECUTE'),
  '(6) la fonction privee reste fermee ; horloge_interlocuteurs reste ouverte aux connectes');

ROLLBACK;
\o
\echo 'FUSEAUX-BIS : scenario vert'
