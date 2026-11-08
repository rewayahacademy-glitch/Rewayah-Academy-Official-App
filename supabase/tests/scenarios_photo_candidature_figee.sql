-- PHOTO-CANDIDATURE-FIGEE (07/11/2026) : la photo du dossier de candidature
-- n'est jamais remplacee ni effacee dans le seau ; la photo d'affichage reste
-- libre ; la direction lit la photo du dossier sous la garde de
-- lire_candidature. Le gel a l'envoi des reponses est prouve dans
-- scenarios_cand_l2a1_moteur_salle_examen.sql (parcours reel).
-- Chaque controle leve 'PHOTO-FIGEE ROUGE : ...' s'il echoue. A rejouer sur
-- une base NEUVE ; le scenario annule tout a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PHOTO-FIGEE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Nombre de lignes touchees par p_sql, joue sous le role authenticated.
CREATE FUNCTION pg_temp.lignes(p_id uuid, p_role text, p_sql text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql;
  GET DIAGNOSTICS v = ROW_COUNT;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, 'aal2');
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf500000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Fixtures : 01 candidat en cours (dossier fige), 03 enseignant actif dont le
-- dossier est fige, 05 direction homme, 06 direction femme, 02 AUTRE candidat,
-- 07 tuteur sans lien avec aucun enseignant (les tiers de la section d).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'photo-figee-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','05','06','07']) n;
INSERT INTO public.households (id, timezone) VALUES ('cf50ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('01'), 'CPF-01', 'teacher', NULL, 'Ibrahima', 'Keita', 'pending_kyc', 'male'),
       (pg_temp.p('02'), 'CPF-02', 'teacher', NULL, 'Moussa', 'Camara', 'pending_kyc', 'male'),
       (pg_temp.p('07'), 'CPF-07', 'guardian', 'cf50ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Tiers', 'active', 'female'),
       (pg_temp.p('03'), 'CPF-03', 'teacher', NULL, 'Oumar', 'Diallo', 'active', 'male'),
       (pg_temp.p('05'), 'CPF-05', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
       (pg_temp.p('06'), 'CPF-06', 'admin', NULL, 'Direction', 'Femme', 'active', 'female');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, photo_storage_key)
VALUES (pg_temp.p('01'), 'GN', ARRAY['francais'], 40, 'pending', 'Africa/Conakry', pg_temp.p('01') || '/1.jpg'),
       (pg_temp.p('02'), 'GN', ARRAY['francais'], 40, 'pending', 'Africa/Conakry', pg_temp.p('02') || '/1.jpg'),
       (pg_temp.p('03'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry', pg_temp.p('03') || '/1.jpg');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source,
                                 photo_cle_figee, photo_figee_le)
VALUES ('cf50cccc-0000-4000-8000-000000000001', 'enseignant', pg_temp.p('01'), 'male', 'Ibrahima Keita',
        'prequalification', 'en_examen', 'en_cours', 'lien_public', pg_temp.p('01') || '/1.jpg', now()),
       ('cf50cccc-0000-4000-8000-000000000003', 'enseignant', pg_temp.p('03'), 'male', 'Oumar Diallo',
        'confirmee', NULL, 'en_cours', 'lien_public', pg_temp.p('03') || '/1.jpg', now());
SET LOCAL session_replication_role = origin;

-- Le seau du banc : les droits de Supabase (la RLS du seau est deja active).
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT EXECUTE ON FUNCTION storage.foldername(text) TO authenticated;
INSERT INTO storage.objects (bucket_id, name)
VALUES ('photos_enseignants', pg_temp.p('01') || '/1.jpg'),
       ('photos_enseignants', pg_temp.p('02') || '/1.jpg'),
       ('photos_enseignants', pg_temp.p('01') || '/2.jpg'),
       ('photos_enseignants', pg_temp.p('03') || '/1.jpg'),
       ('photos_enseignants', pg_temp.p('03') || '/2.jpg');

-- (a) Le candidat : le fichier du dossier ne se remplace pas ; un autre, oui.
SELECT pg_temp.vrai(public.photo_candidat_moi() IS NOT NULL, 'a0 : fonction presente');
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_temp.p('01'), 'teacher',
    pg_catalog.format($$UPDATE storage.objects SET owner_id = auth.uid() WHERE name = %L$$, pg_temp.p('01') || '/1.jpg')) = 0
  AND pg_temp.lignes(pg_temp.p('01'), 'teacher',
    pg_catalog.format($$UPDATE storage.objects SET owner_id = auth.uid() WHERE name = %L$$, pg_temp.p('01') || '/2.jpg')) = 1,
  'a1 : le candidat ne remplace pas la photo de son dossier ; il remplace une autre photo de son dossier');
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_temp.p('01'), 'teacher',
    pg_catalog.format($$DELETE FROM storage.objects WHERE name = %L$$, pg_temp.p('01') || '/1.jpg')) = 0,
  'a2 : le candidat n''efface pas la photo de son dossier');

