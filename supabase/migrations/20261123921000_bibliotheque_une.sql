-- LOT 3 · BIBLIOTHEQUE-UNE, fichier 2 sur 2 (12/11/2026).
--
-- A INSTALLER APRES 20261123920000_bibliotheque_une_types.sql, dans une
-- EXECUTION SEPAREE : ce fichier lit les trois valeurs d'enum que l'autre
-- ajoute, et une valeur d'enum ajoutee n'est employable qu'une fois sa
-- transaction validee.
--
-- FICHIER SANS MOT D'EFFACEMENT NI DE SUPPRESSION D'OBJET : additif. Il
-- remplace six fonctions existantes par `CREATE OR REPLACE` a signature
-- identique (n4_manifeste, bibliotheque_catalogue_lecteur, library_controle_version,
-- library_creer_brouillon, library_mettre_a_jour, library_get_detail) ; il en
-- cree sept (dont trois lectures du lecteur) et deux tables.
--
-- Ce qu'il fait (BIBLIOTHEQUE-UNE, charte partie 11) :
--   1. Deux rayons, EN DONNEE : library_rayon (« Documents des cours » et
--      « Pour aller plus loin », fr et ar). Aucune colonne de prix : le second
--      rayon est une place, rien de plus (decision du directeur du 12/11/2026).
--   2. library_resource porte maintenant un rayon, un ordre d'affichage, un lien
--      externe (https, valide par la base), une cle de vignette et des etapes
--      rattachees PAR CODE STABLE (texte, aucune cle etrangere vers une version
--      du programme : une etape garde son code d'une version a l'autre).
--      La description existe deja (20261016102100) : elle sert de description
--      de carte.
--   3. La vignette se depose par une intention a deux temps, comme le fichier
--      d'un document (confirmation signee par l'Edge) ; sa cle ne quitte jamais
--      le serveur sans passer par `bibliotheque_vignettes_autorisees`, et c'est
--      la fonction Edge `bibliotheque-lecture` qui signe l'URL.
--   4. La lecture du lecteur (eleve, tuteur, enseignant) est ETENDUE, pas
--      doublee : bibliotheque_catalogue_lecteur garde sa signature et ses
--      reponses, et ajoute les filtres rayon, etape, classe et un decalage de
--      pagination ; son manifeste rend description, vignette (indicateur),
--      rayon, ordre, etapes et lien externe. Aucune cle de stockage.
--   5. Le Coran est un document du rayon « Documents des cours », seme ici,
--      publie, visible des inscrits ; il s'ouvre sur le lecteur du Coran.
--   6. La direction depose et publie tous ces types par les ecritures
--      existantes, etendues (brouillon, mise a jour, controle, detail).
--
-- Tests : supabase/tests/scenarios_bibliotheque_une.sql.

-- ---------------------------------------------------------------------------
-- 1. Les rayons, en donnee
-- ---------------------------------------------------------------------------
CREATE TABLE public.library_rayon (
  code text PRIMARY KEY CHECK (code ~ '^[a-z][a-z0-9_]{1,31}$'),
  titre_fr text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(titre_fr)) BETWEEN 1 AND 80),
  titre_ar text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(titre_ar)) BETWEEN 1 AND 80),
  ordre integer NOT NULL CHECK (ordre BETWEEN 1 AND 99),
  UNIQUE (ordre)
);
ALTER TABLE public.library_rayon ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.library_rayon FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON TABLE public.library_rayon TO authenticated;
CREATE POLICY library_rayon_lecture ON public.library_rayon
  FOR SELECT TO authenticated USING (public.app_account_valid());
COMMENT ON TABLE public.library_rayon IS
  'BIBLIOTHEQUE-UNE : les rayons de la Bibliotheque, en donnee. Aucun prix : le second rayon est une place preparee (directeur, 12/11/2026).';

INSERT INTO public.library_rayon (code, titre_fr, titre_ar, ordre) VALUES
  ('cours', 'Documents des cours', 'وثائق الدروس', 1),
  ('plus_loin', 'Pour aller plus loin', 'للتعمّق أكثر', 2)
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Ce que porte un document
-- ---------------------------------------------------------------------------
ALTER TABLE public.library_resource
  ADD COLUMN rayon text NOT NULL DEFAULT 'cours' REFERENCES public.library_rayon(code),
  ADD COLUMN ordre integer NOT NULL DEFAULT 0 CHECK (ordre BETWEEN 0 AND 100000),
  ADD COLUMN lien_externe text,
  ADD COLUMN vignette_cle text,
  ADD COLUMN etapes text[] NOT NULL DEFAULT '{}';

-- Un lien externe est une URL https dont l'hote est un nom de domaine (pas une
-- adresse IP, pas d'identifiants devant l'hote), sans espace ni guillemet.
ALTER TABLE public.library_resource
  ADD CONSTRAINT library_resource_lien_https CHECK (
    lien_externe IS NULL OR (
      pg_catalog.length(lien_externe) <= 2000
      AND lien_externe ~* '^https://[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{1,5})?([/?#][^[:space:]<>"''\\]*)?$'
      AND lien_externe !~* '^https://[0-9.]+([:/?#]|$)'
    )
  ),
  -- Un lien n'a de sens que pour un lien externe ou une video par lien ;
  -- un lien externe en exige un et sa description.
  ADD CONSTRAINT library_resource_lien_selon_type CHECK (
    lien_externe IS NULL OR resource_type::text IN ('external_link', 'video')
  ),
  ADD CONSTRAINT library_resource_lien_requis CHECK (
    resource_type::text <> 'external_link' OR lien_externe IS NOT NULL
  ),
  ADD CONSTRAINT library_resource_lien_description CHECK (
    resource_type::text <> 'external_link'
    OR pg_catalog.length(pg_catalog.btrim(coalesce(description, ''))) > 0
  ),
  ADD CONSTRAINT library_resource_vignette_cle_forme CHECK (
    vignette_cle IS NULL OR vignette_cle ~ '^supports/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[1-9][0-9]{0,8}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'
  ),
  ADD CONSTRAINT library_resource_etapes_forme CHECK (
    pg_catalog.cardinality(etapes) <= 20
    AND pg_catalog.array_to_string(etapes, ',') ~ '^([A-Za-z0-9][A-Za-z0-9_.-]{0,63}(,[A-Za-z0-9][A-Za-z0-9_.-]{0,63})*)?$'
  );

