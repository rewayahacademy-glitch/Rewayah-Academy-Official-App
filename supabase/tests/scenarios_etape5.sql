-- Scenarios d'acceptation SQL du lot N1 (etape 5).
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0007. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler les restrictions posees par 0007. En
-- production l'ordre est inverse : les droits par defaut sont accordes a la
-- creation de la table, la migration restreint ensuite. On rejoue donc les
-- restrictions, sans quoi les scenarios 2 et 5 mesureraient le harnais et non
-- la migration.
revoke insert, update, delete on public.mushaf, public.sourate, public.juz,
  public.page_mushaf, public.verset from authenticated;

-- ============================================================
-- Fixtures : un foyer, un eleve, un tuteur, un enseignant, un admin
-- ============================================================

insert into auth.users (id, email) values
  ('50000000-0000-0000-0000-000000000001', 'tuteur5@example.test'),
  ('50000000-0000-0000-0000-000000000002', 'eleve5@example.test'),
  ('50000000-0000-0000-0000-000000000003', 'enseignant5@example.test'),
  ('50000000-0000-0000-0000-000000000004', 'admin5@example.test'),
  ('50000000-0000-0000-0000-000000000005', 'tuteurAilleurs@example.test');

insert into public.households (id, timezone) values
  ('5fffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('5fffffff-0000-0000-0000-00000000000b', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('50000000-0000-0000-0000-000000000001', 'GUARD-N1-000001', 'guardian',
   '5fffffff-0000-0000-0000-00000000000a', 'Aissatou', 'Balde', 'active', 'female'),
  ('50000000-0000-0000-0000-000000000002', 'STUD-N1-000001', 'student',
   '5fffffff-0000-0000-0000-00000000000a', 'Yacine', 'Balde', 'active', null),
  ('50000000-0000-0000-0000-000000000003', 'TEACH-N1-000001', 'teacher',
   '5fffffff-0000-0000-0000-00000000000b', 'Omar', 'Sy', 'provisional_active', 'male'),
  ('50000000-0000-0000-0000-000000000004', 'ADMIN-N1-000001', 'admin',
   '5fffffff-0000-0000-0000-00000000000b', 'Nadia', 'Cherif', 'active', 'female'),
  ('50000000-0000-0000-0000-000000000005', 'GUARD-N1-000002', 'guardian',
   '5fffffff-0000-0000-0000-00000000000b', 'Karim', 'Toure', 'active', 'male');
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

update public.households set primary_guardian_id = '50000000-0000-0000-0000-000000000001'
 where id = '5fffffff-0000-0000-0000-00000000000a';

insert into public.student_profiles (profile_id) values
  ('50000000-0000-0000-0000-000000000002');

insert into public.teacher_profiles (profile_id) values
  ('50000000-0000-0000-0000-000000000003');

-- Un fragment de Coran : la page, la sourate, deux versets.
--
-- **Ces quatre inserts ne posent plus rien depuis le lot N5.** Ils dataient de
-- N1, quand le corpus n'existait pas et qu'il fallait bien un verset pour
-- mesurer une policy. La migration `0013` importe desormais les 114 sourates,
-- les 30 juz, les 604 pages et les 6236 versets reels : chacun de ces inserts
-- entre donc en conflit de cle avec une ligne qui dit vrai, et c'est la ligne
-- qui dit vrai qui doit rester. On les garde plutot que de les effacer pour
-- que ce fichier continue de se rejouer seul, sur une base ou 0013 n'aurait
-- pas ete appliquee.
insert into public.sourate (numero, nom_arabe, nom_translittere, lieu_revelation, nombre_versets)
values (2, 'البقرة', 'Al-Baqara', 'medine', 286)
on conflict (numero) do nothing;

insert into public.juz (numero, sourate_depart, verset_depart) values (1, 2, 1)
on conflict (numero) do nothing;

insert into public.page_mushaf (mushaf_id, numero, juz_numero)
select m.id, 2, 1 from public.mushaf m where m.code = 'madina-hafs-604'
on conflict (mushaf_id, numero) do nothing;

insert into public.verset (mushaf_id, sourate_numero, numero, texte, page_numero, ligne)
select m.id, 2, 1, 'الم', 2, 1 from public.mushaf m where m.code = 'madina-hafs-604'
on conflict (mushaf_id, sourate_numero, numero) do nothing;
insert into public.verset (mushaf_id, sourate_numero, numero, texte, page_numero, ligne)
select m.id, 2, 30, 'وإذ قال ربك للملائكة', 2, 5 from public.mushaf m where m.code = 'madina-hafs-604'
on conflict (mushaf_id, sourate_numero, numero) do nothing;

