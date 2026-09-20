# TC_AGENT_D_REPORT.md — Teaching Tools

> Lot D du Teaching Core : le Teaching Dock, le focus, les marqueurs, le
> masquage, le stylet et les couches d'annotation.
> Baseline `0071557`, worktree `D:\RA_TC\d`, branche `teaching-core/d-teaching-tools`.
>
> **Etat : livre et vert sur son perimetre.**
> `flutter analyze lib test` -> *No issues found*.
> `flutter test test/teaching_core/d` -> **85 tests, tous verts**.
> `git status --porcelain` -> trois repertoires, tous dans l'ownership de D.

---

## 1. Ce qui a ete construit, en une phrase

Les outils pedagogiques sont des **couches posees sur le support**, jamais des
modifications du support : un trait est une suite de fractions ancrees a un
verset, un marqueur est une metadonnee de plage, un masquage est une liste de
plages, et **aucun des trois ne touche a la ressource d'origine**.

---

## 2. Fichiers crees

### `lib/core/tc_outils/` — le domaine

| Fichier | Role |
|---|---|
| `intention_pedagogique.dart` | Les cinq intentions (contrat D), `valeurSql` + `depuisSql`. **Le seul vocabulaire d'intention du chantier** : `LearningAssignment.purpose` le reutilise. |
| `annotation_layer.dart` | `AnnotationLayer`, `PorteeAnnotation`, `TraitVectoriel`, `PointNormalise`, `OutilTrait`, `MarqueurSemantique` (contrat D, section 10). |
| `learning_assignment.dart` | `LearningAssignment`, `StatutAssignation` (contrat D, section 11). |
| `couleur_intention.dart` | La derivation **intention -> famille semantique -> encre**. Jamais l'inverse, jamais une couleur litterale. |
| `ancrage_annotation.dart` | **Le coeur du lot.** `CarteDesBlocs`, `choisirAncrage`, `resoudreTrait`, `normaliserDans`, `blocsDansPlage`, `passePres`. C'est ici que se joue la survie d'une annotation a un reflow. |
| `compaction_trait.dart` | `TraitEnCours` (paquets legers pendant le geste, version compacte a la fin) et `simplifierTrait` (Ramer-Douglas-Peucker, ecrit a la main). |
| `masquage.dart` | `PlanMasquage` : masquer, reveler, refermer, demasquer. Fonction pure. |
| `etat_outils.dart` | `OutilDock`, `PositionDock`, `EtatOutils`, `ControleurOutils` (Riverpod), `PortPositionDock` + memorisation locale. |
| `evenements_outils.dart` | Les sept evenements que D expose a Agent F, chacun portant **son** canal, et `DiffusionOutils`, seul point de contact avec le realtime. |
| `port_dock_hote.dart` | `PortDockHote`, `ContexteDock`, `SupportPresente`, `SelectionSupport`, `outilsDisponibles`. |
| `port_annotations.dart` | `PortAnnotations` (contrat D) + `AnnotationsMemoire` (double local) + provider. |
| `port_assignations.dart` | `PortAssignations` (contrat D) + `AssignationsMemoire` (double local) + provider. |
| `libelles_tc_outils.dart` | La facade de libelles `tc.outils.*` (decision D-03), chaque constante annotee `// TC-I18N:`. |
| `ports_externes/content_position.dart` | Stub d'Agent B. **Divergence declaree**, voir CONTRACT_REQUEST section 1.1. |
| `ports_externes/content_range.dart` | Stub d'Agent B. Corps de `contient`/`chevauche` ecrits localement, voir 1.2. |
| `ports_externes/library_resource.dart` | Stub d'Agent B, **volontairement partiel** : seules les `CapaciteRessource` sont employees. |
| `ports_externes/port_realtime_pedagogique.dart` | Stub d'Agent F + **double local** de `MessagePedagogique`, voir CONTRACT_REQUEST section 2. |

### `lib/features/tc_dock/` — les surfaces

| Fichier | Role |
|---|---|
| `teaching_dock.dart` | `TeachingDock` (les sept outils) et `HoteDuDock` (la reservation de place mesuree). |
| `bouton_outil.dart` | Le bouton d'outil : cible tactile du mode courant, etat retenu lisible deux fois. |
| `barre_stylet.dart` | La barre courte : stylet, surligner, gomme, annuler, plus. Pas de palette. |
| `couche_annotation.dart` | `PolitiqueSaisie` (qui ecrit, qui navigue) et `CoucheAnnotation` (capture et rendu). |
| `feuille_choix.dart` | Une feuille, trois questions : intention pour Marquer, intention pour Revision, portee pour le stylet. |
| `puce_intention.dart` | Le nom d'une intention avec sa couleur, par `StatusPill`. **Jamais la couleur seule.** |

