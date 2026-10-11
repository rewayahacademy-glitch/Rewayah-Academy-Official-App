CREATE OR REPLACE FUNCTION public.tendance_feedback_comprehension(p_groupe_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_n integer;
  v_seuil integer := public.app_config_int('feedback_seuil_tendance', 5);
  v_difficile integer;
  v_bien integer;
  v_tres_bien integer;
  v_visible boolean;
begin
  if p_groupe_id is null or not coalesce(public.app_account_valid(), false)
     or not coalesce(
       public.app_role() = 'admin'
       or (public.app_role() = 'teacher' and exists (
         select 1 from public.groupes g
         where g.id = p_groupe_id and g.teacher_id = auth.uid() and g.ended_at is null
       )),
       false
     ) then
    raise exception 'tendance reservee a l''enseignant du groupe ou a l''administration'
      using errcode = '42501';
  end if;

  select count(*)::integer,
         count(*) filter (where f.reponse = 'difficile')::integer,
         count(*) filter (where f.reponse = 'bien')::integer,
         count(*) filter (where f.reponse = 'tres_bien')::integer
    into v_n, v_difficile, v_bien, v_tres_bien
  from public.session_feedback f
  where f.groupe_id = p_groupe_id and f.question_id = 'comprehension';
  v_visible := v_n >= greatest(v_seuil, 1);

  return jsonb_build_object(
    'groupe_id', p_groupe_id,
    'nombre_echantillons', v_n,
    'seuil_minimum', greatest(v_seuil, 1),
    'visible_par_enseignant', v_visible,
    'repartition', case when v_visible then jsonb_build_object(
      'difficile', v_difficile::numeric / v_n,
      'bien', v_bien::numeric / v_n,
      'tres_bien', v_tres_bien::numeric / v_n
    ) else null end
  );
end;
$function$

