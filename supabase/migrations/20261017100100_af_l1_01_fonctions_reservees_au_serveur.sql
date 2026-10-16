-- Audit final 16/10/2026, lot L1-01 (P0-1, P1-2, P1-3).
-- Ces trois fonctions n'ont qu'un appelant legitime : le serveur (service_role)
-- ou une fonction SECURITY DEFINER. Sur Supabase, `authenticated` recevait EXECUTE
-- par privilege par defaut, et 0001/0005 ne le retiraient pas (un `revoke from
-- public` ne touche pas un grant explicite).
--
-- Deux triggers INVOKER appelaient log_sensitive_access sous le role de
-- l'administrateur qui ecrit : ils passent en SECURITY DEFINER pour rester
-- fonctionnels. Corps inchange, qualification complete ; la garde de
-- x217_valider_politique_coffres est conservee telle quelle ; aucune garde
-- n'est ajoutee a auditer_regle_remuneration_enseignant (decision de
-- l'orchestrateur, 17/10/2026). Ces deux fonctions ne sont appelables que par
-- le moteur des triggers : aucun role n'en recoit EXECUTE.
begin;

create or replace function public.auditer_regle_remuneration_enseignant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
BEGIN
  PERFORM public.log_sensitive_access(
    'regle_remuneration_creee',
    'regles_remuneration_enseignant',
    NEW.id::text,
    jsonb_build_object(
      'enseignant_id', NEW.enseignant_id,
      'taux_minor_par_heure', NEW.taux_minor_par_heure,
      'devise', NEW.devise,
      'date_effet', NEW.date_effet,
      'motif', NEW.motif
    )
  );
  RETURN NEW;
END;
$function$;

create or replace function public.x217_valider_politique_coffres()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
BEGIN
  IF TG_OP<>'INSERT' OR NOT coalesce(public.app_account_valid()
       AND public.app_role()='admin' AND auth.jwt()->>'aal'='aal2'
       AND NEW.cree_par=auth.uid(),false) THEN
    RAISE EXCEPTION 'politique_allocation_modification_refusee' USING ERRCODE='42501';
  END IF;
  PERFORM public.log_sensitive_access('politique_allocation_coffres_creee',
    'politique_allocation_coffres',NEW.id::text,
    jsonb_build_object('date_effet',NEW.date_effet,
      'taux_taxes_permille',NEW.taux_taxes_permille,
      'taux_charges_permille',NEW.taux_charges_permille,
      'taux_reserve_permille',NEW.taux_reserve_permille));
  RETURN NEW;
END;
$function$;

revoke execute on function public.auditer_regle_remuneration_enseignant(),
  public.x217_valider_politique_coffres()
  from public, anon, authenticated;

revoke execute on function public.record_session_event(uuid, uuid, public.session_event_type, text)
  from public, anon, authenticated, agent_ro;
grant execute on function public.record_session_event(uuid, uuid, public.session_event_type, text)
  to service_role;

revoke execute on function public.log_sensitive_access(text, text, text, jsonb)
  from public, anon, authenticated, agent_ro;
grant execute on function public.log_sensitive_access(text, text, text, jsonb)
  to service_role;

revoke execute on function public.materialiser_seances(uuid)
  from public, anon, authenticated, agent_ro;
grant execute on function public.materialiser_seances(uuid)
  to service_role;

do $postflight$
begin
  if has_function_privilege('authenticated', 'public.record_session_event(uuid,uuid,public.session_event_type,text)', 'execute')
     or has_function_privilege('authenticated', 'public.log_sensitive_access(text,text,text,jsonb)', 'execute')
     or has_function_privilege('authenticated', 'public.materialiser_seances(uuid)', 'execute')
     or not has_function_privilege('service_role', 'public.record_session_event(uuid,uuid,public.session_event_type,text)', 'execute') then
    raise exception 'L1-01 postflight: privileges inattendus';
  end if;
  if not (select p.prosecdef from pg_catalog.pg_proc p
           where p.oid = 'public.auditer_regle_remuneration_enseignant()'::regprocedure)
     or not (select p.prosecdef from pg_catalog.pg_proc p
           where p.oid = 'public.x217_valider_politique_coffres()'::regprocedure) then
    raise exception 'L1-01 postflight: triggers d''audit non SECURITY DEFINER';
  end if;
end $postflight$;

commit;
