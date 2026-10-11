CREATE OR REPLACE FUNCTION public.jetons_agent_actifs()
 RETURNS TABLE(id uuid, libelle text, prefixe text, parcours app_role, profil_observe uuid, observe_identifiant text, observe_prenom text, identite_masquee boolean, expire_le timestamp with time zone, revoque_le timestamp with time zone, cree_le timestamp with time zone, derniere_remise_le timestamp with time zone, remises integer, etat text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$

