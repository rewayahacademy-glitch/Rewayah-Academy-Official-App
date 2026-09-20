# TEACHING_CORE_CONTRACTS.md

---

## ⚠ AMENDEMENT 1 — `ContentPosition` et `ContentRange` : LIS CECI AVANT DE LES STUBER

**Publié en cours de phase parallèle par l'orchestrateur. Il prévaut sur la §7 et la §8 ci-dessous.**

Les agents A et B ont établi, chacun de son côté, que `ContentPosition` et `ContentRange` **tels
qu'écrits en §7 et §8 ne compilent pas** : les champs sont `final` et non nullables alors que
`const ContentPosition._();` ne les initialise pas, et `bool contient(ContentPosition p);` est une
méthode sans corps dans une classe concrète.

**Agent B, qui est le producteur canonique de ces deux types, les a publiés.** La forme canonique
n'est donc plus à inventer, elle existe :

```
lib/core/tc_bibliotheque/content_position.dart   (ContentPosition + enum TypeAncrage)
lib/core/tc_bibliotheque/content_range.dart      (ContentRange)
```

dans le worktree `D:\RA_TC\b`.

**Ce que tu fais si tu as besoin de l'un de ces deux types :**

1. **Ne recopie pas la §7 ni la §8 de ce document.** Elles sont périmées.
2. Ouvre le fichier d'Agent B au chemin ci-dessus (lecture seule, c'est un autre worktree) et copie la
   déclaration **à l'identique** dans ton propre `ports_externes/`, avec l'en-tête `// TC-STUB-PORT:`
   habituel pointant vers le chemin canonique d'Agent B.
3. N'ajoute, ne retire et ne renomme **aucun** champ. Toute divergence reste un BLOCKER au pré-merge.

Surface publique canonique, pour mémoire :

```dart
enum TypeAncrage { page, ayah, section, fraction }   // chacun porte une valeurSql

class ContentPosition {           // @immutable
  const ContentPosition.page({required String resourceId, required int page, String? resourceVersionId});
  const ContentPosition.ayah({required String resourceId, required int sourate, required int ayah, String? resourceVersionId});
  const ContentPosition.section({required String resourceId, required String sectionId, String? resourceVersionId});
  const ContentPosition.fraction({required String resourceId, required double fraction, String? resourceVersionId});
  final String resourceId; final String? resourceVersionId; final TypeAncrage typeAncrage;
  final int? page; final int? sourate; final int? ayah; final String? sectionId; final double? fraction;
}
// Invariant : un seul ancrage a la fois. Les champs hors typeAncrage valent null (assertions).
// Le zoom n'appartient PAS a la position : il est local a chaque personne.

class ContentRange {
  final String resourceId; final String? resourceVersionId;
  final ContentPosition debut; final ContentPosition fin;
  TypeAncrage get typeAncrage;
  bool contient(ContentPosition p);
  bool chevauche(ContentRange autre);
}
```

## ⚠ AMENDEMENT 2 — un port dont la chaîne de types est trop longue se consomme par SLOT

Agent A a soulevé un point qui vaut pour tout le monde. Stuber `PortRosterEnseignant` obligerait à
copier `TeacherStudentProjection` **et** toute sa chaîne (`ResumeSeance`, `AssiduiteRecente`,
`EtatPresenceProjete`, `LearningAssignment`, `StatutAssignation`, `IntentionPedagogique`,
`ContentRange`, `ContentPosition`) : environ 180 lignes appartenant à trois autres agents, donc autant
d'occasions de diverger.

**Arbitrage retenu, conforme à la §2 de ce document :** quand un port consommé traîne une chaîne de
types ouverte, **ne le stube pas**. Expose un *slot* — une enveloppe qui porte un identifiant de
contexte et un paramètre `contenu` que l'hôte remplira — et laisse Agent Z brancher la surface de
l'agent propriétaire à l'intégration. Documente ce choix dans ton rapport.

Stube le port **seulement** quand sa chaîne de types est close (exemples validés : `PortCatalogue`,
`PortTravailAVenir`).

---

> Les seize contrats du Teaching Core, **décrits sans être implémentés**.
> Ce document est la **source de vérité des signatures**. Deux agents qui écrivent chacun un côté d'un
> port doivent compiler ensemble : toute divergence entre un stub local et ce document est un **BLOCKER**
> au contrôle pré-merge.
>
> Un agent qui a besoin d'un champ ou d'une méthode absent ici **ne l'ajoute pas** : il écrit
> `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md` et attend l'amendement.

---

## 0. Conventions communes à tous les contrats

| Règle | Détail |
|---|---|
| **Immuabilité** | Toute classe de contrat est `@immutable`, champs `final`, constructeur `const` quand c'est possible. Aucune mutation en place. |
| **Temps** | Tout `DateTime` d'un contrat est **en UTC** (`DateTime.utc(...)`, `isUtc == true`). Les fuseaux sont des chaînes IANA (`'Europe/Paris'`, `'Africa/Conakry'`, `'Asia/Riyadh'`). **Aucun offset numérique n'apparaît jamais dans un contrat.** |
| **Identifiants** | `String` portant un uuid, jamais un `int`. Un identifiant d'élève exposé à l'enseignant est **toujours** l'`immutable_id`, jamais le `profile_id` brut quand une projection l'évite. |
| **Absence** | Une donnée indisponible est `null`, jamais une valeur de repli trompeuse. Un `null` de présence signifie **inconnu**, jamais **absent** (invariant J3 du dépôt). |
| **Énumérations** | Chaque enum de contrat porte une `valeurSql` et un `depuisSql(String?)` qui rend `null` sur valeur inconnue, comme `lib/core/domain/enums.dart`. **Jamais de repli silencieux.** |
| **Erreurs** | Un port rend un résultat typé ou lève une exception de son domaine (`EchecXxx`). Il n'avale jamais une erreur silencieusement, sauf décision documentée (précédent : `ServiceVideo.annoncerSortie`). |
| **Pas d'IO dans un VM** | Un `…VM` est une donnée calculée, sans réseau, sans horloge locale implicite. `maintenant` est toujours un paramètre. |
| **Chemin canonique** | Chaque port a un chemin unique, donné ci-dessous. Un consommateur qui ne l'a pas encore copie la signature dans `lib/core/tc_<son_domaine>/ports_externes/` avec l'en-tête `// TC-STUB-PORT:` (voir OWNERSHIP §3). |

### Invariant PII — à relire avant d'écrire une ligne de projection

`TeacherStudentProjection` **ne contient jamais**, à aucun niveau d'imbrication :

> téléphone · email · adresse postale · adresse précise ou géolocalisation · identité complète ou
> partielle des tuteurs · coordonnées de la famille · paiements, solde, facture ou moyen de paiement ·
> identifiant privé d'appareil · nom de famille de l'élève, **y compris une initiale**.

Cette règle ne se tient pas par une barrière Flutter : elle se tient parce que la **vue serveur ne
délivre pas ces colonnes**. `teacher_roster_v` a explicitement retiré `last_name` en 0005 (ADR-008),
et `profiles` n'accorde **aucune** policy `select` à l'enseignant. Un agent qui aurait besoin d'une
colonne absente **ne la reconstitue pas par jointure** : il écrit un CONTRACT_REQUEST.

---

## 1. GroupSummaryVM — la carte du Groupe

**Produit par :** Agent A · **Consommé par :** A (Mes groupes), E (header de classe), H (contexte), Q
**Chemin canonique :** `lib/core/tc_groupe/group_summary_vm.dart`

### Champs

| Champ | Type Dart | Note |
|---|---|---|
| `groupeId` | `String` | uuid de `public.groupes.id` |
| `libelle` | `String` | Nom **familier**, jamais un code backend |
| `couleurJeton` | `JetonCouleurGroupe` | Index dans une palette **administrée**. Jamais un hex libre. |
| `enseignant` | `EnseignantVM` | voir ci-dessous |
| `nomCours` | `String?` | Nom **humain** du cours. `null` si non assigné. |
| `niveauHumain` | `String?` | Nom humain du niveau (`programme_niveaux.nom_humain`). **Jamais `code_technique`.** |
| `nombreMembres` | `int` | Lu du serveur |
| `seuilMax` | `int` | Lu du serveur. **Jamais la valeur 5 en dur.** |
| `typePublic` | `TypePublicGroupeVM` | `enfant` \| `adulte` |
| `prochaineSeance` | `OccurrenceSeance?` | `null` = aucune occurrence connue |
| `horloge` | `SessionClockVM?` | `null` si pas d'occurrence |
| `actif` | `bool` | `false` si `groupes.ended_at` est renseigné |

```dart
@immutable
class EnseignantVM {
  final String enseignantId;          // uuid
  final TitreEnseignant titre;        // sayyid | sayyida
  final String nomAffichage;          // prenom, ou prenom + nom d'affichage AUTORISE
  final String? photoUrlOuCle;        // null = photo manquante -> etat d'erreur explicite
}

enum TitreEnseignant { sayyid, sayyida }   // valeurSql: 'sayyid' | 'sayyida'

@immutable
class JetonCouleurGroupe {
  final int index;                    // 0 .. tailleDePalette-1
  final String codeStable;            // ex. 'g17' — stable, administre, jamais un hex
}

@immutable
class OccurrenceSeance {
  final String? sessionId;            // null si l'occurrence n'est pas encore materialisee
  final DateTime debutUtc;            // UTC
  final Duration duree;
  final String fuseauReferenceGroupe; // IANA
}

enum TypePublicGroupeVM { enfant, adulte }
```

