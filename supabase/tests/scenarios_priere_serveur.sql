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


-- ===========================================================================
-- 2. Fixtures : personnes, classes, lieux
-- ===========================================================================
-- Personnes (9e00...) : 01 enseignant a Conakry, 02 enseignant a Paris, 03 enseignant
-- sans lieu, 04 enseignant a Tromso, 05 enseignant sans classe ; 10 direction ;
-- 20 eleve de la classe de 01 (foyer F1), 21 eleve d'une autre classe (foyer F2),
-- 22 tuteur de F1, 23 tuteur de F2.
INSERT INTO auth.users (id, email)
SELECT ('9e000000-0000-4000-8000-0000000000' || n)::uuid, 'priere-' || n || '@test.invalid'
  FROM unnest(ARRAY['01','02','03','04','05','10','20','21','22','23']) n;
INSERT INTO public.households (id, timezone) VALUES
  ('9e0000f1-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('9e0000f2-0000-4000-8000-000000000002', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('9e000000-0000-4000-8000-000000000001','PRI-T1','teacher',NULL,'Conakry','Un','provisional_active','male'),
 ('9e000000-0000-4000-8000-000000000002','PRI-T2','teacher',NULL,'Paris','Deux','provisional_active','male'),
 ('9e000000-0000-4000-8000-000000000003','PRI-T3','teacher',NULL,'Sans','Lieu','provisional_active','male'),
 ('9e000000-0000-4000-8000-000000000004','PRI-T4','teacher',NULL,'Tromso','Quatre','provisional_active','male'),
 ('9e000000-0000-4000-8000-000000000005','PRI-T5','teacher',NULL,'Autre','Cinq','provisional_active','male'),
 ('9e000000-0000-4000-8000-000000000010','PRI-A','admin',NULL,'Direction','Priere','active','female'),
 ('9e000000-0000-4000-8000-000000000020','PRI-S1','student','9e0000f1-0000-4000-8000-000000000001','Eleve','Un','active','male'),
 ('9e000000-0000-4000-8000-000000000021','PRI-S2','student','9e0000f2-0000-4000-8000-000000000002','Eleve','Deux','active','male'),
 ('9e000000-0000-4000-8000-000000000022','PRI-G1','guardian','9e0000f1-0000-4000-8000-000000000001','Tuteur','Un','active','female'),
 ('9e000000-0000-4000-8000-000000000023','PRI-G2','guardian','9e0000f2-0000-4000-8000-000000000002','Tuteur','Deux','active','female');
INSERT INTO public.teacher_profiles (profile_id, country, timezone_iana, kyc_status) VALUES
 ('9e000000-0000-4000-8000-000000000001','GN','Europe/Paris','approved'),
 ('9e000000-0000-4000-8000-000000000002','FR','Europe/Paris','approved'),
 ('9e000000-0000-4000-8000-000000000003','FR','Europe/Paris','approved'),
 ('9e000000-0000-4000-8000-000000000004','NO','Europe/Oslo','approved'),
 ('9e000000-0000-4000-8000-000000000005','FR','Europe/Paris','approved');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
VALUES ('9e000000-0000-4000-8000-000000000020','minor','child'),
       ('9e000000-0000-4000-8000-000000000021','minor','child');

-- Une classe par enseignant, jeudi (isodow 4) 19 h Europe/Paris, genre indetermine.
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
SELECT ('9e0000c0-0000-4000-8000-0000000000' || n)::uuid, ('9e000000-0000-4000-8000-0000000000' || n)::uuid,
       'enfant', 5, 'PRI classe ' || n, 4, 19, 'Europe/Paris', 'indetermine'
  FROM unnest(ARRAY['01','02','03','04','05']) n;
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
 ('9e0000c0-0000-4000-8000-000000000001', '9e000000-0000-4000-8000-000000000020'),
 ('9e0000c0-0000-4000-8000-000000000002', '9e000000-0000-4000-8000-000000000021');

-- Defaut de l'ecole, tel que le serveur le pose.
SELECT pg_temp.vrai((SELECT methode = 'muslim_world_league' AND ecole = 'shafi' AND pause = 10
                            AND pause_ramadan = 20 AND NOT ramadan AND marge_debut = 5
                            AND marge_fin = 15 AND horizon = 14 FROM private.priere_cfg()),
  'reglages de l''ecole : Ligue islamique mondiale, Asr majoritaire, 10 min, Ramadan 20, marges 5 et 15, 14 jours');

-- Sans lieu : aucune ligne, meme quand une seance existe.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('9e0000e0-0000-4000-8000-000000000003', '9e000000-0000-4000-8000-000000000003',
  TIMESTAMPTZ '2027-01-15 18:00+00', TIMESTAMPTZ '2027-01-15 19:00+00', 'planned', 'standard',
  '9e0000c0-0000-4000-8000-000000000003');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                                 WHERE session_id = '9e0000e0-0000-4000-8000-000000000003'),
  'sans lieu de priere : aucune ligne');

-- La direction pose les lieux (direction seulement).
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000005', 'teacher');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001',
  'Conakry', 9.6412, -13.5784, 'Africa/Conakry')$q$), 'un enseignant ne pose pas un lieu');
