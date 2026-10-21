-- AF L1-11 (audit final 17/10/2026, matrice E-01) : un enseignant n'entre que
-- par invitation. Decision du directeur sur A-07, option 1 (fermer), le 17/10.
--
-- Constat : `creer_profil_inscription('teacher', ...)` ouvrait un dossier
-- enseignant a n'importe quelle session connectee, alors que la porte par
-- invitation existe (`inviter_enseignant`, `verifier_invitation_enseignant`,
-- `inscrire_enseignant_invite`, 20261016100300 et 20261016102200).
--
-- Correction, sans changer le mecanisme d'invitation :
-- * le corps de `creer_profil_inscription` passe tel quel dans
--   `private.creer_profil_inscription_interne` (meme signature, aucun droit
--   client : seul un DEFINER de proprietaire postgres l'atteint) ;
-- * `public.creer_profil_inscription` garde signature, proprietaire, DEFINER,
--   search_path vide et droits (authenticated seul), et refuse `teacher`
--   (SQLSTATE 23514, check_violation) avant de deleguer pour les autres roles ;
-- * `inscrire_enseignant_invite` appelle l'interne, apres avoir verrouille et
--   controle l'invitation, dans la meme transaction : seule porte restante.
--   Signature et droits inchanges, empreinte F86 recalculee.
-- Les comptes enseignants deja crees ne sont pas touches (la garde porte sur la
-- creation). La liste blanche des fonctions volatiles ne change pas : aucune
-- signature publique ajoutee ou retiree, la fonction interne n'est executable
-- par aucun role client.
BEGIN;

CREATE FUNCTION private.creer_profil_inscription_interne(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_parent_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
begin
  if v_uid is null then raise exception 'aucune session'; end if;
  if p_role not in ('guardian', 'teacher') then
    raise exception 'role non ouvert a l''inscription publique : %', p_role;
  end if;
  v_role := p_role::public.app_role;
  if v_role <> 'guardian' and coalesce(p_parent_suit_des_cours, false) then
    raise exception 'profil apprenant personnel reserve au titulaire';
  end if;
  if exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'ce compte a deja un profil';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;

  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;
  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  values (v_uid, null, v_role, v_household,
    btrim(p_first_name), btrim(p_last_name), p_gender, 'pending_kyc')
  returning * into v_profile;

  if v_role = 'guardian' then
    update public.households set primary_guardian_id = v_uid where id = v_household;
    if coalesce(p_parent_suit_des_cours, false) then
      insert into public.student_profiles
        (profile_id, titulaire_profile_id, student_type, interface_mode,
         camera_policy, cohorte)
      values (v_uid, v_uid, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');
      perform public.log_sensitive_access(
        'profil_eleve_titulaire_cree', 'student_profiles', v_uid::text,
        jsonb_build_object('student_type', 'autonomous', 'source', 'inscription')
      );
    end if;
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;
  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  return v_profile;
end;
$function$;

ALTER FUNCTION private.creer_profil_inscription_interne(
  text, text, text, public.gender, text, boolean
) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.creer_profil_inscription_interne(
  text, text, text, public.gender, text, boolean
) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.creer_profil_inscription_interne(
  text, text, text, public.gender, text, boolean
) IS 'AF L1-11: corps de creer_profil_inscription, atteint seulement par creer_profil_inscription (hors enseignant) et inscrire_enseignant_invite. Aucun droit client. date=2026-10-17.';

CREATE OR REPLACE FUNCTION public.creer_profil_inscription(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_parent_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
begin
  if auth.uid() is null then raise exception 'aucune session'; end if;
  if p_role = 'teacher' then
    raise exception 'inscription enseignant sur invitation seulement'
      using errcode = 'check_violation';
  end if;
  return private.creer_profil_inscription_interne(
    p_role, p_first_name, p_last_name, p_gender, p_timezone, p_parent_suit_des_cours
  );
end;
$function$;

ALTER FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) TO authenticated;

CREATE OR REPLACE FUNCTION public.inscrire_enseignant_invite(
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

  PERFORM private.creer_profil_inscription_interne('teacher', p_first_name, p_last_name, p_gender);

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

COMMENT ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) IS 'F86 candidate allowlist: signature=public.creer_profil_inscription(text,text,text,public.gender,text,boolean); md5_functiondef=d52b0b37cb2ca581eceec2a66f1be06c; guard_type=PUBLIC_REGISTRATION; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17. Role teacher refuse (23514) : seule inscrire_enseignant_invite cree un enseignant.';
COMMENT ON FUNCTION public.inscrire_enseignant_invite(text, text, text, public.gender) IS
  'F86: signature=public.inscrire_enseignant_invite(text,text,text,public.gender); md5_functiondef=d556f4e4d989a0236d1ef98c4df95746; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-10-17. Garde: session auth avec adresse, sans profil; code lie a l''adresse de la session. DEFINER: auth.users et invitations_enseignant. Cree le profil par private.creer_profil_inscription_interne.';

DO $postflight$
DECLARE
  v_pub regprocedure := 'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'::regprocedure;
  v_inv regprocedure := 'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure;
  v_int regprocedure := 'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)'::regprocedure;
  v_oid regprocedure;
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef(v_pub)) <> 'd52b0b37cb2ca581eceec2a66f1be06c'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef(v_inv)) <> 'd556f4e4d989a0236d1ef98c4df95746' THEN
    RAISE EXCEPTION 'AF-L1-11 : empreinte F86 invalide';
  END IF;
  FOREACH v_oid IN ARRAY ARRAY[v_pub, v_inv, v_int] LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = v_oid AND p.prosecdef
            AND p.proowner = 'postgres'::regrole
            AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'AF-L1-11 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated', v_pub, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_inv, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_int, 'EXECUTE') THEN
    RAISE EXCEPTION 'AF-L1-11 : droits authenticated invalides';
  END IF;
END;
$postflight$;

COMMIT;
