// La demonstration du delta Direction (CPT-BR-09, 12, 13). Posee par CPT-F
// avec une politique neutre ; **propriete de la voie CPT-DIR ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 tenu par CPT-DIR-1 :
// politique cible fixe, politique couverture en mois, allocation automatique
// fixe, Reserve sous l'objectif ; `tresorerie_demo.dart` (CPT-TRES) lit la
// meme politique par `portPolitiqueReserveProvider`. Aucune ecriture reelle :
// une version enregistree vit en memoire, le temps de la page.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import 'socle_comptable_demo.dart';

/// Qui enregistre une politique : « la direction », jamais « admin ».
const String _laDirection = 'La direction';

/// La politique de la Reserve en demonstration (spec §44) : une cible fixe,
/// une alimentation automatique fixe et mensuelle, la Reserve sous l'objectif.
/// Les trois autres cas du §44 (couverture en mois, regle inactive...) se
/// construisent par [PolitiqueReserveDemo.avec]. L'enregistrement ne garde la
/// nouvelle version qu'en memoire de la page : aucune ecriture reelle.
class PolitiqueReserveDemo implements PortPolitiqueReserve {
  /// La demonstration par defaut : cible fixe de 5 000 USD.
  PolitiqueReserveDemo() : this.avec(cibleFixe);

  /// La demonstration qui part de [depart].
  PolitiqueReserveDemo.avec(PolitiqueReserve depart)
    : _courante = depart,
      _journal = <EntreeJournal>[_entree('res-1', depart.version)];

  /// Cible fixe : 5 000 USD, 1 000 USD affectes chaque mois, seuil a 80 %.
  static final PolitiqueReserve cibleFixe = PolitiqueReserve(
    version: '2',
    modeObjectif: ModeObjectifReserve.montantFixe,
    montantCible: SocleComptableDemo.usd(5000),
    regleAlimentation: RegleAlimentation.montantFixe,
    montantAuto: SocleComptableDemo.usd(1000),
    cadence: CadenceAlimentation.mensuelle,
    seuilAlertePourMille: 800,
    retraitSoumisValidation: true,
    dateEffet: DateTime(2026, 9, 15),
    auteur: _laDirection,
  );

  /// Couverture dynamique : 3 mois de charges essentielles, completee
  /// jusqu'a l'objectif a chaque cloture.
  static final PolitiqueReserve couvertureMois = PolitiqueReserve(
    version: '3',
    modeObjectif: ModeObjectifReserve.couvertureMois,
    nombreMois: 3,
    regleAlimentation: RegleAlimentation.jusquAObjectif,
    cadence: CadenceAlimentation.clotureCycle,
    retraitSoumisValidation: true,
    dateEffet: DateTime(2026, 9, 28),
    auteur: _laDirection,
  );

  /// La Reserve sous l'objectif (§44) : 3 200 USD sur 5 000 USD.
  static final IndicateursReserve sousObjectif = IndicateursReserve(
    mode: ModeObjectifReserve.montantFixe,
    objectif: SocleComptableDemo.usd(5000),
    actuel: SocleComptableDemo.usd(3200),
    manque: SocleComptableDemo.usd(1800),
    atteintPourMille: 640,
    etat: EtatReserve.sousObjectif,
    derniereAllocation: DateTime(2026, 9, 30),
    prochaineAllocation: DateTime(2026, 10, 31),
  );

  PolitiqueReserve _courante;
  final List<EntreeJournal> _journal;

  static EntreeJournal _entree(String id, String version) => EntreeJournal(
    id: id,
    date: DateTime(2026, 9, 15),
    initiateur: _laDirection,
    objet: 'Politique de la Réserve stratégique',
    nouvelEtat: 'Version $version',
  );

  @override
  Future<PolitiqueReserve> politique() async => _courante;

  @override
  Future<IndicateursReserve> indicateurs() async => sousObjectif;

  @override
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  }) async {
    final PolitiqueReserve ancienne = _courante;
    final String version = '${(int.tryParse(ancienne.version) ?? 0) + 1}';
    _courante = PolitiqueReserve(
      version: version,
      modeObjectif: brouillon.modeObjectif,
      montantCible: brouillon.montantCible,
      nombreMois: brouillon.nombreMois,
      regleAlimentation: brouillon.regleAlimentation,
      montantAuto: brouillon.montantAuto,
      pourcentageAutoPourMille: brouillon.pourcentageAutoPourMille,
      cadence: brouillon.cadence,
      seuilAlertePourMille: brouillon.seuilAlertePourMille,
      retraitSoumisValidation: brouillon.retraitSoumisValidation,
      dateEffet: SocleComptableDemo.aujourdhui,
      auteur: _laDirection,
    );
    _journal.insert(
      0,
      EntreeJournal(
        id: 'res-$version',
        date: SocleComptableDemo.aujourdhui,
        initiateur: _laDirection,
        objet: 'Politique de la Réserve stratégique',
        ancienEtat: 'Version ${ancienne.version}',
        nouvelEtat: 'Version $version',
      ),
    );
    return _courante;
  }

  @override
  Future<List<EntreeJournal>> journal() async =>
      List<EntreeJournal>.unmodifiable(_journal);
}

