// La demonstration des obligations de contractuels (CPT-BR-08). Posee vide
// par CPT-F ; **propriete de la voie CPT-CTR ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §22.4 a tenir par CPT-CTR :
// « Karim Studio - Facture #024 - 350 USD »
// (`SocleComptableDemo.obligationFacture024`). Aucune ecriture reelle.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/modeles_comptable.dart';

/// Les obligations de contractuels en demonstration : vides tant que
/// CPT-CTR-1 ne les a pas remplies.
class ObligationsContractuelsDemo implements PortObligationsContractuels {
  /// Cree le double.
  const ObligationsContractuelsDemo();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-08');

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) async => const <ObligationContractuel>[];

  @override
  Future<ObligationContractuel> detail(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> creer({
    required BrouillonObligationContractuel brouillon,
    required String cleIdempotence,
  }) => Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> approuver(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> inviterBeneficiaire(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String obligationId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration des contractuels.
List<Override> surchargesDemoContractuels() => <Override>[
  portObligationsContractuelsProvider.overrideWithValue(
    const ObligationsContractuelsDemo(),
  ),
];
