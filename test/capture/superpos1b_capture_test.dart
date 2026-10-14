// SUPERPOS-1b : captures de preuve, avant (tete `5a52ff30`) et apres
// (variable `PHASE`, par defaut `apres`). Demande des reglages de l'enfant
// (bouton jamais grise : appui sans motif, appui sans duree), saisie du code
// de l'appareil eleve (refus « revoque » a 320 x2, francais et arabe), apercu
// avec bandeaux (un seul point d'attention). Jamais sans `CAPTURE_DIR`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bandeau_observation.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/alertes/bandeau_alerte_urgente.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../features/appareils/faux_lecteur_qr.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

String _nom(String quoi) => 'superpos1b_${_phase}_$quoi';

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
  bool repere = false,
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
      builder: (BuildContext _, Widget? app) => Directionality(
        textDirection: sens,
        child: repere ? RepereDemonstration(child: app) : app!,
      ),
      home: home,
    ),
  ),
);

Future<void> _stabiliser(WidgetTester tester) async {
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 600));
  await stabiliser(tester);
}

List<Override> _surchargesReglages() => <Override>[
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
          creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
          depuis: DateTime(2026, 9, 1),
        ),
      ],
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
];

Future<void> _taperEnvoyer(WidgetTester tester) async {
  final Finder envoyer = find.widgetWithText(
    ActionPrincipale,
    t.tuteur.reglages.demandeEnvoyer,
  );
  await tester.ensureVisible(envoyer);
  await _stabiliser(tester);
  await tester.tap(envoyer, warnIfMissed: false);
  await _stabiliser(tester);
}

void main() {
  group('Capture : SUPERPOS-1b', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    setUp(masquerRubanDebug);

    // La demande des reglages de l'enfant : appui sur l'envoi sans motif.
    for (final (Size, double, InterfaceMode, ThemeMode, TextDirection, String) c
        in <(Size, double, InterfaceMode, ThemeMode, TextDirection, String)>[
          (
            const Size(320, 640),
            2,
            InterfaceMode.standard,
            ThemeMode.light,
            TextDirection.ltr,
            '320x2_clair',
          ),
          (
            const Size(320, 640),
            2,
            InterfaceMode.enfant,
            ThemeMode.dark,
            TextDirection.rtl,
            '320x2_guidee_sombre_rtl',
          ),
          (
            const Size(390, 844),
            1,
            InterfaceMode.standard,
            ThemeMode.light,
            TextDirection.ltr,
            '390',
          ),
        ]) {
      testWidgets('reglages, appui sans motif ${c.$6}', (
        WidgetTester tester,
      ) async {
        _vue(tester, c.$1, c.$2);
        await tester.pumpWidget(
          _app(
            mode: c.$3,
            theme: c.$4,
            sens: c.$5,
            home: const ReglagesEnfantPage(),
            surcharges: _surchargesReglages(),
          ),
        );
        await _stabiliser(tester);
        final Finder demande = find.text(
          t.tuteur.reglages.demandeReaffectation,
        );
        await tester.ensureVisible(demande);
        await tester.tap(demande);
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('reglages_vide_${c.$6}'))}',
        );
        await _taperEnvoyer(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('reglages_appui_${c.$6}'))}',
        );
      });
    }

    // La demande de duree : motif saisi, aucune duree choisie, appui.
    testWidgets('reglages, duree non choisie 320x2', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(320, 640), 2);
      await tester.pumpWidget(
        _app(
          home: const ReglagesEnfantPage(),
          surcharges: _surchargesReglages(),
        ),
      );
      await _stabiliser(tester);
      final Finder demande = find.text(t.tuteur.reglages.demandeDuree);
      await tester.ensureVisible(demande);
      await tester.tap(demande);
      await _stabiliser(tester);
      await tester.enterText(find.byType(TextField).first, 'Elle décroche.');
      await _stabiliser(tester);
      await _taperEnvoyer(tester);
      debugPrint(
        'PNG ${await capturerVue(tester, _nom('reglages_duree_320x2'))}',
      );
    });

    // La saisie du code : refus « revoque » a 320 x2.
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('saisie du code, refus revoque ${langue.languageCode}', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(320, 640), 2);
        LocaleSettings.setLocaleSync(langue);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
          ..refus = MotifRefusAppairage.revoque;
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesRouteur(FausseSourceSession()),
              serviceEnfantProvider.overrideWithValue(service),
              stockageSecuriseProvider.overrideWithValue(
                FauxStockageSecurise(),
              ),
              profilsLocauxProvider.overrideWithValue(FauxProfilsLocaux()),
              lecteurQrDisponibleProvider.overrideWithValue(true),
              fabriqueLecteurQrProvider.overrideWithValue(FauxLecteurQr.new),
            ],
            child: TranslationProvider(
              child: Consumer(
                builder: (BuildContext _, WidgetRef ref, Widget? _) {
                  routeur = ref.read(routeurProvider);
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    locale: langue.flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    routerConfig: routeur,
                  );
                },
              ),
            ),
          ),
        );
        await _stabiliser(tester);
        routeur.go(Routes.connexionEleveCode);
        await _stabiliser(tester);
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
        await _stabiliser(tester);
        final Finder valider = find.widgetWithText(
          ActionPrincipale,
          t.eleveConnexion.saisie.valider,
        );
        await tester.tap(valider);
        await _stabiliser(tester);
        await tester.ensureVisible(find.byKey(SaisieCodePage.champKey));
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('code_revoque_320x2_${langue.languageCode}'))}',
        );
      });
    }

    // L'apercu : repere, bandeaux et action principale.
    for (final (ThemeMode, TextDirection, String) c
        in <(ThemeMode, TextDirection, String)>[
          (ThemeMode.light, TextDirection.ltr, 'clair'),
          (ThemeMode.dark, TextDirection.rtl, 'sombre_rtl'),
        ]) {
      testWidgets('apercu et bandeaux 320x2 ${c.$3}', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(320, 640), 2);
        await tester.pumpWidget(
          _app(
            repere: true,
            theme: c.$1,
            sens: c.$2,
            surcharges: <Override>[
              alertesProvider.overrideWith(
                (Ref _) => Stream<List<Alerte>>.value(<Alerte>[
                  Alerte(
                    id: 'a1',
                    gravite: GraviteAlerte.urgent,
                    titre: 'Classe sans enseignant',
                    creeeLe: DateTime(2026, 10, 9, 16, 50),
                  ),
                ]),
              ),
            ],
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const OfflineBanner.message(
                        message:
                            'Les dossiers pourront être validés quand la '
                            'connexion reviendra.',
                      ),
                      const BandeauObservation(
                        observation: Observation(identiteMasquee: true),
                      ),
                      BandeauAlerteUrgente(onOuvrir: () {}),
                      ActionPrincipale(libelle: 'Valider', onPress: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, _nom('apercu_320x2_${c.$3}'))}',
        );
      });
    }
  });
}
