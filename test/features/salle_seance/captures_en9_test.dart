// EN-9 : captures de la salle A (panneau Eleves et file de recitation,
// resume mobile, feuille Eleves, fiche en seance, appel cote eleve, notice
// du parent). Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode,
  RoleSeance role,
  EtatDemoSalle etat,
) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleDemo(role: role, etat: etat, onSortir: () {}),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : EN-9', skip: sautSansCapture, () {
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
        final String s = '${l}_${mode.name}';
        testWidgets('en9_salle_$s', (WidgetTester tester) async {
          await _monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.repos,
          );
          await capturer(tester, 'en9_salle_$s');
        });
        testWidgets('en9_eleves_fiche_$s', (WidgetTester tester) async {
          await _monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.eleves,
          );
          await capturer(tester, 'en9_eleves_fiche_$s');
        });
        testWidgets('en9_appel_eleve_$s', (WidgetTester tester) async {
          await _monter(
            tester,
            taille,
            mode,
            RoleSeance.eleve,
            EtatDemoSalle.appel,
          );
          await capturer(tester, 'en9_appel_eleve_$s');
        });
        testWidgets('en9_notice_parent_$s', (WidgetTester tester) async {
          await _monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.visite,
          );
          await capturer(tester, 'en9_notice_parent_$s');
        });
      }
    }
  });
}
