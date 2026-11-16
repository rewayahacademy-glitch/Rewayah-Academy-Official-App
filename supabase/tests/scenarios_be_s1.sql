-- BE-S1 : les lectures du serveur pour la file et le dossier des candidatures.
-- Migration 20261128100000_be_s1_lectures.sql.
--
-- Cas couverts : (a) droits et empreintes ; (b) historique : details par liste blanche
-- (aucune cle de rattachement, de piece ni de contact) et noms du responsable avant et
-- apres ; (c) dossier : responsableNom ; (d) chaque nouveau filtre de la liste, seul et
-- combine, et les refus 22023 ; (e) voisins : debut, milieu, fin, hors filtre, hors portee
-- (l'autre cote ne fuit rien), refus par appelant ; (f) voisins et liste donnent le meme
-- ordre, le meme total, pour un jeu de filtres et les trois tris.
-- Chaque controle leve 'BE-S1 ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE
-- (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'BE-S1 ROUGE : %', p_label;
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
    RAISE EXCEPTION 'BE-S1 ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'BE-S1 ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be510000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be51cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

CREATE FUNCTION pg_temp.nos(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY t.n), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') WITH ORDINALITY AS t(l, n);
$$;

-- La liste (direction a1, cote hommes) pour un filtre, en numeros de fixture.
CREATE FUNCTION pg_temp.liste(p_filtre jsonb, p_tri text DEFAULT 'activite') RETURNS text[]
LANGUAGE sql AS $$
  SELECT pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format('SELECT public.lister_candidatures(%L::jsonb, %L, 1)', p_filtre::text, p_tri)));
$$;

CREATE FUNCTION pg_temp.ref(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT reference FROM public.candidatures WHERE id = pg_temp.c(p_n); $$;

CREATE FUNCTION pg_temp.voisins(p_qui text, p_n text, p_filtre jsonb DEFAULT '{}', p_tri text DEFAULT 'activite')
RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p(p_qui), 'admin',
    pg_catalog.format('SELECT public.voisins_candidature(%L, %L::jsonb, %L)', pg_temp.ref(p_n), p_filtre::text, p_tri));
$$;

-- La liste et les voisins disent la meme chose : meme ordre, meme total, meme rang.
CREATE FUNCTION pg_temp.concordance(p_filtre jsonb, p_tri text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_liste text[] := pg_temp.liste(p_filtre, p_tri);
  v_i integer;
  v jsonb;
BEGIN
  FOR v_i IN 1 .. coalesce(array_length(v_liste, 1), 0) LOOP
    v := pg_temp.voisins('a1', v_liste[v_i], p_filtre, p_tri);
    IF (v ->> 'rang')::integer <> v_i
       OR (v ->> 'total')::integer <> array_length(v_liste, 1)
       OR v ->> 'precedent' IS DISTINCT FROM (CASE WHEN v_i > 1 THEN pg_temp.ref(v_liste[v_i - 1]) END)
       OR v ->> 'suivant' IS DISTINCT FROM (CASE WHEN v_i < array_length(v_liste, 1)
                                                 THEN pg_temp.ref(v_liste[v_i + 1]) END) THEN
      RAISE EXCEPTION 'BE-S1 ROUGE : % (rang % : %)', p_label, v_i, v;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok(p_label || ' (' || coalesce(array_length(v_liste, 1), 0) || ' lignes)');
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 et a3 direction homme, a2 direction femme, e1 tuteur.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'be-s1-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'e1', '01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('be51ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'BE51-ADM-0001', 'admin', NULL, 'Direction', 'Un', 'active', 'male'),
 (pg_temp.p('a2'), 'BE51-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a3'), 'BE51-ADM-0003', 'admin', NULL, 'Direction', 'Trois', 'active', 'male'),
 (pg_temp.p('e1'), 'BE51-TUT-0001', 'guardian', 'be51ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BE51-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '07' THEN 'female'::public.gender ELSE 'male'::public.gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;

-- 01..06 hommes, 07 femme ; l'activite decroit de 01 a 07 (ordre « activite » connu).
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source,
                                 derniere_activite, recue_le, responsable_id)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s),
       CASE WHEN s = '07' THEN 'female'::public.gender ELSE 'male'::public.gender END,
       'Candidat ' || (ARRAY['Foxtrot', 'Echo', 'Delta', 'Charlie', 'Bravo', 'Alpha', 'Golf'])[s::integer],
       'prequalification', 'a_completer', 'en_cours', 'lien_public',
       now() - (s::integer || ' hours')::interval, now() - (s::integer || ' days')::interval,
       CASE s WHEN '01' THEN pg_temp.p('a1') WHEN '02' THEN pg_temp.p('a3') END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;

