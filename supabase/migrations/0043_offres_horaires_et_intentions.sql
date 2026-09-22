-- 0043 — Les offres horaires vitrines, le parcours d'onboarding, et l'intention
--        d'horaire qui ne promet aucune classe
--
-- Ce lot pose ce qui manquait pour qu'une famille puisse, seule, se decrire et
-- choisir un horaire sans qu'on lui mente. Cinq constats de l'audit du
-- 22 septembre 2026 le commandent, et chacun a change la conception :
--
--   1. **Une offre vitrine ne peut pas etre une ligne `public.groupes`.**
--      `groupes.teacher_id` est `not null` : un groupe n'existe pas sans
--      enseignant affecte. Or la vitrine doit se montrer AVANT qu'un enseignant
--      soit affecte, et l'interdiction d'afficher un professeur y est absolue.
--      Relacher `teacher_id` aurait traverse toutes les policies et toutes les
--      RPC qui tiennent un groupe pour enseigne (jeton video, observation,
--      `mes_groupes_v`) : le cout est une refonte de securite, le gain est nul.
--      L'offre est donc une table a elle, et elle ne porte aucun enseignant.
--
--   2. **`groupes.weekday` est UN jour.** Une offre annonce trois seances par
--      semaine. Trois lignes `groupes` auraient decoupe un meme roster en trois
--      et fait compter le plafond trois fois. `groupe_creneaux` porte donc les
--      creneaux d'un groupe, et `groupes.weekday`/`hour_local` restent l'ancre
--      que tout le code existant continue de lire, sans une ligne a changer.
--      Un declencheur garantit que l'ancre figure toujours parmi les creneaux :
--      les deux ne peuvent pas diverger.
--
--   3. **`programme_niveaux` est VIDE en production.** Le referentiel
--      academique n'est pas importe. Aucun filtre ne peut donc exiger un niveau
--      officiel : `offres_horaires.programme_niveau_id` est nullable, et une
--      offre sans niveau est compatible avec tout le monde. Le niveau
--      auto-declare de l'onboarding vit dans une colonne SEPAREE de
--      `student_profiles.level`, qui reste le niveau officiel : deux colonnes,
--      donc l'impossibilite structurelle qu'un pre-diagnostic attribue un
--      niveau.
--
--   4. **`app_account_valid()` refuse `pending_kyc`.** C'est le piege deja paye
--      sur `peut_deposer_piece_identite` (lot R2). Il vaut ici de plein fouet :
--      la policy d'ecriture de `weekly_availability` et celle de
--      `student_profiles` exigent toutes deux `app_account_valid()`, et le
--      foyer qui s'onboarde est par construction `pending_kyc`. Sans
--      `compte_en_parcours()`, ce lot aurait refuse en silence toute ecriture a
--      exactement la population qu'il vise. Voir la section 2.
--
--   5. **`student_profiles` n'accorde `update` que sur trois colonnes** a
--      `authenticated` (`avatar_storage_key`, `camera_policy`,
--      `interface_mode`). Les colonnes ajoutees ici n'heritent donc d'aucun
--      droit : elles s'ecrivent par RPC, et `diagnostic_statut` n'est jamais
--      accorde au client. Le pre-diagnostic ne peut pas se declarer acquis.
--
-- Ce que ce lot ne fait PAS : il ne touche ni `app_account_valid()`, ni une
-- policy existante, ni une RPC existante. Il n'ajoute que des objets nouveaux
-- et leurs droits.

-- ============================================================
-- 1. Referentiels : la langue du cours, et la cohorte d'age
-- ============================================================

-- La langue du COURS, qui n'est pas la langue de l'interface.
--
-- ADR-015 a retire le poular de l'application. Cette decision portait sur la
-- langue de l'INTERFACE (francais et arabe), et elle reste entiere : rien ici
-- n'ajoute une locale. Le poular revient comme langue d'ENSEIGNEMENT, un axe
-- distinct : une famille peut lire l'application en francais et suivre son
-- cours en poular. L'ADR-029 consigne cette distinction.
--
-- Une table et non un `enum` : ajouter une langue est une decision
-- d'exploitation, pas une migration. `actif = false` retire une langue de
-- l'onboarding sans casser les lignes qui la referencent.
create table if not exists public.langues_cours (
  code text primary key check (btrim(code) <> ''),
  nom_humain text not null check (btrim(nom_humain) <> ''),
  ordre smallint not null,
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.langues_cours (code, nom_humain, ordre) values
  ('poular',   'Poular',   1),
  ('francais', 'Français', 2),
  ('english',  'English',  3)
on conflict (code) do nothing;

-- La cohorte d'age, et ce qu'elle DEDUIT.
--
-- L'onboarding demande une tranche, jamais une date de naissance. Deux raisons.
-- La premiere est l'ecran : une reponse choisie au doigt bat un clavier de date
-- sur un telephone tenu d'une main. La seconde est la donnee : le produit
-- n'a besoin de rien de plus precis qu'une tranche, et il ne stocke aucune
-- date de naissance aujourd'hui -- en collecter une serait une donnee
-- sensible de plus a proteger pour un usage qui n'existe pas.
--
-- Les trois colonnes de deduction sont ici et non dans le client : c'est le
-- serveur qui decide qui est mineur et qui recoit l'interface guidee. Un
-- client qui en decidait pourrait se declarer adulte autonome.
--
-- `age_max_inclus` nul signifie « et au-dela ».
create table if not exists public.cohortes_age (
  code text primary key check (btrim(code) <> ''),
  nom_humain text not null check (btrim(nom_humain) <> ''),
  age_min smallint not null check (age_min >= 0),
  age_max_inclus smallint check (age_max_inclus is null or age_max_inclus >= age_min),
  type_public text not null check (type_public in ('enfant', 'adulte')),
  student_type public.student_type not null,
  interface_mode public.interface_mode not null,
  ordre smallint not null,
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

-- Les bornes suivent `app_config` : `child_ui_mode_max_age` valait 10 le
-- 22 septembre 2026, et la coupure 8-10 / 11-14 tombe donc exactement dessus.
-- Si l'operateur deplace cette regle, ces lignes se corrigent par `update`,
-- sans migration.
insert into public.cohortes_age
  (code, nom_humain, age_min, age_max_inclus, type_public, student_type, interface_mode, ordre) values
  ('enfant_5_7',     '5 à 7 ans',          5,  7,    'enfant', 'minor',      'child',    1),
  ('enfant_8_10',    '8 à 10 ans',         8,  10,   'enfant', 'minor',      'child',    2),
  ('ado_11_14',      '11 à 14 ans',        11, 14,   'enfant', 'minor',      'standard', 3),
  ('ado_15_17',      '15 à 17 ans',        15, 17,   'enfant', 'minor',      'standard', 4),
  ('adulte_18_plus', '18 ans et plus',     18, null, 'adulte', 'autonomous', 'standard', 5)
on conflict (code) do nothing;

alter table public.langues_cours enable row level security;
alter table public.cohortes_age  enable row level security;

-- Deux referentiels de presentation, lisibles par tout compte connecte : sans
-- eux l'onboarding n'a aucune carte a montrer. Aucune ligne n'est nominative.
create policy langues_cours_lecture on public.langues_cours
  for select to authenticated using (true);
create policy cohortes_age_lecture on public.cohortes_age
  for select to authenticated using (true);

create policy langues_cours_admin on public.langues_cours
  for all to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false))
  with check (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));
