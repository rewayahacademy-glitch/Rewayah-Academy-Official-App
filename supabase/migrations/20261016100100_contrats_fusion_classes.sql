-- CONTRATS-MANQUANTS (2/6) : fusion de classes paralleles et transfert d'un
-- eleve, par la direction (R5, R8, R9, R10).
--
-- Contrat : lib/core/admin/port_fusion_classes.dart (PortFusionClasses) :
-- classes_cibles_fusion, apercu_fusion, fusionner_classes, membres_transferables,
-- transferer_eleve, historique_classe.
--
-- * Une cible est une classe active de la meme famille (cle de
--   app_private.classes_numerotees : instant UTC, public, genre, langue,
--   niveau), autre que la source, qui a la place demandee.
-- * Fusion atomique : verrou par cle de famille (R8) puis verrou des deux
--   classes ; demandes rattachees a la cible, membres deplaces, source
--   cloturee, seances futures de la source annulees (l'enseignant redevient
--   libre), mouvement trace, chaque famille notifiee, audit chaine.
-- * Transfert : meme famille, une place, et R5 (aucune seance a venir de
--   l'eleve ne chevauche un creneau de la cible) ; refus 'chevauchement',
--   'classe_pleine' ou 'autre' avec un code de motif.
-- * Idempotence : (acteur, cle_envoi) unique ; la meme cle rend la meme
--   reponse. Une source deja fusionnee rend 'deja_faite', un eleve deja
--   transfere vers cette cible rend 'deja_fait'.
-- * Les noms de classe se rendent en (libelle, numero) : le client compose le
--   nom sans ambiguite (nomClasseDistinct) dans la langue de l'interface. Les
--   motifs de refus sont des codes, mis en mots par l'adaptateur.
-- * Lectures INVOKER (RLS) ; les deux mutations sont DEFINER : elles ecrivent
--   dans groupe_membres, groupes, sessions et notifications, qu'aucun client
--   n'ecrit directement.
BEGIN;

-- ------------------------------------------------------------------
-- L'historique et l'idempotence des mouvements (append-only).
-- ------------------------------------------------------------------
CREATE TABLE public.classe_mouvements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nature text NOT NULL CHECK (nature IN ('fusion', 'transfert')),
  source_id uuid NOT NULL REFERENCES public.groupes(id),
  cible_id uuid NOT NULL REFERENCES public.groupes(id),
  eleve_id uuid REFERENCES public.profiles(id),
  nombre integer NOT NULL CHECK (nombre >= 0),
  acteur_id uuid NOT NULL REFERENCES public.profiles(id),
  cle_envoi text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(cle_envoi)) BETWEEN 1 AND 200),
  resultat jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resultat) = 'object'),
  -- clock_timestamp : deux mouvements d'une meme transaction restent ordonnes.
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT classe_mouvements_cle_unique UNIQUE (acteur_id, cle_envoi),
  CONSTRAINT classe_mouvements_distinctes CHECK (source_id <> cible_id),
  CONSTRAINT classe_mouvements_coherence CHECK (
    (nature = 'fusion' AND eleve_id IS NULL)
    OR (nature = 'transfert' AND eleve_id IS NOT NULL AND nombre = 1))
);
CREATE INDEX classe_mouvements_source_idx ON public.classe_mouvements (source_id, cree_le DESC);
CREATE INDEX classe_mouvements_cible_idx ON public.classe_mouvements (cible_id, cree_le DESC);
CREATE UNIQUE INDEX classe_mouvements_fusion_unique
  ON public.classe_mouvements (source_id) WHERE nature = 'fusion';

ALTER TABLE public.classe_mouvements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.classe_mouvements FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.classe_mouvements TO authenticated;
CREATE POLICY classe_mouvements_direction_lecture ON public.classe_mouvements
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

CREATE FUNCTION public.classe_mouvements_refuser_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'historique des mouvements de classe en ajout seul'
    USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION public.classe_mouvements_refuser_mutation()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER classe_mouvements_ajout_seul
  BEFORE UPDATE OR DELETE ON public.classe_mouvements
  FOR EACH ROW EXECUTE FUNCTION public.classe_mouvements_refuser_mutation();

