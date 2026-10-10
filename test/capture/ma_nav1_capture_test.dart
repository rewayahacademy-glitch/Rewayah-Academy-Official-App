// Captures de recette MA-NAV-1 sur le VRAI routeur : la navigation de l'eleve
// (barre basse, rail, barre laterale), session eleve en Mode Accessibilite
// (enfant) et en standard, clair et sombre, texte x1 et x2, a 320, tablette et
// bureau (1440 x1 et x2). Le prefixe vient de CAPTURE_PREFIX (avant, apres).
//
// Saute sans CAPTURE_DIR. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';

import '../router/support_routeur.dart' show sessionActive, surchargesRouteur;
import '../support/harnais.dart' show FausseSourceSession;
import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIX'] ?? 'apres';

Future<void> _monter(
  WidgetTester tester, {
  required InterfaceMode mode,
  required ThemeMode theme,
  required double echelle,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
        ),
        portAccueilAccessibiliteProvider.overrideWithValue(
          const PortAccueilAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.mariam,
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(mode, Brightness.light),
                darkTheme: AppTheme.pour(mode, Brightness.dark),
                themeMode: theme,
                routerConfig: routeur,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte).copyWith(
                    textScaler: TextScaler.linear(echelle),
                  ),
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
  routeur.go(Routes.eleve);
  await stabiliser(tester);
}

void main() {
  group('Capture : navigation eleve MA-NAV-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.enfant,
      InterfaceMode.standard,
    ]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String nom, Size taille, double echelle) cas
            in <(String, Size, double)>[
              ('320', const Size(320, 640), 1),
              ('320x2', const Size(320, 640), 2),
              ('tablette', const Size(820, 900), 1),
              ('bureau', const Size(1440, 900), 1),
              ('bureaux2', const Size(1440, 900), 2),
            ]) {
          testWidgets('${mode.name} ${theme.name} ${cas.$1}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, cas.$2, 1);
            await _monter(tester, mode: mode, theme: theme, echelle: cas.$3);
            debugPrint(
              'PNG ${await capturer(tester, 'manav1_${_prefixe}_${mode.name}_${theme.name}_${cas.$1}')}',
            );
          });
        }
      }
    }
  });
}