-- Sept seances, une par etat derive a prouver. Leurs plages sont disjointes :
-- `sessions_no_teacher_overlap` interdit a un enseignant deux cours qui se
-- chevauchent, et cette contrainte-la n'est pas ce que ce fichier mesure.
insert into public.sessions (id, teacher_id, started_at, ended_at, status) values
  ('5e000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000003',
   now() - interval '5 hours', now() - interval '4 hours 30 minutes', 'ended'),
  ('5e000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000003',
   now() - interval '4 hours', now() - interval '3 hours 30 minutes', 'ended'),
  ('5e000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000003',
   now() - interval '3 hours', now() - interval '2 hours 30 minutes', 'in_progress'),
  ('5e000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000003',
   now() - interval '2 hours', now() - interval '1 hour 30 minutes', 'in_progress'),
  ('5e000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000003',
   now() - interval '1 hour', now() - interval '30 minutes', 'in_progress'),
  ('5e000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000003',
   now() + interval '5 minutes', now() + interval '35 minutes', 'planned'),
  ('5e000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000003',
   now() + interval '4 hours', now() + interval '5 hours', 'planned');

insert into public.session_participants (session_id, profile_id, role)
select s.id, '50000000-0000-0000-0000-000000000002', 'student'
  from public.sessions s where s.teacher_id = '50000000-0000-0000-0000-000000000003';

-- Seance 3 (debutee il y a une heure) : entre une minute apres le debut.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
  ('5e000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000002',
   'joined', now() - interval '59 minutes', 'livekit_webhook');

-- Seance 4 (debutee il y a trois heures) : entre dix minutes apres le debut,
-- au-dela du seuil de retard.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
  ('5e000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000002',
   'joined', now() - interval '2 hours 50 minutes', 'livekit_webhook');

-- Seance 5 : entre a l'heure, puis coupure reseau il y a trente secondes.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
  ('5e000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000002',
   'joined', now() - interval '1 hour 59 minutes', 'livekit_webhook'),
  ('5e000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000002',
   'left', now() - interval '30 seconds', 'network');

-- Seance 6 : terminee, jamais vu entrer.
-- Seance 7 : terminee, entre a l'heure, jamais ressorti.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
  ('5e000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000002',
   'joined', now() - interval '3 hours 59 minutes', 'livekit_webhook');

-- Depuis 0042, l'appel de etat_presence exige un compte actif.
select set_config('test.uid', '50000000-0000-0000-0000-000000000002', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"student","household_id":"5fffffff-0000-0000-0000-00000000000a"}}',
  false);

-- ============================================================
-- Scenario 1 : la machine a etats derive les dix etats calculables
-- ============================================================

do $$
declare
  v_eleve uuid := '50000000-0000-0000-0000-000000000002';
  v_etat  public.presence_state;
begin
  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000001', v_eleve);
  if v_etat <> 'planifiee' then
    raise exception 'Presence ECHEC : avant la fenetre de jeton, attendu planifiee, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000002', v_eleve);
  if v_etat <> 'en_attente' then
    raise exception 'Presence ECHEC : fenetre ouverte sans joined, attendu en_attente, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000003', v_eleve);
  if v_etat <> 'presente' then
    raise exception 'Presence ECHEC : entre a l''heure, attendu presente, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000004', v_eleve);
  if v_etat <> 'en_retard' then
    raise exception 'Presence ECHEC : entre au-dela du seuil, attendu en_retard, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000005', v_eleve);
  if v_etat <> 'en_reconnexion' then
    raise exception 'Presence ECHEC : coupure recente, attendu en_reconnexion, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000006', v_eleve);
  if v_etat <> 'absente' then
    raise exception 'Presence ECHEC : seance finie sans joined, attendu absente, lu %', v_etat;
  end if;

  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000007', v_eleve);
  if v_etat <> 'confirmation_en_attente' then
    raise exception 'Presence ECHEC : seance finie et presence non consolidee, attendu confirmation_en_attente, lu %', v_etat;
  end if;

  raise notice 'Presence OK : planifiee, en_attente, presente, en_retard, en_reconnexion, absente, confirmation_en_attente';
end;
$$;

-- La meme coupure, vieillie au-dela de la fenetre, devient une deconnexion.
update public.session_events set server_ts = now() - interval '10 minutes'
 where session_id = '5e000000-0000-0000-0000-000000000005' and event_type = 'left';

do $$
declare v_etat public.presence_state;
begin
  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000005',
                                 '50000000-0000-0000-0000-000000000002');
  if v_etat <> 'deconnectee' then
    raise exception 'Presence ECHEC : coupure ancienne, attendu deconnectee, lu %', v_etat;
  end if;
  raise notice 'Presence OK : deconnectee une fois la fenetre de reconnexion passee';
