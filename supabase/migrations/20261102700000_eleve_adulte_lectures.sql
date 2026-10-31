-- Ecrans de l'eleve adulte branches sur le serveur (PR claude/eleve-adulte,
-- 02/11/2026 ; INVENTAIRE-NON-BRANCHE-2026-10-31 section B).
--
-- `accueilAdulteProvider`, `maClasseAdulteProvider` et
-- `historiqueSeancesAdulteProvider` rendaient `CapaciteIndisponible` hors
-- demonstration : aucune lecture serveur ne disait quelle est la Classe de
-- l'adulte lui-meme. Les lectures existantes ne suffisent pas :
--   * `mes_groupes_famille_v` rend aussi les Classes des enfants du foyer
--     (`est_du_foyer`), sans dire laquelle est celle de l'adulte ;
--   * `mes_seances_v` et `presence_seance_v` rendent, pour un tuteur, tout le
--     foyer, sans la Classe de la seance ;
--   * aucune lecture ne rend a un membre les prenoms de sa Classe.
-- Reutilises : `ma_capacite_eleve()` (0090) est la porte, `etat_presence()`
-- (0084) dit l'absence, `groupe_membres` (0017) et `sessions.groupe_id`
-- disent la Classe. La carte de seance, l'horloge et la Bibliotheque restent
-- celles de `mes_groupes_famille_v`, `horloge_classe`, deja branchees.
--
-- Trois lectures, STABLE, SECURITY DEFINER, search_path vide, objets
-- qualifies, EXECUTE pour authenticated seulement. Porte positive : compte
-- valide ET eleve autonome (`ma_capacite_eleve()`), sinon aucune ligne.
-- L'appelant ne passe jamais son identifiant : tout part de auth.uid().
--
-- Aucune suppression : ni ligne, ni objet, ni table videe.

begin;

-- 1. L'espace de l'adulte : son prenom et sa Classe active (une seule : la
--    regle de `ajouter_eleve_groupe` refuse un second groupe actif). Aucune
--    ligne pour qui n'est pas eleve autonome ; une ligne, groupe nul, pour
--    l'adulte qui n'a pas encore de Classe.
create function public.espace_eleve_adulte()
returns table(prenom text, groupe_id uuid)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    p.first_name,
    (select m.groupe_id
       from public.groupe_membres m
       join public.groupes g on g.id = m.groupe_id and g.ended_at is null
      where m.student_id = auth.uid()
        and m.left_at is null
      order by m.joined_at desc
      limit 1)
  from public.profiles p
  where public.ma_capacite_eleve()
    and p.id = auth.uid()
    and p.deleted_at is null;
$function$;

