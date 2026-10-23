// AR-ADULTE-1 : les ecrans de l'eleve adulte en arabe, de droite a gauche.
//
// Les ecrans de /demo/adulte (vraie coquille, vraies pages) se montent en
// arabe sans debordement ni exception, au telephone (390, et 320 a texte x2)
// comme au bureau ; le sens est RTL et les libelles sont ceux de l'arabe.
// Avec CAPTURE_DIR, les memes ecrans sont captures :
//   CAPTURE_DIR=docs/current/captures/AR-ADULTE-1 flutter test \
//     test/features/demo/ar_adulte_rtl_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

const List<EcranDemoAdulte> _ecrans = <EcranDemoAdulte>[
  EcranDemoAdulte.accueil,
  EcranDemoAdulte.maClasse,
  EcranDemoAdulte.monEspace,
  EcranDemoAdulte.forfaitFamille,
  EcranDemoAdulte.maFamille,
];

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

Future<void> _monter(
  WidgetTester tester,
  EcranDemoAdulte ecran, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAdulte(ecran),
    routes: routesDemoAdulte('dev'),
  );
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
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(texte)),
                child: app!,
              ),
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late String titreFr;
  setUpAll(() async {
    titreFr = t.adulte.monEspace.monCompte;
    if (dossierCapture != null) {
      await chargerPolicesDuDepot();
      // En capture, l'asynchrone reel ouvre la base locale (Aujourd'hui,
      // cahier) : son dossier temporaire est simule, rien n'est persiste.
      final Directory dossier = Directory.systemTemp.createTempSync(
        'ar_adulte',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall _) async => dossier.path,
          );
    }
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final EcranDemoAdulte ecran in _ecrans) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      final String nom = 'ar_adulte_${ecran.name}_$cas';
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(tester, ecran, taille: taille, texte: texte, mode: mode);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(DemoAdultePage))),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, nom)}');
        }
      });
    }
  }

  testWidgets('Mon espace en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    await _monter(tester, EcranDemoAdulte.monEspace);
    expect(find.textContaining(t.adulte.monEspace.monCompte), findsWidgets);
    expect(t.adulte.monEspace.monCompte, isNot(titreFr));
    expect(find.textContaining(titreFr), findsNothing);
  });
}
