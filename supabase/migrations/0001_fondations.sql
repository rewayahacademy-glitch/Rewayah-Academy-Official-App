-- 0001: Fondations — schéma, RLS, fonctions, triggers
-- Source de vérité: docs/archive/2026-09-pre-remise-a-plat/architecture/etape-0-1-fondations.md
-- Règles: RLS partout, SECURITY DEFINER => search_path='', argent en entiers,
--         role/foyer lus du JWT (hook custom_access_token), deleted_at partout.

begin;

-- pgcrypto vit dans le schema `extensions`, pas dans `public`.
--
-- Sur un projet Supabase reel, l'extension est DEJA installee dans `extensions` :
-- un `create extension if not exists pgcrypto` sans schema n'y installe rien et ne
-- signale rien, puis chaque appel a `public.digest` echoue a la premiere ecriture
-- d'audit. C'est ce qui aurait fait tomber cette migration au premier `db push`.
-- Les deux lignes ci-dessous sont donc ecrites pour valoir des deux cotes : sur
-- Supabase elles ne font rien, sur un Postgres nu elles posent le meme schema.
-- Les appels sont qualifies `extensions.` parce que toutes les fonctions de ce
-- depot portent `set search_path = ''` : rien n'est resolu implicitement.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
grant usage on schema extensions to public;

-- ============================================================
-- Types
-- ============================================================

create type public.app_role as enum
  ('admin', 'accountant', 'controller', 'teacher', 'guardian', 'student');

create type public.account_status as enum
  ('active', 'provisional_active', 'disabled');

create type public.student_type as enum ('minor', 'autonomous');

create type public.interface_mode as enum ('child', 'standard');

create type public.camera_policy as enum ('allowed', 'forbidden');

create type public.kyc_doc_status as enum ('pending', 'approved', 'rejected');

create type public.gender as enum ('male', 'female');

create type public.session_status as enum
  ('planned', 'preflight', 'in_progress', 'ended',
   'teacher_absent', 'student_absent', 'tech_failure',
   'canceled_late', 'canceled');

create type public.participant_role as enum
  ('teacher', 'student', 'guardian_observer', 'masked_controller');

create type public.session_event_type as enum
  ('joined', 'left', 'track_subscribed', 'track_unsubscribed', 'record_started', 'record_ended');

create type public.recording_status as enum ('available', 'expired', 'revoked');

create type public.recurrence_rule as enum
  ('weekly', 'biweekly', 'four_weekly', 'weekdays', 'custom');

-- ============================================================
-- Identité et foyer
-- ============================================================

create table public.households (
  id uuid primary key default gen_random_uuid(),
  primary_guardian_id uuid,           -- ajoûté après creates des profiles
  timezone text not null default 'Europe/Paris',
  status text not null default 'active' check (status in ('active', 'suspended', 'closed')),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  immutable_id text not null,
  role public.app_role not null,
  household_id uuid not null references public.households(id),
  first_name text not null,
  last_name text not null,
  account_status public.account_status not null default 'active',
  access_until timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_immutable_id_unique unique (immutable_id)
);

alter table public.households
  add constraint households_primary_guardian_fk
  foreign key (primary_guardian_id) references public.profiles(id);

create table public.teacher_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  country text,
  languages text[] not null default '{}',
  weekly_hours_cap int not null default 40 check (weekly_hours_cap between 1 and 80),
  kyc_status text not null default 'pending' check (kyc_status in ('pending', 'approved', 'rejected')),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.student_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  student_type public.student_type not null default 'minor',
  interface_mode public.interface_mode not null default 'child',
  level text,
  riwaya text not null default 'hafs',
  camera_policy public.camera_policy not null default 'forbidden',
  avatar_storage_key text,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.kyc_documents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  doc_type text not null check (doc_type in ('id_card', 'passport', 'residence_permit', 'other')),
  gender public.gender not null,
  object_key text not null,
  status public.kyc_doc_status not null default 'pending',
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  purge_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  device_fingerprint text not null,
  platform text not null check (platform in ('windows', 'android', 'ios', 'web')),
  paired_at timestamptz not null default now(),
  revoked_at timestamptz,
  deleted_at timestamptz,
  constraint devices_fingerprint_unique unique (device_fingerprint)
);

-- ============================================================
-- Planning et session
-- ============================================================

create table public.recurrence_rules (
  id uuid primary key default gen_random_uuid(),
  local_time time not null,
  timezone_iana text not null default 'Europe/Paris',
  rule public.recurrence_rule not null,
  recurrence_end_date date,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  recurrence_id uuid references public.recurrence_rules(id),
  status text not null default 'available' check (status in ('available', 'booked', 'cancelled')),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint availability_slots_range_ok check (ends_at > starts_at)
);

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  status public.session_status not null default 'planned',
  room text,
  session_type text not null default 'standard' check (session_type in ('standard', 'child')),
  -- colonnes d'effet financier créées dès maintenant, inutilisées en MVP-0:
  credit_amount_minor bigint,
  currency text check (currency ~ '^[A-Z]{3}$'),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sessions_range_ok check (ended_at > started_at)
);

