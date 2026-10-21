-- Scenarios d'acceptation SQL de `ADM-05`, l'attribution manuelle.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0008. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.

-- Droits facon Supabase (alter default privileges du projet).
\ir _acl_photo.sql
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler la restriction posee par 0005 sur les
-- tables que seules les fonctions ecrivent. En production l'ordre est inverse :
-- les droits par defaut sont accordes a la creation de la table, la migration
-- les restreint ensuite. On rejoue donc la restriction, sans quoi le scenario 9
-- mesurerait le harnais et non la migration.
revoke insert, update, delete on public.teacher_student_assignments,
  public.matching_requests, public.rule_overrides from authenticated;

-- ============================================================
-- Fixtures : trois eleves sans enseignant, trois enseignants, une admin
-- ============================================================
--
--   * Yacine attend depuis le plus longtemps, et propose mardi 17 h Paris ;
--   * Sokhna attend depuis moins longtemps, meme creneau ;
--   * Awa attend depuis un jour, meme creneau : c'est elle qui mesure le plafond ;
--   * Moussa n'a pose aucun creneau : il attend, et n'est pas attribuable.
--
--   * Omar est a Paris et pose mardi 17 h : il croise.
--   * Fatima est a Conakry et pose mardi 16 h locale, soit le meme INSTANT que
--     17 h Paris : elle croise aussi, et c'est ce que le calcul par heure locale
--     aurait manque.
--   * Ibrahim ne pose rien : il ne croise pas, et c'est lui qui mesure l'ADR-021.

insert into auth.users (id, email) values
  ('a5000000-0000-0000-0000-000000000001', 'tuteurA5@example.test'),
  ('a5000000-0000-0000-0000-000000000002', 'yacine@example.test'),
  ('a5000000-0000-0000-0000-000000000003', 'sokhna@example.test'),
  ('a5000000-0000-0000-0000-000000000004', 'moussa@example.test'),
  ('a5000000-0000-0000-0000-000000000005', 'awa@example.test'),
  ('a5000000-0000-0000-0000-000000000011', 'omar@example.test'),
  ('a5000000-0000-0000-0000-000000000012', 'fatima@example.test'),
  ('a5000000-0000-0000-0000-000000000013', 'ibrahim@example.test'),
  ('a5000000-0000-0000-0000-000000000021', 'adminA5@example.test');

