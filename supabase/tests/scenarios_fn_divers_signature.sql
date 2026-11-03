-- FN-DIVERS, FN-102 (03/11/2026 ; migration 20261108400000) : la signature du
-- contrat enseignant est liee a l'identite connectee.
--
--   1. personne ne signe au nom d'un autre compte : ni par une insertion
--      directe (refus nomme `acces_signature_refusee`), ni un tuteur par la RPC ;
--   2. le nom signe est celui du compte, quel que soit le nom envoye, par la
--      RPC comme par une insertion directe ;
--   3. un compte sans nom ne signe pas (`nom_compte_vide`).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin. Les appels se font en `authenticated`.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un refus attendu, par SQLSTATE et par message.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR SQLERRM <> p_message THEN
      RAISE EXCEPTION 'ROUGE : % (% « % » au lieu de % « % »)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated',
  'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text),
  pg_temp.qui(uuid, text) TO authenticated;

INSERT INTO auth.users (id, email) VALUES
  ('f1020000-0000-4000-8000-000000000001', 'fn102-t1@example.test'),
  ('f1020000-0000-4000-8000-000000000002', 'fn102-t2@example.test'),
  ('f1020000-0000-4000-8000-000000000003', 'fn102-t3@example.test'),
  ('f1020000-0000-4000-8000-000000000011', 'fn102-p1@example.test');
INSERT INTO public.households (id, timezone) VALUES ('f1020000-0000-4000-8000-000000000101', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  ('f1020000-0000-4000-8000-000000000001', 'FN102-T1', 'teacher', NULL, 'Amina', 'Diallo', 'female', 'pending_kyc'),
  ('f1020000-0000-4000-8000-000000000002', 'FN102-T2', 'teacher', NULL, 'Moussa', 'Sow', 'male', 'pending_kyc'),
  ('f1020000-0000-4000-8000-000000000003', 'FN102-T3', 'teacher', NULL, '  ', '', 'male', 'pending_kyc'),
  ('f1020000-0000-4000-8000-000000000011', 'FN102-P1', 'guardian', 'f1020000-0000-4000-8000-000000000101',
   'Tuteur', 'Foyer', 'female', 'active');

SELECT pg_catalog.set_config('test.version',
  (SELECT t.version FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current), true);
SELECT pg_temp.vrai(pg_catalog.current_setting('test.version') <> '', '0 un contrat enseignant courant existe');

SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------
-- 1. Au nom d'un autre compte : refuse, avec le refus nomme.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('f1020000-0000-4000-8000-000000000001', 'teacher');
SELECT pg_temp.refus($q$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version, signer_name)
  VALUES ('f1020000-0000-4000-8000-000000000002', 'teacher_nda', current_setting('test.version'), 'Moussa Sow')$q$,
  '42501', 'acces_signature_refusee',
  '1.1 Amina ne signe pas, par insertion directe, le contrat au nom du compte de Moussa');
SELECT pg_temp.qui('f1020000-0000-4000-8000-000000000011', 'guardian');
SELECT pg_temp.refus($q$SELECT public.signer_contrat(current_setting('test.version'), 'Amina Diallo')$q$,
  '42501', 'acces_signature_refusee',
  '1.2 un tuteur ne signe pas le contrat enseignant par la RPC');
SELECT pg_temp.refus($q$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version, signer_name)
  VALUES ('f1020000-0000-4000-8000-000000000001', 'teacher_nda', current_setting('test.version'), 'Amina Diallo')$q$,
  '42501', 'acces_signature_refusee',
  '1.3 un tuteur ne signe pas, par insertion directe, au nom d''une enseignante');

-- ------------------------------------------------------------------
-- 2. Le nom signe est celui du compte, quel que soit le nom envoye.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('f1020000-0000-4000-8000-000000000001', 'teacher');
SELECT pg_temp.vrai(
  (public.signer_contrat(current_setting('test.version'), 'Quelqu''un d''autre')).signer_name = 'Amina Diallo',
  '2.1 RPC : « Quelqu''un d''autre » envoye, « Amina Diallo » signe (nom du compte)');
SELECT pg_temp.qui('f1020000-0000-4000-8000-000000000002', 'teacher');
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version, signer_name)
VALUES ('f1020000-0000-4000-8000-000000000002', 'teacher_nda', current_setting('test.version'), 'Nom invente');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT c.signer_name FROM public.contract_acceptances c
    WHERE c.profile_id = 'f1020000-0000-4000-8000-000000000002' AND c.contract_kind = 'teacher_nda') = 'Moussa Sow'
  AND (SELECT c.signed_sha256 FROM public.contract_acceptances c
        WHERE c.profile_id = 'f1020000-0000-4000-8000-000000000002' AND c.contract_kind = 'teacher_nda')
      = (SELECT t.sha256 FROM public.contract_texts t
          WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current),
  '2.2 insertion directe : « Nom invente » envoye, « Moussa Sow » signe, empreinte du texte courant');
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------
-- 3. Un compte sans nom ne signe pas.
-- ------------------------------------------------------------------
SELECT pg_temp.qui('f1020000-0000-4000-8000-000000000003', 'teacher');
SELECT pg_temp.refus($q$SELECT public.signer_contrat(current_setting('test.version'), 'Un nom saisi')$q$,
  'P0001', 'nom_compte_vide',
  '3.1 un compte sans prenom ni nom ne signe pas, meme avec un nom saisi');

RESET ROLE;
DO $fin$ BEGIN RAISE NOTICE 'FN-102 : scenario vert'; END $fin$;
ROLLBACK;
