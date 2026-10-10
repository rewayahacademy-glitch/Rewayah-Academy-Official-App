-- 0071 — exposer les classes en attente d'enseignant à l'administration.
begin;

create or replace function public.classes_a_confirmer_admin()
returns table (
  classe_id uuid,
  libelle text,
  peut_affecter_enseignant boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'acces reserve a l''administration';
  end if;
  return query
  select g.id, g.libelle, true
  from public.groupes g
  where g.teacher_id is null
    and g.etat = 'en_attente_enseignant'
    and g.ended_at is null
  order by g.created_at, g.id;
end;
$function$;
revoke all on function public.classes_a_confirmer_admin()
  from public, anon, agent_ro;
grant execute on function public.classes_a_confirmer_admin()
  to authenticated, service_role;

commit;
