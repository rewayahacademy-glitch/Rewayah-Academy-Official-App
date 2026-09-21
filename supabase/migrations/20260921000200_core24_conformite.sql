-- Core24 P0.2 : exigences separees du statut de compte.
begin;

create schema if not exists core24_private;
revoke all on schema core24_private from public, anon, authenticated, agent_ro;

-- L'absence de ligne signifie requis. Aucun nouvel enseignant n'est dispense.
create table public.teacher_kyc_requirements (
  teacher_id uuid primary key references public.teacher_profiles(profile_id),
  required boolean not null default true,
  changed_by uuid not null references public.profiles(id),
  changed_at timestamptz not null default now(),
  reason text not null check (length(btrim(reason)) between 3 and 1000)
);
alter table public.teacher_kyc_requirements enable row level security;
revoke all on public.teacher_kyc_requirements from public, anon, authenticated, agent_ro;

create function core24_private.enseignant_autorise(p_profile_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.teacher_profiles t
    join public.profiles p on p.id = t.profile_id
    left join public.teacher_kyc_requirements k on k.teacher_id = t.profile_id
    where t.profile_id = p_profile_id and t.deleted_at is null
      and p.role = 'teacher' and p.deleted_at is null
      and p.account_status in ('pending_kyc', 'active', 'provisional_active')
      and (p.access_until is null or p.access_until > now())
      and (t.kyc_status = 'approved' or k.required = false)
      and exists (select 1 from public.contract_acceptances c
                  where c.profile_id = t.profile_id and c.contract_kind = 'teacher_nda')
  );
$$;

-- Le helper historique protege les surfaces operationnelles. Les surfaces
-- d'onboarding (mon_dossier, signatures, depot KYC) gardent leurs droits propres.
-- Aucun statut de profil n'est modifie, notamment provisional_active.
create or replace function public.app_account_valid()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.deleted_at is null
      and (p.access_until is null or p.access_until > now())
      and (
        p.account_status in ('active', 'provisional_active')
        or (p.account_status = 'pending_kyc'
            and public.app_role() in ('guardian', 'student', 'teacher'))
      )
      and (public.app_role() is distinct from 'teacher'::public.app_role
           or core24_private.enseignant_autorise(p.id))
  );
$$;

