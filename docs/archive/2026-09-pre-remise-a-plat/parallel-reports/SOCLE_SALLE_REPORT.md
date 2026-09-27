# SOCLE_SALLE_REPORT

Socle partagé de la salle de cours, posé par l'**Agent Z** le 20 septembre 2026,
avant le lancement des agents métier A à E.

Base : `BASELINE_SHA = 550e605`. Périmètre : `lib/core/video/**`,
`lib/core/coran/service_coran.dart`, `lib/features/salle/**`, et les tests
correspondants.

> Ce document est le contrat de branchement de l'**agent B** (`ENS-03`, surface
> `lib/features/salle_enseignant/`). Les signatures de la section 2 sont exactes,
> copiées du code écrit. L'agent B ne touche ni au core vidéo, ni à
> `salle_page.dart`, ni à `vue_salle.dart`.

---

## 1. Ce qui a été fait

| # | Tâche | État |
| :--- | :--- | :--- |
| 1 | Contrat de « contenu présenté » : modèle, transport, reconnexion, faux de test | **fait** |
| 2 | Les cinq états réseau du protocole : `instable` et `retabli` ajoutés, `preVol` supprimé | **fait** |
| 3 | Conversion `sourate:verset` → page du mushaf, sur `ServiceCoran` + provider | **fait** |
| 4 | La scène tient six participants ; motif erroné d'ADR-004 corrigé | **fait** |
| 5 | Un seul chemin vers le pré-vol ; import `livekit_client` tranché | **fait** |
| — | L'échec antérieur de `salle_test.dart` | **remis au vert** |

---

## 2. Ce que l'agent B consomme — signatures exactes

### 2.1 Le contenu présenté

`lib/core/video/video_session_provider.dart`

```dart
/// Le sujet du canal de donnees qui porte le contenu presente.
const String sujetContenuPresente = 'contenu-presente';

@immutable
class ContenuPresente {
  const ContenuPresente({
    required this.page,
    required this.sourate,
    required this.verset,
    required this.presentePar,
    required this.emisLe,
  });

  factory ContenuPresente.depuisJson(Map<String, dynamic> json);

  final int page;
  final int sourate;
  final int verset;
  final String presentePar;
  final DateTime emisLe;

  String get reference;                    // « 2:255 »
  Map<String, dynamic> versJson();         // cles d'une lettre : p, s, v, q, t
}
```

Deux membres **nouveaux** sur `VideoSessionProvider`, qui en porte donc treize :

```dart
Stream<ContenuPresente> get contenusPresentes;
Future<void> presenterContenu(ContenuPresente contenu);
```

Ce que l'agent B doit savoir, et qui n'est pas dans la signature :

1. **`contenusPresentes` rejoue le dernier contenu connu à tout nouvel abonné.**
   Un écran remonté au milieu d'une séance retrouve la page ouverte sans attendre
   que l'enseignant la tourne à nouveau. C'est la même raison qui fait exister
   `etatCourant` à côté de `etats`.
2. **Le présentateur lit son propre contenu par ce même flux.** Il ne doit pas
   garder un état local de « page que je présente » : un seul chemin de rendu,
   donc aucune divergence entre ce qu'il croit montrer et ce qui est montré.
3. **`presenterContenu` refuse en silence** quand `acces.capacites.peutPublierDonnees`
   est faux. Un écran qui appelle sans droit ne reçoit ni erreur ni contenu.
   Corollaire pour l'UI : le bouton « Ouvrir le Coran » **n'existe pas** quand
   `vue.role != RoleSalle.enseignant`, il n'est pas grisé (règle du dépôt).
4. **Le paquet ne porte aucun texte de verset** (invariant J6). Pour afficher la
   page, l'agent B lit `ref.watch(pageCoranProvider(contenu.page))` comme le
   lecteur de l'élève, et réutilise `VueLecteur.depuis(...)`, qui est une
   fonction pure déjà testée sur 302 lignes.
5. **`presenterContenu` n'écrit JAMAIS la position de lecture d'un élève**
   (invariant J2). L'état présenté est éphémère : il vit le temps de la séance,
   dans le provider, et ne touche pas `student_reading_position`.

### 2.2 La conversion d'une référence en page

`lib/core/coran/service_coran.dart`

```dart
// sur ServiceCoran
Future<int?> pageDe(int sourate, int verset);

final FutureProviderFamily<int?, ({int sourate, int verset})> pageDuVersetProvider;
// lecture : ref.watch(pageDuVersetProvider((sourate: 2, verset: 255)))
```

