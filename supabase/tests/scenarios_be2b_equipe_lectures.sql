-- BE-2b (pilote, 17/11/2026) : les lectures de l'ecran « Equipe » (migration 20261129790000). Cas couverts :
--  p : `lister_personnes_mission` ne rend que les comptes actifs des roles admis par accorder_mission (accountant,
--      associe) dont le genre est connu, avec nom, role et cote ; jamais un compte en attente, une direction, un
--      tuteur, un eleve ; refusee a tout autre que la direction active ; anon sans droit ;
--  g : `lister_gestes_mission` rend la liste fermee du serveur ; refusee aux autres ;
--  a : `lister_attributions` porte maintenant le nom, le role et le cote de la personne, sans changer le reste.
-- Chaque controle leve 'EQUIPE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
-- Ce scenario suppose le role `associe` (20261129770000 et 20261129780000, BE-2a-2) installe.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'EQUIPE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$ SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true); $$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb; $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal2') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_aal text DEFAULT 'aal2', p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  EXECUTE 'RESET ROLE';
  IF v_passe THEN
    RAISE EXCEPTION 'EQUIPE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'EQUIPE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2c0000-0000-4000-8000-0000000000' || CASE p_n WHEN 'a1' THEN '01' WHEN 't1' THEN '02' WHEN 'g1' THEN '03'
    WHEN 'ac' THEN '11' WHEN 'as' THEN '12' WHEN 'af' THEN '13' WHEN 'ax' THEN '14' END)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.garde(text, jsonb),
  pg_temp.lu(text), pg_temp.en(uuid, text, text, text), pg_temp.refus_en(uuid, text, text, text, text, text, text),
  pg_temp.u(text) TO authenticated, anon;

-- a1 direction ; t1 enseignant en attente ; g1 tuteur ; ac comptable actif ; as associe actif (homme) ; af associe actif
-- (femme) ; ax associe SANS genre.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(s), 'be2b-' || s || '@test.invalid' FROM unnest(ARRAY['a1','t1','g1','ac','as','af','ax']) s;
INSERT INTO public.households (id, timezone) VALUES ('5b2cffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a1'), 'B2C-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('t1'), 'B2C-ENS-0001', 'teacher', NULL, 'Enseignant', 'Attente', 'pending_kyc', 'male'),
 (pg_temp.u('g1'), 'B2C-TUT-0001', 'guardian', '5b2cffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai', 'active', 'female'),
 (pg_temp.u('ac'), 'B2C-CPT-0001', 'accountant', NULL, 'Comptable', 'Actif', 'active', 'male'),
 (pg_temp.u('as'), 'B2C-ASS-0001', 'associe', NULL, 'Karim', 'Associe', 'active', 'male'),
 (pg_temp.u('af'), 'B2C-ASS-0002', 'associe', NULL, 'Salma', 'Associee', 'active', 'female'),
 (pg_temp.u('ax'), 'B2C-ASS-0003', 'associe', NULL, 'Sans', 'Genre', 'active', NULL);

-- (p) Qui peut recevoir une mission
SELECT pg_temp.garde('pers', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_personnes_mission()$$));
SELECT pg_temp.vrai(
  (SELECT array_agg(e ->> 'nom' ORDER BY e ->> 'nom') FROM jsonb_array_elements(pg_temp.lu('pers')) e)
     = ARRAY['Comptable Actif', 'Karim Associe', 'Salma Associee'],
  'p1 : la liste ne contient que les comptes actifs comptable et associe de genre connu (ni l''enseignant en attente, ni la direction, ni le tuteur, ni l''associe sans genre)');
SELECT pg_temp.vrai(
  (SELECT e ->> 'role' || '/' || (e ->> 'cote') FROM jsonb_array_elements(pg_temp.lu('pers')) e WHERE e ->> 'nom' = 'Karim Associe') = 'associe/male'
  AND (SELECT e ->> 'role' FROM jsonb_array_elements(pg_temp.lu('pers')) e WHERE e ->> 'nom' = 'Comptable Actif') = 'accountant'
  AND (SELECT e ->> 'id' FROM jsonb_array_elements(pg_temp.lu('pers')) e WHERE e ->> 'nom' = 'Karim Associe') = pg_temp.u('as')::text,
  'p2 : chaque ligne porte l''identifiant, le role et le cote');
SELECT pg_temp.refus_en(pg_temp.u('as'), 'associe', $$SELECT public.lister_personnes_mission()$$,
  '42501', 'p3 : un associe ne lit pas la liste des personnes', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('t1'), 'teacher', $$SELECT public.lister_personnes_mission()$$,
  '42501', 'p4 : un enseignant ne la lit pas', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('g1'), 'guardian', $$SELECT public.lister_gestes_mission()$$,
  '42501', 'p5 : un tuteur ne lit pas les gestes', 'aal1');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.lister_personnes_mission()$$,
  '42501', 'p6 : sans session, refus', 'aal1', 'anon');

-- (g) Les gestes
SELECT pg_temp.garde('gestes', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_gestes_mission()$$));
SELECT pg_temp.vrai(
  pg_temp.lu('gestes') = pg_catalog.to_jsonb(private.mission_gestes_ouverts())
  AND pg_temp.lu('gestes') @> '["lire", "voir_contact", "planifier_entretien"]'::jsonb
  AND jsonb_array_length(pg_temp.lu('gestes')) = cardinality(private.mission_gestes_ouverts()),
  'g1 : la liste rendue est exactement la liste fermee du serveur');

-- (a) lister_attributions : le nom, le role, le cote
SELECT pg_temp.garde('m1', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Lecture', ARRAY['lire'], '11111111-0000-4000-8000-0000000000c1'::uuid))$$));
SELECT pg_temp.garde('att', pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT pg_catalog.to_jsonb(public.accorder_mission(%L::uuid, %L::uuid, ''{}''::jsonb, NULL, NULL, ''22222222-0000-4000-8000-0000000000c1''::uuid))',
  pg_temp.u('as'), pg_temp.lu('m1') #>> '{}')));
SELECT pg_temp.garde('attrs', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_attributions('{}'::jsonb)$$));
SELECT pg_temp.vrai(
  jsonb_array_length(pg_temp.lu('attrs')) = 1
  AND pg_temp.lu('attrs') #>> '{0,nomProfil}' = 'Karim Associe'
  AND pg_temp.lu('attrs') #>> '{0,roleProfil}' = 'associe'
  AND pg_temp.lu('attrs') #>> '{0,coteProfil}' = 'male'
  AND pg_temp.lu('attrs') #>> '{0,profil}' = pg_temp.u('as')::text
  AND pg_temp.lu('attrs') #>> '{0,mission}' = 'Lecture'
  AND (pg_temp.lu('attrs') #>> '{0,active}')::boolean,
  'a1 : l''attribution porte le nom, le role et le cote de la personne, et garde ses colonnes d''avant');
SELECT pg_temp.refus_en(pg_temp.u('as'), 'associe', $$SELECT public.lister_attributions('{}'::jsonb)$$,
  '42501', 'a2 : un associe ne lit pas les attributions', 'aal1');

SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.lister_personnes_mission()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lister_gestes_mission()', 'EXECUTE')
  AND (SELECT bool_and(NOT has_function_privilege(r, 'public.lister_personnes_mission()', 'EXECUTE'))
         FROM unnest(ARRAY['service_role', 'agent_ro']) r),
  'd1 : anon, service_role et agent_ro n''ont aucun droit sur les lectures nouvelles');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 10, 'z : au moins 10 controles passes');
ROLLBACK;
