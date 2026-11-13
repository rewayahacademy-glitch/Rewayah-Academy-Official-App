-- PRIERE-2 (20261124500000) : la priere sans formulaire.
-- Prouve : la position partagee par l'enseignant est arrondie au centieme de degre et
-- stockee sans autre trace ; elle n'est permise qu'a l'enseignant pour lui-meme (refus de
-- l'eleve, du tuteur, de la direction, de l'anonyme, de PUBLIC) ; un lieu pose par la
-- direction n'est jamais ecrase (ni par l'enseignant, ni par l'automatique) ; le lieu
-- automatique ne remplace ni celui de la direction ni la position de l'enseignant ; le
-- journal ne garde jamais la position ; la methode suit le pays du lieu (surcharge >
-- pays > academie) et se coupe par un reglage ; la liste de la direction ne rend aucune
-- coordonnee ; les pauses se recalculent aussitot.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier. Se termine par ROLLBACK.
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

-- Personnes (9f00...) : 01 enseignant qui partagera sa position, 02 enseignant dont la
-- direction pose le lieu, 03 enseignant pour l'automatique, 04 enseignant sans lieu ;
-- 10 direction ; 20 eleve mineur ; 22 tuteur.
INSERT INTO auth.users (id, email)
SELECT ('9f000000-0000-4000-8000-0000000000' || n)::uuid, 'zero-' || n || '@test.invalid'
  FROM unnest(ARRAY['01','02','03','04','10','20','22']) n;
INSERT INTO public.households (id, timezone) VALUES ('9f0000f1-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('9f000000-0000-4000-8000-000000000001','ZER-T1','teacher',NULL,'Aicha','Un','provisional_active','female'),
 ('9f000000-0000-4000-8000-000000000002','ZER-T2','teacher',NULL,'Bilal','Deux','provisional_active','male'),
 ('9f000000-0000-4000-8000-000000000003','ZER-T3','teacher',NULL,'Cheikh','Trois','provisional_active','male'),
 ('9f000000-0000-4000-8000-000000000004','ZER-T4','teacher',NULL,'Dina','Quatre','provisional_active','female'),
 ('9f000000-0000-4000-8000-000000000010','ZER-A','admin',NULL,'Direction','Zero','active','female'),
 ('9f000000-0000-4000-8000-000000000020','ZER-S1','student','9f0000f1-0000-4000-8000-000000000001','Eleve','Un','active','male'),
 ('9f000000-0000-4000-8000-000000000022','ZER-G1','guardian','9f0000f1-0000-4000-8000-000000000001','Tuteur','Un','active','female');
INSERT INTO public.teacher_profiles (profile_id, country, timezone_iana, kyc_status) VALUES
 ('9f000000-0000-4000-8000-000000000001','GN','Africa/Conakry','approved'),
 ('9f000000-0000-4000-8000-000000000002','SA','Asia/Riyadh','approved'),
 ('9f000000-0000-4000-8000-000000000003','GN','Africa/Conakry','approved'),
 ('9f000000-0000-4000-8000-000000000004','FR','Europe/Paris','approved');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
VALUES ('9f000000-0000-4000-8000-000000000020','minor','child');

-- Une classe et une seance de T1 : sans lieu, aucune pause ; le partage de position doit en creer une.
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('9f0000c0-0000-4000-8000-000000000001', '9f000000-0000-4000-8000-000000000001', 'enfant', 5,
        'ZER classe 1', 4, 19, 'Europe/Paris', 'indetermine');
CREATE TEMP TABLE h AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.64, -13.58, DATE '2027-01-15',
                                  'muslim_world_league', 'shafi', '{}');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9f0000e0-0000-4000-8000-000000000001', '9f000000-0000-4000-8000-000000000001',
       instant_utc - interval '25 minutes', instant_utc + interval '35 minutes', 'planned', 'standard',
       '9f0000c0-0000-4000-8000-000000000001'
  FROM h WHERE priere = 'maghrib';
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9f0000e0-0000-4000-8000-000000000001'),
  'sans lieu : aucune pause pour la seance de T1');