insert into public.households (id, timezone) values
  ('a5ffffff-0000-0000-0000-00000000000a', 'Europe/Paris'),
  ('a5ffffff-0000-0000-0000-00000000000b', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('a5000000-0000-0000-0000-000000000001', 'GUARD-A5-000001', 'guardian',
   'a5ffffff-0000-0000-0000-00000000000a', 'Aminata', 'Sarr', 'active', 'female'),
  ('a5000000-0000-0000-0000-000000000002', 'STUD-A5-000001', 'student',
   'a5ffffff-0000-0000-0000-00000000000a', 'Yacine', 'Sarr', 'active', null),
  ('a5000000-0000-0000-0000-000000000003', 'STUD-A5-000002', 'student',
   'a5ffffff-0000-0000-0000-00000000000a', 'Sokhna', 'Sarr', 'active', null),
  ('a5000000-0000-0000-0000-000000000004', 'STUD-A5-000003', 'student',
   'a5ffffff-0000-0000-0000-00000000000a', 'Moussa', 'Sarr', 'active', null),
  ('a5000000-0000-0000-0000-000000000005', 'STUD-A5-000004', 'student',
   'a5ffffff-0000-0000-0000-00000000000a', 'Awa', 'Sarr', 'active', null),
  ('a5000000-0000-0000-0000-000000000011', 'TEACH-A5-000001', 'teacher',
   'a5ffffff-0000-0000-0000-00000000000b', 'Omar', 'Sow', 'provisional_active', 'male'),
  ('a5000000-0000-0000-0000-000000000012', 'TEACH-A5-000002', 'teacher',
   'a5ffffff-0000-0000-0000-00000000000b', 'Fatima', 'Balde', 'provisional_active', 'female'),
  ('a5000000-0000-0000-0000-000000000013', 'TEACH-A5-000003', 'teacher',
   'a5ffffff-0000-0000-0000-00000000000b', 'Ibrahim', 'Diop', 'provisional_active', 'male'),
  ('a5000000-0000-0000-0000-000000000021', 'ADMIN-A5-000001', 'admin',
   'a5ffffff-0000-0000-0000-00000000000b', 'Nadia', 'Cherif', 'active', 'female');
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

update public.households set primary_guardian_id = 'a5000000-0000-0000-0000-000000000001'
 where id = 'a5ffffff-0000-0000-0000-00000000000a';

insert into public.student_profiles (profile_id, interface_mode, level) values
  ('a5000000-0000-0000-0000-000000000002', 'child', 'debutant'),
  ('a5000000-0000-0000-0000-000000000003', 'standard', 'intermediaire'),
  ('a5000000-0000-0000-0000-000000000004', 'child', null),
  ('a5000000-0000-0000-0000-000000000005', 'standard', 'debutant');

insert into public.teacher_profiles (profile_id, country) values
  ('a5000000-0000-0000-0000-000000000011', 'FR'),
  ('a5000000-0000-0000-0000-000000000012', 'GN'),
  ('a5000000-0000-0000-0000-000000000013', 'FR');

-- Les creneaux. `created_at` est force : c'est l'anciennete d'attente, et c'est
-- elle qui ordonne la colonne de gauche.
insert into public.weekly_availability
  (profile_id, weekday, hour_local, timezone_iana, created_at)
values
  -- Yacine : mardi 17 h Paris, pose il y a trente jours.
  ('a5000000-0000-0000-0000-000000000002', 2, 17, 'Europe/Paris', now() - interval '30 days'),
  ('a5000000-0000-0000-0000-000000000002', 4, 18, 'Europe/Paris', now() - interval '30 days'),
  -- Sokhna : meme creneau, pose il y a trois jours.
  ('a5000000-0000-0000-0000-000000000003', 2, 17, 'Europe/Paris', now() - interval '3 days'),
  -- Awa : meme creneau, pose hier.
  ('a5000000-0000-0000-0000-000000000005', 2, 17, 'Europe/Paris', now() - interval '1 day'),
  -- Omar : mardi 17 h Paris. Il croise Yacine et Sokhna.
  ('a5000000-0000-0000-0000-000000000011', 2, 17, 'Europe/Paris', now() - interval '60 days');
  -- Ibrahim ne pose rien.

-- Fatima pose le MEME INSTANT que Yacine, dans son fuseau a elle.
--
-- **L'heure est calculee, jamais ecrite en dur** : Conakry ne change pas
-- d'heure, Paris si. Ecrire « 16 h » ici rendrait ce scenario vert d'octobre a
-- mars et rouge le reste de l'annee, ce qui est exactement le piege que
-- `journee_test.dart` a deja tendu une fois au depot.
insert into public.weekly_availability
  (profile_id, weekday, hour_local, timezone_iana, created_at)
select
  'a5000000-0000-0000-0000-000000000012', 2,
  extract(hour from (public.instant_creneau(2, 17, 'Europe/Paris')
                     at time zone 'Africa/Conakry'))::int,
  'Africa/Conakry', now() - interval '60 days';

-- ============================================================
-- A1 : l'attribution manuelle est fermee a tout role autre qu'admin
-- ============================================================

do $$
declare
  v_ok boolean := false;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000011', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  begin
    perform * from public.eleves_sans_enseignant();
  exception when others then
    v_ok := true;
  end;
  if not v_ok then
    raise exception 'A1 ECHEC : un enseignant a pu lire la file d''attribution';
  end if;

  v_ok := false;
  begin
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000002',
      'a5000000-0000-0000-0000-000000000011', 2, 17, null);
  exception when others then
    -- L3-02 : fermee par revoke, refus 42501 exact (et non plus la garde de role).
    if sqlstate <> '42501' then
      raise exception 'A1 ECHEC : SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
    v_ok := true;
  end;
  if not v_ok then
    raise exception 'A1 ECHEC : un enseignant a pu attribuer un eleve';
  end if;

  raise notice 'A1 ok : l''attribution manuelle est reservee a l''administration, lecture comprise';
end $$;

-- ============================================================
-- A2 : la colonne de gauche liste les trois eleves, anciennete d'abord
-- ============================================================

