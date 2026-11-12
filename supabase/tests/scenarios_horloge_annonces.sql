-- HORLOGE-ET-LIEU, partie A : l'annonce du changement d'heure (decision H3 ;
-- migration 20261123940100_horloge_annonces.sql).
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque controle
-- reussi ecrit une ligne "HLA OK" ; un echec leve 'HLA ROUGE : ...'.
--
-- Independant de la date d'execution : les annonces sont calculees a des
-- instants de reference FIXES (mars 2027) ; l'apercu de l'ecran, qui suit
-- l'horloge reelle, n'est controle que par ce qui ne depend pas de la saison.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d2000000-0000-4000-8000-0000000000e1', 'hla-e1@example.test'),
  ('d2000000-0000-4000-8000-000000000b01', 'hla-g1@example.test'),
  ('d2000000-0000-4000-8000-000000000b02', 'hla-g2@example.test'),
  ('d2000000-0000-4000-8000-000000000b03', 'hla-g3@example.test'),
  ('d2000000-0000-4000-8000-000000000b04', 'hla-g4@example.test'),
  ('d2000000-0000-4000-8000-000000000c01', 'hla-s1@example.test'),
  ('d2000000-0000-4000-8000-000000000c02', 'hla-s2@example.test'),
  ('d2000000-0000-4000-8000-000000000c03', 'hla-s3@example.test'),
  ('d2000000-0000-4000-8000-000000000c04', 'hla-s4@example.test'),
  ('d2000000-0000-4000-8000-000000000c05', 'hla-s5@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('d2000000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
  ('d2000000-0000-4000-8000-0000000000f2', 'America/Toronto'),
  ('d2000000-0000-4000-8000-0000000000f3', 'Asia/Kolkata'),
  ('d2000000-0000-4000-8000-0000000000f4', 'Asia/Riyadh');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id, access_until)
VALUES
  ('d2000000-0000-4000-8000-0000000000e1', 'HLATEACHER000E01', 'teacher', 'Fixture', 'Enseignante', 'provisional_active', 'female', NULL, NULL),
  ('d2000000-0000-4000-8000-000000000b01', 'HLAGUARD00000B01', 'guardian', 'Fixture', 'Tuteur1', 'active', 'male', 'd2000000-0000-4000-8000-0000000000f1', NULL),
  ('d2000000-0000-4000-8000-000000000b02', 'HLAGUARD00000B02', 'guardian', 'Fixture', 'Tuteur2', 'active', 'male', 'd2000000-0000-4000-8000-0000000000f2', NULL),
  ('d2000000-0000-4000-8000-000000000b03', 'HLAGUARD00000B03', 'guardian', 'Fixture', 'Tuteur3', 'active', 'male', 'd2000000-0000-4000-8000-0000000000f3', NULL),
  ('d2000000-0000-4000-8000-000000000b04', 'HLAGUARD00000B04', 'guardian', 'Fixture', 'Tuteur4', 'active', 'male', 'd2000000-0000-4000-8000-0000000000f4', NULL),
  ('d2000000-0000-4000-8000-000000000c01', 'HLASTUD000000C01', 'student', 'Fixture', 'Eleve1', 'active', 'female', 'd2000000-0000-4000-8000-0000000000f1', NULL),
  ('d2000000-0000-4000-8000-000000000c02', 'HLASTUD000000C02', 'student', 'Fixture', 'Eleve2', 'active', 'female', 'd2000000-0000-4000-8000-0000000000f2', NULL),
  ('d2000000-0000-4000-8000-000000000c03', 'HLASTUD000000C03', 'student', 'Fixture', 'Eleve3', 'active', 'female', 'd2000000-0000-4000-8000-0000000000f3', NULL),
  ('d2000000-0000-4000-8000-000000000c04', 'HLASTUD000000C04', 'student', 'Fixture', 'Eleve4', 'active', 'female', 'd2000000-0000-4000-8000-0000000000f4', NULL),
  ('d2000000-0000-4000-8000-000000000c05', 'HLASTUD000000C05', 'student', 'Fixture', 'Enfant5', 'active', 'male', 'd2000000-0000-4000-8000-0000000000f1', NULL);
