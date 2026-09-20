# TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md

> Feuille de route d'Agent Z, dans l'ordre où il devra l'exécuter.
> Produit par le contrôle pré-merge du 20/09/2026, à partir de trois audits en lecture seule
> (ownership, cohérence des stubs, consolidation des demandes), d'une passe de correction sur les
> deux lots qui étaient bloqués, et d'une campagne de remesure.
> **Document de planification : il n'autorise rien.** La condition d'ouverture est posée par
> `TEACHING_CORE_PREMERGE_REPORT.md`, qui contient aujourd'hui **un lot BLOCKED (A)**.

---

## 0. Condition d'ouverture — à relire avant la première commande

La spécification est formelle (`D:\RA_TC\SPEC_TEACHING_CORE_V1.md:1421` et `:1430`) :

> « Aucune intégration tant qu'un seul lot est BLOCKED. »
> « CONDITION : `TEACHING_CORE_PREMERGE_REPORT.md` ne contient aucun BLOCKED. »

État au 20/09/2026 : **A = BLOCKED**, seul. Les lots **C** (`e60c5b4`) et **D** (`bc40b4a`), bloqués
au contrôle précédent, ont été corrigés et re-contrôlés par comparaison programmatique : les deux
corrections tiennent, aucun test n'a été supprimé pour verdir la suite. La remise au vert d'A est
décrite au § 1 ; elle est petite et entièrement cernée, mais elle doit être faite, re-contrôlée et le
rapport pré-merge réémis **avant** la PHASE 1 du PROMPT IMMUABLE Z.

Deuxième condition, indépendante de ce chantier : le chantier Admin doit être terminé et porter un
`TARGET_SHA` connu, `integration/teaching-core` partant de ce `TARGET_SHA` et jamais de la baseline
`0071557`.

**Bonne nouvelle mesurée qui allège la PHASE 2 :** sur les 321 fichiers des neuf branches, **321 sont
des ajouts** (`git diff --name-status 0071557 HEAD` : `A=36/36/32/37/39/32/31/39/39`, zéro `M`, zéro
`D`), et le croisement des neuf listes donne **321 chemins distincts pour 321 chemins touchés, donc
zéro intersection**. Aucun fichier préexistant n'a été touché par un agent, donc aucune décision
Admin ne peut être écrasée par un merge d'agent. La PHASE 2 est une vérification, pas une
réconciliation. Tout conflit qui apparaîtrait viendrait du rebase sur `TARGET_SHA`, jamais d'un agent
contre un autre.

**Référence de non-régression** — mesurée pour ce contrôle, à battre après chaque étape :

| A | B | C | D | E | F | G | H | Q | Total |
|---|---|---|---|---|---|---|---|---|---|
| 107 | 95 | 94 | 85 | 93 | 61 | 75 | 71 | 104 | **785 tests verts, 9 `analyze` propres** |

---

## 1. Étape 0 — la remise au vert du lot A, exigée avant toute fusion

Agent A est le seul des six stubeurs à ne pas avoir aligné ses stubs sur les fichiers publiés par les
producteurs : ses en-têtes citent encore « TEACHING_CORE_CONTRACTS.md section 7 », que l'AMENDEMENT 1
déclare périmée. Ce n'est pas une négligence — A avait **demandé** cette forme canonique dans
`TC_CONTRACT_REQUEST_A.md` §6, l'AMENDEMENT 1 y a répondu, et A n'a jamais su que la réponse existait
(un seul commit, `ae66c4c`, quand C et D en ont poussé d'alignement).

Trois corrections, dans cet ordre.

### 1.1 `TypeAncrage` et les cinq autres énumérations appauvries

`a\lib\core\tc_groupe\ports_externes\content_position.dart:18` déclare
`enum TypeAncrage { page, ayah, section, fraction }` nu. Le canonique de B porte
`page('page') …`, `const TypeAncrage(this.valeurSql)`, `final String valeurSql`,
`static TypeAncrage? depuisSql(String?)`, quatre assertions d'invariant, `operator ==` et `hashCode`
— 137 lignes de code contre 70. Même défaut sur cinq énumérations de `a\...\port_catalogue.dart`
(`TypeRessource`, `CapaciteRessource`, `PolitiqueAcces`, `PolitiqueOffline`, `EtatOffline`).

**Remède : supprimer les stubs et pointer sur les canoniques** (§ 5, vague 1). Le code d'A compile
tel quel — la divergence va dans le sens du rétrécissement et A n'appelle jamais `valeurSql` (unique
usage de `ContentPosition` hors stub : `a\...\port_catalogue.dart:215`, une annotation de type).

**Après bascule, exécuter les tests d'A en mode debug, assertions actives.** Les quatre assertions du
canonique n'ont jamais tourné chez A : vérifier qu'aucun appel ne construit une `ContentPosition`
avec deux ancrages renseignés, et qu'aucun `Set<ContentPosition>` ni `Map<ContentPosition, …>` ne
reposait sur l'égalité par identité — on **gagne** l'égalité structurelle, ce qui peut fusionner deux
éléments jusqu'ici distincts.

### 1.2 `portTravailAVenirProvider` — nullable chez A, levant chez H

`a\...\port_travail_a_venir.dart:29` : `Provider<PortTravailAVenir?> … => null`.
`h\lib\core\tc_parcours\port_travail_a_venir.dart:141-146` :
`Provider<PortTravailAVenir> … => throw UnimplementedError(...)`.
`a\lib\features\tc_espace_groupe\espace_groupe_page.dart:178` fait
`ref.watch(portTravailAVenirProvider)` puis teste la nullité : le `watch` lèvera **avant** d'atteindre
le test. L'affectation compile, rien n'est signalé, et l'Espace Groupe passe d'un état vide propre à
un plantage au premier build.

**Arbitrage retenu : la forme nullable, portée par H.** Motif mesuré : `learning_assignment` n'existe
pas en base (`to_regclass` → `null`), l'état « port non branché » est donc un état **réel** du
produit et non un cas mort ; un `throw` transforme une dégradation propre en plantage. Agent Z
remplace `h\...\port_travail_a_venir.dart:141-146` par
`final Provider<PortTravailAVenir?> portTravailAVenirProvider = Provider<PortTravailAVenir?>((Ref ref) => null);`
et reprend le site de lecture de H en conséquence.

Le jour où la composition réelle existe (`TravailAVenir(ref.watch(portAssignationsProvider), <adaptateur SourceContenuSeance>)`),
c'est ce provider qu'on branche — pas le `throw`. **Le même arbitrage s'applique à
`portAssignationsProvider`** (`d\lib\core\tc_outils\port_assignations.dart`), qui lève également.

### 1.3 `portCatalogueProvider` — nullable chez A, non nullable chez B, et pas dans le fichier annoncé

`a\...\port_catalogue.dart:250-252` déclare `Provider<PortCatalogue?> … => null` sous un en-tête qui
annonce `canonique = lib/core/tc_bibliotheque/port_catalogue.dart`. Le vrai canonique est
`b\lib\core\tc_bibliotheque\donnees_catalogue.dart:31-33`,
`Provider<PortCatalogue> … => CatalogueLocal()` — `portCatalogueProvider` n'apparaît **nulle part**
dans `b\...\port_catalogue.dart`.

**Arbitrage retenu : la forme non nullable, chez B.** Motif symétrique du précédent : B livre
`CatalogueLocal`, une implémentation qui existe toujours ; l'état « non branché » de l'emplacement
Bibliothèque est donc inatteignable par construction. Agent Z ouvre
`a\lib\features\tc_espace_groupe\emplacements_groupe.dart:108`, remplace
`final PortCatalogue? catalogue` par `final PortCatalogue catalogue`, **supprime** la branche « non
branché » devenue morte et la remplace par le rendu de l'état vide du catalogue de B. Ne pas laisser
le garde de nullité : `flutter analyze` le signalera.

### 1.4 Le fichier i18n d'A, à traiter à part

`tc_i18n_A.json` est le seul des neuf à porter une enveloppe de locale au-dessus de la racine `tc`
(`_meta`, `fr`, `ar`). Traitement détaillé au § 7, règle 1. **Ne pas le passer dans la boucle de
fusion des huit autres** : il en sortirait silencieusement vide.

### 1.5 Contrôle de sortie

`flutter analyze lib test` propre et `flutter test test/teaching_core/a` à **107 tests verts**
(référence mesurée le 20/09). Puis réémettre `TEACHING_CORE_PREMERGE_REPORT.md` sans aucun BLOCKED.

**Ne pas demander cette correction à Agent A.** Le lot B est intégré avant le lot A dans l'ordre de
la PHASE 4 : le canonique sera déjà en place quand A arrivera.

---

## 2. Ordre d'intégration — PHASE 4 du PROMPT IMMUABLE Z

Cet ordre est imposé par la spécification (`SPEC_TEACHING_CORE_V1.md:1460-1470`). Il n'est pas
négociable et il est cohérent avec le graphe de dépendance des stubs mesuré : B ne consomme rien, et
chaque lot arrive après le producteur des types qu'il consomme.

| Rang | Lot | Domaine | Ce qui doit être en place avant |
|---|---|---|---|
| 1 | **Contrats partagés** | types canoniques, dépendances tranchées, i18n, icônes, jetons, routes | § 3 à § 9 de ce document |
| 2 | **B** | Library Core | rien (B ne consomme aucun port) |
| 3 | **C** | Quran Engine | types de B, types de F |
| 4 | **A** | Group Space | types de B ; les deux providers tranchés (§ 1.2, § 1.3) |
| 5 | **H** | Academic Flow | types de B, de D, de A ; **stubs d'E conservés à ce rang** (voir note) |
| 6 | **D** | Teaching Tools | types de B, de F |
| 7 | **F** | Realtime Protocol | types de B |
| 8 | **E** | Classroom Shell | types de B, D, F, A, G |
| 9 | **G** | Observation & Policies | migration de l'enum `participant_role` appliquée (§ 4, palier 3) |
| 10 | **Q** | QA finale | tout `lib/` unifié, sinon Q compile contre ses propres doubles |

Après **chaque** rang : `flutter analyze`, les tests concernés, le build ciblé, le contrôle des
routes et du câblage. Aucun redesign opportuniste. Si une fonctionnalité exige une réécriture
importante : STOP et `INTEGRATION_REJECT_<AGENT>.md`.

**Deux notes d'ordonnancement, toutes deux importantes.**

1. Les rangs 5 (H) et 6 (D) sont **inversés** par rapport au graphe de types : H consomme
   `LearningAssignment` et `IntentionPedagogique`, qui appartiennent à D. La spécification prime ;
   concrètement, les stubs de H sur les types de D (vague 2 du § 5) doivent être résolus **au rang 1**,
   avec les contrats partagés, et non au rang 5.
2. H arrive **avant** E alors qu'il stube deux types d'E (`TeacherStudentProjection`,
   `PortRosterEnseignant`). Intégrer H **avec ses stubs en place**, faire la substitution au moment
   d'intégrer E (rang 8), et **rejouer `test/teaching_core/h/` à ce moment-là**, pas avant. La copie
   de H a été vérifiée champ par champ contre le canonique d'E : elle est identique, la substitution
   sera mécanique.

---

## 3. Arbitrages à trancher par un humain AVANT l'intégration

Vingt arbitrages ont été relevés qu'aucun agent ne pouvait prendre seul. Ils se rangent en trois
paquets. **Les porter à l'opérateur en un seul document, pas un par un.**

### 3.1 Paquet PRODUIT — une réunion, six questions (bloquant)

