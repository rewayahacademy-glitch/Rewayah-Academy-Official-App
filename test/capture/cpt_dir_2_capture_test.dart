// Captures CPT-DIR-2 (Q-9 et Q-10, decides par delegation le 05/10), dans la
// VRAIE coquille du Comptable en demonstration (`CoquilleComptableDemo`) :
//
// - en ARABE (textes slang en arabe ET sens RTL), montants affiches pour voir
//   l'isolement bidi des montants : Aujourd'hui, Paiements, Tresorerie,
//   Encaissements, a 390x844 @3, 1440x900 @1 et 320x640 @2 texte x2, clair et
//   sombre ; plus la Tresorerie arabe montants masques (masque en RTL) ;
// - en FRANCAIS, montants masques, la jauge et le pourcentage de la Reserve
//   (Aujourd'hui) et la part detenue des coffres (Tresorerie), defiles
//   jusqu'a eux, 390 et 1440, clair et sombre.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
//
//   CAPTURE_DIR=docs/current/captures/CPT-DIR-2 \
//     flutter test test/capture/cpt_dir_2_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/comptable/carte_reserve_strategique.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/carte_coffre.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import 'outil_capture.dart';

Future<void> _comptable(
  WidgetTester tester,
  EcranDemoComptable ecran, {
  required ThemeMode mode,
  double texte = 1,
  bool affiches = false,
  bool arabe = false,
}) async {
  if (arabe) {
    // La locale arabe est chargee en differe par slang.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  }
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
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: (arabe ? AppLocale.ar : AppLocale.fr).flutterLocale,
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
  await stabiliser(tester);
}

/// Defile jusqu'au premier [cible] pour le montrer en haut de la vue.
/// Une liste paresseuse ne construit pas ce qui est loin : on defile d'abord
/// jusqu'a ce que [cible] existe.
Future<void> _defilerJusqua(WidgetTester tester, Finder cible) async {
  if (cible.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      cible.first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(cible.first), alignment: 0.15);
  await stabiliser(tester);
}

const Size _mobile = Size(390, 844);
const Size _bureau = Size(1440, 900);
const Size _etroit = Size(320, 640);
const EdgeInsets _zone = EdgeInsets.only(top: 47, bottom: 34);

void main() {
  group('Captures CPT-DIR-2', skip: sautSansCapture, () {
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

    for (final EcranDemoComptable e in <EcranDemoComptable>[
      EcranDemoComptable.aujourdhui,
      EcranDemoComptable.paiements,
      EcranDemoComptable.tresorerie,
      EcranDemoComptable.encaissements,
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String n = '${e.name}_ar';
        testWidgets('390x844 @3, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
          await _comptable(tester, e, mode: mode, affiches: true, arabe: true);
          debugPrint(
            'PNG ${await capturer(tester, '${n}_390x844@3_${mode.name}_affiches')}',
          );
        });
        testWidgets('1440x900 @1, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _comptable(tester, e, mode: mode, affiches: true, arabe: true);
          debugPrint(
            'PNG ${await capturer(tester, '${n}_1440x900@1_${mode.name}_affiches')}',
          );
        });
        testWidgets('320x640 @2 texte x2, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _etroit, 2);
          await _comptable(
            tester,
            e,
            mode: mode,
            texte: 2,
            affiches: true,
            arabe: true,
          );
          debugPrint(
            'PNG ${await capturer(tester, '${n}_320x640@2_texte2_${mode.name}_affiches')}',
          );
        });
      }
    }

    testWidgets('390x844 @3, tresorerie_ar, clair, masques', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
      await _comptable(
        tester,
        EcranDemoComptable.tresorerie,
        mode: ThemeMode.light,
        arabe: true,
      );
      await _defilerJusqua(tester, find.byType(CarteCoffre));
      debugPrint(
        'PNG ${await capturer(tester, 'tresorerie_ar_coffres_390x844@3_light_masques')}',
      );
    });

    // Sur telephone, Aujourd'hui ne porte pas la carte de la Reserve (une
    // tache dominante, M01) : la jauge s'y voit a 1440, et a 390 dans la
    // Tresorerie.
    for (final (EcranDemoComptable e, Type cible, String nom, bool mobile) p
        in <(EcranDemoComptable, Type, String, bool)>[
          (
            EcranDemoComptable.aujourdhui,
            CarteReserveStrategique,
            'aujourdhui_fr_reserve',
            false,
          ),
          (
            EcranDemoComptable.tresorerie,
            CarteReserveStrategique,
            'tresorerie_fr_reserve',
            true,
          ),
          (
            EcranDemoComptable.tresorerie,
            CarteCoffre,
            'tresorerie_fr_coffres',
            true,
          ),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String n = p.$3;
        if (p.$4) {
          testWidgets('390x844 @3, $n, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, _mobile, 3, zoneSure: _zone);
            await _comptable(tester, p.$1, mode: mode);
            await _defilerJusqua(tester, find.byType(p.$2));
            debugPrint(
              'PNG ${await capturer(tester, '${n}_390x844@3_${mode.name}_masques')}',
            );
          });
        }
        testWidgets('1440x900 @1, $n, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _comptable(tester, p.$1, mode: mode);
          await _defilerJusqua(tester, find.byType(p.$2));
          debugPrint(
            'PNG ${await capturer(tester, '${n}_1440x900@1_${mode.name}_masques')}',
          );
        });
      }
    }
  });
}
