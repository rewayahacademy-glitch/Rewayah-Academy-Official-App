# CONTRACT_REQUEST_C — Agent C, pédagogie hors salle (`ENS-04`, `ENS-08`)

Demandes de contrat écrites plutôt que contournées. Aucune ne m'a fait ouvrir un
fichier hors de mon périmètre.

Ordre de priorité : 1 et 2 bloquent une capacité annoncée par le protocole, 3 à 5
sont des dettes qui se voient à l'écran, 6 et 7 sont des précisions.

---

## 1. Une lecture d'anomalies bornée à l'enseignant (bloque `ENS-08`)

**État mesuré.** Les quatre anomalies du contrat — palier à venir, élève hors
corridor, proposition de transfert, proposition de réorientation — n'existent
sous aucun de ces noms en base. Ce que la base sait produire :

- `anomalies_qualite()` (`0024`), trois types : `rapport_manquant`,
  `blocage_sans_suivi`, `evaluation_en_retard` — **réservée à
  `app_role() = 'admin'`** ;
- `progression_exceptions.type` (`0022`), deux valeurs : `blocage`,
  `derogation` — lecture **admin uniquement**.

Aucune RPC d'anomalies bornée à l'enseignant n'existe. `ENS-08` est donc livré
complet et **vide**, et il le dit à l'écran
(`t.enseignant.revue.aucuneAnomalieDetail`).

**Demande.** Une RPC `mes_anomalies_groupe(p_groupe_id uuid)` rendant, pour
l'enseignant du groupe et lui seul : `type` (valeur SQL fermée), `student_id`,
le libellé déjà masqué de l'élève, et un `detail` court. Deux rappels du dépôt
qui s'appliquent ici : une vue neuve porte `security_invoker` ou
`security_barrier` — sans quoi elle ignore la RLS de ses tables sources (piège
payé au lot N4) — et `agent_ro` ne reçoit `grant execute` que sur une fonction
strictement en lecture.

**Point de branchement déjà prêt.** `anomaliesGroupeProvider`
(`lib/features/revue_groupe/anomalies_revue.dart`) rend aujourd'hui une liste
vide. Le jour où la RPC existe, seul ce provider change : l'écran, sa projection
et ses tests n'ont pas une ligne à modifier.

**Décision à trancher en même temps.** Soit les quatre noms de la fiche sont
produits par cette RPC, soit la fiche prend les noms que la base porte déjà. Je
n'ai pas inventé la correspondance.

---

## 2. `PresenceCorrectionAdaptateurSupabase` (l'exception n'atteint pas la base)

`PresenceCorrectionAdaptateur` (`presence_correction.dart:103`) n'a **aucune
implémentation de production** : le seul implémenteur du dépôt est un faux de
test.

Ce que le cahier fait en attendant, et qui est un choix assumé : l'adaptateur du
cahier **consigne** le motif dans le contenu du cahier, qui part avec sa clé
d'idempotence. Une seule écriture atteint la base, et l'exception est aussi
résistante à la coupure que le reste du cahier.

Ce qui manque : l'écriture dans `session_presence_override` (`0007:161`, états
limités à `excusee | corrigee_manuel | finalisee`, `grant` déjà posé en
`0007:418`), qui seule fait changer `etat_presence()`. Elle appartient au socle :
l'écrire dans `lib/features/cahier/` créerait un second chemin vers la même
décision, et un service d'écriture de présence hors de `core`.

**Demande.** `PresenceCorrectionAdaptateurSupabase` + son provider dans
`lib/core/presence/`, traduisant les échecs en `PresenceCorrectionErreurType`
sans laisser fuir un détail backend. Le cahier le consommera à la place de son
adaptateur local, sans changer de présentation.

---

## 3. Le panneau de correction refuse d'agir hors ligne, le cahier ne peut pas

`PresenceCorrectionPanneau` lit `horsLigneProvider` et, hors ligne, **masque ses
deux actions** (`presence_correction_page.dart:111-115`). C'est juste pour une
écriture serveur immédiate ; c'est faux pour le cahier, dont le hors ligne est le
**chemin nominal** et non un mode dégradé.

Conséquence mesurée aujourd'hui : sans réseau, l'enseignant peut déposer son
cahier mais **pas y signaler une exception de présence**. L'écran le dit
(`t.enseignant.cahier.exceptionHorsLigne`) plutôt que de le taire, mais c'est une
capacité perdue sur le seul écran conçu pour fonctionner sans réseau.

