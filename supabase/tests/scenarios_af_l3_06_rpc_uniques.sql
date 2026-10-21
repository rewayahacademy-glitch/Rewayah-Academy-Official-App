-- AF L3-06 (audit final 16/10/2026) : une seule signature par intention.
-- Les quatre surcharges retirees (creer_groupe a 6 arguments, modifier_groupe
-- a 5 arguments, affecter_enseignant_classe, publier_groupe_depuis_offre)
-- refusent un admin valide par SQLSTATE 42501 exact. Les signatures gardees
-- (creer_groupe a 8 arguments, modifier_groupe a 7 arguments) restent
-- executables par ce meme admin et ecrivent la ligne attendue.
-- Rejoue apres toutes les migrations sur une base jetable.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a3060000-0000-0000-0000-000000000001', 'l306-admin@example.test'),
  ('a3060000-0000-0000-0000-000000000002', 'l306-enseignant@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('a3060000-0000-0000-0000-000000000101', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
VALUES
  ('a3060000-0000-0000-0000-000000000001', 'L306-ADMIN-M', 'admin',
   'a3060000-0000-0000-0000-000000000101', 'Admin', 'L306', 'male', 'active'),
  -- provisional_active : creer_groupe accepte ce statut, et l'activation
  -- passe par la signature du NDA (hors de ce scenario).
  ('a3060000-0000-0000-0000-000000000002', 'L306-ENS-M', 'teacher',
   'a3060000-0000-0000-0000-000000000101', 'Enseignant', 'L306', 'male', 'provisional_active');

-- CAND-Q15 (lot creer_groupe, 21/10) : creer_groupe passe par le predicat
-- d'affectation ; l'enseignant doit avoir sa piece d'identite validee.
INSERT INTO public.teacher_profiles (profile_id, kyc_status)
VALUES ('a3060000-0000-0000-0000-000000000002', 'approved');

-- Controle catalogue (postgres) : privileges effectifs des quatre fonctions
-- retirees et des quatre signatures gardees.
DO $catalogue$
DECLARE
  v_retirees text[] := array[
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint)',
    'public.affecter_enseignant_classe(uuid,uuid)',
    'public.publier_groupe_depuis_offre(uuid,uuid,text,uuid[])'
  ];
  v_gardees text[] := array[
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
    'public.creer_classe_depuis_regroupement(uuid,uuid,text)',
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)'
  ];
  v_fn text;
BEGIN
  FOREACH v_fn IN ARRAY v_retirees LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_fn, 'execute')
       OR pg_catalog.has_function_privilege('anon', v_fn, 'execute') THEN
      RAISE EXCEPTION 'L3-06 : % reste executable par authenticated ou anon', v_fn;
    END IF;
  END LOOP;
  FOREACH v_fn IN ARRAY v_gardees LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v_fn, 'execute') THEN
      RAISE EXCEPTION 'L3-06 : % n''est plus executable par authenticated', v_fn;
    END IF;
  END LOOP;
END
$catalogue$;

-- Admin valide, jeton d'application admin, role authenticated.
SELECT set_config('request.jwt.claim.sub', 'a3060000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

-- Refus : chaque surcharge retiree doit lever 42501 exact.
DO $refus$
DECLARE
  v_enseignant uuid := 'a3060000-0000-0000-0000-000000000002';
  v_groupe uuid := 'a3060000-0000-0000-0000-000000000301';
  v_offre uuid := 'a3060000-0000-0000-0000-000000000401';
BEGIN
  BEGIN
    PERFORM public.creer_groupe(v_enseignant, 'enfant', 'L306 courte',
      2::smallint, 18::smallint, 5::smallint);
    RAISE EXCEPTION 'L3-06 : creer_groupe a 6 arguments accepte un admin valide';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> '42501' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.modifier_groupe(v_groupe, 'L306 courte', 5::smallint,
      3::smallint, 19::smallint);
    RAISE EXCEPTION 'L3-06 : modifier_groupe a 5 arguments accepte un admin valide';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> '42501' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.affecter_enseignant_classe(v_groupe, v_enseignant);
    RAISE EXCEPTION 'L3-06 : affecter_enseignant_classe accepte un admin valide';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> '42501' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.publier_groupe_depuis_offre(v_offre, v_enseignant, 'L306 offre',
      ARRAY[]::uuid[]);
    RAISE EXCEPTION 'L3-06 : publier_groupe_depuis_offre accepte un admin valide';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> '42501' THEN RAISE; END IF;
  END;
END
$refus$;

-- Succes : les signatures gardees ecrivent la ligne attendue sous le meme admin.
DO $succes$
DECLARE
  v_enseignant uuid := 'a3060000-0000-0000-0000-000000000002';
  v_groupe uuid;
BEGIN
  v_groupe := public.creer_groupe(v_enseignant, 'enfant', 'L306 longue',
    2::smallint, 18::smallint, 5::smallint, null::text, null::smallint);
  IF v_groupe IS NULL THEN
    RAISE EXCEPTION 'L3-06 : creer_groupe a 8 arguments n''a pas renvoye d''identifiant';
  END IF;

  PERFORM public.modifier_groupe(v_groupe, 'L306 modifiee', 6::smallint,
    3::smallint, 19::smallint, null::text, null::smallint);
END
$succes$;

RESET ROLE;

DO $verif$
DECLARE
  v_libelle text;
  v_seuil smallint;
  v_heure smallint;
BEGIN
  SELECT g.libelle, g.seuil_max, g.hour_local
    INTO v_libelle, v_seuil, v_heure
    FROM public.groupes g
   WHERE g.libelle = 'L306 modifiee';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'L3-06 : le groupe cree puis modifie par les signatures gardees est absent';
  END IF;
  IF v_seuil <> 6 OR v_heure <> 19 THEN
    RAISE EXCEPTION 'L3-06 : modifier_groupe garde n''a pas applique seuil 6 et heure 19 (%, %)',
      v_seuil, v_heure;
  END IF;
END
$verif$;

ROLLBACK;
