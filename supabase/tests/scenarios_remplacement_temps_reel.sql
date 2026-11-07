-- REMPLACEMENT-TEMPS-REEL (07/11/2026, DECISION-REMPLACEMENT-2026-11-07.md) :
-- toute l'equipe est alertee ; parmi ceux qui acceptent, le serveur retient le
-- mieux place (genre, puis langue), a egalite le premier arrive ; un rang 1
-- est retenu aussitot, sinon a la fin de la fenetre. Prouve :
--   t1. les quatre rangs d'une classe d'hommes en francais ;
--   t2. la fenetre : les rangs 4, 3, 2 attendent, en tete ou non ; le rang 1
--       l'emporte aussitot ; les autres l'apprennent (dejaPrise) ;
--   t3. fin de fenetre (5 s) : le rang 2 l'emporte sur le rang 3 arrive avant ;
--   t4. liste de preferences vide : le premier arrive l'emporte aussitot ;
--   t5. reglage hors bornes ou critere inconnu : le defaut (8 s,
--       ["genre","langue"]), jamais une erreur ;
--   t6. l'alerte part a toute l'equipe ; aucun droit client sur le choix ;
--   t7. egalite de rang : le premier arrive l'emporte ; fenetre de 10 s :
--       rien n'est tranche a 5 s, tout l'est a 10 s ;
--   t8. deux rangs 1 : un seul gagnant, l'autre apprend dejaPrise (la
--       concurrence vraie, deux connexions, est prouvee hors de ce fichier) ;
--   t9. les classes stables gardent le filtre de genre : l'affectation d'une
--       enseignante a une classe d'hommes reste refusee, et
--       remplacement_enseignant_compatible reste faux pour elle ;
--   t11. le titulaire ne prend pas sa propre absence ; un enseignant en cours
--        a la meme heure est refuse, et ne voit pas l'offre ;
--   t12. le filet : une absence en erreur n'empeche pas une autre d'etre
--        tranchee ; une absence deja tranchee n'est plus reprise ;
--   t10. contre-epreuve : sans 20261119300000, le scenario est ROUGE (t1).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'REMPLACEMENT ROUGE : %', p_label;
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
-- Une acceptation, rendue en texte : etat, et en tete si en attente.
CREATE FUNCTION pg_temp.accepter(p_id text, p_seance uuid, p_cle uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id);
  v := public.prendre_remplacement(p_seance, p_cle);
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
  pg_temp.accepter(text, uuid, uuid), pg_temp.rang(uuid, uuid), pg_temp.offres(text) TO authenticated;

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
  now() + interval '4 days', now() + interval '4 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000204', '7e500000-0000-4000-8000-000000000001',
  now() + interval '5 days', now() + interval '5 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000205', '7e500000-0000-4000-8000-000000000001',
  now() + interval '6 days', now() + interval '6 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000206', '7e500000-0000-4000-8000-000000000001',
  now() + interval '7 days', now() + interval '7 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101'),
 ('7e500000-0000-4000-8000-000000000207', '7e500000-0000-4000-8000-000000000001',
  now() + interval '8 days', now() + interval '8 days 1 hour', 'planned', 'standard', '7e500000-0000-4000-8000-000000000101');
-- Le propre cours de H1, a l'heure de S4 (t11).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type) VALUES
 ('7e500000-0000-4000-8000-000000000208', '7e500000-0000-4000-8000-000000000002',
  now() + interval '5 days', now() + interval '5 days 1 hour', 'planned', 'standard');
-- Les sept absences, declarees par le titulaire.
SELECT pg_temp.qui('7e500000-0000-4000-8000-000000000001');
SET LOCAL ROLE authenticated;
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000301');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000202', '7e500000-0000-4000-8000-000000000302');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000203', '7e500000-0000-4000-8000-000000000303');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000204', '7e500000-0000-4000-8000-000000000304');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000205', '7e500000-0000-4000-8000-000000000305');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000206', '7e500000-0000-4000-8000-000000000306');
SELECT public.declarer_absence_seance('7e500000-0000-4000-8000-000000000207', '7e500000-0000-4000-8000-000000000307');
RESET ROLE;

