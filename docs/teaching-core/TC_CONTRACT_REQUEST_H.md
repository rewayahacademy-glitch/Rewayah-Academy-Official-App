# TC_CONTRACT_REQUEST_H.md

> Agent H, Academic Flow. Baseline `0071557`.
> Ce qui manque au lot H pour cesser d'etre un double local, et la forme exacte attendue.
> Rien ici n'a ete contourne : chaque manque est reste un manque, avec un double declare en face.

---

## 0. Resume : ce qui bloque, par ordre de cout

| # | Manque | Consequence aujourd'hui | Qui le leve |
|---|---|---|---|
| 1 | Table `session_feedback` et cadence d'echantillonnage | `FeedbackMemoire` est un double en memoire, le provider echoue en production | Agent Z (SQL) |
| 2 | Table `student_concern` | `SignalementMemoire` est un double en memoire, le provider echoue en production | Agent Z (SQL) |
| 3 | Persistance de la position de reprise **par groupe** | « Reprendre le cours » n'apparait jamais, le post-cours ne propose aucune position | Agent Z (SQL) + Agent F |
| 4 | `SourceContenuSeance` n'a pas d'adaptateur vers `PortEtatPartage` | `rangesTravailles` est toujours vide, donc `travailPropose` aussi | Agent Z (wiring) |
| 5 | `PortAssignations.aVenir` ne filtre pas par eleve | Le bloc peut afficher moins de trois actions pour un eleve donne | Agent D (contrat) |
| 6 | `PortPostCours.enregistrer` rend `void` | L'ecran ne peut pas distinguer « envoye » de « en file » par le contrat seul | Agent 0 / Agent Z (contrat) |
| 7 | `TendanceFeedback` n'a pas de `questionId` | Cinq volets differents sont agreges dans une seule repartition | Agent 0 (contrat) |

---

## 1. DEMANDE SQL

**Migration `0030` ou au-dela. Aucun agent de la phase parallele ne l'ecrit** (decision `D-12`).

Les deux regles de securite a repeter dans chaque objet cree :

1. **Jamais `grant execute` a `agent_ro` sur une RPC volatile ou d'ecriture.** `get_advisors` ne le
   detecte pas. Les trois RPC demandees ci-dessous sont **volatiles** : aucune ne doit etre accordee a
   `agent_ro`.
2. **Toute nouvelle vue d'exposition repete le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne.** Le motif est duplique a la main dans le depot, et
   une surface oubliee est une fuite avec une banniere devant.

### 1.1 `public.session_feedback` — le micro-feedback

**Table neuve.** Aucun equivalent : zero occurrence de `feedback` dans `0001` a `0029`.
`matching_requests` porte la forme « demande -> decision -> audit », pas celle d'un vote anonyme, et
`0022_progression_suivi.sql` (lignes 5-12) **interdit explicitement** de l'etendre avec des clefs
pedagogiques.

```sql
create table public.session_feedback (
  id            uuid primary key default gen_random_uuid(),
  session_id    uuid not null references public.sessions(id) on delete cascade,
  groupe_id     uuid not null references public.groupes(id) on delete cascade,
  question_id   text not null,          -- 'cours' | 'comprehension' | 'rythme' | 'technique' | 'confiance'
  reponse       text not null check (reponse in ('difficile', 'bien', 'tres_bien')),
  soumis_le     timestamptz not null default now(),
  -- Empreinte NON REVERSIBLE de l'auteur, pour empecher un second vote, jamais pour le nommer.
  auteur_empreinte bytea not null,
  constraint session_feedback_un_seul_vote unique (session_id, auteur_empreinte)
);
```

**Le point dur, et il n'est pas negociable.** La spec interdit que l'enseignant lise « tel eleve m'a
mis telle note ». Une colonne `auteur_profile_id` tiendrait cette promesse par une policy, c'est-a-dire
par une ligne de SQL qu'un futur lot pourrait assouplir sans s'en rendre compte. L'empreinte
(`digest(session_id::text || auth.uid()::text || <sel serveur>, 'sha256')`) tient la meme promesse
**par construction** : le serveur peut refuser un second vote sans pouvoir remonter a l'auteur. Le sel
vit dans `app_config`, jamais dans le code client.

