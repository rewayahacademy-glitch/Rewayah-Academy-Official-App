-- Sans fixture persistante : verifie les signatures exposees et les ACL.
-- A executer apres les migrations, avant les anciens tests qui reaccordent
-- globalement EXECUTE a service_role.
begin;
do $$
declare
  v_nom text;
  v_oid oid;
  v_nombre integer;
begin
  foreach v_nom in array array['creer_groupe', 'modifier_groupe'] loop
    select count(*), min(p.oid::bigint)::oid into v_nombre, v_oid
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = v_nom;
    if v_nombre <> 1 then
      raise exception '% : % signatures, une seule attendue', v_nom, v_nombre;
    end if;
    if has_function_privilege('anon', v_oid, 'execute')
       or has_function_privilege('agent_ro', v_oid, 'execute') then
      raise exception '% : une mutation est exposee a anon ou agent_ro', v_nom;
    end if;
    if not has_function_privilege('authenticated', v_oid, 'execute') then
      raise exception '% : inaccessible au client authentifie', v_nom;
    end if;
  end loop;
end;
$$;

-- Les appels par noms employes par Flutter doivent se resoudre jusqu'au
-- controle d'autorisation. Une erreur d'ambiguite n'est pas acceptee.
set local role authenticated;
select set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
do $$
begin
  begin
    perform public.creer_groupe(
      p_teacher_profile_id => null::uuid, p_type_public => 'enfant',
      p_libelle => 'Test', p_weekday => 1::smallint,
      p_hour_local => 16::smallint, p_seuil_max => null::smallint);
    raise exception 'creation non autorisee acceptee';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(
      p_groupe_id => null::uuid, p_libelle => 'Test',
      p_seuil_max => 5::smallint, p_weekday => 1::smallint,
      p_hour_local => 16::smallint);
    raise exception 'modification non autorisee acceptee';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
end;
$$;
rollback;
