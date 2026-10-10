// ECHELLE-CORR-ECRANS-1, R14 : les relectures regulieres ne partent pas
// toutes a la meme seconde, ralentissent apres un echec, et gardent leur
// cadence moyenne. Horloge simulee (`fakeAsync`) : aucune attente reelle.
import 'dart:async';
import 'dart:math' as math;

// fake_async est la dependance de flutter_test qui porte son horloge simulee
// (version fixee par le SDK) ; pubspec.yaml n'est pas modifie par ce lot.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Seance;
import 'package:rewayah_academy/core/reseau/sondage_regulier.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';

const Duration _cadence = Duration(seconds: 10);

/// Les instants (en ms depuis le demarrage) ou une lecture est partie.
List<int> _departs(
  FakeAsync temps,
  SondageRegulier Function(Future<bool> Function() lire) creer, {
  required Duration duree,
  bool Function(int rang)? aboutie,
}) {
  final List<int> departs = <int>[];
  final Stopwatch montre = temps.getClock(DateTime(2026)).stopwatch()..start();
  int rang = 0;
  final SondageRegulier s = creer(() async {
    departs.add(montre.elapsedMilliseconds);
    return aboutie?.call(rang++) ?? true;
  })..demarrer();
  temps.elapse(duree);
  s.arreter();
  return departs;
}

void main() {
  test('la premiere lecture est immediate, la deuxieme decalee au hasard', () {
    fakeAsync((FakeAsync temps) {
      final Set<int> deuxiemes = <int>{};
      for (int graine = 0; graine < 40; graine++) {
        final List<int> d = _departs(
          temps,
          (Future<bool> Function() lire) => SondageRegulier(
            cadence: _cadence,
            lire: lire,
            hasard: math.Random(graine),
          ),
          duree: const Duration(seconds: 16),
        );
        expect(d.first, 0, reason: 'premiere lecture immediate');
        // Entre la moitie et une fois et demie la cadence.
        expect(d[1], inInclusiveRange(5000, 15000));
        deuxiemes.add(d[1] ~/ 1000);
      }
      // 40 appareils ne repartent pas a la meme seconde.
      expect(deuxiemes.length, greaterThan(5));
    });
  });

  test('cadence moyenne inchangee (a 2 % pres sur une heure)', () {
    fakeAsync((FakeAsync temps) {
      final List<int> d = _departs(
        temps,
        (Future<bool> Function() lire) => SondageRegulier(
          cadence: _cadence,
          lire: lire,
          hasard: math.Random(7),
        ),
        duree: const Duration(hours: 1),
      );
      final double moyenne = (d.last - d.first) / (d.length - 1);
      expect(moyenne, closeTo(10000, 200));
      // Chaque intervalle varie de plus ou moins 20 % au plus (le premier
      // excepte, tire entre 0,5 et 1,5 fois la cadence).
      for (int i = 2; i < d.length; i++) {
        expect(d[i] - d[i - 1], inInclusiveRange(8000, 12000));
      }
    });
  });

  test('recul apres des echecs, retour a la cadence apres une reussite', () {
    fakeAsync((FakeAsync temps) {
      // Les 5 premieres lectures echouent, les suivantes aboutissent.
      final List<int> d = _departs(
        temps,
        (Future<bool> Function() lire) => SondageRegulier(
          cadence: _cadence,
          lire: lire,
          hasard: math.Random(3),
        ),
        duree: const Duration(minutes: 10),
        aboutie: (int rang) => rang >= 5,
      );
      final List<int> ecarts = <int>[
        for (int i = 1; i < d.length; i++) d[i] - d[i - 1],
      ];
      // Le recul grandit (x2, x4, x8) puis reste borne a 8 fois la cadence.
      expect(ecarts.reduce(math.max), lessThanOrEqualTo(8 * 12000));
      expect(ecarts.reduce(math.max), greaterThanOrEqualTo(4 * 8000));
      // Une fois les lectures abouties, la cadence revient.
      expect(ecarts.last, inInclusiveRange(8000, 12000));
    });
  });

  test('une exception compte comme un echec', () {
    fakeAsync((FakeAsync temps) {
      final SondageRegulier s = SondageRegulier(
        cadence: _cadence,
        lire: () async => throw StateError('reseau'),
        hasard: math.Random(1),
      )..demarrer();
      temps.flushMicrotasks();
      expect(s.echecs, 1);
      s.arreter();
    });
  });

  test('arreter annule la minuterie : plus aucune lecture', () {
    fakeAsync((FakeAsync temps) {
      int lectures = 0;
      final SondageRegulier s = SondageRegulier(
        cadence: _cadence,
        lire: () async {
          lectures++;
          return true;
        },
      )..demarrer();
      temps.elapse(const Duration(seconds: 30));
      final int avant = lectures;
      s.arreter();
      temps.elapse(const Duration(minutes: 5));
      expect(lectures, avant);
      expect(temps.pendingTimers, isEmpty);
    });
  });

  test('les cadences des flux decales sont inchangees', () {
    expect(cadenceAnnonceObservation, const Duration(seconds: 10));
    expect(cadenceSeanceFamille, const Duration(seconds: 30));
  });

  test('flux des seances famille : decale, et ralenti tant que la lecture '
      'echoue', () {
    fakeAsync((FakeAsync temps) {
      int lectures = 0;
      bool enPanne = true;
      final SeancesFamilleDepuisPlanning port = SeancesFamilleDepuisPlanning(
        lireSeances: () async {
          lectures++;
          if (enPanne) throw StateError('reseau');
          return const <Seance>[];
        },
        horlogeAppareilUtc: () => DateTime.utc(2026, 10, 10),
      );
      final StreamSubscription<SeanceFamille> abonnement = port
          .suivre('s1')
          .listen((SeanceFamille _) {}, onError: (Object _) {});
      // Dix minutes de panne : 20 lectures a 30 s sans recul, bien moins avec.
      temps.elapse(const Duration(minutes: 10));
      expect(lectures, inInclusiveRange(3, 9));
      // Le reseau revient : la cadence de 30 s reprend (une lecture qui
      // aboutit, meme sans seance, n'est pas un echec).
      enPanne = false;
      temps.elapse(const Duration(minutes: 5));
      final int apresRetour = lectures;
      temps.elapse(const Duration(minutes: 10));
      expect(lectures - apresRetour, inInclusiveRange(17, 24));
      unawaited(abonnement.cancel());
      temps.flushMicrotasks();
      expect(temps.pendingTimers, isEmpty);
    });
  });
}
