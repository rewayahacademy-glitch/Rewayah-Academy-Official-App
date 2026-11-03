-- SNT (20261106500000, 20261106500001) : seance non tenue a T+30, report et
-- nouvelle date.
-- Prouve :
--   1. a T+29 rien ne bouge ; a T+30, personne entre : teacher_absent, une
--      seance reportee, la classe prevenue (famille et enseignant), un e-mail
--      a la direction ; deux passages de plus ne creent rien ;
--   2. le titulaire entre a T+29 garde sa seance ;
--   3. un remplacant pris mais pas entre : la seance est reportee, il est
--      prevenu, il ne peut plus entrer (motif seance_reportee), et une prise
--      de remplacement apres le report est refusee ;
--   4. une seance ouverte par un eleve (in_progress, aucun enseignant entre)
--      est reportee ;
--   5. personne n'entre plus apres le report (jeton refuse, motif dit) ;
--   6. aucune ecriture d'argent ; la cloture automatique ne retraite pas une
--      seance reportee ;
--   7. la direction fixe la nouvelle date (authenticated) : seance de la meme
--      classe avec le titulaire, la meme duree et les eleves ; chevauchement,
--      date passee, second geste et autre role refuses ; la classe est
--      prevenue ;
--   8. le reglage se regle dans l'ordre debut_remplacant < non_tenue.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
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
CREATE FUNCTION pg_temp.debut(p_seance text) RETURNS timestamptz
LANGUAGE sql AS $$ SELECT started_at FROM public.sessions WHERE id = p_seance::uuid $$;
CREATE FUNCTION pg_temp.statut(p_seance text) RETURNS text
LANGUAGE sql AS $$ SELECT status::text FROM public.sessions WHERE id = p_seance::uuid $$;
CREATE FUNCTION pg_temp.reports(p_seance text) RETURNS integer
LANGUAGE sql AS $$ SELECT count(*)::integer FROM public.seances_reportees WHERE session_id = p_seance::uuid $$;
CREATE FUNCTION pg_temp.avis(p_seance text, p_evenement text) RETURNS integer
LANGUAGE sql AS $$ SELECT count(*)::integer FROM public.notifications n
                    WHERE n.evenement = p_evenement AND n.params->>'session_id' = p_seance $$;
CREATE FUNCTION pg_temp.argent() RETURNS bigint
LANGUAGE sql AS $$ SELECT (SELECT count(*) FROM public.tresorerie_mouvements)
                        + (SELECT count(*) FROM public.wallet_entries)
                        + (SELECT count(*) FROM public.payouts) $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
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
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text)
  TO authenticated;

SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'remplacement.seance_non_tenue_minutes') = '30'::jsonb,
  'reglage SNT pose : seance non tenue 30');

