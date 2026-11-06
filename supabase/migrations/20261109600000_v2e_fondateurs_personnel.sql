-- V2-e (04/11/2026, numero 20261109600000 reserve par garde-cap) : la lecture de la coche
-- fondateur, pour le menu de ligne des Comptes (ADM-08).
--
-- Decision du directeur (03/11/2026) : « fondateur » est une coche sur le
-- profil d'un membre du personnel, tenue par la direction ; elle ne sert qu'a
-- compter les fondateurs d'un entretien. La coche se pose par
-- poser_fondateur (20261108000001) ; le menu doit savoir si la personne est
-- deja fondatrice pour proposer « Marquer comme fondateur » ou « Retirer des
-- fondateurs ».
--
-- Pourquoi une lecture a part : personnel_fondateurs n'a aucun droit client,
-- et personnel_entretiens() ne rend que le personnel du cote de l'appelant.
-- Les Comptes (comptes_admin) montrent tous les comptes a toute direction
-- active, sans borne de genre : lire la coche n'est pas plus sensible.
--
-- Fonctions existantes remplacees : aucune (0 CREATE OR REPLACE).
-- Mots de suppression de ce fichier : 0.

CREATE FUNCTION public.fondateurs_personnel()
RETURNS SETOF uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'la coche fondateur est lue par la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT f.profile_id FROM public.personnel_fondateurs f
     WHERE f.fondateur
     ORDER BY f.profile_id;
END;
$function$;
REVOKE ALL ON FUNCTION public.fondateurs_personnel() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fondateurs_personnel() TO authenticated;
-- Empreinte F86.
DO $empreinte$
DECLARE
  f regprocedure := 'public.fondateurs_personnel()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.fondateurs_personnel(); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-04. '
    || 'V2-e : les profils coches fondateur, pour la direction active (menu des Comptes), sans borne de genre comme '
    || 'comptes_admin(). Must-pass: supabase/tests/scenarios_v2e_fondateurs.sql.');
END;
$empreinte$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.fondateurs_personnel()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.fondateurs_personnel()', 'EXECUTE') THEN
    RAISE EXCEPTION 'V2-e : droits inattendus sur fondateurs_personnel';
  END IF;
  IF (SELECT p.provolatile FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.fondateurs_personnel()'::regprocedure) <> 's' THEN
    RAISE EXCEPTION 'V2-e : fondateurs_personnel doit etre STABLE (lecture seule)';
  END IF;
  IF pg_catalog.obj_description('public.fondateurs_personnel()'::regprocedure, 'pg_proc')
       !~ ('md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.fondateurs_personnel()'::regprocedure))) THEN
    RAISE EXCEPTION 'V2-e : empreinte F86 absente ou fausse';
  END IF;
END;
$postflight$;
