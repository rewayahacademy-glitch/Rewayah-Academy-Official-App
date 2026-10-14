// Recette visuelle Comptable V1 (CPT-CAPT), apres fusion : chaque ecran W01 a
// W07, M01, M02 dans la VRAIE coquille du Comptable en demonstration
// (`CoquilleComptableDemo`, donnees fictives §44) et les deux panneaux
// Direction (Reserve, delegation) dans la coquille admin de
// `/demo/finance?ecran=reserveDelegation`.
//
// Formats : 390x844 @3 clair et sombre (montants masques), 1440x900 @1 clair
// et sombre (masques), 390x844 @3 clair montants affiches, 320x640 @2 texte
// x2 clair, 1440x900 @1 affiches sur les modules monetaires, RTL (Aujourd'hui,
// Paiements, Tresorerie) a 390 et 320 texte x2.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
//
//   CAPTURE_DIR=docs/current/captures/CPT-CAPT \
//     flutter test test/capture/cpt_capt_recette_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../features/admin_finance/reserve_delegation/support_direction.dart';
import 'outil_capture.dart';

Widget _app({
  required GoRouter routeur,
  required ThemeMode mode,
  required double texte,
  Locale? locale,
  List<Override> surcharges = const <Override>[],
}) {
  return ProviderScope(
    overrides: surcharges,
    child: TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: locale ?? TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(texte)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
}

Future<void> _comptable(
  WidgetTester tester,
  EcranDemoComptable ecran, {
  ThemeMode mode = ThemeMode.light,
  double texte = 1,
  bool affiches = false,
  Locale? locale,
  bool racine = false,
}) async {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) =>
            CoquilleComptableDemo(ecran: ecran, montantsAffiches: affiches),
      ),
    ],
  );
  await tester.pumpWidget(
    _app(
      routeur: routeur,
      mode: mode,
      texte: texte,
      locale: locale,
      // Par defaut AUCUNE surcharge a la racine, comme l'app en
      // preproduction (CPT-RC, M1) : seule la `ProviderScope` imbriquee de
      // la coquille de demonstration pose les ports.
      surcharges: racine
          ? surchargesCoquilleComptableDemo(montantsAffiches: affiches)
          : const <Override>[],
    ),
  );
  await stabiliser(tester);
}

Future<void> _direction(
  WidgetTester tester, {
  required ThemeMode mode,
  double texte = 1,
  bool affiches = false,
  bool delegation = false,
}) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoFinance(OngletFinance.reserveDelegation),
    routes: routesDemoFinance('staging'),
  );
  await tester.pumpWidget(
    _app(
      routeur: routeur,
      mode: mode,
      texte: texte,
      surcharges: sessionDirection(),
    ),
  );
  await tester.pumpAndSettle();
  if (affiches) {
    final Finder b = find.byType(BasculeMontants);
    await tester.ensureVisible(b.first);
    await tester.tap(b.first);
    await tester.pumpAndSettle();
  }
  if (delegation) {
    final Finder d = find.byType(FinanceDelegationPolicyPanelBloc);
    await Scrollable.ensureVisible(tester.element(d.first), alignment: 0);
    await tester.pumpAndSettle();
  }
}

const Size _mobile = Size(390, 844);
const Size _bureau = Size(1440, 900);
const Size _etroit = Size(320, 640);
const EdgeInsets _zone = EdgeInsets.only(top: 47, bottom: 34);

void main() {
  group('Recette visuelle Comptable (CPT-CAPT)', skip: sautSansCapture, () {
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

    const Set<EcranDemoComptable> monetaires = <EcranDemoComptable>{
      EcranDemoComptable.aujourdhui,
      EcranDemoComptable.paiements,
      EcranDemoComptable.tresorerie,
      EcranDemoComptable.encaissements,
      EcranDemoComptable.contractuels,
    };

    for (final EcranDemoComptable e in EcranDemoComptable.values) {
      if (e == EcranDemoComptable.reserveDelegation) continue;
      final String n = e.name;
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('390x844 @3, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
          await _comptable(tester, e, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, '${n}_390x844@3_${mode.name}_masques')}',
          );
        });
        testWidgets('1440x900 @1, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _comptable(tester, e, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, '${n}_1440x900@1_${mode.name}_masques')}',
          );
        });
      }
      testWidgets('390x844 @3, $n, clair, affiches', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
        await _comptable(tester, e, affiches: true);
        debugPrint(
          'PNG ${await capturer(tester, '${n}_390x844@3_light_affiches')}',
        );
      });
      if (monetaires.contains(e)) {
        testWidgets('1440x900 @1, $n, sombre, affiches', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _comptable(tester, e, mode: ThemeMode.dark, affiches: true);
          debugPrint(
            'PNG ${await capturer(tester, '${n}_1440x900@1_dark_affiches')}',
          );
        });
      }
      testWidgets('320x640 @2 texte x2, $n', (WidgetTester tester) async {
        fixerVueCapture(tester, _etroit, 2);
        await _comptable(tester, e, texte: 2);
        debugPrint(
          'PNG ${await capturer(tester, '${n}_320x640@2_texte2_light_masques')}',
        );
      });
    }

    for (final EcranDemoComptable e in <EcranDemoComptable>[
      EcranDemoComptable.aujourdhui,
      EcranDemoComptable.paiements,
      EcranDemoComptable.tresorerie,
    ]) {
      testWidgets('390x844 @3, ${e.name}, RTL', (WidgetTester tester) async {
        fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
        await _comptable(tester, e, locale: AppLocale.ar.flutterLocale);
        debugPrint(
          'PNG ${await capturer(tester, '${e.name}_390x844@3_light_rtl')}',
        );
      });
      testWidgets('320x640 @2 texte x2, ${e.name}, RTL', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _etroit, 2);
        await _comptable(
          tester,
          e,
          texte: 2,
          locale: AppLocale.ar.flutterLocale,
        );
        debugPrint(
          'PNG ${await capturer(tester, '${e.name}_320x640@2_texte2_rtl')}',
        );
      });
    }

    for (final (String nom, bool delegation) p in <(String, bool)>[
      ('direction_reserve', false),
      ('direction_delegation', true),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('390x844 @3, ${p.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
          await _direction(tester, mode: mode, delegation: p.$2);
          debugPrint(
            'PNG ${await capturer(tester, '${p.$1}_390x844@3_${mode.name}_masques')}',
          );
        });
        testWidgets('1440x900 @1, ${p.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _direction(tester, mode: mode, delegation: p.$2);
          debugPrint(
            'PNG ${await capturer(tester, '${p.$1}_1440x900@1_${mode.name}_masques')}',
          );
        });
      }
      testWidgets('390x844 @3, ${p.$1}, clair, affiches', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
        await _direction(
          tester,
          mode: ThemeMode.light,
          affiches: true,
          delegation: p.$2,
        );
        debugPrint(
          'PNG ${await capturer(tester, '${p.$1}_390x844@3_light_affiches')}',
        );
      });
      testWidgets('320x640 @2 texte x2, ${p.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, _etroit, 2);
        await _direction(
          tester,
          mode: ThemeMode.light,
          texte: 2,
          delegation: p.$2,
        );
        debugPrint(
          'PNG ${await capturer(tester, '${p.$1}_320x640@2_texte2_light_masques')}',
        );
      });
    }
  });
}
