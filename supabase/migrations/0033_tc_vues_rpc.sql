-- 0033_tc_vues_rpc.sql
-- Teaching Core -- paliers 5 (vues), 6 (RPC de consultation/ecriture legere) et
-- 7 (« point chaud » : les trois fonctions deja vivantes qui gouvernent
-- l'entree en salle video reelle). Derniere migration du socle commun.
--
-- Regles rappelees, valables pour tout ce fichier :
--   - jamais de `grant execute` a `agent_ro` sur une RPC volatile ou d'ecriture
--     (feedback_agent_ro_jamais_sur_rpc_ecriture) ; `get_advisors` ne le voit pas.
--   - toute vue d'exposition repete le filtre d'appelant et le masquage
--     `agent_identite_masquee()` colonne par colonne : une surface oubliee est
--     une fuite avec une banniere devant.
--   - `create or replace view` DOIT repeter `with (security_barrier = true)`
--     quand la vue l'avait deja, sinon l'option retombe silencieusement a faux.
--   - une porte SQL s'ecrit en exigence positive (`if role <> 'x' then raise`
--     laisse entrer NULL) -- feedback_porte_sql_exigence_positive.
--
-- ============================================================================
-- PALIER 5.0 -- Les six surfaces qui masquent deja `masked_controller`
--   doivent masquer `admin_masked` de la meme facon (ADR-011 etendu par G).
--   Une seule fonction (`est_observateur_masque`) fait ricocher trois d'entre
--   elles (les policies de `session_events`, 0012) sans les toucher directement.
--   `admin_visible` n'entre JAMAIS dans cette liste : c'est l'institution qui
--   se montre, par construction.
-- ============================================================================

create or replace function public.est_observateur_masque(
  p_session_id uuid,
  p_profile_id uuid
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id
      and sp.profile_id = p_profile_id
      and sp.role in ('masked_controller', 'admin_masked')
      and sp.deleted_at is null
  );
$$;

-- `presence_seance_v` : masquage etendu, ET bornage de `entre_le` (A §1.11,
-- "avec §1.4, jamais apres"). Sans le bornage, un eleve entre a T-20 lit une
-- duree en salle gonflee de vingt minutes qu'il n'a pas passees en cours ; avec
-- lui mais sans le `case`, un eleve qui n'est JAMAIS entre lirait `started_at`
-- au lieu de NULL -- `greatest()` a un seul argument non NULL rend cet
-- argument, jamais NULL. D'ou le `case` explicite.
create or replace view public.presence_seance_v
with (security_barrier = true)
as
select
  sp.session_id,
  sp.profile_id,
  sp.role,
  case when public.agent_identite_masquee() then p.immutable_id else p.first_name end as prenom,
  p.immutable_id as identifiant_immuable,
  public.etat_presence(sp.session_id, sp.profile_id) as etat,
  (
    select case when min(e.server_ts) is not null
                then greatest(min(e.server_ts), s.started_at)
           end
      from public.session_events e
     where e.session_id = sp.session_id
       and e.profile_id = sp.profile_id
       and e.event_type = 'joined'
  ) as entre_le,
  (
    select max(e.server_ts) from public.session_events e
     where e.session_id = sp.session_id and e.profile_id = sp.profile_id
  ) as derniere_trace_le,
  o.etat is not null as consolide,
  o.decide_le as consolide_le,
  s.started_at,
  s.ended_at,
  s.status as statut_seance
from public.session_participants sp
  join public.sessions s on s.id = sp.session_id
  join public.profiles p on p.id = sp.profile_id
  left join public.session_presence_override o
    on o.session_id = sp.session_id and o.profile_id = sp.profile_id
where sp.deleted_at is null and s.deleted_at is null and p.deleted_at is null
  and (
    public.app_role() in ('admin', 'controller')
    or s.teacher_id = auth.uid()
    or (public.app_role() = 'guardian' and public.est_du_foyer(p.id))
    or sp.profile_id = auth.uid()
  )
  and (sp.role not in ('masked_controller', 'admin_masked') or public.app_role() = 'admin');

create or replace view public.session_peers_v
with (security_barrier = true)
as
select distinct
  sp.session_id,
  p2.id as peer_id,
  p2.first_name,
  p2.immutable_id
from public.session_participants sp
  join public.session_participants sp2 using (session_id)
  join public.profiles p2 on p2.id = sp2.profile_id
where sp.profile_id = auth.uid()
  and sp.deleted_at is null
  and sp2.deleted_at is null
  and p2.deleted_at is null
  and sp2.profile_id <> sp.profile_id
  and (sp2.role not in ('masked_controller', 'admin_masked') or public.app_role() = 'admin');

drop policy if exists session_participants_controller_read on public.session_participants;
create policy session_participants_controller_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'controller'
    and deleted_at is null
    and role not in ('masked_controller', 'admin_masked')
  );

drop policy if exists session_participants_teacher_read on public.session_participants;
create policy session_participants_teacher_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'teacher' and deleted_at is null
    and public.session_belongs_to_teacher(session_participants.session_id, auth.uid())
    and role not in ('masked_controller', 'admin_masked')
  );

drop policy if exists session_participants_family_read on public.session_participants;
create policy session_participants_family_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'guardian' and deleted_at is null
    and role not in ('masked_controller', 'admin_masked')
    and exists (select 1 from public.profiles p where p.id = session_participants.profile_id
                and p.household_id = public.app_household_id() and p.deleted_at is null)
  );

-- ============================================================================
-- PALIER 5.1 -- mes_groupes_famille_v (A §1.2). L'eleve et le tuteur de son
-- foyer, jamais un roster nomme : aucun nom de famille, coordonnee ni paiement.
-- Le predicat de foyer reprend `est_du_foyer()` (0030), verifie identique a
-- celui deja employe par `mes_seances_v` -- pas `household_members`, qui
-- n'existe pas dans ce depot.
-- ============================================================================

create or replace view public.mes_groupes_famille_v
with (security_barrier = true)
as
select
  g.id as groupe_id,
  g.libelle,
  g.type_public,
  g.seuil_max,
  g.weekday,
  g.hour_local,
  g.timezone_iana,
  g.couleur_jeton,
  g.nom_cours,
  g.programme_niveau_id,
  g.teacher_id,
  case when public.agent_identite_masquee() then null else tp_p.first_name end as teacher_prenom,
  tp.titre as teacher_titre,
  tp.photo_storage_key as teacher_photo_cle,
  count(m2.id) filter (where m2.left_at is null)::int as nb_membres
from public.groupes g
  join public.groupe_membres m on m.groupe_id = g.id and m.left_at is null
  join public.profiles tp_p on tp_p.id = g.teacher_id
  left join public.teacher_profiles tp on tp.profile_id = g.teacher_id
  left join public.groupe_membres m2 on m2.groupe_id = g.id
where g.ended_at is null
  and public.app_account_valid()
  and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
