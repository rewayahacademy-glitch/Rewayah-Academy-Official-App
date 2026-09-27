# TC_AGENT_A_REPORT — Group Space et présentation du temps

> Lot construit dans `D:\RA_TC\a`, sur la baseline `0071557`.
> `flutter analyze lib test` : **propre** (0 problème). `flutter test test/teaching_core/a` :
> **107 tests, tous verts**. `git status --porcelain` : **aucun fichier hors ownership**.
>
> Ce rapport est écrit pour être relu par quelqu'un qui relancera mes commandes. Ce qui est mocké est
> dit mocké, ce qui manque est dit manquant.

---

## 1. Ce qui a été construit

### 1.1 Les contrats (`lib/core/tc_groupe/`, `lib/core/tc_horloge/`)

| Fichier | Contenu | État |
|---|---|---|
| `lib/core/tc_groupe/group_summary_vm.dart` | `GroupSummaryVM`, `EnseignantVM`, `TitreEnseignant`, `JetonCouleurGroupe`, `OccurrenceSeance`, `TypePublicGroupeVM` | Conforme à `CONTRACTS` §1. Champs identiques, plus trois dérivés sans état (`complet`, `placesLibres`, `rejoindreOuvert`) et une recomposition d'horloge (`avecHorloge`). |
| `lib/core/tc_groupe/group_home_vm.dart` | `GroupHomeVM`, `RoleEspaceGroupe`, `SlotAction`, `SlotBibliotheque`, `SlotProgression`, `SlotRoster` | Conforme à `CONTRACTS` §2. Le plafond de trois actions est tenu **par assertion**, et la fabrique `GroupHomeVM.pourRole` compose l'espace sans aucun accès réseau. |
| `lib/core/tc_horloge/session_clock_vm.dart` | `SessionClockVM`, `HorlogeAffichee`, `PhaseSeance`, `NoticeDst`, `EcheanceDst` | Conforme à `CONTRACTS` §3. Trois assertions gardent les invariants : pas de restant en prolongation, pas de restant après la fin, jamais de durée négative. |
| `lib/core/tc_horloge/fenetre_seance.dart` | `FenetreSeance` : les bornes d'une occurrence et la machine d'états de la spec §5.1, **en fonctions pures** | Neuf. C'est ici que se décide toute phase et tout temps restant du Teaching Core. |
| `lib/core/tc_groupe/port_groupes.dart` | `PortGroupes` + `portGroupesProvider`, `mesGroupesProvider`, `groupeProvider` | Deux méthodes, exactement celles du contrat. |
| `lib/core/tc_horloge/port_horloge_seance.dart` | `PortHorlogeSeance` + `portHorlogeSeanceProvider`, `horlogeGroupeProvider` | Trois méthodes, exactement celles du contrat. |

### 1.2 L'unification des comptes à rebours

La mission demandait que `SessionClockVM` **unifie** les calculs de temps existants plutôt que d'en
devenir le quatrième. Le dépôt en portait trois : `Seance.avantDebut()`
(`lib/core/planning/service_planning.dart:151`), `_compteARebours()` avec son `Timer.periodic`
(`lib/features/accueil_eleve/accueil_eleve_page.dart:656`) et un troisième minuteur dans
`journee_page.dart` **[PROTECTED]**.

Ce que j'ai fait, concrètement :

- **toute** décision de temps du lot passe par `FenetreSeance`, qui est pure et testée isolément ;
- **aucun widget de mon lot ne porte de minuteur.** La cadence de rafraîchissement appartient à
  l'implémentation du port (`PortHorlogeSeance.suivre`), et elle est décidée en un seul endroit. Le
  commentaire de `lib/core/presence/service_presence.dart` garde la trace d'un échec mesuré sur ce
  point précis : une boucle posée dans un écran continuait à tourner après la sortie de salle ;
- la coupure d'affichage à une heure et le remplissage des minutes reproduisent **exactement**
  `_compteARebours()` d'`ELV-02`. Deux écrans qui n'arrondiraient pas pareil feraient douter de
  l'heure du cours ;
- `SessionClockVM.calculeeAUtc` porte l'instant serveur de référence. `FenetreSeance` ne lit jamais
  l'horloge par elle-même : `maintenant` est toujours un paramètre.

