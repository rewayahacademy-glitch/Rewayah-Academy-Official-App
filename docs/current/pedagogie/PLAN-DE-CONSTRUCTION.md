# Plan de construction de la charte

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**

> **Qui livre (directeur, 12/11/2026).** « Je ferai les migrations, pour le reste c'est à toi, y compris les fusions. » L'architecte ouvre la pull request et fusionne, CI verte exigée, après revue indépendante du lot ; le directeur installe les migrations, à partir d'une page à coller (`tool/page_migrations/generer.py`) ; « fait » reste ce que le directeur voit en production (`ARBITRAGES.md`, partie 8, C3).
>
> **Fait à connaître.** Le garde-fou du dépôt (`.claude/hooks/garde.py`, décrit dans `CLAUDE.md`) refuse aujourd'hui aux agents toute pull request vers `main` et toute fusion ; il ne se modifie que sur ordre du directeur. Tant qu'il n'est pas adapté, l'architecte prépare les lots sur des branches, un par lot, prêts à fusionner.

Ce plan découpe en dix lots, dans l'ordre, le passage de l'application d'aujourd'hui à la charte (`CHARTE-ECOLE.md`, `REGLAGES.md`, `SCENARIOS-ELEVES.md`, `EVALUATIONS.md`, `MOTEUR-DE-SUIVI.md`). L'ordre est imposé par l'architecte.

## L'état mesuré en production le 12/11/2026

3 classes actives, 5 élèves ; programme : 1 version en brouillon jamais publiée, 1 niveau vide ; aucune classe n'a de niveau ; 0 décision de niveau, 0 sourate validée, 0 document en bibliothèque, 0 évaluation, 0 compte rendu aux familles, 0 travail donné ; 11 cahiers de séance ; 85 notifications, aucune pédagogique ; aucune table de calendrier, de fermetures ni d'attestations ; les fonctions de lecture du suivi sont installées.

**Il n'y a donc presque rien à migrer : c'est le moment de refaire le socle proprement.** Les seules données vivantes à garder sont les 3 classes, les 5 élèves et les 11 cahiers de séance.

**Fait hérité, signalé une fois.** Les 3 classes actuelles (5 élèves) sont sous le seuil d'ouverture de 4 élèves (DÉCIDÉ 30/09). Elles existaient avant la charte ; aucun lot ne les ferme ni ne les modifie automatiquement.

## Les lots en une vue

| Lot | Nom | Taille | Dépend de | Branches non livrées |
|---|---|---|---|---|
| 1 | SOCLE-PROGRAMME | gros | aucun | `parcours-inscrits-main` reprise ; `ma-progression-main` adaptée |
| 2 | CALENDRIER-ET-PAUSES | moyen | 1 | aucune |
| 3 | BIBLIOTHEQUE-UNE | moyen | 1 | aucune |
| 4 | LECTEUR | moyen | 3 | aucune |
| 5 | ESPACE-APPRENDRE | moyen | 1, 3, 4 ; la fiche complète vient du lot 6 | `ma-progression-ecran-travail` adaptée (avec le lot 6) |
| 6 | SUIVI-UNIQUE | gros | 1 ; 5 pour les raccourcis | `ma-progression-ecran-travail` adaptée ; `corriger-sourate-travail` reprise et adaptée ; `corriger-sourate-direction-travail` écartée |
| 7 | MOTEUR-1 | gros | 1, 2, 3, 6 | aucune |
| 8 | EVALUATIONS-ET-LIVRET | gros | 1, 5, 6 | aucune |
| 9 | MOTEUR-2 | moyen | 7, 8 | aucune |
| 10 | NETTOYAGE | moyen | 1 à 9 | aucune |

**En parallèle** : les lots 2 et 3 dès que le lot 1 est fusionné ; puis les lots 4 et 6 ; puis les lots 7 et 8. Le lot 5 attend 3 et 4 ; le lot 7 attend 1, 2, 3 (lectures enregistrées de « Rattraper ce cours ») et 6 ; le lot 9 attend 7 et 8 ; le lot 10 vient en dernier.

## Lot 1 · SOCLE-PROGRAMME

