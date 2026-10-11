CREATE OR REPLACE FUNCTION public.doit_demander_feedback(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance    public.sessions%rowtype;
  v_cadence   int := public.app_config_int('feedback_cadence_seances', 4);
  v_rang      int;
  v_sel       text;
  v_empreinte bytea;
  v_repondu   boolean;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found or v_cadence <= 0 then
    return null;
  end if;

  if not exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id and sp.profile_id = auth.uid()
      and sp.role = 'student' and sp.deleted_at is null
  ) then
    return null;
  end if;

  select count(*) into v_rang
    from public.sessions s
    join public.session_participants sp on sp.session_id = s.id
   where s.groupe_id = v_seance.groupe_id
     and sp.profile_id = auth.uid()
     and sp.role = 'student'
     and sp.deleted_at is null
     and s.deleted_at is null
     and s.started_at <= v_seance.started_at;

  if v_rang % v_cadence <> 0 then
    return null;
  end if;

  select (value #>> '{}') into v_sel from public.app_config where key = 'feedback_empreinte_sel';
  v_empreinte := extensions.digest(p_session_id::text || auth.uid()::text || coalesce(v_sel, ''), 'sha256');

  select exists (
    select 1 from public.session_feedback f
    where f.session_id = p_session_id and f.auteur_empreinte = v_empreinte
  ) into v_repondu;

  return jsonb_build_object(
    'groupe_id', v_seance.groupe_id,
    'rang_seance', v_rang,
    'deja_repondu', v_repondu
  );
end;
$function$

