# Ce que la lettre aux candidats dit et que l'application ne fait pas (20/11/2026)

Ordre du directeur (20/11/2026) : « Pour les nouvelles règles introduites qui ne font pas partie de
l'app tu les mentionnes dans le repo... Comme tout ce qui a été ajouté ici et qui n'existe pas ou
contradictoire. »

La lettre (`LETTRE-fr.md`) est validée par le directeur. Chaque ligne ci-dessous est une phrase de la
lettre qui n'a **pas** son équivalent dans l'application, ou qui contredit une règle écrite. Tant
qu'une ligne est ouverte, la lettre promet quelque chose que l'application ne tient pas.

**Avant de toucher à la paie, au remplacement, aux absences d'un enseignant, aux langues de cours, aux
remises ou au droit de lire la lettre : lire ce fichier.** Une ligne se ferme par une décision écrite
dans la source de vérité nommée, puis par le code ; on note alors la PR.

Légende de l'état : **contraire** (une règle écrite dit autre chose) ; **absent** (rien dans
l'application) ; **non vérifié** (peut exister, personne ne l'a lu dans le code le 20/11).

## Paie

| # | Ce que dit la lettre | État | Source à changer |
| --- | --- | --- | --- |
| P1 | Part de l'enseignant : 47 % pour les adultes, **environ 45 % pour les enfants** (suivi des enfants après le cours) | contraire : 47 % pour tous (décision du 19/10, base) | `DECISION-TARIFS-2026-10-18.md`, `tarifs-2026-10-18.json`, politique commerciale en base |
| P2 | Élève absent : l'enseignant reçoit **la moitié de sa part** pour la séance | contraire : `absence_eleve_payee: false` | mêmes sources, calcul de la paie |
| P3 | Les **montants** en dollars sont donnés aux candidats inscrits | contraire : pourcentages seulement (décision du 22/10) | `DECISION-TARIFS` (§22/10), `savoir-rewayah` §4 |
| P4 | Le remplaçant reçoit **100 %** de la paie de la séance | non vérifié | calcul de la paie, remplacements |
| P5 | Les gains d'un remplaçant sont versés à partir d'un **montant minimum** fixé par la direction | absent ; montant non fixé | décision à prendre |
| P6 | Une classe reçue **en cours de mois** : payée sur les séances restantes | non vérifié | calcul de la paie |
| P7 | La paie du mois **attend** tant que le point de fin de séance manque | non vérifié (la règle du 18/10 parlait du cahier de la semaine, remplacé par le point le 13/11) | paie, `programme-rewayah` §5 |
| P8 | Remise aux **nouveaux convertis**, jamais imputée à l'enseignant | absent du fichier des tarifs | `tarifs-2026-10-18.json` |
| P9 | Versement au plus tard le **5** du mois suivant ; fermetures (Ramadan, Aïd) et mois de pause d'un élève non payés | conforme aux textes ; non vérifié dans le calcul | paie |

## Langues et classes

| # | Ce que dit la lettre | État | Source à changer |
| --- | --- | --- | --- |
| L1 | **L'arabe est une langue de cours** ; une classe d'élèves arabophones reçoit un enseignant arabophone | contraire : décision du 22/10 (`savoir-rewayah` §5, `langues_cours`) | décision à écrire, `langues_cours`, compétences |
| L2 | Une classe s'ouvre à **3 élèves** | contradiction déjà connue : 3 (tarifs) contre 4 (programme) | `programme-rewayah` §5, base |
| L3 | L'académie **étudie des cours individuels**, sans date | absent (annonce seulement) | aucune, tant que rien n'est décidé |

## Assiduité, remplacement, absences

