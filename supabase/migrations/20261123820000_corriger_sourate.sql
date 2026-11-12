-- CORRIGER-SOURATE (directeur, 11/11/2026 ; decisions du garde-cap, 11/11) :
-- une sourate validee par erreur au cahier se retire. Plage reservee par le
-- garde-cap : 20261123820000.
--
-- Decisions du garde-cap, appliquees telles quelles :
--   a) Marquage, jamais d'effacement : colonnes retiree_le, retiree_par et
--      motif_retrait (facultatif) sur public.sourates_validees. La ligne
--      reste ; la regle « jamais effacee » reste vraie.
--   b) Les lecteurs filtrent les sourates retirees : sourates_eleve et
--      sourates_bases_classe (meme signature, meme porte, meme forme de
--      reponse ; seule la jointure change).
--   c) Qui peut retirer : l'AUTEUR de la validation (validee_par =
--      auth.uid(), remplacant compris) dans les 24 h apres valide_le ; la
--      direction (role lu cote serveur), sans limite de temps. Personne
--      d'autre.
--   d) Le declencheur ne reactive une sourate retiree que si elle APPARAIT
--      dans le cahier : absente de OLD.content, presente dans NEW.content
--      (a l'INSERT, toutes celles du cahier). Une sourate retiree que le
--      cahier contient encore n'est donc jamais reactivee par une simple
--      modification du cahier ; decochee puis recochee, elle revient. Une
--      reactivation remet retiree_le, retiree_par et motif_retrait a NULL et
--      met a jour validee_par et valide_le (et la seance, le cahier).
--   e) RPC public.retirer_sourate_validee(p_eleve, p_sourate, p_motif) :
--      SECURITY DEFINER, search_path '', compte valide, garde (c),
--      public.log_sensitive_access. Une reactivation est journalisee de meme.
--   f) Pour l'ecran : public.sourates_retirables_classe(groupe) rend, pour la
--      personne connectee, les sourates qu'ELLE peut retirer et jusqu'a
--      quand (NULL : sans limite). L'ecran lit cette capacite, jamais un
--      role. sourates_bases_classe ne change pas de forme : lui ajouter une
--      colonne demanderait de la recreer.
--
-- Aucun mot qui demande la seconde confirmation de staging (aucune
-- suppression de ligne, aucun vidage, aucun objet retire).

BEGIN;

DO $preflight$
DECLARE
  v_corps text;
BEGIN
  IF pg_catalog.to_regclass('public.sourates_validees') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_sourates_validees()') IS NULL
     OR pg_catalog.to_regprocedure('public.sourates_eleve(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.sourates_bases_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : SOURATES (20261122900000) absente';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'sourates_validees'
                AND column_name IN ('retiree_le', 'retiree_par', 'motif_retrait')) THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.retirer_sourate_validee(uuid,integer,text)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.sourates_retirables_classe(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : une fonction du lot existe deja';
  END IF;
  -- Le declencheur est bien celui de SOURATES : sur lesson_reports, il
  -- appelle private.cahier_sourates_validees, et le corps n'ecrit que par
  -- ajout. Lecture structurelle (espaces normalises) : en production, les
  -- corps de 20261122900000 n'ont plus leurs commentaires, une empreinte du
  -- fichier ne correspondrait pas.
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger tg
     WHERE tg.tgname = 'lesson_reports_sourates_validees'
       AND tg.tgrelid = 'public.lesson_reports'::regclass
       AND NOT tg.tgisinternal
       AND tg.tgfoid = 'private.cahier_sourates_validees()'::regprocedure) THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : declencheur lesson_reports_sourates_validees introuvable';
  END IF;
  SELECT pg_catalog.regexp_replace(p.prosrc, '\s+', ' ', 'g') INTO v_corps
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.cahier_sourates_validees()'::regprocedure;
  IF v_corps NOT LIKE '%ON CONFLICT (student_id, sourate_numero) DO NOTHING%'
     OR v_corps NOT LIKE '%private.sourates_des_bases%'
     OR v_corps NOT LIKE '%session_participants%' THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : le corps du declencheur n''est pas celui de SOURATES';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- a) Le marquage
-- ---------------------------------------------------------------------------
ALTER TABLE public.sourates_validees
  ADD COLUMN retiree_le    timestamptz,
  ADD COLUMN retiree_par   uuid REFERENCES public.profiles(id),
  ADD COLUMN motif_retrait text,
  ADD CONSTRAINT sourates_validees_retrait_complet
    CHECK ((retiree_le IS NULL) = (retiree_par IS NULL)
           AND (motif_retrait IS NULL OR retiree_le IS NOT NULL)),
  ADD CONSTRAINT sourates_validees_motif_court
    CHECK (motif_retrait IS NULL OR pg_catalog.char_length(motif_retrait) BETWEEN 1 AND 500);

