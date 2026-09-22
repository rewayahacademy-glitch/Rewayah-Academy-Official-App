-- Core24 : admissibilite titulaire, formation Admin et remplacement de session.
--
-- Cette migration complete le contrat Classes sans modifier les migrations
-- historiques. Les tables internes refusent toute ecriture directe ; les
-- transitions passent par des RPC security definer auditees.
begin;

-- ============================================================
-- 1. Conformite professionnelle et qualification
-- ============================================================

create table if not exists public.teacher_kyc_requirements (
  teacher_id uuid primary key references public.teacher_profiles(profile_id),
  required boolean not null default true,
  changed_by uuid not null references public.profiles(id),
  changed_at timestamptz not null default now(),
  reason text not null check (length(btrim(reason)) between 3 and 1000)
);
alter table public.teacher_kyc_requirements enable row level security;
revoke all on public.teacher_kyc_requirements from public, anon, authenticated, agent_ro;

create table if not exists public.teacher_qualifications (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teacher_profiles(profile_id),
  niveau_id uuid references public.programme_niveaux(id),
  cycle text,
  approved boolean not null default false,
  expires_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint teacher_qualifications_scope_check check (
    niveau_id is not null or (cycle is not null and btrim(cycle) <> '')
  )
);
alter table public.teacher_qualifications enable row level security;
revoke all on public.teacher_qualifications from public, anon, authenticated, agent_ro;
create unique index if not exists teacher_qualifications_live_uidx
  on public.teacher_qualifications (
    teacher_id,
    coalesce(niveau_id, '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(cycle, '')
  ) where deleted_at is null;

insert into public.app_config (key, value)
values ('enseignant.max_primary_groups', '2'::jsonb)
on conflict (key) do nothing;

create or replace function core24_private.enseignant_autorise(p_profile_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1
    from public.teacher_profiles t
    join public.profiles p on p.id = t.profile_id
    left join public.teacher_kyc_requirements k on k.teacher_id = t.profile_id
    where t.profile_id = p_profile_id
      and t.deleted_at is null
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('pending_kyc', 'active', 'provisional_active')
      and (p.access_until is null or p.access_until > now())
      and (t.kyc_status = 'approved' or k.required = false)
      and exists (
        select 1
        from public.contract_acceptances c
        where c.profile_id = t.profile_id
          and c.contract_kind = 'teacher_nda'
      )
  );
$function$;
revoke all on function core24_private.enseignant_autorise(uuid)
  from public, anon, authenticated, agent_ro, service_role;

create or replace function public.app_account_valid()
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.deleted_at is null
      and p.role = public.app_role()
      and (p.access_until is null or p.access_until > now())
      and (
        p.account_status in ('active', 'provisional_active')
        or (p.account_status = 'pending_kyc'
            and p.role in ('guardian', 'student', 'teacher'))
      )
      and (p.role <> 'teacher'::public.app_role
           or core24_private.enseignant_autorise(p.id))
  );
$function$;

create or replace function public.definir_exigence_kyc_enseignant(
  p_teacher_id uuid,
  p_required boolean,
  p_reason text
)
returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  v_old boolean;
  v_changed_at timestamptz;
