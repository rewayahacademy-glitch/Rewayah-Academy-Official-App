-- A3 (31/10/2026) : remplacer un titulaire qui n'est pas entre dans la salle.
--
-- Decision du directeur du 31/10, relayee par le pilote (amendement de R12,
-- DECISION-CLASSES-SIMULTANEES-2026-10-10.md) : pour une seance commencee, on
-- n'annule pas. Toutes les minutes comptent depuis le debut de la seance et
-- sont des reglages (app_config), jamais ecrites dans une fonction :
--   remplacement.avertissement_minutes (3) : le titulaire est prevenu qu'il
--     perd l'acces s'il n'entre pas ; pre-alerte aux enseignants compatibles et
--     libres, qui peuvent se declarer prets (le premier pret est retenu) ;
--   remplacement.perte_acces_minutes (8) : absence automatique, le titulaire
--     perd l'acces a la seance de ce jour ; l'enseignant pret devient
--     remplacant, sinon l'offre reste ouverte jusqu'a la fin prevue ; familles,
--     eleves et direction prevenus (titulaire en retard, restez dans la salle) ;
--   remplacement.debut_remplacant_minutes (11) : l'objectif, le remplacant en
--     seance ; verifie seulement comme borne (avertissement < perte < objectif).
-- Ces valeurs attendent la confirmation ecrite du directeur.
--
-- Existant reutilise : remplacements_seance (append-only) et ses
-- declencheurs (enseignants : remplacement_propose / remplacement_pris ;
-- familles : private.notifier_classe_remplacements, etendu ici a la seance
-- commencee) ; le courriel suit toute notification (courriel_depuis_
-- notification) ; les arrivees 'joined' de session_events ; c29 et
-- autoriser_jeton_video (etendu d'une regle : le titulaire ecarte) ;
-- private.remplacant_libre_a_l_heure (20261102400000) ; la cloture
-- automatique existante (ses_cloture_auto) en fin de seance sans remplacant.
--
-- Pourquoi une table a part pour la preparation (pre-alerte, pret,
-- remplacement inutile) plutot que de nouveaux types dans remplacements_seance :
-- (1) toutes les lectures existantes (c29, offres, prise, designation, paie)
-- prennent le DERNIER evenement de remplacements_seance comme etat de la
-- seance ; une pre-alerte ou un « pret » y changerait l'enseignant effectif ou
-- fermerait l'offre ; (2) elargir sa contrainte d'evenements exigerait de
-- supprimer puis recreer la contrainte. La preparation est append-only comme
-- elle, sans aucun acces client.
--
-- Acteur de l'absence automatique : acteur_id est NOT NULL et reference
-- profiles. Choix : acteur = titulaire, colonne `origine` = 'auto'. Aucun
-- profil « systeme » n'existe (un compte de plus a proteger) ; nommer la
-- direction serait faux ; toutes les lectures existantes attendent deja
-- acteur = titulaire pour une absence ; `origine` dit que personne n'a clique.
-- La prise automatique par l'enseignant pret a pour acteur cet enseignant (il
-- s'est declare pret), origine 'auto'. Cles d'idempotence derivees de la
-- seance : un second passage ne pose rien de plus.
--
-- ATTENTION, mot DROP present : elargir les contraintes CHECK de
-- public.notifications (evenements et destinations) se fait comme en
-- 20261027120000, par DROP CONSTRAINT IF EXISTS puis ADD CONSTRAINT dans la
-- meme transaction. Aucune donnee n'est supprimee. Sur STAGING, le serveur
-- demandera une seconde confirmation : coller le fichier dans l'editeur SQL
-- (CLAUDE.md, migrations sur staging).

INSERT INTO public.app_config (key, value) VALUES
  ('remplacement.avertissement_minutes', '3'::jsonb),
  ('remplacement.perte_acces_minutes', '8'::jsonb),
  ('remplacement.debut_remplacant_minutes', '11'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 1. Origine des evenements de remplacement.
-- ---------------------------------------------------------------------------
ALTER TABLE public.remplacements_seance
  ADD COLUMN IF NOT EXISTS origine text NOT NULL DEFAULT 'manuelle';
DO $contrainte$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
                  WHERE conname = 'remplacements_seance_origine_check') THEN
    ALTER TABLE public.remplacements_seance
      ADD CONSTRAINT remplacements_seance_origine_check CHECK (origine IN ('manuelle', 'auto'));
  END IF;
END;
$contrainte$;
COMMENT ON COLUMN public.remplacements_seance.origine IS
  'A3 : manuelle (geste d''une personne) ou auto (pose par la planification de chaque minute).';

-- ---------------------------------------------------------------------------
-- 2. La preparation d'un remplacement, append-only.
-- ---------------------------------------------------------------------------
CREATE TABLE public.remplacements_preparation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  evenement text NOT NULL CHECK (evenement IN ('pre_alerte', 'pret', 'remplacement_inutile')),
  enseignant_id uuid REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT remplacements_preparation_pret_check CHECK (
    (evenement = 'pret') = (enseignant_id IS NOT NULL))
);
-- Une pre-alerte, un pret (le premier gagne), une fin par seance.
CREATE UNIQUE INDEX remplacements_preparation_unique
  ON public.remplacements_preparation (session_id, evenement);