**Je n'ai supprimé aucun des trois calculs existants** : deux sont hors de mon ownership et le
troisième est PROTECTED. L'unification est **conceptuelle et disponible** ; sa généralisation est un
geste d'Agent Z, qui peut faire pointer `Seance.avantDebut()` et `_compteARebours()` sur
`FenetreSeance` une fois les trois branches intégrées.

### 1.3 Les écrans

| Fichier | Écran |
|---|---|
| `lib/features/tc_mes_groupes/mes_groupes_page.dart` | « Mes groupes » : quatre états (chargement, échec, aucun groupe, liste), une ou deux colonnes selon la largeur. |
| `lib/features/tc_mes_groupes/carte_groupe.dart` | La carte du Groupe et son liseré de couleur. |
| `lib/features/tc_mes_groupes/photo_enseignant.dart` | La photo obligatoire, ou l'aveu qu'elle manque. |
| `lib/features/tc_espace_groupe/espace_groupe_page.dart` | L'Espace Groupe des quatre rôles, et l'identité de groupe partagée. |
| `lib/features/tc_espace_groupe/carte_session.dart` | La Session Card dominante, les deux horloges, la notice DST, le conseil d'appareil. |
| `lib/features/tc_espace_groupe/emplacements_groupe.dart` | Les emplacements « Avant le prochain cours », Bibliothèque, roster, progression. |
| `lib/features/tc_mes_groupes/routes_tc_a.dart` | `routesTcA()` : **retourne** des routes, ne construit jamais un `GoRouter`. |
| `lib/features/tc_mes_groupes/chemins_tc_a.dart` | Les chemins sous le préfixe réservé `/tc/`. |

Ce que la carte et l'Espace Groupe tiennent, et qui est mesuré :

- **la couleur n'est jamais seule.** `LisereGroupe` est `ExcludeSemantics` et le nom du groupe est
  toujours à côté. Invariant `J7`.
- **la capacité vient de la donnée.** `'$nombreMembres / $seuilMax'`. Un test monte `4 / 5` et `3 / 4`
  dans la même liste, et vérifie que `3 / 5` n'apparaît nulle part.
- **le titre est Sayyid ou Sayyida.** Un test parcourt les sept groupes de démonstration et refuse
  toute occurrence de « ustaz ».
- **le CTA « Rejoindre » n'apparaît que si `horloge.rejoindreOuvert`.** Aucun écran ne décide de la
  fenêtre : la décision vient de l'horloge, qui vient du port.
- **aucun compte à rebours négatif.** En prolongation, l'interface écrit « Cours toujours en cours »
  et ne montre aucun nombre. La pastille dit « En dépassement », pour ne pas répéter deux fois la même
  phrase dans une carte.
- **aucune conversion de fuseau dans un widget.** Les heures arrivent rendues, les villes sont
  lisibles, et un test refuse toute chaîne contenant « UTC+ ».
- **le conseil d'appareil est une ligne**, pas une fenêtre modale. Un test vérifie l'absence de
  `Dialog` et d'`AlertDialog`.

### 1.4 Ce qui a été réutilisé plutôt que redessiné

Le dépôt porte 38 widgets partagés. J'ai listé `lib/core/widgets/` avant d'écrire quoi que ce soit.

