-- SALLE-2-ENTRETIEN (07/11/2026) : les langues d'un creneau sont celles que
-- le candidat peut declarer (20261119200100). Prouve :
--   l1. « francais » (referentiel) et « pt » s'ouvrent ; « xx » est refuse ;
--   l2. un candidat « francais » voit le creneau « francais » ;
--   l3. la direction lit la meme liste que la source ; le candidat ne la lit
--       pas ;
--   l4. contre-epreuve : sans 20261119200100, l1 est ROUGE (V1-b refusait
--       « francais »).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'LANGUES ROUGE : %', p_label;
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
-- En plpgsql : resolue a l'appel, pour que la contre-epreuve tombe sur l1.
CREATE FUNCTION pg_temp.source() RETURNS text[]
LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN RETURN private.langues_entretien(); END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.source() TO authenticated;

-- D : direction homme ; C : candidat homme, francais seulement.
INSERT INTO auth.users (id, email) VALUES
 ('7e400000-0000-4000-8000-0000000000d1', 'lg-d@test.invalid'),
 ('7e400000-0000-4000-8000-0000000000c1', 'lg-c@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e400000-0000-4000-8000-0000000000d1', 'RA-26-7401', 'admin', NULL, 'Direction', 'Lg', 'active', 'male'),
 ('7e400000-0000-4000-8000-0000000000c1', 'RA-26-7402', 'teacher', NULL, 'Candidat', 'Lg', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7e400000-0000-4000-8000-000000000101', 'enseignant', '7e400000-0000-4000-8000-0000000000c1', 'male',
  'Fixture langues', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source) VALUES
 ('7e400000-0000-4000-8000-000000000101', 'salle-examen-2',
  '{"langueMaternelle": "francais", "languesExplication": []}', 'candidat');
-- La regle des fondateurs n'est pas l'objet de ce scenario.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';

SET LOCAL ROLE authenticated;
DO $l1$
DECLARE
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e400000-0000-4000-8000-0000000000d1', 'admin');
  v_r := public.ouvrir_creneau_entretien('male', now() + interval '2 days', 45, ARRAY['francais'],
           ARRAY['7e400000-0000-4000-8000-0000000000d1']::uuid[]);
  PERFORM pg_temp.vrai(v_r ? 'creneauId', 'l1. un creneau « francais » s''ouvre : ' || v_r::text);
  PERFORM set_config('lg.s1', v_r ->> 'creneauId', true);
  v_r := public.ouvrir_creneau_entretien('male', now() + interval '3 days', 45, ARRAY['pt'],
           ARRAY['7e400000-0000-4000-8000-0000000000d1']::uuid[]);
  PERFORM pg_temp.vrai(v_r ? 'creneauId', 'l1. un creneau « pt » s''ouvre : ' || v_r::text);
  v_r := public.ouvrir_creneau_entretien('male', now() + interval '4 days', 45, ARRAY['xx'],
           ARRAY['7e400000-0000-4000-8000-0000000000d1']::uuid[]);
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'langues_invalides', 'l1. « xx » est refuse : ' || v_r::text);

  PERFORM pg_temp.vrai(public.langues_creneaux_entretien() = pg_temp.source()
                       AND 'francais' = ANY (public.langues_creneaux_entretien()),
    'l3. la direction lit la meme liste que la source');

  PERFORM pg_temp.en_tant_que('7e400000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai(
    (SELECT pg_catalog.array_agg(creneau_id) FROM public.creneaux_entretien_disponibles())
      = ARRAY[current_setting('lg.s1')::uuid],
    'l2. le candidat « francais » voit le creneau « francais », pas le « pt »');
  BEGIN
    PERFORM public.langues_creneaux_entretien();
    RAISE EXCEPTION 'LANGUES ROUGE : l3. le candidat a lu la liste de la direction';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK l3. le candidat ne lit pas la liste de la direction';
  END;
END
$l1$;
RESET ROLE;

ROLLBACK;
