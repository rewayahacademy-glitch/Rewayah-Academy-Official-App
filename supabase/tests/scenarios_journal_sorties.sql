-- HORS-SALLE-2 (directeur, 12/11/2026 au soir) : le journal des sorties de
-- l'application d'un eleve pendant une seance.
-- Migration : supabase/migrations/20261124200000_journal_sorties.sql.
--
-- Controle : journal eteint (rien ne s'ecrit, aucun accord recueilli) ;
-- mineur sans accord (rien) ; l'enfant ne peut pas accepter pour lui ; un
-- tuteur d'un autre foyer ne peut ni accepter ni lire ; version perimee a
-- l'acceptation ; mineur avec l'accord d'un tuteur de SON foyer (ecrit) ;
-- bornes des heures (au moins 1 s, au plus le temps ecoule depuis le debut) ;
-- pas de doublon dans la meme seconde ; D6 (le tuteur note pour son enfant
-- depuis son appareil, un autre tuteur non) ; l'enseignant ne note rien ;
-- seance terminee (rien) ; lecture par l'enseignant de la seance, un autre
-- enseignant (rien), la direction, le tuteur (ses enfants seulement), l'eleve
-- (les siennes), anon (refus) ; accord retire (plus rien ne s'ecrit, les
-- lignes passees restent lisibles) ; adulte autonome (sans accord rien, avec
-- le sien ecrit) ; plafond de 200 ; version du texte changee (rien) ;
-- reglages verifies a l'ecriture ; regles_academie rend le delai ; droits.
-- Tout est annule par le ROLLBACK final.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('c2420000-0000-0000-0000-000000000101','js-t1@example.test'),
 ('c2420000-0000-0000-0000-000000000102','js-t2@example.test'),
 ('c2420000-0000-0000-0000-000000000103','js-admin@example.test'),
 ('c2420000-0000-0000-0000-000000000104','js-g1@example.test'),
 ('c2420000-0000-0000-0000-000000000105','js-e1@example.test'),
 ('c2420000-0000-0000-0000-000000000106','js-g2@example.test'),
 ('c2420000-0000-0000-0000-000000000107','js-a1@example.test'),
 ('c2420000-0000-0000-0000-000000000108','js-e2@example.test');
INSERT INTO public.households(id) VALUES
 ('c2420000-0000-0000-0000-000000000111'),
 ('c2420000-0000-0000-0000-000000000112'),
 ('c2420000-0000-0000-0000-000000000113'),
 ('c2420000-0000-0000-0000-000000000114');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
 ('c2420000-0000-0000-0000-000000000101','JS-T1','teacher','c2420000-0000-0000-0000-000000000114','T1','J','provisional_active'),
 ('c2420000-0000-0000-0000-000000000102','JS-T2','teacher','c2420000-0000-0000-0000-000000000114','T2','J','provisional_active'),
 ('c2420000-0000-0000-0000-000000000103','JS-ADMIN','admin','c2420000-0000-0000-0000-000000000114','Admin','J','active'),
 ('c2420000-0000-0000-0000-000000000104','JS-G1','guardian','c2420000-0000-0000-0000-000000000111','G1','J','active'),
 ('c2420000-0000-0000-0000-000000000105','JS-E1','student','c2420000-0000-0000-0000-000000000111','E1','J','active'),
 ('c2420000-0000-0000-0000-000000000106','JS-G2','guardian','c2420000-0000-0000-0000-000000000112','G2','J','active'),
 ('c2420000-0000-0000-0000-000000000107','JS-A1','student','c2420000-0000-0000-0000-000000000113','A1','J','active'),
 ('c2420000-0000-0000-0000-000000000108','JS-E2','student','c2420000-0000-0000-0000-000000000112','E2','J','active');
INSERT INTO public.student_profiles(profile_id,student_type) VALUES
 ('c2420000-0000-0000-0000-000000000105','minor'),
 ('c2420000-0000-0000-0000-000000000107','autonomous'),
 ('c2420000-0000-0000-0000-000000000108','minor');

-- S1 : en cours depuis 20 min. S2 : terminee.
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type) VALUES
 ('c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000101',now()-interval '20 minutes',now()+interval '40 minutes','in_progress','standard'),
 ('c2420000-0000-0000-0000-000000000132','c2420000-0000-0000-0000-000000000101',now()-interval '3 hours',now()-interval '2 hours','ended','standard');
