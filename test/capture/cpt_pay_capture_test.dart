// Captures de recette de la voie CPT-PAY, sur le VRAI routeur et la
// demonstration (`/demo/comptable?ecran=...`) :
// - CPT-PAY-1 : W02 Paiements a effectuer et W03 Detail, 390x844 @3 et
//   1440x900 @1, clair et sombre, puis 320x700 a texte double ;
// - CPT-PAY-2 : la confirmation d'un paiement seul (montant exact malgre le
//   masque, R-FIN-04) et le preflight d'un lot (« 11 prets / 1 exclu », recalcul compris).
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
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/paiements/barre_selection.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.accountant)),
      ),
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
}

Future<void> _appuyer(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await stabiliser(tester);
  await tester.tap(f);
  await stabiliser(tester);
}

void _telephone(WidgetTester tester, {Size taille = const Size(390, 844)}) =>
    fixerVueCapture(
      tester,
      taille,
      3,
      zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
    );

void _texteDouble(WidgetTester tester) {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('Capture : paiements du Comptable (CPT-PAY)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      final double corps = largeurSonde('PlusJakartaSans');
      final double inconnue = largeurSonde('FamilleInexistante');
      expect(corps, lessThan(inconnue * 0.6));
    });

    for (final EcranDemoComptable ecran in <EcranDemoComptable>[
      EcranDemoComptable.paiements,
      EcranDemoComptable.detailPaiement,
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('390x844 @3, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          _telephone(tester);
          await _monter(tester, adresseDemoComptable(ecran), mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'pay1_${ecran.name}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, adresseDemoComptable(ecran), mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'pay1_${ecran.name}_1440x900@1_${mode.name}')}',
          );
        });
      }

      testWidgets('320x700 @3 texte x2, ${ecran.name}', (
        WidgetTester tester,
      ) async {
        _telephone(tester, taille: const Size(320, 700));
        _texteDouble(tester);
        await _monter(tester, adresseDemoComptable(ecran));
        debugPrint(
          'PNG ${await capturer(tester, 'pay1_${ecran.name}_320x700@3_texte2')}',
        );
      });
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, confirmation seule, ${mode.name}', (
        WidgetTester tester,
      ) async {
        _telephone(tester);
        await _monter(
          tester,
          adresseDemoComptable(EcranDemoComptable.detailPaiement),
          mode: mode,
        );
        await _appuyer(tester, find.byKey(DetailPaiementPage.clePayer));
        debugPrint(
          'PNG ${await capturer(tester, 'pay2_confirmation_390x844@3_${mode.name}')}',
        );
      });
    }

    testWidgets('1440x900 @1, confirmation seule, light', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(
        tester,
        adresseDemoComptable(EcranDemoComptable.detailPaiement),
      );
      await _appuyer(tester, find.byKey(DetailPaiementPage.clePayer));
      debugPrint(
        'PNG ${await capturer(tester, 'pay2_confirmation_1440x900@1_light')}',
      );
    });

    testWidgets('320x700 @3 texte x2, confirmation seule', (
      WidgetTester tester,
    ) async {
      _telephone(tester, taille: const Size(320, 700));
      _texteDouble(tester);
      await _monter(
        tester,
        adresseDemoComptable(EcranDemoComptable.detailPaiement),
      );
      await _appuyer(tester, find.byKey(DetailPaiementPage.clePayer));
      debugPrint(
        'PNG ${await capturer(tester, 'pay2_confirmation_320x700@3_texte2')}',
      );
    });

    for (final (Size taille, double densite, String nom) vue
        in <(Size, double, String)>[
          (const Size(390, 844), 3, '390x844@3'),
          (const Size(1440, 900), 1, '1440x900@1'),
        ]) {
      testWidgets('${vue.$3}, preflight du lot', (WidgetTester tester) async {
        if (vue.$2 == 3) {
          _telephone(tester, taille: vue.$1);
        } else {
          fixerVueCapture(tester, vue.$1, vue.$2);
        }
        await _monter(
          tester,
          adresseDemoComptable(EcranDemoComptable.paiements),
        );
        await _appuyer(
          tester,
          find.byKey(PaiementsAEffectuerPage.cleSelectionnerPrets),
        );
        debugPrint(
          'PNG ${await capturer(tester, 'pay2_selection_${vue.$3}_light')}',
        );
        await _appuyer(tester, find.byKey(BarreSelection.clePayer));
        debugPrint('PNG ${await capturer(tester, 'pay2_lot_${vue.$3}_light')}');
      });
    }
  });
}
