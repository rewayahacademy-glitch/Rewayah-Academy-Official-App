-- IMM-BACK-1 A: synthetic RA format, uniqueness and collision retry cases.
begin;

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
begin
  update pg_temp.imm_back_1_draws
     set attempts = attempts + 1
   returning attempts into v_attempt;
  if p_width = 5 then return 45678; end if;
  return case when v_attempt = 1 then 1234
              when v_attempt = 2 then 5678 else 8765 end;
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

rollback;
