-- PX-1 (ancien SEC-1) : Praxis, l'assistant IA de l'academie. SOCLE : le compte, les cles, les reglages, le journal,
-- les outils de LECTURE (etat, boite, fil, rendre_compte, calendrier). Les outils qui ECRIVENT des
-- messages et des annonces (ecrire, annoncer) viennent dans 20261129620000, apres la retouche de la messagerie
-- (20261129610000, installee seule). Documents : docs/current/BUREAU-EQUIPE/PRAXIS/SECURITE-PRAXIS.md (R1 a R15, §3,
-- §7), CAHIER-SEC-1-PRAXIS-MESSAGES.md (A-1 a A-11), RELEVE-PX1.md.
--
-- L'INTERRUPTEUR EST FAUX APRES INSTALLATION (private.praxis_reglages : actif, autonome ; AR-7 B1 : plus dans app_config). Aucune cle n'est creee. Le directeur seul
-- allume (R14).
--
-- Le compte (A-11, AR-1, AR-5) : cree DIRECTEMENT ICI, sans parcours. `auth.users` : une ligne, sans courriel, sans
-- telephone, sans mot de passe, `banned_until` tres loin ; AUCUNE ligne dans `auth.identities`. `public.profiles` : role
-- `accountant` (le moins cite), statut `disabled` (app_account_valid() est faux meme si une session existait),
-- `immutable_id` explicite : la migration ECHOUE si session_user <> 'postgres' (sinon le declencheur de matricule
-- ecrirait une ligne dans private.person_registrations et un matricule RA-… cherchable). Aucun declencheur d'INSERT de
-- profiles n'envoie de courriel ni de notification (releve). L'indicateur « compte officiel » : private.comptes_officiels.
--
-- Les portes de la DIRECTION se nomment `direction_praxis_*` (et non `praxis_*`) : R2 reserve le prefixe `praxis_*` aux
-- outils de Praxis, executables par le seul service_role ; les portes de la direction sont executables par
-- `authenticated` (garde positive : administrateur valide, double verification aal2).
--
-- Journal (R11) : `private.praxis_journal`, append-only PAR CONSTRUCTION : aucun droit pour les roles de l'API, aucune
-- fonction qui le modifie, declencheur contre la modification ; l'effacement n'est empeche que par les droits (ce fichier
-- n'emploie aucun des trois mots d'effacement). Une cle inconnue n'est PAS journalisee en base (la fonction Edge est
-- ouverte a Internet : une ligne par essai se transformerait en inondation) ; la fonction Edge la compte dans ses logs.
--
-- FICHIER SANS EFFACEMENT. Additif : des tables et fonctions neuves, deux retouches par ancrage (les listes de comptes de
-- la direction excluent les comptes officiels). Sans BEGIN/COMMIT de premier niveau.

DO $garde$
BEGIN
  IF session_user <> 'postgres' THEN
    RAISE EXCEPTION 'PRAXIS : session_user % : le compte se cree en postgres (sinon un matricule serait attribue)', session_user;
  END IF;
END
$garde$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_n integer, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION 'PRAXIS : ancre % trouvee % fois (% attendue)', p_nom, v_n, p_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- 1. Le compte officiel
INSERT INTO auth.users (id) VALUES ('9ae15000-0000-4000-8000-000000000001'::uuid);
DO $banni$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'banned_until') THEN
    EXECUTE 'UPDATE auth.users SET banned_until = ''2999-12-31 00:00:00+00''::timestamptz WHERE id = $1'
      USING '9ae15000-0000-4000-8000-000000000001'::uuid;
  END IF;
END
$banni$;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status)
VALUES ('9ae15000-0000-4000-8000-000000000001'::uuid, 'RA-OFFICIEL-PRAXIS', 'accountant'::public.app_role,
        'Praxis', 'IA', 'disabled'::public.account_status);

CREATE TABLE private.comptes_officiels (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles (id),
  code text NOT NULL UNIQUE CHECK (code IN ('praxis', 'staff')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
ALTER TABLE private.comptes_officiels ENABLE ROW LEVEL SECURITY;
INSERT INTO private.comptes_officiels (profile_id, code)
VALUES ('9ae15000-0000-4000-8000-000000000001'::uuid, 'praxis');

-- 2. Les cles, le journal, le calendrier
CREATE TABLE private.praxis_cles (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  libelle text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(libelle)) BETWEEN 1 AND 80),
  prefixe text NOT NULL,
  empreinte text NOT NULL UNIQUE CHECK (empreinte ~ '^[0-9a-f]{64}$'),
  usage text NOT NULL CHECK (usage IN ('chat', 'routine')),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_emission uuid NOT NULL,
  emise_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  revoquee_le timestamptz,
  revoquee_par uuid REFERENCES public.profiles (id),
  motif_revocation text,
  derniere_utilisation_le timestamptz,
  UNIQUE (emise_par, cle_emission),
  CONSTRAINT praxis_cles_expiration CHECK (expire_le > emise_le AND expire_le <= emise_le + interval '90 days'),
  CONSTRAINT praxis_cles_revocation_complete CHECK (
    (revoquee_le IS NULL AND revoquee_par IS NULL AND motif_revocation IS NULL)
    OR (revoquee_le IS NOT NULL AND revoquee_par IS NOT NULL
        AND pg_catalog.length(pg_catalog.btrim(motif_revocation)) BETWEEN 1 AND 240))
);
ALTER TABLE private.praxis_cles ENABLE ROW LEVEL SECURITY;

