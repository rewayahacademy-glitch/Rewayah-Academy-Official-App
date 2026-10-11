CREATE OR REPLACE FUNCTION public.signaler_horaire_insatisfait(p_membre_id uuid, p_detail jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_role public.app_role := public.app_role();
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  if v_role is null then
    raise exception 'compte sans role';
  end if;

  insert into public.matching_requests
    (kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
  values
    ('horaire_insatisfait', p_membre_id, 'offre_horaire',
     coalesce(p_detail, '{}'::jsonb),
     'aucun horaire propose ne convient a ce foyer',
     auth.uid(), v_role)
  returning id into v_id;

  perform public.log_sensitive_access(
    'horaire_insatisfait_signale', 'matching_requests', v_id::text,
    jsonb_build_object('eleve_id', p_membre_id, 'detail', coalesce(p_detail, '{}'::jsonb))
  );

  return v_id;
end;
$function$

