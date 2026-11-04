-- FN-025 : `motif_refus_salle` dit pourquoi la salle est refusee, a qui y a
-- droit seulement. Arbitrage du pilote (01/11/2026) : participant -> motif ;
-- inconnu -> NULL (aucune fuite) ; seance ouverte -> NULL ; droits fermes au
-- client. Tout est annule a la fin (ROLLBACK).
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('f0250000-0000-0000-0000-000000000101','fn025-teacher@example.test'),
 ('f0250000-0000-0000-0000-000000000102','fn025-student@example.test'),
 ('f0250000-0000-0000-0000-000000000103','fn025-guardian@example.test'),
 ('f0250000-0000-0000-0000-000000000104','fn025-stranger@example.test'),
 ('f0250000-0000-0000-0000-000000000105','fn025-other-guardian@example.test');
INSERT INTO public.households(id) VALUES
 ('f0250000-0000-0000-0000-000000000111'),
 ('f0250000-0000-0000-0000-000000000112');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
 ('f0250000-0000-0000-0000-000000000101','FN025-TEACHER','teacher',NULL,'Teacher','X','provisional_active'),
 ('f0250000-0000-0000-0000-000000000102','FN025-STUDENT','student','f0250000-0000-0000-0000-000000000111','Student','X','active'),
 ('f0250000-0000-0000-0000-000000000103','FN025-GUARDIAN','guardian','f0250000-0000-0000-0000-000000000111','Guardian','X','active'),
 ('f0250000-0000-0000-0000-000000000104','FN025-STRANGER','student','f0250000-0000-0000-0000-000000000112','Stranger','X','active'),
 ('f0250000-0000-0000-0000-000000000105','FN025-OTHERG','guardian','f0250000-0000-0000-0000-000000000112','Other','X','active');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local)
VALUES('f0250000-0000-0000-0000-000000000121',
 'f0250000-0000-0000-0000-000000000101','enfant',5,'FN-025 classe',1,10);

-- 131 : ouverte (fenetre d'acces commencee) ; 132 : close par son statut ; 133 : fenetre
-- depassee (fin il y a 2 h, grace de 15 min) ; 134 : pas encore ouverte ;
-- 135 : annulee.
INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type,groupe_id,join_opens_at) VALUES
 ('f0250000-0000-0000-0000-000000000131','f0250000-0000-0000-0000-000000000101',now()+interval '5 minutes',now()+interval '65 minutes','planned','standard','f0250000-0000-0000-0000-000000000121',NULL),
 ('f0250000-0000-0000-0000-000000000132','f0250000-0000-0000-0000-000000000101',now()-interval '55 minutes',now()-interval '5 minutes','planned','standard','f0250000-0000-0000-0000-000000000121',NULL),
 ('f0250000-0000-0000-0000-000000000133','f0250000-0000-0000-0000-000000000101',now()-interval '3 hours',now()-interval '2 hours','planned','standard','f0250000-0000-0000-0000-000000000121',NULL),
 ('f0250000-0000-0000-0000-000000000134','f0250000-0000-0000-0000-000000000101',now()+interval '1 day',now()+interval '1 day 1 hour','planned','standard','f0250000-0000-0000-0000-000000000121',NULL),
 ('f0250000-0000-0000-0000-000000000135','f0250000-0000-0000-0000-000000000101',now()+interval '2 days',now()+interval '2 days 1 hour','planned','standard','f0250000-0000-0000-0000-000000000121',NULL);
INSERT INTO public.session_participants(session_id,profile_id,role)
SELECT s.id, p.id, p.role::public.participant_role FROM
 (VALUES ('f0250000-0000-0000-0000-000000000131'::uuid),('f0250000-0000-0000-0000-000000000132'),
         ('f0250000-0000-0000-0000-000000000133'),('f0250000-0000-0000-0000-000000000134'),
         ('f0250000-0000-0000-0000-000000000135')) AS s(id)
 CROSS JOIN (VALUES ('f0250000-0000-0000-0000-000000000102'::uuid,'student'),
                    ('f0250000-0000-0000-0000-000000000101'::uuid,'teacher')) AS p(id,role)
ON CONFLICT DO NOTHING;

UPDATE public.sessions SET status='preflight' WHERE id='f0250000-0000-0000-0000-000000000132';
UPDATE public.sessions SET status='in_progress' WHERE id='f0250000-0000-0000-0000-000000000132';
UPDATE public.sessions SET status='ended' WHERE id='f0250000-0000-0000-0000-000000000132';
UPDATE public.sessions SET status='canceled' WHERE id='f0250000-0000-0000-0000-000000000135';

SET LOCAL ROLE service_role;
DO $scenario$
DECLARE
  v jsonb;
  c_eleve    constant uuid := 'f0250000-0000-0000-0000-000000000102';
  c_ens      constant uuid := 'f0250000-0000-0000-0000-000000000101';
  c_tuteur   constant uuid := 'f0250000-0000-0000-0000-000000000103';
  c_inconnu  constant uuid := 'f0250000-0000-0000-0000-000000000104';
  c_autre_t  constant uuid := 'f0250000-0000-0000-0000-000000000105';