UPDATE public.households SET primary_guardian_id = ('d2000000-0000-4000-8000-000000000b0' || right(id::text, 1))::uuid
 WHERE id::text LIKE 'd2000000-0000-4000-8000-0000000000f%';

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES ('d2000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- L'enseignante est disponible toute la semaine, comme celle de la production.
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT 'd2000000-0000-4000-8000-0000000000e1'::uuid, j, h, 'Europe/Paris'
  FROM pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(0, 23) AS h;

-- Deux classes a l'heure de La Mecque (aucune seance : seules comptent les
-- creneaux) : adultes mercredi 21 h et jeudi 20 h ; enfants vendredi 21 h.
UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
VALUES
  ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-0000000000e1', 'active', 'adulte', 6,
   'HLA classe adultes', 3, 21, 'Asia/Riyadh', 'indetermine', pg_catalog.now() - interval '40 days'),
  ('d2000000-0000-4000-8000-0000000000a2', 'd2000000-0000-4000-8000-0000000000e1', 'active', 'enfant', 5,
   'HLA classe enfants', 5, 21, 'Asia/Riyadh', 'indetermine', pg_catalog.now() - interval '40 days');
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
VALUES ('d2000000-0000-4000-8000-0000000000a1', 4, 20);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-000000000c01'),
  ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-000000000c02'),
  ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-000000000c03'),
  ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-000000000c04'),
  ('d2000000-0000-4000-8000-0000000000a2', 'd2000000-0000-4000-8000-000000000c05');
-- Les notifications d'installation des fixtures parlent maintenant, puis sont
-- vieillies et effacees de la comparaison : on ne compte que les annonces.
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
CREATE TEMP TABLE hla_avant AS SELECT id FROM public.notifications;

-- =====================================================================
-- (1) Le calcul pur : l'heure locale d'un cours avant et apres
-- =====================================================================
DO $c1$
DECLARE
  v record;
BEGIN
  -- Paris : mercredi 21 h a La Mecque = 19 h, puis 20 h a partir du 28/03/2027.
  SELECT * INTO v FROM private.changement_heure_cours(
    'Europe/Paris', 'Asia/Riyadh', 3, 21, '2027-03-01 00:00:00+00');
  IF v.heure_avant IS DISTINCT FROM '19:00' OR v.heure_apres IS DISTINCT FROM '20:00'
     OR v.jour_avant <> 3 OR v.jour_apres <> 3
     OR v.date_changement IS DISTINCT FROM '2027-03-28'
     OR v.transition IS DISTINCT FROM '2027-03-28 01:00:00+00'::timestamptz THEN
    RAISE EXCEPTION 'HLA ROUGE : Paris mercredi 21 h : %', pg_catalog.to_json(v);
  END IF;
  -- Toronto : 13 h, puis 14 h a partir du 14/03/2027 (une autre date que Paris).
  SELECT * INTO v FROM private.changement_heure_cours(
    'America/Toronto', 'Asia/Riyadh', 3, 21, '2027-03-01 00:00:00+00');
  IF v.heure_avant IS DISTINCT FROM '13:00' OR v.heure_apres IS DISTINCT FROM '14:00'
     OR v.date_changement IS DISTINCT FROM '2027-03-14' THEN
    RAISE EXCEPTION 'HLA ROUGE : Toronto mercredi 21 h : %', pg_catalog.to_json(v);
  END IF;
  -- Le jour change aussi : lundi 01 h a La Mecque = dimanche 23 h a Paris,
  -- puis lundi 00 h.
  SELECT * INTO v FROM private.changement_heure_cours(
    'Europe/Paris', 'Asia/Riyadh', 1, 1, '2027-03-01 00:00:00+00');
  IF v.jour_avant <> 7 OR v.heure_avant <> '23:00' OR v.jour_apres <> 1 OR v.heure_apres <> '00:00' THEN
    RAISE EXCEPTION 'HLA ROUGE : le jour change : %', pg_catalog.to_json(v);
  END IF;
  -- Delhi, Riyad : jamais de changement d'heure, aucune annonce.
  IF EXISTS (SELECT 1 FROM private.changement_heure_cours('Asia/Kolkata', 'Asia/Riyadh', 3, 21, '2027-03-01 00:00:00+00'))
     OR EXISTS (SELECT 1 FROM private.changement_heure_cours('Asia/Riyadh', 'Asia/Riyadh', 3, 21, '2027-03-01 00:00:00+00')) THEN
    RAISE EXCEPTION 'HLA ROUGE : une annonce pour un fuseau sans changement d''heure';
  END IF;
  RAISE NOTICE 'HLA OK : Paris 19 h puis 20 h (28/03/2027), Toronto 13 h puis 14 h (14/03/2027), le jour qui change, Delhi et Riyad sans annonce';
