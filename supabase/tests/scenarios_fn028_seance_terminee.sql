-- FN-028 : l'avis de fin de seance, application seulement, et le drapeau
-- courriel (decision du directeur du 01/11/2026). Tout est annule (ROLLBACK).
BEGIN;

INSERT INTO auth.users(id,email,raw_app_meta_data) VALUES
 ('f0280000-0000-0000-0000-000000000101','fn028-teacher@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000102','fn028-mineur@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000103','fn028-tuteur@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000104','fn028-jamais@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000105','fn028-tuteur-adulte@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000106','fn028-vide@example.test','{}'),
 ('f0280000-0000-0000-0000-000000000107','fn028-enfant@eleves.example.test',
  '{"child_of":"f0280000-0000-0000-0000-000000000103"}');
INSERT INTO public.households(id,timezone) VALUES
 ('f0280000-0000-0000-0000-000000000111','Europe/Paris'),
 ('f0280000-0000-0000-0000-000000000112','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
 ('f0280000-0000-0000-0000-000000000101','FN028-T','teacher',NULL,'Teacher','X','provisional_active'),
 ('f0280000-0000-0000-0000-000000000102','FN028-M','student','f0280000-0000-0000-0000-000000000111','Mineur','X','active'),
 ('f0280000-0000-0000-0000-000000000103','FN028-G','guardian','f0280000-0000-0000-0000-000000000111','Tuteur','X','active'),
 ('f0280000-0000-0000-0000-000000000104','FN028-J','student','f0280000-0000-0000-0000-000000000112','Jamais','X','active'),
 ('f0280000-0000-0000-0000-000000000105','FN028-GA','guardian','f0280000-0000-0000-0000-000000000112','TuteurAdulte','X','active'),
 ('f0280000-0000-0000-0000-000000000106','FN028-V','student','f0280000-0000-0000-0000-000000000112','Vide','X','active'),
 ('f0280000-0000-0000-0000-000000000107','FN028-E','student','f0280000-0000-0000-0000-000000000111','Enfant','X','active');
INSERT INTO public.student_profiles(profile_id,student_type,interface_mode,camera_policy) VALUES
 ('f0280000-0000-0000-0000-000000000102','minor','standard','allowed'),
 ('f0280000-0000-0000-0000-000000000104','autonomous','standard','allowed'),
 ('f0280000-0000-0000-0000-000000000106','autonomous','standard','allowed'),
 ('f0280000-0000-0000-0000-000000000107','minor','child','allowed');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local)
VALUES('f0280000-0000-0000-0000-000000000121',
 'f0280000-0000-0000-0000-000000000101','enfant',6,'FN-028 classe',1,10);
-- L'eleve « Jamais » a une exception de partage : rien ne sort du cahier.
INSERT INTO public.partage_pedagogique_eleve(groupe_id,student_id,regle) VALUES
 ('f0280000-0000-0000-0000-000000000121','f0280000-0000-0000-0000-000000000104','jamais');
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type,groupe_id) VALUES
 ('f0280000-0000-0000-0000-000000000131','f0280000-0000-0000-0000-000000000101',
  now()-interval '70 minutes',now()-interval '10 minutes','planned','standard','f0280000-0000-0000-0000-000000000121');
INSERT INTO public.session_participants(session_id,profile_id,role) VALUES
 ('f0280000-0000-0000-0000-000000000131','f0280000-0000-0000-0000-000000000101','teacher'),
 ('f0280000-0000-0000-0000-000000000131','f0280000-0000-0000-0000-000000000102','student'),
 ('f0280000-0000-0000-0000-000000000131','f0280000-0000-0000-0000-000000000104','student'),
 ('f0280000-0000-0000-0000-000000000131','f0280000-0000-0000-0000-000000000106','student')
ON CONFLICT DO NOTHING;

