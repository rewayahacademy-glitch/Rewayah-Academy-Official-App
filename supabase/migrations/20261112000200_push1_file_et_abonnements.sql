-- PUSH-1 (b), decision du 07/11/2026, qui modifie DECISION-PUSH-2026-11-01 §2
-- (docs/current/DECISION-PUSH-2026-11-01.md, amendement du 07/11) :
--   - le push couvre TOUS les roles qui ont un compte (tuteur, eleve adulte,
--     enseignant, direction, comptable, controleur), JAMAIS un compte enfant ;
--   - par defaut, toute ligne de public.notifications part aussi en push ;
--     seules restent dans l'application les notifications exclues NOMMEMENT,
--     par evenement et par portee, dans la meme table que le drapeau courriel
--     (private.notification_courriel, colonne push) ;
--   - chaque personne coupe le push par categorie dans ses Reglages.
-- DECISION-PUSH §3 : une file push_sortants sur le modele des courriels, des
-- abonnements par appareil sous RLS, une fonction Edge qui signe en VAPID
-- (push-envoi), la cle publique servie par le serveur (push-cle).
--
-- AUCUN mot d'effacement (compte : 0) : un abonnement retire ou mort garde sa
-- ligne, avec retire_le. Sans BEGIN ni COMMIT de premier niveau. Rejouable.
-- A installer APRES 20261112000100.

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.notifier_direction(text,jsonb,text,text,text)') IS NULL THEN
    RAISE EXCEPTION 'PUSH-1 : 20261112000100_push1_notifications_par_role.sql n''est pas installe, arret';
  END IF;
  IF pg_catalog.to_regprocedure('private.notification_avec_courriel(text,text)') IS NULL THEN
    RAISE EXCEPTION 'PUSH-1 : private.notification_avec_courriel absente, arret';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. Le drapeau push, dans la table du drapeau courriel.
--    Lecture : la ligne exacte (evenement, portee), sinon la ligne « * »,
--    sinon OUI (le defaut du 07/11). Une ligne ajoutee ici pour une exclusion
--    recoit le courriel effectif d'avant : le courriel ne change pas.
-- ---------------------------------------------------------------------------
ALTER TABLE private.notification_courriel ADD COLUMN IF NOT EXISTS push boolean;
COMMENT ON COLUMN private.notification_courriel.push IS
  'PUSH-1 (07/11/2026) : false = la notification reste dans l''application ; NULL ou ligne absente = push (defaut). Lue par private.notification_avec_push.';

CREATE OR REPLACE FUNCTION private.notification_avec_push(p_evenement text, p_portee text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT c.push FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = p_portee),
    (SELECT c.push FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = '*'),
    true);
$function$;

