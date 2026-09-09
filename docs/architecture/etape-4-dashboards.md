# Plan d'exécution - Étape 4
## Dashboards Bento Grid, affectation durable, disponibilités et prières

Ce document décrit **ce qui doit exister** et **comment on vérifie que c'est
correct**. Il tient pour l'étape 4 le rôle que `etape-3-auth-kyc.md` tient pour
l'étape 3.

Sources : `docs/produit/parcours-utilisateurs.md` pour les écrans,
`docs/architecture/decisions.md` pour les ADR, `etape-0-1-fondations.md` pour le
schéma, `etape-3-journal.md` pour ce qui existe déjà.

---

## 1. Ce que l'étape 4 doit rendre possible

L'étape 3 s'arrête à la porte : un compte validé arrive sur un placeholder. Le
produit n'a **aucun écran métier**, donc aucun cours ne peut être planifié, pris
en charge, ni même annoncé.

À la fin de l'étape 4, ces six parcours fonctionnent de bout en bout :

| # | Parcours | Écrans |
| :-- | :--- | :--- |
| 1 | Un tuteur pose les créneaux possibles de chaque enfant | `TUT-04` |
| 2 | Un enseignant déclare ses disponibilités et prend un élève | `ENS-06` |
| 3 | Le foyer voit l'état en direct de chaque enfant | `TUT-01` |
| 4 | L'enfant voit son prochain cours, et rien d'autre | `ELV-02` |
| 5 | L'enseignant lit sa journée en une colonne | `ENS-02` |
| 6 | L'administration voit ce qui bloque, et agit d'un tap | `ADM-01` |

Plus `TUT-05`, les réglages par enfant, qui n'est pas un tableau de bord mais
sans lequel l'ADR-009 n'est pas applicable : le tuteur ne peut rien changer.

---

## 2. Décisions de l'opérateur, prises le 6 septembre 2026 (ADR-017)

Elles sont la matière de cette étape, pas des détails de réglage. Elles ont été
demandées avant d'écrire la moindre ligne, parce qu'elles décident du schéma.

### 2.1 Le matching est un engagement durable, pas une réservation

**« Le matching, c'est un mariage. »** Un enseignant qui prend un élève le garde.
La relation ne se rompt que par une **demande de réaffectation**, ouverte à
quatre parties : l'administration, le contrôleur, le tuteur (ou l'élève adulte
autonome), et l'enseignant. Personne ne se dégage seul.

Conséquence directe : ce que `ENS-06` prend n'est pas un créneau, c'est un
**élève**. Le créneau n'est que l'heure du rendez-vous hebdomadaire qui en
découle. Un modèle par réservations successives aurait fait retomber chaque
foyer en « recherche d'enseignant » après chaque cours, ce qui est exactement le
contraire du produit.

**Cinq élèves par enseignant**, valeur d'`app_config` et non constante de code.
Un enseignant qui a du temps demande une augmentation ; c'est une demande du
même registre que la réaffectation, tranchée par l'administration. Cohérent avec
l'ADR-004, qui dimensionne un groupe à six personnes, cinq élèves et le
professeur.

### 2.2 Une séance dure 60 minutes par défaut, et 45 minutes suffisent à la payer

La grille de `TUT-04` et de `ENS-06` pose donc des cases d'une heure.

Le minimum payable existe pour une raison précise : **une pause ou une prière ne
doit jamais faire tomber une séance sous le seuil de rémunération.** C'est la
mécanique de compensation que `couverture-specs.md` signalait comme non
spécifiée. Elle l'est maintenant : 60 minutes prévues, 45 minutes de présence
effective suffisent, et ce qui manque entre les deux est du temps d'interruption
consigné, pas du temps volé à quelqu'un.

**Ces deux nombres sont des valeurs par défaut, pas des règles.** Voir 2.4 : un
élève peut avoir les siennes.

### 2.3 Les prières sont calculées, ajustables, annoncées et consignées

Décision de l'opérateur, contre les deux autres options proposées : les horaires
sont **calculés** (paquet `adhan`), pas saisis à la main ni approximés.

Quatre exigences l'accompagnent, et elles viennent d'un litige réel :

1. **Tout le monde voit la même chose à l'avance.** L'élève et le tuteur voient
   les interruptions prévues avant le cours, pas au moment où elles arrivent.
