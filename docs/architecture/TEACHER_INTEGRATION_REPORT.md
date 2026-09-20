# TEACHER_INTEGRATION_REPORT

Rapport d'intégration du lot **rôle Enseignant**, écrit par l'**Agent Z** le
20 septembre 2026.

Base : `BASELINE_SHA = 550e605`. À lire après
[`TEACHER_PREMERGE_REPORT.md`](TEACHER_PREMERGE_REPORT.md), qui porte l'audit de
propriété, les neuf preuves de responsabilité unique et la classification par
lot.

---

## 1. Le chiffre, avant et après

| Mesure | Avant le lot | Après | Commande |
| :--- | :--- | :--- | :--- |
| Tests | 708, dont **7 rouges** | **872, dont 1 rouge** | `flutter test --no-pub` |
| Analyse statique | `No issues found!` | **`No issues found!`** | `flutter analyze --no-pub` |
| Build web | — | **exit 0**, 316 s | `flutter build web --release` |
| Jetons maison | 11 violations | **10 violations** | `dart run tool/verifier_jetons.dart` |
| Écrans couverts en arabe et à 200 % | 20 | **24** | `test/accessibilite/` |
| Clés `enseignant.*` | 33 | **237**, 8 écrans | `assets/i18n/fr.i18n.json` |

**+164 tests**, six rouges remis au vert, un seul rouge subsistant et il précède
le lot. L'unique violation de jetons retirée est celle que mon propre changement
de navigation avait rendue fausse ; les dix autres précèdent `BASELINE_SHA`,
prouvé fichier par fichier au §6 du rapport pré-fusion et, pour
`lib/core/widgets/nav_shell.dart`, par comparaison ligne à ligne avec
`git show 550e6059:`.

---

## 2. Ce qui existe maintenant et n'existait pas

Huit écrans, dont cinq entièrement neufs, et une salle qui sait présenter le
Coran.

| Écran | État avant | État après |
| :--- | :--- | :--- |
| `ENS-01` Onboarding et bienvenue | tunnel `/attente/*` seul, bienvenue inexistante | **écran neuf**, routé, avec ses deux accusés dits séparément |
| `ENS-02` Journée | une ligne par élève, pas de préflight, pas de rapports | **une entrée par séance**, préflight, alertes rares, rapports en attente, accès contextuel au groupe |
| `ENS-03` Salle, enseignant | aucune surface de présentation | **panneau de présentation du Coran**, en un seul point d'insertion |
| `ENS-04` Cahier de transmission | inexistant | **écran neuf**, prérempli, idempotent, fonctionne hors ligne |
| `ENS-05` Profil enseignant | talon | **construit**, et il porte la déconnexion depuis ADR-027 |
| `ENS-06` Créneaux et matching | grille et feed | **refus métier lisibles**, conflits de case dits, aucune heure avant la réponse du fuseau |
| `ENS-07` Fiche groupe | inexistant | **écran neuf**, contextuel, sans nom de famille |
| `ENS-08` Revue de groupe | inexistant | **écran neuf, livré vide**, et il dit pourquoi |

---

## 3. Le branchement, ligne par ligne

Tout ce qui suit est du travail d'intégration : aucun agent métier n'y avait
accès.

### 3.1 Les quatre routes de pose

Posées dans `lib/core/router/app_router.dart`, **hors** de
`StatefulShellRoute.indexedStack` :

```dart
GoRoute(path: Routes.enseignantBienvenue,                     …BienvenueEnseignantPage())
GoRoute(path: '${Routes.enseignantSeance}/:seanceId/cahier',  …CahierPage(seanceId: …))
GoRoute(path: '${Routes.enseignantGroupe}/:groupeId',         …FicheGroupePage(groupeId: …))
GoRoute(path: '${Routes.enseignantGroupe}/:groupeId/revue',   …RevueGroupePage(groupeId: …))
```

**Hors de la coquille, et c'est le point** : une `GoRoute` posée dans une
`StatefulShellBranch` devient une destination de la barre, et la barre de
l'enseignant en tient exactement trois. Une pose s'atteint depuis un écran puis
se quitte.

Les cinq constantes vivent toutes sous `/enseignant` parce que
`prefixePour(AppRole.teacher)` vaut `'/enseignant'` et que `deciderRedirection`
renvoie chez lui tout chemin hors préfixe : **un cahier posé à `/cahier` serait
refusé à l'enseignant par sa propre garde.**

