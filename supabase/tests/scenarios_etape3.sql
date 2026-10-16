-- Scenarios d'acceptation SQL de l'etape 3 (section 8 de etape-3-auth-kyc.md).
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».

-- Droits facon Supabase (alter default privileges du projet).
-- Auth provenance fields are added only to this scenario fixture.
alter table auth.users add column if not exists raw_app_meta_data jsonb not null default '{}'::jsonb;
alter table auth.users add column if not exists created_at timestamptz not null default now();
grant usage on schema public to anon, authenticated, service_role;
do $scenario_grants$
declare
  v_table record;
begin
  for v_table in
    select schemaname, tablename
    from pg_catalog.pg_tables
    where schemaname = 'public' and tablename <> 'contract_acceptances'
  loop
    execute format(
      'grant all on table %I.%I to authenticated, service_role',
      v_table.schemaname, v_table.tablename
    );
  end loop;
end
$scenario_grants$;
-- Postgres nu n'applique pas les privilèges par défaut de Supabase. La RPC
-- SECURITY INVOKER lit la signature qu'elle vient d'insérer; reproduire ici
-- le SELECT de plateforme, sans modifier stub_auth ni les ACL de production.
grant select on table public.contract_acceptances to authenticated;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'tuteur@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'enseignant@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'admin@example.test'),
  ('44444444-4444-4444-4444-444444444444', 'enfant1@example.test'),
  ('55555555-5555-5555-5555-555555555555', 'enfant2@example.test'),
  ('66666666-6666-6666-6666-666666666666', 'enseignante@example.test'),
  ('77777777-7777-7777-7777-777777777777', 'sansgenre@example.test');

-- ============================================================
-- S3 : une inscription publique est bornee a deux roles et a pending_kyc
-- ============================================================

select set_config('test.uid', '11111111-1111-1111-1111-111111111111', false);
select set_config('test.jwt', '{}', false);

do $$
declare
  v_role text;
  v_refus int := 0;
begin
  foreach v_role in array array['admin', 'controller', 'accountant', 'student'] loop
    begin
      perform public.creer_profil_inscription(v_role, 'Ada', 'Lovelace');
      raise exception 'S3 ECHEC : le role % a ete accepte a l''inscription publique', v_role;
    exception
      when sqlstate 'P0001' then
        if position('non ouvert' in sqlerrm) = 0 then raise; end if;
        v_refus := v_refus + 1;
    end;
  end loop;
  if v_refus <> 4 then
    raise exception 'S3 ECHEC : % refus au lieu de 4', v_refus;
  end if;
  raise notice 'S3a ok : les quatre roles prives sont refuses a l''inscription publique';
end $$;

-- Le tuteur s'inscrit pour de bon.
select public.creer_profil_inscription('guardian', 'Fatou', 'Diallo', 'male') is not null
       as tuteur_cree;

do $$
declare v_statut public.account_status; v_foyer uuid;
begin
  select account_status, household_id into v_statut, v_foyer
  from public.profiles where id = '11111111-1111-1111-1111-111111111111';

  if v_statut <> 'pending_kyc' then
    raise exception 'S3 ECHEC : statut % au lieu de pending_kyc (ADR-014)', v_statut;
  end if;
  if v_foyer is null then
    raise exception 'S3 ECHEC : un tuteur doit fonder un foyer';
  end if;
  raise notice 'S3b ok : le tuteur naît pending_kyc et fonde son foyer';
end $$;

