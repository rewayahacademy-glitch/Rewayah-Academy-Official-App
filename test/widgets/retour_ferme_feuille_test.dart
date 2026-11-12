// RETOUR-FERME-FEUILLE (garde-cap, 12/11/2026) : le retour du navigateur
// ferme d'abord la feuille du bas ouverte, au lieu de changer d'onglet. Le
// navigateur web arrive comme une nouvelle adresse (`handlePushRoute`) ; le
// retour Android comme `handlePopRoute`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/navigation/retour_ferme_feuille.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../support/harnais.dart';

const Key _ouvrir = Key('ouvrir-feuille');
const Key _ouvrirVerrouillee = Key('ouvrir-feuille-verrouillee');

GoRouter _routeur() => GoRouter(
  initialLocation: '/a',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState etat,
            StatefulNavigationShell coque,
          ) => NavShell(
            destinations: destinationsPour(
              role: AppRole.teacher,
              mode: InterfaceMode.standard,
            ),
            indexActif: coque.currentIndex,
            onAller: (_) {},
            child: coque,
          ),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/a',
              builder: (BuildContext context, GoRouterState _) => Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      key: _ouvrir,
                      onPressed: () => AppBottomSheet.ouvrir<void>(
                        context,
                        titre: 'Feuille',
                        libelleFermer: 'Fermer',
                        constructeur: (BuildContext _) =>
                            const SizedBox(height: 80),
                      ),
                      child: const Text('Onglet A'),
                    ),
                    TextButton(
                      key: _ouvrirVerrouillee,
                      onPressed: () => AppBottomSheet.ouvrir<void>(
                        context,
                        titre: 'Verrouillee',
                        constructeur: (BuildContext _) => const PopScope(
                          canPop: false,
                          child: SizedBox(height: 80),
                        ),
                      ),
                      child: const Text('Ouvrir verrouillee'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/b',
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Center(child: Text('Onglet B'))),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Les adresses que l'application publie au navigateur.
final List<String> _publiees = <String>[];

Future<GoRouter> _monter(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _publiees.clear();
  // Comme `lib/main.dart` : avant le routeur.
  RetourFermeFeuille.installer();
  addTearDown(RetourFermeFeuille.desinstaller);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.navigation,
    (MethodCall appel) async {
      if (appel.method == 'routeInformationUpdated') {
        final Map<Object?, Object?> args =
            appel.arguments as Map<Object?, Object?>;
        _publiees.add('${args['uri'] ?? args['location']}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      null,
    ),
  );
  final GoRouter routeur = _routeur();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[sansPersonneConnectee()],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // L'historique : /b, puis /a.
  routeur.go('/b');
  await tester.pumpAndSettle();
  routeur.go('/a');
  await tester.pumpAndSettle();
  return routeur;
}

void main() {
  testWidgets('retour du navigateur, feuille ouverte : la feuille se ferme, '
      'l onglet reste ; le retour suivant change d onglet', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    _publiees.clear();

    await tester.binding.handlePushRoute('/b');
    await tester.pumpAndSettle();
    expect(find.text('Feuille', skipOffstage: false), findsNothing);
    expect(find.text('Onglet A'), findsOneWidget);
    expect(routeur.state.matchedLocation, '/a');
    // L'adresse courante est republiee : la barre d'adresse dit vrai.
    expect(_publiees, contains('/a'));
    expect(FeuillesOuvertes.nombre, 0);

    await tester.binding.handlePushRoute('/b');
    await tester.pumpAndSettle();
    expect(find.text('Onglet B'), findsOneWidget);
    expect(routeur.state.matchedLocation, '/b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('retour du navigateur sans feuille : l onglet change', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester);
    await tester.binding.handlePushRoute('/b');
    await tester.pumpAndSettle();
    expect(find.text('Onglet B'), findsOneWidget);
    expect(routeur.state.matchedLocation, '/b');
  });

  testWidgets('retour Android, feuille ouverte : la feuille se ferme, '
      'l onglet reste (inchange)', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Feuille', skipOffstage: false), findsNothing);
    expect(routeur.state.matchedLocation, '/a');
  });

  testWidgets('une feuille hors scene, dans un onglet quitte, n intercepte '
      'rien', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    routeur.go('/b');
    await tester.pumpAndSettle();
    expect(find.text('Feuille', skipOffstage: false), findsOneWidget);

    // Le navigateur revient a /a : rien a fermer a l'ecran, l'onglet change.
    await tester.binding.handlePushRoute('/a');
    await tester.pumpAndSettle();
    expect(routeur.state.matchedLocation, '/a');
    expect(find.text('Feuille'), findsOneWidget);
  });

  testWidgets('une feuille qui interdit sa fermeture reste ouverte, et '
      'l onglet ne change pas', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.byKey(_ouvrirVerrouillee));
    await tester.pumpAndSettle();
    expect(find.text('Verrouillee'), findsOneWidget);

    await tester.binding.handlePushRoute('/b');
    await tester.pumpAndSettle();
    expect(find.text('Verrouillee'), findsOneWidget);
    expect(routeur.state.matchedLocation, '/a');
    expect(find.text('Onglet B'), findsNothing);
  });

  testWidgets('le registre ne fuit pas : bouton, voile, glissement, '
      'navigateur retire', (WidgetTester tester) async {
    await _monter(tester);
    expect(FeuillesOuvertes.nombre, 0);

    // 1. La croix « Fermer ».
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 1);
    await tester.tap(find.byKey(AppBottomSheet.cleFermer));
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 0);

    // 2. Le voile.
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 1);
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsNothing);
    expect(FeuillesOuvertes.nombre, 0);

    // 3. Le glissement vers le bas.
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 1);
    await tester.fling(find.text('Feuille'), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsNothing);
    expect(FeuillesOuvertes.nombre, 0);

    // 4. Le navigateur retire avec l'application.
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(FeuillesOuvertes.nombre, 0);
  });
}
