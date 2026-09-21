# TC_AGENT_C_REPORT — Quran Engine

> Agent C, Teaching Core. Worktree `D:\RA_TC\c`, baseline `0071557`.
> Rapport écrit pour un contrôleur adversarial qui relancera les commandes.

---

## 1. Verdict en cinq lignes

- **Deux rendus sur trois sont livrés pleinement** : lecture agrandie responsive et focus class-ready.
- **Le troisième, la page Mushaf, est livré avec ses limites de page EXACTES et sa composition interne
  déclarée approximée**, à l'écran comme dans le code. La clause STOP de la spec §7.2 et la décision
  D-23 sont appliquées à la lettre : aucune ligne n'a été inventée.
- `flutter analyze lib test` : **propre, zéro issue**.
- `flutter test test/teaching_core/c` : **94 tests, tous passent**.
- `git status --porcelain` : **trois chemins, tous dans mon ownership**.

---

## 2. Commandes, et leur résultat exact

Depuis `D:\RA_TC\c` :

| Commande | Résultat |
|---|---|
| `flutter analyze lib test` | `No issues found!` |
| `flutter test test/teaching_core/c` | `00:10 +94: All tests passed!` |
| `git status --porcelain` | `?? lib/core/tc_coran/` · `?? lib/features/tc_mushaf/` · `?? test/teaching_core/` |
| `dart run tool/verifier_jetons.dart` | **10 violations, toutes PRÉEXISTANTES, aucune dans mes fichiers** — voir §8 |

⚠ **Un piège rencontré, à signaler** : `flutter pub get` (déclenché automatiquement par `flutter
analyze` et `flutter test`) a modifié trois fichiers **hors de mon ownership** :
`windows/flutter/generated_plugin_registrant.cc`, `.h` et `generated_plugins.cmake`. Ce sont des
fichiers régénérés par l'outillage, pas par moi. Je les ai **restaurés** avec `git checkout --` avant
de commiter. Les autres agents les verront probablement aussi : ce n'est pas une collision, c'est un
effet de bord de l'outillage Windows.

---

## 3. Fichiers créés

### `lib/core/tc_coran/` — le domaine et les ports (13 fichiers)

| Fichier | Rôle |
|---|---|
| `port_corpus_coran.dart` | `PortCorpusCoran` + `SourateVM`, `VersetCorpus`, `PageCorpus`, `ResultatRechercheCoran`, `EchecCorpusCoran`. Signature conforme à `CONTRACTS` §17 |
| `corpus_service_coran.dart` | `CorpusDepuisServiceCoran` : l'adaptateur **lecture seule** au-dessus de `ServiceCoran` [PROTECTED], plus `DebutsDeJuz` (double local déclaré) |
| `port_layout_mushaf.dart` | `PortLayoutMushaf`, `DisponibiliteLayout`, `LayoutPage`, **`SectionLigne`**, `SegmentVersetLigne` |
| `layout_lignes_indisponible.dart` | **`LayoutLignesIndisponible`** : l'implémentation honnête. Rend `indisponible` et `null`, et documente les trois manques |
| `page_mushaf_vm.dart` | **`PageMushafVM`**, `PlancheMushafVM`, `CoteDePage`, `GeometrieMushaf`, `ModeRenduCoran` |
| `metrique_texte_coran.dart` | `MetriqueTexteCoran` : le calcul de reflow. Largeur, taille, interligne et lignes **recalculés**, pas mis à l'échelle |
| `port_navigation_coran.dart` | `PortNavigationCoran`, `CibleCoran` (scellée : page/sourate/juz/ayah), **`OrigineNavigation`**, pont vers `ContentPosition` |
| `navigation_coran.dart` | `NavigationCoran` + providers. Porte la barrière de l'invariant J2 |
| `etat_lecture_coran.dart` | `EtatLectureCoran` + `ControleurLectureCoran`. Le zoom local vit ici |
| `moteur_mushaf.dart` | Les providers d'assemblage : corpus + sourates + layout → `PageMushafVM` |
| `ports_externes/content_position.dart` | **STUB** `ContentPosition`, `TypeAncrage`, `ContentRange` (Agent B) — déclarations recopiées à l'identique des deux fichiers canoniques d'Agent B, par l'AMENDEMENT 1 de `CONTRACTS` |
| `ports_externes/marqueur_semantique.dart` | **STUB** `MarqueurSemantique`, `IntentionPedagogique` (Agent D) |
| `ports_externes/port_etat_partage.dart` | **STUB** `SharedContentState`, `ModeAffichagePartage`, `PortEtatPartage` (Agent F) |

