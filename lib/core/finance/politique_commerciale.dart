// La politique commerciale versionnee (FI-1c, guide Finance V4 §1, §5.7 ;
// FI-BR-01).
//
// **Aucune valeur ici** (FI6) : ce fichier ne porte que la FORME d'une
// politique. Les valeurs de lancement vivent dans
// `lib/features/demo/finance_demo.dart` (demonstration) et, apres BR-1, dans
// la politique effective rendue par le serveur.
//
// Les invariants (idempotence, separation des soldes, historique en ajout
// seul, confirmation avant credit, pas de double debit, acces par periode)
// ne sont JAMAIS des champs (FI22) : ils n'ont pas de place dans ce modele.

import 'package:flutter/foundation.dart';

import 'montant.dart';

/// Un rail de paiement (guide §1.6). Seul [webStripe] est montre au
/// lancement (FI10) ; les deux autres sont prevus, jamais affiches.
enum RailPaiement {
  /// Paiement web par le prestataire (`WEB_STRIPE`), actif au lancement.
  webStripe,

  /// Achat integre iOS (`IOS_STOREKIT`), non active au lancement.
  iosStoreKit,

  /// Facturation Google Play (`ANDROID_PLAY`), non activee au lancement.
  androidPlay,
}

/// Le statut d'une version de politique (guide §5.7).
enum StatutPolitique {
  /// Brouillon, jamais applique.
  brouillon,

  /// Publiee : appliquee a partir de sa date d'effet.
  publiee,
}

/// Une remise par rang de membre payant du foyer (guide §1.3 ; tarifs du
/// 18/10/2026) : a partir du rang [aPartirDuRang], chaque membre payant
/// recoit [remise] (negative) ou [pourMille] de son tarif. L'un des deux,
/// jamais les deux.
@immutable
class RemiseRang {
  /// Cree la remise.
  const RemiseRang({required this.aPartirDuRang, this.remise, this.pourMille})
    : assert(
        (remise == null) != (pourMille == null),
        'une remise en montant ou en pour mille',
      );

  /// Le premier rang concerne (3 = troisieme membre payant).
  final int aPartirDuRang;

  /// La remise, en unites mineures negatives, ou `null` quand elle est en
  /// pour mille.
  final Montant? remise;

  /// La remise en pour mille du tarif (80 = 8 %), ou `null` quand elle est
  /// en montant.
  final int? pourMille;
}

/// La nature d'un budget de pilotage (guide §5.7 « budgets non
/// contraignants » ; ECARTS D5).
enum NatureBudget {
  /// Le budget marketing.
  marketing,

  /// Le budget operationnel.
  operationnel,
}

/// Un budget de pilotage, en pour mille. **Non contraignant** : un repere
/// de depense, jamais un blocage ni une sanction (guide §1.5, §5.7).
@immutable
class BudgetPilotage {
  /// Cree le budget.
  const BudgetPilotage({required this.nature, required this.pourMille});

  /// Sa nature.
  final NatureBudget nature;

  /// Sa valeur, en pour mille (80 = 8 %).
  final int pourMille;

  @override
  bool operator ==(Object other) =>
      other is BudgetPilotage &&
      other.nature == nature &&
      other.pourMille == pourMille;

  @override
  int get hashCode => Object.hash(nature, pourMille);
}

/// Une version de la politique commerciale.
@immutable
class PolitiqueCommerciale {
  /// Cree une version.
  const PolitiqueCommerciale({
    required this.version,
    required this.statut,
    required this.dateEffet,
    required this.tarifEnfant,
    required this.tarifAdulte,
    required this.essaisMax,
    required this.essaiActif,
    required this.remisesParRang,
    required this.baseHoraire,
    required this.plafondHoraire,
    required this.capaciteEnfant,
    required this.capaciteAdulte,
    required this.capaciteDebutant,
    required this.minimumOuverture,
    required this.classesObjectif,
    required this.classesMax,
    required this.joursConservationPlace,
    required this.margeReferencePourMille,
    required this.railsActifs,
    this.allocationInternet,
    this.joursRelance,
    this.budgets = const <BudgetPilotage>[],
    this.tauxEleveHeureEnfant,
    this.tauxEleveHeureAdulte,
    this.plafondEleveHeureEnfant,
    this.plafondEleveHeureAdulte,
    this.dureeDueEnfantMinutes,
    this.dureeDueAdulteMinutes,
    this.prepaiementTrimestrielPourMille,
    this.prepaiementAnnuelPourMille,
    this.parrainageCredit,
    this.boursePourMille,
    this.boursePlacesPourMille,
    this.bourseDureeMois,
    this.cumulMaxPourMille,
    this.jourSuspension,
  });