create table public.session_participants (
  session_id uuid not null references public.sessions(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.participant_role not null,
  entered_at timestamptz,
  exited_at timestamptz,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (session_id, profile_id)
);

-- C4: exactement un enseignant par session.
create unique index session_participants_one_teacher_uidx
  on public.session_participants (session_id) where role = 'teacher';

create table public.session_events (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.sessions(id) on delete cascade,
  profile_id uuid references public.profiles(id),
  event_type public.session_event_type not null,
  server_ts timestamptz not null default now(),
  source text not null default 'livekit_webhook'
);

create table public.session_recordings (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  object_key text not null,
  duration_seconds int not null check (duration_seconds >= 0),
  size_bytes bigint not null check (size_bytes >= 0),
  codec text,
  status public.recording_status not null default 'available',
  expires_at timestamptz not null,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Pédagogie
-- ============================================================

create table public.lesson_reports (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  idempotency_key text not null,
  content jsonb not null,
  author_profile_id uuid not null references public.profiles(id),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lesson_reports_idempotency_unique unique (idempotency_key)
);

create table public.makharij_findings (
  id uuid primary key default gen_random_uuid(),
  lesson_report_id uuid not null references public.lesson_reports(id) on delete cascade,
  makhraj text not null,
  finding jsonb not null default '{}',
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Finance — schéma seulement (ADR-003), aucune interface
-- ============================================================

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null unique references public.households(id) on delete cascade,
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now()
);

create table public.wallet_entries (
  id bigint generated always as identity primary key,
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  amount_minor bigint not null,          -- entier, jamais de float
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  reference_type text not null check (reference_type in ('credit', 'debit', 'adjustment', 'payout')),
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table public.payout_methods (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,
  details jsonb not null,
  last_modified_at timestamptz not null default now(),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.payouts (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  payout_method_id uuid not null references public.payout_methods(id),
  amount_minor bigint not null,
  status text not null default 'requested' check (status in ('requested', 'paid', 'failed', 'cancelled')),
  created_at timestamptz not null default now()
);

create table public.fx_rates (
  id bigint generated always as identity primary key,
  from_currency text not null check (from_currency ~ '^[A-Z]{3}$'),
  to_currency text not null check (to_currency ~ '^[A-Z]{3}$'),
  rate numeric not null check (rate > 0),
  effective_at timestamptz not null
);

create table public.webhook_events (
  id uuid primary key default gen_random_uuid(),
  external_ref text not null unique,     -- C9: idempotence
  source text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

-- ============================================================
-- Système
-- ============================================================

create table public.audit_logs (
  id bigint generated always as identity,
  actor uuid,
  actor_role text,
  action text not null,
  table_name text not null,
  row_id text,
  payload jsonb not null default '{}',
  prev_hash text not null default '',
  hash text not null,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table public.audit_logs_default partition of public.audit_logs default;
-- ponytail: partition mensuelle gérée par une tâche planifiée (comme la purge 30 j et
-- la détection d'absence). Le défaut absorbe tout tant que les partitions n'existent pas.

create table public.id_sequences (
  code text primary key,
  last_value bigint not null default 0
);

create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

create table public.app_config_history (
  id bigint generated always as identity primary key,
  key text not null,
  old_value jsonb,
  new_value jsonb not null,
  changed_by uuid,
  changed_at timestamptz not null default now()
);

create table public.rate_limits (
  bucket text primary key,
  tokens real not null,
  updated_at timestamptz not null default now()
);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('windows', 'android', 'ios', 'web')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- RLS — activée partout, refus par défaut
-- ============================================================

alter table public.households enable row level security;
alter table public.profiles enable row level security;
alter table public.teacher_profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.kyc_documents enable row level security;
alter table public.devices enable row level security;
alter table public.recurrence_rules enable row level security;
alter table public.availability_slots enable row level security;
alter table public.sessions enable row level security;
alter table public.session_participants enable row level security;
alter table public.session_events enable row level security;
alter table public.session_recordings enable row level security;
alter table public.lesson_reports enable row level security;
alter table public.makharij_findings enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_entries enable row level security;
alter table public.payout_methods enable row level security;
alter table public.payouts enable row level security;
alter table public.fx_rates enable row level security;
alter table public.webhook_events enable row level security;
alter table public.audit_logs enable row level security;
alter table public.id_sequences enable row level security;
alter table public.app_config enable row level security;
alter table public.app_config_history enable row level security;
alter table public.rate_limits enable row level security;
alter table public.device_tokens enable row level security;

-- ============================================================
-- Helpers de rôle (lecture du JWT, jamais de sous-requête sur profiles)
-- ============================================================

create function public.app_role()
returns public.app_role
language sql stable security definer set search_path = ''
as $$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'role', '')::public.app_role;
$$;

create function public.app_household_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'household_id', '')::uuid;
$$;

create function public.app_user_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select auth.uid();
$$;

create function public.app_account_valid()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
      and (p.access_until is null or p.access_until > now())
  );
$$;

-- Ponts inter-tables sûrs pour les policies. Les EXISTS croisés entre sessions,
-- session_participants et profiles bouclent sur eux-mêmes via leurs propres
-- policies RLS (détecté: "infinite recursion detected in policy"). Lecture
-- côté définisseur = une seule traversée, aucune récursion.
-- Elles ne répondent que pour l'uid / le foyer passés (l'appelant fournit son
-- propre identifiant): pas d'oracle de foyer étranger.
create function public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.sessions s
    where s.id = p_session_id and s.teacher_id = p_uid and s.deleted_at is null
  );
$$;

create function public.session_in_household(p_session_id uuid, p_household_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.session_participants sp
    join public.profiles p on p.id = sp.profile_id
    where sp.session_id = p_session_id and sp.deleted_at is null
      and p.household_id = p_household_id and p.deleted_at is null
  );
$$;

create function public.session_has_participant(p_session_id uuid, p_uid uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id and sp.profile_id = p_uid and sp.deleted_at is null
  );
$$;

-- ============================================================
-- Hook de jeton d'accès: role + household injectés dans le JWT
-- ============================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  claims jsonb;
  user_id uuid := (event ->> 'user_id')::uuid;
  v_profile public.profiles;
begin
  select * into v_profile
  from public.profiles
  where public.profiles.id = user_id
    and public.profiles.deleted_at is null;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  if v_profile.id is not null then
    if jsonb_typeof(claims -> 'app_metadata') is null then
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
    end if;
    claims := jsonb_set(claims, '{app_metadata, role}', to_jsonb(v_profile.role::text));
    claims := jsonb_set(claims, '{app_metadata, household_id}', to_jsonb(v_profile.household_id::text));
  end if;

  return jsonb_set(event, '{claims}', claims);
end;
$$;

-- ============================================================
-- Identifiant immuable — attribution atomique
-- ============================================================

create function public.next_immutable_id(role_code public.app_role, initials text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  seq_code text := role_code::text;
  new_value bigint;
begin
  insert into public.id_sequences (code) values (seq_code) on conflict (code) do nothing;

  update public.id_sequences
  set last_value = last_value + 1
  where code = seq_code
  returning last_value into new_value;

  return upper(role_code::text) || '-' || upper(initials) || '-' || lpad(new_value::text, 6, '0');
end;
$$;

-- C1: immuabilité appliquée (pas seulement déclarée).
create function public.guard_profile_immutable_id()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.immutable_id is distinct from new.immutable_id then
    raise exception 'immutable_id ne peut pas être modifié';
  end if;
  return new;
end;
$$;

create trigger profiles_immutable_id_guard
before update on public.profiles
for each row execute function public.guard_profile_immutable_id();

-- Sécurité: seul un admin peut changer rôle/foyer/statut/access_until.
-- Un utilisateur qui s'auto-attribuerait 'admin' recevrait vite le claim via le hook.
create function public.guard_profile_privileged_columns()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin'
     and (old.role is distinct from new.role
          or old.household_id is distinct from new.household_id
          or old.account_status is distinct from new.account_status
          or old.access_until is distinct from new.access_until)
  then
    raise exception 'seul un admin modifie rôle, foyer, statut ou accès';
  end if;
  return new;
end;
$$;

create trigger profiles_privileged_columns_guard
before update on public.profiles
for each row execute function public.guard_profile_privileged_columns();

-- ============================================================
-- Audit — append-only + chaînage de hash
-- ============================================================

-- C6: toute modification/suppression refusée, même avec la clé de service.
create function public.guard_audit_logs_immutable()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'audit_logs est append-only';
end;
$$;

create trigger audit_logs_no_update
before update on public.audit_logs
for each row execute function public.guard_audit_logs_immutable();

create trigger audit_logs_no_delete
before delete on public.audit_logs
for each row execute function public.guard_audit_logs_immutable();

revoke update, delete on public.audit_logs from public, anon, authenticated, service_role;

-- Journalisation d'accès sensible (lecture KYC, écoute d'archive).
-- C6 + chaînage: le hash est calculé ici, dans la fonction serveur, et non par un
-- déclencheur BEFORE: les mutations de NEW faites par un déclencheur BEFORE sur une
-- table partitionnée ne survivent pas au routage vers la partition (comportement
-- PostgreSQL vérifié en 17). audit_logs n'est alimentée que par cette fonction.
-- ponytail: LOCK TABLE sérialise tous les écrits audit (perte de hash identiques en
-- écriture concurrente). Si le débit audit devient un jour un sujet, passer à un
-- verrou par transaction ou un advisory lock ciblé.
create function public.log_sensitive_access(
  p_action text,
  p_table_name text,
  p_row_id text,
  p_payload jsonb default '{}'
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  last_hash text;
  row_digest text;
begin
  lock table public.audit_logs in share row exclusive mode;

  select hash into last_hash
  from public.audit_logs
  order by created_at desc, id desc
  limit 1;
  last_hash := coalesce(last_hash, '');

  row_digest := encode(extensions.digest(
    convert_to(coalesce(auth.uid()::text, '') || coalesce(public.app_role()::text, '') || p_action ||
      p_table_name || coalesce(p_row_id, '') || p_payload::text, 'UTF8'),
    'sha256'), 'hex');

  insert into public.audit_logs (actor, actor_role, action, table_name, row_id, payload, prev_hash, hash)
  values (
    auth.uid(), public.app_role()::text, p_action, p_table_name, p_row_id, p_payload, last_hash,
    encode(extensions.digest(convert_to(last_hash || row_digest, 'UTF8'), 'sha256'), 'hex')
  );
end;
$$;

-- ============================================================
-- Vues d'exposition restreinte (section 5) — seule surface inter-utilisateurs
-- ============================================================

-- session_peers_v: élève — prénom + identifiant immuable des pairs d'une même session.
create view public.session_peers_v
with (security_barrier = true)
as
select distinct
  sp.session_id,
  p2.id as peer_id,
  p2.first_name,
  p2.immutable_id
from public.session_participants sp
join public.session_participants sp2 using (session_id)
join public.profiles p2 on p2.id = sp2.profile_id
where sp.profile_id = auth.uid()
  and sp.deleted_at is null
  and sp2.deleted_at is null
  and p2.deleted_at is null
  and sp2.profile_id <> sp.profile_id;

-- teacher_roster_v: enseignant — prénom, nom, identifiant, niveau, riwaya des élèves de SES sessions.
create view public.teacher_roster_v
with (security_barrier = true)
as
select distinct
  s.id as session_id,
  p.id as student_id,
  p.first_name,
  p.last_name,
  p.immutable_id,
  sp.level,
  sp.riwaya
from public.sessions s
join public.session_participants spart on spart.session_id = s.id
join public.profiles p on p.id = spart.profile_id
join public.student_profiles sp on sp.profile_id = p.id
where s.teacher_id = auth.uid()
  and s.deleted_at is null
  and spart.deleted_at is null
  and p.deleted_at is null;

-- family_sessions_v: tuteur — sessions des enfants du foyer avec statut en direct.
create view public.family_sessions_v
with (security_barrier = true)
as
select
  s.id as session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  p.id as student_id,
  p.first_name,
  p.immutable_id
from public.sessions s
join public.session_participants spart on spart.session_id = s.id
join public.profiles p on p.id = spart.profile_id
where p.household_id = public.app_household_id()
  and s.deleted_at is null
  and spart.deleted_at is null
  and p.deleted_at is null;

-- ============================================================
-- Policies — matrice d'accès section 4, suppression logique filtrée
-- ============================================================

-- households: Admin L E, Comptable L, Tuteur L sien (élever: aucune, cellule "-" de la matrice)
create policy households_admin_all on public.households
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy households_accountant_select on public.households
  for select to authenticated using (public.app_role() = 'accountant' and deleted_at is null);
create policy households_guardian_select on public.households
  for select to authenticated using (public.app_role() = 'guardian' and id = public.app_household_id() and deleted_at is null);

-- profiles: Admin L E, Comptable L partiel, Tuteur L foyer, Élève L soi
create policy profiles_admin_all on public.profiles
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy profiles_self_select on public.profiles
  for select to authenticated using (id = auth.uid() and deleted_at is null);
create policy profiles_family_select on public.profiles
  for select to authenticated using (
    household_id = public.app_household_id() and deleted_at is null
    and public.app_role() in ('guardian', 'accountant', 'controller')
  );
create policy profiles_self_update on public.profiles
  for update to authenticated using (id = auth.uid() and deleted_at is null)
  with check (id = auth.uid());

-- teacher_profiles: Admin L E, enseignant L sa fiche
create policy teacher_profiles_admin_all on public.teacher_profiles
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy teacher_profiles_self on public.teacher_profiles
  for select to authenticated using (profile_id = auth.uid() and deleted_at is null);

-- student_profiles: Admin L E, tuteur L E foyer, élève L soi
create policy student_profiles_admin_all on public.student_profiles
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy student_profiles_family on public.student_profiles
  for select to authenticated using (
    exists (select 1 from public.profiles p where p.id = student_profiles.profile_id
            and p.household_id = public.app_household_id() and p.deleted_at is null)
    and deleted_at is null
  );

-- kyc_documents: Admin L E (filtre genre), Tuteur E foyer.
-- Les lectures passent par la fonction read_kyc_document() qui journalise (scénario 12).
create policy kyc_admin_all on public.kyc_documents
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy kyc_guardian_insert on public.kyc_documents
  for insert to authenticated with check (
    public.app_role() = 'guardian'
    and exists (select 1 from public.profiles p where p.id = kyc_documents.profile_id
                and p.household_id = public.app_household_id() and p.deleted_at is null)
  );

-- Lecture KYC journalisée, avec filtre genre (scénarios 11 et 12).
-- Le genre du lecteur est lu sur SON propre dossier KYC (chaque dossier porte un genre).
create function public.read_kyc_documents()
returns setof public.kyc_documents
language plpgsql security definer set search_path = ''
as $$
declare
  reader_gender public.gender;
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'accès KYC refusé';
  end if;

  select k.gender into reader_gender
  from public.kyc_documents k
  where k.profile_id = auth.uid() and k.deleted_at is null
  limit 1;

  -- Chaque lecture est journalisée (scénario 12) avant retour des lignes.
  perform public.log_sensitive_access('kyc_read', 'kyc_documents', null::text,
    jsonb_build_object('reader_gender', reader_gender));

  -- Scénario 11: un personnel masculin ne lit aucun dossier féminin.
  if reader_gender = 'female' then
    return query
      select k.* from public.kyc_documents k
      where k.deleted_at is null and k.gender = 'female';
  else
    return query
      select k.* from public.kyc_documents k
      where k.deleted_at is null and k.gender = 'male';
  end if;
end;
$$;

-- devices: Admin L E, Tuteur L E foyer, Élève L sien
create policy devices_admin_all on public.devices
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy devices_family on public.devices
  for select to authenticated using (
    exists (select 1 from public.profiles p where p.id = devices.profile_id
            and p.household_id = public.app_household_id() and p.deleted_at is null)
    and deleted_at is null
  );
create policy devices_self on public.devices
  for select to authenticated using (profile_id = auth.uid() and deleted_at is null);

-- C11: deux appareils actifs max par élève (app_config.max_devices_per_student).
create function public.guard_devices_max()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  max_devices int;
begin
  select coalesce(value #>> '{}', '2')::int into max_devices
  from public.app_config where key = 'max_devices_per_student';

  if (select count(*) from public.devices d
      where d.profile_id = new.profile_id and d.revoked_at is null and d.deleted_at is null
     ) >= max_devices then
    raise exception 'plafond d''appareils atteint';
  end if;
  return new;
end;
$$;

create trigger devices_cap
before insert on public.devices
for each row execute function public.guard_devices_max();

-- ============================================================
-- Planning: overlaps et plafond de participants
-- ============================================================

-- C2: un même profil ne peut pas participer à deux sessions qui se recoupent.
create function public.guard_session_overlap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.session_participants sp
    join public.sessions s1 on s1.id = sp.session_id
    join public.sessions s2 on s2.id = new.session_id
    where sp.profile_id = new.profile_id
      and sp.deleted_at is null
      and s1.deleted_at is null and s2.deleted_at is null
      and s1.status in ('planned', 'preflight', 'in_progress')
      and tstzrange(s1.started_at, s1.ended_at, '[]') && tstzrange(s2.started_at, s2.ended_at, '[]')
      and s1.id <> s2.id
  ) then
    raise exception 'chevauchement de sessions pour le même profil';
  end if;
  return new;
end;
$$;

create trigger session_participants_overlap
before insert or update of session_id, profile_id on public.session_participants
for each row execute function public.guard_session_overlap();

-- C3: plafond de participants selon app_config (lecture au moment de l'insert).
create function public.guard_session_participant_cap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  allow_multi boolean;
  max_participants int;
  current_count int;
begin
  select (value)::boolean into allow_multi
  from public.app_config where key = 'allow_multi_participant_sessions';
  if allow_multi is null then allow_multi := false; end if;

  select coalesce(value #>> '{}', '2')::int into max_participants
  from public.app_config where key = 'max_participants_per_session';
  if max_participants is null then max_participants := 2; end if;

  if not allow_multi then
    select count(*) into current_count
    from public.session_participants
    where session_id = new.session_id and deleted_at is null;
    if current_count >= max_participants then
      raise exception 'plafond de participants atteint';
    end if;
  end if;
  return new;
end;
$$;

create trigger session_participants_cap
before insert on public.session_participants
for each row execute function public.guard_session_participant_cap();

-- ============================================================
-- Machine à états des sessions (section 7) — appliquée en base
-- ============================================================

create function public.guard_session_state_transition()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.status = new.status then
    return new;
  end if;
  if not (
    (old.status = 'planned' and new.status in ('preflight', 'teacher_absent', 'student_absent', 'canceled_late', 'canceled')) or
    (old.status = 'preflight' and new.status in ('in_progress', 'teacher_absent', 'student_absent')) or
    (old.status = 'in_progress' and new.status in ('ended', 'tech_failure'))
  ) then
    raise exception 'transition de session non autorisée: % -> %', old.status::text, new.status::text;
  end if;
  return new;
end;
$$;

create trigger sessions_state_machine
before update of status on public.sessions
for each row execute function public.guard_session_state_transition();

-- ============================================================
-- Écriture d'événement de présence (webhook vérifié côté Edge, jamais côté client)
-- ============================================================

create function public.record_session_event(
  p_session_id uuid,
  p_profile_id uuid,
  p_event_type public.session_event_type,
  p_source text default 'livekit_webhook'
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.session_events (session_id, profile_id, event_type, source)
  values (p_session_id, p_profile_id, p_event_type, p_source);
end;
$$;

-- ============================================================
-- app_config — configuration administrable (section 8)
-- ============================================================

create function public.get_config(p_key text, p_default jsonb default null)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce((select value from public.app_config where key = p_key), p_default);
$$;

-- Journal de modification app_config (ancienne valeur + opérateur).
create function public.guard_app_config_history()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.value is distinct from new.value then
    insert into public.app_config_history (key, old_value, new_value, changed_by)
    values (new.key, old.value, new.value, coalesce(new.updated_by, auth.uid()));
  end if;
  return new;
end;
$$;

create trigger app_config_history
before update on public.app_config
for each row execute function public.guard_app_config_history();

insert into public.app_config (key, value) values
  ('allow_multi_participant_sessions', 'false'::jsonb),
  ('max_participants_per_session', '2'::jsonb),
  ('camera_auto_allow_min_age', '11'::jsonb),
  ('child_ui_mode_max_age', '8'::jsonb),            -- à trancher (étape 3)
  ('absence_threshold_minutes', '5'::jsonb),
  ('recording_retention_days', '30'::jsonb),
  ('video_active_provider', '"livekit_cloud"'::jsonb),
  ('video_ws_url_override', '""'::jsonb),
  ('video_canary_percentage', '0'::jsonb),
  ('max_devices_per_student', '2'::jsonb),
  ('max_concurrent_sessions_per_profile', '1'::jsonb);

-- app_config: Admin L E seulement
create policy app_config_admin_read on public.app_config
  for select to authenticated using (public.app_role() = 'admin');
create policy app_config_admin_write on public.app_config
  for insert to authenticated with check (public.app_role() = 'admin');
create policy app_config_admin_update on public.app_config
  for update to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

create policy app_config_history_admin on public.app_config_history
  for select to authenticated using (public.app_role() = 'admin');

-- ============================================================
-- Policies restantes — modes lecture représentés par la matrice
-- ============================================================

-- sessions: Admin L E, Comptable L, Contrôleur L, Enseignant L E siennes,
--           Tuteur L foyer, Élève L siennes. Rien sans compte actif.
create policy sessions_admin_all on public.sessions
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy sessions_read_privileged on public.sessions
  for select to authenticated using (
    public.app_account_valid() and public.app_role() in ('accountant', 'controller')
    and deleted_at is null
  );
create policy sessions_teacher_read on public.sessions
  for select to authenticated using (
    public.app_account_valid() and teacher_id = auth.uid() and deleted_at is null
  );
create policy sessions_teacher_insert on public.sessions
  for insert to authenticated with check (
    public.app_account_valid() and teacher_id = auth.uid()
  );
create policy sessions_family_read on public.sessions
  for select to authenticated using (
    public.app_account_valid()
    and public.session_in_household(sessions.id, public.app_household_id())
    and deleted_at is null
  );
create policy sessions_self_read on public.sessions
  for select to authenticated using (
    public.app_account_valid()
    and public.session_has_participant(sessions.id, auth.uid())
    and deleted_at is null
  );

-- session_participants: Admin L E, Contrôleur L, Enseignant L siennes,
--                       Tuteur L foyer, Élève L via vue session_peers_v.
create policy session_participants_admin_all on public.session_participants
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy session_participants_controller_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'controller' and deleted_at is null
  );
create policy session_participants_teacher_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'teacher' and deleted_at is null
    and public.session_belongs_to_teacher(session_participants.session_id, auth.uid())
  );
create policy session_participants_family_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'guardian' and deleted_at is null
    and exists (select 1 from public.profiles p where p.id = session_participants.profile_id
                and p.household_id = public.app_household_id() and p.deleted_at is null)
  );

-- session_events: Admin L, Contrôleur L, Enseignant L siennes, Tuteur L foyer.
create policy session_events_admin_controller_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() in ('admin', 'controller')
  );
create policy session_events_teacher_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'teacher' and
    public.session_belongs_to_teacher(session_events.session_id, auth.uid())
  );
create policy session_events_family_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'guardian' and
    public.session_in_household(session_events.session_id, public.app_household_id())
  );

