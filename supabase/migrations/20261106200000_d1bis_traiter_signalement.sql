-- D1-bis (03/11/2026) : la direction traite un signalement d'enseignant.
--
-- Le circuit est porte par la table `student_concern` (0032, statuts ouvert,
-- en_examen, transmis, clos) ; jusqu'ici, seuls le depot (0059, PE) et la
-- transmission (`transmettre_student_concern`, PE 20261018160000) avaient une
-- fonction. Le dossier maitre (section 6, « Signalements des enseignants »)
-- demande : examiner, rediger le resume destine a la famille, le transmettre
-- au tuteur ou a l'eleve adulte, clore.
--
-- Ce que fait cette migration, en ajout seulement :
--
-- 1. Un reglage `signalements.motif_cloture_obligatoire` : la liste des
--    categories dont la cloture exige un motif. Installe avec TOUTES les
--    categories (pilote, 03/11/2026, valide : un motif court est obligatoire
--    pour clore, quel que soit le signalement) ; la direction peut reduire la
--    liste. Valide par un declencheur.
-- 2. `examiner_student_concern(id)` : ouvert vers en_examen.
-- 3. `rediger_resume_student_concern(id, resume)` : le resume pour la famille,
--    jamais pour un signalement de securite d'un enfant, jamais apres
--    transmission ou cloture. Jamais pre-rempli depuis la note interne.
-- 4. `transmettre_student_concern(id, cible)` : la meme fonction, remplacee
--    (meme signature), qui refuse en plus un signalement clos.
-- 5. `clore_student_concern(id, motif)` : vers clos, depuis tout autre statut ;
--    le motif est exige selon le reglage et ne va qu'au journal.
-- 6. `signalements_ouverts_direction()` : la meme file, qui rend en plus le
--    resume, la cible deduite du profil et, par ligne, ce que la direction
--    peut faire (capacites calculees ici, jamais deduites d'un role cote
--    application).
-- 7. `concern_famille_v` : la famille garde ce qui lui a ete transmis apres
--    la cloture (filtre sur `transmis_le`, plus sur le statut ; regle publiee
--    au registre 08, sans colonne clos_le). Memes colonnes.
--
-- Ordre des etapes : ouvert -> en_examen ; ouvert ou en_examen -> transmis ;
-- ouvert, en_examen ou transmis -> clos ; rien apres clos. Toute autre
-- transition est refusee. Chaque changement ecrit `log_sensitive_access`.
-- Toutes les fonctions sont reservees a un admin au compte valide.
--
-- Securite d'un enfant : decision du directeur du 03/11/2026 (vers 03:40
-- UTC), « Direction seule » : la direction examine et clot seule un
-- signalement « securite d'un enfant », sans le responsable de la protection,
-- avec le motif obligatoire garde au journal. Il ne se transmet toujours pas.
--
-- Lecteurs de `concern_famille_v` (recensement B1, 03/11/2026) : aucun ecran
-- ni fonction de l'application (`lib/`), aucune fonction Edge ; seuls les
-- scenarios `scenarios_pe_protection_enfants` et
-- `scenarios_d1bis_traiter_signalement`. Le message transmis n'est donc lu
-- par aucune famille tant qu'un ecran ne lit pas cette vue (lot a part).
--
-- Effet de bord connu, non traite ici : le poids des controles C29
-- (20261011220000) ne compte que les signalements « ouvert » ; un signalement
-- passe en examen n'y compte plus.
--
-- Aucune suppression de ligne, d'objet ni de colonne.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Reglage : categories dont la cloture exige un motif
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
SELECT 'signalements.motif_cloture_obligatoire',
       pg_catalog.to_jsonb(pg_catalog.enum_range(NULL::public.concern_category)::text[])
ON CONFLICT (key) DO NOTHING;

-- La valeur est une liste de categories connues, sans doublon.
CREATE FUNCTION private.d1bis_valider_motif_cloture()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_element jsonb;
  v_vus text[] := ARRAY[]::text[];
