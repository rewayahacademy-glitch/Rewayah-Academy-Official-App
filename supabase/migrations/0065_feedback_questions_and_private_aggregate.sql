-- 0065 — questions de feedback, echantillonnage prive et tendance comprehension seulement.
begin;

create table public.feedback_questions (
  id text primary key,
  intitule text not null check (pg_catalog.btrim(intitule) <> ''),
  libelles jsonb not null check (
    pg_catalog.jsonb_typeof(libelles) = 'object'
    and libelles ? 'difficile' and libelles ? 'bien' and libelles ? 'tres_bien'
    and (libelles - array['difficile', 'bien', 'tres_bien']) = '{}'::jsonb
  ),
  active boolean not null default true
);
alter table public.feedback_questions enable row level security;
revoke all on public.feedback_questions from public, anon, authenticated, agent_ro;

insert into public.feedback_questions (id, intitule, libelles) values
  ('comprehension', 'Avez-vous compris la leçon ?',
   '{"difficile":"Difficile","bien":"Bien","tres_bien":"Très bien"}'),
  ('rythme', 'Le rythme de la séance était…',
   '{"difficile":"Trop lent","bien":"Juste","tres_bien":"Trop rapide"}'),
  ('participation', 'Avez-vous pu participer ?',
   '{"difficile":"Peu","bien":"Assez","tres_bien":"Beaucoup"}')
on conflict (id) do update
set intitule = excluded.intitule, libelles = excluded.libelles, active = true;

-- Aucun client, y compris l'administration, ne lit les reponses une a une.
drop policy if exists session_feedback_admin on public.session_feedback;
revoke all on public.session_feedback from public, anon, authenticated, agent_ro;

-- Le seul agregat disponible au contrat courant est la comprehension.
create or replace view public.tendance_feedback_v
with (security_barrier = true)
as
select
  f.groupe_id,
  f.question_id,
  count(*) as nombre_echantillons,
  count(*) filter (where f.reponse = 'difficile') as n_difficile,
  count(*) filter (where f.reponse = 'bien') as n_bien,
  count(*) filter (where f.reponse = 'tres_bien') as n_tres_bien
from public.session_feedback f
join public.groupes g on g.id = f.groupe_id
where f.question_id = 'comprehension'
  and (g.teacher_id = auth.uid() or public.app_role() = 'admin')
group by f.groupe_id, f.question_id
having count(*) >= public.app_config_int('feedback_seuil_tendance', 5);
revoke all on public.tendance_feedback_v from public, anon, agent_ro;
grant select on public.tendance_feedback_v to authenticated;

create or replace function public.question_feedback_pour(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
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
$function$;

create or replace function public.soumettre_feedback(
  p_session_id uuid,
  p_question_id text,
  p_reponse text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
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
$function$;

create or replace function public.tendance_feedback_comprehension(p_groupe_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
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
$function$;

revoke all on function public.question_feedback_pour(uuid) from public, anon, agent_ro;
grant execute on function public.question_feedback_pour(uuid) to authenticated;
revoke all on function public.soumettre_feedback(uuid, text, text) from public, anon, agent_ro;
grant execute on function public.soumettre_feedback(uuid, text, text) to authenticated;
revoke all on function public.tendance_feedback_comprehension(uuid) from public, anon, agent_ro;
grant execute on function public.tendance_feedback_comprehension(uuid) to authenticated;

commit;
