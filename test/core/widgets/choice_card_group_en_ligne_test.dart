// SOURATES (pilote, 11/11/2026) : `ChoiceCardGroup.enLigne`, deux cartes
// compactes cote a cote. A 390, un nom long (« At-Takathur ») passait sous sa
// case et sa carte devenait plus haute que sa voisine. Le libelle reste
// maintenant a cote du repere, aucun mot n'est coupe, et les cartes d'une
// rangee ont toujours la meme hauteur (LTR et RTL). En texte x2, le nom ne
// tient pas a cote sans etre trop reduit : la rangee s'empile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

Future<void> _monter(
  WidgetTester tester, {
  required double largeur,
  required double echelle,
  required TextDirection sens,
}) async {
  tester.view.physicalSize = Size(largeur, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(largeur, 2000),
          textScaler: TextScaler.linear(echelle),
        ),
        child: Directionality(
          textDirection: sens,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ChoiceCardGroup(
                enLigne: true,
                selectionMultiple: true,
                indicationMultiple: false,
                autoriserSaisieLibre: false,
                options: const <OptionChoix>[
                  OptionChoix(
                    valeur: '102',
                    libelle: 'At-Takathur',
                    cle: ValueKey<String>('long'),
                  ),
                  OptionChoix(
                    valeur: '106',
                    libelle: 'Quraysh',
                    cle: ValueKey<String>('court'),
                  ),
                ],
                onChange: (ReponseChoix _) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final double echelle in <double>[1]) {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('390 x${echelle.toInt()} ${sens.name} : nom long a cote de '
          'sa case, cartes de meme hauteur', (WidgetTester tester) async {
        await _monter(tester, largeur: 390, echelle: echelle, sens: sens);
        expect(tester.takeException(), isNull);
        final Rect longue = tester.getRect(
          find.byKey(const ValueKey<String>('long')),
        );
        final Rect courte = tester.getRect(
          find.byKey(const ValueKey<String>('court')),
        );
        expect(longue.height, moreOrLessEquals(courte.height, epsilon: 0.5));
        expect(longue.top, moreOrLessEquals(courte.top, epsilon: 0.5));
        // Le libelle est sur la meme rangee que la case, pas dessous.
        final Rect libelle = tester.getRect(find.text('At-Takathur'));
        final Rect caseLongue = tester.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey<String>('long')),
                matching: find.byType(CaseChoix),
              )
              .first,
        );
        expect(libelle.top, lessThan(caseLongue.bottom));
        expect(caseLongue.top, lessThan(libelle.bottom));
        expect(motsCoupes(tester, find.byType(ChoiceCardGroup)), isEmpty);
      });
    }
  }

  for (final double largeur in <double>[320, 390]) {
    testWidgets('${largeur.toInt()} x2 : le nom ne tient pas a cote sans '
        'reduire le texte agrandi, la rangee s empile en cartes pleine '
        'largeur, aucun mot coupe', (WidgetTester tester) async {
      await _monter(
        tester,
        largeur: largeur,
        echelle: 2,
        sens: TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
      final Rect longue = tester.getRect(
        find.byKey(const ValueKey<String>('long')),
      );
      final Rect courte = tester.getRect(
        find.byKey(const ValueKey<String>('court')),
      );
      expect(longue.width, moreOrLessEquals(courte.width, epsilon: 0.5));
      expect(courte.top, greaterThan(longue.bottom));
      expect(motsCoupes(tester, find.byType(ChoiceCardGroup)), isEmpty);
    });
  }
}
