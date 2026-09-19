-- 0019 — Durcissement de securite du lot groupes (0017/0018), releve par revue
--
-- Trois defauts trouves par la revue de code du lot G-01, tous corriges ici :
--
--   1. **`agent_ro` avait recu `EXECUTE` sur les cinq fonctions d'ecriture**
--      (`creer_groupe`, `modifier_groupe`, `ajouter_eleve_groupe`,
--      `retirer_eleve_groupe`, `cloturer_groupe`). L'architecture posee par
--      `0014_acces_agent.sql` construit ce role comme l'intersection stricte
--      « appelable par `authenticated` » ET « stable/immutable » -- jamais
--      volatile -- precisement pour qu'un jeton d'agent ne puisse jamais
--      ecrire, meme quand la personne observee est administratrice. La lecon
--      de 0014/0015/0016 (« accorder `agent_ro` explicitement ») ne
--      s'appliquait qu'aux fonctions de LECTURE (`comptes_admin`,
--      `dossiers_en_attente`...), jamais a une RPC de mutation : la fonction
--      soeur `attribuer_eleve` (0008) n'est grantee qu'a `authenticated`.
--   2. **Aucune des cinq fonctions d'ecriture, ni les deux fonctions de
--      lecture, ne verifiait `app_account_valid()`** en plus du role, alors
--      que c'est la garde constante de toute RPC admin comparable
--      (`attribuer_eleve` 0008, `jetons_agent_actifs` 0016...).
--   3. **`creer_groupe`/`ajouter_eleve_groupe` acceptaient n'importe quel
--      `profiles.id`** comme enseignant ou eleve, sans verifier son role, son
--      compte supprime ou son etat de compte -- contrairement a
--      `attribuer_eleve` qui l'exige explicitement pour l'enseignant.

-- ============================================================
-- 1. Retirer agent_ro des cinq fonctions d'ecriture
-- ============================================================

revoke execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint) from agent_ro;
revoke execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint) from agent_ro;
revoke execute on function public.ajouter_eleve_groupe(uuid, uuid, text) from agent_ro;
revoke execute on function public.retirer_eleve_groupe(uuid, uuid, text) from agent_ro;
revoke execute on function public.cloturer_groupe(uuid, text) from agent_ro;

-- ============================================================
-- 2. app_account_valid() sur les fonctions d'ecriture, et validation du
--    profil enseignant/eleve (meme garde qu'attribuer_eleve, 0008)
-- ============================================================

create or replace function public.creer_groupe(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_weekday smallint,
  p_hour_local smallint,
  p_seuil_max smallint default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  v_seuil := coalesce(
    p_seuil_max,
    case p_type_public
      when 'enfant' then 5
      when 'adulte' then 6
      else null
    end
  );

  if v_seuil is null then
    raise exception 'type de public inconnu : %', p_type_public;
  end if;

  insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
  values (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$;

create or replace function public.modifier_groupe(
  p_groupe_id uuid,
  p_libelle text,
  p_seuil_max smallint,
  p_weekday smallint,
  p_hour_local smallint
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_actifs int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle, seuil_max = p_seuil_max, weekday = p_weekday, hour_local = p_hour_local
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$;

create or replace function public.ajouter_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
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

create or replace function public.retirer_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'retrait d''un eleve d''un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer un eleve d''un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = p_motif
  where groupe_id = p_groupe_id and student_id = p_student_profile_id and left_at is null;

  if not found then
    raise exception 'cet eleve n''est pas membre actif de ce groupe';
  end if;

  perform public.log_sensitive_access(
    'eleve_retire_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create or replace function public.cloturer_groupe(
  p_groupe_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$;

create or replace function public.groupes_admin()
returns table(
  groupe_id uuid,
  libelle text,
  type_public text,
  seuil_max smallint,
  teacher_id uuid,
  teacher_immutable_id text,
  teacher_prenom text,
  teacher_nom text,
  weekday smallint,
  hour_local smallint,
  nombre_membres int,
  actif boolean,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    g.id,
    g.libelle,
    g.type_public,
    g.seuil_max,
    g.teacher_id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    g.weekday,
    g.hour_local,
    (select count(*)::int from public.groupe_membres m where m.groupe_id = g.id and m.left_at is null),
    g.ended_at is null,
    g.created_at
  from public.groupes g
  join public.profiles p on p.id = g.teacher_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by (g.ended_at is not null), g.created_at desc;
$function$;

create or replace function public.groupe_detail(p_groupe_id uuid)
returns table(
  student_id uuid,
  student_immutable_id text,
  student_prenom text,
  student_nom text,
  joined_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    m.joined_at
  from public.groupe_membres m
  join public.profiles p on p.id = m.student_id
  where public.app_role() = 'admin' and public.app_account_valid()
    and m.groupe_id = p_groupe_id
    and m.left_at is null
  order by m.joined_at asc;
$function$;

-- ============================================================
-- 3. Meme garde sur les policies de lecture (branche admin)
-- ============================================================

drop policy groupes_lecture on public.groupes;
create policy groupes_lecture on public.groupes
for select to authenticated
using (
  (public.app_role() = 'admin' and public.app_account_valid())
  or teacher_id = auth.uid()
  or exists (
    select 1 from public.groupe_membres m
    join public.profiles p on p.id = m.student_id
    where m.groupe_id = groupes.id
      and m.left_at is null
      and (p.id = auth.uid() or p.household_id = public.app_household_id())
  )
);

drop policy groupe_membres_lecture on public.groupe_membres;
create policy groupe_membres_lecture on public.groupe_membres
for select to authenticated
using (
  (public.app_role() = 'admin' and public.app_account_valid())
  or exists (
    select 1 from public.groupes g
    where g.id = groupe_membres.groupe_id and g.teacher_id = auth.uid()
  )
  or exists (
    select 1 from public.profiles p
    where p.id = groupe_membres.student_id
      and (p.id = auth.uid() or p.household_id = public.app_household_id())
  )
);
