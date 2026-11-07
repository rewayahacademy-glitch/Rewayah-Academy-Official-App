-- INVITATIONS-PERSONNELLES (lot 7 du plan des trois salles, 07/11/2026 ;
-- note de B validee par le garde-cap le 07/11 vers 20:55 UTC, plage
-- 20261120000000 a 20261120099999 reservee, PR 306).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ; le
-- pilote l'installe tel quel. Additif (B6) : l'ancien code de production
-- continue de marcher (aucune signature changee ; une fonction retouchee par
-- ancre, revoquer_invitation_enseignant, garde ses reponses).
--
-- Les candidats enseignants des formulaires Google importes (ADM-23) recoivent
-- un lien PERSONNEL : une invitation a code (invitations_enseignant, deja la),
-- et son e-mail existant `invitation_enseignant` (lien
-- /#/connexion?mode=creer&invitation=1&code=...). Avec le code, la personne
-- s'inscrit meme si le lien public est ferme (inscrire_candidat, inchange) ;
-- le rapprochement par adresse confirmee relie sa reponse importee et
-- pre-remplit son brouillon de la salle 1 (formulaires_rapprocher_inscription,
-- inchange). Aucun texte nouveau : le modele d'e-mail est celui d'I1.
--
-- Ce fichier :
--   1. private.inv_cand_garde() : direction active, super-admin, aal2 (comme
--      l'import ADM-23), sinon 42501.
--   2. private.inv_cand_personnes() : une ligne par adresse des reponses
--      importees actives non rattachees (la plus ancienne reponse de
--      l'adresse), avec sa situation : a_inviter, a_renvoyer (derniere
--      invitation expiree, jamais utilisee), deja_invite (invitation active),
--      deja_inscrit (un profil existe a cette adresse), revoquee (la
--      direction a revoque une invitation de cette adresse : on ne la relance
--      pas en nombre), desinscrit (recrutement).
--   3. public.apercu_invitations_candidats_importes() : les comptes, sans
--      aucune adresse ; plus les reponses sans adresse, et le plafond du jour.
--   4. public.envoyer_invitations_candidats_importes(p_attendu, p_limite) :
--      pour chaque personne a inviter ou a renvoyer, une invitation neuve et
--      son e-mail, cle invitation_candidat_importe:<reponse>:<n>.
--      * p_limite de 1 a 200 (sinon 22023) ;
--      * p_attendu : le nombre que la direction a vu (a inviter + a renvoyer) ;
--        un nombre qui a change refuse l'envoi, sans ecriture ;
--      * plafond PROPRE a cet usage : 300 messages sur 24 heures glissantes,
--        comptes sur les cles invitation_candidat_importe:* ; au-dela, refus
--        rendu {erreur: plafond_atteint, restants}. Le modele
--        invitation_enseignant garde son regime hors plafond general pour les
--        invitations unitaires de la direction (inviter_enseignant, inchange).
--   5. public.lien_invitation_candidat_importe(p_reponse, p_courriel) : « Copier
--      le lien » pour une reponse, surtout sans adresse. Le code est lie a une
--      adresse (inscrire_candidat le verifie) : sans adresse importee, la
--      direction saisit celle que la personne utilisera. Reutilise une
--      invitation active de cette adresse, sinon en emet une ; n'enfile aucun
--      e-mail ; rend le code et l'echeance (le lien est compose par
--      l'application). Journal : qui, quand, quelle reponse, quelle
--      invitation, jamais le code.
--   6. revoquer_invitation_enseignant (ancre) : revoquer annule aussi l'e-mail
--      encore en attente d'une invitation de ce lot (cle
--      invitation_candidat_importe:*), comme I1 le fait pour la sienne.
--
-- Donnees : aucune adresse ni aucun code dans le journal ; l'apercu ne rend que
-- des comptes. Le code reste stocke en clair (existant, dette notee par le
-- garde-cap le 07/11) : rien n'y est change.
--
-- Le generateur de code est celui d'inviter_enseignant (meme alphabet, meme
-- duree recrutement.invitation_duree_jours) ; il est recopie dans
-- private.inv_cand_emettre plutot que d'appeler inviter_enseignant, qui
-- enfilerait son propre e-mail (cle invitation_enseignant:<id>, hors du plafond
-- de ce lot).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : la fonction retouchee est bien celle de la production.
-- ---------------------------------------------------------------------------
-- Empreinte de pg_get_functiondef(revoquer_invitation_enseignant) lue en
-- production le 07/11/2026 (lecture seule) et egale a celle du depot apres
-- 20261117000000.
DO $preflight$
DECLARE
  v_md5 text := pg_catalog.md5(pg_catalog.pg_get_functiondef(
    'public.revoquer_invitation_enseignant(text)'::regprocedure));
