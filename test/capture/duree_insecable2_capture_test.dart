// DUREE-INSECABLE-2 : capture dediee de la carte de seance `CarteSession`
// (Teaching Core), seule, a 320 px et texte x2, en LTR et en RTL.
//
// Avant (3df81930, base de DUREE-INSECABLE-1) : « Cours dans 3 h / 28 »
// scinde, duree prevue « min 45 » en RTL. Apres : la duree tient sur une
// ligne et garde son ordre.
//
// Prefixe des PNG : variable `CAPTURE_PREFIXE` (avant / apres).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIXE'] ?? 'apres';

void main() {
  group('Capture : DUREE-INSECABLE-2, CarteSession', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('carte de seance, 320 px texte x2, ${sens.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 470), 2);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: RepaintBoundary(
                key: cadreCapture,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  locale: AppLocale.fr.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  builder: (BuildContext c, Widget? app) => MediaQuery(
                    data: MediaQuery.of(c)
                        .copyWith(textScaler: const TextScaler.linear(2)),
                    child: Directionality(textDirection: sens, child: app!),
                  ),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: CarteSession(
                        espace: DonneesAccessibiliteDemo.espaceAccueil(
                          MomentDemoAccessibilite.avant,
                        ),
                        onRejoindre: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        expect(find.byType(CarteSession), findsOneWidget);
        await capturer(tester, '${_prefixe}_carte_session_320x2_${sens.name}');
      });
    }
  });
}
