-- PERSONNES-LECTURES : migration 20261130969000_personnes_lectures.sql. A rejouer sur une base NEUVE (stub_auth puis
-- toutes les migrations) ; donnees fictives a l'echelle (fixtures/personnes_perf_volume.sql) ; tout est annule a la fin.
-- Chaque controle leve 'PERSONNES-LECTURES ROUGE : ...' s'il echoue.
--   1. comptes_admin_page : les pages mises bout a bout rendent EXACTEMENT les lignes de comptes_admin_par_role de la
--      vue, dans son ordre ; total et compteurs justes ; lignes minces ; recherche ; refus.
--   2. voisins_enseignant : precedent, suivant, rang et total egaux a l'ordre des pages de lister_enseignants, pour
--      trois tris et deux filtres.
--   3. dossiers_en_attente_references : les lignes de dossiers_en_attente, dans le meme ordre, plus la bonne reference.
\set ON_ERROR_STOP on
\o /dev/null
BEGIN;
\ir fixtures/personnes_perf_volume.sql

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  v := json_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                         'app_metadata', json_build_object('role', p_role))::text;
  PERFORM set_config('request.jwt.claims', v, true);
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('test.uid', p_id::text, true);
  PERFORM set_config('test.jwt', v, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERSONNES-LECTURES ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text) TO authenticated;
-- Les references attendues, lues ici (la table est fermee aux clients).
CREATE TEMP TABLE pp_refs AS
  SELECT c.profile_id, c.reference FROM public.candidatures c WHERE c.type_code = 'enseignant';
GRANT SELECT ON pp_refs TO authenticated;

SET ROLE authenticated;
DO $$
DECLARE
  q record;
  v_vue text;
  v_attendu jsonb;
  v_obtenu jsonb;
  v_page jsonb;
  v_apres integer;
  v_total integer;
  v_somme integer;
  v_refs text[];
  v_tri text;
  v_filtre jsonb;
  v_p integer;
  v_lignes jsonb;
  i integer;
  v_vois jsonb;
