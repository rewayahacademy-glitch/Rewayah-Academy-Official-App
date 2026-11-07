-- REVENUS-VERITE point 5 « Autres revenus » (06/11/2026), migration
-- 20261110210000_autres_revenus.sql. Rouge sur main (aucune table ni fonction
-- d'autres revenus), vert avec la migration.
--   1. la direction attribue une mission, une aide Internet et une prime ;
--      la meme cle ne cree rien de plus ; un mois ancien est refuse ;
--   2. ni l'enseignant, ni la comptabilite n'attribuent ; la comptabilite lit
--      (peutAttribuer faux) ;
--   3. l'enseignant les lit dans mes_revenus_enseignant (aide Internet a
--      part) ; une annulation les retire, sans effacement ;
--   4. le releve de la direction les compte dans le montant a payer, et
--      montre un enseignant qui n'a qu'une prime ;
--   5. droits : la table est fermee aux clients.
-- Donnees du scenario REVENUS-VERITE (prefixe fe4), plus une comptable et une
-- seconde enseignante. Tout est annule a la fin.
\o /dev/null
BEGIN;
-- Les notifications de seance (20261027120000) sont un declencheur differe :
-- immediat ici, sinon ALTER TABLE sessions refuse les evenements en attente.
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role))::text;
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

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
-- La paie ecrite pour une seance (nul si rien n'est ecrit).
CREATE FUNCTION pg_temp.paie(p_seance text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT m.montant_minor FROM public.tresorerie_mouvements m
      WHERE m.source_type = 'prestation' AND m.source_id = 'fe400000-0000-4000-8000-00000000050' || p_seance
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.mois()
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : une enseignante, une classe d'enfants (e1-e4), une classe
-- d'adultes (e5-e7), quatre seances dans le mois.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('fe400000-0000-4000-8000-0000000000' || x)::uuid, 'ar1-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('fe400000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('fe400000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN 'fe400000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'AR1', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('a1','AR1-ADM-01','admin','Direction'),
   ('b1','AR1-ENS-01','teacher','Maryam'),
   ('e1','AR1-ELV-01','student','Yasmine'),
   ('e2','AR1-ELV-02','student','Nour'),
   ('e3','AR1-ELV-03','student','Safa'),
   ('e4','AR1-ELV-04','student','Hawa'),
   ('e5','AR1-ELV-05','student','Aicha'),
   ('e6','AR1-ELV-06','student','Khadija'),
   ('e7','AR1-ELV-07','student','Zeynab')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('fe400000-0000-4000-8000-0000000000' || x)::uuid,
       (CASE WHEN x IN ('e5','e6','e7') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fe400000-0000-4000-8000-000000000c01','fe400000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour AR1',1,9,'Europe/Paris'),
 ('fe400000-0000-4000-8000-000000000c02','fe400000-0000-4000-8000-0000000000b1','adulte',6,'Al-Huda AR1',3,20,'Europe/Paris');

-- s1 enfants 60 min ; s2 adultes 90 min ; s3 enfants, personne ; s4 enfants, panne.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid, 'fe400000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours' + x.duree * interval '1 minute',
       'planned', ('fe400000-0000-4000-8000-000000000c0' || x.g)::uuid
  FROM (VALUES ('1','1',60),('2','2',90),('3','1',60),('4','1',60)) AS x(s, g, duree);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe400000-0000-4000-8000-0000000000' || x.e)::uuid,
       'student'::public.participant_role
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('1','e4'),
               ('2','e5'),('2','e6'),('2','e7'),
               ('3','e1'),('3','e2'),('4','e1')) AS x(s, e);
-- Arrivees mesurees par la salle : s1 e1, e2, e3 ; s2 e5, e6 ; s4 e1.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe400000-0000-4000-8000-0000000000' || x.e)::uuid,
       'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('2','e5'),('2','e6'),('4','e1')) AS x(s, e)
  JOIN public.sessions s ON s.id = ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid;
-- PRESENCE-MINUTES (20261102900000) : la duree payee est celle ou
-- l'enseignante etait connectee (s1 50 min, s2 60, s3 60 ; s4 en panne).
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, 'fe400000-0000-4000-8000-0000000000b1', x.t::public.session_event_type,
       s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','joined',0),('1','left',50),('2','joined',0),('2','left',60),
               ('3','joined',0),('3','left',60)) AS x(s, t, m)
  JOIN public.sessions s ON s.id = ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid;
-- Corrections de la direction : e3 excusee malgre son arrivee, e4 presente.
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par) VALUES
 ('fe400000-0000-4000-8000-000000000501','fe400000-0000-4000-8000-0000000000e3','excusee','absence prevenue','fe400000-0000-4000-8000-0000000000a1'),
 ('fe400000-0000-4000-8000-000000000501','fe400000-0000-4000-8000-0000000000e4','corrigee_manuel','camera en panne','fe400000-0000-4000-8000-0000000000a1');

-- Cloture : durees tenues fixees a la main (l'horodatage serveur est coupe le
-- temps du scenario), puis passage a « ended » qui declenche la paie.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight'
 WHERE id::text LIKE 'fe400000-0000-4000-8000-00000000050%';
UPDATE public.sessions SET status = 'in_progress'
 WHERE id::text LIKE 'fe400000-0000-4000-8000-00000000050%';
UPDATE public.sessions s
   SET finance_started_at = s.started_at,
       finance_ended_at = s.started_at + x.tenues * interval '1 minute',
       status = x.fin::public.session_status
  FROM (VALUES ('1',50,'ended'),('2',60,'ended'),('3',60,'ended'),('4',20,'tech_failure')) AS x(s, tenues, fin)
 WHERE s.id = ('fe400000-0000-4000-8000-00000000050' || x.s)::uuid;
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------

-- s5 : enfants, 60 min prevues, 30 tenues (< 45) ; e1 et e2 presents :
-- 1,99 x 2 x 0,5 h = 1,99 USD, a partager en 1,00 + 0,99.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('fe400000-0000-4000-8000-000000000505', 'fe400000-0000-4000-8000-0000000000b1',
        pg_temp.mois() + interval '12 days', pg_temp.mois() + interval '12 days' + interval '60 minutes',
        'planned', 'fe400000-0000-4000-8000-000000000c01');
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT 'fe400000-0000-4000-8000-000000000505', ('fe400000-0000-4000-8000-0000000000' || x)::uuid, 'student'
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT 'fe400000-0000-4000-8000-000000000505', ('fe400000-0000-4000-8000-0000000000' || x.p)::uuid,
       x.t::public.session_event_type, pg_temp.mois() + interval '12 days' + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('b1','joined',0),('b1','left',30),('e1','joined',1),('e2','joined',1)) AS x(p, t, m);
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = 'fe400000-0000-4000-8000-000000000505';
UPDATE public.sessions SET status = 'in_progress' WHERE id = 'fe400000-0000-4000-8000-000000000505';
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = started_at + interval '30 minutes',
       status = 'ended' WHERE id = 'fe400000-0000-4000-8000-000000000505';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- Le cahier de la semaine de la Classe d'adultes est depose (s2) ; celui de
