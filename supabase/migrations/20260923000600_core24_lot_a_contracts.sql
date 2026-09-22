-- Core24 Lot A : verrouillage des contrats d'age et de diagnostic.
--
-- La date de naissance est la source d'autorite pour l'age d'un mineur.
-- `cohorte` reste une projection de dispatch et ne doit plus etre modifiable
-- directement par un client authentifie. Le diagnostic officiel reste decide
-- par la porte Admin canonique (`progression_historique`).
begin;

-- 1. La famille ne choisit ni la cohorte derivee ni l'etat de diagnostic.
revoke update (
  cohorte,
  date_naissance,
  placement_basis,
  diagnostic_statut,
  level
)
on public.student_profiles from public, anon, authenticated;

do $migration$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'student_profiles_placement_basis_check'
      and conrelid = 'public.student_profiles'::regclass
  ) then
    alter table public.student_profiles
      add constraint student_profiles_placement_basis_check
      check (
        placement_basis is null
        or placement_basis in (
          'debutant_declare',
          'prediagnostic_declare',
          'diagnostic_academique',
          'legacy_non_reconstructible'
        )
      );
  end if;
end $migration$;

-- 2. Revenir d'un parcours debutant vers un parcours non-debutant doit
--    reouvrir le diagnostic, sans effacer un niveau deja decide.
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
    select 1 from public.langues_cours
    where code = p_langue_code and actif
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
    cohorte = v_cohorte.code,
    placement_basis = case
      when p_niveau_declare = 'debut_lettres'
           and diagnostic_statut <> 'fait' then 'debutant_declare'
      when diagnostic_statut = 'fait'
        then coalesce(placement_basis, 'diagnostic_academique')
      else 'prediagnostic_declare'
    end,
    diagnostic_statut = case
      when p_niveau_declare = 'debut_lettres'
           and diagnostic_statut in ('a_planifier', 'planifie') then 'non_requis'
      when p_niveau_declare <> 'debut_lettres'
           and diagnostic_statut = 'non_requis' then 'a_planifier'
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
    jsonb_build_object(
      'langue', p_langue_code,
      'cohorte', v_cohorte.code,
      'niveau_declare', p_niveau_declare,
      'objectif', p_objectif,
      'fuseau', p_fuseau_iana
    )
  );
end;
$function$;

-- 3. Un diagnostic officiel ne peut pas etre remplace par la declaration
--    d'une famille et marque explicitement la provenance de placement.
create or replace function public.decider_placement(
  p_student_id uuid,
  p_niveau_id uuid,
  p_motif text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_diagnostic_statut text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'decision de placement reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour decider un placement';
  end if;

  select sp.diagnostic_statut into v_diagnostic_statut
  from public.student_profiles sp
  join public.profiles p on p.id = sp.profile_id
  where sp.profile_id = p_student_id
    and sp.deleted_at is null
    and p.role = 'student'
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if not found then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if v_diagnostic_statut = 'non_requis' then
    raise exception 'un debutant declare ne requiert pas de diagnostic';
  end if;

  if not exists (
    select 1 from public.programme_niveaux where id = p_niveau_id
  ) then
    raise exception 'ce niveau de programme n''existe pas';
  end if;

  if exists (
    select 1 from public.progression_historique
    where student_id = p_student_id
  ) then
    raise exception 'cet eleve a deja un niveau decide : passez par Progression pour le modifier';
  end if;

  insert into public.progression_historique
    (student_id, niveau_id, type_mouvement, decide_par, motif)
  values
    (p_student_id, p_niveau_id, 'diagnostic_initial', auth.uid(), p_motif)
  returning id into v_id;

  update public.student_profiles
  set diagnostic_statut = 'fait',
      placement_basis = 'diagnostic_academique'
  where profile_id = p_student_id and deleted_at is null;

  perform public.log_sensitive_access(
    'placement_decide', 'progression_historique', v_id::text,
    jsonb_build_object(
      'student_id', p_student_id,
      'niveau_id', p_niveau_id,
      'motif', p_motif
    )
  );

  return v_id;
end;
$function$;

-- 4. La file Admin n'affiche pas les debutants declares comme a diagnostiquer.
create or replace function public.diagnostics_a_traiter()
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
  join public.student_profiles sp on sp.profile_id = p.id
  where public.app_role() = 'admin'
    and public.app_account_valid()
    and p.role = 'student'
    and p.deleted_at is null
    and sp.deleted_at is null
    and sp.diagnostic_statut in ('a_planifier', 'planifie')
    and p.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.progression_historique h where h.student_id = p.id
    )
  order by p.created_at asc;
$function$;

notify pgrst, 'reload schema';
commit;
