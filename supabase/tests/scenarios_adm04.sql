-- Scenarios d'acceptation SQL de `ADM-04`, le journal d'audit.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0009. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.
--
-- **Ce fichier tourne en DERNIER**, apres les quatre autres, et il est le seul
-- a mesurer une propriete GLOBALE : l'integrite de la chaine. C'est voulu. Les
-- quatre fichiers precedents ont rempli `audit_logs` en passant par les
-- fonctions du produit ; si l'un d'eux avait forge une ligne a la main, J4 le
-- dirait. Toutes les AUTRES assertions restent bornees aux fixtures de ce
-- fichier, par `table_name = 'adm04_fixture'`, parce qu'un compte global y
-- mesurerait la suite et non la migration.
--
-- Deux scenarios (J5, J6) falsifient deliberement le journal pour verifier que
-- la falsification se voit. Tous deux **reparent ce qu'ils ont casse** et le
-- reverifient : un test qui laisse la base rompue rendrait rouge tout ce qui
-- passe apres lui, y compris lui-meme au prochain tour.

-- Droits facon Supabase (alter default privileges du projet).
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient de rendre `audit_logs` ecrivable par
-- `authenticated`, ce que 0001 avait ferme. On rejoue la fermeture, sans quoi
-- J1 mesurerait le harnais et non la migration.
revoke insert, update, delete on public.audit_logs, public.audit_logs_default
  from authenticated;

-- ============================================================
-- Fixtures : une administratrice, un enseignant, un tuteur, un controleur,
-- et cinq entrees de journal qui leur appartiennent
-- ============================================================
--
-- Les entrees passent par `log_sensitive_access()`, jamais par un `insert`
-- direct : c'est la seule facon d'obtenir des lignes reellement chainees, donc
-- la seule qui rende J4, J5 et J6 significatifs.

insert into auth.users (id, email) values
  ('a4000000-0000-0000-0000-000000000001', 'adminA4@example.test'),
  ('a4000000-0000-0000-0000-000000000002', 'enseignantA4@example.test'),
  ('a4000000-0000-0000-0000-000000000003', 'tuteurA4@example.test'),
  ('a4000000-0000-0000-0000-000000000004', 'controleurA4@example.test');

insert into public.households (id, timezone) values
  ('a4ffffff-0000-0000-0000-00000000000a', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('a4000000-0000-0000-0000-000000000001', 'ADMIN-A4-000001', 'admin',
   'a4ffffff-0000-0000-0000-00000000000a', 'Khadija', 'Ndiaye', 'active', 'female'),
  ('a4000000-0000-0000-0000-000000000002', 'TEACH-A4-000001', 'teacher',
   'a4ffffff-0000-0000-0000-00000000000a', 'Moussa', 'Kane', 'provisional_active', 'male'),
  ('a4000000-0000-0000-0000-000000000003', 'GUARD-A4-000001', 'guardian',
   'a4ffffff-0000-0000-0000-00000000000a', 'Bintou', 'Kane', 'active', 'female'),
  ('a4000000-0000-0000-0000-000000000004', 'CTRL-A4-000001', 'controller',
   'a4ffffff-0000-0000-0000-00000000000a', 'Salif', 'Toure', 'active', 'male');
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

insert into public.teacher_profiles (profile_id, country) values
  ('a4000000-0000-0000-0000-000000000002', 'SN');

-- Cinq entrees `adm04_alpha` ecrites par l'administratrice, une entree
-- `adm04_beta` ecrite par l'enseignant. Six lignes, deux acteurs, deux types :
-- de quoi mesurer les trois filtres separement.
do $$
declare
  i int;
begin
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  for i in 1..5 loop
    perform public.log_sensitive_access(
      'adm04_alpha', 'adm04_fixture', 'ligne-' || i,
      jsonb_build_object('rang', i));
  end loop;

  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  perform public.log_sensitive_access(
    'adm04_beta', 'adm04_fixture', 'ligne-6', jsonb_build_object('rang', 6));
end $$;

-- ============================================================
-- J1 : les trois lectures sont fermees a tout role autre qu'admin
-- ============================================================
--
-- Le controleur merite son propre cas : la policy `audit_logs_read` de 0001
-- l'autorise a lire la TABLE, et il continue de le pouvoir. Ce sont les trois
-- FONCTIONS qui lui sont fermees, parce qu'elles sont `security definer` et
-- resolvent l'identite des acteurs par `profiles`, que `profiles_family_select`
-- ne lui ouvre que pour son propre foyer.

do $$
declare
  v_role text;
  v_uid text;
  v_ok boolean;
  v_lignes int;
begin
  foreach v_role in array array['teacher', 'guardian', 'controller'] loop
    v_uid := case v_role
      when 'teacher' then 'a4000000-0000-0000-0000-000000000002'
      when 'guardian' then 'a4000000-0000-0000-0000-000000000003'
      else 'a4000000-0000-0000-0000-000000000004'
    end;

    set local role authenticated;
    perform set_config('test.uid', v_uid, true);
    perform set_config('test.jwt', format('{"app_metadata":{"role":"%s"}}', v_role), true);

    v_ok := false;
    begin
      perform * from public.journal_audit();
    exception when others then
      v_ok := true;
    end;
    if not v_ok then
      raise exception 'J1 ECHEC : le role % a pu lire le journal', v_role;
    end if;

    v_ok := false;
    begin
      perform public.journal_audit_filtres();
    exception when others then
      v_ok := true;
    end;
    if not v_ok then
      raise exception 'J1 ECHEC : le role % a pu lire les filtres du journal', v_role;
    end if;

    v_ok := false;
    begin
      perform * from public.verifier_chaine_audit();
    exception when others then
      v_ok := true;
    end;
    if not v_ok then
      raise exception 'J1 ECHEC : le role % a pu verifier la chaine', v_role;
    end if;

    reset role;
  end loop;

  -- Et ce que le controleur garde : la lecture de la table elle-meme, telle
  -- que 0001 la lui a donnee. Si ce bloc echouait, la migration 0009 aurait
  -- retire un droit existant au lieu d'en ajouter un.
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);
  select count(*) into v_lignes from public.audit_logs
   where table_name = 'adm04_fixture';
  reset role;

  if v_lignes <> 6 then
    raise exception 'J1 ECHEC : le controleur devait garder sa lecture de table, lu % lignes', v_lignes;
  end if;

  raise notice 'J1 ok : les trois fonctions sont reservees a l''administration, et la policy du controleur est intacte';
