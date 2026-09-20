-- 0032_tc_catalogue.sql
-- Teaching Core -- palier 4 : les tables neuves, dans l'ordre des cles etrangeres.
-- Chaine d'Agent B d'abord (reordonnee pour casser le cycle library_resource <->
-- resource_version), puis D, F, G, H. La table `mot` (C §1.4 option a) n'est PAS
-- creee : l'arbitrage produit n°4 retient l'option degradee (verset.ligne seul).
--
-- Regles rappelees (voir 0030) : jamais de `grant execute` a `agent_ro` sur une
-- fonction volatile ou d'ecriture ; la RLS borne les LIGNES, jamais les COLONNES.

-- ============================================================================
-- 1. Les sept types, avant toute table qui les emploie.
-- ============================================================================
create type public.library_resource_type as enum
  ('quran', 'structured_text', 'pdf', 'image', 'lesson');
create type public.library_access_policy as enum
  ('publique', 'inscrits', 'groupe_assigne', 'enseignant_seul', 'admin');
create type public.library_offline_policy as enum
  ('jamais', 'sur_demande', 'automatique');
create type public.statut_version_ressource as enum
  ('brouillon', 'publiee', 'archivee');
create type public.format_artefact as enum ('pdf', 'epub', 'audio', 'image');
create type public.origine_artefact as enum ('genere_a_la_publication', 'importe_tel_quel');
create type public.type_ancrage_contenu as enum ('page', 'ayah', 'section', 'fraction');

-- ============================================================================
-- 2. library_resource -- SANS current_version_id, pour casser le cycle avec
--    resource_version (B §1.1). La colonne est ajoutee en etape 5.
-- ============================================================================
create table public.library_resource (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  short_title    text not null,
  cover_asset    text,
  resource_type  public.library_resource_type not null,
  edition        text,
  language       text not null default 'fr',
  category       text not null default '',
  level_scope    text[] not null default '{}',
  access_policy  public.library_access_policy not null,
  offline_policy public.library_offline_policy not null,
  capabilities   text[] not null default '{}',
  created_at     timestamptz not null default now(),
  archived_at    timestamptz
);

alter table public.library_resource enable row level security;

-- La policy de lecture de library_resource est ajoutee APRES la creation de
-- library_resource_groupe (etape 6), qu'elle referme dans sa clause USING :
-- CREATE POLICY exige que les tables citees existent deja.

-- ============================================================================
-- 3. resource_version -- la version immuable (B §1.2). Calque sur
--    programme_versions (0020) : publication irreversible en base.
-- ============================================================================
create table public.resource_version (
  id                uuid primary key default gen_random_uuid(),
  resource_id       uuid not null references public.library_resource(id) on delete cascade,
  numero_version    int  not null,
  statut            public.statut_version_ressource not null default 'brouillon',
  publiee_le        timestamptz,
  publiee_par       uuid references public.profiles(id),
  download_asset_id uuid,
  empreinte         text,
  unique (resource_id, numero_version)
);

alter table public.resource_version enable row level security;

