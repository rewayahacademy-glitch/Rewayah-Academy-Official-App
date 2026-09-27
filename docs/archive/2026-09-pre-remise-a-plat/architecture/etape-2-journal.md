# Journal d'exécution — Étape 2

> Ce fichier dit **où en est le code**, ce que valent les mesures, et quels pièges
> ont déjà coûté du temps. `docs/architecture/etape-2-core-flutter.md` reste la
> spécification ; ce journal est son compte rendu.
> Mis à jour à la fin de chaque lot, jamais en bloc.

## État : étape 2 terminée, sauf le scénario 7

Onze lots sur onze. Vérifications au 6 septembre 2026 :

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 78 tests, tous verts |
| `dart run tool/verifier_jetons.dart` | 35 fichiers, aucune violation |
| Migrations 0001 à 0003 sur Postgres 17 | appliquées, enum et défaut vérifiés en base |
| `flutter build web` | réussi, galerie totalement élaguée |
| `flutter build web --dart-define=GALERIE=true` | réussi, galerie présente |

## Les sept scénarios d'acceptation

| # | Scénario | État | Où c'est vérifié |
| :-- | :--- | :--- | :--- |
| 1 | Aucun texte blanc sur `surfaceSuccess` ou `surfaceWarning` | vert | `test/theme/contraste_test.dart` mesure le ratio WCAG réel de chaque paire, plus `tool/verifier_jetons.dart` qui refuse toute couleur nue hors de `AppPalette` |
| 2 | `PermanentNotice` sans paramètre de visibilité | vert | `test/widgets/permanent_notice_test.dart` lit la source du constructeur, et le vérificateur applique la même règle en CI |
| 3 | Route protégée refusée à un compte en attente, y compris par URL Web | vert | `test/router/redirection_test.dart`, 17 routes croisées avec `pending_kyc` et `disabled` |
| 4 | Photo supprimée côté serveur, disparue en local sous 24 h | vert | `test/cache/purge_photos_test.dart` |
| 5 | Cahier synchronisé deux fois, une seule ligne | vert | `test/cache/file_rapports_test.dart` |
| 6 | Une seule arborescence de routes pour les deux modes | vert | `test/router/redirection_test.dart` plus le contrôle de fichier unique du vérificateur |
| 7 | Démarrage à froid sous 1,5 s | **non mesuré** | Voir ci-dessous |

**Le scénario 7 n'est pas coché, et il ne doit pas l'être tant qu'il n'est pas
mesuré.** À l'étape 2 il n'y a aucun écran métier à charger : chronométrer un
placeholder ne dirait rien du produit. La mesure appartient à l'étape 3, sur un
appareil d'entrée de gamme, sur `ELV-02` réel. Ce qui est fait dès maintenant :
polices embarquées plutôt que chargées au réseau, élagage d'icônes actif,
langues non basiques chargées en différé par slang.

## Lots

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | `flutter create`, pubspec, lints stricts, `dart_define.example.json` | x |
| L1 | Thème : paires, encres, espacement, deux échelles typographiques, 4 polices | x |
| L2 | `AppIcons`, catalogue unique | x |
| L3 | slang, clés en points, français rempli, arabe déclaré | x |
| L4 | `SessionState`, rôle du JWT, statut lu de `profiles`, `PorteAcces` | x |
| L5 | Routeur unique, redirection en fonction pure, salle éphémère | x |
| L6 | Les neuf composants partagés | x |
| L7 | Drift 4 tables, cache média, stockage sécurisé, file idempotente | x |
| L8 | Galerie `/_galerie` derrière `--dart-define=GALERIE=true` | x |
| L9 | Vérificateur de jetons, tests d'acceptation, CI | x |
| L10 | Migrations 0002 et 0003, statut `pending_kyc` | x |
| L11 | Documentation | x |

## Refonte UX/UI, lot T — 7 septembre 2026

> Le thème de l'étape 2 a été remplacé par celui de la refonte (ADR-018).
> **Les deux tableaux de la section suivante décrivent l'état d'avant** : ils
> restent pour lire un ancien commit, pas pour être appliqués. Les valeurs
> courantes sont dans `docs/produit/design-tokens.md`, et elles sont rejouées
> par quatre fichiers de tests.

### Ce que le lot a changé

| Fichier | Ce qui s'y trouve maintenant |
| :--- | :--- |
| `app_palette.dart` | 25 jetons au lieu de 8 : trois surfaces, trois bordures, six encres, cinq paires pleines, six paires douces, une couleur d'ombre |
| `app_color_pair.dart` | `AppShadowColor` s'ajoute à `AppColorPair` et `AppInkColor` |
| `app_radius.dart` | **nouveau** : cinq rayons, et `enfantDe` qui tient la règle du rayon décroissant |
| `app_elevation.dart` | **nouveau** : quatre niveaux, plus `avecFilet` qui interdit l'ombre sans filet |
| `app_mouvement.dart` | **nouveau** : durées, courbes, amplitudes, réduction du mouvement |
| `app_spacing.dart` | échelle étendue à 40, 48, 64, plus `AppPage` (gouttières, largeur de contenu, largeur de lecture) |
| `app_typography.dart` | deux polices françaises remplacées, crénage calculé, axes `wght` et `opsz` pilotés, chiffres tabulaires |
| `app_theme.dart` | trois surfaces câblées : page sur le crème, barres sur l'élevé, champs sur l'enfoncé |
| `verifier_jetons.dart` | sept règles au lieu de quatre |

### Contraste, après refonte

Les 33 mesures du tableau de `design-tokens.md` section 1 sont rejouées une par
une par `test/theme/contraste_test.dart`, avec une tolérance de 0,01. Une valeur
fausse dans le document fait donc échouer la suite, ce qui est le seul moyen
d'empêcher un tableau de mesures de dériver.