### `test/teaching_core/d/` — 85 tests

| Fichier | Ce qu'il prouve |
|---|---|
| `ancrage_reflow_test.dart` | **Le test cle** : apres un reflow, un trait ancre semantiquement suit son verset ; un trait ancre spatialement ne bouge pas et ne couvre plus le texte. Plus : le zoom ne change rien aux donnees, un ancrage absent n'est pas peint ailleurs, un marqueur emprunte la geometrie des blocs. |
| `couche_annotation_test.dart` | Stylet contre doigt, stylet toujours autorise, doigt admis seulement sur un appareil sans stylet et outil arme ; ancrage au verset touche ; repli a la page sur mise en page figee ; signalement de l'ancrage degrade en reflowable ; gomme ; canaux ephemere puis fiable. |
| `dock_widget_test.dart` | Les sept outils, l'observateur silencieux sans aucun outil, la Bibliotheque ouverte par l'hote, focus, masquer/reveler, marquer, revision + annulation, barre du stylet, position memorisee et reprise, **le dock ne couvre jamais le contenu** (bas et gauche), rotation, cibles de l'Interface guidee, noms pour les technologies d'assistance. |
| `annotations_test.dart` | Source immuable, trois portees distinctes, fin de seance, marqueurs de plage, remplacement d'un marqueur, annuler, gomme, couche inconnue, flux. |
| `assignations_test.dart` | Creation depuis la selection sans formulaire, groupe par defaut, plafond de trois actions, tri par urgence, annulation, cloisonnement par groupe, UTC. |
| `masquage_test.dart` | Masquer, reveler sans detruire, refermer, demasquer, plages independantes, cloisonnement par ressource. |
| `compaction_trait_test.dart` | Compaction, angles preserves, paquets **delta** pendant le geste, pression moyennee et facultative, canaux et charges emises. |
| `support/hote_d.dart`, `faux/faux_dock_hote.dart`, `faux/faux_realtime.dart` | Hote de test et faux, poses sous `test/teaching_core/d/` conformement a D-06. |

---

## 3. Les invariants du lot, et ou ils sont tenus

| Invariant | Ou il est tenu | Ou il est prouve |
|---|---|---|
| La source est immuable, une annotation ne cree **jamais** une copie | `AnnotationLayer` ne porte que des identifiants ; `TraitVectoriel` ne porte que des fractions | `annotations_test.dart` |
| Donnees vectorielles **normalisees** | `PointNormalise` (0..1, relatif au bloc ancre), rien n'est stocke en pixels | `ancrage_reflow_test.dart` (zoom) |
| Paquets legers pendant le geste, version compacte a la fin | `TraitEnCours.prendrePaquet` / `.terminer` ; canaux portes par l'evenement | `compaction_trait_test.dart`, `couche_annotation_test.dart` |
| Trois portees : temporaire, seance, enregistree | `PorteeAnnotation` + `AnnotationsMemoire.fermerSeance` | `annotations_test.dart` |
| Les marqueurs sont des **metadonnees de range**, pas des dessins | `MarqueurSemantique` + `blocsDansPlage` | `annotations_test.dart`, `ancrage_reflow_test.dart` |
| Ancrage semantique prefere en mode reflowable | `choisirAncrage` + `RaisonAncrage.spatialFauteDeSemantique` | `ancrage_reflow_test.dart`, `couche_annotation_test.dart` |
| La couleur derive de l'intention, jamais l'inverse | `CouleurIntention`, aucun selecteur de couleur nulle part | `intention_couleur_test.dart` |
| Jamais la couleur seule | `PuceIntention` passe par `StatusPill`, qui exige un libelle | `intention_couleur_test.dart` |
| Stylet = encre, doigt = pan/zoom | `PolitiqueSaisie` + `GestureDetector.supportedDevices` | `couche_annotation_test.dart` |
| Pression et inclinaison facultatives | `TraitEnCours` les moyenne, `null` si absentes ; le rendu ne les exige pas | `compaction_trait_test.dart` |
| Le dock ne couvre jamais le contenu actif | `HoteDuDock` **mesure** le dock rendu et reserve sa place exacte | `dock_widget_test.dart` |
| Position memorisee localement | `PortPositionDock` | `dock_widget_test.dart` |
| Grandes cibles en Interface guidee | `Pressable` applique `AppMetriques.cibleTactile` (72 pt) | `dock_widget_test.dart` |
| D ne transporte pas les strokes | Aucun import de `lib/core/video/` dans tout le lot ; `DiffusionOutils` passe par le port de F | lecture des imports |
| Aucune commande vocale | Aucun paquet audio, aucune reconnaissance, nulle part | lecture du lot |
| Revision sans formulaire long | `FeuilleChoix` : un choix, et c'est fini | `dock_widget_test.dart` |
| Une seule Bibliotheque | Le dock **demande** l'ouverture a l'hote, il n'en construit aucune | `dock_widget_test.dart` |