CREATE INDEX library_resource_rayon_ordre_idx
  ON public.library_resource (rayon, ordre, title);
CREATE INDEX library_resource_etapes_idx
  ON public.library_resource USING gin (etapes);

-- ---------------------------------------------------------------------------
-- 3. Aides internes (aucun EXECUTE client)
-- ---------------------------------------------------------------------------
-- Les etapes saisies : un tableau JSON de codes, normalise (sans doublon, trie).
CREATE FUNCTION app_private.library_etapes_normalisees(p_valeur jsonb)
RETURNS text[]
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_codes text[];
BEGIN
  IF p_valeur IS NULL OR pg_catalog.jsonb_typeof(p_valeur) = 'null' THEN
    RETURN '{}'::text[];
  END IF;
  IF pg_catalog.jsonb_typeof(p_valeur) <> 'array'
     OR pg_catalog.jsonb_array_length(p_valeur) > 20
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p_valeur) e
                 WHERE pg_catalog.jsonb_typeof(e.value) <> 'string') THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(DISTINCT pg_catalog.btrim(e.value) ORDER BY pg_catalog.btrim(e.value)), '{}'::text[])
    INTO v_codes
    FROM pg_catalog.jsonb_array_elements_text(p_valeur) e(value);
  IF EXISTS (SELECT 1 FROM pg_catalog.unnest(v_codes) c
              WHERE c !~ '^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$') THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  RETURN v_codes;
END;
$function$;
REVOKE ALL ON FUNCTION app_private.library_etapes_normalisees(jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le controle d'une version avant publication, etendu : un document sans
-- fichier mais avec un lien (lien externe, video par lien) n'a ni fichier a
-- sonder ni empreinte a exiger, et n'a pas a prouver un droit de diffusion
-- d'un contenu qu'il ne diffuse pas ; un rattachement a une etape vaut
-- rattachement au programme (critere 10) autant qu'un niveau.
CREATE OR REPLACE FUNCTION app_private.library_controle_version(p_version_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  WITH base AS (
    SELECT v.id, v.empreinte, r.level_scope, r.etapes, r.language,
           (r.lien_externe IS NOT NULL) AS par_lien,
           (r.resource_type::text = 'external_link') AS lien_pur,
           d.approuve, d.source_titre, d.titulaire, d.preuve_id, d.usages, d.expire_le,
           a.id AS asset_id, a.empreinte AS asset_empreinte,
           (d.preuve_id IS NOT NULL AND EXISTS (
              SELECT 1 FROM private.library_rights_proofs p
               WHERE p.id = d.preuve_id AND p.statut IN ('en_attente', 'confirmee'))) AS preuve
    FROM public.resource_version v
    JOIN public.library_resource r ON r.id = v.resource_id
    LEFT JOIN public.library_version_rights d ON d.resource_version_id = v.id
    LEFT JOIN public.download_asset a ON a.id = v.download_asset_id
    WHERE v.id = p_version_id
  ), criteres AS (
    SELECT c.rang, c.cle, CASE WHEN c.ok THEN 'valide' WHEN c.ok IS NULL THEN 'inconnu' ELSE 'bloque' END AS etat
    FROM base b
    CROSS JOIN LATERAL (VALUES
      (1, 'source', coalesce(pg_catalog.btrim(b.source_titre), '') <> ''),
      (2, 'titulaire', coalesce(pg_catalog.btrim(b.titulaire), '') <> ''),
      (3, 'preuve', b.preuve OR b.lien_pur),
      (4, 'usageApplication', coalesce('application' = ANY (b.usages), false)),
      (5, 'usageClasse', coalesce('classe' = ANY (b.usages), false)),
      (6, 'usageTelechargement', true),
      (7, 'expirationAttribution', b.expire_le IS NULL OR b.expire_le > pg_catalog.now()),
      (8, 'fichierSain', b.asset_id IS NOT NULL OR b.par_lien),
      (9, 'renduTeste', CASE WHEN b.asset_id IS NOT NULL OR b.par_lien THEN true END),
      (10, 'langueNiveau', coalesce(pg_catalog.btrim(b.language), '') <> ''
                           AND (coalesce(pg_catalog.cardinality(b.level_scope), 0) > 0
                                OR coalesce(pg_catalog.cardinality(b.etapes), 0) > 0)),
      (11, 'versionEmpreinte', coalesce(b.empreinte, b.asset_empreinte) IS NOT NULL OR b.par_lien)
    ) AS c(rang, cle, ok)
  )
  SELECT pg_catalog.jsonb_build_object(
    'criteres', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('cle', c.cle, 'etat', c.etat)
                                                       ORDER BY c.rang) FROM criteres c), '[]'::jsonb),
    'publiable', coalesce((SELECT b.approuve FROM base b), false)
                 AND EXISTS (SELECT 1 FROM base)
                 AND NOT EXISTS (SELECT 1 FROM criteres c WHERE c.etat <> 'valide'));
$function$;

