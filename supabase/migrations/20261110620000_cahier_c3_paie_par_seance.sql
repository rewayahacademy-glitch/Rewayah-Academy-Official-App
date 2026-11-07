-- CAHIER-C3, PAIE PAR SEANCE (07/11/2026).
--
-- A INSTALLER SEULEMENT QUAND l'ecran de confirmation C3 est en production ET
-- que la liste « Cahiers a remplir » montre chaque seance qui bloque la paie
-- (decision du directeur du 05/11, 08 §5 bis : la paie d'une seance est
-- liberee par la confirmation de position, apres chaque seance, a la place du
-- cahier hebdomadaire). La date de coupure est posee A L'INSTALLATION, jamais
-- avant la mise en production de l'ecran : c'est la constante de la section 1
-- (`private.cahier_c3_coupure`). Par defaut elle vaut le 01/01/2100 : la
-- migration ne change alors RIEN a la paie. Pour l'activer : poser la date
-- dans la section 1 avant d'installer, ou plus tard remplacer seulement
-- `private.cahier_c3_coupure()` (CREATE OR REPLACE, meme signature).
--
-- Effet une fois la coupure posee : une seance commencee a partir de la
-- coupure sans son propre cahier passe « en attente » dans le releve de paie ;
-- les seances d'avant gardent la couverture par le cahier de la semaine
-- (regle de stabilite 2). Le bouton de fin de seance lit la meme regle.
--
-- Fichier SANS mot d'effacement en instruction (B5). Une fonction neuve
-- (la constante) ; une fonction remplacee a signature egale
-- (`private.cahier_semaine_couvert`), precedee d'un preflight md5(prosrc).
-- Lecteurs de la fonction remplacee (B1) : `cahier_semaine_depose`,
-- `mes_rapports_en_attente`, `private.pai_releve_seances` (via
-- 20261103000000, 20261103300000, 20261107500000) : meme signature, meme sens
-- pour les seances d'avant la coupure.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. LA CONSTANTE : la date de coupure (a poser a l'installation)
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.cahier_c3_coupure()
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT '2100-01-01 00:00:00+00'::timestamptz
$function$;

COMMENT ON FUNCTION private.cahier_c3_coupure() IS
  'CAHIER-C3 : debut de la paie par seance. 2100-01-01 = pas encore active. '
  'A poser a l''installation, apres la mise en production de l''ecran C3.';

REVOKE ALL ON FUNCTION private.cahier_c3_coupure()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 2. La regle de couverture, avec la coupure
-- ---------------------------------------------------------------------------
-- Preflight : la definition remplacee doit etre celle de production
-- (md5(prosrc) 72e41dea9b79f3ccface99e632fb71b5, lu en production le
-- 07/11/2026 par le garde-cap) ou celle du depot rejoue sur base nue
-- (cf5e84e7b29e23daa286ee4be3de3816, meme texte que 20261103000000 ; les deux
-- empreintes different, sans doute par les fins de ligne a l'installation).
-- Toute autre definition : rien ne change.
DO $preflight$
BEGIN
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.cahier_semaine_couvert(uuid)'::pg_catalog.regprocedure)
     NOT IN ('72e41dea9b79f3ccface99e632fb71b5', 'cf5e84e7b29e23daa286ee4be3de3816') THEN
    RAISE EXCEPTION 'CAHIER-C3 : private.cahier_semaine_couvert differe de la production, migration a revoir';
  END IF;
END;
$preflight$;

CREATE OR REPLACE FUNCTION private.cahier_semaine_couvert(p_seance uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH s AS (
    SELECT s.id, s.groupe_id, g.timezone_iana AS tz,
           pg_catalog.date_trunc('week', s.started_at AT TIME ZONE g.timezone_iana) AS semaine
      FROM public.sessions s
      LEFT JOIN public.groupes g ON g.id = s.groupe_id
     WHERE s.id = p_seance
  )
  SELECT
    -- Le cahier de la seance elle-meme couvre toujours ses eleves (ancienne
    -- forme du contenu comprise).
    EXISTS (SELECT 1 FROM public.lesson_reports lr
             WHERE lr.session_id = p_seance AND lr.deleted_at IS NULL)
    OR (
      -- CAHIER-C3 : la couverture par le cahier de la semaine ne vaut plus
      -- que pour les seances commencees avant la coupure ; ensuite, chaque
      -- seance attend sa propre confirmation.
      (SELECT s2x.started_at FROM public.sessions s2x WHERE s2x.id = p_seance)
        < private.cahier_c3_coupure()
      AND (SELECT s.groupe_id FROM s) IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
          FROM public.session_participants sp
         WHERE sp.session_id = p_seance AND sp.role = 'student' AND sp.deleted_at IS NULL
           AND NOT EXISTS (
             SELECT 1
               FROM s
               JOIN public.sessions s2
                 ON s2.groupe_id = s.groupe_id AND s2.deleted_at IS NULL
                AND pg_catalog.date_trunc('week', s2.started_at AT TIME ZONE s.tz) = s.semaine
               JOIN public.lesson_reports lr
                 ON lr.session_id = s2.id AND lr.deleted_at IS NULL
                AND pg_catalog.jsonb_typeof(lr.content -> 'eleves') = 'array'
              WHERE EXISTS (
                SELECT 1 FROM pg_catalog.jsonb_array_elements(lr.content -> 'eleves') e
                 WHERE e ->> 'student_id' = sp.profile_id::text))));
$function$;

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated', 'private.cahier_semaine_couvert(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.cahier_semaine_couvert(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.cahier_semaine_couvert(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_c3_coupure()', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'CAHIER-C3 paie : droits des fonctions incorrects';
  END IF;
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.cahier_semaine_couvert(uuid)'::pg_catalog.regprocedure),
       'private.cahier_c3_coupure()') = 0 THEN
    RAISE EXCEPTION 'CAHIER-C3 paie : la regle ne lit pas la coupure';
  END IF;
END;
$postflight$;

COMMIT;
