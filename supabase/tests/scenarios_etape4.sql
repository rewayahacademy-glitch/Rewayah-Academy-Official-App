-- Scenarios d'acceptation SQL de l'etape 4 (section 7 de etape-4-dashboards.md).
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0005, comme le fait la CI.

-- Droits facon Supabase (alter default privileges du projet).
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler la restriction de colonnes posee par 0005
-- sur student_profiles. En production l'ordre est inverse : les droits par
-- defaut sont accordes a la creation de la table, en 0001, et la migration 0005
-- les restreint ensuite. On rejoue donc la restriction ici, sans quoi le
-- scenario 6 mesurerait le harnais et non la migration.
revoke update on public.student_profiles from authenticated;
grant update (interface_mode, camera_policy, avatar_storage_key)
  on public.student_profiles to authenticated;

-- Meme raison pour les trois tables que seules les fonctions ecrivent, et pour
-- la disponibilite qui se pose ou se retire mais ne se deplace pas.
revoke insert, update, delete on public.rule_overrides,
  public.teacher_student_assignments, public.matching_requests
  from authenticated;
revoke update on public.weekly_availability from authenticated;

-- ============================================================
-- Fixtures : deux foyers, deux enseignants, une administration
-- ============================================================

insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'tuteurA@example.test'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'enfantA1@example.test'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'enfantA2@example.test'),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'tuteurB@example.test'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'enfantB1@example.test'),
  ('cccccccc-0000-0000-0000-000000000001', 'enseignant1@example.test'),
  ('cccccccc-0000-0000-0000-000000000002', 'enseignant2@example.test'),
  ('dddddddd-0000-0000-0000-000000000001', 'admin@example.test'),
  ('99999999-0000-0000-0000-000000000001', 'tuteurC@example.test');

insert into public.households (id, timezone) values
  ('ffffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('ffffffff-0000-0000-0000-00000000000b', 'Europe/Paris'),
  ('ffffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'GUARD-FD-000001', 'guardian',
   'ffffffff-0000-0000-0000-00000000000a', 'Fatou', 'Diallo', 'active', 'female'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'STUD-AD-000001', 'student',
   'ffffffff-0000-0000-0000-00000000000a', 'Amina', 'Diallo', 'active', null),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'STUD-ID-000002', 'student',
   'ffffffff-0000-0000-0000-00000000000a', 'Ibrahim', 'Diallo', 'active', null),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'GUARD-MB-000002', 'guardian',
   'ffffffff-0000-0000-0000-00000000000b', 'Moussa', 'Barry', 'active', 'male'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'STUD-KB-000003', 'student',
   'ffffffff-0000-0000-0000-00000000000b', 'Khadija', 'Barry', 'active', null),
  ('cccccccc-0000-0000-0000-000000000001', 'TEACH-OS-000001', 'teacher',
   null, 'Omar', 'Sow', 'provisional_active', 'male'),
  ('cccccccc-0000-0000-0000-000000000002', 'TEACH-AB-000002', 'teacher',
   null, 'Aissatou', 'Balde', 'provisional_active', 'female'),
  ('dddddddd-0000-0000-0000-000000000001', 'ADMIN-RA-000001', 'admin',
   null, 'Rewayah', 'Admin', 'active', 'female'),
  -- Un foyer sans aucun lien avec les deux enseignants : c'est lui qui mesure le
  -- defaut 3.5, les foyers A et B ayant tous deux un enfant suivi par Omar.
  ('99999999-0000-0000-0000-000000000001', 'GUARD-SC-000003', 'guardian',
   'ffffffff-0000-0000-0000-00000000000c', 'Sans', 'Cours', 'active', 'male');
-- Fixture contractuel requis par 0089 : aucune garde d'activation n'est assouplie.
DO $fixture_teacher_contracts$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
  FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active' LOOP
    PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true);
    PERFORM set_config('test.uid',v_teacher.id::text,true);
    PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
    INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version)
      ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
    UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy, level)
values
  ('aaaaaaaa-0000-0000-0000-000000000002', 'minor', 'child', 'forbidden', 'debutant'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'minor', 'standard', 'allowed', 'intermediaire'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'minor', 'child', 'forbidden', 'debutant');

insert into public.teacher_profiles (profile_id, country, timezone_iana) values
  ('cccccccc-0000-0000-0000-000000000001', 'FR', 'Europe/Paris'),
  ('cccccccc-0000-0000-0000-000000000002', 'GN', 'Africa/Conakry');

-- Le fuseau dans lequel chacun pose ses creneaux, quel que soit son role.
do $$
declare
  v_tuteur text;
  v_enseignante text;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_tuteur := public.mon_fuseau();

  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  v_enseignante := public.mon_fuseau();

  if v_tuteur <> 'Europe/Paris' then
    raise exception 'Fuseau ECHEC : le foyer lit % au lieu de son fuseau', v_tuteur;
  end if;
  if v_enseignante <> 'Africa/Conakry' then
    raise exception 'Fuseau ECHEC : l''enseignante lit % au lieu du sien', v_enseignante;
  end if;
  raise notice 'Fuseau ok : chaque role pose ses creneaux dans son fuseau, sans que l''ecran ait a le savoir';
end $$;

-- ============================================================
-- S1 : tuteur et enseignant ecrivent dans la meme table de disponibilites
-- ============================================================

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  -- Le tuteur pose les creneaux de ses deux enfants.
  insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  values ('aaaaaaaa-0000-0000-0000-000000000002', 1, 17, 'Europe/Paris'),
         ('aaaaaaaa-0000-0000-0000-000000000002', 3, 17, 'Europe/Paris'),
         ('aaaaaaaa-0000-0000-0000-000000000003', 2, 18, 'Europe/Paris');

  raise notice 'S1a ok : le tuteur pose les creneaux de son foyer';
end $$;

do $$
declare v_erreur boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);
  begin
    insert into public.weekly_availability (profile_id, weekday, hour_local)
    values ('bbbbbbbb-0000-0000-0000-000000000002', 1, 10);
  exception when insufficient_privilege then
    v_erreur := true;
  end;

  if not v_erreur then
    raise exception 'S1 ECHEC : un tuteur a pose un creneau pour l''enfant d''un autre foyer';
  end if;
  raise notice 'S1b ok : un tuteur ne pose rien hors de son foyer';
