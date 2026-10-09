-- 0058 — comptes actifs, propriété et flux des outils pédagogiques.
-- Les tables viennent de 0032; cette migration ne change pas leur modèle métier.
begin;

-- Les policies d'assignation consultent groupes et groupe_membres, dont les
-- propres policies se referment mutuellement. Ces helpers privés lisent les
-- relations sous RLS contournée, avec une décision bornée à l'appelant courant.
create schema if not exists private;
revoke all on schema private from public, anon, agent_ro;
grant usage on schema private to authenticated;

create or replace function private.tc_assignment_teacher_owns_group(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    public.app_account_valid()
    and public.app_role() = 'teacher'
    and exists (
      select 1
        from public.groupes g
       where g.id = p_group_id
         and g.teacher_id = auth.uid()
         and g.ended_at is null
    ),
    false
  );
$function$;

create or replace function private.tc_assignment_teacher_owns_member(
  p_group_id uuid,
  p_student_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    private.tc_assignment_teacher_owns_group(p_group_id)
    and p_student_id is not null
    and exists (
      select 1
        from public.groupe_membres gm
       where gm.groupe_id = p_group_id
         and gm.student_id = p_student_id
         and gm.left_at is null
    ),
    false
  );
$function$;

create or replace function private.tc_assignment_member_visible(
  p_group_id uuid,
  p_student_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    public.app_account_valid()
    and public.app_role() in ('student', 'guardian')
    and exists (
      select 1
        from public.groupe_membres gm
        join public.profiles p on p.id = gm.student_id
       where gm.groupe_id = p_group_id
         and gm.left_at is null
         and (p_student_id is null or gm.student_id = p_student_id)
         and (
           gm.student_id = auth.uid()
           or p.household_id = public.app_household_id()
         )
    ),
    false
  );
$function$;

revoke all on function private.tc_assignment_teacher_owns_group(uuid)
  from public, anon, agent_ro;
grant execute on function private.tc_assignment_teacher_owns_group(uuid)
  to authenticated;
revoke all on function private.tc_assignment_teacher_owns_member(uuid, uuid)
  from public, anon, agent_ro;
grant execute on function private.tc_assignment_teacher_owns_member(uuid, uuid)
  to authenticated;
revoke all on function private.tc_assignment_member_visible(uuid, uuid)
  from public, anon, agent_ro;
grant execute on function private.tc_assignment_member_visible(uuid, uuid)
  to authenticated;

-- Une assignation de groupe garde un statut partagé. Seul l'enseignant actif
-- propriétaire du groupe et auteur de la ligne la crée ou la modifie.
drop policy if exists learning_assignment_enseignant on public.learning_assignment;
create policy learning_assignment_enseignant on public.learning_assignment
  for all to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and public.app_role() = 'teacher'
      and created_by = auth.uid()
      and private.tc_assignment_teacher_owns_group(learning_assignment.group_id),
      false
    )
  )
  with check (
    coalesce(
      public.app_account_valid()
      and public.app_role() = 'teacher'
      and created_by = auth.uid()
      and private.tc_assignment_teacher_owns_group(learning_assignment.group_id)
      and (
        student_id is null
        or private.tc_assignment_teacher_owns_member(learning_assignment.group_id, learning_assignment.student_id)
      )
      and (
        resource_version_id is null
        or exists (
          select 1 from public.resource_version rv
           where rv.id = learning_assignment.resource_version_id
             and rv.resource_id = learning_assignment.resource_id
        )
      )
      and (
        content_range is null
        or (
          pg_catalog.jsonb_typeof(content_range) = 'object'
          and content_range ->> 'resource_id' = learning_assignment.resource_id::text
        )
      ),
      false
    )
  );

drop policy if exists learning_assignment_membres on public.learning_assignment;
create policy learning_assignment_membres on public.learning_assignment
  for select to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and public.app_role() in ('student', 'guardian')
      and private.tc_assignment_member_visible(learning_assignment.group_id, learning_assignment.student_id),
      false
    )
  );

drop policy if exists learning_assignment_admin on public.learning_assignment;
create policy learning_assignment_admin on public.learning_assignment
  for select to authenticated
  using (coalesce(public.app_account_valid() and public.app_role() = 'admin', false));

