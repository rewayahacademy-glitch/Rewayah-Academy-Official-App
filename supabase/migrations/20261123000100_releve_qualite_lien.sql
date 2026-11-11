-- ############################################################################
-- ##  BROUILLON. NE PAS INSTALLER avant :                                    ##
-- ##    (1) la phrase d'information affichee dans l'application ;            ##
-- ##    (2) la relecture d'un juriste (§10 du dossier                        ##
-- ##        docs/current/salle/DROIT-RELEVE-QUALITE.md).                     ##
-- ##  Installer cette migration commence la collecte le jour meme.           ##
-- ############################################################################
--
-- RESEAU-PREUVE (directeur, 11/11/2026 ; cahier de la salle §6, defaut R-2) :
-- le releve de la qualite de connexion de chaque participant d'une seance,
-- garde comme preuve pendant DEUX ANS (730 jours), lu par la direction seule.
--
-- Ce fichier n'est installe nulle part (ni production, ni base de test, ni
-- pile locale partagee). Il a ete rejoue sur un Postgres nu a part, comme la
-- CI, avec `supabase/tests/scenarios_releve_qualite.sql`.
--
-- FICHIER A MOT D'EFFACEMENT (compte : 1, dans la fonction de purge ; aucun
-- autre) : PAGE COLLEE PAR LE DIRECTEUR (`docs/orchestration/LECONS-MIGRATIONS-STAGING.md`).
-- Un seul fichier, et c'est voulu : la table ne doit jamais exister sans sa
-- purge (la loi borne la duree, `docs/current/salle/DROIT-RELEVE-QUALITE.md` §4).
-- Sans BEGIN ni COMMIT de premier niveau.
--
-- Decisions : `docs/current/salle/JOURNAL-DECISIONS.md` D-004 (proposition),
-- D-024 (ce qui est code). Duree : 180 jours decides le matin du 11/11/2026 ;
-- revue l'apres-midi par le pilote, sur delegation du directeur : deux ans,
-- pour pouvoir retrouver une seance d'il y a un an.
--
-- CE QUI EST GARDE, et rien d'autre (minimisation, RGPD art. 5(1)(c), loi
-- P-39.1 art. 5) : une ligne quand l'etat du lien d'un participant change.
--   session_id   : de quelle seance on parle (la contestation porte sur une seance).
--   profile_id   : de qui est ce lien (l'enseignant ou un eleve ; jamais un observateur).
--   etat         : bon, faible ou perdu. Trois mots, pas une mesure : assez pour
--                  repondre a « a-t-on pu s'entendre ? ».
--   micro_ouvert : au moment du changement, ce participant parlait-il a la classe ?
--                  Un lien faible micro ouvert : on l'entendait peut-etre mal ;
--                  micro ferme : c'est lui qui entendait peut-etre mal.
--   releve_le    : l'heure du SERVEUR (jamais celle de l'appareil).
-- JAMAIS : le son, l'image, l'adresse IP, l'appareil, le navigateur, le lieu,
-- les pertes, la gigue, le debit (la note du serveur de visio les resume deja).
-- Le resume (duree dans chaque etat, nombre de coupures) n'est PAS garde : la
-- lecture le calcule a partir des lignes et des entrees et sorties que le
-- serveur de visio a deja annoncees (`session_events`).
--
-- QUI ECRIT : l'application du participant, par `noter_qualite_lien`. Le
-- serveur de visio ne dit la qualite d'un lien qu'aux applications connectees
-- (message de signalisation) : elle n'est ni dans ses webhooks ni dans la liste
-- des participants que le serveur peut lui demander (verifie dans les
-- definitions du protocole employees par les fonctions Edge, version 1.53.4).
-- La fonction verifie : compte valide ; l'appelant ecrit SA ligne (ou celle
-- d'un eleve de son foyer, quand l'enfant suit le cours depuis le compte de son
-- tuteur) ; le serveur lui a bien delivre un jeton d'enseignant ou d'eleve pour
-- cette seance ; la seance est en cours (60 minutes avant, 60 minutes apres) ;
-- l'etat est un des trois mots ; pas plus d'une ligne toutes les 8 secondes,
-- jamais deux fois le meme etat, 400 lignes au plus par participant et par seance.
--
-- QUI LIT : la direction seule (`releve_qualite_seance`), chaque lecture ecrite
-- au journal d'audit. Ni l'enseignant, ni la famille, ni le controleur, ni la
-- comptabilite. Aucun acces direct a la table (aucune politique, aucun droit).
--
-- LA LECTURE PAR UN PARENT EST PREPAREE, ET FERMEE : `releve_qualite_enfant`
-- (le tuteur, pour un eleve de son foyer : la frise de son enfant, et pour
-- l'enseignant seulement « present » ou « absent », jamais la qualite de son
-- lien) existe et est testee, mais AUCUN role client n'a le droit de l'executer.
-- Elle ne s'ouvre que par une decision datee, apres le juriste
-- (`DROIT-RELEVE-QUALITE.md` §11.10) : une ligne de GRANT, dans une autre migration.
--
-- NON MODIFIABLE : aucune fonction ne modifie une ligne, et un declencheur
-- refuse toute modification, meme par une fonction du serveur.
--
-- DEUX ANS : `private.purger_releve_qualite()`, chaque jour a 03:41 UTC par
-- pg_cron quand elle existe (meme mecanisme que la purge du journal des taches,
-- 20261120200100). Le releve d'une seance part en entier, quand sa derniere
-- ligne a plus de 730 jours.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.releve_qualite_lien') IS NOT NULL THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.app_account_valid()') IS NULL
     OR pg_catalog.to_regprocedure('public.app_role()') IS NULL
     OR pg_catalog.to_regprocedure('public.est_du_foyer(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : une fonction appelee est absente';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM information_schema.columns
       WHERE table_schema = 'public'
         AND (table_name, column_name) IN (
           ('sessions', 'id'), ('sessions', 'started_at'), ('sessions', 'ended_at'), ('sessions', 'deleted_at'),
           ('video_token_grants', 'session_id'), ('video_token_grants', 'profile_id'),
           ('video_token_grants', 'role'), ('video_token_grants', 'emis_le'),
           ('session_events', 'session_id'), ('session_events', 'profile_id'),
           ('session_events', 'event_type'), ('session_events', 'server_ts'),
           ('session_participants', 'session_id'), ('session_participants', 'profile_id'),
           ('session_participants', 'role'))) <> 15 THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : une colonne lue est absente';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La table : un journal en ajout seul
