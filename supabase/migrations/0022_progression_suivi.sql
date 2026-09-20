-- 0022 — Suivi de progression, lot P-03 du domaine Pedagogie
--
-- Troisieme lot de la mission « structurer le domaine Pedagogie du panneau
-- admin ». Vue par groupe, cycle et eleve, avec exceptions et blocages.
--
-- `progression_exceptions` est un catalogue **neuf, distinct** de
-- `rule_overrides`/`matching_requests` (`ADM-06`, migration `0005`) :
-- l'audit d'architecture (`docs/architecture/ADMIN_IA_AUDIT.md`, fiche
-- `ADM-06`) interdit explicitement d'etendre ce dernier avec des cles
-- pedagogiques. `rule_overrides` reste strictement operationnel (duree de
-- seance, pause, plafond eleves/enseignant) ; ceci est pedagogique
-- (blocage, derogation de progression).

-- ============================================================
-- 1. Les exceptions de progression
-- ============================================================

create table public.progression_exceptions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('blocage', 'derogation')),
  motif text not null check (btrim(motif) <> ''),
  cree_par uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  closed_par uuid references public.profiles(id),
  close_motif text,
  constraint progression_exceptions_cloture_complete check (
    (closed_at is null and closed_par is null and close_motif is null)
    or (closed_at is not null and closed_par is not null and coalesce(btrim(close_motif), '') <> '')
  )
);

create index progression_exceptions_student_actives_idx
  on public.progression_exceptions (student_id) where closed_at is null;

comment on table public.progression_exceptions is
  'Un blocage ou une derogation pedagogique pour un eleve. Catalogue distinct '
  'de rule_overrides (ADM-06, strictement operationnel). Aucune policy '
  'd''ecriture directe : seules les fonctions de cette migration ecrivent ici.';

alter table public.progression_exceptions enable row level security;

revoke all on public.progression_exceptions from anon;
revoke insert, update, delete on public.progression_exceptions from public, anon, authenticated;

create policy progression_exceptions_lecture on public.progression_exceptions
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 2. Poser et clore une exception
-- ============================================================

create function public.poser_exception_progression(
  p_student_id uuid,
  p_type text,
  p_motif text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'pose d''une exception de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour poser une exception';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if exists (
    select 1 from public.progression_exceptions
    where student_id = p_student_id and type = p_type and closed_at is null
  ) then
    raise exception 'une exception de ce type est deja active pour cet eleve';
  end if;

  insert into public.progression_exceptions (student_id, type, motif, cree_par)
  values (p_student_id, p_type, p_motif, auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access(
    'exception_progression_posee', 'progression_exceptions', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'type', p_type, 'motif', p_motif)
  );

  return v_id;
end;
$function$;

create function public.clore_exception_progression(
  p_exception_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'cloture d''une exception de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour clore une exception';
  end if;

  update public.progression_exceptions
  set closed_at = now(), closed_par = auth.uid(), close_motif = p_motif
  where id = p_exception_id and closed_at is null;

  if not found then
    raise exception 'exception introuvable ou deja cloturee';
  end if;

  perform public.log_sensitive_access(
    'exception_progression_cloturee', 'progression_exceptions', p_exception_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$;

-- ============================================================
-- 3. Promotion manuelle (hors evaluation)
-- ============================================================

create function public.progression_promouvoir(
  p_student_id uuid,
  p_niveau_id uuid,
  p_motif text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'promotion de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour promouvoir un eleve';
  end if;

  if not exists (
    select 1 from public.progression_historique where student_id = p_student_id
  ) then
    raise exception 'cet eleve n''a encore aucun niveau decide : passez par Diagnostics';
  end if;

  if not exists (select 1 from public.programme_niveaux where id = p_niveau_id) then
    raise exception 'ce niveau de programme n''existe pas';
  end if;

  insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
  values (p_student_id, p_niveau_id, 'promotion', auth.uid(), p_motif)
  returning id into v_id;

  perform public.log_sensitive_access(
    'progression_promue', 'progression_historique', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'motif', p_motif)
  );

  return v_id;
end;
$function$;

-- ============================================================
-- 4. La lecture pour l'ecran Admin > Pedagogie > Progression
-- ============================================================

create function public.progression_admin()
returns table(
  student_id uuid,
  student_immutable_id text,
  student_prenom text,
  student_nom text,
  groupe_id uuid,
  groupe_libelle text,
  niveau_id uuid,
  niveau_nom_humain text,
  niveau_cycle text,
  niveau_depuis timestamptz,
  exception_active_id uuid,
  exception_active_type text
)
language sql stable security definer set search_path = ''
as $function$
  with dernier_mouvement as (
    select distinct on (h.student_id)
      h.student_id, h.niveau_id, h.created_at
    from public.progression_historique h
    order by h.student_id, h.created_at desc
  ),
  exception_active as (
    select distinct on (e.student_id)
      e.student_id, e.id, e.type
    from public.progression_exceptions e
    where e.closed_at is null
    order by e.student_id, e.created_at desc
  )
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    g.id,
    g.libelle,
    n.id,
    n.nom_humain,
    n.cycle,
    dm.created_at,
    xa.id,
    xa.type
  from public.profiles p
  left join dernier_mouvement dm on dm.student_id = p.id
  left join public.programme_niveaux n on n.id = dm.niveau_id
  left join public.groupe_membres m on m.student_id = p.id and m.left_at is null
  left join public.groupes g on g.id = m.groupe_id
  left join exception_active xa on xa.student_id = p.id
  where public.app_role() = 'admin' and public.app_account_valid()
    and p.role = 'student'
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
  order by g.libelle nulls last, p.created_at asc;
$function$;

comment on function public.progression_admin() is
  'Chaque eleve actif, son groupe, son niveau courant et son exception '
  'active le cas echeant, pour l''ecran Admin > Pedagogie > Progression.';

-- ============================================================
-- 5. Les droits -- agent_ro jamais sur les trois ecritures
-- ============================================================

revoke execute on function public.poser_exception_progression(uuid, text, text) from public, anon;
revoke execute on function public.clore_exception_progression(uuid, text) from public, anon;
revoke execute on function public.progression_promouvoir(uuid, uuid, text) from public, anon;
revoke execute on function public.progression_admin() from public, anon;

grant execute on function public.poser_exception_progression(uuid, text, text) to authenticated;
grant execute on function public.clore_exception_progression(uuid, text) to authenticated;
grant execute on function public.progression_promouvoir(uuid, uuid, text) to authenticated;
grant execute on function public.progression_admin() to authenticated, agent_ro;
