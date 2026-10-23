-- CAP29 : les ecritures de la Bibliotheque par la direction
-- (PortBibliothequeAdmin : creerBrouillon, nouvelleVersion, controler,
-- publier, classes, attribuer, retirer).
--
-- Aucune ecriture n'existait : recherche du motif library_ dans tout
-- l'historique et sur les branches origin/codex*/ ; seules les lectures,
-- l'upload signe et la revue des droits existent, aucune RPC de brouillon,
-- de publication, d'attribution ni de retrait. Aucune table nouvelle :
-- library_resource, resource_version, library_version_rights,
-- library_resource_groupe ; l'idempotence de la publication reprend
-- pedagogie_partage_idempotence (operation 'library_publier').
--
-- * Reponses comme admin_library_review_rights : {resultat:
--   'EcritureFaite' | 'EcritureEnConflit', revision} ; publication :
--   'VersionPubliee' | 'PublicationBloquee' (avec le controle) |
--   'PublicationEnConflit'. Erreurs nommees : BibliothequeNonAutorisee
--   (42501), BibliothequeIntrouvable (P0002), saisies invalides (22023).
-- * Controle avant publication (ControleVersion, 11 criteres dans l'ordre
--   de CleCritere) : publiable = droits approuves ET tous valides. Les
--   gardes CAP29 existantes (droits approuves, version unique publiee,
--   pointeur courant) restent la barriere en base.
-- * Les capacites suivent : library_admin_capacites rend vrai pour la
--   direction active ; library_get_detail rend peutPublier, peutAttribuer et
--   peutRetirer selon l'etat de la ressource. peutModifier reste faux :
--   mettreAJour (organisme, description, conditions) n'a ni colonnes ni RPC.
-- * DEFINER partout (tables et colonnes non accordees aux clients), garde
--   positive direction active, md5 reel.
BEGIN;

-- ------------------------------------------------------------------
-- Les capacites de la direction : les ecritures existent desormais.
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.library_admin_capacites()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'peutLire', v.direction, 'peutImporter', v.direction,
    'peutPublier', v.direction, 'peutAttribuer', v.direction)
  FROM (SELECT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) AS direction) v;
$function$;

-- ------------------------------------------------------------------
-- Le controle d'une version avant publication (ControleVersion).
-- INTERNE : INVOKER sans EXECUTE client ; appelee par les RPC DEFINER.
-- Rend {criteres: [{cle, etat}], publiable}. etat : 'valide' | 'bloque' |
-- 'inconnu'. publiable = droits approuves ET tous les criteres valides.
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.library_controle_version(p_version_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  WITH base AS (
    SELECT v.id, v.empreinte, r.level_scope, r.language,
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
      (3, 'preuve', b.preuve),
      (4, 'usageApplication', coalesce('application' = ANY (b.usages), false)),
      (5, 'usageClasse', coalesce('classe' = ANY (b.usages), false)),
      (6, 'usageTelechargement', true),
      (7, 'expirationAttribution', b.expire_le IS NULL OR b.expire_le > pg_catalog.now()),
      (8, 'fichierSain', b.asset_id IS NOT NULL),
      (9, 'renduTeste', CASE WHEN b.asset_id IS NOT NULL THEN true END),
      (10, 'langueNiveau', coalesce(pg_catalog.btrim(b.language), '') <> ''
                           AND coalesce(pg_catalog.cardinality(b.level_scope), 0) > 0),
      (11, 'versionEmpreinte', coalesce(b.empreinte, b.asset_empreinte) IS NOT NULL)
    ) AS c(rang, cle, ok)
  )
  SELECT pg_catalog.jsonb_build_object(
    'criteres', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('cle', c.cle, 'etat', c.etat)
                                                       ORDER BY c.rang) FROM criteres c), '[]'::jsonb),
    'publiable', coalesce((SELECT b.approuve FROM base b), false)
                 AND EXISTS (SELECT 1 FROM base)
                 AND NOT EXISTS (SELECT 1 FROM criteres c WHERE c.etat <> 'valide'));