2. **Alerte** à l'approche, pour que personne ne soit surpris.
3. **Consignation** de chaque interruption, pour que la discussion sur le temps
   dû ne repose sur la mémoire de personne.
4. **Ajustement à la minute près**, parce qu'un horaire calculé ne correspond pas
   toujours à l'heure réelle de la mosquée de référence.

La conséquence technique est le point important : **les réglages de calcul sont
en base, le calcul est déterministe, et tous les rôles calculent à partir des
mêmes réglages.** Si l'enseignant calculait chez lui et annonçait le résultat,
il n'y aurait aucune transparence, seulement une parole contre une autre.

Le préavis de l'alerte suit la même règle et vit dans la même ligne, à côté de
la durée de l'interruption. Un préavis porté par chaque application aurait
prévenu l'enseignant dix minutes avant et l'élève cinq : la pause et son
annonce voyagent ensemble, sinon « personne n'est surpris » ne veut pas dire la
même chose des deux côtés.

### 2.4 Aucune règle n'est figée, et chaque élève peut avoir la sienne

Consigne arrivée après les trois précédentes, et qui les recadre toutes :
**l'administration doit pouvoir changer ces valeurs élève par élève, à la volée
ou sur demande d'une des parties.**

Ce n'est pas un réglage de confort. Un enfant de six ans qui décroche au bout de
trente minutes, un adulte autonome qui veut deux heures, un élève dont la prière
tombe systématiquement au milieu de son créneau : trois cas où une valeur unique
pour toute la plateforme se paie en litiges, exactement ceux que l'ADR-017
cherche à éteindre.

Le modèle est donc à trois étages, et il vaut pour **toute** valeur de règle de
cette étape, y compris celles décidées en 2.1 et 2.2 :

| Étage | Où | Qui écrit |
| :--- | :--- | :--- |
| Défaut de la plateforme | `app_config` | Administration |
| Surcharge d'un élève | `student_rule_overrides` | Administration, avec motif |
| Demande d'une partie | `matching_requests`, sorte `rule_change` | Les quatre parties de 2.1, tranchée par l'administration |

Les valeurs surchargeables sont la durée de séance, le minimum payable, la pause
entre deux cours, et le plafond d'élèves, ce dernier portant sur l'enseignant et
non sur l'élève.

La valeur effective se lit par **une seule fonction**, `regle_effective()`, que
tout écran et toute contrainte emploient. Un écran qui lirait `app_config` en
direct afficherait la règle de la plateforme à un élève qui n'en relève pas :
c'est le genre d'écart qui ne se voit qu'au moment de la facture.

**Une surcharge ne s'efface pas, elle se clôt.** Elle porte son auteur, sa date
et son motif. Une règle qui a compté pour une séance passée doit rester lisible
après coup, sinon la consignation de 2.3 ne prouve rien : « la séance durait 45
minutes ce jour-là » est une phrase qui doit se vérifier six mois plus tard.

---

## 3. Neuf défauts trouvés dans l'existant, à corriger ici

Comme à l'étape 3, ils ont été trouvés en construisant les parcours, pas en
relisant le schéma. Chacun rend un parcours de l'étape 4 impossible.

Les deux derniers, 3.8 et 3.9, ne se sont pas vus en construisant : ils se sont
vus en **mesurant**. Ce document en annonçait sept.

### 3.1 Aucune table ne peut recevoir les disponibilités d'un foyer

`availability_slots.teacher_id` est `not null` et référence un profil
d'enseignant. `TUT-04` n'a donc **rien où écrire**, et le matching inversé, qui
suppose que les créneaux élèves existent, n'a rien à afficher. C'est le défaut
que `parcours-utilisateurs.md` annonçait en toutes lettres dans son tableau des
écrans manquants, sans qu'aucune table ne le corrige.

### 3.2 L'affectation d'un élève à un enseignant n'existe nulle part

Rien dans le schéma ne dit qu'un élève est suivi par un enseignant. La relation
n'existe qu'indirectement, séance par séance, par `session_participants`.

