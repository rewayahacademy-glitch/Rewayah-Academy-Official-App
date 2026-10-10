-- 0063 — boîte de notifications append-only, isolée par destinataire.
begin;

create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  destinataire uuid not null references public.profiles(id) on delete cascade,
  foyer_id     uuid references public.households(id) on delete set null,
  evenement    text not null check (evenement in (
    'demande_recue',
    'classe_validee',
    'enseignant_affecte',
    'demande_close',
    'remplacement_propose',
    'remplacement_pris'
  )),
  params       jsonb not null default '{}'::jsonb
                 check (pg_catalog.jsonb_typeof(params) = 'object')
                 check (pg_catalog.pg_column_size(params) <= 8192),
  destination  text not null check (destination in (
    '/tuteur/demandes',
    '/enseignant/journee/remplacements'
  )),
  cree_le      timestamptz not null default pg_catalog.now(),
  lu_le        timestamptz
);

create index notifications_destinataire_cree_le_idx
  on public.notifications (destinataire, cree_le desc);

alter table public.notifications enable row level security;

create policy notifications_destinataire_lecture
  on public.notifications
  for select to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and destinataire = auth.uid(),
      false
    )
  );

revoke all on public.notifications from public, anon, authenticated, agent_ro;
grant select on public.notifications to authenticated;

create or replace function public.marquer_notification_lue(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_rows integer;
begin
  if not coalesce(
    p_notification_id is not null
    and public.app_account_valid()
    and exists (
      select 1
        from public.notifications n
       where n.id = p_notification_id
         and n.destinataire = auth.uid()
    ),
    false
  ) then
    raise exception 'notification inaccessible' using errcode = '42501';
  end if;

  update public.notifications
     set lu_le = coalesce(lu_le, pg_catalog.now())
   where id = p_notification_id
     and destinataire = auth.uid();
  get diagnostics v_rows = row_count;

  if v_rows <> 1 then
    raise exception 'notification inaccessible' using errcode = '42501';
  end if;
end;
$function$;

revoke all on function public.marquer_notification_lue(uuid)
  from public, anon, agent_ro;
grant execute on function public.marquer_notification_lue(uuid)
  to authenticated;
commit;
