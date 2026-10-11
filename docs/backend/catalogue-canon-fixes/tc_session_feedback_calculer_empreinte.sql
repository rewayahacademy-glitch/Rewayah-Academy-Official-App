CREATE OR REPLACE FUNCTION public.tc_session_feedback_calculer_empreinte()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_sel text;
begin
  select (value #>> '{}') into v_sel
    from public.app_config where key = 'feedback_empreinte_sel';
  new.auteur_empreinte := extensions.digest(
    new.session_id::text || auth.uid()::text || coalesce(v_sel, ''), 'sha256'
  );
  return new;
end;
$function$

