-- 0005 : ce que l'etape 4 exige de la base
--
-- Source de verite : docs/architecture/etape-4-dashboards.md
--
-- Cette migration corrige les huit defauts de la section 3 de ce document, puis
-- ajoute les tables et fonctions dont les tableaux de bord, l'affectation
-- durable, les disponibilites, les regles par eleve et les prieres ont besoin.
-- Comme a l'etape 3, aucun de ces defauts n'etait visible d'une relecture de
-- schema : ils apparaissent quand on essaie de construire les ecrans.
--
-- Regles heritees de l'etape 1, appliquees ici sans exception :
--   - RLS activee sur toute table nouvelle ;
--   - toute fonction SECURITY DEFINER fixe search_path = '' et qualifie ;
--   - une fonction qui contourne la RLS reverifie l'autorisation metier ;
--   - suppression logique filtree dans chaque policy ;
--   - on expose par une vue, on ne durcit pas une policy pour cacher une colonne.
--
-- Ordre des sections : les tables d'abord, les fonctions ensuite, les policies
-- en dernier. Postgres valide le corps d'une fonction SQL et l'expression d'une
-- policy a leur creation : une fonction ecrite avant sa table ferait echouer la
-- migration entiere, defaut deja paye a l'etape 2 avec le stub `auth` de la CI.

begin;

-- ============================================================
-- 1. Aucune regle n'est figee (ADR-017 section 2.4, defaut 3.7)
-- ============================================================

-- Les quatre valeurs qui decident de ce qu'une grille affiche et de ce que la
-- base accepte. Ce sont des DEFAUTS de plateforme : la valeur qui s'applique a
-- un profil donne se lit par regle_effective(), jamais ici.
insert into public.app_config (key, value) values
  ('session_duration_minutes', '60'::jsonb),
  ('session_paid_minimum_minutes', '45'::jsonb),
  ('break_minutes_between_sessions', '30'::jsonb),
  ('max_students_per_teacher', '5'::jsonb),
  ('matching_horizon_weeks', '4'::jsonb)
on conflict (key) do nothing;

-- La surcharge d'un profil. Une valeur unique pour toute la plateforme se paie
-- en litiges : un enfant de six ans qui decroche a trente minutes et un adulte
-- autonome qui veut deux heures ne relevent pas de la meme regle.
--
-- Une surcharge ne se supprime pas, elle se clot : « la seance durait 45 minutes
-- ce jour-la » est une phrase qui doit se verifier six mois plus tard.
create table public.rule_overrides (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  key text not null check (key in (
    'session_duration_minutes',
    'session_paid_minimum_minutes',
    'break_minutes_between_sessions',
    'max_students_per_teacher'
  )),
  value jsonb not null,
  reason text not null,
  set_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references public.profiles(id),
  end_reason text,
  constraint rule_overrides_end_complete check (
    (ended_at is null and ended_by is null and end_reason is null)
    or (ended_at is not null and ended_by is not null and coalesce(btrim(end_reason), '') <> '')
  )
);

-- Une seule surcharge active par profil et par cle : deux valeurs actives ne
-- diraient pas laquelle s'applique.
create unique index rule_overrides_active_uidx
  on public.rule_overrides (profile_id, key) where ended_at is null;

comment on table public.rule_overrides is
  'Regle propre a un profil, qui prime sur le defaut de app_config. Posee par '
  'l''administration, a la volee ou sur demande d''une des quatre parties '
  '(ADR-017). Ne se supprime jamais : elle se clot.';

alter table public.rule_overrides enable row level security;

-- La cle doit correspondre au role du profil : un plafond d'eleves ne veut rien
-- dire sur un eleve, une duree de seance ne veut rien dire sur un enseignant.
create function public.guard_rule_override_coherente()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_role public.app_role;
begin
  select p.role into v_role from public.profiles p where p.id = new.profile_id;

  if new.key = 'max_students_per_teacher' and v_role is distinct from 'teacher' then
    raise exception 'un plafond d''eleves ne se pose que sur un enseignant';
  end if;
  if new.key <> 'max_students_per_teacher' and v_role is distinct from 'student' then
    raise exception 'cette regle ne se pose que sur un eleve';
  end if;
  if (new.value #>> '{}') !~ '^[0-9]+$' or (new.value #>> '{}')::int <= 0 then
    raise exception 'une regle est un entier positif';
  end if;
  return new;
end;
$$;

create trigger rule_overrides_coherence
before insert on public.rule_overrides
for each row execute function public.guard_rule_override_coherente();

-- I11 : une surcharge se clot, elle ne se reecrit pas. Seules les trois colonnes
-- de cloture peuvent changer, et une fois seulement.
create function public.guard_rule_override_immutable()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'une regle ayant compte pour une seance ne s''efface pas';
  end if;

  if old.ended_at is not null then
    raise exception 'cette regle est deja close';
  end if;

  if new.profile_id <> old.profile_id or new.key <> old.key
     or new.value <> old.value or new.reason <> old.reason
     or new.set_by <> old.set_by or new.created_at <> old.created_at then
    raise exception 'seule la cloture d''une regle est modifiable';
  end if;

  return new;
end;
$$;

create trigger rule_overrides_no_delete
before delete on public.rule_overrides
for each row execute function public.guard_rule_override_immutable();

create trigger rule_overrides_close_only
before update on public.rule_overrides
for each row execute function public.guard_rule_override_immutable();

revoke all on public.rule_overrides from anon;
revoke insert, update, delete on public.rule_overrides
  from public, anon, authenticated;

-- ============================================================
-- 2. L'affectation durable (defaut 3.2, ADR-017 section 2.1)
-- ============================================================

-- Rien dans le schema ne disait qu'un eleve est suivi par un enseignant : la
-- relation n'existait qu'indirectement, seance par seance. Sans elle, ENS-06 n'a
-- pas d'eleve a prendre, TUT-01 ne peut pas afficher « en recherche d'un
-- enseignant », ADM-01 ne peut pas compter les foyers sans enseignant.
--
-- « Le matching, c'est un mariage » : ce que prend ENS-06 est un ELEVE, le
-- creneau n'etant que l'heure du rendez-vous hebdomadaire qui en decoule.
create table public.teacher_student_assignments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  -- ISO : 1 = lundi, 7 = dimanche, comme extract(isodow).
  weekday smallint not null check (weekday between 1 and 7),
  hour_local smallint not null check (hour_local between 0 and 23),
  timezone_iana text not null default 'Europe/Paris',
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references public.profiles(id),
  end_reason text,
  constraint assignments_end_complete check (
    (ended_at is null and ended_by is null and end_reason is null)
    or (ended_at is not null and ended_by is not null and coalesce(btrim(end_reason), '') <> '')
  )
);

