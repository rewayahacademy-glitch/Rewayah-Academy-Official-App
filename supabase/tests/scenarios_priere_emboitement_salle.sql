-- PRIERE-1 x PAUSE-SERVEUR : l'emboitement des deux lots.
-- Le lot de la salle (migration 20261124100000_pause_proposee.sql, branche
-- claude/zealous-tesla-ewstzw) lit `public.seance_pause_prevue` quand une
-- seance passe a `in_progress` et copie l'heure, la duree et le motif dans
-- `public.pause_seances`. Ce scenario le prouve APRES les deux migrations.
-- Tant que la migration de la salle n'est pas dans le depot, le scenario se
-- declare « saute » (colonne pause_seances.motif absente) et ne prouve rien.
-- Rejeu : stub_auth.sql, toutes les migrations (la priere ET celle de la salle),
-- puis ce fichier. Se termine par ROLLBACK.
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'pause_seances' AND column_name = 'motif') THEN
    RAISE NOTICE 'SAUTE : la migration de la salle (pause_proposee) n''est pas installee, aucun emboitement a prouver';
    PERFORM set_config('test.saute', 'oui', true);
  END IF;
END $$;

INSERT INTO auth.users (id, email)
SELECT ('9e100000-0000-4000-8000-0000000000' || n)::uuid, 'emboite-' || n || '@test.invalid'
  FROM unnest(ARRAY['01','10']) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('9e100000-0000-4000-8000-000000000001','EMB-T1','teacher',NULL,'Conakry','Un','provisional_active','male'),
 ('9e100000-0000-4000-8000-000000000010','EMB-A','admin',NULL,'Direction','Emboite','active','female');
INSERT INTO public.teacher_profiles (profile_id, country, timezone_iana, kyc_status)
VALUES ('9e100000-0000-4000-8000-000000000001','GN','Africa/Conakry','approved');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('9e1000c0-0000-4000-8000-000000000001', '9e100000-0000-4000-8000-000000000001', 'enfant', 5,
        'EMB classe', 4, 19, 'Asia/Riyadh', 'indetermine');

SELECT set_config('request.jwt.claim.sub', '9e100000-0000-4000-8000-000000000010', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT public.priere_lieu_definir('9e100000-0000-4000-8000-000000000001', 'Conakry', 9.6412, -13.5784, 'Africa/Conakry');
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '', true);

CREATE TEMP TABLE h AS
  SELECT priere, instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-15',
                                  'muslim_world_league', 'shafi', '{}');

-- Seance de 60 minutes, le Maghrib entre a 25 minutes : ligne du contrat, 10 minutes.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e1000e0-0000-4000-8000-000000000001', '9e100000-0000-4000-8000-000000000001',
       instant_utc - interval '25 minutes', instant_utc + interval '35 minutes', 'planned', 'standard',
       '9e1000c0-0000-4000-8000-000000000001'
  FROM h WHERE priere = 'maghrib';
SELECT pg_temp.vrai((SELECT duree_minutes = 10 AND motif = 'priere'
                       FROM public.seance_pause_prevue WHERE session_id = '9e1000e0-0000-4000-8000-000000000001'),
  'avant le demarrage : le contrat porte la pause de priere (10 minutes)');

DO $$
BEGIN
  IF current_setting('test.saute', true) = 'oui' THEN RETURN; END IF;
  UPDATE public.sessions SET status = 'preflight' WHERE id = '9e1000e0-0000-4000-8000-000000000001';
  UPDATE public.sessions SET status = 'in_progress' WHERE id = '9e1000e0-0000-4000-8000-000000000001';
  PERFORM pg_temp.vrai((SELECT ps.statut = 'programmee'
                               AND ps.duree_prevue_minutes = p.duree_minutes
                               AND ps.debut_prevu_utc = p.debut_prevu_utc
                               AND ps.motif = p.motif
                          FROM public.pause_seances ps, public.seance_pause_prevue p
                         WHERE ps.seance_id = '9e1000e0-0000-4000-8000-000000000001'
                           AND p.session_id = ps.seance_id),
    'emboitement : a in_progress, pause_seances porte l''heure, la duree et le motif de la priere');
  PERFORM pg_temp.vrai((SELECT ps.motif = 'priere' AND ps.duree_prevue_minutes = 10
                          FROM public.pause_seances ps WHERE ps.seance_id = '9e1000e0-0000-4000-8000-000000000001'),
    'emboitement : motif priere, 10 minutes');
END $$;

-- Ramadan : 20 minutes, le contrat de la salle accepte (5 a 30 par pas de 5, pause entiere dans la seance).
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'priere.ramadan_en_cours';
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT '9e1000e0-0000-4000-8000-000000000002', '9e100000-0000-4000-8000-000000000001',
       instant_utc - interval '25 minutes' + interval '7 days', instant_utc + interval '35 minutes' + interval '7 days',
       'planned', 'standard', '9e1000c0-0000-4000-8000-000000000001'
  FROM h WHERE priere = 'maghrib';
UPDATE public.sessions s SET started_at = x.instant_utc - interval '25 minutes', ended_at = x.instant_utc + interval '35 minutes'
  FROM (SELECT instant_utc FROM private.priere_calculer(9.6412, -13.5784, DATE '2027-01-22',
                  'muslim_world_league', 'shafi', '{}') WHERE priere = 'maghrib') x
 WHERE s.id = '9e1000e0-0000-4000-8000-000000000002';
SELECT pg_temp.vrai((SELECT duree_minutes = 20 FROM public.seance_pause_prevue
                      WHERE session_id = '9e1000e0-0000-4000-8000-000000000002'),
  'Ramadan : la ligne du contrat dure 20 minutes');
DO $$
BEGIN
  IF current_setting('test.saute', true) = 'oui' THEN RETURN; END IF;
  UPDATE public.sessions SET status = 'preflight' WHERE id = '9e1000e0-0000-4000-8000-000000000002';
  UPDATE public.sessions SET status = 'in_progress' WHERE id = '9e1000e0-0000-4000-8000-000000000002';
  PERFORM pg_temp.vrai((SELECT ps.duree_prevue_minutes = 20 AND ps.motif = 'priere' AND ps.statut = 'programmee'
                          FROM public.pause_seances ps WHERE ps.seance_id = '9e1000e0-0000-4000-8000-000000000002'),
    'emboitement Ramadan : la salle accepte et garde les 20 minutes avec le motif priere');
END $$;
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'priere.ramadan_en_cours';

ROLLBACK;
