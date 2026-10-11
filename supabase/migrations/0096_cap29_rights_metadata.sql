BEGIN;

ALTER TABLE public.resource_version
  ADD CONSTRAINT resource_version_resource_id_id_key UNIQUE (resource_id, id);

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT USAGE ON SCHEMA private TO postgres;

CREATE TABLE private.library_rights_proofs (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  resource_id uuid NOT NULL
    REFERENCES public.library_resource(id) ON DELETE RESTRICT,
  resource_version_id uuid NOT NULL,
  cle_stockage text NOT NULL CHECK (pg_catalog.btrim(cle_stockage) <> ''),
  sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  mime text NOT NULL CHECK (pg_catalog.btrim(mime) <> ''),
  taille bigint NOT NULL CHECK (taille > 0),
  deposee_par uuid NOT NULL REFERENCES public.profiles(id),
  deposee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'confirmee')),
  UNIQUE (id, resource_version_id),
  FOREIGN KEY (resource_id, resource_version_id)
    REFERENCES public.resource_version(resource_id, id) ON DELETE RESTRICT
);
ALTER TABLE private.library_rights_proofs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.library_rights_proofs
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TABLE public.library_version_rights (
  resource_version_id uuid PRIMARY KEY
    REFERENCES public.resource_version(id) ON DELETE CASCADE,
  source_titre text NOT NULL DEFAULT '',
  titulaire text NOT NULL DEFAULT '',
  preuve_id uuid,
  usages text[] NOT NULL DEFAULT '{}',
  attribution text NOT NULL DEFAULT '',
  expire_le timestamptz,
  approuve boolean NOT NULL DEFAULT false,
  revu_par uuid REFERENCES public.profiles(id),
  revu_le timestamptz,
  CONSTRAINT library_version_rights_usages_valides
    CHECK (usages <@ ARRAY[
      'application', 'classe', 'telechargement', 'hors_ligne'
    ]::text[]),
  CONSTRAINT library_version_rights_revue_complete
    CHECK (NOT approuve OR (
      pg_catalog.btrim(source_titre) <> ''
      AND pg_catalog.btrim(titulaire) <> ''
      AND pg_catalog.btrim(attribution) <> ''
      AND pg_catalog.cardinality(usages) > 0
      AND revu_par IS NOT NULL
      AND revu_le IS NOT NULL
  )),
  CONSTRAINT library_version_rights_proof_same_version
    FOREIGN KEY (preuve_id, resource_version_id)
    REFERENCES private.library_rights_proofs(id, resource_version_id)
    ON DELETE RESTRICT
);
ALTER TABLE public.library_version_rights ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.library_version_rights
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE OR REPLACE FUNCTION public.cap29_guard_resource_version()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.statut = 'brouillon'::public.statut_version_ressource
       AND NEW.statut = 'publiee'::public.statut_version_ressource
       AND NOT EXISTS (
         SELECT 1
         FROM public.library_version_rights r
         WHERE r.resource_version_id = NEW.id
           AND r.approuve
           AND (r.expire_le IS NULL OR r.expire_le > pg_catalog.now())
           AND pg_catalog.cardinality(r.usages) > 0
           AND (r.preuve_id IS NULL OR EXISTS (
             SELECT 1 FROM private.library_rights_proofs p
             WHERE p.id = r.preuve_id
               AND p.resource_version_id = NEW.id
               AND p.statut = 'confirmee'
           ))
       ) THEN
      RAISE EXCEPTION 'CAP29: droits absents, non approuves ou expires'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.statut <> 'brouillon'
       OR NEW.publiee_le IS NOT NULL
       OR NEW.publiee_par IS NOT NULL THEN
      RAISE EXCEPTION 'CAP-29: une version doit commencer en brouillon'
        USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.statut <> 'brouillon' THEN
      RAISE EXCEPTION 'CAP-29: une version publiee ou archivee ne se supprime pas'
        USING ERRCODE = '23514';
    END IF;
    RETURN OLD;
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.resource_id IS DISTINCT FROM OLD.resource_id
     OR NEW.numero_version IS DISTINCT FROM OLD.numero_version THEN
    RAISE EXCEPTION 'CAP-29: identite de version immuable'
      USING ERRCODE = '23514';
  END IF;
  IF OLD.statut = 'brouillon'
     AND NEW.statut = 'publiee' THEN
    IF auth.uid() IS NULL THEN
      RAISE EXCEPTION 'CAP-29: publication requiert un utilisateur authentifie'
        USING ERRCODE = '42501';
    END IF;
    NEW.publiee_le := pg_catalog.clock_timestamp();
    NEW.publiee_par := auth.uid();
    RETURN NEW;
  END IF;
  IF OLD.statut = 'brouillon'
     AND NEW.statut = 'brouillon'
     AND NEW.publiee_le IS NULL AND NEW.publiee_par IS NULL THEN
    RETURN NEW;
  END IF;
  IF OLD.statut = 'publiee'
     AND NEW.statut = 'archivee'
     AND ROW(NEW.id, NEW.resource_id, NEW.numero_version, NEW.publiee_le,
             NEW.publiee_par, NEW.download_asset_id, NEW.empreinte)
         IS NOT DISTINCT FROM
         ROW(OLD.id, OLD.resource_id, OLD.numero_version, OLD.publiee_le,
             OLD.publiee_par, OLD.download_asset_id, OLD.empreinte) THEN
    RETURN NEW;
  END IF;
  IF NEW.statut = OLD.statut
     AND ROW(NEW.id, NEW.resource_id, NEW.numero_version, NEW.publiee_le,
             NEW.publiee_par, NEW.download_asset_id, NEW.empreinte)
         IS NOT DISTINCT FROM
         ROW(OLD.id, OLD.resource_id, OLD.numero_version, OLD.publiee_le,
             OLD.publiee_par, OLD.download_asset_id, OLD.empreinte) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'CAP-29: version publiee ou archivee immuable'
    USING ERRCODE = '23514';
END;
$function$;
REVOKE ALL ON FUNCTION public.cap29_guard_resource_version()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
          WHERE c.oid = 'private.library_rights_proofs'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
             WHERE c.oid = 'public.library_version_rights'::regclass)
     OR has_table_privilege('anon', 'private.library_rights_proofs', 'SELECT')
     OR has_table_privilege('authenticated', 'private.library_rights_proofs', 'SELECT')
     OR has_table_privilege('service_role', 'private.library_rights_proofs', 'SELECT')
     OR has_schema_privilege('anon', 'private', 'USAGE')
     OR has_schema_privilege('authenticated', 'private', 'USAGE')
     OR has_schema_privilege('service_role', 'private', 'USAGE')
     OR has_table_privilege('authenticated', 'private.library_rights_proofs', 'INSERT')
     OR has_table_privilege('authenticated', 'private.library_rights_proofs', 'UPDATE')
     OR has_table_privilege('authenticated', 'private.library_rights_proofs', 'DELETE')
     OR has_table_privilege('anon', 'public.library_version_rights', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.library_version_rights', 'SELECT')
     OR has_table_privilege('authenticated', 'public.library_version_rights', 'INSERT')
     OR has_table_privilege('authenticated', 'public.library_version_rights', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.library_version_rights', 'DELETE')
     OR has_table_privilege('service_role', 'public.library_version_rights', 'SELECT')
     OR EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.cap29_assert_published_resource_version()'::regprocedure
         AND p.prosecdef
     ) THEN
    RAISE EXCEPTION 'CAP29 rights schema postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
