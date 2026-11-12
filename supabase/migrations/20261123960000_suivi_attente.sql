-- SUIVI-ATTENTE (directeur, 12/11/2026 ; arbitrages S1 a S9 de l'architecte
-- pedagogique ; plage reservee 20261123960000 a 20261123969999) : le suivi de
-- l'attente de la classe choisie, « comme une livraison ».
--
-- Ce que fait ce fichier, et rien d'autre :
--   1. teacher_profiles : le reglage « je montre ma photo et mes pays aux
--      familles de mes classes » (S4), les deux pays et un mot de presentation.
--      Vrai pour les nouveaux enseignants ; FAUX pour ceux qui existent deja,
--      tant qu'ils ne l'ont pas confirme dans leur profil.
--   2. regler_presentation_aux_familles / ma_presentation_aux_familles :
--      l'enseignant regle et relit SON reglage, jamais celui d'un autre.
--   3. suivi_attente_foyer() : UNE lecture du suivi de chaque demande du foyer
--      (cinq etapes, delai honnete, cas hors du chemin droit, carte de
--      l'enseignant selon S4). Reserve a l'eleve lui-meme et a son tuteur.
--   4. Une notification de l'enseignant a l'affectation, enrichie (classe,
--      nombre d'eleves, public, premier cours) : meme evenement
--      `enseignant_affecte`, portee `classe`, aucun evenement cree.
--   5. private.notification_courriel : le courriel de `enseignant_affecte`
--      part pour la famille et pour l'enseignant (c'est une trace, S5 et S8).
--      Cela amende la decision du 01/11/2026 (« application seulement ») sur
--      cette ligne, a la demande du directeur du 12/11/2026.
--   6. app_config : formation_delai_jours (14) et formation_point_jours (7),
--      decides le 30/09, poses si elles manquent. L'entree en debut de mois
--      n'est PAS construite : aucune valeur n'est posee pour elle.
--
-- Ce que ce fichier NE fait pas : aucun evenement de notification n'est cree
-- (« tout est pret » exigerait de remplacer la contrainte
-- notifications_evenement_check, donc un mot d'effacement : interdit a ce
-- lot). Aucun mot d'effacement dans ce fichier. Rejouable. Sans BEGIN ni
-- COMMIT de premier niveau.

-- ---------------------------------------------------------------------------
-- 1. Les colonnes de la presentation aux familles
-- ---------------------------------------------------------------------------
DO $colonnes$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = 'public.teacher_profiles'::regclass
       AND a.attname = 'montre_aux_familles' AND NOT a.attisdropped
  ) THEN
    ALTER TABLE public.teacher_profiles
      ADD COLUMN montre_aux_familles boolean NOT NULL DEFAULT true,
      ADD COLUMN montre_aux_familles_confirme_le timestamptz NULL,
      ADD COLUMN pays_origine text NULL
        CONSTRAINT teacher_profiles_pays_origine_iso CHECK (pays_origine ~ '^[A-Z]{2}$'),
      ADD COLUMN pays_residence text NULL
        CONSTRAINT teacher_profiles_pays_residence_iso CHECK (pays_residence ~ '^[A-Z]{2}$'),
      ADD COLUMN mot_presentation text NULL
        CONSTRAINT teacher_profiles_mot_presentation_borne
          CHECK (pg_catalog.length(mot_presentation) BETWEEN 1 AND 500);
    -- Les enseignants qui existent deja n'ont rien confirme : la carte ne
    -- montre d'eux que le nom et la langue du cours, jusqu'a leur choix.
    UPDATE public.teacher_profiles SET montre_aux_familles = false;
  END IF;
END
$colonnes$;

COMMENT ON COLUMN public.teacher_profiles.montre_aux_familles IS
  'SUIVI-ATTENTE (S4) : l''enseignant montre sa photo, ses deux pays et son mot aux familles de ses classes. Vrai pour les nouveaux, faux pour ceux d''avant le lot tant qu''ils n''ont pas confirme (montre_aux_familles_confirme_le).';