SELECT pg_temp.personne();
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001',
  'Conakry', 9.6412, -13.5784, 'Africa/Conakry')$q$), 'un anonyme ne pose pas un lieu');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001',
  'Conakry', 91, -13.5784, 'Africa/Conakry')$q$), 'latitude hors bornes refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001',
  'Conakry', 9.6412, -13.5784, 'Mars/Olympus')$q$), 'fuseau inconnu refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000020',
  'Eleve', 9.6412, -13.5784, 'Africa/Conakry')$q$), 'le lieu ne se pose que pour un enseignant');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001',
  'Conakry', 9.6412, -13.5784, 'Africa/Conakry', 'inconnue')$q$), 'methode inconnue refusee');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001', 'Conakry', 9.6412, -13.5784, 'Africa/Conakry');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000002', 'Paris', 48.8566, 2.3522, 'Europe/Paris');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000004', 'Tromso', 69.6492, 18.9553, 'Europe/Oslo');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'priere_lieu_defini'
                        AND payload::text NOT LIKE '%9.64%' AND payload::text NOT LIKE '%latitude%') = 3,
  'le journal garde qui a pose le lieu, jamais la position');

-- Les cinq heures de Conakry le 15/01/2027, sous la forme que lit le placement.
CREATE TEMP TABLE h_conakry AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-15',
                                  'muslim_world_league', 'shafi', '{}');
GRANT SELECT ON h_conakry TO authenticated;

-- ===========================================================================
-- 3. Le placement : milieu, debut, fin, deux prieres, Ramadan
-- ===========================================================================
-- Seance de 60 minutes : le Maghrib entre a 25 minutes -> pause a l'entree, 10 min.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000011', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '25 minutes', instant_utc + interval '35 minutes', 'planned', 'standard',
       '9e0000c0-0000-4000-8000-000000000001'
  FROM h_conakry WHERE priere = 'maghrib';
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc = h.instant_utc AND p.duree_minutes = 10
                            AND p.motif = 'priere' AND p.priere = 'maghrib'
                       FROM public.seance_pause_prevue p, h_conakry h
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000011' AND h.priere = 'maghrib'),
  'priere au milieu : la pause est a l''entree du Maghrib, 10 minutes, motif priere');

-- Dans les 5 premieres minutes : pause a 5 minutes du debut.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000012', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '3 minutes' + interval '1 day', instant_utc + interval '57 minutes' + interval '1 day',
       'planned', 'standard', '9e0000c0-0000-4000-8000-000000000001'
  FROM h_conakry WHERE priere = 'maghrib';
-- (le lendemain, le Maghrib bouge d'une minute au plus : on recalcule la reference du jour)
CREATE TEMP TABLE h_conakry_16 AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-16',
                                  'muslim_world_league', 'shafi', '{}');
UPDATE public.sessions s
   SET started_at = h.instant_utc - interval '3 minutes', ended_at = h.instant_utc + interval '57 minutes'
  FROM h_conakry_16 h
 WHERE s.id = '9e0000e0-0000-4000-8000-000000000012' AND h.priere = 'maghrib';
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc = s.started_at + interval '5 minutes'
                       FROM public.seance_pause_prevue p JOIN public.sessions s ON s.id = p.session_id
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000012'),
  'priere dans les 5 premieres minutes : la pause est a 5 minutes du debut');
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc + make_interval(mins => p.duree_minutes) <= s.ended_at
                       FROM public.seance_pause_prevue p JOIN public.sessions s ON s.id = p.session_id
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000012'),
  'la pause ne depasse jamais l''heure de fin annoncee');

-- Dans les 15 dernieres minutes (entree a 50 minutes sur 60) : aucune pause de priere.
CREATE TEMP TABLE h_conakry_17 AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-17',
                                  'muslim_world_league', 'shafi', '{}');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000013', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '50 minutes', instant_utc + interval '10 minutes', 'planned', 'standard',
       '9e0000c0-0000-4000-8000-000000000001'
  FROM h_conakry_17 WHERE priere = 'maghrib';
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                                 WHERE session_id = '9e0000e0-0000-4000-8000-000000000013'),
  'priere dans les 15 dernieres minutes : aucune pause de priere, l''enseignant prie apres le cours');

-- Deux prieres dans une seance de 90 minutes : le Maghrib (fenetre courte) d'abord.
CREATE TEMP TABLE h_conakry_18 AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-18',
                                  'muslim_world_league', 'shafi', '{}');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000014', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '5 minutes', instant_utc + interval '85 minutes', 'planned', 'standard',
       '9e0000c0-0000-4000-8000-000000000001'
  FROM h_conakry_18 WHERE priere = 'maghrib';
