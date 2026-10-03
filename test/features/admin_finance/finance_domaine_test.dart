// FI-1b : le domaine Finance de la direction, sur le VRAI routeur et la vraie
// application, comme `main.dart` la monte en demonstration (`?demo=admin`) :
// « Finance » est tape dans la vraie coquille admin (K-07), puis l'onglet
// « Politiques commerciales ». Et /demo/finance n'existe pas en production.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../support/selecteur_section.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(Routes.admin);
  await _stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

Finder _dans(Key cle, Finder cible) =>
    find.descendant(of: find.byKey(cle), matching: cible);

void _verifierPageNeutre(OngletFinance onglet) {
  expect(find.byType(FinancePage), findsOneWidget);
  final EtatSysteme etat =
      find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
  expect(etat.nature, NatureEtat.indisponible, reason: onglet.name);
  expect(
    find.text(EtatSysteme.textesPar(NatureEtat.indisponible).titre),
    findsOneWidget,
    reason: onglet.name,
  );
}

void main() {
  test('ongletsFinance : Vue globale puis Politiques commerciales', () {
    expect(ongletsFinance(), <({String libelle, String chemin})>[
      (libelle: 'Vue globale', chemin: Routes.adminFinance),
      (
        libelle: 'Politiques commerciales',
        chemin: Routes.adminFinancePolitiques,
      ),
    ]);
    expect(AdminDomaine.finance.chemin, Routes.adminFinance);
    expect(AdminDomaine.finance.actif, isTrue);
  });

  testWidgets('1440 : « Finance » tape dans la barre 288 ouvre la Vue globale, '
      'puis l onglet Politiques commerciales', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester, const Size(1440, 900));
    expect(find.byType(FinancePage), findsNothing);

    await tester.tap(
      _dans(AdminShell.barreLateraleKey, find.text(t.nav.admin.finance)),
    );
    await _stabiliser(tester);

    expect(_chemin(routeur), Routes.adminFinance);
    final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
      _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
    );
    expect(
      tiroir.selectedIndex,
      domainesAdmin(voitDirection: false).indexOf(AdminDomaine.finance),
    );
    expect(sectionVisible(t.admin.finance.vueGlobale), findsOneWidget);
    _verifierPageNeutre(OngletFinance.vueGlobale);

    await choisirSection(tester, t.admin.finance.politiques);
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminFinancePolitiques);
    _verifierPageNeutre(OngletFinance.politiques);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 : Finance depuis le tiroir mobile', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, const Size(390, 844));
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
    await tester.tap(
      _dans(AdminShell.tiroirKey, find.text(t.nav.admin.finance)),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminFinance);
    _verifierPageNeutre(OngletFinance.vueGlobale);
    expect(tester.takeException(), isNull);
  });

  group('/demo/finance', () {
    test('absente en production et pour un environnement vide', () {
      expect(routesDemoFinance('production'), isEmpty);
      expect(routesDemoFinance(' Production '), isEmpty);
      expect(routesDemoFinance('preprod'), isEmpty);
      expect(routesDemoFinance(''), isEmpty);
      expect(routesDemoFinance('   '), isEmpty);
      expect(routesDemoFinance('staging'), hasLength(1));
      expect(routesDemoFinance('developpement'), hasLength(1));
    });

    test('la porte ne laisse passer /demo/finance que hors production', () {
      String? decider(String environnement) => deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.demoFinance,
        maintenant: DateTime.utc(2026, 10, 3),
        environnement: environnement,
      );
      expect(decider('production'), isNotNull);
      expect(decider(''), isNotNull);
      expect(decider('staging'), isNull);
    });

    testWidgets('hors production : la vraie coquille admin, Finance actif, '
        'et l onglet reste dans la demonstration', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GoRouter routeur = GoRouter(
        initialLocation: Routes.demoFinance,
        routes: routesDemoFinance('staging'),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      // Le repere « Démonstration » coiffe la coquille.
      expect(
        find.ancestor(
          of: find.byType(AdminShell),
          matching: find.byType(RepereDemonstration),
        ),
        findsOneWidget,
      );
      _verifierPageNeutre(OngletFinance.vueGlobale);

      await choisirSection(tester, t.admin.finance.politiques);
      await tester.pumpAndSettle();
      final Uri adresse = routeur.routerDelegate.currentConfiguration.uri;
      expect(adresse.path, Routes.demoFinance);
      expect(adresse.queryParameters['ecran'], OngletFinance.politiques.name);
      _verifierPageNeutre(OngletFinance.politiques);
      expect(tester.takeException(), isNull);
    });
  });
}
