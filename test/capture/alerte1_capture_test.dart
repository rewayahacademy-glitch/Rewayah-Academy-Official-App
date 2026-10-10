// ALERTE-1 : captures de preuve. Centre de commande avec une alerte urgente
// (section en tete), page des alertes (tri gravite puis date), et bandeau en
// tete d'une page de la coque admin (demonstration, cloche a point). 320 x2,
// 390, 1440 ; clair et sombre ; RTL. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/alertes/alertes_page.dart';
import 'package:rewayah_academy/features/demo/alertes_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final DateTime _maintenant = DateTime(2026, 10, 5, 17, 30);

List<Override> _surcharges() => <Override>[
  portAlertesProvider.overrideWithValue(
    AlertesDemo(horloge: () => _maintenant),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()
      ..indicateursRendus = const IndicateursAdmin(
        dossiersEnAttente: 4,
        foyersSansEnseignant: 1,
        rapportsManquants: 2,
        incidents24h: 0,
        comptesEchus: 1,
        demandesEnAttente: 2,
      ),
  ),
  serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
];

void main() {
  group('Capture : ALERTE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size, ThemeMode, double, TextDirection) cas
        in <(Size, ThemeMode, double, TextDirection)>[
          (const Size(390, 1600), ThemeMode.light, 1, TextDirection.ltr),
          (const Size(390, 1600), ThemeMode.light, 1, TextDirection.rtl),
          (const Size(320, 3200), ThemeMode.dark, 2, TextDirection.ltr),
          (const Size(320, 3200), ThemeMode.light, 2, TextDirection.rtl),
          (const Size(1440, 1100), ThemeMode.light, 1, TextDirection.ltr),
          (const Size(1440, 1100), ThemeMode.dark, 1, TextDirection.ltr),
        ]) {
      final String suffixe =
          '${cas.$1.width.toInt()}${cas.$3 == 2 ? 'x2' : ''}_'
          '${cas.$2 == ThemeMode.light ? 'clair' : 'sombre'}'
          '${cas.$4 == TextDirection.rtl ? '_rtl' : ''}';
      for (final (String nom, Widget ecran) e in <(String, Widget)>[
        ('tableau', TableauDeBordPage(horloge: () => _maintenant)),
        ('page', const AlertesPage()),
      ]) {
        testWidgets('${e.$1} $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(textDirection: cas.$4, child: e.$2),
              surcharges: _surcharges(),
              themeMode: cas.$2,
              echelleTexte: cas.$3,
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'alerte1_${e.$1}_$suffixe')}',
          );
        });
      }
    }

    for (final (Size, double) cas in <(Size, double)>[
      (const Size(390, 844), 1),
      (const Size(320, 1400), 2),
      (const Size(1440, 900), 1),
    ]) {
      final String suffixe =
          '${cas.$1.width.toInt()}${cas.$2 == 2 ? 'x2' : ''}';
      testWidgets('coque $suffixe', (WidgetTester tester) async {
        masquerRubanDebug();
        tester.view.physicalSize = cas.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (cas.$2 != 1) {
          tester.platformDispatcher.textScaleFactorTestValue = cas.$2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: surchargesDemoAdmin(
              environnement: 'staging',
              avecAlertes: true,
            ),
            child: TranslationProvider(
              child: RewayahApp(
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              ),
            ),
          ),
        );
        ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
            .read(routeurProvider)
            .go(Routes.adminPersonnesDossiers);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'alerte1_coque_$suffixe')}',
        );
      });
    }
  });
}
