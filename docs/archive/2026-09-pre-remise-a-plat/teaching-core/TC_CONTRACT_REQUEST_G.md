# TC_CONTRACT_REQUEST_G.md

> Agent G — Observation & Policies. Demandes adressées à Agent Z.
> Baseline `0071557`. Aucune migration n'a été écrite : la dernière existante est `0029`,
> la première libre est `0030`, et la phase parallèle les interdit (décision D-12).

Rien dans ce lot ne fonctionne en production tant que la section **DEMANDE SQL** n'est pas appliquée.
Le code Dart est écrit contre les signatures exactes ci-dessous : il n'y a pas d'écart à combler,
seulement une migration à écrire.

---

## 1. DEMANDE SQL

### 1.0 Principe : étendre, jamais ouvrir une troisième porte

`rejoindre_observation()` (contrôleur) et `assister_seance()` (tuteur) existent depuis `0012` et
fonctionnent. L'en-tête de `0012` dit lui-même pourquoi il ne faut pas en créer une troisième :
deux portes qui refuseraient des séances différentes finiraient par se contredire.

`entrer_observation()` ci-dessous **remplace les deux appels côté client** et **réutilise leur corps** :
même fenêtre `started_at .. ended_at + 15 min`, même insertion idempotente dans
`session_participants`, même écriture `audit_logs`. Ce qu'elle ajoute, et qui n'existe nulle part
aujourd'hui, c'est la **politique, le quota et l'intervalle mesurable**.

Deux règles de sécurité du dépôt, à répéter dans la migration :

1. **Jamais `grant execute` à `agent_ro`** sur une des RPC volatiles ci-dessous. `get_advisors` ne le
   détecte pas ([[feedback_agent_ro_jamais_sur_rpc_ecriture]]).
2. Toute nouvelle vue d'exposition **répète le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne**. Le motif est dupliqué à la main dans le dépôt :
   une surface oubliée est une fuite avec une bannière devant.

---

### 1.1 Défauts Académie — `app_config`

`app_config` est déjà le magasin clé/valeur jsonb des seuils réglables sans redéploiement
(`presence.seuil_retard_secondes`, etc.). Les défauts d'observation y appartiennent.

| Clé | Type | Valeur | Origine |
|---|---|---|---|
| `observation.activee` | `boolean` | `true` | spec §11.1 |
| `observation.max_visits_per_session` | `integer` | `1` | spec §11.1 |
| `observation.max_total_seconds` | `integer` | `120` | spec §11.1 |
| `observation.max_seconds_per_visit` | `integer` | `null` | plafond facultatif |
| `observation.policy_version` | `text` | `'a1'` | bumpé à la main par l'administration |

**Ces valeurs ne sont pas dupliquées côté client.** `GuardianObservationPolicy.defautsNormatifs`
existe en Dart comme référence écrite de la spécification et comme double de test ; aucun écran ne
l'appelle, et un test le vérifierait mal — c'est une discipline, pas une barrière. Si vous voulez la
barrière, supprimez ce constructeur à l'intégration une fois la RPC en place.

### 1.2 Surcharge par groupe — colonnes sur `public.groupes`

Aucune table neuve : `groupes` est **la** table de groupe (MAPPING §9.1, « étendre, jamais recréer »),
et `rule_overrides` est scopé profil, donc inutilisable ici.

```sql
alter table public.groupes
  add column observation_source text not null default 'academie'
      check (observation_source in ('academie','groupe','desactivee')),
  add column observation_max_visites smallint,
  add column observation_max_secondes integer,
  add column observation_max_secondes_par_visite integer,
  add column observation_revision integer not null default 1;

-- Une surcharge « groupe » est complète ou n'existe pas : une moitié de surcharge
-- obligerait chaque lecteur à deviner d'où vient l'autre moitié.
alter table public.groupes add constraint groupes_observation_complete
  check (observation_source <> 'groupe'
         or (observation_max_visites is not null and observation_max_secondes is not null));

alter table public.groupes add constraint groupes_observation_bornes
  check ((observation_max_visites is null or observation_max_visites between 1 and 10)
     and (observation_max_secondes is null or observation_max_secondes between 30 and 1800));

-- L'invariant de la spec §11.1, tenu EN BASE et pas par l'écran :
-- « un plafond par visite ne contourne jamais le plafond total ».
alter table public.groupes add constraint groupes_observation_plafond_visite
  check (observation_max_secondes_par_visite is null
         or observation_max_secondes is null
         or observation_max_secondes_par_visite <= observation_max_secondes);
```

