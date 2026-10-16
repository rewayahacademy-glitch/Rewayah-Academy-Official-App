-- Scenarios d'acceptation SQL de `N4`, la presence : ce que `presence_seance_v`
-- montre a chacun, et ce qu'elle refuse de montrer.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0011. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml`, comme
-- celui de N2 : le controle J4 de ce dernier relit la chaine de hachage de
-- tout ce que les fichiers precedents ont ecrit.
--
-- Le calcul des quatorze etats n'est PAS remesure ici : `scenarios_etape5.sql`
-- le tient depuis N1 et `scenarios_n2.sql` depuis le quatorzieme. Ce fichier
-- mesure la seule chose que N4 change -- qui lit quoi -- et la seule chose que
-- N4 ajoute -- le prenom et la consolidation.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler les restrictions de 0010 sur les
-- fonctions d'emission. En production l'ordre est inverse : les droits par
-- defaut sont accordes a la creation, la migration les restreint ensuite. On
-- rejoue donc la restriction, sans quoi les fichiers suivants mesureraient le
-- harnais et non les migrations.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

-- ============================================================
-- Fixtures : deux seances, deux enseignants, deux foyers
-- ============================================================
--
-- La separation des foyers n'est pas decorative : elle est ce qui rend les
-- controles P1 et P5 concluants. Si l'eleve et son enseignant partageaient un
-- foyer, un eleve qui verrait la ligne de son enseignant passerait pour un
-- effet de la branche « foyer » alors que ce serait la borne qui aurait cede.
--
--   * Seance A, en cours, donnee par Yacine : Maryam et Ilyas y sont eleves,
--     Souad y observe en controleur invisible.
--   * Seance B, en cours aussi, donnee par Hafsa a Zineb. Aucun participant
--     commun avec A : c'est elle qui mesure ce qu'un enseignant ne voit PAS.
--   * Karim est le tuteur du foyer de Maryam et Ilyas.
--   * Tarek n'est inscrit a rien, et c'est lui qui mesure le defaut ferme par
--     la migration 0011.

insert into auth.users (id, email) values
  ('b4000000-0000-0000-0000-000000000001', 'yacine@example.test'),
  ('b4000000-0000-0000-0000-000000000002', 'maryam@example.test'),
  ('b4000000-0000-0000-0000-000000000003', 'ilyas@example.test'),
  ('b4000000-0000-0000-0000-000000000004', 'souad@example.test'),
  ('b4000000-0000-0000-0000-000000000005', 'karim@example.test'),
  ('b4000000-0000-0000-0000-000000000006', 'hafsa@example.test'),
  ('b4000000-0000-0000-0000-000000000007', 'zineb@example.test'),
  ('b4000000-0000-0000-0000-000000000008', 'tarek@example.test'),
  ('b4000000-0000-0000-0000-000000000009', 'amine@example.test');

