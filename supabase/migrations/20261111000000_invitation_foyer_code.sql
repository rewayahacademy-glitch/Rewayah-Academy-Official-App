-- INVITATION-SECOND-ADULTE (point 6 du pilote, 07/11/2026 ; conception
-- acceptee par le garde-cap, double lecture de securite obligatoire).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- le pilote l'installe tel quel. Migration additive (B6) : aucune signature
-- publique existante ne change, aucune colonne n'est retiree ni ne change de
-- sens.
--
-- Constat (production) : les inscriptions sont fermees au niveau de
-- l'instance Auth (« Signups not allowed for this instance », journaux Auth
-- lus par le pilote, refus reels les 06/11 et 07/11). Le bouton de l'e-mail
-- `invitation_foyer` menait a `/#/connexion` sans code ; l'adresse invitee ne
-- pouvait pas creer son compte ; aucun renvoi. Le meme mur arrete
-- l'enseignant et le comptable invites : leur code n'est verifie qu'apres
-- la session (`inscrire_enseignant_invite`, `auth.uid()`).
--
-- Correction :
-- 1. Chaque invitation de foyer porte un code AAAA-BBBB-CCCC (meme forme
--    que l'enseignant, 12 signes tires sans biais : 59,4 bits, arbitrage du
--    garde-cap du 07/11).
--    Seule l'empreinte sha256 du code est gardee (table privee) ; le code
--    clair ne vit que dans la transaction qui l'emet et dans l'e-mail, dont
--    il est retire quand l'envoi est fait ou annule (envoye, annule) ; jamais
--    a 'echec', qui n'est pas definitif (admin_courriel_reessayer le relance,
--    seconde lecture du 07/11). Un
--    declencheur l'emet a l'insertion : `inviter_conjoint` ne change pas.
-- 2. `courriel_depuis_invitation_foyer` porte le code dans l'e-mail
--    (remplacement precede d'un preflight sur md5(prosrc)).
-- 3. `renvoyer_invitation_conjoint(p_cle)` : le titulaire renvoie la meme
--    invitation a la meme adresse ; nouveau code, l'ancien ne sert plus ;
--    echeance inchangee ; trois renvois au plus ; idempotent par cle.
-- 4. `mon_invitation_envoyee()` : le titulaire lit son invitation en
--    attente (adresse, echeance, renvois restants). Lecture seule.
-- 5. `invitation_foyer_pour_moi(p_code)` : une session lit si un code est
--    pour son adresse (« pour_vous »), pour une autre (« autre_adresse »),
--    ou ne sert plus (« perimee », « inconnue »). Rien n'est consomme.
-- 6. `invitation_compte_autoriser(p_type, p_code, p_email)`, service_role
--    seul (fonction Edge `invitation-compte`), pour les trois invitations
--    (foyer, enseignant, comptable) : vraie seulement pour un code valide,
--    non utilise, non revoque, non echu, emis pour cette adresse, et une
--    adresse sans compte. Le code d'un foyer est marque utilise dans la meme
--    transaction ; ceux de l'enseignant et du comptable restent consommes par
--    leur inscription, comme avant (un seul compte par adresse de toute
--    facon).
-- 6 bis. Candidat d'un formulaire importe (arbitrage du garde-cap, 07/11) :
--    le courriel `lien_inscription` recoit a l'entree dans la file un code
--    a usage unique lie a l'adresse, garde hache, echeance 30 jours ; le type
--    `candidat` le verifie (adresse d'une reponse de formulaire active encore
--    sans candidature) et le consomme. Le type `equipe` sert un code
--    d'enseignant ou de comptable recopie a la main.
-- 7. `invitation_compte_debit(p_adresse, p_ip)`, service_role seul : cinq
--    demandes par heure au plus, par adresse ET par IP ; chaque demande est
--    journalisee (empreintes seulement).
-- L'echeance reste de 7 jours apres l'envoi : elle ne court jamais d'un clic.


-- ---------------------------------------------------------------------------
-- 0. Preflight : la fonction remplacee est celle du depot (20261023120000).
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.md5((SELECT p.prosrc FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.courriel_depuis_invitation_foyer()'::regprocedure))
     <> 'd98a984f612ea1cfde5ccb84cf8da03d' THEN
    RAISE EXCEPTION 'INVITATION-FOYER : courriel_depuis_invitation_foyer a change depuis le depot';
  END IF;
  IF to_regclass('app_private.codes_invitation_foyer') IS NOT NULL THEN
    RAISE EXCEPTION 'INVITATION-FOYER : deja installee';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Tables privees : codes (empreintes), renvois, demandes.
-- ---------------------------------------------------------------------------
-- Sans cle etrangere vers les invitations : le retrait d'un foyer (CPT-SUPPR)
-- n'est jamais bloque par une de ces lignes ; une ligne orpheline ne sert a
-- rien.
CREATE TABLE app_private.codes_invitation_foyer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invitation_id uuid NOT NULL,
  code_sha256 text NOT NULL UNIQUE CHECK (code_sha256 ~ '^[0-9a-f]{64}$'),
  emis_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  remplace_le timestamptz,
  utilise_le timestamptz
);
CREATE UNIQUE INDEX codes_invitation_foyer_actif
  ON app_private.codes_invitation_foyer(invitation_id) WHERE remplace_le IS NULL;
ALTER TABLE app_private.codes_invitation_foyer ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.codes_invitation_foyer FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TABLE app_private.renvois_invitation_foyer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invitation_id uuid NOT NULL,
  cle uuid NOT NULL,
  renvoye_par uuid NOT NULL,
  renvoye_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (renvoye_par, cle)
);
ALTER TABLE app_private.renvois_invitation_foyer ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.renvois_invitation_foyer FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le journal des demandes de creation de compte, qui sert aussi au debit.
-- `cle` : « adresse:<empreinte> » ou « ip:<empreinte> » (sha256, jamais la
-- valeur claire).
CREATE TABLE app_private.demandes_invitation_compte (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cle text NOT NULL CHECK (cle ~ '^(adresse|ip):[0-9a-f]{64}$'),
  acceptee boolean NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX demandes_invitation_compte_cle
  ON app_private.demandes_invitation_compte(cle, cree_le);
ALTER TABLE app_private.demandes_invitation_compte ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.demandes_invitation_compte FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le code du candidat d'un formulaire importe (lien_inscription), lie a son
-- adresse : la candidature n'existe pas encore (elle nait du compte).
CREATE TABLE app_private.codes_invitation_candidat (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adresse text NOT NULL CHECK (adresse = pg_catalog.lower(pg_catalog.btrim(adresse))),
  code_sha256 text NOT NULL UNIQUE CHECK (code_sha256 ~ '^[0-9a-f]{64}$'),
  emis_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  remplace_le timestamptz,
  utilise_le timestamptz
);
CREATE UNIQUE INDEX codes_invitation_candidat_actif
  ON app_private.codes_invitation_candidat(adresse) WHERE remplace_le IS NULL;
ALTER TABLE app_private.codes_invitation_candidat ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.codes_invitation_candidat FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 2. Le code : forme, empreinte, emission.
-- ---------------------------------------------------------------------------
-- L'empreinte d'un code recopie (casse, espaces, tirets oublies : la forme
-- unique de app_private.code_invitation_normalise, I1).
CREATE FUNCTION app_private.empreinte_code_invitation(p_code text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    app_private.code_invitation_normalise(p_code), 'UTF8')), 'hex');
$function$;
ALTER FUNCTION app_private.empreinte_code_invitation(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.empreinte_code_invitation(text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Un code neuf AAAA-BBBB-CCCC : 12 signes d'un alphabet de 31 sans signe
-- ambigu (59,4 bits, arbitrage du garde-cap du 07/11 : suffisant avec cinq
-- essais par heure par adresse et par IP et un code lie a une adresse),
-- tires par rejet (un octet n'est garde que sous 248 = 8 x 31 : chaque signe
-- a la meme chance).
CREATE FUNCTION app_private.code_invitation_neuf()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_octets bytea;
  v_octet integer;
  v_signes text := '';
  v_i integer;
BEGIN
  WHILE pg_catalog.length(v_signes) < 12 LOOP
    v_octets := extensions.gen_random_bytes(24);
    FOR v_i IN 0..23 LOOP
      v_octet := pg_catalog.get_byte(v_octets, v_i);
      IF v_octet < 248 AND pg_catalog.length(v_signes) < 12 THEN
        v_signes := v_signes || pg_catalog.substr(v_alphabet, (v_octet % 31) + 1, 1);
      END IF;
    END LOOP;
  END LOOP;
  RETURN app_private.code_invitation_normalise(v_signes);
END;
$function$;
ALTER FUNCTION app_private.code_invitation_neuf() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.code_invitation_neuf()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Emet un code neuf pour une invitation ; l'ancien code actif est remplace
-- (il ne sert plus). Rend le code clair, qui n'est garde nulle part : il est
-- aussi pose pour la transaction (`rewayah.code_invitation_foyer`), ou le
-- declencheur de l'e-mail le lit.
CREATE FUNCTION app_private.emettre_code_invitation_foyer(p_invitation uuid)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_code text;
  v_essai integer := 0;
BEGIN
  UPDATE app_private.codes_invitation_foyer
     SET remplace_le = pg_catalog.clock_timestamp()
   WHERE invitation_id = p_invitation AND remplace_le IS NULL;
  LOOP
    v_essai := v_essai + 1;
    v_code := app_private.code_invitation_neuf();
    BEGIN
      INSERT INTO app_private.codes_invitation_foyer (invitation_id, code_sha256)
      VALUES (p_invitation, app_private.empreinte_code_invitation(v_code));
      PERFORM pg_catalog.set_config('rewayah.code_invitation_foyer',
        p_invitation::text || ':' || v_code, true);
      RETURN v_code;
    EXCEPTION WHEN unique_violation THEN
      IF v_essai >= 5 THEN
        RAISE;
      END IF;
    END;
  END LOOP;
END;
$function$;
ALTER FUNCTION app_private.emettre_code_invitation_foyer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.emettre_code_invitation_foyer(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION app_private.code_invitation_foyer_a_l_insertion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM app_private.emettre_code_invitation_foyer(NEW.id);
  RETURN NULL;
END;
$function$;
ALTER FUNCTION app_private.code_invitation_foyer_a_l_insertion() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.code_invitation_foyer_a_l_insertion()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER code_invitation_foyer
  AFTER INSERT ON public.invitations_foyer
  FOR EACH ROW EXECUTE FUNCTION app_private.code_invitation_foyer_a_l_insertion();

-- Les invitations deja en attente recoivent un code (aucun e-mail ne part :
-- le titulaire renvoie s'il le souhaite).
DO $codes$
BEGIN
  PERFORM app_private.emettre_code_invitation_foyer(i.id)
     FROM public.invitations_foyer i
    WHERE i.statut = 'en_attente';
END
$codes$;

-- ---------------------------------------------------------------------------
-- 3. L'e-mail porte le code ; le code quitte la file des que l'envoi est clos.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.courriel_depuis_invitation_foyer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_prenom text;
  v_expire timestamptz;
  v_pose text := pg_catalog.current_setting('rewayah.code_invitation_foyer', true);
  v_code text;
BEGIN
  SELECT p.first_name, i.expire_le INTO v_prenom, v_expire
    FROM public.invitations_foyer i
    JOIN public.profiles p ON p.id = i.invite_par
   WHERE i.id = NEW.invitation_id;
  IF v_pose LIKE NEW.invitation_id::text || ':%' THEN
    v_code := pg_catalog.substr(v_pose, pg_catalog.length(NEW.invitation_id::text) + 2);
  END IF;
  PERFORM public.courriel_enfiler(
    'compte', 'invitation_foyer', NEW.recipient_email, NULL,
    pg_catalog.jsonb_build_object('invite_par', v_prenom, 'expire_le', v_expire,
      'code', v_code),
    'invitation_foyer:' || NEW.id::text);
  RETURN NULL;
END;
$function$;

CREATE FUNCTION app_private.courriel_sans_code_apres_envoi()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.modele IN ('invitation_foyer', 'lien_inscription')
     AND NEW.statut IN ('envoye', 'annule')
     AND NEW.donnees ? 'code' THEN
    NEW.donnees := NEW.donnees - 'code';
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION app_private.courriel_sans_code_apres_envoi() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.courriel_sans_code_apres_envoi()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER courriel_sans_code_apres_envoi
  BEFORE UPDATE OF statut ON public.courriels_sortants
  FOR EACH ROW EXECUTE FUNCTION app_private.courriel_sans_code_apres_envoi();

-- Le courriel lien_inscription d'un candidat recoit son code a l'entree dans
-- la file (une ligne vraiment inseree : ON CONFLICT DO NOTHING ne declenche
-- pas un AFTER INSERT). Echeance : 30 jours. L'ancien code de l'adresse ne
-- sert plus.
CREATE FUNCTION app_private.courriel_code_candidat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_code text;
  v_essai integer := 0;
BEGIN
  IF NEW.modele <> 'lien_inscription' THEN
    RETURN NULL;
  END IF;
  UPDATE app_private.codes_invitation_candidat
     SET remplace_le = pg_catalog.clock_timestamp()
   WHERE adresse = NEW.destinataire_adresse AND remplace_le IS NULL;
  LOOP
    v_essai := v_essai + 1;
    v_code := app_private.code_invitation_neuf();
    BEGIN
      INSERT INTO app_private.codes_invitation_candidat (adresse, code_sha256, expire_le)
      VALUES (NEW.destinataire_adresse, app_private.empreinte_code_invitation(v_code),
              pg_catalog.now() + interval '30 days');
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF v_essai >= 5 THEN
        RAISE;
      END IF;
    END;
  END LOOP;
  UPDATE public.courriels_sortants
     SET donnees = donnees || pg_catalog.jsonb_build_object('code', v_code)
   WHERE id = NEW.id;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION app_private.courriel_code_candidat() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.courriel_code_candidat()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER courriel_code_candidat
  AFTER INSERT ON public.courriels_sortants
  FOR EACH ROW WHEN (NEW.modele = 'lien_inscription')
  EXECUTE FUNCTION app_private.courriel_code_candidat();

-- ---------------------------------------------------------------------------
-- 4. Le titulaire renvoie l'invitation.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.renvoyer_invitation_conjoint(p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_max constant integer := 3;
  v_invitation public.invitations_foyer%ROWTYPE;
  v_renvois integer;
  v_code text;
  v_prenom text;
BEGIN
  IF v_user IS NULL OR p_cle IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'renvoi indisponible' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_invitation
    FROM public.invitations_foyer i
    JOIN public.households h ON h.id = i.foyer_id
   WHERE i.statut = 'en_attente'
     AND i.invite_par = v_user
     AND h.primary_guardian_id = v_user
     AND h.status = 'active' AND h.deleted_at IS NULL
   FOR UPDATE OF i;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'aucune');
  END IF;

  -- Meme cle, meme reponse : une coupure se rejoue sans second e-mail.
  IF EXISTS (SELECT 1 FROM app_private.renvois_invitation_foyer r
              WHERE r.renvoye_par = v_user AND r.cle = p_cle
                AND r.invitation_id = v_invitation.id) THEN
    SELECT pg_catalog.count(*)::integer INTO v_renvois
      FROM app_private.renvois_invitation_foyer r WHERE r.invitation_id = v_invitation.id;
    RETURN pg_catalog.jsonb_build_object('etat', 'renvoyee',
      'renvois_restants', greatest(0, v_max - v_renvois),
      'expire_le', v_invitation.expire_le);
  END IF;

  IF v_invitation.expire_le <= pg_catalog.now() THEN
    UPDATE public.invitations_foyer
       SET statut = 'expiree', updated_at = pg_catalog.now()
     WHERE id = v_invitation.id AND statut = 'en_attente';
    UPDATE public.email_outbox_invitation_foyer
       SET statut = 'annule'
     WHERE invitation_id = v_invitation.id AND statut = 'en_attente';
    RETURN pg_catalog.jsonb_build_object('etat', 'perimee');
  END IF;

  SELECT pg_catalog.count(*)::integer INTO v_renvois
    FROM app_private.renvois_invitation_foyer r WHERE r.invitation_id = v_invitation.id;
  IF v_renvois >= v_max THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'limite', 'renvois_restants', 0,
      'expire_le', v_invitation.expire_le);
  END IF;

  INSERT INTO app_private.renvois_invitation_foyer (invitation_id, cle, renvoye_par)
  VALUES (v_invitation.id, p_cle, v_user);
  v_renvois := v_renvois + 1;
  v_code := app_private.emettre_code_invitation_foyer(v_invitation.id);

  -- Un e-mail precedent encore en file porte un code qui ne sert plus.
  UPDATE public.courriels_sortants
     SET statut = 'annule'
   WHERE statut = 'en_attente'
     AND modele = 'invitation_foyer'
     AND destinataire_adresse = v_invitation.email_invite;

  SELECT p.first_name INTO v_prenom FROM public.profiles p WHERE p.id = v_user;
  PERFORM public.courriel_enfiler(
    'compte', 'invitation_foyer', v_invitation.email_invite, NULL,
    pg_catalog.jsonb_build_object('invite_par', v_prenom,
      'expire_le', v_invitation.expire_le, 'code', v_code),
    'invitation_foyer:' || v_invitation.id::text || ':renvoi:' || v_renvois::text);

  PERFORM public.log_sensitive_access(
    'invitation_conjoint_renvoyee', 'invitations_foyer', v_invitation.id::text,
    pg_catalog.jsonb_build_object('foyer_id', v_invitation.foyer_id, 'renvoi', v_renvois));

  RETURN pg_catalog.jsonb_build_object('etat', 'renvoyee',
    'renvois_restants', v_max - v_renvois,
    'expire_le', v_invitation.expire_le);
END;
$function$;
ALTER FUNCTION public.renvoyer_invitation_conjoint(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.renvoyer_invitation_conjoint(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.renvoyer_invitation_conjoint(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Le titulaire lit son invitation en attente.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.mon_invitation_envoyee()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_invitation public.invitations_foyer%ROWTYPE;
  v_renvois integer;
BEGIN
  IF v_user IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'aucune');
  END IF;
  SELECT i.* INTO v_invitation
    FROM public.invitations_foyer i
    JOIN public.households h ON h.id = i.foyer_id
   WHERE i.statut = 'en_attente'
     AND i.expire_le > pg_catalog.now()
     AND i.invite_par = v_user
     AND h.primary_guardian_id = v_user
     AND h.status = 'active' AND h.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'aucune');
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_renvois
    FROM app_private.renvois_invitation_foyer r WHERE r.invitation_id = v_invitation.id;
  RETURN pg_catalog.jsonb_build_object('etat', 'en_attente',
    'courriel', v_invitation.email_invite,
    'expire_le', v_invitation.expire_le,
    'renvois_restants', greatest(0, 3 - v_renvois));
END;
$function$;
ALTER FUNCTION public.mon_invitation_envoyee() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mon_invitation_envoyee() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.mon_invitation_envoyee() TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. Une session lit si un code est pour elle. Rien n'est consomme.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.invitation_foyer_pour_moi(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_email text;
  v_adresse text;
  v_statut text;
  v_expire timestamptz;
  v_remplace timestamptz;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = v_user;
  IF v_user IS NULL OR v_email IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'inconnue');
  END IF;
  SELECT i.email_invite, i.statut, i.expire_le, c.remplace_le
    INTO v_adresse, v_statut, v_expire, v_remplace
    FROM app_private.codes_invitation_foyer c
    JOIN public.invitations_foyer i ON i.id = c.invitation_id
   WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code);
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'inconnue');
  END IF;
  IF v_remplace IS NOT NULL OR v_statut <> 'en_attente'
     OR v_expire <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'perimee');
  END IF;
  IF v_adresse <> v_email THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'autre_adresse');
  END IF;
  RETURN pg_catalog.jsonb_build_object('etat', 'pour_vous');
