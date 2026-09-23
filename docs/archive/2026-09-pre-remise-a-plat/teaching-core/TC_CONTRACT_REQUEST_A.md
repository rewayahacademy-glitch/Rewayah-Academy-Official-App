# TC_CONTRACT_REQUEST_A — Agent A, Group Space

> Ce qu'il manque pour que l'expérience Groupe et la présentation du temps cessent d'être un double
> local et deviennent le produit. **Tout est vérifié dans `D:\RA_TC\a` à la baseline `0071557`**, y
> compris les migrations `0025` à `0029` que la cartographie d'Agent 0 ne voyait pas.
>
> Destinataire : Agent Z. Aucune migration n'est créée ici (décision `D-12`), aucune dépendance n'est
> ajoutée (décision `D-11`), aucun fichier du socle n'est touché.

---

## 0. Correction de la cartographie — à lire avant le reste

Quatre affirmations de `TEACHING_CORE_EXISTING_MAPPING.md` §1 et de `TEACHING_CORE_CONTRACTS.md` §1 et §3
**ne sont plus exactes** à `0071557`. Elles ont été écrites contre `550e605`, quand `0025` à `0029`
étaient invisibles. Je les corrige avant de demander quoi que ce soit : une demande fondée sur un faux
manque coûte autant qu'un manque oublié.

| Affirmation d'Agent 0 | État réel à `0071557` | Conséquence |
|---|---|---|
| « `public.sessions` n'a pas de colonne `groupe_id` » | **FAUX.** `0025_role_enseignant.sql:46-51` ajoute `sessions.groupe_id uuid references public.groupes(id)`, nullable, avec index partiel `sessions_groupe_idx`. | La colonne existe. **Ce qui manque est son alimentation** : voir §1.1. |
| « `groupes.timezone_iana` n'est lue par aucune RPC » | **FAUX pour l'enseignant.** `mes_groupes_v` (`0025:102-119`) la retourne, et `GroupeEnseignant.depuisJson` (`modeles_enseignant.dart:232-235`) la lit correctement. | Reste vrai pour l'**élève**, le **tuteur** et l'**admin** : voir §1.2 et §1.3. |
| « `GroupeAdmin.depuisJson` recode le fuseau en dur » | **VRAI, et seulement là.** `lib/core/admin/service_groupes.dart:69` écrit `fuseau: 'Europe/Paris'`, parce que `groupes_admin()` (`0019:241`) ne rend pas la colonne. | Chemin **admin** uniquement. Corrigé par §1.3. |
| « Aucune lecture de groupe hors admin » | **FAUX pour l'enseignant** (`mes_groupes_v`, `mon_groupe_detail(uuid)`). **VRAI pour l'élève et le tuteur.** | Voir §1.2. |

Un cinquième point, écrit dans l'en-tête de `0025` lignes 33-40 et qui change la portée de plusieurs
demandes : **les migrations `0020` à `0024` sont committées sur `main` mais n'ont jamais été appliquées
à cette base.** `programme_niveaux`, `progression_historique` et `evaluations` **n'existent pas** en
base. `unite_curriculum()` les lit par SQL dynamique gardé par `to_regclass` et rend `null` tant
qu'elles sont absentes. Toute demande qui s'appuie sur le curriculum (§1.7) doit donc être ordonnancée
après leur application, ou reproduire le même garde-fou.

---

## 1. DEMANDE SQL

Forme imposée par `D-12` : nom exact de l'objet, colonnes et types, RLS attendue, rôle appelant, et la
table existante qu'elle étend. Les deux règles de sécurité rappelées dans chaque demande :

1. **Jamais `grant execute` à `agent_ro` sur une RPC volatile ou d'écriture.** `get_advisors` ne le
   détecte pas. Les fonctions ci-dessous sont marquées `stable` ou `volatile`, et le grant suit.
2. **Toute nouvelle vue d'exposition répète le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne.** Le motif est dupliqué à la main dans le dépôt, et
   une surface oubliée est une fuite avec une bannière devant.

---

### 1.1 Matérialiser les occurrences d'un groupe — **BLOQUANT n°1**