end $$;

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  values ('cccccccc-0000-0000-0000-000000000001', 1, 17, 'Europe/Paris'),
         ('cccccccc-0000-0000-0000-000000000001', 2, 18, 'Europe/Paris'),
         ('cccccccc-0000-0000-0000-000000000001', 3, 17, 'Europe/Paris');

  raise notice 'S1c ok : l''enseignant pose les siens, dans la meme table';
end $$;

-- Le croisement des fuseaux, calcule et non supposé : l'enseignante de Conakry
-- pose l'heure locale qui correspond au meme INSTANT que le lundi 17h de Paris.
-- Le calcul est fait ici plutot qu'ecrit en dur, sinon le test serait vrai en
-- ete et faux en hiver.
do $$
declare
  v_instant timestamptz;
  v_jour int;
  v_heure int;
begin
  v_instant := public.instant_creneau(1, 17, 'Europe/Paris');
  v_jour := extract(isodow from (v_instant at time zone 'Africa/Conakry'))::int;
  v_heure := extract(hour from (v_instant at time zone 'Africa/Conakry'))::int;

  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  values ('cccccccc-0000-0000-0000-000000000002', v_jour, v_heure, 'Africa/Conakry');

  raise notice 'S1d ok : l''enseignante de Conakry pose % h le jour %, soit le meme instant que 17h a Paris',
    v_heure, v_jour;
end $$;

-- La semaine de reference d'un creneau ne depend pas du fuseau qui le demande.
--
-- Le defaut, mesure le 6 septembre 2026 a 22h23 UTC : instant_creneau ancrait sa
-- semaine sur `date_trunc('week', now() at time zone p_tz)`. A cette heure-la,
-- Paris etait deja lundi et Conakry encore dimanche, donc les deux fuseaux
-- dataient deux semaines differentes et le meme rendez-vous rendait deux
-- instants a SEPT JOURS d'ecart. Le feed de ENS-06 se vidait alors de toute
-- famille d'un autre fuseau, deux heures par semaine, sans erreur ni trace.
--
-- Le controle ne compare pas a une valeur ecrite en dur, qui serait vraie en ete
-- et fausse en hiver : deux fuseaux separes de quelques heures ne peuvent pas
-- rendre un ecart d'un jour entier pour le meme jour et la meme heure nominale.
-- Il vaut donc a n'importe quelle heure, n'importe quel jour de l'annee.
do $$
declare
  v_jour int;
  v_ecart interval;
begin
  for v_jour in 1 .. 7 loop
    v_ecart := public.instant_creneau(v_jour, 12, 'Europe/Paris')
             - public.instant_creneau(v_jour, 12, 'Africa/Conakry');
    if abs(extract(epoch from v_ecart)) >= 86400 then
      raise exception
        'Instant ECHEC : le jour % rend % d''ecart entre Paris et Conakry, soit une semaine de decalage',
        v_jour, v_ecart;
    end if;
  end loop;
  raise notice 'Instant ok : la semaine de reference est la meme dans tous les fuseaux';
end $$;

-- ============================================================
-- S15 : une regle posee pour un eleve ne change rien pour les autres
-- ============================================================

do $$
declare
  v_amina int;
  v_ibrahim int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- Amina a six ans : elle decroche a trente minutes.
  perform public.poser_regle('aaaaaaaa-0000-0000-0000-000000000002',
    'session_duration_minutes', 30, 'age de l''enfant, decroche au-dela');

  v_amina := public.regle_effective('aaaaaaaa-0000-0000-0000-000000000002',
    'session_duration_minutes');
  v_ibrahim := public.regle_effective('aaaaaaaa-0000-0000-0000-000000000003',
    'session_duration_minutes');

  if v_amina <> 30 then
    raise exception 'S15 ECHEC : Amina lit % minutes au lieu de 30', v_amina;
  end if;
  if v_ibrahim <> 60 then
    raise exception 'S15 ECHEC : la regle d''Amina a debordé sur Ibrahim (% minutes)', v_ibrahim;
  end if;
  raise notice 'S15a ok : 30 minutes pour Amina, 60 pour Ibrahim, sans redeploiement';
end $$;

-- Une regle ne se lit pas par n'importe qui : elle dit ce que vaut une seance.
do $$
declare v_refus boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'bbbbbbbb-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000b"}}',
    true);
  begin
    perform public.regle_effective('aaaaaaaa-0000-0000-0000-000000000002',
      'session_duration_minutes');
  exception when others then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'S15 ECHEC : un tuteur etranger lit les regles d''un autre foyer';
  end if;
  raise notice 'S15b ok : les regles ne se lisent qu''entre parties concernees';
end $$;

-- Une regle ne se pose que sur un profil dont elle a un sens.
do $$
declare v_refus int := 0;
begin
  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  begin
    perform public.poser_regle('aaaaaaaa-0000-0000-0000-000000000002',
      'max_students_per_teacher', 9, 'incoherent');
  exception when others then v_refus := v_refus + 1;
  end;

  begin
    perform public.poser_regle('cccccccc-0000-0000-0000-000000000001',
      'session_duration_minutes', 90, 'incoherent');
  exception when others then v_refus := v_refus + 1;
  end;

  if v_refus <> 2 then
    raise exception 'S15 ECHEC : % refus au lieu de 2 sur des regles incoherentes', v_refus;
  end if;
  raise notice 'S15c ok : un plafond ne se pose pas sur un eleve, ni une duree sur un enseignant';
end $$;

-- ============================================================
-- S16 : une surcharge close reste lisible, aucune ne se supprime
-- ============================================================

-- Deux barrieres, mesurees separement. La premiere est le privilege : aucun
-- client n'ecrit dans cette table, pas meme l'administration, qui passe par
-- poser_regle() et clore_regle().
do $$
declare
  v_id uuid;
  v_refus int := 0;