`null` signifie « je ne sais pas », jamais « page 1 » : ouvrir la Fatiha devant
une classe parce qu'une requête a échoué serait pire que ne rien présenter.
La clé de famille est un **enregistrement nommé**, qui compare ses champs seul.

### 2.3 Les états de salle

`lib/core/video/video_session_provider.dart` et `lib/features/salle/vue_salle.dart`

```dart
enum EtatSalle { absent, connexion, connecte, instable, reconnexion, retabli, echec }
enum PhaseSalle { materiel, ouverture, connexion, enSalle, instable, reconnexion, retabli, refus }

// sur VueSalle
bool get dansLaSalle;   // enSalle | instable | reconnexion | retabli
```

`dansLaSalle` est le fait que l'agent B doit lire pour savoir si une commande est
active : les quatre phases qui suivent l'entrée ont en commun que **la séance
continue**. Ne pas recomposer cette condition à la main.

### 2.4 Le faux de test

`test/support/harnais.dart`, classe `FauxMoteurSalle` (aucun autre changement
dans ce fichier).

```dart
final List<ContenuPresente> contenusPresentesDemandes;   // tout ce que l'ecran a demande
ContenuPresente? get dernierContenuPresente;             // le dernier reellement publie
void publierContenu(ContenuPresente contenu);            // simule une RECEPTION
```

Le faux **rejoue le refus silencieux du vrai moteur**, lu au même endroit : les
capacités du dernier `AccesSalle` avec lequel on a rejoint. Un écran d'élève qui
présenterait serait donc rouge en test, et pas seulement en production.

> ⚠ **Piège mesuré, à ne pas repayer.** Dans un `testWidgets`, ne jamais écrire
> `addTearDown(abonnement.cancel)` sur un flux : le `cancel` est attendu après la
> sortie de la zone de temps simulé, la micro-tache qui le résoudrait n'est plus
> drainée, et **le test se bloque sans message, hors de son propre délai**
> (`--timeout 30s` ne le rattrape pas). Annuler dans le corps du test, ou lire
> `dernierContenuPresente` / `await moteur.contenusPresentes.first`.

---

## 3. Décisions

### 3.1 Le transport est le canal de données LiveKit

Décision de l'Agent 0, appliquée telle quelle. Ce qui voyage est un **pointeur**.
Le sujet est nommé (`sujetContenuPresente`) et le récepteur filtre dessus :
LiveKit laisse passer n'importe quel paquet, et un second usage du canal, un
jour, ferait ouvrir une page au hasard devant une classe.

Publication en `reliable: true`. Une page perdue est une classe qui ne suit
plus ; le mode non fiable convient à un curseur qui bouge trente fois par
seconde, pas à un tour de page.

API réelle du paquet installé, vérifiée dans le cache pub
(`livekit_client-2.12.0`) et non devinée :
`LocalParticipant.publishData(List<int> data, {bool? reliable, List<String>? destinationIdentities, String? topic})`
et `DataReceivedEvent({RemoteParticipant? participant, List<int> data, String? topic})`.

### 3.2 L'état pédagogique survit à la coupure, pas à la sortie

`_dernierContenu` vit dans le provider, dont la durée de vie est celle de
l'application — et non dans l'état d'un écran, qu'une simple rotation détruirait.

- `RoomDisconnectedEvent` **ne l'effface pas** : c'est une coupure.
- `RoomReconnectedEvent` pose `EtatSalle.retabli` puis **republie** le contenu si
  l'on est le présentateur. Le serveur n'a gardé aucun paquet : sans cela, un
  élève qui se reconnecte reste sur une salle sans page.
- `quitter()` **l'efface** : la séance est finie pour soi. C'est la seule
  différence entre « terminé » et « le réseau a lâché ».

Un paquet plus vieux que le dernier connu est **ignoré** (comparaison sur
`emisLe`) : sans ce test, deux paquets qui se croisent feraient reculer la classe
d'une page.

### 3.3 `EtatSalle.preVol` est supprimé, pas émis

Il était déclaré depuis le lot N2 et jamais posé. Le moteur temps réel
n'inspecte aucun périphérique — c'est `ServicePreVol` qui le fait — et l'attente
correspondante est déjà portée par `PhaseSalle.materiel`, dérivée de
`materielPret`. Faire émettre `preVol` par le moteur aurait été lui attribuer un
travail qui n'est pas le sien. Une valeur morte se lit comme une capacité
existante ; elle coûtait plus qu'elle ne servait.