| # | Question | Pourquoi personne d'autre ne peut trancher | Source |
|---|---|---|---|
| 1 | **Entrée de navigation du Teaching Core** sous le plafond de 4 destinations | `nav_shell.dart:284` pose `maxDestinations = 4` et deux assertions (`:140`, `:225`) interdisent la cinquième ; les quatre de l'enseignant sont prises. Ce n'est pas un patch, c'est un choix de produit. | A §5, B §6, C §7, E §5.2, G §4 |
| 2 | `session_feedback` : **empreinte non réversible** ou colonne nominative | Confidentialité élève. H écrit lui-même : « Le lot H ne tranche pas seul un arbitrage de confidentialité. » | H §1.1 |
| 3 | Dixième valeur de projection **`excuse`** | Aujourd'hui `excusee` devient `absent` et l'information se perd. J4 interdit un quinzième état en base. | E §1.5 |
| 4 | Coran : importer les **83 668 mots QUL** (fidélité) ou peupler `verset.ligne` seul (dégradé assumé) | Mesuré : `verset.ligne` est NULL sur les **6236** versets. | C §1.3 |
| 5 | Jeu de polices **QCF** — 604 fichiers, dizaines de Mo contre un budget de 20 Mo | C recommande **non**, et explique qu'il n'apporte aucune fidélité sans la demande C §1 préalable. | C §2 |
| 6 | `TendanceFeedback` **par question** ou **tonalité générale** | H a implémenté la tonalité générale « parce que c'est ce que le contrat dit » ; le produit doit confirmer. | H §2.3 |

**Trois recommandations déjà chiffrées par les agents, qu'il suffit d'entériner.** Sur (1) : aucune
cinquième destination — la Bibliothèque vit **dans** l'Espace Groupe (B §6), la destination
`/eleve/coran` existante pointe sur le nouveau moteur et l'ancienne route devient une redirection
(C §7, motif déjà employé pour les sept anciennes routes Admin du lot IA-01), et la Classe Live
s'atteint par le bouton « Rejoindre » et la barre « Cours en cours » (E §5.2). **Seul « Mes groupes »
(A) reste sans solution** et exige une décision d'opérateur. Sur (4) : retenir l'option dégradée pour
ce lot, en actant que `DisponibiliteLayout` vaudra `degrade` et jamais `fidele`. Sur (5) : refuser
pour ce lot.

### 3.2 Paquet TECHNIQUE — Agent Z tranche seul, mais écrit sa décision

| # | Question | Décision recommandée |
|---|---|---|
| 7 | Horloges rendues **serveur** ou **client** (A §1.9) | **Serveur.** N'ajoute aucune dépendance, fait converger client et serveur, et A a écrit son code pour ce cas par défaut. Acter que les horloges ne fonctionnent pas hors ligne. |
| 8 | Qui appelle `materialiser_seances_groupe`, et quand | Le dépôt n'a **aucun ordonnanceur** et `materialiser_seances` n'est appelée par aucune fonction SQL ni par `lib/`. Décider d'un appel à la création/modification de groupe plutôt que d'un cron inexistant. |
| 9 | Priorité entre un groupe et une affectation 1-à-1 résiduelle (`guard_session_overlap`) | À trancher dans la **même** réécriture que le palier 7 (§ 4.8). |
| 10 | Plafond de participants et observateurs | Voir § 4.8 : le plafond est **inerte** depuis `0017`. La vraie question est de décider si c'est voulu. |
| 11 | Table Drift ou `shared_preferences` | **Une seule migration Drift 1→2** portant `RessourcesHorsLigne` (B §3.1) **et** `preference_locale` (D §4), sans ajouter `shared_preferences`. |
| 12 | Ordre naturel des ancrages `section` | Le canonique de B fait foi (`_rangTexte` sur 8 caractères). |
| 13 | Convention de suffixe de sujet pour le canal éphémère | F §1.4 Q1 — LiveKit ne remonte pas `DataPacket_Kind` à la réception. |
| 14 | Fermeture serveur des intervalles d'observation : webhook LiveKit ou calcul à la lecture | G §1.7 et Q §4.3 demandent la même chose : **un** ticket. |
| 15 | `entrer_observation()` est-elle la « troisième porte » que `0012` et Q §4.2 interdisent | Trancher avant d'écrire la RPC. |
| 16 | Sort de `tc_i18n_Q.json` | **Supprimer** (§ 7, règle 3). |
| 17 | Prédicat de foyer | **Un seul helper `est_du_foyer(uuid)`**, voir § 4.4 — corrigé depuis la version précédente de ce plan. |
| 18 | Surcharge de politique d'observation par groupe | G §1.2 et §1.6 : ouvrir ou non. |

### 3.3 Paquet JURIDIQUE / BUDGET — hors chantier, ne dépend d'aucun agent

| # | Question | Recommandation |
|---|---|---|
| 19 | Dépendance **`pdfrx`** : licence PDFium et poids du bundle web | Voir § 6. **À mesurer, pas à estimer.** |
| 20 | Côté de page impair-à-droite du Mushaf | « Se vérifie en ouvrant un mushaf » (C §3 bis). |
| 21 | **Licences manquantes** de `UthmanTahaNaskh-Regular.otf` (164 684 o) et `NotoSansArabic-Variable.ttf` (844 676 o) | **À faire tout de suite**, coût = deux fichiers texte. `LICENSE-BricolageGrotesque.txt`, `LICENSE-InstrumentSans.txt` et `LICENSE-Phosphor.txt` existent ; ces deux-là sont redistribuées sans notice. Noto Sans Arabic est sous SIL OFL, qui **exige** que la notice accompagne la redistribution. Pour UthmanTahaNaskh (Complexe du Roi Fahd), vérifier d'abord les conditions : si elles ne permettent pas la redistribution, la police doit **sortir du bundle**, ce qui est un changement de rendu et pas un changement de fichier texte. À faire **avant** de trancher l'arbitrage QCF, pas après — sinon on passerait « de deux fichiers non documentés à six cent six ». |

**Deux arbitrages sont déjà CLOS et ne doivent pas être rouverts** : `TC_CONTRACT_REQUEST_A.md` §6
(forme canonique de `ContentPosition`) l'est par l'**AMENDEMENT 1**, et §7 (port consommé par slot)
par l'**AMENDEMENT 2**, qui reprend nommément l'argument d'Agent A. Agent Z doit marquer ces deux
sections comme closes en les lisant.

---

## 4. Demandes SQL consolidées, ordonnées par dépendance

**63 objets SQL distincts** après déduplication de 11 doublons, plus 2 seaux Storage hors SQL.
Décomposition : 1 extension + 9 (palier 1) + 13 (palier 2) + 1 (palier 3) + 14 (palier 4) +
4 (palier 5) + 18 (palier 6) + 3 (palier 7).

### 4.0 Deux affirmations des audits sont périmées — les corriger avant d'écrire une ligne de SQL

**(a) Les migrations `0020` à `0024` SONT appliquées.** L'audit de consolidation en fait un BLOCKER
préalable ; il a lu l'en-tête de `0025_role_enseignant.sql` (« N'ONT JAMAIS ÉTÉ APPLIQUÉES »), pas la
base. Mesuré sur `gggmtelinlpseweouyav` : `list_migrations` rend `20260919232916 0020_programme_pedagogique`,
`20260920033433 diagnostics_placement`, `20260920033522 progression_suivi`,
`20260920033612 evaluations`, `20260920033657 qualite_pedagogique`, et
`to_regclass('public.programme_niveaux')` rend `programme_niveaux`.

Conséquences directes, à appliquer :
- **A §1.7** : écrire
  `alter table public.groupes add column if not exists programme_niveau_id uuid references public.programme_niveaux(id);`
  **sans garde `to_regclass`, sans repli `null`, sans ordonnancement spécial.**
- **E §1.1** : joindre directement `programme_niveaux` / `progression_historique` dans
  `teacher_roster_v`, en exposant `nom_humain` et **jamais** `code_technique`. Ne pas livrer la vue
  amputée de `curriculum_path`, `current_unit` et `active_goals` : le repli prévu n'a plus lieu d'être.
- **B §1.1** : `level_scope text[]` peut porter une contrainte réelle au lieu de rester un tableau de
  codes non contraints.
- **Corriger l'en-tête de `0025`** (ou poser la note en tête de `0030`) : il est désormais faux et il
  a déjà induit un audit en erreur.

**(b) La migration `0029` EST appliquée ; `dossiers_en_attente()` n'accorde plus `anon`.**
`list_migrations` rend `20260920025402 fermeture_dossiers_en_attente_anon`, et
`information_schema.routine_privileges` rend `agent_ro, authenticated, postgres, service_role` —
`anon` est absent. Le « défaut le plus grave de la baseline », relayé par cinq agents, est **clos**.
Agent Z n'écrit aucun correctif et publie un addendum d'une ligne. Le **second** défaut du même
addendum (`catalogue_galerie_test` rouge) reste ouvert.

### 4.1 Découpage en quatre migrations

| Fichier | Contenu | Motif du découpage |
|---|---|---|
| `0030_tc_socle.sql` | paliers 0, 1 et 2 — aucune table neuve | Le lot le plus sûr ; débloque A §1.4 et le compte à rebours. |
| `0031_participant_role_admin.sql` | **uniquement** les deux `alter type public.participant_role add value` | PostgreSQL refuse d'**utiliser** une valeur d'enum ajoutée dans la même transaction ; une migration est une transaction. L'ordre des fichiers est la seule garantie. |
| `0032_tc_catalogue.sql` | palier 4, chaîne B réordonnée, puis D, F, G, H dans l'ordre des FK | Les tables neuves et elles seules. |
| `0033_tc_vues_rpc.sql` | paliers 5, 6 et 7 | Les vues et RPC ne se créent qu'au-dessus des tables. |

En tête de **chaque** fichier, répéter les deux règles que les huit agents demandent à l'unisson :
jamais de `grant execute` à `agent_ro` sur une fonction volatile ou d'écriture, et masquage colonne
par colonne (la RLS borne les **lignes**, pas les **colonnes**).

Faire échouer `0032` par un bloc `do $$` final si l'une des 14 tables manque, sur le modèle du bloc
de contrôle de `0013_corpus_coranique.sql`.

### 4.2 Palier 0 — l'extension

`create extension if not exists pg_trgm with schema extensions;` — mesuré : `pg_trgm` est
**disponible mais non installée** (`installed_version` nul ; seules `pgcrypto`, `uuid-ossp`,
`btree_gist`, `pg_stat_statements` et `supabase_vault` le sont). Reprendre **exactement** la forme de
`0001:19`, avec `with schema extensions` — le dépôt documente en `0001:11` qu'un
`create extension` sans schéma n'installe rien d'utilisable. Vérifier ensuite que `gin_trgm_ops` se
résout ; selon le `search_path` de la migration, il faudra peut-être le qualifier
`extensions.gin_trgm_ops`. **Demandeur : C §5. Sans elle, l'index GIN de la recherche coranique échoue
à la création.**

### 4.3 Palier 1 — `app_config` et deux helpers (9 objets)

Mesuré : **aucune** des sept clés n'existe aujourd'hui dans `public.app_config`.

| Clé | Valeur | Demandeur | Ce qui casse sans elle |
|---|---|---|---|
| `join_window_minutes` | `20` | A §1.4 (D-13) | Le bouton « Rejoindre » s'ouvre à T-20 côté client alors que `autoriser_jeton_video()` refuse encore 10 minutes. |
| `grace_after_end_minutes` | `15` | A §1.9 | Fin de séance codée en dur (`0010:309`). |
| `observation.activee` | | G §1.1 | Aucun interrupteur d'observation. |
| `observation.max_visits_per_session` | | G §1.1 | Budget d'observation non applicable. |
| `observation.max_total_seconds` | | G §1.1 | idem |
| `observation.max_seconds_per_visit` | | G §1.1 | idem |
| `observation.policy_version` | `'a1'` (**text**) | G §1.1, §1.6 | Voir l'idiome ci-dessous. |