### 3.2 La navigation de niveau 1 passe de quatre destinations à trois

`lib/core/widgets/nav_shell.dart` : « Compte » est retiré. « Compte » et
« Profil » répondaient à la même question, *moi*, et sur téléphone le quatrième
onglet aurait été le seul chemin de déconnexion — donc le doublon serait revenu
par la porte de derrière. `ENS-05` porte désormais l'identité professionnelle, le
contrat, le statut **et** les réglages réellement personnels, déconnexion
comprise.

`test/router/navigation_test.dart` gèle les trois destinations, avec un
commentaire qui nomme la décision et interdit de remettre `Routes.compte`.
`nav.enseignant.compte` a été supprimée de `fr.i18n.json` : le passage à trois
l'avait laissée sans lecteur.

### 3.3 `VueSalle.peutPresenter`

Demande haute de `CONTRACT_REQUEST_B` §1. Champ ajouté sur la vue pure, dérivé de
`capacites?.peutPublierDonnees ?? false`.

**C'est la première consommation de cette capacité dans tout le dépôt** : elle
existait côté jeton depuis le lot N2, parsée depuis `can_publish_data`, et
personne ne la lisait. Elle est dérivée en booléen plutôt que d'ouvrir
l'`AccesSalle` — donc le jeton signé — à toutes les features : un booléen ne dit
que ce qui est nécessaire.

Le panneau n'apparaît donc que pour un enseignant **dont le jeton porte
réellement le droit de présenter**, plutôt que de montrer des commandes que le
moteur refuserait en silence. L'invariant J7 vaut ici comme ailleurs : un état ne
se dit jamais par l'absence de réaction.

### 3.4 Le panneau de B dans la salle des quatre rôles

Un seul point d'insertion, au slot `child:` de `PageImmersive`, exactement là où
B l'avait spécifié :

```dart
child: enImpasse
    ? _Impasse(…)
    : _panneauEnseignant(vue)
        ? _CorpsEnseignant(vue: vue, lignes: lignes, seanceId: widget.seanceId)
        : _Corps(vue: vue, lignes: lignes),
```

Le rôle vient du **jeton** (`vue.role`), jamais de `sessionProvider.role`.

#### Ce que la mesure a imposé, et que la composition suggérée ne prévoyait pas

La composition proposée par B — `Row(Expanded(panneau), Expanded(_Corps))` au
grand gabarit, `Column(flex 3, flex 2)` sur téléphone — **a fait échouer dix
tests de `salle_test.dart`**, et la cause est arithmétique :

- à 800 de large, couper la largeur en deux donne 272 points à `_Corps`, qui en
  réserve **256 fixes** à sa colonne de présence : il reste **seize points** à la
  scène. Tout débordait ;
- le partage en fractions de la **hauteur** ne marchait pas non plus : deux états
  du panneau ne défilent pas d'eux-mêmes — ce sont des `EmptyState`, donc un
  `Center` sur une colonne de taille minimale — et le plus haut demande 464
  points quand trois cinquièmes de la place en offraient 269.

La correction n'a pas été d'ajuster les fractions, parce qu'une fraction repose
la question à chaque gabarit et à chaque échelle de texte. Elle a été :

1. **le côté à côte n'arrive qu'au desktop**, en trois colonnes explicites
   (document, scène, présence) plutôt qu'en imbriquant `_Corps` dans une
   demi-largeur ;
2. **un plancher, pas une fraction** : le document prend tout ce qui reste sous
   une bande de scène fixe, sans jamais descendre sous huit respirations. Le même
   idiome que `_Galerie._hauteurPlancher`, déjà dans ce fichier ;
3. **la bande de scène vaut trois respirations et non deux** — le plancher de la
   galerie — parce que la vignette locale flotte à deux respirations de haut et se
   pose à `lg` du bord : une bande au plancher exact la ferait déborder de sa
   propre marge ;
4. **un `SingleChildScrollView` toujours posé**, qui ne défile que s'il le faut.
   Quand la place suffit, la colonne fait exactement la hauteur offerte et rien
   ne bouge. C'est ce qui met l'échelle de texte à 200 % hors de danger : le
   contenu grandit, la colonne défile, rien ne se rogne.

**Les dix tests sont revenus au vert sans qu'un seul test soit modifié.** C'était
bien la mise en page, et non les garanties.

