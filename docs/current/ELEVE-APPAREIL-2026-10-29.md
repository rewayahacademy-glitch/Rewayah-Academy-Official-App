# Appareil de l'élève : ni carte de la classe ni « Rejoindre », 29/10/2026

Branche `claude/admiring-brown-r6ai72-eleve-appareil`, depuis `origin/main` (0278546).

## Ce qui est inconnu ou non prouvé (à lire d'abord)

1. **Je ne sais pas pourquoi la veille temps réel n'a pas prévenu l'appareil de Hakim.** Elle était en production le 27/10 (PR #62, 05:25 UTC), elle écoute la table `sessions`, et la règle `sessions_self_read` laisse l'élève lire sa séance. Je n'ai pas de compte élève de staging pour ouvrir un canal temps réel et le vérifier. Ce lot ajoute le signalement qui le dira en production ; la réparation, s'il le faut, viendra après.
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

## Correctif (codé, testé localement), modèle décidé par le directeur le 29/10

Le directeur a refusé une relecture toutes les 2 minutes (première version de ce lot) : à terme, tous les élèves seront connectés en permanence. Le modèle retenu :

1. **Le temps réel reste la source principale.** L'accueil en Interface guidée y est maintenant branché (par `generationVeilleProvider` : c'est une lecture « à portée », que la veille ne peut pas invalider directement). Si le canal temps réel n'est pas rejoint en 15 s, un avertissement part vers Sentry (« Veille temps réel : canal non rejoint », avec le rôle seulement). C'est ce qui dira, en production, pourquoi un appareil appairé ne reçoit rien.
2. **Relecture au retour dans l'application** (les deux accueils) **et au retour du réseau** (déjà fait par la veille, qui relit tout).
3. **Une seule relecture programmée à la fois, par séance connue** : 5 minutes avant son début, puis à son début pour l'accueil standard ; à l'ouverture de « Rejoindre », puis au début pour l'Interface guidée (le serveur y calcule l'ouverture).
4. **Aucune minuterie fixe** ; chaque relecture programmée reçoit un aléa de 0 à 30 s contre les rafales.

**Limite, dite au pilote avant d'appliquer ce modèle :** dans le cas exact de Hakim, la séance a été créée après l'ouverture de l'accueil. Une relecture « par séance connue » ne la voit pas : seuls le temps réel ou un retour dans l'application la montrent. Tant que le temps réel ne passe pas sur l'appareil appairé, le défaut peut revenir.

### À faire dans la zone interdite (adaptateur temps réel)

`lib/core/fraicheur/veille_supabase.dart` ne transmet pas les erreurs du canal : il les écrit seulement dans le journal de développement, invisible en production. Correctif proposé, dans `subscribe` :

```dart
          } else if (erreur != null) {
            journalDev('Veille de fraicheur : ${statut.name}, $erreur');
            if (!flux.isClosed) flux.addError(erreur);
          }
```

`veille_fraicheur.dart` reçoit déjà ces erreurs (`onError`) ; il faudra alors les envoyer à la supervision avec le statut (`channelError`, `timedOut`, `closed`).

## Ce que les tests prouvent

- `test/features/accueil_eleve_test.dart`, groupe « relectures de l'accueil, sans minuterie fixe » : (a) la séance créée après l'ouverture n'est pas relue pendant 30 minutes sans signal (aucune minuterie fixe), puis apparaît avec « Rejoindre » au retour dans l'application ; (b) pour une séance connue, une relecture 5 minutes avant, une au début, puis plus rien.
- `test/core/accessibilite/relecture_accueil_test.dart` : le calcul du délai, l'aléa borné, une relecture par instant, le retour dans l'application, et le signal de la veille qui relit l'accueil guidé.
- `test/core/fraicheur/veille_fraicheur_test.dart` : un signal sur `sessions` ou `groupe_membres` relit l'accueil guidé.
- 1 366 tests des accueils, de la veille, de l'accessibilité et du routeur, verts ; analyse et jetons sans problème.

## Une anomalie à décider, sans lien avec la cause

Hakim reçoit 36 séances annulées de 9 classes fermées (une classe fermée garde ses élèves dans `session_participants` de ses séances futures). L'accueil les écarte ; une séance annulée d'une classe fermée, le jour même, afficherait pourtant « Annulée ». Correctif serveur, zone interdite.

## Ce que le directeur fait pour prouver, après fusion

1. Ouvrir l'accueil de Hakim sur son propre appareil, et le laisser ouvert.
2. Depuis la direction, créer une classe avec Hakim et une séance qui commence dans moins de 20 minutes.
3. Sans toucher l'appareil de Hakim : la carte de la séance et « Rejoindre » apparaissent en quelques secondes. Vrai : le temps réel marche. Faux : passer l'application en arrière-plan puis la rouvrir ; si elles apparaissent alors, c'est le secours qui a joué et le temps réel reste à réparer (regarder Sentry : « canal non rejoint »). Capture dans tous les cas.
