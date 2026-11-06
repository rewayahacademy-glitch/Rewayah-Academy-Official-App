-- CAHIER-C3 (rang 22 f, ETUDE-CAHIER-2026-11.md §4.3 et §5 ; reponses du
-- directeur du 05/11, registre 08) : le cahier de confirmation.
--
-- Fichier SANS mot d'effacement en instruction (B5). Migration additive (B6) :
-- une table neuve, un declencheur neuf, une lecture neuve ; une fonction
-- existante remplacee a signature egale (`private.cahier_semaine_couvert`).
--
-- Ce que fait le lot :
--   1. Les observations du cahier deviennent des lignes, une par eleve et par
--      objectif a renforcer, plus « pret pour le petit bilan »
--      (`cahier_observations`). Elles sont tirees du cahier depose
--      (`lesson_reports.content.eleves[].objectifs_a_renforcer`,
--      `.pret_bilan`) par un declencheur : l'ecran et la file hors ligne
--      n'ont rien de plus a envoyer.
--   2. La paie d'une seance est liberee par SA confirmation (reponse 1 du
--      directeur du 05/11 ; arbitrage du garde-cap : confirmation apres chaque
--      seance, elle remplace le cahier hebdomadaire). Regle de stabilite 2
--      (un changement vaut pour la suite, jamais pour le passe) : seules les
--      seances commencees a partir du 07/11/2026 06:00 UTC sont concernees ;
--      celles d'avant gardent la couverture par la semaine.
--   3. Lecture des observations d'une Classe (`observations_classe`), memes
--      lecteurs que la position de reprise (garde de CAHIER-C1).
--
-- Ce que le lot NE fait PAS : aucun indicateur (C4) ; aucun devoir structure
-- ecrit seul (il demande la position de debut et de fin de seance) ; la liste
-- « Cahiers a remplir » (`mes_rapports_en_attente`) garde une ligne par
-- Classe et par semaine.
--
-- Lecteurs de la fonction remplacee (B1) : `cahier_semaine_depose`,
-- `mes_rapports_en_attente`, `private.pai_releve_seances` (via
-- 20261103000000, 20261103300000, 20261107500000) : meme signature, meme sens
-- pour les seances d'avant la coupure.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Les observations, en lignes
-- ---------------------------------------------------------------------------
CREATE TABLE public.cahier_observations (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Sans cle etrangere vers lesson_reports et sessions, a dessein : une
  -- cascade demanderait un mot d'effacement (B5), et une cle simple
  -- bloquerait l'effacement d'une seance (lesson_reports y est en cascade).
  -- Le declencheur est le seul ecrivain : il ne pose que des identifiants
  -- existants.
  lesson_report_id uuid NOT NULL,
  session_id       uuid NOT NULL,
  student_id       uuid NOT NULL REFERENCES public.profiles(id),
  nature           text NOT NULL CHECK (nature IN ('a_renforcer', 'pret_bilan')),
  objectif         text CHECK (objectif IS NULL OR pg_catalog.length(objectif) BETWEEN 1 AND 200),
  cree_le          timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT cahier_observations_objectif_si_renforcer
    CHECK ((nature = 'a_renforcer') = (objectif IS NOT NULL))
);

CREATE INDEX cahier_observations_session_idx ON public.cahier_observations (session_id);
CREATE INDEX cahier_observations_eleve_idx ON public.cahier_observations (student_id, cree_le DESC);

COMMENT ON TABLE public.cahier_observations IS
  'CAHIER-C3 (06/11/2026) : une ligne par eleve et par objectif a renforcer, ou '
  '« pret pour le petit bilan », tiree du cahier depose. Aucun acces direct.';

ALTER TABLE public.cahier_observations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.cahier_observations FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Le declencheur : du cahier depose aux lignes
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.cahier_c3_observations()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  e jsonb;
  v_eleve uuid;
  o text;
