-- Scenarios d'acceptation du hook de jeton d'acces (migration 0038).
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les migrations.
-- Un fichier de scenarios ne se rejoue jamais deux fois sur la meme base : il
-- insere ses fixtures, prefixees `da` pour ne croiser aucun autre fichier.
--
-- CE QUE CE FICHIER MESURE, ET POURQUOI IL EXISTE.
--
-- Le 21 septembre 2026, quatre enseignants etaient bloques en `pending_kyc` en
-- production. Ils avaient depose seize fichiers dans le seau `kyc` sans qu'une
-- seule ligne `kyc_documents` existe. Rien n'etait casse du cote visible : le
-- seau etait la, la policy `kyc_staff_self_insert` etait juste, le declencheur
-- ne refusait rien. Le hook de jeton rendait NULL pour tout profil sans foyer,
-- Auth emettait alors un jeton sans revendication, et `app_role()` fermait
-- toutes les policies en silence.
--
-- Ce fichier mesure donc la chaine ENTIERE, du hook jusqu'a l'insertion reelle
-- (H8) : c'est le seul niveau ou ce defaut etait visible. Chacun de ses maillons
-- pris separement etait correct, et c'est precisement pour cela qu'il a survecu
-- neuf jours a la CI, a deux revues et a une livraison de role complet.
--
-- Placement dans `ci.yml` : apres `scenarios_etape3.sql`, dont le controle
-- ADM-02 compte les dossiers en attente de toute la base -- H8 en cree un.
-- Aucune de ses etapes n'ecrit dans `audit_logs` (le seul declencheur de
-- `kyc_documents` est `completer_kyc_document`, qui ne journalise pas), donc sa
-- position vis-a-vis de `scenarios_adm04.sql` est libre.

-- ============================================================
-- Fixtures : les quatre roles que `profiles_household_required` autorise a
-- n'avoir aucun foyer, plus un tuteur qui en a un.
-- ============================================================
--
-- `profiles_household_required` (0004) : `role in ('admin', 'accountant',
-- 'controller', 'teacher') or household_id is not null`. Ces quatre roles sont
-- exactement la population que le defaut fermait. Un tuteur et un eleve ont
-- toujours un foyer : le chemin par lequel l'application avait ete essayee ne
-- rencontrait jamais le defaut.

insert into auth.users (id, email) values
  ('da000000-0000-0000-0000-000000000001', 'hook.enseignant@example.test'),
  ('da000000-0000-0000-0000-000000000002', 'hook.controleur@example.test'),
  ('da000000-0000-0000-0000-000000000003', 'hook.admin@example.test'),
  ('da000000-0000-0000-0000-000000000004', 'hook.tuteur@example.test'),
  ('da000000-0000-0000-0000-000000000005', 'hook.efface@example.test');

insert into public.households (id, timezone) values
  ('daffffff-0000-0000-0000-00000000000a', 'Europe/Paris');

-- L'enseignant est volontairement laisse `pending_kyc` : c'est l'etat exact des
-- quatre comptes bloques en production. Son genre est renseigne parce que
-- `completer_kyc_document()` (0004) refuse un dossier dont le titulaire n'a pas
-- de genre connu -- ce refus-la n'est pas le defaut mesure ici, et le laisser
-- interferer masquerait H8.
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('da000000-0000-0000-0000-000000000001', 'TEACH-HK-00001', 'teacher',
   null, 'Idriss', 'Ndiaye', 'pending_kyc', 'male'),
  ('da000000-0000-0000-0000-000000000002', 'CTRL-HK-000001', 'controller',
   null, 'Amina', 'Fall', 'active', 'female'),
  ('da000000-0000-0000-0000-000000000003', 'ADMN-HK-000001', 'admin',
   null, 'Bilal', 'Cisse', 'active', 'male'),
  ('da000000-0000-0000-0000-000000000004', 'GUAR-HK-000001', 'guardian',
   'daffffff-0000-0000-0000-00000000000a', 'Fatou', 'Sarr', 'active', 'female'),
  ('da000000-0000-0000-0000-000000000005', 'TEACH-HK-00002', 'teacher',
   null, 'Ancien', 'Parti', 'disabled', 'male');

update public.profiles set deleted_at = now()
where id = 'da000000-0000-0000-0000-000000000005';

-- ============================================================
-- H1 -- CONTROLE DU LOT : un enseignant sans foyer obtient son role
-- ============================================================
--
-- C'est le defaut lui-meme. Avant 0038, le hook rendait NULL sur cette entree.

