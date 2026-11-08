# Décision du directeur, 08/11/2026 : la marque des champs obligatoires

> « Les champs obligatoires doivent [avoir] une étoile rouge ou point. »
> (Directeur, 08/11/2026, relayé par le pilote.)

## Ce qui est décidé

- **Une seule marque** pour tout champ obligatoire : le **point rouge** déjà présent dans le code,
  `TitreChamp` (`lib/core/widgets/champ_etiquete.dart`), qui dessine `PointRappel` à la couleur
  d'alerte du thème (`surfaceAlert`), au bord de début, devant le nom du champ. Aucune étoile, aucune
  seconde marque, aucune couleur nouvelle. Arbitrage du pilote du 08/11/2026, 02:00 UTC : « d'accord
  pour réutiliser le point rouge plutôt qu'ajouter une étoile ». Si le directeur veut une étoile, un
  seul endroit change : `TitreChamp`.
  Sur le violet de la marque, le point est blanc (pointObligatoireMarque, valeur d'inkAlert), car le
  rouge n'y a que 1,06:1 de contraste ; arbitrage du garde-cap du 08/11 vers 03:55 (WCAG 1.4.11).
- **Le lecteur d'écran l'annonce** : le nom du champ suivi de « champ obligatoire » (clé existante
  `formulaire.champObligatoire`).
- **L'étiquette est au-dessus du champ**, sur autant de lignes qu'il faut (`ChampEtiquete`,
  FORM-CORR-1) : dans une étiquette flottante, le point ne laisse pas la place au nom à 320 px en
  texte ×2.
- Un champ **facultatif** ne porte pas la marque.

## Où elle est posée

| Lot | Formulaires | Statut |
| :--- | :--- | :--- |
| CHAMP-OBLIGATOIRE (PR 336) | « Qui est l'élève ? » (prénom, nom, âge, genre) ; invitation du second adulte (prénom, adresse) ; identité de l'inscription (prénom, nom, nom en lettres latines) | fusionné le 08/11 (b0ac31c4) |
| CHAMP-OBLIGATOIRE-2 | Questionnaire d'inscription : prénom de l'enfant, adresse e-mail de l'écran d'accès | en cours |

Le questionnaire de candidature de la salle 1 pose une question par écran, par des choix : il n'a
aucun champ de texte à marquer.
