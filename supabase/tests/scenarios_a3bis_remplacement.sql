-- A3-bis (20261105700000) : le remplacement sans perte de seance.
-- Prouve :
--   1. un titulaire absent sans remplacant pret n'est jamais ecarte et garde
--      son jeton ; la seance reste ouverte au remplacement ;
--   2. un titulaire absent avec un remplacant pret est ecarte, le remplacant
--      est pris dans le meme passage et recoit son jeton ;
--   3. un seul e-mail a chaque compte de la direction au delai d'alerte, meme
--      apres plusieurs passages ; aucun e-mail quand le titulaire est entre ;
--   4. une seance creee tard ne declenche aucun automatisme, mais l'e-mail part ;
--   5. la direction regle les deux delais en authenticated (RLS de app_config,
--      validation du declencheur) ; un autre role ne le peut pas.
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
CREATE FUNCTION pg_temp.alertes(p_seance text) RETURNS integer
LANGUAGE sql AS $$ SELECT count(*)::integer FROM public.courriels_sortants c
                    WHERE c.modele = 'remplacement_personne_en_salle'
                      AND c.cle_idempotence = 'a3bis-alerte:' || p_seance
                                              || ':a3b00000-0000-0000-0000-000000000013' $$;
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
  (SELECT value FROM public.app_config WHERE key = 'remplacement.alerte_direction_minutes') = '3'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'remplacement.seance_tardive_minutes') = '15'::jsonb,
  'reglages A3-bis poses : alerte 3, seance tardive 15');

-- T1 a T4 titulaires (hommes) ; R1, R2 candidats ; A la direction (adresse
-- inventee) ; C un comptable (ne regle rien).
INSERT INTO auth.users (id, email) VALUES
 ('a3b00000-0000-0000-0000-000000000001','a3b-t1@test.invalid'), ('a3b00000-0000-0000-0000-000000000002','a3b-t2@test.invalid'),
 ('a3b00000-0000-0000-0000-000000000003','a3b-t3@test.invalid'), ('a3b00000-0000-0000-0000-000000000004','a3b-t4@test.invalid'),
 ('a3b00000-0000-0000-0000-000000000009','a3b-r1@test.invalid'), ('a3b00000-0000-0000-0000-000000000008','a3b-r2@test.invalid'),
 ('a3b00000-0000-0000-0000-000000000013','a3b-a@test.invalid'), ('a3b00000-0000-0000-0000-000000000014','a3b-c@test.invalid'),
 ('a3b00000-0000-0000-0000-000000000005','a3b-t5@test.invalid'), ('a3b00000-0000-0000-0000-000000000006','a3b-t6@test.invalid'),
 ('a3b00000-0000-0000-0000-000000000015','a3b-r3@test.invalid'), ('a3b00000-0000-0000-0000-000000000016','a3b-r4@test.invalid');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('a3b00000-0000-0000-0000-000000000001','A3B-T1','teacher',NULL,'Titulaire','Un','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000002','A3B-T2','teacher',NULL,'Titulaire','Deux','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000003','A3B-T3','teacher',NULL,'Titulaire','Trois','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000004','A3B-T4','teacher',NULL,'Titulaire','Quatre','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000005','A3B-T5','teacher',NULL,'Titulaire','Cinq','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000006','A3B-T6','teacher',NULL,'Titulaire','Six','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000015','A3B-R3','teacher',NULL,'Remplacant','Trois','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000016','A3B-R4','teacher',NULL,'Remplacant','Quatre','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000009','A3B-R1','teacher',NULL,'Pret','Un','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000008','A3B-R2','teacher',NULL,'Pret','Deux','provisional_active','male'),
 ('a3b00000-0000-0000-0000-000000000013','A3B-A','admin',NULL,'Direction','A','active','female'),
 ('a3b00000-0000-0000-0000-000000000014','A3B-C','accountant',NULL,'Comptable','C','active','female');
INSERT INTO public.teacher_profiles (profile_id, kyc_status)
SELECT id, 'approved' FROM public.profiles WHERE id::text LIKE 'a3b00000-%' AND role = 'teacher';
DO $fixture_contrats$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active'
                    AND id::text LIKE 'a3b00000-%' LOOP
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

INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
SELECT ('a3b00000-0000-0000-0000-00000000010' || n)::uuid, ('a3b00000-0000-0000-0000-00000000000' || n)::uuid,
       'enfant', 5, 'A3B classe ' || n,
       extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + interval '3 days')::int, 18, 'Europe/Paris', 'hommes',
       now() - interval '1 day'
  FROM generate_series(1, 6) n;
