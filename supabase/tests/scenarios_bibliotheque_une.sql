-- LOT 3 · BIBLIOTHEQUE-UNE (12/11/2026) : migrations 20261123920000 et
-- 20261123921000, rejouees sur un Postgres nu apres stub_auth.sql et toutes les
-- migrations. A executer sur base jetable seulement (le script finit par
-- ROLLBACK).
--
--   1. types audio, video, external_link ; deux rayons en donnee, fr et ar ;
--      aucune colonne de prix, aucune cle « prix » acceptee ;
--   2. le Coran seme : document du rayon des cours, publie, visible des
--      inscrits, idempotent ;
--   3. la lecture du lecteur : droits par visibilite (etranger, autre classe,
--      brouillon refuses ; classe assignee visible de ses membres, de leur foyer
--      et de son enseignant ; anonyme refuse), filtres (type, rayon, etape,
--      classe), ordre, pagination, aucune cle de stockage ni colonne reservee ;
--   4. la direction : lien externe (https exige, description exigee), etapes
--      par code, controle et publication d'un lien, vignette en deux temps avec
--      confirmation signee ;
--   5. la chaine « document publie -> droit verifie -> cle a signer » ;
--   6. les droits d'execution.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('b3100000-0000-0000-0000-000000000001', 'b31-direction@example.test'),
  ('b3100000-0000-0000-0000-000000000002', 'b31-eleve@example.test'),
  ('b3100000-0000-0000-0000-000000000003', 'b31-dehors@example.test'),
  ('b3100000-0000-0000-0000-000000000004', 'b31-tuteur@example.test'),
  ('b3100000-0000-0000-0000-000000000005', 'b31-enseignant@example.test'),
  ('b3100000-0000-0000-0000-000000000006', 'b31-autre-classe@example.test'),
  ('b3100000-0000-0000-0000-000000000007', 'b31-enseignant2@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('b31fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('b31fffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('b31fffff-0000-0000-0000-000000000003', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b3100000-0000-0000-0000-000000000001', 'B31DIRECTION0001', 'admin', NULL, 'Direction', 'Trois', 'active', 'female'),
  ('b3100000-0000-0000-0000-000000000002', 'B31ELEVE0000002', 'student', 'b31fffff-0000-0000-0000-000000000001', 'Nour', 'Trois', 'active', NULL),
  ('b3100000-0000-0000-0000-000000000003', 'B31DEHORS000003', 'student', 'b31fffff-0000-0000-0000-000000000002', 'Dehors', 'Trois', 'active', NULL),
  ('b3100000-0000-0000-0000-000000000004', 'B31TUTEUR000004', 'guardian', 'b31fffff-0000-0000-0000-000000000001', 'Tuteur', 'Trois', 'active', NULL),
  ('b3100000-0000-0000-0000-000000000005', 'B31ENSEIGN00005', 'teacher', NULL, 'Enseignant', 'Trois', 'provisional_active', 'male'),
  ('b3100000-0000-0000-0000-000000000006', 'B31AUTRECL00006', 'student', 'b31fffff-0000-0000-0000-000000000003', 'Autre', 'Classe', 'active', NULL),
  ('b3100000-0000-0000-0000-000000000007', 'B31ENSEIGN00007', 'teacher', NULL, 'Enseignant', 'Deux', 'provisional_active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  ('b3100000-0000-0000-0000-000000000002', 'minor', 'child'),
  ('b3100000-0000-0000-0000-000000000003', 'minor', 'child'),
  ('b3100000-0000-0000-0000-000000000006', 'minor', 'child');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('b3100000-0000-0000-0000-000000000021', 'b3100000-0000-0000-0000-000000000005', 'enfant', 5, 'Classe B31 une', 1, 18, 'Europe/Paris'),
  ('b3100000-0000-0000-0000-000000000022', 'b3100000-0000-0000-0000-000000000007', 'enfant', 5, 'Classe B31 deux', 2, 17, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('b3100000-0000-0000-0000-000000000021', 'b3100000-0000-0000-0000-000000000002'),
  ('b3100000-0000-0000-0000-000000000022', 'b3100000-0000-0000-0000-000000000006');

-- Les tranches d'age des trois enfants (D1) : 6-9, 10-13, 14-17.
UPDATE public.student_profiles SET cohorte = 'enfant_6_9' WHERE profile_id = 'b3100000-0000-0000-0000-000000000002';
UPDATE public.student_profiles SET cohorte = 'enfant_10_13' WHERE profile_id = 'b3100000-0000-0000-0000-000000000003';
UPDATE public.student_profiles SET cohorte = 'ado_14_17' WHERE profile_id = 'b3100000-0000-0000-0000-000000000006';

CREATE FUNCTION pg_temp.qui(p_uid text, p_role text, p_foyer text DEFAULT NULL) RETURNS void
LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_uid, true),
         set_config('request.jwt.claims', jsonb_build_object('sub', p_uid,
           'app_metadata', jsonb_build_object('role', p_role, 'household_id', p_foyer))::text, true);
$$;
CREATE FUNCTION pg_temp.titres(p jsonb) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(string_agg(e ->> 'title', ',' ORDER BY ord), '') FROM jsonb_array_elements(p) WITH ORDINALITY x(e, ord) $$;
CREATE FUNCTION pg_temp.titres_tries(p jsonb) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(string_agg(e ->> 'title', ',' ORDER BY e ->> 'title'), '') FROM jsonb_array_elements(p) e $$;

-- ---------------------------------------------------------------------------
-- 0. Les types, les rayons, l'absence de prix
-- ---------------------------------------------------------------------------
DO $socle$
DECLARE v_n integer;
BEGIN
  SELECT count(*) INTO v_n FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
   WHERE t.typname = 'library_resource_type' AND e.enumlabel IN ('audio', 'video', 'external_link', 'quran', 'pdf', 'image', 'lesson', 'structured_text');
  IF v_n <> 8 THEN RAISE EXCEPTION 'B31 ROUGE : types attendus 8, trouves %', v_n; END IF;
  IF (SELECT titre_fr FROM public.library_rayon WHERE code = 'cours') <> 'Documents des cours'
     OR (SELECT titre_ar FROM public.library_rayon WHERE code = 'cours') <> 'وثائق الدروس'
     OR (SELECT titre_fr FROM public.library_rayon WHERE code = 'plus_loin') <> 'Pour aller plus loin'
     OR (SELECT titre_ar FROM public.library_rayon WHERE code = 'plus_loin') <> 'للتعمّق أكثر'
     OR (SELECT ordre FROM public.library_rayon WHERE code = 'cours') >= (SELECT ordre FROM public.library_rayon WHERE code = 'plus_loin') THEN
    RAISE EXCEPTION 'B31 ROUGE : les deux rayons ne sont pas ceux de la charte';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = 'public.library_resource'::regclass AND a.attnum > 0
                AND NOT a.attisdropped AND a.attname ~* '(prix|price|montant|amount|cents|tarif)') THEN
    RAISE EXCEPTION 'B31 ROUGE : une colonne de prix existe';
  END IF;
  IF has_table_privilege('anon', 'public.library_rayon', 'SELECT') THEN
    RAISE EXCEPTION 'B31 ROUGE : anon lit les rayons';
  END IF;
  -- Une valeur de rayon inconnue est refusee par la base elle-meme.
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, rayon)
    VALUES ('x', 'x', 'pdf', 'admin', 'jamais', 'boutique');
    RAISE EXCEPTION 'B31 ROUGE : rayon inconnu accepte';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
  -- Un lien http, une adresse IP, un lien sans description, un lien sur un PDF : refuses par la base.
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, lien_externe, description)
    VALUES ('x', 'x', 'external_link', 'admin', 'jamais', 'http://exemple.org/a', 'd');
    RAISE EXCEPTION 'B31 ROUGE : lien http accepte';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, lien_externe, description)
    VALUES ('x', 'x', 'external_link', 'admin', 'jamais', 'https://127.0.0.1/a', 'd');
    RAISE EXCEPTION 'B31 ROUGE : lien vers une adresse IP accepte';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, lien_externe)
    VALUES ('x', 'x', 'external_link', 'admin', 'jamais', 'https://exemple.org/a');
    RAISE EXCEPTION 'B31 ROUGE : lien externe sans description accepte';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, lien_externe, description)
    VALUES ('x', 'x', 'pdf', 'admin', 'jamais', 'https://exemple.org/a', 'd');
    RAISE EXCEPTION 'B31 ROUGE : lien sur un PDF accepte';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.library_resource (title, short_title, resource_type, access_policy, offline_policy, etapes)
    VALUES ('x', 'x', 'pdf', 'admin', 'jamais', ARRAY['a b']);
    RAISE EXCEPTION 'B31 ROUGE : code d''etape invalide accepte';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END
$socle$;

