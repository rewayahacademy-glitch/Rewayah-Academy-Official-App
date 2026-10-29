# Appareil de l'élève : ni carte de la classe ni « Rejoindre », 29/10/2026

Branche `claude/admiring-brown-r6ai72-eleve-appareil`, depuis `origin/main` (0278546).

## Ce qui est inconnu ou non prouvé (à lire d'abord)

1. **Je ne sais pas pourquoi la veille temps réel n'a pas prévenu l'appareil de Hakim.** Elle était en production le 27/10 (PR #62, 05:25 UTC), elle écoute la table `sessions`, et la règle `sessions_self_read` laisse l'élève lire sa séance. Je n'ai pas de compte élève de staging pour ouvrir un canal temps réel et le vérifier. Le correctif ci-dessous ne dépend pas du temps réel ; la vérification du temps réel sur un appareil appairé reste à faire.
2. Rien n'est prouvé en production. Preuve du directeur : voir en bas.

## Constat du directeur (27/10, transmis le 29/10)

Sur l'appareil de Hakim, appairé par son tuteur : l'application s'affiche (profil, Coran), mais ni la carte de la classe ni « Rejoindre ». La séance du 27/10 s'est tenue depuis l'appareil du tuteur, pas depuis celui de Hakim.

## Cause, prouvée par les données de production (lecture seule)

| Heure (UTC, 27/10) | Fait |
| --: | :-- |
| 16:14:21 | la classe `2d5878ce` est créée ; ses séances du 3, 10, 17 et 24/11 sont créées, Hakim y est inscrit |
| 16:15:37 | le code d'appairage est consommé |
| 16:15:57 | l'appareil de Hakim ouvre sa session et lit ses séances : celle du jour n'existe pas encore |
| 16:19:18 | la séance du jour, 16:00-17:00, est créée (`fc593b57`), Hakim y est inscrit |

L'accueil de l'élève lisait ses séances **une seule fois**. Seule la veille temps réel pouvait le relire ; elle ne l'a pas fait. L'écran gardait donc la liste de 16:15, sans la séance du jour : ni carte, ni « Rejoindre ». L'appareil du tuteur, ouvert après 16:19, lisait la séance.

Second trou, trouvé en chemin : l'accueil en **Interface guidée** (`donneesAccueilAccessibiliteProvider`) n'était **pas du tout** dans la veille temps réel. Un appareil d'enfant en Interface guidée ne se mettait jamais à jour seul.

## Correctif (codé, testé localement)

- L'accueil de l'élève relit ses séances toutes les 2 minutes (`AppDelais.relectureAccueil`) et au retour dans l'application, en plus de la veille. La liste déjà lue reste affichée pendant la relecture.
- L'accueil en Interface guidée suit la veille (classes et séances), par `generationVeilleProvider` : c'est une lecture « à portée », que la veille ne peut pas invalider directement. Il se relit aussi toutes les 2 minutes et au retour dans l'application (`RelectureReguliere`).
- Coût : une petite lecture toutes les 2 minutes par écran d'accueil d'élève ouvert.

## Ce que les tests prouvent

- `test/features/accueil_eleve_test.dart`, « une séance créée après l'ouverture de l'accueil » : reproduit le 27/10 (accueil ouvert, puis séance du jour créée) ; **rouge avant le correctif, vert après** : « Ton cours a commencé » et « Rejoindre » apparaissent.
- `test/core/fraicheur/veille_fraicheur_test.dart` : un signal sur `sessions` ou `groupe_membres` relit l'accueil guidé.
- `test/core/accessibilite/relecture_accueil_test.dart` : la relecture toutes les 2 minutes, et plus rien une fois l'écran quitté.

## Une anomalie à décider, sans lien avec la cause

Hakim reçoit 36 séances annulées de 9 classes fermées (une classe fermée garde ses élèves dans `session_participants` de ses séances futures). L'accueil les écarte ; une séance annulée d'une classe fermée, le jour même, afficherait pourtant « Annulée ». Correctif serveur, zone interdite.

## Ce que le directeur fait pour prouver, après fusion

1. Ouvrir l'accueil de Hakim sur son propre appareil, et le laisser ouvert.
2. Depuis la direction, créer une classe avec Hakim et une séance qui commence dans moins de 20 minutes.
3. Sans toucher l'appareil de Hakim : en moins de 2 minutes, la carte de la séance et « Rejoindre » apparaissent. Vrai ou faux, capture.
4. Si elles apparaissent en quelques secondes, c'est le temps réel qui marche ; si c'est vers 2 minutes, c'est le secours, et le temps réel reste à réparer.
