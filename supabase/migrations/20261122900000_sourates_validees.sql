-- SOURATES (directeur, 11/11/2026, option A) : « l'enseignant coche la
-- sourate au cahier, selon le critere de l'etape » (« Recite chaque sourate
-- de l'etape de memoire, sans erreur de mot »). Plage reservee par le
-- garde-cap : 20261122900000 a 20261122999999.
--
-- Ce que fait cette migration :
--   1. private.sourates_des_bases : LA source unique des 17 sourates des
--      bases, dans l'ordre d'etude, posees telles quelles depuis
--      .claude/skills/programme-rewayah/SKILL.md, section 2, ligne 51 :
--      « Les 17 sourates des bases (105 versets) : Al-Fatiha 7 · An-Nas (114)
--      6 · Al-Falaq (113) 5 · Al-Ikhlas (112) 4 · Al-Masad (111) 5 · An-Nasr
--      (110) 3 · Al-Kafirun (109) 6 · Al-Kawthar (108) 3 · Al-Ma'un (107) 7 ·
--      Quraysh (106) 4 · Al-Fil (105) 5 · Al-Humaza (104) 9 · Al-'Asr (103) 3
--      · At-Takathur (102) 8 · Al-Qari'a (101) 11 · Al-'Adiyat (100) 11 ·
--      Az-Zalzalah (99) 8. » Lecture interne seulement (fonctions SECURITY
--      DEFINER).
--   2. public.sourates_validees : une ligne par eleve et par sourate
--      validee. Jamais effacee ni modifiee (« ce qui est valide n'est jamais
--      perdu ») : aucune politique, aucun droit direct.
--   3. Le seul ecrivain : un declencheur sur le depot du cahier
--      (lesson_reports), sur le modele de CAHIER-C3. L'ecriture reste celle
--      de l'enseignant de la seance, par la politique existante
--      lesson_reports_teacher_write. Aucune ecriture par la direction (option
--      A ; la question est sur la liste du directeur).
--   4. public.sourates_eleve(eleve) : le compte des sourates validees, le
--      total et la liste, avec EXACTEMENT la porte de
--      suivi_pedagogique_eleve (l'eleve, le titulaire de son profil, le
--      tuteur du foyer ; 42501 sinon). suivi_pedagogique_eleve ne change pas
--      (ni signature, ni corps) : elle rend une table, et y ajouter des
--      colonnes demanderait de la supprimer d'abord.
--   5. public.sourates_bases_classe(groupe) : les 17 sourates de chaque
--      eleve de la Classe et celles deja validees, pour le cahier. Porte :
--      private.cahier_c1_peut_lire_classe (titulaire, remplacant de la
--      seance, direction en lecture).
--
-- Decision du directeur (11/11/2026, relayee par le garde-cap et le pilote) :
-- les 17 sourates des bases comptent a toute etape ; le total est 17. La
-- direction ne valide pas les sourates : elle voit l'etat, sans plus (lecture
-- par sourates_bases_classe ; aucune RPC d'ecriture).
--
-- Aucun mot qui demande la seconde confirmation de staging (aucune
-- suppression, aucun vidage, aucun effacement de ligne).

BEGIN;

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.sourates_validees') IS NOT NULL THEN
    RAISE EXCEPTION 'SOURATES : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.suivi_pedagogique_eleve(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL THEN
    RAISE EXCEPTION 'SOURATES : SUIVI-ELEVE ou CAHIER-C1 absent';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les 17 sourates des bases, dans l'ordre d'etude
-- ---------------------------------------------------------------------------
CREATE TABLE private.sourates_des_bases (
  ordre  int PRIMARY KEY CHECK (ordre BETWEEN 1 AND 17),
  numero int NOT NULL UNIQUE REFERENCES public.sourate(numero)
);

INSERT INTO private.sourates_des_bases (ordre, numero) VALUES
  (1, 1), (2, 114), (3, 113), (4, 112), (5, 111), (6, 110), (7, 109), (8, 108),
  (9, 107), (10, 106), (11, 105), (12, 104), (13, 103), (14, 102), (15, 101),
  (16, 100), (17, 99);

COMMENT ON TABLE private.sourates_des_bases IS
  'SOURATES (11/11/2026) : la source unique des 17 sourates des bases, dans '
  'l''ordre d''etude (programme-rewayah). Lecture par fonctions SECURITY DEFINER seulement.';

