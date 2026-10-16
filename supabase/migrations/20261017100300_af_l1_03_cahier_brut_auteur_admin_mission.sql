-- Audit final 16/10/2026, lot L1-03 (P0-2 cahier, P2-1). Le cahier brut est la
-- note de travail de l'enseignant. La famille lit la projection
-- (seance_resumes, 0054), pas la source. Le controleur ne lit que les seances
-- de ses missions ouvertes.
begin;

-- « Controleur en mission sur cette seance » : une ligne de
-- private.controle_missions a son nom, ouverte (attribuee ou en_cours) et dont
-- l'echeance n'est pas passee, comme ma_mission_controle(). La table est dans
-- `private`, que `authenticated` ne peut pas lire : la fonction est definer.
-- Elle vit dans app_private (schema non expose par PostgREST, usage accorde a
-- authenticated par 0073) parce qu'une policy s'evalue avec les droits de
-- l'appelant : il lui faut EXECUTE, sans que ce soit une RPC.
create or replace function app_private.af_controleur_en_mission(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
      from private.controle_missions m
     where m.session_id = p_session_id
       and m.controleur_id = auth.uid()
       and m.statut in ('attribuee', 'en_cours')
       and m.echeance > pg_catalog.statement_timestamp()
  );
$function$;

revoke all on function app_private.af_controleur_en_mission(uuid)
  from public, anon, agent_ro;
grant execute on function app_private.af_controleur_en_mission(uuid)
  to authenticated;

alter policy lesson_reports_reader on public.lesson_reports
  using (
    public.app_account_valid() and deleted_at is null
    and (
      (public.app_role() = 'teacher' and author_profile_id = auth.uid())
      or public.app_role() = 'admin'
      or (public.app_role() = 'controller'
          and app_private.af_controleur_en_mission(session_id))
    )
  );

alter policy makharij_findings_read on public.makharij_findings
  using (
    public.app_account_valid() and deleted_at is null
    and exists (
      select 1 from public.lesson_reports lr
       where lr.id = makharij_findings.lesson_report_id and lr.deleted_at is null
         and (
           (public.app_role() = 'teacher' and lr.author_profile_id = auth.uid())
           or public.app_role() = 'admin'
           or (public.app_role() = 'controller'
               and app_private.af_controleur_en_mission(lr.session_id))
         )
    )
  );

do $postflight$
declare v_q text;
begin
  select qual into v_q from pg_policies
   where schemaname = 'public' and tablename = 'lesson_reports' and policyname = 'lesson_reports_reader';
  if v_q is null or v_q like '%session_in_household%' or v_q like '%session_has_participant%' then
    raise exception 'L1-03 postflight: la famille lit encore le cahier brut';
  end if;
  select qual into v_q from pg_policies
   where schemaname = 'public' and tablename = 'makharij_findings' and policyname = 'makharij_findings_read';
  if v_q is null or v_q like '%session_in_household%' or v_q like '%session_has_participant%' then
    raise exception 'L1-03 postflight: la famille lit encore les constats de prononciation';
  end if;
end $postflight$;

commit;