BEGIN
  -- Participant : le motif et les bornes du serveur.
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_eleve);
  IF v->>'motif' IS DISTINCT FROM 'terminee' OR v->>'fin_utc' IS NULL OR v->>'grace_minutes' IS NULL THEN
    RAISE EXCEPTION 'FN-025: seance close, participant sans motif terminee (%)', v;
  END IF;
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000133', c_eleve);
  IF v->>'motif' IS DISTINCT FROM 'terminee' THEN
    RAISE EXCEPTION 'FN-025: fenetre depassee sans motif terminee (%)', v;
  END IF;
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000134', c_eleve);
  IF v->>'motif' IS DISTINCT FROM 'pas_encore_ouverte' OR v->>'ouverture_utc' IS NULL THEN
    RAISE EXCEPTION 'FN-025: avant l''ouverture sans motif (%)', v;
  END IF;
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000135', c_eleve);
  IF v->>'motif' IS DISTINCT FROM 'annulee' THEN
    RAISE EXCEPTION 'FN-025: seance annulee sans motif annulee (%)', v;
  END IF;
  -- L'enseignant de la seance aussi.
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_ens);
  IF v->>'motif' IS DISTINCT FROM 'terminee' THEN
    RAISE EXCEPTION 'FN-025: enseignant sans motif (%)', v;
  END IF;
  -- Le tuteur pour un eleve de son foyer.
  v := public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_tuteur, c_eleve);
  IF v->>'motif' IS DISTINCT FROM 'terminee' THEN
    RAISE EXCEPTION 'FN-025: tuteur du foyer sans motif (%)', v;
  END IF;

  -- Seance ouverte : le refus a une autre cause, rien a dire.
  IF public.motif_refus_salle('f0250000-0000-0000-0000-000000000131', c_eleve) IS NOT NULL THEN
    RAISE EXCEPTION 'FN-025: seance ouverte avec un motif';
  END IF;

  -- Aucune fuite : inconnu, tuteur d'un autre foyer, tuteur seul, seance
  -- inexistante, arguments nuls.
  IF public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_inconnu) IS NOT NULL
     OR public.motif_refus_salle('f0250000-0000-0000-0000-000000000133', c_inconnu) IS NOT NULL
     OR public.motif_refus_salle('f0250000-0000-0000-0000-000000000134', c_inconnu) IS NOT NULL THEN
    RAISE EXCEPTION 'FN-025: un inconnu apprend l''etat d''une seance';
  END IF;
  IF public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_autre_t, c_eleve) IS NOT NULL THEN
    RAISE EXCEPTION 'FN-025: un tuteur d''un autre foyer apprend l''etat d''une seance';
  END IF;
  IF public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', c_tuteur) IS NOT NULL THEN
    RAISE EXCEPTION 'FN-025: un tuteur sans eleve apprend l''etat d''une seance';
  END IF;
  IF public.motif_refus_salle('f0250000-0000-0000-0000-0000000001ff', c_eleve) IS NOT NULL
     OR public.motif_refus_salle(NULL, c_eleve) IS NOT NULL
     OR public.motif_refus_salle('f0250000-0000-0000-0000-000000000132', NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'FN-025: seance inexistante ou argument nul avec un motif';
  END IF;
END;
$scenario$;
RESET ROLE;

-- Droits : le client n'appelle jamais cette fonction.
DO $droits$
BEGIN
  IF has_function_privilege('anon', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-025: motif_refus_salle ouverte au client';
  END IF;
  IF NOT has_function_privilege('service_role', 'public.motif_refus_salle(uuid, uuid, uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-025: motif_refus_salle fermee au role de service';
  END IF;
END;
$droits$;

SET LOCAL ROLE authenticated;
DO $client$
BEGIN
  BEGIN
    PERFORM public.motif_refus_salle('f0250000-0000-0000-0000-000000000132','f0250000-0000-0000-0000-000000000102');
    RAISE EXCEPTION 'FN-025: authenticated a appele motif_refus_salle';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$client$;
RESET ROLE;

-- A3 (prod du 01/11/2026) : le titulaire ecarte par l'absence automatique
-- lit « acces_perdu », jamais « pas_encore_ouverte » ; la salle reste ouverte
-- a l'eleve, sans motif.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence, origine)
VALUES ('f0250000-0000-0000-0000-000000000131', 'absence_declaree',
        'f0250000-0000-0000-0000-000000000101', 'f0250000-0000-0000-0000-000000000101',
        'f0250000-0000-0000-0000-0000000001a3', 'auto');
DO $a3$
DECLARE
  v jsonb := public.motif_refus_salle('f0250000-0000-0000-0000-000000000131',
                                      'f0250000-0000-0000-0000-000000000101');
BEGIN
  IF v ->> 'motif' IS DISTINCT FROM 'acces_perdu' THEN
    RAISE EXCEPTION 'A3: titulaire ecarte sans motif acces_perdu (%)', v;
  END IF;
  -- La salle reste ouverte a l'eleve : aucun motif pour lui.
  IF public.motif_refus_salle('f0250000-0000-0000-0000-000000000131',
                              'f0250000-0000-0000-0000-000000000102') IS NOT NULL THEN
    RAISE EXCEPTION 'A3: un motif de refus pour l''eleve, dont la salle reste ouverte';
  END IF;
END;
$a3$;

ROLLBACK;
