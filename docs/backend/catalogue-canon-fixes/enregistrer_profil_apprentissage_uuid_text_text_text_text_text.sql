CREATE OR REPLACE FUNCTION public.enregistrer_profil_apprentissage(p_membre_id uuid, p_langue_code text, p_cohorte text, p_niveau_declare text, p_objectif text, p_fuseau_iana text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_cohorte public.cohortes_age;
  v_foyer uuid;
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  select * into v_cohorte from public.cohortes_age
  where code = p_cohorte and actif;
  if not found then
    raise exception 'cohorte inconnue ou retiree : %', coalesce(p_cohorte, 'aucune');
  end if;

  if not exists (
    select 1 from public.langues_cours where code = p_langue_code and actif
  ) then
    raise exception 'langue de cours inconnue ou retiree : %', coalesce(p_langue_code, 'aucune');
  end if;

  if coalesce(btrim(p_fuseau_iana), '') = '' then
    raise exception 'un fuseau est requis : c''est lui qui fixe l''heure affichee';
  end if;

  -- Un fuseau doit exister : sans ce controle, une chaine fantaisiste ferait
  -- echouer chaque conversion d'horaire plus tard, loin de sa cause.
  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana
  ) then
    raise exception 'fuseau IANA inconnu : %', p_fuseau_iana;
  end if;

  update public.student_profiles set
    langue_cours = p_langue_code,
    cohorte = p_cohorte,
    niveau_declare = p_niveau_declare,
    objectif = p_objectif,
    student_type = v_cohorte.student_type,
    interface_mode = v_cohorte.interface_mode,
    onboarding_fait_le = now()
  where profile_id = p_membre_id and deleted_at is null;

  if not found then
    raise exception 'aucune fiche eleve vivante pour ce profil';
  end if;

  select p.household_id into v_foyer from public.profiles p where p.id = p_membre_id;
  if v_foyer is not null then
    update public.households set timezone = p_fuseau_iana
    where id = v_foyer and deleted_at is null;
  end if;

  perform public.log_sensitive_access(
    'profil_apprentissage_enregistre', 'student_profiles', p_membre_id::text,
    jsonb_build_object('langue', p_langue_code, 'cohorte', p_cohorte,
                       'niveau_declare', p_niveau_declare, 'objectif', p_objectif,
                       'fuseau', p_fuseau_iana)
  );
end;
$function$