END
$c1$;

-- =====================================================================
-- (2) L'annonce a 14 jours : tuteurs, adulte, enseignante ; jamais l'enfant
-- =====================================================================
DO $c2$
DECLARE
  v_n integer;
  v_p jsonb;
BEGIN
  -- 14/03/2027 06:00 UTC : Paris est a 14 jours moins 5 h de son changement ;
  -- Toronto est a une heure du sien (donc la veille).
  v_n := private.annoncer_changements_heure('2027-03-14 06:00:00+00');
  -- Classe adultes : enseignante, eleve de Paris et son tuteur, eleve de Toronto et
  -- son tuteur ; classe enfants : enseignante, tuteur de Paris (jamais l'enfant).
  IF v_n <> 7 THEN
    RAISE EXCEPTION 'HLA ROUGE : % annonces au lieu de 7 : %', v_n,
      (SELECT pg_catalog.json_agg(pg_catalog.json_build_object('d', right(n.destinataire::text, 4), 'g', right((n.params ->> 'groupe_id'), 4), 'p', n.params ->> 'palier'))
         FROM public.notifications n WHERE n.id NOT IN (SELECT id FROM hla_avant));
  END IF;
  IF EXISTS (SELECT 1 FROM public.notifications n
              WHERE n.id NOT IN (SELECT id FROM hla_avant)
                AND n.destinataire = 'd2000000-0000-4000-8000-000000000c05') THEN
    RAISE EXCEPTION 'HLA ROUGE : l''enfant (mineur) a ete prevenu';
  END IF;
  IF EXISTS (SELECT 1 FROM public.notifications n
              WHERE n.id NOT IN (SELECT id FROM hla_avant)
                AND n.destinataire IN ('d2000000-0000-4000-8000-000000000c03', 'd2000000-0000-4000-8000-000000000c04',
                                       'd2000000-0000-4000-8000-000000000b03', 'd2000000-0000-4000-8000-000000000b04')) THEN
    RAISE EXCEPTION 'HLA ROUGE : une annonce pour Delhi ou Riyad, qui n''ont pas de changement d''heure';
  END IF;
  -- Paris : 14 jours avant (j14) ; Toronto : la veille (j1).
  IF NOT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.id NOT IN (SELECT id FROM hla_avant)
                    AND n.destinataire = 'd2000000-0000-4000-8000-000000000b01'
                    AND n.params ->> 'groupe_id' = 'd2000000-0000-4000-8000-0000000000a1'
                    AND n.params ->> 'palier' = 'j14')
     OR NOT EXISTS (SELECT 1 FROM public.notifications n
                     WHERE n.id NOT IN (SELECT id FROM hla_avant)
                       AND n.destinataire = 'd2000000-0000-4000-8000-000000000b02'
                       AND n.params ->> 'palier' = 'j1') THEN
    RAISE EXCEPTION 'HLA ROUGE : mauvais palier (Paris j14, Toronto j1)';
  END IF;
  -- Le texte : l'heure exacte avant et apres, le jour du changement, les deux
  -- creneaux de la classe adultes.
  SELECT n.params INTO v_p FROM public.notifications n
   WHERE n.id NOT IN (SELECT id FROM hla_avant)
     AND n.destinataire = 'd2000000-0000-4000-8000-000000000b01'
     AND n.params ->> 'groupe_id' = 'd2000000-0000-4000-8000-0000000000a1';
  IF v_p ->> 'date_changement' <> '2027-03-28'
     OR v_p ->> 'fuseau' <> 'Europe/Paris'
     OR v_p ->> 'motif' <> 'changement_heure'
     OR pg_catalog.jsonb_array_length(v_p -> 'changements') <> 2
     OR NOT (v_p -> 'changements') @> '[{"jour_avant": 3, "avant": "19:00", "jour_apres": 3, "apres": "20:00"}]'::jsonb
     OR NOT (v_p -> 'changements') @> '[{"jour_avant": 4, "avant": "18:00", "jour_apres": 4, "apres": "19:00"}]'::jsonb THEN
    RAISE EXCEPTION 'HLA ROUGE : parametres de l''annonce : %', v_p;
  END IF;
  -- Aucun prenom d'enfant dans les parametres (le push et le courriel les lisent).
  IF EXISTS (SELECT 1 FROM public.notifications n
              WHERE n.id NOT IN (SELECT id FROM hla_avant) AND n.params ? 'eleves') THEN
    RAISE EXCEPTION 'HLA ROUGE : un prenom d''eleve dans une annonce';
  END IF;
  RAISE NOTICE 'HLA OK : annonce a 14 jours (Paris) et la veille (Toronto), heures avant et apres, tuteur pour l''enfant, jamais l''enfant, rien pour Delhi ni Riyad';

  -- Rejouee au meme instant : aucune annonce de plus.
  IF private.annoncer_changements_heure('2027-03-14 06:00:00+00') <> 0 THEN
    RAISE EXCEPTION 'HLA ROUGE : annonces en double au meme instant';
  END IF;
  -- Rejouee le lendemain, toujours dans la fenetre de 14 jours de Paris : rien.
  IF private.annoncer_changements_heure('2027-03-15 06:00:00+00') <> 0 THEN
    RAISE EXCEPTION 'HLA ROUGE : annonces en double le lendemain (meme palier)';
  END IF;
  RAISE NOTICE 'HLA OK : rejouee, la tache n''annonce rien deux fois';