-- T1 a T4 titulaires ; R3 remplacant pris (K3) ; R4 un autre enseignant ;
-- A la direction (adresse inventee) ; P1 tuteur, E1 eleve (foyer H1).
INSERT INTO auth.users (id, email) VALUES
 ('b5e00000-0000-0000-0000-000000000001','snt-t1@test.invalid'), ('b5e00000-0000-0000-0000-000000000002','snt-t2@test.invalid'),
 ('b5e00000-0000-0000-0000-000000000003','snt-t3@test.invalid'), ('b5e00000-0000-0000-0000-000000000004','snt-t4@test.invalid'),
 ('b5e00000-0000-0000-0000-000000000015','snt-r3@test.invalid'), ('b5e00000-0000-0000-0000-000000000016','snt-r4@test.invalid'),
 ('b5e00000-0000-0000-0000-000000000013','snt-a@test.invalid'),
 ('b5e00000-0000-0000-0000-000000000021','snt-p1@test.invalid'), ('b5e00000-0000-0000-0000-000000000022','snt-e1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('b5e00000-0000-0000-0000-000000000901', 'Europe/Paris');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('b5e00000-0000-0000-0000-000000000001','SNT-T1','teacher',NULL,'Titulaire','Un','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000002','SNT-T2','teacher',NULL,'Titulaire','Deux','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000003','SNT-T3','teacher',NULL,'Titulaire','Trois','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000004','SNT-T4','teacher',NULL,'Titulaire','Quatre','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000015','SNT-R3','teacher',NULL,'Remplacant','Trois','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000016','SNT-R4','teacher',NULL,'Remplacant','Quatre','provisional_active','male'),
 ('b5e00000-0000-0000-0000-000000000013','SNT-A','admin',NULL,'Direction','A','active','female'),
 ('b5e00000-0000-0000-0000-000000000021','SNT-P1','guardian','b5e00000-0000-0000-0000-000000000901','Tuteur','Un','active','male'),
 ('b5e00000-0000-0000-0000-000000000022','SNT-E1','student','b5e00000-0000-0000-0000-000000000901','Eleve','Un','active','male');
UPDATE public.households SET primary_guardian_id = 'b5e00000-0000-0000-0000-000000000021'
 WHERE id = 'b5e00000-0000-0000-0000-000000000901';
INSERT INTO public.teacher_profiles (profile_id, kyc_status)
SELECT id, 'approved' FROM public.profiles WHERE id::text LIKE 'b5e00000-%' AND role = 'teacher';
DO $fixture_contrats$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active'
                    AND id::text LIKE 'b5e00000-%' LOOP
  PERFORM pg_temp.en_tant_que(v_teacher.id::text, 'teacher');
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version) ON CONFLICT DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES (v_teacher.id,'teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
 END LOOP;
 PERFORM pg_temp.personne();
END
$fixture_contrats$;

-- Classes K1 a K4 (une par titulaire), et K5, une autre classe de T1.
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
SELECT ('b5e00000-0000-0000-0000-00000000010' || n)::uuid, ('b5e00000-0000-0000-0000-00000000000' || n)::uuid,
       'enfant', 5, 'SNT classe ' || n,
       extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int, 18, 'Europe/Paris', 'hommes',
       now() - interval '1 day'
  FROM generate_series(1, 4) n;
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
VALUES ('b5e00000-0000-0000-0000-000000000105', 'b5e00000-0000-0000-0000-000000000001', 'enfant', 5, 'SNT classe 5',
        extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '4 days')::int, 7, 'Europe/Paris', 'hommes',
        now() - interval '1 day');
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at)
VALUES ('b5e00000-0000-0000-0000-000000000101', 'b5e00000-0000-0000-0000-000000000022', now() - interval '1 day');

-- Seances commencees il y a 2 minutes, 60 minutes, creees la veille.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT ('b5e00000-0000-0000-0000-00000000020' || n)::uuid, ('b5e00000-0000-0000-0000-00000000000' || n)::uuid,
       now() - interval '2 minutes', now() + interval '58 minutes', 'planned', 'child',
       ('b5e00000-0000-0000-0000-00000000010' || n)::uuid
  FROM generate_series(1, 4) n;