create policy session_recordings_admin_controller on public.session_recordings
  for select to authenticated using (
    public.app_account_valid() and public.app_role() in ('admin', 'controller') and deleted_at is null
  );
create policy session_recordings_teacher_family on public.session_recordings
  for select to authenticated using (
    public.app_account_valid() and deleted_at is null and (
      public.session_belongs_to_teacher(session_recordings.session_id, auth.uid())
      or public.session_in_household(session_recordings.session_id, public.app_household_id())
    )
  );

-- lesson_reports: Admin L, Contrôleur L, Enseignant L E siens, Tuteur L foyer, Élève L le concernant.
create policy lesson_reports_admin_all on public.lesson_reports
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy lesson_reports_teacher_write on public.lesson_reports
  for all to authenticated using (
    author_profile_id = auth.uid() and deleted_at is null
  ) with check (
    public.app_role() = 'teacher' and author_profile_id = auth.uid()
  );
create policy lesson_reports_reader on public.lesson_reports
  for select to authenticated using (
    public.app_account_valid() and deleted_at is null and (
      public.app_role() = 'controller'
      or (public.app_role() = 'teacher' and author_profile_id = auth.uid())
      or public.session_in_household(lesson_reports.session_id, public.app_household_id())
      or public.session_has_participant(lesson_reports.session_id, auth.uid())
    )
  );

