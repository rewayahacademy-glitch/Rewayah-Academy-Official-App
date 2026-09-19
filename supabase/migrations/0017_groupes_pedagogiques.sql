-- 0017 — Les groupes pedagogiques, le noyau du pivot 1-a-1 -> groupe
--
-- Le produit change de modele : les cours ne sont plus donnes 1 eleve /
-- 1 enseignant, mais par groupe (5 enfants max, 6 adultes max), et c'est dans
-- ce groupe que la visio et tout le reste se derouleront. Cette migration
-- pose les fondations : `groupes` et `groupe_membres`, plafonnees par un
-- declencheur, geree par l'administration via des fonctions dediees, et ouvre
-- la capacite video multi-participants deja prevue par l'ADR-004.
--
-- Perimetre explicite de ce lot : `teacher_student_assignments` (le 1-a-1
-- actuel) et tout ce qui en depend (ENS-06, ADM-05, ADM-06,
-- indicateurs_admin, comptes_admin) ne sont PAS touches ici. Les deux
-- modeles coexistent le temps d'un lot dedie qui rebranchera les dependants
-- avec l'audit RLS que cela merite. Aucune donnee de production n'existe a
-- ce jour (comptes de test uniquement) : aucun script de migration de
-- donnees n'est necessaire.

-- ============================================================
-- 1. La table des groupes
-- ============================================================

create table public.groupes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  type_public text not null check (type_public in ('enfant', 'adulte')),
  -- 5 pour un groupe d'enfants, 6 pour un groupe d'adultes par defaut, mais
  -- l'administration doit pouvoir l'ajuster groupe par groupe.
  seuil_max smallint not null check (seuil_max between 1 and 6),
  libelle text not null check (btrim(libelle) <> ''),
  -- ISO : 1 = lundi, 7 = dimanche, comme extract(isodow) et comme
  -- teacher_student_assignments.
  weekday smallint not null check (weekday between 1 and 7),
  hour_local smallint not null check (hour_local between 0 and 23),
  timezone_iana text not null default 'Europe/Paris',
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references public.profiles(id),
  end_reason text,
  constraint groupes_end_complete check (
    (ended_at is null and ended_by is null and end_reason is null)
    or (ended_at is not null and ended_by is not null and coalesce(btrim(end_reason), '') <> '')
  )
);

create index groupes_teacher_actif_idx
  on public.groupes (teacher_id) where ended_at is null;

comment on table public.groupes is
  'Une classe collective : un enseignant, jusqu''a seuil_max eleves, un '
  'creneau hebdomadaire partage. Aucune policy d''ecriture directe : seules '
  'les fonctions de cette migration ecrivent ici.';

alter table public.groupes enable row level security;

revoke all on public.groupes from anon;
revoke insert, update, delete on public.groupes from public, anon, authenticated;

-- ============================================================
-- 2. Les membres du groupe
-- ============================================================

create table public.groupe_membres (
  id uuid primary key default gen_random_uuid(),
  groupe_id uuid not null references public.groupes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  left_by uuid references public.profiles(id),
  left_reason text,
  constraint groupe_membres_end_complete check (
    (left_at is null and left_by is null and left_reason is null)
    or (left_at is not null and left_by is not null and coalesce(btrim(left_reason), '') <> '')
  )
);

-- Un eleve n'appartient qu'a un seul groupe actif a la fois -- le meme
-- invariant que l'ancien assignments_one_active_teacher_uidx, deplace au
-- niveau du groupe plutot que de l'enseignant.
create unique index groupe_membres_actif_uidx
  on public.groupe_membres (student_id) where left_at is null;

create index groupe_membres_groupe_actif_idx
  on public.groupe_membres (groupe_id) where left_at is null;

comment on table public.groupe_membres is
  'L''appartenance d''un eleve a un groupe. Un eleve a au plus un groupe '
  'actif. Aucune policy d''ecriture directe : seules les fonctions de cette '
  'migration ecrivent ici.';

alter table public.groupe_membres enable row level security;

revoke all on public.groupe_membres from anon;
revoke insert, update, delete on public.groupe_membres from public, anon, authenticated;

-- ============================================================
-- 3. Le plafond se tranche en base
-- ============================================================

create function public.guard_groupe_membre_cap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_max smallint;
  v_actifs int;
  v_groupe_ended timestamptz;
begin
  if new.left_at is not null then
    return new;
  end if;

  select seuil_max, ended_at into v_max, v_groupe_ended
  from public.groupes
  where id = new.groupe_id;

  if v_groupe_ended is not null then
    raise exception 'ce groupe est cloture, aucun nouveau membre ne peut y entrer';
  end if;

  select count(*) into v_actifs
  from public.groupe_membres m
  where m.groupe_id = new.groupe_id and m.left_at is null and m.id <> new.id;

  if v_actifs >= v_max then
    raise exception 'plafond de membres atteint pour ce groupe (%)', v_max;
  end if;

  return new;
end;
$$;

create trigger groupe_membres_cap
before insert on public.groupe_membres
for each row execute function public.guard_groupe_membre_cap();