-- la Classe d'enfants manque : le versement de s1 et s5 attend le cahier.
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES ('fe400000-0000-4000-8000-000000000502', 'ar1-cahier-s2',
        jsonb_build_object('version', 1, 'session_id', 'fe400000-0000-4000-8000-000000000502', 'eleves',
          jsonb_build_array(jsonb_build_object('student_id', 'fe400000-0000-4000-8000-0000000000e5', 'confirme', true),
                            jsonb_build_object('student_id', 'fe400000-0000-4000-8000-0000000000e6', 'confirme', true),
                            jsonb_build_object('student_id', 'fe400000-0000-4000-8000-0000000000e7', 'confirme', true))),
        'fe400000-0000-4000-8000-0000000000b1');

SELECT pg_temp.vrai(pg_temp.paie('1') = 597 AND pg_temp.paie('2') = 314 AND pg_temp.paie('5') = 199,
  'paie ecrite par le serveur : 5,97 ; 3,14 ; 1,99 USD');


INSERT INTO auth.users(id, email) VALUES
  ('fe400000-0000-4000-8000-0000000000c9', 'ar1-c9@test.invalid'),
  ('fe400000-0000-4000-8000-0000000000b2', 'ar1-b2@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('fe400000-0000-4000-8000-0000000000c9', 'AR1-CPT-01', 'accountant', 'Comptable', 'AR1', 'active', 'female'),
  ('fe400000-0000-4000-8000-0000000000b2', 'AR1-ENS-02', 'teacher', 'Salma', 'AR1', 'provisional_active', 'female');

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_code THEN RAISE NOTICE 'OK %', p_label; RETURN; END IF;
    RAISE EXCEPTION 'ROUGE : % (code % au lieu de %)', p_label, SQLSTATE, p_code;
  END;
  RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- 1. La direction attribue
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT set_config('test.m1', public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'mission', 'Remplacement du 12', 2500, 'ar1-cle-mission-1') ->> 'id', true);
SELECT pg_temp.vrai(public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'aide_internet', 'Aide Internet', 1000, 'ar1-cle-internet-1') ->> 'deja' = 'false',
  '1 : aide Internet attribuee');
