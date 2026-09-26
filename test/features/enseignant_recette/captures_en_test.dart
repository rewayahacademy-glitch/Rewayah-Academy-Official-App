// EN-1b : squelette des captures de la vague Enseignant. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Chaque lot EN-2 a EN-11
// ajoute ses ecrans ici ; EN-12 en fait la recette.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

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
  group('Capture : EN-1b, coquille enseignant', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // La VRAIE coquille (4 destinations, E10) sur chaque destination, aux
    // trois largeurs de reference, clair et sombre.
    for (final EcranDemoEnseignant ecran in EcranDemoEnseignant.values) {
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
              'en1b_coquille_${ecran.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleEnseignantDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });
}