INSERT INTO public.session_participants(session_id,profile_id,role) VALUES
 ('c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000101','teacher'),
 ('c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000105','student'),
 ('c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000107','student'),
 ('c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000108','student'),
 ('c2420000-0000-0000-0000-000000000132','c2420000-0000-0000-0000-000000000101','teacher'),
 ('c2420000-0000-0000-0000-000000000132','c2420000-0000-0000-0000-000000000105','student');

-- Qui appelle.
CREATE FUNCTION pg_temp.qui(p_uid uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE sql AS $f$
  SELECT set_config('request.jwt.claim.sub', coalesce(p_uid::text, ''), true),
         set_config('request.jwt.claims', CASE WHEN p_uid IS NULL THEN '' ELSE
           jsonb_build_object('app_metadata', jsonb_build_object('role', p_role,
             'household_id', p_foyer))::text END, true);
$f$;
CREATE FUNCTION pg_temp.lignes(p_eleve uuid) RETURNS bigint LANGUAGE sql AS $f$
  SELECT count(*) FROM public.journal_sorties_app
   WHERE session_id = 'c2420000-0000-0000-0000-000000000131' AND eleve_id = p_eleve;
$f$;

-- 0. Les reglages, a leurs valeurs de la migration.
DO $s0$
BEGIN
  IF (SELECT value FROM public.app_config WHERE key = 'salle.sorties.journal_actif') <> 'false'::jsonb
     OR public.app_config_int('salle.sorties.delai_secondes', -1) <> 30
     OR (SELECT value #>> '{}' FROM public.app_config WHERE key = 'salle.sorties.accord_version') <> 'sorties-2026-11-v1' THEN
    RAISE EXCEPTION 'JS0: reglages inattendus';
  END IF;
END;
$s0$;

-- 1. Journal eteint : aucun accord recueilli, rien ne s'ecrit.
DO $s1$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  v := public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-11-v1');
  IF v->>'erreur' IS DISTINCT FROM 'journal_eteint' THEN
    RAISE EXCEPTION 'JS1: accord recueilli journal eteint : %', v;
  END IF;
  v := public.accords_sorties();
  IF (v->>'journalActif')::boolean OR jsonb_array_length(v->'eleves') <> 1
     OR v->'eleves'->0->>'eleveId' <> 'c2420000-0000-0000-0000-000000000105'
     OR (v->'eleves'->0->>'enCours')::boolean THEN
    RAISE EXCEPTION 'JS1: etat de l''accord inattendu : %', v;
  END IF;
END;
$s1$;
-- Un accord pose a la main (journal eteint) ne fait rien ecrire non plus.
INSERT INTO public.accords_journal_sorties(eleve_id,accepte_par,version) VALUES
 ('c2420000-0000-0000-0000-000000000105','c2420000-0000-0000-0000-000000000104','sorties-2026-11-v1');
DO $s1b$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 20, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 0 THEN
    RAISE EXCEPTION 'JS1b: ecrit journal eteint : %', v;
  END IF;
END;
$s1b$;
UPDATE public.accords_journal_sorties SET retire_le = clock_timestamp(),
       retire_par = 'c2420000-0000-0000-0000-000000000104'
 WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105' AND retire_le IS NULL;

-- La direction allume le journal.
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'salle.sorties.journal_actif';

-- 2. Mineur sans accord : rien. L'enfant ne peut pas accepter pour lui.
--    Un tuteur d'un autre foyer non plus.
DO $s2$
DECLARE
  v jsonb;
  v_refus boolean;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 20, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 0 THEN
    RAISE EXCEPTION 'JS2: mineur sans accord note : %', v;
  END IF;
  v_refus := false;
  BEGIN
    PERFORM public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-11-v1');
  EXCEPTION WHEN insufficient_privilege THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS2: l''enfant a accepte pour lui-meme'; END IF;
  v_refus := false;
  BEGIN
    PERFORM public.accords_sorties();
    -- L'enfant peut lire la page ? Elle ne lui montre aucun eleve.
    IF jsonb_array_length(public.accords_sorties()->'eleves') <> 0 THEN
      RAISE EXCEPTION 'JS2: l''enfant voit une decision a prendre';
    END IF;
  END;

  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000106','guardian','c2420000-0000-0000-0000-000000000112');
  v_refus := false;
  BEGIN
    PERFORM public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-11-v1');
  EXCEPTION WHEN insufficient_privilege THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS2: un tuteur d''un autre foyer a accepte'; END IF;
  v_refus := false;
  BEGIN
    PERFORM public.retirer_accord_sorties('c2420000-0000-0000-0000-000000000105');
  EXCEPTION WHEN insufficient_privilege THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS2: un tuteur d''un autre foyer a retire'; END IF;
  -- Ni pour l'adulte autonome d'un autre foyer.
  v_refus := false;
  BEGIN
    PERFORM public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000107','sorties-2026-11-v1');
  EXCEPTION WHEN insufficient_privilege THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS2: un tuteur a accepte pour un adulte'; END IF;
END;
$s2$;

-- 3. Le tuteur de SON foyer : version perimee refusee, puis accord donne.
DO $s3$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  v := public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-10-v0');
  IF v->>'erreur' IS DISTINCT FROM 'version_perimee' THEN
    RAISE EXCEPTION 'JS3: version perimee acceptee : %', v;
  END IF;
  v := public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-11-v1');
  IF NOT (v->>'journalActif')::boolean OR NOT (v->'eleves'->0->>'enCours')::boolean
     OR v->'eleves'->0->>'accepteLe' IS NULL THEN
    RAISE EXCEPTION 'JS3: accord non enregistre : %', v;
  END IF;
  -- Rejouable : la meme acceptation n'ajoute rien.
  PERFORM public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000105','sorties-2026-11-v1');
  IF (SELECT count(*) FROM public.accords_journal_sorties
       WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105' AND retire_le IS NULL) <> 1 THEN
    RAISE EXCEPTION 'JS3: plus d''un accord en cours';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'accord_sorties_donne'
                  AND row_id = 'c2420000-0000-0000-0000-000000000105') THEN
    RAISE EXCEPTION 'JS3: accord non journalise';
  END IF;
END;
$s3$;

-- 4. L'enfant note : les heures viennent du serveur.
DO $s4$
DECLARE
  v jsonb;
  r record;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 45, true);
  IF NOT (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 1 THEN
    RAISE EXCEPTION 'JS4: sortie non notee : %', v;
  END IF;
  SELECT * INTO r FROM public.journal_sorties_app
   WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105';
  IF r.retour_le - r.sortie_le <> interval '45 seconds' OR NOT r.sortie_salle
     OR r.retour_le > clock_timestamp() OR r.retour_le < now() THEN
    RAISE EXCEPTION 'JS4: heures inattendues : % %', r.sortie_le, r.retour_le;
  END IF;
  -- Doublon dans la meme seconde : rien.
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 10, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 1 THEN
    RAISE EXCEPTION 'JS4: doublon dans la meme seconde : %', v;
  END IF;
END;
$s4$;

SELECT pg_sleep(1.1);
-- 5. Bornes : au moins 1 s.
DO $s5$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 0, false);
  IF NOT (v->>'note')::boolean OR NOT EXISTS (
       SELECT 1 FROM public.journal_sorties_app WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105'
          AND retour_le - sortie_le = interval '1 second') THEN
    RAISE EXCEPTION 'JS5: borne basse non appliquee : %', v;
  END IF;
END;
$s5$;

SELECT pg_sleep(1.1);
-- 6. Bornes : au plus le temps ecoule depuis le debut de la seance.
DO $s6$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 100000, false);
  IF NOT (v->>'note')::boolean THEN RAISE EXCEPTION 'JS6: non note : %', v; END IF;
  IF (SELECT min(sortie_le) FROM public.journal_sorties_app
       WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105')
     < (SELECT started_at FROM public.sessions WHERE id = 'c2420000-0000-0000-0000-000000000131') THEN
    RAISE EXCEPTION 'JS6: sortie avant le debut de la seance';
  END IF;
  -- L'enseignant ne note rien pour lui.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000101','teacher','c2420000-0000-0000-0000-000000000114');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 20, false);
  IF (v->>'note')::boolean THEN RAISE EXCEPTION 'JS6: l''enseignant a note'; END IF;
  -- Un tuteur d'un autre foyer ne note pas pour E1 (D6).
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000106','guardian','c2420000-0000-0000-0000-000000000112');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 20, false,
                               'c2420000-0000-0000-0000-000000000105');
  IF (v->>'note')::boolean THEN RAISE EXCEPTION 'JS6: un autre foyer a note'; END IF;
  -- Seance terminee : rien.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000132', 20, false);
  IF (v->>'note')::boolean OR EXISTS (SELECT 1 FROM public.journal_sorties_app
                                       WHERE session_id = 'c2420000-0000-0000-0000-000000000132') THEN
    RAISE EXCEPTION 'JS6: note sur une seance terminee';
  END IF;