### Invariants

1. **La couleur n'est jamais le seul identifiant du groupe.** Toute UI qui affiche `couleurJeton`
   affiche aussi `libelle`. Un liseré seul est un défaut d'accessibilité.
2. `seuilMax` vient **toujours** du serveur. Afficher `4 / 5` se fait par `'$nombreMembres / $seuilMax'`.
3. `photoUrlOuCle == null` déclenche un **état d'erreur ou de migration explicite**, jamais un avatar
   générique silencieux : la photo enseignant est obligatoire (décision D-01).
4. `niveauHumain` n'est **jamais** un code technique : c'est une règle UX inscrite en commentaire SQL
   dans `0020_programme_pedagogique.sql`.
5. Toute la carte ouvre l'Espace Groupe. Le CTA « Rejoindre » n'apparaît que si
   `horloge!.rejoindreOuvert == true`.

### Port

```dart
// lib/core/tc_groupe/port_groupes.dart   (Agent A)
abstract class PortGroupes {
  /// Les groupes visibles par l'appelant, selon son role serveur.
  Future<List<GroupSummaryVM>> mesGroupes();

  /// Un groupe precis, ou null s'il n'est pas visible par l'appelant.
  Future<GroupSummaryVM?> groupe(String groupeId);
}

final Provider<PortGroupes> portGroupesProvider = /* declare par Agent A */;
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| `groupeId`, `libelle`, `typePublic`, `seuilMax`, `nombreMembres`, `actif` | `groupes_admin()` / `GroupeAdmin` (`lib/core/admin/service_groupes.dart`) | **Existe, réservé admin.** Une variante par rôle est un CONTRACT_REQUEST. |
| `enseignant.nomAffichage` | `groupes_admin()` rend `teacher_prenom` / `teacher_nom` | Existe (chemin admin) |
| `enseignant.photoUrlOuCle` | **rien** — `teacher_profiles` n'a aucune colonne photo/avatar | **NOUVEAU** → CONTRACT_REQUEST A |
| `enseignant.titre` | **rien** | **NOUVEAU** (décision D-02) → CONTRACT_REQUEST A |
| `couleurJeton` | **rien** — `groupes` n'a pas de colonne couleur | **NOUVEAU** → CONTRACT_REQUEST A |
| `nomCours`, `niveauHumain` | `programme_niveaux` (0020), admin-only, non relié à `groupes` | **NOUVEAU** (le lien manque) |
| `prochaineSeance` | **rien** — `sessions` n'a pas de `groupe_id`, `materialiser_seances()` ignore `groupes` | **NOUVEAU / BLOQUANT** (BASELINE §6.2) |
| `fuseauReferenceGroupe` | `groupes.timezone_iana` **existe mais n'est ni écrite ni exposée** ; `GroupeAdmin.depuisJson` la recode en dur | **Faux existant** → CONTRACT_REQUEST A |

---

## 2. GroupHomeVM — l'Espace Groupe par rôle

**Produit par :** Agent A · **Consommé par :** A, H (remplit les slots), Q
**Chemin canonique :** `lib/core/tc_groupe/group_home_vm.dart`

### Champs

```dart
@immutable
class GroupHomeVM {
  final GroupSummaryVM identite;
  final RoleEspaceGroupe role;              // eleve | tuteur | enseignant | admin
  final SessionClockVM? horloge;
  final List<SlotAction> avantProchainCours; // <= 3, garanti par assertion
  final SlotBibliotheque bibliotheque;       // rempli par B via port, jamais localement
  final SlotProgression? progression;        // null si le role n'en a pas besoin
  final SlotRoster? roster;                  // non null uniquement pour enseignant/admin
  final bool afficheConseilAppareil;
}

enum RoleEspaceGroupe { eleve, tuteur, enseignant, admin }

@immutable
class SlotAction {
  final String id;
  final String libelle;
  final IntentionPedagogique? intention;   // d'Agent D, null si action non pedagogique
  final bool disponibleHorsLigne;
}
```

`SlotBibliotheque`, `SlotProgression` et `SlotRoster` sont des **enveloppes vides** : elles portent un
identifiant de contexte (`groupeId`, éventuellement `sessionId`) et rien d'autre. Le contenu est rendu
par l'agent propriétaire du port correspondant.

### Invariants

1. **Pas de sidebar interne élève/tuteur. Pas de cinq onglets.** Une page verticale, ordre **stable** :
   Session → Avant le prochain cours → Bibliothèque → Progression.
2. `avantProchainCours.length <= 3`, garanti par assertion, pour **tous** les rôles.
3. `bibliotheque` n'est **jamais** implémentée dans `lib/core/tc_groupe/` : Agent A consomme
   `PortCatalogue`. Aucune page Groupe n'invente une deuxième bibliothèque.
4. « Reprendre le cours » **n'est pas une section permanente** : c'est une action contextuelle,
   donc un `SlotAction` conditionnel, jamais un bloc fixe.
5. `afficheConseilAppareil` rend le message discret « Tablette ou ordinateur conseillé pour le cours.
   Le téléphone reste pris en charge. » — **pas de popup, pas de blocage, pas de jugement**.
6. L'Admin garde sa navigation locale (`Aperçu | Membres | Planning | Pédagogie | Ressources | Réglages`)
   mais **Agent A ne touche pas au panneau Admin courant** : c'est Agent Z, à l'intégration.

---

## 3. SessionClockVM — le temps, les horloges, la fenêtre

**Produit par :** Agent A · **Consommé par :** A, E (header, temps restant), G (budget tuteur), H, Q
**Chemin canonique :** `lib/core/tc_horloge/session_clock_vm.dart`

### Champs

```dart
@immutable
class SessionClockVM {
  final String? sessionId;
  final DateTime debutUtc;
  final DateTime finPrevueUtc;
  final DateTime joinOpensAtUtc;        // debutUtc - fenetreAcces
  final Duration fenetreAcces;          // defaut 20 min, CONFIGURABLE, jamais en dur cote client
  final Duration graceApresFin;

  final HorlogeAffichee horlogeUtilisateur;
  final HorlogeAffichee? horlogeContrepartie; // heure de l'enseignant (cote eleve) ou heure de
                                              // reference du groupe (cote enseignant) ; null si
                                              // les deux fuseaux coincident

  final PhaseSeance phase;
  final Duration? restant;              // avant debut, ou avant fin si en cours ; null si terminee
  final bool rejoindreOuvert;
  final NoticeDst? noticeDst;
  final DateTime calculeeAUtc;          // instant serveur de reference, jamais DateTime.now() seul
}

@immutable
class HorlogeAffichee {
  final String fuseauIana;              // 'Asia/Riyadh'
  final String libelleVille;            // 'Riyad' — lisible, jamais 'UTC+3'
  final String heureLocaleRendue;       // '18:00' — DEJA converti, jamais recalcule par le widget
  final String dateLocaleRendue;        // 'Lundi 21 septembre'
}

enum PhaseSeance {
  avantFenetre,      // Rejoindre absent/desactive
  salleOuverte,      // T-20 .. T0 : « Salle ouverte - cours dans 18 min »
  attenteAvantT0,    // connecte avant T0 : AUCUN temps academique consomme
  enCours,           // T0 .. fin : « Cours en cours - reste 1 h 30 »
  prolongee,         // apres fin prevue, session encore ouverte : « Cours toujours en cours »
  terminee,          // retour a la prochaine seance, Rejoindre ferme
}

@immutable
class NoticeDst {
  final DateTime transitionUtc;
  final String fuseauConcerne;          // IANA
  final String heureAvantRendue;
  final String heureApresRendue;
  final EcheanceDst echeance;           // j30 | j7 | j1
}

