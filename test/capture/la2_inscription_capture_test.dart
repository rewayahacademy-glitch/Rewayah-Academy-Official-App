// Captures de recette du sous-paquet LA-2 : inscription par etapes
// (usage, identite, genre, recapitulatif ; phase A, section A du
// 05_LOTS_PHASE1.md, sous-paquet 2).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Route un routeur
// scope aux cinq routes du parcours (meme schema que
// test/features/inscription_test.dart) car /inscription n'est atteignable
// que depuis PorteAcces.inscription sur le vrai routeur, hors perimetre de
// cette capture qui porte sur le contenu des quatre ecrans.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/recapitulatif_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

/// Une source dont le rafraichissement echoue tant qu'on le demande (impasse
/// apres refreshSession, deja corrigee : sert a capturer cet etat).
class _SourceCapricieuse extends FausseSourceSession {
  @override
  Future<void> rafraichir() async {
    rafraichissements++;
    throw StateError('jeton');
  }
}

const Map<String, String?> _maquettesParEcran = <String, String?>{
  'usage': 'CAPTURE_MAQUETTE_LA2_USAGE',
  'identite': null,
  'genre': 'CAPTURE_MAQUETTE_LA2_GENRE',
  'recapitulatif': 'CAPTURE_MAQUETTE_LA2_RECAP',
};

double get _largeurLogique =>
    double.tryParse(Platform.environment['CAPTURE_LARGEUR_LOGIQUE'] ?? '') ??
    390;

Future<GoRouter> _monter(
  WidgetTester tester, {
  required String depart,
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
  FauxServiceDossier? dossier,
  FausseSourceSession? session,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.inscription,
        builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
      ),
      GoRoute(
        path: Routes.inscriptionUsage,
        builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionIdentite,
        builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionGenre,
        builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionRecapitulatif,
        builder: (BuildContext _, GoRouterState _) =>
            const RecapitulatifEtape(),
      ),
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('ATTENTE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceDossierProvider.overrideWithValue(
          dossier ?? FauxServiceDossier(),
        ),
        sourceSessionProvider.overrideWithValue(
          session ?? FausseSourceSession(),
        ),
      ],
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
  return routeur;
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.text(t.commun.continuer));

/// Monte le parcours sur /inscription/usage puis avance par gestes reels
/// jusqu'a l'etape [nom] : une route directe vers identite ou genre est
/// redirigee vers usage par exigerEtapesPrecedentes (brouillon vierge), ce
/// qui produisait des captures de l'ecran usage (constat REVUE LA-F).
Future<GoRouter> _monterEtape(
  WidgetTester tester,
  String nom, {
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
}) async {
  final GoRouter routeur = await _monter(
    tester,
    depart: Routes.inscriptionUsage,
    mode: mode,
    taille: taille,
  );
  if (nom == 'usage') return routeur;
  await _taper(tester, find.byKey(const Key('inscription-usage-moi')));
  await _continuer(tester);
  expect(find.byKey(const Key('inscription-prenom')), findsOneWidget);
  if (nom == 'identite') return routeur;
  await tester.enterText(find.byKey(const Key('inscription-prenom')), 'Amina');
  await tester.enterText(find.byKey(const Key('inscription-nom')), 'Diallo');
  await _continuer(tester);
  expect(find.byKey(const Key('inscription-genre-femme')), findsOneWidget);
  return routeur;
}

