-- 0058 — comptes actifs, propriété et flux des outils pédagogiques.
-- Les tables viennent de 0032; cette migration ne change pas leur modèle métier.
begin;

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
      and exists (
        select 1 from public.groupes g
         where g.id = learning_assignment.group_id
           and g.teacher_id = auth.uid()
           and g.ended_at is null
      ),
      false
    )
  )
  with check (
    coalesce(
      public.app_account_valid()
      and public.app_role() = 'teacher'
      and created_by = auth.uid()
      and exists (
        select 1 from public.groupes g
         where g.id = learning_assignment.group_id
           and g.teacher_id = auth.uid()
           and g.ended_at is null
      )
      and (
        student_id is null
        or exists (
          select 1 from public.groupe_membres gm
           where gm.groupe_id = learning_assignment.group_id
             and gm.student_id = learning_assignment.student_id
             and gm.left_at is null
        )
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
      and (student_id is null or student_id = auth.uid()
           or public.est_du_foyer(student_id))
      and exists (
        select 1 from public.groupe_membres gm
         where gm.groupe_id = learning_assignment.group_id
           and gm.left_at is null
           and (gm.student_id = auth.uid() or public.est_du_foyer(gm.student_id))
      ),
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
   where l.id = new.layer_id;
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
