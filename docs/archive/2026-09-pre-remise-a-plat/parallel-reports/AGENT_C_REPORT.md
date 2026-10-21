# AGENT_C_REPORT — Pédagogie hors salle : `ENS-04` Cahier de transmission, `ENS-08` Revue de groupe

Lot « rôle Enseignant », phase parallèle. Écrit le 20 septembre 2026.

---

## 1. Les fichiers touchés, sans exception

| Fichier | Nature | Quoi |
| :--- | :--- | :--- |
| `lib/features/cahier/cahier_page.dart` | créé | `ENS-04` : l'écran, ses six états, la feuille de réglage par élève, l'adaptateur d'exception, les libellés du panneau partagé |
| `lib/features/cahier/vue_cahier.dart` | créé | la projection pure : `EtatCahier`, `VueCahier.depuis`, `ligneDePresence` |
| `lib/features/cahier/makharij.dart` | créé | le référentiel fermé des quatre paires de makharij |
| `lib/features/revue_groupe/revue_groupe_page.dart` | créé | `ENS-08` : l'écran et ses quatre états de lecture |
| `lib/features/revue_groupe/anomalies_revue.dart` | créé | `TypeAnomalieRevue`, `AnomalieRevue`, `anomaliesDuGroupe`, `anomaliesGroupeProvider` |
| `test/features/cahier_test.dart` | créé | 11 tests |
| `test/features/revue_groupe_test.dart` | créé | 7 tests |
| `docs/parallel-reports/i18n_C.json` | créé | 59 clés, sous `enseignant.cahier` et `enseignant.revue` |
| `docs/parallel-reports/CONTRACT_REQUEST_C.md` | créé | 7 demandes |
| `docs/parallel-reports/AGENT_C_REPORT.md` | créé | ce rapport |

**Hors périmètre : rien.** Aucun fichier de `lib/core/`, de
`lib/features/presence_correction/`, d'`assets/i18n/`, de `supabase/migrations/`
ni `test/support/harnais.dart` n'a été modifié. Aucune dépendance ajoutée, aucune
table ajoutée à `AppDatabase`, aucune migration écrite.

**Une seule action hors code, et il faut la lire.** Sur autorisation explicite de
l'opérateur (« pour la migration tu DOIS la faire, car supabase est connecté »),
j'ai **appliqué `0020_programme_pedagogique` à la base**. `0021` à `0024` n'ont
pas pu l'être : la couche de permissions de l'outil a refusé les appels suivants,
deux fois. Détail et conséquences au §7.

---

## 2. L'API publique exposée, aux noms exacts du contrat

```dart
// lib/features/cahier/cahier_page.dart
class CahierPage extends ConsumerWidget {
  const CahierPage({required this.seanceId, super.key});
  final String seanceId;
}

// lib/features/revue_groupe/revue_groupe_page.dart
class RevueGroupePage extends ConsumerWidget {
  const RevueGroupePage({required this.groupeId, super.key});
  final String groupeId;
}
```

Tout le reste de chaque feature est privé (`_Cahier`, `_Constat`, `_LigneEleve`,
`_FeuilleAjuster`, `_AdaptateurExceptionCahier`, `_ApresDepot`, `_Liste`,
`_Carte`), à quatre exceptions internes au dossier, toutes documentées et
consommées par mes tests : `EtatCahier`, `VueCahier`, `ligneDePresence`,
`referentielMakharij`, `libellesCorrectionCahier` (`@visibleForTesting`),
`TypeAnomalieRevue`, `AnomalieRevue`, `anomaliesDuGroupe`,
`anomaliesGroupeProvider`.

Les deux écrans se rendent depuis une route à paramètre :
`Routes.cahierPour(seanceId)` et `Routes.revuePour(groupeId)` existent déjà dans
`routes.dart`. **Je n'ai créé aucune destination de navigation globale.** Le
cahier porte son chemin de retour vers la Journée (`Routes.enseignantJournee`)
dans sa zone d'action, une fois le cahier parti et sur un cahier déjà déposé.

---

## 3. Le principe anti-burnout, et comment il est tenu

- **tout vaut « Continuer » par défaut, et le défaut ne construit rien.** Une
  entrée absente de la carte des décisions *est* la décision par défaut
  (`DecisionEleve(studentId: id)`, `confirme: true`). Le chemin nominal ne crée
  aucun objet et n'a rien à synchroniser quand le brouillon est relu ;
- **`toutEstNominal` est rendu explicitement** : une carte le dit, et le bouton
  du bas s'appelle « Tout est conforme, valider ». Un test mesure le chemin en
  **un seul tap**, de l'ouverture au dépôt — c'est la seule façon vérifiable
  d'approcher la cible des 45 secondes, que le dépôt n'avait jusqu'ici aucun
  protocole pour mesurer ;
