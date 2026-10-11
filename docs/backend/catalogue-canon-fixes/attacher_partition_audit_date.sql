CREATE OR REPLACE FUNCTION public.attacher_partition_audit(p_debut date)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_nom text := 'audit_logs_' || to_char(p_debut, 'YYYY_MM');
  v_fin date := (p_debut + interval '1 month')::date;
begin
  if to_regclass('public.' || v_nom) is not null then
    return v_nom;
  end if;

  execute format(
    'create table public.%I partition of public.audit_logs for values from (%L) to (%L)',
    v_nom, p_debut, v_fin);

  -- Les deux lignes qui manquaient a la partition par defaut.
  execute format('alter table public.%I enable row level security', v_nom);
  execute format(
    'revoke insert, update, delete on public.%I from public, anon, authenticated, service_role',
    v_nom);

  return v_nom;
end;
$function$

