-- D4 (24/10/2026, decision du pilote deleguee par le directeur) : le tuteur
-- inscrit par l'application nait ACTIF. Une famille ne fournit pas de piece
-- d'identite ; la verification documentaire ne concerne que les enseignants.
--
-- Constat (K3, lecture seule) : private.creer_profil_inscription_interne
-- faisait naitre tout profil en 'pending_kyc' ; seule decider_dossier (piece
-- approuvee) activait un compte, et le tuteur n'a aucun ecran de depot : il
-- restait dans /attente, et creer_profil_enfant le refusait (« compte tuteur
-- non valide »).
--
-- 1. private.creer_profil_inscription_interne, recree a l'identique de la
--    version en production (AF L1-11), sauf le statut : 'active' pour un
--    tuteur, 'pending_kyc' inchange pour un enseignant. Le declencheur
--    guard_teacher_activation_signatures ne vise que les enseignants ; le
--    matricule est pose par profiles_attribuer_matricule (BEFORE INSERT).
-- 2. Rattrapage : les tuteurs non supprimes encore en 'pending_kyc' passent a
--    'active' (aucun en production le 24/10).
--
-- Aucune suppression. CREATE OR REPLACE garde les droits et le commentaire.

BEGIN;

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
  -- D4 : le tuteur nait actif ; l'enseignant reste en attente de sa piece.
  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  values (v_uid, null, v_role, v_household,
    btrim(p_first_name), btrim(p_last_name), p_gender,
    case when v_role = 'guardian' then 'active' else 'pending_kyc' end::public.account_status)
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

-- Rattrapage des tuteurs deja inscrits.
UPDATE public.profiles
   SET account_status = 'active'
 WHERE role = 'guardian' AND account_status = 'pending_kyc' AND deleted_at IS NULL;

COMMIT;
