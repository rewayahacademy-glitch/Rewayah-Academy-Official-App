// La demonstration de la tresorerie (CPT-BR-04, 05 ; CPT-TRES-1 et 2).
// **Hors production** (K-09) : aucune source serveur, aucun mouvement reel.
//
// Spec §44 tenue ici : sept coffres chiffres (montants realistes, marques
// demonstration, sans les valeurs des planches, DR-24), une prevision datee,
// un historique d'allocations, des mouvements permis par la politique (vers
// une protection = delegable ; sortie d'un coffre protege = validation
// supplementaire), un retrait de la Reserve strategique **sans capacite,
// bloque** (R-FIN-10) et un transfert simule qui rend l'etat d'un port,
// jamais un succes local. La Reserve (indicateurs, politique) se lit dans
// `direction_demo.dart` (CPT-DIR), par `portPolitiqueReserveProvider`.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_tresorerie.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import 'socle_comptable_demo.dart';

/// La tresorerie en demonstration.
class TresorerieDemo implements PortTresorerie {
  /// Cree le double.
  const TresorerieDemo();

  static Montant _usd(int unites) => SocleComptableDemo.usd(unites);

  /// Les sept coffres, parts rendues en pour mille comme le ferait la source
  /// (Flutter ne les calcule pas).
  static final List<SoldeCoffre> soldes = <SoldeCoffre>[
    SoldeCoffre(
      coffre: Coffre.fondsClientsEngages,
      montant: _usd(14200),
      partPourMille: 292,
    ),
    SoldeCoffre(
      coffre: Coffre.paieADecaisser,
      montant: _usd(9850),
      partPourMille: 202,
    ),
    SoldeCoffre(
      coffre: Coffre.chargesEssentielles,
      montant: _usd(4300),
      partPourMille: 88,
    ),
    SoldeCoffre(
      coffre: Coffre.taxesObligations,
      montant: _usd(2150),
      partPourMille: 44,
    ),
    SoldeCoffre(
      coffre: Coffre.reserveStrategique,
      montant: _usd(7400),
      partPourMille: 152,
    ),
    SoldeCoffre(
      coffre: Coffre.enTransit,
      montant: _usd(1250),
      partPourMille: 26,
    ),
    SoldeCoffre(
      coffre: Coffre.tresorerieLibre,
      montant: _usd(9500),
      partPourMille: 195,
    ),
  ];

  /// Les couples permis au Comptable de la demonstration.
  static final List<MouvementPermis> permis = <MouvementPermis>[
    MouvementPermis(
      origine: Coffre.tresorerieLibre,
      destination: Coffre.reserveStrategique,
      sensible: false,
      montantPropose: _usd(600),
    ),
    const MouvementPermis(
      origine: Coffre.tresorerieLibre,
      destination: Coffre.chargesEssentielles,
      sensible: false,
    ),
    const MouvementPermis(
      origine: Coffre.tresorerieLibre,
      destination: Coffre.taxesObligations,
      sensible: false,
    ),
    const MouvementPermis(
      origine: Coffre.chargesEssentielles,
      destination: Coffre.tresorerieLibre,
      sensible: true,
    ),
  ];

  /// Les couples refuses : le retrait de la Reserve sans capacite (R-FIN-10).
  static const List<MouvementBloque> bloques = <MouvementBloque>[
    MouvementBloque(
      origine: Coffre.reserveStrategique,
      destination: Coffre.tresorerieLibre,
      raison: RaisonBlocage.capaciteAbsente,
    ),
  ];

  @override
  Future<SyntheseTresorerie> resume() async => SyntheseTresorerie(
    detenue: _usd(48650),
    libre: _usd(9500),
    protegee: _usd(37900),
    enTransit: _usd(1250),
  );

  @override
  Future<List<SoldeCoffre>> coffres() async => soldes;

