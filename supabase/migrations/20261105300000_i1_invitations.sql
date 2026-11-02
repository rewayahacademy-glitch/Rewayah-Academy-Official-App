-- I1 « Inviter quelqu'un » (02/11/2026, lot attribue par le pilote).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- le pilote l'installe tel quel. Migration additive (B6) : l'ancien code de
-- production continue de marcher (memes signatures, memes reponses ; une cle
-- de plus dans la reponse d'inviter_enseignant, que l'ancien client ignore).
--
-- 1. inviter_enseignant enfile un e-mail dans courriels_sortants (modele
--    `invitation_enseignant`, categorie `recrutement`) avec le code et le lien
--    d'inscription. Une invitation deja active recoit aussi son e-mail si elle
--    n'en a jamais eu (meme cle d'idempotence : jamais deux envois). La
--    reponse porte `courriel_en_file` (vrai si une ligne de la file existe
--    pour cette invitation). Revoquer une invitation annule son e-mail encore
--    en attente.
-- 2. UX-016 : le code se normalise cote serveur (casse, espaces, tirets
--    oublies) dans verifier_invitation_enseignant, revoquer_invitation_enseignant
--    et inscrire_enseignant_invite (la consommation). Une seule fonction :
--    app_private.code_invitation_normalise.
-- 3. Familles importees (private.preinscription_households confirmees, non
--    reclamees) : une liste pour la direction et deux envois, un par foyer et
--    un pour tous. Rien ne part tout seul : chaque envoi est un geste de la
--    direction, et l'envoi a tous exige le nombre de foyers que la direction a
--    vu (un nombre qui a change entre-temps refuse l'envoi, sans ecriture).
--
-- Lecteurs recenses (B1) : aucune colonne n'est rendue facultative ni ne
-- change de sens. Les fonctions retouchees le sont par ancre (B4) et gardent
-- leur proprietaire, leurs droits et leur commentaire ; l'empreinte F86 de
-- leur commentaire est recalculee ; un bloc postflight verifie le tout.
--
-- E-mails : les modeles `invitation_enseignant` et `invitation_famille_importee`
-- vivent dans supabase/functions/_shared/courriel/modeles_fr.ts. Tant que la
-- fonction Edge `courriels-envoi` n'est pas redeployee avec ces modeles, une
-- ligne de ces modeles reste en echec a l'envoi (« modele inconnu ») : deployer
-- la fonction AVANT d'installer cette migration.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Outil de la migration (detruit avec la session).
-- ---------------------------------------------------------------------------
-- Remplace [p_ancre] par [p_neuf] dans la definition actuelle de [p_fonction],
-- exactement une fois, puis rafraichit l'empreinte F86 de son commentaire.
-- Echoue si l'ancre manque ou revient (fonction changee depuis le depot).
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
    RAISE EXCEPTION 'I1 : ancre trouvee % fois dans % : %', v_n, p_fonction, pg_catalog.left(p_ancre, 120);
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
-- 1. Le code normalise (UX-016).
-- ---------------------------------------------------------------------------
-- « abcd efgh jkmn », « ABCDEFGHJKMN », « abcd-efgh-jkmn » donnent tous
-- « ABCD-EFGH-JKMN ». Tout signe qui n'est ni lettre ni chiffre est ignore ;
-- douze signes sont regroupes par quatre. Un code d'une autre longueur reste
-- tel quel (en majuscules, sans espaces) et ne trouvera aucune invitation.
CREATE FUNCTION app_private.code_invitation_normalise(p_code text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE WHEN pg_catalog.length(c) = 12
              THEN pg_catalog.substr(c, 1, 4) || '-' || pg_catalog.substr(c, 5, 4) || '-' || pg_catalog.substr(c, 9, 4)
              ELSE c END
    FROM (SELECT pg_catalog.upper(pg_catalog.regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')) AS c) AS x;
$function$;
ALTER FUNCTION app_private.code_invitation_normalise(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.code_invitation_normalise(text) FROM PUBLIC, anon, service_role, agent_ro;
-- Appelee par des fonctions DEFINER (proprietaire postgres) ; authenticated
-- la garde pour un appel INVOKER futur, comme invitation_enseignant_json.
GRANT EXECUTE ON FUNCTION app_private.code_invitation_normalise(text) TO authenticated;
COMMENT ON FUNCTION app_private.code_invitation_normalise(text) IS
  'I1 (02/11/2026, UX-016) : code d''invitation recopie (casse, espaces, tirets) vers la forme stockee AAAA-BBBB-CCCC.';

SELECT pg_temp.remplacer('public.verifier_invitation_enseignant(text)'::regprocedure,
$a$   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))$a$,
$b$   WHERE i.code = app_private.code_invitation_normalise(p_code)$b$);

SELECT pg_temp.remplacer('public.revoquer_invitation_enseignant(text)'::regprocedure,
$a$   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))$a$,
$b$   WHERE i.code = app_private.code_invitation_normalise(p_code)$b$);

SELECT pg_temp.remplacer('public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure,
$a$   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))$a$,
$b$   WHERE i.code = app_private.code_invitation_normalise(p_code)$b$);

