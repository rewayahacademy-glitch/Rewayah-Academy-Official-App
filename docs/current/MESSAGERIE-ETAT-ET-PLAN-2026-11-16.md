# Messagerie, images, site public : état réel et plan pour finir (16/11/2026)

Demande du directeur, 16/11/2026, transmise par la session du recrutement :
« recadrer son travail, voir ce qui reste des lots initiaux, des bricolages et corrections ;
qu'il consigne lui aussi ses erreurs, ses oublis, ses solutions qui ont marché, et ce qui peut
servir aux lots élèves après ; engager la checklist pour que je suive avec lui ».

**Passation du 16/11 au soir : lire d'abord `MESSAGERIE-HANDOFF-2026-11-16.md`, qui prévaut sur les statuts ci-dessous.**

Ce document est **la carte unique** du chantier du pilote de la messagerie. Toute nouvelle demande
du directeur sur ce chantier y prend sa ligne **le jour même** (§5). La checklist vivante est la
liste de tâches de la session du pilote : chaque ligne y passe de « à faire » à « en cours » puis
« fait », et « fait » veut dire **vu par le directeur en production**.

Statuts : `en prod (vu)` = vérifié par le directeur en production ; `en prod` = fusionné et déployé,
pas encore vu par le directeur ; `PR` = ouverte, pas fusionnée ; `en cours` = un agent y travaille ;
`à faire` = rien n'est commencé.

## 1. Les lots demandés depuis le 14/11

| Lot | Demande du directeur | Statut |
| :--- | :--- | :--- |
| PAYS-VERSEMENT #500 | pays du compte bancaire modifiable | en prod (vu) |
| MESSAGERIE-PLEIN-ECRAN #501 | conversation en plein écran, en-tête compact | en prod (vu dans la page Messages) |
| ENTETE-COMMUNICATIONS #502 | en-tête d'une rangée sur mobile | en prod |
| RECHERCHE-LOUPE, DOUBLON-ENVOI, CLOCHE-EN-HAUT #503 | une seule loupe, message affiché en double, cloche dans la barre du haut | en prod |
| BULLES-MESSAGERIE #507 | bulles, sens de lecture arabe, heure à l'extérieur, ombres | en prod |
| FINITIONS-MESSAGERIE #512 | avatar, flèche, rectangle supprimé, compteur, pastilles | en prod |
| IMAGES serveur #510 | images, cœur, 90 jours, purge | en prod, migrations installées par le pilote |
| IMAGES écran #519 | bulles d'image, aperçu, image retirée | en prod |
| Bibliothèques natives #520 | image_picker, flutter_image_compress (accord du directeur) | en prod |
| Règle CORS sur le compartiment des images | posée par le directeur dans Cloudflare | **faite, prouvée** : deux images confirmées en base |
| IMAGES-CORRECTIF #530 | deux bulles, mot « Image » seul, échec qui reste en bas, aplat violet, chargement agréable | **PR**, CI en cours ; migration `20261129200000` à installer après fusion |
| AVIS-ARABE #533 | déploiement bloqué par un avis contenant de l'arabe | en prod (fusionnée 14:16 UTC), déploiement à confirmer |
| CONVERSATIONS-PARTOUT | conversation ouverte depuis un profil : ancien en-tête, bulle au bord, phrase d'aide, plantage ; **toutes** les entrées, tous les rôles | **en cours** (audit fait, branche après #530) |

## 2. Ce qui reste, dans l'ordre

1. Confirmer le déploiement de #533, qui met aussi en ligne #521 et #528.
2. Fusionner #530, installer sa migration, rattraper `confirmee_le` des deux images déjà
   confirmées, vérifier en production, donner au directeur la liste des essais.
3. Mesurer le temps réel d'envoi d'une image côté serveur (`confirmee_le` moins `cree_le`). Les
   lignes de mesure dans la console sont muettes en production.
4. CONVERSATIONS-PARTOUT : matrice `MESSAGERIE-MATRICE.md` (chaque entrée × chaque rôle × téléphone,
   ordinateur, fr, ar, clair, sombre, vide, long, image, échec, retour, cloche) et garde automatique
   qui bloque la mise en ligne d'une entrée absente de la matrice.
5. Recette du directeur en production, entrée par entrée, à partir de la matrice.
6. Petit lot : `supabase/tests/scenarios_fac_f_relances_suspension.sql` échoue le lundi entre 7 et
   8 h UTC (chevauchement de séances), à rendre indépendant de l'heure.

## 3. Bricolages et corrections hors plan

- **Galerie** : renommage `page_conversation.dart` en `page_conversation_plein_ecran.dart` pour un
  test de catalogue (#501).
- **Message en double** : le vrai coupable était une variable initialisée en retard ; prouvé par un
  test qui échoue sans le correctif (#503).
- **Envoi d'image en production** : 6 essais en échec ; aucun appel « confirmer » en base ; cause =
  règle CORS absente sur le compartiment ; corrigé par le directeur.
- **Aplat violet** : la liste des miniatures d'une conversation était gardée une heure ; une image
  arrivée après n'y figurait jamais (#530).
- **Déploiement en panne** : un contrôle du site public refusait toute lettre arabe, et un avis
  sincère en contenait (#533).

## 4. Erreurs et oublis du pilote, devenus des règles

| # | Erreur ou oubli | Conséquence | Règle |
| :--- | :--- | :--- | :--- |
| P1 | Refonte faite sur la page Messages seulement | la conversation ouverte depuis un profil est restée à l'ancienne, au bord, avec la phrase d'aide | **Une correction d'interface commence par l'inventaire, tiré du code, de tous les endroits qui affichent la même chose**, puis une matrice entrée × rôle ; une garde automatique refuse une entrée oubliée |
| P2 | La cloche laissée hors de la barre du haut alors que le directeur l'avait déjà demandée | « c'est la deuxième fois » | Avant de livrer, relire les demandes précédentes du directeur sur le même écran |
| P3 | Agent bloqué 1 h 30 sur `pubspec.yaml` sans que le pilote le voie | retard | Contrôler chaque agent 20 minutes après son lancement, puis toutes les 30 minutes, par une tâche planifiée |
| P4 | Créneau de migration déjà pris donné à un agent | collision évitée de justesse | Lire `supabase/migrations/` sur `origin/main` avant d'attribuer un créneau |
| P5 | Migrations laissées au directeur pendant des semaines | travail inutile pour lui | Consigne 21 : le pilote installe, selon la checklist de `supabase/CLAUDE.md` |
| P6 | Mesures de temps annoncées en console de production | elles sont muettes hors mode debug | Vérifier la règle d'observabilité avant de promettre une mesure ; mesurer côté serveur |
| P7 | PR laissée en conflit sans le voir, CI jamais lancée | retard | Lire `mergeable_state` de la PR avant d'attendre la CI |
| P8 | Agent qui ne lance qu'une partie des tests | CI rouge après coup | Avant d'ouvrir une PR, lancer les tests qui parcourent tout `lib/` (garde-fous), pas seulement ceux du lot |

**Ce qui a marché :**
- prouver la cause en production avant de corriger : lignes en base, aucun appel « confirmer » ;
- un test qui échoue sans le correctif ;
- reconstruire le site avec les vrais avis publiés ;
- installer les migrations soi-même, par ancres, avec un contrôle après installation.

## 5. Règle : toute demande a sa ligne le jour même

Une demande du directeur sur la messagerie, les images ou le site public prend une ligne au §1 le
jour même, avec son statut. Elle prend aussi une tâche dans la checklist de la session du pilote.
Une ligne ne passe à `en prod (vu)` que sur le constat du directeur.
