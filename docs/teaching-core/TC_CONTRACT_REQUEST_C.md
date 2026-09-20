# TC_CONTRACT_REQUEST_C — Quran Engine

> Agent C, Teaching Core. Baseline `0071557`.
> Ce document est écrit pour qu'un décideur tranche en le lisant, sans rouvrir le code.
>
> **Résumé en une phrase** : le moteur livre trois rendus sur la source canonique, mais la
> **composition interne d'une page du Mushaf de Médine n'est pas reproductible** avec les données
> présentes en base, et aucune improvisation n'a été faite pour le masquer (clause STOP, spec §7.2,
> décision D-23).

---

## 0. Ce qui est demandé, en une page

| # | Demande | Type | Bloquant pour | Décision attendue |
|---|---|---|---|---|
| **1** | Peupler `verset.ligne` **et** créer la table `mot` | DEMANDE SQL | fidélité de page | produit + budget données |
| **2** | Jeu de polices QCF page par page | DÉPENDANCE / ASSETS | rendu au glyphe près | produit + juridique + budget bundle |
| **3** | Asset de layout complémentaire (cadre, lignes par page, lignes centrées) | ASSETS | cadre exact des pages 1 et 2 | technique, peu coûteux |
| **4** | Deux méthodes sur `ServiceCoran` **[PROTECTED]** : `rechercher`, `debutDeJuz` | AMENDEMENT DE CONTRAT | recherche texte, navigation juz sans double local | technique |
| **5** | Index de recherche texte sur `verset` | DEMANDE SQL | recherche dans le Coran | technique |
| **6** | Identifiant `LibraryResource` du Coran | AMENDEMENT DE CONTRAT (Agent B) | position partageable | technique |
| **7** | Route + entrée de navigation | ARBITRAGE PRODUIT | accessibilité de l'écran | produit |
| **8** | Notice de licence absente pour deux polices embarquées | **RISQUE JURIDIQUE** | distribution | juridique |

Aucune demande d'icône : le moteur n'emploie que des icônes déjà au catalogue (`coran`, `recherche`,
`chevron`, `horsLigne`, `rienAAfficher`), et remplace les commandes de zoom par des **libellés**, comme
le fait déjà `coran_page.dart` — le catalogue n'a ni « plus » ni « moins », et inventer un point de code
Phosphor au juge poserait un carré vide au milieu d'un écran de lecture.

---

## 1. DEMANDE SQL — le découpage en lignes, chiffré

### 1.1 Le constat, mesuré sur le dépôt

| Fait | Source dans le dépôt |
|---|---|
| `verset.ligne` existe, `nullable`, et **vaut `NULL` sur les 6236 versets** | `supabase/migrations/0007_...sql` ligne 76 ; les `insert` de `0013_corpus_coranique.sql` ne listent que `(mushaf_id, sourate_numero, numero, texte, page_numero)` |
| L'index l'attendait déjà | `create index verset_page_idx on public.verset (mushaf_id, page_numero, ligne)` — `0007` |
| Le refus est délibéré et motivé | En-tête de `0013` : « le layout QPC v2 compte **83 668** mots contre **77 881** pour Tanzil. Mesuré, pas supposé. Faire coïncider les deux demanderait de deviner une correspondance sur un texte sacré » |
| Aucune granularité sub-verset | La table `mot` **n'existe pas**. `verset.page_numero` désigne la page où le verset **commence** : un verset à cheval sur deux pages est attribué entièrement à la première |
| Rien n'en dépend aujourd'hui | `0013` : « Rien dans l'application ne dépend de `ligne` » — c'est toujours vrai après ce lot |

### 1.2 Pourquoi `verset.ligne` seul ne suffit pas

C'est le point à ne pas rater, parce qu'il change le coût de la demande.

Une page du Mushaf de Médine porte 15 lignes et environ 8 à 12 versets. **La plupart des versets
occupent plusieurs lignes, et la plupart des lignes portent des morceaux de deux versets.**
`verset.ligne` ne peut donc porter qu'une seule information : la ligne où le verset **commence**.

Avec elle seule, le moteur saurait regrouper les versets par ligne de départ. Il ne saurait toujours
pas **où couper le texte d'un verset** entre deux lignes. Le rendu resterait approximé — mieux, mais
approximé, et `DisponibiliteLayout` vaudrait `degrade`, jamais `fidele`.

**La fidélité réelle exige la granularité du mot.**

### 1.3 Source, format, volume

**Source retenue** : *Quranic Universal Library* (QUL), jeu « Madani Mushaf layout / QPC v2 ». C'est la
source que `0013` nomme elle-même en expliquant son refus, donc le dossier est déjà ouvert.