/// La delegation en demonstration : paiements standards et remboursements
/// autorises sous trois plafonds de demonstration, retrait de la Reserve
/// interdit, secondes validations actives. Les trois interdits absolus sont
/// vrais. Aucune ecriture reelle : la version enregistree reste en memoire.
class DelegationFinanceDemo implements PortDelegationFinance {
  /// La demonstration par defaut.
  DelegationFinanceDemo() : this.avec(standard);

  /// La demonstration qui part de [depart].
  DelegationFinanceDemo.avec(PolitiqueDelegationFinance depart)
    : _courante = depart,
      _journal = <EntreeJournal>[_entree('del-1', depart.version)];

  /// Les pouvoirs standards, avec des plafonds de demonstration.
  static final PolitiqueDelegationFinance standard = PolitiqueDelegationFinance(
    version: '1',
    paiementsStandardsAutorises: true,
    plafondParTransaction: SocleComptableDemo.usd(500),
    plafondParLot: SocleComptableDemo.usd(2000),
    plafondParPeriode: SocleComptableDemo.usd(5000),
    remboursementStandardAutorise: true,
    alimentationReserveAutorisee: true,
    retraitReserveInterdit: true,
    premierPaiementSecondeValidation: true,
    coordonneesRecentesSecondeValidation: true,
    joursCoordonneesRecentes: 14,
    autoPayoutInterdit: true,
    montantManuelInterdit: true,
    politiqueTarifaireInterdite: true,
    dateEffet: DateTime(2026, 9, 15),
    auteur: _laDirection,
  );

  PolitiqueDelegationFinance _courante;
  final List<EntreeJournal> _journal;

  static EntreeJournal _entree(String id, String version) => EntreeJournal(
    id: id,
    date: DateTime(2026, 9, 15),
    initiateur: _laDirection,
    objet: 'Délégation financière',
    nouvelEtat: 'Version $version',
  );

  @override
  Future<PolitiqueDelegationFinance> politique() async => _courante;

  @override
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  }) async {
    final PolitiqueDelegationFinance ancienne = _courante;
    final String version = '${(int.tryParse(ancienne.version) ?? 0) + 1}';
    _courante = PolitiqueDelegationFinance(
      version: version,
      paiementsStandardsAutorises: brouillon.paiementsStandardsAutorises,
      plafondParTransaction: brouillon.plafondParTransaction,
      plafondParLot: brouillon.plafondParLot,
      plafondParPeriode: brouillon.plafondParPeriode,
      remboursementStandardAutorise: brouillon.remboursementStandardAutorise,
      alimentationReserveAutorisee: brouillon.alimentationReserveAutorisee,
      retraitReserveInterdit: brouillon.retraitReserveInterdit,
      premierPaiementSecondeValidation:
          brouillon.premierPaiementSecondeValidation,
      coordonneesRecentesSecondeValidation:
          brouillon.coordonneesRecentesSecondeValidation,
      joursCoordonneesRecentes: brouillon.joursCoordonneesRecentes,
      autoPayoutInterdit: true,
      montantManuelInterdit: true,
      politiqueTarifaireInterdite: true,
      dateEffet: SocleComptableDemo.aujourdhui,
      auteur: _laDirection,
    );
    _journal.insert(
      0,
      EntreeJournal(
        id: 'del-$version',
        date: SocleComptableDemo.aujourdhui,
        initiateur: _laDirection,
        objet: 'Délégation financière',
        ancienEtat: 'Version ${ancienne.version}',
        nouvelEtat: 'Version $version',
      ),
    );
    return _courante;
  }

  @override
  Future<List<EntreeJournal>> journal() async =>
      List<EntreeJournal>.unmodifiable(_journal);
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

/// Les instances de la demonstration, gardees pour toute la vie de la page :
/// la demonstration Finance reconstruit ses surcharges a chaque rendu, et une
/// version enregistree ne doit pas s'effacer.
final PolitiqueReserveDemo _reserve = PolitiqueReserveDemo();
final DelegationFinanceDemo _delegation = DelegationFinanceDemo();

/// Les surcharges de la demonstration Direction (lues aussi par la
/// demonstration Finance, `/demo/finance?ecran=reserveDelegation`).
List<Override> surchargesDemoDirection() => <Override>[
  portPolitiqueReserveProvider.overrideWithValue(_reserve),
  portDelegationFinanceProvider.overrideWithValue(_delegation),
  portValidationsFinanceProvider.overrideWithValue(
    const ValidationsFinanceDemo(),
  ),
];
