-- RACCORDEMENT 16/10 (D) : la consommation du code d'invitation enseignant.
--
-- Constat : `verifier_invitation_enseignant` (20261016100300) ne fait que
-- dire si un code est valable ; la consommation « atomique a
-- l'inscription » restait a brancher (colonnes utilisee_le / utilisee_par
-- pretes, aucune fonction ne les ecrivait). Un code verifie pouvait donc
-- resservir, et l'administration le voyait toujours « active ».
--
-- * `inscrire_enseignant_invite(p_code, p_first_name, p_last_name,
--   p_gender)` : en UNE transaction, verrouille l'invitation (FOR UPDATE),
--   la controle (adresse de la session, non revoquee, non utilisee, non
--   echue), cree le profil enseignant par `creer_profil_inscription`
--   (inchangee, empreinte F86 conservee) puis marque l'invitation utilisee.
--   Un echec de creation annule tout : le code n'est jamais brule pour rien.
-- * Les refus metier sont rendus, jamais leves : {resultat: 'consommee' |
--   'expiree' | 'deja_utilisee' | 'inconnue'} ; aucun profil n'est cree hors
--   'consommee'. Un code revoque ou emis pour une autre adresse rend
--   'inconnue' (meme regle de non-fuite que la verification).
-- * DEFINER indispensable : lecture de auth.users (adresse de la session),
--   ecriture de invitations_enseignant (aucun droit client). search_path
--   vide, objets qualifies. Porte positive : session auth avec adresse ET
--   aucun profil existant (etape d'inscription).
-- * L'inscription enseignant sans code reste ouverte : la rendre
--   obligatoire est une decision du directeur, pas de ce lot.
BEGIN;

CREATE FUNCTION public.inscrire_enseignant_invite(
  p_code text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_ligne public.invitations_enseignant;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF NOT coalesce(
    v_uid IS NOT NULL AND v_email IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid),
    false
  ) THEN
    RAISE EXCEPTION 'inscription enseignant reservee a une session sans profil' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_enseignant i
   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))
     AND i.email = v_email AND i.revoquee_le IS NULL
   FOR UPDATE;
  IF v_ligne.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'inconnue');
  END IF;
  IF v_ligne.utilisee_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'deja_utilisee');
  END IF;
  IF v_ligne.expire_le <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'expiree');
  END IF;

  PERFORM public.creer_profil_inscription('teacher', p_first_name, p_last_name, p_gender);

  UPDATE public.invitations_enseignant i
     SET utilisee_le = pg_catalog.clock_timestamp(), utilisee_par = v_uid
   WHERE i.id = v_ligne.id;
  PERFORM public.log_sensitive_access('invitation_enseignant_consommee', 'invitations_enseignant',
    v_ligne.id::text, pg_catalog.jsonb_build_object('profile_id', v_uid));
  RETURN pg_catalog.jsonb_build_object('resultat', 'consommee');
END;
$function$;

ALTER FUNCTION public.inscrire_enseignant_invite(text, text, text, public.gender) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.inscrire_enseignant_invite(text, text, text, public.gender)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.inscrire_enseignant_invite(text, text, text, public.gender)
  TO authenticated;

-- @@F86_DEBUT_INVITATION_CONSOMMEE@@
COMMENT ON FUNCTION public.inscrire_enseignant_invite(text, text, text, public.gender) IS
  'F86: signature=public.inscrire_enseignant_invite(text,text,text,public.gender); md5_functiondef=2362a8787a6c30dd9f24d659fd54092c; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-10-16. Garde: session auth avec adresse, sans profil; code lie a l''adresse de la session. DEFINER: auth.users et invitations_enseignant.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure
      AND (pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> '2362a8787a6c30dd9f24d659fd54092c'
           OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%2362a8787a6c30dd9f24d659fd54092c%'
           OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
  ) OR pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'::regprocedure
     )) <> '6e62676fc9cce5c0f76d7f6ae39d6959' THEN
    RAISE EXCEPTION 'RACCORDEMENT-1016 D : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_INVITATION_CONSOMMEE@@

COMMIT;
