# TC_AGENT_H_REPORT.md

> **Agent H, Academic Flow.** Worktree `D:\RA_TC\h`, branche `teaching-core/h-academic`,
> baseline `0071557`.
> Les workflows academiques autour du Groupe : travail a venir, reprise, post-cours, micro-feedback,
> signalement. **Sans reconstruire le Group Shell d'Agent A, et sans refaire le cahier de
> transmission du chantier enseignant.**

---

## 0. Etat en une ligne

`flutter analyze lib test` : **propre, zero issue** sur le depot entier.
`flutter test test/teaching_core/h` : **71 tests, tous verts.**
`git status --porcelain` : **quatre entrees, toutes dans l'ownership du lot H.**
`dart run tool/verifier_jetons.dart` : **10 violations, toutes pre-existantes, zero dans mes fichiers.**

Ce qui est **reellement branche sur le serveur** : rien, et c'est declare partout. Les quatre ports du
lot H echouent en production avec un message qui dit quoi composer, parce qu'aucune des trois tables
dont ils dependent n'existe. Le detail est dans `TC_CONTRACT_REQUEST_H.md`.

---

## 1. Ce qui est livre

### 1.1 Domaine — `lib/core/tc_parcours/` (12 fichiers)

| Fichier | Ce qu'il porte |
|---|---|
| `session_feedback.dart` | `SessionFeedback`, `ReponseFeedback`, `TendanceFeedback` (+ calcul du seuil) |
| `port_feedback.dart` | `PortFeedback`, `QuestionFeedback`, `EchecFeedback`, les trois providers |
| `rotation_feedback.dart` | `CatalogueFeedback` (5 volets) et `RotationFeedback` : rotation + echantillonnage, **purs** |
| `feedback_memoire.dart` | `FeedbackMemoire` : double local, et `ContexteSeanceFeedback` (ce que le serveur devra dire) |
| `student_concern.dart` | `StudentConcern`, ses trois enums, `ResumeFamilleSignalement`, `EchecSignalement` |
| `port_signalement.dart` | `PortSignalement` + `SignalementMemoire` (double local) + provider |
| `post_cours_vm.dart` | `PostCoursVM` : exceptions, ordre d'ecran, copies `avecNotes` / `avecTravail` |
| `port_post_cours.dart` | `PortPostCours` + `PostCoursDepuisCahier` (la composition reelle) + `EchecPostCours` |
| `port_travail_a_venir.dart` | `PortTravailAVenir` + `TravailAVenir` + le plafond de trois + provider de famille |
| `source_contenu_seance.dart` | `SourceContenuSeance` et `ContenuSeanceIndisponible` : la surface etroite vers Agent F |
| `plage_lisible.dart` | `positionLisible` / `plageLisible` : un `ContentPosition` ne s'affiche jamais brut |
| `libelles_tc_parcours.dart` | La facade `tc.parcours.*` (decision `D-03`), 66 libelles annotes `TC-I18N` |

### 1.2 Stubs de ports — `lib/core/tc_parcours/ports_externes/` (8 fichiers)

Tous portent l'en-tete `// TC-STUB-PORT:` avec leur chemin canonique, et **aucun ne contient
d'implementation**.

| Stub | Proprietaire | Source de la copie |
|---|---|---|
| `content_position.dart`, `content_range.dart` | B | **Fichiers publies d'Agent B**, comme l'impose l'AMENDEMENT 1 (les sections 7 et 8 du contrat sont perimees) |
| `intention_pedagogique.dart`, `learning_assignment.dart`, `port_assignations.dart` | D | Contrat section 11, verifie mot pour mot contre les fichiers publies d'Agent D |
| `teacher_student_projection.dart`, `port_roster_enseignant.dart` | E | Contrat section 12, verifie mot pour mot contre les fichiers publies d'Agent E |
| `slot_action.dart` | A | Contrat section 2, verifie contre `group_home_vm.dart` d'Agent A |

`port_assignations.dart` reprend **la classe abstraite seule** : le double `AssignationsMemoire`
d'Agent D et son provider ne sont pas recopies.

### 1.3 Surfaces — `lib/features/tc_flux_academique/` (4 fichiers)