create function public.definir_exigence_kyc_enseignant(
  p_teacher_id uuid, p_required boolean, p_reason text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_ancien boolean; v_date timestamptz;
begin
  if public.app_role() is distinct from 'admin'::public.app_role
     or not public.app_account_valid() or auth.uid() = p_teacher_id then
    raise exception 'action reservee a l''administration' using errcode = '42501';
  end if;
  if p_required is null or p_reason is null or length(btrim(p_reason)) not between 3 and 1000 then
    raise exception 'motif obligatoire' using errcode = '22023';
  end if;
  -- Le verrou de profil serialise aussi la premiere dispense (pas de ligne).
  perform 1 from public.profiles p join public.teacher_profiles t on t.profile_id = p.id
    where p.id = p_teacher_id and p.role = 'teacher'
      and p.deleted_at is null and t.deleted_at is null for update of p;
  if not found then raise exception 'enseignant introuvable' using errcode = '22023'; end if;
  select required, changed_at into v_ancien, v_date
    from public.teacher_kyc_requirements where teacher_id = p_teacher_id;
  v_ancien := coalesce(v_ancien, true);
  if v_ancien is distinct from p_required then
    insert into public.teacher_kyc_requirements(teacher_id, required, changed_by, reason)
      values (p_teacher_id, p_required, auth.uid(), btrim(p_reason))
    on conflict (teacher_id) do update
      set required = excluded.required, changed_by = excluded.changed_by,
          changed_at = now(), reason = excluded.reason
    returning changed_at into v_date;
    perform public.log_sensitive_access('teacher_kyc_requirement_changed',
      'teacher_kyc_requirements', p_teacher_id::text,
      jsonb_build_object('old_required', v_ancien, 'new_required', p_required,
                         'reason', btrim(p_reason), 'changed_at', v_date));
  end if;
  return jsonb_build_object('kyc_required', p_required, 'changed_at', v_date,
    'operational', core24_private.enseignant_autorise(p_teacher_id));
end;
$$;
revoke all on function public.definir_exigence_kyc_enseignant(uuid, boolean, text)
  from public, anon, agent_ro;
grant execute on function public.definir_exigence_kyc_enseignant(uuid, boolean, text) to authenticated;

create function core24_private.photo_mineur_presente(p_profile_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.student_profiles s join storage.objects o
      on o.bucket_id = 'avatars' and o.name = s.avatar_storage_key
    where s.profile_id = p_profile_id and s.deleted_at is null
      and (storage.foldername(o.name))[1] = p_profile_id::text
  );
$$;

create function public.conformite_classe(p_profile_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_id uuid := coalesce(p_profile_id, auth.uid()); v_profil public.profiles;
  v_requis boolean; v_kyc text; v_contrat boolean; v_mineur boolean; v_photo boolean;
begin
  if auth.uid() is null or not (
    v_id = auth.uid()
    or (public.app_role() = 'admin' and public.app_account_valid())
    or (public.app_role() = 'guardian' and public.app_account_valid() and public.est_du_foyer(v_id))
  ) then raise exception 'acces refuse' using errcode = '42501'; end if;
  select * into v_profil from public.profiles where id = v_id and deleted_at is null;
  if not found then raise exception 'profil introuvable' using errcode = '42501'; end if;
  select coalesce(k.required, true), t.kyc_status into v_requis, v_kyc
    from public.teacher_profiles t left join public.teacher_kyc_requirements k on k.teacher_id = t.profile_id
    where t.profile_id = v_id and t.deleted_at is null;
  select exists (select 1 from public.contract_acceptances
    where profile_id = v_id and contract_kind = 'teacher_nda') into v_contrat;
  select exists (select 1 from public.student_profiles
    where profile_id = v_id and student_type = 'minor' and deleted_at is null) into v_mineur;
  v_photo := core24_private.photo_mineur_presente(v_id);
  return jsonb_build_object(
    'account_status', v_profil.account_status,
    'kyc_requirement', case when v_profil.role <> 'teacher' then 'optional'
      when coalesce(v_requis, true) then 'required' else 'waived' end,
    'kyc_status', coalesce(v_kyc, 'pending'), 'teacher_contract_accepted', v_contrat,
    'teacher_operational', core24_private.enseignant_autorise(v_id),
    'live_photo_required', v_mineur, 'live_photo_uploaded', v_photo);
end;
$$;
revoke all on function public.conformite_classe(uuid) from public, anon, agent_ro;
grant execute on function public.conformite_classe(uuid) to authenticated;

-- Conserver le moteur existant, le rendre inaccessible par RPC directe.
alter function public.autoriser_jeton_video(uuid, uuid, text, text) set schema core24_private;
revoke all on function core24_private.autoriser_jeton_video(uuid, uuid, text, text)
  from public, anon, authenticated, agent_ro, service_role;
create function public.autoriser_jeton_video(
  p_session_id uuid, p_profile_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text
) returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare v_profil public.profiles;
begin
  -- Ne fournir les raisons de conformite qu'au participant reel.
  if not exists (select 1 from public.session_participants
    where session_id = p_session_id and profile_id = p_profile_id and deleted_at is null) then
    raise exception 'acces_salle_refuse' using errcode = '42501';
  end if;
  select * into v_profil from public.profiles where id = p_profile_id and deleted_at is null;
  if not found or v_profil.account_status = 'disabled'
    or (v_profil.account_status = 'pending_kyc' and v_profil.role not in ('teacher', 'student', 'guardian'))
    or (v_profil.access_until is not null and v_profil.access_until <= now()) then
    raise exception 'compte_inactif' using errcode = '42501';
  end if;
  if v_profil.role = 'teacher' and not core24_private.enseignant_autorise(p_profile_id) then
    raise exception 'conformite_enseignant_requise' using errcode = '42501';
  end if;
  if exists (select 1 from public.student_profiles where profile_id = p_profile_id
    and student_type = 'minor' and deleted_at is null)
    and not core24_private.photo_mineur_presente(p_profile_id) then
    raise exception 'photo_identification_requise' using errcode = '42501';
  end if;
  return core24_private.autoriser_jeton_video(
    p_session_id, p_profile_id, p_ws_url_cloud, p_ws_url_self_hosted);
end;
$$;
revoke all on function public.autoriser_jeton_video(uuid, uuid, text, text)
  from public, anon, authenticated, agent_ro;
grant execute on function public.autoriser_jeton_video(uuid, uuid, text, text) to service_role;
revoke all on all functions in schema core24_private from public, anon, authenticated, agent_ro, service_role;
notify pgrst, 'reload schema';
commit;
