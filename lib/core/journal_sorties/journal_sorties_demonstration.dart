// HORS-SALLE-2 : le journal des sorties de demonstration (PLAYGROUND
// seulement, force a `false` en production). Il suit les regles du serveur
// pour qu'une demonstration ne promette rien de faux : journal allume, accord
// donne par le tuteur, retrait qui arrete le releve.

import 'port_journal_sorties.dart';

/// Le journal des sorties en memoire.
class JournalSortiesDemonstration implements PortJournalSorties {
  /// Cree la demonstration, avec un enfant sans accord.
  JournalSortiesDemonstration({DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now;

  final DateTime Function() _maintenant;

  static const String _version = 'sorties-2026-11-v1';

  final Map<String, DateTime?> _accords = <String, DateTime?>{
    'demo-eleve-1': null,
  };

  final List<SortieApp> _lignes = <SortieApp>[];

  @override
  Future<bool> noterSortie({
    required String seanceId,
    required int secondes,
    required bool sortieSalle,
    String? eleveId,
  }) async {
    final String eleve = eleveId ?? 'demo-eleve-1';
    if (_accords[eleve] == null) return false;
    final DateTime retour = _maintenant();
    _lignes.add(
      SortieApp(
        eleveId: eleve,
        prenom: 'Yasmine',
        sortieLe: retour.subtract(Duration(seconds: secondes < 1 ? 1 : secondes)),
        retourLe: retour,
        dureeSecondes: secondes < 1 ? 1 : secondes,
        sortieSalle: sortieSalle,
      ),
    );
    return true;
  }

  @override
  Future<List<SortieApp>> sortiesSeance(String seanceId) async =>
      List<SortieApp>.unmodifiable(_lignes);

  EtatAccordsSorties _etat() => EtatAccordsSorties(
    journalActif: true,
    versionCourante: _version,
    eleves: <AccordSortiesEleve>[
      for (final MapEntry<String, DateTime?> a in _accords.entries)
        AccordSortiesEleve(
          eleveId: a.key,
          prenom: 'Yasmine',
          autonome: false,
          enCours: a.value != null,
          accepteLe: a.value,
        ),
    ],
  );

  @override
  Future<EtatAccordsSorties?> accords() async => _etat();

  @override
  Future<EtatAccordsSorties> accepter({
    required String eleveId,
    required String version,
  }) async {
    if (version != _version) {
      throw const AccordSortiesRefuse(MotifRefusAccord.versionPerimee);
    }
    _accords[eleveId] = _maintenant();
    return _etat();
  }

  @override
  Future<EtatAccordsSorties> retirer(String eleveId) async {
    _accords[eleveId] = null;
    return _etat();
  }

  @override
  Future<ReglagesSorties?> reglages() async => const ReglagesSorties(
    journalActif: true,
    delai: Duration(seconds: 30),
  );
}
