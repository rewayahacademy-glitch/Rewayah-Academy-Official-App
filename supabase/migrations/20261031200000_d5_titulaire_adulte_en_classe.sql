-- D5 (RELIQUATS-B1-B2, ordre du directeur du 30/10/2026) : l'adulte qui
-- apprend pour lui-meme entre dans une classe adulte.
--
-- Un adulte titulaire reste un compte `guardian` avec un `student_profiles`
-- sur lui-meme (`student_type = 'autonomous'`, `inscrire_titulaire`,
-- 20261029150000). « Ajouter un eleve » ne proposait que `role = 'student'`,
-- et `ajouter_eleve_groupe` refusait tout autre role : la direction ne pouvait
-- mettre aucun adulte dans une classe, alors que les adultes sont la moitie de
-- l'offre.
--
-- Plus petite correction, cote serveur, sans changer le role ni la RLS :
--   1. `ajouter_eleve_groupe` accepte aussi un tel adulte, et seulement dans
--      une classe adulte de son genre (classe mixte : genre `indetermine`).
--      Le chemin d'un `student` est inchange.
--   2. `eleves_proposables_classe(p_groupe_id)` rend a la direction la liste a
--      proposer pour CETTE classe : les eleves comme avant, plus les adultes
--      titulaires compatibles. Lecture seule (STABLE), reservee a la direction.
--
-- La suite marche deja : `seance_a_rejoindre` admet le membre lui-meme
-- (`m.student_id = auth.uid()`), `materialiser_seances_groupe` l'inscrit
-- comme participant `student`, et `autoriser_jeton_video` prend le role de
-- `session_participants`, jamais celui du compte.
--
-- Ni DELETE, ni DROP, ni TRUNCATE.

begin;

create or replace function public.ajouter_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
      and (
        p.role = 'student'
        -- D5 : l'adulte titulaire, dans une classe adulte de son genre.
        or (
          p.role = 'guardian'
          and exists (
            select 1 from public.student_profiles sp
            where sp.profile_id = p.id
              and sp.student_type = 'autonomous'
              and sp.deleted_at is null
          )
          and exists (
            select 1 from public.groupes g
            where g.id = p_groupe_id
              and g.type_public = 'adulte'
              and (g.genre_public = 'indetermine'
                   or (g.genre_public = 'hommes' and p.gender = 'male')
                   or (g.genre_public = 'femmes' and p.gender = 'female'))
          )
        )
      )
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if exists (
    select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null
  ) then
    raise exception 'cet eleve appartient deja a un groupe actif';
  end if;

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);

  perform public.log_sensitive_access(
    'eleve_ajoute_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create function public.eleves_proposables_classe(p_groupe_id uuid)
returns table(
  profile_id uuid,
  immutable_id text,
  prenom text,
  nom text,
  adulte_titulaire boolean
)
language sql
stable
security definer
set search_path = ''
as $function$
  select p.id, p.immutable_id, p.first_name, p.last_name, p.role = 'guardian'
  from public.profiles p
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and (
      p.role = 'student'
      or (
        p.role = 'guardian'
        and exists (
          select 1 from public.student_profiles sp
          where sp.profile_id = p.id
            and sp.student_type = 'autonomous'
            and sp.deleted_at is null
        )
        and exists (
          select 1 from public.groupes g
          where g.id = p_groupe_id
            and g.type_public = 'adulte'
            and (g.genre_public = 'indetermine'
                 or (g.genre_public = 'hommes' and p.gender = 'male')
                 or (g.genre_public = 'femmes' and p.gender = 'female'))
        )
      )
    );
$function$;

comment on function public.eleves_proposables_classe(uuid) is
  'D5 (30/10/2026) : les personnes que la direction peut ajouter a cette classe. '
  'Eleves actifs, plus les adultes titulaires (guardian avec student_profiles '
  'autonome sur lui-meme) si la classe est adulte et de leur genre. '
  'Vide pour qui n''est pas la direction.';

revoke all on function public.eleves_proposables_classe(uuid) from public, anon;
grant execute on function public.eleves_proposables_classe(uuid) to authenticated;

commit;
