-- NOTIF-RETENU (08/11/2026) : la structure de la notification « retenu pour un
-- entretien ». Migrations 20261121000000_notif_retenu_evenement.sql et
-- 20261121000100_notif_retenu_notification.sql.
--
-- La preuve par le GESTE REEL (une admission pose UNE notification, le rejeu et
-- l'admission refusee n'en posent aucune, une notification en echec n'empeche pas
-- l'admission, un seul courriel) est dans scenarios_cand_l2a2_gestes_direction.sql
-- (239 controles) : sans la migration, ce scenario est ROUGE.
--
-- Ici :
--   (a) l'evenement est dans la contrainte, avec ceux d'avant ;
--   (b) la fonction du geste porte la notification, apres le courriel, et sa fiche
--       F86 est a l'empreinte reelle ; elle n'est pas ouverte a anon ;
--   (c) aucun declencheur sur candidatures ne pose cette notification (un seul circuit) ;
--   (d) categorie du push `admissions`, actif par defaut ;
--   (e) la notification n'enfile aucun second courriel (evenement absent de
--       notification_courriel : application seulement) ;
--   (f) fait a connaitre : un compte pending_kyc n'est pas autorise au push.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Chaque controle leve 'NOTIF-RETENU ROUGE : ...' s'il echoue. Tout est annule.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'NOTIF-RETENU ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

SELECT pg_temp.vrai(
  (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check')
    LIKE '%''retenu_entretien''%'
  AND (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check')
    LIKE '%''bienvenue_equipe''%'
  AND (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check')
    LIKE '%''entretien_reserve''%',
  '(a) l''evenement est dans la contrainte, et ceux d''avant y sont encore');

SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::regprocedure),
                    'NOTIF-RETENU (08/11/2026)') > pg_catalog.strpos(
    pg_catalog.pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::regprocedure),
    '''retenu_entretien:'' || p_id::text')
  AND pg_catalog.obj_description('public.admettre_salle_verification(uuid,integer,text)'::regprocedure, 'pg_proc')
      LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(
        'public.admettre_salle_verification(uuid,integer,text)'::regprocedure)) || '%'
  AND pg_catalog.obj_description('public.admettre_salle_verification(uuid,integer,text)'::regprocedure, 'pg_proc')
      LIKE '%NOTIF-RETENU (08/11/2026)%'
  AND NOT pg_catalog.has_function_privilege('anon',
        'public.admettre_salle_verification(uuid,integer,text)', 'EXECUTE'),
  '(b) la notification suit le courriel dans le geste ; fiche F86 a l''empreinte reelle ; pas ouverte a anon');

SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
               WHERE t.tgrelid = 'public.candidatures'::regclass AND NOT t.tgisinternal
                 AND pg_catalog.pg_get_functiondef(t.tgfoid) LIKE '%retenu_entretien%'),
  '(c) aucun declencheur de candidatures ne pose cette notification : un seul circuit');

SELECT pg_temp.vrai(
  (SELECT e.categorie FROM private.push_evenements e WHERE e.evenement = 'retenu_entretien') = 'admissions'
  AND (SELECT e.tag FROM private.push_evenements e WHERE e.evenement = 'retenu_entretien') IS NULL
  AND private.notification_avec_push('retenu_entretien', NULL),
  '(d) push : categorie admissions (que la personne peut couper), actif par defaut');

SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM private.notification_courriel c WHERE c.evenement = 'retenu_entretien')
  AND NOT private.notification_avec_courriel('retenu_entretien', NULL)
  AND NOT private.notification_avec_courriel('retenu_entretien', 'soi'),
  '(e) evenement absent de notification_courriel : application seulement, aucun second courriel');

INSERT INTO auth.users (id, email) VALUES ('0d3e0000-0000-4000-8000-000000000001', 'nr-pending@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES ('0d3e0000-0000-4000-8000-000000000001', 'NR-P1', 'teacher', NULL, 'Candidate', 'Test', 'pending_kyc', 'female');
SELECT pg_temp.vrai(NOT private.push_compte_autorise('0d3e0000-0000-4000-8000-000000000001'),
  '(f) un compte pending_kyc n''est pas autorise au push : la notification reste dans l''application');

ROLLBACK;