COMMENT ON COLUMN public.teacher_profiles.pays_origine IS
  'SUIVI-ATTENTE : pays d''origine, code ISO 3166-1 alpha-2 majuscule. Nul = non declare, jamais affiche comme « inconnu ». Distinct de country (sens ambigu avant ce lot).';
COMMENT ON COLUMN public.teacher_profiles.pays_residence IS
  'SUIVI-ATTENTE : pays de residence, code ISO 3166-1 alpha-2 majuscule. Nul = non declare.';
COMMENT ON COLUMN public.teacher_profiles.mot_presentation IS
  'SUIVI-ATTENTE : mot de presentation ecrit par l''enseignant (500 caracteres au plus), montre tel quel aux familles de sa classe, jamais modifie.';

-- ---------------------------------------------------------------------------
-- 2. L'enseignant regle et relit SON reglage
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.regler_presentation_aux_familles(
  p_montre boolean,
  p_pays_origine text DEFAULT NULL,
  p_pays_residence text DEFAULT NULL,
  p_mot text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_origine text := nullif(pg_catalog.btrim(p_pays_origine), '');
  v_residence text := nullif(pg_catalog.btrim(p_pays_residence), '');
  v_mot text := nullif(pg_catalog.btrim(p_mot), '');
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'reglage reserve a un enseignant actif' USING ERRCODE = '42501';
  END IF;
  IF p_montre IS NULL
     OR (v_origine IS NOT NULL AND v_origine !~ '^[A-Z]{2}$')
     OR (v_residence IS NOT NULL AND v_residence !~ '^[A-Z]{2}$')
     OR (v_mot IS NOT NULL AND pg_catalog.length(v_mot) > 500) THEN
    RAISE EXCEPTION 'presentation invalide' USING ERRCODE = '22023';
  END IF;

  UPDATE public.teacher_profiles tp
     SET montre_aux_familles = p_montre,
         montre_aux_familles_confirme_le = pg_catalog.now(),
         pays_origine = v_origine,
         pays_residence = v_residence,
         mot_presentation = v_mot
   WHERE tp.profile_id = auth.uid()
     AND tp.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil enseignant introuvable' USING ERRCODE = '42501';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.ma_presentation_aux_familles()
RETURNS TABLE (
  montre_aux_familles boolean,
  confirme boolean,
  pays_origine text,
  pays_residence text,
  mot_presentation text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'lecture reservee a un enseignant actif' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT tp.montre_aux_familles,
         tp.montre_aux_familles_confirme_le IS NOT NULL,
         tp.pays_origine, tp.pays_residence, tp.mot_presentation
    FROM public.teacher_profiles tp
   WHERE tp.profile_id = auth.uid() AND tp.deleted_at IS NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. La lecture unique du suivi
-- ---------------------------------------------------------------------------
-- Les heures sont des heures murales du foyer (AT TIME ZONE households.timezone),
-- comme suivi_demandes_horaires_foyer et la vue des evenements (FRISE-HEURE) :
-- aucune conversion de fuseau n'est inventee ici.
--
-- cas : chemin | en_attente_enseignant | liste_attente | refusee | retiree |
--       close. Etapes : numero 1 a 5, statut fait | en_cours | a_venir.
-- Etape 2 n'a pas de date propre : le serveur n'en connait pas (elle se
-- franchit avec l'etape 3).
-- Etape 5 : franchie seulement si la classe est confirmee, l'enseignant
-- affecte, l'eleve integre et une premiere seance connue.
CREATE OR REPLACE FUNCTION public.suivi_attente_foyer()
RETURNS TABLE (
  demande_id uuid,
  eleve_id uuid,
  prenom text,
  type_public text,
  version_simple boolean,
  fuseau_iana text,
  cas text,
  motif text,
  occurrences jsonb,
  etapes jsonb,
  delai jsonb,
  classe text,
  premier_cours timestamp without time zone,
  creneau_change_le timestamp without time zone,
  enseignant jsonb,
  peut_choisir_autre_creneau boolean,
  premier_cours_passe boolean,
  visible_accueil boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_delai integer;
  v_point integer;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND public.app_role() IN ('guardian', 'student'),
    false
  ) THEN
    RAISE EXCEPTION 'suivi reserve a l''eleve et a son tuteur' USING ERRCODE = '42501';
  END IF;

  -- Une valeur absente ou non entiere : l'ecran ne promet rien.
  SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'number'
               AND (c.value #>> '{}') ~ '^[0-9]{1,3}$'
              THEN (c.value #>> '{}')::integer END
    INTO v_delai FROM public.app_config c WHERE c.key = 'formation_delai_jours';
  SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'number'
               AND (c.value #>> '{}') ~ '^[0-9]{1,3}$'
              THEN (c.value #>> '{}')::integer END
    INTO v_point FROM public.app_config c WHERE c.key = 'formation_point_jours';

  RETURN QUERY
  WITH base AS (
    SELECT d.id AS did, d.eleve_id AS eid, d.etat, d.motif AS dmotif,
           d.type_public AS dtype, d.source, d.groupe_id, d.created_at,
           d.jours, d.heures_locales, d.fuseau_iana AS d_fuseau,
           p.first_name, p.household_id,
           h.timezone AS tz,
           sp.cohorte,
           g.libelle AS g_libelle, g.teacher_id AS g_teacher,
           g.langue_code AS g_langue
      FROM public.demandes_horaires_famille d
      JOIN public.profiles p ON p.id = d.eleve_id AND p.deleted_at IS NULL
      JOIN public.households h ON h.id = p.household_id
                              AND h.deleted_at IS NULL AND h.status = 'active'
      LEFT JOIN public.student_profiles sp ON sp.profile_id = p.id
      LEFT JOIN public.groupes g ON g.id = d.groupe_id
     WHERE (
             public.app_role() = 'student' AND d.eleve_id = auth.uid()
           ) OR (
             public.app_role() = 'guardian'
             AND p.household_id IS NOT NULL
             AND p.household_id = public.app_household_id()
           )
  ), ev AS (
    SELECT b.did,
           min(e.survenu_le) FILTER (WHERE e.type = 'envoyee') AS t_envoyee,
           min(e.survenu_le) FILTER (WHERE e.type = 'classe_creee') AS t_classe,
           min(e.survenu_le) FILTER (WHERE e.type = 'enseignant_affecte') AS t_ens,
           min(e.survenu_le) FILTER (WHERE e.type = 'eleve_integre') AS t_integre,
           min(e.survenu_le) FILTER (WHERE e.type = 'en_attente') AS t_attente,
           min(e.survenu_le) FILTER (WHERE e.type = 'close') AS t_close,
           min(e.motif_attente) FILTER (WHERE e.type = 'en_attente') AS m_attente
      FROM base b
      JOIN public.demande_evenements e ON e.demande_id = b.did
     GROUP BY b.did
  ), calc AS (
    SELECT b.*, ev.t_envoyee, ev.t_classe, ev.t_ens, ev.t_integre, ev.t_attente, ev.m_attente,
           ev.t_close,
           -- La premiere seance de CET eleve : la premiere de sa classe apres son
           -- arrivee, passee ou a venir (elle ne glisse pas sur la suivante).
           CASE WHEN b.etat = 'enseignant_affecte' THEN (
             SELECT min(s.started_at)
               FROM public.sessions s
              WHERE s.groupe_id = b.groupe_id
                AND s.deleted_at IS NULL
                AND s.status NOT IN ('canceled', 'canceled_late')
                AND s.started_at > coalesce(ev.t_integre, ev.t_classe, b.created_at)
           ) END AS t_premier,
           (
             SELECT max(n.cree_le)
               FROM public.notifications n
              WHERE n.evenement = 'creneau_change'
                AND b.groupe_id IS NOT NULL
                AND n.params ->> 'groupe_id' = b.groupe_id::text
                AND n.cree_le > pg_catalog.now() - interval '14 days'
                AND (n.destinataire = b.eid
                     OR n.foyer_id = b.household_id)
           ) AS t_change
      FROM base b
      LEFT JOIN ev ON ev.did = b.did
  ), etat AS (
    SELECT c.*,
           (c.etat IN ('refusee', 'retiree')) AS close_,
           coalesce(c.t_classe IS NOT NULL OR c.etat IN ('classe_validee', 'enseignant_affecte'), false) AS a3,
           coalesce(c.t_ens IS NOT NULL OR c.etat = 'enseignant_affecte', false) AS a4
      FROM calc c
  ), fin AS (
    SELECT e.*,
           (e.a3 AND e.a4 AND e.t_integre IS NOT NULL AND e.t_premier IS NOT NULL) AS a5
      FROM etat e
  )
  SELECT
    f.did,
    f.eid,
    f.first_name,
    f.dtype,
    coalesce(f.cohorte = 'enfant_6_9', false),
    f.tz,
    CASE
      WHEN f.etat = 'refusee' THEN
        CASE WHEN f.dmotif IN ('retrait_famille', 'offre_retiree') THEN 'retiree'
             WHEN f.dmotif = 'refus_direction' THEN 'refusee'
             ELSE 'close' END
      WHEN f.etat = 'retiree' THEN 'retiree'
      WHEN f.a3 AND NOT f.a4 AND f.t_attente IS NOT NULL
           AND f.m_attente = 'aucun_enseignant_libre' THEN 'en_attente_enseignant'
      WHEN f.t_attente IS NOT NULL AND f.m_attente = 'classes_pleines' AND NOT f.a3 THEN 'liste_attente'
      ELSE 'chemin'
    END,
    CASE WHEN f.close_ THEN
      CASE f.dmotif
        WHEN 'retrait_famille' THEN f.dmotif
        WHEN 'offre_retiree' THEN f.dmotif
        WHEN 'classe_non_constituee' THEN f.dmotif
        WHEN 'refus_direction' THEN f.dmotif
        WHEN 'deja_en_classe' THEN f.dmotif
        ELSE NULL END
    END,
    coalesce((
      SELECT pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'jour_iso', extract(isodow FROM x.heure_foyer)::integer,
          'heure', extract(hour FROM x.heure_foyer)::integer,
          'minute', extract(minute FROM x.heure_foyer)::integer)
        ORDER BY x.position)
      FROM (
        SELECT i AS position,
               (
                 (
                   pg_catalog.date_trunc('week', pg_catalog.now() AT TIME ZONE f.d_fuseau)::date
                   + (f.jours[i] - 1)
                   + pg_catalog.make_interval(hours => f.heures_locales[i])
                 ) AT TIME ZONE f.d_fuseau
               ) AT TIME ZONE f.tz AS heure_foyer
          FROM pg_catalog.generate_subscripts(f.jours, 1) AS positions(i)
      ) x
    ), '[]'::jsonb),
    pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('numero', 1, 'statut', 'fait',
        'le', coalesce(f.t_envoyee, f.created_at) AT TIME ZONE f.tz),
      pg_catalog.jsonb_build_object('numero', 2,
        'statut', CASE WHEN f.a3 THEN 'fait'
                       WHEN f.close_ THEN 'a_venir'
                       ELSE 'en_cours' END,
        'le', NULL),
      pg_catalog.jsonb_build_object('numero', 3,
        'statut', CASE WHEN f.a3 THEN 'fait' ELSE 'a_venir' END,
        'le', f.t_classe AT TIME ZONE f.tz),
      pg_catalog.jsonb_build_object('numero', 4,
        'statut', CASE WHEN f.a4 THEN 'fait'
                       WHEN f.a3 AND NOT f.close_ THEN 'en_cours'
                       ELSE 'a_venir' END,
        'le', f.t_ens AT TIME ZONE f.tz),
      pg_catalog.jsonb_build_object('numero', 5,
        'statut', CASE WHEN f.a5 THEN 'fait'
                       WHEN f.a4 AND NOT f.close_ THEN 'en_cours'
                       ELSE 'a_venir' END,
        'le', NULL)
    ),
    -- Delai honnete : date limite et point, nuls quand la valeur manque ou
    -- quand l'etape n'est plus en cours. « depasse » : la limite est passee.
    CASE WHEN NOT f.a3 AND NOT f.close_ AND v_delai IS NOT NULL THEN
      pg_catalog.jsonb_build_object(
        'jours', v_delai,
        'limite', (coalesce(f.t_envoyee, f.created_at) + pg_catalog.make_interval(days => v_delai)) AT TIME ZONE f.tz,
        'point', CASE WHEN v_point IS NULL THEN NULL
                      ELSE (coalesce(f.t_envoyee, f.created_at) + pg_catalog.make_interval(days => v_point)) AT TIME ZONE f.tz END,
        'point_passe', v_point IS NOT NULL
                       AND pg_catalog.now() >= coalesce(f.t_envoyee, f.created_at) + pg_catalog.make_interval(days => v_point),
        'depasse', pg_catalog.now() > coalesce(f.t_envoyee, f.created_at) + pg_catalog.make_interval(days => v_delai))
    END,
    CASE WHEN f.a3 THEN f.g_libelle END,
    f.t_premier AT TIME ZONE f.tz,
    f.t_change AT TIME ZONE f.tz,
    -- La carte de l'enseignant : seulement a l'etape 4. Photo, pays et mot
    -- seulement si l'enseignant l'autorise ; jamais ville, telephone,
    -- courriel, date de naissance ni piece.
    CASE WHEN f.a4 AND f.g_teacher IS NOT NULL THEN (
      SELECT pg_catalog.jsonb_build_object(
        'prenom', t.first_name,
        'nom', t.last_name,
        'titre', CASE t.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayyid' END,
        'langue_cours', (SELECT lc.nom_humain FROM public.langues_cours lc WHERE lc.code = f.g_langue),
        'montre', tp.montre_aux_familles,
        'teacher_id', CASE WHEN tp.montre_aux_familles THEN t.id END,
        'pays_origine', CASE WHEN tp.montre_aux_familles THEN tp.pays_origine END,
        'pays_residence', CASE WHEN tp.montre_aux_familles THEN tp.pays_residence END,
        'mot', CASE WHEN tp.montre_aux_familles THEN tp.mot_presentation END)
        FROM public.profiles t
        JOIN public.teacher_profiles tp ON tp.profile_id = t.id
       WHERE t.id = f.g_teacher AND t.deleted_at IS NULL
    ) END,
    f.etat IN ('refusee', 'retiree')
      AND NOT EXISTS (
        SELECT 1 FROM public.groupe_membres gm
         WHERE gm.student_id = f.eid AND gm.left_at IS NULL),
    f.t_premier IS NOT NULL AND f.t_premier <= pg_catalog.now(),
    -- S6 : en tete de l'accueil tant que le suivi n'est pas fini ; il en
    -- disparait 7 jours apres le premier cours (ou apres la cloture) et reste
    -- consultable dans le parcours.
    CASE
      WHEN f.close_ THEN
        pg_catalog.now() <= coalesce(f.t_close, f.created_at) + interval '7 days'
      WHEN f.t_premier IS NOT NULL AND f.t_premier <= pg_catalog.now() THEN
        pg_catalog.now() <= f.t_premier + interval '7 days'
      ELSE true
    END
  FROM fin f
  ORDER BY (f.etat IN ('refusee', 'retiree')), f.created_at DESC, f.did;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. La notification de l'enseignant a l'affectation
-- ---------------------------------------------------------------------------
-- Meme evenement `enseignant_affecte`, portee `classe` : celle que
-- private.notifier_classe pose deja pour l'enseignant, ici enrichie. Comme
-- notifier_classe, le declencheur est DIFFERE a la validation de la
-- transaction : il lit l'etat final (eleves presents, premiere seance
-- materialisee). Son nom precede `notifications_classe_groupes` : il pose sa
-- ligne AVANT le declencheur de notifier_classe, qui la voit et n'en ajoute pas
-- une seconde (meme destinataire, meme evenement, meme classe, meme
-- transaction). Un message n'est jamais ecrit a un eleve : seul l'enseignant
-- de la classe est destinataire.
CREATE OR REPLACE FUNCTION private.suivi_attente_notifier_enseignant()
RETURNS trigger
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_fuseau text;
  v_premier timestamptz;
  v_eleves integer;
  v_tranche text;
BEGIN
  IF OLD.teacher_id IS NOT NULL OR NEW.teacher_id IS NULL THEN
    RETURN NULL;
  END IF;
  -- L'etat final de la classe : fermee ou reprise avant la validation, rien.
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = NEW.id;
  IF NOT FOUND OR v_g.teacher_id IS DISTINCT FROM NEW.teacher_id
     OR v_g.ended_at IS NOT NULL OR v_g.etat <> 'active' THEN
    RETURN NULL;
  END IF;
  SELECT coalesce(tp.timezone_iana, v_g.timezone_iana) INTO v_fuseau
    FROM public.teacher_profiles tp WHERE tp.profile_id = v_g.teacher_id;
  v_fuseau := coalesce(v_fuseau, v_g.timezone_iana, 'UTC');
  SELECT min(s.started_at) INTO v_premier
    FROM public.sessions s
   WHERE s.groupe_id = v_g.id AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now();
  SELECT count(*)::integer INTO v_eleves
    FROM public.groupe_membres gm
   WHERE gm.groupe_id = v_g.id AND gm.left_at IS NULL;
  -- La tranche d'age : celles des eleves presents, dans l'ordre de la table.
  SELECT pg_catalog.string_agg(x.nom_humain, ', ' ORDER BY x.ordre) INTO v_tranche
    FROM (
      SELECT DISTINCT ca.nom_humain, ca.ordre
        FROM public.groupe_membres gm
        JOIN public.student_profiles sp ON sp.profile_id = gm.student_id
        JOIN public.cohortes_age ca ON ca.code = sp.cohorte
       WHERE gm.groupe_id = v_g.id AND gm.left_at IS NULL
    ) x;

  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT p.id, NULL, 'enseignant_affecte',
         pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'groupe_id', v_g.id,
           'portee', 'classe',
           'classe', v_g.libelle,
           'fuseau', v_fuseau,
           'eleves_n', v_eleves,
           'public', v_g.type_public,
           'tranche', v_tranche,
           'debut_local', CASE WHEN v_premier IS NULL THEN NULL
                               ELSE pg_catalog.to_char(v_premier AT TIME ZONE v_fuseau,
                                                       'YYYY-MM-DD"T"HH24:MI:SS') END)),
         '/enseignant/classes'
    FROM public.profiles p
   WHERE p.id = v_g.teacher_id AND p.deleted_at IS NULL;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.suivi_attente_notifier_enseignant()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $declencheur$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.groupes'::regclass
       AND t.tgname = 'a_suivi_attente_enseignant_affecte'
       AND NOT t.tgisinternal
  ) THEN
    CREATE CONSTRAINT TRIGGER a_suivi_attente_enseignant_affecte
      AFTER UPDATE OF teacher_id ON public.groupes
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW EXECUTE FUNCTION private.suivi_attente_notifier_enseignant();
  END IF;