end $$;

-- ============================================================
-- J2 : l'ordre est chronologique inverse, et la pagination ne saute ni ne
--      rejoue une entree
-- ============================================================
--
-- La pagination est mesuree SOUS FILTRE, sur les cinq `adm04_alpha` : le
-- curseur porte sur `(created_at, id)` de la table entiere, et paginer sans
-- filtre ferait defiler les fixtures des quatre autres fichiers.

do $$
declare
  v_page bigint[];
  v_tout bigint[];
  v_date timestamptz;
  v_id bigint;
  v_attendu bigint[];
  v_pages int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select array_agg(a.id order by a.created_at desc, a.id desc)
    into v_attendu
    from public.audit_logs a
   where a.action = 'adm04_alpha';

  v_tout := array[]::bigint[];
  v_date := null;
  v_id := null;
  v_pages := 0;

  -- La borne de boucle est un garde-fou, pas une attente : cinq entrees par
  -- pages de deux en font trois. Si le curseur n'avancait pas, une boucle sans
  -- borne tournerait jusqu'au delai d'attente de la CI au lieu de dire
  -- laquelle des deux regles est cassee.
  for i in 1..10 loop
    select array_agg(j.entree_id order by j.survenu_le desc, j.entree_id desc)
      into v_page
      from public.journal_audit(null, 'adm04_alpha', null, 2, v_date, v_id) j;

    exit when v_page is null;
    v_tout := v_tout || v_page;
    v_pages := v_pages + 1;

    -- Le curseur est la DERNIERE entree rendue, c'est-a-dire la plus ancienne
    -- de la page. Les deux bornes viennent de la meme ligne : prendre
    -- `min(survenu_le)` et `min(entree_id)` separement marcherait tant que les
    -- deux varient ensemble, et se tromperait le jour ou deux entrees
    -- partagent un horodatage.
    select derniere.survenu_le, derniere.entree_id into v_date, v_id
      from (
        select j.survenu_le, j.entree_id
          from public.journal_audit(null, 'adm04_alpha', null, 2, v_date, v_id) j
         order by j.survenu_le asc, j.entree_id asc
         limit 1
      ) derniere;
  end loop;

  if v_tout is distinct from v_attendu then
    raise exception 'J2 ECHEC : pagination attendue %, lue %', v_attendu, v_tout;
  end if;

  if v_pages <> 3 then
    raise exception 'J2 ECHEC : trois pages attendues pour cinq entrees par deux, lues %', v_pages;
  end if;

  raise notice 'J2 ok : trois pages, cinq entrees, le plus recent d''abord, aucune sautee ni rejouee';
