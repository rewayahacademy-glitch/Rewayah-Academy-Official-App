-- A3 (20261102500000) : remplacer un titulaire qui n'est pas entre.
-- Prouve : minutes 3, 8 et 11 ; le premier pret gagne ; aucune annulation ;
-- le retour du titulaire avant T+8 (remplacement inutile) ; une seance deja
-- ouverte (in_progress, un eleve entre avant le titulaire) suit le meme deroule.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
-- Les declencheurs des familles sont differes a la validation : on les veut
-- tout de suite pour lire leurs notifications.
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.debut(p_seance text) RETURNS timestamptz
LANGUAGE sql AS $$ SELECT started_at FROM public.sessions WHERE id = p_seance::uuid $$;
CREATE FUNCTION pg_temp.notifie(p_qui text, p_evenement text, p_seance text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.destinataire = p_qui::uuid AND n.evenement = p_evenement
                    AND n.params->>'session_id' = p_seance) $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
END $$;

SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'remplacement.avertissement_minutes') = '3'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'remplacement.perte_acces_minutes') = '8'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'remplacement.debut_remplacant_minutes') = '11'::jsonb,
  'reglages 3, 8, 11 poses dans app_config');

-- T1, T2, T3 titulaires ; R1, R2 candidats (hommes) ; F enseignante (classe
-- d'hommes : pas candidate) ; P et S, tuteur et eleve de la classe de T1 ; A
-- la direction.
INSERT INTO auth.users (id, email) VALUES
 ('a3000000-0000-0000-0000-000000000001','a3-t1@test.invalid'), ('a3000000-0000-0000-0000-000000000002','a3-t2@test.invalid'), ('a3000000-0000-0000-0000-000000000003','a3-t3@test.invalid'), ('a3000000-0000-0000-0000-000000000004','a3-t4@test.invalid'),
 ('a3000000-0000-0000-0000-000000000009','a3-r1@test.invalid'), ('a3000000-0000-0000-0000-000000000008','a3-r2@test.invalid'), ('a3000000-0000-0000-0000-000000000007','a3-f@test.invalid'),
 ('a3000000-0000-0000-0000-000000000011','a3-p@test.invalid'), ('a3000000-0000-0000-0000-000000000012','a3-s@test.invalid'), ('a3000000-0000-0000-0000-000000000013','a3-a@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('a3000000-0000-0000-0000-000000000301','Europe/Paris');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('a3000000-0000-0000-0000-000000000001','A3-T1','teacher',NULL,'Titulaire','Un','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000002','A3-T2','teacher',NULL,'Titulaire','Deux','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000003','A3-T3','teacher',NULL,'Titulaire','Trois','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000004','A3-T4','teacher',NULL,'Titulaire','Quatre','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000009','A3-R1','teacher',NULL,'Pret','Un','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000008','A3-R2','teacher',NULL,'Pret','Deux','provisional_active','male'),
 ('a3000000-0000-0000-0000-000000000007','A3-F','teacher',NULL,'Enseignante','F','provisional_active','female'),
 ('a3000000-0000-0000-0000-000000000011','A3-P','guardian','a3000000-0000-0000-0000-000000000301','Tuteur','P','active','female'),
 ('a3000000-0000-0000-0000-000000000012','A3-S','student','a3000000-0000-0000-0000-000000000301','Eleve','S','active','male'),
 ('a3000000-0000-0000-0000-000000000013','A3-A','admin',NULL,'Direction','A','active','female');
UPDATE public.households SET primary_guardian_id = 'a3000000-0000-0000-0000-000000000011' WHERE id = 'a3000000-0000-0000-0000-000000000301';
INSERT INTO public.teacher_profiles (profile_id, kyc_status)
SELECT id, 'approved' FROM public.profiles WHERE id::text LIKE 'a3000000-%' AND role = 'teacher';
DO $fixture_contrats$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active'
                    AND id::text LIKE 'a3000000-%' LOOP
  PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true); PERFORM set_config('test.uid',v_teacher.id::text,true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true); PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version) ON CONFLICT DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES (v_teacher.id,'teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
 END LOOP;
 PERFORM set_config('request.jwt.claim.sub','',true); PERFORM set_config('request.jwt.claims','',true);
 PERFORM set_config('test.uid','',true); PERFORM set_config('test.jwt','',true);
END
$fixture_contrats$;

INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
VALUES
 ('a3000000-0000-0000-0000-000000000101','a3000000-0000-0000-0000-000000000001','enfant',5,'A3 classe 1',extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int,18,'Europe/Paris','hommes', now() - interval '1 day'),
 ('a3000000-0000-0000-0000-000000000102','a3000000-0000-0000-0000-000000000002','enfant',5,'A3 classe 2',extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int,18,'Europe/Paris','hommes', now() - interval '1 day'),
 ('a3000000-0000-0000-0000-000000000103','a3000000-0000-0000-0000-000000000003','enfant',5,'A3 classe 3',extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int,18,'Europe/Paris','hommes', now() - interval '1 day'),
 ('a3000000-0000-0000-0000-000000000104','a3000000-0000-0000-0000-000000000004','enfant',5,'A3 classe 4',extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int,18,'Europe/Paris','hommes', now() - interval '1 day');
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at)
VALUES ('a3000000-0000-0000-0000-000000000101','a3000000-0000-0000-0000-000000000012', now() - interval '1 day');
-- Le jour des classes est celui de dans trois jours : les seances que leur
-- creation genere ne chevauchent jamais les seances d'essai, posees autour
-- de maintenant (sessions_no_teacher_overlap).
-- S1 a commence il y a 4 min, S2 il y a 11 min, S3 il y a 5 min.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('a3000000-0000-0000-0000-000000000201','a3000000-0000-0000-0000-000000000001', now() - interval '4 minutes',  now() + interval '41 minutes', 'planned','standard','a3000000-0000-0000-0000-000000000101'),
 ('a3000000-0000-0000-0000-000000000202','a3000000-0000-0000-0000-000000000002', now() - interval '11 minutes', now() + interval '34 minutes', 'planned','standard','a3000000-0000-0000-0000-000000000102'),
 ('a3000000-0000-0000-0000-000000000203','a3000000-0000-0000-0000-000000000003', now() - interval '5 minutes',  now() + interval '40 minutes', 'planned','standard','a3000000-0000-0000-0000-000000000103'),
 ('a3000000-0000-0000-0000-000000000204','a3000000-0000-0000-0000-000000000004', now() - interval '4 minutes',  now() + interval '41 minutes', 'planned','standard','a3000000-0000-0000-0000-000000000104');
