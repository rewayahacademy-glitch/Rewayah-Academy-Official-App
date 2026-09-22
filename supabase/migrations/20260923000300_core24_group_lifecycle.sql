-- Core24 Classes — projection Admin et transitions de Groupe.
--
-- Les anciennes RPC de groupes restent disponibles pour les parcours legacy.
-- Cette surface nommee est la porte du nouveau lifecycle : DRAFT peut rester
-- sans titulaire ; READY/PUBLISHED/ACTIVE exigent un titulaire et un pool
-- coherent. L'admissibilite professionnelle est un lot distinct.
begin;

drop function if exists public.groupes_admin();

create function public.groupes_admin()
returns table(
  groupe_id uuid,
  libelle text,
  type_public text,
  seuil_max smallint,
  teacher_id uuid,
  teacher_immutable_id text,
  teacher_prenom text,
  teacher_nom text,
  weekday smallint,
  hour_local smallint,
  nombre_membres int,
  actif boolean,
  created_at timestamptz,
  etat text,
  cohorte text,
  niveau_id uuid
)
language sql stable security definer set search_path = ''
as $function$
  select
    g.id,
    g.libelle,
    g.type_public,
    g.seuil_max,
    g.teacher_id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    g.weekday,
    g.hour_local,
    (select count(*)::int from public.groupe_membres m
      where m.groupe_id = g.id and m.left_at is null),
    g.ended_at is null,
    g.created_at,
    g.etat,
    g.cohorte,
    g.niveau_id
  from public.groupes g
  left join public.profiles p on p.id = g.teacher_id
  where public.app_role() = 'admin'
    and public.app_account_valid()
  order by (g.ended_at is not null), g.created_at desc;
$function$;

revoke execute on function public.groupes_admin() from public, anon, agent_ro;
grant execute on function public.groupes_admin() to authenticated;

create or replace function public.transitionner_groupe_classes(
  p_groupe_id uuid,
  p_etat text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_groupe public.groupes;
  v_membres int;
  v_minimum smallint := public.app_config_int('groupe.minimum_lancement', 3)::smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'transition de groupe reservee a l''administration';
  end if;

  if p_etat not in ('ready', 'publiee', 'active') then
    raise exception 'etat de publication inconnu : %', coalesce(p_etat, 'aucun');
  end if;

  select * into v_groupe
  from public.groupes
  where id = p_groupe_id and ended_at is null
  for update;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  if v_groupe.etat = 'brouillon' and p_etat not in ('ready', 'publiee') then
    raise exception 'un brouillon doit passer par ready avant active';
  end if;
  if v_groupe.etat = 'ready' and p_etat = 'active' then
    raise exception 'un groupe ready doit passer par publiee avant active';
  end if;
  if v_groupe.etat in ('publiee', 'active') and p_etat = 'ready' then
    raise exception 'retour vers ready interdit pour un groupe publie';
  end if;

  if v_groupe.teacher_id is null then
    raise exception 'un groupe publie exige un titulaire';
  end if;

  select count(*)::int into v_membres
  from public.groupe_membres m
  where m.groupe_id = p_groupe_id and m.left_at is null;

  if v_membres < v_minimum then
    raise exception 'un groupe se publie a partir de % eleves, % fournis',
      v_minimum, v_membres;
  end if;
  if v_membres > v_groupe.seuil_max then
    raise exception 'la capacite du groupe est depassee';
  end if;

  -- Pour un groupe issu d'une offre, la cle de dispatch reste vraie apres la
  -- validation Admin : langue, cohorte et niveau officiel ne peuvent diverger.
  if v_groupe.offre_id is not null and exists (
    select 1
    from public.groupe_membres m
    join public.student_profiles sp on sp.profile_id = m.student_id
    where m.groupe_id = p_groupe_id and m.left_at is null
      and (
        sp.langue_cours is distinct from v_groupe.langue_code
        or sp.cohorte is distinct from v_groupe.cohorte
        or (
          v_groupe.niveau_id is null
          and exists (
            select 1 from public.progression_historique h
            where h.student_id = m.student_id
          )
        )
        or (
          v_groupe.niveau_id is not null
          and not exists (
            select 1 from public.progression_historique h
            where h.student_id = m.student_id
              and h.niveau_id = v_groupe.niveau_id
          )
        )
      )
  ) then
    raise exception 'les membres du groupe ne sont plus compatibles';
  end if;

  update public.groupes
  set etat = p_etat
  where id = p_groupe_id;

  perform public.log_sensitive_access(
    'groupe_etat_change', 'groupes', p_groupe_id::text,
    jsonb_build_object('etat', p_etat, 'membres', v_membres)
  );
end;
$function$;

revoke execute on function public.transitionner_groupe_classes(uuid, text)
  from public, anon, agent_ro;
grant execute on function public.transitionner_groupe_classes(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
commit;