-- Une couche temporaire reste en memoire. Les couches personnelles persistantes
-- appartiennent à leur auteur; celles de séance sont écrites par l'enseignant
-- actif qui possède la séance et lues par les participants autorisés.
drop policy if exists annotation_layer_auteur on public.annotation_layer;
create policy annotation_layer_auteur on public.annotation_layer
  for all to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and auteur_profile_id = auth.uid(),
      false
    )
  )
  with check (
    coalesce(
      public.app_account_valid()
      and auteur_profile_id = auth.uid()
      and portee <> 'temporaire'
      and (
        session_id is null
        or (
          public.app_role() = 'teacher'
          and public.session_belongs_to_teacher(session_id, auth.uid())
        )
      )
      and (
        resource_version_id is null
        or exists (
          select 1 from public.resource_version rv
           where rv.id = annotation_layer.resource_version_id
             and rv.resource_id = annotation_layer.resource_id
        )
      ),
      false
    )
  );

drop policy if exists annotation_layer_participants_seance on public.annotation_layer;
create policy annotation_layer_participants_seance on public.annotation_layer
  for select to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and portee = 'seance'
      and session_id is not null
      and exists (
        select 1 from public.session_participants sp
         where sp.session_id = annotation_layer.session_id
           and sp.profile_id = auth.uid()
           and sp.deleted_at is null
      ),
      false
    )
  );

drop policy if exists annotation_layer_admin on public.annotation_layer;
create policy annotation_layer_admin on public.annotation_layer
  for select to authenticated
  using (coalesce(public.app_account_valid() and public.app_role() = 'admin', false));

drop policy if exists annotation_trait_lecture on public.annotation_trait;
create policy annotation_trait_lecture on public.annotation_trait
  for select to authenticated using (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l where l.id = annotation_trait.layer_id
    ), false)
  );

drop policy if exists annotation_trait_ecriture on public.annotation_trait;
create policy annotation_trait_ecriture on public.annotation_trait
  for all to authenticated
  using (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l
       where l.id = annotation_trait.layer_id
         and l.auteur_profile_id = auth.uid()
    ), false)
  )
  with check (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l
       where l.id = annotation_trait.layer_id
         and l.auteur_profile_id = auth.uid()
    ), false)
  );

drop policy if exists annotation_marqueur_lecture on public.annotation_marqueur;
create policy annotation_marqueur_lecture on public.annotation_marqueur
  for select to authenticated using (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l where l.id = annotation_marqueur.layer_id
    ), false)
  );

drop policy if exists annotation_marqueur_ecriture on public.annotation_marqueur;
create policy annotation_marqueur_ecriture on public.annotation_marqueur
  for all to authenticated
  using (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l
       where l.id = annotation_marqueur.layer_id
         and l.auteur_profile_id = auth.uid()
    ), false)
  )
  with check (
    coalesce(public.app_account_valid() and exists (
      select 1 from public.annotation_layer l
       where l.id = annotation_marqueur.layer_id
         and l.auteur_profile_id = auth.uid()
    ), false)
  );

-- Le contrat annule le dernier geste, qu'il soit trait ou marqueur. Un temps
-- serveur sur les deux tables permet de comparer leur ordre sans conserver un
-- historique du contenu.
alter table public.annotation_marqueur
  add column if not exists cree_le timestamptz not null default pg_catalog.now();

create or replace function public.tc_annotation_valider_trait()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_resource_id uuid;
begin
  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = new.layer_id
   for update;
  if v_resource_id is null
     or pg_catalog.jsonb_typeof(new.ancrage) <> 'object'
     or new.ancrage ->> 'resource_id' is distinct from v_resource_id::text
     or pg_catalog.jsonb_typeof(new.points) <> 'array' then
    raise exception 'trait incompatible avec la couche';
  end if;
  return new;
end;
$function$;

create or replace function public.tc_annotation_valider_marqueur()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_resource_id uuid;
begin
  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = new.layer_id;
  if v_resource_id is null
     or pg_catalog.jsonb_typeof(new.plage) <> 'object'
     or new.plage ->> 'resource_id' is distinct from v_resource_id::text then
    raise exception 'marqueur incompatible avec la couche';
  end if;
  return new;
end;
$function$;