| Fichier | Ou il se branche |
|---|---|
| `bloc_avant_prochain_cours.dart` | slot `avantProchainCours` de `GroupHomeVM` (Agent A) |
| `carte_feedback_seance.dart` | fin de seance, cote eleve et tuteur (Agent A ou Agent E) |
| `feuille_signalement.dart` | action « Signaler un besoin » de la fiche eleve (Agent E) |
| `panneau_post_cours.dart` | sous le constat du cahier `ENS-04` (chantier enseignant) |

**Aucun ecran, donc aucun `routes_tc_h.dart`.** C'est un choix, explique en section 5.

### 1.4 Tests — `test/teaching_core/h/` (12 fichiers, 71 tests)

`support/hote_h.dart` (hote propre au lot, decision `D-06`), `faux/faux_enseignant.dart`,
`faux/faux_ports_externes.dart`, puis neuf fichiers de test :

| Fichier | Tests |
|---|---|
| `post_cours_test.dart` | 18 |
| `feedback_test.dart` | 10 |
| `signalement_test.dart` | 10 |
| `rotation_feedback_test.dart` | 9 |
| `travail_a_venir_test.dart` | 9 |
| `bloc_avant_prochain_cours_test.dart` | 4 |
| `feuille_signalement_test.dart` | 4 |
| `panneau_post_cours_test.dart` | 4 |
| `carte_feedback_test.dart` | 3 |

### 1.5 Documents

`docs/teaching-core/TC_AGENT_H_REPORT.md`, `TC_CONTRACT_REQUEST_H.md`, `i18n/tc_i18n_H.json`.

---

## 2. Ce qui marche vraiment, et comment c'est prouve

### 2.1 Avant le prochain cours (spec 4.3) — `travail_a_venir_test.dart`, 6 tests

- **aucune tache** : aucune action, et rien d'invente ;
- **1, 2, 3 taches** : rendues telles quelles ;
- **au dela de trois** : le plafond tient, et il est **demande au port** (`limite: 3`), pas tronque a
  l'ecran ;
- **une tache portant un range Coran** : « À renforcer : Sourate 2, versets 255 à 257 » ;
- une consigne courte de l'enseignant **remplace** la plage : il a ecrit plus precis que nous ;
- le travail nominatif **d'un autre eleve** ne s'affiche pas.

### 2.2 Reprendre le cours (spec 4.4) — meme fichier, 3 tests

Action **contextuelle** : absente quand le groupe n'a pas de position connue, en tete quand il en a une,
et elle **prend l'une des trois places** au lieu de repousser le plafond. Aucune intention pedagogique
ne lui est collee : reprendre n'est pas une sixieme intention.

### 2.3 Post-cours enseignant (spec 9.5) — `post_cours_test.dart`, 18 tests

- la duree est **celle de la base** (52 min), pas l'intervalle debut/fin (60 min) : le depot sait deja
  en deduire quatre, une cinquieme donnerait deux chiffres pour le meme cours ;
- les **exceptions passent devant**, et la regle vient d'Agent E
  (`EtatPresenceProjete.demandeUneReaction`), pas d'une seconde echelle ;
- « tout est nominal » n'est **jamais** affirme sur une seance dont on ne sait rien ;
- un **roster non projete** ne bloque pas la cloture : c'est l'etat courant du depot, pas une panne ;
- **hors ligne** : le compte rendu part en file, `SortCahier.enFile`, la file porte une ligne, et le
  **rejeu garde la meme cle d'idempotence** ;
- un cahier **deja depose** ne se redepose pas ;
- le travail propose devient une assignation **a la validation**, jamais avant ; un echec d'ecriture
  est nomme (`travailNonPose`) **et le compte rendu reste parti**.

### 2.4 Micro-feedback (spec 12.1) — `rotation_feedback_test.dart` + `feedback_test.dart`, 19 tests

- **rotation prouvee** : un cycle complet sans repetition, la question suivante rouvre le cycle et
  **jamais avant**, trois cycles verifies un par un, et un identifiant devenu inconnu ne gele pas la
  rotation ;
- **echantillonnage** : une seance sur quatre par defaut, une cadence nulle eteint le feedback, une
  seance inconnue ou deja notee ne demande rien ;
- **une carte ignoree ne consomme pas une question** : un eleve silencieux ne ferait pas defiler le
  catalogue de tout son groupe ;