create policy cohortes_age_admin on public.cohortes_age
  for all to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false))
  with check (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

grant select on public.langues_cours to authenticated, agent_ro;
grant select on public.cohortes_age  to authenticated, agent_ro;
grant insert, update, delete on public.langues_cours to authenticated;
grant insert, update, delete on public.cohortes_age  to authenticated;

-- `anon` n'a rien a faire ici : la vitrine s'adresse a un compte, pas au
-- public du web. Les deux chemins de retrait sont necessaires, aucun ne
-- suffit seul.
revoke all on public.langues_cours from anon;
revoke all on public.cohortes_age  from anon;
revoke all on public.langues_cours from public;
revoke all on public.cohortes_age  from public;

-- ============================================================
-- 2. La porte du parcours : un compte en attente de KYC peut se decrire,
--    il n'entre dans aucune classe
-- ============================================================

-- Vrai pour un compte valide, et AUSSI pour un compte encore en verification.
--
-- Ecrit en exigence positive : toute valeur nulle retombe sur faux. La forme
-- `if role <> 'x' then raise` s'ouvrirait pour un appelant sans role, parce
-- qu'une comparaison a `null` ne declenche pas le `if`.
--
-- **Ce que cette porte ouvre** : ecrire ses propres preferences
-- d'apprentissage, poser ses disponibilites, choisir une offre horaire,
-- signaler qu'aucun horaire ne convient. Rien d'autre.
--
-- **Ce qu'elle n'ouvre pas** : entrer dans un groupe, obtenir un jeton video,
-- lire une seance, voir un enseignant, lire un autre foyer. Ces portes
-- continuent d'exiger `app_account_valid()`, et `ajouter_eleve_groupe` exige
-- deja que l'eleve soit `active` ou `provisional_active`. Choisir un horaire
-- n'est pas suivre un cours : c'est precisement la distinction que ce lot
-- rend visible a l'ecran.
create or replace function public.compte_en_parcours()
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select coalesce(
    (
      select p.deleted_at is null
         and p.account_status in ('pending_kyc', 'active', 'provisional_active')
         and (p.access_until is null or p.access_until > now())
      from public.profiles p
      where p.id = auth.uid()
    ),
    false
  );
$function$;

revoke execute on function public.compte_en_parcours() from public;
revoke execute on function public.compte_en_parcours() from anon;
grant execute on function public.compte_en_parcours() to authenticated, agent_ro;

-- Vrai quand l'appelant est le foyer de cet eleve, ou cet eleve adulte
-- lui-meme. Meme dessin que `peut_poser_disponibilite`, mais sur la porte du
-- parcours : un foyer en verification doit pouvoir decrire son enfant.
create or replace function public.peut_decrire_apprenant(p_profile_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select coalesce(
    public.compte_en_parcours()
    and (
      (
        public.app_role() = 'guardian'
        and exists (
          select 1 from public.profiles p
          where p.id = p_profile_id
            and p.role = 'student'
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
      )
    ),
    false
  );
$function$;

revoke execute on function public.peut_decrire_apprenant(uuid) from public;
revoke execute on function public.peut_decrire_apprenant(uuid) from anon;
grant execute on function public.peut_decrire_apprenant(uuid) to authenticated, agent_ro;

-- ============================================================
-- 3. Le profil d'apprentissage, a cote du niveau officiel
-- ============================================================

alter table public.student_profiles
  add column if not exists langue_cours text references public.langues_cours(code),
  add column if not exists cohorte text references public.cohortes_age(code),
  add column if not exists niveau_declare text,
  add column if not exists objectif text,
  add column if not exists diagnostic_statut text not null default 'a_planifier',
  add column if not exists onboarding_fait_le timestamptz;

-- Le niveau auto-declare n'est pas le niveau officiel, et les libelles visibles
-- ne sont jamais des codes de referentiel : aucune reponse d'onboarding ne
-- s'appelle F1, F2 ni F3.
alter table public.student_profiles
  drop constraint if exists student_profiles_niveau_declare_check;
alter table public.student_profiles
  add constraint student_profiles_niveau_declare_check
  check (niveau_declare is null or niveau_declare in (
    'debut_lettres',
    'lettres_avec_aide',
    'lecture_lente',
    'lecture_courante',
    'memorisation_partielle'
  ));

alter table public.student_profiles
  drop constraint if exists student_profiles_objectif_check;
alter table public.student_profiles
  add constraint student_profiles_objectif_check
  check (objectif is null or objectif in (
    'apprendre_a_lire',
    'devenir_fluide',
    'memoriser',
    'indecis'
  ));

alter table public.student_profiles
  drop constraint if exists student_profiles_diagnostic_statut_check;
alter table public.student_profiles
  add constraint student_profiles_diagnostic_statut_check
  check (diagnostic_statut in ('non_requis', 'a_planifier', 'planifie', 'fait'));

comment on column public.student_profiles.niveau_declare is
  'Pre-diagnostic declare par la famille. Sert au filtrage provisoire, '
  'n''attribue JAMAIS le niveau officiel, qui est public.student_profiles.level '
  'et que le client ne peut pas mettre a jour (aucun grant update).';

comment on column public.student_profiles.diagnostic_statut is
  'Ou en est le diagnostic academique. Jamais accorde en update au client : '
  'une famille ne declare pas son diagnostic acquis.';

-- Ce que la famille peut ecrire, colonne par colonne. `level`,
-- `diagnostic_statut`, `student_type` et `riwaya` restent hors de cette liste :
-- la RLS borne les LIGNES, seuls les grants bornent les COLONNES.
grant update (langue_cours, cohorte, niveau_declare, objectif, onboarding_fait_le)
  on public.student_profiles to authenticated;

-- ============================================================
-- 4. L'offre horaire vitrine
-- ============================================================

-- Vrai quand un tableau de jours ISO est exploitable : non vide, borne a
-- 1..7, sans doublon. `immutable` et sans acces a une table, donc utilisable
-- dans une contrainte.
create or replace function public.jours_iso_valides(p_jours smallint[])
returns boolean
language sql immutable set search_path = ''
as $function$
  select p_jours is not null
     and array_length(p_jours, 1) between 1 and 7
     and not exists (select 1 from unnest(p_jours) j where j is null or j < 1 or j > 7)
     and array_length(p_jours, 1) = (select count(distinct j) from unnest(p_jours) j);
$function$;

revoke execute on function public.jours_iso_valides(smallint[]) from public;
revoke execute on function public.jours_iso_valides(smallint[]) from anon;
grant execute on function public.jours_iso_valides(smallint[]) to authenticated, agent_ro;

-- Un motif d'horaire publie, jamais un groupe.
--
-- **Ce que cette table ne porte pas, et ne portera pas** : aucun enseignant,
-- aucun compteur d'inscrits, aucune place restante. Ce ne sont pas des
-- colonnes oubliees : a ce stade aucun vrai groupe n'est garanti, et les
-- montrer serait une promesse que l'academie n'a pas faite.
create table if not exists public.offres_horaires (
  id uuid primary key default gen_random_uuid(),
  type_public text not null check (type_public in ('enfant', 'adulte')),
  langue_code text not null references public.langues_cours(code),
  fuseau_iana text not null check (btrim(fuseau_iana) <> ''),
  jours smallint[] not null,
  heure_locale smallint not null check (heure_locale between 0 and 23),
  duree_minutes smallint not null check (duree_minutes between 15 and 240),
  rythme public.recurrence_rule not null default 'weekly',
  -- Nullable, et c'est un constat, pas un oubli : `programme_niveaux` est vide
  -- en production. Une offre sans niveau est compatible avec tout le monde.
  programme_niveau_id uuid references public.programme_niveaux(id),
  etat text not null default 'brouillon'
    check (etat in ('brouillon', 'publiee', 'retiree')),
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  publiee_at timestamptz,
  publiee_par uuid references public.profiles(id),
  retiree_at timestamptz,
  retiree_par uuid references public.profiles(id),
  retrait_motif text,
  constraint offres_jours_valides check (public.jours_iso_valides(jours)),
  constraint offres_publication_complete
    check (etat <> 'publiee' or (publiee_at is not null and publiee_par is not null)),
  constraint offres_retrait_complet
    check (etat <> 'retiree' or (retiree_at is not null and retiree_par is not null
           and coalesce(btrim(retrait_motif), '') <> ''))
);

-- Deux offres vivantes identiques diviseraient le vivier pour rien.
create unique index if not exists offres_horaires_motif_unique
  on public.offres_horaires (type_public, langue_code, fuseau_iana, heure_locale, jours)
  where etat <> 'retiree';

create index if not exists offres_horaires_publiees
  on public.offres_horaires (type_public, langue_code) where etat = 'publiee';

alter table public.offres_horaires enable row level security;

-- Une offre publiee se lit par tout compte connecte, y compris en
-- verification : c'est la vitrine. Un brouillon et une offre retiree ne se
-- lisent que par l'administration et le controle.
create policy offres_horaires_vitrine on public.offres_horaires
  for select to authenticated
  using (
    etat = 'publiee'
    or coalesce(public.app_role() in ('admin', 'controller'), false)
  );

create policy offres_horaires_admin on public.offres_horaires
  for all to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false))
  with check (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

grant select on public.offres_horaires to authenticated, agent_ro;
grant insert, update, delete on public.offres_horaires to authenticated;
revoke all on public.offres_horaires from anon;
revoke all on public.offres_horaires from public;

-- ============================================================
-- 5. L'intention d'horaire : une preference enregistree, pas une place reservee
-- ============================================================

create table if not exists public.intentions_horaire (
  id uuid primary key default gen_random_uuid(),
  eleve_id uuid not null references public.profiles(id) on delete cascade,
  offre_id uuid not null references public.offres_horaires(id),
  -- Ce que la famille a VU, dans son fuseau, au moment du choix. Ce n'est pas
  -- une redondance de l'offre : c'est la preuve de ce qui a ete montre. Quand
  -- le fuseau du foyer change, ou quand l'heure d'ete deplace le creneau, on
  -- peut dire « vous aviez vu 18:00, c'est desormais 19:00 » au lieu de
  -- changer l'heure en silence.
  fuseau_affiche text not null check (btrim(fuseau_affiche) <> ''),
  heure_affichee smallint not null check (heure_affichee between 0 and 23),
  jours_affiches smallint[] not null,
  etat text not null default 'enregistree'
    check (etat in ('enregistree', 'diagnostic_planifie', 'en_formation', 'affectee', 'retiree')),
  groupe_id uuid references public.groupes(id),
  created_at timestamptz not null default now(),
  created_by uuid not null references public.profiles(id),
  retiree_at timestamptz,
  retiree_par uuid references public.profiles(id),
  retrait_motif text,
  constraint intentions_jours_valides check (public.jours_iso_valides(jours_affiches)),
  constraint intentions_affectation_complete
    check (etat <> 'affectee' or groupe_id is not null),
  constraint intentions_retrait_complet
    check (etat <> 'retiree' or (retiree_at is not null and retiree_par is not null
           and coalesce(btrim(retrait_motif), '') <> ''))
);

-- Une seule intention vivante par eleve, comme `ajouter_eleve_groupe` n'admet
-- qu'un groupe actif par eleve. Changer d'avis passe donc par un renoncement
-- explicite, jamais par une accumulation silencieuse.
create unique index if not exists intentions_une_vivante_par_eleve
  on public.intentions_horaire (eleve_id) where etat <> 'retiree';

create index if not exists intentions_par_offre
  on public.intentions_horaire (offre_id) where etat <> 'retiree';

alter table public.intentions_horaire enable row level security;

-- Lecture par les parties au dossier -- ce qui inclut le foyer en
-- verification, `partie_concernee` n'exigeant pas un compte valide -- et par
-- l'administration et le controle.
create policy intentions_horaire_parties on public.intentions_horaire
  for select to authenticated
  using (
    public.partie_concernee(eleve_id)
    or coalesce(public.app_role() in ('admin', 'controller'), false)
  );

create policy intentions_horaire_admin on public.intentions_horaire
  for all to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false))
  with check (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

-- Aucune policy d'insertion pour la famille : une intention s'ecrit par
-- `choisir_offre_horaire`, qui verifie la compatibilite. Une insertion directe
-- pourrait poser une intention sur une offre incompatible, ou sur un brouillon.
grant select on public.intentions_horaire to authenticated, agent_ro;
grant insert, update, delete on public.intentions_horaire to authenticated;
revoke all on public.intentions_horaire from anon;
revoke all on public.intentions_horaire from public;

-- ============================================================
-- 6. Les creneaux d'un groupe, sans toucher a l'ancre existante
-- ============================================================

alter table public.groupes
  add column if not exists offre_id uuid references public.offres_horaires(id),
  add column if not exists langue_code text references public.langues_cours(code);

create table if not exists public.groupe_creneaux (
  id uuid primary key default gen_random_uuid(),
  groupe_id uuid not null references public.groupes(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  hour_local smallint not null check (hour_local between 0 and 23),
  created_at timestamptz not null default now(),
  constraint groupe_creneaux_unique unique (groupe_id, weekday, hour_local)
);

create index if not exists groupe_creneaux_par_groupe
  on public.groupe_creneaux (groupe_id);

-- L'ancre `groupes.weekday`/`hour_local` est le creneau que tout le code
-- existant lit. Ce declencheur la recopie dans `groupe_creneaux` a la creation
-- et a chaque deplacement, pour que les deux representations ne puissent pas
-- diverger : le nouveau code lit `groupe_creneaux` et y trouve toujours au
-- moins l'ancre, l'ancien lit `groupes` et n'a pas une ligne a changer.
create or replace function public.groupe_creneau_ancre()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if tg_op = 'UPDATE'
     and old.weekday = new.weekday
     and old.hour_local = new.hour_local then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    delete from public.groupe_creneaux
    where groupe_id = new.id
      and weekday = old.weekday
      and hour_local = old.hour_local;
  end if;

  insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
  values (new.id, new.weekday, new.hour_local)
  on conflict (groupe_id, weekday, hour_local) do nothing;

  return new;
end;
$function$;

drop trigger if exists groupes_creneau_ancre on public.groupes;
create trigger groupes_creneau_ancre
  after insert or update of weekday, hour_local on public.groupes
  for each row execute function public.groupe_creneau_ancre();

-- Rattrapage des groupes deja crees. Aucun en production le 22 septembre 2026,
-- mais un environnement de developpement peut en avoir.
insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
select g.id, g.weekday, g.hour_local from public.groupes g
on conflict (groupe_id, weekday, hour_local) do nothing;

alter table public.groupe_creneaux enable row level security;

-- Un creneau se lit exactement par qui peut lire son groupe : la policy rejoue
-- `groupes_lecture` par un `exists`, elle ne la reecrit pas. Une policy qui
-- recopierait ses conditions finirait par diverger.
create policy groupe_creneaux_lecture on public.groupe_creneaux
  for select to authenticated
  using (exists (
    select 1 from public.groupes g where g.id = groupe_creneaux.groupe_id
  ));

create policy groupe_creneaux_admin on public.groupe_creneaux
  for all to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false))
  with check (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

grant select on public.groupe_creneaux to authenticated, agent_ro;
grant insert, update, delete on public.groupe_creneaux to authenticated;
revoke all on public.groupe_creneaux from anon;
revoke all on public.groupe_creneaux from public;

-- ============================================================
-- 7. Les regles de l'academie, versionnees, jamais ecrites dans un widget
-- ============================================================

insert into public.app_config (key, value) values
  ('groupe.capacite_enfant',         to_jsonb(5)),
  ('groupe.capacite_adulte',         to_jsonb(6)),
  ('groupe.minimum_lancement',       to_jsonb(3)),
  ('groupe.seances_par_semaine',     to_jsonb(3)),
  ('seance.duree_minutes_enfant',    to_jsonb(60)),
  ('seance.duree_minutes_adulte',    to_jsonb(90)),
  ('seance.pause_minutes_enfant',    to_jsonb(6)),
  ('seance.pause_minutes_adulte',    to_jsonb(0))
on conflict (key) do nothing;

-- Les regles que l'onboarding et la vitrine doivent connaitre, en une lecture.
--
-- `app_config` n'est lisible que par l'administration (`app_config_admin_read`).
-- Cette fonction est donc la seule voie par laquelle une famille apprend la
-- capacite d'un groupe ou la duree d'une seance -- et elle ne rend que ces
-- huit valeurs, jamais la table.
create or replace function public.regles_academie()
returns jsonb
language sql stable security definer set search_path = ''
as $function$
  select case
    when public.compte_en_parcours() then jsonb_build_object(
      'capacite_enfant',      public.app_config_int('groupe.capacite_enfant', 5),
      'capacite_adulte',      public.app_config_int('groupe.capacite_adulte', 6),
      'minimum_lancement',    public.app_config_int('groupe.minimum_lancement', 3),
      'seances_par_semaine',  public.app_config_int('groupe.seances_par_semaine', 3),
      'duree_minutes_enfant', public.app_config_int('seance.duree_minutes_enfant', 60),
      'duree_minutes_adulte', public.app_config_int('seance.duree_minutes_adulte', 90),
      'pause_minutes_enfant', public.app_config_int('seance.pause_minutes_enfant', 6),
      'pause_minutes_adulte', public.app_config_int('seance.pause_minutes_adulte', 0)
    )
    else null
  end;
$function$;

revoke execute on function public.regles_academie() from public;
revoke execute on function public.regles_academie() from anon;
grant execute on function public.regles_academie() to authenticated, agent_ro;

-- ============================================================
-- 8. Ce que la famille ecrit
-- ============================================================

-- Enregistre le profil d'apprentissage d'un apprenant.
--
-- Ecrit `student_profiles` (langue, cohorte, niveau declare, objectif) et le
-- fuseau du foyer. `student_type` et `interface_mode` sont DEDUITS de la
-- cohorte par le serveur : le client ne les envoie pas et ne pourrait pas les
-- choisir.
--
-- `camera_policy` n'est deliberement pas touchee : ADR-012 la confie au parent,
-- dans un ecran de reglages qui l'explique. La deduire d'une tranche d'age
-- ouvrirait une camera sans que personne l'ait demande.
create or replace function public.enregistrer_profil_apprentissage(
  p_membre_id uuid,
  p_langue_code text,
  p_cohorte text,
  p_niveau_declare text,
  p_objectif text,
  p_fuseau_iana text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_cohorte public.cohortes_age;
  v_foyer uuid;
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  select * into v_cohorte from public.cohortes_age
  where code = p_cohorte and actif;
  if not found then
    raise exception 'cohorte inconnue ou retiree : %', coalesce(p_cohorte, 'aucune');
  end if;

  if not exists (
    select 1 from public.langues_cours where code = p_langue_code and actif
  ) then
    raise exception 'langue de cours inconnue ou retiree : %', coalesce(p_langue_code, 'aucune');
  end if;

  if coalesce(btrim(p_fuseau_iana), '') = '' then
    raise exception 'un fuseau est requis : c''est lui qui fixe l''heure affichee';
  end if;

  -- Un fuseau doit exister : sans ce controle, une chaine fantaisiste ferait
  -- echouer chaque conversion d'horaire plus tard, loin de sa cause.
  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana
  ) then
    raise exception 'fuseau IANA inconnu : %', p_fuseau_iana;
  end if;

  update public.student_profiles set
    langue_cours = p_langue_code,
    cohorte = p_cohorte,
    niveau_declare = p_niveau_declare,
    objectif = p_objectif,
    student_type = v_cohorte.student_type,
    interface_mode = v_cohorte.interface_mode,
    onboarding_fait_le = now()
  where profile_id = p_membre_id and deleted_at is null;

  if not found then
    raise exception 'aucune fiche eleve vivante pour ce profil';
  end if;

  select p.household_id into v_foyer from public.profiles p where p.id = p_membre_id;
  if v_foyer is not null then
    update public.households set timezone = p_fuseau_iana
    where id = v_foyer and deleted_at is null;
  end if;

  perform public.log_sensitive_access(
    'profil_apprentissage_enregistre', 'student_profiles', p_membre_id::text,
    jsonb_build_object('langue', p_langue_code, 'cohorte', p_cohorte,
                       'niveau_declare', p_niveau_declare, 'objectif', p_objectif,
                       'fuseau', p_fuseau_iana)
  );
end;
$function$;

revoke execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text, text) from public;
revoke execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text, text) from anon;
revoke execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text, text) from agent_ro;
grant execute on function public.enregistrer_profil_apprentissage(uuid, text, text, text, text, text) to authenticated;