  /// L'identifiant de la version, tel que rendu.
  final String version;

  /// Brouillon ou publiee.
  final StatutPolitique statut;

  /// La date d'effet (jamais retroactive sur une facture payee, §1.3).
  final DateTime dateEffet;

  /// Le tarif academique mensuel d'un enfant, hors taxe (§1.1, §1.8).
  final Montant tarifEnfant;

  /// Le tarif academique mensuel d'un adulte, hors taxe.
  final Montant tarifAdulte;

  /// Le nombre maximal de seances d'essai par nouveau profil (§1.2).
  final int essaisMax;

  /// Vrai quand l'essai est propose aux nouveaux profils (guide §5.7
  /// « activation », ECARTS D8).
  final bool essaiActif;

  /// Les remises par rang, dans l'ordre croissant des rangs. Un rang absent
  /// n'a aucune remise (rangs 1 et 2 au lancement).
  final List<RemiseRang> remisesParRang;

  /// La base horaire garantie de l'enseignant (§1.4).
  final Montant baseHoraire;

  /// Le plafond horaire de l'enseignant.
  final Montant plafondHoraire;

  /// La capacite d'une classe d'enfants.
  final int capaciteEnfant;

  /// La capacite d'une classe d'adultes.
  final int capaciteAdulte;

  /// La capacite d'une classe de debutants.
  final int capaciteDebutant;

  /// Le minimum d'eleves pour ouvrir une classe.
  final int minimumOuverture;

  /// L'objectif courant de classes actives par enseignant.
  final int classesObjectif;

  /// Le maximum normal de classes actives par enseignant.
  final int classesMax;

  /// La duree de conservation d'une place non financee, en jours (§1.7).
  final int joursConservationPlace;

  /// La marge de reference de pilotage, en pour mille (300 = 30 %) : objectif,
  /// performance forte, scenario stretch (§1.5). **Jamais une sanction ni un
  /// blocage** (FI21).
  final ({int objectif, int forte, int stretch}) margeReferencePourMille;

  /// Les rails de paiement actifs. Seul `webStripe` au lancement.
  final Set<RailPaiement> railsActifs;

  /// L'allocation Internet par enseignant eligible, ou `null` quand la
  /// politique ne la fixe pas encore (montant configurable, §1.4).
  final Montant? allocationInternet;

  /// Les regles de relance d'une periode non financee (guide §1.7, §5.7
  /// « regles de relance visibles », FI-BR-16) : les jours, comptes depuis
  /// le debut de la periode, ou un rappel part vers le tuteur ou l'adulte
  /// autonome, jamais vers l'enfant. `null` quand la politique ne les fixe
  /// pas encore.
  final List<int>? joursRelance;

  /// Les budgets de pilotage, **non contraignants** (guide §5.7, ECARTS D5).
  /// Vide quand la politique n'en fixe aucun.
  final List<BudgetPilotage> budgets;

  // Les valeurs des tarifs du 18/10/2026 (version v2.0.0) : `null` dans une
  // version qui ne les porte pas.

  /// La paie de l'enseignant par eleve present et par heure, classe
  /// d'enfants (0,95 $ au 18/10/2026).
  final Montant? tauxEleveHeureEnfant;

  /// La paie de l'enseignant par eleve present et par heure, classe
  /// d'adultes.
  final Montant? tauxEleveHeureAdulte;

