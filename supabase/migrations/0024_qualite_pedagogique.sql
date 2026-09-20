-- 0024 — Qualite pedagogique, lot P-05 (dernier) du domaine Pedagogie
--
-- Cinquieme et dernier lot de la mission « structurer le domaine Pedagogie
-- du panneau admin ». Anomalies pedagogiques, controles, coherence des
-- evaluations et suivi enseignant.
--
-- `anomalies_qualite()` est **calculee, jamais stockee** : elle recoupe des
-- tables deja existantes (`sessions`/`lesson_reports`, migration `0001` ;
-- `progression_exceptions`, migration `0022` ; `evaluations`, migration
-- `0023`) sans rien dupliquer. Le premier type -- rapport manquant --
-- raccorde enfin le compteur « rapports manquants » d'`ADM-01`, present
-- depuis le tout debut mais jamais consomme par aucun ecran
-- (`docs/architecture/ADMIN_IA_AUDIT.md`, ligne 134). Le suivi enseignant
-- (mission) est un agregat cote client des memes rapports manquants, par
-- `sessions.teacher_id` -- aucun quatrieme type d'anomalie necessaire.
--
-- `controles_qualite` est la seule table neuve : elle retient qu'une
-- anomalie a ete revue, pour ne pas la faire reapparaitre indefiniment comme
-- neuve sans etat.

-- ============================================================
-- 1. Les controles (une anomalie marquee traitee)
-- ============================================================

create table public.controles_qualite (
  id uuid primary key default gen_random_uuid(),
  type_anomalie text not null check (
    type_anomalie in ('rapport_manquant', 'blocage_sans_suivi', 'evaluation_en_retard')
  ),
  ref_table text not null,
  ref_id uuid not null,
  statut text not null default 'ouvert' check (statut in ('ouvert', 'traite')),
  traite_par uuid references public.profiles(id),
  traite_at timestamptz,
  note text,
  created_at timestamptz not null default now(),
  constraint controles_qualite_unique unique (type_anomalie, ref_id),
  constraint controles_qualite_traitement_complet check (
    (statut = 'ouvert' and traite_par is null and traite_at is null)
    or (statut = 'traite' and traite_par is not null and traite_at is not null)
  )
);

comment on table public.controles_qualite is
  'Marque qu''une anomalie pedagogique detectee a ete revue. Aucune policy '
  'd''ecriture directe : seule la fonction de cette migration ecrit ici.';

alter table public.controles_qualite enable row level security;

revoke all on public.controles_qualite from anon;
revoke insert, update, delete on public.controles_qualite from public, anon, authenticated;

create policy controles_qualite_lecture on public.controles_qualite
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 2. Marquer une anomalie traitee (upsert : re-traiter met a jour la note)
-- ============================================================

create function public.traiter_anomalie_qualite(
  p_type_anomalie text,
  p_ref_id uuid,
  p_note text default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_table text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'traitement d''une anomalie qualite reserve a l''administration';
  end if;

  v_table := case p_type_anomalie
    when 'rapport_manquant' then 'sessions'
    when 'blocage_sans_suivi' then 'progression_exceptions'
    when 'evaluation_en_retard' then 'evaluations'
    else null
  end;

  if v_table is null then
    raise exception 'type d''anomalie inconnu : %', p_type_anomalie;
  end if;

  insert into public.controles_qualite (type_anomalie, ref_table, ref_id, statut, traite_par, traite_at, note)
  values (p_type_anomalie, v_table, p_ref_id, 'traite', auth.uid(), now(), p_note)
  on conflict (type_anomalie, ref_id) do update
    set statut = 'traite', traite_par = excluded.traite_par, traite_at = excluded.traite_at, note = excluded.note
  returning id into v_id;

  perform public.log_sensitive_access(
    'anomalie_qualite_traitee', 'controles_qualite', v_id::text,
    jsonb_build_object('type_anomalie', p_type_anomalie, 'ref_id', p_ref_id, 'note', p_note)
  );

  return v_id;
end;
$function$;

-- ============================================================
-- 3. La lecture pour l'ecran Admin > Pedagogie > Qualite
-- ============================================================

create function public.anomalies_qualite()
returns table(
  type_anomalie text,
  ref_id uuid,
  student_id uuid,
  student_prenom text,
  student_nom text,
  teacher_id uuid,
  teacher_prenom text,
  teacher_nom text,
  depuis timestamptz,
  controle_statut text,
  controle_note text
)
language sql stable security definer set search_path = ''
as $function$
  with brutes as (
    -- 1. Rapport manquant : seance tenue ('ended'), aucun lesson_report.
    select
      'rapport_manquant'::text as type_anomalie,
      s.id as ref_id,
      null::uuid as student_id,
      s.teacher_id as teacher_id,
      s.started_at as depuis
    from public.sessions s
    where s.status = 'ended'
      and s.deleted_at is null
      and not exists (
        select 1 from public.lesson_reports lr
        where lr.session_id = s.id and lr.deleted_at is null
      )

    union all

    -- 2. Blocage actif depuis plus de 7 jours sans cloture.
    select
      'blocage_sans_suivi'::text,
      e.id,
      e.student_id,
      null::uuid,
      e.created_at
    from public.progression_exceptions e
    where e.type = 'blocage'
      and e.closed_at is null
      and e.created_at < now() - interval '7 days'

    union all

    -- 3. Evaluation encore planifiee alors que sa date prevue est passee.
    select
      'evaluation_en_retard'::text,
      ev.id,
      ev.student_id,
      null::uuid,
      ev.date_prevue::timestamptz
    from public.evaluations ev
    where ev.statut = 'planifiee'
      and ev.date_prevue < current_date
  )
  select
    b.type_anomalie,
    b.ref_id,
    sp.id,
    case when public.agent_identite_masquee() then null else sp.first_name end,
    case when public.agent_identite_masquee() then null else sp.last_name end,
    tp.id,
    case when public.agent_identite_masquee() then null else tp.first_name end,
    case when public.agent_identite_masquee() then null else tp.last_name end,
    b.depuis,
    coalesce(c.statut, 'ouvert'),
    c.note
  from brutes b
  left join public.profiles sp on sp.id = b.student_id
  left join public.profiles tp on tp.id = b.teacher_id
  left join public.controles_qualite c on c.type_anomalie = b.type_anomalie and c.ref_id = b.ref_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by b.depuis asc;
$function$;

comment on function public.anomalies_qualite() is
  'Les anomalies pedagogiques calculees (rapports manquants, blocages sans '
  'suivi, evaluations en retard), pour l''ecran Admin > Pedagogie > Qualite.';

-- ============================================================
-- 4. Les droits -- agent_ro jamais sur l'ecriture
-- ============================================================

revoke execute on function public.traiter_anomalie_qualite(text, uuid, text) from public, anon;
revoke execute on function public.anomalies_qualite() from public, anon;

grant execute on function public.traiter_anomalie_qualite(text, uuid, text) to authenticated;
grant execute on function public.anomalies_qualite() to authenticated, agent_ro;