-- ===========================================================================
-- 1. L'enseignant partage sa position, pour lui-meme seulement
-- ===========================================================================
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000020', 'student', '9f0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.64123, -13.57841, 'Africa/Conakry')$q$),
  'un eleve ne partage pas de position de priere');
RESET ROLE;
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000022', 'guardian', '9f0000f1-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.64123, -13.57841, 'Africa/Conakry')$q$),
  'un tuteur ne partage pas de position de priere');
RESET ROLE;
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.64123, -13.57841, 'Africa/Conakry')$q$),
  'la direction ne partage pas de position pour un enseignant (la fonction ne sert qu''a l''enseignant, pour lui-meme)');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.64123, -13.57841, 'Africa/Conakry')$q$),
  'un anonyme ne partage pas de position de priere');
RESET ROLE;
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('anon', 'public.priere_ma_position(numeric, numeric, text)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('public', 'public.priere_ma_position(numeric, numeric, text)', 'EXECUTE')
                    AND pg_catalog.has_function_privilege('authenticated', 'public.priere_ma_position(numeric, numeric, text)', 'EXECUTE'),
  'droits d''execution : ni anon ni PUBLIC, authenticated seulement (la fonction decide qui)');
SELECT pg_temp.vrai((SELECT count(*) FROM pg_catalog.pg_proc p
                      WHERE p.proname = 'priere_ma_position'
                        AND NOT ('p_enseignant_id' = ANY (coalesce(p.proargnames, ARRAY[]::text[])))
                        AND NOT ('p_teacher_id' = ANY (coalesce(p.proargnames, ARRAY[]::text[])))) = 1,
  'la fonction n''a aucun parametre qui designe une autre personne');

-- Validation par le serveur.
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(91, -13.5, 'Africa/Conakry')$q$), 'latitude hors bornes refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.6, -181, 'Africa/Conakry')$q$), 'longitude hors bornes refusee');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(9.6, -13.5, 'Mars/Olympus')$q$), 'fuseau inconnu refuse');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(NULL, -13.5, 'Africa/Conakry')$q$), 'position vide refusee');

-- Le partage : arrondi au centieme, nom lisible, source « enseignant ».
SELECT public.priere_ma_position(9.64123, -13.57841, 'Africa/Conakry');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT latitude = 9.64 AND longitude = -13.58 AND timezone_iana = 'Africa/Conakry'
                            AND actif AND lieu_source = 'enseignant'
                            AND place_label = 'Votre position, fuseau Africa/Conakry'
                       FROM public.prayer_settings WHERE teacher_id = '9f000000-0000-4000-8000-000000000001'),
  'position partagee : arrondie au centieme de degre (9,64 ; -13,58), nom lisible, source « enseignant »');
SELECT pg_temp.vrai((SELECT latitude = pg_catalog.round(latitude, 2) AND longitude = pg_catalog.round(longitude, 2)
                       FROM public.prayer_settings WHERE teacher_id = '9f000000-0000-4000-8000-000000000001')
                    AND NOT EXISTS (SELECT 1 FROM public.prayer_settings WHERE latitude IN (9.64123, 9.641230) OR longitude = -13.57841),
  'la position exacte n''est stockee nulle part (aucune decimale au-dela du centieme)');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue WHERE session_id = '9f0000e0-0000-4000-8000-000000000001'),
  'les pauses sont calculees aussitot : la seance de T1 a sa pause de priere');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'priere_position_partagee') = 1
                    AND (SELECT count(*) FROM public.audit_logs WHERE action = 'priere_position_partagee'
                            AND (payload::text ILIKE '%latitude%' OR payload::text ILIKE '%longitude%'
                                 OR payload::text LIKE '%9.64%' OR payload::text LIKE '%13.5%')) = 0,
  'journal : le partage est trace sans la position');