DO $scenario$
DECLARE
  c_s     constant text := 'f0280000-0000-0000-0000-000000000131';
  c_ens   constant uuid := 'f0280000-0000-0000-0000-000000000101';
  c_m     constant uuid := 'f0280000-0000-0000-0000-000000000102';
  c_g     constant uuid := 'f0280000-0000-0000-0000-000000000103';
  c_j     constant uuid := 'f0280000-0000-0000-0000-000000000104';
  c_ga    constant uuid := 'f0280000-0000-0000-0000-000000000105';
  c_v     constant uuid := 'f0280000-0000-0000-0000-000000000106';
  c_e     constant uuid := 'f0280000-0000-0000-0000-000000000107';
  v       jsonb;
  v_n     integer;
BEGIN
  -- 1. La cloture : l'enseignant seul (pas encore de cahier).
  UPDATE public.sessions SET status='preflight' WHERE id=c_s::uuid;
  UPDATE public.sessions SET status='in_progress' WHERE id=c_s::uuid;
  UPDATE public.sessions SET status='ended' WHERE id=c_s::uuid;
  SELECT n.params INTO v FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.destinataire=c_ens AND n.params->>'session_id'=c_s;
  IF v IS NULL OR v->>'portee'<>'classe' OR v->>'inscrits'<>'3' OR v->>'presents' IS NULL
     OR v->>'cahier_depose'<>'false' OR v->>'classe'<>'FN-028 classe' OR v->>'debut_local' IS NULL THEN
    RAISE EXCEPTION 'FN-028: avis de l''enseignant a la cloture incorrect (%)', v;
  END IF;
  IF EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement='seance_terminee'
              AND n.params->>'session_id'=c_s AND n.destinataire<>c_ens) THEN
    RAISE EXCEPTION 'FN-028: un avis famille est parti avant le cahier';
  END IF;

  -- 2. Le cahier : la famille, avec le Travail a preparer selon le partage.
  INSERT INTO public.lesson_reports(session_id,idempotency_key,content,author_profile_id) VALUES
   (c_s::uuid,'fn028-cahier-1',
    jsonb_build_object('eleves', jsonb_build_array(
      jsonb_build_object('student_id', c_m, 'confirme', true, 'travail_maison', E'Réviser la page 5\nRéciter Al-Fatiha'),
      jsonb_build_object('student_id', c_j, 'confirme', true, 'travail_maison', 'Lire la page 6'),
      jsonb_build_object('student_id', c_v, 'confirme', true))),
    c_ens);

  -- Partage ouvert, travail present.
  SELECT n.params INTO v FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.destinataire=c_m AND n.params->>'session_id'=c_s;
  IF v IS NULL OR v->>'portee'<>'soi' OR v->>'travail_etat'<>'partage'
     OR v->>'travail'<>'Réviser la page 5 · Réciter Al-Fatiha' THEN
    RAISE EXCEPTION 'FN-028: partage ouvert, avis de l''eleve incorrect (%)', v;
  END IF;
  -- Son tuteur (eleve mineur).
  SELECT n.params INTO v FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.destinataire=c_g AND n.params->>'session_id'=c_s;
  IF v IS NULL OR v->>'portee'<>'foyer' OR v->>'travail_etat'<>'partage' THEN
    RAISE EXCEPTION 'FN-028: tuteur de l''eleve mineur sans avis (%)', v;
  END IF;
  -- Partage « jamais » : rien n'est dit du travail.
  SELECT n.params INTO v FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.destinataire=c_j AND n.params->>'session_id'=c_s;
  IF v IS NULL OR v->>'travail_etat'<>'non_partage' OR v ? 'travail' THEN
    RAISE EXCEPTION 'FN-028: partage jamais, le travail fuit (%)', v;
  END IF;
  -- Cahier partage sans travail pour cet eleve : « aucun ».
  SELECT n.params INTO v FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.destinataire=c_v AND n.params->>'session_id'=c_s;
  IF v IS NULL OR v->>'travail_etat'<>'aucun' OR v ? 'travail' THEN
    RAISE EXCEPTION 'FN-028: cahier partage sans travail, avis incorrect (%)', v;
  END IF;
  -- Eleves adultes : leur tuteur ne recoit rien.
  IF EXISTS (SELECT 1 FROM public.notifications n WHERE n.evenement='seance_terminee'
              AND n.destinataire=c_ga AND n.params->>'session_id'=c_s) THEN
    RAISE EXCEPTION 'FN-028: le tuteur d''eleves adultes a recu un avis';
  END IF;

  -- 3. Un seul avis par seance et par destinataire, meme apres correction.
  INSERT INTO public.lesson_reports(session_id,idempotency_key,content,author_profile_id) VALUES
   (c_s::uuid,'fn028-cahier-2',
    jsonb_build_object('eleves', jsonb_build_array(
      jsonb_build_object('student_id', c_m, 'confirme', true, 'travail_maison', 'Autre travail'))),
    c_ens);
  v_n := private.avis_seance_terminee_famille(c_s::uuid) + private.avis_seance_terminee_enseignant(c_s::uuid);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'FN-028: un second avis a ete ecrit (%)', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM public.notifications n
   WHERE n.evenement='seance_terminee' AND n.params->>'session_id'=c_s;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'FN-028: attendu 5 avis (enseignant, 3 eleves, 1 tuteur), trouve %', v_n;
  END IF;

  -- 4. Application seulement : aucun courriel pour l'avis.
  IF EXISTS (SELECT 1 FROM public.courriels_sortants c WHERE c.modele='seance_terminee') THEN
    RAISE EXCEPTION 'FN-028: un courriel est parti pour seance_terminee';
  END IF;

  -- 5. Un evenement « courriel » en ecrit un, une fois ; un compte enfant
  --    n'en recoit aucun ; un evenement « application seulement », aucun.
  INSERT INTO public.notifications(destinataire,foyer_id,evenement,params,destination) VALUES
   (c_m,'f0280000-0000-0000-0000-000000000111','seance_annulee',
    jsonb_build_object('groupe_id','f0280000-0000-0000-0000-000000000121','portee','soi'),'/eleve'),
   (c_e,'f0280000-0000-0000-0000-000000000111','seance_annulee',
    jsonb_build_object('groupe_id','f0280000-0000-0000-0000-000000000121','portee','soi'),'/eleve'),
   (c_g,'f0280000-0000-0000-0000-000000000111','classe_changee',
    jsonb_build_object('groupe_id','f0280000-0000-0000-0000-000000000121','portee','foyer'),'/tuteur'),
   (c_ens,NULL,'eleve_inscrit',
    jsonb_build_object('groupe_id','f0280000-0000-0000-0000-000000000121','portee','classe'),'/enseignant/classes');
  SELECT count(*) INTO v_n FROM public.courriels_sortants c
   WHERE c.modele='seance_annulee' AND c.destinataire_profil=c_m;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'FN-028: seance_annulee devait ecrire un courriel, trouve %', v_n;
  END IF;
  IF EXISTS (SELECT 1 FROM public.courriels_sortants c WHERE c.destinataire_profil=c_e) THEN
    RAISE EXCEPTION 'FN-028: un compte enfant a recu un courriel';
  END IF;
  IF EXISTS (SELECT 1 FROM public.courriels_sortants c
              WHERE c.modele IN ('classe_changee','eleve_inscrit')
                AND c.destinataire_profil IN (c_g, c_ens)) THEN
    RAISE EXCEPTION 'FN-028: un evenement application seulement a ecrit un courriel';
  END IF;
END;
$scenario$;

-- 6. Droits : rien n'est appelable par un compte.
DO $droits$
BEGIN
  IF has_function_privilege('authenticated', 'private.avis_seance_terminee_famille(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'private.avis_seance_terminee_enseignant(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.notification_avec_courriel(text,text)', 'EXECUTE')
     OR has_table_privilege('authenticated', 'private.notification_courriel', 'SELECT') THEN
    RAISE EXCEPTION 'FN-028: une piece de l''avis est ouverte au client';
  END IF;
END;
$droits$;

ROLLBACK;