END
$declencheur$;

-- Effacement du compte : `private.cpt_anonymiser` (20261018150000) efface la
-- photo, le pays et le titre, pas les colonnes de ce lot. La remplacer n'est
-- pas possible sans recopier ses effacements de lignes ; comme PHOTOS-1
-- (20261107300000), un declencheur reconnait la marque d'anonymisation du
-- profil et efface les pays et le mot de l'enseignant, qui ne montre plus rien.
CREATE OR REPLACE FUNCTION private.suivi_attente_effacer_si_anonymise()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.first_name = 'Compte' AND NEW.last_name = 'supprimé'
     AND NEW.account_status = 'disabled' THEN
    UPDATE public.teacher_profiles tp
       SET pays_origine = NULL, pays_residence = NULL,
           mot_presentation = NULL, montre_aux_familles = false
     WHERE tp.profile_id = NEW.id;
  END IF;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.suivi_attente_effacer_si_anonymise()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $declencheur_anonymisation$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.profiles'::regclass
       AND t.tgname = 'profiles_suivi_attente_anonymisation'
       AND NOT t.tgisinternal
  ) THEN
    CREATE TRIGGER profiles_suivi_attente_anonymisation
      AFTER UPDATE OF first_name, last_name, account_status ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION private.suivi_attente_effacer_si_anonymise();
  END IF;
