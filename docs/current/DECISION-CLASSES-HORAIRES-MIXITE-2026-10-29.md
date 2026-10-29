# Classes à plusieurs créneaux et mixité, décisions du directeur du 29/10/2026

Transmises par le pilote le 29/10/2026 ; les points ouverts de la fiche `FICHE-CRENEAUX-2026-10-29.md` ont été arbitrés le même jour par le pilote, sur délégation du directeur. Ce document complète `DECISION-OFFRES-GROUPES-2026-10-09.md` et `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` sans les remplacer.

## D1. Mixité

- Par défaut, une classe est **non mixte** (décision du 10/10, `REGISTRE-RECONCILIATION-2026-10-14.md`), à tout âge.
- La direction peut rendre une classe **mixte**, par un réglage explicite de la classe (motif : pas assez d'enseignants d'un genre). Une classe mixte accepte un enseignant des deux genres.
- Le regroupement automatique respecte le réglage. Le genre reste demandé à l'onboarding, pour chaque apprenant et pour le titulaire.
- Q1 (pilote, 29/10) : les classes de genre « indéterminé » (toutes, au 29/10) : la direction choisit hommes, femmes ou mixte, classe par classe ; tant qu'elle ne l'a pas fait, le regroupement ne leur ajoute aucun élève et l'écran le signale. **Les élèves déjà inscrits ne sont jamais touchés.**

## D2. Plusieurs séances par semaine pour une classe

- Une classe porte N créneaux hebdomadaires (jour de la semaine, heure, fuseau de la classe), **3 par semaine par défaut**, à des jours fixes. Aucune date à saisir.
- La direction ajoute, retire ou modifie un créneau dans l'écran de la classe. Les séances sont générées à partir de tous les créneaux.
- L'unicité reste sur l'élève et l'enseignant, jamais sur l'horaire (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`). Un élève reste dans une seule classe : elle porte toutes ses séances de la semaine.
- Migration des classes existantes : leur créneau unique devient le premier des N ; rien n'est perdu pour les élèves actuels.
- Q2 (pilote, 29/10) : une classe née d'une offre prend les jours de l'offre ; le « 3 par défaut » vaut pour la création à la main.
- Q3 (pilote, 29/10) : modifier un créneau **annule** ses séances à venir, avec statut et motif, au lieu de les supprimer ; l'historique est gardé ; les nouvelles séances sont générées ; familles et enseignant sont prévenus par les notifications existantes.

## Ce qui n'est pas décidé ici

- La durée par créneau (le directeur a parlé de « jour + heure + durée ») : aujourd'hui la durée est celle de la classe (son offre, sinon le réglage de son public) ; elle sert au contrôle des chevauchements de l'enseignant à plusieurs endroits du serveur. Une durée par créneau est un lot à part.
