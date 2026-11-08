-- PHOTO-LECTURE-COURANTE (08/11/2026) : dans le seau `photos_enseignants`, un
-- eleve ou une famille de la classe d'un enseignant ne lit, dans son dossier, que
-- sa photo d'affichage ACTUELLE ; jamais un ancien fichier ni le fichier fige de
-- sa candidature. Le titulaire et tout role `admin` gardent leurs droits. Migration
-- 20261121400000_photo_lecture_courante.sql.
--
-- ROUGE sur main (sans la migration) : l'eleve y lit un ancien fichier. VERT avec.
-- Chaque controle leve 'PHOTO-LECTURE ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE ; tout est annule a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PHOTO-LECTURE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf700000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Combien d'objets du seau, de ce nom exact, la session lit.
CREATE FUNCTION pg_temp.lus(p_id uuid, p_role text, p_foyer uuid, p_nom text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v FROM storage.objects
   WHERE bucket_id = 'photos_enseignants' AND name = p_nom;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Combien d'objets du dossier d'un enseignant la session voit (lister le dossier).
CREATE FUNCTION pg_temp.dossier(p_id uuid, p_role text, p_foyer uuid, p_enseignant uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v FROM storage.objects
   WHERE bucket_id = 'photos_enseignants' AND name LIKE p_enseignant::text || '/%';
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Fixtures.
--   01 enseignant T (photo courante T/courante.jpg ; anciens fichiers ancien.jpg et figee.jpg)
--   02 enseignant T2 (autre classe, sans lien avec les eleves ci-dessous)
--   03 eleve S, membre de la classe de T (foyer F1) ; 04 tuteur de S (foyer F1)
--   05 eleve S3 d'un autre foyer, dans aucune classe ; 06 direction
--   07 eleve S4, sorti de la classe de T (left_at pose) ; 08 enseignant T3 sans photo ;
--   09 eleve de la classe de T3
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(n), 'photo-lecture-' || n || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05','06','07','08','09']) n;
INSERT INTO public.households (id, timezone) VALUES
  ('cf70ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris'),
  ('cf70ffff-ffff-4fff-8fff-000000000002', 'Europe/Paris'),
  ('cf70ffff-ffff-4fff-8fff-000000000003', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'PLC-01', 'teacher', NULL, 'Ens', 'Courant', 'active', 'male'),
  (pg_temp.p('02'), 'PLC-02', 'teacher', NULL, 'Ens', 'Autre', 'active', 'male'),
  (pg_temp.p('03'), 'PLC-03', 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', 'Eleve', 'Membre', 'active', 'male'),
  (pg_temp.p('04'), 'PLC-04', 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Membre', 'active', 'female'),
  (pg_temp.p('05'), 'PLC-05', 'student', 'cf70ffff-ffff-4fff-8fff-000000000002', 'Eleve', 'Tiers', 'active', 'male'),
  (pg_temp.p('06'), 'PLC-06', 'admin', NULL, 'Direction', 'Une', 'active', 'female'),
  (pg_temp.p('07'), 'PLC-07', 'student', 'cf70ffff-ffff-4fff-8fff-000000000003', 'Eleve', 'Sorti', 'active', 'male'),
  (pg_temp.p('08'), 'PLC-08', 'teacher', NULL, 'Ens', 'SansPhoto', 'active', 'male'),
  (pg_temp.p('09'), 'PLC-09', 'student', 'cf70ffff-ffff-4fff-8fff-000000000002', 'Eleve', 'ClasseSansPhoto', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, photo_storage_key) VALUES
  (pg_temp.p('01'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry', pg_temp.p('01') || '/courante.jpg'),
  (pg_temp.p('02'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry', pg_temp.p('02') || '/courante.jpg'),
  (pg_temp.p('08'), 'GN', ARRAY['francais'], 40, 'approved', 'Africa/Conakry', NULL);
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
  ('cf7000aa-0000-4000-8000-000000000001', pg_temp.p('01'), 'enfant', 5, 'Classe essai 1', 1, 18, 'Europe/Paris'),
  ('cf7000aa-0000-4000-8000-000000000008', pg_temp.p('08'), 'enfant', 5, 'Classe essai 8', 2, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id, left_at, left_by, left_reason) VALUES
  ('cf7000aa-0000-4000-8000-000000000001', pg_temp.p('03'), NULL, NULL, NULL),
  ('cf7000aa-0000-4000-8000-000000000001', pg_temp.p('07'), now(), pg_temp.p('06'), 'Fixture : sorti de la classe'),
  ('cf7000aa-0000-4000-8000-000000000008', pg_temp.p('09'), NULL, NULL, NULL);
-- Le fichier fige d'une candidature (PHOTO-CANDIDATURE-FIGEE), quand cette
-- migration est deja installee : l'ancien fichier figee.jpg en est la cle.
DO $fige$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'candidatures'
                AND column_name = 'photo_cle_figee') THEN
    EXECUTE pg_catalog.format($q$
      INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source,
                                       photo_cle_figee, photo_figee_le)
      VALUES ('cf70cccc-0000-4000-8000-000000000001', 'enseignant', %L, 'male', 'Ens Courant',
              'confirmee', NULL, 'en_cours', 'lien_public', %L, now())$q$,
      pg_temp.p('01'), pg_temp.p('01') || '/figee.jpg');
    RAISE NOTICE 'fixture : photo figee posee (PHOTO-CANDIDATURE-FIGEE installee)';
  ELSE
    RAISE NOTICE 'fixture : PHOTO-CANDIDATURE-FIGEE absente, figee.jpg est un ancien fichier comme un autre';
  END IF;
END
$fige$;
SET LOCAL session_replication_role = origin;

GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT EXECUTE ON FUNCTION storage.foldername(text) TO authenticated;
INSERT INTO storage.objects (bucket_id, name) VALUES
  ('photos_enseignants', pg_temp.p('01') || '/courante.jpg'),
  ('photos_enseignants', pg_temp.p('01') || '/ancien.jpg'),
  ('photos_enseignants', pg_temp.p('01') || '/figee.jpg'),
  ('photos_enseignants', pg_temp.p('02') || '/courante.jpg'),
  ('photos_enseignants', pg_temp.p('08') || '/ancien.jpg');

-- (a) L'eleve de la classe : la photo courante, rien d'autre.
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/courante.jpg') = 1,
  'a1 : l''eleve de la classe lit la photo d''affichage actuelle de son enseignant');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/ancien.jpg') = 0,
  'a2 : l''eleve ne lit pas un ancien fichier du dossier de l''enseignant');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/figee.jpg') = 0,
  'a3 : l''eleve ne lit pas le fichier fige de la candidature');
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01')) = 1,
  'a4 : l''eleve qui liste le dossier de l''enseignant n''y voit que la photo actuelle (1 objet sur 3)');

-- (b) La famille de l'eleve : meme regle.
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/courante.jpg') = 1
  AND pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/ancien.jpg') = 0
  AND pg_temp.lus(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/figee.jpg') = 0
  AND pg_temp.dossier(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01')) = 1,
  'b1 : le tuteur de l''eleve lit la photo actuelle, ni un ancien fichier, ni le fichier fige, et ne voit qu''elle en listant');

-- (c) Les tiers ne lisent rien.
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('05'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000002', pg_temp.p('01')) = 0,
  'c1 : un eleve d''un autre foyer, dans aucune classe, ne lit rien du dossier');
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('07'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000003', pg_temp.p('01')) = 0,
  'c2 : un eleve sorti de la classe ne lit plus rien du dossier');
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('02')) = 0,
  'c3 : l''eleve ne lit rien du dossier d''un enseignant dont il n''est pas de la classe');
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('02'), 'teacher', NULL, pg_temp.p('01')) = 0,
  'c4 : un autre enseignant ne lit rien du dossier de T');

