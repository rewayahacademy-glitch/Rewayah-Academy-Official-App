-- HARMONISATION-A, dette 2 (08/11/2026, 20261120300100) : la pre-alerte
-- « Je suis pret » passe par le rang et la fenetre, comme l'absence. Prouve :
--   p1. un rang 3 pret le premier attend, en tete ; un rang 1 est retenu
--       aussitot, arrive apres ; le premier l'apprend (dejaRetenu) ;
--   p2. fin de fenetre (5 s) : le filet retient le rang 2 contre le rang 3
--       arrive avant lui ; le rappel du client rend « retenu » / « dejaRetenu » ;
--   p3. a rang egal, le premier arrive est retenu, le second n'est pas en tete ;
--   p4. une seule ligne « pret » par seance, lue comme avant
--       (offres_remplacement : pret_moi / pret_collegue) ;
--   p5. aucun droit client sur le journal, l'ordre et le choix ;
--   p6. contre-epreuve : sans 20261120300100, le scenario est ROUGE (p1).
-- Fixtures : celles de scenarios_remplacement_temps_reel (classe d'hommes en
-- francais ; H1 rang 1, H2 rang 2, F1 rang 3, F2 rang 4 ; H3 egal a H2).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PRET ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.qui(p_id text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id, true);
  PERFORM set_config('test.uid', p_id, true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
END $$;
-- Un « Je suis pret », rendu en texte : etat, et en tete si en attente.
CREATE FUNCTION pg_temp.pret(p_id text, p_seance uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id);
  v := public.se_declarer_pret_remplacement(p_seance);
  RETURN (v ->> 'etat') || CASE WHEN v ? 'enTete' THEN ':' || (v ->> 'enTete') ELSE '' END;
END $$;
-- Le rang, lu par le proprietaire (plpgsql : resolu a l'appel, pour la
-- contre-epreuve).
-- Les seances proposees a [p_id] (offres_remplacement, comme le client).
CREATE FUNCTION pg_temp.offres(p_id text) RETURNS text[]
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id);
  RETURN ARRAY(SELECT o ->> 'seance_id' FROM pg_catalog.jsonb_array_elements(public.offres_remplacement()) o);
END $$;
CREATE FUNCTION pg_temp.rang(p_seance uuid, p_id uuid) RETURNS smallint
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF pg_catalog.to_regprocedure('private.remplacement_rang(uuid,uuid)') IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN private.remplacement_rang(p_seance, p_id);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.qui(text),
  pg_temp.pret(text, uuid), pg_temp.rang(uuid, uuid), pg_temp.offres(text) TO authenticated;

-- T : titulaire (homme). H1 : homme, francais. H2 : homme, sans francais.
-- F1 : femme, francais. F2 : femme, sans francais. H3 : homme, sans francais
-- (meme rang que H2). H4 : homme, francais (meme rang que H1).
INSERT INTO auth.users (id, email) VALUES
 ('7e500000-0000-4000-8000-000000000006', 'rt-h3@test.invalid'),
 ('7e500000-0000-4000-8000-000000000007', 'rt-h4@test.invalid'),
 ('7e500000-0000-4000-8000-000000000001', 'rt-titulaire@test.invalid'),
 ('7e500000-0000-4000-8000-000000000002', 'rt-h1@test.invalid'),
 ('7e500000-0000-4000-8000-000000000003', 'rt-h2@test.invalid'),
 ('7e500000-0000-4000-8000-000000000004', 'rt-f1@test.invalid'),
 ('7e500000-0000-4000-8000-000000000005', 'rt-f2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e500000-0000-4000-8000-000000000001', 'RT-T', 'teacher', NULL, 'Titulaire', 'Rt', 'provisional_active', 'male'),
 ('7e500000-0000-4000-8000-000000000002', 'RT-H1', 'teacher', NULL, 'Homme', 'Un', 'provisional_active', 'male'),
 ('7e500000-0000-4000-8000-000000000003', 'RT-H2', 'teacher', NULL, 'Homme', 'Deux', 'provisional_active', 'male'),
 ('7e500000-0000-4000-8000-000000000004', 'RT-F1', 'teacher', NULL, 'Femme', 'Un', 'provisional_active', 'female'),
 ('7e500000-0000-4000-8000-000000000005', 'RT-F2', 'teacher', NULL, 'Femme', 'Deux', 'provisional_active', 'female'),
 ('7e500000-0000-4000-8000-000000000006', 'RT-H3', 'teacher', NULL, 'Homme', 'Trois', 'provisional_active', 'male'),
 ('7e500000-0000-4000-8000-000000000007', 'RT-H4', 'teacher', NULL, 'Homme', 'Quatre', 'provisional_active', 'male');
INSERT INTO public.teacher_profiles (profile_id, kyc_status, languages) VALUES
 ('7e500000-0000-4000-8000-000000000001', 'approved', '{francais}'),
 ('7e500000-0000-4000-8000-000000000002', 'approved', '{francais}'),
 ('7e500000-0000-4000-8000-000000000003', 'approved', '{english}'),
 ('7e500000-0000-4000-8000-000000000004', 'approved', '{francais}'),
 ('7e500000-0000-4000-8000-000000000005', 'approved', '{poular}'),
 ('7e500000-0000-4000-8000-000000000006', 'approved', '{english}'),
 ('7e500000-0000-4000-8000-000000000007', 'approved', '{francais}');