create or replace function public.tc_poser_annotation_marqueur(
  p_layer_id uuid,
  p_id uuid,
  p_plage jsonb,
  p_intention text,
  p_note text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_resource_id uuid;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte inactif' using errcode = '42501';
  end if;

  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = p_layer_id
     and l.auteur_profile_id = auth.uid()
   for update;
  if v_resource_id is null then
    raise exception 'couche inaccessible' using errcode = '42501';
  end if;
  if p_id is null or p_plage is null
     or pg_catalog.jsonb_typeof(p_plage) <> 'object'
     or p_plage ->> 'resource_id' is distinct from v_resource_id::text
     or not coalesce(p_intention in ('learn', 'review', 'reinforce', 'maintain', 'assessment'), false) then
    raise exception 'marqueur invalide';
  end if;

  delete from public.annotation_marqueur
   where layer_id = p_layer_id and plage = p_plage;
  insert into public.annotation_marqueur (id, layer_id, plage, intention, note)
  values (p_id, p_layer_id, p_plage, p_intention, p_note);
end;
$function$;

create or replace function public.tc_annuler_derniere_annotation(p_layer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_layer public.annotation_layer%rowtype;
  v_type text;
  v_id uuid;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte inactif' using errcode = '42501';
  end if;

  select * into v_layer
    from public.annotation_layer l
   where l.id = p_layer_id
     and l.auteur_profile_id = auth.uid()
   for update;
  if not found then
    raise exception 'couche inaccessible' using errcode = '42501';
  end if;

  select geste.type, geste.id into v_type, v_id
    from (
      select 'trait'::text as type, t.id, t.cree_le
        from public.annotation_trait t where t.layer_id = p_layer_id
      union all
      select 'marqueur'::text as type, m.id, m.cree_le
        from public.annotation_marqueur m where m.layer_id = p_layer_id
    ) geste
   order by geste.cree_le desc, geste.id desc
   limit 1;

  if v_id is null then
    return;
  elsif v_type = 'trait' then
    delete from public.annotation_trait where id = v_id and layer_id = p_layer_id;
  else
    delete from public.annotation_marqueur where id = v_id and layer_id = p_layer_id;
  end if;
end;
$function$;

create or replace function public.tc_annotation_toucher_couche()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_layer_id uuid;
begin
  v_layer_id := case when tg_op = 'DELETE' then old.layer_id else new.layer_id end;
  update public.annotation_layer
     set maj_le = pg_catalog.now()
   where id = v_layer_id;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$function$;

drop trigger if exists tc_annotation_trait_valider on public.annotation_trait;
create trigger tc_annotation_trait_valider
  before insert or update on public.annotation_trait
  for each row execute function public.tc_annotation_valider_trait();

drop trigger if exists tc_annotation_marqueur_valider on public.annotation_marqueur;
create trigger tc_annotation_marqueur_valider
  before insert or update on public.annotation_marqueur
  for each row execute function public.tc_annotation_valider_marqueur();

drop trigger if exists tc_annotation_trait_toucher_couche on public.annotation_trait;
create trigger tc_annotation_trait_toucher_couche
  after insert or update or delete on public.annotation_trait
  for each row execute function public.tc_annotation_toucher_couche();

drop trigger if exists tc_annotation_marqueur_toucher_couche on public.annotation_marqueur;
create trigger tc_annotation_marqueur_toucher_couche
  after insert or update or delete on public.annotation_marqueur
  for each row execute function public.tc_annotation_toucher_couche();

revoke all on function public.tc_annotation_valider_trait() from public, anon, authenticated, agent_ro;
revoke all on function public.tc_annotation_valider_marqueur() from public, anon, authenticated, agent_ro;
revoke all on function public.tc_annotation_toucher_couche() from public, anon, authenticated, agent_ro;
revoke all on function public.tc_poser_annotation_marqueur(uuid, uuid, jsonb, text, text)
  from public, anon, authenticated, agent_ro;
grant execute on function public.tc_poser_annotation_marqueur(uuid, uuid, jsonb, text, text)
  to authenticated;
revoke all on function public.tc_annuler_derniere_annotation(uuid)
  from public, anon, authenticated, agent_ro;
grant execute on function public.tc_annuler_derniere_annotation(uuid) to authenticated;

-- Les marqueurs sont remplacés atomiquement par RPC; l'identité reste hors table.
revoke all on public.annotation_marqueur
  from public, anon, authenticated, agent_ro;
grant select, delete on public.annotation_marqueur to authenticated;

-- Supabase Flutter stream() reçoit l'état initial et les changements. Le trigger
-- ci-dessus fait remonter les mutations filles via maj_le de la couche.
do $publication$
begin
  if exists (select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_catalog.pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'annotation_layer'
     ) then
    execute 'alter publication supabase_realtime add table public.annotation_layer';
  end if;
end;
$publication$;

commit;