create policy makharij_findings_read on public.makharij_findings
  for select to authenticated using (
    deleted_at is null and exists (
      select 1 from public.lesson_reports lr
      where lr.id = makharij_findings.lesson_report_id and lr.deleted_at is null
        and (lr.author_profile_id = auth.uid()
             or public.session_in_household(lr.session_id, public.app_household_id())
             or public.session_has_participant(lr.session_id, auth.uid()))
    )
  );
create policy makharij_findings_author_write on public.makharij_findings
  for all to authenticated using (
    exists (select 1 from public.lesson_reports lr
            where lr.id = makharij_findings.lesson_report_id and lr.author_profile_id = auth.uid())
  ) with check (
    exists (select 1 from public.lesson_reports lr
            where lr.id = makharij_findings.lesson_report_id and lr.author_profile_id = auth.uid())
  );

-- Finance: Admin L E, Comptable L E, Enseignant L sien, Tuteur L foyer.
create policy wallets_admin_accountant_all on public.wallets
  for all to authenticated using (public.app_role() in ('admin', 'accountant'))
  with check (public.app_role() in ('admin', 'accountant'));
create policy wallets_family_read on public.wallets
  for select to authenticated using (
    household_id = public.app_household_id() and public.app_account_valid()
  );

create policy wallet_entries_admin_accountant_all on public.wallet_entries
  for all to authenticated using (public.app_role() in ('admin', 'accountant'))
  with check (public.app_role() in ('admin', 'accountant'));