-- Reponses. 01 : ijaza, fr, hafs, adultes, lundi a jeudi le soir.
-- 02 : pas d'ijaza, fr et en, warsh, 6-9, lundi et mardi le soir.
-- 03 : ijaza, en, hafs et warsh, lundi a mercredi le soir et jeudi le matin.
-- 04 : ijaza, fr, hafs, lundi a jeudi le matin. 05 : aucune reponse.
-- 06 : prete au test, fr, vendredi et samedi le soir (jusqu'a minuit).
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
VALUES
 (pg_temp.c('01'), 'salle-examen-1', $j${"ijazaPresentable":"oui","languesExplication":["fr"],"riwayat":["hafs"],
   "publics":["adultes"],"disponibilitesDeclarees":[{"jour":1,"debut":"18:00","fin":"21:00"},
   {"jour":2,"debut":"18:00","fin":"21:00"},{"jour":3,"debut":"18:00","fin":"21:00"},
   {"jour":4,"debut":"18:00","fin":"21:00"}]}$j$::jsonb, 'candidat'),
 (pg_temp.c('02'), 'salle-examen-1', $j${"ijazaPresentable":"non","languesExplication":["fr","en"],"riwayat":["warsh"],
   "publics":["6_9"],"disponibilitesDeclarees":[{"jour":1,"debut":"18:00","fin":"21:00"},
   {"jour":2,"debut":"18:00","fin":"21:00"}]}$j$::jsonb, 'candidat'),
 (pg_temp.c('03'), 'salle-examen-1', $j${"ijazaPresentable":"oui","languesExplication":["en"],"riwayat":["hafs","warsh"],
   "publics":["adultes","14_17"],"disponibilitesDeclarees":[{"jour":1,"debut":"19:00","fin":"22:00"},
   {"jour":2,"debut":"19:00","fin":"22:00"},{"jour":3,"debut":"19:00","fin":"22:00"},
   {"jour":4,"debut":"08:00","fin":"10:00"}]}$j$::jsonb, 'candidat'),
 (pg_temp.c('04'), 'salle-examen-1', $j${"ijazaPresentable":"oui","languesExplication":["fr"],"riwayat":["hafs"],
   "publics":["10_13"],"disponibilitesDeclarees":[{"jour":1,"debut":"09:00","fin":"12:00"},
   {"jour":2,"debut":"09:00","fin":"12:00"},{"jour":3,"debut":"09:00","fin":"12:00"},
   {"jour":4,"debut":"09:00","fin":"12:00"}]}$j$::jsonb, 'candidat'),
 (pg_temp.c('06'), 'salle-examen-1', $j${"ijazaPresentable":"pret_test","languesExplication":["fr"],"riwayat":["hafs"],
   "publics":["adultes"],"disponibilitesDeclarees":[{"jour":5,"debut":"18:00","fin":"24:00"},
   {"jour":6,"debut":"18:00","fin":"24:00"}]}$j$::jsonb, 'candidat'),
 (pg_temp.c('07'), 'salle-examen-1', $j${"ijazaPresentable":"oui"}$j$::jsonb, 'candidat');
-- Une reponse plus ancienne de 02 ne compte pas : seule la plus recente est lue.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
VALUES (pg_temp.c('02'), 'salle-examen-1', '{"ijazaPresentable":"oui"}'::jsonb, 'candidat', now() - interval '30 days');

-- Pieces : 01 en attente ; 02 approuvee ; 03 : une ancienne approuvee puis une recente en attente ;
-- 04 : une piece effacee (ne compte pas).
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, status, created_at)
VALUES
 (pg_temp.p('01'), 'id_card', 'male', 'be51/01', 'pending', now() - interval '1 day'),
 (pg_temp.p('02'), 'id_card', 'male', 'be51/02', 'approved', now() - interval '1 day'),
 (pg_temp.p('03'), 'id_card', 'male', 'be51/03a', 'approved', now() - interval '5 days'),
 (pg_temp.p('03'), 'passport', 'male', 'be51/03b', 'pending', now() - interval '1 day');
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, status, created_at, deleted_at)
VALUES (pg_temp.p('04'), 'id_card', 'male', 'be51/04', 'pending', now() - interval '1 day', now());

