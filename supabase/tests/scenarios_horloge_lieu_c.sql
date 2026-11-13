-- HORLOGE-ET-LIEU, correctifs de la partie B (revue du 13/11/2026, migration
-- 20261123943200) :
--   1. le candidat enseignant (teacher en pending_kyc, de vraies RPC d'invitation
--      et d'inscription) cherche puis enregistre SA ville ; rien d'autre n'est
--      ouvert (tuteur en attente, compte desactive, compte supprime, eleve) ;
--      l'adulte « pour moi » (guardian, foyer d'une personne) choisit la sienne ;
--   2. l'anonymisation efface le lieu d'un enseignant, et celui du foyer quand le
--      dernier tuteur actif part (pas avant).
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque controle
-- reussi ecrit une ligne "HLD OK" ; un echec leve 'HLD ROUGE : ...'.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d6000000-0000-4000-8000-000000000001', 'hld-admin@example.test'),
  ('d6000000-0000-4000-8000-000000000102', 'hld-candidat@example.test'),
  ('d6000000-0000-4000-8000-000000000103', 'hld-tuteur-attente@example.test'),
  ('d6000000-0000-4000-8000-000000000104', 'hld-desactive@example.test'),
  ('d6000000-0000-4000-8000-000000000105', 'hld-supprime@example.test'),
  ('d6000000-0000-4000-8000-000000000106', 'hld-adulte@example.test'),
  ('d6000000-0000-4000-8000-000000000107', 'hld-tuteur-a@example.test'),
  ('d6000000-0000-4000-8000-000000000108', 'hld-tuteur-b@example.test'),
  ('d6000000-0000-4000-8000-000000000109', 'hld-actif@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('d6000000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
  ('d6000000-0000-4000-8000-0000000000f2', 'Europe/Paris'),
  ('d6000000-0000-4000-8000-0000000000f3', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id, deleted_at)
VALUES
  ('d6000000-0000-4000-8000-000000000001', 'HLDADMIN00000001', 'admin', 'Fixture', 'Direction', 'active', 'female', NULL, NULL),
  ('d6000000-0000-4000-8000-000000000103', 'HLDGUARD0000103', 'guardian', 'Fixture', 'Attente', 'pending_kyc', 'male', 'd6000000-0000-4000-8000-0000000000f1', NULL),
  ('d6000000-0000-4000-8000-000000000104', 'HLDTEACH0000104', 'teacher', 'Fixture', 'Desactive', 'disabled', 'male', NULL, NULL),
  ('d6000000-0000-4000-8000-000000000105', 'HLDTEACH0000105', 'teacher', 'Fixture', 'Supprime', 'pending_kyc', 'male', NULL, pg_catalog.now()),
  ('d6000000-0000-4000-8000-000000000106', 'HLDGUARD0000106', 'guardian', 'Fixture', 'Adulte', 'active', 'female', 'd6000000-0000-4000-8000-0000000000f2', NULL),
  ('d6000000-0000-4000-8000-000000000107', 'HLDGUARD0000107', 'guardian', 'Fixture', 'TuteurA', 'active', 'male', 'd6000000-0000-4000-8000-0000000000f3', NULL),
  ('d6000000-0000-4000-8000-000000000108', 'HLDGUARD0000108', 'guardian', 'Fixture', 'TuteurB', 'active', 'female', 'd6000000-0000-4000-8000-0000000000f3', NULL),
  ('d6000000-0000-4000-8000-000000000109', 'HLDTEACH0000109', 'teacher', 'Fixture', 'Actif', 'provisional_active', 'male', NULL, NULL);
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES ('d6000000-0000-4000-8000-000000000104', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
       ('d6000000-0000-4000-8000-000000000105', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
       ('d6000000-0000-4000-8000-000000000109', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);
INSERT INTO public.student_profiles (profile_id, student_type, titulaire_profile_id)
VALUES ('d6000000-0000-4000-8000-000000000106', 'autonomous', 'd6000000-0000-4000-8000-000000000106');

SELECT set_config('test.paris', (SELECT id FROM public.villes_ref WHERE nom = 'Paris' AND pays_code = 'FR' ORDER BY milliers DESC LIMIT 1)::text, true),
       set_config('test.lyon', (SELECT id FROM public.villes_ref WHERE nom = 'Lyon' AND pays_code = 'FR' ORDER BY milliers DESC LIMIT 1)::text, true);

CREATE FUNCTION pg_temp.en_tant(p_uid uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE sql AS $f$
  SELECT set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('test.uid', p_uid::text, true),
         set_config('request.jwt.claims', pg_catalog.json_build_object('app_metadata',
           pg_catalog.jsonb_build_object('role', p_role) || coalesce(pg_catalog.jsonb_build_object('household_id', p_foyer), '{}'::jsonb))::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.jsonb_build_object('role', p_role) || coalesce(pg_catalog.jsonb_build_object('household_id', p_foyer), '{}'::jsonb))::text, true);
$f$;

-- Un refus attendu : SQLSTATE ET message exacts.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $f$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'HLD ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR SQLERRM <> p_message THEN
      RAISE EXCEPTION 'HLD ROUGE : % (%, % au lieu de %, %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'HLD OK %', p_label;
END $f$;
GRANT EXECUTE ON FUNCTION pg_temp.en_tant(uuid, text, uuid), pg_temp.refus(text, text, text, text) TO authenticated, anon;

-- =====================================================================
-- (1) Le candidat enseignant : de vraies RPC, de bout en bout
-- =====================================================================
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT public.inviter_enseignant('hld-candidat@example.test');
RESET ROLE;
SELECT set_config('test.code',
  (SELECT code FROM public.invitations_enseignant WHERE email = 'hld-candidat@example.test'), true);
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000102', NULL);
SET LOCAL ROLE authenticated;
DO $c$
BEGIN
  IF public.inscrire_enseignant_invite(current_setting('test.code'), 'Hafsa', 'Candidate', 'female') ->> 'resultat' <> 'consommee' THEN
    RAISE EXCEPTION 'HLD ROUGE : le candidat n''a pas pu s''inscrire par invitation';
  END IF;
END
$c$;
RESET ROLE;
DO $c$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles
                  WHERE id = 'd6000000-0000-4000-8000-000000000102'
                    AND role = 'teacher' AND account_status = 'pending_kyc') THEN
    RAISE EXCEPTION 'HLD ROUGE : le candidat n''est pas un enseignant en attente de verification';
  END IF;
  RAISE NOTICE 'HLD OK un vrai candidat : enseignant pending_kyc, inscrit par invitation';
END
$c$;

-- Il cherche, puis il enregistre sa ville.
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000102', 'teacher');
SET LOCAL ROLE authenticated;
DO $c$
DECLARE
  v_id bigint;
  r jsonb;
BEGIN
  SELECT id INTO v_id FROM public.rechercher_villes('conakry', 'GN') ORDER BY milliers DESC LIMIT 1;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'HLD ROUGE : le candidat ne trouve pas Conakry';
  END IF;
  r := public.enregistrer_ma_ville(v_id);
  IF r ->> 'ville' IS NULL OR r ->> 'pays_code' <> 'GN' OR r ->> 'fuseau_iana' <> 'Africa/Conakry' THEN
    RAISE EXCEPTION 'HLD ROUGE : le candidat n''a pas son lieu (%)', r;
  END IF;
  IF public.mon_lieu() ->> 'fuseau_iana' <> 'Africa/Conakry' OR (public.mon_lieu() ->> 'verifie')::boolean THEN
    RAISE EXCEPTION 'HLD ROUGE : mon_lieu du candidat : % (non verifie attendu)', public.mon_lieu();
  END IF;
  RAISE NOTICE 'HLD OK le candidat pending_kyc cherche puis enregistre sa ville (Conakry, a verifier par la direction)';
END
$c$;
RESET ROLE;
DO $c$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.lieux l
                  WHERE l.profil_id = 'd6000000-0000-4000-8000-000000000102' AND l.fuseau_iana = 'Africa/Conakry' AND l.verifie_le IS NULL)
     OR (SELECT tp.timezone_iana FROM public.teacher_profiles tp WHERE tp.profile_id = 'd6000000-0000-4000-8000-000000000102') <> 'Africa/Conakry' THEN
    RAISE EXCEPTION 'HLD ROUGE : le lieu et le fuseau de la fiche du candidat';
  END IF;
  -- Rien d'autre n'a ete ecrit : un seul lieu, le sien.
  IF (SELECT pg_catalog.count(*) FROM public.lieux WHERE saisi_par = 'd6000000-0000-4000-8000-000000000102') <> 1 THEN
    RAISE EXCEPTION 'HLD ROUGE : le candidat a ecrit autre chose que son propre lieu';
  END IF;
  RAISE NOTICE 'HLD OK le lieu du candidat est le sien seulement, non verifie, fuseau de la fiche mis a jour';
END
$c$;

-- Rien d'autre n'est ouvert.
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000103', 'guardian', 'd6000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_ma_ville(current_setting('test.paris')::bigint)$$,
  '42501', 'ville non autorisee', 'un tuteur en attente de verification reste refuse');
