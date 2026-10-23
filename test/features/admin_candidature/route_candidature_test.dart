// ADM-21 sur le VRAI routeur (demonstration d'administration) : la file ouvre la
// candidature par sa reference dans l'adresse ; l'adresse tapee ou rechargee
// ouvre la meme page ; le retour ramene a la file ; une adresse inconnue dit
// « absente » au lieu d'une page vide.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  FauxCandidaturesDirection port, {
  String depart = Routes.adminPersonnesCandidatures,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await laisser(tester);
  routeur.go(depart);
  await laisser(tester, fois: 12);
  return routeur;
}

/// L'adresse de la page ouverte : celle de la route de la candidature (une page
/// poussee garde la sienne), telle que le navigateur l'ecrit.
String _chemin(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(CandidatureDirectionPage)))
        .uri
        .path;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('la file ouvre la candidature par sa reference', (
    WidgetTester tester,
  ) async {
    final DetailCandidature d = detailTest();
    final FauxCandidaturesDirection port = FauxCandidaturesDirection(
      capacitesRendues: capacitesGestes,
      details: <DetailCandidature>[d],
    );
    await _monter(tester, port);
    expect(find.byType(CandidaturesPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('candidature-c1')));
    await laisser(tester, fois: 12);
    expect(find.byType(CandidatureDirectionPage), findsOneWidget);
    // La reference dans l'adresse, jamais l'identifiant ni un nom.
    expect(_chemin(tester), '/admin/personnes/candidatures/CAND-0000C1');
    expect(_chemin(tester), isNot(contains('/c1')));
    expect(find.text('Amina Diallo'), findsWidgets);
    // L'identifiant venait de la ligne : aucune recherche de reference.
    expect(port.appelsLire, <String>['c1']);
    expect(port.appels, hasLength(1));
  });

  testWidgets('l\'adresse tapee ouvre la meme page, par la recherche exacte', (
    WidgetTester tester,
  ) async {
    final FauxCandidaturesDirection port = FauxCandidaturesDirection(
      capacitesRendues: capacitesGestes,
      details: <DetailCandidature>[detailTest()],
    );
    await _monter(
      tester,
      port,
      depart: Routes.adminPersonnesCandidaturePour('CAND-0000C1'),
    );
    expect(find.byType(CandidatureDirectionPage), findsOneWidget);
    expect(find.text('Amina Diallo'), findsWidgets);
    expect(_chemin(tester), '/admin/personnes/candidatures/CAND-0000C1');
    expect(port.appels.single.filtre.recherche, 'CAND-0000C1');
  });

  testWidgets('le retour ramene a la file', (WidgetTester tester) async {
    final FauxCandidaturesDirection port = FauxCandidaturesDirection(
      capacitesRendues: capacitesGestes,
      details: <DetailCandidature>[detailTest()],
    );
    await _monter(tester, port);
    await tester.tap(find.byKey(const ValueKey<String>('candidature-c1')));
    await laisser(tester, fois: 12);
    expect(find.byType(CandidatureDirectionPage), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour).first);
    await laisser(tester, fois: 12);
    expect(find.byType(CandidatureDirectionPage), findsNothing);
    expect(find.byType(CandidaturesPage), findsOneWidget);
  });

  testWidgets('une reference inconnue : « absente », pas une page vide', (
    WidgetTester tester,
  ) async {
    final FauxCandidaturesDirection port = FauxCandidaturesDirection(
      capacitesRendues: capacitesGestes,
      details: <DetailCandidature>[detailTest()],
    );
    await _monter(
      tester,
      port,
      depart: Routes.adminPersonnesCandidaturePour('CAND-99999'),
    );
    expect(find.text(t.admin.candidatures.detail.titreAbsente), findsOneWidget);
  });

  test('le chemin d\'une reference s\'encode, sans nom ni identifiant', () {
    expect(
      Routes.adminPersonnesCandidaturePour('CAND-00012'),
      '/admin/personnes/candidatures/CAND-00012',
    );
    expect(
      Routes.adminPersonnesCandidature,
      '/admin/personnes/candidatures/:reference',
    );
  });
}
