CREATE OR REPLACE FUNCTION public.revoquer_jeton_agent(p_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_libelle text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'revocation reservee a l administration'
      using errcode = '42501';
  end if;

  update public.jetons_agent
     set revoque_le = now(), revoque_par = auth.uid()
   where id = p_id and revoque_le is null
  returning libelle into v_libelle;

  if v_libelle is null then
    return false;
  end if;

  perform public.log_sensitive_access(
    'agent_token_revoked', 'jetons_agent', p_id::text,
    jsonb_build_object('libelle', v_libelle)
  );
  return true;
end;
$function$

