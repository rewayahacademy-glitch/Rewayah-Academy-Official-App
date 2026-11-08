-- MA-PROGRESSION (08/11/2026, directeur) : « ou il etait, ou il est, ou il doit etre, quoi
-- faire, combien de temps ». Une seule lecture serveur pour l'eleve et sa famille, et le
-- reglage de l'administration qui lui manque.
--
-- Sans mot d'effacement (B5). Migration additive : une table neuve, une lecture neuve, deux
-- fonctions d'administration neuves. Aucune fonction existante n'est modifiee.
--
-- Principes (arbitrages du pilote, 08/11/2026 13:10) :
--   1. `ma_progression` APPELLE `suivi_pedagogique_eleve` (etape, objectifs, duree prevue,
--      date limite, vitesse, page de reprise) : la garde est celle de cette fonction, sans
--      copie (l'eleve lui-meme, le titulaire de son profil, le tuteur du foyer ; 42501 sinon).
--      Elle n'ajoute que ce qui manque : les etapes du cycle dans l'ordre, les etapes
--      franchies avec leur date, les sourates, le reglage de l'etape.
--   2. Tout vient de la version publiee du programme et du corpus. Aucun texte ecrit a la main.
--   3. L'avancement se compte en SOURATES, jamais en versets. La liste des sourates d'une
--      etape est une donnee structuree (numeros de sourate, noms lus dans le corpus), reglable
--      par la direction. Seed : les 17 sourates des bases (Al-Fatiha, puis 114 a 99), etape
--      BASES-4 (programme-rewayah §2).
--   4. « Acquises » = sourates ETUDIEES PAR LA CLASSE : celles qui precedent, dans l'ordre de
--      la liste, la sourate ou se trouve la page de reprise de la Classe. C'est la position de
--      la CLASSE, pas une maitrise de l'eleve : la lecture le dit (`position_de_la_classe`).
--      Sans page de reprise sur le Mushaf, ou etape avant celle des sourates : NULL, jamais 0.
--      Etape apres celle des sourates : toutes.
--   5. Ne sortent jamais : le motif d'un changement d'etape, le nom de celui qui l'a decide,
--      les notes, rien d'un autre eleve.
--   6. Heures de revision par semaine et repetitions estimees : reglage de l'administration par
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
  IF (SELECT pg_catalog.count(*) FROM public.sourate) <> 114 THEN
    RAISE EXCEPTION 'MA-PROGRESSION : le corpus des sourates est incomplet';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.mushaf WHERE code = 'madina-hafs-604') THEN
    RAISE EXCEPTION 'MA-PROGRESSION : Mushaf madina-hafs-604 absent';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le reglage par etape (cle stable entre les versions du programme : le code technique)
-- ---------------------------------------------------------------------------
CREATE TABLE public.programme_etape_reglages (
  code_technique text PRIMARY KEY CHECK (pg_catalog.btrim(code_technique) <> ''),
  -- Les numeros sont verifies contre le corpus par regler_etape_progression (une contrainte
  -- ne peut pas lire une autre table) ; ici, seulement une borne.
  sourates integer[] NOT NULL DEFAULT '{}'::integer[]
    CHECK (pg_catalog.cardinality(sourates) <= 114),
  heures_revision_semaine numeric(4, 1) CHECK (heures_revision_semaine IS NULL OR heures_revision_semaine > 0),
  repetitions_estimees integer CHECK (repetitions_estimees IS NULL OR repetitions_estimees > 0),
  mis_a_jour_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  mis_a_jour_par uuid REFERENCES public.profiles(id)
);

COMMENT ON TABLE public.programme_etape_reglages IS
  'MA-PROGRESSION (08/11/2026) : par etape du programme (code technique, stable entre versions), '
  'la liste ordonnee de ses sourates et, vides par defaut, les heures de revision par semaine et '
  'les repetitions estimees. Ecriture par la direction seule, par fonction. Aucun acces direct.';

