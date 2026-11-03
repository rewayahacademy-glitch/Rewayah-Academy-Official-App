-- FN-SERVEUR (03/11/2026, migration 20261107500000) : trois lectures serveur.
--   FN-003 : une seance close tard (fin financiere bien apres la fin prevue)
--            ne compte plus la presence au-dela de la fin prevue et de la
--            grace ; la paie ne change pas.
--   FN-019 : le remplacant voit la seance qu'il assure dans
--            mes_seances_enseignant_v et lit cahier_semaine_depose ; un
--            enseignant etranger, non.
--   FN-106 : mes_seances_v ne rend plus a la famille ni a l'eleve une seance
--            d'une Classe quittee ou cloturee avant son debut ; les seances
--            d'avant le depart restent ; une seance annulee de la Classe
--            actuelle reste ; enseignant, direction et controleur inchanges.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'ROUGE : ...'.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'sub', p_id, 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('f5000000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Les seances de mes_seances_v visibles par l'appelant, parmi les fixtures.
CREATE FUNCTION pg_temp.vues() RETURNS text LANGUAGE sql AS
  $$ SELECT coalesce(string_agg(DISTINCT right(v.session_id::text, 2), ',' ORDER BY right(v.session_id::text, 2)), '')
       FROM public.mes_seances_v v WHERE v.session_id::text LIKE 'f5000000%' $$;
-- Les seances de mes_seances_enseignant_v visibles par l'appelant.
CREATE FUNCTION pg_temp.vues_ens() RETURNS text LANGUAGE sql AS
  $$ SELECT coalesce(string_agg(right(v.session_id::text, 2), ',' ORDER BY v.session_id), '')
       FROM public.mes_seances_enseignant_v v WHERE v.session_id::text LIKE 'f5000000%' $$;
CREATE FUNCTION pg_temp.cahier_lu(p_seance uuid) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.cahier_semaine_depose(p_seance);
  RETURN true;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN false;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.vues(), pg_temp.vues_ens(), pg_temp.cahier_lu(uuid) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures (dates passees : la materialisation des Classes ne les touche pas)
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'fns-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','d1','b1','b2','b3','d2','e1']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role IN ('student', 'guardian') THEN pg_temp.u('f1') END,
       x.prenom, 'FNS', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','FNS-ADM-01','admin','Direction'),
   ('d1','FNS-CTL-01','controller','Controle'),
   ('b1','FNS-ENS-01','teacher','Ancienne'),
   ('b2','FNS-ENS-02','teacher','Remplacante'),
   ('b3','FNS-ENS-03','teacher','Nouvelle'),
   ('d2','FNS-TUT-01','guardian','Tutrice'),
   ('e1','FNS-ELV-01','student','Eleve')) AS x(id, mat, role, prenom);
UPDATE public.households SET primary_guardian_id = pg_temp.u('d2') WHERE id = pg_temp.u('f1');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
VALUES (pg_temp.u('e1'), 'minor'::public.student_type, 'standard'::public.interface_mode);
-- c1 : l'ancienne Classe (b1), cloturee le 20/10 ; c2 : la nouvelle (b3).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'Ancienne FNS', 1, 18, 'Europe/Paris'),
 (pg_temp.u('c2'), pg_temp.u('b3'), 'enfant', 6, 'Nouvelle FNS', 3, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at, left_at, left_by, left_reason) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), '2026-10-01 10:00+00', '2026-10-20 10:00+00', pg_temp.u('a1'), 'changement de Classe'),
 (pg_temp.u('c2'), pg_temp.u('e1'), '2026-10-20 10:00+00', NULL, NULL, NULL);