$function$;
REVOKE ALL ON FUNCTION app_private.library_controle_version(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ------------------------------------------------------------------
-- Creer un brouillon (NouveauSupport) : la ressource, invisible hors
-- direction (access_policy 'admin', jamais hors ligne), et sa version 1 en
-- brouillon. Rend {id, version_id, revision}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_creer_brouillon(p_saisie jsonb)
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
  v_id uuid;
  v_version uuid;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_saisie IS NULL OR pg_catalog.jsonb_typeof(p_saisie) <> 'object'
     OR (p_saisie - ARRAY['titre', 'type', 'langue', 'categorie', 'niveau']) <> '{}'::jsonb THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  v_titre := pg_catalog.btrim(coalesce(p_saisie ->> 'titre', ''));
  v_type := p_saisie ->> 'type';
  v_langue := pg_catalog.btrim(coalesce(p_saisie ->> 'langue', ''));
  v_categorie := pg_catalog.btrim(coalesce(p_saisie ->> 'categorie', ''));
  v_niveau := nullif(pg_catalog.btrim(coalesce(p_saisie ->> 'niveau', '')), '');
  IF pg_catalog.length(v_titre) NOT BETWEEN 1 AND 200
     OR pg_catalog.length(v_langue) NOT BETWEEN 2 AND 16
     OR pg_catalog.length(v_categorie) > 80
     OR coalesce(pg_catalog.length(v_niveau), 0) > 80
     OR v_type IS NULL OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_enum e
       JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
       JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
       WHERE n.nspname = 'public' AND t.typname = 'library_resource_type' AND e.enumlabel = v_type) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.library_resource
    (title, short_title, resource_type, language, category, level_scope, access_policy, offline_policy)
  VALUES (v_titre, pg_catalog.left(v_titre, 60), v_type::public.library_resource_type, v_langue,
          v_categorie, CASE WHEN v_niveau IS NULL THEN '{}'::text[] ELSE ARRAY[v_niveau] END,
          'admin', 'jamais')
  RETURNING id, revision INTO v_id, v_revision;
  INSERT INTO public.resource_version (resource_id, numero_version, statut)
  VALUES (v_id, 1, 'brouillon') RETURNING id INTO v_version;

  PERFORM public.log_sensitive_access('library_draft_created', 'library_resource', v_id::text,
    pg_catalog.jsonb_build_object('resource_version_id', v_version));
  RETURN pg_catalog.jsonb_build_object('id', v_id, 'version_id', v_version, 'revision', v_revision);
END;
$function$;