BEGIN
  IF v_md5 <> '6242fd1e23318c6a32ef6869386f2a7a' THEN
    RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : revoquer_invitation_enseignant a change depuis la lecture du 07/11 (md5 %)', v_md5;
  END IF;
  IF to_regclass('public.formulaires_reponses') IS NULL
     OR to_regclass('public.invitations_enseignant') IS NULL
     OR to_regclass('public.courriels_sortants') IS NULL
     OR to_regclass('public.courriel_desinscriptions') IS NULL
     OR to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL
     OR to_regprocedure('private.cand_lecteur()') IS NULL THEN
    RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : un objet attendu manque';
  END IF;
END;
$preflight$;

-- Outil de la migration (detruit avec la session) : remplace une ancre, une
-- seule fois, puis rafraichit l'empreinte F86 du commentaire.
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1. La garde : direction active, super-admin, double verification.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.inv_cand_garde()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_super boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations des candidats reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.super_admin INTO v_lecteur, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT coalesce(v_super, false) THEN
    RAISE EXCEPTION 'invitations des candidats reservees au super-admin' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'invitations des candidats : double verification requise' USING ERRCODE = '42501';
  END IF;
  RETURN v_lecteur;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les personnes : une ligne par adresse importee, et sa situation.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.inv_cand_personnes()
RETURNS TABLE (reponse_id uuid, courriel text, recue_le timestamptz, situation text)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  WITH adresses AS (
    SELECT DISTINCT ON (r.courriel) r.id, r.courriel, r.recue_le
      FROM public.formulaires_reponses r
     WHERE r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NOT NULL
     ORDER BY r.courriel, r.recue_le ASC, r.id ASC
  )
  SELECT a.id, a.courriel, a.recue_le,
         CASE
           WHEN EXISTS (SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id = u.id
                         WHERE pg_catalog.lower(u.email) = a.courriel AND p.deleted_at IS NULL)
             THEN 'deja_inscrit'
           WHEN EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                         WHERE d.adresse = a.courriel AND d.categorie = 'recrutement')
             THEN 'desinscrit'
           WHEN EXISTS (SELECT 1 FROM public.invitations_enseignant i
                         WHERE i.email = a.courriel AND i.revoquee_le IS NOT NULL)
             THEN 'revoquee'
           WHEN EXISTS (SELECT 1 FROM public.invitations_enseignant i
                         WHERE i.email = a.courriel AND i.utilisee_le IS NULL
                           AND i.expire_le > pg_catalog.now())
             THEN 'deja_invite'
           WHEN EXISTS (SELECT 1 FROM public.invitations_enseignant i
                         WHERE i.email = a.courriel AND i.utilisee_le IS NOT NULL)
             THEN 'deja_inscrit'
           WHEN EXISTS (SELECT 1 FROM public.invitations_enseignant i WHERE i.email = a.courriel)
             THEN 'a_renvoyer'
           ELSE 'a_inviter'
         END
    FROM adresses a;
$function$;

-- Les envois de ce lot sur les 24 dernieres heures (le plafond propre).
CREATE FUNCTION private.inv_cand_envoyes_24h()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.count(*)::integer
    FROM public.courriels_sortants s
   WHERE s.cle_idempotence LIKE 'invitation\_candidat\_importe:%'
     AND s.cree_le > pg_catalog.now() - interval '24 hours';
$function$;

