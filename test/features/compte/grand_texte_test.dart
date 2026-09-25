// Constat 10 (LT-F) : a 390 px avec le texte a 200 %, la tete de `PageShell`
// defile avec le contenu ; Soldes, Acces et Mouvements s'affichent sans
// debordement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import 'support_compte.dart';

final List<Override> _demo = <Override>[
  portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
];

void main() {
  for (final String depart in <String>[
    Routes.tuteurCompteSoldes,
    Routes.compteTuteurSousPage('acces'),
    Routes.tuteurCompteMouvements,
  ]) {
    testWidgets('390 px, texte a 200 % : $depart sans debordement', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await monterCompte(
        tester,
        depart: depart,
        eleves: DonneesDemo.eleves,
        surcharges: _demo,
      );
      expect(tester.takeException(), isNull);
      // La tete defile : elle est dans la zone defilante.
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView).first,
          matching: find.byType(Text),
        ),
        findsWidgets,
      );
    });
  }
}