-- S1 : sans pret. S2 : R1 pret. S3 : titulaire entre. S4 : creee tard, R2 pret.
-- Toutes commencent il y a 2 minutes ; S1 a S3 ont ete creees la veille.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT ('a3b00000-0000-0000-0000-00000000020' || n)::uuid, ('a3b00000-0000-0000-0000-00000000000' || n)::uuid,
       now() - interval '2 minutes', now() + interval '43 minutes', 'planned', 'standard',
       ('a3b00000-0000-0000-0000-00000000010' || n)::uuid
  FROM generate_series(1, 6) n;
UPDATE public.sessions SET created_at = now() - interval '1 day'
 WHERE id IN ('a3b00000-0000-0000-0000-000000000201', 'a3b00000-0000-0000-0000-000000000202',
              'a3b00000-0000-0000-0000-000000000203', 'a3b00000-0000-0000-0000-000000000205',
              'a3b00000-0000-0000-0000-000000000206');
UPDATE public.sessions SET created_at = started_at - interval '5 minutes'
 WHERE id = 'a3b00000-0000-0000-0000-000000000204';
INSERT INTO public.session_events (session_id, profile_id, event_type, source)
VALUES ('a3b00000-0000-0000-0000-000000000203','a3b00000-0000-0000-0000-000000000003','joined','livekit_webhook');

-- Minute 3 : pre-alerte et alerte a la direction.
SELECT private.remplacement_auto_passer(pg_temp.debut('a3b00000-0000-0000-0000-000000000201') + interval '3 minutes');
SELECT pg_temp.vrai(pg_temp.alertes('a3b00000-0000-0000-0000-000000000201') = 1
  AND EXISTS (SELECT 1 FROM public.courriels_sortants c
               WHERE c.cle_idempotence = 'a3bis-alerte:a3b00000-0000-0000-0000-000000000201:a3b00000-0000-0000-0000-000000000013'
                 AND c.destinataire_adresse = 'a3b-a@test.invalid' AND c.categorie = 'classes'
                 AND c.donnees->>'classe' = 'A3B classe 1' AND c.donnees->>'enseignant' = 'Titulaire Un'
                 AND c.donnees->>'debut_local' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'),
  'minute 3 : un e-mail a la direction pour S1, avec classe, enseignant et heure');
SELECT pg_temp.vrai(pg_temp.alertes('a3b00000-0000-0000-0000-000000000203') = 0,
  'minute 3 : aucun e-mail quand le titulaire est entre (S3)');
SELECT pg_temp.vrai(pg_temp.alertes('a3b00000-0000-0000-0000-000000000204') = 1,
  'minute 3 : la seance creee tard (S4) donne quand meme l''e-mail');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.courriels_sortants c
                                 WHERE c.modele = 'remplacement_personne_en_salle'
                                   AND c.destinataire_profil = 'a3b00000-0000-0000-0000-000000000014'),
  'minute 3 : le comptable ne recoit pas l''alerte');

-- R1 se declare pret pour S2, R2 pour S4, en authenticated.
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000009', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3b00000-0000-0000-0000-000000000202')->>'etat' = 'retenu',
  'R1 pret pour S2 (authenticated)');
RESET ROLE;
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000008', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3b00000-0000-0000-0000-000000000204')->>'etat' = 'retenu',
  'R2 pret pour S4 (authenticated)');
RESET ROLE;
SELECT pg_temp.personne();

-- Minute 8, puis deux passages de plus.
SELECT private.remplacement_auto_passer(pg_temp.debut('a3b00000-0000-0000-0000-000000000201') + interval '8 minutes');
SELECT private.remplacement_auto_passer(pg_temp.debut('a3b00000-0000-0000-0000-000000000201') + interval '9 minutes');
SELECT private.remplacement_auto_passer(pg_temp.debut('a3b00000-0000-0000-0000-000000000201') + interval '10 minutes');

-- 1. Sans pret : rien n'est pose, le titulaire garde son jeton.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = 'a3b00000-0000-0000-0000-000000000201')
  AND NOT private.remplacement_titulaire_ecarte('a3b00000-0000-0000-0000-000000000201', 'a3b00000-0000-0000-0000-000000000001'),
  '1. S1 sans pret : aucune absence, le titulaire n''est pas ecarte');
SELECT pg_temp.vrai(public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000201', 'a3b00000-0000-0000-0000-000000000001',
                      'wss://a3b.cloud.test', 'wss://a3b.auto.test')->>'role' = 'teacher',
  '1. S1 sans pret : le titulaire en retard obtient son jeton et entre');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_preparation
                             WHERE session_id = 'a3b00000-0000-0000-0000-000000000201' AND evenement = 'pre_alerte'),
  '1. S1 reste ouverte au remplacement (pre-alerte)');

