# SOCLE — Catalogue d'écrans, ADR, péremption

Rapport du **socle partagé** du lot Enseignant, volet documentaire.
Écrit le **20 septembre 2026**, sur `BASELINE_SHA = 550e6059654843274e5039e203ad296c565a08b6`,
branche `main`.

Ce volet ne produit **aucun code Dart**. Il produit la documentation que la
constitution du dépôt rend **bloquante** : `CLAUDE.md` ligne 74 interdit
d'implémenter un écran absent du catalogue, et cinq agents métier attendaient
cinq fiches.

---

## 1. Ce qui a été écrit

### 1.1 Cinq fiches d'écran — `docs/design/08-catalogue-ecrans.md`

Les cinq fiches sont regroupées dans une **section 7 nouvelle**, « Fiches du lot
Enseignant (20 septembre 2026) », plutôt que dispersées dans la section 6. La
raison est écrite en tête de la section : les fiches de la section 6 ont été
remplies **à partir du code existant**, ce qui servait de relecture ; celles-ci
sont écrites **avant** le code, et elles le commandent. Mélanger les deux
laisserait croire que ces cinq écrans existent.

| Code | Nom | Route | Nature |
| :--- | :--- | :--- | :--- |
| `ENS-01` | Onboarding et bienvenue | `/enseignant/bienvenue` + les cinq surfaces `/connexion`, `/attente`, `/attente/accuse`, `/attente/contrat`, `/attente/piece` | fiche neuve, code déjà nommé |
| `ENS-04` | Cahier de transmission | `/enseignant/seance/:seanceId/cahier` | fiche neuve, code déjà au registre |
| `ENS-05` | Profil enseignant | `/enseignant/profil` | fiche neuve, code déjà au registre |
| `ENS-07` | Fiche groupe | `/enseignant/groupe/:groupeId` | **code nouveau** |
| `ENS-08` | Revue de groupe | `/enseignant/groupe/:groupeId/revue` | **code nouveau** |

Format repris à l'identique de la section 3 et des fiches `ENS-02` et `ENS-06` :
bloc encadré sans accents, prose avec accents en dessous. Chaque fiche porte les
cinq états obligatoires, et `ENS-04` en porte un sixième (`déjà déposé`) parce
que la règle « sortie de salle implique cahier » le rend atteignable.

### 1.2 Registre — section 1 du même fichier

- **ajoutées** : `ENS-01` (zone Accès), `ENS-07` (zone Journée et salle),
  `ENS-08` (zone Contenu et transmission) ;
- **corrigées** : `ENS-04` (sa route réelle `/enseignant/seance/:seanceId/cahier`
  remplace « depuis la salle », son état passe de « à construire, étape 6 » à
  « à construire, lot Enseignant (Agent C), fiche §6 ») ; `ENS-05` (report
  ADR-003 levé par ADR-027, fiche §6, talon signalé) ; `ENS-02`, `ENS-03`,
  `ENS-06` portent désormais « **en reprise, lot Enseignant** » avec leur agent,
  sans être déclarés faits ;
- **paragraphe « Codes nouveaux »** : un second paragraphe nomme `ENS-07` et
  `ENS-08`, dit pourquoi les deux codes étaient libres, et rattache leur
  existence au pivot du 19 septembre 2026 ;
- **note sur `ENS-05`** : sa ligne reste rangée en zone Administration, par
  héritage du registre d'origine. La ligne n'est **pas déplacée** — un code
  d'écran qui change de place dans un tableau laisse six documents citant
  l'ancienne — et sa fiche déclare sa zone réelle.

### 1.3 Section 2 — le compte d'écrans, et sa méthode

Deux corrections, la seconde plus importante que la première.

**La méthode de comptage ne marche plus.** La section 2 disait « le compte se lit
dans `lib/core/router/app_router.dart`, jamais en parcourant les écrans ». Mesuré
le 20 septembre 2026 : il n'y reste **qu'un seul** `EcranAConstruire`, ligne 91,
et c'est celui que la section nommait déjà comme l'état de chargement de la
racine. La phrase « Onze écrans sont encore `EcranAConstruire` » est donc fausse
et a été réécrite. La méthode est désormais la colonne **État** du registre.

