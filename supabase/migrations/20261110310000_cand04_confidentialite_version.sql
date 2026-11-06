-- CAND-04 (PR B de CANDIDATS-FLUX, 06/11/2026) : la version de la politique de
-- confidentialite que le candidat accepte.
--
-- L'application affiche et envoie la version de `VersionsJuridiques.version`
-- (lib/features/juridique/textes_juridiques.dart), passee a 2026-11-v1 le
-- 02/11/2026 (FN-115a). Le reglage serveur `candidatures.confidentialite_version`
-- est reste a 2026-10-v1 (20261022000600) : `inscrire_candidat` repondrait
-- « confidentialite_perimee » a tout candidat. On aligne le reglage.
--
-- Idempotent : ne change que l'ancienne valeur ; une valeur deja reglee
-- autrement par la direction est laissee telle quelle. Aucune suppression.

UPDATE public.app_config
   SET value = '"2026-11-v1"'::jsonb,
       updated_at = pg_catalog.now()
 WHERE key = 'candidatures.confidentialite_version'
   AND value = '"2026-10-v1"'::jsonb;

DO $postflight$
BEGIN
  IF (SELECT c.value #>> '{}' FROM public.app_config c
       WHERE c.key = 'candidatures.confidentialite_version') IS NULL THEN
    RAISE EXCEPTION 'CAND-04 : reglage candidatures.confidentialite_version absent';
  END IF;
END
$postflight$;
