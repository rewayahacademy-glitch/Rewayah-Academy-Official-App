-- COURRIELS-1 (directeur, 23/10/2026) : l'application envoie ses e-mails.
--
-- Une seule file pour tous les envois, automatiques (evenements metier) ou
-- manuels (direction). Chaque envoi appartient a une categorie, et chaque
-- categorie part de l'alias Google Workspace qui lui est dedie : une reponse
-- de la famille arrive dans la boite qui traite le sujet.
--
-- Ce qui met en file : chaque notification privee (demandes, classes,
-- remplacements, controle, paiements) et chaque invitation au foyer ; la
-- direction, a la main. Ce qui envoie : la fonction Edge `courriels-envoi` reserve un lot
-- (`courriels_reserver`), compose le message, l'envoie, puis consigne le
-- resultat (`courriel_consigner`). Les e-mails d'authentification (lien ou
-- code de connexion) ne passent pas par la file : le hook « Send Email » de
-- Supabase Auth appelle `courriel-auth`, qui envoie tout de suite.
--
-- Ce que la file ne fait jamais : envoyer a un compte enfant (adresse
-- technique), ni une categorie non essentielle a une adresse desinscrite.

-- ------------------------------------------------------------------
-- Categories et alias
-- ------------------------------------------------------------------
CREATE TABLE public.courriel_categories (
  code text PRIMARY KEY CHECK (code ~ '^[a-z_]{3,30}$'),
  libelle text NOT NULL CHECK (pg_catalog.char_length(libelle) BETWEEN 1 AND 80),
  expediteur_adresse text NOT NULL
    CHECK (expediteur_adresse ~ '^[a-z0-9._-]+@rewayahacademy\.com$'),
  expediteur_nom text NOT NULL CHECK (pg_catalog.char_length(expediteur_nom) BETWEEN 1 AND 60),
  repondre_a text NOT NULL
    CHECK (repondre_a ~ '^[a-z0-9._-]+@rewayahacademy\.com$'),
  -- Essentielle : un message lie au service (compte, classe, facture) ; on ne
  -- s'en desinscrit pas. Sinon, chaque message porte un lien de desinscription.
  essentielle boolean NOT NULL DEFAULT true,
  active boolean NOT NULL DEFAULT true,
  modifie_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  modifie_par uuid REFERENCES public.profiles(id)
);

INSERT INTO public.courriel_categories (code, libelle, expediteur_adresse, expediteur_nom, repondre_a, essentielle) VALUES
  ('compte',      'Compte et sécurité',            'support@rewayahacademy.com',     'Rewayah Academy',             'support@rewayahacademy.com',     true),
  ('inscription', 'Demandes et inscriptions',      'contact@rewayahacademy.com',     'Rewayah Academy',             'contact@rewayahacademy.com',     true),
  ('classes',     'Classes et séances',            'support@rewayahacademy.com',     'Rewayah Academy',             'support@rewayahacademy.com',     true),
  ('facturation', 'Facturation',                   'invoice@rewayahacademy.com',     'Rewayah Academy · Facturation', 'invoice@rewayahacademy.com',   true),
  ('recrutement', 'Recrutement',                   'recrutement@rewayahacademy.com', 'Rewayah Academy · Recrutement', 'recrutement@rewayahacademy.com', true),
  ('direction',   'Message de la direction',       'contact@rewayahacademy.com',     'Rewayah Academy',             'contact@rewayahacademy.com',     true),
  ('nouvelles',   'Nouvelles de l''académie',      'contact@rewayahacademy.com',     'Rewayah Academy',             'contact@rewayahacademy.com',     false);