enum EcheanceDst { j30, j7, j1 }
```

### Invariants

1. **Aucun offset hardcodé.** Jamais `UTC+1`, jamais `+ Duration(hours: 1)` pour changer de fuseau.
   Les conversions sont **rendues en amont** : `heureLocaleRendue` est une chaîne déjà calculée.
   Un widget ne calcule **jamais** une règle de fuseau (consigne explicite du PROMPT A).
2. `restant` est dérivé de `calculeeAUtc` et de l'occurrence, **pas de l'horloge locale seule**.
3. `phase == prolongee` ⇒ **aucun countdown négatif**. On affiche « Cours toujours en cours ».
4. `phase == attenteAvantT0` ⇒ **aucun temps académique consommé**. C'est l'invariant §5.2 de la spec,
   et c'est là que le défaut actuel de `VuePresence` se déclencherait (BASELINE §6.4).
5. `rejoindreOuvert == (maintenant >= joinOpensAtUtc && phase != terminee)`, et **la vraie barrière
   reste serveur** : `autoriser_jeton_video()` refuse le jeton hors fenêtre. Un bouton ouvert que le
   serveur refuserait est un défaut — c'est exactement pourquoi `fenetreAcces` ne doit jamais être
   une constante cliente.
6. **Le voyage d'un enseignant ne déplace jamais l'horaire institutionnel du groupe.**
7. `horlogeContrepartie == null` quand les deux fuseaux coïncident : on n'affiche pas deux fois la
   même heure.

### Port

```dart
// lib/core/tc_horloge/port_horloge_seance.dart   (Agent A)
abstract class PortHorlogeSeance {
  /// L'horloge d'une occurrence, resolue cote serveur (conversions incluses).
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  });

  /// Flux de rafraichissement. Cadence decidee par l'implementation, jamais par le widget.
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  });

  /// L'instant serveur de reference. Ne JAMAIS substituer DateTime.now().
  Future<DateTime> maintenantServeurUtc();
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Conversion motif IANA → instant UTC | `public.instant_creneau()` (0005, corrigée **0006**) | **Existe, à réutiliser tel quel.** La recoder rejouerait le bug des 7 jours d'écart Paris/Conakry. |
| Fuseau de l'utilisateur | `public.mon_fuseau()` + `monFuseauProvider` | Existe |
| Fuseau de référence du groupe | `groupes.timezone_iana` déclarée, **jamais écrite ni exposée** | **Faux existant** → CONTRACT_REQUEST A |
| `restant` avant début | `Seance.avantDebut()` (`service_planning.dart`) | **Existe — `SessionClockVM` UNIFIE les deux countdowns existants, il ne devient pas le troisième.** |
| Prochaine occurrence | `prochainCours()` (`lib/core/planning/journee.dart`) | Existe, à consommer |
| `joinOpensAt`, `fenetreAcces` | **rien de persisté** ; T-10 en dur à 3 endroits | **NOUVEAU / BLOQUANT** (BASELINE §6.3) |
| `maintenantServeurUtc()` | **rien** — aucune horloge serveur exposée | **NOUVEAU** → CONTRACT_REQUEST A |
| `noticeDst` | **rien** en base ni en Dart | **NOUVEAU** |
| Conversion IANA côté client | **impossible** : ni `timezone`, ni `tz`, ni `intl` dans `pubspec.yaml` | **Rendu serveur imposé** ; si une conversion cliente s'avère nécessaire → CONTRACT_REQUEST A demandant les paquets |

---

## 4. LibraryResource — le manifeste de ressource

**Produit par :** Agent B · **Consommé par :** A (slot), C (QuranResource), D, E, F, H, Q
**Chemin canonique :** `lib/core/tc_bibliotheque/library_resource.dart`

### Champs

```dart
@immutable
class LibraryResource {
  final String id;
  final String title;
  final String shortTitle;
  final String? coverAsset;              // cle d'asset ou cle Storage, JAMAIS une URL signee
  final TypeRessource resourceType;
  final String? edition;                 // ex. 'madina-hafs-604'
  final String language;                 // 'fr' | 'ar' | ...
  final String category;
  final List<String> levelScope;         // codes de niveau du programme
  final PolitiqueAcces accessPolicy;
  final PolitiqueOffline offlinePolicy;
  final String? currentVersionId;        // null si aucune version publiee
  final Set<CapaciteRessource> capabilities;
}

enum TypeRessource { quran, texteStructure, pdf, image, lecon }
// valeurSql: 'quran' | 'structured_text' | 'pdf' | 'image' | 'lesson'

enum CapaciteRessource {
  pageable, searchable, zoomable, selectable, focusable,
  annotatable, assignable, presentableInClass, supportsStylus, supportsOffline,
}

enum PolitiqueAcces { publique, inscrits, groupeAssigne, enseignantSeul, admin }
enum PolitiqueOffline { jamais, surDemande, automatique }
```

### Invariants

1. **Une seule Bibliothèque.** La même ressource sert hors classe et en classe. Il n'existe pas de
   `LibraryOutsideClass` / `LibraryInsideClass` (interdiction explicite du PROMPT B).
2. **`coverAsset` n'est jamais une URL signée** : une URL signée expire. On persiste la clé — leçon déjà
   inscrite dans `lib/core/appairage/service_avatar.dart`.
3. Les couvertures sont **persistantes et distinctes**. Un fallback contrôlé, jamais une grille
   d'icônes génériques identiques.
4. `capabilities` est la **seule** source du comportement offert. Une UI ne devine jamais qu'un PDF est
   annotable : elle lit `capabilities.contains(CapaciteRessource.annotatable)`.
5. La **source est immuable**. Aucune annotation, aucun marqueur, aucun focus ne crée une copie du
   support.

### Port

```dart
// lib/core/tc_bibliotheque/port_catalogue.dart   (Agent B)
abstract class PortCatalogue {
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre});
  Future<List<LibraryResource>> recents({int limite = 10});
  Future<List<LibraryResource>> pourGroupe(String groupeId);
  Future<LibraryResource?> parId(String resourceId);
  Future<List<LibraryResource>> rechercher(String requete, {FiltreCatalogue? filtre});

  /// « Continuer » : derniere ressource et derniere position.
  Future<ReprisLecture?> derniereLecture();
}

@immutable
class FiltreCatalogue {
  final Set<TypeRessource>? types;
  final String? langue;
  final String? categorie;
  final String? niveau;
  final EtatOffline? etatOffline;
}

@immutable
class ReprisLecture {
  final LibraryResource ressource;
  final ContentPosition position;
  final DateTime vueLeUtc;
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Table de ressource, de version, d'artefact | **aucune** (0001→0024 inventoriées) | **NOUVEAU / BLOQUANT** (BASELINE §6.5) |
| Bucket Storage pour supports et couvertures | **aucun** — seuls `kyc` et `avatars` (0004) | **NOUVEAU** |
| Renderer PDF / Markdown | **aucun** dans `pubspec.yaml` | **NOUVEAU** → CONTRACT_REQUEST B |
| `QuranResource` | `lib/features/coran/coran_page.dart` **est déjà un renderer** | **Existe** — le rendre enfichable est du travail, pas de la réutilisation directe (Agent C) |
| Cahier des charges du domaine | `docs/produit/bibliotheque-contenu.md` | **Existe, à confronter à la spec avant d'en écrire un nouveau** |

---

## 5. ResourceVersion — la version immuable publiée

**Produit par :** Agent B · **Consommé par :** C, D, F, H, Q
**Chemin canonique :** `lib/core/tc_bibliotheque/resource_version.dart`

```dart
@immutable
class ResourceVersion {
  final String id;
  final String resourceId;
  final int numeroVersion;               // unique par ressource
  final StatutVersionRessource statut;   // brouillon | publiee | archivee
  final DateTime? publieeLeUtc;
  final String? publieePar;
  final String? downloadAssetId;         // le PDF derive, s'il existe
  final String? empreinte;               // sha256 du contenu, pour prouver l'immuabilite
}

enum StatutVersionRessource { brouillon, publiee, archivee }
// valeurSql: 'brouillon' | 'publiee' | 'archivee' ; repli sur 'publiee' (precedent 0020)
```

### Invariants

1. **Une version publiée est immuable.** Toute évolution crée un nouveau brouillon. La publication est
   **irréversible**, et cette contrainte est imposée **en base**, pas par le client.
2. Une annotation n'altère **jamais** `resource_version`. C'est un test contractuel explicite d'Agent Q.
3. `downloadAssetId` est renseigné **une seule fois, à la publication**. On ne régénère jamais un PDF à
   chaque clic.

### Port

```dart
// lib/core/tc_bibliotheque/port_versions_ressource.dart   (Agent B)
abstract class PortVersionsRessource {
  Future<ResourceVersion?> versionCourante(String resourceId);
  Future<ResourceVersion?> parId(String versionId);
  Future<List<ResourceVersion>> historique(String resourceId);
}
```

### Mapping vers l'existant

**Le patron existe et est testé** : `programme_versions` / `programme_niveaux` (0020) et son miroir Dart
`StatutVersionProgramme` / `VersionProgramme` (`lib/core/admin/service_programme.dart`). Triplet de
statuts, publication irréversible imposée en base, RPC de clonage `creer_version_programme()`.
**Calquer, ne pas inventer un second vocabulaire de statuts.** La table `resource_version` elle-même est
**NOUVELLE** → CONTRACT_REQUEST B.

---

## 6. DownloadAsset — l'artefact téléchargeable

**Produit par :** Agent B · **Consommé par :** B, H, Q
**Chemin canonique :** `lib/core/tc_telechargement/download_asset.dart`

```dart
@immutable
class DownloadAsset {
  final String id;
  final String resourceVersionId;
  final FormatArtefact format;           // pdf | epub | audio | image
  final String cleStockage;              // cle Storage — JAMAIS une URL signee
  final int tailleOctets;
  final String? empreinte;               // sha256
  final OrigineArtefact origine;         // genereALaPublication | importeTelQuel
  final DateTime creeLeUtc;
}