-- ---------------------------------------------------------------------------
-- 1. Le Coran est un document du rayon des cours (le compte direction existe)
-- ---------------------------------------------------------------------------
DO $coran$
DECLARE v_id uuid; v_encore uuid; v_r public.library_resource%ROWTYPE;
BEGIN
  v_id := app_private.library_semer_coran();
  IF v_id IS NULL THEN RAISE EXCEPTION 'B31 ROUGE : le Coran n''est pas seme malgre un compte direction'; END IF;
  SELECT * INTO v_r FROM public.library_resource WHERE id = v_id;
  IF v_r.resource_type::text <> 'quran' OR v_r.rayon <> 'cours' OR v_r.access_policy::text <> 'inscrits'
     OR v_r.current_version_id IS NULL OR v_r.archived_at IS NOT NULL OR v_r.language <> 'ar' THEN
    RAISE EXCEPTION 'B31 ROUGE : Coran mal seme %', to_jsonb(v_r);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.resource_version v WHERE v.id = v_r.current_version_id AND v.statut = 'publiee') THEN
    RAISE EXCEPTION 'B31 ROUGE : la version du Coran n''est pas publiee';
  END IF;
  v_encore := app_private.library_semer_coran();
  IF v_encore <> v_id OR (SELECT count(*) FROM public.library_resource WHERE resource_type::text = 'quran') <> 1 THEN
    RAISE EXCEPTION 'B31 ROUGE : semer le Coran n''est pas idempotent';
  END IF;
END
$coran$;

-- ---------------------------------------------------------------------------
-- 2. Un catalogue de huit documents, deux rayons
-- ---------------------------------------------------------------------------
INSERT INTO public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy, category, language,
   rayon, ordre, description, lien_externe, etapes, vignette_cle)
VALUES
  ('b3100000-0000-0000-0000-000000000101', 'Doc cours', 'Doc cours', 'pdf', 'inscrits', 'jamais', 'lecture', 'fr',
   'cours', 2, 'Le document des lettres.', NULL, ARRAY['E_LETTRES'], NULL),
  ('b3100000-0000-0000-0000-000000000102', 'Audio lettres', 'Audio lettres', 'audio', 'inscrits', 'jamais', 'lecture', 'ar',
   'cours', 1, 'La voix de la direction.', NULL, ARRAY['E_LETTRES', 'E_VOYELLES'], NULL),
  ('b3100000-0000-0000-0000-000000000103', 'Lien externe', 'Lien externe', 'external_link', 'inscrits', 'jamais', 'lecture', 'fr',
   'plus_loin', 1, 'Un site pour aller plus loin.', 'https://exemple.org/page?a=1', '{}', NULL),
  ('b3100000-0000-0000-0000-000000000104', 'Video', 'Video', 'video', 'publique', 'jamais', 'lecture', 'fr',
   'plus_loin', 0, 'Une video par lien.', 'https://video.exemple.org/v/1', '{}', NULL),
  ('b3100000-0000-0000-0000-000000000105', 'Doc classe', 'Doc classe', 'pdf', 'groupe_assigne', 'jamais', 'lecture', 'fr',
   'cours', 3, NULL, NULL, '{}', NULL),
  ('b3100000-0000-0000-0000-000000000106', 'Brouillon', 'Brouillon', 'pdf', 'inscrits', 'jamais', 'lecture', 'fr',
   'cours', 5, NULL, NULL, '{}', NULL),
  ('b3100000-0000-0000-0000-000000000107', 'Doc classe deux', 'Doc classe deux', 'pdf', 'groupe_assigne', 'jamais', 'lecture', 'fr',
   'cours', 6, NULL, NULL, '{}', NULL),
  ('b3100000-0000-0000-0000-000000000108', 'Image', 'Image', 'image', 'inscrits', 'jamais', 'lecture', 'fr',
   'cours', 4, 'Une image.', NULL, '{}', 'supports/b3100000-0000-0000-0000-0000000001a8/1/vignette.png'),
  ('b3100000-0000-0000-0000-000000000109', 'Doc adultes', 'Doc adultes', 'pdf', 'inscrits', 'jamais', 'lecture', 'fr',
   'cours', 7, 'Un document pour les adultes.', NULL, '{}', NULL);
UPDATE public.library_resource SET tranches = ARRAY['adulte_18_plus'], lecture_coran = 'warsh', ecole_priere = 'malikite'
 WHERE id = 'b3100000-0000-0000-0000-000000000109';
INSERT INTO public.resource_version (id, resource_id, numero_version, statut)
SELECT ('b3100000-0000-0000-0000-000000000' || (200 + n))::uuid,
       ('b3100000-0000-0000-0000-000000000' || (100 + n))::uuid, 1, 'brouillon'
  FROM generate_series(1, 9) n;