ALTER TABLE private.sourates_des_bases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.sourates_des_bases FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Les sourates validees
-- ---------------------------------------------------------------------------
CREATE TABLE public.sourates_validees (
  student_id       uuid NOT NULL REFERENCES public.profiles(id),
  sourate_numero   int  NOT NULL REFERENCES private.sourates_des_bases(numero),
  valide_le        timestamptz NOT NULL DEFAULT pg_catalog.now(),
  -- Sans cle etrangere vers sessions et lesson_reports, a dessein (comme
  -- CAHIER-C3) : une validation survit a l'effacement d'une seance ou d'un
  -- cahier. Le declencheur est le seul ecrivain.
  session_id       uuid NOT NULL,
  lesson_report_id uuid NOT NULL,
  validee_par      uuid NOT NULL REFERENCES public.profiles(id),
  PRIMARY KEY (student_id, sourate_numero)
);

COMMENT ON TABLE public.sourates_validees IS
  'SOURATES (11/11/2026, option A) : une ligne par eleve et par sourate des bases '
  'cochee par l''enseignant au cahier. Jamais effacee ni modifiee. Aucun acces direct.';

ALTER TABLE public.sourates_validees ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.sourates_validees FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Le declencheur : du cahier depose aux sourates validees
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.cahier_sourates_validees()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  e jsonb;
  v_eleve uuid;
  n text;
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
    FOR n IN
      SELECT DISTINCT pg_catalog.btrim(t)
        FROM pg_catalog.jsonb_array_elements_text(e -> 'sourates_validees') AS t
       LIMIT 17
    LOOP
      -- Un numero hors des 17 est ignore (le cahier ne propose que les 17).
      IF n ~ '^[0-9]{1,3}$' AND EXISTS (
        SELECT 1 FROM private.sourates_des_bases b WHERE b.numero = n::int) THEN
        INSERT INTO public.sourates_validees
          (student_id, sourate_numero, session_id, lesson_report_id, validee_par)
        VALUES (v_eleve, n::int, NEW.session_id, NEW.id, NEW.author_profile_id)
        ON CONFLICT (student_id, sourate_numero) DO NOTHING;
      END IF;
    END LOOP;
  END LOOP;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.cahier_sourates_validees()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER lesson_reports_sourates_validees
  AFTER INSERT ON public.lesson_reports
  FOR EACH ROW EXECUTE FUNCTION private.cahier_sourates_validees();

-- ---------------------------------------------------------------------------
-- 4. Les sourates d'un eleve, pour lui et sa famille
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.sourates_eleve(p_student_id uuid)
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
        WHERE v.student_id = p_student_id),
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
           ON v.student_id = p_student_id AND v.sourate_numero = b.numero));
END;
$function$;

COMMENT ON FUNCTION public.sourates_eleve(uuid) IS
  'SOURATES (11/11/2026, option A) : les sourates des bases validees au cahier, '
  'le total (17) et la liste dans l''ordre d''etude. Meme porte que '
  'suivi_pedagogique_eleve : eleve lui-meme, titulaire de son profil, tuteur du foyer.';

REVOKE ALL ON FUNCTION public.sourates_eleve(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sourates_eleve(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Les sourates des eleves d'une Classe, pour le cahier
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.sourates_bases_classe(p_groupe_id uuid)
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
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
     ORDER BY m.student_id, b.ordre;
END;
$function$;

COMMENT ON FUNCTION public.sourates_bases_classe(uuid) IS
  'SOURATES (11/11/2026) : les 17 sourates des bases de chaque eleve de la Classe, '
  'avec celles deja validees, pour le cahier. Titulaire, remplacant de la seance, '
  'direction en lecture (private.cahier_c1_peut_lire_classe).';

REVOKE ALL ON FUNCTION public.sourates_bases_classe(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sourates_bases_classe(uuid) TO authenticated;

DO $postflight$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.sourates_des_bases) <> 17 THEN
    RAISE EXCEPTION 'SOURATES : il faut exactement 17 sourates des bases';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.sourates_validees', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.sourates_validees', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cahier_sourates_validees()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.sourates_eleve(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.sourates_bases_classe(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.sourates_eleve(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.sourates_bases_classe(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SOURATES : droits inattendus';
  END IF;
END
$postflight$;

COMMIT;
