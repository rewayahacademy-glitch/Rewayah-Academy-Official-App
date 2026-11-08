// Captures R3 de REPRISE-CAND-3 (08/11/2026) : la synthese de la file des
// candidatures, reprise de la PR 45 sur main, a la place de la carte
// « A traiter ». Donnees de test uniquement (`faux_candidatures_direction.dart`),
// aucune personne reelle.
//
// Scenes, en francais et en arabe, a 390 et a 1440 (haut de la page) :
// 1. deux alertes servies par le serveur (12 et 2), deux non servies : rien
//    n'est dit pour elles ;
// 2. les quatre alertes servies a zero : « Rien a traiter ».
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

GoRoute _route(String chemin, Widget ecran) =>
    GoRoute(path: chemin, builder: (BuildContext _, GoRouterState _) => ecran);

List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(id: 'a1', nom: 'Amina Diallo'),
  ligneTest(id: 'b2', nom: 'Bilal Haddad'),
  ligneTest(id: 'f6', nom: 'Farah Nasser'),
];

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  double densite,
  CompteursAlertes alertes,
) async {
  fixerVueCapture(tester, taille, densite);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesCandidatures,
    routes: <RouteBase>[
      _route(Routes.adminPersonnesCandidatures, const CandidaturesPage()),
      _route(Routes.adminPersonnesInvitations, const SizedBox()),
      _route(RoutesCandidatsFlux.importFormulaires, const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: capacitesQuiDecide,
            alertes: alertes,
          ),
        ),
        portInvitationsEnseignantProvider.overrideWithValue(null),
        portInvitationsComptableProvider.overrideWithValue(null),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              themeMode: ThemeMode.light,
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

void main() {
  group('Capture REPRISE-CAND-3', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // L'arabe est charge en differe : une fois ici, hors du FakeAsync.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final (String nom, Size taille, double densite) gabarit
        in <(String, Size, double)>[
          ('390', const Size(390, 844), 3),
          ('1440', const Size(1440, 900), 1),
        ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final String suffixe = '${langue.languageCode}_${gabarit.$1}';
        for (final (String scene, CompteursAlertes alertes)
            in <(String, CompteursAlertes)>[
              (
                '1_alertes',
                const CompteursAlertes(
                  informationsManquantes: 12,
                  confirmeesIndisponibles: 2,
                ),
              ),
              (
                '2_rien',
                const CompteursAlertes(
                  bloquees: 0,
                  entretiensEnRetard: 0,
                  informationsManquantes: 0,
                  confirmeesIndisponibles: 0,
                ),
              ),
            ]) {
          testWidgets('REPRISE-CAND-3 ${scene}_$suffixe', (
            WidgetTester tester,
          ) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            await _monter(tester, gabarit.$2, gabarit.$3, alertes);
            debugPrint('PNG ${await capturer(tester, '${scene}_$suffixe')}');
          });
        }
      }
    }
  });
}