-- Un fichier pour les PDF 101, 105 et 107 (cle conforme a la convention).
INSERT INTO public.download_asset (id, resource_version_id, format, cle_stockage, taille_octets, empreinte, origine) VALUES
  ('b3100000-0000-0000-0000-0000000003a1', 'b3100000-0000-0000-0000-000000000201', 'pdf',
   'supports/b3100000-0000-0000-0000-0000000003a1/1/doc.pdf', 1234,
   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'importe_tel_quel'),
  ('b3100000-0000-0000-0000-0000000003a5', 'b3100000-0000-0000-0000-000000000205', 'pdf',
   'supports/b3100000-0000-0000-0000-0000000003a5/1/classe.pdf', 2345,
   'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 'importe_tel_quel'),
  ('b3100000-0000-0000-0000-0000000003a7', 'b3100000-0000-0000-0000-000000000207', 'pdf',
   'supports/b3100000-0000-0000-0000-0000000003a7/1/deux.pdf', 3456,
   'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', 'importe_tel_quel'),
  ('b3100000-0000-0000-0000-0000000003a9', 'b3100000-0000-0000-0000-000000000209', 'pdf',
   'supports/b3100000-0000-0000-0000-0000000003a9/1/adultes.pdf', 4567,
   'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd', 'importe_tel_quel');
UPDATE public.resource_version v SET download_asset_id = a.id, empreinte = a.empreinte
  FROM public.download_asset a WHERE a.resource_version_id = v.id;
INSERT INTO public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
SELECT ('b3100000-0000-0000-0000-000000000' || (200 + n))::uuid, 'Source B31', 'Titulaire B31',
       ARRAY['application', 'classe'], 'Attribution B31', true, 'b3100000-0000-0000-0000-000000000001', now()
  FROM generate_series(1, 9) n;
INSERT INTO public.library_resource_groupe (resource_id, groupe_id) VALUES
  ('b3100000-0000-0000-0000-000000000105', 'b3100000-0000-0000-0000-000000000021'),
  ('b3100000-0000-0000-0000-000000000107', 'b3100000-0000-0000-0000-000000000022');
SELECT set_config('request.jwt.claim.sub', 'b3100000-0000-0000-0000-000000000001', true);
UPDATE public.resource_version SET statut = 'publiee'
 WHERE resource_id::text LIKE 'b3100000-%' AND resource_id <> 'b3100000-0000-0000-0000-000000000106';
UPDATE public.library_resource r SET current_version_id = v.id
  FROM public.resource_version v
 WHERE v.resource_id = r.id AND v.statut = 'publiee' AND r.id::text LIKE 'b3100000-%';

-- Une seule regle : pour un lecteur, les documents rendus sont exactement ceux
-- que la policy library_resource_lecture lui laisse lire (RLS).
CREATE FUNCTION pg_temp.meme_regle(p_qui text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_rpc text; v_rls text;
BEGIN
  SELECT coalesce(string_agg(e ->> 'id', ',' ORDER BY e ->> 'id'), '') INTO v_rpc
    FROM jsonb_array_elements(public.bibliotheque_catalogue_lecteur()) e
   WHERE (e ->> 'id') LIKE 'b3100000-%';
  SELECT coalesce(string_agg(r.id::text, ',' ORDER BY r.id::text), '') INTO v_rls
    FROM public.library_resource r WHERE r.id::text LIKE 'b3100000-%';
  IF v_rpc <> v_rls THEN
    RAISE EXCEPTION 'B31 ROUGE : % : la fonction (%) et la RLS (%) divergent', p_qui, v_rpc, v_rls;
  END IF;
END $$;

SET LOCAL ROLE authenticated;

-- ---------------------------------------------------------------------------
-- 3. L'eleve de la Classe une
-- ---------------------------------------------------------------------------
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $eleve$
DECLARE v jsonb; m jsonb; k text;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  -- Rayon des cours d'abord (par ordre), puis le second rayon ; le brouillon et
  -- la classe deux n'y sont pas.
  IF pg_temp.titres(v) <> 'Le Coran,Audio lettres,Doc cours,Doc classe,Image,Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : eleve, catalogue (ordre) %', pg_temp.titres(v);
  END IF;
  IF v::text ILIKE '%supports/%' OR v::text ILIKE '%cle_stockage%' OR v::text ILIKE '%vignette_cle%' THEN
    RAISE EXCEPTION 'B31 ROUGE : une cle de stockage sort du catalogue';
  END IF;
  -- Le manifeste porte exactement ces cles : aucune colonne reservee n'en sort.
  m := v -> 2;
  FOREACH k IN ARRAY ARRAY['id','title','short_title','cover_asset','resource_type','edition','language','category',
      'level_scope','access_policy','offline_policy','current_version_id','capabilities','description','lien_externe',
      'ordre','rayon','etapes','vignette','tranches','lecture_coran','ecole_priere'] LOOP
    IF NOT m ? k THEN RAISE EXCEPTION 'B31 ROUGE : cle % absente du manifeste', k; END IF;
  END LOOP;
  IF (SELECT count(*) FROM jsonb_object_keys(m)) <> 22 THEN
    RAISE EXCEPTION 'B31 ROUGE : le manifeste porte des cles en trop : %', (SELECT string_agg(x, ',') FROM jsonb_object_keys(m) x);
  END IF;
  IF m::text ~* '(prix|price|montant|amount|cents|tarif)' THEN
    RAISE EXCEPTION 'B31 ROUGE : un mot d''argent dans le manifeste %', m;
  END IF;
  IF m -> 'rayon' ->> 'code' <> 'cours' OR m -> 'rayon' ->> 'titre_fr' <> 'Documents des cours'
     OR m -> 'rayon' ->> 'titre_ar' <> 'وثائق الدروس' OR m ->> 'description' <> 'Le document des lettres.'
     OR m -> 'etapes' <> '["E_LETTRES"]'::jsonb OR (m ->> 'vignette')::boolean IS NOT FALSE THEN
    RAISE EXCEPTION 'B31 ROUGE : manifeste du document %', m;
  END IF;
  -- Filtres.
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"rayon":"plus_loin"}')) <> 'Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre rayon plus_loin';
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"rayon":"cours"}')) <> 'Le Coran,Audio lettres,Doc cours,Doc classe,Image' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre rayon cours %', pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"rayon":"cours"}'));
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"etape":"E_VOYELLES"}')) <> 'Audio lettres'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"etape":"E_LETTRES"}')) <> 'Audio lettres,Doc cours' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre etape';
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"types":["audio"]}')) <> 'Audio lettres'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"types":["pdf"]}')) <> 'Doc cours,Doc classe'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"types":["video","external_link"]}')) <> 'Video,Lien externe'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"types":["quran"]}')) <> 'Le Coran' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre type';
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000021"}')) <> 'Doc classe' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre classe de l''eleve';
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000022"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : la classe d''un autre rend quelque chose';
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"recherche":"lettres"}')) <> 'Audio lettres,Doc cours' THEN
    RAISE EXCEPTION 'B31 ROUGE : la recherche lit aussi la description : %', pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"recherche":"lettres"}'));
  END IF;
  -- Pagination : pages disjointes, dans l'ordre.
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"decalage":0}', 3)) <> 'Le Coran,Audio lettres,Doc cours'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"decalage":3}', 3)) <> 'Doc classe,Image,Video'
     OR pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"decalage":6}', 3)) <> 'Lien externe'
     OR public.bibliotheque_catalogue_lecteur('{"decalage":9}', 3) <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : pagination';
  END IF;
  -- Filtres invalides.
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"rayon":"A B"}'); RAISE EXCEPTION 'B31 ROUGE : rayon invalide accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"decalage":-1}'); RAISE EXCEPTION 'B31 ROUGE : decalage negatif accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"decalage":"2"}'); RAISE EXCEPTION 'B31 ROUGE : decalage texte accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"classe":"pas-un-uuid"}'); RAISE EXCEPTION 'B31 ROUGE : classe invalide acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"etape":"a b"}'); RAISE EXCEPTION 'B31 ROUGE : etape invalide acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"prix":1}'); RAISE EXCEPTION 'B31 ROUGE : filtre prix accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  -- Un document invisible n'est pas rendu par id.
  IF public.bibliotheque_catalogue_lecteur('{"id":"b3100000-0000-0000-0000-000000000106"}') <> '[]'::jsonb
     OR public.bibliotheque_catalogue_lecteur('{"id":"b3100000-0000-0000-0000-000000000107"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : un brouillon ou le document d''une autre classe est rendu par id';
  END IF;
  -- Les rayons, y compris un rayon sans document.
  v := public.bibliotheque_rayons_lecteur();
  IF jsonb_array_length(v) <> 2 OR v -> 0 ->> 'code' <> 'cours' OR v -> 1 ->> 'code' <> 'plus_loin'
     OR v -> 1 ->> 'titre_ar' <> 'للتعمّق أكثر' THEN
    RAISE EXCEPTION 'B31 ROUGE : rayons %', v;
  END IF;
END;
$eleve$;
SELECT pg_temp.meme_regle('eleve');

-- 3 bis. La chaine « document publie -> droit verifie -> cle a signer », et la
-- version rendue au lecteur (sans cle de stockage).
DO $chaine$
DECLARE v jsonb; k text;
BEGIN
  v := public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000101');
  IF v ->> 'id' <> 'b3100000-0000-0000-0000-000000000201' OR v ->> 'statut' <> 'publiee'
     OR v -> 'asset' ->> 'format' <> 'pdf' OR (v -> 'asset' ->> 'taille_octets')::int <> 1234 THEN
    RAISE EXCEPTION 'B31 ROUGE : version du lecteur %', v;
  END IF;
  IF v::text ILIKE '%supports/%' OR v::text ILIKE '%cle_stockage%' THEN
    RAISE EXCEPTION 'B31 ROUGE : une cle de stockage sort de la version';
  END IF;
  -- Le Coran et un lien n'ont pas de fichier : une version, sans artefact.
  IF public.bibliotheque_version_lecteur((SELECT id FROM public.library_resource WHERE resource_type::text = 'quran')) -> 'asset' <> 'null'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : le Coran porte un fichier';
  END IF;
  IF public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000106') IS NOT NULL
     OR public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000107') IS NOT NULL THEN
    RAISE EXCEPTION 'B31 ROUGE : version d''un brouillon ou d''une autre classe rendue';
  END IF;
  -- Le droit verifie : la cle n'est rendue que pour un document lu et ses droits.
  IF public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000201') !~ '^supports/b3100000-0000-0000-0000-0000000003a1/1/doc\.pdf$' THEN
    RAISE EXCEPTION 'B31 ROUGE : la chaine de lecture ne rend pas la cle du document publie';
  END IF;
  IF public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000205') IS NULL THEN
    RAISE EXCEPTION 'B31 ROUGE : l''eleve de la classe ne lit pas le document de sa classe';
  END IF;
  BEGIN
    PERFORM public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000207');
    RAISE EXCEPTION 'B31 ROUGE : l''eleve lit le document d''une autre classe';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000206');
    RAISE EXCEPTION 'B31 ROUGE : une version brouillon est lisible';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  -- Les vignettes autorisees : celles des documents lisibles, avec une cle.
  v := public.bibliotheque_vignettes_autorisees(ARRAY[
    'b3100000-0000-0000-0000-000000000101', 'b3100000-0000-0000-0000-000000000108',
    'b3100000-0000-0000-0000-000000000107']::uuid[]);
  IF jsonb_array_length(v) <> 1 OR v -> 0 ->> 'id' <> 'b3100000-0000-0000-0000-000000000108' THEN
    RAISE EXCEPTION 'B31 ROUGE : vignettes autorisees %', v;
  END IF;
  BEGIN PERFORM public.bibliotheque_vignettes_autorisees(ARRAY[]::uuid[]); RAISE EXCEPTION 'B31 ROUGE : liste vide acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  -- Un eleve n'ecrit rien.
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"x","type":"pdf","langue":"fr"}'); RAISE EXCEPTION 'B31 ROUGE : un eleve cree un brouillon';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/png', 100, repeat('a', 64));
    RAISE EXCEPTION 'B31 ROUGE : un eleve demande un depot de vignette';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$chaine$;

-- ---------------------------------------------------------------------------
-- 4. L'eleve exterieur, le tuteur, les enseignants, l'anonyme
-- ---------------------------------------------------------------------------
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000003', 'student', 'b31fffff-0000-0000-0000-000000000002');
DO $dehors$
BEGIN
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur()) <> 'Le Coran,Audio lettres,Doc cours,Image,Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : eleve exterieur, catalogue %', pg_temp.titres(public.bibliotheque_catalogue_lecteur());
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000021"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : un etranger lit la liste d''une classe';
  END IF;
  IF public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000105') IS NOT NULL THEN
    RAISE EXCEPTION 'B31 ROUGE : un etranger recoit la version du document d''une classe';
  END IF;
  BEGIN
    PERFORM public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000205');
    RAISE EXCEPTION 'B31 ROUGE : un etranger lit le document d''une classe';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF jsonb_array_length(public.bibliotheque_vignettes_autorisees(ARRAY['b3100000-0000-0000-0000-000000000108']::uuid[])) <> 1 THEN
    RAISE EXCEPTION 'B31 ROUGE : la vignette d''un document des inscrits n''est pas autorisee a un inscrit';
  END IF;
END;
$dehors$;
SELECT pg_temp.meme_regle('dehors');

SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000006', 'student', 'b31fffff-0000-0000-0000-000000000003');
DO $autre_classe$
BEGIN
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur()) <> 'Le Coran,Audio lettres,Doc cours,Image,Doc classe deux,Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : eleve de la classe deux, catalogue %', pg_temp.titres(public.bibliotheque_catalogue_lecteur());
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000021"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : un eleve d''une autre classe lit la liste de la classe une';
  END IF;
END;
$autre_classe$;
SELECT pg_temp.meme_regle('autre classe');

SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000004', 'guardian', 'b31fffff-0000-0000-0000-000000000001');
DO $tuteur$
BEGIN
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur()) <> 'Le Coran,Audio lettres,Doc cours,Doc classe,Image,Doc adultes,Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : tuteur du foyer, catalogue %', pg_temp.titres(public.bibliotheque_catalogue_lecteur());
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000021"}')) <> 'Doc classe' THEN
    RAISE EXCEPTION 'B31 ROUGE : le tuteur ne lit pas la liste de la classe de son enfant';
  END IF;
