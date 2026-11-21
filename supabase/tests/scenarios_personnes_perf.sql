-- PERSONNES-PERF : migrations 20261130968000_personnes_perf.sql et 20261130968500_personnes_perf_lectures.sql.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le scenario charge les donnees fictives a
-- l'echelle (fixtures/personnes_perf_volume.sql) et annule tout a la fin. Chaque controle leve
-- 'PERSONNES-PERF ROUGE : ...' s'il echoue.
--   1. com_non_lus_par_objet rend, pour chaque compte, exactement les fils a non-lus de com_lister_fils (memes fils,
--      memes comptes, meme ordre) : memes droits, aucun compte d'un fil invisible.
--   2. Sans appelant reconnu, refus 42501, comme com_lister_fils ; anon ne peut pas l'executer.
--   3. private.perf_bloquee_salle3(c) vaut, pour chaque candidature, ce que lisait l'ancien compteur dans
--      candidature_controles_salle3(c) ; le compteur « bloquees » de lister_candidatures egale l'ancien calcul.
--   4. Les aides passees en plpgsql gardent leurs droits, et aucune n'est executable par anon.
-- La preuve octet pour octet des reponses avant / apres (22 lectures x 6 comptes) est dans
-- supabase/tests/perf/personnes_perf_avant_apres.sh.
\set ON_ERROR_STOP on
\o /dev/null
BEGIN;
\ir fixtures/personnes_perf_volume.sql

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  v := CASE WHEN p_id IS NULL THEN '{}'
            ELSE json_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                                   'app_metadata', json_build_object('role', p_role))::text END;
  PERFORM set_config('request.jwt.claims', v, true);
  PERFORM set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM set_config('test.jwt', v, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERSONNES-PERF ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- La projection de com_lister_fils que doit rendre com_non_lus_par_objet.
CREATE FUNCTION pg_temp.projection(p_fils jsonb) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'fil', f -> 'id', 'type', f -> 'objet' -> 'type', 'objet', f -> 'objet' -> 'id',
           'non_lus', f -> 'non_lus') ORDER BY o), '[]'::jsonb)
  FROM jsonb_array_elements(p_fils) WITH ORDINALITY AS t(f, o)
  WHERE (f ->> 'non_lus')::int > 0;
$$;

-- Le compteur « bloquees » tel que lister_candidatures le calculait avant 20261130968500.
CREATE FUNCTION pg_temp.bloquee_avant(c public.candidatures) RETURNS boolean
LANGUAGE sql AS $$
  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements(private.candidature_controles_salle3(c)) AS k(e)
     WHERE k.e ->> 'nom' IN ('paiement_compatible', 'profil_unique')
       AND NOT coalesce((k.e ->> 'valeur')::boolean, false));
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.projection(jsonb)
  TO authenticated, anon;

-- 1. Memes fils, memes comptes, meme ordre, pour chaque sorte de compte.
SET ROLE authenticated;
DO $$
DECLARE
  q record;
  v_liste jsonb;
  v_non_lus jsonb;
  v_avec integer := 0;
