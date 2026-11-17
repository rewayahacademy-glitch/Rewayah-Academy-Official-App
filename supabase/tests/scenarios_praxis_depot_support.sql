-- PX-BD-SUPPORT, etage 2 (17/11/2026, migration 20261129990000_praxis_depot_support.sql) : le serveur du depot d'un support texte.
-- Aucune personne reelle : une direction fictive, des cles fictives, un secret de confirmation fictif (annule a la fin).
-- Cas : 1 le catalogue et le format `texte` ; 2 preparer (brouillon reserve a la direction, intention, parametres bornes) ; 3 confirmer
-- (la signature de l'Edge est reverifiee ; une mauvaise est refusee ; une bonne range un artefact de format `texte`) ; 4 le depot humain n'a
-- pas bouge (PDF accepte, texte refuse pour une preuve, 100 001 octets refuses) ; 5 la routine ne fait rien ; 6 les adaptateurs sont prives.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX-BD-SUPPORT ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.appel(p_id uuid, p_role text, p_aal text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"sentinelle":true}', true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text), pg_temp.srv(text)
  TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.u(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b00000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b11111-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.s(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1bccccc-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(integer), pg_temp.idem(integer), pg_temp.s(integer) TO authenticated, anon, service_role;


INSERT INTO auth.users (id, email) VALUES (pg_temp.u(1), 'pxsup-1@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(1), 'SUP-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u(1));
INSERT INTO private.library_upload_confirmation_secrets (secret) VALUES (pg_catalog.repeat('s', 40));
CREATE FUNCTION pg_temp.cle(p_n integer, p_usage text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE j jsonb;
BEGIN
  j := pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', pg_catalog.format(
    'SELECT public.direction_praxis_emettre_cle(%L, %L, pg_catalog.now() + interval ''30 days'', %L::uuid)',
    'Cle d''essai ' || p_n, p_usage, pg_temp.idem(900 + p_n)));
  RETURN j ->> 'secret';
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.cle(integer, text) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.code_de(p_jeton text) RETURNS text LANGUAGE sql AS $$
  SELECT x ->> 'code' FROM pg_catalog.jsonb_array_elements(
    pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_confirmations()')) x WHERE x ->> 'id' = p_jeton $$;
GRANT EXECUTE ON FUNCTION pg_temp.code_de(text) TO authenticated, anon, service_role;

CREATE FUNCTION pg_temp.agir(p_cle text, p_acte text, p_params text, p_n integer) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, %L, %L::jsonb, %L::uuid)', p_cle, p_acte, p_params, pg_temp.idem(p_n))) $$;
GRANT EXECUTE ON FUNCTION pg_temp.agir(text, text, text, integer) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.signer(p_id text, p_sha text, p_octets integer) RETURNS text LANGUAGE sql AS $$
  SELECT pg_catalog.encode(extensions.hmac(pg_catalog.convert_to(p_id || E'\n' || p_sha || E'\n' || p_octets::text, 'UTF8'),
                                           pg_catalog.convert_to(pg_catalog.repeat('s', 40), 'UTF8'), 'sha256'), 'hex') $$;
GRANT EXECUTE ON FUNCTION pg_temp.signer(text, text, integer) TO authenticated, anon, service_role;

SELECT pg_temp.cle(1, 'chat') AS k1 \gset
SELECT pg_temp.cle(2, 'routine') AS kr \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler(true, true, 100)');
UPDATE private.praxis_reglages SET donnees_reelles = true;
SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to('# Titre', 'UTF8')), 'hex') AS sha \gset

-- 1. Le catalogue et le format.
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(acte || ':' || niveau ORDER BY acte) FROM private.praxis_actes
                      WHERE acte LIKE 'depot\_support\_%' ESCAPE '\') = ARRAY['depot_support_confirmer:A', 'depot_support_preparer:A'],
  '1a : le catalogue porte EXACTEMENT deux actes depot_support_*, de niveau A');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM pg_catalog.pg_enum e JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
                             WHERE t.typname = 'format_artefact' AND e.enumlabel = 'texte'), '1b : le format texte existe');

-- 2. Preparer.
SELECT pg_temp.agir(:'k1', 'depot_support_preparer',
  pg_catalog.format('{"titre": "Les lettres", "langue": "ar", "rayon": "cours", "description": "Fiche", "octets": 7, "sha256": "%s"}', :'sha'), 1) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND :'j'::jsonb #>> '{resultat,etat}' = 'brouillon'
                    AND :'j'::jsonb #>> '{resultat,cle_finale}' ~ '^supports/[0-9a-f-]{36}/1/document\.md$'
                    AND (:'j'::jsonb #>> '{resultat,upload_id}') ~ '^[0-9a-f-]{36}$',
  '2a : preparer cree le brouillon et l''intention, la cle finale est celle du serveur');
