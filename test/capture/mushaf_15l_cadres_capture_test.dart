// MUSHAF-15L : captures du cadre retenu (C : un ornement en haut et en bas), l ecran du
// lecteur en entier (en-tete et commandes comprises) : la page 544 a 390 points
// en clair et en sombre, plus la page 1 en clair.
//
// Saute sans CAPTURE_DIR. Sortie de preuve :
// docs/current/captures/MUSHAF-15L/cadres/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mushaf_15l.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : cadres MUSHAF-15L', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    setUp(masquerRubanDebug);

    {
      for (final (int page, ThemeMode theme) in <(int, ThemeMode)>[
        (544, ThemeMode.light),
        (544, ThemeMode.dark),
        (1, ThemeMode.light),
      ]) {
        final String sombre = theme == ThemeMode.dark ? 'sombre' : 'clair';
        testWidgets('cadre page $page 390 $sombre', (
          WidgetTester tester,
        ) async {
          await monterPageMadina15(
            tester,
            page: page,
            taille: const Size(390, 844),
            theme: theme,
            ecranComplet: true,
          );
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'cadre_C_p${page}_390_$sombre')}',
          );
        });
      }
    }
  });
}
