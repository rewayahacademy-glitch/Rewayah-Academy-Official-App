-- PAUSE-SERVEUR (directeur, 12/11/2026) : la pause proposee.
-- Migration : supabase/migrations/20261124100000_pause_proposee.sql.
--
-- Controle : la pause par defaut (classe sans reglage : adulte 90 min, au milieu,
-- 10 min ; enfant 60 min, a 30 min, 5 min), le moment compte depuis le debut
-- PREVU, un reglage actif = faux respecte, la pause qui ne tient pas dans une
-- seance trop courte, le Non (compteur, prochaine proposition a + 5 min), la fin
-- des propositions quand la pause ne tient plus, le Oui apres un Non,
-- l'idempotence, le delai de rappel rendu (rappel_minutes, D-042), les refus (eleve, tuteur, autre enseignant, direction, anon) et
-- les droits (has_function_privilege). Tout est annule par le ROLLBACK final.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('c2400000-0000-0000-0000-000000000101','pp-t1@example.test'),
 ('c2400000-0000-0000-0000-000000000102','pp-t2@example.test'),
 ('c2400000-0000-0000-0000-000000000103','pp-t3@example.test'),
 ('c2400000-0000-0000-0000-000000000104','pp-t4@example.test'),
 ('c2400000-0000-0000-0000-000000000105','pp-admin@example.test'),
 ('c2400000-0000-0000-0000-000000000106','pp-student@example.test'),
 ('c2400000-0000-0000-0000-000000000107','pp-guardian@example.test');
INSERT INTO public.households(id) VALUES ('c2400000-0000-0000-0000-000000000111');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
 ('c2400000-0000-0000-0000-000000000101','PP-T1','teacher','c2400000-0000-0000-0000-000000000111','T1','P','provisional_active'),
 ('c2400000-0000-0000-0000-000000000102','PP-T2','teacher','c2400000-0000-0000-0000-000000000111','T2','P','provisional_active'),
 ('c2400000-0000-0000-0000-000000000103','PP-T3','teacher','c2400000-0000-0000-0000-000000000111','T3','P','provisional_active'),
 ('c2400000-0000-0000-0000-000000000104','PP-T4','teacher','c2400000-0000-0000-0000-000000000111','T4','P','provisional_active'),
 ('c2400000-0000-0000-0000-000000000105','PP-ADMIN','admin','c2400000-0000-0000-0000-000000000111','Admin','P','active'),
 ('c2400000-0000-0000-0000-000000000106','PP-STUDENT','student','c2400000-0000-0000-0000-000000000111','Student','P','active'),
 ('c2400000-0000-0000-0000-000000000107','PP-GUARDIAN','guardian','c2400000-0000-0000-0000-000000000111','Guardian','P','active');
-- GA : adultes (T1) ; GE : enfants (T2) ; GX : enfants, pause desactivee par T3.
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local) VALUES
 ('c2400000-0000-0000-0000-000000000121','c2400000-0000-0000-0000-000000000101','adulte',6,'PP adultes',1,10),
 ('c2400000-0000-0000-0000-000000000122','c2400000-0000-0000-0000-000000000102','enfant',5,'PP enfants',1,10),
 ('c2400000-0000-0000-0000-000000000123','c2400000-0000-0000-0000-000000000103','enfant',5,'PP sans pause',1,10);
-- Les seances de l'horaire recurrent n'ont rien a faire ici (meme correction que
-- scenarios_x2_22_pause_seance) : le scenario pose les siennes.
DELETE FROM public.sessions
 WHERE groupe_id IN ('c2400000-0000-0000-0000-000000000121',
                     'c2400000-0000-0000-0000-000000000122',
                     'c2400000-0000-0000-0000-000000000123');

-- Les reglages de la direction, a leurs valeurs de la migration.
DO $config$
BEGIN
  IF public.app_config_int('seance.pause_minutes_adulte', -1) <> 10
     OR public.app_config_int('seance.pause_minutes_enfant', -1) <> 5
     OR public.app_config_int('seance.pause_rappel_minutes', -1) <> 5
     OR public.app_config_int('seance.pause_reste_minimum_minutes', -1) <> 15 THEN
    RAISE EXCEPTION 'PP: reglages de la direction inattendus';
  END IF;
