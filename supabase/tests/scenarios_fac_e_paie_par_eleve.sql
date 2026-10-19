-- FAC-E-02 (18/10/2026) : la paie de l'enseignant par eleve present et par
-- heure. Migration 20261018130000.
--   1. classe d'enfants, 60 min prevues, 50 tenues (>= 45) : 3 presents
--      (deux arrivees mesurees, une presence corrigee par la direction ; une
--      absence excusee ne compte pas) : 0,95 x 3 x 1 h = 2,85 USD ;
--   2. classe d'adultes, 90 min prevues, 60 tenues (< 70) : 2 presents payes
--      sur les 60 minutes tenues : 1,00 x 2 x 1 h = 2,00 USD ;
--   3. seance sans eleve present : rien n'est ecrit ;
--   4. panne technique sans decision : la seance part a la direction ;
--   5. mes_revenus_enseignant : total 4,85 USD, fourchette de paie horaire
--      d'une classe 2,85 a 6,00 USD ;
--   6. le calcul reste au serveur.
-- Le scenario met la v2 en vigueur ce mois-ci ; tout est annule a la fin.
\o /dev/null
BEGIN;

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
      WHERE m.source_type = 'prestation' AND m.source_id = 'fe200000-0000-4000-8000-00000000050' || p_seance
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.mois()
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : une enseignante, une classe d'enfants (e1-e4), une classe
-- d'adultes (e5-e7), quatre seances dans le mois.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('fe200000-0000-4000-8000-0000000000' || x)::uuid, 'fe2-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('fe200000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('fe200000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN 'fe200000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'FE2', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('a1','FE2-ADM-01','admin','Direction'),
   ('b1','FE2-ENS-01','teacher','Maryam'),
   ('e1','FE2-ELV-01','student','Yasmine'),
   ('e2','FE2-ELV-02','student','Nour'),
   ('e3','FE2-ELV-03','student','Safa'),
   ('e4','FE2-ELV-04','student','Hawa'),
   ('e5','FE2-ELV-05','student','Aicha'),
   ('e6','FE2-ELV-06','student','Khadija'),
   ('e7','FE2-ELV-07','student','Zeynab')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('fe200000-0000-4000-8000-0000000000' || x)::uuid,
       (CASE WHEN x IN ('e5','e6','e7') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fe200000-0000-4000-8000-000000000c01','fe200000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FE2',1,9,'Europe/Paris'),
 ('fe200000-0000-4000-8000-000000000c02','fe200000-0000-4000-8000-0000000000b1','adulte',6,'Al-Huda FE2',3,20,'Europe/Paris');

-- s1 enfants 60 min ; s2 adultes 90 min ; s3 enfants, personne ; s4 enfants, panne.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('fe200000-0000-4000-8000-00000000050' || x.s)::uuid, 'fe200000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours' + x.duree * interval '1 minute',
       'planned', ('fe200000-0000-4000-8000-000000000c0' || x.g)::uuid
  FROM (VALUES ('1','1',60),('2','2',90),('3','1',60),('4','1',60)) AS x(s, g, duree);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT ('fe200000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe200000-0000-4000-8000-0000000000' || x.e)::uuid,
       'student'::public.participant_role
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('1','e4'),
               ('2','e5'),('2','e6'),('2','e7'),
               ('3','e1'),('3','e2'),('4','e1')) AS x(s, e);
-- Arrivees mesurees par la salle : s1 e1, e2, e3 ; s2 e5, e6 ; s4 e1.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT ('fe200000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe200000-0000-4000-8000-0000000000' || x.e)::uuid,
       'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('2','e5'),('2','e6'),('4','e1')) AS x(s, e)
  JOIN public.sessions s ON s.id = ('fe200000-0000-4000-8000-00000000050' || x.s)::uuid;
-- Corrections de la direction : e3 excusee malgre son arrivee, e4 presente.
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par) VALUES
 ('fe200000-0000-4000-8000-000000000501','fe200000-0000-4000-8000-0000000000e3','excusee','absence prevenue','fe200000-0000-4000-8000-0000000000a1'),
 ('fe200000-0000-4000-8000-000000000501','fe200000-0000-4000-8000-0000000000e4','corrigee_manuel','camera en panne','fe200000-0000-4000-8000-0000000000a1');

