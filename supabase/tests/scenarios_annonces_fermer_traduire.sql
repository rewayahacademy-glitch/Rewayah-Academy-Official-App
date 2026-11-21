-- ANNONCES-SERVEUR (21/11/2026) : fermer, rouvrir, paginer et traduire les annonces
-- (migration 20261130976000_annonces_fermer_traduire.sql ; DECISION-ANNONCES-NOTIFS-2026-11-21.md, section 2).
--
-- Prouve :
--   1. a l'envoi, chaque annonce generale entre en file de traduction (fr, en, ar) ;
--   2. le travailleur (service_role) reserve, consigne : la langue d'ecriture devient « originale »,
--      les autres « faite » ; un echec se rejoue plus tard, jamais tout de suite ;
--   3. le lecteur recoit le texte dans la langue demandee, puis dans celle de son compte, l'original a
--      cote ; sans traduction, l'original (jamais un vide), traduite = faux ;
--   4. fermer : l'annonce quitte le fil « non fermees », reste dans « toutes » avec fermee = vrai ;
--      fermer deux fois et rouvrir deux fois ne changent rien de plus ; rouvrir la rend au fil ;
--      la fermeture d'une personne ne ferme rien chez une autre ;
--   5. pagination : 20 par defaut, curseur `suite`, derniere page sans suite, 50 au plus ;
--   6. la forme sans argument rend toujours le fil (fermees comprises) ;
--   7. refus : anon (aucun droit), mineur (42501 : ni fil, ni fermeture), annonce non destinee (42501),
--      client sur les fonctions du travailleur (aucun droit), tables fermees au client.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ANN-FERMER ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ANN-FERMER OK %', p_label;
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
CREATE FUNCTION pg_temp.en_tant_que_service() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('request.jwt.claims', '{"role":"service_role"}', true);
  PERFORM set_config('test.jwt', '{"role":"service_role"}', true);
END $$;
CREATE FUNCTION pg_temp.refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS $$
  SELECT ('a5600000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Les identifiants rendus par un fil, dans l'ordre.
CREATE FUNCTION pg_temp.ids(p jsonb) RETURNS uuid[] LANGUAGE sql AS $$
  SELECT coalesce(array_agg((x ->> 'id')::uuid ORDER BY o), '{}')
    FROM jsonb_array_elements(p -> 'annonces') WITH ORDINALITY AS t(x, o) $$;
CREATE FUNCTION pg_temp.une(p jsonb, p_id uuid) RETURNS jsonb LANGUAGE sql AS $$
  SELECT x FROM jsonb_array_elements(p -> 'annonces') x WHERE (x ->> 'id')::uuid = p_id $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.en_tant_que_service(), pg_temp.refus(text), pg_temp.u(text), pg_temp.ids(jsonb),
  pg_temp.une(jsonb, uuid) TO authenticated, anon, service_role;

-- Fixtures : SA super-admin ; S1 eleve adulte ; S2 eleve adulte ; G1 parent du mineur E1 ; C1 candidate.
INSERT INTO auth.users (id, email) VALUES
 (pg_temp.u('a0'), 'af-sa@test.invalid'), (pg_temp.u('e2'), 'af-s1@test.invalid'),
 (pg_temp.u('e3'), 'af-s2@test.invalid'), (pg_temp.u('d1'), 'af-g1@test.invalid'),
 (pg_temp.u('e1'), 'af-e1@test.invalid'), (pg_temp.u('c1'), 'af-c1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f3'), 'Europe/Paris'), (pg_temp.u('f4'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a0'), 'RA-26-5600', 'admin', NULL, 'Fixture', 'SA', 'active', 'male'),
 (pg_temp.u('e2'), 'RA-26-5601', 'student', pg_temp.u('f3'), 'Fixture', 'S1', 'active', 'female'),
 (pg_temp.u('e3'), 'RA-26-5602', 'student', pg_temp.u('f4'), 'Fixture', 'S2', 'active', 'male'),
 (pg_temp.u('d1'), 'RA-26-5603', 'guardian', pg_temp.u('f1'), 'Fixture', 'G1', 'active', 'male'),
 (pg_temp.u('e1'), 'RA-26-5604', 'student', pg_temp.u('f1'), 'Fixture', 'E1', 'active', 'female'),
 (pg_temp.u('c1'), 'RA-26-5605', 'teacher', NULL, 'Fixture', 'C1', 'pending_kyc', 'female');
INSERT INTO public.student_profiles (profile_id, student_type) VALUES
 (pg_temp.u('e2'), 'autonomous'), (pg_temp.u('e3'), 'autonomous'), (pg_temp.u('e1'), 'minor');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 (pg_temp.u('91'), 'enseignant', pg_temp.u('c1'), 'female', 'Fixture AF un', 'verifications',
  'entretien_a_planifier', 'en_cours', 'lien_public');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('a0')) ON CONFLICT DO NOTHING;
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
  ON CONFLICT (key) DO UPDATE SET value = 'true'::jsonb;

-- ------------------------------------------------------------------
-- 1. L'envoi met l'annonce en file
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE envoi_1 AS
  SELECT public.com_annonce_envoyer(ARRAY['tous'], 'Rentree', 'La rentree est lundi.', NULL, false,
                                    gen_random_uuid()) AS r;
CREATE TEMP TABLE envoi_2 AS
  SELECT public.com_annonce_envoyer(ARRAY['tous'], 'Horaires', 'Les horaires changent.', NULL, false,
                                    gen_random_uuid()) AS r;
RESET ROLE;
CREATE TEMP TABLE a AS SELECT (SELECT (r ->> 'id')::uuid FROM envoi_1) AS a1,
                              (SELECT (r ->> 'id')::uuid FROM envoi_2) AS a2;
GRANT SELECT ON a TO authenticated, anon, service_role;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.com_annonce_traductions t, a
    WHERE t.annonce_id IN (a.a1, a.a2) AND t.etat = 'a_faire') = 6,
  '1. deux annonces envoyees : six langues a traduire (fr, en, ar chacune)');

