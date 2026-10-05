# TEACHER_DUPLICATES_AUDIT

Ce que les agents A à E n'ont pas le droit de réinventer, et ce qui est déjà
dupliqué dans le dépôt.

Produit par l'**Agent 0** le 19 septembre 2026, sur la base d'un audit de neuf
zones du dépôt. Base : `BASELINE_SHA = 550e605`.

> **À quoi sert ce document.** Le protocole interdit de dupliquer un composant
> partagé existant. Une interdiction sans index est un vœu : voici l'index. Avant
> d'écrire un widget, un service, un modèle ou une clé de traduction, cherche-le
> ici.

---

## 1. Les 38 composants partagés de `lib/core/widgets/`

Constructeurs copiés du code. **Aucun agent n'ajoute de fichier dans ce
dossier** : le test `test/widgets/catalogue_galerie_test.dart` compare son contenu
à une liste tenue à la main dans la galerie, et il est **déjà rouge**.

### Gabarits de page

| Composant | Constructeur |
| :--- | :--- |
| `PageShell` | `const PageShell({required Widget child, Key? key, String? titre, Widget? entete, Widget? actions, bool defilante = true})` |
| `PageImmersive` | `const PageImmersive({required Widget child, required RegistreImmersif registre, Key? key, Widget? entete, Widget? bandeau, Widget? commandes})` — `enum RegistreImmersif { salle, lecture }` |
| `PageParcours` | `const PageParcours({required int numero, required int total, required String question, required Widget enfant, required String libelleAction, required VoidCallback? onAction, Key? key, String? explication, VoidCallback? onRetour, bool enCours = false, int? minutesRestantes, Widget? souscription})` |
| `NavShell` | voir `nav_shell.dart` — plafond de **4** destinations, assertion |
| `AdminShell` | 8 domaines, hors périmètre Enseignant |
| `SousNavigationDomaine` | `const SousNavigationDomaine({required List<({String libelle, String chemin})> onglets, required int indexActif, Key? key})` — onglets = **routes** |

### Surfaces

| Composant | Constructeur |
| :--- | :--- |
| `AppCard` | `const AppCard({required Widget child, Key? key, AppColorPair? surface, VoidCallback? onPress, String? libelleSemantique, bool selectionnee = false, bool contourFort = false, double? marge, bool dominante = false, Widget? entete, Widget? actions})` |
| `BentoTile` | `const BentoTile({required Widget child, Key? key, TailleBento taille = TailleBento.pleine, AppColorPair? surface, VoidCallback? onPress, String? libelleSemantique, bool contourFort = false})` — `enum TailleBento { pleine, demie, tiers, quart }` |
| `AppBottomSheet` | `const AppBottomSheet({required String titre, required Widget child, Key? key, Widget? actions})` + `static Future<T?> ouvrir<T>(...)` |
| `Pressable` | la surface tactile du produit, avec retour haptique. Tout ce qui se presse passe par lui |

### Lignes de liste

**Quatre existent déjà**, toutes rendues par `Pressable` et terminées par un
chevron. Un cinquième serait un doublon presque certain.

| Composant | Constructeur | Pour quoi |
| :--- | :--- | :--- |
| `SignalRow` | `const SignalRow({required String phrase, required AppIcon icone, required VoidCallback onPress, Key? key, String? anciennete, TonEtat ton = TonEtat.neutre})` | un signal actionnable, avec ancienneté |
| `SettingRow` | `const SettingRow({required String title, required AppIcon icon, Key? key, String? description, String? value, Widget? controle, VoidCallback? onPress, bool enabled = true})` | un réglage |
| `TimelineRow` | `const TimelineRow({required EntreeJournee entree, Key? key})` | une entrée de journée |
| `LignePresence` | voir `ligne_presence.dart` | une présence |

⚠ `SettingRow` et `ScheduleOption` ont une **API en anglais** (`title`,
`description`, `value`, `day`, `hours`) alors que tout le dépôt est en français.
C'est une incohérence existante : emploie-les tels quels, mais **n'imite pas ce
dialecte** dans ce que tu écris.

### États et retours