group by
  g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local,
  g.timezone_iana, g.couleur_jeton, g.nom_cours, g.programme_niveau_id,
  g.teacher_id, tp_p.first_name, tp.titre, tp.photo_storage_key;

revoke all on public.mes_groupes_famille_v from anon;
grant select on public.mes_groupes_famille_v to authenticated, agent_ro;

-- ============================================================================
-- PALIER 5.2 -- teacher_roster_v ETENDUE (E §1.1-1.5), jamais recreee a cote :
-- une seconde vue reproduirait le defaut 3.8 (`last_name` retire par ADR-008
-- en 0005). Colonnes actuelles conservees a l'identique, nom et type ; six
-- colonnes ajoutees APRES, jamais entre elles.
-- N'entrent jamais : last_name, telephone, e-mail, adresse, identite de
-- tuteur, household_id, paiement, geolocalisation, identifiant d'appareil.
-- ============================================================================

create or replace view public.teacher_roster_v
with (security_barrier = true)
as
select
  s.id as session_id,
  p.id as student_id,
  case when public.agent_identite_masquee() then p.immutable_id else p.first_name end as first_name,
  p.immutable_id,
  sp.level,
  sp.riwaya,
  sp.interface_mode,
  prog.cycle as curriculum_path,
  prog.nom_humain as current_unit,
  coalesce(goals.objectifs, '{}') as active_goals,
  pos.page_mushaf as resume_page,
  pos.sourate as resume_sourate,
  pos.verset as resume_verset
from public.sessions s
  join public.session_participants spart on spart.session_id = s.id
  join public.profiles p on p.id = spart.profile_id
  join public.student_profiles sp on sp.profile_id = p.id
  -- Niveau courant : la ligne la plus recente de progression_historique, nom
  -- HUMAIN uniquement (jamais code_technique, cf. consigne E §1.1).
  left join lateral (
    select pn.cycle, pn.nom_humain
      from public.progression_historique ph
      join public.programme_niveaux pn on pn.id = ph.niveau_id
     where ph.student_id = p.id
     order by ph.created_at desc
     limit 1
  ) prog on true
  -- Reprise de lecture : lecture seule, jamais d'ecriture depuis cette vue
  -- (invariant J2, 0007) ; zoom_level volontairement exclu, c'est une
  -- preference personnelle, pas un fait pedagogique.
  left join lateral (
    select srp.page_mushaf, srp.sourate, srp.verset
      from public.student_reading_position srp
     where srp.student_profile_id = p.id
     order by srp.updated_at desc
     limit 1
  ) pos on true
  -- Au plus trois objectifs actifs, deja ordonnes par echeance. Assignation
  -- nominative ou assignation de groupe (student_id is null), jamais close.
  left join lateral (
    select array(
      select la.purpose
        from public.learning_assignment la
       where (la.student_id = p.id or (la.student_id is null and la.group_id = s.groupe_id))
         and la.status in ('a_faire', 'en_cours')
       order by la.due_at nulls last, la.starts_at
       limit 3
    ) as objectifs
  ) goals on true
where s.teacher_id = auth.uid() and s.deleted_at is null and spart.deleted_at is null and p.deleted_at is null;

-- ============================================================================
-- PALIER 5.3 -- tendance_feedback_v, redessinee PAR QUESTION (decision
-- produit posterieure au contrat H, qui ne livrait qu'une tonalite generale
-- avec un seul `group by groupe_id`). Le seuil `feedback_seuil_tendance`
-- s'applique maintenant par (groupe, question) : cinq volets peuvent franchir
-- le seuil a des rythmes differents, et c'est voulu.
-- ============================================================================

create view public.tendance_feedback_v
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
where g.teacher_id = auth.uid() or public.app_role() = 'admin'
group by f.groupe_id, f.question_id
having count(*) >= public.app_config_int('feedback_seuil_tendance', 5);

revoke all on public.tendance_feedback_v from anon;
grant select on public.tendance_feedback_v to authenticated;

-- ============================================================================
-- PALIER 5.4 -- concern_famille_v (H §1.4). internal_details, teacher_id,
-- session_id et groupe_id sont ABSENTS, colonne par colonne : la famille lit
-- un resume transmis, jamais la note interne de l'enseignant.
-- ============================================================================

create view public.concern_famille_v
with (security_barrier = true)
as
select c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a
from public.student_concern c
where c.statut = 'transmis'
  and c.family_summary is not null
  and (public.est_du_foyer(c.student_id) or c.student_id = auth.uid());

revoke all on public.concern_famille_v from anon;
grant select on public.concern_famille_v to authenticated;

-- ============================================================================
-- PALIER 6.0 -- Une cle de configuration manquante : la grace apres la fin
-- de seance est en dur a deux endroits (autoriser_jeton_video 0010:309,
-- pre_vol.dart cote client). Meme geste que join_window_minutes (0030).
-- ============================================================================

insert into public.app_config (key, value) values ('grace_after_end_minutes', '15'::jsonb)
on conflict (key) do nothing;

-- ============================================================================
-- PALIER 6.1 -- materialiser_seances_groupe (A §1.1, BLOQUANT n°1). Rien
-- d'autre n'alimente sessions.groupe_id : sans cette fonction, cinq lots sur
-- neuf n'ont aucune donnee a lire.
--
-- Frequence d'appel : NON tranchee par le contrat, explicitement renvoyee a
-- Agent Z ("le depot n'a aucun ordonnanceur"). Decision prise ici : deux
-- declencheurs (creation/modification d'horaire de groupe, adhesion d'un
-- membre) materialisent a la volee sur un horizon glissant de
-- `matching_horizon_weeks` semaines. Limite connue, documentee et non
-- corrigee ici : un groupe stable sans nouvelle adhesion pendant plus que cet
-- horizon cesse d'etendre son planning jusqu'a la prochaine modification.
-- Combler cette limite demande un ordonnanceur (pg_cron ou tache planifiee
-- hors base) : hors perimetre d'une migration SQL, a poser separement.
--
-- Idempotence : une occurrence par (groupe, debut). Pour une semaine deja
-- materialisee et NON commencee, un nouveau membre est quand meme inscrit
-- dans `session_participants` -- sans ce geste, rejoindre un groupe n'importe
-- quand sauf le jour de la creation laisserait l'eleve absent de seances deja
-- planifiees.
-- ============================================================================

create or replace function public.materialiser_seances_groupe(p_groupe_id uuid)
returns int
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_g        public.groupes;
  v_semaines int;
  v_duree    int;
  v_fenetre  int;
  v_debut    timestamptz;
  v_session  uuid;
  v_n        int := 0;
