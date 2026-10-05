// Captures de recette du sous-paquet LA-3 : dossier /attente refondu, texte
// signe (variante observation) et /tuteur/compte/consentements (phase A,
// section A du 05_LOTS_PHASE1.md, sous-paquet 3).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Routeur scope aux
// routes du parcours (meme schema que test/capture/la2_inscription_capture_test.dart
// et test/features/attente_test.dart / consentements_test.dart).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/consentements_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/consentements/consentement_observation_page.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

EtatDossier _etatIncomplet() => const EtatDossier(
  profilExiste: true,
  role: AppRole.guardian,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: false,
  contratSigne: false,
  pieceDeposee: false,
);

double get _largeurLogique =>
    double.tryParse(Platform.environment['CAPTURE_LARGEUR_LOGIQUE'] ?? '') ??
    390;

Future<void> _monter(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String depart,
  List<Override> surcharges = const <Override>[],
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(initialLocation: depart, routes: routes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
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
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

List<RouteBase> _routesAttente() => <RouteBase>[
  GoRoute(
    path: Routes.attente,
    builder: (BuildContext _, GoRouterState _) => const AttentePage(),
  ),
  GoRoute(
    path: Routes.attenteContrat,
    builder: (BuildContext _, GoRouterState _) => const ContratPage(),
  ),
];

List<RouteBase> _routesConsentements() => <RouteBase>[
  GoRoute(
    path: Routes.tuteurCompteConsentements,
    builder: (BuildContext _, GoRouterState _) =>
        const ConsentementObservationPage(),
  ),
];

void main() {
  group('Capture LA-3 : dossier, contrat, consentements', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    // /attente, dossier incomplet.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('attente 390x844, ${mode.name}', (WidgetTester tester) async {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = _etatIncomplet();
        await _monter(
          tester,
          routes: _routesAttente(),
          depart: Routes.attente,
          mode: mode,
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
          ],
        );
        debugPrint('PNG ${await capturer(tester, 'la3_attente_390x844_${mode.name}')}');
      });

      testWidgets('attente 1440x900, ${mode.name}', (WidgetTester tester) async {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = _etatIncomplet();
        await _monter(
          tester,
          routes: _routesAttente(),
          depart: Routes.attente,
          mode: mode,
          taille: const Size(1440, 900),
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
          ],
        );
        debugPrint('PNG ${await capturer(tester, 'la3_attente_1440x900_${mode.name}')}');
      });
    }

    // /attente/contrat, variante responsable legal (aucun brouillon).
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('contrat 390x844, ${mode.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          routes: _routesAttente(),
          depart: Routes.attenteContrat,
          mode: mode,
        );
        debugPrint('PNG ${await capturer(tester, 'la3_contrat_390x844_${mode.name}')}');
      });

      testWidgets('contrat 1440x900, ${mode.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          routes: _routesAttente(),
          depart: Routes.attenteContrat,
          mode: mode,
          taille: const Size(1440, 900),
        );
        debugPrint('PNG ${await capturer(tester, 'la3_contrat_1440x900_${mode.name}')}');
      });
    }

    // /tuteur/compte/consentements, accord non signe (M6, observation).
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('consentements 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxPortConsentements port = FauxPortConsentements()
          ..signeesRendues = <Acceptation>[];
        await _monter(
          tester,
          routes: _routesConsentements(),
          depart: Routes.tuteurCompteConsentements,
          mode: mode,
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        );
        debugPrint('PNG ${await capturer(tester, 'la3_consentements_390x844_${mode.name}')}');
      });

      testWidgets('consentements 1440x900, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxPortConsentements port = FauxPortConsentements()
          ..signeesRendues = <Acceptation>[];
        await _monter(
          tester,
          routes: _routesConsentements(),
          depart: Routes.tuteurCompteConsentements,
          mode: mode,
          taille: const Size(1440, 900),
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        );
        debugPrint('PNG ${await capturer(tester, 'la3_consentements_1440x900_${mode.name}')}');
      });
    }

    // /tuteur/compte/consentements, deja signe (date affichee, pas de case).
    testWidgets('consentements deja signe 390x844, light', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..signeesRendues = <Acceptation>[
          Acceptation(
            sorte: SorteContrat.conditionsTuteur,
            version: 'v-test',
            accepteeLe: DateTime(2026, 9, 4),
          ),
        ];
      await _monter(
        tester,
        routes: _routesConsentements(),
        depart: Routes.tuteurCompteConsentements,
        surcharges: <Override>[
          consentementsLotAProvider.overrideWithValue(port),
        ],
      );
      debugPrint('PNG ${await capturer(tester, 'la3_consentements_signe_390x844_light')}');
    });

    // Planche maquette | capture (M6, observation).
    testWidgets(
      'consentements, maquette | capture (CAPTURE_MAQUETTE_LA3_CONSENTEMENTS)',
      skip: Platform.environment['CAPTURE_MAQUETTE_LA3_CONSENTEMENTS'] == null,
      (WidgetTester tester) async {
        final String chemin =
            Platform.environment['CAPTURE_MAQUETTE_LA3_CONSENTEMENTS']!;
        late final int largeurPx;
        late final int hauteurPx;
        await tester.runAsync(() async {
          final ui.Codec codec = await ui.instantiateImageCodec(
            await File(chemin).readAsBytes(),
          );
          final ui.Image image = (await codec.getNextFrame()).image;
          largeurPx = image.width;
          hauteurPx = image.height;
          image.dispose();
        });
        final FauxPortConsentements port = FauxPortConsentements()
          ..signeesRendues = <Acceptation>[];
        await _monter(
          tester,
          routes: _routesConsentements(),
          depart: Routes.tuteurCompteConsentements,
          taille: Size(_largeurLogique, _largeurLogique * hauteurPx / largeurPx),
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        );
        fixerVueMaquette(
          tester,
          largeurPx: largeurPx,
          hauteurPx: hauteurPx,
          largeurLogique: _largeurLogique,
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'la3_consentements_contre_M6', chemin)}',
        );
      },
    );
  });
}