CREATE TABLE private.praxis_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cle_id uuid REFERENCES private.praxis_cles (id),
  emise_par uuid REFERENCES public.profiles (id),
  outil text NOT NULL CHECK (pg_catalog.length(outil) BETWEEN 1 AND 40),
  issue text NOT NULL CHECK (pg_catalog.length(issue) BETWEEN 1 AND 60),
  fil_id uuid,
  ids_touches uuid[] NOT NULL DEFAULT '{}'::uuid[],
  -- Le texte QUE PRAXIS A LUI-MEME ENVOYE (jamais le texte d'un tiers).
  texte_envoye text CHECK (texte_envoye IS NULL OR pg_catalog.length(texte_envoye) <= 3000),
  duree_ms integer,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
ALTER TABLE private.praxis_journal ENABLE ROW LEVEL SECURITY;
CREATE INDEX praxis_journal_recent_idx ON private.praxis_journal (outil, issue, cree_le DESC);
CREATE INDEX praxis_journal_fil_idx ON private.praxis_journal (fil_id, cree_le DESC) WHERE fil_id IS NOT NULL;

CREATE FUNCTION private.praxis_journal_ajout_seul()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $f$
BEGIN
  RAISE EXCEPTION 'PRAXIS : le journal est a ajout seul' USING ERRCODE = '42501';
END;
$f$;
CREATE TRIGGER praxis_journal_ajout_seul BEFORE UPDATE ON private.praxis_journal
  FOR EACH ROW EXECUTE FUNCTION private.praxis_journal_ajout_seul();

CREATE TABLE private.praxis_calendrier (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  sujet text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(sujet)) BETWEEN 1 AND 200),
  public_vise text NOT NULL CHECK (public_vise ~ '^[a-z][a-z0-9_]{1,39}$'),
  date_prevue date NOT NULL,
  recurrence text NOT NULL DEFAULT 'aucune' CHECK (recurrence IN ('aucune', 'hebdomadaire', 'mensuelle')),
  statut text NOT NULL DEFAULT 'prevu' CHECK (statut IN ('prevu', 'fait', 'annule')),
  cle_id uuid REFERENCES private.praxis_cles (id),
  cle_idempotence uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (cle_id, cle_idempotence)
);
ALTER TABLE private.praxis_calendrier ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE private.comptes_officiels, private.praxis_cles, private.praxis_journal, private.praxis_calendrier
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. Les reglages (AR-7 B1) : UNE ligne, dans une table PRIVEE (RLS, aucun droit pour les roles de l'API, contraintes de type et
-- de bornes). Ils ne sont PLUS dans app_config, ou tout administrateur sans double verification peut ecrire directement. Seule
-- direction_praxis_regler (aal2) les ecrit. Faux a l'installation ; le directeur seul les change.
CREATE TABLE private.praxis_reglages (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  actif boolean NOT NULL DEFAULT false,
  autonome boolean NOT NULL DEFAULT false,
  envois_par_heure integer NOT NULL DEFAULT 30 CHECK (envois_par_heure BETWEEN 1 AND 120),
  modifie_par uuid REFERENCES public.profiles (id),
  modifie_le timestamptz
);
ALTER TABLE private.praxis_reglages ENABLE ROW LEVEL SECURITY;
INSERT INTO private.praxis_reglages (id) VALUES (true);
REVOKE ALL ON TABLE private.praxis_reglages FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 4. Les aides privees
CREATE FUNCTION private.praxis_empreinte(p_secret text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(p_secret, 'UTF8')), 'hex');
$f$;

CREATE FUNCTION private.praxis_profil()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT o.profile_id FROM private.comptes_officiels o WHERE o.code = 'praxis';
$f$;

-- AR-7 I2 : les cotes de Praxis sont ceux de la PERSONNE QUI A EMIS LA CLE (SECRETAIRE-IA.md §3 : « dans le perimetre de la personne qui
-- l'a connecte ; celui du directeur voit les deux »). La super-administration (private.super_admin_kyc et l'exception active) a les deux.
CREATE FUNCTION private.praxis_cotes(p_emetteur uuid)
RETURNS public.gender[]
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM private.super_admin_kyc s WHERE s.profile_id = p_emetteur)
         AND EXISTS (SELECT 1 FROM public.app_config c WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb)
      THEN ARRAY['female', 'male']::public.gender[]
    ELSE coalesce((SELECT ARRAY[p.gender] FROM public.profiles p WHERE p.id = p_emetteur AND p.gender IS NOT NULL),
                  ARRAY[]::public.gender[])
  END;
$f$;

