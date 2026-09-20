-- 0030_tc_socle.sql
-- Teaching Core -- socle : extension, configuration, deux fonctions, colonnes sur
-- tables existantes et deux seaux Storage. Aucune table neuve (palier 4 : voir 0032).
--
-- Regles rappelees en tete de chacune des quatre migrations Teaching Core (0030-0033),
-- demandees a l'unisson par les huit lots producteurs :
--   1. Jamais de `grant execute` a `agent_ro` sur une fonction volatile ou d'ecriture.
--      `agent_ro` lit ce que la personne observee lit ; il n'ecrit jamais.
--   2. La RLS borne les LIGNES, jamais les COLONNES : toute vue qui expose une donnee
--      sensible le fait colonne par colonne (`case when ... then null`), jamais en
--      comptant sur une policy de table pour le faire a sa place.
--
-- Note de correction (mesuree le 20/09/2026, list_migrations + to_regclass) : l'en-tete
-- de 0025_role_enseignant.sql affirme que 0020-0024 n'ont jamais ete appliquees a cette
-- base. C'est faux aujourd'hui : les quatre le sont, `programme_niveaux` existe. Ne pas
-- relire cette affirmation comme un blocker pour ce lot.

-- ============================================================================
-- PALIER 0 -- extension (demandeur : C, recherche coranique)
-- ============================================================================

-- Disponible mais non installee (installed_version nul, mesure). Reprend la forme de
-- 0001:19 -- un `create extension` sans schema n'installe rien d'utilisable ici.
create extension if not exists pg_trgm with schema extensions;

-- ============================================================================
-- PALIER 1 -- app_config (7 cles) et deux fonctions (demandeurs : A, G, H)
-- ============================================================================

-- Un seul insert pour les sept cles : A et G les ont demandees separement mais elles
-- partagent le meme magasin cle/valeur (0007:150 app_config_int, deja employe trois
-- fois dans etat_presence).
insert into public.app_config (key, value) values
  ('join_window_minutes',                '20'),
  ('grace_after_end_minutes',             '15'),
  ('observation.activee',                 'true'),
  ('observation.max_visits_per_session',  '1'),
  ('observation.max_total_seconds',       '120'),
  ('observation.max_seconds_per_visit',   'null'),
  ('observation.policy_version',          '"a1"')
on conflict (key) do nothing;

-- Predicat de foyer, UNIQUE dans tout le depot. household_members n'existe pas ;
-- la primitive reelle est profiles.household_id, deja employee cinq fois ailleurs
-- (0001:686, :729, :741, :785, :1030). A ecrivait contre une table inexistante, H
-- contre une fonction inexistante, pour le meme besoin : ce helper ferme les deux.
create or replace function public.est_du_foyer(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = p_profile_id
      and p.household_id = public.app_household_id()
      and p.deleted_at is null
  )
$$;

revoke execute on function public.est_du_foyer(uuid) from anon, public;
grant  execute on function public.est_du_foyer(uuid) to authenticated;

-- Horloge serveur (A §1.5). `stable`, sans effet de bord : seule fonction de ce lot
-- ouverte a agent_ro.
create or replace function public.maintenant_serveur()
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$ select now() $$;

revoke execute on function public.maintenant_serveur() from public, anon;
grant  execute on function public.maintenant_serveur() to authenticated, agent_ro, service_role;