UPDATE public.sessions SET created_at = now() - interval '1 day' WHERE id::text LIKE 'b5e00000-0000-0000-0000-00000000020%';
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('b5e00000-0000-0000-0000-000000000201', 'b5e00000-0000-0000-0000-000000000022', 'student');
-- K3 : une absence, puis R3 prend (et n'entre jamais).
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
VALUES ('b5e00000-0000-0000-0000-000000000203', 'absence_declaree', 'b5e00000-0000-0000-0000-000000000003', NULL,
        'b5e00000-0000-0000-0000-000000000003', gen_random_uuid(), 'auto', now() - interval '1 minute'),
       ('b5e00000-0000-0000-0000-000000000203', 'remplacement_pris', 'b5e00000-0000-0000-0000-000000000003',
        'b5e00000-0000-0000-0000-000000000015', 'b5e00000-0000-0000-0000-000000000015', gen_random_uuid(), 'auto', now());
-- K4 : ouverte par un eleve (in_progress), aucun enseignant entre ; une
-- absence declaree, offerte a la prise.
UPDATE public.sessions SET status = 'preflight' WHERE id = 'b5e00000-0000-0000-0000-000000000204';
UPDATE public.sessions SET status = 'in_progress' WHERE id = 'b5e00000-0000-0000-0000-000000000204';
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
VALUES ('b5e00000-0000-0000-0000-000000000204', 'absence_declaree', 'b5e00000-0000-0000-0000-000000000004', NULL,
        'b5e00000-0000-0000-0000-000000000004', gen_random_uuid(), 'auto', now() - interval '1 minute');
-- K5 : une seance a venir de T1, dans une autre classe (chevauchement).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('b5e00000-0000-0000-0000-000000000205', 'b5e00000-0000-0000-0000-000000000001',
        date_trunc('hour', now()) + interval '2 days', date_trunc('hour', now()) + interval '2 days 1 hour',
        'planned', 'child', 'b5e00000-0000-0000-0000-000000000105');

-- 1. T+29 : rien ne bouge.
SELECT private.remplacement_auto_passer(pg_temp.debut('b5e00000-0000-0000-0000-000000000201') + interval '29 minutes');
SELECT pg_temp.vrai((SELECT count(*) FROM public.seances_reportees r JOIN public.sessions s ON s.id = r.session_id
                      WHERE s.id::text LIKE 'b5e00000-%') = 0
  AND pg_temp.statut('b5e00000-0000-0000-0000-000000000201') = 'planned',
  '1. T+29 : aucune seance reportee, K1 toujours planned');

-- 2. Le titulaire de K2 entre a T+29.
SELECT pg_temp.vrai(public.autoriser_jeton_video('b5e00000-0000-0000-0000-000000000202', 'b5e00000-0000-0000-0000-000000000002',
                      'wss://snt.cloud.test', 'wss://snt.auto.test')->>'role' = 'teacher',
  '2. T+29 : le titulaire de K2 obtient son jeton');

CREATE TEMP TABLE argent_avant AS SELECT pg_temp.argent() AS n;

-- T+30, puis deux passages de plus.
SELECT pg_temp.vrai((private.remplacement_auto_passer(pg_temp.debut('b5e00000-0000-0000-0000-000000000201') + interval '30 minutes')
                     ->>'reportees')::integer = 3,
  '1. T+30 : trois seances reportees dans le passage (K1, K3, K4)');
SELECT private.remplacement_auto_passer(pg_temp.debut('b5e00000-0000-0000-0000-000000000201') + interval '31 minutes');
SELECT private.remplacement_auto_passer(pg_temp.debut('b5e00000-0000-0000-0000-000000000201') + interval '32 minutes');

SELECT pg_temp.vrai(pg_temp.statut('b5e00000-0000-0000-0000-000000000201') = 'teacher_absent'
  AND pg_temp.reports('b5e00000-0000-0000-0000-000000000201') = 1
  AND (SELECT enseignant_titulaire_id FROM public.seances_reportees
        WHERE session_id = 'b5e00000-0000-0000-0000-000000000201') = 'b5e00000-0000-0000-0000-000000000001',
  '1. K1 : teacher_absent, une seule seance reportee apres trois passages, titulaire T1');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'seance_reportee'
           AND n.destinataire = 'b5e00000-0000-0000-0000-000000000021'
           AND n.params->>'session_id' = 'b5e00000-0000-0000-0000-000000000201'
           AND n.destination = '/tuteur/classes/b5e00000-0000-0000-0000-000000000101/planning')
  AND EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'seance_reportee'
               AND n.destinataire = 'b5e00000-0000-0000-0000-000000000022'
               AND n.params->>'session_id' = 'b5e00000-0000-0000-0000-000000000201')
  AND EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'seance_reportee'
               AND n.destinataire = 'b5e00000-0000-0000-0000-000000000001'
               AND n.params->>'session_id' = 'b5e00000-0000-0000-0000-000000000201')
  AND pg_temp.avis('b5e00000-0000-0000-0000-000000000201', 'seance_reportee') = 3,
  '1. K1 : le tuteur, l''eleve et le titulaire prevenus une seule fois (seance_reportee)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants c
    WHERE c.modele = 'seance_reportee_direction'
      AND c.cle_idempotence = 'snt-report:b5e00000-0000-0000-0000-000000000201:b5e00000-0000-0000-0000-000000000013'
      AND c.destinataire_adresse = 'snt-a@test.invalid' AND c.categorie = 'classes'
      AND c.donnees->>'classe' = 'SNT classe 1' AND c.donnees->>'enseignant' = 'Titulaire Un'
      AND c.donnees->>'minutes' = '30') = 1
  AND EXISTS (SELECT 1 FROM public.courriels_sortants c
               WHERE c.modele = 'seance_reportee'
                 AND c.destinataire_profil = 'b5e00000-0000-0000-0000-000000000021'),
  '1. K1 : un e-mail a la direction (chemin A3-bis), un e-mail au tuteur');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'seance_reportee_auto'
                             AND a.payload->>'session_id' = 'b5e00000-0000-0000-0000-000000000201'),
  '1. K1 : le report est journalise (audit_logs)');

SELECT pg_temp.vrai(pg_temp.statut('b5e00000-0000-0000-0000-000000000202') <> 'teacher_absent'
  AND pg_temp.reports('b5e00000-0000-0000-0000-000000000202') = 0,
  '2. K2 : le titulaire entre a T+29 garde sa seance');

