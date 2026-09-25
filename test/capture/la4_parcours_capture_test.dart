// Captures de recette du sous-paquet LA-4 : questionnaire par eleve
// /tuteur/parcours/:eleveId (phase A, section A du 05_LOTS_PHASE1.md,
// sous-paquet 4).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Meme schema que
// test/capture/la3_dossier_capture_test.dart.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/schedule_option.dart';
import 'package:rewayah_academy/features/parcours_offres/bloc_parcours.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../parcours/faux_service_offres.dart';
import 'outil_capture.dart';

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

List<RouteBase> _routesParcours() => <RouteBase>[
  GoRoute(
    path: Routes.tuteurAccueil,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: SingleChildScrollView(child: BlocParcours())),
  ),
  GoRoute(
    path: '${Routes.tuteurParcours}/:eleveId',
    builder: (BuildContext _, GoRouterState etat) =>
        ParcoursOffresPage(eleveId: etat.pathParameters['eleveId'] ?? ''),
  ),
  GoRoute(
    path: Routes.tuteurFoyer,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: Center(child: Text('Foyer'))),
  ),
  GoRoute(
    path: Routes.tuteurAjouterEnfant,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: Center(child: Text('Ajouter un profil eleve'))),
  ),
];

void main() {
  group('Capture LA-4 : questionnaire par eleve', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      // Le bloc de l'accueil qui mene au parcours.
      testWidgets('bloc accueil 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: Routes.tuteurAccueil,
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_bloc_accueil_390x844_${mode.name}')}',
        );
      });

      // Chargement : squelette avant la premiere reponse du foyer.
      testWidgets('chargement 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres()
          ..attenteParcours = Completer<void>();
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_chargement_390x844_${mode.name}')}',
        );
      });

      // Contenu : premiere question (age), prenom en contexte.
      testWidgets('question age 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_question_age_390x844_${mode.name}')}',
        );
      });

      testWidgets('question age 1440x900, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          taille: const Size(1440, 900),
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_question_age_1440x900_${mode.name}')}',
        );
      });

      // Horaires : profil rempli, ouvre directement le choix.
      testWidgets('offres 390x844, ${mode.name}', (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[
            apprenantDeTest(
              cohorte: 'enfant_8_10',
              langue: 'francais',
              onboardingFaitLe: DateTime(2026, 9, 20, 10),
            ),
          ],
          offresRendues: <OffreHoraire>[offreDeTest()],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        expect(find.byType(ScheduleOption), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'la4_offres_390x844_${mode.name}')}',
        );
      });

      // Fin d'admission : statut de diagnostic rendu par le serveur.
      testWidgets('fin admission 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[
            apprenantDeTest(
              cohorte: 'enfant_8_10',
              langue: 'francais',
              onboardingFaitLe: DateTime(2026, 9, 20, 10),
              intention: EtatIntention.enregistree,
            ),
          ],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_fin_admission_390x844_${mode.name}')}',
        );
      });

      // Indisponible honnete : backend 0043 non applique (PGRST205).
      testWidgets('indisponible 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres()
          ..erreurParcours = const PostgrestException(
            message: 'relation inconnue',
            code: 'PGRST205',
          );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_indisponible_390x844_${mode.name}')}',
        );
      });

      // Hors ligne : reseau qui ne repond pas.
      testWidgets('hors ligne 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres()
          ..erreurParcours = Exception('Failed host lookup');
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_hors_ligne_390x844_${mode.name}')}',
        );
      });

      // Erreur : toute autre panne, avec Reessayer.
      testWidgets('erreur 390x844, ${mode.name}', (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres()
          ..erreurParcours = Exception('panne inattendue');
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_erreur_390x844_${mode.name}')}',
        );
      });

      // Profil introuvable ("vide") : eleve absent du foyer, retour au Foyer.
      testWidgets('profil introuvable 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: const <ParcoursApprenant>[],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/introuvable',
          mode: mode,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la4_introuvable_390x844_${mode.name}')}',
        );
      });
    }

    // Planches maquette | capture (onboarding mobile, gabarit question/carte).
    testWidgets(
      'question age, maquette | capture (CAPTURE_MAQUETTE_LA4_AGE)',
      skip: Platform.environment['CAPTURE_MAQUETTE_LA4_AGE'] == null,
      (WidgetTester tester) async {
        final String chemin = Platform.environment['CAPTURE_MAQUETTE_LA4_AGE']!;
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        );
        await _monter(
          tester,
          routes: _routesParcours(),
          depart: '${Routes.tuteurParcours}/e1',
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'la4_age_contre_maquette', chemin)}',
        );
      },
    );
  });
}
