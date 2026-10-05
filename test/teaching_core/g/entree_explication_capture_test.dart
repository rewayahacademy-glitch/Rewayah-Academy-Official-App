// Captures de recette du lot O, sous-paquet 1 (entree et explication) :
// 390x844 et 1440x900, clair et sombre, tablette 1024x768, les etats, et la
// planche maquette V8 M2 | rendu.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Planche :
// CAPTURE_MAQUETTE_M2 (M2 decoupee de la planche mobile, 390 logiques).
// Donnees : doubles isoles de `test/teaching_core/g/faux`, jamais un service
// reel.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/verification_prealable.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart' show FauxServicePresence;
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

final String? _maquetteM2 = Platform.environment['CAPTURE_MAQUETTE_M2'];

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// L'adresse de la porte, comme la classe l'ouvre.
final String _porte = cheminObservation(
  's1',
  classeId: 'c1',
  eleveId: 'enfant-1',
);

/// Monte la porte d'observation sous le vrai theme, dans le cadre capture.
Future<void> _monter(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  FauxPortVisite? visites,
  FauxPortPolitique? politique,
  FauxServicePresence? presence,
  StockagePreferences? stockage,
  bool observationReelle = true,
  bool horsLigne = false,
  bool geste = false,
}) async {
  final FauxPortPolitique ports = politique ?? FauxPortPolitique();
  addTearDown(ports.fermer);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: visites,
        politique: ports,
        presence: presence,
        stockage: stockage,
        observationReelle: observationReelle,
        horsLigne: horsLigne,
      ),
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
              routerConfig: GoRouter(
                initialLocation: _porte,
                initialExtra: geste ? const DemandeEntreeObservation() : null,
                routes: <RouteBase>[
                  GoRoute(
                    path: '${Routes.tuteurClasses}/:classeId',
                    builder: (BuildContext _, GoRouterState _) =>
                        const Text('CLASSE'),
                  ),
                  ...routesTcG(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// La memoire « explication deja lue » du compte de test.
StockagePreferencesMemoire _dejaLue() => StockagePreferencesMemoire(
  <String, String>{clefExplicationVue('p1'): 'oui'},
);

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

Future<void> _capturer(WidgetTester tester, String nom) async =>
    debugPrint('PNG ${await capturer(tester, nom)}');

void main() {
  group(
    'Capture : entree et explication de l\'observation',
    skip: sautSansCapture,
    () {
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

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('explication 390x844 @3, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
          await _monter(tester, mode: mode);
          await _capturer(tester, 'o1_explication_390x844@3_${mode.name}');
        });

        testWidgets('explication 390x1100 @2, page entiere, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 1100),
            2,
            zoneSure: _zoneSure,
          );
          await _monter(tester, mode: mode);
          await _capturer(
            tester,
            'o1_explication_390x1100@2_page_entiere_${mode.name}',
          );
        });

        testWidgets('explication 1440x900 @1, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, mode: mode);
          await _capturer(tester, 'o1_explication_1440x900@1_${mode.name}');
        });

        testWidgets('connexion et verification 390x844 @3, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
          final FauxPortVisite visites = FauxPortVisite()
            ..entreeSuspendue = Completer<void>();
          await _monter(
            tester,
            mode: mode,
            visites: visites,
            stockage: _dejaLue(),
            geste: true,
          );
          await _capturer(tester, 'o1_connexion_390x844@3_${mode.name}');
          visites.entreeSuspendue!.complete();
          await stabiliser(tester);
        });

        testWidgets('connexion et verification 1440x900 @1, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          final FauxPortVisite visites = FauxPortVisite()
            ..entreeSuspendue = Completer<void>();
          await _monter(
            tester,
            mode: mode,
            visites: visites,
            stockage: _dejaLue(),
            geste: true,
          );
          await _capturer(tester, 'o1_connexion_1440x900@1_${mode.name}');
          visites.entreeSuspendue!.complete();
          await stabiliser(tester);
        });
      }

      testWidgets('explication 1024x768 @1, tablette', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1024, 768), 1);
        await _monter(tester);
        await _capturer(tester, 'o1_explication_1024x768@1_light');
      });

      testWidgets('deuxieme visite : une restante, 390x1100 @2', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 1100), 2, zoneSure: _zoneSure);
        await _monter(
          tester,
          politique: FauxPortPolitique()
            ..dernierBudget = unBudget(
              visitesUtilisees: 1,
              visitesMax: 2,
              total: const Duration(seconds: 240),
            ),
        );
        await _capturer(tester, 'o1_deuxieme_visite_390x1100@2_light');
      });

      testWidgets('explication, visites epuisees : le motif a la place de '
          'l\'action, 390x1100 @2', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 1100), 2, zoneSure: _zoneSure);
        await _monter(
          tester,
          politique: FauxPortPolitique()
            ..dernierBudget = unBudget(
              visitesUtilisees: 2,
              visitesMax: 2,
              total: const Duration(seconds: 240),
              restant: Duration.zero,
              peutEntrer: false,
              motifRefus: MotifRefusObservation.quotaVisitesAtteint,
            ),
        );
        await _capturer(tester, 'o1_visites_epuisees_390x1100@2_light');
      });

      testWidgets('presence en verification, 390x844 @3', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          presence: FauxServicePresence(
            lignes: <PresenceParticipant>[
              presenceDe(etat: EtatPresence.enConnexion),
            ],
          ),
          stockage: _dejaLue(),
          geste: true,
        );
        await _capturer(tester, 'o1_presence_verification_390x844@3_light');
      });

      testWidgets('observation pas encore ouverte (P3), 390x844 @3', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, observationReelle: false);
        await _capturer(tester, 'o1_pas_ouverte_390x844@3_light');
      });

      testWidgets('erreur du serveur, 390x844 @3', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          politique: FauxPortPolitique()
            ..echecBudget = const EchecObservation(
              MotifEchecObservation.reseau,
            ),
        );
        await _capturer(tester, 'o1_erreur_390x844@3_light');
      });

      testWidgets('hors ligne, 390x844 @3', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          horsLigne: true,
          politique: FauxPortPolitique()
            ..echecBudget = const EchecObservation(
              MotifEchecObservation.reseau,
            ),
        );
        await _capturer(tester, 'o1_hors_ligne_390x844@3_light');
      });

      testWidgets('chargement, 390x844 @3', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        final FauxPortPolitique politique = FauxPortPolitique()
          ..budgetSuspendu = Completer<void>();
        await _monter(tester, politique: politique);
        await _capturer(tester, 'o1_chargement_390x844@3_light');
        politique.budgetSuspendu!.complete();
        await stabiliser(tester);
      });

      testWidgets('connexion prolongee, 390x844 @3', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        final FauxPortVisite visites = FauxPortVisite()
          ..entreeSuspendue = Completer<void>();
        await _monter(
          tester,
          visites: visites,
          stockage: _dejaLue(),
          geste: true,
        );
        await tester.pump(AppDelais.chargementProlonge);
        await stabiliser(tester);
        await _capturer(tester, 'o1_connexion_prolongee_390x844@3_light');
        visites.entreeSuspendue!.complete();
        await stabiliser(tester);
      });

      testWidgets('connexion impossible, 390x844 @3', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          visites: FauxPortVisite(
            echecEntree: const EchecObservation(MotifEchecObservation.reseau),
          ),
          stockage: _dejaLue(),
          geste: true,
        );
        await _capturer(tester, 'o1_connexion_impossible_390x844@3_light');
      });

      testWidgets(
        'planche : explication mobile claire contre la maquette V8 M2',
        skip: _maquetteM2 == null,
        (WidgetTester tester) async {
          final (int l, int h) = await _taillePx(tester, _maquetteM2!);
          fixerVueMaquette(
            tester,
            largeurPx: l,
            hauteurPx: h,
            largeurLogique: 390,
            zoneSure: const EdgeInsets.only(top: 24),
          );
          await _monter(tester);
          debugPrint(
            'PNG ${await capturerEtComparer(tester, 'o1_explication_mobile_contre_maquette_M2', _maquetteM2!)}',
          );
        },
      );
    },
  );
}
