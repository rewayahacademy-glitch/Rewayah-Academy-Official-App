-- 0007 : lot N1 de l'etape 5 — le Coran comme contenu structure, la position
-- de lecture personnelle, et la presence derivee par participant.
--
-- Perimetre fixe par docs/archive/2026-09-pre-remise-a-plat/architecture/etape-5-salle-coran-presence.md
-- section 12 (« N1 | Migration : mushaf/sourate/page_mushaf/verset,
-- student_reading_position, vue ou fonction de presence derivee ») et par
-- l'ADR-020. Ce fichier ne code aucun ecran : il pose ce dont N2 a N5 ont
-- besoin, et rien de plus.
--
-- Trois invariants de l'etape 5 sont portes ici, pas dans le Dart :
--
--   1. Le Coran n'est jamais un PDF (Bible section 23). Le texte est un
--      contenu structure, adressable au verset : aucune colonne ne porte
--      d'identifiant de fichier, et la couche Flutter n'en verra jamais.
--   2. L'etat partage de seance n'ecrase jamais l'etat personnel de l'eleve
--      (Bible section 24.3). `student_reading_position` n'appartient qu'a
--      l'eleve : aucune policy n'autorise un enseignant a y ecrire.
--   3. La presence est une machine a etats **derivee**, pas un journal de
--      plus (section 6.1). Elle se calcule au-dessus de `session_events` et
--      `sessions` ; seule la correction humaine est stockee.

begin;

-- ============================================================
-- 1. Le Coran comme contenu structure (section 4.1)
-- ============================================================

-- Une edition physique de reference. Une seule ligne en MVP-0 : le Complexe
-- du Roi Fahd, riwaya Hafs, trace Uthmani (ADR-020, section 3.1). L'edition et
-- le trace sont portes par cette table, pas par une colonne separee, tant
-- qu'une deuxieme edition n'existe pas.
create table public.mushaf (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  nom text not null,
  riwaya text not null default 'hafs',
  editeur text,
  nombre_pages int not null check (nombre_pages > 0),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint mushaf_code_unique unique (code)
);

create table public.sourate (
  numero int primary key check (numero between 1 and 114),
  nom_arabe text not null,
  nom_translittere text not null,
  lieu_revelation text not null check (lieu_revelation in ('mecque', 'medine')),
  nombre_versets int not null check (nombre_versets > 0)
);

create table public.juz (
  numero int primary key check (numero between 1 and 30),
  sourate_depart int not null references public.sourate(numero),
  verset_depart int not null check (verset_depart > 0)
);

create table public.page_mushaf (
  mushaf_id uuid not null references public.mushaf(id) on delete cascade,
  numero int not null check (numero > 0),
  juz_numero int references public.juz(numero),
  primary key (mushaf_id, numero)
);

-- La granularite retenue en MVP-0 est le verset, pas le mot (section 4.1) :
-- la table `mot` n'est ecrite que si le focus mot-a-mot est construit, ce qui
-- releve de N6, pas de ce lot. `ligne` porte la metadonnee de mise en page qui
-- permet un rendu fidele a l'edition reelle plutot qu'un reflow libre.
create table public.verset (
  id bigint generated always as identity primary key,
  mushaf_id uuid not null references public.mushaf(id) on delete cascade,
  sourate_numero int not null references public.sourate(numero),
  numero int not null check (numero > 0),
  texte text not null,
  page_numero int not null check (page_numero > 0),
  ligne int check (ligne > 0),
  constraint verset_unique unique (mushaf_id, sourate_numero, numero),
  constraint verset_page_fk
    foreign key (mushaf_id, page_numero)
    references public.page_mushaf(mushaf_id, numero) on delete cascade
);

create index verset_page_idx on public.verset (mushaf_id, page_numero, ligne);

-- ============================================================
-- 2. La position de lecture personnelle (section 4.3)
-- ============================================================

-- Une ligne par eleve et par edition : la position la plus recente ecrase la
-- precedente, `updated_at` sert a afficher « Reprendre : sourate ..., verset
-- ... » sur ELV-02 et ELV-04 (Bible section 28), jamais cachee dans un reglage.
--
-- Cette table est le pendant personnel de l'etat partage de seance. Elle ne
-- porte aucune reference a une seance : un eleve lit hors de tout cours, et
-- une page tournee par l'enseignant pour toute la classe ne doit jamais
-- l'ecrire (section 24.3). C'est pourquoi les policies d'ecriture ci-dessous
-- ne nomment que l'eleve lui-meme.
create table public.student_reading_position (
  student_profile_id uuid not null
    references public.student_profiles(profile_id) on delete cascade,
  mushaf_id uuid not null references public.mushaf(id) on delete cascade,
  page_mushaf int not null check (page_mushaf > 0),
  sourate int not null references public.sourate(numero),
  verset int not null check (verset > 0),
  zoom_level real not null default 1.0 check (zoom_level between 0.5 and 4.0),
  updated_at timestamptz not null default now(),
  primary key (student_profile_id, mushaf_id)
);

