-- PIECE-TYPE (pilote, 16/11/2026) : migration 20261129490000_piece_type.sql.
--
-- Cas couverts : piece_dossier_candidat rend typeContenu et genreFichier tires du type MIME enregistre au depot :
-- pdf, image (jpeg, png, heic), NULL quand aucun type n'est enregistre ou qu'aucune piece n'est deposee ; la piece
-- la plus recente decide ; hors portee et sans compte inchanges ; les cles d'avant restent. Chaque controle leve
-- 'PIECE-TYPE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'PIECE-TYPE ROUGE : %', p_label;
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
    RAISE EXCEPTION 'PIECE-TYPE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'PIECE-TYPE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1ec0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1eccccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.piece(p_n text, p_qui text DEFAULT 'a1') RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p(p_qui), 'admin',
    pg_catalog.format('SELECT public.piece_dossier_candidat(%L)', pg_temp.c(p_n)));
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.piece(text, text) TO authenticated, anon;

-- a1 direction (homme). 01 piece PDF ; 02 piece JPEG ; 03 piece PNG ; 04 piece HEIC ; 05 piece sans type enregistre ;
-- 06 aucune piece ; 07 une ancienne piece JPEG puis une piece PDF plus recente ; 08 une candidate (femme) avec un PDF :
-- hors du cote de a1 ; 09 candidature sans compte.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'pt-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'PT-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'PT-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '08' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(s), 'enseignant', CASE WHEN s = '09' THEN NULL ELSE pg_temp.p(s) END,
       CASE WHEN s = '08' THEN 'female'::gender ELSE 'male'::gender END, 'Fixture ' || s,
       CASE WHEN s = '09' THEN 'recue' ELSE 'verifications' END, CASE WHEN s = '09' THEN NULL ELSE 'decision_en_attente' END,
       'en_cours', 'lien_public'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09']) AS s;
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, status, created_at)
VALUES
 (pg_temp.p('01'), 'id_card', 'male', pg_temp.p('01')::text || '/a.pdf', 'pending', now() - interval '1 day'),
 (pg_temp.p('02'), 'passport', 'male', pg_temp.p('02')::text || '/a.jpg', 'pending', now() - interval '1 day'),
 (pg_temp.p('03'), 'id_card', 'male', pg_temp.p('03')::text || '/a.png', 'approved', now() - interval '1 day'),
 (pg_temp.p('04'), 'id_card', 'male', pg_temp.p('04')::text || '/a.heic', 'pending', now() - interval '1 day'),
 (pg_temp.p('05'), 'id_card', 'male', pg_temp.p('05')::text || '/a.bin', 'pending', now() - interval '1 day'),
 (pg_temp.p('07'), 'id_card', 'male', pg_temp.p('07')::text || '/ancienne.jpg', 'rejected', now() - interval '10 days'),
 (pg_temp.p('07'), 'id_card', 'male', pg_temp.p('07')::text || '/recente.pdf', 'pending', now() - interval '1 day'),
 (pg_temp.p('08'), 'id_card', 'female', pg_temp.p('08')::text || '/a.pdf', 'pending', now() - interval '1 day');
INSERT INTO private.kyc_contenus_confirmes (object_key, depose_par, type_contenu) VALUES
 (pg_temp.p('01')::text || '/a.pdf', pg_temp.p('01'), 'application/pdf'),
 (pg_temp.p('02')::text || '/a.jpg', pg_temp.p('02'), 'image/jpeg'),
 (pg_temp.p('03')::text || '/a.png', pg_temp.p('03'), 'image/png'),
 (pg_temp.p('04')::text || '/a.heic', pg_temp.p('04'), 'image/heic'),
 (pg_temp.p('07')::text || '/ancienne.jpg', pg_temp.p('07'), 'image/jpeg'),
 (pg_temp.p('07')::text || '/recente.pdf', pg_temp.p('07'), 'application/pdf'),
 (pg_temp.p('08')::text || '/a.pdf', pg_temp.p('08'), 'application/pdf');
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  pg_temp.piece('01') ->> 'genreFichier' = 'pdf' AND pg_temp.piece('01') ->> 'typeContenu' = 'application/pdf'
  AND pg_temp.piece('02') ->> 'genreFichier' = 'image' AND pg_temp.piece('02') ->> 'typeContenu' = 'image/jpeg'
  AND pg_temp.piece('03') ->> 'genreFichier' = 'image' AND pg_temp.piece('03') ->> 'typeContenu' = 'image/png'
  AND pg_temp.piece('04') ->> 'genreFichier' = 'image' AND pg_temp.piece('04') ->> 'typeContenu' = 'image/heic',
  'a1 : le type vient du type MIME enregistre au depot : pdf pour un PDF, image pour JPEG, PNG et HEIC');
SELECT pg_temp.vrai(
  (pg_temp.piece('05') -> 'genreFichier') = 'null'::jsonb AND (pg_temp.piece('05') -> 'typeContenu') = 'null'::jsonb
  AND pg_temp.piece('05') ->> 'statut' = 'pending' AND pg_temp.piece('05') ->> 'documentId' IS NOT NULL,
  'a2 : sans type enregistre, le serveur ne devine pas (NULL) et la piece reste rendue avec son statut');
SELECT pg_temp.vrai(
  (pg_temp.piece('06') -> 'genreFichier') = 'null'::jsonb AND pg_temp.piece('06') ->> 'statut' = 'a_deposer'
  AND (pg_temp.piece('09') -> 'genreFichier') IS NULL AND pg_temp.piece('09') ->> 'statut' = 'sans_compte',
  'a3 : aucune piece deposee (a_deposer) : NULL ; candidature sans compte : reponse d''avant, sans les nouvelles cles');
SELECT pg_temp.vrai(
  pg_temp.piece('07') ->> 'genreFichier' = 'pdf' AND pg_temp.piece('07') ->> 'typeContenu' = 'application/pdf',
  'a4 : la piece la plus recente decide (un PDF apres une ancienne image)');
SELECT pg_temp.vrai(
  pg_temp.piece('08') = '{"erreur": "hors_portee"}'::jsonb,
  'a5 : une candidate de l''autre cote est hors de portee : aucune cle, aucun type');
SELECT pg_temp.vrai(
  (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.piece('01')) k)
    = ARRAY['decideLe', 'deposeLe', 'documentId', 'genreFichier', 'motifRefus', 'profilId', 'statut', 'typeContenu'],
  'a6 : la reponse garde ses six cles d''avant et gagne typeContenu et genreFichier, rien d''autre (ni cle d''objet, ni nom de fichier)');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  pg_catalog.format($q$SELECT public.piece_dossier_candidat(%L)$q$, pg_temp.c('01')), '42501',
  'a7 : un enseignant ne lit pas la piece de son dossier par cette porte');
SELECT pg_temp.vrai(
  (SELECT obj_description('public.piece_dossier_candidat(uuid)'::regprocedure, 'pg_proc')
     LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.piece_dossier_candidat(uuid)'::regprocedure)) || ';%'),
  'a8 : l''empreinte F86 est celle de la definition installee');
ROLLBACK;