-- t1 : les rangs.
SELECT pg_temp.vrai(
  pg_temp.rang('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000002') = 1
  AND pg_temp.rang('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000003') = 2
  AND pg_temp.rang('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000004') = 3
  AND pg_temp.rang('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000005') = 4,
  't1 : genre et langue (1), genre seul (2), langue seule (3), ni l''un ni l''autre (4)');

-- t6 (alerte) : toute l'equipe a recu l'offre, les femmes comprises.
SELECT pg_temp.vrai(
  (SELECT count(DISTINCT destinataire) FROM public.notifications
    WHERE evenement = 'remplacement_propose'
      AND params ->> 'session_id' = '7e500000-0000-4000-8000-000000000201'
      AND destinataire::text LIKE '7e500000-%') = 6,
  't6 : l''alerte part a toute l''equipe (6 hors titulaire, femmes comprises)');

-- t2 : la fenetre sur S1.
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000005', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000411') = 'enAttente:true',
  't2 : F2 (rang 4) accepte la premiere : en attente, en tete');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000412') = 'enAttente:true',
  't2 : F1 (rang 3) : en attente, en tete');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000005', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000411') = 'enAttente:false',
  't2 : F2 rappelle : toujours en attente, plus en tete (idempotent)');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000413') = 'enAttente:true',
  't2 : H2 (rang 2) : en attente, en tete');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000002', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000414') = 'acceptee',
  't2 : H1 (rang 1) l''emporte aussitot, arrive le dernier');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000201',
                                     '7e500000-0000-4000-8000-000000000412') = 'dejaPrise',
  't2 : F1 l''apprend : dejaPrise');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT enseignant_remplacant_id FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000201' AND evenement = 'remplacement_pris')
    = '7e500000-0000-4000-8000-000000000002'
  AND (SELECT count(*) FROM public.remplacements_seance
        WHERE session_id = '7e500000-0000-4000-8000-000000000201' AND evenement = 'remplacement_pris') = 1,
  't2 : une seule prise, celle de H1');

-- t3 : fenetre de 5 s sur S2 ; F1 (rang 3) puis H2 (rang 2).
UPDATE public.app_config SET value = '5'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000202',
                                     '7e500000-0000-4000-8000-000000000421') = 'enAttente:true',
  't3 : F1 (rang 3) accepte la premiere');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000202',
                                     '7e500000-0000-4000-8000-000000000422') = 'enAttente:true',
  't3 : H2 (rang 2) : en attente, en tete');
RESET ROLE;
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 0,
  't3 : avant la fin de la fenetre, le filet ne tranche rien');
SELECT pg_catalog.pg_sleep(5.2);
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 1,
  't3 : a la fin de la fenetre, le filet tranche');
SELECT pg_temp.vrai(
  (SELECT enseignant_remplacant_id FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000202' AND evenement = 'remplacement_pris')
    = '7e500000-0000-4000-8000-000000000003',
  't3 : H2 (rang 2) l''emporte sur F1 (rang 3) arrivee avant lui');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000202',
                                     '7e500000-0000-4000-8000-000000000422') = 'acceptee'
  AND pg_temp.accepter('7e500000-0000-4000-8000-000000000004', '7e500000-0000-4000-8000-000000000202',
                       '7e500000-0000-4000-8000-000000000421') = 'dejaPrise',
  't3 : H2 rappelle a la fin du compte a rebours : acceptee ; F1 : dejaPrise');
RESET ROLE;

-- t7 : egalite de rang, fenetre de 10 s (S4) ; H3 puis H2, tous deux rang 2.
UPDATE public.app_config SET value = '10'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000006', '7e500000-0000-4000-8000-000000000204',
                                     '7e500000-0000-4000-8000-000000000441') = 'enAttente:true',
  't7 : H3 (rang 2) accepte le premier : en tete');
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000204',
                                     '7e500000-0000-4000-8000-000000000442') = 'enAttente:false',
  't7 : H2 (rang 2, arrive apres) : en attente, pas en tete (egalite : premier arrive)');
