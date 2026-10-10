-- B-09 / OFFRES-DIR-I16 : creation et fermeture de demande notifient le foyer sans donnees tierces.
begin;

insert into auth.users (id, email) values
  ('f1660000-0000-0000-0000-000000000001', 'notif-guardian@example.test'),
  ('f1660000-0000-0000-0000-000000000002', 'notif-student@example.test'),
  ('f1660000-0000-0000-0000-000000000003', 'notif-teacher@example.test'),
  ('f1660000-0000-0000-0000-000000000004', 'notif-admin@example.test'),
  ('f1660000-0000-0000-0000-000000000005', 'notif-adult@example.test');
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
   null, 'Fixture', 'Admin', 'active'),
  ('f1660000-0000-0000-0000-000000000005', 'F1NOTIFADULT', 'student',
   'f16fffff-0000-0000-0000-000000000011', 'Fixture', 'Adult', 'active');

update public.households
set primary_guardian_id = 'f1660000-0000-0000-0000-000000000001'
where id = 'f16fffff-0000-0000-0000-000000000011';

do $notification$
declare
  v_langue text;
  v_cohorte text;
  v_cohorte_adulte text;
  v_admin jsonb;
  v_demande_adulte uuid;
  v_id uuid;
  v_received integer;
  v_closed integer;
  v_other_data boolean;
  v_group_id uuid := 'f16fffff-0000-0000-0000-000000000012';
  v_class_request uuid;
  v_rejected_request uuid;
  v_suivi record;
begin
  select code into v_langue from public.langues_cours where actif order by code limit 1;
  select code into v_cohorte
  from public.cohortes_age
  where actif and type_public = 'enfant'
  order by ordre, code
  limit 1;
  select code into v_cohorte_adulte
  from public.cohortes_age
  where actif and type_public = 'adulte'
  order by ordre, code
  limit 1;
  if v_langue is null or v_cohorte is null or v_cohorte_adulte is null then
    raise exception 'B-09: fixture requires an active language and child cohort';
  end if;

  insert into public.student_profiles (profile_id, langue_cours, cohorte)
  values (
    'f1660000-0000-0000-0000-000000000002',
    v_langue,
    v_cohorte
  );
  insert into public.student_profiles
    (profile_id, student_type, interface_mode, langue_cours, cohorte)
  values (
    'f1660000-0000-0000-0000-000000000005',
    'autonomous', 'standard', v_langue, v_cohorte_adulte
  );

  -- C-04/C-07 : l'enseignant de fixture est complet et disponible pour
  -- l'occurrence du groupe affecté plus bas.
  insert into public.teacher_profiles
    (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
  values
    ('f1660000-0000-0000-0000-000000000003', array[v_langue], 40, 'approved', 'Europe/Paris');
  insert into public.weekly_availability
    (profile_id, weekday, hour_local, timezone_iana)
  values
    ('f1660000-0000-0000-0000-000000000003', 2, 11, 'Europe/Paris');

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

  insert into public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source)
  values (
    'f1660000-0000-0000-0000-000000000005', 'adulte', v_langue,
    'Europe/Paris', array[2]::smallint[], array[18]::smallint[], 'personnalisee'
  )
  returning id into v_demande_adulte;
  if (select count(*) from public.notifications
      where params ->> 'demande_id' = v_demande_adulte::text
        and evenement = 'demande_recue'
        and destinataire in (
          'f1660000-0000-0000-0000-000000000001',
          'f1660000-0000-0000-0000-000000000005'
        )) <> 2 then
    raise exception 'M6: demande adulte autonome non notifiée au foyer et à son titulaire';
  end if;

  update public.demandes_horaires_famille
     set etat = 'refusee', motif = 'refus_direction'
   where id = v_demande_adulte;
  if (select count(*) from public.notifications
      where params ->> 'demande_id' = v_demande_adulte::text
        and evenement = 'demande_close'
        and params ->> 'motif' = 'refus_direction'
        and destinataire in (
          'f1660000-0000-0000-0000-000000000001',
          'f1660000-0000-0000-0000-000000000005'
        )) <> 2 then
    raise exception 'M6: clôture adulte sans code de motif aux deux destinataires';
  end if;

  perform set_config('request.jwt.claim.sub',
    'f1660000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'f1660000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object(
      'role', 'guardian',
      'household_id', 'f16fffff-0000-0000-0000-000000000011'
    )
  )::text, true);
  select * into v_suivi
  from public.suivi_demandes_horaires_foyer()
  where demande_id = v_id;
  if not found
     or v_suivi.eleve_id <> 'f1660000-0000-0000-0000-000000000002'
     or v_suivi.etape <> 'envoyee'
     or v_suivi.fuseau_iana <> 'Europe/Paris'
     or jsonb_array_length(v_suivi.occurrences) <> 1
     or v_suivi.enseignant is not null
     or v_suivi.debut_cours is not null then
    raise exception 'M6: suivi foyer incomplet ou divulguant une donnée prématurée';
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

  select * into v_suivi
  from public.suivi_demandes_horaires_foyer()
  where demande_id = v_id;
  if not found
     or v_suivi.etape <> 'close'
     or v_suivi.motif is not null
     or not v_suivi.peut_choisir_autre_creneau then
    raise exception 'M6: fermeture non typée ou capacité de reprise incorrecte';
  end if;
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

  insert into public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
     source)
  values (
    'f1660000-0000-0000-0000-000000000005', 'adulte', v_langue,
    'Europe/Paris', array[2]::smallint[], array[18]::smallint[], 'personnalisee'
  )
  returning id into v_demande_adulte;
  update public.demandes_horaires_famille
     set etat = 'classe_validee', groupe_id = v_group_id
   where id = v_demande_adulte;
  if (select count(*) from public.notifications
      where destinataire = 'f1660000-0000-0000-0000-000000000005'
        and evenement = 'classe_validee'
        and params ->> 'groupe_id' = v_group_id::text) <> 1 then
    raise exception 'M6: classe validée non notifiée au titulaire adulte autonome';
  end if;

  update public.demandes_horaires_famille
     set etat = 'enseignant_affecte'
   where id = v_demande_adulte;
  if not exists (
    select 1 from public.notifications
    where destinataire = 'f1660000-0000-0000-0000-000000000005'
      and evenement = 'enseignant_affecte'
      and params ->> 'groupe_id' = v_group_id::text
      and coalesce(params ->> 'debut_local', '') <> ''
  ) then
    raise exception 'M6: enseignant affecté ou première séance future non notifiée au titulaire';
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

  select ligne into v_admin
  from public.regroupements_c11bis_admin() AS projection(ligne)
  where ligne ->> 'type_public' = 'enfant'
    and ligne ->> 'langue_code' = v_langue
    and jsonb_array_length(ligne -> 'occurrences') = 1;
  if v_admin is null
     or v_admin ->> 'langue_nom' is null
     or v_admin ->> 'fuseau_iana' <> 'Europe/Paris'
     or (v_admin ->> 'nombre_eleves')::integer <> 1
     or jsonb_array_length(v_admin -> 'autres_fuseaux') <> 0
     or v_admin ? 'eleve_id' then
    raise exception 'M6: projection admin incomplète ou divulgatrice: %', v_admin;
  end if;

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
