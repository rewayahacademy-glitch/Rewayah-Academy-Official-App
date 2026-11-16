-- COURRIEL-ENTRETIEN (pilote, 16/11/2026) : migration 20261129440000_courriel_entretien.sql.
--
-- Cas couverts : le courriel « retenu pour un entretien », mis en file a l'admission en salle de verification,
-- porte creneauxOuverts : faux quand aucun moment n'est ouvert, vrai quand un moment du bon cote, a plus de
-- 30 minutes, dans une langue du candidat et tenable (deux fondateurs parmi ses participants) est ouvert ; faux pour un moment de l'autre cote, deja
-- reserve, annule, trop proche, d'une autre langue ou non tenable (participant refuse) ; le courriel reste
-- UN seul par admission et la fonction privee est fermee. Les controles d'admission (paiement, accords,
-- questionnaire) ne sont pas l'objet : ils sont neutralises DANS la transaction du scenario (annulee a la fin).
-- Chaque controle leve 'COURRIEL-ENTRETIEN ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE.
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
    RAISE EXCEPTION 'COURRIEL-ENTRETIEN ROUGE : %', p_label;
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
    RAISE EXCEPTION 'COURRIEL-ENTRETIEN ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'COURRIEL-ENTRETIEN ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ce100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ce10cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.admettre(p_n text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.admettre_salle_verification(%L, %s, %L)', pg_temp.c(p_n), pg_temp.v(p_n), 'cle-ce-' || p_n));
$$;
CREATE FUNCTION pg_temp.drapeau(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT (s.donnees ->> 'creneauxOuverts') FROM public.courriels_sortants s
   WHERE s.modele = 'retenu_entretien' AND s.destinataire_profil = pg_temp.p(p_n);
$$;
CREATE FUNCTION pg_temp.nombre(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.courriels_sortants s
   WHERE s.modele = 'retenu_entretien' AND s.destinataire_profil = pg_temp.p(p_n);
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.admettre(text), pg_temp.drapeau(text), pg_temp.nombre(text)
  TO authenticated, anon;

-- a1 direction (homme). Candidats hommes 01 a 08 en examen, langue d'explication « fr » ; 09 une candidate (femme).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'ce-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07', '08', '09']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'CE-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'CE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '09' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s), CASE WHEN s = '09' THEN 'female'::gender ELSE 'male'::gender END,
       'Fixture ' || s, 'prequalification', 'en_examen', 'en_cours', 'lien_public'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09']) AS s;
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.c(s), 'v1-2026-10', '{"languesExplication": ["fr"]}'::jsonb, 'candidat', now() - interval '1 day'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09']) AS s;
INSERT INTO auth.users (id, email)
SELECT ('ce100000-0000-4000-8000-0000000000f' || n)::uuid, 'ce-f' || n || '@test.invalid' FROM generate_series(1, 2) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('ce100000-0000-4000-8000-0000000000f' || n)::uuid, 'CE-FON-000' || n, 'admin', 'Fondateur', 'N' || n, 'active', 'male'
FROM generate_series(1, 2) n;
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par)
SELECT ('ce100000-0000-4000-8000-0000000000f' || n)::uuid, true, pg_temp.p('a1') FROM generate_series(1, 2) n;
SET LOCAL session_replication_role = origin;
-- Les controles d'admission ne sont pas l'objet de ce scenario (voir en-tete) : neutralises dans cette transaction.
CREATE OR REPLACE FUNCTION private.candidature_controles_entree(c public.candidatures, p_pour text)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$ SELECT '[]'::jsonb $$;

-- a : aucun moment ouvert.
SELECT set_config('test.r01', pg_temp.admettre('01')::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r01')::jsonb ? 'erreur'
  AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('01')) = 'entretien_a_planifier'
  AND pg_temp.nombre('01') = 1 AND pg_temp.drapeau('01') = 'false',
  'a1 : aucun moment ouvert : l''admission passe, UN courriel, creneauxOuverts faux');

-- b : un moment du bon cote, dans une langue du candidat, a plus de 30 minutes.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce100000-0000-4000-8000-000000000501', 'male', now() + interval '2 days', 30, ARRAY['fr'], pg_temp.p('a1'));
-- Sans fondateurs parmi ses participants (2 exiges par la regle en vigueur), un moment n'est pas tenable : il ne compte pas.
SELECT pg_temp.vrai(private.entretien_creneau_tenable('ce100000-0000-4000-8000-000000000501') ->> 'erreur' = 'fondateurs_insuffisants',
  'a0 : un moment sans les fondateurs exiges n''est pas tenable (regle en vigueur : deux)');
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce100000-0000-4000-8000-000000000501', 'ce100000-0000-4000-8000-0000000000f1'),
       ('ce100000-0000-4000-8000-000000000501', 'ce100000-0000-4000-8000-0000000000f2');
SELECT set_config('test.r02', pg_temp.admettre('02')::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r02')::jsonb ? 'erreur' AND pg_temp.nombre('02') = 1
  AND pg_temp.drapeau('02') = 'true',
  'b1 : un moment ouvert du bon cote, a une langue commune : creneauxOuverts vrai (et un seul courriel)');

-- c : l'autre cote, une autre langue, trop proche, reserve, annule : aucun ne compte.
UPDATE public.entretien_creneaux SET annule_le = now(), annule_par = pg_temp.p('a1')
 WHERE id = 'ce100000-0000-4000-8000-000000000501';
INSERT INTO public.entretien_creneaux (cote, debut, duree_minutes, langues, ouvert_par) VALUES
  ('female', now() + interval '2 days', 30, ARRAY['fr'], pg_temp.p('a1')),
  ('male', now() + interval '2 days', 30, ARRAY['ar'], pg_temp.p('a1')),
  ('male', now() + interval '10 minutes', 30, ARRAY['fr'], pg_temp.p('a1'));
SELECT set_config('test.r03', pg_temp.admettre('03')::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r03')::jsonb ? 'erreur' AND pg_temp.nombre('03') = 1
  AND pg_temp.drapeau('03') = 'false',
  'c1 : un moment de l''autre cote, d''une autre langue, trop proche ou annule ne compte pas : creneauxOuverts faux');

-- d : un moment dont un participant n'est pas du bon cote n'est pas tenable.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce100000-0000-4000-8000-000000000502', 'male', now() + interval '3 days', 30, ARRAY['fr'], pg_temp.p('a1'));
SET LOCAL session_replication_role = replica;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('ce100000-0000-4000-8000-0000000000b1', 'CE-ADM-00B1', 'admin', 'Direction', 'Femme', 'active', 'female');
INSERT INTO auth.users (id, email) VALUES ('ce100000-0000-4000-8000-0000000000b1', 'ce-b1@test.invalid');
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce100000-0000-4000-8000-000000000502', 'ce100000-0000-4000-8000-0000000000b1'),
       ('ce100000-0000-4000-8000-000000000502', 'ce100000-0000-4000-8000-0000000000f1'),
       ('ce100000-0000-4000-8000-000000000502', 'ce100000-0000-4000-8000-0000000000f2');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.vrai(private.entretien_creneau_tenable('ce100000-0000-4000-8000-000000000502') IS NOT NULL,
  'd0 : le moment a un participant du mauvais cote : il n''est pas tenable (fixture)');
SELECT set_config('test.r04', pg_temp.admettre('04')::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r04')::jsonb ? 'erreur' AND pg_temp.drapeau('04') = 'false',
  'd1 : un moment non tenable ne compte pas : creneauxOuverts faux');

-- e : un moment reserve ne compte pas ; puis un moment libre arrive : vrai.
SET LOCAL session_replication_role = replica;
DELETE FROM public.entretien_creneau_participants WHERE creneau_id = 'ce100000-0000-4000-8000-000000000502'
   AND profile_id = 'ce100000-0000-4000-8000-0000000000b1';
SET LOCAL session_replication_role = origin;
SELECT set_config('test.r05', pg_temp.admettre('05')::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r05')::jsonb ? 'erreur' AND pg_temp.drapeau('05') = 'true',
  'e1 : le moment rendu tenable (participant retire) compte : creneauxOuverts vrai');

-- f : rejouer le geste (meme cle) ne met pas un second courriel ; une candidate de l'autre cote reste hors de portee.
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
     'SELECT public.admettre_salle_verification(%L, 1, %L)', pg_temp.c('05'), 'cle-ce-05')) ->> 'erreur') IS NULL
  AND pg_temp.nombre('05') = 1,
  'f1 : rejouer le geste avec la meme cle ne met pas un second courriel en file');
SELECT pg_temp.vrai(
  pg_temp.admettre('09') ->> 'erreur' IS NOT NULL AND pg_temp.nombre('09') = 0,
  'f2 : une candidate de l''autre cote : le geste est refuse, aucun courriel');
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.entretien_creneaux_ouverts_pour(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.entretien_creneaux_ouverts_pour(public.candidatures)', 'EXECUTE')
  AND obj_description('public.admettre_salle_verification(uuid,integer,text)'::regprocedure, 'pg_proc')
      LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::regprocedure)) || '%'
  AND obj_description('public.admettre_salle_verification(uuid,integer,text)'::regprocedure, 'pg_proc') LIKE '%COURRIEL-ENTRETIEN%',
  'g1 : la fonction privee est fermee ; la fiche F86 de l''admission porte la mention et l''empreinte reelle');
ROLLBACK;