Elle publie deux choses complémentaires :

| Jeu | Contenu | Volume |
|---|---|---|
| **Layout** | une ligne par ligne de page : `page_number` (1..604), `line_number` (1..15), `line_type` (`ayah` \| `surah_name` \| `basmallah`), `is_centered`, `first_word_id`, `last_word_id` | **9 060 lignes** (604 × 15), quelques centaines de Ko |
| **Mots** | un enregistrement par mot : sourate, verset, position dans le verset, texte, page | **≈ 83 668 lignes** (chiffre cité par `0013`), ordre de grandeur 2 à 4 Mo |

⚠ **Le point de vigilance est le même que celui de `0013`** : le texte des mots QUL n'est pas le texte
Tanzil (83 668 contre 77 881). La différence ne vient pas d'un désaccord sur le Coran mais d'une
**segmentation différente** (mots liés, particules attachées). Deux conduites possibles, et c'est une
décision, pas une évidence :

- **(a) Deux représentations, une seule source de vérité.** Tanzil reste la source canonique du
  **texte** (`verset.texte`, immuable, CC-BY 3.0, invariant J6 et décision D-09). QUL fournit
  uniquement la **géométrie** : quels mots sur quelle ligne. Le rendu compose alors les mots QUL, et la
  cohérence des deux représentations doit être **prouvée verset par verset** par un contrôle de
  migration, sur le modèle du bloc `do $$` final de `0013` (qui échoue si le corpus ne fait pas
  114 / 30 / 604 / 6236).
- **(b) Ne pas importer les mots, se contenter de `verset.ligne`.** Moins cher, et honnête si le
  produit accepte un rendu **explicitement dégradé**. Le moteur est déjà prêt pour ce cas :
  `DisponibiliteLayout.degrade` existe et le renderer sait l'afficher.

### 1.4 Migration attendue

Numéro : **`0030`** ou suivant. Aucun agent Teaching Core ne la crée (décision D-12) ; elle revient à
Agent Z.

```sql
-- Option (b), minimale : peupler la colonne qui existe deja.
-- Aucune table nouvelle, aucun changement de schema, aucune policy a revoir.
update public.verset v
   set ligne = q.ligne_de_depart
  from import_qpc_v2_verset q
 where v.mushaf_id = (select id from public.mushaf where code = 'madina-hafs-604')
   and v.sourate_numero = q.sourate
   and v.numero = q.verset;

-- Controle obligatoire, sur le modele du bloc final de 0013 :
--   1. aucune ligne nulle sur les 6236 versets ;
--   2. ligne between 1 and 15 pour toute page sauf 1 et 2 ;
--   3. pour chaque page, les lignes de depart sont croissantes dans l'ordre des versets ;
--   4. aucune page ne declare plus de lignes que l'edition n'en porte.
-- Si l'un des quatre echoue, la migration doit ECHOUER, pas avertir.
```

```sql
-- Option (a), complete : la granularite du mot.
create table public.mot (
  id              bigint generated always as identity primary key,
  mushaf_id       uuid not null references public.mushaf(id) on delete cascade,
  sourate_numero  int  not null references public.sourate(numero),
  verset_numero   int  not null check (verset_numero > 0),
  position        int  not null check (position > 0),   -- rang du mot dans le verset
  texte           text not null,
  page_numero     int  not null check (page_numero > 0),
  ligne           int  not null check (ligne > 0),
  constraint mot_unique unique (mushaf_id, sourate_numero, verset_numero, position),
  constraint mot_page_fk foreign key (mushaf_id, page_numero)
    references public.page_mushaf(mushaf_id, numero) on delete cascade
);

create index mot_page_ligne_idx on public.mot (mushaf_id, page_numero, ligne, position);

-- RLS : EXACTEMENT celle de public.verset (0007). Le corpus est en lecture pour
-- tout role authentifie, aucune ecriture depuis le client.
-- Role appelant : le meme que `verset`.
-- Table existante qu'elle etend : `public.verset`, dont elle est la granularite
-- inferieure. Elle ne la remplace pas et ne duplique pas `verset.texte`.
```

**Les deux règles de sécurité à répéter dans la migration**, comme D-12 l'impose :

1. **Jamais `grant execute` à `agent_ro` sur une RPC volatile ou d'écriture.** Si la migration ajoute
   une RPC de lecture du layout, elle doit être `stable` ou `immutable`, et le `grant` doit être écrit
   en le sachant : `get_advisors` ne détecte pas cette erreur.