RESET ROLE;
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000104', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_ma_ville(current_setting('test.paris')::bigint)$$,
  '42501', 'ville non autorisee', 'un enseignant desactive reste refuse');
RESET ROLE;
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000105', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_ma_ville(current_setting('test.paris')::bigint)$$,
  '42501', 'ville non autorisee', 'un candidat supprime reste refuse');
RESET ROLE;
-- Un jeton qui dit « teacher » sans que le profil le soit n'ouvre rien.
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000103', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_ma_ville(current_setting('test.paris')::bigint)$$,
  '42501', 'ville non autorisee', 'un jeton « teacher » sur un profil de tuteur en attente reste refuse');
RESET ROLE;
DO $c$
BEGIN
  IF EXISTS (SELECT 1 FROM public.lieux WHERE saisi_par IN (
       'd6000000-0000-4000-8000-000000000103', 'd6000000-0000-4000-8000-000000000104',
       'd6000000-0000-4000-8000-000000000105')) THEN
    RAISE EXCEPTION 'HLD ROUGE : un refus a quand meme ecrit un lieu';
  END IF;
  RAISE NOTICE 'HLD OK aucun lieu ecrit par les refus';
END
$c$;
-- L'etape pour les inscrits reste fermee au candidat (porte du routeur) : il passe par sa candidature.
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000105', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.mon_lieu_a_fournir()$$, '42501', 'lieu non autorise',
  'l etape pour les inscrits reste fermee a un compte non actif');
