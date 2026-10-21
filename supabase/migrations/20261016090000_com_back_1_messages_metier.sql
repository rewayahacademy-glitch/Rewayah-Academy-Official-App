-- COM-BACK-1 (1/2) : Messages metier (COM-BR-01, COM-BR-02).
--
-- Contrat : lib/features/com_messages/port_messages_metier.dart
-- (PortMessagesMetier) et lib/core/communications/modeles_communication.dart.
-- Spec : Communications V1, section 3 (19_communications/V/
-- REWAYAH_COMMUNICATIONS_FRONTEND_V1.md), proposition Codex
-- docs/orchestration/COM-BACK-1-PROPOSITION.md (branche codex/com-back-1-wip).
--
-- Principes :
-- * un fil est TOUJOURS lie a un objet (Classe, eleve, dossier, remplacement,
--   profil de paiement) et a une PAIRE de parties autorisee par la spec 3.2 ;
--   il n'existe aucun annuaire ni message libre ;
-- * une partie est un profil adulte (enseignant, eleve adulte), un FOYER
--   (tous les tuteurs du foyer lisent le meme fil) ou l'equipe
--   d'administration ; un mineur n'est JAMAIS une partie : tout echange qui
--   concerne un eleve mineur passe par le fil de son foyer, donc reste visible
--   de chacun de ses tuteurs (spec 3.2 : « Enfant en Interface guidee :
--   communication libre : Non ») ;
-- * les paires sont recalculees a chaque appel depuis l'etat courant
--   (Classe active, appartenance active, comptes valides) ; un identifiant de
--   fil n'est jamais une autorisation ;
-- * aucune ecriture directe : RLS active, aucun privilege de table pour
--   PUBLIC, anon, authenticated, service_role ni agent_ro ; tout passe par des
--   RPC SECURITY DEFINER a search_path vide (F86) ;
-- * horodatage : timestamptz (UTC), horloge serveur clock_timestamp().
--
-- Le fil « mission » (controleur et Administration) reste celui de B-12
-- (public.mission_fils, controleur_* : 20261012140000) : le controleur ne lit
-- que les fils de SA mission par ces RPC, et les RPC com_* ne lui ouvrent rien.
--
-- Choix metier non ecrits par le directeur (choix par defaut, a confirmer) :
-- * C1 messages en ajout seul : ni modification ni suppression par un
--   utilisateur (preuve conservee en cas de signalement concernant un mineur) ;
-- * C2 conservation : aucun effacement automatique dans ce lot ; duree cible
--   proposee 24 mois apres le dernier message du fil, a confirmer avant
--   d'ecrire la purge (COM-BR-12) ;
-- * C3 texte de 1 a 5000 caracteres apres retrait des espaces (meme borne que
--   B-12) ; aucune piece jointe ni vocal dans ce lot (COM-BR-03/04 a part) ;
-- * C4 un eleve adulte n'ecrit qu'a l'enseignant de sa Classe (spec 3.2 ne
--   prevoit pas eleve adulte et Administration) ;
-- * C5 lorsqu'une paire n'est plus autorisee (eleve sorti de la Classe,
--   enseignant change), l'enseignant perd la lecture du fil ; le foyer,
--   l'eleve adulte et l'Administration gardent la lecture seule de
--   l'historique ; personne n'y ecrit plus ;
-- * C6 l'Administration ne lit pas les fils enseignant et famille dont elle
--   n'est pas partie (aucune supervision silencieuse) ; a confirmer ;
-- * C7 l'equipe d'un fil « profil de paiement » comprend l'Administration et
--   le Comptable (CPT-BR-11) ; pour tout autre objet, l'Administration seule ;
-- * C8 filPourObjet n'ouvre un fil que si l'objet n'admet qu'une seule paire
--   pour l'appelant ; sinon il rend null et l'ecran passe par
--   ouvrirConversation (paire explicite).

BEGIN;

-- ============================================================
-- 1. Tables
-- ============================================================

