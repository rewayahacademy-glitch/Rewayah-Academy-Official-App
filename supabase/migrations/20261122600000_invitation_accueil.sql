-- INVITATION-ACCUEIL (09/11/2026, lot correctif INVITATION-COMPTE ; conception
-- acceptee par le pilote le 09/11).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- le pilote l'installe tel quel. Migration additive (B6) : aucune signature
-- publique existante ne change, aucune colonne n'est retiree.
--
-- Constat (production, 09/11) : la personne invitee dans un foyer ne parvient
-- pas a creer son compte. Cause premiere : son e-mail (07/11) precede le code
-- de foyer (20261111000000) et ne le porte pas ; le titulaire renverra
-- l'invitation apres cette fusion (`renvoyer_invitation_conjoint`). Deux
-- defauts restent sur le chemin, meme avec un code :
--
-- B. `invitation_compte_autoriser` consommait le code d'un foyer (et d'un
--    candidat) AVANT la creation du compte par la fonction Edge : si
--    `auth.admin.createUser` echouait, le code etait brule et chaque nouvel
--    essai rendait « rien ». Correction : `invitation_compte_autoriser`
--    verifie sans consommer ; `invitation_compte_consommer` (service_role
--    seul) consomme APRES la creation du compte, appele par la fonction Edge
--    sur « cree ».
--
-- C. Le compte cree n'a pas de profil : l'application l'envoyait au
--    questionnaire des familles, et `mon_invitation_en_cours` (0053) exige un
--    profil `guardian` : l'invitation restait invisible. Correction, sur le
--    modele de `inscrire_comptable_invite` (20261017160200) :
--    - `mon_invitation_accueil()` : pour une session SANS profil, le role
--      pour lequel son adresse confirmee est invitee (foyer, enseignant,
--      comptable, candidat) ; pour le foyer, le prenom de la personne qui
--      invite. Rien d'autre, rien n'est consomme.
--    - `accepter_invitation_nouveau_compte(prenom, nom, genre, cle)` : pour une
--      session sans profil, invitee dans un foyer. Decision du directeur du
--      09/11/2026 (option 3, transmise par le pilote) : le profil `guardian`
--      n'est cree QU'A l'acceptation, dans la meme transaction que le
--      rattachement au foyer qui invite. Aucun foyer d'attente : un refus, une
--      annulation ou une echeance ne laissent aucun compte actif hors
--      admission (point bloquant du garde-cap). Memes controles que
--      `repondre_invitation_conjoint` (0053) : adresse confirmee, invitation
--      en attente et non echue, foyer actif dont la personne qui invite est
--      titulaire.
--    - `refuser_invitation_sans_compte(cle)` : la meme personne refuse sans
--      rien creer. L'invitation passe a `annulee` (et non `refusee`) : la
--      contrainte `invitation_reponse_coherente` et la cle etrangere de
--      `repondu_par` (0053) exigent un profil pour `refusee`, et les changer
--      demanderait un mot d'effacement. Le journal sensible dit « refusee
--      sans compte ».
--
-- Rattrapage des invitations sans code : aucun ici. 20261111000000 (section
-- 2) a deja emis un code pour chaque invitation en attente, sans e-mail ; le
-- titulaire le renvoie (`renvoyer_invitation_conjoint`).