END;
$s6$;

SELECT pg_sleep(1.1);
-- 7. D6 : le tuteur note pour son enfant, depuis son appareil.
DO $s7$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 12, false,
                               'c2420000-0000-0000-0000-000000000105');
  IF NOT (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 4 THEN
    RAISE EXCEPTION 'JS7: D6 non note : %', v;
  END IF;
END;
$s7$;

-- 8. Lecture.
DO $s8$
DECLARE
  v_n bigint;
  v_refus boolean;
BEGIN
  -- L'enseignant de la seance : les 4 lignes de E1.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000101','teacher','c2420000-0000-0000-0000-000000000114');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 4 THEN RAISE EXCEPTION 'JS8: enseignant lit % lignes', v_n; END IF;
  IF EXISTS (SELECT 1 FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131')
              WHERE duree_secondes = 45 AND sortie_salle AND prenom = 'E1') IS NOT TRUE THEN
    RAISE EXCEPTION 'JS8: ligne de 45 s absente';
  END IF;
  -- Un autre enseignant : rien.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000102','teacher','c2420000-0000-0000-0000-000000000114');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 0 THEN RAISE EXCEPTION 'JS8: autre enseignant lit % lignes', v_n; END IF;
  -- La direction : tout.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000103','admin','c2420000-0000-0000-0000-000000000114');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 4 THEN RAISE EXCEPTION 'JS8: direction lit % lignes', v_n; END IF;
  -- Le tuteur de E1 : ses lignes ; le tuteur d'un autre foyer : rien.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 4 THEN RAISE EXCEPTION 'JS8: tuteur lit % lignes', v_n; END IF;
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000106','guardian','c2420000-0000-0000-0000-000000000112');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 0 THEN RAISE EXCEPTION 'JS8: autre foyer lit % lignes', v_n; END IF;
  -- L'eleve : les siennes ; un camarade : rien.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 4 THEN RAISE EXCEPTION 'JS8: eleve lit % lignes', v_n; END IF;
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000108','student','c2420000-0000-0000-0000-000000000112');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 0 THEN RAISE EXCEPTION 'JS8: un camarade lit % lignes', v_n; END IF;
  -- Sans compte : refus.
  PERFORM pg_temp.qui(NULL, NULL, NULL);
  v_refus := false;
  BEGIN
    PERFORM count(*) FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  EXCEPTION WHEN insufficient_privilege THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS8: lecture sans compte'; END IF;
