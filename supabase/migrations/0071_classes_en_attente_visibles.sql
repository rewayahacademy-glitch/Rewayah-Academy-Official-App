-- 0071 — exposer les classes en attente d'enseignant à l'administration.
begin;

create or replace function public.groupes_admin()
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
  nombre_membres integer,
  actif boolean,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
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
    (select count(*)::integer
       from public.groupe_membres m
      where m.groupe_id = g.id and m.left_at is null),
    g.ended_at is null,
    g.created_at
  from public.groupes g
  left join public.profiles p on p.id = g.teacher_id
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  order by (g.ended_at is not null), g.created_at desc;
$function$;

create or replace function public.classes_a_confirmer_admin()
returns table (
  classe_id uuid,
  libelle text,
  peut_affecter_enseignant boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'acces reserve a l''administration';
  end if;
  return query
  select g.id, g.libelle, true
  from public.groupes g
  where g.teacher_id is null
    and g.etat = 'en_attente_enseignant'
    and g.ended_at is null
  order by g.created_at, g.id;
end;
$function$;
revoke all on function public.classes_a_confirmer_admin()
  from public, anon, agent_ro;
grant execute on function public.classes_a_confirmer_admin()
  to authenticated, service_role;

commit;