BEGIN
  IF NEW.key <> 'signalements.motif_cloture_obligatoire' THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'reglage du motif de cloture : une liste de categories est attendue';
  END IF;
  FOR v_element IN SELECT e FROM pg_catalog.jsonb_array_elements(NEW.value) e LOOP
    IF pg_catalog.jsonb_typeof(v_element) IS DISTINCT FROM 'string'
       OR NOT (v_element #>> '{}') = ANY (pg_catalog.enum_range(NULL::public.concern_category)::text[]) THEN
      RAISE EXCEPTION 'reglage du motif de cloture : categorie inconnue';
    END IF;
    IF (v_element #>> '{}') = ANY (v_vus) THEN
      RAISE EXCEPTION 'reglage du motif de cloture : categorie en double';
    END IF;
    v_vus := v_vus || (v_element #>> '{}');
  END LOOP;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_d1bis_motif_cloture
BEFORE INSERT OR UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION private.d1bis_valider_motif_cloture();

-- Vrai si la cloture d'un signalement de cette categorie exige un motif.
-- Reglage absent ou illisible : le motif est exige (prudence).
CREATE FUNCTION private.d1bis_motif_cloture_requis(p_categorie text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'array'
                 THEN c.value ? p_categorie END
       FROM public.app_config c
      WHERE c.key = 'signalements.motif_cloture_obligatoire'),
    true);
$function$;

-- La cible d'une transmission, deduite du profil de l'eleve, ou NULL.
CREATE FUNCTION private.d1bis_cible_transmission(p_student_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE sp.student_type::text
           WHEN 'minor' THEN 'tuteur_du_mineur'
           WHEN 'autonomous' THEN 'eleve_adulte'
         END
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.profile_id
   WHERE sp.profile_id = p_student_id
     AND sp.deleted_at IS NULL
     AND p.deleted_at IS NULL;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Examiner : ouvert -> en_examen
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.examiner_student_concern(p_concern_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_status public.concern_status;
  v_categorie text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'traitement de signalement reserve a un admin actif';
  END IF;

  SELECT c.statut, c.categorie::text INTO v_status, v_categorie
    FROM public.student_concern c
   WHERE c.id = p_concern_id
   FOR UPDATE;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'signalement introuvable';
  END IF;
  IF v_status <> 'ouvert' THEN
    RAISE EXCEPTION 'seul un signalement ouvert passe en examen';
  END IF;

  UPDATE public.student_concern
     SET statut = 'en_examen'
   WHERE id = p_concern_id;

  PERFORM public.log_sensitive_access(
    'student_concern_en_examen', 'student_concern', p_concern_id::text,
    pg_catalog.jsonb_build_object('categorie', v_categorie, 'statut_avant', v_status::text)
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Rediger le resume destine a la famille
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.rediger_resume_student_concern(
  p_concern_id uuid,
  p_resume text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_status public.concern_status;
  v_categorie text;
  v_resume text := pg_catalog.btrim(coalesce(p_resume, ''));
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'traitement de signalement reserve a un admin actif';
  END IF;

  SELECT c.statut, c.categorie::text INTO v_status, v_categorie
    FROM public.student_concern c
   WHERE c.id = p_concern_id
   FOR UPDATE;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'signalement introuvable';
  END IF;
  IF v_categorie = 'securite_enfant' THEN
    RAISE EXCEPTION 'signalement de securite d''un enfant sans message famille';
  END IF;
  IF v_status NOT IN ('ouvert', 'en_examen') THEN
    RAISE EXCEPTION 'resume modifiable avant transmission seulement';
  END IF;
  IF v_resume = '' THEN
    RAISE EXCEPTION 'resume famille vide';
  END IF;

  UPDATE public.student_concern
     SET family_summary = v_resume
   WHERE id = p_concern_id;

  PERFORM public.log_sensitive_access(
    'student_concern_resume_redige', 'student_concern', p_concern_id::text,
    pg_catalog.jsonb_build_object('categorie', v_categorie,
      'longueur', pg_catalog.char_length(v_resume))
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Transmettre : la fonction PE, qui refuse en plus un signalement clos
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.transmettre_student_concern(
  p_concern_id uuid,
  p_cible text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_family text;
  v_status public.concern_status;
  v_categorie text;
  v_student_type public.student_type;
  v_expected_target text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'transmission de signalement reservee a un admin actif';
  END IF;
  IF p_cible IS NULL OR p_cible NOT IN ('tuteur_du_mineur', 'eleve_adulte') THEN
    RAISE EXCEPTION 'cible de transmission invalide';
  END IF;

  SELECT c.student_id, c.family_summary, c.statut, c.categorie::text
    INTO v_student_id, v_family, v_status, v_categorie
    FROM public.student_concern c
   WHERE c.id = p_concern_id
   FOR UPDATE;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'signalement introuvable';
  END IF;
  IF v_categorie = 'securite_enfant' THEN
    RAISE EXCEPTION 'signalement de securite d''un enfant non transmissible';
  END IF;
  IF coalesce(pg_catalog.btrim(v_family), '') = '' THEN
    RAISE EXCEPTION 'aucun message famille a transmettre';
  END IF;
  IF v_status = 'transmis' THEN
    RAISE EXCEPTION 'signalement deja transmis';
  END IF;
  -- D1-bis : rien apres la cloture.
  IF v_status = 'clos' THEN
    RAISE EXCEPTION 'signalement clos, transmission refusee';
  END IF;

  SELECT sp.student_type INTO v_student_type
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.profile_id
   WHERE sp.profile_id = v_student_id
     AND sp.deleted_at IS NULL
     AND p.deleted_at IS NULL;
  IF v_student_type IS NULL THEN
    RAISE EXCEPTION 'profil eleve indisponible';
  END IF;

  v_expected_target := CASE v_student_type::text
    WHEN 'minor' THEN 'tuteur_du_mineur'
    WHEN 'autonomous' THEN 'eleve_adulte'
    ELSE NULL
  END;
  IF v_expected_target IS NULL OR p_cible <> v_expected_target THEN
    RAISE EXCEPTION 'cible incompatible avec le profil de l''eleve';
  END IF;

  UPDATE public.student_concern
     SET statut = 'transmis',
         transmis_le = pg_catalog.now(),
         transmis_a = p_cible::public.concern_target
   WHERE id = p_concern_id;

  PERFORM public.log_sensitive_access(
    'student_concern_transmis', 'student_concern', p_concern_id::text,
    pg_catalog.jsonb_build_object('student_id', v_student_id, 'cible', p_cible)
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Clore : ouvert, en_examen ou transmis -> clos
-- ---------------------------------------------------------------------------
-- Le motif ne va qu'au journal : ni l'enseignant ni la famille ne le lisent.
-- 1000 signes au plus : une borne technique du journal, pas une regle.
CREATE FUNCTION public.clore_student_concern(
  p_concern_id uuid,
  p_motif text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_status public.concern_status;
  v_categorie text;
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'traitement de signalement reserve a un admin actif';
  END IF;

  SELECT c.statut, c.categorie::text INTO v_status, v_categorie
    FROM public.student_concern c
   WHERE c.id = p_concern_id
   FOR UPDATE;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'signalement introuvable';
  END IF;
  IF v_status = 'clos' THEN
    RAISE EXCEPTION 'signalement deja clos';
  END IF;
  IF v_motif IS NULL AND private.d1bis_motif_cloture_requis(v_categorie) THEN
    RAISE EXCEPTION 'motif de cloture requis';
  END IF;
  IF pg_catalog.char_length(coalesce(v_motif, '')) > 1000 THEN
    RAISE EXCEPTION 'motif de cloture trop long';
  END IF;

  UPDATE public.student_concern
     SET statut = 'clos'
   WHERE id = p_concern_id;

  PERFORM public.log_sensitive_access(
    'student_concern_clos', 'student_concern', p_concern_id::text,
    pg_catalog.jsonb_build_object('categorie', v_categorie,
      'statut_avant', v_status::text, 'motif', v_motif)
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. La file de la direction, avec ce que la direction peut faire
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.signalements_ouverts_direction()
RETURNS SETOF jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction';
  END IF;

  RETURN QUERY
  SELECT pg_catalog.jsonb_build_object(
    'id', x.id, 'categorie', x.categorie, 'prioritaire', x.prioritaire,
    'groupe_id', x.groupe_id, 'session_id', x.session_id,
    'academy_id', x.academy_id, 'enseignant_id', x.teacher_id,
    'internal_details', x.internal_details, 'statut', x.statut,
    'cree_le', x.cree_le,
    'family_summary', x.family_summary, 'cible', x.cible,
    'transmis_le', x.transmis_le,
    'peut_examiner', x.statut = 'ouvert',
    'peut_rediger', x.securite = false AND x.statut IN ('ouvert', 'en_examen'),
    'peut_transmettre', x.securite = false AND x.statut IN ('ouvert', 'en_examen')
      AND coalesce(pg_catalog.btrim(x.family_summary), '') <> '' AND x.cible IS NOT NULL,
    'peut_clore', true,
    'motif_cloture_requis', private.d1bis_motif_cloture_requis(x.categorie)
  )
    FROM (
      SELECT c.id, c.categorie::text AS categorie, c.prioritaire, c.groupe_id,
             c.session_id, p.immutable_id AS academy_id, c.teacher_id,
             c.internal_details, c.statut::text AS statut, c.cree_le,
             c.family_summary, c.transmis_le,
             c.categorie::text = 'securite_enfant' AS securite,
             private.d1bis_cible_transmission(c.student_id) AS cible
        FROM public.student_concern c
        JOIN public.profiles p ON p.id = c.student_id
       WHERE c.statut <> 'clos'
    ) x
   ORDER BY x.prioritaire DESC, x.cree_le DESC, x.id DESC;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. La famille garde ce qui lui a ete transmis, meme apres la cloture
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.concern_famille_v
WITH (security_barrier = true)
AS
SELECT c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a
  FROM public.student_concern c
 WHERE c.transmis_le IS NOT NULL
   AND c.family_summary IS NOT NULL
   AND c.categorie::text <> 'securite_enfant'
   AND (public.est_du_foyer(c.student_id) OR c.student_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.d1bis_valider_motif_cloture()'::regprocedure,
    'private.d1bis_motif_cloture_requis(text)'::regprocedure,
    'private.d1bis_cible_transmission(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.examiner_student_concern(uuid)'::regprocedure,
    'public.rediger_resume_student_concern(uuid,text)'::regprocedure,
    'public.transmettre_student_concern(uuid,text)'::regprocedure,
    'public.clore_student_concern(uuid,text)'::regprocedure,
    'public.signalements_ouverts_direction()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. D1-bis traiter un signalement.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.examiner_student_concern(uuid)'::regprocedure,
    'public.rediger_resume_student_concern(uuid,text)'::regprocedure,
    'public.transmettre_student_concern(uuid,text)'::regprocedure,
    'public.clore_student_concern(uuid,text)'::regprocedure,
    'public.signalements_ouverts_direction()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'D1-bis : droits ou search_path invalides sur %', v_oid::text;
    END IF;
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'private.d1bis_valider_motif_cloture()'::regprocedure,
    'private.d1bis_motif_cloture_requis(text)'::regprocedure,
    'private.d1bis_cible_transmission(uuid)'::regprocedure] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'D1-bis : fonction privee appelable : %', v_oid::text;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM public.app_config
                  WHERE key = 'signalements.motif_cloture_obligatoire') THEN
    RAISE EXCEPTION 'D1-bis : reglage du motif de cloture absent';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'UPDATE') THEN
    RAISE EXCEPTION 'D1-bis : student_concern ne doit pas etre ecrivable directement';
  END IF;
END;
$postflight$;

COMMIT;