**Le compte juste après ce lot** : **six écrans à construire dans le MVP-0**
(`ENS-01` bienvenue, `ENS-04`, `ENS-05`, `ENS-07`, `ENS-08`, suivi élève), plus
`CPT-01` hors MVP-0. Le compte est passé de deux à six **parce que le catalogue a
rattrapé le produit**, pas parce que le produit a reculé : quatre de ces écrans
étaient déjà dus sans aucune fiche pour les décrire.

### 1.4 Deux ADR — `docs/architecture/decisions.md`

**Numéros pris : ADR-026 et ADR-027.** Le dernier ADR du fichier était ADR-025 ;
les deux numéros suivants étaient libres.

| Numéro | Titre | Objet |
| :--- | :--- | :--- |
| **ADR-026** | Le contenu présenté voyage par le canal de données LiveKit, jamais par une table | transport du pointeur pédagogique ; ferme la question `e` de `etape-5-salle-coran-presence.md` §10 |
| **ADR-027** | Le profil enseignant se construit sans la paie, et reprend l'accès aux paramètres personnels | levée du report d'ADR-003 sur `ENS-05` ; barre à trois destinations |

Chaque ADR suit le format des trois que j'ai relus avant d'écrire (ADR-021,
ADR-022, ADR-025) : titre `## ADR-0XX - …`, décision datée, sous-sections `###`,
« ce qui reste ouvert », « comment défaire », séparateur `---`.

**Cinq lignes ajoutées au registre unique des questions ouvertes** (31 à 35), en
suivant la règle que le tableau s'impose lui-même (« Toute nouvelle décision
prise en cours de développement s'ajoute à ce même tableau »). Les lignes 31 et
32 consignent les deux ADR ; les lignes 33, 34 et 35 consignent trois écarts
mesurés en écrivant les fiches, détaillés en section 3 de ce rapport.

### 1.5 Encadré de péremption — `docs/parallel-reports/00-baseline.md`

Encadré ajouté **en tête**, avant le titre d'origine. Il nomme la date de
péremption (20 septembre 2026), la date d'écriture du document (14 septembre
2026), la matrice qui fait loi (`docs/architecture/TEACHER_FILE_OWNERSHIP.md`,
complétée par `TEACHER_PARALLEL_BASELINE.md`), la règle d'arbitrage en cas de
contradiction, et **les quatre points précis qui sont faux** : la propriété de
`app_router.dart`, de l'i18n, de `ligne_presence.dart` et du catalogue d'écrans ;
la réservation des migrations `0014` à `0016` alors que le dépôt est à `0025` ;
le commit de base `cbc4ff8` remplacé par `550e605` ; le modèle à cinq worktrees
remplacé par un arbre unique à propriété exclusive.

**Aucun contenu n'a été supprimé.** Le document reste la seule trace écrite de
l'état des worktrees au 14 septembre, et son encadré dit de le lire comme un
relevé daté.

---

## 2. `git worktree list` — et la seconde implémentation de `ENS-05`

Commande lancée depuis `D:\RA _APP\RA -OFFICIAL-APP`. Sortie exacte :

```
D:/RA _APP/RA -OFFICIAL-APP                                                          550e605 [main]
C:/Users/dell/.gemini/antigravity/worktrees/RA -OFFICIAL-APP/starlit-surge-glides-04h50  9d0229b [starlit-surge-glides-04h50]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-login                   1110400 [codex/login-demo]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-presence-ui              d55606c [codex/presence-correction-ui]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-prod-release              b02ea98 [codex/production-google-auth-20260916]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-r1                       405683a [codex/r1-adaptive-design-system]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-r2                        65c564f [codex/r2-adaptive-shell]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-review-20260915           b02ea98 [codex/review-visible-20260915]
C:/Users/dell/AppData/Local/Programs/WindowsTerminal/rewayah-vague5-integration        f8a6988 [codex/vague5-integration]
C:/Users/dell/AppData/Local/Temp/claude/.../scratchpad/baseline                        e104605 (detached HEAD)
D:/ra-pwa-build                                                                       e76a14e (detached HEAD)
D:/ra-pwa-ctr                                                                         f1855de (detached HEAD)
D:/ra-pwa-deploy-20260918                                                             99c7b6a (detached HEAD)
D:/ra-pwa-fix                                                                         090ae6f (detached HEAD)
D:/ra-pwa-secure-deploy                                                               cbc4ff8 (detached HEAD)
```

