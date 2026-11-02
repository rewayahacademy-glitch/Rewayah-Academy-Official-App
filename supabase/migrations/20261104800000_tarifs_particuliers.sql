-- Lot (A), fichier 2 sur 2 (02/11/2026) : « Accès offert » et « Prix spécial »,
-- accordes par la direction, eleve par eleve, avec une raison et un mois de fin
-- obligatoires. Le fichier 1 (20261104700000) rend pour_mille facultatif.
--
-- Demande du directeur (02/11) : « certains ne vont pas payer, on doit pouvoir
-- les donner acces ; certains ont des prix speciaux, nos eleves actuels [...]
-- il ne faut pas que l'app le bloque automatiquement » ; « coder en dur sera
-- catastrophique » : aucun montant ni pourcentage n'est ecrit ici, la direction
-- les saisit dans l'application. Ordres du pilote du 02/11 : reutiliser
-- bourses_eleves, fac_bourse_couvre et la ligne « bourse » de la facture ; ces
-- gestes ne comptent pas dans le quota des bourses et ne suivent pas la
-- politique ; un prix special se dit en pour mille OU en montant mensuel hors
-- taxes, strictement inferieur au tarif de l'eleve.
--
-- Inventaire des lecteurs de bourses_eleves.pour_mille et de ce qu'ils font
-- d'une remise en montant (pour_mille absent) :
-- - private.fac_bourse : rend la ligne telle quelle ;
-- - private.fac_mensualite (20261018120000_fac_e) : calculait
--   greatest(tarif + NULL, 0) = 0, une facture a 0 ; CORRIGE en 3 : le montant
--   devient le prix du mois, jamais plus que le tarif ; la ligne dit aussi
--   la nature de la remise (champ « remise ») ;
-- - private.fac_bourse_couvre (20261018170000_fac_f) : pour_mille >= 1000 est
--   faux, un montant ne couvre jamais le mois (relances et suspension
--   normales) ; un montant de 0 est refuse (c'est un acces offert) ;
-- - private.acces_lever_par_bourse (lot B) : NEW.pour_mille < 1000 valait NULL
--   et la suspension se levait ; CORRIGE en 4 ;
-- - private.fac_prix_prepaiement : une remise active ferme le prepaiement
--   (non cumulable), inchange ;
-- - public.accorder_bourse : ecrit toujours un pour_mille (politique) ; son
--   quota ne compte plus que les bourses (2) ;
-- - public.retirer_bourse : ne lit pas pour_mille ;
-- - public.bourses_lister : rendait pourMille NULL ; rend aussi le montant (6) ;
-- - public.mes_donnees_export (20261018150000_cpt) : exportait pour_mille
--   NULL ; exporte aussi nature, montant et devise (7) ;
-- - cote Dart, seul l'adaptateur des tarifs particuliers lit cette table
--   (`tarifs_particuliers_supabase.dart`) ; les autres « pourMille » de
--   l'application sont ceux des politiques commerciales.
--
-- Aucun mot de suppression dans ce fichier.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La nature d'une remise, et sa valeur : pour mille ou montant mensuel.
-- ---------------------------------------------------------------------------
ALTER TABLE public.bourses_eleves
  ADD COLUMN nature text NOT NULL DEFAULT 'bourse'
    CONSTRAINT bourses_eleves_nature_check
    CHECK (nature IN ('bourse', 'acces_offert', 'prix_special')),
  ADD COLUMN montant_mineur bigint
    CONSTRAINT bourses_eleves_montant_positif CHECK (montant_mineur > 0),
  ADD COLUMN devise text
    CONSTRAINT bourses_eleves_devise_format CHECK (devise ~ '^[A-Z]{3}$');
ALTER TABLE public.bourses_eleves
  ADD CONSTRAINT bourses_eleves_une_valeur
    CHECK ((pour_mille IS NULL) <> (montant_mineur IS NULL)),
  ADD CONSTRAINT bourses_eleves_devise_du_montant
    CHECK ((montant_mineur IS NULL) = (devise IS NULL)),
  ADD CONSTRAINT bourses_eleves_montant_prix_special
    CHECK (montant_mineur IS NULL OR nature = 'prix_special'),
  ADD CONSTRAINT bourses_eleves_offert_complet
    CHECK (nature <> 'acces_offert' OR pour_mille = 1000);
COMMENT ON COLUMN public.bourses_eleves.nature IS
  'Lot A (02/11/2026) : bourse (politique, quota, duree de la politique) ; acces_offert (100 %, mois de fin choisi) ; prix_special (pour mille ou montant mensuel choisis, mois de fin choisi). Saisis par la direction ; jamais en dur.';
COMMENT ON COLUMN public.bourses_eleves.montant_mineur IS
  'Lot A (02/11/2026) : prix special en montant mensuel hors taxes, en unites mineures de [devise] : le prix du mois, jamais plus que le tarif de l''eleve. Exclusif de pour_mille.';

-- Remplace [p_ancre] par [p_neuf] dans la definition actuelle de [p_fonction],
-- une seule fois, puis la recree et rafraichit l'empreinte F86 de son
-- commentaire. Echoue si l'ancre manque ou revient (fonction changee depuis).
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'Lot A : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. Le quota des bourses ne compte que les bourses.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.accorder_bourse(uuid,text)'::regprocedure,
$a$  SELECT count(*) INTO v_actives FROM public.bourses_eleves b
   WHERE b.retiree_le IS NULL AND b.mois_fin >= v_mois;$a$,
$b$  SELECT count(*) INTO v_actives FROM public.bourses_eleves b
   WHERE b.retiree_le IS NULL AND b.mois_fin >= v_mois
     -- Lot A, 02/11/2026 : acces offerts et prix speciaux hors quota.
     AND b.nature = 'bourse';$b$);