#### Un effet de bord évité

La première correction retirait la colonne de présence à l'enseignant au gabarit
tablette, faute de largeur. Elle cassait quatre tests, et pour une bonne raison :
`_colonneOuverte` servait **aussi** à décider si l'en-tête offre le bouton
« voir la présence ». L'enseignant se retrouvait sans colonne *et* sans bouton —
sa présence devenait injoignable.

La réponse est une fonction unique, `_colonneDePresence`, que les deux côtés
lisent, et la présence de l'enseignant est posée **dans sa colonne à tous les
gabarits** : sa colonne défile, elle a donc la place que `_Corps` n'a pas en
largeur. C'est la bonne réponse pour lui, et pas un effet de bord : savoir qui
manque est la première chose qu'on regarde en ouvrant un cours de groupe.

### 3.5 La sortie de salle mène au cahier

L'écart inscrit dans `salle_page.dart` depuis le lot N3 — « `ENS-04` n'a pas de
route, on renvoie donc chez soi » — est **levé**.

```dart
final bool versLeCahier = vue.role == RoleSalle.enseignant && vue.dansLaSalle;
…
if (versLeCahier) {
  GoRouter.of(context).go(Routes.cahierPour(widget.seanceId));
  return;
}
_rentrer();
```

Trois décisions portées par ces quatre lignes :

- **`vue` est passée à `_quitter`, pas relue** : la décision se prend sur l'état
  d'AVANT la déconnexion. Après `_moteur.quitter()`, la phase est retombée et
  `dansLaSalle` serait faux pour tout le monde ;
- **`dansLaSalle` et pas seulement le rôle** : un enseignant qui renonce pendant
  que la salle s'ouvre n'a pas fait cours. Lui demander son cahier serait lui
  demander le récit d'un cours qui n'a pas eu lieu — et le déposer consommerait
  la clé d'idempotence de la vraie séance ;
- **`go` et non `push`** : la salle ne doit rester sous aucune pile, l'ADR-005
  lui interdit d'être revenue en arrière.

Deux tests neufs le mesurent dans `salle_test.dart` : l'enseignant qui a fait
cours sort vers **son** cahier, avec l'identifiant de la séance qu'il vient de
quitter ; celui qui n'est jamais entré rentre chez lui, sans cahier.

### 3.6 `seuilOuvertureSalle` remonté en `core`

De `journee_page.dart` vers `lib/core/video/pre_vol.dart`, à côté du pré-vol :
les deux répondent à la même question, « ce geste peut-il aboutir maintenant ? ».
L'un interroge le matériel, l'autre l'horloge, et un écran qui offre d'entrer en
salle a besoin des deux réponses.

Effet de bord utile : le bloc `///` de tête de `journee_page.dart` décrivait
l'écran mais était **attaché à la constante**. En la sortant, il se serait
attaché au `_maximumAlertes` suivant ; il est devenu une documentation de
bibliothèque (`library;`) en tête de fichier, où il décrit ce qu'il décrit.

### 3.7 Deux services remontés en `core`

`service_acceptations.dart` et `service_declaration.dart`, de
`lib/features/profil_enseignant/` vers `lib/core/profil/`.

Ils étaient nés dans la feature parce que c'était le seul endroit où l'agent E
pouvait écrire, et ils y étaient **la seule entorse architecturale du lot** : deux
services parlant à Supabase depuis un dossier d'écran, ce qu'aucun autre service
du dépôt ne fait. Après la remontée, le balayage de `Supabase.instance` ne trouve
**plus aucun client hors de `lib/core/`**.

### 3.8 Les chaînes

Six files d'attente fusionnées dans `assets/i18n/fr.i18n.json`, puis
`dart run slang`. **237 clés sous `enseignant.*`**, réparties en huit écrans :
`bienvenue` 17, `journee` 45, `salle` 21, `cahier` 59, `profil` 51, `creneaux`
19, `ficheGroupe` 15, `revue` 10. JSON validé avant génération.

Sept clés orphelines supprimées, après avoir vérifié qu'aucun appelant écrit à la
main ne subsistait — seul le fichier généré les citait encore. Deux exceptions de
convention notées plutôt que corrigées, parce que les corriger sortirait du lot :
`ENS-07` lit deux libellés sous `t.admin.groupes.*`, et `ENS-06` porte deux
namespaces. Détail au §5.4 du rapport pré-fusion.