-- (b) L'enseignant actif : meme regle pour le fichier de son dossier.
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_temp.p('03'), 'teacher',
    pg_catalog.format($$UPDATE storage.objects SET owner_id = auth.uid() WHERE name = %L$$, pg_temp.p('03') || '/1.jpg')) = 0
  AND pg_temp.lignes(pg_temp.p('03'), 'teacher',
    pg_catalog.format($$DELETE FROM storage.objects WHERE name = %L$$, pg_temp.p('03') || '/1.jpg')) = 0
  AND pg_temp.lignes(pg_temp.p('03'), 'teacher',
    pg_catalog.format($$DELETE FROM storage.objects WHERE name = %L$$, pg_temp.p('03') || '/2.jpg')) = 1,
  'b1 : l''enseignant actif ne remplace ni n''efface la photo de son dossier ; ses autres photos restent libres');
SELECT pg_temp.vrai((SELECT count(*) FROM storage.objects
                      WHERE name IN (pg_temp.p('01') || '/1.jpg', pg_temp.p('03') || '/1.jpg')) = 2,
  'b2 : les deux fichiers de dossier sont toujours la');

-- (c) La photo d'affichage reste libre ; la direction lit celle du dossier.
UPDATE public.teacher_profiles SET photo_storage_key = pg_temp.p('01') || '/2.jpg' WHERE profile_id = pg_temp.p('01');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('05'), 'admin', $$SELECT public.photo_dossier_candidat('cf50cccc-0000-4000-8000-000000000001')$$)
    @> pg_catalog.jsonb_build_object('seau', 'photos_enseignants', 'cle', pg_temp.p('01') || '/1.jpg'),
  'c1 : la photo d''affichage a change ; la direction lit la photo du dossier');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('06'), 'admin', $$SELECT public.photo_dossier_candidat('cf50cccc-0000-4000-8000-000000000001')$$)
    = '{"erreur": "hors_portee"}'::jsonb,
  'c2 : hors du genre du lecteur : hors portee, aucune cle');
DO $refus$
BEGIN
  PERFORM pg_temp.qui(pg_temp.p('01'), 'teacher');
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.photo_dossier_candidat('cf50cccc-0000-4000-8000-000000000001');
    RAISE EXCEPTION 'PHOTO-FIGEE ROUGE : c3 : le candidat lit photo_dossier_candidat';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK c3 : le candidat ne lit pas photo_dossier_candidat (42501)';
  END;
  RESET ROLE;
END
$refus$;
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.photo_dossier_candidat(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.photo_candidature_figee(text)', 'EXECUTE'),
  'c4 : rien pour anon');

