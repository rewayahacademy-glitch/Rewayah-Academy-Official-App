-- Reconciliation forward du domaine Classes.
--
-- Cette migration ne reecrit ni 0043 ni les migrations Core24 historiques.
-- Elle rend explicites les invariants normatifs du handoff : age fiable pour
-- les mineurs, cohortes de dispatch, Groupe DRAFT et offre enfant generique.
begin;

-- ============================================================
-- 1. Configuration centralisee
-- ============================================================

insert into public.app_config (key, value)
values ('enseignant.max_primary_groups', '2'::jsonb)
on conflict (key) do nothing;

-- ============================================================
-- 2. Cohortes normatives, sans remapper les profils legacy
-- ============================================================

update public.cohortes_age
set actif = false
where code in ('enfant_5_7', 'enfant_8_10', 'ado_11_14', 'ado_15_17');

insert into public.cohortes_age
  (code, nom_humain, age_min, age_max_inclus, type_public, student_type,
   interface_mode, ordre, actif)
values
  ('enfant_6_9', '6 à 9 ans', 6, 9, 'enfant', 'minor', 'child', 1, true),
  ('enfant_10_13', '10 à 13 ans', 10, 13, 'enfant', 'minor', 'child', 2, true),
  ('ado_14_17', '14 à 17 ans', 14, 17, 'enfant', 'minor', 'child', 3, true),
  ('adulte_18_plus', '18 ans et plus', 18, null, 'adulte', 'autonomous', 'standard', 4, true)
on conflict (code) do update set
  nom_humain = excluded.nom_humain,
  age_min = excluded.age_min,
  age_max_inclus = excluded.age_max_inclus,
  type_public = excluded.type_public,
  student_type = excluded.student_type,
  ordre = excluded.ordre,
  actif = excluded.actif;

-- ============================================================
-- 3. Source fiable d'age pour un profil mineur
-- ============================================================

alter table public.student_profiles
  add column if not exists date_naissance date,
  add column if not exists placement_basis text;

comment on column public.student_profiles.date_naissance is
  'Date de naissance fiable du mineur, geree par le tuteur. Jamais derivee d''une ancienne cohorte.';

comment on column public.student_profiles.placement_basis is
  'Provenance explicable du placement : declaration debutant ou resultat academique serveur.';

-- La RLS de ligne est deja celle du foyer ; le grant par colonne reste ferme.
revoke update (date_naissance, placement_basis)
  on public.student_profiles from public, anon, authenticated;

create or replace function public.definir_date_naissance_apprenant(
  p_membre_id uuid,
  p_date_naissance date
)
returns jsonb
language plpgsql security definer set search_path = ''
as $function$
declare
  v_role public.app_role;
  v_type public.student_type;
  v_age smallint;
  v_cohorte text;
begin
  if p_date_naissance is null then
    raise exception 'la date de naissance est requise pour un profil mineur';
  end if;

  if p_date_naissance > current_date then
    raise exception 'la date de naissance ne peut pas etre dans le futur';
  end if;

  if not (
    (
      public.app_role() = 'admin'
      and public.app_account_valid()
    )
    or public.peut_decrire_apprenant(p_membre_id)
  ) then
    raise exception 'ce profil ne peut pas etre renseigne par cet appelant';
  end if;

  select p.role, sp.student_type
    into v_role, v_type
  from public.profiles p
  join public.student_profiles sp on sp.profile_id = p.id
  where p.id = p_membre_id
    and p.deleted_at is null
    and sp.deleted_at is null;

  if not found then
    raise exception 'profil eleve introuvable';
  end if;

  if v_role <> 'student' or v_type <> 'minor' then
    raise exception 'la date de naissance de ce profil ne releve pas du parcours mineur';
  end if;

  v_age := extract(year from age(current_date, p_date_naissance))::smallint;
  if v_age >= 18 then
    raise exception 'un profil mineur ne peut pas recevoir une date adulte';
  end if;

  select c.code
    into v_cohorte
  from public.cohortes_age c
  where c.actif
    and c.type_public = 'enfant'
    and c.age_min <= v_age
    and (c.age_max_inclus is null or v_age <= c.age_max_inclus)
  order by c.ordre
  limit 1;

  update public.student_profiles
  set date_naissance = p_date_naissance,
      cohorte = v_cohorte
  where profile_id = p_membre_id
    and deleted_at is null;

  perform public.log_sensitive_access(
    'date_naissance_apprenant_definie',
    'student_profiles',
    p_membre_id::text,
    jsonb_build_object(
      'age_calcule', v_age,
      'cohorte', v_cohorte,
      'hors_dispatch_standard', v_cohorte is null
    )
  );

  return jsonb_build_object(
    'age', v_age,
    'cohorte', v_cohorte,
    'hors_dispatch_standard', v_cohorte is null
  );
