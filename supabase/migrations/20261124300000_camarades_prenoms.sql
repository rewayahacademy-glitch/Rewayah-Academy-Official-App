-- CAMARADES (directeur, 12/11/2026) : les eleves d'une Classe se voient par
-- leur photo et leur prenom.
--
-- Decision du directeur, dite par lui : « Il faut que les autres eleves
-- voient celui qui recite, au moins une partie du nom, la photo, car ils
-- partagent une salle ; psychologiquement, s'ils ne se voient pas, ca risque
-- de creer d'autres problemes ; mais la vraie video, c'est seulement celui
-- qui recite ; sinon on ne voit que sa photo. »
--
-- Elle amende la regle « un enfant ne lit pas le prenom d'un camarade »
-- (PHOTOS-2b, pilote, 04/11/2026). La photo d'un camarade est deja lisible
-- (K-44 du 09/10, `private.photo_visible_par`) ; seul le prenom manquait :
-- `participants_classe_eleve_adulte()` (20261102700000) ne le rend qu'a
-- l'eleve adulte autonome (`ma_capacite_eleve()`).
--
-- Une lecture, STABLE, SECURITY DEFINER, search_path vide, objets
-- qualifies, EXECUTE pour authenticated seulement. Elle complete la
-- precedente, qui ne change pas (meme signature, meme type de retour) :
-- `camarades_classe_eleve()` rend a TOUT eleve (mineur ou adulte, y compris
-- l'enfant ouvert par un appareil jumele, dont la session porte son propre
-- profil : `session-enfant` ouvre une vraie session de son compte, donc
-- auth.uid() est l'enfant) les membres actifs de SA Classe active :
--   * `profile_id`, pour relier l'identite LiveKit au prenom ;
--   * `prenom` : le prenom seul (`first_name`) ;
--   * `est_moi`.
-- Rien d'autre : ni nom de famille, ni matricule, ni cle de photo, ni age,
-- ni foyer. L'appelant ne passe aucun identifiant : tout part de auth.uid().
--
-- Porte positive : compte valide (`app_account_valid()`) ET profil d'eleve
-- vivant (`student_profiles`), sinon refus 42501. Un tuteur qui n'apprend
-- pas, un enseignant, la direction ont leurs propres lectures (presence de
-- la seance, Classes de l'enseignant, listes de la direction) : ils sont
-- refuses ici plutot que de recevoir une liste vide, pour qu'un appel
-- detourne se voie. Un eleve sans Classe active (retire, Classe close) ne
-- recoit aucune ligne.
--
-- Additive : aucun objet efface, aucune ligne retiree, aucune table videe.
-- Rejouable : `create or replace` et droits reposes.

begin;

create or replace function public.camarades_classe_eleve()
returns table(profile_id uuid, prenom text, est_moi boolean)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_autorise boolean;
  v_groupe uuid;
begin
  v_autorise := coalesce(
    public.app_account_valid()
    and exists (
      select 1
        from public.student_profiles sp
       where sp.profile_id = auth.uid()
         and sp.deleted_at is null),
    false);
  if not v_autorise then
    raise exception 'lecture des camarades refusee' using errcode = '42501';
  end if;

  -- Sa Classe active : une seule (`ajouter_eleve_groupe` refuse un second
  -- groupe actif) ; la plus recente par prudence.
  select mm.groupe_id
    into v_groupe
    from public.groupe_membres mm
    join public.groupes g on g.id = mm.groupe_id and g.ended_at is null
   where mm.student_id = auth.uid()
     and mm.left_at is null
   order by mm.joined_at desc
   limit 1;

  if v_groupe is null then
    return;
  end if;

  return query
    select p.id, p.first_name, p.id = auth.uid()
      from public.groupe_membres m
      join public.profiles p
        on p.id = m.student_id
       and p.deleted_at is null
       and p.account_status in ('active', 'provisional_active')
     where m.groupe_id = v_groupe
       and m.left_at is null
     order by (p.id = auth.uid()) desc, p.first_name, p.id;
end;
$function$;

do $droits$
declare
  v_oid pg_catalog.regprocedure := 'public.camarades_classe_eleve()'::pg_catalog.regprocedure;
  v_role text;
begin
  execute pg_catalog.format('alter function %s owner to postgres', v_oid);
  execute pg_catalog.format('revoke all on function %s from public', v_oid);
  foreach v_role in array array['anon', 'service_role', 'agent_ro'] loop
    if exists (select 1 from pg_catalog.pg_roles where rolname = v_role) then
      execute pg_catalog.format('revoke all on function %s from %I', v_oid, v_role);
    end if;
  end loop;
  execute pg_catalog.format('grant execute on function %s to authenticated', v_oid);
  execute pg_catalog.format('comment on function %s is %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-12. CAMARADES (directeur, 12/11/2026) : prenom seul des membres actifs de la Classe active de l''eleve, porte app_account_valid() et profil d''eleve.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
end;
$droits$;

do $verification$
declare
  v_sig constant text := 'public.camarades_classe_eleve()';
  v_role text;
begin
  if (select p.provolatile from pg_catalog.pg_proc p
       where p.oid = v_sig::pg_catalog.regprocedure) <> 's' then
    raise exception '% doit etre STABLE (aucune ecriture)', v_sig;
  end if;
  if not (select p.prosecdef from pg_catalog.pg_proc p
           where p.oid = v_sig::pg_catalog.regprocedure) then
    raise exception '% doit etre SECURITY DEFINER', v_sig;
  end if;
  if not exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid = v_sig::pg_catalog.regprocedure
       and p.proconfig @> array['search_path=""']) then
    raise exception '% doit fixer search_path vide', v_sig;
  end if;
  foreach v_role in array array['anon', 'public', 'agent_ro', 'service_role'] loop
    if (v_role = 'public' or exists (select 1 from pg_catalog.pg_roles where rolname = v_role))
       and pg_catalog.has_function_privilege(v_role, v_sig, 'EXECUTE') then
      raise exception '% ouverte a %', v_sig, v_role;
    end if;
  end loop;
  if not pg_catalog.has_function_privilege('authenticated', v_sig, 'EXECUTE') then
    raise exception '% fermee a authenticated', v_sig;
  end if;
  -- Trois colonnes, et pas une de plus.
  if (select pg_catalog.array_agg(a order by n)
        from pg_catalog.pg_proc p,
             unnest(p.proargnames, p.proargmodes::text[]) with ordinality as x(a, m, n)
       where p.oid = v_sig::pg_catalog.regprocedure and x.m = 't')
     is distinct from array['profile_id', 'prenom', 'est_moi']::text[] then
    raise exception '% : colonnes inattendues', v_sig;
  end if;
end;
$verification$;

commit;
