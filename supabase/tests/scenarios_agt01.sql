-- Scenarios d'acceptation SQL de `AGT-01`, l'acces des agents IA (ADR-025) :
-- ce que le jeton d'observation ouvre, ce qu'il refuse, et ce qu'il laisse lire
-- -- de qui.
--
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente d'un
-- « pas d'erreur ». Les six controles qui comptent sont `A6` (l'agent ne peut
-- rien ecrire), `A7` (son plafond est l'ecran de la personne observee), `A8`
-- (le masquage est DUR, pas un rendu), `A10` (les tables fermees le sont),
-- `A11` (la revocation mord a la requete suivante) et `A13` (une session
-- humaine n'a rien perdu au passage).
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0014. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme base :
-- il insere ses fixtures.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml`, pour la
-- meme raison que `scenarios_ctr01.sql` : `creer_jeton_agent()` et
-- `remettre_session_agent()` ecrivent dans `audit_logs`, et le controle `J4` du
-- journal relit la chaine de hachage de tout ce que les fichiers precedents y
-- ont ecrit.

-- Droits facon Supabase (alter default privileges du projet).
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler les restrictions de 0010 et de 0014 sur
-- les fonctions reservees. On les rejoue, sans quoi les fichiers suivants
-- mesureraient le harnais et non les migrations.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

revoke execute on function
  public.remettre_session_agent(text),
  public.agent_jeton_vivant(uuid)
  from anon, authenticated, public;

-- ============================================================
-- Fixtures : un cours 1-to-1, un foyer, une administration
-- ============================================================
--
--   * Yacine enseigne a Maryam, seance en cours. Deux participants : le plafond
--     du MVP-0 n'a pas besoin d'etre leve, contrairement a N4.
--   * Karim est le tuteur du foyer de Maryam.
--   * Hafsa enseigne a Zineb, dans un autre foyer. C'est la seance temoin :
--     rien de ce qui la concerne ne doit atteindre un agent qui observe Maryam.
--   * Amine est l'administration : lui seul emet et revoque.

insert into auth.users (id, email) values
  ('a7000000-0000-0000-0000-000000000001', 'yacine.agt@example.test'),
  ('a7000000-0000-0000-0000-000000000002', 'maryam.agt@example.test'),
  ('a7000000-0000-0000-0000-000000000003', 'karim.agt@example.test'),
  ('a7000000-0000-0000-0000-000000000004', 'amine.agt@example.test'),
  ('a7000000-0000-0000-0000-000000000005', 'hafsa.agt@example.test'),
  ('a7000000-0000-0000-0000-000000000006', 'zineb.agt@example.test');

insert into public.households (id, timezone) values
  ('a7ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('a7ffffff-0000-0000-0000-00000000000b', 'Europe/Paris'),
  ('a7ffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('a7000000-0000-0000-0000-000000000001', 'TEACH-A7-000001', 'teacher',
   'a7ffffff-0000-0000-0000-00000000000c', 'Yacine', 'Belhadj', 'active', 'male'),
  ('a7000000-0000-0000-0000-000000000002', 'STUD-A7-000001', 'student',
   'a7ffffff-0000-0000-0000-00000000000a', 'Maryam', 'Cherif', 'active', 'female'),
  ('a7000000-0000-0000-0000-000000000003', 'GUAR-A7-000001', 'guardian',
   'a7ffffff-0000-0000-0000-00000000000a', 'Karim', 'Cherif', 'active', 'male'),
  ('a7000000-0000-0000-0000-000000000004', 'ADMIN-A7-00001', 'admin',
   'a7ffffff-0000-0000-0000-00000000000c', 'Amine', 'Rahal', 'active', 'male'),
  ('a7000000-0000-0000-0000-000000000005', 'TEACH-A7-000002', 'teacher',
   'a7ffffff-0000-0000-0000-00000000000c', 'Hafsa', 'Toumi', 'active', 'female'),
  ('a7000000-0000-0000-0000-000000000006', 'STUD-A7-000002', 'student',
   'a7ffffff-0000-0000-0000-00000000000b', 'Zineb', 'Toumi', 'active', 'female');

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values
  ('a7000000-0000-0000-0000-000000000002', 'minor', 'standard', 'allowed'),
  ('a7000000-0000-0000-0000-000000000006', 'autonomous', 'standard', 'allowed');

insert into public.sessions (id, teacher_id, started_at, ended_at, status) values
  ('a7aaaaaa-0000-0000-0000-00000000000a',
   'a7000000-0000-0000-0000-000000000001',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress'),
  ('a7aaaaaa-0000-0000-0000-00000000000b',
   'a7000000-0000-0000-0000-000000000005',
   now() - interval '10 minutes', now() + interval '50 minutes', 'in_progress');

insert into public.session_participants (session_id, profile_id, role) values
  ('a7aaaaaa-0000-0000-0000-00000000000a', 'a7000000-0000-0000-0000-000000000001', 'teacher'),
  ('a7aaaaaa-0000-0000-0000-00000000000a', 'a7000000-0000-0000-0000-000000000002', 'student'),
  ('a7aaaaaa-0000-0000-0000-00000000000b', 'a7000000-0000-0000-0000-000000000005', 'teacher'),
  ('a7aaaaaa-0000-0000-0000-00000000000b', 'a7000000-0000-0000-0000-000000000006', 'student');

insert into public.session_events (session_id, profile_id, event_type, source, server_ts) values
  ('a7aaaaaa-0000-0000-0000-00000000000a', 'a7000000-0000-0000-0000-000000000002',
   'joined', 'livekit_webhook', now() - interval '9 minutes');

-- Les jetons emis par ce fichier voyagent d'un controle a l'autre : les blocs
-- `do` ne partagent pas de variables.
create table agt_fixture (cle text primary key, valeur text);

-- ============================================================
-- A1 : l'emission rend le secret UNE fois, et la base ne le garde pas
-- ============================================================

do $$
declare
  v_secret text;
  v_id     uuid;
  v_exp    timestamptz;
  v_stocke int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select jeton, jeton_id, expire_le into v_secret, v_id, v_exp
  from public.creer_jeton_agent(
    'Observation Maryam (masque)', 'a7000000-0000-0000-0000-000000000002', 8, true);

  if v_secret is null or v_secret !~ '^rag_[0-9a-f]{64}$' then
    raise exception 'A1 : le secret rendu ne respecte pas la forme attendue : %', v_secret;
  end if;

  set local role postgres;

  -- Le secret ne doit se retrouver dans AUCUNE colonne textuelle de la ligne.
  select count(*) into v_stocke
  from public.jetons_agent t
  where t.id = v_id
    and (t.empreinte = v_secret or t.prefixe = v_secret or t.libelle = v_secret);
  if v_stocke <> 0 then
    raise exception 'A1 : le secret est stocke en clair dans jetons_agent';
  end if;

  insert into agt_fixture values
    ('jeton_masque', v_secret),
    ('id_masque', v_id::text);
end $$;

-- ============================================================
-- A2 : personne d'autre que l'administration n'emet
-- ============================================================

do $$
declare
  v_role text;
begin
  foreach v_role in array array['teacher', 'guardian', 'student', 'controller', 'accountant']
  loop
    begin
      set local role authenticated;
      perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000001', true);
      perform set_config('test.jwt',
        format('{"app_metadata":{"role":"%s"}}', v_role), true);

      perform public.creer_jeton_agent(
        'tentative', 'a7000000-0000-0000-0000-000000000002', 4, true);

      raise exception 'A2 : le parcours % a pu emettre un jeton', v_role;
    exception when insufficient_privilege then
      null;   -- attendu
    end;
  end loop;
end $$;

-- ============================================================
-- A3 : la duree est plafonnee cote SERVEUR
-- ============================================================
--
-- Lecon PISI : « plafonnee a 24 h cote SERVEUR (masquer un bouton n'empeche pas
-- d'appeler l'action) ». On appelle donc la fonction directement, sans passer
-- par l'ecran qui propose 8 heures.

do $$
declare
  v_duree int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  foreach v_duree in array array[25, 48, 720, 0, -1]
  loop
    begin
      perform public.creer_jeton_agent(
        'trop long', 'a7000000-0000-0000-0000-000000000002', v_duree, true);
      raise exception 'A3 : une duree de % heures a ete acceptee', v_duree;
    exception when invalid_parameter_value then
      null;   -- attendu
    end;
  end loop;
end $$;

-- ============================================================
-- A4 : la portee d'un jeton ne se releve pas
-- ============================================================
--
-- Meme depuis `postgres`, c'est-a-dire meme pour qui detient la base : le
-- declencheur s'applique a tout le monde. Pour changer de portee, on emet un
-- autre jeton.

do $$
declare
  v_id uuid := (select valeur::uuid from agt_fixture where cle = 'id_masque');
begin
  set local role postgres;

  begin
    update public.jetons_agent set parcours = 'admin' where id = v_id;
    raise exception 'A4 : le parcours d un jeton a pu etre releve';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.jetons_agent
       set profil_observe = 'a7000000-0000-0000-0000-000000000006' where id = v_id;
    raise exception 'A4 : la personne observee a pu etre changee';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.jetons_agent
       set expire_le = now() + interval '20 hours' where id = v_id;
    raise exception 'A4 : l expiration a pu etre repoussee';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.jetons_agent set identite_masquee = false where id = v_id;
    raise exception 'A4 : le masquage a pu etre leve apres coup';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- A5 : la remise refuse, et refuse de la meme facon
-- ============================================================
--
-- « Jeton inconnu » et « jeton expire » se distinguent pour le porteur
-- legitime, pas pour celui qui essaie des jetons au hasard : les deux rendent
-- le meme message.

do $$
declare
  v_msg_inconnu text;
  v_msg_revoque text;
  v_secret text;
  v_id uuid;
begin
  set local role postgres;

  -- Un jeton jetable, revoque aussitot, pour comparer les deux refus.
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select jeton, jeton_id into v_secret, v_id
  from public.creer_jeton_agent(
    'jetable', 'a7000000-0000-0000-0000-000000000002', 1, true);
  perform public.revoquer_jeton_agent(v_id);

  begin
    perform public.remettre_session_agent('rag_inexistant');
    raise exception 'A5 : un jeton inconnu a ete accepte';
  exception when invalid_authorization_specification then
    get stacked diagnostics v_msg_inconnu = message_text;
  end;

  begin
    perform public.remettre_session_agent(v_secret);
    raise exception 'A5 : un jeton revoque a ete accepte';
  exception when invalid_authorization_specification then
    get stacked diagnostics v_msg_revoque = message_text;
  end;

  if v_msg_inconnu is distinct from v_msg_revoque then
    raise exception 'A5 : les refus se distinguent (% vs %) et renseignent l attaquant',
      v_msg_inconnu, v_msg_revoque;
  end if;
end $$;

-- ============================================================
-- A6 : L'AGENT NE PEUT RIEN ECRIRE -- le controle du lot
-- ============================================================
--
-- Pas « l'interface ne propose pas d'ecrire » : le moteur refuse. On attaque
-- donc en SQL direct, ce que fait un agent qui rejoue une requete a la main.

do $$
declare
  v_jwt text;
begin
  v_jwt := format('{"app_metadata":{"role":"student","household_id":"%s","agent_token_id":"%s"}}',
                  'a7ffffff-0000-0000-0000-00000000000a',
                  (select valeur from agt_fixture where cle = 'id_masque'));

  set local role agent_ro;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);

  begin
    insert into public.session_events (session_id, profile_id, event_type, source)
    values ('a7aaaaaa-0000-0000-0000-00000000000a',
            'a7000000-0000-0000-0000-000000000002', 'left', 'network');
    raise exception 'A6 : un agent a pu INSERER un evenement de seance';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.sessions set status = 'canceled'
     where id = 'a7aaaaaa-0000-0000-0000-00000000000a';
    raise exception 'A6 : un agent a pu ANNULER une seance';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.session_participants
     where session_id = 'a7aaaaaa-0000-0000-0000-00000000000a';
    raise exception 'A6 : un agent a pu SUPPRIMER des participants';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.profiles set first_name = 'pirate'
     where id = 'a7000000-0000-0000-0000-000000000002';
    raise exception 'A6 : un agent a pu MODIFIER un profil';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.jetons_agent
      (libelle, prefixe, empreinte, profil_observe, parcours, expire_le, cree_par)
    values ('auto-promotion', 'rag_xxxxxxxx', 'xx',
            'a7000000-0000-0000-0000-000000000002', 'admin',
            now() + interval '1 hour', 'a7000000-0000-0000-0000-000000000002');
    raise exception 'A6 : un agent a pu s emettre un jeton';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- A7 : le plafond d'un agent est l'ecran de la personne observee
-- ============================================================
--
-- Aucune regle nouvelle n'a ete ecrite pour l'agent : ce controle mesure que
-- les bornes deja posees par 0011 pour une eleve (« sa propre ligne, et rien
-- d'autre ») s'appliquent telles quelles a l'agent qui l'observe.

do $$
declare
  v_jwt      text;
  v_presence int;
  v_moi      int;
  v_miennes  int;
  v_autres   int;
begin
  v_jwt := format('{"app_metadata":{"role":"student","household_id":"%s","agent_token_id":"%s"}}',
                  'a7ffffff-0000-0000-0000-00000000000a',
                  (select valeur from agt_fixture where cle = 'id_masque'));

  set local role agent_ro;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);

  select count(*) into v_presence from public.presence_seance_v;
  select count(*) into v_moi from public.presence_seance_v
   where profile_id = 'a7000000-0000-0000-0000-000000000002';
  if v_presence <> 1 or v_moi <> 1 then
    raise exception 'A7 : l agent lit % lignes de presence (dont % celle de l observee), attendu 1 et 1',
      v_presence, v_moi;
  end if;

  select count(*) into v_miennes from public.mes_seances_v
   where session_id = 'a7aaaaaa-0000-0000-0000-00000000000a';
  select count(*) into v_autres from public.mes_seances_v
   where session_id = 'a7aaaaaa-0000-0000-0000-00000000000b';
  if v_miennes < 1 then
    raise exception 'A7 : l agent ne lit pas la seance de la personne observee';
  end if;
  if v_autres <> 0 then
    raise exception 'A7 : l agent lit % ligne(s) de la seance d un autre foyer', v_autres;
  end if;
end $$;

-- ============================================================
-- A8 : LE MASQUAGE EST DUR -- le prenom ne quitte pas la base
-- ============================================================
--
-- Ce n'est pas un rendu : la vue substitue l'identifiant immuable au prenom, et
-- `profiles` ne rend qu'une seule ligne. Un agent qui rejouerait la requete a la
-- main obtiendrait la meme chose.

do $$
declare
  v_jwt     text;
  v_prenom  text;
  v_profils int;
  v_fuite   int;
begin
  v_jwt := format('{"app_metadata":{"role":"student","household_id":"%s","agent_token_id":"%s"}}',
                  'a7ffffff-0000-0000-0000-00000000000a',
                  (select valeur from agt_fixture where cle = 'id_masque'));

  set local role agent_ro;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);

  select prenom into v_prenom from public.presence_seance_v
   where profile_id = 'a7000000-0000-0000-0000-000000000002';
  if v_prenom <> 'STUD-A7-000001' then
    raise exception 'A8 : la vue rend « % » au lieu de l identifiant immuable', v_prenom;
  end if;

  -- Le pair de la seance : son prenom non plus ne doit pas sortir.
  select count(*) into v_fuite from public.session_peers_v
   where first_name = 'Yacine';
  if v_fuite <> 0 then
    raise exception 'A8 : le prenom d un pair a traverse le masquage';
  end if;

  select count(*) into v_profils from public.profiles;
  if v_profils <> 1 then
    raise exception 'A8 : l agent masquant lit % profils, attendu 1 (la personne observee)',
      v_profils;
  end if;
end $$;

-- ============================================================
-- A9 : le masquage est pilote par la LIGNE EN BASE, pas par une constante
-- ============================================================
--
-- Un jeton nominatif rend le prenom. C'est ce qui prouve que `A8` mesure bien
-- la portee lue en base, et non un masquage fige dans la vue.

do $$
declare
  v_secret text;
  v_id     uuid;
  v_jwt    text;
  v_prenom text;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select jeton, jeton_id into v_secret, v_id
  from public.creer_jeton_agent(
    'Observation Maryam (nominatif)', 'a7000000-0000-0000-0000-000000000002', 2, false);

  v_jwt := format('{"app_metadata":{"role":"student","household_id":"%s","agent_token_id":"%s"}}',
                  'a7ffffff-0000-0000-0000-00000000000a', v_id);

  set local role agent_ro;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);

  select prenom into v_prenom from public.presence_seance_v
   where profile_id = 'a7000000-0000-0000-0000-000000000002';
  if v_prenom <> 'Maryam' then
    raise exception 'A9 : un jeton nominatif rend « % » au lieu du prenom', v_prenom;
  end if;

  set local role postgres;
  insert into agt_fixture values ('jeton_nominatif', v_secret), ('id_nominatif', v_id::text);
end $$;

-- ============================================================
-- A10 : les tables fermees le sont
-- ============================================================
--
-- Une piece d'identite de mineur, une empreinte d'appareil, la trace d'audit et
-- la liste des jetons : quatre choses qu'une observation n'a aucune raison de
-- traverser. Le refus vient du privilege, pas d'une policy -- donc il est
-- bruyant, et non un resultat vide qu'on prendrait pour « rien a voir ».

do $$
declare
  v_jwt   text;
  v_table text;
begin
  v_jwt := format('{"app_metadata":{"role":"student","household_id":"%s","agent_token_id":"%s"}}',
                  'a7ffffff-0000-0000-0000-00000000000a',
                  (select valeur from agt_fixture where cle = 'id_masque'));

  set local role agent_ro;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);

  foreach v_table in array array['kyc_documents', 'devices', 'audit_logs', 'jetons_agent']
  loop
    begin
      execute format('select count(*) from public.%I', v_table);
      raise exception 'A10 : un agent a pu lire public.%', v_table;
    exception when insufficient_privilege then null;
    end;
  end loop;
end $$;

-- ============================================================
-- A11 : la revocation mord, sans attendre l'expiration du jeton signe
-- ============================================================
--
-- C'est la regle 3 de l'en-tete de 0014 : le JWT ne porte que l'identifiant, la
-- vivacite se lit en base a chaque requete. Un jeton signe pour huit heures et
-- revoque a la minute est mort a la requete suivante.

do $$
declare
  v_id  uuid := (select valeur::uuid from agt_fixture where cle = 'id_nominatif');
  v_jwt text;
begin
  v_jwt := format('{"sub":"%s","app_metadata":{"role":"student","agent_token_id":"%s"}}', v_id, v_id);

  set local role postgres;
  perform set_config('test.jwt', v_jwt, true);
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);

  -- Vivant : le garde laisse passer.
  perform public.agent_pre_request();

  -- Revoque par l'administration.
  set local role authenticated;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  if not public.revoquer_jeton_agent(v_id) then
    raise exception 'A11 : la revocation n a rien trouve a revoquer';
  end if;

  -- Mort : le garde refuse, alors que le jeton signe court toujours.
  set local role postgres;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', v_jwt, true);
  begin
    perform public.agent_pre_request();
    raise exception 'A11 : le garde central laisse passer un jeton revoque';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- A12 : seul le hook d'agent, sans mutation métier, est volatile et appelable
-- ============================================================
--
-- SEC-01 exige set_config(..., true) pour adapter auth.uid() dans la
-- transaction PostgREST. Le hook reste SECURITY DEFINER, sans argument et ne
-- fait que lire les portées puis modifier un GUC transaction-local. Toute
-- autre fonction volatile applicative reste interdite à agent_ro.

do $$
declare
  v_n      int;
  v_detail text;
  v_hook_ok boolean;
begin
  select count(*), string_agg(p.proname, ', ')
    into v_n, v_detail
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prokind = 'f'
    and p.provolatile = 'v'
    and has_function_privilege('agent_ro', p.oid, 'EXECUTE')
    and p.oid <> to_regprocedure('public.agent_pre_request()')
    -- Les fonctions d'extension sont hors sujet : `btree_gist` est installe
    -- dans `public` par 0005, et ses fonctions de support d'index restent
    -- ouvertes a PUBLIC.
    and not exists (
      select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e'
    );
  if v_n > 0 then
    raise exception 'A12 : agent_ro peut appeler % fonction(s) volatile(s) hors hook : %',
      v_n, v_detail;
  end if;

  select p.provolatile = 'v'
     and p.prosecdef
     and p.pronargs = 0
     and p.prorettype = 'void'::regtype
     and has_function_privilege('agent_ro', p.oid, 'EXECUTE')
    into v_hook_ok
  from pg_proc p
  where p.oid = to_regprocedure('public.agent_pre_request()');
  if coalesce(v_hook_ok, false) IS NOT TRUE then
    raise exception 'A12 : agent_pre_request absent ou privilèges hook incomplets';
  end if;

  SELECT EXISTS (
    SELECT 1
      FROM pg_proc p
      CROSS JOIN LATERAL aclexplode(
        coalesce(p.proacl, acldefault('f', p.proowner))
      ) privilege
     WHERE p.oid = to_regprocedure('public.agent_pre_request()')
       AND privilege.grantee = 0
       AND privilege.privilege_type = 'EXECUTE'
  ) INTO v_public_execute;
  IF v_public_execute THEN
    RAISE EXCEPTION 'A12: agent_pre_request keeps default PUBLIC EXECUTE';
  END IF;

  select count(*), string_agg(distinct c.relname, ', ')
    into v_n, v_detail
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm', 'f')
    and (has_table_privilege('agent_ro', c.oid, 'INSERT')
      or has_table_privilege('agent_ro', c.oid, 'UPDATE')
      or has_table_privilege('agent_ro', c.oid, 'DELETE'));
  if v_n > 0 then
    raise exception 'A12 : agent_ro peut ecrire sur % objet(s) : %', v_n, v_detail;
  end if;
end $$;

-- ============================================================
-- A13 : une session humaine n'a rien perdu au passage
-- ============================================================
--
-- 0014 a reecrit huit vues que TOUT le monde lit. Ce controle est la garantie
-- anti-regression : hors session d'agent, le prenom reste le prenom, et le
-- perimetre de chacun est inchange.

do $$
declare
  v_prenom  text;
  v_lignes  int;
  v_tuteur  int;
begin
  -- L'eleve elle-meme.
  set local role authenticated;
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"a7ffffff-0000-0000-0000-00000000000a"}}', true);

  if public.app_est_agent() then
    raise exception 'A13 : une session humaine se declare session d agent';
  end if;
  if public.agent_identite_masquee() then
    raise exception 'A13 : une session humaine subit le masquage';
  end if;

  select prenom, count(*) over () into v_prenom, v_lignes
  from public.presence_seance_v
  where profile_id = 'a7000000-0000-0000-0000-000000000002';
  if v_prenom <> 'Maryam' then
    raise exception 'A13 : l eleve lit « % » au lieu de son prenom', v_prenom;
  end if;
  if v_lignes <> 1 then
    raise exception 'A13 : l eleve lit % lignes de presence, attendu 1', v_lignes;
  end if;

  -- Le tuteur du foyer.
  perform set_config('test.uid', 'a7000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"a7ffffff-0000-0000-0000-00000000000a"}}', true);

  select count(*) into v_tuteur from public.profils_du_foyer_v
   where first_name = 'Maryam';
  if v_tuteur <> 1 then
    raise exception 'A13 : le tuteur ne lit plus le prenom de son enfant (% ligne(s))', v_tuteur;
  end if;

  -- Le garde central ne coute rien a une session humaine et ne refuse rien.
  set local role postgres;
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
  perform public.agent_pre_request();
end $$;

-- ============================================================
-- Nettoyage : rendre la base a l'etat ou les fichiers suivants l'attendent
-- ============================================================
--
-- Les scenarios partagent une base. Les jetons de ce fichier sont revoques :
-- en laisser un vivant changerait le sens d'un controle ulterieur.

do $$
begin
  set local role postgres;
  update public.jetons_agent
     set revoque_le = coalesce(revoque_le, now())
   where revoque_le is null;
end $$;

drop table agt_fixture;

-- SEC-01 identity resolution uses the real PostgREST JWT request GUCs.
\ir scenarios_agent_identity.sql