insert into public.households (id, timezone) values
  ('b4ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('b4ffffff-0000-0000-0000-00000000000b', 'Europe/Paris'),
  ('b4ffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('b4000000-0000-0000-0000-000000000001', 'TEACH-N4-000001', 'teacher',
   'b4ffffff-0000-0000-0000-00000000000c', 'Yacine', 'Belhadj', 'provisional_active', 'male'),
  ('b4000000-0000-0000-0000-000000000002', 'STUD-N4-000001', 'student',
   'b4ffffff-0000-0000-0000-00000000000a', 'Maryam', 'Cherif', 'active', 'female'),
  ('b4000000-0000-0000-0000-000000000003', 'STUD-N4-000002', 'student',
   'b4ffffff-0000-0000-0000-00000000000a', 'Ilyas', 'Cherif', 'active', 'male'),
  ('b4000000-0000-0000-0000-000000000004', 'CTRL-N4-000001', 'controller',
   'b4ffffff-0000-0000-0000-00000000000c', 'Souad', 'Mansouri', 'active', 'female'),
  ('b4000000-0000-0000-0000-000000000005', 'GUAR-N4-000001', 'guardian',
   'b4ffffff-0000-0000-0000-00000000000a', 'Karim', 'Cherif', 'active', 'male'),
  ('b4000000-0000-0000-0000-000000000006', 'TEACH-N4-000002', 'teacher',
   'b4ffffff-0000-0000-0000-00000000000c', 'Hafsa', 'Toumi', 'provisional_active', 'female'),
  ('b4000000-0000-0000-0000-000000000007', 'STUD-N4-000003', 'student',
   'b4ffffff-0000-0000-0000-00000000000b', 'Zineb', 'Toumi', 'active', 'female'),
  ('b4000000-0000-0000-0000-000000000008', 'STUD-N4-000004', 'student',
   'b4ffffff-0000-0000-0000-00000000000b', 'Tarek', 'Saidi', 'active', 'male'),
  ('b4000000-0000-0000-0000-000000000009', 'ADMIN-N4-00001', 'admin',
   'b4ffffff-0000-0000-0000-00000000000c', 'Amine', 'Rahal', 'active', 'male');
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
END
$fixture_teacher_contracts$;

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values
  ('b4000000-0000-0000-0000-000000000002', 'minor', 'standard', 'allowed'),
  ('b4000000-0000-0000-0000-000000000003', 'minor', 'child', 'forbidden'),
  ('b4000000-0000-0000-0000-000000000007', 'autonomous', 'standard', 'allowed'),
  ('b4000000-0000-0000-0000-000000000008', 'autonomous', 'standard', 'allowed');

-- Le MVP-0 plafonne une seance a deux participants. La seance A en compte
-- quatre, comme celle de N2 : on leve le plafond comme l'administration le
-- ferait, et on le repose en fin de fichier -- les scenarios partagent une
-- base, en laisser un ouvert changerait le sens des fichiers suivants.
update public.app_config set value = 'true'::jsonb
 where key = 'allow_multi_participant_sessions';
insert into public.app_config (key, value)
select 'allow_multi_participant_sessions', 'true'::jsonb
 where not exists (select 1 from public.app_config
                    where key = 'allow_multi_participant_sessions');

insert into public.sessions (id, teacher_id, started_at, ended_at, status) values
  ('b4aaaaaa-0000-0000-0000-00000000000a',
   'b4000000-0000-0000-0000-000000000001',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress'),
  ('b4aaaaaa-0000-0000-0000-00000000000b',
   'b4000000-0000-0000-0000-000000000006',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress');

insert into public.session_participants (session_id, profile_id, role) values
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000001', 'teacher'),
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000002', 'student'),
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000003', 'student'),
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000004', 'masked_controller'),
  ('b4aaaaaa-0000-0000-0000-00000000000b', 'b4000000-0000-0000-0000-000000000006', 'teacher'),
  ('b4aaaaaa-0000-0000-0000-00000000000b', 'b4000000-0000-0000-0000-000000000007', 'student');

-- Maryam est entree a l'heure et elle est la. Ilyas est entre puis a perdu le
-- reseau il y a longtemps : sa deconnexion est acquise, pas une reconnexion en
-- cours. Ces deux traces servent au controle P8.
insert into public.session_events (session_id, profile_id, event_type, source, server_ts) values
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000002',
   'joined', 'livekit_webhook', now() - interval '9 minutes'),
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000003',
   'joined', 'livekit_webhook', now() - interval '9 minutes'),
  ('b4aaaaaa-0000-0000-0000-00000000000a', 'b4000000-0000-0000-0000-000000000003',
   'left', 'network', now() - interval '6 minutes');

-- ============================================================
-- P1 : l'eleve ne voit QUE sa propre ligne
-- ============================================================
--
-- Section 6.6 : « son propre etat ; aucun detail administratif, pas les etats
-- des autres ». Maryam partage sa seance avec trois personnes ; elle doit en
-- lire une seule, et ce doit etre elle.

do $$
declare
  v_lignes int;
  v_moi    int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  select count(*) into v_lignes from public.presence_seance_v;
  select count(*) into v_moi from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000002';

  if v_lignes <> 1 or v_moi <> 1 then
    raise exception 'P1 : une eleve lit % lignes (dont % la sienne), attendu 1 et 1',
      v_lignes, v_moi;
  end if;
end $$;

-- ============================================================
-- P2 : l'enseignant voit SA seance entiere, et rien d'une autre
-- ============================================================

do $$
declare
  v_sienne  int;
  v_autre   int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select count(*) into v_sienne from public.presence_seance_v
   where session_id = 'b4aaaaaa-0000-0000-0000-00000000000a';
  select count(*) into v_autre from public.presence_seance_v
   where session_id = 'b4aaaaaa-0000-0000-0000-00000000000b';

  -- Trois : lui et ses deux eleves. Le controleur invisible n'en fait pas
  -- partie -- c'est le controle P10 qui le mesure pour lui-meme.
  if v_sienne <> 3 then
    raise exception 'P2 : l''enseignant lit % lignes de sa seance, attendu 3', v_sienne;
  end if;
  if v_autre <> 0 then
    raise exception 'P2 : l''enseignant lit % lignes de la seance d''une collegue, attendu 0',
      v_autre;
  end if;
end $$;

-- ============================================================
-- P3 : un tiers ne voit RIEN -- le defaut que 0011 ferme
-- ============================================================
--
-- Tarek est un eleve valide de la plateforme, inscrit a aucune de ces deux
-- seances. Avant 0011, la vue n'avait aucun filtre d'appelant et s'executait
-- avec les droits de son proprietaire : il aurait lu les six lignes, donc la
-- presence d'enfants qu'il ne connait pas. C'est LE controle du lot.

do $$
declare
  v_lignes int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000008', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  select count(*) into v_lignes from public.presence_seance_v;
  if v_lignes <> 0 then
    raise exception 'P3 : un tiers lit % lignes de presence, attendu 0', v_lignes;
  end if;
end $$;

-- ============================================================
-- P4 : le controle qualite voit les deux seances (ADR-011)
-- ============================================================

do $$
declare
  v_a int;
  v_b int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);

  select count(*) into v_a from public.presence_seance_v
   where session_id = 'b4aaaaaa-0000-0000-0000-00000000000a';
  select count(*) into v_b from public.presence_seance_v
   where session_id = 'b4aaaaaa-0000-0000-0000-00000000000b';

  -- Trois et deux : il lit exactement ce que chaque enseignant lit de sa
  -- propre seance, lui-meme exclu. C'est le test visuel de l'ADR-011 porte
  -- jusque dans la presence -- s'il lisait quatre lignes de la seance A, son
  -- ecran montrerait une personne de plus que celui de l'enseignant.
  if v_a <> 3 or v_b <> 2 then
    raise exception 'P4 : le controleur lit % et % lignes, attendu 3 et 2', v_a, v_b;
  end if;