Plus un déclencheur `before update` qui incrémente `observation_revision` dès qu'une des quatre
premières colonnes change. C'est lui qui rend `policy_version` honnête : sans incrément, deux
politiques différentes porteraient la même version et le journal mentirait.

`groupes` a la RLS active et **aucune policy d'écriture** : seules les RPC écrivent. Ne pas en ajouter.

### 1.3 `public.guardian_session_visit` — l'intervalle mesurable

**Ce n'est pas un second journal d'audit.** `audit_logs` reste le journal : chaîné, lisible par
`ADM-04`, et un nouveau type d'événement y apparaît automatiquement dans les filtres. Ce qu'il ne sait
pas faire, c'est répondre à « combien de visites, combien de secondes, sous quelle version de
politique » : ces trois colonnes ne sont ni requêtables ni contraintes dans un `payload` jsonb
(MAPPING §9.5, « distinguer deux besoins »).

```sql
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
                            ('sortie_volontaire','quota_atteint','seance_terminee',
                             'revocation_serveur','deconnexion')),
  constraint guardian_visit_ordre check (left_at is null or left_at >= entered_at),
  constraint guardian_visit_rang  check (visit_number >= 1),
  unique (session_id, observateur_profile_id, visit_number)
);

create index guardian_visit_session_idx
  on public.guardian_session_visit (session_id, observateur_profile_id, entered_at);

-- Un seul intervalle ouvert par (séance, observateur) : sans cet index, deux onglets
-- ouvriraient deux intervalles et le quota compterait deux fois le même temps.
create unique index guardian_visit_ouvert_uidx
  on public.guardian_session_visit (session_id, observateur_profile_id)
  where left_at is null;
```

`duration_seconds` est **calculée en base**, jamais envoyée par le client : deux horodatages recollés
à l'écran donneraient une durée que la machine de l'observateur aurait pu choisir.

**RLS attendue** (`enable row level security`, aucune policy d'écriture) :

| Rôle appelant | `select` |
|---|---|
| l'observateur lui-même | ses propres lignes (`observateur_profile_id = auth.uid()`) |
| `app_role() = 'admin'` | tout |
| enseignant de la séance | **aucune policy directe.** Il lit par `annonces_observation()`, qui ne lui rend que les visites `guardian_observer` ouvertes. Une policy directe lui montrerait les visites incognito. |
| `agent_ro` | **aucune.** |

### 1.4 Deux valeurs de `participant_role`, et les six endroits à ne pas oublier

```sql
alter type public.participant_role add value 'admin_masked';
alter type public.participant_role add value 'admin_visible';
```

L'entrée Admin est aujourd'hui **impossible** : `rejoindre_observation()` lève `insufficient_privilege`
pour tout rôle autre que `controller`, et l'enum n'a que quatre valeurs.

**Ajouter une valeur ne suffit pas.** Il faut la porter dans les six endroits qui raisonnent déjà sur
les rôles d'observation, sinon l'administrateur sera refusé par un déclencheur écrit pour tout autre
chose — c'est exactement le défaut 2 documenté dans `0012` :

1. `guard_session_participant_cap()` — liste d'exemption : ajouter `admin_masked` **et** `admin_visible`.
2. `guard_session_overlap()` — seconde liste d'exemption, même ajout.
3. `est_observateur_masque()` — ajouter `admin_masked` (pas `admin_visible`).
4. Les **quatre surfaces d'invisibilité** fermées par `0012` (`presence_seance_v`, `session_peers_v`,
   et les deux policies de `session_participants`) — ajouter `admin_masked` partout où
   `masked_controller` figure. Le motif est dupliqué à la main : **une surface oubliée est une fuite
   avec une bannière devant.**