do $$
declare
  v_retour jsonb;
  v_claims jsonb;
begin
  v_retour := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'da000000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'da000000-0000-0000-0000-000000000001')
  ));

  if v_retour is null then
    raise exception 'H1 ECHEC : le hook rend NULL pour un enseignant sans foyer -- c''est le defaut de 0038, non corrige';
  end if;

  v_claims := v_retour -> 'claims';

  if v_claims -> 'app_metadata' ->> 'role' is distinct from 'teacher' then
    raise exception 'H1 ECHEC : role attendu << teacher >>, obtenu << % >>',
      coalesce(v_claims -> 'app_metadata' ->> 'role', '<absent>');
  end if;

  -- La cle doit EXISTER et valoir le jsonb `null` : sa forme ne doit pas
  -- dependre de qui se connecte.
  if not (v_claims -> 'app_metadata') ? 'household_id' then
    raise exception 'H1 ECHEC : la cle household_id a disparu du jeton';
  end if;

  if jsonb_typeof(v_claims -> 'app_metadata' -> 'household_id') <> 'null' then
    raise exception 'H1 ECHEC : household_id devait etre le jsonb null, obtenu << % >>',
      jsonb_typeof(v_claims -> 'app_metadata' -> 'household_id');
  end if;

  -- Le `sub` d'origine ne doit pas avoir ete perdu en chemin.
  if v_claims ->> 'sub' is distinct from 'da000000-0000-0000-0000-000000000001' then
    raise exception 'H1 ECHEC : le hook a perdu le sub du jeton';
  end if;
end $$;

-- ============================================================
-- H2 -- Le controleur et l'administrateur sans foyer, meme exigence
-- ============================================================
--
-- Les quatre roles autorises a n'avoir aucun foyer passaient tous par le meme
-- NULL. Mesurer le seul enseignant laisserait croire a un cas particulier.

do $$
declare
  v_cas record;
  v_retour jsonb;
  v_role text;
begin
  for v_cas in
    select * from (values
      ('da000000-0000-0000-0000-000000000002'::uuid, 'controller'),
      ('da000000-0000-0000-0000-000000000003'::uuid, 'admin')
    ) as t(id, role_attendu)
  loop
    v_retour := public.custom_access_token_hook(jsonb_build_object(
      'user_id', v_cas.id,
      'claims', jsonb_build_object('sub', v_cas.id)
    ));

    if v_retour is null then
      raise exception 'H2 ECHEC : le hook rend NULL pour le role %', v_cas.role_attendu;
    end if;

    v_role := v_retour -> 'claims' -> 'app_metadata' ->> 'role';
    if v_role is distinct from v_cas.role_attendu then
      raise exception 'H2 ECHEC : role attendu << % >>, obtenu << % >>',
        v_cas.role_attendu, coalesce(v_role, '<absent>');
    end if;
  end loop;
end $$;

-- ============================================================
-- H3 -- Un foyer present reste un texte, et non le jsonb null
-- ============================================================
--
-- Le correctif ne doit pas avoir aplati le cas qui fonctionnait : c'est le seul
-- chemin que la production avait reellement eprouve.

do $$
declare
  v_claims jsonb;
begin
  v_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'da000000-0000-0000-0000-000000000004',
    'claims', jsonb_build_object('sub', 'da000000-0000-0000-0000-000000000004')
  )) -> 'claims';

  if v_claims -> 'app_metadata' ->> 'role' is distinct from 'guardian' then
    raise exception 'H3 ECHEC : le tuteur a perdu son role';
  end if;

  if v_claims -> 'app_metadata' ->> 'household_id'
     is distinct from 'daffffff-0000-0000-0000-00000000000a' then
    raise exception 'H3 ECHEC : foyer attendu, obtenu << % >>',
      coalesce(v_claims -> 'app_metadata' ->> 'household_id', '<absent>');
  end if;

  if jsonb_typeof(v_claims -> 'app_metadata' -> 'household_id') <> 'string' then
    raise exception 'H3 ECHEC : un foyer present doit rester une chaine';
  end if;
end $$;

-- ============================================================
-- H4 -- Compte inconnu et profil efface : degrade, mais jamais NULL
-- ============================================================
--
-- Aucun role n'est pose, ce qui est correct -- ces deux comptes ne doivent rien
-- obtenir. Mais le hook doit rendre l'evenement : c'est Auth qui decide de la
-- suite, et un NULL le priverait meme des revendications qu'il avait deja.