-- A3-bis (20261105700000) : des seances creees la veille, pas « creees tard ».
UPDATE public.sessions SET created_at = now() - interval '1 day'
 WHERE id::text LIKE 'a3000000-0000-0000-0000-0000000002%';
-- S4 : un eleve est entre avant le titulaire, la seance est ouverte (in_progress).
UPDATE public.sessions SET status = 'preflight' WHERE id = 'a3000000-0000-0000-0000-000000000204';
UPDATE public.sessions SET status = 'in_progress' WHERE id = 'a3000000-0000-0000-0000-000000000204';

-- Minute 2 de S1 : rien encore pour S1.
SELECT private.remplacement_auto_passer(pg_temp.debut('a3000000-0000-0000-0000-000000000201') + interval '2 minutes');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_preparation WHERE session_id = 'a3000000-0000-0000-0000-000000000201'),
  'minute 2 : aucune pre-alerte');
-- Le meme passage a vu S3 a sa minute 3 et S2 a sa minute 9 : depuis A3-bis
-- (20261105700000), la pre-alerte vaut jusqu'a la fin prevue ; S2 la recoit,
-- mais sans avertissement du titulaire (T+perte est passe).
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_preparation
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000202' AND evenement = 'pre_alerte')
  AND NOT pg_temp.notifie('a3000000-0000-0000-0000-000000000002', 'remplacement_avertissement', 'a3000000-0000-0000-0000-000000000202'),
  'A3-bis : S2 a sa minute 9 recoit la pre-alerte, sans avertissement du titulaire');

