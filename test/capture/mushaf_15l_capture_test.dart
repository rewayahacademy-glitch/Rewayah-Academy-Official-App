// MUSHAF-15L : captures des pages 1, 2, 50, 293, 544 (Al-Mujadila, la page de
// l'image du directeur) et 604, en 390 et 1440, clair et sombre.
//
// Saute sans CAPTURE_DIR. Sortie de preuve : docs/current/captures/MUSHAF-15L/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mushaf_15l.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : MUSHAF-15L', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    setUp(masquerRubanDebug);

    for (final int page in <int>[1, 2, 50, 293, 544, 604]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String sombre = theme == ThemeMode.dark ? 'sombre' : 'clair';
          testWidgets('page $page $nom $sombre', (WidgetTester tester) async {
            await monterPageMadina15(
              tester,
              page: page,
              taille: taille,
              theme: theme,
              ecranComplet: true,
            );
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'm15_p${page}_${nom}_$sombre')}',
            );
          });
        }
      }
    }

    // La planche comparative de la page 544 : avant (composition approchee,
    // flux Unicode) contre apres (mise en page de l'edition).
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String sombre = theme == ThemeMode.dark ? 'sombre' : 'clair';
      testWidgets('page 544 avant la mise en page 390 $sombre', (
        WidgetTester tester,
      ) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: const Size(390, 844),
          theme: theme,
          miseEnPage: false,
          ecranComplet: true,
        );
        expect(tester.takeException(), isNull);
        debugPrint(
          'PNG ${await capturer(tester, 'm15_p544_avant_390_$sombre')}',
        );
      });
    }
  });
}
