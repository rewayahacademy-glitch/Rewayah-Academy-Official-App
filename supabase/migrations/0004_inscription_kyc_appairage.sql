-- 0004 : ce que l'etape 3 exige de la base
--
-- Source de verite : docs/architecture/etape-3-auth-kyc.md
--
-- Cette migration corrige les cinq defauts de la section 2 de ce document, puis
-- ajoute les tables et fonctions dont l'inscription, le KYC et l'appairage ont
-- besoin. Les cinq defauts n'etaient visibles d'aucune relecture de schema :
-- ils apparaissent quand on essaie de construire les ecrans.
--
-- Regles heritees de l'etape 1, appliquees ici sans exception :
--   - RLS activee sur toute table nouvelle ;
--   - toute fonction SECURITY DEFINER fixe search_path = '' et qualifie ;
--   - une fonction qui contourne la RLS revérifie l'autorisation metier ;
--   - suppression logique filtree dans chaque policy.

begin;

-- ============================================================
-- 1. Genre du personnel (defaut 2.3)
-- ============================================================

-- read_kyc_documents() deduisait le genre du lecteur de SES PROPRES documents
-- KYC, et se repliait silencieusement sur la branche masculine quand il n'en
-- avait aucun. Une administratrice qui n'a jamais depose de piece ne voyait donc
-- aucun dossier feminin. Le genre du personnel est une donnee de son profil.
alter table public.profiles add column gender public.gender;

comment on column public.profiles.gender is
  'Genre du titulaire. Seul usage : le cloisonnement de lecture des dossiers KYC '
  '(audit 1.3). Sans valeur, la lecture des dossiers est refusee, jamais filtree '
  'a moitie.';

-- ============================================================
-- 2. Le foyer n'existe que pour ceux qui en ont un (defaut 2.5)
-- ============================================================

-- profiles.household_id etait not null pour tout le monde. Un enseignant, un
-- controleur, un administrateur n'ont pas de foyer : leur en fabriquer un
-- polluerait la table qui sert d'unite de facturation et les compteurs de
-- ADM-01. On dit la verite, et on la rend verifiable.
alter table public.profiles alter column household_id drop not null;

alter table public.profiles add constraint profiles_household_required check (
  role in ('admin', 'accountant', 'controller', 'teacher')
  or household_id is not null
);

comment on constraint profiles_household_required on public.profiles is
  'Un eleve et un tuteur appartiennent a un foyer, le personnel n''en a pas. '
  'Un eleve adulte autonome est un foyer d''une personne (ADR-009).';

-- ============================================================
-- 3. Un appareil se partage entre les enfants d'un foyer (defaut 2.4)
-- ============================================================

-- L'unicite portait sur l'empreinte seule : une tablette ne pouvait etre
-- appairee qu'a un seul enfant, alors que ELV-01 est construit autour du choix
-- de profil sur appareil partage.
alter table public.devices drop constraint devices_fingerprint_unique;

alter table public.devices
  add constraint devices_profile_fingerprint_unique
  unique (profile_id, device_fingerprint);

-- Jeton d'appareil emis par le serveur (ADR-010). L'empreinte est fournie par le
-- client, donc forgeable ; le jeton ne l'est pas. Seule son empreinte est
-- stockee : un vol de base ne rend aucun appareil utilisable.
alter table public.devices add column token_hash text;
alter table public.devices add column last_used_at timestamptz;
alter table public.devices add column label text;

create unique index devices_token_hash_uidx
  on public.devices (token_hash) where token_hash is not null;

-- C11 tenue aussi a la reactivation. Le declencheur d'insertion de l'etape 1 ne
-- voyait pas ce chemin : reactiver un appareil revoque pouvait porter un eleve
-- a trois appareils actifs sans qu'aucune insertion n'ait lieu.
create function public.guard_devices_max_reactivation()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  max_devices int;
begin
  if old.revoked_at is null or new.revoked_at is not null then
    return new;
  end if;

  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into max_devices;

  if (select count(*) from public.devices d
      where d.profile_id = new.profile_id
        and d.id <> new.id
        and d.revoked_at is null
        and d.deleted_at is null) >= max_devices then
    raise exception 'plafond d''appareils atteint';
  end if;

  return new;
