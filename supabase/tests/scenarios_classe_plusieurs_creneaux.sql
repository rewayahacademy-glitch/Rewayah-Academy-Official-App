-- Une classe a plusieurs creneaux par semaine, et la mixite (29/10/2026,
-- decisions D1 et D2 ; migration 20261030100000_classe_plusieurs_creneaux.sql),
-- puis la duree par creneau (30/10/2026, bloc $duree$).
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations,
-- sous une direction active (role authenticated). Fixtures sans donnee
-- personnelle ; tout est annule a la fin. Chaque controle reussi ecrit une
-- ligne "CRN OK" ; un echec leve 'CRN ROUGE : ...' (ON_ERROR_STOP).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c7000000-0000-4000-8000-000000000001', 'crn-admin@example.test'),
  ('c7000000-0000-4000-8000-0000000000e1', 'crn-e1@example.test'),
  ('c7000000-0000-4000-8000-0000000000e2', 'crn-e2@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('c7000000-0000-4000-8000-000000000001', 'CRNADMIN00000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('c7000000-0000-4000-8000-0000000000e1', 'CRNTEACHER0000E1', 'teacher',
   'Fixture', 'Enseignante', 'provisional_active', 'female', NULL),
  ('c7000000-0000-4000-8000-0000000000e2', 'CRNTEACHER0000E2', 'teacher',
   'Fixture', 'Enseignant', 'provisional_active', 'male', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('c7000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('c7000000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- Ajouter ou deplacer un creneau exige les disponibilites de l'enseignant
-- (regle de production de 20261025020000) : l'enseignante est disponible
-- tous les jours, de 6 h a 23 h.
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT e.id, j, h, 'Europe/Paris'
  FROM (VALUES ('c7000000-0000-4000-8000-0000000000e1'::uuid),
               ('c7000000-0000-4000-8000-0000000000e2'::uuid)) AS e(id),
       pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(6, 23) AS h;

SELECT set_config('request.jwt.claim.sub', 'c7000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'c7000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

DO $crn$
DECLARE
  v_classe uuid;
  v_n integer;
  v_avant bigint;
  v_jours integer[];
BEGIN
  -- Creation a la main : trois creneaux, une seule transaction.
  v_classe := public.creer_classe_creneaux_admin(
    'c7000000-0000-4000-8000-0000000000e1', 'adulte', 'CRN classe', 6::smallint, NULL,
    '[{"jour": 1, "heure": 18}, {"jour": 3, "heure": 18}, {"jour": 5, "heure": 19}]'::jsonb,
    'femmes');
  SELECT pg_catalog.array_agg(gc.weekday::integer ORDER BY gc.weekday) INTO v_jours
    FROM public.groupe_creneaux gc WHERE gc.groupe_id = v_classe;
  IF v_jours IS DISTINCT FROM ARRAY[1, 3, 5] THEN
    RAISE EXCEPTION 'CRN ROUGE : creneaux de la classe % au lieu de {1,3,5}', v_jours;
  END IF;
  SELECT pg_catalog.count(*) INTO v_avant FROM public.sessions s
   WHERE s.groupe_id = v_classe AND s.status = 'planned' AND s.deleted_at IS NULL;
  IF v_avant < 9 THEN
    RAISE EXCEPTION 'CRN ROUGE : % seances prevues, au moins 9 attendues (3 creneaux)', v_avant;
  END IF;
  RAISE NOTICE 'CRN OK : classe creee avec 3 creneaux et % seances', v_avant;

  -- Deux fois le meme creneau : refus, rien n'est cree.
  BEGIN
    PERFORM public.creer_classe_creneaux_admin(
      'c7000000-0000-4000-8000-0000000000e2', 'adulte', 'CRN double', 6::smallint, NULL,
      '[{"jour": 2, "heure": 10}, {"jour": 2, "heure": 10}]'::jsonb, 'hommes');
    RAISE EXCEPTION 'CRN ROUGE : creneaux en double acceptes';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'CRN OK : creneaux en double refuses';
  END;

  -- Modifier un creneau (non ancre) : ses seances a venir sont annulees,
  -- avec le motif ; les nouvelles sont generees.
  v_n := public.modifier_creneau_classe_admin(v_classe, 3, 18, 4, 20, NULL, 'scenario CRN');
  IF v_n < 1 THEN
    RAISE EXCEPTION 'CRN ROUGE : aucune seance creee au nouveau creneau';
  END IF;
  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.groupe_id = v_classe AND s.status = 'planned' AND s.deleted_at IS NULL
                AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') = 3) THEN
    RAISE EXCEPTION 'CRN ROUGE : une seance du mercredi reste prevue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.sessions s
                  WHERE s.groupe_id = v_classe AND s.status = 'canceled'
                    AND s.motif_annulation = 'scenario CRN' AND s.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'CRN ROUGE : les seances annulees n''ont pas leur motif';
  END IF;
  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.groupe_id = v_classe AND s.deleted_at IS NOT NULL) THEN
    RAISE EXCEPTION 'CRN ROUGE : une seance a ete supprimee au lieu d''etre annulee';
  END IF;
  RAISE NOTICE 'CRN OK : modification : anciennes seances annulees avec motif, % nouvelles', v_n;

  -- Modifier le creneau d'ancrage : l'ancre suit.
  PERFORM public.modifier_creneau_classe_admin(v_classe, 1, 18, 2, 17, NULL, 'scenario CRN ancre');
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = v_classe AND g.weekday = 2 AND g.hour_local = 17) THEN
    RAISE EXCEPTION 'CRN ROUGE : l''ancre n''a pas suivi la modification';
  END IF;
  SELECT pg_catalog.array_agg(gc.weekday::integer ORDER BY gc.weekday) INTO v_jours
    FROM public.groupe_creneaux gc WHERE gc.groupe_id = v_classe;
  IF v_jours IS DISTINCT FROM ARRAY[2, 4, 5] THEN
    RAISE EXCEPTION 'CRN ROUGE : creneaux % apres modification de l''ancre', v_jours;
  END IF;
  RAISE NOTICE 'CRN OK : modification de l''ancre';

  -- Retirer un creneau : annule ses seances a venir et le retire.
  v_n := public.retirer_creneau_classe_admin(v_classe, 5, 19, 'scenario CRN retrait');
  IF v_n < 1 OR EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                         WHERE gc.groupe_id = v_classe AND gc.weekday = 5) THEN
    RAISE EXCEPTION 'CRN ROUGE : le retrait n''a pas annule ou pas retire (% annulees)', v_n;
  END IF;
  -- Retirer l'ancre : elle passe sur le creneau restant.
  PERFORM public.retirer_creneau_classe_admin(v_classe, 2, 17, 'scenario CRN retrait ancre');
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = v_classe AND g.weekday = 4 AND g.hour_local = 20) THEN
    RAISE EXCEPTION 'CRN ROUGE : l''ancre n''est pas passee sur le creneau restant';
  END IF;
  -- Le dernier creneau ne se retire pas.
  BEGIN
    PERFORM public.retirer_creneau_classe_admin(v_classe, 4, 20, 'scenario CRN dernier');
    RAISE EXCEPTION 'CRN ROUGE : le dernier creneau a ete retire';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'CRN OK : retrait, retrait de l''ancre, le dernier creneau reste';
  END;
  -- Sans motif : refus.
  BEGIN
    PERFORM public.retirer_creneau_classe_admin(v_classe, 4, 20, '  ');
    RAISE EXCEPTION 'CRN ROUGE : retrait sans motif accepte';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'CRN OK : un motif est exige';
  END;

  -- Le genre choisi a la creation est enregistre ; une classe ne nait pas
  -- mixte sans le choisir.
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = v_classe AND g.genre_public = 'femmes' AND NOT g.mixte) THEN
    RAISE EXCEPTION 'CRN ROUGE : le genre de la creation n''est pas enregistre';
  END IF;
  BEGIN
    PERFORM public.creer_classe_creneaux_admin(
      'c7000000-0000-4000-8000-0000000000e2', 'adulte', 'CRN sans genre', 6::smallint, NULL,
      '[{"jour": 6, "heure": 10}]'::jsonb, 'indetermine');
    RAISE EXCEPTION 'CRN ROUGE : classe nouvelle sans genre acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'CRN OK : genre enregistre a la creation, jamais indetermine';
  END;
  PERFORM public.regler_genre_classe_admin(v_classe, 'femmes', 'scenario CRN genre');
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = v_classe AND g.genre_public = 'femmes' AND NOT g.mixte) THEN
    RAISE EXCEPTION 'CRN ROUGE : le genre femmes n''est pas pose';
  END IF;
  PERFORM public.regler_genre_classe_admin(v_classe, 'mixte', 'scenario CRN mixite');
  IF NOT EXISTS (SELECT 1 FROM public.groupes g
                  WHERE g.id = v_classe AND g.genre_public = 'indetermine' AND g.mixte) THEN
    RAISE EXCEPTION 'CRN ROUGE : la classe n''est pas mixte';
  END IF;
  BEGIN
    PERFORM public.regler_genre_classe_admin(v_classe, 'autre', 'scenario CRN');
    RAISE EXCEPTION 'CRN ROUGE : un genre inconnu est accepte';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'CRN OK : mixite par reglage explicite, genre inconnu refuse';
  END;
  -- Hommes avec une enseignante attitree : refus, rien n'est ecrit.
  BEGIN
    PERFORM public.regler_genre_classe_admin(v_classe, 'hommes', 'scenario CRN incompatible');
    RAISE EXCEPTION 'CRN ROUGE : classe d''hommes acceptee avec une enseignante';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'CRN ROUGE%' THEN RAISE; END IF;
    RAISE NOTICE 'CRN OK : genre incompatible avec l''enseignante refuse';
  END;
  IF NOT (SELECT g.mixte FROM public.groupes g WHERE g.id = v_classe) THEN
    RAISE EXCEPTION 'CRN ROUGE : un refus a change le genre';
  END IF;
