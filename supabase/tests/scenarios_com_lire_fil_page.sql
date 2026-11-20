-- PE-D1 MESSAGERIE-FIABLE (20/11/2026) : public.com_lire_fil_page, migration 20261130960000.
-- Prouve :
--   0. droits : anon n'execute pas, authenticated execute ; com_fil_json n'a pas bouge ;
--   1. un fil de 300 messages se lit par pages de 50, du plus recent au plus ancien, sans trou ni doublon,
--      chaque page du plus ancien au plus recent, `plus_anciens` faux a la derniere ;
--   2. la limite est bornee (0 -> 1, 1000 -> 200) ;
--   3. la cle d'envoi n'est rendue que pour les messages de l'appelant, et c'est la sienne ;
--   4. une cle rejouee ne fait pas de second message (la page le prouve) ;
--   5. un appelant hors du fil recoit NULL ; un `p_avant` inconnu rend une page vide ;
--   6. le reste du fil (parties, peut_ecrire, non_lus) est celui de com_lire_fil.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'FIL-PAGE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text) TO authenticated;

-- 0. Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.com_lire_fil_page(uuid,uuid,integer)', 'execute')
  AND has_function_privilege('authenticated', 'public.com_lire_fil_page(uuid,uuid,integer)', 'execute'),
  '0. anon n''execute pas, authenticated execute');

INSERT INTO auth.users (id, email) VALUES
 ('7d500000-0000-4000-8000-0000000000a1', 'fp-a1@test.invalid'),
 ('7d500000-0000-4000-8000-0000000000c1', 'fp-c1@test.invalid'),
 ('7d500000-0000-4000-8000-0000000000c2', 'fp-c2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7d500000-0000-4000-8000-0000000000a1', 'RA-26-7501', 'admin', NULL, 'Fictive', 'FP', 'active', 'female'),
 ('7d500000-0000-4000-8000-0000000000c1', 'RA-26-7502', 'teacher', NULL, 'Fictive', 'FPun', 'pending_kyc', 'female'),
 ('7d500000-0000-4000-8000-0000000000c2', 'RA-26-7503', 'teacher', NULL, 'Fictive', 'FPdeux', 'pending_kyc', 'female');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7d500000-0000-4000-8000-000000000101', 'enseignant', '7d500000-0000-4000-8000-0000000000c1', 'female',
  'Fixture FP un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7d500000-0000-4000-8000-000000000102', 'enseignant', '7d500000-0000-4000-8000-0000000000c2', 'female',
  'Fixture FP deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

SET LOCAL ROLE authenticated;

-- 1 a 4 : le candidat C1 ouvre son fil ; 150 messages de lui, 150 de la direction, alternes.
DO $remplir$
DECLARE
  v_id uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7d500000-0000-4000-8000-0000000000c1', 'teacher');
  v_id := (public.com_ouvrir_conversation('candidature', '7d500000-0000-4000-8000-000000000101', 'administration') ->> 'id')::uuid;
  PERFORM set_config('test.fil', v_id::text, true);
END
$remplir$;