ALTER TABLE public.remplacements_preparation ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.remplacements_preparation FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER remplacements_preparation_no_update
  BEFORE UPDATE OR DELETE ON public.remplacements_preparation
  FOR EACH ROW EXECUTE FUNCTION public.remplacements_seance_immutable();
COMMENT ON TABLE public.remplacements_preparation IS
  'A3 : pre-alerte (T+avertissement), enseignant pret (le premier gagne), remplacement inutile (titulaire arrive). Append-only, aucun acces client.';

-- ---------------------------------------------------------------------------
-- 3. Notifications : cinq evenements et la destination de la direction.
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
  'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
  'classe_supprimee',
  -- A3 (31/10/2026).
  'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
  'titulaire_en_retard', 'remplacant_arrive'));
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (
  destination IN (
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages', '/tuteur/foyer/recharge',
    '/eleve', '/tuteur', '/enseignant/classes', '/enseignant/journee',
    -- A3 (31/10/2026) : le planning de la direction.
    '/admin/operations/planning')
  OR destination ~ '^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$');

-- ---------------------------------------------------------------------------
-- 4. Aides privees.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.remplacement_reglage(p_cle text)
RETURNS integer
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_brut jsonb;
BEGIN
  SELECT c.value INTO v_brut FROM public.app_config c WHERE c.key = p_cle;
  IF v_brut IS NULL OR pg_catalog.jsonb_typeof(v_brut) <> 'number'
     OR (v_brut #>> '{}') !~ '^[0-9]{1,3}$' THEN
    RAISE EXCEPTION 'reglage % absent ou invalide', p_cle USING ERRCODE = '22023';
  END IF;
  RETURN (v_brut #>> '{}')::integer;
END;
$function$;

-- Le titulaire a-t-il rejoint la salle de cette seance ?
CREATE FUNCTION private.remplacement_titulaire_entre(p_session_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.sessions s
      JOIN public.session_events e ON e.session_id = s.id
                                  AND e.profile_id = s.teacher_id
                                  AND e.event_type = 'joined'
     WHERE s.id = p_session_id);
$function$;

-- Le titulaire ecarte : le dernier evenement est son absence automatique.
-- (Une prise par un collegue l'ecarte deja par c29.)
CREATE FUNCTION private.remplacement_titulaire_ecarte(p_session_id uuid, p_profile_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT coalesce((
    SELECT r.evenement = 'absence_declaree' AND r.origine = 'auto'
           AND r.enseignant_titulaire_id = p_profile_id
      FROM public.remplacements_seance r
     WHERE r.session_id = p_session_id
     ORDER BY r.cree_le DESC, r.id DESC LIMIT 1), false);
$function$;

-- Un enseignant peut-il se preparer a remplacer cette seance : compatible
-- (genre, KYC, compte), libre a l'heure exacte, pas le titulaire.
CREATE FUNCTION private.remplacement_candidat(p_session_id uuid, p_teacher_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (SELECT 1 FROM public.sessions s
                  WHERE s.id = p_session_id AND s.teacher_id <> p_teacher_id)
     AND public.remplacement_enseignant_compatible(p_session_id, p_teacher_id)
     AND private.remplacant_libre_a_l_heure(p_session_id, p_teacher_id);
$function$;

DO $droits_aides$
DECLARE v text;
BEGIN
  FOREACH v IN ARRAY ARRAY[
    'private.remplacement_reglage(text)',
    'private.remplacement_titulaire_entre(uuid)',
    'private.remplacement_titulaire_ecarte(uuid,uuid)',
    'private.remplacement_candidat(uuid,uuid)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v);
  END LOOP;
END;
$droits_aides$;

-- ---------------------------------------------------------------------------
-- 5. Se declarer pret pendant la pre-alerte : le premier pret gagne.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.se_declarer_pret_remplacement(p_session_id uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_pret uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  -- Verrou par seance : deux « pret » simultanes se suivent ici.
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  SELECT p.enseignant_id INTO v_pret FROM public.remplacements_preparation p
   WHERE p.session_id = p_session_id AND p.evenement = 'pret';
  IF v_pret IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('etat',
      CASE WHEN v_pret = auth.uid() THEN 'retenu' ELSE 'dejaRetenu' END);
  END IF;
  IF v_session.id IS NULL
     OR v_session.deleted_at IS NOT NULL
     OR v_session.status NOT IN ('planned', 'preflight')
     OR v_session.ended_at <= pg_catalog.now()
     OR NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p
                     WHERE p.session_id = p_session_id AND p.evenement = 'pre_alerte')
     OR EXISTS (SELECT 1 FROM public.remplacements_preparation p
                 WHERE p.session_id = p_session_id AND p.evenement = 'remplacement_inutile')
     OR EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = p_session_id)
     OR NOT private.remplacement_candidat(p_session_id, auth.uid()) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'fermee');
  END IF;
  INSERT INTO public.remplacements_preparation (session_id, evenement, enseignant_id)
  VALUES (p_session_id, 'pret', auth.uid());
  PERFORM public.log_sensitive_access('replacement_ready', 'remplacements_preparation',
    p_session_id::text, pg_catalog.jsonb_build_object('session_id', p_session_id));
  RETURN pg_catalog.jsonb_build_object('etat', 'retenu');
END;
$function$;
ALTER FUNCTION public.se_declarer_pret_remplacement(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.se_declarer_pret_remplacement(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.se_declarer_pret_remplacement(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. Le tableau commun : la preparation, puis les offres jusqu'a la fin prevue.
--    etat : 'preparation' | 'pret_moi' | 'pret_collegue' | 'ouverte' |
--    'prise_par_moi' | 'prise_par_un_collegue'.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.offres_remplacement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'seance_id', o.session_id, 'groupe_id', o.groupe_id, 'classe', o.libelle,
             'numero_dans_famille', o.numero, 'debut', o.started_at, 'fin', o.ended_at,
             'nb_eleves', o.nb_eleves, 'etat', o.etat)
           ORDER BY o.started_at, o.session_id)
    FROM (
      -- Les offres : le dernier evenement de remplacements_seance.
      SELECT s.id AS session_id, g.id AS groupe_id, g.libelle, n.numero, s.started_at, s.ended_at,
             (SELECT count(*)::integer FROM public.session_participants sp
               WHERE sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL) AS nb_eleves,
             CASE WHEN dernier.evenement = 'absence_declaree' THEN 'ouverte'
                  WHEN dernier.enseignant_remplacant_id = v_moi THEN 'prise_par_moi'
                  ELSE 'prise_par_un_collegue' END AS etat
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      LEFT JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
      CROSS JOIN LATERAL (
        SELECT r.evenement, r.enseignant_titulaire_id, r.enseignant_remplacant_id
        FROM public.remplacements_seance r
        WHERE r.session_id = s.id
        ORDER BY r.cree_le DESC, r.id DESC LIMIT 1
      ) dernier
      WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
        AND s.ended_at > pg_catalog.now()
        AND dernier.enseignant_titulaire_id <> v_moi
        AND (dernier.enseignant_remplacant_id = v_moi
             OR public.remplacement_enseignant_compatible(s.id, v_moi))
      UNION ALL
      -- La preparation : pre-alerte ouverte, aucun evenement de remplacement.
      SELECT s.id, g.id, g.libelle, n.numero, s.started_at, s.ended_at,
             (SELECT count(*)::integer FROM public.session_participants sp
               WHERE sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL),
             CASE WHEN pret.enseignant_id IS NULL THEN 'preparation'
                  WHEN pret.enseignant_id = v_moi THEN 'pret_moi'
                  ELSE 'pret_collegue' END
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      JOIN public.remplacements_preparation pa ON pa.session_id = s.id AND pa.evenement = 'pre_alerte'
      LEFT JOIN public.remplacements_preparation pret ON pret.session_id = s.id AND pret.evenement = 'pret'
      LEFT JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
      WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
        AND s.ended_at > pg_catalog.now()
        AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation x
                         WHERE x.session_id = s.id AND x.evenement = 'remplacement_inutile')
        AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
        AND s.teacher_id <> v_moi
        AND (pret.enseignant_id = v_moi OR private.remplacement_candidat(s.id, v_moi))
    ) o), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. La prise : ouverte jusqu'a la fin prevue.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prendre_remplacement(p_session_id uuid, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_session public.sessions%ROWTYPE; v_existing public.remplacements_seance%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = auth.uid() AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'remplacement_pris' THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  -- A3 (31/10/2026) : une absence reste a prendre jusqu'a la fin prevue de
  -- la seance, seance prevue ou en preparation.
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL
     OR v_session.status NOT IN ('planned', 'preflight')
     OR v_session.ended_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  IF NOT public.remplacement_enseignant_compatible(p_session_id, auth.uid()) THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF NOT FOUND OR v_existing.evenement <> 'absence_declaree' THEN
    IF FOUND AND v_existing.acteur_id = auth.uid()
       AND v_existing.cle_idempotence = p_cle_idempotence THEN
      RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
    END IF;
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES (p_session_id, 'remplacement_pris', v_session.teacher_id, auth.uid(),
          auth.uid(), p_cle_idempotence);
  PERFORM public.log_sensitive_access('replacement_claimed', 'remplacements_seance',
    p_session_id::text, jsonb_build_object('session_id', p_session_id));
  RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7 bis. Le jeton video : le titulaire ecarte perd l'acces a la seance de ce jour.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.autoriser_jeton_video(p_session_id uuid, p_profile_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_route     record;
  v_ttl       int;
  v_camera    public.camera_policy;
  v_publier       boolean;
  v_publier_video boolean;
  v_publier_data  boolean;
  v_invisible     boolean;
  v_expire    timestamptz;
  v_identite  text;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_budget    jsonb;
begin
  -- Meme exigence que 0042 (compte actif, non supprime, acces non echu), mais
  -- sur le profil pour lequel le jeton est demande : `create-room-token`
  -- appelle sous service_role, sans auth.uid(), et la porte de 0042
  -- refusait donc tout le monde. La fonction Edge passe l'identifiant du
  -- jeton Supabase verifie (`compte.id`), jamais une valeur du corps.
  if not exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and p.deleted_at is null
       and p.account_status in ('active', 'provisional_active')
       and (p.access_until is null or p.access_until > now())
  ) then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  if found and v_role = 'teacher'
     and private.c29_enseignant_effectif_session(p_session_id) is not null
     and private.c29_enseignant_effectif_session(p_session_id) <> p_profile_id then
    -- L'attitre remplace garde parfois une ligne participant : elle ne vaut plus.
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;
  if not found then
    -- L'enseignant EFFECTIF de la seance (attitre, ou remplaçant designe par
    -- le dernier evenement de remplacements_seance) : `materialiser_seances_groupe`
    -- n'inscrit que les eleves dans session_participants.
    if private.c29_enseignant_effectif_session(p_session_id) = p_profile_id then
      v_role := 'teacher';
    else
      raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
    end if;
  end if;

  -- A3 (31/10/2026) : le titulaire qui n'est pas entre a temps perd l'acces a
  -- la seance de ce jour (absence automatique). Il reste titulaire de la classe.
  if v_role = 'teacher' and private.remplacement_titulaire_ecarte(p_session_id, p_profile_id) then
    raise exception 'acces a cette seance perdu' using errcode = 'insufficient_privilege';
  end if;


  -- FAC-F-01 : un eleve suspendu pour paiement ne rejoint pas la salle.
  if v_role = 'student' and private.fac_eleve_suspendu(p_profile_id) then
    raise exception 'acces suspendu pour paiement' using errcode = 'insufficient_privilege';
  end if;


  -- Salle en groupe (30/10/2026) : l'eleve que l'enseignant a fait sortir
  -- ne revient pas dans CETTE seance tant qu'il n'est pas readmis.
  if v_role = 'student' and exists (
    select 1 from public.salle_exclusions e
     where e.session_id = p_session_id
       and e.profile_id = p_profile_id
       and e.readmis_le is null
  ) then
    raise exception 'sorti de la seance par l''enseignant' using errcode = 'insufficient_privilege';
  end if;

  -- La fenetre d'ouverture : configurable (D-13, 20 min par defaut), jusqu'a
  -- la fin annoncee majoree de la grace configurable.
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre)) then
    raise exception 'salle pas encore ouverte' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + make_interval(mins => v_grace) then
    raise exception 'salle fermee' using errcode = 'check_violation';
  end if;

  -- Le quota PRECEDE le jeton pour un observateur-tuteur : un jeton d'abord
  -- et un quota ensuite a deja laisse entrer (G §1.5, confirme par Q).
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      raise exception 'quota d''observation atteint : %', v_budget->>'motif_refus'
        using errcode = 'check_violation';
    end if;
  end if;

  select * into v_route from public.video_route_de_seance(
    p_session_id, p_ws_url_cloud, p_ws_url_self_hosted
  );

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  -- Les capacites. Table de G §1.5 :
  --   guardian_observer : rien ne se publie, masque, ttl borne par le budget.
  --   admin_masked      : rien ne se publie, masque comme un controleur.
  --   admin_visible     : voix + image, JAMAIS le canal de donnees (c'est
  --                       l'enseignant qui garde la main pedagogique), visible.
  --   masked_controller : inchange (0010/0012).
  v_identite      := p_profile_id::text;
  -- SEULE LIGNE MODIFIEE PAR 0040. `guardian_observer` rejoint les roles
  -- masques : c'est ce que la table ci-dessus annoncait deja (« masque ») et ce
  -- que la regle de visibilite du 21/09 exige. Sans lui, le jeton partait avec
  -- hidden = false et les quatre autres enfants du groupe voyaient le tuteur.
  v_invisible     := (v_role in ('masked_controller', 'admin_masked', 'guardian_observer'));
  v_publier       := v_role in ('teacher', 'student', 'admin_visible');
  v_publier_data  := (v_role = 'teacher');
  v_publier_video := (v_role = 'admin_visible');

  if v_role = 'teacher' then
    v_publier_video := true;
  elsif v_role = 'student' then
    select sp.camera_policy into v_camera
      from public.student_profiles sp
     where sp.profile_id = p_profile_id;
    v_publier_video := (coalesce(v_camera, 'forbidden') = 'allowed');
  end if;

  if v_role = 'guardian_observer' then
    v_expire := now() + make_interval(secs => least(v_ttl, ((v_budget->>'restant_secondes')::int)));
  else
    v_expire := now() + make_interval(secs => v_ttl);
  end if;

  -- L'identite institutionnelle : c'est l'institution qui entre, pas
  -- quelqu'un. Jamais le prenom de la personne pour admin_visible.
  if v_role = 'admin_visible' then
    v_identite := 'Administration Rewayah';
  end if;

  insert into public.video_token_grants (
    session_id, profile_id, role, provider,
    can_publish, can_publish_video, can_publish_data, hidden, expire_le
  ) values (
    p_session_id, p_profile_id, v_role, v_route.provider,
    v_publier, v_publier_video, v_publier_data, v_invisible, v_expire
  );

  perform public.log_sensitive_access(
    'video_token_issued',
    'video_token_grants',
    p_session_id::text,
    jsonb_build_object(
      'profile_id', p_profile_id,
      'role', v_role,
      'provider', v_route.provider,
      'hidden', v_invisible
    )
  );

  return jsonb_build_object(
    'ws_url', v_route.ws_url,
    'room_name', v_route.room_name,
    'provider', v_route.provider,
    'identity', v_identite,
    'role', v_role,
    'ttl_seconds', extract(epoch from (v_expire - now()))::int,
    'expire_le', v_expire,
    'capabilities', jsonb_build_object(
      'can_publish', v_publier,
      'can_publish_video', v_publier_video,
      'can_publish_data', v_publier_data,
      'can_subscribe', true,
      'can_moderate', v_role = 'teacher',
      'hidden', v_invisible
    )
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- 7 ter. Les familles d'une seance commencee : restez dans la salle.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notifier_classe_remplacements()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_groupe uuid;
  v_debut timestamptz;
BEGIN
  SELECT s.groupe_id, s.started_at INTO v_groupe, v_debut
    FROM public.sessions s
   WHERE s.id = NEW.session_id AND s.deleted_at IS NULL;
  IF v_groupe IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = v_groupe AND g.ended_at IS NULL) THEN
    RETURN NULL;
  END IF;
  -- A3 (31/10/2026) : seance deja commencee, les mots changent (restez dans
  -- la salle) et la direction est prevenue du retard.
  IF v_debut <= pg_catalog.now() THEN
    PERFORM private.notifier_classe(
      v_groupe,
      CASE WHEN NEW.evenement = 'absence_declaree' THEN 'titulaire_en_retard'
           ELSE 'remplacant_arrive' END,
      p_session := NEW.session_id, p_instant := v_debut,
      p_sans_enseignant := true);
    IF NEW.evenement = 'absence_declaree' THEN
      INSERT INTO public.notifications (destinataire, evenement, params, destination)
      SELECT p.id, 'titulaire_en_retard',
             pg_catalog.jsonb_build_object('session_id', NEW.session_id,
               'groupe_id', v_groupe, 'portee', 'direction'),
             '/admin/operations/planning'
        FROM public.profiles p
       WHERE p.role = 'admin' AND p.deleted_at IS NULL
         AND p.account_status = 'active'
         AND (p.access_until IS NULL OR p.access_until > pg_catalog.now());
    END IF;
    RETURN NULL;
  END IF;
  PERFORM private.notifier_classe(
    v_groupe,
    CASE WHEN NEW.evenement = 'absence_declaree' THEN 'enseignante_absente'
         ELSE 'remplacement_pris' END,
    p_session := NEW.session_id, p_instant := v_debut,
    p_sans_enseignant := true);
  RETURN NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. Le passage de chaque minute. Idempotent, une seance verrouillee a la
--    fois (SKIP LOCKED : une seance tenue par une prise est vue au passage
--    suivant). N'annule jamais une seance.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.remplacement_auto_passer(p_maintenant timestamptz)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_avert integer := private.remplacement_reglage('remplacement.avertissement_minutes');
  v_perte integer := private.remplacement_reglage('remplacement.perte_acces_minutes');
  v_objectif integer := private.remplacement_reglage('remplacement.debut_remplacant_minutes');
  v_s record;
  v_pret uuid;
  v_pre_alertes integer := 0;
  v_inutiles integer := 0;
  v_absences integer := 0;
  v_prises integer := 0;
  v_erreurs integer := 0;
BEGIN
  IF p_maintenant IS NULL THEN
    RAISE EXCEPTION 'instant de reference obligatoire' USING ERRCODE = '22023';
  END IF;
  IF NOT (v_avert < v_perte AND v_perte < v_objectif) THEN
    RAISE EXCEPTION 'reglages remplacement.* incoherents' USING ERRCODE = '22023';
  END IF;

  -- a. T + avertissement : titulaire pas entre, rien de pose. Le titulaire
  --    est prevenu ; pre-alerte aux enseignants candidats.
  FOR v_s IN
    SELECT s.id, s.teacher_id, s.groupe_id
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
       AND s.teacher_id IS NOT NULL
       AND s.started_at + pg_catalog.make_interval(mins => v_avert) <= p_maintenant
       AND s.started_at + pg_catalog.make_interval(mins => v_perte) > p_maintenant
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p WHERE p.session_id = s.id)
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
     ORDER BY s.started_at, s.id
       FOR UPDATE OF s SKIP LOCKED
  LOOP
    BEGIN
      IF private.remplacement_titulaire_entre(v_s.id)
         OR EXISTS (SELECT 1 FROM public.remplacements_preparation p WHERE p.session_id = v_s.id) THEN
        CONTINUE;
      END IF;
      INSERT INTO public.remplacements_preparation (session_id, evenement)
      VALUES (v_s.id, 'pre_alerte');
      INSERT INTO public.notifications (destinataire, evenement, params, destination)
      VALUES (v_s.teacher_id, 'remplacement_avertissement',
              pg_catalog.jsonb_build_object('session_id', v_s.id, 'groupe_id', v_s.groupe_id,
                'minutes', (v_perte - v_avert)::text),
              '/enseignant/journee');
      INSERT INTO public.notifications (destinataire, evenement, params, destination)
      SELECT p.id, 'remplacement_pre_alerte',
             pg_catalog.jsonb_build_object('session_id', v_s.id),
             '/enseignant/journee/remplacements'
        FROM public.profiles p
       WHERE p.role = 'teacher' AND p.id <> v_s.teacher_id
         AND p.account_status = 'active' AND p.deleted_at IS NULL
         AND private.remplacement_candidat(v_s.id, p.id);
      PERFORM public.log_sensitive_access('replacement_pre_alert', 'remplacements_preparation',
        v_s.id::text, pg_catalog.jsonb_build_object('session_id', v_s.id, 'automatique', true,
          'avertissement_minutes', v_avert, 'perte_acces_minutes', v_perte));
      v_pre_alertes := v_pre_alertes + 1;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'pre-alerte de la seance % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  -- b. Le titulaire est entre pendant la pre-alerte : remplacement inutile,
  --    l'enseignant pret est prevenu.
  FOR v_s IN
    SELECT s.id
      FROM public.sessions s
      JOIN public.remplacements_preparation pa ON pa.session_id = s.id AND pa.evenement = 'pre_alerte'
     WHERE s.deleted_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation x
                        WHERE x.session_id = s.id AND x.evenement = 'remplacement_inutile')
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
       AND private.remplacement_titulaire_entre(s.id)
     ORDER BY s.started_at, s.id
       FOR UPDATE OF s SKIP LOCKED
  LOOP
    BEGIN
      INSERT INTO public.remplacements_preparation (session_id, evenement)
      VALUES (v_s.id, 'remplacement_inutile')
      ON CONFLICT (session_id, evenement) DO NOTHING;
      IF FOUND THEN
        INSERT INTO public.notifications (destinataire, evenement, params, destination)
        SELECT p.enseignant_id, 'remplacement_inutile',
               pg_catalog.jsonb_build_object('session_id', v_s.id),
               '/enseignant/journee/remplacements'
          FROM public.remplacements_preparation p
         WHERE p.session_id = v_s.id AND p.evenement = 'pret';
        v_inutiles := v_inutiles + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'fin de pre-alerte de la seance % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  -- c. T + perte d'acces : titulaire toujours absent. Absence automatique ;
  --    l'enseignant pret, s'il est toujours candidat, devient remplacant ;
  --    sinon l'offre reste ouverte jusqu'a la fin prevue. Les familles, les
  --    eleves et la direction sont prevenus par le declencheur des familles.
  FOR v_s IN
    SELECT s.id, s.teacher_id
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
       AND s.teacher_id IS NOT NULL
       AND s.started_at + pg_catalog.make_interval(mins => v_perte) <= p_maintenant
       AND s.ended_at > p_maintenant
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation x
                        WHERE x.session_id = s.id AND x.evenement = 'remplacement_inutile')
     ORDER BY s.started_at, s.id
       FOR UPDATE OF s SKIP LOCKED
  LOOP
    BEGIN
      IF private.remplacement_titulaire_entre(v_s.id)
         OR EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = v_s.id) THEN
        CONTINUE;
      END IF;
      INSERT INTO public.remplacements_seance
        (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence, origine)
      VALUES (v_s.id, 'absence_declaree', v_s.teacher_id, v_s.teacher_id,
              pg_catalog.md5('remplacement-auto-absence:' || v_s.id::text)::uuid, 'auto');
      PERFORM public.log_sensitive_access('replacement_absence_auto', 'remplacements_seance',
        v_s.id::text, pg_catalog.jsonb_build_object('session_id', v_s.id, 'automatique', true,
          'perte_acces_minutes', v_perte));
      v_absences := v_absences + 1;
      SELECT p.enseignant_id INTO v_pret FROM public.remplacements_preparation p
       WHERE p.session_id = v_s.id AND p.evenement = 'pret';
      IF v_pret IS NOT NULL AND private.remplacement_candidat(v_s.id, v_pret) THEN
        INSERT INTO public.remplacements_seance
          (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
           acteur_id, cle_idempotence, origine)
        VALUES (v_s.id, 'remplacement_pris', v_s.teacher_id, v_pret, v_pret,
                pg_catalog.md5('remplacement-auto-pris:' || v_s.id::text)::uuid, 'auto');
        PERFORM public.log_sensitive_access('replacement_claimed', 'remplacements_seance',
          v_s.id::text, pg_catalog.jsonb_build_object('session_id', v_s.id, 'automatique', true,
            'enseignant_pret', true));
        v_prises := v_prises + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'absence automatique de la seance % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'pre_alertes', v_pre_alertes, 'inutiles', v_inutiles,
    'absences', v_absences, 'prises', v_prises, 'erreurs', v_erreurs);