RESET ROLE;

-- L'adulte « pour moi » : guardian avec un foyer d'une personne, sans autre tuteur.
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000106', 'guardian', 'd6000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
DO $c$
DECLARE v_id bigint;
BEGIN
  SELECT id INTO v_id FROM public.rechercher_villes('marseille', 'FR') ORDER BY milliers DESC LIMIT 1;
  IF public.mon_lieu_a_fournir() ->> 'requis' <> 'true' THEN
    RAISE EXCEPTION 'HLD ROUGE : l adulte « pour moi » doit avoir une ville a fournir';
  END IF;
  IF public.enregistrer_ma_ville(v_id) ->> 'fuseau_iana' <> 'Europe/Paris'
     OR public.mon_lieu() ->> 'source' <> 'foyer' THEN
    RAISE EXCEPTION 'HLD ROUGE : l adulte « pour moi » n''a pas son lieu';
  END IF;
  RAISE NOTICE 'HLD OK l''adulte « pour moi » (guardian, foyer d''une personne) choisit sa ville';
END
$c$;
RESET ROLE;

-- Les deux tuteurs d'un foyer choisissent une ville (le foyer d'abord, un enseignant actif aussi).
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000107', 'guardian', 'd6000000-0000-4000-8000-0000000000f3');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.lyon')::bigint);
RESET ROLE;
SELECT pg_temp.en_tant('d6000000-0000-4000-8000-000000000109', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.lyon')::bigint);
RESET ROLE;

-- =====================================================================
-- (2) L'anonymisation efface le lieu
-- =====================================================================
DO $a$
BEGIN
  -- Le candidat et l'enseignant actif ont un lieu ; l'anonymisation de l'un
  -- efface le sien, pas celui de l'autre.
  IF NOT EXISTS (SELECT 1 FROM public.lieux WHERE profil_id = 'd6000000-0000-4000-8000-000000000109')
     OR NOT EXISTS (SELECT 1 FROM public.lieux WHERE foyer_id = 'd6000000-0000-4000-8000-0000000000f3') THEN
    RAISE EXCEPTION 'HLD ROUGE : les lieux de depart manquent';
  END IF;
  INSERT INTO private.lieux_reports (profil_id, reports) VALUES ('d6000000-0000-4000-8000-000000000109', 1)
    ON CONFLICT DO NOTHING;
  PERFORM private.cpt_anonymiser('d6000000-0000-4000-8000-000000000109');
  IF EXISTS (SELECT 1 FROM public.lieux WHERE profil_id = 'd6000000-0000-4000-8000-000000000109')
     OR EXISTS (SELECT 1 FROM private.lieux_reports WHERE profil_id = 'd6000000-0000-4000-8000-000000000109') THEN
    RAISE EXCEPTION 'HLD ROUGE : le lieu d''un enseignant anonymise est reste';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.lieux WHERE profil_id = 'd6000000-0000-4000-8000-000000000102')
     OR NOT EXISTS (SELECT 1 FROM public.lieux WHERE foyer_id = 'd6000000-0000-4000-8000-0000000000f3') THEN
    RAISE EXCEPTION 'HLD ROUGE : l''anonymisation d''un enseignant a efface le lieu d''un autre';
  END IF;
  RAISE NOTICE 'HLD OK l''anonymisation d''un enseignant efface son lieu et le rappel de report, pas ceux des autres';

  -- Un tuteur sur deux : le foyer garde son lieu (l'autre tuteur est encore actif).
  PERFORM private.cpt_anonymiser('d6000000-0000-4000-8000-000000000107');
  IF NOT EXISTS (SELECT 1 FROM public.lieux WHERE foyer_id = 'd6000000-0000-4000-8000-0000000000f3') THEN
    RAISE EXCEPTION 'HLD ROUGE : le lieu du foyer a ete efface alors qu''un tuteur reste actif';
  END IF;
  RAISE NOTICE 'HLD OK un tuteur parti, l''autre reste : le lieu du foyer est garde';

  -- Le dernier tuteur actif part : la ligne du foyer part avec lui.
  PERFORM private.cpt_anonymiser('d6000000-0000-4000-8000-000000000108');
  IF EXISTS (SELECT 1 FROM public.lieux WHERE foyer_id = 'd6000000-0000-4000-8000-0000000000f3') THEN
    RAISE EXCEPTION 'HLD ROUGE : le lieu du foyer est reste apres le depart du dernier tuteur';
  END IF;
  RAISE NOTICE 'HLD OK le dernier tuteur actif anonymise : la ligne du foyer est effacee';
  -- L'adulte « pour moi », seul dans son foyer : son lieu part avec lui.
  PERFORM private.cpt_anonymiser('d6000000-0000-4000-8000-000000000106');
  IF EXISTS (SELECT 1 FROM public.lieux WHERE foyer_id = 'd6000000-0000-4000-8000-0000000000f2') THEN
    RAISE EXCEPTION 'HLD ROUGE : le lieu de l''adulte « pour moi » est reste';
  END IF;
  RAISE NOTICE 'HLD OK l''adulte « pour moi » anonymise : son lieu est efface';
END
$a$;

-- Les droits n'ont pas bouge.
DO $d$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.enregistrer_ma_ville(bigint)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cpt_anonymiser(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.cpt_anonymiser(uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HLD ROUGE : les droits d''execution ont change';
  END IF;
  RAISE NOTICE 'HLD OK droits d''execution inchanges';
END
$d$;

ROLLBACK;
