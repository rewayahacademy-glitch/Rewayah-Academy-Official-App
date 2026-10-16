-- IMM-BACK-1 A: synthetic RA format, uniqueness and collision retry cases.
begin;

-- Test-only Supabase Auth fields used by the server-origin guard; the shared
-- stub_auth.sql remains untouched.
alter table auth.users add column if not exists raw_app_meta_data jsonb not null default '{}'::jsonb;
-- created_at reste nullable, comme sur Supabase, pour sonder la garde NULL.
alter table auth.users add column if not exists created_at timestamptz default now();

create temporary table imm_back_1_draws (attempts integer not null) on commit drop;
insert into imm_back_1_draws values (0);
insert into private.person_registrations
  (profile_id, matricule, registration_year, issued_at)
values ('a1150000-0000-0000-0000-000000000001', 'RA-50-1234', 2050, '2050-01-01 UTC');

create or replace function private.tirer_nombre_matricule(p_width integer)
returns integer
language plpgsql security definer set search_path = ''
as $forced_draw$
declare
  v_attempt integer;
  v_number integer;
begin
  update pg_temp.imm_back_1_draws
     set attempts = attempts + 1
   returning attempts into v_attempt;
  if v_attempt = 1 then return 1234; end if;
  if v_attempt = 2 then return 5678; end if;
  if v_attempt = 3 then return 8765; end if;
  if p_width = 4 then
    select n into v_number
      from pg_catalog.generate_series(0, 9999) as candidates(n)
     where n > 0 and not exists (
       select 1 from private.person_registrations r
        where pg_catalog.split_part(r.matricule, '-', 3) = pg_catalog.lpad(n::text, 4, '0')
     )
     order by n limit 1;
    return v_number;
  end if;
  select n into v_number
    from pg_catalog.generate_series(10000, 99999) as candidates(n)
   where not exists (
     select 1 from private.person_registrations r
      where pg_catalog.split_part(r.matricule, '-', 3) = pg_catalog.lpad(n::text, 5, '0')
   )
   order by n limit 1;
  return v_number;
end;
$forced_draw$;

do $allocator$
declare
  v_code text;
  v_other text;
begin
  v_code := private.attribuer_matricule(
    'a1150000-0000-0000-0000-000000000002', '2050-01-02 UTC'
  );
  v_other := private.attribuer_matricule(
    'a1150000-0000-0000-0000-000000000003', '2050-01-03 UTC'
  );
  if v_code <> 'RA-50-5678'
     or v_other <> 'RA-50-8765'
     or v_code = v_other
     or (select attempts from imm_back_1_draws) <> 3
     or (select count(*) from private.person_registrations
          where profile_id in (
            'a1150000-0000-0000-0000-000000000002',
            'a1150000-0000-0000-0000-000000000003'
          )) <> 2 then
    raise exception 'IMM-01/02/03: format, unicite ou reprise apres collision incorrects';
  end if;
end;
$allocator$;

-- IMM-BACK-1 B: official creation paths and immutability.
-- Toutes les ecritures de fixture (auth.users, auth.sessions, profils) se
-- font en proprietaire. Seuls les appels de RPC passent par le role
-- authenticated, dans une sous-transaction annulee (pg_temp.f86_essai_*).
insert into auth.users (id, email) values
  ('a1100000-0000-0000-0000-000000000001', 'imm1-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000002', 'imm1-outsider@example.test'),
  ('a1100000-0000-0000-0000-000000000003', 'imm1-child@example.test'),
  ('a1100000-0000-0000-0000-000000000004', 'imm1-admin@example.test'),
  ('a1100000-0000-0000-0000-000000000005', 'imm1-signup-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000006', 'imm1-signup-teacher@example.test'),
  ('a1100000-0000-0000-0000-000000000008', 'imm1-direct-insert@example.test'),
  ('a1100000-0000-0000-0000-000000000009', 'imm1-atomic-failure@example.test'),
  ('a1100000-0000-0000-0000-000000000010', 'imm1-teacher@example.test'),
  ('a1100000-0000-0000-0000-000000000011', 'imm1-student@example.test'),
  ('a1100000-0000-0000-0000-000000000012', 'imm1-pending-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000013', 'imm1-expired-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000014', 'imm1-homeless-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000015', 'imm1-active-admin@example.test'),
  ('a1100000-0000-0000-0000-000000000016', 'imm1-signup-probe@example.test');