do $$
declare
  v_ordre text[];
  v_cases int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- **Les assertions se bornent au foyer de ce fichier**, jamais au total : les
  -- scenarios des etapes 3, 4 et 5 tournent sur la meme base avant celui-ci et
  -- y laissent leurs propres eleves. Un compte global mesurerait la suite, pas
  -- la fonction. C'est l'ordre RELATIF des quatre qui se verifie, et il suffit :
  -- il porte exactement la regle, l'anciennete d'abord.
  select array_agg(t.first_name order by t.rn) into v_ordre
    from (
      select first_name, household_id, row_number() over () as rn
        from public.eleves_sans_enseignant()
    ) t
   where t.household_id = 'a5ffffff-0000-0000-0000-00000000000a';

  if v_ordre is distinct from array['Yacine', 'Sokhna', 'Awa', 'Moussa'] then
    raise exception 'A2 ECHEC : file attendue Yacine, Sokhna, Awa, Moussa ; lue %', v_ordre;
  end if;

  -- Celui qui n'a rien pose ferme la file, et il y figure : le masquer donnerait
  -- un compteur ADM-01 sans ligne en face.
  select jsonb_array_length(creneaux) into v_cases
    from public.eleves_sans_enseignant()
   where student_id = 'a5000000-0000-0000-0000-000000000004';
  if v_cases <> 0 then
    raise exception 'A2 ECHEC : l''eleve sans creneau devait porter un tableau vide, lu %', v_cases;
  end if;

  select jsonb_array_length(creneaux) into v_cases
    from public.eleves_sans_enseignant()
   where student_id = 'a5000000-0000-0000-0000-000000000002';
  if v_cases <> 2 then
    raise exception 'A2 ECHEC : Yacine propose deux creneaux, lu %', v_cases;
  end if;

  raise notice 'A2 ok : quatre eleves, le plus ancien en tete, et celui qui n''a rien pose reste visible';
end $$;

-- ============================================================
-- A3 : les creneaux communs se croisent par INSTANT, pas par heure locale
-- ============================================================

do $$
declare
  v_omar int;
  v_fatima int;
  v_ibrahim int;
  v_rang_ibrahim int;
  v_rang_omar int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select jsonb_array_length(creneaux_communs) into v_omar
    from public.enseignants_pour('a5000000-0000-0000-0000-000000000002')
   where teacher_id = 'a5000000-0000-0000-0000-000000000011';
  select jsonb_array_length(creneaux_communs) into v_fatima
    from public.enseignants_pour('a5000000-0000-0000-0000-000000000002')
   where teacher_id = 'a5000000-0000-0000-0000-000000000012';
  select jsonb_array_length(creneaux_communs) into v_ibrahim
    from public.enseignants_pour('a5000000-0000-0000-0000-000000000002')
   where teacher_id = 'a5000000-0000-0000-0000-000000000013';

  if v_omar <> 1 then
    raise exception 'A3 ECHEC : Omar partage mardi 17 h avec Yacine, lu % creneaux', v_omar;
  end if;
  -- Le coeur du scenario : l'heure de Fatima et 17 h Paris sont le meme instant,
  -- jamais la meme heure locale. Un croisement par heure locale rendrait zero.
  if v_fatima <> 1 then
    raise exception 'A3 ECHEC : Fatima (Conakry) devait croiser 17 h Paris, lu % creneaux', v_fatima;
  end if;
  if v_ibrahim is distinct from 0 then
    raise exception 'A3 ECHEC : Ibrahim ne pose rien, attendu zero creneau, lu %', v_ibrahim;
  end if;

  -- Celui qui ne croise pas est rendu quand meme, mais apres : c'est ce qui fait
  -- de ADM-05 un ecran de secours et non un doublon de ENS-06. S'il manquait de
  -- la liste, l'ecran serait vide le jour ou l'on en a besoin.
  select rn into v_rang_ibrahim from (
    select teacher_id, row_number() over () as rn
      from public.enseignants_pour('a5000000-0000-0000-0000-000000000002')
  ) t where t.teacher_id = 'a5000000-0000-0000-0000-000000000013';
  select rn into v_rang_omar from (
    select teacher_id, row_number() over () as rn
      from public.enseignants_pour('a5000000-0000-0000-0000-000000000002')
  ) t where t.teacher_id = 'a5000000-0000-0000-0000-000000000011';

  if v_rang_ibrahim is null then
    raise exception 'A3 ECHEC : l''enseignant sans creneau commun a disparu de la liste';
  end if;
  if v_rang_ibrahim < v_rang_omar then
    raise exception 'A3 ECHEC : celui qui ne croise pas passe devant celui qui croise';
  end if;

  raise notice 'A3 ok : croisement par instant (Conakry = 17 h Paris, quelle que soit la saison), et toute la liste est rendue';
end $$;