-- ------------------------------------------------------------------
-- Une nouvelle version en brouillon. Idempotente : si la derniere version
-- est deja un brouillon, elle est rendue. Rend {version_id, numero}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_nouvelle_version(p_resource_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_derniere public.resource_version%ROWTYPE;
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeRetiree' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_derniere FROM public.resource_version v
   WHERE v.resource_id = p_resource_id ORDER BY v.numero_version DESC LIMIT 1;
  IF v_derniere.statut = 'brouillon' THEN
    RETURN pg_catalog.jsonb_build_object('version_id', v_derniere.id, 'numero', v_derniere.numero_version);
  END IF;
  INSERT INTO public.resource_version (resource_id, numero_version, statut)
  VALUES (p_resource_id, coalesce(v_derniere.numero_version, 0) + 1, 'brouillon')
  RETURNING id INTO v_id;
  UPDATE public.library_resource r SET title = r.title WHERE r.id = p_resource_id;
  PERFORM public.log_sensitive_access('library_version_created', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('resource_version_id', v_id));
  RETURN pg_catalog.jsonb_build_object('version_id', v_id, 'numero', coalesce(v_derniere.numero_version, 0) + 1);
END;
$function$;

-- ------------------------------------------------------------------
-- Controler une version (lecture de la direction).
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_controler_version(p_version_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.resource_version v WHERE v.id = p_version_id) THEN
    RAISE EXCEPTION 'BibliothequeVersionIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  RETURN app_private.library_controle_version(p_version_id);
END;
$function$;

-- ------------------------------------------------------------------
-- Publier une version. Rend {resultat: 'VersionPubliee', revision}
-- | {resultat: 'PublicationBloquee', controle} | {resultat:
-- 'PublicationEnConflit', revision}. La version publiee precedente passe a
-- 'archivee', le pointeur courant bascule ; une ressource encore reservee a
-- la direction devient 'groupe_assigne'. La meme cle rend la meme reponse.
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_publier_version(
  p_resource_id uuid, p_version_id uuid, p_revision_attendue integer, p_cle text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_acteur uuid := auth.uid();
  v_deja jsonb;
  v_resource public.library_resource%ROWTYPE;
  v_version public.resource_version%ROWTYPE;
  v_controle jsonb;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR p_version_id IS NULL OR p_revision_attendue IS NULL
     OR coalesce(pg_catalog.length(pg_catalog.btrim(p_cle)), 0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequePublicationInvalide' USING ERRCODE = '22023';
  END IF;
  SELECT i.resultat INTO v_deja FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_acteur AND i.cle_idempotence = p_cle AND i.operation = 'library_publier';
  IF v_deja IS NOT NULL THEN
    RETURN v_deja;
  END IF;

  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  SELECT * INTO v_version FROM public.resource_version v
   WHERE v.id = p_version_id AND v.resource_id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeVersionIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL OR v_version.statut <> 'brouillon' THEN
    RAISE EXCEPTION 'BibliothequeVersionNonPubliable' USING ERRCODE = '22023';
  END IF;

  IF v_resource.revision <> p_revision_attendue THEN
    v_resultat := pg_catalog.jsonb_build_object('resultat', 'PublicationEnConflit', 'revision', v_resource.revision);
  ELSE
    v_controle := app_private.library_controle_version(p_version_id);
    IF NOT (v_controle ->> 'publiable')::boolean THEN
      v_resultat := pg_catalog.jsonb_build_object('resultat', 'PublicationBloquee', 'controle', v_controle);
    ELSE
      UPDATE public.resource_version SET statut = 'archivee'
       WHERE resource_id = p_resource_id AND statut = 'publiee';
      UPDATE public.resource_version SET statut = 'publiee' WHERE id = p_version_id;
      UPDATE public.library_resource
         SET current_version_id = p_version_id,
             access_policy = CASE WHEN access_policy = 'admin' THEN 'groupe_assigne' ELSE access_policy END
       WHERE id = p_resource_id;
      SELECT r.revision INTO v_resource.revision FROM public.library_resource r WHERE r.id = p_resource_id;
      v_resultat := pg_catalog.jsonb_build_object('resultat', 'VersionPubliee', 'revision', v_resource.revision);
      PERFORM public.log_sensitive_access('library_version_published', 'library_resource', p_resource_id::text,
        pg_catalog.jsonb_build_object('resource_version_id', p_version_id, 'revision', v_resource.revision));
    END IF;
  END IF;

  INSERT INTO public.pedagogie_partage_idempotence (actor_id, cle_idempotence, operation, requete, resultat)
  VALUES (v_acteur, p_cle, 'library_publier',
          pg_catalog.jsonb_build_object('resource_id', p_resource_id, 'version_id', p_version_id,
                                        'revision_attendue', p_revision_attendue),
          v_resultat);
  RETURN v_resultat;
END;
$function$;

-- ------------------------------------------------------------------
-- Les classes actives a qui attribuer un support, paginees (curseur =
-- rang suivant). Rend {elements: [{id, libelle, numero, deja_servie,
-- epinglee}], curseur}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_classes_attribuables(
  p_resource_id uuid, p_curseur text DEFAULT NULL, p_limite integer DEFAULT 25
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_debut integer;
  v_total integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 100
     OR (p_curseur IS NOT NULL AND p_curseur !~ '^[0-9]{1,7}$') THEN
    RAISE EXCEPTION 'BibliothequeCurseurInvalide' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.library_resource r WHERE r.id = p_resource_id) THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  v_debut := coalesce(p_curseur::integer, 0);
  SELECT count(*)::integer INTO v_total FROM public.groupes g WHERE g.ended_at IS NULL;
  RETURN pg_catalog.jsonb_build_object(
    'elements', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'numero', c.numero,
               'deja_servie', c.lrg IS NOT NULL, 'epinglee', coalesce(c.epinglee, false))
             ORDER BY c.libelle, c.numero, c.id)
      FROM (
        SELECT g.id, g.libelle, n.numero, lrg.resource_id AS lrg, lrg.epinglee
        FROM public.groupes g
        JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
        LEFT JOIN public.library_resource_groupe lrg
          ON lrg.groupe_id = g.id AND lrg.resource_id = p_resource_id
        WHERE g.ended_at IS NULL
        ORDER BY g.libelle, n.numero, g.id
        OFFSET v_debut LIMIT p_limite
      ) c), '[]'::jsonb),
    'curseur', CASE WHEN v_debut + p_limite < v_total THEN (v_debut + p_limite)::text END);