update auth.users set raw_app_meta_data = jsonb_build_object(
  'child_of', 'a1100000-0000-0000-0000-000000000001'
) where id in ('a1100000-0000-0000-0000-000000000003',
               'a1100000-0000-0000-0000-000000000009');
insert into public.households (id, timezone) values
  ('a11fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('a11fffff-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a1100000-0000-0000-0000-000000000001', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Amira', 'Test', 'active'),
  ('a1100000-0000-0000-0000-000000000002', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000002', 'Nadia', 'Outside', 'active'),
  ('a1100000-0000-0000-0000-000000000004', null, 'admin',
   null, 'Admin', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000010', null, 'teacher',
   'a11fffff-0000-0000-0000-000000000001', 'Teacher', 'Fixture', 'provisional_active'),
  ('a1100000-0000-0000-0000-000000000011', null, 'student',
   'a11fffff-0000-0000-0000-000000000001', 'Student', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000012', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Pending', 'Guardian', 'pending_kyc'),
  ('a1100000-0000-0000-0000-000000000013', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Expired', 'Guardian', 'active'),
  ('a1100000-0000-0000-0000-000000000015', null, 'admin',
   null, 'Active', 'Admin', 'active');
update public.profiles set access_until = '2000-01-01 UTC'
 where id = 'a1100000-0000-0000-0000-000000000013';

-- L'enseignant de fixture est un vrai enseignant en periode probatoire : il a
-- signe le NDA courant. Il passe donc app_account_valid() et c'est bien la
-- garde de role de creer_profil_enfant qui doit le refuser.
do $teacher_signs_nda$
declare
  v_version text;
begin
  select t.version into v_version from public.contract_texts t
   where t.contract_kind = 'teacher_nda' and t.locale = 'fr' and t.is_current;
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000010', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000010","app_metadata":{"role":"teacher"}}', true);
  perform public.signer_contrat(v_version, 'Enseignant Fixture');
  if not exists (
       select 1 from public.contract_acceptances c
        where c.profile_id = 'a1100000-0000-0000-0000-000000000010'
          and c.contract_kind = 'teacher_nda' and c.version = v_version
          and c.signed_sha256 is not null)
     or not exists (
       select 1 from public.profiles p
        where p.id = 'a1100000-0000-0000-0000-000000000010'
          and p.account_status = 'provisional_active') then
    raise exception 'IMM-BACK-1: fixture enseignant sans NDA signe';
  end if;
end;
$teacher_signs_nda$;

do $official_creation_paths$
declare
  v_profile public.profiles;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000005', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000005","app_metadata":{"role":"guardian"}}', true);
  v_profile := public.creer_profil_inscription(
    'guardian', 'Salma', 'Signup', null, 'Europe/Paris', false
  );
  if not exists (select 1 from private.person_registrations r
                  where r.profile_id = v_profile.id and r.matricule = v_profile.immutable_id) then
    raise exception 'IMM-01: inscription guardian sans registre';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000006', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000006","app_metadata":{"role":"teacher"}}', true);
  v_profile := public.creer_profil_inscription(
    'teacher', 'Omar', 'Signup', null, 'Europe/Paris', false
  );
  if not exists (select 1 from private.person_registrations r
                  where r.profile_id = v_profile.id and r.matricule = v_profile.immutable_id) then
    raise exception 'IMM-01: inscription teacher sans registre';
  end if;
end;
$official_creation_paths$;

do $registration_rpc_acl$
declare
  v_fn text;
begin
  foreach v_fn in array array[
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)',
    'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'
  ] loop
    if not has_function_privilege('authenticated', v_fn, 'EXECUTE')
       or has_function_privilege('anon', v_fn, 'EXECUTE')
       or has_function_privilege('service_role', v_fn, 'EXECUTE')
       or has_function_privilege('agent_ro', v_fn, 'EXECUTE') then
      raise exception 'IMM-BACK-1: droits EXECUTE incorrects sur %', v_fn;
    end if;
  end loop;
end;
$registration_rpc_acl$;