- **les exceptions passent devant**, et elles sont les seules lignes surmontées
  d'un titre « À regarder » avec leur nombre ;
- **rien de déductible n'est redemandé** : présence, durée, unité, position de
  lecture et événements viennent de `brouillonCahierProvider`. Aucun champ de
  saisie ne les double ;
- **la durée du cahier est celle de la base.** `BrouillonCahier.dureeMinutes` est
  affichée telle quelle, avec les minutes d'interruption quand il y en a. Le dépôt
  sait calculer quatre durées pour la même séance (`fin - debut`,
  `entre_le → derniere_trace_le`, `started_at → ended_at`, `minutesInterruption`) :
  l'écran n'en calcule **aucune**, et un test vérifie qu'une durée d'horloge de 45
  min ne s'affiche pas quand la base en compte 38 ;
- **aucun compteur de rapports manquants n'est recalculé côté client** : il en
  existe déjà trois en base. Après un dépôt réussi, le cahier invalide
  `cahiersEnRetardProvider` et `brouillonCahierProvider` — il fait relire, il ne
  recompte pas.

---

## 4. Ce que l'écran n'offre pas, et pourquoi il ne l'offre pas

`DecisionEleve` est volontairement étroit, et je ne l'ai pas contourné : aucun
sélecteur de niveau, aucun changement de cycle, aucune validation de palier,
aucun appel à `poserException` / `clorerException` / `promouvoir` (la base les
refuse à un enseignant, et c'est la frontière institutionnelle du protocole).

Un bouton qui ne peut pas aboutir **n'est pas grisé, il n'est pas rendu** : une
phrase le remplace (`t.enseignant.cahier.curriculumFige`,
`t.enseignant.revue.pasDeDecision`). `UniteCurriculum.codeTechnique` n'est jamais
un titre : `nomHumain` porte le libellé, le code reste en sous-texte, et un test
compare les deux styles de texte pour le prouver.

---

## 5. Les états rendus, un par un

### `ENS-04` (six états)

| État | Où il se voit | Comment il est atteint |
| :--- | :--- | :--- |
| `loading` | `Skeleton.liste(lignes: 4)`, aucun `CircularProgressIndicator` | `FauxServiceEnseignant.delai` |
| `content` | le constat prérempli, exceptions en tête | brouillon avec participants |
| `empty` | « Le constat n'a pas pu être déduit », registre **subi**, sans bouton — et le dépôt reste offert dans la zone d'action | brouillon sans participant ni événement, ou séance introuvable (`null`) |
| `error` | phrase + « Réessayer » + « Déposer sans le constat » | `erreurLecture` sur la lecture du brouillon |
| `offline` | bandeau de `PageShell`, dépôt en file locale, `LocalFeedback(persistant: true)` « sera envoyé dès le retour du réseau », et le retour à la journée tout de suite | `FauxServiceReseau(horsLigneRendu: true)` + dépôt serveur en échec |
| `déjà déposé` | le cahier se lit, **aucun second dépôt n'est proposé**, retour à la journée | `BrouillonCahier.dejaDepose` |

Deux états de plus, non listés par la fiche mais réels : **envoi en cours**
(`ActionPrincipale(enCours: true)`, bouton inerte) et **échec d'enregistrement
local** (`LocalFeedback` non persistant, l'action reste disponible). Un échec de
file locale n'est pas un envoi manqué : le cahier n'a pas été enregistré du tout,
et l'écran ne doit pas dire qu'il partira.

### `ENS-08` (cinq états)

`loading` (squelette trois lignes), `content` (une carte par anomalie),
`empty` (« Rien ne demande votre attention. »), `error` (phrase + Réessayer),
`offline` (bandeau de `PageShell`, aucun second bandeau).

---

## 6. La vérité sur `ENS-08`, dite à l'écran et ici

Les sources des quatre anomalies (programme, progression, évaluations) sont dans
les migrations `0020` à `0024`, et **leurs policies de lecture sont toutes
`app_role() = 'admin'`**. Même toutes appliquées, un enseignant n'y aurait aucun
accès : `anomalies_qualite()` est réservée à l'administration, et **aucune RPC
d'anomalies bornée à l'enseignant n'existe**. De plus, les quatre notions —
palier, corridor, transfert, réorientation — n'existent sous aucun de ces noms en
base ; ce que `0024` calcule, c'est `rapport_manquant`, `blocage_sans_suivi` et
`evaluation_en_retard`.

Conséquence, assumée et écrite dans l'écran : **l'état vide est l'état normal et
fréquent d'`ENS-08` aujourd'hui**, et l'invitation le dit en une phrase (« Le
calcul des anomalies pédagogiques n'est pas encore ouvert aux enseignants »).
**Aucune colonne de tirets, aucun chiffre inventé, aucune section vide qui
promette un contenu** : un test vérifie qu'il n'y a ni carte, ni `—`, ni `-` dans
cet état.

La lecture réelle que l'écran fait — `mon_groupe_detail` par
`membresGroupeEnseignantProvider` — n'est pas décorative : c'est elle qui rend
l'état `error` atteignable en production (la RPC refuse un groupe qui n'est pas
celui de l'enseignant), et c'est elle qui borne les anomalies aux membres actifs
du groupe. Demander un regard sur un élève qui a quitté le groupe serait demander
un regard que l'enseignant ne peut plus porter.

**Divergence à trancher, et je la signale plutôt que de la masquer.** La fiche
`ENS-08` du catalogue écrit l'état vide « en registre **subi**, SANS bouton » ; ma
mission écrite demande `RegistreVide.bonneNouvelle`. J'ai suivi la mission
(`bonneNouvelle`), pour deux raisons : « rien ne demande votre attention » est un
résultat normal d'un groupe qui va bien, et les deux registres ne rendent de toute
façon **aucun bouton** — `EmptyState` réserve l'action au registre `actionnable`.
Un seul caractère change si le catalogue doit primer.

---

## 7. La réutilisation : ce que je n'ai pas redessiné

- **la correction de présence** : `PresenceCorrectionPanneau` est embarqué dans la
  feuille de réglage d'un élève, avec ses quatre états de mutation et sa règle de
  motif obligatoire. Je n'ai pas dessiné de feuille « signaler une exception » ;
- **les états de présence** : `EtatPresence`, `VuePresence.depuis` et
  `LignePresence`. Aucune échelle d'assiduité maison, aucune case
  « présent / absent / en retard » : `inconnu` est une exception et se dit
  « État inconnu », **jamais « Absence »** (invariant J3, mesuré par un test) ;
- **la file hors ligne** : `FileRapports`, `DepotRapports`, `SoumissionCahier`,
  `depotRapportsProvider`. Je n'ai pas écrit une seconde file. La clé
  d'idempotence est générée à la rédaction, et un test prouve que le rejeu envoie
  **la clé de la rédaction** et n'écrit **qu'une fois** ;
- les composants partagés : `PageShell`, `EmptyState`, `Skeleton`,
  `ActionPrincipale`, `AppCard`, `AppBottomSheet`, `ChoiceCardGroup`,
  `SettingRow`, `LocalFeedback`, `LignePresence`, `AppIcons.cahier`,
  `Ecart`/`AppSpacing`, `AppPalette`. Aucune couleur, aucun espacement, aucun
  rayon littéral ; aucune largeur comparée à un nombre.

---

## 8. Les tests, et ce que chacun mesure

`test/features/cahier_test.dart` — 11 tests :

1. le chemin nominal se dépose **en un seul tap**, et les deux élèves partent
   `confirme: true` sans motif ;
2. la durée affichée est celle de la base (38 min), pas celle de l'horloge (45) ;
3. une présence `inconnu` est une exception, et n'est **jamais** dite « Absence » ;
4. une exception signalée par le panneau partagé part dans le cahier avec son
   motif, et `confirme` passe à faux ;
5. `codeTechnique` reste un sous-texte, `nomHumain` porte le titre ;
6. hors ligne, le cahier est mis en file avec sa clé, le serveur ne reçoit rien,
   l'écran le dit et le retour à la journée est immédiat ;
7. le rejeu envoie la clé de la rédaction, une seule fois, et un second rejeu
   n'écrit pas ;
8. le contenu porte sa version de schéma, et une note faite d'espaces ne part pas ;
9. chargement : squelette, aucun rond qui tourne ;
10. erreur : phrase, « Réessayer », et le dépôt sans constat reste offert ;
11. vide ≠ erreur, et déjà déposé ne propose aucun second dépôt ;
12. 390 × 844 avec cinq élèves **à 200 % de taille de texte** : aucun
    débordement, bouton du bas atteignable, deux exceptions remontées devant.

`test/features/revue_groupe_test.dart` — 7 tests : l'état vide (sans bouton, sans
carte, sans tiret), le fait qu'elle ne résume pas le groupe, une carte par
anomalie avec son type dit par un mot, une anomalie visant un ancien membre qui
ne s'affiche pas, l'ordre (type puis nom), le squelette, et l'erreur qui parle au
lieu de dire « rien ne demande votre attention ».

---

## 9. Les dettes, et ce qui n'est pas fini

1. **je n'ai lancé ni `flutter analyze` ni `flutter test`** — c'est la consigne du
   lot parallèle, et c'est donc la première chose à vérifier : **rien de ce que
   j'ai écrit n'a été compilé**. Les deux points les plus susceptibles de casser
   l'analyse sont nommés au §10 ;
2. mes 59 clés n'existent pas encore dans `strings.g.dart` : jusqu'à la fusion et
   au `dart run slang` d'Agent Z, les deux écrans et leurs tests ne compilent pas.
   C'est le fonctionnement prévu du protocole, pas un oubli ;
3. **l'exception de présence ne change pas `etat_presence()`** : elle est consignée
   dans le contenu du cahier. L'écriture dans `session_presence_override` attend
   `PresenceCorrectionAdaptateurSupabase` (demande 2) ;
4. **hors ligne, une exception ne peut pas être signalée** : le panneau partagé
   masque ses actions sans réseau (demande 3). L'écran le dit, mais c'est une
   capacité perdue sur le seul écran conçu pour le hors ligne ;
5. **aucune marge n'est bornée** sur l'objectif personnel et le travail maison :
   `CleRegle` ne porte aucune clé qui le permette, et je n'ai rien inventé
   (demande 5) ;
6. `ENS-08` n'a **pas** de mise en page desktop deux panneaux (liste à gauche,
   détail à droite) : avec zéro anomalie atteignable en production, ce serait du
   code mort et non testable. La liste tient au gabarit mobile comme au gabarit
   desktop, la largeur étant déjà bornée par `PageShell` ;
