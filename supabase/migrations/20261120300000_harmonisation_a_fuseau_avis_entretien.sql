-- HARMONISATION-A, dette 8 (08/11/2026, plan valide par le garde-cap ; une
-- cause par fichier) : le fuseau de l'avis d'entretien. Aucun mot
-- d'effacement.
--
-- private.entretien_heure_locale (20261119200000) faisait AT TIME ZONE sur le
-- fuseau de la fiche enseignant, sinon sur celui de la candidature. Un nom
-- invalide levait 22023 dans private.entretien_avis_passer : l'avis restait
-- du et se relancait chaque minute (jusqu'a 30 jours). Desormais chaque
-- fuseau est essaye (fiche, puis candidature) ; un fuseau invalide est passe ;
-- sans fuseau valide, l'heure part sans fuseau ('{}') et l'avis est pose une
-- seule fois. Meme signature, memes droits ; preflight md5 du corps de
-- production.
--
-- Rejeu : stub_auth, toutes les migrations, puis
-- supabase/tests/scenarios_harmonisation_a_fuseau_sortie.sql (f1) et
-- supabase/tests/scenarios_salle2_entretien_avis.sql (a8, a9).

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.entretien_heure_locale(uuid,timestamptz)'::regprocedure)
     <> '517ef7c876e4a073c919189d0f18ebcd' THEN
    RAISE EXCEPTION 'HARMONISATION-A (fuseau) : private.entretien_heure_locale a change depuis le depot';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Dette 8 : le fuseau de l'avis d'entretien
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.entretien_heure_locale(p_profil uuid, p_debut timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
BEGIN
  -- La fiche enseignant d'abord, puis la candidature la plus recente.
  FOR v_fuseau IN
    SELECT x.fuseau FROM (
      SELECT 1 AS ordre, tp.timezone_iana AS fuseau
        FROM public.teacher_profiles tp WHERE tp.profile_id = p_profil
      UNION ALL
      SELECT 2, d.fuseau_iana FROM (
        SELECT c.fuseau_iana FROM public.candidatures c
         WHERE c.profile_id = p_profil AND c.fuseau_iana IS NOT NULL
         ORDER BY c.recue_le DESC NULLS LAST LIMIT 1) d
    ) x
     WHERE x.fuseau IS NOT NULL
     ORDER BY x.ordre
  LOOP
    BEGIN
      RETURN pg_catalog.jsonb_build_object(
        'debut_local', pg_catalog.to_char(p_debut AT TIME ZONE v_fuseau, 'YYYY-MM-DD"T"HH24:MI'),
        'fuseau', v_fuseau);
    EXCEPTION WHEN invalid_parameter_value THEN
      -- Fuseau inconnu : on essaie le suivant ; jamais d'erreur dans l'avis.
      NULL;
    END;
  END LOOP;
  -- Aucun fuseau valide : l'heure part sans fuseau.
  RETURN '{}'::jsonb;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF (SELECT p.prolang FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.entretien_heure_locale(uuid,timestamptz)'::regprocedure)
     <> (SELECT l.oid FROM pg_catalog.pg_language l WHERE l.lanname = 'plpgsql')
     OR private.entretien_heure_locale(NULL, pg_catalog.now()) <> '{}'::jsonb THEN
    RAISE EXCEPTION 'HARMONISATION-A (fuseau) : postflight en echec';
  END IF;
END
$postflight$;