| Composant | Constructeur |
| :--- | :--- |
| `EmptyState` | `const EmptyState({required String message, Key? key, String? invitation, AppIcon? icone, String? libelleAction, VoidCallback? onAction, RegistreVide registre = RegistreVide.actionnable})` — `enum RegistreVide { actionnable, subi, bonneNouvelle }` |
| `Skeleton` | `Skeleton({required double hauteur, ...})` + `.texte`, `.liste`, `.carteEleve`, `.tuileBento`, `.ligneTimeline` |
| `OfflineBanner` | déjà porté par `PageShell` : **n'en pose pas un second** |
| `LocalFeedback` | `const LocalFeedback({required String? message, Key? key, String? libelleAnnuler, VoidCallback? onAnnuler, bool persistant = false})` |
| `StatusPill` | `const StatusPill({required String libelle, required TonEtat ton, Key? key})` — `enum TonEtat { neutre, accent, succes, avertissement, alerte } ` |
| `PermanentNotice` | **aucun paramètre**, verrou ADR-011 vérifié par `tool/verifier_jetons.dart`. Personne ne le modifie, personne n'en écrit un second |
| `BandeauObservation` | déjà posé par `lib/app.dart` au-dessus de **tous** les écrans |
| `ConfirmDestructive` | `static Future<bool> demander(BuildContext context, {required String question, required String consequence, required String libelleConfirmer, bool irreversible = false})` |

**`RegistreVide` compte.** `actionnable` quand l'usager peut agir depuis l'écran,
`subi` quand il ne peut rien y faire (« aucun cours à venir » sur `ENS-02` est
`subi`), `bonneNouvelle` quand le vide est un succès (« rien ne demande votre
attention » sur `ENS-08`).

### Actions et choix

| Composant | Constructeur |
| :--- | :--- |
| `ActionPrincipale` | `const ActionPrincipale({required String libelle, required VoidCallback? onPress, Key? key, NiveauAction niveau = NiveauAction.principale, bool enCours = false, bool pleineLargeur = true, Widget? prefixe})` — `enum NiveauAction { principale, secondaire, tertiaire, destructive }` |
| `ChoiceCardGroup` | choix **métier**, avec carte « Autre » obligatoire |
| `FilterPill` | `const FilterPill({required String libelle, required VoidCallback? onPress, Key? key, bool retenue = false, int? compteur})` — filtre **court**, en `Wrap` |
| `MenuFiltre<T>` | filtre **long**, déroulant |
| `SelecteurNiveauProgramme` | `FilterPill` groupés par cycle |
| `MenuActions` | menu d'actions secondaires |

**Arbitrage de l'Agent 0, pour couper court aux quatre façons de faire choisir
une valeur :**

- un **choix métier** qui engage (le rôle à l'inscription, le motif d'une
  exception) → `ChoiceCardGroup` ;
- un **filtre court**, deux à cinq valeurs visibles → `FilterPill` ;
- un **filtre long** → `MenuFiltre<T>` ;
- une **action** → `ActionPrincipale`, jamais une carte de choix.

### Divers

`AvatarTile`, `ChildCard`, `DataCollection` (+ `ColonneDonnees`, `RoleColonne` —
le tableau dense), `SectionHeader`, `StatTile`, `AudioLabel`, `MarquePage`,
`PinPad`, `RosaceVerset`, `ScheduleOption`, `SelecteurNiveau`,
`ConfirmDestructive`, `MenuActions`, `SousNavigationDomaine`.

`SectionHeader({required String titre, Key? key, int? compteur, String? libelleAction, VoidCallback? onAction})`
et `StatTile({required int valeur, required String libelle, Key? key, VoidCallback? onPress, TonEtat ton = TonEtat.neutre})`.

⚠ **`StatTile` est déjà contourné** : `journee_page.dart` affiche un compteur avec
`BentoTile` + `Text` alors que `StatTile` existe pour ça. Le doublon est dans le
code : ne l'étends pas, et emploie `StatTile` pour tout nouveau chiffre.

---

## 2. Les jetons de style : jamais une valeur en dur