-- Cloture : durees tenues fixees a la main (l'horodatage serveur est coupe le
-- temps du scenario), puis passage a « ended » qui declenche la paie.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight'
 WHERE id::text LIKE 'fe200000-0000-4000-8000-00000000050%';
UPDATE public.sessions SET status = 'in_progress'
 WHERE id::text LIKE 'fe200000-0000-4000-8000-00000000050%';
UPDATE public.sessions s
   SET finance_started_at = s.started_at,
       finance_ended_at = s.started_at + x.tenues * interval '1 minute',
       status = x.fin::public.session_status
  FROM (VALUES ('1',50,'ended'),('2',60,'ended'),('3',60,'ended'),('4',20,'tech_failure')) AS x(s, tenues, fin)
 WHERE s.id = ('fe200000-0000-4000-8000-00000000050' || x.s)::uuid;
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1 a 4. Paie des seances
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.pai_eleves_presents('fe200000-0000-4000-8000-000000000501') = 3,
  'presents : deux arrivees + une presence corrigee, une absence excusee l''emporte');
SELECT pg_temp.vrai(pg_temp.paie('1') = 285, 'enfants : 0,95 x 3 x 1 h = 2,85 USD (50 min tenues sur 60, seance due en entier)');
SELECT pg_temp.vrai(pg_temp.paie('2') = 200, 'adultes : 60 min tenues sur 90 (< 70) : 1,00 x 2 x 1 h = 2,00 USD');
SELECT pg_temp.vrai((SELECT m.montant_minor FROM public.tresorerie_mouvements m
                      WHERE m.source_id = 'fe200000-0000-4000-8000-000000000501'
                        AND m.coffre = 'fonds_clients_engages' AND m.sens = 'sortie') = 285,
  'contrepartie ecrite dans fonds_clients_engages');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements m
                                 WHERE m.source_id = 'fe200000-0000-4000-8000-000000000503'),
  'seance sans eleve present : rien n''est ecrit');
SELECT pg_temp.vrai(public.remuneration_due_seance('fe200000-0000-4000-8000-000000000503') = 0,
  'seance sans eleve present : paie nulle');
SELECT pg_temp.vrai(pg_temp.paie('4') IS NULL AND EXISTS (
  SELECT 1 FROM public.tresorerie_a_reprendre q
   WHERE q.source_id = 'fe200000-0000-4000-8000-000000000504' AND q.raison = 'duree_indeterminee'),
  'panne technique sans decision : la seance part a la direction');
SELECT pg_temp.vrai(public.remuneration_due_seance('fe200000-0000-4000-8000-000000000501') = 285
  AND (SELECT count(*) FROM public.tresorerie_mouvements m
        WHERE m.source_id = 'fe200000-0000-4000-8000-000000000501') = 2,
  'rejouer la paie n''ecrit rien de plus');

-- ------------------------------------------------------------------
-- 5. Revenus de l'enseignante
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe200000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.mes_revenus_enseignant(NULL) #>> '{totalEstime,mineur}' = '485',
  'revenus : 2,85 + 2,00 = 4,85 USD');
SELECT pg_temp.vrai(public.mes_revenus_enseignant(NULL) #>> '{regle,base,mineur}' = '285'
  AND public.mes_revenus_enseignant(NULL) #>> '{regle,plafond,mineur}' = '600',
  'revenus : paie horaire d''une classe de 2,85 (3 enfants) a 6,00 USD (6 adultes)');
SELECT pg_temp.vrai((SELECT (c #>> '{tauxHoraireEffectif,mineur}')::bigint
                       FROM jsonb_array_elements(public.mes_revenus_enseignant(NULL) -> 'classes') c
                      WHERE c ->> 'classe' = 'Al-Huda FE2') = 200,
  'revenus : taux effectif de la classe d''adultes (2,00 USD de l''heure), sans borne de l''ancien taux');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. Le calcul reste au serveur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'public.remuneration_due_seance(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pai_due_seance(uuid,public.politiques_commerciales)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pai_eleves_presents(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.remuneration_due_seance(uuid)', 'EXECUTE'),
  'droits : aucun client ne calcule la paie');

\o
ROLLBACK;