-- Une invitation neuve pour une adresse (generateur d'inviter_enseignant).
CREATE FUNCTION private.inv_cand_emettre(p_email text, p_auteur uuid)
RETURNS public.invitations_enseignant
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_ligne public.invitations_enseignant;
  v_octets bytea;
  v_code text;
  v_i integer;
  v_essai integer := 0;
BEGIN
  LOOP
    v_essai := v_essai + 1;
    v_octets := extensions.gen_random_bytes(12);
    v_code := '';
    FOR v_i IN 0..11 LOOP
      v_code := v_code || pg_catalog.substr(v_alphabet, (pg_catalog.get_byte(v_octets, v_i) % 31) + 1, 1);
      IF v_i IN (3, 7) THEN
        v_code := v_code || '-';
      END IF;
    END LOOP;
    BEGIN
      INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
      VALUES (v_code, p_email, p_auteur,
              pg_catalog.now() + pg_catalog.make_interval(days =>
                greatest(1, public.app_config_int('recrutement.invitation_duree_jours', 14))))
      RETURNING * INTO v_ligne;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF v_essai >= 5 THEN
        RAISE;
      END IF;
    END;
  END LOOP;
  RETURN v_ligne;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. L'apercu.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.apercu_invitations_candidats_importes()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_plafond constant integer := 300;
  v_envoyes integer;
  v_r jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations des candidats reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  v_lecteur := private.inv_cand_garde();
  v_envoyes := private.inv_cand_envoyes_24h();
  SELECT pg_catalog.jsonb_build_object(
           'aInviter', pg_catalog.count(*) FILTER (WHERE p.situation = 'a_inviter'),
           'aRenvoyer', pg_catalog.count(*) FILTER (WHERE p.situation = 'a_renvoyer'),
           'dejaInvites', pg_catalog.count(*) FILTER (WHERE p.situation = 'deja_invite'),
           'dejaInscrits', pg_catalog.count(*) FILTER (WHERE p.situation = 'deja_inscrit'),
           'revoquees', pg_catalog.count(*) FILTER (WHERE p.situation = 'revoquee'),
           'desinscrits', pg_catalog.count(*) FILTER (WHERE p.situation = 'desinscrit'),
           'sansAdresse', (SELECT pg_catalog.count(*) FROM public.formulaires_reponses r
                            WHERE r.etat = 'active' AND r.candidature_id IS NULL AND r.courriel IS NULL),
           'plafondJour', v_plafond,
           'envoyes24h', v_envoyes,
           'resteAujourdhui', greatest(0, v_plafond - v_envoyes))
    INTO v_r
    FROM private.inv_cand_personnes() p;

  PERFORM public.log_sensitive_access('invitations_candidats_apercu', 'invitations_enseignant', NULL, v_r);
  RETURN v_r;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. L'envoi, etale.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.envoyer_invitations_candidats_importes(p_attendu integer, p_limite integer DEFAULT 200)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_plafond constant integer := 300;
  v_eligibles integer;
  v_reste integer;
  v_p record;
  v_ligne public.invitations_enseignant;
  v_n integer;
  v_id uuid;
  v_mis integer := 0;
  v_r jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations des candidats reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  v_lecteur := private.inv_cand_garde();
  IF p_limite IS NULL OR p_limite < 1 OR p_limite > 200 THEN
    RAISE EXCEPTION 'limite invalide : de 1 a 200' USING ERRCODE = '22023';
  END IF;
  IF p_attendu IS NULL OR p_attendu < 0 THEN
    RAISE EXCEPTION 'nombre attendu invalide' USING ERRCODE = '22023';
  END IF;

  -- Deux envois en meme temps n'invitent pas deux fois la meme personne.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('invitations_candidats_importes'));

  SELECT pg_catalog.count(*)::integer INTO v_eligibles
    FROM private.inv_cand_personnes() p WHERE p.situation IN ('a_inviter', 'a_renvoyer');
  IF v_eligibles <> p_attendu THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'nombre_change', 'eligibles', v_eligibles);
  END IF;

  v_reste := greatest(0, v_plafond - private.inv_cand_envoyes_24h());
  IF v_reste = 0 AND v_eligibles > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_atteint', 'restants', v_eligibles,
                                         'resteAujourdhui', 0);
  END IF;

  FOR v_p IN
    SELECT p.reponse_id, p.courriel
      FROM private.inv_cand_personnes() p
     WHERE p.situation IN ('a_inviter', 'a_renvoyer')
     ORDER BY p.recue_le ASC, p.reponse_id ASC
     LIMIT least(p_limite, v_reste)
  LOOP
    v_ligne := private.inv_cand_emettre(v_p.courriel, v_uid);
    SELECT pg_catalog.count(*)::integer + 1 INTO v_n
      FROM public.courriels_sortants s
     WHERE s.cle_idempotence LIKE 'invitation\_candidat\_importe:' || v_p.reponse_id::text || ':%';
    v_id := public.courriel_enfiler(
      'recrutement', 'invitation_enseignant', v_p.courriel, NULL,
      pg_catalog.jsonb_build_object('code', v_ligne.code, 'expire_le', v_ligne.expire_le),
      'invitation_candidat_importe:' || v_p.reponse_id::text || ':' || v_n::text,
      'manuel', v_uid);
    IF v_id IS NOT NULL THEN
      v_mis := v_mis + 1;
    ELSE
      -- Rien n'est parti (categorie inactive, adresse refusee) : l'invitation
      -- emise ne sert a personne, elle est revoquee aussitot.
      UPDATE public.invitations_enseignant
         SET revoquee_le = pg_catalog.now(), revoquee_par = v_uid
       WHERE id = v_ligne.id;
    END IF;
  END LOOP;

  v_r := pg_catalog.jsonb_build_object(
    'misEnFile', v_mis,
    'restants', v_eligibles - v_mis,
    'resteAujourdhui', greatest(0, v_plafond - private.inv_cand_envoyes_24h()));
  PERFORM public.log_sensitive_access('invitations_candidats_envoi', 'invitations_enseignant', NULL,
    v_r || pg_catalog.jsonb_build_object('limite', p_limite, 'attendu', p_attendu));
  RETURN v_r;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. « Copier le lien » d'une reponse.