END
$c2$;

-- =====================================================================
-- (3) La veille : un second message, pour Paris seulement
-- =====================================================================
DO $c3$
DECLARE
  v_n integer;
BEGIN
  -- 27/03/2027 06:00 UTC : le changement de Paris est dans 19 h ; celui de
  -- Toronto est passe (le prochain est en novembre).
  v_n := private.annoncer_changements_heure('2027-03-27 06:00:00+00');
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'HLA ROUGE : % annonces la veille au lieu de 5 (enseignante x2, eleve et tuteur de Paris, tuteur pour l''enfant)', v_n;
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.annonces_changement_heure a
       WHERE a.destinataire = 'd2000000-0000-4000-8000-000000000b01') <> 4 THEN
    RAISE EXCEPTION 'HLA ROUGE : le tuteur de Paris devait avoir 4 annonces (j14 et j1, classe adultes et classe enfants)';
  END IF;
  RAISE NOTICE 'HLA OK : la veille, un second message a Paris (5 annonces), rien a Toronto (changement passe)';
END
$c3$;

-- =====================================================================
-- (4) Plus de changement d'heure a venir apres : rien
-- =====================================================================
DO $c4$
BEGIN
  -- Le 20 juillet : aucun changement d'heure dans les 14 jours.
  IF private.annoncer_changements_heure('2027-07-20 06:00:00+00') <> 0 THEN
    RAISE EXCEPTION 'HLA ROUGE : une annonce hors de toute fenetre';
  END IF;
  RAISE NOTICE 'HLA OK : hors des fenetres de 14 jours, aucune annonce';