CREATE TABLE public.com_fils (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  type_objet text NOT NULL CHECK (type_objet IN
    ('classe', 'eleve', 'dossier', 'remplacement', 'profilPaiement')),
  objet_id uuid NOT NULL,
  -- partie A : le cote « client » (foyer, eleve adulte, ou enseignant face
  -- a l'equipe). Partie B : l'enseignant ou l'equipe.
  partie_a_nature text NOT NULL CHECK (partie_a_nature IN ('profil', 'foyer')),
  partie_a_id uuid NOT NULL,
  partie_b_nature text NOT NULL CHECK (partie_b_nature IN ('profil', 'equipe')),
  partie_b_id uuid,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  dernier_message_le timestamptz,
  CONSTRAINT com_fils_equipe_sans_id CHECK (
    (partie_b_nature = 'equipe') = (partie_b_id IS NULL)),
  CONSTRAINT com_fils_parties_distinctes CHECK (
    partie_b_id IS NULL OR partie_b_id <> partie_a_id)
);
CREATE UNIQUE INDEX com_fils_paire_uidx ON public.com_fils (
  type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature,
  coalesce(partie_b_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX com_fils_partie_a_idx ON public.com_fils (partie_a_id);
CREATE INDEX com_fils_partie_b_idx ON public.com_fils (partie_b_id)
  WHERE partie_b_id IS NOT NULL;

CREATE TABLE public.com_messages (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  fil_id uuid NOT NULL REFERENCES public.com_fils(id) ON DELETE RESTRICT,
  auteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cle_idempotence uuid NOT NULL,
  texte text NOT NULL CHECK (pg_catalog.btrim(texte) <> ''
    AND pg_catalog.length(texte) <= 5000),
  envoye_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT com_messages_idempotence UNIQUE (fil_id, auteur_id, cle_idempotence)
);
CREATE INDEX com_messages_fil_date_idx ON public.com_messages (fil_id, envoye_le, id);

CREATE TABLE public.com_lectures (
  fil_id uuid NOT NULL REFERENCES public.com_fils(id) ON DELETE RESTRICT,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  lu_jusqu_au timestamptz NOT NULL,
  PRIMARY KEY (fil_id, profile_id)
);

ALTER TABLE public.com_fils ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.com_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.com_lectures ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_fils, public.com_messages, public.com_lectures
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.com_fils IS
  'COM-BACK-1 : fil metier lie a un objet et a une paire autorisee (spec 3.2). '
  'Aucune policy : lecture et ecriture par les RPC com_* seulement.';
COMMENT ON TABLE public.com_messages IS
  'COM-BACK-1 : messages en ajout seul (C1). Conservation cible 24 mois apres '
  'le dernier message du fil, purge non ecrite (C2, a confirmer).';

-- ============================================================
-- 2. Predicats prives (INVOKER, appeles depuis les RPC DEFINER)
-- ============================================================

-- Vrai si le profil est un eleve mineur, ou si rien ne prouve qu'il est
-- adulte (un compte eleve sans profil autonome est traite en mineur).
CREATE FUNCTION private.com_est_mineur(p_profile_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(
    (SELECT sp.student_type = 'minor' FROM public.student_profiles sp
      WHERE sp.profile_id = p_profile_id AND sp.deleted_at IS NULL),
    (SELECT p.role = 'student' FROM public.profiles p WHERE p.id = p_profile_id),
    true);
$function$;

-- Un compte utilisable maintenant, du role attendu.
CREATE FUNCTION private.com_profil_valide(p_profile_id uuid, p_role text)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id
      AND (p_role IS NULL OR p.role::text = p_role)
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp()));
$function$;

-- Un foyer actif qui compte au moins un tuteur au compte valide.
CREATE FUNCTION private.com_foyer_valide(p_foyer_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.households h
    JOIN public.profiles g ON g.household_id = h.id AND g.role = 'guardian'
    WHERE h.id = p_foyer_id AND h.status = 'active' AND h.deleted_at IS NULL
      AND private.com_profil_valide(g.id, 'guardian'));
$function$;

-- L'appelant : compte valide, role du jeton egal au role en base (un jeton
-- perime apres changement de role est refuse), jamais un mineur.
CREATE FUNCTION private.com_appelant()
RETURNS TABLE (id uuid, role text, foyer uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT p.id, p.role::text, p.household_id
  FROM public.profiles p
  WHERE p.id = auth.uid()
    AND coalesce(public.app_account_valid(), false)
    AND p.role::text = public.app_role()::text
    AND private.com_profil_valide(p.id, NULL)
    AND NOT private.com_est_mineur(p.id);
$function$;

-- Les paires autorisees MAINTENANT sur un objet (spec 3.2). Ni famille et
-- famille, ni enseignant et enseignant, ni eleve et eleve : ces paires ne
-- sont construites par aucune branche.
CREATE FUNCTION private.com_paires(p_type text, p_objet_id uuid)
RETURNS TABLE (a_nature text, a_id uuid, b_nature text, b_id uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  WITH membres AS (
    -- Eleves actifs d'une Classe active, avec leur enseignant valide.
    SELECT g.id AS groupe_id, g.teacher_id, s.id AS eleve_id, s.household_id,
           private.com_est_mineur(s.id) AS mineur
    FROM public.groupes g
    JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
    JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
    WHERE g.ended_at IS NULL
  ), cibles AS (
    -- Classe : chaque foyer d'un eleve mineur, chaque eleve adulte, avec
    -- l'enseignant ; foyer et Administration ; enseignant et Administration.
    SELECT 'foyer' AS a_nature, mb.household_id AS a_id, 'profil' AS b_nature, mb.teacher_id AS b_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT 'profil', g.teacher_id, 'equipe', NULL
      FROM public.groupes g WHERE p_type = 'classe' AND g.id = p_objet_id AND g.ended_at IS NULL
    -- Eleve : mineur, son foyer avec son enseignant et avec l'Administration ;
    -- adulte, lui-meme avec son enseignant.
    UNION
    SELECT 'foyer', mb.household_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND NOT mb.mineur
    -- Dossier (identifiant = profil du titulaire du dossier) : enseignant
    -- ou foyer du tuteur, avec l'Administration.
    UNION
    SELECT CASE p.role WHEN 'teacher' THEN 'profil' ELSE 'foyer' END,
           CASE p.role WHEN 'teacher' THEN p.id ELSE p.household_id END,
           'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'dossier' AND p.id = p_objet_id AND p.deleted_at IS NULL
        AND p.role IN ('teacher', 'guardian')
    -- Remplacement : titulaire et remplacant, chacun avec l'Administration.
    UNION
    SELECT 'profil', x.enseignant_id, 'equipe', NULL
      FROM public.remplacements_seance r
      CROSS JOIN LATERAL (VALUES (r.enseignant_titulaire_id), (r.enseignant_remplacant_id))
        AS x(enseignant_id)
      WHERE p_type = 'remplacement' AND r.id = p_objet_id AND x.enseignant_id IS NOT NULL
    -- Profil de paiement (CPT-BR-11) : le beneficiaire enseignant et l'equipe.
    UNION
    SELECT 'profil', p.id, 'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'profilPaiement' AND p.id = p_objet_id AND p.role = 'teacher'
  )
  SELECT c.a_nature, c.a_id, c.b_nature, c.b_id
  FROM cibles c
  WHERE c.a_id IS NOT NULL
    AND CASE c.a_nature
          WHEN 'foyer' THEN private.com_foyer_valide(c.a_id)
          ELSE private.com_profil_valide(c.a_id, NULL) AND NOT private.com_est_mineur(c.a_id)
        END
    AND (c.b_nature = 'equipe'
         OR (private.com_profil_valide(c.b_id, 'teacher') AND c.b_id <> c.a_id));
$function$;

-- Vrai si l'appelant [p_moi] (deja valide par com_appelant) est la partie
-- (nature, id) d'un fil sur un objet de type [p_type].
CREATE FUNCTION private.com_est_partie(
  p_moi uuid, p_role text, p_foyer uuid, p_type text, p_nature text, p_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(CASE p_nature
    WHEN 'profil' THEN p_id = p_moi
    WHEN 'foyer' THEN p_role = 'guardian' AND p_foyer IS NOT NULL AND p_id = p_foyer
    WHEN 'equipe' THEN p_role = 'admin'
                    OR (p_role = 'accountant' AND p_type = 'profilPaiement')
    ELSE false END, false);
$function$;

-- Un participant tel que l'ecran peut le nommer : prenom, et pour un
-- enseignant son nom et son titre (Sayyid, Sayyida). Aucune coordonnee.
CREATE FUNCTION private.com_participant(p_nature text, p_id uuid, p_type text, p_objet_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT CASE p_nature
    WHEN 'equipe' THEN pg_catalog.jsonb_build_object(
      'id', 'administration', 'nature', 'equipe', 'fonction', 'administration')
    WHEN 'foyer' THEN pg_catalog.jsonb_build_object(
      'id', p_id::text, 'nature', 'foyer', 'fonction', 'famille',
      'eleves', coalesce((
        SELECT pg_catalog.jsonb_agg(s.first_name ORDER BY s.first_name, s.id)
        FROM public.profiles s
        WHERE s.household_id = p_id AND s.deleted_at IS NULL
          AND s.role = 'student' AND private.com_est_mineur(s.id)
          AND CASE p_type
                WHEN 'eleve' THEN s.id = p_objet_id
                WHEN 'classe' THEN EXISTS (
                  SELECT 1 FROM public.groupe_membres m
                  WHERE m.student_id = s.id AND m.groupe_id = p_objet_id AND m.left_at IS NULL)
                ELSE true END), '[]'::jsonb))
    ELSE (
      SELECT pg_catalog.jsonb_build_object(
        'id', p.id::text, 'nature', 'profil',
        'fonction', CASE p.role WHEN 'teacher' THEN 'enseignant'
                                WHEN 'guardian' THEN 'famille'
                                WHEN 'student' THEN 'eleve'
                                ELSE 'personne' END,
        'prenom', p.first_name,
        'nom', CASE WHEN p.role = 'teacher' THEN p.last_name END,
        'titre', CASE WHEN p.role = 'teacher' THEN
                   CASE p.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayid' END END)
      FROM public.profiles p WHERE p.id = p_id)
    END;
$function$;

-- L'objet d'un fil, en donnees brutes (l'adaptateur redige le libelle).
CREATE FUNCTION private.com_objet(p_type text, p_objet_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
    'type', p_type, 'id', p_objet_id::text,
    'classe', CASE p_type
      WHEN 'classe' THEN (SELECT g.libelle FROM public.groupes g WHERE g.id = p_objet_id)
      WHEN 'eleve' THEN (SELECT g.libelle FROM public.groupe_membres m
                           JOIN public.groupes g ON g.id = m.groupe_id
                          WHERE m.student_id = p_objet_id AND m.left_at IS NULL
                          ORDER BY m.joined_at DESC LIMIT 1)
      WHEN 'remplacement' THEN (SELECT g.libelle FROM public.remplacements_seance r
                                  JOIN public.sessions s ON s.id = r.session_id
                                  JOIN public.groupes g ON g.id = s.groupe_id
                                 WHERE r.id = p_objet_id)
      END,
    'prenom', CASE p_type WHEN 'eleve' THEN
      (SELECT p.first_name FROM public.profiles p WHERE p.id = p_objet_id) END));
$function$;

-- Le fil [p_fil_id] vu par l'appelant, ou null s'il ne peut pas le lire
-- (C5 : la partie B enseignant ne lit plus une paire retiree).
CREATE FUNCTION private.com_fil_json(p_fil_id uuid, p_moi uuid, p_role text, p_foyer uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $function$
DECLARE
  f public.com_fils%ROWTYPE;
  v_soi_a boolean;
  v_soi_b boolean;
  v_autorisee boolean;
  v_lu timestamptz;
BEGIN
  SELECT * INTO f FROM public.com_fils x WHERE x.id = p_fil_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  v_soi_a := private.com_est_partie(p_moi, p_role, p_foyer, f.type_objet, f.partie_a_nature, f.partie_a_id);
  v_soi_b := private.com_est_partie(p_moi, p_role, p_foyer, f.type_objet, f.partie_b_nature, f.partie_b_id);
  IF NOT (v_soi_a OR v_soi_b) THEN RETURN NULL; END IF;
  v_autorisee := EXISTS (
    SELECT 1 FROM private.com_paires(f.type_objet, f.objet_id) q
    WHERE q.a_nature = f.partie_a_nature AND q.a_id = f.partie_a_id
      AND q.b_nature = f.partie_b_nature AND q.b_id IS NOT DISTINCT FROM f.partie_b_id);
  IF NOT (v_autorisee OR v_soi_a OR f.partie_b_nature = 'equipe') THEN RETURN NULL; END IF;
  SELECT l.lu_jusqu_au INTO v_lu FROM public.com_lectures l
    WHERE l.fil_id = f.id AND l.profile_id = p_moi;
  RETURN pg_catalog.jsonb_build_object(
    'id', f.id,
    'objet', private.com_objet(f.type_objet, f.objet_id),
    'accessible', v_autorisee,
    'peut_ecrire', v_autorisee,
    'cree_le', f.cree_le,
    'dernier_message_le', f.dernier_message_le,
    'parties', pg_catalog.jsonb_build_array(
      private.com_participant(f.partie_a_nature, f.partie_a_id, f.type_objet, f.objet_id)
        || pg_catalog.jsonb_build_object('est_soi', v_soi_a),
      private.com_participant(f.partie_b_nature, f.partie_b_id, f.type_objet, f.objet_id)
        || pg_catalog.jsonb_build_object('est_soi', v_soi_b)),
    'non_lus', (SELECT count(*) FROM public.com_messages m
                 WHERE m.fil_id = f.id AND m.auteur_id <> p_moi
                   AND m.envoye_le > coalesce(v_lu, '-infinity'::timestamptz)),
    'messages', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', m.id,
        'texte', m.texte,
        'envoye_le', m.envoye_le,
        'auteur', CASE
          WHEN f.partie_b_nature = 'equipe' AND NOT private.com_est_partie(
                 m.auteur_id, a.role::text, a.household_id, f.type_objet,
                 f.partie_a_nature, f.partie_a_id)
            THEN private.com_participant('equipe', NULL, f.type_objet, f.objet_id)
          ELSE private.com_participant('profil', m.auteur_id, f.type_objet, f.objet_id)
          END || pg_catalog.jsonb_build_object('est_soi', m.auteur_id = p_moi))
        ORDER BY m.envoye_le, m.id)
      FROM public.com_messages m JOIN public.profiles a ON a.id = m.auteur_id
      WHERE m.fil_id = f.id), '[]'::jsonb));
END;
$function$;

-- Defense en profondeur : aucune partie « profil » ne peut etre un mineur.
CREATE FUNCTION private.com_fils_sans_mineur()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  IF (NEW.partie_a_nature = 'profil' AND private.com_est_mineur(NEW.partie_a_id))
     OR (NEW.partie_b_nature = 'profil' AND private.com_est_mineur(NEW.partie_b_id)) THEN
    RAISE EXCEPTION 'COM-BACK-1 : un mineur n''est jamais partie d''un fil'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER com_fils_sans_mineur BEFORE INSERT OR UPDATE ON public.com_fils
  FOR EACH ROW EXECUTE FUNCTION private.com_fils_sans_mineur();

-- C1 : messages en ajout seul.
CREATE FUNCTION private.com_refuser_mutation()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  RAISE EXCEPTION 'COM-BACK-1 : historique en ajout seul' USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER com_messages_ajout_seul BEFORE UPDATE OR DELETE ON public.com_messages
  FOR EACH ROW EXECUTE FUNCTION private.com_refuser_mutation();

REVOKE ALL ON FUNCTION private.com_est_mineur(uuid), private.com_profil_valide(uuid, text),
  private.com_foyer_valide(uuid), private.com_appelant(), private.com_paires(text, uuid),
  private.com_est_partie(uuid, text, uuid, text, text, uuid),
  private.com_participant(text, uuid, text, uuid), private.com_objet(text, uuid),
  private.com_fil_json(uuid, uuid, text, uuid), private.com_fils_sans_mineur(),
  private.com_refuser_mutation()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 3. RPC (SECURITY DEFINER, search_path vide)
-- ============================================================

-- Les fils lisibles par l'appelant, le plus recent d'abord.
CREATE FUNCTION public.com_lister_fils()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_resultat jsonb;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.fil ORDER BY x.activite DESC, x.id DESC), '[]'::jsonb)
    INTO v_resultat
  FROM (
    SELECT f.id, coalesce(f.dernier_message_le, f.cree_le) AS activite,
           private.com_fil_json(f.id, moi.id, moi.role, moi.foyer) AS fil
    FROM public.com_fils f
    WHERE private.com_est_partie(moi.id, moi.role, moi.foyer, f.type_objet, f.partie_a_nature, f.partie_a_id)
       OR private.com_est_partie(moi.id, moi.role, moi.foyer, f.type_objet, f.partie_b_nature, f.partie_b_id)
  ) x
  WHERE x.fil IS NOT NULL;
  RETURN v_resultat;
END;
$function$;

-- Le fil [p_fil_id], ou null (absent ou refuse : jamais distingues).
CREATE FUNCTION public.com_lire_fil(p_fil_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE moi record;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fil_id IS NULL THEN RETURN NULL; END IF;
  RETURN private.com_fil_json(p_fil_id, moi.id, moi.role, moi.foyer);
END;
$function$;

-- Les conversations que l'appelant peut ouvrir sur un objet.
CREATE FUNCTION public.com_conversations_pour_objet(p_type text, p_objet_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_resultat jsonb;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_objet_id IS NULL THEN RETURN '[]'::jsonb; END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'interlocuteur', y.interlocuteur,
      'nature', CASE y.autre_nature WHEN 'foyer' THEN 'famille'
                                    WHEN 'equipe' THEN 'administration'
                                    ELSE 'personne' END,
      'objet', private.com_objet(p_type, p_objet_id),
      'fil_id', y.fil_id,
      'non_lus', coalesce((private.com_fil_json(y.fil_id, moi.id, moi.role, moi.foyer) ->> 'non_lus')::integer, 0))
    ORDER BY y.rang, y.interlocuteur ->> 'prenom', y.autre_id), '[]'::jsonb)
    INTO v_resultat
  FROM (
    SELECT q.*, f.id AS fil_id,
           CASE WHEN q.soi_a THEN q.b_nature ELSE q.a_nature END AS autre_nature,
           CASE WHEN q.soi_a THEN q.b_id ELSE q.a_id END AS autre_id,
           private.com_participant(CASE WHEN q.soi_a THEN q.b_nature ELSE q.a_nature END,
                                   CASE WHEN q.soi_a THEN q.b_id ELSE q.a_id END,
                                   p_type, p_objet_id) AS interlocuteur,
           CASE WHEN (CASE WHEN q.soi_a THEN q.b_nature ELSE q.a_nature END) = 'equipe' THEN 1 ELSE 0 END AS rang
    FROM (
      SELECT p.*,
             private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.a_nature, p.a_id) AS soi_a,
             private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.b_nature, p.b_id) AS soi_b
      FROM private.com_paires(p_type, p_objet_id) p
    ) q
    LEFT JOIN public.com_fils f ON f.type_objet = p_type AND f.objet_id = p_objet_id
      AND f.partie_a_nature = q.a_nature AND f.partie_a_id = q.a_id
      AND f.partie_b_nature = q.b_nature AND f.partie_b_id IS NOT DISTINCT FROM q.b_id
    WHERE q.soi_a OR q.soi_b
  ) y;
  RETURN v_resultat;
