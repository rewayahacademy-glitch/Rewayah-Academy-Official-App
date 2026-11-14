# Goutte des profils : planche pour la décision du directeur (12/11/2026)

**Proposition. Aucun code livré. La goutte est coupée en production (`goutteActive = false`).**
Ces images sont des captures de TEST de la vraie page d'Accueil de la famille (profil d'un enfant
choisi), pas la vraie application. Le code qui les a produites n'est pas dans le dépôt : il attend
la décision du directeur.

## Les quatre images

- `goutte_390_clair.png`, `goutte_390_sombre.png` : téléphone.
- `goutte_1440_clair.png`, `goutte_1440_sombre.png` : ordinateur.

Sur chacune : en haut l'option A, en bas l'option B ; de gauche à droite, l'écran au repos, le
début du mouvement, le milieu du mouvement.

## Ce que l'on voit, en cinq lignes

1. **Au début du mouvement (A et B)** : une goutte pleine, de la couleur d'accent, pend sous le
   profil choisi et se verse dans une surface qui a la largeur du contenu ; ce n'est plus un fil.
2. **Option A, la nappe passagère** : cette surface n'existe que pendant le mouvement ; elle
   passe de la couleur de la goutte à celle des cartes, puis s'efface. Au repos, l'Accueil est
   exactement celui d'aujourd'hui.
3. **Option B, la carte conteneur permanente** (l'idée du directeur, à la lettre) : la surface
   reste, autour de toutes les cartes. Elle est contraire à la règle des cartes (une carte n'est
   jamais posée sur une carte) et elle change l'Accueil au repos : un cadre de plus autour du
   contenu, partout, tout le temps.
4. **Défaut connu de A à l'ordinateur** : la nappe a la largeur de toute la colonne de contenu,
   plus large que la carte qu'elle laisse ; cela se voit au milieu du mouvement, surtout en sombre.
5. **Ce que la planche ne montre pas** : la goutte entre deux profils (non refaite : aujourd'hui
   une pointe puis un fil de 2 points), un profil qui a une classe (contenu plus long), l'arabe, un
   vrai téléphone. La durée ne change pas : 340 millisecondes, le contenu arrive tout de suite.

## Ce qui a été vérifié

Sur le code de la proposition, en local : l'analyse du code est propre ; les tests de la goutte
passent, sauf les quatre gardes « goutte coupée », qui échouent comme prévu puisqu'ils vérifient
que la goutte est éteinte. Les largeurs et les durées de l'option A ont été mesurées dans la nuit
du 11 au 12/11 sur la vraie application locale (goutte de 21 à 29 points de large, contre 1 point
avant).

## La décision demandée

A, B, ou ni l'une ni l'autre. Puis : faut-il refaire aussi la goutte entre deux profils ?