create policy wallet_entries_family_read on public.wallet_entries
  for select to authenticated using (
    public.app_account_valid() and exists (
      select 1 from public.wallets w where w.id = wallet_entries.wallet_id
        and w.household_id = public.app_household_id()
    )
  );

create policy payout_methods_admin_accountant_all on public.payout_methods
  for all to authenticated using (public.app_role() in ('admin', 'accountant'))
  with check (public.app_role() in ('admin', 'accountant'));
create policy payout_methods_family_read on public.payout_methods
  for select to authenticated using (
    public.app_account_valid() and exists (
      select 1 from public.profiles p where p.id = payout_methods.profile_id
        and p.household_id = public.app_household_id() and p.deleted_at is null
    )
  );

create policy payouts_admin_accountant_all on public.payouts
  for all to authenticated using (public.app_role() in ('admin', 'accountant'))
  with check (public.app_role() in ('admin', 'accountant'));
create policy payouts_family_read on public.payouts
  for select to authenticated using (
    public.app_account_valid() and exists (
      select 1 from public.wallets w where w.id = payouts.wallet_id
        and w.household_id = public.app_household_id()
    )
  );

create policy fx_rates_admin_accountant_read on public.fx_rates
  for select to authenticated using (public.app_role() in ('admin', 'accountant'));

