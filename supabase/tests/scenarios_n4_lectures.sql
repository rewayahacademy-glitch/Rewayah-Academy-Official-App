-- N4, partie serveur (03/11/2026) : migration 20261108200000, sous
-- `authenticated`.
--   1. bibliotheque_catalogue_lecteur rend exactement ce que la policy
--      library_resource_lecture ouvre : l'eleve de la Classe voit publique,
--      inscrits et groupe_assigne ; l'eleve exterieur publique et inscrits ;
--      l'enseignant de la Classe en plus enseignant_seul ; jamais un
--      brouillon ni une ressource archivee ; aucune cle de stockage ;
--   2. un filtre inconnu est refuse ; « parId » d'une ressource invisible
--      rend une liste vide ; un compte suspendu est refuse ;
--   3. recents et reprise ne rendent que des ressources encore visibles ;
--   4. mes_evaluations_publiees : l'eleve voit son code, le tuteur ceux de son
--      foyer, jamais ceux d'un autre foyer ; l'enseignant est refuse.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c4400000-0000-0000-0000-000000000001', 'n4-eleve@example.test'),
  ('c4400000-0000-0000-0000-000000000002', 'n4-dehors@example.test'),
  ('c4400000-0000-0000-0000-000000000003', 'n4-tuteur@example.test'),
  ('c4400000-0000-0000-0000-000000000004', 'n4-enseignant@example.test'),
  ('c4400000-0000-0000-0000-000000000005', 'n4-suspendu@example.test'),
  ('c4400000-0000-0000-0000-000000000006', 'n4-camarade@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('c44fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('c44fffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('c44fffff-0000-0000-0000-000000000003', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('c4400000-0000-0000-0000-000000000001', 'N4ELEVE00000001', 'student', 'c44fffff-0000-0000-0000-000000000001', 'Nour', 'Quatre', 'active'),
  ('c4400000-0000-0000-0000-000000000002', 'N4DEHORS0000002', 'student', 'c44fffff-0000-0000-0000-000000000002', 'Dehors', 'Quatre', 'active'),
  ('c4400000-0000-0000-0000-000000000003', 'N4TUTEUR0000003', 'guardian', 'c44fffff-0000-0000-0000-000000000001', 'Tuteur', 'Quatre', 'active'),
  ('c4400000-0000-0000-0000-000000000004', 'N4ENSEIGN000004', 'teacher', NULL, 'Enseignant', 'Quatre', 'provisional_active'),
  ('c4400000-0000-0000-0000-000000000005', 'N4SUSPEND000005', 'student', 'c44fffff-0000-0000-0000-000000000002', 'Suspendu', 'Quatre', 'disabled'),
  ('c4400000-0000-0000-0000-000000000006', 'N4CAMARA0000006', 'student', 'c44fffff-0000-0000-0000-000000000003', 'Camarade', 'Quatre', 'active');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  ('c4400000-0000-0000-0000-000000000001', 'minor', 'child'),
  ('c4400000-0000-0000-0000-000000000002', 'minor', 'child'),
  ('c4400000-0000-0000-0000-000000000006', 'minor', 'child');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('c4400000-0000-0000-0000-000000000021', 'c4400000-0000-0000-0000-000000000004',
        'enfant', 5, 'Classe N4', 1, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('c4400000-0000-0000-0000-000000000021', 'c4400000-0000-0000-0000-000000000001'),
  ('c4400000-0000-0000-0000-000000000021', 'c4400000-0000-0000-0000-000000000006');

-- Six ressources : publique, inscrits, groupe_assigne, enseignant_seul
-- (publiees), un brouillon et une archivee.
INSERT INTO public.library_resource (id, title, short_title, resource_type, access_policy, offline_policy, category)
VALUES
  ('c4400000-0000-0000-0000-000000000101', 'N4 publique', 'N4 pub', 'pdf', 'publique', 'jamais', 'lecture'),
  ('c4400000-0000-0000-0000-000000000102', 'N4 inscrits', 'N4 ins', 'pdf', 'inscrits', 'jamais', 'lecture'),
  ('c4400000-0000-0000-0000-000000000103', 'N4 classe', 'N4 grp', 'pdf', 'groupe_assigne', 'jamais', 'lecture'),
  ('c4400000-0000-0000-0000-000000000104', 'N4 enseignant', 'N4 ens', 'pdf', 'enseignant_seul', 'jamais', 'lecture'),
  ('c4400000-0000-0000-0000-000000000105', 'N4 brouillon', 'N4 brl', 'pdf', 'publique', 'jamais', 'lecture'),
  ('c4400000-0000-0000-0000-000000000106', 'N4 archivee', 'N4 arc', 'pdf', 'publique', 'jamais', 'lecture');
INSERT INTO public.resource_version (id, resource_id, numero_version, statut)
SELECT ('c4400000-0000-0000-0000-000000000' || (200 + n))::uuid,
       ('c4400000-0000-0000-0000-000000000' || (100 + n))::uuid, 1, 'brouillon'
  FROM generate_series(1, 6) n;
INSERT INTO public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
SELECT ('c4400000-0000-0000-0000-000000000' || (200 + n))::uuid, 'Support N4', 'Titulaire N4',
       ARRAY['application'], 'Attribution N4', true, 'c4400000-0000-0000-0000-000000000004', now()
  FROM generate_series(1, 6) n;
INSERT INTO public.library_resource_groupe (resource_id, groupe_id) VALUES
  ('c4400000-0000-0000-0000-000000000103', 'c4400000-0000-0000-0000-000000000021'),
  ('c4400000-0000-0000-0000-000000000104', 'c4400000-0000-0000-0000-000000000021');
SELECT set_config('request.jwt.claim.sub', 'c4400000-0000-0000-0000-000000000004', true);
UPDATE public.resource_version SET statut = 'publiee'
 WHERE resource_id IN ('c4400000-0000-0000-0000-000000000101', 'c4400000-0000-0000-0000-000000000102',
                       'c4400000-0000-0000-0000-000000000103', 'c4400000-0000-0000-0000-000000000104',
                       'c4400000-0000-0000-0000-000000000106');
UPDATE public.library_resource r SET current_version_id = v.id
  FROM public.resource_version v
 WHERE v.resource_id = r.id AND v.statut = 'publiee'
   AND r.id::text LIKE 'c4400000-%';
UPDATE public.library_resource SET archived_at = now()
 WHERE id = 'c4400000-0000-0000-0000-000000000106';

-- Positions de lecture de Nour : la ressource enseignant_seul (invisible pour
-- elle) est la plus recente ; puis publique ; puis la classe.
INSERT INTO public.library_reading_position (profile_id, resource_id, type_ancrage, page, vue_le) VALUES
  ('c4400000-0000-0000-0000-000000000001', 'c4400000-0000-0000-0000-000000000103', 'page', 3, now() - interval '2 days'),
  ('c4400000-0000-0000-0000-000000000001', 'c4400000-0000-0000-0000-000000000101', 'page', 7, now() - interval '1 day'),
  ('c4400000-0000-0000-0000-000000000001', 'c4400000-0000-0000-0000-000000000104', 'page', 9, now());

-- Une evaluation publiee pour la Classe : Nour et sa camarade d'un autre foyer.
INSERT INTO public.evaluation_publications (id, groupe_id, titre, affichage, published_by)
VALUES ('c4400000-0000-0000-0000-000000000301', 'c4400000-0000-0000-0000-000000000021',
        'Evaluation N4', 'code', 'c4400000-0000-0000-0000-000000000004');
INSERT INTO private.evaluation_codes (publication_id, student_id, code) VALUES
  ('c4400000-0000-0000-0000-000000000301', 'c4400000-0000-0000-0000-000000000001', 'EV-4401'),
  ('c4400000-0000-0000-0000-000000000301', 'c4400000-0000-0000-0000-000000000006', 'EV-4406');

CREATE FUNCTION pg_temp.qui(p_uid text, p_role text, p_foyer text DEFAULT NULL) RETURNS void
LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_uid, true),
         set_config('request.jwt.claims', jsonb_build_object('sub', p_uid,
           'app_metadata', jsonb_build_object('role', p_role, 'household_id', p_foyer))::text, true);
$$;
CREATE FUNCTION pg_temp.titres(p jsonb) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(string_agg(e ->> 'title', ',' ORDER BY e ->> 'title'), '') FROM jsonb_array_elements(p) e $$;

-- Une seule regle : pour un lecteur, les ressources rendues sont exactement
-- celles que la policy library_resource_lecture lui laisse lire (RLS).
CREATE FUNCTION pg_temp.meme_regle(p_qui text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_rpc text; v_rls text;
BEGIN
  SELECT coalesce(string_agg(e ->> 'id', ',' ORDER BY e ->> 'id'), '') INTO v_rpc
    FROM jsonb_array_elements(public.bibliotheque_catalogue_lecteur()) e;
  SELECT coalesce(string_agg(r.id::text, ',' ORDER BY r.id::text), '') INTO v_rls
    FROM public.library_resource r WHERE r.id::text LIKE 'c4400000-%';
  IF v_rpc <> v_rls THEN
    RAISE EXCEPTION 'N4 ROUGE : % : la fonction (%) et la RLS (%) divergent', p_qui, v_rpc, v_rls;
  END IF;
END $$;

SET LOCAL ROLE authenticated;

-- 1. L'eleve de la Classe.
SELECT pg_temp.qui('c4400000-0000-0000-0000-000000000001', 'student', 'c44fffff-0000-0000-0000-000000000001');
DO $eleve$
DECLARE v jsonb; r jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres(v) <> 'N4 classe,N4 inscrits,N4 publique' THEN
    RAISE EXCEPTION 'N4 ROUGE : eleve de la Classe, catalogue %', pg_temp.titres(v);
  END IF;
  IF v::text ILIKE '%supports/%' OR v::text ILIKE '%cle_stockage%' THEN
    RAISE EXCEPTION 'N4 ROUGE : une cle de stockage sort du catalogue';
  END IF;
  IF v -> 0 ->> 'current_version_id' IS NULL OR v -> 0 ->> 'access_policy' IS NULL THEN
    RAISE EXCEPTION 'N4 ROUGE : manifeste incomplet %', v -> 0;
  END IF;
  v := public.bibliotheque_catalogue_lecteur('{"recherche":"class"}'::jsonb);
  IF pg_temp.titres(v) <> 'N4 classe' THEN
    RAISE EXCEPTION 'N4 ROUGE : recherche %', pg_temp.titres(v);
  END IF;
  v := public.bibliotheque_catalogue_lecteur('{"id":"c4400000-0000-0000-0000-000000000104"}'::jsonb);
  IF v <> '[]'::jsonb THEN
    RAISE EXCEPTION 'N4 ROUGE : parId d''une ressource enseignant_seul rendue a l''eleve';
  END IF;
  BEGIN
    PERFORM public.bibliotheque_catalogue_lecteur('{"inconnu":1}'::jsonb);
    RAISE EXCEPTION 'N4 ROUGE : filtre inconnu accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  v := public.bibliotheque_recents_lecteur(10);
  IF pg_temp.titres(v) <> 'N4 classe,N4 publique' OR v -> 0 ->> 'title' <> 'N4 publique' THEN
    RAISE EXCEPTION 'N4 ROUGE : recents % (ordre %)', pg_temp.titres(v), v -> 0 ->> 'title';
  END IF;
  r := public.bibliotheque_reprise_lecteur();
  IF r -> 'ressource' ->> 'title' <> 'N4 publique' OR (r -> 'position' ->> 'page')::int <> 7
     OR r -> 'position' ->> 'type_ancrage' <> 'page' THEN
    RAISE EXCEPTION 'N4 ROUGE : reprise %', r;
  END IF;
  v := public.mes_evaluations_publiees();
  IF jsonb_array_length(v) <> 1 OR v -> 0 ->> 'code' <> 'EV-4401' OR v -> 0 ->> 'classe' <> 'Classe N4' THEN
    RAISE EXCEPTION 'N4 ROUGE : evaluations de l''eleve %', v;
  END IF;
END;
$eleve$;
SELECT pg_temp.meme_regle('eleve');

-- 2. L'eleve exterieur a la Classe.
SELECT pg_temp.qui('c4400000-0000-0000-0000-000000000002', 'student', 'c44fffff-0000-0000-0000-000000000002');
DO $dehors$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres(v) <> 'N4 inscrits,N4 publique' THEN
    RAISE EXCEPTION 'N4 ROUGE : eleve exterieur, catalogue %', pg_temp.titres(v);
  END IF;
  IF public.bibliotheque_reprise_lecteur() IS NOT NULL THEN
    RAISE EXCEPTION 'N4 ROUGE : reprise d''un autre lecteur';
  END IF;
  IF public.mes_evaluations_publiees() <> '[]'::jsonb THEN
    RAISE EXCEPTION 'N4 ROUGE : evaluations d''une autre Classe';
  END IF;
END;
$dehors$;
SELECT pg_temp.meme_regle('dehors');

-- 3. Le tuteur du foyer de Nour : son code a elle, jamais celui de la camarade.
SELECT pg_temp.qui('c4400000-0000-0000-0000-000000000003', 'guardian', 'c44fffff-0000-0000-0000-000000000001');
DO $tuteur$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres(v) <> 'N4 classe,N4 inscrits,N4 publique' THEN
    RAISE EXCEPTION 'N4 ROUGE : tuteur, catalogue %', pg_temp.titres(v);
  END IF;
  v := public.mes_evaluations_publiees();
  IF jsonb_array_length(v) <> 1 OR v -> 0 ->> 'code' <> 'EV-4401' OR v -> 0 ->> 'eleve_prenom' <> 'Nour'
     OR v::text LIKE '%EV-4406%' THEN
    RAISE EXCEPTION 'N4 ROUGE : evaluations du tuteur %', v;
  END IF;
END;
$tuteur$;
SELECT pg_temp.meme_regle('tuteur');

-- 4. L'enseignant de la Classe : enseignant_seul en plus ; pas d'evaluations
--    de famille.
SELECT pg_temp.qui('c4400000-0000-0000-0000-000000000004', 'teacher');
DO $enseignant$
DECLARE v jsonb;
BEGIN
  v := public.bibliotheque_catalogue_lecteur();
  IF pg_temp.titres(v) <> 'N4 classe,N4 enseignant,N4 inscrits,N4 publique' THEN
    RAISE EXCEPTION 'N4 ROUGE : enseignant, catalogue %', pg_temp.titres(v);
  END IF;
  BEGIN
    PERFORM public.mes_evaluations_publiees();
    RAISE EXCEPTION 'N4 ROUGE : l''enseignant lit les evaluations des familles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$enseignant$;
SELECT pg_temp.meme_regle('enseignant');

-- 5. Un compte desactive (disabled) : refuse partout.
SELECT pg_temp.qui('c4400000-0000-0000-0000-000000000005', 'student', 'c44fffff-0000-0000-0000-000000000002');
DO $suspendu$
BEGIN
  BEGIN
    PERFORM public.bibliotheque_catalogue_lecteur();
    RAISE EXCEPTION 'N4 ROUGE : compte suspendu, catalogue lu';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.mes_evaluations_publiees();
    RAISE EXCEPTION 'N4 ROUGE : compte suspendu, evaluations lues';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$suspendu$;
RESET ROLE;

-- 6. Droits.
DO $droits$
BEGIN
  IF has_function_privilege('anon', 'public.bibliotheque_catalogue_lecteur(jsonb,integer)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.mes_evaluations_publiees()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.n4_ressource_lisible(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'N4 ROUGE : droits trop larges';
  END IF;
END;
$droits$;

ROLLBACK;
