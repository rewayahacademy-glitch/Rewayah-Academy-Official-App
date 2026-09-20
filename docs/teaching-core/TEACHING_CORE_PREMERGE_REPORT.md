# TEACHING_CORE_PREMERGE_REPORT.md

> Contrôle pré-merge du Teaching Core — première émission 20/09/2026,
> **clôture 20/09/2026 après la passe de correction A + H.**
> **Aucune fusion n'a été faite. Aucune branche n'a été modifiée par ce contrôle.** Ce document
> constate ; il n'intègre pas et il n'autorise pas.
> Le dépôt principal `D:\RA _APP\RA -OFFICIAL-APP` n'a été ouvert ni en lecture, ni en écriture,
> ni comme répertoire courant.

## Verdict de clôture

**Les neuf branches sont conformes. Zéro BLOCKER DE BRANCHE.**
**L'intégration reste conditionnée au socle de données, qui n'existe pas.**

Ces deux phrases ne se contredisent pas, et le § 9 explique pourquoi la première ne suffit pas à
autoriser la seconde. Le rapport distingue désormais deux familles que sa première émission
mélangeait, ce qui rendait son verdict illisible :

| | |
|---|---|
| **(a) BLOCKERS DE BRANCHE** — ownership enfreint, stub divergent, suite de tests rouge | **0** |
| **(b) CONDITIONS D'INTÉGRATION** — ce qui manque hors des branches (SQL, arbitrages, socle) | **11, dont 4 dures** |
| **Intégration autorisée** | **NON — (a) est vide, (b) ne l'est pas** |

La règle de la spécification (« aucune intégration tant qu'un seul lot est BLOCKED ») est
**satisfaite**. Ce n'est plus elle qui retient l'intégration : c'est le § 9.2.

---

## 0. Méthode, et ce qui distingue ce rapport des audits qui l'alimentent

Ce rapport s'appuie sur trois audits en lecture seule (ownership, cohérence des stubs,
consolidation des demandes) et sur **trois passes de correction** : C et D sur `ContentPosition` et
`ContentRange`, puis A sur `ContentPosition`, puis A et H sur `portTravailAVenirProvider`. Les trois
sont décrites au § 2.5.

Tout ce qui est chiffré ici a été **remesuré** pour ce rapport, y compris quand un audit l'affirmait
déjà. Trois affirmations d'audit n'ont pas survécu à la mesure et sont corrigées au § 7. C'est la
raison d'être de cette passe : trois audits qui se recopient l'un l'autre produisent une certitude
qui n'a été vérifiée qu'une fois.

**Ce que la passe de clôture a revérifié elle-même**, sans se fier aux rapports des agents ni à la
première émission : la coïncidence des deux déclarations de `portTravailAVenirProvider` (comparaison
de chaîne exacte, dans les deux fichiers) ; la correspondance du stub `ContentPosition` d'A au
canonique de B (recherche de sous-chaîne ordinale sur le contenu entier) ; l'ownership des neuf lots
(chaque chemin confronté un par un aux préfixes de `FILE_OWNERSHIP` §5.1) ; les 28 en-têtes de stub
et les 129 imports qui pointent dessus ; les 27 enums de stub comparés à leur canonique ; et les
mesures `analyze` + `test` des deux lots corrigés, rejouées. Là où ce contrôle contredit la première
émission, c'est écrit et chiffré, y compris quand la première émission était de ma propre main.

Ce qui n'a **pas** été fait, et qu'il ne faut pas lire entre les lignes : aucun écran n'a été ouvert,
aucun parcours utilisateur n'a été joué, aucune requête d'écriture n'a été émise en base. Les tests
mesurés ci-dessous sont ceux que les agents ont écrits, contre les doubles que les agents ont écrits.
Voir le § 8.

---

## 1. Origine des neuf branches

Les neuf branches descendent bien de la baseline commune `0071557`
(`git merge-base --is-ancestor 0071557 HEAD` → vrai sur les neuf).

| Lot | Branche | HEAD | Fichiers | Ajouts | Modifications | Suppressions |
|---|---|---|---|---|---|---|
| A | `teaching-core/a-group-space` | `28c2238` | 36 | 36 | 0 | 0 |
| B | `teaching-core/b-library` | `d5bc5bf` | 36 | 36 | 0 | 0 |
| C | `teaching-core/c-quran` | `e60c5b4` | 32 | 32 | 0 | 0 |
| D | `teaching-core/d-teaching-tools` | `bc40b4a` | 37 | 37 | 0 | 0 |
| E | `teaching-core/e-classroom` | `4e65e50` | 39 | 39 | 0 | 0 |
| F | `teaching-core/f-realtime` | `bf01953` | 32 | 32 | 0 | 0 |
| G | `teaching-core/g-observation` | `3545f8c` | 31 | 31 | 0 | 0 |
| H | `teaching-core/h-academic` | `a9b295b` | 39 | 39 | 0 | 0 |
| Q | `teaching-core/q-qa` | `8337531` | 39 | 39 | 0 | 0 |
| | **Total** | | **321** | **321** | **0** | **0** |

**Les 321 chemins sont des ajouts. Zéro fichier préexistant n'a été touché par un agent.**
(`git diff --name-status 0071557 HEAD` sur les neuf.) Conséquence directe pour Agent Z : aucun merge
d'agent ne peut écraser une décision prise ailleurs dans le dépôt. Les seuls conflits possibles sont
ceux qu'Agent Z créera lui-même dans le routeur, l'injection de dépendances et les fichiers i18n,
et ceux qu'un rebase sur un `TARGET_SHA` postérieur à `0071557` apporterait.

Les neuf arbres de travail sont propres (`git status --porcelain` vide sur les neuf après
restauration du bruit de génération ; voir le § 5.3).

---

## 2. État par lot

### 2.1 Tableau de synthèse

`flutter analyze lib test` et `flutter test test/teaching_core/<lot>` ont été **exécutés pour ce
rapport** sur les sept lots A, B, E, F, G, H, Q. Les chiffres de C et D proviennent de la passe de
correction, qui les a mesurés de façon indépendante sur les commits d'alignement `e60c5b4` et
`bc40b4a`.

Les lignes **A** et **H** ont été **remesurées une seconde fois à la clôture**, sur les commits de
correction `28c2238` et `a9b295b` : `No issues found!` des deux côtés, `+109` pour A et `+75` pour H,
zéro échec. Ce sont ces chiffres-là qui figurent ci-dessous.

| Lot | Fichiers | Répertoires touchés | Ownership | `flutter analyze` | `flutter test` | Statut |
|---|---|---|---|---|---|---|
| **A** | 36 | `lib/core/tc_groupe`, `lib/core/tc_horloge`, `lib/features/tc_mes_groupes`, `lib/features/tc_espace_groupe`, `test/teaching_core/a`, `docs/teaching-core` | conforme | `No issues found!` | **109 / 109** | READY WITH CONTRACT CHANGE |
| **B** | 36 | `lib/core/tc_bibliotheque`, `lib/core/tc_telechargement`, `lib/features/tc_catalogue`, `test/teaching_core/b`, `docs/teaching-core` | conforme | `No issues found!` | **95 / 95** | READY WITH CONTRACT CHANGE |
| **C** | 32 | `lib/core/tc_coran`, `lib/features/tc_mushaf`, `test/teaching_core/c`, `docs/teaching-core` | conforme | `No issues found!` | **94 / 94** | READY WITH CONTRACT CHANGE |
| **D** | 37 | `lib/core/tc_outils`, `lib/features/tc_dock`, `test/teaching_core/d`, `docs/teaching-core` | conforme | `No issues found!` | **85 / 85** | READY WITH CONTRACT CHANGE |
| **E** | 39 | `lib/core/tc_classe`, `lib/features/tc_classe_live`, `test/teaching_core/e`, `docs/teaching-core` | conforme | `No issues found!` | **93 / 93** | READY WITH CONTRACT CHANGE |
| **F** | 32 | `lib/core/tc_realtime`, `lib/core/tc_etat_partage`, `test/teaching_core/f`, `docs/teaching-core` | conforme | `No issues found!` | **61 / 61** | READY WITH CONTRACT CHANGE |
| **G** | 31 | `lib/core/tc_observation`, `lib/features/tc_observation_ui`, `test/teaching_core/g`, `docs/teaching-core` | conforme | `No issues found!` | **75 / 75** | READY WITH CONTRACT CHANGE |
| **H** | 39 | `lib/core/tc_parcours`, `lib/features/tc_flux_academique`, `test/teaching_core/h`, `docs/teaching-core` | conforme | `No issues found!` | **75 / 75** | READY WITH CONTRACT CHANGE |
| **Q** | 39 | `test/teaching_core/q`, `test/teaching_core/fixtures`, `docs/teaching-core` | conforme, **une exception déclarée** | `No issues found!` | **104 / 104** | READY WITH CONTRACT CHANGE |