SELECT :'j'::jsonb #>> '{resultat,id}' AS rid, :'j'::jsonb #>> '{resultat,upload_id}' AS upl \gset
SELECT pg_temp.vrai((SELECT r.access_policy::text = 'admin' AND r.resource_type::text = 'structured_text' AND r.current_version_id IS NULL
                            AND r.language = 'ar' AND r.rayon = 'cours' AND r.archived_at IS NULL
                       FROM public.library_resource r WHERE r.id = :'rid'::uuid),
  '2b : le support est un BROUILLON reserve a la direction, jamais publie');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.library_upload_intentions i WHERE i.id = :'upl'::uuid AND i.etat = 'attente'
                            AND i.mime_annonce = 'text/markdown' AND i.finalite = 'support' AND i.requested_by = pg_temp.u(1)) = 1,
  '2c : l''intention est a l''identite de la direction emettrice');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'depot_support_preparer',
  pg_catalog.format('{"titre": "Les lettres", "langue": "ar", "rayon": "cours", "description": "Fiche", "octets": 7, "sha256": "%s"}', :'sha'), 1) ->> 'rejoue' = 'true'
  AND (SELECT pg_catalog.count(*) FROM public.library_resource WHERE title = 'Les lettres') = 1,
  '2d : la meme cle d''idempotence ne cree jamais un second brouillon');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'depot_support_preparer', p, 20 + n) -> 'resultat' ->> 'erreur' = 'parametre',
  '2e : parametre refuse : ' || pg_catalog.left(p, 90))
  FROM (VALUES
    (1, '{"titre": "T", "langue": "fr", "octets": 7, "sha256": "' || :'sha' || '", "quoi": 1}'),
    (2, '{"titre": " ", "langue": "fr", "octets": 7, "sha256": "' || :'sha' || '"}'),
    (3, '{"titre": "T", "langue": "francais", "octets": 7, "sha256": "' || :'sha' || '"}'),
    (4, '{"titre": "T", "langue": "fr", "octets": 0, "sha256": "' || :'sha' || '"}'),
    (5, '{"titre": "T", "langue": "fr", "octets": 100001, "sha256": "' || :'sha' || '"}'),
    (6, '{"titre": "T", "langue": "fr", "octets": 7, "sha256": "xyz"}'),
    (7, '{"titre": "T", "langue": "fr", "octets": 7, "sha256": "' || :'sha' || '", "rayon": "autre"}'),
    (8, '{"titre": "T", "langue": "fr", "octets": "7", "sha256": "' || :'sha' || '"}'),
    (9, '{"titre": "T", "langue": "fr", "octets": 7, "sha256": "' || :'sha' || '", "description": "' || pg_catalog.repeat('x', 1001) || '"}')) v(n, p);
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.library_resource WHERE title = 'T') = 0,
  '2f : un parametre refuse ne laisse aucun brouillon');

-- 3. Confirmer.
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'depot_support_confirmer',
  pg_catalog.format('{"upload_id": "%s", "sha256": "%s", "octets": 7, "signature": "%s"}', :'upl', :'sha', pg_catalog.repeat('0', 64)), 2) ->> 'erreur' = 'refuse',
  '3a : une mauvaise signature est refusee par la base');
SELECT pg_temp.vrai((SELECT i.etat FROM private.library_upload_intentions i WHERE i.id = :'upl'::uuid) = 'attente'
                    AND NOT EXISTS (SELECT 1 FROM public.download_asset a JOIN public.resource_version v ON v.id = a.resource_version_id
                                     WHERE v.resource_id = :'rid'::uuid),
  '3b : rien n''est range apres un refus');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'depot_support_confirmer',
  pg_catalog.format('{"upload_id": "%s", "sha256": "%s", "octets": 8, "signature": "%s"}', :'upl', :'sha', pg_temp.signer(:'upl', :'sha', 8)), 3) ->> 'erreur' = 'refuse',
  '3c : une taille differente de celle annoncee est refusee, meme bien signee');
SELECT pg_temp.agir(:'k1', 'depot_support_confirmer',
  pg_catalog.format('{"upload_id": "%s", "sha256": "%s", "octets": 7, "signature": "%s"}', :'upl', :'sha', pg_temp.signer(:'upl', :'sha', 7)), 4) AS c \gset