end;
$function$;

revoke execute on function public.definir_date_naissance_apprenant(uuid, date)
  from public, anon, agent_ro;
grant execute on function public.definir_date_naissance_apprenant(uuid, date)
  to authenticated;

-- ============================================================
-- 4. Groupe DRAFT et compatibilite de dispatch
-- ============================================================

alter table public.groupes
  add column if not exists cohorte text references public.cohortes_age(code),
  add column if not exists etat text not null default 'active';

alter table public.groupes
  alter column teacher_id drop not null;

update public.groupes
set etat = case when ended_at is null then 'active' else 'cloturee' end
where etat is null or (ended_at is not null and etat <> 'cloturee');

do $migration$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'groupes_etat_check'
      and conrelid = 'public.groupes'::regclass
  ) then
    alter table public.groupes
      add constraint groupes_etat_check
      check (etat in ('brouillon', 'ready', 'publiee', 'active', 'cloturee'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'groupes_publication_teacher_check'
      and conrelid = 'public.groupes'::regclass
  ) then
    alter table public.groupes
      add constraint groupes_publication_teacher_check
      check (etat = 'brouillon' or teacher_id is not null);
  end if;
end $migration$;

create index if not exists groupes_dispatch_compatibilite_idx
  on public.groupes (offre_id, langue_code, cohorte, type_public, etat)
  where ended_at is null;

comment on column public.groupes.teacher_id is
  'Titulaire permanent du Groupe. NULL uniquement avant affectation, en DRAFT.';

comment on column public.groupes.etat is
  'Lifecycle serveur : brouillon, ready, publiee, active ou cloturee.';

-- ============================================================
-- 5. Restriction de cohorte optionnelle sur une offre vitrine
-- ============================================================

alter table public.offres_horaires
  add column if not exists cohorte_code text references public.cohortes_age(code);

do $migration$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'offres_horaires_cohorte_enfant_check'
      and conrelid = 'public.offres_horaires'::regclass
  ) then
    alter table public.offres_horaires
      add constraint offres_horaires_cohorte_enfant_check
      check (cohorte_code is null or type_public = 'enfant');
  end if;
end $migration$;

drop index if exists public.offres_horaires_motif_unique;
create unique index offres_horaires_motif_unique
  on public.offres_horaires (
    type_public,
    langue_code,
    coalesce(cohorte_code, ''),
    fuseau_iana,
    heure_locale,
    jours
  )
  where etat <> 'retiree';

