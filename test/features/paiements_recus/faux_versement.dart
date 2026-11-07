// Faux ports en memoire pour la paie Wise (lot FINANCE-ENSEIGNANT) : memes
// regles visibles que le serveur (champs requis, masquage des numeros sauf
// les 4 derniers caracteres, retrait sans effacement), sans aucun calcul de
// montant.

import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/capacites/port_versements_paie.dart';
import 'package:rewayah_academy/core/finance/montant.dart';

/// Les champs du modele Wise USD, comme le reglage du serveur.
const List<ChampDemande> champsUsd = <ChampDemande>[
  ChampDemande(ChampVersement.titulaire),
  ChampDemande(ChampVersement.numeroCompte),
  ChampDemande(ChampVersement.swift),
  ChampDemande(ChampVersement.adressePays),
  ChampDemande(ChampVersement.adresseVille),
  ChampDemande(ChampVersement.adresseLigne),
  ChampDemande(ChampVersement.adresseEtat, siPays: <String>['US', 'CA']),
  ChampDemande(ChampVersement.codePostal, obligatoire: false),
];

/// Les champs requis en Guinee.
final List<ChampVersement> champsRequisGuinee = <ChampVersement>[
  for (final ChampDemande d in champsUsd)
    if (d.obligatoire && d.demandePour('GN')) d.champ,
];

String _masque(String v) =>
    v.length <= 4 ? v : '••••${v.substring(v.length - 4)}';

/// Le faux port des coordonnees.
class FauxCoordonnees implements PortCoordonneesVersement {
  /// Cree le faux, vide ou deja rempli.
  FauxCoordonnees({
    Map<ChampVersement, String>? depart,
    this.export,
    this.paysRefuses = const <String>{},
    bool valide = true,
  }) : _valeurs = depart,
       // ignore: prefer_initializing_formals, nom public lisible pour les tests
       _valide = valide;

  Map<ChampVersement, String>? _valeurs;
  bool _valide;
  bool _aMonNom = true;
  LienTitulaire? _lien;

  /// Les accords recus par [enregistrer] (compte d'un tiers).
  final List<({bool aMonNom, LienTitulaire? lien, bool autorisation})> accords =
      <({bool aMonNom, LienTitulaire? lien, bool autorisation})>[];

  /// Les validations demandees (enseignant, coordonnees).
  final List<(String, String)> validations = <(String, String)>[];
  final List<EntreeJournalCoordonnees> _journal = <EntreeJournalCoordonnees>[];

  /// Les pays de compte refuses (referentiel : virement indisponible).
  final Set<String> paysRefuses;

  /// Ce que rend l'export ; `null` : modele Wise absent.
  final ExportWise? export;

  /// Les valeurs recues par [enregistrer], en clair (pour verifier l'envoi).
  final List<Map<ChampVersement, String>> envois =
      <Map<ChampVersement, String>>[];

  /// Le nombre d'exports demandes.
  int exports = 0;

  MesCoordonneesVersement _etat() {
    final Map<ChampVersement, String>? v = _valeurs;
    return MesCoordonneesVersement(
      deviseCible: 'USD',
      champs: champsUsd,
      enregistre: v != null,
      complet: v != null && champsRequisGuinee.every(v.containsKey),
      valide: v != null && _valide,
      compteAMonNom: _aMonNom,
      lienTitulaire: _lien,
      paysProfil: 'GN',
      valeurs: v == null
          ? const <ChampVersement, String>{}
          : <ChampVersement, String>{
              for (final MapEntry<ChampVersement, String> e in v.entries)
                e.key:
                    <ChampVersement>{
                      ChampVersement.numeroCompte,
                      ChampVersement.iban,
                      ChampVersement.swift,
                    }.contains(e.key)
                    ? _masque(e.value)
                    : e.value,
            },
    );
  }

  @override
  Future<MesCoordonneesVersement> mesCoordonnees() async => _etat();

  @override
  Future<MesCoordonneesVersement> enregistrer({
    required String deviseCible,
    required Map<ChampVersement, String> valeurs,
    bool compteAMonNom = true,
    LienTitulaire? lien,
    bool autorisation = false,
  }) async {
    if (paysRefuses.contains(valeurs[ChampVersement.adressePays])) {
      throw const PaysVersementIndisponible();
    }
    envois.add(valeurs);
    accords.add((
      aMonNom: compteAMonNom,
      lien: lien,
      autorisation: autorisation,
    ));
    // Tout changement attend la direction, comme sur le serveur.
    _valide = false;
    _aMonNom = compteAMonNom;
    _lien = compteAMonNom ? null : lien;
    _valeurs = <ChampVersement, String>{
      for (final ChampDemande d in champsUsd)
        if (valeurs[d.champ] != null) d.champ: valeurs[d.champ]!,
    };
    _journal.insert(
      0,
      EntreeJournalCoordonnees(
        id: 'j${_journal.length}',
        date: DateTime(2026, 11, 6, 22),
        retrait: false,
      ),
    );
    return _etat();
  }