-- 2. Avec pret : absence et prise ensemble, le titulaire est ecarte.
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remplacements_seance
                             WHERE session_id = 'a3b00000-0000-0000-0000-000000000202' AND evenement = 'absence_declaree' AND origine = 'auto')
  AND EXISTS (SELECT 1 FROM public.remplacements_seance
               WHERE session_id = 'a3b00000-0000-0000-0000-000000000202' AND evenement = 'remplacement_pris'
                 AND enseignant_remplacant_id = 'a3b00000-0000-0000-0000-000000000009' AND origine = 'auto')
  AND private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000202') = 'a3b00000-0000-0000-0000-000000000009',
  '2. S2 avec R1 pret : absence et prise ensemble, R1 enseignant effectif');
-- Decision du 03/11 : c'est l'ENTREE qui ferme la porte. R1 (pris) entre le
-- premier ; le titulaire est ensuite refuse.
DO $jeton$
BEGIN
  IF public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000202', 'a3b00000-0000-0000-0000-000000000009',
                                  'wss://a3b.cloud.test', 'wss://a3b.auto.test')->>'role' <> 'teacher' THEN
    RAISE EXCEPTION 'ROUGE : 2. le remplacant de S2 n''a pas de jeton enseignant';
  END IF;
  BEGIN
    PERFORM public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000202', 'a3b00000-0000-0000-0000-000000000002',
                                         'wss://a3b.cloud.test', 'wss://a3b.auto.test');
    RAISE EXCEPTION 'ROUGE : 2. le titulaire de S2 est entre apres le remplacant';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 2. S2 : le remplacant entre le premier, le titulaire est ensuite refuse';
END;
$jeton$;

-- 3. Un seul e-mail par seance et par personne, apres quatre passages.
SELECT pg_temp.vrai(pg_temp.alertes('a3b00000-0000-0000-0000-000000000201') = 1
  AND pg_temp.alertes('a3b00000-0000-0000-0000-000000000202') = 1
  AND pg_temp.alertes('a3b00000-0000-0000-0000-000000000204') = 1,
  '3. un seul e-mail par seance a la direction apres quatre passages');

-- 4. Seance creee tard : ni absence ni prise, malgre R2 pret.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = 'a3b00000-0000-0000-0000-000000000204')
  AND NOT private.remplacement_titulaire_ecarte('a3b00000-0000-0000-0000-000000000204', 'a3b00000-0000-0000-0000-000000000004'),
  '4. S4 creee tard : aucun automatisme, le titulaire n''est pas ecarte');

-- 6. Decision du directeur du 03/11 : le premier qui entre ferme la porte a
--    l'autre, qui voit un message clair.
-- 6a. Le remplacant a pris S2 : le titulaire refuse lit « acces_perdu », le
--     motif que /salle traduit par « Un remplacant a pris la classe ».
SELECT pg_temp.vrai(public.motif_refus_salle('a3b00000-0000-0000-0000-000000000202',
                      'a3b00000-0000-0000-0000-000000000002')->>'motif' = 'remplacant_entre',
  '6a. S2 : le titulaire refuse lit remplacant_entre (un remplacant a pris la classe), jamais le refus generique');
SELECT pg_temp.vrai(public.motif_refus_salle('a3b00000-0000-0000-0000-000000000201',
                      'a3b00000-0000-0000-0000-000000000001') IS NULL,
  '6a. S1 : le titulaire non remplace n''a aucun motif de refus (il entre)');
-- 6b. R2 se declare pret pour S1, puis le titulaire entre le premier : le
--     remplacement n'est plus necessaire, R2 est prevenu et ne peut plus entrer.
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000008', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3b00000-0000-0000-0000-000000000201')->>'etat' = 'retenu',
  '6b. R2 pret pour S1 (authenticated)');
RESET ROLE;
SELECT pg_temp.personne();
INSERT INTO public.session_events (session_id, profile_id, event_type, source)
VALUES ('a3b00000-0000-0000-0000-000000000201','a3b00000-0000-0000-0000-000000000001','joined','livekit_webhook');
SELECT private.remplacement_auto_passer(pg_temp.debut('a3b00000-0000-0000-0000-000000000201') + interval '11 minutes');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = 'a3b00000-0000-0000-0000-000000000201')
  AND EXISTS (SELECT 1 FROM public.notifications n
               WHERE n.destinataire = 'a3b00000-0000-0000-0000-000000000008' AND n.evenement = 'remplacement_inutile'
                 AND n.params->>'session_id' = 'a3b00000-0000-0000-0000-000000000201'),
  '6b. le titulaire entre le premier : aucune prise, R2 recoit « remplacement inutile »');
