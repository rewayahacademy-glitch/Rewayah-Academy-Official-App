# Comment l'académie compte les minutes de paie d'un enseignant

Règle fixée par le directeur le 13/11/2026. Ce document dit, en mots simples, ce que le système
compte et ce qu'il ne compte pas. Il est écrit pour être lu par un enseignant.

> « Quand on dit qu'une classe est adulte, ça veut dire que c'est 1h30. Les minutes qui viennent
> avant ne sont pas comptées dans la paie, ni les minutes qui viennent après. Et pour une classe
> d'enfants, c'est 1 heure. Là aussi, même chose. » (le directeur, 13/11/2026)

**État au 13/11/2026 : cette règle est écrite et testée sur une base d'essai. Elle n'est pas encore
installée dans l'application. Tant que le directeur ne l'a pas installée et vérifiée lui-même,
l'ancien calcul reste en place.**

## 1. La fenêtre payable

Chaque séance a une fenêtre payable. Seul le temps passé dans la salle à l'intérieur de cette
fenêtre compte pour la paie.

| Classe | La fenêtre commence | La fenêtre dure |
| :--- | :--- | :--- |
| Classe d'enfants | à l'heure prévue de la séance | 1 heure |
| Classe d'adultes | à l'heure prévue de la séance | 1 h 30 |

- Si la séance est inscrite au planning pour **plus longtemps** (une classe d'enfants planifiée
  1 h 30, par exemple), la fenêtre reste de 1 heure. Le temps au-delà n'est pas payé.
- Si la séance est inscrite au planning pour **moins longtemps** (une classe d'adultes planifiée
  1 h 15, par exemple), la fenêtre s'arrête à la fin prévue : 1 h 15.

## 2. Ce qui compte

- Chaque seconde où vous êtes dans la salle, entre le début et la fin de la fenêtre.
- Si vous quittez la salle et la rejoignez plusieurs fois (coupure de connexion, changement
  d'appareil, page rechargée), **tous vos passages s'additionnent**. Rien n'est perdu entre deux
  passages, sauf le temps où vous n'étiez réellement pas dans la salle.
- Si vous êtes dans la salle avec deux appareils en même temps, ce temps est compté une seule fois.
- Le total est arrondi à la minute entière en dessous (57 minutes et 40 secondes donnent 57 minutes).

## 3. Ce qui ne compte pas

- Les minutes **avant** l'heure prévue. Rejoindre la salle 10 minutes en avance est une bonne
  habitude, mais ces 10 minutes ne sont pas payées.
- Les minutes **après** la fin de la fenêtre. Rester avec les élèves après l'heure n'ajoute rien
  à la paie.
- Le temps où vous n'êtes pas dans la salle, même pendant la fenêtre.
- Le temps passé dans la salle par un autre enseignant. Si un remplaçant prend la séance, ce sont
  ses minutes à lui qui comptent, et c'est lui qui est payé pour cette séance.

## 4. Des minutes au montant

La paie d'une séance = **taux par élève présent et par heure x nombre d'élèves présents x durée payée**.

- Taux (décision du 19/10/2026) : 1,99 $ par élève présent et par heure pour une classe d'enfants,
  1,57 $ pour une classe d'adultes.
- Élève présent : un élève qui a rejoint la séance, même pour une partie seulement. Un élève absent
  n'est jamais payé.
- Durée payée :
  - si vous avez tenu **au moins 45 minutes** dans la fenêtre d'une classe d'enfants, ou **au moins
    70 minutes** dans celle d'une classe d'adultes, la **fenêtre entière** est payée (1 heure ou
    1 h 30) ;
  - en dessous, seules vos minutes comptées sont payées.

## 5. Si votre départ n'a pas été reçu

Il arrive que l'application ne reçoive pas l'information de votre départ (coupure brutale, appareil
éteint). Dans ce cas :

- si vous rejoignez la salle ensuite, le système ne peut pas savoir à quel moment vous étiez
  parti : il ferme l'ancien passage à votre départ suivant, et le temps entre les deux est compté
  comme du temps dans la salle ;
- si aucun autre départ n'arrive, le système considère que vous êtes resté **jusqu'à la fin de la
  fenêtre**, ou jusqu'à la clôture de la séance si elle a été close avant. Jamais au-delà.

Si le compte vous semble faux, écrivez à la direction en donnant la classe, le jour et l'heure : la
direction peut relire chaque passage et fixer elle-même la durée d'une séance.

## 6. Exemples chiffrés

**Exemple 1. Classe d'enfants, séance prévue de 17 h 00 à 18 h 00, 4 élèves présents.**

| Ce qui s'est passé | Ce qui compte |
| :--- | :--- |
| Vous rejoignez la salle à 16 h 52 | rien avant 17 h 00 |
| Coupure à 17 h 20 | 17 h 00 à 17 h 20 : 20 minutes |
| Retour à 17 h 23 | les 3 minutes d'absence ne comptent pas |
| Vous quittez la salle à 18 h 06 | 17 h 23 à 18 h 00 : 37 minutes ; rien après 18 h 00 |

Total : 20 + 37 = **57 minutes**. C'est au moins 45 minutes : la fenêtre entière est payée.
Paie : 1,99 $ x 4 élèves x 1 heure = **7,96 $**.

**Exemple 2. Même classe, mais vous rejoignez la salle à 17 h 25 et la quittez à 18 h 10.**

Total : 17 h 25 à 18 h 00 = **35 minutes**. C'est moins de 45 minutes : seules ces 35 minutes
sont payées. Paie : 1,99 $ x 4 élèves x 35 / 60 = **4,64 $**.

**Exemple 3. Classe d'adultes, séance prévue de 19 h 00 à 20 h 30, 5 élèves présents.**

Vous êtes dans la salle de 18 h 55 à 20 h 15 : **75 minutes** comptées (de 19 h 00 à 20 h 15).
C'est au moins 70 minutes : la fenêtre entière est payée.
Paie : 1,57 $ x 5 élèves x 1,5 heure = **11,78 $**.

---

## Pour la direction et les agents (ne se montre pas à un enseignant)

- Code : `supabase/migrations/20261124900000_paie_fenetre.sql` ; preuve locale :
  `supabase/tests/scenarios_paie_fenetre.sql`. Prérequis : `20261124800000_paie_minutes_reconnexion.sql`.
- Durée de la formule : réglage existant de la direction, `app_config`
  `seance.duree_minutes_enfant` (60) et `seance.duree_minutes_adulte` (90). C'est déjà la source de
  la durée des séances créées ; il n'y a pas de seconde source. La durée d'une offre
  (`offres_horaires.duree_minutes`) ne sert pas à la paie.
- Taux et durées dues (45 / 70) : `politiques_commerciales`, inchangés par ce lot.
- Un seul compteur, `private.presence_mesure` : la présence des élèves et la paie s'en servent,
  chacune avec ses bornes. La présence garde sa règle (du début prévu à la fin prévue, plus 15
  minutes de grâce quand la séance est close).
- Aucun montant déjà écrit n'est recalculé. Les minutes affichées d'une séance déjà payée sont
  relues avec la nouvelle règle, son montant ne change pas.
- Changer le réglage de la durée change la fenêtre de toutes les séances pas encore payées, y
  compris passées : le réglage n'est pas daté, à la différence des taux.