Quinze worktrees. Cinq de plus que ce que `00-baseline.md` inventoriait le
14 septembre.

### 2.1 ⚠ OUI, une seconde implémentation de `ENS-05` existe — l'Agent E doit le lire avant d'écrire une ligne

`00-baseline.md` lignes 93 et 117 annonçait « le lot ENS-05 profil enseignant et
Compte/préférences **non commité** » dans `rewayah-r2`. **Vérifié, et ce constat
a changé** : ce n'est plus du non-suivi, c'est **commité sur une branche**.

| Fait | Mesure du 20 septembre 2026 |
| :--- | :--- |
| Le worktree existe | `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-r2` |
| Sa branche | `codex/r2-adaptive-shell`, HEAD `65c564f` |
| Le commit en cause | `65c564f feat: add read-only teacher profile screen` |
| Base de la branche | `cbc4ff8` (le commit du 14 septembre), **jamais fusionnée dans `main`** |
| Le fichier divergent | `lib/features/profil_enseignant/profil_enseignant_page.dart` : **185 lignes** sur la branche, **166 lignes** sur `main` |
| Écart mesuré | `git diff --stat main codex/r2-adaptive-shell` rend `299 ++++----` sur ce seul fichier |
| Fichier identique des deux côtés | `lib/core/profil/service_profil_enseignant.dart` (151 lignes) — il est **sur `main` aussi**, donc il n'est pas une divergence |

Deux chemins non suivis restent dans ce worktree, et ils **ne sont pas** des
nouveautés à récupérer : `lib/features/compte/compte_page.dart` (713 lignes,
contre **755** sur `main`) et `lib/core/preferences/preferences_locales.dart`
(94 lignes, `lib/core/preferences/` existe **aussi** sur `main`). Ce sont des
copies plus anciennes de fichiers que `main` porte déjà.

**Ce que l'Agent E doit en faire, et ce qu'il ne doit pas en faire.**

1. `ENS-05` a donc **trois états** dans ce dépôt : le talon de `main` (166 l.,
   un test de 18 lignes), la version de `codex/r2-adaptive-shell` (185 l.), et
   la fiche que je viens d'écrire. Écrire une quatrième version sans trancher
   les deux premières est le scénario que la carte de propriété existe pour
   empêcher.
2. La version `r2` est un **profil en lecture seule** (c'est le sujet de son
   commit) construit sur l'état du 14 septembre, donc **avant** le pivot
   groupes, avant le panneau admin à huit domaines, et avant la décision de
   retirer la destination « Compte ». Elle ne connaît ni ADR-027 ni la barre à
   trois destinations.
3. **Recommandation, à confirmer par l'Agent Z ou l'opérateur** : construire sur
   le talon de `main`, et **lire** `65c564f` comme matériau — pas le fusionner.
   Fusionner `codex/r2-adaptive-shell` ferait entrer avec lui une série R1/R2
   entière (`6e85aec`, `da34f9c`, `1fc15c6`) que `main` n'a jamais prise, et
   `00-baseline.md` avertissait déjà de ne pas fusionner les deux séries R1 en
   bloc.
4. Je n'ai **pas** supprimé ce worktree, ni cette branche, ni touché à leur
   contenu. Ce n'est pas mon périmètre, et une branche supprimée ne se relit
   plus.

### 2.2 Les autres worktrees, en une ligne

Aucun autre worktree ne porte d'implémentation d'un écran enseignant du lot. Les
détachés (`ra-pwa-*`) sont des états de build et de déploiement historiques ;
`rewayah-login`, `rewayah-presence-ui`, `rewayah-prod-release`,
`rewayah-review-20260915`, `rewayah-vague5-integration` et
`starlit-surge-glides-04h50` n'ont pas été inspectés fichier par fichier, et je
ne prétends donc pas qu'ils sont vides — seulement que je n'ai vérifié que
`ENS-05`, qui était la question posée.

---

## 3. Écarts mesurés, signalés et non corrigés

### 3.1 L'écart de compteur d'écrans (tâche 4) — pour l'Agent Z

| Source | Ce qu'elle dit | Fichier:ligne |
| :--- | :--- | :--- |
| `docs/design/README.md` | « dix-neuf écrans réels », trois fois | `README.md:112`, `:116`, `:117`, `:120` |
| le test | `expect(ecrans.length, 20)` **et** `expect(…toSet().length, 20)` | `test/accessibilite/rtl_echelle_texte_ecrans_test.dart:482-483` |

