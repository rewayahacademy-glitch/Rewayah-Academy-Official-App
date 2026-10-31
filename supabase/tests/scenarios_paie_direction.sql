-- B2.5 PAIE-DIRECTION (02/11/2026) : le releve mensuel de la paie des
-- enseignants, lu par la direction et la comptabilite. Migration
-- 20261102200000, puis PAIE-REMPLACANT, migration 20261102300000.
--   1. classe d'enfants de 3 eleves, 2 presents sur une seance d'une heure :
--      montant = 2 x taux horaire enfant LU EN BASE (politique en vigueur) ;
--   2. une seance annulee n'est jamais comptee ;
--   3. une seance sans eleve present est tenue, a paie nulle ;
--   4. une panne sans decision est « en attente », jamais payee ;
--   5. seance remplacee (regle du directeur, systeme des astreintes : « Paie
--      seance affectee au remplacant ») : la paie va a la remplacante, le
--      titulaire ne la voit plus, le total du mois ne change pas (aucune
--      double paie) ;
--   6. le detail par seance redit les memes montants, filtre sur
--      l'enseignant effectif ; les revenus de chaque enseignante aussi ;
--   7. la comptabilite lit ; un enseignant, un eleve, un tuteur et anon ne
--      lisent rien ;
--   8. rien n'est ecrit par la lecture ; la lecture brute reste au serveur.
-- Le scenario met la v2 en vigueur ce mois-ci ; tout est annule a la fin.
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

-- Vrai si l'appel est refuse (42501).
CREATE FUNCTION pg_temp.refuse(p_sql text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN false;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN true;
END $$;

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.mois(),
  pg_temp.refuse(text) TO authenticated, anon;

-- Le taux horaire enfant de la politique en vigueur ce mois-ci, lu en base.
CREATE TEMP TABLE taux AS
SELECT (private.fac_politique_au(pg_temp.mois())).taux_eleve_heure_enfant_mineur AS enfant,
       (private.fac_politique_au(pg_temp.mois())).devise AS devise;
GRANT SELECT ON taux TO authenticated, anon;
SELECT pg_temp.vrai((SELECT enfant FROM taux) > 0, 'une politique par eleve present est en vigueur');

-- ------------------------------------------------------------------
-- Fixtures : direction, comptabilite, deux enseignantes, un tuteur, trois
-- eleves dans une classe d'enfants ; cinq seances dans le mois.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('d2500000-0000-4000-8000-0000000000' || x)::uuid, 'pd-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','c1','b1','b2','d1','e1','e2','e3']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('d2500000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('d2500000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role IN ('student', 'guardian') THEN 'd2500000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, x.nom, (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PD-ADM-01','admin','Direction','PD'),
   ('c1','PD-CPT-01','accountant','Compta','PD'),
   ('b1','PD-ENS-01','teacher','Maryam','Bah'),
   ('b2','PD-ENS-02','teacher','Hawa','Sow'),
   ('d1','PD-TUT-01','guardian','Amina','PD'),
   ('e1','PD-ELV-01','student','Yasmine','PD'),
   ('e2','PD-ELV-02','student','Nour','PD'),
   ('e3','PD-ELV-03','student','Safa','PD')) AS x(id, mat, role, prenom, nom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('d2500000-0000-4000-8000-0000000000' || x)::uuid, 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('d2500000-0000-4000-8000-000000000c01','d2500000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour PD',1,9,'Europe/Paris');

-- s1 : 60 min, 2 presents sur 3 ; s2 : annulee ; s3 : personne ; s4 : panne
-- sans decision ; s5 : remplacee par b2, 1 present.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('d2500000-0000-4000-8000-00000000050' || x.s)::uuid, 'd2500000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours' + interval '60 minutes',
       'planned', 'd2500000-0000-4000-8000-000000000c01'
  FROM unnest(ARRAY['1','2','3','4','5']) AS x(s);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT ('d2500000-0000-4000-8000-00000000050' || x.s)::uuid, ('d2500000-0000-4000-8000-0000000000' || x.e)::uuid,
       'student'::public.participant_role
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('2','e1'),('2','e2'),('2','e3'),
               ('3','e1'),('3','e2'),('3','e3'),('4','e1'),('5','e1'),('5','e2')) AS x(s, e);
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT ('d2500000-0000-4000-8000-00000000050' || x.s)::uuid, ('d2500000-0000-4000-8000-0000000000' || x.e)::uuid,
       'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','e1'),('1','e2'),('2','e1'),('4','e1'),('5','e1')) AS x(s, e)
  JOIN public.sessions s ON s.id = ('d2500000-0000-4000-8000-00000000050' || x.s)::uuid;

ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight'
 WHERE id::text LIKE 'd2500000-0000-4000-8000-00000000050%' AND id <> 'd2500000-0000-4000-8000-000000000502';