-- Un nouveau partage met a jour (l'enseignant se deplace).
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.priere_ma_position(10.3849, -12.1234, 'Africa/Conakry');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT latitude = 10.38 AND longitude = -12.12 FROM public.prayer_settings
                      WHERE teacher_id = '9f000000-0000-4000-8000-000000000001'),
  'un nouveau partage remplace le precedent, arrondi de la meme facon');

-- ===========================================================================
-- 2. Un lieu pose par la direction n'est jamais ecrase
-- ===========================================================================
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9f000000-0000-4000-8000-000000000002', 'Riyad', 24.7136, 46.6753, 'Asia/Riyadh');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT lieu_source = 'direction' FROM public.prayer_settings
                      WHERE teacher_id = '9f000000-0000-4000-8000-000000000002'),
  'un lieu pose par la direction est marque « direction »');
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.priere_ma_position(48.85, 2.35, 'Europe/Paris')$q$),
  'l''enseignant ne remplace pas un lieu pose par la direction');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai(NOT private.priere_lieu_auto('9f000000-0000-4000-8000-000000000002', 'Paris', 48.857, 2.352, 'Europe/Paris'),
  'le lieu automatique ne remplace pas un lieu pose par la direction');
SELECT pg_temp.vrai((SELECT place_label = 'Riyad' AND timezone_iana = 'Asia/Riyadh' AND lieu_source = 'direction'
                       FROM public.prayer_settings WHERE teacher_id = '9f000000-0000-4000-8000-000000000002'),
  'le lieu de la direction est intact apres les deux tentatives');
-- La direction garde son pouvoir de retirer, puis de poser a nouveau.
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_retirer('9f000000-0000-4000-8000-000000000002');
SELECT pg_temp.personne();
SELECT pg_temp.vrai(private.priere_lieu_auto('9f000000-0000-4000-8000-000000000002', 'Riyad', 24.714, 46.675, 'Asia/Riyadh'),
  'apres retrait par la direction, le lieu automatique peut etre pose');

-- ===========================================================================
-- 3. Le lieu automatique (la ville de l'enseignant)
-- ===========================================================================
SELECT pg_temp.vrai(private.priere_lieu_auto('9f000000-0000-4000-8000-000000000003', 'Conakry', 9.5370, -13.6773, 'Africa/Conakry'),
  'sans lieu : le lieu automatique est pose');
SELECT pg_temp.vrai((SELECT lieu_source = 'auto' AND place_label = 'Conakry' AND actif AND defini_par IS NULL
                       FROM public.prayer_settings WHERE teacher_id = '9f000000-0000-4000-8000-000000000003'),
  'lieu automatique : source « auto », nom de la ville, personne n''a rien saisi');
SELECT pg_temp.vrai(private.priere_lieu_auto('9f000000-0000-4000-8000-000000000003', 'Kindia', 10.0565, -12.8658, 'Africa/Conakry'),
  'une autre ville : le lieu automatique est repose');
SELECT pg_temp.vrai((SELECT place_label FROM public.prayer_settings WHERE teacher_id = '9f000000-0000-4000-8000-000000000003') = 'Kindia',
  'une autre ville remplace l''ancien lieu automatique');
SELECT pg_temp.vrai(NOT private.priere_lieu_auto('9f000000-0000-4000-8000-000000000003', 'X', 95, 0, 'Africa/Conakry')
                    AND NOT private.priere_lieu_auto('9f000000-0000-4000-8000-000000000003', 'X', 9, 0, 'Mars/Olympus')
                    AND NOT private.priere_lieu_auto('9f000000-0000-4000-8000-000000000020', 'X', 9, 0, 'Africa/Conakry'),
  'lieu automatique : position hors bornes, fuseau inconnu et profil qui n''est pas enseignant refuses');
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000003', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.priere_ma_position(9.6, -13.6, 'Africa/Conakry');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai(NOT private.priere_lieu_auto('9f000000-0000-4000-8000-000000000003', 'Kindia', 10.0565, -12.8658, 'Africa/Conakry'),
  'la position partagee par l''enseignant l''emporte sur la ville : l''automatique ne la remplace pas');
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('authenticated', 'private.priere_lieu_auto(uuid, text, numeric, numeric, text)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('anon', 'private.priere_lieu_auto(uuid, text, numeric, numeric, text)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('public', 'private.priere_lieu_auto(uuid, text, numeric, numeric, text)', 'EXECUTE'),
  'private.priere_lieu_auto : aucun droit pour authenticated, anon ni PUBLIC');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'priere_lieu_auto'
                        AND (payload::text ILIKE '%latitude%' OR payload::text ILIKE '%longitude%')) = 0
                    AND (SELECT count(*) FROM public.audit_logs WHERE action = 'priere_lieu_auto') >= 2,
  'journal : le lieu automatique est trace sans la position');