DO $contrats$
DECLARE v record; v_nda text; v_notice text;
BEGIN
  SELECT version INTO v_nda FROM public.contract_texts WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current;
  SELECT version INTO v_notice FROM public.contract_required_versions WHERE contract_kind = 'recording_and_control_notice';
  FOR v IN SELECT id FROM public.profiles WHERE immutable_id LIKE 'RT-%' LOOP
    PERFORM pg_temp.qui(v.id::text);
    PERFORM public.signer_contrat(v_nda, 'Fixture remplacement');
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES (v.id, 'recording_and_control_notice', v_notice) ON CONFLICT DO NOTHING;
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES (v.id, 'teacher_conduct_code', public.code_conduite_version_requise()) ON CONFLICT DO NOTHING;
    UPDATE public.profiles SET account_status = 'active' WHERE id = v.id;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub', '', true); PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('test.uid', '', true); PERFORM set_config('test.jwt', '', true);
END
$contrats$;
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, langue_code)
VALUES ('7e500000-0000-4000-8000-000000000101', '7e500000-0000-4000-8000-000000000001',
        'adulte', 6, 'RT classe', 1, 18, 'Europe/Paris', 'hommes', 'francais');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) VALUES
 ('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000001',
  now() + interval '2 days', now() + interval '2 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000202', '7e500000-0000-4000-8000-000000000001',
  now() + interval '3 days', now() + interval '3 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000203', '7e500000-0000-4000-8000-000000000001',
  now() + interval '4 days', now() + interval '4 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101');
-- Les trois pre-alertes, posees comme par remplacement_auto_passer.
INSERT INTO public.remplacements_preparation (session_id, evenement) VALUES
 ('7e500000-0000-4000-8000-000000000201', 'pre_alerte'),
 ('7e500000-0000-4000-8000-000000000202', 'pre_alerte'),
 ('7e500000-0000-4000-8000-000000000203', 'pre_alerte');
CREATE FUNCTION pg_temp.retenu(p_seance uuid) RETURNS uuid LANGUAGE sql AS $$
  SELECT enseignant_id FROM public.remplacements_preparation
   WHERE session_id = p_seance AND evenement = 'pret' $$;

-- p1 : S1, un rang 3 puis un rang 1.
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000201') = 'enAttente:true',
  'p1 : F1 (rang 3) prete la premiere : en attente, en tete');
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000002', '7e500000-0000-4000-8000-000000000201') = 'retenu',
  'p1 : H1 (rang 1) retenu aussitot, arrive apres');
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000201') = 'dejaRetenu',
  'p1 : F1 l''apprend : dejaRetenu');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.retenu('7e500000-0000-4000-8000-000000000201') = '7e500000-0000-4000-8000-000000000002'
  AND (SELECT count(*) FROM public.remplacements_preparation
        WHERE session_id = '7e500000-0000-4000-8000-000000000201' AND evenement = 'pret') = 1,
  'p1 : une seule ligne « pret », celle de H1');

-- p2 : S2, fenetre de 5 s ; F1 (rang 3) puis H2 (rang 2).
UPDATE public.app_config SET value = '5'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000202') = 'enAttente:true'
  AND pg_temp.pret('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000202') = 'enAttente:true',
  'p2 : F1 puis H2 (rang 2, en tete) attendent');
RESET ROLE;
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 0 AND pg_temp.retenu('7e500000-0000-4000-8000-000000000202') IS NULL,
  'p2 : avant la fin de la fenetre, le filet ne tranche rien');
SELECT pg_catalog.pg_sleep(5.2);
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 1
  AND pg_temp.retenu('7e500000-0000-4000-8000-000000000202') = '7e500000-0000-4000-8000-000000000003',
  'p2 : a la fin de la fenetre, le filet retient H2 (rang 2) contre F1 arrivee avant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000202') = 'retenu'
  AND pg_temp.pret('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000202') = 'dejaRetenu',
  'p2 : le rappel du client : H2 retenu, F1 dejaRetenu');

-- p3 : S3, a rang egal (H3 puis H2, rang 2) : le premier arrive.
SELECT pg_temp.vrai(pg_temp.pret('7e500000-0000-4000-8000-000000000006', '7e500000-0000-4000-8000-000000000203') = 'enAttente:true'
  AND pg_temp.pret('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000203') = 'enAttente:false',
  'p3 : H3 puis H2 (rang egal) : H2 n''est pas en tete');
RESET ROLE;
SELECT pg_catalog.pg_sleep(5.2);
SELECT private.remplacement_fenetres_passer();
SELECT pg_temp.vrai(pg_temp.retenu('7e500000-0000-4000-8000-000000000203') = '7e500000-0000-4000-8000-000000000006',
  'p3 : a rang egal, H3, le premier arrive, est retenu');

-- p4 : la ligne « pret » se lit comme avant dans le tableau commun.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('7e500000-0000-4000-8000-000000000002');
SELECT pg_temp.vrai(
  (SELECT o ->> 'etat' FROM pg_catalog.jsonb_array_elements(public.offres_remplacement()) o
    WHERE o ->> 'seance_id' = '7e500000-0000-4000-8000-000000000201') = 'pret_moi',
  'p4 : H1 voit S1 « pret_moi »');
SELECT pg_temp.qui('7e500000-0000-4000-8000-000000000004');
SELECT pg_temp.vrai(
  (SELECT o ->> 'etat' FROM pg_catalog.jsonb_array_elements(public.offres_remplacement()) o
    WHERE o ->> 'seance_id' = '7e500000-0000-4000-8000-000000000201') = 'pret_collegue',
  'p4 : F1 voit S1 « pret_collegue »');
RESET ROLE;

-- p5 : aucun droit client.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('authenticated', 'private.remplacements_prets_candidats', 'SELECT')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.remplacement_choisir_pret(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated',
        'private.remplacement_ordre(uuid[],smallint[],timestamp with time zone[])', 'EXECUTE'),
  'p5 : le journal, l''ordre et le choix sont fermes au client');

ROLLBACK;
