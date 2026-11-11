// Directeur, 11/11/2026 (production, enseignant au telephone) : « la barre
// disparait sans raison et on est oblige de fermer l'app ». Une feuille du bas
// restee ouverte dans un onglet qu'on quitte (retour du navigateur, lien de la
// feuille, notification) ne doit pas effacer la barre des autres onglets.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../support/harnais.dart';

const Key _ouvrir = Key('ouvrir-feuille');

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
                body: Center(
                  child: TextButton(
                    key: _ouvrir,
                    onPressed: () => AppBottomSheet.ouvrir<void>(
                      context,
                      titre: 'Feuille',
                      constructeur: (BuildContext _) =>
                          const SizedBox(height: 80),
                    ),
                    child: const Text('Onglet A'),
                  ),
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

void main() {
  testWidgets('feuille ouverte dans un onglet, puis on change d onglet sans '
      'la fermer : la barre revient ; de retour, elle s efface ; feuille '
      'fermee, elle revient', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    expect(find.byKey(NavShell.barreBasseKey), findsNothing);
    routeur.go('/b');
    await tester.pumpAndSettle();
    expect(find.text('Onglet B'), findsOneWidget);
    expect(find.text('Feuille', skipOffstage: false), findsOneWidget);
    expect(find.text('Feuille'), findsNothing);
    expect(
      find.byKey(NavShell.barreBasseKey),
      findsOneWidget,
      reason: 'la barre doit revenir quand on quitte l onglet de la feuille',
    );
    routeur.go('/a');
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    expect(find.byKey(NavShell.barreBasseKey), findsNothing);
    Navigator.of(tester.element(find.text('Feuille'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Feuille', skipOffstage: false), findsNothing);
    expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