END
$crn$;

-- Duree par creneau (30/10/2026) : chaque creneau a sa duree (vide : celle de
-- la Classe, 90 minutes pour des adultes) ; les seances la prennent, et le
-- controle des chevauchements de l'enseignant la compte, creneau par creneau.
DO $duree$
DECLARE
  v_a uuid;
  v_b uuid;
  v_n integer;
  v_minutes integer[];
BEGIN
  -- Classe A, enseignant E2 : mardi 10 h pour 45 minutes (ancre), jeudi 10 h
  -- sans duree (celle de la Classe : 90).
  v_a := public.creer_classe_creneaux_admin(
    'c7000000-0000-4000-8000-0000000000e2', 'adulte', 'CRN duree A', 6::smallint, NULL,
    '[{"jour": 2, "heure": 10, "duree": 45}, {"jour": 4, "heure": 10}]'::jsonb, 'hommes');
  SELECT pg_catalog.array_agg(DISTINCT (pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') * 1000
           + pg_catalog.date_part('epoch', s.ended_at - s.started_at) / 60)::integer)
    INTO v_minutes
    FROM public.sessions s
   WHERE s.groupe_id = v_a AND s.status = 'planned' AND s.deleted_at IS NULL;
  IF v_minutes IS DISTINCT FROM ARRAY[2045, 4090] THEN
    RAISE EXCEPTION 'CRN ROUGE : durees des seances % au lieu de mardi 45, jeudi 90', v_minutes;
  END IF;
  IF (SELECT gc.duree_minutes FROM public.groupe_creneaux gc
       WHERE gc.groupe_id = v_a AND gc.weekday = 2) IS DISTINCT FROM 45::smallint THEN
    RAISE EXCEPTION 'CRN ROUGE : la duree de l''ancre n''est pas enregistree';
  END IF;
  RAISE NOTICE 'CRN OK : chaque creneau genere ses seances a sa duree (45, et 90 par defaut)';

  -- Classe B, meme enseignant, mardi 9 h. Pour 90 minutes elle chevaucherait
  -- le mardi 10 h de A : refus. Pour 60 minutes elle finit a 10 h : acceptee.
  BEGIN
    PERFORM public.creer_classe_creneaux_admin(
      'c7000000-0000-4000-8000-0000000000e2', 'adulte', 'CRN duree B90', 6::smallint, NULL,
      '[{"jour": 2, "heure": 9, "duree": 90}]'::jsonb, 'hommes');
    RAISE EXCEPTION 'CRN ROUGE : creneau de 90 minutes qui chevauche accepte';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'chevauchement%' THEN RAISE; END IF;
    RAISE NOTICE 'CRN OK : creation refusee, sa duree chevauche une autre classe (%)', SQLERRM;
  END;
  v_b := public.creer_classe_creneaux_admin(
    'c7000000-0000-4000-8000-0000000000e2', 'adulte', 'CRN duree B60', 6::smallint, NULL,
    '[{"jour": 2, "heure": 9, "duree": 60}]'::jsonb, 'hommes');
  RAISE NOTICE 'CRN OK : creation acceptee, 60 minutes finissent quand l''autre commence';

  -- A l'inverse : A mardi 10 h deplace a 8 h 30 n'existe pas (heures
  -- entieres) ; on allonge B de 60 a 90 minutes : il chevaucherait A, refus,
  -- et rien ne change.
  BEGIN
    PERFORM public.modifier_creneau_classe_admin(v_b, 2, 9, 2, 9, 90, 'scenario CRN duree');
    RAISE EXCEPTION 'CRN ROUGE : allongement qui chevauche accepte';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'chevauchement%' THEN RAISE; END IF;
    RAISE NOTICE 'CRN OK : duree allongee refusee, elle chevaucherait une autre classe (%)', SQLERRM;
  END;
  IF (SELECT gc.duree_minutes FROM public.groupe_creneaux gc
       WHERE gc.groupe_id = v_b) IS DISTINCT FROM 60::smallint
     OR EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.groupe_id = v_b AND s.deleted_at IS NULL
                   AND s.ended_at - s.started_at <> interval '60 minutes') THEN
    RAISE EXCEPTION 'CRN ROUGE : le refus a change la duree';
  END IF;

  -- Deux creneaux d'une meme Classe qui se chevauchent : refus.
  BEGIN
    PERFORM public.creer_classe_creneaux_admin(
      'c7000000-0000-4000-8000-0000000000e1', 'adulte', 'CRN duree soi', 6::smallint, NULL,
      '[{"jour": 6, "heure": 8, "duree": 90}, {"jour": 6, "heure": 9}]'::jsonb, 'femmes');
    RAISE EXCEPTION 'CRN ROUGE : deux creneaux de la classe qui se chevauchent acceptes';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'chevauchement%' THEN RAISE; END IF;
    RAISE NOTICE 'CRN OK : deux creneaux de la meme classe qui se chevauchent refuses';
  END;

  -- La duree seule raccourcie : les seances a venir du jeudi la prennent,
  -- sans etre annulees.
  v_n := public.modifier_creneau_classe_admin(v_a, 4, 10, 4, 10, 60, 'scenario CRN jeudi');
  IF v_n < 1
     OR EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.groupe_id = v_a AND s.deleted_at IS NULL
                   AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') = 4
                   AND (s.status <> 'planned' OR s.ended_at - s.started_at <> interval '60 minutes')) THEN
    RAISE EXCEPTION 'CRN ROUGE : la duree du jeudi n''est pas passee a 60 minutes (% realignees)', v_n;
  END IF;
  RAISE NOTICE 'CRN OK : duree seule modifiee, % seances realignees, aucune annulee', v_n;

  -- L'ancre deplacee avec une nouvelle duree : mercredi 14 h, 120 minutes.
  PERFORM public.modifier_creneau_classe_admin(v_a, 2, 10, 3, 14, 120, 'scenario CRN ancre duree');
  IF (SELECT gc.duree_minutes FROM public.groupe_creneaux gc
       WHERE gc.groupe_id = v_a AND gc.weekday = 3 AND gc.hour_local = 14) IS DISTINCT FROM 120::smallint
     OR NOT EXISTS (SELECT 1 FROM public.sessions s
                     WHERE s.groupe_id = v_a AND s.status = 'planned' AND s.deleted_at IS NULL
                       AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') = 3)
     OR EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.groupe_id = v_a AND s.status = 'planned' AND s.deleted_at IS NULL
                   AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') = 3
                   AND s.ended_at - s.started_at <> interval '120 minutes') THEN
    RAISE EXCEPTION 'CRN ROUGE : l''ancre deplacee n''a pas sa nouvelle duree';
  END IF;
  RAISE NOTICE 'CRN OK : ancre deplacee avec sa nouvelle duree';

  -- Ajouter un creneau avec sa duree.
  v_n := public.ajouter_creneau_classe_admin(v_a, 6, 14, 30);
  IF v_n < 1 OR EXISTS (SELECT 1 FROM public.sessions s
                         WHERE s.groupe_id = v_a AND s.deleted_at IS NULL
                           AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE 'Europe/Paris') = 6
                           AND s.ended_at - s.started_at <> interval '30 minutes') THEN
    RAISE EXCEPTION 'CRN ROUGE : le creneau ajoute n''a pas sa duree';
  END IF;
  RAISE NOTICE 'CRN OK : creneau ajoute avec sa duree, % seances', v_n;

  -- Une duree hors de 15 a 240 minutes : refus.
  BEGIN
    PERFORM public.ajouter_creneau_classe_admin(v_a, 7, 14, 10);
    RAISE EXCEPTION 'CRN ROUGE : duree de 10 minutes acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.creer_classe_creneaux_admin(
      'c7000000-0000-4000-8000-0000000000e1', 'adulte', 'CRN duree trop', 6::smallint, NULL,
      '[{"jour": 7, "heure": 8, "duree": 300}]'::jsonb, 'femmes');
    RAISE EXCEPTION 'CRN ROUGE : duree de 300 minutes acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.modifier_creneau_classe_admin(v_a, 6, 14, 6, 14, 241, 'scenario CRN');
    RAISE EXCEPTION 'CRN ROUGE : duree de 241 minutes acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  RAISE NOTICE 'CRN OK : duree hors de 15 a 240 minutes refusee';