**Un seul `insert into public.app_config` pour les sept.** A, G et H les ont demandées séparément.

| Fonction | Demandeur | Ce qui casse sans elle |
|---|---|---|
| `public.est_du_foyer(uuid)` | A §1.2 **et** H §1.4 — voir § 4.4 | `mes_groupes_famille_v` et `concern_famille_v` sont toutes deux non exécutables. |
| `public.maintenant_serveur()` | A §1.5 | Pas de référence de temps serveur pour les horloges. |

**Idiome de lecture, non négociable.** Deux habitudes se croisent dans les demandes, et l'une emploie
une fonction **révoquée au rôle appelant** : A écrit `(public.get_config('x'))::int`, or `0001:1221`
révoque `get_config` à `anon`, `authenticated` et `public`. Le motif du dépôt pour les seuils
réglables est `public.app_config_int(p_key text, p_defaut int)` (`0007:150`, accordé à
`authenticated` en `0007:421`), déjà employé trois fois dans `etat_presence` (`0010:508-510`), et H
l'utilise correctement. **Remplacer partout `get_config(...)::int` par `app_config_int(clé, défaut)`
dans les objets d'A (1.1, 1.4, 1.9) et de G (1.1, 1.6).** Les fonctions d'A étant `security definer`,
elles s'exécuteraient malgré tout : le défaut n'est pas une panne, c'est une divergence de motif —
et un seul motif de lecture est ce qui permettra de changer la source plus tard sans chercher les
appelants.

Pour une valeur **textuelle** comme `observation.policy_version`, appliquer `#>> '{}'` : un cast
direct rendrait la chaîne **avec ses guillemets**, et le journal d'audit comparerait des versions qui
ne s'égaleraient jamais. Vérifier enfin que chaque clé a le **même défaut en dur** côté appelant : un
défaut différent entre la base et le code est un écart qui ne se voit qu'en production.

### 4.4 La déduplication la plus rentable — un seul prédicat de foyer

**Correction d'une erreur de la version précédente de ce plan.** Il affirmait que `household_members`
était la primitive réelle. **Elle n'existe pas** : zéro occurrence dans les 29 migrations,
`to_regclass('public.household_members')` → `null`. `est_du_foyer` n'existe pas non plus (`pg_proc`
→ 0). Agent A écrivait contre une table inexistante, Agent H contre une fonction inexistante, **pour
le même besoin** : les deux vues sont non exécutables telles qu'écrites.

La forme réelle est `public.profiles.household_id` (`0001:75`), et le prédicat canonique déjà
dupliqué cinq fois dans le dépôt est
`p.household_id = public.app_household_id() and p.deleted_at is null`
(`0001:686`, `:729`, `:741`, `:785`, `:1030`).

```sql
create function public.est_du_foyer(p_profile_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
    where p.id = p_profile_id
      and p.household_id = public.app_household_id()
      and p.deleted_at is null
  )
$$;
revoke execute on function public.est_du_foyer(uuid) from anon, public;
grant  execute on function public.est_du_foyer(uuid) to authenticated;
```

Puis : remplacer dans `mes_groupes_famille_v` (A §1.2) le sous-select sur `household_members` par
`public.est_du_foyer(m.student_id)`, et laisser `concern_famille_v` (H §1.4) inchangée — elle appelle
déjà cette fonction. Appliquer **le même prédicat** dans la policy de lecture tuteur de
`learning_assignment` (D §3.3). **Jamais deux prédicats de foyer** : deux filtres qui divergeraient
feraient voir à un tuteur un groupe qu'un autre écran lui cacherait.

### 4.5 Palier 2 — colonnes sur tables existantes (13 objets ; aucune n'existe, mesuré)

| Objet | Demandeur | Ce qui casse sans lui |
|---|---|---|
| `sessions.join_opens_at` | A §1.4 | La fenêtre d'entrée n'est pas stockable par séance. **À poser AVANT `materialiser_seances_groupe`**, dont le corps l'écrit déjà. |
| `groupes.couleur_jeton` | A §1.6 | Identité visuelle de groupe (§ 9.2). |
| `groupes.nom_cours` | A §1.7 | Le nom du cours n'existe pas. |
| `groupes.programme_niveau_id` → `programme_niveaux(id)` | A §1.7 | **Dépendait de `0020`, qui est appliquée** : FK directe, sans garde. |
| `groupes.observation_source`, `_max_visites`, `_max_secondes`, `_max_secondes_par_visite`, `_revision` (5 colonnes) + 3 `CHECK` + trigger de révision | G §1.2 | Héritage et personnalisation de la politique d'observation par groupe. |
| `teacher_profiles.photo_storage_key`, `teacher_profiles.titre` | A §1.8 (D-01/D-02) | Photo et titre Sayyid/Sayyida de l'enseignant. |
| `verset.texte_recherche` (colonne générée) + index GIN | C §5 | Recherche dans le Coran. **Prérequis palier 0.** Vérifier que la colonne générée **ne modifie pas** `verset.texte` : la licence Tanzil interdit toute modification du texte. |

### 4.6 Palier 3 — l'enum, seul dans son fichier (1 objet)

`alter type public.participant_role add value 'admin_masked';` puis `'admin_visible';` (G §1.4).
Mesuré : `participant_role` porte aujourd'hui `teacher, student, guardian_observer, masked_controller`
et date de `0001:47` — l'enum n'est donc pas créé dans la transaction. PostgreSQL refusera
néanmoins toute `policy`, `check` ou `view` qui **nomme** la nouvelle valeur dans la même transaction
(`55P04 unsafe_new_enum_value_usage`). Les corps de fonction, eux, passent : ils ne sont pas évalués à
la création, ce qui rendrait le piège intermittent, donc pire. **Ne jamais fusionner `0031` avec
`0032`.**

### 4.7 Palier 4 — 14 tables neuves, dans l'ordre des clés étrangères

**La chaîne d'Agent B d'abord, et son DDL n'est pas exécutable tel qu'écrit.** Deux défauts
d'ordonnancement mécaniques : `library_resource` déclare trois types enum écrits **après** elle, et
`library_resource.current_version_id` référence `resource_version`, qui n'est créée qu'ensuite **et**
référence `library_resource` en retour — FK circulaire. Même motif dans B §1.3 et §1.5.

**Réordonnancement imposé dans `0032`** : (1) les sept `create type` **en premier** ; (2)
`library_resource` **sans** `current_version_id` ; (3) `resource_version` ; (4) `download_asset` ;
(5) `alter table public.library_resource add column current_version_id uuid references public.resource_version(id);`
— ou contrainte `deferrable initially deferred`. C'est le seul ordre qui casse le cycle.

| Ordre | Table | Demandeur | Ce qui casse sans elle |
|---|---|---|---|
| 1 | `library_resource` | B §1.1 | Toute la Bibliothèque, **et** les quatre tables qui la référencent. L'échec de cette table bloque quatre autres lots. |
| 2 | `resource_version` | B §1.2 | Versionnement des supports. |
| 3 | `download_asset` | B §1.3 | Mode hors ligne. |
| 4 | `library_resource_groupe` | B §1.4 | Ressources attachées à un groupe. |
| 5 | `library_reading_position` | B §1.5 | Reprise de lecture individuelle. |
| 6 | `annotation_layer` | D §3.1 | Calques d'annotation. `resource_id` doit porter la FK — D l'annonce en prose sans l'écrire en DDL. |
| 7 | `annotation_trait` | D §3.2 | Traits de stylet. |
| 8 | `annotation_marqueur` | D §3.2 | Marqueurs sémantiques. |
| 9 | `learning_assignment` | D §3.3 | Travail à venir. **C'est la table dont l'absence justifie le provider nullable du § 1.2.** Index à créer en `(group_id, student_id, status, due_at)` et non `(group_id, status, due_at)` — voir § 10 des amendements, sinon le filtre par élève fait un scan. |
| 10 | `session_shared_content` | F §3.2 | État partagé de séance. Porte déjà `group_resume_position jsonb` (doublon 4). |
| 11 | `guardian_session_visit` | G §1.3 | Journal des visites d'observation. |
| 12 | `session_feedback` | H §1.1 | Feedback post-cours. Dépend de l'arbitrage 2 (§ 3.1). |
| 13 | `student_concern` | H §1.4 | Signalement. **Ne pas reproduire le défaut de `lesson_reports_teacher_write`** (§ 10, point 3) : vérifier que la séance appartient à l'enseignant, pas seulement `author_profile_id = auth.uid()`. H le demande nommément. |
| 14 | `mot` | C §1.4 option (a) | **Conditionnel** : dépend de l'arbitrage produit n° 4 (§ 3.1). |

**Cohérence de couplage à trancher une fois pour trois tables.** `session_shared_content.resource_id`
(F §3.2) est `uuid not null` **sans** clé étrangère, alors que `annotation_layer.resource_id` et
`learning_assignment.resource_id` sont annoncées comme référençant la table de B. Recommandation : FK
partout, `on delete cascade` pour `annotation_layer` et `learning_assignment` (une annotation sur une
ressource disparue n'a pas de sens), `on delete restrict` pour `session_shared_content` (on ne
supprime pas une ressource présentée pendant une séance archivée). Écrire la décision en commentaire
SQL.

**Identifiant canonique du Coran.** Insérer la ligne du Coran dans `library_resource` avec un
identifiant stable, puis remplacer la constante locale d'Agent C
(`const String identifiantRessourceCoran = 'quran:madina-hafs-604'`, dans
`lib/core/tc_coran/port_navigation_coran.dart`) par cet identifiant. **Un seul fichier à changer**,
C l'indique. Tant que cette constante existe, les positions de C ne sont pas partageables.

### 4.8 Paliers 5, 6 et 7 — vues, RPC, et le point chaud

**Palier 5 — 4 vues.**

| Vue | Demandeur | Ce qui casse sans elle |
|---|---|---|
| `mes_groupes_famille_v` | A §1.2 | Vue famille de « Mes groupes ». **Dépend de `est_du_foyer` (§ 4.4), de 2.1 et de 2.3.** |
| `teacher_roster_v` **étendue, et non recréée** | E §1.1 | Roster enseignant sans le curriculum. Dépend de `0020`-`0024`, **appliquées**. |
| `tendance_feedback_v` | H §1.2 | Tendance de feedback. |
| `concern_famille_v` | H §1.4 | Signalement visible par la famille. **Dépend de `est_du_foyer`.** |

**Palier 6 — 18 RPC**, aucune n'existe (`pg_proc` interrogé → aucun résultat) :
`materialiser_seances_groupe`, `horloge_seance`, `transitions_fuseau_a_venir`, paramètres
supplémentaires sur `creer_groupe` / `modifier_groupe`, `groupes_admin()` élargie (A) ·
`ressources_du_groupe` (B) · `groupe_roster_enseignant` (E) · `publier_etat_partage` (F) · les sept
de G, dont `annonces_observation`, que
`g\lib\core\tc_observation\port_annonce_observation.dart:57-60` signale explicitement comme
inexistante · `doit_demander_feedback` et `derniere_position_groupe` (H).

**`materialiser_seances_groupe` est la condition d'existence du chantier**, pas une demande parmi
d'autres. Mesuré : `0025:46-51` ajoute bien `sessions.groupe_id`, mais la seule insertion dans
`public.sessions` de tout le dépôt (`0005:996`) ne la renseigne pas, et aucun appelant n'existe.
Sans occurrences de séance rattachées à un groupe, **cinq lots sur neuf n'ont aucune donnée à lire**
(A, E, F, G, H). La poser **après** `sessions.join_opens_at` (§ 4.5), sans quoi elle échoue sur
colonne inconnue.

