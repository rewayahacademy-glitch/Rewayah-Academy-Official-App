-- 0023 — Evaluations, lot P-04 du domaine Pedagogie
--
-- Quatrieme lot de la mission « structurer le domaine Pedagogie du panneau
-- admin ». Evaluations prevues, resultats, reevaluations et certifications.
--
-- Une **certification est simplement une evaluation reussie de type
-- `certification`** -- pas de table separee : le mot recouvre un type
-- d'evaluation, pas un objet distinct. Une reevaluation, de meme, est une
-- nouvelle ligne `evaluations` de type `reevaluation` sur le meme niveau
-- apres un `echec`, jamais un objet a part.
--
-- Une reussite en `reevaluation` ou `certification` ajoute une ligne a
-- `progression_historique` (migration `0021`) : c'est la meme table
-- d'historique que Diagnostics et Progression, avec un type de mouvement de
-- plus (`reevaluation`), jamais une nouvelle source de verite sur le niveau
-- courant d'un eleve.

-- ============================================================
-- 1. Les evaluations
-- ============================================================

create table public.evaluations (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  niveau_id uuid not null references public.programme_niveaux(id),
  type text not null check (type in ('initiale', 'periodique', 'reevaluation', 'certification')),
  statut text not null default 'planifiee' check (statut in ('planifiee', 'realisee', 'annulee')),
  date_prevue date not null,
  date_realisee date,
  resultat text check (resultat in ('reussi', 'echec', 'a_revoir')),
  evaluateur_id uuid references public.profiles(id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint evaluations_realisation_coherente check (
    (statut = 'planifiee' and date_realisee is null and resultat is null and evaluateur_id is null)
    or (statut = 'realisee' and date_realisee is not null and resultat is not null and evaluateur_id is not null)
    or (statut = 'annulee')
  )
);

create index evaluations_student_idx on public.evaluations (student_id, date_prevue desc);
create index evaluations_planifiees_idx on public.evaluations (date_prevue) where statut = 'planifiee';

comment on table public.evaluations is
  'Une evaluation (initiale, periodique, reevaluation ou certification) '
  'planifiee puis realisee ou annulee pour un eleve, sur un niveau du '
  'programme. Aucune policy d''ecriture directe : seules les fonctions de '
  'cette migration ecrivent ici.';

alter table public.evaluations enable row level security;

revoke all on public.evaluations from anon;
revoke insert, update, delete on public.evaluations from public, anon, authenticated;

create policy evaluations_lecture on public.evaluations
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 2. Planifier, enregistrer un resultat, annuler
-- ============================================================

create function public.planifier_evaluation(
  p_student_id uuid,
  p_niveau_id uuid,
  p_type text,
  p_date_prevue date
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'planification d''une evaluation reservee a l''administration';
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

  insert into public.evaluations (student_id, niveau_id, type, date_prevue)
  values (p_student_id, p_niveau_id, p_type, p_date_prevue)
  returning id into v_id;

  perform public.log_sensitive_access(
    'evaluation_planifiee', 'evaluations', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'type', p_type, 'date_prevue', p_date_prevue)
  );

  return v_id;
end;
$function$;

create function public.enregistrer_resultat_evaluation(
  p_evaluation_id uuid,
  p_resultat text,
  p_notes text default null
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_statut text;
  v_type text;
  v_student_id uuid;
  v_niveau_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'enregistrement d''un resultat reserve a l''administration';
  end if;

  select statut, type, student_id, niveau_id
    into v_statut, v_type, v_student_id, v_niveau_id
  from public.evaluations where id = p_evaluation_id;

  if v_statut is null then
    raise exception 'evaluation introuvable';
  end if;

  if v_statut <> 'planifiee' then
    raise exception 'cette evaluation n''est plus planifiee';
  end if;

  update public.evaluations
  set statut = 'realisee', date_realisee = current_date, resultat = p_resultat,
      evaluateur_id = auth.uid(), notes = p_notes, updated_at = now()
  where id = p_evaluation_id;

  if p_resultat = 'reussi' and v_type in ('reevaluation', 'certification') then
    insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
    values (
      v_student_id, v_niveau_id, 'reevaluation', auth.uid(),
      case v_type
        when 'certification' then 'certification reussie'
        else 'reevaluation reussie'
      end
    );
  end if;

  perform public.log_sensitive_access(
    'resultat_evaluation_enregistre', 'evaluations', p_evaluation_id::text,
    jsonb_build_object('resultat', p_resultat, 'type', v_type)
  );
end;
$function$;

create function public.annuler_evaluation(
  p_evaluation_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'annulation d''une evaluation reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour annuler une evaluation';
  end if;

  update public.evaluations
  set statut = 'annulee', notes = p_motif, updated_at = now()
  where id = p_evaluation_id and statut = 'planifiee';

  if not found then
    raise exception 'evaluation introuvable ou deja realisee/annulee';
  end if;

  perform public.log_sensitive_access(
    'evaluation_annulee', 'evaluations', p_evaluation_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$;

-- ============================================================
-- 3. La lecture pour l'ecran Admin > Pedagogie > Evaluations
-- ============================================================

create function public.evaluations_admin()
returns table(
  evaluation_id uuid,
  student_id uuid,
  student_immutable_id text,
  student_prenom text,
  student_nom text,
  niveau_id uuid,
  niveau_nom_humain text,
  type text,
  statut text,
  date_prevue date,
  date_realisee date,
  resultat text,
  notes text
)
language sql stable security definer set search_path = ''
as $function$
  select
    e.id,
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    n.id,
    n.nom_humain,
    e.type,
    e.statut,
    e.date_prevue,
    e.date_realisee,
    e.resultat,
    e.notes
  from public.evaluations e
  join public.profiles p on p.id = e.student_id
  join public.programme_niveaux n on n.id = e.niveau_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by (e.statut = 'planifiee') desc, e.date_prevue desc;
$function$;

comment on function public.evaluations_admin() is
  'Toutes les evaluations, planifiees d''abord puis les plus recentes, pour '
  'l''ecran Admin > Pedagogie > Evaluations.';

-- ============================================================
-- 4. Les droits -- agent_ro jamais sur les trois ecritures
-- ============================================================

revoke execute on function public.planifier_evaluation(uuid, uuid, text, date) from public, anon;
revoke execute on function public.enregistrer_resultat_evaluation(uuid, text, text) from public, anon;
revoke execute on function public.annuler_evaluation(uuid, text) from public, anon;
revoke execute on function public.evaluations_admin() from public, anon;

grant execute on function public.planifier_evaluation(uuid, uuid, text, date) to authenticated;
grant execute on function public.enregistrer_resultat_evaluation(uuid, text, text) to authenticated;
grant execute on function public.annuler_evaluation(uuid, text) to authenticated;
grant execute on function public.evaluations_admin() to authenticated, agent_ro;
