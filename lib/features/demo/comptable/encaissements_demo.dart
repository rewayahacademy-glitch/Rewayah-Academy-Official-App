// La demonstration des encaissements et du rapprochement (CPT-BR-07, 14,
// 15). Posee vide par CPT-F ; **propriete de la voie CPT-ENC ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 a tenir par CPT-ENC :
// 3 encaissements, 1 remboursement, 2 rapprochements, 1 doublon potentiel.
// Aucun appel serveur.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_encaissements.dart';
import '../../../core/capacites/port_rapprochement.dart';
import '../../../core/comptable/modeles_comptable.dart';

/// Les encaissements en demonstration : vides tant que CPT-ENC-1 ne les a
/// pas remplis.
class EncaissementsDemo implements PortEncaissements {
  /// Cree le double.
  const EncaissementsDemo();

  @override
  Future<List<Encaissement>> liste(FiltreEncaissements filtre) async =>
      const <Encaissement>[];

  @override
  Future<Encaissement> detail(String encaissementId) =>
      Future<Encaissement>.error(const CapaciteIndisponible('CPT-BR-07'));

  @override
  Future<List<Remboursement>> remboursements(
    FiltreRemboursements filtre,
  ) async => const <Remboursement>[];

  @override
  Future<Remboursement> executerRemboursement({
    required String remboursementId,
    required String cleIdempotence,
  }) => Future<Remboursement>.error(const CapaciteIndisponible('CPT-BR-15'));

  @override
  Future<List<EntreeJournal>> journal(String objetId) async =>
      const <EntreeJournal>[];
}

/// Le rapprochement en demonstration : vide tant que CPT-ENC-2 ne l'a pas
/// rempli.
class RapprochementDemo implements PortRapprochement {
  /// Cree le double.
  const RapprochementDemo();

  @override
  Future<List<ElementRapprochement>> aRapprocher(
    FiltreRapprochement filtre,
  ) async => const <ElementRapprochement>[];

  @override
  Future<PropositionRapprochement> proposer(String transactionId) async =>
      PropositionRapprochement(
        transactionId: transactionId,
        candidats: const <ElementRapprochement>[],
      );

  @override
  Future<ElementRapprochement> rapprocher({
    required String transactionId,
    required String cibleId,
    required String cleIdempotence,
  }) => Future<ElementRapprochement>.error(
    const CapaciteIndisponible('CPT-BR-14'),
  );

  @override
  Future<ElementRapprochement> marquerDoublon({
    required String transactionId,
    required String cleIdempotence,
  }) => Future<ElementRapprochement>.error(
    const CapaciteIndisponible('CPT-BR-14'),
  );

  @override
  Future<List<EntreeJournal>> journal(String elementId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration des encaissements.
List<Override> surchargesDemoEncaissements() => <Override>[
  portEncaissementsProvider.overrideWithValue(const EncaissementsDemo()),
  portRapprochementProvider.overrideWithValue(const RapprochementDemo()),
];