### `lib/features/tc_mushaf/` — les écrans (7 fichiers)

| Fichier | Rôle |
|---|---|
| `mushaf_page.dart` | L'écran : trois rendus, reprises, commandes, attribution Tanzil |
| `vue_page_mushaf.dart` | Le rendu page : cadre, feuilletage RTL, ouverture double, notice de composition |
| `vue_verset_agrandi.dart` | Le rendu verset reflowable |
| `vue_focus_classe.dart` | Le rendu focus |
| `navigation_coran_feuille.dart` | La feuille « Aller à » : page, sourate, juz, référence |
| `routes_tc_c.dart` | `routesTcC()` — **retourne** des routes, ne construit aucun `GoRouter` |
| `libelles_tc_c.dart` | La façade i18n, chaque constante annotée `// TC-I18N:` |

### `test/teaching_core/c/` — 94 tests (9 fichiers)

| Fichier | Tests |
|---|---|
| `page_mushaf_vm_test.dart` | Les goldens : composition, transitions de sourate, `pageSide`, ouverture, fidélité, bornes, états |
| `metrique_texte_coran_test.dart` | Le reflow : 7 largeurs × 7 zooms, aucun débordement |
| `navigation_coran_test.dart` | Les cinq navigations, l'invariant J2, la position de groupe, l'adaptateur, la recherche |
| `etat_lecture_coran_test.dart` | Revisions, suivi automatique, indépendance du zoom local |
| `mushaf_ecran_test.dart` | Les trois rendus montés, à 320, 390 et 1400 points |
| `goldens/corpus_reference.json` | Le corpus de référence, avec sa note de provenance |
| `goldens/corpus_reference.dart` | Son lecteur |
| `faux/faux_corpus_coran.dart` | Les doubles : corpus, `ServiceCoran`, navigation, layout fidèle |
| `support/hote_tc_c.dart` | L'hôte de test et le `GoRouter` de test (hors de `lib/`) |

### `docs/teaching-core/`

`TC_AGENT_C_REPORT.md` (ce fichier) · `TC_CONTRACT_REQUEST_C.md` · `i18n/tc_i18n_C.json`.

---

## 4. Ce qui marche, et ce que cela corrige

### 4.1 Le défaut de la section 2 de la spec, et comment il est traité

La spec le décrit ainsi : « mots distribués selon la surface disponible, absence de géométrie de page
familière, grande perte de repères visuels ». Mesuré dans le dépôt : `coran_page.dart` pose le texte
dans une `ListView` large comme l'écran, avec `fontSize: 26 * zoom`. **La page 293 n'a donc pas la même
tête sur un téléphone et sur une tablette**, et un élève qui mémorise par la position des mots perd ses
repères à chaque changement d'appareil ou de rotation.

Le moteur compose le texte dans un **cadre de page**, et la taille de caractère est dérivée de la
**largeur du cadre**, pas de celle de l'écran (`TexteDePage`, `MetriqueTexteCoran`). La page est donc
**homothétique à elle-même** d'un appareil à l'autre : les coupures de ligne tombent aux mêmes mots.
C'est la part du problème que les données permettent de résoudre, et elle est résolue.

### 4.2 Ce qui est exact, prouvé par les goldens

| Ce qui est exact | Pourquoi c'est exact |
|---|---|
| Les versets d'une page | `verset.page_numero` est renseignée pour les 6236 versets |
| Les transitions de sourate | Dérivées du corpus, par `VueLecteur._decouper` réutilisé |
| Le côté de page (`pageSide`) | Parité + reliure à droite. Impaire à droite, paire à gauche |
| L'ouverture (`spread`) | Couples (1,2), (3,4), … ; assertions sur la construction |
| Les bornes de navigation | 1 et 604 ferment ; une page hors bornes est ramenée dans l'édition |
| Le reflow sans débordement | Borne géométrique testée à 7 largeurs × 7 zooms |

### 4.3 Les trois rendus