-- ---------------------------------------------------------------------------
-- 4. Les ecritures de la direction, etendues
-- ---------------------------------------------------------------------------
-- Creer un brouillon : ajoute description, rayon, ordre, lien externe et
-- etapes aux cinq cles d'origine. Rend {id, version_id, revision}.
CREATE OR REPLACE FUNCTION public.library_creer_brouillon(p_saisie jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_titre text;
  v_type text;
  v_langue text;
  v_categorie text;
  v_niveau text;
  v_description text;
  v_rayon text;
  v_ordre integer := 0;
  v_lien text;
  v_etapes text[];
  v_id uuid;
  v_version uuid;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_saisie IS NULL OR pg_catalog.jsonb_typeof(p_saisie) <> 'object'
     OR (p_saisie - ARRAY['titre', 'type', 'langue', 'categorie', 'niveau', 'description',
                          'rayon', 'ordre', 'lienExterne', 'etapes']) <> '{}'::jsonb THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_saisie - ARRAY['etapes', 'ordre']) e
              WHERE pg_catalog.jsonb_typeof(e.value) NOT IN ('string', 'null'))
     OR (p_saisie ? 'ordre' AND pg_catalog.jsonb_typeof(p_saisie -> 'ordre') NOT IN ('number', 'null')) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  v_titre := pg_catalog.btrim(coalesce(p_saisie ->> 'titre', ''));
  v_type := p_saisie ->> 'type';
  v_langue := pg_catalog.btrim(coalesce(p_saisie ->> 'langue', ''));
  v_categorie := pg_catalog.btrim(coalesce(p_saisie ->> 'categorie', ''));
  v_niveau := nullif(pg_catalog.btrim(coalesce(p_saisie ->> 'niveau', '')), '');
  v_description := nullif(pg_catalog.btrim(coalesce(p_saisie ->> 'description', '')), '');
  v_rayon := coalesce(nullif(pg_catalog.btrim(coalesce(p_saisie ->> 'rayon', '')), ''), 'cours');
  v_lien := nullif(pg_catalog.btrim(coalesce(p_saisie ->> 'lienExterne', '')), '');
  IF p_saisie ? 'ordre' AND pg_catalog.jsonb_typeof(p_saisie -> 'ordre') = 'number' THEN
    IF (p_saisie ->> 'ordre') !~ '^[0-9]{1,6}$' THEN
      RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
    END IF;
    v_ordre := (p_saisie ->> 'ordre')::integer;
  END IF;
  v_etapes := app_private.library_etapes_normalisees(p_saisie -> 'etapes');
  IF pg_catalog.length(v_titre) NOT BETWEEN 1 AND 200
     OR pg_catalog.length(v_langue) NOT BETWEEN 2 AND 16
     OR pg_catalog.length(v_categorie) > 80
     OR coalesce(pg_catalog.length(v_niveau), 0) > 80
     OR v_type IS NULL OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_enum e
       JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
       JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
       WHERE n.nspname = 'public' AND t.typname = 'library_resource_type' AND e.enumlabel = v_type)
     OR NOT EXISTS (SELECT 1 FROM public.library_rayon y WHERE y.code = v_rayon) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  BEGIN
    INSERT INTO public.library_resource
      (title, short_title, resource_type, language, category, level_scope, access_policy, offline_policy,
       description, rayon, ordre, lien_externe, etapes)
    VALUES (v_titre, pg_catalog.left(v_titre, 60), v_type::public.library_resource_type, v_langue,
            v_categorie, CASE WHEN v_niveau IS NULL THEN '{}'::text[] ELSE ARRAY[v_niveau] END,
            'admin', 'jamais', v_description, v_rayon, v_ordre, v_lien, v_etapes)
    RETURNING id, revision INTO v_id, v_revision;
  EXCEPTION WHEN check_violation OR string_data_right_truncation THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END;
  INSERT INTO public.resource_version (resource_id, numero_version, statut)
  VALUES (v_id, 1, 'brouillon') RETURNING id INTO v_version;

  PERFORM public.log_sensitive_access('library_draft_created', 'library_resource', v_id::text,
    pg_catalog.jsonb_build_object('resource_version_id', v_version));
  RETURN pg_catalog.jsonb_build_object('id', v_id, 'version_id', v_version, 'revision', v_revision);
END;
$function$;

-- Modifier la fiche : ajoute rayon, ordre, lien externe, etapes, et le retrait
-- de la vignette (`vignette: null`) aux huit cles d'origine.
CREATE OR REPLACE FUNCTION public.library_mettre_a_jour(
  p_resource_id uuid, p_modification jsonb, p_revision_attendue integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_titre text;
  v_court text;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_modification IS NULL OR pg_catalog.jsonb_typeof(p_modification) <> 'object'
     OR (p_modification - ARRAY['titre', 'titreCourt', 'edition', 'organisme', 'description',
                                'conditionsAttribution', 'visibilite', 'politiqueHorsLigne',
                                'rayon', 'ordre', 'lienExterne', 'etapes', 'vignette']) <> '{}'::jsonb
     OR p_revision_attendue IS NULL THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_modification - ARRAY['etapes', 'ordre']) e
              WHERE pg_catalog.jsonb_typeof(e.value) NOT IN ('string', 'null'))
     OR (p_modification ? 'ordre' AND pg_catalog.jsonb_typeof(p_modification -> 'ordre') <> 'number')
     OR (p_modification ? 'ordre' AND (p_modification ->> 'ordre') !~ '^[0-9]{1,6}$')
     OR (p_modification ? 'vignette' AND pg_catalog.jsonb_typeof(p_modification -> 'vignette') <> 'null')
     OR (p_modification ? 'rayon' AND (pg_catalog.jsonb_typeof(p_modification -> 'rayon') <> 'string'
         OR NOT EXISTS (SELECT 1 FROM public.library_rayon y WHERE y.code = p_modification ->> 'rayon'))) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeRetiree' USING ERRCODE = '22023';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureEnConflit', 'revision', v_resource.revision);
  END IF;

  v_titre := CASE WHEN p_modification ? 'titre'
                  THEN pg_catalog.btrim(coalesce(p_modification ->> 'titre', ''))
                  ELSE v_resource.title END;
  IF pg_catalog.length(v_titre) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  v_court := CASE WHEN p_modification ? 'titreCourt'
                  THEN coalesce(nullif(pg_catalog.btrim(coalesce(p_modification ->> 'titreCourt', '')), ''),
                                pg_catalog.left(v_titre, 60))
                  ELSE v_resource.short_title END;
  IF pg_catalog.length(v_court) > 60 THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  IF (p_modification ? 'visibilite' AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_enum e
        JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typname = 'library_access_policy'
          AND e.enumlabel = p_modification ->> 'visibilite'))
     OR (p_modification ? 'politiqueHorsLigne' AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_enum e
        JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typname = 'library_offline_policy'
          AND e.enumlabel = p_modification ->> 'politiqueHorsLigne')) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  BEGIN
    UPDATE public.library_resource r SET
      title = v_titre,
      short_title = v_court,
      edition = CASE WHEN p_modification ? 'edition'
                     THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'edition', '')), '')
                     ELSE r.edition END,
      organisme = CASE WHEN p_modification ? 'organisme'
                       THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'organisme', '')), '')
                       ELSE r.organisme END,
      description = CASE WHEN p_modification ? 'description'
                         THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'description', '')), '')
                         ELSE r.description END,
      conditions_attribution = CASE WHEN p_modification ? 'conditionsAttribution'
                         THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'conditionsAttribution', '')), '')
                         ELSE r.conditions_attribution END,
      access_policy = CASE WHEN p_modification ? 'visibilite'
                           THEN (p_modification ->> 'visibilite')::public.library_access_policy
                           ELSE r.access_policy END,
      offline_policy = CASE WHEN p_modification ? 'politiqueHorsLigne'
                            THEN (p_modification ->> 'politiqueHorsLigne')::public.library_offline_policy
                            ELSE r.offline_policy END,
      rayon = CASE WHEN p_modification ? 'rayon' THEN p_modification ->> 'rayon' ELSE r.rayon END,
      ordre = CASE WHEN p_modification ? 'ordre' THEN (p_modification ->> 'ordre')::integer ELSE r.ordre END,
      lien_externe = CASE WHEN p_modification ? 'lienExterne'
                          THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'lienExterne', '')), '')
                          ELSE r.lien_externe END,
      etapes = CASE WHEN p_modification ? 'etapes'
                    THEN app_private.library_etapes_normalisees(p_modification -> 'etapes')
                    ELSE r.etapes END,
      vignette_cle = CASE WHEN p_modification ? 'vignette' THEN NULL ELSE r.vignette_cle END
     WHERE r.id = p_resource_id
    RETURNING r.revision INTO v_revision;
  EXCEPTION WHEN check_violation OR string_data_right_truncation THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END;

  PERFORM public.log_sensitive_access('library_resource_draft_updated', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('champs', (SELECT pg_catalog.array_agg(k.cle ORDER BY k.cle)
                                               FROM pg_catalog.jsonb_object_keys(p_modification) AS k(cle))));
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_revision);
END;
$function$;