-- (d) QUI LIT LA PHOTO FIGEE, apres l'envoi (demande du garde-cap, 08/11).
-- Lecture de l'objet dans le seau : la politique photos_enseignants_lecture,
-- INCHANGEE par cette migration (son titulaire, tout role `admin`, et les
-- membres des classes de CET enseignant). Lecture de la cle par la fonction :
-- direction active, dans la portee du genre du lecteur.
CREATE FUNCTION pg_temp.vus(p_id uuid, p_role text, p_prefixe uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE pg_catalog.format($q$SELECT count(*) FROM storage.objects
                               WHERE bucket_id = 'photos_enseignants' AND name LIKE %L$q$, p_prefixe::text || '/%') INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
SELECT pg_temp.vrai(pg_temp.vus(pg_temp.p('02'), 'teacher', pg_temp.p('01')) = 0,
  'd1 : un AUTRE candidat ne voit aucun fichier du dossier d''un candidat');
SELECT pg_temp.vrai(pg_temp.vus(pg_temp.p('03'), 'teacher', pg_temp.p('01')) = 0,
  'd2 : un AUTRE enseignant (actif, sans lien) ne voit aucun fichier du dossier d''un candidat');
SELECT pg_temp.vrai(pg_temp.vus(pg_temp.p('07'), 'guardian', pg_temp.p('01')) = 0,
  'd3 : un tuteur sans lien ne voit aucun fichier du dossier d''un candidat');
SELECT pg_temp.vrai(pg_temp.vus(pg_temp.p('01'), 'teacher', pg_temp.p('01')) = 2,
  'd4 : le candidat voit ses propres fichiers (photo du dossier et photo d''affichage)');
-- FAIT CONNU, non modifie par cette migration : la lecture du SEAU par la
-- direction n'est pas partagee par genre (seule la fonction photo_dossier_candidat
-- l'est). Ce controle fige l'etat actuel pour qu'un changement se voie.
SELECT pg_temp.vrai(pg_temp.vus(pg_temp.p('06'), 'admin', pg_temp.p('01')) = 2,
  'd5 FAIT CONNU : tout role admin lit les objets du seau, meme hors de son genre (politique lecture inchangee)');
DO $refus_tiers$
DECLARE v_u uuid;
BEGIN
  FOREACH v_u IN ARRAY ARRAY[pg_temp.p('02'), pg_temp.p('03'), pg_temp.p('07')] LOOP
    PERFORM pg_temp.qui(v_u, CASE WHEN v_u = pg_temp.p('07') THEN 'guardian' ELSE 'teacher' END);
    SET LOCAL ROLE authenticated;
    BEGIN
      PERFORM public.photo_dossier_candidat('cf50cccc-0000-4000-8000-000000000001');
      RAISE EXCEPTION 'PHOTO-FIGEE ROUGE : d6 : un tiers lit photo_dossier_candidat';
    EXCEPTION WHEN insufficient_privilege THEN
      NULL;
    END;
    RESET ROLE;
  END LOOP;
  RAISE NOTICE 'OK d6 : ni un autre candidat, ni un enseignant, ni un tuteur ne lit la cle (42501)';
END
$refus_tiers$;

-- (e) Le rattrapage de la migration n'ecrase jamais une cle deja figee.
-- Meme instruction que la migration (section 5), rejouee sur le candidat 01 dont
-- la photo d'affichage vaut maintenant 2.jpg alors que la cle figee est 1.jpg.
WITH touchees AS (
  UPDATE public.candidatures c
     SET photo_cle_figee = tp.photo_storage_key,
         photo_figee_le = pg_catalog.clock_timestamp()
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = c.profile_id
     AND tp.photo_storage_key IS NOT NULL
     AND c.photo_cle_figee IS NULL
   RETURNING c.id)
SELECT pg_temp.vrai((SELECT count(*) FROM touchees) = 0
  AND (SELECT c.photo_cle_figee FROM public.candidatures c WHERE c.id = 'cf50cccc-0000-4000-8000-000000000001')
        = pg_temp.p('01') || '/1.jpg',
  'e1 : le rattrapage ne touche aucune ligne deja figee ; la cle du dossier reste la premiere');

-- (f) Garde-cap (08/11) : la photo n'est figee qu'UNE fois ; et les politiques du
-- seau evaluent private.photo_candidature_figee meme si `authenticated` n'a pas
-- USAGE sur le schema private (le nom est resolu a la creation de la politique,
-- seul EXECUTE est verifie a l'evaluation).
SELECT pg_temp.vrai(
  pg_catalog.strpos(pg_catalog.pg_get_functiondef(
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure),
    'WHERE id = v_id AND photo_cle_figee IS NULL') > 0,
  'f1 : l''envoi ne reecrit jamais une photo deja figee (photo_cle_figee IS NULL dans la fonction)');
SELECT pg_temp.vrai(
  pg_temp.lignes(pg_temp.p('01'), 'teacher',
    pg_catalog.format($$UPDATE storage.objects SET owner_id = auth.uid() WHERE name = %L$$, pg_temp.p('01') || '/2.jpg')) = 1
  AND pg_temp.lignes(pg_temp.p('01'), 'teacher',
    pg_catalog.format($$UPDATE storage.objects SET owner_id = auth.uid() WHERE name = %L$$, pg_temp.p('01') || '/1.jpg')) = 0,
  pg_catalog.format('f2 : USAGE de authenticated sur private = %s ; les politiques du seau evaluent quand meme la fonction (fichier libre : 1 ligne, fichier fige : 0)',
                    pg_catalog.has_schema_privilege('authenticated', 'private', 'USAGE')));

ROLLBACK;
