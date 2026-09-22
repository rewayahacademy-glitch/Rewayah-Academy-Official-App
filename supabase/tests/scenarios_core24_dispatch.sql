-- Scenarios du dispatch Core24. A executer sur un replay complet, apres les
-- migrations Classes et le stub_auth.

do $$
begin
  if to_regprocedure('public.dispatcher_offre_horaire(uuid)') is null then
    raise exception 'DISPATCH : RPC absente';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'groupes'
      and column_name = 'niveau_id'
  ) then
    raise exception 'DISPATCH : cle niveau absente sur groupes';
  end if;
end $$;

do $$
begin
  if has_function_privilege(
    'anon', 'public.dispatcher_offre_horaire(uuid)', 'EXECUTE'
  ) then
    raise exception 'DISPATCH SECURITE : anon peut appeler le moteur';
  end if;
  if has_function_privilege(
    'agent_ro', 'public.dispatcher_offre_horaire(uuid)', 'EXECUTE'
  ) then
    raise exception 'DISPATCH SECURITE : agent_ro peut ecrire';
  end if;
end $$;

-- Le replay de donnees mettra en place les cas 7/8/12/13. Ces assertions de
-- forme restent independantes des UUID de fixture : elles documentent la
-- capacite et le minimum que la RPC doit respecter sous concurrence.
do $$
begin
  if public.app_config_int('groupe.capacite_enfant', 0) <> 5 then
    raise exception 'DISPATCH REGLES : capacite enfant != 5';
  end if;
  if public.app_config_int('groupe.capacite_adulte', 0) <> 6 then
    raise exception 'DISPATCH REGLES : capacite adulte != 6';
  end if;
  if public.app_config_int('groupe.minimum_lancement', 0) <> 3 then
    raise exception 'DISPATCH REGLES : minimum != 3';
  end if;
end $$;
