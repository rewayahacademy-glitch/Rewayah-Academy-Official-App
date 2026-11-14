// LANGUES-1 (13/11/2026), etape 2 : l'anglais du chemin d'entree (connexion,
// recuperation d'acces) et le choix de la langue du compte a trois langues.
// 390 clair et 1440 sombre.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(FausseSourceSession()),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  // L'illustration de l'entree joue une fois, puis reste immobile : la
  // capture montre son image finale.
  await tester.pump(AppMouvement.entreeIllustration);
  return routeur;
}

void main() {
  group('Capture LANGUES-1 : anglais', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, String route) in <(String, String)>[
      ('connexion', Routes.connexion),
      ('recuperation', Routes.connexionRecuperation),
    ]) {
      for (final (String taille, Size vue, ThemeMode mode)
          in <(String, Size, ThemeMode)>[
            ('390-clair', const Size(390, 844), ThemeMode.light),
            ('1440-sombre', const Size(1440, 900), ThemeMode.dark),
          ]) {
        testWidgets('$nom en $taille', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          await _monter(tester, route, mode: mode, taille: vue);
          debugPrint('PNG ${await capturer(tester, 'en-$nom-$taille')}');
        });
      }
    }

    for (final (String langue, AppLocale locale) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('en', AppLocale.en),
    ]) {
      testWidgets('choix de la langue du compte, $langue, 390 clair', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 520), 2);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: FeuilleLangueCompte(),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        expect(find.text('English'), findsOneWidget);
        debugPrint('PNG ${await capturer(tester, 'langue-compte-$langue')}');
      });
    }
  });
}