**Deux chiffres du document étaient faux, et le test les a trouvés.**

| Ce que le document disait | Mesure réelle | Conséquence |
| :--- | :--- | :--- |
| Blanc sur le fond général : 1,19 | **1,10** | Aucune : la conclusion tenait. Le 1,19 était la mesure d'un fond qui n'existe plus, et la même paire était déjà donnée à 1,10 trois sections plus haut |
| `opsz` de Bricolage Grotesque, défaut 14 | **défaut 96** | Le risque est l'inverse de celui décrit : c'est le petit titre laissé au défaut qui sort faux, pas le grand |

Deux mesures manquaient au document et ont été ajoutées : `borderStrong` vaut
3,73 sur une carte blanche et 3,21 sur la surface enfoncée. C'est ce qui permet
d'affirmer, sans le supposer, qu'il passe 3:1 **sur les trois surfaces**.

### Poids des polices

| Élément | Avant | Après |
| :--- | ---: | ---: |
| Titres français | VarelaRound, 130 Ko | BricolageGrotesque variable, **398 Ko** |
| Corps français | NotoSans variable, 2 001 Ko | InstrumentSans variable, **189 Ko** |
| **Total français** | **2 131 Ko** | **587 Ko** |

**1 544 Ko de gagnés, soit 72 %**, alors que le produit gagne au passage une
plage de graisses continue de 200 à 800 pour les titres et un axe de taille
optique qu'il n'avait pas. La police de titre pèse trois fois plus qu'avant, et
c'est normal : Varela Round n'avait qu'une graisse, donc rien à faire varier.

Les polices arabes ne bougent pas : 825 Ko et 161 Ko.

### Sous-ensemblage : mesuré, pas livré

Le gain restant a été chiffré, sur un sous-ensemble latin de Google Fonts
(`pyftsubset`, dans un environnement jetable hors du dépôt) :

| Police | Complète | Sous-ensemblée latin | Gain |
| :--- | ---: | ---: | ---: |
| Bricolage Grotesque | 398 Ko | 220 Ko | 45 % |
| Instrument Sans | 189 Ko | 123 Ko | 35 % |
| **Total** | **587 Ko** | **343 Ko** | **42 %** |

Les axes variables, `kern` et `tnum` survivent au découpage, vérifié sur les
binaires produits.

**Les fichiers découpés ne sont pas versionnés, et c'est une décision, pas un
oubli.** Trois raisons, dans cet ordre :

1. Le sous-ensemble latin retire tout ce qui sort de Latin-1. L'application
   affiche des **prénoms saisis par les familles** : un nom en cyrillique, en
   vietnamien ou portant un diacritique rare deviendrait un carré vide. C'est un
   risque produit, il se tranche avec l'opérateur, pas dans un lot de jetons.
2. La chaîne de découpage n'existe pas dans le dépôt. Livrer un binaire modifié
   sans script reproductible en CI, c'est livrer un fichier que personne ne
   saura régénérer.
3. `design-tokens.md` le disait déjà : le remplacement est « l'occasion de
   mesurer le gain, pas la preuve qu'il est acquis ».

### Le piège des valeurs par défaut d'une police variable

Une police variable a une valeur par défaut par axe, et **elle n'est presque
jamais celle qu'on suppose**. Bricolage Grotesque est livrée à `wght` 800 et
`opsz` 96 : un titre qui déclare seulement `fontSize` sort en extra-gras dessiné
pour 96 points, à toutes les tailles. Rien ne le signale, ni à la compilation ni
à l'analyse : ça se voit à l'écran, ou jamais.

La règle qui en sort : **lire la table `fvar` du binaire avant d'écrire un
style**, et piloter tous les axes qu'elle déclare. `typographie_test.dart` le
vérifie rôle par rôle, dans les deux échelles.

### Deux impasses en récupérant les polices

`fonts.google.com/download?family=...` ne rend plus une archive : il rend la
page HTML de l'application, 198 Ko qui ressemblent à un zip par leur taille et
n'en sont pas. Et l'API CSS `css2`, même avec un vieil `User-Agent` pour obtenir
du TrueType, ne sert que des **instances statiques**, une par graisse et par
largeur : 21 fichiers pour Bricolage Grotesque, aucun variable.

Ce qui marche : `fonts.google.com/download/list?family=...`, qui rend un JSON
(préfixé de `)]}'`) contenant l'URL du fichier variable sur `fonts.gstatic.com`,
et le texte de la licence OFL.

### Mesures de fin de lot

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **362 tests**, tous verts (277 avant le lot) |
| `dart run tool/verifier_jetons.dart` | **80 fichiers**, aucune violation |
| `scenarios_etape3.sql` | 34 contrôles verts |
| `scenarios_etape4.sql` | 39 contrôles verts |
| Les sept règles du vérificateur, mises en échec exprès | 7 violations levées sur 7 attendues |
| `flutter build web --release` | réussi. `FontManifest.json` déclare les deux nouvelles familles, les deux anciennes ont disparu du bundle |
| Rendu réel de `/_galerie` dans Chrome | vérifié à l'œil, voir ci-dessous |

### Pourquoi un rendu réel, et pas seulement des tests

**Aucun test Flutter ne prouve qu'une police se charge** : en test, le moteur
rend tout en Ahem, une police de blocs. Un nom de famille mal orthographié dans
`pubspec.yaml` donnerait un repli silencieux, et les 362 tests resteraient
verts.

La galerie a donc été construite avec `--dart-define=GALERIE=true`, servie en
local et ouverte dans Chrome. Ce qui s'y voit, et qui ne se voyait pas
autrement :

