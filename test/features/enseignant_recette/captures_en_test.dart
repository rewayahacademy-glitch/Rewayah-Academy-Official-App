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
  group('Capture : EN-2, Aujourd hui', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1500)),
      ('768', const Size(768, 1300)),
      ('1440', const Size(1440, 1000)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'en2_aujourdhui_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
            taille,
            mode: mode,
          );
        });
      }
    }
    // Les deux situations secondaires, sur telephone.
    for (final EtatDemoEnseignant etat in <EtatDemoEnseignant>[
      EtatDemoEnseignant.vide,
      EtatDemoEnseignant.horsLigne,
    ]) {
      final String fichier = 'en2_aujourdhui_${etat.name}_390_light';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.aujourdhui,
            etat: etat,
          ),
          const Size(390, 1100),
        );
      });
    }
  });

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