-- Lecture : admin, ou version publiee d'une ressource lisible par l'appelant
-- (retombe sur la policy de library_resource, executee comme l'appelant).
create policy resource_version_lecture on public.resource_version
  for select to authenticated using (
    public.app_role() = 'admin'
    or (
      statut = 'publiee'
      and exists (select 1 from public.library_resource r where r.id = resource_version.resource_id)
    )
  );

-- ============================================================================
-- 4. download_asset -- l'artefact derive (B §1.3).
-- ============================================================================
create table public.download_asset (
  id                  uuid primary key default gen_random_uuid(),
  resource_version_id uuid not null references public.resource_version(id) on delete cascade,
  format              public.format_artefact not null,
  cle_stockage        text not null,
  taille_octets       bigint not null,
  empreinte           text,
  origine             public.origine_artefact not null,
  cree_le             timestamptz not null default now(),
  unique (resource_version_id, format)
);

alter table public.download_asset enable row level security;

create policy download_asset_lecture on public.download_asset
  for select to authenticated using (
    public.app_role() = 'admin'
    or exists (
      select 1 from public.resource_version v
      where v.id = download_asset.resource_version_id and v.statut = 'publiee'
    )
  );

alter table public.resource_version
  add constraint resource_version_download_asset_fk
    foreign key (download_asset_id) references public.download_asset(id);

-- ============================================================================
-- 5. Referme le cycle : library_resource.current_version_id.
-- ============================================================================
alter table public.library_resource
  add column current_version_id uuid references public.resource_version(id);

-- ============================================================================
-- 6. library_resource_groupe -- "Pour ce groupe" (B §1.4).
-- ============================================================================
create table public.library_resource_groupe (
  resource_id uuid not null references public.library_resource(id) on delete cascade,
  groupe_id   uuid not null references public.groupes(id) on delete cascade,
  epinglee    boolean not null default false,
  ajoutee_le  timestamptz not null default now(),
  ajoutee_par uuid references public.profiles(id),
  primary key (resource_id, groupe_id)
);

alter table public.library_resource_groupe enable row level security;

create policy library_resource_groupe_lecture on public.library_resource_groupe
  for select to authenticated using (
    public.app_role() = 'admin'
    or exists (
      select 1 from public.groupes g
      where g.id = library_resource_groupe.groupe_id
        and (
          g.teacher_id = auth.uid()
          or exists (
            select 1 from public.groupe_membres m
            where m.groupe_id = g.id
              and m.left_at is null
              and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
          )
        )
    )
  );

-- Policy differee de l'etape 2 (library_resource) : elle cite
-- library_resource_groupe, qui doit deja exister.
create policy library_resource_lecture on public.library_resource
  for select to authenticated using (
    public.app_account_valid() and (
      public.app_role() = 'admin'
      or access_policy in ('publique', 'inscrits')
      or (
        access_policy in ('groupe_assigne', 'enseignant_seul')
        and exists (
          select 1
          from public.library_resource_groupe lrg
          join public.groupes g on g.id = lrg.groupe_id
          where lrg.resource_id = library_resource.id
            and (
              g.teacher_id = auth.uid()
              or (
                access_policy = 'groupe_assigne'
                and exists (
                  select 1 from public.groupe_membres m
                  where m.groupe_id = g.id
                    and m.left_at is null
                    and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
                )
              )
            )
        )
      )
    )
  );

-- ============================================================================
-- 7. library_reading_position -- "Continuer" (B §1.5). Distincte de
--    student_reading_position (invariant J2, 0007) : multi-ressources.
-- ============================================================================
create table public.library_reading_position (
  profile_id          uuid not null references public.profiles(id) on delete cascade,
  resource_id         uuid not null references public.library_resource(id) on delete cascade,
  resource_version_id uuid references public.resource_version(id),
  type_ancrage        public.type_ancrage_contenu not null,
  page                int,
  sourate             int,
  ayah                int,
  section_id          text,
  fraction            double precision,
  vue_le              timestamptz not null default now(),
  primary key (profile_id, resource_id),
  constraint un_seul_ancrage check (
    case type_ancrage
      when 'page' then
        page is not null and sourate is null and ayah is null
        and section_id is null and fraction is null
      when 'ayah' then
        sourate is not null and ayah is not null and page is null
        and section_id is null and fraction is null
      when 'section' then
        section_id is not null and page is null and sourate is null
        and ayah is null and fraction is null
      when 'fraction' then
        fraction is not null and page is null and sourate is null
        and ayah is null and section_id is null
      else false
    end
  )
);

alter table public.library_reading_position enable row level security;

create policy library_reading_position_self on public.library_reading_position
  for all to authenticated using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy library_reading_position_admin on public.library_reading_position
  for select to authenticated using (public.app_role() = 'admin');

-- ============================================================================
-- 8. annotation_layer (D §3.1). Table existante etendue : aucune -- verifie
--    dans TEACHING_CORE_EXISTING_MAPPING.md §10.5.
-- ============================================================================
create table public.annotation_layer (
  id                   uuid primary key default gen_random_uuid(),
  resource_id          uuid not null references public.library_resource(id) on delete cascade,
  resource_version_id  uuid references public.resource_version(id),
  session_id           uuid references public.sessions(id),
  auteur_profile_id    uuid not null references public.profiles(id),
  portee               text not null check (portee in ('temporaire', 'seance', 'enregistree')),
  maj_le               timestamptz not null default now(),
  constraint annotation_layer_seance_requiert_session
    check (portee <> 'seance' or session_id is not null)
);

-- Index unique PARTIEL : une seule couche personnelle (session_id nul) par
-- (resource, auteur, portee), et une seule couche par seance quand elle est liee
-- a une seance. Un index plein laisserait passer plusieurs lignes a session_id
-- nul, puisque NULL <> NULL en unicite.
create unique index annotation_layer_unique_personnelle
  on public.annotation_layer (resource_id, auteur_profile_id, portee)
  where session_id is null;
create unique index annotation_layer_unique_seance
  on public.annotation_layer (resource_id, session_id, auteur_profile_id, portee)
  where session_id is not null;

comment on constraint annotation_layer_seance_requiert_session on public.annotation_layer is
  'La portee temporaire ne s''ecrit jamais en base (decision D, vit et meurt cote client).';

alter table public.annotation_layer enable row level security;

create policy annotation_layer_auteur on public.annotation_layer
  for all to authenticated using (auteur_profile_id = auth.uid())
  with check (auteur_profile_id = auth.uid());

create policy annotation_layer_participants_seance on public.annotation_layer
  for select to authenticated using (
    portee = 'seance'
    and session_id is not null
    and exists (
      select 1 from public.session_participants sp
      where sp.session_id = annotation_layer.session_id
        and sp.profile_id = auth.uid()
        and sp.deleted_at is null
    )
  );

create policy annotation_layer_admin on public.annotation_layer
  for select to authenticated using (public.app_role() = 'admin');

-- ============================================================================
-- 9. annotation_trait et 10. annotation_marqueur (D §3.2). Deux tables filles :
--    une gomme retire un trait precis, une jsonb unique imposerait de reecrire
--    toute la couche a chaque geste, en concurrence avec les autres participants.
-- ============================================================================
create table public.annotation_trait (
  id           uuid primary key default gen_random_uuid(),
  layer_id     uuid not null references public.annotation_layer(id) on delete cascade,
  ancrage      jsonb not null,
  points       jsonb not null,
  outil        text check (outil in ('stylet', 'surligneur', 'gomme')),
  intention    text check (intention is null or intention in
                 ('learn', 'review', 'reinforce', 'maintain', 'assessment')),
  pression     real,
  inclinaison  real,
  cree_le      timestamptz not null default now()
);

comment on table public.annotation_trait is
  'Une annotation ne modifie JAMAIS resource_version. Aucune de ces trois tables '
  '(annotation_layer, annotation_trait, annotation_marqueur) ne porte de contenu '
  'de support, et aucun update sur une version publiee n''est declenche depuis ici.';

alter table public.annotation_trait enable row level security;

create policy annotation_trait_lecture on public.annotation_trait
  for select to authenticated using (
    exists (select 1 from public.annotation_layer l where l.id = annotation_trait.layer_id)
  );

create policy annotation_trait_ecriture on public.annotation_trait
  for all to authenticated using (
    exists (
      select 1 from public.annotation_layer l
      where l.id = annotation_trait.layer_id and l.auteur_profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.annotation_layer l
      where l.id = annotation_trait.layer_id and l.auteur_profile_id = auth.uid()
    )
  );

create table public.annotation_marqueur (
  id        uuid primary key default gen_random_uuid(),
  layer_id  uuid not null references public.annotation_layer(id) on delete cascade,
  plage     jsonb not null,
  intention text not null check (intention in
              ('learn', 'review', 'reinforce', 'maintain', 'assessment')),
  note      text
);

alter table public.annotation_marqueur enable row level security;

create policy annotation_marqueur_lecture on public.annotation_marqueur
  for select to authenticated using (
    exists (select 1 from public.annotation_layer l where l.id = annotation_marqueur.layer_id)
  );

create policy annotation_marqueur_ecriture on public.annotation_marqueur
  for all to authenticated using (
    exists (
      select 1 from public.annotation_layer l
      where l.id = annotation_marqueur.layer_id and l.auteur_profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.annotation_layer l
      where l.id = annotation_marqueur.layer_id and l.auteur_profile_id = auth.uid()
    )
  );

-- ============================================================================
-- 11. learning_assignment (D §3.3). Index CORRIGE par l'amendement H §2.1 :
--     (group_id, student_id, status, due_at), jamais (group_id, status, due_at)
--     sinon le filtre par eleve fait un scan.
-- ============================================================================
create table public.learning_assignment (
  id                   uuid primary key default gen_random_uuid(),
  group_id             uuid not null references public.groupes(id) on delete cascade,
  student_id           uuid references public.profiles(id) on delete cascade,
  resource_id          uuid not null references public.library_resource(id) on delete cascade,
  resource_version_id  uuid references public.resource_version(id),
  content_range        jsonb,
  purpose              text not null check (purpose in
                          ('learn', 'review', 'reinforce', 'maintain', 'assessment')),
  instructions         text,
  starts_at            timestamptz not null,
  due_at               timestamptz,
  created_by           uuid not null references public.profiles(id),
  status               text not null check (status in
                          ('a_faire', 'en_cours', 'fait', 'expire', 'annule')),
  constraint learning_assignment_echeance check (due_at is null or due_at >= starts_at)
);

create index learning_assignment_a_venir_idx
  on public.learning_assignment (group_id, student_id, status, due_at);

alter table public.learning_assignment enable row level security;

create policy learning_assignment_enseignant on public.learning_assignment
  for all to authenticated using (
    exists (select 1 from public.groupes g where g.id = learning_assignment.group_id and g.teacher_id = auth.uid())
  )
  with check (
    exists (select 1 from public.groupes g where g.id = learning_assignment.group_id and g.teacher_id = auth.uid())
  );

create policy learning_assignment_membres on public.learning_assignment
  for select to authenticated using (
    (student_id is null or student_id = auth.uid() or public.est_du_foyer(student_id))
    and exists (
      select 1 from public.groupe_membres m
      where m.groupe_id = learning_assignment.group_id
        and m.left_at is null
        and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
    )
  );

create policy learning_assignment_admin on public.learning_assignment
  for select to authenticated using (public.app_role() = 'admin');

-- ============================================================================
-- 12. session_shared_content (F §3.2). Table telle que publiee par F, mot pour
--     mot, plus la FK vers library_resource (arbitrage §4.7 : on delete restrict
--     -- on ne supprime pas une ressource presentee pendant une seance archivee).
-- ============================================================================
create table public.session_shared_content (
  session_id            uuid primary key references public.sessions(id) on delete cascade,
  resource_id           uuid not null references public.library_resource(id) on delete restrict,
  resource_version_id   uuid,
  content_position      jsonb not null,
  content_range         jsonb,
  display_mode          text not null check (display_mode in ('page', 'verse', 'focus')),
  hidden_ranges         jsonb not null default '[]'::jsonb,
  semantic_markers      jsonb not null default '[]'::jsonb,
  group_resume_position jsonb,
  revision              integer not null check (revision >= 0),
  updated_by            uuid not null references public.profiles(id),
  updated_at            timestamptz not null default now()
);

comment on table public.session_shared_content is
  'Une seule ligne par seance : l''etat COURANT, pas un journal. La monotonie de '
  '`revision` est tenue par publier_etat_partage() (0033), jamais par le client.';

alter table public.session_shared_content enable row level security;

-- Lecture : tout participant inscrit a la seance, y compris l'observateur masque
-- (lecture du late joiner).
create policy ssc_participant_read on public.session_shared_content
  for select to authenticated using (
    public.app_account_valid()
    and exists (
      select 1 from public.session_participants sp
      where sp.session_id = session_shared_content.session_id
        and sp.profile_id = auth.uid()
        and sp.deleted_at is null
    )
  );

create policy ssc_admin_read on public.session_shared_content
  for select to authenticated using (public.app_role() = 'admin');

-- Aucune policy d'ecriture directe : l'ecriture passe par publier_etat_partage()
-- (0033), seul endroit ou la monotonie est tenue.

-- ============================================================================
-- 13. guardian_session_visit (G §1.3). L'intervalle mesurable -- pas un second
--     journal d'audit : audit_logs reste le journal, ceci rend visites/secondes
--     REQUETABLES.
-- ============================================================================
create table public.guardian_session_visit (
  id                      uuid primary key default gen_random_uuid(),
  session_id              uuid not null references public.sessions(id) on delete cascade,
  groupe_id               uuid not null references public.groupes(id),
  observateur_profile_id  uuid not null references public.profiles(id),
  role                    public.participant_role not null,
  enfant_profile_id       uuid references public.profiles(id),
  entered_at              timestamptz not null default now(),
  left_at                 timestamptz,
  duration_seconds        integer generated always as (
                            case when left_at is null then null
                                 else greatest(0, extract(epoch from (left_at - entered_at))::int)
                            end) stored,
  visit_number            smallint not null,
  policy_version          text not null,
  fin_de_visite           text check (fin_de_visite is null or fin_de_visite in
                            ('sortie_volontaire', 'quota_atteint', 'seance_terminee',
                             'revocation_serveur', 'deconnexion')),
  constraint guardian_visit_ordre check (left_at is null or left_at >= entered_at),
  constraint guardian_visit_rang  check (visit_number >= 1),
  unique (session_id, observateur_profile_id, visit_number)
);

create index guardian_visit_session_idx
  on public.guardian_session_visit (session_id, observateur_profile_id, entered_at);

-- Un seul intervalle ouvert par (seance, observateur) : sans cet index, deux
-- onglets ouvriraient deux intervalles et le quota compterait deux fois le meme
-- temps.
create unique index guardian_visit_ouvert_uidx
  on public.guardian_session_visit (session_id, observateur_profile_id)
  where left_at is null;

comment on column public.guardian_session_visit.duration_seconds is
  'Calculee EN BASE, jamais envoyee par le client : deux horodatages recolles a '
  'l''ecran donneraient une duree que la machine de l''observateur aurait pu choisir.';

alter table public.guardian_session_visit enable row level security;

create policy guardian_visit_self on public.guardian_session_visit
  for select to authenticated using (observateur_profile_id = auth.uid());

create policy guardian_visit_admin on public.guardian_session_visit
  for select to authenticated using (public.app_role() = 'admin');

-- Aucune policy d'ecriture : les visites s'ouvrent et se ferment par RPC
-- (autoriser_jeton_video / entrer_observation, palier 7).

-- ============================================================================
-- 14. session_feedback (H §1.1) + trois cles app_config non comptees au palier 1
--     (couplees a cette table, hors du lot des sept clesA/G). Empreinte NON
--     REVERSIBLE : decision produit tranchee par l'operateur le 20/09.
-- ============================================================================
insert into public.app_config (key, value) values
  ('feedback_cadence_seances', '4'),
  ('feedback_seuil_tendance',  '5'),
  ('feedback_empreinte_sel',   to_jsonb(encode(extensions.gen_random_bytes(16), 'hex')))
on conflict (key) do nothing;

create table public.session_feedback (
  id               uuid primary key default gen_random_uuid(),
  session_id       uuid not null references public.sessions(id) on delete cascade,
  groupe_id        uuid not null references public.groupes(id) on delete cascade,
  question_id      text not null,
  reponse          text not null check (reponse in ('difficile', 'bien', 'tres_bien')),
  soumis_le        timestamptz not null default now(),
  -- Empreinte NON REVERSIBLE de l'auteur : empeche un second vote, jamais pour
  -- le nommer. Calculee par declencheur ci-dessous, jamais fournie par le client.
  auteur_empreinte bytea not null,
  constraint session_feedback_un_seul_vote unique (session_id, auteur_empreinte)
);

create or replace function public.tc_session_feedback_calculer_empreinte()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sel text;
begin
  select (value #>> '{}') into v_sel
    from public.app_config where key = 'feedback_empreinte_sel';
  new.auteur_empreinte := extensions.digest(
    new.session_id::text || auth.uid()::text || coalesce(v_sel, ''), 'sha256'
  );
  return new;
end;
$$;

drop trigger if exists tc_session_feedback_empreinte on public.session_feedback;
create trigger tc_session_feedback_empreinte
  before insert on public.session_feedback
  for each row execute function public.tc_session_feedback_calculer_empreinte();

alter table public.session_feedback enable row level security;

-- insert : l'eleve ou le tuteur d'un membre, et seulement sur une seance a
-- laquelle il a participe (meme jointure que 0012 pour assister_seance).
create policy session_feedback_insert on public.session_feedback
  for insert to authenticated with check (
    exists (
      select 1 from public.session_participants sp
      where sp.session_id = session_feedback.session_id
        and sp.profile_id = auth.uid()
        and sp.deleted_at is null
    )
  );

-- select : PERSONNE, hors admin. L'enseignant lit tendance_feedback_v (0033),
-- jamais cette table.
create policy session_feedback_admin on public.session_feedback
  for select to authenticated using (public.app_role() = 'admin');

-- ============================================================================
-- 15. student_concern (H §1.4). Forme de matching_requests (0005), jamais la
--     table elle-meme (0022 l'interdit).
-- ============================================================================
create type public.concern_category as enum
  ('pedagogique', 'presence', 'technique', 'changement', 'autre');
create type public.concern_status   as enum ('ouvert', 'en_examen', 'transmis', 'clos');
create type public.concern_target   as enum ('tuteur_du_mineur', 'eleve_adulte');

create table public.student_concern (
  id               uuid primary key default gen_random_uuid(),
  categorie        public.concern_category not null,
  groupe_id        uuid not null references public.groupes(id) on delete cascade,
  session_id       uuid references public.sessions(id) on delete set null,
  student_id       uuid not null references public.profiles(id) on delete cascade,
  teacher_id       uuid not null references public.profiles(id) on delete cascade,
  internal_details text not null check (length(btrim(internal_details)) > 0),
  family_summary   text,
  statut           public.concern_status not null default 'ouvert',
  cree_le          timestamptz not null default now(),
  transmis_le      timestamptz,
  transmis_a       public.concern_target,
  constraint student_concern_transmission_coherente
    check (transmis_le is null or family_summary is not null)
);

comment on column public.student_concern.internal_details is
  'internal_details et family_summary sont DEUX colonnes, et la contrainte le dit. '
  'Un champ unique avec un drapeau de visibilite finirait par fuir.';

alter table public.student_concern enable row level security;

-- insert : l'enseignant DU GROUPE ET de la seance -- ne pas reproduire le
-- defaut de lesson_reports_teacher_write (0001:1064-1069), qui ne verifie que
-- author_profile_id sans verifier que la seance appartient a l'enseignant.
create policy student_concern_insert on public.student_concern
  for insert to authenticated with check (
    teacher_id = auth.uid()
    and exists (
      select 1 from public.groupes g
      where g.id = student_concern.groupe_id and g.teacher_id = auth.uid()
    )
    and (
      session_id is null
      or public.session_belongs_to_teacher(session_id, auth.uid())
    )
  );

create policy student_concern_select_enseignant on public.student_concern
  for select to authenticated using (teacher_id = auth.uid());

create policy student_concern_select_admin on public.student_concern
  for select to authenticated using (public.app_role() = 'admin');

create policy student_concern_update_admin on public.student_concern
  for update to authenticated using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

-- Aucune policy famille : la famille lit concern_famille_v (0033), qui ne
-- delivre jamais internal_details, teacher_id, session_id ni groupe_id.

-- ============================================================================
-- Deux seaux Storage (0030) : policies, maintenant que library_resource et
-- access_policy existent (calquees sur le motif de la policy `avatars`, 0004).
-- ============================================================================

-- photos_enseignants : l'enseignant ecrit dans son propre dossier (premier
-- segment du chemin = son profile_id). Lecture ouverte aux membres de ses
-- groupes (eleve ou tuteur), a lui-meme et a l'administration.
create policy photos_enseignants_ecriture on storage.objects
  for all to authenticated using (
    bucket_id = 'photos_enseignants'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'photos_enseignants'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy photos_enseignants_lecture on storage.objects
  for select to authenticated using (
    bucket_id = 'photos_enseignants'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.app_role() = 'admin'
      or exists (
        select 1 from public.groupes g
        join public.groupe_membres m on m.groupe_id = g.id
        where g.teacher_id::text = (storage.foldername(name))[1]
          and m.left_at is null
          and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
      )
    )
  );

-- supports : ecriture reservee a l'administration (publication de catalogue) ;
-- lecture calquee sur access_policy via library_resource (premier segment du
-- chemin = resource_id).
create policy supports_ecriture_admin on storage.objects
  for all to authenticated using (bucket_id = 'supports' and public.app_role() = 'admin')
  with check (bucket_id = 'supports' and public.app_role() = 'admin');

create policy supports_lecture on storage.objects
  for select to authenticated using (
    bucket_id = 'supports'
    and exists (
      select 1 from public.library_resource r
      where r.id::text = (storage.foldername(name))[1]
    )
  );

-- ============================================================================
-- Controle de sortie
-- ============================================================================
do $$
declare
  v_manquante text;
begin
  foreach v_manquante in array array[
    'library_resource', 'resource_version', 'download_asset',
    'library_resource_groupe', 'library_reading_position',
    'annotation_layer', 'annotation_trait', 'annotation_marqueur',
    'learning_assignment', 'session_shared_content', 'guardian_session_visit',
    'session_feedback', 'student_concern'
  ]
  loop
    if to_regclass('public.' || v_manquante) is null then
      raise exception 'table % manquante apres 0032', v_manquante;
    end if;
  end loop;
end $$;