-- La notification de famille d'un changement de classe (R9, R10).
ALTER TABLE public.notifications DROP CONSTRAINT notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check
  CHECK (evenement = ANY (ARRAY['demande_recue', 'classe_validee', 'enseignant_affecte',
    'demande_close', 'remplacement_propose', 'remplacement_pris', 'demande_presentation',
    'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee']));

-- ------------------------------------------------------------------
-- Lectures (DEFINER, garde direction).
-- ------------------------------------------------------------------

-- Les classes qui peuvent accueillir p_eleves eleves de p_classe_id (tous ses
-- membres actifs quand p_eleves est nul). Tableau de
-- {classe_id, libelle, numero, enseignant_prenom, membres, capacite}.
CREATE FUNCTION public.classes_cibles_fusion(p_classe_id uuid, p_eleves integer DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cle text;
  v_besoin integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'fusion reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_classe_id IS NULL OR (p_eleves IS NOT NULL AND p_eleves < 1) THEN
    RAISE EXCEPTION 'classe ou nombre d''eleves invalide' USING ERRCODE = '22023';
  END IF;

  SELECT n.cle INTO v_cle FROM app_private.classes_numerotees() n WHERE n.groupe_id = p_classe_id;
  IF v_cle IS NULL THEN
    RAISE EXCEPTION 'classe introuvable' USING ERRCODE = 'P0002';
  END IF;
  v_besoin := coalesce(p_eleves, (SELECT count(*)::integer FROM public.groupe_membres m
                                   WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL));

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'classe_id', c.id, 'libelle', c.libelle, 'numero', c.numero,
             'enseignant_prenom', c.first_name, 'enseignant_nom', c.last_name,
             'membres', c.membres, 'capacite', c.seuil_max)
           ORDER BY c.libelle, c.numero, c.id)
    FROM (
      SELECT g.id, g.libelle, n.numero, p.first_name, p.last_name, g.seuil_max,
             (SELECT count(*)::integer FROM public.groupe_membres m
               WHERE m.groupe_id = g.id AND m.left_at IS NULL) AS membres
      FROM public.groupes g
      JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
      LEFT JOIN public.profiles p ON p.id = g.teacher_id
      WHERE n.cle = v_cle AND g.id <> p_classe_id AND g.ended_at IS NULL
    ) c
    WHERE c.seuil_max - c.membres >= v_besoin), '[]'::jsonb);
END;
$function$;

-- Ce que la fusion de p_source_id dans p_cible_id fera :
-- {source_libelle, source_numero, cible{...}, membres_deplaces,
--  enseignant_libere_prenom, enseignant_libere_nom, familles_notifiees}.
CREATE FUNCTION public.apercu_fusion(p_source_id uuid, p_cible_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_source record;
  v_cible record;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'fusion reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_source_id IS NULL OR p_cible_id IS NULL OR p_source_id = p_cible_id THEN
    RAISE EXCEPTION 'classes invalides' USING ERRCODE = '22023';
  END IF;

  SELECT g.id, g.libelle, n.numero, n.cle, g.ended_at, g.seuil_max, p.first_name, p.last_name,
         (SELECT count(*)::integer FROM public.groupe_membres m
           WHERE m.groupe_id = g.id AND m.left_at IS NULL) AS membres
    INTO v_source
  FROM public.groupes g
  JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
  LEFT JOIN public.profiles p ON p.id = g.teacher_id
  WHERE g.id = p_source_id;
  SELECT g.id, g.libelle, n.numero, n.cle, g.ended_at, g.seuil_max, p.first_name, p.last_name,
         (SELECT count(*)::integer FROM public.groupe_membres m
           WHERE m.groupe_id = g.id AND m.left_at IS NULL) AS membres
    INTO v_cible
  FROM public.groupes g
  JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
  LEFT JOIN public.profiles p ON p.id = g.teacher_id
  WHERE g.id = p_cible_id;
  IF v_source.id IS NULL OR v_cible.id IS NULL THEN
    RAISE EXCEPTION 'classe introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_source.ended_at IS NOT NULL OR v_cible.ended_at IS NOT NULL
     OR v_source.cle <> v_cible.cle THEN
    RAISE EXCEPTION 'classes non fusionnables' USING ERRCODE = '22023';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'source_libelle', v_source.libelle, 'source_numero', v_source.numero,
    'cible', pg_catalog.jsonb_build_object(
      'classe_id', v_cible.id, 'libelle', v_cible.libelle, 'numero', v_cible.numero,
      'enseignant_prenom', v_cible.first_name, 'enseignant_nom', v_cible.last_name,
      'membres', v_cible.membres, 'capacite', v_cible.seuil_max),
    'membres_deplaces', v_source.membres,
    'enseignant_libere_prenom', v_source.first_name,
    'enseignant_libere_nom', v_source.last_name,
    'familles_notifiees', (
      SELECT count(DISTINCT coalesce(p.household_id, p.id))::integer
      FROM public.groupe_membres m JOIN public.profiles p ON p.id = m.student_id
      WHERE m.groupe_id = p_source_id AND m.left_at IS NULL));