SELECT pg_temp.vrai((SELECT count(*) = 2 AND count(*) FILTER (WHERE retenue) = 1
                            AND bool_and(priere = 'maghrib') FILTER (WHERE retenue)
                       FROM private.priere_placer(
                              (SELECT started_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000014'),
                              (SELECT ended_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000014'),
                              9.6412, -13.5784, 'muslim_world_league', 'shafi', '{}', 10, 20, false, 5, 15)),
  'deux prieres dans 90 minutes : deux croisements, une seule pause, celle du Maghrib');
SELECT pg_temp.vrai((SELECT priere = 'maghrib' AND duree_minutes = 10
                       FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000014'),
  'deux prieres dans 90 minutes : la ligne du contrat porte le Maghrib, une seule');

-- Ramadan : le Maghrib dure 20 minutes ; le Dhuhr reste a 10.
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'priere.ramadan_en_cours';
SELECT pg_temp.vrai((SELECT duree_minutes = 20 FROM public.seance_pause_prevue
                      WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'Ramadan vrai : la pause du Maghrib passe a 20 minutes (recalcul par le changement de reglage)');
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc + make_interval(mins => p.duree_minutes) <= s.ended_at
                       FROM public.seance_pause_prevue p JOIN public.sessions s ON s.id = p.session_id
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000012'),
  'Ramadan vrai : la pause de 20 minutes ne depasse pas la fin (seance du debut)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                                 WHERE session_id = '9e0000e0-0000-4000-8000-000000000013'),
  'Ramadan vrai : la marge de fin grandit avec la pause, aucune pause tardive');
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'priere.ramadan_en_cours';
SELECT pg_temp.vrai((SELECT duree_minutes = 10 FROM public.seance_pause_prevue
                      WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'Ramadan faux : retour a 10 minutes');

-- Les reglages de l'ecole sont valides par le serveur.
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.app_config SET value = '7'::jsonb WHERE key = 'priere.pause_minutes'$q$),
  'reglage : une pause de 7 minutes est refusee (pas de 5)');
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.app_config SET value = '25'::jsonb WHERE key = 'priere.pause_minutes'$q$),
  'reglage : une pause de 25 minutes est refusee (bornes 5 a 20)');
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.app_config SET value = '"inconnue"'::jsonb WHERE key = 'priere.methode_defaut'$q$),
  'reglage : une methode inconnue est refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.app_config SET value = '"oui"'::jsonb WHERE key = 'priere.ramadan_en_cours'$q$),
  'reglage : le Ramadan est vrai ou faux');
SELECT pg_temp.vrai(pg_temp.refuse($q$INSERT INTO public.app_config (key, value) VALUES ('priere.inconnu', '1'::jsonb)$q$),
  'reglage : une cle priere.* inconnue est refusee');

-- L'ecole d'Asr et la methode d'un enseignant : surcharge ou defaut de l'ecole.
SELECT pg_temp.vrai((SELECT methode = 'muslim_world_league' AND ecole = 'shafi'
                       FROM private.priere_reglages('9e000000-0000-4000-8000-000000000001')),
  'enseignant sans surcharge : la methode et l''ecole de l''ecole');
UPDATE public.app_config SET value = '"hanafi"'::jsonb WHERE key = 'priere.ecole_asr_defaut';
SELECT pg_temp.vrai((SELECT ecole = 'hanafi' FROM private.priere_reglages('9e000000-0000-4000-8000-000000000001')),
  'defaut de l''ecole change : l''enseignant sans surcharge le suit');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001', 'Conakry', 9.6412, -13.5784,
  'Africa/Conakry', 'egyptian', 'shafi');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT methode = 'egyptian' AND ecole = 'shafi'
                       FROM private.priere_reglages('9e000000-0000-4000-8000-000000000001')),
  'surcharge par enseignant : la sienne l''emporte sur le defaut de l''ecole');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001', 'Conakry', 9.6412, -13.5784,
  'Africa/Conakry');
SELECT pg_temp.personne();
UPDATE public.app_config SET value = '"shafi"'::jsonb WHERE key = 'priere.ecole_asr_defaut';


-- Une priere qui entre a 42 minutes sur 60 : la pause de 10 minutes tient (limite 45) ;
-- pendant le Ramadan (20 minutes), la limite recule a 40 et la pause n'est plus placee.
CREATE TEMP TABLE h_conakry_19 AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-19',
                                  'muslim_world_league', 'shafi', '{}');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000015', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '42 minutes', instant_utc + interval '18 minutes', 'planned', 'standard',
       '9e0000c0-0000-4000-8000-000000000001'
  FROM h_conakry_19 WHERE priere = 'maghrib';
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000015'),
  'entree a 42 minutes sur 60 : la pause de 10 minutes est placee');
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'priere.ramadan_en_cours';
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000015'),
  'Ramadan vrai : la marge de fin suit la duree (entree a 42 minutes, pause de 20 : aucune pause de priere)');
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'priere.ramadan_en_cours';
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000015'),
  'Ramadan faux : la pause revient');

-- ===========================================================================
-- 4. Le remplissage par le serveur
-- ===========================================================================
-- Changement d'heure d'une seance : la pause suit, ou disparait.
UPDATE public.sessions SET started_at = started_at + interval '3 hours', ended_at = ended_at + interval '3 hours'
 WHERE id = '9e0000e0-0000-4000-8000-000000000011';
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'changement d''heure de la seance : plus aucune priere n''entre, la ligne disparait');
UPDATE public.sessions SET started_at = started_at - interval '3 hours', ended_at = ended_at - interval '3 hours'
 WHERE id = '9e0000e0-0000-4000-8000-000000000011';
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'
                              AND priere = 'maghrib'),
  'retour a l''heure d''origine : la ligne revient');

-- L'enseignant ajuste ses heures de -30 a +30 minutes, lui seul.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SELECT public.priere_ajuster('maghrib', 10);
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc = h.instant_utc + interval '10 minutes'
                       FROM public.seance_pause_prevue p, h_conakry h
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000011' AND h.priere = 'maghrib'),
  'ajustement du Maghrib de +10 minutes : la pause suit (recalcul par le changement de reglage)');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('maghrib', 31)$q$), 'ajustement de +31 refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('maghrib', -31)$q$), 'ajustement de -31 refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('sunrise', 1)$q$), 'priere inconnue refusee');