**1. Page Mushaf.** Cadre de page à la proportion de l'édition, feuilletage **RTL**, ouverture double
sur tablette et desktop **quand la géométrie le permet** (décidé par
`PlancheMushafVM.tientEnDoublePage`, qui compare la largeur à `2 × hauteur × ratio + écart`, et **non à
un seuil en dur** : `AppGabarit` reste le seul fichier du dépôt à comparer une largeur à une
constante). Téléphone : une page, ajustée sans déformation. Pied de page portant numéro, juz, côté, et
**l'état de la composition**.

**2. Lecture agrandie.** Reflow responsive complet. Le zoom **n'est pas** un `Transform.scale` : la
largeur de colonne, la taille, l'interligne et le nombre de lignes sont recalculés. La taille est
bornée pour qu'**aucun mot du corpus ne soit coupé entre deux lignes** — on ne coupe pas un mot du
texte révélé — et quand le zoom demandé dépasse cette borne, l'écran l'écrit au lieu de le subir.

**3. Focus class-ready.** La plage active au centre, chrome réduit, texte agrandi. La plage vient de
`SharedContentState.contentRange` quand une classe est en cours ; hors classe, il centre la page
ouverte et le dit.

### 4.4 Navigation

Page, sourate, juz, ayah, recherche rapide, dernière position personnelle, position de groupe. Une
seule entrée pour les quatre premières : « 18 », « Al-Kahf », « juz 15 » et « 2:255 » font le même
geste. Un nombre nu propose **la sourate ET la page**, plutôt que de choisir à la place du lecteur.

### 4.5 Deux invariants tenus par construction, pas par vigilance

**Invariant J2 — la classe n'écrit jamais la position personnelle.** `OrigineNavigation` voyage avec
chaque changement de page. `NavigationCoran.memoriserPositionPersonnelle` **refuse d'écrire** si
l'origine n'est pas `personnelle`, et rend `false`. La barrière est au point d'écriture, pas dans
l'écran : un écran se réécrit, une règle posée au point d'écriture ne se contourne pas par distraction.
Trois tests la couvrent, dont « une page tournée par le groupe n'écrit rien ».

**Décision D-21 — le zoom local est indépendant.** `EtatLectureCoran.fusionnerPartage` applique la
revision partagée et **ne touche pas `zoomLocal`**. Une revision ≤ à celle déjà suivie est ignorée, ce
qui couvre d'un coup le paquet dupliqué et le paquet arrivé en désordre. Six tests.

---

## 5. Ce qui est mocké, et jusqu'où

| Élément | État réel |
|---|---|
| `PortEtatPartage` (Agent F) | **Stub de contrat** copié depuis `CONTRACTS` §9. `portEtatPartageCoranProvider` rend `null` par défaut — ce qui est le comportement **correct** hors classe, pas un repli. Aucune implémentation |
| `ContentPosition` / `ContentRange` (Agent B) | **Stubs de contrat, alignés sur le canonique d'Agent B.** Les déclarations sont recopiées à l'identique depuis `lib/core/tc_bibliotheque/content_position.dart` et `content_range.dart` du worktree `D:\RA_TC\b`, comme l'exige l'AMENDEMENT 1 de `CONTRACTS`. **Plus aucun écart** : `valeurSql` / `depuisSql`, `typeAncrage` sur la plage, les quatre assertions d'ancrage et le constructeur non-`const` de `ContentRange` sont ceux d'Agent B |
| `MarqueurSemantique` (Agent D) | **Stub de contrat**, non consommé par l'UI de ce lot : le moteur affichera les marqueurs quand le dock existera |
| Identifiant `LibraryResource` du Coran | **Double local** `'quran:madina-hafs-604'`. Demande n°6 |
| Les trente débuts de juz | **Double local** `DebutsDeJuz.table`. La base les porte (`public.juz`), `ServiceCoran` ne les expose pas. Demande n°4 |
| La source de layout | **`LayoutLignesIndisponible`** — ce n'est pas un mock, c'est la vérité du dépôt |
| Le corpus des tests | **6 pages réduites**, décrites dans `corpus_reference.json`. Pages 1 et 2 réelles, les quatre autres construites, et le fichier le dit |

---

## 6. Limites, honnêtement

1. **La composition en quinze lignes n'est pas reproduite, et ne peut pas l'être.** `verset.ligne` est
   `NULL` sur les 6236 versets, il n'existe aucune granularité sub-verset, et aucune police
   glyphe-par-page n'est embarquée. `DisponibiliteLayout` vaut `indisponible`, l'écran affiche
   « Composition approchée » **en permanence et sans possibilité de la masquer**, et le rapport le dit.
   Tout est chiffré dans `TC_CONTRACT_REQUEST_C.md` §1.

