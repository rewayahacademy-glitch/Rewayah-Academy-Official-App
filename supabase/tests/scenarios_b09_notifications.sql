-- B-09 : boîte de notifications privée, lecture par destinataire et accusé borné.
-- À exécuter uniquement sur une base PostgreSQL jetable après les migrations.
begin;

insert into auth.users (id, email) values
  ('b0900000-0000-0000-0000-000000000001', 'b09-recipient-a@example.test'),
  ('b0900000-0000-0000-0000-000000000002', 'b09-recipient-b@example.test'),
  ('b0900000-0000-0000-0000-000000000003', 'b09-student-child@example.test'),
  ('b0900000-0000-0000-0000-000000000004', 'b09-student-adult@example.test');

insert into public.households (id, timezone)
values
  ('b09fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('b09fffff-0000-0000-0000-000000000002', 'Europe/London');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b0900000-0000-0000-0000-000000000001', 'B09RECIPIENTA01', 'guardian',
   'b09fffff-0000-0000-0000-000000000001', 'Recipient', 'A', 'provisional_active'),
  ('b0900000-0000-0000-0000-000000000002', 'B09RECIPIENTB01', 'guardian',
   'b09fffff-0000-0000-0000-000000000002', 'Recipient', 'B', 'active'),
  ('b0900000-0000-0000-0000-000000000003', 'B09STUDENTCHILD01', 'student',
   'b09fffff-0000-0000-0000-000000000001', 'Student', 'Child', 'active'),
  ('b0900000-0000-0000-0000-000000000004', 'B09STUDENTADULT01', 'student',
   'b09fffff-0000-0000-0000-000000000002', 'Student', 'Adult', 'active');

update public.households
   set primary_guardian_id = 'b0900000-0000-0000-0000-000000000001'
 where id = 'b09fffff-0000-0000-0000-000000000001';

insert into public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours,
   heures_locales, source)
values
  ('b09fffff-0000-0000-0000-000000000004',
   'b0900000-0000-0000-0000-000000000003',
   'enfant', 'francais', 'Europe/Paris', ARRAY[2,4]::smallint[],
   ARRAY[18,20]::smallint[], 'personnalisee'),
  ('b09fffff-0000-0000-0000-000000000005',
   'b0900000-0000-0000-0000-000000000004',
   'adulte', 'francais', 'Europe/Paris', ARRAY[2,4]::smallint[],
   ARRAY[18,20]::smallint[], 'personnalisee');

update public.demandes_horaires_famille
   set etat = 'refusee'
 where id = 'b09fffff-0000-0000-0000-000000000004';

-- Une nouvelle demande du meme eleve peut etre envoyee apres la cloture
-- precedente; son retrait familial doit lui aussi notifier le tuteur.
insert into public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours,
   heures_locales, source)
values
  ('b09fffff-0000-0000-0000-000000000006',
   'b0900000-0000-0000-0000-000000000003',
   'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[],
   ARRAY[19]::smallint[], 'personnalisee');

update public.demandes_horaires_famille
   set etat = 'retiree', motif = 'retrait_famille'
 where id = 'b09fffff-0000-0000-0000-000000000006';

insert into public.notifications
  (id, destinataire, foyer_id, evenement, params, destination)
values
  ('b09fffff-0000-0000-0000-000000000002',
   'b0900000-0000-0000-0000-000000000001',
   'b09fffff-0000-0000-0000-000000000001',
   'demande_recue', '{}', '/tuteur/demandes'),
  ('b09fffff-0000-0000-0000-000000000003',
   'b0900000-0000-0000-0000-000000000002',
   'b09fffff-0000-0000-0000-000000000002',
   'classe_validee', '{}', '/tuteur/demandes');

set local role authenticated;
select set_config('test.uid', 'b0900000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b09fffff-0000-0000-0000-000000000001"}}',
  true);

do $b09_recipient_only$
declare
  v_count integer;