-- Les sondes F86 appellent la RPC en authenticated puis annulent tout effet.
-- Elles rendent le message d'erreur exact, ou '__f86_accepte__' si l'appel est
-- passe (et a ete annule). Chaque refus est compare a son message attendu,
-- pour qu'une garde retiree ne soit pas masquee par une erreur plus loin.
create temporary table f86_controles (label text not null) on commit drop;
create function pg_temp.f86_attendu(p_label text, p_obtenu text, p_attendu text)
returns void language plpgsql as $attendu$
begin
  if p_obtenu is distinct from p_attendu then
    raise exception 'F86 %: attendu "%", obtenu "%"', p_label, p_attendu, p_obtenu;
  end if;
  insert into pg_temp.f86_controles values (p_label);
end;
$attendu$;

create function pg_temp.f86_essai_enfant(
  p_actor uuid, p_auth uuid, p_guardian uuid,
  p_first text, p_last text, p_age integer
) returns text language plpgsql as $essai_enfant$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_actor::text, ''), true);
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', p_actor, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    perform public.creer_profil_enfant(p_auth, p_guardian, p_first, p_last, p_age, null);
    raise exception '__f86_accepte__';
  exception when others then
    return sqlerrm;
  end;
end;
$essai_enfant$;

create function pg_temp.f86_essai_inscription(
  p_actor uuid, p_role text, p_first text, p_last text, p_parent boolean
) returns text language plpgsql as $essai_inscription$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_actor::text, ''), true);
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', p_actor, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    perform public.creer_profil_inscription(
      p_role, p_first, p_last, null, 'Europe/Paris', p_parent
    );
    raise exception '__f86_accepte__';
  exception when others then
    return sqlerrm;
  end;
end;
$essai_inscription$;

-- auth.sessions existe sur Supabase ; le stub CI ne l'a pas. On cree, en
-- proprietaire, les deux colonnes que la garde lit.
create table if not exists auth.sessions (
  id uuid primary key,
  user_id uuid not null
);

-- F86 creer_profil_enfant : une sonde de refus par garde, chacune ne differant
-- de la base valide que par la condition testee. L'heure est simulee en
-- deplacant auth.users.created_at autour de now() (heure de la transaction).
do $child_rpc_guards$
declare
  c_ok constant text := '__f86_accepte__';
  c_appelant constant text := 'appelant tuteur invalide';
  c_role constant text := 'l''appelant n''est pas un tuteur';
  c_foyer constant text := 'ce tuteur n''a pas de foyer';
  c_statut constant text := 'compte tuteur non valide';
  c_noms constant text := 'prenom et nom sont requis';
  c_age constant text := 'age hors bornes';
  c_origine constant text := 'compte enfant non issu de la creation serveur recente';
  g constant uuid := 'a1100000-0000-0000-0000-000000000001';
  o constant uuid := 'a1100000-0000-0000-0000-000000000002';
  enf constant uuid := 'a1100000-0000-0000-0000-000000000009';
  v_actor uuid;
  v_attendu text;
  v_obtenu text;
