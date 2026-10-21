// EN-5 : captures de Disponibilites (ENS-06) et du detail d'une Classe
// disponible (ENS-06B, detail et confirmation). Jamais sans `CAPTURE_DIR`
// (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode mode) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.disponibilites),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Capture : EN-5', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 900)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${l}_${mode.name}';
        testWidgets('en5_disponibilites_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          debugPrint(
            'PNG ${await capturer(tester, 'en5_disponibilites_$suffixe')}',
          );
        });
        testWidgets('en5_detail_classe_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, find.text('Ar-Rahma'));
          debugPrint(
            'PNG ${await capturer(tester, 'en5_detail_classe_$suffixe')}',
          );
        });
        testWidgets('en5_confirmation_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, find.text('Ar-Rahma'));
          await _toucher(tester, find.text(t.enseignant.creneaux.reserver));
          debugPrint(
            'PNG ${await capturer(tester, 'en5_confirmation_$suffixe')}',
          );
        });
      }
    }
    testWidgets('en5_succes_390_light', (WidgetTester tester) async {
      await _monter(tester, const Size(390, 900), ThemeMode.light);
      await _toucher(tester, find.text('Ar-Rahma'));
      await _toucher(tester, find.text(t.enseignant.creneaux.reserver));
      await _toucher(tester, find.text(t.enseignant.creneaux.confirmer));
      debugPrint('PNG ${await capturer(tester, 'en5_succes_390_light')}');
    });
  });
}