END
$c4$;

-- =====================================================================
-- (5) L'apercu de l'ecran
-- =====================================================================
SELECT set_config('request.jwt.claim.sub', 'd2000000-0000-4000-8000-000000000b01', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"d2000000-0000-4000-8000-0000000000f1"}}', true);
SELECT set_config('test.uid', 'd2000000-0000-4000-8000-000000000b01', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d2000000-0000-4000-8000-0000000000f1"}}', true);
SET LOCAL ROLE authenticated;
DO $c5$
DECLARE
  v jsonb;
BEGIN
  v := public.apercu_creneau_academie('Europe/Paris', 3, 21);
  IF v ->> 'academie' <> 'Asia/Riyadh' OR (v ->> 'meme')::boolean
     OR v ->> 'maintenant' NOT IN ('19:00', '20:00')
     OR v ->> 'heure_apres' NOT IN ('19:00', '20:00')
     OR v ->> 'maintenant' = v ->> 'heure_apres' THEN
    RAISE EXCEPTION 'HLA ROUGE : apercu pour Paris : %', v;
  END IF;
  v := public.apercu_creneau_academie('Asia/Kolkata', 3, 21);
  IF v ->> 'maintenant' <> '23:30' OR NOT (v ->> 'meme')::boolean THEN
    RAISE EXCEPTION 'HLA ROUGE : apercu pour Delhi (23 h 30 attendu) : %', v;
  END IF;
  v := public.apercu_creneau_academie('Asia/Riyadh', 3, 21);
  IF v ->> 'maintenant' <> '21:00' OR NOT (v ->> 'meme')::boolean THEN
    RAISE EXCEPTION 'HLA ROUGE : apercu pour La Mecque : %', v;
  END IF;
  -- Une offre pas encore convertie (a l'heure de Paris, 19 h) vue de Delhi.
  v := public.apercu_creneau_academie('Asia/Kolkata', 3, 19, 'Europe/Paris');
  IF v ->> 'academie' <> 'Europe/Paris' OR v ->> 'maintenant' NOT IN ('23:30', '22:30') THEN
    RAISE EXCEPTION 'HLA ROUGE : apercu d''une offre a l''heure de Paris : %', v;
  END IF;
  BEGIN
    PERFORM public.apercu_creneau_academie('Nulle/Part', 3, 21);
    RAISE EXCEPTION 'HLA ROUGE : un fuseau inconnu est accepte';
  EXCEPTION WHEN invalid_parameter_value THEN
    NULL;
  END;
  RAISE NOTICE 'HLA OK : apercu : Paris (deux heures, selon la saison), Delhi 23 h 30, La Mecque 21 h, fuseau inconnu refuse';
END
$c5$;
RESET ROLE;

-- =====================================================================
-- (6) Droits
-- =====================================================================
DO $c6$
DECLARE
  v_f text;
  v_r text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.changement_heure_cours(text,text,integer,integer,timestamp with time zone)',
    'private.annoncer_changements_heure(timestamp with time zone)']
  LOOP
    FOREACH v_r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_r, v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
        RAISE EXCEPTION 'HLA ROUGE : % peut executer %', v_r, v_f;
      END IF;
    END LOOP;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.apercu_creneau_academie(text,integer,integer,text)'::pg_catalog.regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.apercu_creneau_academie(text,integer,integer,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HLA ROUGE : droits de l''apercu';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.annonces_changement_heure', 'SELECT') THEN
    RAISE EXCEPTION 'HLA ROUGE : la table des annonces est lisible par un client';
  END IF;
  RAISE NOTICE 'HLA OK : aucun EXECUTE client sur le calcul et la tache, apercu pour les comptes valides seulement, table fermee';
END
$c6$;

ROLLBACK;