END;
$config$;

-- SA1 : adultes, 90 min, debut prevu dans 10 min (l'enseignant entre en avance).
-- SE1 : enfants, 60 min, debut prevu dans 5 min. SE2 : enfants, 30 min, plus tard.
-- SX1 : classe dont l'enseignant a desactive la pause.
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type,groupe_id) VALUES
 ('c2400000-0000-0000-0000-000000000131','c2400000-0000-0000-0000-000000000101',now()+interval '10 minutes',now()+interval '100 minutes','planned','standard','c2400000-0000-0000-0000-000000000121'),
 ('c2400000-0000-0000-0000-000000000132','c2400000-0000-0000-0000-000000000102',now()+interval '5 minutes',now()+interval '65 minutes','planned','standard','c2400000-0000-0000-0000-000000000122'),
 ('c2400000-0000-0000-0000-000000000133','c2400000-0000-0000-0000-000000000102',now()+interval '3 hours',now()+interval '210 minutes','planned','standard','c2400000-0000-0000-0000-000000000122'),
 ('c2400000-0000-0000-0000-000000000134','c2400000-0000-0000-0000-000000000103',now()+interval '5 minutes',now()+interval '65 minutes','planned','standard','c2400000-0000-0000-0000-000000000123');

DO $scenario$
DECLARE
  v_r jsonb;
  v_e jsonb;
  v_ok boolean;
BEGIN
  -- 1. Le reglage lu sans ligne : la verite (pause active, au milieu, duree du public).
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000101',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','teacher'))::text,true);
  v_r := public.pause_reglage_lire('c2400000-0000-0000-0000-000000000121');
  IF v_r->>'actif'<>'true' OR v_r->>'apres_minutes'<>'45' OR v_r->>'duree_minutes'<>'10'
     OR v_r->>'version'<>'0' OR v_r->>'par_defaut'<>'true' OR v_r->>'peut_modifier'<>'true' THEN
    RAISE EXCEPTION 'PP: reglage par defaut adulte incorrect : %', v_r;
  END IF;
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000102',true);
  v_r := public.pause_reglage_lire('c2400000-0000-0000-0000-000000000122');
  IF v_r->>'actif'<>'true' OR v_r->>'apres_minutes'<>'30' OR v_r->>'duree_minutes'<>'5'
     OR v_r->>'par_defaut'<>'true' THEN
    RAISE EXCEPTION 'PP: reglage par defaut enfant incorrect : %', v_r;
  END IF;

  -- 2. T3 desactive la pause de sa classe : son choix est respecte.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000103',true);
  v_r := public.pause_reglage_ecrire('c2400000-0000-0000-0000-000000000123',false,30,5,'0','pp-t3-off');
  IF v_r->>'actif'<>'false' OR v_r->>'version'<>'1' OR v_r->>'par_defaut'<>'false' THEN
    RAISE EXCEPTION 'PP: reglage inactif mal enregistre : %', v_r;
  END IF;
END;
$scenario$;

-- Les seances commencent (le declencheur fige la pause).
UPDATE public.sessions SET status='preflight'
 WHERE id IN ('c2400000-0000-0000-0000-000000000131','c2400000-0000-0000-0000-000000000132','c2400000-0000-0000-0000-000000000134');
UPDATE public.sessions SET status='in_progress'
 WHERE id IN ('c2400000-0000-0000-0000-000000000131','c2400000-0000-0000-0000-000000000132','c2400000-0000-0000-0000-000000000134');

DO $instantane$
DECLARE
  v_e jsonb;
