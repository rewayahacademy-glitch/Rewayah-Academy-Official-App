// MESSAGERIE-COULEURS : captures R3 de la liste des conversations sur
// ordinateur (1440 x 900), francais et arabe, clair et sombre (sautees sans
// CAPTURE_DIR). Le volet de conversation est capture dans
// `test/features/admin_candidature/conversation_mise_en_page_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

void main() {
  group('captures liste', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final String nom =
            'bulles-liste-1440-${langue.languageCode}'
            '-${lum == Brightness.dark ? 'sombre' : 'clair'}';
        testWidgets(nom, (WidgetTester tester) async {
          await monterMessages(
            tester,
            port: MessagesMetierDemo(
              role: RoleDemoCommunications.enseignant,
              maintenant: maintenantTest,
              avecBulles: true,
            ),
            depart: cheminListeTest,
            taille: const Size(1440, 900),
            langue: langue,
            luminosite: lum,
          );
          await tester.pumpAndSettle();
          await capturerVue(tester, 'MESSAGERIE-COULEURS/$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
