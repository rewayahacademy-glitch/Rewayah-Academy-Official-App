-- MA-PROGRESSION (08/11/2026, directeur) : « ou il etait, ou il est, ou il doit etre, quoi
-- faire, combien de temps ». Une seule lecture serveur pour l'eleve et sa famille, et le
-- reglage de l'administration qui lui manque.
--
-- Sans mot d'effacement (B5). Migration additive : une table neuve, une lecture neuve, deux
-- fonctions d'administration neuves. Aucune fonction existante n'est modifiee.
--
-- Principes (arbitrages du pilote, 08/11/2026 13:10, puis decision du directeur du 11/11/2026 :
-- « sourate validee » = l'enseignant coche la sourate au cahier) :
--   1. `ma_progression` APPELLE `suivi_pedagogique_eleve` (etape, objectifs, duree prevue,
--      date limite, vitesse, page de reprise) : la garde est celle de cette fonction, sans
--      copie (l'eleve lui-meme, le titulaire de son profil, le tuteur du foyer ; 42501 sinon).
--      Elle n'ajoute que ce qui manque : les etapes du cycle dans l'ordre, les etapes
--      franchies avec leur date, les sourates, le reglage de l'etape.
--   2. Tout vient de la version publiee du programme et du corpus. Aucun texte ecrit a la main.
--   3. L'avancement se compte en SOURATES, jamais en versets. Les sourates et leur validation
--      ne sont PAS dans cette migration : elles viennent du lot SOURATES (migration
--      20261122900000), source unique des 17 sourates des bases (private.sourates_des_bases) et
--      des sourates validees par l'enseignant au cahier (public.sourates_validees).
--      `ma_progression` appelle `public.sourates_eleve(p_student_id)` (meme porte que
--      `suivi_pedagogique_eleve`) et la place telle quelle sous `sourates` : aucune copie,
--      aucune liste ecrite ici, plus de position de la Classe.
--   4. Ne sortent jamais : le motif d'un changement d'etape, le nom de celui qui l'a decide,
--      les notes, rien d'un autre eleve.
--   5. Heures de revision par semaine et repetitions estimees : reglage de l'administration par
--      etape, VIDE par defaut. Aucune valeur inventee.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.programme_etape_reglages') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.ma_progression(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'MA-PROGRESSION : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.suivi_pedagogique_eleve(uuid)') IS NULL THEN
    RAISE EXCEPTION 'MA-PROGRESSION : SUIVI-ELEVE absent (suivi_pedagogique_eleve)';
  END IF;
  IF pg_catalog.to_regprocedure('public.sourates_eleve(uuid)') IS NULL THEN
    RAISE EXCEPTION 'MA-PROGRESSION : lot SOURATES absent (sourates_eleve, migration 20261122900000)';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le reglage par etape (cle stable entre les versions du programme : le code technique)
-- ---------------------------------------------------------------------------
CREATE TABLE public.programme_etape_reglages (
  code_technique text PRIMARY KEY CHECK (pg_catalog.btrim(code_technique) <> ''),
  heures_revision_semaine numeric(4, 1) CHECK (heures_revision_semaine IS NULL OR heures_revision_semaine > 0),
  repetitions_estimees integer CHECK (repetitions_estimees IS NULL OR repetitions_estimees > 0),
  mis_a_jour_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  mis_a_jour_par uuid REFERENCES public.profiles(id)
);

COMMENT ON TABLE public.programme_etape_reglages IS
  'MA-PROGRESSION (08/11/2026) : par etape du programme (code technique, stable entre versions), '
  'vides par defaut, les heures de revision par semaine et les repetitions estimees. Les sourates '
  'ne sont pas ici : elles viennent du lot SOURATES. Ecriture par la direction seule, par '
  'fonction. Aucun acces direct.';

ALTER TABLE public.programme_etape_reglages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.programme_etape_reglages FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 2. Le reglage par la direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.regler_etape_progression(
  p_code_technique text,
  p_heures_revision_semaine numeric,
  p_repetitions_estimees integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reglage de la progression reserve a l''administration' USING errcode = '42501';
  END IF;
  IF p_code_technique IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.programme_niveaux n WHERE n.code_technique = p_code_technique) THEN
    RAISE EXCEPTION 'etape inconnue';
  END IF;
  INSERT INTO public.programme_etape_reglages
    (code_technique, heures_revision_semaine, repetitions_estimees, mis_a_jour_le, mis_a_jour_par)
  VALUES
    (p_code_technique, p_heures_revision_semaine, p_repetitions_estimees,
     pg_catalog.now(), auth.uid())
  ON CONFLICT (code_technique) DO UPDATE
    SET heures_revision_semaine = EXCLUDED.heures_revision_semaine,
        repetitions_estimees = EXCLUDED.repetitions_estimees,
        mis_a_jour_le = EXCLUDED.mis_a_jour_le,
        mis_a_jour_par = EXCLUDED.mis_a_jour_par;
  PERFORM public.log_sensitive_access(
    'progression_etape_reglee', 'programme_etape_reglages', p_code_technique,
    pg_catalog.jsonb_build_object('heures', p_heures_revision_semaine IS NOT NULL,
                                  'repetitions', p_repetitions_estimees IS NOT NULL));
END;
$function$;

CREATE FUNCTION public.reglages_progression_admin()
RETURNS TABLE (
  code_technique text,
  heures_revision_semaine numeric,
  repetitions_estimees integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture des reglages reservee a l''administration' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT r.code_technique, r.heures_revision_semaine, r.repetitions_estimees
      FROM public.programme_etape_reglages r
     ORDER BY r.code_technique;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. La lecture de l'eleve et de sa famille
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.ma_progression(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_suivi record;
  v_version uuid;
  v_courant public.programme_niveaux%ROWTYPE;
  v_etape jsonb := NULL;
  v_cycle jsonb := '[]'::jsonb;
  v_reglage jsonb := NULL;
BEGIN
  -- La garde est celle de suivi_pedagogique_eleve : 42501 si l'appelant n'est ni l'eleve, ni le
  -- titulaire de son profil, ni le tuteur de son foyer. Aucune copie de cette garde ici.
  SELECT * INTO v_suivi FROM public.suivi_pedagogique_eleve(p_student_id) s LIMIT 1;
  IF NOT FOUND THEN
    -- Autorise, mais sans Classe active ni etape publiee : pas d'etape a montrer. Les sourates
    -- validees, elles, sont rendues QUAND MEME : ce que l'eleve a acquis lui appartient
    -- (arbitrage du garde-cap et du pilote, 11/11/2026 ; meme porte que la lecture).
    RETURN pg_catalog.jsonb_build_object('etape', NULL, 'etapes_du_cycle', '[]'::jsonb,
                                         'sourates', public.sourates_eleve(p_student_id),
                                         'reglage', NULL);
  END IF;

  SELECT v.id INTO v_version
    FROM public.programme_versions v
   WHERE v.statut = 'publiee'
   ORDER BY v.numero_version DESC LIMIT 1;

  SELECT n.* INTO v_courant
    FROM public.programme_niveaux n
   WHERE n.version_id = v_version AND n.cycle = v_suivi.cycle AND n.ordre = v_suivi.etape_ordre
   LIMIT 1;

  v_etape := pg_catalog.jsonb_build_object(
    'nom', v_suivi.etape_nom,
    'ordre', v_suivi.etape_ordre,
    'cycle', v_suivi.cycle,
    'objectifs', pg_catalog.to_jsonb(v_suivi.objectifs),
    'duree_prevue_semaines', v_suivi.duree_prevue_semaines,
    'date_limite', v_suivi.date_limite,
    'depuis', v_suivi.depuis,
    'semaines_ecoulees', v_suivi.semaines_ecoulees,
    'rythme', v_suivi.rythme,
    'page_reprise', v_suivi.page_reprise,
    'page_reprise_le', v_suivi.page_reprise_le);

  -- Les etapes du cycle dans l'ordre, la sienne marquee, avec la date a laquelle il y est entre.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'ordre', n.ordre,
           'nom', n.nom_humain,
           'statut', CASE WHEN n.ordre < v_suivi.etape_ordre THEN 'franchie'
                          WHEN n.ordre = v_suivi.etape_ordre THEN 'en_cours'
                          ELSE 'a_venir' END,
           'atteinte_le', (SELECT pg_catalog.min(h.created_at)
                             FROM public.progression_historique h
                             JOIN public.programme_niveaux hn ON hn.id = h.niveau_id
                            WHERE h.student_id = p_student_id AND hn.code_technique = n.code_technique))
           ORDER BY n.ordre), '[]'::jsonb)
    INTO v_cycle
    FROM public.programme_niveaux n
   WHERE n.version_id = v_version AND n.cycle = v_suivi.cycle;

  -- Le reglage de l'etape en cours : vide tant que la direction n'a rien rempli.
  IF v_courant.id IS NOT NULL THEN
    SELECT pg_catalog.jsonb_build_object(
             'heures_revision_semaine', r.heures_revision_semaine,
             'repetitions_estimees', r.repetitions_estimees)
      INTO v_reglage
      FROM public.programme_etape_reglages r
     WHERE r.code_technique = v_courant.code_technique
       AND (r.heures_revision_semaine IS NOT NULL OR r.repetitions_estimees IS NOT NULL);
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'etape', v_etape,
    'etapes_du_cycle', v_cycle,
    -- Les sourates : source unique du lot SOURATES (17 sourates des bases, validees par
    -- l'enseignant au cahier), meme porte que suivi_pedagogique_eleve. Rien n'est copie ici.
    'sourates', public.sourates_eleve(p_student_id),
    'reglage', v_reglage);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Droits
-- ---------------------------------------------------------------------------
ALTER FUNCTION public.regler_etape_progression(text, numeric, integer) OWNER TO postgres;
ALTER FUNCTION public.reglages_progression_admin() OWNER TO postgres;
ALTER FUNCTION public.ma_progression(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.regler_etape_progression(text, numeric, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.reglages_progression_admin() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.ma_progression(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.regler_etape_progression(text, numeric, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reglages_progression_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ma_progression(uuid) TO authenticated;

COMMENT ON FUNCTION public.ma_progression(uuid) IS
  'MA-PROGRESSION (08/11/2026) : etape, etapes du cycle (franchies, en cours, a venir), sourates '
  '(celles que l''enseignant a validees au cahier, jamais en versets, lues dans sourates_eleve) et '
  'reglage de l''etape, pour l''eleve et sa famille. Garde de suivi_pedagogique_eleve. Ni motif, '
  'ni decideur, ni notes.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_progression(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ma_progression(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.regler_etape_progression(text, numeric, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.regler_etape_progression(text, numeric, integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.reglages_progression_admin()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.reglages_progression_admin()', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'SELECT') THEN
    RAISE EXCEPTION 'MA-PROGRESSION : droits inattendus';
  END IF;
END
$postflight$;
