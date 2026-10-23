// REMPL-1 : l'adaptateur de demonstration du tableau commun des
// remplacements. Rien ne quitte l'appareil (K-28).
//
// Il simule ce que le serveur fera (ligne Backend REMPL-1) :
// - le filtre par genre : une Classe d'hommes n'est rendue qu'a un
//   enseignant, une Classe de femmes qu'a une enseignante, une Classe
//   indeterminee a tous (decision du 02/10). Le genre de l'enseignant est un
//   PARAMETRE de la demonstration, jamais une lecture de `profiles.gender` ;
// - l'acceptation atomique : le tableau est partage entre plusieurs
//   enseignants simules ; la premiere acceptation gagne, toute autre rend
//   `dejaPrise` ;
// - l'etat « prise » vu par les autres : chaque changement est diffuse a tous
//   les enseignants qui suivent le tableau.
import 'dart:async';

import '../../core/enseignant/absence_remplacement.dart';
import '../../core/enseignant/port_remplacements.dart';
import '../../core/mouvement/mouvement.dart';
import 'enseignant_demo.dart';

/// A qui s'adresse une Classe (donnee serveur, simulee ici seulement).
enum PublicClasseDemo {
  /// Classe d'hommes : proposee aux enseignants.
  hommes,

  /// Classe de femmes : proposee aux enseignantes.
  femmes,

  /// Public non precise : proposee a tous.
  indetermine,
}

/// Le genre de l'enseignant simule (parametre de demonstration).
enum GenreEnseignantDemo {
  /// Un enseignant.
  homme,

  /// Une enseignante.
  femme,
}

/// Une offre du tableau, avec ce que seul le serveur connait.
class _EntreeTableau {
  _EntreeTableau(this.offre, this.public, this.prisePar);

  final OffreRemplacement offre;
  final PublicClasseDemo public;
  String? prisePar;
}

/// Le tableau commun, partage par tous les enseignants simules.
class TableauRemplacementsDemo {
  /// Cree le tableau avec ses offres : `(offre, public, prise par)`.
  TableauRemplacementsDemo(
    List<(OffreRemplacement, PublicClasseDemo, String?)> offres,
  ) : _entrees = <_EntreeTableau>[
        for (final (OffreRemplacement, PublicClasseDemo, String?) o in offres)
          _EntreeTableau(o.$1, o.$2, o.$3),
      ];

  /// Le tableau de la demonstration enseignant : l'offre d'Al-Fatiha
  /// (ouverte a tous), une Classe d'hommes ouverte, une Classe de femmes
  /// (que l'enseignant de la demonstration ne voit pas) et une offre deja
  /// prise par un collegue.
  factory TableauRemplacementsDemo.demonstration() {
    final OffreRemplacement fatiha = DonneesEnseignantDemo.offreRemplacement();
    OffreRemplacement autre(String id, String classe, DateTime debut) =>
        OffreRemplacement(
          seanceId: id,
          classe: classe,
          debut: debut,
          fin: debut.add(const Duration(minutes: 45)),
          nbEleves: 4,
        );
    return TableauRemplacementsDemo(
      <(OffreRemplacement, PublicClasseDemo, String?)>[
        (fatiha, PublicClasseDemo.indetermine, null),
        (
          autre('demo-rempl-an-nour', 'An-Nour', DateTime(2026, 9, 30, 19)),
          PublicClasseDemo.hommes,
          null,
        ),
        (
          autre('demo-rempl-maryam', 'Maryam', DateTime(2026, 9, 30, 17)),
          PublicClasseDemo.femmes,
          null,
        ),
        (
          autre(
            'demo-rempl-al-kawthar',
            'Al-Kawthar',
            DateTime(2026, 10, 1, 18),
          ),
          PublicClasseDemo.indetermine,
          'demo-enseignant-collegue',
        ),
      ],
    );
  }

  final List<_EntreeTableau> _entrees;
  final StreamController<void> _changements =
      StreamController<void>.broadcast();

  /// Les offres que voit [enseignantId], de genre [genre].
  List<OffreCommune> visibles(String enseignantId, GenreEnseignantDemo genre) =>
      <OffreCommune>[
        for (final _EntreeTableau e in _entrees)
          if (_visible(e.public, genre))
            OffreCommune(
              offre: e.offre,
              etat: e.prisePar == null
                  ? EtatOffreCommune.ouverte
                  : e.prisePar == enseignantId
                  ? EtatOffreCommune.priseParMoi
                  : EtatOffreCommune.priseParUnCollegue,
            ),
      ];

  static bool _visible(PublicClasseDemo public, GenreEnseignantDemo genre) =>
      switch (public) {
        PublicClasseDemo.indetermine => true,
        PublicClasseDemo.hommes => genre == GenreEnseignantDemo.homme,
        PublicClasseDemo.femmes => genre == GenreEnseignantDemo.femme,
      };

  /// L'acceptation atomique : verifier et poser se font sans attente entre
  /// les deux, la premiere gagne. Une offre invisible pour [genre] est
  /// refusee comme prise (le serveur ne revele pas qu'elle existe).
  ResultatPriseRemplacement prendre(
    String seanceId,
    String enseignantId,
    GenreEnseignantDemo genre,
  ) {
    for (final _EntreeTableau e in _entrees) {
      if (e.offre.seanceId != seanceId) continue;
      if (!_visible(e.public, genre)) break;
      if (e.prisePar != null) {
        return e.prisePar == enseignantId
            ? ResultatPriseRemplacement.acceptee
            : ResultatPriseRemplacement.dejaPrise;
      }
      e.prisePar = enseignantId;
      _changements.add(null);
      return ResultatPriseRemplacement.acceptee;
    }
    return ResultatPriseRemplacement.dejaPrise;
  }

  /// Chaque changement du tableau.
  Stream<void> get changements => _changements.stream;
}

/// Le port de demonstration d'un enseignant simule.
class PortRemplacementsDemo implements PortRemplacements {
  /// Cree le port de [enseignantId], de genre [genre], sur [tableau].
  /// [horsLigne] simule l'absence de reponse a une acceptation.
  PortRemplacementsDemo({
    required this.tableau,
    required this.enseignantId,
    required this.genre,
    this.horsLigne = false,
    this.latence = Mouvement.maximum,
  });

  /// Le tableau partage.
  final TableauRemplacementsDemo tableau;

  /// L'enseignant simule.
  final String enseignantId;

  /// Son genre : un parametre de demonstration, jamais `profiles.gender`.
  final GenreEnseignantDemo genre;

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  /// Le delai de la reponse simulee.
  final Duration latence;

  @override
  Stream<List<OffreCommune>> suivre() async* {
    yield tableau.visibles(enseignantId, genre);
    await for (final void _ in tableau.changements) {
      yield tableau.visibles(enseignantId, genre);
    }
  }

  @override
  Future<ResultatPriseRemplacement> prendre(String seanceId) async {
    await Future<void>.delayed(latence);
    if (horsLigne) {
      throw StateError('aucune reponse');
    }
    return tableau.prendre(seanceId, enseignantId, genre);
  }
}
