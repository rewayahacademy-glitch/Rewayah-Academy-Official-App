import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/features/controleur/vue_planning.dart';

/// L'instant de reference de tous les calculs de ce fichier.
///
/// Fige, jamais `DateTime.now()` : le partage entre « en cours » et « a venir »
/// se compte en minutes, et un test cale sur l'horloge de la machine change de
/// resultat selon l'heure a laquelle la suite tourne.
final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

Seance _seance({
  required String id,
  required int debutDansMinutes,
  int duree = 60,
  StatutSeance? statut = StatutSeance.planifiee,
  String enseignantId = 't1',
  String enseignantPrenom = 'Rachid',
  String enseignantIdentifiant = 'TEACH-000001',
  String elevePrenom = 'Sofia',
}) {
  final DateTime debut = _maintenant.add(Duration(minutes: debutDansMinutes));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(Duration(minutes: duree)),
    statut: statut,
    eleveId: 'e-$id',
    elevePrenom: elevePrenom,
    eleveIdentifiant: 'STUD-000001',
    enseignantId: enseignantId,
    enseignantPrenom: enseignantPrenom,
    enseignantIdentifiant: enseignantIdentifiant,
  );
}

VuePlanning _vue(
  List<Seance> seances, {
  String? enseignantId,
  FiltrePlanning filtre = FiltrePlanning.tous,
  int plafond = 200,
}) => VuePlanning.depuis(
  seances: seances,
  maintenant: _maintenant,
  enseignantId: enseignantId,
  filtre: filtre,
  plafond: plafond,
);