-- ===========================================================================
-- 4. La methode suit le pays du lieu : surcharge > pays > academie
-- ===========================================================================
SELECT pg_temp.vrai(private.priere_methode_zone('Asia/Riyadh') = 'umm_al_qura'
                    AND private.priere_methode_zone('Asia/Qatar') = 'qatar'
                    AND private.priere_methode_zone('Asia/Kuwait') = 'kuwait'
                    AND private.priere_methode_zone('Asia/Dubai') = 'dubai'
                    AND private.priere_methode_zone('Africa/Cairo') = 'egyptian'
                    AND private.priere_methode_zone('Asia/Karachi') = 'karachi'
                    AND private.priere_methode_zone('Asia/Singapore') = 'singapore'
                    AND private.priere_methode_zone('Europe/Istanbul') = 'turkey'
                    AND private.priere_methode_zone('Asia/Tehran') = 'tehran',
  'methode du pays : neuf fuseaux, une methode chacun (docs/current/pedagogie/PRIERE.md)');
SELECT pg_temp.vrai(private.priere_methode_zone('Africa/Conakry') IS NULL
                    AND private.priere_methode_zone('Europe/Paris') IS NULL
                    AND private.priere_methode_zone('America/New_York') IS NULL
                    AND private.priere_methode_zone(NULL) IS NULL,
  'methode du pays : la Guinee, la France, l''Amerique du Nord et le vide n''ont pas de correspondance : academie');
SELECT pg_temp.vrai((SELECT bool_and(private.priere_methode_zone(n.name) IS NULL OR EXISTS (SELECT 1 FROM private.priere_methode(private.priere_methode_zone(n.name))))
                       FROM pg_catalog.pg_timezone_names n),
  'methode du pays : chaque methode deduite est une des douze methodes connues');