  @override
  Future<MesCoordonneesVersement> retirer() async {
    _valeurs = null;
    _journal.insert(
      0,
      EntreeJournalCoordonnees(
        id: 'j${_journal.length}',
        date: DateTime(2026, 11, 6, 23),
        retrait: true,
      ),
    );
    return _etat();
  }

  @override
  Future<List<EntreeJournalCoordonnees>> journal() async =>
      List<EntreeJournalCoordonnees>.of(_journal);

  @override
  Future<List<EnseignantVersement>> enseignants() async =>
      <EnseignantVersement>[
        const EnseignantVersement(
          enseignantId: 'e1',
          nom: 'Mamadou Diallo',
          matricule: 'RA-26-4817',
          complet: true,
        ),
        const EnseignantVersement(
          enseignantId: 'e2',
          nom: 'Fatou Sow',
          matricule: 'RA-26-2210',
          complet: false,
        ),
        EnseignantVersement(
          enseignantId: 'e4',
          nom: 'Aïcha Ndiaye',
          matricule: 'RA-26-7731',
          complet: true,
          coordonneesId: 'c4',
          titulaire: 'Moussa Ndiaye',
          compteAMonNom: false,
          lienTitulaire: LienTitulaire.parent,
          autoriseLe: DateTime(2026, 11, 6, 21),
          pays: 'SA',
          numeroMasque: '••••4444',
          enregistreLe: DateTime(2026, 11, 6, 21),
        ),
      ];

  @override
  Future<void> valider({
    required String enseignantId,
    required String coordonneesId,
  }) async {
    validations.add((enseignantId, coordonneesId));
    _valide = true;
  }

  @override
  Future<ExportWise> exporter(DateTime mois) async {
    exports++;
    final ExportWise? e = export;
    if (e == null) throw const ModeleWiseAbsent();
    return e;
  }
}

/// Des coordonnees completes de demonstration (aucune vraie banque).
const Map<ChampVersement, String> coordonneesDemo = <ChampVersement, String>{
  ChampVersement.titulaire: 'Mamadou Diallo',
  ChampVersement.numeroCompte: '0012345678901',
  ChampVersement.swift: 'ECOCGNGN',
  ChampVersement.adressePays: 'GN',
  ChampVersement.adresseVille: 'Conakry',
  ChampVersement.adresseLigne: 'Quartier Kaloum',
};

/// Le faux port des versements notes.
class FauxVersements implements PortVersementsPaie {
  /// Cree le faux.
  FauxVersements({List<VersementPaie>? depart})
    : _liste = depart ?? <VersementPaie>[];

  final List<VersementPaie> _liste;

  /// Les versements recus par [noter].
  final List<VersementANoter> notes = <VersementANoter>[];

  @override
  Future<List<VersementPaie>> mesVersements() async =>
      List<VersementPaie>.of(_liste);

  @override
  Future<List<VersementPaie>> versementsDirection({DateTime? mois}) async =>
      List<VersementPaie>.of(_liste);

  @override
  Future<VersementPaie> noter(VersementANoter v) async {
    notes.add(v);
    final VersementPaie fait = VersementPaie(
      id: 'v${_liste.length + 1}',
      montant: v.montant,
      verseLe: v.verseLe,
      mois: v.mois,
      moyen: v.moyen,
      annule: false,
      reference: v.reference,
      enseignantId: v.enseignantId,
    );
    _liste.insert(0, fait);
    return fait;
  }

  @override
  Future<VersementPaie> annuler({
    required String versementId,
    required String motif,
  }) async => throw UnimplementedError();
}

/// Un versement de demonstration.
VersementPaie versementDemo({bool annule = false}) => VersementPaie(
  id: annule ? 'v-annule' : 'v-1',
  montant: const Montant(2587, 'USD'),
  verseLe: DateTime(2026, 11, 3),
  mois: DateTime(2026, 10),
  moyen: MoyenVersement.virementBancaire,
  annule: annule,
);
