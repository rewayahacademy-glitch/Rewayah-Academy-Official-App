-- NIV1-reprise (03/11/2026, regle G12 du directeur, portee par le pilote) :
-- les profils eleves existants retrouvent le niveau deja donne, sans que la
-- question leur soit reposee.
--
-- Pour chaque profil eleve vivant sans onboarding_fait_le, ce qui est deja
-- connu est cherche, dans cet ordre : la fiche elle-meme, les reponses de la
-- demande liee a ce profil (candidature_apprenants.profil_eleve_id), les
-- reponses que le titulaire a donnees pour lui-meme, la derniere demande
-- horaire (niveau et langue seulement). Rien n'est invente.
--   - Niveau connu et fiche complete (tranche, langue, niveau, objectif) :
--     les valeurs connues sont reprises, sans ecraser une valeur deja posee,
--     et onboarding_fait_le est pose. Le Parcours s'ouvre sur les horaires.
--   - Niveau connu, fiche incomplete : seules les valeurs connues sont
--     reprises ; onboarding_fait_le reste vide, les questions restent
--     (preremplies).
--   - Aucun niveau connu : rien ne change.
--
-- Retour arriere : la valeur d'avant de chaque ligne touchee est gardee dans
-- private.niv1_reprise_avant (insertion seulement, la premiere valeur gardee).
--
-- La reprise est une fonction privee, appelee une fois ici ; le scenario
-- supabase/tests/scenarios_niv1_reprise_profils.sql la rejoue sur ses propres
-- profils. Un second appel ne refait rien sur un profil deja repris.
--
-- FICHIER SANS EFFACEMENT (regle B5) : une table, une vue et une fonction
-- creees, des insertions et des mises a jour ; rien n'est retire.

BEGIN;

-- 1. Table de reprise -----------------------------------------------------

CREATE TABLE private.niv1_reprise_avant (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id),
  niveau_declare text,
  objectif text,
  langue_cours text,
  onboarding_fait_le timestamptz,
  onboarding_pose boolean NOT NULL,
  repris_le timestamptz NOT NULL DEFAULT pg_catalog.now()
);

COMMENT ON TABLE private.niv1_reprise_avant IS
  'NIV1-reprise (03/11/2026, G12) : valeurs d''avant des profils eleves touches par la migration 20261107000000, pour revenir en arriere.';

ALTER TABLE private.niv1_reprise_avant ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.niv1_reprise_avant OWNER TO postgres;
REVOKE ALL ON TABLE private.niv1_reprise_avant FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Ce qui est deja connu, profil par profil ------------------------------
-- Meme lecture que la requete de comptage remise au pilote.

CREATE VIEW private.niv1_reprise_connu AS
SELECT s.profile_id,
       s.niveau_declare AS niveau_avant,
       s.objectif AS objectif_avant,
       s.langue_cours AS langue_avant,
       coalesce(s.niveau_declare, a.niveau_declare, t.niveau_declare, d.niveau_declare) AS niveau,
       coalesce(s.objectif, a.objectif, t.objectif) AS objectif,
       coalesce(s.langue_cours, a.langue_code, t.langue_code, d.langue_code) AS langue,
       s.cohorte
  FROM public.student_profiles s
  LEFT JOIN LATERAL (SELECT ca.niveau_declare, ca.objectif, ca.langue_code
                       FROM public.candidature_apprenants ca
                      WHERE ca.profil_eleve_id = s.profile_id
                      ORDER BY ca.id LIMIT 1) a ON true
  LEFT JOIN LATERAL (SELECT ca.niveau_declare, ca.objectif, ca.langue_code
                       FROM public.candidature_apprenants ca
                       JOIN public.candidatures c ON c.id = ca.candidature_id
                      WHERE ca.est_titulaire AND c.profile_id = s.profile_id
                        AND s.titulaire_profile_id = s.profile_id
                      ORDER BY c.recue_le DESC, ca.rang LIMIT 1) t ON true
  LEFT JOIN LATERAL (SELECT dh.niveau_declare, dh.langue_code
                       FROM public.demandes_horaires_famille dh
                      WHERE dh.eleve_id = s.profile_id
                      ORDER BY dh.created_at DESC LIMIT 1) d ON true
 WHERE s.deleted_at IS NULL
   AND s.onboarding_fait_le IS NULL;

ALTER VIEW private.niv1_reprise_connu OWNER TO postgres;
REVOKE ALL ON TABLE private.niv1_reprise_connu FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. La reprise -------------------------------------------------------------

CREATE FUNCTION private.niv1_reprendre_profils()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_touches integer;
  v_remplis integer;