END;
$function$;

-- Les eleves de la classe que la direction peut transferer :
-- [{eleve_id, prenom}], par prenom.
CREATE FUNCTION public.membres_transferables(p_classe_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'transfert reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_classe_id IS NULL THEN
    RAISE EXCEPTION 'classe invalide' USING ERRCODE = '22023';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('eleve_id', p.id, 'prenom', p.first_name)
                                ORDER BY p.first_name, p.id)
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
    JOIN public.profiles p ON p.id = m.student_id AND p.deleted_at IS NULL
    WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL), '[]'::jsonb);
END;
$function$;

-- L'historique d'une classe, le plus recent d'abord :
-- [{id, type, quand, autre_libelle, autre_numero, nombre, prenom}], type parmi
-- fusion_sortante, fusion_entrante, transfert_sortant, transfert_entrant.
CREATE FUNCTION public.historique_classe(p_classe_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'historique reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_classe_id IS NULL THEN
    RAISE EXCEPTION 'classe invalide' USING ERRCODE = '22023';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', h.id, 'type', h.type, 'quand', h.cree_le,
             'autre_libelle', h.libelle, 'autre_numero', h.numero,
             'nombre', CASE WHEN h.nature = 'fusion' THEN h.nombre END,
             'prenom', h.prenom)
           ORDER BY h.cree_le DESC, h.id DESC)
    FROM (
      SELECT mv.id, mv.nature, mv.nombre, mv.cree_le, autre.libelle, n.numero, eleve.first_name AS prenom,
             CASE WHEN mv.nature = 'fusion' AND mv.source_id = p_classe_id THEN 'fusion_sortante'
                  WHEN mv.nature = 'fusion' THEN 'fusion_entrante'
                  WHEN mv.source_id = p_classe_id THEN 'transfert_sortant'
                  ELSE 'transfert_entrant' END AS type
      FROM public.classe_mouvements mv
      JOIN public.groupes autre
        ON autre.id = CASE WHEN mv.source_id = p_classe_id THEN mv.cible_id ELSE mv.source_id END
      LEFT JOIN app_private.classes_numerotees() n ON n.groupe_id = autre.id
      LEFT JOIN public.profiles eleve ON eleve.id = mv.eleve_id
      WHERE mv.source_id = p_classe_id OR mv.cible_id = p_classe_id
    ) h), '[]'::jsonb);
END;
$function$;

