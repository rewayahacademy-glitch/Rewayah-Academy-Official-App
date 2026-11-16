-- LP-1 serveur (SPEC-LISTE-PERSONNES-2026-11-16, §3) : une seule liste paginee des enseignants, pour
-- toute leur vie, servie par le serveur.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : trois fonctions privees, une
-- fonction publique en lecture, aucune table, aucune ecriture. Sans BEGIN/COMMIT de premier niveau.
--
-- Reutilise, sans les recopier : private.cand_lecteur (portee par genre, exception super admin),
-- private.cand_ligne_json (les 23 cles d'une ligne de candidature), private.be_predicat (filtres
-- responsable, nouveau, pieceEnAttente), private.be_filtre_valider, private.cand_normaliser,
-- private.candidature_regle et private.candidature_gestes_regles (les gestes permis par ligne, avec
-- leur marque `groupable`), private.be_nouvelle, public.log_sensitive_access. Les gestes groupes
-- eux-memes restent ceux qui existent (apercu_lot_candidats, executer_lot_candidats).
--
-- Une personne n'apparait qu'une fois : la ligne d'un enseignant est son dossier de candidature
-- (type `enseignant`), complete par ce qui se passe apres l'embauche. Un compte enseignant sans
-- dossier de candidature n'a pas de ligne ; il est compte a part (`compteursPhases.sansDossier`).
--
-- Les phases (calculees par le serveur, jamais par l'ecran) :
--   candidat   : la candidature n'est pas confirmee, ou elle est refusee / retiree ;
--   accueil    : confirmee, il manque encore quelque chose (liste `manque`) ;
--   disponible : confirmee, rien ne manque, aucune classe ;
--   en_poste   : au moins une classe en cours ;
--   absent     : en poste, avec une absence declaree sur une seance a venir sans remplacant ;
--   pause      : confirmee et mise en pause par la direction ;
--   suspendu   : compte desactive ;
--   parti      : compte supprime (masque par defaut ; filtre `partis`).
-- Non fournis par ce lot, faute de donnee dans la base : la formation, la periode d'essai, la fin de
-- collaboration decidee par la direction, le contrat, la presence et l'avancement des classes.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.lister_enseignants(jsonb,text,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'LP-1 : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.be_nouvelle(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_regle(public.candidatures,text,text,smallint,boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.cand_lecteur()') IS NULL THEN
    RAISE EXCEPTION 'LP-1 : dependances absentes (NOUVEAU-LISTE, moteur des gestes)';
  END IF;
END
$preflight$;

-- ============================================================
-- 1. La phase d'un enseignant et ce qui lui manque
-- ============================================================
CREATE FUNCTION private.lp_phase(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  v_p public.profiles;
  v_tp public.teacher_profiles;
  v_manque text[] := ARRAY[]::text[];
  v_classes integer;
BEGIN
  IF c.issue IS DISTINCT FROM 'en_cours' OR c.etape IS DISTINCT FROM 'confirmee' THEN
    RETURN pg_catalog.jsonb_build_object('phase', 'candidat', 'manque', '[]'::jsonb);
  END IF;
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = c.profile_id;
  IF v_p.id IS NULL OR v_p.deleted_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('phase', 'parti', 'manque', '[]'::jsonb);
  END IF;
  IF v_p.account_status = 'disabled'::public.account_status THEN
    RETURN pg_catalog.jsonb_build_object('phase', 'suspendu', 'manque', '[]'::jsonb);
  END IF;
  IF c.en_pause THEN
    RETURN pg_catalog.jsonb_build_object('phase', 'pause', 'manque', '[]'::jsonb);
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_classes
    FROM public.groupes g WHERE g.teacher_id = c.profile_id AND g.ended_at IS NULL;
  IF v_classes > 0 THEN
    IF EXISTS (
         SELECT 1
           FROM public.remplacements_seance a
           JOIN public.sessions s ON s.id = a.session_id
          WHERE a.evenement = 'absence_declaree'
            AND a.enseignant_titulaire_id = c.profile_id
            AND s.started_at >= pg_catalog.now() - interval '2 hours'
            AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance b
                             WHERE b.session_id = a.session_id
                               AND b.evenement IN ('remplacement_pris', 'remplacement_designe_admin'))) THEN
      RETURN pg_catalog.jsonb_build_object('phase', 'absent', 'manque', '[]'::jsonb);
    END IF;
    RETURN pg_catalog.jsonb_build_object('phase', 'en_poste', 'manque', '[]'::jsonb);
  END IF;

  -- Les memes causes que public.affectation_candidat, plus les trois prerequis de l'enseignant.
  SELECT tp.* INTO v_tp FROM public.teacher_profiles tp
   WHERE tp.profile_id = c.profile_id AND tp.deleted_at IS NULL;
  IF v_p.role IS DISTINCT FROM 'teacher'::public.app_role
     OR v_p.account_status NOT IN ('active'::public.account_status, 'provisional_active'::public.account_status)
     OR (v_p.access_until IS NOT NULL AND v_p.access_until <= pg_catalog.now()) THEN
    v_manque := pg_catalog.array_append(v_manque, 'compte_inactif'::text);
  END IF;
  IF v_tp.kyc_status IS DISTINCT FROM 'approved' THEN
    v_manque := pg_catalog.array_append(v_manque, 'piece_non_validee'::text);
  END IF;
  IF coalesce(pg_catalog.cardinality(v_tp.languages), 0) = 0 THEN
    v_manque := pg_catalog.array_append(v_manque, 'langues_absentes'::text);
  END IF;
  IF v_p.gender IS NULL THEN
    v_manque := pg_catalog.array_append(v_manque, 'genre_inconnu'::text);
  END IF;
  IF private.cand_indisponible(c) THEN
    v_manque := pg_catalog.array_append(v_manque, 'indisponible'::text);
  END IF;
  IF v_tp.photo_storage_key IS NULL THEN
    v_manque := pg_catalog.array_append(v_manque, 'photo_absente'::text);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.weekly_availability wa WHERE wa.profile_id = c.profile_id) THEN
    v_manque := pg_catalog.array_append(v_manque, 'disponibilites_absentes'::text);
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'phase', CASE WHEN pg_catalog.cardinality(v_manque) = 0 THEN 'disponible' ELSE 'accueil' END,
    'manque', pg_catalog.to_jsonb(v_manque));
END;
$function$;
ALTER FUNCTION private.lp_phase(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.lp_phase(public.candidatures) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 2. Les gestes permis sur une ligne, et qui attend quoi
-- ============================================================
CREATE FUNCTION private.lp_gestes(c public.candidatures, p_decider boolean)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'gestes', coalesce(pg_catalog.jsonb_agg(x.geste ORDER BY x.geste), '[]'::jsonb),
    'gestesGroupables', coalesce(pg_catalog.jsonb_agg(x.geste ORDER BY x.geste) FILTER (WHERE x.groupable),
                                 '[]'::jsonb))
  FROM (
    SELECT r.geste, pg_catalog.bool_or(r.groupable) AS groupable
      FROM private.candidature_gestes_regles r
     WHERE p_decider
       AND 'direction' = ANY (r.auteurs)
       AND (private.candidature_regle(c, r.geste, 'direction', NULL, false)).geste IS NOT NULL
     GROUP BY r.geste
  ) x;
$function$;
ALTER FUNCTION private.lp_gestes(public.candidatures, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.lp_gestes(public.candidatures, boolean) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Qui attend quoi : `candidat` si une regle du candidat s'applique a l'etat, `direction` si une
-- regle d'avancement de la direction s'applique, `enseignant` quand il manque quelque chose a un
-- enseignant en accueil, `direction` pour affecter un enseignant disponible, sinon rien.
CREATE FUNCTION private.lp_qui_attend(c public.candidatures, p_phase text)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_phase = 'accueil' THEN 'enseignant'
    WHEN p_phase = 'disponible' THEN 'direction'
    WHEN p_phase <> 'candidat' OR c.en_pause OR c.issue <> 'en_cours' THEN NULL
    WHEN EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                  WHERE 'candidat' = ANY (r.auteurs) AND r.geste IN ('envoyer_reponses', 'planifier_entretien')
                    AND (private.candidature_regle(c, r.geste, 'candidat', NULL, false)).geste IS NOT NULL)
      THEN 'candidat'
    WHEN EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                  WHERE 'direction' = ANY (r.auteurs)
                    AND r.geste IN ('inviter', 'demander_complement', 'admettre_verifications',
                                    'planifier_entretien', 'consigner_entretien_tenu',
                                    'consigner_entretien_non_tenu', 'valider_piece',
                                    'accepter_admission', 'preciser_admission',
                                    'confirmer_moyen_paiement', 'debloquer_versement')
                    AND (private.candidature_regle(c, r.geste, 'direction', NULL, false)).geste IS NOT NULL)
      THEN 'direction'
    ELSE NULL
  END;