DO $porte$
BEGIN
  BEGIN
    PERFORM public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000201', 'a3b00000-0000-0000-0000-000000000008',
                                         'wss://a3b.cloud.test', 'wss://a3b.auto.test');
    RAISE EXCEPTION 'ROUGE : 6b. R2 a recu un jeton alors que le titulaire est entre';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 6b. R2 ne peut plus entrer dans S1';
END;
$porte$;
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000008', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.se_declarer_pret_remplacement('a3b00000-0000-0000-0000-000000000201')->>'etat' IN ('fermee', 'retenu')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.offres_remplacement()) e
                   WHERE e->>'seance_id' = 'a3b00000-0000-0000-0000-000000000201'),
  '6b. S1 sort du tableau des remplacements de R2');
RESET ROLE;
SELECT pg_temp.personne();

-- 7. Decision du 03/11 : la prise ne ferme pas la porte, l'ENTREE la ferme.
--    S5 (T5, pris par R3) et S6 (T6, pris par R4) : prises posees sans entree.
-- Les prises datent d'une minute : le jeton du titulaire, demande dans cette
-- meme transaction (emis_le = now()), vient apres elles.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
VALUES
  ('a3b00000-0000-0000-0000-000000000205','absence_declaree','a3b00000-0000-0000-0000-000000000005',NULL,
   'a3b00000-0000-0000-0000-000000000005','a3b00000-0000-0000-0000-00000000a051','auto', now() - interval '2 minutes'),
  ('a3b00000-0000-0000-0000-000000000206','absence_declaree','a3b00000-0000-0000-0000-000000000006',NULL,
   'a3b00000-0000-0000-0000-000000000006','a3b00000-0000-0000-0000-00000000a061','auto', now() - interval '2 minutes');
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
VALUES
  ('a3b00000-0000-0000-0000-000000000205','remplacement_pris','a3b00000-0000-0000-0000-000000000005',
   'a3b00000-0000-0000-0000-000000000015','a3b00000-0000-0000-0000-000000000015','a3b00000-0000-0000-0000-00000000a052','auto', now() - interval '1 minute'),
  ('a3b00000-0000-0000-0000-000000000206','remplacement_pris','a3b00000-0000-0000-0000-000000000006',
   'a3b00000-0000-0000-0000-000000000016','a3b00000-0000-0000-0000-000000000016','a3b00000-0000-0000-0000-00000000a062','auto', now() - interval '1 minute');

-- 7c. Prise sans aucune entree : comportement d'avant, l'enseignant effectif
--     est le remplacant pris.
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000015'
  AND private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000206') = 'a3b00000-0000-0000-0000-000000000016',
  '7c. prise sans entree : l''enseignant effectif reste le remplacant pris');

-- 7a. Prise, puis entree du titulaire T5 : il entre, R3 est refuse, et la
--     paie et le cahier sont au nom du titulaire.
DO $entree_titulaire$
BEGIN
  IF public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000205', 'a3b00000-0000-0000-0000-000000000005',
                                  'wss://a3b.cloud.test', 'wss://a3b.auto.test')->>'role' <> 'teacher' THEN
    RAISE EXCEPTION 'ROUGE : 7a. le titulaire de S5 (seance prise, personne entre) n''a pas son jeton';
  END IF;
  BEGIN
    PERFORM public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000205', 'a3b00000-0000-0000-0000-000000000015',
                                         'wss://a3b.cloud.test', 'wss://a3b.auto.test');
    RAISE EXCEPTION 'ROUGE : 7a. R3 est entre apres le titulaire';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 7a. S5 : le titulaire entre malgre la prise, R3 est ensuite refuse';
END;
$entree_titulaire$;
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000005'
  AND private.salle_enseignant_effectif('a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000005',
  '7a. S5 : l''enseignant effectif (salle, paie, cahier) est le titulaire');
SELECT pg_temp.vrai(public.motif_refus_salle('a3b00000-0000-0000-0000-000000000205',
                      'a3b00000-0000-0000-0000-000000000015')->>'motif' = 'titulaire_entre',
  '7a. S5 : R3 refuse lit titulaire_entre (l''enseignant de la classe est arrive)');

