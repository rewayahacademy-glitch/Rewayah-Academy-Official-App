-- Scenarios d'acceptation SQL de `CTR-01`, le planning du controle qualite :
-- ce que la porte d'observation accepte, ce qu'elle refuse, et ce que la visite
-- laisse lire -- a qui.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente d'un
-- « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0012. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme base :
-- il insere ses fixtures.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml`, comme ceux
-- de N2 et de N4 : `rejoindre_observation()` ecrit dans `audit_logs`, et le
-- controle J4 du journal relit la chaine de hachage de tout ce que les fichiers
-- precedents y ont ecrit.
--
-- LE CONTROLE DU LOT EST `C1`. Avant 0012, il echouait : le plafond de
-- participants du MVP-0 compte deux, un cours 1-to-1 en compte deja deux, et le
-- declencheur refusait donc TOUTE visite de controle -- c'est-a-dire la
-- fonction que l'ADR-011 confirme pour le MVP-0.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Comme dans `scenarios_n4.sql` : le grant ci-dessus vient d'annuler les
-- restrictions de 0010 sur les fonctions d'emission. On les rejoue, sans quoi
-- les fichiers suivants mesureraient le harnais et non les migrations.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

-- ============================================================
-- Fixtures : quatre seances 1-to-1, et PAS de plafond leve
-- ============================================================
--
-- C'est le point le plus important de ce fichier : contrairement a
-- `scenarios_n4.sql`, il ne touche pas a `allow_multi_participant_sessions`.
-- Les seances restent des cours 1-to-1 pleins au sens du MVP-0, et c'est
-- precisement dans cet etat-la que la visite doit pouvoir entrer.
--
--   * Seance A, en cours : Rachid enseigne a Sofia. C'est la seance observee.
--   * Seance D, en cours AUX MEMES HEURES : Youssef enseigne a Ines. Elle
--     mesure qu'un controleur enchaine deux visites qui se recoupent.
--   * Seance B, dans trois heures : Rachid et Sofia. Elle mesure le refus
--     « pas encore commencee ».
--   * Seance C, terminee : Youssef et Ines. Elle mesure le refus « close ».
--   * Seance E, en cours : Kenza enseigne a Adam, et Nadia y figure deja comme
--     temoin. Fixture artificielle -- un controleur n'a pas vocation a etre
--     tuteur observateur -- mais c'est la seule facon d'exercer l'interdit de
--     l'ADR-011 : « observer une seance ou il est lui-meme participant ».

insert into auth.users (id, email) values
  ('c1000000-0000-0000-0000-000000000001', 'rachid@example.test'),
  ('c1000000-0000-0000-0000-000000000002', 'sofia@example.test'),
  ('c1000000-0000-0000-0000-000000000003', 'nadia@example.test'),
  ('c1000000-0000-0000-0000-000000000004', 'bilal@example.test'),
  ('c1000000-0000-0000-0000-000000000005', 'latifa@example.test'),
  ('c1000000-0000-0000-0000-000000000006', 'youssef@example.test'),
  ('c1000000-0000-0000-0000-000000000007', 'ines@example.test'),
  ('c1000000-0000-0000-0000-000000000008', 'amira@example.test'),
  ('c1000000-0000-0000-0000-000000000009', 'kenza@example.test'),
  ('c1000000-0000-0000-0000-00000000000a', 'adam@example.test'),
  ('c1000000-0000-0000-0000-00000000000b', 'sarah@example.test'),
  ('c1000000-0000-0000-0000-00000000000c', 'mounir@example.test');

insert into public.households (id, timezone) values
  ('c1ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('c1ffffff-0000-0000-0000-00000000000b', 'Europe/Paris'),
  ('c1ffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c1000000-0000-0000-0000-000000000001', 'TEACH-C1-00001', 'teacher',
   'c1ffffff-0000-0000-0000-00000000000c', 'Rachid', 'Benali', 'provisional_active', 'male'),
  ('c1000000-0000-0000-0000-000000000002', 'STUD-C1-000001', 'student',
   'c1ffffff-0000-0000-0000-00000000000a', 'Sofia', 'Haddad', 'active', 'female'),
  ('c1000000-0000-0000-0000-000000000003', 'CTRL-C1-000001', 'controller',
   'c1ffffff-0000-0000-0000-00000000000c', 'Nadia', 'Ould', 'active', 'female'),
  ('c1000000-0000-0000-0000-000000000004', 'CTRL-C1-000002', 'controller',
   'c1ffffff-0000-0000-0000-00000000000c', 'Bilal', 'Kacem', 'active', 'male'),
  ('c1000000-0000-0000-0000-000000000005', 'GUAR-C1-000001', 'guardian',
   'c1ffffff-0000-0000-0000-00000000000a', 'Latifa', 'Haddad', 'active', 'female'),
  ('c1000000-0000-0000-0000-000000000006', 'TEACH-C1-00002', 'teacher',
   'c1ffffff-0000-0000-0000-00000000000c', 'Youssef', 'Amrani', 'provisional_active', 'male'),
  ('c1000000-0000-0000-0000-000000000007', 'STUD-C1-000002', 'student',
   'c1ffffff-0000-0000-0000-00000000000b', 'Ines', 'Zerhouni', 'active', 'female'),
  ('c1000000-0000-0000-0000-000000000008', 'ADMIN-C1-00001', 'admin',
   'c1ffffff-0000-0000-0000-00000000000c', 'Amira', 'Sellami', 'active', 'female'),
  ('c1000000-0000-0000-0000-000000000009', 'TEACH-C1-00003', 'teacher',
   'c1ffffff-0000-0000-0000-00000000000c', 'Kenza', 'Berkani', 'provisional_active', 'female'),
  ('c1000000-0000-0000-0000-00000000000a', 'STUD-C1-000003', 'student',
   'c1ffffff-0000-0000-0000-00000000000b', 'Adam', 'Zerhouni', 'active', 'male'),
  ('c1000000-0000-0000-0000-00000000000b', 'STUD-C1-000004', 'student',
   'c1ffffff-0000-0000-0000-00000000000a', 'Sarah', 'Haddad', 'active', 'female'),
  -- Mounir n'existe que pour porter la seance F : `sessions_no_teacher_overlap`
  -- (0005) interdit a un enseignant deux seances qui se recoupent, et les
  -- quatre autres en donnent deja une sur ce creneau.
  ('c1000000-0000-0000-0000-00000000000c', 'TEACH-C1-00004', 'teacher',
   'c1ffffff-0000-0000-0000-00000000000c', 'Mounir', 'Talbi', 'provisional_active', 'male');
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
    INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
    VALUES (v_teacher.id,'teacher_conduct_code',public.code_conduite_version_requise())
    ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
    UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
  END LOOP;
END
$fixture_teacher_contracts$;

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values
  ('c1000000-0000-0000-0000-000000000002', 'minor', 'standard', 'allowed'),
  ('c1000000-0000-0000-0000-000000000007', 'autonomous', 'standard', 'allowed'),
  ('c1000000-0000-0000-0000-00000000000a', 'minor', 'child', 'forbidden'),
  ('c1000000-0000-0000-0000-00000000000b', 'minor', 'standard', 'forbidden');

insert into public.sessions (id, teacher_id, started_at, ended_at, status) values
  ('c1aaaaaa-0000-0000-0000-00000000000a',
   'c1000000-0000-0000-0000-000000000001',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress'),
  ('c1aaaaaa-0000-0000-0000-00000000000d',
   'c1000000-0000-0000-0000-000000000006',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress'),
  ('c1aaaaaa-0000-0000-0000-00000000000b',
   'c1000000-0000-0000-0000-000000000001',
   now() + interval '3 hours', now() + interval '4 hours', 'planned'),
  ('c1aaaaaa-0000-0000-0000-00000000000c',
   'c1000000-0000-0000-0000-000000000006',
   now() - interval '2 hours', now() - interval '1 hour', 'ended'),
  ('c1aaaaaa-0000-0000-0000-00000000000e',
   'c1000000-0000-0000-0000-000000000009',
   now() - interval '5 minutes', now() + interval '55 minutes', 'in_progress'),
  -- Seance F : declaree, sans aucun participant inscrit. Elle n'existe que pour
  -- le controle C3 -- une seance ou le plafond n'est PAS atteint, sans quoi
  -- l'inscription y serait refusee par le plafond avant d'atteindre la regle du
  -- chevauchement, et le controle mesurerait le mauvais mur.
  ('c1aaaaaa-0000-0000-0000-00000000000f',
   'c1000000-0000-0000-0000-00000000000c',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress');

insert into public.session_participants (session_id, profile_id, role) values
  ('c1aaaaaa-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-000000000001', 'teacher'),
  ('c1aaaaaa-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-000000000002', 'student'),
  ('c1aaaaaa-0000-0000-0000-00000000000d', 'c1000000-0000-0000-0000-000000000006', 'teacher'),
  ('c1aaaaaa-0000-0000-0000-00000000000d', 'c1000000-0000-0000-0000-000000000007', 'student'),
  ('c1aaaaaa-0000-0000-0000-00000000000b', 'c1000000-0000-0000-0000-000000000001', 'teacher'),
  ('c1aaaaaa-0000-0000-0000-00000000000b', 'c1000000-0000-0000-0000-000000000002', 'student'),
  ('c1aaaaaa-0000-0000-0000-00000000000c', 'c1000000-0000-0000-0000-000000000006', 'teacher'),
  ('c1aaaaaa-0000-0000-0000-00000000000c', 'c1000000-0000-0000-0000-000000000007', 'student'),
  ('c1aaaaaa-0000-0000-0000-00000000000e', 'c1000000-0000-0000-0000-000000000009', 'teacher'),
  ('c1aaaaaa-0000-0000-0000-00000000000e', 'c1000000-0000-0000-0000-00000000000a', 'student'),
  -- Nadia, temoin d'une seance E a laquelle elle ne pourra donc pas rendre
  -- visite en tant que controleur (ADR-011). Cette ligne n'est possible que
  -- depuis 0012 : avant, le plafond la refusait aussi.
  ('c1aaaaaa-0000-0000-0000-00000000000e', 'c1000000-0000-0000-0000-000000000003', 'guardian_observer');

-- ============================================================
-- C1 : un cours 1-to-1 plein accepte une visite de controle
-- ============================================================
--
-- LE CONTROLE DU LOT. La seance A compte deux participants, c'est-a-dire le
-- plafond du MVP-0. Avant 0012, `guard_session_participant_cap()` comptait
-- toutes les lignes sans regarder leur role et levait « plafond de participants
-- atteint » : aucune visite n'etait possible sur aucun cours, et l'ADR-011
-- etait une fonction confirmee mais inatteignable.

do $$
declare
  v_retour uuid;
  v_lignes int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"controller"}}', true);

  v_retour := public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000a');

  reset role;
  select count(*) into v_lignes from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and profile_id = 'c1000000-0000-0000-0000-000000000003'
     and role = 'masked_controller'
     and deleted_at is null;

  if v_retour is null or v_lignes <> 1 then
    raise exception 'C1 : la visite a laisse % ligne(s) masked_controller, attendu 1', v_lignes;
  end if;
end $$;

-- ============================================================
-- C2 : le plafond tient toujours pour le groupe pedagogique
-- ============================================================
--
-- Non-regression, et c'est la moitie de la decision : 0012 ne leve pas le
-- 1-to-1 (ADR-004), il dit seulement ce que le plafond compte. Un troisieme
-- ELEVE reste refuse, y compris apres une visite de controle.

create temporary table ctr01_config_snapshot as
select key, value
from public.app_config
where key in ('allow_multi_participant_sessions', 'max_participants_per_session');

-- C2 mesure bien le contrat 1-to-1, quelles que soient les mutations des
-- scénarios précédents sur la base partagée.
begin;
insert into public.app_config (key, value)
values ('allow_multi_participant_sessions', 'false'::jsonb),
       ('max_participants_per_session', '2'::jsonb)
on conflict (key) do update set value = excluded.value;

do $$
declare
  v_refuse boolean := false;
  v_message text;
begin
  begin
    insert into public.session_participants (session_id, profile_id, role)
    values ('c1aaaaaa-0000-0000-0000-00000000000a',
            'c1000000-0000-0000-0000-00000000000b', 'student');
  exception when others then
    v_message := sqlerrm;
    v_refuse := (v_message like '%plafond de participants%');
  end;

  if not v_refuse then
    raise exception 'C2 : le troisieme eleve n''a pas ete refuse par le plafond attendu (erreur: %)', v_message;
  end if;
end $$;

-- Restaurer exactement les deux valeurs, et retirer toute cle ajoutée.
update public.app_config current_config
   set value = snapshot.value
  from pg_temp.ctr01_config_snapshot snapshot
 where current_config.key = snapshot.key;

delete from public.app_config current_config
 where current_config.key in ('allow_multi_participant_sessions', 'max_participants_per_session')
   and not exists (
     select 1 from pg_temp.ctr01_config_snapshot snapshot
     where snapshot.key = current_config.key
   );
drop table pg_temp.ctr01_config_snapshot;
commit;

-- ============================================================
-- C3 : deux visites qui se recoupent sont permises, un double
--      engagement pedagogique ne l'est pas
-- ============================================================
--
-- C2 de l'etape 1 protege un enseignant et un eleve d'un double engagement a la
-- meme heure. Un controleur, lui, passe de salle en salle : l'ADR-011 demande
-- meme de surveiller « un volume d'observations anormal sur une journee ».
-- Les seances A et D occupent exactement les memes heures.

do $$
declare
  v_visites int;
  v_refuse  boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"controller"}}', true);

  perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000d');

  reset role;
  select count(*) into v_visites from public.session_participants
   where profile_id = 'c1000000-0000-0000-0000-000000000003'
     and role = 'masked_controller' and deleted_at is null;

  -- Et la regle tient pour qui elle protege : Sofia est deja en cours dans A,
  -- et la seance F occupe les memes heures. F n'a aucun participant, donc le
  -- plafond ne peut pas refuser a la place du chevauchement.
  begin
    insert into public.session_participants (session_id, profile_id, role)
    values ('c1aaaaaa-0000-0000-0000-00000000000f',
            'c1000000-0000-0000-0000-000000000002', 'student');
  exception when others then
    v_refuse := (sqlerrm like '%chevauchement%');
  end;

  if v_visites <> 2 then
    raise exception 'C3 : le controleur tient % visites simultanees, attendu 2', v_visites;
  end if;
  if not v_refuse then
    raise exception 'C3 : une eleve a ete inscrite a deux seances qui se recoupent';
  end if;
end $$;

-- ============================================================
-- C4 : l'enseignant observe ne lit la visite nulle part
-- ============================================================
--
-- Trois surfaces, toutes ouvertes a l'enseignant depuis l'etape 1, et toutes
-- muettes depuis 0012 : la table des participants, la vue des pairs, et la
-- trace d'entree et de sortie. La lecon de N4 appliquee partout ou la personne
-- peut apparaitre.

insert into public.session_events (session_id, profile_id, event_type, source, server_ts)
values
  ('c1aaaaaa-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-000000000002',
   'joined', 'livekit_webhook', now() - interval '9 minutes'),
  ('c1aaaaaa-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-000000000003',
   'joined', 'livekit_webhook', now() - interval '2 minutes');

do $$
declare
  v_participants int;
  v_pairs        int;
  v_evenements   int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select count(*) into v_participants from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a';
  select count(*) into v_pairs from public.session_peers_v
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a';
  select count(*) into v_evenements from public.session_events
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and profile_id = 'c1000000-0000-0000-0000-000000000003';

  -- Deux participants : lui et Sofia. Un pair : Sofia. Zero evenement de la
  -- visiteuse. Sans 0012, c'etait trois, deux et un.
  if v_participants <> 2 or v_pairs <> 1 or v_evenements <> 0 then
    raise exception 'C4 : l''enseignant lit % participants, % pairs, % evenements de la visite ; attendu 2, 1, 0',
      v_participants, v_pairs, v_evenements;
  end if;
end $$;

-- ============================================================
-- C5 : l'eleve et son foyer ne lisent pas la visite non plus
-- ============================================================

do $$
declare
  v_pairs_eleve  int;
  v_part_tuteur  int;
  v_evt_tuteur   int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  select count(*) into v_pairs_eleve from public.session_peers_v
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a';

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"c1ffffff-0000-0000-0000-00000000000a"}}',
    true);

  select count(*) into v_part_tuteur from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and role = 'masked_controller';
  select count(*) into v_evt_tuteur from public.session_events
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and profile_id = 'c1000000-0000-0000-0000-000000000003';

  -- L'eleve lit son enseignant, et lui seul.
  if v_pairs_eleve <> 1 or v_part_tuteur <> 0 or v_evt_tuteur <> 0 then
    raise exception 'C5 : l''eleve lit % pairs, le tuteur % lignes et % evenements de visite ; attendu 1, 0, 0',
      v_pairs_eleve, v_part_tuteur, v_evt_tuteur;
  end if;
end $$;

-- ============================================================
-- C6 : le controle qualite ne lit ni sa visite ni celle d'un
--      collegue, l'administration lit les deux
-- ============================================================
--
-- « Tout le monde sait que la visite est possible. Personne ne sait qu'elle a
-- lieu » (ADR-011). Personne inclut le voisin de bureau : un controleur qui
-- lirait les visites de ses collegues saurait exactement ou ils ne vont jamais.
-- Meme regle que `presence_seance_v` depuis 0011 -- seule l'administration voit.

do $$
declare
  v_par_nadia int;
  v_par_bilal int;
  v_par_admin int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"controller"}}', true);
  perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000a');

  select count(*) into v_par_bilal from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and role = 'masked_controller';

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000003', true);
  select count(*) into v_par_nadia from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and role = 'masked_controller';

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000008', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select count(*) into v_par_admin from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and role = 'masked_controller';

  if v_par_nadia <> 0 or v_par_bilal <> 0 then
    raise exception 'C6 : un controleur lit % et % visites, attendu 0 et 0',
      v_par_nadia, v_par_bilal;
  end if;
  if v_par_admin <> 2 then
    raise exception 'C6 : l''administration lit % visites, attendu 2', v_par_admin;
  end if;
end $$;

-- ============================================================
-- C7 : chaque entree est journalisee, nommement
-- ============================================================
--
-- « Chaque entree ecrit dans le journal d'audit : identite, seance,
-- horodatage » (ADR-011). Deux visites sur la seance A, deux entrees -- et le
-- role de l'acteur, que `log_sensitive_access` ecrit tout seul, dit
-- « controller ».

do $$
declare
  v_entrees int;
  v_acteurs int;
begin
  select count(*) into v_entrees from public.audit_logs
   where action = 'controller_observation_started'
     and row_id = 'c1aaaaaa-0000-0000-0000-00000000000a';
  select count(distinct actor) into v_acteurs from public.audit_logs
   where action = 'controller_observation_started'
     and row_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and actor_role = 'controller';

  if v_entrees <> 2 or v_acteurs <> 2 then
    raise exception 'C7 : le journal porte % entrees de % acteurs, attendu 2 et 2',
      v_entrees, v_acteurs;
  end if;
end $$;

-- ============================================================
-- C8 : la porte refuse tout ce qu'elle doit refuser
-- ============================================================
--
-- Quatre refus, dont trois portent sur la fenetre. Le quatrieme est l'interdit
-- de l'ADR-011 : « ne peut pas observer une seance ou il est lui-meme
-- participant », et il se verifie en base, pas a l'ecran.

do $$
declare
  v_enseignant   boolean := false;
  v_pas_commence boolean := false;
  v_close        boolean := false;
  v_partie       boolean := false;
begin
  set local role authenticated;

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000d');
  exception when others then
    v_enseignant := (sqlerrm like '%controle qualite%');
  end;

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"controller"}}', true);

  begin
    perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000b');
  exception when others then
    v_pas_commence := (sqlerrm like '%pas encore commencee%');
  end;

  begin
    perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000c');
  exception when others then
    v_close := (sqlerrm like '%close%');
  end;

  begin
    perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000e');
  exception when others then
    v_partie := (sqlerrm like '%partie prenante%');
  end;

  if not (v_enseignant and v_pas_commence and v_close and v_partie) then
    raise exception 'C8 : refus manquants -- enseignant %, pas commencee %, close %, partie prenante %',
      v_enseignant, v_pas_commence, v_close, v_partie;
  end if;
end $$;

-- ============================================================
-- C9 : la visite est idempotente
-- ============================================================
--
-- Un rechargement de page, un billet reemis, un retour dans la salle : le
-- deuxieme appel ne doit pas echouer sur la cle primaire. Il laisse en
-- revanche une seconde entree au journal, et c'est voulu -- ce sont deux
-- entrees dans la salle.

do $$
declare
  v_lignes  int;
  v_entrees int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"controller"}}', true);

  perform public.rejoindre_observation('c1aaaaaa-0000-0000-0000-00000000000a');

  reset role;
  select count(*) into v_lignes from public.session_participants
   where session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and profile_id = 'c1000000-0000-0000-0000-000000000003';
  select count(*) into v_entrees from public.audit_logs
   where action = 'controller_observation_started'
     and row_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and actor = 'c1000000-0000-0000-0000-000000000003';

  if v_lignes <> 1 or v_entrees <> 2 then
    raise exception 'C9 : % ligne(s) et % entree(s) de journal, attendu 1 et 2',
      v_lignes, v_entrees;
  end if;
end $$;

-- ============================================================
-- C10 : l'ancienne porte tuteur est fermee, le flux courant verifie le lien
-- ============================================================
--
-- Depuis 0041, assister_seance est retiree car elle contourne quota et trace.
-- Le flux courant entrer_observation exige un groupe et un enfant du foyer :
-- cette seance legacy sans groupe doit donc etre refusee sans inscription.

do $$
declare
  v_result jsonb;
  v_refus_ancienne_porte boolean := false;
  v_refus_enseignant boolean := false;
  v_role public.participant_role;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"c1ffffff-0000-0000-0000-00000000000a"}}',
    true);

  begin
    perform public.assister_seance('c1aaaaaa-0000-0000-0000-00000000000a');
  exception when insufficient_privilege then
    v_refus_ancienne_porte := true;
  end;

  v_result := public.entrer_observation(
    'c1aaaaaa-0000-0000-0000-00000000000a', 'guardian_observer');
  if (v_result->>'autorise')::boolean is distinct from false
     or v_result->>'motif_refus' is distinct from 'lien_tuteur_absent' then
    raise exception 'C10 : une seance sans groupe/enfant lie n''a pas ete refusee, retour %', v_result;
  end if;

  perform set_config('test.uid', 'c1000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.entrer_observation(
      'c1aaaaaa-0000-0000-0000-00000000000a', 'guardian_observer');
  exception when insufficient_privilege then
    v_refus_enseignant := (sqlerrm like '%observation reservee aux tuteurs et a l''administration%');
  end;

  reset role;
  select sp.role into v_role from public.session_participants sp
   where sp.session_id = 'c1aaaaaa-0000-0000-0000-00000000000a'
     and sp.profile_id = 'c1000000-0000-0000-0000-000000000005';

  if not v_refus_ancienne_porte then
    raise exception 'C10 : l''ancienne porte assister_seance reste appelable';
  end if;
  if not v_refus_enseignant then
    raise exception 'F86 ECHEC : l''enseignant valide a pu entrer dans entrer_observation';
  end if;
  if v_role is not null then
    raise exception 'C10 : refus attendu, mais le tuteur a ete inscrit comme %', v_role;
  end if;
end $$;

\ir _acl_retablir.sql
