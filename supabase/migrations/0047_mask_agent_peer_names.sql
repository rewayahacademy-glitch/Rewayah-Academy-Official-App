-- 0047: apply the existing agent identity mask to peer names as well.
-- A8 in scenarios_agt01 exposed first_name from session_peers_v to agent_ro.
-- Keep the public column contract and expose the immutable identifier for an
-- agent token, matching the policy already used by presence_seance_v.
begin;

create or replace view public.session_peers_v
with (security_barrier = true)
as
select distinct
  sp.session_id,
  p2.id as peer_id,
  case when public.agent_identite_masquee()
       then p2.immutable_id
       else p2.first_name
  end as first_name,
  p2.immutable_id
from public.session_participants sp
join public.session_participants sp2 using (session_id)
join public.profiles p2 on p2.id = sp2.profile_id
where sp.profile_id = auth.uid()
  and sp.deleted_at is null
  and sp2.deleted_at is null
  and p2.deleted_at is null
  and sp2.profile_id <> sp.profile_id
  and ((sp2.role <> all (array[
         'masked_controller'::public.participant_role,
         'admin_masked'::public.participant_role,
         'guardian_observer'::public.participant_role
       ]))
       or public.app_role() = 'admin'::public.app_role);

do $$
declare
  v_definition text;
begin
  v_definition := pg_catalog.pg_get_viewdef('public.session_peers_v'::regclass, true);
  if v_definition not like '%agent_identite_masquee%' then
    raise exception '0047 incomplete: session_peers_v does not mask agent identities';
  end if;
  if not pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'select') then
    raise exception '0047 incomplete: agent_ro lost SELECT on session_peers_v';
  end if;
  if pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select') then
    raise exception '0047 incomplete: anon gained SELECT on session_peers_v';
  end if;
end $$;

commit;
