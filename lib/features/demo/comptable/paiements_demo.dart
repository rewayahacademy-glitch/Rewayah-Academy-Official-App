// La demonstration des paiements sortants (CPT-BR-01, 02, 10). Posee vide par
// CPT-F ; **propriete de la voie CPT-PAY ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 a tenir par CPT-PAY :
// 15 enseignants, 5 contractuels, 12 prets, 2 infos manquantes, 1 methode
// modifiee recemment, 1 auto-payout interdit, 1 validation supplementaire,
// 1 payout echoue, 1 lot partiellement pret (« 18 prets / 3 exclus »). Les
// identites viennent de `socle_comptable_demo.dart` ; aucun paiement (K-28).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_capacite_payout.dart';
import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/capacites/port_payout.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import 'socle_comptable_demo.dart';

/// Les obligations payables en demonstration : vides tant que CPT-PAY-1 ne
/// les a pas remplies.
class ObligationsPayablesDemo implements PortObligationsPayables {
  /// Cree le double.
  const ObligationsPayablesDemo();

  @override
  Future<List<ObligationPayable>> liste(FiltreObligations filtre) async =>
      const <ObligationPayable>[];

  @override
  Future<ObligationPayable> detail(String obligationId) =>
      Future<ObligationPayable>.error(const CapaciteIndisponible('CPT-BR-01'));

  @override
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
  }) async => SignalementEcart(
    id: 'ecart-demo',
    obligationId: obligationId,
    ligneId: ligneId,
    date: SocleComptableDemo.aujourdhui,
  );

  @override
  Future<List<EntreeJournal>> journal(String obligationId) async =>
      const <EntreeJournal>[];
}

/// Le payout en demonstration : aucun lot, aucun paiement (CPT-PAY-2 pose
/// le double qui parcourt les etats avec delai).
class PayoutDemo implements PortPayout {
  /// Cree le double.
  const PayoutDemo();

  @override
  Future<PreflightLot> preflight(List<ObligationChoisie> selection) async =>
      const PreflightLot(
        id: 'preflight-demo',
        nombreBeneficiaires: 0,
        totauxParDevise: <Montant>[SocleComptableDemo.zero],
        prets: <ObligationChoisie>[],
      );

  @override
  Future<List<SuiviPayout>> soumettre({
    required String preflightId,
    required String cleIdempotence,
  }) async => const <SuiviPayout>[];

  @override
  Future<SuiviPayout> suivre(String payoutId) =>
      Future<SuiviPayout>.error(const CapaciteIndisponible('CPT-BR-02'));

  @override
  Future<DemandeValidationDeposee> demanderValidation({
    required String obligationId,
    required String motif,
  }) async => DemandeValidationDeposee(
    demandeId: 'validation-demo',
    obligationId: obligationId,
    etat: EtatDemandeValidation.enAttente,
  );
}

/// Les prestataires neutres du socle ; un corridor inconnu est « non pris
/// en charge » tant que CPT-PAY-2 n'a pas pose ses corridors.
class CapacitePayoutDemo implements PortCapacitePayout {
  /// Cree le double.
  const CapacitePayoutDemo();

  @override
  Future<List<PrestataireFinance>> prestataires() async =>
      SocleComptableDemo.prestataires;

  @override
  Future<CapacitePayout> capacite(CorridorPayout corridor) async =>
      CapacitePayout.nonPrisEnCharge;
}

/// Les surcharges de la demonstration des paiements.
List<Override> surchargesDemoPaiements() => <Override>[
  portObligationsPayablesProvider.overrideWithValue(
    const ObligationsPayablesDemo(),
  ),
  portPayoutProvider.overrideWithValue(const PayoutDemo()),
  portCapacitePayoutProvider.overrideWithValue(const CapacitePayoutDemo()),
];
