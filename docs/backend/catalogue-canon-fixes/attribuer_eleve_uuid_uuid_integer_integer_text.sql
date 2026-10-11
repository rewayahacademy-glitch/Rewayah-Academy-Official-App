CREATE OR REPLACE FUNCTION public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_tz         text;
  v_instant    timestamptz;
  v_hors       boolean;
  v_motif      text := nullif(btrim(coalesce(p_motif, '')), '');
  v_assignment uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  -- Le creneau demande doit etre un creneau POSE par le foyer. Meme phrase et
  -- meme refus que `prendre_eleve()` : ce n'est pas une politesse, c'est la
  -- seule garantie que l'enfant soit disponible a cette heure-la.
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

  v_hors := not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = p_teacher_profile_id
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  );

  -- ADR-021 : passer outre est permis, le faire en silence ne l'est pas. Le
  -- motif est exige **en base** et non seulement a l'ecran, pour la meme raison
  -- qu'un refus de dossier l'exige : ce qui ne se verifie qu'au clavier finit
  -- par ne plus se verifier du tout.
  if v_hors and v_motif is null then
    raise exception 'attribuer hors des disponibilites de cet enseignant exige un motif';
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
    values (p_teacher_profile_id, p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    -- Un enseignant peut prendre ce meme eleve dans `ENS-06` a l'instant ou
    -- l'administration l'attribue. L'index unique partiel tranche, et le perdant
    -- recoit une phrase, pas un code d'erreur.
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_attribuee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'teacher_id', p_teacher_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour,
                       'hors_disponibilite', v_hors,
                       'motif', v_motif));

  return v_assignment;
end;
$function$