`sessions.status = 'preflight'` en base n'est pas concerné : c'est le statut
d'une séance, pas l'état du lien d'un client.

### 3.4 `instable` vient de la qualité du lien, `retabli` de la reconnexion

`instable` est posé par le moteur quand `connectionQuality` passe à `poor` ou
`lost`, et seulement depuis `connecte` ou `retabli` : jamais depuis `reconnexion`
ni `echec`, qui en disent plus. Il redevient `connecte` dès que la qualité
remonte. **Aucune mesure maison de bande passante** n'a été ajoutée (spécification
§30) : c'est la lecture du signal que LiveKit publie déjà, celui-là même qui
pilote la dégradation de la caméra.

Chaque état porte **son mot** (invariant J7) : la pastille de l'en-tête affiche
« Connexion faible » / « Connexion perdue » pour `instable`, « Reconnexion » pour
`reconnexion`, « Réseau rétabli » pour `retabli`, « En direct » sinon. Aucune
couleur seule.

### 3.5 La scène est une galerie à partir de deux distants

Constat mesuré : la `Row` non défilante de vignettes de 96 pt demandait 624 pt
pour six participants, contre 390 pt de large sur téléphone.

- **un seul distant** → il occupe le cadre entier, exactement comme avant le
  pivot. La raison pédagogique de l'ADR-001 tient toujours : les makharij se
  lisent sur une bouche, pas sur une mosaïque ;
- **deux et plus** → une grille dont la hauteur de tuile **se déduit de la place
  réelle** au lieu d'être posée. C'est la seule façon de garantir qu'à un comme à
  six, rien ne sort de l'écran. Colonnes : 1 (deux personnes sur téléphone), 2, ou
  3 sur grand écran — lues sur `AppGabarit`, jamais sur une comparaison de
  largeur, `[RESPONSIVE]` ;
- en dessous d'un plancher de hauteur, la grille **défile** plutôt que de réduire
  les visages à rien. Au-dessus, elle ne défile pas : un geste vertical dans une
  salle doit rester sans effet ;
- **sa propre vignette reste flottante et seule**, en bas, et seulement quand la
  caméra publie (règle de la fiche produit). Se compter parmi les autres serait
  se compter comme un élève.

Aucun fichier n'a été ajouté à `lib/core/widgets/` : `test/widgets/catalogue_galerie_test.dart`
compare ce dossier à une liste tenue à la main et il est **déjà rouge**. La
galerie est un widget privé de `lib/features/salle/salle_page.dart`.

### 3.6 `voitLesParticipants` : le motif change, le droit ne change pas

L'ancien motif — « une séance est plafonnée à deux participants (ADR-004) » — est
invalide depuis le pivot. Il est réécrit, dans le code et dans son test.

**Le droit lui-même n'a pas été touché**, et c'est délibéré : donner à un mineur
la liste nominative de ses camarades est une décision de protection des mineurs,
pas un choix d'interface. Ce qui tient encore comme raison technique : le mode
enfant n'a droit qu'à deux commandes. **Décision à prendre par l'opérateur**, pas
ici. C'est la seule question de ce lot laissée ouverte à dessein.

### 3.7 Un seul chemin vers le pré-vol : `preVolProvider`

Deux chemins coexistaient : ce provider, que personne n'employait, et un appel
impératif à `servicePreVolProvider` depuis la salle. Le prochain écran en aurait
choisi un au hasard.

`preVolProvider` gagne. Son ancien commentaire était **faux** : un
`FutureProvider` non `autoDispose` ne « recalcule pas à chaque écoute », il garde
sa valeur aussi longtemps que l'application. D'où deux usages, écrits dans sa
documentation :

- **savoir** où l'on en est → `ref.watch(preVolProvider)`. C'est ce chemin que
  l'agent A doit prendre pour le préflight de la Journée ;
- **mesurer à nouveau** → `ref.refresh(preVolProvider.future)`. C'est ce que fait
  la salle à chaque entrée et à chaque « Réessayer » : un casque branché entre
  deux essais ne servirait à rien si l'on relisait le cache. Le test
  `un echec de connexion se reessaye, et relance le pre-vol` le vérifie encore
  (`verifications == 2`).

### 3.8 L'import `livekit_client` : le commentaire était faux, il est corrigé

`livekit_session_provider.dart:10` se déclarait « le seul fichier du produit
autorisé à importer `livekit_client` » alors que `pre_vol.dart:3` l'importait
depuis le lot N2. **Le commentaire est corrigé, le code n'est pas déplacé.**

