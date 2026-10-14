# AGENT_A_REPORT

**Agent A — l'expérience enseignant « Journée ».** Écrans `ENS-02` (Journée,
étendu) et `ENS-07` (Fiche groupe, neuf).

Écrit le 20 septembre 2026, après lecture de `TEACHER_SHARED_CONTRACTS.md`,
`TEACHER_FILE_OWNERSHIP.md`, `TEACHER_DUPLICATES_AUDIT.md`,
`TEACHER_PARALLEL_BASELINE.md`, `CLAUDE.md`, `lib/CLAUDE.md`, les fiches §6
(`ENS-02`) et §7 (`ENS-07`) du catalogue d'écrans, et l'audit de zone
« Journee Enseignant (ENS-02) et Planning / Prieres / Pre-vol ».

---

## 1. Fichiers touchés, liste exacte

| Fichier | Nature | Quoi |
| :--- | :--- | :--- |
| `lib/features/journee/journee_page.dart` | modifié | `ENS-02` réécrit sur `seancesEnseignantProvider` : préflight, alertes individuelles, rapports en attente, accès fiche groupe, dégradation hors ligne, un seul chemin de chargement |
| `lib/features/fiche_groupe/fiche_groupe_page.dart` | créé | `ENS-07`, la fiche groupe contextuelle |
| `test/features/journee_test.dart` | modifié | 28 cas de test, les huit états et les invariants |
| `test/features/fiche_groupe_test.dart` | créé | 15 cas de test |
| `docs/parallel-reports/i18n_A.json` | créé | 21 clés sous `enseignant.journee`, 15 sous `enseignant.ficheGroupe` |
| `docs/parallel-reports/CONTRACT_REQUEST_A.md` | créé | 10 demandes, dont l'état réel des migrations |
| `docs/parallel-reports/AGENT_A_REPORT.md` | créé | ce document |

**Aucun autre fichier n'a été touché.** Rien dans `lib/core/**`, rien dans
`assets/i18n/**`, rien dans `supabase/**`, rien dans `test/support/harnais.dart`,
aucune dépendance ajoutée, aucune commande `flutter`/`dart` lancée.

## 2. API publique exposée

| Fichier | Déclaration |
| :--- | :--- |
| `lib/features/journee/journee_page.dart` | `class JourneePage extends ConsumerWidget` / `const JourneePage({super.key})` |
| `lib/features/journee/journee_page.dart` | `const Duration seuilOuvertureSalle` (préexistant, conservé — voir `CONTRACT_REQUEST_A.md` §1) |
| `lib/features/fiche_groupe/fiche_groupe_page.dart` | `class FicheGroupePage extends ConsumerWidget` / `const FicheGroupePage({required this.groupeId, super.key})`, champ `final String groupeId;` |

`JourneePage` **était** un `ConsumerStatefulWidget` : le contrat de branchement
demande un `ConsumerWidget`, et c'est maintenant le cas. L'horloge d'une minute
(qui fait avancer le minuteur et ouvre la fenêtre de lancement toute seule) vit
dans un widget privé `_Cadence`. Tout le reste de chaque feature est privé.

## 3. Ce que `ENS-02` fait maintenant, et pourquoi

Ordre de priorité visuelle : **prochain cours, colonne, exceptions,
secondaire.**

1. **Le bloc dominant** est une carte posée (`BentoTile`), jamais un aplat : une
   seule zone pleine par écran, et elle appartient au bouton de lancement.
   « En direct » se dit par une `StatusPill` verte. La carte porte le **nom du
   groupe** et son **effectif** — `SeanceEnseignant` ne porte aucun prénom, par
   construction (ADR-008), et cinq prénoms avant un cours seraient cinq choses à
   lire. Les prénoms se lisent sur `ENS-07`, à un tap.
2. **Le préflight** se lit par `preVolProvider` (jamais `servicePreVolProvider`
   en impératif). Dans la fenêtre de dix minutes : « Micro prêt » puis le bouton.
   Préflight échoué : **pas de bouton**, la raison exacte — micro absent contre
   permission refusée, deux pannes, deux remèdes — et un « Réessayer » qui
   remesure vraiment le matériel.
3. **Hors ligne**, dans la fenêtre : pas de bouton non plus, une phrase. Une
   salle ne s'ouvre pas sans réseau, et un geste qui échoue après le tap coûte
   plus cher que son absence. `horsLigneProvider` est lu par `hasValue/value` :
   tant que la réponse est inconnue, l'appareil est réputé en ligne.