**Demande.** Une capacité de plus dans `PresenceCorrectionCapacites`, par exemple
`peutDeciderHorsLigne`, qui autorise la surface à recueillir la décision hors
ligne quand l'intégration sait la mettre en file. Le panneau ne m'appartient pas
en écriture : je ne l'ai pas touché.

---

## 4. Les treize libellés du panneau, hors slang

`PresenceCorrectionLibelles` (`presence_correction.dart:111`) injecte treize
chaînes en paramètres au lieu de lire `t.*`, ce qui contrevient à « aucune chaîne
visible en dur » (`lib/CLAUDE.md:36`).

Le cahier paie cette dette en un seul endroit, `libellesCorrectionCahier()`
(`lib/features/cahier/cahier_page.dart`), et il la paie avec des clés slang :
`enseignant.cahier.exception*` dans `docs/parallel-reports/i18n_C.json`. Ces clés
sont utilisables telles quelles si le socle décide de lire l'i18n depuis le
panneau et de supprimer l'injection.

---

## 5. La « marge autorisée » d'un objectif personnel n'est pas exprimable

Le protocole demande que l'objectif personnel et l'ajustement du travail maison
restent « dans la marge autorisée », et que la suspension du nouveau contenu se
fasse « dans la marge ». `CleRegle` (`enums.dart:339`) ne porte que quatre clés :
`session_duration_minutes`, `session_paid_minimum_minutes`,
`break_minutes_between_sessions`, `max_students_per_teacher`. Aucune ne borne un
objectif pédagogique ni un volume de travail maison, et `valeurRegleProvider`
n'a donc rien à lire.

**Ce que j'ai fait, exactement.** Rien borné. Aucune constante inventée, aucun
plafond de caractères, aucune limite de semaines : `service_regles.dart:118` et
la règle des jetons interdisent l'un comme l'autre. L'écran écrit ce qui encadre
réellement l'objectif — le programme est institutionnel et ne se modifie pas
d'ici — et `DecisionEleve` ne porte aucun champ qui permettrait d'en sortir.

**Demande.** Soit de nouvelles clés de règle **avec leur unité** (migration +
`enums.dart`, donc Agent Z), soit une décision écrite qui retire la notion de
marge paramétrable du protocole. Tant qu'aucune des deux n'existe, « dans la
marge autorisée » n'est pas implémentable, et le dire vaut mieux que le simuler.

---

## 6. `ParticipantBrouillon` ne porte pas `consolide`

`presence_seance_v` rend `consolide` et `consolide_le`, et `LignePresence` sait
les afficher (« provisoire contre finalisé », section 6.6). `brouillon_cahier()`
ne les rend pas dans ses `participants`.

Le cahier passe donc `afficherConsolide: false` : il se **tait** plutôt que
d'afficher qu'aucune décision humaine n'a figé l'état, ce qu'il ne sait pas. Si
la RPC peut rendre la colonne, `ParticipantBrouillon` l'accueille et l'écran
retire ce `false`. Modèle partagé : Agent Z.

---

## 7. Deux précisions sur l'état de la base, mesurées le 20 septembre 2026

1. `0025_role_enseignant` et `0026_durcissement_execute_enseignant` **sont
   appliquées** (`list_migrations`) : `brouillon_cahier`, `mon_groupe_detail`,
   `mes_rapports_en_attente` et `mes_seances_enseignant_v` existent bien en base.
   Le `TEACHER_SHARED_CONTRACTS.md` §13 dit encore l'inverse : il vaut la peine
   de le corriger, parce qu'il change l'interprétation de l'état `error`.
2. `0020_programme_pedagogique` a été appliquée dans cette session, sur
   autorisation explicite de l'opérateur. `0021` à `0024` **ne le sont pas** : la
   couche de permissions de l'outil a refusé les appels suivants. La base est
   donc dans un état intermédiaire volontairement noté ici :
   `programme_versions` et `programme_niveaux` existent, `progression_historique`,
   `progression_exceptions`, `evaluations` et `controles_qualite` non. Rien de ce
   que j'ai livré n'en dépend pour fonctionner — les deux écrans lisent des
   contrats, pas des tables — mais le préremplissage de l'unité de curriculum
   restera nul jusqu'à ce que `0021` à `0024` passent.
