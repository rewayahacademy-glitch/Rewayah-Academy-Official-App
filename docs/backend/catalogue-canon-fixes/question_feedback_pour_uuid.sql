CREATE OR REPLACE FUNCTION public.question_feedback_pour(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_groupe uuid;
  v_debut timestamptz;
  v_cadence integer := public.app_config_int('feedback_cadence_seances', 4);
  v_seuil integer := public.app_config_int('feedback_seuil_tendance', 5);
  v_sel text;
  v_hash bytea;
  v_empreinte bytea;
  v_bucket bigint;
  v_last_question text;
  v_question public.feedback_questions%rowtype;
  v_n integer;
  v_offset integer;
begin
  if auth.uid() is null or not coalesce(public.app_account_valid(), false)
     or p_session_id is null or v_cadence <= 0 or v_seuil <= 0 then
    return null;
  end if;

  select s.groupe_id, s.started_at into v_groupe, v_debut
  from public.sessions s
  join public.session_participants sp on sp.session_id = s.id
  where s.id = p_session_id and s.deleted_at is null
    and sp.profile_id = auth.uid() and sp.role = 'student'
    and sp.deleted_at is null;
  if not found or v_groupe is null then
    return null;
  end if;

  select (c.value #>> '{}') into v_sel
  from public.app_config c where c.key = 'feedback_empreinte_sel';
  v_sel := coalesce(v_sel, '');

  v_hash := extensions.digest(v_sel || '|' || auth.uid()::text || '|' || p_session_id::text, 'sha256');
  v_bucket := get_byte(v_hash, 0)::bigint * 16777216
            + get_byte(v_hash, 1)::bigint * 65536
            + get_byte(v_hash, 2)::bigint * 256
            + get_byte(v_hash, 3)::bigint;
  if mod(v_bucket, v_cadence::bigint) <> 0 then
    return null;
  end if;

  v_empreinte := extensions.digest(p_session_id::text || auth.uid()::text || v_sel, 'sha256');
  if exists (
    select 1 from public.session_feedback f
    where f.session_id = p_session_id and f.auteur_empreinte = v_empreinte
  ) then
    return null;
  end if;

  -- La rotation ne conserve pas d'identifiant transversal : elle recalcule
  -- l'empreinte de l'appelant pour ses seules seances precedentes du groupe.
  select f.question_id into v_last_question
  from public.session_feedback f
  join public.sessions s on s.id = f.session_id
  join public.feedback_questions q on q.id = f.question_id and q.active
  where f.groupe_id = v_groupe and s.started_at < v_debut
    and f.auteur_empreinte = extensions.digest(s.id::text || auth.uid()::text || v_sel, 'sha256')
  order by s.started_at desc, s.id desc
  limit 1;

  select count(*) into v_n from public.feedback_questions q where q.active;
  if v_n = 0 then return null; end if;
  v_offset := mod(v_bucket, v_n::bigint)::integer;

  if v_last_question is not null then
    select q.* into v_question from public.feedback_questions q
    where q.active and q.id > v_last_question order by q.id limit 1;
  end if;
  if v_question.id is null then
    select q.* into v_question from public.feedback_questions q
    where q.active order by q.id offset v_offset limit 1;
  end if;
  if v_question.id is null then
    select q.* into v_question from public.feedback_questions q
    where q.active order by q.id limit 1;
  end if;

  return jsonb_build_object(
    'id', v_question.id,
    'intitule', v_question.intitule,
    'libelles', v_question.libelles
  );
end;
$function$

