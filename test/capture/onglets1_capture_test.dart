// ONGLETS-1 : captures de `SelecteurSection` (sous-navigation de Pedagogie et
// de Configuration) sur le VRAI routeur, en demonstration admin, a 320 et
// 1440 px, texte x1 et x2, clair et sombre, puis les quatre autres pages de
// Pedagogie a 320 px (ONGLETS-COUPE-1). Sautee sans CAPTURE_DIR.
//
//   CAPTURE_DIR=docs/current/captures/l1-onglets flutter test \
//     test/capture/onglets1_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../support/selecteur_section.dart';
import 'outil_capture.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String route,
  ThemeMode mode,
  double echelle,
) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surchargesDemoAdmin(environnement: 'staging'),
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
                builder: (BuildContext contexte, Widget? child) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: RepereDemonstration(child: child),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
  return routeur;
}

void main() {
  group('Capture : ONGLETS-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String domaine, String route) d in <(String, String)>[
      ('pedagogie', Routes.adminPedagogieDiagnostics),
      ('configuration', Routes.adminConfigurationFonctionnalites),
    ]) {
      for (final (String nom, Size taille) t in <(String, Size)>[
        ('320', const Size(320, 640)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final double echelle in const <double>[1, 2]) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            final String suffixe = '${t.$1}_x${echelle.toInt()}_${mode.name}';
            testWidgets('${d.$1} $suffixe', (WidgetTester tester) async {
              fixerVueCapture(tester, t.$2, 1);
              await _monter(tester, d.$2, mode, echelle);
              debugPrint('PNG ${await capturer(tester, '${d.$1}_$suffixe')}');
            });
            if (t.$1 == '320') {
              testWidgets('${d.$1} menu ouvert $suffixe', (
                WidgetTester tester,
              ) async {
                fixerVueCapture(tester, t.$2, 1);
                await _monter(tester, d.$2, mode, echelle);
                await tester.tap(
                  find.descendant(
                    of: selecteurSection,
                    matching: find.byType(InkWell).first,
                  ),
                );
                await stabiliser(tester);
                debugPrint(
                  'PNG ${await capturer(tester, '${d.$1}_ouvert_$suffixe')}',
                );
              });
            }
          }
        }
      }
    }

    // ONGLETS-COUPE-1 : les quatre autres pages de Pedagogie a 320 px, ou la
    // colonne debordait de 52 a 480 px (texte x1 et x2, clair et sombre).
    for (final (String nom, String route) p in <(String, String)>[
      ('progression', Routes.adminPedagogieProgression),
      ('evaluations', Routes.adminPedagogieEvaluations),
      ('programmes', Routes.adminPedagogieProgrammes),
      ('qualite', Routes.adminPedagogieQualite),
    ]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String suffixe = '320_x${echelle.toInt()}_${mode.name}';
          testWidgets('${p.$1} $suffixe', (WidgetTester tester) async {
            fixerVueCapture(tester, const Size(320, 640), 1);
            await _monter(tester, p.$2, mode, echelle);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, '${p.$1}_$suffixe')}');
          });
        }
      }
    }
  });
}
