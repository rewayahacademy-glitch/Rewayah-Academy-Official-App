// Captures R3 de REPRISE-CAND-1 (08/11/2026) : le traitement groupe des
// candidatures, repris de la PR 45 sur main. Donnees de test uniquement
// (`faux_candidatures_direction.dart`), aucune personne reelle.
//
// Scenes, en francais et en arabe, a 390 et a 1440 :
// 1. trois candidatures retenues : la barre du lot, collee en bas ;
// 2. « Mettre en pause » : l'apercu du serveur, une candidature exclue ;
// 3. le lot fait : le rapport ligne par ligne.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart'
    show cleCase;
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

GoRoute _route(String chemin, Widget ecran) =>
    GoRoute(path: chemin, builder: (BuildContext _, GoRouterState _) => ecran);

List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(id: 'a1', nom: 'Amina Diallo'),
  ligneTest(id: 'b2', nom: 'Bilal Haddad'),
  // Deja en pause : exclue de « Mettre en pause ».
  ligneTest(id: 'e5', nom: 'Emna Gharbi', enPause: true),
  ligneTest(id: 'f6', nom: 'Farah Nasser'),
  ligneTest(id: 'g7', nom: 'Ghali Mansour'),
];

Future<void> _monter(WidgetTester tester, Size taille, double densite) async {
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
            capacitesRendues: capacitesGestes,
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

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await stabiliser(tester);
  await tester.tap(f);
  await stabiliser(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture REPRISE-CAND-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (String nom, Size taille, double densite) gabarit
        in <(String, Size, double)>[
          ('390', const Size(390, 844), 3),
          ('1440', const Size(1440, 900), 1),
        ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final String suffixe = '${langue.languageCode}_${gabarit.$1}';
        testWidgets('REPRISE-CAND-1 $suffixe', (WidgetTester tester) async {
          await LocaleSettings.setLocale(langue);
          await _monter(tester, gabarit.$2, gabarit.$3);

          // 1. La barre du lot.
          await _toucher(
            tester,
            find.byKey(const ValueKey<String>('candidatures-selectionner')),
          );
          for (final String id in <String>['a1', 'b2', 'e5']) {
            await _toucher(tester, find.byKey(cleCase(id)));
          }
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 5000),
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, '1_barre_$suffixe')}');

          // 2. L'apercu du serveur.
          await _toucher(
            tester,
            find.byKey(
              CandidaturesPage.cleOperationLot(GesteLot.mettreEnPause),
            ),
          );
          debugPrint('PNG ${await capturer(tester, '2_apercu_$suffixe')}');

          // 3. Le rapport.
          await _toucher(
            tester,
            find.byKey(const ValueKey<String>('modele-pause_general')),
          );
          await tester.enterText(
            find.byKey(FeuilleLot.cleMotif),
            'Attente des pieces.',
          );
          await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
          await stabiliser(tester);
          await _toucher(tester, find.byKey(FeuilleLot.cleValider));
          debugPrint('PNG ${await capturer(tester, '3_rapport_$suffixe')}');
        });
      }
    }
  });
}
