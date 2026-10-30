-- B2.1 (30/10/2026) : apres la confirmation de l'import des inscrits actuels,
-- chaque pre-inscription devient un foyer et des matricules RA reserves ; la
-- reclamation apres preuve de l'e-mail donne au tuteur (ou a l'adulte eleve)
-- son profil et son matricule ; le profil d'un enfant cree ensuite reprend le
-- sien. Donnees inventees, adresses en example.test.
-- A rejouer apres stub_auth.sql et toutes les migrations, sur un Postgres jetable.
begin;

-- Fixtures : une direction, et une famille C deja presente dans l'app.
insert into auth.users (id, email, email_confirmed_at) values
  ('b2100000-0000-0000-0000-0000000000ad', 'b21-direction@example.test', now()),
  ('b2100000-0000-0000-0000-0000000000c1', 'famille-c@example.test', now()),
  ('b2100000-0000-0000-0000-0000000000c2', null, null);
insert into public.households (id, timezone) values
  ('b21fffff-ffff-ffff-ffff-0000000000ad', 'Europe/Paris'),
  ('b21fffff-ffff-ffff-ffff-0000000000c0', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b2100000-0000-0000-0000-0000000000ad', 'B21-FIXTURE-ADM', 'admin',
   'b21fffff-ffff-ffff-ffff-0000000000ad', 'Direction', 'Fixture', 'active'),
  ('b2100000-0000-0000-0000-0000000000c1', 'B21-FIXTURE-C1', 'guardian',
   'b21fffff-ffff-ffff-ffff-0000000000c0', 'Claire', 'FamilleC', 'active'),
  ('b2100000-0000-0000-0000-0000000000c2', 'B21-FIXTURE-C2', 'student',
   'b21fffff-ffff-ffff-ffff-0000000000c0', 'Sami', 'FamilleC', 'active');
update public.households set primary_guardian_id = 'b2100000-0000-0000-0000-0000000000c1'
 where id = 'b21fffff-ffff-ffff-ffff-0000000000c0';

create temporary table b21_avant on commit drop as
select (select count(*) from public.households) as foyers,
       (select count(*) from public.profiles) as profils,
       (select count(*) from private.person_registrations) as registre,
       (select count(*) from private.preinscription_households) as pre_foyers,
       (select count(*) from private.preinscription_persons) as pre_personnes;
grant all on b21_avant to authenticated;

create temporary table b21_csv on commit drop as select
  E'Email,Email du tuteur,Nom,Prénom,Date de naissance,Nom de l\'élève 1,Prénom de l\'élève 1,Date de naissance de l\'élève 1,Nom de l\'élève 2,Prénom de l\'élève 2,Date de naissance de l\'élève 2,Pour qui faites-vous cette inscription ?\r\n'
  || E'famille-a@example.test,famille-a@example.test,ParentA,Hind,01/01/1985,ChildA,Lina,02/02/2015,ChildA,Adam,03/03/2017,Pour mon enfant\r\n'
  || E'adulte-b@example.test,,AdulteB,Bilal,04/04/1990,,,,,,,Pour moi\r\n'
  || E'famille-c@example.test,famille-c@example.test,FamilleC,Claire,05/05/1982,FamilleC,Sami,06/06/2014,FamilleC,Yara,07/07/2016,Pour mon enfant\r\n'
  as eleves,
  E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Tarek,EnseignantT,enseignant-t@example.test\r\n'
  as enseignants;
grant select on b21_csv to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', 'b2100000-0000-0000-0000-0000000000ad', true);
select set_config('request.jwt.claims',
  '{"sub":"b2100000-0000-0000-0000-0000000000ad","role":"authenticated","app_metadata":{"role":"admin"}}', true);

-- 1. L'essai a blanc n'ecrit rien.
do $essai$
declare v_apercu jsonb;
begin
  v_apercu := public.previsualiser_import_inscriptions(
    (select eleves from b21_csv), (select enseignants from b21_csv));
  if v_apercu->>'ecriture_effectuee' <> 'false' or v_apercu->>'foyers' <> '3' then
    raise exception 'B2.1-1 : apercu inattendu %', v_apercu;
  end if;
end;
$essai$;
reset role;
do $essai_rien$
begin
  if (select count(*) from public.households) <> (select foyers from b21_avant)
     or (select count(*) from private.person_registrations) <> (select registre from b21_avant)
     or (select count(*) from private.preinscription_households) <> (select pre_foyers from b21_avant) then
    raise exception 'B2.1-1 : l''essai a blanc a ecrit';
  end if;
end;
$essai_rien$;