---

## 4. La preuve du chemin de bout en bout

`test/router/parcours_enseignant_test.dart`, **12 tests, écrits pour ce rapport**.

Ils montent l'application sur son **vrai** routeur — `ref.read(routeurProvider)`,
pas une copie de test — et marchent le chemin. C'est ce qui fait qu'un test
échouerait si une route manquait à `app_router.dart`.

Ce qu'ils prouvent, et qu'aucun test d'écran ne pouvait voir :

| Fait | Comment |
| :--- | :--- |
| les sept étapes rendent leur écran | une route par étape, du bienvenue au cahier |
| le parcours s'enchaîne sans remonter à la racine | les sept sauts faits l'un après l'autre sur la **même** instance de routeur, en vérifiant `matchedLocation` à chacun |
| la barre tient trois destinations | les trois libellés présents sur `ENS-02` |
| une pose ne fait pas apparaître la barre | ni `NavigationBar` ni `NavigationRail` sur le cahier — une barre y offrirait de partir ailleurs sans avoir déposé son compte rendu |
| la garde tient sur les poses | un tuteur qui demande le cahier repart chez lui ; un enseignant en attente de KYC ne voit aucune pose, pas même la fiche d'un groupe d'enfants |

La leçon qui a rendu ce fichier nécessaire est dans la mémoire du projet :
**« brancher l'entrée, pas seulement la route »** — un écran sans navigation qui
l'expose n'existe pas. Un lot peut livrer huit écrans parfaits et n'en rendre
aucun atteignable, et aucun test d'écran ne le dirait.

Le maillon « salle » du chemin est mesuré séparément, dans `salle_test.dart`
(§3.5) : la salle vit hors de l'arbre de navigation et s'atteint par un billet
(ADR-005).

---

## 5. QA UX : ce qui est mesuré, et ce qui ne l'est pas

| Axe | Couverture | Où |
| :--- | :--- | :--- |
| **mobile 390×844** | les huit écrans | tests de chaque agent, plus `salle_test.dart` pour la salle à six participants |
| **tablette, desktop** | les huit écrans | `catalogue_galerie_test.dart` aux trois largeurs pour les composants ; `_CorpsEnseignant` aux trois gabarits |
| **échelle de texte 200 %** | **24 écrans** | `test/accessibilite/rtl_echelle_texte_ecrans_test.dart`, compte gelé à 24 |
| **RTL / arabe** | **24 écrans** | idem — le compte gelé est ce qui empêche d'oublier un écran neuf en silence |
| **loading / empty / error / offline** | les huit écrans | rapports de chaque agent, état par état |
| **clavier, Échap sur modale** | composants partagés | `test/accessibilite/clavier_test.dart` |
| **thème clair / sombre** | non mesuré écran par écran | `AppTheme.pour(mode, Brightness.*)` est la seule source ; la galerie le couvre au niveau composant |

Le compte gelé est passé de 20 à 24 : les quatre écrans neufs (`ENS-01`,
`ENS-04`, `ENS-07`, `ENS-08`) y sont entrés, et `ENS-02` a reçu le
`FauxServiceEnseignant` qui lui manquait depuis le pivot — sans lui, il ne rendait
que son état d'erreur et la garantie RTL ne portait que sur une phrase d'échec.

`ENS-03` n'y figure pas, et ce n'est pas un oubli : ce n'est pas une destination
mais une surface immersive atteinte par un billet, et ses quatre rôles sont
mesurés par `salle_test.dart` et `salle_enseignant_test.dart`, y compris à 390 sur
844 et à 200 %.

---

## 6. Les invariants métier, et où chacun se mesure

