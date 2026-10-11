-- CAP29 C-30 rights review RPC, prepared for isolated PG17 replay; not run here.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('c29d2000-0000-0000-0000-000000000001','cap29-rights-admin@test.invalid'),
 ('c29d2000-0000-0000-0000-000000000002','cap29-rights-teacher@test.invalid');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('c29d2000-0000-0000-0000-000000000001','CAP29-RIGHTS-ADMIN','admin',NULL,'Admin','Rights','active','female'),
 ('c29d2000-0000-0000-0000-000000000002','CAP29-RIGHTS-TEACH','teacher',NULL,'Teacher','Rights','active','male');
INSERT INTO public.library_resource
 (id, title, short_title, resource_type, language, category, access_policy, offline_policy)
VALUES
 ('c29d2000-0000-0000-0000-000000000003','Rights review fixture','Fixture','pdf','fr','cours','admin','jamais');
INSERT INTO public.resource_version (id, resource_id, numero_version, empreinte)
VALUES ('c29d2000-0000-0000-0000-000000000004',
        'c29d2000-0000-0000-0000-000000000003',1,
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc');
INSERT INTO private.library_rights_proofs
 (id, resource_id, resource_version_id, cle_stockage, sha256, mime, taille, deposee_par, statut)
VALUES ('c29d2000-0000-0000-0000-000000000005',
        'c29d2000-0000-0000-0000-000000000003',
        'c29d2000-0000-0000-0000-000000000004',
        'private/libraryproof/c29-rights-fixture',
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
        'application/pdf',512,'c29d2000-0000-0000-0000-000000000001','en_attente');

SELECT set_config('request.jwt.claim.sub','c29d2000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $scenario$
DECLARE v_result jsonb;
BEGIN
 v_result := public.admin_library_review_rights(
  'c29d2000-0000-0000-0000-000000000003',
  'c29d2000-0000-0000-0000-000000000004',
  '{"sourceTitre":"Source test","titulaire":"Titulaire test","preuveFournie":true,"usages":["classe","horsLigne"],"attribution":"Attribution","expireLeUtc":null,"approuver":true}'::jsonb,
  1);
 IF v_result->>'resultat' <> 'EcritureFaite' OR (v_result->>'revision')::int <> 2
    OR v_result::text LIKE '%libraryproof%' THEN
  RAISE EXCEPTION 'CAP29: revue admin ou projection de résultat invalide: %',v_result;
 END IF;
 v_result := public.admin_library_review_rights(
  'c29d2000-0000-0000-0000-000000000003',
  'c29d2000-0000-0000-0000-000000000004',
  '{"sourceTitre":"Autre","titulaire":"Titulaire test","preuveFournie":true,"usages":["classe"],"attribution":"Attribution","expireLeUtc":null,"approuver":true}'::jsonb,
  1);
 IF v_result->>'resultat' <> 'EcritureEnConflit' OR (v_result->>'revision')::int <> 2 THEN
  RAISE EXCEPTION 'CAP29: conflit de revision non rendu';
 END IF;
END;
$scenario$;
RESET ROLE;

DO $postflight$
BEGIN
 IF NOT (SELECT approuve FROM public.library_version_rights
          WHERE resource_version_id='c29d2000-0000-0000-0000-000000000004')
    OR (SELECT source_titre FROM public.library_version_rights
         WHERE resource_version_id='c29d2000-0000-0000-0000-000000000004') <> 'Source test'
    OR (SELECT usages FROM public.library_version_rights
         WHERE resource_version_id='c29d2000-0000-0000-0000-000000000004') <> ARRAY['classe','hors_ligne']
    OR (SELECT statut FROM private.library_rights_proofs
         WHERE id='c29d2000-0000-0000-0000-000000000005') <> 'confirmee'
    OR (SELECT revision FROM public.library_resource
         WHERE id='c29d2000-0000-0000-0000-000000000003') <> 2
    OR (SELECT count(*) FROM public.audit_logs
         WHERE action='library_rights_review'
           AND row_id='c29d2000-0000-0000-0000-000000000003') <> 1 THEN
   RAISE EXCEPTION 'CAP29: droits, preuve, revision ou audit non conformes';
 END IF;
 IF has_function_privilege('anon','public.admin_library_review_rights(uuid,uuid,jsonb,integer)','EXECUTE')
    OR has_function_privilege('service_role','public.admin_library_review_rights(uuid,uuid,jsonb,integer)','EXECUTE')
    OR has_function_privilege('agent_ro','public.admin_library_review_rights(uuid,uuid,jsonb,integer)','EXECUTE')
    OR NOT has_function_privilege('authenticated','public.admin_library_review_rights(uuid,uuid,jsonb,integer)','EXECUTE') THEN
   RAISE EXCEPTION 'CAP29: ACL de revue des droits invalide';
 END IF;
END;
$postflight$;

SELECT set_config('request.jwt.claim.sub','c29d2000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $negative$
BEGIN
  BEGIN
    PERFORM public.admin_library_review_rights(
      'c29d2000-0000-0000-0000-000000000003',
      'c29d2000-0000-0000-0000-000000000004',
      '{"sourceTitre":"S","titulaire":"T","preuveFournie":false,"usages":["classe"],"attribution":"A","expireLeUtc":null,"approuver":false}'::jsonb,
      2);
    RAISE EXCEPTION 'CAP29: non-admin a modifie les droits';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$negative$;
RESET ROLE;

ROLLBACK;