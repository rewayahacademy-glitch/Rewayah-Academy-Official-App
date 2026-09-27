# TC_CONTRACT_REQUEST_E.md — Agent E, Classroom Shell

> Ce qui manque à la Classe Live pour être complète, chiffré et signé.
> Rien de ce qui suit n'a été contourné : chaque manque est doublé localement,
> et le double **dit** qu'il est un double.
>
> Baseline : `0071557`. Dernière migration existante : `0029`. La prochaine libre
> serait `0030` — **et aucune migration n'a été écrite** (décision D-12).

---

## 1. DEMANDE SQL — la projection pédagogique de l'enseignant

`TeacherStudentProjection` (contrat §12) compte treize champs. **Quatre seulement
sont servis aujourd'hui**, et c'est mesuré, pas supposé.

| Champ du contrat | Source réelle | État |
|---|---|---|
| `firstName`, `academyId`, `level` | vue `teacher_roster_v` (0001:650, recréée 0005:705, 0014:868) | **Sert** — branchée par ce lot, elle n'avait aucun consommateur Dart |
| `liveStatus` | `presence_seance_v` → `EtatPresence` → projection | **Sert** |
| `curriculumPath`, `currentUnit`, `activeGoals` | rien — tout le domaine Pédagogie (0020-0024) est `app_role() = 'admin'` | **Manque** |
| `resumePoints` | `student_reading_position` (0007:98) — policies 0007:351-370 : élève, foyer guardian/admin, admin. **Aucune branche enseignant** | **Manque** |
| `recentAttendance` | `presence_seance_v` + `ServiceSuivi` + `SortDuCours` | **Existe, non branché par ce lot** (voir limites du rapport) |
| `currentAssignments` | rien — table `learning_assignment` inexistante (Agent D) | **Manque** |
| `authorizedPedagogicalNotes` | `lesson_reports.content` est un `jsonb` libre, **lisible par son seul auteur** (0001:1074) | **Manque** |
| `interfaceGuidee` | `student_profiles.interface_mode` — `student_profiles` n'accorde **aucune** policy `select` à l'enseignant | **Manque** |

### 1.1 Objet demandé : `create or replace view public.teacher_roster_v`

**On étend la vue existante, on n'en crée pas une neuve.** Elle est déjà bornée
`teacher_id = auth.uid()`, `security_barrier`, sans `security_invoker`, et
`last_name` en a été **volontairement retiré en 0005** (ADR-008, défaut 3.8).
Recréer une vue à côté recréerait le défaut.

```sql
-- Colonnes ACTUELLES, a conserver a l'identique, nom et type :
--   session_id uuid, student_id uuid, first_name text, immutable_id text,
--   level text, riwaya text
-- Colonnes DEMANDEES :
--   interface_mode  public.interface_mode  -- 'child' | 'standard', voir 1.4
--   curriculum_path text                   -- nom HUMAIN, jamais code_technique
--   current_unit    text                   -- nom HUMAIN
--   active_goals    text[]                 -- au plus 3, deja ordonnes
--   resume_page     smallint               -- student_reading_position.page_mushaf
--   resume_sourate  smallint
--   resume_verset   smallint
```

**Ce qui ne doit PAS y entrer, et c'est le point le plus important :** ni
`last_name`, ni initiale, ni téléphone, ni e-mail, ni adresse, ni identité de
tuteur, ni `household_id`, ni paiement, ni géolocalisation, ni identifiant
d'appareil. Aucune de ces colonnes n'existe aujourd'hui dans `profiles` ou
`student_profiles` (grep sur 0001→0029, hors 0013) : la demande ne doit pas être
l'occasion de les introduire.

Les deux règles de sécurité à répéter dans l'implémentation :

1. **Jamais `grant execute` à `agent_ro`** sur une RPC volatile ou d'écriture —
   `get_advisors` ne le détecte pas ;
2. toute vue d'exposition **répète le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne** : le motif est dupliqué à la
   main dans le dépôt, et une surface oubliée est une fuite avec une bannière
   devant.

### 1.2 Objet demandé : `public.groupe_roster_enseignant(p_groupe_id uuid)`