END;
$tuteur$;
SELECT pg_temp.meme_regle('tuteur');

SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000005', 'teacher', NULL);
DO $enseignant$
BEGIN
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur()) <> 'Le Coran,Audio lettres,Doc cours,Doc classe,Image,Doc adultes,Video,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : enseignant, catalogue %', pg_temp.titres(public.bibliotheque_catalogue_lecteur());
  END IF;
  IF pg_temp.titres(public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000021"}')) <> 'Doc classe' THEN
    RAISE EXCEPTION 'B31 ROUGE : l''enseignant ne lit pas la liste de sa classe';
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"classe":"b3100000-0000-0000-0000-000000000022"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : l''enseignant lit la liste de la classe d''un collegue';
  END IF;
END;
$enseignant$;
SELECT pg_temp.meme_regle('enseignant');

-- Aucun compte (jeton sans identite) : refus nomme.
SELECT set_config('request.jwt.claim.sub', '', true), set_config('request.jwt.claims', '{}', true);
DO $anonyme$
BEGIN
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur(); RAISE EXCEPTION 'B31 ROUGE : catalogue rendu sans compte';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_rayons_lecteur(); RAISE EXCEPTION 'B31 ROUGE : rayons rendus sans compte';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000101'); RAISE EXCEPTION 'B31 ROUGE : version rendue sans compte';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.bibliotheque_vignettes_autorisees(ARRAY['b3100000-0000-0000-0000-000000000108']::uuid[]); RAISE EXCEPTION 'B31 ROUGE : vignettes rendues sans compte';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$anonyme$;

-- ---------------------------------------------------------------------------
-- 5. La direction depose, controle et publie un lien externe
-- ---------------------------------------------------------------------------
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $creation$
DECLARE c jsonb; l jsonb; a jsonb; m jsonb; v_rev integer;
BEGIN
  -- Refus : lien http, adresse IP, javascript, sans description, sans lien, sur un audio, rayon inconnu,
  -- ordre mal forme, etape mal formee, cle « prix ».
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"external_link","langue":"fr","description":"d","lienExterne":"http://exemple.org/a"}');
    RAISE EXCEPTION 'B31 ROUGE : lien http accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"external_link","langue":"fr","description":"d","lienExterne":"https://10.0.0.1/a"}');
    RAISE EXCEPTION 'B31 ROUGE : lien vers une IP accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"external_link","langue":"fr","description":"d","lienExterne":"javascript:alert(1)"}');
    RAISE EXCEPTION 'B31 ROUGE : lien javascript accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"external_link","langue":"fr","lienExterne":"https://exemple.org/a"}');
    RAISE EXCEPTION 'B31 ROUGE : lien sans description accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"external_link","langue":"fr","description":"d"}');
    RAISE EXCEPTION 'B31 ROUGE : lien externe sans lien accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"audio","langue":"fr","lienExterne":"https://exemple.org/a"}');
    RAISE EXCEPTION 'B31 ROUGE : lien sur un audio accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"audio","langue":"fr","rayon":"boutique"}');
    RAISE EXCEPTION 'B31 ROUGE : rayon inconnu accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"audio","langue":"fr","ordre":"deux"}');
    RAISE EXCEPTION 'B31 ROUGE : ordre texte accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"audio","langue":"fr","etapes":["a b"]}');
    RAISE EXCEPTION 'B31 ROUGE : etape mal formee acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"audio","langue":"fr","prix":10}');
    RAISE EXCEPTION 'B31 ROUGE : une cle de prix est acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"L","type":"inconnu","langue":"fr"}');
    RAISE EXCEPTION 'B31 ROUGE : type inconnu accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;

  -- Un lien externe, rayon « plus_loin », rattache a deux etapes (doublon et espaces normalises).
  c := public.library_creer_brouillon(jsonb_build_object('titre', 'Lien de la direction', 'type', 'external_link',
        'langue', 'fr', 'description', 'Un site de reference.', 'lienExterne', 'https://exemple.org/ref',
        'rayon', 'plus_loin', 'ordre', 7, 'etapes', jsonb_build_array('E_LETTRES', ' E_VOYELLES ', 'E_LETTRES')));
  SELECT to_jsonb(r) INTO m FROM public.library_resource r WHERE r.id = (c ->> 'id')::uuid;
  IF m ->> 'rayon' <> 'plus_loin' OR (m ->> 'ordre')::int <> 7 OR m -> 'etapes' <> '["E_LETTRES","E_VOYELLES"]'::jsonb
     OR m ->> 'access_policy' <> 'admin' OR m ->> 'current_version_id' IS NOT NULL THEN
    RAISE EXCEPTION 'B31 ROUGE : brouillon du lien %', m;
  END IF;
  PERFORM set_config('b31.lien_id', c ->> 'id', true);
  PERFORM set_config('b31.lien_version', c ->> 'version_id', true);
  PERFORM set_config('b31.lien_revision', c ->> 'revision', true);

  -- Une video par lien, et un audio avec etape : les deux se creent.
  PERFORM public.library_creer_brouillon('{"titre":"Video du cours","type":"video","langue":"fr","description":"d","lienExterne":"https://video.exemple.org/v/9"}');
  a := public.library_creer_brouillon('{"titre":"Audio des lettres","type":"audio","langue":"ar","etapes":["E_LETTRES"]}');
  PERFORM set_config('b31.audio_id', a ->> 'id', true);
  PERFORM set_config('b31.audio_version', a ->> 'version_id', true);
  PERFORM set_config('b31.audio_revision', a ->> 'revision', true);
END;
$creation$;

-- Le brouillon est invisible d'un eleve.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $brouillon_invisible$
BEGIN
  IF pg_temp.titres_tries(public.bibliotheque_catalogue_lecteur()) ~ 'Lien de la direction|Video du cours|Audio des lettres' THEN
    RAISE EXCEPTION 'B31 ROUGE : un brouillon est visible d''un eleve';
  END IF;
END;
$brouillon_invisible$;

-- Droits approuves (revue de la direction : fixture de table), puis controle et publication.
RESET ROLE;
INSERT INTO public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
VALUES
  (current_setting('b31.lien_version')::uuid, 'Site de reference', 'Editeur du site', ARRAY['application', 'classe'],
   'Lien vers le site de l''editeur', true, 'b3100000-0000-0000-0000-000000000001', now()),
  (current_setting('b31.audio_version')::uuid, 'Voix de la direction', 'Rewayah Academy', ARRAY['application', 'classe'],
   'Enregistrement de la direction', true, 'b3100000-0000-0000-0000-000000000001', now());
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $publication$
DECLARE r jsonb; ctl jsonb; v_rev integer;
BEGIN
  -- Le lien : tous les criteres valides sans fichier ni preuve ; l'etape vaut rattachement.
  ctl := public.library_controler_version(current_setting('b31.lien_version')::uuid);
  IF NOT (ctl ->> 'publiable')::boolean THEN
    RAISE EXCEPTION 'B31 ROUGE : un lien externe complet n''est pas publiable : %', ctl;
  END IF;
  -- L'audio sans fichier : bloque (fichier absent), jamais publie a tort.
  ctl := public.library_controler_version(current_setting('b31.audio_version')::uuid);
  IF (ctl ->> 'publiable')::boolean THEN
    RAISE EXCEPTION 'B31 ROUGE : un audio sans fichier est publiable : %', ctl;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(ctl -> 'criteres') c WHERE c ->> 'cle' = 'fichierSain' AND c ->> 'etat' = 'bloque')
     OR EXISTS (SELECT 1 FROM jsonb_array_elements(ctl -> 'criteres') c WHERE c ->> 'cle' = 'langueNiveau' AND c ->> 'etat' <> 'valide') THEN
    RAISE EXCEPTION 'B31 ROUGE : criteres de l''audio sans fichier : %', ctl;
  END IF;
  r := public.library_publier_version(current_setting('b31.lien_id')::uuid, current_setting('b31.lien_version')::uuid,
                                       current_setting('b31.lien_revision')::int, 'cle-b31-lien');
  IF r ->> 'resultat' <> 'VersionPubliee' THEN
    RAISE EXCEPTION 'B31 ROUGE : publication du lien : %', r;
  END IF;
END;
$publication$;

-- Publie, le lien n'est visible d'aucun eleve tant que la direction ne le
-- destine a personne (visibilite groupe_assigne sans classe) ; elle le destine
-- aux inscrits par la mise a jour de sa fiche.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $avant_visibilite$
BEGIN
  IF pg_temp.titres_tries(public.bibliotheque_catalogue_lecteur()) ~ 'Lien de la direction' THEN
    RAISE EXCEPTION 'B31 ROUGE : un lien publie sans destinataire est visible';
  END IF;