-- ------------------------------------------------------------------
-- Le deplacement d'un membre, commun a la fusion et au transfert. INVOKER,
-- jamais expose (aucun EXECUTE client) : appele seulement depuis les deux
-- mutations DEFINER, apres leur garde, avec les droits de leur proprietaire.
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.deplacer_membre_classe(
  p_eleve_id uuid, p_source_id uuid, p_cible_id uuid, p_motif text
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_etat_cible text;
BEGIN
  SELECT CASE WHEN g.teacher_id IS NOT NULL AND g.etat = 'active'
              THEN 'enseignant_affecte' ELSE 'classe_validee' END
    INTO v_etat_cible
  FROM public.groupes g WHERE g.id = p_cible_id;

  -- La demande suit l'eleve AVANT le depart : le declencheur de retrait ne
  -- la cloture donc pas (elle ne pointe plus vers la source).
  UPDATE public.demandes_horaires_famille d
     SET groupe_id = p_cible_id, etat = v_etat_cible, updated_at = pg_catalog.now()
   WHERE d.eleve_id = p_eleve_id AND d.groupe_id = p_source_id
     AND d.etat IN ('classe_validee', 'enseignant_affecte');

  UPDATE public.groupe_membres m
     SET left_at = pg_catalog.now(), left_by = auth.uid(), left_reason = p_motif
   WHERE m.groupe_id = p_source_id AND m.student_id = p_eleve_id AND m.left_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'eleve absent de la classe source';
  END IF;

  -- Les seances a venir de la source ne le comptent plus.
  UPDATE public.session_participants sp
     SET deleted_at = pg_catalog.now()
    FROM public.sessions s
   WHERE sp.session_id = s.id AND sp.profile_id = p_eleve_id AND sp.deleted_at IS NULL
     AND s.groupe_id = p_source_id AND s.deleted_at IS NULL
     AND s.status = 'planned' AND s.started_at > pg_catalog.now();

  INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (p_cible_id, p_eleve_id);

  -- La famille est prevenue (destinataires : les tuteurs du foyer, a defaut
  -- l'eleve lui-meme quand il est autonome).
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT dest.id, eleve.household_id, 'classe_changee',
         pg_catalog.jsonb_build_object('motif', CASE WHEN p_motif LIKE 'fusion%' THEN 'fusion' ELSE 'transfert' END),
         '/tuteur/demandes'
  FROM public.profiles eleve
  CROSS JOIN LATERAL (
    SELECT t.id FROM public.profiles t
     WHERE eleve.household_id IS NOT NULL AND t.household_id = eleve.household_id
       AND t.role = 'guardian' AND t.deleted_at IS NULL
    UNION
    SELECT eleve.id
     WHERE NOT EXISTS (
       SELECT 1 FROM public.profiles t
        WHERE eleve.household_id IS NOT NULL AND t.household_id = eleve.household_id
          AND t.role = 'guardian' AND t.deleted_at IS NULL)
  ) dest
  WHERE eleve.id = p_eleve_id;
END;
$function$;
REVOKE ALL ON FUNCTION app_private.deplacer_membre_classe(uuid, uuid, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ------------------------------------------------------------------
-- Fusion (DEFINER).
-- Rend {statut: 'faite', cible_libelle, cible_numero, eleves_deplaces}
--    | {statut: 'deja_faite'}
--    | {statut: 'refusee', motif: 'classe_introuvable' | 'cible_cloturee'
--                               | 'cible_incompatible' | 'cible_pleine'
--                               | 'source_cloturee'}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.fusionner_classes(p_source_id uuid, p_cible_id uuid, p_cle_envoi text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_acteur uuid := auth.uid();
  v_deja jsonb;
  v_source record;
  v_cible record;
  v_cle_source text;
  v_cle_cible text;
  v_numero_cible integer;
  v_membres uuid[];
  v_places integer;
  v_eleve uuid;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'fusion reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_source_id IS NULL OR p_cible_id IS NULL OR p_source_id = p_cible_id
     OR coalesce(pg_catalog.length(pg_catalog.btrim(p_cle_envoi)), 0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'fusion invalide' USING ERRCODE = '22023';
  END IF;

  SELECT mv.resultat INTO v_deja FROM public.classe_mouvements mv
   WHERE mv.acteur_id = v_acteur AND mv.cle_envoi = p_cle_envoi;
  IF v_deja IS NOT NULL THEN
    RETURN v_deja;
  END IF;

  SELECT n.cle INTO v_cle_source FROM app_private.classes_numerotees() n WHERE n.groupe_id = p_source_id;
  IF v_cle_source IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'classe_introuvable');
  END IF;
  -- R8 : un verrou par cle de famille, puis les deux classes dans l'ordre.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe-famille:' || v_cle_source, 0));
  PERFORM 1 FROM public.groupes g WHERE g.id IN (p_source_id, p_cible_id) ORDER BY g.id FOR UPDATE;

  SELECT g.* INTO v_source FROM public.groupes g WHERE g.id = p_source_id;
  SELECT g.* INTO v_cible FROM public.groupes g WHERE g.id = p_cible_id;
  IF v_cible.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'classe_introuvable');
  END IF;
  IF v_source.ended_at IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.classe_mouvements mv
                WHERE mv.nature = 'fusion' AND mv.source_id = p_source_id) THEN
      RETURN pg_catalog.jsonb_build_object('statut', 'deja_faite');
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'source_cloturee');
  END IF;
  IF v_cible.ended_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'cible_cloturee');
  END IF;
  SELECT n.cle, n.numero INTO v_cle_cible, v_numero_cible
    FROM app_private.classes_numerotees() n WHERE n.groupe_id = p_cible_id;
  IF v_cle_cible IS DISTINCT FROM v_cle_source THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'cible_incompatible');
  END IF;

  SELECT coalesce(pg_catalog.array_agg(m.student_id ORDER BY m.joined_at, m.student_id), '{}')
    INTO v_membres
  FROM public.groupe_membres m WHERE m.groupe_id = p_source_id AND m.left_at IS NULL;
  SELECT v_cible.seuil_max - count(*)::integer INTO v_places
  FROM public.groupe_membres m WHERE m.groupe_id = p_cible_id AND m.left_at IS NULL;
  IF v_places < cardinality(v_membres) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refusee', 'motif', 'cible_pleine');
  END IF;

  FOREACH v_eleve IN ARRAY v_membres LOOP
    PERFORM app_private.deplacer_membre_classe(v_eleve, p_source_id, p_cible_id,
      'fusion vers ' || p_cible_id::text);
  END LOOP;

  UPDATE public.groupes
     SET ended_at = pg_catalog.now(), ended_by = v_acteur, end_reason = 'fusion'
   WHERE id = p_source_id;
  -- R9 : l'enseignant de la source redevient libre a cet horaire.
  UPDATE public.sessions s
     SET status = 'canceled', updated_at = pg_catalog.now()
   WHERE s.groupe_id = p_source_id AND s.deleted_at IS NULL
     AND s.status = 'planned' AND s.started_at > pg_catalog.now();

  v_resultat := pg_catalog.jsonb_build_object(
    'statut', 'faite', 'cible_libelle', v_cible.libelle, 'cible_numero', v_numero_cible,
    'eleves_deplaces', cardinality(v_membres));
  INSERT INTO public.classe_mouvements (nature, source_id, cible_id, nombre, acteur_id, cle_envoi, resultat)
  VALUES ('fusion', p_source_id, p_cible_id, cardinality(v_membres), v_acteur, p_cle_envoi, v_resultat);
  PERFORM public.log_sensitive_access('classes_fusionnees', 'groupes', p_source_id::text,
    pg_catalog.jsonb_build_object('cible_id', p_cible_id, 'eleves', cardinality(v_membres)));
  RETURN v_resultat;
