// EA-9 : les captures de Paiements du foyer (planche 4.1 et colonne droite
// de 6), depuis la VRAIE route /demo/adulte (`adresseDemoAdulte`), comme
// `captures_ea8_test.dart` : 390x844, 768x1024 et 1440x900, clair et sombre,
// plus le texte a 200 % en 390.
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea8_test.dart`).
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
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de Paiements du foyer, titulaire par defaut.
String get _adressePaiements =>
    adresseDemoAdulte(EcranDemoAdulte.paiementsFoyer);

/// Adresse de Paiements du foyer, second adulte (historique seul, E3, F7).
String get _adresseSecondAdulte => adresseDemoAdulte(
  EcranDemoAdulte.paiementsFoyer,
  vue: VueDemoAdulte.secondAdulte,
);

/// Adresse de Ma famille sur bureau (planche 6, colonne droite).
String get _adresseMaFamille => adresseDemoAdulte(EcranDemoAdulte.maFamille);

void main() {
  group('Capture : EA-9', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Paiements du foyer, titulaire : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea9_paiements_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adressePaiements,
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur Paiements du foyer, en 390.
    testWidgets('ea9_paiements_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea9_paiements_390_light_200pc',
        _adressePaiements,
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Vue du second adulte : historique seul (E3, F7) : 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea9_second_adulte_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea9_second_adulte_390_${mode.name}',
          _adresseSecondAdulte,
          const Size(390, 844),
          mode: mode,
        );
      });
    }

    // Ma famille sur bureau : la colonne droite porte la section (planche
    // 6) : 1440, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea9_ma_famille_bureau_1440_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea9_ma_famille_bureau_1440_${mode.name}',
          _adresseMaFamille,
          const Size(1440, 900),
          mode: mode,
        );
      });
    }
  });
}