La règle de l'ADR-001 porte sur le périmètre, pas sur le nombre de fichiers : le
SDK ne s'importe que sous `lib/core/video/`, jamais dans `lib/features/`. Et ce
que `pre_vol.dart` lui demande — énumérer les périphériques sur six plateformes —
est exactement ce qu'on ne doit pas réécrire : le déplacer n'aurait rien gagné, le
réécrire aurait trahi l'ADR pour de bon. La règle reste vérifiable d'un `grep` :
aucun `import 'package:livekit_client` hors de `lib/core/video/`.

---

## 4. L'échec antérieur de `salle_test.dart`, et sa cause réelle

Test : `L invisibilite du controleur se voit a l ecran / il lit deux personnes, et
ne s y trouve pas`. **Remis au vert.**

Ce n'était **pas** un défaut de la logique d'invisibilité. `VueSalle` retirait
correctement le contrôleur de sa propre liste, et le test de la fonction pure
passait. C'était un **débordement de mise en page**, levé comme exception de
rendu par `pumpAndSettle` :

```
A RenderFlex overflowed by 8.0 pixels on the bottom.
  creator: Column ← Center ← _SansImage ← ... ← _Cadre-[<'e1'>] ← SizedBox ← Row
  constraints: BoxConstraints(0.0<=w<=96.0, 0.0<=h<=128.0)
```

