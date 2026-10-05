// Captures de recette de CPT-CTR-1 (W06 Contractuels & obligations) : les
// trois ecrans de la voie dans la VRAIE coquille du Comptable en
// demonstration (`CoquilleComptableDemo`, donnees fictives), 390x844 @3 et
// 1440x900 @1 en clair et en sombre, 320x640 @2 texte x2 en clair.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/contractuels/contractuels_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/obligation_contractuel_page.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget Function() ecran, {
  ThemeMode mode = ThemeMode.light,
  double texte = 1,
}) async {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran()),
    ],
  );
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    TranslationProvider(
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
  );
  await stabiliser(tester);
}

Widget _page(Widget page, {bool affiches = false}) => ProviderScope(
  overrides: surchargesCoquilleComptableDemo(montantsAffiches: affiches),
  child: page,
);

void main() {
  group('Capture : W06 Contractuels (CPT-CTR-1)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    final List<(String, EcranDemoComptable)> ecrans =
        <(String, EcranDemoComptable)>[
          ('liste', EcranDemoComptable.contractuels),
          ('detail', EcranDemoComptable.obligationContractuel),
          ('nouvelle', EcranDemoComptable.nouvelleObligation),
        ];

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, EcranDemoComptable e) in ecrans) {
        testWidgets('390x844 @3, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(
            tester,
            () => CoquilleComptableDemo(ecran: e),
            mode: mode,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ctr_${nom}_390x844@3_${mode.name}')}',
          );
        });
        testWidgets('1440x900 @1, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(
            tester,
            () => CoquilleComptableDemo(ecran: e),
            mode: mode,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ctr_${nom}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }

    for (final (String nom, EcranDemoComptable e) in ecrans) {
      testWidgets('320x640 @2 texte x2, $nom', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 640), 2);
        await _monter(tester, () => CoquilleComptableDemo(ecran: e), texte: 2);
        debugPrint(
          'PNG ${await capturer(tester, 'ctr_${nom}_320x640@2_texte2_light')}',
        );
      });
    }

    // Les variantes que la demonstration fixe ne montre pas : montants
    // affiches, zone « A payer », une obligation a approuver avec invitation
    // d'un externe, une obligation dont l'auteur est le Comptable.
    final List<(String, Widget Function())>
    variantes = <(String, Widget Function())>[
      ('liste_affiches', () => _page(const ContractuelsPage(), affiches: true)),
      ('liste_a_payer', () => _page(const ContractuelsPage(onglet: 'a-payer'))),
      (
        'detail_a_approuver_externe',
        () =>
            _page(const ObligationContractuelPage(obligationId: 'obl-ctr-027')),
      ),
      (
        'detail_auteur_comptable',
        () =>
            _page(const ObligationContractuelPage(obligationId: 'obl-ctr-025')),
      ),
      (
        'detail_recurrente',
        () => _page(
          const ObligationContractuelPage(obligationId: 'obl-ctr-026'),
          affiches: true,
        ),
      ),
    ];
    for (final (String nom, Widget Function() w) in variantes) {
      testWidgets('390x844 @3, $nom', (WidgetTester tester) async {
        fixerVueCapture(
          tester,
          const Size(390, 844),
          3,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monter(tester, w);
        debugPrint(
          'PNG ${await capturer(tester, 'ctr_${nom}_390x844@3_light')}',
        );
      });
    }
  });
}