UPDATE public.sessions SET status = 'in_progress'
 WHERE id::text LIKE 'd2500000-0000-4000-8000-00000000050%' AND id <> 'd2500000-0000-4000-8000-000000000502';
UPDATE public.sessions s
   SET finance_started_at = s.started_at,
       finance_ended_at = s.started_at + x.tenues * interval '1 minute',
       status = x.fin::public.session_status
  FROM (VALUES ('1',60,'ended'),('3',60,'ended'),('4',20,'tech_failure'),('5',60,'ended')) AS x(s, tenues, fin)
 WHERE s.id = ('d2500000-0000-4000-8000-00000000050' || x.s)::uuid;
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
-- s2 annulee par l'academie.
UPDATE public.sessions SET status = 'canceled' WHERE id = 'd2500000-0000-4000-8000-000000000502';
-- La remplacante designee par la direction pour s5 (B-09).
INSERT INTO public.remplacements_seance(session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
                                        acteur_id, cle_idempotence)
VALUES ('d2500000-0000-4000-8000-000000000505', 'remplacement_designe_admin',
        'd2500000-0000-4000-8000-0000000000b1', 'd2500000-0000-4000-8000-0000000000b2',
        'd2500000-0000-4000-8000-0000000000a1', gen_random_uuid());

-- CAHIER-HEBDOMADAIRE (20261103000000) : le cahier de la semaine, depose
-- sur s1, couvre les trois eleves pour toutes les seances de la semaine ;
-- sans lui la paie serait en attente (verifie par scenarios_cahier_hebdomadaire).
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES ('d2500000-0000-4000-8000-000000000501', 'pd-cahier-semaine',
        '{"version": 1, "eleves": [{"student_id": "d2500000-0000-4000-8000-0000000000e1"},
          {"student_id": "d2500000-0000-4000-8000-0000000000e2"},
          {"student_id": "d2500000-0000-4000-8000-0000000000e3"}]}'::jsonb,
        'd2500000-0000-4000-8000-0000000000b1');

CREATE TEMP TABLE avant AS SELECT count(*) AS n FROM public.tresorerie_mouvements;
GRANT SELECT ON avant TO authenticated;
-- Ce que la tresorerie a ecrit pour les seances du scenario, sans enseignant.
CREATE TEMP TABLE ecrit AS
SELECT coalesce(sum(m.montant_minor), 0)::bigint AS n FROM public.tresorerie_mouvements m
 WHERE m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
   AND m.source_id LIKE 'd2500000-0000-4000-8000-00000000050%';
GRANT SELECT ON ecrit TO authenticated;

-- ------------------------------------------------------------------
-- 1 a 5. Le releve de la direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE r AS SELECT public.releve_paie_mensuel(NULL) AS j;
CREATE TEMP TABLE b1 AS
SELECT e FROM r, jsonb_array_elements(r.j -> 'enseignants') e
 WHERE e ->> 'enseignantId' = 'd2500000-0000-4000-8000-0000000000b1';

CREATE TEMP TABLE b2 AS
SELECT e FROM r, jsonb_array_elements(r.j -> 'enseignants') e
 WHERE e ->> 'enseignantId' = 'd2500000-0000-4000-8000-0000000000b2';