-- webhook_events: aucune lecture client (idempotence interne).
create policy webhook_events_admin_read on public.webhook_events
  for select to authenticated using (public.app_role() = 'admin');

-- audit_logs: Admin L, Contrôleur L.
create policy audit_logs_read on public.audit_logs
  for select to authenticated using (
    public.app_role() in ('admin', 'controller')
  );

-- availability_slots / recurrence_rules: Admin L E, Contrôleur L, Enseignant L E siens, Tuteur L.
create policy availability_slots_admin_all on public.availability_slots
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy availability_slots_teacher_all on public.availability_slots
  for all to authenticated using (
    public.app_account_valid() and teacher_id = auth.uid() and deleted_at is null
  ) with check (
    teacher_id = auth.uid()
  );
create policy availability_slots_reader on public.availability_slots
  for select to authenticated using (
    public.app_account_valid() and deleted_at is null
    and public.app_role() in ('controller', 'teacher', 'guardian')
  );

create policy recurrence_rules_admin_all on public.recurrence_rules
  for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy recurrence_rules_teacher_read on public.recurrence_rules
  for select to authenticated using (deleted_at is null and public.app_account_valid());

-- ============================================================
-- Revocations de privilèges — refus par défaut hors grants explicites
-- ============================================================

-- Determinisme: quel que soit auto_expose_new_tables du projet, anon ne touche
-- à rien (aucune policy anon => RLS refuse toute ligne), authenticated reçoit
-- explicitement les privilèges de commande dont ses policies ont besoin.
-- Le vrai cloisonnement reste les policies: une table sans policy rend tout vide.