- les deux polices rendent, et rendent **différemment** l'une de l'autre : ce
  n'est pas un repli système ;
- les chiffres tabulaires alignent bien leurs colonnes, `11 111` au dessus de
  `00 000` ;
- les trois bordures se distinguent à l'œil dans le bon ordre, et
  `borderStrong` se voit franchement là où `borderHairline` s'efface ;
- les quatre élévations montent visiblement, sans qu'aucune ne fasse tache sur
  le crème : l'ombre chaude tient sa promesse ;
- l'échantillon mixte français-arabe se lit sur une seule ligne, le repli vers
  Noto Sans Arabic fonctionne. **L'accord des deux polices reste à juger par
  l'opérateur** : question ouverte 21 du registre.

⚠ Piège de l'outillage, pour la prochaine fois : le défilement de la galerie
ne répond ni à la molette du pilote ni à `Page_Down`. Il faut envoyer un
`WheelEvent` à l'élément `flutter-view` en JavaScript. Et la capture d'écran
échoue une fois sur deux avec un délai de 30 s : réessayer suffit.

---

## Refonte UX/UI, lot C — 7 septembre 2026

> Le lot C donne au produit la **profondeur** que le lot T lui avait donné le
> vocabulaire. Aucun écran métier n'est repris — c'est le lot R. Le catalogue
> `docs/design/07-catalogue-composants.md` est désormais tenu par le code et par
> la galerie.

### Ce que le lot a livré

| Livrable | Détail |
| :--- | :--- |
| **12 composants P0** | `PageShell`, `NavShell`, `AppCard`, `SectionHeader`, `StatusPill`, `Skeleton`, `LocalFeedback`, `StatTile`, `SignalRow`, `AppBottomSheet`, `ConfirmDestructive`, `ChildCard` — chacun avec les états obligatoires de sa famille (section 4) |
| **`app_gabarit.dart`** | nouveau : les trois gabarits de `05-regles-responsive.md` §1, seuils 600 / 1024 dans ce seul fichier, gouttières 20 / 32 / 48, largeur de rail et de barre latérale |
| **11 composants repris** | `Pressable` (survol + anneau de focus + `PressionForcee`), `BentoTile` (→ `surfaceRaised` + `elevation1` + `borderHairline`), `AvatarTile` (repli `washFamily` + `borderStrong`), `PinPad` (erreur en `inkAlert`), `EmptyState` (trois registres), `OfflineBanner` (registre doux), `ChoiceCardGroup` (`washAccent` + `borderStrong`), `ActionPrincipale` (4ᵉ niveau destructif + survol/focus), `GrilleSemaine` (cases vides `surfaceSunken`, posées `washAccent`). `AudioLabel` et `PermanentNotice` : intacts, l'API de `PermanentNotice` reste sans le moindre paramètre (ADR-011) |
| **`PageParcours` remontée** | de `lib/features/inscription/` vers `lib/core/widgets/`, reposée sur `PageShell`, tous les imports mis à jour |
| **La galerie, preuve du catalogue** | `catalogue_galerie.dart` : 24 entrées (12 P0 + 10 partagés + `GrilleSemaine` + `PageParcours`) avec tous leurs états nommés ; `galerie_page.dart` : les cinq axes de la section 5 en bascules réelles |
| **Deux fichiers de test** | `composants_test.dart` (invariants de fond, pas des types de widgets) et `catalogue_galerie_test.dart` (la liste écrite du document, comparée au disque : un composant ajouté à `lib/core/widgets/` sans entrée fait échouer la suite) |

Les deux dettes que le handoff pointait sont payées : une tuile Bento vit
maintenant sur `surfaceRaised` avec son ombre, et les cases vides de la grille de
disponibilités portent `surfaceSunken`.

### L'audit de fin de lot, et ce qu'il a trouvé

Le lot a été relu par six agents en parallèle, une tranche de livrable chacun,
puis chaque constat a été soumis à un sceptique chargé de le réfuter. **29
constats bruts, 8 confirmés de la portée du lot C, tous corrigés dans ce lot.**
Aucun bloquant.

| # | Composant | Gravité | Écart, et correction |
| :-: | :--- | :--- | :--- |
| 1 | `PageShell` | majeur | l'`entete` défilait avec le contenu. Le gabarit sépare désormais une tête fixe (titre + en-tête) d'une zone défilante, comme la zone d'action collée en bas |
| 2 | `ConfirmDestructive` | majeur | le bouton destructif était l'élément le plus bas de la feuille, donc le premier au pouce (`02-regles-ux.md` §5). Il passe en haut ; « Annuler » reste premier au clavier par `FocusTraversalOrder` |
| 3 | `ChildCard` « aucun planning » | mineur | pas de `contour borderStrong` (`07` §3). `AppCard` gagne `contourFort`, que cet état active |
| 4 | `AppBottomSheet` | mineur | les courbes d'ouverture/fermeture venaient de Material. Elles viennent maintenant de `AppMouvement.entree` / `sortie` via `sheetAnimationStyle` |
| 5 | `AppBottomSheet` | mineur | ombre `elevation3` sans filet. La feuille passe par `AppElevation.avecFilet`, qui compose les deux |
| 6 | `ChildCard` « en recherche » | mineur | encre `inkFaint` au lieu de `inkMuted` (`07` §3). Jeton nommé directement |
| 7 | `LocalFeedback` | mineur | sous mouvement réduit, les durées tombaient à 120 ms. `04` §5 dit « inchangé » : elles restent 200 / 160, seule la translation tombe à zéro |
| 8 | `BentoTile` | mineur | `plate: true` fabriquait un filet sans ombre, combinaison interdite (`01` §2) et hors du registre unique du catalogue. Paramètre supprimé, entrée de galerie retirée |

