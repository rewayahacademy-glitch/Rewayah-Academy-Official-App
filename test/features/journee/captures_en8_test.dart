// EN-8 : captures d'ENS-13 (absence sur une seance) et d'ENS-13B (offre de
// remplacement) dans Aujourd'hui. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode mode) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
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
  // Les reponses de demonstration arrivent apres 600 ms.
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

final Finder _declarer = find.byKey(
  const ValueKey<String>('journee-declarer-absence'),
);
final Finder _declarerMonAbsence = find.byKey(
  const ValueKey<String>('absence-principale'),
);

void main() {
  group('Capture : EN-8', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1900)),
      ('768', const Size(768, 1500)),
      ('1440', const Size(1440, 1000)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s = '${l}_${mode.name}';
        testWidgets('en8_alerte_offre_$s', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await capturer(tester, 'en8_alerte_offre_$s');
        });
        testWidgets('en8_feuille_absence_$s', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, _declarer);
          await capturer(tester, 'en8_feuille_absence_$s');
        });
        testWidgets('en8_absence_etat_$s', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, _declarer);
          await _toucher(tester, _declarerMonAbsence);
          await capturer(tester, 'en8_absence_etat_$s');
        });
        // REMPL-1b : la confirmation et la carte ne s'ouvrent plus depuis
        // l'Alerte utile, qui mene a l'ecran commun (captures REMPL-1b).
      }
    }
  });
}
