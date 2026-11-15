// MESSAGERIE-PLEIN-ECRAN : captures R3 (sautees sans CAPTURE_DIR).
// Telephone 390 x 844 avec un clavier simule de 300, fr et ar ; ordinateur
// 1440 x 900.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (Size taille, double clavier) in <(Size, double)>[
        (const Size(390, 844), 300),
        (const Size(390, 844), 0),
        (const Size(1440, 900), 0),
      ]) {
        final String nom =
            'messagerie-${taille.width.toInt()}-${langue.languageCode}'
            '${clavier > 0 ? '-clavier' : ''}';
        testWidgets(nom, (WidgetTester tester) async {
          tester.view.viewInsets = FakeViewPadding(bottom: clavier);
          addTearDown(tester.view.resetViewInsets);
          await monterMessages(
            tester,
            port: portDemo(RoleDemoCommunications.enseignant),
            depart: cheminFilTest('fil-adam'),
            taille: taille,
            langue: langue,
          );
          await tester.pumpAndSettle();
          await capturerVue(tester, 'MESSAGERIE-PLEIN-ECRAN/$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