-- Les offres compatibles avec un apprenant, exprimees dans le fuseau demande.
--
-- Le vivier est celui de la mission : langue exacte, public de la cohorte,
-- offre publiee, niveau compatible quand l'offre en exige un. Le filtrage est
-- SERVEUR : le client ne recoit jamais le catalogue entier.
--
-- `jours_locaux` et `heures_locales` passent par un instant reel
-- (`instant_creneau`), donc l'heure d'ete est prise en compte et un creneau
-- peut changer de jour d'un fuseau a l'autre.
--
-- **Les deux tableaux sont paralleles** : le jour d'indice i se tient a l'heure
-- d'indice i. Ce n'est pas une complication gratuite. Une semaine de changement
-- d'heure decale certains jours et pas d'autres : une offre de 18:00 a Paris
-- peut se lire 19:00 le lundi et 20:00 le mercredi depuis un autre fuseau. Une
-- heure unique aurait donc menti un jour sur trois, deux fois par an.
--
-- `heure_source` et `fuseau_source` disent l'heure de reference de l'offre,
-- pour que l'ecran puisse l'expliquer sans la deviner.
--
-- Aucune colonne d'enseignant, aucun compteur : voir la section 4.
create or replace function public.offres_compatibles(
  p_membre_id uuid,
  p_fuseau_vue text
)
returns table (
  offre_id uuid,
  type_public text,
  langue_code text,
  langue_nom text,
  jours_locaux smallint[],
  heures_locales smallint[],
  heure_source smallint,
  fuseau_source text,
  duree_minutes smallint,
  rythme text,
  pause_minutes smallint,
  capacite smallint,
  deja_choisie boolean
)
language sql stable security definer set search_path = ''
as $function$
  with fiche as (
    select sp.langue_cours, sp.level, c.type_public
    from public.student_profiles sp
    join public.cohortes_age c on c.code = sp.cohorte
    where sp.profile_id = p_membre_id
      and sp.deleted_at is null
      and public.peut_decrire_apprenant(p_membre_id)
      and exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_vue)
  )
  select
    o.id,
    o.type_public,
    o.langue_code,
    l.nom_humain,
    v.jours_locaux,
    v.heures_locales,
    o.heure_locale,
    o.fuseau_iana,
    o.duree_minutes,
    o.rythme::text,
    case o.type_public
      when 'adulte' then public.app_config_int('seance.pause_minutes_adulte', 0)::smallint
      else public.app_config_int('seance.pause_minutes_enfant', 6)::smallint
    end,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = p_membre_id and i.offre_id = o.id and i.etat <> 'retiree'
    )
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join fiche f
  cross join lateral (
    select
      array_agg(x.jour order by x.rang)::smallint[]  as jours_locaux,
      array_agg(x.heure order by x.rang)::smallint[] as heures_locales
    from (
      select
        j.rang,
        extract(isodow from j.local)::smallint as jour,
        extract(hour   from j.local)::smallint as heure
      from (
        select
          u.rang,
          public.instant_creneau(u.j::int, o.heure_locale::int, o.fuseau_iana)
            at time zone p_fuseau_vue as local
        from unnest(o.jours) with ordinality as u(j, rang)
      ) j
    ) x
  ) v
  where o.etat = 'publiee'
    and o.type_public = f.type_public
    and o.langue_code = f.langue_cours
    and (o.programme_niveau_id is null or o.programme_niveau_id::text = f.level)
  order by 2, 7, 4;
