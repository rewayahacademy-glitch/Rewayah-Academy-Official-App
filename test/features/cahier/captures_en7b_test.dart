// EN-7b : captures du cahier de seance (ENS-04) : a remplir, feuille d'un
// eleve (devoir precedent, suite), cahier enregistre.
// Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode mode) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      // Sans ce faux, le cahier ouvre une vraie base drift, qui appelle
      // path_provider (absent en test) : meme fable que captures_en_test.
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
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
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

void main() {
  group('Capture : EN-7b', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1900)),
      ('1440', const Size(1440, 1000)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${l}_${mode.name}';
        testWidgets('en7b_cahier_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await capturer(tester, 'en7b_cahier_$suffixe');
        });
        testWidgets('en7b_eleve_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, find.text('Nour'));
          await capturer(tester, 'en7b_eleve_haut_$suffixe');
          await _toucher(
            tester,
            find.byKey(const ValueKey<String>('cahier-suite-renforcer')),
          );
          await capturer(tester, 'en7b_eleve_$suffixe');
        });
        testWidgets('en7b_enregistre_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(
            tester,
            find.byKey(const ValueKey<String>('cahier-valider')),
          );
          await capturer(tester, 'en7b_enregistre_$suffixe');
        });
      }
    }
  });
}