end;
$$;

-- Le meme `left`, mais volontaire, ne se confond jamais avec une panne :
-- c'est toute la raison d'etre du vocabulaire de `source`.
update public.session_events set source = 'user_action'
 where session_id = '5e000000-0000-0000-0000-000000000005' and event_type = 'left';

do $$
declare v_etat public.presence_state;
begin
  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000005',
                                 '50000000-0000-0000-0000-000000000002');
  if v_etat <> 'sortie' then
    raise exception 'Presence ECHEC : depart volontaire, attendu sortie, lu %', v_etat;
  end if;
  raise notice 'Presence OK : sortie volontaire distinguee de la perte reseau';
end;
$$;

-- Revenu apres une coupure subie : reconnectee, et non presente.
update public.session_events set source = 'network'
 where session_id = '5e000000-0000-0000-0000-000000000005' and event_type = 'left';

insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
  ('5e000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000002',
   'joined', now() - interval '1 minute', 'livekit_webhook');

do $$
declare v_etat public.presence_state;
begin
  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000005',
                                 '50000000-0000-0000-0000-000000000002');
  if v_etat <> 'reconnectee' then
    raise exception 'Presence ECHEC : retour apres coupure, attendu reconnectee, lu %', v_etat;
  end if;
  raise notice 'Presence OK : reconnectee';
end;
$$;

-- ============================================================
-- Scenario 2 : une decision humaine prime sur tout calcul
-- ============================================================

insert into public.session_presence_override
  (session_id, profile_id, etat, motif, decide_par)
values
  ('5e000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000002',
   'excusee', 'Certificat medical remis au secretariat',
   '50000000-0000-0000-0000-000000000004');

do $$
declare v_etat public.presence_state;
begin
  v_etat := public.etat_presence('5e000000-0000-0000-0000-000000000006',
                                 '50000000-0000-0000-0000-000000000002');
  if v_etat <> 'excusee' then
    raise exception 'Presence ECHEC : absence excusee par decision, attendu excusee, lu %', v_etat;
  end if;
  raise notice 'Presence OK : la decision humaine prime sur la derivation';
end;
$$;

-- Les trois etats poses sont les seuls admis en correction : un etat calculable
-- ne se pose pas a la main, il se derive.
do $$
begin
  begin
    insert into public.session_presence_override
      (session_id, profile_id, etat, decide_par)
    values
      ('5e000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000002',
       'presente', '50000000-0000-0000-0000-000000000004');
    raise exception 'Override ECHEC : un etat derivable a pu etre pose a la main';
  exception when check_violation then
    raise notice 'Override OK : seuls excusee, corrigee_manuel et finalisee se posent';
  end;
end;
$$;

-- ============================================================
-- Scenario 3 : le vocabulaire de `source` est ferme
-- ============================================================

do $$
begin
  begin
    insert into public.session_events (session_id, profile_id, event_type, source)
    values ('5e000000-0000-0000-0000-000000000003',
            '50000000-0000-0000-0000-000000000002', 'left', 'peu_importe');
    raise exception 'Source ECHEC : une valeur hors vocabulaire a ete acceptee';
  exception when check_violation then
    raise notice 'Source OK : seules livekit_webhook, user_action, network, server sont admises';
  end;
end;
$$;

-- ============================================================
-- Scenario 4 : la position de lecture appartient a l'eleve seul
-- ============================================================

-- L'eleve pose sa position.
set role authenticated;
select set_config('test.uid', '50000000-0000-0000-0000-000000000002', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"student","household_id":"5fffffff-0000-0000-0000-00000000000a"}}', false);

insert into public.student_reading_position
  (student_profile_id, mushaf_id, page_mushaf, sourate, verset)
select '50000000-0000-0000-0000-000000000002', m.id, 2, 2, 30
  from public.mushaf m where m.code = 'madina-hafs-604';

reset role;

do $$
declare v_n int;
begin
  select count(*) into v_n from public.student_reading_position
   where student_profile_id = '50000000-0000-0000-0000-000000000002';
  if v_n <> 1 then
    raise exception 'Position ECHEC : l''eleve n''a pas pu ecrire sa propre position (% ligne(s))', v_n;
  end if;
  raise notice 'Position OK : l''eleve ecrit sa position';
end;
$$;

-- L'enseignant ne l'ecrit pas. C'est l'invariant de la Bible section 24.3 :
-- une page tournee pour toute la classe n'ecrase jamais l'etat personnel.
set role authenticated;
select set_config('test.uid', '50000000-0000-0000-0000-000000000003', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"5fffffff-0000-0000-0000-00000000000b"}}', false);

