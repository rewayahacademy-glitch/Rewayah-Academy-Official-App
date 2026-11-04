// Captures et mesures de Dossiers a valider refondu (L5 des listes,
// pilote, 02/11/2026 ; DECISION-LISTES-2026-10-23.md §5 quater),
// sur la VRAIE application et le vrai routeur en demonstration
// d'administration : la coque est dans chaque PNG. Classes et enseignants
// fictifs (aucune personne reelle).
// Dossiers d'identite de la demonstration d'administration : la liste, puis
// le dossier ouvert en page (aucun apercu de la piece dans la liste, aucune
// case a cocher, DEC:24).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Les PNG du lot
// sont ranges dans `docs/current/captures/E2E/l5-listes-dossiers/`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
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
  String route = Routes.adminPersonnesDossiers,
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

  group('L5 : captures des dossiers a valider', skip: sautSansCapture, () {
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
      testWidgets('dossiers ${c.$1}', (WidgetTester tester) async {
        await LocaleSettings.setLocale(c.$4);
        tester.platformDispatcher.textScaleFactorTestValue = c.$5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, mode: c.$3);
        debugPrint('MESURE dossiers_${c.$1} ${_mesurer(tester, c.$2)}');
        debugPrint('PNG ${await capturer(tester, 'dossiers_${c.$1}')}');
      });
    }

    // Le dossier ouvert en page, depuis sa ligne : la piece et les
    // verifications n'existent qu'ici.
    for (final (String, Size) c in <(String, Size)>[
      ('1440_dossier_ouvert', b1440),
      ('1366_dossier_ouvert', b1366),
      ('390_dossier_ouvert', tel),
    ]) {
      testWidgets('dossiers ${c.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, mode: ThemeMode.light);
        await tester.tap(
          find.bySemanticsLabel(RegExp("^Ouvrir le dossier d'Omar")),
        );
        await stabiliser(tester);
        debugPrint(
          'DEFILEMENTS dossiers_${c.$1} ${_defilementsVerticaux(tester)}',
        );
        debugPrint('PNG ${await capturer(tester, 'dossiers_${c.$1}')}');
      });
    }
    for (final (String, Size) c in <(String, Size)>[
      ('1440_apres_defilement', b1440),
      ('390_apres_defilement', tel),
    ]) {
      testWidgets('dossiers ${c.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, mode: ThemeMode.light);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -400),
        );
        await stabiliser(tester);
        debugPrint(
          'DEFILEMENTS dossiers_${c.$1} ${_defilementsVerticaux(tester)}',
        );
        debugPrint('PNG ${await capturer(tester, 'dossiers_${c.$1}')}');
      });
    }
  });
}

/// Les lignes de la liste, du haut vers le bas.
List<Rect> _lignes(WidgetTester tester) =>
    find
        .descendant(
          of: find.byType(DataCollection<DossierEnFile>),
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