5. `autoriser_jeton_video()` — dérivation des capacités, voir §1.5.
6. `RoleSalle.depuis()` (`lib/features/salle/vue_salle.dart`, PROTECTED) — sans quoi l'administrateur
   tombe sur `RoleSalle.inconnu`, donc une salle en lecture seule. Le repli est volontairement le plus
   fermé : c'est correct, mais il faut le compléter. **Édition d'Agent Z, pas de la mienne.**

### 1.5 `autoriser_jeton_video()` — les capacités, et la borne du budget

**C'est la demande la plus importante de ce lot.** La spec §11.4 dit « le client ne peut pas prolonger
sa visite en modifiant un timer » : la seule façon de le tenir est que le **jeton lui-même** expire au
bout du budget restant.

| `role` | `can_publish` | `can_publish_video` | `can_publish_data` | `hidden` | `ttl_seconds` |
|---|---|---|---|---|---|
| `guardian_observer` | `false` | `false` | `false` | `false` | **`least(video_config.token_ttl_seconds, restant_secondes)`** |
| `admin_masked` | `false` | `false` | `false` | **`true`** | défaut |
| `admin_visible` | `true` | `true` | `false` | `false` | défaut |
| `masked_controller` | inchangé | inchangé | inchangé | inchangé | inchangé |

Et, **avant d'émettre quoi que ce soit** pour un `guardian_observer` : refuser si
`budget_observation(p_session_id)` rend `peut_entrer = false`. Le contrôle de quota **précède** le
jeton ; un jeton d'abord et un quota ensuite a déjà laissé entrer.

`admin_visible` publie voix et image mais **pas** le canal de données : `can_publish_data` reste
l'outil pédagogique de l'enseignant, et une administration qui pourrait tourner la page du Coran
piloterait le cours sans le donner.

Le nom affiché d'un `admin_visible` doit être l'identité institutionnelle **« Administration Rewayah »**,
posée côté serveur dans l'identité LiveKit. Pas le prénom de la personne : c'est l'institution qui
entre, pas quelqu'un.

### 1.6 Les six fonctions

Toutes `security definer`, `search_path` verrouillé, `grant execute to authenticated` **et jamais à
`agent_ro`**.

```sql
-- stable. Résolution académie -> groupe -> désactivation, en UN seul endroit,
-- sur le modèle de regle_effective(). Jamais recalculée à l'écran.
create function public.politique_observation_effective(p_groupe_id uuid)
returns jsonb;
-- { policy_version: text, source: 'academie'|'groupe'|'desactivee',
--   observation_activee: bool, max_visits_per_session: int,
--   max_total_observation_seconds: int, max_seconds_per_visit: int|null }

-- stable. La vérité du budget. `restant_secondes` inclut l'intervalle OUVERT
-- (now() - entered_at), sans quoi un observateur qui ne sort jamais ne consommerait rien.
create function public.budget_observation(p_session_id uuid)
returns jsonb;
-- { policy_version: text, visites_utilisees: int, visites_max: int,
--   temps_consomme_secondes: int, temps_total_max_secondes: int,
--   restant_secondes: int, peut_entrer: bool,
--   motif_refus: 'policy_desactivee'|'quota_visites_atteint'|'temps_epuise'
--               |'lien_tuteur_absent'|'seance_non_active'|'hors_fenetre'|null }

-- volatile. L'ordre des vérifications EST la garantie :
-- 1. la séance existe et est dans la fenêtre  -> 'seance_non_active' / 'hors_fenetre'
-- 2. l'appelant a le droit de tenir p_role    -> insufficient_privilege
-- 3. lien tuteur-enfant dans CE groupe        -> 'lien_tuteur_absent'
-- 4. politique du groupe                      -> 'policy_desactivee'
-- 5. quota (visites ET temps)                 -> 'quota_visites_atteint' / 'temps_epuise'
-- 6. ALORS SEULEMENT : insert session_participants + insert guardian_session_visit
--    + log_sensitive_access, y compris pour un rôle incognito.
create function public.entrer_observation(p_session_id uuid, p_role text)
returns jsonb;
-- { autorise: bool, motif_refus: text|null, visite: {...}|null, budget: {...}|null }

-- volatile. Ferme l'intervalle ouvert (left_at = now(), fin_de_visite),
-- idempotente, et écrit l'événement de sortie comme quitter_salle().
create function public.sortir_observation(p_session_id uuid)
returns jsonb;

-- stable. L'observateur lui-même et l'admin. Pour l'audit.
create function public.visites_observation(p_session_id uuid)
returns jsonb;   -- tableau de visites

-- stable. RÉSERVÉE À L'ENSEIGNANT DE LA SÉANCE.
-- Ne rend QUE les intervalles ouverts de rôle 'guardian_observer'.
-- Une ligne incognito qui apparaîtrait ici cesserait d'être incognito.
-- Rend un PRÉNOM et des SECONDES, jamais une phrase : le français se fabrique en Dart.
create function public.annonces_observation(p_session_id uuid)
returns jsonb;   -- [{ enfant_prenom: text, enfant_profile_id: uuid, restant_secondes: int }]

-- volatile, [admin]. Écrit la surcharge du groupe, bumpe la révision, audite.
create function public.definir_politique_observation_groupe(
  p_groupe_id uuid, p_source text,
  p_max_visites smallint, p_max_secondes integer)
returns jsonb;
```