do $$
declare v_touche int;
begin
  update public.student_reading_position set page_mushaf = 99
   where student_profile_id = '50000000-0000-0000-0000-000000000002';
  get diagnostics v_touche = row_count;
  if v_touche <> 0 then
    raise exception 'Position ECHEC : un enseignant a modifie % ligne(s) de position d''eleve', v_touche;
  end if;
  raise notice 'Position OK : l''enseignant ne peut pas ecraser la position de l''eleve';
end;
$$;

reset role;

do $$
declare v_page int;
begin
  select page_mushaf into v_page from public.student_reading_position
   where student_profile_id = '50000000-0000-0000-0000-000000000002';
  if v_page <> 2 then
    raise exception 'Position ECHEC : la position vaut % apres la tentative enseignante', v_page;
  end if;
  raise notice 'Position OK : la valeur de l''eleve est intacte';
end;
$$;

-- Le tuteur du foyer la lit ; un tuteur d'un autre foyer ne voit rien.
set role authenticated;
select set_config('test.uid', '50000000-0000-0000-0000-000000000001', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"5fffffff-0000-0000-0000-00000000000a"}}', false);

do $$
declare v_n int;
begin
  select count(*) into v_n from public.student_reading_position;
  if v_n <> 1 then
    raise exception 'Position ECHEC : le tuteur du foyer lit % ligne(s) au lieu d''une', v_n;
  end if;
  raise notice 'Position OK : le tuteur du foyer lit la position de son enfant';
end;
$$;

select set_config('test.uid', '50000000-0000-0000-0000-000000000005', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"5fffffff-0000-0000-0000-00000000000b"}}', false);

do $$
declare v_n int;
begin
  select count(*) into v_n from public.student_reading_position;
  if v_n <> 0 then
    raise exception 'Position ECHEC : un tuteur etranger au foyer lit % ligne(s)', v_n;
  end if;
  raise notice 'Position OK : un autre foyer ne voit rien';
end;
$$;

reset role;

-- ============================================================
-- Scenario 5 : le Coran se lit, ne s'ecrit pas hors administration
-- ============================================================

set role authenticated;
select set_config('test.uid', '50000000-0000-0000-0000-000000000002', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"student","household_id":"5fffffff-0000-0000-0000-00000000000a"}}', false);

do $$
declare v_n int;
begin
  -- 6236 depuis le lot N5, et non plus les deux versets du fragment de N1 :
  -- c'est le corpus entier que `0013` importe, et un eleve valide le lit en
  -- entier. Le chiffre est ecrit en clair plutot que compare a un sous-select
  -- pour qu'un import partiel echoue ici aussi, pas seulement dans 0013.
  select count(*) into v_n from public.verset;
  if v_n <> 6236 then
    raise exception 'Coran ECHEC : un eleve lit % verset(s) au lieu de 6236', v_n;
  end if;

  begin
    update public.verset set texte = 'altere'
     where sourate_numero = 1 and numero = 1;
    raise exception 'Coran ECHEC : un eleve a pu modifier le texte coranique';
  exception when insufficient_privilege then
    raise notice 'Coran OK : lecture ouverte, ecriture refusee a l''eleve';
  end;
end;
$$;

reset role;

do $$
declare v_texte text;
begin
  -- La sourate est nommee : depuis N5, `numero = 1` designe le premier verset
  -- de chacune des 114 sourates, plus un seul.
  select texte into v_texte from public.verset
   where sourate_numero = 1 and numero = 1;
  if v_texte = 'altere' then
    raise exception 'Coran ECHEC : le texte a ete altere';
  end if;
  raise notice 'Coran OK : le texte de reference est intact';
end;
$$;

-- ============================================================
-- Scenario 6 : la vue de presence porte le contexte, pas une seule couleur
-- ============================================================

do $$
declare
  v_etat   public.presence_state;
  v_entre  timestamptz;
  v_statut public.session_status;
begin
  select p.etat, p.entre_le, p.statut_seance
    into v_etat, v_entre, v_statut
    from public.presence_seance_v p
   where p.session_id = '5e000000-0000-0000-0000-000000000003'
     and p.profile_id = '50000000-0000-0000-0000-000000000002';

  if v_etat <> 'presente' then
    raise exception 'Vue ECHEC : etat % au lieu de presente', v_etat;
  end if;
  if v_entre is null then
    raise exception 'Vue ECHEC : aucune heure d''entree, la Bible interdit l''etat nu';
  end if;
  if v_statut <> 'in_progress' then
    raise exception 'Vue ECHEC : statut de seance % inattendu', v_statut;
  end if;
  raise notice 'Vue OK : etat, heure d''entree et statut de seance voyagent ensemble';
end;
$$;

\ir _acl_retablir.sql