begin
  -- Base valide : compte 9 cree par le serveur pour le tuteur 1, a l'instant.
  update auth.users set raw_app_meta_data = jsonb_build_object('child_of', g::text),
         created_at = now(), email_confirmed_at = null
   where id = enf;
  perform pg_temp.f86_attendu('base valide acceptee',
    pg_temp.f86_essai_enfant(g, enf, g, 'Base', 'Valide', 10), c_ok);

  -- Garde 1 (auth.uid() = p_guardian_id) : un autre tuteur valide, porteur
  -- d'un compte enfant a son nom, ne peut pas agir pour le tuteur 1.
  update auth.users set raw_app_meta_data = jsonb_build_object('child_of', o::text)
   where id = enf;
  perform pg_temp.f86_attendu('autre tuteur pour le tuteur 1',
    pg_temp.f86_essai_enfant(o, enf, g, 'Intrus', 'Fixture', 10), c_appelant);

  -- Gardes 1 (app_account_valid) et 2 (role) : chaque acteur porte un compte
  -- enfant a son nom, seule sa capacite le fait refuser.
  for v_actor, v_attendu in
    select * from (values
      ('a1100000-0000-0000-0000-000000000010'::uuid, c_role),      -- enseignant NDA signe
      ('a1100000-0000-0000-0000-000000000011'::uuid, c_role),      -- eleve actif
      ('a1100000-0000-0000-0000-000000000015'::uuid, c_role),      -- admin actif
      ('a1100000-0000-0000-0000-000000000012'::uuid, c_appelant),  -- tuteur pending_kyc
      ('a1100000-0000-0000-0000-000000000013'::uuid, c_appelant)   -- tuteur acces expire
    ) as actors(id, attendu)
  loop
    update auth.users set raw_app_meta_data = jsonb_build_object('child_of', v_actor::text)
     where id = enf;
    perform pg_temp.f86_attendu('acteur ' || v_actor::text,
      pg_temp.f86_essai_enfant(v_actor, enf, v_actor, 'Refuse', 'Fixture', 10), v_attendu);
  end loop;

  -- Administrateur desactive.
  update public.profiles set account_status = 'disabled'
   where id = 'a1100000-0000-0000-0000-000000000004';
  update auth.users set raw_app_meta_data = jsonb_build_object(
    'child_of', 'a1100000-0000-0000-0000-000000000004') where id = enf;
  perform pg_temp.f86_attendu('admin desactive',
    pg_temp.f86_essai_enfant('a1100000-0000-0000-0000-000000000004', enf,
      'a1100000-0000-0000-0000-000000000004', 'Refuse', 'Fixture', 10), c_appelant);
  update public.profiles set account_status = 'active'
   where id = 'a1100000-0000-0000-0000-000000000004';

  -- Garde 3 (foyer, defense en profondeur) : profiles_household_required
  -- interdit aujourd'hui un tuteur sans foyer. On leve la contrainte dans une
  -- sous-transaction annulee pour prouver que la garde tient seule.
  begin
    alter table public.profiles drop constraint profiles_household_required;
    insert into public.profiles
      (id, immutable_id, role, household_id, first_name, last_name, account_status)
    values ('a1100000-0000-0000-0000-000000000014', null, 'guardian',
            null, 'Homeless', 'Guardian', 'active');
    update auth.users set raw_app_meta_data = jsonb_build_object(
      'child_of', 'a1100000-0000-0000-0000-000000000014') where id = enf;
    v_obtenu := pg_temp.f86_essai_enfant('a1100000-0000-0000-0000-000000000014', enf,
      'a1100000-0000-0000-0000-000000000014', 'Sans', 'Foyer', 10);
    raise exception '__f86_restaure__';
  exception when others then
    if sqlerrm <> '__f86_restaure__' then raise; end if;
  end;
  perform pg_temp.f86_attendu('tuteur sans foyer', v_obtenu, c_foyer);

  -- Garde 4 (statut local, defense en profondeur) : app_account_valid() rejette
  -- aujourd'hui les memes statuts. On le neutralise dans une sous-transaction
  -- annulee pour prouver que la garde locale tient seule.
  update auth.users set raw_app_meta_data = jsonb_build_object(
    'child_of', 'a1100000-0000-0000-0000-000000000012') where id = enf;
  begin
    create or replace function public.app_account_valid()
    returns boolean language sql stable security definer set search_path = ''
    as $neutre$ select true $neutre$;
    v_obtenu := pg_temp.f86_essai_enfant('a1100000-0000-0000-0000-000000000012', enf,
      'a1100000-0000-0000-0000-000000000012', 'Statut', 'Local', 10);
    raise exception '__f86_restaure__';
  exception when others then
    if sqlerrm <> '__f86_restaure__' then raise; end if;
  end;
  perform pg_temp.f86_attendu('statut local sans app_account_valid', v_obtenu, c_statut);
  perform pg_temp.f86_attendu('app_account_valid restaure',
    pg_temp.f86_essai_enfant('a1100000-0000-0000-0000-000000000012', enf,
      'a1100000-0000-0000-0000-000000000012', 'Statut', 'Local', 10), c_appelant);

  -- Gardes 5 et 6 : noms et bornes d'age, sur la base valide.
  update auth.users set raw_app_meta_data = jsonb_build_object('child_of', g::text)
   where id = enf;
  perform pg_temp.f86_attendu('prenom blanc',
    pg_temp.f86_essai_enfant(g, enf, g, '  ', 'Fixture', 10), c_noms);
  perform pg_temp.f86_attendu('nom absent',
    pg_temp.f86_essai_enfant(g, enf, g, 'Prenom', null, 10), c_noms);
  perform pg_temp.f86_attendu('age 2',
    pg_temp.f86_essai_enfant(g, enf, g, 'Age', 'Bas', 2), c_age);
  perform pg_temp.f86_attendu('age 100',
    pg_temp.f86_essai_enfant(g, enf, g, 'Age', 'Haut', 100), c_age);
  perform pg_temp.f86_attendu('age absent',
    pg_temp.f86_essai_enfant(g, enf, g, 'Age', 'Absent', null), c_age);
  perform pg_temp.f86_attendu('age 3 accepte',
    pg_temp.f86_essai_enfant(g, enf, g, 'Age', 'Min', 3), c_ok);
  perform pg_temp.f86_attendu('age 99 accepte',
    pg_temp.f86_essai_enfant(g, enf, g, 'Age', 'Max', 99), c_ok);

  -- Garde 7 (origine serveur) : l'attaque d'origine. Un tuteur ne rattache pas
  -- le compte Auth d'un tiers, qu'il soit inexistant, sans provenance, ou cree
  -- par le serveur pour un autre tuteur.
  perform pg_temp.f86_attendu('compte auth inexistant',
    pg_temp.f86_essai_enfant(g, 'a1100000-0000-0000-0000-000000000099', g, 'Sans', 'Compte', 10),
    c_origine);
  perform pg_temp.f86_attendu('compte auth sans provenance',
    pg_temp.f86_essai_enfant(g, 'a1100000-0000-0000-0000-000000000008', g, 'Sans', 'Preuve', 10),
    c_origine);
  update auth.users set raw_app_meta_data = jsonb_build_object('child_of', o::text)
   where id = enf;
  perform pg_temp.f86_attendu('compte enfant d''un autre tuteur',
    pg_temp.f86_essai_enfant(g, enf, g, 'Vol', 'Compte', 10), c_origine);
  update auth.users set raw_app_meta_data = jsonb_build_object('child_of', g::text)
   where id = enf;

  -- Fraicheur : 15 minutes en arriere, 1 minute d'ecart d'horloge en avant.
  update auth.users set created_at = null where id = enf;
  perform pg_temp.f86_attendu('created_at absent',
    pg_temp.f86_essai_enfant(g, enf, g, 'Sans', 'Date', 10), c_origine);
  update auth.users set created_at = now() - interval '16 minutes' where id = enf;
  perform pg_temp.f86_attendu('compte cree il y a 16 min',
    pg_temp.f86_essai_enfant(g, enf, g, 'Trop', 'Ancien', 10), c_origine);
  update auth.users set created_at = now() - interval '14 minutes' where id = enf;
  perform pg_temp.f86_attendu('compte cree il y a 14 min accepte',
    pg_temp.f86_essai_enfant(g, enf, g, 'Encore', 'Frais', 10), c_ok);
  update auth.users set created_at = now() + interval '2 minutes' where id = enf;
  perform pg_temp.f86_attendu('created_at futur de 2 min',
    pg_temp.f86_essai_enfant(g, enf, g, 'Date', 'Future', 10), c_origine);
  update auth.users set created_at = now() + interval '30 seconds' where id = enf;
  perform pg_temp.f86_attendu('ecart d''horloge de 30 s accepte',
    pg_temp.f86_essai_enfant(g, enf, g, 'Horloge', 'Decalee', 10), c_ok);
  update auth.users set created_at = now() where id = enf;

  -- Compte confirme, ou deja connecte.
  update auth.users set email_confirmed_at = now() where id = enf;
  perform pg_temp.f86_attendu('compte enfant confirme',
    pg_temp.f86_essai_enfant(g, enf, g, 'Confirmed', 'Fixture', 10), c_origine);
  update auth.users set email_confirmed_at = null where id = enf;
  insert into auth.sessions (id, user_id)
  values ('a1100000-0000-0000-0000-000000000088', enf);
  perform pg_temp.f86_attendu('compte enfant avec session',
    pg_temp.f86_essai_enfant(g, enf, g, 'Session', 'Fixture', 10), c_origine);
  delete from auth.sessions where id = 'a1100000-0000-0000-0000-000000000088';

  perform pg_temp.f86_attendu('base valide toujours acceptee',
    pg_temp.f86_essai_enfant(g, enf, g, 'Base', 'Finale', 10), c_ok);
