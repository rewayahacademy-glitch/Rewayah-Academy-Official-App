// Captures R3 du bloc « Lots a confirmer » : ferme, avec deux lots, vide, en
// erreur. fr et ar, 360 et 1440.
//
// CAPTURE_DIR=docs/current/captures/E2E/PX-BD-0-ECRAN flutter test \
//   test/features/admin_acces_agents/capture_lots_praxis_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/lots_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_acces_agents/lots_praxis_section.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_service_lots_praxis.dart';
import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  bool arabe,
  FauxServiceLotsPraxis faux, {
  required bool afficher,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Directionality(
        textDirection: arabe ? TextDirection.rtl : TextDirection.ltr,
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: LotsPraxisSection(),
          ),
        ),
      ),
      surcharges: <Override>[serviceLotsPraxisProvider.overrideWithValue(faux)],
    ),
  );
  await tester.pumpAndSettle();
  if (afficher) {
    await tester.tap(find.byKey(ClesLotsPraxis.afficher));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('captures PX-BD-0-ECRAN', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size taille, AppLocale langue) in <(Size, AppLocale)>[
      (const Size(360, 800), AppLocale.fr),
      (const Size(360, 800), AppLocale.ar),
      (const Size(1440, 900), AppLocale.fr),
      (const Size(1440, 900), AppLocale.ar),
    ]) {
      final String suffixe = '${taille.width.toInt()}-${langue.languageCode}';
      final bool arabe = langue == AppLocale.ar;
      Future<void> avant(WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      }

      testWidgets('ferme $suffixe', (WidgetTester tester) async {
        await avant(tester);
        await _monter(
          tester,
          taille,
          arabe,
          FauxServiceLotsPraxis(),
          afficher: false,
        );
        await capturerVue(tester, '1-ferme-$suffixe');
      });
      testWidgets('lots $suffixe', (WidgetTester tester) async {
        await avant(tester);
        await _monter(
          tester,
          taille,
          arabe,
          FauxServiceLotsPraxis(
            lots: <LotPraxis>[
              lotFictif(),
              lotFictif(
                id: 'l2',
                code: '007154',
                nb: 1,
                resume: <String>['Note S : trois'],
              ),
            ],
          ),
          afficher: true,
        );
        await capturerVue(tester, '2-lots-$suffixe');
      });
      testWidgets('vide $suffixe', (WidgetTester tester) async {
        await avant(tester);
        await _monter(
          tester,
          taille,
          arabe,
          FauxServiceLotsPraxis(),
          afficher: true,
        );
        await capturerVue(tester, '3-vide-$suffixe');
      });
      testWidgets('erreur $suffixe', (WidgetTester tester) async {
        await avant(tester);
        await _monter(
          tester,
          taille,
          arabe,
          FauxServiceLotsPraxis(erreurLecture: Exception('x')),
          afficher: true,
        );
        await capturerVue(tester, '4-erreur-$suffixe');
      });
    }
  }, skip: sautSansCapture);
}