BEGIN
  IF pg_catalog.jsonb_typeof(NEW.content -> 'eleves') IS DISTINCT FROM 'array' THEN
    RETURN NEW;
  END IF;
  FOR e IN SELECT x FROM pg_catalog.jsonb_array_elements(NEW.content -> 'eleves') AS x LOOP
    BEGIN
      v_eleve := (e ->> 'student_id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      CONTINUE;
    END;
    -- Seul un eleve inscrit a la seance recoit une observation.
    IF v_eleve IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.session_participants sp
       WHERE sp.session_id = NEW.session_id AND sp.profile_id = v_eleve
         AND sp.role = 'student' AND sp.deleted_at IS NULL) THEN
      CONTINUE;
    END IF;
    IF pg_catalog.jsonb_typeof(e -> 'objectifs_a_renforcer') = 'array' THEN
      FOR o IN
        SELECT DISTINCT pg_catalog.btrim(t)
          FROM pg_catalog.jsonb_array_elements_text(e -> 'objectifs_a_renforcer') AS t
         WHERE pg_catalog.length(pg_catalog.btrim(t)) BETWEEN 1 AND 200
         LIMIT 5
      LOOP
        INSERT INTO public.cahier_observations (lesson_report_id, session_id, student_id, nature, objectif)
        VALUES (NEW.id, NEW.session_id, v_eleve, 'a_renforcer', o);
      END LOOP;
    END IF;
    IF (e ->> 'pret_bilan') = 'true' THEN
      INSERT INTO public.cahier_observations (lesson_report_id, session_id, student_id, nature)
      VALUES (NEW.id, NEW.session_id, v_eleve, 'pret_bilan');
    END IF;
  END LOOP;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.cahier_c3_observations()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER lesson_reports_c3_observations
  AFTER INSERT ON public.lesson_reports
  FOR EACH ROW EXECUTE FUNCTION private.cahier_c3_observations();

-- ---------------------------------------------------------------------------
-- 3. La lecture des observations d'une Classe
-- ---------------------------------------------------------------------------
-- Les observations du dernier cahier en vigueur de chaque seance de la
-- Classe (un cahier corrige remplace le precedent), les plus recentes
-- d'abord, 500 au plus.
CREATE FUNCTION public.observations_classe(p_groupe_id uuid)
RETURNS TABLE (session_id uuid, student_id uuid, nature text, objectif text, observe_le timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
BEGIN
  IF NOT private.cahier_c1_peut_lire_classe(p_groupe_id) THEN
    RAISE EXCEPTION 'observations refusees' USING errcode = '42501';
  END IF;
  RETURN QUERY
    WITH dernier AS (
      SELECT DISTINCT ON (lr.session_id) lr.id, lr.session_id, s.started_at
        FROM public.lesson_reports lr
        JOIN public.sessions s ON s.id = lr.session_id
       WHERE s.groupe_id = p_groupe_id AND s.deleted_at IS NULL AND lr.deleted_at IS NULL
       ORDER BY lr.session_id, lr.created_at DESC
    )
    SELECT o.session_id, o.student_id, o.nature, o.objectif, d.started_at
      FROM public.cahier_observations o
      JOIN dernier d ON d.id = o.lesson_report_id
     ORDER BY d.started_at DESC, o.student_id, o.nature, o.objectif
     LIMIT 500;
END;
$function$;

COMMENT ON FUNCTION public.observations_classe(uuid) IS
  'CAHIER-C3 (06/11/2026) : objectifs a renforcer et « pret pour le petit bilan » '
  'des eleves d''une Classe, du dernier cahier de chaque seance. Memes droits que '
  'position_reprise_classe. 42501 sinon.';

REVOKE ALL ON FUNCTION public.observations_classe(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.observations_classe(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. La paie d'une seance attend sa propre confirmation (pour la suite)
-- ---------------------------------------------------------------------------
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
      -- que pour les seances commencees avant le 07/11/2026 06:00 UTC ;
      -- ensuite, chaque seance attend sa propre confirmation.
      (SELECT s2x.started_at FROM public.sessions s2x WHERE s2x.id = p_seance)
        < '2026-11-07 06:00:00+00'::timestamptz
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
-- 5. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.cahier_observations'::regclass) THEN
    RAISE EXCEPTION 'CAHIER-C3 : RLS absente sur cahier_observations';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.cahier_observations', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.cahier_observations', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.cahier_observations', 'INSERT')
  THEN
    RAISE EXCEPTION 'CAHIER-C3 : acces direct ouvert sur cahier_observations';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.observations_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_c3_observations()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_semaine_couvert(uuid)', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'CAHIER-C3 : droits des fonctions incorrects';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.lesson_reports'::regclass
                    AND t.tgname = 'lesson_reports_c3_observations') THEN
    RAISE EXCEPTION 'CAHIER-C3 : declencheur absent';
  END IF;
END;
$postflight$;

COMMIT;