enum FormatArtefact { pdf, epub, audio, image }
enum OrigineArtefact { genereALaPublication, importeTelQuel }
```

### Invariants

1. **Généré une seule fois à la publication**, puis réutilisé. Jamais à chaque clic.
2. Un PDF **importé** reste l'artefact source téléchargeable ; Rewayah génère autour de lui ses
   métadonnées, sa couverture et son index — sans le remplacer.
3. Pour le Coran, **la source canonique reste structurée**. Le PDF téléchargeable correspond à l'édition
   retenue et à ses droits de distribution. Un PDF ne devient jamais la source interactive.
4. L'enregistrement passe **toujours** par le sélecteur de fichiers du système. **Jamais un chemin
   `/sdcard` bricolé.**

### Ports

```dart
// lib/core/tc_telechargement/port_telechargement.dart   (Agent B)
abstract class PortTelechargement {
  Future<DownloadAsset?> artefactDe(String resourceVersionId, FormatArtefact format);

  /// Rend une URL d'acces ephemere. Elle n'est JAMAIS persistee : on persiste la cle.
  Future<Uri> urlEphemere(DownloadAsset asset);
}

// lib/core/tc_telechargement/port_enregistrement_fichier.dart   (Agent B)
abstract class PortEnregistrementFichier {
  /// « Enregistrer une copie » / « Telecharger en PDF ».
  /// Passe par le selecteur systeme. Rend null si l'utilisateur annule.
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  });
}

// lib/core/tc_telechargement/port_etat_offline.dart   (Agent B)
abstract class PortEtatOffline {
  Future<EtatOffline> etatDe(String resourceId);
  Stream<EtatOffline> suivre(String resourceId);
  Future<void> demanderTelechargement(String resourceId);
  Future<void> libererCache(String resourceId);
}

enum EtatOffline { aTelecharger, enCours, enCache, telecharge, indisponible }
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Sélecteur de fichiers | `lib/core/dossier/selecteur_fichier.dart` ; `file_picker 12.2.0` expose déjà `saveFile()` et `getDirectoryPath()` | **Existe. Aucune dépendance nouvelle requise** pour la règle §6.5. |
| URL signée Storage | `service_avatar.dart` (`urlSignee`, ligne 148) | **Existe, patron à reprendre** |
| Cache fichier | `lib/core/cache/media/cache_media.dart` | **Existe, à étendre par port** — manque une méthode d'obtention **et une persistance des clés** (aujourd'hui un `Set` en mémoire) |
| File de téléchargement avec rejeu | `lib/core/cache/sync/file_rapports.dart` | **Patron existant à transposer** — ne pas réinventer un retry |
| État offline **par ressource** | **rien** | **NOUVEAU** |
| Table `download_asset` | **rien** | **NOUVEAU** → CONTRACT_REQUEST B |

---

## 7. ContentPosition — la position canonique dans un support

**Produit par :** Agent B · **Consommé par :** C, D, E, F, H, Q
**Chemin canonique :** `lib/core/tc_bibliotheque/content_position.dart`

```dart
@immutable
class ContentPosition {
  final String resourceId;
  final String? resourceVersionId;
  final TypeAncrage typeAncrage;

  final int? page;            // typeAncrage == page
  final int? sourate;         // typeAncrage == ayah
  final int? ayah;            // typeAncrage == ayah
  final String? sectionId;    // typeAncrage == section
  final double? fraction;     // 0.0..1.0, typeAncrage == fraction (repli)

  const ContentPosition._();
  // Constructeurs nommes attendus : .page(...), .ayah(...), .section(...), .fraction(...)
}

enum TypeAncrage { page, ayah, section, fraction }
```

### Invariants

1. **Un seul ancrage à la fois.** Les champs non pertinents sont `null`. Une assertion le garantit.
2. Une `ContentPosition` est **valable indépendamment du zoom** : le zoom est local à chaque personne et
   ne fait pas partie de la position pédagogique partagée.
3. Sur un rendu **reflowable**, l'ancrage **sémantique** (`ayah`, `section`) est préféré à `fraction`,
   pour éviter le décalage.

### Mapping vers l'existant

`student_reading_position` (0007) est **l'amorce** de ce contrat, mais elle est liée au mushaf et à
l'élève (`page_mushaf`, `sourate`, `verset`, `zoom_level`). `PositionLecture` (`service_coran.dart`) en
est le miroir Dart. **Une position générique multi-ressources n'existe pas** → NOUVEAU.
⚠ Invariant J2, inscrit en commentaire dans 0007 : `student_reading_position` **ne porte aucune référence
à une séance**, et **une page tournée par l'enseignant pour toute la classe ne doit jamais l'écrire**.
La position de **groupe** est un stockage **distinct** (voir `SharedContentState`).

---

## 8. ContentRange — la plage de travail

**Produit par :** Agent B · **Consommé par :** C, D, F, H, Q
**Chemin canonique :** `lib/core/tc_bibliotheque/content_range.dart`

```dart
@immutable
class ContentRange {
  final String resourceId;
  final String? resourceVersionId;
  final ContentPosition debut;
  final ContentPosition fin;             // inclusif

  bool contient(ContentPosition p);
  bool chevauche(ContentRange autre);
}
```

### Invariants

1. `debut.typeAncrage == fin.typeAncrage == ...` et `debut.resourceId == fin.resourceId`, garantis par
   assertion.
2. `debut <= fin` dans l'ordre naturel du type d'ancrage.
3. Une plage est une **métadonnée**, jamais un dessin. Les marqueurs « À revoir / À renforcer » sont des
   métadonnées de range (spec §8.3).

---

## 9. SharedContentState — le support actif de la classe

**Produit par :** Agent F · **Consommé par :** C, D, E, Q
**Chemin canonique :** `lib/core/tc_etat_partage/shared_content_state.dart`

```dart
@immutable
class SharedContentState {
  final String sessionId;
  final String resourceId;
  final String? resourceVersionId;
  final ContentPosition contentPosition;
  final ContentRange? contentRange;
  final ModeAffichagePartage displayMode;   // page | verse | focus
  final List<ContentRange> hiddenRanges;
  final List<MarqueurSemantique> semanticMarkers;
  final ContentPosition? groupResumePosition;
  final int revision;                        // strictement croissant par session
  final String updatedBy;                    // profile_id de l'emetteur
  final DateTime updatedAtUtc;
}

enum ModeAffichagePartage { page, verse, focus }
```

### Invariants

1. **`revision` est strictement croissante par session.** Un paquet dont la `revision` est ≤ à l'état
   courant est **ignoré**. Cela couvre à la fois le duplicate packet et l'out-of-order — ce sont deux
   tests contractuels explicites.
2. **L'état durable minimal est persisté côté backend.** Un late joiner ou une reconnexion doit pouvoir
   récupérer l'état courant **sans dépendre de l'historique des messages realtime** (spec ligne 1200).
   LiveKit n'est **jamais** une base de données.
3. Les mouvements **éphémères** (pointeur, stroke en cours de geste) ne sont **jamais** dans
   `SharedContentState` : ils passent en lossy et ne sont pas persistés.
4. Pendant une présentation dirigée, **l'élève suit automatiquement**. Aucun bouton « Revenir au
   professeur » n'est requis (décision **D-21**).
5. **Le zoom local de l'élève est indépendant** de `SharedContentState` : il ne casse jamais la position
   pédagogique partagée.
6. Aucune donnée sensible n'entre ici : ni téléphone, ni email, ni identité famille.

### Ports

```dart
// lib/core/tc_realtime/port_realtime_pedagogique.dart   (Agent F)
abstract class PortRealtimePedagogique {
  /// Messages fiables et ordonnes (etat partage, mode, eleve actif, stroke committed, nudge).
  Stream<MessagePedagogique> messagesFiables(String sessionId);

  /// Messages ephemeres, perte acceptee (pointeur, preview de stroke).
  Stream<MessagePedagogique> messagesEphemeres(String sessionId);

  Future<void> emettre(MessagePedagogique message, {required CanalFiabilite canal});

  /// Evenement adresse a UN participant (rappel discret).
  Future<void> emettreCible(
    MessagePedagogique message, {
    required String destinataireProfilId,
    required CanalFiabilite canal,
  });

  /// Capacites projetees pour l'appelant, derivees du jeton serveur. Jamais calculees ici.
  Future<CapacitesPedagogiques> capacites(String sessionId);
}

enum CanalFiabilite { fiable, ephemere }

@immutable
class CapacitesPedagogiques {
  final bool peutPiloterSupport;
  final bool peutAnnoter;
  final bool peutEmettreNudge;
  final bool estObservateurSilencieux;
}

// lib/core/tc_etat_partage/port_etat_partage.dart   (Agent F)
abstract class PortEtatPartage {
  Future<SharedContentState?> etatCourant(String sessionId);
  Stream<SharedContentState> suivre(String sessionId);
  Future<void> publier(SharedContentState etat);
  /// Restauration apres reconnexion ou arrivee tardive. Lit le backend, jamais l'historique realtime.
  Future<SharedContentState?> restaurer(String sessionId);
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Droit d'émettre des données | **`can_publish_data` déjà accordé à l'enseignant** (`autoriser_jeton_video`, `_shared/livekit.ts:103`, `CapacitesSalle.peutPublierDonnees`) | **Existe de bout en bout** |
| Primitive d'envoi Flutter | **zéro ligne** : aucun `publishData`, aucun `DataReceived` | **NOUVEAU** ; extension du contrat core → CONTRACT_REQUEST F |
| Persistance de l'état partagé | **rien** : zéro occurrence de `shared_content` / `etat_partage` / `session_shared` | **NOUVEAU / BLOQUANT** |
| Metadata participant | `_shared/livekit.ts:86` `metadata={role}`, décodée ligne 225 | **Existe, sans PII.** Un champ de plus touche le core **et** la fonction Edge → CONTRACT_REQUEST |
| Realtime Supabase | **jamais utilisé** dans `lib/` | Aucune infrastructure |

---

## 10. AnnotationLayer — la couche indépendante du support

**Produit par :** Agent D · **Consommé par :** C, E, F, Q
**Chemin canonique :** `lib/core/tc_outils/annotation_layer.dart`

```dart
@immutable
class AnnotationLayer {
  final String id;
  final String resourceId;
  final String? resourceVersionId;
  final String? sessionId;              // null = couche personnelle hors classe
  final String auteurProfilId;
  final PorteeAnnotation portee;        // temporaire | seance | enregistree
  final List<TraitVectoriel> traits;
  final List<MarqueurSemantique> marqueurs;
  final DateTime majAUtc;
}

