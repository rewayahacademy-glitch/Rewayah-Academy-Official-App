// Captures de recette de la coque admin (AD-S), sur la VRAIE application et
// le vrai routeur en demonstration admin, comme `main.dart` (`?demo=admin`) :
// 390x844 (et tiroir ouvert), 768x1024 (rail) et 1440x900 (barre 288), clair
// et sombre, sur /admin/personnes/dossiers.
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
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

// `MaterialApp.router` sur le vrai routeur plutot que `RewayahApp` : la
// persistance des preferences de `RewayahApp` appelle `path_provider`, absent
// sous `runAsync` (meme choix que `foyer_capture_test.dart`).
Future<void> _monter(WidgetTester tester, ThemeMode mode) async {
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
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.adminPersonnesDossiers);
  await stabiliser(tester);
}

void main() {
  group('Capture : coque admin', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, dossiers et tiroir, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'coque_admin_dossiers_390x844@3_${mode.name}')}',
        );
        await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'coque_admin_tiroir_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('768x1024 @1, rail, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(768, 1024), 1);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'coque_admin_dossiers_768x1024@1_${mode.name}')}',
        );
      });

      testWidgets('1440x900 @1, barre 288, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'coque_admin_dossiers_1440x900@1_${mode.name}')}',
        );
      });
    }
  });
}