begin
  select id into v_id from public.rule_overrides
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is null;

  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  begin
    delete from public.rule_overrides where id = v_id;
  exception when insufficient_privilege then v_refus := v_refus + 1;
  end;

  begin
    update public.rule_overrides set value = '90'::jsonb where id = v_id;
  exception when insufficient_privilege then v_refus := v_refus + 1;
  end;

  if v_refus <> 2 then
    raise exception 'S16 ECHEC : % refus de privilege au lieu de 2', v_refus;
  end if;
  raise notice 'S16a ok : aucun client n''ecrit dans les regles, l''administration comprise';
end $$;

-- La seconde barriere est le declencheur, qui tient meme pour le proprietaire de
-- la base : c'est elle qui protege d'une reprise faite avec la cle de service.
do $$
declare
  v_id uuid;
  v_refus int := 0;
  v_message text;
begin
  select id into v_id from public.rule_overrides
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is null;

  begin
    delete from public.rule_overrides where id = v_id;
  exception when sqlstate 'P0001' then
    get stacked diagnostics v_message = message_text;
    if v_message like '%ne s''efface pas%' then v_refus := v_refus + 1; end if;
  end;

  begin
    update public.rule_overrides set value = '90'::jsonb where id = v_id;
  exception when sqlstate 'P0001' then
    get stacked diagnostics v_message = message_text;
    if v_message like '%seule la cloture%' then v_refus := v_refus + 1; end if;
  end;

  if v_refus <> 2 then
    raise exception 'S16 ECHEC : le declencheur d''immuabilite laisse passer (% refus)', v_refus;
  end if;
  raise notice 'S16b ok : une regle ne s''efface ni ne se reecrit, meme en direct';
end $$;

do $$
declare
  v_ancienne uuid;
  v_valeur int;
  v_closes int;
begin
  select id into v_ancienne from public.rule_overrides
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is null;

  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- Amina grandit : 45 minutes. L'ancienne regle se clot, elle ne disparait pas.
  perform public.poser_regle('aaaaaaaa-0000-0000-0000-000000000002',
    'session_duration_minutes', 45, 'l''enfant tient plus longtemps');

  v_valeur := public.regle_effective('aaaaaaaa-0000-0000-0000-000000000002',
    'session_duration_minutes');
  select count(*) into v_closes from public.rule_overrides
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is not null;

  if v_valeur <> 45 then
    raise exception 'S16 ECHEC : valeur effective % au lieu de 45', v_valeur;
  end if;
  if v_closes <> 1 then
    raise exception 'S16 ECHEC : % regle close au lieu de 1, l''historique est perdu', v_closes;
  end if;
  if not exists (select 1 from public.rule_overrides
                 where id = v_ancienne and ended_at is not null
                   and ended_by is not null and end_reason is not null) then
    raise exception 'S16 ECHEC : la regle close ne porte ni auteur ni motif';
  end if;
  raise notice 'S16c ok : la regle de 30 minutes reste lisible, avec son auteur et son motif';
end $$;

-- ============================================================
-- S2 et S4 : un eleve a au plus un enseignant, et un seul l'obtient
-- ============================================================

do $$
declare v_assignment uuid;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  v_assignment := public.prendre_eleve('aaaaaaaa-0000-0000-0000-000000000002', 1, 17);

  if v_assignment is null then
    raise exception 'S2 ECHEC : la prise n''a rien rendu';
  end if;
  raise notice 'S2a ok : Omar prend Amina sur le creneau du lundi 17h';
end $$;

do $$
declare v_message text;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.prendre_eleve('aaaaaaaa-0000-0000-0000-000000000002', 1, 17);
    raise exception 'S2 ECHEC : un deuxieme enseignant a pris le meme eleve';
  exception when sqlstate 'P0001' then
    get stacked diagnostics v_message = message_text;
    if v_message like 'S2 ECHEC%' then raise; end if;
  end;
  raise notice 'S2b ok : le second enseignant est refuse (%)', v_message;
end $$;

-- ============================================================
-- S3 : le plafond est tranche en base, et il se surcharge
-- ============================================================

-- Quatre eleves de plus pour Omar, qui en a deja un.
insert into auth.users (id, email)
select ('eeeeeeee-0000-0000-0000-00000000000' || i)::uuid, 'eleve' || i || '@example.test'
from generate_series(1, 5) i;

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
select ('eeeeeeee-0000-0000-0000-00000000000' || i)::uuid,
       'STUD-XX-00001' || i, 'student', 'ffffffff-0000-0000-0000-00000000000b',
       'Eleve' || i, 'Barry', 'active'
from generate_series(1, 5) i;

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
select ('eeeeeeee-0000-0000-0000-00000000000' || i)::uuid, 'minor', 'standard', 'forbidden'
from generate_series(1, 5) i;

-- Chacun sur un creneau distinct, sinon c'est le chevauchement qui refuserait,
-- et le test mesurerait autre chose que le plafond.
insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
select ('eeeeeeee-0000-0000-0000-00000000000' || i)::uuid, 4, 8 + i, 'Europe/Paris'
from generate_series(1, 5) i;

insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
select 'cccccccc-0000-0000-0000-000000000001', 4, 8 + i, 'Europe/Paris'
from generate_series(1, 5) i;

do $$
declare
  v_pris int := 0;
  v_message text;
  i int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  for i in 1 .. 5 loop
    begin
      perform public.prendre_eleve(('eeeeeeee-0000-0000-0000-00000000000' || i)::uuid, 4, 8 + i);
      v_pris := v_pris + 1;
    exception when sqlstate 'P0001' then
      get stacked diagnostics v_message = message_text;
    end;
  end loop;

  -- Omar avait deja Amina : il ne peut en prendre que quatre de plus.
  if v_pris <> 4 then
    raise exception 'S3 ECHEC : % prises au lieu de 4 avant le plafond', v_pris;
  end if;
  if v_message not like '%plafond%' then
    raise exception 'S3 ECHEC : le refus ne parle pas du plafond (%)', v_message;
  end if;
  raise notice 'S3a ok : le sixieme eleve est refuse par la base, pas par l''ecran';
end $$;

