-- 0059 — dépôt et transmission des signalements par RPC bornées.
-- Le modèle de table et ses catégories viennent de 0032_tc_catalogue.sql §15.
begin;

-- Les clients ne contournent pas les gardes métier des RPC.
revoke all on public.student_concern
  from public, anon, authenticated, agent_ro;
grant select on public.student_concern to authenticated;


-- Les policies de lecture suivent aussi l'etat du compte; sinon un role JWT
-- ancien permettrait encore de lire des notes internes apres suspension.
drop policy if exists student_concern_select_enseignant on public.student_concern;
create policy student_concern_select_enseignant
  on public.student_concern
  for select to authenticated
  using (
    coalesce(public.app_role() = 'teacher' and public.app_account_valid()
      and teacher_id = auth.uid(), false)
  );

drop policy if exists student_concern_select_admin on public.student_concern;
create policy student_concern_select_admin
  on public.student_concern
  for select to authenticated
  using (
    coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  );

create or replace function public.deposer_student_concern(
  p_categorie text,
  p_groupe_id uuid,
  p_session_id uuid,
  p_academy_id text,
  p_internal_details text,
  p_family_summary text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_student_id uuid;
  v_id uuid;
  v_result jsonb;
  v_internal text := pg_catalog.btrim(coalesce(p_internal_details, ''));
  v_family text := nullif(pg_catalog.btrim(coalesce(p_family_summary, '')), '');
begin
  if not coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false) then
    raise exception 'depot de signalement reserve a un enseignant actif';
  end if;
  if p_categorie is null or p_categorie not in
    ('pedagogique', 'presence', 'technique', 'changement', 'autre') then
    raise exception 'categorie de signalement invalide';
  end if;
  if p_groupe_id is null or coalesce(pg_catalog.btrim(p_academy_id), '') = ''
     or v_internal = '' then
    raise exception 'groupe, eleve et note interne sont requis';
  end if;

  select p.id into v_student_id
    from public.profiles p
   where p.immutable_id = pg_catalog.btrim(p_academy_id)
     and p.deleted_at is null;

  if v_student_id is null or not exists (
    select 1
      from public.groupes g
      join public.groupe_membres gm on gm.groupe_id = g.id
     where g.id = p_groupe_id
       and g.teacher_id = auth.uid()
       and g.ended_at is null
       and gm.student_id = v_student_id
       and gm.left_at is null
  ) then
    raise exception 'eleve ou groupe introuvable dans votre classe';
  end if;

  if p_session_id is not null and (
    not public.session_belongs_to_teacher(p_session_id, auth.uid())
    or not exists (
      select 1
        from public.session_participants sp
       where sp.session_id = p_session_id
         and sp.profile_id = v_student_id
         and sp.deleted_at is null
    )
  ) then
    raise exception 'seance ou eleve non autorise';
  end if;

  insert into public.student_concern
    (categorie, groupe_id, session_id, student_id, teacher_id,
     internal_details, family_summary)
  values
    (p_categorie::public.concern_category, p_groupe_id, p_session_id,
     v_student_id, auth.uid(), v_internal, v_family)
  returning id into v_id;

  perform public.log_sensitive_access(
    'student_concern_depose', 'student_concern', v_id::text,
    pg_catalog.jsonb_build_object(
      'categorie', p_categorie, 'groupe_id', p_groupe_id,
      'session_id', p_session_id, 'student_id', v_student_id,
      'family_summary_present', v_family is not null
    )
  );

  select pg_catalog.jsonb_build_object(
    'id', c.id, 'categorie', c.categorie::text, 'groupe_id', c.groupe_id,
    'session_id', c.session_id, 'academy_id', p.immutable_id,
    'enseignant_id', c.teacher_id, 'internal_details', c.internal_details,
    'family_summary', c.family_summary, 'statut', c.statut::text,
    'cree_le', c.cree_le, 'transmis_le', c.transmis_le,
    'transmis_a', c.transmis_a::text
  ) into v_result
    from public.student_concern c
    join public.profiles p on p.id = c.student_id
   where c.id = v_id;

  return v_result;
end;
$function$;

create or replace function public.mes_student_concerns(p_groupe_id uuid default null)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false) then
    raise exception 'lecture de signalements reservee a un enseignant actif';
  end if;

  return query
  select pg_catalog.jsonb_build_object(
    'id', c.id, 'categorie', c.categorie::text, 'groupe_id', c.groupe_id,
    'session_id', c.session_id, 'academy_id', p.immutable_id,
    'enseignant_id', c.teacher_id, 'internal_details', c.internal_details,
    'family_summary', c.family_summary, 'statut', c.statut::text,
    'cree_le', c.cree_le, 'transmis_le', c.transmis_le,
    'transmis_a', c.transmis_a::text
  )
    from public.student_concern c
    join public.profiles p on p.id = c.student_id
   where c.teacher_id = auth.uid()
     and (p_groupe_id is null or c.groupe_id = p_groupe_id)
   order by c.cree_le desc, c.id desc;
end;
$function$;

create or replace function public.transmettre_student_concern(
  p_concern_id uuid,
  p_cible text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_student_id uuid;
  v_family text;
  v_status public.concern_status;
  v_student_type public.student_type;
  v_expected_target text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'transmission de signalement reservee a un admin actif';
  end if;
  if p_cible is null or p_cible not in ('tuteur_du_mineur', 'eleve_adulte') then
    raise exception 'cible de transmission invalide';
  end if;

  select c.student_id, c.family_summary, c.statut
    into v_student_id, v_family, v_status
    from public.student_concern c
   where c.id = p_concern_id
   for update;

  if v_student_id is null then
    raise exception 'signalement introuvable';
  end if;
  if coalesce(pg_catalog.btrim(v_family), '') = '' then
    raise exception 'aucun message famille a transmettre';
  end if;
  if v_status = 'transmis' then
    raise exception 'signalement deja transmis';
  end if;

  select sp.student_type into v_student_type
    from public.student_profiles sp
    join public.profiles p on p.id = sp.profile_id
   where sp.profile_id = v_student_id
     and sp.deleted_at is null
     and p.deleted_at is null;
  if v_student_type is null then
    raise exception 'profil eleve indisponible';
  end if;

  v_expected_target := case v_student_type::text
    when 'minor' then 'tuteur_du_mineur'
    when 'autonomous' then 'eleve_adulte'
    else null
  end;
  if v_expected_target is null or p_cible <> v_expected_target then
    raise exception 'cible incompatible avec le profil de l''eleve';
  end if;

  update public.student_concern
     set statut = 'transmis',
         transmis_le = pg_catalog.now(),
         transmis_a = p_cible::public.concern_target
   where id = p_concern_id;

  perform public.log_sensitive_access(
    'student_concern_transmis', 'student_concern', p_concern_id::text,
    pg_catalog.jsonb_build_object('student_id', v_student_id, 'cible', p_cible)
  );
end;
$function$;

revoke all on function public.deposer_student_concern(text, uuid, uuid, text, text, text)
  from public, anon, agent_ro;
grant execute on function public.deposer_student_concern(text, uuid, uuid, text, text, text)
  to authenticated;
revoke all on function public.mes_student_concerns(uuid) from public, anon, agent_ro;
grant execute on function public.mes_student_concerns(uuid) to authenticated;
revoke all on function public.transmettre_student_concern(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.transmettre_student_concern(uuid, text)
  to authenticated;

commit;
