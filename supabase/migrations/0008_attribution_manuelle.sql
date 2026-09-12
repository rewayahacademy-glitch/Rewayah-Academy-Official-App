-- 0008 : `ADM-05`, l'attribution manuelle.
--
-- Perimetre fixe par docs/design/08-catalogue-ecrans.md (ligne `ADM-05`,
-- « Deux listes empilees / Deux listes cote a cote ») et par
-- docs/produit/parcours-utilisateurs.md section 5 (« Ecran de secours quand le
-- matching inverse ne produit rien. Liste des foyers en attente, liste des
-- enseignants disponibles, attribution en deux taps »).
--
-- Ce fichier n'existe que pour une raison, ecrite noir sur blanc en 0005 :
--
--   « I3 : personne n'ecrit ici a la main, pas meme l'administration. Une
--     affectation se cree par prendre_eleve() et se clot par decider_demande(). »
--
-- L'invariant tient, et il tient encore apres cette migration : aucune policy
-- d'ecriture n'est ouverte sur `teacher_student_assignments`. On ajoute une
-- **deuxieme porte**, `attribuer_eleve()`, reservee a l'administration, a cote
-- de celle de l'enseignant. Le mur reste, la porte est nommee et journalisee.
--
-- Trois regles portees ici, pas dans le Dart :
--
--   1. **L'heure appartient au foyer.** Comme `prendre_eleve()`, l'attribution
--      refuse tout creneau que la famille n'a pas pose. Une administration ne
--      choisit pas l'heure du cours d'un enfant a la place de ses parents.
--   2. **L'administration peut passer outre les disponibilites de
--      l'enseignant, jamais en silence** (ADR-021). C'est exactement ce qui
--      distingue un ecran de secours d'un doublon de `ENS-06` : si tout devait
--      se croiser, l'ecran serait vide le jour ou l'on en a besoin. Le prix est
--      un motif obligatoire et une ligne de journal qui le porte.
--   3. **Le plafond ne se contourne pas.** Le declencheur `assignments_cap` de
--      0005 tourne aussi pour cette porte : l'administration qui veut depasser
--      un plafond pose une surcharge de regle, geste deja construit en `ADM-06`,
--      et cela laisse une trace la ou il faut.

begin;

-- ============================================================
-- 1. Ce que la colonne de gauche affiche
-- ============================================================

-- Les eleves sans enseignant actif, vus par l'administration.
--
-- Jumelle assumee de `eleves_en_attente_v`, et non sa reutilisation : cette
-- vue-la croise les creneaux avec ceux de `auth.uid()` et se ferme a tout role
-- autre qu'enseignant. La lire en administration rendrait zero ligne.
--
-- Deux differences de fond avec le feed de `ENS-06`, toutes deux voulues :
--
--   * **une ligne par eleve**, pas une par creneau : la colonne de gauche est
--     une file de personnes, pas un tableau d'heures. Les creneaux voyagent
--     avec, en jsonb, parce que c'est parmi eux que l'attribution choisira ;
--   * **un eleve qui n'a pose aucun creneau reste dans la liste**, avec un
--     tableau vide. Le masquer donnerait un compteur `ADM-01` a 1 et une liste
--     vide en face : l'administration doit voir que ce foyer attend, et
--     pourquoi il ne peut pas encore etre attribue.
create function public.eleves_sans_enseignant()
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
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  return query
  select
    e.id,
    e.first_name,
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
  -- Anciennete d'abord, comme le feed de `ENS-06` : sans ce tri, un foyer peut
  -- rester invisible en bas de liste indefiniment. `nulls last` met en fin de
  -- file celui qui n'a rien pose, qui n'est de toute facon pas attribuable.
  order by creneau.depuis asc nulls last, e.first_name asc;
end;
$$;

revoke execute on function public.eleves_sans_enseignant() from public, anon;
grant execute on function public.eleves_sans_enseignant() to authenticated;

-- ============================================================
-- 2. Ce que la colonne de droite affiche
-- ============================================================