**`derniere_position_groupe` — déduplication gratuite.** H présente deux options sans avoir vu que
l'option (a) est déjà écrite dans la demande de F : `session_shared_content` porte **déjà**
`group_resume_position jsonb`. **Ne créer aucune table `groupe_position_reprise`.** N'écrire qu'une
fonction de lecture rendant le `group_resume_position` de la séance la plus récente du groupe
(`order by updated_at desc limit 1`), avec un prédicat de visibilité **explicite** — membre du
groupe, tuteur du foyer via `est_du_foyer()`, enseignant assigné, admin — puisque `security definer`
contourne la RLS. Brancher ensuite `SourceContenuSeance.repriseDeGroupe(groupeId)` dessus et
supprimer le double `ContenuSeanceIndisponible`. Rappel de l'invariant J2 : cette position ne s'écrit
**jamais** dans `student_reading_position`.

**Palier 7 — le seul point de collision du chantier (3 fonctions).** Trois agents demandent des
modifications **incompatibles en l'état** sur les **mêmes trois fonctions existantes**. Appliquées
dans trois migrations séparées par `create or replace`, la dernière écraserait les deux premières
**sans conflit visible**.

| Fonction | A demande | G demande | Q exige |
|---|---|---|---|
| `autoriser_jeton_video()` | remplacer `interval '10 minutes'` par `join_window_minutes` | capacités des rôles `admin_masked`/`admin_visible` ; `ttl_seconds = least(token_ttl_seconds, restant_secondes)` ; refus si `budget_observation()` rend `peut_entrer = false` | le contrôle de quota **précède** le jeton |
| `guard_session_participant_cap()` | le plafond déborde | ajouter les deux nouveaux rôles à l'exemption | idem |
| `guard_session_overlap()` | élève à la fois en groupe et en 1-à-1 résiduel | ajouter les deux nouveaux rôles | idem |

**Règle : une seule version finale de chacune de ces trois fonctions, dans un seul fichier, portant
simultanément les trois demandes.** Interdire tout second `create or replace` sur elles dans le même
lot.

Ordre imposé du corps d'`autoriser_jeton_video()` (G §1.6 et Q §4.2 — « un jeton d'abord et un quota
ensuite a déjà laissé entrer ») : (1) la séance existe et est dans la fenêtre ; (2) droit de tenir le
rôle ; (3) si rôle d'observation, `budget_observation(p_session_id)` et refus si
`peut_entrer = false` ; (4) **seulement alors** la dérivation des capacités selon le tableau G §1.5 ;
(5) `ttl_seconds = least(token_ttl_seconds, restant_secondes)`.

**Erreur de localisation à ne pas propager.** A §1.4 attribue deux occurrences de
`interval '10 minutes'` à `autoriser_jeton_video()`, dont « `0010:561` ». Les frontières de fonction
de `0010_video_jeton_presence.sql` sont : `autoriser_jeton_video` 261→378, `etat_presence` 493→601.
La ligne 561 tombe donc dans **`etat_presence`**. Il y a **trois sites vivants**, pas deux :
`0010:306` (`autoriser_jeton_video`), `0010:561` (`etat_presence`) et
`lib/core/video/pre_vol.dart:22` (`seuilOuvertureSalle = Duration(minutes: 10)`), qu'aucun agent ne
mentionne. **Ne pas toucher `0007:232`** : c'est le corps d'une fonction remplacée par `0010:493` ; le
modifier ne change rien et brouille l'historique. **Interdire tout `sed` global** sur le répertoire
des migrations.

**Et faire le bornage dans le MÊME lot.** Sans lui, le passage à T-20 fait basculer un élève à
`presente` vingt minutes avant le cours et affiche « en salle depuis 38 min » pour un cours commencé
il y a 18. Écrire `greatest(entre_le, started_at)` dans `etat_presence()` et, côté Dart, promouvoir
`dureeAcademique` de Q dans `lib/core/tc_horloge/duree_academique.dart` (§ 5, vague 7).

**Le plafond de participants : la conclusion d'A s'inverse.** A écrit qu'un observateur ferait
déborder le plafond. Or `0012:77-79` exempte déjà `guardian_observer` et `masked_controller`, et
`0012:93-96` ne compte que `teacher` et `student` ; surtout, tout le bloc de comptage est sous
`if not allow_multi then`, et `0017:432` passe `allow_multi_participant_sessions` à `true`. **Le
plafond de 7 n'est donc jamais évalué.** Retirer le point d'attention d'A ; conserver G §1.4 point 1,
qui reste nécessaire pour les deux nouvelles valeurs **si** le drapeau repassait à `false`. Et
signaler à l'opérateur le fait réellement découvert : **depuis `0017`, plus aucun garde-fou serveur
ne borne le nombre de participants d'une séance** ; seul `seuil_max` (`0017:28`, `check between 1 and 6`)
borne l'adhésion au groupe. Décider si c'est voulu **avant** d'ouvrir l'observation à trois rôles
supplémentaires.

### 4.9 Hors SQL — 2 seaux Storage

`storage.buckets` contient `kyc` et `avatars` uniquement. À créer : **`photos_enseignants`**
(A §1.8) et **`supports`** (B §1.6).

### 4.10 Onze doublons entre demandes — onze tickets, pas vingt-deux

| # | Doublon | Demandeurs | Résolution |
|---|---|---|---|
| 1 | Palette de teintes | A §1.6, B §4, D §9 | **Un seul lot de jetons**, trois accesseurs sur la même table (§ 9.2). |
| 2 | Bornage de la durée académique | A §1.11 (SQL + Dart), Q §3 (`dureeAcademique` **déjà écrite et testée**) | Déplacer la fonction de Q vers `lib/core/tc_horloge/`, la faire consommer par `VuePresence.depuis`, et écrire le `greatest` **dans la même migration** que `join_window_minutes`. |
| 3 | `MessagePedagogique` | D §2 (double local), E §4.1 (`typedef`), F §2.1 (forme canonique) | Inscrire la forme de **F** au contrat. D n'a rien à changer : son double coïncide au caractère près. E branche son `typedef`. |
| 4 | Position de reprise par groupe | H §1.5, F §3.2 | La colonne existe déjà chez F. Retirer l'option (b) de H ; n'écrire que la RPC de lecture (§ 4.8). |
| 5 | Quota vérifié avant le jeton | G §1.5, Q §4.2 | Un ticket (§ 4.8, palier 7). |
| 6 | Fermeture serveur des intervalles d'observation | G §1.7, Q §4.3 | Un ticket (arbitrage 14). |
| 7 | Photo enseignant | A §1.8 (colonnes), Q §1 (`EtatPhotoEnseignant`, **deux** valeurs jamais trois) | Un ticket. |
| 8 | Capacités d'observateur | G §2.1, Q §2 | Un ticket. **Confronter `CapacitesObservateur` ligne à ligne au tableau G §1.5 AVANT d'écrire le patch d'`autoriser_jeton_video`** — c'est précisément ce à quoi Q dit qu'il sert. Ce n'est jamais une barrière : la vérité reste le jeton signé. |
| 9 | `redirection.dart` + plafond de `nav_shell.dart` | A §5, B §6, C §7, E §5.2, G §4 | **Un** lot de routage (§ 8) + **un** arbitrage produit (§ 3.1 n° 1). |
| 10 | Les deux règles de sécurité (`agent_ro`, masquage colonne par colonne) | A à H, verbatim | Les écrire **une** fois, en en-tête de chaque migration. |
| 11 | Stockage local durable | B §3.1 (`RessourcesHorsLigne`), D §4 (`preference_locale`) | **Une** migration Drift 1→2 pour les deux, sans `shared_preferences`. Profiter du passage pour trancher le sort de `PagesMushafConsultees`, morte depuis sa création (§ 10, point 6), et mettre à jour le commentaire normatif d'`app_database.dart:119` (« exactement quatre tables »). |

### 4.11 Palier 5 bis — le fichier de test de Q

`supabase/tests/scenarios_tc_pii.sql` (Q §4.1), étendant `scenarios_n4.sql` déjà en place, pour
prouver qu'aucune vue lisible par l'enseignant ne rend `profiles.last_name`, `households`, `wallets`
ni `payouts`. **C'est un fichier de test, jamais une migration.**

---

## 5. Suppression des stubs — 28 fichiers de `lib/` et 9 doubles de Q

Inventaire mesuré : **A 4, C 3, D 4, E 6, F 3, H 8 = 28**. B, G et Q n'ont aucun répertoire
`ports_externes`, conformément à leur ownership. Les chemins canoniques annoncés en en-tête existent
tous sur disque.

### 5.0 Trois règles avant de commencer

**Règle 1 — la suppression est atomique par TYPE, jamais par fichier.** 121 lignes d'import hors
`ports_externes` pointent sur les stubs (A 3, C 12, D 37, E 15, F 12, H 42 ; dont **51 dans `test/`** :
D 17, H 18, C 6, F 6, E 4), et parmi elles se trouvent des fichiers **canoniques de contrat** que Z
doit conserver :

```
d\lib\core\tc_outils\learning_assignment.dart:4        import 'ports_externes/content_range.dart';
d\lib\core\tc_outils\annotation_layer.dart:4-5         content_position / content_range
d\lib\core\tc_outils\port_dock_hote.dart:4-7           4 imports de stubs
e\lib\core\tc_classe\teacher_student_projection.dart:3-4   content_position / learning_assignment
f\lib\core\tc_etat_partage\shared_content_state.dart:3-5   content_position / content_range / marqueur_semantique
h\lib\core\tc_parcours\port_travail_a_venir.dart:9-12      4 imports de stubs
h\lib\core\tc_parcours\port_post_cours.dart:12-18          7 imports de stubs
```

En Dart, `tc_outils/ports_externes/content_range.dart#ContentRange` et
`tc_bibliotheque/content_range.dart#ContentRange` sont **deux types distincts**, même à déclaration
identique. Procédure par type X : (1) supprimer **toutes** les copies de X d'un coup ; (2) réécrire
**dans le même commit** les imports des fichiers canoniques ci-dessus ; (3) `flutter analyze` vert
**avant** de passer au type suivant. `flutter analyze` après chaque **vague**, pas après chaque
fichier.

**Règle 2 — deux en-têtes `// TC-STUB-PORT:` mentent.** Ils désignent un fichier canonique qui existe
mais qui **ne déclare pas** le type stubé : le contrôle d'existence du chemin passe au vert, l'import
ne résoudrait rien.

