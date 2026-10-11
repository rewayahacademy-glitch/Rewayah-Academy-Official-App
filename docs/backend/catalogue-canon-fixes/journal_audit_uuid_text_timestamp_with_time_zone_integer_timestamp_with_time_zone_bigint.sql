CREATE OR REPLACE FUNCTION public.journal_audit(p_acteur uuid DEFAULT NULL::uuid, p_action text DEFAULT NULL::text, p_depuis timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limite integer DEFAULT 50, p_avant_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_avant_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(entree_id bigint, survenu_le timestamp with time zone, acteur uuid, role_acteur text, nom_acteur text, type_evenement text, table_visee text, ligne_visee text, details jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 200 then
    raise exception 'limite hors bornes';
  end if;

  if (p_avant_date is null) <> (p_avant_id is null) then
    raise exception 'curseur incomplet';
  end if;

  return query
  select
    a.id,
    a.created_at,
    a.actor,
    a.actor_role,
    case
      when v_masque then p.immutable_id
      else coalesce(
        nullif(trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')), ''),
        p.immutable_id
      )
    end,
    a.action,
    a.table_name,
    a.row_id,
    a.payload
  from public.audit_logs a
  left join public.profiles p on p.id = a.actor
  where (p_acteur is null or a.actor = p_acteur)
    and (p_action is null or a.action = p_action)
    and (p_depuis is null or a.created_at >= p_depuis)
    and (
      p_avant_date is null
      or (a.created_at, a.id) < (p_avant_date, p_avant_id)
    )
  order by a.created_at desc, a.id desc
  limit p_limite;
end;
$function$