-- Le plafond de 30 messages par jour du candidat est leve ici en ecrivant directement (fixture, role proprietaire).
RESET ROLE;
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
SELECT current_setting('test.fil')::uuid,
       CASE WHEN i % 2 = 0 THEN '7d500000-0000-4000-8000-0000000000c1'::uuid
            ELSE '7d500000-0000-4000-8000-0000000000a1'::uuid END,
       ('7d500000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'Message fictif ' || i,
       timestamptz '2026-11-01 08:00:00+00' + make_interval(mins => i)
  FROM generate_series(1, 300) AS i;
SET LOCAL ROLE authenticated;

DO $pages$
DECLARE
  v_id uuid := current_setting('test.fil')::uuid;
  v_page jsonb;
  v_avant uuid := NULL;
  v_vus text[] := ARRAY[]::text[];
  v_n integer := 0;
  v_textes text[];
BEGIN
  PERFORM pg_temp.en_tant_que('7d500000-0000-4000-8000-0000000000c1', 'teacher');
  LOOP
    v_page := public.com_lire_fil_page(v_id, v_avant, 50);
    v_n := v_n + 1;
    SELECT array_agg(m ->> 'texte' ORDER BY o) INTO v_textes
      FROM jsonb_array_elements(v_page -> 'messages') WITH ORDINALITY AS e(m, o);
    PERFORM pg_temp.vrai(jsonb_array_length(v_page -> 'messages') = 50,
      '1. page ' || v_n || ' : 50 messages');
    PERFORM pg_temp.vrai(v_textes[1] = 'Message fictif ' || (300 - 50 * v_n + 1)
      AND v_textes[50] = 'Message fictif ' || (300 - 50 * (v_n - 1)),
      '1. page ' || v_n || ' : du plus ancien au plus recent, a la suite de la precedente');
    v_vus := v_vus || v_textes;
    EXIT WHEN NOT (v_page ->> 'plus_anciens')::boolean;
    v_avant := (v_page #>> '{messages,0,id}')::uuid;
    PERFORM pg_temp.vrai(v_n < 10, '1. la lecture s''arrete');
  END LOOP;
  PERFORM pg_temp.vrai(v_n = 6, '1. 300 messages = 6 pages, plus_anciens faux a la sixieme');
  PERFORM pg_temp.vrai((SELECT count(DISTINCT x) FROM unnest(v_vus) x) = 300,
    '1. aucun trou, aucun doublon');

  -- 2. Bornes.
  PERFORM pg_temp.vrai(jsonb_array_length(public.com_lire_fil_page(v_id, NULL, 0) -> 'messages') = 1
    AND jsonb_array_length(public.com_lire_fil_page(v_id, NULL, 1000) -> 'messages') = 200
    AND jsonb_array_length(public.com_lire_fil_page(v_id) -> 'messages') = 50,
    '2. limite bornee de 1 a 200, 50 par defaut');

  -- 3. Cle d'envoi : seulement les miens.
  v_page := public.com_lire_fil_page(v_id, NULL, 200);
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(v_page -> 'messages') m
       WHERE (m #>> '{auteur,est_soi}')::boolean <> (m ? 'cle_idempotence')),
    '3. une cle sur chaque message de soi, aucune sur ceux des autres');
  PERFORM pg_temp.vrai((v_page #>> '{messages,199,cle_idempotence}') = '7d500000-0000-4000-8000-000000000300',
    '3. la cle rendue est celle de l''envoi');

  -- 4. Une cle rejouee : un seul message.
  PERFORM public.com_envoyer_message(v_id, 'Envoi rejoue', '7d500000-0000-4000-8000-00000000f001');
  PERFORM public.com_envoyer_message(v_id, 'Envoi rejoue', '7d500000-0000-4000-8000-00000000f001');
  v_page := public.com_lire_fil_page(v_id, NULL, 3);
  PERFORM pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements(v_page -> 'messages') m
                         WHERE m ->> 'texte' = 'Envoi rejoue') = 1
    AND (v_page #>> '{messages,2,cle_idempotence}') = '7d500000-0000-4000-8000-00000000f001',
    '4. une cle rejouee ne fait qu''un message, rendu avec sa cle');

  -- 6. Le reste du fil est celui de com_lire_fil.
  PERFORM pg_temp.vrai((v_page - 'messages' - 'plus_anciens') = (public.com_lire_fil(v_id) - 'messages'),
    '6. hors messages, le fil rendu est celui de com_lire_fil');

  -- 5. Un p_avant inconnu.
  v_page := public.com_lire_fil_page(v_id, '7d500000-0000-4000-8000-00000000dead', 50);
  PERFORM pg_temp.vrai(jsonb_array_length(v_page -> 'messages') = 0
    AND NOT (v_page ->> 'plus_anciens')::boolean,
    '5. un message inconnu comme repere : page vide, rien de plus ancien');

  -- 3 bis. Cote direction : les cles du candidat ne lui sont pas rendues.
  PERFORM pg_temp.en_tant_que('7d500000-0000-4000-8000-0000000000a1', 'admin');
  v_page := public.com_lire_fil_page(v_id, NULL, 200);
  PERFORM pg_temp.vrai(v_page IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(v_page -> 'messages') m
       WHERE (m #>> '{auteur,est_soi}')::boolean IS NOT TRUE AND m ? 'cle_idempotence'),
    '3. la direction ne recoit aucune cle du candidat');

  -- 5. Un autre candidat : rien.
  PERFORM pg_temp.en_tant_que('7d500000-0000-4000-8000-0000000000c2', 'teacher');
  PERFORM pg_temp.vrai(public.com_lire_fil_page(v_id, NULL, 50) IS NULL,
    '5. un autre candidat ne lit rien du fil');
END
$pages$;

ROLLBACK;