-- (d) Inchange : le titulaire lit tout son dossier, la direction lit tout le seau.
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('01'), 'teacher', NULL, pg_temp.p('01')) = 3,
  'd1 : le titulaire lit tous les fichiers de son dossier (3 sur 3)');
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('06'), 'admin', NULL, pg_temp.p('01')) = 3
  AND pg_temp.dossier(pg_temp.p('06'), 'admin', NULL, pg_temp.p('02')) = 1,
  'd2 FAIT CONNU, inchange : tout role admin lit tout le seau (decision de genre : lot a part)');

-- (e) La photo suit la photo d'affichage : quand l'enseignant en change, la
-- nouvelle est lisible et l'ancienne ne l'est plus.
UPDATE public.teacher_profiles SET photo_storage_key = pg_temp.p('01') || '/ancien.jpg' WHERE profile_id = pg_temp.p('01');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/ancien.jpg') = 1
  AND pg_temp.lus(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01') || '/courante.jpg') = 0,
  'e1 : l''enseignant change de photo : la nouvelle est lisible par sa classe, l''ancienne ne l''est plus');
UPDATE public.teacher_profiles SET photo_storage_key = pg_temp.p('01') || '/courante.jpg' WHERE profile_id = pg_temp.p('01');

-- (f) Un enseignant sans photo d'affichage : sa classe ne lit rien de son dossier.
SELECT pg_temp.vrai(pg_temp.dossier(pg_temp.p('09'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000002', pg_temp.p('08')) = 0,
  'f1 : un enseignant sans photo d''affichage : sa classe ne lit aucun fichier de son dossier');

-- (g) La fonction : lue par la politique, jamais ouverte a anon.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'private.photo_affichage_courante(text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.photo_affichage_courante(text)', 'EXECUTE')
  AND NOT private.photo_affichage_courante(NULL),
  'g1 : EXECUTE pour authenticated, rien pour anon ; une cle nulle n''est jamais une photo courante');

-- (h) Aucune regression d'affichage : la cle que le serveur rend au client pour la
-- photo d'un enseignant (photos_personnes ; vue des classes du foyer) est
-- lisible par la personne qui la demande.
CREATE FUNCTION pg_temp.affichage(p_id uuid, p_role text, p_foyer uuid, p_ens uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v
    FROM public.photos_personnes(ARRAY[p_ens]) x
    JOIN storage.objects o ON o.bucket_id = x.seau AND o.name = x.cle;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.affichage_vue(p_id uuid, p_role text, p_foyer uuid) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT count(*)::integer INTO v
    FROM public.mes_groupes_famille_v g
    JOIN storage.objects o ON o.bucket_id = 'photos_enseignants' AND o.name = g.teacher_photo_cle;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
SELECT pg_temp.vrai(
  pg_temp.affichage(pg_temp.p('03'), 'student', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01')) = 1
  AND pg_temp.affichage(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001', pg_temp.p('01')) = 1,
  'h1 : photos_personnes rend a l''eleve et a son tuteur la cle de la photo de l''enseignant, et cette cle est lisible');
SELECT pg_temp.vrai(
  pg_temp.affichage_vue(pg_temp.p('04'), 'guardian', 'cf70ffff-ffff-4fff-8fff-000000000001') >= 1,
  'h2 : la vue des classes du foyer rend au tuteur la cle de la photo de l''enseignant, et cette cle est lisible');

ROLLBACK;