-- ---------------------------------------------------------------------------
-- 0. Preflight : la fonction remplacee est celle du depot (20261111000000).
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.md5((SELECT p.prosrc FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.invitation_compte_autoriser(text,text,text)'::regprocedure))
     <> 'c64067affbb87232336fb12d61505057' THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL : invitation_compte_autoriser a change depuis le depot';
  END IF;
  IF to_regprocedure('public.invitation_compte_consommer(text,text,text)') IS NOT NULL
     OR to_regprocedure('public.mon_invitation_accueil()') IS NOT NULL
     OR to_regprocedure('public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid)') IS NOT NULL
     OR to_regprocedure('public.refuser_invitation_sans_compte(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL : deja installee';
  END IF;
END
$preflight$;


-- ---------------------------------------------------------------------------
-- 1. B : l'autorisation verifie sans consommer.
-- ---------------------------------------------------------------------------
-- Memes conditions qu'avant, mot pour mot, moins les deux UPDATE de
-- consommation (foyer, candidat), passes dans `invitation_compte_consommer`.
CREATE OR REPLACE FUNCTION public.invitation_compte_autoriser(p_type text, p_code text, p_email text)
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
    -- Adresse vide, ou deja un compte : rien a creer.
    RETURN pg_catalog.jsonb_build_object('autorise', false);
  END IF;

  IF p_type = 'foyer' THEN
    SELECT c.* INTO v_ligne
      FROM app_private.codes_invitation_foyer c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code);
    IF NOT FOUND OR v_ligne.remplace_le IS NOT NULL OR v_ligne.utilise_le IS NOT NULL THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
    SELECT i.* INTO v_invitation FROM public.invitations_foyer i
     WHERE i.id = v_ligne.invitation_id;
    IF NOT FOUND OR v_invitation.statut <> 'en_attente'
       OR v_invitation.expire_le <= pg_catalog.now()
       OR v_invitation.email_invite <> v_email THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
    PERFORM public.log_sensitive_access(
      'invitation_compte_autorise', 'invitations_foyer', v_invitation.id::text,
      pg_catalog.jsonb_build_object('type', 'foyer', 'foyer_id', v_invitation.foyer_id));
    RETURN pg_catalog.jsonb_build_object('autorise', true);
  ELSIF p_type = 'candidat' THEN
    SELECT c.* INTO v_candidat
      FROM app_private.codes_invitation_candidat c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code);
    IF NOT FOUND OR v_candidat.remplace_le IS NOT NULL OR v_candidat.utilise_le IS NOT NULL
       OR v_candidat.expire_le <= pg_catalog.now() OR v_candidat.adresse <> v_email
       OR NOT EXISTS (SELECT 1 FROM public.formulaires_reponses r
                       WHERE r.courriel = v_email AND r.etat = 'active'
                         AND r.candidature_id IS NULL) THEN
      RETURN pg_catalog.jsonb_build_object('autorise', false);
    END IF;
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


-- ---------------------------------------------------------------------------
-- 2. B : la consommation, APRES la creation du compte.
-- ---------------------------------------------------------------------------
-- Appelee par la fonction Edge `invitation-compte` quand `createUser` a cree
-- le compte. Reverifie le code (valide, non utilise, non remplace, non echu,
-- de cette adresse) et exige cette fois que l'adresse AIT un compte : sans
-- compte cree, rien n'est consomme. Usage unique : la ligne est verrouillee.
-- Enseignant et comptable : rien ici, leur code est consomme par leur
-- inscription (`inscrire_enseignant_invite`, `inscrire_comptable_invite`).
CREATE FUNCTION public.invitation_compte_consommer(p_type text, p_code text, p_email text)
RETURNS boolean
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
BEGIN
  IF v_email = '' OR NOT EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = v_email) THEN
    -- Aucun compte pour cette adresse : la creation a echoue, le code reste.
    RETURN false;
  END IF;

  IF p_type = 'foyer' THEN
    SELECT c.* INTO v_ligne
      FROM app_private.codes_invitation_foyer c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code)
     FOR UPDATE;
    IF NOT FOUND OR v_ligne.remplace_le IS NOT NULL OR v_ligne.utilise_le IS NOT NULL THEN
      RETURN false;
    END IF;
    SELECT i.* INTO v_invitation FROM public.invitations_foyer i
     WHERE i.id = v_ligne.invitation_id FOR UPDATE;
    IF NOT FOUND OR v_invitation.statut <> 'en_attente'
       OR v_invitation.expire_le <= pg_catalog.now()
       OR v_invitation.email_invite <> v_email THEN
      RETURN false;
    END IF;
    UPDATE app_private.codes_invitation_foyer
       SET utilise_le = pg_catalog.clock_timestamp()
     WHERE id = v_ligne.id;
    PERFORM public.log_sensitive_access(
      'invitation_compte_consomme', 'invitations_foyer', v_invitation.id::text,
      pg_catalog.jsonb_build_object('type', 'foyer', 'foyer_id', v_invitation.foyer_id));
    RETURN true;
  ELSIF p_type = 'candidat' THEN
    SELECT c.* INTO v_candidat
      FROM app_private.codes_invitation_candidat c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code)
     FOR UPDATE;
    IF NOT FOUND OR v_candidat.remplace_le IS NOT NULL OR v_candidat.utilise_le IS NOT NULL
       OR v_candidat.expire_le <= pg_catalog.now() OR v_candidat.adresse <> v_email THEN
      RETURN false;
    END IF;
    UPDATE app_private.codes_invitation_candidat
       SET utilise_le = pg_catalog.clock_timestamp()
     WHERE id = v_candidat.id;
    PERFORM public.log_sensitive_access(
      'invitation_compte_consomme', 'invitations_candidat', NULL,
      pg_catalog.jsonb_build_object('type', 'candidat'));
    RETURN true;
  END IF;
  RETURN false;