BEGIN
  WITH cible AS (
    SELECT k.*,
           (k.cohorte IS NOT NULL AND k.langue IS NOT NULL
            AND k.niveau IS NOT NULL AND k.objectif IS NOT NULL) AS complete
      FROM private.niv1_reprise_connu k
     WHERE k.niveau IS NOT NULL
       AND (k.niveau_avant IS NULL
            OR k.objectif_avant IS DISTINCT FROM k.objectif
            OR k.langue_avant IS DISTINCT FROM k.langue
            OR (k.cohorte IS NOT NULL AND k.langue IS NOT NULL AND k.objectif IS NOT NULL))
  ), avant AS (
    INSERT INTO private.niv1_reprise_avant
      (profile_id, niveau_declare, objectif, langue_cours, onboarding_fait_le, onboarding_pose)
    SELECT c.profile_id, c.niveau_avant, c.objectif_avant, c.langue_avant, NULL, c.complete
      FROM cible c
    ON CONFLICT (profile_id) DO NOTHING
    RETURNING profile_id
  ), maj AS (
    UPDATE public.student_profiles s
       SET niveau_declare = coalesce(s.niveau_declare, c.niveau),
           objectif = coalesce(s.objectif, c.objectif),
           langue_cours = coalesce(s.langue_cours, c.langue),
           onboarding_fait_le = CASE WHEN c.complete THEN pg_catalog.now() ELSE s.onboarding_fait_le END
      FROM cible c
     WHERE s.profile_id = c.profile_id
       AND s.deleted_at IS NULL
       AND s.onboarding_fait_le IS NULL
    RETURNING s.profile_id, s.onboarding_fait_le IS NOT NULL AS rempli
  )
  SELECT pg_catalog.count(*), pg_catalog.count(*) FILTER (WHERE rempli)
    INTO v_touches, v_remplis
    FROM maj;
  RETURN pg_catalog.jsonb_build_object('touches', v_touches, 'remplis', v_remplis);
END;
$function$;

ALTER FUNCTION private.niv1_reprendre_profils() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.niv1_reprendre_profils()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 4. Une fois, maintenant ---------------------------------------------------

-- Le nombre de profils touches est compare a ce que la lecture prevoit sur
-- la base ou la migration tourne, jamais a un nombre ecrit en dur.
DO $reprise$
DECLARE
  v_prevus integer;
  v_prevus_remplis integer;
  v_r jsonb;
BEGIN
  SELECT pg_catalog.count(*),
         pg_catalog.count(*) FILTER (WHERE k.cohorte IS NOT NULL AND k.langue IS NOT NULL
                                       AND k.objectif IS NOT NULL)
    INTO v_prevus, v_prevus_remplis
    FROM private.niv1_reprise_connu k
   WHERE k.niveau IS NOT NULL
     AND (k.niveau_avant IS NULL
          OR k.objectif_avant IS DISTINCT FROM k.objectif
          OR k.langue_avant IS DISTINCT FROM k.langue
          OR (k.cohorte IS NOT NULL AND k.langue IS NOT NULL AND k.objectif IS NOT NULL));
  v_r := private.niv1_reprendre_profils();
  IF (v_r ->> 'touches')::integer <> v_prevus OR (v_r ->> 'remplis')::integer <> v_prevus_remplis THEN
    RAISE EXCEPTION 'NIV1-reprise : % profils touches (% prevus), % remplis (% prevus)',
      v_r ->> 'touches', v_prevus, v_r ->> 'remplis', v_prevus_remplis;
  END IF;
  RAISE NOTICE 'NIV1-reprise : % profils touches, dont % marques remplis, comme prevu',
    v_r ->> 'touches', v_r ->> 'remplis';
END;
$reprise$;

-- Postflight --------------------------------------------------------------

DO $postflight$
BEGIN
  -- Plus aucun profil vivant au niveau et a la fiche connus sans onboarding.
  IF EXISTS (SELECT 1 FROM private.niv1_reprise_connu k
              WHERE k.niveau IS NOT NULL AND k.cohorte IS NOT NULL
                AND k.langue IS NOT NULL AND k.objectif IS NOT NULL) THEN
    RAISE EXCEPTION 'NIV1-reprise : un profil complet reste sans onboarding_fait_le';
  END IF;
  -- Chaque profil marque rempli par la reprise a sa valeur d'avant.
  IF EXISTS (SELECT 1 FROM private.niv1_reprise_avant r
               JOIN public.student_profiles s ON s.profile_id = r.profile_id
              WHERE r.onboarding_pose AND s.onboarding_fait_le IS NULL) THEN
    RAISE EXCEPTION 'NIV1-reprise : une ligne de reprise ne correspond pas au profil';
  END IF;
  -- Aucun role client n'atteint la table, la vue ni la fonction.
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.niv1_reprise_avant'::pg_catalog.regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'private.niv1_reprise_avant', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.niv1_reprise_avant', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'private.niv1_reprise_connu', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'private.niv1_reprendre_profils()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.niv1_reprendre_profils()', 'EXECUTE') THEN
    RAISE EXCEPTION 'NIV1-reprise : table, vue ou fonction exposee';
  END IF;
END;
$postflight$;

COMMIT;