BEGIN
  FOR q IN SELECT * FROM (VALUES
      ('9e900000-0000-4000-8000-0000000000d1'::uuid, 'admin', 'direction (exception de genre)'),
      ('9e900000-0000-4000-8000-0000000000d2'::uuid, 'admin', 'direction (femme)'),
      ('9e9c0000-0000-4000-8000-000000000001'::uuid, 'teacher', 'candidat'),
      ('9e9c0000-0000-4000-8000-000000000004'::uuid, 'teacher', 'candidate'),
      ('9e9c0000-0000-4000-8000-000000000011'::uuid, 'teacher', 'enseignant actif'),
      ('9e9e0000-0000-4000-8000-000000000001'::uuid, 'guardian', 'tuteur'),
      ('9e9c0000-0000-4000-8000-000000000636'::uuid, 'guardian', 'famille candidate')) AS t(id, role, label) LOOP
    PERFORM pg_temp.qui(q.id, q.role);
    BEGIN
      v_liste := public.com_lister_fils();
    EXCEPTION WHEN insufficient_privilege THEN
      v_liste := NULL;
    END;
    BEGIN
      v_non_lus := public.com_non_lus_par_objet();
    EXCEPTION WHEN insufficient_privilege THEN
      v_non_lus := NULL;
    END;
    PERFORM pg_temp.vrai((v_liste IS NULL) = (v_non_lus IS NULL), q.label || ' : meme refus');
    IF v_liste IS NOT NULL THEN
      PERFORM pg_temp.vrai(v_non_lus = pg_temp.projection(v_liste),
        q.label || ' : non-lus = projection de com_lister_fils (' || jsonb_array_length(v_non_lus) || ' fils)');
      IF jsonb_array_length(v_non_lus) > 0 THEN v_avec := v_avec + 1; END IF;
    END IF;
  END LOOP;
  PERFORM pg_temp.vrai(v_avec >= 3, 'au moins trois comptes ont des non-lus (le controle porte)');

  -- Un message lu fait disparaitre la ligne ; un message recu la fait apparaitre, dans les deux lectures.
  PERFORM pg_temp.qui('9e900000-0000-4000-8000-0000000000d2', 'admin');
  PERFORM public.com_marquer_lu((public.com_non_lus_par_objet() -> 0 ->> 'fil')::uuid);
  PERFORM pg_temp.vrai(public.com_non_lus_par_objet() = pg_temp.projection(public.com_lister_fils()),
    'apres une lecture, toujours la projection');
END $$;

-- 2. Refus sans appelant ; aucun droit pour anon.
DO $$
BEGIN
  PERFORM pg_temp.qui(NULL, NULL);
  BEGIN
    PERFORM public.com_non_lus_par_objet();
    RAISE EXCEPTION 'PERSONNES-PERF ROUGE : sans appelant, aucun refus';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK sans appelant : 42501';
  END;
END $$;
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.com_non_lus_par_objet()', 'EXECUTE'),
  'anon ne peut pas lire les non-lus');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.com_fil_non_lus(uuid,uuid,text,uuid)', 'EXECUTE'),
  'com_fil_non_lus reste privee');

-- 3. Le compteur « bloquees ».
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidatures c WHERE private.perf_bloquee_salle3(c) IS DISTINCT FROM pg_temp.bloquee_avant(c)) = 0,
  'perf_bloquee_salle3 = ancien calcul, pour chaque candidature');
SELECT pg_temp.vrai(
  (SELECT count(DISTINCT private.perf_bloquee_salle3(c)) FROM public.candidatures c WHERE c.etape = 'verifications') = 2,
  'des candidatures en verifications bloquees ET non bloquees (le controle porte)');
-- L'ancien calcul (lu en super-utilisateur : candidature_controles_salle3 est privee), puis la liste en direction.
SELECT count(*) AS bloquees_avant FROM public.candidatures c
 WHERE c.issue = 'en_cours' AND NOT c.en_pause
   AND (coalesce(c.restreinte, false) OR (c.etape = 'verifications' AND pg_temp.bloquee_avant(c))) \gset
SELECT pg_temp.qui('9e900000-0000-4000-8000-0000000000d1', 'admin');
SET ROLE authenticated;
SELECT pg_temp.vrai(
  (public.lister_candidatures('{}', 'activite', 1) -> 'compteursAlertes' ->> 'bloquees')::int = :bloquees_avant,
  'compteur bloquees de la liste = ancien calcul (' || :bloquees_avant || ')');
RESET ROLE;

-- 4. Droits des aides.
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM unnest(ARRAY[
    'private.com_participant(text,uuid,text,uuid)', 'private.com_objet(text,uuid)', 'private.com_paires(text,uuid)',
    'private.com_candidature_lisible(uuid,uuid)', 'private.com_est_partie(uuid,text,uuid,text,text,uuid)',
    'private.entretien_cote_permis(uuid,public.gender)', 'private.praxis_est_officiel(uuid)',
    'private.com_profil_valide(uuid,text)', 'private.com_est_mineur(uuid)', 'private.com_foyer_valide(uuid)',
    'app_private.compte_candidat_hors_portee(uuid)', 'public.kyc_super_admin_exception_active()',
    'private.perf_bloquee_salle3(public.candidatures)']) AS f
  WHERE has_function_privilege('anon', f, 'EXECUTE')), 'aucune aide executable par anon');

\o
SELECT 'PERSONNES-PERF : tous les controles sont verts' AS bilan;
ROLLBACK;