SELECT set_config('test.p1', public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois() + 14, 'prime', 'Prime de fin de trimestre', 500, 'ar1-cle-prime-1') ->> 'id', true);
SELECT pg_temp.vrai(public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'mission', 'Remplacement du 12', 2500, 'ar1-cle-mission-1') ->> 'deja' = 'true',
  '1 : la meme cle (double appui) ne cree rien de plus');
SELECT pg_temp.vrai(public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b2',
  pg_temp.mois(), 'prime', 'Prime d''accueil', 700, 'ar1-cle-prime-b2') ->> 'deja' = 'false',
  '1 : une prime pour une enseignante sans seance');
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  (pg_temp.mois() - interval '3 months')::date, 'prime', 'Ancienne', 100, 'ar1-cle-ancienne')$q$,
  '22023', '1 : un mois ancien est refuse');
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000e1',
  pg_temp.mois(), 'prime', 'Eleve', 100, 'ar1-cle-eleve-1')$q$,
  '22023', '1 : un eleve n''est pas un enseignant');
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'bonus', 'Inconnu', 100, 'ar1-cle-nature-1')$q$,
  '23514', '1 : une nature inconnue est refusee');
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'prime', 'Negative', -5, 'ar1-cle-negatif-1')$q$,
  '23514', '1 : un montant nul ou negatif est refuse');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.revenus_enseignant_autres
                      WHERE enseignant_id = 'fe400000-0000-4000-8000-0000000000b1') = 3,
  '1 : trois lignes pour la premiere enseignante');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'autre_revenu_attribue'
                      AND row_id = current_setting('test.m1')) = 1,
  '1 : l''attribution est journalisee');

-- ------------------------------------------------------------------
-- 2. Qui attribue, qui lit
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'prime', 'Moi-meme', 100, 'ar1-cle-soi-1')$q$, '42501', '2 : l''enseignant n''attribue pas');
SELECT pg_temp.refus($q$SELECT public.autres_revenus_lister('fe400000-0000-4000-8000-0000000000b1', pg_temp.mois())$q$,
  '42501', '2 : l''enseignant ne lit pas la liste de la direction');
RESET ROLE;
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000c9', 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($q$SELECT public.autre_revenu_attribuer('fe400000-0000-4000-8000-0000000000b1',
  pg_temp.mois(), 'prime', 'Comptable', 100, 'ar1-cle-cpt-1')$q$, '42501', '2 : la comptabilite n''attribue pas');