END;
$function$;

-- ------------------------------------------------------------------
-- Attribuer un support publie a des classes actives. Idempotent : une
-- classe deja servie n'est pas comptee deux fois ; p_epingler fixe
-- l'epinglage des classes nommees. Rend {resultat: 'EcritureFaite' |
-- 'EcritureEnConflit', revision}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_attribuer(
  p_resource_id uuid, p_classe_ids uuid[], p_epingler boolean, p_revision_attendue integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_classe_ids IS NULL OR pg_catalog.cardinality(p_classe_ids) NOT BETWEEN 1 AND 500
     OR p_epingler IS NULL OR p_revision_attendue IS NULL THEN
    RAISE EXCEPTION 'BibliothequeAttributionInvalide' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL OR v_resource.current_version_id IS NULL THEN
    RAISE EXCEPTION 'BibliothequeNonPubliee' USING ERRCODE = '42501';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureEnConflit', 'revision', v_resource.revision);
  END IF;
  IF EXISTS (SELECT 1 FROM unnest(p_classe_ids) c(id)
              WHERE NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = c.id AND g.ended_at IS NULL)) THEN
    RAISE EXCEPTION 'BibliothequeClasseIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.library_resource_groupe (resource_id, groupe_id, epinglee, ajoutee_par)
  SELECT DISTINCT p_resource_id, c.id, p_epingler, auth.uid() FROM unnest(p_classe_ids) c(id)
  ON CONFLICT (resource_id, groupe_id) DO UPDATE SET epinglee = EXCLUDED.epinglee;
  UPDATE public.library_resource r SET title = r.title WHERE r.id = p_resource_id
  RETURNING r.revision INTO v_revision;
  PERFORM public.log_sensitive_access('library_assigned', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('classes', pg_catalog.cardinality(p_classe_ids), 'epinglee', p_epingler));
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_revision);
END;
$function$;

-- ------------------------------------------------------------------
-- Retirer un support du catalogue (archived_at), avec son motif trace dans
-- l'audit. Un support deja retire rend EcritureFaite sans rien changer.
-- Les classes qui le presentent le voient retire (support_actif).
-- ------------------------------------------------------------------
CREATE FUNCTION public.library_retirer(p_resource_id uuid, p_motif text, p_revision_attendue integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.length(pg_catalog.btrim(coalesce(p_motif, ''))) NOT BETWEEN 3 AND 500
     OR p_revision_attendue IS NULL THEN
    RAISE EXCEPTION 'BibliothequeMotifInvalide' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_resource.revision);
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureEnConflit', 'revision', v_resource.revision);
  END IF;
  UPDATE public.library_resource r SET archived_at = pg_catalog.clock_timestamp()
   WHERE r.id = p_resource_id RETURNING r.revision INTO v_revision;
  PERFORM public.log_sensitive_access('library_withdrawn', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('motif', pg_catalog.btrim(p_motif)));
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_revision);
END;
$function$;