-- ============================================================
-- A4 : l'attribution nominale cree l'affectation, les seances et la trace
-- ============================================================

do $$
declare
  v_assignment uuid;
  v_seances int;
  v_trace jsonb;
begin
  reset role; -- L3-02 : attribuer_eleve est fermee aux comptes connectes, la garde interne se rejoue sous postgres
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  v_assignment := public.attribuer_eleve(
    'a5000000-0000-0000-0000-000000000002',
    'a5000000-0000-0000-0000-000000000011', 2, 17, null);

  if v_assignment is null then
    raise exception 'A4 ECHEC : aucune affectation rendue';
  end if;

  if not exists (
    select 1 from public.teacher_student_assignments a
    where a.id = v_assignment
      and a.teacher_id = 'a5000000-0000-0000-0000-000000000011'
      and a.student_id = 'a5000000-0000-0000-0000-000000000002'
      and a.timezone_iana = 'Europe/Paris'
      and a.ended_at is null
  ) then
    raise exception 'A4 ECHEC : l''affectation n''est pas celle demandee';
  end if;

  -- Une attribution qui ne materialise rien laisserait TUT-01 et ELV-02 vides
  -- apres le geste : c'est le defaut que ce controle empeche de revenir.
  select count(*) into v_seances
    from public.sessions s
   where s.teacher_id = 'a5000000-0000-0000-0000-000000000011'
     and s.deleted_at is null;
  if v_seances = 0 then
    raise exception 'A4 ECHEC : aucune seance materialisee apres l''attribution';
  end if;

  select payload into v_trace from public.audit_logs
   where action = 'affectation_attribuee' and row_id = v_assignment::text;
  if v_trace is null then
    raise exception 'A4 ECHEC : l''attribution n''a pas ete journalisee';
  end if;
  if (v_trace ->> 'hors_disponibilite')::boolean then
    raise exception 'A4 ECHEC : Omar posait ce creneau, la trace ne devait pas dire le contraire';
  end if;

  -- L'eleve attribue quitte la colonne de gauche.
  if exists (
    select 1 from public.eleves_sans_enseignant()
     where student_id = 'a5000000-0000-0000-0000-000000000002'
  ) then
    raise exception 'A4 ECHEC : un eleve attribue reste dans la file';
  end if;

  raise notice 'A4 ok : affectation creee, % seances materialisees, journal ecrit', v_seances;
end $$;

-- ============================================================
-- A5 : l'heure appartient au foyer
-- ============================================================

do $$
declare
  v_ok boolean := false;
begin
  reset role; -- L3-02 : attribuer_eleve est fermee aux comptes connectes, la garde interne se rejoue sous postgres
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  begin
    -- Sokhna ne propose que mardi 17 h. Le lundi 9 h n'est l'heure de personne.
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000003',
      'a5000000-0000-0000-0000-000000000011', 1, 9, 'Urgence.');
  exception when others then
    v_ok := true;
  end;

  if not v_ok then
    raise exception 'A5 ECHEC : l''administration a pose une heure que le foyer ne propose pas';
  end if;

  raise notice 'A5 ok : meme l''administration ne choisit pas l''heure du cours a la place de la famille';
end $$;

-- ============================================================
-- A6 : hors disponibilite de l'enseignant, le motif est exige en base (ADR-021)
-- ============================================================

do $$
declare
  v_ok boolean := false;
  v_assignment uuid;
  v_trace jsonb;
begin
  reset role; -- L3-02 : attribuer_eleve est fermee aux comptes connectes, la garde interne se rejoue sous postgres
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- Ibrahim ne pose aucun creneau. Sans motif, la base refuse.
  begin
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000003',
      'a5000000-0000-0000-0000-000000000013', 2, 17, null);
  exception when others then
    v_ok := true;
  end;
  if not v_ok then
    raise exception 'A6 ECHEC : attribution hors disponibilite acceptee sans motif';
  end if;

  -- Un motif fait d'espaces n'est pas un motif.
  v_ok := false;
  begin
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000003',
      'a5000000-0000-0000-0000-000000000013', 2, 17, '   ');
  exception when others then
    v_ok := true;
  end;
  if not v_ok then
    raise exception 'A6 ECHEC : un motif vide a ete accepte';
  end if;

  -- Avec motif, elle passe, et la trace porte les deux faits.
  v_assignment := public.attribuer_eleve(
    'a5000000-0000-0000-0000-000000000003',
    'a5000000-0000-0000-0000-000000000013', 2, 17,
    'Aucun enseignant disponible sur ce creneau, accord verbal d''Ibrahim.');

  select payload into v_trace from public.audit_logs
   where action = 'affectation_attribuee' and row_id = v_assignment::text;

  if not (v_trace ->> 'hors_disponibilite')::boolean then
    raise exception 'A6 ECHEC : la trace ne dit pas que l''on est passe outre';
  end if;
  if v_trace ->> 'motif' is null then
    raise exception 'A6 ECHEC : le motif n''est pas dans la trace';
  end if;

  raise notice 'A6 ok : passer outre est permis, le faire en silence ne l''est pas';