END
$declencheur_anonymisation$;

-- ---------------------------------------------------------------------------
-- 5. Le courriel de `enseignant_affecte` : famille et enseignant (trace)
-- ---------------------------------------------------------------------------
INSERT INTO private.notification_courriel (evenement, portee, courriel) VALUES
  ('enseignant_affecte', 'classe', true),
  ('enseignant_affecte', 'soi', true),
  ('enseignant_affecte', 'foyer', true)
ON CONFLICT (evenement, portee) DO UPDATE SET courriel = EXCLUDED.courriel;

-- ---------------------------------------------------------------------------
-- 6. Les delais lus dans les reglages (decision du 30/09)
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('formation_delai_jours', '14'::jsonb),
  ('formation_point_jours', '7'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Droits : EXECUTE retire de PUBLIC et de anon, accorde a authenticated.
-- ---------------------------------------------------------------------------
DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.regler_presentation_aux_familles(boolean,text,text,text)',
    'public.ma_presentation_aux_familles()',
    'public.suivi_attente_foyer()'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END
$acl$;

COMMENT ON FUNCTION public.suivi_attente_foyer() IS
  'SUIVI-ATTENTE : une ligne par demande de l''eleve ou de son tuteur ; cinq etapes tirees des faits du serveur ; carte de l''enseignant a l''etape 4 selon son reglage. guard=compte valide, role guardian ou student.';
COMMENT ON FUNCTION public.regler_presentation_aux_familles(boolean,text,text,text) IS
  'SUIVI-ATTENTE : l''enseignant regle sa visibilite aupres des familles, ses deux pays et son mot. guard=enseignant actif, sa seule ligne.';
COMMENT ON FUNCTION public.ma_presentation_aux_familles() IS
  'SUIVI-ATTENTE : l''enseignant relit son reglage de visibilite. guard=enseignant actif.';

DO $postflight$
DECLARE
  v_oid oid;
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.regler_presentation_aux_familles(boolean,text,text,text)',
    'public.ma_presentation_aux_familles()',
    'public.suivi_attente_foyer()'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure(v_sig);
    IF v_oid IS NULL
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                       WHERE p.oid = v_oid AND p.prosecdef
                         AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'SUIVI-ATTENTE postflight : % absente, non DEFINER, search_path ou ACL invalide', v_sig;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.suivi_attente_effacer_si_anonymise()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE postflight : le declencheur d anonymisation est executable par authenticated';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.suivi_attente_notifier_enseignant()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE postflight : le declencheur est executable par authenticated';
  END IF;
END
$postflight$;
