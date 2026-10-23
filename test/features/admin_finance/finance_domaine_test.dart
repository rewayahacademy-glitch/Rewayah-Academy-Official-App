// FI-1b : le domaine Finance de la direction, sur le VRAI routeur et la vraie
// application, comme `main.dart` la monte en demonstration (`?demo=admin`) :
// « Finance » est tape dans la vraie coquille admin (K-07), puis l'onglet
// « Politiques commerciales ». Et /demo/finance n'existe pas en production.
//
// FI-11a : en demonstration, la Vue globale rend les chiffres de
// `FinanceDirectionDemo` ; sans la demonstration (port de production,
// `CapaciteIndisponible`), elle dit toujours « Pas encore disponible ».
//
// FI-11b : en demonstration, Politiques commerciales rend la politique de
// lancement et son brouillon ; sans la demonstration, « Pas encore
// disponible », sans chiffre.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/demo/services_admin_demo.dart';

import '../../support/selecteur_section.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester,
  Size taille, {
  List<Override>? surcharges,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges ?? surchargesDemoAdmin(environnement: 'staging'),
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

/// La Vue globale de la demonstration : ses chiffres, aucun etat
/// « indisponible ».
void _verifierVueGlobaleDemo() {
  expect(find.byType(FinancePage), findsOneWidget);
  expect(find.byType(VueGlobaleFinanceContenu), findsOneWidget);
  expect(find.byType(EtatSysteme), findsNothing);
  // 690 USD encaisses et 690 USD de revenu, deux indicateurs separes (le
  // graphique de l'encaisse repete le mois, hors de la grille).
  expect(
    find.descendant(
      of: find.byKey(VueGlobaleFinanceContenu.indicateursKey),
      matching: find.text(formaterMontant(DonneesFinanceDemo.usd(690))),
    ),
    findsNWidgets(2),
  );
  expect(find.text(t.admin.finance.vue.marge), findsOneWidget);
}

/// Les Politiques commerciales de la demonstration : le brouillon et la
/// version active, les valeurs de lancement, aucun etat « indisponible ».
void _verifierPolitiquesDemo() {
  expect(find.byType(FinancePage), findsOneWidget);
  expect(find.byType(PolitiquesCommercialesContenu), findsOneWidget);
  expect(find.byType(EtatSysteme), findsNothing);
  final pol = t.admin.finance.pol;
  expect(
    find.text(
      pol.versionActive(version: DonneesFinanceDemo.politiqueLancement.version),
    ),
    findsOneWidget,
  );
  expect(
    find.text(
      pol.versionBrouillon(
        version: DonneesFinanceDemo.politiqueBrouillon.version,
      ),
    ),
    findsOneWidget,
  );
}

void main() {
  test('ongletsFinance : Vue globale, Politiques commerciales, '
      'Reserve et delegation, A valider, Paiements', () {
    expect(ongletsFinance(), <({String libelle, String chemin})>[
      (libelle: 'Vue globale', chemin: Routes.adminFinance),
      (
        libelle: 'Politiques commerciales',
        chemin: Routes.adminFinancePolitiques,
      ),
      (
        libelle: 'Réserve et délégation',
        chemin: Routes.adminFinanceReserveDelegation,
      ),
      (libelle: 'À valider', chemin: Routes.adminFinanceAValider),
      (libelle: 'Paiements', chemin: Routes.adminFinancePaiements),
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
    _verifierVueGlobaleDemo();

    await choisirSection(tester, t.admin.finance.politiques);
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminFinancePolitiques);
    _verifierPolitiquesDemo();
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
    _verifierVueGlobaleDemo();
    expect(tester.takeException(), isNull);
  });

  testWidgets('production (port neutre) : la Vue globale dit toujours « Pas '
      'encore disponible », sans chiffre', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      surcharges: <Override>[
        // Une session admin, et aucun port Finance surcharge : celui de la
        // production (`FinanceDirectionIndisponible`).
        sourceSessionProvider.overrideWithValue(const SourceSessionDemoAdmin()),
        ...surchargesServicesAdminIndisponibles(),
      ],
    );
    routeur.go(Routes.adminFinance);
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminFinance);
    _verifierPageNeutre(OngletFinance.vueGlobale);
    expect(find.byType(VueGlobaleFinanceContenu), findsNothing);
    expect(find.textContaining('\$'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production (port neutre) : Politiques commerciales dit « Pas '
      'encore disponible », sans chiffre ni champ', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(const SourceSessionDemoAdmin()),
        ...surchargesServicesAdminIndisponibles(),
      ],
    );
    routeur.go(Routes.adminFinancePolitiques);
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminFinancePolitiques);
    _verifierPageNeutre(OngletFinance.politiques);
    expect(find.byType(PolitiquesCommercialesContenu), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('\$'), findsNothing);
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
      _verifierVueGlobaleDemo();

      await choisirSection(tester, t.admin.finance.politiques);
      await tester.pumpAndSettle();
      final Uri adresse = routeur.routerDelegate.currentConfiguration.uri;
      expect(adresse.path, Routes.demoFinance);
      expect(adresse.queryParameters['ecran'], OngletFinance.politiques.name);
      _verifierPolitiquesDemo();
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-04 : le lien d une alerte reste dans la demonstration '
        '(K-28), jamais vers une route reelle gardee', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GoRouter routeur = GoRouter(
        initialLocation: Routes.demoFinance,
        routes: <RouteBase>[
          ...routesDemoFinance('staging'),
          GoRoute(
            path: Routes.adminPersonnesComptes,
            builder: (BuildContext _, GoRouterState _) =>
                const Scaffold(body: Text('route reelle')),
          ),
        ],
      );
      addTearDown(routeur.dispose);
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
      final Finder lien = find.byKey(
        const ValueKey<String>('demo-fi-alerte-ibrahim-cible'),
      );
      expect(lien, findsOneWidget);
      expect(find.text(t.admin.finance.vue.alerte.ouvrirComptes), findsOne);
      await tester.ensureVisible(lien);
      await tester.pumpAndSettle();
      await tester.tap(lien);
      await tester.pumpAndSettle();
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.demoFinance,
      );
      expect(find.text('route reelle'), findsNothing);
      expect(find.byType(AdminShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
