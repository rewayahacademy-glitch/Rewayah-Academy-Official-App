// CT-1b : squelette des captures de la vague Controleur. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Chaque lot CT-2 a CT-11
// ajoute ses ecrans ici ; CT-12 en fait la recette.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(ecran, themeMode: mode));
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : CT-1b, coquille controleur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // La VRAIE coquille (4 destinations, C13) sur chaque destination, aux
    // trois largeurs de reference, clair et sombre.
    for (final EcranDemoControleur ecran in EcranDemoControleur.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 900)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'ct1b_coquille_${ecran.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleControleurDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });
}