END;
$function$;

-- Ouvre (cree s'il manque) le fil de la paire (objet, interlocuteur).
-- [p_interlocuteur] : 'administration', l'identifiant d'un profil ou d'un
-- foyer. Il est confronte aux paires recalculees : il n'accorde rien.
CREATE FUNCTION public.com_ouvrir_conversation(p_type text, p_objet_id uuid, p_interlocuteur text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  q record;
  v_fil uuid;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_objet_id IS NULL OR p_interlocuteur IS NULL THEN RETURN NULL; END IF;
  SELECT p.* INTO q
  FROM private.com_paires(p_type, p_objet_id) p
  WHERE (private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.a_nature, p.a_id)
         AND CASE p.b_nature WHEN 'equipe' THEN p_interlocuteur = 'administration'
                             ELSE p_interlocuteur = p.b_id::text END)
     OR (private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.b_nature, p.b_id)
         AND p_interlocuteur = p.a_id::text)
  ORDER BY p.a_id, p.b_id
  LIMIT 1;
  IF NOT FOUND THEN RETURN NULL; END IF;
  INSERT INTO public.com_fils (type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  VALUES (p_type, p_objet_id, q.a_nature, q.a_id, q.b_nature, q.b_id)
  ON CONFLICT DO NOTHING;
  SELECT f.id INTO v_fil FROM public.com_fils f
  WHERE f.type_objet = p_type AND f.objet_id = p_objet_id
    AND f.partie_a_nature = q.a_nature AND f.partie_a_id = q.a_id
    AND f.partie_b_nature = q.b_nature AND f.partie_b_id IS NOT DISTINCT FROM q.b_id;
  RETURN private.com_fil_json(v_fil, moi.id, moi.role, moi.foyer);
END;
$function$;

-- Le fil canonique d'un objet, seulement s'il n'admet qu'une paire pour
-- l'appelant (C8).
CREATE FUNCTION public.com_fil_pour_objet(p_type text, p_objet_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_n integer;
  v_autre text;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_objet_id IS NULL THEN RETURN NULL; END IF;
  SELECT count(*), min(CASE
           WHEN private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.a_nature, p.a_id)
             THEN coalesce(p.b_id::text, 'administration')
           ELSE p.a_id::text END)
    INTO v_n, v_autre
  FROM private.com_paires(p_type, p_objet_id) p
  WHERE private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.a_nature, p.a_id)
     OR private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, p.b_nature, p.b_id);
  IF v_n <> 1 THEN RETURN NULL; END IF;
  RETURN public.com_ouvrir_conversation(p_type, p_objet_id, v_autre);
