// PAGES-FLUIDES (directeur, 12/11/2026) : captures de TEST de la page du
// Coran en salle, avec son cadre et ses marges, rendues par la vraie page
// `/salle` (`SallePage`) avec le faux moteur du harnais. Ce ne sont pas des
// captures de la vraie application ; la preuve reste celle du directeur en
// production, apres fusion.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/pages-fluides \
//   flutter test test/capture/pages_fluides_capture_test.dart
//
// Saute sans CAPTURE_DIR. Nommage : pages_fluides_<role>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_enseignant/page_coran_salle.dart';

import '../features/pages_fluides_salle_test.dart' show monterSalleAvecPage;
import '../support/mushaf_15l.dart' show chargerPoliceMadina15;
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 2, '390'),
  (Size(1440, 900), 1, '1440'),
];

void main() {
  group('Capture : PAGES-FLUIDES', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final String role in <String>['enseignant', 'eleve']) {
      for (final (Size cadre, double densite, String largeur) in _cadres) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom = 'pages_fluides_${role}_${largeur}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            await monterSalleAvecPage(
              tester,
              role: role == 'enseignant' ? 'teacher' : 'student',
              taille: cadre,
              theme: mode,
              densite: densite,
            );
            expect(tester.takeException(), isNull);
            expect(find.byKey(PageCoranSalle.cle), findsOneWidget);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });
}