4. **Les alertes individuelles sont rares, et le mot est tenu par le code** :
   deux lignes au plus (`_maximumAlertes`), puis « et N autres élèves ». Elles
   ne sont lues que **pendant** le cours : avant l'heure, personne n'est attendu
   en salle. Seuls `absente` et `deconnectee` deviennent une alerte ; une
   présence indisponible (`null`) n'annonce **rien** — invariant J3, « je ne
   sais pas » n'est pas « absent ».
5. **Le cours annulé du jour** est annoncé par `seanceAnnuleeDuJour(...)`, qui
   existait pour `ELV-02`/`TUT-01` et que `ENS-02` n'appelait pas.
6. **La colonne** passe par `construireJournee(...)` et `TimelineRow` : cours,
   pauses et prières sont des entrées de même nature, dans une seule colonne
   (ADR-017). `pauseMaximale` vient de `valeurRegleProvider`, jamais d'une
   constante ; une règle illisible ne devient pas une valeur inventée.
7. **Les rapports en attente** viennent de `cahiersEnRetardProvider`. Chaque
   ligne est un `SignalRow` qui mène à `Routes.cahierPour(seanceId)`, avec son
   ancienneté ; au-delà de vingt-quatre heures, le ton passe en avertissement et
   la phrase parle de retard. La navigation est un `push` suivi d'un
   `ref.invalidate` au retour : c'est ce qui fait que **la ligne disparaît
   d'elle-même** une fois le cahier déposé.
8. **Le résumé de fin de journée** est une phrase sous la colonne, singulier ou
   pluriel, inchangé.
9. **Le secondaire** est un `StatTile` — le doublon relevé par l'audit
   (`BentoTile + Text` là où `StatTile` existe) est corrigé — sous un
   `SectionHeader` qui porte « Voir mes créneaux ». Le zéro s'affiche.
10. **L'accès contextuel au groupe** est une action tertiaire de la carte
    dominante, rendue seulement quand la séance a un groupe.

Ce que l'écran **ne fait pas**, volontairement : aucune destination « Présence »
ni « Rapports », aucune statistique qui ne mène nulle part, aucun objectif de
séance inventé, aucun prénom dans la colonne.

## 4. Les trois défauts de l'audit, traités

- **`seancesProvider` → `seancesEnseignantProvider`.** C'est le défaut central :
  `mes_seances_v` joint `session_participants` et rend une ligne par élève, donc
  cinq lignes de colonne pour un cours de cinq enfants. Mesuré par le test « une
  seance de groupe ne compte qu une ligne de colonne ».