end;
$child_rpc_guards$;

-- Creation reelle du compte 3, en authenticated, puis profil deja existant.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000001","app_metadata":{"role":"guardian","household_id":"a11fffff-0000-0000-0000-000000000001"}}', true);
select public.creer_profil_enfant(
  'a1100000-0000-0000-0000-000000000003',
  'a1100000-0000-0000-0000-000000000001', 'Lina', 'Created', 10, null
);
reset role;
select pg_temp.f86_attendu('profil existant',
  pg_temp.f86_essai_enfant('a1100000-0000-0000-0000-000000000001',
    'a1100000-0000-0000-0000-000000000003', 'a1100000-0000-0000-0000-000000000001',
    'Duplicate', 'Profile', 10),
  'compte enfant non issu de la creation serveur recente');

-- F86 creer_profil_inscription : une sonde de refus par garde.
do $registration_rpc_guards$
declare
  c_ok constant text := '__f86_accepte__';
  n constant uuid := 'a1100000-0000-0000-0000-000000000016';
begin
  perform pg_temp.f86_attendu('inscription sans session',
    pg_temp.f86_essai_inscription(null, 'guardian', 'Sans', 'Session', false),
    'aucune session');
  perform pg_temp.f86_attendu('inscription admin',
    pg_temp.f86_essai_inscription(n, 'admin', 'Role', 'Prive', false),
    'role non ouvert a l''inscription publique : admin');
  perform pg_temp.f86_attendu('inscription eleve',
    pg_temp.f86_essai_inscription(n, 'student', 'Role', 'Prive', false),
    'role non ouvert a l''inscription publique : student');
  perform pg_temp.f86_attendu('enseignant apprenant personnel',
    pg_temp.f86_essai_inscription(n, 'teacher', 'Enseignant', 'Apprenant', true),
    'profil apprenant personnel reserve au titulaire');
  perform pg_temp.f86_attendu('second profil',
    pg_temp.f86_essai_inscription('a1100000-0000-0000-0000-000000000001',
      'guardian', 'Deja', 'Inscrit', false),
    'ce compte a deja un profil');
  perform pg_temp.f86_attendu('inscription prenom blanc',
    pg_temp.f86_essai_inscription(n, 'guardian', ' ', 'Nom', false),
    'prenom et nom sont requis');
  perform pg_temp.f86_attendu('inscription nom absent',
    pg_temp.f86_essai_inscription(n, 'guardian', 'Prenom', null, false),
    'prenom et nom sont requis');
  perform pg_temp.f86_attendu('inscription tuteur apprenant acceptee',
    pg_temp.f86_essai_inscription(n, 'guardian', 'Tuteur', 'Apprenant', true), c_ok);
  perform pg_temp.f86_attendu('inscription enseignant acceptee',
    pg_temp.f86_essai_inscription(n, 'teacher', 'Enseignant', 'Valide', false), c_ok);
  if exists (select 1 from public.profiles where id = n) then
    raise exception 'IMM-BACK-1: une sonde d''inscription a laisse un profil';
  end if;
