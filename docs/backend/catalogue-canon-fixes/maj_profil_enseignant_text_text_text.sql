CREATE OR REPLACE FUNCTION public.maj_profil_enseignant(p_country text DEFAULT NULL::text, p_languages text[] DEFAULT NULL::text[], p_timezone text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentification requise';
  end if;

  -- Le fuseau fait loi sur la grille de disponibilites : un libelle absent de
  -- la base de fuseaux casserait mon_fuseau() sans erreur visible. Il se
  -- verifie donc ici, pas a l'ecran.
  if p_timezone is not null
     and not exists (
       select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone
     ) then
    raise exception 'fuseau inconnu';
  end if;

  update public.teacher_profiles t
     set country = coalesce(p_country, t.country),
         languages = coalesce(p_languages, t.languages),
         timezone_iana = coalesce(p_timezone, t.timezone_iana)
   where t.profile_id = v_uid
     and t.deleted_at is null;

  if not found then
    raise exception 'aucun profil enseignant';
  end if;
end;
$function$