2. Si une **vue d'exposition** est créée au-dessus de `mot`, elle **répète le filtre d'appelant et le
   masquage `agent_identite_masquee()` colonne par colonne**. Ici le risque est faible (le corpus ne
   porte aucune donnée personnelle) mais la règle ne souffre pas d'exception de circonstance.

### 1.5 Ce que le moteur fait le jour où la donnée arrive

**Rien à réécrire dans le renderer.** Le point d'extension est déjà posé et déjà testé :

- une implémentation de `PortLayoutMushaf` (`lib/core/tc_coran/port_layout_mushaf.dart`) remplace
  `LayoutLignesIndisponible` dans `portLayoutMushafProvider` — **un seul provider à surcharger** ;
- elle rend `DisponibiliteLayout.fidele` (ou `degrade`) et un `LayoutPage` porteur de `SectionLigne` ;
- `PageMushafVM` bascule automatiquement, et `LigneComposee` (`vue_page_mushaf.dart`) rend les lignes ;
- la notice « Composition approchée » disparaît d'elle-même.

Ce chemin **est couvert par des tests aujourd'hui** (`FauxLayoutFidele`,
`test/teaching_core/c/mushaf_ecran_test.dart` : « avec de vraies lignes, la notice change de discours »).

---

## 2. DÉPENDANCE / ASSETS — les polices QCF, et pourquoi je ne les recommande pas maintenant

### 2.1 Ce que c'est

Le jeu QCF (*Quran Complex Font*) du Complexe du Roi Fahd est **une police par page** : 604 fichiers,
dans lesquels chaque glyphe est un **mot entier de cette page précise**. C'est la seule façon connue
d'obtenir un rendu identique au glyphe près à l'édition imprimée.

### 2.2 Les trois coûts, dans l'ordre d'importance

**a) Ce n'est pas un coût de taille, c'est un coût d'architecture.** Une police QCF ne se compose pas
avec du texte Unicode : chaque mot est un **code de glyphe propre à la page**, adressé par
`word_id`. Employer QCF suppose donc de **stocker une seconde représentation du texte**, dépendante de
l'édition et illisible hors de sa police. Or la décision **D-09** et l'invariant **J6** disent
l'inverse : « la source de vérité reste structurée et immuable », « le Coran n'est pas un PDF paginé ».
Une seconde représentation n'annule pas la première, mais elle crée un couple à maintenir cohérent —
et c'est exactement le genre de couple qui diverge silencieusement.

**b) Le budget du bundle.** 604 fichiers de police, chargés page par page.
`docs/produit/bibliotheque-contenu.md` pose un **budget de 20 Mo**, et `pubspec.yaml` porte déjà un
commentaire normatif expliquant qu'une dépendance ajoutée à la légère peut casser le mode hors ligne.
L'ordre de grandeur du jeu complet se compte en **dizaines de Mo** : le chiffre exact est à obtenir de
la source avant toute décision, mais l'ordre de grandeur suffit déjà à dire que **cela ne passe pas
sans arbitrage explicite sur le budget**.

**c) Elles ne servent à rien sans la demande n°1.** Une police QCF rend les glyphes d'une page ; elle ne
dit pas quels mots vont sur quelle ligne. Sans le layout de la demande n°1, elle n'apporte **aucune**
fidélité supplémentaire.

### 2.3 Recommandation

**Faire la demande n°1, ne pas faire la n°2 maintenant.** Le layout QPC v2 avec
`UthmanTahaNaskh-Regular.otf` — déjà embarquée, déjà déclarée dans `pubspec.yaml`, 164 684 octets —
donne une page **reconnaissable** : mêmes limites de page, mêmes lignes, mêmes repères. Le rendu au
glyphe près est un cran au-dessus, et c'est un projet en soi.

Si l'opérateur veut tout de même QCF, alors : **d'abord la n°1**, puis QCF comme **couche de rendu**
adressée par `mot.id`, Tanzil restant canonique — et un arbitrage écrit sur le budget de bundle.

---

## 3. ASSETS — le complément de layout

Petite demande, peu coûteuse, à joindre à la n°1.

| Donnée | Pourquoi | Où |
|---|---|---|
| Nombre de lignes **par page** | Les pages 1 et 2 de l'édition n'en portent pas 15. `GeometrieMushaf.lignesParPage` vaut 15 pour toutes, faute de mieux | `LayoutPage.nombreLignes` (déjà dans le port) |
| Proportion du cadre de texte | `GeometrieMushaf.ratioCadreTexte` vaut 2/3, **constante déclarée, pas mesurée** : c'est le seul nombre de présentation du moteur | `LayoutPage.ratioLargeurSurHauteur` (déjà dans le port) |
| Lignes centrées, titres de sourate, basmala | Une ligne de titre ne se justifie pas | `SectionLigne.centree` (déjà dans le port) |

