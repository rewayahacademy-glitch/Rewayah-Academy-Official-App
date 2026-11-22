-- FICHE-ELEVE-DIRECTION (directeur, 22/11/2026) : la fiche complete d'un eleve, lue par la direction.
--
-- LIVRE ICI : `public.fiche_eleve_direction(uuid)` rend, en un seul appel et en lecture seule, ce que la
-- direction doit savoir d'un eleve sans ouvrir dix pages : identite, famille (tuteur), reponses de
-- l'admission, classes (enseignant, horaires), presences, progression. Rien n'est calcule ici que le
-- serveur ne sache deja : l'etape et la vitesse viennent de `private.etape_eleve` et
-- `private.vitesse_eleve`, la presence de `public.etat_presence`.
--
-- GARDE : la direction active seulement (comme `lister_demandes_admission`). Sous masquage d'identite
-- (`agent_identite_masquee`), prenoms, noms, courriel et telephone sont nuls : la fiche ne devient pas
-- une porte de derriere.
--
-- Additive : aucune table, aucun DROP, DELETE ni TRUNCATE. Un profil qui n'est pas un eleve (aucune ligne
-- `student_profiles`) rend NULL, jamais une fiche vide.

BEGIN;

CREATE FUNCTION public.fiche_eleve_direction(p_eleve_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_masque boolean := public.agent_identite_masquee();
  v_p public.profiles%ROWTYPE;
  v_sp public.student_profiles%ROWTYPE;
  v_tuteur public.profiles%ROWTYPE;
  v_tuteur_json jsonb := NULL;
  v_admission jsonb := NULL;
  v_cand public.candidatures%ROWTYPE;
  v_app public.candidature_apprenants%ROWTYPE;
  v_classes jsonb;
  v_presences jsonb;
  v_progression jsonb := NULL;
  v_groupe uuid;
  v_etape record;
  v_cacher_dates boolean := false;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'fiche eleve reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_eleve_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_p FROM public.profiles p WHERE p.id = p_eleve_id AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT * INTO v_sp FROM public.student_profiles s
   WHERE s.profile_id = p_eleve_id AND s.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Le tuteur : celui du foyer de l'eleve (le principal d'abord). Un adulte qui apprend pour lui-meme
  -- n'en a pas.
  IF v_p.role = 'student' AND v_p.household_id IS NOT NULL THEN
    SELECT t.* INTO v_tuteur
      FROM public.profiles t
      LEFT JOIN public.households h ON h.id = v_p.household_id
     WHERE t.household_id = v_p.household_id AND t.role = 'guardian' AND t.deleted_at IS NULL
     ORDER BY (t.id = h.primary_guardian_id) DESC, t.created_at, t.id
     LIMIT 1;
    IF FOUND THEN
      v_tuteur_json := pg_catalog.jsonb_build_object(
        'id', v_tuteur.id,
        'matricule', v_tuteur.immutable_id,
        'prenom', CASE WHEN v_masque THEN NULL ELSE v_tuteur.first_name END,
        'nom', CASE WHEN v_masque THEN NULL ELSE v_tuteur.last_name END,
        'courriel', CASE WHEN v_masque THEN NULL
                         ELSE public.courriel_adresse_profil(v_tuteur.id) END,
        'telephone', CASE WHEN v_masque THEN NULL
                          ELSE nullif(pg_catalog.btrim(coalesce(
                                 (SELECT pg_catalog.to_jsonb(u) ->> 'phone'
                                    FROM auth.users u WHERE u.id = v_tuteur.id), '')), '') END,
        'foyer_id', v_p.household_id);
    END IF;
  END IF;

  -- Les reponses de l'admission : la ligne de l'apprenant dans la demande de son titulaire (le lien
  -- `profil_eleve_id`, sinon le prenom dans la demande du foyer), completee par ce que le profil
  -- porte deja (niveau, objectif, langue). La source declaree est celle de la demande.
  SELECT c.* INTO v_cand
    FROM public.candidatures c
   WHERE c.type_code IN ('famille', 'eleve_adulte')
     AND c.profile_id = coalesce(v_tuteur.id, p_eleve_id)
   ORDER BY c.recue_le DESC, c.id
   LIMIT 1;
  SELECT a.* INTO v_app
    FROM public.candidature_apprenants a
    JOIN public.candidatures c ON c.id = a.candidature_id
   WHERE a.profil_eleve_id = p_eleve_id
      OR (a.candidature_id = v_cand.id
          AND ((a.est_titulaire AND v_cand.profile_id = p_eleve_id)
               OR pg_catalog.lower(pg_catalog.btrim(a.prenom))
                  = pg_catalog.lower(pg_catalog.btrim(coalesce(v_p.first_name, '')))))
   ORDER BY (a.profil_eleve_id = p_eleve_id) DESC NULLS LAST, c.recue_le DESC, a.rang
   LIMIT 1;
  v_admission := pg_catalog.jsonb_build_object(
    'age', v_app.age,
    'niveau', coalesce(v_sp.niveau_declare, v_app.niveau_declare),
    'objectif', CASE WHEN v_app.objectif_priere THEN 'priere_invocations'
                     ELSE coalesce(v_sp.objectif, v_app.objectif) END,
    'langue', coalesce(v_app.langue_demandee, v_app.langue_code, v_sp.langue_cours),
    'langue_secours', v_app.langue_secours,
    'langue_autre', v_app.langue_autre,
    'moments', coalesce(v_app.moments, '{}'::text[]),
    'riwaya', v_app.riwaya,
    'riwaya_autre', v_app.riwaya_autre,
    'memorise', v_app.memorise_quantite,
    'juz', pg_catalog.to_jsonb(coalesce(v_app.juz, '{}')),
    'sourates', pg_catalog.to_jsonb(coalesce(v_app.sourates, '{}')),
    'source', v_cand.source_declaree);

  -- Les classes actives : enseignant attitre et horaires (a l'heure de la classe ; l'ecran lit le
  -- fuseau et affiche l'heure locale puis celle de La Mecque).
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', g.id,
           'libelle', g.libelle,
           'nom_cours', g.nom_cours,
           'fuseau', g.timezone_iana,
           'depuis', m.joined_at,
           'enseignant', CASE WHEN g.teacher_id IS NULL THEN NULL
                              ELSE pg_catalog.jsonb_build_object(
                                'id', g.teacher_id,
                                'prenom', CASE WHEN v_masque THEN NULL ELSE tp.first_name END,
                                'nom', CASE WHEN v_masque THEN NULL ELSE tp.last_name END) END,
           'creneaux', coalesce(
             (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                       'jour', k.weekday, 'heure', k.hour_local, 'duree', k.duree_minutes)
                       ORDER BY k.weekday, k.hour_local)
                FROM public.groupe_creneaux k WHERE k.groupe_id = g.id),
             pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
               'jour', g.weekday, 'heure', g.hour_local, 'duree', NULL)))
         ) ORDER BY m.joined_at, g.id), '[]'::jsonb)
    INTO v_classes
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
    LEFT JOIN public.profiles tp ON tp.id = g.teacher_id
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL;

  -- Les presences : les seances tenues ou manquees, jamais celles qui n'ont pas encore eu lieu.
  WITH seances AS (
    SELECT s.id, s.started_at, s.status::text AS statut_seance,
           public.etat_presence(s.id, p_eleve_id)::text AS etat
      FROM public.session_participants sp
      JOIN public.sessions s ON s.id = sp.session_id
     WHERE sp.profile_id = p_eleve_id AND sp.deleted_at IS NULL AND s.deleted_at IS NULL
       AND s.status IN ('ended', 'teacher_absent', 'student_absent', 'tech_failure')
  ), comptes AS (
    SELECT pg_catalog.count(*)::int AS total,
           pg_catalog.count(*) FILTER (WHERE etat IN ('presente', 'reconnectee', 'sortie', 'finalisee',
                                                      'corrigee_manuel', 'deconnectee',
                                                      'en_reconnexion'))::int AS presents,
           pg_catalog.count(*) FILTER (WHERE etat = 'en_retard')::int AS retards,
           pg_catalog.count(*) FILTER (WHERE etat = 'absente')::int AS absents,
           pg_catalog.count(*) FILTER (WHERE etat = 'excusee')::int AS excuses
      FROM seances
  )
  SELECT pg_catalog.jsonb_build_object(
           'total', c.total, 'presents', c.presents, 'retards', c.retards,
           'absents', c.absents, 'excuses', c.excuses,
           'dernieres', coalesce((
             SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                      'id', d.id, 'debut', d.started_at, 'statut', d.statut_seance, 'etat', d.etat)
                      ORDER BY d.started_at DESC)
               FROM (SELECT * FROM seances ORDER BY started_at DESC LIMIT 8) d), '[]'::jsonb))
    INTO v_presences
    FROM comptes c;

  -- La progression : la meme lecture que celle du suivi pedagogique, sans la garde de la famille.
  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL
   ORDER BY m.joined_at DESC, m.groupe_id
   LIMIT 1;
  IF v_groupe IS NOT NULL THEN
    v_cacher_dates := private.dates_retenues(p_eleve_id, v_groupe);
    SELECT e.etape_nom, e.etape_ordre, e.cycle, e.duree_prevue_semaines, e.date_limite, e.depuis
      INTO v_etape
      FROM private.etape_eleve(p_eleve_id, v_groupe) e
     LIMIT 1;
    IF FOUND AND v_etape.etape_nom IS NOT NULL THEN
      v_progression := pg_catalog.jsonb_build_object(
        'etape', v_etape.etape_nom,
        'ordre', v_etape.etape_ordre,
        'cycle', v_etape.cycle,
        'depuis', CASE WHEN v_cacher_dates THEN NULL ELSE v_etape.depuis END,
        'date_limite', CASE WHEN v_cacher_dates THEN NULL ELSE v_etape.date_limite END,
        'rythme', CASE WHEN v_cacher_dates THEN NULL
                       ELSE private.vitesse_eleve(v_etape.depuis, v_etape.duree_prevue_semaines,
                                                  v_etape.date_limite, pg_catalog.now()) END);
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'identite', pg_catalog.jsonb_build_object(
      'id', v_p.id,
      'matricule', v_p.immutable_id,
      'prenom', CASE WHEN v_masque THEN NULL ELSE v_p.first_name END,
      'nom', CASE WHEN v_masque THEN NULL ELSE v_p.last_name END,
      'genre', v_p.gender::text,
      'tranche', CASE v_sp.student_type::text WHEN 'minor' THEN 'enfant'
                                              WHEN 'autonomous' THEN 'adulte' END,
      'langue_cours', v_sp.langue_cours,
      'langue_communication', v_p.langue_communication,
      'etat_compte', v_p.account_status::text,
      'inscrit_le', v_p.created_at,
      'acces_jusqu_au', v_p.access_until,
      'interface', v_sp.interface_mode::text,
      'foyer_id', v_p.household_id,
      'est_titulaire', v_p.role = 'guardian'),
    'tuteur', v_tuteur_json,
    'admission', v_admission,
    'classes', v_classes,
    'presences', v_presences,
    'progression', v_progression);
END;
$function$;

ALTER FUNCTION public.fiche_eleve_direction(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.fiche_eleve_direction(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.fiche_eleve_direction(uuid) TO authenticated;
COMMENT ON FUNCTION public.fiche_eleve_direction(uuid) IS
  'F86 candidate allowlist: signature=public.fiche_eleve_direction(uuid); guard_type=ADMIN_ONLY; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. FICHE-ELEVE-DIRECTION : la fiche complete d''un eleve pour la direction, lecture seule.';

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.fiche_eleve_direction(uuid)'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.provolatile = 's'
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'FICHE-ELEVE-DIRECTION : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
END;
$postflight$;

COMMIT;