-- 2. Confirmer, puis confirmer encore : rien de plus la seconde fois.
set local role authenticated;
do $confirmer$
declare v_r jsonb;
begin
  v_r := public.confirmer_import_inscriptions(
    (select eleves from b21_csv), (select enseignants from b21_csv), '[]'::jsonb);
  if v_r->>'foyers_traites' <> '4' or v_r->>'personnes_creees' <> '8' then
    raise exception 'B2.1-2 : confirmation inattendue %', v_r;
  end if;
end;
$confirmer$;
reset role;

do $apres_confirmation$
declare
  v_a uuid; v_b uuid; v_c uuid; v_t uuid;
  v_audit jsonb;
  v_annee text := pg_catalog.to_char(pg_catalog.now() at time zone 'UTC', 'YY');
begin
  select household_id into v_a from private.preinscription_households where email_normalise = 'famille-a@example.test';
  select household_id into v_b from private.preinscription_households where email_normalise = 'adulte-b@example.test';
  select household_id into v_c from private.preinscription_households where email_normalise = 'famille-c@example.test';
  select household_id into v_t from private.preinscription_households where email_normalise = 'enseignant-t@example.test';
  if v_a is null or v_b is null or v_a = v_b then
    raise exception 'B2.1-2 : foyers A et B absents';
  end if;
  if v_c is distinct from 'b21fffff-ffff-ffff-ffff-0000000000c0'::uuid then
    raise exception 'B2.1-2 : la famille C deja presente n''a pas retrouve son foyer';
  end if;
  if v_t is not null then
    raise exception 'B2.1-2 : un enseignant a recu un foyer';
  end if;
  if (select count(*) from public.households) <> (select foyers from b21_avant) + 2
     or (select count(*) from public.profiles) <> (select profils from b21_avant) then
    raise exception 'B2.1-2 : nombre de foyers ou de profils inattendu';
  end if;
  if exists (select 1 from public.households where id in (v_a, v_b) and primary_guardian_id is not null) then
    raise exception 'B2.1-2 : un foyer importe a un tuteur avant la reclamation';
  end if;
  -- Reserves : Hind, Lina, Adam (A), Bilal (B), Yara (C). Reconnus : Claire, Sami.
  if (select count(*) from private.person_registrations r
        join private.preinscription_persons p on p.id = r.profile_id) <> 5
     or (select count(*) from private.person_registrations) <> (select registre from b21_avant) + 5 then
    raise exception 'B2.1-2 : 5 matricules reserves attendus';
  end if;
  if exists (select 1 from private.person_registrations r
               join private.preinscription_persons p on p.id = r.profile_id
              where r.matricule !~ ('^RA-' || v_annee || '-[0-9]{4,5}$')) then
    raise exception 'B2.1-2 : un matricule ne suit pas la regle RA-AA-NNNN de l''annee du serveur';
  end if;
  if exists (select 1 from private.preinscription_persons p
              join private.person_registrations r on r.profile_id = p.id
             where p.person_kind = 'teacher') then
    raise exception 'B2.1-2 : un enseignant a recu un matricule';
  end if;
  if (select profile_id from private.preinscription_persons where first_name = 'Sami')
       is distinct from 'b2100000-0000-0000-0000-0000000000c2'::uuid
     or (select profile_id from private.preinscription_persons where first_name = 'Claire')
       is distinct from 'b2100000-0000-0000-0000-0000000000c1'::uuid
     or exists (select 1 from private.person_registrations r
                  join private.preinscription_persons p on p.id = r.profile_id
                 where p.first_name in ('Sami', 'Claire')) then
    raise exception 'B2.1-2 : l''eleve ou le tuteur deja present a ete double';
  end if;
  select payload into v_audit from public.audit_logs
   where action = 'preinscription_foyers_realises' order by created_at desc, id desc limit 1;
  if v_audit is null or v_audit->>'foyers_crees' <> '2' or v_audit->>'matricules_reserves' <> '5'
     or v_audit->>'personnes_reconnues' <> '2'
     or v_audit::text ~ '(Hind|Lina|example\.test|RA-)' then
    raise exception 'B2.1-2 : journal absent ou avec des donnees personnelles %', v_audit;
  end if;
end;
$apres_confirmation$;

create temporary table b21_apres on commit drop as
select (select count(*) from public.households) as foyers,
       (select count(*) from private.person_registrations) as registre,
       (select count(*) from public.profiles) as profils;

set local role authenticated;
do $rejouer$
declare v_r jsonb;
begin
  v_r := public.confirmer_import_inscriptions(
    (select eleves from b21_csv), (select enseignants from b21_csv), '[]'::jsonb);
  if v_r->>'foyers_crees' <> '0' or v_r->>'personnes_creees' <> '0' then
    raise exception 'B2.1-2 : rejeu de la confirmation inattendu %', v_r;
  end if;
