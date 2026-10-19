-- SES-CLOTURE-AUTO (18/10/2026) : cloture automatique des seances echues.
-- Migration 20261018180000.
--   1. seance en cours, enseignante arrivee, 2 eleves presents, fin depassee :
--      `ended`, paie due ecrite (1,99 x 2 x 1 h = 3,98 USD), journal automatique ;
--   2. seance planifiee sans enseignante : `teacher_absent`, journal ;
--   3. seance dans la marge : non touchee ; puis marge reduite : close ;
--   4. seance planifiee dont l'enseignante est arrivee : `ended` en passant
--      par preflight et in_progress ; duree non mesuree : file de reprise ;
--   5. seance en cours sans enseignante arrivee : `tech_failure`, file de reprise ;
--   6. seance deja finie : intacte ; second passage : rien ne change ;
--   7. reglage invalide : refus ; droits : direction aal2 seule, aucun client
--      sur la fonction privee.
-- Le scenario met la v2 en vigueur ; tout est annule a la fin.
\o /dev/null
BEGIN;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales SET date_effet = (current_date - 60) WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales SET date_effet = (current_date - 3) WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', p_aal, 'app_metadata',
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

CREATE FUNCTION pg_temp.sid(p_n text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('5e500000-0000-4000-8000-00000000050' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.statut(p_n text) RETURNS text LANGUAGE sql AS
  $$ SELECT s.status::text FROM public.sessions s WHERE s.id = pg_temp.sid(p_n) $$;
CREATE FUNCTION pg_temp.paie(p_n text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT m.montant_minor FROM public.tresorerie_mouvements m
      WHERE m.source_type = 'prestation' AND m.source_id = pg_temp.sid(p_n)::text
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
CREATE FUNCTION pg_temp.journal(p_n text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT a.payload FROM public.audit_logs a
      WHERE a.action = 'seance_cloturee_auto' AND a.row_id = pg_temp.sid(p_n)::text
      ORDER BY a.id DESC LIMIT 1 $$;
CREATE FUNCTION pg_temp.nb_journal() RETURNS bigint LANGUAGE sql AS
  $$ SELECT count(*) FROM public.audit_logs a WHERE a.action = 'seance_cloturee_auto' $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.sid(text)
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : une administratrice, une enseignante, une classe d'enfants (e1, e2).
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('5e500000-0000-4000-8000-0000000000' || x)::uuid, 'ses-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('5e500000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('5e500000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN '5e500000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'SES', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('a1','SES-ADM-01','admin','Direction'),
   ('b1','SES-ENS-01','teacher','Maryam'),
   ('e1','SES-ELV-01','student','Yasmine'),
   ('e2','SES-ELV-02','student','Nour')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('5e500000-0000-4000-8000-0000000000' || x)::uuid, 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('5e500000-0000-4000-8000-000000000c01','5e500000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour SES',1,9,'Europe/Paris');

-- s1 en cours, tenue ; s2 planifiee, personne ; s3 en cours, dans la marge ;
-- s4 planifiee, enseignante arrivee ; s5 en cours, enseignante absente de la salle ;
-- s6 deja finie. Les fins prevues sont depassees d'un jour ou plus,
-- sauf s3 (10 minutes avant).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.sid(x.s), '5e500000-0000-4000-8000-0000000000b1',
       now() - x.fin_il_y_a - interval '60 minutes', now() - x.fin_il_y_a,
       'planned', '5e500000-0000-4000-8000-000000000c01'
  FROM (VALUES ('1', interval '25 hours'), ('2', interval '27 hours'), ('3', interval '10 minutes'),
               ('4', interval '29 hours'), ('5', interval '31 hours'), ('6', interval '33 hours')) AS x(s, fin_il_y_a);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.sid(x.s), ('5e500000-0000-4000-8000-0000000000' || x.e)::uuid, 'student'::public.participant_role
  FROM (VALUES ('1','e1'),('1','e2'),('3','e1'),('4','e1'),('5','e1')) AS x(s, e);
-- Arrivees mesurees : enseignante en s1, s3, s4 ; eleves en s1 (e1, e2), s3, s4 (e1), s5 (e1).
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.sid(x.s), ('5e500000-0000-4000-8000-0000000000' || x.p)::uuid,
       'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','b1'),('1','e1'),('1','e2'),('3','b1'),('3','e1'),
               ('4','b1'),('4','e1'),('5','e1')) AS x(s, p)
  JOIN public.sessions s ON s.id = pg_temp.sid(x.s);

-- Etats de depart par la machine d'etats : s1, s3, s5 en cours ; s6 finie.
UPDATE public.sessions SET status = 'preflight' WHERE id IN (pg_temp.sid('1'), pg_temp.sid('3'), pg_temp.sid('5'), pg_temp.sid('6'));
UPDATE public.sessions SET status = 'in_progress' WHERE id IN (pg_temp.sid('1'), pg_temp.sid('3'), pg_temp.sid('5'), pg_temp.sid('6'));
-- Debut financier d'une journee en arriere (l'enseignante a bien tenu la seance).
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions s SET finance_started_at = s.started_at
 WHERE s.id IN (pg_temp.sid('1'), pg_temp.sid('3'), pg_temp.sid('5'), pg_temp.sid('6'));
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'ended' WHERE id = pg_temp.sid('6');

SELECT pg_temp.vrai(public.get_config('seances.cloture_auto_marge_minutes') = '30'::jsonb,
  'reglage : marge de 30 minutes posee par la migration');

-- ------------------------------------------------------------------
-- Premier passage
-- ------------------------------------------------------------------
CREATE TEMP TABLE bilan1 AS SELECT private.ses_cloturer_seances_echues(now()) AS r;
GRANT SELECT ON bilan1 TO authenticated;

SELECT pg_temp.vrai(pg_temp.statut('1') = 'ended', 'seance tenue : ended');
SELECT pg_temp.vrai(pg_temp.paie('1') = 398, 'seance tenue : paie due 1,99 x 2 x 1 h = 3,98 USD');
SELECT pg_temp.vrai((pg_temp.journal('1') ->> 'automatique')::boolean
  AND pg_temp.journal('1') ->> 'statut_avant' = 'in_progress'
  AND pg_temp.journal('1') ->> 'statut_apres' = 'ended'
  AND pg_temp.journal('1') ->> 'declencheur' = 'planification',
  'seance tenue : journal marque automatique');
SELECT pg_temp.vrai(pg_temp.statut('2') = 'teacher_absent', 'seance sans enseignante : teacher_absent');
SELECT pg_temp.vrai(pg_temp.paie('2') IS NULL AND (pg_temp.journal('2') ->> 'enseignant_present')::boolean = false,
  'seance sans enseignante : rien a payer, journal');
SELECT pg_temp.vrai(pg_temp.statut('3') = 'in_progress' AND pg_temp.journal('3') IS NULL,
  'seance dans la marge : non touchee');
SELECT pg_temp.vrai(pg_temp.statut('4') = 'ended', 'enseignante arrivee, seance jamais lancee : ended par les etapes');
SELECT pg_temp.vrai(pg_temp.paie('4') IS NULL AND EXISTS (
  SELECT 1 FROM public.tresorerie_a_reprendre q
   WHERE q.source_id = pg_temp.sid('4')::text AND q.raison = 'duree_indeterminee' AND q.traite_le IS NULL)
  AND (pg_temp.journal('4') ->> 'duree_a_fixer_par_la_direction')::boolean,
  'duree non mesuree : la seance part a la direction');
SELECT pg_temp.vrai(pg_temp.statut('5') = 'tech_failure' AND EXISTS (
  SELECT 1 FROM public.tresorerie_a_reprendre q
   WHERE q.source_id = pg_temp.sid('5')::text AND q.raison = 'duree_indeterminee'),
  'en cours sans enseignante arrivee : tech_failure, file de reprise');
SELECT pg_temp.vrai(pg_temp.statut('6') = 'ended' AND pg_temp.journal('6') IS NULL,
  'seance deja finie : intacte');
SELECT pg_temp.vrai((SELECT r FROM bilan1) = '{"ended":2,"teacher_absent":1,"tech_failure":1,"erreurs":0}'::jsonb,
  'bilan du premier passage');

-- ------------------------------------------------------------------
-- Idempotence
-- ------------------------------------------------------------------
CREATE TEMP TABLE avant AS SELECT pg_temp.nb_journal() AS j,
  (SELECT count(*) FROM public.tresorerie_mouvements WHERE source_type = 'prestation') AS m;
SELECT pg_temp.vrai(private.ses_cloturer_seances_echues(now())
  = '{"ended":0,"teacher_absent":0,"tech_failure":0,"erreurs":0}'::jsonb,
  'second passage : rien a faire');
SELECT pg_temp.vrai(pg_temp.nb_journal() = (SELECT j FROM avant)
  AND (SELECT count(*) FROM public.tresorerie_mouvements WHERE source_type = 'prestation') = (SELECT m FROM avant)
  AND pg_temp.paie('1') = 398,
  'second passage : ni journal ni paie en double');

-- ------------------------------------------------------------------
-- Marge reglable : a 5 minutes, s3 (fin il y a 10 minutes) est close
-- ------------------------------------------------------------------
UPDATE public.app_config SET value = '5'::jsonb WHERE key = 'seances.cloture_auto_marge_minutes';
SELECT pg_temp.vrai((private.ses_cloturer_seances_echues(now()) ->> 'ended')::int = 1
  AND pg_temp.statut('3') = 'ended' AND pg_temp.paie('3') = 199,
  'marge reduite a 5 minutes : s3 close, paie 1,99 x 1 x 1 h');
UPDATE public.app_config SET value = '"abc"'::jsonb WHERE key = 'seances.cloture_auto_marge_minutes';
DO $$
BEGIN
  BEGIN
    PERFORM private.ses_cloturer_seances_echues(now());
    RAISE EXCEPTION 'ROUGE : un reglage invalide aurait du etre refuse';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    RAISE NOTICE 'OK reglage de marge invalide : refus';
  END;
END $$;
UPDATE public.app_config SET value = '30'::jsonb WHERE key = 'seances.cloture_auto_marge_minutes';

-- ------------------------------------------------------------------
-- Droits : direction aal2 seule
-- ------------------------------------------------------------------
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.sid('7'), '5e500000-0000-4000-8000-0000000000b1',
        now() - interval '3 days', now() - interval '3 days' + interval '1 hour',
        'planned', '5e500000-0000-4000-8000-000000000c01');

SELECT pg_temp.qui('5e500000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  BEGIN
    PERFORM public.ses_cloturer_seances_echues_maintenant();
    RAISE EXCEPTION 'ROUGE : une enseignante ne doit pas cloturer';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK droits : enseignante refusee';
  END;
END $$;
RESET ROLE;

SELECT pg_temp.qui('5e500000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  BEGIN
    PERFORM public.ses_cloturer_seances_echues_maintenant();
    RAISE EXCEPTION 'ROUGE : une direction sans double authentification ne doit pas cloturer';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK droits : direction aal1 refusee';
  END;
END $$;
RESET ROLE;

SELECT pg_temp.qui('5e500000-0000-4000-8000-0000000000a1', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.ses_cloturer_seances_echues_maintenant() ->> 'teacher_absent')::int = 1,
  'droits : direction aal2 cloture la seance oubliee');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.statut('7') = 'teacher_absent'
  AND pg_temp.journal('7') ->> 'declencheur' = 'direction',
  'declenchement manuel : journal avec declencheur direction');

SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.ses_cloturer_seances_echues(timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.ses_cloturer_seances_echues(timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.ses_cloturer_seances_echues_maintenant()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.ses_cloturer_seances_echues_maintenant()', 'EXECUTE'),
  'droits : la fonction privee reste au serveur, l''enveloppe est fermee a anon');

\o
ROLLBACK;