Si l'operateur prefere la colonne nominative, **la demande devient : la vue de lecture enseignant ne la
delivre pas**, et le motif `agent_identite_masquee()` s'applique colonne par colonne. Le lot H ne
tranche pas seul un arbitrage de confidentialite.

RLS attendue :

- `insert` : l'eleve ou le tuteur d'un membre du groupe, **et seulement sur une seance a laquelle il a
  participe** (jointure `session_participants`, comme `0012` le fait deja pour `assister_seance`).
- `select` : **personne**, hors `admin`. L'enseignant ne lit **jamais** cette table : il lit la vue
  agregee ci-dessous.

### 1.2 `public.tendance_feedback_v` — l'agregat, et le seuil en base

```sql
create view public.tendance_feedback_v
  with (security_barrier = true) as
select f.groupe_id,
       count(*)                                           as nombre_echantillons,
       count(*) filter (where f.reponse = 'difficile')    as n_difficile,
       count(*) filter (where f.reponse = 'bien')         as n_bien,
       count(*) filter (where f.reponse = 'tres_bien')    as n_tres_bien
  from public.session_feedback f
  join public.groupes g on g.id = f.groupe_id
 where g.teacher_id = auth.uid() or public.app_role() = 'admin'
 group by f.groupe_id
having count(*) >= public.app_config_int('feedback_seuil_tendance', 5);
```

**Le seuil est applique par la base, pas par l'ecran.** Un seuil tenu cote client serait contourne par
la premiere requete PostgREST ecrite a la main. `having` fait disparaitre la ligne entiere sous le
seuil : l'enseignant ne lit meme pas le compte.

⚠ `security_barrier` **sans** `security_invoker`, comme `teacher_roster_v` : la vue s'execute en owner
et se borne elle-meme par `where`. C'est le motif du depot ; `0011_presence_bornee.sql` documente ce
qui arrive quand on l'oublie.

### 1.3 `public.doit_demander_feedback(p_session_id uuid)` — l'echantillonnage

RPC **volatile**, `security definer`, **jamais accordee a `agent_ro`**.

```sql
-- Rend NULL quand il ne faut rien demander, sinon le contexte de la question.
-- Retour : (groupe_id uuid, rang_seance int, deja_repondu boolean)
```

Trois faits que le client ne peut pas calculer : le groupe de la seance, le **rang** de cette seance
pour l'appelant, et s'il a deja repondu. Ils alimentent exactement
`ContexteSeanceFeedback` (`lib/core/tc_parcours/feedback_memoire.dart`).

Cles `app_config` attendues, sur le modele des trois seuils de presence deja en place :

| Cle | Defaut | Sens |
|---|---|---|
| `feedback_cadence_seances` | `4` | Une seance sur N est echantillonnee. `0` eteint le feedback. |
| `feedback_seuil_tendance` | `5` | En dessous, aucune tendance n'est montree a l'enseignant. |

### 1.4 `public.student_concern` — le signalement structure

**Table neuve.** La **forme** a reprendre est celle de `matching_requests` (`0005`) : demande,
decision d'administration, ecriture d'audit. **Pas la table elle-meme**, interdiction explicite de
`0022`.