END;
$function$;
ALTER FUNCTION public.invitation_foyer_pour_moi(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.invitation_foyer_pour_moi(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitation_foyer_pour_moi(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 7. La creation du compte de l'adresse invitee (service_role seulement).
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.invitation_compte_autoriser(p_type text, p_code text, p_email text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_email, '')));
  v_ligne app_private.codes_invitation_foyer%ROWTYPE;
  v_invitation public.invitations_foyer%ROWTYPE;
  v_candidat app_private.codes_invitation_candidat%ROWTYPE;
  v_trouve boolean;
BEGIN
  IF v_email = '' OR EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = v_email) THEN
    -- Adresse vide, ou deja un compte : rien a creer, rien a consommer.
    RETURN pg_catalog.jsonb_build_object('autorise', false);
  END IF;

  IF p_type = 'foyer' THEN
    SELECT c.* INTO v_ligne
      FROM app_private.codes_invitation_foyer c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code)
     FOR UPDATE;
    IF NOT FOUND OR v_ligne.remplace_le IS NOT NULL OR v_ligne.utilise_le IS NOT NULL THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
    SELECT i.* INTO v_invitation FROM public.invitations_foyer i
     WHERE i.id = v_ligne.invitation_id FOR UPDATE;
    IF NOT FOUND OR v_invitation.statut <> 'en_attente'
       OR v_invitation.expire_le <= pg_catalog.now()
       OR v_invitation.email_invite <> v_email THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
    -- Usage unique, dans la meme transaction que l'autorisation.
    UPDATE app_private.codes_invitation_foyer
       SET utilise_le = pg_catalog.clock_timestamp()
     WHERE id = v_ligne.id;
    PERFORM public.log_sensitive_access(
      'invitation_compte_autorise', 'invitations_foyer', v_invitation.id::text,
      pg_catalog.jsonb_build_object('type', 'foyer', 'foyer_id', v_invitation.foyer_id));
    RETURN pg_catalog.jsonb_build_object('autorise', true);
  ELSIF p_type = 'candidat' THEN
    SELECT c.* INTO v_candidat
      FROM app_private.codes_invitation_candidat c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code)
     FOR UPDATE;
    IF NOT FOUND OR v_candidat.remplace_le IS NOT NULL OR v_candidat.utilise_le IS NOT NULL
       OR v_candidat.expire_le <= pg_catalog.now() OR v_candidat.adresse <> v_email
       OR NOT EXISTS (SELECT 1 FROM public.formulaires_reponses r
                       WHERE r.courriel = v_email AND r.etat = 'active'
                         AND r.candidature_id IS NULL) THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
    UPDATE app_private.codes_invitation_candidat
       SET utilise_le = pg_catalog.clock_timestamp()
     WHERE id = v_candidat.id;
    v_trouve := true;
  ELSIF p_type IN ('enseignant', 'comptable', 'equipe') THEN
    -- `equipe` : un code recopie a la main, sans savoir s'il est d'enseignant
    -- ou de comptable ; il reste lie a son adresse.
    SELECT true INTO v_trouve FROM public.invitations_enseignant i
     WHERE p_type IN ('enseignant', 'equipe')
       AND i.code = app_private.code_invitation_normalise(p_code)
       AND i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
       AND i.expire_le > pg_catalog.now();
    IF NOT coalesce(v_trouve, false) THEN
      SELECT true INTO v_trouve FROM public.invitations_comptable i
       WHERE p_type IN ('comptable', 'equipe')
         AND i.code = app_private.code_invitation_normalise(p_code)
         AND i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
         AND i.expire_le > pg_catalog.now();
    END IF;
  END IF;
  IF coalesce(v_trouve, false) THEN
    PERFORM public.log_sensitive_access(
      'invitation_compte_autorise', 'invitations_' || p_type, NULL,
      pg_catalog.jsonb_build_object('type', p_type));
    RETURN pg_catalog.jsonb_build_object('autorise', true);
  END IF;
  RETURN pg_catalog.jsonb_build_object('autorise', false);
