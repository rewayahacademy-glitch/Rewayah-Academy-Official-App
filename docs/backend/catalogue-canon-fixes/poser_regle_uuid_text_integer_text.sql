CREATE OR REPLACE FUNCTION public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'seul un administrateur pose une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une regle sans motif ne se relit pas six mois plus tard';
  end if;

  -- La precedente se clot, elle ne se remplace pas.
  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(),
      end_reason = 'remplacee : ' || btrim(p_motif)
  where profile_id = p_profile_id and key = p_key and ended_at is null;

  insert into public.rule_overrides (profile_id, key, value, reason, set_by)
  values (p_profile_id, p_key, to_jsonb(p_value), btrim(p_motif), auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access('regle_posee', 'rule_overrides', v_id::text,
    jsonb_build_object('profile_id', p_profile_id, 'key', p_key, 'value', p_value));

  return v_id;
end;
$function$

