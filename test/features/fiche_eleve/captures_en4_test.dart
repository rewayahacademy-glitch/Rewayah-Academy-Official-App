// EN-4 : captures de la fiche eleve (ENS-11), de « Signaler un besoin »
// (ENS-12) et de Mes Classes. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';

import '../../capture/outil_capture.dart';

Future<void> _ouvrirFiche(
  WidgetTester tester,
  Size taille,
  ThemeMode mode,
) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  final Finder ligne = find.text('Mariam').last;
  await tester.ensureVisible(ligne);
  await stabiliser(tester);
  await tester.tap(ligne);
  await stabiliser(tester);
}

void main() {
  group('Capture : EN-4', skip: sautSansCapture, () {
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
        testWidgets('en4_fiche_eleve_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _ouvrirFiche(tester, taille, mode);
          debugPrint(
            'PNG ${await capturer(tester, 'en4_fiche_eleve_${l}_${mode.name}')}',
          );
        });
        testWidgets('en4_signaler_besoin_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _ouvrirFiche(tester, taille, mode);
          final Finder signaler = find.byKey(FicheEleveEnseignant.signalerKey);
          await tester.ensureVisible(signaler);
          await stabiliser(tester);
          await tester.tap(signaler);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'en4_signaler_besoin_${l}_${mode.name}')}',
          );
        });
      }
    }
    testWidgets('en4_mes_classes_390_light', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes),
        ),
      );
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'en4_mes_classes_390_light')}');
    });
  });
}