void main() {
  group('CTR-01 : en cours se mesure sur les heures, jamais sur le statut', () {
    test('une seance commencee est en cours meme si son statut dit planifiee', () {
      // Le coeur de la decision du lot : rien dans le produit ne fait passer une
      // seance a `in_progress`. Un ecran qui attendrait ce statut n'afficherait
      // jamais un seul cours en direct, et son bouton d'entree n'existerait
      // jamais.
      final VuePlanning vue = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -10),
      ]);

      expect(vue.lignes.single.etat, EtatLignePlanning.enCours);
      expect(vue.lignes.single.observable, isTrue);
    });

    test('une seance qui commence dans une minute n\'est pas encore en cours', () {
      final VuePlanning vue = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: 1),
      ]);

      expect(vue.lignes.single.etat, EtatLignePlanning.aVenir);
      // Pas de bouton grise : pas de bouton du tout.
      expect(vue.lignes.single.observable, isFalse);
    });

    test('la fenetre survit un quart d\'heure a l\'heure de fin', () {
      // Le meme quart d'heure que `autoriser_jeton_video()` et que
      // `rejoindre_observation()` : l'ecran ne doit ni retirer une ligne dont la
      // salle est encore ouverte, ni proposer une porte que la base refuse.
      final VuePlanning dedans = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -74, duree: 60),
      ]);
      final VuePlanning dehors = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -76, duree: 60),
      ]);

      expect(dedans.lignes.single.etat, EtatLignePlanning.enCours);
      expect(dehors.lignes.single.etat, EtatLignePlanning.incident);
      expect(dehors.lignes.single.observable, isFalse);
    });

    test('un statut d\'incident prime sur l\'heure, et n\'est pas observable', () {
      for (final StatutSeance statut in <StatutSeance>[
        StatutSeance.enseignantAbsent,
        StatutSeance.eleveAbsent,
        StatutSeance.incidentTechnique,
        StatutSeance.annulee,
        StatutSeance.annuleeTard,
      ]) {
        final VuePlanning vue = _vue(<Seance>[
          _seance(id: 'a', debutDansMinutes: -10, statut: statut),
        ]);

        expect(
          vue.lignes.single.etat,
          EtatLignePlanning.incident,
          reason: 'statut $statut',
        );
        // La base accepterait l'entree pour trois de ces cinq statuts : l'ecran
        // est plus strict qu'elle, parce qu'il n'y a rien a observer d'un cours
        // qui n'a pas eu lieu.
        expect(vue.lignes.single.observable, isFalse, reason: 'statut $statut');
      }
    });

    test('un statut illisible ne fabrique pas un incident', () {
      // `StatutSeance.depuisSql` rend `null` sur une valeur inconnue. Ne pas
      // savoir dans quel etat est une seance ne veut pas dire qu'elle a mal
      // tourne : c'est l'heure qui tranche, comme pour toutes les autres.
      final VuePlanning vue = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -10, statut: null),
      ]);

      expect(vue.lignes.single.etat, EtatLignePlanning.enCours);
    });
  });

  group('CTR-01 : l\'ordre repond a « qu\'est-ce qui necessite une verification »', () {
    test('en cours d\'abord, puis les incidents, puis ce qui arrive', () {
      final VuePlanning vue = _vue(<Seance>[
        _seance(id: 'futur', debutDansMinutes: 120),
        _seance(
          id: 'incident',
          debutDansMinutes: -30,
          statut: StatutSeance.enseignantAbsent,
        ),
        _seance(id: 'direct', debutDansMinutes: -5),
        _seance(id: 'futur-proche', debutDansMinutes: 30),
      ]);

      expect(
        vue.lignes.map((LignePlanning l) => l.seance.id).toList(),
        <String>['direct', 'incident', 'futur-proche', 'futur'],
      );
    });

    test('deux seances a la meme heure gardent un ordre stable', () {
      // Sans le depart a l'identifiant, une liste relue chaque minute pourrait
      // echanger deux lignes toutes seules.
      final VuePlanning premier = _vue(<Seance>[
        _seance(id: 'b', debutDansMinutes: -5),
        _seance(id: 'a', debutDansMinutes: -5),
      ]);
      final VuePlanning second = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -5),
        _seance(id: 'b', debutDansMinutes: -5),
      ]);

      expect(
        premier.lignes.map((LignePlanning l) => l.seance.id).toList(),
        second.lignes.map((LignePlanning l) => l.seance.id).toList(),
      );
    });
  });

  group('CTR-01 : les filtres bornent la liste, jamais les facettes', () {
    List<Seance> troisSeances() => <Seance>[
      _seance(id: 'direct', debutDansMinutes: -5),
      _seance(
        id: 'autre',
        debutDansMinutes: 60,
        enseignantId: 't2',
        enseignantPrenom: 'Hafsa',
        enseignantIdentifiant: 'TEACH-000002',
      ),
      _seance(
        id: 'incident',
        debutDansMinutes: -30,
        statut: StatutSeance.incidentTechnique,
      ),
    ];

    test('le filtre d\'etat ne retient que son etat', () {
      final VuePlanning vue = _vue(
        troisSeances(),
        filtre: FiltrePlanning.enCours,
      );

      expect(vue.lignes.single.seance.id, 'direct');
      // Les compteurs restent ceux de la lecture entiere : une pilule qui
      // afficherait zero des qu'on la retient serait un piege.
      expect(vue.nombreEnCours, 1);
      expect(vue.nombreAVenir, 1);
      expect(vue.nombreIncident, 1);
      expect(vue.total, 3);
    });

    test('le filtre d\'enseignant ne retient que ses seances', () {
      final VuePlanning vue = _vue(troisSeances(), enseignantId: 't2');

      expect(vue.lignes.single.seance.id, 'autre');
      // Les deux enseignants restent proposes : sans quoi, retenir le premier
      // filtre effacerait tous les autres et il n'y aurait plus de sortie.
      expect(vue.enseignants.length, 2);
    });

    test('les facettes comptent, et se trient par prenom', () {
      final VuePlanning vue = _vue(troisSeances());

      expect(
        vue.enseignants.map((FacetteEnseignant e) => e.prenom).toList(),
        <String>['Hafsa', 'Rachid'],
      );
      expect(vue.enseignants.first.nombre, 1);
      expect(vue.enseignants.last.nombre, 2);
      // Prenom et identifiant immuable, jamais le nom de famille (ADR-008).
      expect(vue.enseignants.first.identifiant, 'TEACH-000002');
    });

    test('deux enseignants du meme prenom restent deux facettes', () {
      final VuePlanning vue = _vue(<Seance>[
        _seance(id: 'a', debutDansMinutes: -5),
        _seance(
          id: 'b',
          debutDansMinutes: 30,
          enseignantId: 't9',
          enseignantIdentifiant: 'TEACH-000009',
        ),
      ]);

      expect(vue.enseignants.length, 2);
      expect(
        vue.enseignants.map((FacetteEnseignant e) => e.identifiant).toList(),
        <String>['TEACH-000001', 'TEACH-000009'],
      );
    });

    test('une liste vide sous filtre est une impasse, une liste vide n\'en est pas une', () {
      final VuePlanning impasse = _vue(
        troisSeances(),
        enseignantId: 'inconnu',
      );
      final VuePlanning vide = _vue(const <Seance>[]);

      expect(impasse.lignes, isEmpty);
      expect(impasse.impasseDeFiltre, isTrue);
      expect(vide.impasseDeFiltre, isFalse);
    });
  });

  group('CTR-01 : une lecture bornee le dit', () {
    test('atteindre le plafond marque la vue comme tronquee', () {
      final List<Seance> deux = <Seance>[
        _seance(id: 'a', debutDansMinutes: 10),
        _seance(id: 'b', debutDansMinutes: 20),
      ];

      expect(_vue(deux, plafond: 2).tronquee, isTrue);
      expect(_vue(deux, plafond: 3).tronquee, isFalse);
    });
  });
}