-- ------------------------------------------------------------------
-- 2. Le travailleur traduit l'annonce 1 ; l'annonce 2 echoue
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.com_annonce_traductions_reserver(5)') = '42501',
  '2. sans role de service, la reservation est refusee');
SELECT pg_temp.en_tant_que_service();
SET LOCAL ROLE service_role;
CREATE TEMP TABLE reserve_1 AS SELECT public.com_annonce_traductions_reserver(5) AS r;
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(r) FROM reserve_1) >= 2
  AND (SELECT x -> 'langues' FROM reserve_1, jsonb_array_elements(r) x, a
        WHERE (x ->> 'annonce_id')::uuid = a.a1) = '["ar", "en", "fr"]'::jsonb
  AND (SELECT x ->> 'texte' FROM reserve_1, jsonb_array_elements(r) x, a
        WHERE (x ->> 'annonce_id')::uuid = a.a1) = 'La rentree est lundi.',
  '2. la reservation rend le texte et les trois langues');
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(public.com_annonce_traductions_reserver(5))) = 0,
  '2. une annonce reservee ne se reserve pas deux fois');
SELECT pg_temp.vrai(
  public.com_annonce_traduction_consigner((SELECT a1 FROM a), 'fr',
    '{"en": {"titre": "Back to school", "texte": "School starts on Monday."},
      "ar": {"titre": "العودة", "texte": "تبدأ الدراسة يوم الاثنين."}}'::jsonb, NULL) = 0,
  '2. annonce 1 : plus rien a faire');
