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
import 'validations_demo.dart';

/// Qui enregistre une politique : « la direction », jamais « admin ».
const String _laDirection = 'La direction';

/// La politique de la Reserve en demonstration (spec §44) : une cible fixe,
/// une alimentation automatique fixe et mensuelle, la Reserve sous l'objectif.
/// Les trois autres cas du §44 (couverture en mois, regle inactive...) se
/// construisent par [PolitiqueReserveDemo.avec]. L'enregistrement ne garde la
/// nouvelle version qu'en memoire de la page : aucune ecriture reelle.
class PolitiqueReserveDemo implements PortPolitiqueReserve {
  /// La demonstration par defaut : cible fixe de 9 000 USD.
  PolitiqueReserveDemo() : this.avec(cibleFixe);

  /// La demonstration qui part de [depart].
  PolitiqueReserveDemo.avec(PolitiqueReserve depart)
    : _courante = depart,
      _journal = <EntreeJournal>[_entree('res-1', depart.version)];

  /// Cible fixe : 9 000 USD, 1 000 USD affectes chaque mois, seuil a 80 %.
  static final PolitiqueReserve cibleFixe = PolitiqueReserve(
    version: '2',
    modeObjectif: ModeObjectifReserve.montantFixe,
    montantCible: SocleComptableDemo.usd(9000),
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

  /// La Reserve sous l'objectif (§44) : 7 400 USD sur 9 000 USD, le solde
  /// du coffre Reserve strategique de la Tresorerie (`tresorerie_demo.dart`)
  /// et la Reserve d'Aujourd'hui (`aujourdhui_demo.dart`) : une seule Reserve
  /// dans toute la demonstration (CPT-FUS).
  static final IndicateursReserve sousObjectif = IndicateursReserve(
    mode: ModeObjectifReserve.montantFixe,
    objectif: SocleComptableDemo.usd(9000),
    actuel: SocleComptableDemo.usd(7400),
    manque: SocleComptableDemo.usd(1600),
    atteintPourMille: 822,
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
class DelegationFinanceDemo
    implements PortDelegationFinance, PortControleDelegation {
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
    // DELEG-FIN-1 : la delegation expire (90 jours, renouvelable), les
    // sorties au-dessus du plafond attendent 24 h, une exception existe.
    etat: EtatDelegation.active,
    expireLe: DateTime(2026, 12, 14),
    dureeJours: 90,
    delaiSortieHeures: 24,
    exceptions: <ExceptionDelegation>[
      ExceptionDelegation(
        id: 'exc-1',
        libelle: 'Délégation du Comptable',
        coffresAutorises: const <Coffre>{
          Coffre.tresorerieLibre,
          Coffre.paieADecaisser,
        },
        beneficiairesExclus: const <BeneficiaireExclu>[
          BeneficiaireExclu(id: 'ctr-02', nom: 'Karim Studio'),
        ],
        plafondParTransaction: SocleComptableDemo.usd(300),
      ),
    ],
  );

  /// Les sorties retenues par le delai de securite, en demonstration.
  final List<SortieEnAttente> _sorties = <SortieEnAttente>[
    SortieEnAttente(
      id: 'sortie-1',
      beneficiaire: 'Sayyid Youssouf Diallo',
      objet: 'Octobre 2026 · Classe Al-Fajr',
      montant: SocleComptableDemo.usd(620),
      demandeeLe: DateTime(2026, 10, 4, 9),
      liberableLe: DateTime(2026, 10, 5, 9),
    ),
    SortieEnAttente(
      id: 'sortie-2',
      beneficiaire: 'Karim Studio',
      objet: 'Montage vidéo',
      montant: SocleComptableDemo.usd(900),
      demandeeLe: DateTime(2026, 10, 4, 11),
      liberableLe: DateTime(2026, 10, 5, 11),
    ),
  ];

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
      etat: ancienne.etat,
      suspendueLe: ancienne.suspendueLe,
      expireLe: ancienne.expireLe,
      dureeJours: ancienne.dureeJours,
      delaiSortieHeures: ancienne.delaiSortieHeures,
      exceptions: brouillon.exceptions,
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

  PolitiqueDelegationFinance _avecEtat(
    EtatDelegation etat, {
    DateTime? suspendueLe,
    DateTime? expireLe,
  }) {
    final PolitiqueDelegationFinance p = _courante;
    final String version = '${(int.tryParse(p.version) ?? 0) + 1}';
    return _courante = PolitiqueDelegationFinance(
      version: version,
      paiementsStandardsAutorises: p.paiementsStandardsAutorises,
      plafondParTransaction: p.plafondParTransaction,
      plafondParLot: p.plafondParLot,
      plafondParPeriode: p.plafondParPeriode,
      remboursementStandardAutorise: p.remboursementStandardAutorise,
      alimentationReserveAutorisee: p.alimentationReserveAutorisee,
      retraitReserveInterdit: p.retraitReserveInterdit,
      premierPaiementSecondeValidation: p.premierPaiementSecondeValidation,
      coordonneesRecentesSecondeValidation:
          p.coordonneesRecentesSecondeValidation,
      joursCoordonneesRecentes: p.joursCoordonneesRecentes,
      autoPayoutInterdit: true,
      montantManuelInterdit: true,
      politiqueTarifaireInterdite: true,
      dateEffet: SocleComptableDemo.aujourdhui,
      auteur: _laDirection,
      etat: etat,
      suspendueLe: suspendueLe ?? p.suspendueLe,
      expireLe: expireLe ?? p.expireLe,
      dureeJours: p.dureeJours,
      delaiSortieHeures: p.delaiSortieHeures,
      exceptions: p.exceptions,
    );
  }

  void _inscrire(String objet, String etat) => _journal.insert(
    0,
    EntreeJournal(
      id: 'del-j-${_journal.length + 1}',
      date: SocleComptableDemo.aujourdhui,
      initiateur: _laDirection,
      objet: objet,
      nouvelEtat: etat,
    ),
  );

  @override
  Future<PolitiqueDelegationFinance> suspendreToutes({
    required String cleIdempotence,
  }) async {
    final PolitiqueDelegationFinance p = _avecEtat(
      EtatDelegation.suspendue,
      suspendueLe: SocleComptableDemo.aujourdhui,
    );
    _inscrire('Suspension de toutes les délégations', 'Suspendues');
    return p;
  }

  @override
  Future<PolitiqueDelegationFinance> reactiver({
    required String cleIdempotence,
    required String raison,
  }) async {
    // Une delegation arrivee a expiration n'est jamais restauree : elle reste
    // `expiree`, et seul le renouvellement repart sur la duree.
    final DateTime? fin = _courante.expireLe;
    final bool expiree =
        fin != null && !fin.isAfter(SocleComptableDemo.aujourdhui);
    final PolitiqueDelegationFinance p = _avecEtat(
      expiree ? EtatDelegation.expiree : EtatDelegation.active,
    );
    _inscrire('Réactivation des délégations\u00a0: $raison', 'Réactivées');
    return p;
  }

  @override
  Future<PolitiqueDelegationFinance> renouveler({
    required String cleIdempotence,
  }) async {
    // Renouveler ne change que la date : une delegation suspendue le reste
    // (seule la reactivation, avec sa raison, leve une suspension).
    final bool suspendue = _courante.etat == EtatDelegation.suspendue;
    final PolitiqueDelegationFinance p = _avecEtat(
      suspendue ? EtatDelegation.suspendue : EtatDelegation.active,
      expireLe: SocleComptableDemo.aujourdhui.add(
        Duration(days: _courante.dureeJours ?? 90),
      ),
    );
    _inscrire(
      'Renouvellement de la délégation',
      suspendue ? 'Suspendue' : 'Active',
    );
    return p;
  }

  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() async =>
      List<SortieEnAttente>.unmodifiable(_sorties);

  @override
  Future<void> annulerSortie({
    required String sortieId,
    required String cleIdempotence,
  }) async {
    _sorties.removeWhere((SortieEnAttente s) => s.id == sortieId);
    _inscrire('Annulation d\'une sortie en attente', 'Annulée');
  }
}

/// Les instances de la demonstration, gardees pour toute la vie de la page :
/// la demonstration Finance reconstruit ses surcharges a chaque rendu, et une
/// version enregistree ne doit pas s'effacer.
final PolitiqueReserveDemo _reserve = PolitiqueReserveDemo();
final DelegationFinanceDemo _delegation = DelegationFinanceDemo();

/// Les surcharges de la demonstration Direction (lues aussi par la
/// demonstration Finance, `/demo/finance?ecran=reserveDelegation` et
/// `?ecran=aValider`). Les validations lisent le registre unique de la
/// demonstration au nom de [validations] (la direction par defaut ; la
/// coquille du Comptable y passe le Comptable, CPT-VAL-1).
List<Override> surchargesDemoDirection({
  ValidationsFinanceDemo validations = const ValidationsFinanceDemo(),
}) => <Override>[
  portPolitiqueReserveProvider.overrideWithValue(_reserve),
  portDelegationFinanceProvider.overrideWithValue(_delegation),
  portControleDelegationProvider.overrideWithValue(_delegation),
  portValidationsFinanceProvider.overrideWithValue(validations),
];