END;
$function$;
ALTER FUNCTION public.invitation_compte_consommer(text, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.invitation_compte_consommer(text, text, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitation_compte_consommer(text, text, text) TO service_role;


-- ---------------------------------------------------------------------------
-- 3. C : le role pour lequel une session sans profil est invitee.
-- ---------------------------------------------------------------------------
-- Lecture seule. Session connectee, adresse confirmee, AUCUN profil (une
-- session qui a deja un profil n'a plus d'accueil a recevoir : « aucune »).
-- Ordre : foyer, enseignant, comptable, candidat. Ne rend que le role et,
-- pour le foyer, le prenom de la personne qui invite ; jamais un code, une
-- adresse, un foyer ni une date.
CREATE FUNCTION public.mon_invitation_accueil()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_email text;
  v_confirmee timestamptz;
  v_prenom text;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501';
  END IF;
  SELECT pg_catalog.lower(u.email), u.email_confirmed_at INTO v_email, v_confirmee
    FROM auth.users u WHERE u.id = v_user;
  IF v_email IS NULL OR v_confirmee IS NULL
     OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_user) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'aucune');
  END IF;

  SELECT inv.first_name INTO v_prenom
    FROM public.invitations_foyer i
    JOIN public.profiles inv ON inv.id = i.invite_par
   WHERE i.email_invite = v_email AND i.statut = 'en_attente'
     AND i.expire_le > pg_catalog.now()
   ORDER BY i.created_at DESC
   LIMIT 1;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'invite', 'role', 'foyer',
      'prenom_invitant', nullif(pg_catalog.btrim(coalesce(v_prenom, '')), ''));
  END IF;
  IF EXISTS (SELECT 1 FROM public.invitations_enseignant i
              WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
                AND i.expire_le > pg_catalog.now()) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'invite', 'role', 'enseignant');
  END IF;
  IF EXISTS (SELECT 1 FROM public.invitations_comptable i
              WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
                AND i.expire_le > pg_catalog.now()) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'invite', 'role', 'comptable');
  END IF;
  IF EXISTS (SELECT 1 FROM public.formulaires_reponses r
              WHERE r.courriel = v_email AND r.etat = 'active'
                AND r.candidature_id IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'invite', 'role', 'candidat');
  END IF;
  RETURN pg_catalog.jsonb_build_object('etat', 'aucune');
END;
$function$;
ALTER FUNCTION public.mon_invitation_accueil() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mon_invitation_accueil() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.mon_invitation_accueil() TO authenticated;