-- 3. Le remplacant pris (R3), pas entre.
SELECT pg_temp.vrai(pg_temp.statut('b5e00000-0000-0000-0000-000000000203') = 'teacher_absent'
  AND pg_temp.reports('b5e00000-0000-0000-0000-000000000203') = 1
  AND EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'seance_reportee'
               AND n.destinataire = 'b5e00000-0000-0000-0000-000000000015'
               AND n.params->>'session_id' = 'b5e00000-0000-0000-0000-000000000203'),
  '3. K3 : reportee, le remplacant pris est prevenu');
DO $k3$
BEGIN
  BEGIN
    PERFORM public.autoriser_jeton_video('b5e00000-0000-0000-0000-000000000203', 'b5e00000-0000-0000-0000-000000000015',
                                         'wss://snt.cloud.test', 'wss://snt.auto.test');
    RAISE EXCEPTION 'ROUGE : 3. le remplacant pris entre apres le report';
  EXCEPTION WHEN check_violation THEN
    IF SQLERRM <> 'seance reportee' THEN RAISE EXCEPTION 'ROUGE : 3. refus inattendu : %', SQLERRM; END IF;
  END;
  RAISE NOTICE 'OK 3. K3 : le remplacant pris ne peut plus entrer (seance reportee)';
END;
$k3$;
SELECT pg_temp.vrai(public.motif_refus_salle('b5e00000-0000-0000-0000-000000000203',
                      'b5e00000-0000-0000-0000-000000000015')->>'motif' = 'seance_reportee'
  AND public.motif_refus_salle('b5e00000-0000-0000-0000-000000000203',
                      'b5e00000-0000-0000-0000-000000000003')->>'motif' = 'seance_reportee',
  '3. K3 : le remplacant et le titulaire lisent le motif seance_reportee');

-- 4. K4, ouverte par un eleve.
SELECT pg_temp.vrai(pg_temp.statut('b5e00000-0000-0000-0000-000000000204') = 'teacher_absent'
  AND pg_temp.reports('b5e00000-0000-0000-0000-000000000204') = 1,
  '4. K4 (in_progress, aucun enseignant entre) : reportee');
SELECT pg_temp.en_tant_que('b5e00000-0000-0000-0000-000000000016', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prendre_remplacement('b5e00000-0000-0000-0000-000000000204', gen_random_uuid())->>'etat' = 'dejaPrise',
  '3. une prise de remplacement apres le report est refusee (authenticated)');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance
                                 WHERE session_id = 'b5e00000-0000-0000-0000-000000000204'
                                   AND evenement = 'remplacement_pris'),
  '3. K4 : aucune prise posee');

-- 5. Personne n'entre plus.
DO $k1$
BEGIN
  BEGIN
    PERFORM public.autoriser_jeton_video('b5e00000-0000-0000-0000-000000000201', 'b5e00000-0000-0000-0000-000000000001',
                                         'wss://snt.cloud.test', 'wss://snt.auto.test');
    RAISE EXCEPTION 'ROUGE : 5. le titulaire de K1 entre apres le report';
  EXCEPTION WHEN check_violation THEN
    IF SQLERRM <> 'seance reportee' THEN RAISE EXCEPTION 'ROUGE : 5. refus inattendu : %', SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.autoriser_jeton_video('b5e00000-0000-0000-0000-000000000201', 'b5e00000-0000-0000-0000-000000000022',
                                         'wss://snt.cloud.test', 'wss://snt.auto.test');
    RAISE EXCEPTION 'ROUGE : 5. l''eleve de K1 entre apres le report';
  EXCEPTION WHEN check_violation THEN
    IF SQLERRM <> 'seance reportee' THEN RAISE EXCEPTION 'ROUGE : 5. refus inattendu : %', SQLERRM; END IF;
  END;
  RAISE NOTICE 'OK 5. K1 : ni le titulaire ni l''eleve n''entrent (seance reportee)';
END;
$k1$;
SELECT pg_temp.vrai(public.motif_refus_salle('b5e00000-0000-0000-0000-000000000201',
                      'b5e00000-0000-0000-0000-000000000001')->>'motif' = 'seance_reportee'
  AND public.motif_refus_salle('b5e00000-0000-0000-0000-000000000201',
                      'b5e00000-0000-0000-0000-000000000022')->>'motif' = 'seance_reportee'
  AND public.motif_refus_salle('b5e00000-0000-0000-0000-000000000201',
                      'b5e00000-0000-0000-0000-000000000016') IS NULL,
  '5. K1 : titulaire et eleve lisent seance_reportee ; un autre enseignant n''apprend rien');