-- ---------------------------------------------------------------------------
CREATE TABLE public.releve_qualite_lien (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id   uuid NOT NULL REFERENCES public.sessions(id),
  profile_id   uuid NOT NULL REFERENCES public.profiles(id),
  etat         text NOT NULL CHECK (etat IN ('bon', 'faible', 'perdu')),
  micro_ouvert boolean NOT NULL,
  releve_le    timestamptz NOT NULL DEFAULT pg_catalog.now()
);
ALTER TABLE public.releve_qualite_lien OWNER TO postgres;

-- La derniere ligne d'un participant (rythme, doublon) et la lecture d'une seance.
CREATE INDEX releve_qualite_lien_dernier_ix
  ON public.releve_qualite_lien (session_id, profile_id, releve_le DESC);

COMMENT ON TABLE public.releve_qualite_lien IS
  'RESEAU-PREUVE (11/11/2026) : l''etat du lien (bon, faible, perdu) de l''enseignant et des eleves '
  'pendant une seance, une ligne par changement, heure du serveur. Donnee personnelle, dont des '
  'enfants : aucun son, aucune image, aucune adresse IP. Ecrite par noter_qualite_lien, lue par la '
  'direction seule (releve_qualite_seance), purgee apres deux ans (private.purger_releve_qualite). '
  'Ajout seul, aucun acces direct.';
COMMENT ON COLUMN public.releve_qualite_lien.etat IS
  'bon, faible ou perdu : la note du serveur de visio, filtree par l''application (3 s tenues).';
COMMENT ON COLUMN public.releve_qualite_lien.micro_ouvert IS
  'Le micro de ce participant etait ouvert au moment du changement.';
