-- DEPOT-SIMPLE (directeur, 13/11/2026 ; arbitrage de l'architecte pedagogique
-- du meme jour) : « ca doit rester le strict necessaire ». Un document depose
-- par la direction avec seulement un fichier et un nom doit pouvoir etre
-- enregistre ET publie, sans que personne ne saisisse source, titulaire,
-- preuve, niveau ni revue des droits.
--
-- Ce que la migration ajoute, et rien d'autre :
--   1. trois colonnes de trace sur library_version_rights : qui a fait le
--      depot direct, quand, et si le droit de diffuser le document d'un tiers
--      a ete declare ;
--   2. app_private.library_controle_version : la declaration du depot direct
--      vaut preuve (critere 3) et rattachement au programme (critere 10,
--      « niveau = tous ») ; sans depot direct, le controle est INCHANGE ;
--   3. public.library_depot_direct : la direction seule ; remplit par defaut
--      les droits restes vides, approuve la revue (trace : acteur, date,
--      « depot direct de la direction »), pose le public (tous les inscrits,
--      enfants compris, ou adultes seulement), ouvre le document aux inscrits
--      et le publie par public.library_publier_version (meme controle, meme
--      journal, meme idempotence). TOUT OU RIEN : si la publication est
--      bloquee, la fonction leve une exception et rien n'est ecrit (ni droits,
--      ni visibilite, ni journal, ni cle). Pour le rayon des documents d'un
--      tiers (tout rayon autre que « cours »), UNE declaration est exigee :
--      « l'academie a le droit de diffuser ce document » ;
--   4. public.library_changer_acces : la direction change l'acces d'un
--      document (lire dans l'application seulement, ou telechargement permis)
--      sans redeposer son fichier ni creer de version.
--
-- Aucun prix, aucun paiement. Aucune suppression (ni objet, ni ligne). Rejouable.
-- Tests : supabase/tests/scenarios_depot_direct.sql.

ALTER TABLE public.library_version_rights
  ADD COLUMN IF NOT EXISTS depot_direct_par uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS depot_direct_le timestamptz,
  ADD COLUMN IF NOT EXISTS droit_tiers_declare boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.library_version_rights.depot_direct_par IS
  'DEPOT-SIMPLE : la personne de la direction qui a depose et publie directement ; NULL pour une revue des droits classique.';
COMMENT ON COLUMN public.library_version_rights.droit_tiers_declare IS
  'DEPOT-SIMPLE : vrai quand la direction a declare que l''academie a le droit de diffuser ce document d''un tiers.';

-- ---------------------------------------------------------------------------
-- Le controle de publication : identique a celui de BIBLIOTHEQUE-UNE, plus la
-- declaration du depot direct aux criteres 3 et 10.
-- ---------------------------------------------------------------------------
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
           -- Le depot direct de la direction : sa declaration tracee vaut preuve.
           -- Pour un document d'un tiers, elle n'existe que si le droit de
           -- diffuser a ete declare.
           (d.depot_direct_par IS NOT NULL
            AND (r.rayon = 'cours' OR d.droit_tiers_declare)) AS depot_direct,
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
      (3, 'preuve', b.preuve OR b.lien_pur OR coalesce(b.depot_direct, false)),
      (4, 'usageApplication', coalesce('application' = ANY (b.usages), false)),
      (5, 'usageClasse', coalesce('classe' = ANY (b.usages), false)),
      (6, 'usageTelechargement', true),
      (7, 'expirationAttribution', b.expire_le IS NULL OR b.expire_le > pg_catalog.now()),
      (8, 'fichierSain', b.asset_id IS NOT NULL OR b.par_lien),
      (9, 'renduTeste', CASE WHEN b.asset_id IS NOT NULL OR b.par_lien THEN true END),
      (10, 'langueNiveau', coalesce(pg_catalog.btrim(b.language), '') <> ''
                           AND (coalesce(pg_catalog.cardinality(b.level_scope), 0) > 0
                                OR coalesce(pg_catalog.cardinality(b.etapes), 0) > 0
                                OR coalesce(b.depot_direct, false))),
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
REVOKE ALL ON FUNCTION app_private.library_controle_version(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- Le depot direct : enregistrer et publier en un geste, direction seulement.
--   p_acces       : 'lecture' (lire dans l'application seulement) ou
--                   'telechargement' (telechargement permis).
--   p_droit_tiers : la declaration « l'academie a le droit de diffuser ce
--                   document » ; exigee hors du rayon des cours.
--   p_public      : 'tous' (tous les inscrits, enfants compris), 'adultes'
--                   (adultes seulement), ou NULL (les tranches d'age deja
--                   reglees sont gardees). Le serveur pose les tranches.
-- Rend {resultat: 'VersionPubliee', revision} ou {resultat:
-- 'PublicationEnConflit', revision}. Une publication bloquee LEVE
-- 'BibliothequeDepotBloque' (55000), le controle en DETAIL : rien n'est ecrit.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.library_depot_direct(
  p_resource_id uuid,
  p_revision_attendue integer,
  p_cle text,
  p_acces text,
  p_droit_tiers boolean,
  p_public text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_acteur uuid := auth.uid();
  v_deja record;
  v_resource public.library_resource%ROWTYPE;
  v_version public.resource_version%ROWTYPE;
  v_droits public.library_version_rights%ROWTYPE;
  v_usages text[];
  v_tiers boolean;
  v_revision integer;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR p_revision_attendue IS NULL
     OR p_acces IS NULL OR p_acces NOT IN ('lecture', 'telechargement')
     OR (p_public IS NOT NULL AND p_public NOT IN ('tous', 'adultes'))
     OR coalesce(pg_catalog.length(pg_catalog.btrim(p_cle)), 0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequeDepotInvalide' USING ERRCODE = '22023';
  END IF;
  -- La meme cle rend la meme reponse, pour le MEME document seulement : une
  -- cle deja employee pour un autre document est refusee, jamais confondue.
  SELECT i.resultat, i.requete INTO v_deja FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_acteur AND i.cle_idempotence = p_cle AND i.operation = 'library_publier';
  IF FOUND THEN
    IF v_deja.requete ->> 'resource_id' IS DISTINCT FROM p_resource_id::text THEN
      RAISE EXCEPTION 'BibliothequeCleDejaUtilisee' USING ERRCODE = '22023';
    END IF;
    RETURN v_deja.resultat;
  END IF;

  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeVersionNonPubliable' USING ERRCODE = '22023';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'PublicationEnConflit', 'revision', v_resource.revision);
  END IF;
  SELECT * INTO v_version FROM public.resource_version v
   WHERE v.resource_id = p_resource_id AND v.statut = 'brouillon'
   ORDER BY v.numero_version DESC LIMIT 1 FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeVersionNonPubliable' USING ERRCODE = '22023';
  END IF;
  -- Rien a publier sans le fichier (ou le lien) : le formulaire ne propose pas
  -- le bouton avant, la base le refuse de toute facon.
  IF v_version.download_asset_id IS NULL AND v_resource.lien_externe IS NULL THEN
    RAISE EXCEPTION 'BibliothequeDepotSansFichier' USING ERRCODE = '22023';
  END IF;
  -- Un document d'un tiers : la declaration du droit de diffuser est exigee.
  v_tiers := v_resource.rayon <> 'cours';
  IF v_tiers AND p_droit_tiers IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeDroitTiersRequis' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.library_version_rights (resource_version_id)
  VALUES (v_version.id) ON CONFLICT DO NOTHING;
  SELECT * INTO v_droits FROM public.library_version_rights d
   WHERE d.resource_version_id = v_version.id FOR UPDATE;
  -- L'acces choisi ; le hors ligne garde ce qui a ete regle.
  v_usages := ARRAY['application', 'classe']
    || CASE WHEN p_acces = 'telechargement' AND v_resource.lien_externe IS NULL
            THEN ARRAY['telechargement'] ELSE '{}'::text[] END
    || CASE WHEN 'hors_ligne' = ANY (v_droits.usages) THEN ARRAY['hors_ligne'] ELSE '{}'::text[] END;
  -- Les droits restes vides prennent leur valeur par defaut ; ce que la
  -- direction a saisi dans « Plus de reglages » est garde tel quel.
  UPDATE public.library_version_rights d
     SET source_titre = CASE WHEN pg_catalog.btrim(d.source_titre) <> '' THEN d.source_titre
                             ELSE pg_catalog.left(v_resource.title, 200) END,
         titulaire = CASE WHEN pg_catalog.btrim(d.titulaire) <> '' THEN d.titulaire
                          WHEN v_tiers THEN 'Tiers : droit de diffusion déclaré par la direction'
                          ELSE 'Rewayah Academy' END,
         attribution = CASE WHEN pg_catalog.btrim(d.attribution) <> '' THEN d.attribution
                            WHEN v_tiers THEN pg_catalog.left(v_resource.title, 200)
                            ELSE 'Rewayah Academy' END,
         usages = v_usages,
         droit_tiers_declare = v_tiers AND p_droit_tiers IS TRUE,
         depot_direct_par = v_acteur,
         depot_direct_le = pg_catalog.clock_timestamp(),
         approuve = true,
         revu_par = v_acteur,
         revu_le = pg_catalog.clock_timestamp()
   WHERE d.resource_version_id = v_version.id;

  -- « Visible de qui » : un document encore reserve a la direction s'ouvre
  -- aux inscrits ; une visibilite deja choisie n'est pas changee. Le public
  -- choisi pose les tranches d'age ICI, jamais dans le client.
  UPDATE public.library_resource r
     SET access_policy = CASE WHEN r.access_policy = 'admin' THEN 'inscrits' ELSE r.access_policy END,
         tranches = CASE p_public
                      WHEN 'tous' THEN ARRAY['enfant_6_9', 'enfant_10_13', 'ado_14_17', 'adulte_18_plus']
                      WHEN 'adultes' THEN ARRAY['adulte_18_plus']
                      ELSE r.tranches END
   WHERE r.id = p_resource_id;

  PERFORM public.log_sensitive_access('library_direct_deposit', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object(
      'resource_version_id', v_version.id,
      'motif', 'depot direct de la direction',
      'acces', p_acces,
      'public', p_public,
      'rayon', v_resource.rayon,
      'droit_tiers_declare', v_tiers AND p_droit_tiers IS TRUE));

  SELECT r.revision INTO v_revision FROM public.library_resource r WHERE r.id = p_resource_id;
  v_resultat := public.library_publier_version(p_resource_id, v_version.id, v_revision, p_cle);
  -- TOUT OU RIEN. Une publication bloquee ne laisse ni droits approuves, ni
  -- visibilite ouverte, ni ligne de journal, ni cle d'idempotence : l'exception
  -- annule tout ce que cette fonction a ecrit. Le controle part en DETAIL, pour
  -- que l'ecran dise ce qui bloque et quoi faire.
  IF v_resultat ->> 'resultat' IS DISTINCT FROM 'VersionPubliee' THEN
    RAISE EXCEPTION 'BibliothequeDepotBloque'
      USING ERRCODE = '55000',
            DETAIL = coalesce((v_resultat -> 'controle')::text, v_resultat::text);
  END IF;
  RETURN v_resultat;
END;
$function$;

ALTER FUNCTION public.library_depot_direct(uuid, integer, text, text, boolean, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.library_depot_direct(uuid, integer, text, text, boolean, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_depot_direct(uuid, integer, text, text, boolean, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Changer l'acces d'un document sans redeposer son fichier : la direction
-- seule. L'acces est porte par les droits de la version ; on ne touche que
-- l'usage « telechargement » de la version courante (publiee), ou du dernier
-- brouillon si rien n'est publie. Le fichier, lui, ne change pas.
-- Rend {resultat: 'EcritureFaite' | 'EcritureEnConflit', revision}.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.library_changer_acces(
  p_resource_id uuid,
  p_acces text,
  p_revision_attendue integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_version uuid;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR p_revision_attendue IS NULL
     OR p_acces IS NULL OR p_acces NOT IN ('lecture', 'telechargement') THEN
    RAISE EXCEPTION 'BibliothequeAccesInvalide' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeRetiree' USING ERRCODE = '22023';
  END IF;
  -- Un lien ne se telecharge pas.
  IF v_resource.lien_externe IS NOT NULL AND p_acces = 'telechargement' THEN
    RAISE EXCEPTION 'BibliothequeAccesInvalide' USING ERRCODE = '22023';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureEnConflit', 'revision', v_resource.revision);
  END IF;
  v_version := coalesce(v_resource.current_version_id, (
    SELECT v.id FROM public.resource_version v
     WHERE v.resource_id = p_resource_id AND v.statut = 'brouillon'
     ORDER BY v.numero_version DESC LIMIT 1));
  IF v_version IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.library_version_rights d WHERE d.resource_version_id = v_version) THEN
    RAISE EXCEPTION 'BibliothequeDroitsIntrouvables' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.library_version_rights d
     SET usages = CASE
           WHEN p_acces = 'telechargement' AND NOT ('telechargement' = ANY (d.usages))
             THEN d.usages || ARRAY['telechargement']
           WHEN p_acces = 'lecture'
             THEN pg_catalog.array_remove(d.usages, 'telechargement')
           ELSE d.usages END
   WHERE d.resource_version_id = v_version;
  -- La revision du document avance : un autre ecran ouvert verra le conflit.
  UPDATE public.library_resource r SET title = r.title WHERE r.id = p_resource_id;
  SELECT r.revision INTO v_revision FROM public.library_resource r WHERE r.id = p_resource_id;
  PERFORM public.log_sensitive_access('library_access_changed', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('resource_version_id', v_version, 'acces', p_acces));
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_revision);
END;
$function$;

ALTER FUNCTION public.library_changer_acces(uuid, text, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.library_changer_acces(uuid, text, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_changer_acces(uuid, text, integer) TO authenticated;

DO $empreinte$
DECLARE
  v_signature regprocedure;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.library_depot_direct(uuid,integer,text,text,boolean,text)'::regprocedure,
    'public.library_changer_acces(uuid,text,integer)'::regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_signature,
      pg_catalog.format('F86: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-11-13. Lot DEPOT-SIMPLE. Garde: direction active.',
        v_signature, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_signature))));
  END LOOP;
END
$empreinte$;

DO $postflight$
DECLARE
  v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.library_depot_direct(uuid,integer,text,text,boolean,text)',
    'public.library_changer_acces(uuid,text,integer)'
  ] LOOP
    IF pg_catalog.has_function_privilege('anon', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_signature, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_signature, 'EXECUTE')
       OR NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = v_signature::regprocedure
            AND p.prosecdef AND p.proowner = 'postgres'::regrole
            AND p.proconfig @> ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'DEPOT-SIMPLE : droits ou reglages incorrects pour %', v_signature;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'app_private.library_controle_version(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'DEPOT-SIMPLE : le controle interne est ouvert aux clients';
  END IF;
END
$postflight$;