END;
$function$;
ALTER FUNCTION public.invitation_compte_autoriser(text, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.invitation_compte_autoriser(text, text, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitation_compte_autoriser(text, text, text) TO service_role;

-- Cinq demandes par heure au plus, par adresse ET par IP. Chaque demande est
-- journalisee (empreintes seulement), acceptee ou non.
CREATE FUNCTION public.invitation_compte_debit(p_adresse text, p_ip text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_max constant integer := 5;
  v_adresse text := 'adresse:' || pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.lower(pg_catalog.btrim(coalesce(p_adresse, ''))), 'UTF8')), 'hex');
  v_ip text := 'ip:' || pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.btrim(coalesce(p_ip, '')), 'UTF8')), 'hex');
  v_ok boolean;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_adresse, 0));
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_ip, 0));
  v_ok := (SELECT pg_catalog.count(*) FROM app_private.demandes_invitation_compte d
            WHERE d.cle = v_adresse AND d.acceptee
              AND d.cree_le > pg_catalog.now() - interval '1 hour') < v_max
      AND (SELECT pg_catalog.count(*) FROM app_private.demandes_invitation_compte d
            WHERE d.cle = v_ip AND d.acceptee
              AND d.cree_le > pg_catalog.now() - interval '1 hour') < v_max;
  INSERT INTO app_private.demandes_invitation_compte (cle, acceptee)
  VALUES (v_adresse, v_ok), (v_ip, v_ok);
  RETURN v_ok;