```sql
create type public.concern_category as enum
  ('pedagogique', 'presence', 'technique', 'changement', 'autre');
create type public.concern_status   as enum ('ouvert', 'en_examen', 'transmis', 'clos');
create type public.concern_target   as enum ('tuteur_du_mineur', 'eleve_adulte');

create table public.student_concern (
  id               uuid primary key default gen_random_uuid(),
  categorie        public.concern_category not null,
  groupe_id        uuid not null references public.groupes(id) on delete cascade,
  session_id       uuid     references public.sessions(id) on delete set null,
  student_id       uuid not null references public.profiles(id) on delete cascade,
  teacher_id       uuid not null references public.profiles(id) on delete cascade,
  internal_details text not null check (length(btrim(internal_details)) > 0),
  family_summary   text,                       -- NULLABLE, et c'est le cas normal
  statut           public.concern_status not null default 'ouvert',
  cree_le          timestamptz not null default now(),
  transmis_le      timestamptz,
  transmis_a       public.concern_target,
  -- Rien ne part a la famille sans un message ecrit POUR elle.
  constraint student_concern_transmission_coherente
    check (transmis_le is null or family_summary is not null)
);
```

**`internal_details` et `family_summary` sont deux colonnes, et la contrainte le dit.** Un champ unique
avec un drapeau de visibilite finirait par fuir : il suffirait d'un `select *` dans une vue famille.

RLS attendue :

- `insert` : l'enseignant du groupe (`groupes.teacher_id = auth.uid()`).
- `select` enseignant : **ses propres signalements**, `internal_details` compris.
  ⚠ Ne pas reproduire le defaut de `lesson_reports_teacher_write` (voir section 6).
- `select` admin : tout.
- `update` du statut et de la transmission : **`admin` seulement**.
- **Aucune policy famille sur cette table.** Ce que la famille lit passe par la vue ci-dessous, qui ne
  delivre pas `internal_details`.

```sql
create view public.concern_famille_v
  with (security_barrier = true) as
select c.id, c.categorie, c.family_summary, c.transmis_le, c.transmis_a
  from public.student_concern c
 where c.statut = 'transmis'
   and c.family_summary is not null
   and (public.est_du_foyer(c.student_id) or c.student_id = auth.uid());
-- internal_details, teacher_id, session_id et groupe_id sont ABSENTS, colonne par colonne.
```

Miroir Dart deja ecrit : `ResumeFamilleSignalement.versJson()`
(`lib/core/tc_parcours/student_concern.dart`). Le test
`test/teaching_core/h/signalement_test.dart` verifie sur la charge utile exacte qu'aucun mot de la note
interne n'en fait partie.

### 1.5 La position de reprise **par groupe**

C'est le manque n°3, et il est **transversal** : Agent F persiste (ou non) `SharedContentState` **par
seance**, alors que la reprise est un fait **du groupe** qui survit a la seance qui l'a produite
(invariant `D-19`, « le Groupe est permanent, la Classe Live est temporaire »).

Deux formes possibles, a arbitrer par Agent Z avec Agent F :

**(a) une colonne sur la persistance d'Agent F**, plus une lecture par groupe :

```sql
-- Sur la table de persistance de SharedContentState demandee par Agent F :
--   group_resume_position jsonb  -- { resource_id, type_ancrage, page|sourate+ayah|section_id }
create function public.derniere_position_groupe(p_groupe_id uuid)
returns jsonb language sql stable security definer as $$ ... $$;
```

**(b) une table dediee `public.groupe_position_reprise`** (`groupe_id` unique, `resource_id`,
`position jsonb`, `maj_le`, `maj_par`), ecrite a la cloture du post-cours.

Le lot H n'a besoin **que de la lecture**. `SourceContenuSeance.repriseDeGroupe(groupeId)` en est la
signature cote Dart, et `ContenuSeanceIndisponible` est le double qui rend `null` en attendant.

⚠ **Invariant J2 a ne pas casser** : `student_reading_position` est la position **de l'eleve**, et une
page tournee par l'enseignant pour tout le groupe ne doit **jamais** l'ecrire. La position de groupe est
un stockage **distinct**. Le commentaire est deja inscrit dans `0007`.

---

## 2. AMENDEMENTS DE CONTRAT DEMANDES

### 2.1 `PortAssignations.aVenir` : un filtre par eleve

**Proprietaire : Agent D.** Signature actuelle :