do $$
declare
  v_cas record;
  v_retour jsonb;
begin
  for v_cas in
    select * from (values
      ('00000000-0000-0000-0000-0000000000ff'::uuid, 'compte inconnu'),
      ('da000000-0000-0000-0000-000000000005'::uuid, 'profil efface')
    ) as t(id, quoi)
  loop
    v_retour := public.custom_access_token_hook(jsonb_build_object(
      'user_id', v_cas.id,
      'claims', jsonb_build_object('sub', v_cas.id)
    ));

    if v_retour is null then
      raise exception 'H4 ECHEC : le hook rend NULL pour un %', v_cas.quoi;
    end if;

    if v_retour -> 'claims' -> 'app_metadata' ? 'role' then
      raise exception 'H4 ECHEC : un % obtient un role', v_cas.quoi;
    end if;

    if v_retour -> 'claims' ->> 'sub' is distinct from v_cas.id::text then
      raise exception 'H4 ECHEC : le sub d''origine est perdu pour un %', v_cas.quoi;
    end if;
  end loop;
end $$;

-- ============================================================
-- H5 -- `app_metadata` deja present mais inutilisable
-- ============================================================
--
-- La garde d'origine testait `jsonb_typeof(...) is null`, ce qui ne voyait que
-- la cle ABSENTE. Une cle presente valant `null`, une chaine ou un nombre la
-- passait, et les `jsonb_set` suivants restaient alors sans effet : le jeton
-- partait sans role, du meme silence que le defaut principal.

do $$
declare
  v_cas jsonb;
  v_retour jsonb;
begin
  foreach v_cas in array array[
    '{"sub":"da000000-0000-0000-0000-000000000001","app_metadata":null}'::jsonb,
    '{"sub":"da000000-0000-0000-0000-000000000001","app_metadata":"vide"}'::jsonb,
    '{"sub":"da000000-0000-0000-0000-000000000001","app_metadata":7}'::jsonb,
    '{"sub":"da000000-0000-0000-0000-000000000001","app_metadata":{"autre":"garde"}}'::jsonb
  ]
  loop
    v_retour := public.custom_access_token_hook(jsonb_build_object(
      'user_id', 'da000000-0000-0000-0000-000000000001',
      'claims', v_cas
    ));

    if v_retour is null then
      raise exception 'H5 ECHEC : le hook rend NULL sur app_metadata = %', v_cas -> 'app_metadata';
    end if;

    if v_retour -> 'claims' -> 'app_metadata' ->> 'role' is distinct from 'teacher' then
      raise exception 'H5 ECHEC : role absent alors que app_metadata valait % ; obtenu %',
        v_cas -> 'app_metadata',
        coalesce(v_retour -> 'claims' -> 'app_metadata' ->> 'role', '<absent>');
    end if;
  end loop;
end $$;

-- ============================================================
-- H6 -- Ce que la base lit reellement de ce jeton
-- ============================================================
--
-- `app_role()` et `app_household_id()` sont les deux seules lectrices de ces
-- claims, et ce sont elles que toutes les policies interrogent. Un jsonb `null`
-- doit se lire comme une absence de foyer, pas comme la chaine << null >>.

do $$
declare
  v_claims jsonb;
begin
  v_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'da000000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'da000000-0000-0000-0000-000000000001')
  )) -> 'claims';

  perform set_config('test.jwt', v_claims::text, true);
  perform set_config('test.uid', 'da000000-0000-0000-0000-000000000001', true);

  if public.app_role() is distinct from 'teacher'::public.app_role then
    raise exception 'H6 ECHEC : app_role() ne lit pas << teacher >> dans ce jeton, obtenu << % >>',
      coalesce(public.app_role()::text, '<null>');
  end if;

  if public.app_household_id() is not null then
    raise exception 'H6 ECHEC : app_household_id() rend << % >> au lieu de NULL',
      public.app_household_id()::text;
  end if;
end $$;

-- ============================================================
-- H7 -- Un jeton muet ferme bien la porte (le symptome, isole)
-- ============================================================
--
-- Sans le claim, l'insertion doit etre refusee. Ce controle fixe le symptome
-- exact observe en production, pour qu'un futur relachement de
-- `kyc_staff_self_insert` ne passe pas inapercu.

do $$
declare
  v_etat text;