end $$;

-- ============================================================
-- P5 : le tuteur voit son foyer, et son foyer seulement
-- ============================================================
--
-- Karim doit lire ses deux enfants, et **pas** l'enseignant qui leur fait
-- cours : il n'est pas de son foyer. C'est la difference entre « suivre ses
-- enfants » et « surveiller un enseignant ».

do $$
declare
  v_enfants int;
  v_hors    int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"b4ffffff-0000-0000-0000-00000000000a"}}',
    true);

  select count(*) into v_enfants from public.presence_seance_v
   where profile_id in ('b4000000-0000-0000-0000-000000000002',
                        'b4000000-0000-0000-0000-000000000003');
  select count(*) into v_hors from public.presence_seance_v
   where profile_id not in ('b4000000-0000-0000-0000-000000000002',
                            'b4000000-0000-0000-0000-000000000003');

  if v_enfants <> 2 then
    raise exception 'P5 : le tuteur lit % de ses enfants, attendu 2', v_enfants;
  end if;
  if v_hors <> 0 then
    raise exception 'P5 : le tuteur lit % lignes hors de son foyer, attendu 0', v_hors;
  end if;
end $$;

-- ============================================================
-- P6 : la vue porte un prenom, et jamais un nom de famille (ADR-008)
-- ============================================================

do $$
declare
  v_prenom text;
  v_id     text;
  v_noms   int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select prenom, identifiant_immuable into v_prenom, v_id
    from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000002';

  if v_prenom <> 'Maryam' or v_id <> 'STUD-N4-000001' then
    raise exception 'P6 : la vue rend (%, %), attendu (Maryam, STUD-N4-000001)',
      v_prenom, v_id;
  end if;

  select count(*) into v_noms from information_schema.columns
   where table_schema = 'public' and table_name = 'presence_seance_v'
     and column_name in ('last_name', 'nom', 'nom_famille');
  if v_noms <> 0 then
    raise exception 'P6 : la vue expose % colonne(s) de nom de famille, attendu 0', v_noms;
  end if;
end $$;

-- ============================================================
-- P7 : provisoire contre consolide, sans jamais dire pourquoi
-- ============================================================
--
-- Section 6.6 : l'enseignant doit distinguer ce qui est provisoire de ce qui
-- est finalise. Section 6.6 encore : l'eleve n'a droit a aucun detail
-- administratif. Les deux tiennent ensemble parce que la vue porte le FAIT
-- d'une decision, jamais son motif.

