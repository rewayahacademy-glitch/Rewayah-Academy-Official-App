-- SUPPRIMER, partie serveur (demande du directeur du 03/11/2026, 17:50 UTC,
-- portee par le pilote ; plan accepte a 18:00) : la direction retire une
-- selection de comptes, un tuteur retire le profil d'un enfant de son foyer.
-- Le directeur doit pouvoir retirer ses profils de test.
--
-- Ce qui existe et est reutilise tel quel (CPT-SUPPR-EXPORT, 20261018150000,
-- corps identiques en production, preflight du 03/11/2026 18:05 UTC) :
--   * private.cpt_anonymiser(p) : nom « Compte supprime », genre, photos,
--     appareils, jetons, moyens de paiement, invitations, auth.users (courriel,
--     telephone, banni), identites et sessions de connexion. Le matricule et
--     toutes les lignes financieres sont GARDES. Il n'est pas reecrit ici ;
--   * public.log_sensitive_access : le journal d'audit chaine.
--
-- Ce que cette migration ajoute :
--   1. la cle `compte.anonymisation_delai_jours` (30 jours, PROPOSE, en
--      attente du juriste, CAND-Q21 ; reglable par la direction) ;
--   2. private.retraits_comptes, le journal des retraits (qui, par qui, d'ou,
--      quand, l'echeance et la date de l'anonymisation), en ajout seul pour
--      les clients : aucune politique, aucun droit client ;
--   3. private.suppr_retirer : le retrait immediat. Le profil sort des listes
--      (deleted_at), le compte est desactive et banni, un eleve quitte ses
--      classes (la classe reste intacte pour les autres). Refus nommes : un
--      compte de la direction, de la comptabilite ou du controle, soi-meme, un
--      enseignant qui a des seances a venir (nommees) ;
--   4. l'anonymisation a l'echeance (private.suppr_anonymiser_echus, chaque
--      heure par pg_cron quand elle existe), ou tout de suite pour la
--      direction ;
--   5. public.direction_supprimer_comptes(ids, motif, anonymiser_maintenant) :
--      la direction en double verification (aal2), un resultat par identifiant,
--      200 au plus par appel ;
--   6. public.tuteur_supprimer_profil_enfant(eleve) : un tuteur, pour un eleve
--      mineur de son propre foyer ; refus `profil_hors_foyer` sinon.
--
-- Aucune ecriture comptable n'est touchee : factures, paiements, mouvements de
-- tresorerie, contrats signes et journal d'audit restent en ajout seul.
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun mot d'effacement dans ce fichier.
-- Le seul effacement du parcours est celui, deja installe, de
-- private.cpt_anonymiser (jetons d'appareil, disponibilites, identites et
-- sessions de connexion), appele et non recopie.

BEGIN;