COMMENT ON TABLE public.sourates_validees IS
  'SOURATES (11/11/2026, option A) : une ligne par eleve et par sourate des bases '
  'cochee par l''enseignant au cahier. Jamais effacee. CORRIGER-SOURATE (11/11) : '
  'une sourate retiree garde sa ligne, marquee retiree_le et retiree_par ; les '
  'lecteurs l''ecartent. Aucun acces direct.';

-- ---------------------------------------------------------------------------
-- d) Le declencheur : ajout, et reactivation d'une sourate qui apparait
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.cahier_sourates_validees()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  e jsonb;
  v_eleve uuid;
  n text;
  v_avant jsonb;
  v_apparait boolean;
  v_retiree boolean;
BEGIN
  IF NEW.deleted_at IS NOT NULL
     OR pg_catalog.jsonb_typeof(NEW.content -> 'eleves') IS DISTINCT FROM 'array' THEN
    RETURN NEW;
  END IF;
  FOR e IN SELECT x FROM pg_catalog.jsonb_array_elements(NEW.content -> 'eleves') AS x LOOP
    IF pg_catalog.jsonb_typeof(e -> 'sourates_validees') IS DISTINCT FROM 'array' THEN
      CONTINUE;
    END IF;
    BEGIN
      v_eleve := (e ->> 'student_id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      CONTINUE;
    END;
    -- Seul un eleve inscrit a la seance voit une sourate validee.
    IF v_eleve IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.session_participants sp
       WHERE sp.session_id = NEW.session_id AND sp.profile_id = v_eleve
         AND sp.role = 'student' AND sp.deleted_at IS NULL) THEN
      CONTINUE;
    END IF;
    -- Les sourates de cet eleve dans le cahier d'avant (vide a l'INSERT).
    v_avant := '[]'::jsonb;
    IF TG_OP = 'UPDATE' AND pg_catalog.jsonb_typeof(OLD.content -> 'eleves') = 'array' THEN
      SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.btrim(t)), '[]'::jsonb) INTO v_avant
        FROM pg_catalog.jsonb_array_elements(OLD.content -> 'eleves') AS o,
             LATERAL pg_catalog.jsonb_array_elements_text(
               CASE WHEN pg_catalog.jsonb_typeof(o -> 'sourates_validees') = 'array'
                    THEN o -> 'sourates_validees' ELSE '[]'::jsonb END) AS t
       WHERE o ->> 'student_id' = v_eleve::text;
    END IF;
    FOR n IN
      SELECT DISTINCT pg_catalog.btrim(t)
        FROM pg_catalog.jsonb_array_elements_text(e -> 'sourates_validees') AS t
       LIMIT 17
    LOOP
      -- Un numero hors des 17 est ignore (le cahier ne propose que les 17).
      IF n ~ '^[0-9]{1,3}$' AND EXISTS (
        SELECT 1 FROM private.sourates_des_bases b WHERE b.numero = n::int) THEN
        -- Elle apparait : absente du cahier d'avant (par numero, quelle que
        -- soit l'ecriture, « 7 » ou « 007 »).
        v_apparait := NOT EXISTS (
          SELECT 1 FROM pg_catalog.jsonb_array_elements_text(v_avant) AS a
           WHERE a ~ '^[0-9]{1,3}$' AND a::int = n::int);
        SELECT v.retiree_le IS NOT NULL INTO v_retiree
          FROM public.sourates_validees v
         WHERE v.student_id = v_eleve AND v.sourate_numero = n::int;
        INSERT INTO public.sourates_validees
          (student_id, sourate_numero, session_id, lesson_report_id, validee_par)
        VALUES (v_eleve, n::int, NEW.session_id, NEW.id, NEW.author_profile_id)
        ON CONFLICT (student_id, sourate_numero) DO UPDATE
          SET retiree_le = NULL,
              retiree_par = NULL,
              motif_retrait = NULL,
              valide_le = pg_catalog.now(),
              validee_par = EXCLUDED.validee_par,
              session_id = EXCLUDED.session_id,
              lesson_report_id = EXCLUDED.lesson_report_id
          -- Une validation active ne bouge jamais ; une retiree ne revient
          -- que si elle apparait dans le cahier.
          WHERE public.sourates_validees.retiree_le IS NOT NULL AND v_apparait;
        IF v_retiree IS TRUE AND v_apparait THEN
          PERFORM public.log_sensitive_access(
            'sourate_reactivee', 'sourates_validees', v_eleve::text || ':' || n,
            pg_catalog.jsonb_build_object(
              'sourate', n::int, 'lesson_report_id', NEW.id,
              'validee_par', NEW.author_profile_id));
        END IF;
      END IF;
    END LOOP;
  END LOOP;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.cahier_sourates_validees()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- b) Les lecteurs ecartent les sourates retirees
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sourates_eleve(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
BEGIN
  -- La porte de public.suivi_pedagogique_eleve, a l'identique.
  IF NOT coalesce(
    v_user IS NOT NULL AND p_student_id IS NOT NULL AND public.app_account_valid()
    AND (
      -- L'eleve lui-meme.
      (public.app_role() = 'student' AND p_student_id = v_user)
      -- Le titulaire de son propre profil eleve (0052).
      OR (public.app_role() = 'guardian' AND p_student_id = v_user
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                         AND sp.deleted_at IS NULL))
      -- Le tuteur du foyer de l'eleve : son enfant seulement.
      OR (public.app_role() = 'guardian'
          AND EXISTS (SELECT 1 FROM public.profiles p
                       WHERE p.id = p_student_id AND p.role = 'student' AND p.deleted_at IS NULL
                         AND p.household_id IS NOT NULL
                         AND p.household_id = public.app_household_id()))
    ), false) THEN
    RAISE EXCEPTION 'sourates refusees' USING errcode = '42501';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'sourates_validees',
      (SELECT pg_catalog.count(*)::int FROM public.sourates_validees v
        WHERE v.student_id = p_student_id AND v.retiree_le IS NULL),
    'sourates_total',
      (SELECT pg_catalog.count(*)::int FROM private.sourates_des_bases),
    'sourates',
      (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                'ordre', b.ordre,
                'numero', b.numero,
                'nom', s.nom_translittere,
                'nom_arabe', s.nom_arabe,
                'validee', v.student_id IS NOT NULL,
                'valide_le', v.valide_le) ORDER BY b.ordre), '[]'::jsonb)
         FROM private.sourates_des_bases b
         JOIN public.sourate s ON s.numero = b.numero
         LEFT JOIN public.sourates_validees v
           ON v.student_id = p_student_id AND v.sourate_numero = b.numero
          AND v.retiree_le IS NULL));