do $$
declare
  v_avant  boolean;
  v_apres  boolean;
  v_quand  timestamptz;
  v_motifs int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select consolide into v_avant from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000003';
  if v_avant is not false then
    raise exception 'P7 : un etat calcule se dit consolide (%)', v_avant;
  end if;

  insert into public.session_presence_override
    (session_id, profile_id, etat, motif, decide_par)
  values ('b4aaaaaa-0000-0000-0000-00000000000a',
          'b4000000-0000-0000-0000-000000000003',
          'excusee', 'panne de reseau chez le foyer',
          'b4000000-0000-0000-0000-000000000001');

  select consolide, consolide_le into v_apres, v_quand
    from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000003';
  if v_apres is not true or v_quand is null then
    raise exception 'P7 : une decision humaine ne consolide pas l''etat (%, %)',
      v_apres, v_quand;
  end if;

  select count(*) into v_motifs from information_schema.columns
   where table_schema = 'public' and table_name = 'presence_seance_v'
     and column_name in ('motif', 'decide_par');
  if v_motifs <> 0 then
    raise exception 'P7 : la vue expose % colonne(s) de decision, attendu 0', v_motifs;
  end if;
end $$;

-- ============================================================
-- P8 : l'etat derive traverse la vue sans se perdre
-- ============================================================
--
-- Le calcul est mesure ailleurs ; ce qui se mesure ici est que la vue rende
-- bien ce que `etat_presence()` a calcule, et non une valeur par defaut. Le
-- couple choisi est le plus facile a confondre : Maryam est presente, Ilyas
-- s'est fait couper le reseau il y a six minutes -- soit trois fois la fenetre
-- de reconnexion -- et sa decision d'excuse vient d'etre posee par P7, donc
-- elle prime sur le calcul. C'est l'invariant « une decision humaine prime
-- toujours » de 0007, vu depuis la vue.

do $$
declare
  v_maryam public.presence_state;
  v_ilyas  public.presence_state;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  select etat into v_maryam from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000002';
  select etat into v_ilyas from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000003';

  if v_maryam <> 'presente' then
    raise exception 'P8 : Maryam est %, attendu presente', v_maryam;
  end if;
  if v_ilyas <> 'excusee' then
    raise exception 'P8 : Ilyas est %, attendu excusee (la decision prime)', v_ilyas;
  end if;
end $$;

-- ============================================================
-- P9 : l'administration voit tout, sans etre inscrite nulle part
-- ============================================================

do $$
declare
  v_lignes int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000009', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select count(*) into v_lignes from public.presence_seance_v
   where session_id in ('b4aaaaaa-0000-0000-0000-00000000000a',
                        'b4aaaaaa-0000-0000-0000-00000000000b');
  -- Six, controleur compris : l'administration est la seule a qui une visite
  -- de controle reste lisible, parce que c'est elle qui la commande.
  if v_lignes <> 6 then
    raise exception 'P9 : l''administration lit % lignes, attendu 6', v_lignes;
  end if;
end $$;

-- ============================================================
-- P10 : une visite de controle ne laisse aucune ligne lisible
-- ============================================================
--
-- L'ADR-011 veut qu'une observation soit imperceptible. N3 la retire de la
-- scene -- jeton `hidden`, et le controleur absent de sa propre liste. Mais la
-- presence l'aurait ecrite en toutes lettres : l'enseignant aurait lu une
-- quatrieme ligne, « masked_controller, presente », c'est-a-dire la visite.
-- Trois regards, une seule reponse : personne, pas meme l'interesse.

do $$
declare
  v_par_enseignant int;
  v_par_eleve      int;
  v_par_lui_meme   int;
begin
  set local role authenticated;

  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  select count(*) into v_par_enseignant from public.presence_seance_v
   where role = 'masked_controller';

  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
  select count(*) into v_par_eleve from public.presence_seance_v
   where role = 'masked_controller';

  perform set_config('test.uid', 'b4000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);
  select count(*) into v_par_lui_meme from public.presence_seance_v
   where profile_id = 'b4000000-0000-0000-0000-000000000004';

  if v_par_enseignant <> 0 or v_par_eleve <> 0 or v_par_lui_meme <> 0 then
    raise exception 'P10 : la visite de controle se lit (% par l''enseignant, % par l''eleve, % par lui-meme), attendu 0 partout',
      v_par_enseignant, v_par_eleve, v_par_lui_meme;
  end if;
end $$;

-- ============================================================
-- Remise en etat : le plafond de participants revient a sa valeur du MVP-0
-- ============================================================

update public.app_config set value = 'false'::jsonb
 where key = 'allow_multi_participant_sessions';

\ir _acl_retablir.sql