| Réutilisé | Où | Pourquoi pas un composant neuf |
|---|---|---|
| `PageShell` | Les deux écrans | Il tient la gouttière du gabarit, la largeur bornée à 1200, le centrage et le bandeau hors ligne. Aucun écran ne refait cela. |
| `AppCard` (zones `entete` / `actions`) | Carte de groupe, Session Card, ressources | Seul point d'entrée d'une surface de contenu. Le mode `dominante` est fait pour la Session Card. |
| `ActionPrincipale` | « Rejoindre », « Reprendre le cours », la sortie | Un bouton Material ramènerait la palette de Material et un état désactivé travaillé par transparence, sous le seuil de contraste. |
| `StatusPill` | État de phase, capacité, « Photo à fournir », échéance DST | Refuse par construction une pastille sans libellé : c'est `J7`, tenu par le composant et non par la vigilance. |
| `EmptyState` (`subi` / `bonneNouvelle`) | Aucun groupe, groupe introuvable, emplacement non branché | Les trois registres existent déjà et distinguent un état subi d'un état actionnable. |
| `Skeleton.tuileBento` | Chargement | Il prend la forme de ce qui arrive, et il diffère de 200 ms. |
| `SectionHeader` | Les quatre emplacements | Un titre de section avec compteur et action, déjà calibré. |
| `AvatarTile` | Photo enseignant **présente** | Son repli, son contour et son cadrage sont calibrés ; le redessiner ferait diverger deux avatars du même produit. |
| `OfflineBanner` / `horsLigneProvider` | État hors ligne | **Une seule source pour tout le produit.** Je n'ouvre aucun second abonnement `Connectivity`. |
| `AppGabarit` | Les trois largeurs | **Seul fichier du dépôt autorisé à comparer une largeur à un nombre.** Aucun de mes widgets ne connaît 600, 840 ni 1200. |
| `AppSpacing` / `Ecart`, `AppRadius`, `AppPalette` | Partout | Aucune valeur littérale d'espacement, de rayon ou de couleur n'est écrite dans mon lot. |

**Composants neufs, et pourquoi aucun des 38 ne convenait** : `CarteGroupe` (aucune carte existante ne
porte un liseré administré, une photo obligatoire et une capacité serveur), `LisereGroupe`,
`PhotoEnseignant` (voir §3.2), `CarteSession`, `NoticeChangementHeure`, et les quatre blocs
d'emplacement. Tous vivent dans mes répertoires, **aucun dans `lib/core/widgets/`** — ce répertoire
m'est interdit, et l'addendum de baseline rappelle qu'il est de toute façon verrouillé par un test
rouge préexistant sur la galerie.

---

## 2. Ce qui est mocké, et à quel point

### 2.1 Les deux doubles locaux

`GroupesDemonstrationLocale` (`lib/core/tc_groupe/demonstration_groupes.dart`) et
`HorlogeSeanceDemonstration` (`lib/core/tc_horloge/demonstration_horloge.dart`) sont **les
implémentations par défaut des deux providers**. Ce n'est pas un oubli : aucune lecture serveur ne peut
alimenter cette vue aujourd'hui, et un provider qui lèverait une exception rendrait la route
inutilisable pour Agent Z.

**Ce que le double invente, et que la base ne sait pas produire** :

| Donnée | Réalité en base à `0071557` |
|---|---|
| La prochaine occurrence d'un groupe | `sessions.groupe_id` existe (`0025`) mais **rien ne l'écrit** : le seul insert de `sessions` est `materialiser_seances(p_assignment_id)`, qui ignore les groupes. |
| L'heure rendue dans deux fuseaux | Aucune RPC ne rend de conversion, et le client ne peut pas convertir. |
| `join_opens_at` et la fenêtre de 20 minutes | Rien de persisté. La base refuse encore le jeton avant **T-10**, en dur, à deux endroits. |
| La couleur du groupe | `groupes` n'a aucune colonne de couleur. |
| Le cours et le niveau | `groupes` n'a ni `nom_cours` ni lien vers `programme_niveaux` — laquelle **n'est pas appliquée en base**. |
| La photo et le titre de l'enseignant | `teacher_profiles` n'a ni l'une ni l'autre. |
| La notice de changement d'heure | Rien, nulle part. |

**Le double est ancré sur un instant fixe** (`ancreDemonstration = 2026-09-21T11:32Z`) et c'est
délibéré. `HorlogeAffichee.heureLocaleRendue` est une chaîne **déjà convertie** ; aucune capacité ne
sait la produire. Un double qui lirait l'heure réelle afficherait un compte à rebours vivant à côté
d'heures fausses. L'ancre rend l'ensemble vérifiable ligne à ligne : « Lundi 21 septembre, 18:00 Riyad,
15:00 Conakry, cours dans 3 h 28 ». Agent Z peut injecter `() => DateTime.now().toUtc()` pour voir le
compte à rebours bouger, en sachant qu'il échange la cohérence des heures contre du mouvement.

**Sept groupes, sept états**, choisis pour couvrir et non pour faire nombre : avant la fenêtre, salle
ouverte, attente avant T0, cours en cours (avec notice DST à J-7), prolongation, terminée, et **un
groupe sans aucune occurrence** — parce que c'est l'état réel de la base, et qu'une démonstration qui
le cacherait mentirait sur ce qui reste à construire.