-- I1 : un eleve a au plus un enseignant actif. C'est aussi ce qui tranche I4 :
-- deux enseignants qui prennent le meme eleve au meme instant se disputent cet
-- index, et un seul passe.
create unique index assignments_one_active_teacher_uidx
  on public.teacher_student_assignments (student_id) where ended_at is null;

create index assignments_teacher_active_idx
  on public.teacher_student_assignments (teacher_id) where ended_at is null;

comment on table public.teacher_student_assignments is
  'L''affectation durable de l''ADR-017. Elle ne se rompt que par une demande de '
  'reaffectation tranchee par l''administration : aucune policy d''ecriture '
  'directe n''existe, seules les fonctions de cette migration ecrivent ici.';

alter table public.teacher_student_assignments enable row level security;

-- I2 : le plafond est tranche en base, et il se lit par surcharge d'abord, donc
-- un enseignant peut avoir le sien.
create function public.guard_assignment_cap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_max int;
  v_actifs int;
begin
  if new.ended_at is not null then
    return new;
  end if;

  -- regle_brute et non regle_effective : le declencheur tourne aussi pour un
  -- appelant qui n'est pas partie concernee, et un plafond ne se contourne pas
  -- faute de droit de lecture.
  v_max := public.regle_brute(new.teacher_id, 'max_students_per_teacher');

  select count(*) into v_actifs
  from public.teacher_student_assignments a
  where a.teacher_id = new.teacher_id and a.ended_at is null and a.id <> new.id;

  if v_actifs >= v_max then
    raise exception 'plafond d''eleves atteint pour cet enseignant (%)', v_max;
  end if;

  return new;
end;
$$;

create trigger assignments_cap
before insert on public.teacher_student_assignments
for each row execute function public.guard_assignment_cap();

-- I3 : personne n'ecrit ici a la main, pas meme l'administration. Une affectation
-- se cree par prendre_eleve() et se clot par decider_demande().
revoke all on public.teacher_student_assignments from anon;
revoke insert, update, delete on public.teacher_student_assignments
  from public, anon, authenticated;

-- ============================================================
-- 3. Qui est partie concernee, et ce qu'une regle vaut vraiment
-- ============================================================