Ces trois champs **existent déjà dans le contrat** : il n'y a rien à amender, seulement à remplir.

### 3 bis. Le côté de page, à confirmer une fois

`GeometrieMushaf.coteDe` pose : **page impaire à droite, page paire à gauche**, ouvertures (1,2), (3,4),
… Ce choix vient de la reliure à droite et du fait qu'Al-Fatiha (page 1) et l'ouverture d'Al-Baqara
(page 2) se font face dans l'édition imprimée. **Il se vérifie en ouvrant un mushaf**, et il vaut
mieux le faire confirmer une fois que le découvrir en production : une ouverture inversée se voit
immédiatement et fait lire les pages à l'envers. C'est une vérification, pas un développement.

---

## 4. AMENDEMENT DE CONTRAT — deux méthodes sur `ServiceCoran` [PROTECTED]

`lib/core/coran/service_coran.dart` porte une **interdiction nommée** dans `FILE_OWNERSHIP` : Agent C
ne le modifie sous aucun prétexte. Les deux ajouts suivants lui reviennent donc, à Agent Z ou à son
propriétaire.

```dart
// lib/core/coran/service_coran.dart  (ajouts demandes a l'interface ServiceCoran)

/// Le verset ou commence un juz, ou `null` si le juz n'existe pas.
///
/// La table `public.juz` (0007) porte deja `sourate_depart` et `verset_depart`
/// pour les trente juz, et `0013` les a remplis : aucune donnee nouvelle n'est
/// demandee, seulement une lecture.
Future<({int sourate, int verset})?> debutDeJuz(int juz);

/// Les versets dont le texte contient [requete].
///
/// Rend `null` quand la lecture echoue, comme `sourates()` : une liste vide
/// dirait « ce mot n'est pas dans le Coran », ce qui serait faux.
Future<List<VersetCoran>?> rechercher(String requete, {int limite = 50});
```

**Double local en place en attendant** : `DebutsDeJuz.table` dans
`lib/core/tc_coran/corpus_service_coran.dart` porte les trente couples (sourate, verset) du découpage
Hafs, avec un commentaire qui dit qu'il duplique `public.juz` et **disparaît** le jour où
`debutDeJuz` existe. C'est un double local assumé, pas une donnée inventée : la base porte la même
chose.

---

## 5. DEMANDE SQL — l'index de recherche texte

Aucun index texte n'existe sur `verset` : **ni `tsvector`, ni `pg_trgm`, ni colonne normalisée sans
diacritiques**. Une recherche `ilike` sur `verset.texte` est inutilisable en pratique, parce que le
tracé uthmani porte des diacritiques que personne ne tape au clavier.

```sql
-- Colonne normalisee + index. Elle ne MODIFIE PAS `texte` : la licence Tanzil
-- interdit toute modification du texte, et l'invariant du corpus aussi.
alter table public.verset
  add column texte_recherche text generated always as (
    -- retrait des marques combinantes arabes U+064B..U+0652, U+0670, U+06D6..U+06ED
    regexp_replace(texte, '[ً-ْٰۖ-ۭ]', '', 'g')
  ) stored;

create index verset_recherche_idx on public.verset using gin (texte_recherche gin_trgm_ops);
-- extension requise : pg_trgm (absente du projet, a verifier avant).
-- RLS : la colonne suit celle de `verset`, aucune policy nouvelle.
-- Role appelant : identique a `verset`.
-- Table existante etendue : `public.verset`. Aucune table neuve.
```

**En attendant, l'écran le dit.** `FeuilleNavigationCoran` affiche en permanence :
« La recherche porte sur les numéros de page, les références et les noms de sourate. La recherche dans
le texte du Coran n'est pas encore disponible. » Elle ne rend jamais « aucun résultat » sur un mot
arabe, ce qui ferait croire que le mot n'est pas dans le Coran.

---

## 6. AMENDEMENT DE CONTRAT (Agent B) — l'identifiant de ressource du Coran

> **Les types eux-mêmes ne sont plus une demande.** Le stub
> `lib/core/tc_coran/ports_externes/content_position.dart` a d'abord été recopié des §7 et §8 de
> `CONTRACTS`, que l'AMENDEMENT 1 a ensuite déclarées périmées. Il reprend désormais **à l'identique**
> les déclarations canoniques d'Agent B (`lib/core/tc_bibliotheque/content_position.dart` et
> `content_range.dart`). Écart clos, rien à trancher. Seul l'identifiant ci-dessous reste ouvert.