-- ============================================================
-- 4. Lecture : l'enseignant du groupe, ses membres et leur foyer, et
--    l'administration
-- ============================================================

create policy groupes_lecture on public.groupes
for select to authenticated
using (
  public.app_role() = 'admin'
  or teacher_id = auth.uid()
  or exists (
    select 1 from public.groupe_membres m
    join public.profiles p on p.id = m.student_id
    where m.groupe_id = groupes.id
      and m.left_at is null
      and (p.id = auth.uid() or p.household_id = public.app_household_id())
  )
);

create policy groupe_membres_lecture on public.groupe_membres
for select to authenticated
using (
  public.app_role() = 'admin'
  or exists (
    select 1 from public.groupes g
    where g.id = groupe_membres.groupe_id and g.teacher_id = auth.uid()
  )
  or exists (
    select 1 from public.profiles p
    where p.id = groupe_membres.student_id
      and (p.id = auth.uid() or p.household_id = public.app_household_id())
  )
);

-- ============================================================
-- 5. Les fonctions d'administration
-- ============================================================

create function public.creer_groupe(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_weekday smallint,
  p_hour_local smallint,
  p_seuil_max smallint default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if public.app_role() <> 'admin' then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  v_seuil := coalesce(p_seuil_max, case p_type_public when 'enfant' then 5 when 'adulte' then 6 end);

  insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
  values (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$;

create function public.modifier_groupe(
  p_groupe_id uuid,
  p_libelle text,
  p_seuil_max smallint,
  p_weekday smallint,
  p_hour_local smallint
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_actifs int;
begin
  if public.app_role() <> 'admin' then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle, seuil_max = p_seuil_max, weekday = p_weekday, hour_local = p_hour_local
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$;

create function public.ajouter_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if exists (
    select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null
  ) then
    raise exception 'cet eleve appartient deja a un groupe actif';
  end if;

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);

  perform public.log_sensitive_access(
    'eleve_ajoute_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create function public.retirer_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'retrait d''un eleve d''un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer un eleve d''un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = p_motif
  where groupe_id = p_groupe_id and student_id = p_student_profile_id and left_at is null;

  if not found then
    raise exception 'cet eleve n''est pas membre actif de ce groupe';
  end if;

  perform public.log_sensitive_access(
    'eleve_retire_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create function public.cloturer_groupe(
  p_groupe_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$;

-- ============================================================
-- 6. Les lectures pour l'ecran Admin
-- ============================================================

create function public.groupes_admin()
returns table(
  groupe_id uuid,
  libelle text,
  type_public text,
  seuil_max smallint,
  teacher_id uuid,
  teacher_immutable_id text,
  teacher_prenom text,
  teacher_nom text,
  weekday smallint,
  hour_local smallint,
  nombre_membres int,
  actif boolean,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    g.id,
    g.libelle,
    g.type_public,
    g.seuil_max,
    g.teacher_id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    g.weekday,
    g.hour_local,
    (select count(*)::int from public.groupe_membres m where m.groupe_id = g.id and m.left_at is null),
    g.ended_at is null,
    g.created_at
  from public.groupes g
  join public.profiles p on p.id = g.teacher_id
  where public.app_role() = 'admin'
  order by (g.ended_at is not null), g.created_at desc;
$function$;

comment on function public.groupes_admin() is
  'Liste des groupes pedagogiques pour l''ecran Admin > Operations > Groupes.';

create function public.groupe_detail(p_groupe_id uuid)
returns table(
  student_id uuid,
  student_immutable_id text,
  student_prenom text,
  student_nom text,
  joined_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    m.joined_at
  from public.groupe_membres m
  join public.profiles p on p.id = m.student_id
  where public.app_role() = 'admin'
    and m.groupe_id = p_groupe_id
    and m.left_at is null
  order by m.joined_at asc;
$function$;

comment on function public.groupe_detail(uuid) is
  'Les membres actifs d''un groupe, pour le panneau de detail de l''ecran Admin > Operations > Groupes.';

-- ============================================================
-- 7. Les droits -- agent_ro doit les recevoir explicitement (leçon de 0014/0015)
-- ============================================================

grant execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint) to authenticated, agent_ro;
grant execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint) to authenticated, agent_ro;
grant execute on function public.ajouter_eleve_groupe(uuid, uuid, text) to authenticated, agent_ro;
grant execute on function public.retirer_eleve_groupe(uuid, uuid, text) to authenticated, agent_ro;
grant execute on function public.cloturer_groupe(uuid, text) to authenticated, agent_ro;
grant execute on function public.groupes_admin() to authenticated, agent_ro;
grant execute on function public.groupe_detail(uuid) to authenticated, agent_ro;

-- ============================================================
-- 8. La visio de groupe -- la capacite etait deja prevue (ADR-004)
-- ============================================================

update public.app_config set value = 'true'::jsonb, updated_at = now()
where key = 'allow_multi_participant_sessions';

update public.app_config set value = '7'::jsonb, updated_at = now()
where key = 'max_participants_per_session';