Sans elle, quatre écrans sont sans source : `ENS-06` n'a pas d'élève à prendre,
`TUT-01` ne peut pas afficher « en recherche d'un enseignant », `ADM-01` ne peut
pas compter les foyers sans enseignant, `ADM-05` n'a rien à attribuer. Et le
« mariage » de l'ADR-017 n'aurait aucun support : ce qui n'est pas une ligne ne
se rompt pas par une demande.

### 3.3 Le tuteur ne peut pas modifier les réglages de son enfant

`student_profiles` porte `interface_mode`, `camera_policy` et
`avatar_storage_key`, les trois réglages de `TUT-05`. Sa seule policy famille
est `student_profiles_family`, **en `for select`**. Aucune policy d'écriture
n'existe pour le tuteur, alors que la matrice d'accès de l'étape 1 lui accorde
« L E foyer ».

L'ADR-009 dit que la caméra est un attribut de profil que le tuteur règle à
distance. En l'état, seul un administrateur peut le faire.

### 3.4 Deux séances d'un même enseignant peuvent se chevaucher

`guard_session_overlap` protège `session_participants`, donc un profil déjà
inscrit à une séance. L'enseignant, lui, est porté par `sessions.teacher_id` : si
sa ligne de participant n'est pas créée, rien ne l'empêche d'avoir deux cours à
la même heure. L'audit demandait une contrainte `EXCLUDE` sur `sessions`
(`no_teacher_overlap`, avec `btree_gist`) : **elle n'a jamais été écrite**, ni en
0001 ni ailleurs.

Tant qu'aucun écran ne créait de séance, le défaut était théorique. L'étape 4 en
crée par lots de quatre semaines : il ne l'est plus.

### 3.5 Toutes les disponibilités de tous les enseignants sont lisibles par tous

`availability_slots_reader` accorde le `select` à tout `controller`, `teacher` ou
`guardian`, **sans aucun filtre de ligne**. Un tuteur lit donc le planning de
disponibilité de chaque enseignant de la plateforme, et chaque enseignant celui
de ses collègues.

Ce n'est pas une fuite d'identité au sens de l'ADR-008, puisque la table ne porte
que des identifiants et des heures. C'est une exposition inter-utilisateurs hors
des trois vues qui devaient rester la seule surface de ce type (étape 1,
section 5). Le feed de matching passera par une vue, et cette policy se referme.

### 3.6 Le tuteur ne peut pas lire le nom de l'enseignant de son enfant

`TUT-01` doit afficher « prénom, pastille verte, **nom de l'enseignant**, minuteur
écoulé ». Or `profiles_family_select` borne la lecture au foyer, et un enseignant
n'est dans aucun foyer. `family_sessions_v` ne porte pas non plus l'enseignant.

Le tuteur voit donc que son enfant est en cours, sans pouvoir dire avec qui. La
correction reste dans la règle de l'ADR-008 : prénom et identifiant immuable,
jamais le nom complet ni le courriel, et par une vue, pas par une policy ouverte.

### 3.7 Rien ne porte la durée d'une séance ni le minimum payable

`app_config` n'a ni `session_duration_minutes`, ni minimum de rémunération, ni
plafond d'élèves par enseignant, ni durée de pause. Ces quatre valeurs décident
de ce que la grille affiche et de ce que la base accepte : elles ne peuvent pas
rester des constantes dispersées dans le code Dart.

Plus grave, rien ne permet de les poser **par élève**, ce que l'ADR-017 exige en
2.4. Une valeur d'`app_config` est unique pour la plateforme : la surcharge est
donc une table à écrire, pas une clé à ajouter.

### 3.8 La liste des élèves d'un enseignant porte leur nom de famille

`teacher_roster_v` sélectionne `p.last_name`. L'ADR-008 et le registre des
décisions disent pourtant, pour cette vue précise : « prénom et identifiant
seulement ». C'est le contrôle anti-pillage qui a remplacé le filigrane, et il
fuyait par la vue censée l'appliquer.

Trouvé en écrivant le contrôle de schéma qui devait le vérifier.

### 3.9 Deux cours consécutifs sont refusés comme un chevauchement

Trouvé en mesurant, pas en lisant : sur cinq créneaux consécutifs, trois prises
passaient et deux échouaient, une sur deux. Cela ressemblait à un plafond mal
compté, et n'en était pas un.