`ContentPosition` et `ContentRange` exigent un `resourceId`. La table des ressources d'Agent B est
**neuve** : aucun identifiant réel n'existe.

**Double local en place** :
`const String identifiantRessourceCoran = 'quran:madina-hafs-604';`
(`lib/core/tc_coran/port_navigation_coran.dart`). Il reprend le **code** de l'édition, jamais un uuid :
l'identifiant de la ligne `mushaf` est généré par la base et diffère d'un environnement à l'autre.

**Demande** : qu'Agent B ou Agent Z fixe l'identifiant canonique du Coran dans le catalogue, et que la
constante pointe dessus. Un seul fichier à changer.

---

## 7. ARBITRAGE PRODUIT — la route et l'entrée de navigation

`lib/features/tc_mushaf/routes_tc_c.dart` expose `routesTcC()` sous le chemin réservé `/tc/mushaf`.
Conformément à D-04, la fonction **retourne** des routes et ne construit aucun `GoRouter`.

Deux choses restent à trancher, et aucune n'est du ressort d'Agent C :

1. **`redirection.dart`** redirige toute route hors préfixe de rôle vers la racine du rôle. Une route
   `/tc/…` posée sans ajustement sera **inatteignable**.
2. **L'entrée de navigation.** Une route sans entrée n'existe pas. Or `nav_shell.dart` est PROTECTED et
   **plafonné à quatre destinations par assertion**. Le Coran a déjà sa destination (`/eleve/coran`,
   atteinte depuis `_BlocCoran` de `accueil_eleve_page.dart`).

**Recommandation d'Agent C** : ne pas ajouter de cinquième destination. Le moteur est le **successeur**
de `ELV-04`, pas un écran de plus. Quand Agent Z jugera le moteur prêt, la destination existante doit
pointer sur lui, et `/eleve/coran` devenir une redirection — exactement le motif déjà employé pour les
sept anciennes routes Admin au lot IA-01. `lib/features/coran/coran_page.dart` est resté en place et
intact pour que cet arbitrage soit possible sans rien réécrire.

---

## 8. RISQUE JURIDIQUE — deux polices embarquées sans notice de licence

Constat direct sur `assets/fonts/` à la baseline `0071557` :

| Fichier | Taille | Licence présente |
|---|---|---|
| `BricolageGrotesque-Variable.ttf` | 407 844 o | `LICENSE-BricolageGrotesque.txt` |
| `InstrumentSans-Variable.ttf` | 193 312 o | `LICENSE-InstrumentSans.txt` |
| `Phosphor-Regular.ttf` / `Phosphor-Fill.ttf` | 488 636 / 449 252 o | `LICENSE-Phosphor.txt` |
| **`UthmanTahaNaskh-Regular.otf`** | **164 684 o** | **aucune** |
| **`NotoSansArabic-Variable.ttf`** | **844 676 o** | **aucune** |

`UthmanTahaNaskh` est la police de texte du Complexe du Roi Fahd. Elle est redistribuée dans le bundle
de l'application **sans notice**. Noto Sans Arabic est sous licence SIL OFL, qui **exige elle aussi**
que la notice accompagne toute redistribution.

**Ce n'est pas une demande de code**, c'est un signalement : il faut ajouter les deux fichiers de
licence, et vérifier les conditions de redistribution de la police KFGQPC. Le coût est de deux
fichiers texte ; le risque de ne pas le faire est d'une autre nature.

Ce point prend d'autant plus d'importance si la demande n°2 (jeu QCF) aboutit : on passerait de deux
fichiers non documentés à six cent six.

---

## 9. Ce qui n'est PAS demandé, et pourquoi

Pour que la liste ci-dessus se lise comme une liste courte, voici ce qui a été écarté :

| Écarté | Raison |
|---|---|
| Une seconde table de corpus | `EXISTING_MAPPING` §9.3 : « interdire toute nouvelle table de corpus ». Le moteur lit `0007` + `0013` |
| Un second service de lecture du Coran | Même règle. Tout passe par `ServiceCoran`, derrière `PortCorpusCoran` |
| Une dépendance de rendu PDF | Le Coran n'est pas un PDF (invariant J6, décision D-09) |
| `timezone` / `intl` | Le moteur ne convertit aucun fuseau |
| Une icône de zoom, de focus ou de double page | Des libellés font le travail et se traduisent ; voir §0 |
| Une seconde route Coran | Voir §7 |
| Une migration | Interdite en phase parallèle (D-12). Tout est ci-dessus en « DEMANDE SQL » |
