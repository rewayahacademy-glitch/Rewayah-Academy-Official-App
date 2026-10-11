CREATE OR REPLACE FUNCTION public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_tz text;
  v_instant timestamptz;
  v_assignment uuid;
begin
  if not coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false) then
    raise exception 'seul un enseignant au compte valide prend un eleve';
  end if;

  -- Le creneau demande doit etre un creneau POSE par le foyer : un enseignant ne
  -- choisit pas l'heure a la place de la famille.
  select w.timezone_iana into v_tz
  from public.weekly_availability w
  join public.profiles p on p.id = w.profile_id
  where w.profile_id = p_student_profile_id
    and w.weekday = p_weekday and w.hour_local = p_hour
    and p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_tz is null then
    raise exception 'ce creneau n''est pas propose par ce foyer';
  end if;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  -- Comparaison par instant et non par heure locale : la famille pose en heure
  -- de Paris, l'enseignant travaille en heure de Conakry.
  if not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = auth.uid()
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  ) then
    raise exception 'ce creneau ne figure pas dans vos disponibilites';
  end if;

  if exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = p_student_profile_id and a.ended_at is null
  ) then
    raise exception 'cet eleve a deja un enseignant';
  end if;

  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values (auth.uid(), p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    -- I4 : deux enseignants au meme instant. L'index unique partiel tranche, et
    -- le perdant recoit une phrase, pas un code d'erreur.
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un autre enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_creee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour));

  return v_assignment;
end;
$function$