end;
$$;

create trigger devices_cap_reactivation
before update on public.devices
for each row execute function public.guard_devices_max_reactivation();

-- ============================================================
-- 4. Motif de refus et duree de conservation des pieces
-- ============================================================

-- TUT-00b affiche « le motif en une phrase, et l'action pour corriger ». Sans
-- colonne, l'ecran refuse n'avait rien a dire.
alter table public.kyc_documents add column rejection_reason text;

insert into public.app_config (key, value) values
  ('kyc_retention_days', '90'::jsonb),
  ('pairing_code_ttl_minutes', '10'::jsonb)
on conflict (key) do nothing;

-- Deux valeurs que le client n'a pas a fournir : la date de purge, et surtout le
-- genre.
--
-- Le genre porte par un dossier decide **quel membre du personnel pourra
-- l'ouvrir** (audit 1.3). Le laisser arriver du client reviendrait a confier au
-- deposant le choix de qui le regarde. Il est donc ecrase par celui du profil
-- concerne, et un genre inconnu fait echouer le depot plutot que de creer un
-- dossier que personne ne pourra classer.
create function public.completer_kyc_document()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_genre public.gender;
begin
  if new.purge_at is null then
    new.purge_at := now() + make_interval(days =>
      coalesce((public.get_config('kyc_retention_days', '90'::jsonb) #>> '{}')::int, 90));
  end if;

  select p.gender into v_genre
  from public.profiles p
  where p.id = new.profile_id and p.deleted_at is null;

  if v_genre is null then
    raise exception 'genre du titulaire inconnu : impossible de classer ce dossier';
  end if;

  new.gender := v_genre;
  return new;
end;
$$;

create trigger kyc_documents_completer
before insert on public.kyc_documents
for each row execute function public.completer_kyc_document();

-- ============================================================
-- 5. L'enseignant et le controleur deposent leur propre piece (defaut 2.2)
-- ============================================================

-- La seule policy d'insertion etait kyc_guardian_insert, qui exige le role
-- tuteur. La matrice d'acces de l'etape 1 accorde pourtant a l'enseignant un
-- « E sien » : son parcours d'inscription etait bloque des sa premiere action.
--
-- Volontairement aucune policy de SELECT : le titulaire connait l'etat de son
-- dossier par etat_dossier(), qui rend un resume et jamais la piece. On
-- n'elargit pas une surface de lecture pour afficher un statut.
create policy kyc_staff_self_insert on public.kyc_documents
  for insert to authenticated
  with check (
    profile_id = auth.uid()
    and public.app_role() in ('teacher', 'controller')
  );

-- ============================================================
-- 6. Lecture des dossiers : le genre vient du profil, son absence est un refus
-- ============================================================

create or replace function public.read_kyc_documents()
returns setof public.kyc_documents
language plpgsql security definer set search_path = ''
as $$
declare
  reader_gender public.gender;
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'acces KYC refuse';
  end if;

  select p.gender into reader_gender
  from public.profiles p
  where p.id = auth.uid() and p.deleted_at is null;

  -- I9 : un genre inconnu ferme, il ne filtre pas a moitie. Un repli silencieux
  -- rendait la moitie des dossiers invisible sans que personne ne le sache.
  --
  -- Ce refus precede volontairement la journalisation : une exception annule la
  -- transaction, donc journaliser d'abord ecrirait la trace d'une lecture qui
  -- n'a jamais eu lieu, puis l'effacerait. On refuse, puis on journalise ce qui
  -- va reellement sortir.
  if reader_gender is null then
    raise exception 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier';
  end if;

  -- Chaque lecture est journalisee avant que la moindre ligne ne sorte
  -- (invariant I8, scenario 12 de l'etape 1).
  perform public.log_sensitive_access('kyc_read', 'kyc_documents', null::text,
    jsonb_build_object('reader_gender', reader_gender));

  return query
    select k.* from public.kyc_documents k
    where k.deleted_at is null and k.gender = reader_gender;
end;
$$;

-- ============================================================
-- 7. Acceptations de contrat (ADR-011, ADR-013)
-- ============================================================

create table public.contract_acceptances (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  contract_kind text not null check (contract_kind in (
    'guardian_terms',                 -- conditions d'utilisation du tuteur
    'teacher_nda',                    -- contrat de non-concurrence de l'enseignant
    'recording_and_control_notice'    -- carte a accuser une fois (ADR-011)
  )),
  version text not null,
  accepted_at timestamptz not null default now(),
  constraint contract_acceptances_once unique (profile_id, contract_kind, version)
);

alter table public.contract_acceptances enable row level security;

create policy contract_acceptances_admin_read on public.contract_acceptances
  for select to authenticated using (public.app_role() = 'admin');
create policy contract_acceptances_self_read on public.contract_acceptances
  for select to authenticated using (profile_id = auth.uid());
create policy contract_acceptances_self_insert on public.contract_acceptances
  for insert to authenticated with check (profile_id = auth.uid());

-- Une signature est un fait, pas un etat. Ni modifiable, ni effacable : c'est ce
-- qui la rend opposable le jour d'un litige (ADR-011, « un enseignant qui
-- decouvre le dispositif apres coup est un litige »).
create function public.guard_contract_acceptances_immutable()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'une acceptation de contrat ne se modifie ni ne s''efface';
end;
$$;

create trigger contract_acceptances_no_update
before update on public.contract_acceptances
for each row execute function public.guard_contract_acceptances_immutable();

create trigger contract_acceptances_no_delete
before delete on public.contract_acceptances
for each row execute function public.guard_contract_acceptances_immutable();

revoke update, delete on public.contract_acceptances
  from public, anon, authenticated, service_role;

-- ============================================================
-- 8. Codes d'appairage ephemeres
-- ============================================================

create table public.device_pairing_codes (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references public.profiles(id) on delete cascade,
  -- I4 : l'empreinte, jamais le code. Le code n'existe qu'a l'ecran du tuteur,
  -- le temps de sa validite.
  code_hash text not null,
  created_by uuid not null references public.profiles(id),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  consumed_by_device uuid references public.devices(id),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index device_pairing_codes_hash_uidx
  on public.device_pairing_codes (code_hash)
  where consumed_at is null and deleted_at is null;

alter table public.device_pairing_codes enable row level security;

create policy pairing_codes_admin_read on public.device_pairing_codes
  for select to authenticated using (public.app_role() = 'admin');

-- Aucune policy pour le tuteur : il lit par la vue ci-dessous, qui ne porte pas
-- l'empreinte du code. Principe 8 de l'etape 1 : on expose par une vue, on ne
-- durcit pas une policy pour cacher une colonne.
revoke all on public.device_pairing_codes from anon;

create view public.mes_codes_appairage_v
with (security_barrier = true)
as
select
  c.id,
  c.student_profile_id,
  c.expires_at,
  c.consumed_at,
  c.created_at
from public.device_pairing_codes c
join public.profiles p on p.id = c.student_profile_id
where c.deleted_at is null
  and p.deleted_at is null
  and p.household_id is not null
  and p.household_id = public.app_household_id();

comment on view public.mes_codes_appairage_v is
  'Ce que le tuteur voit d''un code d''appairage : a quel enfant il appartient et '
  'quand il expire. Jamais l''empreinte, jamais le code.';

-- ============================================================
-- 9. Aide de foyer, employee par les policies de stockage
-- ============================================================

create function public.profil_de_mon_foyer(p_profile_id text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id::text = p_profile_id
      and p.household_id is not null
      and p.household_id = public.app_household_id()
      and p.deleted_at is null
  );
$$;

comment on function public.profil_de_mon_foyer(text) is
  'Compare en texte volontairement : le segment de chemin vient du nom d''un '
  'objet de stockage, donc du client. Le convertir en uuid ferait echouer la '
  'policy sur une valeur mal formee au lieu de la refuser.';

-- ============================================================
-- 10. Creation du profil a l'inscription (defaut 2.1)
-- ============================================================

-- Rien ne creait la ligne profiles a l'inscription. Le hook de jeton n'injectait
-- alors ni role ni foyer, et le routeur renvoyait le nouveau compte sur l'ecran
-- de connexion en boucle : le produit n'avait aucune porte d'entree.
create function public.creer_profil_inscription(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender default null,
  p_timezone text default 'Europe/Paris'
) returns public.profiles
language plpgsql security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
  v_initiales text;
begin
  if v_uid is null then
    raise exception 'aucune session';
  end if;

  -- I1 : deux roles publics, pas un de plus. Ni admin, ni controleur, ni
  -- comptable : ce sont des privileges, ils s'attribuent. Ni eleve : un eleve
  -- est cree par son tuteur, jamais par inscription.
  if p_role not in ('guardian', 'teacher') then
    raise exception 'role non ouvert a l''inscription publique : %', p_role;
  end if;
  v_role := p_role::public.app_role;

  -- I3 : un compte, un profil.
  if exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'ce compte a deja un profil';
  end if;

  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;

  -- Un tuteur fonde son foyer ; le personnel n'en a pas.
  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;

  v_initiales := upper(left(btrim(p_first_name), 1) || left(btrim(p_last_name), 1));

  insert into public.profiles (
    id, immutable_id, role, household_id, first_name, last_name, gender, account_status
  ) values (
    v_uid,
    public.next_immutable_id(v_role, v_initiales),
    v_role,
    v_household,
    btrim(p_first_name),
    btrim(p_last_name),
    p_gender,
    -- I2 : ecrit en dur. provisional_active n'est atteignable que par un import
    -- declenche par l'administration (ADR-014, scenario 20 de l'etape 1).
    'pending_kyc'
  )
  returning * into v_profile;

  if v_role = 'guardian' then
    update public.households set primary_guardian_id = v_uid where id = v_household;
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;

  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));

  return v_profile;
end;
$$;

revoke execute on function public.creer_profil_inscription(text, text, text, public.gender, text)
  from public, anon;
grant execute on function public.creer_profil_inscription(text, text, text, public.gender, text)
  to authenticated;

-- ============================================================
-- 11. Etat du dossier, pour le portail d'attente
-- ============================================================

create function public.etat_dossier()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_doc public.kyc_documents;
  v_contrat boolean;
  v_accuse boolean;
begin
  if auth.uid() is null then
    raise exception 'aucune session';
  end if;

  select * into v_profile
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;

  -- Aucun profil : c'est une inscription a terminer, pas un dossier a attendre.
  if v_profile.id is null then
    return jsonb_build_object('profil', false);
  end if;

  select * into v_doc
  from public.kyc_documents k
  where k.profile_id = v_profile.id and k.deleted_at is null
  order by k.created_at desc
  limit 1;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = case when v_profile.role = 'teacher'
                                 then 'teacher_nda' else 'guardian_terms' end
  ) into v_contrat;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = 'recording_and_control_notice'
  ) into v_accuse;

  return jsonb_build_object(
    'profil', true,
    'role', v_profile.role::text,
    'statut', v_profile.account_status::text,
    'piece_deposee', v_doc.id is not null,
    'piece_statut', v_doc.status::text,
    'motif_refus', v_doc.rejection_reason,
    'depose_le', v_doc.created_at,
    'contrat_signe', v_contrat,
    'accuse_signe', v_accuse
  );
