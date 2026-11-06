-- FN-101, option B (migration 20261110800000) : une piece d'identite n'entre
-- dans kyc_documents que si son contenu a ete confirme par le serveur.
--
--   1. sans confirmation, l'insertion directe est refusee (RLS) ;
--   2. la confirmation ne se pose pas par un compte (service_role seul) ;
--   3. confirmee pour soi, l'insertion passe ;
--   4. la confirmation d'un autre ne sert pas (la cle est liee au deposant) ;
--   5. une confirmation hors de sa forme est refusee (cle d'un autre, type
--      hors liste) ;
--   6. la garde du compte reste : un compte suspendu, ou dont l'acces a
--      expire, est refuse MEME avec une confirmation.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus_code(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (% « % » au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated',
  'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus_code(text, text, text),
  pg_temp.qui(uuid, text) TO authenticated;

INSERT INTO auth.users (id, email) VALUES
  ('f1010000-0000-4000-8000-000000000001', 'fn101-t1@example.test'),
  ('f1010000-0000-4000-8000-000000000002', 'fn101-t2@example.test'),
  ('f1010000-0000-4000-8000-000000000003', 'fn101-t3@example.test'),
  ('f1010000-0000-4000-8000-000000000004', 'fn101-t4@example.test');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, gender, account_status) VALUES
  ('f1010000-0000-4000-8000-000000000001', 'FN101-T1', 'teacher', 'Amina', 'Diallo', 'female', 'pending_kyc'),
  ('f1010000-0000-4000-8000-000000000002', 'FN101-T2', 'teacher', 'Moussa', 'Sow', 'male', 'pending_kyc'),
  ('f1010000-0000-4000-8000-000000000003', 'FN101-T3', 'teacher', 'Awa', 'Ba', 'female', 'disabled'),
  ('f1010000-0000-4000-8000-000000000004', 'FN101-T4', 'teacher', 'Ali', 'Kane', 'male', 'pending_kyc');
UPDATE public.profiles SET access_until = pg_catalog.now() - interval '1 day'
 WHERE id = 'f1010000-0000-4000-8000-000000000004';

SET LOCAL ROLE authenticated;

-- 1. Sans confirmation : refuse.
SELECT pg_temp.qui('f1010000-0000-4000-8000-000000000001', 'teacher');
SELECT pg_temp.refus_code($q$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('f1010000-0000-4000-8000-000000000001', 'id_card', 'f1010000-0000-4000-8000-000000000001/1.pdf')$q$,
  '42501', '1 sans confirmation du contenu, la piece n''entre pas');

-- 2. Un compte ne pose pas de confirmation.
SELECT pg_temp.refus_code($q$SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000001',
  'f1010000-0000-4000-8000-000000000001/1.pdf', 'application/pdf')$q$,
  '42501', '2 un compte ne pose pas lui-meme la confirmation');
SELECT pg_temp.refus_code($q$INSERT INTO private.kyc_contenus_confirmes (object_key, depose_par, type_contenu)
  VALUES ('f1010000-0000-4000-8000-000000000001/1.pdf', 'f1010000-0000-4000-8000-000000000001', 'application/pdf')$q$,
  '42501', '2 bis ni par la table');

-- 3. Confirmee (comme le fait la fonction Edge, sous service_role) : passe.
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000001',
  'f1010000-0000-4000-8000-000000000001/1.pdf', 'application/pdf');
SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000002',
  'f1010000-0000-4000-8000-000000000002/2.png', 'image/png');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f1010000-0000-4000-8000-000000000001', 'teacher');
INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('f1010000-0000-4000-8000-000000000001', 'id_card', 'f1010000-0000-4000-8000-000000000001/1.pdf');
SELECT pg_temp.vrai(true, '3 confirmee pour soi, la piece entre');

-- 4. La confirmation de Moussa ne sert pas a Amina.
SELECT pg_temp.refus_code($q$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('f1010000-0000-4000-8000-000000000001', 'id_card', 'f1010000-0000-4000-8000-000000000002/2.png')$q$,
  '42501', '4 la confirmation d''un autre deposant ne sert pas');

-- 5. Une confirmation hors de sa forme est refusee, meme par le service.
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT pg_temp.refus_code($q$SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000001',
  'f1010000-0000-4000-8000-000000000002/3.pdf', 'application/pdf')$q$,
  '22023', '5 une cle d''un autre deposant n''est pas confirmee');
SELECT pg_temp.refus_code($q$SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000001',
  'f1010000-0000-4000-8000-000000000001/4.webp', 'image/webp')$q$,
  '22023', '5 bis un type hors liste n''est pas confirme');

-- 6. Confirmees, mais comptes non autorises : toujours refuses.
SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000003',
  'f1010000-0000-4000-8000-000000000003/5.pdf', 'application/pdf');
SELECT public.kyc_confirmer_contenu('f1010000-0000-4000-8000-000000000004',
  'f1010000-0000-4000-8000-000000000004/6.pdf', 'application/pdf');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f1010000-0000-4000-8000-000000000003', 'teacher');
SELECT pg_temp.refus_code($q$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('f1010000-0000-4000-8000-000000000003', 'id_card', 'f1010000-0000-4000-8000-000000000003/5.pdf')$q$,
  '42501', '6 compte suspendu, contenu confirme : toujours refuse');
SELECT pg_temp.qui('f1010000-0000-4000-8000-000000000004', 'teacher');
SELECT pg_temp.refus_code($q$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('f1010000-0000-4000-8000-000000000004', 'id_card', 'f1010000-0000-4000-8000-000000000004/6.pdf')$q$,
  '42501', '6 bis acces expire, contenu confirme : toujours refuse');
RESET ROLE;

ROLLBACK;
