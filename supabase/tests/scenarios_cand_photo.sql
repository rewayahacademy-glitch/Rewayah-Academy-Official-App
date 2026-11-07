-- CAND-PHOTO (06/11/2026). Migration 20261110330000_cand_photo.sql.
--
-- Cas couverts : (a) la photo du candidat : un candidat (teacher, pending_kyc,
-- candidature en cours) la pose et la retire ; une cle hors de son dossier est
-- refusee ; un enseignant sans candidature en cours, un tuteur et un candidat
-- dont la candidature est close sont refuses ; (b) l'embauche : le compte
-- devient actif, la photo reste la meme (meme ligne teacher_profiles), et le
-- candidat embauche la voit par photo_source ; (c) l'accord de publication :
-- donne a la version courante avec le nom du compte comme signature, une
-- version perimee refusee sans ecriture, rejoue sans doublon, retire (la ligne
-- reste, datee), redonne (nouvelle ligne) ; l'accord en cours se lit par
-- private.accord_publication_en_cours ; un autre compte ne lit pas l'accord
-- d'autrui ; aucune ecriture client directe ; (d) la politique du seau.
-- Le refus « photo_requise » d'un envoi complet est dans
-- scenarios_cand_l2a2_gestes_direction.sql (parcours reel).
-- Chaque controle leve 'CAND-PHOTO ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE ; le scenario annule tout a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CAND-PHOTO ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
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

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'CAND-PHOTO ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-PHOTO ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf300000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Fixtures : c1 candidat en cours, c2 candidat dont la candidature est close,
-- e1 enseignant actif sans candidature, a1 direction.
-- Les gardes d'activation d'un enseignant (contrat signe) ne sont pas l'objet
-- de ce scenario : les fixtures et l'embauche simulee les contournent.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'cand-photo-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05']) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('01'), 'CPH-01', 'teacher', 'Ibrahima', 'Keita', 'pending_kyc', 'male'),
       (pg_temp.p('02'), 'CPH-02', 'teacher', 'Moussa', 'Camara', 'pending_kyc', 'male'),
       (pg_temp.p('03'), 'CPH-03', 'teacher', 'Aminata', 'Diallo', 'active', 'female'),
       (pg_temp.p('05'), 'CPH-05', 'admin', 'Direction', 'Photo', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES (pg_temp.p('01'), 'GN', ARRAY['francais'], 40, 'pending', 'Africa/Conakry'),
       (pg_temp.p('02'), 'GN', ARRAY['francais'], 40, 'pending', 'Africa/Conakry'),
       (pg_temp.p('03'), 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris');
INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES ('enseignant', pg_temp.p('01'), 'male', 'Ibrahima Keita', 'prequalification', 'a_completer', 'en_cours', 'lien_public'),
       ('enseignant', pg_temp.p('02'), 'male', 'Moussa Camara', 'prequalification', 'a_completer', 'refusee', 'lien_public');
SET LOCAL session_replication_role = origin;

-- (a) La photo du candidat.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT to_jsonb(public.photo_candidat_moi())$$) = 'true'
  AND pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT to_jsonb(public.photo_candidat_moi())$$) = 'false'
  AND pg_temp.en(pg_temp.p('03'), 'teacher', $$SELECT to_jsonb(public.photo_candidat_moi())$$) = 'false'
  AND pg_temp.en(pg_temp.p('05'), 'admin', $$SELECT to_jsonb(public.photo_candidat_moi())$$) = 'false',
  'a1 : photo_candidat_moi vrai pour le seul titulaire d''une candidature en cours');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher',
    $$SELECT to_jsonb(r) FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000001/portrait.jpg') r$$)
    = jsonb_build_object('profile_id', pg_temp.p('01'), 'seau', 'photos_enseignants',
                         'cle', 'cf300000-0000-4000-8000-000000000001/portrait.jpg'),
  'a2 : le candidat pose sa photo, seau photos_enseignants');