begin
  select * into v_g from public.groupes
   where id = p_groupe_id and ended_at is null;
  if not found then
    return 0;
  end if;

  v_semaines := public.app_config_int('matching_horizon_weeks', 4);
  v_duree    := public.app_config_int('session_duration_minutes', 60);
  v_fenetre  := public.app_config_int('join_window_minutes', 20);

  for i in 0 .. v_semaines - 1 loop
    -- Le convertisseur du depot (0006), jamais un recodage.
    v_debut := public.instant_creneau(v_g.weekday, v_g.hour_local, v_g.timezone_iana, i);

    select s.id into v_session from public.sessions s
     where s.groupe_id = p_groupe_id and s.started_at = v_debut and s.deleted_at is null;

    if v_session is not null then
      if v_debut > now() then
        insert into public.session_participants (session_id, profile_id, role)
        select v_session, m.student_id, 'student'
          from public.groupe_membres m
         where m.groupe_id = p_groupe_id and m.left_at is null
        on conflict (session_id, profile_id) do nothing;
      end if;
      continue;
    end if;

    insert into public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
    values
      (v_g.teacher_id, v_debut, v_debut + make_interval(mins => v_duree),
       case v_g.type_public when 'enfant' then 'child' else 'standard' end,
       p_groupe_id, v_debut - make_interval(mins => v_fenetre))
    returning id into v_session;

    insert into public.session_participants (session_id, profile_id, role)
    select v_session, m.student_id, 'student'
      from public.groupe_membres m
     where m.groupe_id = p_groupe_id and m.left_at is null;

    v_n := v_n + 1;
  end loop;

  return v_n;
end;
$$;

revoke execute on function public.materialiser_seances_groupe(uuid) from public, anon, agent_ro;
grant  execute on function public.materialiser_seances_groupe(uuid) to service_role;

create or replace function public.tc_materialiser_apres_creation_groupe()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.materialiser_seances_groupe(new.id);
  return new;
end;
$$;

revoke execute on function public.tc_materialiser_apres_creation_groupe() from public, anon, authenticated;

drop trigger if exists tc_materialiser_apres_creation_groupe on public.groupes;
create trigger tc_materialiser_apres_creation_groupe
  after insert or update of weekday, hour_local, timezone_iana on public.groupes
  for each row execute function public.tc_materialiser_apres_creation_groupe();

create or replace function public.tc_materialiser_apres_adhesion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.materialiser_seances_groupe(new.groupe_id);
  return new;
end;
$$;

revoke execute on function public.tc_materialiser_apres_adhesion() from public, anon, authenticated;

drop trigger if exists tc_materialiser_apres_adhesion on public.groupe_membres;
create trigger tc_materialiser_apres_adhesion
  after insert on public.groupe_membres
  for each row execute function public.tc_materialiser_apres_adhesion();

-- ============================================================================
-- PALIER 6.2 -- horloge_seance (A §1.9). Le contrat livre le corps mais
-- signale lui-meme que son dernier `exists` est un EMPLACEMENT, pas la regle :
-- ici, le vrai predicat, calque sur mon_groupe_detail() (membre du groupe,
-- tuteur du foyer, enseignant assigne, admin).
-- ============================================================================

create or replace function public.horloge_seance(p_session_id uuid)
returns table (
  session_id          uuid,
  debut_utc           timestamptz,
  fin_prevue_utc      timestamptz,
  join_opens_at_utc   timestamptz,
  fenetre_minutes     int,
  grace_minutes       int,
  maintenant_utc      timestamptz,
  tz_utilisateur      text,
  heure_utilisateur   text,
  jour_iso_utilisateur int,
  date_utilisateur    date,
  tz_groupe           text,
  heure_groupe        text,
  jour_iso_groupe     int,
  date_groupe         date
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id,
    s.started_at,
    s.ended_at,
    coalesce(s.join_opens_at,
             s.started_at - make_interval(mins => public.app_config_int('join_window_minutes', 20))),
    public.app_config_int('join_window_minutes', 20),
    public.app_config_int('grace_after_end_minutes', 15),
    now(),
    public.mon_fuseau(),
    to_char(s.started_at at time zone public.mon_fuseau(), 'HH24:MI'),
    extract(isodow from s.started_at at time zone public.mon_fuseau())::int,
    (s.started_at at time zone public.mon_fuseau())::date,
    coalesce(g.timezone_iana, public.mon_fuseau()),
    to_char(s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()), 'HH24:MI'),
    extract(isodow from s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()))::int,
    (s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()))::date
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
  where s.id = p_session_id
    and s.deleted_at is null
    and public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or s.teacher_id = auth.uid()
      or exists (
        select 1 from public.session_participants sp
         where sp.session_id = s.id and sp.profile_id = auth.uid() and sp.deleted_at is null
      )
      or (g.id is not null and exists (
        select 1 from public.groupe_membres m
         where m.groupe_id = g.id and m.left_at is null
           and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
      ))
    );
$$;

revoke execute on function public.horloge_seance(uuid) from public, anon;
grant execute on function public.horloge_seance(uuid) to authenticated, agent_ro, service_role;

-- ============================================================================
-- PALIER 6.3 -- transitions_fuseau_a_venir (A §1.10). Le corps n'etait pas
-- fourni ("arbitrage technique qui appartient a qui ecrit la migration") :
-- comparaison semaine a semaine du decalage horaire de la meme occurrence,
-- exactement l'algorithme decrit en commentaire par le contrat.
-- Reservee a l'administration : c'est un ecran Operations > Planning.
-- ============================================================================

