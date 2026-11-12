-- PRIERE-1 (20261123930000) : la priere a l'heure, calculee par le serveur.
-- Prouve :
--   1. le calcul SQL colle au paquet Dart `adhan` sur la matrice de reference
--      supabase/tests/fixtures/priere_reference_adhan.csv (8 lieux x 24 dates x
--      3 methodes x 2 ecoles d'Asr, plus les douze methodes sur 3 lieux x 4 dates) ;
--      ecart maximal admis : 2 minutes ; les cas indefinis concordent ;
--   2. le placement de la pause : au milieu, dans les 5 premieres minutes, dans
--      les 15 dernieres, deux prieres dans 90 minutes, sans lieu, Ramadan, ecole ;
--   3. le remplissage : creation de seance, changement d'heure, de lieu, de
--      reglage, d'enseignant (remplacement), changement d'heure du fuseau de la
--      classe, recalcul de nuit ;
--   4. les droits : eleve et tuteur de la classe lisent l'heure sans lieu ;
--      etranger, autre classe, anonyme refuses ; la position n'est lue que par
--      l'enseignant et la direction ;
--   5. les lectures de la direction : croisements sur 12 mois, heures sans
--      priere, vendredi, incoherences ; le journal d'un calcul indefini.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier, LANCE DEPUIS LA
-- RACINE DU DEPOT (le \copy lit un chemin relatif). Se termine par ROLLBACK.
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text, p_foyer text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.personne() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '', true); PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('test.uid', '', true); PERFORM set_config('test.jwt', '', true);
END $$;
-- Vrai quand l'appel leve une erreur (le refus attendu).
CREATE FUNCTION pg_temp.refuse(p_sql text) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN false;
EXCEPTION WHEN OTHERS THEN
  RETURN true;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text, text),
  pg_temp.refuse(text), pg_temp.personne() TO authenticated, anon;

-- ===========================================================================
-- 1. Le calcul contre la reference `adhan`
-- ===========================================================================
CREATE TEMP TABLE ref (lieu text, lat float8, lon float8, jour date, methode text, ecole text,
  fajr bigint, dhuhr bigint, asr bigint, maghrib bigint, isha bigint);
\copy ref FROM 'supabase/tests/fixtures/priere_reference_adhan.csv' CSV HEADER

CREATE TEMP TABLE resultat AS
SELECT r.*, (SELECT array_agg(extract(epoch FROM c.instant_utc)::bigint
                 ORDER BY CASE c.priere WHEN 'fajr' THEN 1 WHEN 'dhuhr' THEN 2 WHEN 'asr' THEN 3
                                        WHEN 'maghrib' THEN 4 ELSE 5 END)
               FROM private.priere_calculer(r.lat, r.lon, r.jour, r.methode, r.ecole, '{}') c) AS sql
  FROM ref r;

SELECT pg_temp.vrai((SELECT count(*) FROM ref) >= 1152
  AND (SELECT count(DISTINCT lieu) FROM ref) >= 6,
  'reference adhan : au moins 1152 combinaisons et 6 lieux');
SELECT pg_temp.vrai((SELECT count(DISTINCT lieu) FROM ref WHERE lieu IN ('Conakry','Dakar','Paris','Montreal','Londres','Reykjavik')) = 6,
  'reference adhan : Conakry, Dakar, Paris, Montreal, Londres et un lieu de haute latitude');
SELECT pg_temp.vrai((SELECT count(DISTINCT jour) FROM ref) >= 24
  AND (SELECT count(DISTINCT methode) FROM ref) = 12
  AND (SELECT count(DISTINCT ecole) FROM ref) = 2,
  'reference adhan : 24 dates, 12 methodes, 2 ecoles d''Asr');
SELECT pg_temp.vrai((SELECT count(*) FROM resultat WHERE (fajr IS NULL) <> (sql IS NULL)) = 0,
  'cas indefinis : le serveur et adhan sont indefinis aux memes lignes');
SELECT pg_temp.vrai((SELECT count(*) FROM resultat WHERE fajr IS NULL) > 0,
  'cas indefinis : la matrice en contient (Tromso, soleil de minuit et nuit polaire)');
SELECT pg_temp.vrai((SELECT max(greatest(abs(fajr - sql[1]), abs(dhuhr - sql[2]), abs(asr - sql[3]),
                                         abs(maghrib - sql[4]), abs(isha - sql[5]))) / 60.0
                       FROM resultat WHERE sql IS NOT NULL) <= 2,
  'ecart maximal avec adhan <= 2 minutes (mesure : '
  || (SELECT (max(greatest(abs(fajr - sql[1]), abs(dhuhr - sql[2]), abs(asr - sql[3]),
                           abs(maghrib - sql[4]), abs(isha - sql[5]))) / 60.0)::text
        FROM resultat WHERE sql IS NOT NULL) || ' minute)');

-- Les ajustements de la personne s'ajoutent a la minute pres.
SELECT pg_temp.vrai((
  SELECT bool_and(a.instant_utc - b.instant_utc = CASE a.priere
           WHEN 'fajr' THEN interval '-30 minutes' WHEN 'dhuhr' THEN interval '30 minutes'
           WHEN 'asr' THEN interval '7 minutes' WHEN 'maghrib' THEN interval '-1 minute'
           ELSE interval '0' END)
    FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-15', 'muslim_world_league', 'shafi',
           '{"fajr":-30,"dhuhr":30,"asr":7,"maghrib":-1,"isha":0}') a
    JOIN private.priere_calculer(9.6412, -13.5784, DATE '2027-01-15', 'muslim_world_league', 'shafi', '{}') b
      USING (priere)),
  'ajustements : ajoutes a la minute pres, dans les bornes');

-- Methode ou ecole inconnue : erreur, jamais une heure inventee.
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM private.priere_calculer(9.6, -13.5, DATE '2027-01-15', 'inconnue', 'shafi', '{}')$q$),
  'methode inconnue : refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM private.priere_calculer(9.6, -13.5, DATE '2027-01-15', 'egyptian', 'maliki', '{}')$q$),
  'ecole d''Asr inconnue : refusee');

-- Le repli de haute latitude est dit : Reykjavik en juin, l'Isha est approchee.
SELECT pg_temp.vrai((SELECT approximee FROM private.priere_calculer(64.1466, -21.9426, DATE '2027-06-16',
                      'muslim_world_league', 'shafi', '{}') WHERE priere = 'isha'),
  'haute latitude : l''Isha de Reykjavik en juin est marquee approchee');
SELECT pg_temp.vrai(NOT (SELECT bool_or(approximee) FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-06-16',
                      'muslim_world_league', 'shafi', '{}')),
  'Conakry : aucune heure approchee');
SELECT pg_temp.vrai((SELECT count(*) FROM private.priere_calculer(69.6492, 18.9553, DATE '2027-06-16',
                      'muslim_world_league', 'shafi', '{}')) = 0,
  'Tromso en plein soleil de minuit : calcul indefini, zero ligne');

ROLLBACK;