-- 1. Le delai ------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
VALUES ('compte.anonymisation_delai_jours', '30'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- 2. Le journal des retraits ---------------------------------------------------
CREATE TABLE private.retraits_comptes (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  role_au_retrait text NOT NULL,
  source text NOT NULL CHECK (source IN ('direction', 'tuteur')),
  acteur uuid NOT NULL REFERENCES public.profiles(id),
  motif text CHECK (motif IS NULL OR pg_catalog.char_length(motif) <= 500),
  retire_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  anonymiser_le timestamptz NOT NULL,
  anonymise_le timestamptz,
  CONSTRAINT retraits_comptes_echeance CHECK (anonymiser_le >= retire_le),
  CONSTRAINT retraits_comptes_anonymise CHECK (anonymise_le IS NULL OR anonymise_le >= retire_le)
);
CREATE UNIQUE INDEX retraits_comptes_un_par_profil ON private.retraits_comptes (profile_id);
CREATE INDEX retraits_comptes_a_anonymiser ON private.retraits_comptes (anonymiser_le)
  WHERE anonymise_le IS NULL;
COMMENT ON TABLE private.retraits_comptes IS
  'SUPPRIMER (03/11/2026) : un retrait de compte par la direction ou par un tuteur, et son anonymisation a l''echeance. Delai : app_config compte.anonymisation_delai_jours, 30 jours PROPOSE, en attente du juriste (CAND-Q21).';
ALTER TABLE private.retraits_comptes ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.retraits_comptes OWNER TO postgres;
REVOKE ALL ON TABLE private.retraits_comptes FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. Le retrait ----------------------------------------------------------------
-- Rend { id, statut: 'retire' | 'refuse', raison?, seances?, retrait_id?,
-- anonymiser_le? }. Ne leve pas d'erreur pour un refus : la direction retire
-- une selection, un refus ne doit pas annuler les autres.
CREATE FUNCTION private.suppr_retirer(p_profil uuid, p_acteur uuid, p_source text, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_p public.profiles%ROWTYPE;
  v_delai integer;
  v_seances jsonb;
  v_retrait uuid;
  v_echeance timestamptz;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = p_profil FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'introuvable');
  END IF;
  IF v_p.deleted_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'deja_retire');
  END IF;
  IF p_profil = p_acteur THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'soi_meme');
  END IF;
  IF v_p.role::text IN ('admin', 'controller', 'accountant') THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'compte_direction');
  END IF;

  -- Un enseignant qui a encore des seances a venir : on les nomme.
  SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'session_id', s.id, 'debut', s.started_at, 'groupe_id', s.groupe_id) ORDER BY s.started_at)
    INTO v_seances
    FROM public.sessions s
   WHERE s.teacher_id = p_profil
     AND s.deleted_at IS NULL
     AND s.status = 'planned'
     AND s.started_at > v_maintenant;
  IF v_seances IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse',
      'raison', 'seances_a_venir', 'seances', v_seances);
  END IF;

  -- Un eleve quitte ses classes ; la classe reste ouverte pour les autres.
  UPDATE public.groupe_membres gm
     SET left_at = v_maintenant, left_by = p_acteur, left_reason = 'compte retire'
   WHERE gm.student_id = p_profil AND gm.left_at IS NULL;

  UPDATE public.profiles
     SET deleted_at = v_maintenant, account_status = 'disabled', access_until = v_maintenant
   WHERE id = p_profil;

  -- Plus de connexion : le compte est banni (colonne lue au catalogue, le
  -- schema auth est celui de Supabase).
  IF EXISTS (SELECT 1 FROM information_schema.columns c
              WHERE c.table_schema = 'auth' AND c.table_name = 'users' AND c.column_name = 'banned_until') THEN
    EXECUTE pg_catalog.format('UPDATE auth.users SET banned_until = ''infinity''::timestamptz WHERE id = %L', p_profil);
  END IF;

  v_delai := greatest(0, coalesce((SELECT (a.value #>> '{}')::integer FROM public.app_config a
                                     WHERE a.key = 'compte.anonymisation_delai_jours'), 30));
  v_echeance := v_maintenant + pg_catalog.make_interval(days => v_delai);
  INSERT INTO private.retraits_comptes (profile_id, role_au_retrait, source, acteur, motif, retire_le, anonymiser_le)
  VALUES (p_profil, v_p.role::text, p_source, p_acteur, nullif(pg_catalog.btrim(p_motif), ''), v_maintenant, v_echeance)
  RETURNING id INTO v_retrait;

  PERFORM public.log_sensitive_access('compte_retire', 'retraits_comptes', v_retrait::text,
    pg_catalog.jsonb_build_object('profil_id', p_profil, 'source', p_source, 'role', v_p.role::text));
  RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'retire',
    'retrait_id', v_retrait, 'anonymiser_le', v_echeance);
END;
$function$;

-- 4. L'anonymisation -----------------------------------------------------------
CREATE FUNCTION private.suppr_anonymiser(p_retrait uuid)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_r private.retraits_comptes%ROWTYPE;
BEGIN
  SELECT r.* INTO v_r FROM private.retraits_comptes r WHERE r.id = p_retrait FOR UPDATE;
  IF NOT FOUND OR v_r.anonymise_le IS NOT NULL THEN
    RETURN false;
  END IF;
  PERFORM private.cpt_anonymiser(v_r.profile_id);
  UPDATE private.retraits_comptes SET anonymise_le = pg_catalog.clock_timestamp() WHERE id = p_retrait;
  PERFORM public.log_sensitive_access('compte_anonymise', 'retraits_comptes', p_retrait::text,
    pg_catalog.jsonb_build_object('profil_id', v_r.profile_id, 'source', v_r.source));
  RETURN true;
END;
$function$;