create or replace function public.transitions_fuseau_a_venir(p_jours int default 30)
returns table (
  groupe_id      uuid,
  fuseau         text,
  transition_utc timestamptz,
  heure_avant    text,
  heure_apres    text,
  jours_restants int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  return query
    with occurrences as (
      select
        g.id as gid,
        g.timezone_iana as tz,
        i,
        public.instant_creneau(g.weekday, g.hour_local, g.timezone_iana, i) as debut
      from public.groupes g
      cross join generate_series(0, 4) as i
      where g.ended_at is null
    ),
    paires as (
      -- Le decalage UTC d'un instant dans un fuseau : la difference entre son
      -- heure murale dans ce fuseau et son heure murale en UTC. `extract
      -- (timezone from ...)` ne s'applique qu'a un `timestamptz`, jamais au
      -- `timestamp` nu que rend `AT TIME ZONE` -- cette soustraction est la
      -- forme correcte.
      select
        o1.gid, o1.tz, o1.debut as debut_semaine, o2.debut as debut_semaine_suivante,
        (o1.debut at time zone o1.tz) - (o1.debut at time zone 'UTC') as decalage_avant,
        (o2.debut at time zone o1.tz) - (o2.debut at time zone 'UTC') as decalage_apres
      from occurrences o1
      join occurrences o2 on o2.gid = o1.gid and o2.i = o1.i + 1
    )
    select
      p.gid,
      p.tz,
      p.debut_semaine_suivante,
      to_char(p.debut_semaine at time zone p.tz, 'HH24:MI'),
      to_char(p.debut_semaine_suivante at time zone p.tz, 'HH24:MI'),
      extract(day from p.debut_semaine_suivante - now())::int
    from paires p
    where p.decalage_avant is distinct from p.decalage_apres
      and p.debut_semaine_suivante <= now() + make_interval(days => p_jours)
      and p.debut_semaine_suivante >= now();
end;
$$;

revoke execute on function public.transitions_fuseau_a_venir(int) from public, anon, agent_ro;
grant execute on function public.transitions_fuseau_a_venir(int) to authenticated;

-- ============================================================================
-- PALIER 6.4 -- creer_groupe / modifier_groupe : deux parametres de plus,
-- fuseau (A §1.3, validation IANA obligatoire) et couleur (A §1.6, deja bornee
-- par `groupes_couleur_jeton_check`, 0..39, en base).
-- ============================================================================

create or replace function public.creer_groupe(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_weekday smallint,
  p_hour_local smallint,
  p_seuil_max smallint default null,
  p_timezone_iana text default null,
  p_couleur_jeton smallint default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
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

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
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

  insert into public.groupes
    (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, couleur_jeton)
  values
    (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$$;

create or replace function public.modifier_groupe(
  p_groupe_id uuid,
  p_libelle text,
  p_seuil_max smallint,
  p_weekday smallint,
  p_hour_local smallint,
  p_timezone_iana text default null,
  p_couleur_jeton smallint default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actifs int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle,
      seuil_max = p_seuil_max,
      weekday = p_weekday,
      hour_local = p_hour_local,
      timezone_iana = coalesce(p_timezone_iana, timezone_iana),
      couleur_jeton = coalesce(p_couleur_jeton, couleur_jeton)
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$$;

-- groupes_admin() (A §1.2, demande jumelle) : quatre colonnes de plus en
-- sortie. `create or replace` refuse de changer un type `returns table`, donc
-- DROP + CREATE ; les droits sont perdus au DROP et reposes a l'identique de
-- l'existant (agent_ro, authenticated, service_role -- jamais anon).
drop function if exists public.groupes_admin();

create function public.groupes_admin()
returns table(
  groupe_id uuid, libelle text, type_public text, seuil_max smallint,
  teacher_id uuid, teacher_immutable_id text, teacher_prenom text, teacher_nom text,
  weekday smallint, hour_local smallint, nombre_membres integer, actif boolean,
  created_at timestamptz,
  timezone_iana text, couleur_jeton smallint, nom_cours text, programme_niveau_id uuid
)
language sql
stable
security definer
set search_path = ''
as $$
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
    g.created_at,
    g.timezone_iana,
    g.couleur_jeton,
    g.nom_cours,
    g.programme_niveau_id
  from public.groupes g
  join public.profiles p on p.id = g.teacher_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by (g.ended_at is not null), g.created_at desc;
$$;

revoke all on function public.groupes_admin() from public;
grant execute on function public.groupes_admin() to authenticated, agent_ro, service_role;

-- ============================================================================
-- PALIER 6.5 -- ressources_du_groupe (B §1.4). Le corps n'etait pas fourni
-- ("refuse si l'appelant n'est ni membre, ni tuteur, ni enseignant, ni
-- admin") : le filtre est ecrit ici, avant la requete, en exigence positive.
-- Seules les ressources dont la version COURANTE est publiee sont rendues :
-- meme discipline de publication que `programme_versions` (0020).
-- ============================================================================

create or replace function public.ressources_du_groupe(p_groupe_id uuid)
returns setof public.library_resource
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  return query
    select r.*
      from public.library_resource r
      join public.library_resource_groupe lrg on lrg.resource_id = r.id
      join public.resource_version rv on rv.id = r.current_version_id
     where lrg.groupe_id = p_groupe_id
       and rv.statut = 'publiee'
       and r.archived_at is null
     order by lrg.epinglee desc, r.title asc;
end;
$$;

revoke execute on function public.ressources_du_groupe(uuid) from public, anon;
grant execute on function public.ressources_du_groupe(uuid) to authenticated, agent_ro;

-- ============================================================================
-- PALIER 6.6 -- groupe_roster_enseignant (E §1.2). Construite SUR LE MODELE
-- de teacher_roster_v etendue, sans session_id : jamais groupe_detail(), qui
-- est admin-only et rend student_nom (ADR-008).
-- ============================================================================

create or replace function public.groupe_roster_enseignant(p_groupe_id uuid)
returns table (
  student_id      uuid,
  first_name      text,
  immutable_id    text,
  level           text,
  riwaya          text,
  interface_mode  public.interface_mode,
  curriculum_path text,
  current_unit    text,
  active_goals    text[],
  resume_page     int,
  resume_sourate  int,
  resume_verset   int
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    case when public.agent_identite_masquee() then p.immutable_id else p.first_name end,
    p.immutable_id,
    sp.level,
    sp.riwaya,
    sp.interface_mode,
    prog.cycle,
    prog.nom_humain,
    coalesce(goals.objectifs, '{}'),
    pos.page_mushaf,
    pos.sourate,
    pos.verset
  from public.groupe_membres m
    join public.groupes g on g.id = m.groupe_id
    join public.profiles p on p.id = m.student_id
    join public.student_profiles sp on sp.profile_id = p.id
    left join lateral (
      select pn.cycle, pn.nom_humain
        from public.progression_historique ph
        join public.programme_niveaux pn on pn.id = ph.niveau_id
       where ph.student_id = p.id
       order by ph.created_at desc
       limit 1
    ) prog on true
    left join lateral (
      select srp.page_mushaf, srp.sourate, srp.verset
        from public.student_reading_position srp
       where srp.student_profile_id = p.id
       order by srp.updated_at desc
       limit 1
    ) pos on true
    left join lateral (
      select array(
        select la.purpose
          from public.learning_assignment la
         where (la.student_id = p.id or (la.student_id is null and la.group_id = g.id))
           and la.status in ('a_faire', 'en_cours')
         order by la.due_at nulls last, la.starts_at
         limit 3
      ) as objectifs
    ) goals on true
  where m.groupe_id = p_groupe_id
    and m.left_at is null
    and p.deleted_at is null
    and g.teacher_id = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid();
$$;

revoke execute on function public.groupe_roster_enseignant(uuid) from public, anon, agent_ro;
grant execute on function public.groupe_roster_enseignant(uuid) to authenticated;

-- ============================================================================
-- PALIER 6.7 -- publier_etat_partage (F §3.3). La table `session_shared_content`
-- et sa RLS existent deja (0032) ; seule la RPC d'ecriture manquait. Ecrite
-- avec `search_path = ''` et noms qualifies -- jamais `set search_path = public`
-- comme le brouillon de F le montrait : tout y est deja qualifie, la migration
-- suit sa propre discipline plutot que de la relacher a la derniere ligne.
-- ============================================================================

create or replace function public.publier_etat_partage(
  p_session_id            uuid,
  p_resource_id           uuid,
  p_resource_version_id   uuid,
  p_content_position      jsonb,
  p_content_range         jsonb,
  p_display_mode          text,
  p_hidden_ranges         jsonb,
  p_semantic_markers      jsonb,
  p_group_resume_position jsonb,
  p_revision              integer
) returns public.session_shared_content
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ligne public.session_shared_content;
begin
  if not public.session_belongs_to_teacher(p_session_id, auth.uid())
     and public.app_role() <> 'admin' then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  insert into public.session_shared_content as c (
    session_id, resource_id, resource_version_id, content_position,
    content_range, display_mode, hidden_ranges, semantic_markers,
    group_resume_position, revision, updated_by, updated_at
  ) values (
    p_session_id, p_resource_id, p_resource_version_id, p_content_position,
    p_content_range, p_display_mode, p_hidden_ranges, p_semantic_markers,
    p_group_resume_position, p_revision, auth.uid(), now()
  )
  on conflict (session_id) do update
    set resource_id           = excluded.resource_id,
        resource_version_id   = excluded.resource_version_id,
        content_position      = excluded.content_position,
        content_range         = excluded.content_range,
        display_mode          = excluded.display_mode,
        hidden_ranges         = excluded.hidden_ranges,
        semantic_markers      = excluded.semantic_markers,
        group_resume_position = excluded.group_resume_position,
        revision              = excluded.revision,
        updated_by            = excluded.updated_by,
        updated_at            = excluded.updated_at
    where c.revision < excluded.revision
  returning * into v_ligne;

  if v_ligne.session_id is null then
    select * into v_ligne from public.session_shared_content
      where session_id = p_session_id;
  end if;

  return v_ligne;
end;
$$;

revoke execute on function public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)
  from public, anon, agent_ro;
grant execute on function public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)
  to authenticated;

-- ============================================================================
-- PALIER 6.8 -- Les sept fonctions d'observation (G §1.6). Toutes
-- security definer, search_path fige, grant a `authenticated` et JAMAIS a
-- `agent_ro` (ce sont, sauf les deux marquees stables, des ecritures).
-- Arbitrage §1.7 (fermeture serveur) tranche ici pour la voie SANS webhook :
-- `budget_observation` traite tout intervalle ouvert depuis plus que le TTL
-- du jeton comme clos au moment du calcul -- moins exact sur la trace, mais
-- suffisant pour le quota et sans dependance a un gestionnaire de webhook
-- LiveKit qui n'existe pas dans ce depot.
-- ============================================================================

create or replace function public.politique_observation_effective(p_groupe_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_g public.groupes;
  v_source text;
  v_activee boolean;
  v_max_visites int;
  v_max_secondes int;
  v_max_secondes_visite int;
  v_policy_version text;
begin
  select * into v_g from public.groupes where id = p_groupe_id;
  if not found then
    raise exception 'groupe introuvable' using errcode = 'no_data_found';
  end if;

  v_source := v_g.observation_source;

  -- L'interrupteur academie (app_config.observation.activee) prime sur tout :
  -- une desactivation globale n'est pas contournable groupe par groupe.
  if not coalesce((public.get_config('observation.activee', 'true'::jsonb))::boolean, true)
     or v_source = 'desactivee' then
    v_activee := false;
    v_max_visites := 0;
    v_max_secondes := 0;
    v_max_secondes_visite := null;
    v_policy_version := 'desactivee';
  elsif v_source = 'groupe' then
    v_activee := true;
    v_max_visites := v_g.observation_max_visites;
    v_max_secondes := v_g.observation_max_secondes;
    v_max_secondes_visite := v_g.observation_max_secondes_par_visite;
    v_policy_version := 'groupe:' || v_g.observation_revision::text;
  else
    v_activee := true;
    v_max_visites := public.app_config_int('observation.max_visits_per_session', 1);
    v_max_secondes := public.app_config_int('observation.max_total_seconds', 120);
    v_max_secondes_visite := nullif(public.get_config('observation.max_seconds_per_visit', 'null'::jsonb)::text, 'null')::int;
    v_policy_version := coalesce(public.get_config('observation.policy_version', '"a1"'::jsonb) #>> '{}', 'a1');
  end if;

  return jsonb_build_object(
    'policy_version', v_policy_version,
    'source', v_source,
    'observation_activee', v_activee,
    'max_visits_per_session', v_max_visites,
    'max_total_observation_seconds', v_max_secondes,
    'max_seconds_per_visit', v_max_secondes_visite
  );
end;
$$;

revoke execute on function public.politique_observation_effective(uuid) from public, anon, agent_ro;
grant execute on function public.politique_observation_effective(uuid) to authenticated;

create or replace function public.budget_observation(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_seance  public.sessions%rowtype;
  v_pol     jsonb;
  v_ttl     int;
  v_visites int;
  v_temps   int;
  v_max_v   int;
  v_max_t   int;
  v_peut    boolean;
  v_motif   text;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('peut_entrer', false, 'motif_refus', 'seance_non_active');
  end if;

  v_pol   := public.politique_observation_effective(v_seance.groupe_id);
  v_max_v := (v_pol->>'max_visits_per_session')::int;
  v_max_t := (v_pol->>'max_total_observation_seconds')::int;

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  select count(*) into v_visites
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  -- Intervalle ouvert compte, plafonne au TTL du jeton (arbitrage §1.7).
  select coalesce(sum(
    case
      when v.left_at is not null
        then coalesce(v.duration_seconds, extract(epoch from (v.left_at - v.entered_at))::int)
      when now() - v.entered_at >= make_interval(secs => v_ttl) then v_ttl
      else extract(epoch from (now() - v.entered_at))::int
    end
  ), 0) into v_temps
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  if not (v_pol->>'observation_activee')::boolean then
    v_peut := false; v_motif := 'policy_desactivee';
  elsif v_visites >= v_max_v then
    v_peut := false; v_motif := 'quota_visites_atteint';
  elsif v_temps >= v_max_t then
    v_peut := false; v_motif := 'temps_epuise';
  else
    v_peut := true; v_motif := null;
  end if;

  return jsonb_build_object(
    'policy_version', v_pol->>'policy_version',
    'visites_utilisees', v_visites,
    'visites_max', v_max_v,
    'temps_consomme_secondes', v_temps,
    'temps_total_max_secondes', v_max_t,
    'restant_secondes', greatest(0, v_max_t - v_temps),
    'peut_entrer', v_peut,
    'motif_refus', v_motif
  );
end;
$$;

revoke execute on function public.budget_observation(uuid) from public, anon, agent_ro;
grant execute on function public.budget_observation(uuid) to authenticated;

-- entrer_observation : porte UNIQUE pour les trois roles d'observation neufs
-- (guardian_observer, admin_masked, admin_visible). `rejoindre_observation`
-- (0012) reste la porte du controleur qualite, inchangee. L'ordre EST la
-- garantie (G §1.6) : fenetre, droit au role, lien tuteur-enfant, politique,
-- quota, ALORS SEULEMENT l'ecriture -- les trois dernieres etapes ne
-- s'appliquent qu'a `guardian_observer` : la surveillance administrative
-- n'est ni un lien tuteur-enfant, ni soumise a l'interrupteur parental, ni
-- quotee.
create or replace function public.entrer_observation(p_session_id uuid, p_role text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_enfant    uuid;
  v_pol       jsonb;
  v_budget    jsonb;
  v_visit_id  uuid;
  v_visit_num smallint;
begin
  if p_role not in ('guardian_observer', 'admin_masked', 'admin_visible') then
    raise exception 'role d''observation inconnu : %', p_role using errcode = 'invalid_parameter_value';
  end if;
  v_role := p_role::public.participant_role;

  if not public.app_account_valid() then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  -- 1. La seance existe et est dans la fenetre.
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('autorise', false, 'motif_refus', 'seance_non_active');
  end if;
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre))
     or now() > v_seance.ended_at + make_interval(mins => v_grace) then
    return jsonb_build_object('autorise', false, 'motif_refus', 'hors_fenetre');
  end if;

  -- 2. Le droit de tenir CE role.
  if v_role = 'guardian_observer' and public.app_role() <> 'guardian' then
    raise exception 'observation reservee au tuteur' using errcode = 'insufficient_privilege';
  end if;
  if v_role in ('admin_masked', 'admin_visible') and public.app_role() <> 'admin' then
    raise exception 'observation reservee a l''administration' using errcode = 'insufficient_privilege';
  end if;

  -- 3. Lien tuteur-enfant dans CE groupe -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    select m.student_id into v_enfant
      from public.groupe_membres m
     where m.groupe_id = v_seance.groupe_id
       and m.left_at is null
       and public.est_du_foyer(m.student_id)
     limit 1;
    if v_enfant is null then
      return jsonb_build_object('autorise', false, 'motif_refus', 'lien_tuteur_absent');
    end if;
  end if;

  -- 4. Politique du groupe -- guardian_observer seulement.
  v_pol := public.politique_observation_effective(v_seance.groupe_id);
  if v_role = 'guardian_observer' and not (v_pol->>'observation_activee')::boolean then
    return jsonb_build_object('autorise', false, 'motif_refus', 'policy_desactivee');
  end if;

  -- 5. Quota -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      return jsonb_build_object(
        'autorise', false,
        'motif_refus', v_budget->>'motif_refus',
        'budget', v_budget
      );
    end if;
  end if;

  -- 6. Alors seulement : ecriture, y compris pour un role incognito.
  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), v_role)
  on conflict (session_id, profile_id) do update set role = excluded.role, deleted_at = null;

  select coalesce(max(v.visit_number), 0) + 1 into v_visit_num
    from public.guardian_session_visit v
   where v.session_id = p_session_id and v.observateur_profile_id = auth.uid();

  insert into public.guardian_session_visit (
    session_id, groupe_id, observateur_profile_id, role, enfant_profile_id,
    visit_number, policy_version
  ) values (
    p_session_id, v_seance.groupe_id, auth.uid(), v_role, v_enfant,
    v_visit_num, coalesce(v_pol->>'policy_version', '')
  )
  returning id into v_visit_id;

  perform public.log_sensitive_access(
    'observation_entree', 'guardian_session_visit', v_visit_id::text,
    jsonb_build_object('session_id', p_session_id, 'role', v_role, 'enfant_profile_id', v_enfant)
  );

  return jsonb_build_object(
    'autorise', true,
    'motif_refus', null,
    'visite', jsonb_build_object('id', v_visit_id, 'visit_number', v_visit_num),
    'budget', case when v_role = 'guardian_observer' then public.budget_observation(p_session_id) else null end
  );
end;
$$;

revoke execute on function public.entrer_observation(uuid, text) from public, anon, agent_ro;
grant execute on function public.entrer_observation(uuid, text) to authenticated;

create or replace function public.sortir_observation(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_visite public.guardian_session_visit;
begin
  update public.guardian_session_visit v
     set left_at = now(),
         duration_seconds = extract(epoch from (now() - v.entered_at))::int,
         fin_de_visite = 'utilisateur'
   where v.id = (
     select id from public.guardian_session_visit
      where session_id = p_session_id and observateur_profile_id = auth.uid() and left_at is null
      order by entered_at desc limit 1
   )
  returning * into v_visite;

  if not found then
    return jsonb_build_object('ferme', false);
  end if;

  perform public.log_sensitive_access(
    'observation_sortie', 'guardian_session_visit', v_visite.id::text,
    jsonb_build_object('session_id', p_session_id, 'duration_seconds', v_visite.duration_seconds)
  );

  return jsonb_build_object('ferme', true, 'duration_seconds', v_visite.duration_seconds);
end;
$$;

revoke execute on function public.sortir_observation(uuid) from public, anon, agent_ro;
grant execute on function public.sortir_observation(uuid) to authenticated;

create or replace function public.visites_observation(p_session_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', v.id,
    'role', v.role,
    'entered_at', v.entered_at,
    'left_at', v.left_at,
    'duration_seconds', v.duration_seconds,
    'visit_number', v.visit_number,
    'fin_de_visite', v.fin_de_visite
  ) order by v.entered_at), '[]'::jsonb)
  from public.guardian_session_visit v
  where v.session_id = p_session_id
    and (v.observateur_profile_id = auth.uid() or public.app_role() = 'admin');
$$;

revoke execute on function public.visites_observation(uuid) from public, anon, agent_ro;
grant execute on function public.visites_observation(uuid) to authenticated;

-- annonces_observation : reservee a l'enseignant, rend un PRENOM et des
-- SECONDES, jamais une phrase (le francais se fabrique en Dart). Le contrat
-- ne precise pas la source du compte a rebours par observateur : ici, le
-- plafond PAR VISITE s'il existe, sinon le budget TOTAL restant du groupe.
create or replace function public.annonces_observation(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_seance public.sessions%rowtype;
  v_pol    jsonb;
begin
  select * into v_seance from public.sessions s where s.id = p_session_id and s.deleted_at is null;
  if not found or v_seance.teacher_id <> auth.uid() then
    raise exception 'reserve a l''enseignant de la seance' using errcode = 'insufficient_privilege';
  end if;

  v_pol := public.politique_observation_effective(v_seance.groupe_id);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'enfant_prenom', case when public.agent_identite_masquee() then p.immutable_id else p.first_name end,
      'enfant_profile_id', v.enfant_profile_id,
      'restant_secondes', greatest(0, (
        case when v_pol->>'max_seconds_per_visit' is not null
             then (v_pol->>'max_seconds_per_visit')::int
             else (v_pol->>'max_total_observation_seconds')::int
        end
      ) - extract(epoch from (now() - v.entered_at))::int)
    ))
    from public.guardian_session_visit v
      left join public.profiles p on p.id = v.enfant_profile_id
    where v.session_id = p_session_id
      and v.role = 'guardian_observer'
      and v.left_at is null
  ), '[]'::jsonb);