-- ============================================================
-- 3. La presence par participant (section 6)
-- ============================================================

-- Les quatorze etats de la Bible section 29.1, traduits, aucun ajoute ni
-- retire — l'interdiction est explicite. L'ordre est celui du tableau de la
-- specification.
create type public.presence_state as enum (
  'planifiee',
  'en_attente',
  'en_connexion',
  'presente',
  'en_retard',
  'deconnectee',
  'en_reconnexion',
  'reconnectee',
  'sortie',
  'absente',
  'excusee',
  'confirmation_en_attente',
  'corrigee_manuel',
  'finalisee'
);

-- Le vocabulaire de `session_events.source`, laisse ouvert par l'etape 1 et
-- fixe ici (section 6.3). C'est cette colonne, et elle seule, qui empeche
-- `sortie` (geste volontaire) de se confondre avec `deconnectee` (perte
-- reseau) : les deux produisent le meme evenement `left`.
alter table public.session_events
  add constraint session_events_source_vocabulaire
  check (source in ('livekit_webhook', 'user_action', 'network', 'server'));

-- Les deux seuils que la specification refusait d'inventer (section 6.3) :
-- ils se mesurent contre le vrai comportement des webhooks, donc ils sont
-- reglables sans redeploiement.
insert into public.app_config (key, value) values
  ('presence.seuil_retard_secondes', '300'::jsonb),
  ('presence.fenetre_reconnexion_secondes', '120'::jsonb)
on conflict (key) do nothing;

create or replace function public.app_config_int(p_key text, p_defaut int)
returns int
language sql stable security definer set search_path = ''
as $$
  select coalesce((select c.value #>> '{}' from public.app_config c
                   where c.key = p_key)::int, p_defaut);
$$;

