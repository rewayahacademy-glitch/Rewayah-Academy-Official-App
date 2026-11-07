-- FN-101, option B (garde-cap, 06/11/2026 22:47 ; lot suivant, preparee par le
-- lot 13 FN-DIVERS) : une piece d'identite n'entre dans `kyc_documents` que si
-- son CONTENU a ete confirme par le serveur.
--
-- Constat (UX-CONSTATS, FN-101, 31/10/2026) : 53 octets de texte nommes
-- `.pdf` passaient pour une piece d'identite. Le seau `kyc` ne verifie que le
-- type annonce (20261108400000) ; l'application insere ensuite la ligne
-- elle-meme, par les policies `kyc_staff_self_insert` et `kyc_guardian_insert`.
--
-- Ce qui change :
--   1. `private.kyc_contenus_confirmes` : une confirmation par cle d'objet,
--      posee SEULEMENT par la fonction Edge `kyc-confirme` (cle de service),
--      apres lecture des 16 premiers octets ; RLS active, aucune policy, aucun
--      droit pour les comptes ;
--   2. `public.kyc_confirmer_contenu()` : la pose, executable par
--      `service_role` seul ;
--   3. `public.kyc_contenu_confirme()` : la lecture booleenne qu'emploient les
--      policies (la cle doit avoir ete confirmee pour celui qui insere) ;
--   4. les deux policies d'insertion gardent leur condition actuelle, recopiee
--      mot pour mot apres un preflight qui la compare a pg_policies, et exigent
--      en plus la confirmation (ALTER POLICY, rien n'est retire).
--
-- Le depot par le coffre R2 n'est pas touche : `preparer_depot_piece_identite()`
-- insere sous son proprietaire, hors de ces policies, et son contenu est deja
-- controle par `piece-identite-confirme`.
--
-- FICHIER SANS EFFACEMENT (regle B5) : une table et deux fonctions creees, deux
-- policies modifiees ; aucune table, ligne, contrainte, policy ni declencheur
-- retire.

BEGIN;

CREATE TABLE IF NOT EXISTS private.kyc_contenus_confirmes (
  object_key text PRIMARY KEY,
  depose_par uuid NOT NULL,
  type_contenu text NOT NULL
    CHECK (type_contenu IN ('application/pdf', 'image/jpeg', 'image/png', 'image/heic')),
  confirme_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CHECK (pg_catalog.starts_with(object_key, depose_par::text || '/'))
);

ALTER TABLE private.kyc_contenus_confirmes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.kyc_contenus_confirmes FROM PUBLIC, anon, authenticated;

COMMENT ON TABLE private.kyc_contenus_confirmes IS
  'FN-101 (06/11/2026) : une cle d''objet du seau kyc dont les 16 premiers octets correspondent au type. Posee par la fonction Edge kyc-confirme seule ; exigee par les policies d''insertion de kyc_documents.';

-- La pose : service_role seul (la fonction Edge, apres sa lecture).
CREATE OR REPLACE FUNCTION public.kyc_confirmer_contenu(
  p_depose_par uuid,
  p_object_key text,
  p_type_contenu text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    p_depose_par IS NOT NULL
    AND p_object_key IS NOT NULL
    AND pg_catalog.starts_with(p_object_key, p_depose_par::text || '/')
    AND p_type_contenu IN ('application/pdf', 'image/jpeg', 'image/png', 'image/heic'),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'confirmation_invalide';
  END IF;

  INSERT INTO private.kyc_contenus_confirmes (object_key, depose_par, type_contenu)
  VALUES (p_object_key, p_depose_par, p_type_contenu)
  ON CONFLICT (object_key) DO NOTHING;
END;
$function$;

REVOKE ALL ON FUNCTION public.kyc_confirmer_contenu(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.kyc_confirmer_contenu(uuid, text, text) TO service_role;

-- La lecture des policies : vrai seulement pour une cle confirmee, deposee par
-- l'appelant lui-meme.
CREATE OR REPLACE FUNCTION public.kyc_contenu_confirme(p_object_key text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
        FROM private.kyc_contenus_confirmes c
       WHERE c.object_key = p_object_key
         AND c.depose_par = auth.uid()
    ),
    false
  );
$function$;

REVOKE ALL ON FUNCTION public.kyc_contenu_confirme(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kyc_contenu_confirme(text) TO authenticated;

-- Les policies d'insertion. Leur condition actuelle est celle que
-- 20261017120100 a reecrite (garde positive pending_kyc / provisional_active /
-- active, access_until, app_role() evalue une fois), lue dans pg_policies
-- apres toutes les migrations et relue en production par le garde-cap le
-- 06/11/2026. Un ALTER POLICY ... WITH CHECK remplace toute l'expression : elle
-- est donc recopiee mot pour mot, plus la confirmation du contenu.
--
-- Preflight : si la condition en base n'est pas exactement celle-ci, rien
-- n'est change (l'exception annule toute la transaction).
DO $preflight$
DECLARE
  v_staff text;
  v_tuteur text;
BEGIN
  SELECT with_check INTO v_staff FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND tablename = 'kyc_documents' AND policyname = 'kyc_staff_self_insert';
  SELECT with_check INTO v_tuteur FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND tablename = 'kyc_documents' AND policyname = 'kyc_guardian_insert';
  IF v_staff IS DISTINCT FROM $attendu$COALESCE(((profile_id = auth.uid()) AND (( SELECT app_role() AS app_role) = ANY (ARRAY['teacher'::app_role, 'controller'::app_role])) AND (EXISTS ( SELECT 1
   FROM profiles pv
  WHERE ((pv.id = auth.uid()) AND ((pv.account_status = ANY (ARRAY['pending_kyc'::account_status, 'provisional_active'::account_status, 'active'::account_status])) AND ((pv.access_until IS NULL) OR (pv.access_until > now()))) AND (pv.deleted_at IS NULL))))), false)$attendu$ THEN
    RAISE EXCEPTION 'FN-101 preflight : kyc_staff_self_insert differe du texte attendu : %', v_staff;
  END IF;
  IF v_tuteur IS DISTINCT FROM $attendu$COALESCE(((( SELECT app_role() AS app_role) = 'guardian'::app_role) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = kyc_documents.profile_id) AND (p.household_id = app_household_id()) AND (p.deleted_at IS NULL)))) AND (EXISTS ( SELECT 1
   FROM profiles pv
  WHERE ((pv.id = auth.uid()) AND ((pv.account_status = ANY (ARRAY['pending_kyc'::account_status, 'provisional_active'::account_status, 'active'::account_status])) AND ((pv.access_until IS NULL) OR (pv.access_until > now()))) AND (pv.deleted_at IS NULL))))), false)$attendu$ THEN
    RAISE EXCEPTION 'FN-101 preflight : kyc_guardian_insert differe du texte attendu : %', v_tuteur;
  END IF;