-- ---------------------------------------------------------------------------
-- Rend {statut: 'pret', code, expireLe} ou {statut: 'reponse_introuvable' |
-- 'adresse_requise' | 'email_invalide' | 'deja_inscrit' | 'desinscrit'}.
CREATE FUNCTION public.lien_invitation_candidat_importe(p_reponse uuid, p_courriel text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_r public.formulaires_reponses;
  v_email text;
  v_ligne public.invitations_enseignant;
  v_neuve boolean := false;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations des candidats reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  v_lecteur := private.inv_cand_garde();
  SELECT r.* INTO v_r FROM public.formulaires_reponses r
   WHERE r.id = p_reponse AND r.etat = 'active' AND r.candidature_id IS NULL;
  IF v_r.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'reponse_introuvable');
  END IF;
  v_email := coalesce(v_r.courriel, nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_courriel, ''))), ''));
  IF v_email IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'adresse_requise');
  END IF;
  IF pg_catalog.length(v_email) NOT BETWEEN 3 AND 254
     OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'email_invalide');
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-enseignant:' || v_email, 0));

  IF EXISTS (SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id = u.id
              WHERE pg_catalog.lower(u.email) = v_email AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_inscrit');
  END IF;
  IF EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
              WHERE d.adresse = v_email AND d.categorie = 'recrutement') THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'desinscrit');
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_enseignant i
   WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
     AND i.expire_le > pg_catalog.now()
   ORDER BY i.cree_le DESC LIMIT 1;
  IF v_ligne.id IS NULL THEN
    v_ligne := private.inv_cand_emettre(v_email, v_uid);
    v_neuve := true;
  END IF;

  -- Qui, quand (horodatage du journal), quelle reponse, quelle invitation ;
  -- jamais le code ni l'adresse.
  PERFORM public.log_sensitive_access('invitation_candidat_lien_copie', 'invitations_enseignant',
    v_ligne.id::text,
    pg_catalog.jsonb_build_object('reponse', v_r.id, 'neuve', v_neuve,
                                  'adresse_saisie', v_r.courriel IS NULL));
  RETURN pg_catalog.jsonb_build_object('statut', 'pret', 'code', v_ligne.code,
                                       'expireLe', v_ligne.expire_le);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Revoquer annule aussi l'e-mail en attente de ce lot.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.revoquer_invitation_enseignant(text)'::regprocedure,
$a$    UPDATE public.courriels_sortants c SET statut = 'annule'
     WHERE c.cle_idempotence = 'invitation_enseignant:' || v_id::text AND c.statut = 'en_attente';$a$,