do $$
declare v_pris boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  perform public.poser_regle('cccccccc-0000-0000-0000-000000000001',
    'max_students_per_teacher', 6, 'cet enseignant a du temps');
end $$;

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  perform public.prendre_eleve('eeeeeeee-0000-0000-0000-000000000005', 4, 13);

  if (select count(*) from public.teacher_student_assignments
      where teacher_id = 'cccccccc-0000-0000-0000-000000000001' and ended_at is null) <> 6 then
    raise exception 'S3 ECHEC : le plafond surcharge n''a pas pris effet';
  end if;
  raise notice 'S3b ok : plafond porte a 6 pour ce seul enseignant, sans redeploiement';
end $$;

-- ============================================================
-- S5 : une affectation ne se rompt pas toute seule
-- ============================================================

do $$
declare
  v_refus int := 0;
  v_id uuid;
begin
  select id into v_id from public.teacher_student_assignments
  where student_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is null;

  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  begin
    update public.teacher_student_assignments set ended_at = now() where id = v_id;
  exception when insufficient_privilege then v_refus := v_refus + 1;
  end;

  begin
    delete from public.teacher_student_assignments where id = v_id;
  exception when insufficient_privilege then v_refus := v_refus + 1;
  end;

  if v_refus <> 2 then
    raise exception 'S5 ECHEC : % refus au lieu de 2 sur une ecriture directe', v_refus;
  end if;
  if (select count(*) from public.teacher_student_assignments
      where id = v_id and ended_at is null) <> 1 then
    raise exception 'S5 ECHEC : un enseignant s''est retire un eleve sans decision';
  end if;
  raise notice 'S5 ok : ni update ni delete direct sur une affectation';
end $$;

-- ============================================================
-- La prise materialise les seances, a la duree de CET eleve
-- ============================================================

do $$
declare
  v_seances int;
  v_minutes int;
begin
  select count(*) into v_seances
  from public.sessions s
  join public.session_participants sp on sp.session_id = s.id
  where sp.profile_id = 'aaaaaaaa-0000-0000-0000-000000000002' and s.deleted_at is null;

  select distinct extract(epoch from (s.ended_at - s.started_at))::int / 60 into v_minutes
  from public.sessions s
  join public.session_participants sp on sp.session_id = s.id
  where sp.profile_id = 'aaaaaaaa-0000-0000-0000-000000000002';

  if v_seances < 3 then
    raise exception 'S-materialisation ECHEC : % seances posees, l''horizon est de 4 semaines', v_seances;
  end if;
  -- 45 minutes, parce que c'est la regle d'Amina, pas les 60 de la plateforme.
  if v_minutes <> 45 then
    raise exception 'S-materialisation ECHEC : seances de % minutes au lieu des 45 de cet eleve', v_minutes;
  end if;
  raise notice 'S-materialisation ok : % seances de 45 minutes, la regle de l''eleve et non celle de la plateforme', v_seances;
end $$;

-- ============================================================
-- S7 : deux seances qui se recoupent, et deux qui s'enchainent
-- ============================================================

do $$
declare
  v_debut timestamptz;
  v_refus boolean := false;
begin
  select min(started_at) into v_debut from public.sessions
  where teacher_id = 'cccccccc-0000-0000-0000-000000000001';

  begin
    insert into public.sessions (teacher_id, started_at, ended_at)
    values ('cccccccc-0000-0000-0000-000000000001',
            v_debut + interval '10 minutes', v_debut + interval '70 minutes');
  exception when exclusion_violation then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'S7 ECHEC : deux seances du meme enseignant se recoupent';
  end if;
  raise notice 'S7a ok : le chevauchement est refuse par la contrainte, pas par l''ecran';
end $$;

do $$
declare
  v_fin timestamptz;
  v_id uuid;
begin
  -- La seance d'Amina, materialisee le lundi 17h par S2a : c'est la seule
  -- seance d'Omar dont l'heure suivante est libre a coup sur, le lundi ne
  -- portant rien d'autre. `order by started_at limit 1` sur toutes ses seances
  -- tombait sinon sur une seance du jeudi (S3, heures 9 a 13, collees) des que
  -- le prochain jeudi precede le prochain lundi, trois jours sur sept : ce
  -- controle etait alors vert le week-end et rouge du mardi au jeudi. Un
  -- controle vrai seulement certains jours n'est pas un controle.
  select s.ended_at into v_fin
  from public.sessions s
  join public.session_participants sp on sp.session_id = s.id
  where s.teacher_id = 'cccccccc-0000-0000-0000-000000000001'
    and sp.profile_id = 'aaaaaaaa-0000-0000-0000-000000000002'
  order by s.started_at limit 1;

  -- Defaut 3.9 : avec les bornes fermees de l'etape 1, cette seance collee a la
  -- precedente etait refusee comme un chevauchement.
  insert into public.sessions (teacher_id, started_at, ended_at)
  values ('cccccccc-0000-0000-0000-000000000001', v_fin, v_fin + interval '60 minutes')
  returning id into v_id;

  insert into public.session_participants (session_id, profile_id, role)
  values (v_id, 'cccccccc-0000-0000-0000-000000000001', 'teacher');

  raise notice 'S7b ok : deux cours qui s''enchainent passent, la fin de l''un est le debut de l''autre';
end $$;

-- ============================================================
-- S6 : le tuteur regle son enfant, et rien d'autre
-- ============================================================

do $$
declare v_refus boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  update public.student_profiles set camera_policy = 'allowed'
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002';

  update public.student_profiles set interface_mode = 'standard'
  where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002';

  begin
    update public.student_profiles set level = 'avance'
    where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002';
  exception when insufficient_privilege then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'S6 ECHEC : le tuteur a change le niveau pedagogique de son enfant';
  end if;
end $$;