**791 tests, tous verts, sur les neuf lots. Neuf `flutter analyze` propres.** Les neuf agents avaient
déclaré ces chiffres dans leur rapport ; les neuf déclarations se vérifient au test près. C'est un
fait qui mérite d'être écrit, parce qu'il n'allait pas de soi.

Les six tests d'écart avec les 785 de la première émission sont **six ajouts**, pas un recomptage :
A passe de 107 à 109 et H de 71 à 75, et les deux diffs de test sont en **additions pures**
(A : 80 insertions / 0 suppression ; H : additions seules sur deux fichiers). Aucun test n'a été
supprimé, neutralisé ni marqué `skip` pour verdir une suite — c'est le premier réflexe de vérification
quand un compte de tests bouge en même temps qu'un correctif, et il ne trouve rien ici.

**Aucun lot n'est READY sec, et c'est le fait le plus important de ce tableau.** Le statut
« READY WITH CONTRACT CHANGE » ne veut pas dire « presque fini » : il veut dire que le lot compile,
que ses tests passent, qu'il ne déborde de son périmètre nulle part, **et qu'il ne lit aucune donnée
réelle** parce que les tables qu'il interroge n'existent pas en base. Le § 8 le détaille lot par lot.

### 2.2 Ownership — le croisement des neuf listes

Le contrôle décisif n'est pas la lecture du document de disjonction, c'est le croisement des neuf
listes de fichiers. Il a été refait pour ce rapport :

```
Somme des fichiers par branche : 321
Chemins distincts              : 321
Intersections                  : 0
```

L'égalité des deux nombres est la preuve arithmétique qu'aucun chemin n'est touché par deux
branches. Il n'y a **aucune intersection à arbitrer** : `git merge` ne produira aucun conflit de
contenu entre les neuf branches.

Quatre répertoires de premier niveau sont touchés, et seulement quatre : `docs/teaching-core`,
`lib/core`, `lib/features`, `test/teaching_core`. Ce sont les quatre zones neuves du chantier.

**Une seule exception, bénigne, chez Q.** `docs/teaching-core/i18n/tc_i18n_Q.json` est le seul des
321 chemins qui tombe hors des préfixes déclarés de son propriétaire. Deux documents normatifs sont
en tension : `TEACHING_CORE_FILE_OWNERSHIP.md` n'attribue à Q que quatre livrables et lui donne
« sous-arbre i18n : aucun », tandis que `TEACHING_CORE_PROTECTED_FILES.md` §4.2 énumère bien
`tc_i18n_Q.json` parmi les neuf fichiers de libellés. Q a tranché du côté de la production **et a
déclaré l'écart** au lieu de le taire (`TC_CONTRACT_REQUEST_Q.md` §7). Le fichier porte
`"tc": {}` — aucun libellé, aucune collision possible. Ce n'est pas une violation d'ownership ; c'est
une ambiguïté documentaire, tranchée dans le plan d'intégration.

### 2.3 Lot A — ce qui l'a bloqué, et ce qu'il en reste

La première émission classait A BLOCKED sur trois écarts formels. **Les deux premiers sont corrigés**
(§ 2.5) ; le troisième subsiste et **a changé de famille** : ce n'est pas un défaut de branche, c'est
une condition de la boucle de fusion d'Agent Z.

**(a) Stub `ContentPosition` désynchronisé — CORRIGÉ**, commit `28c2238`. Le détail de la
vérification est au § 2.5.

**(b) Deux stubs d'A déclarent un provider**, ce que la règle 1 de `FILE_OWNERSHIP` §3 interdit
(« Jamais une implémentation »). **L'un des deux est tranché** : `portTravailAVenirProvider` est
désormais une forme canonique arbitrée, écrite à l'identique chez A et chez H, et la déclaration est
donc voulue plutôt que subie (§ 2.5). **L'autre subsiste** : `portCatalogueProvider` reste déclaré
`Provider<PortCatalogue?>` rendant `null` chez A, quand B le déclare `Provider<PortCatalogue>`
rendant `CatalogueLocal()`. Ce n'est pas un plantage mais une perte de signal (§ 4.3), et c'est une
condition d'intégration, pas un blocage de branche.

**(c) `tc_i18n_A.json` n'a pas la structure imposée.** `PROTECTED_FILES` §4.2 impose un JSON borné à
la racine `tc`. Vérifié à la clôture, fichier par fichier, sur les neuf : huit portent bien `tc` à la
racine (parfois précédé d'une clé de commentaire ignorable — `_commentaire`, `_lisez_moi`, `_comment`,
`_lisezMoi`, `_note`) ; **A seul porte `_meta`, `fr`, `ar` et aucun `tc` racine.** Une boucle de
fusion uniforme sur les neuf fichiers sauterait A entièrement et **perdrait silencieusement** tous
les libellés de l'Espace Groupe, ainsi que les deux seules valeurs arabes autorisées du chantier. La
motivation d'A est légitime et écrite dans son `_meta.fusion` — il a besoin d'un bloc `ar` pour
l'exception D-02 (titres سيد / سيدة), que le format mono-racine ne sait pas exprimer.

Le format reste non conforme, **et c'est délibérément qu'il n'est plus compté comme un BLOCKER de
branche** : le lot compile, ses tests passent, et ce fichier n'est lu par aucun code. Il ne devient
dangereux qu'au moment où Agent Z écrit sa boucle de fusion. Il est donc porté au § 9.2 comme
condition dure, avec la vérification qui l'attrape.

**Portée mesurée de l'ancien écart (a) :** elle était nulle en exécution. A n'exploitait
`ContentPosition` que comme type de champ, jamais en égalité. Ce qui bloquait, c'était la règle, et
elle est bonne : un stub qui diverge de son canonique est une bombe à retardement, qu'elle ait
explosé ou non pendant la phase parallèle.

### 2.4 Lots C et D — les deux remises au vert du contrôle précédent

Le contrôle précédent bloquait C et D. Les deux corrections ont été vérifiées par comparaison
programmatique, pas par relecture :

- **C** (`e60c5b4`) : le fichier canonique de B est contenu **à l'octet près** dans le stub de C, de
  même que le corps de `content_range.dart`. Après substitution des deux corps, le résidu se réduit
  aux dix lignes d'en-tête `// TC-STUB-PORT:`, tolérées. Les quatre divergences signalées sont
  levées. 94 tests, compte identique à avant correction : aucun test n'a été supprimé pour verdir la
  suite. Le commit ne touche aucun fichier de test.
- **D** (`bc40b4a`) : comparaison ordinale `-ceq` sur les deux stubs → vrai, longueurs égales. Le
  constructeur non contractuel `ContentRange.ponctuelle` a disparu de tout le worktree ; son unique
  appelant a été réécrit et l'équivalence sémantique de la réécriture a été vérifiée, pas seulement
  sa compilation. 85 tests, compte identique à avant correction, vérifié déclaration par déclaration
  contre le commit antérieur.

Les deux corrections tiennent. Les deux lots restent READY WITH CONTRACT CHANGE parce qu'ils
dépendent encore de demandes de contrat pour fonctionner réellement — ce qui est le cas des neuf lots.

### 2.5 CORRECTIONS APPORTÉES APRÈS LE PREMIER CONTRÔLE — 20/09/2026

Trois passes de correction se sont succédé entre la première émission de ce rapport et sa clôture.
Toutes trois portent sur la **cohérence des contrats entre worktrees**, jamais sur la logique métier.
Aucune n'a ajouté ni supprimé de fichier : les neuf branches comptent toujours 321 chemins, tous en
ajout pur depuis `0071557`.

#### Passe 1 — C et D sur `ContentPosition` et `ContentRange` (avant la première émission)

Commits d'alignement `e60c5b4` (C) et `bc40b4a` (D). Détail au § 2.4. Retenus ici pour que la
chronologie des trois passes soit lisible d'un seul tenant.

#### Passe 2 — A sur `ContentPosition` (commit `28c2238`)

Le stub d'A a été resynchronisé sur le canonique d'Agent B, comme l'AMENDEMENT 1 l'exigeait.

**Vérifié à la clôture, sur le contenu entier et non par échantillonnage.** Le canonique de B
(`D:\RA_TC\b\lib\core\tc_bibliotheque\content_position.dart`, 5 985 octets) est retrouvé comme
**sous-chaîne ordinale exacte** du stub d'A (6 515 octets), à l'index **530**, avec un suffixe
résiduel de longueur **0**. Autrement dit :