-- Minute 3 de S1 : avertissement du titulaire, pre-alerte aux candidats.
SELECT private.remplacement_auto_passer(pg_temp.debut('a3000000-0000-0000-0000-000000000201') + interval '3 minutes');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_preparation
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000201' AND evenement = 'pre_alerte'),
  'minute 3 : pre-alerte posee');
SELECT pg_temp.vrai(pg_temp.notifie('a3000000-0000-0000-0000-000000000001', 'remplacement_avertissement', 'a3000000-0000-0000-0000-000000000201')
  AND (SELECT params->>'minutes' FROM public.notifications
        WHERE destinataire = 'a3000000-0000-0000-0000-000000000001' AND evenement = 'remplacement_avertissement') = '5',
  'minute 3 : le titulaire est averti (5 minutes pour entrer)');
SELECT pg_temp.vrai(pg_temp.notifie('a3000000-0000-0000-0000-000000000009', 'remplacement_pre_alerte', 'a3000000-0000-0000-0000-000000000201')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000008', 'remplacement_pre_alerte', 'a3000000-0000-0000-0000-000000000201')
  AND NOT pg_temp.notifie('a3000000-0000-0000-0000-000000000007', 'remplacement_pre_alerte', 'a3000000-0000-0000-0000-000000000201')
  AND NOT pg_temp.notifie('a3000000-0000-0000-0000-000000000001', 'remplacement_pre_alerte', 'a3000000-0000-0000-0000-000000000201'),
  'minute 3 : pre-alerte aux seuls candidats');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = 'a3000000-0000-0000-0000-000000000201'),
  'minute 3 : pas encore d''absence');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_preparation
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000204' AND evenement = 'pre_alerte')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000004', 'remplacement_avertissement', 'a3000000-0000-0000-0000-000000000204'),
  'seance deja ouverte (in_progress) : minute 3, avertissement et pre-alerte quand meme');

-- Le premier pret gagne.
SELECT pg_temp.en_tant_que('a3000000-0000-0000-0000-000000000009');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000201')->>'etat' = 'retenu', 'R1 pret : retenu');
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000201')->>'etat' = 'retenu', 'R1 pret, rejoue : retenu');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                             WHERE e->>'seance_id' = 'a3000000-0000-0000-0000-000000000201' AND e->>'etat' = 'pret_moi'),
  'R1 voit pret_moi');
RESET ROLE;
SELECT pg_temp.en_tant_que('a3000000-0000-0000-0000-000000000008');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000201')->>'etat' = 'dejaRetenu', 'R2 pret apres R1 : dejaRetenu');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                             WHERE e->>'seance_id' = 'a3000000-0000-0000-0000-000000000201' AND e->>'etat' = 'pret_collegue'),
  'R2 voit pret_collegue');
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000203')->>'etat' = 'retenu', 'R2 pret pour S3');
RESET ROLE;
SELECT pg_temp.en_tant_que('a3000000-0000-0000-0000-000000000007');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000201')->>'etat' IN ('fermee', 'dejaRetenu')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                   WHERE e->>'seance_id' = 'a3000000-0000-0000-0000-000000000201'),
  'F (autre genre) ne voit ni ne prend la pre-alerte');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true); SELECT set_config('request.jwt.claims','',true);
SELECT set_config('test.uid','',true); SELECT set_config('test.jwt','',true);