$function$;
ALTER FUNCTION private.lp_qui_attend(public.candidatures, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.lp_qui_attend(public.candidatures, text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 3. La ligne : la ligne de candidature, plus la vie de l'enseignant
-- ============================================================
CREATE FUNCTION private.lp_ligne_json(c public.candidatures, p_decider boolean)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  v_ph jsonb := private.lp_phase(c);
  v_phase text := v_ph ->> 'phase';
  v_classes jsonb;
  v_gestes jsonb := private.lp_gestes(c, p_decider);
  v_actions jsonb := '[]'::jsonb;
BEGIN
  SELECT pg_catalog.jsonb_build_object(
           'nombre', (SELECT pg_catalog.count(*)::integer FROM public.groupes g
                       WHERE g.teacher_id = c.profile_id AND g.ended_at IS NULL),
           'heuresSemaine', coalesce((SELECT pg_catalog.round(pg_catalog.sum(k.duree_minutes) / 60.0, 2)
                                        FROM public.groupe_creneaux k
                                        JOIN public.groupes g ON g.id = k.groupe_id
                                       WHERE g.teacher_id = c.profile_id AND g.ended_at IS NULL), 0))
    INTO v_classes;
  IF p_decider AND v_phase = 'disponible' THEN
    v_actions := '["affecter_classe"]'::jsonb;
  ELSIF p_decider AND v_phase IN ('en_poste', 'absent') THEN
    v_actions := '["reaffecter_classe"]'::jsonb;
  END IF;
  RETURN private.cand_ligne_json(c) || pg_catalog.jsonb_build_object(
    'phase', v_phase,
    'manque', v_ph -> 'manque',
    'quiAttend', private.lp_qui_attend(c, v_phase),
    'classes', v_classes,
    'prochaineSeance', (SELECT private.cand_instant(pg_catalog.min(s.started_at))
                          FROM public.sessions s
                         WHERE s.teacher_id = c.profile_id AND s.deleted_at IS NULL
                           AND s.started_at > pg_catalog.now()
                           AND s.status IN ('planned', 'preflight')),
    'remplacements30j', pg_catalog.jsonb_build_object(
      'donnes', (SELECT pg_catalog.count(*)::integer FROM public.remplacements_seance r
                  WHERE r.enseignant_remplacant_id = c.profile_id
                    AND r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
                    AND r.cree_le > pg_catalog.now() - interval '30 days'),
      'recus', (SELECT pg_catalog.count(*)::integer FROM public.remplacements_seance r
                 WHERE r.enseignant_titulaire_id = c.profile_id
                   AND r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
                   AND r.cree_le > pg_catalog.now() - interval '30 days')),
    'coordonneesVersement', EXISTS (SELECT 1 FROM public.versement_coordonnees v
                                     WHERE v.profile_id = c.profile_id AND v.active
                                       AND v.valide_le IS NOT NULL),
    'gestes', v_gestes -> 'gestes',
    'gestesGroupables', v_gestes -> 'gestesGroupables',
    'actionsPhase', v_actions);
END;
$function$;
ALTER FUNCTION private.lp_ligne_json(public.candidatures, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.lp_ligne_json(public.candidatures, boolean) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 4. La lecture paginee
-- ============================================================
CREATE FUNCTION public.lister_enseignants(
  p_filtre jsonb DEFAULT '{}'::jsonb,
  p_tri text DEFAULT 'activite',
  p_page integer DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
  v_phase text;
  v_etat text;
  v_issue text;
  v_pays text;
  v_recherche text;
  v_recherche_nom text;
  v_en_pause boolean;
  v_avec_classe boolean;
  v_partis boolean;
  v_sous_filtre jsonb;
  v_offset bigint;
  v_total integer;
  v_lignes jsonb;
  v_phases jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'enseignants reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun enseignant lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre d''enseignants invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['phase', 'etat', 'issue', 'paysResidence', 'recherche', 'genre', 'enPause',
                            'avecClasse', 'partis', 'responsable', 'nouveau', 'pieceEnAttente']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre d''enseignants inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'avecClasse', 'partis', 'nouveau', 'pieceEnAttente')
                THEN 'boolean' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre d''enseignants mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;
  PERFORM private.be_filtre_valider(v_filtre);
  v_phase := v_filtre ->> 'phase';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pays := v_filtre ->> 'paysResidence';
  v_en_pause := (v_filtre ->> 'enPause')::boolean;
  v_avec_classe := (v_filtre ->> 'avecClasse')::boolean;
  v_partis := coalesce((v_filtre ->> 'partis')::boolean, false);
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');
  IF (v_phase IS NOT NULL AND v_phase NOT IN
        ('candidat', 'accueil', 'disponible', 'en_poste', 'absent', 'pause', 'suspendu', 'parti'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR (v_filtre ->> 'genre' IS NOT NULL AND v_filtre ->> 'genre' NOT IN ('male', 'female'))
     OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre d''enseignants invalide' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('activite', 'recente', 'nom') THEN
    RAISE EXCEPTION 'tri d''enseignants invalide : activite, recente ou nom' USING ERRCODE = '22023';
  END IF;
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page d''enseignants invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');
  -- Les filtres que be_predicat sait deja lire.
  SELECT coalesce(pg_catalog.jsonb_object_agg(e.key, e.value), '{}'::jsonb) INTO v_sous_filtre
    FROM pg_catalog.jsonb_each(v_filtre) e
   WHERE e.key IN ('responsable', 'nouveau', 'pieceEnAttente') AND pg_catalog.jsonb_typeof(e.value) <> 'null';

  WITH base AS MATERIALIZED (
    SELECT c AS ligne, private.lp_phase(c) ->> 'phase' AS phase,
           EXISTS (SELECT 1 FROM public.groupes g
                    WHERE g.teacher_id = c.profile_id AND g.ended_at IS NULL) AS a_classe
      FROM public.candidatures c
     WHERE c.type_code = 'enseignant'
       AND (v_super OR c.genre = v_genre)
  ), filtrees AS MATERIALIZED (
    SELECT b.ligne,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN (b.ligne).derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN (b.ligne).recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN coalesce((b.ligne).nom_latin, (b.ligne).nom_complet) END ASC,
             (b.ligne).id ASC) AS rang
      FROM base b
     WHERE (v_phase IS NULL AND (v_partis OR b.phase <> 'parti') OR b.phase = v_phase)
       AND (v_etat IS NULL OR (b.ligne).etat = v_etat)
       AND (v_issue IS NULL OR (b.ligne).issue = v_issue)
       AND (v_pays IS NULL OR (b.ligne).pays_residence = v_pays)
       AND (v_filtre ->> 'genre' IS NULL OR (b.ligne).genre::text = v_filtre ->> 'genre')
       AND (v_en_pause IS NULL OR (b.ligne).en_pause = v_en_pause)
       AND (v_avec_classe IS NULL OR b.a_classe = v_avec_classe)
       AND (v_sous_filtre = '{}'::jsonb OR private.be_predicat(b.ligne, v_sous_filtre, v_lecteur))
       AND (v_recherche IS NULL
            OR (b.ligne).reference = pg_catalog.upper(v_recherche)
            OR EXISTS (SELECT 1 FROM public.candidature_contacts k
                        WHERE k.candidature_id = (b.ligne).id
                          AND k.courriel = pg_catalog.lower(v_recherche))
            OR (v_recherche_nom IS NOT NULL
                AND (pg_catalog.strpos(private.cand_normaliser((b.ligne).nom_complet), v_recherche_nom) > 0
                     OR pg_catalog.strpos(private.cand_normaliser((b.ligne).nom_latin), v_recherche_nom) > 0)))
  )
  SELECT pg_catalog.count(*)::integer,
         coalesce(pg_catalog.jsonb_agg(
                    private.lp_ligne_json(f.ligne, coalesce((f.ligne).genre = v_genre, false)) ORDER BY f.rang)
                    FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50),
                  '[]'::jsonb)
    INTO v_total, v_lignes
  FROM filtrees f;

  -- Les compteurs : toute la portee, sans les autres filtres.
  SELECT pg_catalog.jsonb_build_object(
           'candidat', pg_catalog.count(*) FILTER (WHERE x.phase = 'candidat'),
           'accueil', pg_catalog.count(*) FILTER (WHERE x.phase = 'accueil'),
           'disponible', pg_catalog.count(*) FILTER (WHERE x.phase = 'disponible'),
           'en_poste', pg_catalog.count(*) FILTER (WHERE x.phase = 'en_poste'),
           'absent', pg_catalog.count(*) FILTER (WHERE x.phase = 'absent'),
           'pause', pg_catalog.count(*) FILTER (WHERE x.phase = 'pause'),
           'suspendu', pg_catalog.count(*) FILTER (WHERE x.phase = 'suspendu'),
           'parti', pg_catalog.count(*) FILTER (WHERE x.phase = 'parti'),
           'nouveaux', pg_catalog.count(*) FILTER (WHERE x.nouveau),
           'sansDossier', (SELECT pg_catalog.count(*)::integer FROM public.profiles p
                            WHERE p.role = 'teacher'::public.app_role AND p.deleted_at IS NULL
                              AND NOT EXISTS (SELECT 1 FROM public.candidatures c WHERE c.profile_id = p.id)
                              AND (v_super OR p.gender = v_genre)))
    INTO v_phases
  FROM (SELECT private.lp_phase(c) ->> 'phase' AS phase,
               (c.issue = 'en_cours' AND private.be_nouvelle(c)) AS nouveau
          FROM public.candidatures c
         WHERE c.type_code = 'enseignant' AND (v_super OR c.genre = v_genre)) x;

  PERFORM public.log_sensitive_access('enseignants_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'total', v_total,
      'page', p_page,
      'recherche', v_recherche IS NOT NULL));

  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'total', v_total,
    'page', p_page,
    'taillePage', 50,
    'compteursPhases', v_phases);