end;
$rejouer$;
reset role;
do $rejeu_rien$
begin
  if (select count(*) from public.households) <> (select foyers from b21_apres)
     or (select count(*) from private.person_registrations) <> (select registre from b21_apres)
     or (select count(*) from public.profiles) <> (select profils from b21_apres) then
    raise exception 'B2.1-2 : confirmer deux fois a cree quelque chose';
  end if;
  if (select payload->>'matricules_reserves' from public.audit_logs
       where action = 'preinscription_foyers_realises' order by created_at desc, id desc limit 1) <> '0' then
    raise exception 'B2.1-2 : le rejeu a reserve des matricules';
  end if;
end;
$rejeu_rien$;

-- 3. Le tuteur A reclame apres preuve : profil actif, son matricule reserve.
create temporary table b21_reserves on commit drop as
select p.first_name, r.matricule from private.preinscription_persons p
  join private.person_registrations r on r.profile_id = p.id;
insert into auth.users (id, email, email_confirmed_at) values
  ('b2100000-0000-0000-0000-0000000000a1', 'famille-a@example.test', now()),
  ('b2100000-0000-0000-0000-0000000000b1', 'adulte-b@example.test', now());

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b2100000-0000-0000-0000-0000000000a1', true);
select set_config('request.jwt.claims',
  '{"sub":"b2100000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
do $reclamer_a$
declare v_r jsonb;
begin
  v_r := public.reclamer_preinscription_apres_preuve();
  if v_r->>'inscription_connue' <> 'true' or jsonb_array_length(v_r->'personnes') <> 3 then
    raise exception 'B2.1-3 : reclamation inattendue %', v_r;
  end if;
  v_r := public.reclamer_preinscription_apres_preuve();
  if v_r->>'inscription_connue' <> 'true' or v_r->>'message_accueil' is not null then
    raise exception 'B2.1-3 : rejeu de la reclamation inattendu';
  end if;
end;
$reclamer_a$;
reset role;

do $profil_a$
declare v_p public.profiles%rowtype; v_foyer uuid;
begin
  select household_id into v_foyer from private.preinscription_households
   where email_normalise = 'famille-a@example.test';
  select * into v_p from public.profiles where id = 'b2100000-0000-0000-0000-0000000000a1';
  if v_p.id is null or v_p.role <> 'guardian' or v_p.account_status <> 'active'
     or v_p.household_id <> v_foyer or v_p.first_name <> 'Hind' then
    raise exception 'B2.1-3 : profil du tuteur absent ou faux';
  end if;
  if v_p.immutable_id <> (select matricule from b21_reserves where first_name = 'Hind') then
    raise exception 'B2.1-3 : le tuteur n''a pas recu son matricule reserve';
  end if;
  if (select primary_guardian_id from public.households where id = v_foyer)
       is distinct from v_p.id then
    raise exception 'B2.1-3 : le tuteur n''est pas tuteur principal';
  end if;
  if (select count(*) from public.profiles) <> (select profils from b21_apres) + 1
     or (select count(*) from private.person_registrations) <> (select registre from b21_apres) then
    raise exception 'B2.1-3 : reclamer deux fois a cree plus d''un profil ou un matricule neuf';
  end if;
end;
$profil_a$;

-- 4. Le tuteur cree Lina (effet de la fonction Edge creer-profil-enfant) :
-- elle reprend son matricule ; un enfant non importe en recoit un neuf.
insert into auth.users (id, email) values
  ('b2100000-0000-0000-0000-0000000000a2', 'eleve-a2@eleves.example.test'),
  ('b2100000-0000-0000-0000-0000000000a3', 'eleve-a3@eleves.example.test');
insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
select 'b2100000-0000-0000-0000-0000000000a2', null, 'student', household_id, ' lina ', 'CHILDA', 'active'
  from private.preinscription_households where email_normalise = 'famille-a@example.test';
insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
select 'b2100000-0000-0000-0000-0000000000a3', null, 'student', household_id, 'Zed', 'ChildA', 'active'
  from private.preinscription_households where email_normalise = 'famille-a@example.test';
do $enfants$
begin
  if (select immutable_id from public.profiles where id = 'b2100000-0000-0000-0000-0000000000a2')
       <> (select matricule from b21_reserves where first_name = 'Lina') then
    raise exception 'B2.1-4 : Lina n''a pas repris son matricule reserve';
  end if;
  if (select profile_id from private.preinscription_persons where first_name = 'Lina')
       is distinct from 'b2100000-0000-0000-0000-0000000000a2'::uuid then
    raise exception 'B2.1-4 : la personne importee n''est pas reliee au profil de Lina';
  end if;
  if (select immutable_id from public.profiles where id = 'b2100000-0000-0000-0000-0000000000a3')
       in (select matricule from b21_reserves) then
    raise exception 'B2.1-4 : un enfant non importe a pris un matricule reserve';
  end if;
  if not exists (select 1 from private.person_registrations r
                   join private.preinscription_persons p on p.id = r.profile_id
                  where p.first_name = 'Adam') then
    raise exception 'B2.1-4 : la reservation d''Adam a disparu';
  end if;
end;
$enfants$;

-- 5. L'adulte B reclame : tuteur et eleve autonome, tranche adulte du serveur.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b2100000-0000-0000-0000-0000000000b1', true);
select set_config('request.jwt.claims',
  '{"sub":"b2100000-0000-0000-0000-0000000000b1","role":"authenticated"}', true);
