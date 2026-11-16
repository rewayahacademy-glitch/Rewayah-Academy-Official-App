// FINITIONS-MESSAGERIE : captures R3 (sautees sans CAPTURE_DIR).
// Conversation ouverte et liste a 390 (fr, ar), barre du haut avec un
// compteur a 1 et a 12 sur la page Messages.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import '../../support/hote_theme.dart';
import 'support_messages.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String nom, String chemin) in <(String, String)>[
        ('conversation', 'fil-adam'),
        ('liste', ''),
      ]) {
        testWidgets('$nom-390-${langue.languageCode}', (tester) async {
          await monterMessages(
            tester,
            port: portDemo(RoleDemoCommunications.enseignant),
            depart: chemin.isEmpty ? cheminListeTest : cheminFilTest(chemin),
            taille: const Size(390, 844),
            langue: langue,
          );
          await tester.pumpAndSettle();
          await capturerVue(
            tester,
            'FINITIONS-MESSAGERIE/$nom-390-${langue.languageCode}',
          );
        });
      }
    }
    for (final int n in <int>[1, 12]) {
      testWidgets('barre-haut-compteur-$n', (tester) async {
        tester.view.physicalSize = const Size(390, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteTheme(
            AdminShell(
              domaines: domainesAdmin(voitDirection: true),
              domaineActif: AdminDomaine.accueil,
              onAller: (String _) {},
              onCompte: () {},
              onNotifications: () {},
              messages: ClocheNotifications(
                icone: AppIcons.discussion,
                onPress: () {},
                actif: true,
                nonLues: n,
              ),
              child: const Center(child: Text('Messages')),
            ),
            defilant: false,
          ),
        );
        await tester.pumpAndSettle();
        await capturerVue(
          tester,
          'FINITIONS-MESSAGERIE/barre-haut-compteur-$n',
        );
      });
    }
  }, skip: sautSansCapture);
}