revoke all on table public.profiles, public.households, public.teacher_profiles,
  public.student_profiles, public.kyc_documents, public.devices,
  public.recurrence_rules, public.availability_slots, public.sessions,
  public.session_participants, public.session_events, public.session_recordings,
  public.lesson_reports, public.makharij_findings, public.wallets,
  public.wallet_entries, public.payout_methods, public.payouts, public.fx_rates,
  public.webhook_events, public.audit_logs, public.id_sequences, public.app_config,
  public.app_config_history, public.rate_limits, public.device_tokens
  from anon;

revoke all on public.session_peers_v, public.teacher_roster_v, public.family_sessions_v
  from anon;

grant select on public.session_peers_v, public.teacher_roster_v, public.family_sessions_v
  to authenticated;

-- Commandes permises aux policies authenticated (l'exposition ligne par ligne
-- reste entièrement gouvernée par les policies RLS ci-dessus).
grant select, insert, update, delete on all tables in schema public to authenticated;

revoke execute on function public.custom_access_token_hook
  from anon, authenticated, public;

grant execute on function public.custom_access_token_hook
  to supabase_auth_admin;

revoke execute on function public.next_immutable_id, public.record_session_event,
  public.log_sensitive_access, public.read_kyc_documents
  from anon, public;

grant execute on function public.next_immutable_id, public.record_session_event
  to service_role;