### 1.7 Fermeture serveur des intervalles restés ouverts

Un onglet fermé n'annonce rien. `sortir_observation()` ne doit donc pas être la seule fermeture :
il faut que le serveur referme, sans rien attendre du client. Deux voies, au choix d'Agent Z :

- le **webhook LiveKit** (`enregistrer_webhook_livekit`) ferme l'intervalle sur l'événement
  `participant_left`, avec la même déduplication de 30 s que `quitter_salle` ;
- ou `budget_observation()` **traite tout intervalle ouvert depuis plus que le TTL du jeton comme
  clos** au moment du calcul. Moins exact sur la trace, mais suffisant pour le quota, et sans
  dépendance au webhook.

Sans l'une des deux, un tuteur qui ferme son onglet consommerait son quota indéfiniment — ou pas du
tout, selon la voie choisie. C'est un arbitrage, il doit être pris.

---

## 2. AMENDEMENTS DE CONTRAT

### 2.1 `ModeEntreeAdmin` n'a pas de signature dans `TEACHING_CORE_CONTRACTS.md`

`TEACHING_CORE_FILE_OWNERSHIP.md` §2 me l'attribue comme contrat produit, mais `CONTRACTS.md` ne le
décrit nulle part — ni en §13, ni en §14, ni dans le récapitulatif §17. Je l'ai donc publié, et voici
la signature à inscrire au contrat. **Chemin canonique : `lib/core/tc_observation/mode_entree_admin.dart`.**

```dart
enum ModeEntreeAdmin {
  observerDiscretement(RoleObservateur.adminIncognito),
  rejoindreLaClasse(RoleObservateur.adminVisible);
  const ModeEntreeAdmin(this.role);
  final RoleObservateur role;
  bool get visible;        // rejoindreLaClasse seulement
  bool get annonceFaite;   // == visible
}
```

Le même fichier porte `CapaciteObservation` et `ProfilObservateur`, qui ne sont **pas** des contrats
inter-agents : ils servent à ne pas proposer à l'écran une commande que le jeton refuserait, et à
rendre visible un écart entre le jeton et le produit. Si Agent 0 préfère les garder hors contrat,
rien ne change pour les autres agents.

### 2.2 `BudgetObservation` ne porte pas l'instant de sa mesure — et c'est acceptable

Le compte à rebours a besoin de savoir **quand** le budget a été mesuré. Je **n'ai pas ajouté de champ**
au contrat : le client relève lui-même l'instant de réception (`recuA`) et
`VueBudgetObservation.depuis` borne le résultat à la valeur serveur, de sorte qu'une horloge reculée
ne rend aucune seconde.

Un champ `mesureAUtc` au contrat serait plus propre — il permettrait de détecter une dérive d'horloge
plutôt que de seulement l'annuler. **Ce n'est pas une demande bloquante.** Si Agent 0 l'ajoute, mon
code le consomme sans changer de forme.

