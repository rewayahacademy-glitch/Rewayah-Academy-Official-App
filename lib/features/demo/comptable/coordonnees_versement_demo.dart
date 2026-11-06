// Demonstration de « Recevoir mes paiements » (lot FINANCE-ENSEIGNANT,
// 06/11/2026) : des coordonnees fictives, deja validees, et un versement
// recu, pour la coquille du Comptable en demonstration. Aucune vraie banque.

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_coordonnees_versement.dart';
import '../../../core/capacites/port_versements_paie.dart';
import '../../../core/finance/montant.dart';

const List<ChampDemande> _champs = <ChampDemande>[
  ChampDemande(ChampVersement.titulaire),
  ChampDemande(ChampVersement.numeroCompte),
  ChampDemande(ChampVersement.swift),
  ChampDemande(ChampVersement.adressePays),
  ChampDemande(ChampVersement.adresseVille),
  ChampDemande(ChampVersement.adresseLigne),
  ChampDemande(ChampVersement.adresseEtat, siPays: <String>['US', 'CA']),
  ChampDemande(ChampVersement.codePostal, obligatoire: false),
];

/// Les coordonnees de demonstration.
class CoordonneesVersementDemo implements PortCoordonneesVersement {
  /// Cree la demonstration.
  const CoordonneesVersementDemo();

  static const MesCoordonneesVersement _etat = MesCoordonneesVersement(
    deviseCible: 'USD',
    champs: _champs,
    enregistre: true,
    complet: true,
    valide: true,
    valeurs: <ChampVersement, String>{
      ChampVersement.titulaire: 'Karima Benali',
      ChampVersement.numeroCompte: '••••0042',
      ChampVersement.swift: '••••SAJE',
      ChampVersement.adressePays: 'SA',
      ChampVersement.adresseVille: 'Djeddah',
      ChampVersement.adresseLigne: 'Al Rawdah',
    },
  );

  static const CapaciteIndisponible _demo = CapaciteIndisponible('DEMO');

  @override
  Future<MesCoordonneesVersement> mesCoordonnees() async => _etat;

  @override
  Future<MesCoordonneesVersement> enregistrer({
    required String deviseCible,
    required Map<ChampVersement, String> valeurs,
    bool compteAMonNom = true,
    LienTitulaire? lien,
    bool autorisation = false,
  }) => Future<MesCoordonneesVersement>.error(_demo);

  @override
  Future<MesCoordonneesVersement> retirer() =>
      Future<MesCoordonneesVersement>.error(_demo);

  @override
  Future<List<EntreeJournalCoordonnees>> journal() async =>
      <EntreeJournalCoordonnees>[
        EntreeJournalCoordonnees(
          id: 'demo-2',
          date: DateTime(2026, 11, 2, 10),
          retrait: false,
          validee: true,
        ),
        EntreeJournalCoordonnees(
          id: 'demo-1',
          date: DateTime(2026, 11, 1, 18),
          retrait: false,
        ),
      ];

  @override
  Future<ExportWise> exporter(DateTime mois) => Future<ExportWise>.error(_demo);

  @override
  Future<List<EnseignantVersement>> enseignants() async =>
      const <EnseignantVersement>[];

  @override
  Future<void> valider({
    required String enseignantId,
    required String coordonneesId,
  }) => Future<void>.error(_demo);
}

/// Les versements de demonstration.
class VersementsPaieDemo implements PortVersementsPaie {
  /// Cree la demonstration.
  const VersementsPaieDemo();

  static const CapaciteIndisponible _demo = CapaciteIndisponible('DEMO');

  @override
  Future<List<VersementPaie>> mesVersements() async => <VersementPaie>[
    VersementPaie(
      id: 'demo-v1',
      montant: const Montant(31050, 'USD'),
      verseLe: DateTime(2026, 11, 3),
      mois: DateTime(2026, 10),
      moyen: MoyenVersement.virementBancaire,
      annule: false,
    ),
  ];

  @override
  Future<List<VersementPaie>> versementsDirection({DateTime? mois}) =>
      mesVersements();

  @override
  Future<VersementPaie> noter(VersementANoter versement) =>
      Future<VersementPaie>.error(_demo);

  @override
  Future<VersementPaie> annuler({
    required String versementId,
    required String motif,
  }) => Future<VersementPaie>.error(_demo);
}