SELECT pg_temp.vrai((SELECT photo_storage_key FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01'))
      = 'cf300000-0000-4000-8000-000000000001/portrait.jpg',
  'a2bis : dans la meme colonne que l''enseignant (teacher_profiles.photo_storage_key)');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  $$SELECT * FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000003/autre.jpg')$$,
  '22023', 'a3 : une cle hors de son dossier est refusee');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  $$SELECT * FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000001/../x.jpg')$$,
  '22023', 'a4 : une cle qui remonte de dossier est refusee');
SELECT pg_temp.refus_en(pg_temp.p('02'), 'teacher',
  $$SELECT * FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000002/p.jpg')$$,
  '42501', 'a5 : candidature close : refus');
SELECT pg_temp.refus_en(pg_temp.p('03'), 'teacher',
  $$SELECT * FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000003/p.jpg')$$,
  '42501', 'a6 : enseignant sans candidature en cours : refus (il passe par poser_ma_photo)');
SELECT pg_temp.refus_en(pg_temp.p('05'), 'admin',
  $$SELECT * FROM public.poser_photo_candidat('cf300000-0000-4000-8000-000000000005/p.jpg')$$,
  '42501', 'a7 : un compte qui n''est pas candidat (direction) : refus');
-- Une ecriture directe de la colonne par le candidat ne change rien (refus,
-- ou aucune ligne visible en ecriture) : seule la RPC pose la photo.
DO $a8$
BEGIN
  PERFORM pg_temp.qui(pg_temp.p('01'), 'teacher');
  SET LOCAL ROLE authenticated;
  BEGIN
    UPDATE public.teacher_profiles SET photo_storage_key = NULL WHERE profile_id = auth.uid();
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  RESET ROLE;
END $a8$;
SELECT pg_temp.vrai((SELECT photo_storage_key FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01'))
      = 'cf300000-0000-4000-8000-000000000001/portrait.jpg',
  'a8 : une ecriture directe de la colonne par le candidat ne change rien');

SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher',
    $$SELECT coalesce(jsonb_agg(r.cle), '[]') FROM public.photos_personnes(ARRAY[auth.uid(),
      'cf300000-0000-4000-8000-000000000003'::uuid]) r$$)
    = '["cf300000-0000-4000-8000-000000000001/portrait.jpg"]'::jsonb,
  'a9 : le candidat lit sa propre photo, et seulement la sienne');

-- (b) L'embauche : meme ligne, meme photo.
SET LOCAL session_replication_role = replica;
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.p('01');
UPDATE public.candidatures SET etape = 'confirmee', etat = NULL WHERE profile_id = pg_temp.p('01');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.vrai((SELECT cle FROM private.photo_source(pg_temp.p('01')))
    = 'cf300000-0000-4000-8000-000000000001/portrait.jpg'
  AND (SELECT seau FROM private.photo_source(pg_temp.p('01'))) = 'photos_enseignants'
  AND (SELECT count(*) FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01')) = 1,
  'b1 : embauche : la photo du candidat est celle de l''enseignant, sans nouvel envoi');
SET LOCAL session_replication_role = replica;
UPDATE public.profiles SET account_status = 'pending_kyc' WHERE id = pg_temp.p('01');
UPDATE public.candidatures SET etape = 'prequalification', etat = 'a_completer' WHERE profile_id = pg_temp.p('01');
SET LOCAL session_replication_role = origin;

-- (c) L'accord de publication.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.mon_accord_publication()$$)
    @> '{"versionCourante": "publication-2026-11-v1", "enCours": false, "nomCompte": "Ibrahima Keita"}'::jsonb,
  'c1 : la version courante est lue ; aucun accord par defaut');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher',
    $$SELECT public.accepter_accord_publication('publication-2025-01-v0')$$)
    = '{"erreur": "version_perimee", "versionCourante": "publication-2026-11-v1"}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM public.accords_publication WHERE profile_id = pg_temp.p('01')),
  'c2 : une version perimee est refusee, sans ecriture');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher',
    $$SELECT public.accepter_accord_publication('publication-2026-11-v1')$$)
    @> '{"enCours": true, "version": "publication-2026-11-v1", "nomSigne": "Ibrahima Keita"}'::jsonb,
  'c3 : accord donne, signe du nom du compte relu au serveur, en cours');