END
$preflight$;

ALTER POLICY kyc_staff_self_insert ON public.kyc_documents
  WITH CHECK ((COALESCE(((profile_id = auth.uid()) AND (( SELECT app_role() AS app_role) = ANY (ARRAY['teacher'::app_role, 'controller'::app_role])) AND (EXISTS ( SELECT 1
   FROM profiles pv
  WHERE ((pv.id = auth.uid()) AND ((pv.account_status = ANY (ARRAY['pending_kyc'::account_status, 'provisional_active'::account_status, 'active'::account_status])) AND ((pv.access_until IS NULL) OR (pv.access_until > now()))) AND (pv.deleted_at IS NULL))))), false))
    AND public.kyc_contenu_confirme(object_key));

ALTER POLICY kyc_guardian_insert ON public.kyc_documents
  WITH CHECK ((COALESCE(((( SELECT app_role() AS app_role) = 'guardian'::app_role) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = kyc_documents.profile_id) AND (p.household_id = app_household_id()) AND (p.deleted_at IS NULL)))) AND (EXISTS ( SELECT 1
   FROM profiles pv
  WHERE ((pv.id = auth.uid()) AND ((pv.account_status = ANY (ARRAY['pending_kyc'::account_status, 'provisional_active'::account_status, 'active'::account_status])) AND ((pv.access_until IS NULL) OR (pv.access_until > now()))) AND (pv.deleted_at IS NULL))))), false))
    AND public.kyc_contenu_confirme(object_key));

-- Postflight : droits et policies tels qu'annonces.
DO $postflight$
BEGIN
  IF has_function_privilege('authenticated', 'public.kyc_confirmer_contenu(uuid, text, text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.kyc_confirmer_contenu(uuid, text, text)', 'EXECUTE')
     OR NOT has_function_privilege('service_role', 'public.kyc_confirmer_contenu(uuid, text, text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-101 : droits de kyc_confirmer_contenu inattendus';
  END IF;
  IF has_function_privilege('anon', 'public.kyc_contenu_confirme(text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.kyc_contenu_confirme(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-101 : droits de kyc_contenu_confirme inattendus';
  END IF;
  IF has_table_privilege('authenticated', 'private.kyc_contenus_confirmes', 'SELECT')
     OR has_table_privilege('authenticated', 'private.kyc_contenus_confirmes', 'INSERT') THEN
    RAISE EXCEPTION 'FN-101 : la table des confirmations est ouverte aux comptes';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_policies
       WHERE schemaname = 'public' AND tablename = 'kyc_documents'
         AND policyname IN ('kyc_staff_self_insert', 'kyc_guardian_insert')
         AND pg_catalog.strpos(with_check, 'kyc_contenu_confirme') > 0) <> 2 THEN
    RAISE EXCEPTION 'FN-101 : les deux policies d''insertion n''exigent pas la confirmation';
  END IF;
  -- La garde positive du compte est restee : aucun compte suspendu, supprime ou
  -- expire ne retrouve le depot.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_policies
       WHERE schemaname = 'public' AND tablename = 'kyc_documents'
         AND policyname IN ('kyc_staff_self_insert', 'kyc_guardian_insert')
         AND pg_catalog.strpos(with_check, 'access_until') > 0
         AND pg_catalog.strpos(with_check, 'provisional_active') > 0
         AND pg_catalog.strpos(with_check, '<> ''disabled''') = 0) <> 2 THEN
    RAISE EXCEPTION 'FN-101 : la garde positive du compte a disparu d''une policy d''insertion';
  END IF;
END
$postflight$;

COMMIT;