END;
$avant_visibilite$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $mise_a_jour$
DECLARE r jsonb; v_rev integer; d jsonb;
BEGIN
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = current_setting('b31.lien_id')::uuid;
  -- Une revision perimee : conflit, rien d'ecrit.
  r := public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"visibilite":"inscrits"}', v_rev - 1);
  IF r ->> 'resultat' <> 'EcritureEnConflit' THEN RAISE EXCEPTION 'B31 ROUGE : revision perimee acceptee %', r; END IF;
  -- La description d'un lien ne s'efface pas ; ni son lien.
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"description":""}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : la description d''un lien s''efface'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"lienExterne":null}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : le lien d''un lien externe s''efface'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"lienExterne":"ftp://exemple.org/a"}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : un lien ftp est accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"rayon":"boutique"}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : rayon inconnu accepte en mise a jour'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"prix":3}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : cle prix acceptee en mise a jour'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid, '{"ordre":-3}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : ordre negatif accepte'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  r := public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid,
        '{"visibilite":"inscrits","rayon":"plus_loin","ordre":2,"etapes":["E_LETTRES"],"description":"Un site de reference, en francais."}', v_rev);
  IF r ->> 'resultat' <> 'EcritureFaite' THEN RAISE EXCEPTION 'B31 ROUGE : mise a jour du lien %', r; END IF;
  d := public.library_get_detail(current_setting('b31.lien_id')::uuid);
  IF d -> 'support' ->> 'rayon' <> 'plus_loin' OR d -> 'support' -> 'etapes' <> '["E_LETTRES"]'::jsonb
     OR d -> 'support' ->> 'lienExterne' <> 'https://exemple.org/ref' OR d -> 'support' ->> 'type' <> 'external_link'
     OR (d -> 'support' ->> 'vignette')::boolean IS NOT FALSE OR (d -> 'support' ->> 'ordre')::int <> 2 THEN
    RAISE EXCEPTION 'B31 ROUGE : fiche de la direction %', d -> 'support';
  END IF;
END;
$mise_a_jour$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000003', 'student', 'b31fffff-0000-0000-0000-000000000002');
DO $apres_visibilite$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur('{"types":["external_link"]}');
  IF pg_temp.titres_tries(v) <> 'Lien de la direction,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : le lien publie pour les inscrits n''est pas lu : %', pg_temp.titres_tries(v);
  END IF;
  IF (SELECT e ->> 'lien_externe' FROM jsonb_array_elements(v) e WHERE e ->> 'title' = 'Lien de la direction') <> 'https://exemple.org/ref'
     OR (SELECT e ->> 'description' FROM jsonb_array_elements(v) e WHERE e ->> 'title' = 'Lien de la direction') <> 'Un site de reference, en francais.' THEN
    RAISE EXCEPTION 'B31 ROUGE : le lien ou la description n''arrive pas au lecteur';
  END IF;
END;
$apres_visibilite$;
SELECT pg_temp.meme_regle('apres visibilite');

-- ---------------------------------------------------------------------------
-- 5 bis. Les tranches d'age (D1), la lecture du Coran et l'ecole (D2)
-- ---------------------------------------------------------------------------
-- Un lien externe exclut par defaut la tranche 6-9 : l'enfant de 6 a 9 ans ne
-- voit pas le lien de la direction, ni la video par lien ; un adulte seul ne
-- se montre qu'aux adultes (et au tuteur, enseignant et direction).
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $tranche_6_9$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres_tries(v) ~ 'Lien de la direction|Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE : un enfant de 6 a 9 ans voit un lien par defaut ou un document d''adultes : %', pg_temp.titres_tries(v);
  END IF;
  IF pg_temp.titres_tries(v) !~ 'Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : un document a toutes les tranches disparait pour un enfant de 6 a 9 ans';
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"id":"b3100000-0000-0000-0000-000000000109"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : le document d''adultes est rendu par id a un enfant';
  END IF;
  IF public.bibliotheque_version_lecteur('b3100000-0000-0000-0000-000000000109') IS NOT NULL THEN
    RAISE EXCEPTION 'B31 ROUGE : la version d''un document d''adultes est rendue a un enfant';
  END IF;
  BEGIN
    PERFORM public.autoriser_lecture_version('b3100000-0000-0000-0000-000000000209');
    RAISE EXCEPTION 'B31 ROUGE : un enfant recoit la cle d''un fichier d''adultes';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$tranche_6_9$;
SELECT pg_temp.meme_regle('enfant 6-9');

-- Un adolescent de 14 a 17 ans voit le lien, pas le document d'adultes.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000006', 'student', 'b31fffff-0000-0000-0000-000000000003');
DO $tranche_14_17$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres_tries(v) !~ 'Lien de la direction' OR pg_temp.titres_tries(v) ~ 'Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE : un adolescent de 14 a 17 ans : %', pg_temp.titres_tries(v);
  END IF;
END;
$tranche_14_17$;
SELECT pg_temp.meme_regle('ado 14-17');

-- Le tuteur : au moins ce que voit son enfant (et l'adulte qu'il est) ; pour
-- un enfant de son foyer, exactement la liste de la tranche de cet enfant.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000004', 'guardian', 'b31fffff-0000-0000-0000-000000000001');
DO $tuteur_tranches$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres_tries(v) !~ 'Doc adultes' OR pg_temp.titres_tries(v) !~ 'Lien de la direction' THEN
    RAISE EXCEPTION 'B31 ROUGE : le tuteur adulte ne voit pas ce qu''un adulte voit : %', pg_temp.titres_tries(v);
  END IF;
  v := public.bibliotheque_catalogue_lecteur('{"eleve":"b3100000-0000-0000-0000-000000000002"}');
  IF pg_temp.titres_tries(v) ~ 'Lien de la direction|Doc adultes' OR pg_temp.titres_tries(v) !~ 'Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE : le tuteur qui regarde pour son enfant de 6 a 9 ans : %', pg_temp.titres_tries(v);
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"eleve":"b3100000-0000-0000-0000-000000000003"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : le tuteur regarde pour l''enfant d''un autre foyer';
  END IF;
  BEGIN PERFORM public.bibliotheque_catalogue_lecteur('{"eleve":"pas-un-uuid"}'); RAISE EXCEPTION 'B31 ROUGE : eleve invalide accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
END;
$tuteur_tranches$;
SELECT pg_temp.meme_regle('tuteur tranches');

-- Les autres roles : ni tranche ni « regarder pour » un enfant.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000005', 'teacher', NULL);
DO $enseignant_tranches$
BEGIN
  IF public.bibliotheque_catalogue_lecteur('{"eleve":"b3100000-0000-0000-0000-000000000002"}') <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : un enseignant regarde pour un enfant';
  END IF;
  IF pg_temp.titres_tries(public.bibliotheque_catalogue_lecteur()) !~ 'Lien de la direction' THEN
    RAISE EXCEPTION 'B31 ROUGE : l''enseignant ne voit pas tout ce que sa visibilite permet';
  END IF;
END;
$enseignant_tranches$;

