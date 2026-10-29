-- ADMISSION lot B (decision du directeur du 27/10/2026,
-- docs/current/DECISION-ADMISSION-2026-10-27.md §2 et §7) : personne n'entre
-- sans decision de la direction. Annule D4 (20261024160000_tuteur_nait_actif).
--
-- 1. Deux types de demande : famille et eleve_adulte (compte tuteur).
-- 2. private.creer_profil_inscription_interne : le tuteur nait en attente
--    (pending_kyc) avec sa demande (etape recue), et l'e-mail « demande
--    recue » part par la file. Le reste est identique a la version du 24/10.
-- 3. public.inscrire_titulaire : « Moi » fait de la demande une demande
--    d'eleve adulte.
-- 4. public.lister_candidatures : sans type demande, la file ne montre pas
--    les demandes d'admission (ADM-20 n'envoie aucun type) ; les listes des
--    familles viendront au lot C.
-- Les tuteurs deja actifs ne changent pas.

BEGIN;

INSERT INTO public.candidature_types (code, role_compte)
VALUES ('famille', 'guardian'), ('eleve_adulte', 'guardian')
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION private.creer_profil_inscription_interne(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL::public.gender,
  p_timezone text DEFAULT 'Europe/Paris'::text,
  p_parent_suit_des_cours boolean DEFAULT false
)
RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
  v_candidature public.candidatures;
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
  -- La demande recopie le genre du compte (candidatures.genre, NOT NULL).
  if v_role = 'guardian' and p_gender is null then
    raise exception 'genre requis' using errcode = '22023';
  end if;

  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;
  -- Admission (27/10) : tout compte nait en attente de la decision.
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
    -- La demande d'admission, une par compte et par type.
    insert into public.candidatures (type_code, profile_id, genre, nom_complet, source)
    values ('famille', v_uid, p_gender,
      btrim(p_first_name) || ' ' || btrim(p_last_name), 'lien_public')
    returning * into v_candidature;
    perform public.courriel_enfiler(
      'inscription', 'admission_recue', public.courriel_adresse_profil(v_uid), v_uid,
      jsonb_build_object('reference', v_candidature.reference),
      'admission_recue:' || v_candidature.id::text);
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;
  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  return v_profile;
end;
$function$;

CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF NOT coalesce(p_usage IN ('moi', 'famille'), false) THEN
    RAISE EXCEPTION 'usage inconnu : %', p_usage USING ERRCODE = '22023';
  END IF;
  v_profile := private.creer_profil_inscription_interne(
    'guardian', p_first_name, p_last_name, p_gender, p_timezone,
    p_usage = 'moi' OR coalesce(p_suit_des_cours, false));
  UPDATE public.households h
     SET usage_inscription = p_usage
   WHERE h.id = v_profile.household_id;
  -- « Moi » : la demande est celle d'un eleve adulte (liste separee, lot C).
  IF p_usage = 'moi' THEN
    UPDATE public.candidatures c
       SET type_code = 'eleve_adulte'
     WHERE c.profile_id = v_profile.id AND c.type_code = 'famille';
  END IF;
  RETURN v_profile;
END;
$function$;

-- Les empreintes gardees dans les commentaires (F86) suivent les corps recrees.
DO $empreintes$
DECLARE
  v_f pg_catalog.regprocedure;
  v_com text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)'::pg_catalog.regprocedure,
    'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)'::pg_catalog.regprocedure
  ] LOOP
    v_com := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
    END IF;
  END LOOP;
END;
$empreintes$;

-- La file des candidatures (ADM-20, qui n'envoie aucun type) ne montre pas
-- les demandes d'admission des familles et des eleves adultes : leurs listes
-- viendront au lot C. Un type demande reste servi tel quel. Le filtre se
-- change partout ou il est ecrit (liste et total) ; le bloc refuse de
-- continuer s'il ne le trouve pas tel quel.
DO $do$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
  v_avant text := 'AND (v_type IS NULL OR c.type_code = v_type)';
  v_apres text := 'AND (CASE WHEN v_type IS NULL THEN c.type_code NOT IN (''famille'', ''eleve_adulte'') ELSE c.type_code = v_type END)';
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'lister_candidatures : le filtre du type a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  -- L'empreinte gardee dans le commentaire (F86) suit le nouveau corps.
  EXECUTE pg_catalog.format(
    'COMMENT ON FUNCTION public.lister_candidatures(jsonb,text,integer) IS %L',
    pg_catalog.regexp_replace(
      pg_catalog.obj_description(
        'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure,
        'pg_proc'),
      'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(
        'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure))));
END;
$do$;

COMMIT;