enum PorteeAnnotation { temporaire, seance, enregistree }

@immutable
class TraitVectoriel {
  final String id;
  final ContentPosition ancrage;        // ancrage semantique prefere en mode reflow
  final List<PointNormalise> points;    // coordonnees 0.0..1.0 relatives au bloc ancre
  final OutilTrait outil;               // stylet | surligneur | gomme
  final IntentionPedagogique? intention;// la COULEUR derive de l'intention, jamais l'inverse
  final double? pression;               // null si le materiel ne la fournit pas
  final double? inclinaison;            // null si non fournie
}

@immutable
class PointNormalise { final double x; final double y; }

enum OutilTrait { stylet, surligneur, gomme }

@immutable
class MarqueurSemantique {
  final String id;
  final ContentRange plage;
  final IntentionPedagogique intention;
  final String? note;
}

enum IntentionPedagogique { aApprendre, aRevoir, aRenforcer, aEntretenir, pourEvaluation }
// libelles utilisateur : « A apprendre », « A revoir », « A renforcer », « A entretenir »,
// « Pour l'evaluation »
```

### Invariants

1. **La source originale est immuable.** Un trait de stylet est stocké comme données vectorielles
   normalisées, **jamais comme nouvelle copie du support**. Test contractuel d'Agent Q :
   « annotations n'altèrent pas `resource_version` ».
2. **La couleur est dérivée de l'intention, jamais l'inverse.** On marque une intention sémantique, pas
   une couleur brute. Pas de palette graphique complexe.
3. Pendant le geste : paquets realtime **légers** (éphémères). À la fin du trait : version **compacte et
   stable** (fiable). Agent D **ne transporte pas lui-même** les strokes : il expose les événements
   attendus par Agent F.
4. Stylet = encre, doigt = pan/zoom par défaut, via `PointerDeviceKind.stylus` **lorsque disponible**.
   Pression et inclinaison sont **facultatives** : `null` quand le matériel ne les fournit pas, et rien
   dans le rendu ne les rend obligatoires.
5. En mode Mushaf fixe, annotation libre possible. En mode verset reflowable, **ancrage sémantique
   préféré** au mot ou à l'ayah.
6. Le pointeur est **éphémère et non persistant par défaut** : il ne produit pas d'`AnnotationLayer`.

### Port

```dart
// lib/core/tc_outils/port_annotations.dart   (Agent D)
abstract class PortAnnotations {
  Future<AnnotationLayer?> couche({
    required String resourceId,
    String? sessionId,
    required PorteeAnnotation portee,
  });
  Stream<AnnotationLayer> suivre({required String resourceId, String? sessionId});
  Future<void> ajouterTrait(String coucheId, TraitVectoriel trait);
  Future<void> retirerTrait(String coucheId, String traitId);
  Future<void> poserMarqueur(String coucheId, MarqueurSemantique marqueur);
  Future<void> retirerMarqueur(String coucheId, String marqueurId);
  Future<void> annulerDernier(String coucheId);
}
```

### Mapping vers l'existant

**Rien n'existe.** Aucun `AnnotationLayer`, aucun `ContentRange`, aucune table d'annotation, aucun
stockage vectoriel. **NOUVEAU intégralement** → CONTRACT_REQUEST D pour la table.

---

## 11. LearningAssignment — le travail à préparer

**Produit par :** Agent D · **Consommé par :** A (slot), H (avant/après cours), E, Q
**Chemin canonique :** `lib/core/tc_outils/learning_assignment.dart`

```dart
@immutable
class LearningAssignment {
  final String id;
  final String groupId;
  final String? studentId;               // null = assigne a tout le groupe
  final String resourceId;
  final String? resourceVersionId;
  final ContentRange? contentRange;
  final IntentionPedagogique purpose;    // learn | review | reinforce | maintain | assessment
  final String? instructions;            // court, jamais un formulaire narratif
  final DateTime startsAtUtc;
  final DateTime? dueAtUtc;              // nullable
  final String createdBy;
  final StatutAssignation status;
}

enum StatutAssignation { aFaire, enCours, fait, expire, annule }
```

### Invariants

1. **Créée depuis une sélection, sans formulaire long** (outil « Révision » du Teaching Dock).
2. Dans « Avant le prochain cours » : **au maximum 3 actions visibles**, tous rôles confondus.
3. `purpose` réutilise exactement `IntentionPedagogique` : il n'existe **pas** un second vocabulaire
   d'intentions.
4. `studentId == null` ⇒ assignation de groupe. C'est le cas par défaut.

### Port

```dart
// lib/core/tc_outils/port_assignations.dart   (Agent D)
abstract class PortAssignations {
  Future<List<LearningAssignment>> pourGroupe(String groupId, {String? studentId});
  Future<List<LearningAssignment>> aVenir({required String groupId, int limite = 3});
  Future<LearningAssignment> creerDepuisSelection({
    required String groupId,
    String? studentId,
    required String resourceId,
    String? resourceVersionId,
    ContentRange? contentRange,
    required IntentionPedagogique purpose,
    String? instructions,
    DateTime? dueAtUtc,
  });
  Future<void> changerStatut(String assignmentId, StatutAssignation statut);
}
```

### Mapping vers l'existant

**Rien n'existe.** Le domaine Pédagogie (`programme_*`, `progression_*`, `evaluations`) est **admin-only**
et `0022_progression_suivi.sql` (lignes 5-12) **interdit explicitement** d'étendre `rule_overrides` ou
`matching_requests` avec des clés pédagogiques : la forme attendue est un catalogue pédagogique neuf.
**NOUVEAU** → CONTRACT_REQUEST D.

---

## 12. TeacherStudentProjection — la vue pédagogique restreinte

**Produit par :** Agent E · **Consommé par :** E (roster, fiche), H (signalement, post-cours), Q
**Chemin canonique :** `lib/core/tc_classe/teacher_student_projection.dart`

```dart
@immutable
class TeacherStudentProjection {
  final String firstName;                    // PRENOM SEUL
  final String academyId;                    // = profiles.immutable_id, ex. 'RA-AB0012'
  final String? level;
  final String? curriculumPath;
  final String? currentUnit;
  final List<String> activeGoals;
  final ResumeSeance? lastLesson;
  final ContentPosition? resumePoints;
  final AssiduiteRecente? recentAttendance;
  final List<LearningAssignment> currentAssignments;
  final List<String> authorizedPedagogicalNotes;
  final EtatPresenceProjete liveStatus;
  final bool interfaceGuidee;                // miroir de interface_mode, JAMAIS nomme « enfant » en UI
}

@immutable
class ResumeSeance {
  final DateTime dateUtc;
  final ContentPosition? positionAtteinte;
  final String? pointARevoir;                // ex. « Confusion ص / س »
}

@immutable
class AssiduiteRecente {
  final int presences;
  final int total;                            // « 8 / 9 cours »
}

