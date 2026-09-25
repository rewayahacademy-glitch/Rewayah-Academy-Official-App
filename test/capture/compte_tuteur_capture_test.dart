// Captures de recette du Compte du tuteur (lot E, sous-paquet 1), sur le VRAI
// routeur : chaque ecran a 390x844 et 1440x900, clair et sombre, Mon compte
// en pleine hauteur, et les planches maquette | rendu.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Les
// planches demandent en plus les maquettes (recadrees pour la planche V4) :
//   CAPTURE_MAQUETTE_COMPTE_MOBILE, CAPTURE_MAQUETTE_COMPTE_MOBILE_SOMBRE,
//   CAPTURE_MAQUETTE_COMPTE_BUREAU, CAPTURE_MAQUETTE_REGLAGES,
//   CAPTURE_MAQUETTE_APPARENCE.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../features/compte/support_compte.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

String? _env(String nom) {
  final String? v = Platform.environment[nom];
  return v == null || v.trim().isEmpty ? null : v;
}

/// Le foyer A, avec une echeance a venir pour montrer la pastille reelle.
final List<EleveDuFoyer> _eleves = <EleveDuFoyer>[
  FoyersFictifs.a1,
  EleveDuFoyer(
    id: FoyersFictifs.a2.id,
    prenom: FoyersFictifs.a2.prenom,
    identifiantImmuable: FoyersFictifs.a2.identifiantImmuable,
    mode: FoyersFictifs.a2.mode,
    camera: FoyersFictifs.a2.camera,
    finAcces: DateTime.utc(2026, 10, 30, 12),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = _eleves;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        ...surchargesCompte(
          eleves: _eleves,
          acceptations: FauxServiceAcceptations(
            rendues: <Acceptation>[
              Acceptation(
                sorte: SorteContrat.conditionsTuteur,
                version: '2026-09',
                accepteeLe: DateTime(2026, 9, 12, 10),
              ),
            ],
          ),
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
  group('Capture : Compte du tuteur', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    final List<(String, String)> ecrans = <(String, String)>[
      ('compte', Routes.tuteurCompte),
      ('informations', Routes.compteTuteurSousPage('informations')),
      ('securite', Routes.compteTuteurSousPage('securite')),
      ('acces', Routes.compteTuteurSousPage('acces')),
      ('paiements', Routes.compteTuteurSousPage('paiements')),
      ('preferences', Routes.tuteurComptePreferences),
      ('apparence', Routes.tuteurCompteApparence),
      ('aide', Routes.compteTuteurSousPage('aide')),
      (
        'informations_legales',
        Routes.compteTuteurSousPage('informations-legales'),
      ),
    ];

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, String chemin) in ecrans) {
        testWidgets('390x844 @3, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, chemin, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'e_${nom}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, chemin, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'e_${nom}_1440x900@1_${mode.name}')}',
          );
        });
      }

      // Mon compte defile sur telephone : une vue plus haute montre la page
      // entiere (preuve de composition, pas une taille d'ecran reelle).
      testWidgets('390x1900 @2, compte pleine hauteur, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          const Size(390, 1900),
          2,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monter(tester, Routes.tuteurCompte, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'e_compte_390x1900@2_pleine_hauteur_${mode.name}')}',
        );
      });
    }

    // Les planches maquette | rendu, a la taille en pixels de la maquette.
    final List<(String, String?, double, ThemeMode, String, EdgeInsets)>
    planches = <(String, String?, double, ThemeMode, String, EdgeInsets)>[
      (
        'e_planche_compte_mobile_clair',
        _env('CAPTURE_MAQUETTE_COMPTE_MOBILE'),
        390,
        ThemeMode.light,
        Routes.tuteurCompte,
        EdgeInsets.zero,
      ),
      (
        'e_planche_compte_mobile_sombre',
        _env('CAPTURE_MAQUETTE_COMPTE_MOBILE_SOMBRE'),
        390,
        ThemeMode.dark,
        Routes.tuteurCompte,
        EdgeInsets.zero,
      ),
      (
        'e_planche_compte_bureau_clair',
        _env('CAPTURE_MAQUETTE_COMPTE_BUREAU'),
        1440,
        ThemeMode.light,
        Routes.tuteurCompte,
        EdgeInsets.zero,
      ),
      (
        'e_planche_preferences_mobile_sombre',
        _env('CAPTURE_MAQUETTE_REGLAGES'),
        390,
        ThemeMode.dark,
        Routes.tuteurComptePreferences,
        const EdgeInsets.only(top: 47, bottom: 34),
      ),
      (
        'e_planche_apparence_mobile_sombre',
        _env('CAPTURE_MAQUETTE_APPARENCE'),
        390,
        ThemeMode.dark,
        Routes.tuteurCompteApparence,
        const EdgeInsets.only(top: 47, bottom: 34),
      ),
    ];
    for (final (
          String nom,
          String? maquette,
          double largeur,
          ThemeMode mode,
          String chemin,
          EdgeInsets zone,
        )
        in planches) {
      testWidgets('planche : $nom', skip: maquette == null, (
        WidgetTester tester,
      ) async {
        final (int l, int h) = await _taillePx(tester, maquette!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: largeur,
          zoneSure: zone,
        );
        await _monter(tester, chemin, mode: mode);
        debugPrint('PNG ${await capturerEtComparer(tester, nom, maquette)}');
      });
    }
  });
}