-- I3 : un compte, un profil.
do $$
begin
  begin
    perform public.creer_profil_inscription('teacher', 'Fatou', 'Diallo');
    raise exception 'S3 ECHEC : un second profil a pu etre cree pour le meme compte';
  exception when sqlstate 'P0001' then
    if position('deja un profil' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S3c ok : un compte ne peut pas se creer deux profils';
end $$;

-- L'enseignant s'inscrit. Il ne doit PAS recevoir de foyer.
select set_config('test.uid', '22222222-2222-2222-2222-222222222222', false);
select public.creer_profil_inscription('teacher', 'Moussa', 'Barry', 'male') is not null
       as enseignant_cree;

do $$
begin
  if (select household_id from public.profiles
      where id = '22222222-2222-2222-2222-222222222222') is not null then
    raise exception 'S3 ECHEC : un enseignant s''est vu attribuer un foyer fantome';
  end if;
  if not exists (select 1 from public.teacher_profiles
                 where profile_id = '22222222-2222-2222-2222-222222222222') then
    raise exception 'S3 ECHEC : la fiche enseignant n''a pas ete creee';
  end if;
  raise notice 'S3d ok : le personnel n''a pas de foyer, et sa fiche existe';
end $$;

-- ============================================================
-- S4 : l'enseignant depose sa propre piece d'identite
-- ============================================================

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  -- Le genre est volontairement FAUX ici : c'est ce qui decide quel membre du
  -- personnel pourra ouvrir la piece, donc le deposant n'a pas a le choisir.
  insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
  values ('22222222-2222-2222-2222-222222222222', 'id_card', 'female',
          '22222222-2222-2222-2222-222222222222/piece.webp');

  raise notice 'S4 ok : l''enseignant depose sa piece sous RLS';
end $$;

do $$
begin
  if (select gender from public.kyc_documents
      where profile_id = '22222222-2222-2222-2222-222222222222') <> 'male' then
    raise exception
      'S4 ECHEC : le genre envoye par le client a ete conserve. Le deposant '
      'choisirait alors qui peut ouvrir sa piece.';
  end if;
  raise notice 'S4a ok : le genre du dossier est celui du profil, pas celui du client';
end $$;

-- Un profil sans genre ne peut pas deposer : mieux vaut un refus qu'un dossier
-- que personne ne saura classer.
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status)
values ('77777777-7777-7777-7777-777777777777', 'TEACHER-SG-009999', 'teacher',
        'Sans', 'Genre', 'pending_kyc');

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '77777777-7777-7777-7777-777777777777', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
    values ('77777777-7777-7777-7777-777777777777', 'id_card', 'male',
            '77777777-7777-7777-7777-777777777777/piece.webp');
    raise exception 'S4 ECHEC : un dossier sans genre de titulaire a ete accepte';
  exception when sqlstate 'P0001' then
    if position('genre du titulaire inconnu' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S4d ok : sans genre au profil, le depot est refuse';
end $$;

-- Controle negatif : personne ne depose une piece pour autrui.
do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
    values ('11111111-1111-1111-1111-111111111111', 'id_card', 'male', 'x/y.webp');
    raise exception 'S4 ECHEC : une piece a pu etre deposee pour un autre profil';
  exception when insufficient_privilege then
    null;
  end;
  raise notice 'S4b ok : le depot pour autrui est refuse par la RLS';
end $$;

-- La duree de conservation est posee par la base, pas par le client.
do $$
begin
  if (select purge_at from public.kyc_documents
      where profile_id = '22222222-2222-2222-2222-222222222222') is null then
    raise exception 'S4 ECHEC : purge_at n''a pas ete pose';
  end if;
  raise notice 'S4c ok : la date de purge est posee en base';
end $$;

-- Le tuteur depose la sienne.
do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"' ||
    (select household_id from public.profiles where id = '11111111-1111-1111-1111-111111111111') ||
    '"}}', true);
  insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
  values ('11111111-1111-1111-1111-111111111111', 'id_card', 'male',
          '11111111-1111-1111-1111-111111111111/piece.webp');
end $$;

-- ============================================================
-- S5 : un lecteur KYC sans genre recoit un refus explicite
-- ============================================================

insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status)
values ('33333333-3333-3333-3333-333333333333', 'ADMIN-AA-000001', 'admin',
        'Aicha', 'Admin', 'active');

select set_config('test.uid', '33333333-3333-3333-3333-333333333333', false);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', false);

