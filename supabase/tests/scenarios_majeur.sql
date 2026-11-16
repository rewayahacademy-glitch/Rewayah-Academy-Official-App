-- MAJEUR : l'attestation « 18 ans ou plus » (directeur, 16/11/2026).
-- Migration 20261128400000_majeur_attestation.sql.
--
-- Cas couverts : (a) refus par appelant (sans session, direction, tuteur, candidature close,
-- demande qui n'est pas du recrutement) et aucune ecriture directe de la colonne ; (b) l'attestation
-- vraie : colonnes, evenement `engagement`, ni version ni pause, rejouee sans effet, l'inverse
-- refuse ; l'etat du candidat la rend ; (c) l'envoi des reponses refuse sans attestation vraie
-- (majorite_requise) et plus refuse pour ce motif avec elle ; (d) « moins de 18 ans » : pause
-- immediate, deux evenements (engagement, pause sans auteur, motif Age), l'envoi ferme, la
-- declaration inverse refusee, rien de supprime ; (e) personne d'autre que le candidat ne peut
-- attester pour lui ; (f) la direction lit `majorite` et filtre par attestee, non_attestee,
-- moins_18 (liste et voisins) ; (g) droits et empreinte.
-- Chaque controle leve 'MAJEUR ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE (stub_auth
-- puis toutes les migrations) ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
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

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'MAJEUR ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'MAJEUR ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'MAJEUR ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ba1e0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ba1ecccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Ce que la candidature porte, en une ligne : declaration / pause / version.
CREATE FUNCTION pg_temp.vue(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT coalesce(c.majorite_declaree::text, 'nulle') || '/' || c.en_pause::text || '/' || c.version::text
    FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.evenements(p_n text, p_type text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = p_type;
$$;
CREATE FUNCTION pg_temp.refs(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY t.n), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') WITH ORDINALITY AS t(l, n);
$$;
-- La liste, en numeros de fixture, triee (l'ordre par activite n'est pas l'objet ici).
CREATE FUNCTION pg_temp.liste(p_filtre jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT ARRAY(
    SELECT x FROM unnest(pg_temp.refs(pg_temp.en(pg_temp.p('a1'), 'admin',
      pg_catalog.format('SELECT public.lister_candidatures(%L::jsonb, ''activite'', 1)', p_filtre::text)))) AS x
    ORDER BY x);
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme ; e1 tuteur. Candidats (enseignants, hommes) : 01 a completer (le cas
-- principal), 02 a completer (le voisin : il ne change jamais), 03 en examen, deja avance (il
-- attestera plus tard), 04 refusee, 05 a completer (dira « moins de 18 ans »), 06 a completer,
-- deja attestee des le depart. 07 : une demande de famille du tuteur (pas du recrutement).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'majeur-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'e1', '01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ba1effff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'BA1E-ADM-0001', 'admin', NULL, 'Direction', 'Un', 'active', 'male'),
 (pg_temp.p('e1'), 'BA1E-TUT-0001', 'guardian', 'ba1effff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BA1E-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source,
                                 majorite_declaree, majorite_attestee_le)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s,
       'prequalification', v.etat, v.issue, 'lien_public', v.maj, CASE WHEN v.maj IS NOT NULL THEN now() END
FROM (VALUES
  ('01', 'a_completer', 'en_cours', NULL::boolean),
  ('02', 'a_completer', 'en_cours', NULL),
  ('03', 'en_examen', 'en_cours', NULL),
  ('04', 'a_completer', 'refusee', NULL),
  ('05', 'a_completer', 'en_cours', NULL),
  ('06', 'a_completer', 'en_cours', true)
) AS v(s, etat, issue, maj);
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES (pg_temp.c('07'), 'famille', pg_temp.p('e1'), 'female', 'Famille 07', 'confirmee', NULL, 'en_cours',
        'lien_public');

SELECT pg_temp.vrai((SELECT count(*) FROM public.candidatures WHERE id::text LIKE 'ba1ecccc%') = 7
  AND pg_temp.vue('01') = 'nulle/false/1' AND pg_temp.vue('06') = 'true/false/1',
  'fixtures : 7 candidatures, une seule deja attestee (06)');

-- ------------------------------------------------------------
-- (a) Refus
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL, $q$SELECT public.attester_majorite(true)$q$, '42501',
  'a1 : sans session, refuse');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.attester_majorite(true)$q$, '42501',
  'a2 : la direction ne peut pas attester (aucune candidature a elle)');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian', $q$SELECT public.attester_majorite(true)$q$, '42501',
  'a3 : une demande de famille n''est pas du recrutement : refusee');