-- Evenements de 01 : un changement de responsable (a3 vers a1), un controle avec des cles
-- qui ne doivent jamais sortir.
INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
VALUES
 (pg_temp.c('01'), 'responsable', pg_temp.p('a1'), pg_catalog.jsonb_build_object(
   'geste', 'definir_responsable', 'transition', 30, 'auteur', 'direction',
   'changements', pg_catalog.jsonb_build_object(
     'responsable_id', pg_catalog.jsonb_build_object('avant', pg_temp.p('a3'), 'apres', pg_temp.p('a1')),
     'pays_residence', pg_catalog.jsonb_build_object('avant', 'FR', 'apres', 'BE'),
     'courriel', pg_catalog.jsonb_build_object('avant', 'x@test.invalid', 'apres', 'y@test.invalid')),
   'sessionId', 'secret-session', 'cle', 'cle-de-rattachement', 'reponse', 'reponse-brute',
   'telephone', '+33600000000', 'piece', 'be51/01')),
 (pg_temp.c('01'), 'controle', pg_temp.p('a1'), pg_catalog.jsonb_build_object(
   'controle', 'pays_versement_modifie', 'paysAvant', 'FR', 'paysApres', 'BE',
   'valeurAvant', false, 'valeurApres', true, 'cause', 'referentiel', 'ligne', 'ligne-interne'));

-- ------------------------------------------------------------
-- (a) Droits et empreintes
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.voisins_candidature(text,jsonb,text)', 'EXECUTE'),
  'a1 : seul authenticated execute voisins_candidature');
SELECT pg_temp.vrai(
  (SELECT bool_and(NOT has_function_privilege(r, f, 'EXECUTE'))
     FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r,
          unnest(ARRAY['private.be_nom_membre(uuid)', 'private.be_details_lisibles(jsonb)',
                       'private.be_responsable_evenement(jsonb)', 'private.be_filtre_valider(jsonb)',
                       'private.be_predicat(public.candidatures,jsonb,uuid)']::regprocedure[]) AS f),
  'a2 : les cinq aides internes ne sont executables par aucun compte');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
                   AND obj_description(f, 'pg_proc') LIKE '%BE-S1%'
                   AND prosecdef AND proconfig @> ARRAY['search_path=""'])
     FROM unnest(ARRAY['public.voisins_candidature(text,jsonb,text)',
                       'public.historique_candidature(uuid,bigint,integer)',
                       'public.lister_candidatures(jsonb,text,integer)']::regprocedure[]) AS f
     JOIN pg_proc p ON p.oid = f),
  'a3 : empreinte F86 a jour, DEFINER, search_path vide (voisins, historique, liste)');

-- ------------------------------------------------------------
-- (b) Historique
-- ------------------------------------------------------------
DO $$
DECLARE
  v jsonb := pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format('SELECT public.historique_candidature(%L, NULL, 50)', pg_temp.c('01')));
  v_resp jsonb;
  v_ctl jsonb;
  v_tout text := v::text;
