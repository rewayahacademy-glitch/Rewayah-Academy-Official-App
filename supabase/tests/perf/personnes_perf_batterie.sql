\set QUIET on
\pset tuples_only on
\pset format unaligned
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  v := json_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                         'app_metadata', json_build_object('role', p_role))::text;
  PERFORM set_config('request.jwt.claims', v, true);
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('test.uid', p_id::text, true);
  PERFORM set_config('test.jwt', v, true);
END $$;
CREATE FUNCTION pg_temp.essai(p_label text, p_sql text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text;
BEGIN
  BEGIN
    EXECUTE 'SELECT (' || p_sql || ')::text' INTO r;
  EXCEPTION WHEN OTHERS THEN
    r := 'ERREUR ' || SQLSTATE || ' ' || SQLERRM;
  END;
  RETURN p_label || '|' || md5(coalesce(r, '<null>')) || '|' || length(coalesce(r, '<null>'))
         || CASE WHEN r LIKE 'ERREUR%' THEN '|' || r ELSE '' END;
END $$;
CREATE FUNCTION pg_temp.ens(p_label text, p_sql text) RETURNS text LANGUAGE sql AS $$
  SELECT pg_temp.essai(p_label, '(SELECT coalesce(jsonb_agg(to_jsonb(x)), ''[]'') FROM (' || p_sql || ') x)');
$$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated;
CREATE TEMP TABLE qui_essai(id uuid, role text, label text);
INSERT INTO qui_essai VALUES
 ('9e900000-0000-4000-8000-0000000000d1', 'admin', 'd1'),
 ('9e900000-0000-4000-8000-0000000000d2', 'admin', 'd2'),
 ('9e9c0000-0000-4000-8000-000000000001', 'teacher', 'c1'),
 ('9e9c0000-0000-4000-8000-000000000004', 'teacher', 'c4'),
 ('9e9c0000-0000-4000-8000-000000000636', 'guardian', 'g636'),
 ('9e9e0000-0000-4000-8000-000000000001', 'guardian', 'g1');
GRANT SELECT ON qui_essai TO authenticated;
CREATE FUNCTION pg_temp.tout() RETURNS SETOF text LANGUAGE plpgsql AS $f$
DECLARE q record; l text;
BEGIN
  FOR q IN SELECT * FROM qui_essai ORDER BY label LOOP
    PERFORM pg_temp.qui(q.id, q.role);
    FOR l IN SELECT e FROM (VALUES
   (1, pg_temp.essai(q.label || ' com_lister_fils', 'public.com_lister_fils()')),
   (2, pg_temp.essai(q.label || ' com_lire_fil c1', 'public.com_lire_fil(''9e9d0000-0000-4000-8000-000000000001'')')),
   (3, pg_temp.essai(q.label || ' com_lire_fil c4', 'public.com_lire_fil(''9e9d0000-0000-4000-8000-000000000004'')')),
   (4, pg_temp.essai(q.label || ' com_lire_fil d1001', 'public.com_lire_fil(''9e9d0000-0000-4000-8000-000000001001'')')),
   (5, pg_temp.essai(q.label || ' com_lire_fil_page c1', 'public.com_lire_fil_page(''9e9d0000-0000-4000-8000-000000000001'', NULL, 2)')),
   (6, pg_temp.ens(q.label || ' conv cand1', 'SELECT * FROM public.com_conversations_pour_objet(''candidature'', ''9e9ca000-0000-4000-8000-000000000001'')')),
   (7, pg_temp.ens(q.label || ' conv dossier g1', 'SELECT * FROM public.com_conversations_pour_objet(''dossier'', ''9e9e0000-0000-4000-8000-000000000001'')')),
   (8, pg_temp.ens(q.label || ' fil_pour_objet cand4', 'SELECT * FROM public.com_fil_pour_objet(''candidature'', ''9e9ca000-0000-4000-8000-000000000004'')')),
   (9, pg_temp.ens(q.label || ' capacites cand1', 'SELECT * FROM public.com_mes_capacites(''candidature'', ''9e9ca000-0000-4000-8000-000000000001'')')),
   (10, pg_temp.ens(q.label || ' capacites dossier g1', 'SELECT * FROM public.com_mes_capacites(''dossier'', ''9e9e0000-0000-4000-8000-000000000001'')')),
   (11, pg_temp.essai(q.label || ' lister p1', 'public.lister_candidatures(''{}'', ''activite'', 1)')),
   (12, pg_temp.essai(q.label || ' lister p3 nom', 'public.lister_candidatures(''{}'', ''nom'', 3)')),
   (13, pg_temp.essai(q.label || ' lister verif', 'public.lister_candidatures(''{"etape":"verifications"}'', ''recente'', 1)')),
   (14, pg_temp.essai(q.label || ' lister recherche', 'public.lister_candidatures(''{"recherche":"ba"}'', ''ancienne'', 1)')),
   (15, pg_temp.essai(q.label || ' lister pieces', 'public.lister_candidatures(''{"pieceEnAttente":true}'', ''activite'', 1)')),
   (16, pg_temp.essai(q.label || ' lister retirees', 'public.lister_candidatures(''{"issue":"retiree"}'', ''activite'', 1)')),
   (17, pg_temp.essai(q.label || ' voisins', 'public.voisins_candidature(''CAND-90100'', ''{}'', ''activite'')')),
   (18, pg_temp.essai(q.label || ' selection', 'public.selection_resultats_file(''{"etape":"verifications"}'', ''activite'')')),
   (19, pg_temp.ens(q.label || ' comptes', 'SELECT * FROM public.comptes_admin_par_role()')),
   (20, pg_temp.ens(q.label || ' dossiers', 'SELECT * FROM public.dossiers_en_attente()')),
   (21, pg_temp.essai(q.label || ' capacites_candidatures', 'public.capacites_candidatures()')),
   (22, pg_temp.essai(q.label || ' lire_candidature 100', 'public.lire_candidature(''9e9ca000-0000-4000-8000-000000000100'')'))
  ) v(o, e) ORDER BY o LOOP
      RETURN NEXT l;
    END LOOP;
  END LOOP;
END $f$;
GRANT EXECUTE ON FUNCTION pg_temp.tout() TO authenticated;
SET ROLE authenticated;
SELECT * FROM pg_temp.tout();
RESET ROLE;
ROLLBACK;