END;
$function$;

-- ------------------------------------------------------------------
-- Transfert (DEFINER).
-- Rend {statut: 'fait', prenom, cible_libelle, cible_numero}
--    | {statut: 'deja_fait'}
--    | {statut: 'refuse', raison: 'chevauchement' | 'classe_pleine' | 'autre',
--       motif: nul | 'classe_introuvable' | 'eleve_absent' | 'cible_cloturee'
--                  | 'cible_incompatible'}.
-- ------------------------------------------------------------------
CREATE FUNCTION public.transferer_eleve(
  p_eleve_id uuid, p_source_id uuid, p_cible_id uuid, p_cle_envoi text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_acteur uuid := auth.uid();
  v_deja jsonb;
  v_cible record;
  v_cle_source text;
  v_cle_cible text;
  v_numero_cible integer;
  v_prenom text;
  v_duree integer;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'transfert reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_eleve_id IS NULL OR p_source_id IS NULL OR p_cible_id IS NULL OR p_source_id = p_cible_id
     OR coalesce(pg_catalog.length(pg_catalog.btrim(p_cle_envoi)), 0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'transfert invalide' USING ERRCODE = '22023';
  END IF;

  SELECT mv.resultat INTO v_deja FROM public.classe_mouvements mv
   WHERE mv.acteur_id = v_acteur AND mv.cle_envoi = p_cle_envoi;
  IF v_deja IS NOT NULL THEN
    RETURN v_deja;
  END IF;

  SELECT n.cle INTO v_cle_source FROM app_private.classes_numerotees() n WHERE n.groupe_id = p_source_id;
  SELECT n.cle, n.numero INTO v_cle_cible, v_numero_cible
    FROM app_private.classes_numerotees() n WHERE n.groupe_id = p_cible_id;
  IF v_cle_source IS NULL OR v_cle_cible IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'autre', 'motif', 'classe_introuvable');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe-famille:' || v_cle_source, 0));
  PERFORM 1 FROM public.groupes g WHERE g.id IN (p_source_id, p_cible_id) ORDER BY g.id FOR UPDATE;
  SELECT g.* INTO v_cible FROM public.groupes g WHERE g.id = p_cible_id;

  IF NOT EXISTS (SELECT 1 FROM public.groupe_membres m
                  WHERE m.groupe_id = p_source_id AND m.student_id = p_eleve_id AND m.left_at IS NULL) THEN
    IF EXISTS (SELECT 1 FROM public.classe_mouvements mv
                WHERE mv.nature = 'transfert' AND mv.eleve_id = p_eleve_id
                  AND mv.source_id = p_source_id AND mv.cible_id = p_cible_id) THEN
      RETURN pg_catalog.jsonb_build_object('statut', 'deja_fait');
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'autre', 'motif', 'eleve_absent');
  END IF;
  IF v_cible.ended_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'autre', 'motif', 'cible_cloturee');
  END IF;
  IF v_cle_cible <> v_cle_source THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'autre', 'motif', 'cible_incompatible');
  END IF;
  IF (SELECT count(*) FROM public.groupe_membres m
       WHERE m.groupe_id = p_cible_id AND m.left_at IS NULL) >= v_cible.seuil_max THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'classe_pleine', 'motif', NULL);
  END IF;

  -- R5 : aucune seance a venir de l'eleve, hors source et cible, ne chevauche
  -- un creneau de la cible.
  v_duree := public.app_config_int('seance.duree_minutes_' || v_cible.type_public, 60);
  IF EXISTS (
    SELECT 1
    FROM public.session_participants sp
    JOIN public.sessions s ON s.id = sp.session_id
    CROSS JOIN LATERAL (
      SELECT v_cible.weekday::integer AS jour, v_cible.hour_local::integer AS heure
      UNION
      SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_cible_id
    ) slot
    WHERE sp.profile_id = p_eleve_id AND sp.deleted_at IS NULL
      AND s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
      AND s.ended_at > pg_catalog.now()
      AND s.groupe_id IS DISTINCT FROM p_source_id AND s.groupe_id IS DISTINCT FROM p_cible_id
      AND app_private.creneau_recurrent_chevauche_session(
            slot.jour, slot.heure, v_cible.timezone_iana, v_duree, s.started_at, s.ended_at)
  ) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'refuse', 'raison', 'chevauchement', 'motif', NULL);
  END IF;

  PERFORM app_private.deplacer_membre_classe(p_eleve_id, p_source_id, p_cible_id,
    'transfert vers ' || p_cible_id::text);

  SELECT p.first_name INTO v_prenom FROM public.profiles p WHERE p.id = p_eleve_id;
  v_resultat := pg_catalog.jsonb_build_object(
    'statut', 'fait', 'prenom', v_prenom, 'cible_libelle', v_cible.libelle,
    'cible_numero', v_numero_cible);
  INSERT INTO public.classe_mouvements (nature, source_id, cible_id, eleve_id, nombre, acteur_id, cle_envoi, resultat)
  VALUES ('transfert', p_source_id, p_cible_id, p_eleve_id, 1, v_acteur, p_cle_envoi, v_resultat);
  PERFORM public.log_sensitive_access('eleve_transfere', 'groupe_membres', p_source_id::text,
    pg_catalog.jsonb_build_object('cible_id', p_cible_id, 'student_id', p_eleve_id));
  RETURN v_resultat;
