# Décision du directeur, 07/11/2026 : la fluidité

> « Je veux que les gens se sentent comme sur Duolingo, que tout soit instantané. Ce qui est
> sensible comme le paiement, on ne va pas l'accélérer, mais tu peux le cacher par une animation
> qui est jolie à voir. […] L'utilisateur doit être heureux d'attendre. […] Et pour le reste, les
> messages et tout, ça, tu le fais instantanément. Avec des jolies animations. »
> Il ne veut pas de refonte générale.

Cette décision **amende** `DESIGN-GOV-2026-09-26.md` sur deux points seulement :

- la règle 6 du §4 bis.6 (« aucun shimmer, scintillement ou pulsation ») est **levée** pour les
  états d'attente ;
- au contrat E (§4 bis.5), les valeurs restent gelées pour les transitions, mais une **animation
  d'attente** peut boucler tant que l'attente dure (le plafond de 400 ms ne s'applique pas à une
  boucle).

Le reste de DESIGN-GOV reste en vigueur.

## 1. Deux familles d'actions, tranchées par le garde-cap

| Famille | Règle | Exemples |
| :--- | :--- | :--- |
| **Instantanée** | L'écran montre le résultat tout de suite, sans attendre le serveur. En cas d'échec, l'élément revient à son état d'avant avec un message court et un « Réessayer ». | Envoyer un message, marquer comme lu, cocher une présence, écrire une note de cahier, un réglage, un filtre, un onglet |
| **Sensible** | On attend la réponse du serveur, mais l'attente est belle (§2). Rien n'est affiché comme fait avant la réponse. | Payer, recharger, rembourser ; se connecter, s'inscrire, un code ou une invitation ; créer un compte ou un profil ; supprimer, retirer, clôturer ; tout changement de rôle ou de droit |

En cas de doute, l'action est **sensible**. Le serveur reste seul juge (`00`, invariants) : une
action instantanée est seulement *affichée* d'avance, elle n'est jamais *décidée* dans Flutter.

## 2. Une attente belle

- Le bouton d'une action sensible a un état d'attente vivant (mouvement doux et continu dans le
  bouton). Il garde sa taille, il n'est plus cliquable, et il est annoncé au lecteur d'écran.
- Les chargements de page gardent `Skeleton` + `BlocAsynchrone` (forme du contenu, rien de faux),
  avec un reflet lumineux lent qui traverse les blocs.
- Une réussite se voit : une courte animation de réussite après le retour du serveur.
- 60 images par seconde : on n'anime que l'opacité, la position et l'échelle, jamais la taille
  ni le flou.
- **Mouvement réduit** (réglage de l'appareil ou de l'application) : aucune boucle ; un état
  d'attente fixe et lisible. Règle d'accessibilité inchangée (`03`).
- Les seuils de 8 s (chargement prolongé expliqué) et de 20 s (état récupérable) restent.

## 3. Un seul endroit dans le code

Ces trois briques vivent dans `lib/core/`, une fois, et tous les écrans les réutilisent :
l'attente du bouton (`ActionPrincipale.enCours`), le reflet du `Skeleton`, et un petit outil
« afficher d'avance, revenir en arrière si échec » pour les actions instantanées. Aucun écran
n'invente sa propre animation.

## 4. Ordre

1. Le bouton d'attente (lot BOUTON-ATTENTE, train du 08/11).
2. Messages instantanés, puis le reflet du `Skeleton` (lot FLUIDITE-1).
3. Les autres actions instantanées, un écran à la fois.
4. En parallèle, côté serveur, ce qui est vraiment lent (lot PERF-ATTENTE, mesures du 07/11) :
   une belle animation ne remplace pas un serveur rapide.

Chaque lot suit les règles habituelles : quota P5, captures, preuve du directeur en production.