SELECT pg_temp.vrai(
  public.com_annonce_traduction_consigner((SELECT a2 FROM a), NULL, NULL,
    'configuration absente : GOOGLE_TRADUCTION_CLE') = 3,
  '2. annonce 2 : echec, trois langues encore a faire');
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(public.com_annonce_traductions_reserver(5))) = 0,
  '2. un echec ne se rejoue pas tout de suite');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT etat FROM public.com_annonce_traductions t, a WHERE t.annonce_id = a.a1 AND t.langue = 'fr') = 'originale'
  AND (SELECT etat FROM public.com_annonce_traductions t, a WHERE t.annonce_id = a.a1 AND t.langue = 'en') = 'faite'
  AND (SELECT bool_and(etat = 'a_faire' AND prochain_essai > now() AND derniere_erreur LIKE 'configuration absente%')
         FROM public.com_annonce_traductions t, a WHERE t.annonce_id = a.a2),
  '2. etats : originale, faite ; l''echec garde sa cause et sa prochaine date');

-- ------------------------------------------------------------------
-- 3. La langue du lecteur, l'original a cote, jamais vide
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('e2')::text, 'student');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE fil_en AS SELECT public.com_mes_annonces(20, NULL, 'en', false) AS f;
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(f, a.a1) ->> 'texte' FROM fil_en, a) = 'School starts on Monday.'
  AND (SELECT pg_temp.une(f, a.a1) ->> 'titre' FROM fil_en, a) = 'Back to school'
  AND (SELECT pg_temp.une(f, a.a1) ->> 'texte_original' FROM fil_en, a) = 'La rentree est lundi.'
  AND (SELECT pg_temp.une(f, a.a1) ->> 'titre_original' FROM fil_en, a) = 'Rentree'
  AND (SELECT pg_temp.une(f, a.a1) ->> 'langue_originale' FROM fil_en, a) = 'fr'
  AND (SELECT (pg_temp.une(f, a.a1) ->> 'traduite')::boolean FROM fil_en, a)
  AND (SELECT (pg_temp.une(f, a.a1) ->> 'fermee')::boolean FROM fil_en, a) = false,
  '3. en anglais : le texte traduit, l''original et sa langue a cote');
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(f, a.a2) ->> 'texte' FROM fil_en, a) = 'Les horaires changent.'
  AND (SELECT (pg_temp.une(f, a.a2) ->> 'traduite')::boolean FROM fil_en, a) = false
  AND (SELECT pg_temp.une(f, a.a2) -> 'langue_originale' FROM fil_en, a) = 'null'::jsonb,
  '3. sans traduction : l''original, jamais un vide, traduite = faux');
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(public.com_mes_annonces(20, NULL, 'fr', false), a.a1) ->> 'texte' FROM a) = 'La rentree est lundi.'
  AND (SELECT (pg_temp.une(public.com_mes_annonces(20, NULL, 'fr', false), a.a1) ->> 'traduite')::boolean FROM a) = false,
  '3. dans la langue d''ecriture : l''original, traduite = faux');
RESET ROLE;
-- La langue du compte sert quand l'ecran n'en demande pas.
UPDATE public.profiles SET langue_communication = 'ar' WHERE id = pg_temp.u('e2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(public.com_mes_annonces(20), a.a1) ->> 'texte' FROM a) = 'تبدأ الدراسة يوم الاثنين.',
  '3. sans langue demandee : celle du compte (ar)');
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(public.com_mes_annonces(20, NULL, 'xx', false), a.a1) ->> 'texte' FROM a) = 'تبدأ الدراسة يوم الاثنين.',
  '3. une langue inconnue est ignoree : celle du compte');
RESET ROLE;
UPDATE public.profiles SET langue_communication = 'es' WHERE id = pg_temp.u('e2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_temp.une(public.com_mes_annonces(20), a.a1) ->> 'texte' FROM a) = 'La rentree est lundi.',
  '3. un compte dans une langue non servie (es) recoit l''original');

-- ------------------------------------------------------------------
-- 4. Fermer, rouvrir
-- ------------------------------------------------------------------
SELECT public.com_annonce_fermer((SELECT a1 FROM a));
SELECT public.com_annonce_fermer((SELECT a1 FROM a));
SELECT pg_temp.vrai(
  NOT (SELECT a.a1 = ANY (pg_temp.ids(public.com_mes_annonces(20, NULL, NULL, false))) FROM a)
  AND (SELECT a.a2 = ANY (pg_temp.ids(public.com_mes_annonces(20, NULL, NULL, false))) FROM a),
  '4. fermee (deux fois) : elle quitte le fil des annonces non fermees, l''autre reste');