-- 2. Les seances passees de l'adulte, les plus recentes d'abord, par pages
--    (cle `p_avant` : le debut de la derniere seance de la page precedente).
--    Seules les seances tenues : closes (`ended`) ou closes sur l'absence de
--    l'eleve (`student_absent`). Une seance annulee ou que l'enseignant n'a
--    pas tenue n'est pas une seance passee de l'eleve. L'absence vient de
--    `etat_presence`, jamais du client. Le jour et la date sont rendus dans
--    le fuseau de l'appelant (`mon_fuseau()`, comme `horloge_classe`) : le
--    client ne fait que les mettre en mots (`dateRendue`).
create function public.seances_passees_eleve_adulte(
  p_limite integer default 20,
  p_avant timestamptz default null
)
returns table(
  session_id uuid,
  started_at timestamptz,
  ended_at timestamptz,
  status public.session_status,
  groupe_id uuid,
  teacher_id uuid,
  teacher_first_name text,
  absent boolean,
  jour_iso integer,
  date_locale text
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.status,
    s.groupe_id,
    s.teacher_id,
    t.first_name,
    s.status = 'student_absent'
      or public.etat_presence(s.id, auth.uid()) = 'absente',
    pg_catalog.date_part('isodow', s.started_at at time zone public.mon_fuseau())::integer,
    pg_catalog.to_char(s.started_at at time zone public.mon_fuseau(), 'YYYY-MM-DD')
  from public.session_participants sp
  join public.sessions s on s.id = sp.session_id and s.deleted_at is null
  left join public.profiles t on t.id = s.teacher_id and t.deleted_at is null
  where public.ma_capacite_eleve()
    and sp.profile_id = auth.uid()
    and sp.role = 'student'
    and sp.deleted_at is null
    and s.status in ('ended', 'student_absent')
    and (p_avant is null or s.started_at < p_avant)
  order by s.started_at desc, s.id desc
  limit least(greatest(coalesce(p_limite, 20), 1), 100);
$function$;

-- 3. Les participants de la Classe active de l'adulte : prenom seul, rien
--    d'autre sur un camarade (UX_REVIEW_07 ligne 4 b), et seulement les
--    comptes actifs (un compte desactive ne figure plus dans la Classe). La
--    cle de photo n'est
--    rendue que pour l'adulte lui-meme : celle d'un camarade ne le concerne
--    pas, l'ecran montre ses initiales.
create function public.participants_classe_eleve_adulte()
returns table(profile_id uuid, prenom text, cle_avatar text, est_moi boolean)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    p.id,
    p.first_name,
    case when p.id = auth.uid() then sp.avatar_storage_key end,
    p.id = auth.uid()
  from public.groupe_membres m
  join public.profiles p
    on p.id = m.student_id
   and p.deleted_at is null
   and p.account_status in ('active', 'provisional_active')
  left join public.student_profiles sp
    on sp.profile_id = p.id and sp.deleted_at is null
  where public.ma_capacite_eleve()
    and m.left_at is null
    and m.groupe_id = (
      select mm.groupe_id
        from public.groupe_membres mm
        join public.groupes g on g.id = mm.groupe_id and g.ended_at is null
       where mm.student_id = auth.uid()
         and mm.left_at is null
       order by mm.joined_at desc
       limit 1)
  order by (p.id = auth.uid()) desc, p.first_name, p.id;
$function$;

do $droits$
declare
  v_oid pg_catalog.regprocedure;
  v_role text;
begin
  foreach v_oid in array array[
    'public.espace_eleve_adulte()'::pg_catalog.regprocedure,
    'public.seances_passees_eleve_adulte(integer, timestamptz)'::pg_catalog.regprocedure,
    'public.participants_classe_eleve_adulte()'::pg_catalog.regprocedure]
  loop
    execute pg_catalog.format('alter function %s owner to postgres', v_oid);
    execute pg_catalog.format('revoke all on function %s from public', v_oid);
    foreach v_role in array array['anon', 'service_role', 'agent_ro'] loop
      if exists (select 1 from pg_catalog.pg_roles where rolname = v_role) then
        execute pg_catalog.format('revoke all on function %s from %I', v_oid, v_role);
      end if;
    end loop;
    execute pg_catalog.format('grant execute on function %s to authenticated', v_oid);
    execute pg_catalog.format('comment on function %s is %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. Eleve adulte : lecture de ce qui le concerne seul, porte ma_capacite_eleve().',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  end loop;
end;
$droits$;

do $postflight$
declare
  v_sig text;
begin
  foreach v_sig in array array[
    'public.espace_eleve_adulte()',
    'public.seances_passees_eleve_adulte(integer, timestamptz)',
    'public.participants_classe_eleve_adulte()']
  loop
    if (select p.provolatile from pg_catalog.pg_proc p
         where p.oid = v_sig::pg_catalog.regprocedure) <> 's' then
      raise exception '% doit etre STABLE (aucune ecriture)', v_sig;
    end if;
    if not (select p.prosecdef from pg_catalog.pg_proc p
             where p.oid = v_sig::pg_catalog.regprocedure) then
      raise exception '% doit etre SECURITY DEFINER', v_sig;
    end if;
    if pg_catalog.has_function_privilege('anon', v_sig, 'EXECUTE') then
      raise exception '% ouverte a anon', v_sig;
    end if;
    if not pg_catalog.has_function_privilege('authenticated', v_sig, 'EXECUTE') then
      raise exception '% fermee a authenticated', v_sig;
    end if;
  end loop;
end;
$postflight$;

commit;
