-- 0020 — Le programme pedagogique versionne, fondation du domaine Pedagogie
--
-- Premier lot de la mission « structurer le domaine Pedagogie du panneau
-- admin » (5 sous-fonctions : Diagnostics, Progression, Evaluations,
-- Programmes, Qualite). Ce lot pose la fondation dont les quatre autres
-- dependent : un referentiel de niveaux (`programme_niveaux`) versionne
-- (`programme_versions`). Le contenu reel du curriculum (les niveaux, leurs
-- noms humains, ce que chaque code technique recouvre) existe deja en dehors
-- de l'app et sera importe apres verification, dans un lot ulterieur : ce
-- lot construit seulement le squelette de donnees et l'ecran qui l'administre.
--
-- Regle produit explicite de la mission : une version au statut publiee ne
-- peut plus jamais etre modifiee retroactivement. Toute modification
-- academique cree une nouvelle version brouillon. Impose ici en base (les
-- fonctions d'ecriture refusent toute mutation hors 'brouillon'), pas
-- seulement dans l'interface.

-- ============================================================
-- 1. Les versions du programme
-- ============================================================

create table public.programme_versions (
  id uuid primary key default gen_random_uuid(),
  statut text not null default 'brouillon' check (statut in ('brouillon', 'publiee', 'archivee')),
  numero_version int not null,
  cree_par uuid not null references public.profiles(id),
  publiee_par uuid references public.profiles(id),
  publiee_at timestamptz,
  created_at timestamptz not null default now(),
  constraint programme_versions_publication_complete check (
    (statut = 'brouillon' and publiee_at is null and publiee_par is null)
    or (statut in ('publiee', 'archivee') and publiee_at is not null and publiee_par is not null)
  )
);

create unique index programme_versions_numero_uidx on public.programme_versions (numero_version);

comment on table public.programme_versions is
  'Une version du curriculum Rewayah. Aucune policy d''ecriture directe : '
  'seules les fonctions de cette migration ecrivent ici.';

alter table public.programme_versions enable row level security;

revoke all on public.programme_versions from anon;
revoke insert, update, delete on public.programme_versions from public, anon, authenticated;

-- ============================================================
-- 2. Les niveaux d'une version
-- ============================================================

create table public.programme_niveaux (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.programme_versions(id) on delete cascade,
  -- Identifiant technique (ex. F1-PHO-01) : jamais expose comme titre cote
  -- interface, seulement en sous-texte technique discret (interdiction UX
  -- explicite de la mission).
  code_technique text not null check (btrim(code_technique) <> ''),
  nom_humain text not null check (btrim(nom_humain) <> ''),
  cycle text not null check (btrim(cycle) <> ''),
  ordre int not null,
  description text,
  created_at timestamptz not null default now(),
  constraint programme_niveaux_code_unique unique (version_id, code_technique)
);

create index programme_niveaux_version_idx on public.programme_niveaux (version_id, ordre);

comment on table public.programme_niveaux is
  'Un niveau du curriculum au sein d''une version. Aucune policy d''ecriture '
  'directe : seules les fonctions de cette migration ecrivent ici, et '
  'seulement pour une version au statut brouillon.';

alter table public.programme_niveaux enable row level security;

revoke all on public.programme_niveaux from anon;
revoke insert, update, delete on public.programme_niveaux from public, anon, authenticated;

-- ============================================================
-- 3. Lecture : administration seulement (domaine Pedagogie, admin only)
-- ============================================================

create policy programme_versions_lecture on public.programme_versions
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

create policy programme_niveaux_lecture on public.programme_niveaux
for select to authenticated
using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 4. Les fonctions d'administration
-- ============================================================

create function public.creer_version_programme(p_source_version_id uuid default null)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_numero int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'creation de version de programme reservee a l''administration';
  end if;

  if p_source_version_id is not null and not exists (
    select 1 from public.programme_versions where id = p_source_version_id
  ) then
    raise exception 'version source introuvable';
  end if;

  select coalesce(max(numero_version), 0) + 1 into v_numero from public.programme_versions;

  insert into public.programme_versions (statut, numero_version, cree_par)
  values ('brouillon', v_numero, auth.uid())
  returning id into v_id;

  if p_source_version_id is not null then
    insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
    select v_id, code_technique, nom_humain, cycle, ordre, description
    from public.programme_niveaux
    where version_id = p_source_version_id;
  end if;

  perform public.log_sensitive_access(
    'programme_version_creee', 'programme_versions', v_id::text,
    jsonb_build_object('numero_version', v_numero, 'source_version_id', p_source_version_id)
  );

  return v_id;
end;
$function$;

create function public.ajouter_niveau_programme(
  p_version_id uuid,
  p_code_technique text,
  p_nom_humain text,
  p_cycle text,
  p_ordre int,
  p_description text default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
  values (p_version_id, p_code_technique, p_nom_humain, p_cycle, p_ordre, p_description)
  returning id into v_id;

  perform public.log_sensitive_access(
    'niveau_programme_ajoute', 'programme_niveaux', v_id::text,
    jsonb_build_object('version_id', p_version_id, 'code_technique', p_code_technique)
  );

  return v_id;
end;
$function$;

create function public.modifier_niveau_programme(
  p_niveau_id uuid,
  p_nom_humain text,
  p_cycle text,
  p_ordre int,
  p_description text default null
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  update public.programme_niveaux
  set nom_humain = p_nom_humain, cycle = p_cycle, ordre = p_ordre, description = p_description
  where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_modifie', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('nom_humain', p_nom_humain, 'cycle', p_cycle)
  );
end;
$function$;

create function public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour supprimer un niveau';
  end if;

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : impossible de supprimer un niveau publie';
  end if;

  delete from public.programme_niveaux where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_supprime', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$;

create function public.publier_version_programme(p_version_id uuid, p_motif text)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'publication du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour publier une version';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'cette version est deja publiee ou archivee';
  end if;

  if not exists (select 1 from public.programme_niveaux where version_id = p_version_id) then
    raise exception 'impossible de publier une version sans aucun niveau';
  end if;

  update public.programme_versions
  set statut = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_version_id;

  perform public.log_sensitive_access(
    'programme_version_publiee', 'programme_versions', p_version_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$;

-- ============================================================
-- 5. Les lectures pour l'ecran Admin > Pedagogie > Programmes
-- ============================================================

create function public.programme_versions_admin()
returns table(
  version_id uuid,
  statut text,
  numero_version int,
  cree_par_immutable_id text,
  cree_par_prenom text,
  cree_par_nom text,
  publiee_at timestamptz,
  nombre_niveaux int,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    v.id,
    v.statut,
    v.numero_version,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    v.publiee_at,
    (select count(*)::int from public.programme_niveaux n where n.version_id = v.id),
    v.created_at
  from public.programme_versions v
  join public.profiles p on p.id = v.cree_par
  where public.app_role() = 'admin' and public.app_account_valid()
  order by v.numero_version desc;
$function$;

comment on function public.programme_versions_admin() is
  'Liste des versions du programme pour l''ecran Admin > Pedagogie > Programmes.';

create function public.programme_niveaux_admin(p_version_id uuid)
returns table(
  niveau_id uuid,
  code_technique text,
  nom_humain text,
  cycle text,
  ordre int,
  description text
)
language sql stable security definer set search_path = ''
as $function$
  select n.id, n.code_technique, n.nom_humain, n.cycle, n.ordre, n.description
  from public.programme_niveaux n
  where public.app_role() = 'admin' and public.app_account_valid()
    and n.version_id = p_version_id
  order by n.ordre asc;
$function$;

comment on function public.programme_niveaux_admin(uuid) is
  'Les niveaux d''une version du programme, pour le panneau de detail de '
  'l''ecran Admin > Pedagogie > Programmes.';

-- ============================================================
-- 6. Les droits -- agent_ro seulement sur les lectures, jamais sur les
--    cinq fonctions d'ecriture (lecon deja payee deux fois sur ce depot,
--    voir 0018/0019 groupes).
-- ============================================================

revoke execute on function public.creer_version_programme(uuid) from public, anon;
revoke execute on function public.ajouter_niveau_programme(uuid, text, text, text, int, text) from public, anon;
revoke execute on function public.modifier_niveau_programme(uuid, text, text, int, text) from public, anon;
revoke execute on function public.supprimer_niveau_programme(uuid, text) from public, anon;
revoke execute on function public.publier_version_programme(uuid, text) from public, anon;
revoke execute on function public.programme_versions_admin() from public, anon;
revoke execute on function public.programme_niveaux_admin(uuid) from public, anon;

grant execute on function public.creer_version_programme(uuid) to authenticated;
grant execute on function public.ajouter_niveau_programme(uuid, text, text, text, int, text) to authenticated;
grant execute on function public.modifier_niveau_programme(uuid, text, text, int, text) to authenticated;
grant execute on function public.supprimer_niveau_programme(uuid, text) to authenticated;
grant execute on function public.publier_version_programme(uuid, text) to authenticated;
grant execute on function public.programme_versions_admin() to authenticated, agent_ro;
grant execute on function public.programme_niveaux_admin(uuid) to authenticated, agent_ro;
