// Captures du lot REVENUS-VERITE (pilote, 06/11/2026) : la page « Revenus
// estimes » de l'enseignant, a 390 et 1440, en francais et en arabe, avant
// et apres le lot. Donnees de la demonstration enseignant (test/support).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../support/demo/demo_enseignant_page.dart';
import '../support/demo/enseignant_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoEnseignant(EcranDemoEnseignant.revenus),
    routes: routesDemoEnseignant('staging'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sansPersonneConnectee(),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Capture REVENUS-VERITE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 2600),
        const Size(1440, 1500),
      ]) {
        final String vue = '${taille.width.toInt()}';
        testWidgets('revenus $vue ${langue.languageCode}', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(tester, taille);
          debugPrint(
            'PNG ${await capturer(tester, 'revenus_${vue}_${langue.languageCode}')}',
          );
        });
      }
    }
  });
}