-- Les exclusions nommees (proposees par l'agent, a corriger par le garde-cap) :
--   seance_terminee '*'             les presents sortent de la salle, rien a faire ;
--   remplacant_arrive '*'           les presents sont dans la salle (DECISION-PUSH §2) ;
--   titulaire_en_retard '*'         la classe est deja dans la salle ...
--   titulaire_en_retard 'direction' ... mais la direction doit agir : push oui ;
--   creneau_personnalise_demande '*' information sans geste (le quota decide) ;
--   remboursement_demande '*'       information sans geste (l'envoi suit seul).
INSERT INTO private.notification_courriel (evenement, portee, courriel, push)
SELECT v.e, v.p, private.notification_avec_courriel(v.e, v.p), v.push
  FROM (VALUES ('seance_terminee', '*', false),
               ('remplacant_arrive', '*', false),
               ('titulaire_en_retard', '*', false),
               ('titulaire_en_retard', 'direction', true),
               ('creneau_personnalise_demande', '*', false),
               ('remboursement_demande', '*', false)) AS v(e, p, push)
ON CONFLICT (evenement, portee) DO UPDATE SET push = EXCLUDED.push;

-- ---------------------------------------------------------------------------
-- 3. Categories (ce que la personne coupe dans ses Reglages) et etiquette de
--    regroupement (tag : le telephone garde UNE alerte « N nouvelles
--    candidatures a examiner », garde-cap du 07/11). Un evenement absent de
--    la table est dans « classes ».
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS private.push_evenements (
  evenement text PRIMARY KEY,
  categorie text NOT NULL CHECK (categorie IN ('classes', 'remplacements', 'paiements', 'admissions', 'suivi')),
  tag text CHECK (tag IS NULL OR tag ~ '^[a-z_]{3,32}$')
);
ALTER TABLE private.push_evenements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.push_evenements FROM PUBLIC, anon, authenticated, service_role, agent_ro;

INSERT INTO private.push_evenements (evenement, categorie, tag) VALUES
  ('seance_annulee', 'classes', NULL), ('seance_deplacee', 'classes', NULL),
  ('seance_reportee', 'classes', NULL), ('seance_terminee', 'classes', NULL),
  ('enseignante_absente', 'classes', NULL), ('titulaire_en_retard', 'classes', NULL),
  ('remplacant_arrive', 'classes', NULL), ('creneau_change', 'classes', NULL),
  ('classe_validee', 'classes', NULL), ('classe_creee', 'classes', NULL),
  ('classe_changee', 'classes', NULL), ('classe_supprimee', 'classes', NULL),
  ('enseignant_affecte', 'classes', NULL), ('enseignant_change', 'classes', NULL),
  ('eleve_inscrit', 'classes', NULL), ('eleve_retire', 'classes', NULL),
  ('cahier_en_retard', 'classes', NULL),
  ('remplacement_propose', 'remplacements', NULL), ('remplacement_pris', 'remplacements', NULL),
  ('remplacement_pre_alerte', 'remplacements', NULL),
  ('remplacement_avertissement', 'remplacements', NULL),
  ('remplacement_inutile', 'remplacements', NULL),
  ('remplacement_personne_en_salle', 'remplacements', NULL),
  ('paiement_relance', 'paiements', NULL), ('acces_suspendu_paiement', 'paiements', NULL),
  ('acces_retabli_paiement', 'paiements', NULL), ('paiement_recu', 'paiements', NULL),
  ('paiement_echoue', 'paiements', NULL), ('remboursement_effectue', 'paiements', NULL),
  ('remboursement_demande', 'paiements', NULL), ('remboursement_echec', 'paiements', NULL),
  ('litige_ouvert', 'paiements', NULL), ('litige_clos', 'paiements', NULL),
  ('versement_coordonnees_a_valider', 'paiements', NULL),
  ('versement_coordonnees_validees', 'paiements', NULL),
  ('demande_recue', 'admissions', NULL), ('demande_close', 'admissions', NULL),
  ('demande_presentation', 'admissions', NULL),
  ('admission_recue', 'admissions', 'candidatures'),
  ('candidature_enseignant_a_examiner', 'admissions', 'candidatures'),
  ('demande_horaire_recue', 'admissions', 'candidatures'),
  ('creneau_personnalise_demande', 'admissions', NULL),
  ('piece_identite_deposee', 'admissions', 'pieces'),
  ('suppression_compte_demandee', 'admissions', NULL),
  ('signalement_eleve_recu', 'suivi', NULL), ('message_academie_eleve', 'suivi', NULL),
  ('controle_mission_attribuee', 'suivi', NULL), ('controle_mission_non_controlee', 'suivi', NULL)
ON CONFLICT (evenement) DO UPDATE SET categorie = EXCLUDED.categorie, tag = EXCLUDED.tag;

-- ---------------------------------------------------------------------------
-- 4. Qui peut recevoir un push : un compte valide d'un role qui a un compte,
--    jamais un compte enfant (eleve dont le profil est « minor », ou eleve
--    sans profil autonome).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push_compte_autorise(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = p_profil
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND (p.role IN ('admin', 'accountant', 'controller', 'teacher', 'guardian')
            OR (p.role = 'student'
                AND EXISTS (SELECT 1 FROM public.student_profiles sp
                             WHERE sp.profile_id = p.id AND sp.deleted_at IS NULL
                               AND sp.student_type = 'autonomous')
                AND NOT EXISTS (SELECT 1 FROM public.student_profiles sp
                                 WHERE sp.profile_id = p.id AND sp.deleted_at IS NULL
                                   AND sp.student_type = 'minor'))));
$function$;

-- ---------------------------------------------------------------------------
-- 5. Abonnements (un par appareil) et preferences (par categorie), sous RLS :
--    chacun ne lit que les siens ; toute ecriture passe par les RPC.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.abonnements_push (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  endpoint text NOT NULL UNIQUE
    CHECK (endpoint ~ '^https://[^\s]+$' AND pg_catalog.char_length(endpoint) <= 2048),
  p256dh text NOT NULL CHECK (p256dh ~ '^[A-Za-z0-9_-]{80,100}$'),
  auth text NOT NULL CHECK (auth ~ '^[A-Za-z0-9_-]{16,32}$'),
  appareil text CHECK (pg_catalog.char_length(appareil) <= 120),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  vu_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  retire_le timestamptz,
  motif_retrait text CHECK (motif_retrait IS NULL OR motif_retrait IN ('personne', 'expire', 'autre_compte'))
);
CREATE INDEX IF NOT EXISTS abonnements_push_actifs
  ON public.abonnements_push (profile_id) WHERE retire_le IS NULL;
ALTER TABLE public.abonnements_push ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.abonnements_push FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT (id, appareil, cree_le, vu_le, retire_le) ON public.abonnements_push TO authenticated;
DO $policy$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'abonnements_push'
                    AND policyname = 'abonnements_push_les_miens') THEN
    CREATE POLICY abonnements_push_les_miens ON public.abonnements_push
      FOR SELECT TO authenticated
      USING (profile_id = auth.uid() AND retire_le IS NULL);
  END IF;
END;
$policy$;
COMMENT ON TABLE public.abonnements_push IS
  'PUSH-1 (07/11/2026) : un abonnement Web Push par appareil. Lecture : les siens (RLS), sans les cles. Ecriture : push_inscrire / push_desinscrire / push_consigner. Un abonnement mort (404, 410) ou retire garde sa ligne (retire_le).';

CREATE TABLE IF NOT EXISTS public.push_preferences (
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  categorie text NOT NULL CHECK (categorie IN ('classes', 'remplacements', 'paiements', 'admissions', 'suivi')),
  actif boolean NOT NULL,
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (profile_id, categorie)
);
ALTER TABLE public.push_preferences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_preferences FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.push_preferences TO authenticated;
DO $policy$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'push_preferences'
                    AND policyname = 'push_preferences_les_miennes') THEN
    CREATE POLICY push_preferences_les_miennes ON public.push_preferences
      FOR SELECT TO authenticated USING (profile_id = auth.uid());
  END IF;