grant execute on function public.log_sensitive_access, public.read_kyc_documents
  to authenticated;

-- app_config est admin-only (matrice §4) : get_config n'est jamais un point de
-- lecture client. Seul le backend service_role la lit (jamais anon ni authenticated).
revoke execute on function public.get_config from anon, authenticated, public;
grant execute on function public.get_config to service_role;

-- Ponts inter-tables: invoqués par les policies en tant que authenticated.
-- Défenser-read = jamais accessibles à anon.
revoke execute on function public.session_belongs_to_teacher, public.session_in_household,
  public.session_has_participant
  from anon, public;
grant execute on function public.session_belongs_to_teacher, public.session_in_household,
  public.session_has_participant
  to authenticated, service_role;

grant execute on function public.app_role, public.app_household_id, public.app_user_id,
  public.app_account_valid
  to authenticated, anon;

-- helper app_role/app_household_id sont security definer; personne ne doit les exécuter en tant qu'owner malhonnête
-- puisque postgres est owner, le définisseur est postgres: privilège minimal visé par construction (les helpers
-- ne lisent que les claims du JWT via auth.*, impossible à détourner depuis un autre rôle).

-- ============================================================
-- Index attendus (C7, C8)
-- ============================================================

-- C7: index partiels sur les sessions à venir, par enseignant et participant.
create index sessions_upcoming_teacher_ix on public.sessions (teacher_id)
  where status in ('planned', 'preflight') and deleted_at is null;
create index sessions_upcoming_participant_ix on public.session_participants (profile_id, session_id)
  where deleted_at is null;

-- C8: index du journal.
create index audit_logs_created_range_ix on public.audit_logs (created_at);
create index audit_logs_actor_ix on public.audit_logs (actor);
create index audit_logs_payload_ix on public.audit_logs using gin (payload);

-- C2 bis: index de chevauchement côté sessions propre (enseignant).
create index sessions_teacher_time_ix on public.sessions (teacher_id, started_at);

-- Fréquents: participants par session, sessions par statut.
create index session_participants_session_ix on public.session_participants (session_id) where deleted_at is null;
create index sessions_status_ix on public.sessions (status) where deleted_at is null;

commit;