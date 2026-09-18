-- 0015 — L'administration voit les personnes, pas seulement leurs papiers
--
-- Defaut mesure le 18 septembre 2026 sur la base de production : trois
-- enseignants inscrits les 11 et 15 septembre attendaient depuis sept jours,
-- contrats signes, sans avoir depose leur piece d'identite. Le centre de
-- commande affichait « 0 dossiers a valider » et l'ecran de validation
-- « Aucun dossier en attente ».
--
-- La cause n'est pas une panne : `dossiers_en_attente()` lisait
-- `kyc_documents where status = 'pending'`. Elle comptait des **documents**.
-- Une personne qui s'inscrit et s'arrete avant le depot n'a aucun document,
-- donc elle n'existait pour aucun ecran de l'administration.
--
-- Ce que cette migration change :
--
--   1. `dossiers_en_attente()` rend une ligne par **personne** en attente de
--      validation, avec l'etat de sa piece. Une personne sans piece est
--      visible et dit ce qui manque, au lieu d'etre absente ;
--   2. `comptes_admin()` est nouvelle : aucun ecran du produit ne listait les
--      comptes. L'administration n'avait aucun moyen de repondre a « qui s'est
--      inscrit ? » ;
--   3. `indicateurs_admin()` compte desormais les personnes en attente, pour
--      que le chiffre et l'ecran qu'il ouvre disent la meme chose ;
--   4. `journal_audit_filtres()` respecte enfin le masquage d'identite et rend
--      l'identifiant immuable, faute de quoi deux personnes homonymes
--      apparaissaient comme deux filtres identiques.

-- ---------------------------------------------------------------------------
-- 1. Les dossiers en attente sont des personnes
-- ---------------------------------------------------------------------------

drop function if exists public.dossiers_en_attente();

create function public.dossiers_en_attente()
returns table(
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
as $function$
declare
  v_en_attente int;
begin
  if public.app_role() <> 'admin' then
    raise exception 'validation des dossiers reservee a l''administration';
  end if;

  -- `read_kyc_documents()` journalise **chaque** appel, meme quand la table ne
  -- contient aucune piece a verifier. L'appeler a chaque ouverture du tableau
  -- de bord a produit 52 entrees « dossier consulte » pour zero lecture reelle,
  -- qui noient le journal. On ne l'appelle donc que s'il y a quelque chose a
  -- lire.
  select count(*) into v_en_attente
  from public.kyc_documents k
  where k.status = 'pending' and k.deleted_at is null;

  if v_en_attente = 0 then
    return query
      select
        p.id, p.immutable_id, p.first_name, p.last_name, p.role,
        p.account_status, p.created_at,
        null::uuid, null::text, null::public.gender, null::text,
        null::timestamptz,
        'aucune'::text
      from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'
      -- Anciennete d'abord : une inscription ne doit jamais pouvoir rester
      -- invisible en bas d'une liste (meme regle que le feed de ENS-06).
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
      p.id, p.immutable_id, p.first_name, p.last_name, p.role,
      p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      case
        when v.id is not null then 'a_verifier'
        -- La piece existe mais la regle de genre interdit de la lire
        -- (audit 1.3). Le dire est different de « aucune piece » : sans cette
        -- distinction, un dossier feminin lu par un agent masculin ressemblait
        -- a un dossier jamais depose.
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
$function$;

comment on function public.dossiers_en_attente() is
  'ADM-02 : une ligne par personne en attente de validation, avec l''etat de sa piece. Une personne sans piece reste visible.';

-- ---------------------------------------------------------------------------
-- 2. La liste des comptes — l'ecran qui n'existait pas
-- ---------------------------------------------------------------------------

create or replace function public.comptes_admin()
returns table(
  profile_id uuid,
  immutable_id text,
  prenom text,
  nom text,
  role public.app_role,
  etat_compte public.account_status,
  inscrit_le timestamptz,
  acces_jusqu_au timestamptz,
  foyer_id uuid,
  etat_piece text,
  contrats int,
  a_enseignant boolean,
  enfants_du_foyer int
)
language sql
stable
security definer
set search_path to ''
as $function$
  select
    p.id,
    p.immutable_id,
    -- Le masquage n'est pas une option de rendu : un agent qui observe avec
    -- `identite_masquee` ne doit pas pouvoir lire un prenom, quel que soit
    -- l'ecran. L'identifiant immuable suffit a suivre une personne.
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role,
    p.account_status,
    p.created_at,
    p.access_until,
    p.household_id,
    case
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'pending' and k.deleted_at is null
      ) then 'a_verifier'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'approved' and k.deleted_at is null
      ) then 'validee'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'rejected' and k.deleted_at is null
      ) then 'refusee'
      else 'aucune'
    end::text,
    (select count(*)::int from public.contract_acceptances c where c.profile_id = p.id),
    exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p.id and a.ended_at is null
    ),
    (select count(*)::int from public.profiles e
      where e.household_id = p.household_id
        and e.role = 'student' and e.deleted_at is null)
  from public.profiles p
  where p.deleted_at is null
    and public.app_role() = 'admin'
    and public.app_account_valid()
  -- Ce qui attend une decision passe devant, puis l'anciennete. Un compte
  -- bloque depuis une semaine ne doit pas se lire apres trente comptes actifs.
  order by
    case p.account_status
      when 'pending_kyc' then 0
      when 'provisional_active' then 1
      else 2
    end,
    p.created_at asc;
