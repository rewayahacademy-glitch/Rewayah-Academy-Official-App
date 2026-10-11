CREATE OR REPLACE FUNCTION public.transmettre_student_concern(p_concern_id uuid, p_cible text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$

