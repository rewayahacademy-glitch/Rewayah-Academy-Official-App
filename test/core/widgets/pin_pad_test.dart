// PinPad (UX-027, lot A11Y-1, WCAG 2.2 AA 4.1.2) : chaque touche est un
// bouton a son propre noeud, nomme une seule fois par son chiffre ; « Effacer »
// est nomme ; un appui saisit le chiffre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/pin_pad.dart';

import '../../support/harnais.dart';

void main() {
  testWidgets('chaque touche se lit une fois, par son chiffre', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    String? saisi;
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: SingleChildScrollView(
            child: PinPad(onCodeComplet: (String code) => saisi = code),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (int chiffre = 0; chiffre <= 9; chiffre++) {
      expect(
        tester.getSemantics(find.text('$chiffre')),
        isSemantics(
          label: '$chiffre',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
        reason: 'touche $chiffre : un noeud, un nom, lu une fois',
      );
    }
    expect(find.semantics.byLabel(t.pin.effacer), findsOne);

    for (final String c in <String>['2', '5', '8', '0']) {
      await tester.tap(find.text(c));
      await tester.pump();
    }
    expect(saisi, '2580');
    semantique.dispose();
  });

  // Dette (a) : le pave numerique ne se met jamais en miroir. En arabe, les
  // libelles suivent la langue, mais 1 2 3 se lit de gauche a droite.
  testWidgets('en arabe, le pave garde 1 2 3 de gauche a droite', (
    WidgetTester tester,
  ) async {
    unawaited(LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => unawaited(LocaleSettings.setLocale(AppLocale.fr)));
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: PinPad(onCodeComplet: (String code) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double x(int chiffre) => tester.getCenter(find.text('$chiffre')).dx;
    expect(x(1), lessThan(x(2)), reason: '1 a gauche de 2');
    expect(x(2), lessThan(x(3)), reason: '2 a gauche de 3');
    expect(x(4), lessThan(x(5)));
    expect(x(7), lessThan(x(8)));
    expect(x(8), lessThan(x(9)));
    // Le libelle de la touche d'effacement est toujours nomme.
    expect(find.semantics.byLabel(t.pin.effacer), findsOne);
    semantique.dispose();
  });
}