SELECT public.priere_ajuster('maghrib', 0);
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000003', 'teacher');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('maghrib', 3)$q$),
  'un enseignant sans lieu n''ajuste rien');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000020', 'student', '9e0000f1-0000-4000-8000-000000000001');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('maghrib', 3)$q$), 'un eleve n''ajuste rien');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ajuster('maghrib', 3)$q$),
  'la direction ajuste par le lieu, pas par la fonction de l''enseignant');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT p.debut_prevu_utc = h.instant_utc
                       FROM public.seance_pause_prevue p, h_conakry h
                      WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000011' AND h.priere = 'maghrib'),
  'ajustement remis a 0 : la pause revient a l''entree du Maghrib');

-- Changement du lieu par la direction : la pause suit le nouveau lieu.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001', 'Tokyo', 35.68, 139.69, 'Asia/Tokyo');
SELECT pg_temp.personne();
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'changement du lieu (Tokyo) : la priere de Conakry n''est plus celle de la seance, la ligne disparait');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000001', 'Conakry', 9.6412, -13.5784, 'Africa/Conakry');
SELECT pg_temp.personne();
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'lieu remis a Conakry : la ligne revient');

-- Changement d'heure du fuseau de la classe : l'heure locale est fixe (19 h a Paris),
-- l'heure UTC et donc la priere de l'enseignant a Conakry bougent.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('9e0000e0-0000-4000-8000-000000000021', '9e000000-0000-4000-8000-000000000001',
  (TIMESTAMP '2027-03-26 19:30' AT TIME ZONE 'Europe/Paris'), (TIMESTAMP '2027-03-26 20:30' AT TIME ZONE 'Europe/Paris'),
  'planned', 'standard', '9e0000c0-0000-4000-8000-000000000001'),
 ('9e0000e0-0000-4000-8000-000000000022', '9e000000-0000-4000-8000-000000000001',
  (TIMESTAMP '2027-04-02 19:30' AT TIME ZONE 'Europe/Paris'), (TIMESTAMP '2027-04-02 20:30' AT TIME ZONE 'Europe/Paris'),
  'planned', 'standard', '9e0000c0-0000-4000-8000-000000000001');
SELECT pg_temp.vrai((SELECT started_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000022')
                  - (SELECT started_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000021')
                  = interval '6 days 23 hours',
  'fuseau de la classe : 19 h 30 locale = 18 h 30 UTC avant le 28/03/2027, 17 h 30 UTC apres');
SELECT pg_temp.vrai((SELECT priere = 'maghrib' FROM public.seance_pause_prevue
                      WHERE session_id = '9e0000e0-0000-4000-8000-000000000021'),
  'avant le changement d''heure (18 h 30-19 h 30 UTC) : le Maghrib de Conakry entre pendant la seance');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                                 WHERE session_id = '9e0000e0-0000-4000-8000-000000000022'),
  'apres le changement d''heure (17 h 30-18 h 30 UTC) : plus aucune priere n''entre');

-- Seance annulee : la ligne est retiree. Seance commencee : elle ne bouge plus.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000016', '9e000000-0000-4000-8000-000000000001',
       instant_utc - interval '25 minutes' + interval '10 days', instant_utc + interval '35 minutes' + interval '10 days',
       'planned', 'standard', '9e0000c0-0000-4000-8000-000000000001'
  FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-25', 'muslim_world_league', 'shafi', '{}')
 WHERE priere = 'maghrib';
UPDATE public.sessions s SET started_at = h.instant_utc - interval '25 minutes', ended_at = h.instant_utc + interval '35 minutes'
  FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-25', 'muslim_world_league', 'shafi', '{}') h
 WHERE s.id = '9e0000e0-0000-4000-8000-000000000016' AND h.priere = 'maghrib';
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000016'),
  'seance a venir : ligne creee');
UPDATE public.sessions SET status = 'canceled' WHERE id = '9e0000e0-0000-4000-8000-000000000016';
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000016'),
  'seance annulee : la ligne est retiree');

-- Journal d'un calcul indefini : Tromso en plein soleil de minuit, une fois.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('9e0000e0-0000-4000-8000-000000000041', '9e000000-0000-4000-8000-000000000004',
  TIMESTAMPTZ '2027-06-16 18:00+00', TIMESTAMPTZ '2027-06-16 19:00+00', 'planned', 'standard',
  '9e0000c0-0000-4000-8000-000000000004');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000041'),
  'calcul indefini (Tromso, juin) : aucune pause de priere');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'priere_calcul_indefini'
                        AND row_id = '9e0000e0-0000-4000-8000-000000000041') = 1,
  'calcul indefini : une ligne au journal de la direction');
UPDATE public.sessions SET started_at = started_at + interval '1 minute' WHERE id = '9e0000e0-0000-4000-8000-000000000041';
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'priere_calcul_indefini'
                        AND row_id = '9e0000e0-0000-4000-8000-000000000041') = 1,
  'calcul indefini : jamais deux fois pour la meme seance');

-- Recalcul de nuit : une ligne faussee est corrigee ; seance a venir proche.
CREATE TEMP TABLE h_proche AS
  SELECT instant_utc FROM public.priere_horaires_jour('9e000000-0000-4000-8000-000000000001', NULL) LIMIT 0;
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e0000e0-0000-4000-8000-000000000051', '9e000000-0000-4000-8000-000000000001',
       c.instant_utc - interval '20 minutes' + interval '3 days', c.instant_utc + interval '40 minutes' + interval '3 days',
       'planned', 'standard', '9e0000c0-0000-4000-8000-000000000001'
  FROM private.priere_calculer(9.6412, -13.5784, ((now() AT TIME ZONE 'UTC')::date), 'muslim_world_league', 'shafi', '{}') c
 WHERE c.priere = 'maghrib';
