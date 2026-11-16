# Passation du pilote de la messagerie (16/11/2026, 19 h UTC)

Demande du directeur : « prépare un handoff, pour te retirer ». Ce document dit au pilote suivant
ce qui est en cours, ce qui reste et comment travailler sans refaire mes erreurs. La carte du
chantier est `docs/current/MESSAGERIE-ETAT-ET-PLAN-2026-11-16.md`. Le tableau de contrôle est
`docs/current/MESSAGERIE-MATRICE.md`.

## 1. Vérité d'abord : ce qui est faux, ouvert ou non prouvé

- **La messagerie est grise depuis #512.** Le directeur trouve ça « trop moche » et veut les
  couleurs d'avant. La correction est la **PR #551**, ouverte et **pas fusionnée**.
- **La croix qui ferme le volet de conversation a disparu sur ordinateur.** C'est une régression de
  #540. Elle est demandée dans #551.
- **Le champ de saisie s'arrondit en cercle en grandissant et coupe le texte.** La correction est
  demandée dans #551.
- **Rien de ce qui suit n'est vu par le directeur en production :** les photos (#538, #546),
  l'envoi de photo par un candidat, le lien lisible dans sa bulle, la conversation du dossier
  (#540). Il doit les essayer après avoir fermé puis rouvert l'application.
- **Le « plantage » à l'ouverture d'une conversation depuis un profil n'est pas reproduit.** Il
  faut l'heure exacte et une capture du directeur au prochain essai, puis lire les journaux à cette
  heure-là.
- **Le canal du Studio garde l'ancienne présentation.** Le fil plein écran n'a pas d'emplacement
  d'en-tête, et son mode focus disparaîtrait. Le changer est un lot à part, sur décision du
  directeur.
- **`supabase/tests/scenarios_image_candidat.sql` n'est pas dans `.github/workflows/ci.yml`.**
  Le dossier `.github/` est interdit aux agents. Il faut le demander au directeur.

## 2. Agent en cours

Session `session_0163KjrvV6fGAftwzWig2qU9` (Sonnet), qui a fait #530, #538, #540 et #546.

- **En cours : PR #551, MESSAGERIE-COULEURS.** Elle contient :
  - le fond du fil égal au fond de page (`F1EFF4` en clair, `16161E` en sombre) ;
  - la liste en une carte blanche à lignes fines, comme avant #512, **construite ligne par ligne**
    (test : moins de 30 lignes construites sur 500 conversations) ;
  - un champ de saisie à rayon fixe au-delà d'une ligne ;
  - la croix du volet et la touche Échap ;
  - une garde de rendu des couleurs.
- **Avant de fusionner #551 :** relire les captures avant et après, puis lire la CI. L'agent dit
  lui-même « je ne dis pas verte avant de l'avoir lue », et s'est déjà trompé deux fois sur des
  comptes de tests.
- **Ensuite : NOUVEAU-FILS.**
  - Le composant `lib/core/widgets/badge_nouveau.dart` est déjà dans main.
  - Règle côté serveur : une conversation est « nouvelle » si elle a moins de 7 jours et qu'aucun
    membre de l'équipe n'a de ligne dans `com_lectures` pour elle.
  - Une conversation vide affiche « Nouveau · aucun message ».
  - Un filtre « Nouveaux » s'ajoute à la liste.
- **Puis : NOUVELLE-VERSION.**
  - Mesuré : aucun cache, `main.dart.js` est servi en `max-age=0`, mais un onglet ouvert garde
    l'ancien code.
  - Bandeau « Nouvelle version disponible » qui lit `version.json`.
  - Jamais de rechargement automatique pendant un brouillon ou un envoi.
- **Plus tard, sans urgence :** `scenarios_fac_f_relances_suspension.sql` dépend de l'heure. Il
  échoue le lundi entre 7 et 8 h UTC.

Le contrôle programmé « Contrôler COULEURS-MESSAGERIE » (`trig_01BGKXio9FNSJwwxm8tsor84`) se
déclenche dans la session du pilote sortant. **Le pilote suivant le désactive et crée le sien.**

## 3. Base de données : ce qui est installé aujourd'hui

Toutes ces migrations sont installées par le pilote, puis vérifiées en production :

| Migration | Rôle |
| :--- | :--- |
| `20261129100000` à `20261129100400` | images, cœurs, purge 90 jours |
| `20261129200000` | `confirmee_le`, message à image non confirmée masqué aux autres |
| `20261129300000` | rattrapage de `confirmee_le` (5 images confirmées, toutes datées) |
| `20261129500000` | le candidat dépose des images ; « [image] » sans aucune ligne d'image masqué |

**Numéros de migration :**
- le chantier du Bureau prend `202611294xxxxx` ;
- la messagerie prend `202611295xxxxx` et au-delà ;
- toujours vérifier sur `origin/main` avant d'attribuer un numéro. J'ai fait l'erreur deux fois.

Le Bureau a changé de pilote. Pour se coordonner, il faut écrire à
`session_0163KjrudJVgfH6zMjadp2bb`.

## 4. Règles apprises aujourd'hui (le détail est dans la carte, §4)

1. **Avant de corriger un écran, relever dans le code tous les endroits qui affichent la même
   chose.** La garde `tool/verifier_conversations.dart` le fait pour les conversations.
2. **Relire les captures en cherchant ce qui a changé ailleurs que ce qu'on corrigeait.** J'ai
   laissé passer le gris et la croix disparue.
3. **Relire chaque migration ligne à ligne avant la fusion.** C'est ce qui a attrapé la règle qui
   aurait effacé des messages au bout de 90 jours.
4. **Lire `mergeable_state` d'une PR avant d'attendre sa CI.** Une PR en brouillon peut ne lancer
   aucune CI. La passer en « prête » la lance.
5. **Après une mise en ligne, dire au directeur de fermer puis rouvrir l'application.** Un onglet
   ouvert garde l'ancienne version.
6. **« Fait » veut dire vu par le directeur en production.** Un test vert ne suffit pas.
7. **Commit puis push en deux commandes séparées.** Ensemble, le classificateur de permissions les
   refuse.

## 5. Envoyer une photo : la chaîne, si elle recasse

1. Le message est créé, puis `message-image-depot` est appelé avec « demander ».
2. Le navigateur envoie le fichier par un `PUT` signé vers R2. Il faut la règle CORS posée par le
   directeur dans Cloudflare.
3. « confirmer » est appelé.
4. La lecture passe par `message-images-lecture`, qui donne des adresses signées. L'affichage se
   fait par `Image.network` avec `WebHtmlElementStrategy.fallback`, ce qui marche même sans en-tête
   CORS sur le `GET`.

En base, on lit l'avancement ainsi : `com_message_images.etat`, `cree_le` puis `confirmee_le`. Le
temps mesuré de la demande à la confirmation est d'environ 3 secondes.
