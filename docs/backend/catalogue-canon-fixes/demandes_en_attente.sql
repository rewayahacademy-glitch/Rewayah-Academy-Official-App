CREATE OR REPLACE FUNCTION public.demandes_en_attente()
 RETURNS TABLE(id uuid, kind text, subject_profile_id uuid, subject_first_name text, subject_immutable_id text, rule_key text, rule_value jsonb, reason text, requester_role app_role, requested_by uuid, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if NOT coalesce(public.app_role() IN ('admin', 'controller') AND public.app_account_valid(), false) then
    raise exception 'file des demandes reservee a l''administration';
  end if;

  return query
  select m.id, m.kind, m.subject_profile_id,
         case when v_masque then null else p.first_name end,
         p.immutable_id,
         m.rule_key, m.rule_value, m.reason, m.requester_role, m.requested_by,
         m.created_at
  from public.matching_requests m
  join public.profiles p on p.id = m.subject_profile_id
  where m.status = 'pending'
  order by m.created_at asc;
end;
$function$

