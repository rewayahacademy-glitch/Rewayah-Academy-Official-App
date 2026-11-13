-- MA-PROGRESSION sur le SOCLE-PROGRAMME (13/11/2026, numero 20261123910000, apres 900000 qui
-- pose etape_eleve_lecture) : UN SEUL point d'entree pour
-- la progression de l'eleve et de sa famille.
--
-- Le doublon : 20261123830000 (deja installee, jamais modifiee) construit
-- l'etape et le cycle a sa facon, depuis suivi_pedagogique_eleve et la version
-- PUBLIEE du programme ; 20261123900000 (SOCLE-PROGRAMME) pose LA lecture de
-- l'etape (public.etape_eleve_lecture) : fait unique par eleve, version propre a
-- l'eleve, matieres, dates retenues pour l'enfant de 6 a 9 ans. Deux calculs de
-- la meme chose se contrediraient (la fiche d'un enfant de 6 a 9 ans recevait
-- des dates par `atteinte_le` et `rythme`).
--
-- Ce que fait ce fichier, et rien d'autre : ma_progression garde sa signature,
-- son proprietaire, ses droits et sa garde (celle de suivi_pedagogique_eleve,
-- sans copie), et prend desormais son etape, son chemin et ses dates de
-- etape_eleve_lecture. Les cles d'avant restent (`etape`, `etapes_du_cycle` avec
-- `franchie`, `en_cours`, `a_venir`, `sourates`, `reglage`) pour que l'ecran
-- deja en ligne continue de lire ; des cles s'y ajoutent (matieres, entree dans
-- l'etape, duree et date limite de chaque etape du chemin, `niveau`,
-- `eleve_voit_dates`, `attente`). Pour l'eleve qui lit pour lui-meme et ne voit pas
-- ses dates (6 a 9 ans), aucune date ni duree ni rythme, `atteinte_le` compris.
-- Les anciennes cles de statut sont gardees jusqu'au lot 10 (retrait de
-- suivi_pedagogique_eleve). Aucune donnee n'est ecrite ni modifiee.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.ma_progression(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.etape_eleve_lecture(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.suivi_pedagogique_eleve(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.sourates_eleve(uuid)') IS NULL
     OR pg_catalog.to_regclass('public.programme_etape_reglages') IS NULL THEN
    RAISE EXCEPTION 'MA-PROGRESSION sur le socle : MA-PROGRESSION (20261123830000) ou SOCLE-PROGRAMME (20261123900000) absent';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION public.ma_progression(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_suivi record;
  v_lect jsonb;
  v_etape jsonb := NULL;
  v_cycle jsonb := '[]'::jsonb;
  v_reglage jsonb := NULL;
  v_masque boolean;
  v_code text;
  v_trouve boolean;
BEGIN
  -- La garde est celle de suivi_pedagogique_eleve : 42501 si l'appelant n'est ni l'eleve, ni le
  -- titulaire de son profil, ni le tuteur de son foyer. Aucune copie de cette garde ici.
  SELECT * INTO v_suivi FROM public.suivi_pedagogique_eleve(p_student_id) s LIMIT 1;
  v_trouve := FOUND;
  -- LA lecture de l'etape (SOCLE-PROGRAMME) : meme garde, qui laisse passer ces trois appelants.
  v_lect := public.etape_eleve_lecture(p_student_id);

  IF NOT v_trouve OR v_lect IS NULL OR v_lect ->> 'attente' IS NOT NULL THEN
    -- Autorise, mais sans Classe active ni etape : pas d'etape a montrer. Les sourates
    -- validees, elles, sont rendues QUAND MEME : ce que l'eleve a acquis lui appartient
    -- (arbitrage du garde-cap et du pilote, 11/11/2026 ; meme porte que la lecture).
    -- Un eleve qui attend l'entretien de lecture le dit (`attente`) : aucune etape supposee.
    RETURN pg_catalog.jsonb_build_object('etape', NULL, 'etapes_du_cycle', '[]'::jsonb,
                                         'sourates', public.sourates_eleve(p_student_id),
                                         'reglage', NULL)
           || CASE WHEN v_lect ->> 'attente' IS NOT NULL
                   THEN pg_catalog.jsonb_build_object('attente', v_lect ->> 'attente')
                   ELSE '{}'::jsonb END;
  END IF;

  v_masque := NOT coalesce((v_lect -> 'niveau' ->> 'date_limite_visible')::boolean, false);
  v_code := v_lect -> 'etape' ->> 'code';

  -- L'etape : celle de la lecture unique (ses cles incluent nom, ordre, objectifs, matieres,
  -- durees, entree, date limite, semaines ecoulees, rythme), plus le cycle et la reprise de la Classe.
  v_etape := (v_lect -> 'etape')
             || pg_catalog.jsonb_build_object(
                  'cycle', v_suivi.cycle,
                  'page_reprise', v_lect -> 'page_reprise',
                  'page_reprise_le', v_suivi.page_reprise_le);

  -- Les etapes du chemin dans l'ordre, la sienne marquee : les passees et la sienne dans SA
  -- version, les a-venir dans la version publiee. `franchie` pour une etape passee (cle d'avant),
  -- avec la date d'entree dans l'etape seulement si l'eleve voit ses dates.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'ordre', x -> 'ordre',
           'nom', x -> 'nom',
           'statut', CASE WHEN x ->> 'statut' = 'precedente' THEN 'franchie' ELSE x ->> 'statut' END,
           'atteinte_le', CASE WHEN v_masque THEN NULL
                               ELSE (SELECT pg_catalog.min(h.created_at)
                                       FROM public.progression_historique h
                                       JOIN public.programme_niveaux hn ON hn.id = h.niveau_id
                                      WHERE h.student_id = p_student_id AND hn.code_technique = x ->> 'code') END,
           'objectifs', x -> 'objectifs',
           'duree_prevue_semaines', x -> 'duree_prevue_semaines',
           'date_limite_semaines', x -> 'date_limite_semaines')
           ORDER BY (x ->> 'ordre')::int), '[]'::jsonb)
    INTO v_cycle
    FROM pg_catalog.jsonb_array_elements(v_lect -> 'chemin') x;

  -- Le reglage de l'etape en cours : vide tant que la direction n'a rien rempli.
  IF v_code IS NOT NULL THEN
    SELECT pg_catalog.jsonb_build_object(
             'heures_revision_semaine', r.heures_revision_semaine,
             'repetitions_estimees', r.repetitions_estimees)
      INTO v_reglage
      FROM public.programme_etape_reglages r
     WHERE r.code_technique = v_code
       AND (r.heures_revision_semaine IS NOT NULL OR r.repetitions_estimees IS NOT NULL);
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'etape', v_etape,
    'etapes_du_cycle', v_cycle,
    -- Les sourates : source unique du lot SOURATES (17 sourates des bases, validees par
    -- l'enseignant au cahier), meme porte que suivi_pedagogique_eleve. Rien n'est copie ici.
    'sourates', public.sourates_eleve(p_student_id),
    'reglage', v_reglage,
    'niveau', v_lect -> 'niveau',
    'eleve_voit_dates', v_lect -> 'eleve_voit_dates');