`guard_session_overlap` compare les séances avec `tstzrange(..., '[]')`, donc
**bornes fermées**. Un cours de 10h à 11h et le suivant de 11h à 12h partagent
alors l'instant 11h00 et sont réputés se recouper. Or `ENS-02` est écrit pour
« un enseignant qui enchaîne 5 cours ».

Un intervalle de temps se ferme à gauche et s'ouvre à droite : la fin d'une
séance est le début de la suivante, elle ne lui appartient pas. La contrainte
`EXCLUDE` du défaut 3.4 emploie la même convention, sans quoi l'un des deux
garde-fous accepterait ce que l'autre refuse.

---

## 4. Invariants de l'étape 4

| # | Invariant | Où il est appliqué |
| :-- | :--- | :--- |
| I1 | Un élève a **au plus un** enseignant actif | Index unique partiel sur les affectations actives |
| I2 | Un enseignant ne dépasse pas son plafond d'élèves | Déclencheur lisant `app_config`, jamais l'écran |
| I3 | Une affectation ne se rompt que par une décision d'administration | Aucune policy de suppression ni de mise à jour directe. Seules les fonctions de demande et de décision écrivent |
| I4 | Deux enseignants qui prennent le même élève au même instant : un seul passe | La prise est atomique en base, l'autre reçoit un refus explicite |
| I5 | Un enseignant n'a jamais deux séances qui se recoupent | Contrainte `EXCLUDE` sur `sessions`, défaut 3.4 |
| I6 | Le tuteur écrit les trois réglages de son enfant, et rien d'autre | Policy d'update bornée aux colonnes de `student_profiles`, avec `GRANT UPDATE (colonnes)` |
| I7 | Les réglages de prière sont publics pour les personnes concernées, et modifiables par le seul enseignant | Vue de lecture, policy d'écriture propre |
| I8 | L'élève, le tuteur et l'enseignant obtiennent la même minute pour une même prière | Test qui calcule des deux côtés à partir des mêmes réglages |
| I9 | Un compteur d'`ADM-01` affiche zéro, il ne disparaît pas | Écran, et test de widget sur l'état vide |
| I10 | Aucune règle de durée n'est lue ailleurs que par `regle_effective()` | Contrôle de source, comme celui du code personnel de l'étape 3 |
| I11 | Une surcharge de règle ne se supprime pas, elle se clôt, avec auteur et motif | Déclencheur d'immuabilité, comme `contract_acceptances` |
| I12 | Une règle change sans redéploiement, et le changement est visible des quatre parties | Lecture par vue, jamais par constante compilée |

---

## 5. Écrans

### `TUT-04` Disponibilités du foyer

Grille de la semaine, une par enfant, cases d'une heure. On tape une case, elle
bascule. Pas de saisie d'heures, jamais de sélecteur horaire.

Sous la grille, la phrase qui dit ce que cela produit : plus de créneaux
proposés, plus vite le cours démarre.

Heures affichées dans le fuseau du foyer, la base ne connaissant que le motif
hebdomadaire et son fuseau.

### `ENS-06` Disponibilités et élèves

Deux onglets. **Mes disponibilités** : la même grille que `TUT-04`, au sens
littéral, le même composant.

**Élèves en attente** : la liste des élèves sans enseignant dont au moins un
créneau croise les disponibilités de cet enseignant. Prénom, identifiant
immuable, niveau, créneaux compatibles, bouton « Prendre ».

**Tri par ancienneté d'attente**, jamais par nom ni par date de créneau. Un
liseré signale les demandes en attente depuis plusieurs jours.

À la limite de cinq élèves, le bouton « Prendre » n'est pas rendu : il est
remplacé par une phrase qui explique la limite et propose la demande
d'augmentation. Règle constante depuis l'étape 3, un bouton qui échoue après le
geste coûte plus cher qu'un bouton absent.

Un élève pris par un autre enseignant disparaît de la liste. Si deux enseignants
tapent au même instant, l'un reçoit un refus clair : la base tranche, pas
l'écran.

### `TUT-01` Accueil famille

Bloc dominant : l'état en direct de chaque enfant, une ligne par enfant, selon
les cinq états de `parcours-utilisateurs.md`. Le bouton « Assister » n'est rendu
que pendant une séance en cours ; il mène à la salle en observateur, qui est
l'étape 5, donc il est présent et mène à l'écran d'attente de salle.