-- La fiche de la direction : le corps d'origine (20261016102100) et, dans
-- `support`, rayon, ordre, lienExterne, etapes et vignette (indicateur).
CREATE OR REPLACE FUNCTION public.library_get_detail(p_resource_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_versions jsonb;
  v_rights jsonb;
  v_history jsonb;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin', false
  ) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT r.* INTO v_resource
    FROM public.library_resource r
   WHERE r.id = p_resource_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', v.id,
    'numeroVersion', v.numero_version,
    'statut', v.statut::text,
    'publieeLeUtc', v.publiee_le,
    'empreinte', v.empreinte,
    'droits', CASE WHEN d.resource_version_id IS NULL THEN NULL ELSE
      pg_catalog.jsonb_build_object(
        'sourceTitre', d.source_titre,
        'titulaire', d.titulaire,
        'preuveFournie', d.preuve_id IS NOT NULL,
        'preuveStatut', p.statut,
        'preuveMime', p.mime,
        'preuveTaille', p.taille,
        'preuveSha256', p.sha256,
        'usages', d.usages,
        'attribution', d.attribution,
        'expireLeUtc', d.expire_le,
        'approuve', d.approuve,
        'revuLeUtc', d.revu_le
      ) END
  ) ORDER BY v.numero_version DESC), '[]'::jsonb),
  coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'versionId', d.resource_version_id,
    'sourceTitre', d.source_titre,
    'titulaire', d.titulaire,
    'preuveFournie', d.preuve_id IS NOT NULL,
    'preuveStatut', p.statut,
    'preuveMime', p.mime,
    'preuveTaille', p.taille,
    'preuveSha256', p.sha256,
    'usages', d.usages,
    'attribution', d.attribution,
    'expireLeUtc', d.expire_le,
    'approuve', d.approuve,
    'revuLeUtc', d.revu_le
  ) ORDER BY v.numero_version DESC) FILTER (WHERE d.resource_version_id IS NOT NULL), '[]'::jsonb)
  INTO v_versions, v_rights
  FROM public.resource_version v
  LEFT JOIN public.library_version_rights d ON d.resource_version_id = v.id
  LEFT JOIN private.library_rights_proofs p
    ON p.id = d.preuve_id AND p.resource_version_id = v.id
  WHERE v.resource_id = p_resource_id;

  SELECT coalesce(pg_catalog.jsonb_agg(x.entree ORDER BY x.created_at DESC), '[]'::jsonb)
    INTO v_history
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'action', a.action,
        'creeLeUtc', a.created_at
      ) AS entree, a.created_at
        FROM public.audit_logs a
       WHERE a.table_name = 'library_resource'
         AND a.row_id = p_resource_id::text
         AND a.action IN (
           'library_resource_draft_created', 'library_resource_draft_updated',
           'library_rights_review', 'library_version_published',
           'library_resource_withdrawn', 'library_groups_assigned'
         )
       ORDER BY a.created_at DESC, a.id DESC
       LIMIT 100
    ) x;

  PERFORM public.log_sensitive_access(
    'library_resource_detail_read', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('resource_id', p_resource_id)
  );

  RETURN pg_catalog.jsonb_build_object(
    'support', pg_catalog.jsonb_build_object(
      'id', v_resource.id,
      'titre', v_resource.title,
      'titreCourt', v_resource.short_title,
      'type', v_resource.resource_type::text,
      'edition', v_resource.edition,
      'langue', v_resource.language,
      'categorie', v_resource.category,
      'niveaux', v_resource.level_scope,
      'politiqueAcces', v_resource.access_policy::text,
      'politiqueHorsLigne', v_resource.offline_policy::text,
      'capacitesContenu', v_resource.capabilities,
      'retire', v_resource.archived_at IS NOT NULL,
      'retireLeUtc', v_resource.archived_at,
      'versionCouranteId', v_resource.current_version_id,
      'modifieLeUtc', v_resource.updated_at,
      'organisme', v_resource.organisme,
      'description', v_resource.description,
      'conditionsAttribution', v_resource.conditions_attribution,
      'rayon', v_resource.rayon,
      'ordre', v_resource.ordre,
      'lienExterne', v_resource.lien_externe,
      'etapes', v_resource.etapes,
      'vignette', v_resource.vignette_cle IS NOT NULL
    ),
    'revision', v_resource.revision,
    'versions', v_versions,
    'droits', v_rights,
    'historique', v_history,
    'capacites', pg_catalog.jsonb_build_object(
      'peutModifier', v_resource.archived_at IS NULL,
      'peutPublier', v_resource.archived_at IS NULL,
      'peutAttribuer', v_resource.archived_at IS NULL AND v_resource.current_version_id IS NOT NULL,
      'peutRetirer', v_resource.archived_at IS NULL
    )
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. La vignette : une intention a deux temps (comme le fichier d'un document)
-- ---------------------------------------------------------------------------
CREATE TABLE private.library_vignette_intentions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  resource_id uuid NOT NULL REFERENCES public.library_resource(id),
  requested_by uuid NOT NULL REFERENCES public.profiles(id),
  mime_annonce text NOT NULL CHECK (mime_annonce IN ('image/png', 'image/jpeg', 'image/webp')),
  taille_annonce bigint NOT NULL CHECK (taille_annonce BETWEEN 1 AND 2097152),
  sha256_annonce text NOT NULL CHECK (sha256_annonce ~ '^[0-9a-f]{64}$'),
  cle_temporaire text NOT NULL UNIQUE,
  cle_finale text NOT NULL UNIQUE,
  cible_id uuid NOT NULL UNIQUE,
  expire_le timestamptz NOT NULL,
  etat text NOT NULL DEFAULT 'attente' CHECK (etat IN ('attente', 'confirmee', 'annulee')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  confirmee_le timestamptz
);
ALTER TABLE private.library_vignette_intentions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.library_vignette_intentions
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.demander_vignette_bibliotheque(
  p_resource_id uuid,
  p_mime text,
  p_taille bigint,
  p_sha256 text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_intention_id uuid := pg_catalog.gen_random_uuid();
  v_cible_id uuid := pg_catalog.gen_random_uuid();
  v_mime text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_mime, '')));
  v_ext text;
  v_cle_finale text;
  v_expire_le timestamptz := pg_catalog.clock_timestamp() + interval '15 minutes';
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  v_ext := CASE v_mime WHEN 'image/png' THEN 'png' WHEN 'image/jpeg' THEN 'jpg' WHEN 'image/webp' THEN 'webp' END;
  IF p_resource_id IS NULL OR v_ext IS NULL
     OR p_sha256 IS NULL OR p_sha256 !~ '^[0-9a-f]{64}$'
     OR p_taille IS NULL OR p_taille NOT BETWEEN 1 AND 2097152 THEN
    RAISE EXCEPTION 'BibliothequeUploadParametresInvalides' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.library_resource r
                  WHERE r.id = p_resource_id AND r.archived_at IS NULL) THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  v_cle_finale := 'supports/' || v_cible_id::text || '/1/vignette.' || v_ext;
  INSERT INTO private.library_vignette_intentions (
    id, resource_id, requested_by, mime_annonce, taille_annonce, sha256_annonce,
    cle_temporaire, cle_finale, cible_id, expire_le
  ) VALUES (
    v_intention_id, p_resource_id, auth.uid(), v_mime, p_taille, p_sha256,
    'private/libraryupload/' || v_intention_id::text, v_cle_finale, v_cible_id, v_expire_le
  );
  RETURN pg_catalog.jsonb_build_object(
    'id', v_intention_id,
    'cle_temporaire', 'private/libraryupload/' || v_intention_id::text,
    'cle_finale', v_cle_finale, 'cible_id', v_cible_id, 'resource_id', p_resource_id,
    'mime', v_mime, 'taille', p_taille, 'expire_le', v_expire_le
  );