enum EtatPresenceProjete {
  inconnu, attendu, enConnexion, present, enRetard,
  deconnecte, enReconnexion, sorti, absent,
}
```

### Invariants — **LES PLUS IMPORTANTS DU CHANTIER**

1. **Aucune PII famille, jamais.** Voir §0. Ce contrat ne porte **ni `lastName`, ni initiale de nom de
   famille**, et aucun agent ne l'y ajoute.
2. **La protection est serveur, pas Flutter.** La vue `teacher_roster_v` ne délivre pas ces colonnes,
   et `profiles` n'accorde aucune policy `select` à l'enseignant. Une projection Dart qui reconstituerait
   une donnée par jointure serait un contournement — et un **BLOCKER**.
3. `liveStatus == inconnu` quand la lecture échoue. **Jamais `absent`.** C'est l'invariant J3, et il est
   déjà tenu par `service_presence.dart` : erreur → `null` → `inconnu`.
4. `academyId` est l'identifiant affiché. C'est l'`immutable_id`, et il remplace le nom de famille dans
   toute désambiguïsation (ADR-008).
5. `interfaceGuidee` est un **libellé**, pas un champ nouveau : il reflète `interface_mode` dont la
   valeur SQL reste `'child'`. Aucune UI n'écrit « mode enfant » (décision D-07).
6. Les actions de la fiche — `Rappel discret`, `Choisir pour réciter`, `Noter`, `Signaler un besoin` —
   n'ouvrent **jamais** un micro à distance et **ne changent ni la page, ni le focus, ni le stylet, ni le
   support**.

### Ports

```dart
// lib/core/tc_classe/port_roster_enseignant.dart   (Agent E)
abstract class PortRosterEnseignant {
  Future<List<TeacherStudentProjection>> rosterDeSeance(String sessionId);
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId);
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  });
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId);
}

// lib/core/tc_classe/port_rappel_discret.dart   (Agent E)
abstract class PortRappelDiscret {
  /// Reussite silencieuse. Un message n'apparait QUE si l'envoi echoue.
  /// Leve EchecRappel en cas de refus du transport. Aucun accuse de reception.
  Future<void> rappeler({required String sessionId, required String academyId});

  Duration get cooldown;
}

// lib/core/tc_classe/port_session_persistante.dart   (Agent E)
abstract class PortSessionPersistante {
  /// La session live en cours, independamment de l'ecran affiche. null = aucune.
  Stream<SessionEnCours?> suivre();
  Future<SessionEnCours?> courante();
  /// Sortie VOLONTAIRE. Annonce la sortie au serveur AVANT de deconnecter le moteur.
  Future<void> quitter();
}

