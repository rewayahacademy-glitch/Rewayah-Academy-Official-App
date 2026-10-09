// SUPERPOS-1, reprise du relecteur : captures de preuve, avant (tete de la
// branche avant la reprise, 2b42d97d) et apres (variable `PHASE`, par defaut
// `apres`). En-tete compact (« Dossiers a valider », fil des echanges), fil a
// l'arrivee, Interface guidee (fil, demande des reglages de l'enfant),
// lecteur du Coran du Mode Accessibilite avec lecteur d'ecran, aides et
// erreurs de l'invitation du conjoint. Jamais sans `CAPTURE_DIR`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../support/harnais.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

String _nom(String quoi) => 'superpos1r_${_phase}_$quoi';

void _vue(WidgetTester tester, Size taille, double echelle) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (echelle != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = echelle;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

Widget _app({
  required Widget home,
  InterfaceMode mode = InterfaceMode.standard,
  ThemeMode theme = ThemeMode.light,
  TextDirection sens = TextDirection.ltr,
  List<Override> surcharges = const <Override>[],
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(mode, Brightness.light),
      darkTheme: AppTheme.pour(mode, Brightness.dark),
      themeMode: theme,
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext _, Widget? app) =>
          Directionality(textDirection: sens, child: app!),
      home: home,
    ),
  ),
);

Future<void> _stabiliser(WidgetTester tester) async {
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 600));
  await stabiliser(tester);
}