END;
$function$;

CREATE FUNCTION public.lire_vignette_bibliotheque(p_intention_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_intention private.library_vignette_intentions%ROWTYPE;
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_intention FROM private.library_vignette_intentions i
   WHERE i.id = p_intention_id AND i.requested_by = auth.uid();
  IF NOT FOUND OR v_intention.etat <> 'attente'
     OR v_intention.expire_le <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'BibliothequeUploadIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_intention.id, 'resource_id', v_intention.resource_id,
    'mime', v_intention.mime_annonce, 'taille', v_intention.taille_annonce,
    'sha256', v_intention.sha256_annonce, 'cle_temporaire', v_intention.cle_temporaire,
    'cle_finale', v_intention.cle_finale, 'cible_id', v_intention.cible_id,
    'expire_le', v_intention.expire_le
  );
END;
$function$;

CREATE FUNCTION public.confirmer_vignette_bibliotheque(
  p_intention_id uuid,
  p_mime_reel text,
  p_taille_reelle bigint,
  p_sha256_reel text,
  p_confirmation_signature text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_intention private.library_vignette_intentions%ROWTYPE;
  v_empreinte text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_sha256_reel, '')));
  v_signature text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_confirmation_signature, '')));
  v_secret text;
  v_attendue text;
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT s.secret INTO v_secret
    FROM private.library_upload_confirmation_secrets s
   WHERE s.singleton
   FOR SHARE;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 32
     OR v_signature !~ '^[0-9a-f]{64}$'
     OR p_taille_reelle IS NULL OR p_taille_reelle <= 0
     OR v_empreinte !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'BibliothequeUploadConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;
  v_attendue := pg_catalog.encode(
    extensions.hmac(
      pg_catalog.convert_to(p_intention_id::text || E'\n' || v_empreinte || E'\n' || p_taille_reelle::text, 'UTF8'),
      pg_catalog.convert_to(v_secret, 'UTF8'),
      'sha256'
    ),
    'hex'
  );
  IF v_signature IS DISTINCT FROM v_attendue THEN
    RAISE EXCEPTION 'BibliothequeUploadConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_intention FROM private.library_vignette_intentions i
   WHERE i.id = p_intention_id AND i.requested_by = auth.uid() FOR UPDATE;
  IF NOT FOUND OR v_intention.etat <> 'attente'
     OR v_intention.expire_le <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'BibliothequeUploadIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  IF p_mime_reel IS NULL
     OR pg_catalog.lower(pg_catalog.btrim(p_mime_reel)) <> v_intention.mime_annonce
     OR p_taille_reelle <> v_intention.taille_annonce
     OR v_empreinte <> v_intention.sha256_annonce THEN
    RAISE EXCEPTION 'BibliothequeUploadContenuInvalide' USING ERRCODE = '22023';
  END IF;

  UPDATE public.library_resource r SET vignette_cle = v_intention.cle_finale
   WHERE r.id = v_intention.resource_id AND r.archived_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  UPDATE private.library_vignette_intentions
     SET etat = 'confirmee', confirmee_le = pg_catalog.clock_timestamp()
   WHERE id = v_intention.id;
  PERFORM public.log_sensitive_access('library_vignette_set', 'library_resource',
    v_intention.resource_id::text, pg_catalog.jsonb_build_object('intention_id', v_intention.id));
  RETURN pg_catalog.jsonb_build_object('etat', 'pret', 'resource_id', v_intention.resource_id);
