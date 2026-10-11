CREATE OR REPLACE FUNCTION public.deposer_student_concern(p_categorie text, p_groupe_id uuid, p_session_id uuid, p_academy_id text, p_internal_details text, p_family_summary text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$

