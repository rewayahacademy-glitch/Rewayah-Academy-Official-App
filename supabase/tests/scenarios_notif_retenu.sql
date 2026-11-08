-- NOTIF-RETENU (08/11/2026) : la notification « retenu pour un entretien ».
-- Migrations 20261121000000_notif_retenu_evenement.sql et
-- 20261121000100_notif_retenu_notification.sql.
--
--   (a) une candidature d'enseignant passe de la salle 1 (prequalification) a la
--       salle 2 (verifications) : UNE notification retenu_entretien pour la
--       candidate, destination /attente/entretien, sans parametre ;
--   (b) aucun courriel ne part de cette notification (le courriel du meme nom
--       est celui du geste d'admission, prouve dans scenarios_cand_l2a2) ;
--   (c) aucune notification pour une autre transition, ni pour un autre type de
--       candidature, ni sans compte ;
--   (d) un echec de la notification n'empeche pas l'admission ;
--   (e) la fonction du declencheur n'est executable par personne ; l'evenement
--       est dans la contrainte, avec tous ceux d'avant ; categorie du push
--       `admissions` ;
--   (f) fait a connaitre : un compte pending_kyc n'est pas autorise au push
--       (push_compte_autorise), donc le candidat recoit la notification dans
--       l'application seulement.
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

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('notif-retenu-' || p)::uuid $$;

CREATE FUNCTION pg_temp.nb(p_profil uuid) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.notifications
   WHERE evenement = 'retenu_entretien' AND destinataire = p_profil;
$$;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'notif-retenu-' || x || '@test.invalid'
  FROM unnest(ARRAY['a', 'b', 'c', 'd', 'e']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x), 'NRET-' || pg_catalog.upper(x), 'teacher', NULL, 'Candidate', 'Test', 'pending_kyc', 'female'
  FROM unnest(ARRAY['a', 'b', 'c', 'd', 'e']) AS x;

-- Un type de candidature d'un autre role : le declencheur ne le regarde pas.
INSERT INTO public.candidature_types (code, role_compte) VALUES ('fixture_autre', 'teacher');

INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES
  (pg_temp.id('c-a'), 'enseignant', pg_temp.id('a'), 'female', 'Candidate A', 'prequalification', 'en_examen', 'en_cours', 'lien_public'),
  (pg_temp.id('c-b'), 'fixture_autre', pg_temp.id('b'), 'female', 'Candidate B', 'prequalification', 'en_examen', 'en_cours', 'lien_public'),
  (pg_temp.id('c-c'), 'enseignant', pg_temp.id('c'), 'female', 'Candidate C', 'prequalification', 'en_examen', 'en_cours', 'lien_public'),
  (pg_temp.id('c-d'), 'enseignant', pg_temp.id('d'), 'female', 'Candidate D', 'prequalification', 'en_examen', 'en_cours', 'lien_public');

-- (a) La candidate A est admise en salle 2.
UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier'
 WHERE id = pg_temp.id('c-a');
SELECT pg_temp.vrai(pg_temp.nb(pg_temp.id('a')) = 1
  AND (SELECT count(*) FROM public.notifications n
        WHERE n.evenement = 'retenu_entretien' AND n.destinataire = pg_temp.id('a')
          AND n.destination = '/attente/entretien' AND n.params = '{}'::jsonb
          AND n.foyer_id IS NULL) = 1,
  '(a) admise en salle 2 : une notification retenu_entretien, destination /attente/entretien, sans parametre');

-- Un passage suivant de la meme candidature (salle 2 vers confirmee) n'en pose pas.
UPDATE public.candidatures SET etape = 'confirmee', etat = NULL WHERE id = pg_temp.id('c-a');
SELECT pg_temp.vrai(pg_temp.nb(pg_temp.id('a')) = 1,
  '(c) salle 2 vers confirmee : aucune notification de plus');

-- (b) Aucun courriel retenu_entretien ne vient de cette notification.
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants o WHERE o.modele = 'retenu_entretien') = 0
  AND NOT private.notification_avec_courriel('retenu_entretien', NULL)
  AND NOT private.notification_avec_courriel('retenu_entretien', 'soi'),
  '(b) la notification ne declenche aucun second courriel (evenement absent de notification_courriel : application seulement ; le courriel est celui du geste)');

-- (c) Un autre type de candidature : rien. Sans compte : rien (etape recue).
UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier'
 WHERE id = pg_temp.id('c-b');
SELECT pg_temp.vrai(pg_temp.nb(pg_temp.id('b')) = 0,
  '(c) un autre type de candidature : aucune notification');
UPDATE public.candidatures SET etat = 'a_completer' WHERE id = pg_temp.id('c-c');
SELECT pg_temp.vrai(pg_temp.nb(pg_temp.id('c')) = 0,
  '(c) un changement d''etat sans changement d''etape : aucune notification');

-- (d) Un echec de la notification n'empeche pas l'admission.
CREATE FUNCTION pg_temp.refuser() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'echec simule'; END $$;
CREATE TRIGGER zz_echec BEFORE INSERT ON public.notifications
  FOR EACH ROW WHEN (new.evenement = 'retenu_entretien') EXECUTE FUNCTION pg_temp.refuser();
UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier'
 WHERE id = pg_temp.id('c-d');
SELECT pg_temp.vrai(
  (SELECT etape FROM public.candidatures WHERE id = pg_temp.id('c-d')) = 'verifications'
  AND pg_temp.nb(pg_temp.id('d')) = 0,
  '(d) notification en echec : l''admission est faite, aucune notification posee');
DROP TRIGGER zz_echec ON public.notifications;

-- (e) Droits, contrainte, categorie du push.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.notification_retenu_entretien()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.notification_retenu_entretien()', 'EXECUTE'),
  '(e) la fonction du declencheur n''est executable par aucun client');
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
  '(e) l''evenement est dans la contrainte, et ceux d''avant y sont encore');
SELECT pg_temp.vrai(
  (SELECT e.categorie FROM private.push_evenements e WHERE e.evenement = 'retenu_entretien') = 'admissions'
  AND (SELECT e.tag FROM private.push_evenements e WHERE e.evenement = 'retenu_entretien') IS NULL
  AND private.notification_avec_push('retenu_entretien', NULL),
  '(e) push : categorie admissions (que la personne peut couper), actif par defaut');

-- (f) Le candidat est pending_kyc : pas de push sur l'appareil, notification dans l'application.
SELECT pg_temp.vrai(NOT private.push_compte_autorise(pg_temp.id('a')),
  '(f) un compte pending_kyc n''est pas autorise au push : la notification reste dans l''application');

DO $fin$
BEGIN
  RAISE NOTICE 'NOTIF-RETENU : controles verts';
END $fin$;

ROLLBACK;