SELECT pg_temp.vrai(
  (SELECT (pg_temp.une(public.com_mes_annonces(20, NULL, NULL, true), a.a1) ->> 'fermee')::boolean FROM a)
  AND (SELECT (pg_temp.une(public.com_mes_annonces(20, NULL, NULL, true), a.a2) ->> 'fermee')::boolean FROM a) = false,
  '4. elle reste dans « toutes les annonces », marquee fermee');
SELECT pg_temp.vrai(
  (SELECT (pg_temp.une(public.com_mes_annonces(), a.a1) ->> 'fermee')::boolean FROM a),
  '6. la forme sans argument rend toujours les annonces fermees');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.com_annonce_fermetures f, a
    WHERE f.annonce_id = a.a1 AND f.profile_id = pg_temp.u('e2')) = 1,
  '4. fermer deux fois : une seule ligne');
SELECT pg_temp.en_tant_que(pg_temp.u('e3')::text, 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT a.a1 = ANY (pg_temp.ids(public.com_mes_annonces(20, NULL, NULL, false))) FROM a),
  '4. la fermeture d''une personne ne ferme rien chez une autre');
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('e2')::text, 'student');
SET LOCAL ROLE authenticated;
SELECT public.com_annonce_rouvrir((SELECT a1 FROM a));
SELECT public.com_annonce_rouvrir((SELECT a1 FROM a));
SELECT public.com_annonce_rouvrir((SELECT a2 FROM a));
SELECT pg_temp.vrai(
  (SELECT a.a1 = ANY (pg_temp.ids(public.com_mes_annonces(20, NULL, NULL, false))) FROM a)
  AND (SELECT (pg_temp.une(public.com_mes_annonces(20, NULL, NULL, false), a.a1) ->> 'fermee')::boolean FROM a) = false,
  '4. rouvrir (deux fois, et une annonce jamais fermee) : elle revient au fil');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.com_annonce_fermetures f, a
    WHERE f.annonce_id = a.a2 AND f.profile_id = pg_temp.u('e2')) = 0,
  '4. rouvrir une annonce jamais fermee n''ecrit rien');

-- ------------------------------------------------------------------
-- 5. Pagination : 25 annonces de plus (27 en tout)
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT public.com_annonce_envoyer(ARRAY['tous'], 'Page ' || n, 'Annonce numero ' || n, NULL, false, gen_random_uuid())
  FROM generate_series(1, 25) n;
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('e2')::text, 'student');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE p1 AS SELECT public.com_mes_annonces(20) AS f;
CREATE TEMP TABLE p2 AS SELECT public.com_mes_annonces(20, (SELECT (f ->> 'suite')::timestamptz FROM p1)) AS f;
SELECT pg_temp.vrai(
  (SELECT cardinality(pg_temp.ids(f)) FROM p1) = 20
  AND (SELECT f -> 'suite' FROM p1) <> 'null'::jsonb
  AND (SELECT cardinality(pg_temp.ids(f)) FROM p2) = 7
  AND (SELECT f -> 'suite' FROM p2) = 'null'::jsonb,
  '5. 27 annonces : 20 puis 7, un curseur puis aucun');
SELECT pg_temp.vrai(
  (SELECT count(DISTINCT x) FROM (SELECT unnest(pg_temp.ids(f)) x FROM p1
                                  UNION ALL SELECT unnest(pg_temp.ids(f)) FROM p2) t) = 27
  AND NOT ((SELECT (pg_temp.ids(f))[1] FROM p2) = ANY ((SELECT pg_temp.ids(f) FROM p1)::uuid[])),
  '5. aucune annonce en double, aucune perdue');