-- ---------------------------------------------------------------------------
-- 4. C : accepter en creant le compte, ou refuser sans rien creer.
-- ---------------------------------------------------------------------------
-- Session connectee, adresse confirmee, AUCUN profil. Le profil `guardian`
-- (actif) nait dans le foyer qui invite, dans la meme transaction que
-- l'acceptation ; sinon rien n'est cree. Idempotent par `p_cle` : la meme
-- personne qui rappelle apres une acceptation lit « acceptee ».
-- Etats : acceptee, perimee, non_acceptable.
CREATE FUNCTION public.accepter_invitation_nouveau_compte(
  p_prenom text, p_nom text, p_genre public.gender, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_confirmee timestamptz;
  v_invitation public.invitations_foyer%ROWTYPE;
  v_foyer public.households%ROWTYPE;
  v_titulaire text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle requise' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.lower(u.email), u.email_confirmed_at INTO v_email, v_confirmee
    FROM auth.users u WHERE u.id = v_uid;
  IF v_email IS NULL OR v_confirmee IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
  END IF;

  SELECT i.* INTO v_invitation
    FROM public.invitations_foyer i
   WHERE i.email_invite = v_email
     AND i.statut IN ('en_attente', 'acceptee', 'refusee', 'annulee', 'expiree')
   ORDER BY i.created_at DESC
   LIMIT 1
   FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
  END IF;

  -- Rappel apres une acceptation par cette meme personne : meme reponse.
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid) THEN
    IF v_invitation.statut = 'acceptee' AND v_invitation.repondu_par = v_uid THEN
      RETURN pg_catalog.jsonb_build_object('etat', 'acceptee',
        'enregistree_le', v_invitation.repondu_le);
    END IF;
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF v_invitation.statut IN ('annulee', 'expiree') THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'perimee');
  ELSIF v_invitation.statut <> 'en_attente' THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
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

  SELECT h.* INTO v_foyer FROM public.households h
   WHERE h.id = v_invitation.foyer_id
     AND h.primary_guardian_id = v_invitation.invite_par
     AND h.status = 'active' AND h.deleted_at IS NULL
   FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF coalesce(pg_catalog.btrim(p_prenom), '') = '' OR coalesce(pg_catalog.btrim(p_nom), '') = ''
     OR p_genre IS NULL THEN
    RAISE EXCEPTION 'prenom, nom et genre sont requis' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  VALUES (v_uid, NULL, 'guardian', v_invitation.foyer_id,
    pg_catalog.btrim(p_prenom), pg_catalog.btrim(p_nom), p_genre, 'active');
  UPDATE public.invitations_foyer
     SET statut = 'acceptee', repondu_par = v_uid, repondu_le = pg_catalog.now(),
         cle_reponse = p_cle, updated_at = pg_catalog.now()
   WHERE id = v_invitation.id AND statut = 'en_attente';

  SELECT p.first_name INTO v_titulaire FROM public.profiles p WHERE p.id = v_invitation.invite_par;
  PERFORM public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    pg_catalog.jsonb_build_object('role', 'guardian', 'source', 'invitation_foyer'));
  PERFORM public.log_sensitive_access(
    'invitation_conjoint_acceptee', 'invitations_foyer', v_invitation.id::text,
    pg_catalog.jsonb_build_object('foyer_id', v_invitation.foyer_id, 'nouveau_compte', true));
  RETURN pg_catalog.jsonb_build_object('etat', 'acceptee',
    'prenom_titulaire', v_titulaire, 'enregistree_le', pg_catalog.now());