- **seuil** : sous le seuil, `repartition` vaut `null` et `visibleParEnseignant` est faux ; au seuil, la
  repartition sort et somme a 1 ; et une tendance visible **ne peut pas etre construite** sans seuil
  (assertion du contrat).

### 2.5 Signalement (spec 12.2) — `signalement_test.dart` + `feuille_signalement_test.dart`, 14 tests

- le contexte est **prerempli** : groupe, seance, eleve, enseignant, sans qu'aucun soit saisi ;
- `familySummary == null` est un **cas normal** ; une chaine vide vaut absent ;
- **la note interne ne fuit pas** : la verification porte sur la charge utile exacte
  (`ResumeFamilleSignalement.versJson()`), pas sur un ecran ;
- **transmettre sans message famille echoue**, et un `StudentConcern` transmis sans message est
  impossible a construire (assertion) ;
- la note interne **reste attachee** au signalement cote administration : ce qui ne doit pas fuir, c'est
  ce qui **part**.

### 2.6 Les quatre surfaces — 15 tests de widget, tous a 390 x 844

Etat vide qui ne propose rien, plafond de trois, reprise en tete, action remontee a l'hote telle
quelle ; carte de feedback **absente** hors echantillon, trois choix et **aucun champ de commentaire**
quand elle est la, un seul tap qui remercie ; panneau post-cours prerempli, position et plage lues en
clair, cloture en un tap, et **« il partira des le retour du reseau »** hors ligne ; feuille de
signalement avec ses deux champs separes et son bouton inerte tant que la note interne est vide.

---

## 3. Ce qui est mocke, et ce que cela veut dire

| Double | Ou | Ce qui manque en face |
|---|---|---|
| `FeedbackMemoire` | `lib/core/tc_parcours/feedback_memoire.dart` | table `session_feedback`, vue d'agregat, RPC d'echantillonnage |
| `SignalementMemoire` | `lib/core/tc_parcours/port_signalement.dart` | table `student_concern` et sa vue famille |
| `ContenuSeanceIndisponible` | `lib/core/tc_parcours/source_contenu_seance.dart` | persistance de `SharedContentState` (Agent F) et lecture **par groupe** |
| Les quatre providers | chacun dans son fichier | ils **echouent** avec un message d'assemblage, ils ne rendent pas un double |

**Le choix de faire echouer les providers est delibere.** Un double en memoire rendu en production
ferait croire a une collecte de feedback, a un signalement transmis ou a un cours cloture qui n'ont pas
eu lieu. Un `UnimplementedError` qui nomme la composition attendue est plus honnete qu'un silence.

En revanche, **le post-cours n'est pas un double** : `PostCoursDepuisCahier` lit le vrai
`brouillon_cahier()` par `ServiceEnseignant` et ecrit par le vrai `SoumissionCahier`. Sa partie
hors ligne fonctionne aujourd'hui, avec la file drift du chantier enseignant.

---

## 4. Decisions notables, et pourquoi

### 4.1 Le cahier `ENS-04` n'a pas ete refait

Le chantier enseignant a livre le post-cours prerempli : `brouillon_cahier()`, `BrouillonCahier`,
`VueCahier`, `CahierPage`, `SoumissionCahier`, `FileRapports`, cle d'idempotence, contrainte C9, file
drift. **Tout cela existe, est teste, et repond deja a la moitie de la section 9.5.**

Le lot H s'y **branche** au lieu de le doubler : `PostCoursDepuisCahier` compose le constat existant
avec ce qui manquait -- la position de reprise, les plages travaillees, le travail propose -- et ecrit
par le meme chemin. **C'est de la que vient le hors ligne du lot H** : il n'a pas ete reecrit.

Consequence : `lib/features/cahier/` et `lib/core/enseignant/` sont **lus et importes**, jamais
modifies. Aucune ligne du chantier enseignant n'a bouge.

### 4.2 Un constat est retenu entre `preparer` et `enregistrer`

`PostCoursDepuisCahier` garde le dernier `BrouillonCahier` lu. **Ce n'est pas une optimisation** :
l'enregistrement a besoin des identifiants d'eleves pour composer les decisions du cahier, or hors
ligne `brouillon_cahier()` ne repond plus. Sans ce souvenir, le chemin hors ligne -- celui pour lequel
la file existe -- serait le seul a echouer. Un seul constat est garde : un enseignant cloture une
seance a la fois.