END;
$policy$;

-- ---------------------------------------------------------------------------
-- 6. La file, sur le modele de courriels_sortants (20261023120000) : un push
--    qui echoue ne bloque jamais l'ecriture de la notification ni le courriel.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_sortants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id uuid NOT NULL UNIQUE REFERENCES public.notifications(id) ON DELETE CASCADE,
  destinataire uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  evenement text NOT NULL,
  portee text,
  destination text NOT NULL,
  tag text,
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'envoi', 'envoye', 'echec', 'sans_appareil')),
  tentatives integer NOT NULL DEFAULT 0 CHECK (tentatives BETWEEN 0 AND 10),
  prochaine_tentative timestamptz NOT NULL DEFAULT pg_catalog.now(),
  reserve_le timestamptz,
  derniere_erreur text CHECK (pg_catalog.char_length(derniere_erreur) <= 300),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  envoye_le timestamptz,
  CHECK ((statut = 'envoye') = (envoye_le IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS push_sortants_a_envoyer
  ON public.push_sortants (prochaine_tentative) WHERE statut IN ('en_attente', 'envoi');
ALTER TABLE public.push_sortants ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_sortants FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le declencheur : drapeau push, compte autorise, categorie ouverte, au
-- moins un appareil. Toute erreur va au journal (correction 1 du garde-cap).
CREATE OR REPLACE FUNCTION private.push_depuis_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_categorie text;
  v_tag text;
BEGIN
  BEGIN
    IF NOT private.notification_avec_push(NEW.evenement, NEW.params ->> 'portee')
       OR NOT private.push_compte_autorise(NEW.destinataire) THEN
      RETURN NULL;
    END IF;
    SELECT e.categorie, e.tag INTO v_categorie, v_tag
      FROM private.push_evenements e WHERE e.evenement = NEW.evenement;
    v_categorie := coalesce(v_categorie, 'classes');
    IF EXISTS (SELECT 1 FROM public.push_preferences pp
                WHERE pp.profile_id = NEW.destinataire AND pp.categorie = v_categorie
                  AND NOT pp.actif)
       OR NOT EXISTS (SELECT 1 FROM public.abonnements_push a
                       WHERE a.profile_id = NEW.destinataire AND a.retire_le IS NULL) THEN
      RETURN NULL;
    END IF;
    INSERT INTO public.push_sortants (notification_id, destinataire, evenement, portee, destination, tag)
    VALUES (NEW.id, NEW.destinataire, NEW.evenement, NEW.params ->> 'portee', NEW.destination, v_tag)
    ON CONFLICT (notification_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('push:' || NEW.evenement, NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE TRIGGER push_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION private.push_depuis_notification();

-- ---------------------------------------------------------------------------
-- 7. Les RPC de la personne (authenticated)
-- ---------------------------------------------------------------------------

-- S'abonner depuis cet appareil. Un appareil deja inscrit sous un autre
-- compte (meme navigateur, autre personne connectee) passe au compte courant.
CREATE OR REPLACE FUNCTION public.push_inscrire(
  p_endpoint text, p_p256dh text, p_auth text, p_appareil text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND private.push_compte_autorise(v_uid), false) THEN
    RAISE EXCEPTION 'notifications sur l''appareil reservees aux comptes adultes actifs'
      USING ERRCODE = '42501';
  END IF;
  IF p_endpoint IS NULL OR p_endpoint !~ '^https://[^\s]+$' OR pg_catalog.char_length(p_endpoint) > 2048
     OR p_p256dh IS NULL OR p_p256dh !~ '^[A-Za-z0-9_-]{80,100}$'
     OR p_auth IS NULL OR p_auth !~ '^[A-Za-z0-9_-]{16,32}$' THEN
    RAISE EXCEPTION 'abonnement illisible' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.abonnements_push AS a (profile_id, endpoint, p256dh, auth, appareil)
  VALUES (v_uid, p_endpoint, p_p256dh, p_auth, pg_catalog.left(nullif(pg_catalog.btrim(p_appareil), ''), 120))
  ON CONFLICT (endpoint) DO UPDATE
     SET profile_id = v_uid, p256dh = EXCLUDED.p256dh, auth = EXCLUDED.auth,
         appareil = EXCLUDED.appareil, vu_le = pg_catalog.now(),
         retire_le = NULL, motif_retrait = NULL
  RETURNING a.id INTO v_id;
  RETURN v_id;
END;
$function$;

-- Se desabonner depuis cet appareil (la ligne reste, retiree).
CREATE OR REPLACE FUNCTION public.push_desinscrire(p_endpoint text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501';
  END IF;
  UPDATE public.abonnements_push a
     SET retire_le = pg_catalog.now(), motif_retrait = 'personne'
   WHERE a.endpoint = p_endpoint AND a.profile_id = auth.uid() AND a.retire_le IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$function$;

-- Les Reglages : le compte peut-il recevoir des notifications sur l'appareil,
-- cet appareil est-il inscrit, et les cinq categories avec leur etat.
CREATE OR REPLACE FUNCTION public.push_mes_reglages(p_endpoint text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'autorise', private.push_compte_autorise(v_uid),
    'cetAppareil', p_endpoint IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.abonnements_push a
       WHERE a.endpoint = p_endpoint AND a.profile_id = v_uid AND a.retire_le IS NULL),
    'appareils', (SELECT pg_catalog.count(*) FROM public.abonnements_push a
                   WHERE a.profile_id = v_uid AND a.retire_le IS NULL),
    'categories', (
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'code', c.code,
               'actif', coalesce((SELECT pp.actif FROM public.push_preferences pp
                                   WHERE pp.profile_id = v_uid AND pp.categorie = c.code), true))
               ORDER BY c.rang)
        FROM (VALUES ('classes', 1), ('remplacements', 2), ('paiements', 3),
                     ('admissions', 4), ('suivi', 5)) AS c(code, rang)));
END;
$function$;

CREATE OR REPLACE FUNCTION public.push_regler_categorie(p_categorie text, p_actif boolean)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND private.push_compte_autorise(v_uid), false) THEN
    RAISE EXCEPTION 'reglages reserves aux comptes adultes actifs' USING ERRCODE = '42501';
  END IF;
  IF p_categorie IS NULL OR p_actif IS NULL
     OR p_categorie NOT IN ('classes', 'remplacements', 'paiements', 'admissions', 'suivi') THEN
    RAISE EXCEPTION 'categorie inconnue' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.push_preferences (profile_id, categorie, actif)
  VALUES (v_uid, p_categorie, p_actif)
  ON CONFLICT (profile_id, categorie) DO UPDATE SET actif = EXCLUDED.actif, maj_le = pg_catalog.now();
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. Le travailleur (fonction Edge push-envoi, cle de service)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.push_reserver(p_lot integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[];
BEGIN
  -- Plus d'appareil actif : la ligne sort de la file, sans envoi.
  UPDATE public.push_sortants s
     SET statut = 'sans_appareil'
   WHERE s.statut = 'en_attente'
     AND NOT EXISTS (SELECT 1 FROM public.abonnements_push a
                      WHERE a.profile_id = s.destinataire AND a.retire_le IS NULL);

  WITH choisis AS (
    SELECT s.id FROM public.push_sortants s
     WHERE (s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
        OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes')
     ORDER BY s.prochaine_tentative
     LIMIT LEAST(GREATEST(coalesce(p_lot, 20), 1), 100)
     FOR UPDATE SKIP LOCKED
  ), pris AS (
    UPDATE public.push_sortants s
       SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
      FROM choisis WHERE s.id = choisis.id
    RETURNING s.id
  )
  SELECT pg_catalog.array_agg(pris.id) INTO v_ids FROM pris;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', s.id,
             'evenement', s.evenement,
             'portee', s.portee,
             'destination', s.destination,
             'tag', s.tag,
             'langue', coalesce(pr.langue_communication, 'fr'),
             -- Le nombre d'alertes ouvertes sous la meme etiquette.
             'nombre', CASE WHEN s.tag IS NULL THEN 1 ELSE GREATEST(1, (
               SELECT pg_catalog.count(*)::integer FROM public.notifications n
                 JOIN private.push_evenements e ON e.evenement = n.evenement
                WHERE n.destinataire = s.destinataire AND e.tag = s.tag
                  AND n.geste_requis AND n.geste_fait_le IS NULL AND n.ecartee_le IS NULL)) END,
             'abonnements', (
               SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                        'id', a.id, 'endpoint', a.endpoint, 'p256dh', a.p256dh, 'auth', a.auth)),
                      '[]'::jsonb)
                 FROM public.abonnements_push a
                WHERE a.profile_id = s.destinataire AND a.retire_le IS NULL))
             ORDER BY s.prochaine_tentative)
      FROM public.push_sortants s
      JOIN public.profiles pr ON pr.id = s.destinataire
     WHERE s.id = ANY (v_ids)), '[]'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.push_consigner(
  p_id uuid, p_ok boolean, p_erreur text, p_abonnements_morts uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Un abonnement mort (404, 410) est retire, seulement s'il appartient au
  -- destinataire de cette ligne.
  UPDATE public.abonnements_push a
     SET retire_le = pg_catalog.now(), motif_retrait = 'expire'
    FROM public.push_sortants s
   WHERE s.id = p_id AND a.profile_id = s.destinataire
     AND a.id = ANY (coalesce(p_abonnements_morts, '{}'::uuid[]))
     AND a.retire_le IS NULL;
  IF p_ok THEN
    UPDATE public.push_sortants
       SET statut = 'envoye', envoye_le = pg_catalog.now(), derniere_erreur = NULL
     WHERE id = p_id AND statut = 'envoi';
  ELSE
    -- Nouvel essai a 1, 4, 9, 16 minutes ; au cinquieme echec, on arrete.
    UPDATE public.push_sortants
       SET statut = CASE WHEN tentatives >= 5 THEN 'echec' ELSE 'en_attente' END,
           prochaine_tentative = pg_catalog.now() + pg_catalog.make_interval(mins => tentatives * tentatives),
           derniere_erreur = pg_catalog.left(p_erreur, 300)
     WHERE id = p_id AND statut = 'envoi';
  END IF;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 9. Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
  v_personne regprocedure[] := ARRAY[
    'public.push_inscrire(text,text,text,text)'::regprocedure,
    'public.push_desinscrire(text)'::regprocedure,
    'public.push_mes_reglages(text)'::regprocedure,
    'public.push_regler_categorie(text,boolean)'::regprocedure];
  v_service regprocedure[] := ARRAY[
    'public.push_reserver(integer)'::regprocedure,
    'public.push_consigner(uuid,boolean,text,uuid[])'::regprocedure];
  v_interne regprocedure[] := ARRAY[
    'private.notification_avec_push(text,text)'::regprocedure,
    'private.push_compte_autorise(uuid)'::regprocedure,
    'private.push_depuis_notification()'::regprocedure];
BEGIN
  FOREACH v_oid IN ARRAY v_personne || v_service || v_interne LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY v_personne LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY v_service LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_oid);
  END LOOP;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 10. Planification : appel de push-envoi chaque minute, seulement s'il y a