$function$;

revoke execute on function public.offres_compatibles(uuid, text) from public;
revoke execute on function public.offres_compatibles(uuid, text) from anon;
grant execute on function public.offres_compatibles(uuid, text) to authenticated, agent_ro;

-- Enregistre le choix d'une offre. **N'affecte aucun groupe, n'appelle aucun
-- enseignant, ne reserve aucune place.** L'etat rendu a l'ecran doit le dire.
create or replace function public.choisir_offre_horaire(
  p_membre_id uuid,
  p_offre_id uuid,
  p_fuseau_vue text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_compatible record;
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  -- La compatibilite est rejouee ici, et non presumee de l'ecran : un client
  -- pourrait poster n'importe quel identifiant d'offre.
  select * into v_compatible
  from public.offres_compatibles(p_membre_id, p_fuseau_vue) o
  where o.offre_id = p_offre_id;

  if not found then
    raise exception 'cette offre n''est pas compatible avec ce profil, ou n''est plus publiee';
  end if;

  begin
    insert into public.intentions_horaire
      (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
    values
      (p_membre_id, p_offre_id, p_fuseau_vue,
       v_compatible.heures_locales[1], v_compatible.jours_locaux, auth.uid())
    returning id into v_id;
  exception
    when unique_violation then
      raise exception 'cet apprenant a deja une preference horaire enregistree';
  end;

  -- Le diagnostic academique reste a faire : le dire ici, une fois, evite que
  -- l'ecran ait a le deviner.
  update public.student_profiles
  set diagnostic_statut = 'a_planifier'
  where profile_id = p_membre_id and diagnostic_statut = 'non_requis';

  perform public.log_sensitive_access(
    'intention_horaire_enregistree', 'intentions_horaire', v_id::text,
    jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id,
                       'fuseau_affiche', p_fuseau_vue)
  );

  return v_id;
end;
$function$;

revoke execute on function public.choisir_offre_horaire(uuid, uuid, text) from public;
revoke execute on function public.choisir_offre_horaire(uuid, uuid, text) from anon;
revoke execute on function public.choisir_offre_horaire(uuid, uuid, text) from agent_ro;
grant execute on function public.choisir_offre_horaire(uuid, uuid, text) to authenticated;

-- Renonce a une preference horaire. Explicite et motive : sans cela, l'unicite
-- d'intention vivante forcerait la famille dans un choix definitif.
create or replace function public.renoncer_intention_horaire(
  p_membre_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour renoncer a une preference';
  end if;

  update public.intentions_horaire
  set etat = 'retiree', retiree_at = now(), retiree_par = auth.uid(),
      retrait_motif = btrim(p_motif)
  where eleve_id = p_membre_id and etat <> 'retiree';

  if not found then
    raise exception 'aucune preference horaire vivante pour cet apprenant';
  end if;

  perform public.log_sensitive_access(
    'intention_horaire_retiree', 'intentions_horaire', p_membre_id::text,
    jsonb_build_object('motif', btrim(p_motif))
  );
end;
$function$;

revoke execute on function public.renoncer_intention_horaire(uuid, text) from public;
revoke execute on function public.renoncer_intention_horaire(uuid, text) from anon;
revoke execute on function public.renoncer_intention_horaire(uuid, text) from agent_ro;
grant execute on function public.renoncer_intention_horaire(uuid, text) to authenticated;

-- Signale qu'aucun horaire propose ne convient.
--
-- **Ce que cette fonction fait** : une ligne dans `matching_requests`, la table
-- que l'academie depouille deja en `ADM-06`. Elle REUTILISE ce modele plutot
-- que d'inventer une table de liste d'attente.
--
-- **Ce qu'elle ne fait pas** : creer un groupe, chercher un enseignant,
-- promettre un horaire futur. C'est un signal de demande non satisfaite, et
-- rien de plus. La formulation a l'ecran ne doit pas en dire davantage.
--
-- Elle n'emprunte pas `demander()` : `p_rule_value` y est un `integer`, ce qui
-- ne peut pas porter un motif structure (public, langue, fuseau, jours
-- souhaites). La table est reutilisee, la fonction ne l'est pas.
create or replace function public.signaler_horaire_insatisfait(
  p_membre_id uuid,
  p_detail jsonb
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_role public.app_role := public.app_role();
begin
  if not public.peut_decrire_apprenant(p_membre_id) then
    raise exception 'ce profil n''est pas le votre ni celui de votre foyer';
  end if;

  if v_role is null then
    raise exception 'compte sans role';
  end if;

  insert into public.matching_requests
    (kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
  values
    ('horaire_insatisfait', p_membre_id, 'offre_horaire',
     coalesce(p_detail, '{}'::jsonb),
     'aucun horaire propose ne convient a ce foyer',
     auth.uid(), v_role)
  returning id into v_id;

  perform public.log_sensitive_access(
    'horaire_insatisfait_signale', 'matching_requests', v_id::text,
    jsonb_build_object('eleve_id', p_membre_id, 'detail', coalesce(p_detail, '{}'::jsonb))
  );

  return v_id;
end;
$function$;

-- `matching_requests.kind` n'admettait que trois sortes. La contrainte est
-- elargie, pas remplacee : les trois sortes existantes restent valides, et
-- `demander()` continue de refuser toute sorte qu'elle ne connait pas.
alter table public.matching_requests
  drop constraint if exists matching_requests_kind_check;
alter table public.matching_requests
  add constraint matching_requests_kind_check
  check (kind in ('reassignment', 'capacity', 'rule_change', 'horaire_insatisfait'));

revoke execute on function public.signaler_horaire_insatisfait(uuid, jsonb) from public;
revoke execute on function public.signaler_horaire_insatisfait(uuid, jsonb) from anon;
revoke execute on function public.signaler_horaire_insatisfait(uuid, jsonb) from agent_ro;
grant execute on function public.signaler_horaire_insatisfait(uuid, jsonb) to authenticated;

-- ============================================================
-- 9. Ou en est chaque apprenant du foyer
-- ============================================================

-- L'etat du parcours, un apprenant par ligne.
--
-- `security_invoker` est indispensable : une vue sans lui s'executerait avec
-- les droits de son proprietaire et ignorerait la RLS -- le defaut deja paye
-- au lot N4.
--
-- Deux etats ne sont PAS stockes, ils sont DEDUITS, parce que les stocker
-- forcerait a les rafraichir et ils deviendraient faux en silence :
--   * `offre_indisponible` : l'offre choisie a ete retiree depuis le choix ;
--   * `fuseau_change` : le fuseau du foyer n'est plus celui qui etait affiche.
create or replace view public.v_parcours_onboarding
with (security_invoker = true) as
select
  sp.profile_id                                   as eleve_id,
  p.first_name                                    as prenom,
  sp.cohorte,
  c.nom_humain                                    as cohorte_nom,
  c.type_public,
  sp.langue_cours                                 as langue_code,
  l.nom_humain                                    as langue_nom,
  sp.niveau_declare,
  sp.objectif,
  sp.diagnostic_statut,
  sp.onboarding_fait_le,
  h.timezone                                      as fuseau_foyer,
  i.id                                            as intention_id,
  i.etat                                          as intention_etat,
  i.offre_id,
  i.fuseau_affiche,
  i.heure_affichee,
  i.jours_affiches,
  i.groupe_id,
  o.etat                                          as offre_etat,
  (i.id is not null and o.etat <> 'publiee')      as offre_indisponible,
  (i.id is not null and h.timezone is not null
     and h.timezone <> i.fuseau_affiche)          as fuseau_change
-- Aucun compteur d'intentions ici, et c'est deliberé : le nombre de familles
-- ayant choisi le meme creneau appartient a `offres_admin()`. La RLS le
-- filtrerait de toute facon a la seule ligne du foyer, ce qui donnerait un
-- « 1 » que l'ecran prendrait pour un vivier.
from public.student_profiles sp
join public.profiles p on p.id = sp.profile_id
left join public.cohortes_age c on c.code = sp.cohorte
left join public.langues_cours l on l.code = sp.langue_cours
left join public.households h on h.id = p.household_id
left join public.intentions_horaire i
  on i.eleve_id = sp.profile_id and i.etat <> 'retiree'
left join public.offres_horaires o on o.id = i.offre_id
where sp.deleted_at is null and p.deleted_at is null;

grant select on public.v_parcours_onboarding to authenticated, agent_ro;
revoke all on public.v_parcours_onboarding from anon;
revoke all on public.v_parcours_onboarding from public;

-- ============================================================
-- 10. Ce que l'administration lit et publie
-- ============================================================

-- Toutes les offres, avec leur vivier et l'etat de constitution.
--
-- C'est ICI que les compteurs vivent, et nulle part ailleurs : l'administration
-- a besoin de savoir qu'un vivier atteint le minimum, la famille n'a pas besoin
-- de savoir combien d'autres ont choisi le meme creneau.
create or replace function public.offres_admin()
returns table (
  offre_id uuid,
  type_public text,
  langue_code text,
  langue_nom text,
  jours smallint[],
  heure_locale smallint,
  fuseau_iana text,
  duree_minutes smallint,
  etat text,
  capacite smallint,
  minimum_lancement smallint,
  vivier int,
  non_affectes int,
  groupes_publies int,
  lancable boolean,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    o.id, o.type_public, o.langue_code, l.nom_humain, o.jours, o.heure_locale,
    o.fuseau_iana, o.duree_minutes, o.etat,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    public.app_config_int('groupe.minimum_lancement', 3)::smallint,
    v.vivier,
    v.non_affectes,
    (select count(*)::int from public.groupes g
      where g.offre_id = o.id and g.ended_at is null),
    v.non_affectes >= public.app_config_int('groupe.minimum_lancement', 3),
    o.created_at
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join lateral (
    select
      count(*) filter (where i.etat <> 'retiree')::int as vivier,
      count(*) filter (where i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation'))::int
        as non_affectes
    from public.intentions_horaire i where i.offre_id = o.id
  ) v
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  order by (o.etat <> 'publiee'), o.type_public, o.heure_locale;
$function$;

revoke execute on function public.offres_admin() from public;
revoke execute on function public.offres_admin() from anon;
grant execute on function public.offres_admin() to authenticated, agent_ro;

create or replace function public.creer_offre_horaire(
  p_type_public text,
  p_langue_code text,
  p_fuseau_iana text,
  p_jours smallint[],
  p_heure_locale smallint,
  p_duree_minutes smallint default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
  v_duree smallint;
  v_attendu smallint := public.app_config_int('groupe.seances_par_semaine', 3)::smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'creation d''offre reservee a l''administration';
  end if;

  if p_type_public not in ('enfant', 'adulte') then
    raise exception 'public inconnu : %', coalesce(p_type_public, 'aucun');
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana) then
    raise exception 'fuseau IANA inconnu : %', coalesce(p_fuseau_iana, 'aucun');
  end if;

  if not public.jours_iso_valides(p_jours) then
    raise exception 'jours invalides : un tableau non vide de jours ISO distincts est attendu';
  end if;

  if array_length(p_jours, 1) <> v_attendu then
    raise exception 'l''academie annonce % seances par semaine, % jours fournis',
      v_attendu, array_length(p_jours, 1);
  end if;

  v_duree := coalesce(
    p_duree_minutes,
    case p_type_public
      when 'adulte' then public.app_config_int('seance.duree_minutes_adulte', 90)::smallint
      else public.app_config_int('seance.duree_minutes_enfant', 60)::smallint
    end
  );

  insert into public.offres_horaires
    (type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, created_by)
  values
    (p_type_public, p_langue_code, p_fuseau_iana, p_jours, p_heure_locale, v_duree, auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access(
    'offre_horaire_creee', 'offres_horaires', v_id::text,
    jsonb_build_object('type_public', p_type_public, 'langue', p_langue_code,
                       'jours', p_jours, 'heure', p_heure_locale)
  );

  return v_id;
end;
$function$;

create or replace function public.publier_offre_horaire(p_offre_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication d''offre reservee a l''administration';
  end if;

  update public.offres_horaires
  set etat = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_offre_id and etat = 'brouillon';

  if not found then
    raise exception 'offre introuvable ou deja publiee';
  end if;

  perform public.log_sensitive_access(
    'offre_horaire_publiee', 'offres_horaires', p_offre_id::text, '{}'::jsonb);
end;
$function$;

-- Retire une offre de la vitrine. Les intentions deja posees ne sont PAS
-- supprimees : la vue les marque `offre_indisponible`, et l'academie doit les
-- traiter. Effacer ces lignes ferait disparaitre une demande que quelqu'un a
-- exprimee.
create or replace function public.retirer_offre_horaire(
  p_offre_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'retrait d''offre reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer une offre';
  end if;

  update public.offres_horaires
  set etat = 'retiree', retiree_at = now(), retiree_par = auth.uid(),
      retrait_motif = btrim(p_motif)
  where id = p_offre_id and etat <> 'retiree';

  if not found then
    raise exception 'offre introuvable ou deja retiree';
  end if;

  perform public.log_sensitive_access(
    'offre_horaire_retiree', 'offres_horaires', p_offre_id::text,
    jsonb_build_object('motif', btrim(p_motif)));
end;
$function$;

-- Le vivier d'une offre, nominatif, pour que l'administration compose un
-- groupe. Reserve a l'administration, et masque comme partout ailleurs quand
-- un agent observe.
create or replace function public.pool_offre(p_offre_id uuid)
returns table (
  eleve_id uuid,
  immutable_id text,
  prenom text,
  nom text,
  niveau_declare text,
  niveau_officiel text,
  diagnostic_statut text,
  intention_etat text,
  intention_depuis timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select
    i.eleve_id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    sp.niveau_declare,
    sp.level,
    sp.diagnostic_statut,
    i.etat,
    i.created_at
  from public.intentions_horaire i
  join public.profiles p on p.id = i.eleve_id
  join public.student_profiles sp on sp.profile_id = i.eleve_id
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
    and i.offre_id = p_offre_id
    and i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation')
  order by i.created_at asc;
$function$;

-- Publie un vrai groupe depuis une offre : l'enseignant est affecte ICI, et
-- c'est la premiere fois qu'un enseignant existe dans ce parcours.
--
-- Trois regles sont tenues par cette fonction, et non par l'ecran :
--   * pas moins que `groupe.minimum_lancement` eleves ;
--   * pas plus que la capacite du public ;
--   * un eleve doit avoir une intention vivante SUR CETTE OFFRE.
--
-- Elle cree les creneaux de tous les jours de l'offre, et non le seul jour
-- d'ancre : c'est ce qui rend vraie la promesse de la vitrine.
create or replace function public.publier_groupe_depuis_offre(
  p_offre_id uuid,
  p_teacher_profile_id uuid,
  p_libelle text,
  p_eleve_ids uuid[]
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_offre public.offres_horaires;
  v_groupe uuid;
  v_capacite smallint;
  v_minimum smallint := public.app_config_int('groupe.minimum_lancement', 3)::smallint;
  v_n int := coalesce(array_length(p_eleve_ids, 1), 0);
  v_eleve uuid;
  v_jour smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication de groupe reservee a l''administration';
  end if;

  select * into v_offre from public.offres_horaires where id = p_offre_id and etat = 'publiee';
  if not found then
    raise exception 'offre introuvable ou non publiee';
  end if;

  v_capacite := case v_offre.type_public
    when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
    else public.app_config_int('groupe.capacite_enfant', 5)::smallint
  end;

  if v_n < v_minimum then
    raise exception 'un groupe se lance a partir de % eleves, % fournis', v_minimum, v_n;
  end if;
  if v_n > v_capacite then
    raise exception 'la capacite de ce public est de %, % fournis', v_capacite, v_n;
  end if;

  -- `creer_groupe` verifie deja le role et l'etat du compte de l'enseignant :
  -- la reappeler evite de recopier ces controles, et donc de les laisser
  -- diverger.
  --
  -- **Arguments NOMMES, et ce n'est pas un ornement.** `creer_groupe` est
  -- surchargee : une version a 6 parametres dont 1 par defaut, une autre a 8
  -- dont 3 par defaut. Les six premiers portent les memes types dans les deux.
  -- Un appel positionnel a six arguments est donc AMBIGU, et PostgreSQL le
  -- refuse a l'execution -- c'est-a-dire au moment precis ou l'academie
  -- publierait son premier groupe. Nommer `p_timezone_iana`, qui n'existe que
  -- dans la version a huit, designe une seule candidate.
  v_groupe := public.creer_groupe(
    p_teacher_profile_id => p_teacher_profile_id,
    p_type_public        => v_offre.type_public,
    p_libelle            => p_libelle,
    p_weekday            => v_offre.jours[1]::smallint,
    p_hour_local         => v_offre.heure_locale,
    p_seuil_max          => v_capacite,
    p_timezone_iana      => v_offre.fuseau_iana
  );

  update public.groupes
  set offre_id = p_offre_id,
      langue_code = v_offre.langue_code
  where id = v_groupe;

  -- Le declencheur a deja pose l'ancre ; les autres jours s'ajoutent ici.
  foreach v_jour in array v_offre.jours loop
    insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
    values (v_groupe, v_jour, v_offre.heure_locale)
    on conflict (groupe_id, weekday, hour_local) do nothing;
  end loop;

  foreach v_eleve in array p_eleve_ids loop
    if not exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = v_eleve and i.offre_id = p_offre_id
        and i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation')
    ) then
      raise exception 'cet eleve n''a pas de preference vivante sur cette offre : %', v_eleve;
    end if;

    perform public.ajouter_eleve_groupe(
      v_groupe, v_eleve, 'groupe publie depuis l''offre ' || p_offre_id::text);

    update public.intentions_horaire
    set etat = 'affectee', groupe_id = v_groupe
    where eleve_id = v_eleve and offre_id = p_offre_id and etat <> 'retiree';
  end loop;

  -- Ce qui reste sous le minimum reste « en formation », et le dit.
  update public.intentions_horaire
  set etat = 'en_formation'
  where offre_id = p_offre_id and etat = 'enregistree';

  perform public.log_sensitive_access(
    'groupe_publie_depuis_offre', 'groupes', v_groupe::text,
    jsonb_build_object('offre_id', p_offre_id, 'teacher_id', p_teacher_profile_id,
                       'eleves', v_n, 'jours', v_offre.jours)
  );

  return v_groupe;
end;
$function$;

revoke execute on function public.creer_offre_horaire(text, text, text, smallint[], smallint, smallint) from public;
revoke execute on function public.creer_offre_horaire(text, text, text, smallint[], smallint, smallint) from anon;
revoke execute on function public.creer_offre_horaire(text, text, text, smallint[], smallint, smallint) from agent_ro;
grant execute on function public.creer_offre_horaire(text, text, text, smallint[], smallint, smallint) to authenticated;

revoke execute on function public.publier_offre_horaire(uuid) from public;
revoke execute on function public.publier_offre_horaire(uuid) from anon;
revoke execute on function public.publier_offre_horaire(uuid) from agent_ro;
grant execute on function public.publier_offre_horaire(uuid) to authenticated;

revoke execute on function public.retirer_offre_horaire(uuid, text) from public;
revoke execute on function public.retirer_offre_horaire(uuid, text) from anon;
revoke execute on function public.retirer_offre_horaire(uuid, text) from agent_ro;
grant execute on function public.retirer_offre_horaire(uuid, text) to authenticated;

revoke execute on function public.pool_offre(uuid) from public;
revoke execute on function public.pool_offre(uuid) from anon;
grant execute on function public.pool_offre(uuid) to authenticated, agent_ro;

-- La RPC la plus puissante de ce lot -- elle cree un groupe, affecte un
-- enseignant et y inscrit des eleves -- et la seule qui avait ete oubliee dans
-- les retraits. Une fonction sans `revoke` garde l'EXECUTE par defaut, c'est a
-- dire `public`, ce qui sur Supabase inclut `anon` ET `agent_ro` : la porte
-- interne les aurait refuses, mais un agent en lecture seule n'a rien a faire
-- avec un droit d'appel sur une ecriture (ADR-025). Les deux chemins sont
-- necessaires, aucun ne suffit seul.
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from public;
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from anon;
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from agent_ro;
grant execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) to authenticated;

revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from public;
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from anon;
revoke execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) from agent_ro;
grant execute on function public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[]) to authenticated;

revoke execute on function public.groupe_creneau_ancre() from public;
revoke execute on function public.groupe_creneau_ancre() from anon;
revoke execute on function public.groupe_creneau_ancre() from authenticated;
revoke execute on function public.groupe_creneau_ancre() from agent_ro;