**Rôle appelant :** `app_role() = 'teacher'`, et **seulement** l'enseignant
assigné au groupe (`groupes.teacher_id = auth.uid()`).
**Table étendue :** `groupe_membres` (0017, durcie 0019), jointe à `profiles` et
`student_profiles` **à l'intérieur de la fonction** `security definer`.
**Colonnes rendues :** exactement celles de `teacher_roster_v` après 1.1, sans
`session_id`.

> **Ne jamais ouvrir `groupe_detail()` à l'enseignant.** Elle est admin-only dans
> son corps et rend `student_nom` : l'ouvrir serait un contournement d'ADR-008.
> La variante enseignant se construit **sur le modèle de `teacher_roster_v`**.

Sans cet objet, `PortRosterEnseignant.rosterDeGroupe` lève
`EchecRoster(projectionAbsente)` — **elle refuse explicitement plutôt que de
rendre une liste vide**, qui se lirait comme « ce groupe n'a aucun membre ».

### 1.3 Lecture de `student_reading_position` par l'enseignant

Invariant **J2**, inscrit en commentaire normatif dans 0007 : « une page tournée
par l'enseignant pour toute la classe ne doit jamais l'écrire ». La demande porte
donc sur une **lecture seule**, et elle passe par la vue de 1.1 plutôt que par une
policy `select` directe : une policy ouvrirait aussi `zoom_level`, qui est une
préférence personnelle et non un fait pédagogique.

### 1.4 `interface_mode` : un libellé, pas une colonne

Décision D-07 : **la valeur SQL reste `'child'`**. Aucune migration ne la renomme.
Le contrat expose un booléen `interfaceGuidee`, et aucune UI n'écrit « mode
enfant » — c'est vérifié par un test de ce lot.

En attendant, `ficheDepuisRosterV` pose `interfaceGuidee: false` et le commente :
**promettre une Interface guidée qu'on n'a pas lue serait pire que de ne pas
l'annoncer.**

### 1.5 L'état « excusée » disparaît dans la projection

`EtatPresence` compte quatorze valeurs, `EtatPresenceProjete` neuf. La
correspondance est explicite et testée, mais **une information se perd** :
`excusee` devient `absent`. L'excuse est une décision administrative
(`session_presence_override`, 0007) ; le roster live dit où est la personne, et
elle n'est pas là.

**Demande, si le produit veut la distinguer :** une dixième valeur de projection
`excuse`, et la colonne correspondante dans `presence_seance_v`. Elle n'a **pas**
été ajoutée unilatéralement : l'invariant J4 interdit un quinzième état en base,
et projeter n'est pas la même chose qu'ajouter. **Décision produit attendue.**

---

## 2. AMENDEMENT DE CONTRAT — `PortRappelDiscret.cooldownRestant`

**Statut : déjà implémenté, à entériner.**

Le contrat §12 déclare :

```dart
abstract class PortRappelDiscret {
  Future<void> rappeler({required String sessionId, required String academyId});
  Duration get cooldown;
}
```

Il expose la **durée** du cooldown, mais rien qui dise **où l'on en est**. Sans
cette lecture, l'interface ne peut qu'envoyer pour apprendre que c'est trop tôt,
donc afficher un échec là où la spec §10.2 demande de ne rien afficher.

Méthode ajoutée, à intégrer au contrat canonique :

```dart
/// Depuis quand cet eleve est encore sous cooldown. `null` = il ne l'est pas.
Duration? cooldownRestant({required String sessionId, required String academyId});
```

Aucun autre agent ne consomme ce port : l'amendement est sans effet de bord.

---

## 3. AMENDEMENT DE CONTRAT — `SessionEnCours.horloge` doit être nullable

**C'est le seul endroit où le contrat, tel qu'écrit, rend un invariant produit
intenable.**

Contrat §12 :

```dart
class SessionEnCours {
  final String sessionId;
  final String groupeId;
  final String libelleGroupe;
  final SessionClockVM horloge;   // <- obligatoire
}
```

Or `SessionClockVM` vient de `PortHorlogeSeance` (Agent A), lui-même adossé à
`maintenantServeurUtc()` — **une horloge serveur qui n'existe pas en base**, et
qui est nommée « NOUVEAU » dans le mapping du contrat §3. Un cours peut donc être
ouvert, la salle connectée, et l'horloge indisponible.