2. **La hauteur du cadre de page n'est qu'un minimum.** Sans données de ligne, rien ne garantit qu'une
   page tienne en quinze lignes à une taille lisible. Le cadre porte donc la proportion de l'édition
   comme **hauteur minimale** et grandit vers le bas si le texte le demande, la zone défilant. C'est un
   compromis assumé : la largeur, qui fixe les coupures, reste exacte.

3. **Le zoom du mode Mushaf n'existe pas.** En mode page, le zoom déformerait ou casserait la
   géométrie ; l'écran renvoie explicitement vers la lecture agrandie, qui existe pour cela. C'est un
   choix, pas un oubli — mais c'est un choix, et il peut être rediscuté.

4. **La recherche plein texte est absente côté application.** L'index, lui, existe en base : mesuré
   le 21/09/2026 sur le projet `gggmtelinlpseweouyav`, `pg_trgm` 1.6 dans le schéma `extensions`,
   colonne générée `verset.texte_recherche`, index `verset_recherche_idx`, posés par
   `0030_tc_socle`. Ce qui manque est le code qui l'interroge : aucune RPC, aucun appel Dart, et
   `ServiceCoran` est PROTECTED. L'écran affiche une phrase qui dit exactement ce que la recherche
   sait faire, plutôt que
   de rendre « aucun résultat » sur un mot arabe — ce qui ferait croire que le mot n'est pas dans le
   Coran. Demandes n°4 et n°5.

5. **Le côté de page repose sur une convention de reliure, pas sur une donnée.** Impaire à droite,
   paire à gauche. Le raisonnement est écrit dans `CoteDePage` ; il demande **une vérification sur
   l'édition imprimée**, qui coûte une minute et évite une ouverture inversée en production.

6. **`GeometrieMushaf.ratioCadreTexte = 2/3` est une constante déclarée, pas mesurée.** C'est le seul
   nombre de présentation du moteur. Il est remplacé par `LayoutPage.ratioLargeurSurHauteur` dès qu'une
   source de layout en fournit un.

7. **Aucune intégration avec la Classe Live.** `MushafPage` accepte un `sessionId` optionnel et sait en
   tirer la position de groupe, mais rien ne le lui passe : c'est le travail d'Agent E et d'Agent Z.

8. **Les goldens ne portent aucun texte coranique.** Les champs `texte` de la fixture sont des
   marqueurs neutres. Recopier de mémoire du texte révélé dans une fixture serait exactement
   l'improvisation que la spec interdit, et la licence Tanzil interdit par ailleurs toute modification
   du texte. Aucun golden de ce lot ne dépend du contenu des versets.

9. **Aucun golden d'image.** Les « golden tests » de ce lot portent sur la **composition** (quels
   versets, quelles sections, quel côté, quelle ouverture, quel débordement), pas sur des captures :
   une capture de texte arabe dépend du moteur de police de la machine, et serait rouge sur un poste
   sur deux sans rien dire de vrai sur le produit.

10. **Le mode Mushaf ne rend pas les marqueurs ni les annotations.** Ils appartiennent à Agent D et
    arriveront par `PortDockHote`.

---

## 7. Ce qu'Agent Z devra brancher

Par ordre de coût croissant :

1. **Le provider de layout.** `portLayoutMushafProvider` (`layout_lignes_indisponible.dart`) est **le
   seul point à surcharger** le jour où les lignes arrivent. Le renderer, le VM et les tests sont déjà
   prêts, et le chemin « lignes réelles » est couvert par un test.
2. **Les trois stubs de `ports_externes/`** : les supprimer et pointer sur les canoniques de B, D et F.
3. **`portEtatPartageCoranProvider`** : le faire rendre l'implémentation d'Agent F. Tout le reste suit,
   y compris le suivi automatique de la classe et « Reprendre le cours ».
4. **`identifiantRessourceCoran`** : le faire pointer sur le vrai `LibraryResource.id` d'Agent B.
5. **La fusion i18n** : `tc_i18n_C.json` dans `fr.i18n.json`, régénération slang, remplacement des
   constantes de `libelles_tc_c.dart`, suppression du fichier de façade.