-- ---------------------------------------------------------------------------
-- 3. La facture du mois : un prix special en montant est le prix du mois.
-- ---------------------------------------------------------------------------
-- La ligne « bourse » dit l'ecart avec le tarif, comme pour une reduction en
-- pour mille, et porte desormais « remise » (acces_offert, prix_special ;
-- absente pour une bourse) : sans elle, la famille lisait « Bourse Rewayah » pour un
-- acces offert ou un prix special. Si le tarif baisse sous le montant, le tarif s'applique (ligne
-- a 0). Un montant saisi dans une autre devise que la politique du mois ne
-- s'applique pas : la facture garde le tarif, rien n'est converti.
SELECT pg_temp.remplacer(
  'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure,
$a$    v_remise := -((v_tarif * v_bourse.pour_mille + 500) / 1000);
    v_base := greatest(v_tarif + v_remise, 0);
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', 'bourse', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', NULL));$a$,
$b$    IF v_bourse.montant_mineur IS NOT NULL THEN
      -- Lot A, 02/11/2026 : prix special en montant mensuel hors taxes.
      v_base := CASE WHEN v_bourse.devise = p.devise
                     THEN least(v_bourse.montant_mineur, v_tarif) ELSE v_tarif END;
    ELSE
      v_remise := -((v_tarif * v_bourse.pour_mille + 500) / 1000);
      v_base := greatest(v_tarif + v_remise, 0);
    END IF;
    -- Lot A : « remise » dit a la famille ce qu'est la ligne (acces offert,
    -- prix special) ; « nature » reste « bourse » pour les lecteurs, et la
    -- ligne d'une bourse de la politique ne change pas.
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', 'bourse', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', NULL)
      || CASE WHEN v_bourse.nature = 'bourse' THEN '{}'::jsonb
              ELSE pg_catalog.jsonb_build_object('remise', v_bourse.nature) END);$b$);

-- ---------------------------------------------------------------------------
-- 4. Lot B : seule une remise de 100 % leve une suspension.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('private.acces_lever_par_bourse()'::regprocedure,
  $a$NEW.pour_mille < 1000$a$,
  $b$NEW.pour_mille IS NULL OR NEW.pour_mille < 1000$b$);

