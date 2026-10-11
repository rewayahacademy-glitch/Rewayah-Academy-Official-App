CREATE OR REPLACE FUNCTION public.journal_audit_filtres()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resultat jsonb;
  v_masque boolean := public.agent_identite_masquee();
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  select jsonb_build_object(
    'total', (select count(*) from public.audit_logs),
    'premiere', (select min(x.created_at) from public.audit_logs x),
    'actions', coalesce((
      select jsonb_agg(
        jsonb_build_object('action', t.action, 'n', t.n)
        order by t.n desc, t.action asc
      )
      from (
        select a.action, count(*) as n
        from public.audit_logs a
        group by a.action
      ) t
    ), '[]'::jsonb),
    'acteurs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', u.actor,
          'nom', u.nom,
          'identifiant', u.identifiant,
          'role', u.role,
          'n', u.n
        )
        order by u.n desc, u.nom asc
      )
      from (
        select
          a.actor,
          count(*) as n,
          (array_agg(a.actor_role order by a.created_at desc, a.id desc))[1] as role,
          max(p.immutable_id) as identifiant,
          -- Deux corrections d'un coup : le masquage, qui n'etait applique
          -- nulle part sur cet ecran malgre la banniere « prenoms masques » ;
          -- et le repli sur l'identifiant immuable, faute de quoi deux
          -- personnes portant le meme nom produisaient deux filtres
          -- visuellement identiques.
          case
            when v_masque then coalesce(max(p.immutable_id), a.actor::text)
            else coalesce(
              nullif(trim(coalesce(max(p.first_name), '') || ' ' || coalesce(max(p.last_name), '')), ''),
              max(p.immutable_id),
              a.actor::text
            )
          end as nom
        from public.audit_logs a
        left join public.profiles p on p.id = a.actor
        where a.actor is not null
        group by a.actor
      ) u
    ), '[]'::jsonb)
  ) into v_resultat;

  return v_resultat;
end;
$function$

