-- CONTRATS-MANQUANTS : Bibliotheque de la direction (PortBibliothequeAdmin).
-- Correctif du catalogue (42P01 puis 42501, 20261016100600) et ecritures
-- (brouillon, version, controle, publication, attribution, retrait).
-- Chaque garde a un controle de refus. A rejouer sur une base NEUVE.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
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
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- La revision courante d'un support, lue par la fiche.
CREATE FUNCTION pg_temp.rev(p_id text) RETURNS integer
LANGUAGE sql AS $$ SELECT (public.library_get_detail(p_id::uuid) ->> 'revision')::int $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.rev(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('cb000000-0000-4000-8000-0000000000a1','cb-admin@test.invalid'),
 ('cb000000-0000-4000-8000-0000000000a2','cb-admin-off@test.invalid'),
 ('cb000000-0000-4000-8000-0000000000b1','cb-t1@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('cb000000-0000-4000-8000-0000000000a1','CB-ADM-0001','admin',NULL,'Direction','Essai','active','female'),
 ('cb000000-0000-4000-8000-0000000000a2','CB-ADM-0002','admin',NULL,'Direction','Desactivee','disabled','male'),
 ('cb000000-0000-4000-8000-0000000000b1','CB-ENS-0001','teacher',NULL,'Yusuf','Fictif','provisional_active','male');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('cb000000-0000-4000-8000-0000000000c1','cb000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour Essai',1,18,'Europe/Paris'),
 ('cb000000-0000-4000-8000-0000000000c2','cb000000-0000-4000-8000-0000000000b1','enfant',5,'Ancienne Essai',2,18,'Europe/Paris');
UPDATE public.groupes SET ended_at = now(), ended_by = 'cb000000-0000-4000-8000-0000000000a1', end_reason = 'essai'
 WHERE id = 'cb000000-0000-4000-8000-0000000000c2';

-- ------------------------------------------------------------
-- 1. ACL et F86
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.library_get_catalogue(jsonb,text,integer)'::regprocedure,
    'public.library_get_catalogue_facettes()'::regprocedure,
    'public.library_get_detail(uuid)'::regprocedure,
    'public.library_creer_brouillon(jsonb)'::regprocedure,
    'public.library_nouvelle_version(uuid)'::regprocedure,
    'public.library_controler_version(uuid)'::regprocedure,
    'public.library_publier_version(uuid,uuid,integer,text)'::regprocedure,
    'public.library_classes_attribuables(uuid,text,integer)'::regprocedure,
    'public.library_attribuer(uuid,uuid[],boolean,integer)'::regprocedure,
    'public.library_retirer(uuid,text,integer)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND proconfig @> ARRAY['search_path=""'] FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : DEFINER, empreinte ou ACL de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('10 RPC DEFINER, empreinte reelle, authenticated seul');
  IF (SELECT prosecdef FROM pg_proc WHERE oid = 'app_private.library_controle_version(uuid)'::regprocedure)
     OR has_function_privilege('authenticated', 'app_private.library_controle_version(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : controle interne DEFINER ou ouvert';
  END IF;
  PERFORM pg_temp.ok('controle interne INVOKER ferme aux clients');
END $acl$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.library_get_catalogue()$$, '42501', 'anon : catalogue refuse');
SELECT pg_temp.refus($$SELECT public.library_creer_brouillon('{}')$$, '42501', 'anon : brouillon refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Gardes : un enseignant, une direction desactivee
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.library_get_catalogue()$$, '42501', 'enseignant : catalogue refuse');
SELECT pg_temp.refus($$SELECT public.library_get_catalogue_facettes()$$, '42501', 'enseignant : facettes refusees');
SELECT pg_temp.refus($$SELECT public.library_get_detail('cb000000-0000-4000-8000-000000000099')$$, '42501', 'enseignant : fiche refusee');
SELECT pg_temp.refus($$SELECT public.library_creer_brouillon('{"titre":"x","type":"pdf","langue":"fr","categorie":"c"}')$$, '42501', 'enseignant : brouillon refuse');
SELECT pg_temp.refus($$SELECT public.library_nouvelle_version('cb000000-0000-4000-8000-000000000099')$$, '42501', 'enseignant : nouvelle version refusee');
SELECT pg_temp.refus($$SELECT public.library_controler_version('cb000000-0000-4000-8000-000000000099')$$, '42501', 'enseignant : controle refuse');
SELECT pg_temp.refus($$SELECT public.library_publier_version('cb000000-0000-4000-8000-000000000099','cb000000-0000-4000-8000-000000000098',1,'k')$$, '42501', 'enseignant : publication refusee');
SELECT pg_temp.refus($$SELECT public.library_classes_attribuables('cb000000-0000-4000-8000-000000000099')$$, '42501', 'enseignant : classes refusees');
SELECT pg_temp.refus($$SELECT public.library_attribuer('cb000000-0000-4000-8000-000000000099',ARRAY['cb000000-0000-4000-8000-0000000000c1']::uuid[],false,1)$$, '42501', 'enseignant : attribution refusee');
SELECT pg_temp.refus($$SELECT public.library_retirer('cb000000-0000-4000-8000-000000000099','motif essai',1)$$, '42501', 'enseignant : retrait refuse');
SELECT pg_temp.vrai(public.library_admin_capacites() = '{"peutLire": false, "peutImporter": false, "peutPublier": false, "peutAttribuer": false}'::jsonb,
  'enseignant : aucune capacite');
RESET ROLE;
SELECT pg_temp.qui('cb000000-0000-4000-8000-0000000000a2','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.library_creer_brouillon('{"titre":"x","type":"pdf","langue":"fr","categorie":"c"}')$$, '42501', 'direction desactivee : brouillon refuse');
SELECT pg_temp.refus($$SELECT public.library_get_catalogue()$$, '42501', 'direction desactivee : catalogue refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Brouillons et catalogue (le correctif repond enfin)
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.library_admin_capacites() = '{"peutLire": true, "peutImporter": true, "peutPublier": true, "peutAttribuer": true}'::jsonb,
  'direction : capacites d''ecriture rendues');
SELECT pg_temp.vrai(public.library_get_catalogue() = '{"elements": [], "curseur": null}'::jsonb,
  'catalogue vide : repond sans 42P01 ni 42501');
SELECT pg_temp.refus($$SELECT public.library_creer_brouillon('{"titre":"x","type":"video","langue":"fr","categorie":"c"}')$$, '22023', 'type inconnu refuse');
SELECT pg_temp.refus($$SELECT public.library_creer_brouillon('{"titre":"x","type":"pdf","langue":"fr","categorie":"c","cle":"s3"}')$$, '22023', 'champ inconnu refuse');
DO $brouillon$
DECLARE v jsonb; w jsonb; p jsonb;
BEGIN
  v := public.library_creer_brouillon('{"titre":"Manuel essai","type":"pdf","langue":"fr","categorie":"lecture","niveau":"debutant"}');
  PERFORM pg_temp.vrai(v ->> 'id' IS NOT NULL AND v ->> 'version_id' IS NOT NULL AND (v ->> 'revision')::int = 1,
    'brouillon cree avec sa version 1');
  PERFORM set_config('test.s1', v ->> 'id', true);
  PERFORM set_config('test.v1', v ->> 'version_id', true);
  w := public.library_creer_brouillon('{"titre":"Second essai","type":"structured_text","langue":"ar","categorie":"tajwid"}');
  PERFORM set_config('test.s2', w ->> 'id', true);
  p := public.library_get_catalogue('{"etat":"brouillons"}', NULL, 1);
  PERFORM pg_temp.vrai(jsonb_array_length(p -> 'elements') = 1 AND p ->> 'curseur' IS NOT NULL
    AND p -> 'elements' -> 0 ->> 'statutVersion' = 'brouillon',
    'catalogue pagine : une page et un curseur (alias d corrige)');
  p := public.library_get_catalogue('{"etat":"brouillons"}', p ->> 'curseur', 1);
  PERFORM pg_temp.vrai(jsonb_array_length(p -> 'elements') = 1 AND p -> 'curseur' = 'null'::jsonb,
    'catalogue : la page suivante par curseur, puis la fin');
  PERFORM pg_temp.vrai(public.library_get_catalogue_facettes() = '{"niveaux": ["debutant"], "langues": ["ar", "fr"]}'::jsonb,
    'facettes : niveaux et langues presents');
  PERFORM pg_temp.vrai(public.library_get_detail((v ->> 'id')::uuid) -> 'capacites'
    = '{"peutModifier": false, "peutPublier": true, "peutAttribuer": false, "peutRetirer": true}'::jsonb,
    'fiche : capacites calculees (pas d''attribution avant publication)');
END $brouillon$;
RESET ROLE;

-- Depot simule (proprietaire) : la preuve de droits et le fichier du brouillon.
INSERT INTO private.library_rights_proofs(resource_id, resource_version_id, cle_stockage, sha256, mime, taille, deposee_par)
VALUES (current_setting('test.s1')::uuid, current_setting('test.v1')::uuid, 'preuves/essai.pdf',
        repeat('a', 64), 'application/pdf', 64, 'cb000000-0000-4000-8000-0000000000a1');
INSERT INTO public.download_asset(id, resource_version_id, format, cle_stockage, taille_octets, empreinte, origine)
VALUES ('cb000000-0000-4000-8000-000000000091', current_setting('test.v1')::uuid, 'pdf',
        'supports/cb000000-0000-4000-8000-000000000091/1/manuel.pdf', 128, 'sha256:essai', 'importe_tel_quel');
UPDATE public.resource_version SET download_asset_id = 'cb000000-0000-4000-8000-000000000091'
 WHERE id = current_setting('test.v1')::uuid;

-- ------------------------------------------------------------
-- 4. Controle et publication
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $publier$
DECLARE c jsonb; r jsonb; s text := current_setting('test.s1'); v text := current_setting('test.v1');
BEGIN
  c := public.library_controler_version(v::uuid);
  PERFORM pg_temp.vrai(NOT (c ->> 'publiable')::boolean AND jsonb_array_length(c -> 'criteres') = 11
    AND c -> 'criteres' -> 0 = '{"cle": "source", "etat": "bloque"}'::jsonb
    AND c -> 'criteres' -> 7 = '{"cle": "fichierSain", "etat": "valide"}'::jsonb,
    'controle : 11 criteres, droits non revus donc non publiable');
  r := public.library_publier_version(s::uuid, v::uuid, pg_temp.rev(s), 'p-bloque');
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'PublicationBloquee' AND NOT (r -> 'controle' ->> 'publiable')::boolean,
    'publication bloquee tant que le controle ne passe pas');

  r := public.admin_library_review_rights(s::uuid, v::uuid,
         '{"sourceTitre":"Editeur essai","titulaire":"Titulaire essai","preuveFournie":true,
           "usages":["application","classe"],"attribution":"Attribution essai","approuver":true}', pg_temp.rev(s));
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureFaite', 'revue des droits approuvee (RPC existante)');
  c := public.library_controler_version(v::uuid);
  PERFORM pg_temp.vrai((c ->> 'publiable')::boolean, 'controle : publiable apres revue, preuve et fichier');

  r := public.library_publier_version(s::uuid, v::uuid, pg_temp.rev(s) - 1, 'p-conflit');
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'PublicationEnConflit', 'revision perimee : publication en conflit');
  r := public.library_publier_version(s::uuid, v::uuid, pg_temp.rev(s), 'p-ok');
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'VersionPubliee' AND (r ->> 'revision')::int = pg_temp.rev(s),
    'version publiee, revision rendue');
  PERFORM pg_temp.vrai(public.library_publier_version(s::uuid, v::uuid, 1, 'p-ok') = r,
    'meme cle : meme reponse, rien en double');
  PERFORM pg_temp.vrai(jsonb_array_length(public.library_get_catalogue('{"etat":"publies"}') -> 'elements') = 1,
    'catalogue : un support publie');
  PERFORM pg_temp.refus(format($q$SELECT public.library_publier_version(%L, %L, %s, 'p-encore')$q$, s, v, pg_temp.rev(s)),
    '22023', 'une version deja publiee ne se republie pas');