end;
$$;

revoke execute on function public.etat_dossier() from public, anon;
grant execute on function public.etat_dossier() to authenticated;

-- ============================================================
-- 12. File de validation et verdict (ADM-02)
-- ============================================================

-- Construite SUR read_kyc_documents() et non a cote : le filtre de genre et la
-- journalisation ne peuvent donc pas etre contournes par cette porte.
create function public.dossiers_en_attente()
returns table (
  document_id uuid,
  profile_id uuid,
  doc_type text,
  document_gender public.gender,
  object_key text,
  depose_le timestamptz,
  first_name text,
  last_name text,
  immutable_id text,
  role public.app_role
)
language sql security definer set search_path = ''
as $$
  select k.id, k.profile_id, k.doc_type, k.gender, k.object_key, k.created_at,
         p.first_name, p.last_name, p.immutable_id, p.role
  from public.read_kyc_documents() k
  join public.profiles p on p.id = k.profile_id
  where k.status = 'pending' and p.deleted_at is null
  -- Anciennete d'abord : un dossier ne doit jamais pouvoir rester invisible en
  -- bas d'une liste (meme regle que le feed de ENS-06).
  order by k.created_at asc;
$$;

revoke execute on function public.dossiers_en_attente() from public, anon;
grant execute on function public.dossiers_en_attente() to authenticated;