void main() {
  group('Capture : SUPERPOS-1, reprise', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });
    setUp(masquerRubanDebug);

    // En-tete « Dossiers a valider » (coque admin, apercu).
    for (final (ThemeMode, TextDirection, String) c
        in <(ThemeMode, TextDirection, String)>[
          (ThemeMode.light, TextDirection.ltr, 'clair'),
          (ThemeMode.dark, TextDirection.rtl, 'sombre_rtl'),
        ]) {
      testWidgets('en-tete dossiers 320x2 ${c.$3}', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(320, 640), 2);
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: surchargesDemoAdmin(environnement: 'staging'),
            child: TranslationProvider(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? _) {
                  routeur = ref.read(routeurProvider);
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    darkTheme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.dark,
                    ),
                    themeMode: c.$1,
                    locale: TranslationProvider.of(context).flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    routerConfig: routeur,
                    builder: (BuildContext _, Widget? child) => Directionality(
                      textDirection: c.$2,
                      child: RepereDemonstration(child: child),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(Routes.adminPersonnesDossiers);
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('dossiers_320x2_${c.$3}'))}',
        );
      });
    }

    // Le fil des echanges a l'arrivee.
    for (final (Size, double, ThemeMode, TextDirection, InterfaceMode, String) c
        in const <
          (Size, double, ThemeMode, TextDirection, InterfaceMode, String)
        >[
          (
            Size(320, 640),
            2,
            ThemeMode.light,
            TextDirection.ltr,
            InterfaceMode.standard,
            '320x2_clair',
          ),
          (
            Size(320, 640),
            2,
            ThemeMode.dark,
            TextDirection.rtl,
            InterfaceMode.standard,
            '320x2_sombre_rtl',
          ),
          (
            Size(390, 844),
            1,
            ThemeMode.light,
            TextDirection.ltr,
            InterfaceMode.standard,
            '390_clair',
          ),
          (
            Size(1440, 900),
            1,
            ThemeMode.light,
            TextDirection.ltr,
            InterfaceMode.standard,
            '1440_clair',
          ),
          (
            Size(320, 640),
            2,
            ThemeMode.light,
            TextDirection.ltr,
            InterfaceMode.enfant,
            '320x2_guidee',
          ),
        ]) {
      testWidgets('fil des echanges ${c.$6}', (WidgetTester tester) async {
        _vue(tester, c.$1, c.$2);
        final GoRouter routeur = GoRouter(
          initialLocation: adresseDemoControleur(
            EcranDemoControleur.echanges,
            fil: 'demo-mission-al-badr-0924',
          ),
          routes: routesDemoControleur('dev'),
        );
        addTearDown(routeur.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(c.$5, Brightness.light),
                darkTheme: AppTheme.pour(c.$5, Brightness.dark),
                themeMode: c.$3,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext _, Widget? app) =>
                    Directionality(textDirection: c.$4, child: app!),
              ),
            ),
          ),
        );
        await _stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, _nom('fil_${c.$6}'))}');
      });
    }

    // Interface guidee, activee par un adulte : la demande des reglages de
    // l'enfant (zone de saisie partagee).
    for (final (Size, double, String) c in <(Size, double, String)>[
      (const Size(320, 640), 2, '320x2'),
      (const Size(390, 844), 1, '390'),
    ]) {
      testWidgets('reglages de l\'enfant, Interface guidee ${c.$3}', (
        WidgetTester tester,
      ) async {
        _vue(tester, c.$1, c.$2);
        await tester.pumpWidget(
          _app(
            mode: InterfaceMode.enfant,
            home: const ReglagesEnfantPage(),
            surcharges: <Override>[
              serviceAppairageProvider.overrideWithValue(
                FauxServiceAppairage()
                  ..elevesRendus = <EleveDuFoyer>[
                    const EleveDuFoyer(
                      id: 'e1',
                      prenom: 'Amina',
                      identifiantImmuable: 'STUD-AD-000001',
                      mode: InterfaceMode.enfant,
                      camera: CameraPolicy.forbidden,
                    ),
                  ],
              ),
              servicePlanningProvider.overrideWithValue(
                FauxServicePlanning()
                  ..affectationsRendues = <Affectation>[
                    Affectation(
                      id: 'a1',
                      enseignantId: 't1',
                      enseignantPrenom: 'Aminata',
                      enseignantIdentifiant: 'TEACH-AD-000001',
                      eleveId: 'e1',
                      elevePrenom: 'Amina',
                      creneau: const Creneau(
                        jour: 2,
                        heure: 17,
                        fuseau: 'Europe/Paris',
                      ),
                      depuis: DateTime(2026, 9, 1),
                    ),
                  ],
              ),
              serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
              serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
            ],
          ),
        );
        await _stabiliser(tester);
        final Finder demande = find.text(
          t.tuteur.reglages.demandeReaffectation,
        );
        await tester.ensureVisible(demande);
        await tester.tap(demande);
        await _stabiliser(tester);
        await tester.enterText(
          find.byType(TextField),
          'Le créneau du mardi ne convient plus depuis la rentrée.',
        );
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('reglages_guidee_${c.$3}'))}',
        );
      });
    }

    // Le lecteur du Coran du Mode Accessibilite, lecteur d'ecran actif.
    for (final (Size, String) c in <(Size, String)>[
      (const Size(390, 844), '390x2'),
      (const Size(320, 640), '320x2'),
    ]) {
      testWidgets('lecteur du Coran, lecteur d\'ecran ${c.$2}', (
        WidgetTester tester,
      ) async {
        _vue(tester, c.$1, 2);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          _app(
            home: EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              destinationInitiale: EcranAccessibiliteDemo.indexCoran,
              surchargesCoran: <Override>[
                portCorpusCoranProvider.overrideWithValue(
                  FauxCorpusCoran(reference),
                ),
                portLayoutMushafProvider.overrideWithValue(
                  const LayoutLignesIndisponible(),
                ),
                portNavigationCoranProvider.overrideWithValue(
                  FauxNavigationCoran(
                    personnelle: PositionLecture(
                      page: reference.pages.first.numero,
                      sourate: 1,
                      verset: 1,
                      zoom: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.tap(
          find.byKey(const ValueKey<String>('coran-ma-principale')),
        );
        for (int i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('coran_lecteur_ecran_${c.$2}'))}',
        );
      });
    }

    // L'invitation du conjoint : aide du courriel puis erreur, 320 x2.
    testWidgets('invitation du conjoint 320x2', (WidgetTester tester) async {
      _vue(tester, const Size(320, 900), 2);
      await tester.pumpWidget(
        _app(
          home: InviterConjointPage(
            placeFeminine: true,
            onAbandon: () {},
            onTerminee: () {},
          ),
        ),
      );
      await _stabiliser(tester);
      await tester.enterText(
        find.byKey(InviterConjointPage.courrielKey),
        'pas-un-courriel',
      );
      final Finder verifier = find.byKey(InviterConjointPage.verifierKey);
      await tester.ensureVisible(verifier);
      await tester.tap(verifier);
      await _stabiliser(tester);
      await tester.ensureVisible(find.byKey(InviterConjointPage.courrielKey));
      await _stabiliser(tester);
      debugPrint('PNG ${await capturerVue(tester, _nom('invitation_320x2'))}');
    });
  });
}