-- Une cle presentee : vivante, active, du bon usage, ET dont l'emetteur est TOUJOURS une direction active (AR-7 I5). Rend la cle, ses
-- cotes, ou la cause. Les causes de la cle elle-meme ne se distinguent pas pour l'appelant (cle_refusee) : le journal garde la vraie.
CREATE FUNCTION private.praxis_porte(p_secret text, p_ecrit boolean DEFAULT false)
RETURNS TABLE (cle_id uuid, emise_par uuid, usage text, cause text, cause_interne text, cotes public.gender[])
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_c private.praxis_cles%ROWTYPE;
  v_r private.praxis_reglages%ROWTYPE;
  v_cotes public.gender[];
BEGIN
  IF p_secret IS NULL OR p_secret !~ '^prx_[0-9a-f]{64}$' THEN
    RETURN QUERY SELECT NULL::uuid, NULL::uuid, NULL::text, 'cle_refusee'::text, 'cle_invalide'::text, NULL::public.gender[];
    RETURN;
  END IF;
  SELECT c.* INTO v_c FROM private.praxis_cles c WHERE c.empreinte = private.praxis_empreinte(p_secret);
  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::uuid, NULL::uuid, NULL::text, 'cle_refusee'::text, 'cle_inconnue'::text, NULL::public.gender[];
    RETURN;
  END IF;
  IF v_c.revoquee_le IS NOT NULL THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'cle_revoquee'::text, NULL::public.gender[];
    RETURN;
  END IF;
  IF v_c.expire_le <= pg_catalog.clock_timestamp() THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'cle_expiree'::text, NULL::public.gender[];
    RETURN;
  END IF;
  -- AR-7 I5 : la personne qui a emis la cle est toujours une direction active, de compte valide (non supprime, actif, acces non expire).
  IF NOT private.com_profil_valide(v_c.emise_par, 'admin') THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'emetteur_invalide'::text, NULL::public.gender[];
    RETURN;
  END IF;
  v_cotes := private.praxis_cotes(v_c.emise_par);
  IF pg_catalog.cardinality(v_cotes) = 0 THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'emetteur_sans_cote'::text, NULL::public.gender[];
    RETURN;
  END IF;
  SELECT r.* INTO v_r FROM private.praxis_reglages r;
  IF NOT coalesce(v_r.actif, false) THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'eteint'::text, 'eteint'::text, v_cotes;
    RETURN;
  END IF;
  IF v_c.usage = 'routine' AND NOT coalesce(v_r.autonome, false) THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'autonome_requis'::text, 'autonome_requis'::text, v_cotes;
    RETURN;
  END IF;
  UPDATE private.praxis_cles SET derniere_utilisation_le = pg_catalog.clock_timestamp() WHERE id = v_c.id;
  RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, NULL::text, NULL::text, v_cotes;
END;
$f$;

CREATE FUNCTION private.praxis_noter(p_cle uuid, p_emise_par uuid, p_outil text, p_issue text, p_fil uuid,
                                     p_ids uuid[], p_texte text, p_debut timestamptz)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $f$
  INSERT INTO private.praxis_journal (cle_id, emise_par, outil, issue, fil_id, ids_touches, texte_envoye, duree_ms)
  VALUES (p_cle, p_emise_par, p_outil, p_issue, p_fil, coalesce(p_ids, '{}'::uuid[]), p_texte,
          (EXTRACT(epoch FROM (pg_catalog.clock_timestamp() - p_debut)) * 1000)::integer);
$f$;

