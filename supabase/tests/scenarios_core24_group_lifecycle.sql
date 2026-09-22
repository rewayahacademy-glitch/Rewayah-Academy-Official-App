-- Scenarios du lifecycle Groupe Core24.

do $$
begin
  if to_regprocedure('public.transitionner_groupe_classes(uuid,text)') is null then
    raise exception 'LIFECYCLE : RPC absente';
  end if;
  if not has_function_privilege(
    'authenticated',
    'public.groupes_admin()',
    'EXECUTE'
  ) then
    raise exception 'LIFECYCLE : Admin ne peut pas lire groupes_admin';
  end if;
end $$;

do $$
begin
  if has_function_privilege(
    'anon', 'public.transitionner_groupe_classes(uuid,text)', 'EXECUTE'
  ) then
    raise exception 'LIFECYCLE SECURITE : anon peut changer un etat';
  end if;
end $$;
