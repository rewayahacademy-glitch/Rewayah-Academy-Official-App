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

create policy notifications_destinataire_accuse
  on public.notifications
  for update to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and destinataire = auth.uid(),
      false
    )
  )
  with check (
    coalesce(
      public.app_account_valid()
      and destinataire = auth.uid(),
      false
    )
  );

create function public.notifications_accuse_serveur()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  new.lu_le := coalesce(old.lu_le, pg_catalog.now());
  return new;
end;
$function$;

create trigger notifications_accuse_serveur
before update of lu_le on public.notifications
for each row execute function public.notifications_accuse_serveur();

revoke all on public.notifications from public, anon, authenticated, agent_ro;
grant select on public.notifications to authenticated;
grant update (lu_le) on public.notifications to authenticated;
revoke all on function public.notifications_accuse_serveur()
  from public, anon, authenticated, agent_ro;
commit;