SELECT pg_temp.vrai((SELECT e #>> '{montant,mineur}' FROM b1)::bigint = 2 * (SELECT enfant FROM taux),
  'releve : la titulaire est payee de s1 seule (2 presents x 1 h = 2 x taux enfant lu en base)');
SELECT pg_temp.vrai((SELECT e #>> '{montant,devise}' FROM b1) = (SELECT devise FROM taux)
  AND (SELECT j ->> 'devise' FROM r) = (SELECT devise FROM taux),
  'releve : devise de la politique');
SELECT pg_temp.vrai((SELECT (e ->> 'seancesTenues')::int FROM b1) = 2,
  'releve : deux seances tenues par la titulaire (s1, s3 sans eleve present), ni l''annulee ni la remplacee');
SELECT pg_temp.vrai((SELECT (e ->> 'seancesEnAttente')::int FROM b1) = 1,
  'releve : la panne sans decision est en attente');
SELECT pg_temp.vrai((SELECT (e ->> 'minutes')::int FROM b1) = 120
  AND (SELECT (e ->> 'minutesEleves')::int FROM b1) = 120,
  'releve : 120 minutes tenues, 120 minutes-eleves (2 x 60 + 0)');
SELECT pg_temp.vrai((SELECT e ->> 'prenom' FROM b1) = 'Maryam' AND (SELECT e ->> 'nom' FROM b1) = 'Bah'
  AND (SELECT e -> 'classes' FROM b1) = '["An-Nour PD"]'::jsonb,
  'releve : prenom, nom et Classes de l''enseignante');
SELECT pg_temp.vrai((SELECT e #>> '{montant,mineur}' FROM b2)::bigint = (SELECT enfant FROM taux)
  AND (SELECT (e ->> 'seancesTenues')::int FROM b2) = 1
  AND (SELECT (e ->> 'minutes')::int FROM b2) = 60
  AND (SELECT e ->> 'prenom' FROM b2) = 'Hawa'
  AND (SELECT e -> 'classes' FROM b2) = '["An-Nour PD"]'::jsonb,
  'remplacement : la remplacante est payee de s5 (1 present x 1 h), dans la Classe de la titulaire');
SELECT pg_temp.vrai((SELECT e #>> '{montant,mineur}' FROM b1)::bigint
                    + (SELECT e #>> '{montant,mineur}' FROM b2)::bigint = 3 * (SELECT enfant FROM taux)
  AND (SELECT e #>> '{montant,mineur}' FROM b1)::bigint
      + (SELECT e #>> '{montant,mineur}' FROM b2)::bigint = (SELECT n FROM ecrit),
  'remplacement : le total ne change pas, egal a ce que la tresorerie a ecrit (aucune double paie)');
SELECT pg_temp.vrai((SELECT (j #>> '{total,mineur}')::bigint FROM r)
                    = (SELECT coalesce(sum((e #>> '{montant,mineur}')::bigint), 0)
                         FROM r, jsonb_array_elements(r.j -> 'enseignants') e),
  'releve : le total est la somme des lignes, chaque seance comptee une fois');

-- 6. Le detail par seance
CREATE TEMP TABLE d AS
SELECT public.releve_paie_seances(pg_temp.mois(), 'd2500000-0000-4000-8000-0000000000b1') AS j;
SELECT pg_temp.vrai(jsonb_array_length((SELECT j -> 'seances' FROM d)) = 3,
  'detail : trois seances chez la titulaire (ni l''annulee, ni la remplacee)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM d, jsonb_array_elements(d.j -> 'seances') s
                                 WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000505'),
  'remplacement : la titulaire ne voit plus la seance remplacee');
SELECT pg_temp.vrai((SELECT (s #>> '{montant,mineur}')::bigint FROM d, jsonb_array_elements(d.j -> 'seances') s
                      WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000501') = 2 * (SELECT enfant FROM taux)
  AND (SELECT (s ->> 'elevesPresents')::int * 10 + (s ->> 'elevesInscrits')::int
         FROM d, jsonb_array_elements(d.j -> 'seances') s
        WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000501') = 23,
  'detail : classe de 3, 2 presents sur une heure = 2 x taux enfant');
SELECT pg_temp.vrai((SELECT (s #>> '{montant,mineur}')::bigint FROM d, jsonb_array_elements(d.j -> 'seances') s
                      WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000503') = 0,
  'detail : seance sans eleve present a paie nulle');
SELECT pg_temp.vrai((SELECT s -> 'montant' FROM d, jsonb_array_elements(d.j -> 'seances') s
                      WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000504') = 'null'::jsonb
  AND (SELECT (s ->> 'enAttente')::boolean FROM d, jsonb_array_elements(d.j -> 'seances') s
        WHERE s ->> 'seanceId' = 'd2500000-0000-4000-8000-000000000504'),
  'detail : la panne est en attente, sans montant');
SELECT pg_temp.vrai((SELECT j #>> '{total,mineur}' FROM d) = (SELECT e #>> '{montant,mineur}' FROM b1),
  'detail : meme total que le releve');
CREATE TEMP TABLE d2 AS
SELECT public.releve_paie_seances(pg_temp.mois(), 'd2500000-0000-4000-8000-0000000000b2') AS j;
SELECT pg_temp.vrai(jsonb_array_length((SELECT j -> 'seances' FROM d2)) = 1
  AND (SELECT s ->> 'seanceId' FROM d2, jsonb_array_elements(d2.j -> 'seances') s)
      = 'd2500000-0000-4000-8000-000000000505'
  AND (SELECT (s #>> '{montant,mineur}')::bigint FROM d2, jsonb_array_elements(d2.j -> 'seances') s)
      = (SELECT enfant FROM taux)
  AND (SELECT j #>> '{total,mineur}' FROM d2) = (SELECT e #>> '{montant,mineur}' FROM b2),
  'detail : la remplacante voit s5 et sa paie, meme total que le releve');
RESET ROLE;

-- 6 bis. Les revenus de chaque enseignante (`mes_revenus_enseignant`)
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000b2', 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE rv2 AS SELECT public.mes_revenus_enseignant(NULL) AS j;
SELECT pg_temp.vrai((SELECT (j #>> '{totalEstime,mineur}')::bigint FROM rv2) = (SELECT enfant FROM taux)
  AND jsonb_array_length((SELECT j -> 'classes' FROM rv2)) = 1
  AND (SELECT (j #>> '{classes,0,enRemplacement}')::boolean FROM rv2)
  AND (SELECT (j #>> '{classes,0,minutesAssurees}')::int FROM rv2) = 60,
  'revenus : la remplacante voit sa paie de s5, marquee en remplacement');
SELECT pg_temp.vrai(public.mes_revenus_mois_disponibles() ->> 0 = to_char(pg_temp.mois(), 'YYYY-MM-DD'),
  'revenus : le mois de la seance remplacee est disponible pour la remplacante');
RESET ROLE;
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE rv1 AS SELECT public.mes_revenus_enseignant(NULL) AS j;
SELECT pg_temp.vrai((SELECT (j #>> '{totalEstime,mineur}')::bigint FROM rv1) = 2 * (SELECT enfant FROM taux)
  AND NOT (SELECT (j #>> '{classes,0,enRemplacement}')::boolean FROM rv1)
  AND (SELECT (j #>> '{classes,0,minutesAssurees}')::int FROM rv1) = 60,
  'revenus : la titulaire ne voit plus la paie de la seance remplacee (s1 seule ; s3 sans eleve present n''ecrit aucune paie)');
RESET ROLE;

-- 7. Qui lit
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000c1', 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.releve_paie_mensuel(NULL) -> 'enseignants') >= 1,
  'la comptabilite lit le releve');
RESET ROLE;
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse('SELECT public.releve_paie_mensuel(NULL)')
  AND pg_temp.refuse($q$SELECT public.releve_paie_seances(now()::date, 'd2500000-0000-4000-8000-0000000000b1')$q$),
  'un enseignant ne lit rien, pas meme son propre detail');
RESET ROLE;
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000e1', 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse('SELECT public.releve_paie_mensuel(NULL)'), 'un eleve ne lit rien');
RESET ROLE;
SELECT pg_temp.qui('d2500000-0000-4000-8000-0000000000d1', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refuse('SELECT public.releve_paie_mensuel(NULL)'), 'un tuteur ne lit rien');
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.releve_paie_mensuel(date)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.releve_paie_seances(date,uuid)', 'EXECUTE'),
  'anon n''execute pas le releve');

-- 8. Rien n'est ecrit, la lecture brute reste au serveur
SELECT pg_temp.vrai((SELECT count(*) FROM public.tresorerie_mouvements) = (SELECT n FROM avant),
  'la lecture n''ecrit aucun mouvement');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.pai_releve_seances(timestamptz,timestamptz)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pai_releve_autorise()', 'EXECUTE'),
  'droits : les fonctions privees restent fermees');

\o
ROLLBACK;
