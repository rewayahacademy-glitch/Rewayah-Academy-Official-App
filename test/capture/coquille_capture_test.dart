// Captures de recette de la coquille du tuteur (phase 0c2), sur le VRAI
// routeur : barre basse flottante sur telephone, barre laterale depliee sur
// bureau, clair et sombre, et planches contre les maquettes du directeur.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Les
// planches demandent en plus CAPTURE_MAQUETTE_BUREAU (Accueil bureau clair)
// et CAPTURE_MAQUETTE_MOBILE (Mon compte mobile clair). Mode d'emploi :
// `test/capture/LISEZ-MOI.md`.

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

import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

final String? _maquetteBureau = Platform.environment['CAPTURE_MAQUETTE_BUREAU'];
final String? _maquetteMobile = Platform.environment['CAPTURE_MAQUETTE_MOBILE'];

/// Monte l'application sur le vrai routeur, dans le cadre de capture, avec
/// un tuteur actif et le foyer fictif A.
Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = FoyersFictifs.foyerA;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.guardian)),
        appairage: appairage,
      ),
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
}

Future<(int, int)> _taillePx(WidgetTester tester, String chemin) async {
  late int l;
  late int h;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(chemin).readAsBytes(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    l = image.width;
    h = image.height;
    image.dispose();
  });
  return (l, h);
}

void main() {
  group('Capture : coquille du tuteur', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      final double corps = largeurSonde('PlusJakartaSans');
      final double inconnue = largeurSonde('FamilleInexistante');
      expect(corps, lessThan(inconnue * 0.6));
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, String chemin) ecran in <(String, String)>[
        ('accueil', Routes.tuteurAccueil),
        ('compte', Routes.tuteurCompte),
        ('foyer', Routes.tuteurFoyer),
      ]) {
        testWidgets('390x844 @3, ${ecran.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, ecran.$2, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'coquille_${ecran.$1}_390x844@3_${mode.name}')}',
          );
        });
      }

      testWidgets('1440x900 @1, accueil, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, Routes.tuteurAccueil, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'coquille_accueil_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('1024x768 @1, historique, rail replie, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1024, 768), 1);
        await _monter(tester, Routes.tuteurSuivi, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'coquille_historique_1024x768@1_${mode.name}')}',
        );
      });
    }

    testWidgets(
      'planche : Accueil bureau clair contre la maquette',
      skip: _maquetteBureau == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteBureau!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 1440,
        );
        await _monter(tester, Routes.tuteurAccueil);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'coquille_accueil_bureau_contre_maquette', _maquetteBureau!)}',
        );
      },
    );

    testWidgets(
      'planche : Mon compte mobile clair contre la maquette (barre)',
      skip: _maquetteMobile == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteMobile!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monter(tester, Routes.tuteurCompte);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'coquille_compte_mobile_contre_maquette', _maquetteMobile!)}',
        );
      },
    );
  });
}
