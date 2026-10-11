CREATE OR REPLACE FUNCTION public.next_immutable_id(role_code app_role, initials text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  seq_code text := role_code::text;
  new_value bigint;
begin
  insert into public.id_sequences (code) values (seq_code) on conflict (code) do nothing;

  update public.id_sequences
  set last_value = last_value + 1
  where code = seq_code
  returning last_value into new_value;

  return upper(role_code::text) || '-' || upper(initials) || '-' || lpad(new_value::text, 6, '0');
end;
$function$