END
$duree$;

RESET ROLE;

-- Une Classe deplacee par son horaire (groupes.weekday / hour_local, comme
-- le fait modifier_groupe) : son creneau d'ancrage garde sa duree.
DO $ancre$
DECLARE
  v_a uuid := (SELECT g.id FROM public.groupes g WHERE g.libelle = 'CRN duree A');
BEGIN
  UPDATE public.groupes SET hour_local = 17 WHERE id = v_a;
  IF (SELECT gc.duree_minutes FROM public.groupe_creneaux gc
       WHERE gc.groupe_id = v_a AND gc.weekday = 3 AND gc.hour_local = 17) IS DISTINCT FROM 120::smallint
     OR EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.groupe_id = v_a AND s.status = 'planned' AND s.deleted_at IS NULL
                   AND s.started_at = public.instant_creneau(3, 17, 'Europe/Paris', 0)
                   AND s.ended_at - s.started_at <> interval '120 minutes') THEN
    RAISE EXCEPTION 'CRN ROUGE : l''ancre deplacee a perdu sa duree';
  END IF;
  RAISE NOTICE 'CRN OK : l''ancre deplacee garde sa duree';
END
$ancre$;

-- Les fonctions de la direction ne s'ouvrent qu'a elle.
DO $acl$
BEGIN
  IF pg_catalog.has_function_privilege('anon',
       'public.retirer_creneau_classe_admin(uuid,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.annuler_seances_creneau(uuid,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'app_private.creneaux_de_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.ajouter_creneau_classe_admin(uuid,integer,integer,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,integer,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CRN ROUGE : droits trop larges';
  END IF;
  RAISE NOTICE 'CRN OK : droits';
END
$acl$;

ROLLBACK;