do $$
begin
  if (select camera_policy from public.student_profiles
      where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002') <> 'allowed' then
    raise exception 'S6 ECHEC : le reglage camera n''a pas ete ecrit';
  end if;
  if (select level from public.student_profiles
      where profile_id = 'aaaaaaaa-0000-0000-0000-000000000002') <> 'debutant' then
    raise exception 'S6 ECHEC : le niveau a change malgre le refus';
  end if;
  raise notice 'S6a ok : camera et mode d''interface ecrits, niveau refuse. Une RLS borne les lignes, pas les colonnes';
end $$;

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  update public.student_profiles set camera_policy = 'allowed'
  where profile_id = 'bbbbbbbb-0000-0000-0000-000000000002';
end $$;

do $$
begin
  if (select camera_policy from public.student_profiles
      where profile_id = 'bbbbbbbb-0000-0000-0000-000000000002') <> 'forbidden' then
    raise exception 'S6 ECHEC : un tuteur a regle l''enfant d''un autre foyer';
  end if;
  raise notice 'S6b ok : le reglage s''arrete a la limite du foyer';
end $$;

-- La date de fin d'acces, que TUT-01 affiche par enfant en MVP-0 a la place d'un
-- portefeuille. L'import d'administration est represente par un admin actif;
-- la garde du trigger ne doit pas s'appuyer sur un role JWT absent.
do $import_admin$
begin
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  update public.profiles set access_until = now() + interval '30 days'
  where id = 'aaaaaaaa-0000-0000-0000-000000000003';
end
$import_admin$;

do $$
declare
  v_lignes int;
  v_echeance timestamptz;
  v_etrangers int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  select count(*) into v_lignes from public.profils_du_foyer_v;
  select access_until into v_echeance from public.profils_du_foyer_v
  where id = 'aaaaaaaa-0000-0000-0000-000000000003';
  select count(*) into v_etrangers from public.profils_du_foyer_v
  where id = 'bbbbbbbb-0000-0000-0000-000000000002';

  if v_lignes <> 2 then
    raise exception 'S6 ECHEC : le foyer lit % enfants au lieu de 2', v_lignes;
  end if;
  if v_echeance is null then
    raise exception 'S6 ECHEC : la date de fin d''acces de l''enfant n''est pas lisible par son foyer';
  end if;
  if v_etrangers <> 0 then
    raise exception 'S6 ECHEC : un foyer lit l''enfant d''un autre foyer';
  end if;
  raise notice 'S6c ok : le foyer lit les reglages et la date de fin d''acces de ses enfants, et d''aucun autre';
end $$;

-- ============================================================
-- S8 : les disponibilites ne sont plus lisibles par toute la plateforme
-- ============================================================

insert into public.availability_slots (teacher_id, starts_at, ends_at)
values ('cccccccc-0000-0000-0000-000000000001', now() + interval '1 day',
        now() + interval '1 day 1 hour');

do $$
declare
  v_ancienne int;
  v_hebdo int;
begin
  set local role authenticated;
  perform set_config('test.uid', '99999999-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000c"}}',
    true);

  select count(*) into v_ancienne from public.availability_slots;
  select count(*) into v_hebdo from public.weekly_availability
  where profile_id = 'cccccccc-0000-0000-0000-000000000001';

  if v_ancienne <> 0 then
    raise exception 'S8 ECHEC : un tuteur lit % creneaux d''enseignants qui ne suivent pas son enfant', v_ancienne;
  end if;
  if v_hebdo <> 0 then
    raise exception 'S8 ECHEC : un tuteur lit la grille hebdomadaire d''un enseignant etranger';
  end if;
  raise notice 'S8a ok : un tuteur sans lien ne lit aucune disponibilite d''enseignant';
end $$;

do $$
declare v_ancienne int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  select count(*) into v_ancienne from public.availability_slots;

  if v_ancienne <> 1 then
    raise exception 'S8 ECHEC : le tuteur de l''eleve suivi ne lit pas les creneaux de son enseignant (%)', v_ancienne;
  end if;
  raise notice 'S8b ok : le tuteur de l''eleve suivi, lui, les lit';
end $$;

-- ============================================================
-- Les vues d'exposition disent ce qu'elles doivent, et rien de plus
-- ============================================================

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'teacher_roster_v'
      and column_name = 'last_name'
  ) then
    raise exception
      'Defaut 3.8 ECHEC : teacher_roster_v expose encore le nom de famille des eleves';
  end if;
  raise notice 'Defaut 3.8 ok : la liste des eleves d''un enseignant ne porte que prenom et identifiant';
end $$;

do $$
declare
  v_prenom text;
  v_nb int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  select count(*), min(teacher_first_name) into v_nb, v_prenom
  from public.mes_seances_v
  where student_id = 'aaaaaaaa-0000-0000-0000-000000000002';

  if v_nb = 0 then
    raise exception 'Defaut 3.6 ECHEC : le foyer ne voit aucune seance de son enfant';
  end if;
  if v_prenom <> 'Omar' then
    raise exception
      'Defaut 3.6 ECHEC : le tuteur voit son enfant en cours sans savoir avec qui (%)',
      coalesce(v_prenom, 'aucun nom');
  end if;
  raise notice 'Defaut 3.6 ok : le tuteur lit le prenom de l''enseignant de son enfant';
end $$;

-- ============================================================
-- S17 : les quatre parties demandent, l'administration tranche
-- ============================================================

do $$
declare
  v_refus boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'bbbbbbbb-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000b"}}',
    true);
  begin
    perform public.demander('reassignment', 'aaaaaaaa-0000-0000-0000-000000000002',
      'je prefere un autre enseignant');
  exception when sqlstate 'P0001' then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'S17 ECHEC : un tuteur etranger a demande la reaffectation d''un autre foyer';
  end if;
  raise notice 'S17a ok : seule une partie au dossier demande';
end $$;

do $$
declare v_id uuid;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  v_id := public.demander('capacity', 'cccccccc-0000-0000-0000-000000000001',
    'j''ai du temps le samedi', null, 8);

  if v_id is null then
    raise exception 'S17 ECHEC : l''enseignant n''a pas pu demander son plafond';
  end if;
  raise notice 'S17b ok : l''enseignant demande une augmentation de plafond';
end $$;

