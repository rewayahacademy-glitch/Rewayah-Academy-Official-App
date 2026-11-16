# Messagerie : checklist du pilote

**Mise à jour : lundi 16/11/2026, 20 h 45 UTC.** Cette page est mise à jour à chaque étape.

## Où on en est, en clair

**Ce qui est vrai ce soir : rien n'est encore fusionné ni mis en ligne.** Le gris de la messagerie,
la croix disparue du volet et le champ de saisie qui devient un cercle sont toujours en production.

**Ce que je fais (le pilote)** : je ne code pas. Je donne le travail à un seul agent, je le contrôle
toutes les 30 minutes, je relis ses captures et la CI, puis je fusionne et j'installe en base.

**Ce que j'ai demandé à l'agent (un lot à la fois)** :

1. **Finir la correction des couleurs, #551** (en cours depuis 19 h 48)
   - [x] reprendre la branche de l'agent précédent (archivé, il avait fini son contexte)
   - [x] régénérer les textes et le code : aucun changement
   - [x] contrôle du code (`analyze`) : zéro erreur
   - [x] écrire, et cette fois enregistrer, le code qui fait les captures (il avait été perdu)
   - [ ] tous les tests de l'application : en cours, 4 172 passés à 20 h 10, aucun échec signalé, pas fini
   - [x] faire les captures (`07fa7688`) : volet avec la croix, liste, fr et ar, clair et sombre
   - [x] **moi** : relu 3 captures. Croix visible ; fil sur le fond de page ; bulles reçues lisibles
         (aucun contour à ajouter, décision du pilote) ; liste en carte blanche
   - [ ] **défaut vu par le pilote** : l'heure du dernier message est coupée sous le champ de saisie ;
         l'agent vérifie si c'est la capture ou le vrai écran, et corrige si besoin
   - [x] reprendre les dernières fusions de l'équipe (`73651b66`) ; #563 fusionnée depuis, sans conflit
   - [ ] ouvrir la PR à la vérification automatique (CI) et la lire
   - [ ] **moi** : relire les captures avant et après, chercher ce qui a changé ailleurs, fusionner
   - [ ] **vous** : voir en production (fermer puis rouvrir l'application)
2. **NOUVEAU-FILS** (à lancer après #551)
   - [ ] badge « Nouveau » sur une conversation de moins de 7 jours que personne de l'équipe n'a lue
   - [ ] une conversation vide affiche « Nouveau · aucun message »
   - [ ] filtre « Nouveaux » dans la liste
   - [ ] une petite migration en base, que j'installerai moi-même
3. **NOUVELLE-VERSION** (ensuite) : bandeau « Nouvelle version disponible », jamais de rechargement
   pendant que vous écrivez.

**Ce qui attend votre décision** : voir « Pour le directeur au réveil », en bas.

## Point du matin (dix lignes au plus)

_Rempli au matin._

## Faux, bloqué ou non prouvé (à lire d'abord)

- La messagerie est grise depuis #512, la croix du volet a disparu (#540), le champ de saisie
  s'arrondit en cercle : corrections dans la PR #551, **pas fusionnée**, CI pas encore lancée.
- L'agent précédent de #551 (`session_0163KjrvV6fGAftwzWig2qU9`) a poussé `571f558a` (fusion de
  `main` 1ae0202e, sans conflit, vérifié par le pilote) et a été **archivé à 19 h 47**. Sur ce commit,
  **rien n'est vérifié** : ni slang, ni build_runner, ni analyze, ni tests, ni CI ; #551 est encore en
  brouillon, donc sans CI.
- Le conteneur de l'agent de #551 a été recréé : il a **perdu, non poussées**, les captures du volet
  (croix) et de la liste 1440. La tête poussée `667a9543` est intacte. **La croix du volet n'a aucune
  capture** ; elle n'est prouvée que par un test. L'agent attendait une réponse de l'utilisateur de sa
  session ; le pilote lui a relayé la consigne de reprise du directeur (« il repart de sa branche
  poussée »).
- Vérifié par le pilote : entre la base de #551 (`af1cfbb9`) et `main`, aucun changement dans `lib/`
  ni `assets/i18n` ; fusion sans conflit.
- Plafond de quatre agents : un seul agent messagerie à la fois ; NOUVEAU-FILS part après #551.
- #538, #540, #546 sont en production mais **pas vus** par le directeur.
- Le plantage à l'ouverture d'une conversation depuis un profil n'est **pas reproduit**.
- Erreurs de l'ordre de prise de poste, constatées : le fichier `PASSATION-MESSAGERIE-2026-11-16.md`
  n'existe pas (la passation s'appelle `MESSAGERIE-HANDOFF-2026-11-16.md`) ; l'adresse du Pilote Équipe
  donnée par la passation (`session_0163KjrudJVgfH6zMjadp2bb`) diffère de celle reçue ce soir
  (`session_0163KjrvqR38dL9HhgktqAdg`, retenue).

## En cours

| Lot | Qui | Statut | Prochaine étape |
| :--- | :--- | :--- | :--- |
| MESSAGERIE-COULEURS #551 | agent neuf `session_0163KjrwKsohCvdhrjhrWP5N` (Sonnet, lancé 19 h 48) | PR brouillon ; `7e7fae52` poussé (19 h 54) : slang ×2 et build_runner sans changement, analyze à zéro, code des captures commité ; `flutter test` complet en cours, captures non générées, CI non lue | l'agent relance slang deux fois, build_runner, analyze, `flutter test` complet, les trois vérificateurs ; refait et **commite** les captures du volet (1440, fr et ar, clair et sombre, fil remonté, croix) et de la liste 1440 ; passe la PR en « prête », lit la CI ; le pilote relit les captures avant/après (téléphone et ordinateur, clair et sombre, ce qui change ailleurs), lit la CI, prévient le Pilote Équipe (`lib/core`, `assets/i18n`), fusionne |
| Cette checklist #560 | pilote | PR | fusion quand la CI est verte |