-- ---------------------------------------------------------------------------
-- 2. L'e-mail de l'invitation d'un enseignant.
-- ---------------------------------------------------------------------------
-- Enfile l'e-mail d'une invitation active ; rend vrai si une ligne de la file
-- existe pour elle (nouvelle ou deja la). Cle d'idempotence par invitation :
-- un second appel n'envoie rien de plus.
CREATE FUNCTION app_private.i1_enfiler_invitation_enseignant(p_invitation uuid)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ligne public.invitations_enseignant;
  v_cle text := 'invitation_enseignant:' || p_invitation::text;
BEGIN
  SELECT i.* INTO v_ligne FROM public.invitations_enseignant i WHERE i.id = p_invitation;
  IF v_ligne.id IS NULL OR v_ligne.revoquee_le IS NOT NULL OR v_ligne.utilisee_le IS NOT NULL
     OR v_ligne.expire_le <= pg_catalog.now() THEN
    RETURN false;
  END IF;
  PERFORM public.courriel_enfiler(
    'recrutement', 'invitation_enseignant', v_ligne.email, NULL,
    pg_catalog.jsonb_build_object('code', v_ligne.code, 'expire_le', v_ligne.expire_le),
    v_cle, 'manuel', auth.uid());
  RETURN EXISTS (SELECT 1 FROM public.courriels_sortants c WHERE c.cle_idempotence = v_cle);
