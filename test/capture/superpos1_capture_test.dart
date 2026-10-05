// SUPERPOS-1 : captures de preuve, avant et apres (variable `PHASE`, par
// defaut `apres`). Repere « Démonstration » de l'apercu (coque admin), fil
// des echanges du controleur (zone de saisie, clavier ouvert), cahier de
// l'enseignant et observation du controleur (champs multilignes, clavier
// ouvert). 320 x2, 390, 1440 ; clair et sombre ; RTL. Jamais sans
// `CAPTURE_DIR`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

/// Taille, echelle de texte, theme, sens.
typedef _Cas = (Size, double, ThemeMode, TextDirection);

String _suffixe(_Cas c) =>
    '${c.$1.width.toInt()}${c.$2 == 2 ? 'x2' : ''}_'
    '${c.$3 == ThemeMode.light ? 'clair' : 'sombre'}'
    '${c.$4 == TextDirection.rtl ? '_rtl' : ''}';

const List<_Cas> _cas = <_Cas>[
  (Size(320, 640), 2, ThemeMode.light, TextDirection.ltr),
  (Size(320, 640), 2, ThemeMode.dark, TextDirection.rtl),
  (Size(390, 844), 1, ThemeMode.light, TextDirection.ltr),
  (Size(1440, 900), 1, ThemeMode.light, TextDirection.ltr),
];

void _vue(WidgetTester tester, _Cas c, {double clavier = 0}) {
  tester.view.physicalSize = c.$1;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: clavier);
  addTearDown(tester.view.reset);
  if (c.$2 != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = c.$2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

Widget _routeur(GoRouter routeur, _Cas c) => ProviderScope(
  overrides: <Override>[
    depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
  ],
  child: TranslationProvider(
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: c.$3,
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: routeur,
      builder: (BuildContext _, Widget? app) =>
          Directionality(textDirection: c.$4, child: app!),
    ),
  ),
);

Future<void> _stabiliser(WidgetTester tester) async {
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 600));
  await stabiliser(tester);
}

void main() {
  group('Capture : SUPERPOS-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final _Cas c in _cas) {
      final String s = _suffixe(c);

      testWidgets('repere demonstration, coque admin $s', (
        WidgetTester tester,
      ) async {
        _vue(tester, c);
        late GoRouter routeur;
        // `MaterialApp.router` sur le vrai routeur plutot que `RewayahApp` :
        // la persistance des preferences appelle `path_provider`, absent sous
        // `runAsync` (meme choix que `coque_admin_capture_test.dart`).
        await tester.pumpWidget(
          ProviderScope(
            overrides: surchargesDemoAdmin(environnement: 'staging'),
            child: TranslationProvider(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? _) {
                  routeur = ref.read(routeurProvider);
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    darkTheme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.dark,
                    ),
                    themeMode: c.$3,
                    locale: TranslationProvider.of(context).flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    routerConfig: routeur,
                    builder: (BuildContext _, Widget? child) => Directionality(
                      textDirection: c.$4,
                      child: RepereDemonstration(child: child),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(Routes.adminPersonnesDossiers);
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'superpos1_${_phase}_repere_$s')}',
        );
      });

      for (final double clavier in <double>[0, 300]) {
        final String k = clavier == 0 ? '' : '_clavier';
        testWidgets('fil des echanges $s$k', (WidgetTester tester) async {
          _vue(tester, c, clavier: clavier);
          final GoRouter routeur = GoRouter(
            initialLocation: adresseDemoControleur(
              EcranDemoControleur.echanges,
              fil: 'demo-mission-al-badr-0924',
            ),
            routes: routesDemoControleur('dev'),
          );
          await tester.pumpWidget(_routeur(routeur, c));
          await _stabiliser(tester);
          if (clavier > 0) {
            await tester.enterText(
              find.byKey(FilDiscussion.champKey),
              'Merci pour votre retour.\nJe joins le complément demandé.\n'
              'Bonne journée.',
            );
            await _stabiliser(tester);
          }
          debugPrint(
            'PNG ${await capturerVue(tester, 'superpos1_${_phase}_fil_$s$k')}',
          );
        });
      }

      testWidgets('cahier, clavier ouvert $s', (WidgetTester tester) async {
        _vue(tester, c, clavier: 300);
        final GoRouter routeur = GoRouter(
          initialLocation: adresseDemoEnseignant(EcranDemoEnseignant.cahier),
          routes: routesDemoEnseignant('dev'),
        );
        await tester.pumpWidget(_routeur(routeur, c));
        await _stabiliser(tester);
        final Finder champ = find.byType(TextField).first;
        await tester.ensureVisible(champ);
        await tester.enterText(champ, 'Bonne séance.\nRévision à faire.');
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'superpos1_${_phase}_cahier_$s')}',
        );
      });
    }
  });
}