-- ---------------------------------------------------------------------------
-- 5. Accorder un acces offert ou un prix special.
-- ---------------------------------------------------------------------------
-- [p_nature] : 'acces_offert' (100 %, reduction et montant ignores) ou
-- 'prix_special' : exactement un de [p_pour_mille] (1 a 999, la reduction en
-- pour mille du tarif) et [p_montant_mineur] (le prix du mois hors taxes, en
-- unites mineures de la devise de la politique du mois, de 1 au tarif de
-- l'eleve exclu). [p_mois_fin] : le dernier mois couvert, premier jour du
-- mois, au plus tot le mois courant. Une seule remise active par eleve : la
-- remise en cours se retire d'abord (retirer_bourse).
-- Refus : 42501 pas la direction ; 22023 valeur invalide ; BO002 remise deja
-- active ; BO003 montant egal ou superieur au tarif de l'eleve.
CREATE FUNCTION public.accorder_tarif_particulier(
  p_profil uuid, p_nature text, p_pour_mille integer, p_montant_mineur bigint,
  p_mois_fin date, p_motif text)
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
  v_montant bigint;
  v_devise text;
  v_pol public.politiques_commerciales;
  v_tarif bigint;
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
  IF NOT EXISTS (SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
                  WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = '22023';
  END IF;
  IF p_nature = 'acces_offert' THEN
    v_pour_mille := 1000;
  ELSIF (p_pour_mille IS NULL) = (p_montant_mineur IS NULL) THEN
    RAISE EXCEPTION 'reduction ou montant, un des deux' USING ERRCODE = '22023';
  ELSIF p_pour_mille IS NOT NULL THEN
    IF p_pour_mille < 1 OR p_pour_mille > 999 THEN
      RAISE EXCEPTION 'reduction invalide' USING ERRCODE = '22023';
    END IF;
    v_pour_mille := p_pour_mille;
  ELSE
    IF p_montant_mineur < 1 THEN
      RAISE EXCEPTION 'montant invalide (0 : acces offert)' USING ERRCODE = '22023';
    END IF;
    v_pol := private.fac_politique_au(v_mois);
    v_tarif := CASE WHEN v_pol.version IS NULL THEN NULL ELSE private.fac_tarif_profil(p_profil, v_pol) END;
    IF v_tarif IS NULL OR v_tarif < 1 THEN
      RAISE EXCEPTION 'tarif de l''eleve inconnu' USING ERRCODE = '22023';
    END IF;
    IF p_montant_mineur >= v_tarif THEN
      RAISE EXCEPTION 'montant egal ou superieur au tarif' USING ERRCODE = 'BO003';
    END IF;
    v_montant := p_montant_mineur;
    v_devise := v_pol.devise;
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('bourses', 0));
  IF EXISTS (SELECT 1 FROM public.bourses_eleves b WHERE b.profile_id = p_profil AND b.retiree_le IS NULL) THEN
    RAISE EXCEPTION 'une remise est deja active' USING ERRCODE = 'BO002';
  END IF;
  INSERT INTO public.bourses_eleves (profile_id, pour_mille, montant_mineur, devise, mois_debut, mois_fin,
                                     motif, accordee_par, nature)
  VALUES (p_profil, v_pour_mille, v_montant, v_devise, v_mois, p_mois_fin, v_motif, auth.uid(), p_nature)
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access('tarif_particulier_accorde', 'bourses_eleves', v_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'nature', p_nature, 'pour_mille', v_pour_mille,
      'montant_mineur', v_montant, 'devise', v_devise,
      'mois_fin', pg_catalog.to_char(p_mois_fin, 'YYYY-MM-DD')));
  RETURN (SELECT x FROM pg_catalog.jsonb_array_elements(public.bourses_lister()) x
           WHERE x ->> 'profilId' = p_profil::text LIMIT 1);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. La liste rend la nature et le montant (corps de 20261018120000_fac_e).
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
             'montantMensuel', CASE WHEN b.montant_mineur IS NULL THEN NULL
                                    ELSE private.bf1_montant(b.montant_mineur, b.devise) END,
             'moisDebut', pg_catalog.to_char(b.mois_debut, 'YYYY-MM-DD'),
             'moisFin', pg_catalog.to_char(b.mois_fin, 'YYYY-MM-DD'),
             'motif', b.motif, 'nature', b.nature) ORDER BY b.accordee_le DESC)
      FROM public.bourses_eleves b JOIN public.profiles pr ON pr.id = b.profile_id
     WHERE b.retiree_le IS NULL), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. L'export des donnees personnelles dit aussi la nature et le montant.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.mes_donnees_export()'::regprocedure,
  $a$'pour_mille', b.pour_mille, 'mois_debut', b.mois_debut,$a$,
  $b$'pour_mille', b.pour_mille, 'nature', b.nature,
                 'montant_mineur', b.montant_mineur, 'devise', b.devise, 'mois_debut', b.mois_debut,$b$);

-- ---------------------------------------------------------------------------
-- 8. Droits et empreintes F86 (meme forme que 20261018120000_fac_e).
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.bourses_lister()'::regprocedure,
    'public.accorder_tarif_particulier(uuid,text,integer,bigint,date,text)'::regprocedure] LOOP
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
-- 9. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.accorder_bourse(uuid,text)'::regprocedure),
                       $q$b.nature = 'bourse'$q$) = 0 THEN
    RAISE EXCEPTION 'Lot A : le quota des bourses compte encore les tarifs particuliers';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure),
       'v_bourse.montant_mineur') = 0 THEN
    RAISE EXCEPTION 'Lot A : la facture ne lit pas le montant mensuel';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.acces_lever_par_bourse()'::regprocedure),
       'NEW.pour_mille IS NULL OR NEW.pour_mille < 1000') = 0 THEN
    RAISE EXCEPTION 'Lot A : un montant leverait une suspension';
  END IF;
  IF pg_catalog.has_function_privilege('anon',
       'public.accorder_tarif_particulier(uuid,text,integer,bigint,date,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Lot A : accorder_tarif_particulier ouvert a anon';
  END IF;
  IF (SELECT count(*) FROM pg_catalog.pg_constraint
       WHERE conrelid = 'public.bourses_eleves'::regclass
         AND conname IN ('bourses_eleves_une_valeur', 'bourses_eleves_devise_du_montant',
                         'bourses_eleves_montant_prix_special', 'bourses_eleves_offert_complet',
                         'bourses_eleves_montant_positif')) <> 5 THEN
    RAISE EXCEPTION 'Lot A : contraintes de bourses_eleves incompletes';
  END IF;
  -- Les empreintes F86 des fonctions retouchees sont a jour.
  FOREACH f IN ARRAY ARRAY[
    'public.accorder_bourse(uuid,text)'::regprocedure,
    'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure,
    'public.mes_donnees_export()'::regprocedure] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%'
       AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
      RAISE EXCEPTION 'Lot A : empreinte F86 perimee pour %', f;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