END;
$function$;

-- Marque le fil lu jusqu'a maintenant, pour l'appelant seulement.
CREATE FUNCTION public.com_marquer_lu(p_fil_id uuid)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE moi record;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fil_id IS NULL OR private.com_fil_json(p_fil_id, moi.id, moi.role, moi.foyer) IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 fil indisponible' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
  VALUES (p_fil_id, moi.id, pg_catalog.clock_timestamp())
  ON CONFLICT (fil_id, profile_id) DO UPDATE
    SET lu_jusqu_au = greatest(public.com_lectures.lu_jusqu_au, EXCLUDED.lu_jusqu_au);
END;
$function$;

-- Envoie un message ; rend l'accuse du serveur. La cle d'idempotence rejouee
-- rend le meme accuse, sans second message.
CREATE FUNCTION public.com_envoyer_message(p_fil_id uuid, p_texte text, p_cle_idempotence uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_json jsonb;
  v_id uuid;
  v_le timestamptz;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fil_id IS NULL OR p_cle_idempotence IS NULL OR p_texte IS NULL
     OR pg_catalog.btrim(p_texte) = '' OR pg_catalog.length(pg_catalog.btrim(p_texte)) > 5000 THEN
    RAISE EXCEPTION 'COM-BACK-1 message invalide' USING ERRCODE = '22023';
  END IF;
  PERFORM 1 FROM public.com_fils f WHERE f.id = p_fil_id FOR UPDATE;
  v_json := private.com_fil_json(p_fil_id, moi.id, moi.role, moi.foyer);
  IF v_json IS NULL OR NOT coalesce((v_json ->> 'peut_ecrire')::boolean, false) THEN
    RAISE EXCEPTION 'COM-BACK-1 fil indisponible' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)
  VALUES (p_fil_id, moi.id, p_cle_idempotence, pg_catalog.btrim(p_texte))
  ON CONFLICT (fil_id, auteur_id, cle_idempotence) DO NOTHING
  RETURNING id, envoye_le INTO v_id, v_le;
  IF v_id IS NULL THEN
    SELECT m.id, m.envoye_le INTO v_id, v_le FROM public.com_messages m
    WHERE m.fil_id = p_fil_id AND m.auteur_id = moi.id AND m.cle_idempotence = p_cle_idempotence;
  ELSE
    UPDATE public.com_fils SET dernier_message_le = v_le WHERE id = p_fil_id;
    INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
    VALUES (p_fil_id, moi.id, v_le)
    ON CONFLICT (fil_id, profile_id) DO UPDATE
      SET lu_jusqu_au = greatest(public.com_lectures.lu_jusqu_au, EXCLUDED.lu_jusqu_au);
    PERFORM public.log_sensitive_access('com_envoyer_message', 'com_messages', v_id::text, '{}'::jsonb);
  END IF;
  RETURN pg_catalog.jsonb_build_object('id', v_id, 'envoye_le', v_le);
