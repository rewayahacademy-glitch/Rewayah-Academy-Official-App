// EA-1b : squelette des captures de la vague Eleves adultes, complete en
// EA-12 (recette) pour chaque ecran et les 25 cas du doc section 18. Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Modele :
// `captures_en_test.dart`. Chaque ecran passe par la VRAIE route
// /demo/adulte (routesDemoAdulte) sous un GoRouter, comme dans l'application :
// le Foyer de « Ma famille » lit GoRouter.of(context) des sa construction.
// Sortie a plat dans CAPTURE_DIR (le lancer avec CAPTURE_DIR=...\ea1b).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/demo_adulte_page.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 1200)),
  ('768', Size(768, 1100)),
  ('1440', Size(1440, 1000)),
];

const List<ThemeMode> _themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
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
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
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
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  // -------------------------------------------------------------------
  // Coquille de l'eleve adulte (EA-1b) : 3 destinations, plus Ma famille
  // (coquille du tuteur sur le Foyer). Les variantes de Mon espace sont
  // retirees avec lui (MON-ESPACE-ADULTE-SUPPR, 11/11/2026).
  // -------------------------------------------------------------------
  group('Capture EA-1b : coquille', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EcranDemoAdulte ecran in EcranDemoAdulte.values) {
      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _themes) {
          testWidgets('coquille_${ecran.name}_${l}_${mode.name}', (
            WidgetTester tester,
          ) async {
            await _capturer(
              tester,
              'ea1b_${ecran.name}_${l}_${mode.name}',
              adresseDemoAdulte(ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });
}