do $$
declare v_id uuid;
begin
  set local role authenticated;
  perform set_config('test.uid', 'aaaaaaaa-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000a"}}',
    true);

  v_id := public.demander('reassignment', 'aaaaaaaa-0000-0000-0000-000000000002',
    'l''horaire ne convient plus a la famille');

  if v_id is null then
    raise exception 'S17 ECHEC : le tuteur n''a pas pu demander une reaffectation';
  end if;
  raise notice 'S17c ok : le tuteur demande la reaffectation de son enfant';
end $$;

do $$
declare v_file int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select count(*) into v_file from public.demandes_en_attente();
  if v_file <> 2 then
    raise exception 'S17 ECHEC : % demandes dans la file au lieu de 2', v_file;
  end if;
  raise notice 'S17d ok : les deux demandes atteignent la file de ADM-06';
end $$;

do $$
declare
  v_reassignment uuid;
  v_actives int;
  v_annulees int;
begin
  select id into v_reassignment from public.matching_requests
  where kind = 'reassignment' and status = 'pending';

  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  perform public.decider_demande(v_reassignment, true, 'accorde, creneau incompatible');

  select count(*) into v_actives from public.teacher_student_assignments
  where student_id = 'aaaaaaaa-0000-0000-0000-000000000002' and ended_at is null;

  select count(*) into v_annulees from public.sessions s
  join public.session_participants sp on sp.session_id = s.id
  where sp.profile_id = 'aaaaaaaa-0000-0000-0000-000000000002'
    and s.status = 'canceled';

  if v_actives <> 0 then
    raise exception 'S17 ECHEC : l''affectation tient encore apres la decision';
  end if;
  if v_annulees = 0 then
    raise exception
      'S17 ECHEC : des seances restent planifiees avec un enseignant qui ne suit plus l''eleve';
  end if;
  raise notice 'S17e ok : l''affectation est close et % seances a venir sont annulees', v_annulees;
end $$;

-- ============================================================
-- Le feed de ENS-06 croise les fuseaux, et trie par anciennete
-- ============================================================

do $$
declare
  v_amina int;
  v_depuis timestamptz;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select count(*), min(depuis) into v_amina, v_depuis
  from public.eleves_en_attente_v
  where student_id = 'aaaaaaaa-0000-0000-0000-000000000002';

  if v_amina = 0 then
    raise exception
      'Feed ECHEC : l''enseignante de Conakry ne voit pas un creneau pose en heure de Paris';
  end if;
  if v_depuis is null then
    raise exception 'Feed ECHEC : sans anciennete, le tri par attente est impossible';
  end if;
  raise notice 'Feed ok : le creneau se croise par instant, l''attente est datee';
end $$;

do $$
declare v_visible int;
begin
  -- L'enseignante de Conakry n'a qu'un creneau, celui du lundi. Ibrahim propose
  -- le mardi : il ne doit apparaitre nulle part chez elle.
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select count(*) into v_visible from public.eleves_en_attente_v
  where student_id = 'aaaaaaaa-0000-0000-0000-000000000003';

  if v_visible <> 0 then
    raise exception
      'Feed ECHEC : un eleve dont le creneau ne croise aucune disponibilite est propose';
  end if;
  raise notice 'Feed ok : un creneau qui ne croise rien n''est propose a personne';
end $$;

-- ============================================================
-- Les six compteurs de ADM-01, zero compris
-- ============================================================

-- Les compteurs se comparent aux agregats reels, jamais a des nombres ecrits en
-- dur : ce fichier tourne apres celui de l'etape 3, dont il herite les donnees,
-- et un test qui suppose une base vide mesurerait l'ordre d'execution.
do $$
declare
  v_i record;
  v_personnes_en_attente int;
  v_foyers int;
  v_demandes int;
