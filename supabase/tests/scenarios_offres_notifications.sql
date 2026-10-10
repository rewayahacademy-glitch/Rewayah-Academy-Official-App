-- B-09 / OFFRES-DIR-I16 : creation et fermeture de demande notifient le foyer sans donnees tierces.
begin;

insert into auth.users (id, email) values
  ('f1660000-0000-0000-0000-000000000001', 'notif-guardian@example.test'),
  ('f1660000-0000-0000-0000-000000000002', 'notif-student@example.test');
insert into public.households (id, timezone)
values ('f16fffff-0000-0000-0000-000000000011', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('f1660000-0000-0000-0000-000000000001', 'F1NOTIFGUARDIAN', 'guardian',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Guardian', 'active'),
  ('f1660000-0000-0000-0000-000000000002', 'F1NOTIFSTUDENT', 'student',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Student', 'active');

update public.households
set primary_guardian_id = 'f1660000-0000-0000-0000-000000000001'
where id = 'f16fffff-0000-0000-0000-000000000011';

do $notification$
declare
  v_langue text;
  v_id uuid;
  v_received integer;
  v_closed integer;
  v_other_data boolean;
begin
  select code into v_langue from public.langues_cours where actif order by code limit 1;
  if v_langue is null then
    raise exception 'B-09: fixture requires at least one active course language';
  end if;

  insert into public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source)
  values ('f1660000-0000-0000-0000-000000000002', 'enfant', v_langue,
          'Europe/Paris', array[1]::smallint[], array[10]::smallint[], 'personnalisee')
  returning id into v_id;

  select count(*) into v_received from public.notifications
  where destinataire = 'f1660000-0000-0000-0000-000000000001'
    and evenement = 'demande_recue'
    and params ->> 'demande_id' = v_id::text;
  if v_received <> 1 then
    raise exception 'B-09: une demande doit produire une seule notification foyer';
  end if;
  select exists (
    select 1 from public.notifications
    where params ? 'eleve_id' or params ? 'foyer_id' or params ? 'autre_demandeur'
  ) into v_other_data;
  if v_other_data then
    raise exception 'B-09: notification contient des identifiants de tiers';
  end if;

  update public.demandes_horaires_famille
     set etat = 'refusee', motif = 'fixture'
   where id = v_id;
  select count(*) into v_closed from public.notifications
  where destinataire = 'f1660000-0000-0000-0000-000000000001'
    and evenement = 'demande_close'
    and params ->> 'demande_id' = v_id::text;
  if v_closed <> 1 then
    raise exception 'B-09: fermeture doit notifier le foyer une seule fois';
  end if;
end
$notification$;

reset role;
rollback;
