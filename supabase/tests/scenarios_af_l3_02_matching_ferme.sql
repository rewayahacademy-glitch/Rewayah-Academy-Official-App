-- L3-02 (A-06) : prendre_eleve et attribuer_eleve sont fermes aux comptes
-- connectes. Refus attendu : SQLSTATE 42501 exactement (une autre erreur, de
-- garde metier ou de cle etrangere, ne prouve pas la fermeture). Un cours
-- particulier reste possible comme classe de capacite 1.
begin;
insert into auth.users (id, email, email_confirmed_at) values
  ('13020000-0000-4000-8000-0000000000a1', 'l302-admin@test.invalid', now()),
  ('13020000-0000-4000-8000-0000000000b1', 'l302-teacher@test.invalid', now());
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) values
  ('13020000-0000-4000-8000-0000000000a1', 'L302ADMIN0000001', 'admin', 'L302', 'Admin', 'active', null),
  ('13020000-0000-4000-8000-0000000000b1', 'L302TEACHER00001', 'teacher', 'L302', 'Teacher', 'provisional_active', 'male');
-- CAND-Q15 (lot creer_groupe, 21/10) : creer_groupe passe par le predicat
-- d'affectation ; l'enseignant du cours particulier a un genre connu, un
-- profil enseignant et sa piece d'identite validee.
insert into public.teacher_profiles (profile_id, kyc_status) values
  ('13020000-0000-4000-8000-0000000000b1', 'approved');

-- Enseignant : prendre_eleve refuse en 42501.
select set_config('request.jwt.claim.sub', '13020000-0000-4000-8000-0000000000b1', true);
select set_config('test.uid', '13020000-0000-4000-8000-0000000000b1', true);
select set_config('request.jwt.claims', '{"sub":"13020000-0000-4000-8000-0000000000b1","app_metadata":{"role":"teacher"}}', true);
select set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
set local role authenticated;
do $$
begin
  begin
    perform public.prendre_eleve('13020000-0000-4000-8000-0000000000c1', 1, 17);
    raise exception 'L3-02: prendre_eleve accepte sous authenticated enseignant';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L3-02: prendre_eleve SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
  end;
end $$;
reset role;

-- Administrateur aal2 : attribuer_eleve refuse en 42501.
select set_config('request.jwt.claim.sub', '13020000-0000-4000-8000-0000000000a1', true);
select set_config('test.uid', '13020000-0000-4000-8000-0000000000a1', true);
select set_config('request.jwt.claims', '{"sub":"13020000-0000-4000-8000-0000000000a1","aal":"aal2","app_metadata":{"role":"admin"}}', true);
select set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  begin
    perform public.attribuer_eleve('13020000-0000-4000-8000-0000000000c1',
      '13020000-0000-4000-8000-0000000000b1', 1, 17, null);
    raise exception 'L3-02: attribuer_eleve accepte sous authenticated administrateur';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L3-02: attribuer_eleve SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
  end;
end $$;

-- Le cours particulier : une classe de capacite 1 se cree.
do $$
declare v_id uuid;
begin
  v_id := public.creer_groupe('13020000-0000-4000-8000-0000000000b1', 'adulte',
    'L3-02 cours particulier', 2::smallint, 18::smallint, 1::smallint, 'Europe/Paris');
  if (select seuil_max from public.groupes where id = v_id) <> 1 then
    raise exception 'L3-02: creer_groupe n''a pas garde seuil_max = 1';
  end if;
end $$;
reset role;

-- Les privilèges : fermes aux comptes connectes et a anon, pas supprimes.
do $$
begin
  if has_function_privilege('authenticated', 'public.prendre_eleve(uuid,integer,integer)', 'execute')
     or has_function_privilege('authenticated', 'public.attribuer_eleve(uuid,uuid,integer,integer,text)', 'execute')
     or has_function_privilege('anon', 'public.prendre_eleve(uuid,integer,integer)', 'execute')
     or has_function_privilege('anon', 'public.attribuer_eleve(uuid,uuid,integer,integer,text)', 'execute') then
    raise exception 'L3-02: privilege EXECUTE restant';
  end if;
  if to_regprocedure('public.prendre_eleve(uuid,integer,integer)') is null
     or to_regprocedure('public.attribuer_eleve(uuid,uuid,integer,integer,text)') is null then
    raise exception 'L3-02: fonction supprimee au lieu d''etre fermee';
  end if;
end $$;
rollback;
