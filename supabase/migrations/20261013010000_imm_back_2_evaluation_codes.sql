-- IMM-BACK-2: codes EV-NNNN des evaluations publiees (decision 12/10, IMM-06 a 08, IMM-13).
-- Un code par eleve et par publication, tire au hasard, unique dans la publication,
-- distinct du matricule RA. L'administration choisit l'affichage : code, nom ou les deux.
begin;

create schema if not exists private;

create table public.evaluation_publications (
  id uuid primary key default gen_random_uuid(),
  groupe_id uuid not null references public.groupes(id) on delete cascade,
  titre text not null check (btrim(titre) <> ''),
  affichage text not null default 'code' check (affichage in ('code', 'nom', 'les_deux')),
  published_by uuid references public.profiles(id) on delete set null,
  published_at timestamptz not null default now()
);
create index evaluation_publications_groupe_idx
  on public.evaluation_publications (groupe_id, published_at desc);

comment on table public.evaluation_publications is
  'Une evaluation publiee pour un groupe. Aucune ecriture directe : seules les fonctions de cette migration ecrivent ici.';

alter table public.evaluation_publications enable row level security;
revoke all on public.evaluation_publications from anon, service_role;
revoke insert, update, delete on public.evaluation_publications from public, authenticated;
grant select on public.evaluation_publications to authenticated;

create policy evaluation_publications_lecture on public.evaluation_publications
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