COMMENT ON COLUMN public.releve_qualite_lien.releve_le IS
  'Heure du serveur a l''ecriture ; l''heure de l''appareil n''est jamais recue.';

ALTER TABLE public.releve_qualite_lien ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.releve_qualite_lien FROM PUBLIC, anon, authenticated, service_role, agent_ro;
-- Aucune politique : ni lecture ni ecriture directes. Tout passe par les
-- fonctions ci-dessous, qui portent leur garde.

-- Une ligne ecrite ne change plus : c'est ce qui lui donne son poids de preuve.
CREATE FUNCTION private.releve_qualite_sans_modification()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'le releve de qualite ne se modifie pas' USING errcode = '42501';
END;
$function$;
REVOKE ALL ON FUNCTION private.releve_qualite_sans_modification() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER releve_qualite_lien_sans_modification
  BEFORE UPDATE ON public.releve_qualite_lien
  FOR EACH ROW EXECUTE FUNCTION private.releve_qualite_sans_modification();

-- ---------------------------------------------------------------------------
-- 2. L'ecriture : chacun sa ligne, pendant la seance, a un rythme borne
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.noter_qualite_lien(
  p_session_id uuid,
  p_profile_id uuid,
  p_etat text,
  p_micro_ouvert boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_role    public.participant_role;
  v_dernier public.releve_qualite_lien;
  v_nombre  integer;
BEGIN
  -- Qui : un compte valide, pour lui-meme ; ou un tuteur pour un eleve de son
  -- foyer (l'enfant suit le cours depuis le compte de son tuteur, D6 du 24/10).
  IF NOT coalesce(
    public.app_account_valid()
    AND p_session_id IS NOT NULL
    AND p_profile_id IS NOT NULL
    AND (
      p_profile_id = auth.uid()
      OR (public.app_role() = 'guardian' AND public.est_du_foyer(p_profile_id))
    ),
    false
  ) THEN
    RAISE EXCEPTION 'releve refuse' USING errcode = '42501';
  END IF;

  -- Participant : le serveur a delivre a cette personne un jeton pour cette
  -- seance (`video_token_grants`, ecrit par `autoriser_jeton_video` seule). On
  -- ne garde que ceux qui parlent : l'enseignant et les eleves. Un observateur
  -- (tuteur, controleur, direction) n'a pas de ligne. Par le chemin du tuteur,
  -- seule une ligne d'eleve peut s'ecrire.
  SELECT g.role INTO v_role
    FROM public.video_token_grants g
   WHERE g.session_id = p_session_id
     AND g.profile_id = p_profile_id
   ORDER BY g.emis_le DESC, g.id DESC
   LIMIT 1;
  IF NOT coalesce(
    v_role = 'student' OR (v_role = 'teacher' AND p_profile_id = auth.uid()),
    false
  ) THEN
    RAISE EXCEPTION 'releve refuse' USING errcode = '42501';
  END IF;

  -- Pendant la seance seulement (meme fenetre que la page presentee, CAHIER-C1).
  IF NOT EXISTS (
    SELECT 1 FROM public.sessions s
     WHERE s.id = p_session_id
       AND s.deleted_at IS NULL
       AND pg_catalog.now() BETWEEN s.started_at - interval '60 minutes'
                                AND s.ended_at + interval '60 minutes'
  ) THEN
    RAISE EXCEPTION 'releve hors de la seance' USING errcode = '42501';
  END IF;

  -- Tout ce qui n'est pas un etat prevu est ignore, sans erreur et sans ligne.
  IF p_micro_ouvert IS NULL OR p_etat IS NULL
     OR NOT (p_etat = ANY (ARRAY['bon', 'faible', 'perdu'])) THEN
    RETURN false;
  END IF;

  -- Un seul ecrivain a la fois pour ce participant dans cette seance : deux
  -- appels simultanes ne passent pas ensemble sous le rythme.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('releve_qualite:' || p_session_id::text || ':' || p_profile_id::text, 0));

  SELECT r.* INTO v_dernier
    FROM public.releve_qualite_lien r
   WHERE r.session_id = p_session_id
     AND r.profile_id = p_profile_id
   ORDER BY r.releve_le DESC, r.id DESC
   LIMIT 1;
  IF FOUND THEN
    -- Rythme : pas plus d'une ligne toutes les 8 secondes (l'application en
    -- envoie au plus une toutes les 10 secondes).
    IF pg_catalog.now() - v_dernier.releve_le < interval '8 seconds' THEN
      RETURN false;
    END IF;
    -- Rien n'a change : meme etat. Le micro ne compte que si le lien n'est pas
    -- bon (on ne garde pas la trace des prises de parole sur un bon lien).
    IF v_dernier.etat = p_etat
       AND (p_etat = 'bon' OR v_dernier.micro_ouvert = p_micro_ouvert) THEN
      RETURN false;
    END IF;
  END IF;

  -- Plafond : 400 lignes par participant et par seance. Au-dela, plus rien ne
  -- s'ecrit ; la lecture montre le nombre de lignes, donc le plafond atteint.
  SELECT pg_catalog.count(*)::integer INTO v_nombre
    FROM public.releve_qualite_lien r
   WHERE r.session_id = p_session_id
     AND r.profile_id = p_profile_id;
  IF v_nombre >= 400 THEN
    RETURN false;
  END IF;

  INSERT INTO public.releve_qualite_lien (session_id, profile_id, etat, micro_ouvert, releve_le)
  VALUES (p_session_id, p_profile_id, p_etat, p_micro_ouvert, pg_catalog.now());
  RETURN true;
