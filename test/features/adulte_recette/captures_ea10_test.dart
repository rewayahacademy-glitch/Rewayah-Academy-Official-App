// EA-10 : les captures de la recharge du foyer (planches 4.2 et 4.3), depuis
// la VRAIE route /demo/adulte (`adresseDemoAdulte`), comme
// `captures_ea9_test.dart` : 390x844, 768x1024 et 1440x900, clair et sombre,
// plus le texte a 200 % en 390. Etape 1 (choix) et etape 2 (verification).
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea9_test.dart`).
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
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
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
  if (avant != null) await avant(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de la recharge, titulaire par defaut (etape 1).
String get _adresseRecharge => adresseDemoAdulte(EcranDemoAdulte.recharge);

/// Choisit un beneficiaire et son offre, pour atteindre l'etape 2
/// (« Verifier la recharge ») avant la capture.
Future<void> _taper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _jusquALEtape2(WidgetTester tester) async {
  await _taper(
    tester,
    find.byKey(RechargeFoyerPage.caseDe(DonneesAdulteDemo.mamadouId)),
  );
  await _taper(
    tester,
    find.byKey(
      RechargeFoyerPage.offreDe(DonneesAdulteDemo.mamadouId, 'demo-offre-b'),
    ),
  );
  await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
}

void main() {
  group('Capture : EA-10', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Etape 1, « Nouvelle recharge » : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea10_etape1_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseRecharge,
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 1, en 390.
    testWidgets('ea10_etape1_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea10_etape1_390_light_200pc',
        _adresseRecharge,
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Etape 2, « Verifier la recharge » : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea10_etape2_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseRecharge,
            taille,
            mode: mode,
            avant: _jusquALEtape2,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 2, en 390.
    testWidgets('ea10_etape2_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea10_etape2_390_light_200pc',
        _adresseRecharge,
        const Size(390, 844),
        echelle: 2,
        avant: _jusquALEtape2,
      );
    });
  });
}