do $$
begin
  begin
    perform * from public.read_kyc_documents();
    raise exception 'S5 ECHEC : un lecteur sans genre a obtenu des dossiers';
  exception when insufficient_privilege then
    null;
  when sqlstate 'P0001' then
    if position('genre du lecteur inconnu' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S5a ok : genre inconnu, refus explicite plutot que filtrage a moitie';
end $$;

update public.profiles set gender = 'male'
where id = '33333333-3333-3333-3333-333333333333';

do $$
declare v_n int;
begin
  select count(*) into v_n from public.read_kyc_documents();
  if v_n <> 2 then
    raise exception 'S5 ECHEC : % dossiers masculins lus au lieu de 2', v_n;
  end if;
  raise notice 'S5b ok : le genre du lecteur vient de son profil';
end $$;

-- Cloisonnement : un lecteur masculin ne voit aucun dossier feminin.
-- Le dossier feminin vient d'une enseignante reelle, puisque le genre du
-- dossier est desormais celui du profil et ne peut plus etre pose a la main.
select set_config('test.uid', '66666666-6666-6666-6666-666666666666', false);
select public.creer_profil_inscription('teacher', 'Aissatou', 'Balde', 'female')
       is not null as enseignante_creee;

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '66666666-6666-6666-6666-666666666666', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
  values ('66666666-6666-6666-6666-666666666666', 'passport', 'male',
          '66666666-6666-6666-6666-666666666666/piece.webp');
end $$;

select set_config('test.uid', '33333333-3333-3333-3333-333333333333', false);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', false);

do $$
begin
  if (select gender from public.kyc_documents
      where profile_id = '66666666-6666-6666-6666-666666666666') <> 'female' then
    raise exception 'S5 ECHEC : le genre du dossier n''a pas suivi le profil';
  end if;
  if exists (select 1 from public.read_kyc_documents() where gender = 'female') then
    raise exception 'S5 ECHEC : un lecteur masculin a vu un dossier feminin (audit 1.3)';
  end if;
  raise notice 'S5c ok : aucun dossier feminin visible par un lecteur masculin';
end $$;

-- La lecture laisse une trace, le refus n'en laisse pas de fausse.
do $$
declare v_n int;
begin
  select count(*) into v_n from public.audit_logs where action = 'kyc_read';
  if v_n < 2 then
    raise exception 'S5 ECHEC : % lectures journalisees, au moins 2 attendues', v_n;
  end if;
  raise notice 'S5d ok : chaque lecture de dossier est journalisee (%)' , v_n;
end $$;

-- ============================================================
-- ADM-02 : le verdict, et ce qu'il change
-- ============================================================

do $$
declare v_doc uuid; v_n int;
begin
  -- La RPC inclut aussi les profils pending_kyc sans pièce visible
  -- (document_id NULL / etat_piece = aucune ou non_visible). ADM-02 mesure
  -- ici les pièces que cet administrateur peut réellement traiter.
  select count(*) into v_n
  from public.dossiers_en_attente()
  where document_id is not null;
  if v_n <> 2 then
    raise exception 'ADM-02 ECHEC : % pièces visibles au lieu de 2', v_n;
  end if;

  begin
    select document_id into v_doc from public.dossiers_en_attente() limit 1;
    perform public.decider_dossier(v_doc, false, null);
    raise exception 'ADM-02 ECHEC : un refus sans motif a ete accepte';
  exception when sqlstate 'P0001' then
    if position('exige un motif' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'ADM-02a ok : un refus sans motif est refuse';
end $$;

do $$
declare v_doc uuid;
begin
  select document_id into v_doc from public.dossiers_en_attente()
  where profile_id = '11111111-1111-1111-1111-111111111111' limit 1;
  perform public.decider_dossier(v_doc, true);

  if (select account_status from public.profiles
      where id = '11111111-1111-1111-1111-111111111111') <> 'active' then
    raise exception 'ADM-02 ECHEC : le tuteur n''est pas passe actif apres validation';
  end if;
  raise notice 'ADM-02b ok : la validation active le compte';
end $$;

do $$
declare v_doc uuid;
begin
  select document_id into v_doc from public.dossiers_en_attente()
  where profile_id = '22222222-2222-2222-2222-222222222222' limit 1;
  perform public.decider_dossier(v_doc, false, 'Photo illisible, merci de la reprendre en pleine lumiere.');

  if (select rejection_reason from public.kyc_documents where id = v_doc) is null then
    raise exception 'ADM-02 ECHEC : le motif de refus n''a pas ete conserve';
  end if;
  if (select account_status from public.profiles
      where id = '22222222-2222-2222-2222-222222222222') <> 'pending_kyc' then
    raise exception 'ADM-02 ECHEC : un refus ne doit pas activer le compte';
  end if;
  raise notice 'ADM-02c ok : le refus conserve son motif et n''ouvre rien';
end $$;

-- ============================================================
-- S6 et S7 : appareil partage, puis plafond
-- ============================================================

update auth.users set raw_app_meta_data = jsonb_build_object(
  'child_of', '11111111-1111-1111-1111-111111111111'
) where id in ('44444444-4444-4444-4444-444444444444',
               '55555555-5555-5555-5555-555555555555');
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","app_metadata":{"role":"guardian"}}', false);

select public.creer_profil_enfant(
  '44444444-4444-4444-4444-444444444444',
  '11111111-1111-1111-1111-111111111111', 'Amina', 'Diallo', 7) is not null as enfant1;
select public.creer_profil_enfant(
  '55555555-5555-5555-5555-555555555555',
  '11111111-1111-1111-1111-111111111111', 'Ibrahim', 'Diallo', 12) is not null as enfant2;
select set_config('request.jwt.claim.sub', '', false);
select set_config('request.jwt.claims', '', false);

do $$
begin
  if (select interface_mode from public.student_profiles
      where profile_id = '44444444-4444-4444-4444-444444444444') <> 'child' then
    raise exception 'ADR-009 ECHEC : un enfant de 7 ans doit naitre en mode enfant';
  end if;
  if (select camera_policy from public.student_profiles
      where profile_id = '44444444-4444-4444-4444-444444444444') <> 'forbidden' then
    raise exception 'ADR-009 ECHEC : camera interdite en dessous de 11 ans';
  end if;
  if (select interface_mode from public.student_profiles
      where profile_id = '55555555-5555-5555-5555-555555555555') <> 'standard' then
    raise exception 'ADR-009 ECHEC : un enfant de 12 ans doit naitre en mode standard';
  end if;
  raise notice 'ADR-009 ok : mode et camera derives de l''age par la configuration';
end $$;

select set_config('test.uid', '11111111-1111-1111-1111-111111111111', false);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"' ||
  (select household_id from public.profiles where id = '11111111-1111-1111-1111-111111111111') ||
  '"}}', false);

-- F86 student-identity : le contrôle existant était déjà null-safe; cette
-- fixture documente son refus pour le cas du JWT sans claim role.
do $$
declare v_refuse boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'household_id', (select household_id from public.profiles
                       where id = '11111111-1111-1111-1111-111111111111')
    ))::text, true);
  begin
    perform * from public.creer_code_appairage('44444444-4444-4444-4444-444444444444');
  exception when sqlstate 'P0001' then
    v_refuse := sqlerrm = 'seul un tuteur au compte valide appaire un appareil';
  end;
  reset role;
  if not v_refuse then
    raise exception 'F86 ECHEC : le JWT tuteur sans claim role a pu creer un code';
  end if;