END;
$function$;
ALTER FUNCTION private.remplacement_auto_passer(timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacement_auto_passer(timestamptz)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.remplacement_auto_passer(timestamptz) IS
  'A3 : chaque minute, pre-alerte (T+avertissement), remplacement inutile (titulaire arrive), absence automatique et prise par l''enseignant pret (T+perte d''acces). N''annule jamais. Reglages remplacement.*.';

-- ---------------------------------------------------------------------------
-- 9. Planification, si pg_cron est installee (la CI rejoue sans elle).
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('remplacement_auto', '* * * * *',
      'SELECT private.remplacement_auto_passer(pg_catalog.clock_timestamp())')$cron$;
  ELSE
    RAISE NOTICE 'A3 : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

COMMENT ON FUNCTION public.prendre_remplacement(uuid, uuid) IS
  'A3 (31/10/2026) : premier enseignant actif compatible gagne atomiquement, jusqu''a la fin prevue de la seance. F86: signature=public.prendre_remplacement(uuid,uuid); md5_functiondef=5a8744a1f05033d3faaf7a9b0a782e44; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';
COMMENT ON FUNCTION public.offres_remplacement() IS
  'A3 (31/10/2026) : preparation (pre-alerte, pret) puis offres, jusqu''a la fin prevue. F86: signature=public.offres_remplacement(); md5_functiondef=a0d883a41d5b117029b2db435c7e4bf8; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';
COMMENT ON FUNCTION public.se_declarer_pret_remplacement(uuid) IS
  'A3 (31/10/2026) : enseignant actif candidat (compatible, libre a l''heure) se declare pret pendant la pre-alerte ; le premier gagne (index unique, verrou par seance). guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';

DO $postflight$
DECLARE f record;
BEGIN
  FOR f IN SELECT p.oid, p.oid::regprocedure AS sig, p.prosecdef, p.proconfig, p.proowner
             FROM pg_catalog.pg_proc p
            WHERE p.oid IN ('public.prendre_remplacement(uuid,uuid)'::regprocedure,
                            'public.offres_remplacement()'::regprocedure,
                            'public.se_declarer_pret_remplacement(uuid)'::regprocedure)
  LOOP
    IF NOT f.prosecdef OR pg_catalog.pg_get_userbyid(f.proowner) <> 'postgres'
       OR f.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[]
       OR pg_catalog.has_function_privilege('anon', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f.oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'A3 : DEFINER, search_path ou droits invalides pour %', f.sig;
    END IF;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid IN ('public.prendre_remplacement(uuid,uuid)'::regprocedure,
                     'public.offres_remplacement()'::regprocedure)
       AND coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE
           '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%') THEN
    RAISE EXCEPTION 'A3 : empreinte F86 de prendre_remplacement ou offres_remplacement invalide';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.remplacement_auto_passer(timestamptz)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.remplacement_candidat(uuid,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.remplacements_preparation', 'SELECT') THEN
    RAISE EXCEPTION 'A3 : objet prive expose';
  END IF;
  IF pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure)
       NOT LIKE '%remplacement_titulaire_ecarte%'
     OR pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure)
       NOT LIKE '%c29_enseignant_effectif_session%' THEN
    RAISE EXCEPTION 'A3 : autoriser_jeton_video ne lit pas le titulaire ecarte';
  END IF;
END;
$postflight$;
