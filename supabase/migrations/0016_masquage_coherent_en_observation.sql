-- 0016 — Le masquage des identites vaut pour TOUTES les lectures de
-- l'administration, pas seulement pour celles ou on y a pense.
--
-- Constate a l'ecran le 18 septembre 2026, en mode observation, avec la
-- banniere « Observation, lecture seule . Prenoms masques » affichee en haut
-- de l'ecran : `ADM-08` rendait bien « TEACHER-AS-000001 », mais `ADM-02`
-- affichait « Abdallah Sow » en titre de fiche et le tableau de bord
-- « Dossier d'identite de Abdallah » dans sa file. Une promesse tenue par
-- deux fonctions sur cinq n'est pas une promesse : c'est une fuite avec une
-- banniere devant.
--
-- La cause est un motif applique a la main. `comptes_admin()` et
-- `journal_audit_filtres()`, ecrites APRES la bascule en mode observation,
-- portaient `agent_identite_masquee()` ; `dossiers_en_attente()`,
-- `demandes_en_attente()` et `journal_audit()` lui sont anterieures et
-- rendaient `first_name` / `last_name` tels quels. Aucun test ne pouvait le
-- voir : la fonction rend la bonne colonne, la RLS borne les bonnes lignes, et
-- c'est la COLONNE qui trahit — exactement la limite deja payee ailleurs
-- (« une RLS borne les LIGNES, pas les COLONNES »).
--
-- Ce que ce fichier ne fait pas : deplacer le masquage dans une vue unique.
-- Ce serait la bonne forme, mais les cinq fonctions ne rendent pas les memes
-- lignes ni les memes jointures, et une refonte pareille se paie en dette
-- ailleurs. Le motif reste duplique, la dette est nommee ici.
--
-- Cote Dart, le titre retombe sur l'identifiant immuable quand le nom est
-- masque, comme le fait deja `CompteAdmin.libelle` : sans cela la fiche
-- afficherait une ligne vide au-dessus de l'identifiant.

-- ---------------------------------------------------------------------------
-- 1. La file des dossiers d'identite (`ADM-02`) et la file du tableau de bord
-- ---------------------------------------------------------------------------
create or replace function public.dossiers_en_attente()
returns table (
  profile_id uuid,
  immutable_id text,
  first_name text,
  last_name text,
  role public.app_role,
  account_status public.account_status,
  inscrit_le timestamptz,
  document_id uuid,
  doc_type text,
  document_gender public.gender,
  object_key text,
  depose_le timestamptz,
  etat_piece text
)
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_en_attente int;
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'validation des dossiers reservee a l''administration';
  end if;

  -- Compte les pieces en attente AVANT d'appeler `read_kyc_documents()` :
  -- cette derniere journalise chaque appel, et il n'y a rien a journaliser
  -- quand personne n'a rien depose.
  select count(*) into v_en_attente
  from public.kyc_documents k
  where k.status = 'pending' and k.deleted_at is null;

  if v_en_attente = 0 then
    return query
      select
        p.id,
        p.immutable_id,
        case when v_masque then null else p.first_name end,
        case when v_masque then null else p.last_name end,
        p.role,
        p.account_status,
        p.created_at,
        null::uuid, null::text, null::public.gender, null::text,
        null::timestamptz,
        'aucune'::text
      from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'
      order by p.created_at asc;
    return;
  end if;

  return query
    with visibles as (
      select k.*
      from public.read_kyc_documents() k
      where k.status = 'pending'
    )
    select
      p.id,
      p.immutable_id,
      case when v_masque then null else p.first_name end,
      case when v_masque then null else p.last_name end,
      p.role,
      p.account_status,
      p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      case
        when v.id is not null then 'a_verifier'
        when exists (
          select 1 from public.kyc_documents k2
          where k2.profile_id = p.id
            and k2.status = 'pending'
            and k2.deleted_at is null
        ) then 'non_visible'
        else 'aucune'
      end::text
    from public.profiles p
    left join visibles v on v.profile_id = p.id
    where p.deleted_at is null
      and (p.account_status = 'pending_kyc' or v.id is not null)
    order by coalesce(v.created_at, p.created_at) asc;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. La file des demandes (`ADM-06`)