7. le détail d'une anomalie se lit **dans sa carte**, il n'ouvre pas un écran :
   la fiche parle d'« ouvrir l'anomalie pour en lire le détail », et je n'ai pas
   créé de destination de plus pour un détail d'une ligne ;
8. le référentiel des makharij vit dans `lib/features/cahier/makharij.dart`, pas
   dans `core` : un seul écran le consomme. Si un second en a besoin, il remonte
   par demande de contrat — deux listes différentes de makharij seraient pires
   qu'une liste courte ;
9. **la matrice phonétique n'est pas la deuxième zone de la page**, contrairement
   à la mise en page mobile de la fiche (« constat, matrice de phonétique en puces
   géantes, note libre »). Elle est dans la feuille de réglage **de chaque élève**,
   parce que `DecisionEleve.pointPhonetique` est un champ **par élève** : une
   matrice unique posée sur la page ne saurait pas à qui attribuer le point dans un
   groupe de cinq, et le cahier de groupe est désormais la norme (pivot du
   19 septembre). Les puces restent des `ChoiceCardGroup`, donc grandes et
   tapables à une main, et la note libre est bien la dernière zone de la page. La
   divergence est à trancher : ou la fiche décrit une séance individuelle, ou le
   champ devrait être commun au groupe ;
10. la **suggestion** de travail maison n'est pas préremplie : `BrouillonCahier`
   n'en porte aucune. Le champ dit « ajustez la suggestion, ou laissez-la telle
   quelle » et part vide tant que la base n'en rend pas — aucun texte inventé.

