// Captures de la suppression des toleres prouves (feu vert du directeur,
// 08/11/2026) : aucun ecran de production ne change. Preuve : « Ma famille »
// de l'eleve adulte titulaire montre toujours les soldes du foyer par
// `SyntheseSoldesFoyer`, le module branche dont `soldes_foyer.dart` (supprime)
// etait le doublon. 390x844 et 1440x900, clair, francais et arabe.
// Donnees de demonstration uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';

import '../support/demo/demo_adulte_page.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : suppression des toleres', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final String nom =
            'sup_ma_famille_${taille.width.toInt()}_${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, taille, 1);
          final GoRouter routeur = GoRouter(
            initialLocation: adresseDemoAdulte(EcranDemoAdulte.maFamille),
            routes: routesDemoAdulte('dev'),
          );
          addTearDown(routeur.dispose);
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: RepaintBoundary(
                  key: cadreCapture,
                  child: Builder(
                    builder: (BuildContext context) => MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.pour(
                        InterfaceMode.standard,
                        Brightness.light,
                      ),
                      locale: TranslationProvider.of(context).flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      routerConfig: routeur,
                    ),
                  ),
                ),
              ),
            ),
          );
          await stabiliser(tester);
          expect(find.byType(SyntheseSoldesFoyer), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });
      }
    }
  });
}
