-- B-09 / OFFRES-DIR-I16 : creation et fermeture de demande notifient le foyer sans donnees tierces.
begin;

insert into auth.users (id, email) values
  ('f1660000-0000-0000-0000-000000000001', 'notif-guardian@example.test'),
  ('f1660000-0000-0000-0000-000000000002', 'notif-student@example.test'),
  ('f1660000-0000-0000-0000-000000000003', 'notif-teacher@example.test'),
  ('f1660000-0000-0000-0000-000000000004', 'notif-admin@example.test');
insert into public.households (id, timezone)
values ('f16fffff-0000-0000-0000-000000000011', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('f1660000-0000-0000-0000-000000000001', 'F1NOTIFGUARDIAN', 'guardian',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Guardian', 'active'),
  ('f1660000-0000-0000-0000-000000000002', 'F1NOTIFSTUDENT', 'student',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Student', 'active'),
  ('f1660000-0000-0000-0000-000000000003', 'F1NOTIFTEACHER', 'teacher',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Teacher', 'active'),
  ('f1660000-0000-0000-0000-000000000004', 'F1NOTIFADMIN', 'admin',
   null, 'Fixture', 'Admin', 'active');

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
  v_group_id uuid := 'f16fffff-0000-0000-0000-000000000012';
  v_class_request uuid;
  v_rejected_request uuid;
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

  -- Une demande classe_validee suit le groupe : l'affectation doit faire
  -- progresser la demande en meme transaction.
  insert into public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local)
  values (v_group_id, null, 'en_attente_enseignant', 'enfant', 5,
          'Notification fixture', 2, 11);
  insert into public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
     source, etat, groupe_id)
  values ('f1660000-0000-0000-0000-000000000002', 'enfant', v_langue,
          'Europe/Paris', array[2]::smallint[], array[11]::smallint[],
          'personnalisee', 'envoyee', null)
  returning id into v_class_request;

  insert into public.groupe_membres (groupe_id, student_id)
  values (v_group_id, 'f1660000-0000-0000-0000-000000000002');

  update public.demandes_horaires_famille
     set etat = 'classe_validee', groupe_id = v_group_id
   where id = v_class_request;

  update public.groupes
     set teacher_id = 'f1660000-0000-0000-0000-000000000003',
         etat = 'active'
   where id = v_group_id;

  if (select etat from public.demandes_horaires_famille
      where id = v_class_request) <> 'enseignant_affecte' then
    raise exception 'B-09: affectation du groupe ne fait pas progresser la demande';
  end if;

  perform set_config('request.jwt.claim.sub', 'f1660000-0000-0000-0000-000000000004', true);
  perform set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  perform public.retirer_eleve_groupe(
    v_group_id, 'f1660000-0000-0000-0000-000000000002', 'fixture retrait'
  );
  if not exists (
    select 1 from public.demandes_horaires_famille
    where id = v_class_request and etat = 'refusee' and motif = 'refus_direction'
  ) then
    raise exception 'M5: retirer un membre laisse la demande de classe active';
  end if;
  if (select count(*) from public.notifications
      where destinataire = 'f1660000-0000-0000-0000-000000000001'
        and evenement = 'demande_close'
        and params ->> 'demande_id' = v_class_request::text) <> 1 then
    raise exception 'M5: le retrait du membre ne notifie pas son foyer';
  end if;

  insert into public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
     source)
  values ('f1660000-0000-0000-0000-000000000002', 'enfant', v_langue,
          'Europe/Paris', array[3]::smallint[], array[11]::smallint[],
          'personnalisee')
  returning id into v_rejected_request;
  perform public.refuser_demande_horaire(v_rejected_request, 'refus_direction');
  if not exists (
    select 1 from public.demandes_horaires_famille
    where id = v_rejected_request and etat = 'refusee' and motif = 'refus_direction'
  ) then
    raise exception 'M5: la RPC de refus ne ferme pas la demande avec son motif';
  end if;
  if (select count(*) from public.notifications
      where destinataire = 'f1660000-0000-0000-0000-000000000001'
        and evenement = 'demande_close'
        and params ->> 'demande_id' = v_rejected_request::text) <> 1 then
    raise exception 'M5: le refus ne notifie pas le foyer';
  end if;
end
$notification$;

reset role;
rollback;