### 4.3 `TeacherStudentProjection` a ete stube, malgre l'AMENDEMENT 2

L'AMENDEMENT 2 conseille de ne pas stuber un port dont la chaine de types est ouverte. Pour le lot H
elle est **close** : `ContentPosition` et `LearningAssignment` sont deja stubes parce que `PostCoursVM`
en a besoin par ailleurs, et il ne restait que trois types de valeur. Surtout, `PostCoursVM` porte **par
contrat** `List<TeacherStudentProjection>` : ne pas le stuber aurait oblige a faire diverger un contrat
**produit** par le lot H, ce qui coute plus cher qu'une copie verifiee mot pour mot.

### 4.4 `SourceContenuSeance` n'est pas un stub, et c'est l'AMENDEMENT 2 applique

`SharedContentState` traine `MarqueurSemantique` (Agent D) et `ModeAffichagePartage` (Agent F), dont le
lot H n'a **aucun** usage : le recopier aurait fait trois occasions de diverger pour deux lectures. Le
lot H expose donc une surface etroite de trois methodes, **dans son propre namespace**, et Agent Z ecrit
l'adaptateur de dix lignes. Le choix est documente dans le fichier lui-meme.

### 4.5 La tendance agrege cinq volets dans une seule repartition

Le contrat (section 15) donne un `TendanceFeedback` **sans axe de question**. Avec cinq questions en
rotation, « rythme trop rapide » et « cours difficile » tombent donc dans la meme case. Le lot H a
implemente ce que le contrat dit -- une **tonalite generale** -- et demande l'arbitrage en section 2.3
de son CONTRACT_REQUEST. **Aucun ecran ne presente cet agregat comme une note sur un volet precis.**

### 4.6 Ce qui n'a pas ete construit, volontairement

- **Aucune route, aucun ecran.** Les quatre surfaces du lot H remplissent des slots que d'autres
  possedent. Une route sans entree de navigation n'existe pas, et `nav_shell.dart` est plafonne a
  quatre destinations dont l'enseignant occupe deja les quatre (`D-04`). Poser une route aurait produit
  un ecran inatteignable.
- **Aucun ecran « Mes signalements ».** Le port le rend (`mesSignalements`), la spec ne le demande pas.
- **Aucune correction de `lib/features/presence_correction/`.** L'ecran existe, l'adaptateur manque :
  c'est un CONTRACT_REQUEST, et la correction de presence n'appartient pas au flux academique.
- **Aucune icone, aucune dependance, aucune migration.**

---

## 5. Ce qu'Agent Z devra brancher

### 5.1 Les quatre providers

| Provider | Composition attendue |
|---|---|
| `portTravailAVenirProvider` | `TravailAVenir(portAssignations (D), adaptateur SourceContenuSeance)` |
| `portPostCoursProvider` | `PostCoursDepuisCahier(serviceEnseignant, soumissionCahier, portRosterEnseignant (E), SourceContenuSeance, portAssignations (D), profilEnseignantId)` |
| `portFeedbackProvider` | implementation Supabase (tables demandees), ou `FeedbackMemoire` en recette |
| `portSignalementProvider` | implementation Supabase (table demandee), ou `SignalementMemoire` en recette |

### 5.2 Les quatre surfaces

- `BlocAvantProchainCours(groupeId, studentId, onAction)` dans le slot `avantProchainCours` de
  `GroupHomeVM`. `onAction` reste a brancher sur la Bibliotheque d'Agent B : sans lui, le bloc est
  **lisible mais inerte**, et c'est un etat assume.
- `CarteFeedbackSeance(sessionId)` en sortie de seance, cote eleve et tuteur. Elle ne s'affiche
  d'elle-meme que si le serveur echantillonne : **aucune condition a poser a l'appelant**.
- `FeuilleSignalement.ouvrir(context, groupeId, academyId, prenomEleve, sessionId)` depuis l'action
  « Signaler un besoin » de la fiche d'Agent E.
- `PanneauPostCours(sessionId, onTermine)` **sous** le constat du cahier `ENS-04`, pas a sa place.

### 5.3 Les huit stubs a supprimer

Tous sous `lib/core/tc_parcours/ports_externes/`. Chacun porte son chemin canonique en premiere ligne.

