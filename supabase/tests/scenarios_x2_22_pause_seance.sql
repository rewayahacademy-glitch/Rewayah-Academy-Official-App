BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('c2200000-0000-0000-0000-000000000101','x222-teacher@example.test'),
 ('c2200000-0000-0000-0000-000000000102','x222-admin@example.test'),
 ('c2200000-0000-0000-0000-000000000103','x222-student@example.test');
INSERT INTO public.households(id) VALUES
 ('c2200000-0000-0000-0000-000000000111');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
 ('c2200000-0000-0000-0000-000000000101','X222-TEACHER','teacher','c2200000-0000-0000-0000-000000000111','Teacher','X','provisional_active'),
 ('c2200000-0000-0000-0000-000000000102','X222-ADMIN','admin','c2200000-0000-0000-0000-000000000111','Admin','X','active'),
 ('c2200000-0000-0000-0000-000000000103','X222-STUDENT','student','c2200000-0000-0000-0000-000000000111','Student','X','active');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local)
VALUES('c2200000-0000-0000-0000-000000000121',
 'c2200000-0000-0000-0000-000000000101','enfant',5,'X2-22 classe',1,10);
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type,groupe_id) VALUES
 ('c2200000-0000-0000-0000-000000000131','c2200000-0000-0000-0000-000000000101',now(),now()+interval '1 hour','planned','standard','c2200000-0000-0000-0000-000000000121'),
 ('c2200000-0000-0000-0000-000000000132','c2200000-0000-0000-0000-000000000101',now(),now()+interval '1 hour','planned','standard','c2200000-0000-0000-0000-000000000121');

DO $scenario$
DECLARE
  v_reglage jsonb;
  v_etat jsonb;
  v_denied boolean;
  v_typed_error boolean;
  v_debut timestamptz;
  v_fin timestamptz;
BEGIN
  PERFORM set_config('request.jwt.claim.sub','c2200000-0000-0000-0000-000000000101',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','teacher'))::text,true);
  v_reglage := public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,15,10,'0','x222-config-1');
  IF v_reglage->>'version'<>'1' OR v_reglage->>'peut_modifier'<>'true' THEN
    RAISE EXCEPTION 'X2-22: réglage initial incorrect';
  END IF;
  IF public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,15,10,'0','x222-config-1')->>'version'<>'1' THEN
    RAISE EXCEPTION 'X2-22: rejeu idempotent a créé une nouvelle version';
  END IF;
  v_typed_error := false;
  BEGIN
    PERFORM public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,15,10,'0','x222-stale');
  EXCEPTION WHEN SQLSTATE '40001' THEN v_typed_error := true;
  END;
  IF NOT v_typed_error THEN RAISE EXCEPTION 'X2-22: version obsolète non signalée'; END IF;
  v_typed_error := false;
  BEGIN
    PERFORM public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,17,10,'1','x222-invalid');
  EXCEPTION WHEN SQLSTATE '22023' THEN v_typed_error := true;
  END;
  IF NOT v_typed_error THEN RAISE EXCEPTION 'X2-22: valeur invalide non signalée'; END IF;
  IF (SELECT count(*) FROM public.pause_reglages_historique
      WHERE groupe_id='c2200000-0000-0000-0000-000000000121') <> 1
     OR (SELECT count(*) FROM public.audit_logs
         WHERE action='pause_reglage_modifie'
           AND row_id='c2200000-0000-0000-0000-000000000121'
           AND payload ? 'ancienne_valeur' AND payload ? 'nouvelle_valeur') <> 1 THEN
    RAISE EXCEPTION 'X2-22: historique ou audit de réglage absent';
  END IF;

  UPDATE public.sessions SET status='preflight' WHERE id='c2200000-0000-0000-0000-000000000131';
  UPDATE public.sessions SET status='in_progress' WHERE id='c2200000-0000-0000-0000-000000000131';
  v_etat := public.pause_seance_etat('c2200000-0000-0000-0000-000000000131');
  IF v_etat->>'statut'<>'programmee' OR v_etat->>'duree_prevue_minutes'<>'10' THEN
    RAISE EXCEPTION 'X2-22: instantané au démarrage incorrect';
  END IF;
  PERFORM public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,20,20,'1','x222-config-2');
  IF (public.pause_seance_etat('c2200000-0000-0000-0000-000000000131')->>'duree_prevue_minutes')<>'10' THEN
    RAISE EXCEPTION 'X2-22: modification du réglage appliquée à une séance démarrée';
  END IF;
  v_etat := public.pause_seance_demarrer('c2200000-0000-0000-0000-000000000131','x222-start-1');
  v_debut := (v_etat->>'debut_utc')::timestamptz;
  IF v_etat->>'statut'<>'en_cours' OR v_debut IS NULL OR v_etat->>'peut_piloter'<>'true' THEN
    RAISE EXCEPTION 'X2-22: démarrage non horodaté par le serveur';
  END IF;
  v_etat := public.pause_seance_terminer('c2200000-0000-0000-0000-000000000131','x222-stop-1');
  v_fin := (v_etat->>'fin_utc')::timestamptz;
  IF v_etat->>'statut'<>'prise' OR v_fin IS NULL OR v_fin<v_debut THEN
    RAISE EXCEPTION 'X2-22: fin non horodatée par le serveur';
  END IF;

  UPDATE public.sessions SET status='preflight' WHERE id='c2200000-0000-0000-0000-000000000132';
  UPDATE public.sessions SET status='in_progress' WHERE id='c2200000-0000-0000-0000-000000000132';
  UPDATE public.sessions SET status='ended' WHERE id='c2200000-0000-0000-0000-000000000132';
  v_etat := public.pause_seance_etat('c2200000-0000-0000-0000-000000000132');
  IF v_etat->>'statut'<>'non_prise' OR v_etat->>'fin_utc' IS NULL THEN
    RAISE EXCEPTION 'X2-22: fin de séance sans pause non marquée';
  END IF;

  PERFORM set_config('request.jwt.claim.sub','c2200000-0000-0000-0000-000000000102',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','admin'))::text,true);
  v_reglage := public.pause_reglage_lire('c2200000-0000-0000-0000-000000000121');
  IF v_reglage->>'peut_modifier'<>'false' THEN RAISE EXCEPTION 'X2-22: admin annoncé modificateur'; END IF;
  v_denied := false;
  BEGIN
    PERFORM public.pause_reglage_ecrire('c2200000-0000-0000-0000-000000000121',true,15,10,'2','x222-admin-write');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'X2-22: admin a modifié le réglage'; END IF;

  PERFORM set_config('request.jwt.claim.sub','c2200000-0000-0000-0000-000000000103',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('app_metadata',jsonb_build_object('role','student'))::text,true);
  v_denied := false;
  BEGIN
    PERFORM public.pause_seance_etat('c2200000-0000-0000-0000-000000000131');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'X2-22: élève autorisé à lire la pause'; END IF;
END;
$scenario$;

ROLLBACK;