Je n'ai touché **ni** `README.md` (il n'est pas à moi) **ni** le test (aucun
fichier de `test/` ne m'est ouvert).

**Le compte juste, pour ce lot : 20 → 25.** Les cinq écrans de mes fiches doivent
entrer dans la liste du test, et **les cinq sont des ajouts** : j'ai relu les
vingt entrées actuelles (`TUT-00`, `ELV-01`, `TUT-00c`, `TUT-00b`, `TUT-00c/a`,
`TUT-00c/b`, `TUT-00c/c`, `TUT-01`, `TUT-02`, `TUT-02/a`, `TUT-02/b`, `TUT-04`,
`TUT-05`, `TUT-06`, `ENS-06`, `ELV-02`, `ENS-02`, `ADM-01`, `ADM-02`, `ADM-06`)
et **`ENS-05` n'y est pas**, bien que son talon soit branché. Donc 20 + 5 = **25**,
et les deux `expect` de la ligne 482 et de la ligne 483 changent tous les deux.

⚠ **Mais « écrans réels » est un abus de langage dans les deux sources, et c'est
le vrai écart.** Cette liste n'est pas l'ensemble des écrans construits : au
moins **dix-huit** écrans du registre qui existent bel et bien en sont absents —
`ADM-04`, `ADM-05`, `ADM-07` à `ADM-17`, `CTR-01`, la salle
(`ELV-03`/`ENS-03`/`CTR-02`), `ELV-04`, `AGT-00` et le suivi élève. Porter le
compteur à 25 satisfait l'obligation de **ce** lot ; cela ne rend pas la liste
complète, et écrire « les vingt-cinq écrans réels » dans `README.md` reproduirait
l'erreur avec un chiffre plus grand. La formulation juste est « vingt-cinq écrans
du catalogue montés en RTL et à 200 % ».

### 3.2 Un état de ligne du registre périmé, mesuré et laissé tel quel

La ligne « Suivi élève » porte « à construire », alors que
`lib/features/suivi_eleve/` existe et que `app_router.dart` lignes 198-200
branche `SuiviElevePage` sur `Routes.eleveSuivi`. **Je ne l'ai pas passée à
« construit »** : cet écran n'a aucune fiche dans le catalogue, donc au sens de
la constitution il n'est pas fini, et une route qui rend quelque chose n'est pas
une preuve. La ligne porte désormais un avertissement qui renvoie à la section 2,
et le fait y est écrit. La fiche est à écrire, hors du lot Enseignant.

### 3.3 Les migrations `0020` à `0024` ne sont pas appliquées — mesuré

Vérifié par le connecteur Supabase sur le projet `gggmtelinlpseweouyav` : la
dernière migration appliquée est **`groupes_durcissement`** du 19 septembre 2026,
c'est-à-dire `0019`. Les fichiers `0020_programme_pedagogique.sql`,
`0021_diagnostics_placement.sql`, `0022_progression_suivi.sql`,
`0023_evaluations.sql` et `0024_qualite_pedagogique.sql` sont **committés sur
`main` et non appliqués**.

C'est écrit dans la fiche `ENS-08` comme une limite assumée : l'écran est
complet, ses blocs restent vides jusqu'au push, et **il ne pose aucune colonne de
tirets en attendant**. Consigné en ligne 35 du registre des questions ouvertes.

### 3.4 Le vocabulaire des anomalies de `ENS-08` n'existe pas en base

Les quatre anomalies que le contrat du lot nomme — gate à venir, élève hors
corridor, proposition de transfert, proposition de réorientation — n'existent
**sous aucun de ces noms** dans les migrations `0020` à `0024` ni dans les
documents `ADMIN_*`. `grep -i 'corridor|gate|transfert|reorientation'` sur
`supabase/migrations/002*.sql` et `docs/architecture/ADMIN*.md` ne rend qu'un
faux positif.

Ce que la base sait produire : `anomalies_qualite()` avec trois types
(`rapport_manquant`, `blocage_sans_suivi`, `evaluation_en_retard`, table
`controles_qualite`, migration `0024`) et `progression_exceptions.type` à deux
valeurs (`blocage`, `derogation`, migration `0022`). De plus,
`anomalies_qualite()` est **réservée à `app_role() = 'admin'`**, et **aucune RPC
d'anomalies bornée à l'enseignant n'existe**.

La fiche `ENS-08` écrit l'écart plutôt que de le combler. Consigné en ligne 34 du
registre. **Deux issues, à trancher par le socle** : écrire une RPC d'anomalies
bornée à l'enseignant, ou remplacer les quatre noms par ceux que la base porte.

### 3.5 Le pivot groupes n'a toujours aucun ADR, et ADR-004 le contredit

`ADR-004` dit encore « groupes jusqu'à 6, `allow_multi_participant_sessions`
fermé par défaut, plafond à 2 imposé par trigger ». Le pivot du 19 septembre
(cinq enfants, six adultes, une seule visio commune) ne vit que dans la migration
`0017`, dans la fiche `ADM-09` et dans `TEACHER_PARALLEL_BASELINE.md` §2.1.
`etape-5-salle-coran-presence.md` dit encore que ses écrans de salle valent pour
le 1-à-1.

**Je n'ai pas écrit cet ADR** : il n'était pas dans ma mission, et il touche des
plafonds de sécurité et un trigger que je ne suis pas en position de trancher. Il
est consigné en ligne 33 du registre des questions ouvertes, avec la liste de ce
qu'il doit couvrir, et **le numéro libre suivant est ADR-028**.

### 3.6 Deux états de dossier que la base ne distingue pas (`ENS-01`)

La mission demandait de couvrir « correction demandée » et « expiré si
applicable ». Mesuré dans `lib/core/domain/enums.dart` :

- `EtapeDossier` vaut `incomplet`, `enVerification`, `refuse`, `suspendu`. **Il
  n'existe aucun état « correction demandée »** : un refus définitif et une
  demande de correction se disent aujourd'hui par le même `refuse`, avec le motif
  pour seule différence.
- **Aucun état « expiré » n'existe.** Le cas voisin est
  `AccountStatus.provisionalActive` avec `profiles.kyc_completion_deadline` :
  accès complet, profil à compléter sous 30 jours, et **aucune coupure
  automatique** (ADR-014). L'échéance s'affiche, elle ne bloque rien.

La fiche `ENS-01` écrit les deux constats comme des **questions ouvertes**,
nommément, plutôt que d'inventer deux états.

---

## 4. Ce que je n'ai pas fait, et ce que je n'ai pas vérifié

- **Aucun fichier `.dart`, aucun fichier dans `lib/`, `test/` ou `supabase/`.**
- **Aucune clé i18n** : ce volet n'écrit aucune chaîne visible, donc aucun
  `docs/parallel-reports/i18n_*.json` n'a été créé.
- `TEACHER_PARALLEL_BASELINE.md` et `TEACHER_FILE_OWNERSHIP.md` **n'ont pas été
  touchés** : ils sont le gel. Les demandes qu'ils contiennent sont dans ce
  rapport, pas dans leur texte.
- `docs/design/README.md` **n'a pas été touché** (§3.1).
- **Je n'ai lancé aucune commande `flutter`, `dart` ni `psql`.** Aucun chiffre de
  test, d'analyse ou de scénario de ce rapport n'est mesuré par moi : les
  références « 684 passent / 7 échouent » et « 0 problème d'analyse » viennent de
  `TEACHER_PARALLEL_BASELINE.md` §1 et de `docs/HANDOFF.md`. **Une documentation
  ne se vérifie pas par `dart analyze`** : les quatre fichiers que j'ai touchés
  sont du Markdown, et rien dans la chaîne de build ne les lit.
- Je n'ai **pas relu les 61 chapitres** de `00-bible-frontend-v2.md`, ni
  `01-systeme-visuel.md` à `07-catalogue-composants.md`. Les fiches s'appuient sur
  la section 3 du catalogue, sur les fiches `ENS-02`, `ENS-06`, `ELV-02`,
  `ELV-04`, `ADM-17`, sur `lib/CLAUDE.md` et sur le gel. Une contradiction avec
  un chapitre de la Bible que je n'ai pas lu reste possible.
- Je n'ai **pas inspecté** le contenu des worktrees autres que `rewayah-r2`, et
  seulement pour `ENS-05` (§2.2).
- Je n'ai **pas vérifié** que `mes_seances_enseignant_v` corrige effectivement la
  duplication par élève : j'ai lu que la vue est annoncée, pas son `group by`.
- Les fiches nomment des composants partagés (`PageShell`, `OfflineBanner`,
  `SettingRow`, `Skeleton`, `Pressable`, `AppBottomSheet`, `EmptyState`,
  `StatusPill`, `TimelineRow`) d'après les fiches existantes et
  `07-catalogue-composants.md` §2 — **je n'ai pas relu les 38 fichiers** de
  `lib/core/widgets/`. `TEACHER_DUPLICATES_AUDIT.md`, qui devait en être l'index,
  **n'existe pas sur le disque** alors que le gel le coche comme livré
  (`TEACHER_PARALLEL_BASELINE.md:327`).

---

## 5. Ce qui reste ouvert, par ordre de blocage

| # | Ce qui manque | Qui | Bloque |
| :-- | :--- | :--- | :--- |
| 1 | `docs/architecture/TEACHER_SHARED_CONTRACTS.md` **n'existe pas**, alors que le gel le coche livré (`:326`) et que §5 et §2.10 y renvoient pour les signatures exactes | Z | **les cinq agents** : aucune signature Dart gelée à consommer |
| 2 | `docs/architecture/TEACHER_DUPLICATES_AUDIT.md` **n'existe pas**, alors qu'il est coché livré (`:327`) et cité trois fois comme l'index des 38 composants | Z | l'invariant 10 (« aucun doublon de composant ») n'a aucun index à opposer |
| 3 | `deposer_cahier(uuid, text, jsonb)` n'est **pas** dans `0025_role_enseignant.sql` | Z | `ENS-04` : sans elle, la validation du cahier ne peut pas aboutir |
| 4 | Aucun service ni provider Riverpod enseignant : `lib/core/enseignant/` ne porte que des modèles de données | Z | A, B, C : rien à surcharger dans un test |
| 5 | Aucun faux de test pour les services enseignant dans `test/support/harnais.dart` | Z | A, B, C : aucun écran montable en test |
| 6 | Le compteur du test d'accessibilité : 20 → **25**, aux deux `expect` des lignes 482-483 | Z | §3.1 |
| 7 | `docs/design/README.md` : « dix-neuf écrans réels » → la formulation juste, pas un chiffre de plus | Z | §3.1 |
| 8 | Trancher `ENS-05` : talon de `main`, ou `65c564f` de `codex/r2-adaptive-shell` | Z / opérateur | **E, avant sa première ligne** (§2.1) |
| 9 | ADR du pivot groupes (**ADR-028**), et réconciliation avec ADR-004 | Z / opérateur | `ENS-03`, `ENS-07` : les plafonds se contredisent (§3.5) |
| 10 | Correspondance entre les quatre anomalies de `ENS-08` et ce que la base sait calculer | Z / opérateur | `ENS-08` (§3.4) |
| 11 | Décisions **D05** et **D06** (qui corrige une présence, motif, délai), encore `BLOCKED` | opérateur | `ENS-04` : le préremplissage de présence s'appuie sur une règle non tranchée |
| 12 | Confirmation opérateur de **D01**, que ADR-027 remplace par une décision d'agent | opérateur | `ENS-05` |
| 13 | Application des migrations `0020` à `0024` à la base | exploitation | `ENS-08` reste vide sans elles (§3.3) |
| 14 | Distinguer un refus définitif d'une demande de correction ; statuer sur un état « expiré » | opérateur | `ENS-01` (§3.6) |
| 15 | Fiche d'écran du **suivi élève**, construit sans fiche | hors lot Enseignant | §3.2 |

---

## 6. Fichiers touchés par ce volet, et rien d'autre

| Fichier | Nature |
| :--- | :--- |
| `docs/design/08-catalogue-ecrans.md` | modifié : registre §1, §2, section 7 nouvelle avec cinq fiches |
| `docs/architecture/decisions.md` | modifié : ADR-026, ADR-027, lignes 31 à 35 du registre des questions ouvertes |
| `docs/parallel-reports/00-baseline.md` | modifié : encadré de péremption en tête, aucun contenu supprimé |
| `docs/parallel-reports/SOCLE_CATALOGUE_REPORT.md` | créé : ce rapport |
