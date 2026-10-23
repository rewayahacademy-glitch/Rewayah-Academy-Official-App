-- Rétablir les ACL des migrations pour authenticated et service_role
-- (photographie prise par _acl_photo.sql).
do $acl_restauration$
declare
  v record;
  v_priv record;
begin
  for v in select a.genre, a.oid, a.acl from pg_temp.acl_avant_scenario a loop
    if v.genre <> 'fn' then
      execute format('revoke all on %s %s from authenticated, service_role', v.genre, v.oid::regclass);
    else
      execute format('revoke all on function %s from authenticated, service_role', v.oid::regprocedure);
    end if;
    for v_priv in
      select x.privilege_type, r.rolname
        from pg_catalog.aclexplode(v.acl) x
        join pg_catalog.pg_roles r on r.oid = x.grantee
       where r.rolname in ('authenticated', 'service_role')
    loop
      if v.genre <> 'fn' then
        execute format('grant %s on %s %s to %I', v_priv.privilege_type, v.genre, v.oid::regclass, v_priv.rolname);
      else
        execute format('grant %s on function %s to %I', v_priv.privilege_type, v.oid::regprocedure, v_priv.rolname);
      end if;
    end loop;
  end loop;
end
$acl_restauration$;

