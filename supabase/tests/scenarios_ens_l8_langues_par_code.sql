-- ENS-L8 (CAND-Q15, lot langue) : teacher_profiles.languages porte des codes
-- de langues_cours, quel que soit l'ecrivain, et la proposition comme la
-- verification d'affectation retrouvent l'enseignante qui a declare ses
-- langues par leur nom (FORM-L8).
--
-- Base neuve : stub_auth.sql, toutes les migrations dans l'ordre, puis ce
-- fichier. Aucun appel a une base distante. Tout est annule a la fin.
--
-- Contre-epreuve : rejoue sans 20261021210000_ens_l8_langues_par_code.sql,
-- le controle 1 echoue (le nom reste stocke) et, sa seule assertion retiree,
-- le controle 2 aussi (0 ligne) : c'est le defaut.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('e8100000-0000-0000-0000-000000000001', 'ens-l8-admin@example.test'),
  ('e8100000-0000-0000-0000-000000000002', 'ens-l8-enseignante@example.test'),
  ('e8100000-0000-0000-0000-000000000003', 'ens-l8-enseignant-direct@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('e8100000-0000-0000-0000-000000000001', 'ENSL8ADMIN00001', 'admin',
   'Fixture', 'Direction', 'active', 'female'),
  ('e8100000-0000-0000-0000-000000000002', 'ENSL8TEACH00002', 'teacher',
   'Aicha', 'Enseignante', 'provisional_active', 'female'),
  ('e8100000-0000-0000-0000-000000000003', 'ENSL8TEACH00003', 'teacher',
   'Moussa', 'Direct', 'provisional_active', 'male');

-- Comme apres une invitation : aucune langue declaree.
INSERT INTO public.teacher_profiles
  (profile_id, country, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('e8100000-0000-0000-0000-000000000002', 'FR', 40, 'approved', 'Europe/Paris');

INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES ('e8100000-0000-0000-0000-000000000002', 1, 10, 'Europe/Paris');

-- Une classe nee d'un regroupement : en attente d'enseignant, langue_code
-- jamais nul.
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, genre_public, seuil_max, libelle,
   weekday, hour_local, timezone_iana, langue_code)
VALUES
  ('e81fffff-0000-0000-0000-000000000001', NULL, 'en_attente_enseignant',
   'enfant', 'femmes', 5, 'ENS-L8 femmes', 1, 10, 'Europe/Paris', 'francais');

-- 0. Le referentiel de depart (0043) : les noms ecrits par FORM-L8 sont des
-- copies exactes de nom_humain.
DO $ens_l8_0$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.langues_cours
     WHERE code = 'francais' AND nom_humain = 'Français'
  ) THEN
    RAISE EXCEPTION 'ENS-L8 0 : referentiel inattendu, francais absent';
  END IF;
END
$ens_l8_0$;

-- 1. L'enseignante declare par ENS-05 : nom, saisie libre, code mal ecrit.
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'e8100000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SELECT public.maj_profil_enseignant(
  p_languages => ARRAY['Français', 'Arabe', ' francais ']
);
RESET ROLE;

DO $ens_l8_1$
DECLARE
  v_langues text[];
BEGIN
  SELECT tp.languages INTO v_langues
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000002';
  IF v_langues IS DISTINCT FROM ARRAY['francais', 'Arabe']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 1 : attendu {francais,Arabe}, obtenu %', v_langues;
  END IF;
END
$ens_l8_1$;

-- 2. La direction voit l'enseignante proposee pour la classe francais.
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'e8100000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $ens_l8_2$
DECLARE
  v_total integer;
  v_elle integer;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE teacher_id = 'e8100000-0000-0000-0000-000000000002')
    INTO v_total, v_elle
    FROM public.enseignants_pour_classe('e81fffff-0000-0000-0000-000000000001');
  IF v_total <> 1 OR v_elle <> 1 THEN
    RAISE EXCEPTION 'ENS-L8 2 : attendu 1 ligne pour l''enseignante, obtenu % (dont elle %)',
      v_total, v_elle;
  END IF;
END
$ens_l8_2$;
RESET ROLE;

-- 3. La verification d'affectation ne leve rien pour elle. Elle est revoquee
-- a authenticated : on l'appelle hors de ce role.
DO $ens_l8_3$
BEGIN
  PERFORM public.tc_verifier_affectation_enseignant(
    'e81fffff-0000-0000-0000-000000000001',
    'e8100000-0000-0000-0000-000000000002'
  );
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'ENS-L8 3 : verification refusee : %', SQLERRM;
END
$ens_l8_3$;