end;
$registration_rpc_guards$;

do $f86_bilan$
begin
  raise notice 'F86 inscription: % controles de sonde verts',
    (select count(*) from pg_temp.f86_controles);
end;
$f86_bilan$;

do $child_profile_registry$
begin
  if not exists (
    select 1 from public.profiles p
    join private.person_registrations r on r.profile_id = p.id
    where p.id = 'a1100000-0000-0000-0000-000000000003'
      and p.immutable_id ~ '^RA-[0-9]{2}-[0-9]{4,5}$'
      and r.matricule = p.immutable_id
  ) then
    raise exception 'IMM-01: parcours enfant sans matricule du registre';
  end if;
end;
$child_profile_registry$;

-- A dependent-row failure proves profile and reservation roll back together.
create function pg_temp.imm_back_1_fail_student_profile()
returns trigger language plpgsql set search_path = '' as $fail$
begin
  if new.profile_id = 'a1100000-0000-0000-0000-000000000009' then
    raise exception 'IMM-BACK-1 forced post-allocation failure';
  end if;
  return new;
end;
$fail$;
create trigger imm_back_1_force_student_failure
before insert on public.student_profiles
for each row execute function pg_temp.imm_back_1_fail_student_profile();
do $atomicity$
declare
  v_failed boolean := false;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000001","app_metadata":{"role":"guardian"}}', true);
  begin
    perform public.creer_profil_enfant(
      'a1100000-0000-0000-0000-000000000009',
      'a1100000-0000-0000-0000-000000000001', 'Atomic', 'Rollback', 10, null
    );
  exception when raise_exception then
    v_failed := true;
  end;
  if not v_failed
     or exists (select 1 from public.profiles where id = 'a1100000-0000-0000-0000-000000000009')
     or exists (select 1 from private.person_registrations
                 where profile_id = 'a1100000-0000-0000-0000-000000000009') then
    raise exception 'IMM-BACK-1: profil ou matricule conservé après échec';
  end if;