Blocs secondaires : ajouter un appareil, réglages du foyer, et la date de fin
d'accès de chaque enfant.

### `ELV-02` Accueil élève

Deux blocs, rien d'autre, dans les six états prévus. En mode enfant, aucune
navigation : l'écran est le produit.

Deuxième bloc permanent : le Coran, qui mène au placeholder de `ELV-04`.

**Les interruptions de prière prévues pendant la séance à venir sont annoncées
ici**, avant le cours et non pendant (ADR-017). En mode enfant, par un
pictogramme et un libellé audio ; en mode standard, en clair.

C'est l'écran sur lequel se mesure enfin le démarrage à froid, scénario 7 de
l'étape 2, non coché depuis deux étapes faute d'écran métier à charger.

### `ENS-02` Journée

Bloc dominant : le prochain cours, avec prénom et identifiant de l'élève,
minuteur, et le bouton de lancement qui reste inerte tant que le pre-flight de
l'étape 5 n'existe pas. Il n'est donc pas rendu : voir la règle du bouton absent.

Sous ce bloc, **une seule colonne du haut vers le bas** : cours, pauses et
prières comme des entrées de même nature. C'est la demande explicite des specs
produit, et elle interdit un bloc « prières » séparé.

Bloc secondaire : le nombre d'élèves en attente compatibles, et l'accès à
`ENS-06`.

### `TUT-05` Réglages par enfant

Un enfant par carte, trois réglages : photo, caméra, mode d'interface. Le texte
dit la conséquence en clair, avec le prénom de l'enfant, jamais un libellé
abstrait.

Ces réglages s'appliquent à la séance suivante, jamais pendant un cours.

### `ADM-01` Centre de commande

Cinq compteurs, **le zéro affiché comme les autres valeurs**. Sous eux, la liste
« à traiter en premier », ordonnée par ancienneté, chaque ligne menant d'un tap à
l'écran d'action.

| Compteur | Source |
| :--- | :--- |
| Dossiers en attente de validation | `kyc_documents` en `pending` |
| Foyers sans enseignant | Élèves actifs sans affectation active |
| Rapports de cours manquants | Séances terminées sans rapport |
| Incidents des dernières 24 heures | Séances en `tech_failure`, `teacher_absent`, `student_absent` |
| Comptes provisoires arrivés à échéance | `provisional_active` dont `access_until` est passé |

Un sixième compteur s'y ajoute par l'ADR-017 : les **demandes en attente de
décision**, réaffectation, plafond et changement de règle confondus. Sans lui,
une demande faite par un tuteur n'a aucun chemin pour arriver sous les yeux de
quelqu'un.

### `ADM-06` Demandes et règles

Écran nouveau, conséquence de l'ADR-017. Il n'existe dans aucune spec d'origine
parce que la notion de règle par élève n'existait pas.

Deux usages, un seul écran, dans le registre de `ADM-02` : une file de demandes
prise une par une, et la feuille de règles d'un élève.

**La file.** Chaque demande porte qui l'a faite, en quelle qualité, quand, sur
quel élève, et ce qu'elle réclame. Deux verdicts, motif obligatoire pour un
refus, comme `ADM-02`.

**La feuille de règles d'un élève.** Chaque valeur affiche côte à côte le défaut
de la plateforme et la valeur effective, pour que l'écart soit visible sans
calcul mental. Changer une valeur demande un motif : c'est ce motif qui rendra la
décision lisible six mois plus tard. L'historique des surcharges closes reste
affiché sous la valeur courante.

L'administration change une règle **à la volée** depuis cette feuille, sans
qu'une demande existe : c'est la consigne, une demande n'est qu'un des deux
chemins.

### Où les autres parties demandent

Une demande n'a pas d'écran à elle : elle part de l'écran où la règle se
constate.

| Partie | Écran | Ce qu'elle demande |
| :--- | :--- | :--- |
| Tuteur, élève autonome | `TUT-05` | Durée, minimum payable, réaffectation |
| Enseignant | `ENS-06` | Augmentation de plafond, réaffectation |
| Contrôleur, administration | `ADM-06` | Tout, la décision leur revenant |

---

## 6. Ce que la base doit gagner (migration 0005)