| Famille | Accès |
| :--- | :--- |
| couleurs | `AppPalette.of(context)` — 15 paires de surface, 10 encres, 1 ombre |
| espacements | `AppSpacing.xs…respiration`, et `Ecart.vLg` / `Ecart.hMd` comme widgets |
| page | `AppPage.largeurMaxContenu`, `largeurFormulaire`, `hauteurBouton`… |
| rayons | `AppRadius.arrondiSm…arrondiFeuille` |
| élévation | `AppElevation.niveau1(palette.ombre)` |
| typographie | `Theme.of(context).textTheme`, jamais un `TextStyle` construit à la main |
| cibles tactiles | `AppMetriques.of(context).cibleTactile` (48 standard, 72 enfant) |
| gabarit | `AppGabarit.de(context)` — **seul** endroit autorisé à comparer une largeur à un nombre |
| mouvement | `AppMouvement` |
| icônes | `AppIcons.*` — **seul** fichier autorisé à construire un `IconData` |

⚠ **Trois jetons portent la même valeur** dans les deux thèmes :
`borderResting`, `borderStrong` et `inkFaint` valent tous `0xFF84798F` en clair.
Croire différencier un filet au repos d'un filet porteur de sens ne différencie
rien à l'écran. De même `surfaceRaised` == `surfaceOverlay` en thème clair.

⚠ `AppPalette.encreSecondaireSur(surface)` **ne lit pas son argument** et rend
toujours `inkMuted`. La règle « `inkFaint` est interdit sur `surfaceSunken` »
n'est donc pas outillée : elle repose sur ta vigilance.

⚠ `AdminShell.largeurBarreLaterale` vaut `288` alors que
`AppGabarit.largeurBarreLaterale` vaut `256`. Deux valeurs pour la même chose.
Hors périmètre Enseignant, mais ne recopie pas le motif.

---

## 3. Duplications déjà dans le code : ne les aggrave pas

Toutes vérifiées, avec leur emplacement.