---

## 3. ICÔNES DEMANDÉES

`lib/core/icons/app_icons.dart` est un catalogue unique et la CI refuse tout `IconData` posé ailleurs
(décision D-05). Cinq icônes manquent ; en attendant, j'emprunte au catalogue et j'annote chaque
emprunt d'un `// TC-ICONE:` dans le code.

| Souhait | Emprunt actuel | Où |
|---|---|---|
| `observation-incognito` | `AppIcons.controleQualite` | `choix_entree_observation.dart` |
| `administration-visible` | `AppIcons.camera` | `choix_entree_observation.dart` |
| `heritage` | `AppIcons.reglages` | `module_reglages_observation.dart` |
| `personnalisation-groupe` | `AppIcons.foyer` | `module_reglages_observation.dart` |
| `observation-fermee` | `AppIcons.cameraCoupee` | `module_reglages_observation.dart` |

Aucune n'est bloquante : les emprunts sont lisibles, ils sont seulement imprécis.

---

## 4. ROUTES ET ENTRÉES DE NAVIGATION

`routesTcG()` (`lib/features/tc_observation_ui/routes_tc_g.dart`) retourne **une** route,
`/tc/observation/:seanceId`. Elle ne construit aucun `GoRouter`.

Trois branchements sont nécessaires, et le premier est le seul qui soit vraiment bloquant :

1. **`redirection.dart`** — sans ajustement, toute route hors préfixe de rôle est redirigée vers la
   racine du rôle : l'écran serait **inatteignable**. `/tc/observation/...` doit être autorisée pour
   `guardian`, `admin` et `controller`.
2. **Entrées existantes, à rediriger vers la route plutôt qu'à dupliquer** :
   - tuteur : `lib/features/accueil_famille/accueil_famille_page.dart`, `_assister(seanceId)` (~ligne 178)
     appelle aujourd'hui `ServiceVideo.assisterEnTuteur` **sans quota et sans journal**. Il doit
     naviguer vers `RoutesTcG.versObservation(seanceId)`.
   - contrôle qualité : `lib/features/controleur/planning_page.dart`, le bouton « Observer » d'une
     ligne en cours. Même redirection. CTR-01 reste inchangé par ailleurs : je l'ai consommé, pas refait.
3. **Administration** : aucune entrée n'existe aujourd'hui. C'est un **arbitrage produit**, pas un
   patch : `nav_shell.dart` est protégé et plafonné à quatre destinations par assertion. L'endroit le
   plus naturel est une action sur la séance depuis le domaine Opérations, mais je ne la pose pas.

Le **module de réglages n'a pas de route, et c'est voulu** (consigne explicite du chantier). Il se
branche dans « Groupe > Réglages ». `ongletsConfiguration()` ne doit **pas** le lister tant qu'il n'a
pas de route réelle : une entrée qui échoue au clic est exactement ce que l'audit Admin interdit.

---

## 5. DÉPENDANCE DEMANDÉE

**Aucune.** Tout tient avec `flutter_riverpod`, `supabase_flutter`, `go_router` et le thème existant.
`pubspec.yaml` n'a pas été ouvert.

---

## 6. CE QUE JE N'AI PAS DEMANDÉ, ET POURQUOI

- **Aucun neuvième domaine Admin.** `admin_domaine.dart` est gelé à huit, règle absolue.
- **Aucun second journal chaîné.** `audit_logs` reste le journal ; `guardian_session_visit` est une
  table de mesure, pas de trace.
- **Aucune extension de `jetons_agent`.** Ces jetons servent aux agents IA. Leurs **règles** (durée
  plafonnée par `CHECK`, compteur d'usage serveur, aucune prolongation côté client) sont le bon
  modèle et je les ai copiées ; la table, non.
- **Aucun stub de port externe.** Voir le rapport, §« Ports consommés ».
- **Aucune correction du défaut `0029`** signalé par le `BASELINE_ADDENDUM` (migration écrite mais non
  appliquée, `dossiers_en_attente()` exposée à un appelant anonyme). Hors mission, signalé, pas touché.