end $$;

-- ============================================================
-- J3 : les trois filtres bornent reellement, chacun de son cote
-- ============================================================

do $$
declare
  v_n int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  -- Par type d'evenement.
  select count(*) into v_n from public.journal_audit(null, 'adm04_alpha', null, 200, null, null);
  if v_n <> 5 then
    raise exception 'J3 ECHEC : filtre par type, 5 attendues, lues %', v_n;
  end if;

  select count(*) into v_n from public.journal_audit(null, 'adm04_beta', null, 200, null, null);
  if v_n <> 1 then
    raise exception 'J3 ECHEC : filtre par type beta, 1 attendue, lue %', v_n;
  end if;

  -- Par acteur. Croise avec le type, pour rester borne aux fixtures de ce
  -- fichier : l'administratrice n'a ecrit qu'ici, mais rien ne le garantira
  -- toujours.
  select count(*) into v_n from public.journal_audit(
    'a4000000-0000-0000-0000-000000000002', 'adm04_alpha', null, 200, null, null);
  if v_n <> 0 then
    raise exception 'J3 ECHEC : l''enseignant n''a ecrit aucune alpha, lues %', v_n;
  end if;

  select count(*) into v_n from public.journal_audit(
    'a4000000-0000-0000-0000-000000000001', 'adm04_alpha', null, 200, null, null);
  if v_n <> 5 then
    raise exception 'J3 ECHEC : filtre par acteur, 5 attendues, lues %', v_n;
  end if;

  -- Par periode. Les deux sens, sans jamais toucher a `created_at` : une
  -- fixture retro-datee a la main sortirait du chainage et rendrait J4 rouge.
  select count(*) into v_n from public.journal_audit(
    null, 'adm04_alpha', now() - interval '1 hour', 200, null, null);
  if v_n <> 5 then
    raise exception 'J3 ECHEC : periode large, 5 attendues, lues %', v_n;
  end if;

  select count(*) into v_n from public.journal_audit(
    null, 'adm04_alpha', now() + interval '1 hour', 200, null, null);
  if v_n <> 0 then
    raise exception 'J3 ECHEC : periode future, 0 attendue, lues %', v_n;
  end if;

  raise notice 'J3 ok : acteur, type et periode bornent chacun, et dans les deux sens';
end $$;

-- ============================================================
-- J4 : la chaine entiere se verifie, fixtures des quatre autres fichiers
--      comprises
-- ============================================================

do $$
declare
  v_verifiees int;
  v_rompues int;
  v_total int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select count(*) into v_total from public.audit_logs;
  select v.verifiees, v.rompues into v_verifiees, v_rompues
    from public.verifier_chaine_audit(5000) v;

  if v_rompues <> 0 then
    raise exception 'J4 ECHEC : % entrees rompues sur % verifiees', v_rompues, v_verifiees;
  end if;

  -- La fenetre doit avoir vu TOUT le journal, sinon le zero ci-dessus ne dit
  -- rien : une fenetre vide ne rompt jamais.
  if v_verifiees <> least(v_total, 5000) then
    raise exception 'J4 ECHEC : % entrees verifiees pour % en base', v_verifiees, v_total;
  end if;

  if v_verifiees < 6 then
    raise exception 'J4 ECHEC : le journal devait contenir au moins les six fixtures, lu %', v_verifiees;
  end if;

  raise notice 'J4 ok : % entrees, chaine intacte de bout en bout', v_verifiees;
end $$;

-- ============================================================
-- J5 : une entree MODIFIEE se voit, et la reparation la rend de nouveau
--      intacte
-- ============================================================
--
-- C'est le scenario qui justifie que `log_sensitive_access` paie un
-- `lock table` a chaque ecriture depuis l'etape 1. Sans lui, `prev_hash` et
-- `hash` seraient deux colonnes que personne ne relit.

do $$
declare
  v_cible bigint;
  v_avant jsonb;
  v_rompues int;
  v_premiere bigint;