## À lancer

| # | Lot | Condition | Détail |
| :--- | :--- | :--- | :--- |
| 1 | NOUVEAU-FILS | après #551 et une place d'agent libre | badge « Nouveau » (`lib/core/widgets/badge_nouveau.dart`), « Nouveau · aucun message » pour une conversation vide, filtre « Nouveaux » ; règle serveur : moins de 7 jours et aucune ligne `com_lectures` d'un membre de l'équipe ; migration `202611295xxxxx` au-delà de `20261129500000` (déjà pris), vérifiée sur `origin/main` ; session neuve |
| 2 | NOUVELLE-VERSION | après NOUVEAU-FILS | bandeau « Nouvelle version disponible » qui lit `version.json` ; jamais de rechargement pendant un brouillon ou un envoi |
| 3 | Canal du Studio dans la nouvelle présentation | décision du directeur | d'abord un emplacement d'en-tête au fil plein écran ; risque sur le mode focus |
| 4 | Bouton « i » emporté par la barre repliée (Messages, ordinateur) | lot à part | relevé par l'agent de #551, hors de #551 |
| 5 | `scenarios_fac_f_relances_suspension.sql` indépendant de l'heure | sans urgence | échoue le lundi 7-8 h UTC |
| 6 | Recette du directeur en production : #538, #540, #546, puis #551 | après fusion de #551 | liste d'essais, une par une, page humaine |

## Corrections non bloquantes demandées par le directeur

| Date | Demande | Statut |
| :--- | :--- | :--- |
| 16/11 | Le lecteur vocal dans sa propre bulle : contraste à revoir | à faire, à l'ouverture des vocaux |
| 16/11 | « Enregistrer l'image » exige la règle CORS sur le `GET` | à vérifier dans Cloudflare |
| 16/11 | Test local `images_messagerie_test` (glisser vers le bas) qui échoue en local, passe en CI | cause inconnue |

## Pour le directeur au réveil

1. Un fin contour sur les bulles reçues si, après #551, elles se fondent dans le fond clair
   (contraste 1,14:1) ?
2. Le canal du Studio dans la nouvelle présentation, au risque du mode focus ?
3. Ajouter `scenarios_image_candidat.sql` à `.github/workflows/ci.yml` (zone interdite aux agents) ?
4. Le plantage depuis un profil : au prochain essai, noter l'heure exacte et faire une capture.

## Journal du pilote

- 16/11, 19 h 18 : prise de poste de `session_0163KjrvfAPWhND7VanbMLHL` ; checklist ouverte (#560) ;
  session archivée à 19 h 23.
- 16/11, 19 h 40 : prise de poste de `session_0163Kjrx8uX1pRbk4RhE7Yuz` ; lectures faites ; agent de
  #551 contacté ; Pilote Équipe contacté (plafond d'agents, fichiers partagés) ; checklist renommée
  `MESSAGERIE-CHECKLIST.md`.
- 16/11, 19 h 40 : le Pilote Équipe (#557 redéploie courriels-envoi et push-envoi) : rien de la
  messagerie ne les touche, il peut fusionner. Aucune migration messagerie annoncée cette nuit hors
  NOUVEAU-FILS.
- 16/11, 19 h 40 : l'agent de #551 signale la perte des captures du volet ; consigne de reprise relayée.
- 16/11, 19 h 47 : prise de poste de `session_0163KjrvqyXGcbF9eGGztS24`. Agent de #551 archivé après
  « poussé » (`571f558a`). Agent neuf `session_0163KjrwKsohCvdhrjhrWP5N` lancé sur #551 seul. Pilote
  Équipe (`session_0163KjrwwgbbL52RHBDSnDVm`) prévenu des fichiers partagés de #551, dont
  `admin_candidature/volet_conversation.dart`.
- 16/11, 19 h 54 : agent de #551 : `7e7fae52` (slang ×2 et build_runner sans changement, analyze à zéro,
  code des captures commité ; tests et captures en cours). Pilote Équipe : 3 agents de son côté, plafond
  de 4 atteint ; il fusionnera #547 (i18n générés, router, main.dart) ; #551 devra ensuite fusionner
  `main` et relancer slang deux fois. Ses migrations de ce soir : `20261129440000`, `480000`, `490000`.
- 16/11, 20 h 10 : contrôle. `main` a reçu #553, #555, #557 ; #547 pas encore. Agent inactif depuis
  19 h 54 (« en attente des tests ») : relancé par message.
- 16/11, 20 h 10 : agent : `flutter test` complet en cours, 4 172 passés, 1 663 sautés, pas fini.
- 16/11, 20 h 15 : le directeur ne voyait pas la checklist (elle était sur une branche) ; réécrite
  en clair en tête de page et envoyée directement.
- 16/11, 20 h 45 : `07fa7688` (main fusionnée, captures). Pilote : 3 captures relues ; décision :
  pas de contour sur les bulles reçues ; défaut signalé (heure du dernier message sous le champ).