end $$;

-- ============================================================
-- A7 : un eleve n'a qu'un enseignant, quelle que soit la porte
-- ============================================================

do $$
declare
  v_ok boolean := false;
begin
  reset role; -- L3-02 : attribuer_eleve est fermee aux comptes connectes, la garde interne se rejoue sous postgres
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  begin
    -- Yacine a ete attribue a Omar en A4.
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000002',
      'a5000000-0000-0000-0000-000000000012', 2, 17, 'Changement.');
  exception when others then
    v_ok := true;
  end;

  if not v_ok then
    raise exception 'A7 ECHEC : un eleve deja suivi a ete reattribue sans passer par une demande';
  end if;

  raise notice 'A7 ok : la reaffectation passe par ADM-06, jamais par un deuxieme geste d''attribution';
end $$;

-- ============================================================
-- A8 : le plafond de l'enseignant s'applique aussi a l'administration
-- ============================================================

do $$
declare
  v_ok boolean := false;
begin
  -- Le plafond d'Omar tombe a un eleve. Il en a deja un depuis A4.
  insert into public.rule_overrides
    (profile_id, key, value, reason, set_by)
  values ('a5000000-0000-0000-0000-000000000011', 'max_students_per_teacher',
          '1'::jsonb, 'Periode d''essai.', 'a5000000-0000-0000-0000-000000000021');

  reset role; -- L3-02 : attribuer_eleve est fermee aux comptes connectes, la garde interne se rejoue sous postgres
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  begin
    -- Awa propose ce creneau et Omar aussi : rien d'autre que le plafond ne
    -- peut faire echouer cette attribution, sans quoi le controle passerait
    -- pour une mauvaise raison.
    perform public.attribuer_eleve(
      'a5000000-0000-0000-0000-000000000005',
      'a5000000-0000-0000-0000-000000000011', 2, 17, null);
  exception when others then
    v_ok := true;
  end;

  if not v_ok then
    raise exception 'A8 ECHEC : le plafond a ete contourne par l''attribution administrative';
  end if;

  raise notice 'A8 ok : depasser un plafond se fait en le changeant, pas en l''ignorant';
end $$;

-- ============================================================
-- A9 : l'invariant I3 de 0005 tient toujours apres cette migration
-- ============================================================

do $$
declare
  v_ok boolean := false;
  v_plafond int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a5000000-0000-0000-0000-000000000021', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- Aucune policy d'ecriture n'a ete ouverte : l'administration n'ecrit toujours
  -- pas a la main dans la table des affectations. 0008 ajoute une porte nommee,
  -- il n'abat pas le mur.
  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values ('a5000000-0000-0000-0000-000000000012',
            'a5000000-0000-0000-0000-000000000004', 2, 17, 'Europe/Paris');
  exception when others then
    v_ok := true;
  end;

  if not v_ok then
    raise exception 'A9 ECHEC : une ecriture directe dans les affectations a ete acceptee';
  end if;

  -- Et le plafond lu par la colonne de droite est bien le plafond surcharge
  -- d'Omar, pas celui de la plateforme : sans cela, l'ecran afficherait « 1 / 5 »
  -- pour un enseignant complet.
  select plafond into v_plafond
    from public.enseignants_pour('a5000000-0000-0000-0000-000000000004')
   where teacher_id = 'a5000000-0000-0000-0000-000000000011';
  if v_plafond <> 1 then
    raise exception 'A9 ECHEC : la colonne de droite lit le plafond de plateforme, attendu 1, lu %', v_plafond;
  end if;

  raise notice 'A9 ok : le mur de 0005 tient, et le plafond affiche est celui qui s''applique';
end $$;

do $$
begin
  raise notice 'ADM-05 : neuf controles verts.';
end $$;

\ir _acl_retablir.sql
