// BULLES-MESSAGERIE : captures R3 (sautees sans CAPTURE_DIR). Telephone
// 390 x 844 et ordinateur 1440 x 900, en francais et en arabe, en clair et en
// sombre, sur la conversation `fil-bulles` (messages courts et longs, un
// message arabe dans l'interface francaise, deux jours, un groupe de messages
// rapproches) et sur la liste des conversations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        for (final (Size taille, String page) in <(Size, String)>[
          (const Size(390, 844), 'fil'),
          (const Size(390, 844), 'liste'),
          (const Size(1440, 900), 'fil'),
        ]) {
          final String nom =
              'bulles-$page-${taille.width.toInt()}-${langue.languageCode}'
              '-${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await monterMessages(
              tester,
              port: MessagesMetierDemo(
                role: RoleDemoCommunications.enseignant,
                maintenant: maintenantTest,
                avecBulles: true,
              ),
              depart: page == 'fil'
                  ? cheminFilTest('fil-bulles')
                  : cheminListeTest,
              taille: taille,
              langue: langue,
              luminosite: lum,
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'BULLES-MESSAGERIE/$nom');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
