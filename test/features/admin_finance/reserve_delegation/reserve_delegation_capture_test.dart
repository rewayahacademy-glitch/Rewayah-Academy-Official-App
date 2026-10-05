// Captures de recette de CPT-DIR-1 : l'onglet « Reserve et delegation » dans
// la vraie coquille admin, par `/demo/finance?ecran=reserveDelegation`.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais, rien n'est ecrit). Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.
//
//   CAPTURE_DIR=docs/current/captures/CPT-DIR-1 \
//     flutter test test/features/admin_finance/reserve_delegation/reserve_delegation_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../../../capture/outil_capture.dart';
import 'support_direction.dart';

Future<void> _monter(
  WidgetTester tester, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoFinance(OngletFinance.reserveDelegation),
    routes: routesDemoFinance('staging'),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: sessionDirection(),
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
            builder: (BuildContext context, Widget? app) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible.first);
  await tester.tap(cible.first);
  await tester.pumpAndSettle();
}

void main() {
  group(
    'Capture : Reserve et delegation (CPT-DIR-1)',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        final List<String> familles = await chargerPolicesDuDepot();
        debugPrint('FAMILLES chargees : ${familles.join(', ')}');
      });

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String m = mode.name;
        testWidgets('390x844 @3, haut de page, $m', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, mode: mode);
          debugPrint('PNG ${await capturer(tester, 'reserve_390x844@3_$m')}');
        });

        testWidgets('1440x900 @1, haut de page, $m', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, mode: mode);
          debugPrint('PNG ${await capturer(tester, 'reserve_1440x900@1_$m')}');
        });

        testWidgets('390 pleine hauteur, montants affiches, $m', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 7600), 1);
          await _monter(tester, mode: mode);
          await _toucher(tester, find.byType(BasculeMontants));
          debugPrint('PNG ${await capturer(tester, 'pleine_390_$m')}');
        });

        testWidgets('1440 pleine hauteur, $m', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(1440, 4200), 1);
          await _monter(tester, mode: mode);
          debugPrint('PNG ${await capturer(tester, 'pleine_1440_$m')}');
        });
      }

      testWidgets('320 texte x2, pleine hauteur, clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 14000), 1);
        await _monter(tester, mode: ThemeMode.light, echelle: 2);
        debugPrint('PNG ${await capturer(tester, 'pleine_320_x2_light')}');
      });

      testWidgets('390 : couverture en mois, pourcentage, saisie illisible', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 7600), 1);
        await _monter(tester, mode: ThemeMode.light);
        final r = t.comptable.direction.reservePanneau;
        await _toucher(tester, find.text(r.modeMois));
        await _toucher(tester, find.text(r.regle.pourcentage));
        await tester.enterText(
          find
              .descendant(
                of: find.byWidgetPredicate(
                  (Widget w) =>
                      w is Semantics && w.properties.label == r.nombreMois,
                ),
                matching: find.byType(TextField),
              )
              .first,
          '0',
        );
        await tester.pumpAndSettle();
        await _toucher(
          tester,
          find.text(t.comptable.direction.enregistrer).first,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'etat_mois_pourcentage_erreur_390')}',
        );
      });
    },
  );
}