Le bloc « sans image » — avatar, écart de 8, légende « Sans image » — était dessiné
**à l'identique** dans le grand cadre et dans une vignette de 96×128, où il
mesurait 136 points de haut. Le contrôleur est le seul rôle dont l'écran mettait
un participant distant en vignette sans image (il n'est pas dans sa propre liste,
donc `autres` n'est pas vide), et c'est pourquoi lui seul le révélait.

Correctif : `_SansImage` prend `avecLegende`, et **la légende cède avant
l'avatar**. Dans un cadre court, l'avatar porte déjà le prénom et le cadre porte
déjà le nom en bas ; « Sans image » y était la troisième fois qu'on disait la même
chose. Elle reste annoncée aux technologies d'assistance par un `Semantics`, pour
qui rien ne se voit.

Ce défaut était donc le **même** que celui du pivot, à deux personnes au lieu de
six : une vignette de taille fixe dans laquelle on pose un contenu de taille
libre. La refonte de la scène (§3.5) le ferme dans les deux cas.

---

## 5. Vérification

Lancée depuis la racine du dépôt, par l'Agent Z, seul à écrire du Dart.

```
flutter analyze --no-pub
  → No issues found! (67,6 s)

flutter test --no-pub test/features/salle_test.dart test/video test/coran
  → 00:13 +100: All tests passed!

flutter test --no-pub          (suite complete, pour mesurer l'absence de regression)
  → 03:45 +701 -7: Some tests failed.
```

Comparaison au `BASELINE_SHA` sur exactement le même périmètre :

| | Avant | Après |
| :--- | :--- | :--- |
| `test/features/salle_test.dart` + `test/video` + `test/coran` | 82 dont **1 échec** | **100, aucun échec** |

Sur la suite complète, **708 tests dont 7 échecs**, contre 691 dont 7 au
`BASELINE_SHA`. Le compte est identique mais la composition a changé, et il faut
le dire précisément :

| Échec | Au BASELINE | Maintenant | Qui |
| :--- | :--- | :--- | :--- |
| `salle_test.dart` × 1 | rouge | **vert** | ce lot, section 4 |
| `dossier_test.dart` × 3 | rouge | rouge | agent E |
| `inscription_test.dart` × 2 | rouge | rouge | agent E |
| `catalogue_galerie_test.dart` × 1 | rouge | rouge | hors périmètre Enseignant |
| `navigation_test.dart` × 1 | **vert** | **rouge** | **pas ce lot** |

`test/router/navigation_test.dart`, « les chemins des destinations sont exactement
ceux du rôle », est devenu rouge pendant ce lot et **n'appartient pas à ce
périmètre** : il mesure `destinationsPour`, et c'est le retrait de la quatrième
destination de l'enseignant (`TEACHER_PARALLEL_BASELINE.md` §3.1, `nav_shell.dart`)
qui le casse. Ce fichier est modifié en parallèle par un autre travail du socle ;
la mise à jour du test lui revient. Aucun fichier de ce lot n'est importé par ce
test.

Les 17 tests nouveaux de ce lot couvrent : le
paquet `ContenuPresente` (aucun texte de verset, aller-retour JSON, longueur,
paquet tronqué), le refus silencieux du vrai `LiveKitSessionProvider` hors salle,
les cinq états du protocole et leurs cinq phases distinctes, `dansLaSalle`, les
mots de `instable` et `retabli` à l'écran, six participants sur 390×844 sans
rognage, la galerie qui ne s'ouvre pas à deux, la publication et la réception d'un
contenu, le refus opposé à un élève, l'abonné tardif, et la conversion
`2:255` → page.

`dart run tool/verifier_jetons.dart` : **11 violations, aucune dans le périmètre
de ce lot.** Elles portent sur `app_router.dart`, `menu_filtre.dart`,
`nav_shell.dart`, `sous_navigation_domaine.dart`, `admin_dossiers`,
`admin_journal` — six tirets cadratins, un `IconButton`, deux `onTap` nus. Dette
antérieure ou concurrente, signalée et laissée : `nav_shell.dart` est modifié en
parallèle par un autre travail du socle.

---

## 6. Clés i18n

`docs/parallel-reports/i18n_Z_salle.json` = `{}` — **aucune clé nouvelle**, et
c'est un résultat, pas un oubli. Les deux états ajoutés avaient besoin d'un mot ;
les deux existaient déjà :

| Besoin | Clé réutilisée | Texte |
| :--- | :--- | :--- |
| `instable` | `salle.lienMediocre` / `salle.lienPerdu` | « Connexion faible » / « Connexion perdue » |
| `retabli` | `reseau.retabli` | « Réseau rétabli » |

Créer `salle.instableCourt` et `salle.retabliCourt` aurait donné deux jumelles
pour le même fait, ce que l'audit signale déjà comme le risque numéro un de ce
fichier. `salle.ouvrirCoran` (« Ouvrir le Coran ») reste sans appelant : c'est à
l'agent B de l'employer, **sans en créer une jumelle**.

---

## 7. Dettes ouvertes

1. **Le droit de l'élève à la liste des participants** (§3.6) attend une décision
   de l'opérateur. Le code verrouille l'état actuel.
2. **`reglerAudioSeul` reste sans appelant.** Entièrement implémenté depuis le lot
   N2, désabonnement des pistes distantes compris, et aucun écran ne l'expose : le
   mode « économie de données » de l'ADR-001 n'a toujours pas de commande. Hors
   mission de ce lot, et d'autant plus coûteux qu'une salle de six consomme en
   réception autant qu'en émission.
3. **Aucun état `offline` propre dans la salle.** `PageImmersive` refuse
   volontairement le bandeau hors ligne, au motif que le moteur temps réel sait si
   le lien tient. Les états `instable` et `retabli` comblent une partie de l'écart
   ; la règle du dépôt (cinq états par écran) n'est pas formellement tenue. À
   arbitrer, pas à trancher ici sous peine d'ajouter un second signal concurrent.
4. **`_ListePresence`, `_Cadre`, `_Seul`, `_Galerie` restent privés** à
   `salle_page.dart`. Un agent qui afficherait des participants ailleurs les
   redupliquerait. Ils n'ont pas été promus dans `lib/core/widgets/` parce que
   `catalogue_galerie_test.dart` y est déjà rouge. Chemin de reprise : promotion le
   jour où la galerie de développement et son catalogue sont repris.
   `ponytail:` dette assumée. Plafond : duplication à la première surface hors
   `features/salle/`.
5. **Le contenu présenté ne survit pas à un redémarrage d'application**, seulement
   à une coupure réseau et à un remontage d'écran. Il vit en mémoire, par décision
   d'architecture (aucune migration dans ce lot). Si l'exigence devient « rouvrir
   l'application et retrouver la page », il faudra une table d'état de séance,
   donc une migration, donc un autre lot.
6. **Le refus de publication n'est testé que contre le faux et contre un moteur
   hors salle.** Le cas « en salle, avec un jeton sans `can_publish_data` » exige
   un serveur LiveKit : il n'est pas mesurable ici. L'expression gardée est la
   même dans les deux implémentations, ligne pour ligne, et c'est tout ce que ce
   lot peut affirmer.
7. **`_dominant` décide désormais un ordre de lecture, plus un « grand cadre ».**
   Son nom est devenu approximatif. Non renommé : il est lu par
   `test/video/vue_salle_test.dart` et par `salle_page.dart`, et un renommage
   cosmétique pendant un travail à cinq coûterait plus qu'il ne rapporte.
8. **L'arabe reste un talon.** Aucune clé n'a été ajoutée, donc rien n'a été
   aggravé, mais `strings_ar.g.dart` fait toujours 97 lignes contre 4155.