END;
$function$;

DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_lister_fils()',
    'public.com_lire_fil(uuid)',
    'public.com_conversations_pour_objet(text,uuid)',
    'public.com_ouvrir_conversation(text,uuid,text)',
    'public.com_fil_pour_objet(text,uuid)',
    'public.com_marquer_lu(uuid)',
    'public.com_envoyer_message(uuid,text,uuid)'
  ] LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

-- @@F86_DEBUT_MESSAGES@@
COMMENT ON FUNCTION public.com_lister_fils() IS
  'F86: signature=public.com_lister_fils(); md5_functiondef=c30a02ce7bfafa77761fd4e2ac0a501e; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: compte valide non mineur, role du jeton egal au compte; fils dont l appelant est partie.';
COMMENT ON FUNCTION public.com_lire_fil(uuid) IS
  'F86: signature=public.com_lire_fil(uuid); md5_functiondef=0f7f3de20ec477d67b18ba7015d2c329; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: null si absent ou refuse; enseignant sans paire courante refuse (C5).';
COMMENT ON FUNCTION public.com_conversations_pour_objet(text,uuid) IS
  'F86: signature=public.com_conversations_pour_objet(text,uuid); md5_functiondef=e9fbbaba1e89ca304f5f43153de55ebc; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: paires spec 3.2 recalculees; jamais un mineur.';