begin
  -- Depuis 0015, ce compteur désigne les personnes en attente de validation,
  -- avec ou sans pièce déposée; il ne compte pas les lignes KYC.
  select count(*)::int into v_personnes_en_attente
  from public.profiles p
  where p.deleted_at is null and p.account_status = 'pending_kyc';

  select count(distinct p.household_id)::int into v_foyers
  from public.profiles p
  where p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and not exists (select 1 from public.teacher_student_assignments a
                    where a.student_id = p.id and a.ended_at is null);

  select count(*)::int into v_demandes from public.matching_requests
  where status = 'pending';

  set local role authenticated;
  perform set_config('test.uid', 'dddddddd-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select * into v_i from public.indicateurs_admin();

  if v_i.dossiers_en_attente <> v_personnes_en_attente then
    raise exception 'ADM-01 ECHEC : % dossiers annonces, % reels',
      v_i.dossiers_en_attente, v_personnes_en_attente;
  end if;
  if v_i.foyers_sans_enseignant <> v_foyers then
    raise exception 'ADM-01 ECHEC : % foyers sans enseignant annonces, % reels',
      v_i.foyers_sans_enseignant, v_foyers;
  end if;
  if v_i.demandes_en_attente <> v_demandes then
    raise exception 'ADM-01 ECHEC : % demandes annoncees, % reelles',
      v_i.demandes_en_attente, v_demandes;
  end if;
  -- Amina vient d'etre liberee par la reaffectation : son foyer doit compter.
  if v_foyers < 1 then
    raise exception 'ADM-01 ECHEC : aucun foyer sans enseignant apres une reaffectation';
  end if;
  raise notice 'ADM-01 ok : dossiers %, foyers sans enseignant %, rapports manquants %, incidents %, comptes echus %, demandes %',
    v_i.dossiers_en_attente, v_i.foyers_sans_enseignant, v_i.rapports_manquants,
    v_i.incidents_24h, v_i.comptes_echus, v_i.demandes_en_attente;
end $$;

do $$
declare v_refus boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.indicateurs_admin();
  exception when sqlstate 'P0001' then v_refus := true;
  end;

  if not v_refus then
    raise exception 'ADM-01 ECHEC : un enseignant lit le centre de commande';
  end if;
  raise notice 'ADM-01 ok : le centre de commande reste a l''administration';
end $$;

-- ============================================================
-- Les reglages de priere : poses par l'enseignant, lus par ses eleves
-- ============================================================

do $$
declare v_refus int := 0;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  insert into public.prayer_settings
    (teacher_id, latitude, longitude, method, madhab, timezone_iana, place_label)
  values ('cccccccc-0000-0000-0000-000000000001', 48.85341, 2.34880,
          'muslim_world_league', 'shafi', 'Europe/Paris', 'Paris');

  -- L'ajustement a la minute pres, exige par l'operateur. La pause et son
  -- preavis d'alerte se posent au meme endroit, pour que tout le monde soit
  -- prevenu au meme instant.
  update public.prayer_settings
  set adjustments = '{"fajr": 0, "dhuhr": 2, "asr": 0, "maghrib": -1, "isha": 0}'::jsonb,
      pause_minutes = 12,
      alert_lead_minutes = 5
  where teacher_id = 'cccccccc-0000-0000-0000-000000000001';

  begin
    update public.prayer_settings set adjustments = '{"fajr": 0, "dhuhr": 45, "asr": 0, "maghrib": 0, "isha": 0}'::jsonb
    where teacher_id = 'cccccccc-0000-0000-0000-000000000001';
  exception when sqlstate 'P0001' then v_refus := v_refus + 1;
  end;

  begin
    update public.prayer_settings set adjustments = '{"fajr": 0, "dhuhr": 0}'::jsonb
    where teacher_id = 'cccccccc-0000-0000-0000-000000000001';
  exception when sqlstate 'P0001' then v_refus := v_refus + 1;
  end;

  if v_refus <> 2 then
    raise exception 'Prieres ECHEC : % refus au lieu de 2 sur des ajustements aberrants', v_refus;
  end if;
  raise notice 'Prieres ok : ajustement a la minute accepte, decalage de 45 min et priere manquante refuses';
end $$;

do $$
declare
  v_lu int;
  v_dhuhr int;
  v_pause int;
  v_preavis int;
begin
  -- Le tuteur de l'eleve suivi par Omar. Amina a ete reaffectee, on prend donc
  -- un eleve encore suivi : Eleve1, du foyer B.
  set local role authenticated;
  perform set_config('test.uid', 'bbbbbbbb-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"ffffffff-0000-0000-0000-00000000000b"}}',
    true);

  select count(*), min((adjustments -> 'dhuhr' #>> '{}')::int),
         min(pause_minutes), min(alert_lead_minutes)
    into v_lu, v_dhuhr, v_pause, v_preavis
  from public.prayer_settings
  where teacher_id = 'cccccccc-0000-0000-0000-000000000001';

  if v_lu <> 1 then
    raise exception
      'Prieres ECHEC : le foyer ne lit pas les reglages de l''enseignant de son enfant. '
      'Sans cela, il n''y a pas de transparence, seulement une parole contre une autre';
  end if;
  if v_dhuhr <> 2 then
    raise exception 'Prieres ECHEC : l''ajustement lu vaut % au lieu de 2', v_dhuhr;
  end if;
  -- La duree de l'interruption et le moment de l'alerte sont les memes des deux
  -- cotes : c'est la condition pour que « personne ne soit surpris » veuille
  -- dire la meme chose pour l'eleve et pour l'enseignant.
  if v_pause <> 12 or v_preavis <> 5 then
    raise exception
      'Prieres ECHEC : le foyer lit une pause de % min et un preavis de % min, '
      'la ou l''enseignant a pose 12 et 5', v_pause, v_preavis;
  end if;
  raise notice 'Prieres ok : le foyer lit les memes entrees de calcul que l''enseignant, ajustement, pause et preavis compris';
end $$;

do $$
declare v_lu int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'cccccccc-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select count(*) into v_lu from public.prayer_settings
  where teacher_id = 'cccccccc-0000-0000-0000-000000000001';

  if v_lu <> 0 then
    raise exception 'Prieres ECHEC : un enseignant lit les reglages d''un collegue';
  end if;
  raise notice 'Prieres ok : les reglages ne sortent pas du cercle des parties concernees';
end $$;

-- H1: la lecture des groupes ne boucle pas entre les deux policies RLS.
begin;

insert into auth.users (id, email) values
  ('a1730000-0000-0000-0000-000000000001', 'h1-teacher@example.test'),
  ('a1730000-0000-0000-0000-000000000002', 'h1-student-a@example.test'),
  ('a1730000-0000-0000-0000-000000000003', 'h1-student-b@example.test'),
  ('a1730000-0000-0000-0000-000000000004', 'h1-outsider@example.test');
insert into public.households (id, timezone) values
  ('a173ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('a173ffff-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a1730000-0000-0000-0000-000000000001', 'H1-TEACHER-001', 'teacher',
   null, 'Fixture', 'Teacher', 'provisional_active'),
  ('a1730000-0000-0000-0000-000000000002', 'H1-STUDENT-A-001', 'student',
   'a173ffff-0000-0000-0000-000000000001', 'Fixture', 'StudentA', 'active'),
  ('a1730000-0000-0000-0000-000000000003', 'H1-STUDENT-B-001', 'student',
   'a173ffff-0000-0000-0000-000000000001', 'Fixture', 'StudentB', 'active'),
  ('a1730000-0000-0000-0000-000000000004', 'H1-OUTSIDER-001', 'student',
   'a173ffff-0000-0000-0000-000000000002', 'Fixture', 'Outsider', 'active');
-- Fixture contractuel requis par 0089 : aucune garde d'activation n'est assouplie.
DO $fixture_teacher_contracts$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
  FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active' LOOP
    PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true);
    PERFORM set_config('test.uid',v_teacher.id::text,true);
    PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
    INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version)
      ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
    UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;
insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
values
  ('a173ffff-0000-0000-0000-000000000010',
   'a1730000-0000-0000-0000-000000000001', 'enfant', 5,
   'H1 fixture', 1, 10, 'Europe/Paris');
insert into public.groupe_membres (groupe_id, student_id) values
  ('a173ffff-0000-0000-0000-000000000010', 'a1730000-0000-0000-0000-000000000002'),
  ('a173ffff-0000-0000-0000-000000000010', 'a1730000-0000-0000-0000-000000000003');

do $h1$
declare
  v_groups integer;
  v_members integer;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a1730000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"a173ffff-0000-0000-0000-000000000001"}}',
    true);
  select count(*) into v_groups from public.groupes
   where id = 'a173ffff-0000-0000-0000-000000000010';
  select count(*) into v_members from public.groupe_membres
   where groupe_id = 'a173ffff-0000-0000-0000-000000000010';
  if v_groups <> 1 or v_members <> 2 then
    raise exception 'H1: le foyer ne lit pas le groupe et les membres de son foyer (%, %)',
      v_groups, v_members;
  end if;

  perform set_config('test.uid', 'a1730000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"a173ffff-0000-0000-0000-000000000002"}}',
    true);
  select count(*) into v_groups from public.groupes
   where id = 'a173ffff-0000-0000-0000-000000000010';
  select count(*) into v_members from public.groupe_membres
   where groupe_id = 'a173ffff-0000-0000-0000-000000000010';
  if v_groups <> 0 or v_members <> 0 then
    raise exception 'H1: un foyer tiers lit le groupe ou ses membres (%, %)',
      v_groups, v_members;
  end if;

  perform set_config('test.uid', 'a1730000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"teacher"}}',
    true);
  select count(*) into v_groups from public.groupes
   where id = 'a173ffff-0000-0000-0000-000000000010';
  select count(*) into v_members from public.groupe_membres
   where groupe_id = 'a173ffff-0000-0000-0000-000000000010';
  if v_groups <> 1 or v_members <> 2 then
    raise exception 'H1: l''enseignant n''a pas la visibilité complète de son groupe (%, %)',
      v_groups, v_members;
  end if;