select public.reclamer_preinscription_apres_preuve() is not null;
reset role;
do $adulte$
begin
  if (select immutable_id from public.profiles where id = 'b2100000-0000-0000-0000-0000000000b1')
       is distinct from (select matricule from b21_reserves where first_name = 'Bilal') then
    raise exception 'B2.1-5 : l''adulte n''a pas son profil et son matricule reserve';
  end if;
  if not exists (
    select 1 from public.student_profiles sp
     where sp.profile_id = 'b2100000-0000-0000-0000-0000000000b1'
       and sp.titulaire_profile_id = sp.profile_id and sp.student_type = 'autonomous'
       and sp.cohorte is not distinct from (select c.code from public.cohortes_age c
                                             where c.actif and c.type_public = 'adulte'
                                             order by c.ordre limit 1)) then
    raise exception 'B2.1-5 : fiche d''eleve autonome absente';
  end if;
end;
$adulte$;

-- 6. Claire (deja tutrice) reclame : rien n'est cree, Yara reste reservee.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b2100000-0000-0000-0000-0000000000c1', true);
select set_config('request.jwt.claims',
  '{"sub":"b2100000-0000-0000-0000-0000000000c1","role":"authenticated","app_metadata":{"role":"guardian"}}', true);
select public.reclamer_preinscription_apres_preuve() is not null;
reset role;
do $famille_c$
begin
  if (select count(*) from public.profiles where household_id = 'b21fffff-ffff-ffff-ffff-0000000000c0') <> 2
     or (select immutable_id from public.profiles where id = 'b2100000-0000-0000-0000-0000000000c1') <> 'B21-FIXTURE-C1' then
    raise exception 'B2.1-6 : la famille deja presente a change';
  end if;
  if not exists (select 1 from private.person_registrations r
                   join private.preinscription_persons p on p.id = r.profile_id
                  where p.first_name = 'Yara') then
    raise exception 'B2.1-6 : la reservation de Yara a disparu';
  end if;
end;
$famille_c$;

-- 7. Confirmer apres les reclamations ne cree toujours rien.
create temporary table b21_fin on commit drop as
select (select count(*) from public.households) as foyers,
       (select count(*) from private.person_registrations) as registre,
       (select count(*) from public.profiles) as profils;
grant select on b21_fin to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b2100000-0000-0000-0000-0000000000ad', true);
select set_config('request.jwt.claims',
  '{"sub":"b2100000-0000-0000-0000-0000000000ad","role":"authenticated","app_metadata":{"role":"admin"}}', true);
select public.confirmer_import_inscriptions(
  (select eleves from b21_csv), (select enseignants from b21_csv), '[]'::jsonb) is not null;
reset role;
do $fin$
begin
  if (select count(*) from public.households) <> (select foyers from b21_fin)
     or (select count(*) from private.person_registrations) <> (select registre from b21_fin)
     or (select count(*) from public.profiles) <> (select profils from b21_fin) then
    raise exception 'B2.1-7 : confirmer apres les reclamations a cree quelque chose';
  end if;
end;
$fin$;

-- 8. Les aides privees ne sont ouvertes a aucun role de l'API.
do $droits$
declare v_role text;
begin
  foreach v_role in array array['anon', 'authenticated', 'service_role'] loop
    if pg_catalog.has_function_privilege(v_role, 'private.b21_realiser_preinscription(uuid,uuid)', 'EXECUTE')
       or pg_catalog.has_function_privilege(v_role, 'private.b21_realiser_import(text[])', 'EXECUTE')
       or pg_catalog.has_function_privilege(v_role, 'private.b21_profil_reprend_matricule()', 'EXECUTE') then
      raise exception 'B2.1-8 : % execute une aide privee', v_role;
    end if;
  end loop;
end;
$droits$;

rollback;
