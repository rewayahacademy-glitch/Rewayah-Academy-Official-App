-- Scenarios d'acceptation SQL de `N5`, le lecteur de Coran : ce que le corpus
-- importe par `0013` contient reellement, et a qui la position de lecture
-- appartient.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0013. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml`, comme ceux
-- de N2 et N4 : le controle J4 de ce dernier relit la chaine de hachage de
-- tout ce que les fichiers precedents ont ecrit.
--
-- CE QUE CE FICHIER MESURE, ET QUE RIEN D'AUTRE NE MESURE :
--
--   1. Que le corpus est COMPLET et CONCORDANT. La migration 0013 le verifie
--      deja a l'import, mais elle le verifie sur la base ou elle s'applique ;
--      ici on le reverifie apres que six autres fichiers de scenarios ont
--      ecrit dans la meme base.
--   2. Que la pagination est bien celle du Mushaf de Medine. Un corpus complet
--      mais mal pagine passerait tous les comptages : ce sont les reperes de
--      C2 qui le prendraient, et ils se verifient sur un exemplaire imprime.
--   3. Que la position de lecture n'appartient qu'a l'eleve -- l'invariant J2,
--      celui pour lequel `student_reading_position` existe separement de tout
--      etat de seance.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Comme dans scenarios_n4.sql : le grant ci-dessus annule les restrictions de
-- 0010 sur les fonctions d'emission. On les repose, sans quoi les fichiers
-- suivants mesureraient le harnais et non les migrations.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

-- ============================================================
-- Fixtures : deux foyers, deux eleves, un enseignant, un tuteur
-- ============================================================
--
--   * Nour et Sami sont eleves, dans DEUX foyers differents : c'est ce qui
--     rend C7 concluant. Dans un meme foyer, un eleve qui lirait la position
--     de l'autre passerait pour un effet de la branche « foyer » alors que ce
--     serait la borne qui aurait cede.
--   * Rachid est l'enseignant de Nour. C'est lui qui mesure J2 en C6.
--   * Latifa est la tutrice du foyer de Nour.
--   * Omar a un compte desactive : il mesure que le texte n'est pas public.

insert into auth.users (id, email) values
  ('b5000000-0000-0000-0000-000000000001', 'nour@example.test'),
  ('b5000000-0000-0000-0000-000000000002', 'sami@example.test'),
  ('b5000000-0000-0000-0000-000000000003', 'rachid@example.test'),
  ('b5000000-0000-0000-0000-000000000004', 'latifa@example.test'),
  ('b5000000-0000-0000-0000-000000000005', 'omar@example.test'),
  ('b5000000-0000-0000-0000-000000000006', 'nadia@example.test');

insert into public.households (id, timezone) values
  ('b5ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('b5ffffff-0000-0000-0000-00000000000b', 'Europe/Paris'),
  ('b5ffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('b5000000-0000-0000-0000-000000000001', 'STUD-N5-000001', 'student',
   'b5ffffff-0000-0000-0000-00000000000a', 'Nour', 'Benali', 'active', 'female'),
  ('b5000000-0000-0000-0000-000000000002', 'STUD-N5-000002', 'student',
   'b5ffffff-0000-0000-0000-00000000000b', 'Sami', 'Haddad', 'active', 'male'),
  ('b5000000-0000-0000-0000-000000000003', 'TEACH-N5-000001', 'teacher',
   'b5ffffff-0000-0000-0000-00000000000c', 'Rachid', 'Ziani', 'provisional_active', 'male'),
  ('b5000000-0000-0000-0000-000000000004', 'GUAR-N5-000001', 'guardian',
   'b5ffffff-0000-0000-0000-00000000000a', 'Latifa', 'Benali', 'active', 'female'),
  ('b5000000-0000-0000-0000-000000000005', 'STUD-N5-000003', 'student',
   'b5ffffff-0000-0000-0000-00000000000b', 'Omar', 'Kaci', 'disabled', 'male'),
  ('b5000000-0000-0000-0000-000000000006', 'ADMIN-N5-00001', 'admin',
   'b5ffffff-0000-0000-0000-00000000000c', 'Nadia', 'Slimani', 'active', 'female');
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
  ('b5000000-0000-0000-0000-000000000001', 'minor', 'standard', 'allowed'),
  ('b5000000-0000-0000-0000-000000000002', 'autonomous', 'standard', 'allowed'),
  ('b5000000-0000-0000-0000-000000000005', 'autonomous', 'standard', 'allowed');

-- ============================================================
-- C1 : le corpus est complet, et concordant sourate par sourate
-- ============================================================
--
-- Un total juste avec deux sourates qui se compensent passerait un simple
-- comptage : c'est la concordance par sourate qui tranche.

do $$
declare
  v_mushaf   uuid;
  v_sourates int;
  v_juz      int;
  v_pages    int;
  v_versets  int;
  v_ecarts   int;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';
  if v_mushaf is null then
    raise exception 'C1 : l''edition madina-hafs-604 est absente';
  end if;

  select count(*) into v_sourates from public.sourate;
  select count(*) into v_juz from public.juz;
  select count(*) into v_pages from public.page_mushaf where mushaf_id = v_mushaf;
  select count(*) into v_versets from public.verset where mushaf_id = v_mushaf;

  if v_sourates <> 114 or v_juz <> 30 or v_pages <> 604 or v_versets <> 6236 then
    raise exception 'C1 : corpus (%, %, %, %), attendu (114, 30, 604, 6236)',
      v_sourates, v_juz, v_pages, v_versets;
  end if;

  select count(*) into v_ecarts
    from public.sourate s
    left join (
      select sourate_numero, count(*) as n
        from public.verset where mushaf_id = v_mushaf
       group by sourate_numero
    ) v on v.sourate_numero = s.numero
   where coalesce(v.n, 0) <> s.nombre_versets;

  if v_ecarts <> 0 then
    raise exception 'C1 : % sourate(s) dont le compte de versets ne correspond pas',
      v_ecarts;
  end if;
end $$;

-- ============================================================
-- C2 : la pagination est celle du Mushaf de Medine
-- ============================================================
--
-- Quatre reperes que n'importe qui peut verifier sur un exemplaire imprime.
-- C'est le seul controle de ce fichier qui distingue le VRAI mushaf d'un
-- decoupage arbitraire en 604 morceaux : sans lui, un corpus complet mais
-- pagine au hasard passerait C1 sans rien signaler.

do $$
declare
  v_mushaf uuid;
  v_kursi  int;
  v_kahf   int;
  v_yasin  int;
  v_nas    int;
  v_vides  int;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  select page_numero into v_kursi from public.verset
   where mushaf_id = v_mushaf and sourate_numero = 2 and numero = 255;
  select page_numero into v_kahf from public.verset
   where mushaf_id = v_mushaf and sourate_numero = 18 and numero = 1;
  select page_numero into v_yasin from public.verset
   where mushaf_id = v_mushaf and sourate_numero = 36 and numero = 1;
  select page_numero into v_nas from public.verset
   where mushaf_id = v_mushaf and sourate_numero = 114 and numero = 1;

  if v_kursi <> 42 or v_kahf <> 293 or v_yasin <> 440 or v_nas <> 604 then
    raise exception
      'C2 : pages (Kursi %, Kahf %, Ya-Sin %, An-Nas %), attendu (42, 293, 440, 604)',
      v_kursi, v_kahf, v_yasin, v_nas;
  end if;

  -- Aucune page declaree sans texte : 604 pages, 604 pages qui portent des
  -- versets. Une page vide se lirait a l'ecran comme un bug d'affichage.
  select count(*) into v_vides
    from public.page_mushaf p
   where p.mushaf_id = v_mushaf
     and not exists (
       select 1 from public.verset v
        where v.mushaf_id = p.mushaf_id and v.page_numero = p.numero
     );
  if v_vides <> 0 then
    raise exception 'C2 : % page(s) du mushaf ne portent aucun verset', v_vides;
  end if;
end $$;

-- ============================================================
-- C3 : le texte se lit par un compte valide, et par lui seul
-- ============================================================

do $$
declare
  v_eleve int;
  v_hs    int;
  v_anon  int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
  select count(*) into v_eleve from public.verset where page_numero = 1;

  -- Omar est desactive : `app_account_valid()` le refuse, et le texte coranique
  -- n'est pas pour autant public.
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000005', true);
  select count(*) into v_hs from public.verset where page_numero = 1;

  -- Un anonyme est refuse plus tot encore que par la RLS : `0007` n'accorde
  -- `select` sur le texte qu'a `authenticated`, donc la lecture echoue au
  -- niveau du droit de table. Les deux refus comptent pour zero verset lu,
  -- et il faut les accepter tous les deux : tester la seule RLS laisserait
  -- passer le jour ou un grant de trop serait pose.
  set local role anon;
  perform set_config('test.uid', '', true);
  begin
    select count(*) into v_anon from public.verset where page_numero = 1;
  exception when insufficient_privilege then
    v_anon := 0;
  end;

  if v_eleve <> 7 then
    raise exception 'C3 : une eleve lit % versets page 1, attendu 7', v_eleve;
  end if;
  if v_hs <> 0 then
    raise exception 'C3 : un compte desactive lit % versets, attendu 0', v_hs;
  end if;
  if v_anon <> 0 then
    raise exception 'C3 : un anonyme lit % versets, attendu 0', v_anon;
  end if;
end $$;

-- ============================================================
-- C4 : personne n'ecrit le texte hors administration
-- ============================================================

do $$
declare
  v_refus   boolean := false;
  v_mushaf  uuid;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  begin
    update public.verset set texte = 'altere'
     where mushaf_id = v_mushaf and sourate_numero = 1 and numero = 1;
    if not found then
      v_refus := true;
    end if;
  exception when insufficient_privilege then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'C4 : un enseignant a pu modifier le texte coranique';
  end if;
end $$;

-- ============================================================
-- C5 : la position de lecture appartient a l'eleve
-- ============================================================

do $$
declare
  v_mushaf uuid;
  v_lue    int;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  insert into public.student_reading_position
    (student_profile_id, mushaf_id, page_mushaf, sourate, verset)
  values ('b5000000-0000-0000-0000-000000000001', v_mushaf, 42, 2, 255);

  select count(*) into v_lue from public.student_reading_position
   where student_profile_id = 'b5000000-0000-0000-0000-000000000001';

  if v_lue <> 1 then
    raise exception 'C5 : une eleve lit % fois sa propre position, attendu 1', v_lue;
  end if;
end $$;

-- ============================================================
-- C6 : J2 -- un enseignant n'ecrit JAMAIS la position d'un eleve
-- ============================================================
--
-- C'est l'invariant pour lequel `student_reading_position` existe separement
-- de tout etat de seance : une page tournee par l'enseignant pour toute la
-- classe ne doit jamais ecraser silencieusement l'endroit ou l'eleve en etait
-- (Bible section 24.3). Aucune policy de 0007 ne nomme l'enseignant, et ce
-- controle est ce qui empechera d'en ajouter une par megarde.

do $$
declare
  v_mushaf   uuid;
  v_refus    boolean := false;
  v_position int;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  -- Tentative d'ecrasement : l'enseignant « tourne la page » pour son eleve.
  begin
    update public.student_reading_position set page_mushaf = 1
     where student_profile_id = 'b5000000-0000-0000-0000-000000000001';
    if not found then
      v_refus := true;
    end if;
  exception when insufficient_privilege then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'J2 : un enseignant a pu ecrire la position de lecture d''une eleve';
  end if;

  -- Et il ne peut pas davantage en creer une de toutes pieces.
  v_refus := false;
  begin
    insert into public.student_reading_position
      (student_profile_id, mushaf_id, page_mushaf, sourate, verset)
    values ('b5000000-0000-0000-0000-000000000002', v_mushaf, 1, 1, 1);
  exception when insufficient_privilege or check_violation then
    v_refus := true;
  end;
  if not v_refus then
    raise exception 'J2 : un enseignant a pu creer la position de lecture d''un eleve';
  end if;

  -- La position de Nour est restee la ou Nour l'avait laissee. On relit sans
  -- borne d'appelant : la question n'est pas qui la voit, c'est ce qu'elle
  -- vaut apres la tentative.
  execute 'reset role';
  select page_mushaf into v_position from public.student_reading_position
   where student_profile_id = 'b5000000-0000-0000-0000-000000000001';
  if v_position <> 42 then
    raise exception 'J2 : la position de l''eleve vaut % au lieu de 42', v_position;
  end if;
end $$;

-- ============================================================
-- C7 : un tiers ne lit pas la position d'autrui, le foyer si
-- ============================================================

do $$
declare
  v_tiers  int;
  v_foyer  int;
  v_hors   int;
begin
  set local role authenticated;

  -- Sami, eleve d'un autre foyer.
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
  select count(*) into v_tiers from public.student_reading_position
   where student_profile_id = 'b5000000-0000-0000-0000-000000000001';

  -- Latifa, tutrice du foyer de Nour : elle voit ou en est son enfant.
  -- Le foyer est porte par le JETON, pas devine depuis le profil : c'est
  -- `app_household_id()` qui le lit, et un jeton sans foyer ne lit rien.
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000004', true);
  perform set_config(
    'test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"b5ffffff-0000-0000-0000-00000000000a"}}',
    true
  );
  select count(*) into v_foyer from public.student_reading_position
   where student_profile_id = 'b5000000-0000-0000-0000-000000000001';
  select count(*) into v_hors from public.student_reading_position
   where student_profile_id <> 'b5000000-0000-0000-0000-000000000001';

  if v_tiers <> 0 then
    raise exception 'C7 : un eleve tiers lit % position(s) d''autrui, attendu 0', v_tiers;
  end if;
  if v_foyer <> 1 then
    raise exception 'C7 : la tutrice lit % position(s) de son enfant, attendu 1', v_foyer;
  end if;
  if v_hors <> 0 then
    raise exception 'C7 : la tutrice lit % position(s) hors de son foyer, attendu 0', v_hors;
  end if;
end $$;

-- ============================================================
-- C8 : la base borne le grossissement, le client ne fait que suivre
-- ============================================================
--
-- `PositionLecture.zoomMin` et `zoomMax` recopient ces bornes cote Dart. Si
-- l'une des deux bougeait sans l'autre, l'ecriture echouerait en production
-- sans qu'aucun test Flutter ne le voie : ce controle est la pour que la
-- contrainte soit mesuree la ou elle est reellement appliquee.

do $$
declare
  v_mushaf uuid;
  v_refus  boolean := false;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  begin
    insert into public.student_reading_position
      (student_profile_id, mushaf_id, page_mushaf, sourate, verset, zoom_level)
    values ('b5000000-0000-0000-0000-000000000002', v_mushaf, 1, 1, 1, 9.0);
  exception when check_violation then
    v_refus := true;
  end;

  if not v_refus then
    raise exception 'C8 : un grossissement de 9 a ete accepte, borne attendue a 4';
  end if;

  -- Et la borne basse, dans l'autre sens.
  v_refus := false;
  begin
    insert into public.student_reading_position
      (student_profile_id, mushaf_id, page_mushaf, sourate, verset, zoom_level)
    values ('b5000000-0000-0000-0000-000000000002', v_mushaf, 1, 1, 1, 0.1);
  exception when check_violation then
    v_refus := true;
  end;
  if not v_refus then
    raise exception 'C8 : un grossissement de 0,1 a ete accepte, borne attendue a 0,5';
  end if;
end $$;

-- ============================================================
-- C9 : une page se lit d'un seul coup, dans l'ordre du texte
-- ============================================================
--
-- L'ecran demande une page et compose lui-meme : il faut donc que la page
-- rende ses versets dans l'ordre, et que les pages a cheval sur deux sourates
-- se lisent comme telles. La 596 en est une, verifiable sur l'imprime.

do $$
declare
  v_mushaf   uuid;
  v_sourates int;
  v_premier  int;
begin
  select id into v_mushaf from public.mushaf where code = 'madina-hafs-604';

  set local role authenticated;
  perform set_config('test.uid', 'b5000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  select count(distinct sourate_numero) into v_sourates
    from public.verset where mushaf_id = v_mushaf and page_numero = 596;
  if v_sourates < 2 then
    raise exception 'C9 : la page 596 ne porte que % sourate(s), attendu au moins 2',
      v_sourates;
  end if;

  -- La page 1 commence bien au premier verset du Coran.
  select numero into v_premier
    from public.verset
   where mushaf_id = v_mushaf and page_numero = 1
   order by sourate_numero, numero
   limit 1;
  if v_premier <> 1 then
    raise exception 'C9 : la page 1 commence au verset %, attendu 1', v_premier;
  end if;
end $$;

-- Retour a un role neutre pour les fichiers suivants.
reset role;

\ir _acl_retablir.sql
