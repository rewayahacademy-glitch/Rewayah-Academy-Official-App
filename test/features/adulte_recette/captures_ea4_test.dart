// EA-4 : les captures de « Mon espace » de l'eleve adulte. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea3_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390, et les trois
// variantes de la ligne famille.
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
  group('Capture : EA-4', skip: sautSansCapture, () {
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
        final String fichier = 'ea4_mon_espace_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(EcranDemoAdulte.monEspace),
            taille,
            mode: mode,
            pleineHauteur: true,
          );
        });
      }
    }

    // Le texte a 200 % sur la variante la plus longue : adulte seul,
    // « Ajouter ma famille » et sa phrase (comme le test de widget).
    testWidgets('ea4_mon_espace_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea4_mon_espace_390_light_200pc',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        const Size(390, 844),
        echelle: 2,
        pleineHauteur: true,
      );
    });

    // Adulte seul (« Ajouter ma famille » et sa phrase) et second adulte
    // (« Forfait famille »), clair et sombre.
    for (final (String nom, String adresse) in <(String, String)>[
      (
        'adulte_seul',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.adulteSeul,
        ),
      ),
      (
        'conjoint',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          vue: VueDemoAdulte.secondAdulte,
        ),
      ),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea4_mon_espace_390_${mode.name}_$nom';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresse,
            const Size(390, 844),
            mode: mode,
            pleineHauteur: true,
          );
        });
      }
    }

    // Les rubriques ouvertes depuis Mon espace : « Mes accords » (sans
    // source, indisponible) et « Preferences » (la vraie page du Compte).
    for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
      EcranDemoAdulte.accords,
      EcranDemoAdulte.preferences,
    ]) {
      final String fichier = 'ea4_${ecran.name}_390_light';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(ecran),
          const Size(390, 844),
        );
      });
    }
    // « Paiements » : la vraie page, indisponible, rien d'invente.
    testWidgets('ea4_paiements_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea4_paiements_390_light',
        adresseDemoAdulte(EcranDemoAdulte.paiements),
        const Size(390, 844),
      );
    });
  });
}