@immutable
class SessionEnCours {
  final String sessionId;
  final String groupeId;
  final String libelleGroupe;
  final SessionClockVM horloge;
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| `firstName`, `academyId`, `level` | **Vue `teacher_roster_v`** (0001:650, recréée 0005:705 **en retirant `last_name`**, 0014:868) | **EXISTE — c'est le doublon le plus probable du chantier.** Ne pas créer une vue neuve : **l'étendre** par `create or replace view` en gardant noms et types, et **lui brancher enfin un service Dart** (elle n'a aujourd'hui aucun consommateur). |
| `curriculumPath`, `currentUnit`, `activeGoals` | **rien pour l'enseignant** : `programme_*`, `progression_*`, `evaluations` sont admin-only | **NOUVEAU** → CONTRACT_REQUEST E |
| `resumePoints` | `student_reading_position` existe, **mais aucune policy n'ouvre la lecture à l'enseignant** | **Blocage serveur** → CONTRACT_REQUEST E |
| `recentAttendance` | `presence_seance_v` + `ServiceSuivi` + `VueSuiviFoyer` | **Existe, à réutiliser tel quel.** Reprendre `SortDuCours` : un cours non tenu ne s'affiche pas comme un élève absent. |
| `liveStatus` | `presence_seance_v` (état par séance et participant) | Existe — mais **pas** d'état de roster **de groupe** |
| `currentAssignments` | **rien** | **NOUVEAU** (Agent D) |
| `authorizedPedagogicalNotes` | `lesson_reports` existe, mais **lisible par son seul auteur** et `content` est un jsonb libre **sans** séparation `internal_details` / `family_summary` | **Existe partiellement** → CONTRACT_REQUEST E/H |
| Roster nommé pour l'enseignant d'un groupe | `groupe_membres` ne porte que `student_id` ; `groupe_detail()` est **admin-only et rend `student_nom`** | **NE JAMAIS ouvrir `groupe_detail()` à l'enseignant.** Créer la variante sur le modèle de `teacher_roster_v`. |

---

## 13. GuardianObservationPolicy — la politique d'observation tuteur

**Produit par :** Agent G · **Consommé par :** G, E (annonce), Q
**Chemin canonique :** `lib/core/tc_observation/guardian_observation_policy.dart`

```dart
@immutable
class GuardianObservationPolicy {
  final String policyVersion;               // obligatoire : journalise avec chaque visite
  final SourcePolitique source;             // academie | groupe | desactivee
  final bool observationActivee;            // defaut true
  final int maxVisitsPerSession;            // defaut 1
  final Duration maxTotalObservationTime;   // defaut 120 s
  final Duration? maxParVisite;             // plafond optionnel, NE CONTOURNE JAMAIS le total
  final bool microAutorise;                 // TOUJOURS false
  final bool cameraAutorisee;               // TOUJOURS false
  final bool publicationDataAutorisee;      // TOUJOURS false
  final bool admissionEnseignantRequise;    // TOUJOURS false — entree automatique
}

enum SourcePolitique { academie, groupe, desactivee }
```

### Invariants

1. **Défauts normatifs** (spec §1.1 et §11.1) : observation **activée**, **1 visite**, **120 secondes**
   totales par séance, micro **interdit**, caméra **interdite**, publication data **interdite**,
   admission enseignant **aucune**, entrée **automatique après validation serveur**.
2. `maxParVisite` peut exister, mais **ne contourne jamais** `maxTotalObservationTime`.
3. Héritage : l'Admin choisit par groupe **hériter de l'Académie**, **personnaliser** ou **désactiver**.
   La résolution se fait par **une fonction unique** côté serveur, analogue à `regle_effective()`,
   **jamais recalculée à l'écran**.
4. **La règle n'existe jamais seulement côté client.** Un compte à rebours Dart est un **affichage**.
   La borne est serveur : vérification du lien tuteur-enfant, de la session active, du groupe, de la
   policy et du quota **AVANT le token** (spec §11.4). Le client ne peut pas prolonger sa visite en
   modifiant un timer.
5. `policyVersion` est **obligatoire** et journalisé avec chaque visite.

### Port

```dart
// lib/core/tc_observation/port_politique_observation.dart   (Agent G)
abstract class PortPolitiqueObservation {
  /// Politique effective, apres resolution academie -> groupe -> desactivation. Cote serveur.
  Future<GuardianObservationPolicy> politiqueEffective({required String groupeId});

  /// Budget restant du tuteur pour CETTE seance. Verite serveur, jamais un calcul local.
  Future<BudgetObservation> budget({required String sessionId});

  Stream<BudgetObservation> suivreBudget({required String sessionId});
}

@immutable
class BudgetObservation {
  final String policyVersion;
  final int visitesUtilisees;
  final int visitesMax;
  final Duration tempsConsomme;
  final Duration tempsTotalMax;
  final Duration restant;
  final bool peutEntrer;
  final MotifRefusObservation? motifRefus;
}

enum MotifRefusObservation {
  policyDesactivee, quotaVisitesAtteint, tempsEpuise,
  lienTuteurAbsent, seanceNonActive, horsFenetre,
}
```

### Mapping vers l'existant

**Rien n'existe.** `groupes` n'a aucune colonne de politique, `rule_overrides` est scopé **profil**,
et la chaîne `policy_version` n'apparaît **nulle part** dans le dépôt.
Les défauts Académie appartiennent à `app_config` (magasin clé/valeur jsonb déjà utilisé pour des seuils
réglables sans redéploiement). La **surcharge par groupe** est la vraie nouveauté.
**NOUVEAU / BLOQUANT** → CONTRACT_REQUEST G.

Le bon patron de durée bornée et de compteur d'usage côté serveur existe : `jetons_agent` (0014),
`expire_le <= cree_le + 24h` par contrainte `CHECK`, compteur `remises`, révocation immédiate lue en base.
Et côté client, `PorteurSessionAgent` (`lib/core/agent/session_agent.dart`) : jeton en mémoire seule,
**aucune prolongation possible côté client**. **Copier ces règles, ne pas étendre `jetons_agent`** qui
sert aux agents IA.

---

## 14. GuardianSessionVisit — l'intervalle d'observation auditable

**Produit par :** Agent G · **Consommé par :** G, Q, Agent Z (vue admin)
**Chemin canonique :** `lib/core/tc_observation/guardian_session_visit.dart`

```dart
@immutable
class GuardianSessionVisit {
  final String id;
  final String sessionId;
  final String groupeId;
  final String observateurProfilId;
  final RoleObservateur role;            // tuteur | adminIncognito | adminVisible | controleur
  final String? enfantConcerneId;        // uniquement pour le tuteur
  final DateTime enteredAtUtc;
  final DateTime? leftAtUtc;             // null = visite en cours
  final Duration? durationSeconds;
  final int visitNumber;                 // 1-based, par (session, observateur)
  final String policyVersion;
  final FinDeVisite? finDeVisite;
}

enum RoleObservateur { tuteur, adminIncognito, adminVisible, controleur }
enum FinDeVisite { sortieVolontaire, quotaAtteint, seanceTerminee, revocationServeur, deconnexion }
```

### Invariants

1. Les données doivent permettre, **sans reconstruction** : la date, le nombre de visites, la **durée
   exacte** et la `policy_version`.
2. **La fermeture de l'intervalle est écrite côté serveur**, pas confiée au client.
   ⚠ Précédent à ne pas reproduire : `ServiceVideo.annoncerSortie()` **avale volontairement l'échec** —
   acceptable pour une trace, **inacceptable** si c'est ce geste qui doit fermer un quota.
3. L'incognito est invisible aux participants mais **jamais invisible à l'audit**.
4. Le Contrôleur est **incognito uniquement**, sans option visible dans ce chantier.

### Port

```dart
// lib/core/tc_observation/port_visite_observation.dart   (Agent G)
abstract class PortVisiteObservation {
  /// Demande d'entree. Le serveur verifie lien, seance, groupe, policy et quota AVANT le token.
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  });

  /// Sortie volontaire. Annonce au serveur, qui ferme l'intervalle.
  Future<void> sortir({required String sessionId});

  Future<List<GuardianSessionVisit>> visites({required String sessionId});
}

@immutable
class ResultatEntreeObservation {
  final bool autorise;
  final MotifRefusObservation? motifRefus;
  final GuardianSessionVisit? visite;
  final BudgetObservation? budget;
}

// lib/core/tc_observation/port_annonce_observation.dart   (Agent G) — consomme par E
abstract class PortAnnonceObservation {
  /// « Tuteur d'Amina observe » + temps restant. Pas de notification de sortie.
  Stream<List<AnnonceObservation>> annonces(String sessionId);
}

@immutable
class AnnonceObservation {
  final String libelle;            // « Tuteur d'Amina observe »
  final Duration? tempsRestant;
  final String? enfantConcerneId;  // pour l'indicateur discret cote enfant
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Entrée contrôleur | `rejoindre_observation(uuid)` (0012:299) | **EXISTE, complète.** **ÉTENDRE, jamais créer une troisième porte.** |
| Entrée tuteur | `assister_seance(uuid)` (0012:398) | **EXISTE.** Ne journalise pas (choix assumé) et **ne consulte aucun quota**. |
| Entrée admin | **impossible** : `rejoindre_observation` lève `insufficient_privilege` pour tout rôle ≠ `controller` ; l'enum `participant_role` n'a que 4 valeurs | **NOUVEAU** → CONTRACT_REQUEST G. ⚠ Si un rôle d'observation admin est ajouté, il faut l'ajouter aussi aux **deux** listes d'exemption de 0012 (`guard_session_participant_cap`, `guard_session_overlap`), sinon l'admin sera refusé par un déclencheur écrit pour tout autre chose. |
| Invisibilité | 4 surfaces fermées par 0012 + `est_observateur_masque()` | **EXISTE, à étendre à toute surface neuve.** Le motif est dupliqué à la main : **une surface oubliée est une fuite avec une bannière devant.** |
| Capacités (muet, sans caméra, invisible) | dérivées du **seul rôle** dans `autoriser_jeton_video` | **EXISTE.** Aucune capacité ne se calcule côté client ni en TypeScript. |
| Journal d'audit | `audit_logs` chaînée + `log_sensitive_access()` + ADM-04 | **EXISTE.** Un nouveau type d'événement apparaît automatiquement dans les filtres. **Ne pas fabriquer un second journal chaîné.** |
| Table d'intervalles requêtable | **rien** : `session_events` n'a ni `duration_seconds`, ni `visit_number`, ni `policy_version` | **NOUVEAU / BLOQUANT** → CONTRACT_REQUEST G |
| Contrôle de quota avant token | **rien** dans `autoriser_jeton_video` | **NOUVEAU / BLOQUANT** |
| TTL propre au tuteur | **rien** : TTL commun via `video_config.token_ttl_seconds` | **NOUVEAU** |

---

## 15. SessionFeedback — le micro-feedback occasionnel

**Produit par :** Agent H · **Consommé par :** H, Q
**Chemin canonique :** `lib/core/tc_parcours/session_feedback.dart`

```dart
@immutable
class SessionFeedback {
  final String id;
  final String sessionId;
  final String groupeId;
  final String questionId;               // la question posee, pour la rotation
  final ReponseFeedback reponse;
  final DateTime soumisLeUtc;
  // AUCUN champ d'identite de l'auteur dans la projection lue par l'enseignant.
}

enum ReponseFeedback { difficile, bien, tresBien }
// UI : « Difficile » / « Bien » / « Tres bien »

@immutable
class TendanceFeedback {
  final String groupeId;
  final int nombreEchantillons;
  final int seuilMinimum;                // en dessous, rien n'est montre a l'enseignant
  final bool visibleParEnseignant;       // nombreEchantillons >= seuilMinimum
  final Map<ReponseFeedback, double>? repartition; // null tant que le seuil n'est pas atteint
}
```

### Invariants

1. **Occasionnel, pas systématique.** Échantillonnage configurable. Il ne s'affiche pas après chaque
   séance.
2. **Dynamique et variable** : plusieurs questions, en rotation. Une même question ne revient qu'après
   que les autres ont été affichées.
3. **Un tap, terminé.** Aucun commentaire obligatoire.
4. **L'enseignant ne voit jamais « tel élève m'a mis telle note ».** Il voit une tendance **agrégée**, et
   **seulement après un seuil minimum d'échantillons**.
5. **Pas de leaderboard public.** Le feedback n'est qu'un **signal faible** parmi qualité, ponctualité,
   fiabilité, obligations et résultats de contrôle. **Aucun score brut utilisé seul** pour un privilège.

### Port

```dart
// lib/core/tc_parcours/port_feedback.dart   (Agent H)
abstract class PortFeedback {
  /// null = pas d'echantillonnage cette fois. L'UI n'affiche alors rien.
  Future<QuestionFeedback?> questionPour(String sessionId);
  Future<void> soumettre({required String sessionId, required String questionId,
                          required ReponseFeedback reponse});
  /// Cote enseignant : agregat seulement, et seulement au-dessus du seuil.
  Future<TendanceFeedback> tendance({required String groupeId});
}

@immutable
class QuestionFeedback {
  final String id;
  final String intitule;
  final Map<ReponseFeedback, String> libelles;
}
```

### Mapping vers l'existant

**Rien n'existe.** Aucune table `session_feedback`, aucun mécanisme d'échantillonnage.
**NOUVEAU** → CONTRACT_REQUEST H.
Le seuil d'échantillonnage appartient à `app_config` (magasin clé/valeur déjà en place).

---

## 16. StudentConcern — le signalement structuré

**Produit par :** Agent H · **Consommé par :** H, E (action de roster), Q, Agent Z (côté Admin)
**Chemin canonique :** `lib/core/tc_parcours/student_concern.dart`

```dart
@immutable
class StudentConcern {
  final String id;
  final CategorieSignalement categorie;
  final String groupeId;
  final String? sessionId;               // prerempli
  final String academyId;                // eleve concerne — identifiant, jamais un nom de famille
  final String enseignantId;             // prerempli
  final String internalDetails;          // NE PART JAMAIS automatiquement a la famille
  final String? familySummary;           // nullable ; redige ou valide avant transmission
  final StatutSignalement statut;
  final DateTime creeLeUtc;
  final DateTime? transmisLeUtc;
  final CibleTransmission? transmisA;
}

enum CategorieSignalement { pedagogique, presence, technique, changement, autre }
enum StatutSignalement { ouvert, enExamen, transmis, clos }
enum CibleTransmission { tuteurDuMineur, eleveAdulte }
```

### Invariants

1. Le contexte **séance / groupe / élève / enseignant est prérempli**. Le professeur ne retape jamais un
   identifiant.
2. **`internalDetails` et `familySummary` sont séparés.** Une note interne **ne part jamais
   automatiquement** à la famille.
3. La transmission est une **action Admin explicite**, en un clic, vers le tuteur d'un mineur ou vers
   l'élève adulte. Agent H **prépare le port** ; **il ne touche pas au panneau Admin courant**.
4. `familySummary == null` est un cas normal et doit être géré (test contractuel d'Agent Q).

### Port

```dart
// lib/core/tc_parcours/port_signalement.dart   (Agent H)
abstract class PortSignalement {
  /// Le contexte est prerempli par l'implementation, pas saisi par l'enseignant.
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  });

  Future<List<StudentConcern>> mesSignalements({String? groupeId});

  /// Preparation de l'action Admin future. Non branche en phase parallele.
  Future<void> transmettre({required String concernId, required CibleTransmission cible});
}

// lib/core/tc_parcours/port_post_cours.dart   (Agent H)
abstract class PortPostCours {
  /// Prerempli depuis presence, duree, contenu presente, position et ranges. Cible < 45 s.
  Future<PostCoursVM> preparer(String sessionId);
  Future<void> enregistrer(PostCoursVM saisie);
}

@immutable
class PostCoursVM {
  final String sessionId;
  final Duration dureeReelle;
  final List<TeacherStudentProjection> participants;   // exceptions mises en avant
  final ContentPosition? positionDeRepriseProposee;
  final List<ContentRange> rangesTravailles;
  final List<LearningAssignment> travailPropose;
  final String? notesExceptions;                        // exceptions SEULEMENT
}