end;
$atomicity$;
drop trigger imm_back_1_force_student_failure on public.student_profiles;
drop function pg_temp.imm_back_1_fail_student_profile();

do $coverage_and_immutability$
declare
  v_code text;
  v_immutable boolean := false;
begin
  if exists (
    select 1 from public.profiles p
    left join private.person_registrations r on r.profile_id = p.id
    where r.profile_id is null or r.matricule is distinct from p.immutable_id
  ) then
    raise exception 'IMM-02/04: profil sans matricule correspondant au registre';
  end if;
  select immutable_id into v_code from public.profiles
   where id = 'a1100000-0000-0000-0000-000000000003';
  update public.profiles set first_name = 'LinaRenommee', role = 'guardian'
   where id = 'a1100000-0000-0000-0000-000000000003';
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000003') <> v_code then
    raise exception 'IMM-04: renommage ou changement de role a modifie le matricule';
  end if;
  begin
    update public.profiles set immutable_id = 'RA-00-0000'
     where id = 'a1100000-0000-0000-0000-000000000003';
  exception when raise_exception then
    v_immutable := true;
  end;
  if not v_immutable then
    raise exception 'IMM-04: modification directe du matricule acceptee';
  end if;
  if has_table_privilege('authenticated', 'private.person_registrations', 'SELECT')
     or has_table_privilege('service_role', 'private.person_registrations', 'SELECT') then
    raise exception 'IMM-09: lecture directe du registre accordee';
  end if;
end;
$coverage_and_immutability$;

-- IMM-BACK-1 C: the 4,500th code remains four digits; later ones use five.
insert into private.person_registrations
  (profile_id, matricule, registration_year, issued_at)
select
  ('a1290000-0000-0000-0000-' || pg_catalog.lpad(n::text, 12, '0'))::uuid,
  'RA-99-' || pg_catalog.lpad(n::text, 4, '0'),
  2099, '2099-01-01 UTC'
from pg_catalog.generate_series(0, 4498) as candidates(n);
do $threshold$
declare
  v_four text;
  v_five text;
begin
  v_four := private.attribuer_matricule(
    'a1299999-0000-0000-0000-000000000001', '2099-01-02 UTC'
  );
  v_five := private.attribuer_matricule(
    'a1299999-0000-0000-0000-000000000002', '2099-01-03 UTC'
  );
  if v_four !~ '^RA-99-[0-9]{4}$' or v_five !~ '^RA-99-[0-9]{5}$' then
    raise exception 'IMM-11: seuil 4500 incorrect';
  end if;
end;
$threshold$;

-- A deleted account keeps its permanent reservation and cannot receive a new code.
insert into auth.users (id, email)
values ('a1100000-0000-0000-0000-000000000007', 'imm1-retired@example.test');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values ('a1100000-0000-0000-0000-000000000007', null, 'guardian',
        'a11fffff-0000-0000-0000-000000000001', 'Retired', 'Fixture', 'active');
select set_config('imm.back1.deleted_code',
  (select immutable_id from public.profiles where id = 'a1100000-0000-0000-0000-000000000007'), true);
delete from auth.users where id = 'a1100000-0000-0000-0000-000000000007';
do $non_reassignment$
declare
  v_code text := current_setting('imm.back1.deleted_code');
begin
  if exists (select 1 from public.profiles where id = 'a1100000-0000-0000-0000-000000000007')
     or not exists (select 1 from private.person_registrations
                     where profile_id = 'a1100000-0000-0000-0000-000000000007'
                       and matricule = v_code)
     or private.attribuer_matricule('a1100000-0000-0000-0000-000000000007', now()) <> v_code then
    raise exception 'IMM-12: code libere apres suppression';
  end if;
end;
$non_reassignment$;

-- Direct authenticated admin INSERT cannot preserve a caller-supplied code.
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000004","role":"authenticated","app_metadata":{"role":"admin"}}', true);
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values ('a1100000-0000-0000-0000-000000000008', 'RA-26-0000', 'guardian',
        'a11fffff-0000-0000-0000-000000000001', 'Direct', 'Insert', 'active');
