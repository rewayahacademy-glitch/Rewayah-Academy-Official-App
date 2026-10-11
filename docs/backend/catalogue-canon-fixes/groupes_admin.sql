CREATE OR REPLACE FUNCTION public.groupes_admin()
 RETURNS TABLE(groupe_id uuid, libelle text, type_public text, seuil_max smallint, teacher_id uuid, teacher_immutable_id text, teacher_prenom text, teacher_nom text, weekday smallint, hour_local smallint, nombre_membres integer, actif boolean, created_at timestamp with time zone, timezone_iana text, couleur_jeton smallint, nom_cours text, programme_niveau_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
    (select count(*)::int from public.groupe_membres m where m.groupe_id = g.id and m.left_at is null),
    g.ended_at is null,
    g.created_at,
    g.timezone_iana,
    g.couleur_jeton,
    g.nom_cours,
    g.programme_niveau_id
  from public.groupes g
  join public.profiles p on p.id = g.teacher_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by (g.ended_at is not null), g.created_at desc;
$function$

