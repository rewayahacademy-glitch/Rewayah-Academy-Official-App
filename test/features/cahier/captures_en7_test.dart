// EN-7 : captures du cahier de seance (ENS-04) : a remplir, valide, corrige.
// Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode,
  EtatDemoEnseignant etat,
) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.cahier, etat: etat),
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
  // La soumission de demonstration repond apres 600 ms.
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

final Finder _valider = find.byKey(const ValueKey<String>('cahier-valider'));
final Finder _corriger = find.byKey(const ValueKey<String>('cahier-corriger'));

void main() {
  group('Capture : EN-7', skip: sautSansCapture, () {
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
        final String suffixe = '${l}_${mode.name}';
        testWidgets('en7_cahier_a_remplir_$suffixe', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await capturer(tester, 'en7_cahier_a_remplir_$suffixe');
        });
        testWidgets('en7_cahier_valide_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await _toucher(tester, _valider);
          await capturer(tester, 'en7_cahier_valide_$suffixe');
        });
        testWidgets('en7_cahier_corrige_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await _toucher(tester, _valider);
          await _toucher(tester, _corriger);
          await _toucher(tester, _valider);
          await capturer(tester, 'en7_cahier_corrige_$suffixe');
        });
        testWidgets('en7_cahier_en_attente_$suffixe', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille, mode, EtatDemoEnseignant.horsLigne);
          await _toucher(tester, _valider);
          await capturer(tester, 'en7_cahier_en_attente_$suffixe');
        });
      }
    }
  });
}