SELECT pg_temp.vrai((:'c'::jsonb ->> 'ok')::boolean AND :'c'::jsonb #>> '{resultat,etat}' = 'brouillon', '3d : la bonne signature confirme le depot');
SELECT pg_temp.vrai((SELECT a.format::text = 'texte' AND a.taille_octets = 7 AND a.empreinte = :'sha' AND a.cle_stockage ~ '^supports/.*/document\.md$'
                       FROM public.download_asset a JOIN public.resource_version v ON v.id = a.resource_version_id
                      WHERE v.resource_id = :'rid'::uuid)
                    AND (SELECT v.download_asset_id IS NOT NULL AND v.statut = 'brouillon' FROM public.resource_version v WHERE v.resource_id = :'rid'::uuid)
                    AND (SELECT r.current_version_id IS NULL AND r.access_policy::text = 'admin' FROM public.library_resource r WHERE r.id = :'rid'::uuid),
  '3e : un artefact de format texte est range, la version reste un BROUILLON non publie');

-- 4. Le depot humain n'a pas bouge.
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.library_creer_brouillon(''{"titre":"Humain","type":"pdf","langue":"fr","categorie":""}''::jsonb)') ->> 'id' AS hid \gset
SELECT pg_temp.vrai(pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', pg_catalog.format(
  'SELECT public.demander_upload_bibliotheque(%L::uuid, ''support'', ''document.pdf'', ''application/pdf'', 4321, %L)', :'hid', :'sha')) ->> 'mime' = 'application/pdf',
  '4a : un PDF se demande toujours');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.library_creer_brouillon(''{"titre":"Humain2","type":"pdf","langue":"fr","categorie":""}''::jsonb)') ->> 'id' AS hid2 \gset
CREATE FUNCTION pg_temp.refuse(p_sql text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(pg_temp.u(1), 'admin', 'aal2');
  EXECUTE 'SET LOCAL ROLE authenticated';
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    EXECUTE 'RESET ROLE';
    RETURN true;
  END;
  EXECUTE 'RESET ROLE';
  RETURN false;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.refuse(text) TO authenticated, anon, service_role;
SELECT pg_temp.vrai(pg_temp.refuse(pg_catalog.format('SELECT public.demander_upload_bibliotheque(%L::uuid, ''preuve'', ''p.md'', ''text/markdown'', 10, %L)', :'hid2', :'sha')),
  '4b : un texte Markdown n''est jamais une preuve de droits');
SELECT pg_temp.vrai(NOT pg_temp.refuse(pg_catalog.format('SELECT public.demander_upload_bibliotheque(%L::uuid, ''support'', ''document.md'', ''text/markdown'', 100000, %L)', :'hid2', :'sha')),
  '4c0 : 100 000 octets sont acceptes pour un texte (le temoin du refus qui suit)');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.library_creer_brouillon(''{"titre":"Humain3","type":"pdf","langue":"fr","categorie":""}''::jsonb)') ->> 'id' AS hid3 \gset
SELECT pg_temp.vrai(pg_temp.refuse(pg_catalog.format('SELECT public.demander_upload_bibliotheque(%L::uuid, ''support'', ''document.md'', ''text/markdown'', 100001, %L)', :'hid3', :'sha')),
  '4c : 100 001 octets sont refuses pour un texte');
SELECT pg_temp.vrai(pg_temp.refuse(pg_catalog.format('SELECT public.demander_upload_bibliotheque(%L::uuid, ''support'', ''document.txt'', ''text/plain'', 10, %L)', :'hid2', :'sha')),
  '4d : text/plain reste refuse');

-- 5. La routine ne fait rien.
SELECT pg_temp.vrai(pg_temp.agir(:'kr', 'depot_support_preparer',
  pg_catalog.format('{"titre": "R", "langue": "fr", "octets": 7, "sha256": "%s"}', :'sha'), 5) ->> 'erreur' = 'chat_seulement'
  AND (SELECT pg_catalog.count(*) FROM public.library_resource WHERE title = 'R') = 0,
  '5a : la cle de routine est refusee et ne cree rien');

-- 6. Les adaptateurs sont prives.
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege(r, f, 'EXECUTE'),
  '6a : ' || r || ' ne peut pas executer ' || f)
  FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r,
       unnest(ARRAY['private.praxis_acte_depot_support_preparer(jsonb, boolean)', 'private.praxis_acte_depot_support_confirmer(jsonb, boolean)']) f;
SELECT pg_temp.vrai((SELECT pg_catalog.bool_and(pg_catalog.pg_get_functiondef(f::regprocedure) !~* '\mEXECUTE\M')
                       FROM unnest(ARRAY['private.praxis_acte_depot_support_preparer(jsonb, boolean)',
                                         'private.praxis_acte_depot_support_confirmer(jsonb, boolean)']) f),
  '6b : aucun SQL dynamique dans les adaptateurs');

SELECT 'PX-BD-SUPPORT : tous les scenarios sont verts' AS resultat;
ROLLBACK;