```dart
Future<List<LearningAssignment>> aVenir({required String groupId, int limite = 3});
```

Signature demandee :

```dart
Future<List<LearningAssignment>> aVenir({
  required String groupId,
  String? studentId,          // null = le groupe entier, comme LearningAssignment.studentId
  int limite = 3,
});
```

**Pourquoi.** `PortTravailAVenir.avantProchainCours` recoit un `studentId` et doit rendre au maximum
trois actions **pertinentes pour cet eleve**. Faute de filtre en amont, le lot H demande trois lignes
puis retire celles qui visent un autre eleve : la liste peut donc en compter moins de trois alors que
le groupe en porte assez. Le defaut est **declare et teste**
(`test/teaching_core/h/travail_a_venir_test.dart`, « le travail nominatif d un autre eleve ne s affiche
pas »).

### 2.2 `PortPostCours.enregistrer` : dire ce qu'il est advenu

**Proprietaire : le lot H lui-meme, mais le contrat est fige.** Signature actuelle :

```dart
Future<void> enregistrer(PostCoursVM saisie);
```

Signature demandee :

```dart
Future<SortPostCours> enregistrer(PostCoursVM saisie);
enum SortPostCours { envoye, enFile }
```

**Pourquoi.** Hors ligne, le compte rendu part en file et l'ecran doit ecrire « il partira des le retour
du reseau » plutot que « envoye ». Le lot H n'a **pas** modifie le contrat : il a ajoute la methode
`PostCoursDepuisCahier.deposer`, qui rend le `SortCahier` existant du chantier enseignant, et
`enregistrer` la delegue en jetant le resultat. `PanneauPostCours` teste le type de l'implementation
pour choisir la surface riche -- c'est un pis-aller, et il disparait avec cet amendement.

### 2.3 `TendanceFeedback` : par question, ou pas du tout

**Proprietaire : Agent 0.** Le contrat (section 15) donne :

```dart
class TendanceFeedback {
  final String groupeId;
  final int nombreEchantillons;
  final int seuilMinimum;
  final bool visibleParEnseignant;
  final Map<ReponseFeedback, double>? repartition;
}
```

La spec exige cinq volets en rotation. L'agregat, lui, n'a **aucun axe de question** : « rythme trop
rapide » et « cours difficile » tombent dans la meme case `difficile`. La tendance rendue est donc une
**tonalite generale**, pas une mesure par volet.

Deux issues possibles :

- **(a)** ajouter `final String? questionId;` et rendre une tendance **par question** au-dessus du
  seuil, chaque volet comptant ses propres echantillons ;
- **(b)** assumer la tonalite generale et l'ecrire dans le contrat, pour qu'aucun ecran ne presente
  l'agregat comme une note sur un volet precis.

Le lot H a implemente **(b)** parce que c'est ce que le contrat dit, et l'a declare dans son rapport.

### 2.4 Lecture de l'etat partage **par groupe**

**Proprietaire : Agent F.** `PortEtatPartage` raisonne par `sessionId` :

```dart
Future<SharedContentState?> etatCourant(String sessionId);
Future<SharedContentState?> restaurer(String sessionId);
```

Le lot H a besoin d'une lecture **par groupe**, hors seance, pour l'action contextuelle « Reprendre le
cours ». Deux formes acceptables : une methode de plus sur `PortEtatPartage`
(`Future<ContentPosition?> repriseDeGroupe(String groupeId)`), ou l'adaptateur d'Agent Z au-dessus de
la RPC demandee en 1.5. Le lot H n'a **pas** ajoute la methode au stub : il a expose
`SourceContenuSeance`, dans son propre namespace, conformement a l'AMENDEMENT 2.

---

## 3. WIRING ATTENDU D'AGENT Z

Aucun des quatre ports du lot H n'a de provider fonctionnel : tous echouent avec un message qui dit
quoi composer. C'est un choix -- un double en memoire rendu en production ferait croire a une collecte,
a un signalement ou a une cloture qui n'ont pas eu lieu.

