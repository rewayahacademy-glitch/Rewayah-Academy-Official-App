// AR-ENS-1 : les ecrans de l'enseignant en arabe, de droite a gauche.
//
// Chaque ecran de /demo/enseignant (vraie coquille, vraies pages) se monte en
// arabe sans debordement ni exception, au telephone (390, et 320 a texte x2)
// comme au bureau ; le sens est RTL et les libelles sont ceux de l'arabe.
// Avec CAPTURE_DIR, les memes ecrans sont captures :
//   CAPTURE_DIR=docs/current/captures/AR-ENS-1 flutter test \
//     test/features/demo/ar_enseignant_rtl_test.dart

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
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

Future<void> _monter(
  WidgetTester tester,
  EcranDemoEnseignant ecran, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoEnseignant(ecran),
    routes: routesDemoEnseignant('dev'),
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
    titreFr = t.enseignant.cahier.titre;
    if (dossierCapture != null) {
      await chargerPolicesDuDepot();
      // En capture, l'asynchrone reel ouvre la base locale (Aujourd'hui,
      // cahier) : son dossier temporaire est simule, rien n'est persiste.
      final Directory dossier = Directory.systemTemp.createTempSync('ar_ens');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall _) async => dossier.path,
          );
    }
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final EcranDemoEnseignant ecran in EcranDemoEnseignant.values) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      final String nom = 'ar_ens_${ecran.name}_$cas';
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(tester, ecran, taille: taille, texte: texte, mode: mode);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(DemoEnseignantPage))),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, nom)}');
        }
      });
    }
  }

  testWidgets('le cahier de transmission en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    await _monter(tester, EcranDemoEnseignant.cahier);
    expect(find.textContaining(t.enseignant.cahier.titre), findsWidgets);
    expect(t.enseignant.cahier.titre, isNot(titreFr));
    expect(find.textContaining(titreFr), findsNothing);
  });
}
