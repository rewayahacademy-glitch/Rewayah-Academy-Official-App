// Appareil de Hakim (27/10/2026), decision du directeur du 29/10 : la veille
// temps reel d'abord ; en secours, une relecture au retour dans l'application
// et une seule relecture programmee a la fois, aux instants de la seance
// connue, avec un leger alea. Aucune minuterie fixe.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/fraicheur/generation_veille.dart';
import 'package:rewayah_academy/core/fraicheur/relectures_accueil.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';

class _AccueilCompte implements PortAccueilAccessibilite {
  int lectures = 0;

  @override
  Future<DonneesAccueilAccessibilite> lire() async {
    lectures++;
    return const DonneesAccueilAccessibilite(
      prenom: 'Fixture',
      tutoiement: true,
      espace: null,
    );
  }
}

final DateTime _t0 = DateTime.utc(2026, 10, 27, 16);

void main() {
  group('prochainDelaiRelecture', () {
    test('le premier instant a venir, plus l alea', () {
      expect(
        prochainDelaiRelecture(
          <DateTime>[
            _t0.add(const Duration(minutes: 10)),
            _t0.add(const Duration(minutes: 5)),
          ],
          _t0,
          const Duration(seconds: 7),
        ),
        const Duration(minutes: 5, seconds: 7),
      );
    });

    test('rien a venir : aucune relecture', () {
      expect(
        prochainDelaiRelecture(
          <DateTime>[_t0.subtract(const Duration(minutes: 1))],
          _t0,
          Duration.zero,
        ),
        isNull,
      );
      expect(
        prochainDelaiRelecture(const <DateTime>[], _t0, Duration.zero),
        isNull,
      );
    });

    test('l alea reste entre zero et AppDelais.aleaRelecture', () {
      final math.Random hasard = math.Random(1);
      for (int i = 0; i < 200; i++) {
        final Duration a = aleaRelecture(hasard);
        expect(a, greaterThanOrEqualTo(Duration.zero));
        expect(a, lessThanOrEqualTo(AppDelais.aleaRelecture));
      }
    });
  });

  testWidgets('RelecturesAccueil : une relecture par instant, aucune autre', (
    WidgetTester tester,
  ) async {
    var relectures = 0;
    DateTime maintenant = _t0;
    await tester.pumpWidget(
      RelecturesAccueil(
        relire: () => relectures++,
        instants: <DateTime>[
          _t0.add(const Duration(minutes: 5)),
          _t0.add(const Duration(minutes: 10)),
        ],
        horloge: () => maintenant,
        alea: () => const Duration(seconds: 3),
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump(const Duration(minutes: 5));
    expect(relectures, 0);
    maintenant = _t0.add(const Duration(minutes: 5, seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(relectures, 1);

    maintenant = _t0.add(const Duration(minutes: 10, seconds: 3));
    await tester.pump(const Duration(minutes: 5));
    expect(relectures, 2);

    await tester.pump(const Duration(hours: 3));
    expect(relectures, 2);
  });

  testWidgets('RelecturesAccueil : le retour dans l application relit', (
    WidgetTester tester,
  ) async {
    var relectures = 0;
    await tester.pumpWidget(
      RelecturesAccueil(
        relire: () => relectures++,
        instants: const <DateTime>[],
        child: const SizedBox.shrink(),
      ),
    );
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(relectures, 1);
    await tester.pump(const Duration(hours: 1));
    expect(relectures, 1);
  });

  test('un signal de la veille relit l accueil guide', () async {
    final _AccueilCompte accueil = _AccueilCompte();
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        portAccueilAccessibiliteProvider.overrideWithValue(accueil),
      ],
    );
    addTearDown(conteneur.dispose);
    conteneur.listen(donneesAccueilAccessibiliteProvider, (_, _) {});
    await pumpEventQueue();
    expect(accueil.lectures, 1);

    conteneur.read(generationVeilleProvider.notifier).avancer();
    await pumpEventQueue();
    expect(accueil.lectures, 2);
  });
}
