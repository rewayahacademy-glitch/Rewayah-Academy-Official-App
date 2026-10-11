CREATE OR REPLACE FUNCTION public.demander(p_kind text, p_subject_profile_id uuid, p_motif text, p_rule_key text DEFAULT NULL::text, p_rule_value integer DEFAULT NULL::integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_role public.app_role := public.app_role();
  v_id uuid;
begin
  if v_role is null or not public.app_account_valid() then
    raise exception 'compte non valide';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une demande sans motif ne se tranche pas';
  end if;
  if not public.partie_concernee(p_subject_profile_id) then
    raise exception 'vous n''etes pas partie a ce dossier';
  end if;

  if p_kind = 'capacity' then
    -- Le plafond est celui d'un enseignant, et il le demande pour lui-meme.
    if not (v_role = 'admin' or (v_role = 'teacher' and p_subject_profile_id = auth.uid())) then
      raise exception 'un plafond se demande pour soi';
    end if;
    if p_rule_value is null or p_rule_value <= 0 then
      raise exception 'un plafond demande est un entier positif';
    end if;
    p_rule_key := 'max_students_per_teacher';

  elsif p_kind = 'rule_change' then
    if p_rule_key not in ('session_duration_minutes',
                          'session_paid_minimum_minutes',
                          'break_minutes_between_sessions') then
      raise exception 'regle non modifiable par demande : %', coalesce(p_rule_key, 'aucune');
    end if;
    if p_rule_value is null or p_rule_value <= 0 then
      raise exception 'une regle demandee est un entier positif';
    end if;

  elsif p_kind = 'reassignment' then
    p_rule_key := null;
    p_rule_value := null;
    if not exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p_subject_profile_id and a.ended_at is null
    ) then
      raise exception 'cet eleve n''a pas d''enseignant a changer';
    end if;

  else
    raise exception 'sorte de demande inconnue : %', p_kind;
  end if;

  begin
    insert into public.matching_requests
      (kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
    values (p_kind, p_subject_profile_id, p_rule_key,
            case when p_rule_value is null then null else to_jsonb(p_rule_value) end,
            btrim(p_motif), auth.uid(), v_role)
    returning id into v_id;
  exception
    when unique_violation then
      raise exception 'une demande de cette sorte est deja en attente pour ce dossier';
  end;

  perform public.log_sensitive_access('demande_creee', 'matching_requests',
    v_id::text, jsonb_build_object('kind', p_kind, 'subject', p_subject_profile_id));

  return v_id;
end;
$function$