-- 4. Une langue hors referentiel reste une saisie libre : la langue de la
-- classe reste exigee.
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'e8100000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SELECT public.maj_profil_enseignant(p_languages => ARRAY['Wolof']);
SELECT set_config('test.uid', 'e8100000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $ens_l8_4$
DECLARE
  v_elle integer;
BEGIN
  SELECT count(*) FILTER (WHERE teacher_id = 'e8100000-0000-0000-0000-000000000002')
    INTO v_elle
    FROM public.enseignants_pour_classe('e81fffff-0000-0000-0000-000000000001');
  IF v_elle <> 0 THEN
    RAISE EXCEPTION 'ENS-L8 4 : une enseignante sans francais est proposee (% ligne)', v_elle;
  END IF;
END
$ens_l8_4$;
RESET ROLE;

DO $ens_l8_4b$
DECLARE
  v_langues text[];
BEGIN
  SELECT tp.languages INTO v_langues
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000002';
  IF v_langues IS DISTINCT FROM ARRAY['Wolof']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 4 : attendu {Wolof}, obtenu %', v_langues;
  END IF;
  BEGIN
    PERFORM public.tc_verifier_affectation_enseignant(
      'e81fffff-0000-0000-0000-000000000001',
      'e8100000-0000-0000-0000-000000000002'
    );
    RAISE EXCEPTION USING ERRCODE = 'ZX001',
      MESSAGE = 'ENS-L8 4 : verification acceptee sans la langue de la classe';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'enseignant indisponible%' THEN RAISE; END IF;
  END;
END
$ens_l8_4b$;

-- 5. Une ecriture directe de la direction (sous authenticated, donc avec les
-- droits de lecture de ce role sur langues_cours) est normalisee aussi.
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'e8100000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
INSERT INTO public.teacher_profiles (profile_id, languages, kyc_status)
VALUES ('e8100000-0000-0000-0000-000000000003',
        ARRAY['English', 'Poular', '', NULL, 'english'], 'pending');
UPDATE public.teacher_profiles
   SET languages = languages || ARRAY['Arabe', 'POULAR', 'Français']
 WHERE profile_id = 'e8100000-0000-0000-0000-000000000003';
RESET ROLE;

DO $ens_l8_5$
DECLARE
  v_langues text[];
BEGIN
  SELECT tp.languages INTO v_langues
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000003';
  IF v_langues IS DISTINCT FROM ARRAY['english', 'poular', 'Arabe', 'francais']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 5 : attendu {english,poular,Arabe,francais}, obtenu %', v_langues;
  END IF;
END
$ens_l8_5$;

-- 6. La fonction de declenchement n'est executable par aucun role client.
DO $ens_l8_6$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(
         v_role, 'public.teacher_profiles_langues_par_code()', 'EXECUTE'
       ) THEN
      RAISE EXCEPTION 'ENS-L8 6 : % peut executer teacher_profiles_langues_par_code', v_role;
    END IF;
  END LOOP;
  IF (SELECT p.prosecdef FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.teacher_profiles_langues_par_code()'::regprocedure) THEN
    RAISE EXCEPTION 'ENS-L8 6 : la fonction de declenchement doit rester SECURITY INVOKER';
  END IF;
END
$ens_l8_6$;

-- 7. (relecture) Un code exact passe avant un nom homonyme, meme d'ordre
-- plus petit. Un tableau NULL n'est pas maquille en tableau vide.
INSERT INTO public.langues_cours (code, nom_humain, ordre) VALUES
  ('soninke', 'Sarakole', 20),
  ('snk', 'Soninke', 0);
UPDATE public.teacher_profiles
   SET languages = ARRAY['Soninke', 'sarakole', 'SNK']
 WHERE profile_id = 'e8100000-0000-0000-0000-000000000003';

DO $ens_l8_7$
DECLARE
  v_langues text[];
BEGIN
  SELECT tp.languages INTO v_langues
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000003';
  IF v_langues IS DISTINCT FROM ARRAY['soninke', 'snk']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 7 : attendu {soninke,snk}, obtenu %', v_langues;
  END IF;

  BEGIN
    UPDATE public.teacher_profiles
       SET languages = NULL
     WHERE profile_id = 'e8100000-0000-0000-0000-000000000003';
    RAISE EXCEPTION USING ERRCODE = 'ZX001',
      MESSAGE = 'ENS-L8 7 : un tableau NULL a ete accepte';
  EXCEPTION WHEN not_null_violation THEN NULL;
  END;
END
$ens_l8_7$;

-- 8. La reprise : apres l'ajout d'une langue au referentiel, rejouer
-- l'instruction du commentaire de colonne rattache les saisies libres
-- existantes a leur code, et ne touche pas une saisie toujours libre.
UPDATE public.teacher_profiles
   SET languages = ARRAY['Arabe', 'Français']
 WHERE profile_id = 'e8100000-0000-0000-0000-000000000003';
INSERT INTO public.langues_cours (code, nom_humain, ordre) VALUES
  ('ar', 'Arabe', 4);
UPDATE public.teacher_profiles SET languages = languages WHERE languages <> '{}';

DO $ens_l8_8$
DECLARE
  v_direct text[];
  v_elle text[];
BEGIN
  SELECT tp.languages INTO v_direct
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000003';
  IF v_direct IS DISTINCT FROM ARRAY['ar', 'francais']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 8 : attendu {ar,francais}, obtenu %', v_direct;
  END IF;
  SELECT tp.languages INTO v_elle
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = 'e8100000-0000-0000-0000-000000000002';
  IF v_elle IS DISTINCT FROM ARRAY['Wolof']::text[] THEN
    RAISE EXCEPTION 'ENS-L8 8 : saisie libre modifiee, obtenu %', v_elle;
  END IF;
END
$ens_l8_8$;

ROLLBACK;