  /// Le plafond de ce taux, classe d'enfants (palier de fidelite compris).
  final Montant? plafondEleveHeureEnfant;

  /// Le plafond de ce taux, classe d'adultes.
  final Montant? plafondEleveHeureAdulte;

  /// La presence a partir de laquelle une seance d'enfants est due, en
  /// minutes.
  final int? dureeDueEnfantMinutes;

  /// La presence a partir de laquelle une seance d'adultes est due.
  final int? dureeDueAdulteMinutes;

  /// La remise d'un trimestre paye d'avance, en pour mille.
  final int? prepaiementTrimestrielPourMille;

  /// La remise d'une annee payee d'avance, en pour mille.
  final int? prepaiementAnnuelPourMille;

  /// Le credit de parrainage, a chacun des deux foyers.
  final Montant? parrainageCredit;

  /// La remise d'une bourse, en pour mille (jamais cumulee).
  final int? boursePourMille;

  /// Les places de bourse, en pour mille des eleves.
  final int? boursePlacesPourMille;

  /// La duree d'une bourse avant sa revue, en mois.
  final int? bourseDureeMois;

  /// Le plafond des remises cumulees (foyer, prepaiement), en pour mille du
  /// prix.
  final int? cumulMaxPourMille;

  /// Le jour du mois ou l'acces d'un mois non regle est suspendu.
  final int? jourSuspension;

  /// La remise de rang qui s'applique au membre payant de rang [rang]
  /// (1 = premier), ou `null` quand ce rang n'en a aucune.
  RemiseRang? remiseRangPour(int rang) {
    RemiseRang? retenue;
    for (final RemiseRang r in remisesParRang) {
      if (r.aPartirDuRang <= rang) retenue = r;
    }
    return retenue;
  }

  /// La remise en montant du membre payant de rang [rang] (1 = premier), ou
  /// `null` quand ce rang n'en a aucune ou qu'elle est en pour mille.
  /// Lecture de la politique, jamais un calcul de prix.
  Montant? remisePourRang(int rang) => remiseRangPour(rang)?.remise;
}

/// La mensualite d'un enfant payant dans un apercu de foyer (FI-11c, guide
/// §5.7) : arretee par la source, jamais calculee dans un widget (FI6).
@immutable
class MensualiteApercu {
  /// Cree la ligne.
  const MensualiteApercu({
    required this.rang,
    required this.tarif,
    required this.mensualite,
    this.remise,
  });

  /// Le rang du membre payant (1 = premier).
  final int rang;

  /// Le tarif applique a ce rang.
  final Montant tarif;

  /// La remise de rang (negative), ou `null` quand ce rang n'en a aucune.
  final Montant? remise;

  /// La mensualite arretee de ce membre.
  final Montant mensualite;
}

/// L'apercu d'un foyer de demonstration pour une version de politique : une
/// mensualite par enfant payant, puis le total du foyer par mois.
@immutable
class ApercuFamille {
  /// Cree l'apercu.
  const ApercuFamille({required this.enfants, required this.total});

  /// Les mensualites, dans l'ordre des rangs.
  final List<MensualiteApercu> enfants;

  /// Le total du foyer par mois, arrete par la source.
  final Montant total;
}

/// L'apercu du taux horaire d'un enseignant pour une classe (guide §1.4) :
/// la base, la part d'occupation et le taux effectif, arretes par la source.
@immutable
class ApercuEnseignant {
  /// Cree l'apercu.
  const ApercuEnseignant({
    required this.capacite,
    required this.eligibles,
    required this.baseHoraire,
    required this.occupation,
    required this.tauxHoraire,
    required this.plafondHoraire,
  });

  /// La capacite de la classe.
  final int capacite;

  /// Les sieges eligibles retenus (periode financee).
  final int eligibles;

  /// La base horaire garantie.
  final Montant baseHoraire;

  /// La part d'occupation, par heure.
  final Montant occupation;

  /// Le taux horaire effectif.
  final Montant tauxHoraire;

  /// Le plafond horaire.
  final Montant plafondHoraire;
}
