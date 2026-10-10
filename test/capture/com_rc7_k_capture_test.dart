// Captures de recette de la revue du lot K (COM-RC 7) : les echanges du
// controleur partagent le fil des Communications (`FilDiscussion`) ; a 768
// et 1440, un message recu prend la colonne et un message de soi garde un
// leger retrait au debut (92 %), pose au bord d'« Envoyer ». 390 pour
// comparaison (86 %).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Capture : lot K, echanges du controleur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, Size taille, double densite)
        in <(String, Size, double)>[
          ('390', const Size(390, 844), 2),
          ('768', const Size(768, 1024), 1),
          ('1440', const Size(1440, 900), 1),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier =
            'com_controleur_echanges_${nom}_'
            '${mode == ThemeMode.light ? 'clair' : 'sombre'}';
        testWidgets(fichier, (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
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
                      darkTheme: AppTheme.pour(
                        InterfaceMode.standard,
                        Brightness.dark,
                      ),
                      themeMode: mode,
                      locale: TranslationProvider.of(context).flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      routerConfig: GoRouter(
                        initialLocation: adresseDemoControleur(
                          EcranDemoControleur.echanges,
                          fil: 'demo-mission-al-badr-0924',
                        ),
                        routes: routesDemoControleur('dev'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier)}');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  });
}