-- 7b. Prise, puis entree du remplacant R4 : il entre, le titulaire T6 est
--     refuse avec le bon motif, et tout est au nom du remplacant.
DO $entree_remplacant$
BEGIN
  IF public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000206', 'a3b00000-0000-0000-0000-000000000016',
                                  'wss://a3b.cloud.test', 'wss://a3b.auto.test')->>'role' <> 'teacher' THEN
    RAISE EXCEPTION 'ROUGE : 7b. R4 n''a pas son jeton';
  END IF;
  BEGIN
    PERFORM public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000206', 'a3b00000-0000-0000-0000-000000000006',
                                         'wss://a3b.cloud.test', 'wss://a3b.auto.test');
    RAISE EXCEPTION 'ROUGE : 7b. le titulaire T6 est entre apres R4';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 7b. S6 : R4 entre, le titulaire est ensuite refuse';
END;
$entree_remplacant$;
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000206') = 'a3b00000-0000-0000-0000-000000000016'
  AND public.motif_refus_salle('a3b00000-0000-0000-0000-000000000206',
        'a3b00000-0000-0000-0000-000000000006')->>'motif' = 'remplacant_entre',
  '7b. S6 : tout au nom de R4 ; le titulaire lit remplacant_entre');

-- 7d. Une fois fixe, l'enseignant effectif ne bouge plus : c29 rappele, un
--     second jeton du gagnant, une arrivee (webhook) tardive du perdant n'y
--     changent rien.
SELECT public.autoriser_jeton_video('a3b00000-0000-0000-0000-000000000205', 'a3b00000-0000-0000-0000-000000000005',
                                    'wss://a3b.cloud.test', 'wss://a3b.auto.test');
INSERT INTO public.session_events (session_id, profile_id, event_type, source)
VALUES ('a3b00000-0000-0000-0000-000000000205','a3b00000-0000-0000-0000-000000000015','joined','livekit_webhook');
SELECT pg_temp.vrai(private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000005'
  AND private.c29_enseignant_effectif_session('a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000005',
  '7d. c29 appele deux fois apres l''entree, apres un second jeton et un webhook tardif : meme resultat');

-- 7e. La paie : seances closes, relevee au nom de celui qui est entre.
UPDATE public.sessions SET status = 'ended'
 WHERE id IN ('a3b00000-0000-0000-0000-000000000205', 'a3b00000-0000-0000-0000-000000000206');
SELECT pg_temp.vrai(
  (SELECT r.enseignant FROM private.pai_releve_seances(now() - interval '1 day', now() + interval '1 day') r
    WHERE r.seance = 'a3b00000-0000-0000-0000-000000000205') = 'a3b00000-0000-0000-0000-000000000005'
  AND (SELECT r.enseignant FROM private.pai_releve_seances(now() - interval '1 day', now() + interval '1 day') r
        WHERE r.seance = 'a3b00000-0000-0000-0000-000000000206') = 'a3b00000-0000-0000-0000-000000000016',
  '7e. paie : S5 au titulaire entre, S6 au remplacant entre');

-- 5. Les deux delais se reglent par la direction, en authenticated.
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000013', 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '5'::jsonb WHERE key = 'remplacement.alerte_direction_minutes';
UPDATE public.app_config SET value = '20'::jsonb WHERE key = 'remplacement.seance_tardive_minutes';
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'remplacement.alerte_direction_minutes') = '5'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'remplacement.seance_tardive_minutes') = '20'::jsonb,
  '5. la direction regle l''alerte (5) et la seance tardive (20)');
DO $bornes$
BEGIN
  BEGIN
    UPDATE public.app_config SET value = '1000'::jsonb WHERE key = 'remplacement.alerte_direction_minutes';
    RAISE EXCEPTION 'ROUGE : 5. 1000 minutes accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    UPDATE public.app_config SET value = '"dix"'::jsonb WHERE key = 'remplacement.seance_tardive_minutes';
    RAISE EXCEPTION 'ROUGE : 5. un texte accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  RAISE NOTICE 'OK 5. hors bornes et texte refuses';
END;
$bornes$;
RESET ROLE;
SELECT pg_temp.en_tant_que('a3b00000-0000-0000-0000-000000000014', 'accountant');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '9'::jsonb WHERE key = 'remplacement.alerte_direction_minutes';
RESET ROLE;
SELECT pg_temp.personne();
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'remplacement.alerte_direction_minutes') = '5'::jsonb,
  '5. le comptable ne change pas le reglage (RLS)');

-- Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.remplacement_auto_passer(timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.remplacement_auto_passer(timestamptz)', 'EXECUTE'),
  'droits : le passage reste prive');

ROLLBACK;