### 2.2 La palette de couleurs de groupe

`PaletteGroupe` compose avec **quatre** paires existantes du thème, là où la décision `D-18` en demande
**32 à 40**. Deux groupes sur cinq partagent donc leur teinte, et trois de ces quatre paires portent
déjà un sens dans le produit. **C'est un défaut assumé, pas une solution** : `app_palette.dart` est le
seul fichier autorisé à poser une couleur littérale et il m'est interdit. Demande chiffrée en §1.6 et
§4 du CONTRACT_REQUEST.

### 2.3 Les emplacements non branchés

`PortCatalogue` (Agent B) et `PortTravailAVenir` (Agent H) sont déclarés **sans implémentation** : leur
provider vaut `null`. Les blocs correspondants affichent alors un état « Bientôt disponible » explicite
plutôt qu'une étagère ou une liste de tâches inventées. Un emplacement qui simulerait son contenu
ferait disparaître le manque du radar exactement au moment où il faut le voir.

---

## 3. Décisions que j'ai prises, et que quelqu'un pourrait discuter

### 3.1 `PortRosterEnseignant` n'est pas stubé

C'est l'écart le plus visible avec l'ownership, et il est délibéré. Le stuber impose de copier
`TeacherStudentProjection` et sa chaîne — `ResumeSeance`, `AssiduiteRecente`, `EtatPresenceProjete`,
`LearningAssignment`, `StatutAssignation`, `IntentionPedagogique`, `ContentRange`, `ContentPosition` —
soit environ cent quatre-vingts lignes appartenant à trois autres agents, dont deux types qui **ne
compilent pas tels qu'écrits dans le contrat** (§3.3). Chaque ligne copiée est une occasion de
diverger, et toute divergence est un BLOCKER au contrôle pré-merge.

`CONTRACTS` §2 dit que `SlotRoster` est une **enveloppe vide** dont « le contenu est rendu par l'agent
propriétaire du port ». J'ai donc suivi le contrat : `BlocRoster` expose un paramètre `contenu`, et
`EspaceGroupePage.contenuRoster` le fait remonter jusqu'à l'hôte. Agent Z y branche la surface
d'Agent E en une ligne. **Arbitrage demandé** en §7 du CONTRACT_REQUEST.

Les deux autres ports consommés **sont** stubés, eux, parce que leur chaîne de types est close :
`PortCatalogue` et `PortTravailAVenir`.

### 3.2 Un composant `PhotoEnseignant` plutôt que `AvatarTile` nu

`D-01` interdit l'avatar générique silencieux. Or `AvatarTile` retombe sur les initiales aussi bien
quand la photo manque que quand elle ne charge pas. J'ai donc distingué deux cas que le composant
partagé confond :

- `photoUrlOuCle == null` : **la photo n'existe pas**. État explicite, pastille « Photo à fournir »,
  aucune initiale. C'est `D-01`.
- `photoUrlOuCle != null` mais URL non résolue : la photo **existe**, elle n'est pas encore signée,
  parce qu'aucune capacité ne sait la signer. `AvatarTile` est alors réutilisé tel quel, et ses
  initiales sont un état de chargement, pas un cache-misère.

Je le signale parce qu'un relecteur pressé pourrait lire le second cas comme une violation de `D-01`.

### 3.3 `ContentPosition` a dû être matérialisé pour compiler

Le contrat §7 déclare `const ContentPosition._();` et annonce quatre constructeurs nommés sans les
écrire : recopié à l'identique, il **ne compile pas**. J'ai matérialisé les quatre constructeurs
annoncés sans toucher au jeu de champs, et j'ai écrit l'écart en tête du fichier stub. Si la forme
d'Agent B diffère, **c'est la sienne qui prime**. Détail en §6 du CONTRACT_REQUEST.

### 3.4 L'Espace Groupe n'a pas de titre d'écran

`PageShell` accepte un `titre`, et je ne lui en donne pas pour l'Espace Groupe : l'identité du groupe
**est** le titre, avec sa photo, sa couleur et sa capacité. Un « Mes groupes » en tête répéterait mot
pour mot le libellé du chemin de sortie posé juste en dessous.