SELECT pg_temp.vrai(NOT (public.autres_revenus_lister('fe400000-0000-4000-8000-0000000000b1', pg_temp.mois())
                         ->> 'peutAttribuer')::boolean
  AND jsonb_array_length(public.autres_revenus_lister('fe400000-0000-4000-8000-0000000000b1', pg_temp.mois())
                         -> 'lignes') = 3,
  '2 : la comptabilite lit les trois lignes, sans pouvoir attribuer');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. L'enseignant les lit ; une annulation les retire
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.mes_revenus_enseignant(NULL) -> 'autres') = 3
  AND public.mes_revenus_enseignant(NULL) #>> '{totalAutres,mineur}' = '4000'
  AND public.mes_revenus_enseignant(NULL) #>> '{allocationInternet,mineur}' = '1000'
  AND public.mes_revenus_enseignant(NULL) #>> '{totalEstime,mineur}' = '1110',
  '3 : trois autres revenus, 40,00 USD dont 10,00 d''aide Internet ; la paie des seances est inchangee');
RESET ROLE;
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.autre_revenu_annuler(current_setting('test.p1')::uuid) ->> 'deja' = 'false'
  AND public.autre_revenu_annuler(current_setting('test.p1')::uuid) ->> 'deja' = 'true',
  '3 : la prime est annulee, une seconde fois ne change rien');
RESET ROLE;
SELECT pg_temp.vrai((SELECT annule_le IS NOT NULL FROM public.revenus_enseignant_autres
                      WHERE id = current_setting('test.p1')::uuid),
  '3 : la ligne annulee reste en base');
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.mes_revenus_enseignant(NULL) #>> '{totalAutres,mineur}' = '3500'
  AND jsonb_array_length(public.mes_revenus_enseignant(NULL) -> 'autres') = 2,
  '3 : apres annulation, 35,00 USD');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Le releve de la direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe400000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.releve_paie_seances(pg_temp.mois(), 'fe400000-0000-4000-8000-0000000000b1')
                      #>> '{total,mineur}' = '3814'
  AND public.releve_paie_seances(pg_temp.mois(), 'fe400000-0000-4000-8000-0000000000b1')
                      #>> '{totalAutres,mineur}' = '3500'
  AND jsonb_array_length(public.releve_paie_seances(pg_temp.mois(), 'fe400000-0000-4000-8000-0000000000b1')
                      -> 'autres') = 2,
  '4 : detail : 3,14 de seances versables (cahier de la Classe d''adultes depose ; celui des enfants manque) + 35,00 d''autres revenus = 38,14 USD a payer');
SELECT pg_temp.vrai((SELECT e #>> '{montant,mineur}' FROM jsonb_array_elements(
                       public.releve_paie_mensuel(pg_temp.mois()) -> 'enseignants') e
                      WHERE e ->> 'enseignantId' = 'fe400000-0000-4000-8000-0000000000b1') = '3814'
  AND (SELECT e #>> '{montant,mineur}' FROM jsonb_array_elements(
                       public.releve_paie_mensuel(pg_temp.mois()) -> 'enseignants') e
                      WHERE e ->> 'enseignantId' = 'fe400000-0000-4000-8000-0000000000b2') = '700',
  '4 : releve mensuel : 38,14 USD ; l''enseignante sans seance figure avec sa prime de 7,00 USD');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_table_privilege('authenticated', 'public.revenus_enseignant_autres', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.revenus_enseignant_autres', 'DELETE')
  AND NOT has_table_privilege('anon', 'public.revenus_enseignant_autres', 'INSERT')
  AND NOT has_function_privilege('anon', 'public.autre_revenu_attribuer(uuid,date,text,text,bigint,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.autres_revenus_du(uuid,date)', 'EXECUTE')
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.revenus_enseignant_autres'::regclass),
  '5 : table fermee aux clients, RLS activee, fonctions privees fermees');
-- Garde-cap (06/11, 22:19 UTC) : le commentaire F86 des deux releves
-- remplaces porte l'empreinte de la fonction INSTALLEE.
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM unnest(ARRAY['public.releve_paie_mensuel(date)'::regprocedure,
                               'public.releve_paie_seances(date,uuid)'::regprocedure]) f
     WHERE coalesce(obj_description(f, 'pg_proc'), '')
           NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%'),
  '5 : commentaire F86 des releves = md5(pg_get_functiondef) de la fonction installee');

\o
ROLLBACK;