BEGIN
  -- 3. Adultes : au milieu du debut PREVU (+10 + 45 min), 10 min, proposee.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000101',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','teacher'))::text,true);
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000131');
  IF v_e->>'statut'<>'programmee' OR v_e->>'duree_prevue_minutes'<>'10'
     OR (v_e->>'debut_prevu_utc')::timestamptz <> now()+interval '55 minutes'
     OR (v_e->>'proposer_a')::timestamptz <> now()+interval '55 minutes'
     OR v_e->>'refus_nombre'<>'0' OR v_e->>'peut_piloter'<>'true'
     OR NOT (v_e ? 'motif') OR v_e->>'motif' IS NOT NULL THEN
    RAISE EXCEPTION 'PP: pause par defaut adulte incorrecte : %', v_e;
  END IF;
  -- 3 bis. Le delai de rappel de la direction est rendu (D-042) : 5 par defaut,
  -- la valeur reglee ensuite (3), et jamais moins de 1 (reglage a 0).
  IF v_e->>'rappel_minutes' IS DISTINCT FROM '5' THEN
    RAISE EXCEPTION 'PP: rappel_minutes par defaut absent ou faux : %', v_e;
  END IF;
  UPDATE public.app_config SET value=to_jsonb(3) WHERE key='seance.pause_rappel_minutes';
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000131');
  IF v_e->>'rappel_minutes' IS DISTINCT FROM '3' THEN
    RAISE EXCEPTION 'PP: rappel_minutes regle a 3 non rendu : %', v_e;
  END IF;
  UPDATE public.app_config SET value=to_jsonb(0) WHERE key='seance.pause_rappel_minutes';
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000131');
  IF v_e->>'rappel_minutes' IS DISTINCT FROM '1' THEN
    RAISE EXCEPTION 'PP: rappel_minutes non borne a 1 : %', v_e;
  END IF;
  UPDATE public.app_config SET value=to_jsonb(5) WHERE key='seance.pause_rappel_minutes';
  -- Table de la pause prevue absente (lot priere non installe) : regle ordinaire.
  IF pg_catalog.to_regclass('public.seance_pause_prevue') IS NOT NULL THEN
    RAISE EXCEPTION 'PP: la table seance_pause_prevue existe deja, le cas « absente » ne prouve rien';
  END IF;

  -- 4. Enfants : +5 + 30 min, 5 min.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000102',true);
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000132');
  IF v_e->>'statut'<>'programmee' OR v_e->>'duree_prevue_minutes'<>'5'
     OR (v_e->>'debut_prevu_utc')::timestamptz <> now()+interval '35 minutes'
     OR (v_e->>'proposer_a')::timestamptz <> now()+interval '35 minutes' THEN
    RAISE EXCEPTION 'PP: pause par defaut enfant incorrecte : %', v_e;
  END IF;

  -- 5. Classe dont la pause est desactivee : aucune pause, aucune proposition.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000103',true);
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000134');
  IF v_e->>'statut'<>'non_prevue' OR v_e->>'proposer_a' IS NOT NULL THEN
    RAISE EXCEPTION 'PP: reglage inactif non respecte : %', v_e;
  END IF;
END;
$instantane$;

-- 6. Seance de 30 min sans reglage : 15 + 5 + 15 > 30, la pause ne tient pas.
UPDATE public.sessions SET status='ended' WHERE id='c2400000-0000-0000-0000-000000000132';
UPDATE public.sessions SET status='preflight' WHERE id='c2400000-0000-0000-0000-000000000133';
UPDATE public.sessions SET status='in_progress' WHERE id='c2400000-0000-0000-0000-000000000133';
DO $courte$
BEGIN
  IF (SELECT ps.statut FROM public.pause_seances ps
       WHERE ps.seance_id='c2400000-0000-0000-0000-000000000132') <> 'non_prise' THEN
    RAISE EXCEPTION 'PP: pause non prise non marquee a la fin';
  END IF;
  IF (SELECT ps.statut FROM public.pause_seances ps
       WHERE ps.seance_id='c2400000-0000-0000-0000-000000000133') <> 'non_prevue' THEN
    RAISE EXCEPTION 'PP: pause par defaut posee dans une seance trop courte';
  END IF;
END;
$courte$;

DO $refus$
DECLARE
  v_e jsonb;
  v_ok boolean;