END;
$s8$;

SELECT pg_sleep(1.1);
-- 9. Accord retire : plus rien ne s'ecrit, les lignes passees restent lisibles.
DO $s9$
DECLARE
  v jsonb;
  v_n bigint;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  v := public.retirer_accord_sorties('c2420000-0000-0000-0000-000000000105');
  IF (v->'eleves'->0->>'enCours')::boolean THEN RAISE EXCEPTION 'JS9: accord encore en cours : %', v; END IF;
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 20, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000105') <> 4 THEN
    RAISE EXCEPTION 'JS9: ecrit apres retrait : %', v;
  END IF;
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000104','guardian','c2420000-0000-0000-0000-000000000111');
  SELECT count(*) INTO v_n FROM public.sorties_seance('c2420000-0000-0000-0000-000000000131');
  IF v_n <> 4 THEN RAISE EXCEPTION 'JS9: lignes passees illisibles (%)', v_n; END IF;
  IF (SELECT count(*) FROM public.accords_journal_sorties
       WHERE eleve_id = 'c2420000-0000-0000-0000-000000000105') <> 2 THEN
    RAISE EXCEPTION 'JS9: un accord a ete efface';
  END IF;
END;
$s9$;

-- 10. Adulte autonome : sans accord rien ; avec le sien, ecrit.
DO $s10$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000107','student','c2420000-0000-0000-0000-000000000113');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 30, false);
  IF (v->>'note')::boolean THEN RAISE EXCEPTION 'JS10: adulte sans accord note'; END IF;
  v := public.accords_sorties();
  IF jsonb_array_length(v->'eleves') <> 1 OR NOT (v->'eleves'->0->>'autonome')::boolean THEN
    RAISE EXCEPTION 'JS10: l''adulte ne voit pas sa decision : %', v;
  END IF;
  v := public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000107','sorties-2026-11-v1');
  IF NOT (v->'eleves'->0->>'enCours')::boolean THEN RAISE EXCEPTION 'JS10: accord adulte : %', v; END IF;
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 30, false);
  IF NOT (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000107') <> 1 THEN
    RAISE EXCEPTION 'JS10: adulte avec accord non note : %', v;
  END IF;
END;
$s10$;

-- 11. Plafond de 200 par seance et par eleve.
INSERT INTO public.journal_sorties_app(session_id,eleve_id,accord_id,sortie_le,retour_le)
SELECT 'c2420000-0000-0000-0000-000000000131','c2420000-0000-0000-0000-000000000107', a.id,
       now() - interval '19 minutes' + make_interval(secs => g * 5),
       now() - interval '19 minutes' + make_interval(secs => g * 5 + 2)
  FROM generate_series(1, 199) g
  JOIN public.accords_journal_sorties a
    ON a.eleve_id = 'c2420000-0000-0000-0000-000000000107' AND a.retire_le IS NULL;
SELECT pg_sleep(1.1);
DO $s11$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000107','student','c2420000-0000-0000-0000-000000000113');
  IF pg_temp.lignes('c2420000-0000-0000-0000-000000000107') <> 200 THEN
    RAISE EXCEPTION 'JS11: preparation du plafond';
  END IF;
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 30, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000107') <> 200 THEN
    RAISE EXCEPTION 'JS11: plafond depasse : %', v;
  END IF;
END;
$s11$;

-- 12. Le texte change de version : l'accord ancien ne vaut plus.
UPDATE public.app_config SET value = '"sorties-2026-12-v2"'::jsonb WHERE key = 'salle.sorties.accord_version';
DO $s12$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000107','student','c2420000-0000-0000-0000-000000000113');
  v := public.accords_sorties();
  IF (v->'eleves'->0->>'enCours')::boolean OR v->>'versionCourante' <> 'sorties-2026-12-v2' THEN
    RAISE EXCEPTION 'JS12: accord perime encore en cours : %', v;
  END IF;
  -- Le plafond est atteint pour A1 : on verifie sur E2, dont le tuteur
  -- accepte la version ancienne (refusee) puis rien ne s'ecrit.
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000106','guardian','c2420000-0000-0000-0000-000000000112');
  v := public.accepter_accord_sorties('c2420000-0000-0000-0000-000000000108','sorties-2026-11-v1');
  IF v->>'erreur' IS DISTINCT FROM 'version_perimee' THEN RAISE EXCEPTION 'JS12: %', v; END IF;
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000108','student','c2420000-0000-0000-0000-000000000112');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 30, false);
  IF (v->>'note')::boolean THEN RAISE EXCEPTION 'JS12: note sans accord a jour'; END IF;
END;
$s12$;
-- Un accord a la version ancienne pose a la main pour E2 : ne vaut pas.
INSERT INTO public.accords_journal_sorties(eleve_id,accepte_par,version) VALUES
 ('c2420000-0000-0000-0000-000000000108','c2420000-0000-0000-0000-000000000106','sorties-2026-11-v1');
DO $s12b$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000108','student','c2420000-0000-0000-0000-000000000112');
  v := public.noter_sortie_app('c2420000-0000-0000-0000-000000000131', 30, false);
  IF (v->>'note')::boolean OR pg_temp.lignes('c2420000-0000-0000-0000-000000000108') <> 0 THEN
    RAISE EXCEPTION 'JS12b: version perimee notee';
  END IF;
END;
$s12b$;

-- 13. Les reglages se verifient a l'ecriture.
DO $s13$
DECLARE
  v_refus boolean;
BEGIN
  v_refus := false;
  BEGIN
    UPDATE public.app_config SET value = '3'::jsonb WHERE key = 'salle.sorties.delai_secondes';
  EXCEPTION WHEN invalid_parameter_value THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS13: delai de 3 s accepte'; END IF;
  v_refus := false;
  BEGIN
    UPDATE public.app_config SET value = '"oui"'::jsonb WHERE key = 'salle.sorties.journal_actif';
  EXCEPTION WHEN invalid_parameter_value THEN v_refus := true;
  END;
  IF NOT v_refus THEN RAISE EXCEPTION 'JS13: journal_actif non booleen accepte'; END IF;
  UPDATE public.app_config SET value = '45'::jsonb WHERE key = 'salle.sorties.delai_secondes';
END;
$s13$;

-- 14. regles_academie rend le delai a tout participant.
DO $s14$
DECLARE
  v jsonb;
BEGIN
  PERFORM pg_temp.qui('c2420000-0000-0000-0000-000000000105','student','c2420000-0000-0000-0000-000000000111');
  v := public.regles_academie();
  IF (v->>'sorties_delai_secondes')::integer <> 45 OR NOT (v->>'sorties_journal_actif')::boolean
     OR v->>'sorties_accord_version' <> 'sorties-2026-12-v2'
     OR (v->>'capacite_enfant') IS NULL THEN
    RAISE EXCEPTION 'JS14: regles_academie : %', v;
  END IF;
END;
$s14$;

-- 15. Droits.
DO $s15$
DECLARE
  v_fn text;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY['public.accords_sorties()', 'public.accepter_accord_sorties(uuid,text)',
    'public.retirer_accord_sorties(uuid)', 'public.noter_sortie_app(uuid,integer,boolean,uuid)',
    'public.sorties_seance(uuid)'] LOOP
    IF has_function_privilege('anon', v_fn, 'EXECUTE')
       OR NOT has_function_privilege('authenticated', v_fn, 'EXECUTE') THEN
      RAISE EXCEPTION 'JS15: droits de %', v_fn;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'private.sorties_accord_valide(uuid)', 'EXECUTE')
     OR has_table_privilege('authenticated', 'public.journal_sorties_app', 'SELECT')
     OR has_table_privilege('authenticated', 'public.accords_journal_sorties', 'INSERT') THEN
    RAISE EXCEPTION 'JS15: droit direct inattendu';
  END IF;
END;
$s15$;

ROLLBACK;