end $$;

-- Une tablette, deux enfants du meme foyer.
do $$
declare v_code text; v_p1 uuid; v_p2 uuid;
begin
  select code into v_code from public.creer_code_appairage('44444444-4444-4444-4444-444444444444');
  select profile_id into v_p1
  from public.consommer_code_appairage(v_code, 'TABLETTE-SALON', 'android');

  select code into v_code from public.creer_code_appairage('55555555-5555-5555-5555-555555555555');
  select profile_id into v_p2
  from public.consommer_code_appairage(v_code, 'TABLETTE-SALON', 'android');

  if v_p1 = v_p2 then
    raise exception 'S6 ECHEC : le meme profil a ete appaire deux fois';
  end if;
  if (select count(*) from public.devices where device_fingerprint = 'TABLETTE-SALON') <> 2 then
    raise exception 'S6 ECHEC : une tablette ne se partage pas entre deux enfants';
  end if;
  raise notice 'S6 ok : une tablette se partage entre deux enfants du meme foyer';
end $$;

-- Le code n'est jamais stocke en clair (I4).
do $$
begin
  if exists (select 1 from public.device_pairing_codes where length(code_hash) <> 64) then
    raise exception 'I4 ECHEC : une valeur qui n''est pas une empreinte sha256 est stockee';
  end if;
  raise notice 'I4 ok : seule l''empreinte du code est stockee';