END;
$function$;

COMMENT ON FUNCTION public.ma_progression(uuid) IS
  'MA-PROGRESSION (08/11/2026), sur le SOCLE-PROGRAMME (13/11/2026) : etape, chemin du niveau '
  '(franchies, en cours, a venir), matieres, dates retenues pour l''enfant de 6 a 9 ans qui lit '
  'pour lui-meme, sourates (celles que l''enseignant a validees au cahier, jamais en versets, '
  'lues dans sourates_eleve) et reglage de l''etape, pour l''eleve et sa famille. Etape et dates '
  'lues dans etape_eleve_lecture. Garde de suivi_pedagogique_eleve. Ni motif, ni decideur, ni notes.';

-- Droits d'avant (CREATE OR REPLACE les garde ; redits pour qu'un ecart se voie).
REVOKE ALL ON FUNCTION public.ma_progression(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_progression(uuid) TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_progression(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ma_progression(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.ma_progression(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'MA-PROGRESSION sur le socle : droits inattendus';
  END IF;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.ma_progression(uuid)'::pg_catalog.regprocedure),
       'public.etape_eleve_lecture(p_student_id)') = 0 THEN
    RAISE EXCEPTION 'MA-PROGRESSION sur le socle : la lecture unique n''est pas appelee';
  END IF;
END
$postflight$;
