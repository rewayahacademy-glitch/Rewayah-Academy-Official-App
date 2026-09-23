-- 0025 — Le role Enseignant : lecture de groupe, cahier de transmission
--
-- Migration coordonnee du lot « role Enseignant » (protocole multi-agents du
-- 19 septembre 2026, `docs/archive/2026-09-pre-remise-a-plat/architecture/TEACHER_PARALLEL_BASELINE.md`). Elle est
-- ecrite par l'Agent Z, seul autorise a toucher le schema pendant ce lot.
--
-- Trois manques mesures sur la base, que ce lot comble :
--
-- 1. `mes_seances_v` rend UNE LIGNE PAR ELEVE (elle joint
--    `session_participants`). Pour un tuteur ou un eleve, qui ne voient que
--    leur propre ligne, c'est juste ; pour un enseignant de groupe, la meme
--    seance revient autant de fois qu'elle compte d'eleves, et la colonne de
--    `ENS-02` afficherait cinq fois le meme cours. La vue n'est PAS modifiee :
--    elle est partagee par TUT-01, ELV-02, ENS-02 et CTR-01. Une vue propre a
--    l'enseignant, groupee par seance, est ajoutee a cote.
--
-- 2. Aucun lien ne relie une seance a un groupe. Sans lui, la fiche groupe
--    (`ENS-07`) ne s'ouvre pas depuis une carte de seance. `sessions.groupe_id`
--    est ajoute NULLABLE : les seances 1-a-1 anterieures au pivot restent
--    valides, et une seance sans groupe est un cours individuel, pas une
--    donnee incomplete.
--
-- 3. `groupe_detail(uuid)` est reserve a l'ADMIN et rend `student_nom`. Un
--    enseignant ne doit jamais lire un nom de famille (ADR-008). Une fonction
--    propre a l'enseignant est ajoutee, qui ne rend que le prenom et
--    l'identifiant immuable.
--
-- `lesson_reports` et `makharij_findings` existent depuis l'etape 1, avec leur
-- contrainte d'unicite sur la cle d'idempotence (C9) et leurs policies. Aucune
-- table n'est donc creee pour le cahier : il lui manquait un preremplissage et
-- une file de retard, pas un schema.
--
-- PERIMETRE EXPLICITE. Les migrations `0020` a `0024` (programme pedagogique,
-- diagnostics, progression, evaluations, qualite) sont committees sur `main`
-- mais N'ONT JAMAIS ETE APPLIQUEES a cette base. Ce lot ne les applique pas :
-- elles relevent d'un autre perimetre. `unite_curriculum()` ci-dessous lit donc
-- `progression_historique` et `programme_niveaux` par SQL dynamique, garde par
-- `to_regclass` : elle rend `null` tant que ces tables sont absentes, et se
-- met a rendre la vraie unite le jour ou elles arrivent, sans nouvelle
-- migration.

-- ============================================================
-- 1. Le lien seance -> groupe
-- ============================================================

alter table public.sessions
  add column if not exists groupe_id uuid references public.groupes(id);

create index if not exists sessions_groupe_idx
  on public.sessions (groupe_id)
  where deleted_at is null and groupe_id is not null;

comment on column public.sessions.groupe_id is
  'Le groupe dont cette seance est la reunion hebdomadaire. Nul pour les '
  'seances 1-a-1 anterieures au pivot du 19 septembre 2026 : une seance sans '
  'groupe est un cours individuel, jamais une donnee incomplete.';

-- ============================================================
-- 2. Les seances de l'enseignant, UNE LIGNE PAR SEANCE
-- ============================================================

create view public.mes_seances_enseignant_v with (security_barrier = true) as
select
  s.id                       as session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  s.prayer_pause_minutes,
  s.groupe_id,
  g.libelle                  as groupe_libelle,
  g.type_public,
  g.seuil_max,
  count(distinct sp.profile_id) filter (
    where sp.role = 'student' and sp.deleted_at is null
  )::int                     as nb_participants,
  exists (
    select 1 from public.lesson_reports lr
     where lr.session_id = s.id and lr.deleted_at is null
  )                          as cahier_depose
from public.sessions s
  left join public.groupes g on g.id = s.groupe_id
  left join public.session_participants sp on sp.session_id = s.id