BEGIN
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000101',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','teacher'))::text,true);

  -- 7. Non : compteur a 1, prochaine proposition a now() + 5 min.
  v_e := public.pause_seance_refuser('c2400000-0000-0000-0000-000000000131','pp-non-1');
  IF v_e->>'statut'<>'programmee' OR v_e->>'refus_nombre'<>'1'
     OR (v_e->>'proposer_a')::timestamptz <> now()+interval '5 minutes' THEN
    RAISE EXCEPTION 'PP: refus incorrect : %', v_e;
  END IF;
  -- 8. Rejouer la meme cle : aucun second refus.
  v_e := public.pause_seance_refuser('c2400000-0000-0000-0000-000000000131','pp-non-1');
  IF v_e->>'refus_nombre'<>'1' THEN
    RAISE EXCEPTION 'PP: rejeu idempotent a compte un second refus : %', v_e;
  END IF;
  -- La meme cle pour une autre operation est refusee.
  v_ok := false;
  BEGIN
    PERFORM public.pause_seance_demarrer('c2400000-0000-0000-0000-000000000131','pp-non-1');
  EXCEPTION WHEN SQLSTATE '23505' THEN v_ok := true;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'PP: cle de refus reutilisee pour demarrer'; END IF;
  -- Le Non ne laisse que la trace d'idempotence, comme demarrer.
  IF NOT EXISTS (SELECT 1 FROM public.pause_idempotence i
                  WHERE i.acteur_id='c2400000-0000-0000-0000-000000000101'
                    AND i.cle_idempotence='pp-non-1' AND i.operation='refuser') THEN
    RAISE EXCEPTION 'PP: refus non journalise';
  END IF;

  -- 9. Fin des propositions : rappel regle a 80 min, la pause (10) et le reste
  -- minimum (15) ne tiennent plus avant la fin prevue (now() + 100 min).
  UPDATE public.app_config SET value=to_jsonb(80) WHERE key='seance.pause_rappel_minutes';
  v_e := public.pause_seance_refuser('c2400000-0000-0000-0000-000000000131','pp-non-2');
  IF v_e->>'statut'<>'programmee' OR v_e->>'refus_nombre'<>'2' OR v_e->>'proposer_a' IS NOT NULL
     OR v_e->>'rappel_minutes' IS DISTINCT FROM '80' THEN
    RAISE EXCEPTION 'PP: proposition maintenue alors que la pause ne tient plus : %', v_e;
  END IF;
  UPDATE public.app_config SET value=to_jsonb(5) WHERE key='seance.pause_rappel_minutes';

  -- 10. Oui apres un Non : l'enseignant peut toujours prendre la pause.
  v_e := public.pause_seance_demarrer('c2400000-0000-0000-0000-000000000131','pp-oui');
  IF v_e->>'statut'<>'en_cours' OR v_e->>'debut_utc' IS NULL OR v_e->>'proposer_a' IS NOT NULL
     OR v_e->>'refus_nombre'<>'2' THEN
    RAISE EXCEPTION 'PP: oui apres non incorrect : %', v_e;
  END IF;
  -- Un Non sur une pause en cours est refuse.
  v_ok := false;
  BEGIN
    PERFORM public.pause_seance_refuser('c2400000-0000-0000-0000-000000000131','pp-non-3');
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'PP: refus accepte sur une pause en cours'; END IF;
  v_e := public.pause_seance_terminer('c2400000-0000-0000-0000-000000000131','pp-fin');
  IF v_e->>'statut'<>'prise' OR v_e->>'proposer_a' IS NOT NULL THEN
    RAISE EXCEPTION 'PP: fin de pause incorrecte : %', v_e;
  END IF;

  -- 11. Sans pause programmee (reglage inactif), le Non est refuse.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000103',true);
  v_ok := false;
  BEGIN
    PERFORM public.pause_seance_refuser('c2400000-0000-0000-0000-000000000134','pp-t3-non');
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'PP: refus accepte sans pause programmee'; END IF;
END;
$refus$;

-- 12. Les autres appelants ne refusent rien, et ne lisent rien de nouveau.
DO $denials$
DECLARE
  v_ids uuid[] := ARRAY[
    'c2400000-0000-0000-0000-000000000106'::uuid,
    'c2400000-0000-0000-0000-000000000107'::uuid,
    'c2400000-0000-0000-0000-000000000104'::uuid,
    'c2400000-0000-0000-0000-000000000105'::uuid
  ];
  v_roles text[] := ARRAY['student','guardian','teacher','admin'];
  v_i integer;
  v_ok boolean;