```
stub A  =  en-tête de 530 octets  +  canonique de B, octet pour octet
6515    =  530                    +  5985
```

Il n'y a donc pas « peu » de divergence : il n'y en a **aucune** après l'en-tête. LF pur des deux
côtés, zéro CRLF. Les cinq manques signalés par la première émission sont tous comblés : `valeurSql`
sur chaque membre de `TypeAncrage`, `static TypeAncrage? depuisSql(String?)`, les quatre assertions
du constructeur privé, `operator ==` et `hashCode`. L'en-tête de 530 octets est la seule différence,
il est de la forme tolérée `// TC-STUB-PORT:`, et il pointe correctement vers le canonique de B et
vers l'AMENDEMENT 1.

**Aucun `ContentRange` n'a été stubé chez A, et c'est justifié** — zéro occurrence du symbole dans
tout `D:\RA_TC\a\lib`, aucun fichier `content_range.dart`. A n'a donc recopié aucun code de B dont il
n'avait pas besoin.

#### Passe 3 — A et H sur `portTravailAVenirProvider` (commits `28c2238` et `a9b295b`)

C'est l'arbitrage de fond de cette passe, et il mérite d'être écrit en entier parce qu'il ne se
déduit d'aucune règle mécanique.

**Le désaccord.** Le symbole était déclaré deux fois, de deux façons incompatibles, et **chacun des
deux agents avait une raison valable** :

| | Forme | Raison invoquée |
|---|---|---|
| Agent A | `Provider<PortTravailAVenir?>` rendant `null` | « Tant qu'il vaut `null`, le bloc *Avant le prochain cours* affiche son état non branché plutôt qu'une liste inventée. » |
| Agent H | `Provider<PortTravailAVenir>` levant `UnimplementedError` | « Échouer plutôt que rendre un bloc vide qui ferait croire à un groupe sans travail. » |

Les deux craintes sont légitimes et devaient **toutes deux** être honorées. En l'état, la forme
composite compilait sans un mot du compilateur et **levait dès le premier build** : l'Espace Groupe
serait passé d'un état vide propre à un plantage.

**La forme retenue**, écrite à l'identique des deux côtés :

```dart
final Provider<PortTravailAVenir?> portTravailAVenirProvider =
    Provider<PortTravailAVenir?>((Ref ref) => null);
```

**La règle sémantique**, qui est le cœur de l'arbitrage et qui devait être écrite en commentaire de
documentation au-dessus du provider des deux côtés :

- `null` = port **NON BRANCHÉ**. Le consommateur affiche un état explicite « non branché »,
  **JAMAIS** « aucun travail à faire ».
- non-`null` + liste vide = port branché, et il n'y a **réellement** aucun travail. C'est le **seul**
  cas où l'interface a le droit de dire qu'il n'y a rien à préparer.

C'est précisément la distinction que la forme `throw` rendait impossible à exprimer et que la forme
« `null` nu » laissait ambiguë. Le type porte l'information, au lieu de la confier à une convention
que le prochain lecteur ignorerait.

**Vérification de clôture, faite sur les fichiers et non sur les rapports d'agent :**

| Contrôle | Résultat |
|---|---|
| Déclaration identique au caractère près chez A (`a\lib\core\tc_groupe\ports_externes\port_travail_a_venir.dart`) et chez H (`h\lib\core\tc_parcours\port_travail_a_venir.dart`) | **oui**, la chaîne exacte est présente des deux côtés |
| Une seule déclaration du symbole par worktree | **oui**, une occurrence de `portTravailAVenirProvider =` de chaque côté |
| Plus aucune levée | **oui**, zéro `UnimplementedError` et zéro `throw` dans les deux fichiers |
| Règle sémantique écrite en commentaire de documentation des deux côtés | **oui**, dans les deux fichiers, avec la même distinction `null` / liste vide |
| Le consommateur honore la distinction | **oui** — voir ci-dessous |

Le dernier point est le seul qui compte vraiment pour un utilisateur, et c'est le seul que la
déclaration du provider ne prouve pas. Il est vérifié dans le code de rendu d'A :

- `a\lib\features\tc_espace_groupe\espace_groupe_page.dart:178` lit
  `final PortTravailAVenir? travail = ref.watch(portTravailAVenirProvider);` et alimente
  `portBranche: travail != null` (ligne 187) ;
- `a\lib\features\tc_espace_groupe\emplacements_groupe.dart:63-70` teste **`if (!portBranche)` avant
  `else if (actions.isEmpty)`**.

C'est cet **ordre** qui rend l'arbitrage effectif : l'ordre inverse aurait donné le même rendu aux
deux états et le commentaire de documentation n'aurait rien garanti. Côté H, `BlocAvantProchainCours`
teste symétriquement `actions == null` avant `actions.isEmpty`. La branche est donc câblée jusqu'à
l'écran des deux côtés, pas seulement déclarée.

**Vérification annexe qui n'allait pas de soi.** Un provider dont les deux déclarations coïncident ne
sert à rien si son **type de retour** diverge. `SlotAction` a donc été comparé : canonique chez A
(`lib\core\tc_groupe\group_home_vm.dart`), stubé chez H
(`lib\core\tc_parcours\ports_externes\slot_action.dart`), mêmes champs, même constructeur. La
signature `avantProchainCours({required String groupeId, String? studentId})` est identique des deux
côtés. L'arbitrage tient de bout en bout, et pas seulement sur la ligne du provider.

#### Ce que les trois passes n'ont pas touché

Mesuré à la clôture sur les neuf branches : `git diff --name-only 0071557 HEAD -- supabase/
pubspec.yaml pubspec.lock` rend **zéro chemin sur les neuf**. Les corrections n'ont ouvert aucune
porte de service : ni migration, ni dépendance. Les neuf arbres de travail sont propres.

---

## 3. Les `TC_CONTRACT_REQUEST` collectés

Les neuf existent, sont lisibles et sont substantiels. Vingt-huit livrables documentaires au total :
trois par agent de A à H (rapport, demande de contrat, fichier i18n), quatre pour Q
(`TC_TEST_PLAN.md` en plus).

| Lot | Demande de contrat | Nature du besoin dominant |
|---|---|---|
| A | `TC_CONTRACT_REQUEST_A.md` | 11 objets SQL, 1 icône, la palette de 32-40 teintes, `timezone`/`intl` conditionnels |
| B | `TC_CONTRACT_REQUEST_B.md` | 6 objets SQL (le catalogue), **`pdfrx`** — seule dépendance ferme du chantier —, 4 icônes, 1 table Drift |
| C | `TC_CONTRACT_REQUEST_C.md` | 3 objets SQL, `pg_trgm`, 2 méthodes sur un fichier PROTECTED, l'identifiant canonique du Coran |
| D | `TC_CONTRACT_REQUEST_D.md` | 4 tables, 10 icônes, 1 table Drift, l'arbitrage `shared_preferences` (qu'il refuse lui-même) |
| E | `TC_CONTRACT_REQUEST_E.md` | 2 objets SQL, 4 signatures de contrat manquantes, la promotion de la galerie vidéo |
| F | `TC_CONTRACT_REQUEST_F.md` | 2 objets SQL, **2 fichiers PROTECTED** (`video_session_provider`, `livekit_session_provider`) |
| G | `TC_CONTRACT_REQUEST_G.md` | 12 objets SQL dont l'enum `participant_role`, 5 icônes, 1 fichier PROTECTED |
| H | `TC_CONTRACT_REQUEST_H.md` | 6 objets SQL, 4 amendements de contrat, 2 arbitrages de confidentialité |
| Q | `TC_CONTRACT_REQUEST_Q.md` | 4 demandes de **vérifiabilité** (pas de table pour lui-même), 3 types à promouvoir |

