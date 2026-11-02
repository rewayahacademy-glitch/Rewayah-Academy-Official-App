-- Lot (A), 02/11/2026 : « Accès offert » et « Prix spécial », accordes par la
-- direction, eleve par eleve, avec une raison et un mois de fin obligatoires.
--
-- Demande du directeur (02/11) : « certains ne vont pas payer, on doit pouvoir
-- les donner acces ; certains ont des prix speciaux, nos eleves actuels [...]
-- il ne faut pas que l'app le bloque automatiquement » ; « coder en dur sera
-- catastrophique » : aucun montant ni pourcentage n'est ecrit ici, la direction
-- les saisit dans l'application. Ordre du pilote du 02/11 : reutiliser
-- bourses_eleves, fac_bourse_couvre et la ligne « bourse » de la facture ;
-- aucun nouveau calcul de facture ; ces gestes ne comptent pas dans le quota
-- des bourses.
--
-- Ce qui existait et sert tel quel :
-- - la facture du mois retire pour_mille du tarif (ligne « bourse »,
--   20261018120000_fac_e) ; a 1000, fac_bourse_couvre empeche relance et
--   suspension (20261018170000_fac_f) ;
-- - le lot (B) leve une suspension des qu'une remise de 100 % est accordee
--   (declencheur bourses_eleves_leve_suspension) : un acces offert rouvre donc
--   tout de suite.
--
-- Aucun mot de suppression dans ce fichier.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La nature d'une remise.
-- ---------------------------------------------------------------------------
ALTER TABLE public.bourses_eleves
  ADD COLUMN nature text NOT NULL DEFAULT 'bourse'
    CONSTRAINT bourses_eleves_nature_check
    CHECK (nature IN ('bourse', 'acces_offert', 'prix_special'));
ALTER TABLE public.bourses_eleves
  ADD CONSTRAINT bourses_eleves_offert_complet
    CHECK (nature <> 'acces_offert' OR pour_mille = 1000);
COMMENT ON COLUMN public.bourses_eleves.nature IS
  'Lot A (02/11/2026) : bourse (politique, quota, duree de la politique) ; acces_offert (100 %, mois de fin choisi) ; prix_special (pour mille choisi, mois de fin choisi). Saisis par la direction ; jamais en dur.';

-- ---------------------------------------------------------------------------
-- 2. Le quota des bourses ne compte que les bourses.
-- ---------------------------------------------------------------------------
DO $quota$
DECLARE
  f regprocedure := 'public.accorder_bourse(uuid,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(f);
  v_ancre text := $a$  SELECT count(*) INTO v_actives FROM public.bourses_eleves b
   WHERE b.retiree_le IS NULL AND b.mois_fin >= v_mois;$a$;
BEGIN
  IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
    RAISE EXCEPTION 'Lot A : ancre du quota absente de accorder_bourse';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre, $b$  SELECT count(*) INTO v_actives FROM public.bourses_eleves b
   WHERE b.retiree_le IS NULL AND b.mois_fin >= v_mois
     -- Lot A, 02/11/2026 : acces offerts et prix speciaux hors quota.
     AND b.nature = 'bourse';$b$);
END;
$quota$;