BEGIN
  FOR v_i IN 1..array_length(v_ids,1) LOOP
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claim.sub',v_ids[v_i]::text,true);
    PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object(
      'role',v_roles[v_i],'household_id','c2400000-0000-0000-0000-000000000111'))::text,true);
    v_ok := false;
    BEGIN
      PERFORM public.pause_seance_refuser('c2400000-0000-0000-0000-000000000132','pp-refus-'||v_roles[v_i]);
    EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'PP: % a refuse la pause', v_roles[v_i]; END IF;
    IF v_roles[v_i] IN ('student','guardian') THEN
      v_ok := false;
      BEGIN
        PERFORM public.pause_seance_etat('c2400000-0000-0000-0000-000000000133');
      EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
      END;
      IF NOT v_ok THEN RAISE EXCEPTION 'PP: % a lu l''etat de pause', v_roles[v_i]; END IF;
    END IF;
    SET LOCAL ROLE postgres;
  END LOOP;
END;
$denials$;

DO $acl$
DECLARE
  v_role text;
BEGIN
  IF NOT has_function_privilege('authenticated','public.pause_seance_refuser(uuid,text)','EXECUTE') THEN
    RAISE EXCEPTION 'PP: authenticated sans EXECUTE sur pause_seance_refuser';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon','public','agent_ro','service_role'] LOOP
    IF has_function_privilege(v_role,'public.pause_seance_refuser(uuid,text)','EXECUTE')
       OR has_function_privilege(v_role,'public.pause_seance_etat(uuid)','EXECUTE')
       OR has_function_privilege(v_role,'public.pause_reglage_lire(uuid)','EXECUTE') THEN
      RAISE EXCEPTION 'PP: % a EXECUTE sur une fonction de pause', v_role;
    END IF;
  END LOOP;
END;
$acl$;

-- 13. Pause prevue par le serveur (lot priere, 20261123930000, absent de ce
-- depot) : une table de meme forme, creee ici et annulee par le ROLLBACK.
-- GP : adultes de T4. SP1 : ligne valide (priere a +40 min, 15 min) ; SP2 :
-- ligne invalide (7 min, hors du pas de 5) ignoree ; SX2 : classe de T3 a la
-- pause desactivee, ligne valide (point a confirmer : la pause est posee).
CREATE TABLE public.seance_pause_prevue (
  session_id uuid PRIMARY KEY,
  debut_prevu_utc timestamptz NOT NULL,
  duree_minutes integer NOT NULL,
  motif text NOT NULL,
  priere text,
  calcule_le timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local) VALUES
 ('c2400000-0000-0000-0000-000000000124','c2400000-0000-0000-0000-000000000104','adulte',6,'PP priere',2,10);
DELETE FROM public.sessions WHERE groupe_id='c2400000-0000-0000-0000-000000000124';
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type,groupe_id) VALUES
 ('c2400000-0000-0000-0000-000000000141','c2400000-0000-0000-0000-000000000104',now()+interval '10 minutes',now()+interval '100 minutes','planned','standard','c2400000-0000-0000-0000-000000000124'),
 ('c2400000-0000-0000-0000-000000000142','c2400000-0000-0000-0000-000000000104',now()+interval '5 hours',now()+interval '390 minutes','planned','standard','c2400000-0000-0000-0000-000000000124'),
 ('c2400000-0000-0000-0000-000000000143','c2400000-0000-0000-0000-000000000103',now()+interval '3 hours',now()+interval '240 minutes','planned','standard','c2400000-0000-0000-0000-000000000123');
INSERT INTO public.seance_pause_prevue(session_id,debut_prevu_utc,duree_minutes,motif,priere) VALUES
 ('c2400000-0000-0000-0000-000000000141',now()+interval '50 minutes',15,'priere','asr'),
 ('c2400000-0000-0000-0000-000000000142',now()+interval '330 minutes',7,'priere','maghrib'),
 ('c2400000-0000-0000-0000-000000000143',now()+interval '200 minutes',10,'priere','isha');

UPDATE public.sessions SET status='preflight' WHERE id='c2400000-0000-0000-0000-000000000141';
UPDATE public.sessions SET status='in_progress' WHERE id='c2400000-0000-0000-0000-000000000141';
UPDATE public.sessions SET status='ended' WHERE id='c2400000-0000-0000-0000-000000000141';
UPDATE public.sessions SET status='preflight' WHERE id='c2400000-0000-0000-0000-000000000142';
UPDATE public.sessions SET status='in_progress' WHERE id='c2400000-0000-0000-0000-000000000142';
UPDATE public.sessions SET status='ended' WHERE id='c2400000-0000-0000-0000-000000000134';
UPDATE public.sessions SET status='preflight' WHERE id='c2400000-0000-0000-0000-000000000143';
UPDATE public.sessions SET status='in_progress' WHERE id='c2400000-0000-0000-0000-000000000143';