| # | Duplication | Où | Consigne |
| :-: | :--- | :--- | :--- |
| 1 | **Formatage `HH:MM`** écrit deux fois | `journee_page.dart:386` et `core/widgets/timeline_row.dart:96` | n'en écris pas un troisième ; demande un helper partagé par `CONTRACT_REQUEST` |
| 2 | **`seuilOuvertureSalle`** (10 min, miroir de `autoriser_jeton_video`) déclaré dans un fichier d'écran | `journee_page.dart:61` | l'Agent Z le remonte en `core` ; ne le recopie pas |
| 3 | **Deux tests homonymes** `journee_test.dart` | `test/features/` (écran) et `test/planning/` (vue pure) | vérifie lequel tu ouvres |
| 4 | **Double test de chargement** dans `ENS-02` : une première charge interceptée, puis un second squelette inatteignable | `journee_page.dart:115-123` et `:169-173` | en ajoutant une source de données, ne « répare » pas le chemin mort |
| 5 | **Trois bandeaux presque identiques** | `PermanentNotice`, `BandeauObservation`, et `_Rappel` privé dans `salle_page.dart:437` | n'en écris pas un quatrième |
| 6 | **Deux chemins de lecture du pré-vol** | `servicePreVolProvider` impératif vs `preVolProvider` inutilisé | **emploie `preVolProvider`** (arbitrage Agent 0) |
| 7 | **Deux vocabulaires responsive** | `Gabarit` vs `ClasseLargeur`, dans `app_gabarit.dart` | **emploie `Gabarit`** pour ce lot |
| 8 | **Deux navigations vers une branche** | `goBranch` dans le routeur vs `GoRouter.of(context).go(...)` dans `profil_enseignant_page.dart:153,178` | depuis un écran de la coquille, laisse la barre naviguer ; n'imite pas le `go` direct |
| 9 | **Le profil enseignant a deux sources** | `ProfilEnseignantPage` recalcule depuis `seancesProvider` + `elevesEnAttenteProvider` alors que `profilEnseignantProvider` existe | branche le contrat existant ; n'en écris pas un troisième |
| 10 | **Deux constantes pour un chemin** | `Routes.compteProfils` et `Routes.compteProfilEnfant` valent la même chaîne | ne confonds pas la seconde avec une route complète |
| 11 | **Deux écrans d'historique quasi identiques** | `suivi_foyer_page.dart` et `suivi_eleve_page.dart` sur la même projection | n'en fais pas un troisième côté enseignant : ajoute un appelant à `ServiceSuivi` |
| 12 | **Repli `'Europe/Paris'` en dur six fois** | `creneaux_page.dart:208`, `disponibilites_page.dart:53`, `service_planning.dart:30,259`, `service_groupes.dart:69`, `admin_groupes/groupes_page.dart:390` | passe par `monFuseauProvider` |
| 13 | **`VerificationEnseignant` duplique `StatutPiece`** : mêmes trois valeurs SQL | `service_profil_enseignant.dart:99` vs `enums.dart:169` | emploie l'existant, n'en ajoute pas un troisième miroir |
| 14 | **Trois représentations de « où en est ce dossier »** | `AccountStatus`, `VerificationEnseignant`, `StatutPiece` — les trois écrites par `decider_dossier()` | lis `EtatDossier.etape`, qui les réconcilie déjà |
| 15 | **Le rôle de séance lu avec deux vocabulaires** | `RoleSalle.depuis()` vs littéraux `'student'`/`'teacher'` dans `vue_salle.dart:222` et `salle_page.dart:805` | hors périmètre A–E (fichiers de l'Agent Z) |

---

## 4. Concepts qui existent déjà : ne les réinvente pas

C'est la catégorie la plus coûteuse. Il ne s'agit pas de recopier du code mais de
réinventer une notion que le produit tient déjà.

| Concept | Ce qui existe | Le piège |
| :--- | :--- | :--- |
| **File hors ligne à clé d'idempotence** | `FileRapports`, `DepotRapports`, `RapportEnAttente`, table drift `RapportsEnAttente`, 146 lignes de tests. Le socle leur a donné leur implémentation (`DepotRapportsDrift`, `SoumissionCahier`) | écrire une file en mémoire pour aller vite. Le protocole exige l'idempotence, et elle est déjà prouvée |
| **Quatorze états de présence** | `EtatPresence` + `etat_presence()` en base, plus l'état `inconnu` qui n'est **pas** un quinzième état métier | poser ses propres cases « présent / absent / en retard ». Ce serait écraser la distinction `inconnu` ≠ `absente` que deux migrations et deux fichiers Dart protègent (invariant **J3**) |
| **Correction de présence** | `lib/features/presence_correction/` : contrat, panneau, quatre états de mutation, motif obligatoire, testé. **Branché à rien** | redessiner une feuille « signaler une exception » dans le cahier |
| **Construction de la timeline** | `construireJournee(...)`, quatre features l'importent | recoder un mélange cours + prières local |
| **Grille de semaine** | `GrilleSemaine`, partagée par `TUT-04` et `ENS-06` | en créer une jumelle. Et le risque inverse : **lui ajouter un paramètre** changerait silencieusement l'écran du tuteur |
| **Tri par ancienneté** | `parAnciennete(feed)` **et** `.order('depuis')` en base. La redondance est **délibérée et documentée** | la « simplifier » en supprimant l'un des deux : c'est un correctif payé |
| **Base locale drift** | `baseLocaleProvider` est le **seul** point d'ouverture propre. Il vit dans `core/appairage/profils_locaux.dart`, là où personne ne le cherche | faire `AppDatabase()` dans son propre dépôt : deux connexions sur `rewayah_local` |
| **Plafond de lecture** | `plafondSuiviFoyer = 200`, partagé par les deux lectures | reposer un plafond en dur ailleurs : la fenêtre lue divergerait de la fenêtre annoncée |
| **Compteur de rapports manquants** | calculé **deux fois** en base (`0005` et `0015`), plus une dérivation dans `anomalies_qualite()` (`0024`), plus `mes_rapports_en_attente()` (`0025`) | en ajouter un cinquième côté client |
| **Salle de cours** | un seul écran pour quatre rôles, `RoleSalle.enseignant` inclus | construire un second écran de salle faute de trouver son point d'insertion. Ce serait un second provider vidéo et une divergence du bandeau permanent |
| **Portes d'entrée en salle** | `rejoindre_observation()` (contrôleur, invisible, journalisée) et `assister_seance()` (tuteur, muet, borné au foyer). **Aucune pour l'enseignant** | copier l'une des deux : leurs gardes se contredisent par construction |
| **Écriture de présence** | webhook LiveKit (`record_session_event`, `service_role` seul) et `quitter_salle()` côté client | ajouter un battement de cœur client : l'horodatage d'un webhook est serveur et non falsifiable |
| **Attribution d'un élève** | `prendre_eleve()` (l'enseignant prend) et `attribuer_eleve()` (l'administration attribue) | en créer un troisième |

---

## 5. Paires qui coexistent **par décision** : ne les unifie pas

| Paire | Pourquoi les deux | Où c'est écrit |
| :--- | :--- | :--- |
| `teacher_student_assignments` (1-à-1) et `groupes`/`groupe_membres` | le pivot du 19/09 n'a pas encore basculé les dépendants ; la bascule exige un audit RLS complet, lot **G-02** | en-tête de `0017_groupes_pedagogiques.sql` lignes 10-16 |
| `weekly_availability` et `availability_slots` | la première est **la table vivante** ; la seconde attend les exceptions datées d'une version ultérieure | commentaire `0005:390` |
| `rule_overrides` et `progression_exceptions` | opérationnel contre pédagogique. Étendre `rule_overrides` avec des clés pédagogiques est **explicitement interdit** | en-tête de `0022` lignes 6-12 |
| `eleves_en_attente_v`, `eleves_sans_enseignant()`, `enseignants_pour()` | trois angles sur la même file, « jumelle assumée » | commentaire `0008:42` |
| l'accusé montre les deux points, puis le contrat les remontre | **voulu** par l'ADR-011 | `signature_page.dart:26-28` |
| `student_profiles.level` et `progression_historique` | texte libre contre niveau réel du programme. **Ce que l'enseignant voit aujourd'hui n'est pas le niveau institutionnel** | en-tête de `0021` lignes 4-6 |

---

## 6. Clés de traduction déjà présentes, sans appelant

En créer une jumelle donnerait deux clés pour un même libellé. Cherche dans
`assets/i18n/fr.i18n.json` avant d'en déclarer une.

| Clé existante | Pour |
| :--- | :--- |
| `salle.ouvrirCoran` | le bouton d'ouverture du Coran en salle |
| `vide.aucunRapport` | l'état vide d'une liste de rapports |
| `enseignant.journee.*` | ~25 clés déjà écrites pour `ENS-02` : prochain cours, minuteurs, timeline, élèves en attente, erreur |
| `enseignant.profil.*` | 6 clés déjà écrites pour `ENS-05` |
| `nav.enseignant.compte` | devient **orpheline** quand la quatrième destination disparaît. Laisse-la, l'Agent Z tranchera |
| `t.disponibilites.joursLongs` / `joursCourts` | lus par **sept** écrans : emploie-les, ne les renomme jamais |
| `t.commun.reessayer`, `t.commun.chargement` | les libellés communs |

---

## 7. Une hypothèse du protocole que l'audit a démentie

Le `PROMPT D` demande de ne pas créer « deux destinations globales » pour les
disponibilités et les créneaux, comme si le défaut existait.

**Il n'existe pas.** Vérifié : `destinationsPour` place « Disponibilités » dans la
liste du **tuteur** (`AppRole.guardian`) et « Créneaux » dans celle de
l'**enseignant** (`AppRole.teacher`), et le routeur les met dans deux
`StatefulShellRoute` distinctes. Un enseignant ne voit jamais deux entrées : il
n'y a rien à fusionner.

Ce qui reste vrai de l'exigence : `ENS-06` garde **deux vues locales** dans un
seul écran, et n'en fait pas deux destinations.

---

## 8. Fichiers à ne jamais toucher, quelle qu'en soit la raison

```
lib/core/widgets/permanent_notice.dart   verrou ADR-011, verifie par la CI
tool/verifier_jetons.dart                le verificateur lui-meme
lib/core/i18n/strings*.g.dart            genere, versionne, la CI refuse tout diff
lib/core/cache/db/app_database.g.dart    genere
supabase/migrations/0001..0024           une migration appliquee ne se modifie JAMAIS
supabase/config.toml                     un fournisseur absent est pousse enabled=false
supabase/functions/agent-session/        volontairement autonome, ne pas refactorer
lib/core/admin/*                         le curriculum institutionnel : lecture seule
```

Une migration déjà appliquée ne se corrige pas : la CI rejoue les fichiers dans
l'ordre sur une base neuve, et éditer un fichier ancien casse la reconstruction.
Toute correction passe par un fichier neuf.