begin
  select a.id, a.payload into v_cible, v_avant
    from public.audit_logs a
   where a.action = 'adm04_alpha' and a.row_id = 'ligne-3';

  -- La falsification passe par le desarmement du garde-fou : c'est exactement
  -- le pouvoir qu'a un administrateur de BASE, et exactement celui contre
  -- lequel une chaine de hachage protege. Un attaquant sans ce pouvoir ne
  -- peut deja rien faire, les declencheurs de 0001 s'en chargent.
  alter table public.audit_logs disable trigger audit_logs_no_update;
  update public.audit_logs set payload = jsonb_build_object('rang', 99)
   where id = v_cible;

  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select v.rompues, v.premiere_rompue into v_rompues, v_premiere
    from public.verifier_chaine_audit(5000) v;

  if v_rompues <> 1 then
    raise exception 'J5 ECHEC : une seule entree modifiee, % signalees', v_rompues;
  end if;
  if v_premiere <> v_cible then
    raise exception 'J5 ECHEC : entree % attendue, % signalee', v_cible, v_premiere;
  end if;

  reset role;

  -- Reparation : la valeur d'origine restaure le condensat, donc la chaine.
  update public.audit_logs set payload = v_avant where id = v_cible;
  alter table public.audit_logs enable trigger audit_logs_no_update;

  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select v.rompues into v_rompues from public.verifier_chaine_audit(5000) v;
  if v_rompues <> 0 then
    raise exception 'J5 ECHEC : la reparation devait rendre la chaine intacte, % rompues', v_rompues;
  end if;

  raise notice 'J5 ok : une entree modifiee se voit a l''entree elle-meme, et la reparation se voit aussi';
end $$;

-- ============================================================
-- J6 : une entree SUPPRIMEE se voit, et elle se voit AILLEURS que la
--      modification
-- ============================================================
--
-- Le point de ce scenario : une suppression laisse tous les condensats
-- valides. Elle ne se voit QUE par le maillon, sur l'entree SUIVANTE, dont le
-- `prev_hash` ne correspond plus a rien. Sans le second controle de
-- `verifier_chaine_audit`, retirer une ligne genante serait indetectable.

do $$
declare
  v_cible bigint;
  v_suivante bigint;
  v_ligne public.audit_logs%rowtype;
  v_rompues int;
  v_premiere bigint;
begin
  select a.id into v_cible
    from public.audit_logs a
   where a.action = 'adm04_alpha' and a.row_id = 'ligne-3';
  select a.id into v_suivante
    from public.audit_logs a
   where a.action = 'adm04_alpha' and a.row_id = 'ligne-4';

  select * into v_ligne from public.audit_logs a where a.id = v_cible;

  alter table public.audit_logs disable trigger audit_logs_no_delete;
  delete from public.audit_logs where id = v_cible;

  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select v.rompues, v.premiere_rompue into v_rompues, v_premiere
    from public.verifier_chaine_audit(5000) v;

  if v_rompues <> 1 then
    raise exception 'J6 ECHEC : une seule suppression, % entrees signalees', v_rompues;
  end if;
  -- Et c'est bien la SUIVANTE qui parle, pas la disparue : une ligne absente
  -- ne peut pas se denoncer elle-meme.
  if v_premiere <> v_suivante then
    raise exception 'J6 ECHEC : l''entree suivante (%) devait signaler, % signalee', v_suivante, v_premiere;
  end if;

  reset role;

  -- Reparation : la ligne revient a l'identique, identite et horodatage
  -- compris, sans quoi la chaine resterait rompue pour tout le monde.
  insert into public.audit_logs
    (id, actor, actor_role, action, table_name, row_id, payload, prev_hash, hash, created_at)
  overriding system value
  values
    (v_ligne.id, v_ligne.actor, v_ligne.actor_role, v_ligne.action, v_ligne.table_name,
     v_ligne.row_id, v_ligne.payload, v_ligne.prev_hash, v_ligne.hash, v_ligne.created_at);
  alter table public.audit_logs enable trigger audit_logs_no_delete;

  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select v.rompues into v_rompues from public.verifier_chaine_audit(5000) v;
  if v_rompues <> 0 then
    raise exception 'J6 ECHEC : la remise en place devait rendre la chaine intacte, % rompues', v_rompues;
  end if;

  raise notice 'J6 ok : une suppression se voit par le maillon de l''entree suivante, la ou le condensat ne dit rien';
end $$;