begin
  if public.app_role() is distinct from 'admin'::public.app_role
     or not public.app_account_valid()
     or auth.uid() = p_teacher_id then
    raise exception 'action reservee a l''administration' using errcode = '42501';
  end if;
  if p_required is null or p_reason is null
     or length(btrim(p_reason)) not between 3 and 1000 then
    raise exception 'motif obligatoire' using errcode = '22023';
  end if;

  perform 1
  from public.profiles p
  join public.teacher_profiles t on t.profile_id = p.id
  where p.id = p_teacher_id
    and p.role = 'teacher'
    and p.deleted_at is null
    and t.deleted_at is null
  for update of p;
  if not found then
    raise exception 'enseignant introuvable' using errcode = '22023';
  end if;

  select required, changed_at
    into v_old, v_changed_at
  from public.teacher_kyc_requirements
  where teacher_id = p_teacher_id;
  v_old := coalesce(v_old, true);

  if v_old is distinct from p_required then
    insert into public.teacher_kyc_requirements
      (teacher_id, required, changed_by, reason)
    values
      (p_teacher_id, p_required, auth.uid(), btrim(p_reason))
    on conflict (teacher_id) do update
      set required = excluded.required,
          changed_by = excluded.changed_by,
          changed_at = now(),
          reason = excluded.reason
    returning changed_at into v_changed_at;

    perform public.log_sensitive_access(
      'teacher_kyc_requirement_changed',
      'teacher_kyc_requirements',
      p_teacher_id::text,
      jsonb_build_object(
        'old_required', v_old,
        'new_required', p_required,
        'reason', btrim(p_reason)
      )
    );
  end if;

  return jsonb_build_object(
    'teacher_id', p_teacher_id,
    'kyc_required', p_required,
    'changed_at', v_changed_at,
    'operational', core24_private.enseignant_autorise(p_teacher_id)
  );
end;
$function$;
revoke all on function public.definir_exigence_kyc_enseignant(uuid, boolean, text)
  from public, anon, agent_ro;
grant execute on function public.definir_exigence_kyc_enseignant(uuid, boolean, text)
  to authenticated;

