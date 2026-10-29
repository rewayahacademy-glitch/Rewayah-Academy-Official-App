# Lot créneaux : une classe à plusieurs créneaux, et la mixité, rapport du 29/10/2026

Décisions : `DECISION-CLASSES-HORAIRES-MIXITE-2026-10-29.md` (D1, D2, arbitrages Q1 à Q3). Fiche : `FICHE-CRENEAUX-2026-10-29.md`. Branche `claude/admiring-brown-r6ai72-creneaux`, depuis `main`.

## Ce qui n'est pas vrai, ou pas prouvé, d'abord

1. **Rien n'est appliqué ni prouvé en production ni sur staging.** La migration `supabase/migrations/20261029170000_classe_plusieurs_creneaux.sql` n'est appliquée nulle part. Elle contient un `DELETE` (dans le corps de la fonction de retrait d'un créneau) : le directeur la colle lui-même dans l'éditeur SQL (page de collage à fabriquer au moment voulu).
2. **La durée par créneau n'est pas faite.** La durée reste celle de la classe (son offre, sinon le réglage de son public). Elle sert au contrôle des chevauchements de l'enseignant dans plusieurs fonctions du serveur ; la porter par créneau est un lot à part.
3. **Trouvé en lisant le code** : le genre choisi dans « Nouvelle classe » n'était jamais envoyé au serveur (l'écran le disait : « genre non enregistré »), ni le fuseau. C'est pourquoi toutes les classes de la production sont de genre « indéterminé ». La création passe désormais par `creer_classe_creneaux_admin`, qui enregistre le genre et le fuseau.
4. **Le regroupement automatique n'ajoute aujourd'hui aucun élève à une classe existante** : il crée de nouvelles classes depuis les demandes semblables (genre de la clé). La règle Q1 (« pas d'élève ajouté à une classe au genre non réglé ») est donc vraie par construction ; l'écran « Créneaux et genre » le dit pour chaque classe non réglée. L'ajout d'un élève à la main par la direction ne contrôle pas le genre (inchangé).
5. **Modifier ou ajouter un créneau** exige que l'enseignant soit disponible à ce créneau (règle déjà en production pour l'ajout) ; **créer** une classe à plusieurs créneaux ne l'exige pas (comme la création d'une classe à un créneau, décision D4). Différence voulue, à confirmer si elle gêne.
6. Le scénario `scenarios_cpt_suppression_export.sql` a été rouge une fois dans la passe complète, vert seul sur la même base : passager, sans lien constaté avec ce lot.

## Ce qui change

| Quoi | Où |
|---|---|
| Une séance annulée par la direction garde son motif (`sessions.motif_annulation`) ; retirer ou modifier un créneau **annule** ses séances à venir (jamais une séance passée ni commencée), jamais ne les supprime | `private.annuler_seances_creneau` |
| Retirer un créneau (le dernier refusé) ; retirer l'ancre déplace l'ancre sur un autre créneau | `public.retirer_creneau_classe_admin` |
| Modifier un créneau : annulation, déplacement (le contrôle de l'enseignant repasse), génération des nouvelles séances ; familles et enseignant prévenus (« séance annulée », « créneau changé ») | `public.modifier_creneau_classe_admin` |
| Créer une classe à la main avec 1 à 7 créneaux, en une transaction, avec son genre (hommes, femmes ou mixte, jamais « indéterminé ») et son fuseau | `public.creer_classe_creneaux_admin` ; écran « Nouvelle classe » : trois créneaux par défaut (le premier, puis « Autres créneaux de la semaine », deux lignes à remplir ou à retirer, « Ajouter un créneau ») |
| Mixité (D1) : `groupes.mixte` ; la direction règle hommes, femmes ou mixte, avec un motif ; un genre incompatible avec l'enseignant attitré est refusé et rien ne change | `public.regler_genre_classe_admin` ; la liste des classes dit « Mixte » (`classes_admin_page`) |
| Écran de la classe : l'entrée « Ajouter un créneau » devient « Créneaux et genre » : les créneaux de la semaine (Modifier, Retirer, Ajouter), le genre de la classe (réglé ou non), chaque geste avec son motif et sa conséquence dite avant | `lib/features/admin_groupes/feuille_reglages_classe.dart` |
| Les classes existantes : rien à recopier, leur créneau unique est déjà dans `groupe_creneaux` | — |

## Tests

- SQL : `supabase/tests/scenarios_classe_plusieurs_creneaux.sql` (création à 3 créneaux, créneaux en double, genre enregistré et jamais indéterminé, modification d'un créneau et de l'ancre, annulation avec motif et jamais de suppression, retrait, retrait de l'ancre, dernier créneau, motif exigé, mixité, genre incompatible refusé, droits). Passe complète des scénarios : mêmes résultats que `main` (7 rouges déjà rouges sur `main`), plus ce scénario vert. `scenarios_classes_plafond_par_enseignant.sql` et `scenarios_af_liste_blanche_volatiles.sql` relisent la nouvelle fonction de création.
- Flutter : `test/features/admin_groupes/creneau_classe_test.dart` (liste, modifier, retirer, dernier créneau, genre, un seul bouton plein) ; `test/features/classe_form_1_test.dart` (trois créneaux par défaut, créneau incomplet, en double, ce qui part au port ; « Mixte » à la place de « Non déterminé »).

## Ce que le directeur vérifie, après fusion et migration (en gestes simples)

1. Classes, « Nouvelle classe » : sous le premier créneau, « Autres créneaux de la semaine » avec deux lignes. Choisir lundi 18 h, mercredi 18 h, vendredi 18 h, un enseignant, créer.
2. Ouvrir le planning de cette classe : trois séances par semaine.
3. Menu de la classe, « Créneaux et genre » : les trois créneaux. « Modifier ce créneau » sur mercredi : jeudi 19 h, écrire un motif, « Déplacer le créneau ». Les séances du mercredi passent en « annulée », celles du jeudi apparaissent ; la famille et l'enseignant reçoivent la notification.
4. « Retirer ce créneau » sur le dernier qui reste : la phrase dit qu'une classe garde au moins un créneau.
5. « Modifier le genre » d'une classe existante : choisir « Mixte », écrire un motif, enregistrer ; la liste des classes dit « Mixte ».