END;
$function$;
ALTER FUNCTION public.accepter_invitation_nouveau_compte(text, text, public.gender, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.accepter_invitation_nouveau_compte(text, text, public.gender, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.accepter_invitation_nouveau_compte(text, text, public.gender, uuid) TO authenticated;

-- Refus sans compte : rien n'est cree. L'invitation en attente de l'adresse
-- passe a `annulee` (voir l'en-tete : `refusee` exige un profil) et son
-- e-mail en attente est annule. Etats : refusee, perimee, non_acceptable.
CREATE FUNCTION public.refuser_invitation_sans_compte(p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_confirmee timestamptz;
  v_invitation public.invitations_foyer%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle requise' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.lower(u.email), u.email_confirmed_at INTO v_email, v_confirmee
    FROM auth.users u WHERE u.id = v_uid;
  IF v_email IS NULL OR v_confirmee IS NULL
     OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid) THEN
    -- Un compte qui a un profil refuse par repondre_invitation_conjoint.
    RETURN pg_catalog.jsonb_build_object('etat', 'non_acceptable');
  END IF;
  SELECT i.* INTO v_invitation
    FROM public.invitations_foyer i
   WHERE i.email_invite = v_email AND i.statut = 'en_attente'
   ORDER BY i.created_at DESC
   LIMIT 1
   FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'perimee');
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
  UPDATE public.invitations_foyer
     SET statut = 'annulee', cle_reponse = p_cle, updated_at = pg_catalog.now()
   WHERE id = v_invitation.id AND statut = 'en_attente';
  UPDATE public.email_outbox_invitation_foyer
     SET statut = 'annule'
   WHERE invitation_id = v_invitation.id AND statut = 'en_attente';
  PERFORM public.log_sensitive_access(
    'invitation_conjoint_refusee_sans_compte', 'invitations_foyer', v_invitation.id::text,
    pg_catalog.jsonb_build_object('foyer_id', v_invitation.foyer_id));
  RETURN pg_catalog.jsonb_build_object('etat', 'refusee', 'enregistree_le', pg_catalog.now());
END;
$function$;
ALTER FUNCTION public.refuser_invitation_sans_compte(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.refuser_invitation_sans_compte(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.refuser_invitation_sans_compte(uuid) TO authenticated;


-- ---------------------------------------------------------------------------
-- 5. Commentaires F86 et postflight.
-- ---------------------------------------------------------------------------
COMMENT ON FUNCTION public.invitation_compte_autoriser(text, text, text) IS
  'F86: signature=public.invitation_compte_autoriser(text,text,text); md5_functiondef=82a23474390acb3bce15ef81403eff6f; guard_type=SERVICE_ROLE_ONLY; owner=postgres; search_path=""; date=2026-11-09. Fonction Edge invitation-compte : vrai seulement pour un code valide, non utilise, non revoque, non echu, de cette adresse, et une adresse sans compte. Ne consomme rien (INVITATION-ACCUEIL) : invitation_compte_consommer apres la creation du compte.';
COMMENT ON FUNCTION public.invitation_compte_consommer(text, text, text) IS
  'F86: signature=public.invitation_compte_consommer(text,text,text); md5_functiondef=ec1fbb63fc01853d1284f75a2f96d865; guard_type=SERVICE_ROLE_ONLY; owner=postgres; search_path=""; date=2026-11-09. Fonction Edge invitation-compte, apres createUser reussi : consomme le code d''un foyer ou d''un candidat, seulement si l''adresse a un compte. Usage unique.';
COMMENT ON FUNCTION public.mon_invitation_accueil() IS
  'F86: signature=public.mon_invitation_accueil(); md5_functiondef=a1f130d69b3d226c33af722970661341; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-09. Lecture seule, session sans profil, adresse confirmee : le role invite (foyer, enseignant, comptable, candidat) et le prenom de la personne qui invite au foyer. Rien n''est consomme.';
COMMENT ON FUNCTION public.accepter_invitation_nouveau_compte(text, text, public.gender, uuid) IS
  'F86: signature=public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid); md5_functiondef=d86afc57c0239d15aeefbb7c984bf757; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-09. Session sans profil, adresse confirmee : cree le profil guardian actif DANS le foyer qui invite et accepte l''invitation, dans la meme transaction (memes controles que repondre_invitation_conjoint). Aucun foyer d''attente.';
COMMENT ON FUNCTION public.refuser_invitation_sans_compte(uuid) IS
  'F86: signature=public.refuser_invitation_sans_compte(uuid); md5_functiondef=d8cac72d30605179fb51453aa90baca9; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-11-09. Session sans profil, adresse confirmee : refuse l''invitation en attente sans rien creer (statut annulee, refusee exigeant un profil).';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.invitation_compte_autoriser(text,text,text)'::regprocedure)) <> '82a23474390acb3bce15ef81403eff6f'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.invitation_compte_consommer(text,text,text)'::regprocedure)) <> 'ec1fbb63fc01853d1284f75a2f96d865'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mon_invitation_accueil()'::regprocedure)) <> 'a1f130d69b3d226c33af722970661341'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid)'::regprocedure)) <> 'd86afc57c0239d15aeefbb7c984bf757'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.refuser_invitation_sans_compte(uuid)'::regprocedure)) <> 'd8cac72d30605179fb51453aa90baca9' THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL : empreinte F86 invalide';
  END IF;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.invitation_compte_autoriser(text,text,text)'::regprocedure,
    'public.invitation_compte_consommer(text,text,text)'::regprocedure,
    'public.mon_invitation_accueil()'::regprocedure,
    'public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid)'::regprocedure,
    'public.refuser_invitation_sans_compte(uuid)'::regprocedure] LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = v_oid AND p.prosecdef
            AND p.proowner = 'postgres'::regrole
            AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'INVITATION-ACCUEIL : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.invitation_compte_consommer(text,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.invitation_compte_autoriser(text,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.invitation_compte_consommer(text,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mon_invitation_accueil()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.refuser_invitation_sans_compte(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.mon_invitation_accueil()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.accepter_invitation_nouveau_compte(text,text,public.gender,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.refuser_invitation_sans_compte(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'INVITATION-ACCUEIL : droits invalides';
  END IF;
END
$postflight$;