create or replace function public.definir_qualification_enseignant(
  p_teacher_id uuid,
  p_niveau_id uuid,
  p_cycle text,
  p_approved boolean,
  p_motif text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'qualification reservee a l''administration' using errcode = '42501';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour la qualification' using errcode = '22023';
  end if;
  if p_niveau_id is null and coalesce(btrim(p_cycle), '') = '' then
    raise exception 'un niveau ou un cycle est requis' using errcode = '22023';
  end if;
  if not exists (
    select 1
    from public.profiles p
    join public.teacher_profiles t on t.profile_id = p.id
    where p.id = p_teacher_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and t.deleted_at is null
  ) then
    raise exception 'enseignant introuvable' using errcode = '22023';
  end if;
  if p_niveau_id is not null
     and not exists (select 1 from public.programme_niveaux where id = p_niveau_id) then
    raise exception 'niveau de qualification introuvable' using errcode = '22023';
  end if;

  select q.id into v_id
  from public.teacher_qualifications q
  where q.teacher_id = p_teacher_id
    and q.niveau_id is not distinct from p_niveau_id
    and q.cycle is not distinct from nullif(btrim(p_cycle), '')
    and q.deleted_at is null
  for update;

  if v_id is null then
    insert into public.teacher_qualifications
      (teacher_id, niveau_id, cycle, approved, expires_at, created_by)
    values
      (p_teacher_id, p_niveau_id, nullif(btrim(p_cycle), ''), p_approved, null, auth.uid())
    returning id into v_id;
  else
    update public.teacher_qualifications
    set approved = p_approved,
        created_by = auth.uid(),
        created_at = now()
    where id = v_id;
  end if;

  perform public.log_sensitive_access(
    'teacher_qualification_changed',
    'teacher_qualifications',
    v_id::text,
    jsonb_build_object('teacher_id', p_teacher_id, 'approved', p_approved, 'motif', p_motif)
  );
  return v_id;
end;
$function$;
revoke all on function public.definir_qualification_enseignant(uuid, uuid, text, boolean, text)
  from public, anon, agent_ro;
grant execute on function public.definir_qualification_enseignant(uuid, uuid, text, boolean, text)
  to authenticated;

-- ============================================================
-- 2. Compatibilite d'un titulaire et formation Admin
-- ============================================================

create or replace function core24_private.groupe_duree_minutes(p_groupe_id uuid)
returns integer
language sql stable security definer set search_path = ''
as $function$
  select coalesce(
    (
      select o.duree_minutes::int
      from public.groupes g
      join public.offres_horaires o on o.id = g.offre_id
      where g.id = p_groupe_id
    ),
    (
      select case when type_public = 'adulte' then 90 else 60 end
      from public.groupes where id = p_groupe_id
    ),
    60
  );
$function$;
revoke all on function core24_private.groupe_duree_minutes(uuid)
  from public, anon, authenticated, agent_ro, service_role;

create or replace function core24_private.teacher_slot_available(
  p_teacher_id uuid,
  p_weekday smallint,
  p_hour_local smallint,
  p_timezone text,
  p_duration_minutes integer
)
returns boolean
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_slot integer;
  v_target timestamptz;
begin
  for v_slot in 0..greatest(0, floor((p_duration_minutes - 1)::numeric / 60)::int) loop
    v_target := public.instant_creneau(
      p_weekday,
      p_hour_local,
      p_timezone
    ) + make_interval(mins => v_slot * 60);
    if not exists (
      select 1
      from public.weekly_availability a
      where a.profile_id = p_teacher_id
        and public.instant_creneau(a.weekday, a.hour_local, a.timezone_iana) = v_target
    ) then
      return false;
    end if;
  end loop;
  return true;
end;
$function$;
revoke all on function core24_private.teacher_slot_available(uuid, smallint, smallint, text, integer)
  from public, anon, authenticated, agent_ro, service_role;

create or replace function core24_private.enseignant_admissible_pour_groupe(
  p_teacher_id uuid,
  p_groupe_id uuid
)
returns boolean
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_groupe public.groupes;
  v_duree integer;
  v_groupes int;
begin
  select * into v_groupe
  from public.groupes
  where id = p_groupe_id and ended_at is null;
  if not found or not core24_private.enseignant_autorise(p_teacher_id) then
    return false;
  end if;

  if v_groupe.langue_code is not null and not exists (
    select 1 from public.teacher_profiles t
    where t.profile_id = p_teacher_id
      and v_groupe.langue_code = any(t.languages)
  ) then
    return false;
  end if;

  if v_groupe.niveau_id is null then
    if not exists (
      select 1 from public.teacher_qualifications q
      where q.teacher_id = p_teacher_id
        and q.deleted_at is null
        and q.approved
        and (q.expires_at is null or q.expires_at > now())
        and (q.cycle in ('generaliste', 'debutant') or q.niveau_id is null)
    ) then
      return false;
    end if;
  elsif not exists (
    select 1 from public.teacher_qualifications q
    where q.teacher_id = p_teacher_id
      and q.niveau_id = v_groupe.niveau_id
      and q.deleted_at is null
      and q.approved
      and (q.expires_at is null or q.expires_at > now())
  ) then
    return false;
  end if;

  v_duree := core24_private.groupe_duree_minutes(p_groupe_id);
  if exists (
    select 1
    from (
      select v_groupe.weekday as weekday, v_groupe.hour_local as hour_local,
             v_groupe.timezone_iana as timezone_iana
      union
      select c.weekday, c.hour_local, v_groupe.timezone_iana
      from public.groupe_creneaux c
      where c.groupe_id = p_groupe_id
    ) c
    where not core24_private.teacher_slot_available(
      p_teacher_id, c.weekday, c.hour_local, c.timezone_iana, v_duree
    )
  ) then
    return false;
  end if;

  if exists (
    with cible as (
      select distinct v_groupe.weekday as weekday,
             v_groupe.hour_local as hour_local,
             v_groupe.timezone_iana as timezone_iana
      union
      select c.weekday, c.hour_local, v_groupe.timezone_iana
      from public.groupe_creneaux c
      where c.groupe_id = p_groupe_id
    ), autres as (
      select distinct other.id, other.weekday, other.hour_local,
             other.timezone_iana
      from public.groupes other
      where other.teacher_id = p_teacher_id
        and other.id <> p_groupe_id
        and other.ended_at is null
        and other.etat <> 'cloturee'
      union
      select distinct other.id, oc.weekday, oc.hour_local,
             other.timezone_iana
      from public.groupes other
      join public.groupe_creneaux oc on oc.groupe_id = other.id
      where other.teacher_id = p_teacher_id
        and other.id <> p_groupe_id
        and other.ended_at is null
        and other.etat <> 'cloturee'
    )
    select 1
    from autres other
    cross join cible
    cross join lateral (
      select tstzrange(
        public.instant_creneau(other.weekday, other.hour_local, other.timezone_iana),
        public.instant_creneau(other.weekday, other.hour_local, other.timezone_iana)
          + make_interval(mins => core24_private.groupe_duree_minutes(other.id)),
        '[)'
      ) as plage
    ) other_plage
    cross join lateral (
      select tstzrange(
        public.instant_creneau(cible.weekday, cible.hour_local, cible.timezone_iana),
        public.instant_creneau(cible.weekday, cible.hour_local, cible.timezone_iana)
          + make_interval(mins => v_duree),
        '[)'
      ) as plage
    ) cible_plage
    where other_plage.plage && cible_plage.plage
  ) then
    return false;
  end if;

  select count(*)::int into v_groupes
  from public.groupes g
  where g.teacher_id = p_teacher_id
    and g.ended_at is null
    and g.etat <> 'cloturee'
    and g.id <> p_groupe_id;
  if v_groupes >= public.app_config_int('enseignant.max_primary_groups', 2) then
    return false;
  end if;

  return true;
end;
$function$;
revoke all on function core24_private.enseignant_admissible_pour_groupe(uuid, uuid)
  from public, anon, authenticated, agent_ro, service_role;

create or replace function public.enseignants_admissibles_groupe(p_groupe_id uuid)
returns table(
  teacher_id uuid,
  teacher_immutable_id text,
  teacher_prenom text,
  teacher_nom text,
  groupes_actifs integer,
  max_primary_groups integer
)
language sql stable security definer set search_path = ''
as $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    (
      select count(*)::int from public.groupes g2
      where g2.teacher_id = p.id and g2.ended_at is null and g2.etat <> 'cloturee'
    ),
    public.app_config_int('enseignant.max_primary_groups', 2)
  from public.profiles p
  where p.role = 'teacher'
    and p.deleted_at is null
    and core24_private.enseignant_admissible_pour_groupe(p.id, p_groupe_id)
  order by p.created_at, p.id;
$function$;
revoke all on function public.enseignants_admissibles_groupe(uuid) from public, anon, agent_ro;
grant execute on function public.enseignants_admissibles_groupe(uuid) to authenticated;

create or replace function public.affecter_titulaire_groupe(
  p_groupe_id uuid,
  p_teacher_id uuid,
  p_motif text
)
returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  v_groupe public.groupes;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'affectation reservee a l''administration' using errcode = '42501';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour affecter un titulaire' using errcode = '22023';
  end if;

  select * into v_groupe
  from public.groupes where id = p_groupe_id and ended_at is null for update;
  if not found then raise exception 'groupe introuvable ou cloture'; end if;
  perform 1 from public.profiles where id = p_teacher_id for update;
  if not found or not core24_private.enseignant_admissible_pour_groupe(p_teacher_id, p_groupe_id) then
    raise exception 'cet enseignant n''est pas admissible pour ce groupe';
  end if;

  update public.groupes set teacher_id = p_teacher_id where id = p_groupe_id;
  perform public.log_sensitive_access(
    'groupe_titulaire_affecte', 'groupes', p_groupe_id::text,
    jsonb_build_object('teacher_id', p_teacher_id, 'motif', btrim(p_motif))
  );
  return jsonb_build_object('groupe_id', p_groupe_id, 'teacher_id', p_teacher_id);
end;
$function$;
revoke all on function public.affecter_titulaire_groupe(uuid, uuid, text)
  from public, anon, agent_ro;
grant execute on function public.affecter_titulaire_groupe(uuid, uuid, text) to authenticated;

create or replace function public.transitionner_groupe_classes(
  p_groupe_id uuid,
  p_etat text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_groupe public.groupes;
  v_membres int;
  v_minimum smallint := public.app_config_int('groupe.minimum_lancement', 3)::smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'transition de groupe reservee a l''administration';
  end if;
  if p_etat not in ('ready', 'publiee', 'active') then
    raise exception 'etat de publication inconnu : %', coalesce(p_etat, 'aucun');
  end if;
  select * into v_groupe from public.groupes
  where id = p_groupe_id and ended_at is null for update;
  if not found then raise exception 'groupe introuvable ou deja cloture'; end if;
  if v_groupe.etat = 'brouillon' and p_etat not in ('ready', 'publiee') then
    raise exception 'un brouillon doit passer par ready avant active';
  end if;
  if v_groupe.etat = 'ready' and p_etat = 'active' then
    raise exception 'un groupe ready doit passer par publiee avant active';
  end if;
  if v_groupe.etat in ('publiee', 'active') and p_etat = 'ready' then
    raise exception 'retour vers ready interdit pour un groupe publie';
  end if;
  if v_groupe.teacher_id is null then
    raise exception 'un groupe publie exige un titulaire';
  end if;
  if not core24_private.enseignant_admissible_pour_groupe(v_groupe.teacher_id, p_groupe_id) then
    raise exception 'le titulaire n''est plus admissible pour ce groupe';
  end if;
  select count(*)::int into v_membres from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;
  if v_membres < v_minimum then
    raise exception 'un groupe se publie a partir de % eleves, % fournis', v_minimum, v_membres;
  end if;
  if v_membres > v_groupe.seuil_max then
    raise exception 'la capacite du groupe est depassee';
  end if;
  if v_groupe.offre_id is not null and exists (
    select 1 from public.groupe_membres m
    join public.student_profiles sp on sp.profile_id = m.student_id
    where m.groupe_id = p_groupe_id and m.left_at is null
      and (
        sp.langue_cours is distinct from v_groupe.langue_code
        or sp.cohorte is distinct from v_groupe.cohorte
        or (v_groupe.niveau_id is null and exists (
          select 1 from public.progression_historique h where h.student_id = m.student_id
        ))
        or (v_groupe.niveau_id is not null and not exists (
          select 1 from public.progression_historique h
          where h.student_id = m.student_id and h.niveau_id = v_groupe.niveau_id
        ))
      )
  ) then
    raise exception 'les membres du groupe ne sont plus compatibles';
  end if;
  update public.groupes set etat = p_etat where id = p_groupe_id;
  perform public.log_sensitive_access(
    'groupe_etat_change', 'groupes', p_groupe_id::text,
    jsonb_build_object('etat', p_etat, 'membres', v_membres)
  );
end;
$function$;
revoke all on function public.transitionner_groupe_classes(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.transitionner_groupe_classes(uuid, text) to authenticated;

-- ============================================================
-- 3. Offres et pool Admin
-- ============================================================

create or replace function public.offres_horaires_admin()
returns table(
  offre_id uuid,
  type_public text,
  langue_code text,
  langue_nom text,
  fuseau_iana text,
  jours smallint[],
  heure_locale smallint,
  duree_minutes smallint,
  rythme text,
  etat text,
  candidats bigint
)
language sql stable security definer set search_path = ''
as $function$
  select o.id, o.type_public, o.langue_code, l.nom_humain, o.fuseau_iana,
         o.jours, o.heure_locale, o.duree_minutes, o.rythme::text, o.etat,
         (select count(*) from public.intentions_horaire i
          where i.offre_id = o.id and i.etat in ('enregistree', 'en_formation'))
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  where public.app_role() = 'admin' and public.app_account_valid()
  order by o.etat, o.created_at desc;
$function$;
revoke all on function public.offres_horaires_admin() from public, anon, agent_ro;
grant execute on function public.offres_horaires_admin() to authenticated;

create or replace function public.creer_offre_horaire_admin(
  p_type_public text,
  p_langue_code text,
  p_fuseau_iana text,
  p_jours smallint[],
  p_heure_locale smallint,
  p_duree_minutes smallint
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'offre reservee a l''administration' using errcode = '42501';
  end if;
  if p_type_public not in ('enfant', 'adulte')
     or not exists (select 1 from public.langues_cours where code = p_langue_code and actif)
     or not exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana)
     or not public.jours_iso_valides(p_jours)
     or p_heure_locale not between 0 and 23
     or p_duree_minutes not between 15 and 240 then
    raise exception 'parametres d''offre invalides' using errcode = '22023';
  end if;
  insert into public.offres_horaires
    (type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, created_by)
  values
    (p_type_public, p_langue_code, p_fuseau_iana, p_jours, p_heure_locale, p_duree_minutes, auth.uid())
  returning id into v_id;
  return v_id;
end;
$function$;
revoke all on function public.creer_offre_horaire_admin(text, text, text, smallint[], smallint, smallint)
  from public, anon, agent_ro;
grant execute on function public.creer_offre_horaire_admin(text, text, text, smallint[], smallint, smallint)
  to authenticated;

create or replace function public.publier_offre_horaire_admin(p_offre_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication reservee a l''administration' using errcode = '42501';
  end if;
  update public.offres_horaires
  set etat = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_offre_id and etat = 'brouillon';
  if not found then raise exception 'offre introuvable ou deja publiee'; end if;
end;
$function$;
revoke all on function public.publier_offre_horaire_admin(uuid) from public, anon, agent_ro;
grant execute on function public.publier_offre_horaire_admin(uuid) to authenticated;

create or replace function public.retirer_offre_horaire_admin(p_offre_id uuid, p_motif text)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'retrait reserve a l''administration' using errcode = '42501';
  end if;
  if coalesce(btrim(p_motif), '') = '' then raise exception 'motif obligatoire'; end if;
  update public.offres_horaires
  set etat = 'retiree', retiree_at = now(), retiree_par = auth.uid(), retrait_motif = btrim(p_motif)
  where id = p_offre_id and etat <> 'retiree';
  if not found then raise exception 'offre introuvable ou deja retiree'; end if;
end;
$function$;
revoke all on function public.retirer_offre_horaire_admin(uuid, text) from public, anon, agent_ro;
grant execute on function public.retirer_offre_horaire_admin(uuid, text) to authenticated;

create or replace function public.intentions_pool_admin(p_offre_id uuid default null)
returns table(
  intention_id uuid,
  eleve_id uuid,
  eleve_immutable_id text,
  eleve_prenom text,
  langue_code text,
  cohorte text,
  diagnostic_statut text,
  niveau_id uuid,
  etat text,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select i.id, p.id, p.immutable_id,
         case when public.agent_identite_masquee() then null else p.first_name end,
         sp.langue_cours, sp.cohorte, sp.diagnostic_statut, courant.niveau_id,
         i.etat, i.created_at
  from public.intentions_horaire i
  join public.profiles p on p.id = i.eleve_id and p.deleted_at is null
  join public.student_profiles sp on sp.profile_id = p.id and sp.deleted_at is null
  left join lateral (
    select h.niveau_id from public.progression_historique h
    where h.student_id = p.id order by h.created_at desc, h.id desc limit 1
  ) courant on true
  where public.app_role() = 'admin' and public.app_account_valid()
    and i.etat in ('enregistree', 'en_formation')
    and (p_offre_id is null or i.offre_id = p_offre_id)
  order by i.created_at, i.id;
$function$;
revoke all on function public.intentions_pool_admin(uuid) from public, anon, agent_ro;
grant execute on function public.intentions_pool_admin(uuid) to authenticated;

-- ============================================================
-- 4. Remplacement d'une session, sans modifier le titulaire du Groupe
-- ============================================================

create table if not exists public.session_standby_requests (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null unique references public.sessions(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  status text not null default 'standby_requested'
    check (status in ('standby_requested', 'filled', 'cancelled')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id),
  deleted_at timestamptz
);
alter table public.session_standby_requests enable row level security;
revoke all on public.session_standby_requests from public, anon, authenticated, agent_ro;

create table if not exists public.session_teacher_invitations (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'revoked')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  deleted_at timestamptz,
  constraint session_teacher_invitation_once unique (session_id, teacher_id)
);
alter table public.session_teacher_invitations enable row level security;
revoke all on public.session_teacher_invitations from public, anon, authenticated, agent_ro;

create or replace function core24_private.enseignant_admissible_pour_session(
  p_teacher_id uuid,
  p_session_id uuid
)
returns boolean
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_session public.sessions;
  v_groupe public.groupes;
  v_langue text;
  v_niveau uuid;
begin
  select * into v_session from public.sessions
  where id = p_session_id and deleted_at is null;
  if not found or not core24_private.enseignant_autorise(p_teacher_id) then return false; end if;
  if v_session.groupe_id is null then
    return not exists (
      select 1 from public.sessions other
      where other.id <> p_session_id and other.teacher_id = p_teacher_id
        and other.deleted_at is null and other.status in ('planned', 'preflight', 'in_progress')
        and tstzrange(other.started_at, other.ended_at, '[)')
            && tstzrange(v_session.started_at, v_session.ended_at, '[)')
    );
  end if;
  select * into v_groupe from public.groupes where id = v_session.groupe_id and ended_at is null;
  if not found or not core24_private.enseignant_admissible_pour_groupe(p_teacher_id, v_groupe.id) then
    return false;
  end if;
  return not exists (
    select 1 from public.sessions other
    where other.id <> p_session_id and other.teacher_id = p_teacher_id
      and other.deleted_at is null and other.status in ('planned', 'preflight', 'in_progress')
      and tstzrange(other.started_at, other.ended_at, '[)')
          && tstzrange(v_session.started_at, v_session.ended_at, '[)')
  );
end;
$function$;
revoke all on function core24_private.enseignant_admissible_pour_session(uuid, uuid)
  from public, anon, authenticated, agent_ro, service_role;

create or replace function public.demander_remplacement_session(p_session_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare v_id uuid; v_session public.sessions;
begin
  select * into v_session from public.sessions where id = p_session_id and deleted_at is null for update;
  if not found then raise exception 'session introuvable'; end if;
  if not (
    (public.app_role() = 'admin' and public.app_account_valid())
    or (public.app_role() = 'teacher' and public.app_account_valid() and v_session.teacher_id = auth.uid())
  ) then raise exception 'demande de remplacement refusee' using errcode = '42501'; end if;
  if v_session.status not in ('planned', 'preflight') then
    raise exception 'la session ne peut plus demander de remplacement';
  end if;
  insert into public.session_standby_requests (session_id, requested_by)
  values (p_session_id, auth.uid())
  on conflict (session_id) do update set status = 'standby_requested', requested_by = excluded.requested_by,
    created_at = now(), resolved_at = null, resolved_by = null, deleted_at = null
  returning id into v_id;
  perform public.log_sensitive_access(
    'session_standby_requested', 'sessions', p_session_id::text, '{}'::jsonb
  );
  return v_id;
end;
$function$;
revoke all on function public.demander_remplacement_session(uuid) from public, anon, agent_ro;
grant execute on function public.demander_remplacement_session(uuid) to authenticated;

create or replace function public.remplacants_eligibles_session(p_session_id uuid)
returns table(
  teacher_id uuid,
  teacher_immutable_id text,
  teacher_prenom text,
  teacher_nom text
)
language sql stable security definer set search_path = ''
as $function$
  select p.id, p.immutable_id,
         case when public.agent_identite_masquee() then null else p.first_name end,
         case when public.agent_identite_masquee() then null else p.last_name end
  from public.profiles p
  where public.app_role() = 'admin' and public.app_account_valid()
    and p.role = 'teacher' and p.deleted_at is null
    and core24_private.enseignant_admissible_pour_session(p.id, p_session_id)
  order by p.created_at, p.id;
$function$;
revoke all on function public.remplacants_eligibles_session(uuid) from public, anon, agent_ro;
grant execute on function public.remplacants_eligibles_session(uuid) to authenticated;

create or replace function public.inviter_remplacant_session(p_session_id uuid, p_teacher_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'invitation reservee a l''administration' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.session_standby_requests r
    where r.session_id = p_session_id and r.status = 'standby_requested' and r.deleted_at is null
  ) then raise exception 'aucune demande d''astreinte ouverte'; end if;
  if not core24_private.enseignant_admissible_pour_session(p_teacher_id, p_session_id) then
    raise exception 'ce remplaçant n''est pas admissible pour la session';
  end if;
  insert into public.session_teacher_invitations (session_id, teacher_id)
  values (p_session_id, p_teacher_id)
  on conflict (session_id, teacher_id) do update
    set status = 'pending', responded_at = null, deleted_at = null
  returning id into v_id;
  return v_id;
end;
$function$;
revoke all on function public.inviter_remplacant_session(uuid, uuid) from public, anon, agent_ro;
grant execute on function public.inviter_remplacant_session(uuid, uuid) to authenticated;

create or replace function public.accepter_invitation_remplacement(p_invitation_id uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  v_invitation public.session_teacher_invitations;
  v_session public.sessions;
  v_accepted uuid;
begin
  if public.app_role() <> 'teacher' or not public.app_account_valid() then
    raise exception 'acceptation reservee a un enseignant admissible' using errcode = '42501';
  end if;
  select * into v_invitation from public.session_teacher_invitations
  where id = p_invitation_id and deleted_at is null for update;
  if not found or v_invitation.teacher_id <> auth.uid() or v_invitation.status <> 'pending' then
    raise exception 'invitation introuvable ou deja traitee';
  end if;
  select * into v_session from public.sessions where id = v_invitation.session_id and deleted_at is null for update;
  if not found or not core24_private.enseignant_admissible_pour_session(auth.uid(), v_session.id) then
    raise exception 'session indisponible pour ce remplaçant';
  end if;
  select teacher_id into v_accepted
  from public.session_teacher_invitations
  where session_id = v_session.id and status = 'accepted' and deleted_at is null
  for update;
  if v_accepted is not null then
    update public.session_teacher_invitations set status = 'revoked', responded_at = now()
    where id = p_invitation_id;
    raise exception 'un autre remplaçant a deja accepte cette session';
  end if;

  delete from public.session_participants
  where session_id = v_session.id and role = 'teacher';
  insert into public.session_participants (session_id, profile_id, role)
  values (v_session.id, auth.uid(), 'teacher');
  update public.sessions set teacher_id = auth.uid() where id = v_session.id;
  update public.session_teacher_invitations
  set status = case when id = p_invitation_id then 'accepted' else 'revoked' end,
      responded_at = now()
  where session_id = v_session.id and deleted_at is null;
  update public.session_standby_requests
  set status = 'filled', resolved_at = now(), resolved_by = auth.uid()
  where session_id = v_session.id and deleted_at is null;
  perform public.log_sensitive_access(
    'session_remplacement_accepte', 'sessions', v_session.id::text,
    jsonb_build_object('teacher_id', auth.uid(), 'groupe_id', v_session.groupe_id)
  );
  return jsonb_build_object('session_id', v_session.id, 'teacher_id', auth.uid());
end;
$function$;
revoke all on function public.accepter_invitation_remplacement(uuid) from public, anon, agent_ro;
grant execute on function public.accepter_invitation_remplacement(uuid) to authenticated;

commit;