SELECT pg_temp.refus_en(pg_temp.p('04'), 'teacher', $q$SELECT public.attester_majorite(true)$q$, '42501',
  'a4 : une candidature refusee n''est plus en cours : refusee');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher', $q$SELECT public.attester_majorite(NULL)$q$, '22023',
  'a5 : une declaration nulle est un argument invalide');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  pg_catalog.format($q$UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = now() WHERE id = %L$q$, pg_temp.c('01')),
  '42501', 'a6 : aucune ecriture directe de la colonne par un compte');
SELECT pg_temp.vrai(pg_temp.vue('01') = 'nulle/false/1' AND pg_temp.evenements('01', 'engagement') = 0,
  'a7 : les refus n''ont rien ecrit');

-- ------------------------------------------------------------
-- (c bis) Envoi refuse sans attestation (avant d'attester)
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher',
    $q$SELECT public.envoyer_reponses_salle_examen('x', '{}'::jsonb, true, 'x', 1, 'cle-majeur-01-a')$q$)
  = '{"erreur": "majorite_requise"}'::jsonb,
  'c1 : l''envoi des reponses est refuse sans attestation (majorite_requise)');
SELECT pg_temp.vrai(pg_temp.vue('01') = 'nulle/false/1' AND pg_temp.evenements('01', 'transition') = 0,
  'c2 : ce refus n''ecrit ni attestation ni transition');

-- ------------------------------------------------------------
-- (b) L'attestation vraie
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'majorite'$q$)
    = '{"declaree": null, "attesteeLe": null}'::jsonb,
  'b0 : avant, l''etat du candidat rend majorite sans declaration');
SELECT set_config('test.att01', pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.attester_majorite(true)$q$)::text, true);
SELECT pg_temp.vrai(current_setting('test.att01')::jsonb #>> '{majorite,declaree}' = 'true'
  AND current_setting('test.att01')::jsonb #>> '{majorite,attesteeLe}' IS NOT NULL
  AND pg_temp.vue('01') = 'true/false/1'
  AND pg_temp.evenements('01', 'engagement') = 1 AND pg_temp.evenements('01', 'pause') = 0
  AND (SELECT details @> '{"engagement": "majorite", "majeur": true}'::jsonb AND auteur_id = pg_temp.p('01')
         FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('01') AND type = 'engagement'),
  'b1 : 18 ans ou plus : colonnes ecrites, un evenement engagement a son nom, ni pause ni version de plus');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'majorite' ->> 'declaree'$q$) IS NOT NULL
  AND (pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'majorite'$q$)) ->> 'attesteeLe' IS NOT NULL,
  'b2 : l''etat du candidat rend la declaration et sa date');
SELECT pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.attester_majorite(true)$q$);
SELECT pg_temp.vrai(pg_temp.evenements('01', 'engagement') = 1 AND pg_temp.vue('01') = 'true/false/1',
  'b3 : rejouee, la meme declaration ne change rien (aucun evenement de plus)');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.attester_majorite(false)$q$)
    = '{"erreur": "declaration_deja_faite"}'::jsonb
  AND pg_temp.vue('01') = 'true/false/1' AND pg_temp.evenements('01', 'pause') = 0,
  'b4 : dire l''inverse apres coup est refuse, sans ecriture, sans pause');
SELECT pg_temp.vrai(pg_temp.vue('02') = 'nulle/false/1' AND pg_temp.evenements('02', 'engagement') = 0,
  'e1 : personne d''autre n''est touche : la candidature voisine reste sans declaration');

-- ------------------------------------------------------------
-- (c) L'envoi n'est plus refuse pour ce motif une fois attestee
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher',
    $q$SELECT public.envoyer_reponses_salle_examen('x', '{}'::jsonb, true, 'x', 1, 'cle-majeur-01-b')$q$)
    ->> 'erreur' IS DISTINCT FROM 'majorite_requise',
  'c3 : avec l''attestation vraie, l''envoi passe cette porte (il est examine pour ses autres conditions)');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('06'), 'teacher',
    $q$SELECT public.envoyer_reponses_salle_examen('x', '{}'::jsonb, true, 'x', 1, 'cle-majeur-06')$q$)
    ->> 'erreur' IS DISTINCT FROM 'majorite_requise',
  'c4 : une candidature attestee des le depart passe aussi cette porte');

