-- COULEUR-PROFIL (22 i, migration 20261110500000) : la cle d'accent d'un
-- profil. Joue sous `authenticated`, comme un client.
--   1. le tuteur choisit, change et retire la couleur de son enfant, et la relit ;
--   2. une cle hors des six jetons est refusee (jamais une couleur libre) ;
--   3. personne n'ecrit la colonne en direct ;
--   4. l'enfant relit SA couleur, jamais celle de son frere, et ne l'ecrit pas ;
--   5. l'adulte autonome choisit la sienne ;
--   6. un tuteur d'un autre foyer ne lit ni n'ecrit rien chez le premier ;
--   7. anon n'execute aucune des deux fonctions ;
--   8. a la creation, chaque profil recoit une couleur au hasard, differente
--      de celles deja prises dans son foyer (directeur, 06/11/2026) ; une cle
--      fournie a la creation est gardee.
-- Tout est dans une transaction annulee : aucune donnee ne reste.
begin;

insert into auth.users (id, email) values
  ('c0c00000-0000-0000-0000-000000000001', 'cp-tuteur@example.test'),
  ('c0c00000-0000-0000-0000-000000000002', 'cp-enfant1@example.test'),
  ('c0c00000-0000-0000-0000-000000000003', 'cp-enfant2@example.test'),
  ('c0c00000-0000-0000-0000-000000000004', 'cp-adulte@example.test'),
  ('c0c00000-0000-0000-0000-000000000005', 'cp-autre@example.test');

insert into public.households (id, timezone) values
  ('c0c0ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('c0c0ffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('c0c0ffff-0000-0000-0000-000000000003', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c0c00000-0000-0000-0000-000000000001', 'CPTUTEUR00001', 'guardian',
   'c0c0ffff-0000-0000-0000-000000000001', 'Tuteur', 'Couleur', 'active', 'male'),
  ('c0c00000-0000-0000-0000-000000000002', 'CPELEVE000001', 'student',
   'c0c0ffff-0000-0000-0000-000000000001', 'Yusuf', 'Couleur', 'active', 'male'),
  ('c0c00000-0000-0000-0000-000000000003', 'CPELEVE000002', 'student',
   'c0c0ffff-0000-0000-0000-000000000001', 'Aicha', 'Couleur', 'active', 'female'),
  ('c0c00000-0000-0000-0000-000000000004', 'CPELEVE000003', 'student',
   'c0c0ffff-0000-0000-0000-000000000002', 'Adulte', 'Couleur', 'active', 'female'),
  ('c0c00000-0000-0000-0000-000000000005', 'CPTUTEUR00002', 'guardian',
   'c0c0ffff-0000-0000-0000-000000000003', 'Autre', 'Couleur', 'active', 'male');

insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('c0c00000-0000-0000-0000-000000000002', 'minor', 'child'),
  ('c0c00000-0000-0000-0000-000000000003', 'minor', 'child'),
  ('c0c00000-0000-0000-0000-000000000004', 'autonomous', 'standard');

do $creation$
begin
  -- 8. Couleur attribuee a la creation, deux freres et soeurs differents.
  if exists (select 1 from public.student_profiles
              where profile_id in ('c0c00000-0000-0000-0000-000000000002',
                                   'c0c00000-0000-0000-0000-000000000003',
                                   'c0c00000-0000-0000-0000-000000000004')
                and accent_key is null) then
    raise exception 'CP-8: un profil cree n''a pas recu de couleur';
  end if;
  if (select count(distinct accent_key) from public.student_profiles
       where profile_id in ('c0c00000-0000-0000-0000-000000000002',
                            'c0c00000-0000-0000-0000-000000000003')) <> 2 then
    raise exception 'CP-8: deux profils du meme foyer ont recu la meme couleur';
  end if;
end
$creation$;

create function pg_temp.etre(p_id uuid, p_role text) returns void language sql
security definer as $$
  select set_config('test.uid', p_id::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role, 'household_id',
             (select household_id from public.profiles where id = p_id)))::text, true);
$$;
grant execute on function pg_temp.etre(uuid, text) to authenticated;

set local role authenticated;

do $tuteur$
declare
  n integer;