END;
$function$;

CREATE FUNCTION public.annuler_vignette_bibliotheque(p_intention_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  UPDATE private.library_vignette_intentions SET etat = 'annulee'
   WHERE id = p_intention_id AND requested_by = auth.uid() AND etat = 'attente';
  RETURN FOUND;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Les lectures du lecteur (eleve, tuteur, enseignant)
-- ---------------------------------------------------------------------------
-- Le manifeste : les cles d'origine (LibraryResource.depuisJson) et, en plus,
-- description, lien_externe, ordre, rayon, etapes, vignette (indicateur, jamais
-- la cle de stockage). Aucune colonne de prix n'existe ; aucune n'est rendue.
CREATE OR REPLACE FUNCTION private.n4_manifeste(p_resource_id uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', r.id, 'title', r.title, 'short_title', r.short_title,
    'cover_asset', r.cover_asset, 'resource_type', r.resource_type::text,
    'edition', r.edition, 'language', r.language, 'category', r.category,
    'level_scope', pg_catalog.to_jsonb(r.level_scope),
    'access_policy', r.access_policy::text, 'offline_policy', r.offline_policy::text,
    'current_version_id', r.current_version_id,
    'capabilities', pg_catalog.to_jsonb(r.capabilities),
    'description', r.description,
    'lien_externe', r.lien_externe,
    'ordre', r.ordre,
    'rayon', pg_catalog.jsonb_build_object(
      'code', y.code, 'titre_fr', y.titre_fr, 'titre_ar', y.titre_ar, 'ordre', y.ordre),
    'etapes', pg_catalog.to_jsonb(r.etapes),
    'vignette', r.vignette_cle IS NOT NULL)
    FROM public.library_resource r
    JOIN public.library_rayon y ON y.code = r.rayon
   WHERE r.id = p_resource_id;
$function$;

-- La lecture du catalogue pour le lecteur : meme signature, memes reponses
-- pour les anciens filtres ; en plus les filtres `rayon`, `etape` (code
-- stable), `classe` (une classe de l'appelant ; une autre rend une liste vide,
-- sans rien reveler) et `decalage` (pagination : page suivante = decalage +
-- limite). Ordre : rayon, ordre d'affichage, titre.
CREATE OR REPLACE FUNCTION public.bibliotheque_catalogue_lecteur(
  p_filtre jsonb DEFAULT '{}'::jsonb, p_limite integer DEFAULT 100
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_types text[];
  v_langue text := p_filtre ->> 'langue';
  v_categorie text := p_filtre ->> 'categorie';
  v_niveau text := p_filtre ->> 'niveau';
  v_rayon text := p_filtre ->> 'rayon';
  v_etape text := p_filtre ->> 'etape';
  v_recherche text := nullif(pg_catalog.btrim(p_filtre ->> 'recherche'), '');
  v_id uuid;
  v_classe uuid;
  v_decalage integer := 0;
  v_classe_permise boolean;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_filtre IS NULL OR pg_catalog.jsonb_typeof(p_filtre) <> 'object'
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p_filtre) k(cle)
                 WHERE k.cle NOT IN ('types', 'langue', 'categorie', 'niveau', 'recherche', 'id',
                                     'rayon', 'etape', 'classe', 'decalage'))
     OR (p_filtre ? 'types' AND pg_catalog.jsonb_typeof(p_filtre -> 'types') <> 'array')
     OR coalesce(pg_catalog.length(v_langue), 0) > 16
     OR coalesce(pg_catalog.length(v_categorie), 0) > 80
     OR coalesce(pg_catalog.length(v_niveau), 0) > 80
     OR coalesce(pg_catalog.length(v_recherche), 0) > 120
     OR (v_rayon IS NOT NULL AND v_rayon !~ '^[a-z][a-z0-9_]{1,31}$')
     OR (v_etape IS NOT NULL AND v_etape !~ '^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$')
     OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
  END IF;
  IF p_filtre ? 'types' THEN
    SELECT pg_catalog.array_agg(t) INTO v_types
      FROM pg_catalog.jsonb_array_elements_text(p_filtre -> 'types') t;
  END IF;
  IF p_filtre ? 'id' THEN
    BEGIN
      v_id := (p_filtre ->> 'id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
    END;
  END IF;
  IF p_filtre ? 'decalage' THEN
    IF pg_catalog.jsonb_typeof(p_filtre -> 'decalage') <> 'number'
       OR (p_filtre ->> 'decalage') !~ '^[0-9]{1,6}$' THEN
      RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
    END IF;
    v_decalage := (p_filtre ->> 'decalage')::integer;
  END IF;
  IF p_filtre ? 'classe' THEN
    BEGIN
      v_classe := (p_filtre ->> 'classe')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
    END;
    -- Une classe qui n'est pas celle de l'appelant : liste vide, aucun indice.
    v_classe_permise := coalesce(
      public.app_role() = 'admin'
      OR (public.app_role() = 'teacher'
          AND EXISTS (SELECT 1 FROM public.mes_groupes_v mg WHERE mg.groupe_id = v_classe))
      OR (public.app_role() IN ('guardian', 'student')
          AND EXISTS (SELECT 1 FROM public.mes_groupes_famille_v mg WHERE mg.groupe_id = v_classe)),
      false);
    IF v_classe_permise IS NOT TRUE THEN
      RETURN '[]'::jsonb;
    END IF;
  END IF;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.n4_manifeste(x.id) ORDER BY x.rayon_ordre, x.ordre, x.title, x.id)
      FROM (
        SELECT r.id, r.title, r.ordre, y.ordre AS rayon_ordre
          FROM public.library_resource r
          JOIN public.library_rayon y ON y.code = r.rayon
         WHERE private.n4_ressource_lisible(r.id)
           AND (v_id IS NULL OR r.id = v_id)
           AND (v_types IS NULL OR cardinality(v_types) = 0 OR r.resource_type::text = ANY (v_types))
           AND (v_langue IS NULL OR r.language = v_langue)
           AND (v_categorie IS NULL OR r.category = v_categorie)
           AND (v_niveau IS NULL OR r.level_scope @> ARRAY[v_niveau])
           AND (v_rayon IS NULL OR r.rayon = v_rayon)
           AND (v_etape IS NULL OR r.etapes @> ARRAY[v_etape])
           AND (v_classe IS NULL OR EXISTS (
                 SELECT 1 FROM public.library_resource_groupe lrg
                  WHERE lrg.resource_id = r.id AND lrg.groupe_id = v_classe))
           AND (v_recherche IS NULL OR pg_catalog.concat_ws(' ', pg_catalog.lower(r.title),
                  pg_catalog.lower(r.short_title), pg_catalog.lower(coalesce(r.edition, '')),
                  pg_catalog.lower(r.category), pg_catalog.lower(coalesce(r.description, '')))
                LIKE '%' || pg_catalog.lower(v_recherche) || '%')
         ORDER BY y.ordre, r.ordre, r.title, r.id
         LIMIT p_limite OFFSET v_decalage
      ) x
  ), '[]'::jsonb);