// lib/core/tc_parcours/port_travail_a_venir.dart   (Agent H) — consomme par A
abstract class PortTravailAVenir {
  /// Au maximum 3 actions. L'implementation le garantit, pas l'appelant.
  Future<List<SlotAction>> avantProchainCours({required String groupeId, String? studentId});
}
```

### Mapping vers l'existant

| Élément | Existant | État |
|---|---|---|
| Pipeline demande → décision admin + audit | `matching_requests` + `demander()` + `decider_demande()` (0005) + `Demande` Dart | **La FORME existe et est le bon modèle.** ⚠ `0022_progression_suivi.sql` (5-12) **interdit** d'étendre `matching_requests` avec des clés pédagogiques. **Reprendre la forme, pas la table.** |
| `internalDetails` / `familySummary` | `lesson_reports.content` est un jsonb **libre, sans séparation** | **Existe partiellement** — la séparation est NOUVELLE |
| Cahier / notes de séance | `lesson_reports` + `makharij_findings` (0001) | **Existent depuis 0001 sans aucun écran.** ⚠ Le chantier enseignant crée déjà `lib/features/cahier/` : **coordination obligatoire via Agent Z.** Agent H ne modifie pas le cœur `lesson_reports` si une abstraction suffit. |
| Post-cours prérempli | `presence_seance_v`, `ServiceSuivi`, `mes_seances_v` | **Sources existantes à consommer** |
| Table `student_concern` | **rien** | **NOUVEAU** → CONTRACT_REQUEST H |

---

## 17. Tableau récapitulatif — producteur, consommateurs, chemin

| # | Contrat | Produit par | Consommé par | Chemin canonique | Existant |
|---|---|---|---|---|---|
| 1 | `GroupSummaryVM` | **A** | A, E, H, Q | `lib/core/tc_groupe/group_summary_vm.dart` | partiel (`groupes`, `GroupeAdmin`) |
| 2 | `GroupHomeVM` | **A** | A, H, Q | `lib/core/tc_groupe/group_home_vm.dart` | nouveau |
| 3 | `SessionClockVM` | **A** | A, E, G, H, Q | `lib/core/tc_horloge/session_clock_vm.dart` | partiel (`instant_creneau`, `Seance.avantDebut`) |
| 4 | `LibraryResource` | **B** | A, C, D, E, F, H, Q | `lib/core/tc_bibliotheque/library_resource.dart` | nouveau |
| 5 | `ResourceVersion` | **B** | C, D, F, H, Q | `lib/core/tc_bibliotheque/resource_version.dart` | patron existant (`programme_versions`) |
| 6 | `DownloadAsset` | **B** | B, H, Q | `lib/core/tc_telechargement/download_asset.dart` | nouveau |
| 7 | `ContentPosition` | **B** | C, D, E, F, H, Q | `lib/core/tc_bibliotheque/content_position.dart` | amorce (`student_reading_position`) |
| 8 | `ContentRange` | **B** | C, D, F, H, Q | `lib/core/tc_bibliotheque/content_range.dart` | nouveau |
| 9 | `SharedContentState` | **F** | C, D, E, Q | `lib/core/tc_etat_partage/shared_content_state.dart` | nouveau (droit data déjà accordé) |
| 10 | `AnnotationLayer` | **D** | C, E, F, Q | `lib/core/tc_outils/annotation_layer.dart` | nouveau |
| 11 | `LearningAssignment` | **D** | A, E, H, Q | `lib/core/tc_outils/learning_assignment.dart` | nouveau |
| 12 | `TeacherStudentProjection` | **E** | E, H, Q | `lib/core/tc_classe/teacher_student_projection.dart` | **partiel — `teacher_roster_v` existe** |
| 13 | `GuardianObservationPolicy` | **G** | G, E, Q | `lib/core/tc_observation/guardian_observation_policy.dart` | nouveau |
| 14 | `GuardianSessionVisit` | **G** | G, Q, Z | `lib/core/tc_observation/guardian_session_visit.dart` | partiel (RPC d'entrée existent) |
| 15 | `SessionFeedback` | **H** | H, Q | `lib/core/tc_parcours/session_feedback.dart` | nouveau |
| 16 | `StudentConcern` | **H** | H, E, Q, Z | `lib/core/tc_parcours/student_concern.dart` | patron existant (`matching_requests`) |

### Les ports additionnels (non-contrats), par propriétaire

| Port | Propriétaire | Chemin |
|---|---|---|
| `PortGroupes` | A | `lib/core/tc_groupe/port_groupes.dart` |
| `PortHorlogeSeance` | A | `lib/core/tc_horloge/port_horloge_seance.dart` |
| `PortCatalogue` | B | `lib/core/tc_bibliotheque/port_catalogue.dart` |
| `PortVersionsRessource` | B | `lib/core/tc_bibliotheque/port_versions_ressource.dart` |
| `PortTelechargement` | B | `lib/core/tc_telechargement/port_telechargement.dart` |
| `PortEnregistrementFichier` | B | `lib/core/tc_telechargement/port_enregistrement_fichier.dart` |
| `PortEtatOffline` | B | `lib/core/tc_telechargement/port_etat_offline.dart` |
| `ClassLibraryPicker` (surface) | B | `lib/features/tc_catalogue/class_library_picker.dart` |
| `PortCorpusCoran` | C | `lib/core/tc_coran/port_corpus_coran.dart` |
| `PortLayoutMushaf` | C | `lib/core/tc_coran/port_layout_mushaf.dart` |
| `PortNavigationCoran` | C | `lib/core/tc_coran/port_navigation_coran.dart` |
| `PortAnnotations` | D | `lib/core/tc_outils/port_annotations.dart` |
| `PortAssignations` | D | `lib/core/tc_outils/port_assignations.dart` |
| `PortDockHote` | D | `lib/core/tc_outils/port_dock_hote.dart` |
| `PortRosterEnseignant` | E | `lib/core/tc_classe/port_roster_enseignant.dart` |
| `PortRappelDiscret` | E | `lib/core/tc_classe/port_rappel_discret.dart` |
| `PortSessionPersistante` | E | `lib/core/tc_classe/port_session_persistante.dart` |
| `PortRealtimePedagogique` | F | `lib/core/tc_realtime/port_realtime_pedagogique.dart` |
| `PortEtatPartage` | F | `lib/core/tc_etat_partage/port_etat_partage.dart` |
| `PortPolitiqueObservation` | G | `lib/core/tc_observation/port_politique_observation.dart` |
| `PortVisiteObservation` | G | `lib/core/tc_observation/port_visite_observation.dart` |
| `PortAnnonceObservation` | G | `lib/core/tc_observation/port_annonce_observation.dart` |
| `PortFeedback` | H | `lib/core/tc_parcours/port_feedback.dart` |
| `PortSignalement` | H | `lib/core/tc_parcours/port_signalement.dart` |
| `PortPostCours` | H | `lib/core/tc_parcours/port_post_cours.dart` |
| `PortTravailAVenir` | H | `lib/core/tc_parcours/port_travail_a_venir.dart` |

### Le port du moteur Mushaf — signatures d'Agent C

```dart
// lib/core/tc_coran/port_corpus_coran.dart   (Agent C)
// Adaptateur LECTURE SEULE au-dessus de lib/core/coran/service_coran.dart [PROTECTED].
abstract class PortCorpusCoran {
  Future<List<SourateVM>> sourates();
  Future<PageCorpus?> page(int numeroPage);          // 1..604
  Future<PageCorpus?> pageDeAyah({required int sourate, required int ayah});
  Future<int?> pageDeDebutDeSourate(int sourate);
  Future<int?> pageDeDebutDeJuz(int juz);
  Future<List<ResultatRechercheCoran>> rechercher(String requete);
}

// lib/core/tc_coran/port_layout_mushaf.dart   (Agent C)
// La fidelite 604 pages N'EST PAS derivable des donnees actuelles (BASELINE 6.1).
// L'implementation par defaut est LayoutIndisponible : elle rend un etat EXPLICITE,
// jamais une page approximative.
abstract class PortLayoutMushaf {
  Future<DisponibiliteLayout> disponibilite();
  Future<LayoutPage?> layoutDe(int numeroPage);
}

enum DisponibiliteLayout { fidele, degrade, indisponible }
// 'indisponible' est la valeur attendue tant que verset.ligne est NULL et qu'aucun asset
// de layout n'est fourni. Agent C ne renvoie JAMAIS 'fidele' sans donnees de ligne reelles.
```

---

## 18. Ce qu'aucun contrat ne fait

- **Aucun contrat ne calcule une capacité.** Les capacités viennent du jeton serveur
  (`autoriser_jeton_video`), jamais du client ni du TypeScript.
- **Aucun contrat ne décide d'un accès.** La RLS et les vues bornées décident. Un contrat transporte.
- **Aucun contrat ne convertit un fuseau.** `instant_creneau()` le fait en base ; les horloges arrivent
  **déjà rendues**.
- **Aucun contrat ne porte un offset numérique de fuseau.**
- **Aucun contrat ne contient de commande vocale.** Il n'y a pas de moteur de commandes vocales dans ce
  produit, et il ne faut pas en construire un. Le professeur parle avec son micro normal.