END;
$function$;
ALTER FUNCTION public.lister_enseignants(jsonb, text, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lister_enseignants(jsonb, text, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lister_enseignants(jsonb, text, integer) TO authenticated;

-- Empreinte F86 : posee apres la creation, sur la definition installee.
DO $f86$
DECLARE
  f regprocedure := 'public.lister_enseignants(jsonb,text,integer)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.lister_enseignants(jsonb,text,integer); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. '
    || 'LP-1 (SPEC-LISTE-PERSONNES, 16/11/2026) : une ligne par enseignant (dossier de candidature de type enseignant), phase, '
    || 'manque, qui attend quoi, classes, prochaine seance, remplacements 30 jours, gestes permis (ceux du moteur des '
    || 'candidatures, de son cote seulement), compteurs par phase. Lecture seule, portee par genre, audit de chaque liste. '
    || 'Must-pass: supabase/tests/scenarios_lp1_liste_enseignants.sql.');
END;
$f86$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.lister_enseignants(jsonb,text,integer)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'LP-1 : DEFINER ou ACL invalide';
  END IF;
  IF EXISTS (SELECT 1
               FROM pg_catalog.unnest(ARRAY['private.lp_phase(public.candidatures)',
                                            'private.lp_gestes(public.candidatures,boolean)',
                                            'private.lp_qui_attend(public.candidatures,text)',
                                            'private.lp_ligne_json(public.candidatures,boolean)']) AS n(sig)
               CROSS JOIN pg_catalog.unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r(role)
              WHERE pg_catalog.has_function_privilege(r.role, n.sig::regprocedure, 'EXECUTE')) THEN
    RAISE EXCEPTION 'LP-1 : une fonction privee est executable';
  END IF;
END
$postflight$;
