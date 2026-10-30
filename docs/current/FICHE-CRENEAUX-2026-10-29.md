# Fiche courte : une classe à plusieurs créneaux, et la mixité (29/10/2026)

Décisions du directeur du 29/10 (D1 mixité, D2 plusieurs séances par semaine), transmises par le pilote. Fiche écrite **avant** de construire, parce que deux règles manquent (§3). Branche prévue : `claude/admiring-brown-r6ai72-creneaux`, depuis `main`.

## 1. Ce que dit la production (lecture seule, 29/10)

| Fait | Valeur |
|---|---|
| Table des créneaux d'une classe (`groupe_creneaux` : jour, heure) | existe ; **sans durée** (la durée est celle de l'offre ou du public de la classe) |
| Génération des séances (`materialiser_seances_groupe`) | lit **déjà tous** les créneaux de la classe |
| « Créer la classe » depuis un regroupement | pose **déjà un créneau par jour** du regroupement |
| Ajouter un créneau (`ajouter_creneau_classe_admin`) | existe en production ; **ni retrait ni modification** |
| Création d'une classe à la main par la direction (`creer_groupe`) | **un seul** jour et une seule heure |
| Classes actives | 2, un créneau chacune ; 13 classes fermées, un créneau chacune |
| Genre d'une classe (`groupes.genre_public`) | `hommes`, `femmes`, `indetermine` ; **toutes** les classes sont `indetermine` |

Donc le défaut vient surtout de la création à la main (un seul créneau) et de l'absence de retrait et de modification ; les classes existantes ne perdent rien : leur créneau unique est déjà dans `groupe_creneaux`.

## 2. Ce que je construis (sauf réponse contraire)

1. **Création à la main** : la direction saisit 3 créneaux par défaut (jour, heure, durée), en ajoute ou en retire avant de créer ; aucun champ de date. Fuseau de la classe.
2. **Écran de la classe** : la liste de ses créneaux ; « Ajouter un créneau », « Modifier », « Retirer ». Un créneau retiré ou déplacé supprime ses séances **à venir** (jamais une séance passée ni une séance commencée) ; les familles et l'enseignant sont prévenus (événement existant « créneau changé »). Le dernier créneau ne se retire pas.
3. **Durée par créneau** : colonne `duree_minutes` facultative ; vide, la durée reste celle de la classe (rien ne change pour les créneaux existants).
4. **Contrôles** : l'enseignant ne doit avoir aucune séance qui se chevauche (R6), l'élève non plus (R5) : un créneau ajouté ou déplacé qui crée un chevauchement est refusé, avec la phrase de la règle.
5. **Mixité (D1)** : `genre_public` reçoit la valeur `mixte`, posée seulement par un réglage explicite de la direction dans l'écran de la classe ; le regroupement automatique ne met dans une classe non mixte que des élèves de son genre, et dans une classe mixte des élèves des deux.
6. Migration : rien à recopier (le créneau unique de chaque classe est déjà le premier des N) ; un scénario le prouve.

## 3. Ce qui manque, à trancher

| # | Question | Ma proposition |
|---|---|---|
| Q1 | Les classes `indetermine` (toutes, aujourd'hui) : que deviennent-elles ? | La direction choisit hommes, femmes ou mixte classe par classe ; tant qu'elle ne l'a pas fait, le regroupement ne leur ajoute aucun élève et l'écran le signale |
| Q2 | « 3 par semaine par défaut » vaut-il aussi pour une offre de la vitrine qui n'a que 1 ou 2 jours ? | Non : une classe née d'un regroupement prend les jours de l'offre ; le 3 par défaut ne vaut que pour la création à la main |
| Q3 | Un créneau modifié (jour ou heure) : déplacement des séances à venir, ou retrait puis ajout ? | Retrait des séances à venir puis génération des nouvelles, la même opération que « Retirer » puis « Ajouter », tracée une fois |

## 4. Arbitrage du 29/10/2026 (le pilote, par délégation du directeur)

- Q1 : oui. Les élèves déjà inscrits ne sont jamais touchés.
- Q2 : oui.
- Q3 : oui, avec une réserve : les séances à venir du créneau modifié sont **annulées**, avec statut et motif, au lieu d'être supprimées ; l'historique est gardé ; les nouvelles séances sont générées ; familles et enseignant sont prévenus.

Décisions consignées dans `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md`. Écarts à la fiche, construits ainsi : la durée par créneau n'est pas faite (§2, point 3 : la durée reste celle de la classe) ; la mixité passe par une colonne `groupes.mixte` plutôt que par une nouvelle valeur de `genre_public` (§2, point 5), pour ne pas réécrire les fonctions qui énumèrent les genres.
