-- PX-OAUTH 2b (Pilote Equipe, 17/11/2026) : la partie SQL du serveur d'autorisation de Praxis pour claude.ai. Voir
-- docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md (§3, §4, §6, §11). Le JETON D'ACCES d'une connexion est une CLE PRAXIS ORDINAIRE (usage
-- `chat`, `prx_` + 64 hex, une heure), jamais un jeton Supabase : tout ce que la cle porte deja (interrupteur, plafonds, mineurs, cotes,
-- journal, revocation, emetteur toujours direction active) s'applique tel quel.
--
-- Ce fichier ne contient aucun mot d'effacement, ni BEGIN ni COMMIT seul sur une ligne : l'enveloppe de la page ouvre la transaction.
--
-- Additif :
--   * trois tables PRIVEES (clients DCR, demandes d'autorisation, connexions), RLS active, aucun droit pour les roles de l'API ;
--   * une colonne NULLABLE `praxis_cles.connexion_id` ;
--   * cinq fonctions pour le service_role seul (enregistrer un client, creer une demande, echanger un code, renouveler, savoir si une cle
--     est valide) et deux portes de la direction (lire une demande, la decider), administrateur valide + double verification aal2 ;
--   * UNE retouche par ancrage : direction_praxis_revoquer_cle revoque aussi la connexion d'une cle nee d'une connexion (sinon le
--     renouvellement en referait une). Preflight sur l'empreinte du corps lu AVANT l'ecriture.
-- Aucun jeton n'est jamais journalise ni garde en clair : seules des empreintes (SHA-256) sont stockees ; le code ne sort que dans l'URL
-- de retour rendue au navigateur de la direction ; une erreur d'echange est TOUJOURS `invalid_grant` (aucun oracle).
DO $pre$
BEGIN
  IF md5((SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.direction_praxis_revoquer_cle(uuid,text,uuid)'::regprocedure))
     <> 'de50fd0c8c4849021d266851e004fe35' THEN
    RAISE EXCEPTION 'PX-OAUTH 2b : empreinte inattendue de direction_praxis_revoquer_cle ; rien n''est applique';
  END IF;
END
$pre$;

-- 1. Les tables
CREATE TABLE private.praxis_oauth_clients (
  client_id text PRIMARY KEY CHECK (client_id ~ '^prxc_[0-9a-f]{32}$'),
  nom text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(nom)) BETWEEN 1 AND 80),
  rappels text[] NOT NULL CHECK (pg_catalog.cardinality(rappels) BETWEEN 1 AND 5),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
ALTER TABLE private.praxis_oauth_clients ENABLE ROW LEVEL SECURITY;

CREATE TABLE private.praxis_oauth_connexions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  client_id text NOT NULL REFERENCES private.praxis_oauth_clients (client_id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  refresh_empreinte text NOT NULL UNIQUE CHECK (refresh_empreinte ~ '^[0-9a-f]{64}$'),
  refresh_precedente text UNIQUE CHECK (refresh_precedente IS NULL OR refresh_precedente ~ '^[0-9a-f]{64}$'),
  refresh_expire_le timestamptz NOT NULL,
  absolue_expire_le timestamptz NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  derniere_utilisation_le timestamptz,
  revoquee_le timestamptz,
  revoquee_par uuid REFERENCES public.profiles (id),
  motif_revocation text,
  CONSTRAINT praxis_oauth_connexions_duree CHECK (absolue_expire_le > cree_le AND absolue_expire_le <= cree_le + interval '90 days'),
  CONSTRAINT praxis_oauth_connexions_revocation CHECK (
    (revoquee_le IS NULL AND revoquee_par IS NULL AND motif_revocation IS NULL)
    OR (revoquee_le IS NOT NULL AND revoquee_par IS NOT NULL
        AND pg_catalog.length(pg_catalog.btrim(motif_revocation)) BETWEEN 1 AND 240))
);
ALTER TABLE private.praxis_oauth_connexions ENABLE ROW LEVEL SECURITY;

CREATE TABLE private.praxis_oauth_demandes (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  client_id text NOT NULL REFERENCES private.praxis_oauth_clients (client_id),
  rappel text NOT NULL,
  code_challenge text NOT NULL CHECK (code_challenge ~ '^[A-Za-z0-9_-]{43}$'),
  etat text CHECK (etat IS NULL OR pg_catalog.length(etat) <= 512),
  scope text NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  decidee_le timestamptz,
  accordee boolean,
  emise_par uuid REFERENCES public.profiles (id),
  code_empreinte text UNIQUE CHECK (code_empreinte IS NULL OR code_empreinte ~ '^[0-9a-f]{64}$'),
  code_expire_le timestamptz,
  code_utilise_le timestamptz,
  connexion_id uuid REFERENCES private.praxis_oauth_connexions (id),
  CONSTRAINT praxis_oauth_demandes_decision CHECK (
    (decidee_le IS NULL AND accordee IS NULL AND emise_par IS NULL AND code_empreinte IS NULL)
    OR (decidee_le IS NOT NULL AND accordee IS NOT NULL AND emise_par IS NOT NULL
        AND (code_empreinte IS NOT NULL) = accordee))
);
ALTER TABLE private.praxis_oauth_demandes ENABLE ROW LEVEL SECURITY;

ALTER TABLE private.praxis_cles ADD COLUMN connexion_id uuid REFERENCES private.praxis_oauth_connexions (id);

REVOKE ALL ON TABLE private.praxis_oauth_clients, private.praxis_oauth_connexions, private.praxis_oauth_demandes
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Les aides privees (aucun EXECUTE pour les roles de l'API)
-- Le seul rappel que Praxis accepte : celui de claude.ai (chat web, Desktop, mobile). Egalite EXACTE, jamais un motif.
CREATE FUNCTION private.praxis_oauth_rappels()
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT ARRAY['https://claude.ai/api/mcp/auth_callback']::text[];
$f$;

-- base64url sans remplissage (RFC 7636 §4.2).
CREATE FUNCTION private.praxis_oauth_b64url(p_octets bytea)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT pg_catalog.rtrim(pg_catalog.translate(pg_catalog.replace(pg_catalog.encode(p_octets, 'base64'), E'\n', ''), '+/', '-_'), '=');
$f$;

-- Pourcentage-encodage d'une valeur de requete (les octets hors [A-Za-z0-9._~-] deviennent %XX).
CREATE FUNCTION private.praxis_oauth_urlenc(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT coalesce(pg_catalog.string_agg(
           CASE WHEN o < 128 AND pg_catalog.chr(o) ~ '[A-Za-z0-9._~-]' THEN pg_catalog.chr(o)
                ELSE '%' || pg_catalog.upper(pg_catalog.lpad(pg_catalog.to_hex(o), 2, '0')) END, '' ORDER BY i), '')
    FROM (SELECT g AS i, pg_catalog.get_byte(b, g) AS o
            FROM (SELECT pg_catalog.convert_to(coalesce(p_texte, ''), 'UTF8') AS b) x,
                 pg_catalog.generate_series(0, pg_catalog.length(pg_catalog.convert_to(coalesce(p_texte, ''), 'UTF8')) - 1) g) y;
$f$;

-- La personne qui approuve reste une direction active, de compte valide, avec au moins un cote (comme dans praxis_porte).
CREATE FUNCTION private.praxis_oauth_emetteur_valide(p_emetteur uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT private.com_profil_valide(p_emetteur, 'admin') AND pg_catalog.cardinality(private.praxis_cotes(p_emetteur)) > 0;
$f$;

-- Revoque une connexion ET toutes ses cles (aucun renouvellement n'est plus possible).
CREATE FUNCTION private.praxis_oauth_revoquer_connexion(p_id uuid, p_par uuid, p_motif text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_motif text := pg_catalog.left(coalesce(nullif(pg_catalog.btrim(p_motif), ''), 'revocation'), 240);
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  UPDATE private.praxis_oauth_connexions
     SET revoquee_le = v_maintenant, revoquee_par = p_par, motif_revocation = v_motif
   WHERE id = p_id AND revoquee_le IS NULL;
  UPDATE private.praxis_cles
     SET revoquee_le = v_maintenant, revoquee_par = p_par, motif_revocation = v_motif
   WHERE connexion_id = p_id AND revoquee_le IS NULL;
END;
$f$;

-- Une cle d'acces d'une connexion : usage `chat`, une heure, libelle sans texte du client (le nom d'un client enregistre est libre).
CREATE FUNCTION private.praxis_oauth_emettre_cle(p_connexion uuid, p_emetteur uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_secret text := 'prx_' || pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
BEGIN
  INSERT INTO private.praxis_cles (libelle, prefixe, empreinte, usage, emise_par, cle_emission, expire_le, connexion_id)
  VALUES ('Connexion claude.ai du ' || pg_catalog.to_char(pg_catalog.clock_timestamp() AT TIME ZONE 'UTC', 'DD/MM/YYYY HH24:MI') || ' UTC',
          pg_catalog.left(v_secret, 12), private.praxis_empreinte(v_secret), 'chat', p_emetteur, pg_catalog.gen_random_uuid(),
          pg_catalog.clock_timestamp() + interval '1 hour', p_connexion);
  RETURN v_secret;
END;
$f$;

REVOKE ALL ON FUNCTION
  private.praxis_oauth_rappels(), private.praxis_oauth_b64url(bytea), private.praxis_oauth_urlenc(text),
  private.praxis_oauth_emetteur_valide(uuid), private.praxis_oauth_revoquer_connexion(uuid, uuid, text),
  private.praxis_oauth_emettre_cle(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. Les fonctions du service_role (le serveur d'autorisation, fonction Edge `praxis-oauth`). Toute erreur d'echange est `invalid_grant`.
-- 3.1 DCR (RFC 7591) : un client public, rappel UNIQUE en liste blanche, debit borne (10 par heure, 40 par jour).
CREATE FUNCTION public.praxis_oauth_enregistrer(p_nom text, p_rappels text[])
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_nom text := pg_catalog.btrim(pg_catalog.regexp_replace(coalesce(p_nom, ''), '[[:cntrl:]]', '', 'g'));
  v_rappels text[];
  v_id text;
BEGIN
  IF pg_catalog.length(v_nom) NOT BETWEEN 1 AND 80 OR p_rappels IS NULL
     OR pg_catalog.cardinality(p_rappels) NOT BETWEEN 1 AND 5 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'invalid_client_metadata');
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.unnest(p_rappels) r WHERE r IS NULL OR NOT (r = ANY (private.praxis_oauth_rappels()))) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'invalid_redirect_uri');
  END IF;
  SELECT pg_catalog.array_agg(DISTINCT r ORDER BY r) INTO v_rappels FROM pg_catalog.unnest(p_rappels) r;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-oauth-enregistrer', 0));
  IF (SELECT pg_catalog.count(*) FROM private.praxis_oauth_clients c WHERE c.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 10
     OR (SELECT pg_catalog.count(*) FROM private.praxis_oauth_clients c WHERE c.cree_le > pg_catalog.clock_timestamp() - interval '1 day') >= 40 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debit');
  END IF;
  v_id := 'prxc_' || pg_catalog.encode(extensions.gen_random_bytes(16), 'hex');
  INSERT INTO private.praxis_oauth_clients (client_id, nom, rappels) VALUES (v_id, v_nom, v_rappels);
  RETURN pg_catalog.jsonb_build_object('client_id', v_id, 'nom', v_nom, 'rappels', pg_catalog.to_jsonb(v_rappels));
END;
$f$;

-- 3.2 Une demande d'autorisation (point /authorize) : client connu, rappel EXACT, PKCE S256 ; 10 minutes. Un client ou un rappel inconnu ne
-- redirige JAMAIS (la fonction Edge affiche l'erreur).
CREATE FUNCTION public.praxis_oauth_demander(p_client text, p_rappel text, p_challenge text, p_methode text, p_etat text, p_scope text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_c private.praxis_oauth_clients%ROWTYPE;
  v_scope text;
  v_id uuid;
BEGIN
  IF p_client IS NULL OR p_client !~ '^prxc_[0-9a-f]{32}$' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'client_inconnu');
  END IF;
  SELECT c.* INTO v_c FROM private.praxis_oauth_clients c WHERE c.client_id = p_client;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'client_inconnu');
  END IF;
  IF p_rappel IS NULL OR NOT (p_rappel = ANY (v_c.rappels)) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'redirect_invalide');
  END IF;
  IF p_methode IS DISTINCT FROM 'S256' OR p_challenge IS NULL OR p_challenge !~ '^[A-Za-z0-9_-]{43}$'
     OR pg_catalog.length(coalesce(p_etat, '')) > 512 OR pg_catalog.length(coalesce(p_scope, '')) > 200 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'requete_invalide');
  END IF;
  -- Les scopes connus seulement ; `praxis` par defaut.
  SELECT coalesce(pg_catalog.string_agg(DISTINCT s, ' ' ORDER BY s), 'praxis') INTO v_scope
    FROM pg_catalog.unnest(pg_catalog.string_to_array(coalesce(p_scope, ''), ' ')) s WHERE s IN ('praxis', 'offline_access');
  IF (SELECT pg_catalog.count(*) FROM private.praxis_oauth_demandes d
       WHERE d.client_id = p_client AND d.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 30 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debit');
  END IF;
  INSERT INTO private.praxis_oauth_demandes (client_id, rappel, code_challenge, etat, scope, expire_le)
  VALUES (p_client, p_rappel, p_challenge, nullif(p_etat, ''), v_scope, pg_catalog.clock_timestamp() + interval '10 minutes')
  RETURNING id INTO v_id;
  RETURN pg_catalog.jsonb_build_object('demande', v_id);
END;
$f$;

-- 3.3 L'echange d'un code (point /token, authorization_code) : usage unique, 10 minutes, PKCE, client et rappel egaux ; cree la connexion, une
-- cle d'acces d'une heure et le jeton de renouvellement (30 jours, 90 au plus). Un code REJOUE revoque la connexion qu'il avait creee.
CREATE FUNCTION public.praxis_oauth_echanger(p_client text, p_code text, p_rappel text, p_verifier text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_d private.praxis_oauth_demandes%ROWTYPE;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_connexion uuid;
  v_refresh text;
  v_acces text;
  v_refus constant jsonb := pg_catalog.jsonb_build_object('erreur', 'invalid_grant');
BEGIN
  IF p_client IS NULL OR p_code IS NULL OR p_rappel IS NULL OR p_verifier IS NULL
     OR p_code !~ '^[0-9a-f]{64}$' OR p_verifier !~ '^[A-Za-z0-9._~-]{43,128}$' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'invalid_request');
  END IF;
  SELECT d.* INTO v_d FROM private.praxis_oauth_demandes d WHERE d.code_empreinte = private.praxis_empreinte(p_code) FOR UPDATE;
  IF NOT FOUND THEN
    RETURN v_refus;
  END IF;
  -- Code deja employe : rejeu. Ce que le premier echange a cree est revoque.
  IF v_d.code_utilise_le IS NOT NULL THEN
    IF v_d.connexion_id IS NOT NULL THEN
      PERFORM private.praxis_oauth_revoquer_connexion(v_d.connexion_id, private.praxis_profil(), 'code d''autorisation rejoue');
      PERFORM public.log_sensitive_access('praxis_oauth_rejeu_code', 'private.praxis_oauth_connexions', v_d.connexion_id::text,
        pg_catalog.jsonb_build_object('client', v_d.client_id));
    END IF;
    RETURN v_refus;
  END IF;
  -- Le code est brule des qu'il est presente, juste ou faux (un code vole ne se devine pas par essais successifs).
  UPDATE private.praxis_oauth_demandes SET code_utilise_le = v_maintenant WHERE id = v_d.id;
  IF NOT coalesce(v_d.accordee, false) OR v_d.code_expire_le <= v_maintenant OR v_d.client_id <> p_client OR v_d.rappel <> p_rappel
     OR private.praxis_oauth_b64url(pg_catalog.sha256(pg_catalog.convert_to(p_verifier, 'UTF8'))) <> v_d.code_challenge
     OR NOT private.praxis_oauth_emetteur_valide(v_d.emise_par) THEN
    RETURN v_refus;
  END IF;
  v_refresh := 'prxr_' || pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
  INSERT INTO private.praxis_oauth_connexions (client_id, emise_par, refresh_empreinte, refresh_expire_le, absolue_expire_le)
  VALUES (v_d.client_id, v_d.emise_par, private.praxis_empreinte(v_refresh), v_maintenant + interval '30 days', v_maintenant + interval '90 days')
  RETURNING id INTO v_connexion;
  v_acces := private.praxis_oauth_emettre_cle(v_connexion, v_d.emise_par);
  UPDATE private.praxis_oauth_demandes SET connexion_id = v_connexion WHERE id = v_d.id;
  PERFORM public.log_sensitive_access('praxis_oauth_connexion', 'private.praxis_oauth_connexions', v_connexion::text,
    pg_catalog.jsonb_build_object('client', v_d.client_id, 'emisePar', v_d.emise_par));
  RETURN pg_catalog.jsonb_build_object('access_token', v_acces, 'token_type', 'Bearer', 'expires_in', 3600,
                                       'refresh_token', v_refresh, 'scope', v_d.scope);
END;
$f$;

-- 3.4 Le renouvellement (point /token, refresh_token) : rotation (nouveau refresh, nouvelle cle), l'ancien refresh meurt ; la REUTILISATION
-- d'un refresh deja consomme revoque la connexion entiere. Le glissement est de 30 jours, borne par les 90 jours de la connexion.
CREATE FUNCTION public.praxis_oauth_renouveler(p_client text, p_refresh text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_c private.praxis_oauth_connexions%ROWTYPE;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_empreinte text;
  v_refresh text;
  v_acces text;
  v_refus constant jsonb := pg_catalog.jsonb_build_object('erreur', 'invalid_grant');
BEGIN
  IF p_client IS NULL OR p_refresh IS NULL OR p_refresh !~ '^prxr_[0-9a-f]{64}$' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'invalid_request');
  END IF;
  v_empreinte := private.praxis_empreinte(p_refresh);
  SELECT c.* INTO v_c FROM private.praxis_oauth_connexions c WHERE c.refresh_empreinte = v_empreinte FOR UPDATE;
  IF NOT FOUND THEN
    -- Un refresh deja consomme : rejeu, donc vol probable. La connexion entiere est revoquee.
    SELECT c.* INTO v_c FROM private.praxis_oauth_connexions c WHERE c.refresh_precedente = v_empreinte FOR UPDATE;
    IF FOUND AND v_c.revoquee_le IS NULL THEN
      PERFORM private.praxis_oauth_revoquer_connexion(v_c.id, private.praxis_profil(), 'jeton de renouvellement rejoue');
      PERFORM public.log_sensitive_access('praxis_oauth_rejeu_refresh', 'private.praxis_oauth_connexions', v_c.id::text,
        pg_catalog.jsonb_build_object('client', v_c.client_id));
    END IF;
    RETURN v_refus;
  END IF;
  IF v_c.client_id <> p_client OR v_c.revoquee_le IS NOT NULL OR v_c.refresh_expire_le <= v_maintenant
     OR v_c.absolue_expire_le <= v_maintenant OR NOT private.praxis_oauth_emetteur_valide(v_c.emise_par) THEN
    RETURN v_refus;
  END IF;
  v_refresh := 'prxr_' || pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
  UPDATE private.praxis_oauth_connexions
     SET refresh_precedente = refresh_empreinte, refresh_empreinte = private.praxis_empreinte(v_refresh),
         refresh_expire_le = least(v_maintenant + interval '30 days', absolue_expire_le),
         derniere_utilisation_le = v_maintenant
   WHERE id = v_c.id;
  v_acces := private.praxis_oauth_emettre_cle(v_c.id, v_c.emise_par);
  RETURN pg_catalog.jsonb_build_object('access_token', v_acces, 'token_type', 'Bearer', 'expires_in', 3600,
                                       'refresh_token', v_refresh, 'scope', 'praxis offline_access');
END;
$f$;

-- 3.5 praxis-mcp rend 401 (et non 200) quand la CLE est refusee (revoquee, expiree, emetteur plus direction, malformee) : claude.ai ne
-- rafraichit que sur un 401. « Eteint », plafonds et autres causes ne sont pas des problemes de jeton : ils restent des erreurs d'outil.
CREATE FUNCTION public.praxis_cle_valide(p_cle text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $f$
  SELECT coalesce((SELECT p.cause IS DISTINCT FROM 'cle_refusee' FROM private.praxis_porte(p_cle) p), false);
$f$;

-- 4. Les portes de la direction (administrateur valide, double verification aal2) : la page de consentement de l'application.
CREATE FUNCTION public.direction_praxis_oauth_lire(p_demande uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_d private.praxis_oauth_demandes%ROWTYPE;
  v_nom text;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  SELECT d.* INTO v_d FROM private.praxis_oauth_demandes d WHERE d.id = p_demande;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'inconnue');
  END IF;
  SELECT c.nom INTO v_nom FROM private.praxis_oauth_clients c WHERE c.client_id = v_d.client_id;
  RETURN pg_catalog.jsonb_build_object(
    'etat', CASE WHEN v_d.decidee_le IS NOT NULL THEN 'decidee' WHEN v_d.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'en_attente' END,
    'client', v_nom,
    'hote', (pg_catalog.regexp_match(v_d.rappel, '^https://([^/]+)'))[1],
    'expireLe', v_d.expire_le,
    'peutAutoriser', pg_catalog.cardinality(private.praxis_cotes(auth.uid())) > 0);
END;
$f$;

CREATE FUNCTION public.direction_praxis_oauth_decider(p_demande uuid, p_accepter boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_d private.praxis_oauth_demandes%ROWTYPE;
  v_nom text;
  v_code text;
  v_etat text;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_demande IS NULL OR p_accepter IS NULL THEN
    RAISE EXCEPTION 'parametres de decision invalides' USING ERRCODE = '22023';
  END IF;
  SELECT d.* INTO v_d FROM private.praxis_oauth_demandes d WHERE d.id = p_demande FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'inconnue');
  END IF;
  IF v_d.decidee_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'deja_decidee');
  END IF;
  IF v_d.expire_le <= v_maintenant THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'expiree');
  END IF;
  IF p_accepter AND pg_catalog.cardinality(private.praxis_cotes(auth.uid())) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'sans_cote');
  END IF;
  SELECT c.nom INTO v_nom FROM private.praxis_oauth_clients c WHERE c.client_id = v_d.client_id;
  v_etat := CASE WHEN v_d.etat IS NULL THEN '' ELSE '&state=' || private.praxis_oauth_urlenc(v_d.etat) END;
  IF p_accepter THEN
    v_code := pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
    UPDATE private.praxis_oauth_demandes
       SET decidee_le = v_maintenant, accordee = true, emise_par = auth.uid(),
           code_empreinte = private.praxis_empreinte(v_code), code_expire_le = v_maintenant + interval '10 minutes'
     WHERE id = v_d.id;
  ELSE
    UPDATE private.praxis_oauth_demandes
       SET decidee_le = v_maintenant, accordee = false, emise_par = auth.uid()
     WHERE id = v_d.id;
  END IF;
  -- Le code ne figure JAMAIS dans l'audit : seulement la decision et le client.
  PERFORM public.log_sensitive_access('praxis_oauth_decision', 'private.praxis_oauth_demandes', v_d.id::text,
    pg_catalog.jsonb_build_object('accorde', p_accepter, 'client', v_nom));
  RETURN pg_catalog.jsonb_build_object('redirection',
    v_d.rappel || CASE WHEN p_accepter THEN '?code=' || v_code ELSE '?error=access_denied' END || v_etat);
END;
$f$;

-- 5. Retouche par ancrage : revoquer une cle nee d'une connexion revoque la connexion et toutes ses cles.

CREATE OR REPLACE FUNCTION public.direction_praxis_revoquer_cle(p_id uuid, p_motif text, p_cle uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $f$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_row private.praxis_cles%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_cle IS NULL OR pg_catalog.length(v_motif) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'parametres de revocation invalides' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_row FROM private.praxis_cles c WHERE c.id = p_id FOR UPDATE;
  IF NOT FOUND OR v_row.revoquee_le IS NOT NULL THEN
    RETURN false;
  END IF;
  UPDATE private.praxis_cles
     SET revoquee_le = pg_catalog.clock_timestamp(), revoquee_par = auth.uid(), motif_revocation = v_motif
   WHERE id = p_id;
  PERFORM public.log_sensitive_access('praxis_cle_revoquee', 'private.praxis_cles', p_id::text,
    pg_catalog.jsonb_build_object('motif', v_motif));
  -- PX-OAUTH 2b : une cle nee d'une connexion claude.ai ne se revoque pas seule (le renouvellement en referait une) : la connexion entiere
  -- et toutes ses cles sont revoquees.
  IF v_row.connexion_id IS NOT NULL THEN
    PERFORM private.praxis_oauth_revoquer_connexion(v_row.connexion_id, auth.uid(), v_motif);
  END IF;
  RETURN true;
END;
$f$;


-- 6. Droits. Les cinq fonctions du serveur d'autorisation : service_role seul. Les deux portes de la page de consentement : authenticated
-- (la garde positive est dans leur corps).
REVOKE ALL ON FUNCTION
  public.praxis_oauth_enregistrer(text, text[]), public.praxis_oauth_demander(text, text, text, text, text, text),
  public.praxis_oauth_echanger(text, text, text, text), public.praxis_oauth_renouveler(text, text), public.praxis_cle_valide(text),
  public.direction_praxis_oauth_lire(uuid), public.direction_praxis_oauth_decider(uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.praxis_oauth_enregistrer(text, text[]), public.praxis_oauth_demander(text, text, text, text, text, text),
  public.praxis_oauth_echanger(text, text, text, text), public.praxis_oauth_renouveler(text, text), public.praxis_cle_valide(text)
  TO service_role;
GRANT EXECUTE ON FUNCTION
  public.direction_praxis_oauth_lire(uuid), public.direction_praxis_oauth_decider(uuid, boolean)
  TO authenticated;

-- 7. Controle apres coup.
DO $post$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'private' AND c.relname LIKE 'praxis\_oauth\_%' AND c.relkind = 'r' AND c.relrowsecurity) <> 3 THEN
    RAISE EXCEPTION 'PX-OAUTH 2b : une table praxis_oauth_* sans RLS';
  END IF;
  IF (SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.direction_praxis_revoquer_cle(uuid,text,uuid)'::regprocedure)
     NOT LIKE '%praxis_oauth_revoquer_connexion%' THEN
    RAISE EXCEPTION 'PX-OAUTH 2b : retouche de direction_praxis_revoquer_cle absente';
  END IF;
  IF has_function_privilege('authenticated', 'public.praxis_oauth_echanger(text,text,text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.praxis_oauth_echanger(text,text,text,text)', 'EXECUTE')
     OR NOT has_function_privilege('service_role', 'public.praxis_oauth_echanger(text,text,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX-OAUTH 2b : droits de praxis_oauth_echanger inattendus';
  END IF;
END
$post$;