Ce tableau dit ce qui a été écrit, avec les noms retenus à l'implémentation.

| Objet | Rôle |
| :--- | :--- |
| `weekly_availability` | Le motif hebdomadaire, **commun à l'élève et à l'enseignant**. Défaut 3.1 |
| `teacher_student_assignments` | L'affectation durable de l'ADR-017. Défaut 3.2 |
| `matching_requests` | Demandes de réaffectation, d'augmentation de plafond et de changement de règle, avec leur décision |
| `rule_overrides` | La règle d'un profil, avec auteur, motif et clôture. ADR-017 section 2.4. Une seule table pour l'élève et pour l'enseignant, la clé disant sur quel rôle elle a un sens |
| `regle_effective()`, `regles_profil_v` | Le seul chemin client de lecture d'une règle, avec I10 et I12 |
| `regle_brute()` | Le même calcul sans contrôle d'accès, réservé aux déclencheurs et aux tâches : un plafond ne se contourne pas faute de droit de lecture |
| `partie_concernee()` | Qui est partie à un dossier, au sens de l'ADR-017. Une seule définition, partagée par toutes les policies de l'étape |
| `instant_creneau()` | L'instant réel d'un créneau hebdomadaire. Tout croisement passe par là, jamais par une égalité d'heures locales |
| `prayer_settings` | Coordonnées, méthode de calcul, ajustements à la minute, durée de l'interruption et préavis de son alerte, par enseignant |
| `sessions` : contrainte `EXCLUDE` et `prayer_pause_minutes` | Défauts 3.4 et 2.3 |
| `guard_session_overlap()` en bornes semi-ouvertes | Défaut 3.9 |
| Policy d'update famille sur `student_profiles`, plus `GRANT UPDATE (colonnes)` | Défaut 3.3, avec I6 |
| `maj_eleve_pedagogie()` | Ce que le grant par colonnes retire à l'administration lui revient par une porte nommée et journalisée |
| `availability_slots_reader` resserrée | Défaut 3.5 |
| `mes_seances_v` | Les séances des trois rôles, prénom et identifiant des deux côtés. Remplace `family_sessions_v`. Défaut 3.6 |
| `mes_affectations_v` | Qui suit qui, y compris avant la première séance : c'est ce qui permet « en recherche d'un enseignant » |
| `teacher_roster_v` recréée | Défaut 3.8 |
| `eleves_en_attente_v` | Le feed de `ENS-06`, trié par ancienneté, filtré par compatibilité d'instants |
| `prendre_eleve()`, `materialiser_seances()` | La prise atomique, avec I1, I2, I4, et les séances de l'horizon glissant |
| `demander()`, `decider_demande()` | Le seul chemin de rupture et de changement, avec I3 |
| `poser_regle()`, `clore_regle()` | La règle à la volée, et sa clôture. Même porte que la décision d'une demande |
| `indicateurs_admin()`, `demandes_en_attente()` | Les six compteurs de `ADM-01` en une lecture, et la file de `ADM-06` |
| Clés d'`app_config` | Les **défauts** surchargeables : `session_duration_minutes` 60, `session_paid_minimum_minutes` 45, `max_students_per_teacher` 5, `break_minutes_between_sessions` 30. Plus `matching_horizon_weeks` 4, qui n'est pas une règle d'élève |

**Une seule table de disponibilités, pas deux.** `TUT-04` et `ENS-06` affichent
la même grille : deux tables au motif identique divergeraient à la première
évolution. `availability_slots`, en instants absolus, reste pour les exceptions
datées d'une version ultérieure, et n'est pas employée en MVP-0.

---

## 7. Scénarios d'acceptation

Un scénario non mesuré n'est pas un scénario vert.

