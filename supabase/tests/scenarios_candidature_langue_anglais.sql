-- CANDIDATURE-UX (directeur, 14/11/2026) : la langue de la candidature accepte
-- l'anglais. Migration 20261125750000_candidature_langue_anglais.sql.
-- Controle : le CHECK de candidatures.langue (fr, ar, en ; tout autre refuse),
-- la validation de inscrire_candidat, et ce que la migration ne doit pas
-- changer (SECURITY DEFINER, search_path, droits, empreinte F86). Le chemin
-- complet de l'inscription en anglais est dans
-- scenarios_cand_l3_inscription_import.sql.
-- Chaque controle leve 'CANDIDATURE-UX ROUGE : ...' s'il echoue. A rejouer sur
-- une base NEUVE (stub_auth puis toutes les migrations) ; tout est annule.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CANDIDATURE-UX ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- 1. La colonne : fr, ar et en passent, tout autre code est refuse.
SELECT pg_temp.vrai(
  pg_catalog.pg_get_constraintdef(
    (SELECT c.oid FROM pg_catalog.pg_constraint c
      WHERE c.conrelid = 'public.candidatures'::regclass
        AND c.conname = 'candidatures_langue_check'))
  LIKE '%''en''%',
  'le CHECK de candidatures.langue nomme en');

DO $$
DECLARE
  v_refus boolean := false;
BEGIN
  -- Une candidature sans compte, pour essayer la contrainte.
  INSERT INTO public.candidatures (type_code, genre, nom_complet, etape, issue, source, langue)
  VALUES ('enseignant', 'female', 'Essai Langue', 'recue', 'en_cours', 'lien_public', 'en');
  BEGIN
    UPDATE public.candidatures SET langue = 'es' WHERE nom_complet = 'Essai Langue';
  EXCEPTION WHEN check_violation THEN
    v_refus := true;
  END;
  PERFORM pg_temp.vrai(v_refus, 'un code hors de fr, ar, en est refuse par la contrainte');
  PERFORM pg_temp.vrai(
    (SELECT langue = 'en' FROM public.candidatures WHERE nom_complet = 'Essai Langue'),
    'une candidature en anglais s''enregistre');
END $$;

-- 2. La validation de inscrire_candidat.
SELECT pg_temp.vrai(
  pg_catalog.strpos(p.prosrc, 'p_langue NOT IN (''fr'', ''ar'', ''en'')') > 0
  AND pg_catalog.strpos(p.prosrc, 'p_langue NOT IN (''fr'', ''ar'')') = 0,
  'inscrire_candidat valide fr, ar ou en')
FROM pg_catalog.pg_proc p
WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure;

-- 3. Ce qui ne change pas.
SELECT pg_temp.vrai(
  p.prosecdef AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
  AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('public', p.oid, 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE'),
  'SECURITY DEFINER, search_path vide, droits (authenticated seul) gardes')
FROM pg_catalog.pg_proc p
WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure;

SELECT pg_temp.vrai(
  coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%md5_functiondef=%'
  OR pg_catalog.obj_description(p.oid, 'pg_proc')
     LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%',
  'l''empreinte F86 du commentaire suit la definition')
FROM pg_catalog.pg_proc p
WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure;

ROLLBACK;
\o
\echo 'CANDIDATURE-UX : scenarios verts'