BEGIN
  SELECT e INTO v_resp FROM jsonb_array_elements(v -> 'evenements') e WHERE e ->> 'type' = 'responsable';
  SELECT e INTO v_ctl FROM jsonb_array_elements(v -> 'evenements') e WHERE e ->> 'type' = 'controle';
  PERFORM pg_temp.vrai(v_resp ->> 'responsableNom' = 'Direction Un'
    AND v_resp ->> 'responsableAvantNom' = 'Direction Trois', 'b1 : l''evenement responsable rend le nom avant et le nom apres');
  PERFORM pg_temp.vrai(v_resp #>> '{details,geste}' = 'definir_responsable'
    AND v_resp #>> '{details,changements,pays_residence,apres}' = 'BE', 'b2 : details rend le geste et le pays avant et apres');
  PERFORM pg_temp.vrai(v_ctl #>> '{details,paysAvant}' = 'FR' AND v_ctl #>> '{details,paysApres}' = 'BE'
    AND v_ctl #>> '{details,controle}' = 'pays_versement_modifie'
    AND (v_ctl #>> '{details,valeurApres}')::boolean AND v_ctl #>> '{details,cause}' = 'referentiel',
    'b3 : un controle rend son nom, la valeur avant et apres, la cause et les pays');
  PERFORM pg_temp.vrai(v_tout NOT LIKE '%x@test.invalid%' AND v_tout NOT LIKE '%+33600000000%'
    AND v_tout NOT LIKE '%secret-session%' AND v_tout NOT LIKE '%cle-de-rattachement%'
    AND v_tout NOT LIKE '%reponse-brute%' AND v_tout NOT LIKE '%be51/01%' AND v_tout NOT LIKE '%ligne-interne%'
    AND v_tout NOT LIKE '%' || pg_temp.p('a3')::text || '%',
    'b4 : ni contact, ni piece, ni cle de rattachement, ni identifiant de personne dans l''historique');
  PERFORM pg_temp.vrai((v_ctl -> 'responsableNom') IS NULL, 'b5 : le nom du responsable ne sort que pour un evenement responsable');
END $$;

-- ------------------------------------------------------------
-- (c) Dossier
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.c('01')))
    ->> 'responsableNom' = 'Direction Un'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.c('02')))
    ->> 'responsableNom' = 'Direction Trois'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.c('03')))
    -> 'responsableNom' = 'null'::jsonb,
  'c1 : le dossier rend le nom du responsable, nul sans responsable');

-- ------------------------------------------------------------
-- (d) Filtres
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.liste('{}') = ARRAY['01','02','03','04','05','06'], 'd0 : sans filtre, la portee des hommes, par activite');
SELECT pg_temp.vrai(pg_temp.liste('{"ijaza":true}') = ARRAY['01','03','04'],
  'd1 : ijaza oui (la reponse la plus recente seule compte : 02 non)');
SELECT pg_temp.vrai(pg_temp.liste('{"ijaza":false}') = ARRAY['02'], 'd2 : ijaza non (pret_test et sans reponse exclus)');
SELECT pg_temp.vrai(pg_temp.liste('{"langueExplication":"en"}') = ARRAY['02','03'], 'd3 : langue d''explication');
SELECT pg_temp.vrai(pg_temp.liste('{"riwaya":"warsh"}') = ARRAY['02','03'], 'd4 : riwaya');
SELECT pg_temp.vrai(pg_temp.liste('{"public":"adultes"}') = ARRAY['01','03','06'], 'd5 : public');
SELECT pg_temp.vrai(pg_temp.liste('{"jours":[5]}') = ARRAY['06'], 'd6 : un jour disponible');
SELECT pg_temp.vrai(pg_temp.liste('{"jours":[4,5]}') = ARRAY['01','03','04','06'], 'd7 : un ou plusieurs jours (l''un d''eux suffit)');
SELECT pg_temp.vrai(pg_temp.liste('{"joursMin":4}') = ARRAY['01','03','04'], 'd8 : au moins quatre jours disponibles');
SELECT pg_temp.vrai(pg_temp.liste('{"heureMin":18}') = ARRAY['01','02','03','06'], 'd9 : heureMin, le soir');
SELECT pg_temp.vrai(pg_temp.liste('{"heureMin":18,"heureMax":24}') = ARRAY['01','02','03','06'],
  'd10 : heures du soir (24:00 est une borne valide)');