END;
$function$;

REVOKE ALL ON FUNCTION public.classes_cibles_fusion(uuid, integer) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.apercu_fusion(uuid, uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.membres_transferables(uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.historique_classe(uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.fusionner_classes(uuid, uuid, text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.transferer_eleve(uuid, uuid, uuid, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.classes_cibles_fusion(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apercu_fusion(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.membres_transferables(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.historique_classe(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fusionner_classes(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transferer_eleve(uuid, uuid, uuid, text) TO authenticated;

-- @@F86_DEBUT_FUSION@@
COMMENT ON FUNCTION public.classes_cibles_fusion(uuid, integer) IS
  'F86: signature=public.classes_cibles_fusion(uuid,integer); md5_functiondef=a04e0c1073b65d7e24b1a39f60bd7a17; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (cibles).';
COMMENT ON FUNCTION public.apercu_fusion(uuid, uuid) IS
  'F86: signature=public.apercu_fusion(uuid,uuid); md5_functiondef=def84606052fd87cee24e136164c0d87; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (apercu).';
COMMENT ON FUNCTION public.membres_transferables(uuid) IS
  'F86: signature=public.membres_transferables(uuid); md5_functiondef=5bf1db251d109d51a9cc9b447afee450; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (membres).';
COMMENT ON FUNCTION public.historique_classe(uuid) IS
  'F86: signature=public.historique_classe(uuid); md5_functiondef=b0d39d69fafa3ad772e82c8701945069; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (historique).';
COMMENT ON FUNCTION public.fusionner_classes(uuid, uuid, text) IS
  'F86: signature=public.fusionner_classes(uuid,uuid,text); md5_functiondef=b4cd915ef99a2515295d843fabc773ab; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (R9).';
COMMENT ON FUNCTION public.transferer_eleve(uuid, uuid, uuid, text) IS
  'F86: signature=public.transferer_eleve(uuid,uuid,uuid,text); md5_functiondef=82bef6bdee8503a22c392204f50787e3; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active (R5, R10).';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.fusionner_classes(uuid,uuid,text)'::regprocedure, 'b4cd915ef99a2515295d843fabc773ab'),
      ('public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure, '82bef6bdee8503a22c392204f50787e3'),
      ('public.classes_cibles_fusion(uuid,integer)'::regprocedure, 'a04e0c1073b65d7e24b1a39f60bd7a17'),
      ('public.apercu_fusion(uuid,uuid)'::regprocedure, 'def84606052fd87cee24e136164c0d87'),
      ('public.membres_transferables(uuid)'::regprocedure, '5bf1db251d109d51a9cc9b447afee450'),
      ('public.historique_classe(uuid)'::regprocedure, 'b0d39d69fafa3ad772e82c8701945069')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM (VALUES
      ('app_private.deplacer_membre_classe(uuid,uuid,uuid,text)'::regprocedure)
    ) AS e(oid)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CONTRATS fusion : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_FUSION@@

COMMIT;