end;
$$;

revoke execute on function public.annonces_observation(uuid) from public, anon, agent_ro;
grant execute on function public.annonces_observation(uuid) to authenticated;

create or replace function public.definir_politique_observation_groupe(
  p_groupe_id uuid, p_source text,
  p_max_visites smallint, p_max_secondes integer
) returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  if p_source not in ('academie', 'groupe', 'desactivee') then
    raise exception 'source de politique inconnue : %', p_source using errcode = 'invalid_parameter_value';
  end if;

  -- La revision est bumpee par le declencheur existant
  -- (tc_groupes_observation_bump_revision, 0030) : rien a faire ici.
  update public.groupes
     set observation_source = p_source,
         observation_max_visites = p_max_visites,
         observation_max_secondes = p_max_secondes
   where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture' using errcode = 'no_data_found';
  end if;

  perform public.log_sensitive_access(
    'observation_politique_groupe_modifiee', 'groupes', p_groupe_id::text,
    jsonb_build_object('source', p_source, 'max_visites', p_max_visites, 'max_secondes', p_max_secondes)
  );

  return public.politique_observation_effective(p_groupe_id);
end;
$$;

revoke execute on function public.definir_politique_observation_groupe(uuid, text, smallint, integer)
  from public, anon, agent_ro;