-- ---------------------------------------------------------------------------
create or replace function public.demandes_en_attente()
returns table (
  id uuid,
  kind text,
  subject_profile_id uuid,
  subject_first_name text,
  subject_immutable_id text,
  rule_key text,
  rule_value jsonb,
  reason text,
  requester_role public.app_role,
  requested_by uuid,
  created_at timestamptz
)
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'file des demandes reservee a l''administration';
  end if;

  return query
  select m.id, m.kind, m.subject_profile_id,
         case when v_masque then null else p.first_name end,
         p.immutable_id,
         m.rule_key, m.rule_value, m.reason, m.requester_role, m.requested_by,
         m.created_at
  from public.matching_requests m
  join public.profiles p on p.id = m.subject_profile_id
  where m.status = 'pending'
  order by m.created_at asc;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Le journal d'audit (`ADM-04`)
-- ---------------------------------------------------------------------------
-- `nom_acteur` retombait deja sur l'identifiant immuable quand le profil n'a
-- pas de nom : en mode observation, c'est la seule branche qui doit servir.
create or replace function public.journal_audit(
  p_acteur uuid default null,
  p_action text default null,
  p_depuis timestamptz default null,
  p_limite integer default 50,
  p_avant_date timestamptz default null,
  p_avant_id bigint default null
)
returns table (
  entree_id bigint,
  survenu_le timestamptz,
  acteur uuid,
  role_acteur text,
  nom_acteur text,
  type_evenement text,
  table_visee text,
  ligne_visee text,
  details jsonb
)
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 200 then
    raise exception 'limite hors bornes';
  end if;

  if (p_avant_date is null) <> (p_avant_id is null) then
    raise exception 'curseur incomplet';
  end if;

  return query
  select
    a.id,
    a.created_at,
    a.actor,
    a.actor_role,
    case
      when v_masque then p.immutable_id
      else coalesce(
        nullif(trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')), ''),
        p.immutable_id
      )
    end,
    a.action,
    a.table_name,
    a.row_id,
    a.payload
  from public.audit_logs a
  left join public.profiles p on p.id = a.actor
  where (p_acteur is null or a.actor = p_acteur)
    and (p_action is null or a.action = p_action)
    and (p_depuis is null or a.created_at >= p_depuis)
    and (
      p_avant_date is null
      or (a.created_at, a.id) < (p_avant_date, p_avant_id)
    )
  order by a.created_at desc, a.id desc
  limit p_limite;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. L'attribution manuelle (`ADM-05`), ses deux colonnes
-- ---------------------------------------------------------------------------
-- L'ordre de tri passe lui aussi sur l'identifiant quand l'identite est
-- masquee : trier une liste par un prenom qu'on ne montre pas laisse lire
-- l'ordre alphabetique des prenoms, ce qui est deja plus que rien.
create or replace function public.eleves_sans_enseignant()
returns table (
  student_id uuid,
  first_name text,
  immutable_id text,
  household_id uuid,
  level text,
  interface_mode public.interface_mode,
  depuis timestamptz,
  creneaux jsonb
)
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  return query
  select
    e.id,
    case when v_masque then null else e.first_name end,
    e.immutable_id,
    e.household_id,
    sp.level,
    sp.interface_mode,
    creneau.depuis,
    coalesce(creneau.cases, '[]'::jsonb)
  from public.profiles e
  join public.student_profiles sp
    on sp.profile_id = e.id and sp.deleted_at is null
  left join lateral (
    select
      min(w.created_at) as depuis,
      jsonb_agg(
        jsonb_build_object(
          'weekday', w.weekday,
          'hour_local', w.hour_local,
          'timezone_iana', w.timezone_iana,
          'created_at', w.created_at
        )
        order by w.weekday, w.hour_local
      ) as cases
    from public.weekly_availability w
    where w.profile_id = e.id
  ) creneau on true
  where e.role = 'student'
    and e.deleted_at is null
    and e.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = e.id and a.ended_at is null
    )
  order by
    creneau.depuis asc nulls last,
    case when v_masque then e.immutable_id else e.first_name end asc;
end;
$$;

create or replace function public.enseignants_pour(p_student_profile_id uuid)
returns table (
  teacher_id uuid,
  first_name text,
  last_name text,
  immutable_id text,
  country text,
  eleves_actifs integer,
  plafond integer,
  creneaux_communs jsonb
)
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  return query
  select
    ens.id,
    case when v_masque then null else ens.first_name end,
    case when v_masque then null else ens.last_name end,
    ens.immutable_id,
    tp.country,
    charge.actifs::int,
    public.regle_brute(ens.id, 'max_students_per_teacher'),
    coalesce(communs.cases, '[]'::jsonb)
  from public.profiles ens
  join public.teacher_profiles tp
    on tp.profile_id = ens.id and tp.deleted_at is null
  join lateral (
    select count(*) as actifs
    from public.teacher_student_assignments a
    where a.teacher_id = ens.id and a.ended_at is null
  ) charge on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'weekday', we.weekday,
        'hour_local', we.hour_local,
        'timezone_iana', we.timezone_iana
      )
      order by we.weekday, we.hour_local
    ) as cases
    from public.weekly_availability we
    join public.weekly_availability wt on wt.profile_id = ens.id
     and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
       = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
    where we.profile_id = p_student_profile_id
  ) communs on true
  where ens.role = 'teacher'
    and ens.deleted_at is null
    and ens.account_status in ('active', 'provisional_active')
  order by
    (coalesce(jsonb_array_length(communs.cases), 0) > 0) desc,
    charge.actifs asc,
    case when v_masque then ens.immutable_id else ens.first_name end asc;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. La liste des jetons d'agent (`ADM-07`)