END $publier$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT current_version_id = current_setting('test.v1')::uuid AND access_policy = 'groupe_assigne'
                       FROM public.library_resource WHERE id = current_setting('test.s1')::uuid),
  'publication : pointeur courant et visibilite de classe poses');

-- ------------------------------------------------------------
-- 5. Attribution, nouvelle version, retrait
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($q$SELECT public.library_attribuer(%L, ARRAY['cb000000-0000-4000-8000-0000000000c1']::uuid[], false, %s)$q$,
  current_setting('test.s2'), pg_temp.rev(current_setting('test.s2'))), '42501', 'attribuer un brouillon refuse');
SELECT pg_temp.refus(format($q$SELECT public.library_attribuer(%L, ARRAY['cb000000-0000-4000-8000-0000000000c2']::uuid[], false, %s)$q$,
  current_setting('test.s1'), pg_temp.rev(current_setting('test.s1'))), 'P0002', 'attribuer a une classe cloturee refuse');
DO $attribuer$
DECLARE r jsonb; s text := current_setting('test.s1'); n integer;
BEGIN
  r := public.library_attribuer(s::uuid, ARRAY['cb000000-0000-4000-8000-0000000000c1']::uuid[], true, pg_temp.rev(s) - 1);
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureEnConflit', 'attribution sur revision perimee : conflit');
  r := public.library_attribuer(s::uuid, ARRAY['cb000000-0000-4000-8000-0000000000c1','cb000000-0000-4000-8000-0000000000c1']::uuid[], true, pg_temp.rev(s));
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureFaite', 'attribution faite');
  r := public.library_classes_attribuables(s::uuid);
  PERFORM pg_temp.vrai(jsonb_array_length(r -> 'elements') = 1
    AND r -> 'elements' -> 0 = '{"id": "cb000000-0000-4000-8000-0000000000c1", "libelle": "An-Nour Essai",
                                 "numero": 1, "deja_servie": true, "epinglee": true}'::jsonb
    AND r -> 'curseur' = 'null'::jsonb,
    'classes attribuables : seules les actives, deja servie et epinglee');
  r := public.library_attribuer(s::uuid, ARRAY['cb000000-0000-4000-8000-0000000000c1']::uuid[], true, pg_temp.rev(s));
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureFaite', 'attribution rejouee : idempotente');

  r := public.library_nouvelle_version(s::uuid);
  PERFORM pg_temp.vrai((r ->> 'numero')::int = 2 AND public.library_nouvelle_version(s::uuid) = r,
    'nouvelle version 2 en brouillon, rendue a nouveau sans doublon');

  PERFORM pg_temp.refus(format($q$SELECT public.library_retirer(%L, 'x', %s)$q$, s, pg_temp.rev(s)), '22023', 'retrait sans motif refuse');
  r := public.library_retirer(s::uuid, 'Droits a revoir', pg_temp.rev(s) - 1);
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureEnConflit', 'retrait sur revision perimee : conflit');
  r := public.library_retirer(s::uuid, 'Droits a revoir', pg_temp.rev(s));
  PERFORM pg_temp.vrai(r ->> 'resultat' = 'EcritureFaite', 'retrait fait');
  PERFORM pg_temp.vrai((public.library_retirer(s::uuid, 'Droits a revoir', 1) ->> 'resultat') = 'EcritureFaite',
    'retrait rejoue : sans effet');
  PERFORM pg_temp.vrai(jsonb_array_length(public.library_get_catalogue('{"etat":"retires"}') -> 'elements') = 1
    AND public.library_get_detail(s::uuid) -> 'capacites'
        = '{"peutModifier": false, "peutPublier": false, "peutAttribuer": false, "peutRetirer": false}'::jsonb,
    'support retire : catalogue et capacites suivent');
  PERFORM pg_temp.refus(format($q$SELECT public.library_nouvelle_version(%L)$q$, s), '22023', 'nouvelle version d''un support retire refusee');
END $attribuer$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action IN
  ('library_draft_created','library_version_published','library_assigned','library_withdrawn','library_version_created')) = 7,
  'chaque ecriture est auditee (2 brouillons, 1 publication, 2 attributions, 1 version, 1 retrait)');

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 50 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 50 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CONTRATS bibliotheque : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
