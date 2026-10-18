-- PE (18/10/2026) : protection des enfants, trois manques avant les tests reels.
--
-- 1. Categorie « securite d'un enfant » dans « Signaler un besoin »
--    (`student_concern`). Un signalement de cette categorie est prioritaire :
--    la direction (role admin) le lit tout de suite ; ni l'enseignant concerne
--    (pas meme celui qui l'a depose), ni la famille ne le lisent. Il n'a
--    jamais de message pour la famille et ne se transmet pas.
-- 2. Code de conduite de l'enseignant : une acceptation de plus dans
--    `contract_acceptances` (sorte `teacher_conduct_code`), meme mecanisme que
--    l'accuse d'enregistrement : ligne immuable, version et date tracees. La
--    version requise est portee par `contract_required_versions`. Le texte vit
--    dans l'application (i18n), comme celui de l'accuse.
-- 3. Responsable de la protection des enfants : deux reglages de `app_config`
--    (`protection_enfants.responsable_nom`, `protection_enfants.responsable_courriel`),
--    vides par defaut, modifiables par la seule administration (policies
--    existantes d'`app_config`), valides par un declencheur, et lus par tout
--    compte connecte par `responsable_protection_enfants()` (coordonnees d'un
--    point de contact, pas un secret).
--
-- Ce que cette migration ne fait pas : elle n'ajoute pas le code de conduite a
-- la garde d'activation d'un compte enseignant (0089). Le texte n'est pas
-- encore valide par le directeur ; l'exiger a l'activation bloquerait des
-- comptes sur un texte provisoire.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Signalement de securite d'un enfant
-- ---------------------------------------------------------------------------
-- La valeur ne peut pas etre employee dans la meme transaction que son
-- ajout : tout ce qui suit la compare par `categorie::text`.
ALTER TYPE public.concern_category ADD VALUE IF NOT EXISTS 'securite_enfant';

ALTER TABLE public.student_concern
  ADD COLUMN IF NOT EXISTS prioritaire boolean NOT NULL DEFAULT false;

ALTER TABLE public.student_concern
  ADD CONSTRAINT student_concern_securite_enfant_coherente CHECK (
    categorie::text <> 'securite_enfant'
    OR (prioritaire AND family_summary IS NULL AND transmis_le IS NULL)
  );

COMMENT ON COLUMN public.student_concern.prioritaire IS
  'PE 18/10/2026 : vrai pour la categorie securite_enfant. La direction le lit en premier ; l''enseignant et la famille ne le lisent jamais.';

-- L'enseignant ne lit plus ses signalements de securite d'un enfant : meme
-- celui qui l'a depose n'a pas a le relire ni a pouvoir le laisser lire.
DROP POLICY IF EXISTS student_concern_select_enseignant ON public.student_concern;
CREATE POLICY student_concern_select_enseignant
  ON public.student_concern
  FOR SELECT TO authenticated
  USING (
    coalesce(public.app_role() = 'teacher' AND public.app_account_valid()
      AND teacher_id = auth.uid()
      AND categorie::text <> 'securite_enfant', false)
  );

-- La famille ne lit jamais un signalement de securite d'un enfant, meme
-- transmis par erreur.
CREATE OR REPLACE VIEW public.concern_famille_v
WITH (security_barrier = true)
AS
SELECT c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a
  FROM public.student_concern c
 WHERE c.statut = 'transmis'
   AND c.family_summary IS NOT NULL
   AND c.categorie::text <> 'securite_enfant'
   AND (public.est_du_foyer(c.student_id) OR c.student_id = auth.uid());

-- Depot : la categorie est acceptee ; pour la securite d'un enfant, aucun
-- message famille n'est retenu et le signalement est prioritaire.
CREATE OR REPLACE FUNCTION public.deposer_student_concern(
  p_categorie text,
  p_groupe_id uuid,
  p_session_id uuid,
  p_academy_id text,
  p_internal_details text,
  p_family_summary text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_id uuid;
  v_result jsonb;
  v_internal text := pg_catalog.btrim(coalesce(p_internal_details, ''));
  v_securite boolean := p_categorie = 'securite_enfant';
  v_family text := CASE WHEN p_categorie = 'securite_enfant' THEN NULL
    ELSE nullif(pg_catalog.btrim(coalesce(p_family_summary, '')), '') END;
BEGIN
  IF NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'depot de signalement reserve a un enseignant actif';
  END IF;
  IF p_categorie IS NULL OR p_categorie NOT IN
    ('pedagogique', 'presence', 'technique', 'changement', 'autre', 'securite_enfant') THEN
    RAISE EXCEPTION 'categorie de signalement invalide';
  END IF;
  IF p_groupe_id IS NULL OR coalesce(pg_catalog.btrim(p_academy_id), '') = ''
     OR v_internal = '' THEN
    RAISE EXCEPTION 'groupe, eleve et note interne sont requis';
  END IF;

  SELECT p.id INTO v_student_id
    FROM public.profiles p
   WHERE p.immutable_id = pg_catalog.btrim(p_academy_id)
     AND p.deleted_at IS NULL;

  IF v_student_id IS NULL OR NOT EXISTS (
    SELECT 1
      FROM public.groupes g
      JOIN public.groupe_membres gm ON gm.groupe_id = g.id
     WHERE g.id = p_groupe_id
       AND g.teacher_id = auth.uid()
       AND g.ended_at IS NULL
       AND gm.student_id = v_student_id
       AND gm.left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'eleve ou groupe introuvable dans votre classe';
  END IF;

  IF p_session_id IS NOT NULL AND (
    NOT public.session_belongs_to_teacher(p_session_id, auth.uid())
    OR NOT EXISTS (
      SELECT 1
        FROM public.session_participants sp
       WHERE sp.session_id = p_session_id
         AND sp.profile_id = v_student_id
         AND sp.deleted_at IS NULL
    )
  ) THEN
    RAISE EXCEPTION 'seance ou eleve non autorise';
  END IF;

  INSERT INTO public.student_concern
    (categorie, groupe_id, session_id, student_id, teacher_id,
     internal_details, family_summary, prioritaire)
  VALUES
    (p_categorie::public.concern_category, p_groupe_id, p_session_id,
     v_student_id, auth.uid(), v_internal, v_family, v_securite)
  RETURNING id INTO v_id;

  PERFORM public.log_sensitive_access(
    'student_concern_depose', 'student_concern', v_id::text,
    pg_catalog.jsonb_build_object(
      'categorie', p_categorie, 'groupe_id', p_groupe_id,
      'session_id', p_session_id, 'student_id', v_student_id,
      'family_summary_present', v_family IS NOT NULL,
      'prioritaire', v_securite
    )
  );

  SELECT pg_catalog.jsonb_build_object(
    'id', c.id, 'categorie', c.categorie::text, 'groupe_id', c.groupe_id,
    'session_id', c.session_id, 'academy_id', p.immutable_id,
    'enseignant_id', c.teacher_id, 'internal_details', c.internal_details,
    'family_summary', c.family_summary, 'statut', c.statut::text,
    'cree_le', c.cree_le, 'transmis_le', c.transmis_le,
    'transmis_a', c.transmis_a::text, 'prioritaire', c.prioritaire
  ) INTO v_result
    FROM public.student_concern c
    JOIN public.profiles p ON p.id = c.student_id
   WHERE c.id = v_id;

  RETURN v_result;
END;
$function$;

-- Les signalements de l'enseignant : jamais ceux de securite d'un enfant.
CREATE OR REPLACE FUNCTION public.mes_student_concerns(p_groupe_id uuid DEFAULT NULL)
RETURNS SETOF jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture de signalements reservee a un enseignant actif';
  END IF;

  RETURN QUERY
  SELECT pg_catalog.jsonb_build_object(
    'id', c.id, 'categorie', c.categorie::text, 'groupe_id', c.groupe_id,
    'session_id', c.session_id, 'academy_id', p.immutable_id,
    'enseignant_id', c.teacher_id, 'internal_details', c.internal_details,
    'family_summary', c.family_summary, 'statut', c.statut::text,
    'cree_le', c.cree_le, 'transmis_le', c.transmis_le,
    'transmis_a', c.transmis_a::text
  )
    FROM public.student_concern c
    JOIN public.profiles p ON p.id = c.student_id
   WHERE c.teacher_id = auth.uid()
     AND c.categorie::text <> 'securite_enfant'
     AND (p_groupe_id IS NULL OR c.groupe_id = p_groupe_id)
   ORDER BY c.cree_le DESC, c.id DESC;
END;
$function$;

-- La transmission refuse un signalement de securite d'un enfant.
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

-- La file de la direction : les signalements de securite d'un enfant d'abord,
-- puis les autres, du plus recent au plus ancien. Seuls les signalements non
-- clos y figurent.
CREATE FUNCTION public.signalements_ouverts_direction()
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
    'id', c.id, 'categorie', c.categorie::text, 'prioritaire', c.prioritaire,
    'groupe_id', c.groupe_id, 'session_id', c.session_id,
    'academy_id', p.immutable_id, 'enseignant_id', c.teacher_id,
    'internal_details', c.internal_details, 'statut', c.statut::text,
    'cree_le', c.cree_le
  )
    FROM public.student_concern c
    JOIN public.profiles p ON p.id = c.student_id
   WHERE c.statut <> 'clos'
   ORDER BY c.prioritaire DESC, c.cree_le DESC, c.id DESC;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Code de conduite de l'enseignant
-- ---------------------------------------------------------------------------
DO $contraintes$
DECLARE
  v_nom text;
BEGIN
  SELECT c.conname INTO v_nom
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.contract_acceptances'::regclass
     AND c.contype = 'c'
     AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%recording_and_control_notice%';
  IF v_nom IS NULL THEN
    RAISE EXCEPTION 'PE : contrainte de contract_acceptances.contract_kind introuvable';
  END IF;
  EXECUTE pg_catalog.format('ALTER TABLE public.contract_acceptances DROP CONSTRAINT %I', v_nom);
  ALTER TABLE public.contract_acceptances
    ADD CONSTRAINT contract_acceptances_contract_kind_check CHECK (contract_kind IN (
      'guardian_terms', 'teacher_nda', 'recording_and_control_notice',
      'teacher_conduct_code'));

  SELECT c.conname INTO v_nom
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.contract_required_versions'::regclass
     AND c.contype = 'c'
     AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%recording_and_control_notice%';
  IF v_nom IS NULL THEN
    RAISE EXCEPTION 'PE : contrainte de contract_required_versions.contract_kind introuvable';
  END IF;
  EXECUTE pg_catalog.format('ALTER TABLE public.contract_required_versions DROP CONSTRAINT %I', v_nom);
  ALTER TABLE public.contract_required_versions
    ADD CONSTRAINT contract_required_versions_contract_kind_check CHECK (
      contract_kind IN ('recording_and_control_notice', 'teacher_conduct_code'));
END;
$contraintes$;

INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('teacher_conduct_code', '2026-10-cond')
ON CONFLICT (contract_kind) DO NOTHING;

-- La version requise du code de conduite, lue par la policy d'insertion (une
-- policy s'execute avec les droits de l'appelant, qui ne lit pas la table).
CREATE FUNCTION public.code_conduite_version_requise()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT r.version
    FROM public.contract_required_versions r
   WHERE r.contract_kind = 'teacher_conduct_code';
$function$;

-- Seul un enseignant accepte le code de conduite, et seulement la version
-- requise. Les autres sortes gardent leurs propres policies (0086).
CREATE POLICY contract_acceptances_code_conduite_enseignant
  ON public.contract_acceptances
  AS RESTRICTIVE
  FOR INSERT TO authenticated
  WITH CHECK (
    contract_kind <> 'teacher_conduct_code'
    OR coalesce(
      public.app_role() = 'teacher'::public.app_role
      AND version = public.code_conduite_version_requise(),
      false)
  );

-- ---------------------------------------------------------------------------
-- 3. Responsable de la protection des enfants (reglage de l'administration)
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('protection_enfants.responsable_nom', '""'::jsonb),
  ('protection_enfants.responsable_courriel', '""'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Une valeur de ces deux reglages est un texte court : le nom (120 signes au
-- plus, sans caractere de commande), le courriel (vide, ou une adresse
-- plausible de 254 signes au plus). La valeur est rangee sans espaces autour.
CREATE FUNCTION private.pe_valider_responsable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_texte text;
BEGIN
  IF NEW.key NOT IN ('protection_enfants.responsable_nom',
                     'protection_enfants.responsable_courriel') THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'string' THEN
    RAISE EXCEPTION 'reglage de protection des enfants : un texte est attendu';
  END IF;
  v_texte := pg_catalog.btrim(NEW.value #>> '{}');
  IF v_texte ~ '[[:cntrl:]]' THEN
    RAISE EXCEPTION 'reglage de protection des enfants : caractere interdit';
  END IF;
  IF NEW.key = 'protection_enfants.responsable_nom' THEN
    IF pg_catalog.char_length(v_texte) > 120 THEN
      RAISE EXCEPTION 'reglage de protection des enfants : nom trop long';
    END IF;
  ELSIF v_texte <> '' AND (pg_catalog.char_length(v_texte) > 254
        OR v_texte !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') THEN
    RAISE EXCEPTION 'reglage de protection des enfants : courriel invalide';
  END IF;
  NEW.value := pg_catalog.to_jsonb(v_texte);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_pe_responsable
BEFORE INSERT OR UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION private.pe_valider_responsable();

-- Le point de contact, lu par l'ecran de signalement et par la page
-- Protection des enfants. Deux textes, vides tant que l'administration n'a rien
-- saisi : l'ecran dit alors que la direction recoit le signalement.
CREATE FUNCTION public.responsable_protection_enfants()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'nom', coalesce((SELECT c.value #>> '{}' FROM public.app_config c
                      WHERE c.key = 'protection_enfants.responsable_nom'), ''),
    'courriel', coalesce((SELECT c.value #>> '{}' FROM public.app_config c
                           WHERE c.key = 'protection_enfants.responsable_courriel'), ''));
$function$;

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
  v_garde text;
BEGIN
  REVOKE ALL ON FUNCTION private.pe_valider_responsable()
    FROM PUBLIC, anon, authenticated, service_role, agent_ro;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.deposer_student_concern(text,uuid,uuid,text,text,text)'::regprocedure,
    'public.mes_student_concerns(uuid)'::regprocedure,
    'public.transmettre_student_concern(uuid,text)'::regprocedure,
    'public.signalements_ouverts_direction()'::regprocedure,
    'public.code_conduite_version_requise()'::regprocedure,
    'public.responsable_protection_enfants()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    v_garde := CASE
      WHEN v_oid = 'public.responsable_protection_enfants()'::regprocedure THEN 'AUTHENTICATED_PUBLIC_CONTACT'
      WHEN v_oid = 'public.code_conduite_version_requise()'::regprocedure THEN 'AUTHENTICATED_PUBLIC_VERSION'
      WHEN v_oid = 'public.signalements_ouverts_direction()'::regprocedure THEN 'ROLE_POSITIVE_ADMIN'
      WHEN v_oid = 'public.transmettre_student_concern(uuid,text)'::regprocedure THEN 'ROLE_POSITIVE_ADMIN'
      ELSE 'ROLE_POSITIVE_TEACHER' END;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. PE protection des enfants.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)), v_garde));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.deposer_student_concern(text,uuid,uuid,text,text,text)'::regprocedure,
    'public.mes_student_concerns(uuid)'::regprocedure,
    'public.transmettre_student_concern(uuid,text)'::regprocedure,
    'public.signalements_ouverts_direction()'::regprocedure,
    'public.code_conduite_version_requise()'::regprocedure,
    'public.responsable_protection_enfants()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PE : droits ou search_path invalides sur %', v_oid::text;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.pe_valider_responsable()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PE : le declencheur de validation ne doit pas etre appelable';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.contract_required_versions
                  WHERE contract_kind = 'teacher_conduct_code') THEN
    RAISE EXCEPTION 'PE : version requise du code de conduite absente';
  END IF;
  IF (SELECT count(*) FROM public.app_config
       WHERE key IN ('protection_enfants.responsable_nom',
                     'protection_enfants.responsable_courriel')) <> 2 THEN
    RAISE EXCEPTION 'PE : reglages du responsable absents';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'UPDATE') THEN
    RAISE EXCEPTION 'PE : student_concern ne doit pas etre ecrivable directement';
  END IF;
END;
$postflight$;

COMMIT;