-- 6. Argent et cloture automatique.
SELECT pg_temp.vrai(pg_temp.argent() = (SELECT n FROM argent_avant),
  '6. aucune ecriture d''argent (tresorerie, portefeuilles, paiements) pour les seances reportees');
CREATE TEMP TABLE avis_k1 AS SELECT count(*) AS n FROM public.notifications WHERE params->>'session_id' = 'b5e00000-0000-0000-0000-000000000201';
SELECT private.ses_cloturer_seances_echues(pg_temp.debut('b5e00000-0000-0000-0000-000000000201') + interval '3 hours');
SELECT pg_temp.vrai(pg_temp.statut('b5e00000-0000-0000-0000-000000000201') = 'teacher_absent'
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'seance_cloturee_auto'
                   AND a.row_id = 'b5e00000-0000-0000-0000-000000000201')
  AND (SELECT count(*) FROM public.notifications WHERE params->>'session_id' = 'b5e00000-0000-0000-0000-000000000201')
      = (SELECT n FROM avis_k1),
  '6. la cloture automatique ne retraite pas une seance reportee (aucune seconde notification)');

-- 7. La direction fixe la nouvelle date.
SELECT pg_temp.en_tant_que('b5e00000-0000-0000-0000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
DO $autre_role$
BEGIN
  BEGIN
    PERFORM public.fixer_nouvelle_date_seance(
      (SELECT id FROM public.seances_reportees WHERE session_id = 'b5e00000-0000-0000-0000-000000000201'),
      now() + interval '4 days');
    RAISE EXCEPTION 'ROUGE : 7. un enseignant fixe la nouvelle date';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.lister_seances_reportees();
    RAISE EXCEPTION 'ROUGE : 7. un enseignant lit les seances reportees';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 7. un enseignant ne fixe ni ne lit (authenticated)';
END;
$autre_role$;
RESET ROLE;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.seances_reportees WHERE session_id = 'b5e00000-0000-0000-0000-000000000201'),
  '7. (la lecture directe passe par postgres, jamais par le client)');

SELECT pg_temp.en_tant_que('b5e00000-0000-0000-0000-000000000013', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM jsonb_array_elements(public.lister_seances_reportees()) e
    WHERE e->>'classe' LIKE 'SNT classe %') = 3,
  '7. la direction lit les trois seances reportees (authenticated)');
DO $refus$
DECLARE
  v_report uuid := (SELECT public.lister_seances_reportees() -> 0 ->> 'id')::uuid;
  v_detail text;
BEGIN
  SELECT (e->>'id')::uuid INTO v_report FROM jsonb_array_elements(public.lister_seances_reportees()) e
   WHERE e->>'session_id' = 'b5e00000-0000-0000-0000-000000000201';
  BEGIN
    PERFORM public.fixer_nouvelle_date_seance(v_report, date_trunc('hour', now()) + interval '2 days 15 minutes');
    RAISE EXCEPTION 'ROUGE : 7. chevauchement accepte';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_detail = PG_EXCEPTION_DETAIL;
    IF SQLERRM <> 'chevauchement avec une séance existante' OR v_detail NOT LIKE '%"classe" : "SNT classe 5"%' THEN
      RAISE EXCEPTION 'ROUGE : 7. refus de chevauchement inattendu : % / %', SQLERRM, v_detail;
    END IF;
  END;
  BEGIN
    PERFORM public.fixer_nouvelle_date_seance(v_report, now() - interval '1 hour');
    RAISE EXCEPTION 'ROUGE : 7. date passee acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  RAISE NOTICE 'OK 7. chevauchement (refus nomme de C1, classe SNT classe 5) et date passee refuses';
END;
$refus$;
SELECT set_config('snt.k1', (SELECT e->>'id' FROM jsonb_array_elements(public.lister_seances_reportees()) e
                              WHERE e->>'session_id' = 'b5e00000-0000-0000-0000-000000000201'), true);
CREATE TEMP TABLE nouvelle AS
SELECT public.fixer_nouvelle_date_seance(current_setting('snt.k1')::uuid,
  date_trunc('hour', now()) + interval '4 days') AS id;