Trois issues, deux fausses :

1. fabriquer une horloge locale depuis `DateTime.now()` — **interdit**, c'est
   l'invariant 9 de l'annexe des décisions ;
2. ne rien déclarer tant que l'horloge manque — le cours tournerait **sans barre
   « Cours en cours »**, donc sans retour possible, ce qui casse la spec §9.4 ;
3. tenir l'état réel à côté et ne projeter sur le contrat que ce qui est complet.

**C'est la troisième qui a été faite** : `CoursOuvert`
(`lib/core/tc_classe/session_persistante.dart`) porte `SessionClockVM? horloge` et
`versContrat` rend `null` tant qu'elle manque. Conséquence assumée et testée :
`PortSessionPersistante.courante()` rend `null` pendant qu'un cours tourne.

**Amendement demandé :** `final SessionClockVM? horloge;` dans `SessionEnCours`.
Alors `CoursOuvert` disparaît et Agent Z supprime la projection.

---

## 4. SIGNATURES MANQUANTES — trois ports nommés sans contrat

Aucun de ces trois n'a pu être stubé : **on ne copie pas à l'identique une classe
abstraite qui n'existe nulle part.**

### 4.1 `MessagePedagogique` (Agent F)

`PortRealtimePedagogique.emettreCible(MessagePedagogique, ...)` est la voie du
rappel discret. Mais `MessagePedagogique` est **nommé** en §9 et en §17 de
`TEACHING_CORE_CONTRACTS.md` et **ses champs ne sont donnés nulle part**.

Agent D a écrit un double local et l'a déclaré. **Agent E n'en écrit pas un
troisième** : il réduit son besoin à ce qu'il est réellement — « fais parvenir à
cette personne, dans cette séance, le fait que le professeur l'appelle » — soit
un `typedef` de deux identifiants :

```dart
typedef TransportRappel =
    Future<void> Function({required String sessionId, required String academyId});
```

Le défaut est `transportRappelAbsent`, qui **échoue explicitement** : un transport
muet ferait croire à l'enseignant que l'élève a été appelé. Agent Z branche
`emettreCible` derrière cette ligne, et **un seul endroit change**.

Signature demandée à Agent F : les champs de `MessagePedagogique`, et en
particulier le type d'un message de nudge.

### 4.2 `PortDockHote` (Agent D)

Listé au tableau des ports (§17), chemin canonique
`lib/core/tc_outils/port_dock_hote.dart`, **sans aucune signature**. Ce que la
Classe Live doit savoir pour l'accueillir :

```dart
// Attendu, a confirmer par Agent D :
//   - le dock est-il un Widget, ou un descripteur que l'hote rend ?
//   - de quoi a-t-il besoin : sessionId, resourceId, ContentPosition courante ?
//   - quelle hauteur reserve-t-il, et flotte-t-il ou s'ancre-t-il ?
```

En attendant : `SlotClasse` + `HoteDock`
(`lib/features/tc_classe_live/slots_tc_classe.dart`), une enveloppe qui porte un
identifiant de contexte et un `WidgetBuilder?`. Tant qu'il est `null`, **rien
n'est rendu** — pas même un cadre vide : un dock en attente occuperait la place du
Coran pour ne rien offrir.

### 4.3 `ClassLibraryPicker` (Agent B)

Déclaré « surface réutilisable » au §17, chemin
`lib/features/tc_catalogue/class_library_picker.dart`, **sans signature**. Même
mécanisme de slot, mais avec un état **explicite** quand il manque
(« Bibliothèque non branchée ») : ici l'enseignant a appuyé sur un bouton, il doit
savoir pourquoi rien ne s'ouvre.

Contrainte à respecter côté B, rappelée ici parce qu'elle est facile à perdre :
la surface s'ouvre **dans** la Classe Live, en panneau latéral ou en feuille. Elle
ne navigue pas. La room reste connectée (décision D-20).

---

## 5. DEMANDES À AGENT Z — intégration

### 5.1 Promouvoir la galerie vidéo en composant partagé