RESET ROLE;
SELECT pg_catalog.pg_sleep(5.2);
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 0,
  't7 : fenetre de 10 s : rien n''est tranche a 5 s');
SELECT pg_catalog.pg_sleep(5);
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 1,
  't7 : fenetre de 10 s : tranche a 10 s');
SELECT pg_temp.vrai(
  (SELECT enseignant_remplacant_id FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000204' AND evenement = 'remplacement_pris')
    = '7e500000-0000-4000-8000-000000000006',
  't7 : a rang egal, H3, le premier arrive, l''emporte');

-- t8 : deux rangs 1 sur S5 : H4 puis H1 ; un seul gagnant.
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000007', '7e500000-0000-4000-8000-000000000205',
                                     '7e500000-0000-4000-8000-000000000451') = 'acceptee'
  AND pg_temp.accepter('7e500000-0000-4000-8000-000000000002', '7e500000-0000-4000-8000-000000000205',
                       '7e500000-0000-4000-8000-000000000452') = 'dejaPrise',
  't8 : deux rangs 1 : H4, le premier, l''emporte ; H1 : dejaPrise');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000205' AND evenement = 'remplacement_pris') = 1,
  't8 : une seule prise');

-- t9 : les classes stables gardent le filtre de genre.
DO $t9$
BEGIN
  BEGIN
    PERFORM app_private.verifier_affectation_enseignant_base(
      '7e500000-0000-4000-8000-000000000101', '7e500000-0000-4000-8000-000000000004', false);
    RAISE EXCEPTION 'REMPLACEMENT ROUGE : t9 : une enseignante est affectee a une classe d''hommes';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'enseignant incompatible avec le public de la classe' THEN
      RAISE EXCEPTION 'REMPLACEMENT ROUGE : t9 : refus inattendu';
    END IF;
    RAISE NOTICE 'OK t9 : classe stable : l''enseignante reste refusee pour une classe d''hommes';
  END;
END
$t9$;
SELECT pg_temp.vrai(
  NOT public.remplacement_enseignant_compatible('7e500000-0000-4000-8000-000000000205', '7e500000-0000-4000-8000-000000000004')
  AND public.remplacement_enseignant_compatible('7e500000-0000-4000-8000-000000000205', '7e500000-0000-4000-8000-000000000002'),
  't9 : remplacement_enseignant_compatible garde le genre (direction, genre_compatible)');

-- t11 : titulaire et enseignant en cours.
SET LOCAL ROLE authenticated;
DO $t11$
BEGIN
  BEGIN
    PERFORM pg_temp.accepter('7e500000-0000-4000-8000-000000000001', '7e500000-0000-4000-8000-000000000206',
                             '7e500000-0000-4000-8000-000000000461');
    RAISE EXCEPTION 'REMPLACEMENT ROUGE : t11 : le titulaire prend sa propre absence';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK t11 : le titulaire ne prend pas sa propre absence';
  END;
  BEGIN
    PERFORM pg_temp.accepter('7e500000-0000-4000-8000-000000000002', '7e500000-0000-4000-8000-000000000204',
                             '7e500000-0000-4000-8000-000000000462');
    RAISE EXCEPTION 'REMPLACEMENT ROUGE : t11 : H1 est pris pendant son propre cours';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK t11 : un enseignant en cours a la meme heure est refuse';
  END;
END
$t11$;
SELECT pg_temp.vrai(
  NOT ('7e500000-0000-4000-8000-000000000204' = ANY(pg_temp.offres('7e500000-0000-4000-8000-000000000002')))
  AND '7e500000-0000-4000-8000-000000000204' = ANY(pg_temp.offres('7e500000-0000-4000-8000-000000000003')),
  't11 : H1, en cours a l''heure de S4, ne voit pas l''offre ; H2 la voit');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM private.remplacements_acceptations
               WHERE enseignant_id IN ('7e500000-0000-4000-8000-000000000001', '7e500000-0000-4000-8000-000000000002')
                 AND session_id IN ('7e500000-0000-4000-8000-000000000206', '7e500000-0000-4000-8000-000000000204')),
  't11 : aucune acceptation enregistree pour ces refus');