| Stub | En-tête annonce | Vrai canonique |
|---|---|---|
| `a\...\intention_pedagogique.dart:1` | `tc_outils/annotation_layer.dart` | `tc_outils/intention_pedagogique.dart:19` (unique consommateur d'A : `group_home_vm.dart:5`) |
| `c\...\marqueur_semantique.dart:1` | `tc_outils/annotation_layer.dart` seul | `annotation_layer.dart:202` (`MarqueurSemantique`) **+** `intention_pedagogique.dart:19` (`IntentionPedagogique`) — le stub déclare **deux** types ; Agent F, lui, a bien cité les deux chemins |

**Règle 3 — douze stubs demandent DEUX imports là où ils n'en annoncent qu'un**, et celui d'A pour le
catalogue en demande **quatre**. C'est la seule difficulté réelle de cette phase. Agent C a par
ailleurs fusionné `ContentPosition` **et** `ContentRange` dans un fichier unique nommé
`content_position.dart` : il n'existe pas de `content_range.dart` chez C.

### Vague 1 — types d'Agent B (B ne consomme rien)

| # | Stub à supprimer | Remplacé par |
|---|---|---|
| 1 | `a\lib\core\tc_groupe\ports_externes\content_position.dart` | `lib/core/tc_bibliotheque/content_position.dart` — **divergent, voir § 1.1** |
| 2 | `c\lib\core\tc_coran\ports_externes\content_position.dart` | `content_position.dart` **+** `content_range.dart` (fichier fusionné) |
| 3 | `d\lib\core\tc_outils\ports_externes\content_position.dart` | `content_position.dart` |
| 4 | `e\lib\core\tc_classe\ports_externes\content_position.dart` | `content_position.dart` |
| 5 | `f\lib\core\tc_etat_partage\ports_externes\content_position.dart` | `content_position.dart` |
| 6 | `h\lib\core\tc_parcours\ports_externes\content_position.dart` | `content_position.dart` |
| 7 | `d\lib\core\tc_outils\ports_externes\content_range.dart` | `lib/core/tc_bibliotheque/content_range.dart` |
| 8 | `e\lib\core\tc_classe\ports_externes\content_range.dart` | `content_range.dart` |
| 9 | `f\lib\core\tc_etat_partage\ports_externes\content_range.dart` | `content_range.dart` |
| 10 | `h\lib\core\tc_parcours\ports_externes\content_range.dart` | `content_range.dart` |
| 11 | `d\lib\core\tc_outils\ports_externes\library_resource.dart` | `lib/core/tc_bibliotheque/library_resource.dart` — le stub de D ne déclare **aucun** `LibraryResource` malgré son nom : il ne porte que `CapaciteRessource`, nu. Le canonique est un sur-ensemble strict : suppression sans retouche du code de D. |
| 12 | `a\lib\core\tc_groupe\ports_externes\port_catalogue.dart` | **quatre** fichiers : `tc_bibliotheque/port_catalogue.dart` + `tc_bibliotheque/library_resource.dart` + `tc_telechargement/port_etat_offline.dart` (`EtatOffline`) + `tc_bibliotheque/donnees_catalogue.dart` (le provider) — **collision de provider, voir § 1.3** |

### Vague 2 — types d'Agent D

| # | Stub | Remplacé par |
|---|---|---|
| 13 | `a\...\ports_externes\intention_pedagogique.dart` | `lib/core/tc_outils/intention_pedagogique.dart` — **en-tête faux, règle 2** |
| 14 | `h\...\ports_externes\intention_pedagogique.dart` | idem |
| 15 | `c\...\ports_externes\marqueur_semantique.dart` | `tc_outils/annotation_layer.dart` **+** `tc_outils/intention_pedagogique.dart` — **en-tête incomplet, règle 2** |
| 16 | `f\...\ports_externes\marqueur_semantique.dart` | idem (F cite déjà les deux) |
| 17 | `e\...\ports_externes\learning_assignment.dart` | `tc_outils/learning_assignment.dart` **+** `tc_outils/intention_pedagogique.dart` |
| 18 | `h\...\ports_externes\learning_assignment.dart` | `tc_outils/learning_assignment.dart` |
| 19 | `h\...\ports_externes\port_assignations.dart` | `tc_outils/port_assignations.dart` — **provider levant, voir § 1.2** |

### Vague 3 — types d'Agent F

| # | Stub | Remplacé par |
|---|---|---|
| 20 | `c\...\ports_externes\port_etat_partage.dart` | `tc_etat_partage/port_etat_partage.dart` **+** `tc_etat_partage/shared_content_state.dart` |
| 21 | `d\...\ports_externes\port_realtime_pedagogique.dart` | `tc_realtime/port_realtime_pedagogique.dart` **+** `tc_etat_partage/shared_content_state.dart` |

Attention sur 20 : le canonique de F est **non const** et porte deux assertions (`revision >= 0`,
`updatedAtUtc.isUtc`), précédées du commentaire « Pas `const`, et ce n'est pas un oubli ». Vérifié :
C n'appelle jamais `const SharedContentState(...)` et ses usages passent `DateTime.utc(...)`. Ne pas
réintroduire `const`.

### Vague 4 — types d'Agent A

| # | Stub | Remplacé par |
|---|---|---|
| 22 | `e\...\ports_externes\session_clock_vm.dart` | `tc_horloge/session_clock_vm.dart` **seul** : `PhaseSeance` arrive par le re-export `export 'fenetre_seance.dart' show FenetreSeance, PhaseSeance;`. **Ne pas importer `fenetre_seance.dart`.** |
| 23 | `e\...\ports_externes\titre_enseignant.dart` | `tc_groupe/group_summary_vm.dart` (vérifié identique) |
| 24 | `h\...\ports_externes\slot_action.dart` | `tc_groupe/group_home_vm.dart` (vérifié identique, y compris le défaut `disponibleHorsLigne = false`) |

### Vague 5 — types d'Agent E

| # | Stub | Remplacé par |
|---|---|---|
| 25 | `h\...\ports_externes\teacher_student_projection.dart` | `tc_classe/teacher_student_projection.dart` |
| 26 | `h\...\ports_externes\port_roster_enseignant.dart` | `tc_classe/port_roster_enseignant.dart` |

Ces deux-là s'écartent de l'AMENDEMENT 2, qui nomme précisément le cas de H et conseille de ne pas
stuber une chaîne de types ouverte. L'écart est **sans danger et documenté en tête de fichier** : la
copie est rigoureusement fidèle (enum `EtatPresenceProjete` à neuf valeurs avec `valeurSql`,
`ResumeSeance`, `AssiduiteRecente`, les treize champs de `TeacherStudentProjection`,
`MotifEchecRoster`/`EchecRoster`). H le justifie : `PostCoursVM`, contrat qu'il produit lui-même,
porte `List<TeacherStudentProjection>`. **Traiter le lot H comme READY sur ce point.** Rappel du § 2,
note 2 : la substitution a lieu au rang 8 (E), et les tests de H sont rejoués **à ce moment-là**.

### Vague 6 — port croisé de G

| # | Stub | Remplacé par |
|---|---|---|
| 27 | `e\...\ports_externes\port_annonce_observation.dart` | `tc_observation/port_annonce_observation.dart` |

**Attention au modificateur de classe.** G publie `abstract interface class` (`:43`), E stube
`abstract class` (`:36`). Le modificateur de G **est le bon choix et doit être conservé** ; seul
`implements` sera légal. Vérifié : aucune classe d'E n'étend ni n'implémente ce port aujourd'hui
(`grep extends\s+Port[A-Za-z]+` sur les 321 fichiers → aucun résultat), E n'en consomme que la classe
de données `AnnonceObservation`, identique des deux côtés. Faire pointer `entete_classe.dart` et
`classe_live_page.dart` sur le canonique. Si un faux de test apparaît, l'écrire avec `implements`,
**jamais** `extends`.

G déclare également ses trois ports en `abstract interface class` quand les 33 autres déclarations du
chantier emploient `abstract class`. Ce n'est pas un défaut à corriger ; c'est un écart de
modificateur qui passe sous le radar d'une comparaison champ par champ, et qui doit être connu.

### Vague 7 — le port de H, puis les 9 doubles de Q, en dernier

| # | Stub | Remplacé par |
|---|---|---|
| 28 | `a\...\ports_externes\port_travail_a_venir.dart` | `tc_parcours/port_travail_a_venir.dart`, **après** avoir rendu le provider de H nullable (§ 1.2) |

`D:\RA_TC\q\test\teaching_core\fixtures\contrats\` porte **9 fichiers** : `content_position.dart`,
`content_range.dart`, `contrats_a_groupe.dart`, `contrats_a_horloge.dart`,
`contrats_b_ressources.dart`, `contrats_d_outils.dart`, `contrats_e_classe.dart`,
`contrats_f_etat_partage.dart`, `contrats_g_observation.dart`.

Ils portent l'en-tête `// TC-DOUBLE-CONTRAT:` et **non** `// TC-STUB-PORT:` : un grep d'intégration
sur le seul marqueur `TC-STUB-PORT` les manquerait tous les neuf. Chercher
`Select-String -Pattern 'TC-STUB-PORT|TC-DOUBLE-CONTRAT'`.

Les traiter **dans la même vague que les stubs** : sinon Q compilera contre ses propres copies pendant
que `lib/` compile contre les canoniques, et Dart verra deux jeux de types incompatibles bien
qu'identiques à l'œil. Qualité mesurée, et elle est bonne : les copies de Q sont identiques aux
canoniques de B aux commentaires près. Seul écart : `contrats_f_etat_partage.dart:15` déclare
`enum ModeAffichagePartage { page, verse, focus }` sans `valeurSql` — il disparaît avec le fichier.

Au même moment, **déplacer les trois helpers de Q vers leurs chemins canoniques, tels quels, sans les
réécrire** : `EtatPhotoEnseignant` + `etatPhoto(EnseignantVM)` → `lib/core/tc_groupe/group_summary_vm.dart` ;
`CapacitesObservateur` + `capacitesDe(RoleObservateur)` → `lib/core/tc_observation/capacites_observateur.dart` ;
`dureeAcademique({entreLe, debutSeance, maintenant, finSeance})` → `lib/core/tc_horloge/duree_academique.dart`.
Cette dernière est **pure et déjà couverte** par une suite complète ; elle est le pendant Dart exact
du bornage SQL `greatest(entre_le, started_at)`. Vérifier ensuite que les **quatre tests dormants**
de Q mordent : sinon ses chemins canoniques pointent à côté.

**Et ne pas éditer `lib/core/presence/vue_presence.dart` en phase parallèle** — Q l'interdit
explicitement, le fichier est consommé par quatre écrans existants.

### 5.1 Ce qui est prouvé identique — à supprimer sans relecture ligne à ligne

Diff mécanique (commentaires et lignes vides retirés) de chaque stub contre le canonique de son
producteur : `ContentPosition` est **identique** chez C, D, E, F et H ; `ContentRange` est identique
dans ses cinq copies ; `TeacherStudentProjection`, `PortRosterEnseignant`, `TitreEnseignant`,
`SlotAction`, `LearningAssignment` (H), `MarqueurSemantique` + `IntentionPedagogique` (F) sont
conformes au mot près. **L'AMENDEMENT 1 a été correctement appliqué par C, D, E, F et H.**
Concentrer l'effort de revue sur A.

### 5.2 Ce qui reste appauvri après la vague 1 — les enums sans `valeurSql`

`CONTRACTS` §0 rend `valeurSql` et `depuisSql(String?)` obligatoires pour **tout** enum de contrat
(« Jamais de repli silencieux »). Onze enums ont été recopiés nus. Ce sont des sous-ensembles, donc
le code compilera après bascule ; le risque réel est qu'un agent ait écrit sa sérialisation autour
d'un enum sans `valeurSql`, en se rabattant sur `.name` ou `.index`. **C'est arrivé une fois** — voir
§ 5.3.

Après la bascule, exécuter sur l'arbre fusionné :

```
rg -n '(TypeAncrage|IntentionPedagogique|ModeAffichagePartage|TypeRessource|CapaciteRessource|PolitiqueAcces|PolitiqueOffline|EtatOffline)[a-zA-Z]*\.(name|index)\b' lib/
```

et remplacer chaque occurrence par `.valeurSql`, chaque lecture inverse par `depuisSql(...)`.
**Vérifier spécifiquement A, C et D**, seuls à avoir perdu ces membres.

### 5.3 Un défaut de sérialisation actif, à corriger dans la même passe

`d\lib\core\tc_outils\evenements_outils.dart:308` écrit
`'type_ancrage': position.typeAncrage.name`, alors que F, l'autre bout du **même canal realtime**,
écrit et relit cette clé par `.valeurSql` / `depuisSql`
(`f\lib\core\tc_etat_partage\codec_etat_partage.dart:31` et `:45-46`).

Les deux encodages coïncident **aujourd'hui**, parce que les quatre valeurs de `TypeAncrage` ont une
`valeurSql` égale à leur nom Dart. C'est une coïncidence, pas un contrat. Le jour où une `valeurSql`
s'en écarte, les annotations émises par le Teaching Dock cesseront **silencieusement** d'être
décodées : `depuisSql` rendra `null` sans erreur, conformément à la règle « jamais de repli
silencieux », et le marqueur disparaîtra sans trace.

C'est d'autant plus une étourderie que les **six autres** sérialisations du même fichier
(`:72`, `:73`, `:105`, `:110`, `:111`, `:208`) emploient correctement `.valeurSql`. Remplacer `:308`,
contrôler `_plageJson` juste en dessous, et **ajouter un test contractuel côté Q** qui fait transiter
une `ContentPosition` de chaque `TypeAncrage` de l'encodeur de D vers le décodeur de F, pour que la
coïncidence cesse d'être tacite. C'est le seul site de sérialisation par `.name` trouvé sur les types
stubés, tous worktrees confondus.

### 5.4 Trois pertes d'égalité structurelle à surveiller après bascule

`c\...\marqueur_semantique.dart` s'arrête sans `operator ==`, `a\...\content_position.dart` de même,
et `d\...\port_realtime_pedagogique.dart` déclare `CapacitesPedagogiques` sans `==`/`hashCode`. Le
sens du changement est favorable — on **gagne** l'égalité structurelle — mais un `Set`, une `Map` ou
un `identical()` qui reposait sur l'identité change de comportement. Rejouer
`test/teaching_core/a/`, `.../c/` et `.../d/` en surveillant les tests qui comptent des éléments dans
un `Set` : un doublon jusqu'ici distinct peut désormais fusionner.

Deux divergences de constness, toutes deux **latentes** (aucun site de `lib/` ne construit les types
concernés) : le stub d'A déclare `const ReprisLecture({...})` là où B est délibérément **non const**
(l'assertion `vueLeUtc.isUtc` lit un getter d'instance), et le stub de C déclare
`const SharedContentState({...})` là où F ne l'est pas. Elles disparaissent avec les stubs.
**Ne pas réintroduire `const`** : dans les deux cas le producteur a renoncé au `const` pour conserver
une assertion d'invariant, et c'est le bon arbitrage.

### 5.5 Les câblages de slot à poser APRÈS la suppression des stubs

Ce ne sont pas des défauts : ce sont les ports consommés « par slot » au titre de l'AMENDEMENT 2, tous
documentés sur place, **sans une ligne de code qui les appelle aujourd'hui**. Ne stuber aucun d'eux :
les brancher directement.

- `GroupHomeVM.roster` ← `PortRosterEnseignant` (E). `SlotRoster` ne porte que `groupeId` et
  `sessionId` : c'est exactement le cas décrit par l'AMENDEMENT 2, soulevé par A lui-même.
- `e\lib\features\tc_classe_live\slots_tc_classe.dart:14,17` ← `ClassLibraryPicker` (B),
  `PortDockHote` (D), `PortRealtimePedagogique` (F) — références en commentaire seulement.
- `e\lib\core\tc_classe\rappel_discret.dart:8,123` ← `PortRealtimePedagogique.emettreCible` (F).
  **Aujourd'hui l'action est cadencée mais n'émet rien.**
- `vue_budget_observation.dart` (G) ← `SessionClockVM` (A) : l'ownership le déclare consommé, le code
  ne l'utilise pas. **Vérifier que G ne recalcule pas une durée localement**, ce qui contredirait
  l'invariant « un compte à rebours Dart est un affichage, la borne est serveur ».

Deux **non-consommations de fait**, à ne pas traiter comme des oublis à combler : D n'utilise jamais
`PortNavigationCoran` (il a construit son propre `ancrage_annotation.dart`), et F n'utilise jamais
`LibraryResource` (il transporte `resourceId` en `String`, chaîne de types close).

**Deux collisions de nom de classe à traiter au moment du câblage** (mesure : 352 déclarations
distinctes hors `ports_externes` sur les huit lots de production, dont **2** déclarées par deux lots) :

| Nom | Hôte (coquille) | Réel (implémentation) | Conséquence |
|---|---|---|---|
| `BlocAvantProchainCours` | `a\...\emplacements_groupe.dart:40` (`StatelessWidget`) | `h\...\bloc_avant_prochain_cours.dart:29` (`ConsumerWidget`) | `ambiguous_import` dès qu'un fichier importe les deux sans préfixe |
| `SurfaceBibliotheque` | `e\...\slots_tc_classe.dart:114` (`StatelessWidget`) | `b\...\surface_bibliotheque.dart:49` (`ConsumerStatefulWidget`) | idem |

Remède recommandé : renommer les deux **hôtes** (`EmplacementAvantProchainCours`,
`EmplacementBibliothequeEnClasse`), jamais les implémentations réelles.

### 5.6 Contrôle de sortie de la phase

Les six répertoires `ports_externes` doivent être **vides et supprimés** à la fin. Leur présence
résiduelle signale un type oublié.

---

## 6. Dépendances `pubspec.yaml`

Mesuré : **aucune des neuf branches ne touche `pubspec.yaml` ni `pubspec.lock`.** Toutes les demandes
sont restées des demandes ; Agent Z est le seul à pouvoir les satisfaire.

| Dépendance | Demandeur | Recommandation |
|---|---|---|
| **`pdfrx` ^1.x** | B §2.1 — « aucune composition à partir de l'existant ne peut afficher une page de PDF » | **À mesurer avant de décider, pas à estimer.** L'ajouter sur une branche jetable, lancer le build web, comparer la taille du **bundle servi** au budget de 20 Mo de `docs/produit/bibliotheque-contenu.md`, vérifier la licence de PDFium, et surtout contrôler que `flutter pub get` ne rétrograde **ni `path_provider_android` ni `jni`**. **Si l'un des deux bouge : refuser.** Motif écrit dans le dépôt (`pubspec.yaml:57-66`) : `sentry_flutter` est gelé en 8.x parce que 9.x force `path_provider_android` à une version antérieure, « qui porte le répertoire du cache Drift, donc le mode hors ligne, qui est un invariant produit ». Or le mode hors ligne est précisément l'invariant d'Agent B. Le précédent du `pubspec` n'est pas un précédent de poids, c'est un précédent de casse. |
| Repli si `pdfrx` est refusé | B | **Déjà livré et honnête** : « L'aperçu de ce format n'est pas encore disponible dans l'application. Vous pouvez en enregistrer une copie. » — et « Enregistrer une copie » fonctionne avec `file_picker 12.2.0`, déjà au `pubspec`. |
| `timezone` ^0.10.0 + `intl` ^0.20.0 | A §2, **uniquement si** l'option cliente de A §1.9 est retenue | **Refuser**, en retenant l'option serveur (arbitrage 7). Deux arguments : A donne lui-même le contre-argument (« le produit n'a qu'une langue rédigée et slang fait déjà le travail »), et `pdfrx` et `timezone` se disputent le même budget de bundle — `timezone` n'a pas d'utilisateur tant que la Bibliothèque hors ligne n'existe pas. |
| `syncfusion_flutter_pdfviewer` | pesée et écartée par B | **Refuser** : licence commerciale. |
| `pdfx` | pesée et écartée par B | **Refuser** : seconde chaîne de rendu web par PDF.js. |
| `shared_preferences` | évoquée par D §4, **que D refuse lui-même** | **Refuser** : la migration Drift 1→2 (doublon 11) couvre le besoin. |
| Jeu de polices QCF (604 fichiers) | C §2.3 | **Refuser pour ce lot**, C le recommande lui-même. Voir aussi § 3.3 n° 21. |
| C, D, E, F, G, H, Q | — | **Aucune demande**, chacun listant ce qui a été essayé avant de conclure. |

---

## 7. Fusion i18n

Les neuf fichiers `docs/teaching-core/i18n/tc_i18n_*.json` sont du **JSON valide** (`ConvertFrom-Json`
réussit sur les neuf), **UTF-8 sans BOM** (vérifié au niveau octet — le mojibake visible via
`Get-Content` en PowerShell 5.1 est un artefact de lecture, pas un défaut des fichiers), et leurs
sous-arbres sont **strictement disjoints**.

| Fichier | Clés de premier niveau | Sous-arbre | Taille |
|---|---|---|---|
| `tc_i18n_A.json` | `_meta, fr, ar` | `fr.tc.groupe` **et** `ar.tc.groupe` | 5 159 o |
| `tc_i18n_B.json` | `_commentaire, tc` | `tc.bibliotheque` | 3 157 o |
| `tc_i18n_C.json` | `_lisez_moi, tc` | `tc.coran` | 2 902 o |
| `tc_i18n_D.json` | `_comment, tc` | `tc.outils` | 2 371 o |
| `tc_i18n_E.json` | `_lisezMoi, tc` | `tc.classe` | 5 824 o |
| `tc_i18n_F.json` | `tc` | `tc.realtime` | 399 o |
| `tc_i18n_G.json` | `tc` | `tc.observation` | 3 802 o |
| `tc_i18n_H.json` | `tc` | `tc.parcours` | 3 957 o |
| `tc_i18n_Q.json` | `_note, _pour_agent_z, tc` | **vide** | 802 o |

**Huit sous-arbres, deux à deux disjoints.** `tc.classe.observation` (E) et `tc.observation` (G) sont
deux sous-arbres distincts, comme `tc.coran.focus` (C) et `tc.outils.focus` (D) : aucun libellé ne
sera perdu par chevauchement. Conforme à D-03. Le fichier de F à 399 o est conforme et non un oubli :
la matrice annonce pour F « probablement vide, protocole sans UI », et il ne porte que deux messages
d'échec. Cible vérifiée : `assets/i18n/fr.i18n.json` porte 33 racines et **aucune** ne s'appelle
`tc` ; `ar.i18n.json` ne porte que la racine `eleve`. `slang.yaml` : `base_locale fr`,
`fallback_strategy base_locale`, `flat_map true`, namespaces **non** activés (conforme à D-27).

**Quatre règles pour le script de fusion.**

1. **Ne pas écrire un merge uniforme sur neuf fichiers.** Agent A est le seul à porter `fr` et `ar` au
   premier niveau. Un script qui itère la racine et cherche `tc` produirait `tc.fr`/`tc.ar` pour A, ou
   sauterait A entièrement : les libellés de l'Espace Groupe disparaîtraient **silencieusement**, et
   avec eux les deux seules valeurs arabes du chantier. Écrire le fusionneur en **deux passes** : si
   le fichier porte une racine `fr` ou `ar`, prendre `fichier.fr.tc` et `fichier.ar.tc` ; sinon
   prendre `fichier.tc`. Verser le bloc `fr` dans `assets/i18n/fr.i18n.json` sous une racine `tc`
   neuve, et le bloc `ar` d'A dans `assets/i18n/ar.i18n.json` sous la même racine — ce sont les titres
   سيد / سيدة de la décision D-02, **seule traduction arabe autorisée du chantier**. Un fusionneur qui
   lirait uniquement `.tc` perdrait tout le lot A ; un fusionneur qui lirait uniquement `.fr.tc`
   perdrait les huit autres.
2. **Retirer toute clé commençant par `_` à n'importe quelle profondeur**, pas seulement à la racine.
   Sept clés de métadonnées vivent à la racine de six fichiers, mais Agent E en a placé trois **à
   l'intérieur** de son sous-arbre : `tc.classe.entete.titreEnseignant._note`, `tc.classe.rappel._note`
   et `tc.classe.attente._note`. slang ne sait pas que ce sont des commentaires : il les générerait
   comme des libellés dans `strings.g.dart`. **Consigner ces trois valeurs dans le rapport de fusion
   avant de les jeter** : ce sont des notes de conception, qui ont leur place dans le code Dart d'E.
3. **Exclure `tc_i18n_Q.json` de la boucle et le supprimer** (`git rm` après le merge de `q-qa`). Son
   `tc` est vide, le fusionner serait un no-op. Ne pas le compter comme violation d'ownership ; c'est
   une ambiguïté documentaire entre `FILE_OWNERSHIP` (« sous-arbre i18n : aucun ») et
   `PROTECTED_FILES` §4.2 (qui le nomme), et Q l'a **déclarée** au lieu de la taire.
4. **Deux canaris après `dart run slang` et `dart run build_runner build --delete-conflicting-outputs`** :
   `tc.groupe.carte.capacitePhrase` doit exister dans `fr.i18n.json` (preuve qu'A n'a pas été sauté),
   et `tc.groupe.enseignant.sayyid` doit exister dans **les deux** locales (preuve que la greffe arabe
   a tenu). Vérifier aussi qu'il y a exactement **huit** sous-arbres sous `tc`.

**Les huit façades `// TC-I18N:` ne se trouvent pas par glob de chemin.** `PROTECTED_FILES` §4.3
impose `lib/core/tc_<domaine>/libelles_tc_<agent>.dart`, mais les fichiers livrés sont à huit
emplacements et sous deux conventions de nom :

```
A  lib/core/tc_groupe/libelles_tc_groupe.dart
B  lib/features/tc_catalogue/libelles_tc_b.dart      <- sous features/
C  lib/features/tc_mushaf/libelles_tc_c.dart         <- sous features/
D  lib/core/tc_outils/libelles_tc_outils.dart
E  lib/core/tc_classe/libelles_tc_classe.dart
F  lib/core/tc_realtime/libelles_tc_realtime.dart
G  lib/core/tc_observation/libelles_tc_g.dart
H  lib/core/tc_parcours/libelles_tc_parcours.dart
```

Chaque fichier reste dans le périmètre de son propriétaire — ce n'est pas une violation d'ownership —
mais un glob sur `lib/core/tc_*/libelles_tc_*.dart` **raterait B et C**. Recenser par le marqueur,
fiable partout : `grep -rn "// TC-I18N:" lib/`. Chaque occurrence donne la clé `tc.<domaine>.<écran>.<élément>`
exacte à substituer. **Ne supprimer les huit fichiers qu'une fois les substitutions faites et
`flutter analyze` vert.**

**Trois vocabulaires dupliqués à promouvoir après fusion**, sinon ils divergeront le jour où un mot
change :

| Contenu | Présent chez | À promouvoir en |
|---|---|---|
| Sayyid / Sayyida (D-02, vocabulaire fermé) | `tc.groupe.enseignant.*` (A) **et** `tc.classe.entete.titreEnseignant.*` (E) | `tc.commun.titre.*` |
| Photo manquante (D-01, état normatif) | `tc.groupe.enseignant.photoManquante` (A) **et** `tc.classe.entete.photoManquante` (E) | `tc.commun.enseignant.photoManquante` |
| Les cinq intentions pédagogiques | `tc.outils.intention.aApprendre\|aRevoir\|…` (D) **et** `tc.parcours.intention.apprendre\|revoir\|…` (H) — **noms de clé différents pour le même vocabulaire**, ce qui masque la duplication | `tc.commun.intention.*` |

D §3.3 impose d'ailleurs explicitement le vocabulaire commun : « le même vocabulaire que les
marqueurs, jamais un second ».

---

## 8. Routes — le lot de branchement

### 8.1 Ce qui est livré, et qui ne se recoupe pas

Mesuré sur les dix worktrees : **un seul `GoRouter(` par worktree**, toujours
`lib/core/router/app_router.dart:80`, fichier protégé **intact** dans les neuf diffs. Aucun second
routeur n'a été construit dans `lib/`.

| Fonction | Fichier | Chemins déclarés |
|---|---|---|
| `routesTcA({RoleEspaceGroupe role = RoleEspaceGroupe.eleve})` | `a\lib\features\tc_mes_groupes\routes_tc_a.dart:26` | `/tc/groupes` + segment `:groupeId` |
| `routesTcB({String? groupeId})` | `b\lib\features\tc_catalogue\routes_tc_b.dart:40` | `/tc/bibliotheque`, `/tc/bibliotheque/:resourceId` |
| `routesTcC()` | `c\lib\features\tc_mushaf\routes_tc_c.dart:24` | `/tc/mushaf` |
| `routesTcE()` | `e\lib\features\tc_classe_live\routes_tc_e.dart:34` | `/tc/classe` |
| `routesTcG()` | `g\lib\features\tc_observation_ui\routes_tc_g.dart:37` | `/tc/observation/:seanceId` |

**Sept chemins, deux à deux distincts ; cinq segments distincts, aucune collision de préfixe.** D, F,
H et Q ne livrent aucune fonction de routes, et c'est conforme : D s'insère par `PortDockHote`, F est
un protocole sans interface, H remplit des slots, Q ne produit aucune interface.

### 8.2 Ce qu'Agent Z fait

1. Appeler les cinq fonctions depuis `app_router.dart`.
2. **Promouvoir les constantes** de `CheminsTcA`, `RoutesTcB`, `routes_tc_c`, `routes_tc_e` et
   `RoutesTcG` dans `lib/core/router/routes.dart`.
3. Uniformiser les deux signatures paramétrées : dériver `RoleEspaceGroupe` de la session applicative
   (A §5) et passer `groupeId` à `routesTcB` depuis l'Espace Groupe.
4. **Ne pas oublier `redirection.dart`.** C'est le point que **sept agents nomment indépendamment** et
   qu'aucun ne peut traiter. Mécanisme vérifié : `redirection.dart:106-107` —
   `final String prefixe = Routes.prefixePour(role); return _dansLeSousArbre(cheminDemande, prefixe) ? null : racine;`.
   Le préfixe `/tc/` n'appartient à aucun rôle : **posés tels quels, les sept chemins sont
   inatteignables**, quelle que soit la qualité des écrans. Autoriser le préfixe rôle par rôle :

| Chemin | Rôles à autoriser |
|---|---|
| `/tc/groupes`, `/tc/groupes/:groupeId` | `student`, `guardian` |
| `/tc/bibliotheque`, `/tc/bibliotheque/:resourceId` | `student`, `guardian` |
| `/tc/classe` | `teacher`, `student` |
| `/tc/mushaf` | `student` |
| `/tc/observation/:seanceId` | `guardian`, `admin`, `controller` (G §4) |

5. **Ne pas prendre `q\test\teaching_core\q\support\hote_navigation.dart` pour une table de routes.**
   Il déclare `/tc/groupes`, `/tc/accueil`, `/tc/bibliotheque`, `/tc/classe` ; `/tc/accueil` n'existe
   dans **aucun** lot, et les trois autres y sont des doubles locaux. Le fichier porte sa propre
   justification en tête : il vit sous `test/`, hors de la règle CI qui refuse un second `GoRouter`
   dans `lib/`.

### 8.3 L'arbitrage que le branchement ne remplace pas

`nav_shell.dart:284` pose `maxDestinations = 4` et deux assertions interdisent la cinquième. Les
quatre destinations de l'enseignant sont prises. Ouvrir une entrée de navigation Teaching Core est
donc un **arbitrage produit** (§ 3.1 n° 1), pas un patch. Les trois issues proposées par les agents
sont compatibles entre elles et couvrent la Bibliothèque, le Coran et la Classe Live. **Seul « Mes
groupes » (A) reste sans solution.**

---

## 9. Icônes et jetons de design

### 9.1 Vingt icônes, aucune demandée deux fois

| Demandeur | Icônes |
|---|---|
| A (1) | `tabletteOuOrdinateur` (placeholder `AppIcons.appareil`) |
| B (4) | `fichierPdf` (`AppIcons.dossiers`), `texteStructure` (`AppIcons.cahier`), `image` (`AppIcons.qr`), `lecon` (`AppIcons.pedagogie`) |
| D (10) | `bibliotheque`, `focus`, `marqueur`, `masquer`, `stylet`, `surligneur`, `pointeur`, `annuler`, `poigneeDock`, `revision` |
| G (5) | `observation-incognito`, `administration-visible`, `heritage`, `personnalisation-groupe`, `observation-fermee` |
| C, E, F, H, Q | **aucune**, chacun avec sa raison écrite |

À faire en **un seul passage** sur `lib/core/icons/app_icons.dart` — fichier qu'aucun agent n'édite —
en normalisant les cinq noms de G, écrits en kebab-case et impossibles en identifiant Dart :
`observationIncognito`, `administrationVisible`, `heritage`, `personnalisationGroupe`,
`observationFermee`. Puis supprimer les commentaires `// TC-ICONE:` et leurs placeholders.

**Se fier au tableau de D, pas à son chiffre** : son texte annonce « huit icônes manquent », son
propre tableau en liste **dix**. Un intégrateur qui se fie à la phrase en livrerait deux de moins que
le code n'en attend.

**Traiter en priorité les deux collisions de placeholder**, qui deviennent ambiguës dès que les
surfaces se côtoient : `AppIcons.pedagogie` sert à la fois `marqueur` et `surligneur` chez D, et
`AppIcons.cameraCoupee` sert `masquer` (D) **et** `observation-fermee` (G). Les livrer ensemble ou pas
du tout.

Source exhaustive et mécanique à extraire : `grep -rn 'TC-ICONE:' lib/`.

### 9.2 Un seul lot de jetons, trois accesseurs

A et B demandent la **même** palette de 32 à 40 teintes accessibles sous deux noms différents et pour
la même raison ; D signale un troisième besoin, plus petit. Un seul lot ferme les trois.

La cible D-18 est de **32 à 40 paires**. L'existant en fournit **quatre**, dont trois portent déjà un
sens dans le produit. A écrit lui-même : « un huitième de la cible, deux groupes sur cinq partagent
leur teinte — c'est un défaut assumé, pas une solution ». B réutilise les mêmes quatre pour les
couvertures.

À faire : poser **une seule liste de 32 à 40 `AppColorPair`** dans `lib/core/theme/app_palette.dart`
— seul fichier du dépôt autorisé à poser une couleur littérale, et READ-ONLY pour les agents ; le type
existe déjà (`app_color_pair.dart:13`) — et exposer **trois accesseurs qui indexent la même table**
plutôt que trois listes : `teinteGroupe(int)` (A §1.6), `teinteCouverture(int)` (B §4),
`paireDe(TonEtat)` (D §9, trois lignes, qui retire le détour `AppInkColor.asBorderSide().color`).

Contraintes **non négociables**, sans quoi trente-deux teintes en valent douze : contraste vérifié en
clair **et** en sombre, et distinguabilité pour les trois formes courantes de dyschromatopsie. Ne
réutiliser **aucune** paire porteuse de sens (`washAccent`, `washSuccess`, `washWarning`) comme teinte
d'identité — « employer `washWarning` comme couleur d'identité ferait lire une anomalie là où il n'y a
qu'un groupe ». Rappel D-18 : la couleur n'est **jamais** le seul identifiant du groupe, et le liseré
doit rester `ExcludeSemantics`.

Côté client, un seul fichier bouge chez chaque demandeur : `CouvertureRessource.nombreTeintes` et
`VignetteRessource.teinte` chez B, `palette_groupe.dart` chez A.

Vérifier ensuite par `dart run tool/verifier_jetons.dart` qu'aucune couleur nue n'a fui — en sachant
que cet outil est **déjà rouge** sur la baseline (§ 10, point 1).

---

## 10. Défauts préexistants du dépôt, découverts en chemin

Quatorze au total, dont deux déjà clos par la mesure. **Ouvrir un ticket « dette baseline » séparé du
chantier Teaching Core.** Quatre seulement ont un effet direct sur l'intégration et doivent passer
avant ; **ne corriger aucun des autres** dans le lot d'intégration.

| # | Défaut | Effet | Quand |
|---|---|---|---|
| 1 | `dart run tool/verifier_jetons.dart` **rouge sur la baseline `0071557`**, 10 violations : `nav_shell.dart` (1 `IconButton`, 1 `onTap:` nu, 3 M-dash), `menu_filtre.dart` (2 M-dash), `sous_navigation_domaine.dart` (1 `onTap:` nu), `dossiers_page.dart` et `journal_page.dart` (1 M-dash chacun). Rapporté **indépendamment et à l'identique par sept agents**. `flutter analyze` est propre : ce sont des règles maison. | Le contrôle de jetons du § 9.2 partira de rouge. | **Avec les 20 icônes** : les deux touchent `nav_shell.dart` |
| 2 | `catalogue_galerie_test` **rouge**, ce qui interdit tout composant nouveau dans `lib/core/widgets/`. Mesuré de l'extérieur par F : `flutter test` sur tout le dépôt rend **`+931 -1`**, l'unique échec étant « La galerie est la preuve du catalogue ». | **Bloque E §5.1** (promotion de la galerie vidéo) — par un test, pas par une décision. | **Avant le merge** : réparer, ou refuser E §5.1 |
| 3 | `lesson_reports_teacher_write` (`0001:1064-1069`) ne vérifie que `author_profile_id = auth.uid()` et **pas** que `session_id` appartient à l'enseignant : un enseignant peut déposer un cahier sur la séance d'un autre. H écrit dans cette table et hérite du défaut. | Sécurité. | **Avant** d'écrire la policy de `student_concern` (§ 4.7, table 13) — H demande nommément de ne pas calquer |
| 4 | `pg_trgm` **absente du projet** (vérifié : `installed_version` nul) | Prérequis de C §5. | **Avant le merge** (§ 4.2) |
| 5 | `session_participants.entered_at` / `exited_at` ne sont **jamais écrites** — deux occurrences dans tout le dépôt, leurs déclarations | Données mortes. | Ticket dette |
| 6 | Table Drift `PagesMushafConsultees` déclarée et générée mais **morte** : aucune lecture ni écriture hors `app_database.g.dart` | idem | **Avec la migration Drift 1→2** (doublon 11) : la supprimer ou inscrire pourquoi elle reste |
| 7 | `CacheMediaFichiers` tient ses clés dans un `Set` en mémoire : une ressource « Téléchargée » repasse à « À télécharger » au lancement suivant | Recouvre le doublon 11 | Ticket dette |
| 8 | `assister_seance()` (`0012`) ne journalise rien et ne consulte aucun quota : **le tuteur entre aujourd'hui sans budget et sans trace** | Sécurité / conformité. | À connaître avant le § 4.8 |
| 9 | `lib/features/presence_correction/` : l'écran existe, l'adaptateur manque, la page n'est enregistrée dans **aucune** route | Interface orpheline. | Ticket dette |
| 10 | `session_state.dart` câble `peutVoirDirection` **en dur à `false`** parce que ni `AppRole` (plat, 6 valeurs) ni le JWT ne portent de permission plus fine | **Aucune capacité Teaching Core qui ne serait pas un rôle entier n'a de support aujourd'hui.** | À lire **avant** de concevoir les capacités d'observation (§ 4.8) |
| 11 | `GroupeAdmin.depuisJson` recode `fuseau: 'Europe/Paris'` en dur (`service_groupes.dart:69`) parce que `groupes_admin()` (`0019:241`) ne rend pas la colonne | Recouvre la demande A « `groupes_admin()` élargie ». | Ticket dette |
| 12 | `ContenuPresente` est ordonné par **horodatage d'émission** dans `LiveKitSessionProvider._recevoirDonnees` : un client dont l'horloge avance peut faire ignorer les paquets d'un autre | Relevé par F. | Ticket dette, à connaître avant de généraliser le canal |
| 13 | **Licences manquantes** pour `UthmanTahaNaskh-Regular.otf` et `NotoSansArabic-Variable.ttf` | Juridique. | **Tout de suite** (§ 3.3 n° 21) |
| 14 | `verset.ligne` vaut NULL sur les **6236** versets | Alimente l'arbitrage produit n° 4. | Arbitrage |
| — | ~~`0029` / `dossiers_en_attente` accordée à `anon`~~ | **CLOS** : `0029` est appliquée, `anon` n'y figure plus (mesuré). Publier un addendum d'une ligne au `BASELINE_ADDENDUM.md`, n'écrire aucun correctif. | Clos le 20/09 |
| — | ~~Migrations `0020`-`0024` non appliquées~~ | **CLOS** : elles sont appliquées (mesuré). Corriger l'en-tête de `0025`, qui affirme le contraire et a déjà induit un audit en erreur. | Clos le 20/09 |

**Bruit de génération, jamais une modification d'agent** : `flutter analyze` et `flutter pub get`
réécrivent `windows/flutter/generated_plugin_registrant.cc`, `generated_plugin_registrant.h` et
`generated_plugins.cmake`. Vérifié : `git diff 0071557 HEAD -- windows/` rend **rien** sur les neuf
branches. Ne jamais les compter, ne jamais les committer. Exécuter `git checkout -- windows/` dans
chaque worktree avant la PHASE 1, pour qu'ils ne soient pas emportés par inadvertance dans
`integration/teaching-core`.

---

## 11. Signatures de contrat à verser au canonique

Quatre surfaces sont **nommées** dans `TEACHING_CORE_CONTRACTS.md` sans y être décrites, et trois
agents ont dû écrire des doubles locaux pour compiler. Bonne nouvelle mesurée : deux doubles sont
déjà identiques au caractère près, il n'y a rien à arbitrer.

**Verser au contrat, sans rien réécrire :**

- `MessagePedagogique` et `CanalFiabilite` à la forme publiée par **F §2.1**
  (`lib/core/tc_realtime/port_realtime_pedagogique.dart`). D et F sont déjà alignés, vérifié ligne à
  ligne ; E refuse d'en écrire un troisième et réduit son besoin à un `typedef TransportRappel`.
- `PortEtatPartagePersistant`, `MotifEchecEtatPartage` et `EchecEtatPartage` à la forme de **F §2.2**.
- `PortDockHote` et `ContexteDock` à la forme de **D §6** (réclamée par E §4.2).
- `ModeEntreeAdmin` à la forme de **G §2.1** (`lib/core/tc_observation/mode_entree_admin.dart`).

**Entériner quatre amendements que leurs propriétaires ont déjà implémentés :**

- `PortRappelDiscret.cooldownRestant` (E §2) — aucun autre consommateur, sans effet de bord.
- `SessionEnCours.horloge` rendu **nullable** (E §3) — sans quoi la barre « Cours en cours »
  disparaît pendant qu'un cours tourne ; `CoursOuvert` peut alors être supprimé.
- `PortPostCours.enregistrer` rendant `SortPostCours { envoye, enFile }` (H §2.2).
- `PortAssignations.aVenir({required String groupId, String? studentId, int limite = 3})` (H §2.1).
  **Corollaire SQL** : changer l'index de `learning_assignment` de `(group_id, status, due_at)` en
  `(group_id, student_id, status, due_at)`, sinon le filtre par élève fait un scan.

**Demander enfin à B de publier la signature de `ClassLibraryPicker`**, en rappelant la contrainte que
E §4.3 souligne : la surface s'ouvre **dans** la Classe Live, en panneau ou en feuille ; elle ne
navigue pas, la room reste connectée (D-20).

**Quatre demandes portent sur des fichiers PROTECTED et n'appartiennent qu'à Agent Z.** Elles ne sont
pas du SQL et se perdraient dans une consolidation qui ne regarde que les migrations. **Les traiter
comme un lot à part, AVANT le SQL** : elles sont purement additives et ne dépendent d'aucune
migration.

- **F §1** (bloquant, « sans elle, rien n'est émis en production ») : ajouter `publierDonnees`,
  `donneesRecues`, `accesCourant`, `PaquetDonnees` et `EchecPublicationDonnees` à
  `lib/core/video/video_session_provider.dart`, et relayer **tout** sujet dans `_recevoirDonnees` de
  `lib/core/video/livekit_session_provider.dart`. F corrige au passage la cartographie officielle :
  contrairement à `TEACHING_CORE_BASELINE.md` §6.7, **un premier canal de données existe déjà** depuis
  `0071557` — la demande n'est donc pas « ajoutez un canal » mais « généralisez celui qui existe ».
  **Ne pas oublier `await _donnees.close();` dans `liberer()`**, à côté des quatre `close()` existants :
  c'est le genre de ligne qu'un relecteur ne cherche pas. **Conserver `presenterContenu` et
  `contenusPresentes` tels quels** : F a écrit un test qui vérifie qu'aucun paquet du protocole
  pédagogique ne part par la primitive coranique du socle. Deux protocoles, deux sujets, aucune
  lecture croisée.
- **C §4** : `debutDeJuz(int)` et `rechercher(String, {int limite})` sur
  `lib/core/coran/service_coran.dart`. Double local assumé en attendant (`DebutsDeJuz.table`, qui
  duplique `public.juz` et disparaît le jour où `debutDeJuz` existe).
- **G §1.4 point 6** : compléter `RoleSalle.depuis()` dans `lib/features/salle/vue_salle.dart`, sans
  quoi l'administrateur tombe sur `RoleSalle.inconnu`, donc une salle en lecture seule.
- **B §3** : deux méthodes sur `CacheMedia` (qui ne porte aujourd'hui que `retirer(String)` et
  `clesConservees()`). B a déjà préparé la sortie : son `DepotOctetsLocal` **hérite** de `CacheMedia`
  et ajoute exactement `deposer(String, List<int>)` et `obtenir(String)` ; le jour où ces deux
  méthodes rejoignent le contrat, `CacheMediaFichiers` satisfait le port sans une ligne de changement
  et le port disparaît.

---

## 12. Ordre d'exécution récapitulatif

| Étape | Contenu | Bloquant pour |
|---|---|---|
| **0** | **Remise au vert du lot A** (§ 1), re-contrôle, réémission du rapport pré-merge **sans aucun BLOCKED** | tout |
| 1 | Arbitrages du paquet PRODUIT (§ 3.1) et licences des deux polices (§ 3.3 n° 21) | contrats partagés |
| 2 | `TARGET_SHA` connu, `integration/teaching-core` créée depuis lui, PHASE 2 vérifiée (321 ajouts, 0 modification, 0 intersection) | tout |
| 3 | Lot PROTECTED (§ 11), purement additif et sans dépendance SQL | F, C, G, B |
| 4 | Contrats partagés : suppression des 28 stubs + 9 doubles par vagues (§ 5), signatures versées au canonique (§ 11), jetons + 20 icônes (§ 9), fusion i18n (§ 7), `pubspec` tranché (§ 6) | rang 2 |
| 5 | Migrations `0030` → `0033` dans l'ordre (§ 4), `pg_trgm`, 2 seaux Storage, migration Drift 1→2 | les écrans qui lisent la base |
| 6 | Merges dans l'ordre **B, C, A, H, D, F, E, G, Q** (§ 2), avec `flutter analyze` + tests après chaque | — |
| 7 | Branchement des routes et de `redirection.dart` (§ 8), câblage des slots et des deux collisions de nom (§ 5.5) | PHASE 5 |
| 8 | PHASE 5 end-to-end, puis ticket « dette baseline » (§ 10) | — |
