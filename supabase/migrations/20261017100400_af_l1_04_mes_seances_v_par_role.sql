-- Audit final 16/10/2026, lot L1-04 (P0-2 fratrie). `mes_seances_v` ouvrait
-- une ligne si la session appartenait au foyer de l'appelant, quel que soit son
-- role : un enfant lisait les seances de ses freres et soeurs. Meme colonnes,
-- meme security_barrier ; seule la clause d'acces change : une clause par role.
-- agent_ro n'a pas de clause propre dans 0014 : il recoit les memes clauses que
-- le role porte par son jeton (app_metadata.role), comme avant.
begin;

create or replace view public.mes_seances_v
with (security_barrier = true)
as
select
  s.id as session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  s.prayer_pause_minutes,
  eleve.id as student_id,
  case when public.agent_identite_masquee()
       then eleve.immutable_id else eleve.first_name end as student_first_name,
  eleve.immutable_id as student_immutable_id,
  ens.id as teacher_id,
  case when public.agent_identite_masquee()
       then ens.immutable_id else ens.first_name end as teacher_first_name,
  ens.immutable_id as teacher_immutable_id
from public.sessions s
join public.session_participants spe
  on spe.session_id = s.id and spe.role = 'student' and spe.deleted_at is null
join public.profiles eleve on eleve.id = spe.profile_id and eleve.deleted_at is null
join public.profiles ens on ens.id = s.teacher_id and ens.deleted_at is null
where s.deleted_at is null
  and public.app_account_valid()
  and (
    (public.app_role() = 'teacher' and s.teacher_id = auth.uid())
    or (public.app_role() = 'student' and spe.profile_id = auth.uid())
    or (
      public.app_role() = 'guardian'
      and eleve.household_id is not null
      and eleve.household_id = public.app_household_id()
    )
    or public.app_role() in ('admin', 'controller')
  );

do $postflight$
declare v_def text;
begin
  v_def := pg_get_viewdef('public.mes_seances_v'::regclass, true);
  if v_def not like '%guardian%' or v_def not like '%app_account_valid%' then
    raise exception 'L1-04 postflight: la vue ne filtre pas par role';
  end if;
end $postflight$;

commit;