BEGIN
  FOR q IN SELECT * FROM (VALUES ('9e900000-0000-4000-8000-0000000000d1'::uuid, 'direction (exception de genre)'),
                                 ('9e900000-0000-4000-8000-0000000000d2'::uuid, 'direction (femme)')) AS t(id, label) LOOP
    PERFORM pg_temp.qui(q.id, 'admin');

    -- 1. Les comptes, vue par vue.
    v_somme := 0;
    FOREACH v_vue IN ARRAY ARRAY['eleves', 'familles', 'enseignants', 'direction'] LOOP
      SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY o), '[]'::jsonb) INTO v_attendu
        FROM public.comptes_admin_par_role() WITH ORDINALITY AS x(profile_id, immutable_id, prenom, nom, role,
               etat_compte, inscrit_le, acces_jusqu_au, foyer_id, etat_piece, contrats, a_enseignant, enfants_du_foyer,
               teacher_country, tranche_age, classe_id, classe_libelle, classe_numero, classes_actives, tuteur_id,
               tuteur_prenom, tuteur_nom, admission_a_traiter, est_apprenant, o)
       WHERE CASE v_vue WHEN 'eleves' THEN x.role::text = 'student' OR x.est_apprenant
                        WHEN 'familles' THEN x.role::text = 'guardian'
                        WHEN 'enseignants' THEN x.role::text = 'teacher'
                        ELSE x.role::text IN ('admin', 'accountant', 'associe', 'controller') END;
      -- to_jsonb(x) porte la colonne d'ordre : on la retire pour comparer.
      SELECT coalesce(jsonb_agg(e - 'o' ORDER BY n), '[]'::jsonb) INTO v_attendu
        FROM jsonb_array_elements(v_attendu) WITH ORDINALITY AS t(e, n);
      v_obtenu := '[]'::jsonb;
      v_apres := 0;
      LOOP
        v_page := public.comptes_admin_page(v_vue, NULL, '{}', 'defaut', v_apres, 37, false);
        v_obtenu := v_obtenu || (v_page -> 'lignes');
        v_total := (v_page ->> 'total')::int;
        EXIT WHEN v_page -> 'suivant' = 'null'::jsonb;
        v_apres := (v_page ->> 'suivant')::int;
      END LOOP;
      PERFORM pg_temp.vrai(v_obtenu = v_attendu,
        q.label || ' ' || v_vue || ' : pages bout a bout = comptes_admin_par_role (' || jsonb_array_length(v_attendu) || ')');
      PERFORM pg_temp.vrai(v_total = jsonb_array_length(v_attendu), q.label || ' ' || v_vue || ' : total');
      PERFORM pg_temp.vrai((v_page -> 'compteursVues' ->> v_vue)::int = v_total, q.label || ' ' || v_vue || ' : compteur de la vue');
      v_somme := v_somme + v_total;
    END LOOP;
    PERFORM pg_temp.vrai(v_somme > 0, q.label || ' : des comptes lus (le controle porte)');

    -- Lignes minces : les dix champs, rien d'autre ; meme ordre.
    v_page := public.comptes_admin_page('enseignants', NULL, '{}', 'nom', 0, 20, true);
    PERFORM pg_temp.vrai((SELECT bool_and((SELECT count(*) FROM jsonb_object_keys(l)) = 10)
                            FROM jsonb_array_elements(v_page -> 'lignes') l),
      q.label || ' : lignes minces de dix champs');
    PERFORM pg_temp.vrai(
      (SELECT jsonb_agg(l -> 'profile_id') FROM jsonb_array_elements(v_page -> 'lignes') l)
      = (SELECT jsonb_agg(l -> 'profile_id')
           FROM jsonb_array_elements(public.comptes_admin_page('enseignants', NULL, '{}', 'nom', 0, 20, false) -> 'lignes') l),
      q.label || ' : minces et completes dans le meme ordre');
    -- Recherche par matricule.
    v_page := public.comptes_admin_page('enseignants', 'pp-ens-0008', '{}', 'defaut', 0, 50, false);
    PERFORM pg_temp.vrai((v_page ->> 'total')::int <= 1, q.label || ' : la recherche par matricule borne la liste');

    -- 2. Les voisins des enseignants.
    FOREACH v_tri IN ARRAY ARRAY['activite', 'nom', 'recente'] LOOP
      FOREACH v_filtre IN ARRAY ARRAY['{}'::jsonb, '{"etat": "a_completer"}'::jsonb] LOOP
        v_refs := ARRAY[]::text[];
        v_p := 1;
        LOOP
          v_lignes := public.lister_enseignants(v_filtre, v_tri, v_p) -> 'lignes';
          EXIT WHEN jsonb_array_length(v_lignes) = 0;
          v_refs := v_refs || ARRAY(SELECT l ->> 'reference' FROM jsonb_array_elements(v_lignes) WITH ORDINALITY t(l, n) ORDER BY n);
          v_p := v_p + 1;
        END LOOP;
        PERFORM pg_temp.vrai(array_length(v_refs, 1) > 2, q.label || ' ' || v_tri || ' ' || v_filtre::text || ' : liste lue');
        FOREACH i IN ARRAY ARRAY[1, array_length(v_refs, 1) / 2, array_length(v_refs, 1)] LOOP
          v_vois := public.voisins_enseignant(v_refs[i], v_filtre, v_tri);
          PERFORM pg_temp.vrai(
            (v_vois ->> 'rang')::int = i
            AND (v_vois ->> 'total')::int = array_length(v_refs, 1)
            AND (v_vois ->> 'precedent') IS NOT DISTINCT FROM (CASE WHEN i > 1 THEN v_refs[i - 1] END)
            AND (v_vois ->> 'suivant') IS NOT DISTINCT FROM v_refs[i + 1],
            q.label || ' ' || v_tri || ' ' || v_filtre::text || ' : voisins du rang ' || i);
        END LOOP;
      END LOOP;
    END LOOP;
    PERFORM pg_temp.vrai(public.voisins_enseignant('CAND-00000', '{}', 'activite') = '{"erreur": "absente"}'::jsonb,
      q.label || ' : reference inconnue = absente');

    -- 3. Les pieces en attente et leur reference.
    PERFORM pg_temp.vrai(
      (SELECT jsonb_agg(to_jsonb(d) ORDER BY n) FROM public.dossiers_en_attente() WITH ORDINALITY AS d(profile_id,
         immutable_id, first_name, last_name, role, account_status, inscrit_le, document_id, doc_type, document_gender,
         object_key, depose_le, etat_piece, n))
      = (SELECT jsonb_agg((to_jsonb(r) - 'candidature_id' - 'candidature_reference') || jsonb_build_object('n', n) ORDER BY n)
           FROM public.dossiers_en_attente_references() WITH ORDINALITY AS r(profile_id, immutable_id, first_name,
             last_name, role, account_status, inscrit_le, document_id, doc_type, document_gender, object_key, depose_le,
             etat_piece, candidature_id, candidature_reference, n)),
      q.label || ' : dossiers_en_attente_references = dossiers_en_attente, meme ordre');
    PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM public.dossiers_en_attente_references() r
       WHERE r.candidature_reference IS DISTINCT FROM
             (SELECT x.reference FROM pp_refs x WHERE x.profile_id = r.profile_id)),
      q.label || ' : la reference est celle de la candidature enseignante du compte');
  END LOOP;

  -- Refus : un compte qui n'est pas la direction.
  PERFORM pg_temp.qui('9e9c0000-0000-4000-8000-000000000001', 'teacher');
  BEGIN
    PERFORM public.comptes_admin_page('eleves');
    RAISE EXCEPTION 'PERSONNES-LECTURES ROUGE : un enseignant lit les comptes';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK comptes_admin_page refuse a un enseignant';
  END;
  BEGIN
    PERFORM public.voisins_enseignant('CAND-90001');
    RAISE EXCEPTION 'PERSONNES-LECTURES ROUGE : un enseignant lit les voisins';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK voisins_enseignant refuse a un enseignant';
  END;
  PERFORM pg_temp.qui('9e900000-0000-4000-8000-0000000000d1', 'admin');
  BEGIN
    PERFORM public.comptes_admin_page('tous');
    RAISE EXCEPTION 'PERSONNES-LECTURES ROUGE : vue inconnue acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN RAISE NOTICE 'OK vue inconnue refusee (22023)';
  END;
END $$;
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.comptes_admin_page(text,text,jsonb,text,integer,integer,boolean)', 'EXECUTE')
                    AND NOT has_function_privilege('anon', 'public.voisins_enseignant(text,jsonb,text)', 'EXECUTE')
                    AND NOT has_function_privilege('anon', 'public.dossiers_en_attente_references()', 'EXECUTE'),
  'aucune des trois lectures pour anon');
\o
SELECT 'PERSONNES-LECTURES : tous les controles sont verts' AS bilan;
ROLLBACK;