| # | Ce que dit la lettre | État | Source à changer |
| --- | --- | --- | --- |
| A1 | Salle ouverte 20 min avant ; avertissement à 3 min ; alerte à 8 min ; remplaçant à 11 min au plus | conforme aux réglages `remplacement.*` (lus le 20/11) | si un réglage change, la lettre change |
| A2 | Un enseignant remplacé souvent reçoit des **avertissements**, puis perd la classe | absent ; nombre d'avertissements non fixé | décision à prendre, puis code |
| A3 | Une **absence prévenue** à l'avance (date de départ et de retour) : remplaçant temporaire ; non-retour à la date = perte de la classe | non vérifié | remplacements |
| A4 | Perdre une classe **ne fait pas perdre l'accès** : l'enseignant se déclare disponible pour d'autres classes | non vérifié | attribution des classes |
| A5 | **Enseigner ailleurs est permis**, sauf aux mêmes heures | absent (règle nouvelle) | à écrire (code de conduite ou contrat) |
| A6 | Hors de la salle **plus de 30 secondes** pendant son cours : l'enseignant est sorti et la **direction prévenue** | absent pour l'enseignant (la règle des 30 s existe pour les élèves, retirée de l'entretien) | salle |
| A7 | Visite de contrôle sans prévenir ; une enseignante est **toujours visitée par une femme** | visite : existe ; choix d'une visiteuse : non vérifié | contrôle |

## Parcours du candidat

| # | Ce que dit la lettre | État | Source à changer |
| --- | --- | --- | --- |
| C1 | Une **formation à l'application** avant la première classe | non vérifié | parcours enseignant |
| C2 | Un **matricule officiel** (le directeur veut le format « #xxxxxx@ra », la lettre ne donne pas de format) | contraire : `RA-26-4817` (`DECISION-IMMATRICULATION-2026-10-12.md`) ; lot à part, « pas urgent » | décision et lot à part |
| C3 | Retrait de la candidature, suppression des données par **support@rewayahacademy.com** ; reprise possible pendant 7 jours | reprise : en production (#662) ; suppression sur demande : non vérifié | |
| C4 | Praxis **en pause**, en réglage avant relance | conforme au 20/11 | |

## Qui peut lire la lettre

| # | Règle du directeur (20/11) | État |
| --- | --- | --- |
| D1 | **Seulement les enseignants, et les candidats enseignants qui ont accepté leurs accords** | dans `main` (PR 665), non prouvé par le directeur |
| D2 | **Le serveur doit décider aussi** | dans `main` (PR 665) ; `lire_lettre_candidats` installée en production le 21/11/2026 et vérifiée par empreinte ; non prouvé par le directeur |

## Interactions du guide (directeur, 20/11/2026, 23 h)

| # | Règle | État |
| --- | --- | --- |
| I1 | La page ne s'appelle plus « lettre » | en cours : « Guide de l'enseignant » (choix de l'agent, à confirmer) |
| I2 | Les lecteurs commentent ; la direction et Praxis lisent et répondent ; les autres lecteurs ne voient pas les commentaires | serveur et page de la direction écrits le 21/11/2026 (GUIDE-COMMENTAIRES, migration `20261130972000`, page « Commentaires du guide » sous Opérations, `/admin/operations/guide`). **Circuit à part, hors de la messagerie** (directeur, 21/11). Reste : Praxis qui répond (en pause), un badge des fils en attente |
| I3 | « J'aime » et « Pas clair » par partie, nombres visibles de tous | serveur écrit le 21/11/2026 (GUIDE-AVIS, migration `20261130971000`, `lire_interactions_guide`, `donner_avis_guide`) ; « Commenter » masqué tant que I2 n'existe pas |
| I4 | Praxis reste en haut et suit la lecture | fait sur la branche : la tête de page (titre court « Guide de l'enseignant » et bande de Praxis) reste fixe, le corps défile seul. **Écart daté à `DECISION-DEFILEMENT-2026-11-01.md`** (« rien de gros collé au-dessus du contenu »), **confirmé par le directeur le 21/11/2026 (« Oui, tête fixe »)**, pour cette page seulement ; la tête reste sous les 160 points de WEB-BUREAU B6 (garde verte) |