END;
$function$;

-- Les rayons : tout compte valide. Un rayon vide existe quand meme (la place
-- du second rayon est preparee sans qu'aucun document y soit).
CREATE FUNCTION public.bibliotheque_rayons_lecteur()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'code', y.code, 'titre_fr', y.titre_fr, 'titre_ar', y.titre_ar, 'ordre', y.ordre)
      ORDER BY y.ordre)
      FROM public.library_rayon y
  ), '[]'::jsonb);
END;
$function$;

-- La version courante d'un document lisible, avec son fichier (sans cle de
-- stockage) : ce que la fiche attend de PortVersionsRessource et
-- PortTelechargement. `null` quand l'appelant ne lit pas ce document ou qu'il
-- n'a pas de version publiee. L'URL signee reste celle de la fonction Edge
-- `bibliotheque-lecture`, apres `autoriser_lecture_version`.
CREATE FUNCTION public.bibliotheque_version_lecteur(p_resource_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR NOT private.n4_ressource_lisible(p_resource_id) THEN
    RETURN NULL;
  END IF;
  RETURN (
    SELECT pg_catalog.jsonb_build_object(
      'id', v.id, 'resource_id', v.resource_id, 'numero_version', v.numero_version,
      'statut', v.statut::text, 'publiee_le', v.publiee_le, 'empreinte', v.empreinte,
      'download_asset_id', v.download_asset_id,
      'asset', CASE WHEN a.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
        'id', a.id, 'resource_version_id', a.resource_version_id, 'format', a.format::text,
        'taille_octets', a.taille_octets, 'empreinte', a.empreinte,
        'origine', a.origine::text, 'cree_le', a.cree_le) END)
      FROM public.library_resource r
      JOIN public.resource_version v ON v.id = r.current_version_id AND v.resource_id = r.id
      LEFT JOIN public.download_asset a ON a.id = v.download_asset_id
     WHERE r.id = p_resource_id AND v.statut = 'publiee'
  );
END;
$function$;

-- Les vignettes d'une liste de documents : pour chaque document que l'appelant
-- lit et qui porte une vignette, la cle a signer. Appelee par la fonction Edge
-- `bibliotheque-lecture` (jeton de l'appelant), qui signe l'URL ; l'application
-- ne voit jamais une cle.
CREATE FUNCTION public.bibliotheque_vignettes_autorisees(p_ids uuid[])
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_ids IS NULL OR pg_catalog.cardinality(p_ids) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('id', r.id, 'cle', r.vignette_cle)
                                ORDER BY r.id)
      FROM public.library_resource r
     WHERE r.id = ANY (p_ids)
       AND r.vignette_cle IS NOT NULL
       AND private.n4_ressource_lisible(r.id)
  ), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Le Coran, un document du rayon « Documents des cours »
-- ---------------------------------------------------------------------------
-- Idempotent. Il faut un compte direction actif (la publication d'une version
-- exige un utilisateur, et sa revue des droits un reviseur) ; sans lui, la
-- fonction le dit et ne seme rien : la rappeler une fois ce compte present.
-- Aucun fichier : le Coran se lit dans le lecteur du Coran de l'application.
CREATE FUNCTION app_private.library_semer_coran()
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_admin uuid;
  v_id uuid;
  v_version uuid;