-- La direction : les tranches au depot, la lecture du Coran, l'ecole, les filtres.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $direction_tranches$
DECLARE c jsonb; d jsonb; r jsonb; v_rev integer; v_id uuid;
BEGIN
  -- Defaut : un lien et une video par lien excluent 6-9 ; un audio garde les quatre.
  d := public.library_get_detail(current_setting('b31.lien_id')::uuid);
  IF d -> 'support' -> 'tranches' <> '["enfant_10_13","ado_14_17","adulte_18_plus"]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : tranches par defaut d''un lien : %', d -> 'support' -> 'tranches';
  END IF;
  d := public.library_get_detail(current_setting('b31.audio_id')::uuid);
  IF jsonb_array_length(d -> 'support' -> 'tranches') <> 4 THEN
    RAISE EXCEPTION 'B31 ROUGE : tranches par defaut d''un audio : %', d -> 'support' -> 'tranches';
  END IF;
  c := public.library_creer_brouillon('{"titre":"Video 6-9","type":"video","langue":"fr","lienExterne":"https://video.exemple.org/v/7","tranches":["enfant_6_9","adulte_18_plus"]}');
  v_id := (c ->> 'id')::uuid;
  IF (SELECT tranches FROM public.library_resource WHERE id = v_id) <> ARRAY['adulte_18_plus','enfant_6_9'] THEN
    RAISE EXCEPTION 'B31 ROUGE : tranches choisies par la direction : %', (SELECT tranches FROM public.library_resource WHERE id = v_id);
  END IF;
  -- Refus : liste vide, code inconnu, valeur qui n'est pas une liste, nulle.
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"x","type":"audio","langue":"fr","tranches":[]}');
    RAISE EXCEPTION 'B31 ROUGE : tranches vides acceptees'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"x","type":"audio","langue":"fr","tranches":["bebe"]}');
    RAISE EXCEPTION 'B31 ROUGE : tranche inconnue acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"x","type":"audio","langue":"fr","tranches":"adulte_18_plus"}');
    RAISE EXCEPTION 'B31 ROUGE : tranches texte acceptees'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  -- Lecture du Coran et ecole.
  BEGIN PERFORM public.library_creer_brouillon('{"titre":"x","type":"audio","langue":"fr","lectureCoran":"inconnue"}');
    RAISE EXCEPTION 'B31 ROUGE : lecture inconnue acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = current_setting('b31.audio_id')::uuid;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.audio_id')::uuid, '{"lectureCoran":"abc"}', v_rev);
    RAISE EXCEPTION 'B31 ROUGE : lecture inconnue acceptee en mise a jour'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour(current_setting('b31.audio_id')::uuid, jsonb_build_object('ecolePriere', repeat('x', 81)), v_rev);
    RAISE EXCEPTION 'B31 ROUGE : ecole trop longue acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  r := public.library_mettre_a_jour(current_setting('b31.audio_id')::uuid,
        '{"lectureCoran":"qalun","ecolePriere":"Ecole suivie en classe","tranches":["ado_14_17","adulte_18_plus"]}', v_rev);
  IF r ->> 'resultat' <> 'EcritureFaite' THEN RAISE EXCEPTION 'B31 ROUGE : mise a jour lecture et ecole %', r; END IF;
  d := public.library_get_detail(current_setting('b31.audio_id')::uuid);
  IF d -> 'support' ->> 'lectureCoran' <> 'qalun' OR d -> 'support' ->> 'ecolePriere' <> 'Ecole suivie en classe'
     OR d -> 'support' -> 'tranches' <> '["ado_14_17","adulte_18_plus"]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : fiche de la direction (lecture, ecole, tranches) %', d -> 'support';
  END IF;
  -- Le Coran seme porte la lecture hafs.
  IF (SELECT lecture_coran FROM public.library_resource WHERE resource_type::text = 'quran') <> 'hafs' THEN
    RAISE EXCEPTION 'B31 ROUGE : le Coran seme ne porte pas la lecture hafs';
  END IF;
  -- Les filtres de la direction.
  r := public.library_get_catalogue('{"lectureCoran":"hafs"}');
  IF jsonb_array_length(r -> 'elements') <> 1 OR r -> 'elements' -> 0 ->> 'titre' <> 'Le Coran'
     OR r -> 'elements' -> 0 ->> 'lectureCoran' <> 'hafs' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre de la direction par lecture du Coran : %', r;
  END IF;
  r := public.library_get_catalogue('{"lectureCoran":"warsh"}');
  IF jsonb_array_length(r -> 'elements') <> 1 OR r -> 'elements' -> 0 ->> 'titre' <> 'Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre warsh : %', r;
  END IF;
  r := public.library_get_catalogue('{"ecolePriere":"MALIK"}');
  IF jsonb_array_length(r -> 'elements') <> 1 OR r -> 'elements' -> 0 ->> 'titre' <> 'Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE : filtre ecole : %', r;
  END IF;
  r := public.library_get_catalogue('{"rayon":"plus_loin"}');
  IF jsonb_array_length(r -> 'elements') < 2 THEN RAISE EXCEPTION 'B31 ROUGE : filtre rayon de la direction'; END IF;
  BEGIN PERFORM public.library_get_catalogue('{"lectureCoran":"autre"}'); RAISE EXCEPTION 'B31 ROUGE : filtre de lecture invalide accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  -- Le lien : la direction coche expressement 6-9 ; l'enfant le voit alors.
  SELECT revision INTO v_rev FROM public.library_resource WHERE id = current_setting('b31.lien_id')::uuid;
  r := public.library_mettre_a_jour(current_setting('b31.lien_id')::uuid,
        '{"tranches":["enfant_6_9","enfant_10_13","ado_14_17","adulte_18_plus"]}', v_rev);
  IF r ->> 'resultat' <> 'EcritureFaite' THEN RAISE EXCEPTION 'B31 ROUGE : tranches du lien %', r; END IF;
  -- Les etapes du programme publie : liste vide sans version publiee, puis les
  -- etapes de la version publiee avec leur code stable.
  IF public.bibliotheque_etapes_publiees() <> '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE : des etapes sans programme publie : %', public.bibliotheque_etapes_publiees();
  END IF;
  -- Le depot de fichiers n'est pas active tant que le secret n'est pas pose.
  IF public.bibliotheque_depot_actif() IS NOT FALSE THEN
    RAISE EXCEPTION 'B31 ROUGE : le depot est dit actif sans secret';
  END IF;
END;
$direction_tranches$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $tranche_cochee$
BEGIN
  IF pg_temp.titres_tries(public.bibliotheque_catalogue_lecteur()) !~ 'Lien de la direction' THEN
    RAISE EXCEPTION 'B31 ROUGE : la tranche 6-9 cochee n''ouvre pas le lien';
  END IF;
  BEGIN PERFORM public.bibliotheque_depot_actif(); RAISE EXCEPTION 'B31 ROUGE : un eleve lit l''etat du depot';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$tranche_cochee$;
SELECT pg_temp.meme_regle('tranche cochee');

-- Les etapes publiees (D3) : une version publiee du programme les rend, par code
-- stable ; un compte qui n'est pas la direction ne les lit pas.
RESET ROLE;
INSERT INTO public.programme_versions (id, statut, numero_version, cree_par)
VALUES ('b3100000-0000-0000-0000-0000000004a1', 'brouillon', 9901, 'b3100000-0000-0000-0000-000000000001');
INSERT INTO public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre) VALUES
  ('b3100000-0000-0000-0000-0000000004a1', 'E_LETTRES', 'Les lettres', 'Les bases', 1),
  ('b3100000-0000-0000-0000-0000000004a1', 'E_VOYELLES', 'Les voyelles', 'Les bases', 2);
-- La publication d'un programme exige un contenu complet (objectifs, durees) :
-- sans rapport avec ce scenario, qui ne lit que les codes. Declencheurs coupes
-- le temps de cette seule ecriture (le scenario tourne en super-utilisateur).
SET LOCAL session_replication_role = replica;
UPDATE public.programme_versions SET statut = 'publiee', publiee_par = 'b3100000-0000-0000-0000-000000000001', publiee_at = now()
 WHERE id = 'b3100000-0000-0000-0000-0000000004a1';
SET LOCAL session_replication_role = origin;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $etapes_publiees$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_etapes_publiees();
  IF jsonb_array_length(v) <> 2 OR v -> 0 ->> 'code' <> 'E_LETTRES' OR v -> 1 ->> 'nom' <> 'Les voyelles' THEN
    RAISE EXCEPTION 'B31 ROUGE : etapes publiees : %', v;
  END IF;
END;
$etapes_publiees$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $etapes_refus$
BEGIN
  BEGIN PERFORM public.bibliotheque_etapes_publiees(); RAISE EXCEPTION 'B31 ROUGE : un eleve lit les etapes du programme';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$etapes_refus$;

-- ---------------------------------------------------------------------------
-- 5 ter. Correctifs de la revue independante
-- ---------------------------------------------------------------------------
-- B1 : l'onglet de la classe (ressources_du_groupe) applique la tranche d'age
-- et ne rend ni lien externe ni cle de vignette. Quatre documents attribues a
-- la Classe une : un lien pour tous (103), une image a vignette (108), un
-- document d'adultes (109), le lien de la direction sans les 6-9 ans.
RESET ROLE;
INSERT INTO public.library_resource_groupe (resource_id, groupe_id)
SELECT r, 'b3100000-0000-0000-0000-000000000021'::uuid
  FROM unnest(ARRAY['b3100000-0000-0000-0000-000000000103', 'b3100000-0000-0000-0000-000000000108',
                    'b3100000-0000-0000-0000-000000000109']::uuid[]
              || current_setting('b31.lien_id')::uuid) r;
-- Le lien de la direction a ete rouvert aux 6-9 ans plus haut (section 5 bis) :
-- on le remet sans eux pour ce cas.
UPDATE public.library_resource SET tranches = ARRAY['enfant_10_13', 'ado_14_17', 'adulte_18_plus']
 WHERE id = current_setting('b31.lien_id')::uuid;
SET LOCAL ROLE authenticated;

CREATE FUNCTION pg_temp.groupe_titres() RETURNS text
LANGUAGE sql AS $$
  SELECT coalesce(string_agg(g.title, ',' ORDER BY g.title), '')
    FROM public.ressources_du_groupe('b3100000-0000-0000-0000-000000000021') g $$;
CREATE FUNCTION pg_temp.groupe_colonnes_ajoutees() RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::integer FROM public.ressources_du_groupe('b3100000-0000-0000-0000-000000000021') g
   WHERE g.lien_externe IS NOT NULL OR g.vignette_cle IS NOT NULL OR g.etapes IS NOT NULL
      OR g.tranches IS NOT NULL OR g.lecture_coran IS NOT NULL OR g.ecole_priere IS NOT NULL
      OR g.ordre IS NOT NULL OR g.rayon IS NOT NULL $$;

SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $b1_enfant$
BEGIN
  -- Un enfant de 6 a 9 ans ne recoit ni le lien de la direction ni le document d'adultes.
  IF pg_temp.groupe_titres() ~ 'Lien de la direction|Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : l''onglet de la classe rend a un enfant de 6 a 9 ans un document d''une autre tranche : %', pg_temp.groupe_titres();
  END IF;
  IF pg_temp.groupe_titres() <> 'Doc classe,Image,Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : l''onglet de la classe de l''enfant : %', pg_temp.groupe_titres();
  END IF;
  -- Meme pour ce qu'il a le droit de voir : ni adresse, ni cle de vignette.
  IF pg_temp.groupe_colonnes_ajoutees() <> 0 THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : une colonne ajoutee par le lot est rendue par l''onglet de la classe';
  END IF;
  IF (SELECT to_jsonb(g)::text FROM public.ressources_du_groupe('b3100000-0000-0000-0000-000000000021') g LIMIT 1)
       ILIKE '%exemple.org%' OR (SELECT string_agg(to_jsonb(g)::text, '') FROM public.ressources_du_groupe('b3100000-0000-0000-0000-000000000021') g) ILIKE '%supports/%' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : une adresse ou une cle de stockage est rendue par l''onglet de la classe';
  END IF;
