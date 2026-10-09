-- 0046: permit the read-only household predicate to agent_ro.
-- 0030 defines est_du_foyer as STABLE SECURITY DEFINER; it derives the
-- household from the signed request claims and only returns a boolean.
-- RLS-backed family views evaluate this predicate for the scoped agent role.
revoke execute on function public.est_du_foyer(uuid) from public, anon;
grant execute on function public.est_du_foyer(uuid) to authenticated, agent_ro;

do $$
begin
  if not pg_catalog.has_function_privilege('agent_ro', 'public.est_du_foyer(uuid)', 'execute') then
    raise exception '0046 incomplete: agent_ro lacks EXECUTE on est_du_foyer';
  end if;
  if pg_catalog.has_function_privilege('anon', 'public.est_du_foyer(uuid)', 'execute') then
    raise exception '0046 incomplete: anon retains EXECUTE on est_du_foyer';
  end if;
end $$;
