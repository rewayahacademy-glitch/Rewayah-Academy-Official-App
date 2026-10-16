-- L1-07 (audit final 16/10/2026, P1-5) : `profiles.gender` devient une colonne
-- privilegiee. Sans cette garde, la policy `profiles_self_update` laisse un
-- administrateur ou un enseignant changer son propre genre, donc contourner le
-- cloisonnement de `read_kyc_documents` (0088) qui se fonde sur ce genre.
--
-- Copie de la fonction de 0084, avec `gender` ajoute aux colonnes gardees.
-- `create or replace` conserve le trigger attache, le proprietaire et les droits.
begin;

create or replace function public.guard_profile_privileged_columns()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin')
     and not coalesce(
       public.app_role() = 'admin' and public.app_account_valid(),
       false
     )
     and (
       old.role is distinct from new.role
       or old.household_id is distinct from new.household_id
       or old.account_status is distinct from new.account_status
       or old.access_until is distinct from new.access_until
       or old.gender is distinct from new.gender
     )
  then
    raise exception 'seul un admin modifie rôle, foyer, statut, accès ou genre'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$function$;

-- Postflight : la garde doit referencer le genre dans sa definition effective.
do $postflight$
begin
  if pg_get_functiondef('public.guard_profile_privileged_columns()'::regprocedure)
       not like '%new.gender%' then
    raise exception 'L1-07 postflight';
  end if;
end
$postflight$;

commit;