-- Le compte officiel (Praxis).
CREATE FUNCTION private.praxis_est_officiel(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce(EXISTS (SELECT 1 FROM private.comptes_officiels o WHERE o.profile_id = p_profil), false);
$f$;

-- AR-7 B2 : « l'equipe » d'un fil est tout compte que la MESSAGERIE tient pour partie de l'academie dans ce fil
-- (private.com_est_partie, cote « equipe »), jamais le seul role admin. Le compte Praxis n'en fait pas partie.
CREATE FUNCTION private.praxis_est_equipe(p_profil uuid, p_fil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce(EXISTS (
    SELECT 1 FROM public.com_fils f JOIN public.profiles p ON p.id = p_profil
     WHERE f.id = p_fil AND NOT private.praxis_est_officiel(p.id)
       AND private.com_est_partie(p.id, p.role::text, p.household_id, f.type_objet, 'equipe', NULL)), false);
$f$;

-- La personne (partie A du fil : le profil lui-meme, ou un tuteur de son foyer), selon la messagerie.
CREATE FUNCTION private.praxis_est_partie_a(p_profil uuid, p_fil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce(EXISTS (
    SELECT 1 FROM public.com_fils f JOIN public.profiles p ON p.id = p_profil
     WHERE f.id = p_fil AND NOT private.praxis_est_officiel(p.id)
       AND private.com_est_partie(p.id, p.role::text, p.household_id, f.type_objet, f.partie_a_nature, f.partie_a_id)), false);
$f$;

-- AR-7 B2 : LISTE POSITIVE des types de fil que Praxis peut lire et ecrire. Tout type absent est ferme, y compris un type cree plus
-- tard. Fermes : profilPaiement (IBAN, montants), candidature (fils de recrutement : com_paires y lit auth.uid()). `dossier` n'est
-- ouvert que pour un fil de FOYER (le tuteur, AR-3) : un dossier d'enseignant reste a l'equipe.
CREATE FUNCTION private.praxis_types_fil()
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT ARRAY['classe', 'eleve', 'dossier', 'remplacement']::text[];
$f$;

-- AR-7 I2 : le fil est du cote de la personne qui a emis la cle. Un profil : son genre ; un foyer : TOUS ses tuteurs (un foyer
-- sans tuteur, ou dont un tuteur a un genre inconnu ou de l'autre cote, est ferme).
CREATE FUNCTION private.praxis_fil_dans_cotes(p_fil uuid, p_cotes public.gender[])
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce((
    SELECT CASE f.partie_a_nature
      WHEN 'profil' THEN coalesce((SELECT p.gender = ANY (p_cotes) FROM public.profiles p WHERE p.id = f.partie_a_id), false)
      ELSE EXISTS (SELECT 1 FROM public.profiles g WHERE g.household_id = f.partie_a_id AND g.role = 'guardian'::public.app_role
                    AND g.deleted_at IS NULL)
           AND NOT EXISTS (SELECT 1 FROM public.profiles g WHERE g.household_id = f.partie_a_id
                            AND g.role = 'guardian'::public.app_role AND g.deleted_at IS NULL
                            AND (g.gender IS NULL OR NOT (g.gender = ANY (p_cotes))))
    END FROM public.com_fils f WHERE f.id = p_fil), false);
$f$;

-- La cause du refus d'un fil, ou NULL s'il est ouvert. Ordre : fil inconnu, hors academie, type ferme (liste positive), mineur
-- (AR-3 : un compte mineur ou d'age inconnu est partie du fil ou y a ecrit), cote.
CREATE FUNCTION private.praxis_fil_refus(p_fil uuid, p_cotes public.gender[])
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  f public.com_fils%ROWTYPE;
BEGIN
  SELECT x.* INTO f FROM public.com_fils x WHERE x.id = p_fil;
  IF NOT FOUND THEN RETURN 'fil_inconnu'; END IF;
  IF f.partie_b_nature IS DISTINCT FROM 'equipe' THEN RETURN 'hors_academie'; END IF;
  IF NOT (f.type_objet = ANY (private.praxis_types_fil()))
     OR (f.type_objet = 'dossier' AND f.partie_a_nature IS DISTINCT FROM 'foyer') THEN
    RETURN 'type_ferme';
  END IF;
  IF f.partie_a_nature = 'profil' AND private.com_est_mineur(f.partie_a_id) THEN RETURN 'mineur'; END IF;
  IF f.partie_a_nature = 'foyer' AND EXISTS (
       SELECT 1 FROM public.profiles g
        WHERE g.household_id = f.partie_a_id AND g.role = 'guardian'::public.app_role AND g.deleted_at IS NULL
          AND private.com_est_mineur(g.id)) THEN
    RETURN 'mineur';
  END IF;
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = f.id AND private.com_est_mineur(m.auteur_id)) THEN
    RETURN 'mineur';
  END IF;
  IF NOT private.praxis_fil_dans_cotes(f.id, p_cotes) THEN RETURN 'cote'; END IF;
  RETURN NULL;
END;
$f$;

-- Le role d'un auteur dans un fil, SANS identite : praxis, equipe, famille, enseignant, eleve (adulte), personne. Le prenom est un
-- texte de tiers : il sort dans contenu_tiers (AR-7 I6), jamais ici.
CREATE FUNCTION private.praxis_auteur_json(p_profil uuid, p_fil uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT CASE
    WHEN private.praxis_est_officiel(p_profil) THEN pg_catalog.jsonb_build_object('role', 'praxis')
    WHEN private.praxis_est_equipe(p_profil, p_fil) THEN pg_catalog.jsonb_build_object('role', 'equipe')
    ELSE (SELECT pg_catalog.jsonb_build_object(
            'role', CASE p.role WHEN 'guardian' THEN 'famille' WHEN 'teacher' THEN 'enseignant'
                                WHEN 'student' THEN 'eleve' ELSE 'personne' END,
            'cote', p.gender::text)
           FROM public.profiles p WHERE p.id = p_profil) END;
$f$;

REVOKE ALL ON FUNCTION
  private.praxis_empreinte(text), private.praxis_profil(), private.praxis_porte(text, boolean),
  private.praxis_noter(uuid, uuid, text, text, uuid, uuid[], text, timestamptz), private.praxis_cotes(uuid),
  private.praxis_est_officiel(uuid), private.praxis_est_equipe(uuid, uuid), private.praxis_est_partie_a(uuid, uuid),
  private.praxis_types_fil(), private.praxis_fil_dans_cotes(uuid, public.gender[]),
  private.praxis_fil_refus(uuid, public.gender[]), private.praxis_auteur_json(uuid, uuid), private.praxis_journal_ajout_seul()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 5. Les portes de la direction (administrateur valide, double verification)
CREATE FUNCTION public.direction_praxis_emettre_cle(p_libelle text, p_usage text, p_expire_le timestamptz, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_secret text;
  v_libelle text := pg_catalog.btrim(coalesce(p_libelle, ''));
  v_ex private.praxis_cles%ROWTYPE;
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR pg_catalog.length(v_libelle) NOT BETWEEN 1 AND 80 OR p_usage IS NULL
     OR p_usage NOT IN ('chat', 'routine') OR p_expire_le IS NULL
     OR p_expire_le <= pg_catalog.clock_timestamp() + interval '1 minute'
     OR p_expire_le > pg_catalog.clock_timestamp() + interval '90 days' THEN
    RAISE EXCEPTION 'parametres de cle invalides (expiration obligatoire, 90 jours au plus)' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-cle:' || p_cle::text, 0));
  SELECT c.* INTO v_ex FROM private.praxis_cles c WHERE c.emise_par = auth.uid() AND c.cle_emission = p_cle;
  IF FOUND THEN
    -- Rejeu : le secret n'est jamais remontre.
    RETURN pg_catalog.jsonb_build_object('id', v_ex.id, 'rejoue', true, 'prefixe', v_ex.prefixe,
                                         'expireLe', v_ex.expire_le);
  END IF;
  v_secret := 'prx_' || pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
  INSERT INTO private.praxis_cles (libelle, prefixe, empreinte, usage, emise_par, cle_emission, expire_le)
  VALUES (v_libelle, pg_catalog.left(v_secret, 12), private.praxis_empreinte(v_secret), p_usage, auth.uid(), p_cle,
          p_expire_le)
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access('praxis_cle_emise', 'private.praxis_cles', v_id::text,
    pg_catalog.jsonb_build_object('usage', p_usage, 'expireLe', p_expire_le));
  RETURN pg_catalog.jsonb_build_object('id', v_id, 'secret', v_secret, 'prefixe', pg_catalog.left(v_secret, 12),
                                       'expireLe', p_expire_le, 'rejoue', false);
END;
$f$;

CREATE FUNCTION public.direction_praxis_revoquer_cle(p_id uuid, p_motif text, p_cle uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
  RETURN true;
END;
$f$;

CREATE FUNCTION public.direction_praxis_regler(p_actif boolean, p_autonome boolean, p_envois_par_heure integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_envois_par_heure IS NOT NULL AND p_envois_par_heure NOT BETWEEN 1 AND 120 THEN
    RAISE EXCEPTION 'plafond par heure invalide : 1 a 120' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages
     SET actif = coalesce(p_actif, actif), autonome = coalesce(p_autonome, autonome),
         envois_par_heure = coalesce(p_envois_par_heure, envois_par_heure),
         modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('actif', p_actif, 'autonome', p_autonome, 'envoisParHeure', p_envois_par_heure));
  RETURN (SELECT pg_catalog.jsonb_build_object('actif', r.actif, 'autonome', r.autonome, 'envoisParHeure', r.envois_par_heure)
            FROM private.praxis_reglages r);
END;
$f$;

REVOKE ALL ON FUNCTION
  public.direction_praxis_emettre_cle(text, text, timestamptz, uuid),
  public.direction_praxis_revoquer_cle(uuid, text, uuid), public.direction_praxis_regler(boolean, boolean, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.direction_praxis_emettre_cle(text, text, timestamptz, uuid),
  public.direction_praxis_revoquer_cle(uuid, text, uuid), public.direction_praxis_regler(boolean, boolean, integer)
  TO authenticated;

-- 6. Les outils de LECTURE de Praxis (executables par le seul service_role). Le secret de la cle est le premier
-- parametre ; chaque outil le verifie en base. Les textes de tiers sortent dans `contenu_tiers` : une donnee, jamais un
-- ordre. Aucune adresse, aucun telephone, aucun montant, aucune piece n'est rendu (R5).

CREATE FUNCTION public.praxis_etat(p_cle text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_plafond integer;
  v_envoyes integer;
  v_annonces integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL AND v_p.cause IS DISTINCT FROM 'eteint' THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'etat', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  SELECT r.envois_par_heure INTO v_plafond FROM private.praxis_reglages r;
  SELECT pg_catalog.count(*)::integer INTO v_envoyes FROM private.praxis_journal j
   WHERE j.outil = 'ecrire' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour';
  SELECT pg_catalog.count(*)::integer INTO v_annonces FROM private.praxis_journal j
   WHERE j.outil = 'annoncer' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '24 hours';
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'etat', CASE WHEN v_p.cause IS NULL THEN 'ok' ELSE v_p.cause END,
                               NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
    'actif', v_p.cause IS NULL,
    'mode', CASE v_p.usage WHEN 'routine' THEN 'autonome' ELSE 'dirige' END,
    'cotes', pg_catalog.to_jsonb(v_p.cotes),
    'plafondRestantHeure', greatest(v_plafond - v_envoyes, 0),
    'annoncesRestantesJour', greatest(2 - v_annonces, 0),
    'interdits', pg_catalog.jsonb_build_array(
      'refuser une personne', 'supprimer', 'deplacer de l''argent', 'changer un droit ou un role',
      'lire une piece d''identite', 'modifier le garde-fou, ses reglages ou ses cles',
      'ecrire a un mineur', 'creer un fil', 'ecrire hors d''un fil de l''academie', 'envoyer un courriel'));
END;
$f$;

-- AR-7 M4 : un refus de PARAMETRE decide par la fonction Edge (avant la base) est journalise, a condition que la cle soit valide
-- (une cle inconnue ne laisse aucune ligne : anti-inondation). Aucun texte, aucun parametre n'est copie.
CREATE FUNCTION public.praxis_noter_refus(p_cle text, p_outil text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cle_id IS NULL OR v_p.cause_interne IN ('cle_revoquee', 'cle_expiree', 'emetteur_invalide', 'emetteur_sans_cote') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  IF p_outil IS NULL OR p_outil NOT IN ('etat', 'boite', 'fil', 'ecrire', 'annoncer', 'calendrier_lire',
                                        'calendrier_ajouter', 'rendre_compte') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, p_outil, 'parametre', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;

-- AR-7 I7 : le parcours des fils est borne AVANT le filtre : au plus 200 fils, les plus recents (tri sur le dernier message). Un
-- fil plus ancien que les 200 plus recents n'est pas liste ; c'est un choix de charge, documente.
CREATE FUNCTION public.praxis_boite(p_cle text, p_filtre text DEFAULT 'attend', p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_fils jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('attend', 'non_lu', 'tout') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  WITH recents AS (
    SELECT f.* FROM public.com_fils f
     WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
     ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id
     LIMIT 200
  ), base AS (
    SELECT f.id, f.type_objet, f.partie_a_nature, f.partie_a_id,
           d.auteur_id AS dernier_auteur, d.texte AS dernier_texte, d.envoye_le AS dernier_le,
           (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m
             WHERE m.fil_id = f.id AND (m.auteur_id = private.praxis_profil() OR private.praxis_est_equipe(m.auteur_id, f.id))) AS derniere_academie
      FROM recents f
      JOIN LATERAL (SELECT m.auteur_id, m.texte, m.envoye_le FROM public.com_messages m
                     WHERE m.fil_id = f.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1) d ON true
     WHERE private.praxis_fil_refus(f.id, v_p.cotes) IS NULL
  ), calc AS (
    SELECT b.*,
           private.praxis_est_partie_a(b.dernier_auteur, b.id) AS attend,
           (SELECT pg_catalog.count(*) FROM public.com_messages m
             WHERE m.fil_id = b.id AND private.praxis_est_partie_a(m.auteur_id, b.id)
               AND m.envoye_le > coalesce(b.derniere_academie, '-infinity'::timestamptz))::integer AS sans_reponse
      FROM base b
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', c.id, 'type', c.type_objet,
           'interlocuteur', CASE c.partie_a_nature
              WHEN 'profil' THEN private.praxis_auteur_json(c.partie_a_id, c.id)
              ELSE pg_catalog.jsonb_build_object('role', 'famille') END,
           'dernier_auteur', private.praxis_auteur_json(c.dernier_auteur, c.id),
           -- Tout texte qui n'est pas de Praxis (prenoms compris, messages de l'equipe compris) est une DONNEE de tiers.
           'contenu_tiers', CASE WHEN c.dernier_auteur = private.praxis_profil() THEN NULL
              ELSE pg_catalog.jsonb_build_object(
                'prenoms', CASE c.partie_a_nature
                  WHEN 'profil' THEN (SELECT pg_catalog.jsonb_build_array(p.first_name) FROM public.profiles p WHERE p.id = c.partie_a_id)
                  ELSE coalesce((SELECT pg_catalog.jsonb_agg(g.first_name ORDER BY g.first_name, g.id) FROM public.profiles g
                                  WHERE g.household_id = c.partie_a_id AND g.role = 'guardian'::public.app_role
                                    AND g.deleted_at IS NULL), '[]'::jsonb) END,
                'dernier_message', pg_catalog.left(c.dernier_texte, 300)) END,
           'attente_heures', CASE WHEN c.attend
              THEN (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.dernier_le) / 3600)::integer END,
           'sans_reponse', c.sans_reponse,
           'repris_par_equipe', EXISTS (SELECT 1 FROM public.com_messages m
             WHERE m.fil_id = c.id AND private.praxis_est_equipe(m.auteur_id, c.id)
               AND m.envoye_le > coalesce((SELECT pg_catalog.max(x.envoye_le) FROM public.com_messages x
                                            WHERE x.fil_id = c.id AND x.auteur_id = private.praxis_profil()),
                                          'infinity'::timestamptz))
         ) ORDER BY c.dernier_le DESC), '[]'::jsonb)
    INTO v_fils
    FROM (SELECT * FROM calc c2
           WHERE p_filtre = 'tout' OR (p_filtre = 'attend' AND c2.attend) OR (p_filtre = 'non_lu' AND c2.sans_reponse > 0)
           ORDER BY c2.dernier_le DESC LIMIT p_limite) c;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('fils', v_fils);
END;
$f$;

CREATE FUNCTION public.praxis_fil(p_cle text, p_fil uuid, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_refus text;
  v_msgs jsonb;
  v_dernier uuid;
  v_derniere_praxis timestamptz;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_praxis FROM public.com_messages m
   WHERE m.fil_id = p_fil AND m.auteur_id = private.praxis_profil();
  SELECT m.auteur_id INTO v_dernier FROM public.com_messages m WHERE m.fil_id = p_fil
   ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1;
  SELECT coalesce(pg_catalog.jsonb_agg(x.j ORDER BY x.le), '[]'::jsonb) INTO v_msgs
    FROM (SELECT m.envoye_le AS le, pg_catalog.jsonb_build_object(
                   'auteur', private.praxis_auteur_json(m.auteur_id, p_fil),
                   'est_praxis', m.auteur_id = private.praxis_profil(),
                   'envoye_le', m.envoye_le)
                 || CASE
                      WHEN EXISTS (SELECT 1 FROM public.com_message_images i WHERE i.message_id = m.id)
                        THEN pg_catalog.jsonb_build_object('image', true)
                      WHEN m.auteur_id = private.praxis_profil()
                        THEN pg_catalog.jsonb_build_object('texte', pg_catalog.left(m.texte, 1500))
                      -- AR-7 I6 : tout texte qui n'est pas de Praxis (message de la personne OU de l'equipe, prenom) est une donnee.
                      ELSE pg_catalog.jsonb_build_object('contenu_tiers', pg_catalog.jsonb_build_object(
                             'prenom', (SELECT p.first_name FROM public.profiles p WHERE p.id = m.auteur_id),
                             'texte', pg_catalog.left(m.texte, 1500))) END AS j
            FROM public.com_messages m WHERE m.fil_id = p_fil
           ORDER BY m.envoye_le DESC, m.id DESC LIMIT p_limite) x;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', 'ok', p_fil, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
    'fil', p_fil,
    'messages', v_msgs,
    'dernier_auteur', private.praxis_auteur_json(v_dernier, p_fil),
    'repris_par_equipe', v_derniere_praxis IS NOT NULL AND EXISTS (
       SELECT 1 FROM public.com_messages m
        WHERE m.fil_id = p_fil AND private.praxis_est_equipe(m.auteur_id, p_fil) AND m.envoye_le > v_derniere_praxis));
END;
$f$;

CREATE FUNCTION public.praxis_rendre_compte(p_cle text, p_heures integer DEFAULT 24)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_envois jsonb;
  v_refus integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_heures IS NULL OR p_heures NOT BETWEEN 1 AND 168 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'outil', j.outil, 'fil', j.fil_id, 'extrait', pg_catalog.left(j.texte_envoye, 300), 'heure', j.cree_le)
           ORDER BY j.cree_le DESC), '[]'::jsonb) INTO v_envois
    FROM (SELECT * FROM private.praxis_journal x
           WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue = 'ok'
             AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures)
           ORDER BY x.cree_le DESC LIMIT 50) j;
  SELECT pg_catalog.count(*)::integer INTO v_refus FROM private.praxis_journal x
   WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue <> 'ok' AND x.issue <> 'rejoue'
     AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('envoye', v_envois, 'refuses', v_refus,
    'laisse_en_attente', (SELECT pg_catalog.count(*)::integer FROM (
        SELECT f.id FROM public.com_fils f
         WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
         ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id LIMIT 200) r
        WHERE private.praxis_fil_refus(r.id, v_p.cotes) IS NULL
          AND private.praxis_est_partie_a((SELECT m.auteur_id FROM public.com_messages m
                WHERE m.fil_id = r.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1), r.id)));
END;
$f$;

CREATE FUNCTION public.praxis_calendrier_lire(p_cle text, p_du date, p_au date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_lire', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_du IS NULL OR p_au IS NULL OR p_au < p_du OR p_au - p_du > 366 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('sujets', coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', c.id, 'sujet', c.sujet, 'public', c.public_vise, 'date', c.date_prevue,
             'recurrence', c.recurrence, 'statut', c.statut) ORDER BY c.date_prevue, c.id)
      FROM (SELECT * FROM private.praxis_calendrier x WHERE x.date_prevue BETWEEN p_du AND p_au
             ORDER BY x.date_prevue, x.id LIMIT 100) c), '[]'::jsonb));
