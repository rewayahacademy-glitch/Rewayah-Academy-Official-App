// ONGLETS-1 : captures de `SelecteurSection` (sous-navigation de Pedagogie et
// de Configuration) a 320 et 1440 px. Sautee sans CAPTURE_DIR.
//
//   CAPTURE_DIR=docs/current/captures/l1-onglets flutter test \
//     test/capture/onglets1_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../support/selecteur_section.dart';
import 'outil_capture.dart';

Widget _page(Widget sousNavigation) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Pédagogie', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          sousNavigation,
        ],
      ),
    ),
  ),
);

void main() {
  group('Capture : ONGLETS-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size taille in const <Size>[Size(320, 640), Size(1440, 900)]) {
      final String nom = '${taille.width.toInt()}';
      testWidgets('pedagogie, cinq sections, $nom px', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 2);
        await tester.pumpWidget(
          hoteCapture(
            _page(
              SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 2),
            ),
          ),
        );
        await stabiliser(tester);
        await capturer(tester, 'pedagogie_${nom}_ferme');
      });
    }

    testWidgets('pedagogie, menu ouvert, 320 px', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, 640), 2);
      await tester.pumpWidget(
        hoteCapture(
          _page(
            SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 2),
          ),
        ),
      );
      await stabiliser(tester);
      await tester.tap(
        find.descendant(
          of: selecteurSection,
          matching: find.byType(InkWell).first,
        ),
      );
      await stabiliser(tester);
      await capturer(tester, 'pedagogie_320_ouvert');
    });

    testWidgets('configuration, quatre sections, 390 px', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 2);
      await tester.pumpWidget(
        hoteCapture(
          _page(
            SousNavigationDomaine(
              onglets: ongletsConfiguration(politiqueRevueKyc: true),
              indexActif: 1,
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await capturer(tester, 'configuration_390');
    });
  });
}
