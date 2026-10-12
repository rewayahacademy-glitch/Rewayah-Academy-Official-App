-- RECH-BACK-4: reuse the existing RECH-D3 Edge Function and make its fresh
-- authorization explicit. Control mission projections exclude expired work.
begin;

create or replace function public.ma_mission_controle()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce((
    select pg_catalog.jsonb_build_object(
      'id', m.id,
      'session_id', m.session_id,
      'groupe_id', m.groupe_id,
      'enseignant_effectif_id', m.enseignant_effectif_id,
      'echeance', m.echeance,
      'statut', m.statut,
      'commencee_le', m.commencee_le
    )
      from private.controle_missions m
      join private.controle_capacites c on c.profile_id = m.controleur_id
      join public.profiles p on p.id = auth.uid()
     where m.controleur_id = auth.uid()
       and m.statut in ('attribuee', 'en_cours')
       and m.echeance > pg_catalog.statement_timestamp()
       and c.revoked_at is null
       and c.active_from <= pg_catalog.statement_timestamp()
       and c.expires_at > pg_catalog.statement_timestamp()
       and (c.scope_all_groups
            or m.groupe_id = any(c.scope_group_ids)
            or m.enseignant_effectif_id = any(c.scope_teacher_ids))
       and p.role = 'controller'
       and p.account_status = 'active'
       and p.deleted_at is null
       and (p.access_until is null or p.access_until > pg_catalog.statement_timestamp())
       and public.rech_session_autorisee()
       and public.app_account_valid()
       and public.app_role() = 'controller'
     order by m.affectee_le desc, m.id
     limit 1
  ), '{}'::jsonb);
$function$;

alter function public.ma_mission_controle() owner to postgres;
revoke all on function public.ma_mission_controle()
  from public, anon, service_role, agent_ro;
grant execute on function public.ma_mission_controle() to authenticated;
comment on function public.ma_mission_controle() is
  'D3 caller-scoped control mission summary; checks fresh authorization, live capability and mission deadline on every read.';

commit;