begin
  perform set_config('test.jwt', '{"sub":"da000000-0000-0000-0000-000000000001"}', true);
  perform set_config('test.uid', 'da000000-0000-0000-0000-000000000001', true);
  set local role authenticated;

  begin
    insert into public.kyc_documents (profile_id, doc_type, object_key)
    values ('da000000-0000-0000-0000-000000000001', 'id_card', 'da-sans-claim.jpg');
    v_etat := 'ACCEPTE';
  exception when insufficient_privilege then
    v_etat := 'REFUSE';
  end;

  reset role;

  if v_etat <> 'REFUSE' then
    raise exception 'H7 ECHEC : un jeton sans role a pu creer un dossier KYC';
  end if;
end $$;

-- ============================================================
-- H8 -- CONTROLE DE BOUT EN BOUT : l'enseignant depose enfin
-- ============================================================
--
-- Le hook produit les claims, la base les lit, la policy ouvre, la ligne
-- existe. C'est le seul niveau auquel le defaut etait visible : chacun de ses
-- maillons, pris seul, etait correct.

do $$
declare
  v_claims jsonb;
  v_lignes int;
begin
  v_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'da000000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'da000000-0000-0000-0000-000000000001')
  )) -> 'claims';

  perform set_config('test.jwt', v_claims::text, true);
  perform set_config('test.uid', 'da000000-0000-0000-0000-000000000001', true);
  set local role authenticated;

  insert into public.kyc_documents (profile_id, doc_type, object_key)
  values ('da000000-0000-0000-0000-000000000001', 'id_card',
          'da000000-0000-0000-0000-000000000001/1700000000.jpg');

  reset role;

  select count(*) into v_lignes
  from public.kyc_documents
  where profile_id = 'da000000-0000-0000-0000-000000000001'
    and object_key = 'da000000-0000-0000-0000-000000000001/1700000000.jpg';

  if v_lignes <> 1 then
    raise exception 'H8 ECHEC : % ligne(s) creee(s) au lieu d''une seule', v_lignes;
  end if;

  -- Le declencheur de `0004` doit avoir fait son travail : le genre vient du
  -- profil, jamais du deposant, et la duree de conservation est posee.
  if not exists (
    select 1 from public.kyc_documents
    where profile_id = 'da000000-0000-0000-0000-000000000001'
      and gender = 'male' and purge_at is not null and status = 'pending'
  ) then
    raise exception 'H8 ECHEC : la ligne creee n''est pas correctement classee';
  end if;
end $$;

-- ============================================================
-- H9 -- Le hook reste ferme a tout le monde sauf Auth
-- ============================================================

do $$
begin
  if not has_function_privilege('supabase_auth_admin',
       'public.custom_access_token_hook(jsonb)', 'execute') then
    raise exception 'H9 ECHEC : supabase_auth_admin ne peut plus appeler le hook -- Auth emettrait des jetons muets';
  end if;

  if has_function_privilege('authenticated',
       'public.custom_access_token_hook(jsonb)', 'execute')
     or has_function_privilege('anon',
       'public.custom_access_token_hook(jsonb)', 'execute') then
    raise exception 'H9 ECHEC : le hook est appelable par un client';
  end if;
end $$;

do $$
begin
  raise notice 'scenarios_hook_jeton : H1 a H9 au vert.';
end $$;