### 3.5 Le code Dart est sans accents, les documents en portent

Le protocole demande « le français, accents inclus ». Le dépôt, lui, écrit son Dart **sans accents** :
195 fichiers sur 212 sous `lib/` n'en contiennent aucun, et les commentaires du socle suivent cette
règle sans exception visible. J'ai suivi le dépôt pour le code et le protocole pour les documents et
le JSON de libellés, où les accents sont corrects. Les libellés visibles par l'utilisateur sont de
toute façon **accentués dans `tc_i18n_A.json`**, qui est la vraie source : la façade Dart est un
placeholder qu'Agent Z supprimera.

### 3.6 Le bouton « Rejoindre » est offert mais inactif tant qu'il n'est pas branché

L'entrée en Classe Live appartient à Agent E et passe par `BilletSalle`. Mes écrans prennent un rappel
`onRejoindre` ; tant qu'il est nul, le bouton **apparaît** quand la fenêtre est ouverte — parce que sa
présence est la chose que T-20 gouverne — mais reste **inactif**. On ne fait pas semblant d'ouvrir une
porte. Hors ligne, il est inactif également, quelle que soit la fenêtre.

---

## 4. Les tests

`flutter test test/teaching_core/a` → **107 tests, tous verts.**

| Fichier | Tests | Ce qu'il mesure |
|---|---|---|
| `fenetre_seance_test.dart` | 17 | Les bornes, les sept phases, le temps restant, l'absence de négatif à six instants, et une occurrence qui **traverse une transition d'heure d'hiver** sans bouger d'une minute. |
| `session_clock_vm_test.dart` | 16 | Les deux horloges, la contrepartie nulle quand les fuseaux coïncident, le restant dérivé de l'instant serveur, la notice DST transportée et non calculée, et la cohérence des sept groupes de démonstration. |
| `group_summary_vm_test.dart` | 20 | La capacité `4 / 5`, `3 / 4` et `2 / 6`, la photo absente, `depuisSql` qui rend `null` sur « ustaz », la composition par rôle, et l'assertion à quatre actions. |
| `carte_groupe_test.dart` | 12 | État normal, T-20, dépassement, séance terminée, absence d'occurrence, photo manquante, photo présente, ouverture au tap, groupe complet. |
| `mes_groupes_page_test.dart` | 8 | Liste, aucun groupe, échec avec « Réessayer », chargement, **hors ligne**, rappel d'entrée, groupe sans occurrence, et les six états du temps dans une seule liste. |
| `espace_groupe_page_test.dart` | 23 | Absence d'onglets et de barre latérale, ordre vertical stable, les deux horloges, un seul fuseau, le libellé côté enseignant, le conseil d'appareil, l'attente avant T0, la notice DST, les emplacements, « Reprendre le cours » contextuel, les états subis. |
| `responsive_test.dart` | 7 | Une colonne à 390, deux à 900, contenu centré et borné à 1440, et la même information aux trois largeurs. |
| `routes_tc_a_test.dart` | 4 | `routesTcA()` retourne des routes, le préfixe `/tc/`, la navigation carte → Espace Groupe, et le chemin de sortie. |

Les faux vivent dans `test/teaching_core/a/faux/` et l'hôte dans `test/teaching_core/a/support/`
(décision `D-06`). **Je n'ai pas touché `test/support/harnais.dart`** ; j'ai repris son patron d'hôte
(`ProviderScope` + `TranslationProvider` + `MaterialApp`) sans le modifier. Le `GoRouter` des tests est
construit dans `test/`, jamais dans `lib/`.

Un détail qui a son importance : le double d'horloge accepte une cadence nulle, qui ferme le flux après
sa première valeur. Un minuteur qui survit à la fin d'un test fait échouer le suivant, et c'est
exactement le défaut que `lib/core/presence/service_presence.dart` documente.

---

## 5. Vérifications lancées

| Commande | Résultat |
|---|---|
| `flutter analyze lib test` | **No issues found!** |
| `flutter test test/teaching_core/a` | **107 tests, all passed** |
| `dart format` sur mes quatre répertoires + `test/teaching_core` | 0 fichier à reformater |
| `git status --porcelain` | 5 entrées, **toutes dans mon ownership** |
| `dart run tool/verifier_jetons.dart` | **10 violations, toutes préexistantes, aucune dans mes fichiers** (voir §6) |