SELECT pg_temp.vrai(pg_temp.liste('{"heureMax":12}') = ARRAY['03','04'], 'd11 : heureMax, le matin');
SELECT pg_temp.vrai(pg_temp.liste('{"heureMin":21,"heureMax":23}') = ARRAY['03','06'],
  'd12 : une plage qui recouvre la fenetre compte, une qui finit a la borne non');
SELECT pg_temp.vrai(pg_temp.liste('{"heureMin":18,"heureMax":24,"joursMin":4}') = ARRAY['01'],
  'd13 : libres le soir quatre jours (03 n''a que trois soirs)');
SELECT pg_temp.vrai(pg_temp.liste('{"ijaza":true,"heureMin":18,"heureMax":24,"joursMin":4}') = ARRAY['01'],
  'd14 : la phrase du lot : ijaza, le soir, quatre jours');
SELECT pg_temp.vrai(pg_temp.liste('{"jours":[1],"heureMin":18}') = ARRAY['01','02','03'] AND
                    pg_temp.liste('{"jours":[6],"heureMin":18}') = ARRAY['06'], 'd15 : jours et heures se combinent');
SELECT pg_temp.vrai(pg_temp.liste('{"pieceEnAttente":true}') = ARRAY['01','03'],
  'd16 : piece en attente (la derniere piece non effacee compte)');
SELECT pg_temp.vrai(pg_temp.liste('{"pieceEnAttente":false}') = ARRAY['02','04','05','06'], 'd17 : sans piece en attente');
SELECT pg_temp.vrai(pg_temp.liste('{"responsable":"moi"}') = ARRAY['01'], 'd18 : mes dossiers');
SELECT pg_temp.vrai(pg_temp.liste('{"responsable":"aucun"}') = ARRAY['03','04','05','06'], 'd19 : sans responsable');
SELECT pg_temp.vrai(pg_temp.liste(pg_catalog.jsonb_build_object('responsable', pg_temp.p('a3'))) = ARRAY['02'],
  'd20 : un responsable par identifiant');
SELECT pg_temp.vrai(pg_temp.liste('{"ijaza":null,"jours":null,"responsable":null}') = ARRAY['01','02','03','04','05','06'],
  'd21 : une cle nulle ne filtre pas');
SELECT pg_temp.vrai(pg_temp.liste('{"genre":"female"}') = ARRAY[]::text[]
  AND pg_temp.en(pg_temp.p('a2'), 'admin', $q$SELECT public.lister_candidatures('{"ijaza":true}', 'activite', 1)$q$)
      -> 'total' = '1'::jsonb, 'd22 : la portee de genre tient avec les nouveaux filtres (la direction femme ne voit que 07)');

SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"inconnue":1}', 'activite', 1)$q$,
  '22023', 'd23 : cle inconnue refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"jours":[8]}', 'activite', 1)$q$,
  '22023', 'd24 : jour hors 1 a 7');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"jours":"1"}', 'activite', 1)$q$,
  '22023', 'd25 : jours doit etre une liste');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"heureMin":20,"heureMax":18}', 'activite', 1)$q$,
  '22023', 'd26 : heureMin apres heureMax');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"heureMin":25}', 'activite', 1)$q$,
  '22023', 'd27 : heure hors 0 a 24');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"joursMin":9}', 'activite', 1)$q$,
  '22023', 'd28 : joursMin hors 1 a 7');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"ijaza":"oui"}', 'activite', 1)$q$,
  '22023', 'd29 : ijaza doit etre un booleen');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"public":"retraites"}', 'activite', 1)$q$,
  '22023', 'd30 : public hors liste');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.lister_candidatures('{"responsable":"quelquun"}', 'activite', 1)$q$,
  '22023', 'd31 : responsable ni moi, ni aucun, ni identifiant');

-- ------------------------------------------------------------
-- (e) Voisins
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.voisins('a1', '01') = pg_catalog.jsonb_build_object('precedent', NULL, 'suivant', pg_temp.ref('02'), 'rang', 1, 'total', 6),
  'e1 : au debut, pas de precedent');
