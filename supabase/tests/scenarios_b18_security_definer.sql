-- Scénarios négatifs B-18 / 0044.
-- À exécuter après toutes les migrations sur PostgreSQL jetable seulement.
begin;
select set_config('request.jwt.claims', '{}', true);

set local role anon;
do $$
begin
  if pg_catalog.has_function_privilege('anon', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.read_kyc_documents()', 'execute') then
    raise exception 'B-18: anon retains EXECUTE on a protected RPC';
  end if;
end $$;
reset role;

set local role authenticated;
do $$
declare
  v_rows integer;
begin
  select count(*) into v_rows from public.comptes_admin();
  if v_rows <> 0 then
    raise exception 'B-18: comptes_admin exposed rows with no app role';
  end if;
  begin
    perform public.creer_groupe(null::uuid, null::text, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long creer_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.creer_groupe(null::uuid, null::text, null::text, null::smallint, null::smallint, null::smallint);
    raise exception 'B-18: short creer_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint);
    raise exception 'B-18: short modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform 1 from public.read_kyc_documents();
    raise exception 'B-18: read_kyc_documents accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'acces KYC refuse' then raise; end if;
  end;
end $$;
reset role;

set local role agent_ro;
do $$
begin
  if pg_catalog.has_function_privilege('agent_ro', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'execute') then
    raise exception 'B-18: agent_ro retains EXECUTE on a protected RPC';
  end if;
end $$;
-- B2 / I-18 : un compte Auth sans profil ne lit ni n'écrit via les RPC
-- administratives SECURITY DEFINER. Ces six fonctions avaient une garde
-- négative; NULL <> 'admin' laissait passer l'appel.
set local role authenticated;
do $b2$
declare
  v_test record;
  v_uid constant uuid := 'b1800000-0000-0000-0000-000000000001';
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('test.uid', v_uid::text, true);
  perform set_config('request.jwt.claims', '{}', true);
  perform set_config('test.jwt', '{}', true);

  if auth.uid() <> v_uid or public.app_account_valid() then
    raise exception 'B2 ECHEC : le fixture doit avoir auth.uid sans profil applicatif';
  end if;

  for v_test in
    select * from (values
      ('eleves_sans_enseignant', 'select * from public.eleves_sans_enseignant()', 'attribution manuelle reservee a l''administration'),
      ('enseignants_pour', 'select * from public.enseignants_pour(null::uuid)', 'attribution manuelle reservee a l''administration'),
      ('indicateurs_admin', 'select * from public.indicateurs_admin()', 'centre de commande reserve a l''administration'),
      ('demandes_en_attente', 'select * from public.demandes_en_attente()', 'file des demandes reservee a l''administration'),
      ('journal_audit_filtres', 'select public.journal_audit_filtres()', 'journal d''audit reserve a l''administration'),
      ('maj_eleve_pedagogie', 'select public.maj_eleve_pedagogie(null::uuid, ''inconnu'', ''inconnu'')', 'seul un administrateur modifie le niveau ou la riwaya')
    ) as tests(nom, commande, refus_attendu)
  loop
    begin
      execute v_test.commande;
      raise exception 'B2 ECHEC : % a accepté un JWT sans profil', v_test.nom;
    exception when raise_exception then
      if sqlerrm <> v_test.refus_attendu then
        raise;
      end if;
    end;
  end loop;

  raise notice 'B2 ok : compte Auth sans profil refusé par les six RPC sensibles';
end
$b2$;
reset role;
reset role;
rollback;