-- L'offre reste generique quand cohorte_code est NULL. Une restriction
-- explicite est une exception de catalogue, jamais une obligation.
create or replace function public.offres_compatibles(
  p_membre_id uuid,
  p_fuseau_vue text
)
returns table (
  offre_id uuid,
  type_public text,
  langue_code text,
  langue_nom text,
  jours_locaux smallint[],
  heures_locales smallint[],
  heure_source smallint,
  fuseau_source text,
  duree_minutes smallint,
  rythme text,
  pause_minutes smallint,
  capacite smallint,
  deja_choisie boolean
)
language sql stable security definer set search_path = ''
as $function$
  with fiche as (
    select sp.langue_cours, sp.cohorte, sp.level, c.type_public
    from public.student_profiles sp
    join public.cohortes_age c on c.code = sp.cohorte
    where sp.profile_id = p_membre_id
      and sp.deleted_at is null
      and public.peut_decrire_apprenant(p_membre_id)
      and exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_vue)
  )
  select
    o.id,
    o.type_public,
    o.langue_code,
    l.nom_humain,
    v.jours_locaux,
    v.heures_locales,
    o.heure_locale,
    o.fuseau_iana,
    o.duree_minutes,
    o.rythme::text,
    case o.type_public
      when 'adulte' then public.app_config_int('seance.pause_minutes_adulte', 0)::smallint
      else public.app_config_int('seance.pause_minutes_enfant', 6)::smallint
    end,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = p_membre_id and i.offre_id = o.id and i.etat <> 'retiree'
    )
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join fiche f
  cross join lateral (
    select
      array_agg(x.jour order by x.rang)::smallint[] as jours_locaux,
      array_agg(x.heure order by x.rang)::smallint[] as heures_locales
    from (
      select
        j.rang,
        extract(isodow from j.local)::smallint as jour,
        extract(hour from j.local)::smallint as heure
      from (
        select
          u.rang,
          public.instant_creneau(u.j::int, o.heure_locale::int, o.fuseau_iana)
            at time zone p_fuseau_vue as local
        from unnest(o.jours) with ordinality as u(j, rang)
      ) j
    ) x
  ) v
  where o.etat = 'publiee'
    and o.type_public = f.type_public
    and o.langue_code = f.langue_cours
    and (o.cohorte_code is null or o.cohorte_code = f.cohorte)
    and (o.programme_niveau_id is null or o.programme_niveau_id::text = f.level)
  order by 2, 7, 4;
$function$;

revoke execute on function public.offres_compatibles(uuid, text)
  from public, anon;
grant execute on function public.offres_compatibles(uuid, text)
  to authenticated, agent_ro;

-- ============================================================
-- 6. L'onboarding ne fait plus confiance a une cohorte envoyee par le client
-- ============================================================

-- La signature historique est conservee pour compatibilite des clients en
-- cours de transition, mais `p_cohorte` n'est plus une source d'autorite.
-- Pour un mineur, la date fiable deja posee par le tuteur est la seule source
-- de calcul. Pour un adulte autonome, le public adulte vient du type de profil.
create or replace function public.enregistrer_profil_apprentissage(
  p_membre_id uuid,
  p_langue_code text,
  p_cohorte text,
  p_niveau_declare text,
  p_objectif text,
  p_fuseau_iana text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_type public.student_type;
  v_date_naissance date;
  v_age smallint;
  v_cohorte public.cohortes_age;
  v_foyer uuid;
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  select sp.student_type, sp.date_naissance
    into v_type, v_date_naissance
  from public.student_profiles sp
  where sp.profile_id = p_membre_id and sp.deleted_at is null;

  if not found then
    raise exception 'aucune fiche eleve vivante pour ce profil';
  end if;

  if v_type = 'minor' then
    if v_date_naissance is null then
      raise exception 'la date de naissance du mineur doit etre renseignee par le tuteur';
    end if;
    v_age := extract(year from age(current_date, v_date_naissance))::smallint;
    if v_age >= 18 then
      raise exception 'la date de naissance ne correspond plus a un profil mineur';
    end if;
    select c.* into v_cohorte
    from public.cohortes_age c
    where c.actif
      and c.type_public = 'enfant'
      and c.age_min <= v_age
      and (c.age_max_inclus is null or v_age <= c.age_max_inclus)
    order by c.ordre
    limit 1;
  else
    select c.* into v_cohorte
    from public.cohortes_age c
    where c.actif and c.code = 'adulte_18_plus'
    limit 1;
  end if;

  if v_cohorte.code is null then
    raise exception 'aucune cohorte active ne correspond a ce profil';
  end if;

  if not exists (
    select 1 from public.langues_cours where code = p_langue_code and actif
  ) then
    raise exception 'langue de cours inconnue ou retiree : %', coalesce(p_langue_code, 'aucune');
  end if;

  if coalesce(btrim(p_fuseau_iana), '') = '' then
    raise exception 'un fuseau est requis : c''est lui qui fixe l''heure affichee';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana
  ) then
    raise exception 'fuseau IANA inconnu : %', p_fuseau_iana;
  end if;

  update public.student_profiles set
    langue_cours = p_langue_code,
    niveau_declare = p_niveau_declare,
    objectif = p_objectif,
    placement_basis = case
      when p_niveau_declare = 'debut_lettres' then 'debutant_declare'
      else 'prediagnostic_declare'
    end,
    diagnostic_statut = case
      when p_niveau_declare = 'debut_lettres'
           and diagnostic_statut = 'a_planifier' then 'non_requis'
      else diagnostic_statut
    end,
    onboarding_fait_le = now()
  where profile_id = p_membre_id and deleted_at is null;

  select p.household_id into v_foyer
  from public.profiles p
  where p.id = p_membre_id;

  if v_foyer is not null then
    update public.households set timezone = p_fuseau_iana
    where id = v_foyer and deleted_at is null;
  end if;

  perform public.log_sensitive_access(
    'profil_apprentissage_enregistre', 'student_profiles', p_membre_id::text,
    jsonb_build_object('langue', p_langue_code, 'cohorte', v_cohorte.code,
                       'niveau_declare', p_niveau_declare, 'objectif', p_objectif,
                       'fuseau', p_fuseau_iana)
  );
