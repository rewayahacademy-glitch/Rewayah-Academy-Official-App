-- Scenarios d'acceptation SQL du stockage R2 (migration 0034).
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un << pas d'erreur >>.
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les migrations.
-- Un fichier de scenarios ne se rejoue jamais deux fois sur la meme base : il
-- insere ses fixtures.
--
-- CE QUE CE FICHIER NE MESURE PAS, ET POURQUOI.
--
-- Il ne mesure aucune connexion a Cloudflare. Les quatre seaux ont ete eprouves
-- le 21 septembre 2026, cycle complet compris ; refaire cette preuve ici
-- n'apprendrait rien et exigerait des secrets dans la CI. Le routage des quatre
-- domaines vers leurs quatre seaux, la forme des URL signees et les verrous du
-- depot se mesurent la ou ils vivent, en Deno :
-- `supabase/functions/_shared/r2/*_test.ts`.
--
-- Ce fichier mesure LA PORTE : qui obtient le droit de faire signer une URL, et
-- surtout qui ne l'obtient pas. C'est la moitie qui ne peut se prouver qu'en
-- base, la ou les roles, la RLS, les relations de seance et le journal d'audit
-- sont sous la main.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml` : le
-- controle J4 de ce dernier verifie l'integrite de tout ce que les fichiers
-- precedents ont ecrit, et chacune des portes ci-dessous ecrit dans
-- `audit_logs`.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler les restrictions que 0034 pose. En
-- production l'ordre est inverse : les droits par defaut sont accordes a la
-- creation, la migration les restreint ensuite. On rejoue donc les restrictions,
-- sans quoi R15 et R16 mesureraient le harnais et non la migration.
revoke execute on function
  public.autoriser_lecture_piece_identite(uuid),
  public.peut_deposer_piece_identite(uuid),
  public.preparer_depot_piece_identite(uuid, text),
  public.confirmer_depot_piece_identite(uuid),
  public.autoriser_ecoute_archive(uuid),
  public.geler_archive_seance(uuid, text, boolean),
  public.enregistrer_archive_seance(text, text, text, int, bigint, text)
  from anon, public;
revoke execute on function
  public.enregistrer_archive_seance(text, text, text, int, bigint, text),
  public.confirmer_depot_piece_identite(uuid)
  from authenticated;

-- ============================================================
-- Fixtures
-- ============================================================
--
--   * Hafsa administre et son dossier la dit `female` : elle ouvre les pieces
--     feminines, et elle seule.
--   * Omar administre aussi, dossier `male` : c'est lui qui mesure le
--     cloisonnement, puisqu'il ne doit PAS ouvrir la piece de Sara.
--   * Yacine enseigne la seance archivee.
--   * Sara, eleve du foyer A, y participe. Sa piece d'identite est la cible.
--   * Malik tutore le foyer A : il depose pour Sara, jamais pour un autre.
--   * Nadia tutore le foyer B : elle n'a part a rien, et c'est elle qui mesure
--     les refus.

insert into auth.users (id, email) values
  ('c4000000-0000-0000-0000-000000000001', 'hafsa@example.test'),
  ('c4000000-0000-0000-0000-000000000002', 'omar@example.test'),
  ('c4000000-0000-0000-0000-000000000003', 'yacine@example.test'),
  ('c4000000-0000-0000-0000-000000000004', 'sara@example.test'),
  ('c4000000-0000-0000-0000-000000000005', 'malik@example.test'),
  ('c4000000-0000-0000-0000-000000000006', 'nadia@example.test');

insert into public.households (id, timezone) values
  ('c4ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('c4ffffff-0000-0000-0000-00000000000b', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c4000000-0000-0000-0000-000000000001', 'ADMN-R2-000001', 'admin',
   null, 'Hafsa', 'Toure', 'active', 'female'),
  ('c4000000-0000-0000-0000-000000000002', 'ADMN-R2-000002', 'admin',
   null, 'Omar', 'Toure', 'active', 'male'),
  ('c4000000-0000-0000-0000-000000000003', 'TEACH-R2-00001', 'teacher',
   null, 'Yacine', 'Sow', 'provisional_active', 'male'),
  ('c4000000-0000-0000-0000-000000000004', 'STUD-R2-000001', 'student',
   'c4ffffff-0000-0000-0000-00000000000a', 'Sara', 'Diallo', 'active', 'female'),
  ('c4000000-0000-0000-0000-000000000005', 'GUAR-R2-000001', 'guardian',
   'c4ffffff-0000-0000-0000-00000000000a', 'Malik', 'Diallo', 'active', 'male'),
  ('c4000000-0000-0000-0000-000000000006', 'GUAR-R2-000002', 'guardian',
   'c4ffffff-0000-0000-0000-00000000000b', 'Nadia', 'Kane', 'active', 'female');
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
values ('c4000000-0000-0000-0000-000000000004', 'minor', 'standard', 'forbidden');

-- Le genre du LECTEUR est lu sur son propre dossier (`read_kyc_documents`,
-- 0001). Sans ces deux pieces, Hafsa et Omar liraient tous deux le versant
-- masculin par defaut et le cloisonnement ne serait pas mesurable.
insert into public.kyc_documents (id, profile_id, doc_type, gender, object_key, status)
values
  ('c4dddddd-0000-0000-0000-00000000000f', 'c4000000-0000-0000-0000-000000000001',
   'id_card', 'female', 'c4000000-0000-0000-0000-000000000001/1.jpg', 'approved'),
  ('c4dddddd-0000-0000-0000-00000000000e', 'c4000000-0000-0000-0000-000000000002',
   'id_card', 'male', 'c4000000-0000-0000-0000-000000000002/1.jpg', 'approved');

-- La piece cible : celle de Sara, feminine, encore dans le stockage historique.
insert into public.kyc_documents (id, profile_id, doc_type, gender, object_key, status)
values
  ('c4dddddd-0000-0000-0000-00000000000a', 'c4000000-0000-0000-0000-000000000004',
   'passport', 'female', 'c4000000-0000-0000-0000-000000000004/1700000000.jpg', 'pending');

insert into public.sessions (id, teacher_id, started_at, ended_at, status)
values
  ('c4aaaaaa-0000-0000-0000-00000000000a',
   'c4000000-0000-0000-0000-000000000003',
   now() - interval '3 hours', now() - interval '2 hours', 'ended');

insert into public.session_participants (session_id, profile_id, role) values
  ('c4aaaaaa-0000-0000-0000-00000000000a', 'c4000000-0000-0000-0000-000000000003', 'teacher'),
  ('c4aaaaaa-0000-0000-0000-00000000000a', 'c4000000-0000-0000-0000-000000000004', 'student');

-- La salle, telle que `0010` la fige a la premiere emission de jeton. C'est
-- elle qui permet a l'entree des metadonnees de retrouver la seance sans que
-- le webhook ait a la nommer.
insert into public.session_video_route (session_id, provider, ws_url, room_name)
values ('c4aaaaaa-0000-0000-0000-00000000000a', 'cloud',
        'wss://cloud.example', 'salle-r2-000000000a');

-- ============================================================
-- R1 : l'entree des metadonnees resout la seance par la SALLE, et elle est
--      idempotente -- un webhook n'arrive ni une fois, ni dans l'ordre
-- ============================================================

do $$
declare
  v_un uuid;
  v_deux uuid;
  v_lignes int;
  v_expire timestamptz;
begin
  set local role service_role;

  v_un := public.enregistrer_archive_seance(
    'salle-r2-000000000a', 'EG_R2_0001',
    'recordings/c4aaaaaa-0000-0000-0000-00000000000a/c4bbbbbb-0000-0000-0000-00000000000a.ogg',
    3600, 15728640, 'opus');

  -- Le meme Egress, rejoue. L'unicite de `egress_id` tranche, pas une
  -- condition ecrite dans la fonction.
  v_deux := public.enregistrer_archive_seance(
    'salle-r2-000000000a', 'EG_R2_0001',
    'recordings/c4aaaaaa-0000-0000-0000-00000000000a/c4bbbbbb-0000-0000-0000-00000000000a.ogg',
    3600, 15728640, 'opus');

  if v_un is null or v_un <> v_deux then
    raise exception 'R1 : l entree des metadonnees n est pas idempotente';
  end if;

  select count(*) into v_lignes
  from public.session_recordings
  where session_id = 'c4aaaaaa-0000-0000-0000-00000000000a';
  if v_lignes <> 1 then
    raise exception 'R1 : % lignes pour un seul Egress', v_lignes;
  end if;

  -- La duree de conservation vient de `app_config`, pas d'une valeur en dur.
  select expires_at into v_expire from public.session_recordings where id = v_un;
  if v_expire <= now() + interval '29 days' or v_expire >= now() + interval '31 days' then
    raise exception 'R1 : expiration hors de la retention de trente jours (%)', v_expire;
  end if;

  -- Une salle inconnue ne cree rien : la seance est resolue, jamais recue.
  begin
    perform public.enregistrer_archive_seance(
      'salle-qui-n-existe-pas', 'EG_R2_0002', 'recordings/x/y.ogg', 10, 10, null);
    raise exception 'R1 : une salle inconnue a ete acceptee';
  exception when foreign_key_violation then null;
  end;
end $$;

-- ============================================================
-- R2 : un anonyme n'obtient aucune autorisation, donc aucune URL
-- ============================================================
--
-- Le point precis que `0029` a paye cher : une porte ecrite en refus
-- (`app_role() <> 'admin'`) ne se declenche pas sur le NULL d'un appelant sans
-- role. Les portes de `0034` sont ecrites en exigence positive ; ce controle
-- mesure qu'elles ferment vraiment pour `anon`, et que le `revoke` tient meme
-- si la porte etait un jour reecrite.

do $$
declare
  v_execute boolean;
begin
  -- Defense 1 : le droit d'EXECUTE lui-meme.
  for v_execute in
    select has_function_privilege('anon', f, 'execute')
    from unnest(array[
      'public.autoriser_lecture_piece_identite(uuid)',
      'public.preparer_depot_piece_identite(uuid, text)',
      'public.autoriser_ecoute_archive(uuid)',
      'public.enregistrer_archive_seance(text, text, text, int, bigint, text)',
      'public.geler_archive_seance(uuid, text, boolean)'
    ]) as f
  loop
    if v_execute then
      raise exception 'R2 : anon garde un droit d execute sur une porte R2';
    end if;
  end loop;
end $$;

do $$
begin
  -- Defense 2 : la porte elle-meme, atteinte en se donnant le droit.
  set local role authenticated;
  perform set_config('test.uid', '', true);
  perform set_config('test.jwt', '{}', true);

  begin
    perform public.autoriser_lecture_piece_identite('c4dddddd-0000-0000-0000-00000000000a');
    raise exception 'R2 : un appelant sans role a ouvert une piece d identite';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.autoriser_ecoute_archive(
      (select id from public.session_recordings
        where session_id = 'c4aaaaaa-0000-0000-0000-00000000000a'));
    raise exception 'R2 : un appelant sans role a obtenu une archive';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- R3 : un role non autorise n'ouvre aucune piece d'identite
-- ============================================================

do $$
declare
  v_roles text[][] := array[
    ['c4000000-0000-0000-0000-000000000005', 'guardian'],
    ['c4000000-0000-0000-0000-000000000003', 'teacher'],
    ['c4000000-0000-0000-0000-000000000004', 'student']
  ];
  v_i int;
begin
  set local role authenticated;
  for v_i in 1 .. array_length(v_roles, 1) loop
    perform set_config('test.uid', v_roles[v_i][1], true);
    perform set_config('test.jwt',
      format('{"app_metadata":{"role":"%s"}}', v_roles[v_i][2]), true);
    begin
      perform public.autoriser_lecture_piece_identite('c4dddddd-0000-0000-0000-00000000000a');
      raise exception 'R3 : le role % a ouvert une piece d identite', v_roles[v_i][2];
    exception when insufficient_privilege then null;
    end;
  end loop;

  -- Y compris le TUTEUR de l'enfant concerne : deposer n'est pas relire.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
  begin
    perform public.autoriser_lecture_piece_identite('c4dddddd-0000-0000-0000-00000000000a');
    raise exception 'R3 : le tuteur du foyer a relu la piece';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- R4 : le cloisonnement par genre tient jusque dans l'ouverture d'UNE piece
-- ============================================================
--
-- C'est le controle du lot. Omar administre, donc il passe la porte de role.
-- Il ne doit pourtant pas obtenir la cle de la piece de Sara, et le refus doit
-- etre indistinct d'une piece inexistante : la difference renseignerait sur le
-- contenu du coffre.

do $$
declare
  v_resultat jsonb;
begin
  set local role authenticated;

  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  begin
    perform public.autoriser_lecture_piece_identite('c4dddddd-0000-0000-0000-00000000000a');
    raise exception 'R4 : un administrateur masculin a ouvert une piece feminine';
  exception when insufficient_privilege then null;
  end;

  -- Hafsa, elle, l'ouvre -- et obtient la cle et le stockage a interroger.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  v_resultat := public.autoriser_lecture_piece_identite('c4dddddd-0000-0000-0000-00000000000a');

  if v_resultat ->> 'object_key' <> 'c4000000-0000-0000-0000-000000000004/1700000000.jpg' then
    raise exception 'R4 : cle inattendue (%)', v_resultat ->> 'object_key';
  end if;
  if v_resultat ->> 'storage_backend' <> 'supabase' then
    raise exception 'R4 : le stockage historique n est pas signale comme tel';
  end if;
end $$;

-- ============================================================
-- R5 : chaque ouverture est journalisee AVEC l'identite de celle qui regarde
-- ============================================================
--
-- L'exigence de l'ADR-002, litteralement. Elle n'est tenue que parce que la
-- RPC est appelee sous le jeton de l'appelant : avec la cle de service,
-- `auth.uid()` rendrait NULL et le journal porterait un acteur vide.

do $$
declare
  v_acteur uuid;
  v_ligne text;
begin
  set local role service_role;
  select actor, row_id into v_acteur, v_ligne
  from public.audit_logs
  where action = 'kyc_document_open'
  order by created_at desc limit 1;

  if v_acteur is distinct from 'c4000000-0000-0000-0000-000000000001' then
    raise exception 'R5 : la trace ne designe pas l auditrice (%)', v_acteur;
  end if;
  if v_ligne is distinct from 'c4dddddd-0000-0000-0000-00000000000a' then
    raise exception 'R5 : la trace ne designe pas la piece ouverte (%)', v_ligne;
  end if;
end $$;

-- ============================================================
-- R6 : au depot, la cle est fabriquee par le serveur et suit la convention
-- ============================================================

do $$
declare
  v_resultat jsonb;
  v_cle text;
  v_attendue text;
begin
  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);

  v_resultat := public.preparer_depot_piece_identite(
    'c4000000-0000-0000-0000-000000000004', 'id_card');

  v_cle := v_resultat ->> 'object_key';
  v_attendue := 'identity/c4000000-0000-0000-0000-000000000004/' || (v_resultat ->> 'document_id');
  if v_cle is distinct from v_attendue then
    raise exception 'R6 : cle hors convention (%)', v_cle;
  end if;

  -- Aucune donnee lisible dans la cle : ni nom, ni type de piece, ni genre.
  if v_cle ilike '%diallo%' or v_cle ilike '%id_card%' or v_cle ilike '%female%' then
    raise exception 'R6 : la cle porte une donnee lisible (%)', v_cle;
  end if;

  -- La ligne est creee, marquee `r2`, et son genre a ete ECRASE par celui du
  -- profil : le deposant ne choisit pas qui pourra la regarder.
  --
  -- La verification se fait en `service_role`, et c'est un constat en soi :
  -- aucune policy de SELECT n'existe pour un tuteur sur `kyc_documents`
  -- (`0001` ne lui donne que l'ecriture). Il depose donc une piece qu'il ne
  -- peut pas relire -- ce qui est le comportement voulu, et que R3 mesure par
  -- ailleurs du cote de la porte serveur.
  set local role service_role;
  if not exists (
    select 1 from public.kyc_documents
    where id = (v_resultat ->> 'document_id')::uuid
      and storage_backend = 'r2' and status = 'pending' and gender = 'female'
      -- La reservation nait INVISIBLE : l'objet n'est pas encore depose.
      and deleted_at is not null
  ) then
    raise exception 'R6 : la ligne preparee est absente ou mal classee';
  end if;

  -- Et elle n'entre pas dans la file de validation tant qu'elle n'est pas
  -- confirmee : c'est tout l'objet de la naissance invisible. Sans cela,
  -- l'administration ouvrirait un document qui n'existe pas dans le coffre.
  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  if exists (
    select 1 from public.dossiers_en_attente()
    where document_id = (v_resultat ->> 'document_id')::uuid
  ) then
    raise exception 'R6 : une reservation non confirmee est entree dans ADM-02';
  end if;
end $$;

-- ============================================================
-- R6 bis : la confirmation rend la piece visible, et elle est hors de portee
--          d'un compte humain
-- ============================================================
--
-- La confirmation n'est accordee qu'a `service_role` parce que la fonction Edge
-- qui l'appelle vient d'interroger R2 par un HEAD. Si un compte pouvait
-- l'appeler directement, cette verification deviendrait contournable, donc
-- inutile : la reservation redeviendrait une simple declaration du client.

do $$
declare
  v_doc uuid;
begin
  set local role service_role;
  select id into v_doc from public.kyc_documents
  where profile_id = 'c4000000-0000-0000-0000-000000000004'
    and storage_backend = 'r2' and deleted_at is not null
  order by created_at desc limit 1;

  if has_function_privilege('authenticated',
       'public.confirmer_depot_piece_identite(uuid)', 'execute') then
    raise exception 'R6 bis : un compte humain peut confirmer un depot sans verification';
  end if;

  perform public.confirmer_depot_piece_identite(v_doc);

  if exists (select 1 from public.kyc_documents where id = v_doc and deleted_at is not null) then
    raise exception 'R6 bis : la piece confirmee est restee invisible';
  end if;

  -- Deux fois n'est pas mieux qu'une : la seconde confirmation ne trouve plus
  -- de reservation a confirmer et refuse franchement.
  begin
    perform public.confirmer_depot_piece_identite(v_doc);
    raise exception 'R6 bis : une piece deja confirmee a ete reconfirmee';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- R6 ter : un ELEVE ne depose aucune piece, ni pour lui, ni pour son foyer
-- ============================================================
--
-- Les trois policies d'insertion de `kyc_documents` excluent le role `student`.
-- Mais tout eleve a un foyer (`profiles_household_required`, 0004), donc son
-- jeton porte un `household_id` : une porte qui se contenterait de << pour soi
-- ou pour son foyer >> le laisserait creer une piece au nom de son tuteur, puis
-- obtenir une URL de depot sous le prefixe de celui-ci dans le coffre.

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);

  if public.peut_deposer_piece_identite('c4000000-0000-0000-0000-000000000004') then
    raise exception 'R6 ter : un eleve peut deposer pour lui-meme';
  end if;
  if public.peut_deposer_piece_identite('c4000000-0000-0000-0000-000000000005') then
    raise exception 'R6 ter : un eleve peut deposer au nom de son tuteur';
  end if;

  begin
    perform public.preparer_depot_piece_identite(
      'c4000000-0000-0000-0000-000000000005', 'id_card');
    raise exception 'R6 ter : un eleve a reserve une piece au nom de son tuteur';
  exception when insufficient_privilege then null;
  end;

  -- L'enseignant depose pour LUI (kyc_staff_self_insert), jamais pour un autre.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  if not public.peut_deposer_piece_identite('c4000000-0000-0000-0000-000000000003') then
    raise exception 'R6 ter : un enseignant ne peut pas deposer sa propre piece';
  end if;
  if public.peut_deposer_piece_identite('c4000000-0000-0000-0000-000000000004') then
    raise exception 'R6 ter : un enseignant peut deposer pour un eleve';
  end if;
end $$;

-- ============================================================
-- R7 : on ne depose pas pour un profil qui n'est pas de son foyer
-- ============================================================

do $$
begin
  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000006', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000b"}}', true);

  begin
    perform public.preparer_depot_piece_identite(
      'c4000000-0000-0000-0000-000000000004', 'id_card');
    raise exception 'R7 : un tuteur a depose pour l enfant d un autre foyer';
  exception when insufficient_privilege then null;
  end;

  -- Et un type de piece hors de la liste fermee est refuse.
  begin
    perform public.preparer_depot_piece_identite(null, 'sagouin');
    raise exception 'R7 : un type de piece inconnu a ete accepte';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- ============================================================
-- R8 : l'ecoute d'une archive exige une relation avec la seance
-- ============================================================

do $$
declare
  v_archive uuid;
  v_resultat jsonb;
begin
  select id into v_archive from public.session_recordings
  where session_id = 'c4aaaaaa-0000-0000-0000-00000000000a';

  set local role authenticated;

  -- Nadia n'a part ni a la seance, ni au foyer de Sara.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000006', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000b"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R8 : un tiers sans relation a obtenu une archive';
  exception when insufficient_privilege then null;
  end;

  -- L'enseignant de la seance, lui, l'obtient.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  v_resultat := public.autoriser_ecoute_archive(v_archive);
  if v_resultat ->> 'object_key' not like 'recordings/%' then
    raise exception 'R8 : cle d archive inattendue';
  end if;

  -- Le foyer d'un participant aussi.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);
  perform public.autoriser_ecoute_archive(v_archive);
end $$;

-- ============================================================
-- R9 : une archive expiree se tait, et un gel legal la garde ouverte a la
--      seule administration
-- ============================================================
--
-- C'est l'exigence que la specification interdit de rendre impossible : une
-- purge ecrite sans etat de gel effacerait une piece sous litige. La colonne
-- existe, elle se pose, et elle change ce que la porte repond.

do $$
declare
  v_archive uuid;
begin
  select id into v_archive from public.session_recordings
  where session_id = 'c4aaaaaa-0000-0000-0000-00000000000a';

  set local role service_role;
  update public.session_recordings set expires_at = now() - interval '1 day'
  where id = v_archive;

  set local role authenticated;

  -- Expiree : le foyer n'ecoute plus, meme s'il avait le droit hier.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R9 : une archive expiree a ete servie';
  exception when insufficient_privilege then null;
  end;

  -- Expiree et sans gel : l'administration non plus.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R9 : une archive expiree a ete servie a l administration';
  exception when insufficient_privilege then null;
  end;

  -- Le gel exige un motif.
  begin
    perform public.geler_archive_seance(v_archive, '   ', true);
    raise exception 'R9 : un gel sans motif a ete accepte';
  exception when invalid_parameter_value then null;
  end;

  -- Et un sens de gel NON PRECISE echoue, au lieu de degeler en silence.
  -- Sans ce refus, `if p_gel and ...` ne se declenche pas (NULL and true vaut
  -- NULL, donc aucun motif n'est exige) et le `case when p_gel then ... else
  -- null end` tombe dans le ELSE : une archive retenue pour un litige perdrait
  -- sa protection sur un argument omis. C'est le renversement que `0029` a
  -- corrige ailleurs -- l'inconnue doit fermer, pas ouvrir.
  begin
    perform public.geler_archive_seance(v_archive, 'un motif', null);
    raise exception 'R9 : un sens de gel NULL a ete accepte';
  exception when invalid_parameter_value then null;
  end;

  perform public.geler_archive_seance(v_archive, 'litige ouvert le 21 septembre', true);

  -- Le motif ne vit PAS sur la ligne : la RLS borne les lignes, jamais les
  -- colonnes, et les deux policies de `session_recordings` donnent le select a
  -- l'enseignant de la seance et au foyer d'un participant. Un motif tel que
  -- << plainte contre l'enseignant Y >> y serait lisible par l'interesse.
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'session_recordings'
      and column_name = 'legal_hold_reason'
  ) then
    raise exception 'R9 : le motif du gel est stocke sur une ligne que l enseignant peut lire';
  end if;

  -- Gelee : l'administration retrouve l'acces, le foyer non.
  perform public.autoriser_ecoute_archive(v_archive);

  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R9 : un gel legal a rouvert l archive a la famille';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ============================================================
-- R10 : le gel est reserve a l'administration, et une archive revoquee se tait
--       pour tout le monde
-- ============================================================

do $$
declare
  v_archive uuid;
begin
  select id into v_archive from public.session_recordings
  where session_id = 'c4aaaaaa-0000-0000-0000-00000000000a';

  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.geler_archive_seance(v_archive, 'je decide', true);
    raise exception 'R10 : un enseignant a pose un gel de conservation';
  exception when insufficient_privilege then null;
  end;

  set local role service_role;
  update public.session_recordings
  set status = 'revoked', expires_at = now() + interval '10 days'
  where id = v_archive;

  set local role authenticated;
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R10 : une archive revoquee a ete servie a l administration';
  exception when insufficient_privilege then null;
  end;

  -- Etat rendu, pour ne pas changer le sens des fichiers suivants.
  set local role service_role;
  update public.session_recordings set status = 'available' where id = v_archive;
end $$;

-- ============================================================
-- R11 : chaque ecoute laisse sa trace, et le gel aussi
-- ============================================================

do $$
declare
  v_ecoutes int;
  v_gels int;
  v_acteur uuid;
begin
  set local role service_role;

  select count(*) into v_ecoutes from public.audit_logs where action = 'recording_listen';
  if v_ecoutes < 3 then
    raise exception 'R11 : % ecoutes journalisees, au moins 3 attendues', v_ecoutes;
  end if;

  select count(*) into v_gels from public.audit_logs where action = 'recording_legal_hold_set';
  if v_gels <> 1 then
    raise exception 'R11 : % poses de gel journalisees, 1 attendue', v_gels;
  end if;

  select actor into v_acteur from public.audit_logs
  where action = 'recording_legal_hold_set' order by created_at desc limit 1;
  if v_acteur is distinct from 'c4000000-0000-0000-0000-000000000001' then
    raise exception 'R11 : le gel n est pas impute a son auteure (%)', v_acteur;
  end if;
end $$;

-- ============================================================
-- R12 : l'entree des metadonnees reste hors de portee d'une personne
-- ============================================================

do $$
begin
  if has_function_privilege('authenticated',
       'public.enregistrer_archive_seance(text, text, text, int, bigint, text)', 'execute') then
    raise exception 'R12 : un compte humain peut ecrire des metadonnees d archive';
  end if;

  -- Et `agent_ro` n'a aucun droit sur les portes qui ECRIVENT -- elles
  -- journalisent toutes, donc aucune n'est en lecture seule (regle de 0014,
  -- que `get_advisors` ne detecte pas).
  if has_function_privilege('agent_ro',
       'public.autoriser_lecture_piece_identite(uuid)', 'execute')
     or has_function_privilege('agent_ro',
       'public.autoriser_ecoute_archive(uuid)', 'execute')
     or has_function_privilege('agent_ro',
       'public.preparer_depot_piece_identite(uuid, text)', 'execute')
     or has_function_privilege('agent_ro',
       'public.geler_archive_seance(uuid, text, boolean)', 'execute')
  then
    raise exception 'R12 : agent_ro a recu un droit sur une fonction d ecriture';
  end if;
end $$;

-- ============================================================
-- R14 : sur une seance de GROUPE, la famille n'ecoute pas les enfants des
--       autres foyers
-- ============================================================
--
-- Le controle du lot, et celui qui a failli manquer.
--
-- `session_in_household()` (0001) rend vrai des qu'UN SEUL participant
-- appartient au foyer interroge. Elle a ete ecrite quand une seance comptait
-- deux personnes : elle voulait alors dire << le foyer de l'eleve de ce
-- cours >>. Depuis le pivot du 19 septembre, `0017` porte
-- `max_participants_per_session` a 7 et ouvre `allow_multi_participant_sessions`.
--
-- Appliquee telle quelle a une archive de groupe, cette relation donnerait a
-- CHAQUE tuteur l'audio complet de la seance, ou recitent aussi les enfants des
-- autres familles. La policy `session_recordings_teacher_family` porte la meme
-- forme, mais elle n'avait jamais servi : rien n'alimentait ni ne lisait cette
-- table avant `0034`. Ouvrir la lecture, c'est l'activer.

insert into auth.users (id, email) values
  ('c4000000-0000-0000-0000-000000000007', 'ines@example.test'),
  ('c4000000-0000-0000-0000-000000000008', 'tuteur-c@example.test');

insert into public.households (id, timezone) values
  ('c4ffffff-0000-0000-0000-00000000000c', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c4000000-0000-0000-0000-000000000007', 'STUD-R2-000002', 'student',
   'c4ffffff-0000-0000-0000-00000000000c', 'Ines', 'Sy', 'active', 'female'),
  ('c4000000-0000-0000-0000-000000000008', 'GUAR-R2-000003', 'guardian',
   'c4ffffff-0000-0000-0000-00000000000c', 'Awa', 'Sy', 'active', 'female');

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values ('c4000000-0000-0000-0000-000000000007', 'minor', 'standard', 'forbidden');

-- Une seance de groupe : l'enseignant, Sara (foyer A) et Ines (foyer C).
insert into public.sessions (id, teacher_id, started_at, ended_at, status)
values
  ('c4aaaaaa-0000-0000-0000-00000000000b',
   'c4000000-0000-0000-0000-000000000003',
   now() - interval '5 hours', now() - interval '4 hours', 'ended');

insert into public.session_participants (session_id, profile_id, role) values
  ('c4aaaaaa-0000-0000-0000-00000000000b', 'c4000000-0000-0000-0000-000000000003', 'teacher'),
  ('c4aaaaaa-0000-0000-0000-00000000000b', 'c4000000-0000-0000-0000-000000000004', 'student'),
  ('c4aaaaaa-0000-0000-0000-00000000000b', 'c4000000-0000-0000-0000-000000000007', 'student');

insert into public.session_video_route (session_id, provider, ws_url, room_name)
values ('c4aaaaaa-0000-0000-0000-00000000000b', 'cloud',
        'wss://cloud.example', 'salle-r2-000000000b');

do $$
declare
  v_archive uuid;
begin
  set local role service_role;
  v_archive := public.enregistrer_archive_seance(
    'salle-r2-000000000b', 'EG_R2_GROUPE',
    'recordings/c4aaaaaa-0000-0000-0000-00000000000b/c4bbbbbb-0000-0000-0000-00000000000b.ogg',
    3600, 15728640, null);

  set local role authenticated;

  -- Le tuteur du foyer A a bien un enfant dans cette seance. Il n'obtient
  -- pourtant rien : l'archive porte aussi la voix d'Ines.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000a"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R14 : un tuteur a obtenu l audio d une seance de groupe';
  exception when insufficient_privilege then null;
  end;

  -- Le tuteur du foyer C non plus, symetriquement.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000008', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c4ffffff-0000-0000-0000-00000000000c"}}', true);
  begin
    perform public.autoriser_ecoute_archive(v_archive);
    raise exception 'R14 : le second foyer a obtenu l audio du groupe';
  exception when insufficient_privilege then null;
  end;

  -- L'enseignant de la seance, l'administration et le controle gardent l acces :
  -- c'est le sens meme du dispositif de l'ADR-002.
  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  perform public.autoriser_ecoute_archive(v_archive);

  perform set_config('test.uid', 'c4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  perform public.autoriser_ecoute_archive(v_archive);
end $$;

-- ============================================================
-- R13 : aucune valeur de secret R2 n'entre dans le schema
-- ============================================================
--
-- Les NOMS des secrets ont le droit d'apparaitre dans le code ; leurs VALEURS
-- nulle part, et surtout pas dans une table de configuration que
-- l'administration peut lire.

do $$
declare
  v_fuite int;
begin
  set local role service_role;
  select count(*) into v_fuite from public.app_config
  where key ilike 'r2%' or key ilike '%access_key%' or key ilike '%secret%'
     or value::text ilike '%r2.cloudflarestorage.com%';
  if v_fuite > 0 then
    raise exception 'R13 : % cles de configuration ressemblent a un secret R2', v_fuite;
  end if;
end $$;

\ir _acl_retablir.sql