where s.deleted_at is null
  and s.teacher_id = auth.uid()
group by
  s.id, s.started_at, s.ended_at, s.status, s.session_type,
  s.prayer_pause_minutes, s.groupe_id, g.libelle, g.type_public, g.seuil_max;

comment on view public.mes_seances_enseignant_v is
  'ENS-02 : les seances de l''enseignant connecte, une ligne par seance et non '
  'par eleve. Ne porte aucun prenom : le roster se lit par teacher_roster_v, '
  'qui applique deja le masquage d''observation.';

revoke all on public.mes_seances_enseignant_v from anon;
grant select on public.mes_seances_enseignant_v to authenticated, agent_ro;

-- ============================================================
-- 3. Mes groupes
-- ============================================================

create view public.mes_groupes_v with (security_barrier = true) as
select
  g.id             as groupe_id,
  g.libelle,
  g.type_public,
  g.seuil_max,
  g.weekday,
  g.hour_local,
  g.timezone_iana,
  g.created_at,
  count(m.id) filter (where m.left_at is null)::int as nb_membres
from public.groupes g
  left join public.groupe_membres m on m.groupe_id = g.id
where g.ended_at is null
  and g.teacher_id = auth.uid()
group by
  g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local,
  g.timezone_iana, g.created_at;

comment on view public.mes_groupes_v is
  'ENS-07 : les groupes actifs de l''enseignant connecte. L''enseignant n''avait '
  'aucun moyen de lire ses propres groupes : groupes_admin() est reserve a '
  'l''administration.';

revoke all on public.mes_groupes_v from anon;
grant select on public.mes_groupes_v to authenticated, agent_ro;

-- ============================================================
-- 4. Le detail d'UN DE MES groupes, sans nom de famille
-- ============================================================

create function public.mon_groupe_detail(p_groupe_id uuid)
returns table (
  student_id          uuid,
  identifiant_immuable text,
  prenom              text,
  niveau              text,
  riwaya              text,
  joined_at           timestamptz
)
language sql
stable
security definer
set search_path to ''
as $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    sp.level,
    sp.riwaya,
    m.joined_at
  from public.groupe_membres m
    join public.groupes g on g.id = m.groupe_id
    join public.profiles p on p.id = m.student_id
    left join public.student_profiles sp on sp.profile_id = p.id
  where m.groupe_id = p_groupe_id
    and m.left_at is null
    and p.deleted_at is null
    and g.ended_at is null
    and g.teacher_id = auth.uid()
    and public.app_account_valid()
  order by m.joined_at asc;
$function$;

comment on function public.mon_groupe_detail(uuid) is
  'ENS-07 : les membres d''un groupe dont l''appelant est l''enseignant. Ne rend '
  'JAMAIS last_name, contrairement a groupe_detail(uuid) qui est reserve a '
  'l''administration : un enseignant ne lit qu''un prenom et un identifiant '
  'immuable (ADR-008).';

revoke all on function public.mon_groupe_detail(uuid) from anon;
grant execute on function public.mon_groupe_detail(uuid) to authenticated, agent_ro;

-- ============================================================
-- 5. L'unite de curriculum d'un eleve, si le curriculum existe
-- ============================================================