-- (le Maghrib de dans trois jours differe de moins de deux minutes de celui d'aujourd'hui :
--  on recale la seance sur le vrai Maghrib du jour cible)
UPDATE public.sessions s SET started_at = c.instant_utc - interval '20 minutes', ended_at = c.instant_utc + interval '40 minutes'
  FROM private.priere_calculer(9.6412, -13.5784, ((now() AT TIME ZONE 'UTC')::date + 3), 'muslim_world_league', 'shafi', '{}') c
 WHERE s.id = '9e0000e0-0000-4000-8000-000000000051' AND c.priere = 'maghrib';
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000051'),
  'seance a trois jours : ligne creee');
UPDATE public.seance_pause_prevue_stock SET debut_prevu_utc = debut_prevu_utc + interval '1 hour', priere = 'asr'
 WHERE session_id = '9e0000e0-0000-4000-8000-000000000051';
SELECT pg_temp.vrai((SELECT priere = 'asr' FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000051'),
  'ligne faussee a la main (preparation du controle)');
SELECT pg_temp.vrai(private.priere_recalculer_horizon() >= 1, 'recalcul de nuit : au moins une seance traitee');
SELECT pg_temp.vrai((SELECT priere = 'maghrib' FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000051'),
  'recalcul de nuit : la ligne faussee est corrigee');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_recalculer_maintenant()$q$),
  'recalcul a la main : refuse sans double authentification');
SELECT pg_temp.personne();

-- ===========================================================================
-- 5. Les droits
-- ===========================================================================
-- Lire la pause prevue : direction, enseignant de la seance, eleves de la classe, foyer.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000020', 'student', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')) = 1,
  'eleve de la classe : lit l''heure de la pause');
SELECT pg_temp.vrai((SELECT array_agg(k ORDER BY k) = ARRAY['debut_prevu_utc','duree_minutes','motif','priere']
                       FROM (SELECT jsonb_object_keys(to_jsonb(p)) k
                               FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011') p) q),
  'eleve de la classe : quatre colonnes, aucun lieu');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.seance_pause_prevue$q$), 'la vue du contrat n''a aucun droit direct');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.seance_pause_prevue_stock$q$), 'le stock n''a aucun droit direct');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM private.priere_calculer(9, -13, DATE '2027-01-15', 'egyptian', 'shafi', '{}')$q$),
  'le calcul prive n''est pas appelable par un client');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000022', 'guardian', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')) = 1,
  'tuteur du foyer de l''eleve : lit l''heure de la pause');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')) = 1,
  'enseignant titulaire : lit l''heure de la pause');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')) = 1,
  'direction : lit l''heure de la pause');
RESET ROLE;
-- Refus : eleve d'une autre classe, son tuteur, un autre enseignant, un inconnu.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000021', 'student', '9e0000f2-0000-4000-8000-000000000002');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')$q$),
  'eleve d''une autre classe : refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000023', 'guardian', '9e0000f2-0000-4000-8000-000000000002');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')$q$),
  'tuteur d''un autre foyer : refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000005', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')$q$),
  'enseignant etranger a la seance : refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('00000000-0000-4000-8000-00000000dead')$q$),
  'seance inconnue : meme refus');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000011')$q$),
  'anonyme : refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000020', 'student', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance(NULL)$q$) OR
  (SELECT count(*) FROM public.pause_prevue_seance(NULL)) = 0, 'seance nulle : rien');
RESET ROLE;

-- La position : lue par l'enseignant et la direction seulement.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000020', 'student', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings) = 0, 'eleve : ne lit aucune position');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_reglages_lire('9e000000-0000-4000-8000-000000000001')$q$),
  'eleve : priere_reglages_lire refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_horaires_jour('9e000000-0000-4000-8000-000000000001')$q$),
  'eleve : priere_horaires_jour refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000022', 'guardian', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings) = 0,
  'tuteur de la classe : ne lit aucune position (l''ancienne politique l''admettait)');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000005', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings) = 0, 'enseignant d''une autre classe : ne lit pas celle d''un collegue');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_reglages_lire('9e000000-0000-4000-8000-000000000001')$q$),
  'enseignant : refuse de lire les reglages d''un collegue');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings) = 1 AND (SELECT lieu FROM (SELECT public.priere_reglages_lire() ->> 'lieu' AS lieu) q) = 'Conakry',
  'enseignant : lit son lieu');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_horaires_jour()) = 5, 'enseignant : lit ses cinq heures du jour');
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.prayer_settings SET latitude = 0$q$),
  'enseignant : n''ecrit pas son lieu (droit d''ecriture retire)');
SELECT pg_temp.vrai(pg_temp.refuse($q$INSERT INTO public.prayer_settings (teacher_id, latitude, longitude)
  VALUES ('9e000000-0000-4000-8000-000000000001', 1, 1)$q$), 'enseignant : n''insere rien');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings) = 3, 'direction : lit les trois lieux');
