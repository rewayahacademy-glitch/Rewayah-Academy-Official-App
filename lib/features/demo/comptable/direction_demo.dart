// La demonstration du delta Direction (CPT-BR-09, 12, 13). Posee par CPT-F
// avec une politique neutre ; **propriete de la voie CPT-DIR ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 a tenir par CPT-DIR :
// politique cible fixe, politique couverture en mois, allocation automatique
// fixe, Reserve sous l'objectif ; `tresorerie_demo.dart` (CPT-TRES) lit la
// meme politique par `portPolitiqueReserveProvider`. Aucune ecriture reelle.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/modeles_comptable.dart';
import 'socle_comptable_demo.dart';

/// La politique de la Reserve en demonstration : regle inactive, aucun
/// chiffre, tant que CPT-DIR-1 n'a pas pose les trois politiques §44.
class PolitiqueReserveDemo implements PortPolitiqueReserve {
  /// Cree le double.
  const PolitiqueReserveDemo();

  static const PolitiqueReserve _neutre = PolitiqueReserve(
    version: 'demo-0',
    modeObjectif: ModeObjectifReserve.montantFixe,
    montantCible: SocleComptableDemo.zero,
    regleAlimentation: RegleAlimentation.desactivee,
    cadence: CadenceAlimentation.manuelle,
    retraitSoumisValidation: true,
  );

  @override
  Future<PolitiqueReserve> politique() async => _neutre;

  @override
  Future<IndicateursReserve> indicateurs() async =>
      SocleComptableDemo.reserveVide;

  @override
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  }) async => _neutre;

  @override
  Future<List<EntreeJournal>> journal() async => const <EntreeJournal>[];
}

/// La delegation en demonstration : tout ferme, aucun plafond rendu.
class DelegationFinanceDemo implements PortDelegationFinance {
  /// Cree le double.
  const DelegationFinanceDemo();

  static const PolitiqueDelegationFinance _neutre = PolitiqueDelegationFinance(
    version: 'demo-0',
    paiementsStandardsAutorises: false,
    remboursementStandardAutorise: false,
    alimentationReserveAutorisee: false,
    retraitReserveInterdit: true,
    premierPaiementSecondeValidation: true,
    coordonneesRecentesSecondeValidation: true,
    autoPayoutInterdit: true,
    montantManuelInterdit: true,
    politiqueTarifaireInterdite: true,
  );

  @override
  Future<PolitiqueDelegationFinance> politique() async => _neutre;

  @override
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  }) async => _neutre;

  @override
  Future<List<EntreeJournal>> journal() async => const <EntreeJournal>[];
}

/// Les validations en demonstration : aucune demande (l'ecran Direction
/// attend CPT-Q1).
class ValidationsFinanceDemo implements PortValidationsFinance {
  /// Cree le double.
  const ValidationsFinanceDemo();

  @override
  Future<List<DemandeValidation>> demandes(
    FiltreDemandesValidation filtre,
  ) async => const <DemandeValidation>[];

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    String? motif,
  }) => throw UnsupportedError('Aucune demande en demonstration.');

  @override
  Future<List<EntreeJournal>> journal(String demandeId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration Direction (lues aussi par la
/// demonstration Finance, `/demo/finance?ecran=reserveDelegation`).
List<Override> surchargesDemoDirection() => <Override>[
  portPolitiqueReserveProvider.overrideWithValue(const PolitiqueReserveDemo()),
  portDelegationFinanceProvider.overrideWithValue(
    const DelegationFinanceDemo(),
  ),
  portValidationsFinanceProvider.overrideWithValue(
    const ValidationsFinanceDemo(),
  ),
];