- **Le double test de chargement est supprimé, pas réparé.** Le chemin mort
  (`journee_page.dart:169-173` dans l'ancienne version) n'existe plus ; il reste
  **un** test de première charge, qui couvre les cinq lectures, et c'est la forme
  du second squelette (tuile puis lignes de timeline) qui a été gardée, parce
  qu'un squelette ressemble à ce qui arrive.
- **L'état `error` partiel est comblé.** L'échec de `seancesEnseignantProvider`
  donne un `EmptyState` avec « Réessayer » ; l'échec d'une lecture secondaire
  (prières, pause, rapports, feed) ne s'avale plus en silence : une phrase le
  dit, parce qu'une pause illisible fait disparaître toutes les pauses.
- **Aucun troisième `_hhmm`** n'a été écrit, et `seuilOuvertureSalle` n'a pas
  été recopiée (elle n'est pas en `core` : voir `CONTRACT_REQUEST_A.md` §1).

## 5. `ENS-07` Fiche groupe

Une **pose**, pas une destination : elle s'ouvre depuis la Journée et porte un
chemin de sortie visible en tête de page, parce qu'elle vit hors de la coquille
de navigation. Contenu : le nom du groupe, son public, son rendez-vous
hebdomadaire (une seule visio commune depuis le pivot), les places libres sur le
seuil du groupe, ses membres, et l'accès à la revue courte (`ENS-08`).

Garanties tenues :

- **aucun nom de famille, courriel, téléphone ou adresse.** La fiche lit
  `membresGroupeEnseignantProvider` → `MembreSeance`, qui **n'a aucun champ de
  nom de famille**. `MembreGroupe` (`core/admin/service_groupes.dart`) n'est pas
  importé ;
- un prénom masqué (observation) laisse l'identifiant immuable nommer l'élève ;
- le `niveau` est annoncé « niveau indiqué », jamais « niveau du programme » :
  il vient de `student_profiles.level`, un texte libre. **Absent, il se tait**,
  aucune ligne « niveau : - » ;
- le seuil affiché est celui du groupe, jamais un chiffre calculé à l'écran, et
  « 0 place libre » se lit comme les autres valeurs ;
- aucune action de composition : c'est l'administration qui compose les groupes
  (`ADM-09`), et `groupe_membre_ajouter` est bornée à `app_role() = 'admin'`.
  Un état vide **subi**, sans bouton.

## 6. États réellement rendus

`ENS-02`, les huit demandés :

| État | Où il se voit |
| :--- | :--- |
| `loading` | `Skeleton.tuileBento` + `Skeleton.ligneTimeline`, un seul chemin |
| `content` | carte dominante, colonne, sections |
| `empty` | `EmptyState` registre **subi** « Aucun cours à venir » + « Rien de prévu aujourd'hui » et le prochain cours d'un autre jour |
| `error` | `EmptyState` + « Réessayer » qui relit vraiment ; phrase d'erreur partielle pour les lectures secondaires |
| `offline` | bandeau de `PageShell` (non dupliqué) **et** dégradation propre du lancement |
| préflight échoué | pas de bouton, raison distincte selon micro absent / permission refusée, « Réessayer » qui remesure |
| élève absent détecté | ligne d'alerte en registre doux sous la carte dominante, pendant le cours seulement, deux au plus |
| rapport en retard | `SignalRow` avec ancienneté et ton d'avertissement, menant au cahier |

Plus : cours en cours (pastille + « jusqu'à »), autre jour, journée finie, cours
annulé du jour, séance sans groupe.

`ENS-07` : `loading`, `content`, `empty` (groupe sans élève), `error`,
`offline` (bandeau du shell), plus **« ce groupe n'est pas le vôtre »**, qui
n'est pas une erreur de lecture : `mes_groupes_v` ne rend que ses groupes
actifs, et une absence est un groupe clôturé ou celui d'un collègue.

## 7. Tests écrits

`test/features/journee_test.dart` (28 cas). Ils mesurent des invariants, pas des
montages : une séance de groupe ne produit **qu'une** ligne de colonne ; le
bouton n'existe ni hors fenêtre, ni hors ligne, ni sans micro ; « Réessayer »
incrémente `verifications` du faux pré-vol et `lecturesSeances` du faux service ;
une présence `null` n'affiche **aucune** absence ; trois absents donnent deux
lignes et un compte ; le compteur compte les élèves et non les lignes du feed ;
la ligne de rapport atterrit sur `cahier:s9` et la carte sur `groupe:g1` ; à
390 × 844 et à 200 % d'échelle de texte, `takeException()` est nul.

`test/features/fiche_groupe_test.dart` (15 cas) : les cinq états plus
l'introuvable, le prénom masqué qui laisse l'identifiant nommer, l'absence de
niveau qui se tait, les places libres sur le seuil (dont le zéro et le
singulier), la sortie qui ramène à la journée, la revue qui s'ouvre, et les deux
mesures mobiles.

Aucun faux n'a été ajouté ni modifié : `FauxServiceEnseignant`,
`FauxServicePresence`, `FauxServicePreVol`, `FauxServiceReseau`,
`FauxServicePriere`, `FauxServiceRegles`, `FauxServiceMatching`,
`FausseSourceSession`, `seanceDeTest` et `membreDeTest` suffisaient.

**Ces tests n'ont pas été exécutés** : la consigne interdit `flutter test` aux
agents métier, la vérification est centralisée chez l'Agent Z.

## 8. Ce qui reste ouvert

1. **La route de `ENS-07` n'est pas branchée.** `Routes.groupePour` existe dans
   `routes.dart`, mais `app_router.dart` ne déclare aucune des quatre routes
   contextuelles : un tap sur « Voir le groupe » n'aboutira qu'après le
   branchement de l'Agent Z. C'est le plan (`BASELINE.md` §3.2), pas un oubli ;
   c'est aussi la condition pour que `ENS-07` **existe** vraiment.
2. **Les clés de `i18n_A.json` ne sont pas générées** : le code les emploie comme
   si elles existaient, l'analyse échouera jusqu'à la fusion et à `dart run
   slang` par l'Agent Z. C'est le protocole.
3. Le libellé bancal d'un cours **individuel** dans la colonne (« Cours avec
   Cours individuel ») tant que `EntreeJournee`/`TimelineRow` ignorent le
   groupe — `CONTRACT_REQUEST_A.md` §2.
4. Trois clés i18n deviennent orphelines (§8 du `CONTRACT_REQUEST`).
5. Pas de tirage-pour-rafraîchir : le seul chemin de relecture est le retour du
   cahier et le « Réessayer » des états d'erreur.
6. Le panneau de détail desktop de `ENS-02` reste non implémenté (dette reportée
   par la fiche §6) ; `ENS-07` a ses deux colonnes.
7. La fiche `ENS-02` du catalogue est en retard sur l'écran construit
   (`CONTRACT_REQUEST_A.md` §7) — `docs/design/` appartient à l'Agent Z.

## 9. Migrations : ce que j'ai vérifié en base

L'opérateur a demandé explicitement que la migration soit faite. **Vérification
avant toute écriture** (`get_project_url` → `gggmtelinlpseweouyav`, réflexe
imposé par la mémoire du projet) : `0025_role_enseignant` et
`0026_durcissement_execute_enseignant` **sont déjà appliquées**. Les sept objets
dont ce lot dépend existent (`mes_seances_enseignant_v`, `mes_groupes_v`,
`teacher_roster_v`, `mon_groupe_detail`, `brouillon_cahier`,
`mes_rapports_en_attente`, `sessions.groupe_id`), et les colonnes des deux vues
que je lis correspondent **exactement** aux `depuisJson` du socle.

**Il n'y avait donc rien à appliquer, et je n'ai écrit aucune migration.** Deux
constats sortis de cette vérification sont dans `CONTRACT_REQUEST_A.md` §10 :
`deposer_cahier(...)` n'existe pas en base (le socle écrit par `insert`), et les
migrations `0020` à `0024` ne sont **pas** appliquées.

## 10. Autoévaluation — ce qu'un relecteur doit vérifier d'abord

1. **`_versSeance` (journee_page.dart).** C'est la décision la plus discutable du
   lot : une `Seance` fabriquée dont `elevePrenom` porte un libellé de groupe.
   C'était le seul moyen d'employer `construireJournee` et `TimelineRow` — tous
   deux imposés, tous deux partagés et fermés — avec un modèle qui ne porte plus
   de prénom. Si le relecteur préfère attendre le contrat §2, l'alternative est
   une colonne locale, c'est-à-dire précisément ce que l'audit interdit.
2. **L'ordre des alertes.** Je les ai posées **avant** la colonne, alors que la
   consigne dit « exceptions » après. La raison est mesurable (à 390 de large,
   une absence sous la colonne se lit après le cours), mais c'est un écart.
3. **Les heures de `ENS-07`.** La fiche §7 impose « heures de l'appareil, sans
   mention de fuseau », or un créneau de groupe est stocké en `hour_local` +
   `timezone_iana` : ce qui est affiché est l'heure **du fuseau où le groupe a
   été posé**, pas celle de l'appareil. Pour un enseignant en déplacement, les
   deux diffèrent. J'ai suivi la fiche et je signale le doute : c'est un
   arbitrage produit, pas un détail d'affichage.
4. **`push` pour le cahier, `go` partout ailleurs.** Justifié (c'est ce qui fait
   disparaître la ligne), mais c'est une deuxième manière de naviguer dans le
   même écran. À trancher si l'Agent Z préfère une règle unique.
5. **L'alerte d'absence dépend d'un flux relu toutes les vingt secondes**
   (`presenceSeanceProvider`), qui n'est écouté que pendant un cours. Je n'ai pas
   pu mesurer l'effet sur la batterie ni sur le nombre de requêtes d'une journée
   complète : c'est une lecture de plus toutes les vingt secondes pendant les
   séances, et seulement pendant elles.
6. **Ce que je n'ai pas mesuré du tout** : aucune commande d'analyse ni de test
   n'a été lancée (consigne). Les 36 clés de `i18n_A.json` n'ont pas été
   confrontées au générateur. Deux tests dépendent de l'heure de la machine : « la
   journée finie » mentirait s'il s'exécutait dans la première minute du jour
   civil, et les tests de prière dépendent du fuseau de la machine (ils l'étaient
   déjà avant ce lot).
7. **Ce que je n'ai pas fait** : aucun roster n'est lu par `ENS-02` (donc aucun
   prénom dans la carte dominante), les lignes de la colonne ne sont pas
   pressables (l'accès au groupe passe par la carte dominante seule), et aucune
   fiche de séance n'existe — le protocole parle d'un « accès contextuel à la
   fiche groupe/séance », et seule la fiche groupe est au catalogue.