ALTER TABLE public.programme_etape_reglages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.programme_etape_reglages FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Seed : les 17 sourates des bases, dans l'ordre d'etude (Al-Fatiha, puis 114 a 99).
INSERT INTO public.programme_etape_reglages (code_technique, sourates)
VALUES ('BASES-4', ARRAY(SELECT 1 UNION ALL SELECT g FROM pg_catalog.generate_series(114, 99, -1) g))
ON CONFLICT (code_technique) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Le reglage par la direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.regler_etape_progression(
  p_code_technique text,
  p_sourates integer[],
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
  IF p_sourates IS NULL THEN
    p_sourates := '{}'::integer[];
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.unnest(p_sourates) s
              WHERE s IS NULL OR NOT EXISTS (SELECT 1 FROM public.sourate c WHERE c.numero = s))
     OR (SELECT pg_catalog.count(DISTINCT s) FROM pg_catalog.unnest(p_sourates) s)
        <> pg_catalog.cardinality(p_sourates) THEN
    RAISE EXCEPTION 'sourates invalides : numeros du corpus, sans doublon';
  END IF;
  INSERT INTO public.programme_etape_reglages
    (code_technique, sourates, heures_revision_semaine, repetitions_estimees, mis_a_jour_le, mis_a_jour_par)
  VALUES
    (p_code_technique, p_sourates, p_heures_revision_semaine, p_repetitions_estimees,
     pg_catalog.now(), auth.uid())
  ON CONFLICT (code_technique) DO UPDATE
    SET sourates = EXCLUDED.sourates,
        heures_revision_semaine = EXCLUDED.heures_revision_semaine,
        repetitions_estimees = EXCLUDED.repetitions_estimees,
        mis_a_jour_le = EXCLUDED.mis_a_jour_le,
        mis_a_jour_par = EXCLUDED.mis_a_jour_par;
  PERFORM public.log_sensitive_access(
    'progression_etape_reglee', 'programme_etape_reglages', p_code_technique,
    pg_catalog.jsonb_build_object('sourates', pg_catalog.cardinality(p_sourates)));
END;
$function$;