--     quelque chose a envoyer. Aucun secret nouveau : l'adresse se deduit de
--     celle de courriels-envoi et la porte reutilise courriels_envoi_secret
--     (Vault), comme la fonction Edge. Sur un Postgres nu (CI), sans effet.
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_net')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'vault') THEN
    PERFORM cron.schedule('push-envoi', '* * * * *', $cron$
      SELECT net.http_post(
        url := pg_catalog.replace(
          (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url'),
          '/courriels-envoi', '/push-envoi'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-courriels-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret')),
        body := '{}'::jsonb)
      WHERE EXISTS (SELECT 1 FROM public.push_sortants
                     WHERE statut IN ('en_attente', 'envoi') AND prochaine_tentative <= pg_catalog.now())
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url');
    $cron$);
  END IF;
END;
$planification$;

-- ---------------------------------------------------------------------------
-- 11. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.push_inscrire(text,text,text,text)'::regprocedure,
    'public.push_desinscrire(text)'::regprocedure,
    'public.push_mes_reglages(text)'::regprocedure,
    'public.push_regler_categorie(text,boolean)'::regprocedure,
    'public.push_reserver(integer)'::regprocedure,
    'public.push_consigner(uuid,boolean,text,uuid[])'::regprocedure,
    'private.notification_avec_push(text,text)'::regprocedure,
    'private.push_compte_autorise(uuid)'::regprocedure]
  LOOP
    IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PUSH-1 : anon peut executer %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'public.push_reserver(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.push_consigner(uuid,boolean,text,uuid[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.push_reserver(integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.push_inscrire(text,text,text,text)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.push_sortants', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.abonnements_push', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.abonnements_push', 'INSERT')
     OR pg_catalog.has_column_privilege('authenticated', 'public.abonnements_push', 'auth', 'SELECT')
     OR pg_catalog.has_column_privilege('authenticated', 'public.abonnements_push', 'endpoint', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.push_preferences', 'INSERT') THEN
    RAISE EXCEPTION 'PUSH-1 : droits inattendus sur la file ou les abonnements';
  END IF;
  IF private.notification_avec_push('seance_terminee', NULL)
     OR private.notification_avec_push('titulaire_en_retard', 'classe')
     OR NOT private.notification_avec_push('titulaire_en_retard', 'direction')
     OR NOT private.notification_avec_push('admission_recue', 'direction')
     OR NOT private.notification_avec_push('seance_annulee', 'foyer') THEN
    RAISE EXCEPTION 'PUSH-1 : drapeau push inattendu';
  END IF;
END;
$postflight$;