end $$;

-- Deuxieme appareil pour Amina : accepte. Troisieme : refuse par la base.
do $$
declare v_code text;
begin
  select code into v_code from public.creer_code_appairage('44444444-4444-4444-4444-444444444444');
  perform public.consommer_code_appairage(v_code, 'TELEPHONE-MAMAN', 'ios');

  begin
    select code into v_code from public.creer_code_appairage('44444444-4444-4444-4444-444444444444');
    raise exception 'S7 ECHEC : un troisieme code a pu etre demande';
  exception when sqlstate 'P0001' then
    if position('plafond' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S7a ok : le troisieme appareil est refuse des la demande de code';
end $$;

-- Le plafond tient aussi a la reactivation d'un appareil revoque.
do $$
declare v_code text; v_revoque uuid;
begin
  select id into v_revoque from public.devices
  where profile_id = '44444444-4444-4444-4444-444444444444'
    and device_fingerprint = 'TELEPHONE-MAMAN';
  update public.devices set revoked_at = now() where id = v_revoque;

  select code into v_code from public.creer_code_appairage('44444444-4444-4444-4444-444444444444');
  perform public.consommer_code_appairage(v_code, 'ORDINATEUR-PAPA', 'windows');

  begin
    update public.devices set revoked_at = null where id = v_revoque;
    raise exception 'S7 ECHEC : un appareil revoque a pu etre reactive au-dela du plafond';
  exception when sqlstate 'P0001' then
    if position('plafond' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S7b ok : la reactivation ne contourne pas le plafond';
end $$;

-- ============================================================
-- S8 : un code expire ou deja consomme est refuse
-- ============================================================

do $$
declare v_code text;
begin
  select code into v_code from public.creer_code_appairage('55555555-5555-5555-5555-555555555555');
  perform public.consommer_code_appairage(v_code, 'TELEPHONE-IBRAHIM', 'ios');
  begin
    perform public.consommer_code_appairage(v_code, 'AUTRE-APPAREIL', 'web');
    raise exception 'S8 ECHEC : un code deja consomme a ete accepte';
  exception when sqlstate 'P0001' then
    if position('deja utilise' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S8a ok : un code consomme ne se rejoue pas';
end $$;

do $$
declare v_code text;
begin
  update public.devices set revoked_at = now()
  where profile_id = '55555555-5555-5555-5555-555555555555';

  select code into v_code from public.creer_code_appairage('55555555-5555-5555-5555-555555555555');
  update public.device_pairing_codes set expires_at = now() - interval '1 minute'
  where consumed_at is null and deleted_at is null
    and student_profile_id = '55555555-5555-5555-5555-555555555555';

  begin
    perform public.consommer_code_appairage(v_code, 'APPAREIL-TARDIF', 'web');
    raise exception 'S8 ECHEC : un code expire a ete accepte';
  exception when sqlstate 'P0001' then
    if position('expire' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S8b ok : un code expire est refuse';
end $$;

-- Un code inconnu ne dit pas pourquoi il est inconnu.
do $$
begin
  begin
    perform public.consommer_code_appairage('ZZZZZZ', 'APPAREIL-INTRUS', 'web');
    raise exception 'S8 ECHEC : un code invente a ete accepte';
  exception when sqlstate 'P0001' then
    if position('inconnu' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'S8c ok : un code inconnu est refuse';
end $$;

-- ============================================================
-- La revocation : possible pour le tuteur, bornee a son foyer
-- ============================================================

do $$
declare v_device uuid;
begin
  select id into v_device from public.devices
  where profile_id = '44444444-4444-4444-4444-444444444444'
    and revoked_at is null limit 1;

  perform public.revoquer_appareil(v_device);

  if (select revoked_at from public.devices where id = v_device) is null then
    raise exception 'REVOCATION ECHEC : l''appareil n''a pas ete revoque';
  end if;
  -- Un appareil revoque dont le jeton survivrait resterait utilisable.
  if (select token_hash from public.devices where id = v_device) is not null then
    raise exception 'REVOCATION ECHEC : le jeton survit a la revocation';
  end if;
  raise notice 'Revocation ok : le tuteur retire un appareil, et son jeton avec';
end $$;

do $$
declare v_device uuid;
begin
  -- Un tuteur d'un autre foyer ne revoque rien.
  select id into v_device from public.devices limit 1;
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"00000000-0000-0000-0000-000000000000"}}',
    true);
  begin
    perform public.revoquer_appareil(v_device);
    raise exception 'REVOCATION ECHEC : un appareil d''un autre foyer a pu etre revoque';
  exception when sqlstate 'P0001' then
    if position('votre foyer' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'Revocation ok : bornee au foyer de l''appelant';
end $$;

-- ============================================================
-- Le tuteur voit ses codes sans jamais voir leur empreinte
-- ============================================================

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'mes_codes_appairage_v'
      and column_name = 'code_hash'
  ) then
    raise exception 'PRINCIPE 8 ECHEC : la vue expose l''empreinte du code';
  end if;
  raise notice 'Vue ok : le tuteur lit ses codes sans leur empreinte';
end $$;

-- ============================================================
-- Etat du dossier, tel que le portail d'attente le lira
-- ============================================================

select set_config('test.uid', '22222222-2222-2222-2222-222222222222', false);
select set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', false);
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","app_metadata":{"role":"teacher"}}', false);

do $$
declare v_etat jsonb;
begin
  v_etat := public.etat_dossier();
  if (v_etat ->> 'piece_statut') <> 'rejected' then
    raise exception 'ETAT ECHEC : statut de piece % au lieu de rejected', v_etat ->> 'piece_statut';
  end if;
  if (v_etat ->> 'motif_refus') is null then
    raise exception 'ETAT ECHEC : le portail d''attente n''a aucun motif a afficher';
  end if;
  if (v_etat ->> 'contrat_signe') <> 'false' then
    raise exception 'ETAT ECHEC : contrat signe sans acceptation';
  end if;
  raise notice 'Etat ok : le portail d''attente sait quoi afficher';
end $$;

-- Une acceptation de contrat est un fait : ni modifiable, ni effacable.
-- La fixture synthétique reste distincte du texte juridique approuvé publié
-- par la migration 0090.
-- L'enseignant signe dès pending_kyc, avant que la direction l'active.

-- Avis de contrôle préchargé par le propriétaire du scénario : il n'existe pas
-- de RPC de signature dédiée à cet avis.
insert into public.contract_acceptances (profile_id, contract_kind, version)
values (
  '22222222-2222-2222-2222-222222222222',
  'recording_and_control_notice', '2026-10-jur'
);

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","app_metadata":{"role":"teacher"}}', true);
  perform public.signer_contrat('2026-10-jur', 'Yasmine Test');
end $$;

reset role;
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', false);
update public.profiles set account_status = 'active'
where id = '22222222-2222-2222-2222-222222222222';

-- Bascule la fixture vers sa propre version courante pour tester signer_contrat.
update public.contract_texts set is_current = false
where contract_kind = 'teacher_nda' and locale = 'fr' and is_current;

insert into public.contract_texts (
  contract_kind, version, locale, body, sha256, is_current
) values (
  'teacher_nda', 'test-signature-0057', 'fr',
  'Texte synthétique réservé au test de signature.',
  encode(extensions.digest(
    convert_to('Texte synthétique réservé au test de signature.', 'UTF8'), 'sha256'
  ), 'hex'),
  false
);

update public.contract_texts set is_current = true
where contract_kind = 'teacher_nda'
  and version = 'test-signature-0057'
  and locale = 'fr';

update public.profiles set account_status = 'disabled'
where id = '66666666-6666-6666-6666-666666666666';

do $$
declare
  v_signature public.contract_acceptances%rowtype;
  v_rejouee public.contract_acceptances%rowtype;
  v_refus text;
begin
  set local role authenticated;
  perform set_config('test.uid', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
  perform set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","app_metadata":{"role":"guardian"}}', true);
  begin
    insert into public.contract_acceptances (
      profile_id, contract_kind, version, signer_name
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'teacher_nda', 'test-signature-0057', 'Parent Test'
    );
    raise exception 'CONTRAT ECHEC : un tuteur a pu signer comme enseignant';
  exception when insufficient_privilege then
    null;
  end;

  perform set_config('test.uid', '66666666-6666-6666-6666-666666666666', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  perform set_config('request.jwt.claim.sub', '66666666-6666-6666-6666-666666666666', true);
  perform set_config('request.jwt.claims', '{"sub":"66666666-6666-6666-6666-666666666666","app_metadata":{"role":"teacher"}}', true);
  begin
    insert into public.contract_acceptances (
      profile_id, contract_kind, version, signer_name
    ) values (
      '66666666-6666-6666-6666-666666666666',
      'teacher_nda', 'test-signature-0057', 'Compte Desactive'
    );
    raise exception 'CONTRAT ECHEC : un compte desactive a pu signer';
  exception when insufficient_privilege then
    null;
  end;

  perform set_config('test.uid', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
  perform set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","app_metadata":{"role":"teacher"}}', true);

  begin
    insert into public.contract_acceptances (
      profile_id, contract_kind, version, signer_name, signed_sha256
    ) values (
      '22222222-2222-2222-2222-222222222222',
      'teacher_nda', 'test-signature-0057', 'Enseignant Test', repeat('0', 64)
    );
    raise exception 'CONTRAT ECHEC : le client a pu fournir son empreinte';
  exception when insufficient_privilege then
    null;
  end;

  select * into v_signature
  from public.signer_contrat('test-signature-0057', '  Yasmine Test  ');
  select * into v_rejouee
  from public.signer_contrat('test-signature-0057', 'Autre nom');

  if v_signature.id is distinct from v_rejouee.id
     or v_signature.accepted_at is distinct from v_rejouee.accepted_at then
    raise exception 'CONTRAT ECHEC : le rejeu n''a pas renvoye la signature initiale';
  end if;
  if v_signature.signer_name is distinct from 'Yasmine Test'
     or v_signature.signed_sha256 is distinct from (
       select t.sha256 from public.contract_texts t
       where t.contract_kind = 'teacher_nda'
         and t.version = 'test-signature-0057' and t.locale = 'fr'
     ) then
    raise exception 'CONTRAT ECHEC : nom ou empreinte source different du texte courant';
  end if;

  begin
    perform public.signer_contrat('ancienne-version', 'Yasmine Test');
    raise exception 'CONTRAT ECHEC : une version perimee a ete signee';
  exception when sqlstate 'P0001' then
    get stacked diagnostics v_refus = message_text;
    if v_refus not like 'version_perimee:%' then raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.contract_acceptances set version = '2020-01'
    where profile_id = '22222222-2222-2222-2222-222222222222';
    raise exception 'CONTRAT ECHEC : une acceptation a pu etre modifiee';
  exception when sqlstate 'P0001' then
    if position('ne se modifie' in sqlerrm) = 0 then raise; end if;
  end;
  begin
    delete from public.contract_acceptances
    where profile_id = '22222222-2222-2222-2222-222222222222';
    raise exception 'CONTRAT ECHEC : une acceptation a pu etre effacee';
  exception when sqlstate 'P0001' then
    if position('ne se modifie' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice 'Contrat ok : une signature ne se modifie ni ne s''efface';
end $$;

-- ============================================================
-- Invariant ADR-014 deja verifie par la CI, reverifie apres 0004
-- ============================================================

do $$
begin
  if (select column_default from information_schema.columns
      where table_schema = 'public' and table_name = 'profiles'
        and column_name = 'account_status')
     is distinct from '''pending_kyc''::account_status' then
    raise exception 'ADR-014 ECHEC : une nouvelle inscription ne naît plus pending_kyc';
  end if;
  raise notice 'ADR-014 ok : le defaut de compte reste pending_kyc';
end $$;

-- ============================================================
-- Le journal d'audit ne se lit pas par sa partition
-- ============================================================

do $$
declare v_parent int; v_partition int;
begin
  set local role authenticated;
  perform set_config('test.uid', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);

  select count(*) into v_parent from public.audit_logs;
  if v_parent <> 0 then
    raise exception 'AUDIT ECHEC : un tuteur lit % lignes du journal par le parent', v_parent;
  end if;

  begin
    select count(*) into v_partition from public.audit_logs_default;
  exception when insufficient_privilege then
    v_partition := -1;
  end;
  if v_partition > 0 then
    raise exception 'AUDIT ECHEC : un tuteur lit % lignes du journal par la partition', v_partition;
  end if;

  raise notice 'Audit ok : le journal ne fuit ni par le parent ni par la partition';
end $$;

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', '11111111-1111-1111-1111-111111111111', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
  begin
    insert into public.audit_logs (action, table_name, hash)
    values ('forge', 'profiles', 'x');
    raise exception 'AUDIT ECHEC : une ligne de journal a pu etre forgee par la partition';
  exception when insufficient_privilege then
    null;
  end;
  raise notice 'Audit ok : aucune ligne de journal ne se forge depuis un compte';
end $$;

-- ============================================================
-- Aucune table sans RLS
-- ============================================================

do $$
declare v_sans text;
begin
  select string_agg(c.relname, ', ') into v_sans
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity;
  if v_sans is not null then
    raise exception 'RLS ECHEC : tables sans RLS : %', v_sans;
  end if;
  raise notice 'RLS ok : aucune table publique sans RLS';
end $$;

-- ============================================================
-- Aucune fonction SECURITY DEFINER sans search_path fixe
-- ============================================================

do $$
declare v_sans text;
begin
  select string_agg(p.proname, ', ') into v_sans
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef
    and not exists (
      select 1 from unnest(coalesce(p.proconfig, array[]::text[])) cfg
      where cfg like 'search_path=%'
    );
  if v_sans is not null then
    raise exception 'SEARCH_PATH ECHEC : % ', v_sans;
  end if;
  raise notice 'search_path ok : toute fonction SECURITY DEFINER le fixe';
end $$;

-- F70 : ni l'insertion directe ni un changement de rôle ne peuvent créer un
-- enseignant déjà actif sans la signature du texte courant.
INSERT INTO auth.users (id, email) VALUES
  ('88888888-8888-8888-8888-888888888881', 'f70-teacher@example.test'),
  ('88888888-8888-8888-8888-888888888882', 'f70-student@example.test');
INSERT INTO public.households (id, timezone, status)
VALUES ('88888888-8888-8888-8888-888888888883', 'Europe/Paris', 'active');

do $$
begin
  begin
    insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status)
    values ('88888888-8888-8888-8888-888888888881', 'F70INSERT000001',
            'teacher', 'Sans', 'Signature', 'active');
    raise exception 'F70 ECHEC : insertion enseignant actif sans signature acceptée';
  exception when check_violation then
    if position('contract_not_signed_current:teacher_nda' in sqlerrm) = 0 then raise; end if;
  end;

  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  values ('88888888-8888-8888-8888-888888888882', 'F70ROLE0000001',
          'student', '88888888-8888-8888-8888-888888888883',
          'Sans', 'Signature', 'active');
  begin
    update public.profiles set role = 'teacher'
    where id = '88888888-8888-8888-8888-888888888882';
    raise exception 'F70 ECHEC : promotion role-only vers enseignant actif acceptée';
  exception when check_violation then
    if position('contract_not_signed_current:teacher_nda' in sqlerrm) = 0 then raise; end if;
  end;
end $$;

select 'TOUS LES SCENARIOS SQL DE L''ETAPE 3 SONT PASSES' as verdict;