begin
  if not pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'SELECT')
     or pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'INSERT')
     or pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'DELETE')
     or not pg_catalog.has_column_privilege(
       'authenticated', 'public.notifications', 'lu_le', 'UPDATE')
     or pg_catalog.has_column_privilege(
       'authenticated', 'public.notifications', 'params', 'UPDATE')
     or pg_catalog.has_table_privilege('anon', 'public.notifications', 'SELECT')
     or pg_catalog.has_table_privilege('service_role', 'public.notifications', 'SELECT')
     or pg_catalog.has_table_privilege('service_role', 'public.notifications', 'INSERT')
     or pg_catalog.has_table_privilege('service_role', 'public.notifications', 'UPDATE')
     or pg_catalog.has_table_privilege('service_role', 'public.notifications', 'DELETE')
     or pg_catalog.has_table_privilege('agent_ro', 'public.notifications', 'SELECT')
     or pg_catalog.has_function_privilege(
       'authenticated', 'public.notifications_accuse_serveur()', 'EXECUTE')
     or pg_catalog.has_function_privilege(
       'service_role', 'public.notifications_accuse_serveur()', 'EXECUTE')
     or pg_catalog.has_function_privilege(
       'authenticated', 'public.tc_notification_demande_horaire_famille()', 'EXECUTE')
     or pg_catalog.has_function_privilege(
       'service_role', 'public.tc_notification_demande_horaire_famille()', 'EXECUTE')
     or (
       select count(*)
         from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname in (
            'notifications_accuse_serveur',
            'tc_notification_demande_horaire_famille',
            'tc_demandes_horaires_enseignant_affecte'
          )
          and p.prorettype = 'trigger'::pg_catalog.regtype
          and not p.prosecdef
          and p.proconfig @> array['search_path=""']
     ) <> 3 then
    raise exception 'B-09: table or trigger function privileges do not match the contract';
  end if;

  select count(*) into v_count from public.notifications;
  if v_count <> 5 then
    raise exception 'B-09: recipient must see only their own notification';
  end if;
  if not exists (
    select 1 from public.notifications
     where id <> 'b09fffff-0000-0000-0000-000000000002'
       and destinataire = auth.uid()
       and foyer_id = 'b09fffff-0000-0000-0000-000000000001'
       and evenement = 'demande_recue'
       and params = '{"etat":"envoyee"}'::jsonb
       and destination = '/tuteur/demandes'
  ) then
    raise exception 'B-09: child request notification missing or not recipient-scoped';
  end if;
  if not exists (
    select 1 from public.notifications
     where destinataire = auth.uid()
       and foyer_id = 'b09fffff-0000-0000-0000-000000000001'
       and evenement = 'demande_close'
       and params = '{"etat":"refusee"}'::jsonb
       and destination = '/tuteur/demandes'
  ) then
    raise exception 'B-09: refusal notification missing or not recipient-scoped';
  end if;
  if not exists (
    select 1 from public.notifications
     where destinataire = auth.uid()
       and foyer_id = 'b09fffff-0000-0000-0000-000000000001'
       and evenement = 'demande_close'
       and params = '{"etat":"retiree"}'::jsonb
       and destination = '/tuteur/demandes'
  ) then
    raise exception 'B-09: family withdrawal notification missing or not recipient-scoped';
  end if;

  update public.notifications set lu_le = '2000-01-01T00:00:00Z'
   where id = 'b09fffff-0000-0000-0000-000000000003';
  if found then
    raise exception 'B-09: a recipient updated another profile notification';
  end if;

  update public.notifications set lu_le = '2000-01-01T00:00:00Z'
   where id = 'b09fffff-0000-0000-0000-000000000099';
  if found then
    raise exception 'B-09: a recipient updated an unknown notification';
  end if;

  update public.notifications set lu_le = '2000-01-01T00:00:00Z'
   where id = 'b09fffff-0000-0000-0000-000000000002';

  begin
    update public.notifications set params = '{"changed":true}'
     where id = 'b09fffff-0000-0000-0000-000000000002';
    raise exception 'B-09: client changed notification content';
  exception when insufficient_privilege then
    null;
  end;

  begin
    delete from public.notifications
     where id = 'b09fffff-0000-0000-0000-000000000002';
    raise exception 'B-09: client delete was accepted';
  exception when insufficient_privilege then
    null;
  end;

  update public.notifications set lu_le = '2099-01-01T00:00:00Z'
   where id = 'b09fffff-0000-0000-0000-000000000002';
end
$b09_recipient_only$;

reset role;
do $b09_read_marker$
declare
  v_read_at timestamptz;
  v_other_read_at timestamptz;
  v_request_notifications integer;
  v_close_notifications integer;
begin
  select lu_le into v_read_at from public.notifications
   where id = 'b09fffff-0000-0000-0000-000000000002';
  select lu_le into v_other_read_at from public.notifications
   where id = 'b09fffff-0000-0000-0000-000000000003';
  select count(*) into v_request_notifications from public.notifications
   where evenement = 'demande_recue'
     and params ->> 'etat' = 'envoyee';
  select count(*) into v_close_notifications from public.notifications
   where evenement = 'demande_close';
  if v_read_at is null or v_other_read_at is not null then
    raise exception 'B-09: read acknowledgement changed the wrong row';
  end if;
  if v_read_at >= '2099-01-01T00:00:00Z'::timestamptz then
    raise exception 'B-09: client controlled the server read timestamp';
  end if;
  if v_request_notifications <> 2 OR v_close_notifications <> 2 then
    raise exception 'B-09: adult requests must not create guardian notifications';
  end if;
end
$b09_read_marker$;

set local role anon;
do $b09_anonymous_denied$
begin
  begin
    perform 1 from public.notifications;
    raise exception 'B-09: anonymous reads were accepted';
  exception when insufficient_privilege then
    null;
  end;

end
$b09_anonymous_denied$;

reset role;
rollback;