-- Les enseignants, vus pour un eleve donne.
--
-- **Tous les enseignants au compte valide sont rendus, pas seulement ceux dont
-- un creneau croise.** C'est le point de l'ecran de secours : le jour ou aucun
-- croisement n'existe est precisement le jour ou l'on ouvre `ADM-05`, et une
-- liste vide y serait le troisieme placeholder de l'espace administration.
--
-- Ce qui voyage avec chaque enseignant sert a juger avant d'attribuer :
-- sa charge courante, son plafond effectif, et les creneaux qu'il partage
-- vraiment avec ce foyer. Le croisement se fait **par instant** et non par heure
-- locale, exactement comme `eleves_en_attente_v` : la famille pose en heure de
-- Paris, l'enseignant travaille en heure de Conakry.
create function public.enseignants_pour(p_student_profile_id uuid)
returns table (
  teacher_id uuid,
  first_name text,
  last_name text,
  immutable_id text,
  country text,
  eleves_actifs int,
  plafond int,
  creneaux_communs jsonb
)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  return query
  select
    ens.id,
    ens.first_name,
    ens.last_name,
    ens.immutable_id,
    tp.country,
    charge.actifs::int,
    -- `regle_brute` et non `regle_effective` : l'administration n'est pas partie
    -- concernee au sens de l'ADR-017, et un plafond qui s'affiche a sa valeur de
    -- plateforme faute de droit de lecture ferait mentir la colonne.
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
  -- Celui qui peut prendre ce foyer sans rien forcer d'abord, puis le moins
  -- charge : c'est l'ordre dans lequel une attribution se decide.
  order by
    (coalesce(jsonb_array_length(communs.cases), 0) > 0) desc,
    charge.actifs asc,
    ens.first_name asc;
end;
$$;

revoke execute on function public.enseignants_pour(uuid) from public, anon;
grant execute on function public.enseignants_pour(uuid) to authenticated;

-- ============================================================
-- 3. La deuxieme porte
-- ============================================================

-- L'attribution administrative. Jumelle de `prendre_eleve()`, avec trois
-- differences et pas une de plus :
--
--   * l'appelant est l'administration, et l'enseignant est un parametre ;
--   * le creneau peut ne pas figurer dans les disponibilites de l'enseignant,
--     et c'est alors un motif qui le paie (ADR-021) ;
--   * la ligne de journal porte ce motif et le fait que l'on soit passe outre.
--
-- Ce qui ne change pas : l'heure vient du foyer, un eleve n'a qu'un enseignant,
-- le plafond est tranche par le declencheur de 0005, et les seances sont
-- materialisees dans la foulee — sans quoi l'attribution ne produirait aucun
-- cours et `TUT-01`/`ELV-02` resteraient vides apres le geste.
create function public.attribuer_eleve(
  p_student_profile_id uuid,
  p_teacher_profile_id uuid,
  p_weekday int,
  p_hour int,
  p_motif text default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_tz         text;
  v_instant    timestamptz;
  v_hors       boolean;
  v_motif      text := nullif(btrim(coalesce(p_motif, '')), '');
  v_assignment uuid;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  -- Le creneau demande doit etre un creneau POSE par le foyer. Meme phrase et
  -- meme refus que `prendre_eleve()` : ce n'est pas une politesse, c'est la
  -- seule garantie que l'enfant soit disponible a cette heure-la.
  select w.timezone_iana into v_tz
  from public.weekly_availability w
  join public.profiles p on p.id = w.profile_id
  where w.profile_id = p_student_profile_id
    and w.weekday = p_weekday and w.hour_local = p_hour
    and p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_tz is null then
    raise exception 'ce creneau n''est pas propose par ce foyer';
  end if;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  v_hors := not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = p_teacher_profile_id
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  );

  -- ADR-021 : passer outre est permis, le faire en silence ne l'est pas. Le
  -- motif est exige **en base** et non seulement a l'ecran, pour la meme raison
  -- qu'un refus de dossier l'exige : ce qui ne se verifie qu'au clavier finit
  -- par ne plus se verifier du tout.
  if v_hors and v_motif is null then
    raise exception 'attribuer hors des disponibilites de cet enseignant exige un motif';
  end if;

  if exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = p_student_profile_id and a.ended_at is null
  ) then
    raise exception 'cet eleve a deja un enseignant';
  end if;

  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values (p_teacher_profile_id, p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    -- Un enseignant peut prendre ce meme eleve dans `ENS-06` a l'instant ou
    -- l'administration l'attribue. L'index unique partiel tranche, et le perdant
    -- recoit une phrase, pas un code d'erreur.
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_attribuee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'teacher_id', p_teacher_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour,
                       'hors_disponibilite', v_hors,
                       'motif', v_motif));

  return v_assignment;
end;
$$;

revoke execute on function public.attribuer_eleve(uuid, uuid, int, int, text)
  from public, anon;
grant execute on function public.attribuer_eleve(uuid, uuid, int, int, text)
  to authenticated;

commit;
