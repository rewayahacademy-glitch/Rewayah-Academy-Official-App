# TC_CONTRACT_REQUEST_D.md

> Agent D, Teaching Tools. Ce qui manque pour que le lot soit **complet**, et ce
> qui a ete fait en attendant. Rien ici n'a ete contourne : chaque manque a
> produit un double local **declare dans le code**, jamais une modification du
> socle.
>
> Baseline : `0071557`. Aucune migration creee (D-12). Aucune dependance ajoutee
> (D-11). Aucun fichier hors ownership modifie.

---

## 0. ERRATUM — la « collision `ContentPosition` » n'existait pas

> Une version precedente de ce document portait ici une section 1.1 affirmant
> qu'« en Dart, un constructeur nomme ne peut pas porter le nom d'un membre de
> sa classe », et citait un message `The name 'page' is already used as a class
> member`. **C'est faux, et la section a ete retiree.** La restriction de Dart
> porte sur les membres **statiques** ; un constructeur nomme peut porter le nom
> d'un champ d'instance. `const ContentPosition.page({required int page})`
> coexiste sans erreur avec `final int? page;` — reproduit et compile,
> `dart analyze` ne signale rien.
>
> Le canonique d'Agent B etait donc correct, et **rien n'etait a trancher**. Le
> stub de D avait renomme les quatre constructeurs en `.surPage` / `.surAyah` /
> `.surSection` / `.surFraction`, transforme les `const` en `factory`, retire
> `valeurSql` et `depuisSql` de `TypeAncrage`, et ajoute un membre
> `estSemantique` absent du canonique. **Tout cela a ete annule** :
> `lib/core/tc_outils/ports_externes/content_position.dart` est desormais une
> recopie a l'identique du canonique.
>
> `estSemantique` n'etait pas une addition benigne : elle etait appelee par du
> code de production (`ancrage_annotation.dart`, `couche_annotation.dart`), qui
> aurait cesse de compiler le jour ou Agent Z remplace le stub par le canonique.
> Elle vit maintenant comme **fonction libre** dans le namespace de D,
> `bool estSemantique(ContentPosition p)` dans
> `lib/core/tc_outils/ancrage_annotation.dart`. Agent B n'a donc rien a verser a
> son contrat : il reste sans comportement, comme il l'a voulu.

---

## 1. ERRATUM — `ContentRange` n'a jamais eu d'ordre a trancher