**Constat mesuré.** `sessions.groupe_id` existe mais **aucune écriture ne l'alimente** : la seule
insertion dans `public.sessions` du dépôt est `materialiser_seances(p_assignment_id uuid)`
(`0005:996`), qui lit `teacher_student_assignments` (modèle 1-à-1 d'avant le pivot) et écrit
`insert into public.sessions (teacher_id, started_at, ended_at, session_type)` — **sans `groupe_id`**.
Un groupe créé aujourd'hui ne produit donc **aucune séance**, et par conséquent aucune prochaine
séance, aucun compte à rebours, aucun bouton « Rejoindre ».

**Étend** : `public.materialiser_seances(uuid)` (`0005`), `public.sessions` (`0001`, `0025`),
`public.groupes` et `public.groupe_membres` (`0017`, durcies `0019`).

**Objet demandé** :

```sql
create or replace function public.materialiser_seances_groupe(p_groupe_id uuid)
returns int
language plpgsql
volatile
security definer
set search_path to ''
as $function$
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

  v_semaines := coalesce((public.get_config('matching_horizon_weeks'))::int, 4);
  v_duree    := coalesce((public.get_config('session_duration_minutes'))::int, 90);
  v_fenetre  := coalesce((public.get_config('join_window_minutes'))::int, 20);   -- voir 1.4

  for i in 0 .. v_semaines - 1 loop
    -- LE convertisseur du depot, jamais un recodage : instant_creneau() ancre la
    -- semaine en UTC depuis 0006, et la recoder rejouerait les sept jours d'ecart
    -- entre Paris et Conakry.
    v_debut := public.instant_creneau(
      v_g.weekday, v_g.hour_local, v_g.timezone_iana, i
    );

    -- Idempotence : une occurrence par (groupe, debut). Sans elle, un second
    -- appel doublerait le planning, exactement comme le ferait un cron rejoue.
    if exists (
      select 1 from public.sessions s
       where s.groupe_id = p_groupe_id
         and s.started_at = v_debut
         and s.deleted_at is null
    ) then
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
$function$;

revoke execute on function public.materialiser_seances_groupe(uuid) from public, anon, agent_ro;
grant  execute on function public.materialiser_seances_groupe(uuid) to service_role;
```

**RLS / rôle appelant** : `service_role` **uniquement**, exactement comme `materialiser_seances(uuid)`
(`0005:1013-1014`). C'est une écriture : `agent_ro` en est explicitement révoqué.

**Points d'attention qu'Agent Z doit trancher, et que je ne tranche pas ici** :

- `guard_session_participant_cap` (`0001:847-862`) lit `app_config.max_participants_per_session`,
  porté à 7 par `0017`. Un groupe d'adultes à 6 élèves plus l'enseignant tient tout juste. **Un
  observateur tuteur ou un admin ferait déborder ce plafond** : l'exemption existe déjà pour le
  contrôleur (`0012`, deux listes), elle devra couvrir les nouveaux rôles d'observation. C'est la
  demande d'Agent G, mais elle croise celle-ci.
- `guard_session_overlap` : un élève inscrit à la fois dans un groupe et dans une affectation 1-à-1
  résiduelle produira deux séances au même créneau. `0017` déclare que **les deux modèles coexistent**
  en attendant un lot dédié avec audit RLS complet. Une règle de priorité est un arbitrage produit.
- Qui appelle cette fonction, et quand : à la création du groupe, à chaque ajout de membre, ou par une
  tâche planifiée. Le dépôt n'a **aucun ordonnanceur** ; `materialiser_seances` n'est appelée par
  aucune autre fonction SQL ni par `lib/`.

---

### 1.2 Une lecture de groupe pour l'élève et le tuteur — **BLOQUANT n°2**

**Constat mesuré.** `mes_groupes_v` (`0025:102-119`) est bornée par `g.teacher_id = auth.uid()`.
`groupes_admin()` / `groupe_detail(uuid)` sont `[admin]`. **Un élève et un tuteur n'ont aujourd'hui
aucun moyen de lire leur groupe.** Or l'Espace Groupe leur est destiné en premier.

**Étend** : `public.mes_groupes_v` (`0025`), `public.groupe_membres` (`0017`),
`public.household_members` / `public.app_household_id()` (`0001`, `0005`) pour le lien tuteur-enfant.

**Objet demandé** :

```sql
create or replace view public.mes_groupes_famille_v
with (security_barrier = true) as
select
  g.id                                            as groupe_id,
  g.libelle,
  g.type_public,
  g.seuil_max,
  g.weekday,
  g.hour_local,
  g.timezone_iana,
  g.couleur_jeton,                                 -- voir 1.6
  g.nom_cours,                                     -- voir 1.7
  g.programme_niveau_id,                           -- voir 1.7
  g.teacher_id,
  -- Masquage colonne par colonne, motif de 0014:828-1039. Une surface oubliee
  -- est une fuite avec une banniere devant.
  case when public.agent_identite_masquee() then null else tp_p.first_name end
                                                   as teacher_prenom,
  tp.titre                                         as teacher_titre,        -- voir 1.8
  tp.photo_storage_key                             as teacher_photo_cle,    -- voir 1.8
  count(m2.id) filter (where m2.left_at is null)::int as nb_membres
from public.groupes g
  join public.groupe_membres m on m.groupe_id = g.id and m.left_at is null
  join public.profiles tp_p on tp_p.id = g.teacher_id
  left join public.teacher_profiles tp on tp.profile_id = g.teacher_id
  left join public.groupe_membres m2 on m2.groupe_id = g.id
where g.ended_at is null
  and public.app_account_valid()
  and (
    -- L'eleve, pour lui-meme.
    m.student_id = auth.uid()
    -- Le tuteur legal, pour les eleves de son foyer.
    or m.student_id in (
      select hm.profile_id from public.household_members hm
       where hm.household_id = public.app_household_id()
         and hm.deleted_at is null
    )
  )
group by
  g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local,
  g.timezone_iana, g.couleur_jeton, g.nom_cours, g.programme_niveau_id,
  g.teacher_id, tp_p.first_name, tp.titre, tp.photo_storage_key;

revoke all on public.mes_groupes_famille_v from anon;
grant select on public.mes_groupes_famille_v to authenticated, agent_ro;
```

**Ce que la vue ne porte jamais** : aucun nom de famille d'élève, aucune coordonnée, aucun paiement.
Elle décrit un **groupe**, pas ses membres. Le roster nommé reste `mon_groupe_detail(uuid)`, réservé à
l'enseignant du groupe.

⚠ **Vérification demandée à Agent Z** : je n'ai pas mesuré la forme exacte de `household_members` ;
le prédicat de foyer doit être repris du prédicat déjà employé par `mes_seances_v`, pas réinventé.

**Demande jumelle** : que `groupes_admin()` (`0019:241`) retourne `timezone_iana`, `couleur_jeton`,
`nom_cours` et `programme_niveau_id`, afin que `GroupeAdmin.depuisJson` cesse de recoder
`'Europe/Paris'` en dur (`service_groupes.dart:69`). **Je n'ai pas corrigé ce fichier : il est hors de
mon ownership.**

---

### 1.3 Écrire `groupes.timezone_iana`

**Constat mesuré.** La colonne existe depuis `0017:34` (`not null default 'Europe/Paris'`). Elle est
**lue** par `mes_groupes_v` depuis `0025`. Elle n'est **écrite par aucune RPC** : `creer_groupe`
(`0019:82`) insère `(teacher_id, type_public, seuil_max, libelle, weekday, hour_local)` et
`modifier_groupe` (`0019:120`) met à jour `libelle, seuil_max, weekday, hour_local`. Le fuseau de
référence d'un groupe est donc **inchangeable**, et tout groupe est de facto parisien.

**Étend** : `public.creer_groupe(...)` et `public.modifier_groupe(...)` (`0019`).

**Objet demandé** : un paramètre `p_timezone_iana text default null` sur les deux fonctions, écrit tel
quel quand il est fourni, avec une validation :

```sql
-- Dans creer_groupe et modifier_groupe, avant l'ecriture :
if p_timezone_iana is not null then
  perform 1 from pg_timezone_names where name = p_timezone_iana;
  if not found then
    raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
  end if;
end if;
```

**Invariant produit à ne pas casser** : *le voyage d'un enseignant ne déplace jamais l'horaire
institutionnel du groupe*. `groupes.timezone_iana` est le fuseau du **groupe**, jamais celui de la
personne connectée. `mon_fuseau()` (`0005:407`) reste la source du fuseau **utilisateur** et n'est pas
touchée.

---

### 1.4 `join_opens_at` persisté et fenêtre configurable — **BLOQUANT n°3**

**Constat mesuré.** La fenêtre vaut **T-10, écrite en dur, à trois endroits** :

| Endroit | Ligne | Valeur |
|---|---|---|
| `autoriser_jeton_video()` | `0010:306` — `if now() < v_seance.started_at - interval '10 minutes'` | 10 min |
| `autoriser_jeton_video()`, seconde vérification | `0010:561` | 10 min |
| `seuilOuvertureSalle` | `lib/core/video/pre_vol.dart` **[PROTECTED]** | `Duration(minutes: 10)` |

La décision `D-13` exige **20 minutes par défaut, configurable**. Elle interdit aussi d'en poser une
quatrième : je n'en ai posé aucune. `FenetreSeance.fenetreAcces` est un **champ**, alimenté par le
port ; la seule valeur `20 min` de mon lot vit dans le jeu de démonstration
(`lib/core/tc_horloge/demonstration_horloge.dart`), lu par aucun widget.

**Le danger précis, s'il n'est pas traité** : une interface qui offre « Rejoindre » à T-20 propose une
porte que `autoriser_jeton_video()` refuse pendant dix minutes. **L'utilisateur clique et essuie une
erreur.** Les deux valeurs doivent venir de la même source, ou aucune des deux ne doit changer.

**Étend** : `public.app_config` (`0001:326`), `public.get_config(text, jsonb)` (`0001:934`),
`public.sessions` (`0001`, `0025`), `public.autoriser_jeton_video(...)` (`0010:261`).

**Objets demandés** :

```sql
-- 1. La valeur, dans le magasin cle/valeur deja employe pour les trois seuils
--    de presence. Vingt minutes, et non dix : decision D-13.
insert into public.app_config (key, value) values ('join_window_minutes', '20'::jsonb)
  on conflict (key) do nothing;

-- 2. Le fait, persiste sur l'occurrence : le client lit une donnee, il ne
--    recalcule pas une regle.
alter table public.sessions
  add column if not exists join_opens_at timestamptz;

comment on column public.sessions.join_opens_at is
  'Instant a partir duquel la salle est joignable. Ecrit a la materialisation '
  'depuis app_config.join_window_minutes. Nul pour les seances anterieures : '
  'autoriser_jeton_video() retombe alors sur la valeur de configuration.';

-- 3. La barriere serveur lit la MEME source. Sans ce troisieme point, les deux
--    premiers ne font qu'ouvrir un bouton que le serveur refusera.
--    Dans autoriser_jeton_video(), remplacer les deux occurrences de
--    `v_seance.started_at - interval '10 minutes'` par :
--      coalesce(
--        v_seance.join_opens_at,
--        v_seance.started_at
--          - make_interval(mins => coalesce(
--              (public.get_config('join_window_minutes'))::int, 20))
--      )
```

**RLS / rôle appelant** : inchangés. `autoriser_jeton_video` reste `security definer`, son grant
d'exécution n'est pas élargi. `join_opens_at` est exposé en lecture par les vues de §1.2 et par
`mes_seances_enseignant_v`.

---

### 1.5 L'horloge serveur

**Constat mesuré.** Aucune fonction n'expose l'heure du serveur. Les deux comptes à rebours existants
lisent `DateTime.now()` local : `_compteARebours()` dans `accueil_eleve_page.dart` et le minuteur de
`journee_page.dart` **[PROTECTED]**. Un appareil dont l'horloge dérive affiche un compte à rebours
faux, et un compte à rebours faux est pire qu'un compte à rebours absent.

**Étend** : rien. Objet neuf, minuscule.

```sql
create or replace function public.maintenant_serveur()
returns timestamptz
language sql
stable
security definer
set search_path to ''
as $function$ select now() $function$;

revoke execute on function public.maintenant_serveur() from public, anon;
-- `stable` et sans effet de bord : agent_ro est acceptable ici, et c'est le
-- seul cas de ce document ou il l'est.
grant execute on function public.maintenant_serveur() to authenticated, agent_ro, service_role;
```

L'adaptateur client en dérive un **décalage** mesuré une fois, puis applique ce décalage à l'horloge
locale : un aller-retour par seconde serait absurde. `SessionClockVM.calculeeAUtc` porte l'instant de
référence, et `FenetreSeance` ne lit jamais l'horloge par elle-même.

---

### 1.6 La couleur du groupe

**Constat mesuré.** `public.groupes` n'a **aucune colonne de couleur** (`0017:22-40`).
`lib/core/theme/app_palette.dart` est le **seul** fichier du dépôt autorisé à poser une couleur
littérale, et `tool/verifier_jetons.dart` refuse toute couleur nue ailleurs. La décision `D-18` demande
**32 à 40 teintes accessibles**, jamais un sélecteur hexadécimal libre.

**Ce que j'ai fait en attendant** : `lib/core/tc_groupe/palette_groupe.dart` compose avec **quatre**
paires existantes du thème (`washAccent`, `washFamily`, `surfaceQuran`, `surfaceSunken`). C'est un
huitième de la cible : deux groupes sur cinq partagent leur teinte, et trois de ces paires portent déjà
un sens dans le produit. **C'est un défaut assumé, pas une solution.**

**Objets demandés** :

```sql
alter table public.groupes
  add column if not exists couleur_jeton smallint
    check (couleur_jeton is null or couleur_jeton between 0 and 39);

comment on column public.groupes.couleur_jeton is
  'Index dans la palette administree (decision D-18). JAMAIS un hexadecimal : '
  'une couleur transportee echappe au contraste, au mode sombre et au theme. '
  'Nul = aucune couleur choisie, l''interface retombe sur l''index 0.';
```

Plus, côté client et **hors de mon périmètre** : 32 à 40 paires `AppColorPair` dans
`lib/core/theme/app_palette.dart`, contrastées en clair **et** en sombre, exposées par une méthode
`AppPalette.teinteGroupe(int index)`. C'est un lot de jetons de design, à chiffrer par Agent Z.

Et le paramètre d'écriture correspondant sur `creer_groupe` / `modifier_groupe`.

**Ne jamais oublier** : la couleur n'est **jamais** le seul identifiant du groupe. Mon interface
affiche toujours le nom à côté du liseré, et le liseré est `ExcludeSemantics` : une couleur ne se lit
pas à voix haute.

---

### 1.7 Le cours et le niveau, en langage humain

**Constat mesuré.** `programme_niveaux` (`0020:51-63`) porte bien `code_technique` **et**
`nom_humain`, avec un commentaire normatif UX. Mais **rien ne relie un groupe à un niveau** :
`public.groupes` n'a ni `nom_cours`, ni `programme_niveau_id`. Et surtout, d'après l'en-tête de `0025`
lignes 33-40, **`0020` à `0024` n'ont jamais été appliquées à cette base** : `programme_niveaux`
n'existe pas encore.

**Objets demandés**, à ordonnancer **après** l'application de `0020` :

```sql
alter table public.groupes
  add column if not exists nom_cours text,
  add column if not exists programme_niveau_id uuid
    references public.programme_niveaux(id);

comment on column public.groupes.nom_cours is
  'Nom HUMAIN du cours, affiche tel quel. Jamais un code academique interne.';
```

**Invariant à tenir dans la vue**, pas dans le client : exposer `programme_niveaux.nom_humain`, et
**jamais** `code_technique`. C'est une règle UX inscrite en commentaire SQL dans `0020`.

Si `0020` ne peut pas être appliquée dans ce lot, la même garde que `unite_curriculum()` s'impose :
`to_regclass` et un `null` franc. Mon `GroupSummaryVM.niveauHumain` est **nullable** et l'interface
gère son absence sans laisser de séparateur orphelin : ce cas est testé.

---

### 1.8 La photo et le titre de l'enseignant

**Constat mesuré.** `public.teacher_profiles` (`0001`) porte `profile_id`, `country`, `languages`,
`weekly_hours_cap`, `kyc_status`, `deleted_at`, `created_at`. **Ni photo, ni avatar, ni titre.**
`student_profiles` a bien `avatar_storage_key`, mais c'est l'élève. Les seuls seaux Storage existants
sont `kyc` et `avatars` (`0004:997-998`), tous deux privés.

La décision `D-01` rend la photo **obligatoire** pour tout enseignant actif ou assignable,
**distincte des pièces KYC**, et son absence doit déclencher un état explicite. La décision `D-02` fixe
les titres à **Sayyid / Sayyida**, jamais Ustaz.

**Objets demandés** :

```sql
alter table public.teacher_profiles
  add column if not exists photo_storage_key text,
  add column if not exists titre text
    check (titre is null or titre in ('sayyid', 'sayyida'));

comment on column public.teacher_profiles.photo_storage_key is
  'Cle Storage de la photo professionnelle PUBLIQUE de l''enseignant, dans le '
  'seau photos_enseignants. On persiste la CLE, jamais une URL signee : une URL '
  'signee expire (lecon de lib/core/appairage/service_avatar.dart:148). '
  'Distincte des pieces KYC, qui vivent dans le seau kyc et n''en sortent pas.';

insert into storage.buckets (id, name, public)
values ('photos_enseignants', 'photos_enseignants', false)
on conflict (id) do nothing;
```

Plus les policies Storage, calquées sur celles du seau `avatars` (`0004:1019-1060`) : l'enseignant
écrit dans son propre dossier ; la lecture est ouverte aux membres du groupe, à l'enseignant et à
l'administration, **par URL signée**, jamais par un seau public.

**Ce que mon interface fait, et que je documente pour qu'il ne soit pas pris pour un défaut** :

- `photoUrlOuCle == null` → état d'erreur explicite, pastille « Photo à fournir », **aucune initiale**.
  C'est `D-01`, tenu par `PhotoEnseignant` et mesuré par deux tests.
- `photoUrlOuCle != null` mais URL non résolue → `AvatarTile` avec ses initiales. Ce n'est **pas** un
  contournement de `D-01` : la photo existe, elle n'est simplement pas encore signée, parce que la
  capacité de signature n'existe pas. C'est un état de chargement. Il disparaîtra le jour où l'hôte
  passera une URL signée à `PhotoEnseignant.urlSignee`.

---

### 1.9 Rendre les conversions de fuseau — et le choix qu'il faut trancher

**Constat mesuré.** Le client **ne peut pas** convertir un fuseau IANA : `pubspec.yaml` n'a ni
`timezone`, ni `tz`, ni `flutter_timezone`, ni `intl` — vérifié. Et `pubspec.yaml` est gelé (`D-11`).
`DateTime.toLocal()` ne connaît que le fuseau de l'**appareil**, qui n'est ni celui du groupe, ni
nécessairement celui de l'utilisateur au sens de `mon_fuseau()`.

**Les deux options, honnêtement pesées.**

| | (A) Rendu serveur | (B) Dépendance cliente `timezone` + `intl` |
|---|---|---|
| Poids | 0 Mo client | ≈ 1,2 Mo de base de fuseaux embarquée, plus `intl` |
| Justesse | `instant_creneau()` est déjà corrigé sur les transitions (`0006`) | Base de fuseaux à tenir à jour par release ; un appareil jamais mis à jour dérive |
| Hors ligne | **Ne fonctionne pas sans réseau** | Fonctionne hors ligne |
| Risque `pubspec` | Nul | `D-11` rappelle que `sentry_flutter` est bloqué en 8.x pour ne pas rétrograder `path_provider_android`, **qui porte le cache Drift, donc le mode hors ligne** |
| Cohérence | Une seule vérité, celle qui décide déjà des séances | Deux vérités, client et serveur, qui peuvent diverger d'une version de tzdata |

**Ce que je recommande : (A), avec une nuance.** Le serveur convertit, le client **compose les mots**.

La raison de la nuance est concrète : `to_char()` en PostgreSQL rend les noms de mois et de jours selon
`lc_time`, qui n'est pas garanti francophone sur l'instance et n'est pas administrable depuis une
migration. Faire rendre « Lundi 21 septembre » par la base nous ferait dépendre d'un réglage de
serveur pour une chaîne d'interface — et ce serait la seule chaîne du produit à échapper à slang.

```sql
create or replace function public.horloge_seance(p_session_id uuid)
returns table (
  session_id          uuid,
  debut_utc           timestamptz,
  fin_prevue_utc      timestamptz,
  join_opens_at_utc   timestamptz,
  fenetre_minutes     int,
  grace_minutes       int,
  maintenant_utc      timestamptz,
  -- Fuseau de la personne connectee, via mon_fuseau()
  tz_utilisateur      text,
  heure_utilisateur   text,     -- 'HH24:MI', insensible a la locale
  jour_iso_utilisateur int,     -- 1..7, l'interface nomme le jour
  date_utilisateur    date,     -- l'interface nomme le mois
  -- Fuseau de reference du GROUPE, jamais celui d'un collegue
  tz_groupe           text,
  heure_groupe        text,
  jour_iso_groupe     int,
  date_groupe         date
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
    coalesce(s.join_opens_at,
             s.started_at - make_interval(mins => coalesce(
               (public.get_config('join_window_minutes'))::int, 20))),
    coalesce((public.get_config('join_window_minutes'))::int, 20),
    coalesce((public.get_config('grace_after_end_minutes'))::int, 15),
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
    -- La RLS de sessions decide de la visibilite : cette fonction ne l'elargit pas.
    and exists (
      select 1 from public.sessions v where v.id = s.id
    );
$function$;

revoke execute on function public.horloge_seance(uuid) from public, anon;
grant execute on function public.horloge_seance(uuid) to authenticated, agent_ro, service_role;
```

⚠ **Deux points qu'Agent Z doit vérifier et que je ne peux pas trancher depuis mon périmètre** :

1. `security definer` **contourne la RLS**. Le prédicat de visibilité doit être écrit explicitement
   (appartenance au groupe, tuteur du foyer, enseignant assigné, rôle admin), exactement comme
   `mon_groupe_detail()` le fait. Le `exists` ci-dessus est un **emplacement**, pas la règle.
2. `grace_after_end_minutes` n'existe pas encore dans `app_config`. La valeur de 15 minutes est
   aujourd'hui écrite en dur à deux endroits : `autoriser_jeton_video()` (`0010:309`) et
   `graceApresFin` dans `lib/core/controle/service_controle.dart`. La remonter en configuration est le
   même geste que §1.4, et il vaut mieux les faire ensemble.

**Conséquence de contrat, à arbitrer par Agent 0 ou Agent Z.**
`TEACHING_CORE_CONTRACTS.md` §3 décrit `HorlogeAffichee.dateLocaleRendue` comme « déjà converti ».
Avec l'option (A) nuancée, c'est l'**adaptateur** Dart du port qui compose « Lundi 21 septembre » à
partir de `jour_iso` et de `date`, en lisant les noms de jours et de mois dans slang. L'invariant
« **un widget ne calcule jamais une règle de fuseau** » reste entier : la conversion est faite par la
base, et le widget reçoit une chaîne. Je n'ai pas modifié le contrat ; je signale l'endroit exact où il
demande une précision.

**Si (B) est finalement retenu**, la demande de dépendance est en §2.

---

### 1.10 L'avertissement de changement d'heure

**Constat mesuré.** Rien, ni en base ni en Dart. Zéro occurrence de DST, de `pg_timezone_names` ou
d'une quelconque anticipation. La spec §5.3 demande une alerte **jusqu'à 30 jours** avant, puis des
rappels à J-7 et J-1, et un écran `Admin > Opérations > Planning` listant les groupes affectés.

**Objet demandé** :

```sql
create or replace function public.transitions_fuseau_a_venir(p_jours int default 30)
returns table (
  groupe_id        uuid,
  fuseau            text,
  transition_utc    timestamptz,
  heure_avant       text,          -- 'HH24:MI'
  heure_apres       text,
  jours_restants    int
)
language sql
stable
security definer
set search_path to ''
as $function$
  -- Detection sans table de transitions : on compare l'heure locale de
  -- l'occurrence de cette semaine a celle de la semaine suivante. Si elles
  -- different alors que le motif n'a pas bouge, une transition est passee
  -- entre les deux. C'est exactement ce que instant_creneau() sait deja faire.
  select ...
$function$;
```

Je n'écris pas le corps : la forme retenue dépend de savoir si l'on compare semaine à semaine ou si
l'on interroge `pg_timezone_names`, et c'est un arbitrage technique qui appartient à qui écrit la
migration. **Ce dont mon interface a besoin est déjà fixé par le contrat** : `NoticeDst` porte
`transitionUtc`, `fuseauConcerne`, `heureAvantRendue`, `heureApresRendue` et `echeance` (j30 | j7 | j1).
Le widget n'en calcule aucun, et c'est mesuré par un test.

---

### 1.11 Le défaut latent de T-20 — à corriger **avec** §1.4, jamais après

`D-13` le nomme et m'interdit de l'éditer. Je confirme qu'il est **toujours présent** à `0071557`, et
je le chiffre.

| Défaut | Emplacement | Effet le jour où la fenêtre passe à 20 min |
|---|---|---|
| L'état de présence bascule à `presente` dès le premier `joined`, sans comparer à `started_at` | `etat_presence()`, `0010` | Un élève entré à T-20 est compté présent vingt minutes avant le cours. **L'invariant §5.2 de la spec est violé en base**, pas à l'écran. |
| La durée en salle se compte depuis `entre_le` brut | `VuePresence.depuis`, `lib/core/presence/vue_presence.dart:70-85` : `RepereTemps.entree => maintenant.difference(origine)` où `origine = ligne.entreLe` | Un élève entré à T-20 lit « en salle depuis 38 min » pour un cours commencé il y a 18 minutes. |

**Correction demandée**, des deux côtés, en un seul geste :
borner l'origine à `greatest(entre_le, started_at)` en SQL, et à `entreLe.isBefore(debutSeance) ? debutSeance : entreLe`
dans `VuePresence.depuis`. La fonction est **pure** et déjà couverte par des tests : la modification est
mesurable sans monter un écran.

**Je n'ai touché ni l'une ni l'autre.** `vue_presence.dart` est nommément interdit à Agent A, et
`etat_presence()` est une migration.

---

## 2. DÉPENDANCE DEMANDÉE

**Aucune, si §1.9 option (A) est retenue.** C'est mon cas par défaut, et mon code compile et passe ses
tests sans aucune dépendance nouvelle.

**Si et seulement si (B) est retenu** :

| Paquet | Version | Raison | Ce qui a été essayé avant |
|---|---|---|---|
| `timezone` | `^0.10.0` | Convertir un instant UTC vers un fuseau IANA côté client, et donc rendre les horloges hors ligne. | `DateTime.toLocal()` : ne connaît que le fuseau de l'appareil, pas `groupes.timezone_iana`. Écarté. Rendu serveur : fonctionne, mais pas hors ligne. |
| `intl` | `^0.20.0` | Formater une date en français sans dépendre de `lc_time` côté serveur. | Composition manuelle depuis slang : **retenue**, et suffisante. `intl` n'est nécessaire que si l'on veut des formats longs localisés au-delà du français. |

**Mon avis, en une phrase** : `timezone` seul vaut probablement son poids le jour où la Bibliothèque
hors ligne existera ; `intl` ne le vaut pas, parce que le produit n'a qu'une langue rédigée et que
slang fait déjà le travail. À peser contre le commentaire normatif de `pubspec.yaml` sur
`path_provider_android`.

---

## 3. ICÔNES DEMANDÉES

Aucun agent n'édite `lib/core/icons/app_icons.dart` (`D-05`). J'ai employé un placeholder annoté
`// TC-ICONE:` dans le code.

| Icône souhaitée | Usage | Placeholder employé | Fichier |
|---|---|---|---|
| `tabletteOuOrdinateur` | Le conseil d'appareil de la Session Card. Un appareil « posé », distinct du téléphone. | `AppIcons.appareil` | `lib/features/tc_espace_groupe/carte_session.dart` |

C'est la seule. Les autres besoins sont couverts par le catalogue existant : `cours`, `avertissement`,
`rienAAfficher`, `succes`.

---

## 4. JETONS DE DESIGN DEMANDÉS

| Jeton | Besoin | Pourquoi il ne peut pas venir de l'existant |
|---|---|---|
| `AppPalette.teinteGroupe(int)` — 32 à 40 paires accessibles | La couleur d'identification du Groupe (`D-18`) | `app_palette.dart` est le seul fichier autorisé à poser une couleur littérale, et il est en lecture seule pour moi. Les quatre paires que je réutilise portent déjà un sens : employer `washWarning` comme couleur d'identité ferait lire une anomalie là où il n'y a qu'un groupe. |

Contraintes à tenir au moment de les poser : contraste vérifié en clair **et** en sombre, et
distinguabilité pour les trois formes courantes de dyschromatopsie — sans quoi trente-deux teintes en
valent douze.

---

## 5. ROUTES ET NAVIGATION

`routesTcA()` (`lib/features/tc_mes_groupes/routes_tc_a.dart`) **retourne** des routes et ne construit
jamais un `GoRouter`. Trois choses restent à faire à l'intégration, et deux sont des pièges.

1. **Appeler `routesTcA()` depuis `app_router.dart`** et promouvoir `CheminsTcA.mesGroupes`
   (`/tc/groupes`) et son segment enfant dans `routes.dart`.
2. **Ajuster `redirection.dart`.** C'est le piège nommé par `D-04` : `deciderRedirection()` renvoie
   toute route hors préfixe de rôle vers la racine du rôle. Posé tel quel, `/tc/groupes` est
   **inatteignable**. Le préfixe `/tc/` n'appartient à aucun rôle.
3. **Trancher l'entrée de navigation.** Une route sans entrée n'existe pas. Or `nav_shell.dart` est
   PROTECTED et **plafonné à quatre destinations par assertion**, et l'enseignant en a déjà quatre.
   Ajouter « Mes groupes » est donc un **arbitrage produit**, pas un patch : soit une destination
   remplace une autre, soit le plafond change, soit l'Espace Groupe s'atteint depuis l'accueil
   existant. **Je ne tranche pas.**

`EspaceGroupePage.role` est aujourd'hui un paramètre avec `RoleEspaceGroupe.eleve` par défaut. Agent Z
le dérive de la session applicative. ⚠ À noter : `lib/core/session/session_state.dart` documente que
`peutVoirDirection` est câblé en dur à `false` parce que ni `AppRole` (plat, 6 valeurs) ni le JWT ne
portent de permission plus fine. **Toute capacité Teaching Core qui ne serait pas un rôle entier n'a
aujourd'hui aucun support** : le rôle de l'Espace Groupe se dérivera donc de `AppRole`, pas d'une
capacité.

---

## 6. ÉCART DE CONTRAT — `ContentPosition` n'est pas compilable tel qu'écrit — ✅ **RÉPONDU, DEMANDE CLOSE**

> **Réponse reçue : AMENDEMENT 1 de `TEACHING_CORE_CONTRACTS.md`.** La section est conservée telle
> quelle — elle documente pourquoi l'écart a été signalé — mais **ce n'est plus une demande ouverte**.
> L'amendement, publié en tête du document CONTRACTS, prévaut sur les §7 et §8 et désigne le canonique :
> `lib/core/tc_bibliotheque/content_position.dart` (Agent B). Ma forme et la sienne divergeaient sur
> cinq points : `valeurSql` sur chaque membre de `TypeAncrage`, `depuisSql(String?)`, `operator ==`,
> `hashCode`, et les quatre assertions qui tiennent l'invariant « un seul ancrage à la fois ».
> **Comme annoncé ci-dessous, c'est la sienne qui prime** : mon stub a été resynchronisé et recopie
> désormais le canonique à l'identique, en-tête `TC-STUB-PORT` pointant vers ce chemin et vers
> l'AMENDEMENT 1. `ContentRange` reste non stubé, faute d'usage (position utilisée uniquement comme
> type de champ, `port_catalogue.dart`). Rien d'autre à arbitrer ici.

`TEACHING_CORE_CONTRACTS.md` §7 déclare :

```dart
const ContentPosition._();
// Constructeurs nommes attendus : .page(...), .ayah(...), .section(...), .fraction(...)
```

Recopié à l'identique, ce code **ne compile pas** : `resourceId` et `typeAncrage` sont `final` et non
nullables, et aucun constructeur ne les initialise. Le même problème frappe `ContentRange` §8, dont
`bool contient(ContentPosition p);` est une méthode sans corps dans une classe concrète.

**Ce que j'ai fait** : dans `lib/core/tc_groupe/ports_externes/content_position.dart`, j'ai matérialisé
les quatre constructeurs nommés que le contrat **annonce**, sans ajouter ni retirer un seul champ, et
j'ai écrit l'écart en tête du fichier. **Je n'ai pas stubé `ContentRange`** : il ne m'est pas
nécessaire, et l'implémenter aurait été écrire du code d'Agent B.

**Demande** : qu'Agent B publie la forme canonique, et que le contrat soit amendé pour que les huit
autres agents ne réinventent pas huit constructeurs différents. Si la forme d'Agent B diffère de la
mienne, **c'est la sienne qui prime** : mon fichier porte l'en-tête `TC-STUB-PORT` et disparaîtra à
l'intégration.

---

## 7. UN PORT QUE JE N'AI PAS STUBÉ, ET POURQUOI

`TEACHING_CORE_FILE_OWNERSHIP.md` liste `PortRosterEnseignant` (Agent E) parmi mes ports consommés.
**Je ne l'ai pas stubé, et c'est un choix que je soumets à arbitrage plutôt qu'un oubli.**

La raison est mécanique. Stuber ce port impose de copier `TeacherStudentProjection`, et avec elle
`ResumeSeance`, `AssiduiteRecente`, `EtatPresenceProjete`, `LearningAssignment` (Agent D),
`StatutAssignation`, `IntentionPedagogique`, `ContentRange` et `ContentPosition` (Agent B) — soit
environ cent quatre-vingts lignes appartenant à trois autres agents, dont deux types qui ne compilent
pas en l'état (§6). Chacune de ces lignes est une occasion de diverger, et toute divergence est un
BLOCKER au contrôle pré-merge.

**Ce que j'ai fait à la place, et qui suit le contrat à la lettre** :
`TEACHING_CORE_CONTRACTS.md` §2 dit que `SlotRoster` est une **enveloppe vide** qui « porte un
identifiant de contexte et rien d'autre », et que « le contenu est rendu par l'agent propriétaire du
port correspondant ». `BlocRoster` expose donc un paramètre `contenu` que l'hôte remplit, et
`EspaceGroupePage.contenuRoster` le fait remonter. Agent Z y branche la surface d'Agent E en une ligne,
sans que `lib/core/tc_groupe/` ait jamais connu la forme de `TeacherStudentProjection`.

**Demande** : confirmer que cette lecture est la bonne, ou me dire de stuber le port — auquel cas la
forme canonique de `ContentPosition` et de `ContentRange` (§6) devient un préalable.

Pour mémoire, les deux autres ports consommés **sont** stubés, eux, parce que leur chaîne de types est
close : `PortCatalogue` (Agent B) et `PortTravailAVenir` (Agent H).

---

## 8. Récapitulatif ordonné

| # | Demande | Nature | Bloque quoi |
|---|---|---|---|
| 1.1 | `materialiser_seances_groupe(uuid)` | RPC neuve | **Tout.** Sans elle, aucune occurrence, donc aucun compte à rebours réel. |
| 1.2 | `mes_groupes_famille_v` | Vue neuve | L'Espace Groupe côté élève et tuteur. |
| 1.4 | `join_window_minutes` + `sessions.join_opens_at` + `autoriser_jeton_video` | Config + colonne + modification | Le bouton « Rejoindre » à T-20. **Les trois ensemble, jamais séparément.** |
| 1.5 | `maintenant_serveur()` | RPC neuve | La justesse du compte à rebours. |
| 1.9 | `horloge_seance(uuid)` | RPC neuve | Les deux horloges de la Session Card. |
| 1.3 | Écriture de `timezone_iana` | Paramètre sur deux RPC | Tout groupe non parisien. |
| 1.8 | Photo et titre enseignant | Colonnes + seau | `D-01` et `D-02`. |
| 1.6 | `groupes.couleur_jeton` + palette | Colonne + jetons de design | `D-18`. |
| 1.7 | `nom_cours`, `programme_niveau_id` | Colonnes | Le cours et le niveau en langage humain. Dépend de l'application de `0020`. |
| 1.10 | `transitions_fuseau_a_venir(int)` | RPC neuve | La notice DST. |
| 1.11 | Bornage à `greatest(entre_le, started_at)` | Correction, deux endroits | **À faire en même temps que 1.4**, sinon le passage à T-20 casse la présence. |