`git status --porcelain` rend exactement :

```
?? lib/core/tc_groupe/
?? lib/core/tc_horloge/
?? lib/features/tc_espace_groupe/
?? lib/features/tc_mes_groupes/
?? test/teaching_core/
```

plus les trois fichiers documentaires sous `docs/teaching-core/`.

⚠ **Un effet de bord que j'ai corrigé et que je signale** : lancer `dart run tool/verifier_jetons.dart`
déclenche les *build hooks* de Flutter, qui réécrivent
`windows/flutter/generated_plugin_registrant.cc`, `.h` et `generated_plugins.cmake`. Ces trois fichiers
sont apparus modifiés dans `git status` sans que je les aie touchés. Je les ai restaurés par
`git checkout --`. **Tout agent qui lance une commande `dart run` dans son worktree doit vérifier ces
trois fichiers avant de committer.**

---

## 6. Défauts préexistants rencontrés, et non corrigés

Hors de ma mission. Signalés, pas touchés.

### 6.1 `tool/verifier_jetons.dart` : 10 violations sur la baseline

```
lib/core/widgets/menu_filtre.dart:42,45                  [m-dash]
lib/core/widgets/nav_shell.dart:246,264,265              [m-dash]
lib/core/widgets/nav_shell.dart:461                      [bouton-material]  IconButton(
lib/core/widgets/nav_shell.dart:513                      [ontap-nu]
lib/core/widgets/sous_navigation_domaine.dart:63         [ontap-nu]
lib/features/admin_dossiers/dossiers_page.dart:267       [m-dash]
lib/features/admin_journal/journal_page.dart:198         [m-dash]
```

Tous dans des fichiers du socle ou de l'administration, **aucun dans mes répertoires**. Le vérificateur
sort donc en code 1 sur la baseline elle-même : quiconque l'invoque après moi doit savoir que ces dix
lignes ne viennent pas d'Agent A.

### 6.2 `GroupeAdmin.depuisJson` recode le fuseau en dur

`lib/core/admin/service_groupes.dart:69` écrit `fuseau: 'Europe/Paris'` parce que `groupes_admin()`
(`0019:241`) ne retourne pas `timezone_iana`. L'enseignant, lui, la lit correctement depuis `0025`.
**Fichier nommément interdit à Agent A.** Demande en §1.2 du CONTRACT_REQUEST.

### 6.3 Le défaut latent de T-20, toujours présent

`VuePresence.depuis` (`lib/core/presence/vue_presence.dart:70-85`) calcule la durée en salle depuis
`entre_le` brut, sans la borner à `debutSeance`. Le jour où la fenêtre passera à 20 minutes, un élève
entré à T-20 lira « en salle depuis 38 min » pour un cours commencé il y a 18. Le pendant SQL
(`etat_presence()`, `0010`) a le même défaut. **`D-13` m'interdit de l'éditer** : c'est un
CONTRACT_REQUEST, §1.11, et il doit être corrigé **en même temps** que la fenêtre, jamais après.

### 6.4 Les migrations `0020` à `0024` ne sont pas appliquées

Écrit noir sur blanc dans l'en-tête de `0025`, lignes 33-40. `programme_niveaux`,
`progression_historique` et `evaluations` **n'existent pas en base**. Toute demande qui s'appuie sur le
curriculum — dont mon `niveauHumain` — doit être ordonnancée après leur application, ou reproduire la
garde `to_regclass` d'`unite_curriculum()`.

### 6.5 Rappel de l'addendum de baseline

`supabase/migrations/0029` est écrite mais **pas appliquée** : en l'état, `dossiers_en_attente()` livre
nom et prénom de toute personne en attente de KYC à un appelant anonyme. Et
`test/.../catalogue_galerie_test` est rouge. Je ne les ai ni aggravés ni corrigés ; je n'ai ajouté
aucun composant dans `lib/core/widgets/`.

---

## 7. Ce qu'Agent Z devra brancher

Par ordre de dépendance.