SELECT pg_temp.vrai(private.accord_publication_en_cours(pg_temp.p('01')), 'c3bis : l''accord en cours se lit pour le site');
SELECT pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.accepter_accord_publication('publication-2026-11-v1')$$);
SELECT pg_temp.vrai((SELECT count(*) FROM public.accords_publication WHERE profile_id = pg_temp.p('01')) = 1,
  'c4 : rejoue a la meme version : aucune ligne de plus');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('03'), 'teacher',
    $$SELECT coalesce(jsonb_agg(a.id), '[]') FROM public.accords_publication a$$) = '[]'::jsonb
  AND pg_temp.en(pg_temp.p('05'), 'admin',
    $$SELECT to_jsonb(count(*)) FROM public.accords_publication a$$) = '1'::jsonb,
  'c5 : un autre enseignant ne lit pas l''accord d''autrui ; la direction le lit');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  $$INSERT INTO public.accords_publication (profile_id, version, nom_signe) VALUES (auth.uid(), 'x', 'Faux nom')$$,
  '42501', 'c6 : aucune ecriture client directe (insertion)');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  $$UPDATE public.accords_publication SET nom_signe = 'Faux nom'$$,
  '42501', 'c7 : aucune ecriture client directe (modification)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.retirer_accord_publication()$$)
    @> '{"enCours": false}'::jsonb,
  'c8 : retire : plus en cours');
SELECT pg_temp.vrai(NOT private.accord_publication_en_cours(pg_temp.p('01'))
  AND (SELECT count(*) FROM public.accords_publication
        WHERE profile_id = pg_temp.p('01') AND retire_le IS NOT NULL) = 1,
  'c8bis : la ligne reste, avec sa date de retrait');
SELECT pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.accepter_accord_publication('publication-2026-11-v1')$$);
SELECT pg_temp.vrai((SELECT count(*) FROM public.accords_publication WHERE profile_id = pg_temp.p('01')) = 2
  AND private.accord_publication_en_cours(pg_temp.p('01')),
  'c9 : redonne apres retrait : une nouvelle ligne, en cours');
SELECT pg_temp.refus_en(pg_temp.p('05'), 'admin', $$SELECT public.accepter_accord_publication('publication-2026-11-v1')$$,
  '42501', 'c10 : un compte qui n''est pas enseignant ne donne pas d''accord de publication');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('03'), 'teacher',
    $$SELECT public.accepter_accord_publication('publication-2026-11-v1')$$) @> '{"enCours": true, "nomSigne": "Aminata Diallo"}'::jsonb,
  'c11 : un enseignant actif donne aussi son accord (Profil de l''enseignant)');

-- (d) Droits et seau.
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.accord_publication_en_cours(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.poser_photo_candidat(text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.accepter_accord_publication(text)', 'EXECUTE'),
  'd1 : lecture du site privee ; rien pour anon');
SELECT pg_temp.vrai(to_regclass('storage.objects') IS NULL OR (
    (SELECT count(*) FROM pg_policies WHERE schemaname = 'storage'
      AND policyname IN ('photos_enseignants_ajout_candidat', 'photos_enseignants_remplacement_candidat')) = 2
    AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage'
      AND policyname LIKE 'photos\_enseignants\_%candidat' AND cmd NOT IN ('INSERT', 'UPDATE'))),
  'd2 : le candidat ajoute et remplace sa photo, il n''efface aucun objet');

ROLLBACK;
