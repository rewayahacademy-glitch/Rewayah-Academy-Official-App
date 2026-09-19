-- 0021 — Diagnostics de placement, lot P-02 du domaine Pedagogie
--
-- Deuxieme lot de la mission « structurer le domaine Pedagogie du panneau
-- admin ». S'appuie sur `programme_niveaux` (migration `0020`) : un eleve est
-- place sur un niveau reel du programme, jamais sur le champ libre
-- `student_profiles.level`.
--
-- `progression_historique` est **append-only** : le niveau courant d'un
-- eleve est sa derniere ligne, jamais une colonne d'etat separee a garder
-- synchronisee -- meme esprit que `groupe_membres.left_at is null` pour
-- « actif » (migration `0017`). Ce choix donne l'historique de progression
-- « gratuitement », et les lots suivants (Progression, Evaluations) y
-- ajoutent leurs propres types de mouvement sans nouvelle table.

-- ============================================================
-- 1. L'historique de progression
-- ============================================================

create table public.progression_historique (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  niveau_id uuid not null references public.programme_niveaux(id),
  type_mouvement text not null check (
    type_mouvement in ('diagnostic_initial', 'promotion', 'reevaluation', 'correction')
  ),
  decide_par uuid not null references public.profiles(id),
  motif text not null check (btrim(motif) <> ''),
  created_at timestamptz not null default now()
);

create index progression_historique_student_idx
  on public.progression_historique (student_id, created_at desc);

comment on table public.progression_historique is
  'Chaque changement de niveau d''un eleve, dans l''ordre. Append-only : le '
  'niveau courant d''un eleve est sa derniere ligne. Aucune policy '
  'd''ecriture directe : seules les fonctions de cette migration ecrivent ici.';

alter table public.progression_historique enable row level security;

revoke all on public.progression_historique from anon;
revoke insert, update, delete on public.progression_historique from public, anon, authenticated;

create policy progression_historique_lecture on public.progression_historique
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 2. Decider un placement (diagnostic initial seulement -- une correction
--    d'un niveau deja decide passe par Progression, pas par Diagnostics)
-- ============================================================

create function public.decider_placement(
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
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'decision de placement reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour decider un placement';
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

  if not exists (select 1 from public.programme_niveaux where id = p_niveau_id) then
    raise exception 'ce niveau de programme n''existe pas';
  end if;

  if exists (select 1 from public.progression_historique where student_id = p_student_id) then
    raise exception 'cet eleve a deja un niveau decide : passez par Progression pour le modifier';
  end if;

  insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
  values (p_student_id, p_niveau_id, 'diagnostic_initial', auth.uid(), p_motif)
  returning id into v_id;

  perform public.log_sensitive_access(
    'placement_decide', 'progression_historique', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'motif', p_motif)
  );

  return v_id;
end;
$function$;

-- ============================================================
-- 3. La lecture pour l'ecran Admin > Pedagogie > Diagnostics
-- ============================================================

create function public.diagnostics_a_traiter()
returns table(
  student_id uuid,
  student_immutable_id text,
  student_prenom text,
  student_nom text,
  inscrit_depuis timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.created_at
  from public.profiles p
  where public.app_role() = 'admin' and public.app_account_valid()
    and p.role = 'student'
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.progression_historique h where h.student_id = p.id
    )
  order by p.created_at asc;
$function$;

comment on function public.diagnostics_a_traiter() is
  'La file des eleves sans niveau decide, pour l''ecran Admin > Pedagogie > '
  'Diagnostics.';

-- ============================================================
-- 4. Les droits -- agent_ro jamais sur decider_placement (ecriture)
-- ============================================================

revoke execute on function public.decider_placement(uuid, uuid, text) from public, anon;
revoke execute on function public.diagnostics_a_traiter() from public, anon;

grant execute on function public.decider_placement(uuid, uuid, text) to authenticated;
grant execute on function public.diagnostics_a_traiter() to authenticated, agent_ro;