### Ce qui est renvoyé ailleurs, à dessein

- **Deux imprécisions de `07-catalogue-composants.md` à trancher côté document**,
  pas côté code : le « sélection en `surfacePrimary` » de la ligne `GrilleSemaine`
  §1 (la grille n'a pas d'état « sélection » distinct de « posée », et vingt
  aplats violets violeraient « une seule zone pleine par écran » — un test fige
  d'ailleurs `isNot(surfacePrimary)`) ; et la clause « plus hors ligne » de la
  famille « composant d'état » §4, que la section 3 ne réclame que pour la donnée
  volatile.
- **Deux des cinq puces de `07` §6 ne sont pas encore outillées** (`Container`
  avec `decoration` dans `lib/features/`, `showDialog` de confirmation
  destructive). `showDialog` : zéro occurrence. `Container(decoration:)` : seize,
  toutes dans des écrans métier que le lot C n'a pas le droit de toucher. Les
  deux règles s'ajouteront à `verifier_jetons.dart` **avec la reprise des
  écrans, au lot R** — les poser maintenant rendrait le vérificateur rouge sur
  du code hors périmètre.
- **Le ressort amorti de la feuille** (`04` §2) : les courbes viennent désormais
  du budget de mouvement (correction 4), mais l'ouverture/fermeture reste pilotée
  par une courbe et non par une `SpringSimulation` sur une route modale
  personnalisée. Le geste de glissement, lui, porte déjà la physique de ressort
  de Material. `AppMouvement.ressort` reste en place : il sert aussi au conteneur
  partagé, à venir.

⚠ Le commit du lot C emporte un `dart format` pris sur tout le dépôt : il touche
des écrans métier et des fichiers de tests sans raison fonctionnelle. « Aucun
écran touché » reste vrai au sens des usages — aucune reprise d'écran, seulement
des ajustements d'appel forcés par les changements d'API des composants partagés
(`BentoTile` perd `avecBordure`, `ActionPrincipale` passe de `surface` à
`niveau`) — mais faux au niveau fichier.

### Mesures de fin de lot

| Contrôle | Résultat | Après le lot T, pour mémoire |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **418 tests**, tous verts | 362 |
| `dart run tool/verifier_jetons.dart` | **94 fichiers**, aucune violation | 80 |
| `scenarios_etape3.sql` | 34 contrôles verts | 34 |
| `scenarios_etape4.sql` | 39 contrôles verts | 39 |

Les deux harnais SQL n'ont pas bougé, et c'est attendu : le lot C ne touche
aucun `.sql`. Ils ont été rejoués sur un conteneur neuf pour la forme.

---

## Refonte UX/UI, lot R — 7 septembre 2026

> Le lot R reprend les écrans déjà construits pour qu'ils portent le langage
> posé aux lots T et C. Un sous-lot par commit, dans l'ordre de
> `docs/design/08-catalogue-ecrans.md` section 5 : `ELV-02`, puis `TUT-01`, puis
> `ENS-02` et `ADM-01`, puis le reste. Chaque écran repris gagne sa fiche dans
> `08-catalogue-ecrans.md` section 6, remplie **à partir du code**.

### R1 : `ELV-02`, l'accueil de l'élève

Le plus simple des quatre premiers, et celui montré à l'opérateur : deux blocs,
rien d'autre. Il sert de preuve du système.

| Livrable | Détail |
| :--- | :--- |
| **`ELV-02` repris** | passe par `PageShell` (fond crème, gouttière du gabarit, colonne centrée et bornée à 1200, bandeau hors ligne) au lieu de son `Scaffold` propre ; le cours en direct et le hors ligne redeviennent des cartes `surfaceRaised` avec pastille verte et bouton d'entrée en `surfacePrimary`, seul le bloc imminent reste un aplat plein ; la pastille « en direct » passe de `Container` décoré à `StatusPill` ; les états vides passent au registre `subi` ; sous mouvement réduit, la pulsation est **remplacée** par une bordure `borderStrong` fixe |
| **`BentoTile` gagne `contourFort`** | prise jumelle de celle d'`AppCard` (lot C) : un filet `borderStrong` au repos, sans survol. Sert la bordure fixe qui remplace la pulsation d'`ELV-02` sous mouvement réduit (`04-systeme-mouvement.md` §5). Nouvel état « contour fort » dans la galerie, nouveau contrôle dans `composants_test.dart` |
| **Fiche `ELV-02`** | remplie dans `08-catalogue-ecrans.md` section 6, à partir du code. Elle consigne aussi la dette assumée : pas d'état `loading` ni `error` dédié, la lecture des séances qui échoue ou tarde retombe sur « aucun cours » |
| **Tests `ELV-02`** | le contrôle « à moins de cinq minutes, le bloc pulse » est scindé : un cas pour la pulsation réelle (sans `pumpAndSettle`, la pulsation tourne en boucle), un cas pour la bordure fixe sous mouvement réduit. Le contrôle « une heure plus tôt » vérifie désormais la carte `surfaceRaised` par défaut, pas l'ancien `surfaceCanvas` |

### Ce qui n'a délibérément pas bougé

- **`NavShell` n'est toujours pas câblé au routeur.** `ELV-02` en mode enfant
  n'a aucune navigation (0 destination), donc R1 n'en a pas besoin. Le câblage
  de la barre de navigation pour les rôles qui en ont une reste un chantier à
  part, à traiter avec `TUT-01` / `ENS-02` / `ADM-01` ou après.
- **Aucun `.sql` touché.** Le harnais SQL lit exactement les mêmes octets
  qu'avant R1.

### Mesures de fin de sous-lot R1

| Contrôle | Résultat | Après le lot C, pour mémoire |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **420 tests**, tous verts | 418 |
| `dart run tool/verifier_jetons.dart` | **94 fichiers**, aucune violation | 94 |
| `scenarios_etape3.sql` | 34 contrôles verts | 34 |
| `scenarios_etape4.sql` | 39 contrôles verts, **après un correctif à part** (voir ci-dessous) | 39 verts |

⚠ **S7b de `scenarios_etape4.sql` était rouge sur ce poste**, et R1 n'y touchait
aucun octet. Le contrôle prenait `order by started_at limit 1` sur toutes les
séances de l'enseignant `cccc…01` et insérait une séance juste après : dès que le
prochain jeudi précède le prochain lundi (mardi à jeudi), cette séance tombait
sur une séance de S3 déjà en place, collision. Exactement la fragilité horodatée
que ce journal signalait déjà pour le contrôle « Feed », « vert le 6 septembre,
rouge le 7 à 00h23 locales ». Corrigé dans un **commit à part**, hors lot R : S7b
cible désormais la séance d'Amina du lundi 17 h, la seule dont l'heure suivante
est libre à coup sûr. Le harnais passe 34 puis 39 sur ce poste comme sur la CI.

### R2 : `TUT-01`, l'accueil du foyer

Le deuxième des quatre premiers. Il porte `ChildCard`, la carte du domaine
famille, et c'est elle que la note de refonte donnait en exemple.

| Livrable | Détail |
| :--- | :--- |
| **`TUT-01` repris** | passe par `PageShell` au lieu de son `Scaffold` + `OfflineBanner` + `RefreshIndicator` + `ListView` propres ; les lignes d'enfant deviennent des `ChildCard` ; la pastille « en direct », un `Container` décoré, passe par `StatusPill` portée par la carte ; le cours en direct redevient une carte `surfaceRaised` avec bouton d'entrée en `surfacePrimary`, seule zone pleine désormais réservée au bouton |
| **`phaseEnfant`, fonction pure** | renommage de l'ancien `etatEnfant` : `ChildCard` exporte déjà un `EtatEnfant` scellé, et deux `EtatEnfant` dans le même fichier ne cohabitent pas. `phaseEnfant` **décide** de la phase (cinq, celles de la fiche produit) ; un mapper la traduit en état visuel de `ChildCard` avec les phrases mises en forme. Le corps de la décision et `attendDepuis` sont inchangés, leurs tests unitaires aussi |
| **`SectionHeader` « Gérer le foyer »** | sépare les cartes des trois blocs secondaires (appareils, réglages, accès), qui restent des `BentoTile` comme le bloc Coran d'`ELV-02`. Nouvelle clé `t.tuteur.accueil.gererLeFoyer` |
| **Deux règles pour `verifier_jetons.dart`** | les deux puces de `07-catalogue-composants.md` §6 que le lot C avait renvoyées au lot R : aucun `Container` porteur d'une `decoration` sous `lib/features/` (`container-decore-dans-features`), aucun `showDialog` hors de `ConfirmDestructive` (`showdialog-hors-confirmation`). Chacune **vérifiée en la faisant échouer** sur un fichier piège. Zéro occurrence de l'une comme de l'autre après la reprise |
| **Fiche `TUT-01`** | remplie dans `08-catalogue-ecrans.md` §6, à partir du code, dettes assumées comprises |
| **Tests `TUT-01`** | les contrôles qui lisaient un `BentoTile` et sa `surface` lisent désormais une `ChildCard` et la décoration de son `Container` externe ; « rien aujourd'hui » vérifie l'absence du préambule ; « séance annulée » vérifie la pastille et non le libellé de statut. Deux ajoutés : « passe par `PageShell` », « deux enfants en direct : deux cartes posées, aucun aplat » |

### L'audit de fin de sous-lot, et ce qu'il a trouvé

Six agents en parallèle, une tranche chacun, puis un sceptique par constat, comme
au lot C. **Treize constats bruts, dont un doublon entre deux tranches, et aucun
code à changer.** Onze réfutés, le dernier ramené de « majeur » à « mineur, à
consigner ». La tranche « tests » : propre.

Ce que les réfutations ont rappelé : plusieurs « pertes » de la reprise sont des
simplifications que `07-catalogue-composants.md` §3 **prescrit** (le préambule
« Rien aujourd'hui », la phrase de conséquence de « aucune heure proposée », le
libellé de statut « Séance annulée » porté par la pastille) ; le chevron listé
pour la ligne « Normal » de `ChildCard` est une prise du **composant**, pas une
obligation de câblage de l'écran, et `07` §4 interdirait une affordance qui ne
mène nulle part ; la mise en colonnes desktop relève de
`05-regles-responsive.md`, hors du périmètre du lot R comme pour `ELV-02` ; les
deux règles du vérificateur, plus larges que la lettre de leur puce, suivent le
style déjà accepté au lot C pour `bouton-material`.

Le seul constat qui survit : **le tirage-pour-rafraîchir de l'ancien écran
disparaît** avec le passage à `PageShell`. Le fait est réel — l'ancien
`RefreshIndicator` invalidait les trois providers, `PageShell` n'a pas de prise
équivalente, et `seancesProvider` / `affectationsProvider` ne sont sinon relus
qu'au démarrage. Mais le remède n'est pas un correctif R2 : `PageShell` exclut
**volontairement** les états de données de son périmètre (son en-tête le dit), et
envelopper l'écran dans un `RefreshIndicator` réintroduirait la tuyauterie par
écran que le lot R retire. `R1` a traité son manque analogue — pas d'état
loading/error — en le **consignant** dans la fiche `ELV-02`, sans code. R2 fait
pareil : la dette est écrite dans la fiche `TUT-01` §6, avec la piste propre
(une prise `onRafraichir` optionnelle de `PageShell`, à trancher explicitement
puisqu'elle touche cette frontière, et utile aussi à `ELV-02` et aux écrans
R3/R4).

### Ce qui n'a délibérément pas bougé

- **`NavShell` n'est toujours pas câblé au routeur.** R1 l'avait classé « un
  chantier à part » ; R2 confirme. Le tuteur a quatre destinations, le routeur
  n'a aucun `StatefulShellRoute`, et l'ajouter couvrirait tous les rôles à barre
  d'un coup : ça éclaterait « un sous-lot par commit » et forcerait une reprise à
  R3/R4. Après R2, la racine du rôle tuteur est refondue mais n'offre toujours
  aucune navigation de premier niveau. Son sous-lot naturel est R3, avec
  `ENS-02` / `ADM-01`, ou après.
- **Aucun `.sql` touché.** Le harnais lit exactement les mêmes octets qu'avant R2.
- **`docs/produit/parcours-utilisateurs.md`** n'est pas modifié : la fiche `TUT-01`
  y décrit toujours les cinq états de l'enfant, que la reprise respecte.

### Mesures de fin de sous-lot R2

| Contrôle | Résultat | Après R1, pour mémoire |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **422 tests**, tous verts | 420 |
| `dart run tool/verifier_jetons.dart` | **94 fichiers**, aucune violation | 94 |
| `scenarios_etape3.sql` | 34 contrôles verts | 34 |
| `scenarios_etape4.sql` | 39 contrôles verts | 39 |

Rejoués sur un conteneur `postgres:17-alpine` neuf. Le compte de fichiers du
vérificateur ne bouge pas : R2 n'ajoute aucun fichier `.dart` à `lib/`, et
`strings.g.dart` reste hors de son balayage.

### R3 : `ENS-02`, `ADM-01`, et le câblage de `NavShell`

Les trois derniers chantiers du lot R annoncés en tête : les deux écrans
restants passent au langage des lots T/C, et la barre de premier niveau, mise de
côté en R1 puis R2, est enfin câblée au routeur.

| Livrable | Détail |
| :--- | :--- |
| **`ENS-02` repris** | passe par `PageShell` au lieu de son `Scaffold` + `OfflineBanner` ; `_LigneJournee` disparaît au profit de `TimelineRow` ; `_BlocDominant` n'a plus d'aplat plein : une carte `BentoTile` posée, et la pastille « En direct » passe par `StatusPill` ; la phrase « sans lancement » remplace le bouton de lancement ; la consultation des interruptions de prière n'a plus besoin du harnais complet, la lecture de la journée fournit les entrées |
| **`TimelineRow`, composant de registre** | nouvelle famille de la section 2 de `07-catalogue-composants.md` : une icône (cours / pause / prière), une plage, un libellé, l'identifiant de l'élève pour un cours, la durée pour une pause ou une prière. L'icône vit dans un cercle posé sur la surface, le texte en encre secondaire, jamais `inkFaint`. Deux points de code ajoutés à `AppIcons` (`cours` 0xe600, `pause` 0xe1c2). Trois états à la galerie (cours avec identifiant, pause, prière) |
| **`ADM-01` repris** | passe par `PageShell` au lieu de son `Scaffold` + `RefreshIndicator` + `ListView` ; `maintenant = horloge()` lu **une seule fois** dans le build, l'ancienneté reste cohérente sur toute la liste d'un même rendu ; les six compteurs passent par `StatTile` (deux actionnables — dossiers, demandes —, quatre rapports sans prise), la liste à traiter par `SignalRow` avec l'ancienneté en jours ; `_Compteur` et `_Ligne` supprimés, `ATraiter` reste une fonction pure |
| **`destinationsPour`, fonction pure** | dans `nav_shell.dart` : le nombre et l'ordre des destinations d'un rôle et d'un mode. Élève 3 (0 en mode enfant, ADR-009 — sans décision, pas de barre), tuteur 4, enseignant 3, admin 4 (les demandes restent derrière leur compteur, une cinquième entrée ferait une barre-menu), contrôleur et comptable 0 (une seule destination ne monte pas de barre). L'assertion « jamais plus de quatre » borne chaque rôle, pour la règle de `03-architecture-information.md` §5. Testée par `test/router/navigation_test.dart` |
| **`NavShell` câblé au routeur** | quatre `StatefulShellRoute.indexedStack` dans `app_router.dart` (élève, tuteur, enseignant, admin), une coquille par rôle : elle lit le mode d'interface dans la session et délègue à `destinationsPour`. Le tuteur a enfin sa barre, annonce des R1/R2. La navigation URL directe (PWA, ADR-005) n'est pas touchée : les branches gardent leurs chemins, `redirection_test.dart` passe sans modification. Le contrôleur, une seule destination, garde sa route nue |
| **Fiches `ENS-02` et `ADM-01`** | remplies dans `08-catalogue-ecrans.md` §6, à partir du code. Deux écarts à trancher y sont consignés : **six compteurs contre cinq** annoncés dans le produit, et **l'ordre « chiffres d'abord »** choisi par l'écran contre « les signaux d'abord » du registre — la hiérarchie des documents (`parcours-utilisateurs.md` au-dessus des registres) justifie le choix fait, sans le figer. Dettes assumées : la suppression du tirage-pour-rafraîchir (même format que la fiche `TUT-01`), le panneau de détail / plein largeur desktop |
| **Clé i18n `nav.tuteur.accueil`** | absente des clés `nav.*` (il n'y avait aucune navigation de premier niveau tuteur), ajoutée puis générée. Confirmer à la relecture que les sept rôles ont bien tous leurs libellés |

### L'audit de fin de sous-lot R3

Huit tranches en parallèle, puis un sceptique par constat (le même protocole
qu'aux lots C, C et R2). **Sept constats bruts : cinq réfutés par le sceptique,
deux retenus.** Les réfutations : la phrase « en direct », la cohérence de
l'ancienneté et l'incohérence d'un mode enfant naviguant ont été relues contre
les documents sources puis rejetées (la première est prise par l'icône `StatusPill`,
la deuxième est gérée par `maintenant` hoisté et le label des `StatTile`, la
troisième relève du routeur, pas de `NavShell`).

Les deux constats retenus : **la suppression du tirage-pour-rafraîchir** du
tableau de bord (même famille que la dette `TUT-01`, `PageShell` exclut
volontairement les états de données, la piste propre est la prise
`onRafraichir` — consignée, pas implémentée) et **les deux imprécisions de
`07-catalogue-composants.md`** (« sélection en `surfacePrimary` » de
`GrilleSemaine` §1, « plus hors ligne » de la famille « composant d'état » §4)
que la reprise a fait remonter en même temps que la doc s'aligne sur le code.

### Ce qui n'a délibérément pas bougé

- **La navigation URL directe.** Les chemins des branches sont restés les
  mêmes, `deciderRedirection` n'a pas changé de comportement : les tests de
  redirection passent sans être touchés. C'est la condition du câblage, posée
  dès R1.
- **Aucun `.sql` touché.** Le harnais lit exactement les mêmes octets qu'avant R3.

### Mesures de fin de sous-lot R3

| Contrôle | Résultat | Après R2, pour mémoire |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **426 tests**, tous verts | 422 |
| `dart run tool/verifier_jetons.dart` | **95 fichiers**, aucune violation | 94 |
| `scenarios_etape3.sql` | 34 contrôles verts | 34 |
| `scenarios_etape4.sql` | 39 contrôles verts | 39 |
| `flutter build web --release` | compile | — (non rejoué à R2) |

Le compte du vérificateur passe à 95 : R3 ajoute `timeline_row.dart` à
`lib/core/widgets/`. R3b n'ajoute aucun fichier à `lib/`, les coquilles vivent
le même routeur que les routes nues.

---

## Mesures relevées à l'étape 2 — état d'avant la refonte

### Contraste

Le tableau de `design-tokens.md` a été mesuré, pas relu.

Valeurs relevées par `Color.computeLuminance` de Flutter, pas estimées.

| Jeton | Mesure | Seuil | Verdict |
| :--- | ---: | ---: | :--- |
| `surfaceBase` | 13,51:1 | 4,5 | passe |
| `surfacePrimary` | 4,81:1 | 4,5 | passe, de peu |
| `surfaceSuccess` | 11,55:1 | 4,5 | passe |
| `surfaceWarning` | 9,64:1 | 4,5 | passe |
| `surfaceAlert` | 6,84:1 | 4,5 | passe |
| `textOnLightAccent` sur `surfaceBase` | 6,48:1 | 4,5 | passe |
| `surfacePrimary` sur `surfaceBase` (focus) | 3,86:1 | 3,0 | passe |
| `surfaceAlert` sur `surfaceBase` (erreur) | 5,49:1 | 3,0 | passe |
| `borderDefault` sur `surfaceBase` | **1,86:1** | 3,0 | **échoue** |
| `#CCBCBC` d'origine sur `surfaceBase` | 1,47:1 | 3,0 | échoue, valeur citée dans les specs, confirmée |

**`borderDefault` (`#B8A6A6`) reste sous le seuil de 3:1 des éléments non
textuels (WCAG 1.4.11).** La correction héritée de l'audit l'a fait passer de
1,47:1 à 1,86:1, ce qui améliore sans résoudre. Conséquence tenue dans le code :
ce jeton est **décoratif**, il ne porte jamais seul le sens d'un contrôle ou
d'un état. Le focus, l'erreur et la sélection passent par `surfacePrimary`,
`surfaceAlert` et `textOnLightAccent`, qui eux passent le seuil.

**Décision en attente de l'opérateur** : si les bordures doivent devenir
porteuses de sens, `#8F8080` mesure 3,03:1 sur `surfaceBase`, valeur vérifiée et
non estimée. Le test `contraste_test.dart` encadre la mesure par le haut et par
le bas, pour qu'un changement de ce jeton soit un choix conscient et non un
glissement.

Un mot sur `surfacePrimary` à 4,81:1 : la marge au-dessus de 4,5 est mince.
Toute retouche du violet `#8652E6` doit être remesurée, pas jugée à l'œil.

### Poids

| Élément | Livré | Après élagage |
| :--- | ---: | ---: |
| Phosphor regular | 489 Ko | 10,6 Ko |
| Phosphor fill | 449 Ko | 8,9 Ko |
| Material Icons | 1 645 Ko | 7,7 Ko |
| Cupertino Icons | 258 Ko | 1,5 Ko |
| **NotoSans-Variable** | **2 001 Ko** | **2 001 Ko** |
| NotoSansArabic-Variable | 825 Ko | 825 Ko |
| UthmanTahaNaskh | 161 Ko | 161 Ko |
| VarelaRound | 130 Ko | 130 Ko |

Les polices de texte ne sont pas sous-ensemblées : l'élagage de Flutter ne
concerne que les polices d'icônes. **NotoSans-Variable pèse 2 Mo pour une
interface française** : c'est le plus gros gain disponible sur le budget de
20 Mo du cahier des charges bibliothèque. Un sous-ensemble latin le ramènerait
autour de 150 Ko. Non fait à l'étape 2, faute d'outil de sous-ensemble dans la
chaîne ; à traiter quand le budget de démarrage sera mesuré pour de vrai.

## Pièges rencontrés, à ne pas repayer

### `phosphor_flutter` ne compile plus, et aucune version ne le corrige

Le paquet 2.1.0, dernière version publiée, fait `class PhosphorIconData extends
IconData`. Sous Flutter 3.47, `IconData` est une classe `final` : la
compilation échoue. **`dart analyze` ne le voit pas**, seul `flutter test` ou un
build le révèle. Ne pas conclure trop vite qu'un `analyze` vert suffit.

Résolu en intégrant les deux graisses utiles en assets (`assets/fonts/Phosphor-Regular.ttf`
et `Phosphor-Fill.ttf`, licence MIT dans `assets/fonts/LICENSE-Phosphor.txt`) et
en déclarant les points de code dans `AppIcons`. Les `IconData` y sont **const**,
sans quoi l'élagage d'icônes échoue et fait tomber le build de production.

### Le stub `auth` de la CI était incomplet

`ci.yml` créait le schéma `auth` et la table `auth.users`, mais ni `auth.jwt()`
ni `auth.uid()`. Postgres valide le corps d'une fonction SQL à sa création :
`public.app_role()` échouait, donc la migration 0001 entière. Le job n'avait
jamais tourné (il ne se déclenche que sur une pull request vers `main`), donc
personne ne l'avait vu. Corrigé.

**Leçon générale : un job de CI qui n'a jamais tourné n'est pas un job vert.**

### slang lisait sa configuration deux fois

`slang.yaml` d'un côté, `build_runner` de l'autre, qui cherchait un `build.yaml`
et se rabattait sur une locale de base `en` inexistante. `build.yaml` désactive
désormais le builder slang. Deux commandes, dans cet ordre :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

### Le poste de travail ne fait pas confiance à `github.com`

Le magasin de racines de cette machine valide `raw.githubusercontent.com` mais
pas `github.com` (`SEC_E_UNTRUSTED_ROOT`), et bloque la vérification de
révocation sur `release-assets.githubusercontent.com`. Conséquence : le hook de
build de `package:sqlite3` ne peut pas télécharger sa bibliothèque native, et
**tout `dart run` ou `flutter test` du projet échoue** tant que ce n'est pas
réglé.

Contournement appliqué : bibliothèque récupérée par un autre chemin, empreinte
SHA-256 vérifiée contre celle publiée dans le paquet
(`2bf39f2a...`), puis déposée dans
`.dart_tool/hooks_runner/shared/sqlite3/build/download-2bf39f2a/sqlite3.dll`.
Le hook réutilise un fichier dont l'empreinte correspond.

**C'est un contournement local, pas un correctif.** Il disparaît à chaque
nettoyage de `.dart_tool`. Le vrai correctif est côté poste : installer la
racine manquante ou lever l'interception TLS. La CI n'est pas concernée.

Le mode développeur Windows est également désactivé, ce que Flutter réclame
pour les liens symboliques des greffons. À activer par `start ms-settings:developers`.

### `Get-Content` de PowerShell 5.1 détruit l'UTF-8

Un fichier parfaitement valide s'affiche en mojibake. Ne pas « corriger » un
accent sur la foi d'un affichage PowerShell : relire avec un outil qui respecte
l'encodage.

### Le chemin du dépôt contient des espaces

`D:\RA _APP\RA -OFFICIAL-APP`. Les builds Web et l'analyse passent. Si
`flutter build apk` ou `flutter build windows` échoue localement sur Gradle,
regarder ce point avant tout le reste. La CI compile dans un chemin propre.

## Écarts assumés par rapport à la spécification

| Point | Spécification | Ce qui est fait | Raison |
| :--- | :--- | :--- | :--- |
| Langues | « fichiers poular préparés mais vides » | Français rempli, arabe déclaré, **aucun poular** | Décision de l'opérateur du 6 septembre 2026, ADR-015 |
| Composants | « les huit composants partagés » (section 8) | Neuf | La section 2 en liste bien neuf : `ChoiceCardGroup` est arrivé avec l'ADR-013 et la section 8 n'a pas suivi |
| Sous-ensembles de polices | « réduites aux glyphes réellement utilisés » | Icônes élaguées, polices de texte entières | Aucun outil de sous-ensemble dans la chaîne ; mesure et gain consignés plus haut |
| Scénario 7 | Démarrage sous 1,5 s | Non mesuré | Aucun écran réel à charger avant l'étape 3 |

## Ce qui reste ouvert, hors périmètre de l'étape 2

- **Étape D de l'onboarding, les secrets.** Toujours non faite. Elle demande
  `supabase login`, `supabase link --project-ref gggmtelinlpseweouyav`, puis les
  secrets GitHub `SUPABASE_ACCESS_TOKEN` et `SUPABASE_DB_URL`. Le code n'en a
  pas besoin pour compiler : il lit sa configuration par `String.fromEnvironment`,
  voir `dart_define.example.json`.
- **Étape G, variantes `dev` / `staging` / `prod`.** L'identifiant est
  `com.rewayahacademy.app` pour les trois. Trois identifiants distincts
  restent à poser.
- **Étape F, Sentry.** Non faite.
- **Étape M, PWA.** Le build Web fonctionne ; le manifest, le service worker et
  l'URL déployée restent à faire.
- **`borderDefault`**, voir la décision en attente plus haut.
- **`child_ui_mode_max_age`** est toujours « à trancher » dans `app_config`.
  L'étape 2 n'en dépend pas : elle fournit les deux échelles, le seuil est lu à
  la création du profil, à l'étape 3.
