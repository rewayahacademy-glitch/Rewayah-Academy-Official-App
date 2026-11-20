-- CONFIDENTIALITE-PRAXIS (17/11/2026, ordre du directeur : publier la politique de confidentialite de
-- l'assistant Praxis) : la version de la politique que le candidat accepte passe a 2026-11-v2.
--
-- L'application affiche et envoie la version de `VersionsJuridiques.version`
-- (lib/features/juridique/textes_juridiques.dart), montee a 2026-11-v2 le 20/11/2026 (PR 645 ; fichier repris
-- de la PR 609, renomme de 20261129950000 en 20261130400000 pour passer apres les migrations de main). Le reglage serveur
-- `candidatures.confidentialite_version` etait a 2026-11-v1 (20261110310000) : sans cet alignement,
-- `inscrire_candidat` repondrait « confidentialite_perimee » a tout candidat, et l'ecran d'inscription
-- (recapitulatif_etape.dart) bloquerait de lui-meme. Meme erreur que celle payee le 06/11 (CAND-04).
--
-- A installer par le pilote des que le deploiement de main est en ligne (fenetre de l'ordre de la minute).
--
-- Idempotent : ne change que l'ancienne valeur ; une valeur deja reglee autrement par la direction est
-- laissee telle quelle. Aucune suppression.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.app_config c WHERE c.key = 'candidatures.confidentialite_version') THEN
    RAISE EXCEPTION 'CONFIDENTIALITE-PRAXIS : reglage candidatures.confidentialite_version absent';
  END IF;
  IF (SELECT c.value #>> '{}' FROM public.app_config c
       WHERE c.key = 'candidatures.confidentialite_version') NOT IN ('2026-11-v1', '2026-11-v2') THEN
    RAISE NOTICE 'CONFIDENTIALITE-PRAXIS : reglage candidatures.confidentialite_version = %, regle autrement : laisse tel quel',
      (SELECT c.value #>> '{}' FROM public.app_config c WHERE c.key = 'candidatures.confidentialite_version');
  END IF;
END
$preflight$;

UPDATE public.app_config
   SET value = '"2026-11-v2"'::jsonb,
       updated_at = pg_catalog.now()
 WHERE key = 'candidatures.confidentialite_version'
   AND value = '"2026-11-v1"'::jsonb;

DO $postflight$
DECLARE
  v_valeur text;
BEGIN
  SELECT c.value #>> '{}' INTO v_valeur FROM public.app_config c
   WHERE c.key = 'candidatures.confidentialite_version';
  IF v_valeur IS NULL THEN
    RAISE EXCEPTION 'CONFIDENTIALITE-PRAXIS : reglage candidatures.confidentialite_version absent';
  END IF;
  -- Une valeur reglee autrement par la direction n'est pas un echec ; la valeur attendue partout ailleurs est v2.
  IF v_valeur = '2026-11-v1' THEN
    RAISE EXCEPTION 'CONFIDENTIALITE-PRAXIS : reglage encore a 2026-11-v1 apres la mise a jour';
  END IF;
END
$postflight$;
