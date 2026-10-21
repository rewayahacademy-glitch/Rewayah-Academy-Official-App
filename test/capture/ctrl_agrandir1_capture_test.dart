// CTRL-AGRANDIR-1 : la salle du controleur sans « Agrandir le support » (aucun
// support rendu ; la commande agrandissait l'enseignant, releve VERIF-CT-1),
// a 320 x2, 390 x3 et 1440 x1, clair et sombre. Jamais sans `CAPTURE_DIR`
// (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import 'outil_capture.dart';

void main() {
  group(
    'Capture : CTRL-AGRANDIR-1, salle du controleur',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final (String l, Size taille, double densite)
          in <(String, Size, double)>[
            ('320', const Size(320, 700), 2),
            ('390', const Size(390, 844), 3),
            ('1440', const Size(1440, 900), 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('ctrl_agrandir1_salle_${l}_$m', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, densite);
            final GoRouter routeur = GoRouter(
              initialLocation: cheminDemoSalleControleur,
              routes: routesDemoControleur('dev'),
            );
            await tester.pumpWidget(
              ProviderScope(
                child: TranslationProvider(
                  child: RepaintBoundary(
                    key: cadreCapture,
                    child: Builder(
                      builder: (BuildContext contexte) => MaterialApp.router(
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
                        locale: TranslationProvider.of(contexte).flutterLocale,
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
            expect(
              find.bySemanticsLabel(RegExp(t.salle.visiteControle.agrandir)),
              findsNothing,
            );
            debugPrint(
              'PNG ${await capturer(tester, 'ctrl_agrandir1_salle_${l}_$m')}',
            );
          });
        }
      }
    },
  );
}