grant execute on function public.definir_politique_observation_groupe(uuid, text, smallint, integer)
  to authenticated;

-- ============================================================================
-- PALIER 6.9 -- doit_demander_feedback / derniere_position_groupe (H §1.3,
-- §1.5). Corps non fournis par le contrat ; ecrits ici.
-- derniere_position_groupe reutilise `session_shared_content.group_resume_position`
-- (F, deja en base depuis 0032) -- decision produit : pas de nouvelle table.
-- ============================================================================

create or replace function public.doit_demander_feedback(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_seance    public.sessions%rowtype;
  v_cadence   int := public.app_config_int('feedback_cadence_seances', 4);
  v_rang      int;
  v_sel       text;
  v_empreinte bytea;
  v_repondu   boolean;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found or v_cadence <= 0 then
    return null;
  end if;

  if not exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id and sp.profile_id = auth.uid()
      and sp.role = 'student' and sp.deleted_at is null
  ) then
    return null;
  end if;

  select count(*) into v_rang
    from public.sessions s
    join public.session_participants sp on sp.session_id = s.id
   where s.groupe_id = v_seance.groupe_id
     and sp.profile_id = auth.uid()
     and sp.role = 'student'
     and sp.deleted_at is null
     and s.deleted_at is null
     and s.started_at <= v_seance.started_at;

  if v_rang % v_cadence <> 0 then
    return null;
  end if;

  select (value #>> '{}') into v_sel from public.app_config where key = 'feedback_empreinte_sel';
  v_empreinte := extensions.digest(p_session_id::text || auth.uid()::text || coalesce(v_sel, ''), 'sha256');

  select exists (
    select 1 from public.session_feedback f
    where f.session_id = p_session_id and f.auteur_empreinte = v_empreinte
  ) into v_repondu;

  return jsonb_build_object(
    'groupe_id', v_seance.groupe_id,
    'rang_seance', v_rang,
    'deja_repondu', v_repondu
  );
end;
$$;

revoke execute on function public.doit_demander_feedback(uuid) from public, anon, agent_ro;
grant execute on function public.doit_demander_feedback(uuid) to authenticated;

create or replace function public.derniere_position_groupe(p_groupe_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_autorise boolean;
  v_position jsonb;
begin
  select exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) into v_autorise;

  if not v_autorise then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  select c.group_resume_position into v_position
    from public.session_shared_content c
    join public.sessions s on s.id = c.session_id
   where s.groupe_id = p_groupe_id
     and s.deleted_at is null
     and c.group_resume_position is not null
   order by s.started_at desc
   limit 1;

  return v_position;
end;
$$;

revoke execute on function public.derniere_position_groupe(uuid) from public, anon, agent_ro;
grant execute on function public.derniere_position_groupe(uuid) to authenticated;

-- ============================================================================
-- PALIER 7 -- Le point chaud. Trois fonctions deja vivantes, gouvernant
-- l'entree en salle video REELLE aujourd'hui. Fusion A + G + Q.
-- ============================================================================

-- guard_session_participant_cap / guard_session_overlap (G §1.4) : les deux
-- listes d'exemption s'etendent a admin_masked et admin_visible -- exactement
-- le defaut 2 de 0012 qu'il ne faut pas reproduire pour l'administration.
create or replace function public.guard_session_participant_cap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  allow_multi boolean;
  max_participants int;
  current_count int;
begin
  if new.role in ('masked_controller', 'guardian_observer', 'admin_masked', 'admin_visible') then
    return new;
  end if;

  select (value)::boolean into allow_multi
  from public.app_config where key = 'allow_multi_participant_sessions';
  if allow_multi is null then allow_multi := false; end if;

  select coalesce(value #>> '{}', '2')::int into max_participants
  from public.app_config where key = 'max_participants_per_session';
  if max_participants is null then max_participants := 2; end if;

  if not allow_multi then
    select count(*) into current_count
    from public.session_participants
    where session_id = new.session_id and deleted_at is null
      and role in ('teacher', 'student');
    if current_count >= max_participants then
      raise exception 'plafond de participants atteint';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_session_overlap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.role in ('masked_controller', 'guardian_observer', 'admin_masked', 'admin_visible') then
    return new;
  end if;

  if exists (
    select 1
    from public.session_participants sp
    join public.sessions s1 on s1.id = sp.session_id
    join public.sessions s2 on s2.id = new.session_id
    where sp.profile_id = new.profile_id
      and sp.deleted_at is null
      and sp.role in ('teacher', 'student')
      and s1.deleted_at is null and s2.deleted_at is null
      and s1.status in ('planned', 'preflight', 'in_progress')
      and tstzrange(s1.started_at, s1.ended_at, '[)')
          && tstzrange(s2.started_at, s2.ended_at, '[)')
      and s1.id <> s2.id
  ) then
    raise exception 'chevauchement de sessions pour le meme profil';
  end if;
  return new;
end;
$$;

-- etat_presence : la fenetre T-10 en dur devient app_config.join_window_minutes
-- (A §1.4, "les trois ensemble, jamais separement" -- ceci est le troisieme).
create or replace function public.etat_presence(
  p_session_id uuid,
  p_profile_id uuid
) returns public.presence_state
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_seance         public.sessions%rowtype;
  v_override       public.presence_state;
  v_premier_joined timestamptz;
  v_dernier_type   public.session_event_type;
  v_dernier_ts     timestamptz;
  v_dernier_source text;
  v_left_subi      boolean;
  v_jeton_le       timestamptz;
  v_seuil_retard   int := public.app_config_int('presence.seuil_retard_secondes', 300);
  v_fenetre_reco   int := public.app_config_int('presence.fenetre_reconnexion_secondes', 120);
  v_fenetre_conn   int := public.app_config_int('presence.fenetre_connexion_secondes', 90);
  v_fenetre_join   int := public.app_config_int('join_window_minutes', 20);
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return null;
  end if;

  select o.etat into v_override from public.session_presence_override o
   where o.session_id = p_session_id and o.profile_id = p_profile_id;
  if v_override is not null then
    return v_override;
  end if;

  select min(e.server_ts) into v_premier_joined
    from public.session_events e
   where e.session_id = p_session_id
     and e.profile_id = p_profile_id
     and e.event_type = 'joined';

  select e.event_type, e.server_ts, e.source
    into v_dernier_type, v_dernier_ts, v_dernier_source
    from public.session_events e
   where e.session_id = p_session_id
     and e.profile_id = p_profile_id
     and e.event_type in ('joined', 'left', 'track_subscribed')
   order by e.server_ts desc, e.id desc
   limit 1;

  if v_premier_joined is null then
    if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
      return 'absente';
    end if;

    select max(g.emis_le) into v_jeton_le
      from public.video_token_grants g
     where g.session_id = p_session_id
       and g.profile_id = p_profile_id;

    if v_jeton_le is not null
       and now() - v_jeton_le <= make_interval(secs => v_fenetre_conn) then
      return 'en_connexion';
    end if;

    if now() < v_seance.started_at - make_interval(mins => v_fenetre_join) then
      return 'planifiee';
    end if;
    return 'en_attente';
  end if;

  if v_dernier_type = 'left' then
    if v_dernier_source = 'user_action' then
      return 'sortie';
    end if;
    if now() - v_dernier_ts <= make_interval(secs => v_fenetre_reco) then
      return 'en_reconnexion';
    end if;
    return 'deconnectee';
  end if;

  select exists (
    select 1 from public.session_events e
     where e.session_id = p_session_id
       and e.profile_id = p_profile_id
       and e.event_type = 'left'
       and e.source <> 'user_action'
       and e.server_ts < v_dernier_ts
  ) into v_left_subi;

  if v_left_subi then
    return 'reconnectee';
  end if;

  if v_premier_joined > v_seance.started_at + make_interval(secs => v_seuil_retard) then
    return 'en_retard';
  end if;

  if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
    return 'confirmation_en_attente';
  end if;

  return 'presente';
end;
$$;

-- autoriser_jeton_video : fusion A (fenetre configurable, grace configurable)
-- + G (capacites admin_masked/admin_visible, quota AVANT jeton pour
-- guardian_observer, identite institutionnelle) + Q (le quota precede
-- toujours l'emission, jamais l'inverse -- "un jeton d'abord et un quota
-- ensuite a deja laisse entrer").
create or replace function public.autoriser_jeton_video(
  p_session_id uuid,
  p_profile_id uuid,
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_route     record;
  v_ttl       int;
  v_camera    public.camera_policy;
  v_publier       boolean;
  v_publier_video boolean;
  v_publier_data  boolean;
  v_invisible     boolean;
  v_expire    timestamptz;
  v_identite  text;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_budget    jsonb;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  if not found then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  -- La fenetre d'ouverture : configurable (D-13, 20 min par defaut), jusqu'a
  -- la fin annoncee majoree de la grace configurable.
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre)) then
    raise exception 'salle pas encore ouverte' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + make_interval(mins => v_grace) then
    raise exception 'salle fermee' using errcode = 'check_violation';
  end if;

  -- Le quota PRECEDE le jeton pour un observateur-tuteur : un jeton d'abord
  -- et un quota ensuite a deja laisse entrer (G §1.5, confirme par Q).
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      raise exception 'quota d''observation atteint : %', v_budget->>'motif_refus'
        using errcode = 'check_violation';
    end if;
  end if;

  select * into v_route from public.video_route_de_seance(
    p_session_id, p_ws_url_cloud, p_ws_url_self_hosted
  );

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  -- Les capacites. Table de G §1.5 :
  --   guardian_observer : rien ne se publie, masque, ttl borne par le budget.
  --   admin_masked      : rien ne se publie, masque comme un controleur.
  --   admin_visible     : voix + image, JAMAIS le canal de donnees (c'est
  --                       l'enseignant qui garde la main pedagogique), visible.
  --   masked_controller : inchange (0010/0012).
  v_identite      := p_profile_id::text;
  v_invisible     := (v_role in ('masked_controller', 'admin_masked'));
  v_publier       := v_role in ('teacher', 'student', 'admin_visible');
  v_publier_data  := (v_role = 'teacher');
  v_publier_video := (v_role = 'admin_visible');

  if v_role = 'teacher' then
    v_publier_video := true;
  elsif v_role = 'student' then
    select sp.camera_policy into v_camera
      from public.student_profiles sp
     where sp.profile_id = p_profile_id;
    v_publier_video := (coalesce(v_camera, 'forbidden') = 'allowed');
  end if;

  if v_role = 'guardian_observer' then
    v_expire := now() + make_interval(secs => least(v_ttl, ((v_budget->>'restant_secondes')::int)));
  else
    v_expire := now() + make_interval(secs => v_ttl);
  end if;

  -- L'identite institutionnelle : c'est l'institution qui entre, pas
  -- quelqu'un. Jamais le prenom de la personne pour admin_visible.
  if v_role = 'admin_visible' then
    v_identite := 'Administration Rewayah';
  end if;

  insert into public.video_token_grants (
    session_id, profile_id, role, provider,
    can_publish, can_publish_video, can_publish_data, hidden, expire_le
  ) values (
    p_session_id, p_profile_id, v_role, v_route.provider,
    v_publier, v_publier_video, v_publier_data, v_invisible, v_expire
  );

  perform public.log_sensitive_access(
    'video_token_issued',
    'video_token_grants',
    p_session_id::text,
    jsonb_build_object(
      'profile_id', p_profile_id,
      'role', v_role,
      'provider', v_route.provider,
      'hidden', v_invisible
    )
  );

  return jsonb_build_object(
    'ws_url', v_route.ws_url,
    'room_name', v_route.room_name,
    'provider', v_route.provider,
    'identity', v_identite,
    'role', v_role,
    'ttl_seconds', extract(epoch from (v_expire - now()))::int,
    'expire_le', v_expire,
    'capabilities', jsonb_build_object(
      'can_publish', v_publier,
      'can_publish_video', v_publier_video,
      'can_publish_data', v_publier_data,
      'can_subscribe', true,
      'hidden', v_invisible
    )
  );
end;
$$;

-- Fin de 0033. Verification de sortie : les 18 objets de ce fichier existent.
do $$
begin
  if to_regclass('public.mes_groupes_famille_v') is null
     or to_regclass('public.tendance_feedback_v') is null
     or to_regclass('public.concern_famille_v') is null
     or to_regprocedure('public.materialiser_seances_groupe(uuid)') is null
     or to_regprocedure('public.entrer_observation(uuid, text)') is null
     or to_regprocedure('public.autoriser_jeton_video(uuid, uuid, text, text)') is null
  then
    raise exception '0033 incomplete : verification de sortie echouee';
  end if;
end $$;
