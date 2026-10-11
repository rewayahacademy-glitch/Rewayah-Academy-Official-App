CREATE OR REPLACE FUNCTION public.soumettre_feedback(p_session_id uuid, p_question_id text, p_reponse text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_groupe uuid;
  v_sel text;
  v_empreinte bytea;
  v_question jsonb;
begin
  if auth.uid() is null or p_session_id is null
     or p_question_id is null
     or p_reponse is null or p_reponse not in ('difficile', 'bien', 'tres_bien')
     or not coalesce(public.app_account_valid(), false) then
    raise exception 'feedback invalide' using errcode = '42501';
  end if;

  select (c.value #>> '{}') into v_sel
  from public.app_config c where c.key = 'feedback_empreinte_sel';
  v_empreinte := extensions.digest(p_session_id::text || auth.uid()::text || coalesce(v_sel, ''), 'sha256');
  if exists (
    select 1 from public.session_feedback f
    where f.session_id = p_session_id and f.auteur_empreinte = v_empreinte
  ) then
    raise exception 'feedback deja depose' using errcode = '23505';
  end if;

  v_question := public.question_feedback_pour(p_session_id);
  if v_question is null or v_question ->> 'id' is distinct from p_question_id then
    raise exception 'question de feedback indisponible' using errcode = '42501';
  end if;
  select s.groupe_id into v_groupe from public.sessions s
  where s.id = p_session_id and s.deleted_at is null;
  if v_groupe is null then
    raise exception 'seance indisponible' using errcode = '42501';
  end if;

  insert into public.session_feedback(session_id, groupe_id, question_id, reponse)
  values (p_session_id, v_groupe, p_question_id, p_reponse);
end;
$function$

