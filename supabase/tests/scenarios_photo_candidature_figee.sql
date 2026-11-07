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

-- Fixtures : c1 candidat en cours (dossier fige), e1 enseignant actif dont le
-- dossier est fige, a1 direction homme, a2 direction femme.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'photo-figee-' || n || '@test.invalid' FROM unnest(ARRAY['01','03','05','06']) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('01'), 'CPF-01', 'teacher', 'Ibrahima', 'Keita', 'pending_kyc', 'male'),
       (pg_temp.p('03'), 'CPF-03', 'teacher', 'Oumar', 'Diallo', 'active', 'male'),
       (pg_temp.p('05'), 'CPF-05', 'admin', 'Direction', 'Homme', 'active', 'male'),
       (pg_temp.p('06'), 'CPF-06', 'admin', 'Direction', 'Femme', 'active', 'female');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, photo_storage_key)
VALUES (pg_temp.p('01'), 'GN', ARRAY['francais'], 40, 'pending', 'Africa/Conakry', pg_temp.p('01') || '/1.jpg'),
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

ROLLBACK;
