-- RECH-BACK-5 partial: exact finance-reference search through existing RLS.
-- No amount, payment details, capabilities, or FI/CPT grants are added.
begin;

create index if not exists wallet_entries_reference_lookup_idx
  on public.wallet_entries (reference_id, reference_type, created_at desc)
  where reference_id is not null;

create or replace function public.rech_d4_rechercher_reference_finance(
  p_reference_id uuid
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $function$
declare
  v_items jsonb;
begin
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  if p_reference_id is null then
    raise exception 'RechercheReferenceInvalide' using errcode = '22023';
  end if;

  select coalesce(pg_catalog.jsonb_agg(
    pg_catalog.jsonb_build_object(
      'referenceType', x.reference_type,
      'referenceId', x.reference_id,
      'updatedAt', x.updated_at
    ) order by x.reference_type
  ), '[]'::jsonb)
    into v_items
    from (
      select e.reference_type, e.reference_id, max(e.created_at) as updated_at
        from public.wallet_entries e
       where e.reference_id = p_reference_id
       group by e.reference_type, e.reference_id
       limit 4
    ) x;

  return pg_catalog.jsonb_build_object('items', v_items, 'has_more', false);
end;
$function$;

revoke all on function public.rech_d4_rechercher_reference_finance(uuid)
  from public, anon, service_role;
grant execute on function public.rech_d4_rechercher_reference_finance(uuid)
  to authenticated;
comment on function public.rech_d4_rechercher_reference_finance(uuid) is
  'D4 exact-reference projection through existing wallet RLS; omits amounts and payment details.';

commit;
