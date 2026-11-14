// LANGUES-3 (14/11/2026) : les textes juridiques et la politique de controle
// du contrat en anglais, avec la mention « la version francaise fait foi ».
// 390 clair et 1440 sombre.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/dossier/politique_controle.dart';
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/mention_traduction.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import 'outil_capture.dart';

const List<(String, Size, ThemeMode)> _vues = <(String, Size, ThemeMode)>[
  ('390_clair', Size(390, 844), ThemeMode.light),
  ('1440_sombre', Size(1440, 900), ThemeMode.dark),
];

void main() {
  group('Capture : juridique en anglais', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.en);
    });
    tearDownAll(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final (String nom, Size vue, ThemeMode theme) in _vues) {
      testWidgets('$nom : liste des textes', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          hoteCapture(const JuridiquePage(), themeMode: theme),
        );
        await stabiliser(tester);
        expect(find.byType(MentionTraduction), findsOneWidget);
        await capturer(tester, 'juridique_liste_$nom');
      });

      testWidgets('$nom : conditions', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          hoteCapture(
            const TexteJuridiquePage(texte: TexteJuridique.conditions),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.juridique.traduction), findsOneWidget);
        await capturer(tester, 'juridique_conditions_$nom');
      });

      testWidgets('$nom : politique de controle du contrat', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: TextePolitiqueControle(),
              ),
            ),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.juridique.traduction), findsOneWidget);
        await capturer(tester, 'juridique_politique_$nom');
      });
    }
  });
}