- **But** : le programme des bases existe en données, fidèle aux décisions, publié, et chaque élève a une seule étape lue de la même façon par tous.
- **Ce qu'on voit de neuf** : la direction voit le programme des bases publié (4 étapes, objectifs, durée prévue et date limite de chaque étape par tranche d'âge) et le niveau de chaque classe ; l'élève et le tuteur voient son étape, la date limite de cette étape (le tuteur seul avant 10 ans) et l'horizon du niveau ; l'enseignant voit l'étape de chaque élève à côté de son nom, la même partout.
- **Réutilisé** : `programme_versions` et les étapes existantes (la version en brouillon est complétée puis publiée) ; `suivi_pedagogique_eleve` et `private.etape_eleve`, qui deviennent la seule lecture ; `private.sourates_des_bases` ; les codes techniques d'étape comme identité stable. Branche `claude/parcours-inscrits-main` : **reprise** telle quelle, en tête du lot, parce qu'elle corrige l'accueil des inscrits déjà dans une classe et ne touche pas au programme ; avant installation, comparer la définition de `v_parcours_onboarding` en production, comme son fichier l'exige. Branche `claude/ma-progression-main` : **adaptée** ; on garde l'idée d'une lecture serveur unique qui appelle `suivi_pedagogique_eleve` et ses tests de refus (aucune lecture hors de l'élève, de son tuteur et de ses enseignants) ; on écarte sa table `programme_etape_reglages`, parce que les heures de révision sont un réglage par âge (`REGLAGES.md`), pas par étape, et qu'une seconde clé d'étape contredirait l'arbitrage n° 1.
- **Créé** : le fait unique « étape en cours » par élève (étape, date d'entrée dans l'étape, date limite de l'étape ; l'horizon du niveau en est déduit), créé seul à l'entrée en classe (étape 1 pour un débutant, sinon celle fixée par la direction après l'entretien de lecture) ; le niveau de chaque classe, posé seul ; la durée prévue et la date limite de chaque étape par tranche d'âge (tableau 1 bis) ; l'archivage automatique de la version précédente à la publication.
- **Retiré** : rien encore (les anciens calculs restent jusqu'au lot 10, mais plus aucun écran ne les lit).
- **Migrations** : oui, additives ; aucune suppression.
- **Preuve** : le directeur ouvre en production la fiche d'un des 5 élèves comme direction, comme enseignant et comme tuteur, et lit la même étape et la même date limite d'étape ; il voit le programme des bases publié, une seule version publiée, et le niveau de chacune des 3 classes.

## Lot 2 · CALENDRIER-ET-PAUSES

- **But** : l'année de l'école et la pause d'un mois existent en réglages, et la date limite recule seule quand il le faut.
- **Ce qu'on voit de neuf** : la direction saisit une fois par an les fermetures, les rencontres de récitation et les dates d'évaluation ; le tuteur (ou l'adulte) demande une pause d'un mois et la voit acceptée ; l'onglet Programme montre les dates qui concernent l'élève ; la direction accorde une pause d'exception.
- **Réutilisé** : `app_config` pour les valeurs ; `timezone_iana` ; le fait « étape en cours » du lot 1.
- **Créé** : `calendrier_ecole` (fermetures, rencontres, dates d'évaluation) ; `pauses_eleve` (pause d'un mois, pause d'exception, plafond de 2 mois sur 12) ; le recul de la date limite de l'étape pour une pause ou une fermeture. Une interruption temporaire accordée (07/11) entre comme une pause, pour la pédagogie seulement (`ARBITRAGES.md`, n° 56 et C17) ; rien d'argent dans ce lot (lot d'harmonisation de l'argent réservé par le directeur le 07/11).
- **Retiré** : rien.
- **Migrations** : oui, additives ; aucune suppression.
- **Preuve** : le directeur publie la fermeture de l'Aïd al-Adha et voit la date limite de chaque élève reculer d'autant ; il demande une pause d'un mois pour un élève de test et voit la date limite reculer d'un mois.

## Lot 3 · BIBLIOTHEQUE-UNE

- **But** : un seul catalogue de documents pour toute l'application, avec deux rayons, où le Coran est un document.
- **Ce qu'on voit de neuf** : la direction dépose un document, un audio, une vidéo ou un lien externe, choisit son rayon et son étape ; l'élève voit « Documents des cours » en haut et « Pour aller plus loin » en bas (vide, sans prix) ; l'enseignant ouvre la même bibliothèque depuis le tiroir de la salle.
- **Réutilisé** : `library_resource` et ses écrans (`features/tc_catalogue`, `features/admin_pedagogie_bibliotheque`) ; le Coran déjà servi par `features/tc_mushaf`, inscrit comme document.
- **Créé** : les types audio, vidéo, lien externe ; le rayon ; le rattachement à une étape ; le Coran comme fiche du catalogue.
- **Retiré** : l'étagère séparée de la salle (`etagere_supports`, `supportsDeSalleProvider`) est rebranchée sur `library_resource` ; ses tables restent jusqu'au lot 10.
- **Migrations** : oui, additives ; aucune suppression.
- **Preuve** : le directeur dépose un audio rattaché à l'étape 1, le voit dans la bibliothèque d'un élève et dans le tiroir de la salle, au même endroit ; le Coran apparaît comme un document parmi les autres.

## Lot 4 · LECTEUR

- **But** : un seul lecteur performant pour texte, audio et vidéo, qui reprend où l'élève s'était arrêté.
- **Ce qu'on voit de neuf** : l'élève ouvre un document, un audio ou une vidéo dans le même lecteur ; il retrouve sa page ou sa minute en revenant ; un lien externe s'affiche en petite carte avec sa description.
- **Réutilisé** : les rendus existants de `features/tc_catalogue` (`rendu_ressource`, `detail_ressource_page`) et le lecteur du Coran de `features/tc_mushaf` ; `student_reading_position` pour la reprise personnelle (elle ne fait plus foi pour la classe).
- **Créé** : le lecteur unique (texte, audio, vidéo), la reprise de lecture pour l'audio et la vidéo, la carte de lien externe ; pilotable au clavier, en miroir en arabe.
- **Retiré** : les rendus en double par type, dès que le lecteur unique les remplace.
- **Migrations** : oui si la reprise d'un audio ou d'une vidéo demande un champ de plus ; additive ; aucune suppression.
- **Preuve** : le directeur écoute la moitié d'un audio sur son téléphone, ferme l'application, la rouvre et reprend à la même minute ; il ouvre une vidéo et un lien externe depuis la bibliothèque.

## Lot 5 · ESPACE-APPRENDRE

- **But** : le hub « Apprendre » à trois onglets, Bibliothèque, Programme, Mon livret, pour l'élève adulte et pour l'enfant.
- **Ce qu'on voit de neuf** : l'adulte et l'enfant (en Interface guidée) ouvrent « Apprendre » ; la Bibliothèque se montre en grille ou en liste, avec un filtre par type ; l'onglet Programme montre l'étape et le chemin entier de son parcours (lot 1), puis les dates ; il reçoit la fiche de suivi complète au lot 6 ; « Mon livret » existe (vide tant que le lot 8 n'est pas là) ; le tuteur ouvre le même espace depuis le profil de l'enfant.
- **Réutilisé** : la navigation décidée (Aujourd'hui · Apprendre · Suivi · Profil) ; `features/mon_espace_adulte`, `features/accueil_eleve`, `features/suivi_famille` ; les lots 1, 3 et 4. Branche `claude/ma-progression-ecran-travail` : **adaptée**, avec le lot 6 ; ses pièces d'écran (carte de suivi, section de l'étape) entrent dans l'onglet Programme ; on écarte sa saisie des heures de révision par étape (valeur de `REGLAGES.md`) et ses doublons de l'onglet « Suivi ».
- **Créé** : les trois onglets ; le choix grille ou liste gardé sur l'appareil ; les filtres par type.
- **Retiré** : l'onglet « Apprendre » réduit au Coran pour l'adulte ; l'onglet « Coran » de l'enfant (le Coran devient un document de la Bibliothèque).
- **Migrations** : non.
- **Preuve** : le directeur ouvre « Apprendre » avec un compte adulte et avec un compte enfant, passe de la grille à la liste, filtre les audios, et retrouve le Coran dans la Bibliothèque.

## Lot 6 · SUIVI-UNIQUE

- **But** : la fiche de suivi de l'élève est un seul objet, avec une seule position, une seule échelle et un seul travail, atteint par des raccourcis.
- **Ce qu'on voit de neuf** : l'enseignant confirme la position en moins de 20 secondes et ne signale que les exceptions ; « Stable » apparaît seul quand il est mérité ; le travail confirmé arrive dans « Avant le prochain cours » et dans l'emploi du temps de révision ; l'enseignant, la direction et le tuteur ouvrent la même fiche depuis le profil de l'élève, et depuis la classe et la salle.
- **Réutilisé** : `classe_position_reprise` (absorbe `classe_position_support`) ; `lesson_reports` et `cahier_observations` ; `sourates_validees` ; `learning_assignment`, désormais écrit à la confirmation ; `rythme_classe` pour l'indicateur de classe. Branche `claude/corriger-sourate-travail` : **reprise et adaptée** ; le retrait d'une sourate par l'enseignant auteur, avec motif et trace, est conforme à la charte ; son délai codé en dur (24 heures, décision du garde-cap du 11/11) devient le réglage de `REGLAGES.md` (7 jours, ARBITRÉ le 12/11), lu dans `app_config`. Branche `claude/corriger-sourate-direction-travail` : **écartée** ; elle donne à la direction le pouvoir de retirer une sourate sans limite de temps, alors que la direction voit sans valider (DÉCIDÉ 11/11) et que seule l'erreur de l'enseignant auteur se corrige ; on ne garde que la lecture des sourates de la classe sur la fiche de classe. Branche `claude/ma-progression-ecran-travail` : voir lot 5.
- **Créé** : la fiche de suivi unique ; « Stable » calculé par le serveur ; l'écriture du travail dans `learning_assignment` ; les raccourcis.
- **Retiré** : les échelles du cahier à 4 niveaux et 6 faiblesses et la projection famille à 2 états (plus lues) ; le second circuit du travail (`travail_maison` n'est plus lu) ; la carte de suivi recopiée dans « Suivi ».
- **Migrations** : oui, additives (dont le fichier `20261123820000_corriger_sourate.sql` de la branche reprise : c'est le nom d'une migration qui existe déjà sur cette branche, gardé tel quel ; ce n'est pas un horodatage) ; aucune suppression.
- **Preuve** : après un vrai cours, le directeur voit la position confirmée par l'enseignant dans la fiche de l'élève, côté tuteur et côté direction, et le travail dans « Avant le prochain cours » ; il ouvre cette même fiche depuis la salle et depuis le profil de l'élève.

## Lot 7 · MOTEUR-1

- **But** : le moteur reconnaît seul l'absence, le cours non rattrapé, le travail non fait et la date limite, et envoie le message de la semaine, sans IA et sans saisie de plus.
- **Ce qu'on voit de neuf** : après une absence ou une présence partielle, « Rattraper ce cours » apparaît chez l'élève et le tuteur, avec la page, la lecture enregistrée (lot 3) et le travail ; le bouton « J'ai rattrapé ce cours » ; en salle, la marque discrète « a rattrapé » ou « n'a pas rattrapé » ; les messages des trois seuils d'absences ; le rythme « À surveiller » et les rappels ; le message de la semaine du samedi ; une seule liste « à faire » par personne.
- **Réutilisé** : `etat_presence`, `sessions`, `private.ses_cloturer_seances_echues` ; `notifications`, `push_sortants`, `courriels_sortants` ; `app_config` ; tout ce que liste `MOTEUR-DE-SUIVI.md`, partie 8.1.
- **Créé** : `suivi_etats_eleve`, `suivi_regles`, `suivi_declenchements` (une fois pour un même fait), `suivi_taches`, `cours_rattrape`, `travail_fait` ; les règles 1 à 5, 13 (éteinte tant que le marquage « fait » n'existe pas), 15, 16 et 32 ; plafond, heures calmes et protection des mineurs dans `private.suivi_notifier` ; le calcul de nuit.
- **Retiré** : les notifications écrites pour un mineur qui ne peut pas les lire (portée `soi` d'un enfant dans `notifier_classe`).
- **Migrations** : oui ; ajout des codes `suivi_*` à la contrainte `notifications_evenement_check`, qui se fait par `DROP CONSTRAINT` puis `ADD CONSTRAINT` : le mot de suppression déclenche la seconde confirmation de Supabase, à prévoir ; aucune donnée supprimée.
- **Preuve** : un élève de test manque un cours en production ; le directeur voit « Rattraper ce cours » chez le tuteur, le message reçu au bon moment, puis la marque en salle au cours suivant ; à la deuxième absence, le message du premier seuil arrive une seule fois.

## Lot 8 · EVALUATIONS-ET-LIVRET

- **But** : le petit bilan, l'examen de fin des bases, les résultats publiés, la réévaluation et l'attestation existent, et « Mon livret » les montre.
- **Ce qu'on voit de neuf** : l'enseignant marque « prêt pour un petit bilan » et le fait passer en cours normal ; la direction planifie l'examen et désigne l'évaluateur ; le résultat est publié en une des trois phrases et trois lignes ; la famille demande une réévaluation ; l'attestation des bases, signée par le directeur, se télécharge et se vérifie par son code ; « Mon livret » montre résultats, bilans et attestations.
- **Réutilisé** : `evaluations`, `evaluation_publications`, `publier_evaluation` ; `features/admin_pedagogie_evaluations` ; l'onglet du lot 5.
- **Créé** : la suite des trois résultats, la réévaluation, la table des attestations et sa page de vérification sans données personnelles, l'onglet « Mon livret » rempli.
- **Retiré** : le compte rendu jamais alimenté (`seance_resumes`, `enregistrer_resume_seance`, `resume_seance_famille`) n'est plus lu ; il est remplacé par le livret et le message de la semaine.
- **Migrations** : oui, additives ; aucune suppression.
- **Preuve** : le directeur fait passer un petit bilan de test, confirme « Étape validée », voit l'élève passer à l'étape 2 avec la date limite de l'étape 2 comptée depuis ce jour, et lit le résultat dans « Mon livret » côté tuteur.

## Lot 9 · MOTEUR-2

- **But** : toutes les autres règles du moteur tournent, et la direction pilote par un journal et un tableau de bord.
- **Ce qu'on voit de neuf** : les règles 6 à 12, 14, 17 à 31, 33 et 34 ; le journal par élève, classe ou règle ; le tableau de bord à cinq chiffres et le résumé du jour ; la suspension d'une règle pour un élève.
- **Réutilisé** : tout le lot 7 ; `features/admin_pilotage`, `features/admin_tableau`.
- **Créé** : les règles restantes, `suivi_suspensions`, le journal, le tableau de bord.
- **Retiré** : rien.
- **Migrations** : oui, additives ; aucune suppression.
- **Preuve** : le directeur ouvre le tableau de bord, clique sur « alertes hors délai », retrouve une alerte de test passée en rouge, et lit dans le journal pourquoi chaque message a été envoyé ou retenu.

## Lot 10 · NETTOYAGE

- **But** : retirer les doublons et les restes listés dans la charte (partie 13), quand plus rien ne les lit.
- **Ce qu'on voit de neuf** : rien pour les personnes ; l'application ne garde qu'une représentation par notion.
- **Réutilisé** : l'inventaire de la charte, partie 13, et `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md`.
- **Créé** : rien.
- **Retiré** : les cinq calculs de l'étape ; les six représentations de la reprise ramenées à une ; les anciennes échelles ; `travail_maison` ; `seance_resumes` et ses fonctions ; `etagere_supports` ; les restes orphelins (`makharij_findings`, `tendance_feedback_v`, `TendanceFeedbackClasse`, `progressionGroupeProvider`, `anomaliesGroupeProvider`, `tc_flux_academique`, `port_post_cours`).
- **Migrations** : oui, **avec suppressions** ; seulement après inventaire, sauvegarde et accord du directeur sur la liste précise ; le directeur colle lui-même les fichiers qui contiennent une suppression (page privée générée par `tool/page_migrations/generer.py`).
- **Preuve** : le directeur refait en production les preuves des lots 1, 6 et 7 après le nettoyage, et tout marche comme avant.

## Les règles de l'équipe, pour chaque lot

1. **Six vérifications avant de dire fini** : `dart run slang` ; `dart run build_runner build --delete-conflicting-outputs` ; `dart analyze --fatal-infos` ; `flutter test` ; `dart run tool/verifier_jetons.dart` ; `dart run tool/verifier_branchement.dart`. Côté base, les scénarios SQL du lot passent sur un Postgres nu.
2. **Captures pour tout changement d'écran**, dans `docs/current/captures/E2E/<lot>/`, en clair et en sombre.
3. **Cinq états par écran** : chargement, contenu, vide, erreur, hors ligne.
4. **Textes par le vocabulaire** : chaque texte passe par les fichiers de traduction et la compétence `mots-rewayah` ; aucun code interne affiché.
5. **Une branche par lot**, inscrite le jour même au registre des lots.
6. **La production passe par une fusion.** L'architecte ouvre la pull request et fusionne, CI verte exigée, après revue indépendante du lot ; le directeur installe les migrations à partir d'une page à coller (directeur, 12/11/2026). « Fait » veut dire « prouvé par le directeur en production ».