| Invariant | Mesure |
| :--- | :--- |
| **J3** : `inconnu` n'est pas `absente` | `journee_test.dart` (« une presence inconnue ne s annonce pas comme une absence ») et `salle_test.dart` |
| **J6** : aucun texte de verset dans un paquet | le contenu présenté est un **pointeur** (`page`, `sourate`, `verset`), clés d'une lettre. `modeles_video_test.dart` |
| **J7** : un état ne se dit jamais par la couleur seule | `StatusPill` partout, et `peutPresenter` plutôt qu'un bouton que le moteur refuse en silence |
| **C9** : idempotence du cahier | `lesson_reports_idempotency_unique` en base ; un rejeu lève `23505` que le service traite en succès. `cahier_test.dart` |
| **ADR-005** : la salle n'est ni partageable ni marque-page | la sortie fait `go` et non `push` ; le billet est exigé par `deciderRedirection` |
| **ADR-008** : aucun nom de famille chez l'enseignant | balayage du dépôt (§3 du rapport pré-fusion, preuve 9) **et** mesure à l'exécution dans `creneaux_test.dart` |
| **ADR-011** : le bandeau permanent n'a aucune prise | `permanent_notice_test.dart` ; le panneau de B ne l'entoure ni ne le double |
| **ADR-027** : trois destinations | `navigation_test.dart`, gelé |
| **ADR-028** : le groupe est la norme | une entrée par séance sur `ENS-02`, mesurée par la déduplication de séance de groupe |
| **anti-burnout** : moins d'une minute avant, moins de 45 s après | le cahier est **prérempli** : aucune saisie manuelle pour une donnée déductible. Le préflight répond avant le geste, pas après |

---

## 7. Ce qui reste, et à qui

### Ce qui bloque quelqu'un d'autre

1. **`0029_fermeture_dossiers_en_attente_anon.sql` est écrite et non appliquée.**
   Le classificateur a refusé l'appel. Tant qu'elle n'est pas passée,
   `public.dossiers_en_attente()` livre à un appelant **anonyme** le prénom, le
   **nom de famille** et l'identifiant immuable de toute personne en attente de
   vérification — mesuré, 4 lignes. C'est antérieur à ce lot, mais c'est vivant.
   Détail et preuve au §7.2 du rapport pré-fusion.
2. **`0021` à `0024` ne sont pas appliquées.** Conséquence bornée et déjà
   documentée : `unite_curriculum()` rend nul, donc le bloc curriculum du cahier
   reste vide. La fonction est gardée de façon à s'allumer toute seule le jour où
   les tables existent.
3. **Cinq composants de `lib/core/widgets/` n'ont pas d'entrée de galerie**, ce
   qui garde `catalogue_galerie_test.dart` rouge et interdit d'ajouter un
   composant partagé. Antérieur, prouvé, et c'est un lot à lui seul : chaque
   entrée serait soumise à une dizaine de tests de rendu.

### Décisions qui n'appartiennent pas à un agent

Cinq, listées au §5.1 du rapport pré-fusion : retrait d'une disponibilité
engagée, inventaire des fuseaux, « correction demandée » contre « refusé », droit
de l'élève à la liste des participants, nature de `student_profiles.level`.

### Dettes de socle, dans l'ordre où elles se paieront

`mes_anomalies_groupe()` — c'est elle qui remplit `ENS-08`, et **seul son provider
changera**. Puis `PresenceCorrectionAdaptateurSupabase`, les deux accusés
séparément opposables d'ADR-011, le champ de groupe sur `EntreeJournee`, un
`errcode` stable sur `prendre_eleve()`. Les quinze autres sont au §5 du rapport
pré-fusion.

### Le seul libellé bancal du lot

Une séance **individuelle** antérieure au pivot (`groupe_id` nul) affiche
« Cours avec Cours individuel » dans la colonne de la journée : `TimelineRow` est
partagé par trois rôles et raisonne encore en élève unique. Il disparaît avec le
champ de groupe sur `EntreeJournee` (`CONTRACT_REQUEST_A` §2).

---

## 8. Conditions de fusion du `PROMPT Z`, phase 9

| Condition | État |
| :--- | :--- |
| analyse verte | ✅ `No issues found!` |
| tests verts | ⚠️ **871 / 872** — l'unique échec prouvé antérieur à `BASELINE_SHA` |
| build réussi | ✅ `flutter build web --release`, exit 0 |
| E2E réussi | ✅ `parcours_enseignant_test.dart`, 12 tests sur le routeur réel |
| zéro BLOCKER | ✅ |
| zéro duplication fonctionnelle connue | ✅ neuf preuves mesurées |

**Aucun conflit Git n'a été résolu en choisissant « ours » ou « theirs ».** La
question ne s'est pas posée une seule fois : les périmètres exclusifs ont produit
zéro conflit, ce qui est exactement ce que la matrice de propriété achetait.

Le pari de l'Agent 0 a tenu jusqu'au bout : les cinq API publiques gelées avant
qu'une ligne soit écrite sont livrées **au caractère près**, et le routeur les a
branchées sans une seule adaptation.