END;
$function$;
ALTER FUNCTION public.invitation_compte_debit(text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.invitation_compte_debit(text, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitation_compte_debit(text, text) TO service_role;

-- ---------------------------------------------------------------------------
-- 8. Commentaires F86 et postflight.
-- ---------------------------------------------------------------------------
COMMENT ON FUNCTION public.courriel_depuis_invitation_foyer() IS
  'F86 candidate allowlist: signature=courriel_depuis_invitation_foyer(); md5_functiondef=0ac0f9a9ea9014e1b7bf1bb725067798; guard_type=INTERNAL_NO_EXECUTE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-07. COURRIELS-1 ; INVITATION-FOYER : le code clair de la transaction entre dans l''e-mail.';
COMMENT ON FUNCTION public.renvoyer_invitation_conjoint(uuid) IS
  'F86: signature=public.renvoyer_invitation_conjoint(uuid); md5_functiondef=bd9af4be5addd46635160be990cf247f; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Garde: app_role() = guardian et app_account_valid(), titulaire du foyer actif auteur de l''invitation en attente. Trois renvois au plus, idempotent par cle, echeance inchangee.';
COMMENT ON FUNCTION public.mon_invitation_envoyee() IS
  'F86: signature=public.mon_invitation_envoyee(); md5_functiondef=6de1bbacc07f7ba2db222221bbbd0345; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Lecture seule : l''invitation en attente du titulaire (adresse, echeance, renvois restants).';
COMMENT ON FUNCTION public.invitation_foyer_pour_moi(text) IS
  'F86: signature=public.invitation_foyer_pour_moi(text); md5_functiondef=e220269ab8dea32a13e6c0cff0792a4c; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-07. Lecture seule, rien n''est consomme : pour_vous, autre_adresse, perimee ou inconnue.';
COMMENT ON FUNCTION public.invitation_compte_autoriser(text, text, text) IS
  'F86: signature=public.invitation_compte_autoriser(text,text,text); md5_functiondef=a352135882bab4512136ed50f5a4a2b7; guard_type=SERVICE_ROLE_ONLY; owner=postgres; search_path=""; date=2026-11-07. Fonction Edge invitation-compte : vrai seulement pour un code valide, non utilise, non revoque, non echu, de cette adresse, et une adresse sans compte ; le code d''un foyer est consomme dans la meme transaction.';
COMMENT ON FUNCTION public.invitation_compte_debit(text, text) IS
  'F86: signature=public.invitation_compte_debit(text,text); md5_functiondef=1b07be1cd858958cc66b2260812168fd; guard_type=SERVICE_ROLE_ONLY; owner=postgres; search_path=""; date=2026-11-07. Cinq demandes par heure au plus par adresse et par IP ; journal par empreintes.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.courriel_depuis_invitation_foyer()'::regprocedure)) <> '0ac0f9a9ea9014e1b7bf1bb725067798'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.renvoyer_invitation_conjoint(uuid)'::regprocedure)) <> 'bd9af4be5addd46635160be990cf247f'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mon_invitation_envoyee()'::regprocedure)) <> '6de1bbacc07f7ba2db222221bbbd0345'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.invitation_foyer_pour_moi(text)'::regprocedure)) <> 'e220269ab8dea32a13e6c0cff0792a4c'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.invitation_compte_autoriser(text,text,text)'::regprocedure)) <> 'a352135882bab4512136ed50f5a4a2b7'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.invitation_compte_debit(text,text)'::regprocedure)) <> '1b07be1cd858958cc66b2260812168fd' THEN
    RAISE EXCEPTION 'INVITATION-FOYER : empreinte F86 invalide';
  END IF;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.renvoyer_invitation_conjoint(uuid)'::regprocedure,
    'public.mon_invitation_envoyee()'::regprocedure,
    'public.invitation_foyer_pour_moi(text)'::regprocedure,
    'public.invitation_compte_autoriser(text,text,text)'::regprocedure,
    'public.invitation_compte_debit(text,text)'::regprocedure,
    'public.courriel_depuis_invitation_foyer()'::regprocedure,
    'app_private.emettre_code_invitation_foyer(uuid)'::regprocedure,
    'app_private.code_invitation_foyer_a_l_insertion()'::regprocedure,
    'app_private.courriel_sans_code_apres_envoi()'::regprocedure,
    'app_private.courriel_code_candidat()'::regprocedure] LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = v_oid AND p.prosecdef
            AND p.proowner = 'postgres'::regrole
            AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'INVITATION-FOYER : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.renvoyer_invitation_conjoint(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mon_invitation_envoyee()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.invitation_foyer_pour_moi(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.invitation_compte_debit(text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.invitation_compte_debit(text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.emettre_code_invitation_foyer(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'app_private.emettre_code_invitation_foyer(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'INVITATION-FOYER : droits invalides';
  END IF;
  IF EXISTS (SELECT 1 FROM public.invitations_foyer i
              WHERE i.statut = 'en_attente'
                AND NOT EXISTS (SELECT 1 FROM app_private.codes_invitation_foyer c
                                 WHERE c.invitation_id = i.id AND c.remplace_le IS NULL)) THEN
    RAISE EXCEPTION 'INVITATION-FOYER : une invitation en attente sans code';
  END IF;
END
$postflight$;

