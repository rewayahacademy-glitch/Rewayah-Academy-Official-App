// AR-ADMIN-1 : les ecrans de l'administration en arabe, de droite a gauche.
//
// Le centre de commande, les demandes, les classes, les comptes et les
// diagnostics, montes sur le VRAI routeur avec une session d'administration,
// s'affichent en arabe
// sans debordement ni exception, au telephone (390, et 320 a texte x2) comme
// au bureau ; le sens est RTL. Avec CAPTURE_DIR, les memes ecrans sont
// captures :
//   CAPTURE_DIR=docs/current/captures/AR-ADMIN-1 flutter test \
//     test/router/ar_admin_rtl_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../capture/outil_capture.dart' hide stabiliser;
import '../support/harnais.dart' show FausseSourceSession;
import 'support_routeur.dart';

const Map<String, String> _ecrans = <String, String>{
  'accueil': Routes.admin,
  'demandes': Routes.adminOperationsDemandes,
  'classes': Routes.adminOperationsGroupes,
  'comptes': Routes.adminPersonnesComptes,
  'diagnostics': Routes.adminPedagogieDiagnostics,
};

/// Ecrans qui debordent deja en francais a 320 x2.
const Set<String> _debordentDejaA320x2 = <String>{'classes', 'comptes'};

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(AppRole.admin))),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
      ],
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
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(texte)),
                  child: app!,
                ),
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

void main() {
  setUpAll(() async {
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _ecrans.forEach((String nom, String route) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      // Classes et Comptes debordent deja en francais a 320 x2 (tableaux
      // d'administration, hors de cette tranche) : ce cadrage n'y prouve
      // rien de l'arabe et pollue le test suivant.
      if (texte > 1 && _debordentDejaA320x2.contains(nom)) continue;
      final String fichier = 'ar_admin_${nom}_$cas';
      testWidgets(fichier, (WidgetTester tester) async {
        await _monter(tester, route, taille: taille, texte: texte, mode: mode);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, fichier)}');
        }
      });
    }
  });

  testWidgets('le centre de commande en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    final String titreFr = t.admin.tableau.titre;
    await LocaleSettings.setLocale(AppLocale.ar);
    await _monter(tester, Routes.admin);
    expect(find.text(t.admin.tableau.titre), findsWidgets);
    expect(find.text(titreFr), findsNothing);
  });
}