DO $priere$
DECLARE
  v_ps public.pause_seances%ROWTYPE;
  v_e jsonb;
BEGIN
  SELECT ps.* INTO v_ps FROM public.pause_seances ps WHERE ps.seance_id='c2400000-0000-0000-0000-000000000141';
  IF v_ps.duree_prevue_minutes<>15 OR v_ps.debut_prevu_utc<>now()+interval '50 minutes'
     OR v_ps.motif IS DISTINCT FROM 'priere' OR v_ps.statut<>'non_prise' THEN
    RAISE EXCEPTION 'PP: pause prevue valide non reprise : % % % %',
      v_ps.duree_prevue_minutes, v_ps.debut_prevu_utc, v_ps.motif, v_ps.statut;
  END IF;
  -- Ligne invalide : la regle ordinaire (milieu, 10 min, sans motif).
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000104',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','teacher'))::text,true);
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000142');
  IF v_e->>'statut'<>'programmee' OR v_e->>'duree_prevue_minutes'<>'10' OR v_e->>'motif' IS NOT NULL
     OR (v_e->>'debut_prevu_utc')::timestamptz <> now()+interval '345 minutes' THEN
    RAISE EXCEPTION 'PP: ligne invalide de pause prevue non ignoree : %', v_e;
  END IF;
  -- Pause desactivee par l'enseignant, mais pause prevue par le serveur :
  -- posee (point a confirmer), motif rendu, et le Non est compte.
  PERFORM set_config('request.jwt.claim.sub','c2400000-0000-0000-0000-000000000103',true);
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000143');
  IF v_e->>'statut'<>'programmee' OR v_e->>'motif'<>'priere' OR v_e->>'duree_prevue_minutes'<>'10'
     OR (v_e->>'proposer_a')::timestamptz <> now()+interval '200 minutes' THEN
    RAISE EXCEPTION 'PP: pause prevue sur classe sans pause incorrecte : %', v_e;
  END IF;
  v_e := public.pause_seance_refuser('c2400000-0000-0000-0000-000000000143','pp-priere-non');
  IF v_e->>'refus_nombre'<>'1' OR v_e->>'motif'<>'priere'
     OR (v_e->>'proposer_a')::timestamptz <> now()+interval '5 minutes' THEN
    RAISE EXCEPTION 'PP: refus d''une pause de priere incorrect : %', v_e;
  END IF;
  -- Le reste minimum ne vaut que pour la pause ordinaire (convenu avec le lot
  -- priere, 12/11/2026). Pause de 10 min placee a 20 min de la fin prevue
  -- (now() + 240 min) : a motif, elle reste proposee ; ordinaire, non (10 + 15 > 20).
  UPDATE public.pause_seances SET prochaine_proposition_utc = now()+interval '220 minutes'
   WHERE seance_id='c2400000-0000-0000-0000-000000000143';
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000143');
  IF v_e->>'motif'<>'priere' OR (v_e->>'proposer_a')::timestamptz IS DISTINCT FROM now()+interval '220 minutes' THEN
    RAISE EXCEPTION 'PP: pause de priere a 20 min de la fin non proposee : %', v_e;
  END IF;
  UPDATE public.pause_seances SET motif = NULL
   WHERE seance_id='c2400000-0000-0000-0000-000000000143';
  v_e := public.pause_seance_etat('c2400000-0000-0000-0000-000000000143');
  IF v_e->>'motif' IS NOT NULL OR v_e->>'proposer_a' IS NOT NULL THEN
    RAISE EXCEPTION 'PP: pause ordinaire a 20 min de la fin encore proposee : %', v_e;
  END IF;
END;
$priere$;

SET LOCAL ROLE anon;
DO $anon$
BEGIN
  BEGIN
    PERFORM public.pause_seance_refuser('c2400000-0000-0000-0000-000000000133','pp-anon');
    RAISE EXCEPTION 'PP: anon a refuse la pause';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$anon$;
RESET ROLE;

ROLLBACK;