end
$h1$;

-- H2: un compte valide avec un JWT sans rôle ne peut pas rejoindre un groupe.
-- Avant 0067, « role <> admin OR NOT compte_valide » valait NULL et IF NULL
-- laissait passer cette mutation SECURITY DEFINER.
do $h2$
declare
  v_refuse boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{}', true);
  perform set_config('test.uid', 'a1730000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{}', true);

  begin
    perform public.ajouter_eleve_groupe(
      'a173ffff-0000-0000-0000-000000000010',
      'a1730000-0000-0000-0000-000000000004',
      'H2 regression: no role claim'
    );
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'ajout d''un eleve a un groupe reserve a l''administration' then
      raise;
    end if;
    v_refuse := true;
  end;

  if not v_refuse then
    raise exception 'H2 ECHEC : un JWT sans rôle a ajouté un élève au groupe';
  end if;
  raise notice 'H2 ok : ajouter_eleve_groupe refuse un compte valide sans rôle JWT';
end
$h2$;

-- F86: les quatre mutations admin refusent un JWT admin sans profil, puis
-- un profil admin dont le compte est désactivé.
do $f86_admin_mutators$
declare
  v_test record;
  v_uid uuid := 'eeeeeeee-0000-0000-0000-000000000099';
  v_admin uuid := 'dddddddd-0000-0000-0000-000000000001';
  v_refuse boolean;
begin
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_uid::text, true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
  perform set_config('test.uid', v_uid::text, true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  if auth.uid() is distinct from v_uid or public.app_account_valid() then
    raise exception 'F86 fixture: le JWT admin doit être sans profil applicatif';
  end if;

  for v_test in
    select * from (values
      ('select public.maj_eleve_pedagogie(''aaaaaaaa-0000-0000-0000-000000000002'', ''intermediaire'', ''hafs'')',
       'seul un administrateur modifie le niveau ou la riwaya'),
      ('select public.poser_regle(''aaaaaaaa-0000-0000-0000-000000000002'', ''session_duration_minutes'', 45, ''F86 sans profil'')',
       'seul un administrateur pose une regle'),
      ('select public.clore_regle(''ffffffff-0000-0000-0000-0000000000ff'', ''F86 sans profil'')',
       'seul un administrateur clot une regle'),
      ('select public.decider_demande(''ffffffff-0000-0000-0000-0000000000ff'', true, ''F86 sans profil'')',
       'seul un administrateur tranche une demande')
    ) as tests(commande, refus_attendu)
  loop
    v_refuse := false;
    begin
      execute v_test.commande;
      raise exception 'F86 ECHEC: une RPC admin a accepté le JWT sans profil';
    exception when sqlstate 'P0001' then
      if sqlerrm <> v_test.refus_attendu then raise; end if;
      v_refuse := true;
    end;
    if not v_refuse then
      raise exception 'F86 ECHEC: refus absent pour le JWT sans profil';
    end if;
  end loop;

  reset role;
  update public.profiles set account_status = 'disabled' where id = v_admin;
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_admin::text, true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
  perform set_config('test.uid', v_admin::text, true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  if auth.uid() is distinct from v_admin or public.app_account_valid() then
    raise exception 'F86 fixture: le compte admin doit être désactivé';
  end if;

  for v_test in
    select * from (values
      ('select public.maj_eleve_pedagogie(''aaaaaaaa-0000-0000-0000-000000000002'', ''intermediaire'', ''hafs'')',
       'seul un administrateur modifie le niveau ou la riwaya'),
      ('select public.poser_regle(''aaaaaaaa-0000-0000-0000-000000000002'', ''session_duration_minutes'', 45, ''F86 admin désactivé'')',
       'seul un administrateur pose une regle'),
      ('select public.clore_regle(''ffffffff-0000-0000-0000-0000000000ff'', ''F86 admin désactivé'')',
       'seul un administrateur clot une regle'),
      ('select public.decider_demande(''ffffffff-0000-0000-0000-0000000000ff'', true, ''F86 admin désactivé'')',
       'seul un administrateur tranche une demande')
    ) as tests(commande, refus_attendu)
  loop
    v_refuse := false;
    begin
      execute v_test.commande;
      raise exception 'F86 ECHEC: une RPC admin a accepté un compte désactivé';
    exception when sqlstate 'P0001' then
      if sqlerrm <> v_test.refus_attendu then raise; end if;
      v_refuse := true;
    end;
    if not v_refuse then
      raise exception 'F86 ECHEC: refus absent pour le compte désactivé';
    end if;
  end loop;

  reset role;
  update public.profiles set account_status = 'active' where id = v_admin;
end
$f86_admin_mutators$;

reset role;
rollback;