$b$    UPDATE public.courriels_sortants c SET statut = 'annule'
     WHERE c.cle_idempotence = 'invitation_enseignant:' || v_id::text AND c.statut = 'en_attente';
    -- INVITATIONS-PERSONNELLES : l'e-mail d'une invitation de candidat importe
    -- (cle invitation_candidat_importe:*) qui porte ce code ne part plus.
    UPDATE public.courriels_sortants c SET statut = 'annule'
     WHERE c.cle_idempotence LIKE 'invitation\_candidat\_importe:%' AND c.statut = 'en_attente'
       AND c.donnees ->> 'code' = (SELECT i.code FROM public.invitations_enseignant i WHERE i.id = v_id);$b$);

-- ---------------------------------------------------------------------------
-- 7. Droits, empreintes F86, controle final.
-- ---------------------------------------------------------------------------
DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'private.inv_cand_garde()',
    'private.inv_cand_personnes()',
    'private.inv_cand_envoyes_24h()',
    'private.inv_cand_emettre(text,uuid)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', f);
  END LOOP;
  FOREACH f IN ARRAY ARRAY[
    'public.apercu_invitations_candidats_importes()',
    'public.envoyer_invitations_candidats_importes(integer,integer)',
    'public.lien_invitation_candidat_importe(uuid,text)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.apercu_invitations_candidats_importes()', 'ROLE_POSITIVE_ADMIN_SUPER_AAL2',
       'Direction active, super-admin, aal2, sinon 42501 ; comptes seulement (a inviter, a renvoyer, deja invites, deja inscrits, revoquees, desinscrits, sans adresse, plafond du jour) ; aucune adresse rendue ; audit des comptes.'),
      ('public.envoyer_invitations_candidats_importes(integer,integer)', 'ROLE_POSITIVE_ADMIN_SUPER_AAL2',
       'Direction active, super-admin, aal2, sinon 42501 ; limite 1 a 200 sinon 22023 ; nombre attendu change : refus rendu sans ecriture ; plafond propre de 300 par 24 h glissantes sur les cles invitation_candidat_importe:* ; verrou consultatif ; une invitation neuve et son e-mail invitation_enseignant par personne a inviter ou a renvoyer, cle invitation_candidat_importe:<reponse>:<n> ; audit des comptes.'),
      ('public.lien_invitation_candidat_importe(uuid,text)', 'ROLE_POSITIVE_ADMIN_SUPER_AAL2',
       'Direction active, super-admin, aal2, sinon 42501 ; reponse active non rattachee ; adresse importee, sinon saisie ; compte existant ou desinscrit : refus rendu ; reutilise l invitation active, sinon en emet une ; aucun e-mail ; rend le code et l echeance ; audit sans code ni adresse.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=garde-cap a relire; date=2026-11-07. INVITATIONS-PERSONNELLES. %s Must-pass: supabase/tests/scenarios_invitations_candidats_importes.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde,
      v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT e.signature, p.*
    FROM (VALUES
      ('public.apercu_invitations_candidats_importes()'),
      ('public.envoyer_invitations_candidats_importes(integer,integer)'),
      ('public.lien_invitation_candidat_importe(uuid,text)')
    ) AS e(signature)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> 'v'
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;
  FOR v IN
    SELECT e.signature, p.oid
    FROM (VALUES
      ('private.inv_cand_garde()'), ('private.inv_cand_personnes()'),
      ('private.inv_cand_envoyes_24h()'), ('private.inv_cand_emettre(text,uuid)')
    ) AS e(signature)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : outil prive absent ou ouvert : %', v.signature;
    END IF;
  END LOOP;
  -- La retouche par ancre garde la fonction revoquee intacte ailleurs.
  IF pg_catalog.pg_get_functiondef('public.revoquer_invitation_enseignant(text)'::regprocedure)
       NOT LIKE '%invitation\_candidat\_importe:%' THEN
    RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : revoquer_invitation_enseignant non retouchee';
  END IF;
  -- La file reste fermee aux comptes.
  IF pg_catalog.has_function_privilege('authenticated',
       'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.courriels_sortants', 'SELECT,INSERT,UPDATE') THEN
    RAISE EXCEPTION 'INVITATIONS-PERSONNELLES : la file des courriels est ouverte aux comptes';
  END IF;
END;
$postflight$;

COMMIT;