SELECT pg_temp.vrai((SELECT public.priere_reglages_lire('9e000000-0000-4000-8000-000000000001') ->> 'fuseau') = 'Africa/Conakry',
  'direction : lit les reglages d''un enseignant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_horaires_jour('9e000000-0000-4000-8000-000000000001')) = 5,
  'direction : apercu des cinq heures du jour');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.prayer_settings$q$), 'anonyme : aucun droit sur les reglages');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_reglages_lire()$q$), 'anonyme : priere_reglages_lire refuse');
RESET ROLE;


-- ===========================================================================
-- 6. Changement d'enseignant : la pause suit le lieu de celui qui enseigne
-- ===========================================================================
-- Seance 12 (debut de seance, Conakry). Le remplacant T3 n'a pas de lieu : aucune ligne.
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000012'),
  'avant le remplacement : la seance porte la pause de Conakry');
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id,
  enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('9e0000e0-0000-4000-8000-000000000012', 'remplacement_designe_admin',
  '9e000000-0000-4000-8000-000000000001', '9e000000-0000-4000-8000-000000000003',
  '9e000000-0000-4000-8000-000000000010', '9e0000a0-0000-4000-8000-000000000001');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9e0000e0-0000-4000-8000-000000000012'),
  'remplacant sans lieu : aucune ligne');
-- Le remplacant suivant, T2, est a Paris : la pause suit son lieu, pas celui du titulaire.
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id,
  enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('9e0000e0-0000-4000-8000-000000000012', 'remplacement_designe_admin',
  '9e000000-0000-4000-8000-000000000001', '9e000000-0000-4000-8000-000000000002',
  '9e000000-0000-4000-8000-000000000010', '9e0000a0-0000-4000-8000-000000000002');
CREATE TEMP TABLE attendu_paris AS
  SELECT x.priere, x.debut_prevu_utc
    FROM private.priere_placer(
           (SELECT started_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000012'),
           (SELECT ended_at FROM public.sessions WHERE id = '9e0000e0-0000-4000-8000-000000000012'),
           48.8566, 2.3522, 'muslim_world_league', 'shafi', '{}', 10, 20, false, 5, 15) x
   WHERE x.retenue;
SELECT pg_temp.vrai(
  CASE WHEN EXISTS (SELECT 1 FROM attendu_paris)
       THEN (SELECT p.priere = a.priere AND p.debut_prevu_utc = a.debut_prevu_utc
               FROM public.seance_pause_prevue p, attendu_paris a
              WHERE p.session_id = '9e0000e0-0000-4000-8000-000000000012')
       ELSE NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                         WHERE session_id = '9e0000e0-0000-4000-8000-000000000012') END,
  'remplacant a Paris : la pause suit le lieu de celui qui enseigne reellement');
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('9e0000e0-0000-4000-8000-000000000012')
                    = '9e000000-0000-4000-8000-000000000002',
  'le dernier remplacement fait foi (T2)');
-- Les droits suivent l'enseignant qui enseigne : le remplacant lit, le titulaire plus.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000012')$q$),
  'remplacant accepte : lit la pause de la seance');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.pause_prevue_seance('9e0000e0-0000-4000-8000-000000000012')$q$),
  'titulaire remplace : ne lit plus la pause de la seance');
RESET ROLE;
SELECT pg_temp.personne();

-- ===========================================================================
-- 7. Les lectures de la direction : croisements, heures sans priere, vendredi
-- ===========================================================================
SELECT pg_temp.vrai((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000003', 4, 19, 'Europe/Paris', 60))
                      = '{"sans_lieu": true}'::jsonb,
  'enseignant sans lieu : la lecture dit « sans lieu », rien d''autre');

CREATE TEMP TABLE lecture AS
  SELECT private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60) AS j;
SELECT pg_temp.vrai((SELECT (j ->> 'seances')::int BETWEEN 51 AND 54 AND NOT (j ->> 'sans_lieu')::boolean
                       FROM lecture),
  'creneau du jeudi 19 h : 52 ou 53 seances sur 12 mois');
SELECT pg_temp.vrai((SELECT jsonb_array_length(j -> 'croisements') > 0 FROM lecture),
  'creneau du jeudi 19 h a Paris, enseignant a Conakry : des croisements existent');
-- Le changement d'heure de la classe : le Maghrib de Conakry croise le creneau l'hiver
-- (18 h-19 h UTC), jamais l'ete (17 h-18 h UTC). Controle date-independant : chaque
-- seance croisee est en heure d'hiver de Paris, et au moins une seance d'ete ne croise rien.
SELECT pg_temp.vrai((SELECT bool_and(((o.debut_utc AT TIME ZONE 'Europe/Paris') - (o.debut_utc AT TIME ZONE 'UTC')) = interval '1 hour')
                       FROM private.priere_occurrences(4, 19, 'Europe/Paris') o
                       JOIN private.priere_projection('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60) p
                         ON p.jour_local = o.jour_local
                      WHERE p.priere = 'maghrib'),
  'croisement du Maghrib : seulement les seances en heure d''hiver de la classe (changement d''heure pris en compte)');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM private.priere_occurrences(4, 19, 'Europe/Paris') o
                              JOIN private.priere_projection('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60) p
                                ON p.jour_local = o.jour_local
                             WHERE p.zone = 'aucune'
                               AND ((o.debut_utc AT TIME ZONE 'Europe/Paris') - (o.debut_utc AT TIME ZONE 'UTC')) = interval '2 hours'),
  'au moins une seance d''ete (heure UTC avancee) ne croise aucune priere');