-- La correction humaine, et elle seule, est stockee. Tout le reste se derive.
-- `excusee`, `corrigee_manuel` et `finalisee` ne sont pas calculables : ce
-- sont des decisions, journalisees comme telles (meme esprit qu'ADR-011).
create table public.session_presence_override (
  session_id uuid not null references public.sessions(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  etat public.presence_state not null
    check (etat in ('excusee', 'corrigee_manuel', 'finalisee')),
  motif text,
  decide_par uuid not null references public.profiles(id),
  decide_le timestamptz not null default now(),
  primary key (session_id, profile_id)
);

-- La derivation. Elle suit la colonne « Se deduit de » du tableau de la
-- section 6.2, dans l'ordre ou la Bible la donne.
--
-- Un etat des quatorze n'est volontairement pas produit ici : `en_connexion`
-- (« token emis, connexion LiveKit en cours, avant le premier joined »). Rien
-- en base ne trace l'emission d'un token aujourd'hui — c'est N2 qui l'emet.
-- L'inventer reviendrait a deviner ; la fonction le laisse a N2, qui posera la
-- trace en meme temps que l'emission.
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
  v_seuil_retard   int := public.app_config_int('presence.seuil_retard_secondes', 300);
  v_fenetre_reco   int := public.app_config_int('presence.fenetre_reconnexion_secondes', 120);
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return null;
  end if;

  -- Une decision humaine prime sur tout calcul, toujours.
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

  -- Jamais vu entrer.
  if v_premier_joined is null then
    if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
      return 'absente';
    end if;
    -- La fenetre de token s'ouvre a T-10 min (ADR-005) : avant, la seance
    -- n'est qu'inscrite au planning ; apres, on attend quelqu'un.
    if now() < v_seance.started_at - interval '10 minutes' then
      return 'planifiee';
    end if;
    return 'en_attente';
  end if;

  -- Sorti : le vocabulaire de `source` tranche entre geste et panne.
  if v_dernier_type = 'left' then
    if v_dernier_source = 'user_action' then
      return 'sortie';
    end if;
    if now() - v_dernier_ts <= make_interval(secs => v_fenetre_reco) then
      return 'en_reconnexion';
    end if;
    return 'deconnectee';
  end if;

  -- Present. Reste a savoir s'il revient d'une coupure, ou s'il est entre
  -- en retard.
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

  -- Une seance finie dont la presence n'a pas encore ete consolidee.
  if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
    return 'confirmation_en_attente';
  end if;

  return 'presente';
end;
$$;

-- La vue que ENS-03, CTR-02 et ADM-01 liront (sections 6.6 et 7). Elle porte
-- l'etat **et son contexte** : la Bible interdit de reduire une presence a une
-- seule couleur (section 29.3), donc l'heure d'entree et la derniere trace
-- voyagent avec l'etat.
create view public.presence_seance_v
with (security_barrier = true)
as
select
  sp.session_id,
  sp.profile_id,
  sp.role,
  public.etat_presence(sp.session_id, sp.profile_id) as etat,
  (select min(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id
      and e.event_type = 'joined')                   as entre_le,
  (select max(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id)              as derniere_trace_le,
  s.started_at,
  s.ended_at,
  s.status                                           as statut_seance
from public.session_participants sp
join public.sessions s on s.id = sp.session_id
where sp.deleted_at is null
  and s.deleted_at is null;

-- ============================================================
-- 4. RLS — activee partout, refus par defaut (invariant du depot)
-- ============================================================

alter table public.mushaf enable row level security;
alter table public.sourate enable row level security;
alter table public.juz enable row level security;
alter table public.page_mushaf enable row level security;
alter table public.verset enable row level security;
alter table public.student_reading_position enable row level security;
alter table public.session_presence_override enable row level security;

-- Le texte coranique est un contenu de reference : tout compte valide le lit,
-- personne ne l'ecrit hors administration.
create policy mushaf_lecture on public.mushaf
  for select to authenticated using (public.app_account_valid());
create policy mushaf_admin on public.mushaf
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

create policy sourate_lecture on public.sourate
  for select to authenticated using (public.app_account_valid());
create policy sourate_admin on public.sourate
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

create policy juz_lecture on public.juz
  for select to authenticated using (public.app_account_valid());
create policy juz_admin on public.juz
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

create policy page_mushaf_lecture on public.page_mushaf
  for select to authenticated using (public.app_account_valid());
create policy page_mushaf_admin on public.page_mushaf
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

create policy verset_lecture on public.verset
  for select to authenticated using (public.app_account_valid());
create policy verset_admin on public.verset
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

-- La position de lecture appartient a l'eleve. Le foyer la lit (un tuteur voit
-- ou en est son enfant), l'administration aussi ; **aucune policy n'ouvre
-- l'ecriture a un enseignant**, c'est l'invariant 2 de l'en-tete.
create policy srp_eleve_tout on public.student_reading_position
  for all to authenticated
  using (student_profile_id = public.app_user_id() and public.app_account_valid())
  with check (student_profile_id = public.app_user_id() and public.app_account_valid());

create policy srp_foyer_lecture on public.student_reading_position
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
       where p.id = student_reading_position.student_profile_id
         and p.household_id = public.app_household_id()
         and p.deleted_at is null
    )
    and public.app_role() in ('guardian', 'admin')
  );

create policy srp_admin on public.student_reading_position
  for all to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

-- Une correction de presence se lit par les participants concernes, ne
-- s'ecrit que par l'enseignant de la seance ou l'administration.
create policy spo_lecture on public.session_presence_override
  for select to authenticated
  using (
    public.app_role() = 'admin'
    or profile_id = public.app_user_id()
    or exists (
      select 1 from public.sessions s
       where s.id = session_presence_override.session_id
         and s.teacher_id = public.app_user_id()
         and s.deleted_at is null
    )
  );

create policy spo_ecriture on public.session_presence_override
  for all to authenticated
  using (
    public.app_role() = 'admin'
    or exists (
      select 1 from public.sessions s
       where s.id = session_presence_override.session_id
         and s.teacher_id = public.app_user_id()
         and s.deleted_at is null
    )
  )
  with check (
    decide_par = public.app_user_id()
    and (
      public.app_role() = 'admin'
      or exists (
        select 1 from public.sessions s
         where s.id = session_presence_override.session_id
           and s.teacher_id = public.app_user_id()
           and s.deleted_at is null
      )
    )
  );

-- ============================================================
-- 5. Droits
-- ============================================================

grant select on public.mushaf, public.sourate, public.juz,
  public.page_mushaf, public.verset to authenticated;
grant select, insert, update, delete on public.student_reading_position to authenticated;
grant select, insert, update, delete on public.session_presence_override to authenticated;
grant select on public.presence_seance_v to authenticated;
grant execute on function public.etat_presence(uuid, uuid) to authenticated;
grant execute on function public.app_config_int(text, int) to authenticated;

-- ============================================================
-- 6. Amorcage du mushaf de reference (ADR-020, section 3.1)
-- ============================================================

-- La ligne d'edition, pas le texte : les 604 pages et les 6236 versets sont un
-- jeu de donnees a importer, pas une migration (section 4.1 laisse l'arbitrage
-- import/API au codage). Poser l'edition des maintenant permet a N5 de
-- referencer un `mushaf_id` stable.
insert into public.mushaf (code, nom, riwaya, editeur, nombre_pages)
values ('madina-hafs-604', 'Mushaf de Medine (Complexe du Roi Fahd)', 'hafs',
        'Complexe du Roi Fahd pour l''impression du Noble Coran', 604)
on conflict (code) do nothing;

commit;
