// Captures de recette AD-5 (file ADM-02A), sur le vrai routeur en
// demonstration admin, comme `main.dart` (`?demo=admin`) : Personnes >
// Dossiers a 390x844, 768x1024 et 1440x900, clair et sombre ; a 1440, le
// squelette et « Selectionnez un dossier a examiner. ».
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
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

late WidgetRef _ref;

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode, {
  bool attendre = true,
}) async {
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
              _ref = ref;
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
  if (attendre) {
    await stabiliser(tester);
  }
}

void main() {
  group('Capture : AD-5 file des dossiers', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, liste puis detail, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'ad5_file_390x844@3_${mode.name}')}',
        );
        await tester.tap(
          find.bySemanticsLabel(RegExp("^Ouvrir le dossier d'Amina")),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ad5_detail_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('768x1024 @1, repli sequentiel, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(768, 1024), 1);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'ad5_file_768x1024@1_${mode.name}')}',
        );
      });

      testWidgets('1440x900 @1, maitre-detail, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, mode);
        debugPrint(
          'PNG ${await capturer(tester, 'ad5_maitre_detail_1440x900@1_${mode.name}')}',
        );
        _ref.read(selectionDossierProvider.notifier).retirer();
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ad5_aucune_selection_1440x900@1_${mode.name}')}',
        );
      });
    }
    // Squelette : non capture. La demonstration repond dans la trame ; une
    // trame de transition n'est pas une preuve (ecart note au relevé AD-5).
  });
}