END;
$b1_enfant$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000004', 'guardian', 'b31fffff-0000-0000-0000-000000000001');
DO $b1_tuteur$
BEGIN
  -- Le tuteur est adulte : il voit ce qu'un adulte voit, mais jamais l'adresse ni la cle.
  IF pg_temp.groupe_titres() !~ 'Doc adultes' OR pg_temp.groupe_titres() !~ 'Lien de la direction' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : le tuteur adulte ne voit pas les documents d''adultes de la classe : %', pg_temp.groupe_titres();
  END IF;
  IF pg_temp.groupe_colonnes_ajoutees() <> 0 THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : le tuteur recoit une colonne ajoutee par le lot';
  END IF;
END;
$b1_tuteur$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000005', 'teacher', NULL);
DO $b1_enseignant$
BEGIN
  IF pg_temp.groupe_titres() !~ 'Lien de la direction' OR pg_temp.groupe_colonnes_ajoutees() <> 0 THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : l''onglet de la classe de l''enseignant : %', pg_temp.groupe_titres();
  END IF;
END;
$b1_enseignant$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000003', 'student', 'b31fffff-0000-0000-0000-000000000002');
DO $b1_etranger$
BEGIN
  PERFORM * FROM public.ressources_du_groupe('b3100000-0000-0000-0000-000000000021');
  RAISE EXCEPTION 'B31 ROUGE (B1) : un eleve d''une autre classe lit l''onglet de la classe';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$b1_etranger$;

-- B1 (suite) : la recherche ne montre pas, a un enfant, le titre d'un document
-- d'une autre tranche.
CREATE FUNCTION pg_temp.qui_recherche(p_uid text, p_role text, p_foyer text, p_av bigint) RETURNS void
LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_uid, true),
         set_config('request.jwt.claims', jsonb_build_object('sub', p_uid,
           'app_metadata', jsonb_build_object('role', p_role, 'household_id', p_foyer,
                                              'authorization_version', p_av))::text, true);
$$;
RESET ROLE;
SELECT set_config('b31.av_002', (SELECT authorization_version::text FROM public.profiles WHERE id = 'b3100000-0000-0000-0000-000000000002'), true),
       set_config('b31.av_004', (SELECT authorization_version::text FROM public.profiles WHERE id = 'b3100000-0000-0000-0000-000000000004'), true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui_recherche('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001',
                             current_setting('b31.av_002')::bigint);
DO $b1_recherche$
DECLARE v jsonb;
BEGIN
  v := public.rech_d1_rechercher_supports('lien');
  IF v::text ~ 'Lien de la direction' OR v::text !~ 'Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : la recherche d''un enfant de 6 a 9 ans : %', v;
  END IF;
  IF public.rech_d1_rechercher_supports('adultes')::text ~ 'Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : la recherche rend le titre d''un document d''adultes a un enfant';
  END IF;
END;
$b1_recherche$;
SELECT pg_temp.qui_recherche('b3100000-0000-0000-0000-000000000004', 'guardian', 'b31fffff-0000-0000-0000-000000000001',
                             current_setting('b31.av_004')::bigint);
DO $b1_recherche_tuteur$
BEGIN
  IF public.rech_d1_rechercher_supports('adultes')::text !~ 'Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE (B1) : la recherche du tuteur adulte ne trouve pas un document d''adultes';
  END IF;
END;
$b1_recherche_tuteur$;

-- I3 : un compte dont l'acces est suspendu pour impaye ne lit plus la
-- Bibliotheque, SAUF le Coran (regle du 04/11/2026), et la fonction reste
-- identique a la RLS. Il n'y a qu'UN Coran : celui qui est seme, par son
-- identifiant ; la direction ne peut pas en creer un second, et un document de
-- type Coran insere par un autre chemin n'a pas l'exception.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $coran_unique$
BEGIN
  BEGIN
    PERFORM public.library_creer_brouillon('{"titre":"Pas le Coran","type":"quran","langue":"ar","categorie":"coran"}');
    RAISE EXCEPTION 'B31 ROUGE (I3) : la direction cree un second document de type Coran';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  IF (SELECT id FROM public.library_resource WHERE resource_type::text = 'quran' AND title = 'Le Coran') <> 'c0a4a000-0000-4000-8000-0000000c0a4a'::uuid THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : le Coran seme n''a pas l''identifiant reserve';
  END IF;
END;
$coran_unique$;
RESET ROLE;
-- Un document de type Coran qui ne serait pas le Coran seme (insere hors de la
-- direction) : publie pour les inscrits, il ne passe PAS l'acces paye.
INSERT INTO public.library_resource (id, title, short_title, resource_type, access_policy, offline_policy, category, language)
VALUES ('b3100000-0000-0000-0000-0000000005b1', 'Pas le Coran', 'Pas le Coran', 'quran', 'inscrits', 'jamais', 'coran', 'ar');
INSERT INTO public.resource_version (id, resource_id, numero_version, statut)
VALUES ('b3100000-0000-0000-0000-0000000005b2', 'b3100000-0000-0000-0000-0000000005b1', 1, 'brouillon');
INSERT INTO public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
VALUES ('b3100000-0000-0000-0000-0000000005b2', 'Source B31', 'Titulaire B31', ARRAY['application'], 'Attribution B31', true,
        'b3100000-0000-0000-0000-000000000001', now());
UPDATE public.resource_version SET statut = 'publiee' WHERE id = 'b3100000-0000-0000-0000-0000000005b2';
UPDATE public.library_resource SET current_version_id = 'b3100000-0000-0000-0000-0000000005b2' WHERE id = 'b3100000-0000-0000-0000-0000000005b1';
SET LOCAL session_replication_role = replica;
INSERT INTO public.acces_suspensions_paiement (id, profile_id, facture_id, jour)
VALUES ('b3100000-0000-0000-0000-0000000005a1', 'b3100000-0000-0000-0000-000000000003',
        'b3100000-0000-0000-0000-0000000005f1', current_date);
SET LOCAL session_replication_role = origin;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000003', 'student', 'b31fffff-0000-0000-0000-000000000002');
DO $i3_impaye$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres(v) <> 'Le Coran' THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : un compte suspendu pour impaye lit autre chose que le Coran : %', pg_temp.titres(v);
  END IF;
  IF (SELECT count(*) FROM public.library_resource WHERE id::text LIKE 'b3100000-%') <> 0
     OR (SELECT count(*) FROM public.library_resource WHERE resource_type::text = 'quran') <> 1 THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : la RLS d''un compte suspendu ne laisse pas exactement le Coran';
  END IF;
  IF public.bibliotheque_catalogue_lecteur('{"types":["quran"]}') = '[]'::jsonb THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : le Coran est ferme a un compte suspendu';
  END IF;
END;
$i3_impaye$;
-- La recherche suit la meme regle : rien pour un compte suspendu, sauf le Coran.
RESET ROLE;
SELECT set_config('b31.av_003', (SELECT authorization_version::text FROM public.profiles WHERE id = 'b3100000-0000-0000-0000-000000000003'), true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui_recherche('b3100000-0000-0000-0000-000000000003', 'student', 'b31fffff-0000-0000-0000-000000000002',
                             current_setting('b31.av_003')::bigint);
DO $i3_recherche$
BEGIN
  IF public.rech_d1_rechercher_supports('lien')::text ~ 'Lien externe' THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : la recherche d''un compte suspendu rend un document';
  END IF;
  IF public.rech_d1_rechercher_supports('coran')::text !~ 'Le Coran' THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : la recherche d''un compte suspendu ne trouve pas le Coran';
  END IF;
  IF public.rech_d1_rechercher_supports('coran')::text ~ 'Pas le Coran' THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : un faux Coran passe l''acces paye dans la recherche : %', public.rech_d1_rechercher_supports('coran');
  END IF;
END;
$i3_recherche$;
-- L'onglet de la classe suit la meme regle : un eleve membre de la classe, suspendu
-- pour impaye, n'y voit plus aucun document (le Coran n'est rattache a aucune classe).
RESET ROLE;
SET LOCAL session_replication_role = replica;
INSERT INTO public.acces_suspensions_paiement (id, profile_id, facture_id, jour)
VALUES ('b3100000-0000-0000-0000-0000000005a2', 'b3100000-0000-0000-0000-000000000002',
        'b3100000-0000-0000-0000-0000000005f2', current_date);
SET LOCAL session_replication_role = origin;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000002', 'student', 'b31fffff-0000-0000-0000-000000000001');
DO $i3_classe$
BEGIN
  IF pg_temp.groupe_titres() <> '' THEN
    RAISE EXCEPTION 'B31 ROUGE (I3) : un eleve suspendu voit encore des documents dans l''onglet de la classe : %', pg_temp.groupe_titres();
  END IF;
END;
$i3_classe$;
RESET ROLE;
SET LOCAL session_replication_role = replica;
UPDATE public.acces_suspensions_paiement SET retabli_le = now(), retabli_motif = 'paiement'
 WHERE id IN ('b3100000-0000-0000-0000-0000000005a1', 'b3100000-0000-0000-0000-0000000005a2');
SET LOCAL session_replication_role = origin;
SET LOCAL ROLE authenticated;

-- I4 : la direction compte les mineurs sans tranche (traites comme des 6-9 ans).
RESET ROLE;
UPDATE public.student_profiles SET cohorte = NULL WHERE profile_id = 'b3100000-0000-0000-0000-000000000006';
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $i4_mineurs$
DECLARE n integer;
BEGIN
  n := public.library_mineurs_sans_cohorte();
  IF n < 1 THEN RAISE EXCEPTION 'B31 ROUGE (I4) : le mineur sans tranche n''est pas compte (%)', n; END IF;
END;
$i4_mineurs$;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000006', 'student', 'b31fffff-0000-0000-0000-000000000003');
DO $i4_prudence$
BEGIN
  -- Sans tranche, un mineur est traite comme un 6-9 ans : il ne voit pas le lien par defaut.
  IF pg_temp.titres_tries(public.bibliotheque_catalogue_lecteur()) ~ 'Lien de la direction|Doc adultes' THEN
    RAISE EXCEPTION 'B31 ROUGE (I4) : un mineur sans tranche voit un document reserve a d''autres tranches';
  END IF;
  BEGIN PERFORM public.library_mineurs_sans_cohorte(); RAISE EXCEPTION 'B31 ROUGE (I4) : un eleve lit le compte des mineurs sans tranche';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$i4_prudence$;
RESET ROLE;
UPDATE public.student_profiles SET cohorte = 'ado_14_17' WHERE profile_id = 'b3100000-0000-0000-0000-000000000006';
SET LOCAL ROLE authenticated;

-- ---------------------------------------------------------------------------
-- 6. La vignette : une intention a deux temps, confirmation signee par l'Edge
-- ---------------------------------------------------------------------------
RESET ROLE;
INSERT INTO private.library_upload_confirmation_secrets(singleton, secret)
VALUES (true, 'test-only-b31-vignette-confirmation-key-32-bytes');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000001', 'admin', NULL);
DO $depot_actif$
BEGIN
  IF public.bibliotheque_depot_actif() IS NOT TRUE THEN
    RAISE EXCEPTION 'B31 ROUGE : le depot n''est pas dit actif avec un secret';
  END IF;
END;
$depot_actif$;
DO $vignette$
DECLARE
  i jsonb; sig text; r jsonb; v_sha text := repeat('d', 64); v jsonb;
BEGIN
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'application/pdf', 100, v_sha);
    RAISE EXCEPTION 'B31 ROUGE : une vignette PDF est acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/png', 3 * 1024 * 1024, v_sha);
    RAISE EXCEPTION 'B31 ROUGE : une vignette de 3 Mio est acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/png', 100, 'xyz');
    RAISE EXCEPTION 'B31 ROUGE : une empreinte mal formee est acceptee'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-0000000009ff', 'image/png', 100, v_sha);
    RAISE EXCEPTION 'B31 ROUGE : une vignette pour un document inconnu est acceptee'; EXCEPTION WHEN no_data_found THEN NULL; END;

  i := public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/png', 1000, v_sha);
  IF i ->> 'cle_temporaire' <> 'private/libraryupload/' || (i ->> 'id')
     OR i ->> 'cle_finale' !~ '^supports/[0-9a-f-]{36}/1/vignette\.png$' THEN
    RAISE EXCEPTION 'B31 ROUGE : chemin de depot de la vignette %', i;
  END IF;
  -- Une signature qui n'est pas celle de l'Edge est refusee.
  BEGIN PERFORM public.confirmer_vignette_bibliotheque((i ->> 'id')::uuid, 'image/png', 1000, v_sha, repeat('0', 64));
    RAISE EXCEPTION 'B31 ROUGE : signature de confirmation invalide acceptee';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  -- Separation de domaine (I7) : une signature calculee comme celle d'un
  -- FICHIER de document (sans le prefixe de la vignette) est refusee.
  sig := encode(extensions.hmac(convert_to((i ->> 'id') || E'\n' || v_sha || E'\n1000', 'UTF8'),
          convert_to('test-only-b31-vignette-confirmation-key-32-bytes', 'UTF8'), 'sha256'), 'hex');
  BEGIN PERFORM public.confirmer_vignette_bibliotheque((i ->> 'id')::uuid, 'image/png', 1000, v_sha, sig);
    RAISE EXCEPTION 'B31 ROUGE : une signature de fichier confirme une vignette';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  sig := encode(extensions.hmac(convert_to('bibliotheque-vignette-v1' || E'\n' || (i ->> 'id') || E'\n' || v_sha || E'\n1000', 'UTF8'),
          convert_to('test-only-b31-vignette-confirmation-key-32-bytes', 'UTF8'), 'sha256'), 'hex');
  -- Un contenu different de celui annonce est refuse meme signe.
  BEGIN PERFORM public.confirmer_vignette_bibliotheque((i ->> 'id')::uuid, 'image/jpeg', 1000, v_sha, sig);
    RAISE EXCEPTION 'B31 ROUGE : un type different de l''annonce est confirme';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  r := public.confirmer_vignette_bibliotheque((i ->> 'id')::uuid, 'image/png', 1000, v_sha, sig);
  IF r ->> 'etat' <> 'pret' THEN RAISE EXCEPTION 'B31 ROUGE : confirmation de la vignette %', r; END IF;
  -- Une intention ne se confirme qu'une fois.
  BEGIN PERFORM public.confirmer_vignette_bibliotheque((i ->> 'id')::uuid, 'image/png', 1000, v_sha, sig);
    RAISE EXCEPTION 'B31 ROUGE : une intention confirmee deux fois';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF NOT (public.library_get_detail('b3100000-0000-0000-0000-000000000101') -> 'support' ->> 'vignette')::boolean THEN
    RAISE EXCEPTION 'B31 ROUGE : la fiche ne dit pas que la vignette existe';
  END IF;
  -- Annuler une intention en attente.
  i := public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/webp', 500, v_sha);
  IF public.annuler_vignette_bibliotheque((i ->> 'id')::uuid) IS NOT TRUE THEN
    RAISE EXCEPTION 'B31 ROUGE : annulation de la vignette';
  END IF;
  -- Le retrait de la vignette.
  PERFORM public.library_mettre_a_jour('b3100000-0000-0000-0000-000000000101', '{"vignette":null}',
    (SELECT revision FROM public.library_resource WHERE id = 'b3100000-0000-0000-0000-000000000101'));
  IF (public.library_get_detail('b3100000-0000-0000-0000-000000000101') -> 'support' ->> 'vignette')::boolean THEN
    RAISE EXCEPTION 'B31 ROUGE : la vignette n''est pas retiree';
  END IF;