-- Les quatre parties de l'ADR-017, et personne d'autre. En SECURITY DEFINER pour
-- la meme raison que les ponts de l'etape 1 : les EXISTS croises entre profiles
-- et les affectations boucleraient sur leurs propres policies.
create function public.partie_concernee(p_profile_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    public.app_role() in ('admin', 'controller')
    or p_profile_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = p_profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
    or exists (
      select 1 from public.teacher_student_assignments a
      where a.ended_at is null
        and (
          (a.teacher_id = auth.uid() and a.student_id = p_profile_id)
          or (a.student_id = auth.uid() and a.teacher_id = p_profile_id)
        )
    )
    -- Le foyer est partie au dossier de l'enseignant de son enfant. Sans cette
    -- branche, un tuteur ne pourrait lire ni les disponibilites ni les reglages
    -- de priere de la personne qui fait cours a son enfant : la transparence
    -- exigee par l'ADR-017 s'arreterait a l'enfant lui-meme, qui a six ans.
    or exists (
      select 1
      from public.teacher_student_assignments a
      join public.profiles eleve on eleve.id = a.student_id
      where a.ended_at is null
        and a.teacher_id = p_profile_id
        and eleve.household_id is not null
        and eleve.household_id = public.app_household_id()
        and eleve.deleted_at is null
    );
$$;

revoke execute on function public.partie_concernee(uuid) from public, anon;
grant execute on function public.partie_concernee(uuid) to authenticated, service_role;

-- Le calcul nu : surcharge active si elle existe, defaut de plateforme sinon.
-- Sans controle d'acces, donc **jamais accordee a un client** : elle sert aux
-- declencheurs et aux taches, qui doivent trancher meme quand l'appelant n'a pas
-- le droit de lire la regle. Un plafond ne se contourne pas faute de droit de
-- lecture.
create function public.regle_brute(p_profile_id uuid, p_key text)
returns int
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_valeur text;
begin
  select r.value #>> '{}' into v_valeur
  from public.rule_overrides r
  where r.profile_id = p_profile_id and r.key = p_key and r.ended_at is null;

  if v_valeur is null then
    select public.get_config(p_key, null) #>> '{}' into v_valeur;
  end if;

  if v_valeur is null then
    raise exception 'regle inconnue : %', p_key;
  end if;
  return v_valeur::int;
end;
$$;

revoke execute on function public.regle_brute(uuid, text)
  from public, anon, authenticated;
grant execute on function public.regle_brute(uuid, text) to service_role;

-- La valeur qui s'applique reellement, cote client. **Seul chemin de lecture
-- d'une regle** (I10) : un ecran qui lirait app_config en direct afficherait la
-- regle de la plateforme a un eleve qui n'en releve pas, et l'ecart ne se
-- verrait qu'au moment de la facture.
create function public.regle_effective(p_profile_id uuid, p_key text)
returns int
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.partie_concernee(p_profile_id) then
    raise exception 'regles hors du perimetre de lecture';
  end if;
  return public.regle_brute(p_profile_id, p_key);
end;
$$;

revoke execute on function public.regle_effective(uuid, text) from public, anon;
grant execute on function public.regle_effective(uuid, text) to authenticated, service_role;

create policy rule_overrides_parties_read on public.rule_overrides
  for select to authenticated using (public.partie_concernee(profile_id));

create policy assignments_privileged_read on public.teacher_student_assignments
  for select to authenticated
  using (public.app_role() in ('admin', 'controller', 'accountant'));

create policy assignments_parties_read on public.teacher_student_assignments
  for select to authenticated
  using (public.partie_concernee(student_id) or teacher_id = auth.uid());

-- Ce que ADM-06 affiche : la valeur effective a cote du defaut de plateforme,
-- pour que l'ecart se voie sans calcul mental. L'historique des surcharges
-- closes se lit dans la table, cette vue ne porte que ce qui s'applique.
create view public.regles_profil_v
with (security_barrier = true)
as
select
  p.id as profile_id,
  c.key,
  (c.value #>> '{}')::int as valeur_plateforme,
  (r.value #>> '{}')::int as valeur_surchargee,
  coalesce((r.value #>> '{}')::int, (c.value #>> '{}')::int) as valeur_effective,
  r.id as override_id,
  r.reason as motif,
  r.created_at as pose_le
from public.profiles p
join public.app_config c on (
  (p.role = 'teacher' and c.key = 'max_students_per_teacher')
  or (p.role = 'student' and c.key in (
    'session_duration_minutes', 'session_paid_minimum_minutes',
    'break_minutes_between_sessions'))
)
left join public.rule_overrides r
  on r.profile_id = p.id and r.key = c.key and r.ended_at is null
where p.deleted_at is null
  and public.partie_concernee(p.id);

-- ============================================================
-- 4. Disponibilites hebdomadaires, communes aux deux roles (defaut 3.1)
-- ============================================================

-- availability_slots.teacher_id est not null : TUT-04 n'avait rien ou ecrire, et
-- le matching inverse, qui suppose que les creneaux eleves existent, n'avait
-- rien a afficher.
--
-- Une seule table pour les deux roles, parce que TUT-04 et ENS-06 affichent la
-- meme grille (ADR-017). Deux tables jumelles divergeraient a la premiere
-- evolution. Un motif hebdomadaire, pas des instants : une recurrence porte un
-- fuseau IANA et non une heure absolue, sinon tout se decale au changement
-- d'heure (audit O3).
create table public.weekly_availability (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  hour_local smallint not null check (hour_local between 0 and 23),
  timezone_iana text not null default 'Europe/Paris',
  created_at timestamptz not null default now(),
  constraint weekly_availability_unique unique (profile_id, weekday, hour_local)
);

comment on table public.weekly_availability is
  'Le motif hebdomadaire de disponibilite, commun a l''eleve (pose par son '
  'tuteur, TUT-04) et a l''enseignant (ENS-06). availability_slots, en instants '
  'absolus, reste pour les exceptions datees d''une version ulterieure.';

alter table public.weekly_availability enable row level security;

-- Un foyer porte son fuseau depuis l'etape 1 ; un enseignant n'a pas de foyer et
-- n'en portait aucun. Il lui en faut un : c'est ce qui decide de l'heure locale
-- qu'il pose dans la grille, et le produit fait travailler Conakry avec Paris.
alter table public.teacher_profiles
  add column timezone_iana text not null default 'Europe/Paris';

-- Le fuseau dans lequel l'appelant pose et lit ses creneaux. Une seule reponse,
-- quel que soit le role : l'ecran n'a pas a savoir ou la valeur est rangee, et
-- ne doit surtout pas se rabattre sur le fuseau de l'appareil, qui suit le
-- voyageur alors que le cours, lui, ne bouge pas.
create function public.mon_fuseau()
returns text
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select h.timezone from public.households h
      where h.id = public.app_household_id() and h.deleted_at is null),
    (select tp.timezone_iana from public.teacher_profiles tp
      where tp.profile_id = auth.uid() and tp.deleted_at is null),
    'Europe/Paris'
  );
$$;

revoke execute on function public.mon_fuseau() from public, anon;
grant execute on function public.mon_fuseau() to authenticated, service_role;

-- Qui pose les creneaux d'un profil : l'enseignant les siens, le tuteur ceux des
-- eleves de son foyer, l'eleve adulte autonome les siens (ADR-009).
create function public.peut_poser_disponibilite(p_profile_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    (p_profile_id = auth.uid() and public.app_role() = 'teacher')
    or (
      public.app_role() = 'guardian'
      and exists (
        select 1 from public.profiles p
        where p.id = p_profile_id and p.role = 'student'
          and p.household_id is not null
          and p.household_id = public.app_household_id()
          and p.deleted_at is null
      )
    )
    or (
      p_profile_id = auth.uid()
      and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid()
          and sp.student_type = 'autonomous'
          and sp.deleted_at is null
      )
    );
$$;

revoke execute on function public.peut_poser_disponibilite(uuid) from public, anon;
grant execute on function public.peut_poser_disponibilite(uuid)
  to authenticated, service_role;

create policy weekly_availability_admin_all on public.weekly_availability
  for all to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

create policy weekly_availability_parties_read on public.weekly_availability
  for select to authenticated using (public.partie_concernee(profile_id));

create policy weekly_availability_write on public.weekly_availability
  for insert to authenticated
  with check (public.app_account_valid() and public.peut_poser_disponibilite(profile_id));

create policy weekly_availability_delete on public.weekly_availability
  for delete to authenticated
  using (public.app_account_valid() and public.peut_poser_disponibilite(profile_id));

revoke all on public.weekly_availability from anon;
-- Une case se pose ou se retire ; elle ne se deplace pas.
revoke update on public.weekly_availability from public, anon, authenticated;

-- Defaut 3.5 : availability_slots_reader accordait le select a tout controleur,
-- enseignant ou tuteur, SANS filtre de ligne. Un tuteur lisait le planning de
-- disponibilite de chaque enseignant de la plateforme, et chaque enseignant
-- celui de ses collegues. L'exposition inter-utilisateurs passe par des vues
-- (etape 1, section 5), pas par une policy ouverte.
drop policy availability_slots_reader on public.availability_slots;

create policy availability_slots_reader on public.availability_slots
  for select to authenticated using (
    public.app_account_valid() and deleted_at is null
    and (public.app_role() = 'controller' or public.partie_concernee(teacher_id))
  );

-- L'instant reel d'un creneau hebdomadaire. Deux personnes de fuseaux
-- differents ne peuvent pas comparer des heures locales : la famille pose en
-- heure de Paris, l'enseignant lit en heure de Conakry, et seule la base connait
-- l'UTC. Tout croisement de creneaux passe donc par cette fonction, jamais par
-- une egalite de `hour_local`.
--
-- **La semaine de reference s'ancre en UTC, jamais dans le fuseau de la ligne.**
-- Premiere ecriture : `date_trunc('week', now() at time zone p_tz)`. Chaque
-- fuseau y datait donc sa propre semaine, et les deux minuits du lundi ne
-- tombent pas au meme instant : entre lundi 00h00 a Paris et lundi 00h00 a
-- Conakry, Paris est en semaine N et Conakry encore en semaine N-1. Pendant ces
-- deux heures, chaque semaine, les deux instants d'un meme rendez-vous
-- differaient d'exactement sept jours, et le feed de ENS-06 se vidait de toute
-- famille d'un autre fuseau. Sans erreur, sans trace, et deux heures plus tard
-- tout revenait. Mesure du 6 septembre 2026 a 22h23 UTC, sur les fixtures :
-- « lundi 17h Paris » rendait 2026-09-07 15:00+00 et « lundi 15h Conakry »
-- 2026-08-31 15:00+00.
--
-- L'ancre UTC donne aux deux appels le meme lundi, donc la meme reponse a
-- l'heure ou ils se comparent. C'est la regle de L5 sur `PrayerTimes.utc`,
-- appliquee au calendrier : **un calcul partage entre plusieurs fuseaux se fait
-- sur une reference commune, et se convertit a l'affichage seulement.**
create function public.instant_creneau(
  p_weekday int,
  p_hour int,
  p_tz text,
  p_semaine_offset int default 0
) returns timestamptz
language sql stable set search_path = ''
as $$
  select ((date_trunc('week', (now() at time zone 'UTC'))::date
           + (p_weekday - 1) + (p_semaine_offset * 7))::timestamp
          + make_interval(hours => p_hour)) at time zone p_tz;
$$;

revoke execute on function public.instant_creneau(int, int, text, int) from public, anon;
grant execute on function public.instant_creneau(int, int, text, int)
  to authenticated, service_role;

-- ============================================================
-- 5. Le tuteur regle enfin le profil de son enfant (defaut 3.3)
-- ============================================================

-- student_profiles porte les trois reglages de TUT-05, et sa seule policy
-- famille etait en `for select`. L'ADR-009 dit que la camera est un attribut de
-- profil que le tuteur regle a distance : en l'etat, seul un administrateur
-- pouvait le faire.
create policy student_profiles_family_update on public.student_profiles
  for update to authenticated
  using (
    public.app_account_valid()
    and deleted_at is null
    and exists (
      select 1 from public.profiles p
      where p.id = student_profiles.profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = student_profiles.profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
  );

-- I6. **Une RLS borne les LIGNES, pas les COLONNES** : sans ce grant par
-- colonnes, la policy ci-dessus laisserait un tuteur changer le niveau, la
-- riwaya ou le type d'eleve de son enfant, qui sont des donnees pedagogiques et
-- non des reglages de foyer.
revoke update on public.student_profiles from authenticated;
grant update (interface_mode, camera_policy, avatar_storage_key)
  on public.student_profiles to authenticated;
grant update on public.student_profiles to service_role;

-- Ce que le grant ci-dessus retire a l'administration lui revient par une porte
-- nommee : un administrateur reste le seul a pouvoir corriger le niveau ou la
-- riwaya d'un eleve, et cela se journalise.
create function public.maj_eleve_pedagogie(
  p_profile_id uuid,
  p_level text default null,
  p_riwaya text default null
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur modifie le niveau ou la riwaya';
  end if;

  update public.student_profiles
  set level = coalesce(p_level, level),
      riwaya = coalesce(p_riwaya, riwaya)
  where profile_id = p_profile_id and deleted_at is null;

  perform public.log_sensitive_access('maj_pedagogie', 'student_profiles',
    p_profile_id::text,
    jsonb_build_object('level', p_level, 'riwaya', p_riwaya));
end;
$$;

revoke execute on function public.maj_eleve_pedagogie(uuid, text, text) from public, anon;
grant execute on function public.maj_eleve_pedagogie(uuid, text, text) to authenticated;

-- La fiche produit de TUT-01 demande, en MVP-0 et a la place d'un portefeuille,
-- « la date de fin d'acces de chaque enfant ». Elle vit dans profiles, que le
-- tuteur lit deja par profiles_family_select, mais profils_du_foyer_v ne la
-- portait pas : l'ecran aurait du lire une seconde source pour une colonne de la
-- meme ligne, et les deux auraient fini par diverger.
--
-- Elle est ajoutee ICI plutot qu'a la vue de 0004 pour la meme raison que le
-- reste de cette migration : 0004 est deja ecrite, et une vue se recree ou elle
-- gagne une colonne. Ce qui entre dans cette vue entre aussi dans le cache local
-- de l'appareil de l'enfant, ce qui est acceptable pour une date d'echeance du
-- foyer : c'est une information que ce foyer possede deja, pas celle d'un tiers.
create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  p.first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key,
  p.access_until
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null;

-- ============================================================
-- 6. Deux seances d'un meme enseignant (defaut 3.4)
-- ============================================================

-- guard_session_overlap protege session_participants, donc un profil deja
-- inscrit a une seance. L'enseignant, lui, est porte par sessions.teacher_id :
-- si sa ligne de participant n'est pas creee, rien ne l'empechait d'avoir deux
-- cours a la meme heure. L'audit initial demandait cette contrainte
-- (`no_teacher_overlap`) : elle n'avait jamais ete ecrite.
--
-- Tant qu'aucun ecran ne creait de seance, le defaut etait theorique. L'etape 4
-- en cree par lots de quatre semaines : il ne l'est plus.
create extension if not exists btree_gist;

alter table public.sessions
  add constraint sessions_no_teacher_overlap
  exclude using gist (
    teacher_id with =,
    tstzrange(started_at, ended_at, '[)') with &&
  ) where (deleted_at is null and status in ('planned', 'preflight', 'in_progress'));

-- Defaut 3.9, trouve en mesurant le scenario 3 et non en relisant le schema :
-- guard_session_overlap compare les seances avec `tstzrange(..., '[]')`, donc
-- **bornes fermees**. Un cours de 10h a 11h et le suivant de 11h a 12h partagent
-- alors l'instant 11h00 et sont refuses comme un chevauchement.
--
-- Mesure : sur cinq creneaux consecutifs, trois prises passaient et deux
-- echouaient, une sur deux, ce qui a l'air d'un plafond et n'en est pas un. Or
-- ENS-02 est ecrit pour « un enseignant qui enchaine 5 cours ».
--
-- Un intervalle de temps se ferme a gauche et s'ouvre a droite : la fin d'une
-- seance est le debut de la suivante, elle ne lui appartient pas. C'est aussi
-- la convention de la contrainte EXCLUDE ci-dessus : les deux garde-fous
-- doivent dire la meme chose, sinon l'un accepte ce que l'autre refuse.
create or replace function public.guard_session_overlap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.session_participants sp
    join public.sessions s1 on s1.id = sp.session_id
    join public.sessions s2 on s2.id = new.session_id
    where sp.profile_id = new.profile_id
      and sp.deleted_at is null
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

-- Le temps d'interruption d'une seance, dont les prieres (ADR-017 section 2.3).
-- Pose ici, rempli par la salle a l'etape 5 : la consignation exigee par
-- l'operateur a donc sa colonne avant d'avoir son ecran, et non l'inverse.
alter table public.sessions add column prayer_pause_minutes int not null default 0
  check (prayer_pause_minutes >= 0);

comment on column public.sessions.prayer_pause_minutes is
  'Minutes d''interruption consignees pour cette seance. Le minimum payable de '
  'l''eleve (regle_effective, session_paid_minimum_minutes) s''apprecie sur le '
  'temps restant : une priere ne fait jamais tomber une seance sous le seuil.';

-- ============================================================
-- 7. Ce que chaque role voit d'une seance (defauts 3.6 et 3.8)
-- ============================================================

-- Defaut 3.8 : teacher_roster_v exposait `last_name`. L'ADR-008 et le registre
-- des decisions disent « prenom et identifiant seulement » pour cette vue : le
-- nom de famille d'un eleve n'a aucune raison d'arriver chez l'enseignant, c'est
-- exactement le controle anti-pillage qui a remplace le filigrane.
drop view public.teacher_roster_v;

create view public.teacher_roster_v
with (security_barrier = true)
as
select distinct
  s.id as session_id,
  p.id as student_id,
  p.first_name,
  p.immutable_id,
  sp.level,
  sp.riwaya
from public.sessions s
join public.session_participants spart on spart.session_id = s.id
join public.profiles p on p.id = spart.profile_id
join public.student_profiles sp on sp.profile_id = p.id
where s.teacher_id = auth.uid()
  and s.deleted_at is null
  and spart.deleted_at is null
  and p.deleted_at is null;

-- Defaut 3.6 : family_sessions_v ne portait pas l'enseignant, et
-- profiles_family_select borne la lecture au foyer, ou aucun enseignant ne se
-- trouve. Le tuteur voyait donc que son enfant etait en cours, sans pouvoir dire
-- avec qui.
--
-- Une seule vue remplace family_sessions_v et sert les trois roles : TUT-01,
-- ELV-02 et ENS-02 lisent la meme ligne. Deux vues jumelles finiraient par
-- afficher deux etats differents de la meme seance.
drop view public.family_sessions_v;

create view public.mes_seances_v
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
  eleve.first_name as student_first_name,
  eleve.immutable_id as student_immutable_id,
  ens.id as teacher_id,
  ens.first_name as teacher_first_name,
  ens.immutable_id as teacher_immutable_id
from public.sessions s
join public.session_participants spe
  on spe.session_id = s.id and spe.role = 'student' and spe.deleted_at is null
join public.profiles eleve on eleve.id = spe.profile_id and eleve.deleted_at is null
join public.profiles ens on ens.id = s.teacher_id and ens.deleted_at is null
where s.deleted_at is null
  and (
    s.teacher_id = auth.uid()
    or spe.profile_id = auth.uid()
    or (
      eleve.household_id is not null
      and eleve.household_id = public.app_household_id()
    )
    or public.app_role() in ('admin', 'controller')
  );

comment on view public.mes_seances_v is
  'Les seances de l''appelant, quel que soit son role. Prenom et identifiant '
  'immuable des deux cotes, jamais de nom de famille ni de courriel (ADR-008).';

-- Qui suit qui, y compris quand aucune seance n'existe encore : c'est ce qui
-- permet a TUT-01 d'afficher « en recherche d'un enseignant » plutot qu'un vide.
create view public.mes_affectations_v
with (security_barrier = true)
as
select
  a.id,
  a.teacher_id,
  ens.first_name as teacher_first_name,
  ens.immutable_id as teacher_immutable_id,
  a.student_id,
  eleve.first_name as student_first_name,
  eleve.immutable_id as student_immutable_id,
  a.weekday,
  a.hour_local,
  a.timezone_iana,
  a.created_at,
  a.ended_at
from public.teacher_student_assignments a
join public.profiles ens on ens.id = a.teacher_id and ens.deleted_at is null
join public.profiles eleve on eleve.id = a.student_id and eleve.deleted_at is null
where a.teacher_id = auth.uid()
   or public.partie_concernee(a.student_id);

revoke all on public.mes_seances_v, public.mes_affectations_v,
  public.regles_profil_v from anon;
grant select on public.mes_seances_v, public.mes_affectations_v,
  public.regles_profil_v to authenticated;
revoke all on public.teacher_roster_v from anon;
grant select on public.teacher_roster_v to authenticated;

-- ============================================================
-- 8. Reglages de priere (ADR-017 section 2.3)
-- ============================================================

-- Le calcul lui-meme est fait par le client, avec le paquet `adhan`. Ce qui est
-- en base, ce sont ses ENTREES : lieu, methode, ecole, ajustements a la minute.
-- C'est ce qui rend la transparence possible. Si l'enseignant calculait chez lui
-- et annoncait le resultat, il n'y aurait pas de transparence, seulement une
-- parole contre une autre : ici, l'eleve et son tuteur recalculent la meme
-- minute a partir des memes reglages (I8).
create table public.prayer_settings (
  teacher_id uuid primary key references public.profiles(id) on delete cascade,
  latitude numeric(8, 5) not null check (latitude between -90 and 90),
  longitude numeric(8, 5) not null check (longitude between -180 and 180),
  method text not null default 'muslim_world_league' check (method in (
    'muslim_world_league', 'egyptian', 'karachi', 'umm_al_qura', 'dubai',
    'moon_sighting_committee', 'north_america', 'kuwait', 'qatar',
    'singapore', 'tehran', 'turkey'
  )),
  madhab text not null default 'shafi' check (madhab in ('shafi', 'hanafi')),
  -- L'ajustement a la minute pres exige par l'operateur : une heure calculee ne
  -- correspond pas toujours a celle de la mosquee de reference.
  adjustments jsonb not null default
    '{"fajr": 0, "dhuhr": 0, "asr": 0, "maghrib": 0, "isha": 0}'::jsonb,
  timezone_iana text not null default 'Europe/Paris',
  pause_minutes smallint not null default 15 check (pause_minutes between 0 and 60),
  -- Le preavis de l'alerte exigee par l'operateur. Il vit ICI et non dans le
  -- code client : si chaque role portait le sien, l'enseignant serait prevenu
  -- dix minutes avant et l'eleve cinq, ce qui rouvre exactement le litige que
  -- l'ADR-017 ferme. Une pause et son annonce voyagent ensemble.
  alert_lead_minutes smallint not null default 10
    check (alert_lead_minutes between 0 and 60),
  place_label text,
  updated_at timestamptz not null default now()
);

comment on table public.prayer_settings is
  'Entrees du calcul des horaires de priere d''un enseignant. Lisibles par ses '
  'eleves et leurs tuteurs : tout le monde calcule la meme minute (ADR-017).';

alter table public.prayer_settings enable row level security;

-- Les cinq prieres, et rien d'autre. Un ajustement se compte en minutes, borne
-- a une demi-heure : au-dela, ce n'est plus un ajustement, c'est une autre
-- methode de calcul.
create function public.guard_prayer_adjustments()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_cle text;
  v_valeur jsonb;
begin
  if jsonb_typeof(new.adjustments) <> 'object' then
    raise exception 'les ajustements sont un objet';
  end if;

  foreach v_cle in array array['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] loop
    v_valeur := new.adjustments -> v_cle;
    if v_valeur is null or jsonb_typeof(v_valeur) <> 'number' then
      raise exception 'ajustement manquant ou non numerique : %', v_cle;
    end if;
    if (v_valeur #>> '{}')::numeric < -30 or (v_valeur #>> '{}')::numeric > 30 then
      raise exception 'ajustement hors bornes pour % : au-dela de 30 minutes, changez de methode', v_cle;
    end if;
  end loop;

  if (select count(*) from jsonb_object_keys(new.adjustments)) <> 5 then
    raise exception 'les ajustements ne portent que les cinq prieres';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger prayer_settings_adjustments
before insert or update on public.prayer_settings
for each row execute function public.guard_prayer_adjustments();

create policy prayer_settings_admin_all on public.prayer_settings
  for all to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

-- I7 : l'enseignant est le seul a poser ses reglages, ses eleves et leurs
-- tuteurs les lisent.
create policy prayer_settings_self_write on public.prayer_settings
  for all to authenticated
  using (teacher_id = auth.uid() and public.app_account_valid())
  with check (teacher_id = auth.uid() and public.app_role() = 'teacher');

create policy prayer_settings_parties_read on public.prayer_settings
  for select to authenticated using (public.partie_concernee(teacher_id));

revoke all on public.prayer_settings from anon;

-- ============================================================
-- 9. Demandes des quatre parties, et leur decision
-- ============================================================

-- Une affectation ne se rompt pas toute seule, une regle ne se change pas dans
-- son coin, un plafond ne s'augmente pas soi-meme. Les trois passent par ici, et
-- l'administration tranche.
create table public.matching_requests (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('reassignment', 'capacity', 'rule_change')),
  -- L'eleve concerne, ou l'enseignant quand il s'agit de son plafond.
  subject_profile_id uuid not null references public.profiles(id) on delete cascade,
  rule_key text,
  rule_value jsonb,
  reason text not null,
  requested_by uuid not null references public.profiles(id),
  requester_role public.app_role not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  decision_reason text,
  created_at timestamptz not null default now()
);

-- Une seule demande ouverte par sujet et par sorte : la deuxieme ne dirait rien
-- de plus et doublerait la file de ADM-06.
create unique index matching_requests_pending_uidx
  on public.matching_requests (subject_profile_id, kind) where status = 'pending';

create index matching_requests_pending_age_idx
  on public.matching_requests (created_at) where status = 'pending';

alter table public.matching_requests enable row level security;

create policy matching_requests_privileged_read on public.matching_requests
  for select to authenticated
  using (public.app_role() in ('admin', 'controller'));

create policy matching_requests_parties_read on public.matching_requests
  for select to authenticated
  using (requested_by = auth.uid() or public.partie_concernee(subject_profile_id));

-- Comme les affectations : seules les fonctions ecrivent.
revoke all on public.matching_requests from anon;
revoke insert, update, delete on public.matching_requests
  from public, anon, authenticated;

-- ============================================================
-- 10. Les fonctions de l'etape : prendre, demander, decider, compter
-- ============================================================

-- Materialise les seances d'une affectation sur l'horizon glissant. Appelee a la
-- prise, puis par une tache qui prolonge : c'est ce qui permet a TUT-01 et
-- ELV-02 d'afficher un prochain cours au-dela de la semaine.
create function public.materialiser_seances(p_assignment_id uuid)
returns int
language plpgsql security definer set search_path = ''
as $$
declare
  v_a public.teacher_student_assignments;
  v_semaines int;
  v_duree int;
  v_type text;
  v_debut timestamptz;
  v_session uuid;
  v_creees int := 0;
  i int;
begin
  select * into v_a from public.teacher_student_assignments
  where id = p_assignment_id and ended_at is null;
  if v_a.id is null then
    raise exception 'affectation introuvable ou close';
  end if;

  v_semaines := coalesce(
    (public.get_config('matching_horizon_weeks', '4'::jsonb) #>> '{}')::int, 4);
  v_duree := public.regle_brute(v_a.student_id, 'session_duration_minutes');

  select case when sp.interface_mode = 'child' then 'child' else 'standard' end
    into v_type
  from public.student_profiles sp where sp.profile_id = v_a.student_id;

  for i in 0 .. (v_semaines - 1) loop
    v_debut := public.instant_creneau(v_a.weekday, v_a.hour_local, v_a.timezone_iana, i);
    if v_debut <= now() then
      continue;
    end if;

    -- Une seance deja posee sur ce creneau ne se double pas : la tache de
    -- prolongation repasse sur les memes semaines a chaque execution.
    if exists (
      select 1 from public.sessions s
      where s.teacher_id = v_a.teacher_id and s.started_at = v_debut
        and s.deleted_at is null
    ) then
      continue;
    end if;

    insert into public.sessions (teacher_id, started_at, ended_at, session_type)
    values (v_a.teacher_id, v_debut,
            v_debut + make_interval(mins => v_duree),
            coalesce(v_type, 'standard'))
    returning id into v_session;

    insert into public.session_participants (session_id, profile_id, role)
    values (v_session, v_a.teacher_id, 'teacher'),
           (v_session, v_a.student_id, 'student');

    v_creees := v_creees + 1;
  end loop;

  return v_creees;
end;
$$;

revoke execute on function public.materialiser_seances(uuid) from public, anon;
grant execute on function public.materialiser_seances(uuid) to service_role;

-- Ce que prend ENS-06 : un eleve, pas un creneau (ADR-017).
create function public.prendre_eleve(
  p_student_profile_id uuid,
  p_weekday int,
  p_hour int
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_tz text;
  v_instant timestamptz;
  v_assignment uuid;
begin
  if public.app_role() <> 'teacher' or not public.app_account_valid() then
    raise exception 'seul un enseignant au compte valide prend un eleve';
  end if;

  -- Le creneau demande doit etre un creneau POSE par le foyer : un enseignant ne
  -- choisit pas l'heure a la place de la famille.
  select w.timezone_iana into v_tz
  from public.weekly_availability w
  join public.profiles p on p.id = w.profile_id
  where w.profile_id = p_student_profile_id
    and w.weekday = p_weekday and w.hour_local = p_hour
    and p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_tz is null then
    raise exception 'ce creneau n''est pas propose par ce foyer';
  end if;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  -- Comparaison par instant et non par heure locale : la famille pose en heure
  -- de Paris, l'enseignant travaille en heure de Conakry.
  if not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = auth.uid()
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  ) then
    raise exception 'ce creneau ne figure pas dans vos disponibilites';
  end if;

  if exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = p_student_profile_id and a.ended_at is null
  ) then
    raise exception 'cet eleve a deja un enseignant';
  end if;

  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values (auth.uid(), p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    -- I4 : deux enseignants au meme instant. L'index unique partiel tranche, et
    -- le perdant recoit une phrase, pas un code d'erreur.
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un autre enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_creee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour));

  return v_assignment;
end;
$$;

revoke execute on function public.prendre_eleve(uuid, int, int) from public, anon;
grant execute on function public.prendre_eleve(uuid, int, int) to authenticated;

-- Une demande, faite par l'une des quatre parties.
create function public.demander(
  p_kind text,
  p_subject_profile_id uuid,
  p_motif text,
  p_rule_key text default null,
  p_rule_value int default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_role public.app_role := public.app_role();
  v_id uuid;
begin
  if v_role is null or not public.app_account_valid() then
    raise exception 'compte non valide';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une demande sans motif ne se tranche pas';
  end if;
  if not public.partie_concernee(p_subject_profile_id) then
    raise exception 'vous n''etes pas partie a ce dossier';
  end if;

  if p_kind = 'capacity' then
    -- Le plafond est celui d'un enseignant, et il le demande pour lui-meme.
    if not (v_role = 'admin' or (v_role = 'teacher' and p_subject_profile_id = auth.uid())) then
      raise exception 'un plafond se demande pour soi';
    end if;
    if p_rule_value is null or p_rule_value <= 0 then
      raise exception 'un plafond demande est un entier positif';
    end if;
    p_rule_key := 'max_students_per_teacher';

  elsif p_kind = 'rule_change' then
    if p_rule_key not in ('session_duration_minutes',
                          'session_paid_minimum_minutes',
                          'break_minutes_between_sessions') then
      raise exception 'regle non modifiable par demande : %', coalesce(p_rule_key, 'aucune');
    end if;
    if p_rule_value is null or p_rule_value <= 0 then
      raise exception 'une regle demandee est un entier positif';
    end if;

  elsif p_kind = 'reassignment' then
    p_rule_key := null;
    p_rule_value := null;
    if not exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p_subject_profile_id and a.ended_at is null
    ) then
      raise exception 'cet eleve n''a pas d''enseignant a changer';
    end if;

  else
    raise exception 'sorte de demande inconnue : %', p_kind;
  end if;

  begin
    insert into public.matching_requests
      (kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
    values (p_kind, p_subject_profile_id, p_rule_key,
            case when p_rule_value is null then null else to_jsonb(p_rule_value) end,
            btrim(p_motif), auth.uid(), v_role)
    returning id into v_id;
  exception
    when unique_violation then
      raise exception 'une demande de cette sorte est deja en attente pour ce dossier';
  end;

  perform public.log_sensitive_access('demande_creee', 'matching_requests',
    v_id::text, jsonb_build_object('kind', p_kind, 'subject', p_subject_profile_id));

  return v_id;
end;
$$;

revoke execute on function public.demander(text, uuid, text, text, int) from public, anon;
grant execute on function public.demander(text, uuid, text, text, int) to authenticated;

-- Pose une regle sur un profil. Chemin unique : la decision d'une demande passe
-- aussi par ici, pour qu'une regle posee a la volee et une regle accordee sur
-- demande soient exactement la meme chose en base.
create function public.poser_regle(
  p_profile_id uuid,
  p_key text,
  p_value int,
  p_motif text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur pose une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une regle sans motif ne se relit pas six mois plus tard';
  end if;

  -- La precedente se clot, elle ne se remplace pas.
  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(),
      end_reason = 'remplacee : ' || btrim(p_motif)
  where profile_id = p_profile_id and key = p_key and ended_at is null;

  insert into public.rule_overrides (profile_id, key, value, reason, set_by)
  values (p_profile_id, p_key, to_jsonb(p_value), btrim(p_motif), auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access('regle_posee', 'rule_overrides', v_id::text,
    jsonb_build_object('profile_id', p_profile_id, 'key', p_key, 'value', p_value));

  return v_id;
end;
$$;

revoke execute on function public.poser_regle(uuid, text, int, text) from public, anon;
grant execute on function public.poser_regle(uuid, text, int, text) to authenticated;

create function public.clore_regle(p_override_id uuid, p_motif text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur clot une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une cloture sans motif ne se relit pas';
  end if;

  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(), end_reason = btrim(p_motif)
  where id = p_override_id and ended_at is null;

  if not found then
    raise exception 'regle introuvable ou deja close';
  end if;

  perform public.log_sensitive_access('regle_close', 'rule_overrides',
    p_override_id::text, jsonb_build_object('motif', btrim(p_motif)));
end;
$$;

revoke execute on function public.clore_regle(uuid, text) from public, anon;
grant execute on function public.clore_regle(uuid, text) to authenticated;

-- Le verdict de ADM-06. Comme decider_dossier() a l'etape 3 : un refus exige un
-- motif, et l'effet metier est applique ici, pas par l'ecran.
create function public.decider_demande(
  p_request_id uuid,
  p_accepte boolean,
  p_motif text default null
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_d public.matching_requests;
  v_assignment uuid;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur tranche une demande';
  end if;
  if not p_accepte and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  select * into v_d from public.matching_requests
  where id = p_request_id and status = 'pending';
  if v_d.id is null then
    raise exception 'demande introuvable ou deja tranchee';
  end if;

  if p_accepte then
    if v_d.kind = 'reassignment' then
      -- L'affectation se clot, et les seances a venir tombent avec elle : une
      -- famille ne doit pas voir un cours planifie avec un enseignant qui ne la
      -- suit plus.
      update public.teacher_student_assignments
      set ended_at = now(), ended_by = auth.uid(),
          end_reason = coalesce(btrim(p_motif), btrim(v_d.reason))
      where student_id = v_d.subject_profile_id and ended_at is null
      returning id into v_assignment;

      update public.sessions s
      set status = 'canceled', updated_at = now()
      where s.deleted_at is null
        and s.status = 'planned'
        and s.started_at > now()
        and exists (
          select 1 from public.session_participants sp
          where sp.session_id = s.id and sp.profile_id = v_d.subject_profile_id
            and sp.deleted_at is null
        );
    else
      perform public.poser_regle(
        v_d.subject_profile_id, v_d.rule_key, (v_d.rule_value #>> '{}')::int,
        'demande accordee : ' || v_d.reason);
    end if;
  end if;

  update public.matching_requests
  set status = case when p_accepte then 'approved' else 'rejected' end,
      decided_by = auth.uid(), decided_at = now(),
      decision_reason = btrim(p_motif)
  where id = p_request_id;

  perform public.log_sensitive_access('demande_tranchee', 'matching_requests',
    p_request_id::text,
    jsonb_build_object('accepte', p_accepte, 'kind', v_d.kind));
end;
$$;

revoke execute on function public.decider_demande(uuid, boolean, text) from public, anon;
grant execute on function public.decider_demande(uuid, boolean, text) to authenticated;

-- Les six compteurs de ADM-01, en une seule lecture. Le zero est une valeur
-- comme une autre : un compteur qui disparait a zero fait douter s'il a ete
-- charge ou s'il est reellement nul.
create function public.indicateurs_admin()
returns table (
  dossiers_en_attente int,
  foyers_sans_enseignant int,
  rapports_manquants int,
  incidents_24h int,
  comptes_echus int,
  demandes_en_attente int
)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    (select count(*)::int from public.kyc_documents k
      where k.status = 'pending' and k.deleted_at is null),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$$;

revoke execute on function public.indicateurs_admin() from public, anon;
grant execute on function public.indicateurs_admin() to authenticated;

-- La file de ADM-06, anciennete d'abord, comme celle des dossiers.
create function public.demandes_en_attente()
returns table (
  id uuid,
  kind text,
  subject_profile_id uuid,
  subject_first_name text,
  subject_immutable_id text,
  rule_key text,
  rule_value jsonb,
  reason text,
  requester_role public.app_role,
  requested_by uuid,
  created_at timestamptz
)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'file des demandes reservee a l''administration';
  end if;

  return query
  select m.id, m.kind, m.subject_profile_id, p.first_name, p.immutable_id,
         m.rule_key, m.rule_value, m.reason, m.requester_role, m.requested_by,
         m.created_at
  from public.matching_requests m
  join public.profiles p on p.id = m.subject_profile_id
  where m.status = 'pending'
  order by m.created_at asc;
end;
$$;

revoke execute on function public.demandes_en_attente() from public, anon;
grant execute on function public.demandes_en_attente() to authenticated;

-- Le feed de ENS-06 : les eleves sans enseignant dont un creneau croise ceux de
-- l'enseignant qui regarde. **Tri par anciennete d'attente**, jamais par nom :
-- sans ce tri, un eleve peut rester invisible en bas de liste indefiniment, ce
-- qui viderait le matching inverse de son interet.
create view public.eleves_en_attente_v
with (security_barrier = true)
as
select
  e.id as student_id,
  e.first_name,
  e.immutable_id,
  sp.level,
  sp.interface_mode,
  we.weekday,
  we.hour_local,
  we.timezone_iana,
  attente.depuis
from public.profiles e
join public.student_profiles sp on sp.profile_id = e.id and sp.deleted_at is null
join public.weekly_availability we on we.profile_id = e.id
join public.weekly_availability wt on wt.profile_id = auth.uid()
  and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
    = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
join lateral (
  select min(w2.created_at) as depuis
  from public.weekly_availability w2 where w2.profile_id = e.id
) attente on true
where e.role = 'student'
  and e.deleted_at is null
  and e.account_status in ('active', 'provisional_active')
  and public.app_role() = 'teacher'
  and not exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = e.id and a.ended_at is null
  );

comment on view public.eleves_en_attente_v is
  'Feed de ENS-06. Les creneaux se croisent par INSTANT et non par heure locale : '
  'la famille pose en heure de Paris, l''enseignant lit en heure de Conakry.';

revoke all on public.eleves_en_attente_v from anon;
grant select on public.eleves_en_attente_v to authenticated;

commit;
