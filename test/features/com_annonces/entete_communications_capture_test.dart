// ENTETE-COMMUNICATIONS : captures R3 (sautees sans CAPTURE_DIR).
// Telephone 390 x 844, Annonces et Messages, fr et ar ; ordinateur 1440.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../../capture/outil_capture.dart';
import 'admin_banc.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final bool arabe in <bool>[false, true]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final String onglet in <String>['annonces', 'messages']) {
          final String nom =
              '$onglet-${taille.width.toInt()}-${arabe ? 'ar' : 'fr'}';
          testWidgets(nom, (WidgetTester tester) async {
            final GoRouter routeur = await monterAdministration(
              tester,
              taille: taille,
              arabe: arabe,
            );
            if (onglet == 'messages') {
              routeur.go(Routes.adminCommunicationsMessages);
              for (int i = 0; i < 10; i++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
            }
            await capturerVue(tester, 'ENTETE-COMMUNICATIONS/$nom');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