END;
$vignette$;

-- L'enseignant ne depose pas de vignette.
SELECT pg_temp.qui('b3100000-0000-0000-0000-000000000005', 'teacher', NULL);
DO $enseignant_refuse$
BEGIN
  BEGIN PERFORM public.demander_vignette_bibliotheque('b3100000-0000-0000-0000-000000000101', 'image/png', 100, repeat('e', 64));
    RAISE EXCEPTION 'B31 ROUGE : un enseignant depose une vignette'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.library_mettre_a_jour('b3100000-0000-0000-0000-000000000101', '{"rayon":"plus_loin"}', 1);
    RAISE EXCEPTION 'B31 ROUGE : un enseignant range un document'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$enseignant_refuse$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 7. Droits d'execution
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.bibliotheque_catalogue_lecteur(jsonb,integer)', 'public.bibliotheque_rayons_lecteur()',
    'public.bibliotheque_version_lecteur(uuid)', 'public.bibliotheque_vignettes_autorisees(uuid[])',
    'public.demander_vignette_bibliotheque(uuid,text,bigint,text)', 'public.lire_vignette_bibliotheque(uuid)',
    'public.confirmer_vignette_bibliotheque(uuid,text,bigint,text,text)', 'public.annuler_vignette_bibliotheque(uuid)',
    'public.library_creer_brouillon(jsonb)', 'public.library_mettre_a_jour(uuid,jsonb,integer)',
    'public.library_get_detail(uuid)', 'public.library_get_catalogue(jsonb,text,integer)',
    'public.bibliotheque_depot_actif()', 'public.bibliotheque_etapes_publiees()'
  ] LOOP
    IF has_function_privilege('anon', v_signature, 'EXECUTE') OR has_function_privilege('agent_ro', v_signature, 'EXECUTE')
       OR has_function_privilege('service_role', v_signature, 'EXECUTE')
       OR NOT has_function_privilege('authenticated', v_signature, 'EXECUTE') THEN
      RAISE EXCEPTION 'B31 ROUGE : droits d''execution de %', v_signature;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'private.n4_manifeste(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'app_private.library_semer_coran()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'app_private.library_etapes_normalisees(jsonb)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'app_private.library_controle_version(uuid)', 'EXECUTE')
     OR has_table_privilege('authenticated', 'private.library_vignette_intentions', 'SELECT') THEN
    RAISE EXCEPTION 'B31 ROUGE : une aide interne est ouverte aux clients';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid = 'public.bibliotheque_catalogue_lecteur(jsonb,integer)'::regprocedure
                AND (NOT p.prosecdef OR NOT p.proconfig @> ARRAY['search_path=""'])) THEN
    RAISE EXCEPTION 'B31 ROUGE : la lecture du lecteur n''est pas DEFINER a search_path vide';
  END IF;
END;
$droits$;

ROLLBACK;