`lib/features/salle/salle_page.dart` porte déjà `_Scene`, `_Galerie`, `_Cadre` et
`_SansImage` — **quatre classes privées à ce fichier**, lui-même **nommé INTERDIT**
à Agent E. Elles sont donc inaccessibles, pas seulement inconvenables.

`lib/features/tc_classe_live/scene_classe.dart` en est une version réduite, et
**la duplication est déclarée dans l'en-tête du fichier**. Demande : promouvoir la
galerie dans `lib/core/widgets/` à l'intégration, et faire consommer les deux
écrans.

> Contrainte connue : `test/.../catalogue_galerie_test` est **rouge dans la
> baseline**, donc aucun composant nouveau ne peut entrer dans
> `lib/core/widgets/` avant sa réparation (BASELINE_ADDENDUM).

### 5.2 Route et entrée de navigation

`routesTcE()` (`lib/features/tc_classe_live/routes_tc_e.dart`) **retourne** des
routes et ne construit aucun `GoRouter`. Deux ajustements restent à Agent Z :

1. **`redirection.dart`** renvoie toute route hors préfixe de rôle vers la racine
   du rôle. `/tc/classe` posée sans cet ajustement sera **inatteignable** ;
2. `ContexteClasseLive` voyage par `state.extra`, comme `BilletSalle` (ADR-005) :
   aucune URL de salle n'est mémorisable. La route rend un état explicite quand
   le contexte manque ; **la redirection reste à câbler**.

**Aucune destination de `nav_shell.dart` n'est demandée.** Le plafond de quatre y
est tenu par assertion et l'enseignant en a déjà quatre : la Classe Live s'atteint
par le bouton « Rejoindre » du Groupe et par la barre compacte « Cours en cours »,
qui est faite pour être posée dans la coque de navigation et ne rend **rien** quand
aucun cours n'est ouvert.

### 5.3 Brancher les deux actions de fiche restées ouvertes

`FicheSeance` expose `onNoter` et `onSignaler`. Quand ils sont `null`, **l'action
n'est pas rendue** — jamais grisée : un bouton visible mais inerte invite à
appuyer dessus, son absence ne pose pas la question.

- « Noter » appartient au cahier du chantier enseignant (`lib/features/cahier/`) ;
- « Signaler un besoin » appartient à `PortSignalement` d'Agent H.

---

## 6. ICÔNES DEMANDÉES

**Aucune.** La Classe Live n'introduit aucun `IconData` : les commandes passent par
`ActionPrincipale` (libellés), les états par `StatusPill` (mot + pastille), les
vides par `EmptyState` (icône de registre). Aucun placeholder `// TC-ICONE:` n'a
été posé.

---

## 7. DÉPENDANCE DEMANDÉE

**Aucune.** `pubspec.yaml` n'est pas touché. Rien dans ce lot n'a eu besoin d'un
paquet absent : le moteur temps réel, le pré-vol et la présence existent déjà.

---

## 8. DÉFAUTS PRÉ-EXISTANTS CONSTATÉS — signalés, non corrigés

Hors mission. Aucun n'a été touché.

1. **`dart run tool/verifier_jetons.dart` est ROUGE dans la baseline `0071557`** :
   10 violations, toutes hors du périmètre d'Agent E —
   `core/widgets/nav_shell.dart` (un `IconButton`, un `onTap:` nu, trois M-dash),
   `core/widgets/menu_filtre.dart` (deux M-dash),
   `core/widgets/sous_navigation_domaine.dart` (un `onTap:` nu),
   `features/admin_dossiers/dossiers_page.dart` et
   `features/admin_journal/journal_page.dart` (un M-dash chacun).
   `flutter analyze lib test`, lui, est **propre**.
2. `supabase/migrations/0029` est écrite mais **non appliquée en base** :
   `dossiers_en_attente()` livre nom et prénom de toute personne en attente de KYC
   à un appelant anonyme (rappel du BASELINE_ADDENDUM).
3. `test/.../catalogue_galerie_test` est rouge (rappel du BASELINE_ADDENDUM).
4. `session_participants.entered_at` / `exited_at` ne sont **jamais écrites** :
   deux occurrences dans tout le dépôt, leurs déclarations. La Classe Live n'en
   dépend pas — elle lit `presence_seance_v` — mais toute future mesure de durée
   en salle tomberait dessus.