create table private.evaluation_codes (
  publication_id uuid not null references public.evaluation_publications(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  code text not null check (code ~ '^EV-[0-9]{4}$'),
  issued_at timestamptz not null default now(),
  primary key (publication_id, student_id),
  constraint evaluation_codes_unique_in_publication unique (publication_id, code)
);
alter table private.evaluation_codes enable row level security;
revoke all on private.evaluation_codes from public, anon, authenticated, service_role;

comment on table private.evaluation_codes is
  'Codes EV-NNNN : un par eleve et par publication, tires au hasard, uniques dans la publication, distincts du matricule RA.';

create or replace function private.tirer_nombre_evaluation()
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_random bytea;
begin
  v_random := extensions.gen_random_bytes(4);
  return pg_catalog.mod(
    pg_catalog.get_byte(v_random, 0)::bigint * 16777216
    + pg_catalog.get_byte(v_random, 1)::bigint * 65536
    + pg_catalog.get_byte(v_random, 2)::bigint * 256
    + pg_catalog.get_byte(v_random, 3)::bigint,
    10000
  )::integer;
end;
$function$;

alter function private.tirer_nombre_evaluation() owner to postgres;
revoke all on function private.tirer_nombre_evaluation() from public, anon, authenticated, service_role;
comment on function private.tirer_nombre_evaluation() is
  'F86 candidate allowlist: signature=private.tirer_nombre_evaluation(); md5_functiondef=08e1a193ca9d87e7640bdf81d2d08ebd; guard_type=SERVER_INTERNAL; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

create or replace function private.attribuer_codes_evaluation(
  p_publication_id uuid,
  p_groupe_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_student uuid;
  v_attempt integer;
  v_code text;
  v_count integer := 0;
begin
  if p_publication_id is null or p_groupe_id is null then
    raise exception 'EvaluationCodesParametresInvalides' using errcode = '22023';
  end if;

  for v_student in
    select m.student_id
      from public.groupe_membres m
      join public.profiles p on p.id = m.student_id
     where m.groupe_id = p_groupe_id
       and m.left_at is null
       and p.deleted_at is null
     order by m.student_id
  loop
    for v_attempt in 1..1000 loop
      v_code := 'EV-' || pg_catalog.lpad(private.tirer_nombre_evaluation()::text, 4, '0');
      begin
        insert into private.evaluation_codes (publication_id, student_id, code)
        values (p_publication_id, v_student, v_code);
        v_count := v_count + 1;
        exit;
      exception when unique_violation then
        if v_attempt = 1000 then
          raise exception 'EvaluationCodesTiragesEpuises' using errcode = '54000';
        end if;
      end;
    end loop;
  end loop;
  return v_count;
end;
$function$;

alter function private.attribuer_codes_evaluation(uuid, uuid) owner to postgres;
revoke all on function private.attribuer_codes_evaluation(uuid, uuid)
  from public, anon, authenticated, service_role;
comment on function private.attribuer_codes_evaluation(uuid, uuid) is
  'F86 candidate allowlist: signature=private.attribuer_codes_evaluation(uuid,uuid); md5_functiondef=7864e850281a9d967d29aa6482cf1c19; guard_type=SERVER_INTERNAL; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

create or replace function public.publier_evaluation(
  p_groupe_id uuid,
  p_titre text,
  p_affichage text default 'code'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_id uuid;
  v_count integer;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication d''une evaluation reservee a l''administration';
  end if;
  if coalesce(btrim(p_titre), '') = '' then
    raise exception 'un titre est requis pour publier une evaluation';
  end if;
  if p_affichage is null or p_affichage not in ('code', 'nom', 'les_deux') then
    raise exception 'affichage invalide : code, nom ou les_deux';
  end if;
  if not exists (
    select 1 from public.groupes g where g.id = p_groupe_id and g.ended_at is null
  ) then
    raise exception 'ce groupe n''existe pas ou est cloture';
  end if;
  if not exists (
    select 1 from public.groupe_membres m
     where m.groupe_id = p_groupe_id and m.left_at is null
  ) then
    raise exception 'ce groupe n''a aucun eleve actif';
  end if;

  insert into public.evaluation_publications (groupe_id, titre, affichage, published_by)
  values (p_groupe_id, btrim(p_titre), p_affichage, auth.uid())
  returning id into v_id;

  v_count := private.attribuer_codes_evaluation(v_id, p_groupe_id);

  perform public.log_sensitive_access(
    'evaluation_publiee', 'evaluation_publications', v_id::text,
    jsonb_build_object('groupe_id', p_groupe_id, 'affichage', p_affichage, 'eleves', v_count)
  );
  return v_id;
end;
$function$;

create or replace function public.changer_affichage_evaluation(
  p_publication_id uuid,
  p_affichage text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'choix de l''affichage reserve a l''administration';
  end if;
  if p_affichage is null or p_affichage not in ('code', 'nom', 'les_deux') then
    raise exception 'affichage invalide : code, nom ou les_deux';
  end if;

  update public.evaluation_publications
     set affichage = p_affichage
   where id = p_publication_id;
  if not found then
    raise exception 'publication introuvable';
  end if;

  perform public.log_sensitive_access(
    'evaluation_affichage_change', 'evaluation_publications', p_publication_id::text,
    jsonb_build_object('affichage', p_affichage)
  );
end;
$function$;

-- Administration : toutes les lignes, filtrees par l'affichage choisi.
-- Eleve ou tuteur : uniquement ses propres codes (le sien, ou ceux de son foyer).
create or replace function public.evaluation_publiee_lignes(p_publication_id uuid)
returns table (
  student_id uuid,
  code text,
  first_name text,
  last_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_affichage text;
begin
  if auth.uid() is null or not coalesce(public.app_account_valid(), false) then
    return;
  end if;

  select e.affichage into v_affichage
    from public.evaluation_publications e where e.id = p_publication_id;
  if v_affichage is null then
    return;
  end if;

  if coalesce(public.app_role() = 'admin', false) then
    return query
      select c.student_id,
             case when v_affichage in ('code', 'les_deux') then c.code end,
             case when v_affichage in ('nom', 'les_deux')
                   and not public.agent_identite_masquee() then p.first_name end,
             case when v_affichage in ('nom', 'les_deux')
                   and not public.agent_identite_masquee() then p.last_name end
        from private.evaluation_codes c
        join public.profiles p on p.id = c.student_id
       where c.publication_id = p_publication_id
       order by c.code;
    return;
  end if;

  return query
    select c.student_id, c.code, null::text, null::text
      from private.evaluation_codes c
      join public.profiles p on p.id = c.student_id
     where c.publication_id = p_publication_id
       and (c.student_id = auth.uid()
            or (public.app_role() = 'guardian'
                and p.household_id is not null
                and p.household_id = public.app_household_id()))
     order by c.code;
end;
$function$;

alter function public.publier_evaluation(uuid, text, text) owner to postgres;
alter function public.changer_affichage_evaluation(uuid, text) owner to postgres;
alter function public.evaluation_publiee_lignes(uuid) owner to postgres;
revoke all on function public.publier_evaluation(uuid, text, text)
  from public, anon, service_role;
revoke all on function public.changer_affichage_evaluation(uuid, text)
  from public, anon, service_role;
revoke all on function public.evaluation_publiee_lignes(uuid)
  from public, anon, service_role;
grant execute on function public.publier_evaluation(uuid, text, text) to authenticated;
grant execute on function public.changer_affichage_evaluation(uuid, text) to authenticated;
grant execute on function public.evaluation_publiee_lignes(uuid) to authenticated;

comment on function public.publier_evaluation(uuid, text, text) is
  'F86 candidate allowlist: signature=public.publier_evaluation(uuid,text,text); md5_functiondef=3a753d1fd6d8a8424f345d2e87257bfe; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';
comment on function public.changer_affichage_evaluation(uuid, text) is
  'F86 candidate allowlist: signature=public.changer_affichage_evaluation(uuid,text); md5_functiondef=61bb4cf1f07cd5c59ea2cbd74e71d2f9; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';
comment on function public.evaluation_publiee_lignes(uuid) is
  'F86 candidate allowlist: signature=public.evaluation_publiee_lignes(uuid); md5_functiondef=26b2835900121de46bc3a45f9f6b806c; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

-- Postflight : proprietaire, search_path, ACL, et empreinte du commentaire egale
-- a l'empreinte reelle de la definition.
do $postflight$
declare
  v_sig text;
  v_oid pg_catalog.regprocedure;
  v_public boolean;
begin
  foreach v_sig in array array[
    'private.tirer_nombre_evaluation()',
    'private.attribuer_codes_evaluation(uuid,uuid)',
    'public.publier_evaluation(uuid,text,text)',
    'public.changer_affichage_evaluation(uuid,text)',
    'public.evaluation_publiee_lignes(uuid)'
  ] loop
    v_oid := v_sig::pg_catalog.regprocedure;
    v_public := v_sig like 'public.%';
    if not exists (
         select 1 from pg_catalog.pg_proc p
          where p.oid = v_oid::oid and p.prosecdef
            and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
            and coalesce(p.proconfig @> array['search_path=""'], false)
            and pg_catalog.strpos(
                  pg_catalog.obj_description(p.oid, 'pg_proc'),
                  'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || ';'
                ) > 0
       )
       or pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       or pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       or pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') is distinct from v_public then
      raise exception 'F86 IMM-BACK-2 postflight invalide pour %', v_sig;
    end if;
  end loop;
end
$postflight$;

commit;
