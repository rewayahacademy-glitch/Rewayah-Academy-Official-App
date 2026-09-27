// EA-2 : les captures finales de l'accueil de l'eleve adulte. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(ecran, themeMode: mode, echelleTexte: echelle),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea2_accueil_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            const CoquilleAdulteDemo(ecran: EcranDemoAdulte.accueil),
            taille,
            mode: mode,
          );
        });
      }
    }

    testWidgets('ea2_accueil_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea2_accueil_390_light_200pc',
        const CoquilleAdulteDemo(ecran: EcranDemoAdulte.accueil),
        const Size(390, 844),
        echelle: 2,
      );
    });
  });
}