COMMENT ON FUNCTION public.com_ouvrir_conversation(text,uuid,text) IS
  'F86: signature=public.com_ouvrir_conversation(text,uuid,text); md5_functiondef=ab89fc2996d76cf67ca595cd791db2a0; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: interlocuteur confronte aux paires recalculees; famille-famille, enseignant-enseignant, eleve-eleve absents.';
COMMENT ON FUNCTION public.com_fil_pour_objet(text,uuid) IS
  'F86: signature=public.com_fil_pour_objet(text,uuid); md5_functiondef=8007d713e4738a842b4748e072a6b35f; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: une seule paire pour l appelant, sinon null (C8).';
COMMENT ON FUNCTION public.com_marquer_lu(uuid) IS
  'F86: signature=public.com_marquer_lu(uuid); md5_functiondef=215add8f2dd861e81307bf6935cc4d2b; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: lecture individuelle, fil lisible requis.';
COMMENT ON FUNCTION public.com_envoyer_message(uuid,text,uuid) IS
  'F86: signature=public.com_envoyer_message(uuid,text,uuid); md5_functiondef=cc97e875cb6083a3141a1a7128c73062; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: paire courante requise; texte 1 a 5000; cle idempotente.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
    ('public.com_lister_fils()'::regprocedure, 'c30a02ce7bfafa77761fd4e2ac0a501e'),
    ('public.com_lire_fil(uuid)'::regprocedure, '0f7f3de20ec477d67b18ba7015d2c329'),
    ('public.com_conversations_pour_objet(text,uuid)'::regprocedure, 'e9fbbaba1e89ca304f5f43153de55ebc'),
    ('public.com_ouvrir_conversation(text,uuid,text)'::regprocedure, 'ab89fc2996d76cf67ca595cd791db2a0'),
    ('public.com_fil_pour_objet(text,uuid)'::regprocedure, '8007d713e4738a842b4748e072a6b35f'),
    ('public.com_marquer_lu(uuid)'::regprocedure, '215add8f2dd861e81307bf6935cc4d2b'),
    ('public.com_envoyer_message(uuid,text,uuid)'::regprocedure, 'cc97e875cb6083a3141a1a7128c73062')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'COM-BACK-1 MESSAGES : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_MESSAGES@@

COMMIT;