CREATE FUNCTION public.reglages_progression_admin()
RETURNS TABLE (
  code_technique text,
  sourates integer[],
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
    SELECT r.code_technique, r.sourates, r.heures_revision_semaine, r.repetitions_estimees
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
  v_sourates jsonb := NULL;
  v_reglage jsonb := NULL;
  v_liste integer[];
  v_ordre_min integer;
  v_ordre_max integer;
  v_acquises integer := NULL;
  v_page integer;
  v_pos integer;
BEGIN
  -- La garde est celle de suivi_pedagogique_eleve : 42501 si l'appelant n'est ni l'eleve, ni le
  -- titulaire de son profil, ni le tuteur de son foyer. Aucune copie de cette garde ici.
  SELECT * INTO v_suivi FROM public.suivi_pedagogique_eleve(p_student_id) s LIMIT 1;
  IF NOT FOUND THEN
    -- Autorise, mais sans Classe active ni etape publiee : rien a montrer.
    RETURN pg_catalog.jsonb_build_object('etape', NULL, 'etapes_du_cycle', '[]'::jsonb,
                                         'sourates', NULL, 'reglage', NULL);
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

  -- Les sourates du cycle, dans l'ordre d'etude (ordre de l'etape, puis ordre de la liste).
  SELECT pg_catalog.array_agg(x.numero ORDER BY x.ordre, x.rang),
         pg_catalog.min(x.ordre), pg_catalog.max(x.ordre)
    INTO v_liste, v_ordre_min, v_ordre_max
    FROM (
      SELECT n.ordre, u.numero, u.rang
        FROM public.programme_niveaux n
        JOIN public.programme_etape_reglages r ON r.code_technique = n.code_technique
        CROSS JOIN LATERAL pg_catalog.unnest(r.sourates) WITH ORDINALITY AS u(numero, rang)
       WHERE n.version_id = v_version AND n.cycle = v_suivi.cycle
    ) x;

  IF v_liste IS NOT NULL THEN
    v_page := v_suivi.page_reprise;
    IF v_suivi.etape_ordre > v_ordre_max THEN
      v_acquises := pg_catalog.cardinality(v_liste);
    ELSIF v_suivi.etape_ordre >= v_ordre_min
          AND v_page IS NOT NULL
          AND coalesce(v_courant.plage_support ->> 'support', '') = 'mushaf' THEN
      -- La premiere sourate de la liste dont les pages contiennent la page de reprise.
      SELECT pg_catalog.min(t.i) INTO v_pos
        FROM pg_catalog.unnest(v_liste) WITH ORDINALITY AS t(numero, i)
       WHERE EXISTS (
         SELECT 1
           FROM public.verset vs
           JOIN public.mushaf m ON m.id = vs.mushaf_id AND m.code = 'madina-hafs-604'
          WHERE vs.sourate_numero = t.numero
          GROUP BY vs.sourate_numero
         HAVING pg_catalog.min(vs.page_numero) <= v_page AND pg_catalog.max(vs.page_numero) >= v_page);
      IF v_pos IS NOT NULL THEN
        v_acquises := v_pos - 1;
      END IF;
    END IF;

    v_sourates := pg_catalog.jsonb_build_object(
      'total', pg_catalog.cardinality(v_liste),
      -- Position de la CLASSE, pas une maitrise de l'eleve (NULL si inconnue).
      'position_de_la_classe', v_acquises,
      'liste', (
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'numero', c.numero,
                 'nom', c.nom_translittere,
                 'nom_arabe', c.nom_arabe,
                 'etudiee_par_la_classe', CASE WHEN v_acquises IS NULL THEN NULL
                                               ELSE t.i <= v_acquises END)
               ORDER BY t.i)
          FROM pg_catalog.unnest(v_liste) WITH ORDINALITY AS t(numero, i)
          JOIN public.sourate c ON c.numero = t.numero));
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'etape', v_etape,
    'etapes_du_cycle', v_cycle,
    'sourates', v_sourates,
    'reglage', v_reglage);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Droits
-- ---------------------------------------------------------------------------
ALTER FUNCTION public.regler_etape_progression(text, integer[], numeric, integer) OWNER TO postgres;
ALTER FUNCTION public.reglages_progression_admin() OWNER TO postgres;
ALTER FUNCTION public.ma_progression(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.regler_etape_progression(text, integer[], numeric, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.reglages_progression_admin() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.ma_progression(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.regler_etape_progression(text, integer[], numeric, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reglages_progression_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ma_progression(uuid) TO authenticated;

COMMENT ON FUNCTION public.ma_progression(uuid) IS
  'MA-PROGRESSION (08/11/2026) : etape, etapes du cycle (franchies, en cours, a venir), sourates '
  '(total et position de la CLASSE, jamais en versets) et reglage de l''etape, pour l''eleve et sa '
  'famille. Garde de suivi_pedagogique_eleve. Ni motif, ni decideur, ni notes.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_progression(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ma_progression(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.regler_etape_progression(text, integer[], numeric, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.regler_etape_progression(text, integer[], numeric, integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.reglages_progression_admin()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.reglages_progression_admin()', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'SELECT') THEN
    RAISE EXCEPTION 'MA-PROGRESSION : droits inattendus';
  END IF;
  IF (SELECT pg_catalog.cardinality(sourates) FROM public.programme_etape_reglages WHERE code_technique = 'BASES-4') IS DISTINCT FROM 17 THEN
    RAISE EXCEPTION 'MA-PROGRESSION : les 17 sourates des bases ne sont pas posees';
  END IF;
END
$postflight$;