void main() {
  group('Capture LA-2 : inscription par etapes', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final String nom in <String>['usage', 'identite', 'genre']) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('$nom 390x844, ${mode.name}', (WidgetTester tester) async {
          await _monterEtape(tester, nom, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'la2_${nom}_390x844_${mode.name}')}',
          );
        });

        testWidgets('$nom 1440x900, ${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monterEtape(
            tester,
            nom,
            mode: mode,
            taille: const Size(1440, 900),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'la2_${nom}_1440x900_${mode.name}')}',
          );
        });
      }

      final String? variable = _maquettesParEcran[nom];
      final String? maquette = variable == null
          ? null
          : Platform.environment[variable];
      testWidgets(
        '$nom, maquette | capture ($variable)',
        skip: maquette == null,
        (WidgetTester tester) async {
          final String chemin = maquette!;
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
          await _monterEtape(
            tester,
            nom,
            taille: Size(
              _largeurLogique,
              _largeurLogique * hauteurPx / largeurPx,
            ),
          );
          fixerVueMaquette(
            tester,
            largeurPx: largeurPx,
            hauteurPx: hauteurPx,
            largeurLogique: _largeurLogique,
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerEtComparer(tester, 'la2_${nom}_contre_maquette', chemin)}',
          );
        },
      );
    }

    // Recapitulatif : atteint en parcourant les trois etapes precedentes
    // (pas de route directe possible sans profil rempli).
    Future<GoRouter> monterJusquAuRecap(
      WidgetTester tester, {
      ThemeMode mode = ThemeMode.light,
      Size taille = const Size(390, 844),
      FauxServiceDossier? dossier,
      FausseSourceSession? session,
    }) async {
      final GoRouter routeur = await _monter(
        tester,
        depart: Routes.inscriptionUsage,
        mode: mode,
        taille: taille,
        dossier: dossier,
        session: session,
      );
      await _taper(tester, find.byKey(const Key('inscription-usage-moi')));
      await _continuer(tester);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const Key('inscription-nom')),
        'Diallo',
      );
      await _continuer(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-genre-femme')),
      );
      await _continuer(tester);
      return routeur;
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('recapitulatif 390x844, ${mode.name}', (
        WidgetTester tester,
      ) async {
        await monterJusquAuRecap(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'la2_recapitulatif_390x844_${mode.name}')}',
        );
      });

      testWidgets('recapitulatif 1440x900, ${mode.name}', (
        WidgetTester tester,
      ) async {
        await monterJusquAuRecap(
          tester,
          mode: mode,
          taille: const Size(1440, 900),
        );
        debugPrint(
          'PNG ${await capturer(tester, 'la2_recapitulatif_1440x900_${mode.name}')}',
        );
      });
    }

    testWidgets(
      'recapitulatif, maquette | capture (CAPTURE_MAQUETTE_LA2_RECAP)',
      skip: Platform.environment['CAPTURE_MAQUETTE_LA2_RECAP'] == null,
      (WidgetTester tester) async {
        final String chemin = Platform.environment['CAPTURE_MAQUETTE_LA2_RECAP']!;
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
        await monterJusquAuRecap(tester);
        fixerVueMaquette(
          tester,
          largeurPx: largeurPx,
          hauteurPx: hauteurPx,
          largeurLogique: _largeurLogique,
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'la2_recapitulatif_contre_maquette', chemin)}',
        );
      },
    );

    // Etat erreur : identite avec le service qui jette (erreur sous les
    // champs). Etat actualisation : recapitulatif apres creation du profil
    // avec une source de session en echec de rafraichissement (impasse
    // corrigee : Reessayer + Se deconnecter restent visibles).
    testWidgets('identite, etat erreur 390x844, light', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, depart: Routes.inscriptionUsage, dossier: dossier);
      await _taper(tester, find.byKey(const Key('inscription-usage-moi')));
      await _continuer(tester);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const Key('inscription-nom')),
        'Diallo',
      );
      dossier.erreurAJeter = null;
      await _continuer(tester);
      await _taper(tester, find.byKey(const Key('inscription-genre-femme')));
      dossier.erreurAJeter = StateError('reseau');
      await _continuer(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'la2_recapitulatif_erreur_390x844_light')}',
      );
    });

    testWidgets('recapitulatif, etat actualisation en echec 390x844, light', (
      WidgetTester tester,
    ) async {
      final _SourceCapricieuse session = _SourceCapricieuse();
      await monterJusquAuRecap(tester, session: session);
      debugPrint(
        'PNG ${await capturer(tester, 'la2_recapitulatif_actualisation_390x844_light')}',
      );
    });
  });
}
