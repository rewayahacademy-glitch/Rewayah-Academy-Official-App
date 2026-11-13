import 'package:rewayah_academy/core/journal_sorties/port_journal_sorties.dart';

/// HORS-SALLE-2 : un faux journal des sorties, qui garde ce qu'on lui
/// demande et rend ce qu'on lui donne.
class FauxJournalSorties implements PortJournalSorties {
  /// Cree le faux.
  FauxJournalSorties({
    this.etat,
    this.sorties = const <SortieApp>[],
    this.reglagesRendus,
    this.refus,
  });

  /// L'etat des accords rendu (null : serveur ancien).
  EtatAccordsSorties? etat;

  /// Les sorties rendues.
  List<SortieApp> sorties;

  /// Les reglages rendus.
  ReglagesSorties? reglagesRendus;

  /// Un refus a lever a l'acceptation.
  Exception? refus;

  /// Les notes recues.
  final List<
    ({String seanceId, int secondes, bool sortieSalle, String? eleveId})
  >
  notes =
      <({String seanceId, int secondes, bool sortieSalle, String? eleveId})>[];

  /// Les accords donnes.
  final List<(String, String)> acceptes = <(String, String)>[];

  /// Les accords retires.
  final List<String> retires = <String>[];

  EtatAccordsSorties _avec(String eleveId, {required bool enCours}) {
    final EtatAccordsSorties e = etat!;
    return etat = EtatAccordsSorties(
      journalActif: e.journalActif,
      versionCourante: e.versionCourante,
      eleves: <AccordSortiesEleve>[
        for (final AccordSortiesEleve a in e.eleves)
          a.eleveId == eleveId
              ? AccordSortiesEleve(
                  eleveId: a.eleveId,
                  prenom: a.prenom,
                  autonome: a.autonome,
                  enCours: enCours,
                  accepteLe: enCours ? DateTime.utc(2026, 11, 13, 9) : null,
                )
              : a,
      ],
    );
  }

  @override
  Future<bool> noterSortie({
    required String seanceId,
    required int secondes,
    required bool sortieSalle,
    String? eleveId,
  }) async {
    notes.add((
      seanceId: seanceId,
      secondes: secondes,
      sortieSalle: sortieSalle,
      eleveId: eleveId,
    ));
    return true;
  }

  @override
  Future<List<SortieApp>> sortiesSeance(String seanceId) async => sorties;

  @override
  Future<EtatAccordsSorties?> accords() async => etat;

  @override
  Future<EtatAccordsSorties> accepter({
    required String eleveId,
    required String version,
  }) async {
    final Exception? r = refus;
    if (r != null) throw r;
    acceptes.add((eleveId, version));
    return _avec(eleveId, enCours: true);
  }

  @override
  Future<EtatAccordsSorties> retirer(String eleveId) async {
    retires.add(eleveId);
    return _avec(eleveId, enCours: false);
  }

  @override
  Future<ReglagesSorties?> reglages() async => reglagesRendus;
}

/// Trois sorties de Yasmine sur une seance : 45 s, 1 min 30 (sortie de la
/// salle), 2 min.
List<SortieApp> troisSorties(String eleveId, {String prenom = 'Yasmine'}) {
  SortieApp s(int h, int m, int duree, {bool salle = false}) {
    final DateTime sortie = DateTime.utc(2026, 11, 12, h, m);
    return SortieApp(
      eleveId: eleveId,
      prenom: prenom,
      sortieLe: sortie,
      retourLe: sortie.add(Duration(seconds: duree)),
      dureeSecondes: duree,
      sortieSalle: salle,
    );
  }

  return <SortieApp>[s(18, 12, 45), s(18, 20, 90, salle: true), s(18, 41, 120)];
}
