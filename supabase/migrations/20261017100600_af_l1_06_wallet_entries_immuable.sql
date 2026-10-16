-- Audit final 16/10/2026, lot L1-06 (P1-4). Le grand livre est un journal :
-- on n'y corrige qu'en écrivant l'inverse. Même modèle que audit_logs (0001).
begin;

-- Security invoker : current_user doit rester le compte appelant (et non le
-- propriétaire), sinon la condition sur current_user ne voit jamais un admin.
create or replace function public.guard_wallet_entries_immutable()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  -- Une réécriture identique ne change rien au journal : admise (x2_17 la fait).
  if tg_op = 'UPDATE' and to_jsonb(new) = to_jsonb(old) then
    return new;
  end if;
  -- Seule exception : l'horodatage de confirmation prestataire, posé une seule
  -- fois par le serveur (x2_17). Tout le reste, postgres compris, est refusé.
  if tg_op = 'UPDATE'
     and old.confirme_par_prestataire_le is null
     and new.confirme_par_prestataire_le is not null
     and (to_jsonb(new) - 'confirme_par_prestataire_le') = (to_jsonb(old) - 'confirme_par_prestataire_le')
     and current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  raise exception 'wallet_entries est immuable : écrire une écriture inverse (adjustment)'
    using errcode = 'insufficient_privilege';
end;
$$;
revoke all on function public.guard_wallet_entries_immutable() from public, anon, authenticated, agent_ro;
-- Fonction de trigger : elle n'a pas besoin de EXECUTE pour se déclencher, et
-- la liste blanche des fonctions volatiles (L1-09) refuse qu'authenticated
-- en ait un.
revoke execute on function public.guard_wallet_entries_immutable() from public, anon, authenticated;

drop trigger if exists wallet_entries_no_update on public.wallet_entries;
create trigger wallet_entries_no_update
  before update on public.wallet_entries
  for each row execute function public.guard_wallet_entries_immutable();

drop trigger if exists wallet_entries_no_delete on public.wallet_entries;
create trigger wallet_entries_no_delete
  before delete on public.wallet_entries
  for each row execute function public.guard_wallet_entries_immutable();

drop policy if exists wallet_entries_admin_accountant_all on public.wallet_entries;
create policy wallet_entries_admin_accountant_read on public.wallet_entries
  for select to authenticated
  using (coalesce(public.app_role() in ('admin', 'accountant') and public.app_account_valid(), false));
create policy wallet_entries_admin_accountant_insert on public.wallet_entries
  for insert to authenticated
  with check (coalesce(public.app_role() in ('admin', 'accountant') and public.app_account_valid(), false));

revoke update, delete on public.wallet_entries from authenticated, anon, agent_ro;

do $postflight$
begin
  if exists (select 1 from pg_policies where tablename = 'wallet_entries' and policyname = 'wallet_entries_admin_accountant_all') then
    raise exception 'L1-06 postflight: policy FOR ALL encore présente';
  end if;
  if has_table_privilege('authenticated', 'public.wallet_entries', 'update')
     or has_table_privilege('authenticated', 'public.wallet_entries', 'delete') then
    raise exception 'L1-06 postflight: authenticated garde update ou delete';
  end if;
end $postflight$;

commit;