END;
$f$;

CREATE FUNCTION public.praxis_calendrier_ajouter(p_cle text, p_sujet text, p_public text, p_date date,
                                                 p_recurrence text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_sujet text := pg_catalog.btrim(coalesce(p_sujet, ''));
  v_id uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_ajouter', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_cle_idempotence IS NULL OR pg_catalog.length(v_sujet) NOT BETWEEN 1 AND 200 OR p_public IS NULL
     OR p_public !~ '^[a-z][a-z0-9_]{1,39}$' OR p_date IS NULL
     OR p_date < current_date - 1 OR p_date > current_date + 730
     OR coalesce(p_recurrence, 'aucune') NOT IN ('aucune', 'hebdomadaire', 'mensuelle') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_ajouter', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_calendrier c WHERE c.statut = 'prevu') >= 500 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_ajouter', 'plafond', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond');
  END IF;
  INSERT INTO private.praxis_calendrier (sujet, public_vise, date_prevue, recurrence, cle_id, cle_idempotence)
  VALUES (v_sujet, p_public, p_date, coalesce(p_recurrence, 'aucune'), v_p.cle_id, p_cle_idempotence)
  ON CONFLICT (cle_id, cle_idempotence) DO NOTHING
  RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    SELECT c.id INTO v_id FROM private.praxis_calendrier c
     WHERE c.cle_id = v_p.cle_id AND c.cle_idempotence = p_cle_idempotence;
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'calendrier_ajouter', 'ok', NULL, ARRAY[v_id], NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('id', v_id);
END;
$f$;

-- NON LIVRE EN PX-1 : `alerter_responsable` (passer la main a la direction par une notification), DIFFERE par le pilote
-- (16/11/2026). Aucun evenement de notification n'est fait pour cet usage ; sa migration etendra
-- `notifications_evenement_check` en reprenant la liste ENTIERE de la production. Ecart depot / production releve ici : la
-- contrainte rejouee depuis `supabase/migrations` n'accepte pas `annonce_direction`, la production l'accepte (le seul
-- evenement qui differe) ; la migration qui l'ajoute n'est pas dans le depot.

REVOKE ALL ON FUNCTION
  public.praxis_etat(text), public.praxis_boite(text, text, integer), public.praxis_fil(text, uuid, integer),
  public.praxis_rendre_compte(text, integer), public.praxis_calendrier_lire(text, date, date),
  public.praxis_calendrier_ajouter(text, text, text, date, text, uuid), public.praxis_noter_refus(text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.praxis_etat(text), public.praxis_boite(text, text, integer), public.praxis_fil(text, uuid, integer),
  public.praxis_rendre_compte(text, integer), public.praxis_calendrier_lire(text, date, date),
  public.praxis_calendrier_ajouter(text, text, text, date, text, uuid), public.praxis_noter_refus(text, text)
  TO service_role;

-- 7. R13 : les listes de comptes de la direction n'affichent pas les comptes officiels (retouche par ancrage).
DO $retouche$
DECLARE
  v_f regprocedure;
  v_def text;
  v_com text;
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY['public.comptes_admin()', 'public.comptes_admin_par_role()'] LOOP
    v_f := v_sig::regprocedure;
    v_def := pg_catalog.pg_get_functiondef(v_f);
    IF pg_catalog.strpos(v_def, 'comptes_officiels') = 0 THEN
      v_def := pg_temp.remplacer(v_def,
        '    and not app_private.compte_candidat_hors_portee(p.id)',
        '    and not app_private.compte_candidat_hors_portee(p.id)
    and not exists (select 1 from private.comptes_officiels co where co.profile_id = p.id)', 1, 'comptes.officiels ' || v_sig);
      EXECUTE v_def;
      v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
      IF v_com LIKE '%md5_functiondef=%' THEN
        v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
        EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
      END IF;
    END IF;
  END LOOP;
END;
$retouche$;

DO $postflight$
DECLARE
  v_identites bigint;
BEGIN
  IF (SELECT r.actif FROM private.praxis_reglages r) IS NOT FALSE
     OR (SELECT r.autonome FROM private.praxis_reglages r) IS NOT FALSE
     OR (SELECT pg_catalog.count(*) FROM private.praxis_reglages) <> 1
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_etat(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_etat(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.praxis_etat(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_etat(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.praxis_porte(text,boolean)', 'EXECUTE')
     OR EXISTS (SELECT 1 FROM private.praxis_cles) THEN
    RAISE EXCEPTION 'PRAXIS : interrupteur, droits ou cles incorrects apres installation';
  END IF;
  IF pg_catalog.to_regclass('auth.identities') IS NOT NULL THEN
    EXECUTE 'SELECT pg_catalog.count(*) FROM auth.identities WHERE user_id = $1'
      USING '9ae15000-0000-4000-8000-000000000001'::uuid INTO v_identites;
    IF v_identites > 0 THEN
      RAISE EXCEPTION 'PRAXIS : une identite de connexion existe pour le compte officiel';
    END IF;
  END IF;
  IF EXISTS (SELECT 1 FROM private.person_registrations r
              WHERE r.profile_id = '9ae15000-0000-4000-8000-000000000001'::uuid) THEN
    RAISE EXCEPTION 'PRAXIS : un matricule a ete attribue au compte officiel';
  END IF;
END
$postflight$;