-- Les retraits echus, anonymises un par un (un echec n'arrete pas les autres).
CREATE FUNCTION private.suppr_anonymiser_echus()
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_n integer := 0;
BEGIN
  FOR v_id IN
    SELECT r.id FROM private.retraits_comptes r
     WHERE r.anonymise_le IS NULL AND r.anonymiser_le <= pg_catalog.clock_timestamp()
     ORDER BY r.anonymiser_le
     LIMIT 500
  LOOP
    BEGIN
      IF private.suppr_anonymiser(v_id) THEN
        v_n := v_n + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'SUPPRIMER : anonymisation du retrait % en echec : %', v_id, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- 5. La direction --------------------------------------------------------------
CREATE FUNCTION public.direction_supprimer_comptes(
  p_ids uuid[],
  p_motif text DEFAULT NULL,
  p_anonymiser_maintenant boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_r jsonb;
  v_resultats jsonb := '[]'::jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'suppression reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  IF p_ids IS NULL OR pg_catalog.cardinality(p_ids) = 0 THEN
    RAISE EXCEPTION 'selection_vide' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.cardinality(p_ids) > 200 THEN
    RAISE EXCEPTION 'selection_trop_grande' USING ERRCODE = '22023';
  END IF;
  IF p_motif IS NOT NULL AND pg_catalog.char_length(p_motif) > 500 THEN
    RAISE EXCEPTION 'motif_trop_long' USING ERRCODE = '22023';
  END IF;

  FOR v_id IN SELECT DISTINCT x FROM pg_catalog.unnest(p_ids) AS x WHERE x IS NOT NULL ORDER BY 1 LOOP
    BEGIN
      v_r := private.suppr_retirer(v_id, auth.uid(), 'direction', p_motif);
      IF v_r ->> 'statut' = 'retire' AND p_anonymiser_maintenant THEN
        PERFORM private.suppr_anonymiser((v_r ->> 'retrait_id')::uuid);
        v_r := v_r || pg_catalog.jsonb_build_object('anonymise', true);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_r := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'refuse', 'raison', 'erreur');
    END;
    v_resultats := v_resultats || pg_catalog.jsonb_build_array(v_r);
  END LOOP;
  RETURN v_resultats;
END;
$function$;

-- 6. Le tuteur -----------------------------------------------------------------
CREATE FUNCTION public.tuteur_supprimer_profil_enfant(p_eleve uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid;
  v_r jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'guardian'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'suppression reservee au tuteur du foyer' USING ERRCODE = '42501';
  END IF;
  SELECT p.household_id INTO v_foyer
    FROM public.profiles p
   WHERE p.id = auth.uid() AND p.deleted_at IS NULL AND p.household_id IS NOT NULL;
  -- Un eleve mineur, vivant, de son propre foyer ; jamais soi-meme, jamais un
  -- eleve adulte autonome (il decide pour lui-meme).
  IF NOT coalesce(v_foyer IS NOT NULL AND p_eleve IS NOT NULL AND p_eleve <> auth.uid() AND EXISTS (
       SELECT 1
         FROM public.profiles e
         JOIN public.student_profiles sp ON sp.profile_id = e.id
        WHERE e.id = p_eleve
          AND e.household_id = v_foyer
          AND e.role = 'student'
          AND e.deleted_at IS NULL
          AND sp.student_type IS DISTINCT FROM 'autonomous'), false) THEN
    RAISE EXCEPTION 'profil_hors_foyer' USING ERRCODE = '42501';
  END IF;

  v_r := private.suppr_retirer(p_eleve, auth.uid(), 'tuteur', NULL);
  IF v_r ->> 'statut' <> 'retire' THEN
    RAISE EXCEPTION '%', coalesce(v_r ->> 'raison', 'refuse') USING ERRCODE = '55000';
  END IF;
  RETURN v_r - 'retrait_id';
END;
$function$;

-- Droits ----------------------------------------------------------------------
ALTER FUNCTION private.suppr_retirer(uuid, uuid, text, text) OWNER TO postgres;
ALTER FUNCTION private.suppr_anonymiser(uuid) OWNER TO postgres;
ALTER FUNCTION private.suppr_anonymiser_echus() OWNER TO postgres;
ALTER FUNCTION public.direction_supprimer_comptes(uuid[], text, boolean) OWNER TO postgres;
ALTER FUNCTION public.tuteur_supprimer_profil_enfant(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.suppr_retirer(uuid, uuid, text, text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.suppr_anonymiser(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.suppr_anonymiser_echus() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.direction_supprimer_comptes(uuid[], text, boolean) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.tuteur_supprimer_profil_enfant(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.direction_supprimer_comptes(uuid[], text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.tuteur_supprimer_profil_enfant(uuid) TO authenticated;

COMMENT ON FUNCTION public.direction_supprimer_comptes(uuid[], text, boolean) IS
  'SUPPRIMER (03/11/2026) : la direction en double verification retire une selection de comptes (200 au plus), un resultat par identifiant ; anonymisation a l''echeance ou tout de suite.';
COMMENT ON FUNCTION public.tuteur_supprimer_profil_enfant(uuid) IS
  'SUPPRIMER (03/11/2026) : un tuteur retire le profil d''un eleve mineur de son foyer ; anonymisation a l''echeance.';

-- 7. Planification, si pg_cron est installee (la CI rejoue sans elle) ----------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('anonymisation-comptes', '17 * * * *',
      'SELECT private.suppr_anonymiser_echus()')$cron$;
  ELSE
    RAISE NOTICE 'SUPPRIMER : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur : on lit le catalogue.
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.retraits_comptes'::pg_catalog.regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'private.retraits_comptes', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.retraits_comptes', 'SELECT') THEN
    RAISE EXCEPTION 'SUPPRIMER : journal des retraits expose';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.direction_supprimer_comptes(uuid[],text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.tuteur_supprimer_profil_enfant(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_supprimer_comptes(uuid[],text,boolean)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_supprimer_comptes(uuid[],text,boolean)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.tuteur_supprimer_profil_enfant(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.suppr_retirer(uuid,uuid,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.suppr_anonymiser(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.suppr_anonymiser_echus()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUPPRIMER : droits d''execution incorrects';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'compte.anonymisation_delai_jours') THEN
    RAISE EXCEPTION 'SUPPRIMER : delai d''anonymisation absent';
  END IF;
END;
$postflight$;

COMMIT;
