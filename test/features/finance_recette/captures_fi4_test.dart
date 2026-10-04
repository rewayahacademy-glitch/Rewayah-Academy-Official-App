// FI-4 : captures du Foyer du tuteur avec ses soldes et paiements (guide
// Finance V4 §5.1, maquette 03), depuis le VRAI routeur et la demonstration
// tuteur branchee sur chacun des six jeux du foyer : 390, 768, 1200 (FI-5b)
// et 1440, clair et sombre, et 390 a texte 200 %.
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
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  JeuFoyerFinance jeu,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoTuteur(environnement: 'staging', finances: jeu),
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
  routeur.go(Routes.tuteurFoyer);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : FI-4 Foyer, soldes et paiements', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 2000)),
        ('768', const Size(768, 1600)),
        ('1200', const Size(1200, 1200)),
        ('1440', const Size(1440, 1200)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'fi4_${jeu.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, jeu, taille, mode: mode);
          });
        }
      }
      final String agrandi = 'fi4_${jeu.name}_390_light_200pc';
      testWidgets(agrandi, (WidgetTester tester) async {
        await _capturer(
          tester,
          agrandi,
          jeu,
          const Size(390, 3200),
          echelle: 2,
        );
      });
    }
  });
}