-- ------------------------------------------------------------------
-- La file
-- ------------------------------------------------------------------
CREATE TABLE public.courriels_sortants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  categorie text NOT NULL REFERENCES public.courriel_categories(code),
  modele text NOT NULL CHECK (modele ~ '^[a-z_]{3,40}$'),
  destinataire_adresse text NOT NULL
    CHECK (destinataire_adresse = pg_catalog.lower(pg_catalog.btrim(destinataire_adresse))
           AND destinataire_adresse ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
           AND pg_catalog.char_length(destinataire_adresse) <= 254),
  destinataire_profil uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  donnees jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(donnees) = 'object')
    CHECK (pg_catalog.pg_column_size(donnees) <= 16384),
  origine text NOT NULL CHECK (origine IN ('auto', 'manuel')),
  cree_par uuid REFERENCES public.profiles(id),
  cle_idempotence text UNIQUE CHECK (pg_catalog.char_length(cle_idempotence) <= 120),
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'envoi', 'envoye', 'echec', 'annule')),
  tentatives integer NOT NULL DEFAULT 0 CHECK (tentatives BETWEEN 0 AND 10),
  prochaine_tentative timestamptz NOT NULL DEFAULT pg_catalog.now(),
  reserve_le timestamptz,
  derniere_erreur text CHECK (pg_catalog.char_length(derniere_erreur) <= 300),
  fournisseur_id text CHECK (pg_catalog.char_length(fournisseur_id) <= 200),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  envoye_le timestamptz,
  CHECK ((statut = 'envoye') = (envoye_le IS NOT NULL))
);
CREATE INDEX courriels_sortants_a_envoyer
  ON public.courriels_sortants (prochaine_tentative) WHERE statut IN ('en_attente', 'envoi');
CREATE INDEX courriels_sortants_cree_le ON public.courriels_sortants (cree_le DESC);
CREATE INDEX courriels_sortants_profil ON public.courriels_sortants (destinataire_profil, cree_le DESC);

-- Desinscriptions (categories non essentielles seulement), et les jetons des
-- liens de desinscription : on ne garde que l'empreinte du jeton.
CREATE TABLE public.courriel_desinscriptions (
  adresse text NOT NULL CHECK (adresse = pg_catalog.lower(pg_catalog.btrim(adresse))),
  categorie text NOT NULL REFERENCES public.courriel_categories(code),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (adresse, categorie)
);
CREATE TABLE public.courriel_jetons_desinscription (
  empreinte bytea PRIMARY KEY,
  adresse text NOT NULL,
  categorie text NOT NULL REFERENCES public.courriel_categories(code),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now()
);

DO $tables$
DECLARE
  v_t text;
BEGIN
  FOREACH v_t IN ARRAY ARRAY['courriel_categories', 'courriels_sortants', 'courriel_desinscriptions',
                             'courriel_jetons_desinscription'] LOOP
    EXECUTE pg_catalog.format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_t);
    EXECUTE pg_catalog.format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_t);
  END LOOP;
END;
$tables$;

COMMENT ON TABLE public.courriels_sortants IS
  'COURRIELS-1 : file unique des e-mails, automatiques et manuels ; lue et ecrite seulement par des fonctions DEFINER.';

