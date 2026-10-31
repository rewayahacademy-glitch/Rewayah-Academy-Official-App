-- REAFFECTER-CLASSE (31/10/2026) : la direction retire une Classe a son
-- enseignant pour la confier a un autre. Migration 20261103100000.
--
-- Quatre enseignants : t1 (titulaire de la Classe A), t2 (libre, femme),
-- t3 (homme, la Classe A est « femmes »), t4 (titulaire de la Classe B, au
-- meme creneau que A).
--   1. l'affectation d'une Classe deja servie repond toujours deja_affecte ;
--   2. les enseignants possibles : t2 seul ;
--   3. refus : t4 occupe a l'heure, t3 incompatible, un enseignant n'a pas
--      le droit, une Classe sans enseignant est indisponible ;
--   4. reaffectation a t2 : Classe et seances futures, la seance passee garde
--      t1, journal, notifications a t1 et t2 ;
--   5. rejeu : deja_en_place, rien de plus ;
--   6. droits.
-- Tout est annule a la fin. Chaque controle ecrit « RCL OK ».
\o /dev/null
BEGIN;
-- Les notifications de Classe sont un declencheur differe : immediat ici.
SET CONSTRAINTS ALL IMMEDIATE;

INSERT INTO auth.users (id, email)
SELECT ('c8000000-0000-4000-8000-0000000000' || x)::uuid, 'rcl-' || x || '@example.test'
  FROM unnest(ARRAY['a1','b1','b2','b3','b4']) AS x;
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('c8000000-0000-4000-8000-0000000000a1', 'RCLADMIN0000A1', 'admin', 'Fixture', 'Direction', 'active', 'female', NULL),
  ('c8000000-0000-4000-8000-0000000000b1', 'RCLTEACHER00T1', 'teacher', 'Maryam', 'Un', 'provisional_active', 'female', NULL),
  ('c8000000-0000-4000-8000-0000000000b2', 'RCLTEACHER00T2', 'teacher', 'Hawa', 'Deux', 'provisional_active', 'female', NULL),
  ('c8000000-0000-4000-8000-0000000000b3', 'RCLTEACHER00T3', 'teacher', 'Moussa', 'Trois', 'provisional_active', 'male', NULL),
  ('c8000000-0000-4000-8000-0000000000b4', 'RCLTEACHER00T4', 'teacher', 'Safa', 'Quatre', 'provisional_active', 'female', NULL);
INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
SELECT ('c8000000-0000-4000-8000-0000000000' || x)::uuid, 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL
  FROM unnest(ARRAY['b1','b2','b3','b4']) AS x;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT ('c8000000-0000-4000-8000-0000000000' || x)::uuid, j, h, 'Europe/Paris'
  FROM unnest(ARRAY['b1','b4']) AS x,
       pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(6, 23) AS h;