-- ---------------------------------------------------------------------------
-- Cas le plus net du lot : la colonne dit le prenom de la personne OBSERVEE,
-- a cote de la case « identite masquee » du jeton. Un agent qui lit cette
-- liste lisait donc le prenom que son propre jeton lui interdit de voir.
create or replace function public.jetons_agent_actifs()
returns table (
  id uuid,
  libelle text,
  prefixe text,
  parcours public.app_role,
  profil_observe uuid,
  observe_identifiant text,
  observe_prenom text,
  identite_masquee boolean,
  expire_le timestamptz,
  revoque_le timestamptz,
  cree_le timestamptz,
  derniere_remise_le timestamptz,
  remises integer,
  etat text
)
language sql
stable security definer
set search_path to ''
as $$
  select
    t.id, t.libelle, t.prefixe, t.parcours, t.profil_observe,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    t.identite_masquee, t.expire_le, t.revoque_le, t.cree_le,
    t.derniere_remise_le, t.remises,
    case
      when t.revoque_le is not null then 'revoque'
      when t.expire_le <= now()     then 'expire'
      else 'actif'
    end
  from public.jetons_agent t
  join public.profiles p on p.id = t.profil_observe
  where public.app_role() = 'admin' and public.app_account_valid()
  order by
    case when t.revoque_le is null and t.expire_le > now() then 0 else 1 end,
    t.cree_le desc;
$$;

-- ---------------------------------------------------------------------------
-- 6. Les personnes proposees a l'observation (`ADM-07`), fonction NOUVELLE
-- ---------------------------------------------------------------------------
-- Ce n'est pas un oubli de masquage, c'est un chemin different : l'ecran
-- lisait `profiles` **en direct** par PostgREST
-- (`from('profiles').select('id, immutable_id, first_name, last_name, role')`).
-- Aucune fonction n'etait appelee, donc `agent_identite_masquee()` n'avait
-- aucun endroit ou s'appliquer, et la RLS n'y pouvait rien : elle borne les
-- lignes, jamais les colonnes.
--
-- La liste passe donc par une fonction, comme les six autres lectures de
-- l'administration. Le tri reste fait en base — deux rendus successifs ne
-- doivent pas proposer deux ordres — et la borne d'admin est explicite au
-- lieu d'etre deleguee a une policy ecrite pour un autre usage.
create or replace function public.personnes_observables()
returns table (
  id uuid,
  immutable_id text,
  first_name text,
  last_name text,
  role public.app_role
)
language sql
stable security definer
set search_path to ''
as $$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role
  from public.profiles p
  where p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and public.app_role() = 'admin'
    and public.app_account_valid()
  order by
    p.role,
    case
      when public.agent_identite_masquee() then p.immutable_id
      else p.first_name
    end;
$$;

-- `create or replace` conserve les droits deja accordes ; on les redit quand
-- meme, parce qu'un `EXECUTE` accorde a `PUBLIC` par defaut est le trou qu'on
-- a deja trouve une fois dans ce depot.
revoke all on function public.dossiers_en_attente() from public;
revoke all on function public.demandes_en_attente() from public;
revoke all on function public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint) from public;
revoke all on function public.eleves_sans_enseignant() from public;
revoke all on function public.enseignants_pour(uuid) from public;
revoke all on function public.jetons_agent_actifs() from public;
revoke all on function public.personnes_observables() from public;

grant execute on function public.dossiers_en_attente() to authenticated, agent_ro;
grant execute on function public.demandes_en_attente() to authenticated, agent_ro;
grant execute on function public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint) to authenticated, agent_ro;
grant execute on function public.eleves_sans_enseignant() to authenticated, agent_ro;
grant execute on function public.enseignants_pour(uuid) to authenticated, agent_ro;
grant execute on function public.jetons_agent_actifs() to authenticated, agent_ro;
grant execute on function public.personnes_observables() to authenticated, agent_ro;