1. **Le routeur.** Appeler `routesTcA()` depuis `app_router.dart`, promouvoir `CheminsTcA` dans
   `routes.dart`, et **ajuster `redirection.dart`** — sans quoi `/tc/groupes` est inatteignable, le
   préfixe `/tc/` n'appartenant à aucun rôle.
2. **L'entrée de navigation.** `nav_shell.dart` est plafonné à quatre destinations par assertion, et
   l'enseignant en a déjà quatre. **C'est un arbitrage produit**, pas un patch.
3. **Le rôle.** `EspaceGroupePage.role` vaut `eleve` par défaut. Le dériver de la session applicative.
   ⚠ `session_state.dart` documente que ni `AppRole` ni le JWT ne portent de permission plus fine
   qu'un rôle entier : la dérivation se fera depuis `AppRole`.
4. **Les deux ports d'Agent A.** Remplacer `GroupesDemonstrationLocale` et
   `HorlogeSeanceDemonstration` par les adaptateurs réels, une fois les sections 1.1 à 1.9 du
   CONTRACT_REQUEST livrées. Les deux providers sont déclarés au bon endroit et se surchargent sans
   toucher à mes écrans.
5. **Les trois ports consommés.** `portCatalogueProvider` (B), `portTravailAVenirProvider` (H), et la
   surface de roster d'Agent E via `EspaceGroupePage.contenuRoster`. Les trois emplacements affichent
   un état explicite tant qu'ils sont nuls : le branchement se voit immédiatement.
6. **L'entrée en Classe Live.** `MesGroupesPage.onRejoindre` et `EspaceGroupePage.onRejoindre`
   attendent le geste d'Agent E, `BilletSalle` compris.
7. **« Reprendre le cours ».** `EspaceGroupePage.onReprendreLeCours` attend la position de groupe
   d'Agent F (`SharedContentState`). Agent A pose l'action au bon moment, il ne restaure rien.
8. **L'i18n.** Fusionner `docs/teaching-core/i18n/tc_i18n_A.json` sous la racine `tc`, régénérer slang,
   remplacer les appels à `LibellesGroupe` et **supprimer** `lib/core/tc_groupe/libelles_tc_groupe.dart`.
   Le bloc `ar` du JSON ne porte que les deux titres, seule exception prévue par `D-02`.
9. **L'icône et les jetons.** Une icône (`tabletteOuOrdinateur`) et la palette administrée de 32 à 40
   teintes. Sans la seconde, la couleur de groupe reste à un huitième de ce que `D-18` demande.
10. **La photo signée.** `PhotoEnseignant.urlSignee` et `CarteGroupe.urlPhotoEnseignant` attendent une
    URL signée de courte durée, sur le modèle de `service_avatar.dart:148`. Tant qu'elle est nulle, un
    enseignant qui **a** une photo montre ses initiales.

---

## 8. Limites, dites sans détour

- **Aucune donnée réelle ne circule.** Les deux ports sont servis par des doubles. L'écran est juste ;
  ce qu'il montre est fabriqué.
- **Le double est figé dans le temps.** Compte à rebours et heures sont cohérents entre eux, mais ne
  bougent pas, faute de capacité serveur pour rendre les conversions.
- **La fenêtre de 20 minutes est une valeur de fixture.** La base refuse toujours le jeton avant T-10.
  Tant que §1.4 du CONTRACT_REQUEST n'est pas livrée **en entier**, un bouton offert à T-20 proposerait
  une porte que le serveur refuse.
- **La palette de groupe est à quatre teintes** au lieu de 32 à 40.
- **`PortRosterEnseignant` n'est pas stubé** ; le roster passe par un emplacement que l'hôte remplit.
- **La notice DST n'a aucune source.** Elle est affichée et testée, mais un seul groupe de
  démonstration en porte une, écrite à la main.
- **Le niveau humain dépend de `0020`, qui n'est pas appliquée.** `niveauHumain` est nullable et son
  absence est gérée, mais elle sera l'état normal un moment encore.
- **Je n'ai supprimé aucun des trois comptes à rebours existants.** L'unification est disponible, pas
  généralisée : deux des trois fichiers sont hors de mon ownership et le troisième est PROTECTED.
- **Aucune vérification visuelle réelle.** Je n'ai lancé ni appareil, ni navigateur : les preuves sont
  des tests de widget à 390, 900 et 1440 de large, pas des captures.