END;
$function$;
ALTER FUNCTION public.noter_qualite_lien(uuid, uuid, text, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.noter_qualite_lien(uuid, uuid, text, boolean)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.noter_qualite_lien(uuid, uuid, text, boolean) TO authenticated;

COMMENT ON FUNCTION public.noter_qualite_lien(uuid, uuid, text, boolean) IS
  'RESEAU-PREUVE (11/11/2026) : ecrit une ligne du releve de qualite (bon, faible, perdu ; micro '
  'ouvert ou non) pour le participant lui-meme, ou pour un eleve du foyer du tuteur appelant. '
  'Exige un jeton video d''enseignant ou d''eleve delivre pour la seance et la fenetre de la seance '
  '(42501 sinon). Rend false sans rien ecrire : etat inconnu, moins de 8 s depuis la derniere ligne, '
  'etat inchange, 400 lignes atteintes. Heure du serveur.';

-- ---------------------------------------------------------------------------
-- 3. La frise d'une seance : une seule requete, sans garde, sans droit client
-- ---------------------------------------------------------------------------
-- Une ligne par evenement, dans l'ordre : les changements d'etat ecrits par
-- les appareils, et les entrees et sorties que le serveur de visio a annoncees
-- (`session_events`, deja la) pour les memes personnes. `etat_courant` est
-- l'etat en vigueur a partir de cette ligne (absent apres une sortie, inconnu
-- avant le premier releve), `duree_secondes` le temps jusqu'a la ligne suivante
-- de la meme personne (ou jusqu'a la fin prevue de la seance). Le resume se
-- calcule de la : somme des durees par etat, nombre de sorties.
-- Les deux lectures ci-dessous l'appellent ; chacune porte sa garde et sa trace.
CREATE FUNCTION private.releve_qualite_frise(p_session_id uuid)
RETURNS TABLE (
  profile_id uuid,
  role_seance text,
  instant timestamp with time zone,
  evenement text,
  micro_ouvert boolean,
  source text,
  etat_courant text,
  duree_secondes integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH lignes AS (
    SELECT r.profile_id AS qui, r.releve_le AS quand, r.etat AS quoi,
           r.micro_ouvert AS micro, 'appareil'::text AS origine, r.id AS rang
      FROM public.releve_qualite_lien r
     WHERE r.session_id = p_session_id
  ),
  presences AS (
    SELECT e.profile_id AS qui, e.server_ts AS quand,
           CASE WHEN e.event_type = 'joined' THEN 'entree' ELSE 'sortie' END AS quoi,
           NULL::boolean AS micro, 'serveur'::text AS origine, e.id AS rang
      FROM public.session_events e
     WHERE e.session_id = p_session_id
       AND e.event_type IN ('joined', 'left')
       AND e.profile_id IN (SELECT l.qui FROM lignes l)
  ),
  tout AS (
    SELECT * FROM lignes
    UNION ALL
    SELECT * FROM presences
  ),
  numerote AS (
    -- A la meme seconde, l'entree annoncee par le serveur passe avant l'etat.
    SELECT t.*,
           pg_catalog.count(*) FILTER (WHERE t.origine = 'appareil')
             OVER (PARTITION BY t.qui ORDER BY t.quand, t.origine DESC, t.rang) AS groupe,
           pg_catalog.lead(t.quand)
             OVER (PARTITION BY t.qui ORDER BY t.quand, t.origine DESC, t.rang) AS suivant
      FROM tout t
  ),
  avec_etat AS (
    SELECT n.*,
           pg_catalog.max(n.quoi) FILTER (WHERE n.origine = 'appareil')
             OVER (PARTITION BY n.qui, n.groupe) AS dernier_etat
      FROM numerote n
  )
  SELECT a.qui,
         (SELECT g.role::text
            FROM public.video_token_grants g
           WHERE g.session_id = p_session_id AND g.profile_id = a.qui
           ORDER BY g.emis_le DESC, g.id DESC
           LIMIT 1),
         a.quand,
         a.quoi,
         a.micro,
         a.origine,
         CASE WHEN a.quoi = 'sortie' THEN 'absent' ELSE coalesce(a.dernier_etat, 'inconnu') END,
         CASE
           WHEN a.suivant IS NOT NULL THEN
             greatest(0, pg_catalog.floor(extract(epoch FROM (a.suivant - a.quand))))::integer
           WHEN a.quoi = 'sortie' THEN NULL
           ELSE greatest(0, pg_catalog.floor(extract(epoch FROM (
                  least(pg_catalog.now(), greatest(coalesce(s.ended_at, pg_catalog.now()), a.quand))
                  - a.quand))))::integer
         END
    FROM avec_etat a
    LEFT JOIN public.sessions s ON s.id = p_session_id
   ORDER BY a.quand, a.qui, a.origine DESC, a.rang
$function$;
ALTER FUNCTION private.releve_qualite_frise(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.releve_qualite_frise(uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION private.releve_qualite_frise(uuid) IS
  'RESEAU-PREUVE (11/11/2026) : la frise du releve de qualite d''une seance (changements d''etat, '
  'entrees et sorties, etat en vigueur et sa duree). Sans garde : aucun EXECUTE client ; appelee par '
  'releve_qualite_seance (direction) et releve_qualite_enfant (tuteur, fermee).';

-- ---------------------------------------------------------------------------
-- 4. La lecture de la direction, chaque lecture au journal d'audit
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.releve_qualite_seance(p_session_id uuid)
RETURNS TABLE (
  profile_id uuid,
  role_seance text,
  instant timestamp with time zone,
  evenement text,
  micro_ouvert boolean,
  source text,
  etat_courant text,
  duree_secondes integer
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'lecture du releve reservee a la direction' USING errcode = '42501';
  END IF;
  IF p_session_id IS NULL THEN
    RETURN;
  END IF;

  -- Tracabilite des acces (CNIL, guide des durees : archive a acces restreint).
  PERFORM public.log_sensitive_access(
    'lecture_releve_qualite', 'releve_qualite_lien', p_session_id::text, '{}'::jsonb);

  RETURN QUERY SELECT f.* FROM private.releve_qualite_frise(p_session_id) f;
END;
$function$;
ALTER FUNCTION public.releve_qualite_seance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.releve_qualite_seance(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.releve_qualite_seance(uuid) TO authenticated;

COMMENT ON FUNCTION public.releve_qualite_seance(uuid) IS
  'RESEAU-PREUVE (11/11/2026) : le releve de qualite d''une seance, pour la direction seule (42501 '
  'sinon). Changements d''etat ecrits par les appareils et entrees et sorties annoncees par le '
  'serveur de visio, dans l''ordre, avec l''etat en vigueur et sa duree. Chaque lecture est ecrite '
  'au journal d''audit (lecture_releve_qualite).';

-- ---------------------------------------------------------------------------
-- 5. La lecture par un parent : PREPAREE, FERMEE (aucun EXECUTE client)
-- ---------------------------------------------------------------------------
-- Demande du directeur (11/11/2026) : « permettre a un parent ou un admin de
-- chercher le rapport d'il y a 1 an pour un eleve un jour precis ». Ce que le
-- parent verrait, au plus sobre (`DROIT-RELEVE-QUALITE.md` §11.10) :
--   * la frise de SON enfant (eleve de son foyer, inscrit a cette seance) ;
--   * pour l'enseignant, seulement ses entrees et ses sorties annoncees par le
--     serveur de visio (present ou absent). JAMAIS l'etat de son lien ni son
--     micro : c'est une donnee de l'enseignant (RGPD art. 15(4)) ;
--   * rien sur les autres eleves.
-- La fonction ne rend aucun identifiant : `qui` vaut 'eleve' ou 'enseignant'.
-- Chaque lecture est ecrite au journal d'audit.
-- FERMEE : aucun role client ne peut l'executer. Elle attend la decision du
-- directeur et la relecture du juriste (droit d'acces direct d'un parent,
-- donnee de presence de l'enseignant montree a une famille, information des
-- enseignants). L'ouvrir = une ligne de GRANT a `authenticated`, par une
-- migration datee.
CREATE FUNCTION public.releve_qualite_enfant(p_session_id uuid, p_eleve_id uuid)
RETURNS TABLE (
  qui text,
  instant timestamp with time zone,
  evenement text,
  micro_ouvert boolean,
  etat_courant text,
  duree_secondes integer
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Le tuteur, compte valide, pour un eleve de SON foyer inscrit a cette seance.
  IF NOT coalesce(
    public.app_account_valid()
    AND public.app_role() = 'guardian'
    AND p_session_id IS NOT NULL
    AND p_eleve_id IS NOT NULL
    AND public.est_du_foyer(p_eleve_id)
    AND EXISTS (
      SELECT 1 FROM public.session_participants sp
       WHERE sp.session_id = p_session_id
         AND sp.profile_id = p_eleve_id
         AND sp.role = 'student'
    ),
    false
  ) THEN
    RAISE EXCEPTION 'lecture du releve refusee' USING errcode = '42501';
  END IF;

  PERFORM public.log_sensitive_access(
    'lecture_releve_qualite_enfant', 'releve_qualite_lien', p_session_id::text,
    pg_catalog.jsonb_build_object('eleve', p_eleve_id));

  RETURN QUERY
  WITH enfant AS (
    SELECT 'eleve'::text AS qui, f.instant, f.evenement, f.micro_ouvert, f.etat_courant, f.duree_secondes
      FROM private.releve_qualite_frise(p_session_id) f
     WHERE f.profile_id = p_eleve_id
  ),
  -- L'enseignant : ceux a qui le serveur a delivre un jeton d'enseignant pour
  -- cette seance (titulaire ou remplacant) ; leurs entrees et sorties seules.
  presence_enseignant AS (
    SELECT e.server_ts AS instant,
           CASE WHEN e.event_type = 'joined' THEN 'entree' ELSE 'sortie' END AS evenement,
           pg_catalog.lead(e.server_ts) OVER (ORDER BY e.server_ts, e.id) AS suivant
      FROM public.session_events e
     WHERE e.session_id = p_session_id
       AND e.event_type IN ('joined', 'left')
       AND e.profile_id IN (
         SELECT g.profile_id FROM public.video_token_grants g
          WHERE g.session_id = p_session_id AND g.role = 'teacher')
  )
  SELECT x.qui, x.instant, x.evenement, x.micro_ouvert, x.etat_courant, x.duree_secondes
    FROM (
      SELECT n.qui, n.instant, n.evenement, n.micro_ouvert, n.etat_courant, n.duree_secondes
        FROM enfant n
      UNION ALL
      SELECT 'enseignant'::text, p.instant, p.evenement, NULL::boolean,
             CASE WHEN p.evenement = 'sortie' THEN 'absent' ELSE 'present' END,
             CASE WHEN p.suivant IS NULL THEN NULL
                  ELSE greatest(0, pg_catalog.floor(extract(epoch FROM (p.suivant - p.instant))))::integer END
        FROM presence_enseignant p
    ) x
   ORDER BY x.instant, x.qui;
END;
$function$;
ALTER FUNCTION public.releve_qualite_enfant(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.releve_qualite_enfant(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION public.releve_qualite_enfant(uuid, uuid) IS
  'RESEAU-PREUVE (11/11/2026) : PREPAREE, FERMEE (aucun EXECUTE client). Pour un tuteur : la frise du '
  'releve de qualite d''un eleve de son foyer dans une seance, et pour l''enseignant seulement ses '
  'entrees et sorties (jamais l''etat de son lien). Lecture ecrite au journal d''audit '
  '(lecture_releve_qualite_enfant). A ouvrir par une migration datee, apres le juriste.';

-- ---------------------------------------------------------------------------
-- 6. La purge : deux ans, 730 jours (pilote, sur delegation du directeur, 11/11/2026)
-- ---------------------------------------------------------------------------
-- Sans parametre, et c'est voulu : la duree est une decision datee, elle ne se
-- change que par une migration. Le releve d'une seance part en entier, des que
-- sa derniere ligne a plus de 730 jours : jamais un releve a moitie purge.
CREATE FUNCTION private.purger_releve_qualite()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  DELETE FROM public.releve_qualite_lien r
   WHERE r.session_id IN (
     SELECT x.session_id
       FROM public.releve_qualite_lien x
      GROUP BY x.session_id
     HAVING pg_catalog.max(x.releve_le) < pg_catalog.now() - interval '730 days'
   );
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;
ALTER FUNCTION private.purger_releve_qualite() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.purger_releve_qualite() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION private.purger_releve_qualite() IS
  'RESEAU-PREUVE (11/11/2026) : purge le releve de qualite des seances dont la derniere ligne a plus '
  'de 730 jours (deux ans ; pilote, sur delegation du directeur, 11/11/2026) ; rend le nombre de '
  'lignes purgees. Lancee une fois par jour par la tache purge-releve-qualite. Aucun EXECUTE client.';

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('purge-releve-qualite', '41 3 * * *',
      'SELECT private.purger_releve_qualite()')$cron$;
  ELSE
    RAISE NOTICE 'purge du releve de qualite : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

DO $postflight$
DECLARE
  v_taches integer;
  v_role text;
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.releve_qualite_lien'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : la securite par ligne n''est pas active';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
              WHERE p.polrelid = 'public.releve_qualite_lien'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : une politique ouvre la table';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.releve_qualite_lien', 'SELECT, INSERT, UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.releve_qualite_lien', 'SELECT, INSERT, UPDATE')
     OR pg_catalog.has_table_privilege('service_role', 'public.releve_qualite_lien', 'SELECT, INSERT, UPDATE')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.releve_qualite_lien', 'SELECT, INSERT, UPDATE') THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : un role client garde un droit sur la table';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.releve_qualite_seance(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.releve_qualite_seance(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.releve_qualite_seance(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'RESEAU-PREUVE : droits d''execution inattendus';
  END IF;
  -- La purge, la frise et la lecture du parent : aucun role client.
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, 'private.purger_releve_qualite()', 'EXECUTE')
       OR pg_catalog.has_function_privilege(v_role, 'private.releve_qualite_frise(uuid)', 'EXECUTE')
       OR pg_catalog.has_function_privilege(v_role, 'public.releve_qualite_enfant(uuid,uuid)', 'EXECUTE') THEN
      RAISE EXCEPTION 'RESEAU-PREUVE : la purge, la frise ou la lecture du parent est executable par %', v_role;
    END IF;
  END LOOP;
  -- Dynamique : sans pg_cron, cron.job n'existe pas et la requete ne se planifie pas.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $q$SELECT pg_catalog.count(*)::integer FROM cron.job j
                 WHERE j.jobname = 'purge-releve-qualite' AND j.active AND j.schedule = '41 3 * * *'$q$
      INTO v_taches;
    IF v_taches <> 1 THEN
      RAISE EXCEPTION 'RESEAU-PREUVE : la purge n''est pas planifiee une fois par jour';
    END IF;
  END IF;
END
$postflight$;