END;
$function$;
ALTER FUNCTION app_private.i1_enfiler_invitation_enseignant(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.i1_enfiler_invitation_enseignant(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION app_private.i1_enfiler_invitation_enseignant(uuid) IS
  'I1 (02/11/2026) : enfile l''e-mail d''une invitation d''enseignant active (code et lien), une seule fois par invitation.';

-- La creation : l'e-mail part avec l'invitation.
SELECT pg_temp.remplacer('public.inviter_enseignant(text)'::regprocedure,
$a$  PERFORM public.log_sensitive_access('invitation_enseignant_emise', 'invitations_enseignant',
    v_ligne.id::text, '{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('statut', 'creee',
    'invitation', app_private.invitation_enseignant_json(v_ligne));$a$,
$b$  PERFORM public.log_sensitive_access('invitation_enseignant_emise', 'invitations_enseignant',
    v_ligne.id::text, '{}'::jsonb);
  -- I1 (02/11/2026) : l'e-mail avec le code et le lien part avec l'invitation.
  RETURN pg_catalog.jsonb_build_object('statut', 'creee',
    'invitation', app_private.invitation_enseignant_json(v_ligne),
    'courriel_en_file', app_private.i1_enfiler_invitation_enseignant(v_ligne.id));$b$);

-- Une invitation deja active : son e-mail part s'il n'est jamais parti.
SELECT pg_temp.remplacer('public.inviter_enseignant(text)'::regprocedure,
$a$    RETURN pg_catalog.jsonb_build_object('statut', 'deja_invite',
      'invitation', app_private.invitation_enseignant_json(v_ligne));$a$,
$b$    RETURN pg_catalog.jsonb_build_object('statut', 'deja_invite',
      'invitation', app_private.invitation_enseignant_json(v_ligne),
      -- I1 : une invitation d'avant ce lot recoit ici son premier e-mail.
      'courriel_en_file', app_private.i1_enfiler_invitation_enseignant(v_ligne.id));$b$);

-- Revoquer annule l'e-mail encore en attente (il ne part plus).
SELECT pg_temp.remplacer('public.revoquer_invitation_enseignant(text)'::regprocedure,
$a$  IF FOUND THEN
    PERFORM public.log_sensitive_access('invitation_enseignant_revoquee', 'invitations_enseignant',$a$,
$b$  IF FOUND THEN
    -- I1 : l'e-mail pas encore parti ne part plus.
    UPDATE public.courriels_sortants c SET statut = 'annule'
     WHERE c.cle_idempotence = 'invitation_enseignant:' || v_id::text AND c.statut = 'en_attente';
    PERFORM public.log_sensitive_access('invitation_enseignant_revoquee', 'invitations_enseignant',$b$);

-- ---------------------------------------------------------------------------
-- 3. Les familles importees.
-- ---------------------------------------------------------------------------
-- L'etat de l'invitation d'un foyer importe, d'apres la file (jamais l'horloge
-- de l'appareil) : 'compte_cree' (le foyer est reclame), 'a_envoyer' (rien en
-- file, ou le dernier envoi annule), 'en_file', 'envoyee', 'echec'.
CREATE FUNCTION app_private.i1_etat_invitation_famille(p_foyer uuid, p_reclame boolean)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_reclame THEN pg_catalog.jsonb_build_object('etat', 'compte_cree', 'envoyee_le', d.envoye_le)
    WHEN d.statut IS NULL OR d.statut = 'annule' THEN pg_catalog.jsonb_build_object('etat', 'a_envoyer', 'envoyee_le', NULL)
    WHEN d.statut IN ('en_attente', 'envoi') THEN pg_catalog.jsonb_build_object('etat', 'en_file', 'envoyee_le', NULL)
    WHEN d.statut = 'envoye' THEN pg_catalog.jsonb_build_object('etat', 'envoyee', 'envoyee_le', d.envoye_le)
    ELSE pg_catalog.jsonb_build_object('etat', 'echec', 'envoyee_le', NULL) END
  FROM (SELECT NULL::integer AS rien) AS r
  LEFT JOIN LATERAL (
    SELECT c.statut, c.envoye_le FROM public.courriels_sortants c
     WHERE c.modele = 'invitation_famille_importee'
       AND c.cle_idempotence LIKE 'invitation_famille_importee:' || p_foyer::text || ':%'
     ORDER BY c.cree_le DESC LIMIT 1) AS d ON true;
$function$;
ALTER FUNCTION app_private.i1_etat_invitation_famille(uuid, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.i1_etat_invitation_famille(uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Enfile l'invitation d'un foyer (sans garde : appelee par les deux RPC de la
-- direction). Rend 'en_file', 'deja_en_file', 'compte_cree' ou 'introuvable'.
CREATE FUNCTION app_private.i1_envoyer_invitation_famille(p_foyer uuid)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer private.preinscription_households;
  v_etat text;
  v_n integer;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-famille-importee:' || p_foyer::text, 0));
  SELECT h.* INTO v_foyer FROM private.preinscription_households h
   WHERE h.id = p_foyer AND h.status = 'confirmed';
  IF v_foyer.id IS NULL OR NOT EXISTS (
       SELECT 1 FROM private.preinscription_persons p
        WHERE p.household_id = p_foyer AND p.person_kind <> 'teacher') THEN
    RETURN 'introuvable';
  END IF;
  v_etat := app_private.i1_etat_invitation_famille(p_foyer, v_foyer.linked_auth_user_id IS NOT NULL) ->> 'etat';
  IF v_etat = 'compte_cree' THEN
    RETURN 'compte_cree';
  ELSIF v_etat IN ('en_file', 'envoyee') THEN
    RETURN 'deja_en_file';
  END IF;
  -- Premier envoi, ou nouvel envoi apres un echec ou une annulation.
  SELECT count(*) INTO v_n FROM public.courriels_sortants c
   WHERE c.modele = 'invitation_famille_importee'
     AND c.cle_idempotence LIKE 'invitation_famille_importee:' || p_foyer::text || ':%';
  PERFORM public.courriel_enfiler(
    'inscription', 'invitation_famille_importee', v_foyer.email_normalise, NULL,
    '{}'::jsonb, 'invitation_famille_importee:' || p_foyer::text || ':' || (v_n + 1)::text,
    'manuel', auth.uid());
  PERFORM public.log_sensitive_access('invitation_famille_importee_envoyee',
    'preinscription_households', p_foyer::text, '{}'::jsonb);
  RETURN 'en_file';
END;
$function$;
ALTER FUNCTION app_private.i1_envoyer_invitation_famille(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.i1_envoyer_invitation_famille(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- La liste des foyers importes et confirmes, du plus ancien au plus recent.
-- Rend {foyers: [{id, email, personnes, etat, envoyee_le}], a_envoyer: n}.
CREATE FUNCTION public.invitations_familles_importees()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyers jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(
           pg_catalog.jsonb_build_object(
             'id', h.id, 'email', h.email_normalise,
             'personnes', (SELECT count(*) FROM private.preinscription_persons p
                            WHERE p.household_id = h.id AND p.person_kind <> 'teacher'))
           || app_private.i1_etat_invitation_famille(h.id, h.linked_auth_user_id IS NOT NULL)
           ORDER BY h.created_at, h.id), '[]'::jsonb)
    INTO v_foyers
    FROM private.preinscription_households h
   WHERE h.status = 'confirmed'
     AND EXISTS (SELECT 1 FROM private.preinscription_persons p
                  WHERE p.household_id = h.id AND p.person_kind <> 'teacher');
  RETURN pg_catalog.jsonb_build_object(
    'foyers', v_foyers,
    'a_envoyer', (SELECT count(*) FROM pg_catalog.jsonb_array_elements(v_foyers) f
                   WHERE f ->> 'etat' IN ('a_envoyer', 'echec')));
END;
$function$;

-- Un foyer. Rend {statut: 'en_file' | 'deja_en_file' | 'compte_cree' | 'introuvable'}.
CREATE FUNCTION public.envoyer_invitation_famille_importee(p_foyer uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object('statut', app_private.i1_envoyer_invitation_famille(p_foyer));
END;
$function$;

-- Tous les foyers a envoyer (jamais envoyes, ou en echec). [p_attendu] est le
-- nombre que la direction a vu et confirme : s'il a change, rien ne part.
-- Rend {statut: 'en_file', envoyees: n} ou {statut: 'nombre_change', a_envoyer: n}.
CREATE FUNCTION public.envoyer_invitations_familles_importees(p_attendu integer)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[];
  v_id uuid;
  v_n integer := 0;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  -- Un seul envoi groupe a la fois.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-famille-importee:toutes', 0));
  SELECT coalesce(pg_catalog.array_agg(h.id ORDER BY h.created_at, h.id), ARRAY[]::uuid[]) INTO v_ids
    FROM private.preinscription_households h
   WHERE h.status = 'confirmed'
     AND EXISTS (SELECT 1 FROM private.preinscription_persons p
                  WHERE p.household_id = h.id AND p.person_kind <> 'teacher')
     AND app_private.i1_etat_invitation_famille(h.id, h.linked_auth_user_id IS NOT NULL) ->> 'etat'
         IN ('a_envoyer', 'echec');
  IF p_attendu IS NULL OR p_attendu <> coalesce(pg_catalog.array_length(v_ids, 1), 0) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'nombre_change',
      'a_envoyer', coalesce(pg_catalog.array_length(v_ids, 1), 0));
  END IF;
  FOREACH v_id IN ARRAY v_ids LOOP
    IF app_private.i1_envoyer_invitation_famille(v_id) = 'en_file' THEN
      v_n := v_n + 1;
    END IF;
  END LOOP;
  RETURN pg_catalog.jsonb_build_object('statut', 'en_file', 'envoyees', v_n);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Droits et empreintes F86 des fonctions nouvelles.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  f text;
  v_oid regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.invitations_familles_importees()',
    'public.envoyer_invitation_famille_importee(uuid)',
    'public.envoyer_invitations_familles_importees(integer)'] LOOP
    v_oid := f::regprocedure;
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. I1 : invitations des familles importees, envoi sur geste de la direction seulement. Must-pass: supabase/tests/scenarios_i1_invitations.sql.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 5. Postflight.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  IF app_private.code_invitation_normalise(' abcd efgh-jkmn ') <> 'ABCD-EFGH-JKMN'
     OR app_private.code_invitation_normalise('ABCDEFGHJKMN') <> 'ABCD-EFGH-JKMN'
     OR app_private.code_invitation_normalise(NULL) <> '' THEN
    RAISE EXCEPTION 'I1 : normalisation du code incorrecte';
  END IF;
  -- Les ancres sont posees.
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.inviter_enseignant(text)'::regprocedure),
                       'app_private.i1_enfiler_invitation_enseignant(v_ligne.id)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.verifier_invitation_enseignant(text)'::regprocedure),
                       'app_private.code_invitation_normalise(p_code)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.revoquer_invitation_enseignant(text)'::regprocedure),
                       'app_private.code_invitation_normalise(p_code)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.revoquer_invitation_enseignant(text)'::regprocedure),
                       'SET statut = ''annule''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure),
                       'app_private.code_invitation_normalise(p_code)') = 0 THEN
    RAISE EXCEPTION 'I1 : une ancre n''est pas posee';
  END IF;
  -- Droits : la direction passe par authenticated ; jamais anon ni agent_ro.
  FOREACH f IN ARRAY ARRAY[
    'public.invitations_familles_importees()'::regprocedure,
    'public.envoyer_invitation_famille_importee(uuid)'::regprocedure,
    'public.envoyer_invitations_familles_importees(integer)'::regprocedure] LOOP
    IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'I1 : droits incorrects sur %', f;
    END IF;
  END LOOP;
  FOREACH f IN ARRAY ARRAY[
    'app_private.i1_enfiler_invitation_enseignant(uuid)'::regprocedure,
    'app_private.i1_envoyer_invitation_famille(uuid)'::regprocedure,
    'app_private.i1_etat_invitation_famille(uuid,boolean)'::regprocedure] LOOP
    IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'I1 : aide privee ouverte : %', f;
    END IF;
  END LOOP;
  -- DEFINER et search_path vide partout.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid IN ('public.inviter_enseignant(text)'::regprocedure,
                     'public.verifier_invitation_enseignant(text)'::regprocedure,
                     'public.revoquer_invitation_enseignant(text)'::regprocedure,
                     'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure,
                     'public.invitations_familles_importees()'::regprocedure,
                     'public.envoyer_invitation_famille_importee(uuid)'::regprocedure,
                     'public.envoyer_invitations_familles_importees(integer)'::regprocedure,
                     'app_private.i1_enfiler_invitation_enseignant(uuid)'::regprocedure,
                     'app_private.i1_envoyer_invitation_famille(uuid)'::regprocedure,
                     'app_private.i1_etat_invitation_famille(uuid,boolean)'::regprocedure)
       AND (NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""']))) THEN
    RAISE EXCEPTION 'I1 : fonction sans DEFINER ou search_path';
  END IF;
  -- Les empreintes F86 des fonctions retouchees sont a jour.
  FOREACH f IN ARRAY ARRAY[
    'public.inviter_enseignant(text)'::regprocedure,
    'public.verifier_invitation_enseignant(text)'::regprocedure,
    'public.revoquer_invitation_enseignant(text)'::regprocedure,
    'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure,
    'public.invitations_familles_importees()'::regprocedure,
    'public.envoyer_invitation_famille_importee(uuid)'::regprocedure,
    'public.envoyer_invitations_familles_importees(integer)'::regprocedure] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%'
       AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(f))) = 0 THEN
      RAISE EXCEPTION 'I1 : empreinte F86 perimee pour %', f;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
