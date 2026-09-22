-- CORE24 : demande d'affichage standard d'un profil enfant.
--
-- L'enfant peut demander a partir de 10 ans revolus, mais ne change jamais
-- lui-meme son interface. Le tuteur tranche par RPC. La date de naissance
-- reste dans student_profiles et ne rejoint pas la vue mise en cache par les
-- appareils du foyer.

alter table public.student_profiles
  add column if not exists interface_standard_request_status text
    not null default 'none'
    check (interface_standard_request_status in ('none', 'pending', 'declined')),
  add column if not exists interface_standard_requested_at timestamptz,
  add column if not exists interface_standard_decided_at timestamptz;

comment on column public.student_profiles.interface_standard_request_status is
  'Demande enfant d affichage standard : none, pending ou declined.';
comment on column public.student_profiles.interface_standard_requested_at is
  'Instant de la derniere demande d affichage standard.';
comment on column public.student_profiles.interface_standard_decided_at is
  'Instant de la decision du tuteur ou de l administration.';

-- La famille continue a ecrire la camera et la photo, mais jamais directement
-- l interface. Les transitions passent par les fonctions nommees ci-dessous.
revoke update on public.student_profiles from authenticated;
grant update (camera_policy, avatar_storage_key)
  on public.student_profiles to authenticated;