-- Les periodes sont consecutives, comptees, et leur total est celui des croisements.
SELECT pg_temp.vrai((SELECT coalesce(sum((c ->> 'nb_seances')::int), 0)
                            = (SELECT count(*) FROM private.priere_projection(
                                 '9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60) q
                                WHERE q.priere IS NOT NULL)
                       FROM lecture, jsonb_array_elements(lecture.j -> 'croisements') c),
  'les periodes totalisent exactement les croisements de la projection');
SELECT pg_temp.vrai((SELECT bool_and((c ->> 'nb_pause')::int + (c ->> 'nb_apres_cours')::int = (c ->> 'nb_seances')::int
                                     AND (c ->> 'du')::date <= (c ->> 'au')::date)
                       FROM lecture, jsonb_array_elements(lecture.j -> 'croisements') c),
  'chaque periode : pause placee + priere apres le cours = seances ; du <= au');
-- Heures sans priere : coherentes avec les croisements (autre chemin de calcul).
SELECT pg_temp.vrai(
  (SELECT bool_and(NOT EXISTS (SELECT 1 FROM private.priere_projection('9e000000-0000-4000-8000-000000000001',
                                  4, h, 'Europe/Paris', 60) q WHERE q.priere IS NOT NULL OR q.indefini))
     FROM unnest(private.priere_heures_sans_priere('9e000000-0000-4000-8000-000000000001', 4, 'Europe/Paris', 60)) h),
  'heures sans priere : aucune seance de ces heures ne croise une priere sur toute l''annee');
SELECT pg_temp.vrai(
  (SELECT bool_and(EXISTS (SELECT 1 FROM private.priere_projection('9e000000-0000-4000-8000-000000000001',
                                  4, h, 'Europe/Paris', 60) q WHERE q.priere IS NOT NULL))
     FROM generate_series(0, 23) h
    WHERE h <> ALL (private.priere_heures_sans_priere('9e000000-0000-4000-8000-000000000001', 4, 'Europe/Paris', 60))),
  'heures sans priere : toute autre heure croise au moins une priere');
SELECT pg_temp.vrai((SELECT cardinality(private.priere_heures_sans_priere('9e000000-0000-4000-8000-000000000001',
                                                         4, 'Europe/Paris', 60)) BETWEEN 1 AND 23),
  'heures sans priere : une liste non vide et non pleine');
SELECT pg_temp.vrai(private.priere_heures_sans_priere('9e000000-0000-4000-8000-000000000003', 4, 'Europe/Paris', 60) IS NULL,
  'heures sans priere : sans lieu, la reponse est « inconnu », pas une liste complete');
SELECT pg_temp.vrai(private.priere_heures_sans_priere('9e000000-0000-4000-8000-000000000004', 4, 'Europe/Oslo', 60) IS NULL,
  'heures sans priere : calcul indefini sur l''annee (Tromso), la reponse est « inconnu »');

-- Vendredi (P9) : avertissement quand l'enseignant assiste a la priere et que le creneau chevauche sa plage.
SELECT pg_temp.vrai(((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 13, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int = 0
                    AND NOT ((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 13, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'assiste')::boolean,
  'vendredi : reglage faux par defaut, aucun avertissement');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000002', 'Paris', 48.8566, 2.3522, 'Europe/Paris',
  NULL, NULL, true);
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000002', 'Paris',
  48.8566, 2.3522, 'Europe/Paris', NULL, NULL, true, TIME '14:00', TIME '13:00')$q$), 'plage du vendredi inversee refusee');
SELECT pg_temp.personne();
SELECT pg_temp.vrai(((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 13, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int
                    = (private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 13, 'Europe/Paris', 60) ->> 'seances')::int
                    AND ((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 13, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int > 0,
  'vendredi : assiste, creneau du vendredi 13 h : toutes les seances sont signalees');
SELECT pg_temp.vrai(((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 15, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int = 0,
  'vendredi : creneau a 15 h, hors de la plage 12 h 30-14 h 30 : aucun signalement');
SELECT pg_temp.vrai(((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 4, 13, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int = 0,
  'vendredi : creneau du jeudi, aucun signalement');
-- 12 h-13 h chevauche la plage 12 h 30-14 h 30 : signale. 11 h-12 h : non.
SELECT pg_temp.vrai(((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 12, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int > 0
                    AND ((private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000002', 5, 11, 'Europe/Paris', 60))
                       -> 'vendredi' ->> 'nb_seances')::int = 0,
  'vendredi : 12 h-13 h chevauche la plage, 11 h-12 h non');

-- La direction lit tout par les fonctions publiques ; les autres sont refuses.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT jsonb_array_length(public.priere_lecture_classe('9e0000c0-0000-4000-8000-000000000001') -> 'creneaux') >= 1),
  'direction : le bloc d''une classe donne au moins un creneau');
SELECT pg_temp.vrai((SELECT public.priere_lecture_classe('9e0000c0-0000-4000-8000-000000000001') -> 'creneaux' -> 0 ->> 'duree_minutes') IS NOT NULL,
  'direction : la duree de la classe est lue (seance a venir ou reglage de l''ecole)');
SELECT pg_temp.vrai((SELECT public.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60)) IS NOT NULL,
  'direction : lecture d''un creneau');
SELECT pg_temp.vrai((SELECT cardinality(public.priere_creneaux_sans_priere('9e000000-0000-4000-8000-000000000001', 4, 'Europe/Paris', 60))) > 0,
  'direction : heures sans priere');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 9, 19, 'Europe/Paris', 60)$q$),
  'creneau invalide (jour 9) refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 4, 19, 'Mars/Olympus', 60)$q$),
  'creneau invalide (fuseau inconnu) refuse');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_classe('9e0000c0-0000-4000-8000-000000000001')$q$), 'enseignant : lecture de classe refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60)$q$), 'enseignant : lecture de creneau refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_creneaux_sans_priere('9e000000-0000-4000-8000-000000000001', 4, 'Europe/Paris', 60)$q$), 'enseignant : heures sans priere refusees');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_incoherences_enseignants()$q$), 'enseignant : incoherences refusees');