-- ============================================================
-- J7 : les garde-fous des parametres
-- ============================================================
--
-- Le curseur incomplet merite son cas : une comparaison de lignes dont un
-- membre est NULL vaut NULL, donc « aucune ligne ». Sans le refus explicite,
-- un appel a moitie renseigne rendrait une page vide, et un journal qui
-- s'arrete au bout d'une page ressemble a un journal qui finit.

do $$
declare
  v_ok boolean;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  v_ok := false;
  begin
    perform * from public.journal_audit(null, null, null, 0, null, null);
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'J7 ECHEC : une limite de 0 a ete acceptee';
  end if;

  v_ok := false;
  begin
    perform * from public.journal_audit(null, null, null, 201, null, null);
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'J7 ECHEC : une limite de 201 a ete acceptee';
  end if;

  v_ok := false;
  begin
    perform * from public.journal_audit(null, null, null, 50, now(), null);
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'J7 ECHEC : un curseur sans identifiant a ete accepte';
  end if;

  v_ok := false;
  begin
    perform * from public.verifier_chaine_audit(0);
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'J7 ECHEC : une fenetre de verification de 0 a ete acceptee';
  end if;

  raise notice 'J7 ok : limites bornees et curseur entier ou rien';
end $$;

-- ============================================================
-- J8 : un acteur dont le compte est clos garde son nom dans le journal
-- ============================================================
--
-- Une jointure `deleted_at is null` ici rendrait anonymes les lignes de qui
-- part, c'est-a-dire exactement celles qu'un audit sert a relire. La jointure
-- de `journal_audit()` est donc volontairement sans filtre, et ce scenario le
-- fige.

do $$
declare
  v_nom text;
begin
  update public.profiles set deleted_at = now()
   where id = 'a4000000-0000-0000-0000-000000000002';

  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  select j.nom_acteur into v_nom
    from public.journal_audit(null, 'adm04_beta', null, 200, null, null) j;

  if v_nom is distinct from 'Moussa Kane' then
    raise exception 'J8 ECHEC : le nom devait survivre a la cloture du compte, lu %', v_nom;
  end if;

  reset role;
  update public.profiles set deleted_at = null
   where id = 'a4000000-0000-0000-0000-000000000002';

  raise notice 'J8 ok : une ligne de journal nomme encore son acteur apres la cloture de son compte';
end $$;

-- ============================================================
-- J9 : les filtres proposes viennent du journal, jamais d'une liste ecrite
-- ============================================================

do $$
declare
  v_filtres jsonb;
  v_n int;
  v_nom text;
begin
  set local role authenticated;
  perform set_config('test.uid', 'a4000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

  v_filtres := public.journal_audit_filtres();

  select (t.valeur ->> 'n')::int into v_n
    from jsonb_array_elements(v_filtres -> 'actions') t(valeur)
   where t.valeur ->> 'action' = 'adm04_alpha';
  if v_n is distinct from 5 then
    raise exception 'J9 ECHEC : adm04_alpha devait compter 5, lu %', v_n;
  end if;

  select t.valeur ->> 'nom', (t.valeur ->> 'n')::int into v_nom, v_n
    from jsonb_array_elements(v_filtres -> 'acteurs') t(valeur)
   where t.valeur ->> 'id' = 'a4000000-0000-0000-0000-000000000001';
  if v_nom is distinct from 'Khadija Ndiaye' then
    raise exception 'J9 ECHEC : l''administratrice devait etre nommee, lu %', v_nom;
  end if;
  if v_n < 5 then
    raise exception 'J9 ECHEC : l''administratrice devait compter au moins 5 entrees, lu %', v_n;
  end if;

  -- Aucun type propose qui n'existe pas en base : un filtre qui offre un
  -- chemin vers un ecran vide ment sur ce que le journal contient.
  perform 1
    from jsonb_array_elements(v_filtres -> 'actions') t(valeur)
   where not exists (
     select 1 from public.audit_logs a where a.action = t.valeur ->> 'action'
   );
  if found then
    raise exception 'J9 ECHEC : un type d''evenement propose n''existe pas en base';
  end if;

  if (v_filtres ->> 'total')::int <> (select count(*) from public.audit_logs) then
    raise exception 'J9 ECHEC : le total annonce ne correspond pas au journal';
  end if;

  raise notice 'J9 ok : les filtres ne proposent que ce que le journal contient';
end $$;
