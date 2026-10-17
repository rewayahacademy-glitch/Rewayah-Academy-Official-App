-- Retire la population de test du STAGING créée par staging_population_test.sql.
delete from public.session_participants where session_id in (select id from public.sessions where groupe_id::text like 'e5500000-%');
delete from public.sessions where groupe_id::text like 'e5500000-%';
delete from public.groupes where id::text like 'e5500000-%';
delete from auth.users where email like '%@sim.rewayah.invalid';
delete from public.households where id::text like 'e5400000-%';
