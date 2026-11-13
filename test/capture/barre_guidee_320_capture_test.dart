// ESPACE-APPRENDRE (lot 5), arbitrage de l'architecte du 13/11/2026 : la barre
// guidee reste sur UNE rangee ; quand les libelles ne tiennent pas, les
// onglets non selectionnes passent en icone seule. Captures de la barre basse
// a 320 pour les quatre roles (avant / apres le lot : meme test, deux
// versions de `NavShell`).
//
//   CAPTURE_DIR=docs/current/captures/E2E/espace-apprendre/barre/apres \
//     flutter test test/capture/barre_guidee_320_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, sautSansCapture;

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Capture de la barre guidee a 320', skip: sautSansCapture, () {
    for (final AppRole role in <AppRole>[
      AppRole.student,
      AppRole.guardian,
      AppRole.teacher,
      AppRole.controller,
    ]) {
      for (final double echelle in <double>[1, 2]) {
        testWidgets('barre guidee ${role.valeurSql} 320 x${echelle.toInt()}', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = const Size(320, 220);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final List<Destination> d = destinationsPour(
            role: role,
            mode: InterfaceMode.enfant,
          );
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
                  builder: (BuildContext context, Widget? app) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(echelle)),
                    child: app!,
                  ),
                  home: Scaffold(
                    body: NavShell(
                      destinations: d,
                      indexActif: 1,
                      onAller: (String _) {},
                      libellesDansLeRail: false,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          await capturerVue(
            tester,
            'barre-guidee-${role.valeurSql}-320-x${echelle.toInt()}',
          );
        });
      }
    }
  });
}
