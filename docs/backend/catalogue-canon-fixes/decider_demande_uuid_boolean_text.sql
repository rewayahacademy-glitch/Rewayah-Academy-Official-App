CREATE OR REPLACE FUNCTION public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_d public.matching_requests;
  v_assignment uuid;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'seul un administrateur tranche une demande';
  end if;
  if not p_accepte and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  select * into v_d from public.matching_requests
  where id = p_request_id and status = 'pending';
  if v_d.id is null then
    raise exception 'demande introuvable ou deja tranchee';
  end if;

  if p_accepte then
    if v_d.kind = 'reassignment' then
      -- L'affectation se clot, et les seances a venir tombent avec elle : une
      -- famille ne doit pas voir un cours planifie avec un enseignant qui ne la
      -- suit plus.
      update public.teacher_student_assignments
      set ended_at = now(), ended_by = auth.uid(),
          end_reason = coalesce(btrim(p_motif), btrim(v_d.reason))
      where student_id = v_d.subject_profile_id and ended_at is null
      returning id into v_assignment;

      update public.sessions s
      set status = 'canceled', updated_at = now()
      where s.deleted_at is null
        and s.status = 'planned'
        and s.started_at > now()
        and exists (
          select 1 from public.session_participants sp
          where sp.session_id = s.id and sp.profile_id = v_d.subject_profile_id
            and sp.deleted_at is null
        );
    else
      perform public.poser_regle(
        v_d.subject_profile_id, v_d.rule_key, (v_d.rule_value #>> '{}')::int,
        'demande accordee : ' || v_d.reason);
    end if;
  end if;

  update public.matching_requests
  set status = case when p_accepte then 'approved' else 'rejected' end,
      decided_by = auth.uid(), decided_at = now(),
      decision_reason = btrim(p_motif)
  where id = p_request_id;

  perform public.log_sensitive_access('demande_tranchee', 'matching_requests',
    p_request_id::text,
    jsonb_build_object('accepte', p_accepte, 'kind', v_d.kind));
end;
$function$