  @override
  Future<List<EntreeJournal>> historique(
    FiltreHistoriqueTresorerie filtre,
  ) async => <EntreeJournal>[
    EntreeJournal(
      id: 'mvt-demo-03',
      date: DateTime(2026, 10, 1),
      initiateur: SocleComptableDemo.leComptable.nom,
      objet: 'Trésorerie libre → Réserve stratégique',
      ancienEtat: 'Préparé',
      nouvelEtat: 'Exécuté',
      montant: _usd(500),
      reference: 'MVT-DEMO-0003',
    ),
    EntreeJournal(
      id: 'mvt-demo-02',
      date: DateTime(2026, 9, 30),
      initiateur: 'Allocation automatique (démonstration)',
      objet: 'Encaissements consolidés → Fonds clients engagés',
      nouvelEtat: 'Exécuté',
      montant: _usd(3200),
      reference: 'MVT-DEMO-0002',
    ),
    EntreeJournal(
      id: 'mvt-demo-01',
      date: DateTime(2026, 9, 28),
      initiateur: SocleComptableDemo.leComptable.nom,
      objet: 'Trésorerie libre → Taxes & obligations',
      ancienEtat: 'Préparé',
      nouvelEtat: 'Exécuté',
      montant: _usd(700),
      reference: 'MVT-DEMO-0001',
    ),
  ];

  @override
  Future<List<LignePrevision>> prevision() async => <LignePrevision>[
    LignePrevision(
      date: DateTime(2026, 10, 10),
      libelle: "Paie d'octobre des enseignants (démonstration)",
      montant: _usd(9850),
    ),
    LignePrevision(
      date: DateTime(2026, 10, 12),
      libelle: 'Échéances des contractuels (démonstration)',
      montant: _usd(1900),
    ),
    LignePrevision(
      date: DateTime(2026, 10, 15),
      libelle: 'Encaissements attendus des familles (démonstration)',
      montant: _usd(6400),
      entree: true,
    ),
    LignePrevision(
      date: DateTime(2026, 10, 31),
      libelle: 'Allocation Taxes & obligations du mois (démonstration)',
      montant: _usd(2150),
    ),
  ];

  @override
  Future<List<MouvementPermis>> mouvementsPermis() async => permis;

  @override
  Future<List<MouvementBloque>> mouvementsBloques() async => bloques;

  /// Simule la reponse d'une source : un couple refuse ou absent est refuse
  /// avec sa raison ; une sortie de coffre protege ouvre une demande de
  /// validation (rien ne bouge) ; un mouvement vers une protection est
  /// « execute » avec son entree de journal. Les soldes de la demonstration
  /// ne changent pas : Flutter ne recalcule jamais un solde.
  @override
  Future<ResultatMouvement> transferer({
    required Coffre origine,
    required Coffre destination,
    required Montant montant,
    required String cleIdempotence,
  }) async {
    final String id = 'mvt-demo-$cleIdempotence';
    for (final MouvementBloque b in bloques) {
      if (b.origine == origine && b.destination == destination) {
        return ResultatMouvement(
          mouvementId: id,
          execute: false,
          refus: b.raison,
        );
      }
    }
    MouvementPermis? couple;
    for (final MouvementPermis m in permis) {
      if (m.origine == origine && m.destination == destination) couple = m;
    }
    if (couple == null) {
      return ResultatMouvement(
        mouvementId: id,
        execute: false,
        refus: RaisonBlocage.horsDelegation,
      );
    }
    if (couple.sensible || origine.protege) {
      return ResultatMouvement(
        mouvementId: id,
        execute: false,
        validation: EtatDemandeValidation.enAttente,
      );
    }
    return ResultatMouvement(
      mouvementId: id,
      execute: true,
      journal: EntreeJournal(
        id: id,
        date: SocleComptableDemo.aujourdhui,
        initiateur: SocleComptableDemo.leComptable.nom,
        objet: 'Mouvement entre coffres (démonstration)',
        nouvelEtat: 'Exécuté',
        montant: montant,
        reference: 'MVT-DEMO-0004',
      ),
    );
  }

  @override
  Future<List<EntreeJournal>> journal(String mouvementId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration de la tresorerie.
List<Override> surchargesDemoTresorerie() => <Override>[
  portTresorerieProvider.overrideWithValue(const TresorerieDemo()),
];