| # | Scénario | Comment il se vérifie |
| :-- | :--- | :--- |
| 1 | Un tuteur pose et retire un créneau, un enseignant aussi, dans la même table | Test SQL de policy, sur les deux rôles |
| 2 | Un élève ne peut pas avoir deux enseignants actifs | Test SQL, index unique partiel |
| 3 | Le sixième élève est refusé par la base, pas par l'écran | Test SQL sur le déclencheur de plafond |
| 4 | Deux enseignants prennent le même élève au même instant : un seul passe | Test SQL en deux transactions concurrentes |
| 5 | Un enseignant ne peut pas se retirer un élève sans décision | Test SQL : update et delete directs refusés |
| 6 | Un tuteur change la politique caméra de son enfant, et rien d'autre | Test SQL : la colonne autorisée passe, `household_id` et `level` sont refusés |
| 7 | Deux séances du même enseignant qui se recoupent sont refusées | Test SQL sur la contrainte `EXCLUDE` |
| 8 | Un tuteur ne lit plus les disponibilités des enseignants qui ne suivent pas son enfant | Test SQL, défaut 3.5 |
| 9 | L'élève et l'enseignant affichent la même minute pour une même prière | Test Dart sur les réglages partagés |
| 10 | Un ajustement de plus ou moins une minute déplace l'entrée dans les deux écrans | Test Dart |
| 11 | Les cinq compteurs de `ADM-01` affichent zéro sans disparaître | Test de widget |
| 12 | `ENS-06` ne rend pas le bouton « Prendre » au plafond | Test de widget |
| 13 | `ELV-02` affiche ses six états, dont l'annulation et le hors ligne | Test de widget |
| 14 | Démarrage à froid mesuré sur `ELV-02` réel | Mesure, scénario 7 de l'étape 2 |
| 15 | Une durée posée pour un seul élève change ce que voient ses écrans, et rien pour les autres | Test SQL sur `regle_effective()`, plus test de widget |
| 16 | Une surcharge close reste lisible, et aucune ne se supprime | Test SQL : `delete` et `update` refusés, la clôture passe |
| 17 | Une demande faite par chacune des quatre parties atteint `ADM-06` et se tranche | Test SQL par rôle |

---

## 8. Ce que l'étape 4 ne fait pas

- **Aucune salle de cours.** `ELV-03`, `ENS-03` et le pre-flight sont l'étape 5.
  Le bouton de lancement de `ENS-02` n'est donc pas rendu.
- **Aucun cahier de transmission.** `ENS-04` et `TUT-06` sont l'étape 6. Les
  interruptions de prière ont leur colonne dès maintenant, elle sera remplie par
  la salle, à l'étape 5 : l'exigence de consignation de l'ADR-017 est donc posée
  ici et honorée là.
- **Aucune notification poussée.** L'alerte de prière de l'ADR-017 est rendue
  dans l'application, pas envoyée à un appareil éteint. Le canal de notification
  n'existe pas encore, `device_tokens` est vide et l'étape D reste ouverte.
- **Aucun `ADM-05` ni `CTR-01`.** L'attribution manuelle et le planning global
  sont utiles, mais `ADM-01` mène déjà à `ADM-02`, et le contrôleur n'a rien à
  observer tant qu'aucune salle n'existe.
- **Aucun groupe.** `allow_multi_participant_sessions` reste faux : l'ADR-004
  prévoit les groupes, le MVP-0 les laisse fermés.

---

## 9. Découpage en lots

Un lot, un commit, et le journal mis à jour à la fin de chacun. Jamais en bloc :
c'est ce qui a permis, aux étapes 2 et 3, de dire ce qui était mesuré et ce qui
ne l'était pas.

| Lot | Contenu |
| :-- | :--- |
| L0 | Cette spécification, l'ADR-017, le journal d'étape |
| L1 | Migration `0005` : les sept défauts, les quatre tables, les fonctions, plus `supabase/tests/scenarios_etape4.sql` rejoué par la CI |
| L2 | Services Dart : règles effectives, planning, affectations, disponibilités, avec leurs miroirs de types |
| L3 | La grille de semaine partagée, `TUT-04` et l'onglet disponibilités de `ENS-06` |
| L4 | `ENS-06` élèves en attente, prise atomique, plafond, demande d'augmentation |
| L5 | Prières : réglages, calcul, ajustements, entrées de planning communes aux trois rôles |
| L6 | `ENS-02` la journée en une colonne |
| L7 | `ELV-02` et ses six états, puis la mesure du démarrage à froid |
| L8 | `TUT-01`, `TUT-05`, et les demandes des parties |
| L9 | `ADM-01` et `ADM-06` |
| L10 | Vérifications de fin d'étape, documentation, mise à jour de `PROGRESS.md` |