---

## 10. Ce qu'un relecteur doit vérifier en premier

1. **que ça compile.** Trois points précis, dans l'ordre de risque :
   - `anomaliesGroupeProvider.overrideWith((Ref ref, String groupeId) async => …)`
     dans `revue_groupe_test.dart` : c'est un override de **famille** de
     providers, et aucun test du dépôt n'en fournissait de précédent. Si Riverpod 3
     veut une autre forme ici, c'est une ligne à corriger dans le test, pas dans
     l'écran ;
   - l'assertion de style du test 5 (`code.style?.fontSize ==
     textes.bodySmall?.fontSize`) suppose que le thème donne une taille explicite
     à `bodySmall` et `bodyMedium`. Le test le vérifie d'abord
     (`expect(textes.bodySmall?.fontSize, isNotNull)`), donc un échec y désignera
     le thème et non l'écran ;
   - le test à 200 % de taille de texte : un débordement y lèverait une exception
     de rendu. S'il échoue, la question à trancher est **où** ça déborde — dans ma
     carte d'élève, ou dans `LignePresence`/`StatusPill`, que je n'ai pas le droit
     de modifier.
2. **le registre de l'état vide d'`ENS-08`** : `bonneNouvelle` (mission) contre
   `subi` (catalogue), §6.
3. **l'état de la base** : `0020` appliquée, `0021`-`0024` non (§1 et demande 7).
   Rien de livré n'en dépend — `unite_curriculum()` de `0025` se garde par
   `to_regclass(...) is null` et rend `null` proprement, vérifié en lisant la
   migration — mais l'unité de curriculum restera nulle jusqu'à ce que `0021` à
   `0024` passent, et l'écran se tait alors sur le sujet au lieu d'afficher un
   champ vide.
4. **que la sortie de salle mène bien ici** : c'est le branchement d'Agent Z dans
   `salle_page.dart`, et sans lui l'écran existe sans que personne n'y arrive.
   `ENS-08` attend de même son ouverture depuis `ENS-07` ou depuis une anomalie de
   la Journée.