END;
$function$;

REVOKE ALL ON FUNCTION public.sourates_eleve(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sourates_eleve(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sourates_bases_classe(p_groupe_id uuid)
RETURNS TABLE (
  student_id uuid,
  ordre int,
  numero int,
  nom text,
  nom_arabe text,
  validee boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
BEGIN
  IF NOT coalesce(p_groupe_id IS NOT NULL AND private.cahier_c1_peut_lire_classe(p_groupe_id), false) THEN
    RAISE EXCEPTION 'sourates de la classe refusees' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT m.student_id,
           b.ordre,
           b.numero,
           s.nom_translittere,
           s.nom_arabe,
           v.student_id IS NOT NULL
      FROM public.groupe_membres m
      CROSS JOIN private.sourates_des_bases b
      JOIN public.sourate s ON s.numero = b.numero
      LEFT JOIN public.sourates_validees v
        ON v.student_id = m.student_id AND v.sourate_numero = b.numero
       AND v.retiree_le IS NULL
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
     ORDER BY m.student_id, b.ordre;
END;
$function$;

REVOKE ALL ON FUNCTION public.sourates_bases_classe(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sourates_bases_classe(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- c) et e) Retirer une sourate validee
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.retirer_sourate_validee(
  p_eleve uuid,
  p_sourate int,
  p_motif text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_direction boolean;
  v_ligne public.sourates_validees%ROWTYPE;
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
BEGIN
  IF v_user IS NULL OR NOT coalesce(public.app_account_valid(), false)
     OR p_eleve IS NULL OR p_sourate IS NULL THEN
    RAISE EXCEPTION 'retrait refuse' USING errcode = '42501';
  END IF;
  IF v_motif IS NOT NULL AND pg_catalog.char_length(v_motif) > 500 THEN
    RAISE EXCEPTION 'motif trop long' USING errcode = '22023';
  END IF;
  v_direction := coalesce(public.app_role() = 'admin', false);

  SELECT * INTO v_ligne FROM public.sourates_validees v
   WHERE v.student_id = p_eleve AND v.sourate_numero = p_sourate
     AND v.retiree_le IS NULL
   FOR UPDATE;

  -- La garde avant tout : a qui n'a pas le droit, la meme reponse, que la
  -- sourate existe ou non.
  IF NOT v_direction AND NOT coalesce(
       v_ligne.student_id IS NOT NULL
       AND public.app_role() = 'teacher'
       AND v_ligne.validee_par = v_user
       AND v_ligne.valide_le > pg_catalog.now() - interval '24 hours', false) THEN
    RAISE EXCEPTION 'retrait refuse' USING errcode = '42501';
  END IF;
  IF v_ligne.student_id IS NULL THEN
    RAISE EXCEPTION 'sourate non validee' USING errcode = 'P0002';
  END IF;

  UPDATE public.sourates_validees v
     SET retiree_le = pg_catalog.now(),
         retiree_par = v_user,
         motif_retrait = v_motif
   WHERE v.student_id = p_eleve AND v.sourate_numero = p_sourate;

  PERFORM public.log_sensitive_access(
    'sourate_retiree', 'sourates_validees', p_eleve::text || ':' || p_sourate::text,
    pg_catalog.jsonb_build_object(
      'sourate', p_sourate,
      'motif', v_motif,
      'validee_par', v_ligne.validee_par,
      'valide_le', v_ligne.valide_le,
      'lesson_report_id', v_ligne.lesson_report_id,
      'par_la_direction', v_direction));
END;
$function$;

COMMENT ON FUNCTION public.retirer_sourate_validee(uuid, int, text) IS
  'CORRIGER-SOURATE (11/11/2026) : retire une sourate validee par erreur. La ligne '
  'reste, marquee. L''auteur de la validation dans les 24 h, la direction sans limite ; '
  'personne d''autre (42501). Journalise (log_sensitive_access).';

REVOKE ALL ON FUNCTION public.retirer_sourate_validee(uuid, int, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.retirer_sourate_validee(uuid, int, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- f) Ce que la personne connectee peut retirer, pour l'ecran
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.sourates_retirables_classe(p_groupe_id uuid)
RETURNS TABLE (
  student_id uuid,
  numero int,
  retirable_jusqua timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_user uuid := auth.uid();
  v_direction boolean := coalesce(public.app_role() = 'admin', false);
  v_enseignant boolean := coalesce(public.app_role() = 'teacher', false);
BEGIN
  IF NOT coalesce(p_groupe_id IS NOT NULL AND private.cahier_c1_peut_lire_classe(p_groupe_id), false) THEN
    RAISE EXCEPTION 'sourates de la classe refusees' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT v.student_id,
           v.sourate_numero,
           CASE WHEN v_direction THEN NULL::timestamptz
                ELSE v.valide_le + interval '24 hours' END
      FROM public.groupe_membres m
      JOIN public.sourates_validees v ON v.student_id = m.student_id
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
       AND v.retiree_le IS NULL
       AND (v_direction
            OR (v_enseignant AND v.validee_par = v_user
                AND v.valide_le > pg_catalog.now() - interval '24 hours'))
     ORDER BY v.student_id, v.sourate_numero;
END;
$function$;

COMMENT ON FUNCTION public.sourates_retirables_classe(uuid) IS
  'CORRIGER-SOURATE (11/11/2026) : les sourates validees de la Classe que la personne '
  'connectee peut retirer, et jusqu''a quand (NULL : sans limite). Meme porte que '
  'sourates_bases_classe.';

REVOKE ALL ON FUNCTION public.sourates_retirables_classe(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sourates_retirables_classe(uuid) TO authenticated;

DO $postflight$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'sourates_validees'
         AND column_name IN ('retiree_le', 'retiree_par', 'motif_retrait')) <> 3 THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : colonnes absentes';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.sourates_validees', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_sourates_validees()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.retirer_sourate_validee(uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.sourates_retirables_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.sourates_eleve(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.sourates_bases_classe(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.retirer_sourate_validee(uuid,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.sourates_retirables_classe(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.sourates_eleve(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.sourates_bases_classe(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : droits inattendus';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.cahier_sourates_validees()'::regprocedure
                    AND p.prosrc LIKE '%v_apparait%' AND p.prosrc LIKE '%retiree_le = NULL%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'public.sourates_eleve(uuid)'::regprocedure
                       AND p.prosrc LIKE '%retiree_le IS NULL%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'public.sourates_bases_classe(uuid)'::regprocedure
                       AND p.prosrc LIKE '%retiree_le IS NULL%') THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : declencheur ou lecteurs non remplaces';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger tg
     WHERE tg.tgname = 'lesson_reports_sourates_validees'
       AND tg.tgrelid = 'public.lesson_reports'::regclass
       AND tg.tgfoid = 'private.cahier_sourates_validees()'::regprocedure) THEN
    RAISE EXCEPTION 'CORRIGER-SOURATE : declencheur detache';
  END IF;
END
$postflight$;

COMMIT;