| Provider | A composer avec |
|---|---|
| `portFeedbackProvider` | l'implementation Supabase de 1.1 a 1.3, ou `FeedbackMemoire` en recette |
| `portSignalementProvider` | l'implementation Supabase de 1.4, ou `SignalementMemoire` en recette |
| `portTravailAVenirProvider` | `TravailAVenir(portAssignations (D), adaptateur SourceContenuSeance)` |
| `portPostCoursProvider` | `PostCoursDepuisCahier(serviceEnseignant, soumissionCahier, portRosterEnseignant (E), SourceContenuSeance, portAssignations (D), profilEnseignantId)` |

Et un adaptateur a ecrire, de dix lignes :

```dart
class ContenuSeanceDepuisEtatPartage implements SourceContenuSeance {
  // positionDeReprise  -> PortEtatPartage.restaurer(sessionId)?.contentPosition
  // rangesTravailles   -> [ ...restaurer(sessionId)?.contentRange ]  (ou l'historique si F le garde)
  // repriseDeGroupe    -> la RPC de la section 1.5
}
```

**Aucune route n'est demandee.** Le lot H ne produit aucun ecran : ses quatre surfaces remplissent des
slots que d'autres possedent. Voir le rapport, section « Ou brancher ».

---

## 4. ICONES DEMANDEES

**Aucune.** Les quatre surfaces du lot H n'utilisent ni `IconData` ni `Icons.` : les etats se disent
par des mots, et `StatusPill` refuse par construction une pastille sans libelle (invariant J7).

## 5. DEPENDANCE DEMANDEE

**Aucune.** `uuid` est deja au `pubspec.yaml` et deja employe par `FileRapports`. Aucun renderer,
aucun paquet de date, aucun moteur de sondage.

---

## 6. DEFAUTS PRE-EXISTANTS CONSTATES, NON CORRIGES

Hors mission. Signales, pas touches.

1. **`lesson_reports_teacher_write` (0001:1064-1069) ne verifie pas que `session_id` appartient a
   l'enseignant**, seulement `author_profile_id = auth.uid()`. Un enseignant peut donc deposer un
   cahier sur la seance d'un autre. Le lot H **ecrit dans cette table** par `SoumissionCahier` : il
   herite du defaut sans l'aggraver. La policy de `student_concern` demandee en 1.4 ne doit pas le
   reproduire. Deja note par la cartographie (EXISTING_MAPPING section 6).
2. **`supabase/migrations/0029` est ecrite mais pas appliquee** (BASELINE_ADDENDUM) : en l'etat,
   `dossiers_en_attente()` livre nom et prenom de toute personne en attente de KYC a un appelant
   anonyme. Sans rapport avec le lot H, mais c'est le defaut le plus grave de la baseline.
3. **`tool/verifier_jetons.dart` est rouge sur la baseline `0071557`** : 10 violations, toutes
   pre-existantes (5 M-dash dans des commentaires, 1 `IconButton` et 2 `onTap` nus dans
   `core/widgets/nav_shell.dart` et `sous_navigation_domaine.dart`). **Zero violation dans les fichiers
   du lot H.** Liste complete dans le rapport.
4. **`PostCoursVM.participants` est vide tant qu'Agent E n'a pas sa projection serveur.** Ce n'est pas
   un defaut du lot H : `groupe_membres` ne porte que `student_id` et la jointure vers `profiles` est
   fermee a l'enseignant par la RLS. La demande est celle d'Agent E, section 1 de son propre
   CONTRACT_REQUEST. Le lot H la consomme, il ne la double pas.
5. **`lib/features/presence_correction/` : l'ecran existe, l'adaptateur manque** et la page n'est
   enregistree dans aucune route. Le lot H ne l'a ni reecrit ni branche : la correction de presence
   n'appartient pas au flux academique, elle appartient a la presence. Rappele ici parce que la
   cartographie le demandait expressement.