-- B-17 : claim de tranche d'âge et demandes MA-9, sans date de naissance.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('db000000-0000-0000-0000-000000000001', 'b17.guardian@example.test'),
  ('db000000-0000-0000-0000-000000000002', 'b17.minor@example.test'),
  ('db000000-0000-0000-0000-000000000003', 'b17.adult@example.test'),
  ('db000000-0000-0000-0000-000000000004', 'b17.other@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('dbffffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('db000000-0000-0000-0000-000000000001', 'B17-GUARD-001', 'guardian',
   'dbffffff-0000-0000-0000-000000000001', 'Tuteur', 'Test', 'active', 'female'),
  ('db000000-0000-0000-0000-000000000002', 'B17-MINOR-001', 'student',
   'dbffffff-0000-0000-0000-000000000001', 'Enfant', 'Test', 'active', 'male'),
  ('db000000-0000-0000-0000-000000000003', 'B17-ADULT-001', 'student',
   'dbffffff-0000-0000-0000-000000000001', 'Adulte', 'Test', 'active', 'male'),
  ('db000000-0000-0000-0000-000000000004', 'B17-OTHER-001', 'guardian',
   'dbffffff-0000-0000-0000-000000000001', 'Autre', 'Test', 'active', 'female');

UPDATE public.households
SET primary_guardian_id = 'db000000-0000-0000-0000-000000000001'
WHERE id = 'dbffffff-0000-0000-0000-000000000001';

INSERT INTO public.student_profiles (profile_id, student_type)
VALUES
  ('db000000-0000-0000-0000-000000000002', 'minor'),
  ('db000000-0000-0000-0000-000000000003', 'autonomous');

DO $b17_hook$
DECLARE
  v_child jsonb;
  v_adult jsonb;
  v_teacher jsonb;
BEGIN
  v_child := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'db000000-0000-0000-0000-000000000002',
    'claims', jsonb_build_object('sub', 'db000000-0000-0000-0000-000000000002')
  )) -> 'claims';
  v_adult := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'db000000-0000-0000-0000-000000000003',
    'claims', jsonb_build_object('sub', 'db000000-0000-0000-0000-000000000003')
  )) -> 'claims';
  v_teacher := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'da000000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'da000000-0000-0000-0000-000000000001')
  )) -> 'claims';

  IF v_child ->> 'tranche_age' IS DISTINCT FROM 'enfant'
     OR v_adult ->> 'tranche_age' IS DISTINCT FROM 'adulte'
     OR v_teacher ->> 'tranche_age' IS DISTINCT FROM 'inconnu'
     OR v_child::text LIKE '%date_naissance%' THEN
    RAISE EXCEPTION 'B-17 claim âge invalide: enfant %, adulte %, non-élève %',
      v_child ->> 'tranche_age', v_adult ->> 'tranche_age', v_teacher ->> 'tranche_age';
  END IF;
END
$b17_hook$;

DO $b17_requests$
DECLARE
  v_request uuid;
  v_retry uuid;
  v_count integer;
  v_denied boolean := false;
BEGIN
  PERFORM set_config('request.jwt.claim.sub',
    'db000000-0000-0000-0000-000000000002', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'student', 'household_id', 'dbffffff-0000-0000-0000-000000000001'
    ))::text, true);

  PERFORM public.demander_presentation_standard();
  SELECT id INTO v_request FROM public.demandes_presentation
  WHERE eleve_id = 'db000000-0000-0000-0000-000000000002'
    AND statut = 'en_attente';
  PERFORM public.demander_presentation_standard();
  SELECT id INTO v_retry FROM public.demandes_presentation
  WHERE eleve_id = 'db000000-0000-0000-0000-000000000002'
    AND statut = 'en_attente';
  IF v_request IS NULL OR v_request IS DISTINCT FROM v_retry THEN
    RAISE EXCEPTION 'B-17 création non idempotente';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.notifications
  WHERE destinataire = 'db000000-0000-0000-0000-000000000001'
    AND evenement = 'demande_presentation'
    AND params ->> 'demande_id' = v_request::text;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-17 notification attendue une fois, obtenue %', v_count;
  END IF;

  -- Un adulte autonome ne peut pas envoyer la demande standard MA-8.
  PERFORM set_config('request.jwt.claim.sub',
    'db000000-0000-0000-0000-000000000003', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'student', 'household_id', 'dbffffff-0000-0000-0000-000000000001'
    ))::text, true);
  BEGIN
    PERFORM public.demander_presentation_standard();
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-17 un élève adulte a envoyé une demande standard';
  END IF;

  -- Un tuteur du foyer lit et tranche, sans accès à un autre foyer.
  PERFORM set_config('request.jwt.claim.sub',
    'db000000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'dbffffff-0000-0000-0000-000000000001'
    ))::text, true);
  SELECT count(*) INTO v_count
  FROM public.lire_demandes_presentation_en_attente();
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-17 le tuteur autorisé ne voit pas la demande';
  END IF;

  IF public.accepter_demande_presentation(v_request) <> 'acceptee'
     OR public.accepter_demande_presentation(v_request) <> 'acceptee' THEN
    RAISE EXCEPTION 'B-17 acceptation ou répétition idempotente invalide';
  END IF;

  v_denied := false;
  BEGIN
    PERFORM public.refuser_demande_presentation(v_request);
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'demande déjà tranchée' THEN v_denied := true; ELSE RAISE; END IF;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-17 une décision opposée a été acceptée';
  END IF;

  IF pg_catalog.has_function_privilege(
       'anon', 'public.demander_presentation_standard()', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
       'anon', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
       'anon', 'public.accepter_demande_presentation(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.repondre_demande_presentation(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_table_privilege(
       'authenticated', 'public.demandes_presentation', 'SELECT') THEN
    RAISE EXCEPTION 'B-17 ACL trop large';
  END IF;
END
$b17_requests$;

ROLLBACK;
