# Image de profil de Praxis (#Ra_Praxis)

Fichier : `praxis-profil.png` (2000 x 2000, RGBA, 160 Ko).

**Origine : fournie par le directeur le 17/11/2026**, dans la session cloud de l'agent PRAXIS-AFFICHAGE
(« le voici. mets-le dans le dépôt et partout pour ne pas qu'on le perde »). Ce n'est pas une image dessinée
par un agent : ne pas la redessiner, ne pas la remplacer par un dessin en code. Elle remplace les propositions
précédentes (brouillon d'avatar « marteau et clé », abandonné sur ordre du directeur le 17/11).

Contenu : fond violet clair uni, un mortier (toque de diplômé) noir au-dessus de deux yeux noirs à pupille blanche.
Aucun visage humain complet ; lue à 24 points, à vérifier à l'écran avant usage (non vérifié à ce jour).

## État : rangée, PAS ENCORE EMBARQUÉE dans l'application

`assets/brand/` n'est pas déclaré dans `pubspec.yaml` (zone interdite aux agents). Pour qu'elle serve d'avatar,
il faut, sur décision du directeur ou du pilote :

1. déclarer le dossier dans `pubspec.yaml` (`- assets/brand/praxis/`) ;
2. faire employer l'image par `AvatarParticipant` pour tout participant `officiel` (indicateur du lot
   PRAXIS-AFFICHAGE, PR #612), en un seul endroit, avec une version réduite (2000 points pèsent trop pour un avatar de 24) ;
3. vérifier le rendu à 24, 40 et 48 points, en clair et en sombre.

Hors de l'application (courriels, documents, pages publiques) : Praxis n'apparaît pas (SECRETAIRE-IA §11).