reset session authorization;
do $caller_chosen_code$
begin
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000008') = 'RA-26-0000'
     or not exists (
       select 1 from private.person_registrations r
        join public.profiles p on p.id = r.profile_id
        where r.profile_id = 'a1100000-0000-0000-0000-000000000008'
          and r.matricule = p.immutable_id
     ) then
    raise exception 'IMM-09: insertion directe a conserve le matricule fourni';
  end if;
end;
$caller_chosen_code$;
set local session authorization authenticated;

-- Exact lookup accepts separators/case but never reveals non-related profiles.
do $lookup_and_acl$
declare
  v_code text := (select immutable_id from public.profiles
                   where id = 'a1100000-0000-0000-0000-000000000003');
  v_outsider_code text := (select immutable_id from public.profiles
                            where id = 'a1100000-0000-0000-0000-000000000002');
  v_rows integer;
  v_denied boolean := false;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(lower(replace(v_code, '-', ' '))) r
   where r.profile_id = 'a1100000-0000-0000-0000-000000000003'
     and r.matricule = v_code and r.first_name = 'LinaRenommee'
     and r.role = 'guardian';
  if v_rows <> 1
     or exists (select 1 from public.rechercher_personne_par_matricule(v_outsider_code))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-O1-12I4'))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-26-')) then
    raise exception 'IMM-05: recherche exacte ou droits du foyer incorrects';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000002',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000002'
    )
  )::text, true);
  if exists (select 1 from public.rechercher_personne_par_matricule(v_code)) then
    raise exception 'IMM-09: foyer etranger a resolu un matricule connu';
  end if;

  begin
    perform 1 from private.person_registrations;
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'IMM-09: lecture directe du registre permise';
  end if;
end;
$lookup_and_acl$;

reset session authorization;
update public.profiles set account_status = 'disabled'
 where id = 'a1100000-0000-0000-0000-000000000002';
select set_config('imm.back1.disabled_lookup_code',
  (select immutable_id from public.profiles
    where id = 'a1100000-0000-0000-0000-000000000002'), true);
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'a1100000-0000-0000-0000-000000000002',
  'role', 'authenticated',
  'app_metadata', jsonb_build_object(
    'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000002'
  )
)::text, true);
do $disabled_lookup$
declare
  v_code text := current_setting('imm.back1.disabled_lookup_code');
begin
  if exists (select 1 from public.rechercher_personne_par_matricule(v_code)) then
    raise exception 'IMM-BACK-1: compte désactivé a recherché un matricule';
  end if;
end;
$disabled_lookup$;

reset session authorization;
do $catalogue$
begin
  if not exists (
    select 1 from pg_catalog.pg_index i
    join pg_catalog.pg_class t on t.oid = i.indrelid
    join pg_catalog.pg_namespace n on n.oid = t.relnamespace
    join pg_catalog.pg_attribute a on a.attrelid = t.oid
      and a.attname = 'matricule' and a.attnum = i.indkey[0]
    where n.nspname = 'private' and t.relname = 'person_registrations'
      and i.indisunique and i.indisvalid and i.indpred is null and i.indexprs is null
  ) then
    raise exception 'IMM-14: index unique exact du matricule absent';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid in (
       'private.tirer_nombre_matricule(integer)'::regprocedure,
       'private.attribuer_matricule(uuid,timestamptz)'::regprocedure,
       'public.profiles_attribuer_matricule()'::regprocedure,
       'public.rechercher_personne_par_matricule(text)'::regprocedure
     )
       and (not p.prosecdef or p.proowner <> 'postgres'::regrole
         or not (p.proconfig @> array['search_path=""']))
  ) then
    raise exception 'IMM-BACK-1: nouveau DEFINER sans owner postgres et search_path vide';
  end if;
  -- F86 : le commentaire DEFINER porte l'empreinte reelle de la definition.
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid in (
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)'::regprocedure,
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'::regprocedure
     )
       and (not p.prosecdef or p.proowner <> 'postgres'::regrole
         or not (p.proconfig @> array['search_path=""'])
         or position('md5_functiondef=' || md5(pg_get_functiondef(p.oid))
                     in coalesce(obj_description(p.oid, 'pg_proc'), '')) = 0)
  ) then
    raise exception 'F86: empreinte md5 du commentaire DEFINER inexacte (inscription)';
  end if;
end;
$catalogue$;

rollback;