SELECT set_config('request.jwt.claim.sub', 'c8000000-0000-4000-8000-0000000000a1', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'c8000000-0000-4000-8000-0000000000a1', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE rcl (cle text PRIMARY KEY, id uuid);
GRANT ALL ON rcl TO authenticated;

DO $rcl$
DECLARE
  v_a uuid;
  v_b uuid;
  v_r jsonb;
  v_n integer;
BEGIN
  v_a := public.creer_classe_creneaux_admin(
    'c8000000-0000-4000-8000-0000000000b1', 'adulte', 'RCL A', 6::smallint, NULL,
    '[{"jour": 1, "heure": 18}]'::jsonb, 'femmes');
  v_b := public.creer_classe_creneaux_admin(
    'c8000000-0000-4000-8000-0000000000b4', 'adulte', 'RCL B', 6::smallint, NULL,
    '[{"jour": 1, "heure": 18}]'::jsonb, 'femmes');
  INSERT INTO rcl VALUES ('a', v_a), ('b', v_b);

  -- 1. L'affectation existante ne retire rien.
  IF public.affecter_enseignant_classe_c11bis(v_a, 'c8000000-0000-4000-8000-0000000000b2') <> 'deja_affecte' THEN
    RAISE EXCEPTION 'RCL ROUGE : affecter_enseignant_classe_c11bis ne repond plus deja_affecte';
  END IF;
  RAISE NOTICE 'RCL OK : l''affectation d''une Classe servie repond toujours deja_affecte';

  -- 2. Les enseignants possibles.
  IF (SELECT pg_catalog.array_agg(e.enseignant_id::text ORDER BY e.enseignant_id)
        FROM public.enseignants_pour_reaffectation(v_a) e)
     IS DISTINCT FROM ARRAY['c8000000-0000-4000-8000-0000000000b2'] THEN
    RAISE EXCEPTION 'RCL ROUGE : possibles = %', (SELECT pg_catalog.array_agg(e.nom)
      FROM public.enseignants_pour_reaffectation(v_a) e);
  END IF;
  RAISE NOTICE 'RCL OK : possibles : t2 seule (ni la titulaire, ni l''homme, ni l''occupee)';

  -- 3. Refus.
  BEGIN
    PERFORM public.reaffecter_enseignant_classe(v_a, 'c8000000-0000-4000-8000-0000000000b4', NULL);
    RAISE EXCEPTION 'RCL ROUGE : enseignante occupee acceptee';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'EnseignantOccupe' THEN RAISE EXCEPTION 'RCL ROUGE : % au lieu de EnseignantOccupe', SQLERRM; END IF;
    RAISE NOTICE 'RCL OK : occupee a l''heure de la Classe : EnseignantOccupe';
  END;
  BEGIN
    PERFORM public.reaffecter_enseignant_classe(v_a, 'c8000000-0000-4000-8000-0000000000b3', NULL);
    RAISE EXCEPTION 'RCL ROUGE : homme accepte dans une Classe « femmes »';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'EnseignantIncompatible' THEN RAISE EXCEPTION 'RCL ROUGE : % au lieu de EnseignantIncompatible', SQLERRM; END IF;
    RAISE NOTICE 'RCL OK : genre du public : EnseignantIncompatible';
  END;
  IF (SELECT g.teacher_id FROM public.groupes g WHERE g.id = v_a) <> 'c8000000-0000-4000-8000-0000000000b1' THEN
    RAISE EXCEPTION 'RCL ROUGE : un refus a change la Classe';
  END IF;
END;
$rcl$;

-- Une seance passee de la Classe A, tenue par t1 : elle doit lui rester.
RESET ROLE;
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT 'c8000000-0000-4000-8000-000000000501', 'c8000000-0000-4000-8000-0000000000b1',
       now() - interval '7 days', now() - interval '7 days' + interval '1 hour', 'planned', r.id
  FROM rcl r WHERE r.cle = 'a';

-- Un enseignant n'a pas le droit.
SELECT set_config('request.jwt.claim.sub', 'c8000000-0000-4000-8000-0000000000b1', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.uid', 'c8000000-0000-4000-8000-0000000000b1', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SET LOCAL ROLE authenticated;
DO $prof$
BEGIN
  PERFORM public.reaffecter_enseignant_classe((SELECT id FROM rcl WHERE cle = 'a'),
                                              'c8000000-0000-4000-8000-0000000000b1', NULL);
  RAISE EXCEPTION 'RCL ROUGE : un enseignant a reaffecte une Classe';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'RCL OK : un enseignant ne reaffecte pas';
END;
$prof$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub', 'c8000000-0000-4000-8000-0000000000a1', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'c8000000-0000-4000-8000-0000000000a1', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

-- 4. La reaffectation.
DO $rcl$
DECLARE
  v_a uuid := (SELECT id FROM rcl WHERE cle = 'a');
  v_futures integer;
  v_r jsonb;
BEGIN
  SELECT count(*) INTO v_futures FROM public.sessions s
   WHERE s.groupe_id = v_a AND s.deleted_at IS NULL AND s.status = 'planned' AND s.started_at > now();
  v_r := public.reaffecter_enseignant_classe(v_a, 'c8000000-0000-4000-8000-0000000000b2', 'absences repetees');
  IF v_r ->> 'etat' <> 'reaffecte' OR (v_r ->> 'seances')::int <> v_futures OR v_futures < 1 THEN
    RAISE EXCEPTION 'RCL ROUGE : reponse % pour % seances futures', v_r, v_futures;
  END IF;
  RAISE NOTICE 'RCL OK : reaffectee a t2, % seances futures', v_futures;

  -- 5. Rejeu.
  v_r := public.reaffecter_enseignant_classe(v_a, 'c8000000-0000-4000-8000-0000000000b2', 'absences repetees');
  IF v_r ->> 'etat' <> 'deja_en_place' THEN
    RAISE EXCEPTION 'RCL ROUGE : rejeu %', v_r;
  END IF;
  RAISE NOTICE 'RCL OK : rejeu : deja_en_place';
END;
$rcl$;
RESET ROLE;

DO $verif$
DECLARE
  v_a uuid := (SELECT id FROM rcl WHERE cle = 'a');
BEGIN
  IF (SELECT g.teacher_id FROM public.groupes g WHERE g.id = v_a) <> 'c8000000-0000-4000-8000-0000000000b2'
     OR EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.groupe_id = v_a AND s.deleted_at IS NULL AND s.status = 'planned'
                   AND s.started_at > now() AND s.teacher_id <> 'c8000000-0000-4000-8000-0000000000b2') THEN
    RAISE EXCEPTION 'RCL ROUGE : la Classe ou une seance future n''est pas a t2';
  END IF;
  RAISE NOTICE 'RCL OK : Classe et seances futures a t2';
  IF (SELECT s.teacher_id FROM public.sessions s WHERE s.id = 'c8000000-0000-4000-8000-000000000501')
     <> 'c8000000-0000-4000-8000-0000000000b1' THEN
    RAISE EXCEPTION 'RCL ROUGE : la seance passee a change d''enseignant';
  END IF;
  RAISE NOTICE 'RCL OK : la seance passee garde t1';
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs l
                  WHERE l.action = 'enseignant_reaffecte_classe' AND l.row_id = v_a::text
                    AND l.payload ->> 'ancien_teacher_id' = 'c8000000-0000-4000-8000-0000000000b1'
                    AND l.payload ->> 'teacher_id' = 'c8000000-0000-4000-8000-0000000000b2'
                    AND l.payload ->> 'motif' = 'absences repetees') THEN
    RAISE EXCEPTION 'RCL ROUGE : journal absent';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs l
       WHERE l.action = 'enseignant_reaffecte_classe' AND l.row_id = v_a::text) <> 1 THEN
    RAISE EXCEPTION 'RCL ROUGE : le rejeu a ecrit au journal';
  END IF;
  RAISE NOTICE 'RCL OK : journal (ancien, nouveau, motif), une seule ligne';
  IF NOT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.destinataire = 'c8000000-0000-4000-8000-0000000000b1' AND n.evenement = 'enseignant_change')
     OR NOT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.destinataire = 'c8000000-0000-4000-8000-0000000000b2' AND n.evenement = 'enseignant_change') THEN
    RAISE EXCEPTION 'RCL ROUGE : notification enseignant_change manquante';
  END IF;
  RAISE NOTICE 'RCL OK : t1 et t2 prevenues (enseignant_change)';
  -- Une Classe sans enseignant n'est pas reaffectable.
  UPDATE public.groupes SET teacher_id = NULL, etat = 'en_attente_enseignant'
   WHERE id = (SELECT id FROM rcl WHERE cle = 'b');
END;
$verif$;

SET LOCAL ROLE authenticated;
DO $indispo$
BEGIN
  PERFORM public.reaffecter_enseignant_classe((SELECT id FROM rcl WHERE cle = 'b'),
                                              'c8000000-0000-4000-8000-0000000000b2', NULL);
  RAISE EXCEPTION 'RCL ROUGE : Classe sans enseignant reaffectee';
EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'ClasseIndisponible' THEN RAISE EXCEPTION 'RCL ROUGE : %', SQLERRM; END IF;
  RAISE NOTICE 'RCL OK : Classe sans enseignant : ClasseIndisponible';
END;
$indispo$;
RESET ROLE;

-- 6. Droits.
DO $droits$
BEGIN
  IF has_function_privilege('anon', 'public.reaffecter_enseignant_classe(uuid,uuid,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.enseignants_pour_reaffectation(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.verifier_reaffectation(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'RCL ROUGE : droits trop larges';
  END IF;
  RAISE NOTICE 'RCL OK : droits';
END;
$droits$;

\o
ROLLBACK;
