// `FinanceProvider` et `PayoutCapabilityPort` (spec §1.2, §42 ; CPT-BR-10).
// Pose par CPT-F avec son interface complete ; **propriete de la voie
// CPT-PAY ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Le frontend ne suppose jamais un pays, une devise, un operateur, un solde
// ou une API disponibles : il affiche le retour de la source. Aucun
// prestataire n'est code comme obligatoire ; un prestataire non active
// n'apparait jamais operationnel.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import 'capacite_indisponible.dart';

/// Un corridor de payout : pays, devise, operateur, methode.
@immutable
class CorridorPayout {
  /// Cree le corridor.
  const CorridorPayout({
    required this.pays,
    required this.devise,
    this.operateur,
    this.methode,
  });

  /// Le pays (code rendu).
  final String pays;

  /// La devise ISO 4217.
  final String devise;

  /// L'operateur (mobile money, banque), s'il compte.
  final String? operateur;

  /// La methode (mobile money, virement), si elle compte.
  final String? methode;
}

/// Les prestataires et leurs capacites (CPT-BR-10).
abstract interface class PortCapacitePayout {
  /// Les prestataires reellement actives.
  Future<List<PrestataireFinance>> prestataires();

  /// La capacite pour un corridor (§42).
  Future<CapacitePayout> capacite(CorridorPayout corridor);
}

/// **Aucune source serveur a ce jour** (CPT-BR-10).
class CapacitePayoutIndisponible implements PortCapacitePayout {
  /// Cree l'implementation.
  const CapacitePayoutIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-10');

  @override
  Future<List<PrestataireFinance>> prestataires() =>
      Future<List<PrestataireFinance>>.error(_manque);

  @override
  Future<CapacitePayout> capacite(CorridorPayout corridor) =>
      Future<CapacitePayout>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`paiements_demo.dart`).
final Provider<PortCapacitePayout> portCapacitePayoutProvider =
    Provider<PortCapacitePayout>((Ref _) => const CapacitePayoutIndisponible());
