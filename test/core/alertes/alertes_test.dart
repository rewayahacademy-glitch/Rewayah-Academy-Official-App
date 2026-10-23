// ALERTE-1 : ordre de lecture des alertes, port neutre et capacite.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/features/alertes/section_alertes.dart';
import 'package:rewayah_academy/features/demo/alertes_demo.dart';

final DateTime _midi = DateTime(2026, 10, 5, 12);

Alerte _a(String id, GraviteAlerte g, int minutesAvant, {String? vers}) =>
    Alerte(
      id: id,
      gravite: g,
      titre: id,
      creeeLe: _midi.subtract(Duration(minutes: minutesAvant)),
      destination: vers,
    );

class _PortFlux implements PortAlertes {
  // Flux de test, libere avec le conteneur du test.
  // ignore: close_sinks
  final StreamController<List<Alerte>> flux =
      StreamController<List<Alerte>>.broadcast();

  @override
  Stream<List<Alerte>> suivre() => flux.stream;
}

void main() {
  group('trierAlertes (A1)', () {
    test('la gravite passe avant la date, puis la plus recente d abord', () {
      final List<Alerte> triees = trierAlertes(<Alerte>[
        _a('info-recente', GraviteAlerte.info, 1),
        _a('importante-ancienne', GraviteAlerte.important, 120),
        _a('urgente-ancienne', GraviteAlerte.urgent, 90),
        _a('importante-recente', GraviteAlerte.important, 10),
        _a('urgente-recente', GraviteAlerte.urgent, 30),
      ]);
      expect(triees.map((Alerte a) => a.id), <String>[
        'urgente-recente',
        'urgente-ancienne',
        'importante-recente',
        'importante-ancienne',
        'info-recente',
      ]);
    });

    test('a egalite de gravite et de date, l ordre est stable', () {
      final List<Alerte> a = trierAlertes(<Alerte>[
        _a('b', GraviteAlerte.urgent, 5),
        _a('a', GraviteAlerte.urgent, 5),
      ]);
      final List<Alerte> b = trierAlertes(<Alerte>[
        _a('a', GraviteAlerte.urgent, 5),
        _a('b', GraviteAlerte.urgent, 5),
      ]);
      expect(a.map((Alerte x) => x.id), <String>['a', 'b']);
      expect(b.map((Alerte x) => x.id), <String>['a', 'b']);
    });

    test('ne modifie pas la liste recue', () {
      final List<Alerte> recue = <Alerte>[
        _a('info', GraviteAlerte.info, 1),
        _a('urgente', GraviteAlerte.urgent, 9),
      ];
      trierAlertes(recue);
      expect(recue.first.id, 'info');
    });
  });

  test('une destination externe ou mal formee n est jamais suivie', () {
    expect(
      _a('x', GraviteAlerte.urgent, 1, vers: 'https://exemple.org').destination,
      isNull,
    );
    expect(
      _a('x', GraviteAlerte.urgent, 1, vers: '//hote').destination,
      isNull,
    );
    expect(
      _a(
        'x',
        GraviteAlerte.urgent,
        1,
        vers: '/admin/operations/groupes',
      ).destination,
      '/admin/operations/groupes',
    );
  });

  group('alertesDuTableau (A2, D6)', () {
    test('toutes les urgentes, jamais cachees derriere Voir tout', () {
      final List<Alerte> triees = trierAlertes(<Alerte>[
        for (int i = 0; i < 5; i++) _a('u$i', GraviteAlerte.urgent, i),
        _a('i', GraviteAlerte.info, 0),
      ]);
      final List<Alerte> montrees = alertesDuTableau(triees);
      expect(montrees.where((Alerte a) => a.urgente), hasLength(5));
      expect(montrees, hasLength(5));
    });

    test('sans plus de trois urgentes : trois lignes au plus', () {
      final List<Alerte> triees = trierAlertes(<Alerte>[
        _a('u', GraviteAlerte.urgent, 3),
        _a('m1', GraviteAlerte.important, 1),
        _a('m2', GraviteAlerte.important, 2),
        _a('i', GraviteAlerte.info, 0),
      ]);
      expect(alertesDuTableau(triees).map((Alerte a) => a.id), <String>[
        'u',
        'm1',
        'm2',
      ]);
    });
  });

  group('port et capacite (A6)', () {
    test('production : indisponible, jamais une liste vide', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await expectLater(
        c.read(portAlertesProvider).suivre(),
        emitsError(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            'DASH-BR-03',
          ),
        ),
      );
    });

    test('la capacite vaut null tant que la source ne rend rien', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final ProviderSubscription<int?> s = c.listen(
        alertesUrgentesProvider,
        (int? _, int? _) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(s.read(), isNull);
    });

    test('le flux trie chaque emission et compte les urgentes', () async {
      final _PortFlux port = _PortFlux();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[portAlertesProvider.overrideWithValue(port)],
      );
      addTearDown(c.dispose);
      final ProviderSubscription<int?> s = c.listen(
        alertesUrgentesProvider,
        (int? _, int? _) {},
      );
      c.listen(alertesProvider, (Object? _, Object? _) {});
      await Future<void>.delayed(Duration.zero);
      port.flux.add(<Alerte>[_a('i', GraviteAlerte.info, 0)]);
      await Future<void>.delayed(Duration.zero);
      expect(s.read(), 0);

      // Une urgente arrive en queue du flux : elle passe en tete.
      port.flux.add(<Alerte>[
        _a('i', GraviteAlerte.info, 0),
        _a('u', GraviteAlerte.urgent, 7),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(s.read(), 1);
      expect(c.read(alertesProvider).requireValue.first.id, 'u');
    });
  });

  group('demonstration', () {
    test(
      'l urgente n est pas la plus recente, elle passe pourtant en tete',
      () {
        final List<Alerte> brutes = alertesDemo(_midi);
        final Alerte plusRecente = brutes.reduce(
          (Alerte a, Alerte b) => a.creeeLe.isAfter(b.creeeLe) ? a : b,
        );
        expect(plusRecente.urgente, isFalse);
        expect(trierAlertes(brutes).first.urgente, isTrue);
      },
    );

    testWidgets(
      'une urgente arrive apres le delai, la minuterie meurt avec le flux',
      (WidgetTester tester) async {
        final List<List<Alerte>> recues = <List<Alerte>>[];
        final StreamSubscription<List<Alerte>> abonnement = const AlertesDemo(
          arrivee: Duration(seconds: 20),
        ).suivre().listen(recues.add);
        await tester.pump();
        expect(recues, hasLength(1));
        await tester.pump(const Duration(seconds: 19));
        expect(recues, hasLength(1));
        await tester.pump(const Duration(seconds: 1));
        expect(recues, hasLength(2));
        expect(recues.last.where((Alerte a) => a.urgente), hasLength(2));
        unawaited(abonnement.cancel());
        await tester.pump();

        // Quitter avant l'arrivee : aucune minuterie ne reste (le test
        // echouerait sur une minuterie en attente).
        final StreamSubscription<List<Alerte>> quitte = const AlertesDemo(
          arrivee: Duration(seconds: 20),
        ).suivre().listen((_) {});
        await tester.pump();
        unawaited(quitte.cancel());
        await tester.pump();
      },
    );
  });
}