drop policy if exists student_profiles_family on public.student_profiles;
create policy student_profiles_family on public.student_profiles
  for select to authenticated using (
    public.app_role() in ('guardian', 'controller', 'accountant')
    and exists (
      select 1
      from public.profiles p
      where p.id = student_profiles.profile_id
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
    and deleted_at is null
  );

drop policy if exists student_profiles_self on public.student_profiles;
create policy student_profiles_self on public.student_profiles
  for select to authenticated using (
    profile_id = auth.uid()
    and deleted_at is null
  );

create or replace function public.demander_affichage_standard()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.student_profiles%rowtype;
  v_age int;
begin
  if public.app_role() <> 'student' or auth.uid() is null then
    raise exception 'seul l eleve connecte peut demander un affichage standard';
  end if;

  select * into v_profile
  from public.student_profiles
  where profile_id = auth.uid() and deleted_at is null
  for update;

  if not found then
    raise exception 'profil eleve introuvable';
  end if;
  if v_profile.interface_mode = 'standard' then
    return jsonb_build_object('status', 'standard', 'eligible', true);
  end if;
  if v_profile.date_naissance is null then
    raise exception 'date de naissance inconnue';
  end if;

  v_age := extract(year from age(current_date, v_profile.date_naissance))::int;
  if v_age < 10 then
    raise exception 'demande indisponible avant 10 ans revolus';
  end if;

  update public.student_profiles
  set interface_standard_request_status = 'pending',
      interface_standard_requested_at = now(),
      interface_standard_decided_at = null
  where profile_id = auth.uid();

  return jsonb_build_object('status', 'pending', 'eligible', true);
end;
$$;

create or replace function public.repondre_demande_affichage_standard(
  p_student_profile_id uuid,
  p_accepter boolean
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.student_profiles%rowtype;
begin
  if public.app_role() not in ('guardian', 'admin') then
    raise exception 'seul le tuteur ou l administration peut repondre';
  end if;

  select sp.* into v_profile
  from public.student_profiles sp
  join public.profiles p on p.id = sp.profile_id
  where sp.profile_id = p_student_profile_id
    and sp.deleted_at is null
    and p.deleted_at is null
    and (
      public.app_role() = 'admin'
      or p.household_id = public.app_household_id()
    )
  for update;

  if not found then
    raise exception 'profil enfant hors du foyer';
  end if;
  if v_profile.interface_mode <> 'child'
     or v_profile.interface_standard_request_status <> 'pending' then
    raise exception 'aucune demande en attente';
  end if;

  update public.student_profiles
  set interface_mode = case when p_accepter then 'standard' else 'child' end,
      interface_standard_request_status = case
        when p_accepter then 'none' else 'declined' end,
      interface_standard_decided_at = now()
  where profile_id = p_student_profile_id;

  perform public.log_sensitive_access(
    'reponse_affichage_standard',
    'student_profiles',
    p_student_profile_id::text,
    jsonb_build_object('accepted', p_accepter)
  );

  return jsonb_build_object(
    'status', case when p_accepter then 'standard' else 'declined' end,
    'accepted', p_accepter
  );
end;
$$;

create or replace function public.repasser_interface_guidee(
  p_student_profile_id uuid
) returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.app_role() not in ('guardian', 'admin') then
    raise exception 'seul le tuteur ou l administration peut modifier l interface';
  end if;

  update public.student_profiles sp
  set interface_mode = 'child',
      interface_standard_request_status = 'none',
      interface_standard_decided_at = now()
  where sp.profile_id = p_student_profile_id
    and sp.deleted_at is null
    and exists (
      select 1
      from public.profiles p
      where p.id = sp.profile_id
        and p.deleted_at is null
        and (
          public.app_role() = 'admin'
          or p.household_id = public.app_household_id()
        )
    );

  if not found then
    raise exception 'profil enfant hors du foyer';
  end if;
end;
$$;

-- Chemin distinct : le tuteur peut activer l'affichage standard sans qu'une
-- demande enfant existe. L'absence de demande n'est donc jamais un refus
-- implicite de l'action du tuteur.
create or replace function public.activer_affichage_standard_tuteur(
  p_student_profile_id uuid
) returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.app_role() not in ('guardian', 'admin') then
    raise exception 'seul le tuteur ou l administration peut activer l affichage';
  end if;

  update public.student_profiles sp
  set interface_mode = 'standard',
      interface_standard_request_status = 'none',
      interface_standard_decided_at = now()
  where sp.profile_id = p_student_profile_id
    and sp.deleted_at is null
    and exists (
      select 1
      from public.profiles p
      where p.id = sp.profile_id
        and p.deleted_at is null
        and (
          public.app_role() = 'admin'
          or p.household_id = public.app_household_id()
        )
    );

  if not found then
    raise exception 'profil enfant hors du foyer';
  end if;

  perform public.log_sensitive_access(
    'activation_affichage_standard_tuteur',
    'student_profiles',
    p_student_profile_id::text,
    jsonb_build_object('source', 'guardian')
  );
end;
$$;

create or replace function public.interface_guidee_etat()
returns table(
  interface_mode public.interface_mode,
  eligible boolean,
  request_status text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.student_profiles%rowtype;
  v_age int;
begin
  if public.app_role() <> 'student' or auth.uid() is null then
    raise exception 'seul l eleve connecte peut lire cet etat';
  end if;

  select * into v_profile
  from public.student_profiles
  where profile_id = auth.uid() and deleted_at is null;

  if not found then
    raise exception 'profil eleve introuvable';
  end if;

  v_age := case
    when v_profile.date_naissance is null then null
    else extract(year from age(current_date, v_profile.date_naissance))::int
  end;

  return query select
    v_profile.interface_mode,
    v_profile.date_naissance is not null and v_age >= 10,
    v_profile.interface_standard_request_status;
end;
$$;

revoke execute on function public.demander_affichage_standard() from public, anon;
grant execute on function public.demander_affichage_standard() to authenticated;
revoke execute on function public.repondre_demande_affichage_standard(uuid, boolean)
  from public, anon;
grant execute on function public.repondre_demande_affichage_standard(uuid, boolean)
  to authenticated;
revoke execute on function public.repasser_interface_guidee(uuid) from public, anon;
grant execute on function public.repasser_interface_guidee(uuid) to authenticated;
revoke execute on function public.activer_affichage_standard_tuteur(uuid)
  from public, anon;
grant execute on function public.activer_affichage_standard_tuteur(uuid)
  to authenticated;
revoke execute on function public.interface_guidee_etat() from public, anon;
grant execute on function public.interface_guidee_etat() to authenticated;

create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  p.first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key,
  p.access_until,
  sp.interface_standard_request_status
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null;