-- ------------------------------------------------------------------
-- Enfiler (interne : declencheurs et fonctions DEFINER seulement)
-- ------------------------------------------------------------------
CREATE FUNCTION public.courriel_enfiler(
  p_categorie text, p_modele text, p_adresse text, p_profil uuid,
  p_donnees jsonb, p_cle text, p_origine text DEFAULT 'auto', p_auteur uuid DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adresse text := pg_catalog.lower(pg_catalog.btrim(p_adresse));
  v_cat public.courriel_categories%ROWTYPE;
  v_donnees jsonb := coalesce(p_donnees, '{}'::jsonb);
  v_jeton text;
  v_prenom text;
  v_id uuid;
BEGIN
  SELECT * INTO v_cat FROM public.courriel_categories WHERE code = p_categorie;
  IF NOT FOUND OR NOT v_cat.active OR v_adresse IS NULL OR v_adresse = '' THEN
    RETURN NULL;
  END IF;

  IF p_profil IS NOT NULL THEN
    -- Un compte enfant a une adresse technique : on ne lui ecrit jamais.
    IF EXISTS (SELECT 1 FROM auth.users u
                WHERE u.id = p_profil AND u.raw_app_meta_data ? 'child_of') THEN
      RETURN NULL;
    END IF;
    SELECT p.first_name INTO v_prenom FROM public.profiles p WHERE p.id = p_profil;
    IF v_prenom IS NOT NULL AND NOT v_donnees ? 'prenom' THEN
      v_donnees := v_donnees || pg_catalog.jsonb_build_object('prenom', v_prenom);
    END IF;
  END IF;

  IF NOT v_cat.essentielle THEN
    IF EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                WHERE d.adresse = v_adresse AND d.categorie = p_categorie) THEN
      RETURN NULL;
    END IF;
    v_jeton := pg_catalog.translate(
                 pg_catalog.encode(extensions.gen_random_bytes(24), 'base64'), '+/=', '-_');
    INSERT INTO public.courriel_jetons_desinscription (empreinte, adresse, categorie)
    VALUES (extensions.digest(v_jeton, 'sha256'), v_adresse, p_categorie);
    v_donnees := v_donnees || pg_catalog.jsonb_build_object('jeton_desinscription', v_jeton);
  END IF;

  INSERT INTO public.courriels_sortants
    (categorie, modele, destinataire_adresse, destinataire_profil, donnees, origine, cree_par, cle_idempotence)
  VALUES (p_categorie, p_modele, v_adresse, p_profil, v_donnees, p_origine, p_auteur, p_cle)
  ON CONFLICT (cle_idempotence) DO NOTHING
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.courriel_adresse_profil(p_profil uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.lower(u.email) FROM auth.users u WHERE u.id = p_profil;
$function$;

-- ------------------------------------------------------------------
-- Declencheurs metier
-- ------------------------------------------------------------------

-- Notifications privees (CT-BR, puis C29, FAC-F-01) : chaque notification part
-- aussi par e-mail. Les relances de paiement, suspensions et retablissements
-- creent deja une notification : elles passent par ici, sans second chemin.
CREATE FUNCTION public.courriel_depuis_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM public.courriel_enfiler(
    CASE
      WHEN NEW.evenement IN ('paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement')
        THEN 'facturation'
      WHEN NEW.evenement IN ('demande_recue', 'classe_validee', 'demande_close', 'demande_presentation')
        THEN 'inscription'
      ELSE 'classes' END,
    NEW.evenement,
    public.courriel_adresse_profil(NEW.destinataire),
    NEW.destinataire,
    NEW.params || pg_catalog.jsonb_build_object('destination', NEW.destination),
    'notification:' || NEW.id::text);
  RETURN NULL;
END;
$function$;

CREATE TRIGGER courriel_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.courriel_depuis_notification();

-- Invitation d'un adulte au foyer : la file historique 0053 est maintenant
-- videe vers la file commune (elle garde son role de journal).
CREATE FUNCTION public.courriel_depuis_invitation_foyer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_prenom text;
  v_expire timestamptz;
BEGIN
  SELECT p.first_name, i.expire_le INTO v_prenom, v_expire
    FROM public.invitations_foyer i
    JOIN public.profiles p ON p.id = i.invite_par
   WHERE i.id = NEW.invitation_id;
  PERFORM public.courriel_enfiler(
    'compte', 'invitation_foyer', NEW.recipient_email, NULL,
    pg_catalog.jsonb_build_object('invite_par', v_prenom, 'expire_le', v_expire),
    'invitation_foyer:' || NEW.id::text);
  RETURN NULL;
END;
$function$;

CREATE TRIGGER courriel_invitation_foyer
  AFTER INSERT ON public.email_outbox_invitation_foyer
  FOR EACH ROW EXECUTE FUNCTION public.courriel_depuis_invitation_foyer();

-- ------------------------------------------------------------------
-- Envoi manuel et suivi (direction)
-- ------------------------------------------------------------------
CREATE FUNCTION public.admin_courriel_envoyer(
  p_profil uuid, p_adresse text, p_categorie text, p_sujet text, p_corps text, p_cle uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adresse text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_adresse, '')));
  v_sujet text := pg_catalog.btrim(p_sujet);
  v_corps text := pg_catalog.btrim(p_corps);
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle' USING ERRCODE = '22023';
  END IF;
  IF p_profil IS NOT NULL THEN
    v_adresse := public.courriel_adresse_profil(p_profil);
  END IF;
  IF v_adresse IS NULL OR v_adresse !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'adresse' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.courriel_categories c WHERE c.code = p_categorie AND c.active) THEN
    RAISE EXCEPTION 'categorie' USING ERRCODE = '22023';
  END IF;
  IF v_sujet IS NULL OR pg_catalog.char_length(v_sujet) NOT BETWEEN 1 AND 120 THEN
    RAISE EXCEPTION 'sujet' USING ERRCODE = '22023';
  END IF;
  IF v_corps IS NULL OR pg_catalog.char_length(v_corps) NOT BETWEEN 1 AND 5000 THEN
    RAISE EXCEPTION 'corps' USING ERRCODE = '22023';
  END IF;

  v_id := public.courriel_enfiler(
    p_categorie, 'message_libre', v_adresse, p_profil,
    pg_catalog.jsonb_build_object('sujet', v_sujet, 'corps', v_corps),
    'manuel:' || p_cle::text, 'manuel', auth.uid());
  IF v_id IS NULL THEN
    -- Meme cle deja envoyee (double clic) ou adresse exclue (compte enfant,
    -- desinscription) : on rend la ligne existante si elle existe.
    SELECT s.id INTO v_id FROM public.courriels_sortants s WHERE s.cle_idempotence = 'manuel:' || p_cle::text;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'destinataire exclu' USING ERRCODE = '22023';
    END IF;
  END IF;
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.admin_courriels_lister(p_statut text DEFAULT NULL, p_limite integer DEFAULT 100)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(r ORDER BY r.cree_le DESC) FROM (
      SELECT s.id, s.categorie, s.modele, s.destinataire_adresse, s.origine, s.statut,
             s.tentatives, s.derniere_erreur, s.cree_le, s.envoye_le,
             CASE WHEN s.modele = 'message_libre' THEN s.donnees->>'sujet' END AS sujet
        FROM public.courriels_sortants s
       WHERE p_statut IS NULL OR s.statut = p_statut
       ORDER BY s.cree_le DESC
       LIMIT LEAST(GREATEST(coalesce(p_limite, 100), 1), 500)) r), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.admin_courriel_reessayer(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  UPDATE public.courriels_sortants
     SET statut = 'en_attente', tentatives = 0, prochaine_tentative = pg_catalog.now(), derniere_erreur = NULL
   WHERE id = p_id AND statut IN ('echec', 'annule');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'introuvable' USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

CREATE FUNCTION public.admin_courriel_categories()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.to_jsonb(c) - 'modifie_par' ORDER BY c.code)
                     FROM public.courriel_categories c), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.admin_courriel_categorie_regler(
  p_code text, p_expediteur text, p_nom text, p_repondre_a text, p_active boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  UPDATE public.courriel_categories
     SET expediteur_adresse = pg_catalog.lower(pg_catalog.btrim(p_expediteur)),
         expediteur_nom = pg_catalog.btrim(p_nom),
         repondre_a = pg_catalog.lower(pg_catalog.btrim(p_repondre_a)),
         active = coalesce(p_active, active),
         modifie_le = pg_catalog.now(),
         modifie_par = auth.uid()
   WHERE code = p_code;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'introuvable' USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

-- ------------------------------------------------------------------
-- Desinscription (lien dans l'e-mail, page publique ; sans compte)
-- ------------------------------------------------------------------
CREATE FUNCTION public.courriel_desinscrire(p_jeton text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_j public.courriel_jetons_desinscription%ROWTYPE;
BEGIN
  IF p_jeton IS NULL OR pg_catalog.char_length(p_jeton) NOT BETWEEN 20 AND 64 THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  SELECT * INTO v_j FROM public.courriel_jetons_desinscription
   WHERE empreinte = extensions.digest(p_jeton, 'sha256');
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  INSERT INTO public.courriel_desinscriptions (adresse, categorie)
  VALUES (v_j.adresse, v_j.categorie) ON CONFLICT DO NOTHING;
  RETURN pg_catalog.jsonb_build_object('ok', true, 'categorie',
    (SELECT c.libelle FROM public.courriel_categories c WHERE c.code = v_j.categorie));
END;
$function$;

-- ------------------------------------------------------------------
-- Le travailleur (fonction Edge, cle de service)
-- ------------------------------------------------------------------
CREATE FUNCTION public.courriels_reserver(p_lot integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[];
BEGIN
  -- Une ligne restee « envoi » plus de dix minutes (travailleur tombe) redevient
  -- disponible ; l'envoi peut alors partir deux fois, jamais zero.
  WITH choisis AS (
    SELECT s.id FROM public.courriels_sortants s
     WHERE (s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
        OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes')
     ORDER BY s.prochaine_tentative
     LIMIT LEAST(GREATEST(coalesce(p_lot, 20), 1), 100)
     FOR UPDATE SKIP LOCKED
  ), pris AS (
    UPDATE public.courriels_sortants s
       SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
      FROM choisis WHERE s.id = choisis.id
    RETURNING s.id
  )
  SELECT pg_catalog.array_agg(pris.id) INTO v_ids FROM pris;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', p.id, 'modele', p.modele, 'categorie', p.categorie,
             'a', p.destinataire_adresse, 'donnees', p.donnees, 'tentatives', p.tentatives,
             'de', c.expediteur_adresse, 'de_nom', c.expediteur_nom, 'repondre_a', c.repondre_a,
             'essentielle', c.essentielle) ORDER BY p.prochaine_tentative)
      FROM public.courriels_sortants p JOIN public.courriel_categories c ON c.code = p.categorie
     WHERE p.id = ANY (v_ids)), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.courriel_consigner(p_id uuid, p_ok boolean, p_fournisseur_id text, p_erreur text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_ok THEN
    UPDATE public.courriels_sortants
       SET statut = 'envoye', envoye_le = pg_catalog.now(),
           fournisseur_id = pg_catalog.left(p_fournisseur_id, 200), derniere_erreur = NULL
     WHERE id = p_id AND statut = 'envoi';
  ELSE
    -- Nouvel essai a 1, 4, 9, 16 minutes... ; au cinquieme echec, on arrete.
    UPDATE public.courriels_sortants
       SET statut = CASE WHEN tentatives >= 5 THEN 'echec' ELSE 'en_attente' END,
           prochaine_tentative = pg_catalog.now() + pg_catalog.make_interval(mins => tentatives * tentatives),
           derniere_erreur = pg_catalog.left(p_erreur, 300)
     WHERE id = p_id AND statut = 'envoi';
  END IF;
END;
$function$;

-- ------------------------------------------------------------------
-- Droits, liste blanche des fonctions DEFINER
-- ------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
  v_admin regprocedure[] := ARRAY[
    'public.admin_courriel_envoyer(uuid,text,text,text,text,uuid)'::regprocedure,
    'public.admin_courriels_lister(text,integer)'::regprocedure,
    'public.admin_courriel_reessayer(uuid)'::regprocedure,
    'public.admin_courriel_categories()'::regprocedure,
    'public.admin_courriel_categorie_regler(text,text,text,text,boolean)'::regprocedure];
  v_service regprocedure[] := ARRAY[
    'public.courriels_reserver(integer)'::regprocedure,
    'public.courriel_consigner(uuid,boolean,text,text)'::regprocedure];
  v_interne regprocedure[] := ARRAY[
    'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure,
    'public.courriel_adresse_profil(uuid)'::regprocedure,
    'public.courriel_depuis_notification()'::regprocedure,
    'public.courriel_depuis_invitation_foyer()'::regprocedure];
  v_public regprocedure := 'public.courriel_desinscrire(text)'::regprocedure;
  v_garde text;
BEGIN
  FOREACH v_oid IN ARRAY v_admin || v_service || v_interne || ARRAY[v_public] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
    v_garde := CASE
      WHEN v_oid = ANY (v_admin) THEN 'ROLE_POSITIVE_ADMIN'
      WHEN v_oid = ANY (v_service) THEN 'SERVICE_ROLE_ONLY'
      WHEN v_oid = v_public THEN 'PUBLIC_TOKEN_WRITE_VALIDATED'
      ELSE 'INTERNAL_NO_EXECUTE' END;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23. COURRIELS-1.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)), v_garde));
  END LOOP;
  FOREACH v_oid IN ARRAY v_admin LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY v_service LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_oid);
  END LOOP;
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', v_public);
END;
$droits$;

-- ------------------------------------------------------------------
-- Planification : appel de `courriels-envoi` chaque minute.
-- Seulement sur un projet Supabase (pg_cron et pg_net disponibles) ; un
-- Postgres nu (CI) passe. L'URL et la cle viennent du coffre (Vault) :
-- `courriels_envoi_url` et `courriels_envoi_secret`, poses hors depot.
-- ------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'pg_net')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'vault') THEN
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    PERFORM cron.schedule('courriels-envoi', '* * * * *', $cron$
      SELECT net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-courriels-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret')),
        body := '{}'::jsonb)
      WHERE EXISTS (SELECT 1 FROM public.courriels_sortants
                     WHERE statut IN ('en_attente', 'envoi') AND prochaine_tentative <= pg_catalog.now())
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url');
    $cron$);
  END IF;
END;
$planification$;

-- ------------------------------------------------------------------
-- Controle final
-- ------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.courriels_reserver(integer)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.admin_courriel_envoyer(uuid,text,text,text,text,uuid)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('anon', 'public.courriel_desinscrire(text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.courriels_sortants', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.courriel_desinscriptions', 'SELECT') THEN
    RAISE EXCEPTION 'COURRIELS-1 : droits inattendus';
  END IF;
END;
$postflight$;