end;
$function$;

-- Nouvelle signature sans argument d'autorite obsolete. Le client migre vers
-- celle-ci ; l'ancienne reste sure pendant la transition.
create function public.enregistrer_profil_apprentissage(
  p_membre_id uuid,
  p_langue_code text,
  p_niveau_declare text,
  p_objectif text,
  p_fuseau_iana text
)
returns void
language sql security definer set search_path = ''
as $function$
  select public.enregistrer_profil_apprentissage(
    p_membre_id, p_langue_code, null, p_niveau_declare,
    p_objectif, p_fuseau_iana
  );
$function$;

revoke execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text)
  from public, anon, agent_ro;
grant execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text)
  to authenticated;

-- Le parcours a besoin de savoir s'il doit encore demander la date, mais la
-- ligne reste bornee au foyer par la security-invoker view et sa RLS.
drop view public.v_parcours_onboarding;
create view public.v_parcours_onboarding
with (security_invoker = true) as
select
  sp.profile_id                                   as eleve_id,
  p.first_name                                    as prenom,
  sp.date_naissance,
  sp.cohorte,
  c.nom_humain                                    as cohorte_nom,
  c.type_public,
  l.nom_humain                                    as langue_nom,
  sp.langue_cours                                 as langue_code,
  sp.niveau_declare,
  sp.objectif,
  sp.placement_basis,
  sp.diagnostic_statut,
  sp.onboarding_fait_le,
  h.timezone                                      as fuseau_foyer,
  i.id                                            as intention_id,
  i.etat                                          as intention_etat,
  i.offre_id,
  i.fuseau_affiche,
  i.heure_affichee,
  i.jours_affiches,
  i.groupe_id,
  o.etat                                          as offre_etat,
  (i.id is not null and o.etat <> 'publiee')      as offre_indisponible,
  (i.id is not null and h.timezone is not null
     and h.timezone <> i.fuseau_affiche)          as fuseau_change
from public.student_profiles sp
join public.profiles p on p.id = sp.profile_id
left join public.cohortes_age c on c.code = sp.cohorte
left join public.langues_cours l on l.code = sp.langue_cours
left join public.households h on h.id = p.household_id
left join public.intentions_horaire i
  on i.eleve_id = sp.profile_id and i.etat <> 'retiree'
left join public.offres_horaires o on o.id = i.offre_id
where sp.deleted_at is null and p.deleted_at is null;

grant select on public.v_parcours_onboarding to authenticated, agent_ro;
revoke all on public.v_parcours_onboarding from anon;
revoke all on public.v_parcours_onboarding from public;

notify pgrst, 'reload schema';
commit;