-- La fiche : capacites calculees (le reste du corps est inchange).
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
      'modifieLeUtc', v_resource.updated_at
    ),
    'revision', v_resource.revision,
    'versions', v_versions,
    'droits', v_rights,
    'historique', v_history,
    'capacites', pg_catalog.jsonb_build_object(
      'peutModifier', false,
      'peutPublier', v_resource.archived_at IS NULL,
      'peutAttribuer', v_resource.archived_at IS NULL AND v_resource.current_version_id IS NOT NULL,
      'peutRetirer', v_resource.archived_at IS NULL
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.library_creer_brouillon(jsonb) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_creer_brouillon(jsonb) TO authenticated;
REVOKE ALL ON FUNCTION public.library_nouvelle_version(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_nouvelle_version(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.library_controler_version(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_controler_version(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.library_publier_version(uuid, uuid, integer, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_publier_version(uuid, uuid, integer, text) TO authenticated;
REVOKE ALL ON FUNCTION public.library_classes_attribuables(uuid, text, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_classes_attribuables(uuid, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.library_attribuer(uuid, uuid[], boolean, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_attribuer(uuid, uuid[], boolean, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.library_retirer(uuid, text, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_retirer(uuid, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.library_get_detail(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_get_detail(uuid) TO authenticated;

-- @@F86_DEBUT_BIBLIOTHEQUE@@
COMMENT ON FUNCTION public.library_creer_brouillon(jsonb) IS
  'F86: signature=public.library_creer_brouillon(jsonb); md5_functiondef=0c18dc716fd7aa0da78adf06eeca7c72; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_nouvelle_version(uuid) IS
  'F86: signature=public.library_nouvelle_version(uuid); md5_functiondef=0e38544823de6cb7a0ff8cacfeae6e90; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_controler_version(uuid) IS
  'F86: signature=public.library_controler_version(uuid); md5_functiondef=543b04dad65a6ee43bdee9a36407846f; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_publier_version(uuid, uuid, integer, text) IS
  'F86: signature=public.library_publier_version(uuid,uuid,integer,text); md5_functiondef=4c631ec0202c2a564bb7f2d546fa2c8b; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_classes_attribuables(uuid, text, integer) IS
  'F86: signature=public.library_classes_attribuables(uuid,text,integer); md5_functiondef=62204099bbd5e363a853c124474b5b3e; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_attribuer(uuid, uuid[], boolean, integer) IS
  'F86: signature=public.library_attribuer(uuid,uuid[],boolean,integer); md5_functiondef=82687bb8358ac3b774e322eb5a38030e; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_retirer(uuid, text, integer) IS
  'F86: signature=public.library_retirer(uuid,text,integer); md5_functiondef=bf9eb10c6a3f79fbd37e5774b6bdc7a6; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
COMMENT ON FUNCTION public.library_get_detail(uuid) IS
  'F86: signature=public.library_get_detail(uuid); md5_functiondef=15218fda36b0dc892dc5febf17460390; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.library_creer_brouillon(jsonb)'::regprocedure, '0c18dc716fd7aa0da78adf06eeca7c72'),
      ('public.library_nouvelle_version(uuid)'::regprocedure, '0e38544823de6cb7a0ff8cacfeae6e90'),
      ('public.library_controler_version(uuid)'::regprocedure, '543b04dad65a6ee43bdee9a36407846f'),
      ('public.library_publier_version(uuid,uuid,integer,text)'::regprocedure, '4c631ec0202c2a564bb7f2d546fa2c8b'),
      ('public.library_classes_attribuables(uuid,text,integer)'::regprocedure, '62204099bbd5e363a853c124474b5b3e'),
      ('public.library_attribuer(uuid,uuid[],boolean,integer)'::regprocedure, '82687bb8358ac3b774e322eb5a38030e'),
      ('public.library_retirer(uuid,text,integer)'::regprocedure, 'bf9eb10c6a3f79fbd37e5774b6bdc7a6'),
      ('public.library_get_detail(uuid)'::regprocedure, '15218fda36b0dc892dc5febf17460390')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'app_private.library_controle_version(uuid)'::regprocedure
      AND (p.prosecdef OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'CAP29 ecritures : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_BIBLIOTHEQUE@@

COMMIT;