RESET ROLE;
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000022', 'guardian', '9e0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_classe('9e0000c0-0000-4000-8000-000000000001')$q$), 'tuteur : lecture de classe refusee');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_lecture_classe('9e0000c0-0000-4000-8000-000000000001')$q$), 'anonyme : lecture de classe refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_incoherences_enseignants()$q$), 'anonyme : incoherences refusees');
RESET ROLE;

-- Incoherences : fuseau du compte, fuseau du lieu, pays du compte.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9e000000-0000-4000-8000-000000000005', 'Conakry', 9.6412, -13.5784, 'Asia/Tokyo');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000001' AND motif = 'fuseau_compte_different') = 1,
  'incoherence : Conakry, compte en Europe/Paris, lieu en Africa/Conakry, est signale (le cas reel de la production)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000001' AND motif = 'pays_lieu_incoherent') = 0,
  'incoherence : pays GN et lieu a Conakry concordent, aucun signal de pays');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000005' AND motif = 'fuseau_lieu_incoherent') = 1,
  'incoherence : un lieu a Conakry avec le fuseau Asia/Tokyo est signale');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000002') = 0,
  'incoherence : Paris, compte FR en Europe/Paris, lieu a Paris : rien a signaler');
SELECT pg_temp.personne();
UPDATE public.teacher_profiles SET country = 'FR' WHERE profile_id = '9e000000-0000-4000-8000-000000000001';
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000001' AND motif = 'pays_lieu_incoherent') = 1,
  'incoherence : pays FR et lieu a Conakry sont signales');
SELECT pg_temp.personne();
-- Le cas releve en production : pays Guinee, fuseau Europe/Paris, AUCUN lieu pose.
UPDATE public.teacher_profiles SET country = 'GN' WHERE profile_id = '9e000000-0000-4000-8000-000000000003';
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000003'
                        AND motif = 'pays_fuseau_incoherent' AND detail = 'GN / Europe/Paris') = 1,
  'incoherence : pays GN et fuseau Europe/Paris, meme sans lieu de priere, est signale (le cas de la production)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_incoherences_enseignants()
                      WHERE enseignant_id = '9e000000-0000-4000-8000-000000000005'
                        AND motif = 'pays_fuseau_incoherent') = 0,
  'incoherence : pays FR et fuseau Europe/Paris concordent');
SELECT pg_temp.personne();
UPDATE public.teacher_profiles SET country = 'FR' WHERE profile_id = '9e000000-0000-4000-8000-000000000003';

-- Rien n'est corrige automatiquement : le lieu et le fuseau enregistres n'ont pas bouge.
SELECT pg_temp.vrai((SELECT timezone_iana FROM public.teacher_profiles WHERE profile_id = '9e000000-0000-4000-8000-000000000001') = 'Europe/Paris'
                    AND (SELECT timezone_iana FROM public.prayer_settings WHERE teacher_id = '9e000000-0000-4000-8000-000000000001') = 'Africa/Conakry',
  'incoherence : rien n''est corrige automatiquement');

-- Retrait du lieu : la position est ecrasee, les pauses disparaissent.
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_retirer('9e000000-0000-4000-8000-000000000001');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT NOT actif AND latitude = 0 AND longitude = 0 AND place_label IS NULL
                       FROM public.prayer_settings WHERE teacher_id = '9e000000-0000-4000-8000-000000000001'),
  'lieu retire : la position est ecrasee');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue
                                 WHERE session_id = '9e0000e0-0000-4000-8000-000000000011'),
  'lieu retire : plus aucune pause de priere pour cet enseignant');
SELECT pg_temp.vrai(private.priere_lecture_creneau('9e000000-0000-4000-8000-000000000001', 4, 19, 'Europe/Paris', 60)
                    = '{"sans_lieu": true}'::jsonb, 'lieu retire : la lecture dit « sans lieu »');

-- La liste des enseignants et de leur lieu (ecran « Lieux de priere » de la direction).
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_enseignants_liste()) = 5
                    AND (SELECT count(*) FROM public.priere_enseignants_liste() WHERE a_un_lieu) = 3
                    AND (SELECT NOT a_un_lieu AND lieu IS NULL FROM public.priere_enseignants_liste()
                          WHERE enseignant_id = '9e000000-0000-4000-8000-000000000001'),
  'liste des enseignants : cinq enseignants, trois lieux, celui dont le lieu est retire n''en montre aucun');
SELECT pg_temp.en_tant_que('9e000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_enseignants_liste()$q$), 'enseignant : liste refusee');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_enseignants_liste()$q$), 'anonyme : liste refusee');
RESET ROLE;

ROLLBACK;