---

## 4. Ce qui est mocke, et jusqu'ou

**Trois doubles locaux, tous declares dans le code et tous listes au
CONTRACT_REQUEST.** Aucun ne pretend etre plus que ce qu'il est.

1. **`AnnotationsMemoire`** — les couches vivent en memoire. Aucune table
   `annotation_layer` n'existe, et la phase parallele interdit d'en creer une.
   Consequence honnete : **une portee « enregistree » n'est pas plus durable
   qu'une portee « temporaire »** tant qu'Agent Z n'a pas branche le serveur.
   Le double applique en revanche **toutes** les regles du contrat, pour que le
   branchement soit mecanique.
2. **`AssignationsMemoire`** — meme situation pour `learning_assignment`.
3. **`MessagePedagogique`** — forme inventee localement, faute de signature
   canonique (CONTRACT_REQUEST section 2). Construit en **un seul endroit**.

Les deux providers `portAnnotationsProvider` et `portAssignationsProvider`
**levent `UnimplementedError`** par defaut. C'est volontaire : un double pose en
defaut silencieux laisserait croire, en production, que des annotations sont
enregistrees alors qu'elles disparaitraient au redemarrage.

---

## 5. Limites honnetes

1. **Les annotations ne sont pas persistees.** Voir ci-dessus. C'est le manque
   le plus lourd du lot, et il est entierement du a l'interdiction de migration.
2. **Rien n'est recu du realtime.** D **emet** ses sept evenements ; il ne les
   **applique** pas a l'arrivee. Un eleve ne verra donc pas encore le trait de
   l'enseignant : il manque le sens retour, qui appartient a Agent F (le flux)
   et a l'hote (qui l'applique). La forme des messages est prete des deux cotes.
3. **La position du dock ne survit pas a la fermeture de l'application.** Aucun
   stockage local durable n'existe dans le depot (CONTRACT_REQUEST section 4).
4. **Le dock ne se deplace pas au glisser**, il tourne entre bas, droite et
   gauche par une poignee. Un glisser-deposer aurait demande une zone de depot
   et une animation ; la poignee tient la regle (« position memorisee ») avec
   trois fois moins de code, et elle est atteignable au clavier.
5. **Une revision s'adresse toujours au groupe entier.** `LearningAssignment`
   porte `studentId`, et le port le prend, mais l'interface ne propose pas de
   choisir un eleve : la liste nominative appartient a `PortRosterEnseignant`
   (Agent E), que D ne consomme pas. Le raccordement est un branchement, pas une
   reecriture.
6. **`instructions` n'a pas de champ de saisie.** Le port l'accepte ; la feuille
   ne le propose pas, parce que la spec demande « sans formulaire long ». Si
   l'operateur veut une consigne libre, c'est un arbitrage produit.
7. **La gomme retire un trait entier**, elle ne coupe pas un trait en deux.
   C'est le comportement le plus previsible et le seul qui garde des donnees
   vectorielles simples ; une gomme « par morceaux » demanderait de decouper et
   de reecrire des traits en cours de partage.
8. **Aucun golden test.** Le peintre est teste par ses **entrees** (resolution
   des ancrages, couleurs derivees) et non par une image : un golden aurait fige
   un rendu que personne n'a encore valide visuellement, et
   `test/.../catalogue_galerie_test` est deja rouge sur la baseline.
9. **Le rendu d'un marqueur est une bande teintee sous le texte.** La puce qui
   le **nomme** (`PuceIntention`) existe, mais c'est l'hote qui decide ou la
   poser : D ne connait pas la mise en page de l'ecran d'accueil.
10. **`ContentRange` sur des sections ne sait pas comparer deux sections
    differentes** (aucun ordre n'est defini par le contrat). Documente dans le
    stub et au CONTRACT_REQUEST.

---

## 6. Ce qu'Agent Z devra brancher

1. **Les trois tables SQL** (CONTRACT_REQUEST section 3), puis remplacer
   `AnnotationsMemoire` et `AssignationsMemoire` par les implementations
   Supabase, en surchargeant les deux providers.
2. **Les deux stubs de B** (`content_position.dart`, `content_range.dart`) et le
   **stub de F** (`port_realtime_pedagogique.dart`) : les supprimer, pointer sur
   les canoniques. **Trancher d'abord la collision `ContentPosition`** (section
   1.1), qui empeche le contrat canonique de compiler.