-- ============================================================================
-- PALIER 2 -- colonnes sur tables existantes (13 objets, aucune n'existe -- mesure)
-- ============================================================================

-- A §1.4 -- fenetre d'entree persistee par seance. A poser AVANT
-- materialiser_seances_groupe (0033), dont le corps l'ecrit deja.
alter table public.sessions
  add column if not exists join_opens_at timestamptz;

comment on column public.sessions.join_opens_at is
  'Instant a partir duquel la salle est joignable. Ecrit a la materialisation '
  'depuis app_config.join_window_minutes. Nul pour les seances anterieures : '
  'autoriser_jeton_video() retombe alors sur la valeur de configuration.';

-- A §1.6 -- identite visuelle du groupe : un INDEX dans la palette administree,
-- jamais un hexadecimal. tool/verifier_jetons.dart refuse toute couleur nue ailleurs
-- que lib/core/theme/app_palette.dart.
alter table public.groupes
  add column if not exists couleur_jeton smallint
    check (couleur_jeton is null or couleur_jeton between 0 and 39);

comment on column public.groupes.couleur_jeton is
  'Index dans la palette administree (decision D-18). JAMAIS un hexadecimal : '
  'une couleur transportee echappe au contraste, au mode sombre et au theme. '
  'Nul = aucune couleur choisie, l''interface retombe sur l''index 0.';

-- A §1.7 -- le cours et le niveau, en langage humain. programme_niveaux existe deja
-- (0020, appliquee) : FK directe, sans garde to_regclass.
alter table public.groupes
  add column if not exists nom_cours text,
  add column if not exists programme_niveau_id uuid
    references public.programme_niveaux(id);

comment on column public.groupes.nom_cours is
  'Nom HUMAIN du cours, affiche tel quel. Jamais un code academique interne.';

-- G §1.2 -- surcharge de la politique d'observation par groupe. Une surcharge
-- "groupe" est complete ou n'existe pas (contrainte plus bas).
alter table public.groupes
  add column if not exists observation_source text not null default 'academie'
      check (observation_source in ('academie', 'groupe', 'desactivee')),
  add column if not exists observation_max_visites smallint,
  add column if not exists observation_max_secondes integer,
  add column if not exists observation_max_secondes_par_visite integer,
  add column if not exists observation_revision integer not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'groupes_observation_complete'
  ) then
    alter table public.groupes add constraint groupes_observation_complete
      check (observation_source <> 'groupe'
             or (observation_max_visites is not null and observation_max_secondes is not null));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'groupes_observation_bornes'
  ) then
    alter table public.groupes add constraint groupes_observation_bornes
      check ((observation_max_visites is null or observation_max_visites between 1 and 10)
         and (observation_max_secondes is null or observation_max_secondes between 30 and 1800));
  end if;

  -- Invariant de la spec §11.1 tenu EN BASE, pas par l'ecran : un plafond par visite
  -- ne contourne jamais le plafond total.
  if not exists (
    select 1 from pg_constraint where conname = 'groupes_observation_plafond_visite'
  ) then
    alter table public.groupes add constraint groupes_observation_plafond_visite
      check (observation_max_secondes_par_visite is null
             or observation_max_secondes is null
             or observation_max_secondes_par_visite <= observation_max_secondes);
  end if;
end $$;

-- Deroulement automatique de la revision : rend policy_version honnete. Sans lui,
-- deux politiques differentes porteraient la meme version et le journal mentirait.
create or replace function public.tc_groupes_observation_bump_revision()
returns trigger
language plpgsql
as $$
begin
  if (new.observation_source, new.observation_max_visites, new.observation_max_secondes,
      new.observation_max_secondes_par_visite)
     is distinct from
     (old.observation_source, old.observation_max_visites, old.observation_max_secondes,
      old.observation_max_secondes_par_visite)
  then
    new.observation_revision := old.observation_revision + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists tc_groupes_observation_revision on public.groupes;
create trigger tc_groupes_observation_revision
  before update on public.groupes
  for each row execute function public.tc_groupes_observation_bump_revision();

-- A §1.8 -- photo et titre de l'enseignant (D-01 photo obligatoire distincte du KYC,
-- D-02 titres Sayyid/Sayyida jamais Ustaz).
alter table public.teacher_profiles
  add column if not exists photo_storage_key text,
  add column if not exists titre text
    check (titre is null or titre in ('sayyid', 'sayyida'));

comment on column public.teacher_profiles.photo_storage_key is
  'Cle Storage de la photo professionnelle PUBLIQUE de l''enseignant, dans le seau '
  'photos_enseignants. On persiste la CLE, jamais une URL signee : une URL signee '
  'expire (lecon de lib/core/appairage/service_avatar.dart:148). Distincte des pieces '
  'KYC, qui vivent dans le seau kyc et n''en sortent pas.';

-- C §5 -- recherche dans le Coran. Colonne GENEREE : elle ne modifie JAMAIS `texte`,
-- la licence Tanzil interdit toute modification du texte source.
alter table public.verset
  add column if not exists texte_recherche text generated always as (
    regexp_replace(texte, '[ً-ْٰۖ-ۭ]', '', 'g')
  ) stored;

create index if not exists verset_recherche_idx
  on public.verset using gin (texte_recherche extensions.gin_trgm_ops);

-- ============================================================================
-- Hors palier numerote -- deux seaux Storage (§4.9). Bruts ici ; les policies de
-- lecture/ecriture rejoignent 0032, apres l'existence de library_resource.access_policy
-- pour `supports` et de groupe_membres (deja existante) pour `photos_enseignants`.
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('photos_enseignants', 'photos_enseignants', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('supports', 'supports', false)
on conflict (id) do nothing;

-- ============================================================================
-- Controle de sortie
-- ============================================================================
do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_trgm') then
    raise exception 'pg_trgm non installee apres 0030';
  end if;
  if (select count(*) from public.app_config
      where key in ('join_window_minutes', 'grace_after_end_minutes',
                     'observation.activee', 'observation.max_visits_per_session',
                     'observation.max_total_seconds', 'observation.max_seconds_per_visit',
                     'observation.policy_version')) <> 7 then
    raise exception 'app_config incomplete apres 0030';
  end if;
  if to_regprocedure('public.est_du_foyer(uuid)') is null then
    raise exception 'est_du_foyer manquante apres 0030';
  end if;
  if to_regprocedure('public.maintenant_serveur()') is null then
    raise exception 'maintenant_serveur manquante apres 0030';
  end if;
end $$;