-- Retour du titulaire avant T+8 : T3 entre, la pre-alerte se clot, R2 est prevenu.
INSERT INTO public.session_events (session_id, profile_id, event_type, source)
VALUES ('a3000000-0000-0000-0000-000000000203','a3000000-0000-0000-0000-000000000003','joined','livekit_webhook');
SELECT private.remplacement_auto_passer(clock_timestamp());
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_preparation
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000203' AND evenement = 'remplacement_inutile')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000008', 'remplacement_inutile', 'a3000000-0000-0000-0000-000000000203'),
  'retour avant T+8 : remplacement inutile, le pret est prevenu');

-- Minute 8 de S1 : absence automatique, R1 (pret) devient remplacant.
SELECT private.remplacement_auto_passer(pg_temp.debut('a3000000-0000-0000-0000-000000000201') + interval '8 minutes');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_seance
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000201' AND evenement = 'absence_declaree'
                               AND origine = 'auto' AND acteur_id = 'a3000000-0000-0000-0000-000000000001'),
  'minute 8 : absence automatique, acteur = titulaire, origine auto');
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3000000-0000-0000-0000-000000000201') = 'a3000000-0000-0000-0000-000000000009',
  'minute 8 : le pret devient l''enseignant effectif');
-- A3-bis (20261105700000) : sans enseignant pret, rien n'est pose.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance
                                 WHERE session_id = 'a3000000-0000-0000-0000-000000000204')
  AND NOT private.remplacement_titulaire_ecarte('a3000000-0000-0000-0000-000000000204', 'a3000000-0000-0000-0000-000000000004'),
  'A3-bis, seance deja ouverte (in_progress) sans pret : minute 8, le titulaire n''est pas ecarte');
SELECT pg_temp.en_tant_que('a3000000-0000-0000-0000-000000000008');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                             WHERE e->>'seance_id' = 'a3000000-0000-0000-0000-000000000204' AND e->>'etat' = 'preparation'),
  'A3-bis, seance deja ouverte : elle reste ouverte au remplacement (preparation)');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true); SELECT set_config('request.jwt.claims','',true);
SELECT set_config('test.uid','',true); SELECT set_config('test.jwt','',true);
SELECT pg_temp.vrai(pg_temp.notifie('a3000000-0000-0000-0000-000000000012', 'titulaire_en_retard', 'a3000000-0000-0000-0000-000000000201')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000011', 'titulaire_en_retard', 'a3000000-0000-0000-0000-000000000201')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000013', 'titulaire_en_retard', 'a3000000-0000-0000-0000-000000000201'),
  'minute 8 : eleve, tuteur et direction prevenus du retard');
SELECT pg_temp.vrai(pg_temp.notifie('a3000000-0000-0000-0000-000000000012', 'remplacant_arrive', 'a3000000-0000-0000-0000-000000000201')
  AND pg_temp.notifie('a3000000-0000-0000-0000-000000000011', 'remplacant_arrive', 'a3000000-0000-0000-0000-000000000201'),
  'minute 8 : eleve et tuteur prevenus qu''un remplacant arrive');
-- A3-bis (decision du directeur du 03/11/2026) : c'est l'ENTREE qui ferme la
-- porte ; R1 (pris) entre le premier, le titulaire est ensuite refuse.
DO $jeton$
BEGIN
  IF public.autoriser_jeton_video('a3000000-0000-0000-0000-000000000201', 'a3000000-0000-0000-0000-000000000009', 'wss://a', 'wss://b')->>'role' <> 'teacher' THEN
    RAISE EXCEPTION 'ROUGE : R1 (pris) n''a pas son jeton enseignant';
  END IF;
  BEGIN
    PERFORM public.autoriser_jeton_video('a3000000-0000-0000-0000-000000000201', 'a3000000-0000-0000-0000-000000000001', 'wss://a', 'wss://b');
    RAISE EXCEPTION 'ROUGE : le titulaire ecarte a recu un jeton apres l''entree de R1';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK minute 8 : le titulaire ecarte (remplacant pret) n''a plus de jeton';