create function public.decider_dossier(
  p_document_id uuid,
  p_approuve boolean,
  p_motif text default null
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_doc public.kyc_documents;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur decide d''un dossier';
  end if;

  -- Un refus sans motif laisserait TUT-00b sans rien a dire, et la famille sans
  -- rien a corriger.
  if not p_approuve and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  -- Le filtre de genre s'applique a la decision, pas seulement a l'affichage :
  -- sinon il suffirait de connaitre un identifiant pour le contourner.
  select * into v_doc from public.read_kyc_documents() k where k.id = p_document_id;
  if v_doc.id is null then
    raise exception 'dossier introuvable ou hors du perimetre de lecture';
  end if;

  update public.kyc_documents
  set status = case when p_approuve then 'approved'::public.kyc_doc_status
                    else 'rejected'::public.kyc_doc_status end,
      rejection_reason = case when p_approuve then null else btrim(p_motif) end,
      verified_by = auth.uid(),
      verified_at = now()
  where id = p_document_id;

  if p_approuve then
    update public.profiles
    set account_status = 'active', updated_at = now()
    where id = v_doc.profile_id and account_status = 'pending_kyc';
  end if;

  update public.teacher_profiles
  set kyc_status = case when p_approuve then 'approved' else 'rejected' end
  where profile_id = v_doc.profile_id;

  perform public.log_sensitive_access('kyc_decision', 'kyc_documents', p_document_id::text,
    jsonb_build_object('approuve', p_approuve, 'motif', btrim(coalesce(p_motif, ''))));
end;
$$;

revoke execute on function public.decider_dossier(uuid, boolean, text) from public, anon;
grant execute on function public.decider_dossier(uuid, boolean, text) to authenticated;

-- ============================================================
-- 13. Appairage : creation du code, puis consommation
-- ============================================================

create function public.creer_code_appairage(p_student_profile_id uuid)
returns table (code text, expires_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
declare
  -- 32 caracteres, sans 0 O 1 I : 256 est un multiple de 32, donc le tirage est
  -- uniforme sans biais de modulo. 32^6, soit environ 1,07 milliard.
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text;
  v_expire timestamptz;
  v_max int;
  v_actifs int;
begin
  if public.app_role() <> 'guardian' or not public.app_account_valid() then
    raise exception 'seul un tuteur au compte valide appaire un appareil';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.household_id is not null
      and p.household_id = public.app_household_id()
      and p.role = 'student'
      and p.deleted_at is null
  ) then
    raise exception 'cet eleve n''appartient pas a votre foyer';
  end if;

  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into v_max;
  select count(*) into v_actifs from public.devices d
  where d.profile_id = p_student_profile_id
    and d.revoked_at is null and d.deleted_at is null;
  if v_actifs >= v_max then
    raise exception 'plafond d''appareils atteint';
  end if;

  -- Un seul code vivant par eleve : en demander un nouveau perime le precedent.
  update public.device_pairing_codes
  set deleted_at = now()
  where student_profile_id = p_student_profile_id
    and consumed_at is null and deleted_at is null;

  select string_agg(substr(v_alphabet, 1 + (get_byte(s.b, i) % 32), 1), '' order by i)
  into v_code
  from (select public.gen_random_bytes(6) as b) s,
       generate_series(0, 5) as i;

  v_expire := now() + make_interval(mins =>
    coalesce((public.get_config('pairing_code_ttl_minutes', '10'::jsonb) #>> '{}')::int, 10));

  insert into public.device_pairing_codes (student_profile_id, code_hash, created_by, expires_at)
  values (
    p_student_profile_id,
    encode(public.digest(convert_to(v_code, 'UTF8'), 'sha256'), 'hex'),
    auth.uid(),
    v_expire
  );

  perform public.log_sensitive_access('appairage_code_cree', 'device_pairing_codes',
    p_student_profile_id::text, '{}'::jsonb);

  return query select v_code, v_expire;
end;
$$;

revoke execute on function public.creer_code_appairage(uuid) from public, anon;
grant execute on function public.creer_code_appairage(uuid) to authenticated;

-- Consommation : appelee par la fonction Edge session-enfant, jamais par un
-- client. L'appareil qui presente le code n'a par construction aucune session.
create function public.consommer_code_appairage(
  p_code text,
  p_device_fingerprint text,
  p_platform text
) returns table (profile_id uuid, device_id uuid, device_token text)
language plpgsql security definer set search_path = ''
as $$
declare
  v_hash text := encode(public.digest(convert_to(upper(btrim(p_code)), 'UTF8'), 'sha256'), 'hex');
  v_row public.device_pairing_codes;
  v_device uuid;
  v_token text := encode(public.gen_random_bytes(32), 'hex');
  v_max int;
  v_actifs int;
begin
  select * into v_row
  from public.device_pairing_codes c
  where c.code_hash = v_hash and c.deleted_at is null
  for update;

  if v_row.id is null then
    raise exception 'code inconnu';
  end if;
  if v_row.consumed_at is not null then
    raise exception 'code deja utilise';
  end if;
  if v_row.expires_at <= now() then
    raise exception 'code expire';
  end if;

  -- I7 : le plafond est verifie au moment ou l'appareil arrive, pas seulement au
  -- moment ou le code a ete demande. L'appareil en cours d'appairage est exclu
  -- du compte, pour qu'un reappairage ne se compte pas deux fois.
  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into v_max;
  select count(*) into v_actifs from public.devices d
  where d.profile_id = v_row.student_profile_id
    and d.device_fingerprint <> p_device_fingerprint
    and d.revoked_at is null and d.deleted_at is null;
  if v_actifs >= v_max then
    raise exception 'plafond d''appareils atteint';
  end if;

  insert into public.devices (
    profile_id, device_fingerprint, platform, token_hash, last_used_at
  ) values (
    v_row.student_profile_id, p_device_fingerprint, p_platform,
    encode(public.digest(convert_to(v_token, 'UTF8'), 'sha256'), 'hex'), now()
  )
  -- Le conflit se designe par le NOM de la contrainte, pas par ses colonnes :
  -- `profile_id` est aussi le nom d'un parametre de sortie de cette fonction, et
  -- PL/pgSQL ne sait pas lequel des deux est vise dans une clause d'inference.
  on conflict on constraint devices_profile_fingerprint_unique do update
  set token_hash = excluded.token_hash,
      revoked_at = null,
      last_used_at = now()
  returning id into v_device;

  update public.device_pairing_codes
  set consumed_at = now(), consumed_by_device = v_device
  where id = v_row.id;

  perform public.log_sensitive_access('appairage_consomme', 'devices', v_device::text,
    jsonb_build_object('platform', p_platform));

  return query select v_row.student_profile_id, v_device, v_token;
end;
$$;

revoke execute on function public.consommer_code_appairage(text, text, text)
  from public, anon, authenticated;
grant execute on function public.consommer_code_appairage(text, text, text) to service_role;

-- Le jeton d'appareil rouvre une session sans repasser par un code. Reserve a la
-- fonction Edge pour la meme raison.
create function public.profil_du_jeton_appareil(p_token text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_hash text := encode(public.digest(convert_to(p_token, 'UTF8'), 'sha256'), 'hex');
  v_profile uuid;
begin
  select d.profile_id into v_profile
  from public.devices d
  where d.token_hash = v_hash
    and d.revoked_at is null and d.deleted_at is null;

  if v_profile is null then
    raise exception 'jeton d''appareil inconnu ou revoque';
  end if;

  update public.devices set last_used_at = now() where token_hash = v_hash;
  return v_profile;
end;
$$;

revoke execute on function public.profil_du_jeton_appareil(text)
  from public, anon, authenticated;
grant execute on function public.profil_du_jeton_appareil(text) to service_role;

-- ============================================================
-- 14. Creation d'un profil enfant, appelee par la fonction Edge
-- ============================================================

-- La creation de l'utilisateur auth revient a la fonction Edge, seule detentrice
-- de la cle de service. Tout le reste, y compris la reverification que
-- l'appelant est bien le tuteur du foyer vise, est ici : la cle de service
-- contourne la RLS, elle ne remplace pas le controle metier (etape 1, regle 4).
create function public.creer_profil_enfant(
  p_auth_user_id uuid,
  p_guardian_id uuid,
  p_first_name text,
  p_last_name text,
  p_age int,
  p_level text default null
) returns public.profiles
language plpgsql security definer set search_path = ''
as $$
declare
  v_guardian public.profiles;
  v_profile public.profiles;
  v_mode public.interface_mode;
  v_camera public.camera_policy;
  v_seuil_enfant int;
  v_age_camera int;
begin
  select * into v_guardian
  from public.profiles p
  where p.id = p_guardian_id and p.deleted_at is null;

  if v_guardian.id is null or v_guardian.role <> 'guardian' then
    raise exception 'l''appelant n''est pas un tuteur';
  end if;
  if v_guardian.household_id is null then
    raise exception 'ce tuteur n''a pas de foyer';
  end if;
  if v_guardian.account_status not in ('active', 'provisional_active') then
    raise exception 'compte tuteur non valide';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;
  if p_age is null or p_age < 3 or p_age > 99 then
    raise exception 'age hors bornes';
  end if;

  -- Les deux valeurs initiales viennent de la configuration, jamais du client :
  -- ce sont elles qui decident du mode d'interface et de la politique camera
  -- (ADR-009). Le tuteur les modifie ensuite, enfant par enfant, depuis TUT-05.
  select coalesce((public.get_config('child_ui_mode_max_age', '8'::jsonb) #>> '{}')::int, 8)
    into v_seuil_enfant;
  select coalesce((public.get_config('camera_auto_allow_min_age', '11'::jsonb) #>> '{}')::int, 11)
    into v_age_camera;

  v_mode := case when p_age <= v_seuil_enfant then 'child' else 'standard' end;
  v_camera := case when p_age >= v_age_camera then 'allowed' else 'forbidden' end;

  insert into public.profiles (
    id, immutable_id, role, household_id, first_name, last_name, account_status
  ) values (
    p_auth_user_id,
    public.next_immutable_id('student', upper(left(btrim(p_first_name), 1) || left(btrim(p_last_name), 1))),
    'student',
    v_guardian.household_id,
    btrim(p_first_name),
    btrim(p_last_name),
    -- L'enfant herite de l'acces de son foyer : le dossier valide est celui du
    -- tuteur, l'enfant n'en depose aucun.
    v_guardian.account_status
  )
  returning * into v_profile;

  insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy, level)
  values (p_auth_user_id, 'minor', v_mode, v_camera, p_level);

  perform public.log_sensitive_access('profil_enfant_cree', 'profiles', p_auth_user_id::text,
    jsonb_build_object('household_id', v_guardian.household_id, 'mode', v_mode::text));

  return v_profile;
end;
$$;

revoke execute on function public.creer_profil_enfant(uuid, uuid, text, text, int, text)
  from public, anon, authenticated;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, int, text)
  to service_role;

-- Les profils du foyer que l'appareil de l'enfant met en cache local, pour que
-- le choix de profil de ELV-01 fonctionne hors ligne. Prenom et avatar
-- seulement : le cache local ne peut pas fuiter ce qu'il ne contient pas.
create view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  p.first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null;

-- ============================================================
-- 15. Le journal d'audit fuyait par sa partition (defaut trouve a l'etape 3)
-- ============================================================

-- `alter table public.audit_logs enable row level security` de l'etape 1 ne
-- protege QUE le parent. Une partition porte sa propre RLS, et
-- `audit_logs_default` n'en avait aucune. Mesure faite sur Postgres 17 : un
-- tuteur lit 0 ligne par `public.audit_logs`, et 24 par
-- `public.audit_logs_default`, dont chaque consultation de dossier KYC, avec le
-- nom du lecteur. Les droits par defaut de Supabase accordent ces tables a
-- `authenticated`, donc la fuite est atteignable depuis n'importe quel compte.
--
-- Activer la RLS sur la partition SANS y poser de policy est plus strict que d'y
-- recopier celle du parent : une requete sur le parent applique les policies du
-- parent et ignore celles des partitions, donc les lectures legitimes de l'admin
-- et du controleur continuent de passer, tandis qu'un acces direct a la
-- partition se heurte au refus par defaut.
alter table public.audit_logs_default enable row level security;

revoke insert, update, delete on public.audit_logs_default
  from public, anon, authenticated, service_role;

-- Meme oubli possible sur chaque partition mensuelle a venir. La tache planifiee
-- qui les cree doit passer par ici, jamais par un `create table ... partition of`
-- ecrit a la main.
create function public.attacher_partition_audit(p_debut date)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_nom text := 'audit_logs_' || to_char(p_debut, 'YYYY_MM');
  v_fin date := (p_debut + interval '1 month')::date;
begin
  if to_regclass('public.' || v_nom) is not null then
    return v_nom;
  end if;

  execute format(
    'create table public.%I partition of public.audit_logs for values from (%L) to (%L)',
    v_nom, p_debut, v_fin);

  -- Les deux lignes qui manquaient a la partition par defaut.
  execute format('alter table public.%I enable row level security', v_nom);
  execute format(
    'revoke insert, update, delete on public.%I from public, anon, authenticated, service_role',
    v_nom);

  return v_nom;
end;
$$;

revoke execute on function public.attacher_partition_audit(date)
  from public, anon, authenticated;
grant execute on function public.attacher_partition_audit(date) to service_role;

-- ============================================================
-- 16. Stockage : deux seaux prives
-- ============================================================

-- Le schema storage n'existe pas sur un Postgres nu : le harnais de la CI
-- applique les memes migrations sans lui. Le bloc se saute proprement plutot que
-- de faire echouer la migration la ou elle n'a pas lieu de s'appliquer.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    raise notice 'schema storage absent : seaux et policies ignores (harnais Postgres nu)';
    return;
  end if;

  insert into storage.buckets (id, name, public)
  values ('kyc', 'kyc', false), ('avatars', 'avatars', false)
  on conflict (id) do nothing;

  -- KYC : chacun depose dans son propre dossier, personne ne relit depuis le
  -- client. L'apercu de ADM-02 passe par une URL signee generee cote serveur,
  -- et chaque consultation est journalisee par read_kyc_documents().
  execute $p$
    create policy kyc_depot_self on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'kyc'
        and (storage.foldername(name))[1] = auth.uid()::text
      )
  $p$;

  execute $p$
    create policy kyc_lecture_admin on storage.objects
      for select to authenticated
      using (bucket_id = 'kyc' and public.app_role() in ('admin', 'controller'))
  $p$;

  -- Avatars : le dossier porte l'identifiant de l'enfant. Le tuteur ecrit, le
  -- foyer et l'enfant lisent (ADR-012). Ni l'enseignant ni les autres eleves :
  -- teacher_roster_v et session_peers_v ne portent pas l'avatar.
  execute $p$
    create policy avatar_ecriture_foyer on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'avatars'
        and public.app_role() = 'guardian'
        and public.profil_de_mon_foyer((storage.foldername(name))[1])
      )
  $p$;

  execute $p$
    create policy avatar_remplacement_foyer on storage.objects
      for update to authenticated
      using (
        bucket_id = 'avatars'
        and public.app_role() = 'guardian'
        and public.profil_de_mon_foyer((storage.foldername(name))[1])
      )
  $p$;

  execute $p$
    create policy avatar_suppression_foyer on storage.objects
      for delete to authenticated
      using (
        bucket_id = 'avatars'
        and public.app_role() = 'guardian'
        and public.profil_de_mon_foyer((storage.foldername(name))[1])
      )
  $p$;

  execute $p$
    create policy avatar_lecture_foyer on storage.objects
      for select to authenticated
      using (
        bucket_id = 'avatars'
        and (
          (storage.foldername(name))[1] = auth.uid()::text
          or public.profil_de_mon_foyer((storage.foldername(name))[1])
        )
      )
  $p$;
end
$storage$;

commit;