### 5.4 L'i18n

`docs/teaching-core/i18n/tc_i18n_H.json` porte l'arbre `tc.parcours.*`, puis la facade
`LibellesParcours` disparait. **Deux clefs de plus que de constantes** : la facade collapse le singulier
et le pluriel dans une seule fonction (`plageVersets`, `plagePages`), la ou slang veut
`versets`/`versetUnique` et `pages`/`pageUnique`.

---

## 6. Limites honnetes

1. **Rien n'est branche sur un serveur.** Trois tables manquent, et les quatre providers echouent en
   production. Le lot est utilisable en recette, pas en production.
2. **`rangesTravailles` est toujours vide aujourd'hui**, donc `travailPropose` aussi : sans persistance
   de l'etat partage, le post-cours ne propose ni position ni travail. Le code est complet et teste avec
   un double ; c'est la donnee qui manque.
3. **`PostCoursVM.participants` est vide tant qu'Agent E n'a pas sa projection serveur.** Le panneau se
   tait alors au lieu d'affirmer que la seance etait deserte.
4. **Le filtre par eleve du bloc « Avant le prochain cours » est pose apres coup**, faute de parametre
   `studentId` sur `PortAssignations.aVenir` : la liste peut compter moins de trois actions quand le
   groupe porte du travail nominatif pour quelqu'un d'autre. Declare, teste, et demande en 2.1 du
   CONTRACT_REQUEST.
5. **`PanneauPostCours` teste le type de l'implementation** (`port is PostCoursDepuisCahier`) pour
   choisir entre « envoye » et « en file », parce que `PortPostCours.enregistrer` rend `void`. C'est un
   pis-aller assume ; il disparait avec l'amendement 2.2.
6. **La regle de proposition de travail est simple et assumee** : ce qui vient d'etre vu se revoit,
   intention « À revoir », plafonne a trois. Aucune heuristique pedagogique n'a ete inventee.
7. **La tendance melange cinq volets** (voir 4.5).
8. **Le double `FeedbackMemoire` raisonne par groupe, pas par personne** pour la rotation : un seul
   appareil, un seul utilisateur. L'implementation serveur devra, elle, suivre l'historique **par
   appelant**, faute de quoi deux eleves du meme groupe se voleraient leurs questions.
9. **Le stub `ContentRange` porte l'ordre de section par rang de texte** d'Agent B : pour un corpus ou
   l'identifiant de section n'est pas un ordre de lecture, une plage de sections n'a pas de sens. Herite,
   pas introduit.

---

## 7. Defauts pre-existants croises, non corriges

1. **`tool/verifier_jetons.dart` est rouge sur la baseline** : 10 violations, **zero dans les fichiers
   du lot H**. Cinq M-dash dans des commentaires (`core/widgets/menu_filtre.dart`, `nav_shell.dart` x3,
   `features/admin_dossiers/dossiers_page.dart`, `features/admin_journal/journal_page.dart`), un
   `IconButton` (`nav_shell.dart:461`) et deux `onTap` nus (`nav_shell.dart:513`,
   `sous_navigation_domaine.dart:63`).
2. **`lesson_reports_teacher_write` ne verifie pas l'appartenance de la seance** (0001:1064-1069). Le lot
   H ecrit dans cette table par le chemin existant : il herite du defaut sans l'aggraver.
3. **`supabase/migrations/0029` est ecrite mais pas appliquee** : `dossiers_en_attente()` livre nom et
   prenom a un appelant anonyme. Signale par le BASELINE_ADDENDUM, hors mission.
4. **`flutter pub get` reecrit trois fichiers generes Windows** (`windows/flutter/generated_*`) par
   simple normalisation de fins de ligne, sans changement de contenu. Restaures par
   `git checkout --` avant le commit : ils ne figurent pas dans le lot.

---

## 8. Commandes rejouables

```powershell
cd D:\RA_TC\h
flutter analyze lib test          # No issues found!
flutter test test/teaching_core/h # 71 tests, All tests passed!
dart run tool/verifier_jetons.dart # 10 violations, aucune dans tc_parcours/ ni tc_flux_academique/
git status --porcelain            # docs/teaching-core/, lib/core/tc_parcours/,
                                  # lib/features/tc_flux_academique/, test/teaching_core/
```
