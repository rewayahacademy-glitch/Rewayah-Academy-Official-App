-- X2-08: the three SELECT policies must gate access on app_account_valid().
do $x2_08_select_policies$
declare
  v_expected record;
  v_policy record;
  v_qual text;
begin
  for v_expected in
    select *
    from (values
      ('langues_cours', 'langues_cours_lecture'),
      ('cohortes_age', 'cohortes_age_lecture'),
      ('offres_horaires', 'offres_horaires_vitrine')
    ) as expected(table_name, policy_name)
  loop
    select p.* into v_policy
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = v_expected.table_name
      and p.policyname = v_expected.policy_name;
    if not found then
      raise exception 'X2-08 SELECT policy missing valid-account gate: %.%',
        v_expected.table_name, v_expected.policy_name;
    end if;

    if v_policy.cmd <> 'SELECT'
      or v_policy.roles is distinct from array['authenticated']::name[] then
      raise exception 'X2-08 unexpected command or role on policy: %.%',
        v_expected.table_name, v_expected.policy_name;
    end if;

    v_qual := lower(regexp_replace(coalesce(v_policy.qual, ''), '[[:space:]()]', '', 'g'));
    if v_expected.table_name in ('langues_cours', 'cohortes_age') then
      if v_qual <> 'coalescepublic.app_account_valid,false' then
        raise exception 'X2-08 catalog SELECT is not gated only by app_account_valid(): %.%',
          v_expected.table_name, v_expected.policy_name;
      end if;
    elsif position('app_account_valid' in v_qual) = 0
      or position('etat' in v_qual) = 0
      or position('publiee' in v_qual) = 0
      or position('app_role' in v_qual) = 0
      or position('admin' in v_qual) = 0
      or position('controller' in v_qual) = 0
      or regexp_count(lower(coalesce(v_policy.qual, '')), '\mor\m') <> 1
      or regexp_count(lower(coalesce(v_policy.qual, '')), '\mand\m') <> 1 then
      raise exception 'X2-08 offer SELECT lost its account gate or published/admin predicate';
    end if;
  end loop;
end;
$x2_08_select_policies$;