-- T2 : lieu automatique a Riyad -> Umm al-Qura ; T1 : Conakry -> academie.
SELECT pg_temp.vrai((SELECT methode = 'umm_al_qura' FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002'))
                    AND private.priere_methode_origine('9f000000-0000-4000-8000-000000000002') = 'pays',
  'lieu a Riyad : la methode appliquee est Umm al-Qura, d''origine « pays »');
SELECT pg_temp.vrai((SELECT methode = 'muslim_world_league' FROM private.priere_reglages('9f000000-0000-4000-8000-000000000001'))
                    AND private.priere_methode_origine('9f000000-0000-4000-8000-000000000001') = 'academie',
  'lieu a Conakry : la methode de l''academie (Ligue islamique mondiale), d''origine « academie »');
-- La surcharge de la direction l'emporte.
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9f000000-0000-4000-8000-000000000002', 'Riyad', 24.7136, 46.6753, 'Asia/Riyadh', 'egyptian');
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT methode = 'egyptian' FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002'))
                    AND private.priere_methode_origine('9f000000-0000-4000-8000-000000000002') = 'enseignant',
  'surcharge posee par la direction : elle l''emporte sur le pays');
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SELECT public.priere_lieu_definir('9f000000-0000-4000-8000-000000000002', 'Riyad', 24.7136, 46.6753, 'Asia/Riyadh');
SELECT pg_temp.personne();
-- Le reglage « methode selon le pays » se coupe, la methode de l'academie reprend.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'priere.methode_selon_pays';
SELECT pg_temp.vrai((SELECT methode = 'muslim_world_league' FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002'))
                    AND private.priere_methode_origine('9f000000-0000-4000-8000-000000000002') = 'academie',
  'reglage coupe : la methode de l''academie reprend partout');
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'priere.methode_selon_pays';
SELECT pg_temp.vrai((SELECT methode = 'umm_al_qura' FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002')),
  'reglage remis : Umm al-Qura revient');
SELECT pg_temp.vrai(pg_temp.refuse($q$UPDATE public.app_config SET value = '"oui"'::jsonb WHERE key = 'priere.methode_selon_pays'$q$)
                    AND pg_temp.refuse($q$UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'priere.methode_selon_pays'$q$),
  'reglage : « methode selon le pays » est vrai ou faux');
-- Les heures de Riyad suivent la methode du pays (le paquet de reference calcule la meme chose).
SELECT pg_temp.vrai((SELECT count(*) = 5 AND bool_and(a.instant_utc = b.instant_utc)
                       FROM private.priere_calculer(24.7136, 46.6753, DATE '2027-01-15', 'umm_al_qura', 'shafi', '{}') a
                       JOIN private.priere_calculer(
                              (SELECT lat FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002')),
                              (SELECT lon FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002')),
                              DATE '2027-01-15',
                              (SELECT methode FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002')),
                              (SELECT ecole FROM private.priere_reglages('9f000000-0000-4000-8000-000000000002')), '{}') b
                         ON b.priere = a.priere),
  'les heures de T2 sont celles de la methode du pays (Umm al-Qura)');

-- ===========================================================================
-- 5. La liste a lire de la direction, et les reglages lus
-- ===========================================================================
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000010', 'admin');
SELECT pg_temp.vrai((SELECT count(*) FROM public.priere_enseignants_vue()) = 4
                    AND (SELECT count(*) FROM public.priere_enseignants_vue() WHERE a_un_lieu) = 3,
  'liste de la direction : quatre enseignants, trois avec un lieu');
SELECT pg_temp.vrai((SELECT NOT a_un_lieu AND lieu IS NULL AND horaires IS NULL AND lieu_source IS NULL
                       FROM public.priere_enseignants_vue() WHERE enseignant_id = '9f000000-0000-4000-8000-000000000004'),
  'sans lieu : « en attente », aucune heure, aucune source');
SELECT pg_temp.vrai((SELECT a_un_lieu AND jsonb_array_length(horaires) = 5 AND methode = 'umm_al_qura'
                            AND methode_origine = 'pays' AND lieu_source = 'direction' AND lieu = 'Riyad'
                       FROM public.priere_enseignants_vue() WHERE enseignant_id = '9f000000-0000-4000-8000-000000000002'),
  'avec lieu : cinq heures du jour, methode appliquee et son origine, source du lieu, nom de la zone');
SELECT pg_temp.vrai((SELECT NOT (to_jsonb(v) ?| ARRAY['latitude','longitude','lat','lon'])
                            AND NOT (horaires::text ILIKE '%latitude%')
                       FROM public.priere_enseignants_vue() v LIMIT 1),
  'la liste de la direction ne porte aucune coordonnee');
SELECT pg_temp.vrai((SELECT (public.priere_reglages_lire('9f000000-0000-4000-8000-000000000002') ->> 'methode') = 'umm_al_qura'
                            AND (public.priere_reglages_lire('9f000000-0000-4000-8000-000000000002') ->> 'methode_origine') = 'pays'
                            AND (public.priere_reglages_lire('9f000000-0000-4000-8000-000000000002') ->> 'lieu_source') = 'direction'),
  'reglages lus : methode appliquee, origine et source du lieu');
SELECT pg_temp.en_tant_que('9f000000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_enseignants_vue()$q$), 'enseignant : la liste de la direction est refusee');
RESET ROLE;
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT * FROM public.priere_enseignants_vue()$q$), 'anonyme : la liste de la direction est refusee');
RESET ROLE;

ROLLBACK;