-- ---------------------------------------------------------------------------
-- 3. Accorder un acces offert ou un prix special.
-- ---------------------------------------------------------------------------
-- [p_nature] : 'acces_offert' (100 %, [p_pour_mille] ignore) ou
-- 'prix_special' ([p_pour_mille] de 1 a 999 : la reduction, en pour mille du
-- tarif). [p_mois_fin] : le dernier mois couvert, premier jour du mois, au
-- plus tot le mois courant. Une seule remise active par eleve : la remise en
-- cours se retire d'abord (retirer_bourse).
CREATE FUNCTION public.accorder_tarif_particulier(
  p_profil uuid, p_nature text, p_pour_mille integer, p_mois_fin date, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_mois date := private.fac_mois_courant();
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
  v_pour_mille integer;
  v_id uuid;
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'tarif particulier reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(p_nature IN ('acces_offert', 'prix_special'), false) THEN
    RAISE EXCEPTION 'nature invalide' USING ERRCODE = '22023';
  END IF;
  IF v_motif IS NULL OR pg_catalog.length(v_motif) > 500 THEN
    RAISE EXCEPTION 'motif obligatoire' USING ERRCODE = '22023';
  END IF;
  IF p_mois_fin IS NULL OR p_mois_fin <> pg_catalog.date_trunc('month', p_mois_fin)::date
     OR p_mois_fin < v_mois THEN
    RAISE EXCEPTION 'mois de fin invalide' USING ERRCODE = '22023';
  END IF;
  v_pour_mille := CASE p_nature WHEN 'acces_offert' THEN 1000 ELSE p_pour_mille END;
  IF v_pour_mille IS NULL OR v_pour_mille < 1 OR v_pour_mille > 1000
     OR (p_nature = 'prix_special' AND v_pour_mille = 1000) THEN
    RAISE EXCEPTION 'reduction invalide' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
                  WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('bourses', 0));
  IF EXISTS (SELECT 1 FROM public.bourses_eleves b WHERE b.profile_id = p_profil AND b.retiree_le IS NULL) THEN
    RAISE EXCEPTION 'une remise est deja active' USING ERRCODE = 'BO002';
  END IF;
  INSERT INTO public.bourses_eleves (profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par, nature)
  VALUES (p_profil, v_pour_mille, v_mois, p_mois_fin, v_motif, auth.uid(), p_nature)
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access('tarif_particulier_accorde', 'bourses_eleves', v_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'nature', p_nature, 'pour_mille', v_pour_mille,
      'mois_fin', pg_catalog.to_char(p_mois_fin, 'YYYY-MM-DD')));
  RETURN (SELECT x FROM pg_catalog.jsonb_array_elements(public.bourses_lister()) x
           WHERE x ->> 'profilId' = p_profil::text LIMIT 1);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. La liste rend la nature (corps de 20261018120000_fac_e, plus « nature »).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.bourses_lister()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'bourse reservee a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'profilId', b.profile_id, 'prenom', pr.first_name, 'nom', pr.last_name,
             'matricule', pr.immutable_id, 'pourMille', b.pour_mille,
             'moisDebut', pg_catalog.to_char(b.mois_debut, 'YYYY-MM-DD'),
             'moisFin', pg_catalog.to_char(b.mois_fin, 'YYYY-MM-DD'),
             'motif', b.motif, 'nature', b.nature) ORDER BY b.accordee_le DESC)
      FROM public.bourses_eleves b JOIN public.profiles pr ON pr.id = b.profile_id
     WHERE b.retiree_le IS NULL), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Droits et empreintes F86 (meme forme que 20261018120000_fac_e).
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accorder_bourse(uuid,text)'::regprocedure,
    'public.bourses_lister()'::regprocedure,
    'public.accorder_tarif_particulier(uuid,text,integer,date,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. FAC-E-01, lot A.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

-- Remarque du pilote (02/11) sur le lot (B) : agent_ro lit session_recordings
-- sous la politique session_recordings_teacher_family, qui appelle desormais
-- private.acces_paye_seance. Sans EXECUTE, sa lecture echouerait.
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    GRANT EXECUTE ON FUNCTION private.acces_paye_seance(uuid), private.acces_paye_groupe(uuid),
      private.acces_paye_appelant() TO agent_ro;
  END IF;
END;
$agent$;

-- ---------------------------------------------------------------------------
-- 6. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.accorder_bourse(uuid,text)'::regprocedure),
                       $q$b.nature = 'bourse'$q$) = 0 THEN
    RAISE EXCEPTION 'Lot A : le quota des bourses compte encore les tarifs particuliers';
  END IF;
  IF pg_catalog.has_function_privilege('anon',
       'public.accorder_tarif_particulier(uuid,text,integer,date,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Lot A : accorder_tarif_particulier ouvert a anon';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
                  WHERE conname = 'bourses_eleves_offert_complet') THEN
    RAISE EXCEPTION 'Lot A : contrainte de l''acces offert absente';
  END IF;
END;
$postflight$;

COMMIT;
