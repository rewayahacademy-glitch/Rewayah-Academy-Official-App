// Captures et mesures de la liste Operations > Classes refondue (L1 des
// listes, directeur, 01/11/2026 ; DECISION-LISTES-2026-10-23.md §5 quater),
// sur la VRAIE application et le vrai routeur en demonstration
// d'administration : la coque est dans chaque PNG. Classes et enseignants
// fictifs (aucune personne reelle).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Les PNG du lot
// sont ranges dans `docs/current/captures/E2E/fn113-listes-classes/`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester, {
  required ThemeMode mode,
  String route = Routes.adminOperationsGroupes,
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
  routeur.go(route);
  await stabiliser(tester);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('L1 : captures de la liste des classes', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    const Size b1440 = Size(1440, 900);
    const Size b1366 = Size(1366, 768);
    const Size tel = Size(390, 844);
    for (final (String, Size, ThemeMode, AppLocale, double) c
        in <(String, Size, ThemeMode, AppLocale, double)>[
          ('1440_clair', b1440, ThemeMode.light, AppLocale.fr, 1),
          ('1440_sombre', b1440, ThemeMode.dark, AppLocale.fr, 1),
          ('1366_clair', b1366, ThemeMode.light, AppLocale.fr, 1),
          ('1440_ar', b1440, ThemeMode.light, AppLocale.ar, 1),
          ('1440_texte_x2', b1440, ThemeMode.light, AppLocale.fr, 2),
          ('390_clair', tel, ThemeMode.light, AppLocale.fr, 1),
          ('390_sombre', tel, ThemeMode.dark, AppLocale.fr, 1),
          ('390_ar', tel, ThemeMode.light, AppLocale.ar, 1),
          ('390_texte_x2', tel, ThemeMode.light, AppLocale.fr, 2),
        ]) {
      testWidgets('classes ${c.$1}', (WidgetTester tester) async {
        await LocaleSettings.setLocale(c.$4);
        tester.platformDispatcher.textScaleFactorTestValue = c.$5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, mode: c.$3);
        debugPrint('MESURE classes_${c.$1} ${_mesurer(tester, c.$2)}');
        debugPrint('PNG ${await capturer(tester, 'classes_${c.$1}')}');
      });
    }

    // Le panneau des filtres deplie (bureau), puis la page apres defilement :
    // seules la barre de l'application et la rangee d'en-tetes restent.
    testWidgets('classes 1440_filtres_ouverts', (WidgetTester tester) async {
      fixerVueCapture(tester, b1440, 1);
      await _monter(tester, mode: ThemeMode.light);
      await tester.tap(
        find.byKey(const ValueKey<String>('classes-bascule-filtres')),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'classes_1440_filtres_ouverts')}',
      );
    });
    for (final (String, Size) c in <(String, Size)>[
      ('1440_apres_defilement', b1440),
      ('390_apres_defilement', tel),
    ]) {
      testWidgets('classes ${c.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, mode: ThemeMode.light);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -400),
        );
        await stabiliser(tester);
        debugPrint(
          'DEFILEMENTS classes_${c.$1} ${_defilementsVerticaux(tester)}',
        );
        debugPrint('PNG ${await capturer(tester, 'classes_${c.$1}')}');
      });
    }
  });
}

/// Les lignes de la liste, du haut vers le bas.
List<Rect> _lignes(WidgetTester tester) =>
    find
        .descendant(
          of: find.byType(DataCollection<ClasseListee>),
          matching: find.byWidgetPredicate(
            (Widget w) => w is KeyedSubtree && w.key is ValueKey<String>,
          ),
        )
        .evaluate()
        .map((Element e) => tester.getRect(find.byWidget(e.widget)))
        .toList()
      ..sort((Rect a, Rect b) => a.top.compareTo(b.top));

/// Le haut de la premiere ligne et le nombre de lignes entieres visibles sans
/// defiler, en points logiques, plus le nombre de defilements verticaux.
String _mesurer(WidgetTester tester, Size vue) {
  final List<Rect> lignes = _lignes(tester);
  if (lignes.isEmpty) return 'aucune ligne';
  final int entieres = lignes
      .where((Rect r) => r.top >= 0 && r.bottom <= vue.height)
      .length;
  return 'premiere ligne y=${lignes.first.top.toStringAsFixed(0)}, '
      'hauteur=${lignes.first.height.toStringAsFixed(0)}, '
      'lignes entieres visibles=$entieres, '
      '${_defilementsVerticaux(tester)}';
}

/// DECISION-DEFILEMENT-2026-11-01 : une seule barre de defilement par ecran.
/// Compte les zones qui defilent verticalement ET debordent.
String _defilementsVerticaux(WidgetTester tester) {
  int n = 0;
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    final ScrollPosition p = etat.position;
    if (etat.axisDirection == AxisDirection.down ||
        etat.axisDirection == AxisDirection.up) {
      if (p.hasContentDimensions && p.maxScrollExtent > 0) n++;
    }
  }
  return 'defilements verticaux qui debordent=$n';
}
