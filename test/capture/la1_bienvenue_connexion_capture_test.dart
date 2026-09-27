// Captures de recette du sous-paquet LA-1 : bienvenue, connexion,
// recuperation d'acces (phase A, section A du 05_LOTS_PHASE1.md).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:ui' as ui;

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

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Aucune maquette du directeur ne couvre bienvenue/connexion/recuperation
/// dans les references du lot A (deja constate par la session precedente,
/// etat/B.md) : la variable reste disponible si une maquette est fournie
/// plus tard, mais aucune planche n'est produite par defaut.
final String? _maquette = Platform.environment['CAPTURE_MAQUETTE_LA1'];
final double _largeurLogique =
    double.tryParse(Platform.environment['CAPTURE_LARGEUR_LOGIQUE'] ?? '') ??
    390;

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(FausseSourceSession()),
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
  return routeur;
}

void main() {
  group('Capture LA-1 : bienvenue, connexion, recuperation', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (String nom, String route) in <(String, String)>[
      ('bienvenue', Routes.bienvenue),
      ('connexion', Routes.connexion),
      ('connexion_recuperation', Routes.connexionRecuperation),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        testWidgets('$nom 390x844, ${mode.name}', (WidgetTester tester) async {
          await _monter(tester, route, mode: mode, taille: const Size(390, 844));
          debugPrint(
            'PNG ${await capturer(tester, 'la1_${nom}_390x844_${mode.name}')}',
          );
        });

        testWidgets('$nom 1440x900, ${mode.name}', (WidgetTester tester) async {
          await _monter(tester, route, mode: mode, taille: const Size(1440, 900));
          debugPrint(
            'PNG ${await capturer(tester, 'la1_${nom}_1440x900_${mode.name}')}',
          );
        });
      }

      testWidgets(
        '$nom, maquette | capture (CAPTURE_MAQUETTE_LA1)',
        skip: _maquette == null,
        (WidgetTester tester) async {
          final String maquette = _maquette!;
          late final int largeurPx;
          late final int hauteurPx;
          await tester.runAsync(() async {
            final ui.Codec codec = await ui.instantiateImageCodec(
              await File(maquette).readAsBytes(),
            );
            final ui.Image image = (await codec.getNextFrame()).image;
            largeurPx = image.width;
            hauteurPx = image.height;
            image.dispose();
          });
          final GoRouter routeur = await _monter(
            tester,
            route,
            taille: Size(_largeurLogique, _largeurLogique * hauteurPx / largeurPx),
          );
          fixerVueMaquette(
            tester,
            largeurPx: largeurPx,
            hauteurPx: hauteurPx,
            largeurLogique: _largeurLogique,
          );
          routeur.go(route);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerEtComparer(tester, 'la1_${nom}_contre_maquette', maquette)}',
          );
        },
      );
    }
  });
}
