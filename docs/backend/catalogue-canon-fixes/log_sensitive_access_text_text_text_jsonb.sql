CREATE OR REPLACE FUNCTION public.log_sensitive_access(p_action text, p_table_name text, p_row_id text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  last_hash text;
  row_digest text;
begin
  lock table public.audit_logs in share row exclusive mode;

  select hash into last_hash
  from public.audit_logs
  order by created_at desc, id desc
  limit 1;
  last_hash := coalesce(last_hash, '');

  row_digest := encode(extensions.digest(
    convert_to(coalesce(auth.uid()::text, '') || coalesce(public.app_role()::text, '') || p_action ||
      p_table_name || coalesce(p_row_id, '') || p_payload::text, 'UTF8'),
    'sha256'), 'hex');

  insert into public.audit_logs (actor, actor_role, action, table_name, row_id, payload, prev_hash, hash)
  values (
    auth.uid(), public.app_role()::text, p_action, p_table_name, p_row_id, p_payload, last_hash,
    encode(extensions.digest(convert_to(last_hash || row_digest, 'UTF8'), 'sha256'), 'hex')
  );
end;
$function$