Consolidées et dédupliquées, ces neuf demandes forment **63 objets SQL distincts** (le détail et
l'ordre de dépendance sont dans `TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md` § 4), plus 2 seaux
Storage hors SQL, 20 icônes, un lot de jetons de couleur, 1 dépendance `pubspec` à trancher,
1 migration Drift, et 20 arbitrages dont 6 exigent une décision humaine.

Onze demandes sont des doublons entre deux agents qui ne se sont pas parlé. Elles font **onze
tickets, pas vingt-deux** ; le plan d'intégration les fusionne nommément.

---

## 4. Duplications de service, de provider, de route ou de modèle

Recherche menée sur les 321 fichiers, et non sur les documents d'ownership.

### 4.1 Routes — aucune collision

Cinq fonctions `routesTc<X>()` produisent sept chemins, deux à deux distincts :

| Fonction | Chemins |
|---|---|
| `routesTcA` | `/tc/groupes`, `/tc/groupes/:groupeId` |
| `routesTcB` | `/tc/bibliotheque`, `/tc/bibliotheque/:resourceId` |
| `routesTcC` | `/tc/mushaf` |
| `routesTcE` | `/tc/classe` |
| `routesTcG` | `/tc/observation/:seanceId` |

Les cinq segments — `groupes`, `bibliotheque`, `mushaf`, `classe`, `observation` — sont distincts :
aucune collision de chemin, aucune collision de préfixe. D, F, H et Q ne posent aucune route, ce qui
est conforme à leur nature (D s'insère par un port de dock, F n'a pas d'interface, H remplit des
slots, Q ne produit aucune interface).

### 4.2 Routeur — aucun second `GoRouter`

Mesuré sur les dix worktrees, worktree témoin `D:\RA_TC\0` compris : **exactement un `GoRouter(` par
worktree**, toujours `lib/core/router/app_router.dart:80`, et ce fichier est **intact** dans les neuf
diffs. Aucun agent n'a construit un second routeur dans `lib/`. Les `GoRouter` de test vivent tous
sous `test/teaching_core/<lettre>/support/`, emplacement explicitement autorisé.

### 4.3 Providers — une collision réglée, une qui subsiste

Ce sont les deux seules duplications de provider du chantier. **L'une est close**, l'autre reste à
trancher par Agent Z.

| Symbole | Chez A | Chez le producteur | État à la clôture |
|---|---|---|---|
| `portTravailAVenirProvider` | `Provider<PortTravailAVenir?>` rendant `null` | **idem chez H**, à l'identique | **RÉGLÉ** (§ 2.5, passe 3). La levée a disparu, la règle sémantique `null` / liste vide est écrite des deux côtés et honorée par le consommateur. Le plantage au premier build est éliminé. |
| `portCatalogueProvider` | `Provider<PortCatalogue?>` rendant `null` | `Provider<PortCatalogue>` rendant `CatalogueLocal()` (B, `donnees_catalogue.dart:31`) | **OUVERT.** Pas de panne : une **perte de signal**. Le garde `catalogue == null` devient du code mort et « non branché » devient indiscernable d'« étagère vide ». |

**Pourquoi le second n'est pas traité comme le premier.** Il ne produit aucun plantage, et sa
résolution n'est pas symétrique : chez `portTravailAVenir`, les deux côtés n'avaient **aucune**
implémentation à proposer, donc `null` était la vérité des deux côtés. Chez `portCatalogue`, B a une
implémentation réelle (`CatalogueLocal()`) et A ne le sait pas. Adopter la forme nullable ferait
perdre à B son branchement ; adopter la forme non-nullable ferait perdre à A son état « non
branché ». C'est un arbitrage produit que ce contrôle n'a pas mandat de rendre, et qui appartient à
Agent Z au moment où B et A se rencontrent (§ 9.2, condition 5). **La règle sémantique établie au
§ 2.5 lui donne le patron** : si A doit continuer à distinguer « non branché » d'« étagère vide »,
c'est la forme nullable qui gagne et B branche par `overrideWithValue`.

### 4.4 Modèles — deux collisions de nom de classe

Mesure : 352 déclarations de classe distinctes hors `ports_externes` sur les huit lots de
production, dont **deux** portent le même nom chez deux lots.

| Nom | Hôte (coquille qui attend) | Réel (implémentation) |
|---|---|---|
| `BlocAvantProchainCours` | `a\lib\features\tc_espace_groupe\emplacements_groupe.dart:40` (`StatelessWidget`) | `h\lib\features\tc_flux_academique\bloc_avant_prochain_cours.dart:29` (`ConsumerWidget`) |
| `SurfaceBibliotheque` | `e\lib\features\tc_classe_live\slots_tc_classe.dart:114` (`StatelessWidget`) | `b\lib\features\tc_catalogue\surface_bibliotheque.dart:49` (`ConsumerStatefulWidget`) |

Elles ne gênent personne aujourd'hui, les deux lots étant isolés. Le jour où un fichier importera les
deux sans préfixe, Dart rendra `ambiguous_import`. Remède recommandé : renommer les **hôtes**, jamais
les implémentations.

### 4.5 Types de contrat — 28 stubs et 9 doubles, aucune divergence sauvage

Vingt-huit fichiers stub existent, répartis sur six worktrees (**A 4, C 3, D 4, E 6, F 3, H 8**) ;
B, G et Q n'ont aucun répertoire `ports_externes`. Les vingt-huit portent l'en-tête
`// TC-STUB-PORT:`. Agent Q porte en plus **9 doubles de contrat** sous
`test/teaching_core/fixtures/contrats/`, sous l'en-tête différent `// TC-DOUBLE-CONTRAT:` — un grep
d'intégration sur le seul marqueur `TC-STUB-PORT` les manquerait tous les neuf.

Point important pour la suite : **aucun agent n'a inventé de méthode absente du contrat.** Toutes les
divergences constatées sont des sous-ensembles — des membres manquants — jamais des sur-ensembles.
C'est ce qui rend la remise au canonique mécanique plutôt que négociée, sauf pour le provider
`portCatalogue` du § 4.3, où la sémantique change vraiment.

**Recensement de clôture, refait sur disque :** 28 fichiers sous un répertoire `ports_externes`,
répartis **A 4, C 3, D 4, E 6, F 3, H 8** ; B, G et Q n'en ont aucun. **Les 28 portent bien l'en-tête
`// TC-STUB-PORT:` en première ligne** — vérifié un par un, pas par sondage. Les 9 doubles de contrat
de Q sont toujours 9, sous l'en-tête distinct `// TC-DOUBLE-CONTRAT:`.

#### 4.5 bis — Neuf enums de stub appauvris, sur trois lots

Contrôle ajouté à la clôture, parce que la première émission ne le faisait que pour D et qu'un
défaut n'est un défaut que s'il est cherché partout. Chaque enum déclaré dans un stub a été comparé
au canonique du même nom chez son producteur :

| Lot | Stub | Enum appauvri | Canonique |
|---|---|---|---|
| A | `intention_pedagogique.dart` | `IntentionPedagogique` | D — `lib/core/tc_outils/intention_pedagogique.dart` |
| A | `port_catalogue.dart` | `TypeRessource`, `CapaciteRessource`, `PolitiqueAcces`, `PolitiqueOffline` | B — `lib/core/tc_bibliotheque/library_resource.dart` |
| C | `marqueur_semantique.dart` | `IntentionPedagogique` | D — `lib/core/tc_outils/intention_pedagogique.dart` |
| C | `port_etat_partage.dart` | `ModeAffichagePartage` | F — `lib/core/tc_etat_partage/shared_content_state.dart` |
| D | `library_resource.dart` | `CapaciteRessource` | B — `lib/core/tc_bibliotheque/library_resource.dart` |
| D | `port_realtime_pedagogique.dart` | `ModeAffichagePartage` | F — `lib/core/tc_etat_partage/shared_content_state.dart` |

**Neuf cas, sur 27 enums de stub comparables.** Dans les neuf, les **constantes sont identiques** —
mêmes valeurs, même ordre. Ce qui manque est uniformément le même triplet : le constructeur
`const <Enum>(this.valeurSql)`, le champ `final String valeurSql`, et la fabrique
`static <Enum>? depuisSql(String?)`.

**Ce sont des sous-ensembles, donc ce ne sont pas des BLOCKERS de branche**, et il faut le dire
franchement : la première émission bloquait A pour cette classe d'écart tout en laissant passer C et
D qui la portaient à l'identique. C'était une incohérence de traitement, pas une mesure. La règle
appliquée à la clôture est uniforme — un stub sous-ensemble se résout mécaniquement à la
substitution du canonique — **à une condition**, qui est la condition 3 du § 9.2 : la substitution
doit être atomique par type.

**Le risque n'est pas théorique, et il a déjà mordu une fois.** Un enum appauvri se contente de
`.name` là où le canonique attend `.valeurSql`. C'est exactement le défaut actif d'Agent D
(§ 8) : `d\lib\core\tc_outils\evenements_outils.dart:308` écrit
`'type_ancrage': position.typeAncrage.name`, quand F, l'autre bout du même canal, écrit et relit
cette clé par `.valeurSql` (`f\lib\core\tc_etat_partage\codec_etat_partage.dart:31` et `:46`).
Vérifié à la clôture, toujours présent. Les deux encodages coïncident aujourd'hui **par
coïncidence** — les quatre valeurs de `TypeAncrage` ont une `valeurSql` égale à leur nom Dart. Le
jour où l'une s'en écarte, les annotations du Teaching Dock cessent **silencieusement** d'être
décodées. C'est la raison pour laquelle les neuf enums appauvris sont une condition d'intégration
nommée et non une remarque de style.

---

## 5. Migrations, `pubspec`, fichiers protégés

### 5.1 Aucune migration non autorisée

**Aucune des neuf branches n'ajoute ni ne modifie un fichier sous `supabase/`**
(`git diff --name-only 0071557 HEAD -- supabase/` → vide sur les neuf). L'interdiction D-12 de
migration en phase parallèle est tenue sans exception. La dernière migration du dépôt reste
`0029_fermeture_dossiers_en_attente_anon.sql` ; le numéro `0030` est libre pour Agent Z.

### 5.2 Aucun `pubspec` modifié

**Ni `pubspec.yaml` ni `pubspec.lock` ne sont touchés par aucune branche.** Le gel §16.4 est tenu :
aucune dépendance nouvelle n'est entrée par la porte de service. Les demandes de dépendance existent
— une ferme (`pdfrx`, B), une conditionnelle (`timezone`+`intl`, A), une latente que son demandeur
refuse lui-même (`shared_preferences`, D) — mais elles sont restées des demandes, et Agent Z est le
seul à pouvoir les satisfaire.

### 5.3 Aucun fichier PROTECTED touché

Mesuré chemin par chemin sur les neuf branches : `lib/core/router/`, `theme/`, `auth/`, `video/`,
`i18n/`, `widgets/`, `icons/`, `assets/i18n/`, `lib/main.dart`, `lib/app.dart`,
`analysis_options.yaml`, `slang.yaml` → **rien** sur les neuf.

Quatre agents (B, C, F, G) **demandent** des modifications sur des fichiers PROTECTED ; aucun ne se
les est autorisées. F qualifie les siennes de bloquantes : « sans elle, rien n'est émis en
production ». C'est la bonne discipline, et elle a un coût — voir le § 8.

**Bruit de génération.** `flutter analyze` et `flutter pub get` réécrivent
`windows/flutter/generated_plugin_registrant.cc`, `generated_plugin_registrant.h` et
`generated_plugins.cmake`. Vérifié : `git diff 0071557 HEAD -- windows/` rend **rien** sur les neuf
branches — ces fichiers ne sont dans aucun commit d'agent. Ils ont été régénérés par les mesures de
ce rapport puis restaurés ; les neuf arbres de travail sont propres.

---

## 6. Aucune réimplémentation du socle

C'était le risque le plus sérieux d'un chantier à neuf agents parallèles : que deux d'entre eux
réécrivent la même fondation. Recherche menée sur les 321 fichiers ajoutés, motifs
`Room(`, `RoomOptions`, `.disconnect(`, `Connectivity(`, `signInWith`, `supabase.auth`,
`createClient(`, `class ServiceCoran` :

```
a : 0   b : 0   c : 0   d : 0   e : 0   f : 0   g : 0   h : 0   q : 0
```

**Zéro occurrence sur les neuf branches.**

- **LiveKit** — aucune `Room` n'est construite, aucun `.disconnect(` n'est appelé, aucune seconde
  `Connectivity` n'est instanciée. E et F, les deux lots qui touchent au temps réel, **consomment**
  le provider de la baseline (`import '../video/livekit_session_provider.dart'`) au lieu de le
  refaire. Les autres occurrences du mot « LiveKit » dans les 321 fichiers sont des commentaires de
  conception et des noms de test — B va jusqu'à écrire un test qui **vérifie** que sa surface
  n'importe pas `livekit_client`.
- **Auth** — aucun `signInWith`, aucun `supabase.auth`, aucun `createClient(`. Aucune branche ne
  touche `lib/core/auth/`.
- **Bibliothèque** — un seul `lib/core/tc_bibliotheque`, celui de B. Les cinq autres lots qui
  manipulent des ressources passent par des stubs de ses types, jamais par une seconde
  implémentation.
- **Coran** — aucune seconde `class ServiceCoran`. C consomme le service protégé de la baseline et
  demande deux méthodes supplémentaires par sa demande de contrat, en assumant un double local
  temporaire (`DebutsDeJuz.table`) qu'il documente comme destiné à disparaître.

Contrôles CI complémentaires, tous verts sur les 321 fichiers : aucun `IconData`, aucun `Icons.`
direct, aucun `Color(0x` littéral. Les icônes passent toutes par le catalogue partagé `AppIcons.*`
en consommation, et les vingt manquantes sont signalées par des commentaires `// TC-ICONE:` plutôt
que codées en dur.

---

## 7. Les audits se contredisent sur trois points — mesure et arbitrage

C'est le § le plus important pour Agent Z, parce que deux de ces contradictions auraient produit du
SQL faux.

### 7.1 Les migrations `0020` à `0024` **sont appliquées**

- L'audit de consolidation affirme qu'elles ne le sont pas, et en fait un BLOCKER dont dépendent
  trois demandes (A §1.7, B §1.1, E §1.1). Sa source est l'en-tête de `0025_role_enseignant.sql`
  (« N'ONT JAMAIS ÉTÉ APPLIQUÉES à cette base »).
- **Mesure en base** (projet `gggmtelinlpseweouyav`) : `list_migrations` rend
  `20260919232916 0020_programme_pedagogique`, `20260920033433 diagnostics_placement`,
  `20260920033522 progression_suivi`, `20260920033612 evaluations`,
  `20260920033657 qualite_pedagogique`. Et `to_regclass('public.programme_niveaux')` rend
  `programme_niveaux`.

**Tranché : elles sont appliquées.** L'audit a lu un en-tête de fichier, pas la base. Conséquence
pratique : A §1.7 s'écrit avec une clé étrangère **dure**, sans garde `to_regclass` et sans repli, et
E §1.1 peut joindre directement le domaine Pédagogie. L'en-tête de `0025` est désormais faux et doit
être corrigé, sans quoi il induira le prochain lecteur en erreur exactement comme il a induit cet
audit.

### 7.2 La migration `0029` **est appliquée** — la fuite de PII est close

- L'audit de consolidation la classe en défaut préexistant grave : `dossiers_en_attente()` livrerait
  nom et prénom de toute personne en attente de KYC à un appelant **anonyme**. Cinq agents la
  relaient, et l'un d'eux écrit qu'elle « mérite d'être la première chose qu'Agent Z regarde ».
- **Mesure en base** : `list_migrations` rend `20260920025402 fermeture_dossiers_en_attente_anon`, et
  `information_schema.routine_privileges` sur `dossiers_en_attente` rend
  `agent_ro, authenticated, postgres, service_role`. **`anon` est absent.**

**Tranché : c'est clos.** Agent Z n'écrit aucun correctif et publie un addendum d'une ligne au
`BASELINE_ADDENDUM.md`. Le **second** défaut du même addendum — `catalogue_galerie_test` rouge —
reste ouvert, lui.

### 7.3 `household_members` n'existe pas — et l'ancien plan d'intégration se trompait

Contradiction entre l'audit de consolidation et la version précédente de
`TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md`, qui affirmait que `household_members` était la
primitive réelle et qu'il fallait recopier son prédicat depuis `mes_seances_v`.

- **Mesure** : `household_members` apparaît **zéro fois** dans les 29 migrations, et
  `to_regclass('public.household_members')` rend `null`. La fonction `est_du_foyer` n'existe pas non
  plus (zéro occurrence, `pg_proc` → 0).
- La forme réelle est `public.profiles.household_id` (`0001:75`), et le prédicat canonique déjà
  dupliqué cinq fois dans le dépôt est
  `p.household_id = public.app_household_id() and p.deleted_at is null`
  (`0001:686`, `:729`, `:741`, `:785`, `:1030`).

**Tranché : l'audit de consolidation a raison, l'ancien plan avait tort.** Agent A écrivait contre une
table inexistante et Agent H contre une fonction inexistante, **pour le même besoin**. Les deux vues
(`mes_groupes_famille_v` et `concern_famille_v`) sont non exécutables telles qu'écrites. Un seul
helper `public.est_du_foyer(uuid)` bâti sur `profiles.household_id` ferme les deux, et doit être
écrit **une seule fois** : deux prédicats de foyer qui divergeraient feraient voir à un tuteur un
groupe qu'un autre écran lui cacherait.

### 7.4 Deux écarts de comptage, sans enjeu

- Doubles de contrat de Q : un audit annonce dix, un autre neuf. **Comptage sur disque : 9.**
- Icônes d'Agent D : son texte annonce huit, son propre tableau en liste dix. **Retenir dix** —
  le tableau est l'inventaire, la phrase est un résumé périmé. Un intégrateur qui se fie au chiffre
  en livrerait deux de moins que le code n'en attend.
- Total d'objets SQL : un audit annonce « environ 45 après déduplication ». Ce chiffre ne se
  recompose pas à partir de son propre détail par palier. Le plan d'intégration retient le détail,
  appuyé requête par requête sur la base, soit **63**, et signale l'écart plutôt que de reprendre le
  chiffre rond.

---

## 8. CE QUI RESTE FAUX OU FRAGILE

Cette section existe parce que les neuf `analyze` propres et les 791 tests verts du § 2 donnent une
impression que les faits ne soutiennent pas.

**Le fait central : ce chantier a construit des interfaces qui tournent sur des doubles locaux,
parce que le socle de données n'existe pas.** Mesuré en base :
`to_regclass('public.library_resource')` → `null`, `to_regclass('public.learning_assignment')` →
`null`, aucune des sept clés `app_config` du chantier n'existe, `participant_role` ne porte toujours
que `teacher, student, guardian_observer, masked_controller`. **Aucune** des 14 tables demandées
n'existe. Les 791 tests prouvent que le code fait ce que ses auteurs ont décidé qu'il ferait face à
des faux ; ils ne prouvent pas qu'un élève verra son groupe.

**Le blocage racine, qui n'appartient à aucun lot : rien n'alimente `sessions.groupe_id`.**
`0025` ajoute bien la colonne, mais la seule insertion dans `public.sessions` de tout le dépôt
(`0005:996`) ne la renseigne pas, et aucune fonction SQL ni aucun code de `lib/` n'appelle de
matérialisation. Sans occurrences de séance rattachées à un groupe, **cinq lots sur neuf n'ont
aucune donnée à lire en production** : A (compte à rebours, bouton Rejoindre), E (séance en cours,
roster), F (état partagé, dont la FK vise `sessions`), G (visites d'observation), H (déclenchement du
feedback). C'est une demande d'Agent A ; c'est en réalité la condition d'existence du chantier.

### Lot par lot

| Lot | Ce qui reste faux ou fragile |
|---|---|
| **A** | Des trois écarts du § 2.3, le premier est corrigé et le deuxième à moitié (§ 2.5) ; restent `portCatalogueProvider` et le format de `tc_i18n_A.json`, tous deux portés au § 9.2. Par ailleurs `TC_CONTRACT_REQUEST_A.md` §7 (lignes 731-733 et 743) renvoie encore à « deux types qui ne compilent pas en l'état (§6) » alors que la §6 est close depuis la passe 2 — écart purement documentaire, signalé par A lui-même, sans effet sur le code ; la demande d'arbitrage sur `PortRosterEnseignant` qu'il porte reste, elle, légitimement ouverte. Au-delà : son analyse du plafond de participants est **fausse sur deux points** — le tuteur observateur est exempté depuis `0012:77-79`, et le plafond lui-même est inerte depuis que `0017:432` passe `allow_multi_participant_sessions` à `true`. La conclusion s'inverse : le fait à signaler n'est pas que l'observateur ferait déborder le plafond, c'est que **plus aucun garde-fou serveur ne borne le nombre de participants d'une séance**. Sa lecture de configuration emploie `get_config`, révoquée à `authenticated` (`0001:1221`), au lieu de `app_config_int`, le motif du dépôt. Enfin, il localise une occurrence de `interval '10 minutes'` dans `autoriser_jeton_video()` alors qu'elle est dans `etat_presence()` : un intégrateur qui suit son tableau patche la mauvaise fonction, et il existe une **quatrième** occurrence qu'aucun agent ne mentionne (`lib/core/video/pre_vol.dart:22`). |
| **B** | Le catalogue est la clé de voûte : quatre autres lots référencent sa table de ressource, et deux l'ont écrite **sans clé étrangère**. Son DDL n'est pas exécutable dans l'ordre où il est écrit — trois enums déclarés après leur usage, et une FK circulaire entre `library_resource` et `resource_version`. L'affichage d'un PDF n'existe pas sans `pdfrx`, dépendance non tranchée ; le repli est livré et honnête, mais c'est un repli. Sa `CacheMediaFichiers` tient ses clés dans un `Set` en mémoire : une ressource « Téléchargée » repasse à « À télécharger » au prochain lancement. |
| **C** | Le moteur tourne sur un identifiant de ressource **codé en dur** (`'quran:madina-hafs-604'`) en attendant que le Coran entre au catalogue de B : tant que cette ligne existe, les positions de C ne sont pas partageables avec les autres lots. La recherche dans le texte arabe est désactivée et l'écran le dit en toutes lettres ; `pg_trgm` est **absente du projet** (vérifié : `installed_version` nul). Le rendu du Mushaf restera explicitement `degrade` et jamais `fidele` tant que l'arbitrage sur les 83 668 mots QUL n'est pas rendu. Deux méthodes lui manquent sur un fichier PROTECTED. |
| **D** | **Un défaut de sérialisation actif** : `evenements_outils.dart:308` écrit `position.typeAncrage.name` sur la clé `type_ancrage`, quand F, l'autre bout du même canal, écrit et relit cette clé par `.valeurSql`/`depuisSql`. Les deux encodages coïncident aujourd'hui **par coïncidence** — les quatre valeurs de `TypeAncrage` ont une `valeurSql` égale à leur nom Dart. Le jour où l'une s'en écarte, les annotations du Teaching Dock cesseront **silencieusement** d'être décodées. C'est d'autant plus une étourderie que les six autres sérialisations du même fichier emploient correctement `.valeurSql`. Par ailleurs, ses stubs autres que `ContentPosition` portent encore des enums appauvris (`CapaciteRessource`, `ModeAffichagePartage`). |
| **E** | `rappel_discret.dart` **cadence une action qui n'émet rien** : le raccordement à `PortRealtimePedagogique.emettreCible` d'Agent F est au contrat et n'existe dans aucun code. Son stub `PortAnnonceObservation` déclare `abstract class` quand G publie `abstract interface class` : divergence latente aujourd'hui (aucun `extends`, aucun `implements` chez E), erreur de compilation à la première implémentation écrite contre la mauvaise forme. Sa demande de promotion de la galerie vidéo est bloquée par un test rouge préexistant, pas par une décision. La projection `excusee` se perd en `absent` faute d'une dixième valeur non tranchée. |
| **F** | Le protocole est écrit, testé, et **n'émet rien en production** : ses deux demandes portent sur des fichiers PROTECTED qu'il n'a pas le droit de toucher, et il le qualifie lui-même de bloquant. Il corrige au passage la cartographie officielle : un premier canal de données **existe déjà** depuis `0071557`, contrairement à ce qu'affirme `TEACHING_CORE_BASELINE.md` §6.7 — la demande n'est donc pas « ajoutez un canal » mais « généralisez celui qui existe ». Il relève aussi que `ContenuPresente` est ordonné par horodatage d'émission : un client dont l'horloge avance peut faire ignorer les paquets d'un autre. |
| **G** | Les trois RPC dont dépend l'observation n'existent pas, et l'enum `participant_role` ne porte pas les deux valeurs nécessaires — vérifié en base. Tant que `RoleSalle.depuis()` (fichier PROTECTED) n'est pas complété, l'administrateur tombe sur `RoleSalle.inconnu`, donc une salle en lecture seule. Son compte à rebours de budget **n'utilise pas** `SessionClockVM` d'Agent A alors que l'ownership le déclare consommé : à vérifier qu'il ne recalcule pas une durée localement, ce qui contredirait l'invariant « un compte à rebours Dart est un affichage, la borne est serveur ». Enfin, `assister_seance()` laisse aujourd'hui le tuteur entrer **sans budget et sans trace**. |
| **H** | **Défaut préexistant relevé à la clôture, hors du périmètre de la passe 3 et donc non corrigé par elle :** la branche d'erreur de `BlocAvantProchainCours` (`h\lib\features\tc_flux_academique\bloc_avant_prochain_cours.dart:86-96`) affiche `LibellesParcours.avantRienDetail` — le texte de l'état **vide** — quand la lecture échoue. C'est la confusion que l'arbitrage du § 2.5 vient d'interdire, transposée de « non branché » à « illisible » : une panne de lecture affirme à la famille un fait sur le travail à venir que personne n'a mesuré. Le libellé `avantNonBrancheDetail` créé par la passe 3 conviendrait mot pour mot. À traiter par Agent Z, ce n'est pas un motif de blocage. — Par ailleurs H a stubé `PortRosterEnseignant` et `TeacherStudentProjection` alors que l'AMENDEMENT 2 nomme précisément son cas et conseille de ne pas le faire. L'écart est sans danger — la copie est rigoureusement fidèle au canonique d'E, vérifiée champ par champ — et H le justifie par écrit. Mais l'ordre d'intégration place H **avant** E, donc H sera intégré avec ses stubs en place et la substitution n'aura lieu que plus tard ; ses tests devront être rejoués **à ce moment-là**, pas avant. Deux arbitrages de confidentialité qu'il refuse explicitement de trancher seul restent ouverts. |
| **Q** | Ses 104 tests compilent aujourd'hui contre **ses propres doubles**, pas contre le code des autres lots : ce sont des tests de conformité de contrat, pas encore des tests de régression. Q l'écrit lui-même — ils ne le deviendront qu'une fois les neuf imports rebasculés sur les chemins canoniques. Quatre de ses tests sont « dormants » et il demande qu'on vérifie qu'ils **mordent** après bascule, sinon ses chemins canoniques pointent à côté. Son fichier i18n est vide et à supprimer. |

### Fragilités transverses

1. **Les 28 stubs ne sont pas supprimables un par un. CONSIGNE FERME POUR AGENT Z : la suppression
   est ATOMIQUE PAR TYPE, jamais par fichier, et tout fichier canonique important un stub est
   réécrit dans le MÊME commit.** Ce point a été revérifié à la clôture et il tient.

   **Le recensement, remesuré :** **129 lignes d'import** hors `ports_externes` pointent sur un stub
   — A 4, C 12, D 37, E 15, F 12, H 49 — dont **59 dans `test/`** et 70 dans `lib/`. (La première
   émission comptait 121 dont 51 en test ; l'écart de 8 est l'effet des passes 2 et 3, qui ont ajouté
   des imports chez A et chez H en même temps que leurs nouveaux tests. Les deux chiffres sont justes
   à leur date.)

   **Pourquoi la suppression ne peut pas être incrémentale.** En Dart, **deux types homonymes
   déclarés dans deux fichiers sont deux types DISTINCTS**, même à déclaration rigoureusement
   identique. Il n'existe aucun mécanisme d'unification structurelle : `SlotAction` importé de
   `tc_groupe/group_home_vm.dart` et `SlotAction` importé de
   `tc_parcours/ports_externes/slot_action.dart` ne sont pas le même type pour le compilateur.
   Supprimer un stub sans réécrire dans le même commit **tous** ses importeurs ne compile pas ; le
   garder tout en ajoutant le canonique fait coexister deux types qui ne s'affectent pas l'un à
   l'autre.

   **Le piège, vérifié à la clôture : cinq fichiers CANONIQUES — que Z doit conserver — importent
   eux-mêmes des stubs.** Ce ne sont pas des fichiers jetables :

   | Fichier canonique à conserver | Stubs qu'il importe |
   |---|---|
   | `d\lib\core\tc_outils\learning_assignment.dart` | 1 — `content_range.dart` |
   | `f\lib\core\tc_etat_partage\shared_content_state.dart` | 3 — `content_position`, `content_range`, `marqueur_semantique` |
   | `e\lib\core\tc_classe\teacher_student_projection.dart` | 2 — `content_position`, `learning_assignment` |
   | `h\lib\core\tc_parcours\port_travail_a_venir.dart` | 4 — `content_position`, `learning_assignment`, `port_assignations`, `slot_action` |
   | `h\lib\core\tc_parcours\port_post_cours.dart` | 7 — `content_position`, `content_range`, `intention_pedagogique`, `learning_assignment`, `port_assignations`, `port_roster_enseignant`, `teacher_student_projection` |

   **Le cas le plus instructif est celui que la passe 3 vient d'arbitrer.** `port_travail_a_venir.dart`
   chez H est le fichier **canonique** qui porte `portTravailAVenirProvider`, et il importe le stub
   `slot_action.dart` — alors que `SlotAction` est canonique chez **A**, dans
   `lib\core\tc_groupe\group_home_vm.dart`. Le provider a pour type
   `Provider<PortTravailAVenir?>`, et `PortTravailAVenir.avantProchainCours` rend
   `Future<List<SlotAction>>`. Si Agent Z supprime le stub `slot_action.dart` de H sans réécrire
   `port_travail_a_venir.dart` dans le même commit, cela ne compile pas. S'il laisse les deux, le
   `SlotAction` d'A et celui de H sont deux types distincts, et **l'arbitrage qui vient d'être rendu
   cesse de tenir au point exact où il comptait** : A ne peut plus lire le provider de H. La règle
   d'atomicité n'est pas une précaution de forme ; c'est ce qui préserve le § 2.5.

2. **Deux en-têtes `// TC-STUB-PORT:` désignent un fichier canonique qui ne déclare pas le type
   stubé.** Le contrôle automatique d'existence du chemin passe au vert ; celui de la déclaration
   échouerait. Agent Z qui suivrait ces en-têtes à la lettre écrirait un import qui ne résout rien.
   **Les deux ont été identifiés nommément à la clôture, avec leur correction :**

   | Stub | En-tête actuel (faux) | Chemin réel du type |
   |---|---|---|
   | `a\lib\core\tc_groupe\ports_externes\intention_pedagogique.dart` | `lib/core/tc_outils/annotation_layer.dart` | `lib/core/tc_outils/intention_pedagogique.dart` (D) |
   | `c\lib\core\tc_coran\ports_externes\port_etat_partage.dart` | `lib/core/tc_etat_partage/shared_content_state.dart` | `lib/core/tc_etat_partage/port_etat_partage.dart` (F) |

   Les 26 autres en-têtes ont été vérifiés de la même façon — chemin canonique existant **et**
   déclarant bien le type principal du stub — et sont exacts.
3. **Les façades de libellés sont à huit emplacements et sous deux conventions de nom.** B et C
   placent la leur sous `lib/features/` au lieu de `lib/core/`, et le suffixe hésite entre le nom de
   domaine et la lettre d'agent. Un glob sur `lib/core/tc_*/libelles_tc_*.dart` **raterait B et C**.
   Le marqueur `// TC-I18N:` est fiable partout ; le chemin ne l'est pas.
4. **Onze défauts préexistants du dépôt** ont été découverts en chemin, dont `tool/verifier_jetons.dart`
   rouge sur la baseline avec 10 violations (rapporté indépendamment et à l'identique par sept
   agents), `catalogue_galerie_test` rouge (`flutter test` sur tout le dépôt : `+931 -1`), une policy
   qui laisse un enseignant déposer un cahier sur la séance d'un autre, et deux polices arabes
   redistribuées **sans notice de licence**. Ils sont hors mission et ne doivent pas se perdre ; ils
   sont consignés au § 10 du plan d'intégration.

---

## 9. Verdict — deux familles à ne pas confondre

La première émission de ce rapport mélangeait deux choses de nature différente sous le même mot
« bloquant », et c'est ce qui rendait son verdict illisible. Elles sont séparées ici, et la
distinction est le point le plus important du document.

> **(a) Un BLOCKER DE BRANCHE** est un défaut **imputable à un agent** : il a enfreint l'ownership,
> son stub diverge du canonique, ou sa suite de tests est rouge. Ce sont les seuls qui empêchent de
> déclarer les branches conformes, et ce sont les seuls que la règle de la spécification vise.
>
> **(b) Une CONDITION D'INTÉGRATION** est ce qui manque **hors des branches** et qu'aucun agent
> n'avait le droit de produire : les migrations SQL, les arbitrages produit, les fichiers PROTECTED.
> Ce sont des tâches pour Agent Z, **pas des défauts des lots**.

### 9.1 (a) BLOCKERS DE BRANCHE — zéro

| Contrôle | Mesure de clôture | Verdict |
|---|---|---|
| Ownership respecté sur les neuf lots | 321 chemins, **321 distincts, 0 intersection** ; chaque chemin confronté un par un aux préfixes de `FILE_OWNERSHIP` §5.1 : **0 débordement**, hors l'exception de Q déjà déclarée et tranchée (§ 2.2) | **conforme** |
| Tous les chemins en ajout pur | `git diff --name-status 0071557 HEAD` sur les neuf : **que des statuts `A`** (36, 36, 32, 37, 39, 32, 31, 39, 39), zéro `M`, zéro `D`. Aucun fichier préexistant du dépôt n'est touché | **conforme** |
| Aucun stub divergent au sens de la règle | `ContentPosition` d'A **corrigé** (§ 2.5) ; C et D corrigés (§ 2.4) ; les 9 enums appauvris restants sont des **sous-ensembles** traités uniformément en condition 3 (§ 4.5 bis) | **conforme** |
| Les deux providers arbitrés coïncident | `portTravailAVenirProvider` identique au caractère près chez A et H, zéro levée, règle sémantique écrite et **honorée par le consommateur** | **conforme** |
| Neuf suites de tests vertes | **791 tests, 0 échec.** A 109, B 95, C 94, D 85, E 93, F 61, G 75, H 75, Q 104. A et H remesurés à la clôture | **conforme** |
| Neuf `flutter analyze` propres | `No issues found!` sur les neuf ; A et H remesurés à la clôture | **conforme** |
| Aucune migration, aucun `pubspec`, aucun fichier PROTECTED touché | zéro chemin sur les neuf | **conforme** |
| Neuf arbres de travail propres | `git status --porcelain` vide sur les neuf. Le bruit `windows/flutter/generated_*` régénéré par les mesures de ce rapport a été restauré (`git checkout -- windows/flutter/`) dans `a`, `c`, `d`, `h` | **conforme** |

**BLOCKERS DE BRANCHE : 0.** Les neuf branches sont conformes. La règle de la spécification
(« aucune intégration tant qu'un seul lot est BLOCKED », « le rapport ne contient aucun BLOCKED »)
est **satisfaite**.

| | |
|---|---|
| Lots BLOCKED | **0** |
| Lots READY WITH CONTRACT CHANGE | **9** — A, B, C, D, E, F, G, H, Q |
| Lots READY sec | **0** |

### 9.2 (b) CONDITIONS D'INTÉGRATION — onze, dont quatre dures

Aucune de ces onze conditions n'est un défaut d'un lot. Aucune ne peut être levée par un agent A…H
ou Q : toutes tombent dans le périmètre exclusif d'Agent Z (`FILE_OWNERSHIP` §2, Agent Z) ou
demandent une décision humaine.

**Les quatre conditions dures — sans elles, l'intégration produit une application qui compile et
n'affiche rien de réel :**

| # | Condition | Nature | Référence |
|---|---|---|---|
| **1** | **Les migrations SQL consolidées n'existent pas.** 63 objets SQL distincts sont demandés par les neuf lots ; **aucune** des 14 tables n'existe en base, aucune des 7 clés `app_config` n'existe, `participant_role` ne porte pas les deux valeurs nécessaires. `0030` est libre. | Agent Z, phase SQL | § 3, § 8 |
| **2** | **Rien n'alimente `sessions.groupe_id`.** `0025` ajoute la colonne ; la seule insertion dans `public.sessions` de tout le dépôt (`0005:996`) ne la renseigne pas, et aucune fonction SQL ni aucun code de `lib/` n'appelle de matérialisation. **Sans cela, cinq lots sur neuf n'ont aucune donnée à lire** : A, E, F, G, H. | Agent Z, phase SQL | § 8 |
| **3** | **La suppression des 28 stubs doit être atomique par type.** 129 imports hors `ports_externes` pointent dessus, dont 59 en `test/`, et **cinq fichiers canoniques à conserver importent eux-mêmes des stubs**. Deux types homonymes sont distincts en Dart : toute suppression partielle casse la compilation, et laisser coexister stub et canonique **défait l'arbitrage du § 2.5**. | Agent Z, phase bascule | § 8 fragilité 1 |
| **4** | **`tc_i18n_A.json` n'a pas la racine `tc`.** Une boucle de fusion uniforme sur les neuf fichiers sauterait A et perdrait **silencieusement** tous les libellés de l'Espace Groupe et les deux seules valeurs arabes du chantier. Vérification qui l'attrape : après fusion, compter les clés et **échouer** si le total est inférieur à la somme des neuf fichiers. | Agent Z, phase i18n | § 2.3 (c) |

**Les sept conditions restantes :**

| # | Condition | Référence |
|---|---|---|
| 5 | **Arbitrer `portCatalogueProvider`** entre la forme nullable d'A et la forme branchée de B. Le § 2.5 donne le patron à suivre. | § 4.3 |
| 6 | **Corriger deux en-têtes `// TC-STUB-PORT:`** qui désignent un canonique ne déclarant pas le type stubé (les deux sont nommés, avec leur chemin réel). | § 8 fragilité 2 |
| 7 | **Substituer les 9 enums appauvris** (A 5, C 2, D 2) et, dans le même passage, corriger `d\...\evenements_outils.dart:308` qui écrit `.name` là où F lit `.valeurSql`. | § 4.5 bis |
| 8 | **Renommer les deux hôtes** en collision de nom de classe — `BlocAvantProchainCours` et `SurfaceBibliotheque` — jamais les implémentations. | § 4.4 |
| 9 | **Trancher `pdfrx`** (seule dépendance ferme), livrer les 20 icônes `// TC-ICONE:` et le lot de jetons de couleur. | § 3, § 5.2 |
| 10 | **Rendre les 6 arbitrages qui exigent une décision humaine**, dont les deux arbitrages de confidentialité qu'H refuse explicitement de trancher seul et la fidélité Mushaf de C. | § 3, § 8 |
| 11 | **Obtenir le `TARGET_SHA` du chantier Admin.** `integration/teaching-core` part de ce `TARGET_SHA`, **jamais** de la baseline `0071557`. Condition indépendante de ce chantier. | — |

**Deux points sont désormais acquis et ne sont plus des conditions**, contrairement à ce que laissait
croire la première émission : les migrations **`0020` à `0024` sont appliquées** (§ 7.1, mesuré en
base) et **`0029` est appliquée**, donc la fuite de PII vers `anon` est close (§ 7.2). L'en-tête de
`0025` qui affirme le contraire est faux et doit être corrigé, sans quoi il induira le prochain
lecteur en erreur exactement comme il a induit un audit.

Restent aussi les **onze défauts préexistants du dépôt** relevés en chemin (§ 8, fragilité 4). Ils
sont hors mission, ne conditionnent pas l'intégration, et sont consignés au § 10 du plan
d'intégration pour ne pas se perdre.

### 9.3 Verdict global

**INTÉGRATION NON AUTORISÉE — et la raison a changé.**

Elle n'est plus retenue par un lot défaillant. Les neuf branches sont conformes : ownership respecté,
791 tests verts, neuf analyses propres, plus aucun stub divergent, les deux providers arbitrés
coïncidant. **(a) est vide.**

Elle est retenue par **(b)**, et singulièrement par ses quatre conditions dures, dont aucune
n'appartient à une branche. La PHASE 1 du PROMPT IMMUABLE Z **peut commencer** — c'est précisément
son objet que de lever ces conditions — mais la fusion elle-même ne peut aboutir à un produit
utilisable tant que les conditions 1 et 2 ne sont pas levées.

Formulé exactement : **les branches sont conformes, l'intégration reste conditionnée au socle de
données.**

### 9.4 Ce qui a été construit, sans emballage

Ce chantier a produit neuf lots d'interface et de domaine **qui tournent sur des doubles locaux,
parce que le socle de données nécessaire n'existe pas en base.** C'est un résultat honorable et
conforme au protocole : les migrations étaient **interdites** en phase parallèle, et les neuf agents
ont tenu l'interdiction sans exception — zéro fichier sous `supabase/`, zéro `pubspec` modifié, zéro
fichier PROTECTED touché, sur 321 chemins. Quand il leur a manqué une capacité serveur, ils ont écrit
une demande de contrat au lieu de la fabriquer eux-mêmes. C'est la bonne discipline, et elle est
rare.

**Mais ce n'est pas un produit fini, et ce rapport ne doit pas laisser croire le contraire.** Les 791
tests verts prouvent que le code fait ce que ses auteurs ont décidé qu'il ferait **face à des faux
qu'ils ont écrits eux-mêmes**. Ils ne prouvent pas qu'un élève verra son groupe. Aucun écran n'a été
ouvert, aucun parcours utilisateur n'a été joué, aucune requête d'écriture n'a été émise en base.
Aucun lot n'est READY sec, et les neuf sont READY **WITH CONTRACT CHANGE** — ce qui ne veut pas dire
« presque fini » mais « compile, testé, dans son périmètre, **et ne lit aucune donnée réelle** ».

Le chemin qui reste n'est pas une finition : c'est la construction du socle de données que la phase
parallèle avait interdiction de toucher, plus les arbitrages produit que personne n'avait mandat de
rendre seul.