3. **La fusion i18n** : `docs/teaching-core/i18n/tc_i18n_D.json` -> sous-arbre
   `tc.outils.*`, regeneration slang, remplacement des constantes de
   `libelles_tc_outils.dart`, suppression du fichier de facade.
4. **Les dix icones** (CONTRACT_REQUEST section 7), en un seul lot dans
   `app_icons.dart`, puis remplacement des placeholders `// TC-ICONE:`.
5. **La persistance locale de la position du dock** (section 4).
6. **Le sens retour du realtime** : brancher `PortRealtimePedagogique.messagesFiables`
   et `.messagesEphemeres` sur l'application des evenements cote eleve. Les sept
   types et leurs charges sont figes et documentes.
7. **L'insertion du dock chez ses hotes** : Agent C (`tc_mushaf`) et Agent E
   (`tc_classe_live`) implementent `PortDockHote` et enveloppent leur contenu
   dans `HoteDuDock`. **D n'a ecrit dans aucun des deux.**
8. **Aucune route a brancher.** D ne produit pas d'ecran : le dock et la couche
   sont des surfaces inserees chez un hote. Il n'y a donc **pas** de
   `routes_tc_d.dart`, et aucune destination de navigation n'est demandee.

---

## 7. Ce qui a ete reutilise plutot que recree

`lib/core/widgets/` a ete liste avant d'ecrire le moindre composant, comme
`TEACHING_CORE_EXISTING_MAPPING.md` section 9.6 l'exige.

| Besoin | Composant existant employe |
|---|---|
| Toute zone pressable | `Pressable` (et sa cible tactile par mode) |
| Choix ferme propose a l'utilisateur | `ChoiceCardGroup`, `autoriserSaisieLibre: false` |
| Feuille modale | `AppBottomSheet.ouvrir` |
| Couleur + mot d'un etat | `StatusPill` et son enum `TonEtat` |
| Retour apres une action invisible | `LocalFeedback`, avec annulation plutot que confirmation |
| Surface elevee | `AppElevation.avecFilet` (filet **et** ombre) |
| Espacements, rayons, encres, mouvement | `AppSpacing`, `AppRadius`, `AppPalette`, `AppMetriques`, `AppGabarit` |
| Patron de service et de provider | Interface + implementation + provider **dans le meme fichier**, comme les trente et un services du depot |
| Patron de `Notifier` | `PreferencesLocalesControleur` |

**Trois composants ont ete ecrits**, et aucun existant ne convenait :
`BoutonOutil` (aucun bouton d'icone compact n'existe : `ActionPrincipale` est un
bouton de page pleine largeur), `TeachingDock` / `HoteDuDock` (aucune surface
flottante n'existe) et `CoucheAnnotation` (aucune surface de trace n'existe).
`PuceIntention` n'est pas un composant neuf : c'est trois lignes au dessus de
`StatusPill`.

---

## 8. Ownership : ce qui a ete touche

```
lib/core/tc_outils/      (neuf, possede par D)
lib/features/tc_dock/    (neuf, possede par D)
test/teaching_core/d/    (neuf, possede par D)
docs/teaching-core/TC_AGENT_D_REPORT.md
docs/teaching-core/TC_CONTRACT_REQUEST_D.md
docs/teaching-core/i18n/tc_i18n_D.json
```

**Aucun autre fichier du depot n'est modifie.** `flutter pub get` a reecrit
trois fichiers generes de `windows/flutter/` : ils ont ete restaures par
`git checkout --` et ne figurent pas dans le commit.

Aucun ecrit dans `lib/core/video/`, `lib/core/coran/`, `lib/features/tc_mushaf/`,
`lib/core/theme/`, `lib/core/icons/`, `lib/core/router/`, `assets/i18n/`,
`pubspec.yaml`, `supabase/migrations/` ni `test/support/`.

---

## 9. Commandes lancees, et leur resultat

```
flutter analyze lib test          -> No issues found! (ran in 11.8s)
flutter test test/teaching_core/d -> 00:10 +85: All tests passed!
dart run tool/verifier_jetons.dart -> 10 violations, TOUTES pre-existantes
                                      et hors du perimetre de D (voir
                                      CONTRACT_REQUEST section 10)
git status --porcelain            -> 3 repertoires neufs, tous a D
```

`flutter test` sur l'ensemble du depot n'a **pas** ete relance : l'addendum de
baseline signale `test/.../catalogue_galerie_test` comme deja rouge, et le lot D
n'ajoute aucun composant a `lib/core/widgets/`.