BEGIN
  SELECT r.id INTO v_id FROM public.library_resource r
   WHERE r.resource_type::text = 'quran' ORDER BY r.created_at, r.id LIMIT 1;
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;
  SELECT p.id INTO v_admin FROM public.profiles p
   WHERE p.role::text = 'admin' AND p.account_status::text = 'active'
   ORDER BY p.id LIMIT 1;
  IF v_admin IS NULL THEN
    RAISE NOTICE 'BIBLIOTHEQUE-UNE : le Coran n''est pas seme (aucun compte direction actif). Rappeler app_private.library_semer_coran() ensuite.';
    RETURN NULL;
  END IF;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_admin::text, true);

  INSERT INTO public.library_resource
    (title, short_title, resource_type, edition, language, category, access_policy, offline_policy,
     capabilities, description, rayon, ordre)
  VALUES ('Le Coran', 'Coran', 'quran'::public.library_resource_type, 'madina-hafs-604', 'ar', 'coran',
          'inscrits', 'jamais', ARRAY['pageable', 'searchable', 'zoomable'],
          'Le Coran en entier, page par page, dans le lecteur de l''académie.', 'cours', 0)
  RETURNING id INTO v_id;
  INSERT INTO public.resource_version (resource_id, numero_version, statut)
  VALUES (v_id, 1, 'brouillon') RETURNING id INTO v_version;
  INSERT INTO public.library_version_rights
    (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
  VALUES (v_version,
          'Coran, texte intégré au lecteur du Coran de l''application',
          'Voir « À propos de l''édition » dans le lecteur du Coran',
          ARRAY['application', 'classe'],
          'Sources et licences : « À propos de l''édition », dans le lecteur du Coran.',
          true, v_admin, pg_catalog.now());
  UPDATE public.resource_version SET statut = 'publiee' WHERE id = v_version;
  UPDATE public.library_resource SET current_version_id = v_version WHERE id = v_id;
  RETURN v_id;
END;
$function$;
REVOKE ALL ON FUNCTION app_private.library_semer_coran()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

SELECT app_private.library_semer_coran();

-- ---------------------------------------------------------------------------
-- 8. Droits d'execution, proprietaire, empreintes
-- ---------------------------------------------------------------------------
ALTER FUNCTION public.demander_vignette_bibliotheque(uuid, text, bigint, text) OWNER TO postgres;
ALTER FUNCTION public.lire_vignette_bibliotheque(uuid) OWNER TO postgres;
ALTER FUNCTION public.confirmer_vignette_bibliotheque(uuid, text, bigint, text, text) OWNER TO postgres;
ALTER FUNCTION public.annuler_vignette_bibliotheque(uuid) OWNER TO postgres;
ALTER FUNCTION public.bibliotheque_rayons_lecteur() OWNER TO postgres;
ALTER FUNCTION public.bibliotheque_version_lecteur(uuid) OWNER TO postgres;
ALTER FUNCTION public.bibliotheque_vignettes_autorisees(uuid[]) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.demander_vignette_bibliotheque(uuid, text, bigint, text)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.lire_vignette_bibliotheque(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.confirmer_vignette_bibliotheque(uuid, text, bigint, text, text)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.annuler_vignette_bibliotheque(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.bibliotheque_rayons_lecteur()
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.bibliotheque_version_lecteur(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.bibliotheque_vignettes_autorisees(uuid[])
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_vignette_bibliotheque(uuid, text, bigint, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lire_vignette_bibliotheque(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirmer_vignette_bibliotheque(uuid, text, bigint, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.annuler_vignette_bibliotheque(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bibliotheque_rayons_lecteur() TO authenticated;
GRANT EXECUTE ON FUNCTION public.bibliotheque_version_lecteur(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bibliotheque_vignettes_autorisees(uuid[]) TO authenticated;

-- Les fonctions remplacees gardent leur proprietaire et leurs droits ; on les
-- reaffirme sans rien elargir.
REVOKE ALL ON FUNCTION public.library_creer_brouillon(jsonb) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_creer_brouillon(jsonb) TO authenticated;
REVOKE ALL ON FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.library_get_detail(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_get_detail(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.bibliotheque_catalogue_lecteur(jsonb, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.bibliotheque_catalogue_lecteur(jsonb, integer) TO authenticated;
REVOKE ALL ON FUNCTION private.n4_manifeste(uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION app_private.library_controle_version(uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Empreinte F86 de chaque fonction publique touchee : calculee ici, sur la
-- definition reellement installee.
DO $empreintes$
DECLARE
  v_signature regprocedure;
  v_garde text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.library_creer_brouillon(jsonb)'::regprocedure,
    'public.library_mettre_a_jour(uuid,jsonb,integer)'::regprocedure,
    'public.library_get_detail(uuid)'::regprocedure,
    'public.demander_vignette_bibliotheque(uuid,text,bigint,text)'::regprocedure,
    'public.lire_vignette_bibliotheque(uuid)'::regprocedure,
    'public.confirmer_vignette_bibliotheque(uuid,text,bigint,text,text)'::regprocedure,
    'public.annuler_vignette_bibliotheque(uuid)'::regprocedure,
    'public.bibliotheque_catalogue_lecteur(jsonb,integer)'::regprocedure,
    'public.bibliotheque_rayons_lecteur()'::regprocedure,
    'public.bibliotheque_version_lecteur(uuid)'::regprocedure,
    'public.bibliotheque_vignettes_autorisees(uuid[])'::regprocedure
  ] LOOP
    v_garde := CASE WHEN v_signature::text LIKE 'public.bibliotheque\_%lecteur%' ESCAPE '\'
                         OR v_signature::text LIKE 'public.bibliotheque\_vignettes%' ESCAPE '\'
                    THEN 'AUTHENTIFIE_POSITIF' ELSE 'ROLE_POSITIVE_TEMPLATE' END;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_signature,
      pg_catalog.format('F86: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; date=2026-11-12. Lot BIBLIOTHEQUE-UNE.',
        v_signature, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_signature)), v_garde));
  END LOOP;
END
$empreintes$;

-- ---------------------------------------------------------------------------
-- 9. Controle de sortie
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.library_creer_brouillon(jsonb)',
    'public.library_mettre_a_jour(uuid,jsonb,integer)',
    'public.library_get_detail(uuid)',
    'public.demander_vignette_bibliotheque(uuid,text,bigint,text)',
    'public.lire_vignette_bibliotheque(uuid)',
    'public.confirmer_vignette_bibliotheque(uuid,text,bigint,text,text)',
    'public.annuler_vignette_bibliotheque(uuid)',
    'public.bibliotheque_catalogue_lecteur(jsonb,integer)',
    'public.bibliotheque_rayons_lecteur()',
    'public.bibliotheque_version_lecteur(uuid)',
    'public.bibliotheque_vignettes_autorisees(uuid[])'
  ] LOOP
    IF pg_catalog.has_function_privilege('anon', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_signature, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_signature, 'EXECUTE') THEN
      RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : ACL incorrecte pour %', v_signature;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = v_signature::regprocedure
         AND p.prosecdef
         AND p.proconfig @> ARRAY['search_path=""']
         AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
    ) THEN
      RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : DEFINER, search_path ou proprietaire invalide pour %', v_signature;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.n4_manifeste(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.library_controle_version(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.library_semer_coran()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.library_etapes_normalisees(jsonb)', 'EXECUTE') THEN
    RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : une fonction interne est executable par un client';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.library_rayon'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.library_vignette_intentions'::regclass) THEN
    RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : RLS absente sur une table neuve';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.library_vignette_intentions', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.library_rayon', 'SELECT') THEN
    RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : droit de table trop large';
  END IF;
  -- Aucune colonne de prix : la vente n'est pas ouverte (directeur, 12/11/2026).
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
              WHERE a.attrelid = 'public.library_resource'::regclass AND a.attnum > 0 AND NOT a.attisdropped
                AND a.attname ~* '(prix|price|montant|amount|cents|tarif)') THEN
    RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : une colonne de prix existe sur library_resource';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.library_rayon) < 2 THEN
    RAISE EXCEPTION 'BIBLIOTHEQUE-UNE : les deux rayons ne sont pas semes';
  END IF;
END
$postflight$;