> Une version precedente de ce document portait ici une demande d'arbitrage sur
> l'ordre naturel d'un ancrage `section`, et un tableau d'options. **Il n'y
> avait rien a trancher** : le canonique d'Agent B
> (`lib/core/tc_bibliotheque/content_range.dart`) donne bel et bien le corps de
> `contient` et de `chevauche`, ainsi qu'un ordre total pour les quatre types
> d'ancrage — les sections y sont ordonnees par `_rangTexte`, un rang monotone
> tire des huit premiers caracteres de l'identifiant. Une plage de sections y
> est donc une **vraie plage**, pas seulement ses deux bornes.
>
> Le stub de D divergeait sur trois points, tous annules :
> il ajoutait un constructeur `ContentRange.ponctuelle` absent du canonique
> (AMENDEMENT 1 : « n'ajoute, ne retire et ne renomme AUCUN champ ») ; il
> portait un jeu d'assertions different, auquel manquait
> `_rang(debut) <= _rang(fin)` ; et son `contient` ne repondait vrai, sur une
> section, que sur l'egalite avec une borne — deux plages de sections se
> seraient donc comportees differemment selon le fichier utilise.
>
> `lib/core/tc_outils/ports_externes/content_range.dart` est desormais une
> recopie a l'identique du canonique, en dehors de son en-tete `TC-STUB-PORT`.
> L'unique appelant de `ContentRange.ponctuelle` (`ancrage_reflow_test.dart`)
> passe par le constructeur canonique avec `debut` et `fin` egaux. Agent B n'a
> rien a verser a son contrat.

---

## 2. `MessagePedagogique` (Agent F) n'a aucune signature

`TEACHING_CORE_CONTRACTS.md` annonce `MessagePedagogique` comme contrat produit
par Agent F (section 9, puis tableau de la section 17), mais **sa forme n'est
donnee nulle part**. Or `PortRealtimePedagogique.emettre()` la prend en
parametre : le port n'est donc pas copiable dans un stub sans elle.

**Double local ecrit par D** (`lib/core/tc_outils/ports_externes/port_realtime_pedagogique.dart`),
a confirmer ou a remplacer :

```dart
@immutable
class MessagePedagogique {
  const MessagePedagogique({
    required this.type,              // ex. 'tc.outils.trait_termine'
    required this.sessionId,
    required this.emetteurProfilId,
    required this.charge,            // Map<String, dynamic>, serialisable
    required this.emisLeUtc,         // UTC
  });
}
```

**Le risque est borne** : D ne construit un `MessagePedagogique` qu'en **un seul
endroit**, la methode `DiffusionOutils.emettre` (`evenements_outils.dart`). Si
la forme canonique differe, une seule fonction change.

**Les sept types d'evenements que D emet**, avec leur canal — c'est le contrat
que D offre a F, et il est stable :

| Type | Canal | Charge |
|---|---|---|
| `tc.outils.trait_en_cours` | **ephemere** | `trait_id`, `ancrage`, `points` (**delta seulement**), `outil`, `intention` |
| `tc.outils.trait_termine` | fiable | `couche_id`, `portee`, `trait` complet et compacte |
| `tc.outils.trait_retire` | fiable | `couche_id`, `trait_id` |
| `tc.outils.pointeur` | **ephemere** | `position` ou `null` |
| `tc.outils.marqueur` | fiable | `couche_id`, `marqueur` ou `marqueur_id` + `retire` |
| `tc.outils.focus` | fiable | `plage` ou `null` |
| `tc.outils.masquage` | fiable | `masquees`, `revelees` (**etat complet, jamais un delta** : un arrivant tardif doit se remettre a jour en un message) |

Aucune de ces charges ne porte de nom, de telephone, de courriel ni aucune
donnee de famille : uniquement des identifiants et des fractions.

---

## 3. DEMANDE SQL

> Rappel de securite a repeter dans chaque migration (D-12) :
> **(1) jamais `grant execute` a `agent_ro` sur une RPC volatile ou d'ecriture**,
> `get_advisors` ne le detecte pas ;
> **(2) toute nouvelle vue d'exposition repete le filtre d'appelant et le
> masquage `agent_identite_masquee()` colonne par colonne.**
>
> **Table existante etendue : aucune.** Verifie dans
> `TEACHING_CORE_EXISTING_MAPPING.md` section 10.5 : `annotation_layer` et
> `learning_assignment` figurent parmi les tables explicitement ABSENTES. Et
> `0022_progression_suivi.sql` (lignes 5-12) **interdit** d'etendre
> `rule_overrides` ou `matching_requests` avec des clefs pedagogiques : la forme
> attendue est un catalogue pedagogique neuf.

### 3.1 `public.annotation_layer`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` pk default `gen_random_uuid()` | |
| `resource_id` | `uuid not null` | reference la table de ressource demandee par Agent B |
| `resource_version_id` | `uuid null` | |
| `session_id` | `uuid null references public.sessions(id)` | `null` = couche personnelle hors classe |
| `auteur_profile_id` | `uuid not null references public.profiles(id)` | |
| `portee` | `text not null check (portee in ('temporaire','seance','enregistree'))` | ou un enum `public.annotation_scope` |
| `maj_le` | `timestamptz not null default now()` | |

Index unique partiel : une seule couche par
`(resource_id, session_id, auteur_profile_id, portee)`.

**Contrainte de coherence** : `portee = 'seance'` exige `session_id not null`.
Elle est deja tenue cote Dart par une assertion ; il la faut aussi en base.

**Decision proposee** : la portee `'temporaire'` **ne s'ecrit jamais en base**.
Elle vit dans le client et meurt avec l'ecran. L'ecrire creerait des lignes que
personne ne relira jamais, et un ramasse-miettes a construire pour rien.

RLS :
- l'auteur lit et ecrit **sa** couche ;
- les participants de la seance lisent les couches `portee = 'seance'` **de
  cette seance** (jointure sur `session_participants`, filtre d'appelant
  repete) ;
- aucune policy ne permet de lire la couche personnelle d'un autre ;
- aucune ecriture n'est ouverte a `agent_ro`.

### 3.2 `public.annotation_trait` et `public.annotation_marqueur`

Deux tables filles, `on delete cascade` depuis `annotation_layer`. Une table
fille plutot qu'un `jsonb` dans la couche, parce que **la gomme retire un trait
precis** et que l'annulation retire le dernier : un tableau jsonb imposerait de
relire et reecrire toute la couche a chaque geste, en concurrence avec les
autres participants.

`annotation_trait` : `id uuid pk`, `layer_id uuid not null`, `ancrage jsonb not null`
(`type_ancrage` + `page`/`sourate`/`ayah`/`section_id`/`fraction`),
`points jsonb not null` (tableau de `{x, y}` **normalises 0..1**),
`outil text check (outil in ('stylet','surligneur','gomme'))`,
`intention text null check (...)`, `pression real null`, `inclinaison real null`,
`cree_le timestamptz not null default now()`.

`annotation_marqueur` : `id uuid pk`, `layer_id uuid not null`,
`plage jsonb not null` (`debut` + `fin`),
`intention text not null check (intention in ('learn','review','reinforce','maintain','assessment'))`,
`note text null`.

**Invariant a inscrire en commentaire SQL** : *une annotation ne modifie jamais
`resource_version`. Aucune de ces trois tables ne porte de contenu de support,
et aucun `update` sur une version publiee ne doit etre declenche depuis ici.*
C'est un test contractuel annonce d'Agent Q.

### 3.3 `public.learning_assignment`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` pk | |
| `group_id` | `uuid not null references public.groupes(id)` | |
| `student_id` | `uuid null references public.profiles(id)` | `null` = tout le groupe, **cas par defaut** |
| `resource_id` | `uuid not null` | table d'Agent B |
| `resource_version_id` | `uuid null` | |
| `content_range` | `jsonb null` | `null` = la ressource entiere |
| `purpose` | `text not null check (purpose in ('learn','review','reinforce','maintain','assessment'))` | **le meme vocabulaire que les marqueurs**, jamais un second |
| `instructions` | `text null` | court |
| `starts_at` | `timestamptz not null` | |
| `due_at` | `timestamptz null` | `check (due_at is null or due_at >= starts_at)` |
| `created_by` | `uuid not null references public.profiles(id)` | |
| `status` | `text not null check (status in ('a_faire','en_cours','fait','expire','annule'))` | |

RLS :
- l'enseignant assigne au groupe (`groupes.teacher_id = auth.uid()`) ecrit et lit ;
- les membres actifs du groupe (`groupe_membres`, `left_at is null`) lisent ce
  qui les concerne : `student_id is null or student_id = auth.uid()` ;
- le tuteur du foyer lit ce qui concerne ses enfants ;
- l'admin lit ;
- **aucune vue neuve ne rend un nom de famille.** Si une projection par eleve
  devient necessaire, elle se calque sur `teacher_roster_v` : prenom et
  `immutable_id`, jamais `last_name` (ADR-008, D-08).

**Volumetrie** : trois actions au maximum sont affichees dans « Avant le
prochain cours », mais la table en contient l'historique complet. L'index utile
est `(group_id, status, due_at)`.

---

## 4. Persistance locale de la position du dock

La spec demande que la position du dock (bas / gauche / droite) soit
**memorisee localement**. Le depot n'a aujourd'hui **aucun stockage local
durable de preference** :

- `PreferencesLocales` (`lib/core/preferences/preferences_locales.dart`) porte
  un commentaire normatif : elle est **en memoire seulement**, volontairement ;
- `AppDatabase` (`lib/core/cache/db/app_database.dart`) exige une justification
  de spec **et** une migration Drift 1 -> 2 pour toute table supplementaire ;
- `flutter_secure_storage` existe, mais c'est le coffre des secrets : une
  preference d'affichage n'y a pas sa place.

**Livre par D** : `PortPositionDock` + `PositionDockMemoire` (en memoire, le
temps de la session applicative). Le contrat est pret ; il ne manque que
l'implementation durable.

**Demande a Agent Z** : trancher entre (a) une table Drift `preference_locale`
(clef, valeur) dans `AppDatabase`, qui servirait aussi aux autres agents, et
(b) l'ajout de `shared_preferences` au `pubspec.yaml`. D **n'a pas demande la
dependance** : l'option (a) n'ajoute rien et reutilise un mecanisme deja en
place.

---

## 5. Ce que D consomme d'Agent C, et qui n'existe pas

`TEACHING_CORE_FILE_OWNERSHIP.md` inscrit `PortNavigationCoran` (Agent C) parmi
les ports consommes par D, « pour l'ancrage semantique ». **Aucune signature de
ce port ne figure dans `TEACHING_CORE_CONTRACTS.md`** : la section 17 le nomme,
sans le decrire. D n'a donc pas pu le stubber.

**Ce dont D a reellement besoin**, et qui est plus petit qu'un port de
navigation : la **geometrie courante des blocs ancrables**, c'est-a-dire, pour
chaque verset ou section visible a l'ecran, le rectangle qu'il occupe **dans le
rendu du moment**.

D a donc declare cette donnee dans son propre namespace, `CarteDesBlocs`
(`lib/core/tc_outils/ancrage_annotation.dart`), et l'hote la publie par
`SupportPresente.blocs`. **Aucune methode n'a ete inventee sur le port d'Agent C.**

Proposition, a inscrire au contrat si Agent C la valide :

```dart
// lib/core/tc_coran/port_navigation_coran.dart   (Agent C)
/// La geometrie des blocs ancrables du rendu courant, pour la couche
/// d'annotation. Recalculee a chaque recomposition.
Map<ContentPosition, Rect> blocsAncrables();
```

Sans elle, les annotations d'un support rendu par Agent C ne peuvent pas suivre
le texte apres un reflow : elles retombent sur l'ancrage spatial, et **se
decalent**. C'est exactement le defaut que la spec section 8.3 demande d'eviter.

---

## 6. `PortDockHote` : signature a inscrire au contrat

`PortDockHote` est annonce comme port **produit par D** (ownership, et section
17 du contrat), mais sa signature n'est donnee nulle part. D l'a donc ecrite.
Elle est livree dans `lib/core/tc_outils/port_dock_hote.dart` et la voici, pour
qu'Agent 0 la verse au contrat et qu'Agents C, E et B ecrivent contre elle :

```dart
abstract class PortDockHote {
  ContexteDock contexte();              // groupeId, sessionId, profilId
  SupportPresente? supportActif();      // ressource, version, capacites, mode, blocs, ancrage de cadre
  SelectionSupport? selectionCourante();// plage + ancrage semantique + ancrage spatial
  CapacitesPedagogiques? capacites();   // lues du jeton serveur, jamais calculees
  Future<void> ouvrirBibliotheque();    // l'hote ouvre, le dock demande
}
```

Le sens de lecture compte : l'hote **declare**, le dock **publie** son etat
(`etatOutilsProvider`), que l'hote observe. Aucun des deux n'appelle une methode
de rendu de l'autre.

---

## 7. ICONES DEMANDEES

Huit icones manquent au catalogue `lib/core/icons/app_icons.dart`, qu'aucun
agent n'edite (D-05). Chaque emploi porte dans le code un commentaire
`// TC-ICONE: <nom souhaite>` et un **placeholder pris dans l'existant**.

| Icone souhaitee | Dessin attendu | Placeholder employe |
|---|---|---|
| `bibliotheque` | etagere de livres | `AppIcons.cahier` |
| `focus` | cible, ou cadre de recadrage | `AppIcons.recherche` |
| `marqueur` | etiquette | `AppIcons.pedagogie` |
| `masquer` | oeil barre | `AppIcons.cameraCoupee` |
| `stylet` | stylo | `AppIcons.journal` |
| `surligneur` | marqueur large | `AppIcons.pedagogie` |
| `pointeur` | main qui designe | `AppIcons.suivant` |
| `annuler` | fleche qui revient en arriere | `AppIcons.reaffectation` |
| `poigneeDock` | six points de prise | `AppIcons.menuDeroulant` |
| `revision` | fleche circulaire | `AppIcons.enAttenteEnvoi` |

Deux placeholders sont partages (`pedagogie` sert marqueur **et** surligneur) :
c'est acceptable tant qu'ils ne se cotoient pas, et ils ne se cotoient pas
aujourd'hui, mais c'est une raison de plus de livrer les vraies icones.

---

## 8. DEPENDANCE DEMANDEE

**Aucune.** Ce qui a ete essaye avec l'existant avant de conclure :

| Besoin | Ce qui a ete employe |
|---|---|
| Simplification d'une ligne polygonale | Ramer-Douglas-Peucker ecrit a la main, trente lignes (`compaction_trait.dart`). Aucun paquet de geometrie n'etait justifiable pour cela. |
| Identifiants de traits, marqueurs et travaux | `uuid 4.6.0`, deja present. |
| Detection du stylet, pression, inclinaison | `PointerDeviceKind` et `GestureDetector.supportedDevices` du framework. Aucun paquet d'encre. |
| Rendu des traits | `CustomPainter` du framework. |
| Choix ferme propose a l'utilisateur | `ChoiceCardGroup` existant (ADR-013). |
| Pilule couleur + libelle | `StatusPill` existant, qui refuse par construction une couleur sans mot. |
| Retour local apres une action invisible | `LocalFeedback` existant. |

---

## 9. JETONS DE DESIGN

**Aucun demande.** Les cinq intentions sont derivees vers `TonEtat`, le
vocabulaire ferme que `StatusPill` emploie deja, puis vers les encres du theme
(`inkAccent`, `inkMuted`, `inkSuccess`, `inkWarning`, `inkAlert`). Aucune
couleur litterale n'a ete posee : `dart run tool/verifier_jetons.dart` ne
signale aucune violation dans `lib/core/tc_outils/` ni `lib/features/tc_dock/`.

**Une dette a signaler** : la table « famille semantique -> paire douce » vit
dans `StatusPill._fond`, qui est **privee**. `CouleurIntention` derive donc vers
la famille, et laisse `StatusPill` faire le reste ; mais le peintre de la couche
d'annotation, lui, a besoin d'une couleur brute et passe par
`AppInkColor.asBorderSide().color` — le meme detour que
`AppPalette.calqueInteraction` (`app_palette.dart` ligne 224), qui en est le
precedent. Si Agent Z juge ce detour trop discret, une methode publique
`AppPalette.paireDe(TonEtat)` reglerait la question pour tout le monde.

---

## 10. Defauts pre-existants croises, NON corriges

Conformement a la consigne, ils sont signales et laisses tels quels.

1. **`dart run tool/verifier_jetons.dart` est rouge sur la baseline `0071557`** :
   10 violations, toutes hors du perimetre de D et anterieures a lui.
   `lib/core/widgets/nav_shell.dart` (2 `onTap` nus, 1 `IconButton`, 3 M-dash),
   `lib/core/widgets/menu_filtre.dart` (2 M-dash),
   `lib/core/widgets/sous_navigation_domaine.dart` (1 `onTap` nu),
   `lib/features/admin_dossiers/dossiers_page.dart` et
   `lib/features/admin_journal/journal_page.dart` (1 M-dash chacun).
   `flutter analyze lib test` est propre : ce sont des regles maison, pas des
   regles de l'analyseur.
2. **`flutter pub get` reecrit trois fichiers generes de `windows/flutter/`**
   (`generated_plugin_registrant.cc`, `.h`, `generated_plugins.cmake`). Ils ont
   ete restaures par `git checkout --` : aucun d'eux n'est dans l'ownership de
   D. Tout agent qui lance `flutter analyze` les verra apparaitre.
