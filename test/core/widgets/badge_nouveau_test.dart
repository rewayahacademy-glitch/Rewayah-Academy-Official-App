import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/badge_nouveau.dart';

import '../../support/hote_theme.dart';

/// Le badge « Nouveau » (SPEC-LISTE-PERSONNES §2.1 bis) : un mot, une icone,
/// dans les trois langues, sans debordement a 320 et en texte double.
void main() {
  for (final (AppLocale langue, String mot) cas in <(AppLocale, String)>[
    (AppLocale.fr, 'Nouveau'),
    (AppLocale.en, 'New'),
    (AppLocale.ar, 'جديد'),
  ]) {
    testWidgets('le badge dit « ${cas.$2} » (${cas.$1.languageCode})', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(cas.$1));
      addTearDown(
        () => tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr)),
      );
      await tester.pumpWidget(hoteTheme(const Center(child: BadgeNouveau())));
      expect(find.text(cas.$2), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.bySemanticsLabel(cas.$2), findsOneWidget);
    });
  }

  testWidgets('a 320 de large et en texte double : aucun debordement', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteTheme(const Center(child: BadgeNouveau()), echelleTexte: 2),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(BadgeNouveau.clePastille)).width,
      lessThan(320),
    );
  });
}