create function public.unite_curriculum(p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_resultat jsonb;
begin
  -- Les migrations 0020 a 0024 ne sont pas appliquees sur toutes les bases.
  -- Une reference statique a `progression_historique` empecherait la creation
  -- de cette fonction ; le SQL dynamique garde par `to_regclass` rend `null`
  -- tant que la table est absente, et la vraie unite des qu'elle arrive.
  if to_regclass('public.progression_historique') is null
     or to_regclass('public.programme_niveaux') is null then
    return null;
  end if;

  -- `code_technique` voyage, mais l'interface a l'interdiction explicite de
  -- l'employer comme titre : il ne se dit qu'en sous-texte technique discret
  -- (`0020_programme_pedagogique.sql`). `nom_humain` est le libelle a afficher.
  execute $dyn$
    select jsonb_build_object(
             'niveau_id',      n.id,
             'nom_humain',     n.nom_humain,
             'code_technique', n.code_technique,
             'cycle',          n.cycle,
             'ordre',          n.ordre,
             'depuis',         h.created_at,
             'type_mouvement', h.type_mouvement
           )
      from public.progression_historique h
      join public.programme_niveaux n on n.id = h.niveau_id
     where h.student_id = $1
     order by h.created_at desc
     limit 1
  $dyn$
  into v_resultat
  using p_student_id;

  return v_resultat;
exception
  -- Une colonne absente ne doit pas faire echouer le preremplissage du cahier :
  -- l'unite est un enrichissement, pas la donnee qui porte l'ecran.
  when undefined_column or undefined_table then
    return null;
end;
$function$;

comment on function public.unite_curriculum(uuid) is
  'L''unite de curriculum courante d''un eleve, ou null quand le programme '
  'pedagogique (migrations 0020-0024) n''est pas applique sur cette base. '
  'Lecture dynamique gardee par to_regclass, volontairement : l''ecran doit '
  'taire ce qu''il ne sait pas, jamais afficher un tiret a la place.';

revoke all on function public.unite_curriculum(uuid) from anon;
grant execute on function public.unite_curriculum(uuid) to authenticated, agent_ro;

-- ============================================================
-- 6. Le brouillon du cahier de transmission
-- ============================================================

create function public.brouillon_cahier(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_seance      public.sessions%rowtype;
  v_participants jsonb;
  v_evenements  jsonb;
begin
  select * into v_seance
    from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;

  if not found then
    return null;
  end if;

  -- La porte : seul l'enseignant de la seance prepare son cahier. L'admin et
  -- le controleur lisent le cahier depose, ils n'en redigent pas.
  if v_seance.teacher_id <> auth.uid()
     or public.app_role() <> 'teacher'
     or not public.app_account_valid() then
    raise exception 'cahier refuse' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(ligne order by ligne ->> 'prenom'), '[]'::jsonb)
    into v_participants
    from (
      select jsonb_build_object(
               'student_id',           p.id,
               'prenom',               p.first_name,
               'identifiant_immuable', p.immutable_id,
               'niveau',               sp.level,
               'riwaya',               sp.riwaya,
               'presence',             public.etat_presence(p_session_id, p.id),
               'entre_le',             (
                 select min(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id
                    and e.profile_id = p.id
                    and e.event_type = 'joined'
               ),
               'derniere_trace_le',    (
                 select max(e.server_ts) from public.session_events e
                  where e.session_id = p_session_id and e.profile_id = p.id
               ),
               -- Memes cles que `student_reading_position`, volontairement :
               -- `PositionLecture.depuisJson` (core/coran/service_coran.dart)
               -- les lit deja, et un second jeu de noms imposerait un second
               -- modele Dart pour le meme fait.
               --
               -- La position d'un eleve LUI APPARTIENT (invariant J2) : aucune
               -- policy ne laisse un enseignant l'ecrire, et ce n'est pas ce
               -- qui se passe ici. Cette fonction la LIT, pour le seul
               -- enseignant de la seance, afin de preremplir « ce qui a ete
               -- travaille » -- ce que le protocole exige de deduire plutot que
               -- de redemander. Une page tournee par l'enseignant n'ecrase
               -- jamais l'endroit ou l'eleve en etait.
               'position',             (
                 select jsonb_build_object(
                          'page_mushaf', r.page_mushaf,
                          'sourate',     r.sourate,
                          'verset',      r.verset,
                          'zoom_level',  r.zoom_level,
                          'updated_at',  r.updated_at
                        )
                   from public.student_reading_position r
                  where r.student_profile_id = p.id
               ),
               'unite_curriculum',     public.unite_curriculum(p.id)
             ) as ligne
        from public.session_participants spart
        join public.profiles p on p.id = spart.profile_id
        left join public.student_profiles sp on sp.profile_id = p.id
       where spart.session_id = p_session_id
         and spart.role = 'student'
         and spart.deleted_at is null
         and p.deleted_at is null
    ) lignes;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'type',       e.event_type,
               'instant',    e.server_ts,
               'profile_id', e.profile_id
             ) order by e.server_ts
           ),
           '[]'::jsonb
         )
    into v_evenements
    from public.session_events e
   where e.session_id = p_session_id;

  return jsonb_build_object(
    'session_id',           v_seance.id,
    'groupe_id',            v_seance.groupe_id,
    'debut',                v_seance.started_at,
    'fin',                  v_seance.ended_at,
    'statut',               v_seance.status,
    'duree_minutes',
      greatest(
        0,
        (extract(epoch from (v_seance.ended_at - v_seance.started_at)) / 60)::int
      ),
    'minutes_interruption', v_seance.prayer_pause_minutes,
    'deja_depose',          exists (
      select 1 from public.lesson_reports lr
       where lr.session_id = p_session_id and lr.deleted_at is null
    ),
    'participants',         v_participants,
    'evenements',           v_evenements
  );
