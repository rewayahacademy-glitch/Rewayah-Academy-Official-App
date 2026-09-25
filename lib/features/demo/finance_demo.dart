// Finance fictive de la demonstration tuteur (LT-2).
//
// Aucun appel serveur, jamais en production (surchargesDemoTuteur). Les
// montants sont exprimes en `XTS`, code ISO 4217 reserve aux essais : aucune
// valeur ne peut passer pour un prix reel. Aucun calcul : chaque nombre,
// total compris, est ecrit en dur. Le devis (DB-FIN-03), le paiement
// (DB-FIN-04) et l'annulation (DB-FIN-06) restent indisponibles meme ici :
// jamais un succes qui pourrait passer pour reel.

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_foyer.dart';
import 'mode_demonstration.dart';

/// Finance hors serveur des eleves fictifs.
class FinanceFoyerDemo implements PortFinanceFoyer {
  const FinanceFoyerDemo();

  /// Code ISO 4217 reserve aux essais.
  static const String devise = 'XTS';

  static final Map<String, int> _montants = <String, int>{
    DonneesDemo.aichaId: 1200,
    DonneesDemo.yusufId: 800,
  };

  static final List<MouvementSolde> _mouvements = <MouvementSolde>[
    for (final String id in _montants.keys) ...<MouvementSolde>[
      MouvementSolde(
        id: 'demo-mvt-$id-recharge',
        profilId: id,
        natureServeur: 'demo_recharge',
        statutServeur: 'demo_confirme',
        montantSigneMineur: 1000,
        devise: devise,
        date: DateTime.utc(2026, 9, 1, 10),
      ),
      MouvementSolde(
        id: 'demo-mvt-$id-seance',
        profilId: id,
        natureServeur: 'demo_consommation',
        statutServeur: 'demo_confirme',
        montantSigneMineur: -100,
        devise: devise,
        date: DateTime.utc(2026, 9, 8, 16, 45),
        seanceId: 'demo-seance-$id--14',
      ),
      MouvementSolde(
        id: 'demo-mvt-$id-remise',
        profilId: id,
        natureServeur: 'demo_remise_seance',
        statutServeur: 'demo_confirme',
        montantSigneMineur: 100,
        devise: devise,
        date: DateTime.utc(2026, 9, 15, 17),
        seanceId: 'demo-seance-$id--7',
      ),
    ],
  ];

  static Future<T> _manque<T>(String code) =>
      Future<T>.error(CapaciteIndisponible(code));

  static MouvementSolde? _remiseDe(String id) {
    for (final MouvementSolde m in _mouvements) {
      if (m.profilId == id && m.natureServeur == 'demo_remise_seance') {
        return m;
      }
    }
    return null;
  }

  static SoldeProfil _solde(String id) => SoldeProfil(
    profilId: id,
    montantMineur: _montants[id],
    devise: _montants.containsKey(id) ? devise : null,
    derniereRemise: _remiseDe(id),
  );

  @override
  Future<SoldesFoyer> soldes() async => SoldesFoyer(
    profils: <SoldeProfil>[for (final String id in _montants.keys) _solde(id)],
    // Total ecrit en dur, comme un serveur le rendrait.
    totaux: const <TotalSoldes>[
      TotalSoldes(montantMineur: 2000, devise: devise),
    ],
    complet: true,
    luLe: DateTime.now().toUtc(),
  );

  @override
  Future<List<MouvementSolde>> mouvements({String? profilId}) async =>
      _mouvements
          .where(
            (MouvementSolde m) => profilId == null || m.profilId == profilId,
          )
          .toList();

  @override
  Future<MouvementSolde?> mouvement(String id) async {
    for (final MouvementSolde m in _mouvements) {
      if (m.id == id) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<List<OffreRecharge>> offresRecharge(List<String> profilIds) async =>
      <OffreRecharge>[
        for (final String id in profilIds)
          if (_montants.containsKey(id))
            OffreRecharge(
              id: 'demo-offre-$id',
              profilId: id,
              prixMineur: 1000,
              devise: devise,
              quantiteMineure: 1000,
            ),
      ];

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) =>
      _manque('DB-FIN-03');

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) => _manque('DB-FIN-04');

  @override
  bool get annulationDisponible => true;

  @override
  Future<ApercuAnnulation> apercuAnnulation(List<String> profilIds) async =>
      ApercuAnnulation(
        reference: 'demo-apercu',
        profils: <ConsequencesAnnulation>[
          for (final String id in profilIds)
            _montants.containsKey(id)
                ? ConsequencesAnnulation(
                    profilId: id,
                    eligible: true,
                    consequencesServeur: const <String>[
                      'demo_seances_futures_retirees',
                      'demo_solde_conserve',
                    ],
                    repriseDisponible: true,
                    dateEffet: DonneesDemo.finAcces,
                    soldeConserve: _solde(id),
                  )
                : ConsequencesAnnulation(
                    profilId: id,
                    eligible: false,
                    consequencesServeur: const <String>[],
                    repriseDisponible: false,
                    motifServeur: 'demo_profil_inconnu',
                  ),
        ],
      );

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) => _manque('DB-FIN-06');
}