$function$;

comment on function public.comptes_admin() is
  'ADM-08 : tous les comptes du produit, ce qui attend une decision d''abord. Respecte le masquage d''identite des agents.';

-- ---------------------------------------------------------------------------
-- 3. Le compteur dit la meme chose que l'ecran qu'il ouvre
-- ---------------------------------------------------------------------------

create or replace function public.indicateurs_admin()
returns table(
  dossiers_en_attente integer,
  foyers_sans_enseignant integer,
  rapports_manquants integer,
  incidents_24h integer,
  comptes_echus integer,
  demandes_en_attente integer
)
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    -- Des **personnes** en attente de validation, plus des documents deposes.
    -- L'ancien compte lisait `kyc_documents where status='pending'` et
    -- affichait donc zero pendant que trois enseignants attendaient.
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Le journal respecte le masquage et distingue les homonymes
-- ---------------------------------------------------------------------------

create or replace function public.journal_audit_filtres()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_resultat jsonb;
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  select jsonb_build_object(
    'total', (select count(*) from public.audit_logs),
    'premiere', (select min(x.created_at) from public.audit_logs x),
    'actions', coalesce((
      select jsonb_agg(
        jsonb_build_object('action', t.action, 'n', t.n)
        order by t.n desc, t.action asc
      )
      from (
        select a.action, count(*) as n
        from public.audit_logs a
        group by a.action
      ) t
    ), '[]'::jsonb),
    'acteurs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', u.actor,
          'nom', u.nom,
          'identifiant', u.identifiant,
          'role', u.role,
          'n', u.n
        )
        order by u.n desc, u.nom asc
      )
      from (
        select
          a.actor,
          count(*) as n,
          (array_agg(a.actor_role order by a.created_at desc, a.id desc))[1] as role,
          max(p.immutable_id) as identifiant,
          -- Deux corrections d'un coup : le masquage, qui n'etait applique
          -- nulle part sur cet ecran malgre la banniere « prenoms masques » ;
          -- et le repli sur l'identifiant immuable, faute de quoi deux
          -- personnes portant le meme nom produisaient deux filtres
          -- visuellement identiques.
          case
            when v_masque then coalesce(max(p.immutable_id), a.actor::text)
            else coalesce(
              nullif(trim(coalesce(max(p.first_name), '') || ' ' || coalesce(max(p.last_name), '')), ''),
              max(p.immutable_id),
              a.actor::text
            )
          end as nom
        from public.audit_logs a
        left join public.profiles p on p.id = a.actor
        where a.actor is not null
        group by a.actor
      ) u
    ), '[]'::jsonb)
  ) into v_resultat;

  return v_resultat;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Les droits
-- ---------------------------------------------------------------------------
--
-- `agent_ro` n'avait recu aucun `EXECUTE` sur les lectures de l'administration
-- (defaut de la migration 0014, corrige le 18 septembre). Toute nouvelle
-- lecture doit lui etre accordee explicitement, sinon une session
-- d'observation recoit `403` sur l'ecran concerne.

grant execute on function public.dossiers_en_attente() to authenticated, agent_ro;
grant execute on function public.comptes_admin() to authenticated, agent_ro;
grant execute on function public.indicateurs_admin() to authenticated, agent_ro;
grant execute on function public.journal_audit_filtres() to authenticated, agent_ro;