end;
$function$;

comment on function public.brouillon_cahier(uuid) is
  'ENS-04 : tout ce que le systeme sait deja d''une seance, pour que le cahier '
  's''ouvre prerempli et se valide en moins de 45 secondes. Presence deduite '
  'par etat_presence(), duree et interruptions par la seance, contenu par la '
  'position de lecture, unite par unite_curriculum() quand elle existe. '
  'L''enseignant ne confirme que les exceptions : aucune donnee deductible ne '
  'lui est redemandee.';

revoke all on function public.brouillon_cahier(uuid) from anon;
grant execute on function public.brouillon_cahier(uuid) to authenticated, agent_ro;

-- ============================================================
-- 7. Les cahiers en retard
-- ============================================================

create function public.mes_rapports_en_attente()
returns table (
  session_id      uuid,
  started_at      timestamptz,
  ended_at        timestamptz,
  groupe_id       uuid,
  groupe_libelle  text,
  nb_participants int,
  heures_de_retard int
)
language sql
stable
security definer
set search_path to ''
as $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.groupe_id,
    g.libelle,
    count(distinct sp.profile_id) filter (
      where sp.role = 'student' and sp.deleted_at is null
    )::int,
    greatest(0, (extract(epoch from (now() - s.ended_at)) / 3600)::int)
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
    left join public.session_participants sp on sp.session_id = s.id
  where s.deleted_at is null
    and s.teacher_id = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid()
    -- Une seance annulee, ou l'enseignant ne s'est pas presente, ne doit aucun
    -- cahier : il n'y a rien a transmettre.
    and s.status in ('ended', 'student_absent', 'tech_failure')
    and s.ended_at < now()
    and not exists (
      select 1 from public.lesson_reports lr
       where lr.session_id = s.id and lr.deleted_at is null
    )
  group by s.id, s.started_at, s.ended_at, s.groupe_id, g.libelle
  order by s.ended_at asc;
$function$;

comment on function public.mes_rapports_en_attente() is
  'ENS-02 : les seances terminees dont le cahier manque, la plus ancienne '
  'd''abord. Alimente le bloc « rapports en attente » de la Journee et, une '
  'fois le cahier depose, la ligne disparait d''elle-meme.';

revoke all on function public.mes_rapports_en_attente() from anon;
grant execute on function public.mes_rapports_en_attente() to authenticated, agent_ro;

-- ============================================================
-- 8. Durcissement : un cahier ne s'ecrit que sur SA seance
-- ============================================================
--
-- `lesson_reports_teacher_write` n'exigeait que `author_profile_id = auth.uid()`
-- et le role enseignant : un enseignant pouvait donc deposer un cahier sur la
-- seance de quelqu'un d'autre. La RLS bornait l'auteur, pas la seance.

drop policy if exists lesson_reports_teacher_write on public.lesson_reports;

create policy lesson_reports_teacher_write on public.lesson_reports
  for all
  using (
    author_profile_id = auth.uid()
    and deleted_at is null
  )
  with check (
    public.app_role() = 'teacher'
    and author_profile_id = auth.uid()
    and public.session_belongs_to_teacher(session_id, auth.uid())
  );

comment on table public.lesson_reports is
  'Les cahiers de transmission. Une cle d''idempotence unique (C9) rend le rejeu '
  'de la file hors ligne inoffensif. Depuis 0025, l''ecriture exige aussi que la '
  'seance soit celle de l''enseignant : borner l''auteur ne bornait pas la seance.';
