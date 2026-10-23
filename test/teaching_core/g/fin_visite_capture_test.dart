// Captures de recette du lot O, sous-paquet 3 (fins de visite et etats) :
// 390x844 et 1440x900, clair et sombre, les variantes (duree atteinte, fin de
// seance, visites epuisees, interrompue, visites restantes illisibles, texte a
// 200 %), et la planche maquette V8 M5 | rendu.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Planche :
// CAPTURE_MAQUETTE_M5 (390 logiques). Donnees : doubles isoles de
// `test/teaching_core/g/faux`, jamais un service reel.

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
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/verification_prealable.dart';

import '../../capture/outil_capture.dart';
import '../e/faux/faux_classe.dart'
    show FauxMoteurClasse, FauxServiceVideoClasse, accesDe, participantDe;
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

final String? _maquetteM5 = Platform.environment['CAPTURE_MAQUETTE_M5'];

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

final String _porte = cheminObservation(
  's1',
  classeId: 'c1',
  eleveId: 'enfant-1',
);

ResultatEntreeObservation _entree({int rang = 1, int utilisees = 1}) =>
    ResultatEntreeObservation(
      autorise: true,
      visite: uneVisite(visitNumber: rang),
      budget: unBudget(
        restant: const Duration(seconds: 102),
        visitesUtilisees: utilisees,
        visitesMax: 2,
        total: const Duration(seconds: 240),
      ),
    );

class _Salle {
  _Salle(this.politique, this.moteur);

  final FauxPortPolitique politique;
  final FauxMoteurClasse moteur;
}

/// Monte la salle (geste de la classe, explication deja lue), l'enfant et
/// l'enseignant presents.
Future<_Salle> _monterSalle(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  ResultatEntreeObservation? reponse,
  double echelleTexte = 1,
}) async {
  final FauxPortPolitique politique = FauxPortPolitique();
  addTearDown(politique.fermer);
  final FauxMoteurClasse moteur = FauxMoteurClasse();
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: FauxPortVisite(reponse: reponse ?? _entree()),
        politique: politique,
        moteur: moteur,
        video: FauxServiceVideoClasse(acces0: accesDe('guardian_observer')),
        stockage: StockagePreferencesMemoire(<String, String>{
          clefExplicationVue('p1'): 'oui',
        }),
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
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelleTexte)),
                child: enfant!,
              ),
              routerConfig: GoRouter(
                initialLocation: _porte,
                initialExtra: const DemandeEntreeObservation(),
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
  moteur.publier(<ParticipantSalle>[
    participantDe(identite: 'prof-1', role: 'teacher', nom: 'Amina'),
    participantDe(identite: 'enfant-1', role: 'student', nom: 'Mariam'),
  ]);
  await stabiliser(tester);
  return _Salle(politique, moteur);
}

Future<void> _laisserFinir(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await stabiliser(tester);
}

/// Quitter, confirmer : la fin de visite.
Future<void> _quitter(WidgetTester tester) async {
  await tester.tap(find.text(t.tc.observation.visite.quitter));
  await stabiliser(tester);
  await tester.tap(find.text(t.tc.observation.visite.quitterConfirmer));
  await _laisserFinir(tester);
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

Future<void> _capturer(WidgetTester tester, String nom) async =>
    debugPrint('PNG ${await capturer(tester, nom)}');

void main() {
  group('Capture : fin de visite', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('fin 390x844 @3, ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        final _Salle salle = await _monterSalle(tester, mode: mode);
        salle.politique.dernierBudget = unBudget(
          visitesUtilisees: 1,
          visitesMax: 2,
          total: const Duration(seconds: 240),
        );
        await _quitter(tester);
        await _capturer(tester, 'o3_fin_390x844@3_${mode.name}');
      });

      testWidgets('fin 1440x900 @1, ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        final _Salle salle = await _monterSalle(tester, mode: mode);
        salle.politique.dernierBudget = unBudget(
          visitesUtilisees: 1,
          visitesMax: 2,
          total: const Duration(seconds: 240),
        );
        await _quitter(tester);
        await _capturer(tester, 'o3_fin_1440x900@1_${mode.name}');
      });
    }

    testWidgets('duree atteinte 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(tester);
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 1,
        visitesMax: 2,
        total: const Duration(seconds: 240),
      );
      salle.politique.flux.add(
        unBudget(restant: Duration.zero, peutEntrer: false),
      );
      await _laisserFinir(tester);
      await _capturer(tester, 'o3_duree_atteinte_390x844@3_light');
    });

    testWidgets('fin de seance 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(tester);
      salle.politique.flux.add(
        unBudget(
          restant: const Duration(seconds: 90),
          peutEntrer: false,
          motifRefus: MotifRefusObservation.seanceNonActive,
        ),
      );
      await _laisserFinir(tester);
      await _capturer(tester, 'o3_fin_seance_390x844@3_light');
    });

    testWidgets('visites epuisees 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(
        tester,
        reponse: _entree(rang: 2, utilisees: 2),
      );
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 2,
        visitesMax: 2,
        peutEntrer: false,
        total: const Duration(seconds: 240),
      );
      await _quitter(tester);
      await _capturer(tester, 'o3_visites_epuisees_390x844@3_light');
    });

    testWidgets('interrompue 390x844 @3, clair et 1440 sombre', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(tester);
      salle.moteur.poser(EtatSalle.reconnexion);
      await stabiliser(tester);
      salle.moteur.poser(EtatSalle.echec);
      await _laisserFinir(tester);
      await _capturer(tester, 'o3_interrompue_390x844@3_light');
    });

    testWidgets('interrompue 1440x900 @1 sombre', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      final _Salle salle = await _monterSalle(tester, mode: ThemeMode.dark);
      salle.moteur.poser(EtatSalle.echec);
      await _laisserFinir(tester);
      await _capturer(tester, 'o3_interrompue_1440x900@1_dark');
    });

    testWidgets('visites restantes illisibles 390x844 @3', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(tester);
      salle.politique.echecBudget = const EchecObservation(
        MotifEchecObservation.reseau,
      );
      await _quitter(tester);
      await _capturer(tester, 'o3_restantes_inconnues_390x844@3_light');
    });

    testWidgets('texte a 200 % 390x844 @2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 2, zoneSure: _zoneSure);
      final _Salle salle = await _monterSalle(tester, echelleTexte: 2);
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 1,
        visitesMax: 2,
        total: const Duration(seconds: 240),
      );
      await _quitter(tester);
      await _capturer(tester, 'o3_texte200_390x844@2_light');
    });

    testWidgets(
      'planche : fin de visite contre la maquette V8 M5',
      skip: _maquetteM5 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM5!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: const EdgeInsets.only(top: 24),
        );
        final _Salle salle = await _monterSalle(tester);
        salle.politique.dernierBudget = unBudget(
          visitesUtilisees: 1,
          visitesMax: 2,
          total: const Duration(seconds: 240),
        );
        await _quitter(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'o3_fin_mobile_contre_maquette_M5', _maquetteM5!)}',
        );
      },
    );
  });
}
