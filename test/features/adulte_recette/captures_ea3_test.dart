// EA-3 : les captures finales de « Ma classe » de l'eleve adulte. Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a
// l'agent : ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea2_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool pleineHauteur = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
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
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (pleineHauteur) {
    // La vue grandit de ce qui reste a defiler, jusqu'a ce que plus rien ne
    // defile : la page entiere tient dans le PNG, progression comprise.
    for (int i = 0; i < 4; i++) {
      double reste = 0;
      for (final ScrollableState s in tester.stateList<ScrollableState>(
        find.byType(Scrollable),
      )) {
        if (s.position.axis == Axis.vertical &&
            s.position.maxScrollExtent > reste) {
          reste = s.position.maxScrollExtent;
        }
      }
      if (reste <= 0) break;
      fixerVueCapture(
        tester,
        Size(taille.width, tester.view.physicalSize.height + reste),
        1,
      );
      await stabiliser(tester);
    }
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-3', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea3_ma_classe_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(EcranDemoAdulte.maClasse),
            taille,
            mode: mode,
          );
        });
        // La page entiere : participants avec photo (K-44), les trois
        // ressources et la ligne de progression.
        testWidgets('${fichier}_pleine', (WidgetTester tester) async {
          await _capturer(
            tester,
            '${fichier}_pleine',
            adresseDemoAdulte(EcranDemoAdulte.maClasse),
            taille,
            mode: mode,
            pleineHauteur: true,
          );
        });
      }
    }

    testWidgets('ea3_ma_classe_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea3_ma_classe_390_light_200pc',
        adresseDemoAdulte(EcranDemoAdulte.maClasse),
        const Size(390, 844),
        echelle: 2,
      );
    });

    testWidgets('ea3_ma_classe_390_light_200pc_pleine', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea3_ma_classe_390_light_200pc_pleine',
        adresseDemoAdulte(EcranDemoAdulte.maClasse),
        const Size(390, 844),
        echelle: 2,
        pleineHauteur: true,
      );
    });

    // La vue du second adulte : eleve d'une autre Classe, que la
    // demonstration n'a pas ; jamais la Classe du titulaire.
    testWidgets('ea3_ma_classe_390_light_conjoint', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea3_ma_classe_390_light_conjoint',
        adresseDemoAdulte(
          EcranDemoAdulte.maClasse,
          vue: VueDemoAdulte.secondAdulte,
        ),
        const Size(390, 844),
      );
    });
  });
}