SELECT pg_temp.vrai(
  pg_temp.voisins('a1', '03') = pg_catalog.jsonb_build_object('precedent', pg_temp.ref('02'), 'suivant', pg_temp.ref('04'), 'rang', 3, 'total', 6),
  'e2 : au milieu, les deux voisins');
SELECT pg_temp.vrai(
  pg_temp.voisins('a1', '06') = pg_catalog.jsonb_build_object('precedent', pg_temp.ref('05'), 'suivant', NULL, 'rang', 6, 'total', 6),
  'e3 : a la fin, pas de suivant');
SELECT pg_temp.vrai(
  pg_temp.voisins('a1', '03', '{"ijaza":true}') = pg_catalog.jsonb_build_object('precedent', pg_temp.ref('01'), 'suivant', pg_temp.ref('04'), 'rang', 2, 'total', 3),
  'e4 : dans un filtre, les voisins sont ceux de la liste filtree');
SELECT pg_temp.vrai(pg_temp.voisins('a1', '02', '{"ijaza":true}') = '{"erreur":"hors_liste"}'::jsonb,
  'e5 : un dossier lisible mais hors du filtre : hors_liste');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', $q$SELECT public.voisins_candidature('CAND-INCONNUE', '{}', 'activite')$q$)
    = '{"erreur":"absente"}'::jsonb, 'e7 : une reference inconnue : absente');
SELECT pg_temp.vrai(pg_temp.voisins('a2', '01') = '{"erreur":"hors_portee"}'::jsonb,
  'e8 : l''autre cote : hors_portee, sans reference ni total');
SELECT pg_temp.vrai(pg_temp.voisins('a2', '07') ->> 'total' = '1' AND pg_temp.voisins('a2', '07') ->> 'precedent' IS NULL
  AND pg_temp.voisins('a2', '07') ->> 'suivant' IS NULL, 'e9 : la direction femme n''a que son cote dans le total');
SELECT pg_temp.vrai(pg_temp.voisins('a1', '07') = '{"erreur":"hors_portee"}'::jsonb,
  'e10 : la direction homme ne voit pas le cote femme');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian', $q$SELECT public.voisins_candidature('CAND-X', '{}', 'activite')$q$,
  '42501', 'e11 : un tuteur est refuse');
SELECT pg_temp.refus_en(NULL, NULL, $q$SELECT public.voisins_candidature('CAND-X', '{}', 'activite')$q$,
  '42501', 'e12 : sans session, refuse');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.voisins_candidature('CAND-X', '{"inconnue":1}', 'activite')$q$,
  '22023', 'e13 : filtre inconnu refuse comme la liste');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.voisins_candidature('CAND-X', '{}', 'hasard')$q$,
  '22023', 'e14 : tri inconnu refuse comme la liste');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.voisins_candidature('', '{}', 'activite')$q$,
  '22023', 'e15 : reference vide refusee');

-- ------------------------------------------------------------
-- (f) Concordance liste / voisins
-- ------------------------------------------------------------
SELECT pg_temp.concordance('{}', 'activite', 'f1 : sans filtre, tri activite');
SELECT pg_temp.concordance('{}', 'recente', 'f2 : sans filtre, tri recente');
SELECT pg_temp.concordance('{}', 'nom', 'f3 : sans filtre, tri nom');
SELECT pg_temp.concordance('{"ijaza":true}', 'nom', 'f4 : ijaza, tri nom');
SELECT pg_temp.concordance('{"heureMin":18,"heureMax":24,"joursMin":3}', 'activite', 'f5 : le soir trois jours');
SELECT pg_temp.concordance('{"pieceEnAttente":true}', 'recente', 'f6 : piece en attente');
SELECT pg_temp.concordance('{"responsable":"aucun","public":"adultes"}', 'activite', 'f7 : sans responsable, adultes');
SELECT pg_temp.concordance('{"recherche":"Delta"}', 'activite', 'f8 : recherche par nom');
SELECT pg_temp.concordance('{"etape":"verifications"}', 'activite', 'f9 : filtre vide de resultat');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 64,
  'z : au moins 64 controles passes');
DO $$ BEGIN RAISE NOTICE 'BE-S1 : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
