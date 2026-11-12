// COMPTE-A-REBOURS-JOURS (12/11/2026) : la PAGE ENTIERE de l'accueil adulte
// (« Bonjour … », « Prochaine séance », carte de séance), montée dans la
// vraie coquille adulte, a 110 h 14 du cours : des jours, jamais des heures.
// Captures R3 si CAPTURE_DIR est donne.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/classe_demo.dart';
import '../../support/demo/demo_adulte_page.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('accueil adulte entier a 110 h 14 : ${langue.languageCode}', (
      WidgetTester tester,
    ) async {
      if (dossierCapture != null) await tester.runAsync(chargerPolicesDuDepot);
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      fixerVueCapture(tester, const Size(390, 1100), 1);
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoAdulte(
          EcranDemoAdulte.accueil,
          seance: EtatDemoClasse.dansQuatreJours,
        ),
        routes: routesDemoAdulte('dev'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: RepaintBoundary(
              key: cadreCapture,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: langue.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.byType(CarteSession), findsOneWidget);
      expect(find.textContaining('110'), findsNothing);
      expect(
        find.textContaining(
          langue == AppLocale.fr
              ? RegExp(r'^Cours dans [45] jours$')
              : RegExp('أيام'),
        ),
        findsOneWidget,
      );
      if (dossierCapture != null) {
        await capturer(tester, 'page_accueil_adulte_${langue.languageCode}');
      }
    });
  }
}
