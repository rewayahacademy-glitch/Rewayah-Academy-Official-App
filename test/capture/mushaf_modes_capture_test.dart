// MUSHAF-MODES : captures des modes « Lecture agrandie » et « Focus » avec la
// mise en page de Medine : 1440 clair et sombre (100 % et zoom maximal), 390
// clair. Page 293. Saute sans CAPTURE_DIR. Sortie de preuve :
// docs/current/captures/MUSHAF-15L/modes/ (les `avant_*` sont ceux de
// claude/mushaf-15l-captures).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';

import '../support/mushaf_15l.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : MUSHAF-MODES', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    setUp(masquerRubanDebug);

    final List<(String, ModeRenduCoran, Size, double, ThemeMode)>
    cas = <(String, ModeRenduCoran, Size, double, ThemeMode)>[
      for (final ThemeMode theme in ThemeMode.values.skip(
        1,
      )) ...<(String, ModeRenduCoran, Size, double, ThemeMode)>[
        (
          'agrandie_1440_100_${theme == ThemeMode.light ? 'clair' : 'sombre'}',
          ModeRenduCoran.versetAgrandi,
          const Size(1440, 900),
          1,
          theme,
        ),
        (
          'agrandie_1440_max_${theme == ThemeMode.light ? 'clair' : 'sombre'}',
          ModeRenduCoran.versetAgrandi,
          const Size(1440, 900),
          4,
          theme,
        ),
        (
          'focus_1440_${theme == ThemeMode.light ? 'clair' : 'sombre'}',
          ModeRenduCoran.focus,
          const Size(1440, 900),
          1,
          theme,
        ),
      ],
      (
        'agrandie_390_100_clair',
        ModeRenduCoran.versetAgrandi,
        const Size(390, 844),
        1,
        ThemeMode.light,
      ),
      (
        'focus_390_clair',
        ModeRenduCoran.focus,
        const Size(390, 844),
        1,
        ThemeMode.light,
      ),
    ];
    for (final (
          String nom,
          ModeRenduCoran mode,
          Size taille,
          double zoom,
          ThemeMode theme,
        )
        in cas) {
      testWidgets(nom, (WidgetTester tester) async {
        await monterPageMadina15(
          tester,
          page: 293,
          taille: taille,
          mode: mode,
          zoom: zoom,
          theme: theme,
          ecranComplet: true,
        );
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'apres_$nom')}');
      });
    }
  });
}