SELECT pg_temp.vrai(
  (SELECT cardinality(pg_temp.ids(public.com_mes_annonces(100)))) = 27
  AND (SELECT cardinality(pg_temp.ids(public.com_mes_annonces(0)))) = 1,
  '5. bornes : 27 rendues pour 100 demandees (moins de 50), au moins une');
RESET ROLE;
-- 50 au plus : 30 de plus (57 en tout).
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT public.com_annonce_envoyer(ARRAY['tous'], 'Encore ' || n, 'Encore ' || n, NULL, false, gen_random_uuid())
  FROM generate_series(1, 30) n;
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('e2')::text, 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT cardinality(pg_temp.ids(public.com_mes_annonces(100)))) = 50
  AND (SELECT public.com_mes_annonces(100) -> 'suite') <> 'null'::jsonb,
  '5. jamais plus de 50 a la fois');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. Refus
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.com_mes_annonces(integer,timestamptz,text,boolean)', 'execute')
  AND NOT has_function_privilege('anon', 'public.com_annonce_fermer(uuid)', 'execute')
  AND NOT has_function_privilege('anon', 'public.com_annonce_rouvrir(uuid)', 'execute')
  AND NOT has_function_privilege('authenticated', 'public.com_annonce_traductions_reserver(integer)', 'execute')
  AND NOT has_function_privilege('authenticated', 'public.com_annonce_traduction_consigner(uuid,text,jsonb,text)', 'execute')
  AND NOT has_table_privilege('authenticated', 'public.com_annonce_fermetures', 'select')
  AND NOT has_table_privilege('authenticated', 'public.com_annonce_traductions', 'select')
  AND NOT has_table_privilege('service_role', 'public.com_annonce_traductions', 'select'),
  '7. droits : anon rien ; client sans travailleur ni table ; tables fermees meme au service');
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.com_mes_annonces(20)') = '42501',
  '7. anon : refus du fil');
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('e1')::text, 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.refus('SELECT public.com_mes_annonces(20)') = '42501'
  AND pg_temp.refus('SELECT public.com_annonce_fermer(''' || (SELECT a1 FROM a) || ''')') = '42501'
  AND pg_temp.refus('SELECT public.com_annonce_rouvrir(''' || (SELECT a1 FROM a) || ''')') = '42501',
  '7. mineur : ni fil, ni fermeture');
RESET ROLE;
-- Le parent lit le fil ; une annonce qui ne lui est pas destinee ne se ferme pas.
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE envoi_3 AS
  SELECT public.com_annonce_envoyer(ARRAY['eleves_adultes'], 'Eleves', 'Pour les eleves adultes.', NULL, false,
                                    gen_random_uuid()) AS r;
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('d1')::text, 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT cardinality(pg_temp.ids(public.com_mes_annonces(50, NULL, NULL, true)))) = 50
  AND pg_temp.refus('SELECT public.com_annonce_fermer(''' || (SELECT r ->> 'id' FROM envoi_3) || ''')') = '42501',
  '7. le parent lit son fil, mais ne ferme pas une annonce qui ne lui est pas destinee');
RESET ROLE;
-- Le curseur juste apres l'annonce 1 (la plus ancienne), pour la retrouver dans une page.
CREATE TEMP TABLE curseur_a1 AS
  SELECT x.diffusee_le + interval '1 microsecond' AS c FROM public.com_annonces x, a WHERE x.id = a.a1;
GRANT SELECT ON curseur_a1 TO authenticated;
SELECT pg_temp.en_tant_que(pg_temp.u('c1')::text, 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.com_annonce_fermer((SELECT a1 FROM a));
SELECT pg_temp.vrai(
  (SELECT (pg_temp.une(public.com_mes_annonces(50, (SELECT c FROM curseur_a1), NULL, true), a.a1) ->> 'fermee')::boolean FROM a)
  AND NOT (SELECT a.a1 = ANY (pg_temp.ids(public.com_mes_annonces(50, (SELECT c FROM curseur_a1), NULL, false))) FROM a),
  '7. la candidate (compte en attente) ferme une annonce de son fil');
RESET ROLE;

ROLLBACK;
