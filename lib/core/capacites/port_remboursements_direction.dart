// FN-115c (pilote, 02/11/2026) : « Rembourser » depuis l'ecran Finance de la
// direction. Decision du directeur du 01/11/2026 (point 7) : le serveur
// propose le montant juste, la direction confirme, l'application rembourse
// par le prestataire.
//
// **Aucun calcul ici** : le montant propose et son detail sont arretes par le
// serveur (`remboursement_paiements_eleve`) ; la confirmation est plafonnee
// par le serveur ; l'envoi au prestataire relit la demande cote serveur.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La regle qui a donne le montant propose.
enum RegleRemboursement {
  /// Dans le delai : ce qui a ete paye, moins les seances suivies.
  delai,

  /// Une formule payee d'avance : les mois commences au prix mensuel normal.
  prepaiement,

  /// Un mois paye, apres le delai : rien a rendre.
  horsDelai,

  /// Rien a rembourser (paiement non abouti, deja rendu).
  aucune,
}

/// Un paiement d'un eleve, avec ce que le serveur propose de rendre.
class PaiementRemboursable {
  /// Cree le paiement.
  const PaiementRemboursable({
    required this.commandeId,
    required this.reference,
    required this.payeLe,
    required this.paye,
    required this.propose,
    required this.regle,
    this.dejaRendu,
    this.seancesSuivies = 0,
    this.prixSeance,
    this.moisCommences = 0,
    this.prixMensuel,
    this.delaiJours,
  });

  /// La commande payee.
  final String commandeId;

  /// La reference de la commande (lisible par la famille).
  final String reference;

  /// La date du paiement.
  final DateTime payeLe;

  /// La part payee pour cet eleve.
  final Montant paye;

  /// Le montant juste propose par le serveur (zero : rien a rendre).
  final Montant propose;

  /// La regle appliquee.
  final RegleRemboursement regle;

  /// Deja rendu (remboursement ou contestation) et deja decide.
  final Montant? dejaRendu;

  /// Les seances suivies depuis le paiement (regle « delai »).
  final int seancesSuivies;

  /// Le prix d'une seance suivie, tire de la politique.
  final Montant? prixSeance;

  /// Les mois commences d'une formule payee d'avance.
  final int moisCommences;

  /// Le prix mensuel normal, sans remise.
  final Montant? prixMensuel;

  /// Le delai de remboursement de la politique, en jours.
  final int? delaiJours;

  /// Vrai si le serveur propose de rendre quelque chose.
  bool get remboursable => propose.mineur > 0;
}

/// L'issue de l'envoi au prestataire.
enum IssueRemboursement {
  /// Parti chez le prestataire : il apparaitra quand celui-ci le confirme.
  envoye,

  /// Deja passe aux ecritures.
  rembourse,

  /// Le prestataire a refuse ; rien n'est parti.
  refuse,
}

/// Les remboursements decides par la direction.
abstract interface class PortRemboursementsDirection {
  /// Les eleves qui ont au moins un paiement remboursable : la capacite du
  /// serveur qui montre « Rembourser » sur leur ligne.
  Future<Set<String>> elevesRemboursables();

  /// Les paiements d'un eleve, le plus recent d'abord.
  Future<List<PaiementRemboursable>> paiements(String profilId);

  /// Confirme un remboursement de [montant] (au plus le montant propose) ;
  /// rend l'identifiant de la demande. Idempotent par [cle].
  Future<String> confirmer({
    required String commandeId,
    required String profilId,
    required Montant montant,
    required String cle,
  });

  /// Envoie la demande au prestataire (idempotent par la demande).
  Future<IssueRemboursement> envoyer(String demandeId);
}

/// Sans source : aucun eleve remboursable, rien ne s'ouvre.
class RemboursementsIndisponibles implements PortRemboursementsDirection {
  /// Cree la source vide.
  const RemboursementsIndisponibles();

  static const String _dependance = 'FN-115c';

  @override
  Future<Set<String>> elevesRemboursables() async => const <String>{};

  @override
  Future<List<PaiementRemboursable>> paiements(String profilId) =>
      Future<List<PaiementRemboursable>>.error(
        const CapaciteIndisponible(_dependance),
      );

  @override
  Future<String> confirmer({
    required String commandeId,
    required String profilId,
    required Montant montant,
    required String cle,
  }) => Future<String>.error(const CapaciteIndisponible(_dependance));

  @override
  Future<IssueRemboursement> envoyer(String demandeId) =>
      Future<IssueRemboursement>.error(const CapaciteIndisponible(_dependance));
}

/// La source des remboursements de la direction.
final Provider<PortRemboursementsDirection>
portRemboursementsDirectionProvider = Provider<PortRemboursementsDirection>(
  (Ref ref) => const RemboursementsIndisponibles(),
);