END;
$jeton$;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = 'a3000000-0000-0000-0000-000000000203')
  AND NOT private.remplacement_titulaire_ecarte('a3000000-0000-0000-0000-000000000203', 'a3000000-0000-0000-0000-000000000003'),
  'retour avant T+8 : ni absence ni perte d''acces pour T3');

-- Minute 11 de S2 (sans pret) : A3-bis, le titulaire n'est pas ecarte ; R2 se
-- declare pret, et le passage suivant le prend (absence et prise ensemble).
SELECT pg_temp.vrai(clock_timestamp() - pg_temp.debut('a3000000-0000-0000-0000-000000000202') >= interval '11 minutes',
  'S2 est bien a sa minute 11');
SELECT pg_temp.vrai(NOT private.remplacement_titulaire_ecarte('a3000000-0000-0000-0000-000000000202', 'a3000000-0000-0000-0000-000000000002'),
  'A3-bis, minute 11 de S2 sans pret : le titulaire n''est pas ecarte');
SELECT pg_temp.en_tant_que('a3000000-0000-0000-0000-000000000008');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                             WHERE e->>'seance_id' = 'a3000000-0000-0000-0000-000000000202' AND e->>'etat' = 'preparation'),
  'minute 11 : S2 reste ouverte au remplacement (preparation)');
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3000000-0000-0000-0000-000000000202')->>'etat' = 'retenu',
  'minute 11 : R2 se declare pret pour S2');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true); SELECT set_config('request.jwt.claims','',true);
SELECT set_config('test.uid','',true); SELECT set_config('test.jwt','',true);
SELECT private.remplacement_auto_passer(clock_timestamp());
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_seance
                             WHERE session_id = 'a3000000-0000-0000-0000-000000000202' AND evenement = 'absence_declaree' AND origine = 'auto')
  AND EXISTS (SELECT 1 FROM public.remplacements_seance
               WHERE session_id = 'a3000000-0000-0000-0000-000000000202' AND evenement = 'remplacement_pris'
                 AND enseignant_remplacant_id = 'a3000000-0000-0000-0000-000000000008'),
  'passage suivant : absence et prise par R2, ensemble');
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3000000-0000-0000-0000-000000000202') = 'a3000000-0000-0000-0000-000000000008',
  'minute 11 : R2 est l''enseignant effectif de S2');

-- Aucune annulation, meme apres la fin prevue.
SELECT private.remplacement_auto_passer(clock_timestamp() + interval '2 hours');
-- A3-bis : le jeton de R1 a ouvert S1 (in_progress) ; aucune n'est annulee.
-- SNT (03/11/2026, 20261106500000) : deux heures apres, S2, S3 et S4, ou aucun
-- enseignant n'est entre, sont des seances non tenues : teacher_absent et
-- reportees (decision du directeur du 03/11), jamais annulees.
SELECT pg_temp.vrai((SELECT bool_and(status NOT IN ('canceled', 'canceled_late')) FROM public.sessions
                      WHERE id::text LIKE 'a3000000-0000-0000-0000-00000000020%')
  AND (SELECT status FROM public.sessions WHERE id = 'a3000000-0000-0000-0000-000000000201') = 'in_progress'
  AND (SELECT bool_and(s.status = 'teacher_absent'
                       AND EXISTS (SELECT 1 FROM public.seances_reportees r WHERE r.session_id = s.id))
         FROM public.sessions s
        WHERE s.id IN ('a3000000-0000-0000-0000-000000000202','a3000000-0000-0000-0000-000000000203',
                       'a3000000-0000-0000-0000-000000000204')),
  'aucune seance annulee par le remplacement automatique ; sans enseignant entre, reportee (SNT)');

-- Droits.
SELECT pg_temp.vrai(
  NOT has_table_privilege('authenticated', 'public.remplacements_preparation', 'SELECT')
  AND NOT has_function_privilege('anon', 'public.se_declarer_pret_remplacement(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.remplacement_auto_passer(timestamptz)', 'EXECUTE'),
  'droits : preparation et passage prives');

ROLLBACK;