-- t12 : le filet isole chaque absence. S6 echoue (declencheur de test), S7
-- est tranchee quand meme ; les absences deja tranchees ne sont plus reprises.
UPDATE public.app_config SET value = '5'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000003', '7e500000-0000-4000-8000-000000000206',
                                     '7e500000-0000-4000-8000-000000000471') = 'enAttente:true'
  AND pg_temp.accepter('7e500000-0000-4000-8000-000000000005', '7e500000-0000-4000-8000-000000000207',
                       '7e500000-0000-4000-8000-000000000472') = 'enAttente:true',
  't12 : H2 attend sur S6, F2 attend sur S7');
RESET ROLE;
CREATE FUNCTION pg_temp.panne_s6() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.session_id = '7e500000-0000-4000-8000-000000000206' THEN
    RAISE EXCEPTION 'panne de test';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER rt_panne_s6 BEFORE INSERT ON public.remplacements_seance
  FOR EACH ROW EXECUTE FUNCTION pg_temp.panne_s6();
SELECT pg_catalog.pg_sleep(5.2);
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 1,
  't12 : S6 en erreur, S7 tranchee quand meme (un seul passage)');
SELECT pg_temp.vrai(
  (SELECT enseignant_remplacant_id FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000207' AND evenement = 'remplacement_pris')
    = '7e500000-0000-4000-8000-000000000005'
  AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance
    WHERE session_id = '7e500000-0000-4000-8000-000000000206' AND evenement = 'remplacement_pris'),
  't12 : F2 retenue sur S7 ; S6 reste ouverte');
DROP TRIGGER rt_panne_s6 ON public.remplacements_seance;
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 1,
  't12 : la panne levee, S6 est tranchee (seule ; les absences deja tranchees ne comptent pas)');
SELECT pg_temp.vrai(private.remplacement_fenetres_passer() = 0,
  't12 : un passage de plus ne tranche rien');

-- t4 : sans preference, le premier arrive l'emporte aussitot (S3).
UPDATE public.app_config SET value = '[]'::jsonb WHERE key = 'remplacement.preferences';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.accepter('7e500000-0000-4000-8000-000000000005', '7e500000-0000-4000-8000-000000000203',
                                     '7e500000-0000-4000-8000-000000000431') = 'acceptee',
  't4 : liste vide : F2, la premiere, l''emporte aussitot');
RESET ROLE;

-- t5 : bornes et criteres.
UPDATE public.app_config SET value = '11'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SELECT pg_temp.vrai(private.remplacement_fenetre() = interval '8 seconds',
  't5 : une fenetre de 11 s donne le defaut, 8 s');
UPDATE public.app_config SET value = '"huit"'::jsonb WHERE key = 'remplacement.fenetre_priorite_secondes';
SELECT pg_temp.vrai(private.remplacement_fenetre() = interval '8 seconds',
  't5 : une fenetre illisible donne le defaut, 8 s');
UPDATE public.app_config SET value = '["age"]'::jsonb WHERE key = 'remplacement.preferences';
SELECT pg_temp.vrai(private.remplacement_preferences() = ARRAY['genre', 'langue']::text[],
  't5 : un critere inconnu donne le defaut (jamais de second circuit)');
UPDATE public.app_config SET value = '{"x":1}'::jsonb WHERE key = 'remplacement.preferences';
SELECT pg_temp.vrai(private.remplacement_preferences() = ARRAY['genre', 'langue']::text[]
  AND pg_temp.rang('7e500000-0000-4000-8000-000000000201', '7e500000-0000-4000-8000-000000000004') = 3,
  't5 : une liste illisible donne le defaut ; le rang se calcule toujours');

-- t6 : aucun droit client.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.remplacement_choisir(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.remplacement_rang(uuid,uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.remplacement_fenetres_passer()', 'EXECUTE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'private.remplacements_acceptations', 'SELECT')
  AND NOT pg_catalog.has_table_privilege('anon', 'private.remplacements_acceptations', 'SELECT'),
  't6 : le choix, le rang et le journal sont fermes au client');

ROLLBACK;