-- Seances :
--   71 : c1, le 13/10, avant le depart (historique) ;
--   72 : c1, le 27/10, apres le depart, annulee (le defaut FN-106) ;
--   73 : c2, le 28/10, annulee (Classe actuelle : reste visible) ;
--   74 : c2, le 21/10, tenue, remplacee par b2 (FN-019), close tard (FN-003).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 (pg_temp.u('71'), pg_temp.u('b1'), '2026-10-13 16:00+00', '2026-10-13 17:00+00', 'planned', pg_temp.u('c1')),
 (pg_temp.u('72'), pg_temp.u('b1'), '2026-10-27 17:00+00', '2026-10-27 18:00+00', 'canceled', pg_temp.u('c1')),
 (pg_temp.u('73'), pg_temp.u('b3'), '2026-10-28 17:00+00', '2026-10-28 18:00+00', 'canceled', pg_temp.u('c2')),
 (pg_temp.u('74'), pg_temp.u('b3'), '2026-10-21 16:00+00', '2026-10-21 17:00+00', 'planned', pg_temp.u('c2'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(x), pg_temp.u('e1'), 'student'::public.participant_role
  FROM unnest(ARRAY['71','72','73','74']) AS x;
UPDATE public.groupes SET ended_at = '2026-10-20 10:00+00', ended_by = pg_temp.u('a1'), end_reason = 'Classe cloturee' WHERE id = pg_temp.u('c1');

-- 74 : absence declaree par b3, remplacement pris par b2.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, cree_le)
VALUES
  (pg_temp.u('74'), 'absence_declaree', pg_temp.u('b3'), NULL, pg_temp.u('b3'),
   pg_temp.u('91'), pg_catalog.clock_timestamp()),
  (pg_temp.u('74'), 'remplacement_pris', pg_temp.u('b3'), pg_temp.u('b2'), pg_temp.u('b2'),
   pg_temp.u('92'), pg_catalog.clock_timestamp() + interval '1 millisecond');
-- La remplacante entre a l'heure et ne sort jamais ; la seance est close
-- (fin financiere) trente heures apres sa fin prevue.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
VALUES (pg_temp.u('74'), pg_temp.u('b2'), 'joined', '2026-10-21 16:00+00', 'livekit_webhook');
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = pg_temp.u('74');
UPDATE public.sessions SET status = 'in_progress' WHERE id = pg_temp.u('74');
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = ended_at + interval '30 hours',
       status = 'ended' WHERE id = pg_temp.u('74');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- FN-003 : la presence bornee a la fin prevue plus la grace
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT t.minutes FROM private.presence_temps_reel(pg_temp.u('74'), pg_temp.u('b2')) t)
    = 60 + public.app_config_int('grace_after_end_minutes', 15),
  'FN-003 : entree sans sortie, close 30 h plus tard : 60 minutes plus la grace, plus 1 860');
SELECT pg_temp.vrai(private.pai_minutes_enseignant(pg_temp.u('74'))
    = 60 + public.app_config_int('grace_after_end_minutes', 15),
  'FN-003 : les minutes de paie de l''enseignant effectif suivent la meme borne');
-- La paie ne change pas : elle est deja plafonnee a la duree prevue ;
-- scenarios_ses_cloture_auto.sql (cas 4, montant paye d'une seance close
-- automatiquement) le prouve avec cette migration installee.

-- ------------------------------------------------------------------
-- FN-019 : le remplacant
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SELECT pg_temp.vrai(pg_temp.vues_ens() = '74', 'FN-019 : la remplacante voit la seance qu''elle assure');
SELECT pg_temp.vrai(pg_temp.cahier_lu(pg_temp.u('74')), 'FN-019 : la remplacante lit l''etat du cahier de la semaine');
SELECT pg_temp.vrai((SELECT v.groupe_libelle FROM public.mes_seances_enseignant_v v
                      WHERE v.session_id = pg_temp.u('74')) = 'Nouvelle FNS',
  'FN-019 : la ligne de la remplacante porte le nom de la Classe');
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SELECT pg_temp.vrai(pg_temp.vues_ens() LIKE '%74%' AND pg_temp.cahier_lu(pg_temp.u('74')),
  'FN-019 : la titulaire garde la seance remplacee');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SELECT pg_temp.vrai(pg_temp.vues_ens() NOT LIKE '%74%' AND NOT pg_temp.cahier_lu(pg_temp.u('74')),
  'FN-019 : une enseignante etrangere a la seance ne la voit pas et ne lit pas son cahier');

-- ------------------------------------------------------------------
-- FN-106 : la famille et l'eleve
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('d2'), 'guardian', pg_temp.u('f1'));
SELECT pg_temp.vrai(pg_temp.vues() = '71,73,74',
  'FN-106 : la tutrice voit 71 (avant le depart), 73 (annulee, Classe actuelle), 74 ; plus 72');
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SELECT pg_temp.vrai(pg_temp.vues() = '71,73,74', 'FN-106 : l''eleve, de meme');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SELECT pg_temp.vrai(pg_temp.vues() = '71,72', 'FN-106 : l''enseignante de l''ancienne Classe garde ses seances');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SELECT pg_temp.vrai(pg_temp.vues() = '71,72,73,74', 'FN-106 : la direction voit tout');
SELECT pg_temp.qui(pg_temp.u('d1'), 'controller');
SELECT pg_temp.vrai(pg_temp.vues() = '71,72,73,74', 'FN-106 : le controleur voit tout');
RESET ROLE;

\o
SELECT 'FN-SERVEUR VERT' AS resultat;
ROLLBACK;