-- ------------------------------------------------------------
-- (d) Moins de 18 ans : pause immediate, rien de supprime
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('05'), 'teacher', $q$SELECT public.attester_majorite(false)$q$)) #>> '{majorite,declaree}' = 'false'
  AND pg_temp.vue('05') = 'false/true/2',
  'd1 : moins de 18 ans : declaration fausse, candidature en pause, une version de plus');
SELECT pg_temp.vrai(pg_temp.evenements('05', 'engagement') = 1 AND pg_temp.evenements('05', 'pause') = 1
  AND (SELECT e.auteur_id IS NULL AND e.motif_interne LIKE 'Âge%' AND e.details @> '{"cause": "age"}'::jsonb
         FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('05') AND e.type = 'pause')
  AND (SELECT count(*) FROM public.candidatures WHERE id = pg_temp.c('05')) = 1,
  'd2 : deux evenements (engagement a son nom, pause sans auteur, motif Age, cause age) ; la candidature est gardee');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('05'), 'teacher',
    $q$SELECT public.envoyer_reponses_salle_examen('x', '{}'::jsonb, true, 'x', 2, 'cle-majeur-05')$q$)
    ->> 'erreur' IS NOT NULL,
  'd3 : en pause pour l''age, l''envoi est refuse');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('05'), 'teacher', $q$SELECT public.attester_majorite(true)$q$)
    = '{"erreur": "declaration_deja_faite"}'::jsonb
  AND pg_temp.vue('05') = 'false/true/2',
  'd4 : la personne ne peut pas se dedire seule (la direction le voit et decide) ; rien n''est ecrit');

-- ------------------------------------------------------------
-- (f) La direction : la cle majorite et le filtre
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L) -> 'majorite'$q$, pg_temp.c('01')))
    ->> 'declaree' = 'true'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L) -> 'majorite'$q$, pg_temp.c('05')))
    ->> 'declaree' = 'false'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L) -> 'majorite'$q$, pg_temp.c('02')))
    ->> 'declaree' IS NULL,
  'f1 : le dossier de la direction rend majorite : vraie, fausse, sans declaration');
SELECT pg_temp.vrai(pg_temp.liste('{"majorite":"attestee"}') = ARRAY['01', '06'] , 'f2 : filtre attestee');
SELECT pg_temp.vrai(pg_temp.liste('{"majorite":"non_attestee"}') @> ARRAY['02', '03']
  AND NOT (pg_temp.liste('{"majorite":"non_attestee"}') && ARRAY['01', '05', '06']),
  'f3 : filtre non_attestee (sans declaration : les avances comme les autres)');
SELECT pg_temp.vrai(pg_temp.liste('{"majorite":"moins_18"}') = ARRAY['05'], 'f4 : filtre moins_18');
SELECT pg_temp.vrai(pg_temp.liste('{"majorite":"attestee", "pieceEnAttente": false}') <@ pg_temp.liste('{"majorite":"attestee"}'),
  'f5 : le filtre se combine avec les autres cles');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin',
  $q$SELECT public.lister_candidatures('{"majorite":"peut-etre"}', 'activite', 1)$q$, '22023',
  'f6 : valeur hors liste refusee');
SELECT set_config('test.ref01', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), true);
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.voisins_candidature(%L, '{"majorite":"attestee"}', 'activite')$q$,
                      current_setting('test.ref01')))
    ->> 'total' = '2',
  'f7 : les voisins suivent le meme filtre (2 candidatures attestees)');

-- ------------------------------------------------------------
-- (g) Droits et empreinte
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.attester_majorite(boolean)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.attester_majorite(boolean)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.attester_majorite(boolean)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.attester_majorite(boolean)', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.attester_majorite(boolean)', 'EXECUTE'),
  'g1 : seul authenticated execute attester_majorite');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
                   AND obj_description(f, 'pg_proc') LIKE '%MAJEUR%'
                   AND prosecdef AND proconfig @> ARRAY['search_path=""'])
     FROM unnest(ARRAY['public.attester_majorite(boolean)']::regprocedure[]) AS f
     JOIN pg_proc p ON p.oid = f),
  'g2 : empreinte F86 a jour, DEFINER, search_path vide');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 31,
  'z : au moins 31 controles passes');
DO $$ BEGIN RAISE NOTICE 'MAJEUR : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