begin
  perform pg_temp.etre('c0c00000-0000-0000-0000-000000000001', 'guardian');

  -- 1. Choisir, relire, changer, retirer.
  perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000002', 'menthe');
  perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000003', 'ciel');
  select count(*) into n from public.accents_profils_du_foyer();
  if n <> 2 then raise exception 'CP-1: le tuteur relit % couleurs, 2 attendues', n; end if;
  perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000002', 'rose');
  if (select accent_key from public.accents_profils_du_foyer()
       where profile_id = 'c0c00000-0000-0000-0000-000000000002') is distinct from 'rose' then
    raise exception 'CP-1: le changement de couleur n''est pas relu';
  end if;
  perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000003', null);
  select count(*) into n from public.accents_profils_du_foyer();
  if n <> 1 then raise exception 'CP-1: « Sans couleur » n''a pas retire la couleur (% lignes)', n; end if;

  -- 2. Jamais une couleur libre.
  begin
    perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000002', '#ff0000');
    raise exception 'CP-2: une couleur libre est acceptee';
  exception when invalid_parameter_value then null;
  end;

  -- 3. Pas d'ecriture directe.
  begin
    update public.student_profiles set accent_key = 'sable'
     where profile_id = 'c0c00000-0000-0000-0000-000000000002';
    raise exception 'CP-3: le tuteur ecrit la colonne en direct';
  exception when insufficient_privilege then null;
  end;
end
$tuteur$;

do $enfant$
declare
  n integer;
begin
  perform pg_temp.etre('c0c00000-0000-0000-0000-000000000002', 'student');
  -- 4. L'enfant relit sa couleur seule.
  select count(*) into n from public.accents_profils_du_foyer();
  if n <> 1 then raise exception 'CP-4: l''enfant relit % lignes, 1 attendue', n; end if;
  if (select accent_key from public.accents_profils_du_foyer()) is distinct from 'rose' then
    raise exception 'CP-4: l''enfant ne relit pas sa couleur';
  end if;
  begin
    perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000002', 'sable');
    raise exception 'CP-4: l''enfant choisit sa couleur';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000003', 'sable');
    raise exception 'CP-4: l''enfant choisit la couleur de sa soeur';
  exception when insufficient_privilege then null;
  end;
end
$enfant$;

do $soeur$
declare
  n integer;
begin
  -- 4 bis. La soeur, sans couleur, ne voit pas celle de son frere.
  perform pg_temp.etre('c0c00000-0000-0000-0000-000000000003', 'student');
  select count(*) into n from public.accents_profils_du_foyer();
  if n <> 0 then raise exception 'CP-4: la soeur lit la couleur de son frere'; end if;
end
$soeur$;

do $adulte$
begin
  -- 5. L'adulte autonome choisit la sienne.
  perform pg_temp.etre('c0c00000-0000-0000-0000-000000000004', 'student');
  perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000004', 'lavande');
  if (select accent_key from public.accents_profils_du_foyer()) is distinct from 'lavande' then
    raise exception 'CP-5: l''adulte ne relit pas sa couleur';
  end if;
end
$adulte$;

do $autre$
declare
  n integer;
begin
  -- 6. Un autre foyer.
  perform pg_temp.etre('c0c00000-0000-0000-0000-000000000005', 'guardian');
  select count(*) into n from public.accents_profils_du_foyer();
  if n <> 0 then raise exception 'CP-6: un autre tuteur lit % couleurs', n; end if;
  begin
    perform public.choisir_accent_profil('c0c00000-0000-0000-0000-000000000002', 'peche');
    raise exception 'CP-6: un autre tuteur choisit la couleur d''un enfant';
  exception when insufficient_privilege then null;
  end;
end
$autre$;

reset role;

do $anon$
begin
  -- 7.
  if has_function_privilege('anon', 'public.choisir_accent_profil(uuid, text)', 'EXECUTE')
     or has_function_privilege('anon', 'public.accents_profils_du_foyer()', 'EXECUTE') then
    raise exception 'CP-7: anon execute une fonction de couleur';
  end if;
  if (select accent_key from public.student_profiles
       where profile_id = 'c0c00000-0000-0000-0000-000000000002') is distinct from 'rose' then
    raise exception 'CP: la couleur de l''enfant a ete changee par un appelant refuse';
  end if;
end
$anon$;

rollback;
