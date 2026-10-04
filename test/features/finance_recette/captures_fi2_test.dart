// FI-2 : captures de la couleur de profil choisie par le tuteur (decision du
// directeur du 04/10/2026, K-62, maquette 11), depuis le VRAI routeur et la
// demonstration tuteur (Aicha en Menthe, Yusuf en Rose) : le Foyer, la fiche
// d'Aicha et sa page « Couleur du profil ». 390x844 et 1440x900, clair et
// sombre, texte a 200 % en 390.
//
// **Jamais execute sans `CAPTURE_DIR`** (`sautSansCapture`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String chemin,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoTuteur(environnement: 'staging'),
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
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: app!,
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(chemin);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : FI-2 couleur de profil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, String)> ecrans = <(String, String)>[
      ('foyer', Routes.tuteurFoyer),
      ('fiche', Routes.ficheElevePour(DonneesDemo.aichaId)),
      ('couleur', Routes.ficheEleveSousPage(DonneesDemo.aichaId, 'couleur')),
    ];
    for (final (String nom, String chemin) in ecrans) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'fi2_${nom}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, chemin, taille, mode: mode);
          });
        }
      }
      final String agrandi = 'fi2_${nom}_390_light_200pc';
      testWidgets(agrandi, (WidgetTester tester) async {
        await _capturer(
          tester,
          agrandi,
          chemin,
          const Size(390, 844),
          echelle: 2,
        );
      });
    }
  });
}