DO $second$
BEGIN
  BEGIN
    PERFORM public.fixer_nouvelle_date_seance(current_setting('snt.k1')::uuid,
      date_trunc('hour', now()) + interval '5 days');
    RAISE EXCEPTION 'ROUGE : 7. second geste accepte';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 7. la nouvelle date ne se fixe qu''une fois';
END;
$second$;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM jsonb_array_elements(public.lister_seances_reportees()) e
    WHERE e->>'classe' LIKE 'SNT classe %') = 2,
  '7. K1 sort de la liste une fois sa nouvelle date fixee');
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai(
  (SELECT s.teacher_id = 'b5e00000-0000-0000-0000-000000000001'
          AND s.groupe_id = 'b5e00000-0000-0000-0000-000000000101'
          AND s.status = 'planned'
          AND s.started_at = date_trunc('hour', now()) + interval '4 days'
          AND s.ended_at - s.started_at = interval '60 minutes'
     FROM public.sessions s WHERE s.id = (SELECT id FROM nouvelle))
  AND EXISTS (SELECT 1 FROM public.session_participants p
               WHERE p.session_id = (SELECT id FROM nouvelle)
                 AND p.profile_id = 'b5e00000-0000-0000-0000-000000000022' AND p.role = 'student')
  AND (SELECT seance_nouvelle_id = (SELECT id FROM nouvelle) AND fixee_par = 'b5e00000-0000-0000-0000-000000000013'
         FROM public.seances_reportees WHERE session_id = 'b5e00000-0000-0000-0000-000000000201'),
  '7. nouvelle seance : meme classe, titulaire T1, 60 minutes, l''eleve inscrit ; seance reportee close');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement = 'seance_deplacee'
           AND n.destinataire = 'b5e00000-0000-0000-0000-000000000021'
           AND n.params->>'session_id' = (SELECT id FROM nouvelle)::text
           AND n.params ? 'debut_local'),
  '7. le tuteur est prevenu de la nouvelle date (seance_deplacee)');
SELECT pg_temp.vrai(pg_temp.argent() = (SELECT n FROM argent_avant),
  '7. fixer la nouvelle date n''ecrit aucun argent');
DO $garde$
BEGIN
  BEGIN
    UPDATE public.seances_reportees SET seance_nouvelle_id = NULL, fixee_le = NULL, fixee_par = NULL
     WHERE session_id = 'b5e00000-0000-0000-0000-000000000201';
    RAISE EXCEPTION 'ROUGE : 7. la nouvelle date est retiree';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 7. une seance reportee close ne se rouvre pas';
END;
$garde$;

-- 8. Le reglage, par la direction, en authenticated.
SELECT pg_temp.en_tant_que('b5e00000-0000-0000-0000-000000000013', 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '25'::jsonb WHERE key = 'remplacement.seance_non_tenue_minutes';
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'remplacement.seance_non_tenue_minutes') = '25'::jsonb,
  '8. la direction regle la seance non tenue a 25');
DO $ordre$
BEGIN
  BEGIN
    UPDATE public.app_config SET value = '11'::jsonb WHERE key = 'remplacement.seance_non_tenue_minutes';
    RAISE EXCEPTION 'ROUGE : 8. seance non tenue egale au remplacant dans la salle';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    UPDATE public.app_config SET value = '25'::jsonb WHERE key = 'remplacement.debut_remplacant_minutes';
    RAISE EXCEPTION 'ROUGE : 8. remplacant dans la salle apres la seance non tenue';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    UPDATE public.app_config SET value = '1000'::jsonb WHERE key = 'remplacement.seance_non_tenue_minutes';
    RAISE EXCEPTION 'ROUGE : 8. 1000 minutes accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  RAISE NOTICE 'OK 8. ordre debut_remplacant < non_tenue impose, bornes gardees';
END;
$ordre$;
RESET ROLE;
SELECT pg_temp.personne();

-- Droits.
SELECT pg_temp.vrai(
  NOT has_table_privilege('authenticated', 'public.seances_reportees', 'SELECT')
  AND NOT has_table_privilege('anon', 'public.seances_reportees', 'SELECT')
  AND NOT has_function_privilege('anon', 'public.fixer_nouvelle_date_seance(uuid,timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lister_seances_reportees()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.snt_enseignant_entre(uuid)', 'EXECUTE'),
  'droits : table fermee au client, RPC fermees a anon, predicat prive');

ROLLBACK;
