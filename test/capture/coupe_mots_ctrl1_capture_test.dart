// COUPE-MOTS-CTRL-1 : le Controle (demonstration, en direct et deja
// controle) a 320 px et vrai texte x2 (densite 1), clair et sombre, LTR et
// RTL, et a 1440 pour verifier que la pastille reste au bord de fin quand la
// ligne suffit. Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

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

Future<void> _monter(
  WidgetTester tester,
  EtatDemoControleur etat,
  ThemeMode mode,
  double echelle,
  TextDirection direction,
) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoControleur(
      EcranDemoControleur.controle,
      etat: etat,
    ),
    routes: routesDemoControleur('dev'),
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
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: Directionality(textDirection: direction, child: app!),
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : COUPE-MOTS-CTRL-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EtatDemoControleur etat in <EtatDemoControleur>[
      EtatDemoControleur.enDirect,
      EtatDemoControleur.dejaControlee,
    ]) {
      for (final (String th, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final (String l, Size taille, double echelle, TextDirection d)
            in <(String, Size, double, TextDirection)>[
              ('320x2_ltr', const Size(320, 1100), 2, TextDirection.ltr),
              ('320x2_rtl', const Size(320, 1100), 2, TextDirection.rtl),
              ('1440', const Size(1440, 900), 1, TextDirection.ltr),
            ]) {
          final String nom = 'controle_${etat.name}_${l}_$th';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await _monter(tester, etat, mode, echelle, d);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });
}