6. **`routesTcC()`** : l'appeler depuis `app_router.dart`, promouvoir `RoutesCoran.mushaf` dans
   `routes.dart`, **ajuster `redirection.dart`** (sans quoi la route est inatteignable).
7. **L'arbitrage du remplacement d'`ELV-04`.** `lib/features/coran/coran_page.dart` est **intact et en
   place**, comme l'ownership l'exige. Ma recommandation est en §7 du CONTRACT_REQUEST : faire pointer
   la destination existante sur le moteur et transformer `/eleve/coran` en redirection, plutôt que
   d'ajouter une cinquième destination à `nav_shell.dart` (plafonné à quatre par assertion).
8. **Les deux méthodes de `ServiceCoran`** (`debutDeJuz`, `rechercher`) : les deux doubles locaux
   disparaissent le jour où elles existent.

---

## 8. Défauts préexistants rencontrés, non corrigés

Conformément à la consigne, je les signale sans y toucher. **Aucun n'est dans mes fichiers.**

**`dart run tool/verifier_jetons.dart` rend 10 violations sur la baseline `0071557`** :

| Fichier | Règle | Occurrences |
|---|---|---|
| `lib/core/widgets/menu_filtre.dart` | `m-dash` | 2 (lignes 42, 45) |
| `lib/core/widgets/nav_shell.dart` | `m-dash` | 3 (lignes 246, 264, 265) |
| `lib/core/widgets/nav_shell.dart` | `bouton-material` | 1 (ligne 461, `IconButton`) |
| `lib/core/widgets/nav_shell.dart` | `ontap-nu` | 1 (ligne 513) |
| `lib/core/widgets/sous_navigation_domaine.dart` | `ontap-nu` | 1 (ligne 63) |
| `lib/features/admin_dossiers/dossiers_page.dart` | `m-dash` | 1 (ligne 267) |
| `lib/features/admin_journal/journal_page.dart` | `m-dash` | 1 (ligne 198) |

Les cinq fichiers concernés sont hors de mon ownership, et trois d'entre eux sont explicitement
READ-ONLY pour tous les agents. **La baseline n'est donc pas verte au sens de `verifier_jetons`**,
contrairement à ce que l'addendum laisse entendre — `flutter analyze`, lui, est bien propre.

Les deux défauts déjà nommés par `BASELINE_ADDENDUM.md` (migration `0029` écrite mais non appliquée,
`catalogue_galerie_test` rouge) n'ont pas croisé mon périmètre : je n'ai ajouté aucun composant à
`lib/core/widgets/`, et tous mes composants vivent dans mes répertoires possédés.

---

## 9. Conformité

| Règle | État |
|---|---|
| Ownership | 3 chemins modifiés, tous possédés. `git status --porcelain` le prouve |
| Socle gelé | `lib/core/router/`, `theme/`, `auth/`, `video/`, `i18n/`, `widgets/`, `assets/i18n/`, `pubspec.yaml`, `supabase/migrations/`, `test/support/` : **aucun touché** |
| `service_coran.dart` [PROTECTED] | **Non modifié.** Lu et adapté derrière `PortCorpusCoran` |
| `coran_page.dart` | **Non modifié, non déplacé, non supprimé** |
| `vue_lecteur.dart`, `rosace_verset.dart`, `page_immersive.dart` | **Réutilisés tels quels**, jamais réécrits |
| Aucune migration | Aucune. Tout en « DEMANDE SQL » |
| i18n | Façade + JSON. `fr.i18n.json` et `strings*.g.dart` intacts. Les libellés qui existaient déjà sont **lus**, pas recopiés |
| Routes | `routesTcC()` retourne des routes. Aucun `GoRouter` dans `lib/`. Celui des tests vit dans `test/teaching_core/c/support/` |
| Stubs de port | 3 fichiers sous `ports_externes/`, en-tête `// TC-STUB-PORT:`, signatures copiées. `content_position.dart` suit le canonique d'Agent B (AMENDEMENT 1), **aucun écart restant** |
| Capacité codée en dur | Aucune. Le moteur ne manipule aucune capacité |
| Offset UTC | Aucun. Le moteur ne convertit aucun fuseau |
| Commande vocale | Aucune |
| PII famille | Aucune. Le moteur ne connaît aucune donnée de personne, sauf le `profile_id` que `ServiceCoran` exige déjà pour la position de lecture |
| Texte canonique | Jamais modifié. Attribution Tanzil rendue dans le flux de l'écran |
